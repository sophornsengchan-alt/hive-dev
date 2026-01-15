/*********************************************************************************************************************************
@ Class:          UploadCoInvestControllerTest
@ Version:        1.0
@ Author:         Mony Nou
@ Purpose:        US-0033626 - Test class for UploadCoInvestController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  11.12.2025 / Mony Nou / Created the class.
*********************************************************************************************************************************/
@isTest
private class UploadCoInvestControllerTest {
    
    /*********************************************************************************************************************************
    @ Method:         setup
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Create test data for all test methods
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @testSetup 
    private static void setup() {
        // Create RecordType for Coupon Co-invest Exclusions
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        RecordType programCouponRecordType = ApexUtil.getRecordTypeByName('Coupon__c', 'Program_Coupon');
        RecordType programCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c', 'Program_Coupon_Seller');
        
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Seller Account',
            RecordTypeId = sellerRecordType.Id,
            EBH_RegistrationCountry__c = '0',
            EBH_RevRollup__c = 'US',
            SP_Coupons__c = 'Full Access',
            EBH_BillingAddress__c = '123 Test St',
            EBH_BillingCity__c = 'Test City',
            EBH_BillingCountry__c = 'US',
            EBH_CompanyName__c = 'Test Company',
            EBH_BillingPostalCode__c = '12345'
        );
        insert testAccount;
        
        // Create test coupon
        Coupon__c testCoupon = new Coupon__c(
            RecordTypeId = programCouponRecordType.Id,
            Main_Coupon_Site__c = 'ebay.com',
            Coupon_Co_invest_Type__c = 'Contra',
            Coupon_ID__c = 'TESTCOUPON001'
        );
        insert testCoupon;
        
        // Create test coupon seller
        Coupon_Seller__c testCouponSeller = new Coupon_Seller__c(
            Coupon__c = testCoupon.Id,
            Seller__c = testAccount.Id,
            RecordTypeId = programCouponSellerRecordType.Id
        );
        insert testCouponSeller;
    }
    
    /*********************************************************************************************************************************
    @ Method:         testImportExcCoInvestPreDMLWithValidData
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Test importExcCoInvestPreDML with valid data
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testImportExcCoInvestPreDMLWithValidData() {
        // Retrieve test data
        Coupon_Seller__c testCouponSeller = [SELECT Id FROM Coupon_Seller__c LIMIT 1];
        
        // Prepare test records
        List<Map<String, String>> testRecords = new List<Map<String, String>>();
        for (Integer i = 0; i < 10; i++) {
            Map<String, String> record = new Map<String, String>();
            record.put('Name', 'Test Co-Invest ' + i);
            record.put('item_id__c', '12345678' + i);
            record.put('item_title__c', 'Test Item Title ' + i);
            testRecords.add(record);
        }
        
        // Prepare arguments
        Map<String, Object> args = new Map<String, Object>();
        args.put('listRecord', testRecords);
        args.put('startIndex', 0);
        args.put('parentId', testCouponSeller.Id);
        args.put('hasHeader', true);
        args.put('isExcelImporterV2', true);
        
        Test.startTest();
        UploadCoInvestController controller = new UploadCoInvestController();
        Map<String, Object> result = controller.importExcCoInvestPreDML(args);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('ok', result.get('status'), 'Status should be ok for valid data');
        List<Map<String, String>> resultRecords = (List<Map<String, String>>) result.get('listRecord');
        System.assertEquals(10, resultRecords.size(), 'Should return 10 records');
        
        // Verify Coupon_Seller__c is prepopulated
        for (Map<String, String> record : resultRecords) {
            System.assertEquals(testCouponSeller.Id, record.get('Coupon_Seller__c'), 'Coupon_Seller__c should be prepopulated');
            System.assertNotEquals(null, record.get('RecordTypeId'), 'RecordTypeId should be assigned');
        }
        
        // Verify no errors
        Map<Integer, String> errorMap = (Map<Integer, String>) result.get('mapIndexToErrMsg');
        System.assertEquals(0, errorMap.size(), 'Should have no errors for valid data');
    }
    
    
    /*********************************************************************************************************************************
    @ Method:         testImportExcCoInvestPreDMLWithHeader
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Test importExcCoInvestPreDML with header row adjustment
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testImportExcCoInvestPreDMLWithHeader() {
        // Retrieve test data
        Coupon_Seller__c testCouponSeller = [SELECT Id FROM Coupon_Seller__c LIMIT 1];
        
        // Prepare test records
        List<Map<String, String>> testRecords = new List<Map<String, String>>();
        Map<String, String> record = new Map<String, String>();
        record.put('Name', 'Test Co-Invest');
        record.put('item_id__c', '123456789');
        record.put('item_title__c', 'Test Item Title');
        testRecords.add(record);
        
        // Prepare arguments with header
        Map<String, Object> args = new Map<String, Object>();
        args.put('listRecord', testRecords);
        args.put('startIndex', 0);
        args.put('parentId', testCouponSeller.Id);
        args.put('hasHeader', true);
        args.put('isExcelImporterV2', true);
        
        Test.startTest();
        UploadCoInvestController controller = new UploadCoInvestController();
        Map<String, Object> result = controller.importExcCoInvestPreDML(args);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('ok', result.get('status'), 'Status should be ok');
        List<Map<String, String>> resultRecords = (List<Map<String, String>>) result.get('listRecord');
        System.assertEquals(1, resultRecords.size(), 'Should return 1 record');
        
        // Verify fields are prepopulated
        System.assertEquals(testCouponSeller.Id, resultRecords[0].get('Coupon_Seller__c'), 'Coupon_Seller__c should be prepopulated');
        System.assertNotEquals(null, resultRecords[0].get('RecordTypeId'), 'RecordTypeId should be assigned');
    }
    
    /*********************************************************************************************************************************
    @ Method:         testImportExcCoInvestPreDMLWithoutHeader
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Test importExcCoInvestPreDML without header row
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testImportExcCoInvestPreDMLWithoutHeader() {
        // Retrieve test data
        Coupon_Seller__c testCouponSeller = [SELECT Id FROM Coupon_Seller__c LIMIT 1];
        
        // Prepare test records
        List<Map<String, String>> testRecords = new List<Map<String, String>>();
        Map<String, String> record = new Map<String, String>();
        record.put('Name', 'Test Co-Invest');
        record.put('item_id__c', '987654321');
        record.put('item_title__c', 'Test Item');
        testRecords.add(record);
        
        // Prepare arguments without header
        Map<String, Object> args = new Map<String, Object>();
        args.put('listRecord', testRecords);
        args.put('startIndex', 5);
        args.put('parentId', testCouponSeller.Id);
        args.put('hasHeader', false);
        args.put('isExcelImporterV2', false);
        
        Test.startTest();
        UploadCoInvestController controller = new UploadCoInvestController();
        Map<String, Object> result = controller.importExcCoInvestPreDML(args);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('ok', result.get('status'), 'Status should be ok');
        List<Map<String, String>> resultRecords = (List<Map<String, String>>) result.get('listRecord');
        System.assertEquals(1, resultRecords.size(), 'Should return 1 record');
    }
    
    /*********************************************************************************************************************************
    @ Method:         testCallMethodWithImportAction
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Test call() method with importExcCoInvestPreDML action
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testCallMethodWithImportAction() {
        // Retrieve test data
        Coupon_Seller__c testCouponSeller = [SELECT Id FROM Coupon_Seller__c LIMIT 1];
        
        // Prepare test records
        List<Map<String, String>> testRecords = new List<Map<String, String>>();
        Map<String, String> record = new Map<String, String>();
        record.put('Name', 'Test Co-Invest');
        record.put('item_id__c', '111222333');
        record.put('item_title__c', 'Callable Test Item');
        testRecords.add(record);
        
        // Prepare arguments
        Map<String, Object> args = new Map<String, Object>();
        args.put('listRecord', testRecords);
        args.put('startIndex', 0);
        args.put('parentId', testCouponSeller.Id);
        args.put('hasHeader', true);
        args.put('isExcelImporterV2', true);
        
        Test.startTest();
        UploadCoInvestController controller = new UploadCoInvestController();
        Object result = controller.call('importExcCoInvestPreDML', args);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>) result;
        System.assertEquals('ok', resultMap.get('status'), 'Status should be ok');
    }
    
    /*********************************************************************************************************************************
    @ Method:         testCallMethodWithInvalidAction
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Test call() method with invalid action - negative test case
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testCallMethodWithInvalidAction() {
        // Prepare arguments
        Map<String, Object> args = new Map<String, Object>();
        
        Test.startTest();
        UploadCoInvestController controller = new UploadCoInvestController();
        Boolean exceptionThrown = false;
        try {
            controller.call('invalidAction', args);
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Method not implemented'), 'Exception message should mention method not implemented');
        }
        Test.stopTest();
        
        // Assertions
        System.assert(exceptionThrown, 'Exception should be thrown for invalid action');
    }
    
    /*********************************************************************************************************************************
    @ Method:         testBulkRecordProcessing
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Test bulk processing with 200+ records to verify bulkification
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testBulkRecordProcessing() {
        // Retrieve test data
        Coupon_Seller__c testCouponSeller = [SELECT Id FROM Coupon_Seller__c LIMIT 1];
        
        // Prepare 250 test records for bulk testing
        List<Map<String, String>> testRecords = new List<Map<String, String>>();
        for (Integer i = 0; i < 250; i++) {
            Map<String, String> record = new Map<String, String>();
            record.put('Name', 'Bulk Test Co-Invest ' + i);
            record.put('item_id__c', '99999' + i);
            record.put('item_title__c', 'Bulk Item ' + i);
            testRecords.add(record);
        }
        
        // Prepare arguments
        Map<String, Object> args = new Map<String, Object>();
        args.put('listRecord', testRecords);
        args.put('startIndex', 0);
        args.put('parentId', testCouponSeller.Id);
        args.put('hasHeader', true);
        args.put('isExcelImporterV2', true);
        
        Test.startTest();
        UploadCoInvestController controller = new UploadCoInvestController();
        Map<String, Object> result = controller.importExcCoInvestPreDML(args);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('ok', result.get('status'), 'Status should be ok for bulk data');
        List<Map<String, String>> resultRecords = (List<Map<String, String>>) result.get('listRecord');
        System.assertEquals(250, resultRecords.size(), 'Should return 250 records');
        
        // Verify all records have required fields prepopulated
        for (Map<String, String> record : resultRecords) {
            System.assertEquals(testCouponSeller.Id, record.get('Coupon_Seller__c'), 'All records should have Coupon_Seller__c prepopulated');
            System.assertNotEquals(null, record.get('RecordTypeId'), 'All records should have RecordTypeId assigned');
        }
    }
    
    /*********************************************************************************************************************************
    @ Method:         testEmptyRecordList
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Test importExcCoInvestPreDML with empty record list - edge case
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testEmptyRecordList() {
        // Retrieve test data
        Coupon_Seller__c testCouponSeller = [SELECT Id FROM Coupon_Seller__c LIMIT 1];
        
        // Prepare empty test records
        List<Map<String, String>> testRecords = new List<Map<String, String>>();
        
        // Prepare arguments
        Map<String, Object> args = new Map<String, Object>();
        args.put('listRecord', testRecords);
        args.put('startIndex', 0);
        args.put('parentId', testCouponSeller.Id);
        args.put('hasHeader', true);
        args.put('isExcelImporterV2', true);
        
        Test.startTest(); 
        UploadCoInvestController controller = new UploadCoInvestController();
        Map<String, Object> result = controller.importExcCoInvestPreDML(args);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('ok', result.get('status'), 'Status should be ok even for empty list');
        List<Map<String, String>> resultRecords = (List<Map<String, String>>) result.get('listRecord');
        System.assertEquals(0, resultRecords.size(), 'Should return 0 records for empty input');
        
        Map<Integer, String> errorMap = (Map<Integer, String>) result.get('mapIndexToErrMsg');
        System.assertEquals(0, errorMap.size(), 'Should have no errors for empty list');
    }
    
    /*********************************************************************************************************************************
    @ Method:         testImportExcCoInvestPreDMLWithBlankItemId
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Test importExcCoInvestPreDML with blank item_id__c - validation error
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testImportExcCoInvestPreDMLWithBlankItemId() {
        // Retrieve test data
        Coupon_Seller__c testCouponSeller = [SELECT Id FROM Coupon_Seller__c LIMIT 1];
        
        // Prepare test records with blank item_id__c
        List<Map<String, String>> testRecords = new List<Map<String, String>>();
        Map<String, String> record1 = new Map<String, String>();
        record1.put('item_id__c', ''); // Blank
        record1.put('item_title__c', 'Test Item Title');
        testRecords.add(record1);
        
        Map<String, String> record2 = new Map<String, String>();
        record2.put('item_id__c', '   '); // Whitespace only
        record2.put('item_title__c', 'Test Item Title 2');
        testRecords.add(record2);
        
        // Prepare arguments
        Map<String, Object> args = new Map<String, Object>();
        args.put('listRecord', testRecords);
        args.put('startIndex', 0);
        args.put('parentId', testCouponSeller.Id);
        args.put('hasHeader', true);
        args.put('isExcelImporterV2', true);
        
        Test.startTest();
        UploadCoInvestController controller = new UploadCoInvestController();
        Map<String, Object> result = controller.importExcCoInvestPreDML(args);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('ok', result.get('status'), 'Status should be ok');
        Map<Integer, String> errorMap = (Map<Integer, String>) result.get('mapIndexToErrMsg');
        System.assertEquals(2, errorMap.size(), 'Should have 2 error messages for blank item_id__c');
        System.assert(errorMap.get(0).contains('eBay Item Id'), 'Error message should mention eBay Item Id');
        System.assert(errorMap.get(0).contains('is Required Field'), 'Error message should mention is Required Field');
        System.assert(errorMap.get(1).contains('eBay Item Id'), 'Second error should also mention eBay Item Id');
    }
    
    /*********************************************************************************************************************************
    @ Method:         testImportExcCoInvestPreDMLWithBlankItemTitle
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Test importExcCoInvestPreDML with blank item_title__c - validation error
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testImportExcCoInvestPreDMLWithBlankItemTitle() {
        // Retrieve test data
        Coupon_Seller__c testCouponSeller = [SELECT Id FROM Coupon_Seller__c LIMIT 1];
        
        // Prepare test records with valid item_id__c but blank item_title__c
        List<Map<String, String>> testRecords = new List<Map<String, String>>();
        Map<String, String> record1 = new Map<String, String>();
        record1.put('item_id__c', '123456789');
        record1.put('item_title__c', ''); // Blank
        testRecords.add(record1);
        
        Map<String, String> record2 = new Map<String, String>();
        record2.put('item_id__c', '987654321');
        record2.put('item_title__c', '   '); // Whitespace only
        testRecords.add(record2);
        
        // Prepare arguments
        Map<String, Object> args = new Map<String, Object>();
        args.put('listRecord', testRecords);
        args.put('startIndex', 0);
        args.put('parentId', testCouponSeller.Id);
        args.put('hasHeader', false);
        args.put('isExcelImporterV2', false);
        
        Test.startTest();
        UploadCoInvestController controller = new UploadCoInvestController();
        Map<String, Object> result = controller.importExcCoInvestPreDML(args);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('ok', result.get('status'), 'Status should be ok');
        Map<Integer, String> errorMap = (Map<Integer, String>) result.get('mapIndexToErrMsg');
        System.assertEquals(2, errorMap.size(), 'Should have 2 error messages for blank item_title__c');
        System.assert(errorMap.get(0).contains('eBay Item Title'), 'Error message should mention eBay Item Title');
        System.assert(errorMap.get(0).contains('is Required Field'), 'Error message should mention is Required Field');
        System.assert(errorMap.get(1).contains('eBay Item Title'), 'Second error should also mention eBay Item Title');
    }
    
    /*********************************************************************************************************************************
    @ Method:         testImportExcCoInvestPreDMLWithValidItemFields
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Test importExcCoInvestPreDML with valid item_id__c and item_title__c
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testImportExcCoInvestPreDMLWithValidItemFields() {
        // Retrieve test data
        Coupon_Seller__c testCouponSeller = [SELECT Id FROM Coupon_Seller__c LIMIT 1];
        
        // Prepare test records with valid item_id__c and item_title__c
        List<Map<String, String>> testRecords = new List<Map<String, String>>();
        for (Integer i = 0; i < 5; i++) {
            Map<String, String> record = new Map<String, String>();
            record.put('item_id__c', '12345678' + i);
            record.put('item_title__c', 'Test Item Title ' + i);
            testRecords.add(record);
        }
        
        // Prepare arguments
        Map<String, Object> args = new Map<String, Object>();
        args.put('listRecord', testRecords);
        args.put('startIndex', 0);
        args.put('parentId', testCouponSeller.Id);
        args.put('hasHeader', true);
        args.put('isExcelImporterV2', true);
        
        Test.startTest();
        UploadCoInvestController controller = new UploadCoInvestController();
        Map<String, Object> result = controller.importExcCoInvestPreDML(args);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('ok', result.get('status'), 'Status should be ok for valid data');
        List<Map<String, String>> resultRecords = (List<Map<String, String>>) result.get('listRecord');
        System.assertEquals(5, resultRecords.size(), 'Should return 5 records');
        
        // Verify all records passed validation and have prepopulated fields
        Map<Integer, String> errorMap = (Map<Integer, String>) result.get('mapIndexToErrMsg');
        System.assertEquals(0, errorMap.size(), 'Should have no errors for valid data');
        
        for (Map<String, String> record : resultRecords) {
            System.assertEquals(testCouponSeller.Id, record.get('Coupon_Seller__c'), 'Coupon_Seller__c should be prepopulated');
            System.assertNotEquals(null, record.get('RecordTypeId'), 'RecordTypeId should be assigned');
        }
    }
    
    /*********************************************************************************************************************************
    @ Method:         testImportExcCoInvestPreDMLMixedValidAndInvalid
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        Test importExcCoInvestPreDML with mix of valid and invalid records
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testImportExcCoInvestPreDMLMixedValidAndInvalid() {
        // Retrieve test data
        Coupon_Seller__c testCouponSeller = [SELECT Id FROM Coupon_Seller__c LIMIT 1];
        
        // Prepare mix of valid and invalid test records
        List<Map<String, String>> testRecords = new List<Map<String, String>>();
        
        // Valid record
        Map<String, String> record1 = new Map<String, String>();
        record1.put('item_id__c', '123456789');
        record1.put('item_title__c', 'Valid Item Title');
        testRecords.add(record1);
        
        // Invalid - blank item_id__c
        Map<String, String> record2 = new Map<String, String>();
        record2.put('item_id__c', '');
        record2.put('item_title__c', 'Some Title');
        testRecords.add(record2);
        
        // Valid record
        Map<String, String> record3 = new Map<String, String>();
        record3.put('item_id__c', '987654321');
        record3.put('item_title__c', 'Another Valid Title');
        testRecords.add(record3);
        
        // Invalid - blank item_title__c
        Map<String, String> record4 = new Map<String, String>();
        record4.put('item_id__c', '111222333');
        record4.put('item_title__c', '');
        testRecords.add(record4);
        
        // Prepare arguments
        Map<String, Object> args = new Map<String, Object>();
        args.put('listRecord', testRecords);
        args.put('startIndex', 10);
        args.put('parentId', testCouponSeller.Id);
        args.put('hasHeader', true);
        args.put('isExcelImporterV2', true);
        
        Test.startTest();
        UploadCoInvestController controller = new UploadCoInvestController();
        Map<String, Object> result = controller.importExcCoInvestPreDML(args);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('ok', result.get('status'), 'Status should be ok');
        Map<Integer, String> errorMap = (Map<Integer, String>) result.get('mapIndexToErrMsg');
        System.assertEquals(2, errorMap.size(), 'Should have 2 error messages');
        System.assert(errorMap.get(11).contains('eBay Item Id'), 'Row 11 should have eBay Item Id error');
        System.assert(errorMap.get(13).contains('eBay Item Title'), 'Row 13 should have eBay Item Title error');
    }
}