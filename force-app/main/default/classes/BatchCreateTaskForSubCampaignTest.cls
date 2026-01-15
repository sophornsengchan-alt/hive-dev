/********************************************************************************************************************************
@ Class:        BatchCreateTaskForSubCampaign
@ Version:      1.0
@ Author:       Acmatac Seing (acmatac.seing@gaea-sys.com)
@ Purpose:    	TestClass for BatchCreateTaskForSubCampaign.cls
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.March.2019 / Acmatac Seing (acmatac.seing@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
@isTest
private class BatchCreateTaskForSubCampaignTest{
	@testSetup private static void setup() {
		EBH_TestDataFactory.setUpCustomSettings();
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
        ArdiraSurvey__Survey__c vista1= new ArdiraSurvey__Survey__c (name='vista1');
        insert vista1;

        Campaign subCampaign = new Campaign();
        subCampaign.Name = 'Test SubCampaign 01';
        subCampaign.recordTypeId = EBH_TestDataFactory.getRecordTypeByName('Campaign', EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE).Id;
        subCampaign.EBH_Channel__c = EBH_ConstantsUtility.CAMPAIGN_CHANNEL_GCX_OUTREACH;
        subCampaign.Survey_ID__c = 'testServey';
        subCampaign.Ardira_Survey__c = vista1.Id;        
        insert subCampaign;

        Contact sContact1 = new Contact();
        sContact1.EBH_Status__c = 'Active';
        sContact1.LastName = 'Test Contact 1';
        sContact1.AccountId = sellers[0].Id;
        sContact1.recordTypeId = EBH_TestDataFactory.getRecordTypeByName('Contact','EBH_DWH').Id;
        sContact1.EBH_DataOrigin__c = 'test';
        insert sContact1;
        Contact sContact2 = new Contact();
        sContact2.EBH_Status__c = 'Active';
        sContact2.LastName = 'Test Contact 2';
        sContact2.AccountId = sellers[0].Id;
        sContact2.recordTypeId = EBH_TestDataFactory.getRecordTypeByName('Contact','EBH_DWH').Id;
        sContact2.EBH_DataOrigin__c = 'test';
        insert sContact2;
        Contact sContact3 = new Contact();
        sContact3.EBH_Status__c = 'Active';
        sContact3.LastName = 'Test Contact 3';
        sContact3.AccountId = sellers[0].Id;
        sContact3.recordTypeId = EBH_TestDataFactory.getRecordTypeByName('Contact','EBH_DWH').Id;
        sContact3.EBH_DataOrigin__c = 'test';
        insert sContact3;
        
        CampaignMember campMem1 = new CampaignMember();
        campMem1.CampaignId = subCampaign.Id;
        campMem1.ContactId = sContact1.Id;
        campMem1.EBH_Results__c = 'Sent'; 
        campMem1.EBH_ResponseCode__c = 10;
        campMem1.EBH_FirstResponseDate__c = System.today()-5;
        campMem1.EBH_LastResponseDate__c = System.today();
        campMem1.Campaign_Related_Seller_Details__c = 'test1';
        campMem1.PriorityOrder__c = 98;
        insert campMem1;
        CampaignMember campMem2 = new CampaignMember();
        campMem2.CampaignId = subCampaign.Id;
        campMem2.ContactId = sContact2.Id;
        campMem2.EBH_Results__c = 'Sent'; 
        campMem2.EBH_ResponseCode__c = 10;
        campMem2.EBH_FirstResponseDate__c = System.today()-5;
        campMem2.EBH_LastResponseDate__c = System.today();
        campMem2.Campaign_Related_Seller_Details__c = 'test2';
        campMem2.PriorityOrder__c = 99;
        insert campMem2;
	}
	@isTest private static void batchCreateTaskForSubCampaign1() {
        Test.startTest();
            List<Contact> lstContact = [SELECT Id FROM Contact WHERE Name LIKE '%Test Contact%' ORDER BY LastName];
            Campaign subCampaign = [SELECT Name FROM Campaign WHERE Name = 'Test SubCampaign 01' LIMIT 1];
            //Database.executeBatch(new BatchCreateTaskForSubCampaign());
            // Task won't create duplicate in case the combination of ContactId AND CampaignId in Task.
            EBH_TestDataFactory.createCampaignMembers2(1, subCampaign.Id, lstContact.get(2).Id, 10, System.today()-5, System.today());
            Database.executeBatch(new BatchCreateTaskForSubCampaign());
        Test.stopTest();
        List<Task> lstTask = [SELECT Subject
                                    , Type
                                    , WhatId
                                    , What.Name
                                    , WhoId
                                    , Status , Survey_ID__c
                            FROM Task 
                            WHERE WhatId =: subCampaign.Id];
        // Task 1
        System.assert(lstTask.size() == 3, 'Task should be created 3 records, Actual = ' + lstTask.size());
        System.assert(lstTask.get(0).Subject == 'GCX Outreach call task', 'Task Subject should be \'GCX Outreach call task\', Actual = ' + lstTask.get(0).Subject);
        System.assert(lstTask.get(0).Type == EBH_ConstantsUtility.GCX_TASK_TYPE, 'Task Subject should be \''+ EBH_ConstantsUtility.GCX_TASK_TYPE +'\', Actual = ' + lstTask.get(0).Type);
        System.assert(lstTask.get(0).WhoId == lstContact.get(0).Id, 'Task.Contact should be Cont1');
        System.assert(lstTask.get(0).WhatId == subCampaign.Id, 'Task.WhatId should be \''+ subCampaign.Name +'\', Actual = '+ lstTask.get(0).What.Name);
        System.assert(lstTask.get(0).Status == 'Open' , 'Task.Status should be Open, Actual = '+ lstTask.get(0).Status);

        ArdiraSurvey__Survey__c vista1 = [Select Id,Name From ArdiraSurvey__Survey__c Where Name='vista1' limit 1];
        System.assert(lstTask.get(0).Survey_ID__c == vista1.Id , 'survey id copied from campaign (vista)'+ lstTask.get(0).Survey_ID__c);

        // Task 2
        System.assert(lstTask.get(1).Subject == 'GCX Outreach call task', 'Task Subject should be \'GCX Outreach call task\', Actual = ' + lstTask.get(1).Subject);
        System.assert(lstTask.get(1).Type == EBH_ConstantsUtility.GCX_TASK_TYPE, 'Task Subject should be \''+ EBH_ConstantsUtility.GCX_TASK_TYPE +'\', Actual = ' + lstTask.get(1).Type);
        System.assert(lstTask.get(1).WhoId == lstContact.get(1).Id, 'Task.Contact should be Cont2');
        System.assert(lstTask.get(1).WhatId == subCampaign.Id, 'Task.WhatId should be \''+ subCampaign.Name +'\', Actual = '+ lstTask.get(1).What.Name);
        System.assert(lstTask.get(1).Status == 'Open' , 'Task.Status should be Open, Actual = '+ lstTask.get(1).Status);
        // Task 3
        System.assert(lstTask.get(2).Subject == 'GCX Outreach call task', 'Task Subject should be \'GCX Outreach call task\', Actual = ' + lstTask.get(2).Subject);
        System.assert(lstTask.get(2).Type == EBH_ConstantsUtility.GCX_TASK_TYPE, 'Task Subject should be \''+ EBH_ConstantsUtility.GCX_TASK_TYPE +'\', Actual = ' + lstTask.get(2).Type);
        System.assert(lstTask.get(2).WhoId == lstContact.get(2).Id, 'Task.Contact should be Cont3');
        System.assert(lstTask.get(2).WhatId == subCampaign.Id, 'Task.WhatId should be \''+ subCampaign.Name +'\', Actual = '+ lstTask.get(2).What.Name);
        System.assert(lstTask.get(2).Status == 'Open' , 'Task.Status should be Open, Actual = '+ lstTask.get(2).Status);
	}
    @isTest private static void batchCreateTaskForSubCampaign2() {
        Test.startTest();
            BatchCreateTaskForSubCampaign bCreateTask4SP = new BatchCreateTaskForSubCampaign();
            SchedulableContext ctx;
            bCreateTask4SP.execute(ctx);
        Test.stopTest();
    }
    @isTest private static void batchCreateTaskForSubCampaign3() {
        Test.startTest();
            List<Contact> lstContact = [SELECT Id FROM Contact WHERE Name LIKE '%Test Contact%' ORDER BY LastName];
            Campaign subCampaign = [SELECT Name FROM Campaign WHERE Name = 'Test SubCampaign 01' LIMIT 1];
            CampaignMember campMem = [SELECT Campaign.Survey_ID__c, ContactId, CampaignId, PriorityOrder__c, Campaign_Related_Seller_Details__c
                                      FROM CampaignMember WHERE CampaignId =: subCampaign.Id AND Contact.LastName='Test Contact 1' LIMIT 1];
            Task sTask = new Task();
            sTask.Subject = 'GCX Outreach call task';
            // 'Phone Outreach'
            sTask.Type = EBH_ConstantsUtility.GCX_TASK_TYPE;
            // Customer(Contact)
            sTask.WhoId = campMem.ContactId;
            // RelatedTo
            sTask.WhatId = campMem.CampaignId;
            sTask.Status = 'Open';
            sTask.Campaign_related_Seller_Details__c = (''+campMem.Campaign_Related_Seller_Details__c).left(255); //NK:29/11/2019: US-0000802 
            sTask.EBH_CampaignMemberId__c = campMem.Id;
            sTask.Survey_ID__c = campMem.Campaign.Survey_ID__c;
            // US-0007006
            sTask.Order_Priority__c = campMem.PriorityOrder__c;
            insert sTask;
            // US-0007006, Updted CampMember to reflect Task 
            campMem.PriorityOrder__c = 9988;
            campMem.Campaign_Related_Seller_Details__c = 'any test string';
            update campMem;
            Database.executeBatch(new BatchCreateTaskForSubCampaign());
        Test.stopTest();
        // 1st step, insert
        List<Task> task1 = [SELECT Order_Priority__c, Campaign_related_Seller_Details__c, MCStatus__c FROM Task WHERE EBH_CampaignMemberId__c =: campMem.Id];
        System.assert(task1.size() == 1);
        System.assert(task1[0].Order_Priority__c == 9988, 'After Batch fired ,Task Order_Priority__c should equal to CampaignMember, Actual = ' + task1[0].Order_Priority__c);
        System.assert(task1[0].Campaign_related_Seller_Details__c == 'any test string', 'After Batch fired ,Task Campaign_related_Seller_Details__c should equal to CampaignMember, Actual = ' + task1[0].Campaign_related_Seller_Details__c);
        System.assert(task1[0].MCStatus__c == 'Updated', 'After Batch fired ,Task MCStatus__c should be \'Updated\', Actual = ' + task1[0].MCStatus__c);
    }
}