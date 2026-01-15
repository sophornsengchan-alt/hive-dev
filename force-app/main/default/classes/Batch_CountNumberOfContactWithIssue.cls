/*********************************************************************************************************************************
@ Class:         Batch_CountNumberOfContactWithIssue
@ Version:       1.0
@ Author:        Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       EPH-5630 Seller - Quality & Preference
                Number of Contacts with Issues = COUNT number of Contacts that are not Green 
                Contact Data Quality =  "Red" =Seller has 0 Contacts with Contact Data Quality equal to "Green".
                                        "Amber" = Seller has 1 or more Contacts not Green, but at least 1 Contact that is Green
                                        "Green" = All Contacts of the Seller are Green
                Run to populate the existing contacts to sellers
                DeveloperConsole: Batch_CountNumberOfContactWithIssue.runCountContactToAccount();
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
global without sharing class Batch_CountNumberOfContactWithIssue implements Database.Batchable<SObject>, Database.Stateful{
    String soql = 'select id , AccountId from Contact';
    /*****************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        QueryLocator start method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
    ****************************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Id sellerRecordTypeId = [SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
        soql += ' where Account.RecordTypeId =: sellerRecordTypeId';
        return Database.getQueryLocator(soql);
    }
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        QueryLocator execute method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/
    global void execute(Database.BatchableContext pBc, List<SObject> scope){
        system.debug('>>>>>>>scope:'+scope);
        system.debug('>>>>>>>scope:'+scope.size());
        EBH_ContactTriggerHandler.countNumberOfContactsWithIssues((List<Contact>)scope); //forceUpdate
    }
    
    /*****************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        QueryLocator finish method, it calls the insert batch
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/ 
    global void finish(Database.BatchableContext pBc){
        
    }
     
     /*****************************************************************************************************************************
    @ Method:         runCountContactToAccount
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        Allow this batch to be schedulable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/ 
    public static void runCountContactToAccount(){
            Batch_CountNumberOfContactWithIssue b = new Batch_CountNumberOfContactWithIssue();
        Database.executeBatch(b,100);
    }
}