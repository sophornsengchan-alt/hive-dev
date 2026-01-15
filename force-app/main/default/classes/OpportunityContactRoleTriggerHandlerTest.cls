/*********************************************************************************************************************************
 @ Class:          OpportunityContactRoleTriggerHandlerTest
 @ Version:        1.0
 @ Author:         ... 
 @ Purpose:        OpportunityContactRoleTriggerHandler
----------------------------------------------------------------------------------------------------------------------------------
@ Change history    : ...
@				    : 13/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
*********************************************************************************************************************************/
@isTest
private class OpportunityContactRoleTriggerHandlerTest {
    
    @TestSetup
    static void makeData(){
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
                                         Product__c = true,
                                         EBH_SellerListTrigger__c = true,
                                         EBH_EnableUrgencyEmail__c = true,
                                         EBH_TargetedSellerTrigger__c = true,
                                         EBH_TaskTrigger__c = true,
                                         EBH_TicketTrigger__c = true,
                                         EBH_User__c = true,
                                         DealTrigger__c = true,
                                         Coupon_Send_BCD_File_To_DL__c =true,
                                         Coupon_Seller_Send_T4_T40_to_seller__c =true,
                                         CaseTrigger__c =true,
                                         OpportunityContactRole__c = true
                                        );    
    }

    @IsTest
    static void updatePrimaryContactAndSAP()
    {
        Account account = TST_DataGenerator.generateAccount();
        account.SAP_ID__c = '11111111';
        insert account;

        Date startDate = Date.today();
        Date endDate = startDate.addMonths(3);

        

        Contact con1 = new Contact(LastName='test con1',AccountId=account.Id);
        Contact con2 = new Contact(LastName='test con2',AccountId=account.Id);
        insert new Contact[]{con1,con2};

        Test.startTest();
            Opportunity opp1 = new Opportunity(
                Name = 'Opp 1',
                Amount = 1000,
                StageName = 'Qualified Meeting',
                CloseDate = endDate,
                Start_Date__c = startDate,
                End_Date__c = endDate,
                AccountId = account.Id
            );
            insert opp1;
            
            //case 1: insert CR with correct role
            OpportunityContactRole cr1 = new OpportunityContactRole(ContactId=con1.Id,OpportunityId=opp1.Id,Role=OpportunityContactRoleTriggerHandler.ROLE_INVOICE_RECIPIENT,IsPrimary=true);
            OpportunityContactRole cr2 = new OpportunityContactRole(ContactId=con2.Id,OpportunityId=opp1.Id,Role='Other',IsPrimary=false);
            insert new OpportunityContactRole[]{cr1,cr2};
                
                
                Opportunity oppSel = [Select Id,Primary_Contact__c From Opportunity Where Id=:opp1.Id];
            System.assertEquals(con1.Id, oppSel.Primary_Contact__c);
            
            //case 2: delete CR, so opp primary contact role is cleared
            delete cr1;
            oppSel = [Select Id,Primary_Contact__c From Opportunity Where Id=:opp1.Id];
            
            System.assertEquals(null, oppSel.Primary_Contact__c);
            
            //case3: update CR to invoice recepient
            cr2.Role=OpportunityContactRoleTriggerHandler.ROLE_INVOICE_RECIPIENT;
            cr2.IsPrimary = true;
            update cr2;
            oppSel = [Select Id,Primary_Contact__c From Opportunity Where Id=:opp1.Id];
            
            System.assertEquals(con2.Id, oppSel.Primary_Contact__c);
        Test.stopTest();
    }
}