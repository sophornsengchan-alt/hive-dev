@isTest
public class Batch_DeleteSellerPortalLogRecordTest {
    @isTest static void testBatch_DeleteSellerPortalLogRecord() {
        // Prepare test data
        Seller_Portal_Log__c sellerPortaLog = new Seller_Portal_Log__c();
        sellerPortaLog.Exclude_from_auto_deletion__c = false;
        sellerPortaLog.CreatedDate = System.now().addDays(-91);
        insert sellerPortaLog;

        // Prepare test batch
        Batch_DeleteSellerPortalLogRecord batch = new Batch_DeleteSellerPortalLogRecord();

        // Start test
        Test.startTest();
        // Execute batch
        Database.executeBatch(batch);
        // Stop test
        Test.stopTest();

        // Verify
        List<Seller_Portal_Log__c> deletedSellerPortaLog = [SELECT Id FROM Seller_Portal_Log__c WHERE Id = :sellerPortaLog.Id];
        System.assertEquals(true, deletedSellerPortaLog.isEmpty(), 'The sellerPortaLog record should be deleted');

        // Execute schedulable
        String cronExp = '0 0 0 1 1 ? 2099';
        String jobName = 'TestScheduledApex';
        System.schedule(jobName, cronExp, batch);

    }

    @isTest static void testBatch_DeleteSellerPortalLogRecordWithId() {
        // Prepare test data
        Seller_Portal_Log__c sellerPortaLog = new Seller_Portal_Log__c();
        sellerPortaLog.Exclude_from_auto_deletion__c = false;
        sellerPortaLog.CreatedDate = System.now().addDays(-91);
        insert sellerPortaLog;

        // Prepare test batch
        Batch_DeleteSellerPortalLogRecord batch = new Batch_DeleteSellerPortalLogRecord(sellerPortaLog.Id);

        // Start test
        Test.startTest();
        // Execute batch
        Database.executeBatch(batch);
        // Stop test
        Test.stopTest();

        // Verify
        List<Seller_Portal_Log__c> deletedSellerPortaLog = [SELECT Id FROM Seller_Portal_Log__c WHERE Id = :sellerPortaLog.Id];
        System.assertEquals(true, deletedSellerPortaLog.isEmpty(), 'The sellerPortaLog record should be deleted');

    }
}