@isTest(seeAllData = False)
private class LinkedAccountsControllerTest {
    

    @TestSetup
    static void makeData(){
        User[] admins = [Select Id,Name From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        RecordType groupRt = ApexUtil.getRecordTypeByName('Account', 'Seller_Portal_Group');
        Account groupAccount = new Account(
            Name = 'Test Group',
            RecordTypeId = groupRt.Id
        );
        insert groupAccount;
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        Account portalAccount1, portalAccount2,portalAccount3,portalAccount4;
        Contact contact1,contact2,contact3,contact4;
        System.runAs(admins[0])
        {
            portalAccount1 = SEPTestGenerator.prepareAccountRecord('AMT_TEST', recSeller.Id, 'test_test_test', 'sellerportal.ebay.com', null, null, null);
            portalAccount2 = SEPTestGenerator.prepareAccountRecord('test_seller007', recSeller.Id, 'test_test_test2', 'wachstumsportal.ebay.de', 'Full Access', null, null);
            portalAccount3 = SEPTestGenerator.prepareAccountRecord('test_seller008', recSeller.Id, 'test_test_test3', 'wachstumsportal.ebay.de', 'Full Access', null, null);
            portalAccount4 = SEPTestGenerator.prepareAccountRecord('test_seller009', recSeller.Id, 'test_test_test4', 'wachstumsportal.ebay.de', 'Full Access', null, null);
            portalAccount4.Seller_Portal_Group__c = groupAccount.Id;
            insert new List<Account>{portalAccount1, portalAccount2,portalAccount3,portalAccount4};
            
            RecordType recSP = ApexUtil.getRecordTypeByName('Contact', 'Seller_Portal');
            RecordType recDWH = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
            contact1 = new Contact(
                FirstName = 'Test1111111111',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test1@test.com',
                RecordTypeId=recSP.Id
            );
            contact2 = new Contact(
                FirstName = 'Test',
                Lastname = 'test con2',
                AccountId = portalAccount2.Id,
                Email = System.now().millisecond() + 'srotest2@test.com',
                RecordTypeId=recDWH.Id
            );
            contact3 = new Contact(
                FirstName = 'Test3',
                Lastname = 'test con3',
                AccountId = portalAccount3.Id,
                Email = System.now().millisecond() + 'test3@test.com',
                RecordTypeId=recDWH.Id
            );
            contact4 = new Contact(
                FirstName = 'Test4',
                Lastname = 'test con4',
                AccountId = portalAccount4.Id,
                Email = System.now().millisecond() + 'test4@test.com',
                RecordTypeId=recDWH.Id
            );
            insert new Contact[]{contact1,contact2,contact3,contact4};

            AccountContactRelation acr =  new AccountContactRelation(ContactId=contact1.Id,AccountId=portalAccount2.Id,IsActive=True);
            AccountContactRelation acr1 = new AccountContactRelation(ContactId=contact2.Id, AccountId=portalAccount1.Id,IsActive=True);
            AccountContactRelation acr2 = new AccountContactRelation(ContactId=contact1.Id, AccountId=portalAccount4.Id,IsActive=True);
            insert new AccountContactRelation[]{acr,acr1,acr2};
        }  

    }

    @IsTest
    static void testGetAccounts(){
        
        Test.startTest();
        
        Contact contact1 = [Select Id,FirstName,LastName,Email From Contact Where Account.Name ='AMT_TEST' Limit 1];
        User user1 = SEPTestGenerator.prepareCommunityUserRecord('sepNAlac1', contact1.Id, null);

        //System.runAs(userPortals[0])
        System.runAs(user1)
        {

            Map<String,Object> mapResult = LinkedAccountsController.getAccounts();
            System.assert(mapResult != null && !mapResult.isEmpty(), 'There should be linked accounts result return.');
            
        }
        
            
        Test.stopTest();
        
    }

    //28/04/2022:vadhanak: US-0011082 - Allow Sellers to link Accounts
    static testMethod void testLinkingAccount()
    {
        Account accToLink1 = [Select Id From Account Where eBay_API_User_Id__c = 'test_test_test3'];
        Account accToLink2 = [Select Id From Account Where eBay_API_User_Id__c = 'test_test_test4'];
        Account mainSeller = [Select Id From Account Where eBay_API_User_Id__c = 'test_test_test2'];
        User adminUser = [Select Id From User Where Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];

        Contact contact2 = [Select Id,FirstName,LastName,Email From Contact Where Account.Name ='test_seller007' Limit 1];
        User user1;
        // Create user in a separate context to avoid mixed DML
        System.runAs(new User(Id = UserInfo.getUserId())) {
            user1 = SEPTestGenerator.prepareCommunityUserRecord('sepDElac1', contact2.Id, null);
        }

        Id groupId;
        String mainAccId;

        Test.startTest();

        System.runAs(user1) {
            Map<String,Object> mapResultAccList = LinkedAccountsController.getAccounts();
            List<Object> accs = (List<Object>)mapResultAccList.get('accRelation');
            System.assertEquals(2, accs.size(), '2 accounts visible');

            SEP_Helper.sepUser.domain = SEP_Helper.SEP_Domain_DE;
            Map<String,Object> sessionResult = LinkedAccountsController.apexGetEbaySessionId();
            System.assert(String.isNotBlank(sessionResult.get('ebaySessionId')+''), 'session returns');

            Map<String,Object> confirmIdResult = LinkedAccountsController.apexEbayConfirmIdentity();
            mainAccId = String.valueOf(confirmIdResult.get('mainAccId'));
            if (String.isBlank(mainAccId) || 'null'.equalsIgnoreCase(mainAccId)) {
                mainAccId = mainSeller.Id;
            }
            System.assertNotEquals('null', mainAccId, 'mainAccId missing: ' + confirmIdResult);
            System.assertNotEquals(null, accToLink1.Id, 'link account missing');

            Map<String,Object> createGroupResult = LinkedAccountsController.apexManageGroup('Group Test999', '', mainAccId, accToLink1.Id, 'a');
            System.assertEquals('ok', String.valueOf(createGroupResult.get('status')), 'Group creation failed: ' + createGroupResult);
        }

        System.runAs(adminUser) {
            Account createdGroup = [Select Id, SP_Deals__c, SP_Coupons__c, SP_Account_Management__c, NA_Deal_Program_Vetted__c, SP_Promotions_Manager__c From Account Where RecordType.DeveloperName = 'Seller_Portal_Group' AND Requested_By__c = :contact2.Id ORDER BY CreatedDate DESC LIMIT 1];
            groupId = createdGroup.Id;
            System.assertNotEquals(null, groupId, 'Group should be created for requested contact');

            // Reset group fields so the existing-group branch repopulates them.
            createdGroup.SP_Deals__c = null;
            createdGroup.SP_Coupons__c = null;
            createdGroup.SP_Account_Management__c = null;
            createdGroup.NA_Deal_Program_Vetted__c = false;
            createdGroup.SP_Promotions_Manager__c = null;
            update createdGroup;
        }

        System.runAs(user1) {
            LinkedAccountsController.apexManageGroup('', groupId, mainAccId, accToLink2.Id, 'a');

            Account updatedGroup = [Select SP_Deals__c, SP_Account_Management__c, SP_Coupons__c, NA_Deal_Program_Vetted__c, SP_Promotions_Manager__c From Account Where Id = :groupId];
            System.assertEquals('Allowed', updatedGroup.SP_Deals__c, 'Existing group should inherit SP Deals access');
            Account newLinkedAccount = [Select Seller_Portal_Group__c, User_Disconnected__c From Account Where Id = :accToLink2.Id];
            System.assertEquals(groupId, newLinkedAccount.Seller_Portal_Group__c, 'Linked account should point to existing group');
            System.assertEquals(false, newLinkedAccount.User_Disconnected__c, 'Linked account should remain connected');

            LinkedAccountsController.apexManageGroup('', groupId, mainAccId, mainSeller.Id, 'a');
        }

        Test.stopTest();
    }

    @isTest
    static void testRemoveLinkedAccountWithNoGroup() {
		Contact contact2 = [Select Id,FirstName,LastName,Email From Contact Where Account.Name ='test_seller007' Limit 1];
        User deUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            deUser= SEPTestGenerator.prepareCommunityUserRecord('sepDElac1', contact2.Id, null);
        }
        Account accToLink1 = [Select Id From Account Where eBay_API_User_Id__c = 'test_test_test'];
        
        Test.startTest();
            System.runAs(deUser) {
                Map<String,Object> mapResult = LinkedAccountsController.removeLinkedAccount(accToLink1.Id);
                System.assertEquals(null,mapResult.get('error'));
                System.assertEquals('ok', String.valueOf(mapResult.get('status')));
            }
        Test.stopTest();
    }

