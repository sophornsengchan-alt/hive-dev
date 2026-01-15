@isTest
private class CommunityHomePageControllerTest {
    @testSetup
    private static void setup(){
        EBH_TestDataFactory.setUpCustomSettings();  
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
        
        RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
        EBH_Filter__c sellerList1 = new EBH_Filter__c(Name='test m1',RecordTypeId=rtSellerlist.Id);
        insert sellerList1;
        
        List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,null,'Feasibility');
        List<Contact> contacts = EBH_TestDataFactory.createContacts(4, 'Test Contact', sellers[0].id);
        contacts[0].EBH_PhoneOptOut__c = false;
        contacts[1].EBH_PhoneOptOut__c = false;
        contacts[2].EBH_PhoneOptOut__c = false;
        contacts[3].EBH_PhoneOptOut__c = false;
        update contacts;
        
        campaigns1[0].EBH_ChannelMP__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
        campaigns1[0].EBH_Channel__c = 'GCX Outreach (Phone)';
        campaigns1[0].EBH_SellerList__c = sellerList1.Id;
        campaigns1[0].EBH_PriorityDescription__c = 'P1';
        update campaigns1;
        
        List<CampaignMember> listCM0 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,11,System.today()-5,System.today());
        listCM0[0].EBH_ResponseCode__c = 10;
        update listCM0;
        
        Task t1 = new Task(Subject ='test1', WhatId=campaigns1[0].Id,WhoId=contacts[0].Id,EBH_CampaignMemberId__c=listCM0[0].id,Call_attempts__c=1,Order_Priority__c=1,Call_Back_Window_start__c=system.today()+2);
        insert t1;
    }
    @isTest
    private static void test1(){
        Test.startTest();
            Task sTask = [SELECT Id,WhatId,Subject FROM Task];
            CommunityHomePageController chp = new CommunityHomePageController(new ApexPages.standardController(sTask));
            chp.getPriorityDescription();
            chp.selectedPriorityValue = 'P1';
            chp.filterResults();
            chp.taskFilter.Call_attempts__c = 1;
            chp.taskFilter.Order_Priority__c = 1;
            chp.taskFilter.Whoid = sTask.WhatId;
            chp.taskFilter.Call_Back_Window_start__c = system.today()+2;
            chp.first();
            chp.next();
            chp.previous();
        	chp.last();
        	String queryStr = chp.TaskQuery;
        	String filterStatus = chp.filterStatus;
            String filterCallAttempts = chp.filterCallAttempts;
            String filterRelatedTo = chp.filterRelatedTo;
            String filterPriority = chp.filterPriority;
            //List<Task> tasks = chp.Tasks;
        Test.stopTest();
    }
}