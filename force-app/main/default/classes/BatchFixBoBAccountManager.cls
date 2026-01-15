/*********************************************************************************************************************************
@ Class:         BatchFixBoBAccountManager
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       US-0007069 Create a batch job to update Managed Account records based on most recent BoB
@				 SOQL1: Update Owner, Account Manager name, Managed flag (account object) for sellers in current BoB
@				 	select Seller__c, from BoB_Seller__c where Active__c = true and Status__c in ('New','Submitted')
@				 	
@				 SOQL2: For sellers where managed flag is checked true, but they are not part of an active BoB, these sellers must be removed.
@				 	select Id from Account where EBH_BOBManaged__c = true and Id NOT IN (select Seller__c from BoB_Seller__c where Active__c = true and Status__c in ('New','Submitted') )
@----------------------------------------------------------------------------------------------------------------------------------
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.01.2020 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the class.
@ Version:      	2.0
@ Purpose:      	US-0007676 This requirement is captured to sync below 6 fields from BoB_Seller (LTTM Seller) to the "Account"(Seller) record
@					This is required to differentiate Accounts as "LTTM" vs "Managed" and will be consumed by Analytics to display the scorecard in Customer 360 view for LTTM sellers and "Mid Group of focus Sellers" outside LTTM.
@					SOQL1: 1.Update Account(Seller) from BoB_Seller__c when LTTM Cohort(BoB__c) is of status "BoB Active" and record type = "Light_touch_Category_Cohort"
@						Query BoB_Seller__c
@						select
@							Seller__c
@						from BoB_Seller__c
@
@						where (Active__c = true and Status__c in ('New','Submitted') and 
@						Bob__r.RecordType.DeveloperName = 'Managed_Cohort')
@							OR
@						(Bob__r.Status__c = 'BoB Active' and Bob__r.RecordType.DeveloperName = 'Light_Touch_Category_Cohort')
@				 	
@					SOQL2: Update Seller record after removal of LTTM Sellers from Active BoB__c
@						For sellers where the managed flag is checked true, but they are not part of an active BoB, these sellers must be removed.
@						Updated the Query as below:
@						select Id from Account where EBH_BOBManaged__c = true and Id NOT IN
@
@ 						(select Seller__c from BoB_Seller__c where (Active__c = true and Status__c in ('New','Submitted') and Bob__r.RecordType.DeveloperName = 'Managed_Cohort') OR 
@
@						(Bob__r.Status__c = 'BoB Active' and Bob__r.RecordType.DeveloperName = 'Light_Touch_Category_Cohort'))
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history:	05.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / Update the class, add class property for sql string, disable old sql string, update methods
@ 					11.01.2022 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011008 - Clear the seller Managed fields for removed Cohort [P2] Bug - Seller and when entire Cohort is moved to status "Cohort Inactive"
@					06.06.2022 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011827 - Managed Country is displayed for Austria AT Cohort as UNKNOWN on Seller Record
@					9.07.2022 / Chetra Sarom / US-0012010 - Add New Button "Deactivate Sellers" Button next to "Remove Sellers"
@					15.11.2022 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012826 - Batch job updating Account.owner twice for Inactive Cohort Seller who is active in another Active instance
@					17.05.2023 / Chetra Sarom / US-0013584 - Batch "BatchFixBoBAccountManager" failed in Production
@					18.05.2023 / Bora Chhorn / US-0012616 - Automation to change Cohort Seller Status to Inactive when Cohort Status is changed to "Inactive"
@					09.11.2023 / Sophal Noch / US-0014361 - Cohort Activation Process Part 2
@					16.02.2024 / Sophal Noch / US-0014755 - ADS - Cohort Seller and Seller nightly synch
@					23.04.2024 / Sovantheany dim / US-0015106 : Retire Managed Cohort - Retire the record type Managed Cohort and update the Record Type of LTTM
@					13.05.2024 / Sophal Noch / US-0015242 - Fix Account Owner Updating to Integration User Issue
@					24.02.2024 / Sophal Noch / US-0016833 - Account History | Owner changes several times a day
@			 		28.04.2025 / Sophal Noch / US-0017154 - Replace OwnerId with Account_Manager__c for CohortSeller, Account, Campaign Related classes
*********************************************************************************************************************************/

