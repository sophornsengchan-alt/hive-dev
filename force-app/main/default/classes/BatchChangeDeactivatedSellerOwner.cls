/*********************************************************************************************************************************
@ Class:          BatchChangeDeactivatedSellerOwner
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        US-0015242 - Fix Account Owner Updating to Integration User Issue
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  13.05.2024 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
global inherited sharing class BatchChangeDeactivatedSellerOwner implements Database.Batchable<SObject>,Schedulable{

    private final String CLASS_NAME = 'BatchChangeDeactivatedSellerOwner';

	private final String DEACTIVATION_USER_ID = String.valueOf(Label.Cohort_Deactivation_UserId);
    private final String INTEGRATION_USER_ID = ApexUtil.INTEGRATION_USER_ID;

    private final String SOQL_ACC = 'Select Id From Account Where OwnerId =: DEACTIVATION_USER_ID';
    private final String COND_COHORT_SELLER = ' AND Id IN (Select Seller__c From BoB_Seller__c Where BoB__c IN: setCohortId)';

    private Set<String> setCohortId;
    private String finalSOQL;

    /*********************************************************************************************************************************
    @ Method:         BatchChangeDeactivatedSellerOwner
    @ Author:         Sophal Noch
    @ Purpose:        US-0015242 - Fix Account Owner Updating to Integration User Issue
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  13.05.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public BatchChangeDeactivatedSellerOwner() {
        this.finalSOQL = SOQL_ACC;
    }

    /*********************************************************************************************************************************
    @ Method:         BatchChangeDeactivatedSellerOwner
    @ Author:         Sophal Noch
    @ Purpose:        US-0015242 - Fix Account Owner Updating to Integration User Issue
    @ Param:          Set<String> setCohortId : use to filter the Account that are related to the Cohort when batch run manually in dev console
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  13.05.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public BatchChangeDeactivatedSellerOwner(Set<String> setCohortId) {
        this.setCohortId = setCohortId;
        this.finalSOQL = SOQL_ACC + COND_COHORT_SELLER;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(finalSOQL);
    }

    /*********************************************************************************************************************************
    @ Method:         BatchChangeDeactivatedSellerOwner
    @ Author:         Sophal Noch
    @ Purpose:        US-0015242 - Fix Account Owner Updating to Integration User Issue
    @ Param:          Database.BatchableContext bc : batch context, List<SObject> scope : list of account owned by deactivation user id
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  13.05.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    global void execute(Database.BatchableContext bc, List<SObject> scope){
        
        List<Account> lstAccToUpdate = new List<Account>();
        for(Account acc : (List<Account>)scope){
            acc.OwnerId = INTEGRATION_USER_ID; // update all account that has owner as deactivation user id to integration user
            lstAccToUpdate.add(acc);
        }

        List<Database.SaveResult> listResult = ApexSafe.dml().secCheck(false).doUpdate(lstAccToUpdate, false); //  update the account partailly if there is error in dml
        List<Database.Error> listError = new List<Database.Error>();
        for(Database.SaveResult result : listResult){
            if(!result.isSuccess()){
                listError.addAll(result.getErrors());
            }
        }
        if(!listError.isEmpty()){
            EBH_ApexLogger.logError(listError, CLASS_NAME, 'execute');
        }
    }

    global void finish(Database.BatchableContext bc){
    }

    /*********************************************************************************************************************************
    @ Method:         execute
    @ Author:         Sophal Noch
    @ Purpose:        US-0015242 - Fix Account Owner Updating to Integration User Issue
    @ Param:          SchedulableContext sc : schedule job context
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  13.05.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    global void execute(SchedulableContext sc) { // make it available to be scheduled
        Database.executeBatch(new BatchChangeDeactivatedSellerOwner());
    } 

}