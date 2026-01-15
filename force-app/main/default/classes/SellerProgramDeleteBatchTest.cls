@IsTest
public with sharing class SellerProgramDeleteBatchTest {
    @isTest
    static void testSellerProgramDeleteBatchTest() {

        EBH_TestDataFactory.setUpCustomSettings();
        Set<Id> accountIds = new Set<Id>();
		List<Account> listSeller =  EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
		listSeller[0].Name = 'TEST Seller AMT 01';
    	listSeller[0].EBH_OracleId__c = '111222333';

		listSeller[1].Name = 'TEST Seller AMT 02';
    	listSeller[1].EBH_OracleId__c = '444555666';
		update listSeller;
        accountIds.add(listSeller[0].Id);
        accountIds.add(listSeller[1].Id);

		Opportunity myOppo = new Opportunity();
		myOppo.RecordTypeId = OpportunityTriggerHandler.opportunityRecTypeBD.Id;
		myOppo.Seller__c = listSeller[0].Id;
        myOppo.Name = 'TEST Oppo';
        myOppo.StageName = 'Discovery';
        myOppo.CloseDate = System.today();
		insert myOppo;

        List<AccountTeamMember> listPreAccountTeam = new List<AccountTeamMember>();
        listPreAccountTeam.add(new AccountTeamMember(
            AccountId = listSeller[0].Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'BD Partner',
            Last_Sync_Date_Time__c = DateTime.now().addMinutes(-60)
        ));
        insert listPreAccountTeam;

        Test.startTest();
            List<AccountTeamMember> teamMembers = [SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :listSeller[0].Id];
            System.assertEquals(1, teamMembers.size(), 'One AccountTeamMember should be inserted');


            Datetime currentDateTime = DateTime.now().addMinutes(-10);
            // Create an instance of the batch class
            SellerProgramDeleteBatch batch = new SellerProgramDeleteBatch(currentDateTime, new Set<String>{'BD Partner'});
            // Execute the batch
            Database.executeBatch(batch);
            List<String> fakeErrors = new List<String>{'Test Error MSG'};
            batch.sendResult(fakeErrors);

        Test.stopTest();

        // Verify the results
        teamMembers = [SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :listSeller[0].Id];
        System.assertEquals(0, teamMembers.size(), 'One AccountTeamMember should be deleted');
    }
}