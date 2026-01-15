/*********************************************************************************************************************************
@ Class:          EBH_CampaignMemberTriggerHandlerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_CampaignMemberTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.06.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/
@isTest(seeAllData = False)
public class EBH_CampaignMemberTriggerHandlerTest {
    @testSetup
    static void setup(){
    	byPass__c settings = byPass__c.getOrgDefaults();
        settings.Delete_Task_From_Trigger__c = true;
        upsert settings byPass__c.Id;
    }
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testFrontEndMetrics(); }        
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
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testFrontEndMetrics(); }
    }
    /*****************************************************************************************************************************
    @ Method:         testFrontEndMetrics
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) System should be able to rollup the following fields in sellers to its legal entity 
                                    (which is a one to many relationship of one level of depth) 
                                    on insert and update and reparenting:
                                     - GMV
                                     - Revenue 
                                     - Sold Items
                      COVERAGES (*) updateCustomRollUp(): Updates custom roll ups on legal entity from child sellers 
                                        |___hasRollupChanged(): Checks field change in seller
                                        |___hasParentChanged(): Checks parent change in seller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testFrontEndMetrics() {
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        List<CampaignMember> campaignMembers = EBH_TestDataFactory.setUpCampaignMemberTriggerHandlerData();     
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/
        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Excecute test*/
            campaignMembers[0].EBH_Results__c = 'Blocked';
            campaignMembers[1].EBH_Results__c = 'Targeted';
            campaignMembers[2].EBH_Results__c = 'Not Interested';
           /* campaignMembers[0].EBH_HasResponded__c = FALSE;
            campaignMembers[1].EBH_HasResponded__c = FALSE;
            campaignMembers[2].EBH_HasResponded__c = TRUE;*/
            campaignMembers[0].EBH_ResponseCode__c = 60;
            campaignMembers[1].EBH_ResponseCode__c = 160;
            campaignMembers[2].EBH_ResponseCode__c = 110;
            campaignMembers[2].EBH_LastResponseDate__c = system.today();
            update campaignMembers;
            campaignMembers[0].EBH_ResponseCode__c = 50;
            campaignMembers[1].EBH_ResponseCode__c = 90;
            update campaignMembers;
            /*Validate test*/
            //System.assertEquals('Sent',campaignMembers[0].Status);
            //System.assertEquals('Not Reached',campaignMembers[0].EBH_Results__c);
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            /*Excecute test*/
            /*Validate test*/
            campaignMembers[2].EBH_LastResponseDate__c = system.today()-365;
            update campaignMembers;
            System.assertEquals(system.today()-365,campaignMembers[2].EBH_LastResponseDate__c);
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/             
            /*Excecute test*/
            /*Validate test*/
            et4ae5__IndividualEmailResult__c em =new  et4ae5__IndividualEmailResult__c();
            String contactId = [SELECT id from Contact limit 1][0].Id; 
            em.et4ae5__CampaignMemberId__c = campaignMembers[0].Id;
        //    em.et4ae5__Contact_ID__c = [SELECT id from Contact limit 1][0].Id;
            em.et4ae5__HardBounce__c = true;
            em.et4ae5__Contact__c = contactId;
            insert em;
            em =new  et4ae5__IndividualEmailResult__c();
            em.et4ae5__CampaignMemberId__c = campaignMembers[0].Id;
          //  em.et4ae5__Contact_ID__c = [SELECT id from Contact limit 1][0].Id;
            em.et4ae5__SoftBounce__c = true;
            em.et4ae5__Contact__c = contactId;
            insert em;
             em =new  et4ae5__IndividualEmailResult__c();
            em.et4ae5__CampaignMemberId__c = campaignMembers[0].Id;
            //em.et4ae5__Contact_ID__c = [SELECT id from Contact limit 1][0].Id;
           // em.et4ae5__Clicked__c = true;
           em.et4ae5__Contact__c = contactId;
            insert em;
             em =new  et4ae5__IndividualEmailResult__c();
            em.et4ae5__CampaignMemberId__c = campaignMembers[0].Id;
            //em.et4ae5__Contact_ID__c = [SELECT id from Contact limit 1][0].Id;
            em.et4ae5__Opened__c = true;
            em.et4ae5__Contact__c = contactId;
            insert em;
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
	static testMethod void testAggregateCMResponse() {
    	EBH_TestDataFactory.setUpCustomSettings();  
    	List<Account> legalEntities = EBH_TestDataFactory.createAccounts(1, 'EBH_LegalEntity') ;
    	Test.startTest();
    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE,null,'Feasibility');
    	List<Campaign> subcamps1 = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test sub Campaign1', 'UK', EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE,campaigns1[0].Id,'Feasibility');
    	et4ae5__Automated_Send__c triggerSend = new et4ae5__Automated_Send__c();
    	insert triggerSend;
    	subcamps1[0].Triggered_Send_Name__c = triggerSend.Id;
    	update subcamps1[0];
    	List<Contact> contacts = EBH_TestDataFactory.createContacts(2, 'Test Contact', legalEntities[0].id);
    		List<CampaignMember> listCM_master = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,10,System.today()-5,System.today());
    		List<CampaignMember> listCM_Sub = EBH_TestDataFactory.createCampaignMembers2(1,subcamps1[0].Id,contacts[0].Id,40,System.today()-7,System.today()-1);
    	Test.stopTest();
    	String cm_masterId = listCM_master[0].Id;
    	String cm_subId = listCM_Sub[0].Id;
    	//'Select campaignId, ContactId,EBH_ResponseCode__c,EBH_LastResponseDate__c,EBH_FirstResponseDate__c From CampaignMember'
    	CampaignMember cm_master_sel = Database.query(EBH_ConstantsUtility.SOQL_CAM_MEMBER +' Where Id=:cm_masterId');
    	System.assertEquals(40,cm_master_sel.EBH_ResponseCode__c,'code 40 from sub campaign with same contact');
    	System.assertEquals(System.today()-7,cm_master_sel.EBH_FirstResponseDate__c,' System.today()-7  from sub campaign with same contact');
    	System.assertEquals(System.today(),cm_master_sel.EBH_LastResponseDate__c,'System.today() because current cm from master is still bigger');
    	et4ae5__IndividualEmailResult__c ier =new  et4ae5__IndividualEmailResult__c(et4ae5__DateBounced__c=System.today()-5,et4ae5__DateOpened__c=System.today()-4,et4ae5__DateUnsubscribed__c=System.today(),et4ae5__Opened__c=true,et4ae5__TriggeredSendDefinition__c=triggerSend.Id,et4ae5__Contact__c=contacts[0].Id);
    	et4ae5__IndividualEmailResult__c ier2 =new  et4ae5__IndividualEmailResult__c(et4ae5__CampaignMemberId__c=cm_masterId,et4ae5__DateBounced__c=System.today()-5,et4ae5__DateOpened__c=System.today()-4,et4ae5__Opened__c=true,et4ae5__TriggeredSendDefinition__c=triggerSend.Id,et4ae5__Contact__c=contacts[1].Id);
    	insert new list<et4ae5__IndividualEmailResult__c>{ier,ier2};
    	et4ae5__IndividualEmailResult__c ierSel = [Select Id,et4ae5__CampaignMemberId__c,et4ae5__Opened__c From et4ae5__IndividualEmailResult__c Where Id=:ier.Id];
    	System.assertEquals(listCM_Sub[0].Id,ierSel.et4ae5__CampaignMemberId__c,'member assigned from trigger');
    	cm_master_sel = Database.query(EBH_ConstantsUtility.SOQL_CAM_MEMBER +' Where Id=:cm_subId');
    	System.assertEquals(80,cm_master_sel.EBH_ResponseCode__c,'80  "res.et4ae5__DateUnsubscribed__c != null ? 80"  assigned res code');
    	listCM_Sub[0].EBH_ResponseCode__c = null;
    	update listCM_Sub[0];
    	listCM_Sub[0].EBH_ResponseCode__c = 20;
    	update listCM_Sub[0];
    	Campaign subcamps1Sel = [Select Id,Status from Campaign where Id=:subcamps1[0].Id];
    	System.assertEquals(EBH_ConstantsUtility.CMRC_EXECUTION,subcamps1Sel.Status,' Campaign status chagned to executed after first repspone code from campaign member updated');
    }
    private static testMethod void testPopulateTargetDate()
    {
    	    	EBH_TestDataFactory.setUpCustomSettings();  
    	List<Account> legalEntities = EBH_TestDataFactory.createAccounts(1, 'EBH_LegalEntity') ;
    	Test.startTest();
    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE,null,'Feasibility');
    	List<Campaign> subcamps1 = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test sub Campaign1', 'UK', EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE,campaigns1[0].Id,'Feasibility');
    	et4ae5__Automated_Send__c triggerSend = new et4ae5__Automated_Send__c();
    	insert triggerSend;
    	subcamps1[0].Triggered_Send_Name__c = triggerSend.Id;
    	subcamps1[0].EBH_Channel__c = EBH_ConstantsUtility.CAMPAIGN_CHANNEL_EMAIL;
    	update subcamps1[0];
    	List<Contact> contacts = EBH_TestDataFactory.createContacts(2, 'Test Contact', legalEntities[0].id);
    		List<CampaignMember> listCM_master = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,10,System.today()-5,System.today());
    		List<CampaignMember> listCM_Sub = EBH_TestDataFactory.createCampaignMembers2(1,subcamps1[0].Id,contacts[0].Id,40,System.today()-7,System.today()-1);
    	Test.stopTest();
    	//'Select campaignId, ContactId,EBH_ResponseCode__c,EBH_LastResponseDate__c,EBH_FirstResponseDate__c From CampaignMember'
    	et4ae5__IndividualEmailResult__c ier =new  et4ae5__IndividualEmailResult__c(et4ae5__DateSent__c=System.today()-2,et4ae5__DateBounced__c=System.today()-5,et4ae5__DateOpened__c=System.today()-4,et4ae5__DateUnsubscribed__c=System.today(),et4ae5__Opened__c=true,et4ae5__TriggeredSendDefinition__c=triggerSend.Id,et4ae5__Contact__c=contacts[0].Id);
    	insert ier;
    	CampaignMember cmSel = [Select Id,Target_Date__c From CampaignMember Where Id=:listCM_Sub[0].Id];
    	System.assertEquals(System.today()-2,cmSel.Target_Date__c,' date populated from IER.et4ae5__DateSent__c on insert');
    	ier.et4ae5__DateSent__c=System.today()-1;
    	update ier;
    	cmSel = [Select Id,Target_Date__c From CampaignMember Where Id=:listCM_Sub[0].Id];
    	System.assertEquals(System.today()-1,cmSel.Target_Date__c,' date populated from IER.et4ae5__DateSent__c on update');
    }
    static testMethod void testUpdateSellerDetailToTasks() {
    	EBH_TestDataFactory.setUpCustomSettings();  
    	List<Account> legalEntities = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity') ;
    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE,null,'Feasibility');
    	List<Contact> contacts = EBH_TestDataFactory.createContacts(2, 'Test Contact', legalEntities[0].id);
    	Test.startTest();
    		//CampaignMember listCM_master = new CampaignMember(CampaignId = campaigns1[0].Id,ContactId = contacts[0].Id, EBH_ResponseCode__c = 10, Campaign_Related_Seller_Details__c = null);
    		CampaignMember camp = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,10,System.today()-5,System.today())[0];
    		CampaignMember camp2 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[1].Id,10,System.today()-5,System.today())[0];
    		Set<String> setCMIds = new Set<String>{camp.Id,camp2.Id};
    		
    		Task task1 = new Task(Subject = 'Test Campaign', EBH_CampaignMemberId__c = camp.Id ,Follow_Up_Task__c=false,WhoId=contacts[0].Id,WhatId=campaigns1[0].Id);
    		Task task2 = new Task(Subject = 'Test Campaign', EBH_CampaignMemberId__c = camp2.Id ,Follow_Up_Task__c=false,WhoId=contacts[1].Id,WhatId=campaigns1[0].Id);
			insert new Task[]{ task1,task2};
    		
    		task1.EBH_ResponseCode__c = 30;
    		task2.EBH_ResponseCode__c = 40;
    		//System.debug('tttxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx>>>' );
    		update new Task[]{ task1,task2};
    		//Task[] ttt = Database.query(EBH_ConstantsUtility.SOQL_TASK +' Where EBH_CampaignMemberId__c IN: setCMIds AND Follow_Up_Task__c=false');
    	 	//System.debug('tttxx>>>' +ttt);
    		
    		 
    		camp.Campaign_Related_Seller_Details__c = 'Test Task 001';
    		camp.PriorityOrder__c = 3;
    		camp2.Marketing_Cloud_Status__c=EBH_ConstantsUtility.CM_MC_STATUS_CANCELLED;
    		camp2.EBH_ResponseCode__c = 40; 
    		 
    		update new CampaignMember[]{camp,camp2};
    		
    		//System.debug('camp>>>>'+camp.Campaign_Related_Seller_Details__c);
    		Task[] testTask1 = [select Id, EBH_ResponseCode__c,MCStatus__c,Status,Campaign_Related_Seller_Details__c from Task where EBH_CampaignMemberId__c =: camp.Id];
    		Task[] testTask2 = [select Id,EBH_ResponseCode__c,MCStatus__c,Status,Campaign_Related_Seller_Details__c from Task where EBH_CampaignMemberId__c =: camp2.Id];
    		 
    	 	
    	 	//assert Tasks
    		System.assertEquals(0,testTask2.size(),'Task has been deleted');
    		System.assertEquals(30,testTask1[0].EBH_ResponseCode__c,'Task with respone code not 10 or 40 is not touched');
    		
    		camp = [Select Id,EBH_ResponseCode__c,EBH_Results__c From CampaignMember where Id=:camp.Id];
    		camp2 = [Select Id,EBH_ResponseCode__c,EBH_Results__c From CampaignMember where Id=:camp2.Id];
    		
    		System.assertEquals(10,camp.EBH_ResponseCode__c,'nothing changed');
    		System.assertEquals(22,camp2.EBH_ResponseCode__c,'updated by EBH_CampaignMemberTriggerHandler.updateSellerDetailToTasks()');
    		System.assertEquals(EBH_ConstantsUtility.CMRC_CANCELLED,camp2.EBH_Results__c,'updated by EBH_CampaignMemberTriggerHandler.updateSellerDetailToTasks()');
    	Test.stopTest();	
    }
}