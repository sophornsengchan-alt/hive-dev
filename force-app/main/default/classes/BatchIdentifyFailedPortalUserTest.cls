@isTest
private class BatchIdentifyFailedPortalUserTest {

    @TestSetup
    static void makeData(){

        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');

        Account portalAccount1, portalAccount2,portalAccount3;
        Contact contact1,contact2,contact3;
        System.runAs(admins[0])
        {
            //Create account
            portalAccount1 = new Account(
                EBH_OracleId__c='1003293591',
                Name='Test Acc1',
                Risk_tier_manual__c=1,
                RecordTypeID = recSeller.Id,
                EBH_RevRollup__c='US',
                EBH_VeROViolation__c = false,
                EBH_PredictedStandard__c = 'ETRS',
                EBH_GMVLast12Months__c= 98000,
                EBH_ActualStandard__c='Above Standard',
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA,
                EBH_LastSellDate__c= Date.today().addDays(-100)
            );

            portalAccount2 = new Account(
                EBH_OracleId__c='1004444444',
                Name='Test Acc2',
                Risk_tier_manual__c=1,
                RecordTypeID = recSeller.Id,
                EBH_RevRollup__c='CA',
                EBH_VeROViolation__c =false,
                EBH_PredictedStandard__c = 'ETRS',
                EBH_GMVLast12Months__c= 58000,
                EBH_ActualStandard__c='Above Stardard',
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA,
                
                EBH_LastSellDate__c= Date.today().addDays(-10)
            );
            portalAccount3 = new Account(
                EBH_OracleId__c='1004444664',
                Name='Test Acc3',
                Risk_tier_manual__c=1,
                RecordTypeID = recSeller.Id,
                EBH_RevRollup__c='US',
                EBH_VeROViolation__c =false,
                EBH_PredictedStandard__c = 'ETRS',
                EBH_GMVLast12Months__c= 58000,
                EBH_ActualStandard__c='Above Stardard',
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA,
                Below_SP_Standard_Date__c = Date.today().addDays(-100),
                EBH_LastSellDate__c= Date.today().addDays(-90)
            );
            insert new List<Account>{portalAccount1, portalAccount2, portalAccount3};
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
                Email = System.now().millisecond() + 'test2@test.com',
                RecordTypeId=recDWH.Id
            );
            contact1 = new Contact(
                FirstName = 'Test1111111111',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test1@test.com',
                RecordTypeId=recSP.Id
            );
            contact3 = new Contact(
                FirstName = 'Test',
                Lastname = 'test con3',
                AccountId = portalAccount3.Id,
                Email = System.now().millisecond() + 'test3@test.com',
                RecordTypeId=recDWH.Id
            );
            insert new Contact[]{contact1,contact2,contact3};

            AccountContactRelation acr =  new AccountContactRelation(ContactId=contact1.Id,AccountId=portalAccount2.Id,IsActive=True);
            insert acr;
        }

        System.runAs(admins[1])
        {
            //Create user
            User user1 = SEPTestGenerator.prepareCommunityUserRecord('user001', contact1.Id, null);
            User user2 = SEPTestGenerator.prepareCommunityUserRecord('user002', contact2.Id, null);
            User user3 = SEPTestGenerator.prepareCommunityUserRecord('user003', contact3.Id, null);
            user1.Permission_Sets__c = 'Seller_Portal_NA,Seller_Portal_Baseline_Account_Contact_Access_V2';
            user2.Permission_Sets__c = 'Seller_Portal_NA,Seller_Portal_Baseline_Account_Contact_Access_V2';
            user3.Permission_Sets__c = 'Seller_Portal_NA,Seller_Portal_Baseline_Account_Contact_Access_V2';
            user3.PendingforProcessing__c = true;
            insert new List<User>{user1,user2,user3};

        }
    }   

    @isTest 
    static void testBatchIdentifyFailedPortalUser_Schedule(){
        
        Map<Id, User> mSEPUser = new Map<Id, User>([Select Id,Name, Username, Permission_Sets__c from User where LastName = 'McTesty']);
        
        //First delete the group members in order to see if the batch will add them back
        delete [select id from GroupMember where UserOrGroupId IN :mSEPUser.keySet()];

        Test.startTest();
            
            //Run the schedule
            new BatchIdentifyFailedPortalUser().execute(null);

        Test.stopTest();

        //Asert that the group members were added back
        List<GroupMember> result = [select id, UserOrGroupId from GroupMember where UserOrGroupId IN :mSEPUser.keySet()];
        System.assert(result.size() > 0, 'Group members not added back');
        for (GroupMember gm : result){
            System.assert(mSEPUser.keySet().contains(gm.UserOrGroupId), 'Group member not added back');
        }

    }

    @isTest 
    static void testBatchIdentifyFailedPortalUser_Batch(){
        Map<Id, User> mSEPUser = new Map<Id, User>([Select Id,Name, Username, Permission_Sets__c from User where LastName = 'McTesty']);
        
        //First delete the group members in order to see if the batch will add them back
        delete [select id from GroupMember where UserOrGroupId IN :mSEPUser.keySet()];

        Test.startTest();
            
            //Run the batch
            BatchIdentifyFailedPortalUser btc = new BatchIdentifyFailedPortalUser(mSEPUser.keySet());
            Database.executeBatch(btc);

        Test.stopTest();

        //Asert that the group members were added back
        List<GroupMember> result = [select id, UserOrGroupId from GroupMember where UserOrGroupId IN :mSEPUser.keySet()];
        System.assert(result.size() > 0, 'Group members not added back');
        for (GroupMember gm : result){
            System.assert(mSEPUser.keySet().contains(gm.UserOrGroupId), 'Group member not added back');
        }
    }
}