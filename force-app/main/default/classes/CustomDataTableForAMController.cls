/*********************************************************************************************************************************
@ Class:         CustomDataTableForAM
@ Version:       1.0
@ Author:        Acmatac Seing
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.02.2024 / Acmatac Seing / US-0016646 - Homepage for AM Cockpit - EA Components
@               : 26.08.2025 / Sothea Horn / US-0033306 - [TDD] Creating List view for Account Plans on Parent
*********************************************************************************************************************************/
public with sharing class CustomDataTableForAMController {
    
    /**
     * @description Main entry point for retrieving records from a given object 
     * based on the specified field set and various query parameters.
     * @param objectApiName The API name of the SObject.
     * @param fieldSetName The name of the field set to retrieve fields from.
     * @param recordOwnerField The name of the field in the SObject that references the current user (e.g., OwnerId).
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
        String recordOwnerField, 
        String additionalClause, 
        String sortBy, 
        String filterBy, 
        String recordLimit
    ) {
        // 26.08.2025 / Sothea Horn / US-0033306 / modified to call method CustomDynamicRelatedListController.getRecords for centralization  
        return CustomDynamicRelatedListController.getRecords(objectApiName, fieldSetName, null, null, recordOwnerField, additionalClause, sortBy, filterBy, recordLimit);
    }

}