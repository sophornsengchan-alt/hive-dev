/*********************************************************************************************************************************
@ Class:          BatchToUpdateExistingAction
@ Version:        1.0
@ Author:         Sreymeas Nao (sreymeas.nao@gaea-sys.com)
@ Purpose:        US-0008485: [LTTM] Actions to be displayed front page of the Cohort seller record and Customer 360 
				  to update Managed_Seller__c that are null to seller__c of bobSeller
@ Description:    Run only once after story get deployed
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.11.2020 / Sreymeas Nao  / Created the class.
*********************************************************************************************************************************/
global class BatchToUpdateExistingAction implements Database.Batchable<sObject> {
   
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
       
        String queryAction = 'SELECT Id,LTTM_Seller__c,LTTM_Seller__r.Seller__c ,Managed_Seller__c FROM Action__c WHERE Managed_Seller__c = null AND LTTM_Seller__r.Seller__c != null';
        return Database.getQueryLocator(queryAction);
    }
    
    global void execute(Database.BatchableContext BC, List<Action__c> lstActions) {
       
        // process each batch of records
        for(Action__c oneAct : lstActions){
            oneAct.Managed_Seller__c = oneAct.LTTM_Seller__r.Seller__c;
        }
        
        update lstActions;
       
    }   
    
    global void finish(Database.BatchableContext BC) {
    	// execute any post-processing operations
  }
}