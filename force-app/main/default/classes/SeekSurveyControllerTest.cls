@isTest
private class SeekSurveyControllerTest {

    @TestSetup
    static void makeData(){
        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 1];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        System.runAs(admins[0])
        {
            //Create account
            Account portalAccount = new Account(
                Name = 'DEV_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id,
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA //MN-10062024-US-0015298
            );

            insert portalAccount;
            RecordType recSP = ApexUtil.getRecordTypeByName('Contact', 'Seller_Portal');
            RecordType recDWH = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
            Contact contact = new Contact(
                FirstName = 'Test1111111111',
                Lastname = 'DEV_TEST',
                AccountId = portalAccount.Id,
                Email = System.now().millisecond() + 'test1@test.com',
                RecordTypeId=recSP.Id
            );
            insert contact;

            //Create user
            User naUser = SEPTestGenerator.createSEPUser('sepNassc1', contact.Id); //MN-10062024-US-0015298

            /* MN-10062024-US-0015298
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'NA - Seller Portal' LIMIT 1];
            User naUser = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = contact.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'DEV_TEST',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            insert naUser;
            */

        }   
    }

    @isTest
    static void testGetSellerData() {

        Test.startTest();
        
        //User[] testUser = [Select Id From User Where Email='test12345@test.com']; //MN-10062024-US-0015298

        Account acc = [SELECT Id FROM Account WHERE SP_Main_Domain__c =:SEP_Helper.SEP_Domain_NA limit 1]; //MN-10062024-US-0015298
        User[] testUser = [SELECT Id,name From User WHERE Contact.AccountId=:acc.Id limit 1]; //MN-10062024-US-0015298
        
        // Set the test user as the current user
        System.runAs(testUser[0]) {
            // Call the method being tested
            Map<String, Object> sellerData = SeekSurveyController.getSellerData();

            // Verify the results
            System.assertEquals('DEV_TEST', sellerData.get('sellerName'));
        }
            
        Test.stopTest();
    }
}