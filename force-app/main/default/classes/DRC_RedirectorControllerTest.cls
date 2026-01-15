@isTest
private class DRC_RedirectorControllerTest {
    private static EBH_DealRetailCampaign__c drc;
    private static EBH_Deal__c d1;
    private static EBH_Deal__c d2;
    private static EBH_SpotlightCategory__c sc;
    
    static void setupData(){
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account acc = new Account(Name='se1',RecordTypeID = sellerRecordType.Id,NA_Deals_Subsidy_PayPal_Email__c='test@test.com',NA_Deal_Program_Vetted__c = true);
        insert acc; 
        sc = new EBH_SpotlightCategory__c(Name='Test 1', EBH_Country__c='US');
        insert sc; 
        RecordType naUnsubDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V3');
        RecordType standardDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V1');
        RecordType dealWindowRecordType = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c','Deal_Campaign_V2');   
        drc = new EBH_DealRetailCampaign__c(RecordTypeId=dealWindowRecordType.Id,EBH_Country__c='0');
        insert drc;
        d1 = new EBH_Deal__c(EBH_DealRetailCampaign__c=drc.Id,RecordTypeId=naUnsubDealRecordType.Id,EBH_BusinessName__c=acc.Id,EBH_DealSiteId__c='0', EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456781456', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test',EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), 
                                EBH_DealEndDate__c=Date.today().addDays(1),EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
        d2 = new EBH_Deal__c(RecordTypeId=standardDealRecordType.Id,EBH_BusinessName__c=acc.Id,EBH_DealSiteId__c='0', EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456780768', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test2',EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), 
                                EBH_DealEndDate__c=Date.today().addDays(1),EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
                                
        insert new List<EBH_Deal__c>{d1,d2};
    }
    @isTest
    static void testRedirectPage(){
        setupData();
        PageReference pageRef = Page.DRC_Redirector_Page;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',drc.Id);
        ApexPages.StandardSetController ssc0 = new ApexPages.StandardSetController(new List<EBH_Deal__c>{d1});
        ssc0.setSelected(new List<EBH_Deal__c>{d1});
        DRC_RedirectorController dcsa0 = new DRC_RedirectorController(ssc0);
        //dcsa0.redirectToPage();

    }
    
        

}