/*********************************************************************************************************************************
@ Class:          SEPToDoListController
@ Author:         Patrick Duncan | patrick@triggdigital.com
@ Purpose:        US-0011799 - Refactor to-do list within Seller Portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13/06/22 Patrick Duncan / Created test class for use by SEPToDoListController
*********************************************************************************************************************************/
@isTest
public with sharing class SEPToDoListControllerTest {
    public static final String DE_DEALS_AGGREGATE_METADATA_NAME = 'Deals_Aggregate_DE';
    public static final String DE_COUPONS_AGGREGATE_METADATA_NAME = 'Coupons_Aggregate_DE';


    @TestSetup
    static void makeData(){
        User admin = [Select Id,Name From User Where Profile.Name='System Administrator' AND isActive = TRUE and UserRoleId <> null LIMIT 1];
        System.runAs(admin) {
            Profile DE_Profile = ApexUtil.getProfileByName('DE - Seller Portal');

            Account account = new Account (Name='Test eBaySeller For Doc Approve 1',EBH_OracleID__c='12345',NA_Deal_Program_Vetted__c=true,NA_Deals_Subsidy_PayPal_Email__c ='ttt@ttt.com', SP_Deals__c='Full Access', EBH_RevRollup__c='DE', SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
            insert account;
            Contact contact = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',FirstName='firstname',Salutation='Mr.',LastName='test1',Email='test1@test.com' , AccountId = account.Id,Contact_Role__c='Deals');
            insert contact;

            
            User user = new User(Username = System.now().millisecond() + 'test_12345@testbb.com',ContactId = contact.Id, ProfileId = DE_Profile.Id,Alias = 'test123',Email = 'test12345xx@test.com',EmailEncodingKey = 'UTF-8',LastName = 'McTesty',CommunityNickname = 'test12345',TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',LanguageLocaleKey = 'en_US');
            insert user;

            EBH_SpotlightCategory__c spotlightCategory = new EBH_SpotlightCategory__c(Name = 'test spotLightCat',EBH_Country__c='NA',EBH_SpotlightCategoryID__c='testSpotId');
            insert spotlightCategory;

            Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c();
            insert ndca;

            Id devRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2').Id;

            List<EBH_Deal__c> dealsToInsert = new List<EBH_Deal__c>();
            for(Integer i=0;i<8;i++){
                EBH_Deal__c deal;
                if(i < 2){
                    deal = createDeal(i, contact, account, spotlightCategory, devRecordTypeId, ndca, 'Resubmission');
                }
                else if(i < 4){
                    deal = createDeal(i, contact, account, spotlightCategory, devRecordTypeId, ndca, 'Confirmation');
                }
                else if(i < 6){
                    deal = createDeal(i, contact, account, spotlightCategory, devRecordTypeId, ndca, 'Awaiting Upload');
                }
                else if(i < 8){
                    deal = createDeal(i, contact, account, spotlightCategory, devRecordTypeId, ndca, 'Requiring Id');
                }
                dealsToInsert.add(deal);
            }

            insert dealsToInsert;
        

            //String categoryBasedRecordTypeId = Schema.sObjectType.Coupon__c.getRecordTypeInfosByName().get('Seller / Category Based').getRecordTypeId();
            //String itemBasedRecordTypeId = Schema.sObjectType.Coupon__c.getRecordTypeInfosByName().get('Item Based').getRecordTypeId();
            String categoryBasedRecordTypeId = Schema.sObjectType.Coupon__c.getRecordTypeInfosByDeveloperName().get('Category_Based').getRecordTypeId();
            String itemBasedRecordTypeId = Schema.sObjectType.Coupon__c.getRecordTypeInfosByDeveloperName().get('Item_Based').getRecordTypeId();

            Coupon__c categoryCoupon = new Coupon__c(Coupon_ID__c = 'TestCoupon001', Coupon_Start_Time__c=System.Now().timeGmt(), Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), Coupon_Start_Date__c=System.Today(), Coupon_End_Date__c=System.Today().addDays(2),Main_Coupon_Site__c = 'ebay.de', Coupon_Co_invest_Type__c = 'Contra', RecordTypeId=categoryBasedRecordTypeId);

            Coupon__c itemCoupon = new Coupon__c(Coupon_ID__c = 'TestCoupon002', Coupon_Start_Time__c=System.Now().timeGmt(), Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), Coupon_Start_Date__c=System.Today(), Coupon_End_Date__c=System.Today().addDays(2),Main_Coupon_Site__c = 'ebay.de', Coupon_Co_invest_Type__c = 'Contra', RecordTypeId=itemBasedRecordTypeId);
            insert new List<Coupon__c>{categoryCoupon, itemCoupon};

            List<Coupon_Seller__c> couponSellersToInsert = new List<Coupon_Seller__c>();
            for(Integer i=0;i<10;i++){
                Coupon_Seller__c couponSeller;
                if(i < 5){
                    couponSeller = createCouponSeller(categoryCoupon, account, 'Ready for Signature');
                }
                else if(i < 10){
                    couponSeller = createCouponSeller(itemcoupon, account, 'Ready for Upload');
                }
                couponSellersToInsert.add(couponSeller);
            }

            insert couponSellersToInsert;
        }
        
    }

    public static EBH_Deal__c createDeal(Integer i, Contact contact, Account account, EBH_SpotlightCategory__c spotlightCategory, Id devRecordTypeId, Deal_Contract_Agreement__c ndca, String type){
        Time now = System.now().time();
        Date today = System.Today();
        Time startTime = now.addHours(2);
        Time endTime = now.addHours(3);                        
        EBH_Deal__c deal = new EBH_Deal__c(EBH_eBayItemID__c = '00000000001'+i, Seller_Approver_1__c = contact.Id,EBH_BusinessName__c=account.Id,EBH_SpotlightCategory__c = spotlightCategory.Id,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c=20,EBH_Quantity__c=2,EBH_SoldItems__c=2, Final_Sold_Items__c=5,EBH_DealPrice__c =10,EBH_DealStartDate__c=today,EBH_DealStartTime__c =  startTime,EBH_DealEndDate__c=today,EBH_DealEndTime__c = endTime,EBH_Status__c='Running',EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);
        if(type == 'Resubmission'){
            //Sambath Seng - 15/01/2024 - US-0013136
            // deal.Seller_Portal_Status__c = 'Deal proposal rejected';
            deal.EBH_Status__c  = 'Rejected';
            // deal.EBH_DealSiteId__c  = '77';
        }
        else if(type == 'Confirmation'){
            //Sambath Seng - 15/01/2024 - US-0013136
            // deal.Seller_Portal_Status__c = 'Please agree on the proposed Deal';
            deal.EBH_Status__c  = 'Planned';
        }
        else if(type == 'Awaiting Upload'){
            //Sambath Seng - 15/01/2024 - US-0013136
            // deal.Seller_Portal_Status__c = 'Please provide an invoice';
            deal.EBH_Status__c  = 'Statement Verified';
        }
        else if(type == 'Requiring Id'){
            //Sambath Seng - 15/01/2024 - US-0013136
            // deal.Seller_Portal_Status__c = 'New Deal proposed to eBay';
            deal.EBH_Status__c  = 'New';
            deal.EBH_eBayItemID__c = null;
            deal.EBH_DealStartDate__c = Date.today().addDays(7);
            deal.EBH_DealEndDate__c = Date.today().addDays(14);

        }

        deal.EBH_DealSiteId__c  = '77';
        deal.EBH_MaximumPurchases__c = 2;
        return deal;
    }

    public static Coupon_Seller__c createCouponSeller(Coupon__c coupon, Account account, String type){
        Coupon_Seller__c couponSeller = new Coupon_Seller__c(Coupon__c = coupon.Id, Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED, Seller__c=account.Id);
        if(type == 'Ready for Signature'){
            couponSeller.Coupon_Seller_Stage__c = 'Contract Send';
            couponSeller.Coupon_Type__c = 'Category Based';
        }
        else if(type == 'Ready for Upload'){
            String manhattanRecordTypeId = Schema.sObjectType.Coupon_Seller__c.getRecordTypeInfosByDeveloperName().get('Manhattan_Coupon').getRecordTypeId();
            couponSeller.RecordTypeId = manhattanRecordTypeId;
            couponSeller.Coupon_Seller_Stage__c = 'Contract Negotiation';
            couponSeller.Coupon_Type__c = 'Item Based';
        }
        return couponSeller;
    }

    @isTest
    public static void testDealToDoAggregate(){
        List<SEPToDoListController.ToDoListItemDTO> toDoListItems = SEPToDoListController.getToDoListItems(true, DE_DEALS_AGGREGATE_METADATA_NAME);
        System.assertEquals(1,toDoListItems.size(), 'There should be 1 aggregate/parent item returned');
        System.assertEquals(8,toDoListItems.get(0).count, 'There is 2 deals created for each category, 4 categories = 4*2=8');
    }

    @isTest
    public static void testDealsToDoChildRecords(){
        List<SEPToDoListController.ToDoListItemDTO> toDoListItems = SEPToDoListController.getToDoListItems(false, DE_DEALS_AGGREGATE_METADATA_NAME);
        System.assertEquals(4,toDoListItems.size(), 'There should be 4 child to do items returned');
        for(SEPToDoListController.ToDoListItemDTO toDoListItem:toDoListItems){
            System.assertEquals(2,toDoListItem.count,  'There is 2 deals created for each category');
        }
    }

    @isTest
    public static void testCouponToDoAggregate(){
        List<SEPToDoListController.ToDoListItemDTO> toDoListItems = SEPToDoListController.getToDoListItems(true, DE_COUPONS_AGGREGATE_METADATA_NAME);
        System.assertEquals(1,toDoListItems.size(), 'There should be 1 aggregate/parent item returned');
        System.assertEquals(10,toDoListItems.get(0).count, 'There is 5 coupon sellers created for each category, 2 categories = 5*2=10');
    }

    @isTest
    public static void testCouponsToDoChildRecords(){
        List<SEPToDoListController.ToDoListItemDTO> toDoListItems = SEPToDoListController.getToDoListItems(false, DE_COUPONS_AGGREGATE_METADATA_NAME);

        System.assertEquals(2,toDoListItems.size(), 'There should be 2 child to do items returned');
        for(SEPToDoListController.ToDoListItemDTO toDoListItem:toDoListItems){
            System.assertEquals(5,toDoListItem.count, 'There is 5 coupon sellers created for each category');
        }
    }
}