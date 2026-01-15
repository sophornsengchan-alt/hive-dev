/*********************************************************************************************************************************
@ Class:          EBH_CampaignMemberRefreshControllerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_AttachmentTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.06.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_CampaignMemberRefreshControllerTest {
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testCampaignMemberRefresh(); }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testCampaignMemberRefresh(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testCampaignMemberRefresh
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) System should be able to create the Targeted Sellers based on the attachment
                                    uploaded on Seller List Snapshot record, It will delete previous Targeted Sellers &
                                    creates the new Targeted Sellers
                      COVERAGES (*) testCampaignMemberRefresh(): Creates the Seller records
                                    Attachment records on Seller List Snapshot object
                                    Attachment Trigger and Handler class
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testCampaignMemberRefresh() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        //EBH_TestDataFactory.setUpCampaignKPITriggerHandlerData();
        
        Test.startTest();
       // EBH_TestDataFactory.setUpCampaignMemberBatchData(); 
         
       
        EBH_TestDataFactory.setUpStrategicCampaignData();
        
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
                         
            
            /*Excecute test*/
            
            Campaign pRecord = [SELECT id from Campaign][0];
            /*Validate test*/
          //  System.assertEquals( 0, [SELECT id from CampaignMember where campaignId = :pRecord.id].size());
           // System.assertEquals( 2, [SELECT id from EBH_TargetedSeller__c].size());
            EBH_CampaignMemberRefreshController controller = new EBH_CampaignMemberRefreshController(
            new ApexPages.standardController(pRecord)); 
          //  System.assertEquals( 5, [SELECT id from CampaignMember].size());
            controller.refreshFilter();
			
			pRecord.Status = EBH_ConstantsUtility.CMRC_EXECUTION;
			pRecord.EBH_Channel__c = EBH_ConstantsUtility.CAMP_CHANNEL_AM_OUTREACH;
			pRecord.recordtypeId = EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID;
            update   pRecord;
            
            controller = new EBH_CampaignMemberRefreshController(
            new ApexPages.standardController(pRecord)); 
            controller.refreshFilter();
            
              System.assertEquals(controller.validationError,true, 'campaign already in status executed - not allowed');
              System.assert(controller.validateErrorMsg.contains(System.Label.ErrorCampaignMemberRefresh_Executed),' campaign already in status executed');
              
            List<EBH_Filter__c> sellerLists = EBH_TestDataFactory.createSellerLists(1, 'Test Seller List', 
                                                'EBH_AutoRefreshSellerList', System.today() + 365);

          /*  Campaign cRecord = [SELECT id, parentId from Campaign where parentId != null][0];
            cRecord.EBH_SellerList__c = sellerLists[0].id;
            update cRecord;
            Campaign parent = new Campaign(Id = cRecord.ParentId);
            parent.Status = 'Draft';
            update parent;
            controller = new EBH_CampaignMemberRefreshController(
            new ApexPages.standardController(cRecord)); 
            controller.refreshFilter();*/
              
           // System.assertEquals( 2, [SELECT id from EBH_TargetedSeller__c].size());
              
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
           /* Id cID = [SELECT campaignID from CampaignMember limit 1].campaignID;
            controller = new EBH_CampaignMemberRefreshController(
            new ApexPages.standardController(new Campaign(Id = cId))); 
            controller.refreshFilter();*/
           // System.assertEquals( 0, [SELECT id from CampaignMember where campaignId = :cRecord.id].size());
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            
            /*Excecute test*/
            
            /*Validate test*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
             
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/             
            
            /*Excecute test*/
            
            /*Validate test*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
    static testMethod void testRefreshMemberCreate()
    {
    	 
    	
    	EBH_TestDataFactory.setUpCustomSettings();  
    	List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
    	
    	RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
    	EBH_Filter__c sellerList1 = new EBH_Filter__c(Name='test m1',RecordTypeId=rtSellerlist.Id);
    	insert sellerList1;
    	
    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,null,'Feasibility');
    	List<Contact> contacts = EBH_TestDataFactory.createContacts(4, 'Test Contact', sellers[0].id);
    	
    	
    	contacts[0].Primary_Contact__c = true;
    	contacts[2].AccountId = sellers[1].Id;
    	contacts[2].RecordTypeId = ApexUtil.getRecordTypeByName('Contact','EBH_DWH').Id;
    	update contacts;
    	
    	campaigns1[0].EBH_Channel__c = EBH_ConstantsUtility.CAMP_CHANNEL_AM_OUTREACH;
    	update campaigns1;
    	
//    	List<CampaignMember> listCM0 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,10,System.today()-5,System.today());
//    	List<CampaignMember> listCM1 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[1].Id,10,System.today()-5,System.today());
//    	List<CampaignMember> listCM2 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[2].Id,10,System.today()-5,System.today());
    	 
    	
    	EBH_TargetedSeller__c ts = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[0].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='10');
    	EBH_TargetedSeller__c ts1 = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[1].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='10');
    	insert new List<EBH_TargetedSeller__c>{ts,ts1};
    	
    	//List<EBH_TargetedSeller__c> listTS =[Select Id,EBH_Seller__c,EBH_SellerList__c,EBH_ExitCode__c From EBH_TargetedSeller__c];
    	
    	//System.debug('>>List TS New:'+listTS);
    	Campaign_Targeting__c  ct = new Campaign_Targeting__c(Campaign__c=campaigns1[0].Id,Seller_List__c=sellerList1.Id);
    	insert ct;
    	
    	Test.startTest();
    	
    	Test.setCurrentPage(Page.AssignTasks);
	    	ApexPages.StandardController stdController = new ApexPages.StandardController(campaigns1[0]);
	    	EBH_CampaignMemberRefreshController con = new EBH_CampaignMemberRefreshController(stdController);
    	
	    	system.debug('-------------------------------------------------------');
	    	
	    	con = new EBH_CampaignMemberRefreshController(stdController);
	    	con.refreshFilter();
    		
    		Test.stopTest();
    		
    		List<CampaignMember> listSelCM = [Select Id,ContactId,EBH_Seller__c,CampaignId From CampaignMember Where CampaignId =:campaigns1[0].Id];
    	//	System.assertEquals(2,listSelCM.size(),'2 Campaign Member  for 2 sellers of 1 campaign. 1 for primary, 1 for dwh in another seller');
    		
    		
    }
    
    static testMethod void testRefreshMemberCreateOutreachMarketing()
    {
    	 
    	User[] admins = [Select Id,Name From User Where ProfileId =:EBH_ConstantsUtility.ADMIN_PROFILE_ID AND isActive = true limit 2];
    	System.runAs(admins[0])
    	{
    		
    	 	String psName = 'GCX_Super_User';
    		PermissionSet p = [Select Id From PermissionSet Where Name =:psName];
    		PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = p.Id, AssigneeId=admins[1].Id);
    		Database.insert(psa,false);
    	}
    	
    	System.runAs(admins[1])
    	{
    		
    	 
	    	EBH_TestDataFactory.setUpCustomSettings();  
	    	List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
	    	
	    	RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
	    	EBH_Filter__c sellerList1 = new EBH_Filter__c(Name='test m1',RecordTypeId=rtSellerlist.Id);
	    	insert sellerList1;
	    	
	    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,null,'Feasibility');
	    	List<Contact> contacts = EBH_TestDataFactory.createContacts(4, 'Test Contact', sellers[0].id);
	    	
	    	
	    	contacts[0].Primary_Contact__c = true;
	    	contacts[0].EBH_PhoneOptOut__c  = true;
	    	contacts[2].AccountId = sellers[1].Id;
	    	contacts[2].RecordTypeId = ApexUtil.getRecordTypeByName('Contact','EBH_DWH').Id;
	    	contacts[2].EBH_PhoneOptOut__c  = false;
	    	update contacts;
	    	
	    	campaigns1[0].EBH_Channel__c = EBH_ConstantsUtility.CAMP_CHANNEL_AM_OUTREACH;
	    	campaigns1[0].Campaign_Type__c = EBH_ConstantsUtility.OUTREACH_TYPE_MARKETING;
	    	update campaigns1;
	    	
	    	EBH_TargetedSeller__c ts = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[0].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='10');
	    	EBH_TargetedSeller__c ts1 = new EBH_TargetedSeller__c(EBH_Seller__c=sellers[1].Id,EBH_SellerList__c=sellerList1.Id,Priority__c=10,EBH_ExitCode__c='10');
	    	insert new List<EBH_TargetedSeller__c>{ts,ts1};
	    	
	    	//List<EBH_TargetedSeller__c> listTS =[Select Id,EBH_Seller__c,EBH_SellerList__c,EBH_ExitCode__c From EBH_TargetedSeller__c];
	    	
	    	//System.debug('>>List TS New:'+listTS);
	    	Campaign_Targeting__c  ct = new Campaign_Targeting__c(Campaign__c=campaigns1[0].Id,Seller_List__c=sellerList1.Id);
	    	insert ct;
	    	
	    	Test.startTest();
	    	
	    	Test.setCurrentPage(Page.AssignTasks);
		    	ApexPages.StandardController stdController = new ApexPages.StandardController(campaigns1[0]);
		    	EBH_CampaignMemberRefreshController con = new EBH_CampaignMemberRefreshController(stdController);
	    	
		    	system.debug('-------------------------------------------------------');
		    	
		    	con = new EBH_CampaignMemberRefreshController(stdController);
		    	con.refreshFilter();
	    		
	    		Test.stopTest();
	    		
	    		List<CampaignMember> listSelCM = [Select Id,ContactId,EBH_Seller__c,CampaignId From CampaignMember Where CampaignId =:campaigns1[0].Id];
	    		System.assertEquals(1,listSelCM.size(),'1 Campaign Member not created. only 1 for dwh in another seller');
		}
    		
    }
}