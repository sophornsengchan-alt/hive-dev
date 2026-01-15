@isTest
private class Batch_CreateCoInvestTest {
    static RecordType sellerRecordType;
    static Map<String,RecordType> couponRecordType;
    static Account acc;
    static Account acc2;    	 
    static Coupon__c c1;	 
    static Coupon_Seller__c cs1;
    static Coupon_Seller__c cs2;    	 
    static Category_Tree__c ct1;     
    static Category_Tree__c ct2;
    static Coupon_Category__c cc1;
    static Coupon_Category__c cc2;        
        
    static void setupData()
    {
        EBH_TestDataFactory.setUpCustomSettings();  

        sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');
    	acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c ='AU', SP_Coupons__c='Full Access');
    	acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c ='AU', SP_Coupons__c='Full Access');
    	insert new List<Account>{acc,acc2};
        Contact con = new Contact(LastName='Test Con1', Email='test@test.com', AccountId=acc.Id,Accepted_Current_Deals_Agreement__c=false); //MN-30082021-US-0009948
        insert con;
        Contact con2 = new Contact(LastName='Test Con2', Email='test@test.com', AccountId=acc2.Id); //MN-30082021-US-0009948
        insert con2;
        DateTime now = System.now();
    	RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
        c1 = new Coupon__c(Coupon_Co_invest_Type__c='Contra',Main_Coupon_Site__c='ebay.com.au',RecordTypeID = couponRecordTypeItem.Id, Coupon_Start_Time__c=now.timeGmt(), Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), Coupon_Start_Date__c=System.Today(), Coupon_End_Date__c=System.Today().addDays(2));
    	insert c1;
        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
        cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Reached',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
        //cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id);
    	//cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc2.Id);
        cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Reached',Seller_Contact__c=con2.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc2.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
        insert new List<Coupon_Seller__c>{cs1,cs2};
    	ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0,Active__c=true);
    	ct2 = new Category_Tree__c(Name = 'testCategoryTree2',Level__c = 1,Note_ID__c=ct1.Id,Active__c=true);
    	insert ct2;
    	cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct1.Id);
    	cc2 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct2.Id);
    	insert new List<Coupon_Category__c>{cc1,cc2};
    }
    static @IsTest
    void testBatchCoInvest(){
        setupData();       

        Test.startTest();
            Batch_CreateCoInvest bCoInvest = new Batch_CreateCoInvest(new Set<Id>{c1.Id});
            bCoInvest.countAllCoInvest_fail = 1; // to cover code coverage
            Database.executeBatch(bCoInvest);
        Test.stopTest();
        
    }
}