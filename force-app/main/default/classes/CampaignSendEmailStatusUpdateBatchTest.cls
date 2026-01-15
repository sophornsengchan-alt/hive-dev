/**
 * Class name: CampaignSendEmailStatusUpdateBatchTest
 * Purpose: Test class of CampaignSendEmailStatusUpdateBatch
 */
@isTest
public with sharing class CampaignSendEmailStatusUpdateBatchTest {
    static List<Campaign> campaigns;
    static List<Account> sellers ;

    @TestSetup
    static void makeData(){
        sellers = EBH_TestDataFactory.createAccounts(3, 'EBH_Seller');
		sellers[0].OwnerId = UserInfo.getUserId();
		update sellers[0];

        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		User standardUser;
		System.runAs(admin){
			Profile p = [select id from Profile where name='Standard User Profile' limit 1];
            standardUser = new User(alias = 'tsUser', email='TestStardardUser@ebay.com',
                            emailencodingkey='UTF-8', lastname='TestStandardUser', firstname='TestStandardUser', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id,
                            timezonesidkey='America/Los_Angeles', username='TestStardarduser@salesforce.de', isActive = true);
            insert standardUser;
		}

        campaigns = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign', 'DE', 'EBH_AMOutreach',null,'Feasibility');
		campaigns[0].EBH_Channel__c = 'GCX Outreach (Phone)';
		campaigns[0].OwnerId = standardUser.Id;
		campaigns[0].EBH_Site__c = 'DE';
        campaigns[0].EndDate = system.today() -1;

		campaigns[1].EBH_Channel__c = 'GCX Outreach (Phone)';
		campaigns[1].OwnerId = standardUser.Id;
		campaigns[1].EBH_Site__c = 'AU';		
        campaigns[1].EndDate = system.today() +7;

		update campaigns;
    }

    static testMethod void testStatusUpdateAndSendEmail() {
        
        campaigns = [Select Id,Campaign_Type__c,RecordTypeId, EBH_Channel__c, EBH_ChannelMp__c From Campaign]; 
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute()); 
        String ss = String.valueOf(Datetime.now().second());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        Feature_Switch__c featureSwitch = new Feature_Switch__c();
        featureSwitch.Update_Campaign_Status_to_Stopped__c = true;
        insert featureSwitch;

        Test.startTest();
            CampaignSendEmailStatusUpdateScheduler campaignEmailSchedulerClass = new CampaignSendEmailStatusUpdateScheduler(); 
            System.schedule('Schedule to send email and status update', nextFireTime,campaignEmailSchedulerClass);
        Test.stopTest();

    }
}