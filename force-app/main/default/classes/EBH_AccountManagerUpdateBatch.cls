/*************************************************************************************************************************************
@ Class:          EBH_AccountManagerUpdateBatch
@ Version:        1.0
@ Author:         NEHA LUND (nalund@deloitte.co.uk)
@ Purpose:        Batch class to insert targeted seller
                  EPH-2828 : Customer Management
--------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.08.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the class.
*************************************************************************************************************************************/

global with sharing class EBH_AccountManagerUpdateBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    
    /*********************************************************************************************************************************
    @ Constructor:    EBH_AccountManagerUpdateBatch
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Initialises the class for controller instance.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the constructor.
    *********************************************************************************************************************************/
    global EBH_AccountManagerUpdateBatch() { }
    
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
            //Get the account records where Update Account Manager flag is true
            //If account manager name is updated,update owner flag will be checked 
            return Database.getQueryLocator(EBH_ConstantsUtility.ACCOUNT_QUERY);
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.ABTH_CLASS, EBH_ConstantsUtility.ABTH_SMETHOD);
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
    global void execute(Database.BatchableContext pBc, List<Account> scope){
        
        Set<String> names = new Set<String>{Label.EBH_IntegrationUser};
        List<Account> accountsToBeProcessed = new List<Account>();
        Map<String,Id> userMap = new Map<String,Id>();
        String accName = EBH_ConstantsUtility.DCS_BLANK;
       
        for(Account acc: scope) {        
            //if account manager name is changed/new records are inserted with account manager value else blanked
            names.add(acc.EBH_AccountManageName__c);
            accountsToBeProcessed.add(acc);
        }       
        
        //get the existing active users
        if(!names.isEmpty()) {
            //Existing users matching the user names from Account Manager name
            for(User usr: Database.query(EBH_ConstantsUtility.ATH_ACTIVEUSERQUERY) ){
                userMap.put(usr.Name.toLowerCase(), usr.Id);
            }
        }
        
        for(Account acc: accountsToBeProcessed) {    
            //converting it to lowercase as map key is case sensitive        
            accName = acc.EBH_AccountManageName__c != null ?acc.EBH_AccountManageName__c.trim().toLowerCase() : '';
             
            //set the owner id as the existing active user based on the name of account manager
            if(acc.EBH_AccountManageName__c != null && userMap.containsKey(accName)){
                acc.ownerID = userMap.get(accName);
                 
              
            } else {//if active user is not found, then default it to Integration User 
                acc.ownerID = userMap.containsKey(Label.EBH_IntegrationUser.toLowerCase())? 
                              userMap.get(Label.EBH_IntegrationUser.toLowerCase()) : acc.OwnerID;
            }
            acc.EBH_UpdateAccountManager__c = false;
        }
        if(!accountsToBeProcessed.isEmpty()) {
            try {
                Database.update(accountsToBeProcessed); 
            } catch(Exception ex) {
                EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.ABTH_CLASS, EBH_ConstantsUtility.ABTH_EMETHOD);
            }
        }        
    }
    
    /*********************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        To schedule the batch  
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.08.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    *********************************************************************************************************************************/
    global void execute(SchedulableContext sc) {     
        EBH_AccountManagerUpdateBatch b = new EBH_AccountManagerUpdateBatch();
        Database.executeBatch(b);
    }
    
    /*********************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        QueryLocator finish method, it sends an email notification to the seller list owner once the insert batch
                      is complete.  
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.08.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    *********************************************************************************************************************************/
    global void finish(Database.BatchableContext pBc) {  
       
    }
}