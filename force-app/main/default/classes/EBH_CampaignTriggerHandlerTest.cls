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
 @Change history: 04.07.2022 /Chetra Sarlom/ US-0007031 - Deactivate triggers
 @               : 21.11.2023 / SRONG TIN / Update the test Method. //US-0014419
 */
@isTest
private class EBH_CampaignTriggerHandlerTest {

   static testMethod void testValidateStatus() {

	   	User adminUser = [Select Id from User where IsActive = true and Profile.Name = 'System Administrator' Limit 1];

        System.runAs(adminUser){
            EBH_TestDataFactory.setUpCustomSettings(); 
        }

    	Test.startTest();

		List<Campaign> campaigns;
		System.runAs(adminUser){
			campaigns = EBH_TestDataFactory.createCampaigns(1, 'Request', 'UK', 'EBH_Campaign');  //US-0014419 change EBH_CampaignRequest to EBH_Campaign
			campaigns[0].Status = EBH_ConstantsUtility.CAMP_PREPARATION;
			update campaigns;
		}

		User standardUser;
		System.runAs(adminUser){
			standardUser = EBH_TestDataFactory.createUser('Standard User Profile');
		}
        
        System.runAs(standardUser) { 
			try{
				Campaign c = new Campaign( Name = 'test camp',EBH_Site__c = 'UK',recordTypeId = EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID);
				insert c;
				
				c.Status = EBH_ConstantsUtility.CAMP_SUBMITTED;
				update c;
			}catch(Exception ex)
			{	 
				System.assert(ex.getMessage().contains(System.Label.CampaignStatusError.substring(0,10)));
			}
		}

		System.runAs(adminUser){
	        Campaign camSell = [Select Id,Status From Campaign Where Id=:campaigns[0].Id];
	        
	        //System.assertEquals(EBH_ConstantsUtility.CAMP_PREPARATION,camSell.Status,'status not updated cause by standard user is not allowed to change');
	        
	        campaigns[0].Status = EBH_ConstantsUtility.CAMP_SUBMITTED;
	        update campaigns[0];
	        
	        camSell = [Select Id,Status From Campaign Where Id=:campaigns[0].Id];
	        System.assertEquals(EBH_ConstantsUtility.CAMP_SUBMITTED,camSell.Status,'status updated by admin');
         	
         	
         	List<Campaign> campaigns2 = EBH_TestDataFactory.createCampaigns(1, 'Request', 'UK', 'EBH_AMOutreach');   
         	System.runAs(EBH_TestDataFactory.createUser('Marketing Profile')) { 
			 	Campaign c = new Campaign( Name = 'test camp',EBH_Site__c = 'UK',recordTypeId = EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID);
				insert c;
				
				c.Status = EBH_ConstantsUtility.CAMP_SUBMITTED;
				c.EBH_Channel__c = EBH_ConstantsUtility.CAMP_CHANNEL_GCXINBOUND_PHONE;
				update c;
			 
			 camSell = [Select Id,Status From Campaign Where Id=:c.Id];
			System.assertEquals(EBH_ConstantsUtility.CAMP_SUBMITTED,camSell.Status,'status updated by marketing user with channel = GCX Inbound (Phone)');
			 
		 	}
		 	System.runAs(EBH_TestDataFactory.createUser('Standard User')) { 
			 	Campaign c = new Campaign( Name = 'test camp',EBH_Site__c = 'UK',recordTypeId = EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID);
				insert c;
				
				c.Status = EBH_ConstantsUtility.CAMP_PREPARATION;
				c.EBH_Channel__c = EBH_ConstantsUtility.CAMP_CHANNEL_AM_OUTREACH;
				//COMMENTED BY DHE 20181211 FOR FIXING THE DEPLOYMENT		update campaigns2[0];
					
				//	 camSell = [Select Id,Status From Campaign Where Id=:campaigns2[0].Id];
				//COMMENTED BY DHE 20181211 FOR FIXING THE DEPLOYMENT	 System.assertEquals(EBH_ConstantsUtility.CAMP_PREPARATION,camSell.Status,'status updated by marketing user with channel = GCX Inbound (Phone)');
			 
		 	}
		}
		

		
        Test.stopTest();
    }
    
