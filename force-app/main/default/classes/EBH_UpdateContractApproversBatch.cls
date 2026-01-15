/*********************************************************************************************************************************
@ Class:          EBH_UpdateContractApproversBatch
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Batch class to insert targeted seller
                  EPH-51 : Targeting Engine Filters
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.07.2017 / NEHA LUND / Created the class.
*********************************************************************************************************************************/

global with sharing class EBH_UpdateContractApproversBatch implements Database.Batchable<SObject>, Database.Stateful{
    
   
   
    
    /*****************************************************************************************************************************
    @ Constructor:    EBH_UpdateContractApproversBatch
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Initialises the class for controller instance.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Seller List record, LocalAccQuery
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / NEHA LUND / Created the constructor.
    *****************************************************************************************************************************/
    global EBH_UpdateContractApproversBatch (){
        
       
    }
    
    /*****************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        QueryLocator start method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / NEHA LUND / Created the method.
    *****************************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(EBH_ConstantsUtility.SOQL_CONTRACTS);
    }
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        QueryLocator execute method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / NEHA LUND / Created the method.
    *****************************************************************************************************************************/
    global void execute(Database.BatchableContext pBc, List<Contract> scope){
        
        
        //try {
            Database.update(scope);
        /*} catch(Exception ex) {
            //log error on exception to apex logger object
            EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                    EBH_ConstantsUtility.ITSBATCH_CLASSNAME, EBH_ConstantsUtility.ITSBATCH_METHODEXECUTE);
        }*/
    }
    
    /*****************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        QueryLocator finish method, it sends an email notification to the seller list owner once the insert batch
                      is complete.  
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / NEHA LUND / Created the method.
    *****************************************************************************************************************************/
   global void finish(Database.BatchableContext pBc){
        
        EBH_ActiveTriggers__c tr = EBH_ActiveTriggers__c.getInstance(EBH_ConstantsUtility.TRIGGERCONTROLLER);
              tr.EBH_ExecuteContractUpdateBatch__c = false;
              update tr;
        
    }
}