/**
 * change log:
 *  11/04/2022: US-0010870 - Auto Provisioning of Sellers (Deals) - NA, DE
 *  11/06/2024: US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
 */
@isTest(isParallel=false)
private class EbayRegistrationHandlerTest {
   @TestSetup
    private static void makeData(){

        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        RecordType recSellerGroup = ApexUtil.getRecordTypeByName('Account', 'Seller_Portal_Group');
        Account portalAccount1;
        Contact contact1, contact2,contact3,contact4,contact5,contact6,contact7,contactGroup;
        System.runAs(admins[0])
        {
            //SP_Deals__c IN ('Full Access', 'Read Only')
            //Create account
            portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id,
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA, //MN-11062024-US-0015298
                SP_Deals__c = 'Full Access'
            );
            //Seller_Portal_Setting__mdt :
            // EBH_DealsProgram__c IN ('Allow','Accepted') AND EBH_RevRollup__c = 'DE' AND Seller_Portal_Beta_User__c = TRUE
            Account portalAccount2 = new Account(
                Name = 'seller1DE',
                eBay_API_User_Id__c = 'seller1DE',
                RecordTypeId = recSeller.Id,
                //EBH_DealsProgram__c = 'Accepted',//LA:05-12-2023-US-0014231
                EBH_RevRollup__c  = 'DE',
                Seller_Portal_Beta_User__c =true,
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_DE, //MN-11062024-US-0015298
                SP_Deals__c = 'Full Access'
            );
            //Seller_Portal_Setting__mdt : 
            //EBH_RevRollup__c IN ('US','CA') AND EBH_PredictedStandard__c = 'ETRS' AND EBH_PositiveFeedback__c >= 98 AND EBH_VeROViolation__c = FALSE AND EBH_LastSellDate__c >= LAST_90_DAYS AND EBH_FeedbackScore__c > 2000 AND EBH_StoreSubscription__c IN ('Anchor','Platinum') AND EBH_ActualStandard__c IN ('Above Standard','ETRS') AND EBH_GMVLast12Months__c >= 60000
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
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA, //MN-11062024-US-0015298
                SP_Deals__c = 'Full Access'

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
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA, //MN-11062024-US-0015298
                SP_Deals__c = 'Full Access'

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
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_AU, //MN-11062024-US-0015298
                SP_Deals__c = 'Full Access'

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
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_DE, //MN-11062024-US-0015298
                SP_Deals__c = 'Full Access'
            );
            Account portalSSOAccount2 = new Account(
                Name = 'apiSSOid2',
                eBay_API_User_Id__c = 'apiSSOid2',
                RecordTypeId = recSeller.Id,
                //EBH_DealsProgram__c = 'Accepted', //LA:05-12-2023-US-0014231
                EBH_RevRollup__c  = 'DE',
                Seller_Portal_Beta_User__c =true,
               /// Seller_Portal_Group__c = portalSSOAccountGroup.Id,
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_DE, //MN-11062024-US-0015298
                SP_Deals__c = 'Full Access'
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
        }

