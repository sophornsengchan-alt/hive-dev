/*********************************************************************************************************************************
@ Class:          CouponSellerRedirectorTest
@ Version:        1.0
@ Author:         LoumAng SENG (loumang.seng@gaea-sys.com)
@ Purpose:        US-0007360 - wrong coupon seller record when click on NEW
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.04.2020 / LoumAng SENG / Created the class.
				  
*********************************************************************************************************************************/
@isTest
private class CouponSellerRedirectorTest {
	@testSetup
    static void setup(){
        EBH_TestDataFactory.setUpCustomSettings();
        
    }
    @isTest
    static void doGetCouponTest(){
        setup();
        Coupon__c c1 = new Coupon__c();
        c1.Coupon_ID__c = '12345';
        c1.RecordTypeId = ApexUtil.getRecordTypeByName('Coupon__c','Pop_Coupon').Id;
        insert c1;
        Coupon__c c2 = new Coupon__c();
        c2.Coupon_ID__c = '54321';
        c2.Main_Coupon_Site__c = 'ebay.co.uk';
        c2.Coupon_Co_invest_Type__c='Contra';
        c2.RecordTypeId = ApexUtil.getRecordTypeByName('Coupon__c','Category_Based').Id;
        insert c2;
        Test.startTest();
         	Map<String, Object> mResult = CouponSellerRedirector.doGetCoupon(c1.Id);
        	System.assert(ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPON_POP_RECORDTYPE).Id ==  mResult.get('recordTypeId'), mResult.get('recordTypeId'));
        	Map<String, Object> mResult2 = CouponSellerRedirector.doGetCoupon(c2.Id);
        	System.assert(ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE).Id ==  mResult2.get('recordTypeId'), mResult2.get('recordTypeId'));
            Map<String, Object> mResult3 = CouponSellerRedirector.doGetCoupon(null);
        Test.stopTest();
    }
}