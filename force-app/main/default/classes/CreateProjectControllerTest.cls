/*********************************************************************************************************************************
@ Class:        CreateProjectControllerTest
@ Class:        CreateProjectController
@ Version:      1.0
@ Author:       sovantheany.dim (sovantheany.dim@gaea-sys.com)
@ Purpose:      US-0015820 - Create Project Quick Action button
@				Test class for CreateProjectController.cls
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.09.2024 / sovantheany.dim (sovantheany.dim@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
@isTest
private class CreateProjectControllerTest {
    @testSetup
    static void makeData(){
        EBH_TestDataFactory.setUpCustomSettings();
        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        List<Contact> contacts = EBH_TestDataFactory.createContacts(1, 'Test Contact', sellers[0].id);
    }

    @isTest
    static void testApexInit(){
        List<Account> lstAcs = [select Id from Account where RecordType.DeveloperName = 'EBH_Seller' limit 1];
        Test.startTest();
        Map<String,Object> mapResult = CreateProjectController.apexInit(lstAcs[0].ID);
        System.assert(mapResult.get('status')=='ok','get record success');
        Test.stopTest();
        
    }
    @isTest
    static void testApexInitWithExistingInitialProject(){
        List<Account> lstAcs = [select Id from Account where RecordType.DeveloperName = 'EBH_Seller' limit 1];
        RecordType oneOffRecordType = ApexUtil.getRecordTypeByName('EBH_Project__c', CreateProjectController.ONE_OFF_RECORDTYPE);
        EBH_Project__c pro = new EBH_Project__c(Name='Project 1',EBH_Seller__c=lstAcs[0].id,RecordTypeId=oneOffRecordType.Id,EBH_Stage__c='Initial');
        EBH_ProjectTriggerHandler.isFromQuickAction = true;
        insert pro;
        Test.startTest();
        Map<String,Object> mapResult = CreateProjectController.apexInit(lstAcs[0].ID);
        System.assert(mapResult.get('status')=='ok','get record success');
        Test.stopTest();
        
    }
    @isTest
    static void testApexInitWithExistingSecondProject(){
        List<Account> lstAcs = [select Id from Account where RecordType.DeveloperName = 'EBH_Seller' limit 1];
        RecordType oneOffRecordType = ApexUtil.getRecordTypeByName('EBH_Project__c', CreateProjectController.ONE_OFF_RECORDTYPE);
        EBH_Project__c pro = new EBH_Project__c(Name='Project 1',EBH_Seller__c=lstAcs[0].id,RecordTypeId=oneOffRecordType.Id,EBH_Stage__c='Second');
        EBH_ProjectTriggerHandler.isFromQuickAction = true;
        insert pro;
        Test.startTest();
        Map<String,Object> mapResult = CreateProjectController.apexInit(lstAcs[0].ID);
        System.assert(mapResult.get('status')=='ok','get record success');
        Test.stopTest();
        
    }

    //@ Change history: 20.09.2024 / Vimean Heng (vimean.heng@gaea-sys.com) / Created test method.
    @isTest
    static void testCreateProject() {
        List<Account> sellers =  EBH_TestDataFactory.createAccounts(1, 'EBH_Seller') ;
        RecordType recTypeAccManagement = ApexUtil.getRecordTypeByName('EBH_Project__c','One_Off_Account_Management');
        EBH_Project__c proj1 = new EBH_Project__c(Name= 'Test - 1',RecordTypeId=recTypeAccManagement.Id,EBH_Stage__c = 'wrong'); 
        EBH_Project__c proj2 = new EBH_Project__c(Name= 'Test - 2',RecordTypeId=recTypeAccManagement.Id,EBH_Seller__c=sellers[0].id);
        Test.startTest();
        
        Map<String,Object> m1 = CreateProjectController.createProject(proj1);
        Map<String,Object> m2 = CreateProjectController.createProject(proj2);
        System.AssertEquals(m1.get('status'), 'ko',true);
        System.AssertEquals(m2.get('status'), 'ok',true);
        Test.stopTest();
    }
}