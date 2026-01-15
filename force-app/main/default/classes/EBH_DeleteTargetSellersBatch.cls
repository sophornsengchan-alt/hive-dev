/*********************************************************************************************************************************
@ Class:          EBH_DeleteTargetSellersBatch
@ Version:        1.0
@ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
@ Purpose:        Batch class to delete targeted seller
                  EPH-20 : Targeting Engine Filters
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the class.
*********************************************************************************************************************************/

global with sharing class EBH_DeleteTargetSellersBatch implements Database.Batchable<SObject>, Database.Stateful{
    
    global final EBH_Filter__c Filter {get;set;}
    global final String LocalAccountQuery {get;set;}
    global final String FilterId;

    // Acmatac SEING, 17/03/2022 US-0011204 - TECHDEBT: SOQL SOSL Injection - Prio 1
    // global final String targetedSellerQuery = EBH_ConstantsUtility.DTSBATCH_QUERYSTRING;
    global final static String targetedSellerQuery = 'SELECT id from EBH_TargetedSeller__c where EBH_SellerList__C = :FilterId';
    
    /*****************************************************************************************************************************
    @ Constructor:    EBH_DeleteTargetSellersBatch
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        Initialises the class for controller instance.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Seller List record, LocalAccQuery
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the constructor.
    *****************************************************************************************************************************/
    global EBH_DeleteTargetSellersBatch(EBH_Filter__c Filt, String LocalAccQuery){
        Filter = Filt;
        LocalAccountQuery = LocalAccQuery;
        FilterId = Filt.Id;
    }
    
    /*****************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator start method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(targetedSellerQuery);
    }
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator execute method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global void execute(Database.BatchableContext pBc, List<SObject> scope){
        try {
            Database.delete(scope);
        } catch(Exception ex) {
            //log error on exception to apex logger object
            EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                    EBH_ConstantsUtility.DTSBATCH_CLASSNAME, EBH_ConstantsUtility.DTSBATCH_CLASSMETHOD);
        } 
    }
    
    /*****************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator finish method, it calls the insert batch
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global void finish(Database.BatchableContext pBc){
        EBH_InsertTargetSellersBatch tSBatch = new EBH_InsertTargetSellersBatch (Filter, LocalAccountQuery);
        Database.executeBatch(tSBatch,200);
    }
}