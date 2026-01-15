/*********************************************************************************************************************************
@ Class:         Batch_CouponSellerPackPromotionsTest
@ Version:       1.0
@ Author:        SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:       Batch_CouponSellerPackPromotions
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.12.2023 / SRONG TIN / Created the class.
*********************************************************************************************************************************/
@isTest
public class Batch_CouponSellerPackPromotionsTest {    
    
    static void setupData()
    {
        	EBH_TestDataFactory.setUpCustomSettings(); 	
        	DateTime now = System.now();
            RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        	RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c','Manhattan_Coupon');
            Account acc1 = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c ='AU', SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
            insert acc1;
        	List<Contact> listCont = new List<Contact>();
            for(Integer i = 0; i < 4; i++){
                
                Contact cont = new Contact(
                    LastName = 'SellerContact_'+(i+1),
                    Email='test@test.com.invalid', 
                    AccountId=acc1.Id
                );
                
                listCont.add(cont);
            }
            insert listCont;
        
            RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
            Coupon__c c1 = new Coupon__c(Coupon_Co_invest_Type__c='Contra',Main_Coupon_Site__c='ebay.com.au',RecordTypeID = couponRecordTypeItem.Id, Coupon_Start_Time__c=now.timeGmt(), Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), Coupon_Start_Date__c=System.Today().addDays(3), Coupon_End_Date__c=System.Today().addDays(9));
            Coupon__c c2 = new Coupon__c(Coupon_Co_invest_Type__c='Contra',Main_Coupon_Site__c='ebay.com.au',RecordTypeID = couponRecordTypeItem.Id, Coupon_Start_Time__c=now.timeGmt(), Coupon_End_Time__c=now.timeGmt(), Coupon_Start_Date__c=System.Today().addDays(3), Coupon_End_Date__c=System.Today().addDays(9));
            insert new List<Coupon__c>{c1,c2};
                
            Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Contract_Signed_Declined_By__c=listCont[0].Id,RecordTypeID=manhattanCouponSellerRecordType.Id,Coupon_Seller_Stage__c='Contract Signed', Seller__c=acc1.Id);
    		Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c2.Id,Contract_Signed_Declined_By__c=listCont[0].Id,RecordTypeID=manhattanCouponSellerRecordType.Id,Coupon_Seller_Stage__c='Contract Signed', Seller__c=acc1.Id);
    		insert new List<Coupon_Seller__c>{cs1,cs2};
    }
    
    static @IsTest
    void testBatchCouponSellerPackPromotions(){
        setupData();       
        Test.startTest();
        List<Coupon_Seller__c> couponS = [Select Id From Coupon_Seller__c];
        List<String> ids = new List<String>();
        for(Coupon_Seller__c con:couponS){
            ids.add(con.Id);
        }
        Batch_CouponSellerPackPromotions bCouponSeller = new Batch_CouponSellerPackPromotions();
        Batch_CouponSellerPackPromotions bCouponSeller2 = new Batch_CouponSellerPackPromotions(ids);
        bCouponSeller.execute(null);
        bCouponSeller2.execute(null);
        Test.stopTest();
        
    }
}