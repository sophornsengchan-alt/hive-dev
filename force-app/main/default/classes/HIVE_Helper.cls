/*********************************************************************************************************************************
@ Class:          HIVE_Helper
@ Author:         Sothea Horn (sohorn@ebay.com)
@ Purpose:        Helper class for general using related to object records in HIVE
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.12.2024 / Sothea Horn / Created the class.
**********************************************************************************************************************************/
public with sharing class HIVE_Helper {

    private static final String SOQL_OPPORTUNITY = 'SELECT Id, Pricebook2Id, CurrencyIsoCode, RecordType.DeveloperName FROM Opportunity WHERE Id = :opportunityId LIMIT 1';
    private static final String BASE_SOQL_PRICEBOOK = 'SELECT Id, Name, IsActive FROM Pricebook2 WHERE IsActive = true';

    /**
    * This method is used to get all active pricebook records which:
    *   - has at least 1 Price book entry with status = Active and currency = Opportunity currency
    *   - Record Type of the Pricebook matches the possible values from "Opportunity Pricebook Record Type Mapping" based on Opportunity Record Type.
    *   - The pricebook is shared with me as "Use" (automatic through Salesforce) - continue to use with sharing on controller
    *
    * @param1 Id opportunityId
    * @return List<Pricebook2>
    ----------------------------------------------------------------------------------------------------------------------------------
    * @ Change history: 10.12.2024 / Sothea Horn / Created the method.
    */
    public static List<Pricebook2> getPriceBooks(String opportunityId, String searchName) {
        List<Pricebook2> pricebooks = new List<Pricebook2>();
        String soqlPricebook =  BASE_SOQL_PRICEBOOK;
        if (String.isNotBlank(searchName)) {
            searchName = '%'+ searchName +'%';
            soqlPricebook = soqlPricebook + ' AND Name LIKE : SearchName';
        }
        soqlPricebook = soqlPricebook + ' AND RecordType.Name = :pbRecordTypeName AND Id IN (SELECT Pricebook2Id FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode= :CurrencyIsoCode) ORDER BY Name';
        // Get custom metadata that mapping Opportuntiy Pricebook record type
        Map<String, String> mapOppPBRecordType = new Map<String, String>();
        for(OpportunityPricebookRecordTypeMapping__mdt oppPBRTMapping : OpportunityPricebookRecordTypeMapping__mdt.getAll().values()) {
            mapOppPBRecordType.put(oppPBRTMapping.OpportunityRecordType__c, oppPBRTMapping.PricebookRecordType__c);
        }
        // Get opportunity 
        List<Opportunity> listOpps = ApexSafe.query().doQuery(SOQL_OPPORTUNITY, new Map<String, Object> {'opportunityId' => opportunityId});
        if (!listOpps.isEmpty()) {
            Opportunity opp = listOpps[0];
            // Get pricebooks
            pricebooks = ApexSafe.query().doQuery(soqlPricebook, new Map<String, Object> {
                'SearchName' => searchName, 
                'pbRecordTypeName' => mapOppPBRecordType.get(opp.RecordType.DeveloperName), 
                'CurrencyIsoCode' => opp.CurrencyIsoCode
            });
        }
        return pricebooks;
    }

    public static List<Pricebook2> getPriceBooks(String opportunityId) {
        return getPriceBooks(opportunityId, null);
    }
}