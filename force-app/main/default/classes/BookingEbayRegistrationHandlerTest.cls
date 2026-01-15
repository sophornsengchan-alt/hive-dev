/*********************************************************************************************************************************
@ Class:          BookingEbayRegistrationHandlerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0013565 - eBay Registration Handler for Call booking site.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.04.2023 / Sophal Noch / create class
@                 11.06.2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
@                 16.10.2024/ vadhanak voun / US-0015432 - ADS - Eligibility for Advertising program component
@                                           / disaled TestSetup on makeData method to avoid UNABLE_TO_LOCK_ROW when run test in combination with EbayRegistrationHandlerTest
*********************************************************************************************************************************/
@isTest(isParallel=false)
private class BookingEbayRegistrationHandlerTest {
    @TestSetup
    private static void makeData(){
       
        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        RecordType recSellerGroup = ApexUtil.getRecordTypeByName('Account', 'Seller_Portal_Group');
        Account portalAccount1;
        Contact contact1, contact2,contact3,contact4,contact5,contact6,contact7,contactGroup;

       User calenderlyUser = [Select Id, Calendly__CalendlyLink__c From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE AND Id NOT IN : admins LIMIT 1];
       System.runAs(admins[0]){
            calenderlyUser.Calendly__CalendlyLink__c = 'test.salesforce.com'; // in test class, use any url for now 
            update calenderlyUser;
       }

        System.runAs(admins[0])
        {

            portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id,
                Brand_Engagement_Lead__c = calenderlyUser.Id
            );

            Account portalAccount2 = new Account(
                Name = 'seller1DE',
                eBay_API_User_Id__c = 'seller1DE',
                RecordTypeId = recSeller.Id,
                //EBH_DealsProgram__c = 'Accepted',//LA:05-12-2023-US-0014231
                EBH_RevRollup__c  = 'DE',
                Seller_Portal_Beta_User__c =true,
                Brand_Engagement_Lead__c = calenderlyUser.Id
            );
            
            Account portalAccount3 = new Account(
                Name = 'seller2NA',
                eBay_API_User_Id__c = 'seller2NA',
                RecordTypeId = recSeller.Id,
                EBH_RevRollup__c  = 'US',
                EBH_PredictedStandard__c = 'ETRS',
                EBH_PositiveFeedback__c = 100,
                EBH_VeROViolation__c = false,
                EBH_LastSellDate__c = System.today().addDays(-5),
                EBH_FeedbackScore__c = 3000,
                EBH_StoreSubscription__c = 'Anchor',
                EBH_ActualStandard__c = 'ETRS',
                EBH_GMVLast12Months__c = 70000,
                Brand_Engagement_Lead__c = calenderlyUser.Id

            );
            Account portalAccount4 = new Account(
                Name = 'seller2NA2',
                eBay_API_User_Id__c = 'seller2NA2',
                RecordTypeId = recSeller.Id,
                EBH_RevRollup__c  = 'US',
                EBH_PredictedStandard__c = 'ETRS',
                EBH_PositiveFeedback__c = 100,
                EBH_VeROViolation__c = false,
                EBH_LastSellDate__c = System.today(),
                EBH_FeedbackScore__c = 3000,
                EBH_StoreSubscription__c = 'Anchor',
                EBH_ActualStandard__c = 'ETRS',
                EBH_GMVLast12Months__c = 70000,
                Brand_Engagement_Lead__c = calenderlyUser.Id

            );
            Account portalAccount5 = new Account(
                Name = 'seller2AU',
                eBay_API_User_Id__c = 'seller2AU',
                RecordTypeId = recSeller.Id,
                EBH_RevRollup__c  = 'AU',
                EBH_PredictedStandard__c = 'ETRS',
                EBH_PositiveFeedback__c = 100,
                EBH_VeROViolation__c = false,
                EBH_LastSellDate__c = System.today(),
                EBH_FeedbackScore__c = 3000,
                EBH_StoreSubscription__c = 'Anchor',
                EBH_ActualStandard__c = 'ETRS',
                EBH_GMVLast12Months__c = 70000,
                Brand_Engagement_Lead__c = calenderlyUser.Id

            );
            // Account for SSO
            Account portalSSOAccountGroup = new Account(
                Name = 'TestGroup',
                RecordTypeId = recSellerGroup.Id
            );
            insert portalSSOAccountGroup;
            Account portalSSOAccount1 = new Account(
                Name = 'apiSSOid',
                eBay_API_User_Id__c = 'apiSSOid',
                RecordTypeId = recSeller.Id,
                //EBH_DealsProgram__c = 'Accepted', //LA:05-12-2023-US-0014231
                EBH_RevRollup__c  = 'DE',
                Seller_Portal_Beta_User__c =true,
                Seller_Portal_Group__c = portalSSOAccountGroup.Id,
                Brand_Engagement_Lead__c = calenderlyUser.Id
            );
            Account portalSSOAccount2 = new Account(
                Name = 'apiSSOid2',
                //eBay_API_User_Id__c = 'apiSSOid2',
                RecordTypeId = recSeller.Id,
                //EBH_DealsProgram__c = 'Accepted',//LA:05-12-2023-US-0014231
                EBH_RevRollup__c  = 'DE',
                Seller_Portal_Beta_User__c =true,
                Brand_Engagement_Lead__c = calenderlyUser.Id
            );
            
            
            insert new List<Account>{portalAccount1,portalAccount2,portalAccount3,portalAccount4,portalAccount5,portalSSOAccount1,portalSSOAccount2};

            //Create contact
            contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com'
            );
            contact2 = new Contact(
                FirstName = 'Test',
                Lastname = 'test contact 002',
                AccountId = portalAccount2.Id,
                Email = System.now().millisecond() + 'test002@test.com'
            );
            contact3 = new Contact(
                FirstName = 'Test',
                Lastname = 'test contact 003',
                AccountId = portalAccount3.Id,
                Email = System.now().millisecond() + 'test003@test.com'
            );
            contact4 = new Contact(
                FirstName = 'Test',
                Lastname = 'test contact 004',
                AccountId = portalAccount4.Id,
                Email = System.now().millisecond() + 'test004@test.com'
            );
            contact5 = new Contact(
                FirstName = 'de',
                Lastname = 'testSSO',
                AccountId = portalSSOAccount1.Id,
                Email = System.now().millisecond() + 'testsso1@test.com'
            );
            contact6 = new Contact(
                FirstName = 'de',
                Lastname = 'testSSO2',
                AccountId = portalSSOAccount2.Id,
                Email = System.now().millisecond() + 'testsso2@test.com'
            );
            contact7 = new Contact(
                FirstName = 'Test',
                Lastname = 'test contact 007',
                AccountId = portalAccount5.Id,
                Email = System.now().millisecond() + 'test007@test.com'
            );
            contactGroup = new Contact(
                FirstName = 'de',
                Lastname = 'testSSO',
                AccountId = portalSSOAccountGroup.Id,
                Email = System.now().millisecond() + 'testsso2@test.com'
            );
            insert new Contact[]{contact1,contact2,contact3,contact4,contact5,contact6,contact7,contactGroup};

