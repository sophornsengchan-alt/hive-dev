/*********************************************************************************************************************************
@ Class:         Batch_FixCampaignMemberResponseValue
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       EPH-5187: batch to fix the missing Response Value (EBH_Results__c)  while EBH_ResponseCode__c presence.
                 There's a trigger, EBH_CampaignMemberTriggerHandler, that populate the correct value for EBH_Results__c bases on EBH_ResponseCode__c.
                 However, for unknow reason, EBH_Results__c is empty. This batch runs nightly job to fix this issue.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.02.2018 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/

global without sharing class Batch_FixCampaignMemberResponseValue implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
    
    String soql = 'select id,campaignId,Status,EBH_LastResponseDate__c,  EBH_Results__c, EBH_ResponseCode__c '+
    'from CampaignMember where  EBH_Results__c=NULL AND EBH_ResponseCode__c <>null';
    
    /*****************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        QueryLocator start method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.02.2018 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the method.
    ****************************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(soql);
    }
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        QueryLocator execute method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.02.2018 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/
    global void execute(Database.BatchableContext pBc, List<SObject> scope){
        system.debug('>>>>>>>scope:'+scope.size());
        EBH_CampaignMemberTriggerHandler.doUpdateCampaignMemberStatus((List<CampaignMember>)scope,null,true); //forceUpdate
        update scope;
        
         system.debug('>>>>scope updapted:'+scope);
    }
    
    /*****************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        QueryLocator finish method, it calls the insert batch
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.02.2018 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/ 
    global void finish(Database.BatchableContext pBc){
        
    }
     
     /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        Allow this batch to be schedulable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.02.2018 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/ 
     global void execute(SchedulableContext sc) { 
        Batch_FixCampaignMemberResponseValue b = new Batch_FixCampaignMemberResponseValue();
        Database.executeBatch(b);
    }
}