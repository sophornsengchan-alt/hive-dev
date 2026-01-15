/*********************************************************************************************************************************
@ Class:          EBH_CampaignTriggerHandler
@ Version:        1.0
@ Author:         NEHA LUND 
@ Purpose:        Handler Class for Campaign Trigger
                  EPH-106 : KPI Inheritance
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.06.2017 / NEHA LUND / Created the class.
@ Change history: 04.07.2022 /Chetra Sarlom/ US-0007031 - Deactivate triggers
@ Change history : 20.05.2022/ Sophal Noch / US-0011717 - Enable new column "Campaign Related Seller Details" in the Target List to create/update Key metrics in campaign members
@ Change history: 25.07.2022 / SRONG TIN / US-0012126  - CPU Limit error when user update Campaign stage to "Stopped"
@                 02.12.2024 / vadhanak voun /US-0015501 - Campaign - Feedback bug fixes
*********************************************************************************************************************************/
public without sharing class EBH_CampaignTriggerHandler {

    // 20.05.2022 / Sophal Noch / US-0011717 : using "order by id desc" to make sure latest target seller is on top of the list
    private static final String CTH_TARGETEDSELLERQUERY = 'SELECT Id,Priority__c,Campaign_Related_Seller_Details__c, EBH_Seller__c, EBH_SellerList__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c WHERE EBH_SellerList__c in: sellerMapId Order By Id desc';
    //SRONG TIN / 25.07.2022 : US-0012126
    public static Integer TASK_BATCH_LIMIT = Integer.valueOf(Label.BATCH_TASK_DELETEUPDATE_LIMIT_SIZE);
    public final static String CMRC_EXECUTION     = 'Execution';
    public final static String CMRC_COMPLETED     = 'Completed';

    //NK:02/12/2024:US-0015501 
    private final static String STATUS_CAMP_IN_DEV = 'Preparation';//     label: Campaign in Development		api: Preparation
    /*****************************************************************************************************************************
    @ Method:         createCampaignKPIRecords
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Creates Campaign KPIs roll downs to Child Campaigns from the associated Parent Campaigns        
                      - Actual
                      - KPI
                      - Campaign - mapped to the new campaign record
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Campaigns:      Campaigns from the trigger scope
                      CampaignOldMap: Campaigns old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.06.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static void createCampaignKPIRecords(List<Campaign> Campaigns, Map<Id, Campaign> CampaignOldMap) {
        
        Set<Id> parentIds = new Set<Id>();    //distinct parent ids of the Campaigns in trigger scope
        Map<Id, Campaign> parents = new Map<Id, Campaign>();                //list of distinct parents from parentIds
        //Only process campaign records where parent is populated
        List<Campaign> campaignRecordsToBeProcessed = new List<Campaign>();
        
        //loop through trigger scope
        for(Campaign camp : Campaigns) { 
            //get distinct parent ids from trigger scope Campaigns and populate parentIds 
            if(hasRollupChanged(camp, CampaignOldMap)) {              
                Id pId = camp.ParentId;
                if(!String.isBlank(pId)) {
                    parentIds.add(pId); 
                    campaignRecordsToBeProcessed.add( camp);
                }
            }
        }
        
        //fetch the parents and the childs Campaign KPIS
        for( Campaign camp: Database.query(EBH_ConstantsUtility.CTH_PARENTCHILDQUERY)){
            parents.put( camp.id, camp);
        }
        
        //to insert Campaign KPI records for new campaign records being created
        List<EBH_CampaignKPI__c> clonedCampaignKPIRecords = new List<EBH_CampaignKPI__c>();
        EBH_CampaignKPI__c cloneKPI = new EBH_CampaignKPI__c();
        
        //fetch the childs and sellers of parents from parentIds and populate parentChildMap
        for(Campaign camp : campaignRecordsToBeProcessed) {
            if(parents.containsKey(camp.ParentId)) {
                for(EBH_CampaignKPI__c ccamp : parents.get(camp.ParentId).EBH_CampaignKPIs__r) {
                    cloneKPI = ccamp.clone(false, false, false, false);
                    cloneKPI.EBH_Campaign__c = camp.id;
                    clonedCampaignKPIRecords.add( cloneKPI);
                }
            }
        }
        
        //update parents
        try {
            Database.insert(clonedCampaignKPIRecords);
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                    EBH_ConstantsUtility.CTH_CLASS, EBH_ConstantsUtility.CTH_CKPIMETHOD);
        }
    }
     /*****************************************************************************************************************************
    @ Method:         updateCampaignDates
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Creates Campaign KPIs roll downs to Child Campaigns from the associated Parent Campaigns        
                      - Actual
                      - KPI
                      - Campaign - mapped to the new campaign record
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Campaigns:      Campaigns from the trigger scope
                      CampaignOldMap: Campaigns old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.06.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static void updateCampaignDates(List<Campaign> campRecords, Map<Id, Campaign> CampaignOldMap) {
         
         List<Campaign> campaigns = new List<Campaign>();
         for( Campaign camp: campRecords){
             
             if( (campaignOldMap != null && camp.Status != campaignOldMap.get(camp.id).Status) ||
                 (!String.isBlank(camp.Status) && campaignOldMap == null ) ){
                 //if status is Submitted, then Date Submitted should be populated as today
                 if( camp.Status.equalsIgnoreCase(EBH_ConstantsUtility.CAMP_SUBMITTED) ){
                     camp.EBH_DateSubmitted__c = Date.Today();
                     
                 } else
                 if( camp.Status.equalsIgnoreCase(EBH_ConstantsUtility.CAMP_FEASIBILITY ) ){
                     //Converted Date should be captured, when the status is Feasibility
                     camp.EBH_DateConvertedtoCampaign__c = Date.Today();
                 }
                 else 
                 if ( camp.Status.equalsIgnoreCase(EBH_ConstantsUtility.CAMP_PREPARATION ) ) {
                     //Date Approved should be populated as Today
                     camp.EBH_DateApproved__c = Date.Today();
                 }
                 campaigns.add( camp );
             }
         }
     }
    /*****************************************************************************************************************************
    @ Method:         hasRollupChanged
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Check and returns true if any of the following fields has changed in Campaign:
                        - EBH_Targeted__c
                        - EBH_Sent__c
                        - EBH_Reached__c
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      camp:           Campaign to check field(s) change for
                      CampaignOldMap: Campaign old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
                      Targeted
                      Sent
                      Reached
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.06.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static Boolean hasRollupChanged(Campaign camp, Map<Id, Campaign> CampaignOldMap) {
        
        Campaign oldcamp = CampaignOldMap != Null ? CampaignOldMap.get(camp.Id) : camp;
        
        return   camp.ParentId != oldcamp.ParentId ||
                 camp.EBH_Targeted__c != oldcamp.EBH_Targeted__c ||
                 camp.EBH_Sent__c != oldcamp.EBH_Sent__c ||
                 camp.EBH_Reached__c != oldcamp.EBH_Reached__c ||
                 CampaignOldMap == null; 
    } 
     /*****************************************************************************************************************************
    @ Method:         updateControlGroupOnSellerList 
    @ Version:        1.0
    @ Author:         Neha Lund
    @ Purpose:        EPH-5854: Check and returns true if control group has changed in old Campaign passed in param
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      campRecord:           Campaign to check field(s) change for
                      CampaignOldMap: Campaign old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2018 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static void updateControlGroupOnSellerList (List<Campaign> campaigns, Map<Id, Campaign> campaignOldMap) {
        
        Set<ID> campaignIds = new Set<ID>();
        List<EBH_Filter__c> filterRecords = new List<EBH_Filter__c>();
        EBH_Filter__c filter = new EBH_Filter__c ();
        
        for(Campaign camp: campaigns){
            
            if(hasControlGroupChanged(camp, campaignOldMap)){
                filter = new EBH_Filter__c(Id = camp.EBH_SellerList__c);
                filter.EBH_ProposedControlGroupSize__c = camp.EBH_ControlGroupSize__c;
                
                //EPH-5731 - to copy campaign Id on Filter when seller list is attached to a campain
                filter.EBH_Campaign__c = camp.Id;
                filterRecords.add( filter);
            }
        }

        if( !filterRecords.isEmpty()){
            
            Database.update(filterRecords, false);
            
            
        }
    }
    /*****************************************************************************************************************************
    @ Method:         hasControlGroupChanged
    @ Version:        1.0
    @ Author:         Neha Lund
    @ Purpose:        EPH-5854: Check and returns true if control group has changed in old Campaign passed in param
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      campRecord:           Campaign to check field(s) change for
                      CampaignOldMap: Campaign old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2018 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static Boolean hasControlGroupChanged (Campaign campRecord, Map<Id, Campaign> CampaignOldMap) {
        
        Campaign oldcampRecord = CampaignOldMap != Null ? CampaignOldMap.get(campRecord.Id) : campRecord;
        return (campRecord.EBH_ControlGroupSize__c != oldcampRecord.EBH_ControlGroupSize__c || 
        campRecord.EBH_SellerList__c != oldcampRecord.EBH_SellerList__c || 
        (CampaignOldMap == null )) &&  campRecord.EBH_SellerList__c != null ;
    }
    
    /*****************************************************************************************************************************
    @ Method:         createCampaignMemberRecords
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL 
    @ Purpose:        Create CampaignMembers on insert operation of Campaign with Seller List
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Campaigns:      Campaigns from the trigger scope
                      CampaignOldMap: Campaigns old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.06.2017 / ASHISH BARANWAL / Created the  Method.
    @				: 29.12.2018 / Vadhanak Voun / EPH-6825 Add /Delete Multiple Seller Lists to Outreach
    @				AC4: Given that I am any User
    @				When I go to Outreach record and channel = AM Outreach
	@				When I press on Refresh Members button.
	@				Given that Campaign members > 0
	@				Then:
	@					1. Update all Campaign Members with existing response code < 20 or empty to response code = 22
	@					2. Compare new Seller List with existing campaign members. If sellerlist.businessname exists in campmember.contact.account -> if
	@						campmember.response code = 22, then set it to 10; else skip
	@					3. Upload Campaign Members from new Target List, set Response code to 10
    *****************************************************************************************************************************/
    public static void createCampaignMemberRecords(List<Campaign> Campaigns) {
        
        Set<Id> accountIds = new Set<Id>();    //distinct parent ids of the Campaigns in trigger scope
        Set<Id> campaignIds = new Set<Id>();            //distinct account ids of the targetedSellerList in trigger scope
        Map<Id, Campaign> sellerIdCampaignMap = new Map<Id, Campaign>();            //list of seller ids and campaigns
        //targeted seller list
        List<EBH_TargetedSeller__c> targetedSellerNewList = new List<EBH_TargetedSeller__c>();
        //targeted seller query result from the seller list
        List<EBH_TargetedSeller__c> targetedSellerQueryList = new List<EBH_TargetedSeller__c>();
        Map<Id,CampaignMember> campaignMemberMap = new Map<Id,CampaignMember>();    //list of CampaignMember to insert
        Map<Id, Account> accountMap = new Map<Id, Account>();    //account map
        //map of seller list id and list of targeted seller 
        Map<Id,List<EBH_TargetedSeller__c>> sellerListTargetedSellerMap = new Map<Id,List<EBH_TargetedSeller__c>>();
        //map of seller list id and list of contacts
        Map<Id,List<AccountContactRelation>> sellerListContactMap = new Map<Id,List<AccountContactRelation>>();    
        Set<Id> sellerMapId = new Set<Id>();
        List<CampaignMember> campaignMemberListToDelete = new List<CampaignMember>();    //list of CampaignMember to delete
        //double campaignControlSize = 0;
        
        //loop through trigger scope
        //NK:Disabled:29/12/2018: single lookup field, EBH_SellerList__c no longer use, use multiple SellerList instead (EPH-6825)
//        for(Campaign campaignRecords : Campaigns) { 
//            if(CampaignOldMap == null || (CampaignOldMap != null && campaignRecords.EBH_SellerList__c != 
//                            CampaignOldMap.get(campaignRecords.Id).EBH_SellerList__c)){
//                campaignIds.add(campaignRecords.Id);
//                sellerIdCampaignMap.put(campaignRecords.EBH_SellerList__c,campaignRecords);
//                
//            
//            }
//        }
		Map<Id,Campaign> mapCampaigns = new Map<Id,Campaign>();
		for(Campaign c: Campaigns)
		{
			mapCampaigns.put(c.Id,c);
		}
		campaignIds = mapCampaigns.keySet();
        for(Campaign_Targeting__c ct : Database.query(EBH_ConstantsUtility.SOQL_CAMP_TARGET_SELLERLIST + ' Where Campaign__c IN: campaignIds'))
        {
        	sellerIdCampaignMap.put(ct.Seller_List__c,mapCampaigns.get(ct.Campaign__c));
        }
        
        
        
        //targeted seller query result from the seller list
        sellerMapId = sellerIdCampaignMap.keySet();
        // targetedSellerQueryList = Database.query(EBH_ConstantsUtility.CTH_TARGETEDSELLERQUERY);
        targetedSellerQueryList = Database.query(CTH_TARGETEDSELLERQUERY); // 20.05.2022 / Sophal Noch / US-0011717
        
        System.debug('campaignIds: ' + campaignIds);
         System.debug('targetedSellerQueryList: ' + targetedSellerQueryList);
        
        

        //Map<Id,EBH_TargetedSeller__c> resetExitCode = new MAp<Id,EBH_TargetedSeller__c>();
         
        //to get sellerListMap and sellerListTargetedSellerMap
        for(EBH_TargetedSeller__c targetedSellerRecord : targetedSellerQueryList) {
           
        
            accountIds.add(targetedSellerRecord.EBH_Seller__c);
            if(sellerListTargetedSellerMap.containsKey(targetedSellerRecord.EBH_SellerList__c)){
                sellerListTargetedSellerMap.get(targetedSellerRecord.EBH_SellerList__c).add(targetedSellerRecord);
            } else {
                targetedSellerNewList.add(targetedSellerRecord);
                sellerListTargetedSellerMap.put(targetedSellerRecord.EBH_SellerList__c,targetedSellerNewList);
            }
            
        }
        
         
         //NK:29/12/2018: disabled 'delete batch'
        //call EBH_DeleteCampaignMemberBatch batch class to delete the existing campaignmembers
        //EBH_DeleteCampaignMemberBatch DCMBatch = new EBH_DeleteCampaignMemberBatch(accountIds, campaignIds, sellerListTargetedSellerMap, sellerIdCampaignMap);
        //Database.executeBatch(DCMBatch,200);
        
        //batch create new
        System.debug('AccountIds : ' + accountIds);
        System.debug('sellerListTargetedSellerMap : ' + sellerListTargetedSellerMap);
        EBH_InsertCampaignMemberBatch cmBatch = new EBH_InsertCampaignMemberBatch(accountIds, campaignIds, sellerListTargetedSellerMap, sellerIdCampaignMap);//sellerList -> Camp
        //scope 200
        Database.executeBatch(cmBatch,200);
        
    }  

    /*****************************************************************************************************************************
    @ Method:         updatePrioritiesInChildCampaign
    @ Version:        1.0
    @ Author:         DEEPAK MAZUMDAR
    @ Purpose:        Updates the following on all child campaign records:
                            - EBH_Priorities__c
                      [EBH] (EPH-2546) : Priority Update from parent campaign                            
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    Campaigns:      Campaigns from the trigger scope
                    CampaignOldMap: Campaigns old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.06.2017 / DEEPAK MAZUMDAR / Created the  method.
                      05.09.2017 / ASHISH BARANWAL / Updated the method.  
    *****************************************************************************************************************************/
    public static void updatePrioritiesInChildCampaign(List<Campaign> Campaigns, 
                                                       Map<Id, Campaign> CampaignOldMap, 
                                                       string TriggerContext) {
                                                       
        /*
        Set<Id> parentIds               = new Set<Id>();                    //parent campaign ids in trigger scope
        Set<Id> parents             = new Set<Id>();                    //campaign ids in trigger scope                                                    
        Map<Id, Campaign> ParentIdCampaignMap   = new Map<Id, Campaign>();  //map of parent campaign id and campaign
       
        for(Campaign c: campaigns){
            parents.add(c.ParentId);
        }
        
        //query all child campaigns
        parentIdCampaignMap =new Map<ID, campaign>((List<campaign>)Database.query(EBH_ConstantsUtility.CTH_CCRQUERY));
        
        
                                            
        //loop through campaigns to get parent campaign ids from trigger scope
        for(Campaign camp : Campaigns) {
            parentIds.add(camp.Id);
            //assign parent name if recordtype is programme
            if( camp.RecordTypeId == EBH_ConstantsUtility.CampaignProgrammeRTId 
                                && parentIdCampaignMap.containskey(camp.parentId)) {
                
                camp.EBH_StrategicPriority__c  = parentIdCampaignMap.get(Camp.ParentId).Name;
            }
            else if((camp.RecordTypeId != EBH_ConstantsUtility.CampaignProgrammeRTId 
                   || camp.RecordTypeId != EBH_ConstantsUtility.StrategicPriorityRTId)
                   && parentIdCampaignMap.containskey(camp.parentId)) {
                camp.EBH_StrategicPriority__c  = parentIdCampaignMap.get(Camp.ParentId).EBH_StrategicPriority__C;
            }
        } */
        
    }
    
    /*****************************************************************************************************************************
    @ Method:         updatePrioritiesInChildCampaign
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Updates the following on all child campaign records:
                      [EBH] (EPH-2546) : Priority Update from parent campaign
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    Campaigns:      Campaigns from the trigger scope
                    CampaignOldMap: Campaigns old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.09.2017 / ASHISH BARANWAL / Created the method.  
    *****************************************************************************************************************************/
    public static void updateChildCampaigns(List<Campaign> Campaigns, Map<Id, Campaign> CampaignOldMap){
       
       /*
        Set<Id> parentIds               = new Set<Id>();   
        Set<Id> parents             = new Set<Id>();   
        for(Campaign c: campaigns){
            parents.add(c.ParentId);
        }
        Map<Id, Campaign> ParentIdCampaignMap   = new Map<Id, Campaign>();  //map of parent campaign id and campaign
       
        //query all child campaigns
        parentIdCampaignMap =new Map<ID, campaign>((List<campaign>)Database.query(EBH_ConstantsUtility.CTH_CCRQUERY));
                                                
        //loop through campaigns to get parent campaign ids from trigger scope
        for(Campaign camp : Campaigns) {
            parentIds.add(camp.Id);
        }
                                                             
        List<Campaign> updateCamps = new List<campaign>();
        //fetch the childs and parents based on parent id's
        for(Campaign oCamp : Database.query(EBH_ConstantsUtility.CTH_PARENTCAMPPRIORITYQUERY)) {
            //assign parent Strategic Priority if recordtype is not programme or strategic campaign
            if((ocamp.RecordTypeId != EBH_ConstantsUtility.CampaignProgrammeRTId 
             && ocamp.RecordTypeId != EBH_ConstantsUtility.StrategicPriorityRTId)) {
                
                ocamp.EBH_StrategicPriority__c  = oCamp.Parent.EBH_StrategicPriority__c;
                updateCamps.add(oCamp);
            }
        }
        try {
            Database.update(updateCamps);
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.CTH_CLASS, EBH_ConstantsUtility.CTH_UCC);
        }
        */
    }
	
	/*****************************************************************************************************************************
    @ Method:         validateStatus
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        EPH-6636 Error message when changing status of a campaign
    @                  Given that I am a Standard User or GCX super user.
	@					When I go to a Campaign record.
	@					When I try to change a status of a campaign to anything than Brief Submitted.
	@					Regardless of current campaign status, I get an error message, saying "As a Standard User/GCX super user" you do not have permissions to change campaign status. Please contact your Country Marketing Lead."
	@					Trigger: before update
    @ Parameter:    Campaigns:      Campaigns from the trigger scope
    @                CampaignOldMap: Campaigns old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.11.2018 / Vadhanak Voun / Created the method.  
    @				  11.12.2018 / Vadhanak Voun /EPH-6841: for recordtype outreach
    @				  12.12.2018/ Vadhanak Voun/ EPH-6636 CR:		
    @						AC1:
	@						Given that I am a Marketing User or Business User
	@						When I go to ANY Campaign record
	@						I can change a status of a Campaigns to any status
	@						
	@						AC2:
	@						Given that I am a Standard User or GCX Super User
	@						When I go to Campaign Record except Outreach record
	@						Then try to change a status
	@						Then I get "As a Standard User/GCX super user" you do not have permissions to change campaign status. Please contact your Country Marketing Lead."
	@						
	@						AC3:
	@						Given that I am a Standard User
	@						When I go to Campaign Record: Outreach
	@						And Outreach channel = AM Outreach
	@						Then I am able to change a status of Campaign (Outreach record) to any status
	@						
	@						AC4:
	@						Given that I am GCX Super User
	@						When I go to Campaign Record: Outreach
	@						And Outreach channel = Channel value = GCX Outreach  (Phone) OR GCX Inbound (Phone)
	@						Then I am able to change a status of Campaign (Outreach record) to any status
	@
    @					20.12.2018/ Vadhanak Voun/EPH-6886 updated on EPH-6636
    @						AC2: When I go to Campaign Record except for Outreach record and Marketing Support Request (EBH_CampaignRequest)
    @						AC5: Given that I am ANY User
	@							When I go to Marketing Support Request
	@							I can change a status of a Campaign to status: "Draft" and "Request Submitted"
    *****************************************************************************************************************************/
    public static void validateStatus(List<Campaign> listCam,Map<Id,Campaign> mapOld)
    {  
    	Boolean isStandardUser = UserInfo.getProfileId().equals((!Test.isRunningTest()?EBH_ConstantsUtility.PROFILE_ID_STANDARD:'00e6A000000HO02QAG'));
    	Boolean isMarketingUser = UserInfo.getProfileId().equals(EBH_ConstantsUtility.PROFILE_ID_MARKETING);
    	Boolean isBizUser = UserInfo.getProfileId().equals(EBH_ConstantsUtility.PROFILE_ID_BIZADMIN);
    	Boolean isAdmingUser = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
    	Boolean isGCXSuperUser =   checkGCXSuperUser();
    	
    	if(isAdmingUser) return;
    	
    	for(Campaign cam: listCam)
    	{	 
    		//AC1: Marketing User or Business User
    		//AC3: Standard User,  Campaign Record: Outreach And Outreach channel = AM Outreach
    		//AC4: GCX Super User, Campaign Record: Outreach And Outreach channel = Channel value = GCX Outreach  (Phone) OR GCX Inbound (Phone)
    		if((isMarketingUser || isBizUser) 
    			|| (isStandardUser && cam.recordtypeId.equals(EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID) && cam.EBH_Channel__c == EBH_ConstantsUtility.CAMP_CHANNEL_AM_OUTREACH  ) 
    			|| (isGCXSuperUser && cam.recordtypeId.equals(EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID) && (cam.EBH_Channel__c == EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL || cam.EBH_Channel__c ==EBH_ConstantsUtility.CAMP_CHANNEL_GCXINBOUND_PHONE))
    			|| (cam.recordtypeId.equals(EBH_ConstantsUtility.CAMP_RECORDTYPE_REQUEST_ID) && (cam.Status== EBH_ConstantsUtility.CAMP_STATUS_DRAFT || cam.Status==EBH_ConstantsUtility.CAMP_STATUS_REQUEST_SUBMITED) ) 
    		)
    		{   
    			 continue;// allow changing
    		}
    		//AC2: (Standard User or GCX Super User)  <> Outreach record -> NOT Allow changing
            /*
            US-0009894
            There is a trigger that is updating the campaign when the first task is executed
    		else if(((isStandardUser || isGCXSuperUser))
    			&& mapOld.get(cam.Id).Status <> null && cam.Status <> mapOld.get(cam.Id).Status
    		)
    		{
    			cam.addError(System.Label.CampaignStatusError);
    		}
            */
    	}
    }
    private static Boolean isGCXSuperUser = null;
    public static Boolean checkGCXSuperUser()
    {
    	if(isGCXSuperUser==null)
    	{
    		String currentUserId = UserInfo.getUserId();
    		List<PermissionSetAssignment> listPSA = Database.query(EBH_ConstantsUtility.SOQL_GCX_TEAM_LEAD);//GCX super user
    		isGCXSuperUser = !listPSA.isEmpty();
    	}
    	return isGCXSuperUser;
    }
    
    /*****************************************************************************************************************************
    @ Method:         checkDuplicateCampaignName
    @ Version:        1.0
    @ Author:         Sovantheany Dim
    @ Purpose:        EPH-6851 Campaign Record Enhancements
    @               AC1: Create restrictions on the field Campaign Name for record type "Campaign" and for the record type "Sub-Campaign"
    					Field Name Already Exists
    					Name Cannot Exceed 80 Characters
    				AC2:
						Given that I am Marketing User when I create Campaign Name for record type "Campaign" or "Sub-Campaign"
						When Campaign Name does not match any of two criteria in AC1
						Then I get an error message:
						"Campaign Name does not match one of the following criteria:
						Campaign ID is Unique
						Campaign ID does not exceed 80 Characters
						Please make adjustments to the Campaign Name"
	@				Trigger: before create/update
    @ Parameter:    Campaigns:      Campaigns from the trigger scope
    @                CampaignOldMap: Campaigns old map from the trigger scope
    @
    ---------------------------------------------------------------------------------------------------------------
    @Change history: 24.12.2018 / sovantheany dim / 
					 06.08.2019 / acmatac seing / deprecated due to EPH-7922.
    check duplicate for all profile that can create Campaign and sub campaign,
	so they are:
    *****************************************************************************************************************************/
    /*public static void checkDuplicateCampaignName(List<Campaign> Campaigns, Map<Id, Campaign> CampaignOldMap){
    	Set<String> setRestrictedRecTypes = new Set<String>{EBH_ConstantsUtility.CAMP_RECORDTYPE_MASTER_ID,EBH_ConstantsUtility.CAMP_RECORDTYPE_SUB_ID};//master and sub id
    	
    	Map<ID,String> mapCamName = new Map<ID,String>();
    	Set<String> sCamName = new Set<String>();
    	List<Campaign> lstNewCampaign = new List<Campaign>();
    	for(Campaign cam : Campaigns){
    		if(campaignOldMap != null && cam.Name == campaignOldMap.get(cam.id).Name) continue;
			if(setRestrictedRecTypes.contains(cam.RecordTypeId)){
				if(sCamName.contains(cam.Name)){
					//if duplicate in new list of campaigns
					cam.addError(System.Label.Campaign_Duplicate_Name,false);
					continue;
				}
				sCamName.add(cam.Name.toLowerCase());
				lstNewCampaign.add(cam);
			}
    	}
    	Set<String> dupNames = new Set<String>();
    	for(Campaign cam : [select Name from Campaign where Name IN: sCamName]){
    		dupNames.add(cam.Name.toLowerCase());
    	}
    	for(Campaign cam : lstNewCampaign){
    		if(cam.Name.length() > 80 || dupNames.contains(cam.Name.toLowerCase())){
    			cam.addError(System.Label.Campaign_Duplicate_Name,false);
    		}
    	}
    }*/
    
    /*****************************************************************************************************************************
    @ Method:         updateMarketingTicketDueDate
    @ Version:        1.0
    @ Author:         Sovantheany Dim
    @ Purpose:        EPH-6853 Due Dates,This value will be automatically populated based on Campaign Start Date		  
    Record Type "Targeting": Campaign.StartDate - 3 Working Day
    Record Type "Copy/Creative": Campaign.StartDate - 2 Working Day
    Record Type "Journey": Campaign.StartDate - 1 Working Day
	@ Trigger: after update
    @ Parameter:    Campaigns:      Campaigns from the trigger scope
    @                CampaignOldMap: Campaigns old map from the trigger scope
    @
    ---------------------------------------------------------------------------------------------------------------
    @Change history: 28.12.2018 / sovantheany dim /Created the method.  
    @Change history: 04.07.2022 /Chetra Sarlom/ US-0007031 - Deactivate triggers
    *****************************************************************************************************************************/
    /*
    public static void updateMarketingTicketDueDate(List<Campaign> Campaigns, Map<Id, Campaign> CampaignOldMap){
    	Set<String> sCampaign = new Set<String>();
    	for(Campaign cam : Campaigns){
    		Campaign oldCam = CampaignOldMap.get(cam.Id);
    		if(cam.StartDate!= null && cam.StartDate != oldCam.StartDate){
    			sCampaign.add(cam.Id);
    		}
    	}
    	List<Marketing_Ticket__c> lstMarketingTicket = new List<Marketing_Ticket__c>();
    	Integer substractDay = 0;
		
    	RecordType rCopyCreative = ApexUtil.getRecordTypeByName('Marketing_Ticket__c','Copy_Creative');
        RecordType rTargeting = ApexUtil.getRecordTypeByName('Marketing_Ticket__c','Targeting');
        RecordType rJourney = ApexUtil.getRecordTypeByName('Marketing_Ticket__c','Journey');
    	Map<String,Integer> mapSubDay = new Map<String,Integer>{rTargeting.ID=>3, rCopyCreative.ID=>2,rJourney.ID=>1};
    	
		for(Marketing_Ticket__c marketingTicket : [select RecordTypeId,Campaign__r.StartDate from Marketing_Ticket__c where Campaign__c IN: sCampaign]){
    		substractDay = mapSubDay.get(marketingTicket.RecordTypeId);
    		
    		marketingTicket.Due_Date__c = marketingTicket.Campaign__r.StartDate != null ? MarketingTicketTriggerHandler.subtractDays(marketingTicket.Campaign__r.StartDate,substractDay): null;
    		
    		lstMarketingTicket.add(marketingTicket);
    	}
    	
    	if(!lstMarketingTicket.isEmpty()) update lstMarketingTicket;
    	
    }
    */
	
	/*****************************************************************************************************************************
    @ Method:         checkOutReachStatusChanged
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        EPH-6852 Tasks Status: "Paused", "Stopped"
    @				AC2:
	@				Given that a status of the Outreach is changed to "Campaign Paused"
	@				Then tasks with "Open" status are changed to "Paused" status.
	@				Tasks with status "Completed" stay not impacted. 
	@ Trigger:      after update
    @ Parameter:    Campaigns:      Campaigns from the trigger scope
    @               CampaignOldMap: Campaigns old map from the trigger scope
    @
    ---------------------------------------------------------------------------------------------------------------
    @Change history: 19.01.2019 / Vadhanak Voun /Created the method.  
    @			   : 15.02.2019/ Vadhanak Voun	/ EPH-7058 Outreach status: change from "Paused" to "Stopped"
    @						Given that a status of the Outreach is changed to "Campaign Running" from "Campaign Paused"
	@						Then tasks with "Paused" status are changed to "Open" status.
	@						Tasks with status "Completed" stay not impacted.
	@				AC2: Given that a status of the Outreach is changed to "Campaign Stopped" (original wrong wording: "Campaign Paused")
    @               : 29.10.2019/ Sreymeas Nao/ US-0015754: GCX Outreach Tasks showing as paused when campaign is stopped 
                    : SRONG TIN / 25.11.2021 : US-0010907 - [HypercareBug] Campaign could not change stage to "Campaign Stopped"
                    : SRONG TIN / 25.07.2022 : US-0012126 - CPU Limit error when user update Campaign stage to "Stopped" 
    *****************************************************************************************************************************/
    public static void checkOutReachStatusChanged(List<Campaign> listNew,Map<Id,Campaign> mapOld)
    {
    	Set<String> setCampIdPaused = new Set<String>();
    	Set<String> setCampIdCancelled = new Set<String>();
    	Set<String> setCampIdBackToRunning = new Set<String>();
    	for(Campaign c: listNew)
    	{
    		if(c.RecordTypeId == EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID
    			&& c.Status <> mapOld.get(c.Id).Status 
    			)
	    	{
	    		if(c.Status == EBH_ConstantsUtility.CAMP_STATUS_PAUSED)
	    		{
	    			setCampIdPaused.add(c.Id);
	    		}else if(c.Status == CMRC_COMPLETED)//NK:15/02/2019: EPH-7058: cancelled -> stopped
	    		{
	    			setCampIdCancelled.add(c.Id);
	    		}else if(mapOld.get(c.Id).Status == EBH_ConstantsUtility.CAMP_STATUS_PAUSED && c.Status == CMRC_EXECUTION) //'paused' back to 'running' 
	    		{
	    			setCampIdBackToRunning.add(c.Id);
	    		}
	    		
	    	}	
    	}
    	String taskStatusOpen = EBH_ConstantsUtility.AOC_TASKSTATUS;
    	if(!setCampIdPaused.isEmpty())
    	{
    		List<Task> taskToUpdate = new List<Task>();
    		for(Task t: Database.query(EBH_ConstantsUtility.SOQL_TASK+' WHERE WhatId IN :setCampIdPaused AND Status =:taskStatusOpen'))
    		{
    			//Then tasks with "Open" status are changed to "Paused" status.
    			t.Status = EBH_ConstantsUtility.TASK_STATUS_PAUSED;
    			taskToUpdate.add(t);
    		}
    		if(!taskToUpdate.isEmpty())
    		{
    			update taskToUpdate;
    		}
    	}
    	 
    	if(!setCampIdCancelled.isEmpty())
    	{
    		
            List<Task> taskToDelete = new List<Task>();
    		List<Task> taskToCancel = new List<Task>();
            //SRONG TIN / 25.11.2021 : US-0010907
    		Map<Id,CampaignMember> mapMemberToUpdate = new Map<Id,CampaignMember>();
            String taskStatusPaused = EBH_ConstantsUtility.TASK_STATUS_PAUSED;

            for(Task t: Database.query(EBH_ConstantsUtility.SOQL_TASK+' WHERE WhatId IN :setCampIdCancelled AND (Status =:taskStatusOpen OR Status =:taskStatusPaused)'))
    		{
    			//Then Tasks with status "Open" and call attempt = 0 ---> are deleted
    			if(t.Call_attempts__c == null || t.Call_attempts__c == 0)
    			{
    				
                    taskToDelete.add(t);
    				if(t.EBH_CampaignMemberId__c <> null)//if not from Refresh Member
    				{   
    					//Then Response code for Campaigns Members whose Tasks are deleted = 22 = "Call Cancelled"
                        //SRONG TIN / 25.11.2021 : US-0010907
    					mapMemberToUpdate.put(t.EBH_CampaignMemberId__c,new CampaignMember(Id=t.EBH_CampaignMemberId__c,EBH_ResponseCode__c = 22));
                        getStoppedCampaigns().add(t.WhatId);

    				}
    			}else
    			{
    				//Then Tasks with "Open" status and call attempt >0 ---> change status to "Cancelled"
    				t.Status = EBH_ConstantsUtility.TASK_STATUS_CANCELLED;
    				taskToCancel.add(t);
    			}
    		}

    		//SRONG TIN / 25.07.2022 : US-0012126
            if((taskToDelete.size()+taskToCancel.size()+mapMemberToUpdate.size()) <= TASK_BATCH_LIMIT ){

                if(!taskToDelete.isEmpty()){
                    delete taskToDelete;
                }
                if(!taskToCancel.isEmpty()){
                    update taskToCancel;
                }
                if(!mapMemberToUpdate.isEmpty()){
                    update mapMemberToUpdate.values();
                }
            }

    		
            
    	}
    	
    	//NK:15/02/2019: EPH-7093
    	if(!setCampIdBackToRunning.isEmpty())
    	{
    		String taskStatusPaused = EBH_ConstantsUtility.TASK_STATUS_PAUSED;
    		List<Task> taskToOpen = new List<Task>();
    		for(Task t: Database.query(EBH_ConstantsUtility.SOQL_TASK+' WHERE WhatId IN :setCampIdBackToRunning AND Status =:taskStatusPaused'))
    		{
    			t.Status =  EBH_ConstantsUtility.AOC_TASKSTATUS;
    			taskToOpen.add(t);
    		}
    		if(!taskToOpen.isEmpty())
    		{
    			update taskToOpen;
    		}
    	}
    }

    /*NK:22/02/2019: EPH-7139
    	Set of campaign Ids when member being updated with response code, then prevent campaign back to Running (that will cause validation)
    */
    private static Set<String> stoppedCampaign;
    public static Set<String> getStoppedCampaigns()
    {
    	if(stoppedCampaign==null)
    	{
    		stoppedCampaign = new Set<String>();
    	}
    	return stoppedCampaign; 
    }

    /*****************************************************************************************************************************
    @ Method:       populateFields
    @ Version:      1.0
    @ Author:       vadhanak voun
    @ Purpose:      US-0015501 - Campaign - Feedback bug fixes
    @ Event:        before insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    listCamp:      List of Campaigns from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2024 / vadhanak voun / Created the  Method. US-0015501 - Campaign - Feedback bug fixes
    *****************************************************************************************************************************/
    public static void populateFields(List<Campaign> listCamp) 
    {
        Set<String> setValidRT = new Set<String>{'eBay_Ads','EBH_Campaign','EBH_CampaignProgramme','EBH_ExternalCampaign','EBH_AMOutreach','EBH_StrategicPriority','EBH_SubCampaign'};
        Schema.DescribeSObjectResult dsr = Schema.SObjectType.Campaign; 
        Map<Id,Schema.RecordTypeInfo> rtMapById = dsr.getRecordTypeInfosById();

        for(Campaign camp: listCamp)
        {
            String  rtDevName =  rtMapById.get(camp.recordTypeId).getDeveloperName();
            //camp.isClone() && 
            if(camp.recordTypeId <> NULL && setValidRT.contains(rtDevName))
            {
                //Any RT above, on clone get default stats = 'Campaign in Development'
                camp.Status = STATUS_CAMP_IN_DEV;
            }
        }
    }
}