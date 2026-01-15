@isTest
private without sharing class BannerCardControllerTest {
    
    
    private static List<EBH_Deal__c> deals = new List<EBH_Deal__c>();
    private static Deal_Statement_Setting__c setting = new Deal_Statement_Setting__c();
     @testSetup
    static void setup(){
    	setting.Initial_Payout__c=0.60;
    	setting.Amount_Held_Back__c=0.40;
    	setting.Deal_Statement_Owner__c = 'Deals_BU_team';
    	insert setting;
        Account acc = new Account(Name='Test Account Name: 1', BillingCountry='CH');
        insert acc;
        Account eBaySeller1 = new Account (Name='Trigg Digital Ltd',EBH_OracleID__c='12345');
        Account eBaySeller2 = new Account (Name='Test eBaySeller For Doc Approve 2',EBH_OracleID__c='12346');
        Account eBaySeller3 = new Account (Name='Test eBaySeller For Doc Approve 3',EBH_OracleID__c='12347');
        insert new List<Account>{eBaySeller1,eBaySeller2,eBaySeller3};
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller1.Id);
        Contact contact2 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test2',
                                      email='test2@test.com' , AccountId = eBaySeller2.Id);
        insert new List<Contact>{contact1,contact2};
        Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
        dealTimezone.TimeZone__c='America/Los_Angeles';     
        insert dealTimezone;
        EBH_SpotlightCategory__c spotCat = new EBH_SpotlightCategory__c(Name = 'test spotLightCat',EBH_Country__c='NA',EBH_SpotlightCategoryID__c='testSpotId');
        insert spotCat;
        Id devRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2').Id;
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c();
        insert ndca;
        Time t = System.now().time();
        Date myDate = System.Today();
        integer i=0;
        Time startTime = t.addHours(2);
        Time endTime = t.addHours(3);
        deals = new List<EBH_Deal__c>();
            EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i++, 
            Seller_Approver_1__c = contact1.Id,
            EBH_BusinessName__c=eBaySeller1.ID,
            EBH_SpotlightCategory__c = spotCat.Id,
            RecordTypeId=devRecordTypeId,
            EBH_SellerPrice__c=20,
            EBH_Quantity__c=2,
            EBH_SoldItems__c=2,
            Final_Sold_Items__c=5,
            EBH_DealPrice__c =10,
            EBH_DealStartDate__c=myDate,
            EBH_DealStartTime__c =  startTime,
            EBH_DealEndDate__c=myDate,
            EBH_DealEndTime__c = endTime,
            EBH_Status__c='Running',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
            Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id,
            EBH_DealSiteId__c = '77',
            EBH_MaximumPurchases__c = 2);

            deals.add( d1);
            
            EBH_Deal__c d2 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i++, 
            Seller_Approver_1__c = contact1.Id,
            EBH_BusinessName__c=eBaySeller2.ID,
            EBH_SpotlightCategory__c = spotCat.Id,
            RecordTypeId=devRecordTypeId,
            EBH_SellerPrice__c=20,
            EBH_Quantity__c=5,
            EBH_DealPrice__c =10,
            EBH_DealStartDate__c=myDate,
            EBH_DealStartTime__c =  startTime,
            EBH_DealEndDate__c=myDate,
            EBH_DealEndTime__c = startTime,           
            EBH_SoldItems__c=5,
            Final_Sold_Items__c=5,
            EBH_Status__c='Running',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
            Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id,
            EBH_DealSiteId__c = '77',
            EBH_MaximumPurchases__c = 2);
            deals.add( d2);
            
            EBH_Deal__c d3 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i, 
            Seller_Approver_1__c = contact1.Id,
            EBH_BusinessName__c=eBaySeller3.ID,
            EBH_SpotlightCategory__c = spotCat.Id,
            RecordTypeId=devRecordTypeId,
            EBH_SellerPrice__c=20,
            EBH_Quantity__c=5,         
            EBH_SoldItems__c=5,
            Final_Sold_Items__c=5,
            EBH_DealStartDate__c=myDate,
            EBH_DealPrice__c =5,
            EBH_DealStartTime__c =  startTime,
            EBH_DealEndDate__c=myDate,
            EBH_DealEndTime__c = startTime,
            EBH_Status__c='Running',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
            Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id,
            EBH_DealSiteId__c = '77',
            EBH_MaximumPurchases__c = 2);     
            deals.add( d3);
            
            EBH_Deal__c d4 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000002'+i, 
            Seller_Approver_1__c = contact1.Id,
            EBH_BusinessName__c=eBaySeller3.ID,
            EBH_SpotlightCategory__c = spotCat.Id,
            RecordTypeId=devRecordTypeId,
            EBH_SellerPrice__c=20,
            EBH_Quantity__c=5,         
            EBH_SoldItems__c=5,
            Final_Sold_Items__c=5,
            EBH_DealStartDate__c=myDate,
            EBH_DealPrice__c =5,
            EBH_DealStartTime__c =  startTime,
            EBH_DealEndDate__c=myDate,
            EBH_DealEndTime__c = startTime,
            EBH_Status__c='Running',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
            Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id,
            EBH_DealSiteId__c = '77',
            EBH_MaximumPurchases__c = 2);
            deals.add(d4);
            insert deals;
    }

    @IsTest
    static void testCountDeal(){
        
        Test.startTest();       
        
        String dealNumber = BannerCardController.initCountDeal('7');       

        System.assert(Integer.ValueOf(dealNumber) > 0);
        
        Test.stopTest();
        
    }

    @isTest 
    static void test_Count() {
        Test.startTest();
        BannerCardController.retWrapper rw =  BannerCardController.getCount('2', 'EBH_Deal__c');     
        System.assertEquals('1', rw.dealCount);
        BannerCardController.retWrapper rw1 =  BannerCardController.getCount('2', 'Coupon__c');
        System.assertEquals('0', rw1.dealCouponSeller);

        Test.stopTest();
    }
}