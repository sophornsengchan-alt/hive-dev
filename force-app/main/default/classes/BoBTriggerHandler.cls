/*********************************************************************************************************************************
@ Class:        BoBTriggerHandler
@ Version:      1.0
@ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:      Handler for BoB__c Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.08.2018 / Vadhanak Voun / Created the Class.
@                 13.04.2022 / Mony Nou / US-0012209 - Add Managed Segment field on Seller Mgmt record and add value "Pro-Trader Plus"
@				  11.05.2023 / Bora Chhorn / US-0012616 - Automation to change Cohort Seller Status to Inactive when Cohort Status is changed to "Inactive"
@                   12.06.2023 / Acmatac Seing / US-0013681 Move the logic to future to reduce CPU limit
@                10.08.2023 / Sophal Noch / US-0013955 - Error Future Method causing BOB deactivation not work properly
@                15.11.2023 / Sophal Noch / US-0014353 - Cohort Deactivation Process
@                26/1/24 / sovantheany dim / US-0014729 - Managed Segment field value on Cohort Seller shouldn't be overwritten
@                23.04.2024 / Sovantheany dim / US-0015106 - Retire Managed Cohort - Retire the record type Managed Cohort and update the Record Type of LTTM
@                14.05.2024 / Sophal Noch / US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
@                10.03.2025 / Vimean Heng / US-0016616 - 3. Eliminate manual BOB category selection validation for Activating the PT Cohort
*********************************************************************************************************************************/
public without sharing class BoBTriggerHandler {

    /************************************* CONSTANT DEFINITION *************************************************/
    private static String SOQL_BOB_With_Category = 'Select (Select Id From BoB_Categories__r limit 1) From BOB__c b';
    private static String SOQL_BOB_SELLER = 'Select BoB__c,(Select Id From Actions__r limit 1) From BoB_Seller__c b';
    private static Boolean isBeingDeactivated = false;
    private final static String BOB_LTTM_RECORDTYPE = 'Light_Touch_Category_Cohort';
    //BR-11-05-23-US-0012616
    private static String BOBSELLER_LTTM_RECORDTYPE = 'LTTM';
    private final static String BOBSELLER_INACTIVE_STATUS = 'Inactive';
    private final static Integer COHORT_SELLER_RECORD_LIMIT = Integer.valueOf(System.Label.Cohort_Seller_Record_Limit);
    //END-BR-11-05-23-US-0012616
    /************************************ END OF CONSTANT DEFINITION*******************************************/

    private static final String BOB_ACTIVE_STATUS='BoB Active'; // 10.08.2023 / Sophal Noch / US-0013955

    private final static String BOB_MNG_TYPE_PRO_TRADER = 'LTTM Managed'; // 14.05.2024 / Sophal Noch / US-0015200

    /*****************************************************************************************************************************
    @ Method:   syncFieldsFromBoB2BoBSeller
    @ Version:  1.0
    @ Author:   Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:  US-0012209 - AC2
    @               + When there is a Change in BOB__c.Managed_Segment__c, it should update BoB_Seller__c.EBH_BOBSegment__c
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     mapNew BoB, mapOld BoB
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.04.2023 / Mony Nou / Created the  Method.
    @                   12.06.2023 / Acmatac Seing / US-0013681 Move the logic to future to reduce CPU limit
    @                   26/1/24 / sovantheany dim / US-0014729 - Managed Segment field value on Cohort Seller shouldn't be overwritten
    *****************************************************************************************************************************/
    public static void syncFieldsFromBoB2BoBSeller (Map<Id,BoB__c> newMap , Map<Id,BoB__c> oldMap) {
        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',BOB_LTTM_RECORDTYPE);
        Set<Id> sBoBIds = new Set<Id>();

        for (BoB__c bob : newMap.values()) {
            if (bob.RecordTypeID == bobRecordTypeLTTM.Id && bob.Managed_Segment__c != oldMap.get(bob.Id).Managed_Segment__c) {
                sBoBIds.add(bob.Id);
            }
        }

        if (sBoBIds.isEmpty()) return;
        if(System.isFuture() || System.isBatch()){
            BoBTriggerHandler.doSyncFieldsFromBoB2BoBSeller(sBoBIds);
        }else{
            BoBTriggerHandler.future_syncFieldsFromBoB2BoBSeller(sBoBIds);
        }
         

    }
    @future
    private static void future_syncFieldsFromBoB2BoBSeller (Set<Id> sBoBIds) {
        BoBTriggerHandler.doSyncFieldsFromBoB2BoBSeller(sBoBIds);
    }

    private static void doSyncFieldsFromBoB2BoBSeller (Set<Id> sBoBIds) {
        // 12.06.2023 / Acmatac Seing / US-0013681 Update existing code to make future method working
        // for (BoB_Seller__c bobSeller : [SELECT BoB__c, EBH_BOBSegment__c FROM BoB_Seller__c WHERE BoB__c IN:sBoBIds]) {
        //     String bobManagedSegment = newMap.get(bobSeller.BoB__c).Managed_Segment__c;
        //     if (bobSeller.EBH_BOBSegment__c != bobManagedSegment) {
        //         bobSeller.EBH_BOBSegment__c = bobManagedSegment;
        //         lstBoBSeller2Update.add(bobSeller);
        //     }
        // }

        List<BoB_Seller__c> lstBoBSeller2Update = new List<BoB_Seller__c>();
        for (BoB_Seller__c bobSeller : [SELECT Id, EBH_BOBSegment__c, BoB__r.Managed_Segment__c FROM BoB_Seller__c WHERE BoB__c IN:sBoBIds and EBH_BOBSegment__c = null]) {
            //if (bobSeller.EBH_BOBSegment__c != bobSeller.BoB__r.Managed_Segment__c) {//TH: US-0014729 :Comment out , since i add EBH_BOBSegment__c = null in query already, there is no need to check this condition
                bobSeller.EBH_BOBSegment__c = bobSeller.BoB__r.Managed_Segment__c;
                lstBoBSeller2Update.add(bobSeller);
            //}
        }
        if(!lstBoBSeller2Update.isEmpty()) update lstBoBSeller2Update;
    }
    /*****************************************************************************************************************************
@ Method:   assignActiveBoBFieldsToSellerFromBoB
@ Version:  1.0
@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:  [EPH-5727] BOB MGMT - Seller BOB Object - Fields
@			Then the following fields now show the below based on the Active related BoB Seller record
@
@		Existing ?	Field Lable			FLS			Comment
@		Existing	BoB Managed?		Checkbox	TRUE = at least 1 related BoB Seller is Active
@		Existing	BoB Country			Read Only	Take parent BoB Country of Active BoB Seller record
@		Existing	BoB Vertical		Read Only	Take parent BoB Vertical of Active BoB Seller record
@		Existing	BoB Segment			Read Only	Take BoB Segment on Active BoB Seller record
@		New			BoB Subsegment		Read Only	Take BoB Subsegment on Active BoB Seller record
@	    
@		Trigger: After Update		
@		When	: when BoBSeller created with active BoB and connected to Seller -> populate fields
@				: when BoBSeller with inactive BoB already connected ton a Seller, then BoB update to Active -> find related Seller from Child(BoBSeller) and populate fields to Seller
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      List<BoB_Seller__c> list of BoB Seller
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.08.2018 / Vadhanak Voun / Created the  Method.
@				: 11.02.2020/ Vadhanak Voun /Disabled: US-0007164: handle by batch from button, or nightly job
*****************************************************************************************************************************/
 /*   public static void assignActiveBoBFieldsToSellerFromBoB(List<BoB__c> listBoB,Map<Id,BoB__c> mapOld)
    {
        Set<String> setBoBIds = new Set<String>();
        for(BoB__c b : listBoB)
        {
            //Active BoB changing somehing or become Active
            if((b.Status__c==EBH_ConstantsUtility.BOB_STATUS_ACTIVE) 
            	&& b.Status__c <> mapOld.get(b.Id).Status__c)//NK:05/12/2019: optimized for: US-0006885
            {
                setBoBIds.add(b.Id);
            }
        }
        
        //the get all related Sellers from its children
        if(!setBoBIds.isEmpty())
        {
        	//NK:16/12/2019:US-0006885: prevent account trigger to useless fire
    		if(System.isFuture())
    		{
    			doAssignBoBFields(setBoBIds);
    		}else
    		{
    			doAssignBoBFields_Asyn(setBoBIds);
    		}
        }
        
    }
    */
    /*****************************************************************************************************************************
    @ Method:   doAssignBoBFields_Asyn
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0006885 Hypercare - BoB Activation is not working 
	@		    moved from above to avoid cpu limit for huge sellers
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:   map of seller id and new ownerid    
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.01.2020/ Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    /*@future
    private static void doAssignBoBFields_Asyn(Set<String> setBoBIds)
    {
    	doAssignBoBFields(setBoBIds);
    }
    
    private static void doAssignBoBFields(Set<String> setBoBIds)
    {
    	EBH_AccountTriggerHandler.NO_TRIGGER_RUN  = true;  
    		    		
        BoBSellerTriggerHandler.assignActiveBoBFieldsToSeller(Database.query(EBH_ConstantsUtility.SOQL_BOB_WITH_CHILDREN),null);
    }
    */
    /*****************************************************************************************************************************
@ Method:   UpdateSellerOwnerBasedonBobSellerAccountManager
@ Version:  1.0
@ Author:   David Herrero dherrero@ebay.de
@ Purpose:  [EPH-6310] BOB MGMT - BOB MGMT - Update Seller "Owner" using Account Manager field
@			AC1b)
@			ensure that the account manager I assigned is also the seller record owner
@			AC2: Update Account Owner field based on BOB Account Manager
@			The Account Owner field should populated by a User that matches the Account Manager lookup field on the active BoB Seller record.
@			If there is no active BoB Seller record, than the Owner field should stay/revert back to the default Integration User.
@
@			Trigger: After insert / After update
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      List<BoB_Seller__c> list of BoB Seller
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.08.2018 / David Herrero / Created the  Method.
@				: 05/12/2019/ Vadhanak/ US-0006885 Hypercare - BoB Activation is not working: optimized and moved to Asyn
@				: 11.02.2020/ Vadhanak Voun / Disabled U:S-0007164: handle by batch from button, or nightly job
*****************************************************************************************************************************/
   
    static final string BOB_INACTIVE_STATUS='BoB Inactive';
    
    /* 
    public static void UpdateSellerOwnerBasedonBobSellerAccountManager(List<Bob__c> listBoBs ,Map<id,Bob__c> oldMap){
        set<id> ActivatedBob = new set<id>();
        set<id> InactivatedBob = new set<id>();
        //Map<String,Id> userMap = new Map<String,Id>();
        //list<Account> sellersToUpdate = new list <Account>();
        Map<String,String> mapSellerToUpdate = new Map<String,String>(); //NK:05/12/2019
        
        //populate active users
        //for(User usr: Database.query('select id,name from user where isactive=true limit 5000') ){
        //    userMap.put(usr.Name.toLowerCase(), usr.Id);
        //}
        
        //take changed status to active 
        for (Bob__c b : listBoBs){
         //   if (b.Status__c==EBH_ConstantsUtility.BOB_STATUS_ACTIVE && b.Status__c!= oldMap.get(b.Id).Status__c){
         //NK:05/12/2019: added status changed to allow only status changed. for both to Active and to Inactive.
         // Active -> Account Manager as Owner
         // Inactiv -> Integration User as Owner
         	if ( b.Status__c!= oldMap.get(b.Id).Status__c && (b.Status__c==EBH_ConstantsUtility.BOB_STATUS_ACTIVE || b.Status__c ==EBH_ConstantsUtility.BOB_STATUS_INACTIVE))
         	{
     			ActivatedBob.add(b.ID);
            }
        }
        
        if (!ActivatedBob.isEmpty()){
        	set<id> accountIds = new set<id>();
        	
        	//NK:12/03/2019:EPH-7135:fixing... AND Status__c <> :EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED ]){//NK:30/10/2018: removed seller will stay still as Integration user
            for (BoB_Seller__c bs : [select seller__c,seller__r.OwnerId,account_manager__c,active__c,status__c from Bob_seller__c where Bob__c in :ActivatedBob AND Status__c <> :EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED])
            { 
                //accountIds.add(bs.seller__c);
                if (bs.active__c) //Active to BS.Account Manager
                {
                     
                     if(String.isNotBlank(bs.Account_manager__c) && bs.Account_manager__c <> bs.seller__r.OwnerId)
                     {
                     	mapSellerToUpdate.put(bs.seller__c,bs.Account_manager__c);
                     }
                      
                }else{ //Inactive to Integeration User
                    mapSellerToUpdate.put(bs.seller__c,EBH_ConstantsUtility.INTEGRATION_USER_ID);
                }
                        
            }
            
            if (!mapSellerToUpdate.isEmpty()){
                    
                if(System.isFuture())
                {
                	updateSellerOwner(mapSellerToUpdate); 
                }else
                {
                	updateSellerOwnerAsyn(mapSellerToUpdate); 
                }
                   
            }
                
        }
    }
    */
     /*****************************************************************************************************************************
    @ Method:   updateSellerOwnerAsyn
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0006885 Hypercare - BoB Activation is not working 
	@		    moved from above to avoid cpu limit for huge sellers
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:   map of seller id and new ownerid    
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.12.2019 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    /*
    @future
    private static void updateSellerOwnerAsyn(Map<String,String> mapSellerToUpdate)
    {
    	updateSellerOwner(mapSellerToUpdate);
    } 
    
    private static void updateSellerOwner(Map<String,String> mapSellerToUpdate)
    {
    	List<Account> listSellerToUpdate = new List<Account>();
    	for(String accId : mapSellerToUpdate.keySet())
    	{
    		listSellerToUpdate.add(new Account(Id=accId,OwnerId=mapSellerToUpdate.get(accId),From_BoB__c=true));
    	}
    	
    	try {
    		//NK:16/12/2019:US-0006885: prevent account trigger to useless fire
    		EBH_AccountTriggerHandler.NO_TRIGGER_RUN  = true;  
           update listSellerToUpdate;  
		} catch(Exception ex) {
			EBH_ApexLogger.logError(new List<Exception> { ex }, 'BoBTriggerHandler','updateSellerOwnerAsyn');
		} 
    	
    	
    } 
    */
    /*****************************************************************************************************************************
    @ Method:   bobActivationCheck
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  EPH-6421 BOB MGMT. - Activate/De-activate BoB
	@		    Any other "BOB Active" BoB records AND has the same "BoB Country + BoB Vertical" should be moved to "BoB Inactive"
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<BoB__c> list of BoB , mapOld BoB
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.09.2018 / Vadhanak Voun / Created the  Method.
    @ 				: 05/06/2020 / Sovantheany Dim/ Updated methode: US-0007688 - Bugs on LTTM seller management
    @               : 14.02.2022 / Sophal Noch / US-0011283 - [P1] Managed Cohorts are not set to inactive automatically when cloned cohort is Activated
    @               : 22.04.2024 / Sovantheany Dim / US-0015106 - Deactivate the record type, Managed Cohort
    *****************************************************************************************************************************/
    /*public static void bobActivationCheck(List<BoB__c> listBoB,Map<Id,BoB__c> mapOld)
    {
        Map<String,BoB__c> mapBob = new Map<String,BoB__c>();
        Set<String> setBobCounry = new Set<String>();
        Set<String> setBobVertical = new Set<String>();
        String recTypeManagedId = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_MANAGE_RECORDTYPE).Id;
        Set<Id> setInactiveBobId = new Set<Id>();
        for(BoB__c b : listBoB)
        {	 
            //NK:23/05/2019:EPH-7522: fixed other active bob not change to inactive.
            //TH:05/06/2020: US-0007688 : add b.RecordTypeId == recTypeManagedId
            if(b.Status__c == EBH_ConstantsUtility.BOB_STATUS_ACTIVE && mapOld.get(b.Id).Status__c <> b.Status__c && b.RecordTypeId == recTypeManagedId)
            {
                setBobVertical.add(b.EBH_BOBVertical__c);
                setBobCounry.add(b.EBH_BOBCNTRY__c);
                mapBob.put(b.Id,b); 
            }else if(b.Status__c == BOB_INACTIVE_STATUS && b.Status__c != mapOld.get(b.Id).Status__c){  // 14.02.2022 / Sophal Noch / US-0011283 move inactive logic to bobActivationCheck method here
                if(isBeingDeactivated) continue; // 10.02.2022 / Sophal Noch / US-0011283 skip this method to avoid UNABLE_TO_LOCK_ROW error when this method is called from future method
                setInactiveBobId.add(b.Id);
            }
        }
         
        if(!mapBob.isEmpty())
        {	
            Set<String> setBobIds = mapBob.keySet();
            if(System.isFuture() || System.isBatch())
            {
                deactivateRelatedBoB(setBoBIds,setBobCounry,setBobVertical,recTypeManagedId);
            }else
            {
                deactivateRelatedBoB_Asyn(setBoBIds,setBobCounry,setBobVertical,recTypeManagedId);
            }
             
        }
        if(!setInactiveBobId.isEmpty()){
            // BoBSellerTriggerHandler.resetSellerFields([SELECT Seller__c FROM BoB_Seller__c WHERE Bob__c IN:setInActivedBobId AND BoB__r.RecordType.DeveloperName IN : BoBSellerTriggerHandler.SET_BOB_RTYPES]);
            if(System.isFuture() || System.isBatch()){callResetSellerFields(setInactiveBobId);}
            else{callResetSellerFields_Asyn(setInactiveBobId);} // 07.02.2022 / Sophal Noch / US-0011283 call future method to avoid cpu limit
        }
    }*/
    
    /*****************************************************************************************************************************
    @ Method:   deactivateRelatedBoB_Asyn
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0006885 Hypercare - BoB Activation is not working 
	@		    moved from above to avoid cpu limit for huge sellers
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:   map of seller id and new ownerid    
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.01.2020/ Vadhanak Voun / Created the  Method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.02.2022/ Sophal Noch / US-0011283 - [P1] Managed Cohorts are not set to inactive automatically when cloned cohort is Activated
    @               : 22.04.2024 / Sovantheany Dim / US-0015106 - comment out
    *****************************************************************************************************************************/
    /*@future
    private static void deactivateRelatedBoB_Asyn(Set<String> setBoBIds,Set<String> setBobCounry,Set<String> setBobVertical,String recTypeManagedId)
    {
    	deactivateRelatedBoB(setBoBIds,setBobCounry,setBobVertical,recTypeManagedId);
    }
    private static void deactivateRelatedBoB(Set<String> setBoBIds,Set<String> setBobCounry,Set<String> setBobVertical, String recTypeManagedId)
    {

    	// String addCondition = ' AND RecordTypeId =: recTypeManagedId';
        String addCondition = ' AND RecordTypeId =: recTypeManagedId AND Status__c =: BOB_ACTIVE_STATUS'; // 10.08.2022 / Sophal Noch / US-0013955

    	//find other active bob with same country and vertical
    	List<BoB__c> listBoBToInActive = new List<BoB__c>();
    	//TH:05/06/2020: US-0007688 : add condition for bob Managed Record type

        Set<Id> setBobId = new Set<Id>();

		for(BoB__c b : Database.query(EBH_ConstantsUtility.SOQL_BOB_BY_COUNRY_VERTICAL+addCondition))
		{
			b.Status__c = EBH_ConstantsUtility.BOB_STATUS_INACTIVE;
			listBoBToInActive.add(b);
            setBobId.add(b.Id);
		}
		if(!listBoBToInActive.isEmpty())
		{
            isBeingDeactivated = true;
		 	update listBoBToInActive;
            callResetSellerFields(setBobId); // 11.02.2022 / Sophal Noch / US-0011283 call to empty seller, calling it here instead of waiting for inactive method that can cause UNABLE_TO_LOCK_ROW error
            
		} 
    }*/

    /*****************************************************************************************************************************
    @ Method:   bobDeactivationCheck
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  US-0011008 - Clear the seller Managed fields for removed Cohort [P2] Bug - Seller and when entire Cohort is moved to status "Cohort Inactive"
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:  List<BoB__c> list of BoB , mapOld BoB
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.01.2022 / Sophal Noch / Created the  Method.
     ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.02.2022 / Sophal Noch / US-0011283 - [P1] Managed Cohorts are not set to inactive automatically when cloned cohort is Activated
    *****************************************************************************************************************************/
    // public static void bobDeactivationCheck(List<BoB__c> listBoB,Map<Id,BoB__c> mapOld){

    //     if(isBeingDeactivated) return; // 10.02.2022 / Sophal Noch / US-0011283 skip this method to avoid UNABLE_TO_LOCK_ROW error

    //     Set<Id> setInactiveBobId = new Set<Id>();
    //     for(BoB__c bob : listBoB){
    //         if(bob.Status__c == BOB_INACTIVE_STATUS && bob.Status__c != mapOld.get(bob.Id).Status__c){
    //             setInactiveBobId.add(bob.Id);
    //         }
    //     }
    //     if(!setInactiveBobId.isEmpty()){
    //         // BoBSellerTriggerHandler.resetSellerFields([SELECT Seller__c FROM BoB_Seller__c WHERE Bob__c IN:setInActivedBobId AND BoB__r.RecordType.DeveloperName IN : BoBSellerTriggerHandler.SET_BOB_RTYPES]);
    //         if(System.isFuture() || System.isBatch()){callResetSellerFields(setInactiveBobId);}
    //         else{callResetSellerFields_Asyn(setInactiveBobId);} // 07.02.2022 / Sophal Noch / US-0011283 call future method to avoid cpu limit
    //     }
    // }
    /* 
    @ Change history: 11.05.2023 / Bora Chhorn / US-0012616 - Automation to change Cohort Seller Status to Inactive when Cohort Status is changed to "Inactive"
    @               : 22.04.2024 / Sovantheany Dim / US-0015106 -Comment out
    */
    /*private static void callResetSellerFields(Set<Id> setBoBId){
        List<BoB_Seller__c> listInactiveBs = new List<BoB_Seller__c>();
        Set<Id> setAccId = new Set<Id>();

        
        // 15.11.2023 / Sophal Noch / US-0014353 : no need this anymore

        //BR-11-05-23-US-0012616
       // List<BoB_Seller__c> listInactiveBsLTTM = new List<BoB_Seller__c>(); 

        // RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c',BOBSELLER_LTTM_RECORDTYPE);
        // Set<Id> newSetBobIds = new Set<Id>();

        //for(BoB_Seller__c bs : [Select Seller__c,BoB__c, RecordTypeId From BoB_Seller__c Where BoB__c IN: setBoBId]){
           // listInactiveBs.add(bs);
           // setAccId.add(bs.Seller__c);
            //BR-11-05-23-US-0012616
           // if(bs.RecordTypeId == bobSellerRecordTypeLTTM.Id){
            //    bs.Status__c = BOBSELLER_INACTIVE_STATUS;
            //bs.Deactivation_Reason__c = 'Cohort Inactivated';
           //     listInactiveBsLTTM.add(bs);
           //     newSetBobIds.add(bs.BoB__c);
            //}
        //}

        

        if(!BatchCohortAction.isRunning){ //  15.11.2023 / Sophal Noch / US-0014353 : If Batch BatchCohortAction is running, It already handles clearing account fields, so do not need logic below.
            
            for(BoB_Seller__c bs : [Select Seller__c,BoB__c, RecordTypeId From BoB_Seller__c Where BoB__c IN: setBoBId]){
                listInactiveBs.add(bs);
                setAccId.add(bs.Seller__c);
            }
            
            BoBSellerTriggerHandler.resetSellerFields(listInactiveBs, setAccId, false);
        }
       
        
         // 15.11.2023 / Sophal Noch / US-0014353 : no need this anymore

        //BR-11-05-23-US-0012616
       // if(!listInactiveBsLTTM.isEmpty()){
         //  Database.update(listInactiveBsLTTM, false); 
        //}
        //BR-11-05-23-US-0012616

        
    }*/

    /*TH: US-0015106 -Comment out
    @future
    private static void callResetSellerFields_Asyn(Set<Id> setBoBId){
        callResetSellerFields(setBoBId);
    }*/

	/*****************************************************************************************************************************
    @ Method:   bobCreationDuplicateCheck
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  EPH-6482 BOB MGMT. - Prevent from creating a NEW BOB which is a duplicate of an exiistng one.
	@		     When a user clcks on new and fills out fields and then clicks on save we need to do a check if there is already a BOB with the same Country + Vertical combination in stage DRAFT, SUBMITTED or ACTIVE
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter	:   List<BoB__c> list of BoB 
    @ Trigger	:	Before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.09.2018 / Vadhanak Voun / Created the  Method.
    @				: 11/03/2019 / Vadhanak Voun / EPH-7218 BOB Object - Bo Owner was able to create two Drafts for same BOB
    @				: 06/04/2020/ Vadhanak Voun/ US-0007426 - LTTM Bug Validation Error Conflicts
    @							: no douplicate check for LTTM
    @               : 21/04/2020/ LoumAng SENG/ US-0007430 - [LTTM] - Create /Amend fields and Page Layout changes
    @               : 02/07/2021/ Mony Nou/ US-0009839 - [Pro-Trader] - change Cohort Seller-Facing Name field to accept "non-unique" values
    @               : 06/06/2022 / Sophal Noch / US-0011827 - Managed Country is displayed for Austria AT Cohort as UNKNOWN on Seller Record
    *****************************************************************************************************************************/
    public static void bobCreationDuplicateCheck(List<BoB__c> listBoB,Map<Id,BoB__c> mapOld)
    {
    	Set<String> setBoBIds = new Set<String>();
    	Set<String> setBoBCountry = new Set<String>();
        Set<String> setBoBVertical = new Set<String>();
        Set<String> setBoBLttmGroup = new Set<String>();
        Set<String> setBoBCampCode = new Set<String>(); //MN-02072021
        Set<String> setBoBRecId = new Set<String>();
    	Map<String,BoB__c> mapBoB = new Map<String,BoB__c>(); //mapping for addError
    	Boolean isNew = (mapOld==null);
        String recTypeLTTMId = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE).Id;
        //String recTypeManageId = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_MANAGE_RECORDTYPE).Id; //TH:US-0015106:comment out
        Set<String> setLocalDupCheck = new Set<String>();// in case mass insert with same country,vertical,draft
        Set<String> setLocalDupCheckLTTM = new Set<String>();// in case mass insert with same country,vertical,group fro lttm
    	for(BoB__c b: listBoB)
    	{
            //LoumAng:21/04/2020:US-0007430: Update validation for LTTM record type
            if((isNew && (
            //(b.RecordTypeId == recTypeManageId && String.isNotBlank(b.EBH_BOBCNTRY__c) && String.isNotBlank(b.EBH_BOBVertical__c) && String.isBlank(b.Source_BoB__c) ) || //TH:US-0015106:comment out , Managed_Cohort record type no logner use
            //||(b.RecordTypeId == recTypeLTTMId && String.isNotBlank(b.EBH_BOBCNTRY__c) && String.isNotBlank(b.EBH_BOBVertical__c) && String.isNotBlank(b.LTTM_Group__c)))) //MN-02072021 - No longer use uniqueness on LTTM_Group__c
            (b.RecordTypeId == recTypeLTTMId && String.isNotBlank(b.EBH_BOBCNTRY__c) && String.isNotBlank(b.EBH_BOBVertical__c) && String.isNotBlank(b.Campaign_Code__c)))) //MN-02072021
            //|| !isNew && (b.EBH_BOBCNTRY__c <> mapOld.get(b.Id).EBH_BOBCNTRY__c || b.EBH_BOBVertical__c <> mapOld.get(b.Id).EBH_BOBVertical__c || b.LTTM_Group__c <> mapOld.get(b.Id).LTTM_Group__c)) //MN-02072021 - No longer use uniqueness on LTTM_Group__c
            || !isNew && (b.EBH_BOBCNTRY__c <> mapOld.get(b.Id).EBH_BOBCNTRY__c || b.EBH_BOBVertical__c <> mapOld.get(b.Id).EBH_BOBVertical__c || b.Campaign_Code__c <> mapOld.get(b.Id).Campaign_Code__c)) //MN-02072021
    		{
                setBoBCampCode.add(b.Campaign_Code__c); //MN-02072021
                //setBoBLttmGroup.add(b.LTTM_Group__c); //MN-02072021 - No longer use uniqueness on LTTM_Group__c
                setBoBCountry.add(b.EBH_BOBCNTRY__c);
                setBoBVertical.add(b.EBH_BOBVertical__c);
                setBoBRecId.add(b.RecordTypeId);
                //mapBoB.put(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+b.LTTM_Group__c,b);
                //mapBoB.put(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+(recTypeManageId==b.RecordTypeId?'':b.LTTM_Group__c)+'_'+b.RecordTypeId,b); //MN-02072021 - No longer use uniqueness on LTTM_Group__c
                //mapBoB.put(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+(recTypeManageId==b.RecordTypeId?'':b.Campaign_Code__c)+'_'+b.RecordTypeId,b); //MN-02072021 // TH:US-0015106:comment out , Managed_Cohort record type no logner use
                mapBoB.put(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+b.Campaign_Code__c+'_'+b.RecordTypeId,b);
                //in case mass insert with same country,vertical,draft
                 
                //TH:US-0015106:comment out , Managed_Cohort record type no logner use
    			/*if(isNew && b.Status__c==EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT && b.recordTypeId==recTypeManageId)
    			{
    				if(setLocalDupCheck.contains(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+b.Status__c))
    				{
    					b.addError(System.Label.ErrorBoBDuplicate+'.');
    				}    				
    				setLocalDupCheck.add(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+b.Status__c);
                }*/
                //NK:30/04/2020 local validation for lttm
                if(isNew && b.recordTypeId==recTypeLTTMId)
                {
                    //if(setLocalDupCheckLTTM.contains(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+b.LTTM_Group__c)) //MN-02072021 - No longer use uniqueness on LTTM_Group__c
                    if(setLocalDupCheckLTTM.contains(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+b.Campaign_Code__c)) //MN-02072021
    				{
                        // String errMsg = System.Label.Error_LTTM_Validation+' ' +b.LTTM_Group__c+' already exists.'; //MN-02072021 - No longer use uniqueness on LTTM_Group__c
                        String errMsg = System.Label.Error_LTTM_Validation_2+' ' +b.Campaign_Code__c+' already exists.'; //MN-02072021
                        // errMsg = errMsg.replace('{!country}',EBH_ConstantsUtility.MAP_CODE_TO_COUNTRY.get(b.EBH_BOBCNTRY__c)).replace('{!vertical}',b.EBH_BOBVertical__c);
                        errMsg = errMsg.replace('{!country}',BatchFixBoBAccountManager.MAP_CODE_TO_COUNTRY.get(b.EBH_BOBCNTRY__c)).replace('{!vertical}',b.EBH_BOBVertical__c); // 06.06.2022 / Sophal Noch / US-0011827
    					b.addError(errMsg);
    				}    				
    				//setLocalDupCheckLTTM.add(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+b.LTTM_Group__c); //MN-02072021 - No longer use uniqueness on LTTM_Group__c
                    setLocalDupCheckLTTM.add(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+b.Campaign_Code__c); //MN-02072021
                }
    			setBoBIds.add(b.Id);
    		}
    		
    	}
    	
    	Set<String> bobStatusDupCreateCheck = isNew? new Set<String>{EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_ConstantsUtility.BOB_STATUS_SUBMITTED,EBH_ConstantsUtility.BOB_STATUS_ACTIVE}
                                             : new Set<String>{EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_ConstantsUtility.BOB_STATUS_ACTIVE}; //prevent new on same draft, for update to active, the existing same actvive will become inactive  
    	if(!mapBoB.isEmpty())
    	{
            //TH:US-0015106:comment out , Managed_Cohort record type no logner use
            //MN-02072021
            //String SOQL_BOB_BY_COUNTRY_VERTICAL = 'Select Id,RecordTypeId,Campaign_Code__c,EBH_BOBCNTRY__c,EBH_BOBVertical__c,Name,OwnerId,Owner.Name From BoB__c Where ((EBH_BOBCNTRY__c IN:setBoBCountry AND EBH_BOBVertical__c IN:setBoBVertical AND Status__c IN:bobStatusDupCreateCheck AND recordtypeId =:recTypeManageId) OR (EBH_BOBCNTRY__c IN:setBoBCountry AND EBH_BOBVertical__c IN:setBoBVertical AND Campaign_Code__c <> null AND Campaign_Code__c IN:setBoBCampCode AND recordtypeId =:recTypeLTTMId))';
            String SOQL_BOB_BY_COUNTRY_VERTICAL = 'Select Id,RecordTypeId,Campaign_Code__c,EBH_BOBCNTRY__c,EBH_BOBVertical__c,Name,OwnerId,Owner.Name From BoB__c Where  (EBH_BOBCNTRY__c IN:setBoBCountry AND EBH_BOBVertical__c IN:setBoBVertical AND Campaign_Code__c <> null AND Campaign_Code__c IN:setBoBCampCode AND recordtypeId =:recTypeLTTMId)';
            
            //LoumAng:21/04/2020:US-0007430: Update validation for LTTM record type
            for(BoB__c b: Database.query(SOQL_BOB_BY_COUNTRY_VERTICAL +' AND Id NOT IN :setBoBIds AND RecordTypeId IN :setBoBRecId')) //NK:04/06/2019: fixed duplicate not check when update country/vertical on active bob
            {
                
                String errMsg = '';
                //TH:US-0015106:comment out , Managed_Cohort record type no logner use
                /*if(b.RecordTypeId==recTypeManageId){
                    errMsg = System.Label.ErrorBoBDuplicate+'...';
                    
                }else{*/
                    
                    // errMsg = System.Label.Error_LTTM_Validation+' ' +b.LTTM_Group__c+' already exists.'; //MN-02072021 - No longer use uniqueness on LTTM_Group__c
                    errMsg = System.Label.Error_LTTM_Validation_2+' ' +b.Campaign_Code__c+' already exists.'; //MN-02072021
                    // errMsg = errMsg.replace('{!country}',EBH_ConstantsUtility.MAP_CODE_TO_COUNTRY.get(b.EBH_BOBCNTRY__c)).replace('{!vertical}',b.EBH_BOBVertical__c);
                    errMsg = errMsg.replace('{!country}',BatchFixBoBAccountManager.MAP_CODE_TO_COUNTRY.get(b.EBH_BOBCNTRY__c)).replace('{!vertical}',b.EBH_BOBVertical__c);  // 06.06.2022 / Sophal Noch / US-0011827
                //}

                //TH:US-0015106:comment out , Managed_Cohort record type no logner use
                //String key = b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+(recTypeManageId==b.RecordTypeId?'':b.Campaign_Code__c)+'_'+b.RecordTypeId; //MN-06072021-key to check with mapBoB to avoid error of null pointer
                String key = b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+b.Campaign_Code__c+'_'+b.RecordTypeId; //MN-06072021-key to check with mapBoB to avoid error of null pointer
                // mapBoB.get(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+(recTypeManageId==b.RecordTypeId?'':b.LTTM_Group__c)+'_'+b.RecordTypeId).addError(errMsg); //MN-02072021 - No longer use uniqueness on LTTM_Group__c
                // mapBoB.get(b.EBH_BOBCNTRY__c+'_'+b.EBH_BOBVertical__c+'_'+(recTypeManageId==b.RecordTypeId?'':b.Campaign_Code__c)+'_'+b.RecordTypeId).addError(errMsg); //MN-02072021
                if (mapBoB.containsKey(key)) mapBoB.get(key).addError(errMsg); //MN-02072021
                
            }
            
        }
    }
    /*****************************************************************************************************************************
    @ Method:   validationLLTMbobBeforeActivated
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  US-0007697 - [LTTM] Validations before activating the Light Touch Category Cohort
	@		     AC2.As Any user (with permission "BoB Category Lead" or Mid Focus BoB Lead"
	@ Select the LTTM Cohort created in AC1
	@ Add Cohort Sellers, Do not select categories, Do not create Actions and attempt to change the status from "Draft" to "Cohort Active" (API Name - BoB Active).
	@ System Validation to throw the below error when criteria is met
	@ If below criteria is met
	@ Bob__r.Status__c = 'BoB Active' and Bob__r.RecordType.DeveloperName = 'Light_Touch_Category_Cohort' and Bob__r.Managed_Type="LTTM Managed" and
	@ Count of "BoB_Category__c" = 0 and Count of Action__c = 0 (Check if at least 1 "Catagory Selection" and 1 "Action Creation" is completed )
	@ Error Message
	@ "Please click "Category Selection" to select the category and click "Create Actions" to create recommended Actions for the sellers before activating the cohort"
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter	:   List<BoB__c> listBoB,Map<Id,BoB__c> mapOld
    @ Trigger	:	Before Updated
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.06.2020 / Sovantheany Dim / Created the  Method.
    @               : 14.05.2024 / Sophal Noch / US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
    @               :  10.03.2025 / Vimean Heng / US-0016616 - 3. Eliminate manual BOB category selection validation for Activating the PT Cohort
    *****************************************************************************************************************************/
    public static void validationLLTMbobBeforeActivated(List<BoB__c> listBoB,Map<Id,BoB__c> mapOld)
    {
    	String recTypeLTTMId = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE).Id;
    	Map<String,BoB__c> mapbob = new Map<String,BoB__c>();
    	for(BoB__c newbob : listBoB){
    		BoB__c oldBob = mapOld.get(newbob.Id);
            if(newbob.RecordTypeId == recTypeLTTMId && newbob.Status__c <> oldBob.Status__c && newbob.Status__c==BOB_ACTIVE_STATUS && newbob.Managed_Type__c == BOB_MNG_TYPE_PRO_TRADER){ //  14.05.2024 / Sophal Noch / US-0015200
    			mapbob.put(newbob.Id,newbob);
    		}
    	}
    	if(mapbob.isEmpty()) return;
    	Set<String> sBobId = mapbob.keySet();
    	Map<String,Integer> mapBobContaintAction = new Map<String,Integer>();
    	for(BoB_Seller__c bobSeller :Database.query(SOQL_BOB_SELLER+' where BoB__c IN: sBobId')){
    		Integer actionNumber = mapBobContaintAction.containsKey(bobSeller.BoB__c)?mapBobContaintAction.get(bobSeller.BoB__c):0;
    		if(!bobSeller.Actions__r.isEmpty()){
    			actionNumber++;
    		}
    		mapBobContaintAction.put(bobSeller.BoB__c,actionNumber);
    	}
        //  10.03.2025 / Vimean Heng / US-0016616 / No Require Category for PT Cohort
        /*
    	for(BoB__c bob :Database.query(SOQL_BOB_With_Category+' where id IN: sBobId')){
            BoB__c newbob = mapbob.get(bob.Id);
            //  14.05.2024 / Sophal Noch / US-0015200 : add isProTrader check in condition below
            if((bob.BoB_Categories__r.isEmpty() && newbob != null && CohortActionController.isProTrader(newbob)) || !mapBobContaintAction.containsKey(bob.Id) || (mapBobContaintAction.containsKey(bob.Id) && mapBobContaintAction.get(bob.Id) == 0)){
                newbob.addError(System.Label.error_before_activate);
            }
    	}
        */
    }
    	 

}