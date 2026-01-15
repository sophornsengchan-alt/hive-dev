/*********************************************************************************************************************************
@ Class:          EBH_SellerListRefreshBatch
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Batch Class that retrieves all selet lests that needs to be refreshed today and updates the next refresh date
                  EPH-20, EPH-22 : Targeting Engine Filters, Targeting Engine Integration
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.06.2017 / JOY MONDOL / Created the batch class.
*********************************************************************************************************************************/
global without sharing class EBH_SellerListRefreshBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    private static final String sellerListQuery = EBH_ConstantsUtility.SLRBATCH_SELLERLISTQUERY;
    private static final String recordTypeQuery = EBH_ConstantsUtility.SLRBATCH_RECORDTYPEQUERY;
    
    private List<EBH_Filter__c> sellerLists = new List<EBH_Filter__c>();
     
    global Database.QueryLocator start(Database.BatchableContext BC) {        
        Id recTypeId = Database.query(recordTypeQuery)[0].Id;        
        return Database.getQueryLocator(sellerListQuery);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {        
        for(EBH_Filter__c sellerList : (List<EBH_Filter__c>)scope) {
            sellerList.EBH_NextRefreshDate__c = System.today().addDays(Integer.valueOf(sellerList.EBH_RefreshFrequence__c));
            sellerLists.add(sellerList); 
        }
        try {
            Database.update(sellerLists);
        } catch(Exception ex) {
            //log error on exception to apex logger object
            EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                    EBH_ConstantsUtility.SLRBATCH_CLASSNAME, EBH_ConstantsUtility.SLRBATCH_METHOD);
        }
    }

    global void execute(SchedulableContext sc) {     
        EBH_SellerListRefreshBatch b = new EBH_SellerListRefreshBatch();
        Database.executeBatch(b);
    }
    
    global void finish(Database.BatchableContext BC) { 
        for(EBH_Filter__c sellerList : sellerLists) {
            if( sellerList.EBH_Filter__c != null)
            EBH_TargetingCockpitController2.generateTargetedSellers(
                sellerList.Id, sellerList.EBH_Filter__c.split(' LIMIT ')[0]
                    .replace(' COUNT() ', ' Id '));             
        }
    }
}