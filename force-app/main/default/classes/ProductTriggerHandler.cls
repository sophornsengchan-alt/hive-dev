/*********************************************************************************************************************************
@ Class:          ProductTriggerHandler
@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        Handler class for Product2 Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.11.2024 / Sambath Seng / US-0016090 - Certilogo - Product/Pricebook Usability & Field Updates
*********************************************************************************************************************************/
public with sharing class ProductTriggerHandler {

    private static final String SOQL_STANDARDPRICEBOOK = 'SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1';
    private static final String SOQL_CURRENCYTYPE = 'SELECT IsoCode FROM CurrencyType WHERE IsActive = true';

    /**
    * This method is used to create standard price for certilogo products created
    * @param1 List<Product2> products
    */
    public static void createStandardPrice(List<Product2> products) {
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();

        // Get the standard pricebook ID
        List<Pricebook2> standardPricebook = ApexSafe.query().doQuery(SOQL_STANDARDPRICEBOOK);
        Id standardPricebookId = Test.isRunningTest() ? Test.getStandardPricebookId() : standardPricebook[0].Id;

        // Get the record type ID for 'certilogo'
        Id certilogoRecordTypeId = ApexUtil.getRecordTypeByName('Product2', 'Certilogo').Id;

        // Query active currencies once
        List<CurrencyType> currencyTypes = ApexSafe.query().doQuery(SOQL_CURRENCYTYPE);

        for (Product2 product : products) {
            // Check if the product's record type is 'Certilogo'
            if (product.RecordTypeId == certilogoRecordTypeId) {
                // Create a PricebookEntry for each currency
                for (CurrencyType currencyType : currencyTypes) {
                    PricebookEntry pbe = new PricebookEntry();
                    pbe.Pricebook2Id = standardPricebookId;
                    pbe.Product2Id = product.Id;
                    pbe.UnitPrice = 0; // Set the default price to 0
                    pbe.CurrencyIsoCode = currencyType.IsoCode;
                    pbe.IsActive = true;
                    pricebookEntries.add(pbe);
                }
            }
        }

        if (!pricebookEntries.isEmpty()) {
            Database.SaveResult[] insertResult = ApexSafe.dml().doInsert(pricebookEntries, true);
            if(!insertResult[0].isSuccess()){
                EBH_ApexLogger.logError(insertResult[0].getErrors(), 'Product2TriggerHandler', 'createStandardPrice');
            }
        }
    }
}