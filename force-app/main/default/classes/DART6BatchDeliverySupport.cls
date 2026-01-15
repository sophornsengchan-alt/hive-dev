/*****************************************************************************************************************************************************************
    @ Class:          DART6BatchDeliverySupport
    @ Version:        1.0
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
    @                 Cloned from EU Advertising + Merging to NA
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.11.2020 / Acmatac SEING / Updated the class.
	@				: 11.09.2023 /vadhanak voun/ US-0013940 - PART 2 - Upgrade API version of all classes having an API version lower than 31
***********************************************************************************************************************************************************/
global virtual without sharing class DART6BatchDeliverySupport implements Database.Batchable<sObject>, Database.AllowsCallOuts, Database.Stateful{

    public final static String CALL_TYPE_CHECK_REPORT_STATUS = 'Check Running Report';
    public final static String CALL_TYPE_REQUEST_REPORT = 'Query Report';
    private String callType;
    public String jobId;
    @TestVisible
    private DART_Delivery_Support__c dds;
    
    // Acmatac, Copied from EU Instance
    public DART6BatchDeliverySupport(String ddsId, String calltype){
        this.callType = calltype;
        dds = DeliveryController.getDeliverySupportRecord(ddsId);
    }

    /**
     * Start batch
     */
    global virtual Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select Id From DART_Delivery_Support__c Where Id =: dds.Id]);
    }
    
    /**
     * execute batch
     */ 
    global virtual void execute(Database.BatchableContext BC, List<sObject> scope){}  
    
    /**
     * Finish batch
     * Check batch status, run delivery & checking to run delivery from other adserverLogin
     */
    global virtual void finish(Database.BatchableContext BC){
        try{ 
            if(callType == CALL_TYPE_CHECK_REPORT_STATUS){ 
                DeliveryController.checkJobStatus(dds); 
            }else if(callType == CALL_TYPE_REQUEST_REPORT){ 
                DeliveryController.doStart(dds);
            }
            if(jobId != null ) System.abortJob(jobId);
        }catch(Exception e){
            DeliveryController.retryImport(dds, new DARTLogger.LogMessage(
                                dds.Id , callType,
                                'DART6BatchDeliverySupport.finish', dds.AdServer_Login__r.RecordType.name, e));
            if(jobId != null ) System.abortJob(jobId);
        }
    }
}