@isTest
private class DealClonePageControllerTest {
    
    @testSetup
    static void setupData(){
        EBH_TestDataFactory.setUpCustomSettings();     
        Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData();     
        Account acc = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
                       FROM Account WHERE Id =: testDataMap.get('se1').Id][0];
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Test', EBH_Country__c='UK');
        insert sc;
        
        EBH_Deal__c d1 = new EBH_Deal__c(EBH_BusinessName__c=acc.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456789', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                         EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test', EBH_SpotlightCategory__c=sc.Id,
                                         EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                         EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
        insert d1;
    }
    
    static testMethod void testClone() {
        EBH_Deal__c d = [select id,EBH_BusinessName__c,EBH_SellerEmail__c,EBH_ProductTitle__c,EBH_DealSiteId__c,EBH_MarketingTitle__c,EBH_Category__c,EBH_Vertical__c,EBH_SpotlightCategory__c
                         ,EBH_DealPrice__c from EBH_Deal__c limit 1];
        Test.startTest();
        
        EBH_Deal__c d2=d.clone();
        insert d2;
        Test.stopTest();
        
        EBH_Deal__c d3=[select id,ebh_status__c,ebh_category__c,EBH_DealFormat__c from EBH_Deal__c where id=:d2.ID];
        
        SYSTEM.assert(d3.EBH_Status__c==EBH_ConstantsUtility.DEAL_STATUS_NEW);
        System.assert(d3.EBH_DealFormat__c==null);
        System.assert(d3.EBH_Category__c==d.EBH_Category__c);
        
        
    }
    
    static testMethod void testDealClonePage(){
        
         EBH_Deal__c d = [select id,EBH_BusinessName__c,EBH_SellerEmail__c,EBH_ProductTitle__c,EBH_DealSiteId__c,EBH_MarketingTitle__c,EBH_Category__c,EBH_Vertical__c,EBH_SpotlightCategory__c
                         ,EBH_DealPrice__c from EBH_Deal__c limit 1];
        Test.startTest();
        DealClonePageController controller = new DealClonePageController(
            new ApexPages.standardController(d)); 
        controller.clonecustom();
        Test.stopTest();
        
        
    }
    
}