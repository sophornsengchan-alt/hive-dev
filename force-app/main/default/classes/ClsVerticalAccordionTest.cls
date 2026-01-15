/*********************************************************************************************************************************
@ Class:          ClsVerticalAccordionTest
@ Version:        1.0
@ Author:         Sochettra Saing
@ Purpose:        Ability to run test the logic in class ClsVerticalAccordionTest(EBAY-226)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 2.07.2021 / Sochettra Saing / Created the class.
*********************************************************************************************************************************/

@isTest 
public with sharing class ClsVerticalAccordionTest {
    static testMethod void testMethod1() {

        Test.startTest();
        Map<String, Object>  mResult = ClsVerticalAccordion.getSettings('Deal_Retail_Period');

        //System.debug('>>>>>>>> mResult:' + mResult);
        System.assertEquals('status:success', 'status:'+ mResult.get('status'));
        //System.assertEquals('status:success', 'status:'+ mResult.get('status'));
        
        Map<String, Object>  mResultExistingRec = ClsVerticalAccordion.getExistingRecords('test', 'Deal_Window__c', 'asc', 'Deal_Retail_Period');
        //System.debug('>>>>>>>> mResult:' + mResultExistingRec);
        List<Sobject> lstSobj = (List<Sobject>) mResultExistingRec.get('listRecord');
        if(lstSobj != null){
        	System.assertEquals('listRecord:0', 'listRecord:'+ lstSobj.size());
        }

        Test.stopTest();
    }
}