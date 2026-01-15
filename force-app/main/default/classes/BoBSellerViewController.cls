/*********************************************************************************************************************************
@ Class:          BoBSellerViewController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        EPH-6318 BOB MGMT - BOB Object - Page Layout (VF)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.08.2018 / Vadhanak Voun / Created the class.
@ Change history: 19.01.2023 / Bora Chhorn / US-0013099 - Unable to Clone a Managed BoB System throws a error message
@				: 01.02.2033 / SRONG TIN  /  US-0013130 - Existing Validation to exclude "Refurbished" Contract record type
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.08.2021 / Mony Nou / US-0009992 - "Clone" Button should be enabled always on Classic BoB
	+ Problem statement: Users forgetting that they have cloned a cohort and get confused if the "Clone" button is inactive on an Active Cohort.
	+ Goal: Provide a clear guidance why the user cannot clone existing Active cohort instead of just making the button inactive.
	+ Solution: Make the button active even if there is a draft record of an active and throw a clear message to the user
@				: 15.08.2023 / Sophal Noch / US-0013955 - Error when trying to update Account manager and managed Segment
@			 	: 07.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
*********************************************************************************************************************************/
public with sharing class BoBSellerViewController {
    /****************************************************************************************************************************
	* CONSTANTS DEFINITION
	*****************************************************************************************************************************/
	private static String BOBSELLER_MANAGED_RECORDTYPE = 'Managed';
	private static String BOB_MANAGED_RECORDTYPE = 'Managed_Cohort'; //MN-03082021-US-0009992 
	/************************************END CONSTANTS DEFINITION*************************************************************/
    
    /*****************************************************************************************************************************
	@ Method:   queryAllBoBSellers
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6318 BOB MGMT - BOB Object - Page Layout (VF)
	@			called from Aura: BoBSellerView to get all list of related BoBSellers to BoB by statuses 
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      parentId: parent BoB__c id, bsTye(all,new,removal), requestPag: page numbe to be displayed, searchKey: search text
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 31.09.2018 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> queryAllBoBSellers(String parentId,String bsType,Integer requestPage,String searchKey)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
    	
    	Navigator nav = null;
    	if(bsType=='all')
    	{
    		nav = new Navigator(parentId, EBH_ConstantsUtility.SOQL_BOB_SELLER_VIEW,' And Status__c <> :bobSellerStatus_removed',requestPage,searchKey); 
    	}else if(bsType=='new')
    	{
    		nav = new Navigator(parentId, EBH_ConstantsUtility.SOQL_BOB_SELLER_VIEW,' And Status__c= :bobSellerStatus_new',requestPage,searchKey); 
    	}else if(bsType=='removal')
    	{
    		nav = new Navigator(parentId, EBH_ConstantsUtility.SOQL_BOB_SELLER_VIEW,' And Status__c= :bobSellerStatus_removed',requestPage,searchKey); 
    	}
    	 
    	mapResult.put('listRecord',nav.listRecord);
    	mapResult.put('totalRecord',nav.totalResultCount);
    	mapResult.put('currentPage',requestPage); 
    	mapResult.put('totalPage',nav.totalPage);
    	
    	return mapResult;
    }
    
     /*****************************************************************************************************************************
	@ Method:   queryBoBInfo
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6318 BOB MGMT - BOB Object - Page Layout (VF)
	@			called from Aura: BoBSellerView to get all list of related BoBSellers to BoB by statuses 
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      parentId: parent BoB__c id
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 20.08.2018 / Vadhanak Voun / Created the  Method.
	@				  12.11.2018 / Vadhanak Voun / added showUndo().
	@				  19.12.2018 / Vadhanak Voun / EPH-6695: isOwner
	*****************************************************************************************************************************/
     @AuraEnabled
    public static Map<String,Object> queryBoBInfo(String parentId)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
    	
    	BoB__c bob =  Database.query(EBH_ConstantsUtility.SOQL_BOB);
    	RecordType bobSellerRecordTypeManaged = ApexUtil.getRecordTypeByName('BoB_Seller__c',BOBSELLER_MANAGED_RECORDTYPE);  
    	
    	mapResult.put('bob',bob);
    	mapResult.put('showSubmit',showSubmitButton(bob));
    	mapResult.put('showClone', showCloneButton(bob) );
    	mapResult.put('showConfirmNew',showConfirmNewButton(bob));
    	mapResult.put('showConfirmRemove',showConfirmRemoveButton(bob) );
    	mapResult.put('isCatLeadOrAdmin',isCatLeadOrAdmin() );
    	mapResult.put('showUndo',showUndo(bob) );//NK:12/11/2018: EPH-6570
    	mapResult.put('recordTypeId',bobSellerRecordTypeManaged.Id);//TH: 14/05/2020: US-0007576
    	
    	mapResult.put('isBoBActive',(bob.Status__c == EBH_ConstantsUtility.BOB_STATUS_ACTIVE) );
    	mapResult.put('isOwner',(bob.OwnerId == UserInfo.getUserId()));
		
		mapResult.put('isAdmin',(UserInfo.getProfileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID));//TH: 19/03/2021 : US-0009127 - [BoB Clean up]Hide "Managed Sub segment" from BoB Seller and Customer 360
    	return mapResult;
    	
    }
    
    /*****************************************************************************************************************************
	@ Method:   showUndo
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6570 BOB MGMT. - Add Undo Button when BOB Owner accidently removed seller
	@			As a GCX Lead when I am in stage DRAFT I need to have a button to revent my action if I have accidently removed a seller.
	@			The following can only be edited by the BOB Owner and in stage DRAFT
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      bob: BoB__c id
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 12.11.2018 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    private static Boolean showUndo(BoB__c bob)
    {
    	return ((bob.Status__c == EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT) && (UserInfo.getUserId()==bob.OwnerId));
    }
    
    private static Boolean isCatLeadOrAdmin()
    {
    	return (isCategoryLead() || UserInfo.getProfileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID );
    }
    
 	private static Boolean showCloneButton(BoB__c bob)
    {
		//MN-03082021-US-0009992
    	//return (isCategoryLead() || UserInfo.getProfileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID ) && (bob.Status__c == EBH_ConstantsUtility.BOB_STATUS_ACTIVE) && bob.BOBs__r.isEmpty();//NK:05/11/2018:EPH-6680:allows clone only once

		return (isCategoryLead() || UserInfo.getProfileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID ) && (bob.Status__c == EBH_ConstantsUtility.BOB_STATUS_ACTIVE); //MN-03082021-US-0009992
    }
    
    /**
    	Given that I am Category Lead. When I navigate to a draft BOB record. Then I can click "Submit"
    */
    private static Boolean showSubmitButton(BoB__c bob)
    {
    	if(bob.Status__c==EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT)
    	{
    		//if user Category Lead? (or Admin)
    		return  (UserInfo.getProfileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID || isCategoryLead()); 
    	}
    	return false;
    }
    /**
    AC2) Only a BoB GCX Lead can confirm the "BoB New In".Given that I am the BoB GCX Lead
	When I navigate to a submitted BoB record of my BoB Country.
	Then I have the option to click "Confirm" for the "BoB New In" section
    */
    private static Boolean showConfirmNewButton(BoB__c bob ) 
    {
	 	if(bob.Status__c == EBH_ConstantsUtility.BOB_STATUS_SUBMITTED)
	 	{
	 		Set<String> setUserId = new Set<String>{UserInfo.getUserId()};
	 		String bobCountry = bob.EBH_BOBCNTRY__c;
	 		List<User> listUser =  Database.query(EBH_ConstantsUtility.SOQL_BOB_USER_BY_COUNTRY);
	 		// current user is same country with bob and is gcx lead, or Admin
	 		Boolean isBoBGCXLead = isInGroup(new Set<String>{EBH_ConstantsUtility.BOB_GROUP_GCX_LEADS}); 
   			if((!listUser.isEmpty() && isBoBGCXLead) ||  UserInfo.getProfileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID) 
   			{
   				 return true;
   			} 
	 	}
	 	
	 	return false;
    }
    /**
	   AC2) Only a BoB Finance can confirm the "BoB Removed"
	Given that I am the BoB Finance
	When I navigate to a submitted BoB record of my BoB Country
	Then I have the option to click "Confirm" for the "BoB Removed" section
    */
    private static Boolean showConfirmRemoveButton(BoB__c bob )
    {
	 	if(bob.Status__c == EBH_ConstantsUtility.BOB_STATUS_SUBMITTED)
	 	{
	 		Set<String> setUserId = new Set<String>{UserInfo.getUserId()};
	 		String bobCountry = bob.EBH_BOBCNTRY__c;
	 		List<User> listUser =  Database.query(EBH_ConstantsUtility.SOQL_BOB_USER_BY_COUNTRY);
	 		// current user is same country with bob and corresponding group, or Admin
	 		Boolean isBoBFinance = isInGroup(new Set<String>{EBH_ConstantsUtility.BOB_GROUP_BOB_FINANCE});
   			if((!listUser.isEmpty() && isBoBFinance) ||  UserInfo.getProfileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID) 
   			{
   				 return true;
   			} 
	 	}
	 	
	 	return false;
    }
    
    
    private static Boolean isCategoryLead()
    {
    	String currentUserId = UserInfo.getUserId();
    	List<PermissionSetAssignment> listPSA = Database.query(EBH_ConstantsUtility.SOQL_BOB_CAT_LEAD);
    	return !listPSA.isEmpty();
    	
    }
    /**
     NK:28/08/2018: check if current user belong to group BoB Finance
    */
    private static Boolean isInGroup(Set<String> setGoups)
    {
    	for(GroupMember gm: Database.query(EBH_ConstantsUtility.SOQL_GROUP_MEMBER))
   		{
   			if(UserInfo.getUserId()==gm.UserOrGroupId)
   			{
   				return true;
   			}
   		} 
   		
   		return false;
    	
    }
    
    /*****************************************************************************************************************************
	@ Method:   apexReomveBoBSeller
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6318 BOB MGMT - BOB Object - Page Layout (VF)
	@			called from Aura: Users can "Delete" the row if the status is "New". If not "New", users can "Remove" the row which DOES NOT delete the row, but changes the status to "Removed" 
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      bobSellerId: id of current BoBseller being removed (changed status to 'Removed')
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 20.08.2018 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> apexReomveBoBSeller(String bobSellerId,String status)
    {
    	Map<String,String> mapResult = new Map<String,String>();
    	
    	try
    	{
    		BoB_Seller__c bobSel = Database.query(EBH_ConstantsUtility.SOQL_BOBSELLER +' WHERE Id=:bobSellerId');
    		
    		if(!checkContract(bobSel.Seller__c))
    		{
    			mapResult.put('status','ko');mapResult.put('error',System.Label.BoBRemoveError);
    			return mapResult;
    		}
    		
    		if(EBH_ConstantsUtility.BOB_SELLER_STATUS_NEW==status)
    		{
    			delete bobSel;
    		}else
    		{
    			bobSel.Previous_Status__c = bobSel.Status__c;//NK:12/11/2018:EPH-6570: transfer and keep it for Undo
    			bobSel.Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED;
    			update bobSel;
    		}
    		
    		mapResult.put('status','ok');
    	}catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
    	catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}
    	
    	return mapResult;
    	
    }
    /*****************************************************************************************************************************
	@ Method:   checkContract
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6517 BoB Mgmt - Automate confirmation for seller removals by cross-checking the contract object
	@			AC1) When a BOB is in status draft and a BoB Owner clicks on a seller "REMOVE" button then we should have a cross check with the contract object whether there is an contract in any stage except "Expired" or "Voided"  (covering all active contracts) for respective oracle ID and if yes then block the seller  removal.
	@			AC2) Also when we check under AC1) If there is a contract in any stage except "Expired" or "Voided" then the BOB Owner should also get a error message
	@				"Please note that the seller cannot be removed from the Managed Cohort until all active contracts with the seller are terminated."
	@------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      sellerId: sellerId to find the related contracts for cross checking
	@------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 05.02.2019 / Vadhanak Voun / Created the  Method.
	@				: 01.02.2033 / SRONG TIN  /  US-0013130 - Existing Validation to exclude "Refurbished" Contract record type
	*****************************************************************************************************************************/
    private static Boolean checkContract(String sellerId)
    {
    	//system.debug('>>>sellerId: '+sellerId);
    	Set<String> statusToCheck = new Set<String>{'Expired','Voided'};
		//01.02.2033 / SRONG TIN  /  US-0013130
		Set<String> recordTypeToCheck = new Set<String>{'EBH_ACP','EBH_ListingAgreement'};
		List<EBH_ContractSeller__c> contractSellerList = [Select Id,EBH_BusinessName__c, EBH_ContractNumber__c,EBH_ContractNumber__r.Status From EBH_ContractSeller__c Where EBH_BusinessName__c=:sellerId AND EBH_ContractNumber__r.Status NOT IN :statusToCheck AND EBH_ContractNumber__r.RecordType.DeveloperName IN :recordTypeToCheck];
     	Boolean isOk = contractSellerList.isEmpty();
      	//system.debug('>>>isOk: '+isOk+'>>>:'+Database.query(EBH_ConstantsUtility.SOQL_CONTRACT_SELLER+soqlWhere)); 
     	return isOk;
    }
     
    /*****************************************************************************************************************************
	@ Method:   apexUndoReomveBoBSeller
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6570 BOB MGMT. - Add Undo Button when BOB Owner accidently removed seller
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      bobSellerId: id of current BoBseller being undone  
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 12.11.2018 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> apexUndoReomveBoBSeller(String bobSellerId)
    {
    	Map<String,String> mapResult = new Map<String,String>();
    	
    	try
    	{
    		BoB_Seller__c bobSel = Database.query(EBH_ConstantsUtility.SOQL_BOBSELLER +' WHERE Id=:bobSellerId');
    		 
			bobSel.Status__c=bobSel.Previous_Status__c;
			update bobSel;
    		
    		mapResult.put('status','ok');
    	}catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
    	catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}
    	
    	return mapResult;
    	
    }
    
    /*****************************************************************************************************************************
	@ Method:   apexCloneBoB
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6329 BOB MGMT - Submit / Approve / Activate BOB
	@			When I click "Clone"
	@			Then the BoB record is cloned
	@			"BoB Status" is reverted to "Draft"
	@			And the related BoB Seller records where Status is not "Removed" are also cloned
	@			BoB Seller "Status" marked as "Submitted"
	@			BoB Seller "Active" checkbox is reverted to default FALSE
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      bobId: id of current BoB to be cloned
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 21.08.2018 / Vadhanak Voun / Created the  Method.
	@				: 11.02.2020/ Vadhanak Voun /U:S-0007164: handled by batch from button, or nightly job
	@				: 03.08.2021/ Mony Nou / US-0009992 - "Clone" Button should be enabled always on Classic BoB
	@				: 19.01.2023 / Bora Chhorn / US-0013099 - Unable to Clone a Managed BoB System throws a error message
	@				: 15.08.2023 / Sophal Noch / US-0013955 - Error when trying to update Account manager and managed Segment
	@				: 07.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> apexCloneBoB(String parentId)
    {

		Savepoint sp = Database.setSavepoint(); // 15.08.2023 / Sophal Noch / US-0013955
    	
    	Map<String,String> mapResult = new Map<String,String>();

		/*
    	String bobSellerStatus_removed = EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED;
    	try
    	{
    		String soqlBoB  = 'Select '+ApexUtil.generateSQOLFields('BoB__c')+' From BoB__c Where Id=:parentId';
    		String soqlBoBSellers  = 'Select Seller__r.Name,Seller__r.EBH_Status__c,'+ApexUtil.generateSQOLFields('BoB_Seller__c')+' From BoB_Seller__c Where BoB__c=:parentId And Status__c <>:bobSellerStatus_removed';
    		List<BoB__c> bobs = Database.query(soqlBoB);
			
			//MN-03082021-US-0009992 - Find another DRAFT BoB for the same Name <BoB__c.Group_Name__c>, Vertical <BoB__c.EBH_BOBVertical__c>and Country<BoB__c.EBH_BOBCNTRY__c>
			RecordType bobRecordTypeManaged = ApexUtil.getRecordTypeByName('BOB__c',BOB_MANAGED_RECORDTYPE);  
			Boolean isValid = true;
			BoB__c existed_bob = new BoB__c();
			String grpName = bobs[0].Group_Name__c + '%';
			for (BoB__c b :[SELECT Id,Name FROM BoB__c WHERE Group_Name__c LIKE:grpName AND RecordTypeId=:bobRecordTypeManaged.Id
								AND EBH_BOBVertical__c=:bobs[0].EBH_BOBVertical__c AND EBH_BOBCNTRY__c=:bobs[0].EBH_BOBCNTRY__c AND Status__c=:EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT
								LIMIT 1]) {
				existed_bob = b;
				isValid = false;
			} 

			//if there is another draft bob then throw an error
			if (!isValid) {
				mapResult.put('status','dup_err');
				String errMsg = System.Label.BoB_Duplicate_Cloned_Found;
				mapResult.put('error', errMsg);
				mapResult.put('ex_bob_id',existed_bob.id);
				mapResult.put('ex_bob_name',existed_bob.Name);
				return mapResult;
			}
			//---- MN-03082021-US-0009992//

    		BoB__c cloneBoB = bobs[0].clone(false,true,false,false);
    		cloneBoB.Status__c = EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT; 
    		cloneBoB.Source_BoB__c = parentId;
    		cloneBoB.BoB_New_In_Confirm_Date__c = null;
    		cloneBoB.BoB_Removal_Confirm_Date__c= null;
    		cloneBoB.Date_Activated__c = null;
    		insert cloneBoB;
    		
    		 
    		Set<String> setDeletedSellers = new Set<String>();
    		List<BoB_Seller__c> listBoBSellersNotRemoved = Database.query(soqlBoBSellers); 
    	 
    		List<BoB_Seller__c> listBoBSellersToClone = new List<BoB_Seller__c>();
    		for(BoB_Seller__c bs : listBoBSellersNotRemoved)
    		{
    			//EPH-6525
    			if(bs.Seller__r.EBH_Status__c==EBH_ConstantsUtility.ACRTH_DELETEDSTATUS)
    			{
    				setDeletedSellers.add(bs.Seller__r.Name);
    				continue;
    			}
    			
    			BoB_Seller__c bsClone = bs.clone(false,true,false,false);
    			bsClone.Status__c = EBH_ConstantsUtility.BOB_SELLER_STATUS_SUBMITTED;
    			bsClone.BoB__c = cloneBoB.Id;
    			bsClone.Cloned__c = true;
				bsClone.OwnerId = UserInfo.getUserId(); //BR-US-0013099
    			listBoBSellersToClone.add(bsClone);  
    		} 
    		if(!listBoBSellersToClone.isEmpty())
    		{
    			insert listBoBSellersToClone; 	
    		}
    		
    		mapResult.put('status',setDeletedSellers.isEmpty()?'ok':'warn');
    		mapResult.put('message',System.Label.Attention_DeletedSeller+'\n'+String.join(new List<String>(setDeletedSellers), ','));
    		mapResult.put('bobId',cloneBoB.Id+'');
    		
    		//NK:11/02/2020:US-0007164: handle by batch from button + nightly job instead of trigger to prevent governor limit
    		BatchFixBoBAccountManager b = new BatchFixBoBAccountManager('bs', new Set<String>{parentId,cloneBoB.Id});
     		Database.executeBatch(b);
     		
    	}catch(DMLException dex){Database.rollback(sp);mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
    	catch(Exception ex){Database.rollback(sp);mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}
    	
		*/
    	return mapResult;
    	
    }

    /*****************************************************************************************************************************
	@ Method:   apexSubmitBoB
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6329 BOB MGMT - Submit / Approve / Activate BOB
	@			Given that I am Category Lead
	@			When I navigate to a draft BOB record
	@			Then I can click "Submit"
	@			And status of the BOB updates to "Submitted"
	@			And the assigned BoB GCX Lead and BoB Finance of the BoB Country will get a email notification that he has to "CONFIRM" the BoB
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      bobId: id  
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 24.08.2018 / Vadhanak Voun / Created the  Method.
	@				  14/11/2018/ Vadhanak Voun / EPH-6469 BOB MGMT. - Automatically confirm BOB if no removed or added seller
	@				  19/07/2019/ Vadhanak Voun/ EPH-7776: Auto confirm when submit if country = AU
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> apexSubmitBoB(String parentId)
    {
    	Map<String,String> mapResult = new Map<String,String>();
    	
    	
    	try
    	{
    		//BoB__c bob = new BoB__c(Id=parentId,);
    		//String soqlBoB  = 'Select '+ApexUtil.generateSQOLFields('BoB__c')+' From BoB__c Where Id=:parentId';
    		//bob =  Database.query(EBH_ConstantsUtility.SOQL_BOB);
    		BoB__c bob = Database.query(EBH_ConstantsUtility.SOQL_BOB);
    		bob.Status__c=EBH_ConstantsUtility.BOB_STATUS_SUBMITTED;
    		//Boolean isAU = (bob.EBH_BOBCNTRY__c == '15');
    		
    		//NK:14/11/2018 EPH-6469 
	    	String bobSellerStatus_new = EBH_ConstantsUtility.BOB_SELLER_STATUS_NEW;
	    	String bobSellerStatus_removed = EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED;
			
			List<BoB_Seller__c> listBSNew = Database.query(EBH_ConstantsUtility.SOQL_BOB_SELLER_VIEW+' And Status__c= :bobSellerStatus_new LIMIT 1');
		 	//List<BoB_Seller__c> listBSRemove = Database.query(EBH_ConstantsUtility.SOQL_BOB_SELLER_VIEW+' And Status__c= :bobSellerStatus_removed LIMIT 1');
	 	 	
	 	 	//EPH-7711
	 	 	//if(listBSNew.isEmpty() || isAU)
	 	 	if(listBSNew.isEmpty())
	 	 	{
	 	 		bob.BoB_New_In_Confirm_Date__c = System.now(); //EPH-6469: auto confirm if no seller
	 	 		bob.Status__c =  EBH_ConstantsUtility.BOB_STATUS_ACTIVE; //NK:27/03/2019: EPH-7217
	 	 	}
	 	 	
	 	 	//NKL05/02/2019: EPH-6517 AC3:  It should automatically move status to confirmed for section "REMOVALS"
	 	 	bob.BoB_Removal_Confirm_Date__c = System.now(); 
	 	 	
   			update bob;
   			
   			//EPH-7711
//   			if(isAU)
//   			{
//   				mapResult.put('status','ok');
//		        mapResult.put('message','BoB has been submitted and automatically confirmed.');
//		        return mapResult; //auto confirm (no email) for AU
//   			}
   			
   			String bobCountry = bob.EBH_BOBCNTRY__c;
   			
   			Set<String> setGoups = new Set<String>{(listBSNew.isEmpty()?null:EBH_ConstantsUtility.BOB_GROUP_GCX_LEADS)}; //,(listBSRemove.isEmpty()?null:EBH_ConstantsUtility.BOB_GROUP_BoB_FINANCE)//EPH-6517: no sending to finance anymore
   			List<User> listUser = getRespectiveUsers('(\''+bob.EBH_BOBCNTRY__c+'\')',setGoups);
   			
   			//System.debug('>>>listUser to send email: '+listUser);
   			if(!listUser.isEmpty())
   			{
	   			String templateName = 'BoB_Submission';
	   			
	   			List<EmailTemplate>  emailTemplates = Database.query(EBH_ConstantsUtility.SOQL_BOB_EMAIL_TEMPLATE);
	   			if(!emailTemplates.isEmpty())
	   			{
	   				 List<Messaging.SingleEmailMessage> listEmail = new List<Messaging.SingleEmailMessage>(); 
			         for(User u: listUser)
			         {
			         	//https://hive--SPRINTDEV.cs68.my.salesforce.com
			         	String bobUrl = System.URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/BOB__c/'+bob.Id+'/view';
			         	String bodHtml = emailTemplates[0].HtmlValue;
			         	 bodHtml = bodHtml.replace('{!GCX_LEAD}',u.Name).replace('{!BOB__c.OwnerFullName}',bob.Owner.Name).replace('{!BOB__c.Name}',bob.Name).replace('{!BOB_URL}',bobUrl);
			         	
			         	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				        mail.setToAddresses(new String[]{u.Email});
				        mail.setSenderDisplayName('Hive Support');
				        mail.setSubject(emailTemplates[0].subject);
				        mail.setBccSender(false);
				        mail.setUseSignature(false); 
				        mail.setHtmlBody(bodHtml);
				        
				        listEmail.add(mail);
			         }
			         
			         doSend(listEmail);
			         
	   			}else
	   			{
	   				mapResult.put('status','ok');
			        mapResult.put('message','BoB has been submitted succesfully but not email template found for notification.');
	   			}
   			}
   			
   			//NK:27/03/2019:EPH-7217:  New In auto confirmed when empty seller (+removal always auto), but BoB not Activate!
   			if(listBSNew.isEmpty())
   			{
   				sendEmailConfirmNotification(bob);
   			}
   			
   			mapResult.put('status','ok');
	        mapResult.put('message','BoB has been submitted succesfully.');
        	
        	//NK:11/02/2020:US-0007164: handle by batch from button + nightly job instead of trigger to prevent governor limit
        	if(bob.Status__c ==  EBH_ConstantsUtility.BOB_STATUS_ACTIVE)
        	{
        		BatchFixBoBAccountManager b = new BatchFixBoBAccountManager('bs', new Set<String>{parentId});
     			Database.executeBatch(b);
        	}
     		
    	}catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
    	catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}
    	return mapResult;
    }
    
    /*****************************************************************************************************************************
	@ Method:   apexBoBConfirmNew
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6329 BOB MGMT - Submit / Approve / Activate BOB
	@			Only a BoB GCX Lead can confirm the "BoB New In"
	@			Given that I am the BoB GCX Lead
	@			When I navigate to a submitted BoB record of my BoB Country
	@			Then I have the option to click "Confirm" for the "BoB New In" section
	@			When I click "Confirm"
	@			Then the status of the BoB New In section changes to "BoB Active"
	@------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      bobId: id  
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 28.08.2018 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> apexBoBConfirmNew(String parentId)
    {
    	 Map<String,String> mapResult = new Map<String,String>();
    	 
    	 try
    	 {
    	 	BoB__c bob =  Database.query(EBH_ConstantsUtility.SOQL_BOB);
    	 	bob.BoB_New_In_Confirm_Date__c = System.now();
    	 	Boolean sendEmail = false;
    	 	if(bob.BoB_Removal_Confirm_Date__c <> null && bob.BoB_New_In_Confirm_Date__c <> null)
    	 	{
    	 		bob.Status__c =  EBH_ConstantsUtility.BOB_STATUS_ACTIVE;
    	 		sendEmail = true;
    	 	}
    	 	
    	 	update bob;
    	 	
    	 	if(sendEmail)
    	 	{
    	 		sendEmailConfirmNotification(bob);	
    	 	}
    	 	
    	 	mapResult.put('status','ok');
    	 	
    	 	//NK:11/02/2020:US-0007164: handle by batch from button + nightly job instead of trigger to prevent governor limit
    	 	if(bob.Status__c ==  EBH_ConstantsUtility.BOB_STATUS_ACTIVE)
        	{
        		BatchFixBoBAccountManager b = new BatchFixBoBAccountManager('bs', new Set<String>{parentId});
     			Database.executeBatch(b);
        	}
        	
    	 }catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
    	 catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}
   		
   		return mapResult;
    }
    
    /*****************************************************************************************************************************
	@ Method:   apexBoBConfirmRemove
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6329 BOB MGMT - Submit / Approve / Activate BOB
	@			Only a BoB Finance can confirm the "BoB Removed"
	@			Given that I am the BoB Finance
	@			When I navigate to a submitted BoB record of my BoB Country
	@			Then I have the option to click "Confirm" for the "BoB Removed" section
	@			When I click "Confirm"
	@			Then the status of the BoB Removed section changes to "Confirmed"
	@------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      bobId: id  
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 28.08.2018 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> apexBoBConfirmRemove(String parentId)
    {
    	 Map<String,String> mapResult = new Map<String,String>();
    	 
    	 try
    	 {
    	 	BoB__c bob =  Database.query(EBH_ConstantsUtility.SOQL_BOB);
    	 	bob.BoB_Removal_Confirm_Date__c = System.now();
    	 	
    	 	Boolean sendEmail = false;
    	 	if(bob.BoB_Removal_Confirm_Date__c <> null && bob.BoB_New_In_Confirm_Date__c <> null)
    	 	{
    	 		bob.Status__c =  EBH_ConstantsUtility.BOB_STATUS_ACTIVE;
    	 		sendEmail = true;
    	 	}
    	 	
    	 	update bob;
    	 	
    	 	if(sendEmail)
    	 	{
    	 		sendEmailConfirmNotification(bob);	
    	 	}
    	 	
    	 	mapResult.put('status','ok');
    	 	
    	 	//NK:11/02/2020:US-0007164: handle by batch from button + nightly job instead of trigger to prevent governor limit
    	 	if(bob.Status__c ==  EBH_ConstantsUtility.BOB_STATUS_ACTIVE)
        	{
        		BatchFixBoBAccountManager b = new BatchFixBoBAccountManager('bs', new Set<String>{parentId});
     			Database.executeBatch(b);
        	}
        	
    	 }catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));	mapResult.put('errorDetail',dex.getStackTraceString());}
    	 catch(Exception ex){mapResult.put('status','ko');	mapResult.put('error',ex.getMessage());	mapResult.put('errorDetail',ex.getStackTraceString());}
   		
   		return mapResult;
    }
    
	/*****************************************************************************************************************************
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 21.09.2021 / Acmatac SEING / US-0010425 - [AU Managed BoB] Inactivated Users are receiving Email notifications
	@				: 07.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
	*****************************************************************************************************************************/
    public static List<User> getRespectiveUsers(String bobCountry ,Set<String> setGoups)
    {
   		//String bobCountry = bob.EBH_BOBCNTRY__c;
   			
   		Set<String> setUserId = new Set<String>();
   		//get all user ids from related group
   		for(GroupMember gm: Database.query(EBH_ConstantsUtility.SOQL_GROUP_MEMBER))
   		{
   			setUserId.add(gm.UserOrGroupId);
   		}
   		List<User> listUser = new List<User>();
   		//filter only user with same bob country
   		//for(User u: Database.query(EBH_ConstantsUtility.SOQL_BOB_USER_BY_COUNTRY))

		//NK:07/06/2024:US-0015255
		//String whereClause = ' And BoB_Country__c includes '+bobCountry;		 
		String whereClause = ' AND IsActive=true '; // Acmatac SEING / 21.09.2021 / US-0010425 - [AU Managed BoB] Inactivated Users are receiving Email notifications
   		
		for(User u: Database.query(EBH_ConstantsUtility.SOQL_BOB_USER_BY_ID + whereClause))
   		{
   			listUser.add(u);
   		}
   			
   		return listUser;
    }
    /*
    private static List<User> getUsersByIdAndCountry(Set<String> setUserId,String bobCountry)
    {
    	List<User> listUser = new List<User>();
    	Set<String> setBoBCountry = new Set<String>();
   		//filter only user with same bob country
   		for(User u: Database.query(EBH_ConstantsUtility.SOQL_BOB_USER_BY_ID))
   		{
   			if(u.BoB_Country__c <> null)
   			{
   				setBoBCountry.addAll(u.BoB_Country__c.split(';')); //'186;101'
   			}
   		}
   		
   		return listUser;
    }
    */
    /**
    	When both BoB New In and BoB Removed section are marked as "Confirmed"
		Then the status of the BoB record moves to "Confirmed" "BoB Active"
		And the Category Lead (BoB Owner) and *GCX Operation*s will receive an email notification that the BoB has been confirmed.
		
		- 30.11.2018/vadhanak.voun/EPH-6813 Add user in BOB GCX Lead group in cc of BoB email confirmation
		: 07.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
    */
    private static void sendEmailConfirmNotification(BoB__c bob)
    {
		/*
    	//1,send confirm email to bob owner
    	//cc to GCX Operations (public group)
    	Set<String> setGoups = new Set<String>{EBH_ConstantsUtility.BOB_GROUP_BOB_GCX_OPERATIONS,EBH_ConstantsUtility.BOB_GROUP_GCX_LEADS};//NK:30.11.2018
   		List<User> listUserGCXOperation = getRespectiveUsers('(\''+bob.EBH_BOBCNTRY__c+'\')',setGoups);
   		
   		 
   		String templateName = 'BoB_Confirmation';
   		List<EmailTemplate>  emailTemplates = Database.query(EBH_ConstantsUtility.SOQL_BOB_EMAIL_TEMPLATE);
   		if(!emailTemplates.isEmpty())
   		{
   			 List<Messaging.SingleEmailMessage> listEmail = new List<Messaging.SingleEmailMessage>(); 
	       	//https://hive--SPRINTDEV.cs68.my.salesforce.com
	       	String bobUrl = URL.getSalesforceBaseUrl().toExternalForm() +'/lightning/r/BOB__c/'+bob.Id+'/view';
	       	String bodHtml = emailTemplates[0].HtmlValue;
	        Set<String> setUserId = new Set<String>{UserInfo.getUserId()};
	        User currentUser = Database.query(EBH_ConstantsUtility.SOQL_BOB_USER_BY_ID);
	        
	       	 bodHtml = bodHtml.replace('{!GCX_LEAD}',currentUser.Name)
	       	 .replace('{!BOB__c.OwnerFullName}',bob.Owner.Name)
	       	 .replace('{!BOB__c.Name}',bob.Name)
	       	 .replace('{!BOB_URL}',bobUrl);
	         	
	       	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	        mail.setToAddresses(new String[]{bob.Owner.Email});
	        mail.setSenderDisplayName('Hive Support');
	        mail.setSubject(emailTemplates[0].subject);
	        mail.setBccSender(false);
	        mail.setUseSignature(false); 
	        mail.setHtmlBody(bodHtml);
		    
		    mail.setFileAttachments(constructCSVAttachments(bob)); //NK:13/11/2018:EPH-6571
		        
	      List<String> gcxCC = new List<String>();
	      for(User u: listUserGCXOperation)
	      {
	        gcxCC.add(u.Email);
	      }
	      if(!gcxCC.isEmpty())
	      {
	       	mail.setCcAddresses(gcxCC);
	      }
	        
	      listEmail.add(mail);
		        
		      doSend(listEmail);
   		} 
   		 */
    }
    /*****************************************************************************************************************************
	@ Method:   constructCSVAttachments
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6571 BOB MGMT. - Change to BOB Confirmation Email
	@------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      bob  
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 13.11.2018 / Vadhanak Voun / Created the  Method.
	@				: 08.06.2019/ Vadhanak Voun / EPH-7107 BOB MGMT. - Add commentfield to BoB Object and BOB Confirmation email
	*****************************************************************************************************************************/
    private static List<Messaging.EmailFileAttachment> constructCSVAttachments(BoB__c bob)
    {
    	String parentId = bob.Id;
    	String bobSellerStatus_new = EBH_ConstantsUtility.BOB_SELLER_STATUS_NEW;
    	String bobSellerStatus_removed = EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED;
    	List<Messaging.EmailFileAttachment> listAtt = new List<Messaging.EmailFileAttachment>();
    	
    	//new in
    	String csvContent ='STATUS,SELLER,ORACLE ID,MANAGED SEGMENT,MANAGED SUBSEGMENT,ACCOUNT MANAGER,SWL VOLUME REQUEST,SWL GMV REQUEST,STORE SUBSCRIPTION REQUEST,FREE STORE REQUEST,SET BUSINESS POLICIES\n';
	 	for(BoB_Seller__c bs: Database.query(EBH_ConstantsUtility.SOQL_BOB_SELLER_VIEW+' And Status__c= :bobSellerStatus_new'))
	 	{
	 		csvContent+= bs.Status__c+','+bs.Seller__r.Name +','+ (bs.Oracle_Id__c==null?'':bs.Oracle_Id__c)+','+ bs.EBH_BOBSegment__c+','+bs.BoB_Subsegment__c+','+bs.Account_Manager__r.Name+','+(bs.SWL_Volume_Request__c==null?'':bs.SWL_Volume_Request__c+'')+','+(bs.SWL_GMV_Request__c==null?'':bs.SWL_GMV_Request__c+'')+','+(bs.Store_Subscription_Request__c==null?'':bs.Store_Subscription_Request__c)+','+bs.Free_Store_Request__c+','+bs.Set_business_policies__c+'\n'; 
	 	}
	 	//removed
	 	for(BoB_Seller__c bs: Database.query(EBH_ConstantsUtility.SOQL_BOB_SELLER_VIEW+' And Status__c= :bobSellerStatus_removed'))
	 	{
	 		csvContent+= bs.Status__c+','+bs.Seller__r.Name +','+ (bs.Oracle_Id__c==null?'':bs.Oracle_Id__c)+','+ bs.EBH_BOBSegment__c+','+bs.BoB_Subsegment__c+','+bs.Account_Manager__r.Name+','+(bs.SWL_Volume_Request__c==null?'':bs.SWL_Volume_Request__c+'')+','+(bs.SWL_GMV_Request__c==null?'':bs.SWL_GMV_Request__c+'')+','+(bs.Store_Subscription_Request__c==null?'':bs.Store_Subscription_Request__c)+','+bs.Free_Store_Request__c+','+bs.Set_business_policies__c+'\n'; 
	 	}
	 	
	 	Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
        fileAttachment.setBody(Blob.valueOf(csvContent));
        fileAttachment.setFileName('Managed Seller.csv');  
        listAtt.add(fileAttachment);  
        
    	 return listAtt;
    }
    
     public static void doSend(List<Messaging.SingleEmailMessage> listEmail){
        //start sending
        Messaging.sendEmail(listEmail);
    }
 	
 	/**
 	NK: Wrapper for Navigation 	
 	*/
    class Navigator{
    	String parentId;
    	String soql;
    	Integer recordLimit = EBH_ConstantsUtility.BOBSELLER_LIMT_VIEW;
    	public List<SObject> listRecord;
    	public Integer totalResultCount = 0;
    	
    	public Integer totalPage = 0;
    	public Integer currentPage = 0;
    	
    	String bobSellerStatus_new = EBH_ConstantsUtility.BOB_SELLER_STATUS_NEW;
    	String bobSellerStatus_removed = EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED;
    	String searchKey;
    	Integer myRequestPage = 1; //default
    	String where1;
    	Integer myOffset = 0;
    	public Navigator(String parentId,String soql,String where1,Integer requestPage, String searchKey)
    	{
    		this.parentId = parentId;
    		this.soql = soql;
    		this.where1 = where1;
    		this.myRequestPage = requestPage;
    		this.searchKey = searchKey;
    		
    		fetch();
    	}
    	
    	private void fetch()
    	{
    	  	String whereSearch = '';
    	  	if(String.isNotBlank(searchKey))
    	  	{
    	  		searchKey = '%'+searchKey+'%';
    	  		whereSearch = ' AND Seller__r.Name LIKE :searchKey ';
    	  	}
    	  	totalResultCount 	=  Database.countQuery(EBH_ConstantsUtility.SOQL_BOBSELLER_COUNT+where1 + whereSearch);
    	  	
    	  	calTotalPage();
			
			findOffset();
			
    		listRecord 			= 	Database.query(soql + where1 + whereSearch + EBH_ConstantsUtility.SOQL_BOB_SELLER_VIEW_SORT + EBH_ConstantsUtility.OFFSET_LIMIT );
    		
    		 
    	}
    	
    	private void calTotalPage()
    	{
    		if(totalResultCount > 0)
    		{
    			Decimal d = Decimal.valueOf(totalResultCount) / Decimal.valueOf(recordLimit); 
				totalPage = d.round(System.RoundingMode.CEILING).intValue();
    		}
    		
    	}
    	private void findOffset()
    	{
    		myRequestPage = Integer.valueOf(myRequestPage); //convert Integer to Integer (sfdc bug? Internal Salesforce.com Error)
    		myOffset = (myRequestPage * recordLimit ) - recordLimit;
    	}
    	 
    	
    }
    
    
}