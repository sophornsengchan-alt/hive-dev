/*********************************************************************************************************************************
@ Class:         BatchDealEmailReminder
@ Version:       1.0
@ Author:        Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       US-0026100 - Contarct Signature reminder email before Cancelling the Deals
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.05.2025 / Sovantheany Dim / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class BatchDealEmailReminder implements Database.Batchable<SObject>, Schedulable{
    private final static string STATUS_SENT_TO_SELLER = 'Sent to Seller';
    private final static string DEAL_V2 = 'Deal_V2';
    private final static string DEAL_US_SITE = '0';
    private Set<String> setIds = new Set<String>();
    private String sDCAjointQuery = 'SELECT Id, eBay_Seller__c FROM Deal_Contract_Agreement__c WHERE eBay_Seller__c != null and id IN (SELECT Deal_Contract_Agreement__c FROM EBH_Deal__c where RecordType.DeveloperName =: DEAL_V2 and EBH_Status__c =: STATUS_SENT_TO_SELLER and EBH_DealStartDate__c = TODAY and EBH_DealSiteId__c =: DEAL_US_SITE )';
    public final static string SELLER_COMM_NAME = 'Reminder Sub Deals Contract Signature - US';
    private final static String EMAILTEMPLATE = 'Contract Signature Reminder';
    public BatchDealEmailReminder() {
    }
    // THIS CONSTRUCTOR IS USED FOR TESTING PURPOSES ONLY
    public BatchDealEmailReminder(Set<String> setIds) {
        this.setIds = setIds;
        sDCAjointQuery += ' and id in :setIds';
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(sDCAjointQuery);
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope){
        Map<String,String> mapDCASellerId = new Map<String,String>();
        for(Deal_Contract_Agreement__c dca : (List<Deal_Contract_Agreement__c>) scope){
            mapDCASellerId.put(dca.Id,dca.eBay_Seller__c);
        }
        DealContractAgreementTriggerHandler.createSellerComsByDCA('Deals',mapDCASellerId,SELLER_COMM_NAME, EMAILTEMPLATE);
    }
    public void finish(Database.BatchableContext bc){
    }

    public void execute(SchedulableContext sc){
        BatchDealEmailReminder b = new BatchDealEmailReminder();
        Database.executeBatch(b, 100);
    }
}