/*****************************************************************************************************************************
@ Class:       EBH_UpdateContractApproversBatch
@ Author:      Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:     US-0008386 test class for EBH_UpdateContractApproversBatch
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  28.09.2021 / Mony Nou / Created the method.
@               : 13/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
@*****************************************************************************************************************************/
@IsTest 
private class EBH_UpdateContractApproversBatchTest {
   
    @isTest
    static void test_method() {

        setUpCustomSettings();
        List<Account> legalEntities = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
        List<Contract> contractsListing = EBH_TestDataFactory.createContracts (3, 'Listing Agreement', legalEntities[0].id, legalEntities[1].id );

        Test.startTest();

            EBH_UpdateContractApproversBatch obj = new EBH_UpdateContractApproversBatch();
            Database.executeBatch(obj);

        Test.stopTest();
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
}