/*********************************************************************************************************************************
@ Class:          FeeTypeTriggerHandlerTest
@ Version:        1.0
@ Author:         GitHub Copilot 
@ Purpose:        Test class for FeeTypeTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.12.2025 / GitHub Copilot / Created the test class for FeeType timezone offset functionality
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class FeeTypeTriggerHandlerTest {
    
    @testSetup 
    static void setup(){
        EBH_TestDataFactory.setUpCustomSettings();
    }
    
    /*****************************************************************************************************************************
    @ Method:         testPopulateTimezoneOffsetsOnInsert
    @ Version:        1.0
    @ Author:         GitHub Copilot
    @ Purpose:        Test timezone offset population on FeeType insert using Contract dates
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2025 / GitHub Copilot / Created the test Method.
    *****************************************************************************************************************************/
    @isTest
    static void testPopulateTimezoneOffsetsOnInsert() {
        // Create test data
        User testUser = EBH_TestDataFactory.createUser('System Administrator');
        System.runAs(testUser) {
            // Create Account
            RecordType legalEntity = ApexUtil.getRecordTypeByName('Account', 'EBH_LegalEntity');
            Account testAccount = new Account(
                Name = 'Test Legal Entity',
                RecordTypeId = legalEntity.Id,
                EBH_BillingCountry__c = 'US'
            );
            insert testAccount;
            
            // Create Contact
            RecordType contactRT = ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL');
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test@test.com',
                AccountId = testAccount.Id,
                RecordTypeId = contactRT.Id
            );
            insert testContact;
            
            // Create Contract with specific dates
            RecordType contractRT = ApexUtil.getRecordTypeByName('Contract', 'EBH_ListingAgreement');
            Contract testContract = new Contract(
                Name = 'Test Contract',
                AccountId = testAccount.Id,
                Status = 'Draft',
                RecordTypeId = contractRT.Id,
                StartDate = Date.newInstance(2025, 6, 15), // June 15, 2025
                EndDate = Date.newInstance(2025, 12, 31), // December 31, 2025
                EBH_Site__c = 'US',
                CompanySignedId = testUser.Id,
                CompanySignedDate = System.today(),
                CustomerSignedDate = System.today(),
                Business_Contact__c = testContact.Id
            );
            insert testContract;
            
            // Create FeeType record
            RecordType feeTypeRT = ApexUtil.getRecordTypeByName('FeeType__c', 'Primary');
            
            Test.startTest();
            FeeType__c testFeeType = new FeeType__c(
                RecordTypeId = feeTypeRT.Id,
                PrimarySite__c = 'US',
                RelatedContract__c = testContract.Id,
                TypeofFee__c = 'EBAY_TOP_RATED_SELLER_DISCOUNT'
            );
            insert testFeeType;
            Test.stopTest();
            
            // Verify timezone offsets were populated
            FeeType__c insertedFeeType = [SELECT Id, StartDateOffset__c, EndDateOffset__c, PrimarySite__c FROM FeeType__c WHERE Id = :testFeeType.Id];
            
            System.assertNotEquals(null, insertedFeeType.StartDateOffset__c, 'Start Date Offset should be populated on insert');
            System.assertNotEquals(null, insertedFeeType.EndDateOffset__c, 'End Date Offset should be populated on insert');
            
            // Verify the offset values match expected timezone calculation for US
            // US timezone offset should be calculated using Contract StartDate/EndDate and US site
            Decimal expectedStartOffset = ApexUtil.getDateTimezoneOffsetForSite(testContract.StartDate, 'US');
            Decimal expectedEndOffset = ApexUtil.getDateTimezoneOffsetForSite(testContract.EndDate, 'US');
            
            System.assertEquals(expectedStartOffset, insertedFeeType.StartDateOffset__c, 'Start Date Offset should match expected US timezone offset');
            System.assertEquals(expectedEndOffset, insertedFeeType.EndDateOffset__c, 'End Date Offset should match expected US timezone offset');
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testPopulateTimezoneOffsetsOnUpdate
    @ Version:        1.0
    @ Author:         GitHub Copilot
    @ Purpose:        Test timezone offset population on FeeType site change
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2025 / GitHub Copilot / Created the test Method.
    *****************************************************************************************************************************/
    @isTest
    static void testPopulateTimezoneOffsetsOnUpdate() {
        // Create test data
        User testUser = EBH_TestDataFactory.createUser('System Administrator');
        System.runAs(testUser) {
            // Create Account
            RecordType legalEntity = ApexUtil.getRecordTypeByName('Account', 'EBH_LegalEntity');
            Account testAccount = new Account(
                Name = 'Test Legal Entity',
                RecordTypeId = legalEntity.Id,
                EBH_BillingCountry__c = 'DE'
            );
            insert testAccount;
            
            // Create Contact
            RecordType contactRT = ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL');
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test@test.com',
                AccountId = testAccount.Id,
                RecordTypeId = contactRT.Id
            );
            insert testContact;
            
            // Create Contract
            RecordType contractRT = ApexUtil.getRecordTypeByName('Contract', 'EBH_ListingAgreement');
            Contract testContract = new Contract(
                Name = 'Test Contract',
                AccountId = testAccount.Id,
                Status = 'Draft',
                RecordTypeId = contractRT.Id,
                StartDate = Date.newInstance(2025, 3, 15), // March 15, 2025 (DST change period)
                EndDate = Date.newInstance(2025, 10, 31), // October 31, 2025 (DST change period)
                EBH_Site__c = 'DE',
                CompanySignedId = testUser.Id,
                CompanySignedDate = System.today(),
                CustomerSignedDate = System.today(),
                Business_Contact__c = testContact.Id
            );
            insert testContract;
            
            // Create FeeType record with initial site
            RecordType feeTypeRT = ApexUtil.getRecordTypeByName('FeeType__c', 'Primary');
            FeeType__c testFeeType = new FeeType__c(
                RecordTypeId = feeTypeRT.Id,
                PrimarySite__c = 'DE',
                RelatedContract__c = testContract.Id,
                TypeofFee__c = 'EBAY_TOP_RATED_SELLER_DISCOUNT'
            );
            insert testFeeType;
            
            // Get initial offset values
            FeeType__c initialFeeType = [SELECT Id, StartDateOffset__c, EndDateOffset__c, PrimarySite__c FROM FeeType__c WHERE Id = :testFeeType.Id];
            Decimal initialStartOffset = initialFeeType.StartDateOffset__c;
            Decimal initialEndOffset = initialFeeType.EndDateOffset__c;
            
            Test.startTest();
            // Update the PrimarySite to trigger timezone offset recalculation
            testFeeType.PrimarySite__c = 'UK';
            update testFeeType;
            Test.stopTest();
            
            // Verify timezone offsets were updated
            FeeType__c updatedFeeType = [SELECT Id, StartDateOffset__c, EndDateOffset__c, PrimarySite__c FROM FeeType__c WHERE Id = :testFeeType.Id];
            
            System.assertNotEquals(initialStartOffset, updatedFeeType.StartDateOffset__c, 'Start Date Offset should change when site changes');
            System.assertNotEquals(initialEndOffset, updatedFeeType.EndDateOffset__c, 'End Date Offset should change when site changes');
            
            // Verify the new offset values match expected timezone calculation for UK
            Decimal expectedStartOffset = ApexUtil.getDateTimezoneOffsetForSite(testContract.StartDate, 'UK');
            Decimal expectedEndOffset = ApexUtil.getDateTimezoneOffsetForSite(testContract.EndDate, 'UK');
            
            System.assertEquals(expectedStartOffset, updatedFeeType.StartDateOffset__c, 'Start Date Offset should match expected UK timezone offset');
            System.assertEquals(expectedEndOffset, updatedFeeType.EndDateOffset__c, 'End Date Offset should match expected UK timezone offset');
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testNoTimezoneOffsetsWhenNoContract
    @ Version:        1.0
    @ Author:         GitHub Copilot
    @ Purpose:        Test that timezone offsets are not populated when no contract is related
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2025 / GitHub Copilot / Created the test Method.
    *****************************************************************************************************************************/
    @isTest
    static void testNoTimezoneOffsetsWhenNoContract() {
        // Create test data
        User testUser = EBH_TestDataFactory.createUser('System Administrator');
        System.runAs(testUser) {
            // Create FeeType record without related contract
            RecordType feeTypeRT = ApexUtil.getRecordTypeByName('FeeType__c', 'Primary');
            
            Test.startTest();
            FeeType__c testFeeType = new FeeType__c(
                RecordTypeId = feeTypeRT.Id,
                PrimarySite__c = 'US',
                TypeofFee__c = 'EBAY_TOP_RATED_SELLER_DISCOUNT'
                // RelatedContract__c is null
            );
            insert testFeeType;
            Test.stopTest();
            
            // Verify timezone offsets were NOT populated
            FeeType__c insertedFeeType = [SELECT Id, StartDateOffset__c, EndDateOffset__c, PrimarySite__c FROM FeeType__c WHERE Id = :testFeeType.Id];
            
            System.assertEquals(null, insertedFeeType.StartDateOffset__c, 'Start Date Offset should be null when no contract is related');
            System.assertEquals(null, insertedFeeType.EndDateOffset__c, 'End Date Offset should be null when no contract is related');
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testNoTimezoneOffsetsWhenNoSite
    @ Version:        1.0
    @ Author:         GitHub Copilot
    @ Purpose:        Test that timezone offsets are not populated when PrimarySite is null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2025 / GitHub Copilot / Created the test Method.
    *****************************************************************************************************************************/
    @isTest
    static void testNoTimezoneOffsetsWhenNoSite() {
        // Create test data
        User testUser = EBH_TestDataFactory.createUser('System Administrator');
        System.runAs(testUser) {
            // Create Account
            RecordType legalEntity = ApexUtil.getRecordTypeByName('Account', 'EBH_LegalEntity');
            Account testAccount = new Account(
                Name = 'Test Legal Entity',
                RecordTypeId = legalEntity.Id,
                EBH_BillingCountry__c = 'US'
            );
            insert testAccount;
            
            // Create Contact
            RecordType contactRT = ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL');
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test@test.com',
                AccountId = testAccount.Id,
                RecordTypeId = contactRT.Id
            );
            insert testContact;
            
            // Create Contract
            RecordType contractRT = ApexUtil.getRecordTypeByName('Contract', 'EBH_ListingAgreement');
            Contract testContract = new Contract(
                Name = 'Test Contract',
                AccountId = testAccount.Id,
                Status = 'Draft',
                RecordTypeId = contractRT.Id,
                StartDate = Date.today(),
                EndDate = Date.today().addDays(365),
                EBH_Site__c = 'US',
                CompanySignedId = testUser.Id,
                CompanySignedDate = System.today(),
                CustomerSignedDate = System.today(),
                Business_Contact__c = testContact.Id
            );
            insert testContract;
            
            // Create FeeType record without PrimarySite
            RecordType feeTypeRT = ApexUtil.getRecordTypeByName('FeeType__c', 'Primary');
            
            Test.startTest();
            FeeType__c testFeeType = new FeeType__c(
                RecordTypeId = feeTypeRT.Id,
                RelatedContract__c = testContract.Id,
                TypeofFee__c = 'EBAY_TOP_RATED_SELLER_DISCOUNT'
                // PrimarySite__c is null
            );
            insert testFeeType;
            Test.stopTest();
            
            // Verify timezone offsets were NOT populated
            FeeType__c insertedFeeType = [SELECT Id, StartDateOffset__c, EndDateOffset__c, PrimarySite__c FROM FeeType__c WHERE Id = :testFeeType.Id];
            
            System.assertEquals(null, insertedFeeType.StartDateOffset__c, 'Start Date Offset should be null when PrimarySite is null');
            System.assertEquals(null, insertedFeeType.EndDateOffset__c, 'End Date Offset should be null when PrimarySite is null');
        }
    }
}