@isTest
private class ManageUserControllerTest {
    
    @TestSetup
    static void makeData(){
        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        Account portalAccount1;
        Contact contact1,contact2,contact3;
        System.runAs(admins[0])
        {
            //Create account
            /* MN-11062024-US-0015298
            portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id
            );
            */
            portalAccount1 = SEPTestGenerator.prepareAccountRecord('AMT_TEST', recSeller.Id, 'test_test_test', SEP_Helper.SEP_Domain_NA, null, null, null);
            insert new List<Account>{portalAccount1};

            RecordType recSP = ApexUtil.getRecordTypeByName('Contact', 'Seller_Portal');
            contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test1@test.com',
                RecordTypeId=recSP.Id
            );
            contact2 = new Contact(
                FirstName = 'Test2',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test2@test.com',
                RecordTypeId=recSP.Id
            );
            contact3 = new Contact(
                FirstName = 'Test3',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test3@test.com',
                RecordTypeId=recSP.Id
            );
            insert new Contact[]{contact1,contact2,contact3};
        }
        System.runAs(admins[1])
        {
            //Create user
            /* MN-11062024-US-0015298
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'NA - Seller Portal' LIMIT 1];
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
                Username = System.now().millisecond() + 'test3@test.com',
                ContactId = contact3.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123a',
                Email = 'test3@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'AMT_TEST',
                CommunityNickname = 'test1234a',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            */
            User user1 = SEPTestGenerator.prepareCommunityUserRecord('sepNAmuc1', contact1.Id, null);
            User user2 = SEPTestGenerator.prepareCommunityUserRecord('sepNAmuc2', contact3.Id, null);

            insert new User[]{user1,user2};
        }   

    }

    @IsTest
    static void testManageUser(){
        
        Test.startTest();

        for(PermissionSetGroup psg : [select Id, Status from PermissionSetGroup where DeveloperName IN ('Seller_Portal_DE', 'Seller_Portal_NA')]){
            // force calculation of the PSG if it is not already Updated
            if (psg.Status != 'Updated') {
                Test.calculatePermissionSetGroup(psg.Id);
            }
        }
        
        //User[] userPortals = [Select Id From User Where Email='test12345@test.com']; //MN-11062024-US-0015298
        User[] userPortals = [Select Id From User Where Contact.FirstName = 'Test']; //MN-11062024-US-0015298

        Contact cont2 = [Select Id,FirstName,LastName,Email From Contact Where FirstName='Test2'];
        Contact cont3 = [Select Id,FirstName,LastName,Email From Contact Where FirstName='Test3'];
        
        //User userPortal3 = [Select Id From User Where Email='test3@test.com']; //MN-11062024-US-0015298
        User userPortal3 = [Select Id From User Where Contact.FirstName ='Test3']; //MN-11062024-US-0015298
        

        System.runAs(userPortals[0])
        {

            Map<String,Object> mapResult = ManageUserController.getContacts();
            System.debug('--state0 err: '+mapResult.get('error')+''+mapResult.get('errorDetail'));
            Map<String,String> mapCont = new Map<String,String>{'firstName'=>'first','lastName'=>'last','email'=>'test999@test.com'};
            mapResult = ManageUserController.apexSubmitContact(mapCont, new String[]{});
            System.debug('--state1 err: '+mapResult.get('error')+''+mapResult.get('errorDetail'));

            System.assertEquals('ok', mapResult.get('status'),'submit contact ok');
            System.assertNotEquals(null, mapResult.get('conId'),' contact created');
            mapCont.put('Id',mapResult.get('conId')+'');

            mapResult = ManageUserController.apexSubmitUser(mapCont, new String[]{});
            System.debug('--state2 err: '+mapResult.get('error')+''+mapResult.get('errorDetail'));

            System.assertNotEquals(null, mapResult.get('user_id'),' user created');

            mapResult = ManageUserController.apexSubmitContact(mapCont, new String[]{});
            System.assertEquals('ko', mapResult.get('status'),'submit failed. contact already exists');
            System.debug('--state3 err: '+mapResult.get('error')+''+mapResult.get('errorDetail'));
             
            mapCont.put('email','....');
            mapCont.put('Id',cont2.Id+'');
            mapResult = ManageUserController.apexSubmitUser(mapCont, new String[]{});
            System.assertEquals('ko', mapResult.get('status'),'submit failed. bad user data (email)');
            System.debug('--state4 err: '+mapResult.get('error')+''+mapResult.get('errorDetail'));

            //deactivate user/contact
            mapResult = ManageUserController.apexRemoveContact('contact',cont3.Id,userPortal3.Id);
            System.debug('--state5 err: '+mapResult.get('error')+''+mapResult.get('errorDetail'));
            System.assertEquals('ok', mapResult.get('status'),'contact removed (anonymized)');            

            mapResult = ManageUserController.apexRemoveContact('user',cont3.Id,userPortal3.Id);
            System.debug('--state6 err: '+mapResult.get('error')+''+mapResult.get('errorDetail'));
            System.assertEquals('ok', mapResult.get('status'),'user removed (anonymized/deactivated)');
        }
        
            
        Test.stopTest();
        
    }
}