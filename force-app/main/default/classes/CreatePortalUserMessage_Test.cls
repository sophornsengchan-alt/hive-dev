@isTest
public class CreatePortalUserMessage_Test {
    @isTest
    static void testLoadData() {
		Test.startTest();

        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        system.debug('portalRole is ' + portalRole);

        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
        UserRoleId = portalRole.Id,
        ProfileId = profile1.Id,
        Username = System.now().millisecond() + 'test2@test.com',
        Alias = 'batman',
        Email='bruce.wayne@wayneenterprises.com',
        EmailEncodingKey='UTF-8',
        Firstname='Bruce',
        Lastname='Wayne',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);

        //User u1 = [Select ID From User Where Id =: portalAccountOwner1.Id];

        System.runAs ( portalAccountOwner1 ) {
                //Create account
                /* MN-10062024-US-0015298
                Account portalAccount1 = new Account(
                Name = 'TestAccount',
                OwnerId = portalAccountOwner1.Id
                );
                Database.insert(portalAccount1);
                */

                Account portalAccount1 = SEPTestGenerator.createSeller('Portal Seller', SEP_Helper.SEP_Domain_NA);

                //Create contact
                Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com'
                );
                Database.insert(contact1);

                //Create user
                /* MN-10062024-US-0015298
                Profile portalProfile = [SELECT Id FROM Profile where name ='NA - Seller Portal' Limit 1];
                User user1 = new User(
                Username = System.now().millisecond() + 'teswerewt12345@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
                );
                Database.insert(user1);
                */

                User user1 = SEPTestGenerator.createSEPUser('sepUsercpum1', contact1.Id); //MN-10062024-US-0015298

                List<User> userCollection =new List<User>();
                userCollection.add(user1);

                Portal_User_Message__c portalUserMsgItem = new Portal_User_Message__c();
                portalUserMsgItem.Name = 'hwidshj';
                portalUserMsgItem.Message_Type__c='Modal';
                portalUserMsgItem.Status__c= 'Active';
                portalUserMsgItem.Type__c ='Broadcast';
                portalUserMsgItem.Content__c ='hjgsdfiuerjhrifwe';
                portalUserMsgItem.Applies_to_User_Region__c ='DE';
                portalUserMsgItem.Start_time__c =System.today();
                portalUserMsgItem.End_time__c =System.today().adddays(2);
                insert portalUserMsgItem;
                CreatePortalUserMessage.Request req = new CreatePortalUserMessage.Request();
                req.userCollection = userCollection;
                req.portalUserMsg = portalUserMsgItem;
                List<CreatePortalUserMessage.Request> reqParamlist = new List<CreatePortalUserMessage.Request>();
                reqParamlist.add(req);
                CreatePortalUserMessage.CreatePortalUserMessageItem(reqParamlist);
        }
        Test.stopTest();
    } 
}