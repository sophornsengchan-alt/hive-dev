@isTest
public class CustomDataTableForAMControllerTest {
        
    @isTest
    static void testGetRecords() {
        EBH_TestDataFactory.setUpCustomSettings(); 

        // Setup test data
        String objectApiName = 'Task';
        String fieldSetName = 'My_Planned_Call';
        String userFieldName = 'OwnerId';
        String additionalClause = '';
        String sortBy = 'Id';
        String filterBy = 'CreatedDate = LAST_N_DAYS:30';
        String recordLimit = '10';

        List<Account> lstAcc = EBH_TestDataFactory.createAccounts(1,'EBH_Seller');
        // Create test records
        Task task = new Task(
            Subject = 'Test Call',
            ActivityDate = System.today(),
            OwnerId = UserInfo.getUserId(),
            WhatId = lstAcc.get(0).Id
            );
        insert task;

        // Create a field set with fields
        // Note: Field sets cannot be created in Apex, so this part is assumed to be pre-existing in the org

        // Call the method
        Test.startTest();
        Map<String, Object> result = CustomDataTableForAMController.getRecords(
            objectApiName, 
            fieldSetName, 
            userFieldName, 
            additionalClause, 
            sortBy, 
            filterBy, 
            recordLimit
        );
        Test.stopTest();

        // Assert the results
        System.assert(result.containsKey('records'), 'Result should contain records');
        System.assert(result.containsKey('fields'), 'Result should contain fields');

        List<SObject> records = (List<SObject>) result.get('records');
        System.assertEquals(1, records.size(), 'There should be one record returned');

        List<Map<String, String>> fields = (List<Map<String, String>>) result.get('fields');
        System.assert(fields.size() > 0, 'Fields should not be empty');
    }
}