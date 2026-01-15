/*********************************************************************************************************************************
@ Class:          CertilogoAddManageProductsController
@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        Handle the Add/Manage Products functionality
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.09.2024 / Sambath Seng / US-0015493 Create the class
                  25-09-2024 Anujit/0015765
                  10-12-2024 / Sothea Horn / US-0016235 - ADS - Apply Filters on Price books in Edit line items screen
*********************************************************************************************************************************/
public with sharing class CertilogoAddManageProductsController {

    private static final String SOQL_LINEITEM = 'SELECT Id,opportunity.CurrencyIsoCode FROM OpportunityLineItem WHERE OpportunityId = :opportunityId';
    private static final String SOQL_LINEITEM_COUNT = 'SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :opportunityId';
    private static final String SOQL_OPPORTUNITY = 'SELECT Id, Pricebook2Id,CurrencyIsoCode, RecordType.DeveloperName FROM Opportunity WHERE Id = :opportunityId LIMIT 1';
    private static final String SOQL_PRICEBOOKENTRY = 'SELECT Id, Name, Product2Id, Product2.Name, Product2.ProductCode, UnitPrice,Product2.Family,Product2.Description FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND CurrencyIsoCode = :currencyIsoCode AND isActive = true';

    /**
    * This method is used to check if opportunity has lineitem
    * @param1 Id opportunityId
    * @return true if opportunity has line items, if no line items return false
    */
    @AuraEnabled(cacheable=true)
    public static boolean opportunityHasLineItems(Id opportunityId) {
        Integer lineItemsCount = ApexSafe.query().doCount(SOQL_LINEITEM_COUNT,new Map<String, Object> {'opportunityId' => opportunityId});
       return lineItemsCount > 0;
       
    }

     /**
    * This method is used to get opporty details
    * @param1 Id opportunityId
    * @return opportunity
    */
    @AuraEnabled(cacheable=true)
    public static opportunity getOpptyDetails(Id opportunityId) {
        Sobject[] oppList = ApexSafe.query().doQuery(SOQL_OPPORTUNITY, new Map<String, Object> {'opportunityId' => opportunityId});
        return (opportunity)oppList[0];
       
    }

    /**
    * This method is used to get all active pricebook records which:
    *   - has at least 1 Price book entry with status = Active and currency = Opportunity currency
    *   - Record Type of the Pricebook matches the possible values from "Opportunity Pricebook Record Type Mapping" based on Opportunity Record Type.
    *   - The pricebook is shared with me as "Use" (automatic through Salesforce) - continue to use with sharing on controller
    *
    * @param1 Id opportunityId
    * @return list of active pricebooks 
    *         
    * ------------------------------------------------------------------------------------------------------------------------------------------------------
    * @ Change history: 10-12-2024 / Sothea Horn / US-0016235 - ADS - Apply Filters on Price books in Edit line items screen
    */
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getPriceBooks(Id opportunityId) {
        Map<String,Object> mapResult = new Map<String,Object>();
        try {
            List<Pricebook2> pricebooks = HIVE_Helper.getPriceBooks(opportunityId);
            mapResult.put('status','ok');
            mapResult.put('pricebooks', pricebooks);

        } catch(Exception ex) {
            mapResult.put('status', 'ko');
            mapResult.put('error', ex.getMessage());
            mapResult.put('errorDetail', ex.getStackTraceString());
    	}
        return mapResult;
    }

    /**
    * This method is used to update Pricebook2Id of opportunity and delete all related lineitem records
    * @param1 Id opportunityId
    * @param2 Id pricebookId
    * @return map result of dml
    */
    @AuraEnabled
    public static Map<String,Object> updateOpportunityPricebook(Id opportunityId, Id pricebookId) {
        Map<String,Object> mapResult = new Map<String,Object>();

        Sobject[] lineItems = ApexSafe.query().doQuery(SOQL_LINEITEM, new Map<String, Object> {'opportunityId' => opportunityId});

        // delete all related lineitem
        Database.DeleteResult[] deleteResult = ApexSafe.dml().doDelete(lineItems, true);
        if(deleteResult.size() > 0 && deleteResult[0].isSuccess()){
            mapResult.put('status','success');  
        }else if (deleteResult.size() > 0 && !deleteResult[0].isSuccess()){
            mapResult.put('status','error'); EBH_ApexLogger.logError(deleteResult[0].getErrors(), 'CertilogoAddManageProductsController', 'updateOpportunityPricebook');
        }

        Sobject[] oppList = ApexSafe.query().doQuery(SOQL_OPPORTUNITY, new Map<String, Object> {'opportunityId' => opportunityId});

        // update Pricebook2Id of opportunity
        if (!oppList.isEmpty()) {
            //Opportunity opp = (Opportunity)oppList[0];
            Opportunity opp = new Opportunity(Id=oppList[0].Id); //MN-12122024-US-0016235: To avoid the error "Cannot specify both an external ID reference RecordType and a salesforce id,  RecordTypeId"
            opp.Pricebook2Id = pricebookId;
            
            Database.SaveResult[] updateResult = ApexSafe.dml().doUpdate(new List<Opportunity>{opp}, true);
            if(updateResult[0].isSuccess()){
                mapResult.put('status','success');  
            }else{
                mapResult.put('status','error'); EBH_ApexLogger.logError(updateResult[0].getErrors(), 'CertilogoAddManageProductsController', 'updateOpportunityPricebook');
            }
        }
        return mapResult;
    }


    /**
    * This method is used to get the get a list of products that have pricebook entries in the opportunity's pricebook, 
    * and for the currency of the opportunity.
    */
    @AuraEnabled(cacheable=true)
    public static list<PricebookEntry>  getlistofProducts(Id opportunityId) {
        
        list<PricebookEntry> pricebookEntries = new list<PricebookEntry>();
        List<Opportunity> oppList = ApexSafe.query().doQuery(SOQL_OPPORTUNITY, new Map<String, Object> {'opportunityId' => opportunityId});
        
        Opportunity opp = oppList[0];
        String currencyIsoCode = opp.CurrencyIsoCode;
        Id pricebookId = opp.Pricebook2Id;
        try{
            pricebookEntries = ApexSafe.query().secCheck(false).doQuery(SOQL_PRICEBOOKENTRY, new Map<String, Object> {'pricebookId' => pricebookId, 'currencyIsoCode' => currencyIsoCode});
        }catch(Exception ex){
            EBH_ApexLogger.logError(new List<Exception> { ex }, 'CertilogoAddManageProductsController','getlistofProducts');
        }

        return pricebookEntries;       
    }
    
}