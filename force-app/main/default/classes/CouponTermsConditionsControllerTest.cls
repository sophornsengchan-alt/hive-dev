/*********************************************************************************************************************************
@ Class:          CouponTermsConditionsControllerTest
@ Version:        1.0
@ Author:         sovantheany dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Test class for EBH_DealController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.11.2017 / sovantheany dim / Created the test class.
*********************************************************************************************************************************/
@isTest
private class CouponTermsConditionsControllerTest {
	 static testMethod void testhandleCouponTermsAndCondition() {
         EBH_TestDataFactory.setUpCustomSettings();
         RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
         Account acc1 = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_VATNumber__c='1111',EBH_RevRollup__c='US');
         insert acc1;
         
         RecordType couponRecordTypeCategory = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
         Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordTypeCategory.Id,Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCoupon123');
         insert c1;
         Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO,Seller__c = acc1.Id);
         insert cs1;
         Test.startTest();
        
          PageReference pageRef = Page.Coupon_Terms_and_Conditions;
          Test.setCurrentPage(pageRef);
          ApexPages.currentPage().getParameters().put('csid', cs1.Id);
          
          Coupon_Terms_and_ConditionsController con = new Coupon_Terms_and_ConditionsController();
          con.handleCouponTermsAndCondition();
          System.assert(con.abn == '1111','ABN/VATNumber');
          
          ApexPages.currentPage().getParameters().put('csid', null);
          con.handleCouponTermsAndCondition();
          
        Test.stopTest();
     }
}