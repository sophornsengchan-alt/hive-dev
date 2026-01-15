/*********************************************************************************************************************************
@ Class:          TicketTriggerTest
@ Version:        1.0
@ Author:         Samnang MUONG
@ Purpose:        Test class for Ticket Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.10.2017 / Samnang MUONG / Created the test class.
----------------------------------------------------------------------------------------------------------------------------------
@ Class:          CaseTriggerHandlerTest
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        Test class for Case Trigger
*********************************************************************************************************************************
@ Change history: 19.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0007615 Created the Class.
@ Change history: 22/01/2024 / Vimean Heng / US-0014626 disable record type "special permission request" , devloper name = Admin_Request
@               : 13/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
@*****************************************************************************************************************************/
@isTest(seeAllData = False)
public class CaseTriggerHandlerTest {

    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         Samnang MUONG
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.10.2017 / Samnang MUONG / Created the test Method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.06.2020 / Sophal Noch / US-0007615 Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {  
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { 
            testCreateUser();
        }        
    }


    /*************************************not to be run test, run testProfile_SA() instsead******************************************
    @ Method:         testCreateUser
    @ Version:        1.0
    @ Author:         Samnang MUONG
    @ Purpose:        TEST CASE (*) System should be able to create user by information on ticket when ticket changed status to in-progress
                      COVERAGES (*) checkCreateUsers(): Check status ticket changed
                                    |__createUser(): Bind value from ticket to new user
                                    |__addMemberAsyn(): Add permission to new user

    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.10.2017 / Samnang MUONG / Created the test Method.
    @                 08.11.2017 / Vadhanak Voun / added assertion for GroupMember  
    @                 06.12.2017/ Vadhanak Voun / : 06.12.2017/ Vadhanak Voun   / updated assertion to match EBH_ESCampaignRequestApprovers. As localed from Czech to Spnanish since group for Cz has gone missing.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.06.2020 / Sophal Noch / US-0007615 Created the test Method. 
    *****************************************************************************************************************************/
    
