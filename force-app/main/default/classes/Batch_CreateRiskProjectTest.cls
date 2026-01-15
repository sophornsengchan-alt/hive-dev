/*********************************************************************************************************************************
@ Class:        Batch_CreateRiskProjectTest
@ Version:      1.0
@ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:      Test for Batch_CreateRiskProject
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.Aug.2021 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class.
@ Change history: 27.Apr.2022 / Chetra Sarom (chetra.sarom@gaea-sys.com) :US-0011612 - Automated Risk Project logic modification
*********************************************************************************************************************************/
@isTest
private class Batch_CreateRiskProjectTest {
    static testMethod void testCreateRiskProject(){
        
        EBH_TestDataFactory.setUpCustomSettings();   
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        
        // 27.Apr.2022 / Chetra Sarom (chetra.sarom@gaea-sys.com) / US-0011612 - Automated Risk Project logic modification
        Account acc1 = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',Risk_tier_manual__c=1,RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',Risk_Status__c=Batch_CreateRiskProject.APPROVED);//LA:05-12-2023-US-0014231: Remove EBH_DealsProgram__c='Accepted'
        Account acc2 = new Account(EBH_OracleId__c='1003293592',Name='Test Acc2',Risk_tier_manual__c=2,RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='US',Risk_Status__c=Batch_CreateRiskProject.APPROVED);//LA:05-12-2023-US-0014231: Remove EBH_DealsProgram__c='Accepted'
        Account acc3 = new Account(EBH_OracleId__c='1003293593',Name='Test Acc3',Risk_tier_manual__c=3,RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='FR',Risk_Status__c=Batch_CreateRiskProject.APPROVED);//LA:05-12-2023-US-0014231: Remove EBH_DealsProgram__c='Accepted'
        Account acc4 = new Account(EBH_OracleId__c='1003293594',Name='Test Acc4',Risk_tier_manual__c=4,RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='IT',Risk_Status__c=Batch_CreateRiskProject.APPROVED);//LA:05-12-2023-US-0014231: Remove EBH_DealsProgram__c='Accepted'
        Account acc5 = new Account(EBH_OracleId__c='1003293595',Name='Test Acc5',Risk_tier_manual__c=5,RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='DE',Risk_Status__c=Batch_CreateRiskProject.APPROVED);//LA:05-12-2023-US-0014231: Remove EBH_DealsProgram__c='Accepted'
        Account acc6 = new Account(EBH_OracleId__c='1003293596',Name='Test Acc6',Risk_tier_manual__c=6,RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',Risk_Status__c=Batch_CreateRiskProject.APPROVED);//LA:05-12-2023-US-0014231: Remove EBH_DealsProgram__c='Accepted'
		// end US-0011612
        insert new List<Account>{acc1,acc2,acc3,acc4,acc5,acc6};
        //update Risk_Last_modified_Date__c for testing
        acc1.Risk_Last_modified_Date__c = System.now()-360;
        acc2.Risk_Last_modified_Date__c = System.now()-360;
        acc3.Risk_Last_modified_Date__c = System.now()-180;
        acc4.Risk_Last_modified_Date__c = System.now()-90;
        acc5.Risk_Last_modified_Date__c = System.now()-45;
        acc6.Risk_Last_modified_Date__c = System.now()-360;
        List<Account> lstToUpdated = new List<Account>{acc1,acc2,acc3,acc4,acc5,acc6};
        update lstToUpdated;
        Test.startTest();
            Database.executeBatch(new Batch_CreateRiskProject());
        Test.stopTest();
        List<EBH_Project__c> lst = [select id from EBH_Project__c where EBH_Seller__c IN: lstToUpdated];
        System.assert(lst.size()==5);
    }
}