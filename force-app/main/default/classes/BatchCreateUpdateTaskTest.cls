/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class BatchCreateUpdateTaskTest {

    static testMethod void testCreateUpdateTask() {
        EBH_TestDataFactory.setUpCustomSettings();  
    	List<Account> sellers = EBH_TestDataFactory.createAccounts(5, 'EBH_Seller') ;

		User integrationUser = [Select Id, name from user Where Name = 'Integration User'];
		System.assertNotEquals(null,integrationUser.Id);
		sellers[4].OwnerId = integrationUser.Id; // 20.07.2021 / Sophal Noch / US-0009938 to coverage where Campaign.Contact.Account.Owner = Integration User.
		update sellers[4];
    	
    	RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
    	EBH_Filter__c sellerList1 = new EBH_Filter__c(Name='test m1',RecordTypeId=rtSellerlist.Id);
    	insert sellerList1;
    	
    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign1', 'UK', 'EBH_AMOutreach',null,'Feasibility');
    	List<Contact> contacts = EBH_TestDataFactory.createContacts(5, 'Test Contact', sellers[0].id);
    	
    	Integer i = 0;
    	for(Contact c: contacts)
    	{
    		c.EBH_PhoneOptOut__c = false; 
    		c.Primary_Contact__c=true;
    		c.EBH_DoNotContact__c=false;
    		c.Incorrect_Phone_Number__c=false;
    		c.AccountId = sellers[i++].Id;
    	}
    	
    	update contacts;
    	
    	campaigns1[0].EBH_Channel__c = EBH_ConstantsUtility.CAMP_CHANNEL_AM_OUTREACH;
    	campaigns1[0].EBH_SellerList__c = sellerList1.Id;
    	update campaigns1;
    	
		Test.startTest();

		List<CampaignMember> listCM0 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,10,System.today()-5,System.today());
		 
    	List<CampaignMember> listCM1 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[1].Id,10,System.today()-5,System.today());
    	List<CampaignMember> listCM2 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[2].Id,10,System.today()-5,System.today());
		List<CampaignMember> listCM3 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[3].Id,10,System.today()-5,System.today());
		List<CampaignMember> listCM4 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[4].Id,10,System.today()-5,System.today());
    	 
    	EBH_TargetedSeller__c ts = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[0].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
    	EBH_TargetedSeller__c ts1 = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[1].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
    	EBH_TargetedSeller__c ts2 = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[2].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
    	EBH_TargetedSeller__c ts3 = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[3].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
		EBH_TargetedSeller__c ts4 = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[4].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
    	insert new List<EBH_TargetedSeller__c>{ts,ts1,ts2,ts3,ts4};
    	
    	Campaign_Targeting__c  ct = new Campaign_Targeting__c(Campaign__c=campaigns1[0].Id,Seller_List__c=sellerList1.Id);
    	insert ct;
    	
    	String campaignId = campaigns1[0].Id;
    	
    	
    	
	    	EBH_InsertCampaignMemberBatch cmBatch = new EBH_InsertCampaignMemberBatch(new Set<Id>{campaignId});
			Database.executeBatch(cmBatch);
			
			//----create new tasks	
	    	BatchCreateUpdateTask b = new BatchCreateUpdateTask(campaignId);
	    	Database.executeBatch(b); 
    	
    	Test.stopTest();
    		
    		listCM0[0].EBH_ResponseCode__c = 22;
			update listCM0[0];
			Task t0 = [Select Id,EBH_CampaignMemberId__c From Task where EBH_CampaignMemberId__c =:listCM0[0].Id];
			
	    	t0.Call_attempts__c = 2;
	    	update t0;
	    	
	    	//System.debug('2 >>>>>>>>>>>>>>>>>>>>>>To Cancelled.....');
	    	//-----to EBH_ConstantsUtility.TASK_STATUS_CANCELLED;
	    	String sWhere = ' Where CampaignId =:campaignId';
	    	List<CampaignMember> listCM_Scope = Database.query(EBH_ConstantsUtility.SOQL_CAM_MEMBER + sWhere);
	    	b.execute(null,listCM_Scope);
	    	
	    	//----re-open the task
	    	//t0.Status = EBH_ConstantsUtility.TASK_STATUS_CANCELLED;
	    	//update t0;
	    	
	    	//listCM_Scope = Database.query(EBH_ConstantsUtility.SOQL_CAM_MEMBER + sWhere);
	    	//b.execute(null,listCM_Scope);
        
    }

    static testMethod void testCreateGCXPhoneOutreachTask() {
		// 20.07.2021 / Sophal Noch / US-0009938 test method for Campaign channel = 'GCX Outreach (Phone)'

        EBH_TestDataFactory.setUpCustomSettings();  

		List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
		sellers[0].OwnerId = UserInfo.getUserId();
		update sellers[0];

		RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
    	EBH_Filter__c sellerList1 = new EBH_Filter__c(Name='test m1',RecordTypeId=rtSellerlist.Id);
    	insert sellerList1;

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

		List<Campaign> campaigns = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign', 'DE', 'EBH_AMOutreach',null,'Feasibility');
		campaigns[0].EBH_Channel__c = 'GCX Outreach (Phone)';
		campaigns[0].OwnerId = standardUser.Id;
		campaigns[0].EBH_Site__c = 'DE';

		campaigns[1].EBH_Channel__c = 'GCX Outreach (Phone)';
		campaigns[1].OwnerId = standardUser.Id;
		campaigns[1].EBH_Site__c = 'AU';

		update campaigns;

		List<Contact> contacts = EBH_TestDataFactory.createContacts(1, 'Test Contact', sellers[0].id);
		contacts[0].EBH_PhoneOptOut__c = false; 
		contacts[0].Primary_Contact__c=true;
		contacts[0].EBH_DoNotContact__c=false;
		contacts[0].Incorrect_Phone_Number__c=false;
		contacts[0].AccountId = sellers[0].Id;
		update contacts[0];

		List<CampaignMember> listCamp1Cm1 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns[0].Id,contacts[0].Id,10,System.today()-5,System.today());
		List<CampaignMember> listCamp2Cm1 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns[1].Id,contacts[0].Id,10,System.today()-5,System.today());

		EBH_TargetedSeller__c ts = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[0].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
		insert ts;

		Campaign_Targeting__c  camp1Ct1 = new Campaign_Targeting__c(Campaign__c=campaigns[0].Id,Seller_List__c=sellerList1.Id);
		Campaign_Targeting__c  camp2Ct1 = new Campaign_Targeting__c(Campaign__c=campaigns[1].Id,Seller_List__c=sellerList1.Id);
    	insert new List<Campaign_Targeting__c>{camp1Ct1,camp2Ct1};
    	
    	String campaign1Id = campaigns[0].Id;
		String campaign2Id = campaigns[1].Id;

		Test.startTest();

			EBH_InsertCampaignMemberBatch campsCmBatch = new EBH_InsertCampaignMemberBatch(new Set<Id>{campaign1Id,campaign2Id});
			Database.executeBatch(campsCmBatch);
			
			//----create new tasks	
			BatchCreateUpdateTask camp1b = new BatchCreateUpdateTask(campaign1Id);
			Database.executeBatch(camp1b); 

			BatchCreateUpdateTask camp2b = new BatchCreateUpdateTask(campaign2Id);
			Database.executeBatch(camp2b); 

		Test.stopTest();

		List<Task> listCreatedTask = [Select Id, OwnerId From Task where WhatId =: campaign1Id Or WhatId =: campaign2Id Order By Id ASC];

		System.assertEquals(standardUser.Id, listCreatedTask[0].OwnerId);
		System.assertEquals(standardUser.Id, listCreatedTask[1].OwnerId);
	

	}
 
}