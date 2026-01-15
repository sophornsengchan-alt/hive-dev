/*********************************************************************************************************************************
@ Class:          Batch_Task_DeleteUpdateTest
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        US-0012126  - CPU Limit error when user update Campaign stage to "Stopped"
@ Change history: 25.July.2022 / SRONG TIN / Created the class.
@               : 13/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
*********************************************************************************************************************************/
@isTest 
public with sharing class Batch_Task_DeleteUpdateTest {
    
    @testSetup 
    static void setupData(){
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
                                         Coupon__c = false, //Disable Coupon Trigger so that we can use Batch to sync data
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
	 
      RecordType rt = EBH_TestDataFactory.getRecordTypeByName('Campaign','EBH_AMOutreach');
        Campaign campaigns1 = new Campaign();
        campaigns1.Name = 'CPU LIMT';
		campaigns1.EBH_Site__c = 'UK';
		campaigns1.RecordTypeId = rt.Id;  
        campaigns1.Status = 'Completed';
        insert campaigns1;
        
        List<Account> accounts = new List<Account>();
        for(integer i = 0;i<20;i++){
            Account acc = new Account();
            acc.Name = 'SRO Account CPU Limit Test_'+i;
            acc.EBH_RevRollup__c = 'DE';
            acc.RecordTypeId = '0126A000000M9xLQAS';
            acc.EBH_OracleID__c = '09876543'+i;
            acc.EBH_PrimarySite__c = 'Germany';
            accounts.add(acc);
        }
        insert accounts;
        
        List<Contact> lstCon = new List<Contact>();
        for(Account acc: accounts){
            Contact con = new Contact();
            con.AccountId = acc.Id;
            con.Salutation = 'Mr.';
            con.FirstName = 'CPU';
            con.LastName = 'Limit';
            con.Email = 'srong.tin@gaea-sys.com';
            con.Primary_Contact__c = true;
            con.EBH_EmailOut__c = false;
            con.EBH_PhoneOptOut__c = false;
            con.EBH_PostOptOut__c = false;
            lstCon.add(con);
        }
        insert lstCon;
       
        List<CampaignMember> camMember = new List<CampaignMember>();
        for(Contact con: lstCon){
            CampaignMember cm = new CampaignMember();
            cm.CampaignId = campaigns1.Id;
            cm.ContactId = con.Id;
            cm.EBH_ResponseCode__c = 10;
            cm.EBH_Results__c = 'Call Planned';
            cm.EBH_LastResponseDate__c = System.today();
            camMember.add(cm);
        }
        insert camMember;  
       
    }
    
    static testMethod void testBatchTaskDeleteTask() {
        
        
        List<Task> lstTask = new List<Task>();
        for(CampaignMember cm: [Select Id,ContactId,CampaignId From CampaignMember limit 20]){
             Task task2 = new Task(
                Subject = 'Test Campaign', 
                EBH_CampaignMemberId__c = cm.Id ,
                Follow_Up_Task__c=false,
                WhoId=cm.ContactId,
                WhatId=cm.CampaignId,
                Related_Campaign__c = cm.CampaignId
            );
            lstTask.add(task2);
        }
        if(!lstTask.isEmpty()){
            insert lstTask;
        }
        
        Test.startTest();
        Database.executeBatch(new Batch_Task_DeleteUpdate());
        Test.stopTest();
    }
    
    static testMethod void testBatchTaskUpdateTask() {
        
        
        List<Task> lstTask = new List<Task>();
        for(CampaignMember cm: [Select Id,ContactId,CampaignId From CampaignMember limit 20]){
             Task task2 = new Task(
                Subject = 'Test Campaign', 
                EBH_CampaignMemberId__c = cm.Id ,
                Call_attempts__c = 2,
                Follow_Up_Task__c=false,
                WhoId=cm.ContactId,
                WhatId=cm.CampaignId,
                Related_Campaign__c = cm.CampaignId
            );
            lstTask.add(task2);
        }
        if(!lstTask.isEmpty()){
            insert lstTask;
        }
        
        Test.startTest();
        Database.executeBatch(new Batch_Task_DeleteUpdate());
        Test.stopTest();
    }
	
	static testMethod void testBatchTaskUpdateTask2() {
        List<Task> lstTask = new List<Task>();
        Set<String> camIds = new Set<String>();
        for(CampaignMember cm: [Select Id,ContactId,CampaignId From CampaignMember limit 20]){
             Task task2 = new Task(
                Subject = 'Test Campaign', 
                EBH_CampaignMemberId__c = cm.Id ,
                Follow_Up_Task__c=false,
                WhoId=cm.ContactId,
                WhatId=cm.CampaignId,
                Related_Campaign__c = cm.CampaignId
            );
            camIds.add(cm.CampaignId);
            lstTask.add(task2);
        }
        if(!lstTask.isEmpty()){
            insert lstTask;
        }
        
        Test.startTest();
        Database.executeBatch(new Batch_Task_DeleteUpdate(camIds));
        Test.stopTest();
    }    
    
}