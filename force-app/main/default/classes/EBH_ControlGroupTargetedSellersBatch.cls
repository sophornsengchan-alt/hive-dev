/*********************************************************************************************************************************
@ Class:          EBH_ControlGroupTargetedSellersBatch
@ Version:        1.0
@ Author:         NEHA LUND (nalund@deloitte.co.uk)
@ Purpose:        Batch class to reset Targeted Sellers Control group flagging
                  EPH-106 : Campaign Member creation
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.05.2018 / NEHA LUND (nalund@deloitte.co.uk) / Created the class.
*********************************************************************************************************************************/

global with sharing class EBH_ControlGroupTargetedSellersBatch implements Database.Batchable<SObject>, Database.Stateful{
    
    
    //set to store campaign ids
    global final Id filterID;
    global final double controlSize;
    global double calculatedcontrolGroupSize;
    
    //MN-11112021-US-0008402 - Release constant variable from EBH_ConstantsUtility
    public final static String RCG_TARGETEDSELLERQUERY 
         =  'SELECT Id, EBH_Seller__c, EBH_SellerList__c,Priority__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c WHERE EBH_SellerList__c = :filterId '; 

    public final static String RCG_VALIDSELLERQUERY 
         =  'SELECT Id, EBH_Seller__c, EBH_SellerList__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c WHERE EBH_SellerList__c = :filterId AND EBH_ExitCode__c != \'30\' '; 
    /*****************************************************************************************************************************
    @ Constructor:    EBH_ControlGroupTargetedSellersBatch
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Initialises the class for controller instance.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accounts, campaigns, sellerListTargetedSellers, sellerIdCampaigns
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2018 / NEHA LUND (nalund@deloitte.co.uk) / Created the constructor.
    *****************************************************************************************************************************/
    global EBH_ControlGroupTargetedSellersBatch (Id filterId, Decimal controlSize){
        this.filterId = filterId;
        this.controlSize = controlSize;
        
        System.debug('£££££'+controlSize);
    }
    
    /*****************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        QueryLocator start method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2018 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        calculatedcontrolGroupSize= Integer.valueOf(Math.floor(Database.query(RCG_VALIDSELLERQUERY ).size() * controlSize /100));
        
        System.debug('******'+calculatedcontrolGroupSize);
        
        //run the query and pass the records to excute method in 200 scope
        return Database.getQueryLocator(RCG_TARGETEDSELLERQUERY);
    
    }
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        QueryLocator execute method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2018 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global void execute(Database.BatchableContext pBc, List<EBH_TargetedSeller__c> scope){
        
         Map<Id,EBH_TargetedSeller__c> resetExitCode = new MAp<Id,EBH_TargetedSeller__c>();
        
        //fetch all the account and related contacts
        for(EBH_TargetedSeller__c targetedSellerRecord: scope) {
            if( targetedSellerRecord.EBH_ExitCode__c == '09' || targetedSellerRecord.EBH_ExitCode__c == '9'){
                targetedSellerRecord.EBH_ExitCode__c = '10';
                resetExitCode.put(targetedSellerRecord.ID, targetedSellerRecord);
            
            }
        }
        
        
          for(EBH_TargetedSeller__c targetedSellerRecord : scope) {
           
               if( targetedSellerRecord.EBH_ExitCode__c == '10' && calculatedcontrolGroupSize > 0){
                    targetedSellerRecord.EBH_ExitCode__c = '09';
                    calculatedcontrolGroupSize--;
                    resetExitCode.put(targetedSellerRecord.Id, targetedSellerRecord);
                
                }
                
         }
         
         System.debug('££££££'+resetExitCode.size());
         
         if( !resetExitCode.isEmpty()){
             update resetExitCode.values();
         }
        
           
    }
    
    /*****************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        QueryLocator finish method, it sends an email notification to the seller list owner once the insert batch
                      is complete.  
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2018 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global void finish(Database.BatchableContext pBc){
        
    }
}