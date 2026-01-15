/*********************************************************************************************************************************
@ Class:        BatchCancelTaskOnCampaignMemberTest
@ Version:      1.0
@ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:      Test for BatchCancelTaskOnCampaignMember
@               - If Campaign Member record has Marketing Cloud Status = "Cancelled"
@               the related task should be deleted.
@                  
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 30.04.2021 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
@isTest
private class Batch_CancelTaskOnCampaignMemberTest {
    @TestSetup
    static void makeData(){
        EBH_TestDataFactory.setUpCustomSettings();
    }
    
    static testMethod void testDeletedTask() {
        List<Account> legalEntities = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity') ;
        List<Contact> contacts = EBH_TestDataFactory.createContacts(2, 'Test Contact', legalEntities[0].id);
        List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE,null,'Feasibility');
        CampaignMember camp2 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[1].Id,10,System.today()-5,System.today())[0];
        Task task2 = new Task(Subject = 'Test Campaign', EBH_CampaignMemberId__c = camp2.Id ,Follow_Up_Task__c=false,WhoId=contacts[1].Id,WhatId=campaigns1[0].Id);
        insert new Task[]{task2};
        task2.EBH_ResponseCode__c = 40;
        update new Task[]{task2};
        camp2.Marketing_Cloud_Status__c=EBH_ConstantsUtility.CM_MC_STATUS_CANCELLED;
        camp2.EBH_ResponseCode__c = 40; 
        update new CampaignMember[]{camp2};
        Test.startTest();
            Database.executeBatch(new Batch_CancelTaskOnCampaignMember());
        Test.stopTest();
        Task[] testTask2 = [select Id from Task where EBH_CampaignMemberId__c =: camp2.Id];
        System.assertEquals(0,testTask2.size(),'Task has been deleted');
    }
}