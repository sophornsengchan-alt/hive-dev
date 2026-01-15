@IsTest
private class SEPServiceEventTriggerHandlerTest {
    @IsTest
    static void testHandleCreateLog() {
        
        //create Custom Setting record for EBH_ActiveTriggers__c
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller', Seller_Portal_Service__c = true);
        
        // Create test data
        List<SellerPortalServiceEvent__e> serviceList = new List<SellerPortalServiceEvent__e>();
        SellerPortalServiceEvent__e event1 = new SellerPortalServiceEvent__e();
        event1.Json_Data__c = '{"JsonData": {"action": "create", "targetObject": "Seller_Portal_Log__c", "targetData": {"Seller_Name__c": "Test Account"}}}';
        serviceList.add(event1);

        // Call the method being tested
        Test.startTest();
        SEPServiceEventTriggerHandler.handleCreateLog(serviceList);
        Test.stopTest();

        // Verify the results
        List<Seller_Portal_Service__c> insertedRecords = [SELECT Json_Data__c FROM Seller_Portal_Service__c];
        System.assertEquals(1, insertedRecords.size());
    }
}