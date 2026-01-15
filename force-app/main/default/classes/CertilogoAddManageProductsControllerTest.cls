@isTest
private class CertilogoAddManageProductsControllerTest {

    private static Map<String, Id> setupTestData() {
        // Test data setup
        RecordType recordTypeCertilogo = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Certilogo' LIMIT 1];
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), //Set a valid close date
            Amount = 10000.00,
            RecordTypeId = recordTypeCertilogo.Id
        );
        insert testOpportunity;
 
        // Add test products
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        // Create a standard pricebook entry
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPricebookEntry;

        // Create a custom pricebook entry
        RecordType pricebookRecordTypeCertilogo = [SELECT Id FROM RecordType WHERE SObjectType = 'Pricebook2' AND DeveloperName = 'Certilogo' LIMIT 1];
        Pricebook2 customPricebook = new Pricebook2(
            Name = 'Custom Pricebook',
            IsActive = true,
            RecordTypeId = pricebookRecordTypeCertilogo.Id
        );
        insert customPricebook;

        PricebookEntry customPricebookEntry = new PricebookEntry(
            Pricebook2Id = customPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert customPricebookEntry;

        OpportunityLineItem testLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = customPricebookEntry.Id,
            Quantity = 1,
            TotalPrice = 100
        );
        insert testLineItem;

        // Return the IDs of the created records
        return new Map<String, Id>{
            'OpportunityId' => testOpportunity.Id,
            'ProductId' => testProduct.Id,
            'StandardPricebookEntryId' => standardPricebookEntry.Id,
            'CustomPricebookEntryId' => customPricebookEntry.Id,
            'OpportunityLineItemId' => testLineItem.Id
        };
    }

    @isTest
    private static void testOpportunityHasLineItems() {
        // Set up test data
        Map<String, Id> testData = setupTestData();

        // Perform the test
        Test.startTest();

        // Call the method to be tested
        Boolean result = CertilogoAddManageProductsController.opportunityHasLineItems(testData.get('OpportunityId'));
        CertilogoAddManageProductsController.getOpptyDetails(testData.get('OpportunityId'));

        // Stop the test
        Test.stopTest();

        // Assert the result
        System.assert(result, 'The opportunity should have line items.');
    }

    @isTest
    private static void testGetPriceBooks() {
        // Set up test data
        Map<String, Id> testData = setupTestData();

        // Perform the test
        Test.startTest();

        // Call the method to be tested
        Map<String,Object>  pricebooks = CertilogoAddManageProductsController.getPriceBooks(testData.get('OpportunityId'));

        // Stop the test
        Test.stopTest();

        // Assert the result
        System.assert(pricebooks.size() > 0, 'Pricebook2 records not found');
    }

    @isTest
    private static void testUpdateOpportunityPricebookSuccess() {
        // Set up test data
        Map<String, Id> testData = setupTestData();

        // Perform the test
        Test.startTest();

        // Call the method to test
        OpportunityLineItemTriggerHandler.isDeleteViaProductConfiguration = true;
        Map<String, Object> result = CertilogoAddManageProductsController.updateOpportunityPricebook(testData.get('OpportunityId'), testData.get('CustomPricebookId'));
        CertilogoAddManageProductsController.getlistofProducts(testData.get('OpportunityId'));
        // Assert the result
        System.assertEquals('success', result.get('status'), 'Expected success status');

        // Assert that the opportunity's pricebook has been updated
        Sobject[] oppList = ApexSafe.query().doQuery('SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = \'' + testData.get('OpportunityId') + '\' LIMIT 1');
        if (!oppList.isEmpty()) {
            Opportunity opp = (Opportunity)oppList[0];
            System.assertEquals(testData.get('CustomPricebookId'), opp.Pricebook2Id, 'Expected updated Pricebook2Id');
        }

        // Stop the test
        Test.stopTest();
    }
}