@isTest
// 29/03/2022/ vadhanak voun/ US-0008153 - Outreach tasks Trigger Deletion if Campaign Members response code 10 or 40
private class EBH_InsertCampaignMemberBatchTest {
    static List<Campaign> campaigns;
    static List<Account> sellers ;
    static List<EBH_TargetedSeller__c> listTS;
    @TestSetup
    static void makeData(){
        EBH_TestDataFactory.setUpCustomSettings();  

		sellers = EBH_TestDataFactory.createAccounts(3, 'EBH_Seller');
		sellers[0].OwnerId = UserInfo.getUserId();
		update sellers[0];

		RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
    	EBH_Filter__c sellerList1 = new EBH_Filter__c(Name='test m1',RecordTypeId=rtSellerlist.Id);
        EBH_Filter__c sellerList2 = new EBH_Filter__c(Name='test m2',RecordTypeId=rtSellerlist.Id);
    	insert new EBH_Filter__c[]{sellerList1,sellerList2};

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

		campaigns[1].EBH_Channel__c = 'GCX Outreach (Phone)';
		campaigns[1].OwnerId = standardUser.Id;
		campaigns[1].EBH_Site__c = 'AU';		

		update campaigns;

		List<Contact> contacts = createContacts(1, 'Test Contact', sellers[0].id);
		contacts[0].EBH_PhoneOptOut__c = false; 
		contacts[0].Primary_Contact__c=true;
		contacts[0].EBH_DoNotContact__c=false;
		contacts[0].Incorrect_Phone_Number__c=false;
		contacts[0].AccountId = sellers[0].Id;
        contacts[0].EBH_GDPRRemoved__c = false;
		//update contacts[0];

        List<Contact> contacts2 = createContacts(1, 'Test Contact', sellers[1].id);
		contacts2[0].EBH_PhoneOptOut__c = false; 
		contacts2[0].Primary_Contact__c=true;
		contacts2[0].EBH_DoNotContact__c=false;
		contacts2[0].Incorrect_Phone_Number__c=false;
		contacts2[0].AccountId = sellers[1].Id;
        contacts2[0].EBH_GDPRRemoved__c = false;

		List<Contact> contacts3 = createContacts(1, 'Test Contact 3', sellers[1].id);
		contacts2[0].EBH_PhoneOptOut__c = false; 
		contacts2[0].Primary_Contact__c=true;
		contacts2[0].EBH_DoNotContact__c=false;
		contacts2[0].Incorrect_Phone_Number__c=false;
		contacts2[0].AccountId = sellers[2].Id;
        contacts2[0].EBH_GDPRRemoved__c = false;

		List<Contact> listAllCont = new List<Contact>();
		listAllCont.addAll(contacts);
		listAllCont.addAll(contacts2);
		listAllCont.addAll(contacts3);

		insert listAllCont;

		List<CampaignMember> listCamp1Cm1 = createCampaignMembers2(1,campaigns[0].Id,contacts[0].Id,10,System.today()-5,System.today());
		List<CampaignMember> listCamp2Cm1 = createCampaignMembers2(1,campaigns[1].Id,contacts2[0].Id,10,System.today()-5,System.today());
		List<CampaignMember> listCamp2Cm2 = createCampaignMembers2(1,campaigns[1].Id,contacts3[0].Id,22,System.today()-5,System.today());

		listCamp1Cm1[0].Marketing_Cloud_Status__c= 'Cancelled';
		listCamp1Cm1[0].EBH_ResponseCode__c = 40;

		List<CampaignMember> listAllCM = new List<CampaignMember>();
		listAllCM.addAll(listCamp1Cm1);
		listAllCM.addAll(listCamp2Cm1);
		listAllCM.addAll(listCamp2Cm2);
		insert listAllCM;

		EBH_TargetedSeller__c ts = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[0].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
		EBH_TargetedSeller__c ts1 = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[1].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='10');
		EBH_TargetedSeller__c ts2 = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[2].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='10');
    	listTS = new List<EBH_TargetedSeller__c>{ts,ts1,ts2};
		//listTS = new List<EBH_TargetedSeller__c>{ts1};
        insert listTS;

		Campaign_Targeting__c  camp1Ct1 = new Campaign_Targeting__c(Campaign__c=campaigns[0].Id,Seller_List__c=sellerList1.Id);
		Campaign_Targeting__c  camp2Ct1 = new Campaign_Targeting__c(Campaign__c=campaigns[1].Id,Seller_List__c=sellerList2.Id);
		 
    	insert new List<Campaign_Targeting__c>{camp1Ct1,camp2Ct1};
    	

        Task t1 = new Task(EBH_CampaignMemberId__c=listCamp1Cm1[0].Id,Call_attempts__c=1);
        Task t2 = new Task(EBH_CampaignMemberId__c=listCamp2Cm1[0].Id,Call_attempts__c=0);
		Task t3 = new Task(EBH_CampaignMemberId__c=listCamp2Cm2[0].Id,Call_attempts__c=0);
        insert new Task[]{t1,t2,t3};

    }
	

    static testMethod void testRefreshMemberCreate() 
    {
        selectData();

        String campaign1Id = campaigns[0].Id;
		String campaign2Id = campaigns[1].Id;
	 
        Set<Id> accounts = new Set<Id>{sellers[0].Id};
        Set<Id> scampaigns = new Set<Id>{ campaign1Id,campaign2Id};
        Map<Id,List<EBH_TargetedSeller__c>> sellerListTargetedSellers = new  Map<Id,List<EBH_TargetedSeller__c>>{sellers[0].Id=>listTS};
        Map<Id, Campaign> sellerIdCampaigns = new  Map<Id, Campaign>{sellers[0].Id => campaigns[0]};

        Test.startTest();

            EBH_InsertCampaignMemberBatch campsCmBatch = new EBH_InsertCampaignMemberBatch(accounts,scampaigns,sellerListTargetedSellers,sellerIdCampaigns);
            Database.executeBatch(campsCmBatch);
        
     
        Test.stopTest();
    }

    static testMethod void testRefreshMemberUpate() 
    {
        selectData();

        String campaign1Id = campaigns[0].Id;
		String campaign2Id = campaigns[1].Id;
            
    	         
		Test.startTest();

			EBH_InsertCampaignMemberBatch campsCmBatch = new EBH_InsertCampaignMemberBatch(new Set<Id>{campaign1Id,campaign2Id});
			Database.executeBatch(campsCmBatch);			
		 
		Test.stopTest();	 
	}

    static void selectData()
    {
         campaigns = [Select Id,Campaign_Type__c,RecordTypeId, EBH_Channel__c, EBH_ChannelMp__c From Campaign]; // 20.05.2022 / Sophal Noch / US-0011717
         sellers = [Select Id From Account];
         listTS = [Select Id,EBH_SellerList__c,EBH_Seller__c,Campaign_Related_Seller_Details__c From EBH_TargetedSeller__c]; // 20.05.2022 / Sophal Noch / US-0011717
    }

	static List<CampaignMember> createCampaignMembers2(Integer numRecords, id campId, Id contId,Decimal resCode,Date firstResDate,Date lastResDate) {
        
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            campaignMembers.add(new CampaignMember(CampaignId = campId, ContactId = contId, EBH_Results__c = 'Sent', 
                                    EBH_ResponseCode__c = resCode, EBH_FirstResponseDate__c  = firstResDate, 
                                    EBH_LastResponseDate__c = lastResDate));
        }

       
        return campaignMembers;
    }
	static List<Contact> createContacts(Integer numRecords, String lastname, Id accId) {
        
        List<Contact> contacts = new List<Contact>();
        RecordType rt = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
        
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            contacts.add(new Contact(EBH_Status__c='Active', LastName = lastname + iCounter, AccountId = accId,recordTypeId = rt.Id, EBH_DataOrigin__c='test'));
        }

        
        return contacts;
    }
}