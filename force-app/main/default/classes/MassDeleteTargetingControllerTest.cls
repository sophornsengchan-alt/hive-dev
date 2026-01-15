/*********************************************************************************************************************************
@ Class:          MassDeleteTargetingControllerTest
@ Version:        1.0
@ Author:         Sovantheany dim
@ Purpose:        06.12.2022/ US-0011047 - Team Lead with GCX Super user Permission unable to Remove Target Lists created by other People from Campaigns
*********************************************************************************************************************************/
@isTest
public with sharing class MassDeleteTargetingControllerTest {
    @testSetup static void setUp() {
        User admin = EBH_TestDataFactory.createUser('System Administrator');
    	System.runAs(admin)
    	{
            List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller') ;
            RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
            EBH_Filter__c sellerList1 = new EBH_Filter__c(Name='test m1',RecordTypeId=rtSellerlist.Id);
            insert sellerList1;
            List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,null,'Feasibility');
            List<Contact> contacts = EBH_TestDataFactory.createContacts(1, 'Test Contact', sellers[0].id);
            contacts[0].EBH_PhoneOptOut__c = false;
            update contacts;

            campaigns1[0].EBH_ChannelMP__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
            campaigns1[0].EBH_Channel__c = 'GCX Outreach (Phone)';
            campaigns1[0].EBH_SellerList__c = sellerList1.Id;
            update campaigns1;

            List<CampaignMember> listCM0 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,11,System.today()-5,System.today());
            listCM0[0].EBH_ResponseCode__c = 10;
            update listCM0;

            EBH_TargetedSeller__c ts = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[0].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
            insert ts;
        
            Campaign_Targeting__c  ct = new Campaign_Targeting__c(Campaign__c=campaigns1[0].Id,Seller_List__c=sellerList1.Id);
            insert ct;
        }
    }

    static testMethod void testDeleteTargeting() {
        User admin = EBH_TestDataFactory.createUser('System Administrator');
        System.runAs(admin)
    	{
            Test.startTest();
            List<Campaign_Targeting__c> lstTargeting = [select id from Campaign_Targeting__c];
                ApexPages.StandardController sc = new ApexPages.StandardController(lstTargeting[0]);
                MassDeleteTargetingController controller = new MassDeleteTargetingController(sc);
                controller.deleteTargeting();
                controller.backToListView();
                controller.cancel();
                System.assert(controller.isDone);
            Test.stopTest();
            List<Campaign_Targeting__c> lstTargeting2 = [select id from Campaign_Targeting__c];
            System.assert(lstTargeting2.isEmpty());
        }
    }
}