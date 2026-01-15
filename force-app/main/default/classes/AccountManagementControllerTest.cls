/*********************************************************************************************************************************
@ Class:          AccountManagementControllerTest
@ Version:        1.0
@ Author:         Sochettra Saing
@ Purpose:        Ability to run test the logic in class AccountManagementController(EBAY-749)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.10.2021 / Sochettra Saing / Created the class.
@                 10.06.2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
@                 02.07.2025 / Sophal Noch / US-0032963 - SP: Do not show Paid programs to GSD sellers
*********************************************************************************************************************************/

@isTest 
public with sharing class AccountManagementControllerTest {

    /*
    @testSetup
    static void setup(){
        //create an account
        Account acc = new Account( Name = 'TestAccount', EBH_StoreSubscription__c = 'Anchor', SP_Deals__c = 'Full Access', Store_Subscription_Site__c='Germany', Seller_Portal_Beta_User__c = true,EBH_RegistrationCountry__c = 'Germany');//Basic
        insert acc;
        Account acc2 = new Account( Name = 'TestAccount2', EBH_StoreSubscription__c = 'Anchor', SP_Deals__c = 'Full Access', Store_Subscription_Site__c='Germany', Seller_Portal_Beta_User__c = true,EBH_RegistrationCountry__c = 'Germany');//Basic
        insert acc2;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;

        AccountContactRelation acr =  new AccountContactRelation(ContactId=con.Id,AccountId=acc2.Id,IsActive=True);
        insert acr;

        //create Custom Setting record for EBH_ActiveTriggers__c
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller', Subscription_Request_Trigger__c = false);

        Profile adminProfile = [select Id,Name from Profile where Name = 'System Administrator'];
        Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'DE - Seller Portal'];

        User adminUser = new User();
        adminUser.Alias='admin';
        adminUser.Email='admintest@ebay.com';
        adminUser.EmailEncodingKey='UTF-8';
        adminUser.LastName='AdminUser';
        adminUser.LanguageLocaleKey='en_US';
        adminUser.LocaleSidKey='en_US';
        adminUser.ProfileId = adminProfile.Id;
        adminUser.TimeZoneSidKey='America/Los_Angeles';
        adminUser.UserName='adminprofile@ebay.com';
        
        User currentUser = [Select Id,Name from User where Id=: UserInfo.getUserId()];
        
        User user1 = new User(
                                Username = System.now().millisecond() + 'test12345@test.com',
                                ContactId = con.Id,
                                ProfileId = profile1.Id,
                                Alias = 'testU',
                                Email = 'test12345xx@test.com',
                                EmailEncodingKey = 'UTF-8',
                                LastName = 'McTesty',
                                CommunityNickname = 'test12345',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'de_DE',
                                LanguageLocaleKey = 'de'
                                );
        System.runAs(currentUser) {
            insert new List<User>{adminUser,user1};
        }
    }
    */

    @TestSetup
    static void makeData(){

        //create Custom Setting record for EBH_ActiveTriggers__c
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller', Subscription_Request_Trigger__c = false, Seller_Communication__c = false);
        
        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        Account portalAccountNA, portalAccountDE;
        Contact contact1,contact2,contact3;
        System.runAs(admins[0])
        {
            /* MN-10062024-US-0015298
            //Create account
            portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id,
                SP_Deals__c = 'Full Access'
            );

            portalAccount2 = new Account(
                Name = 'test_seller007',
                eBay_API_User_Id__c = 'test_test_test2',
                RecordTypeId = recSeller.Id,
                SP_Deals__c = 'Full Access'
            );
            insert new List<Account>{portalAccount1, portalAccount2};
            */ 

            portalAccountNA = SEPTestGenerator.createSeller('Portal Seller NA', SEP_Helper.SEP_Domain_NA, 'Full Access', null, null);
            portalAccountDE = SEPTestGenerator.createSeller('Portal Seller DE', SEP_Helper.SEP_Domain_DE, 'Full Access', null, null);


            RecordType recSP = ApexUtil.getRecordTypeByName('Contact', 'Seller_Portal');
            RecordType recDWH = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
            contact1 = new Contact(
                FirstName = 'Test1111111111',
                Lastname = 'AMT_TEST',
                AccountId = portalAccountNA.Id,
                Email = System.now().millisecond() + 'test1@test.com',
                RecordTypeId=recSP.Id
            );
            contact2 = new Contact(
                FirstName = 'Test',
                Lastname = 'test con2',
                AccountId = portalAccountDE.Id,
                Email = System.now().millisecond() + 'test2@test.com',
                RecordTypeId=recDWH.Id
            );
            insert new Contact[]{contact1,contact2};

            AccountContactRelation acr =  new AccountContactRelation(ContactId=contact1.Id,AccountId=portalAccountDE.Id,IsActive=True);
            insert acr;
        }
        System.runAs(admins[1])
        {
            //Create user
            /*
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'NA - Seller Portal' LIMIT 1];
            Profile portalProfileDE = [SELECT Id FROM Profile WHERE Name = 'DE - Seller Portal' LIMIT 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'AMT_TEST',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            User user2 = new User(
                Username = System.now().millisecond() + 'test2@test.com',
                ContactId = contact2.Id,
                ProfileId = portalProfileDE.Id,
                Alias = 'test2',
                Email = 'test2@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Test2',
                CommunityNickname = 'test2',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            insert new User[]{user1,user2};
            */
            
            User sepNA = SEPTestGenerator.prepareCommunityUserRecord('sepNAamc1', contact1.Id, null);
            User sepDE = SEPTestGenerator.prepareCommunityUserRecord('sepDEamc1', contact2.Id, null);

            insert new List<User>{sepNA,sepDE}; 

            PermissionSetGroup psg = [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName = 'Seller_Portal_DE'];
            if (psg.Status != 'Updated') {
                Test.calculatePermissionSetGroup(psg.Id);
            }
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = sepDE.Id,
                PermissionSetGroupId = psg.Id
            );
            insert psa;
        }   

    }
    
    @IsTest
    static void testSubscriptionAMProcess(){

        Test.startTest(); 
        
        //Account acc = [SELECT Id FROM Account WHERE Name = 'test_seller007' limit 1]; //MN-10062024-US-0015298

        Account acc = [SELECT Id FROM Account WHERE SP_Main_Domain__c =:SEP_Helper.SEP_Domain_DE limit 1]; //MN-10062024-US-0015298
        Contact con = [SELECT Id,Email FROM Contact WHERE AccountId=:acc.Id limit 1];
        User user1 = [SELECT Id,name From User WHERE ContactId=:con.Id limit 1];


        // 06.02.2023 / Sophal Noch / US-0011132 :
        acc.EBH_BOBManaged__c = true;
        acc.Managed_Type__c = 'Managed BoB';
        update acc;

        //Create Active Initial Cohort Seller
        RecordType bobRecordTypeLttm = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort'); // 02.07.2025 / Sophal Noch / US-0032963
        BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',Managed_Type__c ='LTTM Managed', RecordTypeId = bobRecordTypeLttm.Id);
        insert bob;

        RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB_Seller__c bs = new BoB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLttm.Id,
            Account_manager__c = UserInfo.getUserId(),
            Status__c = 'New',
            Seller__c = acc.Id,
            BoB__c = bob.Id,
            EBH_BOBSegment__c = 'Pro-Trader Plus', // 02.07.2025 / Sophal Noch / US-0032963
            BoB_Subsegment__c = 'Platin'
        );

        insert new List<BoB_Seller__c>{bs};  
        bob.Status__c = 'BoB Active';
        update bob;

        bs.Status__c = 'Draft';
        update bs; // 28.04.2025 / Sophal Noch / US-0017160 : there is async process to sync bob seller to account so this update must be between Test.startTest(); and  Test.stopTest();

        Test.stopTest();

        System.runAs(user1) {
            
            //Get Seller Information
            Map<String,Object> mapResult =  AccountManagementController.getSellerInfo(acc.Id);
            System.assert(mapResult.containsKey('account') && mapResult.get('account') != null, 'There should be an account return.');

            //Create Subscription Request
            mapResult = AccountManagementController.createSubscription(acc.Id);
            system.debug('mapResult : '+mapResult);
            Subscription_Request__c[] srequest = [Select Id from Subscription_Request__c];
            System.assert(!srequest.isEmpty(),'subscription request created');
            Id subReqId = Id.valueOf(String.valueOf(mapResult.get('recordId')));

            //Get Active Cohort Seller
            mapResult =  AccountManagementController.getActiveCohortSeller(acc.Id);  // 10.02.2023 / Sophal Noch / US-0011132

            User usr = (User) mapResult.get('accountMgmtInfo');

            System.assert( usr != null && usr.Id != null, 'There is an Account Manager');

            //Unsubscribe Request
            for (Subscription_Request__c sReq : srequest) {
                sReq.Status__c = 'Subscribed';
                sReq.Opt_In_Effective_Date__c = System.today() ;
            }
            
            update srequest;

            mapResult = AccountManagementController.requestUnsubscription(acc.Id);
            for (Subscription_Request__c sr : [select Status__c from Subscription_Request__c where Id =: subReqId]) { 
                System.assert( sr.Status__c == 'Unsubscribe Request', 'The Subscription Request Status should be Unsubscribe Request.');
            }


            //Get All Accounts Infor
            mapResult = AccountManagementController.getAllAccounts();


        }
        

        /*
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];

        //Create Active Initial Cohort Seller
        BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',Managed_Type__c ='Others Managed');
        insert bob;
        RecordType bobSellerRecordTypeManaged = ApexUtil.getRecordTypeByName('BoB_Seller__c','Managed');
        BoB_Seller__c bs = new BoB_Seller__c(
            RecordTypeId = bobSellerRecordTypeManaged.Id,
            Account_Manager__c = UserInfo.getUserId(),
            Status__c = 'New',
            Seller__c = acc.Id,
            BoB__c = bob.Id,
            EBH_BOBSegment__c = 'MSO',
            BoB_Subsegment__c = 'Platin'
        );

        // 06.02.2023 / Sophal Noch / US-0011132 :
        acc.EBH_BOBManaged__c = true;
        acc.Managed_Type__c = 'Managed BoB';
        update acc;

        insert new List<BoB_Seller__c>{bs};  
        bob.Status__c = 'BoB Active';
        update bob;

        List<Subscription_Request__c> srequest = new List<Subscription_Request__c>();
        Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'DE - Seller Portal'];

        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];
        User admin = [SELECT Id,name From User WHERE Alias='admin' limit 1];
       	User user1 = [SELECT Id,name From User WHERE Alias='testU' limit 1];
        Test.startTest(); 

        System.runAs(user1) {
            /-- MN-21122023-US-0014593: Commented out as it is not used anymore
            Account acc1 = AccountManagementController.getStoreSubscription();
            System.assertEquals('Store Subscription Level:Anchor','Store Subscription Level:'+ acc1.EBH_StoreSubscription__c);
            --/
            // Account accName = AccountManagementController.getAccountName();
            // System.assertEquals('Account Name:TestAccount','Account Name:'+ accName.Name);

            Map<String,Object> mapResult1 =  AccountManagementController.getSellerInfo(acc.Id);

            Map<String,Object> mapResult2 = AccountManagementController.createSubscription(acc.Id);
            srequest = [Select Id, Seller__c from Subscription_Request__c];
            System.assert(!srequest.isEmpty(),'subscription request created');

        }
        // 06.02.2023 / Sophal Noch / US-0011132 
        // System.runAs(admin) { 

        //     for (Subscription_Request__c sr : srequest) { sr.Initial_Cohort_Seller__c = bs.Id; }
    
        //     update srequest;
        // }
        System.runAs(user1) {
            // Map<String,Object> mapResult1 =  AccountManagementController.getActiveCohortSeller();
            Map<String,Object> mapResult1 =  AccountManagementController.getActiveCohortSeller(acc.Id);  // 10.02.2023 / Sophal Noch / US-0011132

            User usr = (User) mapResult1.get('accountMgmtInfo');

            System.assert( usr != null && usr.Id != null, 'There is an Account Manager');
        }

        Test.stopTest();
        */
    }

    @IsTest
    static void testGetAccountManagementMetadata() {
        // Call the method to test
        Map<String, Component_help_text_setting__mdt> result = AccountManagementController.getAccountManagementMetadata('DEAccountManagerHelpTextElmt');
    }

    @isTest
    private static void testInitDataGSDAccMgn(){
        Test.startTest();

        Account acc = [SELECT Id FROM Account WHERE SP_Main_Domain__c =:SEP_Helper.SEP_Domain_DE limit 1];
        acc.EBH_BOBManaged__c = true;
        acc.Managed_Type__c = 'Managed BoB';
        update acc;

        Contact con = [SELECT Id,Email FROM Contact WHERE AccountId=:acc.Id limit 1];
        User user1 = [SELECT Id,name From User WHERE ContactId=:con.Id limit 1];

        // New Cohort
        RecordType bobRecordTypeLttm = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
        BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',Managed_Type__c ='Managed BoB', RecordTypeId = bobRecordTypeLttm.Id);
        insert bob;

        // New Cohort Seller
        RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB_Seller__c bs = new BoB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLttm.Id,
            Account_Manager__c = UserInfo.getUserId(),
            Status__c = 'New',
            Seller__c = acc.Id,
            BoB__c = bob.Id,
            EBH_BOBSegment__c = 'Strategic', // 02.07.2025 / Sophal Noch / US-0032963
            BoB_Subsegment__c = 'Platin'
        );
        insert new List<BoB_Seller__c>{bs};

        bob.Status__c = 'BoB Active';
        update bob;

        bs.Status__c = 'Draft';
        update bs;

        Test.stopTest();

        System.runAs(user1) {
            List<BoB_Seller__c> lstBs = [select id from BoB_Seller__c];
            Map<String,Object> funcInitData = AccountManagementController.initDataBookingAdvertising(lstBs.get(0).Id);
            system.assertEquals(true, funcInitData.containsKey('accManagerName'),'Account_Manager__c name is found');
        }
    }

    @isTest
    private static void testGetCohortSellerBySellerIdAndProgramType(){
        Test.startTest();
        
        User currentUser = [Select Id From User Where Id = : UserInfo.getUserId() And IsActive = true Limit 1];
        System.runAs(currentUser){ 
            currentUser.Calendly__CalendlyLink__c = 'ebay.com';
            update currentUser;
        }  

        Account acc = [SELECT Id FROM Account WHERE SP_Main_Domain__c =:SEP_Helper.SEP_Domain_DE limit 1];
        acc.EBH_BOBManaged__c = true;
        acc.Managed_Type__c = 'Managed BoB';
        update acc;

        Contact con = [SELECT Id,Email FROM Contact WHERE AccountId=:acc.Id limit 1];
        User user1 = [SELECT Id,name From User WHERE ContactId=:con.Id limit 1];

        // New Cohort
        RecordType bobRecordTypeLttm = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
        BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',Managed_Type__c ='Managed BoB', RecordTypeId = bobRecordTypeLttm.Id);
        insert bob;

        // New Cohort Seller
        RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB_Seller__c bs = new BoB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLttm.Id,
            Account_Manager__c = UserInfo.getUserId(),
            Status__c = 'New',
            Seller__c = acc.Id,
            BoB__c = bob.Id,
            EBH_BOBSegment__c = 'Strategic',
            BoB_Subsegment__c = 'Platin'
        );
        insert new List<BoB_Seller__c>{bs};

        bob.Status__c = 'BoB Active';
        update bob;

        bs.Status__c = 'Draft';
        update bs;

        Test.stopTest();

        System.runAs(user1) {
            List<BoB_Seller__c> lstBs = [select id from BoB_Seller__c];
            String cohortSellerId = AccountManagementController.getCohortSellerBySellerIdAndProgramType(acc.Id,'Account Management');
            system.assertEquals(true, String.isNotBlank(cohortSellerId), 'cohortSellerId is not found');
        }
    }

}