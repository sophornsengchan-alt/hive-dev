/*********************************************************************************************************************************
@ Class:          Delete Coupon Co-invest
@ Version:        1.0
@ Author:         Chetra Sarom
@ Purpose:        22.11.2022/ US-0012681 - Ability to delete Coupon Co-invest records in bulk
*********************************************************************************************************************************/
@isTest
public with sharing class BulkDeleteCouponCoinvestControllerTest {
    @testSetup static void setUp() {
        User admin = EBH_TestDataFactory.createUser('System Administrator');
    	System.runAs(admin)
    	{
               Test.startTest();
                    RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
                    Account acc = new Account(
                                Name = 'Seller_1',
                                EBH_RevRollup__c = 'UK',
                                EBH_PrimarySite__c= 'UK',
                                //EBH_DealsProgram__c='Accepted',
                                RecordTypeId = sellerRecordType.Id,
                                SP_Coupons__c = 'Full Access',
                                EBH_BillingAddress__c='PP',
                                EBH_BillingCity__c='pp',
                                EBH_BillingCountry__c='US',
                                EBH_CompanyName__c='test',
                                EBH_BillingPostalCode__c='12102'
                                );
                    insert acc;

                    Contact cont = new Contact(
                                LastName = 'SellerContact_1',
                                Email='test@test.com.invalid', 
                                AccountId=acc.Id);
                    insert cont;

                    RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
                    Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c = 'ebay.co.uk',Coupon_Co_invest_Type__c='Contra',MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1);
                    insert new List<Coupon__c>{c1};
                    
                    RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
                    Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Review',Seller_Contact__c=cont.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
                    Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Contract Negotiation',Seller_Contact__c=cont.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
                    insert new List<Coupon_Seller__c>{cs1,cs2};
                    
                    Coupon_Co_Invest__c coInvest1 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
                    Coupon_Co_Invest__c coInvest2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs2.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
                    List<Coupon_Co_Invest__c> lstCCI = new List<Coupon_Co_Invest__c>{coInvest1,coInvest2}; 
                    insert lstCCI;
                    
                Test.stopTest();
            }     
               
    }

    private static void deleteCoinvest(List<Coupon_Co_Invest__c> lstCC, Coupon_Seller__c cs){
        List<Coupon_Seller__c> listCS = [select id from Coupon_Seller__c];
        String str = '/apex/Coupon_Co_Invests__r?Id=' + cs.Id ;
        PageReference pageRef = new PageReference(str);
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstCC);
        sc.setSelected(lstCC);
        BulkDeleteCouponCoinvestController tc = new BulkDeleteCouponCoinvestController(sc);
        tc.deleteCouponCoInvest();     
        tc.backToListView();
    }

    static testMethod void deleteCouponCoInvest(){
        Test.startTest();
            List<Coupon_Co_Invest__c> lstCC = [select id from Coupon_Co_Invest__c];
            List<Coupon_Seller__c> listCS = [select id from Coupon_Seller__c];
            deleteCoinvest(lstCC,listCS[0]);
        Test.stopTest();
    }

    static testMethod void deleteCouponCoInvest_noRecordSelected(){
        Test.startTest();
            List<Coupon_Seller__c> listCS = [select id from Coupon_Seller__c];
            deleteCoinvest(new List<Coupon_Co_Invest__c>(),listCS[0]);
        Test.stopTest();
    }

    static testMethod void deleteCouponCoInvest_csStageNotReview(){
        Test.startTest();
            List<Coupon_Co_Invest__c> lstCC = [select id from Coupon_Co_Invest__c];
            List<Coupon_Seller__c> listCS = [select id from Coupon_Seller__c];
            deleteCoinvest(lstCC,listCS[1]);
        Test.stopTest();
    }

    static testMethod void deleteCouponCoInvest_profileNotAdmin(){
        Test.startTest();
            User u1;
            Profile p = [select id from Profile where name='Standard Ads User Profile' limit 1];
            u1 = new User(alias = 'TestApro', email='TestsubApprov@ebay.com', 
                                emailencodingkey='UTF-8', lastname='TestsubApprov', firstname='TestsubApprov', languagelocalekey='en_US', 
                                localesidkey='en_US', profileid = p.Id, 
                                timezonesidkey='America/Los_Angeles', username='TestsubApprov@salesforce.de', isActive = true);
            System.runAs(u1){
                List<Coupon_Co_Invest__c> lstCC = [select id from Coupon_Co_Invest__c];
                List<Coupon_Seller__c> listCS = [select id from Coupon_Seller__c];
                deleteCoinvest(lstCC,listCS[0]);
            }
        Test.stopTest();
    }
    
}