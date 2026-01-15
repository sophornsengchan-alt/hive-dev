/*********************************************************************************************************************************
@ Class:         BatchUpdateFVFStage
@ Author:        Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:       US-0013877 - FVF stage stuck in "contract signed" phase
@                - This batch schedule is the replica of Flow "FVF - Record Trigger Flow - Time Based" and will run daily at 6am CET
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.08.2023 / Mony Nou / Created the batch.
@               : 22.07.2024/ vadhanak voun/ US-0015373 - Align Apex Classes with Deactivated FVF_Campaign Record Type
*********************************************************************************************************************************/
global class BatchUpdateFVFStage implements Database.Batchable<SObject>, Schedulable {
    
    private final static String STAGE_DRAFT = 'Draft';
    private final static String STAGE_CONTRACTSENT = 'Contract Sent';
    private final static String STAGE_CONTRACTSIGNED = 'Contract Signed';
    private final static String STAGE_CONTRACTDECLINED = 'Contract Declined';
    private final static String STAGE_PLUTOPROMOCREATED = 'Plutus Promo Created';
    private final static String STAGE_RUNNINGCAMPAIGN = 'Running Campaign';
    private final static String STAGE_RUNNINGCONTRACT = 'Running Contract';
    private final static String STAGE_EXECUTEDCAMPAIGNS = 'Executed Campaigns';
    private final static String STAGE_EXECUTEDCONTRACT = 'Executed Contract';
    
    // private final static String RT_FVF_CAMPAIGN = 'FVF_Campaign';
    private final static String RT_FVF_LISTINGLEVEL = 'FVF_Listing_Level';
    private final static String RT_FVF_SELLERLEVEL = 'FVF_Seller_Level';

    private final static String CONTACTDECLINEREASON = 'Auto decline';
    
    private final static Set<String> FVF_RUNNING_STAGES = new Set<String>{STAGE_RUNNINGCAMPAIGN, STAGE_RUNNINGCONTRACT};
    private final static Set<String> FVF_SELLERLEVER_NOTDECLINED_STAGES = new Set<String>{STAGE_CONTRACTSIGNED, STAGE_PLUTOPROMOCREATED, STAGE_RUNNINGCONTRACT, STAGE_EXECUTEDCONTRACT, STAGE_CONTRACTDECLINED, STAGE_DRAFT};

    private String sQuery = 'Select id, Final_Value_Fee_Stage__c, RecordType.DeveloperName, Start_Date_w__c, End_Date_w__c From Final_Value_Fee_FVF__c';
    private String sWhere = ' Where (Start_Date_w__c <= TODAY AND Final_Value_Fee_Stage__c =:STAGE_CONTRACTSIGNED AND RecordType.DeveloperName =:RT_FVF_LISTINGLEVEL)'
                            + ' OR (Start_Date_w__c <= TODAY AND Final_Value_Fee_Stage__c =:STAGE_PLUTOPROMOCREATED AND RecordType.DeveloperName =:RT_FVF_SELLERLEVEL)'
                            //+ ' OR (Start_Date_w__c <= TODAY AND Final_Value_Fee_Stage__c =:STAGE_CONTRACTSENT AND RecordType.DeveloperName =:RT_FVF_CAMPAIGN)'
                            + ' OR (End_Date_w__c <= TODAY AND Final_Value_Fee_Stage__c IN:FVF_RUNNING_STAGES)'
                            + ' OR ((Start_Date_w__c=TODAY OR Start_Date_w__c = NEXT_N_DAYS:6) AND RecordType.DeveloperName =:RT_FVF_SELLERLEVEL AND Final_Value_Fee_Stage__c NOT IN:FVF_SELLERLEVER_NOTDECLINED_STAGES)';
    
    private Set<String> fvfIds;

    public BatchUpdateFVFStage() {}

    public BatchUpdateFVFStage(Set<String> fvfIds) {
        this.fvfIds = new Set<String>();
        this.fvfIds.addAll(fvfIds);
        this.sWhere = ' WHERE Id IN:fvfIds';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {

        return Database.getQueryLocator(sQuery+sWhere);
    
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        /*
            We need to update fvf records based on correct steps as below so it can display in Field History Tracking correctly
            - 1st step (DECLINE)
                + For FVF_Seller_Level only: 6 days before Start Date and if it isn't in Non-Declined Stages (var FVF_SELLERLEVER_NOTDECLINED_STAGES) => update to "Contract Declined"
            - 2nd step (RUNNING):
                + For FVF_Campaign: Update from "Contract Sent" to "Running Campaign"
                + For FVF_Listing_Level & FVF_Seller_Level: Update from "Contract Signed"/"Pluto Promo Created" to "Running Contract"
            - 3rd step (EXECUTED):
                + For FVF_Campaign: Update from "Running Campaign" to "Executed Campaigns"
                + For FVF_Listing_Level & FVF_Seller_Level: Update from "Running Contract" to "Executed Contract"
        
        */
        
        List<Final_Value_Fee_FVF__c> lstFVF2Update = new List<Final_Value_Fee_FVF__c>();

        Date dToday = Date.today();
        
        for (Final_Value_Fee_FVF__c fvf : (List<Final_Value_Fee_FVF__c>) scope) {

            //1st step: Check for fvf to Decline
            if (fvf.RecordType.DeveloperName == RT_FVF_SELLERLEVEL && !FVF_SELLERLEVER_NOTDECLINED_STAGES.contains(fvf.Final_Value_Fee_Stage__c) && (fvf.Start_Date_w__c == dToday || fvf.Start_Date_w__c <= dToday.addDays(6))) {
                
                fvf.Final_Value_Fee_Stage__c = STAGE_CONTRACTDECLINED;
                fvf.Contract_Decline_Reasons__c = CONTACTDECLINEREASON;
                
            }
            else {

                //2nd step: Check for fvf to update to Running
                if (fvf.Start_Date_w__c <= dToday && ((fvf.RecordType.DeveloperName == RT_FVF_LISTINGLEVEL && fvf.Final_Value_Fee_Stage__c == STAGE_CONTRACTSIGNED) 
                            || (fvf.RecordType.DeveloperName == RT_FVF_SELLERLEVEL && fvf.Final_Value_Fee_Stage__c == STAGE_PLUTOPROMOCREATED)
                            //|| (fvf.RecordType.DeveloperName == RT_FVF_CAMPAIGN && fvf.Final_Value_Fee_Stage__c == STAGE_CONTRACTSENT)
                            )) 
                            {

                    // fvf.Final_Value_Fee_Stage__c = (fvf.RecordType.DeveloperName == RT_FVF_CAMPAIGN)?STAGE_RUNNINGCAMPAIGN:STAGE_RUNNINGCONTRACT;
                    fvf.Final_Value_Fee_Stage__c = STAGE_RUNNINGCONTRACT;

                }

                //3rd step: Check for fvf to update to Executed
                //Incase FVF has the same Start Date & End Date => that FVF will update to Executed in tomorrow batch instead
                if (FVF_RUNNING_STAGES.contains(fvf.Final_Value_Fee_Stage__c) 
                            && (fvf.End_Date_w__c < dToday 
                                || (fvf.End_Date_w__c == dToday && fvf.End_Date_w__c != fvf.Start_Date_w__c))) {

                    //fvf.Final_Value_Fee_Stage__c = (fvf.RecordType.DeveloperName == RT_FVF_CAMPAIGN)?STAGE_EXECUTEDCAMPAIGNS:STAGE_EXECUTEDCONTRACT;
                    fvf.Final_Value_Fee_Stage__c = STAGE_EXECUTEDCONTRACT;

                }

            }
            
            
            lstFVF2Update.add(fvf);
            
        }

        if (!lstFVF2Update.isEmpty()) {
            
            Database.SaveResult[] results = Database.update(lstFVF2Update,false);
            List<Database.Error> dbError = new List<Database.Error>();

            for (Database.SaveResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()){ dbError.addAll(result.getErrors()); }
            }

            if (!dbError.isEmpty()) EBH_ApexLogger.logError(dbError, 'BatchUpdateFVFStage','execute (batch)');
        }


    }

    global void finish(Database.BatchableContext pBc){

    }

    global void execute(SchedulableContext sc) { 

        BatchUpdateFVFStage b = new BatchUpdateFVFStage();
        Database.executeBatch(b, 50);
    }

}