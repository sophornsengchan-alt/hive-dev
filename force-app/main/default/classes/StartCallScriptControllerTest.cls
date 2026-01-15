/*********************************************************************************************************************************
@ Class:          StartCallScriptControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        test class for StartCallScriptController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  15.06.2021 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
private class StartCallScriptControllerTest {

    @TestSetup
    static void makeData(){
        User adminUser = [
        SELECT Id
        FROM User
        WHERE IsActive = TRUE AND Profile.Name = 'System Administrator'
        LIMIT 1
        ];
        System.runAs(adminUser) {
        EBH_TestDataFactory.setUpCustomSettings();
        }

        // Account acc = new Account();
        // acc.Name = 'Test Account 007';
        // acc.recordTypeID = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id;
        // insert acc;
        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');

        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'User';
        con.Email = 'test.007@example.com';
        con.AccountId = sellers[0].Id;
        con.recordTypeId = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL').Id;
        insert con;

        Task t = new Task();
        t.Subject = 'Test Task 007';
        t.WhatId = sellers[0].Id;
        t.WhoId = con.Id;
        t.Order_Priority__c = 10;
        t.EBH_Account__c = sellers[0].Id;
        insert t;
         
    }

    /*****************************************************************************************************************************
    @ Method:       testGetSessionId
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0009379 - test method for StartCallScriptController.getSessionId
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.06.2021 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    @isTest 
    private static void testGetSessionId(){
        String sessionId = StartCallScriptController.getSessionId();
        System.assertNotEquals(null, sessionId);
    }
    
    /*****************************************************************************************************************************
    @ Method:       testSaveContacts
    @ Author:       sovantheany.dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0011439 - Duplicate Management Contacts
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  11.07.2022 / sovantheany.dim / Created the method.
    @*****************************************************************************************************************************/
    @isTest 
    private static void testSaveContacts(){
        Test.startTest();
        Account acc = new Account();
        acc.Name = 'Test Acc1';
        acc.RecordTypeID = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id;
        insert acc;
        Contact cont = new Contact(
            	FirstName = 'Test',
                Lastname = 'test con2',
                AccountId = acc.Id,
                Email = System.now().millisecond() + 'test2@test.com',
                RecordTypeId=ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL').Id);
        
        StartCallScriptController.saveContacts(new List<Contact>{cont});
        
        Test.stopTest();
    }

    @isTest 
    private static void testApexInit()
    {
        Task tt = [Select Id, Subject, WhatId, WhoId from Task Where Subject = 'Test Task 007' Limit 1];
        Map<String,Object> mapResult = StartCallScriptController.apexInit(tt.Id);
        System.assertNotEquals(null, mapResult);
    }
    
}