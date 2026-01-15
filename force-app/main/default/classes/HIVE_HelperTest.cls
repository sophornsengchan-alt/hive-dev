/*********************************************************************************************************************************
@ Class:          HIVE_HelperTest
@ Author:         Sothea Horn (sohorn@ebay.com)
@ Purpose:        Unit Test of HIVE_Helper class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.12.2024 / Sothea Horn / Created the class.
**********************************************************************************************************************************/
@isTest
private class HIVE_HelperTest {

    private static Map<String, String> setupTestData() {
        // Test data setup
        RecordType recordTypeCertilogo = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Certilogo' LIMIT 1];
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), // Set a valid close date
            Amount = 10000.00,
            RecordTypeId = recordTypeCertilogo.Id
        );
        insert testOpportunity;

        // Add test products
        Product2 testProduct1 = new Product2(Name = 'Test Product1', IsActive = true);
        insert testProduct1;
        Product2 testProduct2 = new Product2(Name = 'Test Product2', IsActive = true);
        insert testProduct2;

        // Create a standard pricebook entry
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPricebookEntry;

        PricebookEntry standardPricebookEntry2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct2.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPricebookEntry2;


        RecordType pricebookRTCertilogo = [SELECT Id FROM RecordType WHERE SObjectType = 'Pricebook2' AND DeveloperName = 'Certilogo' LIMIT 1];
        // Create a custom pricebook entry
        Pricebook2 customActivePricebookNoEntry = new Pricebook2(
            Name = 'Custom Pricebook1',
            IsActive = true,
            RecordTypeId = pricebookRTCertilogo.Id
        );
        insert customActivePricebookNoEntry;

        Pricebook2 customInActivePricebook = new Pricebook2(
            Name = 'Custom Pricebook2',
            IsActive = false,
            RecordTypeId = pricebookRTCertilogo.Id
        );
        insert customInActivePricebook;

        
        Pricebook2 customActivePricebook = new Pricebook2(
            Name = 'Custom Pricebook3',
            IsActive = true,
            RecordTypeId = pricebookRTCertilogo.Id
        );
        insert customActivePricebook;

        List<PricebookEntry> listPBEntries = new List<PricebookEntry>();
        listPBEntries.add(new PricebookEntry(
            Pricebook2Id = customActivePricebook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 100,
            IsActive = true
        ));
        listPBEntries.add(new PricebookEntry(
            Pricebook2Id = customActivePricebook.Id,
            Product2Id = testProduct2.Id,
            UnitPrice = 100,
            IsActive = false
        ));
        insert listPBEntries;

         // Create a standard pricebook entry
         RecordType pricebookRTAdvertising = [SELECT Id FROM RecordType WHERE SObjectType = 'Pricebook2' AND DeveloperName = 'Advertising' LIMIT 1];
         Pricebook2 customAdPricebook = new Pricebook2(
             Name = 'Custom Advertising Pricebook',
             IsActive = true,
             RecordTypeId = pricebookRTAdvertising.Id
         );
         insert customAdPricebook;
         PricebookEntry advertisingPBEntry = new PricebookEntry(
             Pricebook2Id = customAdPricebook.Id,
             Product2Id = testProduct2.Id,
             UnitPrice = 100,
             IsActive = true
         );
         insert advertisingPBEntry;

        // Return the IDs of the created records
        return new Map<String, String>{
            'OpportunityId' => testOpportunity.Id,
            'ProductId' => testProduct1.Id,
            'customActivePricebookName' => customActivePricebook.Name
        };
    }

    @isTest
    static void getPriceBooksTest() {
        // Set up test data
        Map<String, String> testData = setupTestData();

        // Perform the test
        Test.startTest();

        // Call the method to be tested
        List<Pricebook2> pricebooks = HIVE_Helper.getPriceBooks(testData.get('OpportunityId'));

        // Assert the result
        System.assertEquals(pricebooks.size(), 1, 'Return only one Certilogo Pricebook');
        System.assertEquals(pricebooks[0].Name, testData.get('customActivePricebookName'), 'Certilogo Pricebook is Custom Pricebook3');
        System.assertEquals(pricebooks[0].IsActive, true, 'Certilogo Pricebook is active');

         // Stop the test
         Test.stopTest();
    }

    @isTest
    static void getPriceBooksWithSearchTextTest() {
        // Set up test data
        Map<String, String> testData = setupTestData();

        // Perform the test
        Test.startTest();

        String searchText = 'Advertising';
        List<Pricebook2> pricebooks = HIVE_Helper.getPriceBooks(testData.get('OpportunityId'), searchText);

        // Assert the result
        System.assertEquals(pricebooks.size(), 0, 'No Advertising pricebook found for certilogo');

        searchText = 'custom';
        pricebooks = HIVE_Helper.getPriceBooks(testData.get('OpportunityId'), searchText);

        // Assert the result
        System.assertEquals(pricebooks.size(), 1, 'Return only one certilogo pricebook with search text custom');
        System.assertEquals(pricebooks[0].Name, testData.get('customActivePricebookName'), 'Certilogo Pricebook is Custom Pricebook3');
        System.assertEquals(pricebooks[0].IsActive, true, 'Certilogo Pricebook is active');

        // Stop the test
        Test.stopTest();
    }
}