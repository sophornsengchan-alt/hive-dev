/*************************************************************************************************************************************
@ Class:          EBH_PhoneCampaignCompletionBatch
@ Version:        1.0
@ Author:         NEHA LUND (nalund@deloitte.co.uk)
@ Purpose:        Batch class to mark the AM Outreach campaigns completed if there is any inactivity for phone mini campaigns
                  EPH-3780 : Campaign Management
--------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.10.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the class.
*************************************************************************************************************************************/

global with sharing class EBH_PhoneCampaignCompletionBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    
    /*********************************************************************************************************************************
    @ Constructor:    EBH_PhoneCampaignCompletionBatch
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Initialises the class for controller instance.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.10.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the constructor.
    *********************************************************************************************************************************/
    global EBH_PhoneCampaignCompletionBatch() { }
    
    /*********************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        QueryLocator start method
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.08.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    *********************************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            //get all campaign members where campaign record type is AM Outreach
            // Last Response Date is not null and Campaign status is not completed
            return Database.getQueryLocator(EBH_constantsUtility.PCB_QUERY);
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.PCB_CLASS, EBH_ConstantsUtility.PCB_METHOD);
        }
        
        return null;
    }
    
    /*********************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        QueryLocator execute method
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.08.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    *********************************************************************************************************************************/
    global void execute(Database.BatchableContext pBc, List<CampaignMember> scope){
        
        Date dt = Date.today()-14;
        List<Campaign> campaigns = new List<Campaign>();
        Set<ID> campaignIds = new Set<ID>();
        
        Campaign campaign = new Campaign();
        Map<Id, CampaignMember> mostRecentMembers = new Map<Id, CampaignMember>();
        
        //Retrieve only most recent last response date from campaign members
        for(CampaignMember tsk : scope){
            
             if( !mostRecentMembers.containsKey(tsk.CampaignId)){
                 mostRecentMembers.put(tsk.CampaignId, tsk);
                 
             }
             
        }
        
        //Check if last response date is less than or equal to Today
        for( CampaignMember cm: mostRecentMembers.values()){
            
            if( !campaignIds.contains(cm.campaignId) && cm.EBH_LastResponseDate__c <= dt ){
                 campaignIds.add(cm.campaignId);
             }
        }
        
        //Parse through campaigns and mark them completed 
        for( Id campId : campaignIds){
             campaign = new Campaign(Id = campId);
             campaign.Status = EBH_ConstantsUtility.PCB_COMPLETED;
             campaigns.add(campaign);
        }
        try {
            Database.update(campaigns);
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.PCB_CLASS, EBH_ConstantsUtility.PCB_METHOD);
        }
    }
    
    /*********************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        To schedule the batch  
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.10.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    *********************************************************************************************************************************/
    global void execute(SchedulableContext sc) {     
        EBH_PhoneCampaignCompletionBatch b = new EBH_PhoneCampaignCompletionBatch();
        Database.executeBatch(b);
    }
    
    /*********************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        QueryLocator finish method, it sends an email notification to the seller list owner once the insert batch
                      is complete.  
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.10.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    *********************************************************************************************************************************/
    global void finish(Database.BatchableContext pBc) {  
       
    }
}