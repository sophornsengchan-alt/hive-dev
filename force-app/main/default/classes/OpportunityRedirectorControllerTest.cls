/*********************************************************************************************************************************
@ Class:          OpportunityRedirectorControllerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0008557 - [NA] Opportunity Layout "Details" and "Related" sections
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.11.2020 / Sovantheany Dim / Created the class.
                : 08.11.2024 / Bora Chhorn / US-0016108 - Remove ebay NA Acquisition record type from Profiles/permission sets
                : 07.01.2025 / Bora Chhorn / US-0016403 - Ability to create Opportunities on existing Legal Entities
*********************************************************************************************************************************/
@isTest
private class OpportunityRedirectorControllerTest {
    @testSetup
    static void setup(){
        EBH_TestDataFactory.setUpCustomSettings();
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'NA Standard User Base' Limit 1];
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User Profile' Limit 1];  
        Profile standardAdsProfile = [SELECT Id FROM Profile WHERE Name = 'Standard Ads User Profile' Limit 1];  
        User adminUser = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(adminUser){
            User objUser = new User(Alias = 'test1', 
                                Email = 'test.test@test.com', 
                                EmailEncodingKey = 'UTF-8', 
                                LastName = 'test',
                                LocaleSidKey = 'en_US', 
                                LanguageLocaleKey='en_US', 
                                ProfileId = objProfile.Id, 
                                TimeZoneSidKey = 'Europe/London', 
                                UserName = 'test@hive.project.com.invalide');
            insert objUser;

            User objUser2 = new User(Alias = 'test2', 
                                Email = 'test2.test@test.com', 
                                EmailEncodingKey = 'UTF-8', 
                                LastName = 'test2',
                                LocaleSidKey = 'en_US', 
                                LanguageLocaleKey='en_US', 
                                ProfileId = standardProfile.Id, 
                                TimeZoneSidKey = 'Europe/London', 
                                UserName = 'test2@hive.project.com.invalide');
            insert objUser2;

            User objUserAds = new User(Alias = 'test3', 
                                Email = 'test3.test@test.com', 
                                EmailEncodingKey = 'UTF-8', 
                                LastName = 'test3',
                                LocaleSidKey = 'en_US', 
                                LanguageLocaleKey='en_US', 
                                ProfileId = standardAdsProfile.Id, 
                                TimeZoneSidKey = 'Europe/London', 
                                UserName = 'test3@hive.project.com.invalide');
            insert objUserAds;
        }
    }
    @isTest
    static void validatedOpportunityTest(){
        Test.startTest();
        
        User currentUser = [SELECT Id FROM User WHERE Username='test@hive.project.com.invalide'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'US_CA_Standard_user'];
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = currentUser.Id);
        insert psa;
        System.runAs(currentUser) {
            RecordType receBayBusinessDevelopment = ApexUtil.getRecordTypeByName('Opportunity', 'eBay_Business_Development');
            Map<String, Object> mapResult = OpportunityRedirectorController.validatedOpportunity(receBayBusinessDevelopment.ID);
            Test.stopTest();
            System.assert(mapResult.get('isSuccess') == true,'Opporunity is validated');
        }
    }
    @isTest
    static void validatedOpportunityWitheBayBusinessDevelopmentTest(){
        User currentUser = [SELECT Id FROM User WHERE Username='test2@hive.project.com.invalide'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Opportunity_Business_Development_Base_Access'];
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = currentUser.Id);
        insert psa;
        System.runAs(currentUser) {
            Test.startTest();
            RecordType receBayBusinessDevelopment = ApexUtil.getRecordTypeByName('Opportunity', 'eBay_Business_Development');
            Map<String, Object> mapResult = OpportunityRedirectorController.validatedOpportunity(receBayBusinessDevelopment.ID);
            Test.stopTest();
            System.assert(mapResult.get('isSuccess') == true,'User can create opportunity without any error');
        }
        
    }
    @isTest
    static void validatedOpportunityWitheBayBusinessDevelopmentTest2(){
        User currentUser = [SELECT Id FROM User WHERE Username='test2@hive.project.com.invalide'];
        System.runAs(currentUser) {
            Test.startTest();
            RecordType receBayBusinessDevelopment = ApexUtil.getRecordTypeByName('Opportunity', 'eBay_Business_Development');
            Map<String, Object> mapResult = OpportunityRedirectorController.validatedOpportunity(receBayBusinessDevelopment.ID);
            Test.stopTest();
            System.assert(mapResult.get('isSuccess') == true,'User can create opportunity without any error');
        }
        
    }
    @isTest
    static void validatedOpportunityWithMISTeamTest(){
        User currentUser = [SELECT Id FROM User WHERE Username='test@hive.project.com.invalide'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Project_Integration_Help_Manager'];
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = currentUser.Id);
        insert psa;
        System.runAs(currentUser) {
            Test.startTest();
            RecordType receBayBusinessDevelopment = ApexUtil.getRecordTypeByName('Opportunity', 'eBay_Business_Development');
            Map<String, Object> mapResult = OpportunityRedirectorController.validatedOpportunity(receBayBusinessDevelopment.ID);
            Test.stopTest();
            System.assert(mapResult.get('isSuccess') == false,'Opportunities for Business Development cannot be created manually.');
        }
        
    }
    @isTest
    static void validateCloneQuoteButtonTest(){

        User currentUser = [SELECT Id FROM User WHERE Username='test3@hive.project.com.invalide'];
        System.runAs(currentUser) {
            Test.startTest();
                Map<String, Object> mapResult = OpportunityRedirectorController.validateCloneQuoteButton();
            Test.stopTest();
            System.assert(mapResult.get('isSuccess') == true,'The result should return isSuccess = true.');
        }
    }
}