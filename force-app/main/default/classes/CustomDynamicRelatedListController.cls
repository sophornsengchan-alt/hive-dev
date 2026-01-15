/*********************************************************************************************************************************
@ Class:         CustomDynamicRelatedListController
@ Version:       1.0
@ Author:        Sothea Horn
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.08.2025 / Sothea Horn / US-0033306 - [TDD] Creating List view for Account Plans on Parent 
*********************************************************************************************************************************/
public with sharing virtual class CustomDynamicRelatedListController {
    private final static String REFERENCE_FIELD_SUFFIX = '__c';
    private static final Set<String> STANDARD_NAME_FIELD_SET = new Set<String>{'Name', 'Subject'};
    private static final Map<String, Map<String, String>> FIELD_LABEL_MAP = new Map<String, Map<String, String>>{
        'Event' => new Map<String, String>{'Related To ID' => 'Seller', 'Start Date Time' => 'Start Date'},
        'Task' => new Map<String, String>{'Due Date Only' => 'Due Date'}
    };
    
    /**
     * @description Main entry point for retrieving records from a given object 
     * based on the specified field set and various query parameters.
     * @param objectApiName The API name of the SObject.
     * @param fieldSetName The name of the field set to retrieve fields from.
     * @param parentField The name of the field in the SObject that references the parent (e.g., AccountId).
     * @param parentFieldValue The value of the field in the SObject that references the parent
     * @param ownerField The name of the field in the SObject that references the current user (e.g., OwnerId).
     * @param additionalClause Additional conditions for the WHERE clause.
     * @param sortBy The field name to sort by.
     * @param filterBy Additional filter logic appended to the WHERE clause.
     * @param recordLimit String representation of the limit for the number of rows.
     * @return A map containing 'records', 'fields', and 'queryStr'.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRecords(
        String objectApiName, 
        String fieldSetName, 
        String parentField,
        String parentFieldValue,
        String ownerField, 
        String additionalClause, 
        String sortBy, 
        String filterBy, 
        String recordLimit
    ) {
        try {
            List<Map<String, String>> fieldMetadata = getFieldSetFields(objectApiName, fieldSetName);
            if (fieldMetadata.isEmpty()) {
                throw new AuraHandledException('Field set has no fields.');
            }

            // Gather the actual field names for the query
            List<String> fieldNames = new List<String>();
            for (Map<String, String> field : fieldMetadata) {
                fieldNames.add(field.get('fieldName'));
            }

            // Build the SOQL query
            String queryString = buildQuery(
                objectApiName,
                fieldNames,
                parentField,
                parentFieldValue,
                ownerField,
                filterBy,
                additionalClause,
                sortBy,
                recordLimit
            );
            // Execute the query, to avoid the field fls or record sharing issue, we query without sharing.
            List<SObject> records = ApexSafe.query().secCheck(false).doQuery(queryString, new Map<String, Object>{ 'parentFieldValue' => parentFieldValue, 'currentUserId' => UserInfo.getUserId() });
            
            // Return results in a structured map
            return new Map<String, Object> {
                'records'  => records,
                'fields'   => fieldMetadata
            };
        } catch (Exception e) {
            // Log or handle the exception as needed
            throw new AuraHandledException('Error retrieving records: ' + e.getMessage()+' : '+e.getStackTraceString());
        }
    }

    /**
     * @description Retrieves the fields from the specified field set in an SObject.
     * @param objectApiName The API name of the SObject.
     * @param fieldSetName The name of the field set to retrieve fields from.
     * @return A list of maps, each containing field metadata (API name, label).
     */
    private static List<Map<String, String>> getFieldSetFields(
        String objectApiName, 
        String fieldSetName
    ) {
        List<Map<String, String>> fieldMetadata = new List<Map<String, String>>();
        Schema.DescribeSObjectResult objSchema = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        Schema.FieldSet fieldSet = objSchema.fieldSets.getMap().get(fieldSetName);
        if (fieldSet == null) {
            // If no matching field set is found, return an empty list or throw an exception
            return fieldMetadata;
        }

        Map<String, Schema.SObjectField> fieldMap = objSchema.fields.getMap();
        for (Schema.FieldSetMember fMember : fieldSet.getFields()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fMember.getFieldPath()).getDescribe();
            Map<String, String> fieldDetails = new Map<String, String>();
            String fieldName = fMember.getFieldPath();
            String fieldApi = fMember.getFieldPath();
            String fieldType = String.valueOf(fieldDescribe.getType());
            String fieldLabel = fMember.getLabel();

            // Handle reference fields: change <Field>__c to <Field>__r.Name or standardRefField.Name
            if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                if (fieldDescribe.isCustom()) {
                    String relatedObjApiName = fieldDescribe.getReferenceTo().get(0).getDescribe().getName();
                    // We use ContractNumber field instead of Name
                    if(relatedObjApiName == 'Contract'){
                        // Adjust this logic if your suffix or reference handling differs
                        fieldName = fieldName.replace(
                            REFERENCE_FIELD_SUFFIX,
                            '__r.ContractNumber'
                        );
                    }
                    else{
                        // Adjust this logic if your suffix or reference handling differs
                        fieldName = fieldName.replace(
                            REFERENCE_FIELD_SUFFIX,
                            '__r.Name'
                        );
                    }
                } else {
                    // Standard polymorphism field, like WhatId
                    if(fieldApi == 'WhatId'){
                        fieldName = fieldName.replace('Id', '.Name');
                    }
                    else{
                        fieldName = fieldName.replace('Id', '.Name');
                    }
                }
            }

            // Standard Name Field then set type as Name
            if(!fieldDescribe.isCustom() && STANDARD_NAME_FIELD_SET.contains(fieldApi)){
                fieldType = 'NAME';
            }
            
            // Relabel the column. Example: Related To Id => Seller, Due Date Only => Due Date
            if(FIELD_LABEL_MAP.containsKey(objectApiName)){
                if(FIELD_LABEL_MAP.get(objectApiName).containsKey(fieldLabel)){
                    fieldLabel = FIELD_LABEL_MAP.get(objectApiName).get(fieldLabel);
                }
            }

            fieldDetails.put('fieldApi', fieldApi);
            fieldDetails.put('fieldName', fieldName);
            fieldDetails.put('label', fieldLabel);
            fieldDetails.put('type', fieldType);
            fieldMetadata.add(fieldDetails);
        }

        return fieldMetadata;
    }

    /**
     * @description Constructs a dynamic SOQL query string based on the provided parameters.
     * @param objectApiName The API name of the SObject.
     * @param fieldNames A list of fields to select.
     * @param parentField
     * @param parentFieldValue
     * @param ownerField The field that references the current user (for filtering).
     * @param filterBy Additional filter logic appended to the WHERE clause.
     * @param additionalClause Additional WHERE clause conditions.
     * @param sortBy The field to sort by.
     * @param recordLimit The max number of records to return.
     * @return The dynamic SOQL query string.
     */
     private static String buildQuery(
        String objectApiName,
        List<String> fieldNames,
        String parentField,
        String parentFieldValue,
        String ownerField,
        String filterBy,
        String additionalClause,
        String sortBy,
        String recordLimit
    ) {
        // Start building the query
        String fieldList = String.join(fieldNames, ',');
        String query = 'SELECT ' + fieldList + ' FROM ' + objectApiName;

        // WHERE clause conditions
        List<String> conditions = new List<String>();

        if (String.isNotBlank(parentField) ) {
            // We bind 'parentFieldValue' later in doQuery
            conditions.add(String.escapeSingleQuotes(parentField) + ' = :parentFieldValue');
        }

        if (String.isNotBlank(ownerField)) {
            // We bind 'currentUserId' later in doQuery
            conditions.add(String.escapeSingleQuotes(ownerField) + ' = :currentUserId');
        }

        if (String.isNotBlank(filterBy)) {
            conditions.add(String.escapeSingleQuotes(filterBy));
        }

        if (String.isNotBlank(additionalClause)) {
            conditions.add(additionalClause);
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        // Handle sort
        if (String.isNotBlank(sortBy)) {
            query += ' ORDER BY ' + sortBy;
        }

        // Handle limit
        if (String.isNotBlank(recordLimit)) {
            query += ' LIMIT ' + recordLimit;
        }

        return query;
    }
}