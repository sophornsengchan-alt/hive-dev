@isTest
private class SellerPortalServiceTriggerHandlerTest {
    @isTest
    static void testHandleCreateLog() {

        //create Custom Setting record for EBH_ActiveTriggers__c
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller', Seller_Portal_Service__c = true);

        // Create test data
        List<Seller_Portal_Service__c> serviceList = new List<Seller_Portal_Service__c>();
        Seller_Portal_Service__c service1 = new Seller_Portal_Service__c(Json_Data__c = '{"action": "create", "targetObject": "Seller_Portal_Log__c", "targetData": {"Seller_Name__c": "Test Account"}}');
        serviceList.add(service1);
        insert serviceList;

        // Call the method to be tested
        Test.startTest();
        SellerPortalServiceTriggerHandler.handleCreateLog(serviceList);
        Test.stopTest();

        // Perform assertions
        Seller_Portal_Log__c testLog = [SELECT Id, Seller_Name__c FROM Seller_Portal_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertNotEquals(null, testLog, 'Log should be created');
        System.assertEquals('Test Account', testLog.Seller_Name__c, 'Log Seller Name should be "Test Account"');
    }
}