global without sharing class BatchFixBoBAccountManager implements Database.Batchable<SObject>,Schedulable{
		
	Set<String> setStatus = new Set<String>{EBH_ConstantsUtility.BOB_SELLER_STATUS_NEW,EBH_ConstantsUtility.BOB_STATUS_SUBMITTED};
	
	private final static String BOBSELLER_INACTIVE_STATUS = 'Inactive'; //@ Change history: 19.07.2022 / Chetra Sarom / US-0012010
	private final static String BOBSELLER_ACTIVE_STATUS = 'Draft'; // 09.11.2023 / Sophal Noch / US-0014361 
	private final static String BOBSELLER_INVITED_STATUS = 'Invited'; // 24.02.2024 / Sophal Noch / US-0016833

	private final static Set<String> SET_BS_ACTIVE_STATUS = new Set<String>{BOBSELLER_ACTIVE_STATUS, BOBSELLER_INVITED_STATUS}; // 24.02.2024 / Sophal Noch / US-0016833

	/*
	// 16.02.2024 / Sophal Noch / US-0014755 :
	String sellerSOQL = 'select Id from Account where EBH_BOBManaged__c = true '
						 +'and Id NOT IN (select Seller__c from BoB_Seller__c %sWhere1% ) ';
	*/
	String sellerSOQL = AbstractBatchCohortAction.ACC_SOQL + 'where EBH_BOBManaged__c = true '
	+'and Id NOT IN (select Seller__c from BoB_Seller__c %sWhere1% ) '; // 16.02.2024 / Sophal Noch / US-0014755 : reuse soql from class AbstractBatchCohortAction
						 
	//String sWhere = ' where Active__c = true and Status__c in :setStatus ';
	//' where ((Active__c = true and Status__c in :setStatus AND Bob__r.RecordType.DeveloperName =: BOB_MANAGED_COHORT_RECORDTYPE) OR ' //TH:US-0015106 : comment out
	// 28.04.2025 / Sophal Noch / US-0017154 : add Seller__r.Account_Manager__c != null to condition 
	String sWhere = ' where ( '
					+'(Bob__r.Status__c =: BOB_ACTIVE_STATUS AND Status__c IN: SET_BS_ACTIVE_STATUS AND Bob__r.RecordType.DeveloperName IN :SET_BOB_LTTM_ADS_RTYPES) OR ' // 16.02.2024 / Sophal Noch / US-0014755 : add advertising cohort to soql, // 24.02.2024 / Sophal Noch / US-0016833 : add "Draft" and "Invited" status check
					+'((Bob__r.Status__c =: BOB_INACTIVE_STATUS OR Status__c =: BOBSELLER_INACTIVE_STATUS) AND Seller__r.EBH_BOBManaged__c = false AND Bob__r.RecordType.DeveloperName IN: SET_BOB_RTYPES AND ' // 11.01.2022 / Sophal Noch / US-0011008 query inactive bob with EBH_BOBManaged__c = false but other fields are not empty.,  // 24.02.2024 / Sophal Noch / US-0016833 : add "Inactive" status check
					+'(Seller__r.OwnerId NOT IN : SET_DEACTIVATION_USER_ID OR Seller__r.Account_Manager__c != null OR Seller__r.Managed_Type__c != null OR Seller__r.EBH_BOBSegment__c != null OR Seller__r.BoB_Subsegment__c != null OR Seller__r.EBH_AccountManageName__c != null OR Seller__r.EBH_BOBVertical__c != null OR Seller__r.EBH_BOBCNTRY__c != null))) '; // 13.05.2024 / Sophal Noch / US-0015242 : add deaction user id into condition

	// use bobSellerSOQL instead of EBH_ConstantsUtility.SOQL_BOBSELLER because EBH_ConstantsUtility.SOQL_BOBSELLER missing field Bob__r.RecordType.DeveloperName

	/*
	// 16.02.2024 / Sophal Noch / US-0014755 :
	String bobSellerSOQL = 'Select Managed_Type__c, EBH_BOBSegment__c,BoB_Subsegment__c,Status__c,Previous_Status__c,Id,Account_Manager__c,'
	 + 'Account_Manager__r.Name,BoB__c,BoB__r.Name,BoB__r.EBH_BOBVertical__c,BoB__r.OwnerId,BoB__r.Owner.Name,BoB__r.EBH_BOBCNTRY__c,BoB__r.Status__c,'
	 + 'Bob__r.RecordType.DeveloperName, Seller__c,Seller__r.Name,Seller__r.EBH_OracleID__c from BoB_Seller__c ';
	*/
	String bobSellerSOQL = AbstractBatchCohortAction.BS_TO_SYNC_SOQL; // 16.02.2024 / Sophal Noch / US-0014755 : reuse soql from class AbstractBatchCohortAction
	
	String soqlFinal = '';
	String processObject = 'bs'; //bs (bob seller) or acc	
	Set<String> processIds; //portion of ids as param to be processed for quick batch

	//public final static String BOB_MANAGED_COHORT_RECORDTYPE = 'Managed_Cohort';//TH:US-0015106 : comment out

	public final static String BOB_LIGHT_TOUCH_CATEGORY_COHORT_RECORDTYPE = 'Light_Touch_Category_Cohort';

	private final String BOB_ADVERTISING_COHORT_RECORDTYPE = 'Advertising_Cohort'; // 16.02.2024 / Sophal Noch / US-0014755

	public final static String BOB_ACTIVE_STATUS = 'BoB Active';

	private final static String BOB_INACTIVE_STATUS = 'BoB Inactive';

	//private static final Set<String> SET_BOB_RTYPES = new Set<String>{BOB_LIGHT_TOUCH_CATEGORY_COHORT_RECORDTYPE,BOB_MANAGED_COHORT_RECORDTYPE};//TH:US-0015106 : comment out
	private static final Set<String> SET_BOB_RTYPES = new Set<String>{BOB_LIGHT_TOUCH_CATEGORY_COHORT_RECORDTYPE};
	
	private final Set<String> SET_BOB_LTTM_ADS_RTYPES = new Set<String>{BOB_LIGHT_TOUCH_CATEGORY_COHORT_RECORDTYPE, BOB_ADVERTISING_COHORT_RECORDTYPE}; // 16.02.2024 / Sophal Noch / US-0014755

	private final Set<String> SET_BOB_LTTM_RTYPE = new Set<String>{BOB_LIGHT_TOUCH_CATEGORY_COHORT_RECORDTYPE}; // 16.02.2024 / Sophal Noch / US-0014755

	// private final String INTEGRATION_USER_ID = ApexUtil.INTEGRATION_USER_ID;
	// private final String DEACTIVATION_USER_ID = String.valueOf(Label.Cohort_Deactivation_UserId); // 13.05.2024 / Sophal Noch / US-0015242
	private final Set<Id> SET_DEACTIVATION_USER_ID = AbstractBatchCohortAction.SET_DEACTIVATION_USER_ID;  // 13.05.2024 / Sophal Noch / US-0015242, 24.02.2024 / Sophal Noch / US-0016833 : change to use constant from AbstractBatchCohortAction

	// 16.02.2024 / Sophal Noch / US-0014755 :
	private final String CLASS_NAME = 'BatchFixBoBAccountManager';
	private final String MEHTOD_NAME_EXECUTE = 'execute';


	Map<Id,User> mapValidUser = new Map<Id,User>(); //17.05.2023 / Chetra Sarom / US-0013584

	// public final static Map<String,String> MAP_CODE_TO_COUNTRY  = new Map<String,String>{
	// 	'3'=> 'UK','77'=> 'DE','71'=> 'FR','101'=> 'IT','186'=> 'ES','163'=> 'PL','99'=> 'IE','193'=> 'CH','146'=> 'NL','23'=> 'Small Site','168'=> 'EEC-Unsited','15'=> 'AU','0'=>'US','2'=>'CA'
	// };//Update from '23'=>'BE' to '23'=>'Small Site'

	// 06.06.2022 / Sophal Noch / US-0011827 : MAP_CODE_TO_COUNTRY used here and reused in class BoBTriggerHandler. the purpose is getting value and label directly from picklist BoB__c.EBH_BOBCNTRY__c
	public static Map<String,String> MAP_CODE_TO_COUNTRY {
		get{
			if(MAP_CODE_TO_COUNTRY == null){
				MAP_CODE_TO_COUNTRY = new Map<String,String>();
				Schema.DescribeFieldResult fieldResult = BoB__c.EBH_BOBCNTRY__c.getDescribe();
				List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
				for( Schema.PicklistEntry pickListVal : ple){
					MAP_CODE_TO_COUNTRY.put(pickListVal.getValue(),pickListVal.getLabel());
				}
			}
			return MAP_CODE_TO_COUNTRY;
		}
		set{}
	}

	
	//from test
	public BatchFixBoBAccountManager()
	{		
	} 
	
	public BatchFixBoBAccountManager(String processObject)
	{
		buildSoql(processObject,null);
	}
	public BatchFixBoBAccountManager(String processObject,Set<String> processIds)
	{
		buildSoql(processObject,processIds);
	}

	/*****************************************************************************************************************************
	@ Method:   buildSoql
	@ Version:  2.0
	@ Purpose:  update soqlFinal variable depending on processObject whether it is bob seller or account.
	@			bobSellerSOQL for bob seller query and sellerSOQL for seller query.
	@			if value processIds is not empty, ad it to sql string.
	@			return soqlFinal as final sql string value.
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      processObject, processIds
	------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / update the method.
	@ Change history: 15.11.2022 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012826 - Batch job updating Account.owner twice for Inactive Cohort Seller who is active in another Active instance
	@				: 16.02.2024 / Sophal Noch / US-0014755 - ADS - Cohort Seller and Seller nightly synch
    *****************************************************************************************************************************/
	private void buildSoql(String processObject,Set<String> processIds) 
	{
		this.processObject = processObject;
		this.processIds = processIds;
		if(processObject=='bs')
		{
			// soqlFinal = EBH_ConstantsUtility.SOQL_BOBSELLER + sWhere +(processIds==null?'':' AND BoB__c IN :processIds');
			soqlFinal = bobSellerSOQL + sWhere +(processIds==null?'':' AND BoB__c IN :processIds');
			// EBH_ConstantsUtility.SOQL_BOBSELLER // missing field Bob__r.RecordType.DeveloperName, that why use sql string above instead of this
		}else if(processObject=='acc')
		{
			soqlFinal = sellerSOQL.replace('%sWhere1%',sWhere)+(processIds==null?'':' AND Id IN :processIds');
			soqlFinal = soqlFinal.replace(':SET_BOB_LTTM_ADS_RTYPES', ':SET_BOB_LTTM_RTYPE'); // 16.02.2024 / Sophal Noch / US-0014755 : unsync account here do not need to check Advertising Cohort
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(soqlFinal);
    }

    global void execute(Database.BatchableContext pBc, List<SObject> scope){

		// 16.02.2024 / Sophal Noch / US-0014755 : call method to sync cohort seller to account
		if(processObject=='bs'){
			BatchCohortActionExecution.synCohortSellerToAccount(CLASS_NAME, MEHTOD_NAME_EXECUTE, scope);
		}else if(processObject=='acc'){
			BatchCohortActionExecution.unsyncAccount(CLASS_NAME, MEHTOD_NAME_EXECUTE, scope);
		}
	}
    
    global void execute(SchedulableContext sc) { 
    	//when scedueler start, BS start first
        BatchFixBoBAccountManager b = new BatchFixBoBAccountManager('bs');
        Database.executeBatch(b);
    }   
    
    global void finish(Database.BatchableContext pBc){
		if(processObject=='bs' && !Test.isRunningTest()) //next step for acc (Seller that has flag checked but not particiate in any Active BoB)
		{
			BatchFixBoBAccountManager b = new BatchFixBoBAccountManager('acc');
			Database.executeBatch(b);
		} else {
			//BR-18-05-2023-US-0012616
			BatchDeactivateBobSeller batchDeactiveBs = new BatchDeactivateBobSeller();
			Database.executeBatch(batchDeactiveBs);
		}	
    }
}