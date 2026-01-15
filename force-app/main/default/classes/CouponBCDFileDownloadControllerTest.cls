/*********************************************************************************************************************************
@ Class:          CouponBCDFileDownloadControllerTest
@ Version:        1.0
@ Author:         
@ Purpose:        test CouponBCDFileDownloadController
@                  EPH-7723 Coupon Object - csv file + download functionality for BCD
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24/07/2019 / Created the class.
*********************************************************************************************************************************/

@isTest
private class CouponBCDFileDownloadControllerTest {

    static testMethod void myUnitTest() {
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Map<String,RecordType> couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');
        Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,Registration_Site_ID__c ='77',ISO_Currency_Code__c ='123',EBH_RevRollup__c='DE',SP_Coupons__c='Full Access');
        insert acc;
        Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id,Main_Coupon_Site__c = 'ebay.de',Coupon_Co_invest_Type__c='Contra');
        insert c1;
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,Contract_Accept_Date__c=System.today(),Coupon_Seller_Stage__c='T34 Statement Send');
        Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,Contract_Accept_Date__c=System.today(),Coupon_Seller_Stage__c='T34 Statement Send');
        insert new List<Coupon_Seller__c>{cs1,cs2};
        
        Test.startTest();
        CouponBCDFileDownloadController controller = new CouponBCDFileDownloadController(new ApexPages.standardController(c1)); 
        System.debug('<<<controller.csvData='+controller.csvData);
        List<String> listRow = controller.csvData.split('\n'); 
      //  System.assert(listRow.size() == 3);
     //   System.assert(controller.csvData.contains('testExternalId'));
      //  System.assert(controller.csvData.contains('testProvideId'));
      //  System.assert(controller.csvData.contains('EUR'));
        Test.stopTest();
        
    }
}