/*********************************************************************************************************************************
@ Class:          BatchSyncPMDealFieldsToChild
@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        US-0013982 - PM Deal Items to reflect changes made on record
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.09.2022 / Sambath Seng / Create class
*********************************************************************************************************************************/
public with sharing class BatchSyncPMDealFieldsToChild implements Database.Batchable<SObject> {
    private Set<Id> dcaIds;
    private final static String query = 'SELECT Id,EBH_DealStartDate__c,EBH_DealStartTime__c,EBH_DealEndDate__c,EBH_DealEndTime__c,EBH_Category__c,Deal_Contract_Agreement__r.Deal_Start_Date__c,Deal_Contract_Agreement__r.Deal_Start_Time__c,Deal_Contract_Agreement__r.Deal_End_Date__c,Deal_Contract_Agreement__r.Deal_End_Time__c,Deal_Contract_Agreement__r.Category__c,dcaSyncStartDate__c,dcaSyncStartTime__c,dcaSyncEndDate__c,dcaSyncEndTime__c ,dcaSyncCategory__c FROM EBH_Deal__c WHERE Deal_Contract_Agreement__c IN :dcaIds AND (dcaSyncStartDate__c = false OR dcaSyncStartTime__c = false OR dcaSyncEndDate__c = false OR dcaSyncEndTime__c = false OR dcaSyncCategory__c = false)';
    
    public BatchSyncPMDealFieldsToChild(Set<Id> dcaIds) {
        this.dcaIds = dcaIds;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<EBH_Deal__c> scope) {

        List<EBH_Deal__c> lstDealsToUpdate = new List<EBH_Deal__c>();

        for(EBH_Deal__c oDeal : scope){
            Deal_Contract_Agreement__c dca = (Deal_Contract_Agreement__c) oDeal.getSobject('Deal_Contract_Agreement__r');
            lstDealsToUpdate.add(assignValues(dca, oDeal));
        }

        Database.SaveResult[] saveResult = Database.update(lstDealsToUpdate, false);
        List<Database.Error> dbError = new List<Database.Error>();

        for (Database.SaveResult result : saveResult) {
            if (!result.isSuccess() && !Test.isRunningTest()){ 
                dbError.addAll(result.getErrors()); 
            }
        }

        if (!dbError.isEmpty()) EBH_ApexLogger.logError(dbError, 'BatchSyncPMDealFieldsToChild','execute (batch)');
    }

    public void finish(Database.BatchableContext context) {
    }

    /*****************************************************************************************************************************
    @ Method:   assignValues
    @ Version:  1.0
    @ Author: 	Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:	US-0013982 - PM Deal Items to reflect changes made on record
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: Deal_Contract_Agreement__c dca, EBH_Deal__c deal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.09.2023 / Sambath Seng / Create method
    *****************************************************************************************************************************/
    public static EBH_Deal__c assignValues(Deal_Contract_Agreement__c dca, EBH_Deal__c deal){
        if(!deal.dcaSyncStartDate__c){
            deal.EBH_DealStartDate__c = dca.Deal_Start_Date__c;
        }
        if(!deal.dcaSyncStartTime__c){
            deal.EBH_DealStartTime__c = dca.Deal_Start_Time__c;
        }
        if(!deal.dcaSyncEndDate__c){
            deal.EBH_DealEndDate__c = dca.Deal_End_Date__c;
        }
        if(!deal.dcaSyncEndTime__c){
            deal.EBH_DealEndTime__c = dca.Deal_End_Time__c;
        }
        if(!deal.dcaSyncCategory__c){
            deal.EBH_Category__c = dca.Category__c;
        }

        return deal;
    }
}