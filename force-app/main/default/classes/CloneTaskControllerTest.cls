/*********************************************************************************************************************************
@ Class:          CloneTaskControllerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0008191 - [AU & EU] Create follow up task from a closed task record
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.09.2020 / Sovantheany Dim / Created the class.
*********************************************************************************************************************************/
@isTest
public class CloneTaskControllerTest {
    static testMethod void testapexCloneTaskSuccess() {
        EBH_TestDataFactory.setUpCustomSettings(); 
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
        RecordType contactManaul = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        List<Contact> listContact = new List<Contact>{
            new Contact(EBH_Status__c='Active', LastName = 'last1', AccountId = sellers[0].Id,recordTypeId = contactManaul.Id, EBH_DataOrigin__c='test'),
                new Contact(EBH_Status__c='Inactive', LastName = 'last2', AccountId = sellers[0].Id,recordTypeId = contactManaul.Id, EBH_DataOrigin__c='test')
                };
                    insert listContact;
        Task t1 = new Task( status = 'Completed', RecordTypeId = ApexUtil.getRecordTypeByName('Task','X3CallAttempts').Id, EBH_Account__c = sellers[1].Id, WhatId=sellers[0].Id,WhoId=listContact[0].Id,Subject=EBH_ConstantsUtility.TTH_URGENCYTASK);
        insert t1;
        Test.startTest();
        Map<String,Object> mapResult = CloneTaskController.apexCloneTask(t1.Id);
        Test.stopTest();
        System.assertEquals('ok',mapResult.get('status'));
    }
    
    static testMethod void testapexCloneTaskFail() {
        EBH_TestDataFactory.setUpCustomSettings(); 
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
        RecordType contactManaul = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        List<Contact> listContact = new List<Contact>{
            new Contact(EBH_Status__c='Active', LastName = 'last1', AccountId = sellers[0].Id,recordTypeId = contactManaul.Id, EBH_DataOrigin__c='test'),
                new Contact(EBH_Status__c='Inactive', LastName = 'last2', AccountId = sellers[0].Id,recordTypeId = contactManaul.Id, EBH_DataOrigin__c='test')
                };
                    insert listContact;

        Task t2 = new Task( status = 'Open', RecordTypeId = ApexUtil.getRecordTypeByName('Task','X3CallAttempts').Id, EBH_Account__c = sellers[1].Id, WhatId=sellers[0].Id,WhoId=listContact[0].Id,Subject=EBH_ConstantsUtility.TTH_URGENCYTASK);
        insert t2;
        Test.startTest();
        Map<String,Object> mapResult2 = CloneTaskController.apexCloneTask(t2.Id);
        try{
            Map<String,Object> mapResult3 = CloneTaskController.apexCloneTask(null);
        }catch(Exception ex){
            System.assert(true);
        }
        Test.stopTest();
        System.assertEquals('ko',mapResult2.get('status'));
    }
}