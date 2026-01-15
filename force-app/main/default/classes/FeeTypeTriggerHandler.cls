/*********************************************************************************************************************************
@ Class:          FeeTypeTriggerHandler
@ Version:        1.0
@ Author:         GitHub Copilot 
@ Purpose:        Handler Class for FeeType Trigger
                  US-0033985: Timezone offset calculations for FeeType records
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.12.2025 / GitHub Copilot / Created the class for timezone offset population
*********************************************************************************************************************************/

public without sharing class FeeTypeTriggerHandler {
    
    /*****************************************************************************************************************************
    @ Method:         populateTimezoneOffsets
    @ Version:        1.0
    @ Author:         GitHub Copilot
    @ Purpose:        US-0033985: Populate Start Date Offset and End Date Offset fields based on PrimarySite__c using timezone names to handle DST
                      Uses Contract StartDate and EndDate through RelatedContract__c relationship, only triggers on site changes
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2025 / GitHub Copilot / Method Creation - Updated to use timezone names and handle DST
    *****************************************************************************************************************************/
    public static void populateTimezoneOffsets(List<FeeType__c> newFeeTypes, Map<Id, FeeType__c> oldMap) {
        // Collect Contract IDs for records that need timezone offset updates
        Set<Id> contractIdsToQuery = new Set<Id>();
        Map<Id, FeeType__c> feeTypesToUpdate = new Map<Id, FeeType__c>();
        
        for (FeeType__c feeType : newFeeTypes) {
            FeeType__c oldFeeType = oldMap?.get(feeType.Id);
            
            // Only trigger on site changes (insert or site field change) or when offset fields are null
            if (feeType.PrimarySite__c != null && 
                (oldFeeType == null || 
                 feeType.PrimarySite__c != oldFeeType.PrimarySite__c ||
                 feeType.StartDateOffset__c == null ||
                 feeType.EndDateOffset__c == null)) {
                
                if (feeType.RelatedContract__c != null) {
                    contractIdsToQuery.add(feeType.RelatedContract__c);
                    feeTypesToUpdate.put(feeType.Id, feeType);
                }
            }
        }
        
        // Query Contract records to get StartDate and EndDate
        if (!contractIdsToQuery.isEmpty()) {
            String contractQuery = 'SELECT Id, StartDate, EndDate FROM Contract WHERE Id IN :contractIdsToQuery';
            List<Contract> contractList = ApexSafe.query().secCheck(false).doQuery(contractQuery, new Map<String, Object> {'contractIdsToQuery' => contractIdsToQuery});
            Map<Id, Contract> contractMap = new Map<Id, Contract>(contractList);
            
            // Update offset fields using Contract dates
            for (FeeType__c feeType : feeTypesToUpdate.values()) {
                Contract relatedContract = contractMap.get(feeType.RelatedContract__c);
                
                if (relatedContract != null) {
                    // Check and populate Start Date Offset using Contract StartDate
                    if (relatedContract.StartDate != null) {
                        feeType.StartDateOffset__c = ApexUtil.getDateTimezoneOffsetForSite(relatedContract.StartDate, feeType.PrimarySite__c);
                    }
                    
                    // Check and populate End Date Offset using Contract EndDate
                    if (relatedContract.EndDate != null) {
                        feeType.EndDateOffset__c = ApexUtil.getDateTimezoneOffsetForSite(relatedContract.EndDate, feeType.PrimarySite__c);
                    }
                }
            }
        }
    }
    
}