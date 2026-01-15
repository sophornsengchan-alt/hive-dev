/*********************************************************************************************************************************
@ Class:         BatchUpdateDealStatus
@ Version:       1.0
@ Author:        Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       US-0016569 - Auto cancel deals with deal start date in the past
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.03.2025 / Sovantheany Dim / Created the class.
@                 20.04.2025 / Sovantheany Dim / US-0017103 - Auto Cancel DCA if there no active related Deals
@                 08.05.2025 / Vimean Heng / US-0017164 - Launch - Deal Site filter should be applied for Auto Cancellation of Sub Deals when not signed past Deal Start Date
@                 01.07.2025 / Vimean Heng / US-0033105 - Exclude auto cancellation of Amended deals
----------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class BatchUpdateDealStatus implements Database.Batchable<SObject>, Schedulable, Database.Stateful{
    private Set<String> setDCAlIds = new Set<String>(); //US-0017103 : to store the DCA Ids
    private Set<String> setInactiveStatus = new Set<String>{'Cancelled','Rejected','Internally Rejected','Seller Rejected'}; // US-0017103 : to store the inactive status
    private final static string STATUS_SENT_TO_SELLER = 'Sent to Seller';
    private final static string STATUS_CANCELLED = 'Cancelled';
    private final static string DEAL_V2 = 'Deal_V2';
    private final static string DEAL_US_SITE = '0';
    private final static string AMENDED_YES = 'Yes';
    private String sDealQuery = 'select id,EBH_Status__c,Cancellation_Reason__c, Deal_Contract_Agreement__c,Deal_Contract_Agreement__r.Amended__c from EBH_Deal__c where RecordType.DeveloperName =: DEAL_V2 and EBH_Status__c =: STATUS_SENT_TO_SELLER and EBH_DealStartDate__c < TODAY and EBH_DealSiteId__c =: DEAL_US_SITE and Deal_Contract_Agreement__r.Amended__c !=: AMENDED_YES';
    private String sDCAquery = 'select id, Status__c, (select id from Deals__r where EBH_Status__c NOT IN: setInactiveStatus limit 1) from Deal_Contract_Agreement__c where id in :setDCAlIds';
    private Set<String> setIds = new Set<String>();
    private final static String OBJ_DEAL = 'Deal';
    private final static String OBJ_DCA = 'DCA';
    private String objToRun;
    
    public BatchUpdateDealStatus() {
        this.objToRun = OBJ_DEAL;
    }

    // THIS CONSTRUCTOR IS USED FOR TESTING PURPOSES ONLY
    public BatchUpdateDealStatus(Set<String> setIds) {
        this.objToRun = OBJ_DEAL;
        this.setIds = setIds;
        sDealQuery += ' and Deal_Contract_Agreement__c in :setIds';
    }

    // This constuctor is used When finish method is called to run the next batch for DCA
    public BatchUpdateDealStatus(String objToRun, Set<String> setDCAlIds) {
        this.objToRun = objToRun;
        this.setDCAlIds = setDCAlIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        String sQuery = objToRun == OBJ_DEAL ? sDealQuery : sDCAquery;
        return Database.getQueryLocator(sQuery);
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope){
        if(objToRun == OBJ_DEAL){
            updateDealStatus(scope);
        }else {
            updateDCAStatus(scope);
        }
    }
    public void finish(Database.BatchableContext bc){
        if(this.objToRun == OBJ_DEAL && !setDCAlIds.isEmpty()){
            BatchUpdateDealStatus b = new BatchUpdateDealStatus(OBJ_DCA, setDCAlIds);
            Database.executeBatch(b);
        }
    }

    /*********************************************************************************************************************************
    @ Method:         updateDealStatus
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0016569 - Auto cancel deals with deal start date in the past
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.04.2025 / Sovantheany Dim / Created the method.
    *********************************************************************************************************************************/
    private void updateDealStatus(List<EBH_Deal__c> scope){
        List<EBH_Deal__c> lstDeal2Update = new List<EBH_Deal__c>();

        for (EBH_Deal__c deal : scope) {
            deal.EBH_Status__c = STATUS_CANCELLED;
            deal.Cancellation_Reason__c = 'Did not sign on time';
            lstDeal2Update.add(deal);
            setDCAlIds.add(deal.Deal_Contract_Agreement__c);
        }
        try {
            Database.SaveResult[] results = ApexSafe.dml().doUpdate(lstDeal2Update, false);
            List<Database.Error> dbError = new List<Database.Error>();
            for (Database.SaveResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()) { dbError.addAll(result.getErrors()); }
            }
            if (!dbError.isEmpty()) { EBH_ApexLogger.logError(dbError, 'BatchUpdateDealStatus','execute (batch)'); }
        } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchUpdateDealStatus','execute (batch)'); }
    }

    /*********************************************************************************************************************************
    @ Method:         updateDCAStatus
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0017103 - Cacelled DCA if there is no Active Deals within the DCA
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  20.04.2025 / Sovantheany Dim / Created the method.
    *********************************************************************************************************************************/
    private void updateDCAStatus(List<Deal_Contract_Agreement__c> scope){
        
        List<Deal_Contract_Agreement__c> lstDCA2Update = new List<Deal_Contract_Agreement__c>();
        //List<Deal_Contract_Agreement__c> lstDCA = ApexSafe.query().doQuery(sDCAquery,new Map<String, Object> {'setInactiveStatus' => setInactiveStatus, 'setDCAlIds' => setDCAlIds});
        
        for(Deal_Contract_Agreement__c dca : scope){
            //if there is no active deals within the DCA, then update the DCA status to cancelled
            if(dca.Deals__r.size() == 0){
                dca.Status__c = STATUS_CANCELLED;
                dca.Cancellation_Reason__c = 'Did not sign on time (or Missed deadline)';
                lstDCA2Update.add(dca);
            }
        }
        try {
            Database.SaveResult[] results = ApexSafe.dml().doUpdate(lstDCA2Update, false);
            List<Database.Error> dbError = new List<Database.Error>();
            for (Database.SaveResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()) { dbError.addAll(result.getErrors()); }
            }
            if (!dbError.isEmpty()) { EBH_ApexLogger.logError(dbError, 'BatchUpdateDealStatus','updateDCAStatus'); }
        } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchUpdateDealStatus','updateDCAStatus'); }
    }

    public void execute(SchedulableContext sc){
        BatchUpdateDealStatus b = new BatchUpdateDealStatus();
        Database.executeBatch(b, 100);
    }
}