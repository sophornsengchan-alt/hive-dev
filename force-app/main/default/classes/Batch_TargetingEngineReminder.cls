/*********************************************************************************************************************************
@ Class:          Batch_TargetingEngineReminder
@ Version:        1.0
@ Author:         Ratha SIM (ratha.sim@gaea-sys.com)
@ Purpose:        US-0008047 Targeting Engine Delete Lists 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.08.2020 / Ratha SIM / Created the class.
*********************************************************************************************************************************/
global class Batch_TargetingEngineReminder implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    private Set<Id> teIdsToDelete = new Set<Id>();
    private Id teId;
    private Date todayDate = System.now().dateGMT();
    //
    public final static String STR_TE_SELECTQUERY = 'SELECT Id, ' +
                                                        ' EBH_TE_Expiration_Date__c, ' +
                                                        ' Name, ' +
                                                        ' Owner.email, ' +
                                                        ' Owner.name ' +
                                                    ' FROM EBH_Filter__c ';
    //
    private String STR_TE_WHEREQUERY = ' WHERE EBH_TE_Expiration_Date__c =: day3 ' +
                                                    ' OR EBH_TE_Expiration_Date__c =: day7 ' +
                                                    ' OR EBH_TE_Expiration_Date__c <= TODAY ';
    //create object to execute batch all records need time to delete record
    global Batch_TargetingEngineReminder() {

    }
    // create object with specific id targeting engine to delete
    global Batch_TargetingEngineReminder(Id teId) {
        this.teId = teId;
        STR_TE_WHEREQUERY = ' WHERE Id =:teId';
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date day3 = todayDate.addDays(3);
        Date day7 = todayDate.addDays(7);
        return Database.getQueryLocator(STR_TE_SELECTQUERY + STR_TE_WHEREQUERY); 
    }

    /*********************************************************************************************************************************
    @ Method:         execute
    @ Change history: 21.08.2020 / Ratha SIM / Created the method.
                    22.08.2020 / Acmatac SEING / Add conditional deletion where <=0.
    *********************************************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<EBH_Filter__c> scope) {
    try 
    {
        List<EBH_Filter__c> lstTEReminder = new List<EBH_Filter__c>();
        for(EBH_Filter__c oTE : scope) {
            Integer expirationDate = todayDate.daysBetween(oTE.EBH_TE_Expiration_Date__c);
            // Update driving field = TODAY, 
            // then workflow:(TE_Deletion_Notify_3days OR TE_Deletion_Notify_7days_Workflow) will be triggered and send email
            if(expirationDate == 3) {
                oTE.DateReminder3__c = todayDate;
                lstTEReminder.add(oTE);
            }else if(expirationDate == 7) {
                oTE.DateReminder7__c = todayDate;
                lstTEReminder.add(oTE);
            }
            // When EBH_TE_Expiration_Date__c <= TODAY, mean expired => DELETE
            else if(expirationDate <= 0) {
                teIdsToDelete.add(oTE.Id);
            }
        }

        if(!lstTEReminder.isEmpty()) {
            Database.update(lstTEReminder);
        }    
    }catch(Exception ex) {//TH: 04/07/2022: US-0011961 : check Error message
        EBH_ApexLogger.logError(new List<Exception> { ex }, 'Batch_TargetingEngineReminder', 'execute');
    }  
    }

    global void finish(Database.BatchableContext BC) {
        if(!teIdsToDelete.isEmpty()) {
            Database.executeBatch(new Batch_DeleteTargettedSeller(teIdsToDelete, 0));
        }
    }

    global void execute(System.SchedulableContext sc) { 
        Database.executeBatch(this);
    }
}