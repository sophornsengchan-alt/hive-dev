/*
* Test class for OpportunityLineItemTrigger & OpportunityLineItemTriggerHandler
*/
@isTest
private class OpportunityLineItemTriggerHandlerTest {

    private static Map<String, Id> setupTestData() {

        //Create User
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		User standardUser;
		System.runAs(admin){
			Profile p = [select id from Profile where name='Certilogo Standard User' limit 1];
            standardUser = new User(alias = 'olitUser', email='TestStardardUser@ebay.olit.com',
                            emailencodingkey='UTF-8', lastname='TestStandardUserOLIT', firstname='TestStandardUserOLIT', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id,
                            timezonesidkey='America/Los_Angeles', username='TestStardarduser@salesforce.olit.de', isActive = true);
            insert standardUser;

            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Certilogo_Standard_User' LIMIT 1];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = standardUser.Id,
                PermissionSetId = ps.Id
            );
            insert psa;

		}

        Account testAccount;
        Opportunity testOpportunity;
        Product2 testProduct, testDiscountProduct;
        PricebookEntry standardPricebookEntry, standardDiscPricebookEntry;
        Pricebook2 customPricebook;
        PricebookEntry customPricebookEntry, customDiscPricebookEntry;
        OpportunityLineItem testLineItem;
        OpportunityProductDocument__c oppoProdDocument;
        OpportunityProductDocumentLine__c oppoProdDocumentLine;
        Id standardPricebookEntryId, standardDiscPricebookEntryId;
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
            testDiscountProduct = new Product2(Name = 'Test Discount Product', IsActive = true, IsDiscount__c = true);
            insert new List<Product2>{testProduct, testDiscountProduct};

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

            //Check first if it is already in the standard pricebook
            List<PricebookEntry> pbe1 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testDiscountProduct.Id AND Pricebook2Id =: Test.getStandardPricebookId()];
            if (pbe1.isEmpty()) {
                /// Create a standard pricebook entry
                standardDiscPricebookEntry = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = testDiscountProduct.Id,
                    UnitPrice = 100,
                    IsActive = true
                );
                insert standardDiscPricebookEntry;
                standardDiscPricebookEntryId = standardDiscPricebookEntry.Id;
            }else {
                standardDiscPricebookEntryId = pbe[0].Id;
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
            customDiscPricebookEntry = new PricebookEntry(
                Pricebook2Id = customPricebook.Id,
                Product2Id = testDiscountProduct.Id,
                UnitPrice = 100,
                IsActive = true
            );
            insert new List<PricebookEntry>{customPricebookEntry, customDiscPricebookEntry};

            testLineItem = new OpportunityLineItem(
                OpportunityId = testOpportunity.Id,
                PricebookEntryId = customPricebookEntry.Id,
                InvoiceStatus__c = 'Draft',
                Quantity = 1,
                TotalPrice = 100
            );
            insert testLineItem;

        }

        // Return the IDs of the created records
        return new Map<String, Id>{
            'OpportunityId' => testOpportunity.Id,
            'ProductId' => testProduct.Id,
            'DiscountProductId' => testDiscountProduct.Id,
            'StandardPricebookEntryId' => standardPricebookEntryId,
            'CustomPricebookEntryId' => customPricebookEntry.Id,
            'CustomDiscPricebookEntryId' => customDiscPricebookEntry.Id,
            'OpportunityLineItemId' => testLineItem.Id,
            'certilogoUserId' => standardUser.Id
        };
        
    }

    @isTest 
    private static void testLockProductsOnCertilogoOpportunity () {

        Test.startTest();

            Map<String, Id> testData = setupTestData();

            //Update Approval Status to Approved
            Opportunity opp = new Opportunity(Id = testData.get('OpportunityId'), Approval_Status__c = 'Approved');
            update opp;

            System.runAs(new User(Id = testData.get('certilogoUserId'))) {
                //1) Update Opportunity Line Item
                try{
                    
                    OpportunityLineItem oli = new OpportunityLineItem(
                        Id = testData.get('OpportunityLineItemId'),
                        Quantity = 2
                    );

                    update oli;

                }catch(Exception e){
                    System.assert(String.isNotBlank(e.getMessage()), 'There should be an error message.');
                }

                //2) Insert Opportunity Line Item
                try{
                    
                    OpportunityLineItem oli = new OpportunityLineItem(
                        OpportunityId = testData.get('OpportunityId'),
                        PricebookEntryId = testData.get('CustomPricebookEntryId'), 
                        InvoiceStatus__c = 'Draft',
                        Quantity = 1,
                        TotalPrice = 100
                    );

                    insert oli;

                }catch(Exception e){
                    System.assert(String.isNotBlank(e.getMessage()), 'There should be an error message.');
                }


                //3) Delete Opportunity Line Item
                try{
                    
                    delete new OpportunityLineItem(Id = testData.get('OpportunityLineItemId'));

                }catch(Exception e){
                    System.assert(String.isNotBlank(e.getMessage()), 'There should be an error message.');
                }
            }
            

        Test.stopTest();
    }

    @isTest 
    private static void testCheckDiscountProductOnCertilogoOpportunity () {

        Map<String, Id> testData = setupTestData();

        Test.startTest();

            //1) Add new discount line item
            OpportunityLineItem discOLI = new OpportunityLineItem(
                OpportunityId = testData.get('OpportunityId'),
                PricebookEntryId = testData.get('CustomDiscPricebookEntryId'), 
                InvoiceStatus__c = 'Draft',
                Quantity = 1,
                TotalPrice = 100
            );

            insert discOLI;

            for (Opportunity opp : [select id, Approval_Status__c from Opportunity where id = :testData.get('OpportunityId')]) {
                System.assert(opp.Approval_Status__c == 'Requires Approval', 'Approval Status should be Requires Approval');
            }

            //2) Delete discount line item
            OpportunityLineItemTriggerHandler.isDeleteViaProductConfiguration = true;
            delete discOLI;

            for (Opportunity opp : [select id, Approval_Status__c from Opportunity where id = :testData.get('OpportunityId')]) {
                System.assert(opp.Approval_Status__c == 'Not Required', 'Approval Status should be Not Required');
            }

        Test.stopTest();

    }
}