/*********************************************************************************************************************************
 @ Class:          TicketTriggerHandler
 @ Version:        1.0
 @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
 @ Purpose:        Handler Class for Ticket Trigger
 EPH-3309: User Creation
 ----------------------------------------------------------------------------------------------------------------------------------
 @ Change history:  14.09.2017 / Vadhanak Voun /Created the class.
 @                  11.10.2017 / Samnang MUONG /Created the class and move logic from trigger
 @                  20/07/2020/ vadhanak voun/ added PSL_WAVE_COMM, PSL_EA_MEMB
 ----------------------------------------------------------------------------------------------------------------------------------
 @ Class:          CaseTriggerHandler
 @ Version:        1.0
 @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
 @ Purpose:        US-0007615 Handler Class for Ticket Trigger
 @                 All metadata from Ticket__c has been replicated in Cases to allow code to quickly be reconfigured for migration to cases.
 @                 Existing trigger handler to be copied and pasted, find & replace "Ticket__c" with "Case" object.
 @                 Updates required for Ticket component, controller & class.
 @                 Will update User Creation & Validate Survey automation.
 @                 1) double check that all required fields are existing in Case object
 @                 2) Create new CaseTriggerHandler. Copy Paste the code from TicketTriggerHandler. Replace Ticket__c with Case
 @                 3) Create new Case trigger. Add Cases to "Active Triggers" Custom Settings. Copy & Paste all code from Ticket into trigger.
 @                 4) Create new CaseTriggerHandlerTest class , copy & paste & adapt code from TicketTriggerTest
 @REMEMBER: Any mention to EBH_ConstantUtility should be replaced with a new definition of public final string at the top of the classes.
 ----------------------------------------------------------------------------------------------------------------------------------
 @ Change history: 19.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the class.
 @ 				   24.05.2021 / Mony Nou / US-0009540 - Check Licenses Availability when creating users 
 @				   14.06.2021 / Mony Nou / US-0009688 - [Cases] - Ensure User trigger processes either Reactivation or Creation after record type swap
 @				   27.07.2022 / SRONG TIN / US-0011596 - US-0011596 - SPIKE Enhancements to survey validation trigger
 @				   22.03.2023 / Sophal Noch / US-0012859 - Remove reference to Class in a CaseTriggerHandler
 @				   11.08.2023 / vadhanak voun / US-0013997 - Tech Debt: fix hardcoded Id (part 2)
 @ Change history: 22/01/2024 / Vimean Heng / US-0014626 / disable record type "special permission request" , devloper name = Admin_Request
 *********************************************************************************************************************************/
