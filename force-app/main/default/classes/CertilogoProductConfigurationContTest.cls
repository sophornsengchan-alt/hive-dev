/*
* Test class for CertilogoProductConfigurationController & CertilogoButtonService
*/
@isTest
private class CertilogoProductConfigurationContTest {
    private static Id oppoProdDocPORTId = ApexUtil.getRecordTypeByName('OpportunityProductDocument__c','PurchaseOrder').Id;
    private static Map<String, Id> setupTestData() {

        //Create User
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		User standardUser;
		System.runAs(admin){
			Profile p = [select id from Profile where name='Certilogo Standard User' limit 1];
            standardUser = new User(alias = 'tsUser', email='TestStardardUser@ebay.com',
                            emailencodingkey='UTF-8', lastname='TestStandardUserCPC', firstname='TestStandardUserCPC', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id,
                            timezonesidkey='America/Los_Angeles', username='TestStardardusercpc@salesforce.cpc.de', isActive = true);
            insert standardUser;

            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Certilogo_Standard_User' LIMIT 1];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = standardUser.Id,
                PermissionSetId = ps.Id
            );
            insert psa;

            byPass__c bp = new byPass__c(SetupOwnerId = standardUser.Id, ByPass_Validation__c=true);
            insert bp;

		}

        Account testAccount;
        Opportunity testOpportunity;
        Product2 testProduct;
        PricebookEntry standardPricebookEntry;
        Pricebook2 customPricebook;
        PricebookEntry customPricebookEntry;
        OpportunityLineItem testLineItem;
        OpportunityProductDocument__c oppoProdDocument;
        OpportunityProductDocumentLine__c oppoProdDocumentLine;
        Id standardPricebookEntryId;
        System.runAs(standardUser){

            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email =  'testcertilogo@test.com'
            );
            insert testContact;
            
            RecordType rtAccountCertilogo = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Certilogo' LIMIT 1];
            testAccount = new Account(
                Name = 'Test Account',
                Country_Code__c = 'US',
                Primary_Contact__c = testContact.Id,
                RecordTypeId = rtAccountCertilogo.Id
            );
            insert testAccount;