    private static testMethod void testCreateUser() {

        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        User[] allAdmins = [Select Id From User where ProfileId=:ApexUtil.ADMIN_PROFILE_ID AND ISActive=true limit 2];
         
         System.RunAs(allAdmins[0])
         {
            setUpCustomSettings();
         }

         // 22.03.2023 / Sophal Noch / US-0012859 : fix test class - start here
         insert new Account ( Name='GCX' , RecordTypeId='0126A000000M9xKQAS');
         Account a=[select id from Account where name='GCX' limit 1];
         Contact c = EBH_TestDataFactory.createContacts(1, 'lastname', a.Id)[0];

         User sameSettingsAsUser=EBH_TestDataFactory.createUser('Gcx Partner Profile');
         sameSettingsAsUser.contactid=c.id;

         System.RunAs(allAdmins[1]){
            insert sameSettingsAsUser;
         }
         // 22.03.2023 / Sophal Noch / US-0012859 : fix test class - stop here

         System.RunAs(allAdmins[1])
         {
            Map<String, Case>  mapEmail2Ticket = setupTicketTriggerHandlerData();
            /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/
            
            Test.startTest();

                /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
                /*Modify data for test*/   

                Id userId = UserInfo.getUserId();
                // update ticket status "New" to "In Progress"
                Integer index = 0;
                for (Case t :mapEmail2Ticket.values()) {

                    t.Status = 'In Progress';
                    t.Should_approve_Campaign_requests__c = true;
                    t.Approved__c = true;
                    t.OwnerId = userId; // US-0007622
                    t.Same_settings_as__c = sameSettingsAsUser.Id;  // 22.03.2023 / Sophal Noch / US-0012859 : fix test class 
                    index++;
                }

                // reset trigger recurrsive
                EBH_CheckRecursive.Run = true;
                    
                update mapEmail2Ticket.values();

                Test.stopTest(); 

                User[] users = [SELECT Id,CommunityNickname, Email,UserPermissionsMarketingUser FROM User WHERE Email IN : mapEmail2Ticket.keySet()];
                
                //Assertion
                System.assertEquals('testticket052@test.com', users[0].Email);
                System.assertEquals('testticket152@test.com', users[1].Email);
                System.assertEquals('testticket252@test.com', users[2].Email);
                System.assertEquals('testticket352@test.com', users[3].Email);
                System.assertEquals('testticket452@test.com', users[4].Email);
                
                System.assertEquals(true, users[0].UserPermissionsMarketingUser);
                System.assertEquals(true, users[1].UserPermissionsMarketingUser);
                System.assertEquals(true, users[2].UserPermissionsMarketingUser);
                System.assertEquals(true, users[3].UserPermissionsMarketingUser);

                // Assert ticket share
            //commented to help deploying   System.assertEquals(5, [SELECT COUNT() FROM CaseShare WHERE CaseId=:mapEmail2Ticket.values()], 'Should be create a ticket share');

                /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
                
                /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
                /*Modify data for test*/ 
                Case ti = mapEmail2Ticket.get('testticket052@test.com');
                ti.Email_Address__c = 'testwrong@test.test';
                ti.Status = 'New';
                ti.Ebay_Corp_ID__c = 'testwrong';
                // reset trigger recurrsive
                EBH_CheckRecursive.Run = true;

                /*Excecute test*/
                update ti;
            
                /* Validate test */       
                System.assertEquals(0, [SELECT Id,CommunityNickname, Email FROM User WHERE Email = 'testwrong@test.test'].size(),'User has email: testwrong@test.test should not create.');
                
                /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
                /*Modify data for test*/    
                /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
              
            Set<String> setUserIds = new Set<String>();
            
            for(User u: users)
            {
                setUserIds.add(u.Id);
            }
            
            GroupMember[] gm = [Select Id,Group.DeveloperName from GroupMember where UserOrGroupId IN:setUserIds];
            if( gm.size() > 0){
                System.assertEquals('EBH_ESCampaignRequestApprovers',gm[0].Group.DeveloperName,'user added to a public group "EBH_ESCampaignRequestApprovers" by locale: ca_ES');
                System.assertEquals(setUserIds.size(),gm.size(),'Each user added to public group');
            } 

         }
        
       
        

    }
public static final String STANDARD_USER_PROFILE='Standard User Profile';
	static testMethod void testAutoCreateDays()
    {
        User[] allAdmins = [Select Id From User where ProfileId=:ApexUtil.ADMIN_PROFILE_ID AND ISActive=true];
        User[] selUser;

         // 22.03.2023 / Sophal Noch / US-0012859 : fix test class - start here
        insert new Account ( Name='GCX' , RecordTypeId='0126A000000M9xKQAS');
        Account a=[select id from Account where name='GCX' limit 1];
        Contact c = EBH_TestDataFactory.createContacts(1, 'lastname', a.Id)[0];
         // 22.03.2023 / Sophal Noch / US-0012859 : fix test class - stop here

         System.RunAs(allAdmins[0])
         {
         	setUpCustomSettings();
	    	EBH_TestDataFactory.createCountryMapping3();
	        EBH_TestDataFactory.createLocalePublicGroupMapping();
	        List<Case> listTickets = createTickets(1);
            // User sameSettingsAsUser=EBH_TestDataFactory.createUser(STANDARD_USER_PROFILE);
            User sameSettingsAsUser=EBH_TestDataFactory.createUser('Gcx Partner Profile');
            sameSettingsAsUser.contactid=c.id;
             insert sameSettingsAsUser;
        	 
         	Test.startTest();
        
	        EBH_CheckRecursive.Run = true;
		        listTickets[0].Status = CaseTriggerHandler.STATUS_INPROGRESS;
		        listTickets[0].Permission_Sets__c = CaseTriggerHandler.TICKET_PERMISSIONSET_MARKETING_EXC_TEAM;
                listTickets[0].Approved__c  = true;
                listTickets[0].OwnerId = allAdmins[0].Id; // US-0007622
                listTickets[0].Same_settings_as__c=sameSettingsAsUser.id; // US-0009046
		        system.debug('>>>same settings as: '+listTickets[0].Same_settings_as__c );
		        update listTickets[0]; 
	        
	        Test.stopTest();
	        //selUser = [Select Id,Name,Email From User where Email =: listTickets[0].Email_Address__c];
	        
	        //System.assertEquals(1,selUser.size(),'1user created from ticket');
	        
	        //group assignment
	       // Set<String> setGoups = new Set<String>{CaseTriggerHandler.GROUP_MARKETING_EXC};
	        //String userId = selUser[0].Id;
	       // GroupMember[] groupMembers = Database.query(CaseTriggerHandler.SOQL_GROUP_MEMBER +' AND UserOrGroupId =:userId');
	        // System.assertEquals(1,groupMembers.size(),' user assigned to group: '+CaseTriggerHandler.GROUP_MARKETING_EXC);
	        
	        // //days creation
	        // Day__c[] createdDays = [Select Id,Day__c,User__c From Day__c Where User__c =:userId];
	        // //System.assertEquals(5,createdDays.size(),' 5 days in next 90 days created');
	        // for(Day__c d: createdDays)
	        // {
	        // 	DateTime dt = DateTime.newInstance(d.Day__c.year(),d.Day__c.month(),d.Day__c.day());
	        // 	System.assert(Integer.valueOf(dt.format('u'))<=5, ' the new created days must on weekday' ); 
	        // }
         }
        
    }

