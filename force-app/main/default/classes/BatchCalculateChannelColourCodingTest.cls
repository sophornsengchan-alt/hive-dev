@isTest
private class BatchCalculateChannelColourCodingTest {
    @TestSetup
    static void setup(){
        RecordType accInfluencerRT = ApexUtil.getRecordTypeByName('Account','Influencer');
        RecordType campInfluencerRT = ApexUtil.getRecordTypeByName('Campaign','Influencer_Campaign');

        Account accInfluencer = new Account(
            Name = 'Influencer JB Acc',
            RecordTypeId = accInfluencerRT.Id
        );
        insert accInfluencer;

        Channel__c cc1 = new Channel__c(
            Link__c = 'https://www.instagram.com/justinbieber/',
            Social_Media_Channel_Type__c = 'Instagram',
            Influencer__c = accInfluencer.Id
        );
        insert cc1;

        Channel__c cc2 = new Channel__c(
            Link__c = 'https://www.facebook.com/JustinBieber/',
            Social_Media_Channel_Type__c = 'Facebook',
            Influencer__c = accInfluencer.Id
        );
        insert cc2;

        Channel__c cc3 = new Channel__c(
            Link__c = 'https://www.twitter.com/JustinBieber/',
            Social_Media_Channel_Type__c = 'Twitter',
            Influencer__c = accInfluencer.Id
        );
        insert cc3;

        Campaign camp01 = new Campaign(
            Name = 'Music Festival',
            RecordTypeId = campInfluencerRT.Id,
            Status = 'Planning'
        );
        Campaign camp02 = new Campaign(
            Name = 'PhnomPenh Festival',
            RecordTypeId = campInfluencerRT.Id,
            Status = 'Planning'
        );
        insert new List<Campaign>{camp01, camp02};

        Campaign_Channel__c campC01 = new Campaign_Channel__c(
            Campaign__c = camp01.Id,
            Channel__c = cc1.Id,
            Status__c = 'Approached'
        );
        insert campC01;

        Campaign_Channel__c campC02 = new Campaign_Channel__c(
            Campaign__c = camp02.Id,
            Channel__c = cc2.Id,
            Status__c = 'Approved'
        );
        insert campC02;
    }
    @isTest
    static void batchCalculateChannelColourCodingTestTest1() {
        Test.startTest();
            Account accInfluencer = [SELECT Id FROM Account WHERE Name = 'Influencer JB Acc'];
            Database.executeBatch(new BatchCalculateChannelColourCoding(accInfluencer.Id));
        Test.stopTest();
        Channel__c channelIG = [SELECT Numeric_Status__c FROM Channel__c WHERE Social_Media_Channel_Type__c = 'Instagram'];
        // Yellow
        System.assertEquals(20, channelIG.Numeric_Status__c);

        Channel__c channelFB = [SELECT Numeric_Status__c FROM Channel__c WHERE Social_Media_Channel_Type__c = 'Facebook'];
        // Red
        System.assertEquals(30, channelFB.Numeric_Status__c);

        Channel__c channelTW = [SELECT Numeric_Status__c FROM Channel__c WHERE Social_Media_Channel_Type__c = 'Twitter'];
        // Green
        System.assertEquals(0, channelTW.Numeric_Status__c);
    }

    @isTest
    static void batchCalculateChannelColourCodingTestTest2() {
        Database.executeBatch(new BatchCalculateChannelColourCoding());
        BatchCalculateChannelColourCoding bccc = new BatchCalculateChannelColourCoding();
        SchedulableContext sc = null;
        bccc.execute(sc);
    }
}