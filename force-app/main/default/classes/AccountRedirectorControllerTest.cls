/**
 * Test class for AccountRedirectorController
 */
@isTest
private class AccountRedirectorControllerTest {
    
    @isTest
    static void test_handleRequestSAPID() {

        Test.startTest();

            Account test_account = new Account(
                Name = 'Test Account'
            );
            insert test_account;

            Map<String,Object> result = AccountRedirectorController.handleRequestSAPID(test_account.Id);
            
            System.assert(result != null && !result.isEmpty());

        Test.stopTest();

    }

}