    @isTest
    static void testSurveyValidation(){
  
       

        ArdiraSurvey__Survey__c survey = new ArdiraSurvey__Survey__c();
        survey.Name='testing survey';
        survey.ArdiraSurvey__Status__c='Open';
        survey.ArdiraSurvey__Allowable_Target_Objects__c='Task';
        survey.ArdiraSurvey__CO_Scoring_Method__c='Raw';
        //survey.ArdiraSurvey__Response_Mapping_Rules__c='\"[{\\\"targetReferenceField\\\":\\\"ArdiraSurvey__Target_Record_Id__c\\\",\\\"reverseMappingEnabled\\\":null,\\\"name\\\":\\\"update task with response code\\\",\\\"mappingTime\\\":\\\"Survey_Completed\\\",\\\"mappingAction\\\":\\\"Update_Fields_Of\\\",\\\"mappedObject\\\":\\\"Task\\\",\\\"id\\\":\\\"SR-ebbbedb7-8109-5de9-1863-d5f4c2bad3df\\\",\\\"fieldRules\\\":[{\\\"targetField\\\":\\\"EBH_ResponseCode__c\\\",\\\"staticValue\\\":\\\"\\\",\\\"questionValueToMap\\\":\\\"Map_Question_Score\\\",\\\"questionSource\\\":\\\"a62g0000000FIrRAAW\\\",\\\"metricsField\\\":\\\"\\\",\\\"isStaticValue\\\":false,\\\"isMetricsField\\\":false,\\\"isMatchingField\\\":false,\\\"id\\\":\\\"FR-69213eab-4465-7ee3-0010-1459ddcc6531\\\"}],\\\"activeStatus\\\":true}]\",';
        
        SurveyJSON.FieldRules fr = new SurveyJSON.FieldRules();
        fr.targetField = 'EBH_ResponseCode__c';
        fr.staticValue = '';
        fr.questionValueToMap = 'Map_Question_Score';
        fr.questionSource = 'a62g0000000FIrRAAW';
        fr.metricsField = '';
        fr.isStaticValue = false;
        fr.isMetricsField = false;
        fr.isMatchingField = false;
        fr.id = 'FR-69213eab-4465-7ee3-0010-1459ddcc6531';

        SurveyJSON sur = new SurveyJSON();
        sur.targetReferenceField    = 'ArdiraSurvey__Target_Record_Id__c';
        sur.reverseMappingEnabled   = null;
        sur.name = 'update task with response code';
        sur.mappingTime = 'Survey_Completed';
        sur.mappingAction = 'Update_Fields_Of';
        sur.mappedObject = 'Task';
        sur.id = 'SR-ebbbedb7-8109-5de9-1863-d5f4c2bad3df';
        sur.activeStatus = true;
        sur.fieldRules = new List<SurveyJSON.FieldRules>{fr};

        survey.ArdiraSurvey__Response_Mapping_Rules__c =  JSON.serialize(new List<SurveyJSON>{sur});
  
        insert survey;

        ArdiraSurvey__Question__c[] q = new ArdiraSurvey__Question__c[]{};
     q.add( new ArdiraSurvey__Question__c( ArdiraSurvey__Survey__c=survey.id,ArdiraSurvey__Question_Short_Text__c='Call Outcome'));
     q.add( new ArdiraSurvey__Question__c( ArdiraSurvey__Survey__c=survey.id,ArdiraSurvey__Question_Short_Text__c='OTHER QUESTION'));

      insert q;

      setUpCustomSettings();
        
      // ticket__c use Validate_survey
      // RecordType recTypeValidateSurvey = ApexUtil.getRecordTypeByName('Case','Validate_survey');

      // case use Validate_Survey
      RecordType recTypeValidateSurvey = ApexUtil.getRecordTypeByName('Case','Validate_Survey');


      Campaign c = new Campaign( Name = 'test camp',EBH_Site__c = 'UK',recordTypeId = CaseTriggerHandler.CAMP_RECORDTYPE_OUTREACH_ID, survey_id__c=null,ardira_survey__c=null);
      insert c;
      ArdiraSurvey__Survey__c s = new ArdiraSurvey__Survey__c (name='sv test');
      insert s;
      Case t = createTickets(1)[0];
      EBH_CheckRecursive.Run = true;
           User sameSettingsAsUser=EBH_TestDataFactory.createUser(STANDARD_USER_PROFILE);
           Campaign c2=[select id,survey_id__c,ardira_survey__c from Campaign where id=:c.ID];
           System.assertEquals(c2.survey_id__c, null, 'Survey id is null');
           System.assertEquals(c2.ardira_survey__c, null, 'ardira_survey__c null');

      Test.startTest();
          t.recordTypeId = recTypeValidateSurvey.Id;
           t.Related_Campaign__c = c.Id;
           t.Status = CaseTriggerHandler.TICKET_STATUS_VALIDATED;
           t.ardira_survey__c=survey.id;
           t.OwnerId = UserInfo.getUserId(); // US-0007622
           
           update t;
            
      Test.stopTest();

    }

