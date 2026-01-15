/*************************************************************************************************************************
    @ Change history:  14.12.2023 / Vimean Heng / Fix lock row.
*************************************************************************************************************************/    
@isTest 
public class AssignTaskTestTest 
{
    static testMethod void testMethod1() 
    {
        
        //List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithSellerList(2, 'Test Campaign', 'UK', 'EBH_Campaign',EBH_TestDataFactory.createSellerLists(2, 'Test Seller List', 'Snapshot_Seller_List', System.today() + 365));
        List<Task> ltasks = new List<task>();
        List<Account> la = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        EBH_TestDataFactory.setUpCustomSettings();
        ltasks.add (new Task(whatId=la[0].id,subject='test'));
        insert ltasks;
        
        
        Test.startTest();
        Test.setCurrentPage(Page.AssignTasks);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(ltasks);
        stdSetController.setSelected(ltasks);
        AssignCallTaskController actc = new AssignCallTaskController(stdSetController);
        actc.assignTasks();
        Test.stopTest();
        
    }
    
    
	static testMethod void testMethod2() 
    {
        
        //List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithSellerList(2, 'Test Campaign', 'UK', 'EBH_Campaign',EBH_TestDataFactory.createSellerLists(2, 'Test Seller List', 'Snapshot_Seller_List', System.today() + 365));
        List<Task> ltasks = new List<task>();
        List<Account> la = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        EBH_TestDataFactory.setUpCustomSettings();
        ltasks.add (new Task(whatId=la[0].id,subject='test'));
        insert ltasks;
        
        
        Test.startTest();
        Test.setCurrentPage(Page.AssignTasks);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(ltasks);
        stdSetController.setSelected(ltasks);
        AssignCallTaskController actc = new AssignCallTaskController(stdSetController);
        actc.task.ownerId=null;
        
        actc.assignTasks();    
        actc.cancel();
            
        
        
        Test.stopTest();
        
    }    
    
	static testMethod void testRedirect()
    {
    	EBH_TestDataFactory.setUpCustomSettings();  
    	List<Account> legalEntities = EBH_TestDataFactory.createAccounts(1, 'EBH_LegalEntity') ;
    	
    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(3, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE,null,'Feasibility');
    	
    	List<Contact> contacts = EBH_TestDataFactory.createContacts(1, 'Test Contact', legalEntities[0].id);
    	Test.startTest();
    		List<CampaignMember> listCM = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,10,System.today()-5,System.today());
    		Task t1 = new Task(whatId=campaigns1[0].id,subject='test',EBH_CampaignMemberId__c=listCM[0].Id);
    		insert t1;
    		
    		Test.setCurrentPage(Page.AssignTaskRedirect);
    		
    		//------no error - redirect
	        ApexPages.StandardController stdController = new ApexPages.StandardController(campaigns1[0]);
	        AssignTaskRedirectController contr = new AssignTaskRedirectController(stdController);
        	contr.updateSurveyIdToTasks(); 
        	System.assertEquals(false,contr.isError,'no error');
        	
        	//-------------- task created without survey id
        	campaigns1[0].EBH_TaskCreated__c = true;
        	campaigns1[0].Survey_ID__c = null;
    		update campaigns1[0];
        	stdController = new ApexPages.StandardController(campaigns1[0]);
        	contr = new AssignTaskRedirectController(stdController);
        	System.assertEquals(true,contr.isError,'hide button');
        	
        	contr.updateSurveyIdToTasks(); 
        	system.debug('>>>:isError: '+contr.isError);
        	
        	System.assert(!contr.msg.contains(System.Label.WarningTaskAlreadyCreated ),'show error');
        	 
        	//--------------- task created with survey id
        	campaigns1[0].Survey_ID__c = '123456';
    		update campaigns1[0];
    		stdController = new ApexPages.StandardController(campaigns1[0]);
        	contr = new AssignTaskRedirectController(stdController);
        	System.assert(contr.msg.contains(System.Label.WarningTaskAlreadyCreated ),'show message with button');
        	contr.updateSurveyIdToTasks(); 
        	System.assertEquals(false,contr.isError,'show button');
        	system.debug('>>>:contr.msg: '+contr.msg);
        	System.assert(contr.msg.contains('Survey Id has been updated to tasks.' ),'show message with button');
        	
