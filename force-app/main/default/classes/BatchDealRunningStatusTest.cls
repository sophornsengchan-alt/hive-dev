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
private class BatchDealRunningStatusTest {

    static testMethod void testDealAutoStatus() {
		/*
		DateTime now = System.now();
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id);
        insert acc1;
        
		RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
        Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordTypeItem.Id, Coupon_Start_Time__c=now.timeGmt(), Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), Coupon_Start_Date__c=System.Today(), Coupon_End_Date__c=System.Today());
        Coupon__c c2 = new Coupon__c(RecordTypeID = couponRecordTypeItem.Id, Coupon_Start_Time__c=now.timeGmt(), Coupon_End_Time__c=now.timeGmt(), Coupon_Start_Date__c=System.Today().addDays(-5), Coupon_End_Date__c=System.Today());
		insert new List<Coupon__c>{c1,c2};
		 
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED, Seller__c=acc1.Id);
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c2.Id,Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_RUNNING, Seller__c=acc1.Id);
		insert new List<Coupon_Seller__c>{cs1,cs2};
    	
		Test.startTest();
		
		BatchDealRunningStatus b = new BatchDealRunningStatus();
		BatchDealRunningStatus b1 = new BatchDealRunningStatus(c1.Id);
		Database.executeBatch(b);
		b.execute(null);

		Test.stopTest();

		Coupon_Seller__c res1 = [select Coupon_Seller_Stage__c from Coupon_Seller__c where Id =:cs1.Id];
		System.assertEquals('Coupon Running', res1.Coupon_Seller_Stage__c, 'Coupon Seller stage is Coupon Running');

		Coupon_Seller__c res2= [select Coupon_Seller_Stage__c from Coupon_Seller__c where Id =:cs2.Id];
		System.assertEquals('Coupon executed', res2.Coupon_Seller_Stage__c, 'Coupon Seller stage is Coupon executed');
        */

		Test.startTest();
		
		BatchDealRunningStatus b = new BatchDealRunningStatus();	 
		Database.executeBatch(b);
		b.execute(null);
		b.execute(null,null);

		Test.stopTest();
    }
}