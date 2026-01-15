/**
 * description: This class is used to get the Cohort Seller (BoB_Seller__c) data
 * change logs
 *  ...
 *      :21.10.2024/ vadhanak voun / US-0015188 - Tech debt- Remove Currency_ISO_Code__c custom field in cohort seller object
 */
public with sharing class CohortSellerDataFactory implements IDataFactory{

    public sObject getRecord() {
       return null;
    }

    /**
     * get list of  record
     */
    public list<sObject> getRecordsByIds(set<id> sobjectdIds) {
        
        return null;
    }

    public list<sObject> getRecordbyId(Id sObjectId){

        string cohortSellerQuery = 'SELECT id,Account_Manager__c,Share_of_Sales__c,Total_Sales_Cohort__c,Ranking__c,Total_Sales_Cohort_Previous_Month__c,Total_Sales_Cohort_Previous_Year__c,';
        cohortSellerQuery += 'Total_Sales_vs_Previous_year__c,Share_of_Sales_Previous_Month__c,Share_of_Sales_Previous_Year__c,Bob_Cohort_Name__c,';
        cohortSellerQuery += 'EBH_BOBSegment__c,Dashboard_Data_Available__c,Status__c,Seller_Name__c, ';
        //NK:21/10/2024:US-0015188 Currency_ISO_Code__c to CurrencyIsoCode
        cohortSellerQuery += 'Ranking_Previous_Month__c,Ranking_Previous_Year__c,Conversion_Rate_USD_Local__c,CurrencyIsoCode FROM BoB_Seller__c ';
        string cohortSellerWhereClause = ' WHERE Id ='+ApexUtil.closeSQoute(sObjectId) ;
        string addtionalCohortSellerWhereClause =+' AND Dashboard_Data_Available__c = TRUE '; 
        addtionalCohortSellerWhereClause += ' AND Status__c = '+ApexUtil.closeSQoute('Draft') +' AND EBH_BOBSegment__c = '+ApexUtil.closeSQoute('Pro-Trader Cat');
        //addtionalCohortSellerWhereClause += ' WITH SECURITY_ENFORCED'; AND BoB__r.Status__c = '+ApexUtil.closeSQoute('BoB Active')
        cohortSellerQuery += cohortSellerWhereClause + addtionalCohortSellerWhereClause;
        return Database.query(cohortSellerQuery);

        //return WithoutSharing.doQuery(cohortSellerQuery,cohortSellerWhereClause'','')[0];
    }

    /**
     * Returns a list of records
     */
    public List<sObject> getRecords(){
        return null;
    }

    public sObject createRecord() {
        BoB_Seller__c bobSeller = (BoB_Seller__c) getRecord();
        try{
            insert as user bobSeller ;
        }catch(Exception e){
            //handle exception
        }
        
        return bobSeller;
    }

    /**
     * create a single record
     */
    public sObject createRecord(sObject sObjectRecord){
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

    public static list<BoB_Seller__c> getCohortSellerId(Set<Id> sellerIds){


        return [select id,Account_Manager__c from BoB_Seller__c where Seller__c IN: sellerIds and BoB__r.Status__c = 'BoB Active'];
    }

    


}