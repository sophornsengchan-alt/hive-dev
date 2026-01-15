@isTest
public class ProductTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        EBH_TestDataFactory.setUpCustomSettings();  
        EBH_ActiveTriggers__c csettingTrigger = EBH_ActiveTriggers__c.getInstance(CaseTriggerHandler.TRIGGERCONTROLLER);
        csettingTrigger.Product__c = true;
        update csettingTrigger;
    }

    @isTest
    static void testCreateStandardPrice() {
        // Get the record type ID for 'Certilogo'
        Id certilogoRecordTypeId = ApexUtil.getRecordTypeByName('Product2', 'Certilogo').Id;

        // Create test products
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Test Product 1', RecordTypeId = certilogoRecordTypeId),
            new Product2(Name = 'Test Product 2', RecordTypeId = certilogoRecordTypeId)
        };
        insert products;
        
        // Verify the results
        List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, Pricebook2Id, UnitPrice, CurrencyIsoCode FROM PricebookEntry WHERE Product2Id IN :products];
        System.assertEquals(products.size() * [SELECT COUNT() FROM CurrencyType WHERE IsActive = true], pricebookEntries.size(), 'Expected pricebook entries for each product and currency');
        for (PricebookEntry pbe : pricebookEntries) {
            System.assertEquals(0, pbe.UnitPrice, 'Expected unit price to be 0');
        }
    }
}