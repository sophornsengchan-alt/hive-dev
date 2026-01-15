/*********************************************************************************************************************************
@ Class:        BoBSellerTriggerHandler
@ Version:      1.0
@ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:      Handler for BoB_Seller__c Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.08.2018 / Vadhanak Voun / Created the Class.
@ Change history: 10.01.2022 / Sophal Noch / US-0011008 - Clear the seller Managed fields for removed Cohort [P2] Bug - Seller and when entire Cohort is moved to status "Cohort Inactive"
@ Change history: 15.07.2022 / Sophal Noch / US-0011996 - Call booking for Ads
@ Change history: 19.07.2022 / Chetra Sarom / US-0012010 - Add New Button "Deactivate Sellers" Button next to "Remove Sellers"
@ Change history: 01.09.2022 / SRONG TIN / US-0012222 - Amends to existing warning message when an active BoB Seller is added to another Cohort
@ Change history: 05.09.2022 / Sambath Seng / US-0012558 - Validations when changing Cohort Seller Status from "Inactive" to "Active"
@				  16.03.2023 / Sovantheany Dim / US-0013334 - New fields and automations on Seller Invitation process
@				  13.04.2023 / Mony Nou / US-0012209 - Add Managed Segment field on Seller Mgmt record and add value "Pro-Trader Plus"
@				  11.05.2023 / Bora Chhorn / US-0013649 - Bulk upload of Cohort Sellers not inheriting the BoB__C.Managed Segment Value
@				  12.06.2023 / Acmatac Seing / US-0013681 - Error when trying to update Account manager and managed Segment
@				  30.06.2023 / Sovantheany dim / US-0013781 - Account Manager of the Cohort Seller is empty when adding a singular selle
@				  15.08.2023 / Sophal Noch / US-0013955 - Error when trying to update Account manager and managed Segment
@				  21.09.2023 / Sophal Noch / US-0014098 - ADS - Cohort Validation Rules
@				  19.10.2023 / Sovantheany Dim / US-0014224 - Tech Debt - Migrate the Workflow Populate Bob Seller Unique Key to Flow and other code updates
@                 09.11.2023 / Sophal Noch / US-0014361 - Cohort Activation Process Part 2
@                 29.11.2023 / Bora Chhorn / US-0014457 - Ph 1 - Restriction Rules - to expose Cohort Seller Data for only eligible sellers
@                 11.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
@                 11.12.2023 / Sophal Noch / US-0014363 - Ph 1 - Deactivate Sellers button
@                 05.01.2024 / Bora Chhorn / US-0014524 - Cohort seller validation - skip for New Status
@				  25.1.24 / Sovantheany Dim / US-0014729 - Managed Segment field value on Cohort Seller shouldn't be overwritten
@				  30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
@				  14.02.2024 / Sophal Noch / US-0014756 - Data Synchronization of the Managed fields when the Account Manager on Active Cohort is updated
@				  22.02.2024 / Acmatac Seing / US-0014796 / When Cohort Status updated from Invited to Active we should run it in Synchronously mode.
@				  11.03.2024 / Acmatac Seing / US-0014548 - Launch - Remove the Seller Portal Beta User from the restriction Rule
@				  12.03.2024 / Bora Chhorn / US-0014942 - When Seller Signs up for the PT program, check the Seller Signed up flag
@				  12.03.2024 / Sophal Noch / US-0014887 - ADS - Data synchronization of additional Managed fields
@				  28.03.2024 / Sophal Noch / US-0015011 - 1 PT for US - Enable Cohort Invitation Process
@				  29.03.2024 / Sophal Noch / US-0015044 - Error Null Pointer when transferring Cohort Seller
@				  18.04.2024 / Sophal Noch / US-0014964 - Tech Debt - Stop sending the email to the public group when Account Manager is updated
@				  22.04.2024 / Sovantheany Dim / US-0015107 - Retire Managed Cohort - Retire the record type Managed on Cohort Seller
@				  26.04.2024 / Sovantheany Dim / US-0015106 - Retire Managed Cohort - Retire the record type Managed Cohort and update the Record Type of LTTM
@				  14.05.2024 / Sophal Noch / US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
@				  04.06.2024 / Sophal Noch / US-0015352 - Transfer Cohort Seller Issue - Conflict and Order of execution
@				  16.10.2024/ vadhanak voun / US-0015432 - ADS - Eligibility for Advertising program component
@				  28.11.2024/ Chan Sophorn / US-0016308 - After Transfer BoB-Seller then Create New BoB-Seller with New BoB-Seller's Account Manager, if BoB-Seller's Account Manager has value
@				  13.05.2025 / Davy Sorn / US-0012356 - 1. Enable Account Management and call booking for Account Management sellers
@				  03.07.2025 / Sophal Noch / US-0033064 - Limiting paid programs visibility to only existing subscribers
@				  07.01.2026 / Sophal Noch / US-0033990 - UK Paid Programs - Current Subscription Overview (Step 1)
*********************************************************************************************************************************/
public without sharing class BoBSellerTriggerHandler {
	/****************************************************************************************************************************
	* CONSTANTS DEFINITION
	*****************************************************************************************************************************/
	private static String BOBSELLER_LTTM_RECORDTYPE = 'LTTM';
	//private static String BOBSELLER_MANAGED_RECORDTYPE = 'Managed';
	private static String BOBSELLER_ADVERTISING_RECORDTYPE = 'Advertising'; // 05.01.2024 / Bora Chhorn / US-0014524
	private static String BOBSELLER_DRAFT_STATUS = 'Draft';
	public static String BOB_LTTM_RECORDTYPE = 'Light_Touch_Category_Cohort';
	private static final String BOB_ADS_RECORDTYPE = 'Advertising_Cohort'; // 21.09.2023 / Sophal Noch / US-0014098

	public static final Set<String> SET_BOB_RTYPES = new Set<String>{BOB_LTTM_RECORDTYPE};//TH:US-0015106:remove 'Managed_Cohort'

	private final static String BS_STATUS_INVITED = 'Invited';
    private final static String BS_STATUS_ACTIVE = 'Draft';
    private final static String BS_STATUS_INACTIVE = 'Inactive';
	private final static String BS_MANAGED_SEGMENT_PRO_TRADER_CAT = 'Pro-Trader Cat'; // 12.03.2024 / Bora Chhorn / US-0014942

	private static final Set<String> SET_BS_STATUS_TO_ACTIVATE = new Set<String>{BS_STATUS_INVITED,BS_STATUS_ACTIVE};
	private static final Set<String> SET_BS_STATUS_TO_DEACTIVATE = new Set<String>{BS_STATUS_INACTIVE};

	private static final Set<String> SET_BOB_RTYPE_TO_SYNC_ACC = new Set<String>{
		BOB_LTTM_RECORDTYPE,
		BOB_ADS_RECORDTYPE
	};

	private final static List<CohortSellerSync_Field_Change__mdt> LIST_CS_SYNC_FLD_CHANGE_MTD { // 12.03.2024 / Sophal Noch / US-0014887 
		get{
			if(LIST_CS_SYNC_FLD_CHANGE_MTD == null){
				List<CohortSellerSync_Field_Change__mdt> listCsSyncFldChangeMtd = new List<CohortSellerSync_Field_Change__mdt>(); // must use list here to keep the order of record retrieved from query
				for(CohortSellerSync_Field_Change__mdt fldChangeMtd : [Select Id, DeveloperName, Field__c, Is_Active__c, Change_Type__c, BatchCohortAction_Name__c, Old_Value__c, New_Value__c, Is_Always_Syncronous__c, RecordType__c From CohortSellerSync_Field_Change__mdt Where Is_Active__c = true Order By Order__c, Id ASC]){
					listCsSyncFldChangeMtd.add(fldChangeMtd);
				}				
				LIST_CS_SYNC_FLD_CHANGE_MTD = listCsSyncFldChangeMtd;
			}
			return LIST_CS_SYNC_FLD_CHANGE_MTD;
	 	}set;
	}

	private final static Map<String, CohortSellerSync_Field_Change__mdt> MAP_SYNC_NAME_TO_FLD_CHANGE_MTD { // 12.03.2024 / Sophal Noch / US-0014887
		get{
			if(MAP_SYNC_NAME_TO_FLD_CHANGE_MTD == null){
				Map<String, CohortSellerSync_Field_Change__mdt> mapSyncNameToFldChangeMtd = new Map<String, CohortSellerSync_Field_Change__mdt>();
				for(CohortSellerSync_Field_Change__mdt fldChangeMtd : LIST_CS_SYNC_FLD_CHANGE_MTD){
					mapSyncNameToFldChangeMtd.put(fldChangeMtd.DeveloperName, fldChangeMtd);
				}
				MAP_SYNC_NAME_TO_FLD_CHANGE_MTD = mapSyncNameToFldChangeMtd;
			}
			return MAP_SYNC_NAME_TO_FLD_CHANGE_MTD;
	 	}set;
	}

	// 12.03.2024 / Sophal Noch / US-0014887 :
	private final static String MTD_CHANG_TYPE_OLD_NEW = 'specific old value and specific new value';
	private final static String MTD_CHANG_TYPE_NEW = 'specific new value';
	private final static String MTD_CHANG_TYPE_ANY = 'any new value';

	//@ Change history: 19.07.2022 / Chetra Sarom / US-0012010
	private final static String BOB_ACTIVE_STATUS = 'BoB Active';
	private final static String BOBSELLER_INACTIVE_STATUS = 'Inactive';
	private final static String SOQL_BOBSELLER_CHECK_BOB_ACTIVE = 'Select  BoB__r.OwnerId,BoB__r.Owner.Name, Id,BoB__c,BoB__r.Name,Seller__c,Seller__r.Name, BoB__r.Status__c, BoB__r.RecordType.DeveloperName, Status__c from BoB_Seller__c WHERE BoB__c NOT IN :setBoBIds AND Seller__c IN :setSellers';
	private final static String BOB_SELLER_STATUS_SUBMITTED = 'Submitted';
	public final static String BOB_SELLER_STATUS_DRAFT = 'Draft';
	private final static String BOB_SELLER_STATUS_REMOVED = 'Removed';
	private final static String BOBSELLER_MANAGED_TYPE = 'LTTM Managed'; // 29.11.2023 / Bora Chhorn / US-0014457

	private final static String BOBSELLER_MANAGED_TYPE_MANAGED_BOB = 'Managed BoB'; // 26.05.2025 / DS / US-0012356
	private final static String BOBSELLER_MANAGED_TYPE_PAID_BOB = 'Paid BoB'; // 07.01.2026 / Sophal Noch / US-0033990
	
	//NK:16/10/2024:US-0015432 
	private final static String BOBSELLER_ADVETISING = 'Advertising';
	private final static String BOBSELLER_RT_ADVETISING = 'Advertising'; 

	// 09.11.2034 / Sophal Noch / US-0014361 : add conficted status and set<string> to skip duplicate validation
	private final static String BOB_SELLER_STATUS_CONFLICTED = 'Conflicted';
	private final static String BOB_SELLER_STATUS_NEW = 'New'; // 05.01.2024 / Bora Chhorn / US-0014524
	private final static Set<String> SET_BS_STATUS_SKIP_DUP = new Set<String>{BOB_SELLER_STATUS_REMOVED, BOB_SELLER_STATUS_CONFLICTED, BOBSELLER_INACTIVE_STATUS}; // 05.01.2024 / Bora Chhorn / US-0014524
	private final static Set<String> SET_STATUS_BOB_SELLER = new Set<String>{'Invited', 'Draft'};//Draft=Active // 29.11.2023 / Bora Chhorn / US-0014457
	private final static Set<String> SET_BOB_COUNTRY = CohortActionController.MAP_COUNTRY_KEY_TO_DOMAIN.keySet(); // 29.11.2023 / Bora Chhorn / US-0014457, 28.03.2024 / Sophal Noch / US-0015011
	//@ end : 19.07.2022 / Chetra Sarom / US-0012010

	//MN-13042023-US-0012209: Move out from EBH_ConstantsUtility class and add field Managed_Segment__c into the query
	private final static String SOQL_BOB_1 = 'Select Managed_Segment__c, Status__c, Name, RecordTypeId,Account_Manager__c,Owner.Name,owner.Email From BOB__c'; 

	/************************************END CONSTANTS DEFINITION*************************************************************/
	
    /*****************************************************************************************************************************
    @ Method:   checkBoBSellerDelete
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  [EPH-5727] BOB MGMT - Seller BOB Object - Fields
    @			AC1b)
	@			Users should be able to Create/Edit
	@			Users can only delete records that are status = New. Users can NOT delete BoB Seller records in any other status
    @			Trigger: Before Delete
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<BoB_Seller__c> list of BoB Seller
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 15.08.2018 / Vadhanak Voun / Created the  Method.
	@				  16.03.2023 / Sovantheany Dim / US-0013334 - New fields and automations on Seller Invitation process
	@				  22.04.2024 / Sovantheany Dim / US-0015107 - Retire Managed Cohort - Retire the record type Managed on Cohort Seller
    *****************************************************************************************************************************/
    public static void checkBoBSellerDelete(List<BoB_Seller__c> listBoBSellers)
    {
		//RecordType bobSellerRecordTypeManaged = ApexUtil.getRecordTypeByName('BoB_Seller__c',BOBSELLER_MANAGED_RECORDTYPE);
		RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c',BOBSELLER_LTTM_RECORDTYPE);
		Boolean isAdmin = Userinfo.getprofileId() == ApexUtil.ADMIN_PROFILE_ID;
    	for(BoB_Seller__c bs: listBoBSellers)
    	{
			//TH:US-0015107:Deactivate the record type, Managed from Cohort Seller object
    		 /*if(bs.Status__c != EBH_ConstantsUtility.BOB_SELLER_STATUS_NEW && bs.RecordTypeId == bobSellerRecordTypeManaged.Id)//TH: 05/05/2020: US-0007538 - [LTTM] "Managed Type" to be added for LTTM //Nirmala said:this msg is not developed for LTTM and we need to shown only for record type “Managed Cohort”
    		 {
    		 	bs.addError(System.Label.ErrorBoBSellerDelete);
    		 }else */
			 if(!isAdmin && bs.RecordTypeId == bobSellerRecordTypeLTTM.Id && bs.Date_Time_Invitation_Sent__c != null){//TH: US-0013334 : System should throw an error message, when BoB_Seller__c.Date / Time Invitation Sent !=NULL
				bs.addError(System.Label.Error_Deleted_InviteBobSeller);
			 }
    	}
    }

	/*****************************************************************************************************************************
    @ Method:   removeRelatedRecordWithCohortSeller
    @ Version:  1.0
    @ Author:   Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:  US-0010407 - [BoB] Empty Seller."Owner" when Category Leads click "Remove Sellers"
    @			Trigger: Before Delete
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<BoB_Seller__c> list of BoB Seller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 23.09.2021 / Mony Nou / Created the  Method.
	@ Change history: 10.01.2022 / Sophal Noch / Modified the Method. US-0011008
	@ Change history: 07.02.2022 / Sophal Noch / US-0011283 - [P1] Managed Cohorts are not set to inactive automatically when cloned cohort is Activated
					: 30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
    *****************************************************************************************************************************/
    public static void removeRelatedRecordWithCohortSeller(List<BoB_Seller__c> listBoBSellers)
    {	

		List<BoB_Seller__c> lstLTTMBoBSeller = new List<BoB_Seller__c>();
		Set<String> setRemovedBsId = new Set<String>();

		//Filtering for Cohort Seller that link with BoB's Record Type = "Light_Touch_Category_Cohort" only
		// for (BoB_Seller__c bs : [SELECT Seller__c FROM BoB_Seller__c WHERE Id IN:listBoBSellers AND BoB__r.RecordType.DeveloperName='Light_Touch_Category_Cohort']) {
		// for (BoB_Seller__c bs : [SELECT Seller__c FROM BoB_Seller__c WHERE Id IN:listBoBSellers AND BoB__r.RecordType.DeveloperName IN : SET_BOB_RTYPES]) { // 10.01.2022 / Sophal Noch / US-0011008 query both record types (Light_Touch_Category_Cohort, Managed_Cohort)
		for (BoB_Seller__c bs : [SELECT Seller__c FROM BoB_Seller__c WHERE Id IN:listBoBSellers AND BoB__r.RecordType.DeveloperName =: BOB_LTTM_RECORDTYPE]) { // 07.02.2022 / Sophal Noch / US-0011283 no need to run on Managed_Cohort because when bob RT = Managed_Cohort is active, other bobs will be inactive and account fields will be reset anyway.
			lstLTTMBoBSeller.add(bs);
			if(bs.Seller__c != null){
				setRemovedBsId.add(bs.Seller__c);
			}
			
		}

		if (lstLTTMBoBSeller.isEmpty()) return;

    	//MN-17092021-US-0010407 - Delete the related "Actions" tied to the Cohort Seller
		delete [SELECT Id FROM Action__c WHERE LTTM_Seller__c IN:lstLTTMBoBSeller];

		// 30.01.2024 / Sophal Noch / US-0014277 : disable using old method to unsync account
		// resetSellerFields(lstLTTMBoBSeller, setRemovedBsId, true); // 10.01.2022 / Sophal Noch / US-0011008 move some code to this method so the method can be reused in BoBTriggerHandler.
			
		// 30.01.2024 / Sophal Noch / US-0014277 : use batch to unsync account
		if(!BatchCohortAction.isRunning){
			Boolean isSync = !System.isFuture() && !System.isBatch() && !System.isQueueable();
			if(!setRemovedBsId.isEmpty()){
				if(isSync){
					Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_USYNC_ACC, null, setRemovedBsId)); 
				}else{
					new BatchCohortAction(BatchCohortAction.ACTION_USYNC_ACC, null, setRemovedBsId).executeSync();
				}
			}
		}




    }

	/*****************************************************************************************************************************
    @ Method:   resetSellerFields
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  US-0011008 - Clear the seller Managed fields for removed Cohort [P2] Bug - Seller and when entire Cohort is moved to status "Cohort Inactive"
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<BoB_Seller__c> list of BoB Seller
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 10.01.2022 / Sophal Noch / Create the Method
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 03.02.2022 / Sophal Noch / US-0011081 - [Bug]Clear the BoB_Subsegment__c in Account and Cohort Seller once the Cohort is Inactivated or when Cohort Seller is removed
	@ Change history: 11.02.2022 / Sophal Noch / US-0011283 - [P1] Managed Cohorts are not set to inactive automatically when cloned cohort is Activated
						15.03.2022 / Acmatac SEING / US-0011473 - [P1] Managed Cohorts are not set to inactive automatically when cloned cohort is Activated
	@				: 23.04.2024 / sovantheany dim / US-0015107 - comment out becaue managed record type is removed	
    *****************************************************************************************************************************/
	/*public static void resetSellerFields(List<BoB_Seller__c> lstLTTMBoBSeller, Set<Id> setAccId, Boolean allOrNone)
    {
		// this method is called from BoBSellerTriggerHandler and BoBTriggerHandler
		
		if (lstLTTMBoBSeller.isEmpty()) return;

		//MN-17092021-US-0010407 - Reset Seller fields
		// List<Account> lstAcc = new List<Account>();
		
		// 11.02.2022 / Sophal Noch / US-0011283 get all bob seller that is active regardless of record type, verticle, site
		Set<Id> setActiveBsAccId = new Set<Id>();
		for (BoB_Seller__c bs : [Select Seller__c From BoB_Seller__c Where Seller__c IN: setAccId And Active__c = true And Id NOT IN :lstLTTMBoBSeller]) {
			setActiveBsAccId.add(bs.Seller__c);
		}

		Map<Id,Account> mapAcc = new Map<Id,Account>();  // 03.02.2022 / Sophal Noch / US-0011081

		// for (BoB_Seller__c bs : [SELECT Seller__c FROM BoB_Seller__c WHERE Id IN:lstLTTMBoBSeller]) {
		for (BoB_Seller__c bs : lstLTTMBoBSeller) { // 11.01.2022 / Sophal Noch / US-0011008 use exist bobseller list, no need to requery
			if(setActiveBsAccId.contains(bs.Seller__c)) continue;
			// lstAcc.add(new Account(Id = bs.Seller__c, OwnerId = ApexUtil.INTEGRATION_USER_ID, Managed_Type__c = '', EBH_BOBManaged__c = false, EBH_BOBSegment__c = '', EBH_BOBVertical__c = '', EBH_BOBCNTRY__c='')); // 10.01.2022 / Sophal Noch / US-0011008 empty EBH_BOBVertical__c,EBH_BOBCNTRY__c
			mapAcc.put(bs.Seller__c, new Account(Id = bs.Seller__c, OwnerId = ApexUtil.INTEGRATION_USER_ID, Managed_Type__c = '', EBH_BOBManaged__c = false, EBH_BOBSegment__c = '', EBH_BOBVertical__c = '', EBH_BOBCNTRY__c='', BoB_Subsegment__c = '', EBH_AccountManageName__c = '')); // 03.02.2022 / Sophal Noch / US-0011081
		}

		if(!mapAcc.isEmpty()){
			// update lstAcc;
			// update mapAcc.values(); // 03.02.2022 / Sophal Noch / US-0011081
			//----MN-17092021-US-0010407 - Reset Seller fields

			// Acmatac SEING / US-0011473 / Update Account as partial
			Database.SaveResult[] bobSellerSR = Database.update(mapAcc.values(), allOrNone);
			List<Database.Error> listException = new List<Database.Error>();  
			for (Database.SaveResult sr : bobSellerSR) {
				// 15.07.2022 / Sophal Noch / US-0011996 : fix insert log in loop issue.
				// if (!sr.isSuccess()) {
				// 	// Operation failed, so get all errors                
				// 	EBH_ApexLogger.logError(sr.getErrors(), 'BoBSellerTriggerHandler','resetSellerFields');
				// }
				if (!sr.isSuccess()) listException.addAll(sr.getErrors());
			}
			if(!listException.isEmpty()) EBH_ApexLogger.logError(listException, 'BoBSellerTriggerHandler','resetSellerFields');
		}

	}*/


	/*****************************************************************************************************************************
    @ Method:   validateBoBSeller
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  EPH-6416 BOB MGMT. - Duplicate Seller Rules
	@		    AC1) Duplicate Validation Rules
	@				a) As a categroy manager (BOB OWNER) when I want to add a seller to a BOB that is in status DRAFT I shouldn't be able to select the same seller
	@				again (screenshot attached) (excluding the previous version of current BOB).
	@				b) As a category manager after cloning a BOB (i.e. the BoB is in Draft mode) I shouldn't be able to add a seller that is part of another BOB with status "ACTIVE".
    @			Trigger: Before insert,before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<BoB_Seller__c> list of BoB Seller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 03.09.2018 / Vadhanak Voun / Created the  Method.
	@				: 03.10.2018/ Vadhanak Voun	/ EPH-6449: AC2) Seller Record Owner changes after the Account Manager field is updated  on the BoB
	@ 				: 19.07.2022 / Chetra Sarom / US-0012010 - Add New Button "Deactivate Sellers" Button next to "Remove Sellers"
	@				: 01.09.2022 / SRONG TIN / US-0012222 - Amends to existing warning message when an active BoB Seller is added to another Cohort
	@				: 06.09.2022 / Sambath Seng / US-0012558 - Validations when changing Cohort Seller Status from "Inactive" to "Active"
	@				: 23.09.2022 / SRONG TIN / US-0012648 - [P1] Managed Cohorts are not set to inactive automatically when cloned cohort is Activated
	@				: 21.09.2023 / Sophal Noch / US-0014098 - ADS - Cohort Validation Rules
	@				: 19.10.2023 / Sovantheany Dim / US-0014224 - Tech Debt - Migrate the Workflow Populate Bob Seller Unique Key to Flow and other code updates
	@				: 09.11.2034 / Sophal Noch / US-0014361 - Cohort Activation Process Part 2
	@				: 15.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
	@               : 05.01.2024 / Bora Chhorn / US-0014524 - Cohort seller validation - skip for New Status
	@				: 18.04.2024 / Sophal Noch / US-0014964 - Tech Debt - Stop sending the email to the public group when Account Manager is updated
	@				: 04.06.2024 / Sophal Noch / US-0015352 - Transfer Cohort Seller Issue - Conflict and Order of execution
    *****************************************************************************************************************************/
    public static void validateBoBSeller(List<BoB_Seller__c> listBoBSellers,Map<Id,BoB_Seller__c> mapOld)
    {
    	//1, check duplicate seller
    	Boolean isNew = (mapOld==null);
    	Map<String,BoB_Seller__c> mapBoBSeller = new Map<String,BoB_Seller__c>();
    	// Map<String,BoB_Seller__c> mapSellerBS = new Map<String,BoB_Seller__c>();
		Map<String, BoB_Seller__c> mapSellerKeyToBs = new Map<String, BoB_Seller__c>(); // 21.09.2023 / Sophal Noch / US-0014098
		Map<String, List<BoB_Seller__c>> mapSellerToListBs = new Map<String, List<BoB_Seller__c>>(); // 21.09.2023 / Sophal Noch / US-0014098
		Set<String> setBoBSellers = new Set<String>();
    	Set<String> setBoBIds = new Set<String>();
    	Set<String> setSellers = new Set<String>();
		
    	for(BoB_Seller__c bs: listBoBSellers)
    	{

    		if(	(!isNew && !isSellerChanged(bs,mapOld.get(bs.Id)) && !(bs.Status__c != mapOld.get(bs.Id).Status__c)) //update but no seller changed // Sambath Seng 07.09.2022 US-0012558
    			|| (isNew && bs.Cloned__c)	//bypass clone BS: EPH-6460:CR
    		)
    		{
				continue;
    		}
    		//created with seller, or change seller (e.g. from null) 
    		//check current working BS   		
    		if(setBoBSellers.contains(bs.Id+''+bs.Seller__c))
    		{
    			 bs.addError(System.Label.ErrorSellerDuplicate);
    		}
    		setBoBSellers.add(bs.Id+''+bs.Seller__c);
    		setBoBIds.add(bs.BoB__c);
    		setSellers.add(bs.Seller__c);
    		mapBoBSeller.put(bs.BoB__c,bs); // just keep any current object to addError for friendly msg 
    		// mapSellerBS.put(bs.Seller__c,bs); //same same

			// 21.09.2023 / Sophal Noch / US-0014098 :
			mapSellerKeyToBs.put(bs.Bob__c+''+bs.Seller__c, bs); 
			List<BoB_Seller__c> listBs = mapSellerToListBs.get(bs.Seller__c);
			if(listBs == null){
				listBs = new List<BoB_Seller__c> ();
				mapSellerToListBs.put(bs.Seller__c, listBs);
			}
			listBs.add(bs);

    	}
		
    	String excludeStatus = EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED;
    	String addionalExcusion = ' AND Status__c <> :excludeStatus ';
		//check the existing in system, ignore removed seller   
		if(isNew){// Sambath Seng 07.09.2022 US-0012558
			for(BoB_Seller__c bs: Database.query(EBH_ConstantsUtility.SOQL_BOBSELLER_BY_BOB_AND_SELLER +addionalExcusion))
			{
				//TH:24/04/2020: comment out because running from batch get error : Too many retries of batch save in the presence of Apex triggers with failures: when triggers are present partial save requires that some subset of rows save without any errors in order to avoid inconsistent side effects from those triggers.
				//mapBoBSeller.get(bs.BoB__c).addError(System.Label.ErrorSellerDuplicate+'\n'+bs.Seller__r.Name);
				
				// mapSellerBS.get(bs.Seller__c).addError(System.Label.ErrorSellerDuplicate+'\n'+bs.Seller__r.Name);
				// 21.09.2023 / Sophal Noch / US-0014098 :
				BoB_Seller__c duplicateBs = mapSellerKeyToBs.get(bs.Bob__c+''+bs.Seller__c);
				if(duplicateBs != null){
					duplicateBs.addError(System.Label.ErrorSellerDuplicate+'\n'+bs.Seller__r.Name);
				}
				
			}
		}
		
		if(!BatchCohortAction.isRunning){ // 15.12.2023 / Sophal Noch / US-0014362 : skip this part when user activate cohort seller from custom components because custom component already handle this logic

			//2, check occupied seller by another Active BoB
			//NK:12/09/2018 EPH-6467 CR: showing multiple BOB Owner
			Set<String> setAffectBoBOwner = new Set<String>();
			Set<String> setAffectSeller = new Set<String>();
			Set<String> setAffectBoB = new Set<String>(); 
			//Set<String> setStatus = new Set<String>{BOB_SELLER_STATUS_SUBMITTED,BOB_SELLER_STATUS_DRAFT,BOBSELLER_INACTIVE_STATUS};
			// Set<String> setStatus = new Set<String>{BOB_SELLER_STATUS_SUBMITTED,BOB_SELLER_STATUS_DRAFT};//TH:US-0014224:AC2:Remove BOBSELLER_INACTIVE_STATUS
			// String addtionalWhere = '  AND  (Active__c = true OR BoB__r.Status__c IN :setStatus)';
			String addtionalWhere = ' AND Status__c IN :SET_STATUS_BOB_SELLER AND BoB__r.Status__c = :BOB_ACTIVE_STATUS'; // 04.06.2024 / Sophal Noch / US-0015352 : retrieve only active and invited bob sellers to check duplication
			
			//SRONG TIN / 23.09.2022 US-0012648

			/*
				// 21.09.2023 / Sophal Noch / US-0014098 : disable because it does not support multiple bob seller with the same seller
				List<BoB_Seller__c> listAffectSeller = new List<BoB_Seller__c>(); 

				for(BoB_Seller__c bs: Database.query(SOQL_BOBSELLER_CHECK_BOB_ACTIVE + addtionalWhere+addionalExcusion))
				{    		
					if(mapSellerBS.get(bs.Seller__c) != null && mapSellerBS.get(bs.Seller__c).Status__c != BOB_SELLER_STATUS_REMOVED){

						listAffectSeller.add(bs);
						setAffectBoBOwner.add(bs.BoB__r.Owner.Name);
						setAffectSeller.add(bs.Seller__r.Name);
						//SRONG TIN / 01.09.2022 US-0012222
						setAffectBoB.add(bs.BoB__c);

					}
				}
			*/

			// 21.09.2023 / Sophal Noch / US-0014098 : keep the same duplicate validation logic but allow allow seller from lttml and managed cohort to be added to advertising cohort and vice versa
			Map<Id, BoB_Seller__c> mapAffectSeller = new Map<Id, BoB_Seller__c>();
			Map<Id, List<BoB_Seller__c>> mapSellerToListDupBs = new Map<Id, List<BoB_Seller__c>>();
			Map<Id, BoB__c> mapBob = new Map<Id, BoB__c>([Select Id, RecordType.DeveloperName From BoB__c Where Id IN: setBoBIds]);
			// 05.01.2024 / Bora Chhorn / US-0014524
			RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c',BOBSELLER_LTTM_RECORDTYPE);
			RecordType bobSellerRecordTypeAdvertising = ApexUtil.getRecordTypeByName('BoB_Seller__c',BOBSELLER_ADVERTISING_RECORDTYPE);

			for(BoB_Seller__c existBs: Database.query(SOQL_BOBSELLER_CHECK_BOB_ACTIVE + addtionalWhere+addionalExcusion))
			{    	
				for(BoB_Seller__c duplicateBs : mapSellerToListBs.get(existBs.Seller__c)){

					// if(duplicateBs.Status__c == BOB_SELLER_STATUS_REMOVED){ continue; }
					if(SET_BS_STATUS_SKIP_DUP.contains(duplicateBs.Status__c)){ continue; } // 09.11.2034 / Sophal Noch / US-0014361
					
					// 05.01.2024 / Bora Chhorn / US-0014524
					if(duplicateBs.Status__c == BOB_SELLER_STATUS_NEW && (duplicateBs.RecordTypeId == bobSellerRecordTypeLTTM.Id || duplicateBs.RecordTypeId == bobSellerRecordTypeAdvertising.Id)){ continue; }
					
					BoB__c bob = mapBob.get(duplicateBs.BoB__c);
					
					if(bob != null && ((bob.RecordType.DeveloperName == BOB_ADS_RECORDTYPE && SET_BOB_RTYPES.contains(existBs.Bob__r.RecordType.DeveloperName )) || (SET_BOB_RTYPES.contains(bob.RecordType.DeveloperName) && existBs.Bob__r.RecordType.DeveloperName == BOB_ADS_RECORDTYPE))){ continue; }

					mapAffectSeller.put(existBs.Id, existBs);
					setAffectBoBOwner.add(existBs.BoB__r.Owner.Name);
					setAffectSeller.add(existBs.Seller__r.Name);
					//SRONG TIN / 01.09.2022 US-0012222
					setAffectBoB.add(existBs.BoB__c);

					List<BoB_Seller__c> listDupBs = mapSellerToListDupBs.get(existBs.Seller__c);
					if(listDupBs == null){
						listDupBs = new List<BoB_Seller__c>();
						mapSellerToListDupBs.put(existBs.Seller__c, listDupBs);
					}
					listDupBs.add(duplicateBs);
				}

			}

			List<String> listOwnerTmp = new List<String>(setAffectBoBOwner);
			List<String> listSellerTmp = new List<String>(setAffectSeller);
			//SRONG TIN / 01.09.2022 US-0012222
			List<String> listAffectBob = new List<String>();
			String serverUrl =  System.URL.getOrgDomainUrl().toExternalForm();
			for(String bobId: setAffectBoB){
				String link = serverUrl +'/'+bobId;
				listAffectBob.add(link);
			}

			//@ Change history: 19.07.2022 / Chetra Sarom / US-0012010 

			// for(BoB_Seller__c bs: listAffectSeller)
			for(BoB_Seller__c bs: mapAffectSeller.values()) // 21.09.2023 / Sophal Noch / US-0014098
			{
				BoB_Seller__c oldBs = !isNew ? mapOld.get(bs.Id) : new BoB_Seller__c();// Sambath Seng 06.09.2022 US-0012558
				if (!(bs.BoB__r.RecordType.DeveloperName == BOB_LTTM_RECORDTYPE && bs.BoB__r.Status__c == BOB_ACTIVE_STATUS && bs.Status__c == BOBSELLER_INACTIVE_STATUS)
				|| (bs.BoB__r.RecordType.DeveloperName == BOB_LTTM_RECORDTYPE && bs.BoB__r.Status__c == BOB_ACTIVE_STATUS && bs.Status__c != oldBs.Status__c && bs.Status__c == BOBSELLER_DRAFT_STATUS) // Sambath Seng 06.09.2022 US-0012558
				) { // if Seller Management record type = 'Light Touch category Cohort' and status = 'Cohort Active' and BoB_Seller__c.Status__c = 'Inactive' = system allow to created Cohort Seller
					//SRONG TIN / 01.09.2022 US-0012222
					String errorMsg = System.Label.ErrorSellerPartOfActiveBoB.replace('BOB_OWNER_NAME',String.join(listOwnerTmp,','))+'\nAffect Seller: '+String.join(listSellerTmp,',');
					errorMsg = errorMsg.replace('EFFECTIVE_BOB',String.join(listAffectBob,','));
					// mapSellerBS.get(bs.Seller__c).addError(errorMsg,false);
					for(BoB_Seller__c duplicateBs : mapSellerToListDupBs.get(bs.Seller__c)) { // 21.09.2023 / Sophal Noch / US-0014098
						duplicateBs.addError(errorMsg,false);
					}
				}
			}
			// end 19.07.2022 / Chetra Sarom / US-0012010 			
		}

    }


	private static Boolean isSellerChanged(BoB_Seller__c bsNew, BoB_Seller__c bsOld)
	{
		return bsNew.Seller__c <> bsOld.Seller__c;
	}
	/*****************************************************************************************************************************
    @ Method:   populateBobSeller
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  US-0007354 - LTTM - Manual addition of LTTM BoB Sellers
	@ 1) On Creation /update of "BoB_Seller__c"(Managed Sellers) via Manual or Bulk upload
	@ if "Parent Seller" Field in "BoB_Seller__c" = ""
	@ Autopopulate the "BoB_Seller__c"."Parent Seller" = BoB_Seller__c"."Seller"
	@ 2) 1.1 System to auto populate
	@	BoB_Seller__c. Account_Manager__c = BOB__c. Account_Manager__c
	@	BoB_Seller__c. EBH_BOBSegment__c = "LTTM"
	@ 
    @			Trigger: Before insert,before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<BoB_Seller__c> listBoBSellers, Map<Id,BoB_Seller__c> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.03.2020 / Sovantheany Dim / Created the  Method.
	@				  13.04.2023 / Mony Nou / US-0012209 - AC2
	@				  11.05.2023 / Bora Chhorn / US-0013649 - Bulk upload of Cohort Sellers not inheriting the BoB__C.Managed Segment Value
	@				  30.06.2023 / Sovantheany dim / US-0013781 - Account Manager of the Cohort Seller is empty when adding a singular seller
	@				  25.1.2024 / SOVANTHEANY DIM / US-0014729 - Managed Segment field value on Cohort Seller shouldn't be overwritten
	@				  28.11.2024/ Chan Sophorn / US-0016308 - After Transfer BoB-Seller then Create New BoB-Seller with New BoB-Seller's Account Manager, if BoB-Seller's Account Manager has value
    *****************************************************************************************************************************/
    public static void populateBobSeller(List<BoB_Seller__c> listBoBSellers,Map<Id,BoB_Seller__c> mapOld)
    {
    	RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c',BOBSELLER_LTTM_RECORDTYPE);
    	Boolean isNew = (mapOld==null);
    	set<String> sBob = new Set<String>();
    	for(BoB_Seller__c bobSeller : listBoBSellers){
    		if(bobSeller.BoB__c != null && bobSeller.RecordTypeId == bobSellerRecordTypeLTTM.Id){//TH: 14/05/2020 : US-0007576 : add Condition for Record type LTTM
			 	sBob.add(bobSeller.BoB__c);
			 }
    	}
    	if(sBob.isEmpty()) return;
    	String lttmRecordTypeid = bobRecordTypeLTTM.Id;
    	String whereCl = ' where id IN: sBob and RecordTypeId =: lttmRecordTypeid';
    	Map<Id,BOB__c> mapBob = new Map<Id,BOB__c>((List<BOB__c>) Database.query(SOQL_BOB_1 + whereCl)); //MN-13042023-US-0012209-Using variable from this class instead
    	//auto populate bobSeller.Account Manager = bob.Account Manager
    	for(BoB_Seller__c bobSeller : listBoBSellers){
    		if(!mapBob.containsKey(bobSeller.BoB__c)) continue;
			BOB__c bob = mapBob.get(bobSeller.BoB__c);
			//System.debug('isBatchBobSeller::'+Batch_BobSellerBulkCSV.isBatchBobSeller);
			//TH:US-0013781 when bob seller is manually created and bob.Account_Manager__c != null , auto populate bobSeller.Account_Manager__c = bob.Account_Manager__c;
			//28.11.2024/ CSP / US-0016308
    		if(isNew && ((!Batch_BobSellerBulkCSV.isBatchBobSeller && bob.Account_Manager__c != null && bobSeller.Account_Manager__c == null ) || (Batch_BobSellerBulkCSV.isBatchBobSeller && bobSeller.Account_Manager__c == null))){

    			//set default Segment//TH: Comment out 19/06/2020: US-0007674 - Add new field "Managed Type" in Account and sync values with BoB_Seller__c
    			//bobSeller.EBH_BOBSegment__c = EBH_ConstantsUtility.BOB_SELLER_SEGMENT_LTTM;
    			//auto populate bobSeller.Account Manager = bob.Account Manager
    			bobSeller.Account_Manager__c = bob.Account_Manager__c;
				// bobSeller.EBH_BOBSegment__c = bob.Managed_Segment__c; //MN-13042023-US-0012209-AC2 // Comment by //BR-11052023-US-0013649
    		}
			//TH:US-0014729:auto populate bobSeller.EBH_BOBSegment__c = bob.Managed_Segment__c; only if bobSeller.EBH_BOBSegment__c is empty
			if(isNew && bobSeller.EBH_BOBSegment__c == null) bobSeller.EBH_BOBSegment__c = bob.Managed_Segment__c; //BR-11052023-US-0013649
    		//set "Parent Seller" = seller if Parent Seller is empty
    		if(bobSeller.Parent_Seller__c == null && bobSeller.Seller__c <> null && (isNew || (!isNew && bobSeller.Seller__c <> mapOld.get(bobSeller.Id).Seller__c)) ){
    			bobSeller.Parent_Seller__c = bobSeller.Seller__c;
    		}
    	}
    }


	/*****************************************************************************************************************************
    @ Method:   populateSchduleSlotsWithBS
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  US-0011996 - Call booking for Ads
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     listNewBs = list of New Bob Seller, mapOldBs =  map of Old Bob Seller 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.07.2022 / Sophal Noch / Created the  Method.
    *****************************************************************************************************************************/
	public static void populateSchduleSlotsWithBS(List<BoB_Seller__c> listNewBs,Map<Id,BoB_Seller__c> mapOldBs)
    {

		RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c',BOBSELLER_LTTM_RECORDTYPE);

		Boolean isNewOrDelete = mapOldBs == null ? true : false;
		Set<String> setUniqueId = new Set<String>();
		for(BoB_Seller__c newBs : listNewBs){

			BoB_Seller__c oldBs = !isNewOrDelete ? mapOldBs.get(newBs.Id) : null;

			// when there are changes in bob_seller__c like bob_seller__c.Account_Manager__c, User_Availability__c of Old bob_seller__c.Account_Manager__c need to be re-calculated.
			if(!isNewOrDelete && validateSchduleSlotsWithBS(bobRecordTypeLTTM, true, oldBs, newBs)){
				setUniqueId.add(UserAvailabilityTriggerHandler.createUniqueId(oldBs.Account_Manager__c, oldBs.Next_Call_Schedule_Date__c));
			}

			// when there are changes in bob_seller__c like bob_seller__c.Account_Manager__c, User_Availability__c of New bob_seller__c.Account_Manager__c need to be re-calculated.
			if((!isNewOrDelete && validateSchduleSlotsWithBS(bobRecordTypeLTTM, true, newBs, oldBs)) || (isNewOrDelete && validateSchduleSlotsWithBS(bobRecordTypeLTTM, false, newBs, null))){
				setUniqueId.add(UserAvailabilityTriggerHandler.createUniqueId(newBs.Account_Manager__c, newBs.Next_Call_Schedule_Date__c));
			}

		}

		if(!setUniqueId.isEmpty()) UserAvailabilityTriggerHandler.calculateSlotsFromRelatedObj(setUniqueId, false, true);

	}

	private static Boolean validateSchduleSlotsWithBS(RecordType recType, Boolean isCompareField, BoB_Seller__c targetBs, BoB_Seller__c comparedBs){
		return ((targetBs.RecordTypeId == recType.Id && targetBs.Account_Manager__c != null && targetBs.Next_Call_Schedule_Date__c != null && targetBs.Time_Slot__c != null)
				&& (!isCompareField || (isCompareField && (targetBs.RecordTypeId != comparedBs.RecordTypeId || targetBs.Account_Manager__c != comparedBs.Account_Manager__c || targetBs.Next_Call_Schedule_Date__c != comparedBs.Next_Call_Schedule_Date__c || targetBs.Time_Slot__c != comparedBs.Time_Slot__c))));
	}

	/*****************************************************************************************************************************
    @ Method:   populateSomeValues
    @ Version:  1.0
    @ Author:   Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:  US-0013681 - Error when trying to update Account manager and managed Segment
	@			Moving the flow Cohort Seller-Populate Vertical Feild to trigger
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter	: listNewBs = list of New Bob Seller
	@ Trigger 	: before insert, before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.06.2023 / Acmatac Seing / Created the  Method.
	@				: 15.08.2023 / Sophal Noch / US-0013955 - Error when trying to update Account manager and managed Segment
	@				: 12.03.2024 / Bora Chhorn / US-0014942 - When Seller Signs up for the PT program, check the Seller Signed up flag
	@				: 29.03.2024 / Sophal Noch / US-0015044 - Error Null Pointer when transferring Cohort Seller
    *****************************************************************************************************************************/
	public static void populateSomeValues(List<BoB_Seller__c> listNewBs, Map<Id, BoB_Seller__c> mapOldBs)
    {
		
		Datetime currentDateTime = System.now();
		Boolean isNew = mapOldBs == null ? true : false; // 29.03.2024 / Sophal Noch / US-0015044

		for(BoB_Seller__c newBS: listNewBs){

			BoB_Seller__c oldBs = isNew ? null : mapOldBs.get(newBS.Id);

			newBS.Vertical__c = newBS.Main_Vertical__c;
			newBS.BoB_Owner_Email__c = newBS.BoB_Owner_Email_f__c;
			newBS.Seller_Portal_Eligible__c = isChangedAndEligible(newBS, oldBs); // 29.11.2023 / Bora Chhorn / US-0014457
			// 12.03.2024 / Bora Chhorn / US-0014942
			if(newBS.EBH_BOBSegment__c == BS_MANAGED_SEGMENT_PRO_TRADER_CAT && (!isNew && newBS.Status__c == BS_STATUS_ACTIVE && oldBs.Status__c == BS_STATUS_INVITED)){
				newBS.Seller_Signed_up__c = true;
			}
			// END / US-0014942
			// 15.08.2023 / Sophal Noch / US-0013955 : move logic from process builder on user story US-0009330 to trigger
			if(newBS.Seller_Signed_up__c == true && (isNew || newBS.Seller_Signed_up__c != oldBs.Seller_Signed_up__c)){
				newBS.Seller_Signed_up_Date__c = currentDateTime;
			}

		}
	}

	/*****************************************************************************************************************************
    @ Method:   isChangedAndEligible
    @ Version:  1.0
    @ Author:   Bora Chhorn (bora.chhorn@gaea-sys.com)
    @ Purpose:  US-0014457 - Ph 1 - Restriction Rules - to expose Cohort Seller Data for only eligible sellers
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.11.2023 / Bora Chhorn / Created the  Method.
	@				  11.03.2024 / Acmatac Seing / US-0014548 - Launch - Remove the Seller Portal Beta User from the restriction Rule
	@				  14.05.2024 / Sophal Noch / US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
	@				  16.10.2024/ vadhanak voun / US-0015432 - ADS - Eligibility for Advertising program component
	@				  13.05.2025 / Davy Sorn / US-0012356 - 1. Enable Account Management and call booking for Account Management sellers
	@				  03.07.2025 / Sophal Noch / US-0033064 - Limiting paid programs visibility to only existing subscribers
	@				  07.01.2026 / Sophal Noch / US-0033990 - UK Paid Programs - Current Subscription Overview (Step 1)
    *****************************************************************************************************************************/
	private static Boolean isChangedAndEligible(BoB_Seller__c bsNew, BoB_Seller__c bsOld)
    {
		Boolean isNew = bsOld == null ? true : false;
		Boolean sellerPortalEligible = bsNew.Seller_Portal_Eligible__c;
		if((isNew || bsNew.Status__c != bsOld.Status__c)){
			// 11.03.2024 / Acmatac Seing / US-0014548, 14.05.2024 / Sophal Noch / US-0015200 : add bsNew.EBH_BOBSegment__c == BS_MANAGED_SEGMENT_PRO_TRADER_CAT
			sellerPortalEligible = bsNew.Managed_Type__c == BOBSELLER_MANAGED_TYPE && bsNew.EBH_BOBSegment__c == BS_MANAGED_SEGMENT_PRO_TRADER_CAT && SET_STATUS_BOB_SELLER.contains(bsNew.Status__c) && SET_BOB_COUNTRY.contains(bsNew.BoB_Country__c);

			/* 03.07.2025 / Sophal Noch / US-0033064 : disable code below and check eligibility for GSD Account Management in SEP_Helper.isGSDAccMgnEligible instead
				// 13.05.2025 / Davy Sorn / US-0012356
				if (sellerPortalEligible == false) {
					sellerPortalEligible = bsNew.RecordTypeName__c == BOBSELLER_LTTM_RECORDTYPE &&
					bsNew.Managed_Type__c == BOBSELLER_MANAGED_TYPE_MANAGED_BOB && 
					bsNew.EBH_BOBSegment__c != BS_MANAGED_SEGMENT_PRO_TRADER_CAT &&
					SET_STATUS_BOB_SELLER.contains(bsNew.Status__c);
				}
			*/
			sellerPortalEligible = sellerPortalEligible == false ? SEP_Helper.isGSDAccMgnEligible(bsNew)  : sellerPortalEligible; // 03.07.2025 / Sophal Noch / US-0033064 : check eligibility for GSD Account Management

			//NK:16/10/2024:US-0015432
			sellerPortalEligible = sellerPortalEligible == false ? isBookingdEligible(bsNew, bsOld) : sellerPortalEligible;

			// 07.01.2026 / Sophal Noch / US-0033990 :
			sellerPortalEligible = sellerPortalEligible == false ? isPaidProgramEligible(bsNew, bsOld) : sellerPortalEligible;
		}
		return sellerPortalEligible;
	}

	/*****************************************************************************************************************************
    @ Method:   isBookingdEligible
    @ Version:  1.0
    @ Author:   vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0015432 - ADS - Eligibility for Advertising program component
	@				// AND BoB__r.Status__c = 'BoB Active' 
	@				// AND Managed_Type__c = 'Advertising' 
	@				// AND RecordType.DeveloperName='Advertising' 
	@				// AND Status__c IN ('Invited', 'Draft') 
	@				// AND Seller__r.Brand_Engagement_Lead__c != null 
	@				// AND Seller__r.Brand_Engagement_Lead__r.Calendly__CalendlyLink__c != null	 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.10.2024 / vadhanak voun / Created the  Method.
    *****************************************************************************************************************************/
	private static Boolean isBookingdEligible(BoB_Seller__c bsNew, BoB_Seller__c bsOld)
    {
		return  
		bsNew.Seller_Management_Status__c==BOB_ACTIVE_STATUS
		&& bsNew.Managed_Type__c==BOBSELLER_ADVETISING
		&& bsNew.RecordTypeName__c==BOBSELLER_ADVETISING
		&& (bsNew.Status__c == BS_STATUS_INVITED || bsNew.Status__c == BS_STATUS_ACTIVE)
		&& String.isNotBlank(bsNew.Ads_Partner_Manager_Calendly__c);
	}

	/*****************************************************************************************************************************
    @ Method:   isPaidProgramEligible
    @ Version:  1.0
    @ Author:   Sophal Noch
    @ Purpose:  US-0033990 - UK Paid Programs - Current Subscription Overview (Step 1)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.01.2025 / Sophal Noch / Created the  Method.
    *****************************************************************************************************************************/
	private static Boolean isPaidProgramEligible(BoB_Seller__c bsNew, BoB_Seller__c bsOld){
		return
		bsNew.Seller_Management_Status__c==BOB_ACTIVE_STATUS
		&& bsNew.Status__c == BS_STATUS_ACTIVE
		&& bsNew.Managed_Type__c == BOBSELLER_MANAGED_TYPE_PAID_BOB
		&& bsNew.RecordTypeName__c == BOBSELLER_LTTM_RECORDTYPE;
	}

	/*********************************************************************************************************************************
    @ Method:         syncBoBSellerToAcc
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        11.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  11.12.2023 / Sophal Noch / US-0014362 / Sophal Noch / Created the method.
					:  11.12.2023 / Sophal Noch / US-0014363 - Ph 1 - Deactivate Sellers button
					:  30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
					:  14.02.2024 / Sophal Noch / US-0014756 - Data Synchronization of the Managed fields when the Account Manager on Active Cohort is updated
					:  22.02.2024 / Acmatac Seing / US-0014796 / When Cohort Status updated from Invited to Active we should run it in Synchronously mode.
					:  12.03.2024 / Sophal Noch / US-0014887 - ADS - Data synchronization of additional Managed fields
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
	public static void syncBoBSellerToAcc(List<BoB_Seller__c> listNewBs, Map<Id, BoB_Seller__c> mapOldBs){
		if(BatchCohortAction.isRunning){ 
			return;
		}

		Map<String, Set<String>> mapSyncNameToSetBsId = new Map<String, Set<String>>();
		for(BoB_Seller__c bs : listNewBs){

			BoB_Seller__c oldBs = mapOldBs.get(bs.Id);

			if(	bs.BoB__c == null 
				|| (!SET_BS_STATUS_TO_ACTIVATE.contains(bs.Status__c) && !SET_BS_STATUS_TO_DEACTIVATE.contains(bs.Status__c))
				|| (bs.Status__c != BS_STATUS_ACTIVE && bs.Status__c == oldBs.Status__c)
			){
				continue;
			}
			
			for(CohortSellerSync_Field_Change__mdt fldChangeMtd : LIST_CS_SYNC_FLD_CHANGE_MTD){

				if(fldChangeMtd.RecordType__c != null && !fldChangeMtd.RecordType__c.contains(bs.RecordTypeId)){ // 12.03.2024 / Sophal Noch / US-0014887 : only sync when record type is matched between metadata and cohort seller
					continue;
				}
				Object fldNewValue = bs.get(fldChangeMtd.Field__c);
				Object fldOldValue = oldBs.get(fldChangeMtd.Field__c);
				Object mtdNewValue = (Object)fldChangeMtd.New_Value__c;
				Object mtdOldValue = (Object)fldChangeMtd.Old_Value__c;
				if(  // 12.03.2024 / Sophal Noch / US-0014887 : the same field has multiple ways to check whether old and new value are changed
					fldNewValue != fldOldValue
					&& (
						(fldChangeMtd.Change_Type__c == MTD_CHANG_TYPE_OLD_NEW && fldNewValue == mtdNewValue && fldOldValue == mtdOldValue)
						|| (fldChangeMtd.Change_Type__c == MTD_CHANG_TYPE_NEW && fldNewValue == mtdNewValue)
						|| (fldChangeMtd.Change_Type__c == MTD_CHANG_TYPE_ANY)
					)
				){
					Set<String> setBsId = mapSyncNameToSetBsId.get(fldChangeMtd.DeveloperName);
					if(setBsId == null){
						setBsId = new Set<String>();
						mapSyncNameToSetBsId.put(fldChangeMtd.DeveloperName, setBsId);  // 12.03.2024 / Sophal Noch / US-0014887 : store set of cohort seller id by metdata name because each set has different BatchCohortAction action name
					}
					setBsId.add(bs.Id);
					break;
				}
			}

		}
		if(mapSyncNameToSetBsId.isEmpty()){
			return;
		}

		Boolean isAsyncRunning = System.isFuture() || System.isBatch() || System.isQueueable();
		for(String fldChangeName : mapSyncNameToSetBsId.keySet()){
			Set<String> setBsId = mapSyncNameToSetBsId.get(fldChangeName);
			CohortSellerSync_Field_Change__mdt fldChangeMtd = MAP_SYNC_NAME_TO_FLD_CHANGE_MTD.get(fldChangeName);
			if(isAsyncRunning || fldChangeMtd.Is_Always_Syncronous__c){ // 12.03.2024 / Sophal Noch / US-0014887 : run sync process when current process is async or metadata config is set to always run synchronously
				new BatchCohortAction(fldChangeMtd.BatchCohortAction_Name__c, null, setBsId).executeSync();
			}else{
				Database.executeBatch(new BatchCohortAction(fldChangeMtd.BatchCohortAction_Name__c, null, setBsId)); 
			}
		}	

	}

}