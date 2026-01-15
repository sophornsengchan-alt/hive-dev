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
private class ReAssignTaskControllerTest {

    static testMethod void testReasign() {
         
     	EBH_TestDataFactory.setUpCustomSettings();  
     	User[] admins = [Select Id From User where ProfileId=:EBH_ConstantsUtility.ADMIN_PROFILE_ID AND ISActive=true limit 2];
     	 
    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(3, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,null,'Feasibility');
    	campaigns1[0].EBH_Channel__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
    	campaigns1[2].Status = EBH_ConstantsUtility.CAMP_STATUS_PAUSED;
    	campaigns1[2].EBH_Channel__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
    	update campaigns1;
    	
    	List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
    	
    	Contact[] listContacts = EBH_TestDataFactory.createContacts(4,'test-xx-gcx-',sellers[0].Id);
    	
    	User[] agents;
    	System.runAs(admins[0])
    	{
    		
    		agents = EBH_TestDataFactory.createUsers(4,EBH_ConstantsUtility.PROFILE_GCX_PARTNER);
    		Integer i = 0;
    		for(User u: agents )
    		{
    			u.ContactId = listContacts[i++].Id;
    		}
    		insert agents;
    	}
    	 
    	System.runAs(admins[1])
    	{
    		  
    		Map<String,Object> mapResult = ReAssignTaskController.apexReAssignTasks(campaigns1[0].Id,new List<String>{},0,new Map<Integer,GCX_User__c>{},1);
    		System.assertEquals('ko',mapResult.get('status'),'no task');
    		System.assertEquals(System.Label.Error_No_OpenTask_Assign,mapResult.get('message'),'No open tasks to reassign.');
    		
    		insert new List<Task>{ 
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=1,Call_attempts__c=0),
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=1,Call_attempts__c=0),
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=1,Call_attempts__c=0),
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=1,Call_attempts__c=0),
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=1,Call_attempts__c=0),
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=1,Call_attempts__c=0),
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=2,Call_attempts__c=0),
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=2,Call_attempts__c=0),
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=2,Call_attempts__c=0),
    			new Task(Status='Open',WhatId=campaigns1[0].Id,Order_Priority__c=2,Call_attempts__c=0)
    		
    		};
    		 
    		mapResult = ReAssignTaskController.apexReAssignTasks(campaigns1[0].Id,new List<String>{},0,new Map<Integer,GCX_User__c>{},1);
    		System.assertEquals('ko',mapResult.get('status'),'no agent');
    		System.assertEquals(System.Label.Error_No_GCX_User_available,mapResult.get('message'),'No available agents for task.');
    		
    		GCX_User__c gcx1 = new GCX_User__c(Campaign_Name__c=campaigns1[0].Id,User_Name__c=agents[0].Id);
    		GCX_User__c gcx2 = new GCX_User__c(Campaign_Name__c=campaigns1[0].Id,User_Name__c=agents[1].Id);
    		GCX_User__c gcx3 = new GCX_User__c(Campaign_Name__c=campaigns1[0].Id,User_Name__c=agents[2].Id);
    		GCX_User__c gcx4 = new GCX_User__c(Campaign_Name__c=campaigns1[0].Id,User_Name__c=agents[3].Id);
    		
    		insert new List<GCX_User__c>{gcx1,gcx2,gcx3,gcx4};
			
			
    		mapResult = ReAssignTaskController.apexReAssignTasks(campaigns1[0].Id,new List<String>{},0,new Map<Integer,GCX_User__c>{},1);
			Map<String,Object> mapChunkedTask = (Map<String,Object>) mapResult.get('mapAllChunk');
			List<List<Object>> lstAllchunk = (List<List<Object>>) mapChunkedTask.get('listAllChunk');
			Map<Integer,GCX_User__c> mapAgents = (Map<Integer,GCX_User__c>) mapResult.get('mapAgents');
			
			mapResult = ReAssignTaskController.apexReAssignTasks(campaigns1[0].Id,(List<String>) lstAllchunk[0],0,mapAgents,1);
			
			mapResult = ReAssignTaskController.apexReAssignTasks(campaigns1[1].Id,new List<String>{},0,new Map<Integer,GCX_User__c>{},1);
			
    		System.assertEquals('ko',mapResult.get('status'),'invalid channel');
    		System.assertEquals(System.Label.Error_Invalid_OutReach_Channel,mapResult.get('message'),'invalid channel');
    		
    		mapResult = ReAssignTaskController.apexReAssignTasks(campaigns1[2].Id,new List<String>{},0,new Map<Integer,GCX_User__c>{},1);
    		System.assertEquals('ko',mapResult.get('status'),'paused');
    		System.assertEquals(System.Label.Error_Campaign_Paused,mapResult.get('message'),'paused');
    	}
    	System.runAs(agents[0])
    	{
    		Map<String,Object>  mapResult = ReAssignTaskController.apexReAssignTasks(campaigns1[0].Id,new List<String>{},0,new Map<Integer,GCX_User__c>{},1);
    		System.assertEquals('ko',mapResult.get('status'),'not gcx super user');
    		System.assertEquals('Only GCX Super User allowed.',mapResult.get('message'),'Only GCX Super User allowed.');
    	}
        
    }
}