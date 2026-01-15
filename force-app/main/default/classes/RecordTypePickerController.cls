/*********************************************************************************************************************************@ Class:          SEPCouponController@ Version:        1.0
@ Author:         
@ Purpose:        The purpose of this class could be to provide methods that:
@                   - Retrieve a list of available record types for a specific object.
@                   - Determine the default record type for a specific object.
@                   - Handle user selection of a record type from a list.
@                   - Navigate to the appropriate page layout based on the selected record type.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.04.2024 / Mony Nou / Created the class for US-0015145
@
@
*********************************************************************************************************************************/
global with sharing class RecordTypePickerController {
    
    /* NOT USE FOR NOW BUT MIGHT USE IN FUTURE
    // Use this method in flow to get a list of Record Types for a given object
    @AuraEnabled(cacheable=true)
    public static List<RecordType> getRecordTypes(String sObjectApiName) {
    
        Set<Id> availableRTForSelectedObject = RecordTypePickerController.availableRecordTypeIdsFromObjectApiNames(
            new List<String>{ sObjectApiName }
        );

        return [
            SELECT Id, Name, Description, DeveloperName 
            FROM RecordType 
            WHERE Id IN :availableRTForSelectedObject
        ];
    }
    */

    /**
     * @description This class provides a method to retrieve a collection of Record Types that are available to the running user for a given object API name.
     * @category Record Types
     * @iconName slds:standard:relationship
     */
    @InvocableMethod(
        label='Record Types for Running User'
        description='Input an Object\'s API name, returns a collection of Record Types that are available to the running user'
        category='Record Types'
        iconName='slds:standard:relationship'
    )
    global static List<RecordTypePickerController.Result> invokeGetRecordTypes(List<RecordTypePickerController.Request> requests) {
        Set<String> objectNameSet = new Set<String>();
        Set<Id> availableRecordTypeIds = new Set<Id>();
        List<RecordTypePickerController.Result> results = new List<RecordTypePickerController.Result>();

        for (RecordTypePickerController.Request request : requests) {
            objectNameSet.add(request.objectApiName);
        }

        availableRecordTypeIds.addAll(
            RecordTypePickerController.availableRecordTypeIdsFromObjectApiNames(new List<String>( objectNameSet ))
        );

        Map<String,List<RecordType>> objToRtMap = RecordTypePickerController.getMapOfObjectNameToRT(
            RecordTypePickerController.recordTypesFromIds(availableRecordTypeIds)
        );

        for (RecordTypePickerController.Request request : requests) {
            RecordTypePickerController.Result result = new RecordTypePickerController.Result();
            result.recordTypes = objToRtMap.get(request.objectApiName);
            results.add(result);
        }
        
        return results;
    }

    global class Request {
        @InvocableVariable(
            label='Object API Name'
            required=true
        )
        global String objectApiName;
    }

    global class Result {
        @InvocableVariable(
            label='Record Types for Running User'
        )
        global List<RecordType> recordTypes;
    }

    /**
     * For use in Custom Property Editor to Return a list of Objects that have active RecordTypes
     * 
     */
    /* NOT USE FOR NOW BUT MIGHT USE IN FUTURE
    @AuraEnabled(cacheable=true)
    public static List<EntityDefinition> getObjectsWithRecordTypes(){
        // There's a deprecated standard object called Metric with RecordTypes. WTF.
        // Anyway, there's hardcoding here to filter it out. Whatever.
        // TODO: find a better way to handle this. Cannot use UserEntityAccess in SOQL Where clause
        List<RecordType> activeRecordTypes = [
            SELECT SObjectType 
            FROM RecordType 
            WHERE IsActive = true
                AND SObjectType != 'Metric'
        ];

        Set<String> SObjectsWithRecordTypes = new Set<String>();

        for (RecordType recordType : activeRecordTypes){
            SObjectsWithRecordTypes.add(recordType.SObjectType);
        }


        return [
            SELECT MasterLabel, QualifiedApiName 
            FROM EntityDefinition
            WHERE QualifiedApiName IN :SObjectsWithRecordTypes
            ORDER BY MasterLabel ASC
        ];
    }
    */
    
    private static List<RecordType> recordTypesFromIds(Set<Id> ids) {
        return  [ 
            SELECT Id, Name, Description, DeveloperName, SobjectType 
            FROM RecordType
            WHERE Id IN :ids
        ];
    }

    /**
     * Here we take a list of RecordTypes from the result of the RecordType query
     * and transform it into a map of object names to each object name's list of Record Types
     * 
     * This map enables us to rebuild the list of results from the list of requests
     * that we're working with in the invocable method
     */
    private static Map<String,List<RecordType>> getMapOfObjectNameToRT(List<RecordType> recordTypes) {
        Map<String,List<RecordType>> resultMap = new Map<String,List<RecordType>>();
        for (RecordType rt : recordTypes) {
            if (resultMap.containsKey(rt.SobjectType)) {
                List<RecordType> rts = resultMap.get(rt.SObjectType);
                rts.add(rt);
                resultMap.put(rt.SobjectType,rts);
            } else {
                resultMap.put(rt.SobjectType, new List<RecordType>{rt});
            }
        }
        return resultMap;
    }

    /**
     *  Takes a list of object api names and returns a set of Ids containing 
     *  the active and available record types for those SObjects
     */
    private static Set<Id> availableRecordTypeIdsFromObjectApiNames(List<String> objectApiNames){
        Set<Id> resultRecordTypeIds = new Set<Id>();
        
        // this seems like not the best way to handle this, would love to revisit
        for (Schema.DescribeSObjectResult describeInfo : Schema.describeSObjects(objectApiNames)){
            for (Schema.RecordTypeInfo rtInfo : describeInfo.getRecordTypeInfos()){
                if (rtInfo.isActive() && rtInfo.isAvailable()) {
                    resultRecordTypeIds.add(rtInfo.getRecordTypeId());
                    }
                }
            }
        return resultRecordTypeIds;
    }
}