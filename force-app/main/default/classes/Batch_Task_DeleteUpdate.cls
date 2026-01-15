/*********************************************************************************************************************************
@ Class:          Batch_Task_DeleteUpdate
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        US-0012126  - CPU Limit error when user update Campaign stage to "Stopped"
@ Change history: 25.July.2022 / SRONG TIN / Created the class.
@ Change history: 23.November.2022 / Bora CHHORN / US-0012763 - Exception in Batch_Task_DeleteUpdate
*********************************************************************************************************************************/
global with sharing class Batch_Task_DeleteUpdate implements Database.Batchable<SObject>, Schedulable{

    private final String CAMPAIGN_STATUS = 'Completed';
    private final String taskStatusOpen = EBH_ConstantsUtility.AOC_TASKSTATUS;
    private final String taskStatusPaused = EBH_ConstantsUtility.TASK_STATUS_PAUSED;
    private final String taskStatusCancelled = EBH_ConstantsUtility.TASK_STATUS_CANCELLED;
    private final String COMPLETE_TASK_DAILY_QUERY = 'SELECT Id, WhatId, Status, Call_attempts__c, EBH_CampaignMemberId__c FROM Task ';
    private String whereCS = 'WHERE WhatId != null AND Related_Campaign__r.Status =:CAMPAIGN_STATUS AND (Status =:taskStatusOpen OR Status =:taskStatusPaused) ';
    private String batchQuery = '';
    private Set<String> campaignIds;
    public Batch_Task_DeleteUpdate(){
        batchQuery = COMPLETE_TASK_DAILY_QUERY + whereCS;
    }

    public Batch_Task_DeleteUpdate(Set<String> campaignIds){
        this.campaignIds = campaignIds;
        whereCS += 'AND WhatId IN:campaignIds';
        batchQuery = COMPLETE_TASK_DAILY_QUERY + whereCS;
    }

   global Database.QueryLocator start(Database.BatchableContext BC) 
   {        
       return Database.getQueryLocator(batchQuery);
   }

   global void execute(Database.BatchableContext pBc, List<Task> scope)
   {
       
        if(!scope.isEmpty()){
            List<Task> taskToDelete = new List<Task>();
            List<Task> taskToUpdate = new List<Task>();
            Map<Id, CampaignMember> mapCampMember = new Map<Id, CampaignMember>(); // BR-23-11-22-US-0012763
            for(Task t: scope){

                if(t.Call_attempts__c == null || t.Call_attempts__c == 0){
    				
                    taskToDelete.add(t);
    				if(t.EBH_CampaignMemberId__c <> null){   
                        CampaignMember oneCamp = new CampaignMember(Id=t.EBH_CampaignMemberId__c,EBH_ResponseCode__c = 22);
    					mapCampMember.put(oneCamp.Id, oneCamp);
    				}

    			}else{

    				t.Status = taskStatusCancelled;
    				taskToUpdate.add(t);
    			}
            }
            if(!taskToDelete.isEmpty()){
                delete taskToDelete;
            }
            if(!taskToUpdate.isEmpty()){
                update taskToUpdate;
            }
            if(!mapCampMember.isEmpty()){
                update mapCampMember.values(); // BR-23-11-22-US-0012763
            }
            
        }  
   }  
   
   
   global void finish(Database.BatchableContext pBc)
   {
       
   }
    
   global void execute(SchedulableContext sc) 
   {
        Batch_Task_DeleteUpdate bat_task = new Batch_Task_DeleteUpdate();
        Database.executeBatch(bat_task);
    }
}