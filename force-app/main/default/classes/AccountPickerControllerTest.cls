@isTest
private class AccountPickerControllerTest {
    
    @TestSetup
    static void makeData(){

        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        //Account portalAccount1, portalAccount2; //MN-10062024-US-0015298
        Account portalAccountNA, portalAccountDE; //MN-10062024-US-0015298
        Contact contact1,contact2,contact3;

        System.runAs(admins[0])
        {
            
            /* MN-10062024-US-0015298
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

            //Create account
            portalAccountNA = SEPTestGenerator.createSeller('Portal Seller NA', SEP_Helper.SEP_Domain_NA, 'Full Access', null, null);
            portalAccountDE = SEPTestGenerator.createSeller('Portal Seller DE', SEP_Helper.SEP_Domain_DE, 'Full Access', null, null);

            //Create Contact
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
            
            /* MN-10062024-US-0015298
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

            //Create user
            User sepNA = SEPTestGenerator.prepareCommunityUserRecord('sepNAapc1', contact1.Id, null);
            User sepDE = SEPTestGenerator.prepareCommunityUserRecord('sepDEapc1', contact2.Id, null);

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
    static void test_getDEEligibleAccounts(){
        
        Test.startTest();
        
        /* MN-10062024-US-0015298
        User[] userPortals = [Select Id From User Where Email='test12345@test.com'];
        Contact cont1 = [Select Id,FirstName,LastName,Email From Contact Where FirstName='Test1111111111'];
        */

        User[] userPortals = [Select Id, ContactId From User Where SPMainDomain__c =: SEP_Helper.SEP_Domain_DE];
        
        System.runAs(userPortals[0])
        {

            Map<String,Object> mapResult = AccountPickerController.getDEEligibleAccounts();
            System.assert(mapResult != null && !mapResult.isEmpty(), 'There should be eligible accounts result return.');
            
        }
        
            
        Test.stopTest();
        
    }

}