            RecordType rtBob_Adv = ApexUtil.getRecordTypeByName('BOB__c','Advertising_Cohort');
            BoB__c bob = new BoB__c(RecordtypeId = rtBob_Adv.Id,Status__c='BoB Active',
                EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',Managed_Type__c ='Advertising');
            insert bob;

            RecordType rtBS_Adv = ApexUtil.getRecordTypeByName('BoB_Seller__c','Advertising');
            BoB_Seller__c bs1 = new BoB_Seller__c(RecordTypeId = rtBS_Adv.Id, Account_Manager__c=UserInfo.getUserId(),
                Status__c='Draft',Seller__c=portalAccount1.Id,
                 Ads_Partner_Manager__c = calenderlyUser.Id,
                BoB__c = bob.Id);

            BoB_Seller__c bs2 = new BoB_Seller__c(RecordTypeId = rtBS_Adv.Id, Account_Manager__c=UserInfo.getUserId(),
                Status__c='Draft',Seller__c=portalAccount2.Id,
                Ads_Partner_Manager__c = calenderlyUser.Id,
                BoB__c = bob.Id);

            BoB_Seller__c bs3 = new BoB_Seller__c(RecordTypeId = rtBS_Adv.Id, Account_Manager__c=UserInfo.getUserId(),
                Status__c='Draft',Seller__c=portalAccount3.Id,
                Ads_Partner_Manager__c = calenderlyUser.Id,
                BoB__c = bob.Id);

            BoB_Seller__c bs4 = new BoB_Seller__c(RecordTypeId = rtBS_Adv.Id, Account_Manager__c=UserInfo.getUserId(),
                Status__c='Draft',Seller__c=portalAccount4.Id,
                Ads_Partner_Manager__c = calenderlyUser.Id,
                BoB__c = bob.Id);
            
            BoB_Seller__c bs5 = new BoB_Seller__c(RecordTypeId = rtBS_Adv.Id, Account_Manager__c=UserInfo.getUserId(),
                Status__c='Draft',Seller__c=portalAccount5.Id,
                Ads_Partner_Manager__c = calenderlyUser.Id,
                BoB__c = bob.Id);

                //////
            BoB_Seller__c bs6 = new BoB_Seller__c(RecordTypeId = rtBS_Adv.Id, Account_Manager__c=UserInfo.getUserId(),
                Status__c='Draft',Seller__c=portalSSOAccount1.Id,
                Ads_Partner_Manager__c = calenderlyUser.Id,
                BoB__c = bob.Id);

            BoB_Seller__c bs7 = new BoB_Seller__c(RecordTypeId = rtBS_Adv.Id, Account_Manager__c=UserInfo.getUserId(),
                Status__c='Draft',Seller__c=portalSSOAccount2.Id,
                Ads_Partner_Manager__c = calenderlyUser.Id,
                BoB__c = bob.Id);
            insert new List<BoB_Seller__c>{bs1,bs2,bs3,bs4,bs5,bs6,bs7};  
                         
        }

