/**
 * Test class for RequestSapNumber
 */
@isTest
private class RequestSapNumberTest {
    
    @isTest
    static void test_SendEmailNotification() {

        Test.startTest();

            Account test_account = TST_DataGenerator.generateAccount();
            insert test_account;

            Map<String,Object> result = RequestSapNumber.SendEmailNotification(test_account.Id);
            System.debug('### result :: ' + result);
            System.assert(result != null && !result.isEmpty());

        Test.stopTest();

    }
}