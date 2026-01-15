@IsTest
public class UpdateJsonFieldTest {
    
    @TestSetup
    static void setup() {
        // Create a test Account record with a JSON field
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Partner_Comment__c = '{"test":"oldValue"}';  // Assume this is a custom field that stores JSON
        insert acc;
    }

    @IsTest
    static void testUpdateJsonField() {
        // Retrieve the test Account created in the @TestSetup method
        Account testAcc = [SELECT Id, Partner_Comment__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Define the input parameters for the invocable method
        UpdateJsonField.InputParameters input = new UpdateJsonField.InputParameters();
        input.recordId = testAcc.Id;
        input.objectName = 'Account';
        input.fieldName = 'Partner_Comment__c';
        input.variableName = 'test';
        input.newValue = 'newValue';
        
        // Call the invocable method
        List<UpdateJsonField.InputParameters> inputs = new List<UpdateJsonField.InputParameters>();
        inputs.add(input);
        
        Test.startTest();
        UpdateJsonField.updateJsonField(inputs);
        Test.stopTest();
        
        // Query the record again to check if the JSON was updated
        Account updatedAcc = [SELECT Partner_Comment__c FROM Account WHERE Id = :testAcc.Id LIMIT 1];
        
        // Verify the JSON field was updated correctly
        Map<String, Object> jsonData = (Map<String, Object>)JSON.deserializeUntyped(updatedAcc.Partner_Comment__c);
        System.assertEquals('newValue', jsonData.get('test'), 'The JSON variable was not updated correctly.');
    }
}