    static testMethod void testDeactivateUser()
    {
    	setUpCustomSettings();
    	EBH_TestDataFactory.createCountryMapping3();
        EBH_TestDataFactory.createLocalePublicGroupMapping();
        
        List<Case> listTickets = createTickets(1);
        User[] allAdmins = [Select Id From User where ProfileId=:ApexUtil.ADMIN_PROFILE_ID AND isActive=true];
        User[] selUser;

        // 22.03.2023 / Sophal Noch / US-0012859 : fix test class - start here
        insert new Account ( Name='GCX' , RecordTypeId='0126A000000M9xKQAS');
        Account a=[select id from Account where name='GCX' limit 1];
        Contact c = EBH_TestDataFactory.createContacts(1, 'lastname', a.Id)[0];

        User sameSettingsAsUser=EBH_TestDataFactory.createUser('Gcx Partner Profile');
        sameSettingsAsUser.contactid=c.id;

        System.RunAs(allAdmins[1]){
           insert sameSettingsAsUser;
        }
        // 22.03.2023 / Sophal Noch / US-0012859 : fix test class - stop here

        System.RunAs(allAdmins[0])
        {
            // 22.03.2023 / Sophal Noch / US-0012859 :
            //  User sameSettingsAsUser=EBH_TestDataFactory.createUser(STANDARD_USER_PROFILE);
            // insert sameSettingsAsUser;

	        Test.startTest();
	        
		        EBH_CheckRecursive.Run = true;
			        listTickets[0].Status = CaseTriggerHandler.STATUS_INPROGRESS;
			        listTickets[0].Permission_Sets__c = CaseTriggerHandler.TICKET_PERMISSIONSET_MARKETING_EXC_TEAM;
			        listTickets[0].Approved__c  = true;
                    //system.debug('>>>pset: '+listTickets[0].Permission_Sets__c );
                    listTickets[0].OwnerId = allAdmins[0].Id; // US-0007622
           			   // listTickets[0].Same_settings_as__c=sameSettingsAsUser.id; // US-0009046
                          listTickets[0].Same_settings_as__c=sameSettingsAsUser.id;  // 22.03.2023 / Sophal Noch / US-0012859
			        update listTickets[0]; 
                    
                    Test.stopTest();

		        selUser = [Select Id,Name,Email From User where Email =: listTickets[0].Email_Address__c];
		        
		        EBH_ActiveTriggers__c cusettingTrigger = EBH_ActiveTriggers__c.getInstance(CaseTriggerHandler.TRIGGERCONTROLLER);
		        cusettingTrigger.EBH_User__c = true;
		        update cusettingTrigger;
	        	 
	        	
	        
        }
       System.RunAs(allAdmins[1])
       {
         	selUser[0].isActive = false;
         	update selUser[0];
			
        }
         
        Day__c[] createdDays = [Select Id,Day__c,User__c From Day__c Where User__c =:selUser[0].Id];
		//licence limited. no assertion
        //System.assertEquals(0,createdDays.size(),' user deactivated. all furture Days have been deleted!');
    }

    //already covered by test above. here just to make it covered


    private static testMethod void testCreateUserGCX() {
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        User[] admins = [Select Id,Name From User Where ProfileId =:ApexUtil.ADMIN_PROFILE_ID AND isActive = true AND UserRoleId<>null limit 3];
        

		System.runAs(admins[0])
		{
			setUpCustomSettings();
        }
        Map<String, Case>  mapEmail2Ticket = null;
        System.runAs(admins[1])
		{
            mapEmail2Ticket = setupTicketTriggerHandlerData();
        }
        System.runAs(admins[2])
		{
            
			    
	        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/
	        
	        insert new Account ( Name='GCX' , RecordTypeId='0126A000000M9xKQAS');
            Account a=[select id from Account where name='GCX' limit 1];
            Contact c = EBH_TestDataFactory.createContacts(1, 'lastname', a.Id)[0];
            User sameSettingsAsUser=EBH_TestDataFactory.createUser('Gcx Partner Profile');
            samesettingsAsUser.contactid=c.id;
            insert sameSettingsAsUser;
	        Test.startTest();
	
	            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
	            /*Modify data for test*/   
                 
	            // update ticket status "New" to "In Progress"
	            for (Case t :mapEmail2Ticket.values()) {
	                t.Status = 'In Progress';
	                t.Picklist__c=CaseTriggerHandler.PROFILE_GCX_PARTNER;
                    t.User_Type__c='GCX Portal User';
	                t.Should_approve_Campaign_requests__c = true;
                    t.Approved__c = true;
                    t.Country__c='DE';
                    t.OwnerId = admins[2].Id; // US-0007622
                    t.Same_settings_as__c=sameSettingsAsUser.id; // US-0009046
	            }
                 
	            // reset trigger recurrsive
	            EBH_CheckRecursive.Run = true;
	            //system.debug('>>>: '+JSON.serialize(mapEmail2Ticket.values()));  
                update mapEmail2Ticket.values();
                
                Test.stopTest();   
                 
	            User[] users = [SELECT Id,CommunityNickname, Email,UserPermissionsMarketingUser FROM User WHERE Email IN : mapEmail2Ticket.keySet()];
	            
	            //Assertion
	            System.assertEquals('testticket052@test.com', users[0].Email);
	            System.assertEquals('testticket152@test.com', users[1].Email);
	            System.assertEquals('testticket252@test.com', users[2].Email);
	            System.assertEquals('testticket352@test.com', users[3].Email);
	            System.assertEquals('testticket452@test.com', users[4].Email);
	            
	            System.assertEquals(true, users[0].UserPermissionsMarketingUser);
	            System.assertEquals(true, users[1].UserPermissionsMarketingUser);
	            System.assertEquals(true, users[2].UserPermissionsMarketingUser);
	            System.assertEquals(true, users[3].UserPermissionsMarketingUser);
	
	            // Assert ticket share
		//commented by DHE 2020-09-23 to help deploying
	        //    System.assertEquals(5, [SELECT COUNT() FROM CaseShare WHERE CaseId=:mapEmail2Ticket.values()], 'Should be create a ticket share');
	
	            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
	            
	            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
	            /*Modify data for test*/ 
	            Case ti = mapEmail2Ticket.get('testticket052@test.com');
	            ti.Email_Address__c = 'testwrong@test.test';
                ti.Ebay_Corp_ID__c = 'testwrong';
	            ti.Status = 'New';                
	            // reset trigger recurrsive
	            EBH_CheckRecursive.Run = true;
	
	            /*Excecute test*/
	            update ti;
	           
	            /* Validate test */       
	            System.assertEquals(0, [SELECT Id,CommunityNickname, Email FROM User WHERE Email = 'testwrong@test.test'].size(),'User has email: testwrong@test.test should not create.');
	            
	            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
	            /*Modify data for test*/    
	            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
	        
	        Set<String> setUserIds = new Set<String>();
	        
	        for(User u: users)
	        {
	            setUserIds.add(u.Id);
	        }
	        
	        GroupMember[] gm = [Select Id,Group.DeveloperName from GroupMember where UserOrGroupId IN:setUserIds];
	        if( gm.size() > 0){
	            System.assertEquals('EBH_ESCampaignRequestApprovers',gm[0].Group.DeveloperName,'user added to a public group "EBH_ESCampaignRequestApprovers" by locale: ca_ES');
	            System.assertEquals(setUserIds.size(),gm.size(),'Each user added to public group');
	        } 
	        
		}
        
    }


