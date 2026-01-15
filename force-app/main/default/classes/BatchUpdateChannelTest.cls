@isTest
private class BatchUpdateChannelTest {
    @isTest
    static void batchUpdateChannelTest() {
        RecordType accInfluencerRT = ApexUtil.getRecordTypeByName('Account','Influencer');

        Account accInfluencer = new Account(
            Name = 'Influencer Acc',
            RecordTypeId = accInfluencerRT.Id
        );
        insert accInfluencer;

        Channel__c ccO = new Channel__c(
            Link__c = 'https://www.instagram.com/justinbieber/',
            Social_Media_Channel_Type__c = 'Instagram',
            Influencer__c = accInfluencer.Id,
            API_Last_Refresh_Date__c = System.today().addDays(-8)
        );
        insert ccO;
        Database.executeBatch(new BatchUpdateChannel());
    }

    @isTest
    static void batchUpdateChannelTest2() {
        RecordType accInfluencerRT = ApexUtil.getRecordTypeByName('Account','Influencer');

        Account accInfluencer = new Account(
            Name = 'Influencer Acc',
            RecordTypeId = accInfluencerRT.Id
        );
        insert accInfluencer;

        Channel__c ccO = new Channel__c(
            Link__c = 'https://www.instagram.com/justinbieber/',
            Social_Media_Channel_Type__c = 'Instagram',
            Influencer__c = accInfluencer.Id,
            API_Last_Refresh_Date__c = System.today().addDays(-8)
        );
        insert ccO;
        Database.executeBatch(new BatchUpdateChannel(ccO.Id));
    }
}