        System.runAs(admins[1])
        {
            //Create user
            User user1 = SEPTestGenerator.prepareCommunityUserRecord('sepUsererh1', contact1.Id, null);
            User user2 = SEPTestGenerator.prepareCommunityUserRecord('sepUsererh2', contact3.Id, null);
            User user3 = SEPTestGenerator.prepareCommunityUserRecord('sepUsererh3', contact4.Id, null);
            User user4 = SEPTestGenerator.prepareCommunityUserRecord('sepUsererh4', contactGroup.Id, null);
            User user5 = SEPTestGenerator.prepareCommunityUserRecord('sepUsererh5', contact6.Id, null);
            User user6 = SEPTestGenerator.prepareCommunityUserRecord('sepUsererh6', contact5.Id, null);
            insert new User[]{user1,user2,user3, user4, user5, user6};
            
                   
        }        
    }
    
    @isTest
    private static void ebayRegistrationHandlerTest2() {
        
        Test.startTest();

            EbayRegistrationHandler handler = new EbayRegistrationHandler();

            Set<String> sPSGDevName = new Set<String>{'Seller_Portal_DE','Seller_Portal_NA','Seller_Portal_AU'};
            for (PermissionSetGroup psg : [select Id, Status from PermissionSetGroup where DeveloperName IN:sPSGDevName]){
                // force calculation of the PSG if it is not already Updated
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }
            }
            //create user DE
            Auth.UserData sampleData = new Auth.UserData('seller1DE', 'testFirst2', 'seller1DE','testFirst testLast', 'testuser2_seller1DE@example2.org', 'seller1DE', 'seller1DE', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            User newUser = handler.createUser(null, sampleData);
            System.assert(newUser.Permission_Sets__c.contains('Seller_Portal_DE'),'user is eligible for portal');

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
    private static void ebayRegistrationHandlerTestAC1() {
        
        Test.startTest();

            EbayRegistrationHandler handler = new EbayRegistrationHandler();

            //create user DE
            Auth.UserData sampleData = new Auth.UserData('apiSSOid1', 'test', 'apiSSOid1','test', 'testsso_apiSSOid1@example2.org', 'apiSSOid1', 'apiSSOid1', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            // AC1
            try{
                User newUser = handler.createUser(null, sampleData);
            }catch(Exception e){
                System.assert(String.isNotBlank(e.getMessage()), 'There must be error message return.');
            }
        Test.stopTest();
    }
    @isTest
    private static void ebayRegistrationHandlerTest3() {
         
        Test.startTest();
            Set<String> sPSGDevName = new Set<String>{'Seller_Portal_DE','Seller_Portal_NA','Seller_Portal_AU'};
            for (PermissionSetGroup psg : [select Id, Status from PermissionSetGroup where DeveloperName IN:sPSGDevName]){
                // force calculation of the PSG if it is not already Updated
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }
            }
            EbayRegistrationHandler handler = new EbayRegistrationHandler();
            List<Account> lstAcc = new List<Account>();
            for(Account acc: [Select Id,Name,eBay_API_User_Id__c,Seller_Portal_Group__c FROM Account Where Name = 'apiSSOid' or Name = 'apiSSOid2' or Name ='TestGroup']){
                acc.eBay_API_User_Id__c = acc.Name;  
                lstAcc.add(acc);
            }

            User admin_usr = [select id from user where Id <>:UserInfo.getUserId() and IsActive = true and Profile.Name = 'System Administrator' limit 1];

            System.runAs(admin_usr) {
                update lstAcc;
            }

            
            //create user DE
            Auth.UserData sampleData = new Auth.UserData('apiSSOid2', 'test', 'apiSSOid2','test', 'testsso_apiSSOid2@example2.org', 'apiSSOid2', 'apiSSOid2', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            User newUser = handler.createUser(null, sampleData);
        
            Test.stopTest();
    }

    //MN-05012023-US-0014477
    @isTest static void testReactivateUserWithInvalidUserRole() {
       
        Test.startTest();

            Set<String> sPSGDevName = new Set<String>{'Seller_Portal_DE','Seller_Portal_NA','Seller_Portal_AU'};
            for (PermissionSetGroup psg : [select Id, Status from PermissionSetGroup where DeveloperName IN:sPSGDevName]){
                // force calculation of the PSG if it is not already Updated
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }
            }
            //User usr = [select id,Name, isActive, UserRoleId, UserRole.Name, UserRole.PortalAccountOwnerId, Contact.AccountId, Contact.Account.OwnerId, Contact.Account.Owner.Alias from user where alias = 'testsso2']; //MN-11062024-US-0015298
            User usr = [select id,Name, isActive, UserRoleId, UserRole.Name, UserRole.PortalAccountOwnerId, Contact.AccountId, Contact.Account.OwnerId, Contact.Account.Owner.Alias from user where Contact.LastName = 'testSSO2']; //MN-11062024-US-0015298

            //Deactivate user
            usr.IsActive = false;
            update usr;

            //Change User's Account Owner
            User new_owner = [select id from user where Id <>:usr.Contact.Account.OwnerId and IsActive = true and Profile.Name = 'System Administrator' limit 1];

            System.runAs(new_owner) {
                
                update new Account(Id=usr.Contact.AccountId, OwnerId=new_owner.Id);
               
            }

            EbayRegistrationHandler handler = new EbayRegistrationHandler();
            
            Auth.UserData sampleData = new Auth.UserData('apiSSOid2', 'test', 'apiSSOid2','test', 'testsso_apiSSOid2@example2.org', 'apiSSOid2', 'apiSSOid2', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            handler.updateUser(usr.Id, null, sampleData);

            //Assert that user is active
            //usr = [select id,Name, isActive from user where alias = 'testsso2']; //MN-11062024-US-0015298
            usr = [select id,Name, isActive from user where Contact.LastName = 'testSSO2']; //MN-11062024-US-0015298

            System.assertEquals(true, usr.IsActive, 'User should be active.');
            

        Test.stopTest();
    }

    //MN-05012023-US-0014477
    @isTest static void testReactivateUserWithInvalidUserRole_2() {
        
        Test.startTest();

            Account acc = [select Id from Account where Name = 'TestGroup' limit 1]; //MN-11062024-US-0015298
            //User usr = [select id,Name, isActive, UserRoleId, UserRole.Name, UserRole.PortalAccountOwnerId, Contact.AccountId, Contact.Account.OwnerId, Contact.Account.Owner.Alias from user where alias = 'TestSSO']; //MN-11062024-US-0015298
            User usr = [select id,Name, isActive, UserRoleId, UserRole.Name, UserRole.PortalAccountOwnerId, Contact.AccountId, Contact.Account.OwnerId, Contact.Account.Owner.Alias from user where Contact.AccountId =:acc.Id]; //MN-11062024-US-0015298

            //Deactivate user
            usr.IsActive = false;
            update usr;

            //Change User's Account Owner
            User new_owner = [select id from user where Id <>:usr.Contact.Account.OwnerId and IsActive = true and Profile.Name = 'System Administrator' limit 1];

            //Change User's Account Owner
            System.runAs(new_owner) {
                
                update new Account(Id=usr.Contact.AccountId, OwnerId=new_owner.Id);
            
            }

            EbayRegistrationHandler handler = new EbayRegistrationHandler();
            
            Auth.UserData sampleData = new Auth.UserData('apiSSOid', 'test', 'apiSSOid','test', 'testsso_apiSSOid@example2.org', 'apiSSOid', 'apiSSOid', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            
            handler.updateUser(usr.Id, null, sampleData);

            //Assert that user is active
            //usr = [select id,Name, isActive from user where alias = 'TestSSO']; //MN-11062024-US-0015298
            usr = [select id,Name, isActive from user where Contact.AccountId =:acc.Id]; //MN-11062024-US-0015298

            System.assertEquals(true, usr.IsActive, 'User should be active.');
            

        Test.stopTest();
    }

    //MN-05012023-US-0014477
    @isTest static void testReactivateUserWithInvalidUserRole_WithError() {
         
        Test.startTest();

            Account acc = [select id from Account where Name = 'apiSSOid' limit 1]; //MN-11062024-US-0015298
            //User usr = [select id,Name, isActive, UserRoleId, UserRole.Name, UserRole.PortalAccountOwnerId, Contact.AccountId, Contact.Account.OwnerId, Contact.Account.Owner.Alias from user where alias = 'testsso3']; //MN-11062024-US-0015298
            User usr = [select id,Name, isActive, UserRoleId, UserRole.Name, UserRole.PortalAccountOwnerId, Contact.AccountId, Contact.Account.OwnerId, Contact.Account.Owner.Alias from user where Contact.AccountId=:acc.Id]; //MN-11062024-US-0015298

            //Deactivate user
            usr.IsActive = false;
            update usr;

            //Change User's Account Owner
            User new_owner = [select id from user where Id <>:usr.Contact.Account.OwnerId and IsActive = true and Profile.Name = 'System Administrator' limit 1];

            System.runAs(new_owner) {                
                update new Account(Id=usr.Contact.AccountId, OwnerId=new_owner.Id);
            
            }
            EbayRegistrationHandler handler = new EbayRegistrationHandler();
            
            Auth.UserData sampleData = new Auth.UserData('apiSSOid', 'test', 'apiSSOid','test', 'testsso_apiSSOid@example2.org', 'apiSSOid', 'apiSSOid', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            
            //Error 1
            try {
                handler.updateUser(usr.Id, null, sampleData);
            }catch(Exception ex){
                System.assert(String.isNotBlank(ex.getMessage()), 'There must be error message return.');
            }
            System.runAs(new_owner) {
                
                update new Account(Id=usr.Contact.AccountId, User_Disconnected__c = true);
            
            }            
            sampleData = new Auth.UserData('apiSSOid', 'test', 'apiSSOid','test', 'testsso_apiSSOid@example2.org', 'apiSSOid', 'apiSSOid', 'en_US', 'facebook',null, new Map<String, String>{'language' => 'en_US'});
            
            //Error 2
            try {
                handler.updateUser(usr.Id, null, sampleData);
            }catch(Exception ex){
                System.assert(String.isNotBlank(ex.getMessage()), 'There must be error message return.');
            }
            
        Test.stopTest();
    }
}