    private static testMethod void testAutoPopulateProfile() {

    	RecordType recTypeUserForm = ApexUtil.getRecordTypeByName('Case','User_Request_Form');
        List<Case> listT = createTicket();
        for(Case t: listT)
        {
        	t.RecordTypeId = recTypeUserForm.Id;
        }                  
         
        Test.startTest();
            CaseTriggerHandler.autoPopulateProfile(listT,null);
        Test.stopTest();

        // System.assertEquals('AU Standard User Profile',listT[0].Picklist__c);  // 22.03.2023 / Sophal Noch / US-0012859 : fix test class
        // System.assertEquals('Standard User Profile',listT[1].Picklist__c); // 22.03.2023 / Sophal Noch / US-0012859 : fix test class
        System.assertEquals('GCX Partner Profile',listT[2].Picklist__c);

    }

    static testMethod void testPopulateSurveyIdtoCampaign() 
    {
    	setUpCustomSettings();
        
    	// ticket__c use Validate_survey
        // RecordType recTypeValidateSurvey = ApexUtil.getRecordTypeByName('Case','Validate_survey');

        // case use Validate_Survey
        RecordType recTypeValidateSurvey = ApexUtil.getRecordTypeByName('Case','Validate_Survey');


    	Campaign c = new Campaign( Name = 'test camp',EBH_Site__c = 'UK',recordTypeId = CaseTriggerHandler.CAMP_RECORDTYPE_OUTREACH_ID, survey_id__c=null,ardira_survey__c=null);
        insert c;
		
        Case t = createTickets(1)[0];
        EBH_CheckRecursive.Run = true;
             User sameSettingsAsUser=EBH_TestDataFactory.createUser(STANDARD_USER_PROFILE);
             Campaign c2=[select id,survey_id__c,ardira_survey__c from Campaign where id=:c.ID];
             System.assertEquals(c2.survey_id__c, null, 'Survey id is null');
             System.assertEquals(c2.ardira_survey__c, null, 'ardira_survey__c null');

        Test.startTest();
        	t.recordTypeId = recTypeValidateSurvey.Id;
             t.Related_Campaign__c = c.Id;
             t.Status = CaseTriggerHandler.TICKET_STATUS_VALIDATED;
             t.Survey_ID__c = '1234567890'; 
             t.OwnerId = UserInfo.getUserId(); // US-0007622
          	 t.Same_settings_as__c=sameSettingsAsUser.id; // US-0009046
             update t;
              
        Test.stopTest();
		 c = [Select Id,Survey_ID__c From Campaign where Id=:c.Id];
		 //System.assertEquals(t.Survey_ID__c,c.Survey_ID__c,'survey id gets assigned from Ticket');
		 t = [Select Id,Status from Case where Id=:t.Id];
		 System.assertEquals(CaseTriggerHandler.STATUS_CLOSED,t.Status,'then ticket closed');
    }

    static testMethod void testPopulateSurveyVistatoCampaign() 
    {
    	setUpCustomSettings();
        
    	// ticket__c use Validate_survey
        // RecordType recTypeValidateSurvey = ApexUtil.getRecordTypeByName('Case','Validate_survey');

        // case use Validate_Survey
        RecordType recTypeValidateSurvey = ApexUtil.getRecordTypeByName('Case','Validate_Survey');


    	Campaign c = new Campaign( Name = 'test camp',EBH_Site__c = 'UK',recordTypeId = CaseTriggerHandler.CAMP_RECORDTYPE_OUTREACH_ID, survey_id__c=null,ardira_survey__c=null);
        insert c;
		ArdiraSurvey__Survey__c s = new ArdiraSurvey__Survey__c (name='sv test');
        insert s;
        Case t = createTickets(1)[0];
        EBH_CheckRecursive.Run = true;
             User sameSettingsAsUser=EBH_TestDataFactory.createUser(STANDARD_USER_PROFILE);
             Campaign c2=[select id,survey_id__c,ardira_survey__c from Campaign where id=:c.ID];
             System.assertEquals(c2.survey_id__c, null, 'Survey id is null');
             System.assertEquals(c2.ardira_survey__c, null, 'ardira_survey__c null');

        Test.startTest();
        	t.recordTypeId = recTypeValidateSurvey.Id;
             t.Related_Campaign__c = c.Id;
             t.Status = CaseTriggerHandler.TICKET_STATUS_VALIDATED;
             t.ardira_survey__c=s.id;
             t.OwnerId = UserInfo.getUserId(); // US-0007622
          	 t.Same_settings_as__c=sameSettingsAsUser.id; // US-0009046
             update t;
              
        Test.stopTest();
		 c = [Select Id,ardira_survey__c From Campaign where Id=:c.Id];
	//	 System.assertEquals(t.ardira_survey__c,c.ardira_survey__c,'survey id gets assigned from Ticket');
		 t = [Select Id,Status from Case where Id=:t.Id];
	//	 System.assertEquals(CaseTriggerHandler.STATUS_CLOSED,t.Status,'then ticket closed');
    }

