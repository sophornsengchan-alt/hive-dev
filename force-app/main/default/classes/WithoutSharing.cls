/** 
 This class is created to do DML or Query in 'without sharing' context to avoid INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
 @ Change history : 25.09.2023 / Sophal Noch / US-0014118 - ADS - New Cohort seller bulk upload template
 */
public without sharing class WithoutSharing {
    
    public static void doUpdate(sObject[] sObj){
    	if(!sObj.isempty()) update sObj;
    }
    
    public static void doInsert(sObject[] sObj){
    	if(!sObj.isempty()) insert sObj;
    }

    public static void doDelete(sObject[] sObj){
    	if(!sObj.isEmpty()) delete sObj;
    }

    public static void doUpsert(sObject[] sObjs){
        upsert sObjs;
    }
    
    public static Database.SaveResult[] doUpdate( sObject[] sObjs, boolean allOrNone ){
        return Database.Update(sObjs, allOrNone);
    }

    public static Database.UpsertResult[] doUpsert( sObject[] sObjs, Schema.SObjectField uniqueId, boolean allOrNone ){ // 25.09.2023 / Sophal Noch / US-0014118
        return Database.Upsert(sObjs, uniqueId, allOrNone);
    }

	public static void doUpsert(List<FMRS__c> lstRSMonthly){
    	if(!lstRSMonthly.isEmpty()) upsert lstRSMonthly UniqueKey__c; 
    }

    public static void doUpsert(List<Revenue_Schedules_Monthly__c> lstRSMonthly){
    	if(!lstRSMonthly.isEmpty()) upsert lstRSMonthly Unique_Key__c; 
    }

	public static void doUpsert(List<FDRS__c> lstRSDaily){
    	if(!lstRSDaily.isEmpty()) upsert lstRSDaily UniqueKey__c;
    }

    public static void doUpsert(List<RS_Daily__c> lstRSDaily){
    	if(!lstRSDaily.isEmpty()) upsert lstRSDaily Unique_Key__c;
    }
    
    public static void doUpsert(List<IO_Revenue_Schedule_Monthly__c> lstRSMonthly){
        if(!lstRSMonthly.isEmpty()) upsert lstRSMonthly Unique_Key__c; 
    }

    public static void doUpsert(List<IO_Revenue_Schedule_Daily__c> lstRSDaily){
        if(!lstRSDaily.isEmpty()) upsert lstRSDaily Unique_Key__c;
    }
     
    //String soql = 'Select Id,Name FROM Contact ';
    //String sWhere = ' WHERE AccountId=\'0012300000ZDvYMAA1\' AND MobilePhone=\'12345\'';
    //String addtion = ' ORDER BY CreatedDate DESC LIMIT 3'
    public static List<SObject> doQuery(String soql,String sWhere,String addtion)
    {  
        //system.debug('--------------soql: '+soql + sWhere +  addtion);
        return Database.query(soql + sWhere +  addtion);
    }
 
    public static  Database.SaveResult[] doInsert(List<SObject> listObj,Boolean allOrNone)
    {         
        return Database.Insert(listObj,allOrNone);
    }

    //NK:15/07/2022:US-0012070
    public static  Database.DeleteResult[] doDelete(List<SObject> listObj,Boolean allOrNone)
    {         
        return Database.delete(listObj,allOrNone);
    }
     
    /**
    public static IO_LineItem_Junction__c[] getIOItemJunctionsForCalculate(Set<Id> ioLineIds) {
    	// The query criteria and ORDER BY are the logic implimented in caller method
    	return [select id, IO_LineItem__c, 
						Quote_LineItem__r.Quantity, Quote_LineItem__r.SalesPriceNet__c,
						IO_LineItem__r.Product__r.Billing_Category__c 
				from IO_LineItem_Junction__c 
				where IO_LineItem__c IN :ioLineIds and Quote_LineItem__c != null order by CreatedDate];
    }
    */
}