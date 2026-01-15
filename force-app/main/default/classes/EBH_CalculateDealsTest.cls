/*****************************************************************************************************************************
  @ Change history: 13.09.2022 / Sarom Chetra / US-0012444 - Fix failing test class EBH_CalculateDealsTest
*********************************************************************************************************************************/
@isTest
private class EBH_CalculateDealsTest {
     
    @IsTest
    static void testCalc(){
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='se1',RecordTypeID = sellerRecordType.Id);
        insert acc;

        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Test', EBH_Country__c='UK');
        insert sc;
        RecordType dealV1Rec = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V1');
        
        //Change history: 13.09.2022 / Sarom Chetra / US-0012444 - Fix failing test class EBH_CalculateDealsTest
        EBH_Deal__c d1 = new EBH_Deal__c(RecordTypeId=dealV1Rec.Id,EBH_BusinessName__c=acc.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456789', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test', EBH_SpotlightCategory__c=sc.Id,
                                EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_Vertical__c='Fashion',EBH_DealSiteId__c='77');
        
        EBH_Deal__c d2 = new EBH_Deal__c(RecordTypeId=dealV1Rec.Id,EBH_BusinessName__c=acc.Id, EBH_SellerPrice__c=11, EBH_eBayItemID__c='223456789', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=3, 
                                EBH_RecommendedRetailPriceWAS__c='WAS', EBH_MarketingTitle__c='test2', EBH_SpotlightCategory__c=sc.Id,
                                EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                EBH_Category__c='Garten', EBH_ProductTitle__c='product 2',EBH_SellerEmail__c='sales1@test.com',EBH_Quantity__c=1,EBH_Vertical__c='Moda',EBH_DealSiteId__c='88');
        
        insert new List<EBH_Deal__c>{d1,d2};
		// End Sarom Chetra / US-0012444 - Fix failing test class EBH_CalculateDealsTest
		
        EBH_DealsBudget__c db = new EBH_DealsBudget__c(Deal_Site__c='77',EBH_Budget__c=1000,Subsidy_Final__c=2000,EBH_Vertical__c='Fashion',Year__c=Date.today().year()+'',EBH_Quarter__c='Q1');
        insert db;
        
        String thisMonth = Datetime.now().format('MMMM');

        EBH_DealsBudgetMonth__c dbm = new EBH_DealsBudgetMonth__c(EBH_Month__c=thisMonth,EBH_DealsBudget__c=db.Id);
        insert dbm;

        EBH_Deal__c[]  ddd = [Select Id From EBH_Deal__c WHERE SystemModStamp =TODAY AND EBH_Vertical__c<> null AND EBH_DealStartDate__c<>null];
         
        Test.startTest();     
            EBH_CalculateDeals cd = new EBH_CalculateDeals();        
            cd.execute(null);
        Test.stopTest();
        
    }
}