public without sharing class CaseTriggerHandler{
	static Set<String> SET_ADMIN_PROFILES = new Set<String>();
	static Map<String, String> MAP_GROUP_IDS = new Map<String, String>();
	static Map<String, String> MAP_PROFILES = new Map<String, String>();
	public final static string TRIGGERCONTROLLER = 'EBH Trigger Controller';
	public final static String TICKET_COUNTRY_AU = 'AU';
	public final static String TICKET_USER_TYPE_LICENSE = 'Full License User';
	public final static String TICKET_USER_TYPE_PORTAL = 'GCX Portal User';
	public final static String TICKET_AU_PROFILE = 'AU Standard User Profile';
	public final static String TICKET_STANDARD_PROFILE = 'Standard User Profile';
	public final static String TICKET_GCX_PROFILE = 'GCX Partner Profile';
	public static final String SOQL_ADMIN_PROFILES = 'SELECT ID FROM Profile WHERE NAME IN(\'System Administrator\',\'Business Admin\',\'System Administrator - Limited Privileges\')';
	public static final String SOQL_PROFILE = 'select Id,Name from Profile';
	public final static String STATUS_INPROGRESS = 'In Progress';
	public final static String STATUS_WAITINGFORLICENSES = 'Waiting for licenses'; //MN-24052021-US-0009540
	public final static String PROFILE_GCX_PARTNER = 'GCX Partner Profile';
	public static final String CLASS_TICKETHANDLER = 'TicketHandler';
	public static final String CLASS_TICKETHANDLER_METH_CHECKCREATEUSERS = 'checkCreateUsers';
	public static final String STATUS_CLOSED = 'Closed';
	public final static String TICKET_STATUS_VALIDATED = 'Validated';
	public final static String TICKET_PERMISSIONSET_MARKETING_EXC_TEAM = 'Marketing Execution Team';
	// public final static String PROFILE_GCX_PARTNER_ID = '00e6A000001o6m4QAA'; //NK:11/08/2023:US-0013997
	public final static String CONTACT_STATUS_ACTIVE = 'Active';
	//public final static String SOQL_GCX_ACCOUNT = 'Select Id From Account Where Name=\'GCX\' AND RecordTypeId=\'0126A000000M9xKQAS\' LIMIT 1';
	public final static String SOQL_GCX_ACCOUNT = 'Select Id From Account Where Name=\'GCX\' AND RecordTypeId=\''+ ApexUtil.GCX_RT_ID +'\' LIMIT 1';//NK:11/08/2023:US-0013997

	public static final String SOQL_PERMISSIONSET = 'SELECT ID,Name FROM PermissionSet';
	public static final String SOQL_PERMISSIONSET_WAVE_A_USER = 'SELECT ID FROM PermissionSet WHERE NAME =\'CustomEinsteinAnalyticsPlusUser\'';
	public static final String SOQL_User = 'Select Id,FirstName, lastName,Name,UserType, username,Email,isActive, Permission_Sets__c,LocaleSidKey From User Where Id in: setUser';
	public static final String ERROR_LOCALE_GROUP_MAPPING = 'No Locale to Public Group Mapping defined in CustomSetting(Locale_PublicGroup_Mapping) :';
	public final static String GROUP_MARKETING_EXC = 'Marketing_Execution_Team';
	// public final static String PERMISSION_SET_LICENSE_COMMUNITYWAVE_ID = ApexUtil.PERMISSION_SET_LICENSE_COMMUNITYWAVE_ID;//NK:11/08/2023:US-0013997
	//public final static String PERMISSION_SET_COMMUNITY_ANALYTICS_ID = ApexUtil.PERMISSION_SET_COMMUNITY_ANALYTICS_ID;//NK:11/08/2023:US-0013997
	public static final String SOQL_GRP = 'SELECT ID,Name,DeveloperName FROM Group';
	public static final String ERROR_NO_COUNTRY_MAPPING = 'No Country Mapping defined in CustomSetting(CountryMapping3__c) :';
	public static final String AT_GCX_SUFFIX = '@hive.gcx.com';
	public static final String ENCODE_UTF8 = 'UTF-8';
	public static final String HIVE_SUFFIX = 'Hive';
	public static final String AT_HIVE_SUFFIX = '@hive.project.com';
	// below constant is for test class CaseTriggerHandlerTest
	public final static String SOQL_RECTYPE_USERFORM = 'SELECT Id,Name,DeveloperName FROM RecordType WHERE DeveloperName=\'User_Request_Form\' AND SobjectType=\'Case\'';
	// public final static String ADMIN_PROFILE_ID = ApexUtil.ADMIN_PROFILE_ID;//NK:11/08/2023:US-0013997
	public final static String SOQL_GROUP_MEMBER = 'Select UserOrGroupId, Group.DeveloperName, GroupId From GroupMember Where Group.DeveloperName IN:setGoups';
	public final static String CAMP_RECORDTYPE_OUTREACH_ID = ApexUtil.CAMP_RECORDTYPE_OUTREACH_ID;
	public final static String PSL_WAVE_COMM = 'WaveCommunitiesPsl'; //Analytics Cloud - Wave Community Users
	public final static String PSL_EA_MEMB = 'EinsteinAnalyticsForCommunityMembersPsl';//Einstein Analytics For Community Members
	public static final String ROLE_GLOBAL = 'Global';
	public static final String SOQL_USERS_PROFILE = 'Select id, profileId, Profile.UserLicense.TotalLicenses, Profile.UserLicense.UsedLicenses from user where id in :sameSettingAsUsers'; //query samesettings as users profile
	public static final String USER_CREATION_SETTINGS_NAME = 'CaseTrigger'; //custom metadata type name
	public static Map<String, String> SameSettingUserProfile = new Map<String, String>();
	public static Map<String, User> sameSettingUser = new Map<String, User>();
	public static final String MyTrailHeadAssignation = 'MyTrailHead_License_Assignation__c';
	public static final String EA_License_Assignation = 'EA_License_Assignation__c';
    public static final String MYTRAILHEAD_USERPS='myTrailhead_User';
	//SRONG TIN / 27.07.2022 / US-0011596
	public static final String SURVEY_QUERY = 'SELECT ID,ArdiraSurvey__CS_Do_Not_Require_Authentication__c  ,ArdiraSurvey__Enable_Scoring_Survey_Responses__c,ArdiraSurvey__CO_Scoring_Method__c,ArdiraSurvey__Status__c,ArdiraSurvey__Allowable_Target_Objects__c,ArdiraSurvey__Response_Mapping_Rules__c,ArdiraSurvey__Community_Id__c FROM ArdiraSurvey__Survey__c where id IN :surveyIds';
	public final static String COMMUNITY_SITE_ID = ApexUtil.COMMUNITY_SITE_ID;//GCX site	//NK:11/08/2023:US-0013997

	public static final String SURVEY_QUESTION_QUERY = 'select id,ArdiraSurvey__Question_Short_Text__c,ArdiraSurvey__Survey__c from ArdiraSurvey__Question__c where ArdiraSurvey__Survey__c IN :surveyIds';
	public static final String SURVEY_LATEST_VERSION_QUERY='SELECT ArdiraSurvey__Root_Version__c,id from ardirasurvey__survey__c where ardirasurvey__root_version__c in :surveyIds and ArdiraSurvey__Is_Latest_Version__c = true';
	//SRONG TIN / 27.07.2022 / US-0011596
	public static final String SURVEY_ANSWER_CHOICE='Select id,ArdiraSurvey__Score__c from ArdiraSurvey__Answer_Choice__c where ArdiraSurvey__Question__c=:callOutcomeQuestionId';
	public static final set<String> SURVEY_TARGET_OBJECT = new set<string> {'Task','CampaignMember'};

	public static final String SURVEY_SCORING = 'Raw';
	public static final String SURVEY_STATUS='Open';
	public static final String CALL_OUTCOME = 'Call Outcome';
	public static final String MAPPING_TIME = 'Survey_Completed';
	public static final String MAPPING_ACTION = 'Update_Fields_Of';
	public static final String MAPPED_OBJECT = 'Task';
	public static final Boolean MAPPING_ACTIVE_STATUS = true;
	public static final String MAPPING_FIELDRULES_TARGET_FIELD = 'EBH_ResponseCode__c';
	public static final String MAPPING_FIELDRULES_QUESTION_VALUE_TO_MAP = 'Map_Question_Score';
	public static final String MAPPING_STATUS = 'true';
	//SRONG TIN / 27.07.2022 / US-0011596
	public static final set<Integer> CALL_OUTCOME_SCORE_VALUES = new set<Integer>{70,90,100};
	public static final String Scoring_must_be_enabled =' scoring must be enabled';
	public static final String WRONG_AUTHENTICATION=System.Label.Ardira_Surveys_ERROR_WRONG_AUTENTICATION;
	public static final String SURVEY_VALIDATED='Validated';
	public static final String SURVEY_VALIDATION_FAILED='Validation Failed';
	
	public static Map<String, List<String>> mapCasesSurveyErrors = new Map<String, List<String>>();

	//NK:25/05/2021: US-0009366
    private static Map<String,String> MAP_PKL_PS_NAME = new Map<String,String>{
			 //'Marketing Execution Team'=>'Marketing_Execution_Team',
			 'Export Reports'=>'EBH_exportReportsPermissionSet'
			 //'Campaign Approval'=>'', // not use
			 //'Ticket Manager'=>'' // not use
		};

	public CaseTriggerHandler(){
	}

	/*****************************************************************************************************************************
	 @ Method:         checkCreateUsers
	 @ Version:        1.0
	 @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	 @ Purpose:        EPH-3309: Automatic User creation on custom object "Ticket".
	 @                  If the business / sys admin changes the status to "In progress",
	 @                  a user should be automatically created in Salesforce.
	 @ Event:         before update
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Parameter:      list oldTrigger:
	 @                  list newTrigger:
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        void
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  14.09.2017 / Vadhanak Voun /Created the Method.
	 @                   07/03/2019 / Vadhanak Voun /NK:EPH-7025: create contact for gcx partner profile
	 @                   23/09/2019/ Vadhanak Voun/US-0015717 Survey ID - Read Only Field
	 @            AC3:
	 @            Given that I am Admin
	 @            When I change status of Validate survey ticket to "Validated" ,the trigger updates the survey Id in Campaign.
	 @            Then Validated survey.Survey ID is copied to the related Campaign. Survey ID.
	 @            and the trigger updates the Ticket status is "Closed"
	 ----------------------------------------------------------------------------------------------------------------------------------
	 @ Change history: 19.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0007615 Created the Method.
	 @ Change history:  01.12.2020 / Vadhanak Voun / US-0008096 - US_Update New User Creation Process to include Role (Mixed DML!)
	 @                                             / moved insert user to Asyn
	 @ Change history: 22.04.2021 / David Herrero / Consider Ardira_Survey__c can be populated instead of survey_id__c
	 @ Change history: 24.05.2021 / Mony Nou / US-0009540 - Check Licenses Availability when creating users
	 @ Change history: 14.06.2021 / Mony Nou / US-0009688 - [Cases] - Ensure User trigger processes either Reactivation or Creation after record type swap
	 @ change history: 08.11.2021 / SRONG TIN / US-0009796 - [Cases] - Fix for User Request / Reactivation issue
	 @*****************************************************************************************************************************/
	public static void checkCreateUsers(List<Case> oldTickets, List<Case> newTickets){
         
		List<PermissionSetAssignment> psa = [select id
		                                     from PermissionSetAssignment
		                                     where assigneeId = :Userinfo.getUserId() AND permissionset.name = 'Create_Users'];
		for (Profile p : Database.query(SOQL_ADMIN_PROFILES)){
			SET_ADMIN_PROFILES.add(p.Id);
		}

		if (!SET_ADMIN_PROFILES.contains(UserInfo.getProfileId()) && psa.isEmpty()){
			return;
		}
		/* MN-24052021 - MAP_PROFILES is no longer use
		//profile mapping
		for (Profile p : Database.query(SOQL_PROFILE)){
			MAP_PROFILES.put(p.Name, p.Id);
		}
		*/
         
		//NK:30/05/2018: EPH-5957 Auto-User creation should only work for ticket type "User_Request_Form"
		//Map<Id,RecordType> mapRecordType = new Map<Id,RecordType>((List<RecordType>)Database.query(EBH_ConstantsUtility.SOQL_RECTYPE_USERFORM));
		RecordType recTypeUserForm = ApexUtil.getRecordTypeByName('Case', 'User_Request_Form');

		// ticket__c use Validate_survey
		// RecordType recTypeValidateSurvey = ApexUtil.getRecordTypeByName('Case','Validate_survey');

		// case use Validate_Survey
		RecordType recTypeValidateSurvey = ApexUtil.getRecordTypeByName('Case', 'Validate_Survey');

		RecordType recTypeUserReactivate = ApexUtil.getRecordTypeByName('Case', 'User_Reactivation');

		integer i = 0;
		List<User> userToCreate = new List<User>();
		List<User> userToGroupSalesPlaner = new List<User>();
		Map<String, Contact> mapContacts = new Map<String, Contact>();
		Map<String, Campaign> mapCampaignSurveyId = new Map<String, Campaign>();

		Map<String, String> permissionSetUserMap = new Map<String, String>();
		Map<String, String> mapRoleReactivate = new Map<String, String>();
		Set<String> setReactivateUsers = new Set<String>();
		set<string> sameSettingAsUsers = new set<string>();
		Set<Id> setTicketId = new Set<Id>();
		//SRONG TIN / 08.11.2021 / US-0009796
		Map<String, Case> caseMap = new Map<String, Case>();


		for (Case ticket : newTickets){
			if (ticket.recordTypeId == recTypeUserForm.Id && String.isNotBlank(ticket.Same_settings_as__c)){ //MN-14062021-US-0009688 - Add record type in condition to avoid some mulfunction when Reactvation Ticket also has field Same_settings_as__c populated
				sameSettingAsUsers.add(ticket.Same_settings_as__c);
			}
			else if (ticket.recordTypeId == recTypeUserReactivate.Id && String.isNotBlank(ticket.Inactive_User__c)) { //MN-26052021-US-0009540 - Will check available license for User Reactivation as well
				sameSettingAsUsers.add(ticket.Inactive_User__c);
			}
		}
		for (User u : Database.query(SOQL_USERS_PROFILE)){
			// SameSettingUserProfile.put(u.id, u.profileid); //MN-24052021 - US-0009540
			sameSettingUser.put(u.id, u); //MN-24052021-US-0009540
		}
		for (Case ticketOld : oldTickets){

			//if(mapRecordType.containsKey(newTickets[i].recordTypeId) && ticketOld.Status__c != newTickets[i].Status__c && newTickets[i].Status__c ==EBH_ConstantsUtility.STATUS_INPROGRESS) {
			if ((recTypeUserForm.Id == newTickets[i].recordTypeId || recTypeUserReactivate.Id == newTickets[i].recordTypeId)  //request or reactivate
			 && ticketOld.Status != newTickets[i].Status && newTickets[i].Status == STATUS_INPROGRESS){
				//system.debug('>>>>:'+JSON.serialize(newTickets[i]));
				if (!newTickets[i].Approved__c){
					newTickets[i].addError(System.Label.Ticket_Error_NotApproved);
					continue;

				} else if (recTypeUserForm.Id == newTickets[i].recordTypeId){
					
					//MN-24052021-US-0009540 - To indicate whether this new user able to create or not due to amount of remain license
					Boolean hasLicense = validateLicense(newTickets[i].Same_settings_as__c); 

					try{

						if (hasLicense) {  //MN-24052021-US-0009540 - Only create new user when there are available licenses
							
						User u = createUser(newTickets[i]);
						// system.debug('>>>>U:'+JSON.serialize(u));
							
						userToCreate.add(u);

						//NK:EPH-7025: 07/03/2019
						if (newTickets[i].Picklist__c == PROFILE_GCX_PARTNER)
							//Profile
							{
								if (getGCXAccount() == null){
									newTickets[i].addError('No GCX Partner for Partner User!');
								return;
							}
							mapContacts.put(u.UserName, createContactFromTicket(newTickets[i]));

						}
						} 
						
					} catch (Exception e){
						//system.debug(e);
						EBH_ApexLogger.logError(new List<Exception>{e}, CLASS_TICKETHANDLER, CLASS_TICKETHANDLER_METH_CHECKCREATEUSERS);
					}
					//newTickets[i].Status__c = EBH_ConstantsUtility.STATUS_DONE; //must before update-trigger

					// newTickets[i].Status = STATUS_CLOSED; //must before update-trigger //MN-24052021-US-0009540
					newTickets[i].Status = (hasLicense)?STATUS_CLOSED:STATUS_WAITINGFORLICENSES; //MN-24052021-US-0009540 - If there aren't license remain => update Case's status to Waiting for Licenses

				} else if (recTypeUserReactivate.Id == newTickets[i].recordTypeId && newTickets[i].Inactive_User__c<>null)//reactivate by future
					{
					//MN-26052021-US-0009540 - To indicate whether this inactive user able to reactivate or not due to amount of remain license
					Boolean hasLicense = validateLicense(newTickets[i].Inactive_User__c);
					
					if (hasLicense) { //MN-26052021-US-0009540 - Only reactivate user when there are available licenses 
						setReactivateUsers.add(newTickets[i].Inactive_User__c);
						//SRONG TIN / 08.11.2021 / US-0009796
						caseMap.put(newTickets[i].Inactive_User__c, newTickets[i]);

						mapRoleReactivate.put(newTickets[i].Inactive_User__c, getRoleId(newTickets[i]));
						//setTicketId.add(newTickets[i].Id);LA:10/09/2021
						//newTickets[i].Status = STATUS_CLOSED;//Loumang:2021-05-25:US-0008982-update Ticket status to closed
					}

                    // newTickets[i].Status = STATUS_CLOSED;//Loumang:2021-05-25:US-0008982-update Ticket status to closed 

					newTickets[i].Status = (hasLicense)?STATUS_CLOSED:STATUS_WAITINGFORLICENSES;//MN-26052021-US-0009540 - update status to Waiting for License when there is no license available
				}

			} else if (recTypeValidateSurvey.Id == newTickets[i].recordTypeId && ticketOld.Status != newTickets[i].Status && newTickets[i].Status == TICKET_STATUS_VALIDATED && newTickets[i].Related_Campaign__c<>null && (newTickets[i].Survey_ID__c<>null || newTickets[i].Ardira_Survey__c<>null)){
				//Then Validated survey.Survey ID is copied to the related Campaign. Survey ID.
				//if Ardira_survey__c <> null
				if (newTickets[i].Ardira_Survey__c<>null){
					mapCampaignSurveyId.put(newTickets[i].Related_Campaign__c, new Campaign(Id = newTickets[i].Related_Campaign__c, Ardira_Survey__c = newTickets[i].Ardira_Survey__c));
				} else{
					mapCampaignSurveyId.put(newTickets[i].Related_Campaign__c, new Campaign(Id = newTickets[i].Related_Campaign__c, Survey_ID__c = newTickets[i].Survey_ID__c));
				}

				newTickets[i].Status = STATUS_CLOSED;
			}

			i++;
		}

		if (!setReactivateUsers.isEmpty()){
			//SRONG TIN / 08.11.2021 / US-0009796
			 for(User oneUser : [Select Id,Email From User Where Id in:setReactivateUsers]){
				caseMap.get(oneUser.Id).Email_address__c = oneUser.Email;
			 }
			reactivateUsers(setReactivateUsers, mapRoleReactivate);
		}

		// if (!mapCampaignSurveyId.isEmpty()){
		// 	update mapCampaignSurveyId.values();
		// }
		UpdateCampaignsAfterTicketValidation(newTickets,new Map<Id,Case> ( oldTickets));	
		if (!userToCreate.isEmpty()){

			if (!mapContacts.isEmpty()){
				//1, Insert Contact first to get Id for GCX Partner Users
				Database.insert(mapContacts.values());
				//portal user need ContactId
				//insert contact first, then assign the id of newly contact to portal User (GCX Community partner profile)
				for (User u : userToCreate){
					if (mapContacts.containsKey(u.UserName)){
						u.ContactId = mapContacts.get(u.UserName).Id;
						u.UserRoleId = null; // Community do not need RoleId or INVALID Role Assignment! //NK:17/03/2019
					}
				}
			}
			//2, insert User here
			//Database.insert(userToCreate);
			//NK:01/12/2020:US-0008096. moved to asyn to avoid mixed DML
			createUserAsyn(JSON.serialize(userToCreate));

		}
		//NK:29/10/2020: allow 'after' event to continue after RunOnce()
		EBH_CheckRecursive.Run = true;
	}

	/*****************************************************************************************************************************
    @ Method:         addPermissionAccess
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        US-0009366 - [Export Reports] - Manage PII access within Hive in a SOX compliant manner
    ------------------------------------------------------------------------------------------------------------------------------
    @ Event:        BEfore update
    @ Parameter:      List<Case> of case to be assign permission set 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  24.05.2021 / Vadhanak Voun / US-0009366 - [Export Reports] - Manage PII access within Hive in a SOX compliant manner
	@ Change history: 22/01/2024 / Vimean Heng / US-0014626 / disable record type "special permission request" , devloper name = Admin_Request
    *****************************************************************************************************************************/
	/*
    public static void addPermissionAccess(List<Case> listNew, Map<Id,Case> mapOld) 
	{	
        RecordType recTypeAdmin_Request = ApexUtil.getRecordTypeByName('Case','Admin_Request');
        List<Case> listCaseUserAccess = new List<Case>();
        for(Case cs: listNew)
        {
            Case ticketOld = mapOld.get(cs.Id);
            if(cs.RecordTypeId == recTypeAdmin_Request.Id && ticketOld.Status != cs.Status && cs.Status ==STATUS_INPROGRESS && cs.Who_should_have_admin_access__c <> null && cs.Admin_Request_Type__c <> null && cs.Terms_Signed_Date__c <>null) 
			{
				listCaseUserAccess.add(cs);	
				cs.Status = STATUS_CLOSED; 			
			}
        }
          	
        if(listCaseUserAccess.isEmpty()) return;
            
        Set<String> setPS = new Set<String>();
        Set<String> setUser = new Set<String>();
        Set<String> setPS_toAdd = new Set<String>();
        for(Case cs : listCaseUserAccess)
        {
            for(String ps: (cs.Admin_Request_Type__c+'').split(';'))
            {
                String ps_API_Name = MAP_PKL_PS_NAME.get(ps);
                if(ps_API_Name <> null )
                {
                    setPS.add(ps_API_Name);
                    setPS_toAdd.add(cs.Who_should_have_admin_access__c+'_!!_'+ps_API_Name);
                }
            }			
            setUser.add(cs.Who_should_have_admin_access__c);
        }
        Set<String> setCheckExistDB = new Set<String>();
        for(PermissionSetAssignment psa: [Select PermissionSet.Name, PermissionSetId, AssigneeId from PermissionSetAssignment Where PermissionSet.Name IN :setPS AND AssigneeId IN :setUser])
        {
            setCheckExistDB.add(psa.AssigneeId+'_!!_'+psa.PermissionSet.Name);
        }
        Map<String,String> mapPS = new Map<String,String>();
        for(PermissionSet ps: [Select Id,Name From PermissionSet Where Name IN :setPS ])
        {
            mapPS.put(ps.Name,ps.Id);
        }
         
        Map<String,String> mapPSA_toAdd = new Map<String,String>();
        for(String us_ps : setPS_toAdd)
        {
            if(!setCheckExistDB.contains(us_ps)) //PS not assign yet
            {
                String userid = us_ps.split('_!!_')[0];
                String psAPI  = us_ps.split('_!!_')[1];
                 
                if(mapPS.get(psAPI) <> null)
                {
                    mapPSA_toAdd.put(userid,mapPS.get(psAPI));
                }				
            }
        }
        
        if(!mapPSA_toAdd.isEmpty())
        {
            addPermissionAccessAsyn(mapPSA_toAdd);
        }
	}

	@future
	private static void addPermissionAccessAsyn(Map<String,String> mapPSA_toAdd) 
	{
		List<PermissionSetAssignment> listPSA_toAdd = new List<PermissionSetAssignment>();
		for(String uid: mapPSA_toAdd.keySet())
		{
			listPSA_toAdd.add(new PermissionSetAssignment(PermissionSetId=mapPSA_toAdd.get(uid),AssigneeId=uid) );
		}
		insert listPSA_toAdd;		
	}
	*/
    /*****************************************************************************************************************************
    @ Method:         removePermissionsAccess
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        US-0009366 - [Export Reports] - Manage PII access within Hive in a SOX compliant manner
    ------------------------------------------------------------------------------------------------------------------------------
    @ Event:          Time base from Ticket Process (Case): 7 days after term signed/closed
    @ Parameter:      List<Case> of case to be assign permission set 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  25.05.2021 / Vadhanak Voun / US-0009366 - [Export Reports] - Manage PII access within Hive in a SOX compliant manner
	@ Change history: 22/01/2024 / Vimean Heng / US-0014626 / disable record type "special permission request" , devloper name = Admin_Request
    *****************************************************************************************************************************/	
	/*
	@InvocableMethod
    public static void removePermissionsAccess(List<Case> listCase) 
	{
        Set<String> setUID = new Set<String>();
        Set<String> setPS = new Set<String>();
        for(Case cs: listCase)
        {
            setUID.add(cs.Who_should_have_admin_access__c);
            for(String ps: (cs.Admin_Request_Type__c+'').split(';'))
            {
                String ps_API_Name = MAP_PKL_PS_NAME.get(ps);
                if(ps_API_Name <> null )
                {
                    setPS.add(ps_API_Name);                    
                }
            }	
        }
        if(!setUID.isEmpty() && !setPS.isEmpty())
        {
            removePSA_asyn(setUID,setPS);
        }
	}

    @future
	private static void removePSA_asyn(Set<String> setUID, Set<String> setPS) 
	{
        Delete [Select Id From PermissionSetAssignment WHERE AssigneeId IN :setUID AND PermissionSet.Name IN :setPS ];
    }
	*/
	
	/*****************************************************************************************************************************
	 @ Method:         createUserAsyn (private)
	 @ Version:        1.0
	 @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	 @ Purpose:        US-0008096 - US_Update New User Creation Process to include Role
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Parameter:      list of user as json
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  01.12.2020 / Vadhanak Voun / US-0008096 - US_Update New User Creation Process to include Role (Mixed DML!)
	 			     :  22.03.2023 / Sophal Noch / US-0012859 - Remove reference to Class in a CaseTriggerHandler
	 *****************************************************************************************************************************/
	@future
	private static void createUserAsyn(String userJson){
		List<User> userToCreate = (List<User>)JSON.deserialize(userJson, List<User>.class);

		//In the new requirement user should not be added to public groups,
		//they must be assigned with "wave analytics user" permission set.
		Set<Id> setUser = new Set<Id>();
		Set<Id> setUserGCX = new Set<Id>();
		Set<String> setUserExcTeam = new Set<String>();
		try{
			Database.insert(userToCreate);

		} catch (System.DmlException e){
			//system.debug(e);
			EBH_ApexLogger.logError(new List<Exception>{e}, CLASS_TICKETHANDLER, CLASS_TICKETHANDLER_METH_CHECKCREATEUSERS);
		}

		for (User u : userToCreate){
			setUser.add(u.id);
			if (u.Permission_Sets__c<>null && u.Permission_Sets__c.contains(TICKET_PERMISSIONSET_MARKETING_EXC_TEAM)){
				setUserExcTeam.add(u.Id);
			}

			if (u.ProfileId == ApexUtil.PROFILE_GCX_PARTNER_ID){ //NK:11/08/2023:US-0013997 - replace to ApexUtil
				setUserGCX.add(u.Id);
			}
		}
		addMemberAsyn(setUser, setUserGCX);  //removed future

		// 22.03.2023 / Sophal Noch / US-0012859 :
		// if (!setUserExcTeam.isEmpty()){ 
		// 	autoCreateDaysAsyn(setUserExcTeam); //removed future
		// }
	}

	@future
	private static void reactivateUsers(Set<String> setUserToReactivate, Map<String, String> mapRoleReactivate){
		List<User> listUser = new List<User>();
		for (String uId : setUserToReactivate){
			listUser.add(new User(Id = uId, isActive = true, UserRoleId = mapRoleReactivate.get(uId)));
		}
		update listUser;
	}

	/*****************************************************************************************************************************
	 @ Method:         createContactFromTicket
	 @ Version:        1.0
	 @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	 @ Purpose:        EPH-7025 User Ticket Automation Flow - Create GCX User
	 AC2: a) Create new Contact
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Parameter:      list oldTrigger:
	 list newTrigger:
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        new Contact in memory
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  07.03.2019 / Vadhanak Voun /Created the Method.
	 @                :  26.06.2019 / Vadhanak Voun /EPH-7674
	 *****************************************************************************************************************************
	 @ Change history: 19.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0007615 Created the Method.
	 *****************************************************************************************************************************/
	private static Contact createContactFromTicket(Case ticket){
		Contact c = new Contact(LastName = ticket.Last_Name__c, FirstName = ticket.First_Name__c, Email = ticket.Email_address__c, AccountId = getGCXAccount() == null ? null : getGCXAccount().Id, RecordTypeId = ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL').Id,  //NK:26/06/2019:EPH-7674,
		EBH_Status__c = CONTACT_STATUS_ACTIVE);
		return c;
	}

	private static Account gcxPartnerAccount;
	private static Account getGCXAccount(){
		if (gcxPartnerAccount == null){
			List<Account> listAcc = Database.query(SOQL_GCX_ACCOUNT);
			gcxPartnerAccount = listAcc.isEmpty() ? null : listAcc[0];
		}
		return gcxPartnerAccount;
	}

	//: 01.12.2020/ US-0008096: removed future since this method called from createUserAsyn
	//@future
	// public static void autoCreateDaysAsyn(Set<String> setUserId){ // 22.03.2023 / Sophal Noch / US-0012859
	// 	BatchAutoCreateDay.doInsertDaysForUsersFromToday(setUserId);
	// }

	/*****************************************************************************************************************************
	 @ Method:         addMemberAsyn (private)
	 @ Version:        1.0
	 @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	 @ Purpose:        EPH-3309:  As the dml in mixed objects. Asynchronous method need to separate the transaction.
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Parameter:      list String: list of userId and group id (userId_groupId) to be created  from method checkCreateUsers.
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        void
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  14.09.2017 / Vadhanak Voun /Created the Method.
	 @                  08.11.2017 / Vadhanak Voun/ updated method to: #13032
	 @                  This time a new requirement has came to map right public group when a user selects permission sets in User request form In tickets.
	 @                  Public groups has to be assigned according to the locale:
	 @                   *Locale                     *Public Group
	 @                   German (Germany) -          DE Campaign Request Approvers
	 @                   Czech (Czech Republic) -    EEC Campaign Request Approvers
	 @                   English (Ireland) -         EEC Campaign Request Approvers
	 @                   German (Switzerland) -      EEC Campaign Request Approvers
	 @                   Spanish (Spain) -           ES Campaign Request Approvers
	 @                   French (France) -           FR Campaign Request Approvers
	 @                   Italian (Italy) -           IT Campaign Request Approvers
	 @                   English (UK) -              UK Campaign Request Approvers
	 @
	 @                   15.12.2017 / Vadhanak Voun / Fixed nullpointer of  u.Permission_Sets__c line 148
	 @                    09.07.2018 / David Herrero / commented the creation of group members . EPH-6253
	 @                   20.07.2020/ vadhanak voun / US-0007854 - User creation flow for GCX profile not adding Analytics PS
	 *****************************************************************************************************************************
	 @ Change history: 19.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0007615 Created the Method.
	 @               : 01.12.2020/ US-0008096: removed future since this method called from createUserAsyn
	 *****************************************************************************************************************************/
	//@future
	private static void addMemberAsyn(Set<Id> setUser, Set<Id> setUserGCX){

		List<PermissionSet> permisss = Database.query(SOQL_PERMISSIONSET);
		List<Group> grp = Database.query(SOQL_GRP);
		List<PermissionSet> permissWave = Database.query(SOQL_PERMISSIONSET_WAVE_A_USER);

		Map<String, String> PerSetMap = new Map<String, String>();

		List<PermissionSetAssignment> listPSA = new List<PermissionSetAssignment>();
		List<PermissionSetLicenseAssign> listPSALSC = new List<PermissionSetLicenseAssign>(); //for gcx user
		List<GroupMember> listgrpMem = new List<GroupMember>();

		List<User> usrList = new List<User>();
		usrList = Database.query(SOQL_User);

		for (PermissionSet psRec : permisss){
			PerSetMap.put(psRec.Name + 'PS', psRec.Id);
		}

		for (Group grpRec : grp){
			PerSetMap.put(grpRec.DeveloperName + 'PG', grpRec.Id);
		}

		Map<String, String> matchGrpPermSet = new Map<String, String>();
		matchGrpPermSet.put('Campaign Approval', 'Sales planner / marketer');
		//matchGrpPermSet.put('Report exports', 'EBH_exportReportsPermissionSet');
		matchGrpPermSet.put('Ticket Manager', 'Ticket Manager');

		matchGrpPermSet.put('Marketing Execution Team', 'Marketing_Execution_Team');//21/01/2019: EPH-6940

		for (User u : usrList){

			List<String> strSplit = u.Permission_Sets__c == null ? new List<String>() : u.Permission_Sets__c.split(';');

			for (String str : strSplit){
				String str1 = matchGrpPermSet.get(str);
				PermissionSetAssignment psa = new PermissionSetAssignment();
				// GroupMember grpMem = new GroupMember();
				if (PerSetMap.containskey(str1 + 'PS')){
					psa = new PermissionSetAssignment(PermissionSetId = PerSetMap.get(str1 + 'PS'), AssigneeId = u.id);
					listPSA.add(psa);
				}
			}

			//NK:01/12/2020: no longer used?
			//Locale_PublicGroup_Mapping__c gMapping = Locale_PublicGroup_Mapping__c.getInstance(u.LocaleSidKey);
			//if(gMapping==null)
			//{
			//     throw new TicketException(ERROR_LOCALE_GROUP_MAPPING+u.LocaleSidKey);
			//}

			//NK:16/01/2019: EPH-6940
			if (u.Permission_Sets__c<>null && u.Permission_Sets__c.contains(TICKET_PERMISSIONSET_MARKETING_EXC_TEAM)){
				listgrpMem.add(new GroupMember(GroupId = PerSetMap.get(GROUP_MARKETING_EXC + 'PG'), UserOrGroupId = u.Id));
			}
			//GCX Profile:
			//1, assign permission license
			//2, assing permssion set (differ from normal user)
		//	if (AssigEALicenses()){
            if (AssignLicense(EA_License_Assignation)){
				if (setUserGCX.contains(u.Id)){
					//NK:20/07/2020: US-0007854
					//replaced hardcoded id with ApexUtil.getPermissionSetL()
					//listPSALSC.add(new PermissionSetLicenseAssign(PermissionSetLicenseId=ApexUtil.getPermissionSetL(PSL_WAVE_COMM).Id,AssigneeId=u.Id)); //NO LONGER USED
					listPSALSC.add(new PermissionSetLicenseAssign(PermissionSetLicenseId = ApexUtil.getPermissionSetL(PSL_EA_MEMB).Id, AssigneeId = u.Id));

					listPSA.add(new PermissionSetAssignment(PermissionSetId = ApexUtil.PERMISSION_SET_COMMUNITY_ANALYTICS_ID, AssigneeId = u.id)); ////NK:11/08/2023:US-0013997-replace with ApexUtil
				} else
					//normal user
					{
						listPSA.add(new PermissionSetAssignment(PermissionSetId = permissWave[0].Id, AssigneeId = u.id));
				}
			}
            if (AssignLicense(MyTrailHeadAssignation)){

                if (!setUserGCX.contains(u.Id)){
                    listPSA.add(new PermissionSetAssignment(PermissionSetId = PerSetMap.get(MYTRAILHEAD_USERPS + 'PS'), AssigneeId = u.id));
                }
            }
		}
		try{
			//System.debug('>>>listPSALSC: '+listPSALSC.size());
			if (!listPSALSC.isEmpty() && !Test.isRunningTest()){
				Database.insert(listPSALSC);
			}

			if (!listPSA.isEmpty() && !Test.isRunningTest())
				Database.insert(listPSA);
			if (!listgrpMem.isEmpty())
				Database.insert(listgrpMem);
		} catch (Exception ex){
			//NK:20/07/2020: disabled to avoid MIXED_DML_OPERATION
			//EBH_ApexLogger.logError(new List<Exception> { ex }, 'TicketTriggerHandler','addMemberAsyn');
			ApexUtil.doSend('Error: PermissionSet/PSL/Group Assingment', UserInfo.getUserEmail(), ex.getMessage());
		}
	}

	/*****************************************************************************************************************************
	 @ Method:         validateLicense (private)
	 @ Version:        1.0
	 @ Author:         Mony Nou (mony.nou@gaea-sys.com)
	 @ Purpose:        US-0009540 - Check Licenses Availability when creating users
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Parameter:      Id sameSettingUserId: User Id from field Case.Same_settings_as__c
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        Boolean - Return True/False depend on the availability of No. Licenses
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  24.05.2021 / Mony Nou /Created the Method.
	 *****************************************************************************************************************************/
	private static Boolean validateLicense(Id sameSettingUserId){

		return (sameSettingUser.containsKey(sameSettingUserId) && sameSettingUser.get(sameSettingUserId).Profile.UserLicense.UsedLicenses < sameSettingUser.get(sameSettingUserId).Profile.UserLicense.TotalLicenses);

	}

	/*****************************************************************************************************************************
	 @ Method:         createUser (private)
	 @ Version:        1.0
	 @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	 @ Purpose:        EPH-3309: private method to construct a User object from a reference Ticket.
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Parameter:      object Ticket: ticket reference to create User
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        new object User.
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  14.09.2017 / Vadhanak Voun /Created the Method.
	 @                  20.10.2017 / Vadhanak Voun / added UserPermissionsMarketingUser = true to createUser
	 @                  27.10.2020 / Vadhanak Voun / US-0008096 - US_Update New User Creation Process to include Role
	 @ 					24.05.2021 / Mony Nou / US-0009540 - Check Licenses Availability when creating users
	 *****************************************************************************************************************************/
	private static User createUser(Case ticket){

		//cs_CZ___Europe/Prague___en_US
		CountryMapping3__c cMapping = CountryMapping3__c.getInstance(ticket.Locale__c);
		String localeKey = '';
		String timeZoneKey = ''; //oneTicket.Timezone__c =
		String langKey = '';
		if (cMapping != null){
			String[] keys = (cMapping.value__c + '').split('___');
			localeKey = keys[0];
			timeZoneKey = keys[1];
			langKey = keys[2];
		} else{
			throw new TicketException(ERROR_NO_COUNTRY_MAPPING + ticket.Locale__c);
		}
		//NK:26/06/2019:EPH-7674
		String u_suffix = ticket.Picklist__c == PROFILE_GCX_PARTNER ? AT_GCX_SUFFIX : AT_HIVE_SUFFIX;
		String roleId = getRoleId(ticket);

		//MN-24052021 - US-0009540 - Check the remain license for that New User's profile. If there is out of License => do not create user and change Case.Status = Waiting for licenses
		User u;
		if (sameSettingUser.containsKey(ticket.same_settings_as__c)) {
			
			User setting_user = sameSettingUser.get(ticket.same_settings_as__c);

			//Check available License by compare the used licenses to the total licenses
			if (setting_user.Profile.UserLicense.UsedLicenses < setting_user.Profile.UserLicense.TotalLicenses) {
				
				u = new User(//Username = ticket.Email_address__c.split('@')[0] + AT_HIVE_SUFFIX,
					Username = ticket.Ebay_Corp_ID__c + u_suffix, TimeZoneSidKey = timeZoneKey, 
					ProfileId = setting_user.ProfileId, LocaleSidKey = localeKey, LanguageLocaleKey = langKey, EmailEncodingKey = ENCODE_UTF8, 
					LastName = ticket.Last_Name__c, FirstName = ticket.First_Name__c, FederationIdentifier = ticket.Ebay_Corp_ID__c, Email = ticket.Email_address__c, 
					Division = ticket.Division__c, Alias = ticket.First_Name__c.left(1)+ticket.Last_Name__c.left(7), 
					CommunityNickname = ticket.First_Name__c + ticket.Last_Name__c + HIVE_SUFFIX, Permission_Sets__c = ticket.Permission_Sets__c, 
					UserPermissionsMarketingUser = true, Cost_Center__c = ticket.Cost_Center__c, Department = ticket.Department__c, UserRoleId = roleId);
			}

		}
		//*****MN-24052021 - US-0009540

		/* MN-24052021 - US-0009540 - Comment old logic and move to above
		User u = new User(//Username = ticket.Email_address__c.split('@')[0] + AT_HIVE_SUFFIX,
		Username = ticket.Ebay_Corp_ID__c + u_suffix, TimeZoneSidKey = timeZoneKey, 
		//  ProfileId = MAP_PROFILES.get(ticket.Picklist__c),
		ProfileId = SameSettingUserProfile.get(ticket.same_settings_as__c), LocaleSidKey = localeKey, LanguageLocaleKey = langKey, EmailEncodingKey = ENCODE_UTF8, LastName = ticket.Last_Name__c, FirstName = ticket.First_Name__c, FederationIdentifier = ticket.Ebay_Corp_ID__c, Email = ticket.Email_address__c, Division = ticket.Division__c, Alias = ticket.First_Name__c.left(1)+ticket.Last_Name__c.left(7), CommunityNickname = ticket.First_Name__c + ticket.Last_Name__c + HIVE_SUFFIX, Permission_Sets__c = ticket.Permission_Sets__c, UserPermissionsMarketingUser = true, Cost_Center__c = ticket.Cost_Center__c, Department = ticket.Department__c, UserRoleId = roleId);
		*/

		return u;
	}

	/*****************************************************************************************************************************
	 @ Method:         getRoleId (private)
	 @ Version:        1.0
	 @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	 @ Purpose:        US-0008096 - US_Update New User Creation Process to include Role
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Parameter:      object Case: ticket reference to create User
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        role id.
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  29.10.2020 / Vadhanak Voun /Created the Method.
	 *****************************************************************************************************************************/
	private static String getRoleId(Case ticket){
		UserRole uRole = ApexUtil.getUserRoleByName(ticket.Roles__c);
		uRole = uRole == null ? ApexUtil.getUserRoleByName(ROLE_GLOBAL) : uRole;
		String roleId = String.isNotBlank(ticket.Role_Id_Same_As__c) ? ticket.Role_Id_Same_As__c : uRole.Id;

		return (ticket.Picklist__c == PROFILE_GCX_PARTNER && ticket.Roles__c == null) ? null : roleId;
	}

	/*****************************************************************************************************************************
	 @ Method:         createTicketShare
	 @ Version:        1.0
	 @ Author:         Samnang MUONG (samnang.muong@gaea-sys.com)
	 @ Purpose:        //EPH-2950 - Trigger on ticket object for manual sharing with record creator.
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Parameter:      list newTrigger:
	 Map oldTrigger:
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        void
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  10.10.2017 / Samnang MUONG /Created the Method.
	 *****************************************************************************************************************************
	 @ Change history: 19.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0007615 Created the Method.
	 @*****************************************************************************************************************************/
	public static void createTicketShare(List<Case> newTickets, Map<Id, Case> oldMapTicket){

		map<Id, Id> mapTicketCreatorID = new map<Id, Id>();
		for (Case ticket : newTickets){

			if (oldMapTicket != null && (ticket.OwnerId == oldMapTicket.get(ticket.id).OwnerId))
				continue;
			mapTicketCreatorID.put(ticket.id, ticket.CreatedById);
		}

		if (mapTicketCreatorID.isEmpty())
			return;
		list<Ticket__Share> lstTicketShr = new list<Ticket__Share>();
		for (Id ticketId : mapTicketCreatorID.keySet()){
			Ticket__Share ticketShr = new Ticket__Share();
			ticketShr.ParentId = ticketId;
			ticketShr.UserOrGroupId = mapTicketCreatorID.get(ticketId);
			ticketShr.AccessLevel = 'Edit';
			ticketShr.RowCause = Schema.Ticket__Share.RowCause.Manual;
			lstTicketShr.add(ticketShr);
		}

		if (!lstTicketShr.isEmpty())
			list<Database.SaveResult> lstResult = Database.insert(lstTicketShr, false);
	}
	
	/*****************************************************************************************************************************
	 @ Method:         autoPopulateProfile
	 @ Version:        1.0
	 @ Author:         Sreymeas NAO (sreymeas.nao@gaea-sys.com)
	 @ Purpose:        US-0009431 User creation ticket process enhancement
	 @                Based on "User Type" and "Country" selected in the "Ticket" Object,
	 @                auto populate "Profile" as "AU Standard User Profile" if Country = AU and User Type = Full License User
	 @                auto populate "Profile" as "Standard User Profile" if Country is not AU and User Type is Full License User
	 @                auto populate "Profile" as "GCX Partner Profile" if Country is not AU and User Type is GCX Portal User
	 @                If user select Country = AU and User Type is GCX Portal User, throw the below error message
	 @                "GCX Community is currently not enabled for AU. Please select "Full License user" as User Type."
	 @ Event :           Before Insert / Before Update
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Parameter:      lstTicket:
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        void
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  20.09.2019 / Sreymeas NAO /Created the Method.
	 *****************************************************************************************************************************
	 @ Change history:  US-0007615 19.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the method.
	 *****************************************************************************************************************************/
	public static void autoPopulateProfile(List<Case> lstTicket, Map<Id, Case> mapOld){

		RecordType recTypeUserForm = ApexUtil.getRecordTypeByName('Case', 'User_Request_Form');

		for (Case oneTicket : lstTicket){
			if (recTypeUserForm.Id<> oneTicket.recordTypeId)
				continue;
			//rule for only user request
			if (mapOld == null || ticketChanged(mapOld.get(oneTicket.Id), oneTicket))
				//new or updated with eligible fields
				{
					//1, auto populate "Profile" as "AU Standard User Profile" if Country = AU and User Type = Full License User
					if (oneTicket.Country__c == TICKET_COUNTRY_AU && oneTicket.User_Type__c == TICKET_USER_TYPE_LICENSE){
						oneTicket.Picklist__c = TICKET_AU_PROFILE;
				}
				//2, auto populate "Profile" as "Standard User Profile" if Country is not AU and User Type is Full License User
				else if (oneTicket.Country__c != TICKET_COUNTRY_AU && oneTicket.User_Type__c == TICKET_USER_TYPE_LICENSE){
					oneTicket.Picklist__c = TICKET_STANDARD_PROFILE;
				}
				//3, auto populate "Profile" as "GCX Partner Profile" if Country is not AU and User Type is GCX Portal User
				else if (oneTicket.Country__c != TICKET_COUNTRY_AU && oneTicket.User_Type__c == TICKET_USER_TYPE_PORTAL){
					oneTicket.Picklist__c = TICKET_GCX_PROFILE;
				} else{
					oneTicket.addError(System.Label.Error_Ticket_AU_GCX);
				}

				if (oneTicket.CurrencyIsoCode == null){
					oneTicket.CurrencyIsoCode.addError(System.Label.Error_Currency_Required);
				}
			}


		}
	}

	private static Boolean ticketChanged(Case tOld, Case tNew){
		return tOld.Country__c<> tNew.Country__c || tOld.Timezone__c<> tNew.Timezone__c || tOld.Cost_Center__c<> tNew.Cost_Center__c || tOld.Department__c<> tNew.Department__c || tOld.User_Type__c<> tNew.User_Type__c || tOld.CurrencyIsoCode<> tNew.CurrencyIsoCode;
	}

	/*****************************************************************************************************************************
	 @ Method:         assignUniqueKey
	 @ Version:        1.0
	 @ Author:         Vadhanak Voun
	 @ Purpose:        US-0009366 - [Export Reports] - Manage PII access within Hive in a SOX compliant manner
     @ Event:          before insert,before update
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        void
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  21.05.2021 / Vadhanak Voun /Created the Method.
	 *****************************************************************************************************************************/	
	public static void assignUniqueKey(List<Case> listNew)
    {
        for(Case c: listNew)
        {
            if(c.Unique_Id__c == null)
            {                 
                c.Unique_Id__c = ApexUtil.doEncrypt(System.now().formatLong()+'',ApexUtil.encryptionkey).left(30).replace('+','');//url decode + to space. 
            }
        }
    }
	
	/*****************************************************************************************************************************
	 @ Method:         AssigEALicenses
	 @ Version:        1.0
	 @ Author:         David Herrero
	 @ Purpose:        US-0009285 Add the ability to switch on / off the assignation of EAlicenses
	 @
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        void
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  20.09.2019 / David /Created the Method.
	 *****************************************************************************************************************************
	 *****************************************************************************************************************************/
	public static String assigneaLicense;
	/*public static Boolean AssigEALicenses(){
		if (assigneaLicense == null){
			User_Creation_Settings__mdt uc = [select id, EA_License_Assignation__c
			                                  from User_Creation_Settings__mdt
			                                  where QualifiedApiName = :USER_CREATION_SETTINGS_NAME];
			if (uc != null){
				assigneaLicense = String.valueOf(uc.EA_License_Assignation__c);
			} else{
				assigneaLicense = 'FALSE';
			}
		}
		return Boolean.valueOf(assigneaLicense);
	}*/
    public static User_Creation_Settings__mdt uc;
    public static Boolean AssignLicense(String LicenseType){
		
            if (uc==null){
                uc = [select id, EA_License_Assignation__c, MyTrailHead_License_Assignation__c
                from User_Creation_Settings__mdt
                where QualifiedApiName = :USER_CREATION_SETTINGS_NAME];
            }
			return uc==null?false:Boolean.valueOf(uc.get(LicenseType));
		
	}

	/*****************************************************************************************************************************
	 @ Method:         validateSurveyVista
	 @ Version:        1.0
	 @ Author:         David Herrero
	 @ Purpose:        US-0009538 Validate Ardira Surveys
	 @ Event: 		   CaseTrigger executed BEFORE insert / update
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        void
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  20.05.2021 / David /Created the Method.
	 					17.09.2021 / SRONG TIN / backup code back.
						27.07.2022 / SRONG TIN / US-0011596 - SPIKE Enhancements to survey validation trigger
	 *****************************************************************************************************************************/
	public static final string VALIDATE_SURVEY_RECORDTYPEID=ApexUtil.VALIDATE_SURVEY_RECORDTYPEID;	//NK:11/08/2023:US-0013997
	public static void validateSurveyVista(List<Case> newList, Map<id,Case>oldMap){

		List<Case> ticketsToValidateSurvey = new List<Case>();
		List<Case> ticketsToUpdate = new List<Case>();
		for (Case c : newList){
			if (c.recordtypeid==VALIDATE_SURVEY_RECORDTYPEID && c.Ardira_Survey__c!=null){
				ticketsToValidateSurvey.add(c);
			}
		}
		if(ticketsToValidateSurvey.isEmpty()) return;
		// validate Ardira Survey
		// 27.07.2022 / SRONG TIN / US-0011596
		validateArdiraSurvey(ticketsToValidateSurvey);
		//System.debug(JsON.serializePretty(mapCasesSurveyErrors));
		for (Case c : newList){
			c.Ardira_Survey_Validation_Result__c='';
			if (mapCasesSurveyErrors.containsKey(c.Unique_Id__c)){
				c.Ardira_Survey_Validation_Result__c=string.join(mapCasesSurveyErrors.get(c.Unique_Id__c),'][');
				c.status=(String.isBlank(c.Ardira_Survey_Validation_Result__c)?SURVEY_VALIDATED:SURVEY_VALIDATION_FAILED);
			}else{
				c.status=SURVEY_VALIDATED;
			}
		}
		UpdateCampaignsAfterTicketValidation(newList,oldMap);

	
	}

	/*****************************************************************************************************************************
	 @ Method:         validateArdiraSurvey
	 @ Version:        1.0
	 @ Author:         David Herrero
	 @ Purpose:        US-0009538 Validate Ardira Surveys
	 @
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        void
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  20.05.2021 / David /Created the Method.
	 					17.09.2021 / SRONG TIN / backup code back.
						01.03.2022 / David / Enhance the method (US-0011035)
	 *****************************************************************************************************************************/
	
	public static void validateArdiraSurvey(List<Case> cl){
		id callOutcomeQuestionId;
		set <String> surveyIds= new set<String>();
		map<String,String> mapSurveyCase = new map<String,String>();
		for (Case c : cl){
			surveyIds.add(c.Ardira_Survey__c);
			mapSurveyCase.put(c.ardira_survey__c,c.Unique_Id__c);
		}
		
		Map<ID,ArdiraSurvey__Survey__c> mapIdSurveys = new map<id,ArdiraSurvey__Survey__c>((ArdiraSurvey__Survey__c[]) Database.query(SURVEY_QUERY));

		Map<id,ArdiraSurvey__Question__c[]>mapCaseRelatedQuestions = new map<id,ArdiraSurvey__Question__c[]>();
		for (ArdiraSurvey__Question__c qqs :(ArdiraSurvey__Question__c[]) Database.query(SURVEY_QUESTION_QUERY)){
			if (mapCaseRelatedQuestions.containskey(qqs.ArdiraSurvey__Survey__c)){
				mapCaseRelatedQuestions.get(qqs.ArdiraSurvey__Survey__c).add(qqs);
			}else{
				mapCaseRelatedQuestions.put(qqs.ArdiraSurvey__Survey__c, new List<ArdiraSurvey__Question__c>{qqs});
			}
		}
		Map<String,String> questionIdsMap = new Map<String,String>();
		for (Id surveyId : mapSurveyCase.keySet()){
			ArdiraSurvey__Survey__c arSurvey;
			
			if (!mapIdSurveys.containsKey(surveyId)){
				addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_SURVEY_DONT_EXIST);
			}else{
				arSurvey=mapIdSurveys.get(surveyId);
			}

			//SRONG TIN / 27.07.2022 / US-0011596
			if (!arSurvey.ArdiraSurvey__Enable_Scoring_Survey_Responses__c){
				addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_WRONG_SCORING  + Scoring_must_be_enabled);

			}
			if (arSurvey.ArdiraSurvey__Allowable_Target_Objects__c != null){
				List<String> targetObjects = arSurvey.ArdiraSurvey__Allowable_Target_Objects__c.split(',');
				for (String sTarget : targetObjects){
					sTarget=sTarget.trim();
					if(!SURVEY_TARGET_OBJECT.contains(sTarget)){
						addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_WRONG_TARGET_OBJECT  + ' ' +sTarget	);
						break;
					}
				}

			}
			if (!arsurvey.ArdiraSurvey__CS_Do_Not_Require_Authentication__c){
				addErrorMessage(mapSurveyCase.get(surveyId), WRONG_AUTHENTICATION);
			}
			//SRONG TIN / 2.08.2022 / US-0011596
			if (arsurvey.ArdiraSurvey__Community_Id__c != COMMUNITY_SITE_ID){
				addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_WRONG_COMMUNITY);
			}
		
			if (arSurvey.ArdiraSurvey__Status__c != SURVEY_STATUS){
				addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_STATUS_NOT_OPEN);

			}
			/*if (arSurvey.ArdiraSurvey__Allowable_Target_Objects__c==null || (arSurvey.ArdiraSurvey__Allowable_Target_Objects__c!=null && !arSurvey.ArdiraSurvey__Allowable_Target_Objects__c.equalsIgnoreCase(SURVEY_TARGET_OBJECT))){
				addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_WRONG_TARGET_OBJECT);
			}*/

			//System.debug('Checking survey scoring' + arSurvey.ArdiraSurvey__CO_Scoring_Method__c);
			if (arSurvey.ArdiraSurvey__CO_Scoring_Method__c != SURVEY_SCORING){
				addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_WRONG_SCORING);
			}

			//getting Survey questions
		

			if (!mapCaseRelatedQuestions.containsKey(arSurvey.Id)){
				addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_NO_QUESTIONS);
			} else{
				callOutcomeQuestionId = searchQuestion(mapCaseRelatedQuestions.get(arSurvey.Id), CALL_OUTCOME);
				if (callOutcomeQuestionId == null){
					addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_NO_CALLOUTCOME);
				
				}else{
					//SRONG TIN / 27.07.2022 / US-0011596
					List <ArdiraSurvey__Answer_Choice__c> AnswerChoice = (List<Ardirasurvey__Answer_Choice__c>)Database.query(SURVEY_ANSWER_CHOICE);
					if (AnswerChoice.size()!=3){
						//add error
					}else{
						for (ArdiraSurvey__Answer_Choice__c c : AnswerChoice){
							if (c.ArdiraSurvey__Score__c<=0 || ! CALL_OUTCOME_SCORE_VALUES.contains((Integer)c.ArdiraSurvey__Score__c)){
								addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_NO_CALLOUTCOME + ' ' + c.ArdiraSurvey__Score__c);
								break;

							}
						}
					}
				}


			}
			if (arSurvey.ArdiraSurvey__Response_Mapping_Rules__c == null || String.isBlank(arSurvey.ArdiraSurvey__Response_Mapping_Rules__c)){
				addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_NO_MAPPINGS_DEFINED);
			} else{

				try{
					List<SurveyJSON> obj = SurveyJSON.parse(arSurvey.ArdiraSurvey__Response_Mapping_Rules__c);
					SurveyJson mapping = obj[0];
					if (mapping.mappingTime != MAPPING_TIME || 
						mapping.reverseMappingEnabled!=null ||
				
						mapping.mappingAction != MAPPING_ACTION || 
						mapping.mappedObject != MAPPED_OBJECT ||
						mapping.FieldRules == NULL || 
						mapping.activeStatus != MAPPING_ACTIVE_STATUS ||
						( !mapping.fieldRules.isEmpty() && 
							( mapping.fieldRules[0].targetField != MAPPING_FIELDRULES_TARGET_FIELD || 
							mapping.fieldRules[0].questionValueToMap != MAPPING_FIELDRULES_QUESTION_VALUE_TO_MAP
							)
						)
				
					){ 
						addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_WRONG_MAPPING);
					}
				}catch(Exception e){
					addErrorMessage(mapSurveyCase.get(surveyId), System.Label.Ardira_Surveys_ERROR_WRONG_MAPPING);
				}
			}
		}
	}

	@TestVisible
	private static ID searchQuestion(ArdiraSurvey__Question__c[] relques, String searchedString){
		for (ArdiraSurvey__Question__c q : relques){
			if (q.ArdiraSurvey__Question_Short_Text__c.trim().equalsIgnorecase(searchedString)){
				return q.ID;
			}
		}
		return null;
	}

	@TestVisible
	private static void addErrorMessage(String caseId, String errorString){
		//System.debug('Assigning error message ' + errorString + ' to CaseId:' + caseId);
		if (mapCasesSurveyErrors.containsKey(caseId)){
			mapCasesSurveyErrors.get(caseId).add(errorString);
		} else{
			mapCasesSurveyErrors.put(caseId, new List<String>{errorString});
		}
	}

	@TestVisible
	private static void UpdateCampaignsAfterTicketValidation(List<Case>newList, Map<Id,Case>oldMap){
	RecordType recTypeValidateSurvey = ApexUtil.getRecordTypeByName('Case', 'Validate_Survey');
		List<Case> CasesToUpdate = new List<Case>();
		List<Campaign> CampaignsToUpdate = new List<Campaign>();
		//System.debug('New List ? +'+ newList.size());
		for (Case c : newList){
			//System.debug('Recordtype= '  + (c.recordtypeid == recTypeValidateSurvey.Id));
			//System.debug('Status = ' + c.status);
			//System.debug('Old Status = ' + oldMap.get(c.id).status);
			
			
			if (c.recordtypeid == recTypeValidateSurvey.Id &&
			c.Status==TICKET_STATUS_VALIDATED 
			//&&c.status!= oldMap.get(c.id).status
			){
				c.Status=STATUS_CLOSED;
				CasesToUPdate.add(c);
				if (c.Related_Campaign__c!=null){
					//SRONG TIN / 02.08.2022 / US-0011596
					CampaignstoUpdate.add(
						new Campaign(Id=c.Related_Campaign__c, Ardira_Survey__c=c.Ardira_Survey__c));
				}
			
			}
		}
		//System.debug('About to update Campaigns + '  + CampaignsToUpdate);
		if (!CampaignsToUpdate.isEmpty()){
			update CampaignsToUpdate;
		}
	}

	class TicketException extends Exception{
	}

	public static Method_Trigger_Manager__mdt readMtdObject(String mdtName) {
        Method_Trigger_Manager__mdt m=[select Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, method1__c, Method_1_name__c, Method_2_name__c, Method_3_name__c, Method_4_name__c, Method_5_name__c, Method_6_name__c, Method_7_name__c, Method_8_name__c, Method_9_name__c, method2__c, method3__c, method4__c, method5__c, method6__c, method7__c, method8__c, method9__c from Method_Trigger_Manager__mdt  WHERE DeveloperName =: mdtName];
        return  m;
        
    }

	 /*****************************************************************************************************************************
	 @ Method:         manageSPUserDisconnect
	 @ Version:        1.0
	 @ Author:         Vadhanak Voun
	 @ Purpose:       US-0011343 - Adding User to Existing Seller Portal Group
	 @				  disconect user from portal and revoke access
	 @				 from web2case, triggers the revokeAccess and disconection
     @ Event:          after insert
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        void
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  24.05.2022 / Vadhanak Voun /Created the Method.
	 *****************************************************************************************************************************/	
	public static void manageSPUserDisconnect(List<Case> listNewCase)
	{
		RecordType caseSP = ApexUtil.getRecordTypeByName('Case', 'Seller_Portal_Deactivation');
		List<Case> listTodo = new List<Case>();
		for(Case cse : listNewCase)
		{
			if(cse.RecordTypeId == caseSP.Id && cse.Description <> null)
			{
				listTodo.add(cse);
			}
		}

		if(!listTodo.isEmpty())
		{	
			Set<String> setUserIds = new Set<String>();
			List<Account> listSellerReset = new List<Account>();
			for(Case cse : listTodo)
			{
				//system.debug('---Description: '+cse.Description);
				Map<String,String> mapUsrSSO_SlaveCont = (Map<String,String>)JSON.deserialize(cse.Description, Map<String,String>.class);
				String apiId = mapUsrSSO_SlaveCont.get('eBay_API_User_Id__c');
				String usrId = mapUsrSSO_SlaveCont.get('UserId');
				if(String.isNotBlank(usrId))
				{
					setUserIds.add(usrId);
				}
				doRevokeSeller(usrId,apiId);
				listSellerReset.add(new Account(eBay_API_User_Id__c=apiId,User_Disconnected__c = FALSE));
				
			}

			upsert listSellerReset eBay_API_User_Id__c;
			//system.debug('---setUserIds: '+setUserIds);
			if(!setUserIds.isEmpty())
			{
				disconnectSPUsers(setUserIds);
			}
		}
	}
	@future(callout=true)
	private static void doRevokeSeller(String usrId,String sellerApiId )
	{
		Boolean revokeResult = ApexUtil.revokeUserAccess3PLink(usrId,sellerApiId);
		//system.debug('---revokeResult: '+revokeResult);
	}
	@future
	private static void disconnectSPUsers(Set<String> setUserIds )
	{
		List<User> listUsr = new List<User>();
		for(User usr: [Select Id,FirstName,LastName From User Where Id IN:setUserIds])
		{
			usr.IsPortalEnabled=FALSE;
			usr.UserName = (usr.Id+'@deactivated.com');
            usr.FirstName = 'Deactivated '+usr.FirstName;
            usr.LastName = 'Deactivated '+usr.LastName;
            usr.Email = (usr.Id+'@deactivated.com');
             
            Database.DMLOptions dlo = new Database.DMLOptions();
            dlo.EmailHeader.triggerUserEmail = false;
            usr.setOptions(dlo);

			listUsr.add(usr);
		}
		update listUsr;
	}
}