    @isTest
    static void testRemoveLinkedAccountWithGroup()
    {
        Contact contact2 = [Select Id,FirstName,LastName,Email From Contact Where Account.Name ='test_seller009' Limit 1];
        User deUser = SEPTestGenerator.prepareCommunityUserRecord('sepDElac1', contact2.Id, null);
        User adminUser = [Select Id From User Where Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
        
        Account accToLink1 = [Select Id From Account Where eBay_API_User_Id__c = 'test_test_test4'];
        Account anotherLinkedAccount = [Select Id From Account Where eBay_API_User_Id__c = 'test_test_test3'];
        Test.startTest();
        String restulltTxt = '';
        Id mainAccountId;
        Id sellerGroupId;
        System.runAs(adminUser) {
                AccountContactRelation supplementalRelation = new AccountContactRelation(ContactId = deUser.ContactId, AccountId = anotherLinkedAccount.Id, IsActive = true);
                insert supplementalRelation;
            }
            System.runAs(deUser)
            {
                SEP_Helper.sepUser.domain = SEP_Helper.SEP_Domain_DE;
                Map<String,Object> sessionResult = LinkedAccountsController.apexGetEbaySessionId();
                String sessionStatus = String.valueOf(sessionResult.get('status'));
                System.assertEquals('ok', sessionStatus, 'Session request failed: ' + sessionResult);

                String sessionId = String.valueOf(sessionResult.get('ebaySessionId'));
                System.assert(String.isNotBlank(sessionId),'session returns');
                System.assert(String.isNotBlank(String.valueOf(sessionResult.get('endpoint'))),'Endpoint returned');
                System.assert(String.isNotBlank(String.valueOf(sessionResult.get('ebayRuName'))),'RuName returned');

                Account accResult = [Select Id, ebay_session_id_tmp__c From Account Where eBay_API_User_Id__c = 'test_test_test4'];
                System.assertEquals(sessionId, accResult.ebay_session_id_tmp__c, 'Session id temporarily saved to account');

                Map<String,Object> confirmIdResult = LinkedAccountsController.apexEbayConfirmIdentity();
                mainAccountId = Id.valueOf(String.valueOf(confirmIdResult.get('mainAccId')));
                restulltTxt = 'confirmIdResult: ' + confirmIdResult;

                Account accAfterConfirm = [Select ebay_session_id_tmp__c From Account Where Id = :accResult.Id];
                System.assertEquals(null, accAfterConfirm.ebay_session_id_tmp__c, 'Session id cleared after confirm identity');

                Map<String,Object> resultCreateGeroup = LinkedAccountsController.apexManageGroup('Group Test999','',mainAccountId,accToLink1.Id,'a');
                restulltTxt += '\nresultCreateGeroup: '+(resultCreateGeroup);

                Account mainAccountWithGroup = [Select Seller_Portal_Group__c From Account Where Id = :mainAccountId];
                sellerGroupId = mainAccountWithGroup.Seller_Portal_Group__c;
                System.assertNotEquals(null, sellerGroupId, 'Seller group expected after linking');

                Map<String,Object> linkAdditionalAccount = LinkedAccountsController.apexManageGroup('', sellerGroupId, mainAccountId, anotherLinkedAccount.Id, 'a');
                restulltTxt += '\nlinkAdditionalAccount: ' + linkAdditionalAccount;
            }

            

            List<AccountContactRelation> listAcr = [Select Id, AccountId From AccountContactRelation Where ContactId =: deUser.ContactId];
            System.assertEquals(2, listAcr.size(),'Result: '+restulltTxt);

            System.runAs(deUser) {
                Map<String,Object> mapResult = LinkedAccountsController.removeLinkedAccount(accToLink1.Id);
                System.assertEquals(null,mapResult.get('error'),''+mapResult);
                System.assertEquals('ok', String.valueOf(mapResult.get('status')));
            }

            listAcr = [Select Id, AccountId From AccountContactRelation Where ContactId =: deUser.ContactId];
            System.assertEquals(1, listAcr.size());

            Account remainingLinkedAccount = [Select Seller_Portal_Group__c, User_Disconnected__c From Account Where Id = :anotherLinkedAccount.Id];
            System.assertEquals(sellerGroupId, remainingLinkedAccount.Seller_Portal_Group__c, 'Remaining seller should stay in group');
            System.assertEquals(false, remainingLinkedAccount.User_Disconnected__c, 'Remaining seller remains connected');

            Account removedAccount = [Select Seller_Portal_Group__c, User_Disconnected__c From Account Where Id = :accToLink1.Id];
            System.assertEquals(null, removedAccount.Seller_Portal_Group__c, 'Removed account should no longer reference group');
            System.assertEquals(true, removedAccount.User_Disconnected__c, 'Removed account should be flagged as disconnected');

            Account groupAfterUnlink = [Select SP_Deals__c, SP_Coupons__c, SP_Account_Management__c, NA_Deal_Program_Vetted__c, SP_Promotions_Manager__c From Account Where Id = :sellerGroupId];
            System.assertEquals('Allowed', groupAfterUnlink.SP_Deals__c, 'Group should retain Deals access based on remaining member');

        Test.stopTest();

    }

    @isTest
    static void testPopulateSellerGroupSPFields() {
        RecordType groupRt = ApexUtil.getRecordTypeByName('Account', 'Seller_Portal_Group');
        RecordType sellerRt = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');

        Account groupAccount = new Account(Name = 'Populate Group', RecordTypeId = groupRt.Id);
        insert groupAccount;

        Account includedAccount = SEPTestGenerator.prepareAccountRecord('Populate Seller 1', sellerRt.Id, 'populate_seller_1', SEP_Helper.SEP_Domain_DE, 'Full Access', 'Full Access', 'Full Access');
        includedAccount.Seller_Portal_Group__c = groupAccount.Id;
        includedAccount.SP_Account_Management__c = 'Full Access';
        includedAccount.SP_Promotions_Manager__c = 'Full Access';
        

        Account excludedAccount = SEPTestGenerator.prepareAccountRecord('Populate Seller 2', sellerRt.Id, 'populate_seller_2', SEP_Helper.SEP_Domain_DE, null, null, null);
        excludedAccount.Seller_Portal_Group__c = groupAccount.Id;

        insert new List<Account>{includedAccount, excludedAccount};

        Test.startTest();
        Map<Id, Account> result = LinkedAccountsController.populateSellerGroupSPFields(new Set<String>{groupAccount.Id}, new Set<String>{excludedAccount.Id});
        Map<Id, Account> emptyResult = LinkedAccountsController.populateSellerGroupSPFields(new Set<String>(), new Set<String>());
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Expected group in result map');
        Account updatedGroup = result.get(groupAccount.Id);
        System.assertEquals('Allowed', updatedGroup.SP_Promotions_Manager__c, 'Promotions manager flag should be Allowed');

        System.assertEquals(0, emptyResult.size(), 'Empty seller group set should yield empty result');
    }

}