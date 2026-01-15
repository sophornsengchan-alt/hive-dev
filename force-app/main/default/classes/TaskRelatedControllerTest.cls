/*********************************************************************************************************************************
@ Class:          TaskRelatedControllerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Test class for TaskRelatedController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.02.2019 / Sovantheany Dim  / Created the test class.
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.12.2023 / Vimean Heng  / Fixed mix DML
*********************************************************************************************************************************/
@isTest(seeAllData = False)
private class TaskRelatedControllerTest {

    private static User currentUser = [ select Id, Name from User where Id = :UserInfo.getUserId() ]; 

    @testSetup static void testSetup() {
        EBH_TestDataFactory.setUpCustomSettings();
    	List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE,null,'Feasibility');
        List<Account> lstAcc = EBH_TestDataFactory.createAccounts(2,'EBH_LegalEntity');
        RecordType sellerId = [SELECT Id FROM RecordType where SobjectType = 'Account' and DeveloperName = 'EBH_Seller'];
		RecordType legalEntityId = [SELECT Id FROM RecordType where SobjectType = 'Account' and DeveloperName = 'EBH_LegalEntity'];
        Account legalAcc0 = new Account(Name = 'testLegalAcc0',RecordTypeId = legalEntityId.Id);
        Account legalAcc1 = new Account(Name = 'testLegalAcc1',RecordTypeId = legalEntityId.Id);
        insert new List<Account>{legalAcc0,legalAcc1};
        Account acc1 = new Account(Name = 'testAccount0', RecordTypeId = sellerId.ID, ParentId = legalAcc0.Id,EBH_OracleID__c = '1111', BillingStreet = 'testStreet1',BillingState ='testState1',BillingPostalCode='testpostalcode1',BillingCountry = 'testcountry1',BillingCity='testcity1');
        Account acc2 = new Account(Name = 'testAccount1', RecordTypeId = sellerId.ID, ParentId = legalAcc1.Id,EBH_OracleID__c = '2222', BillingStreet = 'testStreet2',BillingState ='testState2',BillingPostalCode='testpostalcode2',BillingCountry = 'testcountry2',BillingCity='testcity2');
        Account sellerAcc1 = new Account(Linked_Acc_Group_Id__c='11111111',EBH_OracleId__c='1003293592',Name='Test Acc2',RecordTypeID = sellerId.ID,EBH_RevRollup__c='UK');
        Account sellerAcc2 = new Account(Linked_Acc_Group_Id__c='11111111', EBH_OracleId__c='1003293593',Name='Test Acc3',RecordTypeID = sellerId.ID,EBH_RevRollup__c='UK');
        List<Account> lstAccount = new List<Account>{acc1,acc2,sellerAcc1,sellerAcc2};
        insert lstAccount;
        List<Contact> lstCont = new List<Contact>();
        for(Integer i = 0; i < 4; i++){
        	Contact con = new Contact(LastName = 'testContact' + i, AccountId = lstAccount[i].Id, EBH_Status__c='Active',Email='test'+i+'@gmail.com',
        	Phone='123456'+i,EBH_MailingStreet__c='testMailingStreet'+i,EBH_MailingPostalCode__c='testMailingPostalcode'+i,
        	EBH_MailingCountry__c='testMailingCountry'+i,EBH_MailingCity__c='testMailingCity'+i,EBH_MailingAddress__c='testMailingAddress'+i);
        	
        	lstCont.add(con);
        }
        insert lstCont;
        List<Task> lstTask = new List<Task>();
        for(Integer i = 0; i < 4; i++){
        	Task t1 = new Task(whatId=campaigns1[0].id,subject='testTask'+i,WhoId = lstCont[i].Id,Order_Priority__c = 10,EBH_Account__c = lstAccount[i].Id);
        	lstTask.add(t1);
        }
    	insert lstTask;
    }
    
    /*****************************************************************************************************************************
    @ Method:         testgetTasksWhenTheSameGroupid
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        Test Display related Tasks with Linked B2C Seller
    @
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2020 / Sovantheany Dim  / Created the test class.
    *****************************************************************************************************************************/
    static testMethod void testgetTasksWhenTheSameGroupid() {
    	Task t0 = [select id from Task where EBH_Account__r.Linked_Acc_Group_Id__c = '11111111' limit 1];
    	Test.startTest();
    		Map<String,Object> mapGetTask1 = TaskRelatedController.getOpenTasks(t0.Id);
    	Test.stopTest();
    	System.assert(mapGetTask1.get('isOK') == true,'Business Name are equal for task 0 and task 1');
    }
	/*****************************************************************************************************************************
    @ Method:         testgetTasksWhenTheSameBusinessName
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        test get task where Tasks have the same and not NULL at least one fields below
    @
    @ Contact. Business Name
    @ Contact. Primary Email
@ Contact. Phone
    @ Seller. Oracle ID
    @ Seller. Parent Legal Entity
    @ Seller. Address
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.02.2019 / Sovantheany Dim  / Created the test class.
    *****************************************************************************************************************************/
    static testMethod void testgetTasksWhenTheSameBusinessName() {
        Task t0 = [select id from Task where Subject = 'testTask0'];
        Task t1 = [select id from Task where Subject = 'testTask1'];
        Account a = [select id from Account where Name = 'testAccount0'];
        Contact c = [select id from Contact where LastName = 'testContact1'];
        
        //test Contact.Business Name
        c.AccountId = a.ID;
        update c;
        Map<String,Object> mapGetTask1 = TaskRelatedController.getOpenTasks(t0.Id);
        System.assert(mapGetTask1.get('isOK') == true,'Business Name are equal for task 0 and task 1');
        
    }
	/*****************************************************************************************************************************
    @ Method:         testgetTasksWhenTheSameEmail
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        test get task where Tasks have the same and not NULL at least one fields below
    @
    @ Contact. Business Name
    @ Contact. Primary Email
    @ Contact. Phone
    @ Seller. Oracle ID
    @ Seller. Parent Legal Entity
    @ Seller. Address
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.02.2019 / Sovantheany Dim  / Created the test class.
    *****************************************************************************************************************************/
    static testMethod void testgetTasksWhenTheSameEmail() {
        Task t0 = [select id from Task where Subject = 'testTask0'];
        Task t1 = [select id from Task where Subject = 'testTask1'];
        Contact c = [select id from Contact where LastName = 'testContact1'];
        //test Contact. Primary Email
        c.Email = 'test0@gmail.com';
        update c;
        Map<String,Object> mapGetTask = TaskRelatedController.getOpenTasks(t0.Id);   
        System.assert(mapGetTask.get('isOK') == true,'Email are equal for task 0 and task 1');
    }
    
    /*****************************************************************************************************************************
    @ Method:         testgetTasksWhenTheSamePhone
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        test get task where Tasks have the same and not NULL at least one fields below
    @
    @ Contact. Business Name
    @ Contact. Primary Email
    @ Contact. Phone
    @ Seller. Oracle ID
    @ Seller. Parent Legal Entity
    @ Seller. Address
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.02.2019 / Sovantheany Dim  / Created the test class.
    *****************************************************************************************************************************/
    static testMethod void testgetTasksWhenTheSamePhone() {
        Task t0 = [select id from Task where Subject = 'testTask0'];
        Task t1 = [select id from Task where Subject = 'testTask1'];
        Contact c = [select id from Contact where LastName = 'testContact1'];
        //test Contact. Phone
        c.Phone = '1234560';
        update c;
        Map<String,Object> mapGetTask = TaskRelatedController.getOpenTasks(t0.Id);
        System.assert(mapGetTask.get('isOK') == true,'Phone are equal for task 0 and task 1');
        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testgetTasksWhenTheSameParentLegalEntity
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        test get task where Tasks have the same and not NULL at least one fields below
    @
    @ Contact. Business Name
    @ Contact. Primary Email
    @ Contact. Phone
    @ Seller. Oracle ID
    @ Seller. Parent Legal Entity
    @ Seller. Address
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.02.2019 / Sovantheany Dim  / Created the test class.
    *****************************************************************************************************************************/
    static testMethod void testgetTasksWhenTheSameParentLegalEntity() {
        Task t0 = [select id from Task where Subject = 'testTask0'];
        Task t1 = [select id from Task where Subject = 'testTask1'];
        Account a = [select id from Account where Name = 'testAccount1'];
        Account b = [select id from Account where Name = 'testLegalAcc0'];
        //test Seller. Parent Legal Entity
        a.ParentId = b.Id;
        update a;
       	Map<String,Object> mapGetTask = TaskRelatedController.getOpenTasks(t0.Id);
        System.assert(mapGetTask.get('isOK') == true,'Parent LegalEntity are equal for task 0 and task 1');
    }
    
    /*****************************************************************************************************************************
    @ Method:         testgetTasksWhenTheSameAddress
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        test get task where Tasks have the same and not NULL at least one fields below
    @
    @ Contact. Business Name
    @ Contact. Primary Email
    @ Contact. Phone
    @ Seller. Oracle ID
    @ Seller. Parent Legal Entity
    @ Seller. Address
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.02.2019 / Sovantheany Dim  / Created the test class.
    *****************************************************************************************************************************/
    static testMethod void testgetTasksWhenTheSameAddress() {
        Task t0 = [select id from Task where Subject = 'testTask0'];
        Task t1 = [select id from Task where Subject = 'testTask1'];
        Account a = [select id from Account where Name = 'testAccount1'];
        //test Seller.Address
        a.billingStreet = 'testStreet1';
        a.billingState = 'testState1';
        a.billingPostalCode = 'testpostalcode1';
        a.billingCountry = 'testcountry1';
        a.billingCity = 'testcity1';
        update a;
       	Map<String,Object> mapGetTask = TaskRelatedController.getOpenTasks(t0.Id);
        System.assert(mapGetTask.get('isOK') == true,'Address are equal for task 0 and task 1');
    }
    
    /*****************************************************************************************************************************
    @ Method:         testReAssignTask
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        EPH-7029 Reassign Tasks
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.02.2019 / Sovantheany Dim  / Created the test class.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.12.2023 / Vimean Heng  / US-001442 Fixed mix DML
    *****************************************************************************************************************************/
    static testMethod void testReAssignTask() {
    	Profile p =[SELECT Id, Name FROM Profile WHERE Name = 'Business Admin'];
	        
        User businessAdm = new User(Alias             = 'usr', 
                            Email             = 'usr' + Math.random() + '@org.com', 
                            EmailEncodingKey  = 'UTF-8', 
                            LastName          = 'Testing' + Math.random(), 
                            LanguageLocaleKey = 'en_US', 
                            LocaleSidKey      = 'en_US', 
                            ProfileId         = p.Id, 
                            TimeZoneSidKey    = 'America/Los_Angeles',
                            UserName          = 'usr' + Math.random() + '@org.com',
                            IsActive = true,
                            Competency__c = 'Copy');   
                        
		insert businessAdm;
        System.runAs(currentUser){
            Task t0 = [select id from Task where Subject = 'testTask0'];
    	    Map<String,String> mapAssignTask = TaskRelatedController.reAssignTask(businessAdm.ID,new List<String> {t0.Id});
    	    System.assert(mapAssignTask.get('status') == 'ok');
        }
		
    	
    }
    /*****************************************************************************************************************************
    @ Method:         testgetCompletedTasks
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        EPH-7879 "Open Related Tasks” and "Completed Related Tasks" tab in Task Detail Page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.08.2019 / Sovantheany Dim  / Created the test class.
    *****************************************************************************************************************************/
    static testMethod void testgetCompletedTasks() {
    	Task t0 = [select id from Task where Subject = 'testTask0'];
        Task t1 = [select id from Task where Subject = 'testTask1'];
        Account a = [select id from Account where Name = 'testAccount0'];
        Contact c = [select id from Contact where LastName = 'testContact1'];
        //test Contact.Business Name
        c.AccountId = a.ID;
        update c;
        t1.status = EBH_ConstantsUtility.TASK_STATUS_COMPLETED;
        update t1;
        Map<String,Object> mapGetTask1 = TaskRelatedController.getCompletedTasks(t0.Id);
        System.assert(mapGetTask1.get('isOK') == true,'Business Name are equal for task 0 and task 1 On Completed Task');
        String whoIds = '["'+c.Id+'"]';
        Map<String,Object> mapResultLstContact = TaskRelatedController.queryRelatedFields(whoIds);
        System.debug('<<<<mapResultLstContact.get(\'lstContact\')='+mapResultLstContact.get('lstContact'));
         System.assert(!mapResultLstContact.isEmpty());
    }
    
     /*****************************************************************************************************************************
    @ Method:         testgetCompletedTasksisBlankWhoid
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0007968
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.08.2020 / Sovantheany Dim  / Created the test class.
    *****************************************************************************************************************************/
    static testMethod void testgetCompletedTasksisBlankWhoid() {
    	Task t0 = [select whoid from Task where Subject = 'testTask0'];
        //test Contact.Business Name
        t0.whoid = null;
        t0.status = EBH_ConstantsUtility.TASK_STATUS_COMPLETED;
        update t0;
        Map<String,Object> mapGetTask1 = TaskRelatedController.getCompletedTasks(t0.Id);
        System.assert(mapGetTask1.get('isOK') == false);
        
    	Account b = [select id from Account where Name = 'testLegalAcc0'];
    	Contact c = [select id,AccountId from Contact where LastName = 'testContact1'];
    	c.AccountId = b.Id;
    	update c;
        t0.whoid = c.Id;
        update t0;
        Map<String,Object> mapGetTask2 = TaskRelatedController.getCompletedTasks(t0.Id);
        System.assert(mapGetTask2.get('isOK') == false);
    }
}