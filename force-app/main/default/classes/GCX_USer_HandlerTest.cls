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
private class GCX_USer_HandlerTest {

    static testMethod void testRemoveGCX() {
        
        EBH_TestDataFactory.setUpCustomSettings();  
     	User[] admins = [Select Id From User where ProfileId=:EBH_ConstantsUtility.ADMIN_PROFILE_ID AND ISActive=true limit 2];
     	 
    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,null,'Feasibility');
    	campaigns1[0].EBH_Channel__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
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
    		GCX_User__c gcx1 = new GCX_User__c(Campaign_Name__c=campaigns1[0].Id,User_Name__c=agents[0].Id);
    		GCX_User__c gcx2 = new GCX_User__c(Campaign_Name__c=campaigns1[0].Id,User_Name__c=agents[1].Id);
    		GCX_User__c gcx3 = new GCX_User__c(Campaign_Name__c=campaigns1[0].Id,User_Name__c=agents[2].Id);
    		GCX_User__c gcx4 = new GCX_User__c(Campaign_Name__c=campaigns1[0].Id,User_Name__c=agents[3].Id);
    		insert new List<GCX_User__c>{gcx1,gcx2,gcx3,gcx4};
    		
    		Test.startTest();
	    		gcx1.Active__c = false;
	    		gcx2.Active__c = false;
	    		update new GCX_User__c[]{gcx1,gcx2};
    		Test.stopTest();
    		
    		String campId = campaigns1[0].Id;
    		GCX_User__c[] listGCXUsers = Database.query(EBH_ConstantsUtility.SOQL_GCX_USER +' Where Campaign_Name__c =:campId');
    		System.assertEquals(2,listGCXUsers.size(),'2 have been removed by trigger');
    	}
    }
}