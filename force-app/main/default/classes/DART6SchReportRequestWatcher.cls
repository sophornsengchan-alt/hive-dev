/*****************************************************************************************************************************************************************
    @ Class:          DART6SchReportRequestWatcher
    @ Version:        1.0
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
    @                 Cloned from EU Advertising
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.11.2020 / Acmatac SEING / Updated the class.
***********************************************************************************************************************************************************/

global without sharing class DART6SchReportRequestWatcher implements Schedulable{
    public final static Integer NEXT_EXEC_TIME_IN_SECONDS = 120; // minimum 2 mins
    private String ddsId;
    
     public DART6SchReportRequestWatcher(String ddsId){
        this.ddsId = ddsId;
    }
    
    public String createCronExpForNextFireTime(){
        DateTime now = System.now().addSeconds(NEXT_EXEC_TIME_IN_SECONDS);
        return now.second() + ' ' 
            + now.minute() + ' ' 
            + now.hour() + ' '
            + now.day() + ' '
            + now.month() + ' ? ' 
            + now.year();
    }
    
    global void execute(SchedulableContext sc) {
        DART_Delivery_Support__c dds = DeliveryController.getDeliverySupportRecord(ddsId);
        try{
            DART6BatchDeliverySupport batchSupport = new DART6BatchDeliverySupport(ddsId, DART6BatchDeliverySupport.CALL_TYPE_CHECK_REPORT_STATUS);
            if(sc != null) batchSupport.jobId = sc.getTriggerID();
            ID batchprocessid = Database.executeBatch(batchSupport);
        }catch(Exception e){
            DeliveryController.retryImport(dds, new DARTLogger.LogMessage(dds.Id , DART6BatchDeliverySupport.CALL_TYPE_CHECK_REPORT_STATUS,'DART6SchReportRequestWatcher.execute', dds.AdServer_Login__r.RecordType.name, e));if(sc.getTriggerID() != null ) System.abortJob(sc.getTriggerID());
        }
    }
}