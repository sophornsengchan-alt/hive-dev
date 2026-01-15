/*********************************************************************************************************************************
@ Class:          QuickActionRedirectorControllerTest
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        Code Coverage for QuickActionRedirectorController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.09.2021 / Mony Nou / Created the class.
*********************************************************************************************************************************/
@isTest
private class QuickActionRedirectorControllerTest {

    @isTest
    static void test_validateDealForAmendContract() {

        Test.startTest();

            Map<String,Object>  resutl = QuickActionRedirectorController.validateDealForAmendContract('');
            System.debug('***** resutl :: ' + resutl);
            
        Test.stopTest();

    }

    @isTest
    static void test_cancelAmendContract() {

        Test.startTest();

            Map<String,Object>  resutl = QuickActionRedirectorController.cancelAmendContract('');
            System.debug('***** resutl :: ' + resutl);
        Test.stopTest();

    }

    @isTest
    static void test_withdrawApprovalQuote() {

        Test.startTest();

            Map<String,Object>  resutl = QuickActionRedirectorController.withdrawApprovalQuote('');
            System.debug('***** resutl :: ' + resutl);
        Test.stopTest();

    }
}