/**
 * Testclass for ProTraderSellerDashboardController
 */
@isTest(seeAllData=false)
private class ProTraderSellerDashboardControllerTest {
    
    static testMethod void testProTraderBoBSeller(){

        User existAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        RecordType bobRecordTypeManage = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
        RecordType bobSellerRecordTypeManaged = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        Account portalAccount1;
        Contact contact1;
        User portalUser;
        BoB_Seller__c bs = new BoB_Seller__c();
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');

        System.runAs(existAdmin){
            //Create account
            portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id,
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA //MN-10062024-US-0015298
            );            
            insert new List<Account>{portalAccount1};

            //Create contact
            contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com'
            );            
            insert new Contact[]{contact1};

            BoB__c bob = new BoB__c(RecordTypeId = bobRecordTypeManage.Id ,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,
                                   EBH_BOBCNTRY__c='Spain',EBH_BOBVertical__c='Fashion');
            insert bob;

            
            bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeManaged.Id,Status__c='Draft',EBH_BOBSegment__c='Pro-Trader Cat',
                                                Account_Manager__c=existAdmin.id,Parent_Seller__c=portalAccount1.Id,Seller__c=portalAccount1.Id,
                                                BoB__c = bob.Id,BoB_Subsegment__c='Platin',Dashboard_Data_Available__c = TRUE);
            insert bs;  

            //NK:21/01/2025:US-0015150
            RecordType rt = ApexUtil.getRecordTypeByName('Action_Template__c','LTTM');
            Action_Template__c template = new Action_Template__c(RecordTypeId=rt.Id,name='Template1',Visible_to_Sellers__c=true,ActionTemplate_Help_Text__c='help');
            insert template;

            Action__c actionNew = new Action__c(Action_Template__c=template.Id,Status__c='Completed',LTTM_Seller__c=bs.Id,name='TaskItem Category Optimisation & Stagnant Listings ');
            insert actionNew;

            Category_Tree__c catTree = new Category_Tree__c(name='Railway and controle',Active__c=true);
            insert catTree;

            Bob_Seller_Category__c bobSellerCat = new Bob_Seller_Category__c(name='railwayCategory',
                                                    Cohort_Seller__c=bs.Id,Category_Tree__c=catTree.Id,Nextday_Delivery__c=12,MultiBuy__c=50);
            insert bobSellerCat;
            
            Test.startTest();
            DataCreator.createRecords(BoB_Seller__c.sObjectType, new List<BoB_Seller__c>{bs});
            DataCreator.updateRecord(BoB_Seller__c.sObjectType, new List<BoB_Seller__c>{bs});
            //Create user
            portalUser = SEPTestGenerator.createSEPUser('sepUserptsdc1', contact1.Id); //MN-10062024-US-0015298

            /* MN-10062024-US-0015298
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'NA - Seller Portal' LIMIT 1];
            portalUser = new User(
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
                LanguageLocaleKey = 'en_US',
                Permission_Sets__c = 'Seller_Portal_DE'
            );
            
            insert portalUser;
            */
        }
        

        
            
            ProTraderSellerDashboardController.getCohortSellerandCategoryPerformanceData(bs.id);
            
            ProTraderSellerDashboardController.getObjectsHelpTexts('Bob_Seller_Category__c');

            
        Test.stopTest();        
    }

    static testMethod void testCohertSellerDataFactoryClass(){

        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        Account portalAccount1;

        portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id
            );            
            insert new List<Account>{portalAccount1};
            CohortSellerDataFactory cohortSellerDataFactoryObj = new CohortSellerDataFactory();
            Test.startTest();
                cohortSellerDataFactoryObj.getRecordsByIds(new set<Id>{portalAccount1.Id});
                cohortSellerDataFactoryObj.getRecords();
                cohortSellerDataFactoryObj.createRecord(portalAccount1);
                cohortSellerDataFactoryObj.createRecords(new list<Account>{portalAccount1});
                cohortSellerDataFactoryObj.updateRecord(portalAccount1.id);
                cohortSellerDataFactoryObj.updateRecords(new list<Account>{portalAccount1});
                cohortSellerDataFactoryObj.upsertRecord(portalAccount1);
                cohortSellerDataFactoryObj.upsertRecords(new list<Account>{portalAccount1});
                cohortSellerDataFactoryObj.deleteRecord(portalAccount1);
                cohortSellerDataFactoryObj.deleteRecords(new list<Account>{portalAccount1});
                cohortSellerDataFactoryObj.dmlMerge(portalAccount1,new list<Account>{portalAccount1});
                CohortSellerDataFactory.getCohortSellerId(new set<Id>{portalAccount1.Id});

            Test.stopTest();
            
            // Assert statements
            System.assertNotEquals(null, CohortSellerDataFactory.getCohortSellerId(new set<Id>{portalAccount1.Id}));

    }

    @isTest
    static void testUserDataFactory() {

        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id);
        insert testContact;
     
        test.startTest();
        // Call the method being tested
        UserDataFactory userDataFactory = new UserDataFactory();
        list<user> result = (list<user>)userDataFactory.getRecordbyId(userInfo.getUserId());
        userDataFactory.getRecords();
        userDataFactory.getRecord();
        userDataFactory.createRecord(testAccount);
        userDataFactory.createRecord();
        userDataFactory.getRecordsByIds(new set<Id>{testAccount.Id});
        userDataFactory.createRecords(new list<Account>{testAccount});
        userDataFactory.updateRecord(testAccount.id);
        userDataFactory.updateRecords(new list<Account>{testAccount});
        userDataFactory.upsertRecord(testAccount);
        userDataFactory.upsertRecords(new list<Account>{testAccount});
        userDataFactory.deleteRecord(testAccount);
        userDataFactory.deleteRecords(new list<Account>{testAccount});
        userDataFactory.dmlMerge(testAccount,new list<Account>{testAccount});

        // Verify the result
        System.assertEquals(userInfo.getUserId(), result[0].Id);
        Test.stopTest();
        
    }

    @isTest
    static void testActionDataFactory() {

        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id);
        insert testContact;
        Account testAccount1 = new Account(Name = 'Test Account1');

        test.startTest();
        // Call the method being tested
        ActionDataFactory actionDataFactory = new ActionDataFactory();
        actionDataFactory.getRecordbyId(userInfo.getUserId());
        actionDataFactory.getRecords();
        actionDataFactory.getRecord();
        Account result = (Account)actionDataFactory.createRecord(testAccount1);
        actionDataFactory.createRecord();
        actionDataFactory.getRecordsByIds(new set<Id>{testAccount.Id});
        actionDataFactory.createRecords(new list<Account>{testAccount});
        actionDataFactory.updateRecord(testAccount.id);
        actionDataFactory.updateRecords(new list<Account>{testAccount});
        actionDataFactory.upsertRecord(testAccount);
        actionDataFactory.upsertRecords(new list<Account>{testAccount});
        actionDataFactory.deleteRecord(testAccount);
        actionDataFactory.deleteRecords(new list<Account>{testAccount});
        actionDataFactory.dmlMerge(testAccount,new list<Account>{testAccount});

        // Verify the result
        System.assertEquals(testAccount1.Id, result.Id);
        Test.stopTest();
        
    }

    /**
     * Test method for CategoryPerformanceDataFactory
     */
    @isTest
    static void testCategoryPerformanceDataFactory() {

        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id);
        insert testContact;
        Account testAccount1 = new Account(Name = 'Test Account1');


        Test.startTest();
        // Call the method being tested
        CohortSellerCatPeformanceDataFactory cohortSellerCatPeformanceDataFactory = new CohortSellerCatPeformanceDataFactory();
        cohortSellerCatPeformanceDataFactory.getRecordbyId(userInfo.getUserId());
        cohortSellerCatPeformanceDataFactory.getRecords();
        cohortSellerCatPeformanceDataFactory.getRecord();
        Account result = (Account) cohortSellerCatPeformanceDataFactory.createRecord(testAccount1);
        cohortSellerCatPeformanceDataFactory.createRecord();
        cohortSellerCatPeformanceDataFactory.getRecordsByIds(new set<Id>{testAccount.Id});
        cohortSellerCatPeformanceDataFactory.createRecords(new list<Account>{testAccount});
        cohortSellerCatPeformanceDataFactory.updateRecord(testAccount.id);
        cohortSellerCatPeformanceDataFactory.updateRecords(new list<Account>{testAccount});
        cohortSellerCatPeformanceDataFactory.upsertRecord(testAccount);
        cohortSellerCatPeformanceDataFactory.upsertRecords(new list<Account>{testAccount});
        cohortSellerCatPeformanceDataFactory.deleteRecord(testAccount);
        cohortSellerCatPeformanceDataFactory.deleteRecords(new list<Account>{testAccount});
        cohortSellerCatPeformanceDataFactory.dmlMerge(testAccount,new list<Account>{testAccount});

        // Verify the result
        System.assertEquals(testAccount1.Id, result.Id);
        
    }

    @isTest
    public static void testCalendlyURL() {

        BoB_Seller__c bs;
        RecordType bobRecordTypeManage = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
        RecordType bobSellerRecordTypeManaged = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

        User existAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        Account a = new Account(name='TEST', brand_engagement_lead__c=userInfo.getUserId());
        insert a;

        Contact c = new Contact (lastname='TEST', accountID=a.id, email='test@test.com');
        insert c;

        Event e = new Event(whoID=c.id, subject='TEST', calendly_event_uuid__c='TEST', startDateTime=System.now().addDays(1),DurationInMinutes=30);
        insert e;

        User portalUser;
        System.runAs(existAdmin) {

            BoB__c bob = new BoB__c(RecordTypeId = bobRecordTypeManage.Id ,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,
                                   EBH_BOBCNTRY__c='Spain',EBH_BOBVertical__c='Fashion');
            insert bob;

            
            bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeManaged.Id,Status__c='Draft',EBH_BOBSegment__c='Pro-Trader Cat',
                                                Account_Manager__c=existAdmin.id,Parent_Seller__c=a.Id,Seller__c=a.Id,
                                                BoB__c = bob.Id,BoB_Subsegment__c='Platin',Dashboard_Data_Available__c = TRUE);
            insert bs;  

            Test.startTest();
            
            portalUser = SEPTestGenerator.createSEPUser('sepUserptsdc2', c.Id); //MN-10062024-US-0015298
            
            // Assign permission set "Seller Portal - Seller Management" to portalUser
            try {
                PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Seller_Portal_Seller_Management' OR Label = 'Seller Portal - Seller Management' LIMIT 1];
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = portalUser.Id;
                psa.PermissionSetId = ps.Id;
                insert psa;
                System.debug('Successfully assigned permission set Seller Portal - Seller Management to user: ' + portalUser.Id);
            } catch(Exception ex) {
                System.debug('Permission set assignment failed: ' + ex.getMessage());
            }
            
            /* MN-10062024-US-0015298
            Profile p = [SELECT id,name FROM profile WHERE name = 'DE - Seller Portal'];

            portalUser = new User (Username = System.now().millisecond() + 'test12345@test.com',
                            Alias = 'test123',
                            Email = 'test12345@test.com',
                            EmailEncodingKey = 'UTF-8',
                            LastName = 'AMT_TEST',
                            CommunityNickname = 'test12345',
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US',
                            contactID=c.id, ProfileId=p.id);
            insert portalUser;
            System.assertEquals(p.name, 'DE - Seller Portal','profile name matches');
            */
        }
      
        System.runAs(portalUser) {
            ProTraderSellerDashboardController.getEvents(bs.id);   
            ProTraderSellerDashboardController.getCommunityBasePath();    
        }     

        Test.stopTest();
    }
}