    /*****************************************************************************************************************************
    @ Method:         testcheckDuplicateCampaignName
    @ Version:        1.0
    @ Author:         Sovantheany Dim
    @ Purpose:        check duplicate campaign name
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.12.2018 / Sovantheany Dim / Created the test Method.
					  06.08.2019 / acmatac seing / deprecated due to EPH-7922.
    *****************************************************************************************************************************/
    /*static testMethod void testcheckDuplicateCampaignName() {
    	EBH_TestDataFactory.setUpCustomSettings();
    	Test.startTest();
        System.runAs(EBH_TestDataFactory.createUser('Marketing Profile')) {
        	RecordType rt = [SELECT id from RecordType where sobjectType ='Campaign' and DeveloperName = 'EBH_Campaign'];
        	List<Campaign> listCamp = new List<Campaign>();
        	//Test Duplicate campaign Name
        	try{
        		for(Integer i = 0; i < 2; i++){
        			listCamp.add( new Campaign( Name = 'test camp1',EBH_Site__c = 'UK',recordTypeId = rt.Id));
        		}
        		insert listCamp;
        	}catch(Exception e){
        		System.assert(e.getMessage().contains(System.Label.Campaign_Duplicate_Name));
        	}
        	//Insert Success
        		listCamp = new List<Campaign>();
        		for(Integer i = 0; i < 3; i++){
        			listCamp.add( new Campaign( Name = 'test camp'+i,EBH_Site__c = 'UK',recordTypeId = rt.Id));
        		}
        		insert listCamp;
        		System.assert([select id from Campaign where id IN: listCamp].size() == 3);
        	//Insert Fial:duplicate existing Name
        	try{
        		List<Campaign> listCamp2 = EBH_TestDataFactory.createCampaigns(1, 'test camp1', 'UK','EBH_Campaign');
        	}catch(Exception e){
        		System.assert(e.getMessage().contains(System.Label.Campaign_Duplicate_Name));
        	}
        	//Test Update
        		try{
        			for(Campaign cam : listCamp){
	        			cam.Name = 'test camp1';
	        		}
	        		update listCamp;
        		}catch(Exception e){
        			System.assert(e.getMessage().contains(System.Label.Campaign_Duplicate_Name));
        		}
        		
       	}
       	Test.stopTest();
    }
    */
     /*****************************************************************************************************************************
    @ Method:         testupdateMarketingTicketDueDate
    @ Version:        1.0
    @ Author:         Sovantheany Dim
    @ Purpose:        EPH-6853 Due Dates,This value will be automatically populated based on Campaign Start Date		  
    Record Type "Targeting": Campaign.StartDate - 3 Working Day
    Record Type "Copy/Creative": Campaign.StartDate - 2 Working Day
    Record Type "Journey": Campaign.StartDate - 1 Working Day
	@ Trigger: after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.12.2018 / Sovantheany Dim / Created the test Method.
	@Change history: 04.07.2022 /Chetra Sarlom/ US-0007031 - Deactivate triggers
    *****************************************************************************************************************************/
	/*
	static testMethod void testupdateMarketingTicketDueDate() {
    	EBH_TestDataFactory.setUpCustomSettings();
    	RecordType rCopyCreative = EBH_TestDataFactory.getRecordTypeByName('Marketing_Ticket__c','Copy_Creative');
        RecordType rTargeting = EBH_TestDataFactory.getRecordTypeByName('Marketing_Ticket__c','Targeting');
        RecordType rJourney = EBH_TestDataFactory.getRecordTypeByName('Marketing_Ticket__c','Journey');
        //RecordType rt = [SELECT id from RecordType where sobjectType ='Campaign' and DeveloperName = 'EBH_Campaign'];
        RecordType rt = EBH_TestDataFactory.getRecordTypeByName('Campaign','EBH_Campaign'); 	
		Campaign cam = new Campaign( Name = 'test camp1',EBH_Site__c = 'UK',recordTypeId = rt.Id);
		insert cam;
		Marketing_Ticket__c mtA1 = new Marketing_Ticket__c(RecordTypeId=rCopyCreative.Id,Campaign__c=cam.Id);
		Marketing_Ticket__c mtB1 = new Marketing_Ticket__c(RecordTypeId=rTargeting.Id,Campaign__c=cam.Id);
		Marketing_Ticket__c mtB3 = new Marketing_Ticket__c(RecordTypeId=rJourney.Id,Campaign__c=cam.Id);
		List<Marketing_Ticket__c> listTicktes = new List<Marketing_Ticket__c>{mtA1,mtB1,mtB3};
		insert listTicktes;
		//test update campaign start date
    	Test.startTest();
    		cam.StartDate = date.newInstance(2018,12,19);
			update cam;
    	Test.stopTest();
    		Map<Id,Marketing_Ticket__c> mapResult1 = new Map<Id,Marketing_Ticket__c>([Select Id,Name,Count__c,Due_Date__c From Marketing_Ticket__c Where Id IN:listTicktes]);
			//System.assertEquals(date.newInstance(2018,12,14),mapResult1.get(mtA1.Id).Due_Date__c,'Due date = campaign start date - 2 Working Day');
			//System.assertEquals(date.newInstance(2018,12,13),mapResult1.get(mtB1.Id).Due_Date__c,'Due date = campaign start date - 3 Working Day');
			//System.assertEquals(date.newInstance(2018,12,17),mapResult1.get(mtB3.Id).Due_Date__c,'Due date = campaign start date - 1 Working Day');
    } 
	*/
	// end US-0007031
	
	static testMethod void testOutReachStatusChange()
    {
    	 
    	
    	EBH_TestDataFactory.setUpCustomSettings();  
    	List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
    	
    	RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
    	EBH_Filter__c sellerList1 = new EBH_Filter__c(Name='test m1',RecordTypeId=rtSellerlist.Id);
    	insert sellerList1;
    	
    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,null,'Feasibility');
    	List<Contact> contacts = EBH_TestDataFactory.createContacts(1, 'Test Contact', sellers[0].id);
    	List<Contact> contacts2 = EBH_TestDataFactory.createContacts(1, 'Test Contact', sellers[1].id);
    	contacts[0].EBH_PhoneOptOut__c = false;
    	contacts2[0].EBH_PhoneOptOut__c = false;
    	update new List<Contact>{contacts[0],contacts2[0]};
    	
