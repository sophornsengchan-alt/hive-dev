/*********************************************************************************************************************************
@ Class:        ManageSellerInitiateCallController
@ Version:      1.0
@ Author:       vadhanak.voun (vadhanak.voun@gaea-sys.com)
@ Purpose:      US-0007452 - LTTM - Managed Sellers(Initiate call)
@				Controller for aura: ManageSellerInitiate
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.04.2020 / vadhanak.voun (vadhanak.voun@gaea-sys.com) / Created the class.
				: 30.07.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / Modify a method.
				: 03.07.2023/ Sophal Noch / US-0013169 - Validation to not allow "Initiate Call" for Inactive Cohort Sellers
				: 10.04.2024 / Sophal Noch / US-0014987 - Convert Initiate Call button screen from Aura to LWC
				: 05.07.2024 / Sovantheany Dim / US-0015460 - Hide deactivated contacts from Contact related list view
				: 05.11.2024 / Sovantheany Dim / US-0016104 - Initiate call does not allow to track DMC not committed
				: 29.07.2025 / Davy Sorn / US-0033116 - Genesys - Pro-Trader Cohort Seller Initiate Call seamless flow
@				: 12.11.2025 / karthik nag / US-0033693 - Bulk Edit Actions (Cohort Seller)
*********************************************************************************************************************************/
public with sharing class ManageSellerInitiateCallController {
	
	final static String TASK_TYPE_GCC = 'Growth Coaching Call';
	private final static String AU_PROFILE = 'AU Standard User Profile';
	private final static String STATUS_INACTIVE = 'Inactive';
	private final static String STATUS_OK = 'ok';
	private final static String STATUS_KO = 'ko';

	/*****************************************************************************************************************************
    @ Method:   apexInit
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0007452 - LTTM - Managed Sellers(Initiate call)
	@		    Init list for component
	@		Validation on the button "Initiate call"
	@		LTTM Agent (Standard user profile user)cannot click "Initiate call" with seller if BoB_seller has NO associated Actions
	@		On Click of “Initiate Call” check
	@		if the BoB_seller has associated Actions
	@		If yes proceed with the Initiate call flow
	@		If no Actions throw below error message
	@		Error Message
	@		Click “Create Actions” to create the Actions for each of the LTTM Sellers before initiating the call with Seller.
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String bob seller id
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 24.04.2020 / Vadhanak Voun / Created the  Method.
	@				: 23/06/2020 / Vadhanak Voun / US-0007763 - [Hyper Care] "DMC Not Committed" label not appearing once the mass Edit of Action Outcome is saved
	@							 label has been renamed but value still the same. datatable can not reflect the change
	@				: 06/08/2021 / Sovantheany Dim/ US-0010034 : hide colum Seller facing Dashboard message from Action Table for GCX
	@				: 15.10.2021/ vadhanak voun (vadhanak.voun@gaea-sys.com) / US-0010579 - [AU] Remove Visibility of Activity.SR Number for AU Standard user profile users
	@				: 03.07.2023/ Sophal Noch / US-0013169 - Validation to not allow "Initiate Call" for Inactive Cohort Sellers
	@				: 10.04.2024 / Sophal Noch / US-0014987 - Convert Initiate Call button screen from Aura to LWC
	@				: 05.11.2024 / Sovantheany Dim / US-0016104 - Initiate call does not allow to track DMC not committed
	@				: 29.07.2025 / Davy Sorn / US-0033116 - Genesys - Pro-Trader Cohort Seller Initiate Call seamless flow
    *****************************************************************************************************************************/
	
	@AuraEnabled
	public static Map<String,Object> apexInit(String recordId) {

		Map<String,Object> mapResponseData = new Map<String,Object>();
		try {

			//LA:20-09-2021:US-0010363: add two fields SRNumber__c,LastCallDate__c in query
			//List<BoB_Seller__c> listBobSeller = [Select  SRNumber__c,LastCallDate__c,Advisor_Comments__c,Call_Attempt__c,Next_Call_Schedule_Date__c,Comments__c,Name, Call_Outcome__c, Status__c,Id,Seller__c,LTTM_Group__c,BoB__r.LTTM_Group__c,(Select Id From Actions__r limit 1) from BoB_Seller__c where Id =:recordId];
			String soqlCohortSeller = 'Select MostRecentContactPhone__c, SRNumber__c,LastCallDate__c,Advisor_Comments__c,Call_Attempt__c,Next_Call_Schedule_Date__c,Comments__c,Name, Call_Outcome__c, Status__c,Id,Seller__c,LTTM_Group__c,BoB__r.LTTM_Group__c,(Select Id From Actions__r limit 1) from BoB_Seller__c where Id =:recordId';
			List<BoB_Seller__c> listBobSeller = ApexSafe.query().secCheck(false).doQuery(soqlCohortSeller,new Map<String, Object> {'recordId' => recordId});
			if(listBobSeller[0].Actions__r.isEmpty())
			{
				mapResponseData.put('status',STATUS_KO);
				mapResponseData.put('error',Label.Error_No_Actions_When_InitiateCall); // 03.07.2023/ Sophal Noch / US-0013169, 10.04.2024 / Sophal Noch / US-0014987
			}else if(listBobSeller[0].Status__c == STATUS_INACTIVE){ // 03.07.2023/ Sophal Noch / US-0013169
				mapResponseData.put('status',STATUS_KO);
				mapResponseData.put('error',Label.ErrorInitiateCallInactiveCohortSeller);
			}else
			{
				Boolean isAccessGenesysPS = FeatureManagement.checkPermission(ApexUtil.ACCESS_GENESYS_CUSTOM_PERMISSION);
				Boolean isAUProfileOnly = Userinfo.getprofileId()== ApexUtil.getProfileByName(AU_PROFILE).Id; //NK:15/10/2021:US-0010579
				//LA:20-09-2021:US-0010363
				Boolean isAUProfile = (Userinfo.getprofileId()== ApexUtil.getProfileByName(AU_PROFILE).Id || UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID));//Loumang:20-09-2021:US-0010363
				Set<Id> sellerId = new Set<Id>();
				for (BoB_Seller__c oneSeller : listBobSeller) {
					sellerId.add(oneSeller.Seller__c);
				}
				Map<String,String> mapFixLabel = new Map<String,String>{'RecordType.Name'=>'Record Type','Owner.Name'=>'Owner'};
				
				List<ColName> listColNameContact = new List<ColName>();
				Set<String> setFieldNameCont = new Set<String>{'id'};

				populateContactColName(mapFixLabel, listColNameContact, setFieldNameCont); // 10.04.2024 / Sophal Noch / US-0014987 : move some code to a separate method
				
				List<ColName> listColNameAction = new List<ColName>();
				Set<String> setFieldNameAction = new Set<String>{'id'};
				//TH:US-0016104 : comment out toLabel(Action_Outcome__c)
				//Map<String,String> mapFixPkl = new Map<String,String>{'Action_Outcome__c'=>'toLabel(Action_Outcome__c)Action_Outcome__c'};
				Map<String,String> mapFixPkl = new Map<String,String>();

				populateActionColName(mapFixLabel, isAUProfile, listColNameAction, setFieldNameAction, mapFixPkl); // 10.04.2024 / Sophal Noch / US-0014987 : move some code to a separate method

				String soqlCont = 'Select '+String.join(new List<String>(setFieldNameCont),',')+' From Contact Where AccountId IN :sellerId and Active_Contact__c = true'; //TH:05.07.2024: US-0015460 : Hide deactivated contacts from Contact related list
				String soqlAction = ' Select '+String.join(new List<String>(setFieldNameAction),',')+' From Action__c Where LTTM_Seller__c=:recordId';//LA:20-09-2021:US-0010363: add two fields SRNumber__c,LastCallDate__c in query
				
				//Contact[] listContact = Database.query(soqlCont); //[Select Id, Name, Account.Name, Email, RecordType.Name, Phone, Owner.Alias From Contact Where AccountId IN :sellerId];
				Contact[] listContact = ApexSafe.query().doQuery(soqlCont,new Map<String, Object> {'sellerId' => sellerId});
				//Action__c[] listActions = Database.query(soqlAction);
				Action__c[] listActions = ApexSafe.query().doQuery(soqlAction,new Map<String, Object> {'recordId' => recordId});
				mapResponseData.put('listColNameContact',listColNameContact);
				mapResponseData.put('listContact',listContact);
				mapResponseData.put('listColNameAction',listColNameAction);
				mapResponseData.put('actionOutComePicklists',ApexUtil.getPicklistValues(Action__c.Action_Outcome__c));//TH:US-0016104:Get picklist values for Action_Outcome__c
				mapResponseData.put('listActions',listActions);
				mapResponseData.put('bobSeller',listBobSeller[0]);
				mapResponseData.put('recordTypeActionId',ApexUtil.getRecordTypeByName('Action__c','LTTM').Id);
				mapResponseData.put('sitePrefix',Site.getPathPrefix());
				
				mapResponseData.put('status',STATUS_OK);
				mapResponseData.put('isAUProfile',isAUProfile);//Loumang:20-09-2021:US-0010363: put AU profile in mapResult
				mapResponseData.put('isAUProfileOnly',isAUProfileOnly);
				mapResponseData.put('isAccessGenesysPS',isAccessGenesysPS);
			}
        } catch (Exception e) {
			mapResponseData.put('status',STATUS_KO);
			mapResponseData.put('error',e.getMessage());
		}
        return mapResponseData;
    }	

	private static void populateContactColName(Map<String,String> mapFixLabel, List<ColName> listColNameContact, Set<String> setFieldNameCont){
		for(Schema.FieldSetMember f: SObjectType.Contact.FieldSets.InitiateCallBoBSeller.getFields()){
			setFieldNameCont.add(f.getFieldPath());
			if(f.getFieldPath().contains('.') && f.getFieldPath().endsWith('Name'))
			{
				String fId = ApexUtil.getFieldIdRef(f.getFieldPath());
				setFieldNameCont.add(fId);
			}
		
			listColNameContact.add(
				new ColName(mapFixLabel.containsKey(f.getFieldPath())?mapFixLabel.get(f.getFieldPath()):f.getLabel(),
				f.getFieldPath(),
				f.getType()+'')
			);
		}
	}

	private static void populateActionColName(Map<String,String> mapFixLabel, Boolean isAUProfile, List<ColName> listColNameAction, Set<String> setFieldNameAction, Map<String,String> mapFixPkl){

		for(Schema.FieldSetMember f: SObjectType.Action__c.FieldSets.InitiateCall.getFields())
		{
			//TH:US-0010034:06/08/2021:hide colum "Seller facing Dashboard message" from Action Table for GCX 
			if(Userinfo.getprofileId()==EBH_ConstantsUtility.PROFILE_GCX_PARTNER_ID && f.getFieldPath() == 'Seller_facing_Dashboard_message__c') {continue;}
			
			if(!isAUProfile && (f.getFieldPath() == 'SRNumber__c' || f.getFieldPath() == 'LastCallDate__c' )) {continue;}//LA:20-09-2021:US-0010363:if profile is not AU profile, hide column SRNumber__c and LastCallDate__c
			
			setFieldNameAction.add(mapFixPkl.containsKey(f.getFieldPath())?mapFixPkl.get(f.getFieldPath()):f.getFieldPath() );
			
			if(f.getFieldPath().contains('.') && f.getFieldPath().endsWith('Name'))
			{
				String fId = ApexUtil.getFieldIdRef(f.getFieldPath());
				setFieldNameAction.add(fId);
			}
		
			listColNameAction.add(
				new ColName(mapFixLabel.containsKey(f.getFieldPath())?mapFixLabel.get(f.getFieldPath()):f.getLabel(),
				f.getFieldPath(),
				f.getType()+'')
			);
		}
	}

	
	/*****************************************************************************************************************************
    @ Method:   apexSave
    @ Version:  2.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:        US-0007888
	@                 As a...
	@                 Any user
	@                 Want to...
	@                 the capability to record Growth coaching call with Sellers and record Call Log - Agent Name, Date when call recorded, record Inbound Call Attempts.
	@                 So that...
	@                 every Inbound call can be recorded and the Agent performance can be calculated.
	@                 Description
	@                 Summary - Inbound call tracking capability to record call Log for every Inbound call initiated by LTTM + Concierge team
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      bob seller bs, list action, boolean bsOnly, list contact
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 30.07.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / modify a method
	@ 				: 10.04.2024 / Sophal Noch / US-0014987 - Convert Initiate Call button screen from Aura to LWC
    *****************************************************************************************************************************/

	@AuraEnabled

    public static Map<String,Object> apexSave(BoB_Seller__c bs, List<Action__c> listActions,Boolean bsOnly,Boolean isFromSeller,List<Contact> listContacts,Map<String,String> addParam) {

        return apexSaveWithCallAttempt(bs, listActions, bsOnly, isFromSeller, listContacts, addParam, true);

    }
    /*****************************************************************************************************************************
    @ Method:   apexSaveBulkEditOnly
    @ Version:  1.0
    @ Author:   karthik nag 
    @ Purpose:  US-0033693 - Bulk Edit Actions (Cohort Seller)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.11.2025 / karthik nag / Created the  Method.
    *****************************************************************************************************************************/

	@AuraEnabled

    public static Map<String,Object> apexSaveBulkEditOnly(BoB_Seller__c bs, List<Action__c> listActions,Boolean bsOnly,Boolean isFromSeller,List<Contact> listContacts,Map<String,String> addParam) {

        // Call the enhanced save method but don't increment call attempt for bulk edits

        return apexSaveWithCallAttempt(bs, listActions, bsOnly, isFromSeller, listContacts, addParam, false);

    }

	@AuraEnabled
	public static Map<String,Object> apexSaveWithCallAttempt(BoB_Seller__c bs, List<Action__c> listActions,Boolean bsOnly,Boolean isFromSeller,List<Contact> listContacts,Map<String,String> addParam, Boolean incrementCallAttempt) {

		Map<String,Object> mapResponseData = new Map<String,Object>();
		Savepoint sp = Database.setSavepoint();
		try {
			if (incrementCallAttempt) {
				bs.Call_Attempt__c = (bs.Call_Attempt__c==null?0:bs.Call_Attempt__c) +1;
			}
			//update bs;
			ApexSafe.dml().secCheck(false).doUpdate(new List<BoB_Seller__c>{bs}, true);
			//if(!bsOnly)update listActions;
			if(!bsOnly){
				ApexSafe.dml().doUpdate(listActions, true);
			}
			if(isFromSeller){ //US-0007888 if user click from RecordInboundCall page, create Task
				createTask(bs,listContacts,addParam);
			}
			mapResponseData.put('status',STATUS_OK);
		}catch(Exception ex){
			Database.rollback(sp);
			mapResponseData.put('status',STATUS_KO);
			mapResponseData.put('error',ex.getMessage());
		}
		return mapResponseData;
	}

	/*****************************************************************************************************************************
    @ Method:   createTask
    @ Version:  2.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:        US-0007888
	@                 As a...
	@                 Any user
	@                 Want to...
	@                 the capability to record Growth coaching call with Sellers and record Call Log - Agent Name, Date when call recorded, record Inbound Call Attempts.
	@                 So that...
	@                 every Inbound call can be recorded and the Agent performance can be calculated.
	@                 Description
	@                 Summary - Inbound call tracking capability to record call Log for every Inbound call initiated by LTTM + Concierge team
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      bob seller bs, list action, boolean bsOnly, list contact
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 30.07.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / modify a method
	@ 				: 15/10/2020/ Vadhanak Voun (vadhanak.voun@gaea-sys.com) / US-0008206 - [LTTM Plus] Campaign Code to be mandated and Cohort Seller Comments ,DMC, SR# to be recorded in Activities
    *****************************************************************************************************************************/
	private static void createTask(BoB_Seller__c bs, List<Contact> listContacts,Map<String,String> addParam) {

		Task tsk = new Task();
		tsk.Type = TASK_TYPE_GCC;

		if(!listContacts.isEmpty()){
			tsk.WhoId = listContacts[0].Id;
		}

		tsk.WhatId = bs.Id;
		tsk.Status = 'Completed';
		tsk.Subject= bs.BoB__r.LTTM_Group__c + '_ ' + TASK_TYPE_GCC;
		tsk.Description = bs.Advisor_Comments__c; //LA:US-0009514: replace field Comments__c with Advisor_Comments__c
		tsk.Call_attempts__c = 1;
		tsk.RecordtypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('X3CallAttempts').getRecordTypeId();
		tsk.Task_Completed_Date__c =  System.now();
		tsk.Log_Task__c = true;


		tsk.SR_Number__c  = addParam.get('SRNumber');
		tsk.EBH_Account__c = bs.Seller__c;
		tsk.EBH_DMC__c = bs.Call_Outcome__c == 'DMC Committed';
		 

		//insert tsk;
		ApexSafe.dml().doInsert(new List<Task>{tsk}, true);
		
	}

	
    static Map<String,String> mapLinkField = new Map<String,String>{'Name'=>'Name','Account.Name'=>'AccountId','RecordType.Name'=>'RecordTypeId','Owner.Name'=>'OwnerId'};
    
    
    class ColName{
    	@AuraEnabled
    	public String label;
    	
    	@AuraEnabled
    	public String fieldName;
      
        @AuraEnabled
    	public String type;
    	
        @AuraEnabled
    	public Boolean sortable = true;
    	
    	@AuraEnabled
    	public Map<String,Object> typeAttributes;
    	
    	public ColName(String label,String fieldName,String type)
    	{
    		this.label = label;
    		this.fieldName = fieldName;
    		this.type = type.toLowerCase();
    		
    		if(fieldName=='RecordType.Name')
    		{
    			this.fieldName = mapLinkField.get(fieldName);
    		}else if(mapLinkField.containsKey(fieldName))
    		{
    			typeAttributes = new Map<String,Object>{
    				'label' => new Map<String,Object>{'fieldName'=>mapLinkField.get(fieldName)},
    				'target'=>'_blank',
    				'tooltip'=>''
    			};
    			this.fieldName = 'link_'+mapLinkField.get(fieldName);
    			this.type = 'url';
    		}
    	}
    }
   
   
}