/*
 * Created by: David Herrero
 * Creation Date: October 11, 2024
 * Purpose: This class updates a specific variable inside a JSON field within a Salesforce object.
 * Version: 1.0
 */

public with sharing class UpdateJsonField {
  // Define the invocable input class
  public class InputParameters {
    @InvocableVariable(required=true)
    public String recordId; // ID of the record to update

    @InvocableVariable(required=true)
    public String objectName; // Name of the object (e.g., 'Account', 'CustomObject__c')

    @InvocableVariable(required=true)
    public String fieldName; // Name of the field that contains the JSON

    @InvocableVariable(required=true)
    public String variableName; // Name of the variable inside the JSON

    @InvocableVariable(required=true)
    public String newValue; // New value to update in the JSON
  }

  // Invocable method
  @InvocableMethod(
    label='Update JSON Field'
    description='Updates a JSON field in a given object'
  )
  public static void updateJsonField(List<InputParameters> inputs) {
    for (InputParameters input : inputs) {
      // Create the SOQL query dynamically
      String inputid = input.recordId;
      String query =
        'SELECT ' +
        input.fieldName +
        ' FROM ' +
        input.objectName +
        ' WHERE Id = :inputid';
      System.debug('query: ' + query);
      System.debug('inputid: ' + inputid);
      System.debug('input.fieldName: ' + input.fieldName);
      System.debug('input.objectName: ' + input.objectName);

      // Execute the query
      List<SObject> records = Database.query(query);

      if (!records.isEmpty()) {
        SObject record = records[0];

        // Retrieve the JSON field
        String jsonField = (String) record.get(input.fieldName);

        // Parse the JSON field
        Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
          jsonField
        );

        // Update the variable in the JSON
        jsonData.put(input.variableName, input.newValue);

        // Serialize the updated JSON
        String updatedJsonField = JSON.serialize(jsonData);

        // Assign the modified value back to the field
        record.put(input.fieldName, updatedJsonField);

        // Update the record
        update record;
      }
    }
  }
}