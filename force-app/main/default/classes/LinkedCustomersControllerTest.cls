/*********************************************************************************************************************************
@ Class:          LinkedCustomersControllerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0009214 - [Linked Acc]Enable Linked B2C Customers to be shown in Customer 360
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.03.2021 / Sovantheany Dim / Created the class.
                : 17.03.2025 / Bora Chhorn / US-0016865 - Display Linked Customers on the Seller 360
                : 01.04.2025 / Sothea Horn / US-0017049 - Validate Linkage and capture first call feedback
*********************************************************************************************************************************/
@isTest
public class LinkedCustomersControllerTest {
    static testMethod void testgetAccounts(){
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account sellerAcc1 = new Account(Linked_Acc_Group_Id__c='11111111',EBH_OracleId__c='1003293592',Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
    	insert sellerAcc1;
        Account sellerAcc2 = new Account(Linked_Acc_Group_Id__c='11111111', EBH_OracleId__c='1003293593',Name='Test Acc3',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
    	insert sellerAcc2;
        Test.startTest();
        	Map<String,Object> mapResult = LinkedCustomersController.getAccounts(sellerAcc1.Id,6,'LinkedCustomers');                                 
        Test.stopTest();
        if(mapResult.containsKey('lstWrapper')){
            ContactsRelatedController.LightningTableWraper lstWrapper = (ContactsRelatedController.LightningTableWraper) mapResult.get('lstWrapper');
            System.assert(lstWrapper.tableRecord.size()==1);
        }
    }

    static testMethod void updateLinkedCustomers(){
        List<Account> listAccs = new List<Account>();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account sellerAcc1 = new Account(Linked_Acc_Group_Id__c='11111111',EBH_OracleId__c='1003293595',Name='Test Acc4',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
    	listAccs.add(sellerAcc1);
        Account sellerAcc2 = new Account(Linked_Acc_Group_Id__c='11111111', EBH_OracleId__c='1003293596',Name='Test Acc5',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
    	listAccs.add(sellerAcc2);
        Account sellerAcc3 = new Account(Linked_Acc_Group_Id__c='11111111', EBH_OracleId__c='1003293597',Name='Test Acc6',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
    	listAccs.add(sellerAcc3);
        insert listAccs;
        Set<Id> accIdsSet = new Set<Id>{sellerAcc2.Id, sellerAcc3.Id};
        Test.startTest();
            List<Account> listUpdatedLikedAccs = [Select Id, Name, ParentId, ValidateLinkage__c from Account where Id IN: accIdsSet];
            for (Account acc : listUpdatedLikedAccs) {
                acc.ValidateLinkage__c = 'Seller Rejected';
                acc.ValidateLinkage__c = 'Seller Uncertain';
            }
        	Map<String,Object> mapResult = LinkedCustomersController.updateLinkedCustomers(listUpdatedLikedAccs);                                 
        Test.stopTest();
        if(mapResult.containsKey('lstWrapper')){
            List<Account> listLikedAccs = [Select Id, ValidateLinkage__c from Account where Id IN: accIdsSet order by Name];
            System.assert(listLikedAccs.size()==2);
            System.assertEquals(listLikedAccs[0].ValidateLinkage__c, 'Seller Rejected');
            System.assertEquals(listLikedAccs[1].ValidateLinkage__c, 'Seller Uncertain');
        }
    }
}