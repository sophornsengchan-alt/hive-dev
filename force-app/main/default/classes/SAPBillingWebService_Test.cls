@isTest
private class SAPBillingWebService_Test {


    @isTest
    private static void doTest() {


        RecordType rt = [SELECT id FROM recordType WHERE sobjectType = 'Account' AND name = 'Legal Entity'];

        Account parent = new Account(name='Parent', recordtypeID=rt.id);
        insert parent; 

        Account acc = new Account(name='TestForAccountName', sap_status__c='Ready to Sync', parentId = parent.id, recordtypeID=rt.id);
        insert acc;

        Contact c = new Contact(lastname='TEST', accountID=acc.id);
        insert c;

        String jsonString = SAPBillingWebService.getRecords('TestingOnly'); // cannot create metadata types in test methods, so must always have a TestingOnly metadata type
        System.assertNotEquals(jsonString, null);

        System.assert(jsonString.contains('"NAME1":"TestForAccountName"'));
        System.assert(jsonString.contains('"NAME2":"Parent"'));


    }
}