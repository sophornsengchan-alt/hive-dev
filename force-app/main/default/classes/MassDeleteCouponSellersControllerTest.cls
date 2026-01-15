@isTest
public class MassDeleteCouponSellersControllerTest {
	@testSetup private static void setup() {
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		System.runAs(admin){
			Profile p = [select id from Profile where name='Standard User Profile' limit 1];
            User standardUsr = new User(alias = 'tsUser', email='TestStardardUser@ebay.com',
                            emailencodingkey='UTF-8', lastname='TestStandardUser', firstname='TestStandardUser', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id,
                            timezonesidkey='America/Los_Angeles', username='TestStardarduser@salesforce.de', isActive = true);
            insert standardUsr;
		}
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType couponItemBaseRecordType = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RegistrationCountry__c = '0',EBH_RevRollup__c='US',SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	Account acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_RegistrationCountry__c = '0',EBH_RevRollup__c='US',SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert new List<Account>{acc,acc2};
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponItemBaseRecordType.Id,Main_Coupon_Site__c = 'ebay.com',Coupon_Co_invest_Type__c='Contra');
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,RecordTypeId = manhattanCouponSellerRecordType.Id);
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc2.Id,RecordTypeId = manhattanCouponSellerRecordType.Id);
    	insert new List<Coupon_Seller__c>{cs1,cs2};
    }

    @isTest
    static void deleteActionTest() {
        Test.startTest();
        List<Coupon_Seller__c> lstCs = [SELECT Id FROM Coupon_Seller__c];
        Test.setCurrentPage(Page.MassDeleteCouponSellers);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstCs);
        stdSetController.setSelected(lstCs);
        MassDeleteCouponSellersController ctr = new MassDeleteCouponSellersController(stdSetController);
        ctr.deleteRecordAction();
        lstCs = [SELECT Id FROM Coupon_Seller__c];
        System.assertEquals(0,lstCs.size(),'Delete Success');
        Test.stopTest();

    }

    @isTest
    static void testCouponSellerSelectFail() {
        Test.startTest();
        List<Coupon_Seller__c> lstCs = [SELECT Coupon_Seller_Stage__c FROM Coupon_Seller__c];
        User user1 = [SELECT Id,name From User WHERE Alias='tsUser' limit 1];
        List<Coupon__c> lstC = [SELECT Stage__c FROM Coupon__c];
        lstC[0].Stage__c = 'Seller Negotiation';
        lstCs[0].Coupon_Seller_Stage__c = 'Contract Send';
        update lstC;
        update lstCs;
        ApexPages.StandardSetController stdSetController2 = new ApexPages.StandardSetController(lstCs);
        stdSetController2.setSelected(lstCs);
        MassDeleteCouponSellersController ctr2 = new MassDeleteCouponSellersController(stdSetController2);
        System.runAs(user1) {
            ctr2.deleteRecordAction();
        }
        lstCs = [SELECT Coupon_Seller_Stage__c FROM Coupon_Seller__c];
        System.assertEquals(2,lstCs.size(),'Delete fail');
        Test.stopTest();
    }
}