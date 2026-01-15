@istest
private class AccountTeamTriggerHandlerTest {
     @TestSetup
     static void makeData(){
        EBH_TestDataFactory.setUpCustomSettings();
     }

    @IsTest
    static void testCountAccountTeam(){
        RecordType recET = ApexUtil.getRecordTypeByName('Account', 'eBay_Team');
        Account acc1 = new Account(Name='Team007',RecordTypeId=recET.Id,EBH_PrimarySite__c='Canada',NA_Contract_Type__c='Standard');
        Test.startTest();
            insert acc1;

            User[] admins = [Select Id,Name From User Where Profile.Name='System Administrator' And IsActive=True  order by createddate desc LIMIT 5];
            List<AccountTeamMember> listAT = new List<AccountTeamMember>();
            for(User usr: admins)
            {
                listAT.add(new AccountTeamMember(AccountId=acc1.Id,UserId=usr.Id,TeamMemberRole='Account Manager',AccountAccessLevel='Read',OpportunityAccessLevel='None',CaseAccessLevel='None'));
            }
            insert listAT;

        Test.stopTest();
        
    }
}