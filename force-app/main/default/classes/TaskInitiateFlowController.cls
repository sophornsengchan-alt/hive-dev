/*********************************************************************************************************************************
@ Class:          TaskInitiateFlowController
@ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:        US-0008991 - [AU GCX] Initiate Epilogue Flow from Task record Page
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  2.Feb.2021 / Acmatac SEING / Created Class & queryTasks Method.
*********************************************************************************************************************************/
public without sharing class TaskInitiateFlowController {
    @AuraEnabled
    public static Task queryTasks(String recordId){
        try {
            return [SELECT Id, EBH_ResponseCode__c FROM Task WHERE Id =: recordId AND Related_Campaign__r.EBH_Site__c = 'AU'];

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}