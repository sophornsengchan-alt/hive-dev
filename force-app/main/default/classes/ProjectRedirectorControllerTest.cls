/*********************************************************************************************************************************
@ Class:          ProjectRedirectorControllerTest
@ Version:        1.0
@ Author:         Sothea Horn (sohorn@ebay.com)
@ Created Date:   25 Nov 2024
@ Purpose:        US-0015912 - Remove ability to create new project for BD and MIS
----------------------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************************/
@isTest
private class ProjectRedirectorControllerTest {
    private final static String PROJECT_OBJECT_NAME = 'EBH_Project__c';
    private final static String INTEGRATION_HELP_RECORTTYPE_NAME = 'Integration_Help';
    private final static String EUONBOARDING_RECORTTYPE_NAME = 'EUOnboarding';

    @testSetup
    static void setup(){
        EBH_TestDataFactory.setUpCustomSettings();
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User Profile' Limit 1];  
        User adminUser = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 1];
        List<User> listTestUsers = new List<User>();
        System.runAs(adminUser){
            listTestUsers.add( new User(Alias = 'test1', 
                Email = 'test1.test@test.com', 
                EmailEncodingKey = 'UTF-8', 
                LastName = 'testUser1',
                LocaleSidKey = 'en_US', 
                LanguageLocaleKey='en_US', 
                ProfileId = standardProfile.Id, 
                TimeZoneSidKey = 'Europe/London', 
                UserName = 'testUser1@hive.project.com.invalide'
            ));
            listTestUsers.add(new User(Alias = 'test2', 
                Email = 'test2.test@test.com', 
                EmailEncodingKey = 'UTF-8', 
                LastName = 'testUser2',
                LocaleSidKey = 'en_US', 
                LanguageLocaleKey='en_US', 
                ProfileId = standardProfile.Id, 
                TimeZoneSidKey = 'Europe/London', 
                UserName = 'testUser2@hive.project.com.invalide'
            ));
            listTestUsers.add(new User(Alias = 'test3', 
                Email = 'test3.test@test.com', 
                EmailEncodingKey = 'UTF-8', 
                LastName = 'testUser3',
                LocaleSidKey = 'en_US', 
                LanguageLocaleKey='en_US', 
                ProfileId = standardProfile.Id, 
                TimeZoneSidKey = 'Europe/London', 
                UserName = 'testUser3@hive.project.com.invalide'
            ));
            insert listTestUsers;
        }
    }

    @isTest
    static void testBDUserCanCreateBDProject(){
        User currentUser = [SELECT Id FROM User WHERE Username='testUser1@hive.project.com.invalide'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Opportunity_Business_Development_Base_Access'];
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = currentUser.Id);
        insert psa;
        System.runAs(currentUser) {
            Test.startTest();
            RecordType recordTypeIntegrationHelp = ApexUtil.getRecordTypeByName(PROJECT_OBJECT_NAME, INTEGRATION_HELP_RECORTTYPE_NAME);
            Map<String, Object> mapResult = ProjectRedirectorController.validateProject(recordTypeIntegrationHelp.ID);
            Test.stopTest();
            System.assert(mapResult.get('isSuccess') == false,'Projects for Business Development cannot be created manually.');
        }
    }
    @isTest
    static void testMISUserCanCreateBDProject(){
        User currentUser = [SELECT Id FROM User WHERE Username='testUser3@hive.project.com.invalide'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Project_Integration_Help_Manager'];
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = currentUser.Id);
        insert psa;
        System.runAs(currentUser) {
            Test.startTest();
            RecordType recordTypeIntegrationHelp = ApexUtil.getRecordTypeByName(PROJECT_OBJECT_NAME, INTEGRATION_HELP_RECORTTYPE_NAME);
            Map<String, Object> mapResult = ProjectRedirectorController.validateProject(recordTypeIntegrationHelp.ID);
            Test.stopTest();
            System.assert(mapResult.get('isSuccess') == true,'Projects for Business Development can be created manually MIS users.');
        }
    }
    static void testValidateNewBDProjectWithoutPermissionSet(){
        User currentUser = [SELECT Id FROM User WHERE Username='testUser2@hive.project.com.invalide'];
        System.runAs(currentUser) {
            Test.startTest();
            RecordType recordTypeIntegrationHelp = ApexUtil.getRecordTypeByName(PROJECT_OBJECT_NAME, INTEGRATION_HELP_RECORTTYPE_NAME);
            Map<String, Object> mapResult = ProjectRedirectorController.validateProject(recordTypeIntegrationHelp.ID);
            Test.stopTest();
            System.assert(mapResult.get('isSuccess') == true,'User can create Business Development Project without any error.');
        }
    }
    @isTest
    static void testValidateNewNoneBDProject(){
        User currentUser = [SELECT Id FROM User WHERE Username='testUser2@hive.project.com.invalide'];
        System.runAs(currentUser) {
            Test.startTest();
            RecordType recordTypeEUOnboarding = ApexUtil.getRecordTypeByName(PROJECT_OBJECT_NAME, EUONBOARDING_RECORTTYPE_NAME);
            Map<String, Object> mapResult = ProjectRedirectorController.validateProject(recordTypeEUOnboarding.ID);
            Test.stopTest();
            System.assert(mapResult.get('isSuccess') == true,'User can create none Business Development project without any error');
        }
        
    }
}