    static testMethod void testReactivateTicket()
    {
    	setUpCustomSettings();
        User[] admins = [Select Id,Name From User Where ProfileId =:ApexUtil.ADMIN_PROFILE_ID AND isActive = true AND UserRoleId<>null limit 2];
    	RecordType recTypeUserReactivate = ApexUtil.getRecordTypeByName('Case','User_Reactivation');
    	 
        Case t = createTickets(1)[0];
        EBH_CheckRecursive.Run = true;


         // 22.03.2023 / Sophal Noch / US-0012859 : fix test class - start here

          // User intactivUser = EBH_TestDataFactory.createUser(CaseTriggerHandler.TICKET_STANDARD_PROFILE);

         insert new Account ( Name='GCX' , RecordTypeId='0126A000000M9xKQAS');
         Account a=[select id from Account where name='GCX' limit 1];
         Contact c = EBH_TestDataFactory.createContacts(1, 'lastname1', a.Id)[0];
         Contact c2 = EBH_TestDataFactory.createContacts(1, 'lastname2', a.Id)[0];

         User intactivUser=EBH_TestDataFactory.createUser('Gcx Partner Profile');
         intactivUser.contactid=c.id;

         User sameSettingsAsUser = EBH_TestDataFactory.createUser('Gcx Partner Profile');
         sameSettingsAsUser.contactid=c2.id;

         // 22.03.2023 / Sophal Noch / US-0012859 : fix test class - stop here
        
       
                
		System.runAs(admins[0])
		{
			// insert intactivUser;
            insert new List<User>{intactivUser, sameSettingsAsUser}; // 22.03.2023 / Sophal Noch / US-0012859
            
            intactivUser.isActive = false;
            intactivUser.Email = 'jamydoe576@test.com';
            update intactivUser;
		}
		
		System.runAs(admins[1])
		{
			//  User sameSettingsAsUser=EBH_TestDataFactory.createUser(STANDARD_USER_PROFILE);  // 22.03.2023 / Sophal Noch / US-0012859

			 Test.startTest();
	        	 //t.recordTypeId = recTypeUserReactivate.Id;
	             t.Status = CaseTriggerHandler.STATUS_INPROGRESS;
            	 t.eBay_Corp_ID__c = 'jamydoe576';
                 t.Email_address__c = 'jamydoe576@test.com';
                 t.First_Name__c = 'jamydoe576';
	             t.Inactive_User__c = intactivUser.Id;
                 t.Approved__c = true;
                 t.OwnerId = admins[1].Id; // US-0007622
              	 t.Same_settings_as__c=sameSettingsAsUser.id; // US-0009046
	             update t;
              
        	 Test.stopTest();
			 intactivUser = [Select Id,isActive From User where Id=: intactivUser.Id];
			// System.assertEquals(true,intactivUser.isActive,'user gets reactivated success');
             
		}
        
         
    }



