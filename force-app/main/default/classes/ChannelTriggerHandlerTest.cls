@isTest
private class ChannelTriggerHandlerTest {
    @TestSetup
    static void setup(){
        EBH_TestDataFactory.setUpCustomSettings();
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
            Influencer__c = accInfluencer.Id,
            Numeric_Status__c = 0
        );
        insert cc1;

        Channel__c cc2 = new Channel__c(
            Link__c = 'https://www.facebook.com/JustinBieber/',
            Social_Media_Channel_Type__c = 'Facebook',
            Influencer__c = accInfluencer.Id,
            Numeric_Status__c = 0
        );
        insert cc2;
    }
    @isTest
    static void calculateInfluencerColourCodingTest() {
        Test.startTest();
            Channel__c channelIG = [SELECT Numeric_Status__c FROM Channel__c WHERE Social_Media_Channel_Type__c = 'Instagram'];
            channelIG.Numeric_Status__c = 30;
            update channelIG;

            Account accInfluencer = [SELECT Numeric_Status__c FROM Account WHERE Name = 'Influencer JB Acc'];
            System.assertEquals(30, channelIG.Numeric_Status__c);

            channelIG.Numeric_Status__c = 20;
            update channelIG;

            accInfluencer = [SELECT Numeric_Status__c FROM Account WHERE Name = 'Influencer JB Acc'];
            System.assertEquals(20, channelIG.Numeric_Status__c);

        Test.stopTest();
    }
    @isTest
    static void populateProfilePicture() {
        Test.startTest();

        
            RecordType accInfluencerRT = ApexUtil.getRecordTypeByName('Account','Influencer');
            Account accInfluencer = new Account(
                Name = 'Influencer JB',
                RecordTypeId = accInfluencerRT.Id
            );
            insert accInfluencer;

            Channel__c channelProfile = new Channel__c(
                Link__c = 'https://www.instagram.com/justinbieber/1',
                Social_Media_Channel_Type__c = 'Instagram',
                Influencer__c = accInfluencer.Id,
                Profile_Picture_Source__c = 'TestingSource'
            );
            insert channelProfile;

            Channel__c channelIG = [SELECT Profile_Picture_Source__c, Link__c FROM Channel__c WHERE Link__c = 'https://www.instagram.com/justinbieber/1'];
            System.assertNotEquals(channelIG.Profile_Picture_Source__c, null,'Profile_Picture_Source__c should not be null');

        Test.stopTest();
    }
}