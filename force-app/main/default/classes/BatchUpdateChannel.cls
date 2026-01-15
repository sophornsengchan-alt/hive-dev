/*********************************************************************************************************************************
@ Class:         BatchUpdateChannel
@ Author:        Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:       US-0011821 - 1.2.2 Influencer (API for channel record)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.07.2022 / Acmatac SEING / Created the batch.
@                 02.11.2022 / Acmatac SEING / US-0012874 - Mulesoft last update date
@                 05.12.2022 / Acmatac SEING / US-0012966 - API is not updated for all IG channels
@                15.08.2023 / Acmatac Seing / US-0014001 - Logger error on future.
@                26.09.2023 / Acmatac Seing / US-0014139 - Meta APIs seems to be not working for eBay Influencer Portal
*********************************************************************************************************************************/
public class BatchUpdateChannel implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable{
    private final Integer LIMIT_RECORD = 180;
    private final String STR_QUERY = 'SELECT Id,Link__c FROM Channel__c ';
    private final String STR_TARGET = 'instagram_business_discovery';
    // now work only for instagram, but will change for future service
    private String sWhereCoupon = ' WHERE Link__c != null AND Link__c LIKE \'%instagram%\' AND (API_Last_Refresh_Date__c < LAST_N_DAYS:7 OR API_Last_Refresh_Date__c = null) ';

    private String channelId;

    public BatchUpdateChannel(){}

    public BatchUpdateChannel(String channelId){
        this.channelId = channelId;
        sWhereCoupon += ' AND Id=: channelId';
    }
 
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(STR_QUERY+sWhereCoupon+' LIMIT: LIMIT_RECORD');
    }
 
    public void execute(Database.BatchableContext BC, List<SObject> listRecord){
        try {
            List<Channel__c> listChannelToUpdate = new List<Channel__c>();
            List<String> listErrorMSG = new List<String>();
            for(Channel__c oChannel: (List<Channel__c>) listRecord){
                InfluencerService.CustomParameter cp = new InfluencerService.CustomParameter();
                cp.target = STR_TARGET;
                cp.url = oChannel.Link__c;
                List<InfluencerService.ResultWrapper> lstRW = InfluencerService.getUserInformation(new List<InfluencerService.CustomParameter>{cp});
                // Acmatac SEING / US-0012966
                if(!lstRW.get(0).hasError){ // Success
                    Channel__c cc = lstRW.get(0).channelRecord;
                    cc.Id = oChannel.Id;
                    cc.API_Last_Refresh_Date__c = System.now(); //Acmatac SEING / US-0012874 - Mulesoft last update date
                    listChannelToUpdate.add(cc);
                }else{
                    listErrorMSG.add(lstRW.get(0).errorMessage);
                }
            }
            if(!listErrorMSG.isEmpty()){
                // System.debug('BatchUpdateChannel : '+String.join(listErrorMSG, ', '));
                if(!Test.isRunningTest()){
                    // 15.08.2023 / Acmatac Seing / US-0014001 - Logger error on future.
                    EBH_ApexLogger.doLogError('', 0, '', '', String.join(listErrorMSG, ', '), 'BatchUpdateChannel','execute (batch) - listErrorMSG');
                }
            }
            // US-0014139 - Meta APIs seems to be not working for eBay Influencer Portal
            if(!listChannelToUpdate.isEmpty()){
                Database.SaveResult[] results = Database.update(listChannelToUpdate,false);
                List<Database.Error> dbError = new List<Database.Error>();

                for (Database.SaveResult result : results) {
                    if (!result.isSuccess() && !Test.isRunningTest()){ dbError.addAll(result.getErrors()); }
                }

                if (!dbError.isEmpty()) EBH_ApexLogger.logError(dbError, 'BatchUpdateChannel','execute (batch) on update');
            }
        } catch (Exception ex) {
            system.debug(ex);if(!Test.isRunningTest())EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchUpdateChannel','execute (batch)');
        }
    }
 
    public void finish(Database.BatchableContext BC){

    }
    
    //for scheduler
    public void execute(SchedulableContext ctx){
    	BatchUpdateChannel batchUC = new BatchUpdateChannel();
        // Set batch to 50, prevent 101 callout error
    	Database.executeBatch(batchUC, 50);
    }
 }