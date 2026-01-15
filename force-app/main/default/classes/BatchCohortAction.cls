/*********************************************************************************************************************************
@ Class:          BatchCohortAction
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        US-0014361 - Cohort Activation Process Part 2
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  09.11.2023 / Sophal Noch / Created the class.
                :  15.11.2023 / Sophal Noch / US-0014353 - Cohort Deactivation Process
                :  30.11.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
                :  01.12.2023 / Sophal Noch / US-0014363 - Ph 1 - Deactivate Sellers button
                :  01.12.2023 / Sophal Noch / US-0014172 - ADS - Cohort Seller field synch
                :  30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
----------------------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************************/
global class BatchCohortAction implements Database.Batchable<SObject>, Database.Stateful{

    public static Boolean isRunning = false;
    private String className = 'BatchCohortAction';

    public static final String ACTION_ACTIVATE_COHORT_SELLER = 'Action_Activate_BoB_Seller';
    public static final String ACTION_DEACTIVATE_COHORT_SELLER = 'Action_Deactivate_BoB_Seller'; // 15.11.2023 / Sophal Noch / US-0014353
    public static final String ACTION_ACTIVATE_SELECTED_COHORT_SELLER = 'Action_Activate_Selected_BoB_Seller'; // 30.11.2023 / Sophal Noch / US-0014362
    public static final String ACTION_DEACTIVATE_SELECTED_COHORT_SELLER = 'Action_Deactivate_Selected_BoB_Seller'; // 01.12.2023 / Sophal Noch / US-0014363
    public static final String ACTION_SYNC_COHORT_SELLER = 'Action_Sync_BoB_Seller';
    public static final String ACTION_UNSYNC_COHORT_SELLER = 'Action_UnSync_BoB_Seller';
    public static final String ACTION_USYNC_ACC = 'Action_Unsync_Account';
    public static final String ACTION_FINISH = 'Action_Finish';


    // 30.01.2024 / Sophal Noch / US-0014277 : move each batch execution to seperate class, store in map MAP_ACTION_TYPE_TO_EXECUTION
    private Map<String, ICohortAction> MAP_ACTION_TYPE_TO_EXECUTION = new Map<String, ICohortAction>{
        (ACTION_ACTIVATE_COHORT_SELLER + '_0') => new BatchCohortActionExecution.CohortSellerActivation(),
        (ACTION_ACTIVATE_COHORT_SELLER + '_1') => new BatchCohortActionExecution.CSActivationEmailSend(),
    
        (ACTION_DEACTIVATE_COHORT_SELLER + '_0') => new BatchCohortActionExecution.CohortSellerDeactivation(),
        (ACTION_DEACTIVATE_COHORT_SELLER + '_1') => new BatchCohortActionExecution.CohortDeactivation(),
        (ACTION_DEACTIVATE_COHORT_SELLER + '_2') => new BatchCohortActionExecution.CSDectivationEmailSend(),
    
        (ACTION_ACTIVATE_SELECTED_COHORT_SELLER + '_0') => new BatchCohortActionExecution.SelectedCohortSellerActivation(),
        (ACTION_ACTIVATE_SELECTED_COHORT_SELLER + '_1') => new BatchCohortActionExecution.CSActivationEmailSend(),
    
        (ACTION_DEACTIVATE_SELECTED_COHORT_SELLER + '_0') => new BatchCohortActionExecution.SelectedCohortSellerDectivation(),
        (ACTION_DEACTIVATE_SELECTED_COHORT_SELLER + '_1') => new BatchCohortActionExecution.CSDectivationEmailSend(),

        ACTION_SYNC_COHORT_SELLER => new BatchCohortActionExecution.SelectedCohortSellerActivation(),

        ACTION_UNSYNC_COHORT_SELLER => new BatchCohortActionExecution.SelectedCohortSellerDectivation(),

        ACTION_USYNC_ACC => new BatchCohortActionExecution.AccountUnsync()
    };

    private String action;
    private Integer soqlIndex = null;
    private Set<String> setSobjIds = new Set<String>();
    private Set<String> setNextSobjIds;
    private ICohortAction execution;


    /*********************************************************************************************************************************
    @ Method:         BatchCohortAction
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0014361 - Cohort Activation Process Part 2
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.11.2023 / Sophal Noch / Created the method.
                    :  11.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
                    :  30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
    *********************************************************************************************************************************/
    public BatchCohortAction(String action, Integer soqlIndex, Set<String> setSobjIds){

        this.action = action;
        this.soqlIndex = soqlIndex;
        this.setSobjIds = setSobjIds;

        // 30.01.2024 / Sophal Noch / US-0014277 : change from call method to call class that extend AbstractBatchCohortAction
        ICohortAction execution = this.MAP_ACTION_TYPE_TO_EXECUTION.get(this.getActionNameIndex()); // 11.12.2023 / Sophal Noch / US-0014362

        if(execution == null){
            return;
        }
        execution.setAction(this.action).setSoqlIndex(this.soqlIndex).setSetSobjIds(this.setSobjIds).setClassName(this.className);
        this.execution = execution;

        this.execution.publishInitEvent(); // 11.12.2023 / Sophal Noch / US-0014362 : publish init event when batch start
        this.execution.publishSuccessEvent(); // publish platform event so lwc that subscribe to the event display the progress

    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        // 30.01.2024 / Sophal Noch / US-0014277 : change from call method to call class that extend AbstractBatchCohortAction
        return this.execution.startBatch();
    }


    /*********************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014361 - Cohort Activation Process Part 2
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.11.2023 / Sophal Noch / Created the method.
                    :  30.11.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
                    :  30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
    *********************************************************************************************************************************/
    global void execute(Database.BatchableContext bc, List<SObject> scope){

        isRunning = true;
        try {
            // 30.01.2024 / Sophal Noch / US-0014277 : change from call method to call class that extend AbstractBatchCohortAction
            this.execution.publishInitEvent(); // 11.12.2023 / Sophal Noch / US-0014362
            this.execution.publishSuccessEvent();

            this.execution.execute(scope);
            if(this.execution.getNextSobjIds() != null){
                this.setNextSobjIds = this.setNextSobjIds != null ? this.setNextSobjIds : new Set<String>();
                this.setNextSobjIds.addAll(this.execution.getNextSobjIds());
            }
        } catch (Exception e) {
            this.execution.publishErrorEvent(e);
        }



    }

    /*********************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014361 - Cohort Activation Process Part 2
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.11.2023 / Sophal Noch / Created the method.
                    :  30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
    *********************************************************************************************************************************/
    global void finish(Database.BatchableContext bc){

        this.soqlIndex = this.soqlIndex != null ? (this.soqlIndex + 1) : this.soqlIndex;
        // 30.01.2024 / Sophal Noch / US-0014277 : change from call method to call class that extend AbstractBatchCohortAction
        if(this.soqlIndex != null && this.MAP_ACTION_TYPE_TO_EXECUTION.containsKey(this.getActionNameIndex())){ // when execute next batch
            if(setNextSobjIds == null){ 
                setNextSobjIds = this.setSobjIds.clone();
            }
            BatchCohortAction nextBatch = new BatchCohortAction(action, this.soqlIndex, setNextSobjIds);
			Database.executeBatch(nextBatch);
        }else{  // when there are no batch to excecute, publish finish event
            CohortAction_Event__e updateEvent = new CohortAction_Event__e(Action_Name__c = ACTION_FINISH, Action_Index__c = 0, Action_Label__c = Label.Finish, Is_Finish__c = true);
            EventBus.publish(updateEvent);
        }

    }

    /*********************************************************************************************************************************
    @ Method:         executeSync
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014361 - Cohort Activation Process Part 2
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.11.2023 / Sophal Noch / Created the method.
                    :  30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
    *********************************************************************************************************************************/
    public void executeSync(){ // call logic in batch in sync mode
        
        if(this.execution == null){
            return;
        }

        execute(null, this.execution.executeQuery());

        this.soqlIndex = this.soqlIndex != null ? (this.soqlIndex + 1) : this.soqlIndex;
        // 30.01.2024 / Sophal Noch / US-0014277 : change from call method to call class that extend AbstractBatchCohortAction
        if(this.soqlIndex != null && this.MAP_ACTION_TYPE_TO_EXECUTION.containsKey(this.getActionNameIndex())){ // when execute next batch
            if(setNextSobjIds == null){ 
                setNextSobjIds = this.setSobjIds.clone();
            }
            new BatchCohortAction(action, this.soqlIndex, setNextSobjIds).executeSync();
        }
        
    }

    private String getActionNameIndex(){
        return (this.action + (this.soqlIndex != null ? ('_'+this.soqlIndex) : ''));
    }

}