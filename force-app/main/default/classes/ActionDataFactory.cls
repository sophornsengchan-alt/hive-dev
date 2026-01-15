/**
 * description : This is a data factory class for Action__c object
 * @ Change history:   : 12.01.2024 / Bora Chhorn / US-0014603 - Design Update - Pro-Trader Seller Dashboard
 *                 : 06.01.2025 / vadhanak voun / US-0016426 - PT Actions visibility on Dashboard condition amendments
 */
public with sharing class ActionDataFactory implements IDataFactory{
    public sObject getRecord() {
        return null;
     }
 
     /**
      * get list of  record
       : 06.01.2025 / vadhanak voun / US-0016426 - PT Actions visibility on Dashboard condition amendments
      */
     public list<sObject> getRecordsByIds(set<id> sobjectIds) {    //pdf to be done later
        List<id> sobjectIdList = new list<id>();
        sobjectIdList.addAll(sobjectIds);
        string sobjId = sobjectIdList[0];

        string actionQuery = 'SELECT id,Action_Template__c,Comments__c,Status__c,Description__c,Seller_facing_Dashboard_message__c,Due_Date__c,';// 12.01.2024 / Bora Chhorn / US-0014603
        actionQuery += 'Action_Document_Link__c,Action_Template__r.ActionTemplate_Help_Text__c ';
        actionQuery += ' FROM Action__c '; 
        string actionQueryWhereClause = ' WHERE LTTM_Seller__c ='+ApexUtil.closeSQoute(sobjId)+ ' AND Status__c IN (\'In Progress\',\'Completed\')';  
        actionQueryWhereClause += ' AND Action_Template__r.Visible_to_Sellers__c = TRUE';//NK:06/01/2025:US-0016426

        return WithoutSharing.doQuery(actionQuery,actionQueryWhereClause,'');
    }
 
     public list<sObject> getRecordbyId(Id sObjectId){
 
         return null;
     }
 
     /**
      * Returns a list of records
      */
     public List<sObject> getRecords(){
         return null;
     }
 
     public sObject createRecord() {
         return null;
     }
 
     /**
      * create a single record
      */
     public sObject createRecord(sObject sObjectRecord){
        insert sObjectRecord;
        return sObjectRecord;
     }
 
     /**
      * create a list of records
      */
     public List<sObject> createRecords(List<sObject> sObjects){
         return null;
     }
 
     /**
      * update a single record
      */
     public sObject updateRecord(id sObjectId){
         return null;
     }
 
     /**
      * update a list of records
      */
     public List<sObject> updateRecords(List<sobject> sObjects){
         update sobjects;
         return sobjects;
     }
 
     /**
      * upsert a single record
      */
     public sObject upsertRecord(sobject sObjectRecord){
         return null;
     }
 
     /**
      * upsert a list of records
      */
     public List<sObject> upsertRecords(List<sobject> sObjects){
         return null;
     }
 
     /**
      * delete a single record
      */
     public sObject deleteRecord(sobject sObjectRecord){
         return null;
     }
 
     /**
      * delete a list of records
      */
     public List<sObject> deleteRecords(List<sobject> sObjects){
         return null;
     }
 
     /**
      * merge a list of records
      */
     public void dmlMerge(SObject masterRecord, List<SObject> objList){
         
     }
 
     
}