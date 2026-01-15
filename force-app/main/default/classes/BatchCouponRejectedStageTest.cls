/*********************************************************************************************************************************
@ Class         : BatchCouponRejectedStage
@ Version       : 1.0
@ Author        : Loumang SENG (loumang.seng@gaea-sys.com)
@ Purpose       : Test class for Batch BatchCouponRejectedStage
@ Change history: 01.04.2024 / Loumang SENG / Created the class
*********************************************************************************************************************************/
@isTest 
public with sharing class BatchCouponRejectedStageTest {
    private static Coupon__c c1;

    @TestSetup
    static void setupData()
    {
        EBH_TestDataFactory.setUpCustomSettings(); 	
        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c','Manhattan_Coupon');
        Account acc1 = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c ='AU', SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='AU',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        Account acc2 = new Account(Name='Test Abc124',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c ='AU', SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='AU',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert new List<Account>{acc1,acc2};

        Contact cont1 = new Contact(LastName = 'SellerContact_1',Email='test@test.com.invalid', AccountId=acc1.Id);
        Contact cont2 = new Contact(LastName = 'SellerContact_2',Email='test@test.com.invalid', AccountId=acc2.Id);
        insert new List<Contact>{cont1,cont2};
    
        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
        c1 = new Coupon__c(Coupon_Co_invest_Type__c='Contra',Main_Coupon_Site__c='ebay.com.au',RecordTypeID = couponRecordTypeItem.Id, Coupon_Start_Time__c=now.timeGmt(), Coupon_End_Time__c=now.timeGmt(), Coupon_Start_Date__c=System.Today().addDays(3), Coupon_End_Date__c=System.Today().addDays(9));
        insert c1;
            
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id,Coupon_Seller_Stage__c='Targeted', Seller__c=acc1.Id);
        Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,Contract_Signed_Declined_By__c=cont2.Id,RecordTypeID=manhattanCouponSellerRecordType.Id,Coupon_Seller_Stage__c='Contract Signed', Seller__c=acc2.Id);
        insert new List<Coupon_Seller__c>{cs1,cs2};
    }
    

    @isTest 
    public static void test_batch() {
        setupData();
        c1.Stage__c ='Coupon rejected';
        update c1;
        Test.startTest();

            BatchCouponRejectedStage b = new BatchCouponRejectedStage();
            b.execute(null);
            BatchCouponRejectedStage b1 = new BatchCouponRejectedStage(new Set<String>{c1.Id});
            b1.execute(null);

        Test.stopTest();
        List<Coupon_Seller__c> listCs= [Select Id,Coupon_Seller_Stage__c,Seller_Declined_Reasons__c From Coupon_Seller__c Where Coupon__c =: c1.Id];
        System.assertEquals('Seller Declined', listCS[0].Coupon_Seller_Stage__c);
        System.assertEquals('Contract Voided', listCS[0].Seller_Declined_Reasons__c);
    }    

}