            // Test data setup
            RecordType recordTypeCertilogo = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Certilogo' LIMIT 1];
            testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(30), // Set a valid close date
                Amount = 10000.00,
                AccountId = testAccount.Id,
                RecordTypeId = recordTypeCertilogo.Id
            );
            insert testOpportunity;

            // Add test products
            //testProduct = new Product2(Name = 'Test Product', IsActive = true, RequiresManufacture__c = true, Manufacturer__c = testAccount.Id);
            testProduct = new Product2(Name = 'Test Product', IsActive = true, Manufacturer__c = testAccount.Id);
            insert testProduct;

            //Check first if it is already in the standard pricebook
            List<PricebookEntry> pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id =: Test.getStandardPricebookId()];
            if (pbe.isEmpty()) {
                /// Create a standard pricebook entry
                standardPricebookEntry = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = testProduct.Id,
                    UnitPrice = 100,
                    IsActive = true
                );
                insert standardPricebookEntry;
                standardPricebookEntryId = standardPricebookEntry.Id;
            }else {
                standardPricebookEntryId = pbe[0].Id;
            }

            // Create a custom pricebook entry
            customPricebook = new Pricebook2(
                Name = 'Custom Pricebook',
                IsActive = true
            );
            insert customPricebook;

            customPricebookEntry = new PricebookEntry(
                Pricebook2Id = customPricebook.Id,
                Product2Id = testProduct.Id,
                UnitPrice = 100,
                IsActive = true
            );
            insert customPricebookEntry;

            testProduct.RequiresManufacture__c = true;
            Update testProduct;

            testLineItem = new OpportunityLineItem(
                OpportunityId = testOpportunity.Id,
                PricebookEntryId = customPricebookEntry.Id,
                InvoiceStatus__c = 'Draft',
                Quantity = 2,
                TotalPrice = 100
            );
            insert testLineItem;

            OppoProdDocument = new OpportunityProductDocument__c(
                RecordTypeId = oppoProdDocPORTId,
                Status__c = 'Active',
                Opportunity__c = testOpportunity.Id
            );
            insert OppoProdDocument;

            oppoProdDocumentLine = new OpportunityProductDocumentLine__c(
                OpportunityProduct__c = testLineItem.Id,
                OpportunityProductDocument__c = OppoProdDocument.Id
            );
            insert oppoProdDocumentLine;
            
        }

        // Return the IDs of the created records
        return new Map<String, Id>{
            'OpportunityId' => testOpportunity.Id,
            'ProductId' => testProduct.Id,
            'StandardPricebookEntryId' => standardPricebookEntryId,
            'CustomPricebookEntryId' => customPricebookEntry.Id,
            'OpportunityLineItemId' => testLineItem.Id,
            'certilogoUserId' => standardUser.Id,
            'OppoProdDocumentId' => OppoProdDocument.Id,
            'oppoProdDocumentLineId' => oppoProdDocumentLine.Id
        };
        
    }

    @isTest
    private static void testinitData() {
        // Set up test data
        Map<String, Id> testData = setupTestData();
        // Insert a ContentVersion to create a ContentDocument
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test content for our document'),
            IsMajorVersion = true
        );
        insert contentVersion;

        // Query the ContentDocumentId from the inserted ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;

        // Prepare the ContentDocumentLink record
        ContentDocumentLink contentDocLink = new ContentDocumentLink(
            LinkedEntityId = testData.get('OppoProdDocumentId'),
            ContentDocumentId = contentDocumentId,
            ShareType = 'V',  // V for View access, C for Collaborator, I for Inferred permission
            Visibility = 'AllUsers'
        );

        // Insert the ContentDocumentLink
        insert contentDocLink;

        // Perform the test
        Test.startTest();

        System.runAs(new User(Id = testData.get('certilogoUserId'))) {
            
            // Call the method to be tested
            Map<String,Object>  result = CertilogoProductConfigurationController.initData(
                testData.get('OpportunityId'),
                testData.get('CustomPricebookEntryId'),
                new List<String>{testData.get('CustomPricebookEntryId')}
            );

            // Assert the result
            System.assert(result.get('status') == 'success', 'The Production Configuration Initialized should be sucessful.');

        }

        // Stop the test
        Test.stopTest();
        
    }

    @isTest
    private static void testsaveRecordsSuccess() {
        // Set up test data
        Map<String, Id> testData = setupTestData();

        // Perform the test
        Test.startTest();

        OpportunityLineItem oli = new OpportunityLineItem (
            Id = testData.get('OpportunityLineItemId'),
            OpportunityId = testData.get('OpportunityId'), 
            PricebookEntryId = testData.get('CustomPricebookEntryId'), 
            Quantity=2,
            UnitPrice=450
        );
        

        // Call the method to be tested
        Map<String,Object> result = CertilogoProductConfigurationController.saveRecords(
            new List<OpportunityLineItem>{oli}
        );
        
        // Stop the test
        Test.stopTest();

        // Assert the result
            System.assert(result.get('status') == 'success', 'The Opportuinty Line Item should update sucessfully.');
        
    }

    @isTest
    private static void testsaveRecordsError() {
        // Set up test data
        Map<String, Id> testData = setupTestData();

        // Perform the test
        Test.startTest();

        OpportunityLineItem oli = new OpportunityLineItem (
            Id = testData.get('OpportunityLineItemId'),
            OpportunityId = testData.get('OpportunityId'), 
            PricebookEntryId = testData.get('CustomPricebookEntryId'), 
            Quantity=2,
            UnitPrice=450,
            TotalPrice = 900);
            

        // Call the method to be tested
        Map<String,Object> result = CertilogoProductConfigurationController.saveRecords(
            new List<OpportunityLineItem>{oli}
        );
        
        // Stop the test
        Test.stopTest();

        // Assert the result
        System.assert(result.get('status') == 'error', 'The Opportuinty Line Item should have error while updating.');
    }

    @isTest
    private static void testvalidateProducts() {
        // Set up test data
        Map<String, Id> testData = setupTestData();
        
        // Perform the test
        Test.startTest();

        System.runAs(new User(Id = testData.get('certilogoUserId'))) {
            
            // Call the method to be tested
            Map<String,Object>  result = CertilogoProductConfigurationController.initData(
                testData.get('OpportunityId'),
                testData.get('CustomPricebookEntryId'),
                new List<String>{testData.get('CustomPricebookEntryId')}
            );

            // Assert the result
            System.assert(result.get('status') == 'success', 'The Production Configuration Initialized should be sucessful.');
            
            
            List<String> oppLineIds = new List<String>{testData.get('OpportunityLineItemId')}; 
            Map<String, List<CertilogoButtonConfiguration__mdt>> mButtonValidation = (Map<String, List<CertilogoButtonConfiguration__mdt>>) result.get('buttonValidation');

            for (CertilogoButtonConfiguration__mdt metadata : CertilogoButtonConfiguration__mdt.getAll().values()) {
                if (metadata.Active__c && metadata.Top_Button__c) {
                    
                    if (mButtonValidation.containsKey(metadata.MasterLabel)) {
                        String buttonName = metadata.DeveloperName;
                        List<CertilogoButtonConfiguration__mdt> validations = mButtonValidation.get(metadata.MasterLabel);

                        result = CertilogoProductConfigurationController.validateProducts(testData.get('OpportunityId'), oppLineIds, buttonName, validations);
                    }
                    
                }
            }

            String buttonName = 'DeleteButton';
            List<CertilogoButtonConfiguration__mdt> validations = mButtonValidation.get('Delete');
            result = CertilogoProductConfigurationController.validateProducts(testData.get('OpportunityId'), oppLineIds, buttonName, validations);
            

        }
        
        
        // Stop the test
        Test.stopTest();
    }

    @isTest
    private static void testgetFieldSetFields() {

        // Perform the test
        Test.startTest();

            List<String> result = CertilogoProductConfigurationController.getFieldSetFields('OpportunityProductDocument__c', 'CertilogoProdConfig_GeneratePO');
            
            System.assert(result.size() > 0, 'The field set should have fields.');

        // Stop the test
        Test.stopTest();

    }

    @isTest
    private static void testSubmitButton() {

        // Set up test data
        Map<String, Id> testData = setupTestData();

        // Perform the test
        Test.startTest();

        System.runAs(new User(Id = testData.get('certilogoUserId'))) {
            
            // Call the method to be tested
            Map<String,Object>  result = CertilogoProductConfigurationController.initData(
                testData.get('OpportunityId'),
                testData.get('CustomPricebookEntryId'),
                new List<String>{testData.get('CustomPricebookEntryId')}
            );

            // Assert the result
            System.assert(result.get('status') == 'success', 'The Production Configuration Initialized should be sucessful.'+result.get('error'));
            
            
            List<String> oppLineIds = new List<String>{testData.get('OpportunityLineItemId')}; 
            Map<String, List<CertilogoButtonConfiguration__mdt>> mButtonValidation = (Map<String, List<CertilogoButtonConfiguration__mdt>>) result.get('buttonValidation');

            for (CertilogoButtonConfiguration__mdt metadata : CertilogoButtonConfiguration__mdt.getAll().values()) {
                if (metadata.Active__c && metadata.Top_Button__c) {
                    
                    String buttonName = metadata.DeveloperName;
                    result = CertilogoProductConfigurationController.submitProducts(oppLineIds, buttonName, new OpportunityProductDocument__c(Note__c = 'Test'), new Map<String, Object>{'test' => 'test'});
                    System.assert(result.get('status') == 'success', 'Submit Action for button ' + metadata.MasterLabel + ' should be sucessful.');
                    
                }
            }

            String buttonName = 'DeleteButton';
            result = CertilogoProductConfigurationController.submitProducts(oppLineIds, buttonName, new OpportunityProductDocument__c(Note__c = 'Test'), new Map<String, Object>{'test' => 'test'});
            System.assert(result.get('status') == 'success', 'Submit Action for Delete button should be sucessful.');

            String buttonName1 = 'SplitLineButton';
            result = CertilogoProductConfigurationController.submitProducts(oppLineIds, buttonName1, new OpportunityProductDocument__c(Note__c = 'Test'), new Map<String, Object>{'splitqty' => 1});
            System.assert(result.get('status') == 'success', 'Submit Action for Delete button should be sucessful.');
            
        }

        // Stop the test
        Test.stopTest();

    }
    @isTest
    private static void testmergedocument() {
        // Set up test data
        Map<String, Id> testData = setupTestData();
		Id oppproddoc = testData.get('OppoProdDocumentId');
        
        // Perform the test
        Test.startTest();
        MockHttpMD mdMock = new MockHttpMD();
        Test.setMock(HttpCalloutMock.class, mdMock);
        CertilogoProductConfigurationController.mergeDocument(oppproddoc,'PurchaseOrder'); 
       // Stop the test
        Test.stopTest();
        
    }

 public class MockHttpMD implements HttpCalloutMock {
    // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            system.debug('>>mock endpoint: '+req.getEndpoint());
            if(req.getEndpoint().startsWith('https://composer.congamerge.com/composer8/index.html'))
            {
                res.setBody('068VE000004DP4lYAG');
            }
            res.setStatusCode(200);
            return res;
        }
	}
}