/*********************************************************************************************************************************
@ Class:          SEPServiceEventTriggerHandler
@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        US-0014263 - Store log of unsuccessful logins for sellers portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.12.2023 / Sambath Seng / Create class
*********************************************************************************************************************************/
public with sharing class SEPServiceEventTriggerHandler {

    /*****************************************************************************************************************************
    @ Method:         handleCreateLog
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0014263 - Store log of unsuccessful logins for sellers portal
    @ Event :         after insert
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<ServiceEvent__e> events
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.12.2023 / Sambath Seng / Create method
    *********************************************************************************************************************************/
    public static void handleCreateLog(List<SellerPortalServiceEvent__e> serviceList) {
        List<Seller_Portal_Service__c> recordsToInsert = new List<Seller_Portal_Service__c>();
        for (SellerPortalServiceEvent__e oService : serviceList) {
            if (oService != null) {
                Seller_Portal_Service__c record = new Seller_Portal_Service__c();
                record.Json_Data__c = oService.Json_Data__c;
                recordsToInsert.add(record);
            }
        }

        if(!recordsToInsert.isEmpty()){
            insert recordsToInsert;
        }
    }
}