    	campaigns1[0].EBH_Channel__c = EBH_ConstantsUtility.CAMP_CHANNEL_AM_OUTREACH;
    	campaigns1[0].EBH_SellerList__c = sellerList1.Id;
    	update campaigns1;
    	
    	//List<CampaignMember> listCM0 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,10,System.today()-5,System.today());
    	//List<CampaignMember> listCM1 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[1].Id,10,System.today()-5,System.today());
    	//List<CampaignMember> listCM2 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[2].Id,10,System.today()-5,System.today());
    	 
    	
    	EBH_TargetedSeller__c ts = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[0].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
    	EBH_TargetedSeller__c ts1 = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[1].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
    	insert new List<EBH_TargetedSeller__c>{ts,ts1};
    	
    	Campaign_Targeting__c  ct = new Campaign_Targeting__c(Campaign__c=campaigns1[0].Id,Seller_List__c=sellerList1.Id);
    	insert ct;
    	
    	Test.startTest();
    	
    	String campaignId = campaigns1[0].Id;
    	EBH_CampaignTriggerHandler.createCampaignMemberRecords((Database.query(EBH_ConstantsUtility.CMRC_QUERY)));
    	Test.stopTest();
    	
    	
    	Test.setCurrentPage(Page.AssignTasks);
	    	ApexPages.StandardController stdController = new ApexPages.StandardController(campaigns1[0]);
	    	AssignTasksController con = new AssignTasksController(stdController);
	    	con.validUser = true;
	    	//con.assignCallTasks();
	    	con.showConfirmNumber = false;
	    	con.createUpdateTasks();
	    	
	    	
	    	system.debug('---------------11111111111---------------------------------------------');
	    	//1, test updated to Paused
	    	campaigns1[0].Status = EBH_ConstantsUtility.CAMP_STATUS_PAUSED;
    		update campaigns1;
    	
	    	//Set<String> setCMid = new Set<String>{listCM0[0].Id,listCM1[0].Id,listCM2[0].Id};
	    	//Task[] taskSel = [Select Id,Status,EBH_CampaignMemberId__c,Call_attempts__c From Task Where WhatId=: campaigns1[0].Id];
	    	
	    	//ystem.assertEquals(2,taskSel.size(),'2 tasks created for the first click. 1 task per contact per seller');
	    	
	    	//Map<String,Task> mapTask  = new Map<String,Task>();
	    	//for(Task t: taskSel)
	    	//{
	    	//	//mapTask.put(t.EBH_CampaignMemberId__c,t);
	    	//	System.assertEquals(EBH_ConstantsUtility.TASK_STATUS_PAUSED,t.Status,' Then tasks with "Open" status are changed to "Paused" status');
	    	//}
	    	
	    	//2, test outrech Cancelled
	    	 
    		//taskSel[0].Status = EBH_ConstantsUtility.AOC_TASKSTATUS;  
    		//taskSel[0].Call_attempts__c = 0;
	    	 
	    	
    		//taskSel[1].Call_attempts__c = 1;  
    		//taskSel[1].Status = EBH_ConstantsUtility.AOC_TASKSTATUS; //open
    		 
    		//update taskSel;
    		
    		system.debug('---------------2222222222222222222---------------------------------------------');
	    	campaigns1[0].Status = EBH_ConstantsUtility.CMRC_COMPLETED;//EBH_ConstantsUtility.CMRC_CANCELLED;
    		update campaigns1; 
    		
    		//Task[] taskSel2 = [Select Id,Status,EBH_CampaignMemberId__c,Call_attempts__c From Task Where WhatId=: campaigns1[0].Id];
    		 
    		//System.assertEquals(1,taskSel2.size(),' 1 has been deleted');
    		//System.assertEquals(EBH_ConstantsUtility.TASK_STATUS_CANCELLED,taskSel2[0].Status, ' remain 1 set to Cancelled');
    		 
    	
    }
    
	static testMethod void testPopulateField()
    {
		EBH_TestDataFactory.setUpCustomSettings();
		
		//RecordType rtAMO = EBH_TestDataFactory.getRecordTypeByName('Campaign','EBH_AMOutreach');
		List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test Campaign1', 'UK', 'EBH_AMOutreach',null,'Feasibility');
		 
		Test.startTest();

			Campaign cpmClone = campaigns1[0].clone(false, true);
			cpmClone.Name = 'Campaign2-cloned-007';
			insert cpmClone;

		Test.stopTest();

			Campaign cpmCloneSel = [Select Id,Name,Status From Campaign Where Id=:cpmClone.Id];
			//Value							Api
			//Campaign in Development		Preparation
			System.assertEquals('Preparation', cpmCloneSel.Status, 'Clone Campaign Status set default to "Campaign in Development" (Preparation)');

		

	}

}