        // System.runAs(admins[1])
        // {
        //     //Create user
        //     User user1 = SEPTestGenerator.prepareCommunityUserRecord('sepNAberh1', contact1.Id, null);
        //     User user2 = SEPTestGenerator.prepareCommunityUserRecord('sepNAberh2', contact3.Id, null);
        //     User user3 = SEPTestGenerator.prepareCommunityUserRecord('sepNAberh3', contact4.Id, null);
        //     User user4 = SEPTestGenerator.prepareCommunityUserRecord('sepNAberh4', contactGroup.Id, null);
        //     User user5 = SEPTestGenerator.prepareCommunityUserRecord('sepNAberh5', contact6.Id, null);

        //     insert new User[]{user1,user2,user3};             
        // }  
 
    }

    @isTest
    private static void bookingEbayRegistrationHandlerTest2() {       
        Test.startTest();

            BookingEbayRegistrationHandler handler = new BookingEbayRegistrationHandler();

            Set<String> sPSGDevName = new Set<String>{'Bookings_Portal'};
            for (PermissionSetGroup psg : [select Id, Status from PermissionSetGroup where DeveloperName IN:sPSGDevName]){
                // force calculation of the PSG if it is not already Updated
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }
            }
            //create user DE
            Auth.UserData sampleData = new Auth.UserData('seller1DE', 'testFirst2', 'seller1DE','testFirst testLast', 'testuser2_seller1DE@example2.org', 'seller1DE', 'seller1DE', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            User newUser = handler.createUser(null, sampleData);
            System.assert(newUser.Permission_Sets__c.contains('Bookings_Portal'),'user is eligible for booking portal');

            //create user NA
            Auth.UserData sampleDataNA = new Auth.UserData('seller2NA', 'testFirst2', 'seller2NA','testFirst testLast', 'testuser2_seller1DE@example2.org', 'seller2NA', 'seller2NA', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            User newUserNA = handler.createUser(null, sampleDataNA);  
            
            //create user AU
            Auth.UserData sampleDataAU = new Auth.UserData('seller2AU', 'testFirst2', 'seller2AU','testFirst testLast', 'testuser2_seller1AU@example2.org', 'seller2AU', 'seller2AU', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            User newUserAU = handler.createUser(null, sampleDataAU);  
            
            //reactivate user NA
            Auth.UserData sampleDataNA2 = new Auth.UserData('seller2NA2', 'testFirst2', 'seller2NA2','testFirst testLast', 'testuser2_seller1DE@example2.org', 'seller2NA2', 'seller2NA2', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            User newUserNA2 = handler.createUser(null, sampleDataNA2);
            
        Test.stopTest(); 
    }
    @isTest
    private static void bookingEbayRegistrationHandlerTestAC1() {
        Test.startTest();

            BookingEbayRegistrationHandler handler = new BookingEbayRegistrationHandler();

            //create user DE
            Auth.UserData sampleData = new Auth.UserData('apiSSOid1', 'test', 'apiSSOid1','test', 'testsso_apiSSOid1@example2.org', 'apiSSOid1', 'apiSSOid1', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            // AC1
            try{
                User newUser = handler.createUser(null, sampleData);
            }catch(Exception e){
                //System.assertEquals('Sorry your Account was not found! Please ensure you are using a Business Account to use the Seller Portal.',e.getMessage()); //MN-11062024-0015298
                System.assert(String.isNotBlank(e.getMessage()), 'There should be an error message.');
            }
        Test.stopTest();
    }
    @isTest
    private static void bookingEbayRegistrationHandlerTest3() {
        Test.startTest();

            BookingEbayRegistrationHandler handler = new BookingEbayRegistrationHandler();
            List<Account> lstAcc = new List<Account>();
            for(Account acc: [Select Id,Name,eBay_API_User_Id__c,Seller_Portal_Group__c FROM Account Where Name = 'apiSSOid' or Name = 'apiSSOid2' or Name ='TestGroup']){
                acc.eBay_API_User_Id__c = acc.Name;  
                lstAcc.add(acc);
            }
            update lstAcc;
            //create user DE
            Auth.UserData sampleData = new Auth.UserData('apiSSOid2', 'test', 'apiSSOid2','test', 'testsso_apiSSOid2@example2.org', 'apiSSOid2', 'apiSSOid2', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            User newUser = handler.createUser(null, sampleData);
            
        Test.stopTest();
    }
}