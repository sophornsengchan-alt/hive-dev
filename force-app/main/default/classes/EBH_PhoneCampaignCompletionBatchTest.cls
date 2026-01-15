@isTest
private class EBH_PhoneCampaignCompletionBatchTest {

    static void setupTestData() {
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        RecordType rtContact = EBH_TestDataFactory.getRecordTypeByName('Contact','EBH_DWH');
        Contact con1 = new Contact(EBH_Status__c='Active', LastName = 'Test Contact 1', AccountId = sellers[0].Id, recordTypeId = rtContact.Id);
        insert con1;
        Contact con2 = new Contact(EBH_Status__c='Active', LastName = 'Test Contact 2', AccountId = sellers[1].Id, recordTypeId = rtContact.Id);
        insert con2;
    //     
        // Create a RecordType for AM Outreach if not already present
        RecordType rt = ApexUtil.getRecordTypeByName('Campaign','EBH_AMOutreach');

        // Create test Campaigns
        List<Campaign> testCampaigns = new List<Campaign>();
        for (Integer i = 0; i < 3; i++) {
            testCampaigns.add(new Campaign(
                Name = 'Test Campaign ' + i,
                RecordTypeId = rt.Id,
                Status = 'In Progress'
            ));
        }
        insert testCampaigns;

        // Create CampaignMembers with LastResponseDate older than 14 days
        List<CampaignMember> testMembers = new List<CampaignMember>();
        Date pastDate = Date.today().addDays(-15);

        for (Campaign camp : testCampaigns) {
            testMembers.add(new CampaignMember(
                CampaignId = camp.Id,
                Status = 'Sent',
                EBH_LastResponseDate__c = pastDate,
                ContactId = con1.Id
            ));
        }
        insert testMembers;
    }

    @isTest
    static void testBatchExecution() {
        setupTestData();

        Test.startTest();
        EBH_PhoneCampaignCompletionBatch batch = new EBH_PhoneCampaignCompletionBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify campaigns are marked as completed
        List<Campaign> updatedCampaigns = [SELECT Id, Status FROM Campaign WHERE Name LIKE 'Test Campaign%'];
        for (Campaign c : updatedCampaigns) {
            System.assertEquals(EBH_ConstantsUtility.PCB_COMPLETED, c.Status, 'Campaign should be marked as completed');
        }
    }

    @isTest
    static void testNoCampaignsToUpdate() {
        setupTestData();
        // Create a campaign with recent LastResponseDate
        Campaign camp = new Campaign(Name = 'Recent Campaign', Status = 'In Progress');
        insert camp;

        CampaignMember cm = new CampaignMember(
            CampaignId = camp.Id,
            Status = 'Sent',
            EBH_LastResponseDate__c = Date.today(),
            ContactId = [SELECT Id FROM Contact LIMIT 1].Id
        );
        insert cm;

        Test.startTest();
        EBH_PhoneCampaignCompletionBatch batch = new EBH_PhoneCampaignCompletionBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Campaign result = [SELECT Status FROM Campaign WHERE Id = :camp.Id];
        System.assertNotEquals(EBH_ConstantsUtility.PCB_COMPLETED, result.Status, 'Campaign should not be marked as completed');
    }
    
    @isTest
    static void testExecSchedule(){
        SchedulableContext sc;
        EBH_PhoneCampaignCompletionBatch batch = new EBH_PhoneCampaignCompletionBatch();
        batch.execute(sc);
        
    }
}