/*********************************************************************************************************************************
@ Class:          BatchDealPriceChangeAlertTest
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        Test class for Batch BatchDealPriceChangeAlert
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06-10-2022/ Mony Nou / Created test class
*********************************************************************************************************************************/
@isTest 
public with sharing class BatchDealPriceChangeAlertTest {
    

    @TestSetup
    static void setup(){


        User admin = [Select Id,Name From User Where Profile.Name='System Administrator' AND isActive = TRUE and UserRoleId <> null LIMIT 1];
        System.runAs(admin) {

            //Profile DE_Profile = ApexUtil.getProfileByName('DE - Seller Portal'); //MN-10062024-US-0015298

            Account account = new Account (Name='Test eBaySeller For Doc Approve 1',EBH_OracleID__c='12345',NA_Deal_Program_Vetted__c=true,NA_Deals_Subsidy_PayPal_Email__c ='ttt@ttt.com', SP_Deals__c='Full Access', EBH_RevRollup__c='DE', SP_Coupons__c='Full Access');
            insert account;
            Contact contact = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',FirstName='firstname',Salutation='Mr.',LastName='test1',Email='test1@test.com' , AccountId = account.Id,Contact_Role__c='Deals');
            insert contact;

            /* MN-10062024-US-0015298
            User user = new User(Username = System.now().millisecond() + 'test_12345@testbb.com',ContactId = contact.Id, ProfileId = DE_Profile.Id,Alias = 'test123',Email = 'test12345xx@test.com',EmailEncodingKey = 'UTF-8',LastName = 'McTesty',CommunityNickname = 'test12345',TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',LanguageLocaleKey = 'en_US');
            insert user;
            */

            User user = SEPTestGenerator.createSEPUser('sepUserbdpca1', contact.Id); //MN-10062024-US-0015298

            EBH_SpotlightCategory__c spotlightCategory = new EBH_SpotlightCategory__c(Name = 'test spotLightCat',EBH_Country__c='DE',EBH_SpotlightCategoryID__c='testSpotId');
            insert spotlightCategory;

            RecordType dealV1Rec = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V1')        ;

            EBH_Deal__c d1 = new EBH_Deal__c(Seller_Contact__c=contact.Id, EBH_Pricenotmatching__c=true,RecordTypeId=dealV1Rec.Id,EBH_BusinessName__c=account.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456789', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                    EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test', EBH_SpotlightCategory__c=spotlightCategory.Id,
                                    EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                    EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_Vertical__c='Fashion',EBH_DealSiteId__c='77', EBH_Status__c = 'Running');
            insert d1;

        }


    }

    @isTest 
    public static void test_batch() {

        Test.startTest();

            BatchDealPriceChangeAlert batch = new BatchDealPriceChangeAlert();
            Database.executebatch(batch,1);

        Test.stopTest();
    }

}