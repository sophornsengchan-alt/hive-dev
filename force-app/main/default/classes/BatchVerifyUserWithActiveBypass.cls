/*********************************************************************************************************************************
@ Class:          BatchVerifyUserAdminProfile
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0012474 - 9Elevated Admin Access - 3 Ensure Appropriate User Permissions and Profiles
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.06.2025 / Sovantheany Dim / Created the class.
@                 24.07.2025 / Sovantheany Dim / US-0033180 - Ignore Deployment user in bypass custom setting update 
********************************************************************************************************************************/
public with sharing class BatchVerifyUserWithActiveBypass implements Database.Batchable<SObject>, Schedulable{
    public static final String TICKET_RECORD_TYPE = 'Elevated_Access_Request';
    public static final String TICKET_TYPE_BYPASS= 'Enable Bypass';
    private Set<String> setStatus = new Set<String>{'Completed', 'Rejected', 'Closed'};
    private static Set<String> setIgnoreUserIds = new Set<String>(System.Label.Ignore_UserIds_To_Update_In_Bypass_Setting.split(';'));//US-0033180
    private String sQuery = 'SELECT Id,SetupOwnerId,triggerObjects__c,Bypass_Flow__c,byPass_Trigger__c,ByPass_Validation__c from byPass__c where SetupOwnerId NOT IN: setIgnoreUserIds AND SetupOwnerId != null and triggerObjects__c != null and (Bypass_Flow__c =true or byPass_Trigger__c = true or ByPass_Validation__c = true)';
    private String sTicketQuery = 'SELECT Id,Triggered_Objects__c,Flow__c,Trigger__c,Validation_Rule__c,Duration_In_Date_time__c,User__c FROM Ticket__c WHERE Triggered_Objects__c != null AND User__c IN: setUserIds AND RecordType.DeveloperName =: TICKET_RECORD_TYPE AND Type_of_Elevated_Access__c =: TICKET_TYPE_BYPASS AND Status__c !=: setStatus';
    private String userId;

    public BatchVerifyUserWithActiveBypass() {

    }
    // THIS CONSTRUCTOR IS USED FOR TESTING PURPOSES ONLY
    public BatchVerifyUserWithActiveBypass(String userId) {
        this.userId = userId;
        this.sQuery += ' AND SetupOwnerId =: userId';
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(sQuery);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<byPass__c> listBypass = (List<byPass__c>)scope;
        Map<String,byPass__c> mapByPass = new Map<String,byPass__c>();
        for(byPass__c b : listBypass){
            mapByPass.put(b.SetupOwnerId, b);
        }
        
        List<Ticket__c> listTickets = (List<Ticket__c>)ApexSafe.query().doQuery(sTicketQuery, new Map<String, Object>{'setUserIds' => mapByPass.keySet(), 'TICKET_RECORD_TYPE' => TICKET_RECORD_TYPE, 'TICKET_TYPE_BYPASS' => TICKET_TYPE_BYPASS, 'setStatus' => setStatus});
        List<Ticket__c> ticketsToUpdate = new List<Ticket__c>();
        for(Ticket__c t : listTickets){
            if (mapByPass.containsKey(t.User__c)) {
                byPass__c b = mapByPass.get(t.User__c);
                if(t.Triggered_Objects__c == b.triggerObjects__c && t.Flow__c == b.Bypass_Flow__c && t.Trigger__c == b.byPass_Trigger__c && t.Validation_Rule__c == b.ByPass_Validation__c && t.Duration_In_Date_time__c >= Datetime.now() ) {
                    // The user has an active bypass that matches the Custom Setting, so we do not update the Custom Setting.
                    mapByPass.remove(t.User__c);
                    continue;
                }
            }
            // If we reach here, it means the ticket does not have an active bypass that matches the Custom Setting.
            t.status__c = 'Completed';
            ticketsToUpdate.add(t);
        }
        if(!ticketsToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = ApexSafe.dml().doUpdate(ticketsToUpdate, false);
                List<Database.Error> dbError = new List<Database.Error>();
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess() && !Test.isRunningTest()) { dbError.addAll(result.getErrors()); }
                }
                if (!dbError.isEmpty()) { EBH_ApexLogger.logError(dbError, 'BatchVerifyUserWithActiveBypass','Updated Ticket'); }
    
            } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchVerifyUserWithActiveBypass','Updated Ticket'); }
            
        }
        if(!mapByPass.isEmpty()){
            List<byPass__c> bypassToUpdate = new List<byPass__c>();
            for(String userId : mapByPass.keySet()) {
                byPass__c b = mapByPass.get(userId);
                b.triggerObjects__c = null;
                b.Bypass_Flow__c = false;
                b.byPass_Trigger__c = false;
                b.ByPass_Validation__c = false;
                bypassToUpdate.add(b);
            }
            try {
                Database.SaveResult[] resultsBypass = ApexSafe.dml().doUpdate(bypassToUpdate, false);
                List<Database.Error> dbError = new List<Database.Error>();
                for (Database.SaveResult result : resultsBypass) {
                    if (!result.isSuccess() && !Test.isRunningTest()) { dbError.addAll(result.getErrors()); }
                }
                if (!dbError.isEmpty()) { EBH_ApexLogger.logError(dbError, 'BatchVerifyUserWithActiveBypass','Updated Bypass Custom Setting'); }
    
            } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchVerifyUserWithActiveBypass','Updated Bypass Custom Setting'); }
            
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    public void execute(SchedulableContext sc) {
        BatchVerifyUserWithActiveBypass batch = new BatchVerifyUserWithActiveBypass();
        Database.executeBatch(batch, 100);
    }
}