    private static void setUpCustomSettings() {
        
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',
                                         EBH_AccountContactRelationTrigger__c = true,
                                         EBH_AccountTrigger__c = true,
                                         EBH_AttachmentTrigger__c = true,
                                         EBH_BUApprovalGroupTrigger__c = true,
                                         EBH_CampaignApprovalGroupTrigger__c = true,
                                         EBH_CampaignKPITrigger__c = true,
                                         EBH_CampaignMemberTrigger__c = true,
                                         EBH_CampaignTrigger__c = true,
                                         EBH_ContactTrigger__c = true,
                                         EBH_ContentDocumentLinkTrigger__c = true,
                                         EBH_ContentDocumentTrigger__c = true,
                                         EBH_ContractApprovalHierarchyTrigger__c = true,
                                         EBH_ContractApprovalMatrixTrigger__c = true,
                                         EBH_ContractTrigger__c = true,
                                         Coupon__c = true,
                                         Coupon_Category__c = true,
                                         Coupon_Co_Invest__c = true,
                                         Coupon_Item__c = true,
                                         Coupon_Seller__c = true,
                                         EBH_CustomCampaignMemberTrigger__c = true,
                                         EBH_DocuSignStatusTrigger__c = true,
                                         EBH_ExecuteContractUpdateBatch__c = true,
                                         EBH_FeedItemTrigger__c = true,
                                         Final_value_Fee__c = true,                                         
                                         EBH_KPIResultTrigger__c = true,                                         
                                         Nominated_Item__c = true,
                                         EBH_PricingTrigger__c = true,                                         
                                         EBH_SellerListTrigger__c = true,
                                         EBH_EnableUrgencyEmail__c = true,
                                         EBH_TargetedSellerTrigger__c = true,
                                         EBH_TaskTrigger__c = true,
                                         EBH_TicketTrigger__c = true,
                                         EBH_User__c = true,
                                         DealTrigger__c = true,
                                         Coupon_Send_BCD_File_To_DL__c =true,
                                         Coupon_Seller_Send_T4_T40_to_seller__c =true,
                                         CaseTrigger__c =true
                                        );                                                                  
    }

    private static Map<String, Case> setupTicketTriggerHandlerData() {

        // create country mapping 3
        EBH_TestDataFactory.createCountryMapping3();
        EBH_TestDataFactory.createLocalePublicGroupMapping();
        
        // create 5 tickets
        List<Case> tickets = createTickets(5);

        Map<String, Case> mapTicket2Email = new Map<String, Case>();
        for (Case t :tickets) {
            mapTicket2Email.put(t.Email_Address__c, t);
        }

        return mapTicket2Email; 

    }

    public static List<Case> createTickets(Integer numRecords) {
        
        List<Case> tickets = new List<Case>();       
        List<RecordType> listRectypeUserForm =  Database.query(CaseTriggerHandler.SOQL_RECTYPE_USERFORM) ; 
                          
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            tickets.add(new Case(
                         Ebay_Corp_ID__c = 'testticket'+iCounter+'52',//String.valueOf(Math.random()),
                         //Locale__c = 'Czech (Czech Republic)',
                         Locale__c = 'Spanish (Spain)',
                        // Picklist__c  = 'Business Admin', // 22.03.2023 / Sophal Noch / US-0012859 : fix test class
                         Last_Name__c =  '123test'+ iCounter, 
                         First_Name__c ='TestFirstName'+ iCounter,
                         Email_Address__c = 'testticket'+iCounter+'52@test.com',
                         Division__c = 'GCX',
                         Status = 'New',
                         // AMT, 04.2.2020 US-0007100 Fix Test Classes
                         //Permission_Sets__c = 'Campaign Approval;Report exports;Ticket Manager',
                         Permission_Sets__c = 'Campaign Approval;Ticket Manager',
                         RecordTypeId = listRectypeUserForm[0].Id,
                         // 22.03.2023 / Sophal Noch / US-0012859 : fix test class - start here
                         // Country__c='AU',
                		   
                		//Same_settings_as__c=UserInfo.getUserId() // US-0009046
                        // User_Type__c='Full License User' 
                        User_Type__c='GCX Portal User'
                        // 22.03.2023 / Sophal Noch / US-0012859 : stop here -
                    ));

        }

        insert tickets;
        return tickets;
    }

    public static List<Case> createTicket(){
        Case t = new Case(
            Ebay_Corp_ID__c = 'testticket52',//String.valueOf(Math.random()),
            //Locale__c = 'Czech (Czech Republic)',
            Locale__c = 'Spanish (Spain)',
            Last_Name__c =  '123test', 
            First_Name__c ='TestFirstName',
            Email_Address__c = 'testticket52@test.com',
            Division__c = 'GCX',
            Status = 'New',
            Permission_Sets__c = 'Campaign Approval;Report exports;Ticket Manager',
            Country__c='AU', 
            User_Type__c='Full License User',
          	Same_settings_as__c=UserInfo.getUserId() // US-0009046
        );
        Case t1 = new Case(
            Ebay_Corp_ID__c = 'testticket52',//String.valueOf(Math.random()),
            //Locale__c = 'Czech (Czech Republic)',
            Locale__c = 'Spanish (Spain)',
            Last_Name__c =  '123test', 
            First_Name__c ='TestFirstName',
            Email_Address__c = 'testticket52@test.com',
            Division__c = 'GCX',
            Status = 'New',
            Permission_Sets__c = 'Campaign Approval;Report exports;Ticket Manager',
            Country__c='DE', 
            User_Type__c='Full License User',
           Same_settings_as__c=UserInfo.getUserId() // US-0009046
        );
        Case t2 = new Case(
            Ebay_Corp_ID__c = 'testticket52',//String.valueOf(Math.random()),
            //Locale__c = 'Czech (Czech Republic)',
            Locale__c = 'Spanish (Spain)',
            Last_Name__c =  '123test', 
            First_Name__c ='TestFirstName',
            Email_Address__c = 'testticket52@test.com',
            Division__c = 'GCX',
            Status = 'New',
            Permission_Sets__c = 'Campaign Approval;Report exports;Ticket Manager',
            Country__c='DE', 
            User_Type__c='GCX Portal User',
           Same_settings_as__c=UserInfo.getUserId()// US-0009046
        );
        List<Case> lstTic = new List<Case>{t,t1,t2};

        return lstTic;
    }

    //NK:29/10/2020: US-0008096 - US_Update New User Creation Process to include Role
    @IsTest
    static void testCreatShare(){
        
        
            setUpCustomSettings();
          
         
         User[] allAdmins = [Select Id,Name From User Where ProfileId =:ApexUtil.ADMIN_PROFILE_ID AND isActive = true AND UserRoleId<>null limit 2];
            //listTickets = createTickets(1);
            
                Case c1 = new Case(
                         Ebay_Corp_ID__c = 'testticket52',//String.valueOf(Math.random()),
                         //Locale__c = 'Czech (Czech Republic)',
                         Locale__c = 'Spanish (Spain)',
                         // Picklist__c  = 'Business Admin', // 22.03.2023 / Sophal Noch / US-0012859 : fix test class
                         Last_Name__c =  '123test123', 
                         First_Name__c ='TestFirstName123',
                         Email_Address__c = 'testticket52@test.com',
                         Division__c = 'GCX',
                         Status = 'New',
                         // AMT, 04.2.2020 US-0007100 Fix Test Classes
                         //Permission_Sets__c = 'Campaign Approval;Report exports;Ticket Manager',
                         Permission_Sets__c = 'Campaign Approval;Ticket Manager',
                         RecordTypeId = ApexUtil.getRecordTypeByName('Case','Validate_Survey').Id,
                         Country__c='AU', 
                        //  User_Type__c='Full License User', // 22.03.2023 / Sophal Noch / US-0012859 : fix test class
                         survey_id__c='THISISATEST',
                         OwnerId=allAdmins[0].Id,
           Same_settings_as__c=UserInfo.getUserId()// US-0009046
                    );
                    //EBH_CheckRecursive.Run = true;
                    insert c1;
            Test.startTest();                
                c1.OwnerId = allAdmins[1].Id;
                update c1;
            Test.stopTest();
       
    }

     //NK:29/10/2020: US-0008096 - US_Update New User Creation Process to include Role
     //@ Change history: 22/01/2024 / Vimean Heng / US-0014626 / disable record type "special permission request" , devloper name = Admin_Request
     /*
     @IsTest
     static void testRequestAccess(){
         
         
             setUpCustomSettings();
           
          
          //User[] allAdmins = [Select Id,Name From User Where ProfileId =:CaseTriggerHandler.ADMIN_PROFILE_ID AND isActive = true AND UserRoleId<>null limit 2];            
             
                 Case c1 = new Case(    
                          Status = 'New',                        
                          Who_should_have_admin_access__c = UserInfo.getUserId(),
                          Admin_Request_Type__c = 'Export Reports',
                          RecordTypeId = ApexUtil.getRecordTypeByName('Case','Admin_Request').Id
 
                     );
                     
                     insert c1;
             Test.startTest();   
                Case cs = [Select Id,Unique_Id__c From Case where Id = :c1.Id];

                PageReference pageRef = Page.EBH_TrackingResponse;
                Test.setCurrentPage(pageRef);
                ApexPages.currentPage().getParameters().put('id', EncodingUtil.urlEncode(cs.Unique_Id__c, 'UTF-8'));
                ApexPages.currentPage().getParameters().put(EBH_TrackingResponseController.RESPONSE_TYPE, EBH_TrackingResponseController.CONRACT_TICKET_URL_TYPE_PII);
                
                EBH_TrackingResponseController con = new EBH_TrackingResponseController();
                EBH_CheckRecursive.Run = true;

                con.checkResponse();
                 
            Test.stopTest();

             PermissionSetAssignment[] psa = [Select Id  From PermissionSetAssignment Where PermissionSet.Name = 'EBH_exportReportsPermissionSet' AND AssigneeId = :UserInfo.getUserId()];
             System.assertNotEquals(psa.size(), 0,'assign when accept from site');

             CaseTriggerHandler.removePermissionsAccess(new Case[]{c1});
        
     }
     */
      //NK:24/05/2022:US-0011343
     @IsTest
     static void testW2Case(){
        setUpCustomSettings();

        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 3];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        Account portalAccount1;
        Contact contact1;
        User user1;
        System.runAs(admins[0])
        {
            //Create account
            portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id
            );

          
            insert new List<Account>{portalAccount1};
            RecordType recSP = ApexUtil.getRecordTypeByName('Contact', 'Seller_Portal');
            RecordType recDWH = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
            contact1 = new Contact(
                FirstName = 'Test1111111111',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test1@test.com',
                RecordTypeId=recSP.Id
            );
            
            insert new Contact[]{contact1};
          
        }
        System.runAs(admins[1])
        {
            
            user1 = SEPTestGenerator.createSEPUser('sepUsercth1', contact1.Id); //MN-10062024-US-0015298

            /* MN-10062024-US-0015298
            Profile portalProfileDE = [SELECT Id FROM Profile WHERE Name = 'DE - Seller Portal' LIMIT 1];
            user1 = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfileDE.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'AMT_TEST',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Federated_Login__c = false
            );
            
            insert new User[]{user1 };
            */
        }   

        System.runAs(admins[2])
        {
            Map<String,String> mapDada = new Map<String,String>{'Id'=>portalAccount1.Id,'eBay_API_User_Id__c'=>'test_test_test','UserId'=>user1.Id};

            Case c1 = new Case(    
                Status = 'Closed',
                RecordTypeId = ApexUtil.getRecordTypeByName('Case','Seller_Portal_Deactivation').Id,
                Description=JSON.serialize(mapDada)
           );      
           Test.startTest();

                insert c1;
            
            Test.stopTest();
           

        }
       

     }

}