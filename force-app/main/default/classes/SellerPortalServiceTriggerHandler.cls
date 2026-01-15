/*********************************************************************************************************************************
@ Class:          SellerPortalServiceTriggerHandler
@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        US-0014263 - Store log of unsuccessful logins for sellers portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.12.2023 / Sambath Seng / Create class
*********************************************************************************************************************************/
public with sharing class SellerPortalServiceTriggerHandler {

    /*****************************************************************************************************************************
    @ Method:         handleCreateServiceRecord
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0014263 - Store log of unsuccessful logins for sellers portal
    @ Event :         after insert
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<ServiceEvent__e> events
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.12.2023 / Sambath Seng / Create method
    *********************************************************************************************************************************/
    public static void handleCreateLog(List<Seller_Portal_Service__c> serviceList) {
        List<SObject> listInsert = new List<SObject>();
        for (Seller_Portal_Service__c oService : serviceList) {
            Map<String, Object> jsonData = extractJson(oService.Json_Data__c);
            if(jsonData != null && jsonData.get('action') == 'create'){
                listInsert.add(buildRecordFromJson(jsonData));
            }
        }

        if(!listInsert.isEmpty()){
            insert listInsert;
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         buildRecordFromJson
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0014263 - Store log of unsuccessful logins for sellers portal
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Map<String, Object> jsonData
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.12.2023 / Sambath Seng / Create method
    *********************************************************************************************************************************/
    private static SObject buildRecordFromJson(Map<String, Object> jsonData){

        Map<String, Object> targetData = (Map<String, Object>) jsonData.get('targetData');
        String targetDataJson = JSON.serialize(targetData);

        String targetObject = (String) jsonData.get('targetObject');
        Type targetType = Type.forName(targetObject);
        
        SObject record = (SObject) JSON.deserialize(targetDataJson, targetType);

        return record;
    }

    private static Map<String,Object> extractJson (String jsonData){
        Map<String,Object> result = new Map<String,Object>();
        if(String.isBlank(jsonData)){
            return null;
        }
        try {
            result = (Map<String,Object>) JSON.deserializeUntyped(jsonData);
        } catch (Exception ex) {
            System.debug('error :: '+ex.getMessage());
            return null;
        }

        return result;
    }
}