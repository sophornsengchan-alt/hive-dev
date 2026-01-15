@isTest
public class BatchUpdateCouponStageTest {

    @isTest static void testBatchUpdateCouponStage() {
        // Prepare test data
        DateTime dtNow = System.now();
    	Coupon__c cp = new Coupon__c(
            Coupon_Start_Date__c=dtNow.addDays(-1).date(),
            Coupon_Start_Time__c=dtNow.timeGmt(),
            Coupon_End_Date__c=dtNow.addDays(1).date(),
            Coupon_end_Time__c=dtNow.timeGmt(),
            Main_Coupon_Site__c = 'ebay.com',
            Coupon_Co_invest_Type__c='Contra',
            Coupon_id__c='SALE15',
            Stage__c='Seller Negotiation'
        );
    	insert cp;

        // Prepare test batch
        BatchUpdateCouponStage batch = new BatchUpdateCouponStage();

        // Start test
        Test.startTest();
        // Execute batch
        Database.executeBatch(batch);
        // Stop test
        Test.stopTest();

        // Verify
        List<Coupon__c> runningCoupon = [SELECT Id,Stage__c FROM Coupon__c WHERE Id = :cp.Id];
        System.assertEquals('Coupon Running', runningCoupon[0].Stage__c);

        // Execute schedulable
        String cronExp = '0 0 0 1 1 ? 2099';
        String jobName = 'TestScheduledApex';
        System.schedule(jobName, cronExp, batch);

    }

    @isTest static void testBatchUpdateCouponStageWithId() {
        // Prepare test data
        DateTime dtNow = System.now();
    	Coupon__c cp = new Coupon__c(
            Coupon_Start_Date__c=dtNow.addDays(-1).date(),
            Coupon_Start_Time__c=dtNow.timeGmt(),
            Coupon_End_Date__c=dtNow.addDays(1).date(),
            Coupon_end_Time__c=dtNow.timeGmt(),
            Main_Coupon_Site__c = 'ebay.com',
            Coupon_id__c='SALE15',
            Coupon_Co_invest_Type__c='Contra',
            Stage__c='Seller Negotiation'
        );
    	insert cp;

        // Prepare test batch
        BatchUpdateCouponStage batch = new BatchUpdateCouponStage(cp.Id);

        // Start test
        Test.startTest();
        // Execute batch
        Database.executeBatch(batch);
        // Stop test
        Test.stopTest();

        // Verify
        List<Coupon__c> couponList = [SELECT Id,Stage__c FROM Coupon__c WHERE Id = :cp.Id];
        System.assertEquals('Coupon Running', couponList[0].Stage__c);

    }
    @isTest static void testBatchUpdateCouponStageCanadaSite() {
        // Prepare test data
        DateTime dtNow = System.now();
    	Coupon__c cp = new Coupon__c(
            Coupon_Start_Date__c=dtNow.addDays(-1).date(),
            Coupon_Start_Time__c=dtNow.timeGmt(),
            Coupon_End_Date__c=dtNow.addDays(1).date(),
            Coupon_end_Time__c=dtNow.timeGmt(),
            Main_Coupon_Site__c = 'ebay.ca',
            Coupon_id__c='SALE15',
            Coupon_Co_invest_Type__c='Contra',
            Stage__c='Seller Negotiation'
        );
    	insert cp;

        // Prepare test batch
        BatchUpdateCouponStage batch = new BatchUpdateCouponStage();

        // Start test
        Test.startTest();
        // Execute batch
        Database.executeBatch(batch);
        // Stop test
        Test.stopTest();

        // Verify
        List<Coupon__c> runningCoupon = [SELECT Id,Stage__c FROM Coupon__c WHERE Id = :cp.Id];
        System.assertEquals('Coupon Running', runningCoupon[0].Stage__c);

        // Execute schedulable
        String cronExp = '0 0 0 1 1 ? 2099';
        String jobName = 'TestScheduledApex';
        System.schedule(jobName, cronExp, batch);
    }
}