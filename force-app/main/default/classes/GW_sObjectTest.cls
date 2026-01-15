/*****************************************************************************************************************************
@ Class:       GW_sObject
@ Author:      Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:     US-0008388 - Upgrade code coverage of GW_sObject from 70% to 85% [ lines not covered 16]
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  19.04.2021 / Mony Nou / Created the method.
@*****************************************************************************************************************************/
@IsTest 
private class GW_sObjectTest {

    static Account acc;
    static Opportunity opp;

    private static void setUpData(){
		
		acc = TST_DataGenerator.generateAccount();
        insert acc;

        opp = TST_DataGenerator.generateOpp(acc.Id);
        opp.Special_Terms__c = 'New Terms - Spe';
        opp.StageName = 'Qualified Meeting';
        insert opp;
	}
   
    @isTest
    static void test_isFieldChanged () {

        setUpData();

        Test.startTest();

            Account acc_new = acc.clone();
            acc_new.Name = 'Changed Name';

            Boolean result = GW_sObject.isFieldChanged(acc_new, acc, 'Name');

            System.assert(result, 'Result should be TRUE');
            
            result = GW_sObject.isFieldChanged(acc_new, null, 'Name');
            System.assert(result, 'Result should be TRUE');

            result = GW_sObject.oneOrMoreFieldsChanged(acc_new, acc, new Set<String>());
            System.assert(!result, 'Result should be FALSE');

        Test.stopTest();
    }

    @isTest
    static void test_fieldExists() {

        Test.startTest();

            Boolean result = GW_sObject.fieldExists('Account', 'Name');
            System.assert(result, 'Result should be TRUE');

        Test.stopTest();
    }

    @isTest
    static void test_getMapChildren() {

        setUpData();

        Test.startTest();

            Map<Id, List<SObject>> result = GW_sObject.getMapChildren(new List<SObject>{opp}, 'AccountId');
            System.assert(result != null, 'Result should not be null');
            
        Test.stopTest();
    }

    @isTest
    static void test_getIds() {

        setUpData();

        Test.startTest();

            Set<String> result = GW_sObject.getIds(new List<SObject>{opp}, 'Id');
            System.assert(result != null, 'Result should not be null');
            
        Test.stopTest();
    }

    @isTest
    static void test_getFieldValueAsObject() {

        setUpData();

        Test.startTest();

            opp = [SELECT Name, Account.Name FROM Opportunity WHERE Id=:opp.Id];

            Object result = GW_sObject.getFieldValueAsObject(opp, 'Account.Name');
            System.assert(result != null, 'Result should not be null');

            result = GW_sObject.getFieldValueAsObject(opp, 'Name');
            System.assert(result != null, 'Result should not be null');

        Test.stopTest();
    }
 
}