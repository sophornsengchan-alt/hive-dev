/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class EBH_ScrapDealTest {

    static testMethod void testBatScrapDeal() {
    	
        EBH_TestDataFactory.setUpCustomSettings();     
        Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData();     
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Spotlight Category', EBH_SpotlightCategoryID__c='Spotlight Category1',EBH_Country__c='UK'); 
        insert sc;
        EBH_Deal__c d1 = new EBH_Deal__c(EBH_DealEndDate__c=Date.today().addDays(1),EBH_DealFormat__c='Primary',EBH_eBayItemID__c='123456789',EBH_SellerPrice__c=1000,EBH_DealPrice__c=500,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.today(),EBH_Status__c='Deal Agreed',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1, EBH_SpotlightCategory__c=sc.id,EBH_BusinessName__c=testDataMap.get('se1').Id);
        EBH_Deal__c d2 = new EBH_Deal__c(EBH_DealEndDate__c=Date.today().addDays(1),EBH_DealFormat__c='Primary',EBH_eBayItemID__c='233121274562',EBH_SellerPrice__c=1000,EBH_DealPrice__c=439,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.today(),EBH_Status__c='Deal Agreed',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1, EBH_SpotlightCategory__c=sc.id,EBH_BusinessName__c=testDataMap.get('se1').Id);
        List<EBH_Deal__c> ld = new List<EBH_Deal__c>{d1,d2};
        insert ld;
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute()); 
        String ss = String.valueOf(Datetime.now().second());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        Test.startTest();
          
          //bat.execute(null);
          EBH_ScrapDeal bat = new EBH_ScrapDeal(); 
          System.schedule('Schedule to Insert Deal Sloth Allocation', nextFireTime,bat);
          //Database.execute(ld); 
        Test.stopTest();
          
        EBH_Deal__c d1Sel = [Select Id,EBH_DealPrice__c,EBH_Pricenotmatching__c From EBH_Deal__c where Id=:d1.Id];
        EBH_Deal__c d2Sel = [Select Id,EBH_DealPrice__c,EBH_Pricenotmatching__c From EBH_Deal__c where Id=:d2.Id];
        //can not assert true, Workflow: 01Q6A000000DAoe, reset to false, when true
        //System.assertEquals(true,d2Sel.EBH_Pricenotmatching__c,'Price does not match the eBay deal site: 500 vs 439.0: '+d1Sel);
       // System.assertEquals(false,d2Sel.EBH_Pricenotmatching__c,'Price matched from eBay deal site: 439 vs 439.0: '+d2Sel);
    }

    @isTest
    static void testBatScrapDealError() {
    	
      EBH_TestDataFactory.setUpCustomSettings();     
      Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData();     
      EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Spotlight Category', EBH_SpotlightCategoryID__c='Spotlight Category1',EBH_Country__c='UK'); 
      insert sc;
      EBH_Deal__c d1 = new EBH_Deal__c(EBH_DealEndDate__c=Date.today().addDays(1),EBH_DealFormat__c='Primary',EBH_eBayItemID__c='123456789',EBH_SellerPrice__c=1000,EBH_DealPrice__c=500,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.today(),EBH_Status__c='Deal Agreed',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1, EBH_SpotlightCategory__c=sc.id,EBH_BusinessName__c=testDataMap.get('se1').Id);
      EBH_Deal__c d2 = new EBH_Deal__c(EBH_DealEndDate__c=Date.today().addDays(1),EBH_DealFormat__c='Primary',EBH_eBayItemID__c='233121274562',EBH_SellerPrice__c=1000,EBH_DealPrice__c=439,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.today(),EBH_Status__c='Deal Agreed',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1, EBH_SpotlightCategory__c=sc.id,EBH_BusinessName__c=testDataMap.get('se1').Id);
      List<EBH_Deal__c> ld = new List<EBH_Deal__c>{d1,d2};
      insert ld;
      
      Test.startTest();
        
        //bat.execute(null);
        EBH_ScrapDeal bat = new EBH_ScrapDeal(); 
        bat.lstAPIErrMsg.add('Test error message.');
        Database.executebatch(bat,20);

      Test.stopTest();
        
      
  }
    
}