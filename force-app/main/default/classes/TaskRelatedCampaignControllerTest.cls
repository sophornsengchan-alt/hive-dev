/*********************************************************************************************************************************
@ Class:          TaskRelatedCampaignControllerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Test class for TaskRelatedCampaignController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.05.2020 / Sovantheany Dim  / Created the test class.
*********************************************************************************************************************************/
@isTest(seeAllData = False)
private class TaskRelatedCampaignControllerTest {
	@testSetup static void testSetup() {
		EBH_TestDataFactory.setUpCustomSettings();
		List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(3, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,null,'Feasibility');
		RecordType recSeller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		RecordType recLegal = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
		Account legalAcc0 = new Account(Name = 'testLegalAcc0',RecordTypeId = recLegal.Id);
        Account legalAcc1 = new Account(Name = 'testLegalAcc1',RecordTypeId = recLegal.Id);
        insert new List<Account>{legalAcc0,legalAcc1};
        Account acc1 = new Account(Name = 'testAccount0', RecordTypeId = recSeller.ID, ParentId = legalAcc0.Id,EBH_OracleID__c = '1111', BillingStreet = 'testStreet1',BillingState ='testState1',BillingPostalCode='testpostalcode1',BillingCountry = 'testcountry1',BillingCity='testcity1');
        Account acc2 = new Account(Name = 'testAccount1', RecordTypeId = recSeller.ID, ParentId = legalAcc1.Id,EBH_OracleID__c = '2222', BillingStreet = 'testStreet2',BillingState ='testState2',BillingPostalCode='testpostalcode2',BillingCountry = 'testcountry2',BillingCity='testcity2');
        List<Account> lstAccount = new List<Account>{acc1,acc2};
        insert lstAccount;
        List<Contact> lstCont = new List<Contact>();
        for(Integer i = 0; i < 2; i++){
        	Contact con = new Contact(LastName = 'testContact' + i, AccountId = lstAccount[i].Id, EBH_Status__c='Active',Email='test'+i+'@gmail.com',
        	Phone='123456'+i,EBH_MailingStreet__c='testMailingStreet'+i,EBH_MailingPostalCode__c='testMailingPostalcode'+i,
        	EBH_MailingCountry__c='testMailingCountry'+i,EBH_MailingCity__c='testMailingCity'+i,EBH_MailingAddress__c='testMailingAddress'+i);
        	
        	lstCont.add(con);
        }
        insert lstCont;
        List<Task> lstTask = new List<Task>();
        for(Integer i = 0; i < 2; i++){
        	Task t1 = new Task(whatId=campaigns1[0].id,subject='testTask'+i,WhoId = lstCont[i].Id,Order_Priority__c = 10);
        	lstTask.add(t1);
        }
    	insert lstTask;
	}
	@IsTest
    static void testApexInit(){
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
    	List<Campaign> campaigns1 = [select id from Campaign where Name = 'Test Campaign1'];
    	Test.startTest();            
            Map<String,Object> mapResult =  (Map<String, Object>) TaskRelatedCampaignController.apexInit(campaigns1[0].Id);
        	//System.debug('mapResult>>>>>>>>>>>'+mapResult.get('listTask'));
            //List<TaskWrapper> lstTask = List<TaskWrapper> mapResult.get('listTask');
            //System.assertEquals(2, lstTask.size(),'2 realated Task');
            
           // Map<String,String> mapResult2 =  TaskRelatedCampaignController.assignTask(businessAdm.Id, new List<String>{lstTask[0].Id});
            
        Test.stopTest();
        //List<Task> lstTaskselect = [select ownerId from Task where id =: lstTask[0].Id];
        //System.assertEquals(businessAdm.id, lstTaskselect[0].ownerId);
    }
}