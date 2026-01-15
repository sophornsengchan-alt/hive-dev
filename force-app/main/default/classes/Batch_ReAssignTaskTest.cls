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
private class Batch_ReAssignTaskTest {

    static testMethod void testReassign() {
       EBH_TestDataFactory.setUpCustomSettings(); 
       User[] admins = [Select Id From User where ProfileId=:EBH_ConstantsUtility.ADMIN_PROFILE_ID AND ISActive=true limit 2];
        
       List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(3, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,null,'Feasibility');
       campaigns1[0].EBH_Channel__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
       campaigns1[1].EBH_Channel__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
       update campaigns1;
       
       List<Account> sellers = EBH_TestDataFactory.createAccounts(3, 'EBH_Seller');
       List<Contact> contacts = EBH_TestDataFactory.createContacts(1, 'Test Contact1', sellers[0].id);
       List<Contact> contacts2 = EBH_TestDataFactory.createContacts(1, 'Test Contact2', sellers[1].id);
       List<Contact> contacts3 = EBH_TestDataFactory.createContacts(1, 'Test Contact3', sellers[2].id);
       List<Contact> contacts4 = EBH_TestDataFactory.createContacts(1, 'Test Contact3', sellers[2].id);
       
       List<CampaignMember> listCM = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,10,System.today()-5,System.today());
       List<CampaignMember> listCM2 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts2[0].Id,10,System.today()-5,System.today());
       List<CampaignMember> listCM3 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[1].Id,contacts3[0].Id,10,System.today()-5,System.today());
       List<CampaignMember> listCM4 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[2].Id,contacts4[0].Id,10,System.today()-5,System.today());
       
       List<Task> listTasks = new List<Task>{ 
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=1,Call_attempts__c=0,EBH_ResponseCode__c=10,EBH_CampaignMemberId__c=listCM[0].Id),
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=2,Call_attempts__c=0,EBH_ResponseCode__c=10,EBH_CampaignMemberId__c=listCM2[0].Id),
    			new Task(Status='Open',WhatId=campaigns1[1].Id,Order_Priority__c=2,Call_attempts__c=0,EBH_ResponseCode__c=10,EBH_CampaignMemberId__c=listCM3[0].Id),
    			new Task(Status='Open',WhatId=campaigns1[2].Id,Order_Priority__c=2,Call_attempts__c=0,EBH_ResponseCode__c=10,EBH_CampaignMemberId__c=listCM4[0].Id)
    		};
    	insert listTasks;
  		
  		User[] agents;
    	System.runAs(admins[0])
    	{
    		agents = EBH_TestDataFactory.createUsers(4,EBH_ConstantsUtility.PROFILE_GCX_PARTNER);
    		 
			agents[0].ContactId = contacts[0].Id;
			agents[1].ContactId = contacts2[0].Id;
			agents[2].ContactId = contacts3[0].Id;
			agents[3].ContactId = contacts4[0].Id;
    		 
    		insert agents;
    	}
    	
		GCX_User__c gcx1 = new GCX_User__c(Campaign_Name__c=campaigns1[0].Id,User_Name__c=agents[0].Id,Active__c=True);
		GCX_User__c gcx2 = new GCX_User__c(Campaign_Name__c=campaigns1[0].Id,User_Name__c=agents[1].Id,Active__c=True);
		GCX_User__c gcx3 = new GCX_User__c(Campaign_Name__c=campaigns1[0].Id,User_Name__c=agents[2].Id,Active__c=True);
		GCX_User__c gcx4 = new GCX_User__c(Campaign_Name__c=campaigns1[1].Id,User_Name__c=agents[3].Id,Active__c=True);
    		
		List<GCX_User__c> listGCX = new List<GCX_User__c>{gcx1,gcx2,gcx3,gcx4};
		insert listGCX;  		
		
		String subCampaignRT = ApexUtil.getRecordTypeByName('Campaign', EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE).Id;
		String statusOpen = 'Open';
    	String GCXOutReachCampChannel = EBH_ConstantsUtility.CAMPAIGN_CHANNEL_GCX_OUTREACH;
    
       Test.startTest();
	       Set<Id> setCampaign = new Set<Id>{campaigns1[0].Id,campaigns1[1].Id,campaigns1[2].Id};
	       Batch_ReAssignTask b = new Batch_ReAssignTask(setCampaign);
	       List<Task> scope = Database.query(EBH_ConstantsUtility.SOQL_TASK+b.sWhereTask);
	       b.execute(null,new List<Task>{scope[0]});
	       b.execute(null,new List<Task>{scope[1]});
	       b.execute(null,new List<Task>{scope[2]});
	       b.execute(null,new List<Task>{scope[3]});
       Test.stopTest();
			Task t1 = [Select Id,OwnerId from Task Where Id=:scope[0].Id];
			Task t2 = [Select Id,OwnerId from Task Where Id=:scope[1].Id];
			
		//	String sWhereGCX = ' Where Campaign_Name__c IN:setThisCampIds And Active__c=True AND User_Name__c <> NULL';
			GCX_User__c[] sel_agents = [Select Id,Name,Campaign_Name__c,User_Name__c From GCX_User__c Where Id IN:listGCX Order BY NAME ASC];
			//System.debug('>>>sel_agents: '+sel_agents);
		
			System.assertEquals(sel_agents[0].User_Name__c,t1.OwnerId);     
			//System.assertEquals(sel_agents[1].User_Name__c,t2.OwnerId);

        
        Database.executeBatch(b);
    }
}