/*********************************************************************************************************************************
@ Class:         Batch_DeleteServiceRecords
@ Version:       1.0
@ Author:        Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:       US-0014263 - Store log of unsuccessful logins for sellers portal		 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 1.12.2023 / Sambath Seng / Created the class.
*********************************************************************************************************************************/
global with sharing class Batch_DeleteSellerPortalLogRecord implements Database.Batchable<SObject>, Schedulable{	
    
	private String soqlSellerPortalLog = 'Select Exclude_from_auto_deletion__c,CreatedDate From Seller_Portal_Log__c';
    private String sWhere = ' Where Exclude_from_auto_deletion__c = false And CreatedDate < LAST_N_DAYS:90';
    private String sellerPortalLogId;

    public Batch_DeleteSellerPortalLogRecord()
    {
    }
    
	public Batch_DeleteSellerPortalLogRecord(String sellerPortalLogId)
    {
    	this.sellerPortalLogId = sellerPortalLogId;
    	sWhere = ' Where Exclude_from_auto_deletion__c = false And Id =:sellerPortalLogId';
    }
	
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(soqlSellerPortalLog+sWhere);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {

        Database.DeleteResult[] result = Database.delete(scope,false);

        for(Database.DeleteResult dr : result) {
            if ( !dr.isSuccess() ) {  
                EBH_ApexLogger.logError(new List<Database.Error> { dr.getErrors()[0]}, 'Batch_DeleteSellerPortalLogRecord', 'execute');
                break;
            }
        }
    }

    global void finish(Database.BatchableContext pBc){

    }
    global void execute(SchedulableContext sc) { 
        Batch_DeleteSellerPortalLogRecord b = new Batch_DeleteSellerPortalLogRecord();
        Database.executeBatch(b);
    }

}