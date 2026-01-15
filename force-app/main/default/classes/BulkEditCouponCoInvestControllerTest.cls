/*********************************************************************************************************************************
@ Class:          BulkEditCouponCoInvestControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        BulkEditCouponCoInvestController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  07.09.2020 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
public without sharing class BulkEditCouponCoInvestControllerTest {
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
    
    private static testMethod void cancelActionTest() {
        Test.startTest();
        List<Coupon_Seller__c> lstCs = [SELECT Id FROM Coupon_Seller__c];
        Test.setCurrentPage(Page.BulkEditCouponCoInvestPage);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstCs);
        stdSetController.setSelected(lstCs);
        BulkEditCouponCoInvestController ctr = new BulkEditCouponCoInvestController(stdSetController);
        ctr.cancelAction();
        
        Test.stopTest();

    }
    
    static testMethod void testInitAndSaveCouponCoInvest(){

        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        //LA:05-12-2023-US-0014231
        //Account acc = new Account(SP_Coupons__c='Full Access',EBH_RevRollup__c='DE',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        Account acc = new Account(SP_Coupons__c='Full Access',EBH_RevRollup__c='DE',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc;

        Contact con = new Contact(LastName='Test Con1', Email='test@test.com.invalid', AccountId=acc.Id);
        insert con;

        Coupon__c c1 = new Coupon__c(Seller_Co_funding_share_forecast__c = null,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c = System.today().addDays(1), Negotiation_End_Date__c=System.today().addDays(1),Main_Coupon_Site__c = 'ebay.de',Coupon_Co_invest_Type__c='Contra');
        insert c1;
        
        //MN-30082021-US-0009948-Replace Email_Adress__c with Seller_Contact__c
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Seller_Contact__c = con.Id, Coupon__c = c1.Id,seller__c = acc.Id,Legal_Entity_Name_w__c = 'testName',Legal_Entity_Street_w__c='testStreet',Legal_Entity_Zip_w__c='testZip');
        insert cs1;
        
        /* //MN-30082021-US-0009948-Replace Email_Adress__c with Seller_Contact__c
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Email_Adress__c = 'sophal.noch@gaea-sys.com', Coupon__c = c1.Id,seller__c = acc.Id,Legal_Entity_Name_w__c = 'testName',Legal_Entity_Street_w__c='testStreet',Legal_Entity_Zip_w__c='testZip');
        insert cs1;
        */

        cs1.Legal_Entity_Name_w__c = 'testName';
        cs1.Legal_Entity_Street_w__c = 'testStreet';
        cs1.Legal_Entity_Zip_w__c = 'testZip';

        update cs1;

        Coupon_Co_Invest__c coInvest1 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id, Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
        Coupon_Co_Invest__c coInvest2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id, Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=20);
        
        List<Coupon_Co_Invest__c> listCoInvestToInsert = new List<Coupon_Co_Invest__c>{coInvest1,coInvest2}; 
        insert listCoInvestToInsert;

        Map<String,Object> mapResult = BulkEditCouponCoInvestController.apexInit();
        System.assertEquals('ok', mapResult.get('status'));

        listCoInvestToInsert[0].Co_Invest__c = 50;
        listCoInvestToInsert[1].Co_Invest__c = 60;

        mapResult = BulkEditCouponCoInvestController.apexSave(listCoInvestToInsert);

        System.assertEquals('ok', mapResult.get('status'));

        List<Coupon_Co_Invest__c> listCoInvestAfterUpdate = [SELECT Id, Co_Invest__c from Coupon_Co_Invest__c WHERE Id IN : listCoInvestToInsert Order By Id ASC];

        System.assertEquals(listCoInvestToInsert[0].Co_Invest__c, listCoInvestAfterUpdate[0].Co_Invest__c);
        System.assertEquals(listCoInvestToInsert[1].Co_Invest__c, listCoInvestAfterUpdate[1].Co_Invest__c);

    }
}