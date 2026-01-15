/*********************************************************************************************************************************
@ Class:        BatchDeactivateBobSeller
@ Version:      1.0
@ Author:       Bora Chhorn (bora.chhorn@gaea-sys.com)
@ Purpose:      US-0012616 - Automation to change Cohort Seller Status to Inactive when Cohort Status is changed to "Inactive"
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.05.2024 / Sophal Noch / US-0015242 - Fix Account Owner Updating to Integration User Issu
*********************************************************************************************************************************/

global with sharing class BatchDeactivateBobSeller implements Database.Batchable<SObject> {

    private final static string BOB_INACTIVE_STATUS='BoB Inactive';
    private final static String BOBSELLER_INACTIVE_STATUS = 'Inactive';
    private static String BOBSELLER_LTTM_RECORDTYPE = 'LTTM';
    Set<ID> bobIds;
    Id bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c',BOBSELLER_LTTM_RECORDTYPE).Id;
    String soqlBobSeller = 'SELECT RecordTypeId, BoB__c, Status__c, BoB__r.Status__c, Deactivation_Reason__c FROM BoB_Seller__c ';
    String sWhere = 'WHERE BoB__r.Status__c =:BOB_INACTIVE_STATUS AND Status__c !=: BOBSELLER_INACTIVE_STATUS AND RecordTypeId =:bobSellerRecordTypeLTTM';
    
	// for testing
    public BatchDeactivateBobSeller(set<Id> bobIds)
    {
    	this.bobIds = bobIds;
        sWhere += ' AND BoB__c IN: bobIds';
    }

    public BatchDeactivateBobSeller()
    {
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(soqlBobSeller+sWhere);
    }

    global void execute(Database.BatchableContext pBc, List<BoB_Seller__c> scope){
        
        List<BoB_Seller__c> listBobSeller = new List<BoB_Seller__c>();
        
        for (BoB_Seller__c bs : scope){
            bs.Status__c = BOBSELLER_INACTIVE_STATUS;
            bs.Deactivation_Reason__c = 'Cohort Inactivated';
            listBobSeller.add(bs);
		}

        if (!listBobSeller.isEmpty()) {
            
            Database.SaveResult[] results = Database.update(listBobSeller,false);
            List<Database.Error> dbError = new List<Database.Error>();

            for (Database.SaveResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()){ dbError.addAll(result.getErrors()); }
            }

            if (!dbError.isEmpty()) EBH_ApexLogger.logError(dbError, 'BatchDeactivateBobSeller','execute (batch)');
        }

    }

    global void finish(Database.BatchableContext pBc){
        Database.executeBatch(new BatchChangeDeactivatedSellerOwner()); // 13.05.2024 / Sophal Noch / US-0015242
    }
}