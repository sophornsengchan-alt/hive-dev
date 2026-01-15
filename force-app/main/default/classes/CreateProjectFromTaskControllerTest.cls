@isTest
private class CreateProjectFromTaskControllerTest {
    @isTest
    static void CreateProjectFromTaskControllerTest() { 
        EBH_TestDataFactory.setUpCustomSettings();
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        List<Contact> contacts = EBH_TestDataFactory.createContacts(2, 'Test Contact', sellers[1].id);

        Task oTask = new Task(WhatId=sellers[0].Id, WhoId=contacts[0].Id, Subject='test');
        insert oTask;

        RemoteResponse result = CreateProjectFromTaskController.getTaskRec(oTask.Id);
        System.assertEquals(RemoteResponse.STATUSCODE_OK, result.statusCode);

        Map<String, Object> mResult = (Map<String, Object>) result.content;

        result = CreateProjectFromTaskController.linkProjectToTask(oTask.Id, String.valueOf(mResult.get('uniqueId')));
        System.assertEquals(RemoteResponse.STATUSCODE_ERROR, result.statusCode);
    }
}