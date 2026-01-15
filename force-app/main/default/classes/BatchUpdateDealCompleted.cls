/*********************************************************************************************************************************
@ Class:         BatchUpdateDealCompleted
@ Version:       1.0
@ Author:        Vimean Heng (vimean.heng@gaea-sys.com)
@ Purpose:       US-0033060 - The Deals needs to be marked Completed past the Deal End Date
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.06.2025 / Vimean Heng / US-0033060 - The Deals needs to be marked Completed past the Deal End Date
----------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class BatchUpdateDealCompleted implements Database.Batchable<SObject>, Schedulable, Database.Stateful{
    private Map<String,String> mapRecordTypeToStatus = new Map<String,String>{
        'Deal_V1' => 'Executed',
        'Deal_V2' => 'Completed',
        'Deal_V3' => 'Completed'
    };
    Set<String> recordTypes = mapRecordTypeToStatus.keySet();
    private String statusRunning = 'Running';
    private String sDealQuery = 'select id,EBH_Status__c,RecordType.DeveloperName from EBH_Deal__c where RecordType.DeveloperName IN :recordTypes and EBH_Status__c =: statusRunning and EBH_DealEndDate__c < TODAY';
    public BatchUpdateDealCompleted() {}
    
    public BatchUpdateDealCompleted(Set<String> setIds) {
        sDealQuery += ' and id in :setIds';
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(sDealQuery);
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope){
        updateDealStatus(scope);
    }
    public void finish(Database.BatchableContext bc){
        
    }

    public void execute(SchedulableContext sc) { 
        BatchUpdateDealCompleted b = new BatchUpdateDealCompleted();
        Database.executeBatch(b, 100);
    }

    /*********************************************************************************************************************************
    @ Method:         updateDealStatus
    @ Version:        1.0
    @ Author:         Vimean Heng (vimean.heng@gaea-sys.com)
    @ Purpose:        US-0033060 - The Deals needs to be marked Completed past the Deal End Date
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  26.06.2025 / Vimean Heng / Created the method.
    *********************************************************************************************************************************/
    private void updateDealStatus(List<EBH_Deal__c> scope){
        List<EBH_Deal__c> lstDeal2Update = new List<EBH_Deal__c>();

        for (EBH_Deal__c deal : scope) {
            deal.EBH_Status__c = mapRecordTypeToStatus.get(deal.RecordType.DeveloperName);
            lstDeal2Update.add(deal);
        }
        try {
            Database.SaveResult[] results = ApexSafe.dml().doUpdate(lstDeal2Update, false);
            List<Database.Error> dbError = new List<Database.Error>();
            for (Database.SaveResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()) { dbError.addAll(result.getErrors()); }
            }
            if (!dbError.isEmpty()) { EBH_ApexLogger.logError(dbError, 'BatchUpdateDealCompleted','updateDealStatus'); }
        } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchUpdateDealCompleted','updateDealStatus'); }
    }
}