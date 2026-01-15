@isTest
public class SellerProgramSyncBatchTest {
    @isTest
    static void testSellerProgramSyncBatch() {

        EBH_TestDataFactory.setUpCustomSettings();
		List<Account> listSeller =  EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
		listSeller[0].Name = 'TEST Seller AMT 01';
    	listSeller[0].EBH_OracleId__c = '111222333';

		listSeller[1].Name = 'TEST Seller AMT 02';
    	listSeller[1].EBH_OracleId__c = '444555666';
		update listSeller;

		Opportunity myOppo = new Opportunity();
		myOppo.RecordTypeId = OpportunityTriggerHandler.opportunityRecTypeBD.Id;
		myOppo.Seller__c = listSeller[0].Id;
        myOppo.Name = 'TEST Oppo';
        myOppo.StageName = 'Discovery';
        myOppo.CloseDate = System.today();
		insert myOppo;

        Test.startTest();
            // Create an instance of the batch class
            SellerProgramSyncBatch batch = new SellerProgramSyncBatch();
            // Execute the batch
            Database.executeBatch(batch);
            List<String> fakeErrors = new List<String>{'Test Error MSG'};
            batch.sendResult(fakeErrors);
            try {
                batch.logError(null, fakeErrors, 'execute');
            } catch (Exception exec) {
                System.debug('error');
            }
            SellerProgramSyncBatch batch2 = new SellerProgramSyncBatch(5);

            SchedulableContext sc = null;
            batch.execute(sc);
        Test.stopTest();

        // Verify the results
        List<AccountTeamMember> teamMembers = [SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :listSeller[0].Id];
        System.assertEquals(1, teamMembers.size(), 'One AccountTeamMember should be inserted');
        System.assertEquals('BD Partner', teamMembers[0].TeamMemberRole, 'BD Partner');
    }
}