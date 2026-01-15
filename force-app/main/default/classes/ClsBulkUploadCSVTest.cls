/*********************************************************************************************************************************
@ Class:          ClsBulkUploadCSVTest
@ Version:        1.0
@ Author:         Sochettra Saing
@ Purpose:        Ability to run test the logic in class ClsBulkUploadCSVTest(EBAY-228)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.07.2021 / Sochettra Saing / Created the class.
*********************************************************************************************************************************/

@isTest 
public with sharing class ClsBulkUploadCSVTest {

    public static final String DRC_Deal_WINDOW = 'Deal_Campaign_V2';
    private static List<EBH_Deal__c> lstDeal;
    private static EBH_DealRetailCampaign__c dsa1;

    @testSetup
    static void setup(){
        
        EBH_TestDataFactory.setUpCustomSettings();

    	//create an account
        Account acc = new Account( Name = 'TestAccount' , SP_Main_Domain__c = SEP_Helper.SEP_Domain_DE , NA_Deal_Program_Vetted__c = true, SP_Promotions_Manager__c = 'Full Access',SP_Coupons__c='Full Access');
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
        /*user1 = new User(
                                Username = System.now().millisecond() + 'test12345@test.com',
                                ContactId = con.Id,
                                ProfileId = portalProfile.Id,
                                Alias = 'test123',
                                Email = 'test12345xx@test.com',
                                EmailEncodingKey = 'UTF-8',
                                LastName = 'McTesty',
                                CommunityNickname = 'test12345',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US'
                                );
        insert user1;*/

        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c = 'ebay.com',MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1);
        insert new List<Coupon__c>{c1};

        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
        insert cs1;

        Date today = System.today();
        Date dDate = Date.newInstance( today.year()+1, today.month()+1, 1);
        RecordType recPM = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c','Promotions_Manager_Deals');
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(RecordTypeId = recPM.Id,eBay_Seller__c = acc.id,Deal_Start_Date__c=dDate, Deal_End_Date__c = dDate+10);
        insert ndca;

        Id dealRetailCampaignRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', 'Deal_Campaign_V1').Id;
        EBH_DealRetailCampaign__c drc1 = new EBH_DealRetailCampaign__c(RecordtypeId=dealRetailCampaignRecordTypeId, Focus_Categories__c = 'Electronics', EBH_Date__c = System.Today(), EPH_EndDate__c = System.Today(), EBH_Country__c = '101' );
        insert drc1;
    }

    @IsTest
    static void testMethod1(){

        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];

        //Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'DE - Seller Portal']; //MN-10062024-US-0015298
        //UserRole ur = new UserRole(Name = 'Liny - TEST US Seller Customer User', DeveloperName= 'LinyTESTUSSellerCustomerUser', PortalType = 'CustomerPortal', PortalAccountId = acc.Id);
        //insert ur;
        //UserRole userRole = [SELECT Id FROM UserRole WHERE PortalType = 'CustomerPortal' LIMIT 1]; UserRoleId = userRole.Id,
        /*Account acc = new Account( Name = 'TestAccount' );
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;  */
        
        
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];

        User user1 = SEPTestGenerator.createSEPUser('sepUsercbuc1', con.Id); //MN-10062024-US-0015298

        /* MN-10062024-US-0015298
        User user1 = new User(
                                Username = System.now().millisecond() + 'test12345@test.com',
                                ContactId = con.Id,
                                ProfileId = profile1.Id,
                                
                                Alias = 'test123',
                                Email = 'test12345xx@test.com',
                                EmailEncodingKey = 'UTF-8',
                                LastName = 'McTesty',
                                CommunityNickname = 'test12345',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US'
                                );

        insert user1;
        */
        
        Test.startTest(); 

        Id drcId;

        System.runAs(user1) {

            // Id dealRetailCampaignRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', DRC_Deal_WINDOW).Id;
            Id dealRetailCampaignRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', 'Deal_Campaign_V1').Id;
            
            Date myDate = System.Today();
            integer i=0;
            
            //"SELECT Deal_Window__c, Focus_Categories__c, EBH_Date__c, EPH_EndDate__c, Status_Seller_Portal__c, EBH_DealTitle__c, Retail_Moment_Inventory__c, EBH_Country__c, (SELECT Id, EBH_DealTitle__c, Status_Seller_Portal__c, EBH_Date__c, EPH_EndDate__c FROM Deal_Retail_Campaigns__r WHERE RecordType.Name = 'Deal Window Campaign')  FROM EBH_DealRetailCampaign__c WHERE RecordType.Name = 'Deal Window' AND OwnerId='0051F00000nGBdyQAG' ORDER BY EBH_AcceptProposalsStart__c desc"
            
            dsa1 = new EBH_DealRetailCampaign__c(RecordtypeId=dealRetailCampaignRecordTypeId, Focus_Categories__c = 'Electronics', EBH_Date__c = myDate, EPH_EndDate__c = myDate, EBH_Country__c = '101' );
            insert dsa1;

            
            drcId = dsa1.Id;
            
            Map<String, Object> mResult = (Map<String, Object>) ClsBulkUploadCSV.doLoadSetting(dsa1.Id);

            mResult = (Map<String, Object>) ClsBulkUploadCSV.doLoadSettingLinkedAccount(dsa1.Id, acc.Id);
            
            /*mResult.put('availableDeal', maxDealWindow - totalDeal);
            mResult.put('userId', userId);
            mResult.put('accountId', accountId);
            mResult.put('contactId', contactId);
            mResult.put('conEmail', conEmail);
            mResult.put('status', 'success');*/
            System.assertEquals('Status:success', 'Status:'+mResult.get('status'));
            System.assertEquals('Account:'+acc.Id, 'Account:'+mResult.get('accountId'));
            System.assertEquals('email:'+con.Email, 'email:'+mResult.get('conEmail'));

            Time t = System.now().time();
            Time startTime = t.addHours(2);
            Time endTime = t.addHours(3);
            lstDeal = new List<EBH_Deal__c>();
            EBH_Deal__c d1 = new EBH_Deal__c();
            d1.EBH_BusinessName__c = acc.Id;
            d1.EBH_Category__c = 'Electronics';
            d1.EBH_DealEndDate__c = dsa1.EPH_EndDate__c;
            d1.EBH_DealEndTime__c = endTime;
            d1.EBH_DealFormat__c = 'Core';
            d1.EBH_DealPrice__c = 20;
            d1.EBH_DealRetailCampaign__c = dsa1.Id;
            d1.EBH_DealSiteId__c = '0';
            d1.EBH_DealStartDate__c = dsa1.EBH_Date__c;
            d1.EBH_DealStartTime__c = startTime;
            d1.EBH_Dealdateearliestpossible__c = dsa1.EBH_Date__c;
            d1.EBH_ProductTitle__c = 'Deal Test 1';
            d1.EBH_Quantity__c = 500;
            d1.EBH_RRPWASPrice__c = 100;
            d1.EBH_SellerEmail__c = con.Email;
            d1.EBH_SellerPrice__c = 200;
            d1.EBH_eBayItemID__c = '100000000001';
            d1.Seller_Contact__c = con.Id;
            lstDeal.add(d1);

            EBH_Deal__c d2 = new EBH_Deal__c();
            d2.EBH_BusinessName__c = acc.Id;
            d2.EBH_Category__c = 'Electronics';
            d2.EBH_DealEndDate__c = dsa1.EPH_EndDate__c;
            d2.EBH_DealEndTime__c = endTime;
            d2.EBH_DealFormat__c = 'Core';
            d2.EBH_DealPrice__c = 20;
            d2.EBH_DealRetailCampaign__c = dsa1.Id;
            d2.EBH_DealSiteId__c = '0';
            d2.EBH_DealStartDate__c = dsa1.EBH_Date__c;
            d2.EBH_DealStartTime__c = startTime;
            d2.EBH_Dealdateearliestpossible__c = dsa1.EBH_Date__c;
            d2.EBH_ProductTitle__c = 'Deal Test 1';
            d2.EBH_Quantity__c = 500;
            d2.EBH_RRPWASPrice__c = 100;
            d2.EBH_SellerEmail__c = con.Email;
            d2.EBH_SellerPrice__c = 200;
            d2.EBH_eBayItemID__c = '100000000002';
            d2.Seller_Contact__c = con.Id;
            lstDeal.add(d2);
            
            Map<String,Object> mResultSubmit = (Map<String,Object>) ClsBulkUploadCSV.doSubmitMultipleDeals(lstDeal, user1.Contact.AccountId);
            //System.debug('>>>>>>> mResultSubmit:'+ mResultSubmit);
            //mResult.put('status', 'success');
            //mResult.put('lstDeals', lstDeals);
            //mResult.put('message', 'The Deals are submited successfully!');
            //System.debug('error: '+mResultSubmit.get('message'));
            //lstDeal = (List<EBH_Deal__c>) mResultSubmit.get('lstDeals');
            
            System.assertEquals('Status:success', 'Status:'+mResultSubmit.get('status'));
            //System.assertEquals('total:2', 'total:'+lstDeal.size());
            System.assertEquals('message:The Deals are submitted successfully!', 'message:'+mResultSubmit.get('message'));

            //Map<String,Object> mResultClear = (Map<String,Object>) ClsBulkUploadCSV.doClearHalfCompleteDeals(lstDeal);
            //System.debug('>>>>>>> mResultClear:'+ mResultClear);

            //mResult.put('status', 'success');
            //mResult.put('message', 'The Deals are removed successfully!');
            //System.assertEquals('Status:success', 'Status:'+mResultClear.get('status'));
            //System.assertEquals('message:The Deals are removed successfully!', 'message:'+mResultClear.get('message'));

            



        }

        Map<String,Object> mResultDRC = (Map<String,Object>) ClsBulkUploadCSV.getDealRetailCampaign(dsa1.Id);
        // System.debug('>>>>>>> mResult:'+ mResultDRC.get('message'));
        System.assertEquals('Status:success', 'Status:'+mResultDRC.get('status'));
        System.assertEquals('message:The Deal Retail Campaign was retrived successfully!', 'message:'+mResultDRC.get('message'));

        //Map<String,Object> mResultDealOverlappingDate = (Map<String,Object>) ClsBulkUploadCSV.getDealOverlapDateDRC(dsa1.Id, 'DE - Seller Portal');
        Map<String,Object> mResultDealOverlappingDate = (Map<String,Object>) ClsBulkUploadCSV.getDealOverlapDateDRC(dsa1.Id, ''); //MN-10062024-US-0015298
        
        System.assertEquals('Status:success', 'Status:'+mResultDealOverlappingDate.get('status'));
        //The Deals were retrived successfully!
        System.assertEquals('message:The Deals were retrived successfully!', 'message:'+mResultDealOverlappingDate.get('message'));

        Test.stopTest();
        
    }
    
    @isTest 
    static void test_doSubmitMultipleCouponItems() {

        Coupon_Seller__c cs1 = [SELECT ID FROM Coupon_Seller__c LIMIT 1];

        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];
        
        /* MN-18102023-US-0012769: After we removed "without sharing" from ClsBulkUploadCSV, create records will based on current user's permission and since the ability 
                            to create Coupon-Co-Invest is enabled in eBay Seller Portal Community only, we cannot run as community user to test this functionality in test class context.
        Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'DE - Seller Portal'];
        
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];
        
        User user1 = new User(
                                Username = System.now().millisecond() + 'test12345@test.com',
                                ContactId = con.Id,
                                ProfileId = profile1.Id,
                                
                                Alias = 'test123',
                                Email = 'test12345xx@test.com',
                                EmailEncodingKey = 'UTF-8',
                                LastName = 'McTesty',
                                CommunityNickname = 'test12345',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US'
                                );
        insert user1;
        */
        

        
       
        Test.startTest(); 

        //System.runAs(user1) {

            List<Coupon_Co_Invest__c> lstCCI = new List<Coupon_Co_Invest__c>();

            lstCCI.add(new Coupon_Co_Invest__c(
                Coupon_Seller__c = cs1.Id,
                Seller_Name__c = acc.Id,
                Co_Invest__c = 10,
                CurrencyIsoCode = 'USD'
            ));

            Object result = ClsBulkUploadCSV.doSubmitMultipleCouponItems(lstCCI, 'Item Based');

            List<Coupon_Co_Invest__c> lstCCICreated = [SELECT Id FROM Coupon_Co_Invest__c];
            System.assert(!lstCCICreated.isEmpty(), 'There should be Coupon Co-Invest created.');

        //}
        
       
        Test.stopTest();
    }
    
    @isTest 
    static void test_doSubmitMultipleDealsForDCA() {

        Deal_Contract_Agreement__c dca = [SELECT ID FROM Deal_Contract_Agreement__c LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];
        Test.startTest(); 
            List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
            Date myDate = System.today().addDays(1);
			RecordType rt_PMdeal = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'PM_Deal');
            lstDeal.add(new EBH_Deal__c(EBH_eBayItemID__c  = '000000000010', Seller_Approver_1__c = con.Id,EBH_BusinessName__c =acc.ID,RecordTypeId=rt_PMdeal.Id,EBH_SellerPrice__c =20,EBH_DealPrice__c =5,EBH_Quantity__c =2,EBH_DealStartDate__c =myDate,EBH_DealEndDate__c =myDate,EBH_Status__c='New',EBH_DealSiteId__c = '0',EBH_Vertical__c = 'Home & Garden',EBH_Category__c ='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c ='product 1',EBH_SellerEmail__c ='sales@test.com',Deal_Contract_Agreement__c=dca.Id));
        
            Object result = ClsBulkUploadCSV.doSubmitMultipleDealsForDCA(lstDeal);
        Test.stopTest();
        List<EBH_Deal__c> lstDeal2 = [select id from EBH_Deal__c where Deal_Contract_Agreement__c =: dca.Id];
        System.assert(!lstDeal2.isEmpty());
    }
    
    @isTest 
    static void test_doLoadDCAUploadDeal() {
        Deal_Contract_Agreement__c dca = [SELECT ID FROM Deal_Contract_Agreement__c LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];
        Date myDate = System.today().addDays(1);
		RecordType rt_PMdeal = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'PM_Deal');
        EBH_Deal__c deal = new EBH_Deal__c(EBH_eBayItemID__c  = '000000000010', Seller_Approver_1__c = con.Id,EBH_BusinessName__c =acc.ID,RecordTypeId=rt_PMdeal.Id,EBH_SellerPrice__c =20,EBH_DealPrice__c =5,EBH_Quantity__c =2,EBH_DealStartDate__c =myDate,EBH_DealEndDate__c =myDate,EBH_Status__c='New',EBH_DealSiteId__c = '0',EBH_Vertical__c = 'Home & Garden',EBH_Category__c ='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c ='product 1',EBH_SellerEmail__c ='sales@test.com',Deal_Contract_Agreement__c=dca.Id);
        insert deal;
        Test.startTest(); 
        Map<String, Object> mResult = ClsBulkUploadCSV.doLoadDCAUploadDeal(dca.Id);
        Set<String> setDealItem = (Set<String>) mResult.get('dealItemIds');
        System.Assert(setDealItem.size()>0);
        Test.stopTest();
    }
    
    @isTest 
    static void test_doLoadCouponUploadItems(){
        Coupon_Seller__c cs = [select id from Coupon_Seller__c limit 1];
        Test.startTest(); 
        ClsBulkUploadCSV.doLoadCouponUploadItems(cs.Id);
        Test.stopTest();
        
    }
}