/**
 * description : This is a factory class for Bob_Seller_Category__c object
 */
public with sharing class CohortSellerCatPeformanceDataFactory implements IDataFactory{
    public sObject getRecord() {
        return null;
     }
 
     /**
      * get list of  record
      */
     public list<sObject> getRecordsByIds(set<id> sobjectdIds) {
         
        string cohortSellerCategoryPerformanceQuery = 'SELECT id,Category_Tree__c,Category_Tree__r.name,Categ_Share_Sales__c,Categ_Share_Sales_Prev_MOM__c,';
        cohortSellerCategoryPerformanceQuery += 'Categ_Total_Sales__c,Categ_Total_sales_Prev_MOM__c,Categ_Ranking__c,';
        cohortSellerCategoryPerformanceQuery += 'Categ_Ranking_Prev_Month__c,Category_Name__c,' ;
        cohortSellerCategoryPerformanceQuery += 'Fast_Free_Ship__c,Click_Collect__c,Returns_30days_Or_Longer__c,Nextday_Delivery__c,MultiBuy__c,';
        cohortSellerCategoryPerformanceQuery += 'Order_Discount__c,Sale_Event__c,Slr_Item_Specifics_Per_LL__c,';
        cohortSellerCategoryPerformanceQuery += 'Item_Specifics_Per_LL__c,Slr_Photos_Per_LL__c,Photos_Per_LL__c,';
        cohortSellerCategoryPerformanceQuery += 'Slr_Title_length_Character_Cnt__c,Title_Length_Character_Cnt__c,Slr_Sponsored_LL_Number_of_LL__c,';
        cohortSellerCategoryPerformanceQuery += 'Sponsored_LL_Number_of_LL__c FROM Bob_Seller_Category__c';
        string cohortSellerCategoryPerformanceWhereClause = ' WHERE Cohort_Seller__c IN:sobjectdIds ORDER BY Categ_Performance_Rank__c ASC'; 
        cohortSellerCategoryPerformanceQuery += cohortSellerCategoryPerformanceWhereClause;
        return Database.query(cohortSellerCategoryPerformanceQuery);
        //return WithoutSharing.doQuery(cohortSellerCategoryPerformanceQuery,/*cohortSellerCategoryPerformanceWhereClause*/'','');
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