/*********************************************************************************************************************************
@ Class:          EBH_InsertTargetSellersBatch
@ Version:        1.0
@ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
@ Purpose:        Batch class to insert targeted seller
                  EPH-20 : Targeting Engine Filters
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the class.
*********************************************************************************************************************************/

global with sharing class EBH_InsertTargetSellersBatch implements Database.Batchable<SObject>, Database.Stateful{
    
    global final EBH_Filter__c Filter {get;set;}
    global final String LocalAccountQuery {get;set;}
    
    /*****************************************************************************************************************************
    @ Constructor:    EBH_InsertTargetSellersBatch
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        Initialises the class for controller instance.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Seller List record, LocalAccQuery
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the constructor.
    *****************************************************************************************************************************/
    global EBH_InsertTargetSellersBatch (EBH_Filter__c Filt, String LocalAccQuery){
        Filter = Filt;
        LocalAccountQuery = LocalAccQuery;
    }
    
    /*****************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator start method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(LocalAccountQuery);
    }
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator execute method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global void execute(Database.BatchableContext pBc, List<Account> scope){
        List<EBH_TargetedSeller__c> targetedSellers = new List<EBH_TargetedSeller__c>();
        
        for(Account acc : scope) {
            targetedSellers.add(new EBH_TargetedSeller__c(EBH_Seller__c = acc.Id, EBH_SellerList__c = Filter.Id));
        }
        try {
            Database.insert(targetedSellers);
        } catch(Exception ex) {
            //log error on exception to apex logger object
            EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                    EBH_ConstantsUtility.ITSBATCH_CLASSNAME, EBH_ConstantsUtility.ITSBATCH_METHODEXECUTE);
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator finish method, it sends an email notification to the seller list owner once the insert batch
                      is complete.  
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
   global void finish(Database.BatchableContext pBc){
        
        Filter.EBH_Refreshing__c = FALSE;
        try {
            Database.update(Filter);
        } catch(Exception ex) {
            //log error on exception to apex logger object
            EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                    EBH_ConstantsUtility.ITSBATCH_CLASSNAME, EBH_ConstantsUtility.ITSBATCH_METHODFINISH);
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {Filter.Owner.Email};
        mail.setToAddresses(toAddresses);
        mail.setReplyTo(EBH_ConstantsUtility.ITSBATCH_NOREPLY);
        mail.setSubject(Label.EBH_TargetingEngineBatchComplete);
        mail.setSenderDisplayName(EBH_ConstantsUtility.ITSBATCH_SENDERDISPLAY + Filter.Name);
        mail.setTargetObjectId(Filter.OwnerId);
        mail.setWhatId(filter.Id);
        mail.setSaveAsActivity(false);
        mail.setPlainTextBody(EBH_ConstantsUtility.ITSBATCH_MAILBODY + EBH_LightningURL__c.getInstance().EBH_URL__c+ Filter.Id);
                              
        if(toAddresses[0] != null) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}