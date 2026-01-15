/*********************************************************************************************************************************
@ Class:        BatchCancelTaskOnCampaignMember
@ Version:      1.0
@ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:      Expected;
@               When Marketing Cloud Journey updates Campaign Member.Marketing_Cloud_Status__c = "Cancelled"
@               If Campaign Member record has Marketing Cloud Status = "Cancelled"
@               Trigger currently updates CampaignMember.EBH_Responsecode__c = 22, then related task** should be deleted.
@               Issue is believed to relate to large volume of tasks being deleted via Trigger causing failures.
@               Proposed solutions: Move from Trigger to nightly batch job for Campaign Member update & related task deletions
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.April.2021 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class. Move from Trigger EBH_CampaignMemberTriggerHandler
*********************************************************************************************************************************/
global without sharing class Batch_CancelTaskOnCampaignMember implements Database.Batchable<SObject>, Schedulable,Database.Stateful{
    private static String status_mc_cancelled = EBH_ConstantsUtility.CM_MC_STATUS_CANCELLED;
    private static String SOQL_CAMPAIGNMEMBER = 'SELECT CampaignId, ContactId FROM CampaignMember where Marketing_Cloud_Status__c =: status_mc_cancelled AND EBH_Results__c=: status_mc_cancelled';
    private static String SOQL_TASK = EBH_ConstantsUtility.SOQL_TASK + EBH_CampaignMemberTriggerHandler.WHERE_TASK + ' AND EBH_ResponseCode__c != null AND (EBH_ResponseCode__c = 10 OR EBH_ResponseCode__c = 40)';

    global Database.querylocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(SOQL_CAMPAIGNMEMBER);
    }
    global void execute(Database.BatchableContext bc, List<CampaignMember> scope) {
        Map<String,CampaignMember> mapCMUpdated = new Map<String,CampaignMember>();
        Set<String> setCampIds = new Set<String>();
        Set<String> setContIds = new Set<String>();
        for(CampaignMember cm : scope){
            mapCMUpdated.put(cm.Id,cm);
            setCampIds.add(cm.CampaignId);
            setContIds.add(cm.ContactId);
        }
        if(mapCMUpdated.isEmpty()) return;
        Set<String> setCMIds = mapCMUpdated.keySet();
        List<Task> lstTaskToDeleted = Database.query(SOQL_TASK);
        if(!lstTaskToDeleted.isEmpty()) delete lstTaskToDeleted;

    }
    global void finish(Database.BatchableContext bc) {
    }
    
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new Batch_CancelTaskOnCampaignMember());
    }
}