        	//--------------- no related task
        	campaigns1[2].EBH_TaskCreated__c = true;
        	campaigns1[2].Survey_ID__c = '123456';
    		update campaigns1[2];
    		stdController = new ApexPages.StandardController(campaigns1[2]);
        	contr = new AssignTaskRedirectController(stdController);
        	contr.updateSurveyIdToTasks(); 
        	System.assertEquals(true,contr.isError,'show error');
        	system.debug('>>>:contr.msg: '+contr.msg);
        	System.assert(contr.msg.contains('No Related Task'),'show error');
        	
        	contr.redirect(); 
        	
        	contr.allowRedirect = true;
        	contr.redirect(); 
        	 
    	Test.stopTest();
    	
    }
    
    static testMethod void testCreateTask()
    {
    	
    	EBH_TestDataFactory.setUpCustomSettings();  
    	List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
    	
    	RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
    	EBH_Filter__c sellerList1 = new EBH_Filter__c(Name='test m1',RecordTypeId=rtSellerlist.Id);
    	insert sellerList1;
    	
    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE,null,'Feasibility');
    	List<Contact> contacts = EBH_TestDataFactory.createContacts(4, 'Test Contact', sellers[0].id);
    	
    	contacts[0].EBH_PhoneOptOut__c = false;
    	contacts[1].EBH_PhoneOptOut__c = false;
    	contacts[2].EBH_PhoneOptOut__c = false;
    	contacts[3].EBH_PhoneOptOut__c = false;
    	update contacts;
    	
    	campaigns1[0].EBH_ChannelMP__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
    	campaigns1[0].EBH_SellerList__c = sellerList1.Id;
    	update campaigns1;
    	
    	List<CampaignMember> listCM0 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,10,System.today()-5,System.today());
    	List<CampaignMember> listCM1 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[1].Id,10,System.today()-5,System.today());
    	List<CampaignMember> listCM2 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[2].Id,10,System.today()-5,System.today());
    	 
    	
    	EBH_TargetedSeller__c ts = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[0].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
    	EBH_TargetedSeller__c ts1 = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[1].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
    	insert new List<EBH_TargetedSeller__c>{ts,ts1};
    	
    	Campaign_Targeting__c  ct = new Campaign_Targeting__c(Campaign__c=campaigns1[0].Id,Seller_List__c=sellerList1.Id);
    	insert ct;
    	
    	Test.startTest();
    	
    	Test.setCurrentPage(Page.AssignTasks);
	    	ApexPages.StandardController stdController = new ApexPages.StandardController(campaigns1[0]);
	    	AssignTasksController con = new AssignTasksController(stdController);
	    	con.validUser = false;
	    	con.showConfirmNumber = false;
	    	con.assignCallTasks();
	    	con.createUpdateTasks();
	    	
    		con.insertedTasks = 1;
    		
    		con.validUser = true;
    		con.assignCallTasks();
    		
    		con.recordOK = false;
    		con.assignCallTasks();
    		
    		campaigns1[0].EBH_Channel__c = EBH_ConstantsUtility.CAMP_CHANNEL_AM_OUTREACH;
    		campaigns1[0].RecordTypeId = ApexUtil.getRecordTypeByName('Campaign', 'EBH_AMOutreach').Id;
    		update campaigns1;
    	
    		campaigns1[0].survey_id__c = null;
    		con.recordOK = true;
    		con.assignCallTasks();
    		
    		con.validUser = true;
    		con.recordOK = true;
    		con.cRecord.survey_id__c = 'xxxyyyzzz';
    		con.cRecord.EBH_TaskCreated__c = false;
    		con.assignCallTasks();
    		
    		con.cancel();
	}
	//@ Change history:  14.12.2023 / Vimean Heng / US-0014423 / Fix lock row.
	static testMethod void testCreateTaskForPLAdsTeam()
    {
    	User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		//User[] plAdsUser = EBH_TestDataFactory.createUsers(1,AssignTasksController.PROFILE_STANDARD_ADS_USER);
		//VM: 14.12.2023: US-0014423: ignore flow assign role by assign user role.
		User plAdsUser = EBH_TestDataFactory.createUser('Chatter Free User');
		User us = EBH_TestDataFactory.createUser(AssignTasksController.PROFILE_STANDARD_ADS_USER);
		System.runAs(admin){
			EBH_TestDataFactory.setUpCustomSettings();  
			insert plAdsUser;
			plAdsUser.ProfileId = us.ProfileId;
			update plAdsUser;
		}
		System.runAs(new User(Id=UserInfo.getUserId())){
			PermissionSet[] ps = Database.query(EBH_ConstantsUtility.SOQL_PERMISSIONSET + ' WHERE Name=\'GCX_Super_User\'');
			insert new PermissionSetAssignment(AssigneeId = plAdsUser.id, PermissionSetId = ps[0].Id);
		}

		System.runAs(plAdsUser) {

			List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
    	
			RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
			EBH_Filter__c sellerList1 = new EBH_Filter__c(Name='test m1',RecordTypeId=rtSellerlist.Id);
			insert sellerList1;
			
			List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE,null,'Feasibility');
			List<Contact> contacts = EBH_TestDataFactory.createContacts(4, 'Test Contact', sellers[0].id);
			
			contacts[0].EBH_PhoneOptOut__c = false;
			contacts[1].EBH_PhoneOptOut__c = false;
			contacts[2].EBH_PhoneOptOut__c = false;
			contacts[3].EBH_PhoneOptOut__c = false;

			//NSP:30/07/2021: US-0009970 use 'EBH_MANUAL' record type to bypass validation rule error.
			RecordType rt = [SELECT id,sobjectType,DeveloperName from RecordType Where sobjectType = 'Contact' AND DeveloperName = 'EBH_MANUAL'];
			contacts[0].RecordTypeId = rt.Id;
			contacts[1].RecordTypeId = rt.Id;
			contacts[2].RecordTypeId = rt.Id;
			contacts[3].RecordTypeId = rt.Id;

			update contacts;
			
			campaigns1[0].EBH_ChannelMP__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
			campaigns1[0].EBH_SellerList__c = sellerList1.Id;
			update campaigns1;
			
			List<CampaignMember> listCM0 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,10,System.today()-5,System.today());
			List<CampaignMember> listCM1 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[1].Id,10,System.today()-5,System.today());
			List<CampaignMember> listCM2 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[2].Id,10,System.today()-5,System.today());
			
			
			EBH_TargetedSeller__c ts = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[0].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
			EBH_TargetedSeller__c ts1 = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[1].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='20');
			insert new List<EBH_TargetedSeller__c>{ts,ts1};
			
			Campaign_Targeting__c  ct = new Campaign_Targeting__c(Campaign__c=campaigns1[0].Id,Seller_List__c=sellerList1.Id);
			insert ct;
			
			Test.startTest();
			
			Test.setCurrentPage(Page.AssignTasks);
				ApexPages.StandardController stdController = new ApexPages.StandardController(campaigns1[0]);
				AssignTasksController con = new AssignTasksController(stdController);
				con.validUser = false;
				con.usr = new User(Id=UserInfo.getUserId());
				con.showConfirmNumber = false;
				con.assignCallTasks();
				con.createUpdateTasks();
				
				con.insertedTasks = 1;
				
				con.validUser = true;
				con.assignCallTasks();
				
				con.recordOK = false;
				con.assignCallTasks();
				
				campaigns1[0].EBH_Channel__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
				campaigns1[0].RecordTypeId = ApexUtil.getRecordTypeByName('Campaign', 'EBH_AMOutreach').Id;
				update campaigns1;
			
				campaigns1[0].survey_id__c = null;
				con.recordOK = true;
				con.assignCallTasks();
				
				//Repress button
				con = new AssignTasksController(stdController);
				con.assignCallTasks();
				
				con.cancel();
			Test.stopTest();

		}

    	
    }
     
}