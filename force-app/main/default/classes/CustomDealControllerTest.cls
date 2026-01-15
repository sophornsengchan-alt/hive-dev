/**
 * @description Test unit for cover code in CustomDealController class
 * @date        23/07/2021
 * @author      Samnang MUONG
 
 @ Change history: 30.09.2022/ Chetra Sarom / US-0012482 - Fix failing test class CustomDealControllerTest
 */

@isTest(seeAllData = False)
private with sharing class CustomDealControllerTest {
    private static List<EBH_Deal__c> deals = new List<EBH_Deal__c>();
    private static Deal_Statement_Setting__c setting = new Deal_Statement_Setting__c();
    
    // @ Change history: 30.09.2022/ Chetra Sarom / US-0012482 - Fix failing test class CustomDealControllerTest
     @testSetup
    static void setup(){
        User[] admins = [Select Id,Name From User Where Profile.Name='System Administrator' AND isActive=TRUE and UserRoleId <> null LIMIT 2];
        //User user2 ;
        Account eBaySeller1,eBaySeller3,eBaySeller2;
        Contact contact1,contact2;
        Profile NA_Profile,DE_Profile;

        System.runAs(admins[0]) {

            eBaySeller1 = new Account (Name='Test eBaySeller For Doc Approve 1', SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA, EBH_OracleID__c='12345',NA_Deal_Program_Vetted__c=true,NA_Deals_Subsidy_PayPal_Email__c ='ttt@ttt.com');
            eBaySeller2 = new Account (SP_Main_Domain__c = SEP_Helper.SEP_Domain_DE, Name='Test eBaySeller For Doc Approve 2',EBH_OracleID__c='12346',NA_Deal_Program_Vetted__c=true, SP_Deals__c = 'Full Access');
            eBaySeller3 = new Account (SP_Main_Domain__c = SEP_Helper.SEP_Domain_DE, Name='Test eBaySeller For Doc Approve 3',EBH_OracleID__c='12347',NA_Deal_Program_Vetted__c=true);
            insert new List<Account>{eBaySeller1,eBaySeller2,eBaySeller3};

            contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                        email='test1@test.com' , AccountId = eBaySeller1.Id,Contact_Role__c='Deals');
            contact2 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test2',
                                      email='test2@test.com' , AccountId = eBaySeller2.Id);
            insert new List<Contact>{contact1,contact2};
                
            //user2 = SEPTestGenerator.prepareCommunityUserRecord('sepUser2', contact2.Id, null); //MN-10062024-US-0015298
            //insert new List<User>{user2};
        }

        System.runAs(admins[1]) {
            setting.Initial_Payout__c=0.60;
            setting.Amount_Held_Back__c=0.40;
            setting.Deal_Statement_Owner__c = 'Deals_BU_team';
            insert setting;
            Account acc = new Account(Name='Trigg Digital Ltd', BillingCountry='CH');
            insert acc;
            AccountContactRelation acr1 =  new AccountContactRelation(ContactId=contact1.Id,AccountId=acc.Id,IsActive=True);
            AccountContactRelation acr2 =  new AccountContactRelation(ContactId=contact2.Id,AccountId=acc.Id,IsActive=True);
            AccountContactRelation acr3 = new AccountContactRelation(ContactId=contact2.Id,AccountId=eBaySeller3.Id, isActive=true);
            insert new List<AccountContactRelation>{acr1, acr2,acr3};
            
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
            // 30.09.2022/ Chetra Sarom / US-0012482
            EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_DealSiteId__c = '0',    
            EBH_MaximumPurchases__c = 2,
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
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);

            deals.add( d1);
            
            EBH_Deal__c d2 = new EBH_Deal__c(
            EBH_DealSiteId__c = '0',    
            EBH_MaximumPurchases__c = 2,    
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
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);
            deals.add( d2);
            
            EBH_Deal__c d3 = new EBH_Deal__c(
            EBH_DealSiteId__c = '0',    
            EBH_MaximumPurchases__c = 2,    
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
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);     
            deals.add( d3);
            
            EBH_Deal__c d4 = new EBH_Deal__c(
            EBH_DealSiteId__c = '0',    
            EBH_MaximumPurchases__c = 2,
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
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);
            deals.add(d4);

            EBH_Deal__c d5 = new EBH_Deal__c( 
                EBH_MaximumPurchases__c = 2,
                EBH_eBayItemID__c = '009988770001', 
                Seller_Approver_1__c = contact2.Id,
                EBH_BusinessName__c=eBaySeller2.ID,
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
                EBH_DealSiteId__c  = '77',
                EBH_ReasonforRejection__c = 'Preis zu hoch, Fehlende oder falsche Angaben',
                EBH_Status__c='Rejected',
                EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
                Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
                EBH_SellerEmail__c='sales@test.com'
                //OwnerId = user2.Id
                );            
            deals.add(d5);
            insert deals;

    }

            
    }

    

    @IsTest
    static void test_getAccountIdUser(){
        Contact cont1 = [SELECT Id From Contact where LastName = 'test1' LIMIT 1];
        User user1 = SEPTestGenerator.prepareCommunityUserRecord('sepUser1', cont1.Id, null);
        Test.startTest();

        System.runAs(user1) {
            
            String accId = CustomDealController.getAccountIdUser();
            System.assert(String.isNotBlank(accId));
         //   System.assert(String.isNotBlank(accId));
        }
        
       
        Test.stopTest();
        
    }

    @IsTest
    static void test_getExistingDeals(){
        
        Test.startTest();

        List<EBH_Deal__c> lstDeals = CustomDealController.getExistingDeals('product 1', 'EBH_ProductTitle__c', 'ASC');
      
        System.assert(!lstDeals.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void test_getDuplicatedDeals(){
        
        Test.startTest();
        
        Object mResult = CustomDealController.getDuplicateEbayItemID('', '');
      
        //System.assertEquals(mResult[0]['status'],'success');

        Test.stopTest();
    }

    @isTest 
    static void test_InitData() {
        Test.startTest();
        String jsonRes = CustomDealController.initData();
        System.assert(String.isNotBlank(jsonRes));
        Test.stopTest();
    }

    @IsTest
    static void testApexUpdateDeal()
    {
        //User de_PortalUser = [SELECT Id FROM User WHERE Profile.Name = 'DE - Seller Portal' and IsActive=true and Email='testQ123@test.com' LIMIT 1]; //MN-10062024-US-0015298
        
        Contact cont = [Select Id From Contact Where Email = 'test2@test.com' LIMIT 1]; //MN-10062024-US-0015298
        //User de_PortalUser = [SELECT Id FROM User WHERE ContactId=:cont.Id and IsActive=true LIMIT 1]; //MN-10062024-US-0015298
        User de_PortalUser = SEPTestGenerator.prepareCommunityUserRecord('sepUser2', cont.Id, null);            
        Test.startTest();
            
        //system.debug('--de_PortalUser: '+de_PortalUser);

            System.runAs(de_PortalUser) 
            {
                EBH_Deal__c deal2 = [Select Id From  EBH_Deal__c deal2 Where EBH_eBayItemID__c='009988770001' Limit 1];
                
                Map<String,Object> mapResult = CustomDealController.apexUpdateDeal(deal2, false);
                system.debug( '--mapResult: '+ mapResult );    
            
            
                EBH_Deal__c d = [Select Id,EBH_Status__c,EBH_ReasonforRejection__c FROM EBH_Deal__c WHERE Id=:deal2.Id];
        
                System.assertEquals('New', d.EBH_Status__c,'reset to New after resubmit');
                System.assertEquals(null, d.EBH_ReasonforRejection__c,'clear reason after resubmit');
            }            
            
        Test.stopTest();
    }

    @IsTest
    static void testGetSelectedCategories()
    {                    
        Test.startTest();
        List<String> lstString = CustomDealController.getSelectedCategories();
        Test.stopTest();
        System.assert(!lstString.isEmpty());
    }
   
    @IsTest
    static void testGetTodayDealSetting()
    {   
        Id dealRetailCampaignRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', 'Deal_Campaign_V2').Id;
        Date myDate = System.Today();
        
        //User de_PortalUser = [SELECT Id FROM User WHERE Profile.Name = 'DE - Seller Portal' and IsActive=true and Email='testQ123@test.com' LIMIT 1];

        Contact cont = [Select Id From Contact Where Email = 'test2@test.com' LIMIT 1]; //MN-10062024-US-0015298
        //User de_PortalUser = [SELECT Id FROM User WHERE ContactId=:cont.Id and IsActive=true LIMIT 1]; //MN-10062024-US-0015298
		User de_PortalUser = SEPTestGenerator.prepareCommunityUserRecord('sepUser2', cont.Id, null);  
        /*
        Account acc = new Account( Name = 'TestAccount' );
        insert acc;
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,FirstName='test fn', LastName='test ln', AccountId=acc.Id);
        insert con;
        */

        Map<String, Object> mResult = new Map<String, Object>();
        Test.startTest();
        System.runAs(de_PortalUser) {
            EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(Focus_Categories__c = 'Electronics', EBH_Date__c = myDate, EPH_EndDate__c = myDate, EBH_Country__c = '0', EBH_OpenSeatsAvailable__c=10 );
            insert dsa1;
            mResult = (Map<String, Object>) CustomDealController.getTodayDealSetting(dsa1.Id); 
        }
        Test.stopTest();
        System.assertEquals('Status:success', 'Status:'+mResult.get('status'));
    } 

    @IsTest
    static void test_getTodayDEDealSetting()
    {   
        Id dealRetailCampaignRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', 'Deal_Campaign_V2').Id;
        Date myDate = System.Today();
        
        //User de_PortalUser = [SELECT Id FROM User WHERE Profile.Name = 'DE - Seller Portal' and IsActive=true and Email='testQ123@test.com' LIMIT 1];
        Contact cont = [Select Id,AccountId From Contact Where Email = 'test2@test.com' LIMIT 1]; //MN-10062024-US-0015298
        //User de_PortalUser = [SELECT Id FROM User WHERE ContactId=:cont.Id and IsActive=true LIMIT 1]; //MN-10062024-US-0015298
		User de_PortalUser = SEPTestGenerator.prepareCommunityUserRecord('sepUser2', cont.Id, null);  
        /*Account acc = new Account( Name = 'TestAccount' );
        insert acc;
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,FirstName='test fn', LastName='test ln', AccountId=acc.Id);
        insert con;*/
        Map<String, Object> mResult = new Map<String, Object>();
        Test.startTest();
        System.runAs(de_PortalUser) {
            EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(Focus_Categories__c = 'Electronics', EBH_Date__c = myDate, EPH_EndDate__c = myDate, EBH_Country__c = '0', EBH_OpenSeatsAvailable__c=10 );
            insert dsa1;
            mResult = (Map<String, Object>) CustomDealController.getTodayDEDealSetting(dsa1.Id, cont.AccountId); 
        }
        Test.stopTest();
        System.assertEquals('Status:success', 'Status:'+mResult.get('status'));
    }

    @IsTest
    static void testGetLinkedAccSpDeal()
    {   
        User[] admins = [Select Id,Name From User Where Profile.Name='System Administrator' AND isActive=TRUE and UserRoleId <> null LIMIT 2];

        // 03.04.2022 / Sophal Noch / US-0011156
        //User user2 = [SELECT Id,ContactId,Contact.AccountId FROM User WHERE IsActive = true And Email='testQ123@test.com' LIMIT 1]; //MN-11062024-US-0015298
        //User user2 = [SELECT Id,ContactId,Contact.AccountId FROM User WHERE IsActive = true And Contact.LastName='test2' LIMIT 1]; //MN-11062024-US-0015298
		Contact cont = [Select Id From Contact Where Email = 'test2@test.com' LIMIT 1];
        User user2 = SEPTestGenerator.prepareCommunityUserRecord('sepUser2', cont.Id, null);  
        Account eBaySeller2 = [Select Id,SP_Deals__c from Account Where EBH_OracleID__c = '12346'];
        eBaySeller2.SP_Deals__c = 'Read Only';
        Account eBaySeller3 = [Select Id,SP_Deals__c from Account Where EBH_OracleID__c = '12347'];
        eBaySeller3.SP_Deals__c = 'Full Access';

        System.runAs(admins[0]) {
            update new List<Account>{eBaySeller2,eBaySeller3};
        }

        
        
        test.startTest();
            System.runAs(user2) {
                Map<String, Object> mResult = CustomDealController.getLinkedAccSpDeal();
                System.assertEquals(null,mResult.get('error'));
                System.assertEquals('ok', String.valueOf(mResult.get('status')));
                System.assertEquals(false, Boolean.valueOf(mResult.get('isHavingNoFullAccess')));
            }
        test.stopTest();
    }

    @IsTest
    static void testProcessDealCancellation()
    {
        //User de_PortalUser = [SELECT Id FROM User WHERE Profile.Name = 'DE - Seller Portal' and IsActive=true and Email='testQ123@test.com' LIMIT 1]; //MN-10062024-US-0015298

        Contact cont = [Select Id From Contact Where Email = 'test2@test.com' LIMIT 1]; //MN-10062024-US-0015298
        //User de_PortalUser = [SELECT Id FROM User WHERE ContactId=:cont.Id and IsActive=true LIMIT 1]; //MN-10062024-US-0015298
		User de_PortalUser = SEPTestGenerator.prepareCommunityUserRecord('sepUser2', cont.Id, null);                      
        EBH_Deal__c deal2 = [Select Id From  EBH_Deal__c deal2 Where EBH_eBayItemID__c='009988770001' Limit 1];
        Test.startTest();
            
        //system.debug('--de_PortalUser: '+de_PortalUser);

            System.runAs(de_PortalUser) 
            {
                
                Map<String,Object> mapResult = CustomDealController.processDealCancellation(deal2.Id, 'Test Cancel Reason.');
                system.debug( '--mapResult: '+ mapResult );    
            
            }       
        	EBH_Deal__c d = [Select Id,EBH_Status__c,Seller_Cancellation_Reason__c FROM EBH_Deal__c WHERE Id=:deal2.Id];
        
        System.assertEquals('Seller Cancelled', d.EBH_Status__c,'Status should be Seller Cancelled');
        System.assertEquals('Test Cancel Reason.', d.Seller_Cancellation_Reason__c,'Test Cancel Reason.');
            
        Test.stopTest();
    }
}