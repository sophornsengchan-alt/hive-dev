/*********************************************************************************************************************************
@ Class:          QueryUtil
@ Version:        1.0
@ Author:         Mony Nou
@ Purpose:        US-0012419 - Test class for QueryUtil
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.10.2022 / Mony Nou / Created the class.
*********************************************************************************************************************************/

@isTest
private class QueryUtilTest {

    @isTest 
    static void test_queryRecord() {

        Account account = TST_DataGenerator.generateAccount();
        insert account;

        Opportunity opp = TST_DataGenerator.generateOpp(account.Id);
        opp.RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id;
        
        insert new List<Opportunity>{opp};


        Test.startTest();
            
            Account res = (Account) QueryUtil.queryRecord(account.Id);
            System.assert(res != null, 'There should be an Account record retrieved from the method.');

            Set<String> sStringId = QueryUtil.toStringSet(new Set<Id>{account.Id});
            System.assert(!sStringId.isEmpty(), 'This set of string should not empty.');

            List<Account> res1 = (List<Account>) QueryUtil.queryRecords('Account', sStringId);
            System.assert(!res1.isEmpty(), 'There should be an Account record retrieved from the method.');

            String res2 = QueryUtil.getQueryFieldString('Account');
            System.assert(String.isNotBlank(res2), 'This string should not empty.');

            List<Account> res3 = (List<Account>) QueryUtil.queryRecordsWithChildren('Account', '', 'Opportunities', sStringId);
            System.assert(!res3.isEmpty(), 'There should be an Account record retrieved from the method.');

            List<Account> res4 = (List<Account>) QueryUtil.queryRecords('Account');
            System.assert(!res4.isEmpty(), 'There should be an Account record retrieved from the method.');

            List<Account> res5 = (List<Account>) QueryUtil.queryRecords('Account', '');
            System.assert(!res5.isEmpty(), 'There should be an Account record retrieved from the method.');

            List<Account> res6 = (List<Account>) QueryUtil.queryRecords('Account', '', new Map<String,Object>());
            System.assert(!res6.isEmpty(), 'There should be an Account record retrieved from the method.');

            List<Account> res7 = (List<Account>) QueryUtil.queryRecords('Account', '', new Set<String>(), new Map<String,Object>());
            System.assert(!res7.isEmpty(), 'There should be an Account record retrieved from the method.');

            List<Account> res8 = (List<Account>) QueryUtil.queryRecords('Account', '', new Set<String>(), new Map<String,Object>(), '');
            System.assert(!res8.isEmpty(), 'There should be an Account record retrieved from the method.');
            

        Test.stopTest();

    }
    
}