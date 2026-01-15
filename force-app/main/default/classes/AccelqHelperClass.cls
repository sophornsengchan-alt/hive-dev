/*This class is used to delete records based on the provided userId and processName
 * Developer: Anujit
 ----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 07.07.2025 / Sothea Horn / US-0033083 - Enable the merging tool for DWH contact
@               : 17/07/2025 / Sovantheany Dim / US-0033220 - [Blocking] Timeout error when run delete records method from accelQ
@               : 03.09.2025 / Sothea Horn / US-0033306 / Fix issue System.QueryException: sObject type 'AccountPlan' is not supported.
*********************************************************************************************************************************/

public without sharing class AccelqHelperClass {
    
    // This method deletes records based on the provided userId and processName
    public static void deleteRecords(string userId, string processName){

        // Map to store the object name and the maximum number of records to delete
        Map<String, Integer> objectNameToMaxRecords = new Map<String, Integer>();
        List<SObject> recordsToDelete = new List<SObject>();

        // Retrieve the metadata records based on the provided processName
        String soqlAccelqDeleteRecordConfig = 'SELECT Object_Name__c, Process_Name__c, Execution_Order__c, isActive__c, MaxRecordsToDelete__c FROM AccelqDeleteRecordConfigration__mdt WHERE isActive__c = true AND Process_Name__c =:processName ORDER BY Execution_Order__c ASC';
        ApexSafe.SafeQuery safeQuery = ApexSafe.query().secCheck(false); 
        List<AccelqDeleteRecordConfigration__mdt> metadataList = safeQuery.doQuery(soqlAccelqDeleteRecordConfig, new Map<String, Object> {'processName' => processName});
        
        // Populate the map with the object name and the maximum number of records to delete
        for (AccelqDeleteRecordConfigration__mdt metadata : metadataList) {
            objectNameToMaxRecords.put(metadata.Object_Name__c, Integer.valueOf(metadata.MaxRecordsToDelete__c));
        }
        
        // Retrieve the records to delete based on the userId and the object name
        for (String objectName : objectNameToMaxRecords.keySet()) {
            // 03.09.2025 / Sothea Horn / US-0033306 / Fix issue System.QueryException: sObject type 'AccountPlan' is not supported.
            String query = 'SELECT Id FROM ' + objectName + ' WHERE CreatedById = :userId and CreatedDate = LAST_N_DAYS:30  LIMIT ' + objectNameToMaxRecords.get(objectName);//US-0033220: add Index field CreatedDate
            recordsToDelete.addAll(safeQuery.doQuery(query, new Map<String, Object> {'userId' => userId}));
        }

        try {
            // ApexSafe.SafeDML safeDml = ApexSafe.dml().secCheck(false);
            ApexSafe.dml().secCheck(false).doDelete(recordsToDelete, true);
        } catch (DmlException e) {
            System.debug('An error occurred when deleting records: ' + e.getMessage());
            // Handle the exception as needed
        }
    }

    /*****************************************************************************************************************************
    @ Method:         createRecord
    @ Version:        1.0
    @ Author:         Sothea Horn
    @ Purpose:        US-0033083 - Enable the merging tool for DWH contact
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      userId            : owner of the new created record
    @ Parameter:      objectName        : the name of the object record to be created
    @ Parameter:      jsonFieldsValues  : the fields values of the record to be created as JSON
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.07.2025 / Sothea Horn / Created the Method.
    *****************************************************************************************************************************/
    public static void createRecord(string userId, string objectName, string jsonFieldsValues) {
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectName);
        SObject record = sobjectType.newSObject();
        record.put('OwnerId', userId);
        // Populate fields value
        Map<String, Object> fieldValuesMap = (Map<String, Object>)JSON.deserializeUntyped(jsonFieldsValues);
        if (fieldValuesMap != null) {
            for (String fieldName : fieldValuesMap.keySet()) {
                record.put(fieldName, fieldValuesMap.get(fieldName));
            }
        }
        try {
            ApexSafe.SafeDML safeDml = ApexSafe.dml().secCheck(false);
            safeDml.doInsert(new List<SObject>{record}, true);
         } catch (DmlException e) {
            System.debug('An error occurred when creating a record: ' + e.getMessage());
            // Handle the exception as needed
        }
    }
}