/*********************************************************************************************************************************
@ Class:         BatchCalculateChannelColourCoding
@ Author:        Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:       US-0012674 - Colour coding for Channel /Influencer Account
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.10.2022 / Acmatac SEING / Created the batch.
*********************************************************************************************************************************/
public with sharing class BatchCalculateChannelColourCoding implements Database.Batchable<sObject>, Schedulable {
    private final String STR_QUERY = 'SELECT Id, Name From Channel__c ';
    private String str_WhereClause = 'WHERE Name != null AND Influencer__c != null ';
    private String influencerId;

    public BatchCalculateChannelColourCoding() {}
    public BatchCalculateChannelColourCoding(String influencerId) {
        this.influencerId = influencerId;
        str_WhereClause += 'AND Influencer__c =: influencerId';
    }

    public Database.querylocator start(Database.BatchableContext bc)
    {
    	return Database.getQueryLocator(STR_QUERY + str_WhereClause);
    }
    
    public void execute(Database.BatchableContext bc, List<Channel__c> scope)
    {
        Set<Id> channelIds = new Set<Id>();
        for(Channel__c oChann: scope){
            channelIds.add(oChann.Id);
        }
        List<Channel__c> listCalculateChannel = new List<Channel__c>();
        for(Channel__c oChann: [SELECT Id, Numeric_Status__c, (SELECT Id,Numeric_Status__c FROM Campaign_Channel__r Order by Numeric_Status__c DESC LIMIT 1) From Channel__c WHERE Id IN: channelIds ORDER BY Influencer__c]){
            if(oChann.Campaign_Channel__r.size() > 0){
                // If the same value no update, to prevent wasted CPU
                if(oChann.Numeric_Status__c == oChann.Campaign_Channel__r.get(0).Numeric_Status__c){
                    continue;
                }
                oChann.Numeric_Status__c = oChann.Campaign_Channel__r.get(0).Numeric_Status__c;
                listCalculateChannel.add(oChann);
            }else{
                oChann.Numeric_Status__c = 0;
                listCalculateChannel.add(oChann);
            }
        }

        try {
            update listCalculateChannel;
        } catch (Exception ex) {
            system.debug(ex);if(!Test.isRunningTest())EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchCalculateChannelColourCoding','execute (batch)');
        }
    }

    public void finish(Database.BatchableContext bc)
    {
        
    }
    
    public void execute(SchedulableContext ctx)
    {
    	BatchCalculateChannelColourCoding myBatch = new BatchCalculateChannelColourCoding();
    	Database.executeBatch(myBatch);
    }
    
}