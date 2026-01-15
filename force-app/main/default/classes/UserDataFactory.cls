/**
 * description: This class is used to get the user data
 */
public with sharing class UserDataFactory implements IDataFactory{

    public sObject getRecord() {

        string userQuery = 'SELECT Id, Contact.Account.EBH_RevRollup__c, contactId, contact.email, contact.name,Calendly__CalendlyLink__c,Name,Customer_facing_eMail__c,MediumPhotoUrl, ';
        userQuery += 'contact.account.EBH_OracleID__c,contact.account.name, contact.phone, contact.account.Brand_Engagement_Lead__c,';
        userQuery += 'contact.account.Brand_Engagement_Lead__r.calendly__calendlylink__c,contact.AccountId FROM User ';
        
        return (User) WithoutSharing.doQuery(userQuery ,' WHERE id ='+ApexUtil.closeSQoute(userInfo.getUserId()),'')[0];
    }    

    public list<sObject> getRecordbyId(Id sObjectId){
        string userQuery = 'SELECT Id, email,firstname,lastname, contactId,contact.AccountId,Calendly__CalendlyLink__c,Name,Customer_facing_eMail__c,MediumPhotoUrl FROM User ';
        
        return (list<User>) WithoutSharing.doQuery(userQuery ,' WHERE id ='+ApexUtil.closeSQoute(sObjectId),'');
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
        return null;
    }

    /**
     * get list of  record
     */
    public list<sObject> getRecordsByIds(set<id> sObjectIds) {
        return null;
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