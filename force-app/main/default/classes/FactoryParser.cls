/**
 * Call to parse DFP object to Apex dartObject
 */
public without sharing class FactoryParser {

    private static FactoryParser instance;

    private FactoryParser() {}

    public static FactoryParser getInstance() {
        if (instance == null) {
            instance = new FactoryParser();
        }
        return instance;
    }


    /**
     * Advertiser Parser 
     * @param Account
     * @param Dart Version
     * @return IDARTParser
     */
    public DART6Parser.IDARTParser createAdvertiserParser(Account acc, String dartVersion) {
        if (DARTUtil.DART6.equals(dartVersion)) {
            return new DART6Parser.DFPResponseToCompanyParser(acc);
        }
        return null;
    }

    /** 
     * Order Parser 
     * @param AdserverLoing
     * @param Opportunity
     * @return IDARTParser
     */
    public DART6Parser.IDARTParser createOrderParser(AdServer_Login__c credential, String dartVersion, SObject contextRecord) {
        if (DARTUtil.DART6.equals(dartVersion)) {
            return new DART6Parser.DFPResponseToOrderParser(contextRecord, credential);
        }
        return null;
    }

    /*********************************************************************************************************************************
    @ Method:         createProposalParser
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        method to call to create propsoal parser
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Create method. US-0009927 - Update PG Opportunity Flow 
    *********************************************************************************************************************************/
    public DART6Parser.IDARTParser createProposalParser(AdServer_Login__c credential, String dartVersion, SObject contextRecord) {
        if (DARTUtil.DART6.equals(dartVersion)) {
            return new DART6Parser.DFPResponseToProposalParser(contextRecord, credential);
        }
        return null;
    }


    /** 
     * Person Parser 
     * @param Dart version
     * @return IDARTParser
     */
    public DART6Parser.IDARTParser createSalespersonParser(String dartVersion) {
        if (DARTUtil.DART6.equals(dartVersion)) {
            return new DART6Parser.DFPResponseToSalespersonParser();
        }
        return null;
    }

    /**
     * Ads/LineItem Parser
     * @param AdserverLogin
     * @param dartVersion
     * @param OpportunityLineItem
     * @param mapAdvertiser
     * @return IDARTParser
     */
    public DART6Parser.IDARTParser createAdsParser(AdServer_Login__c credential, String dartVersion, SObject contextRecord, Map<String, Advertiser__c> mapAdvertiser) {
        if (DARTUtil.DART6.equals(dartVersion)) {
            return new DART6Parser.DFPResponseToAdsParser(contextRecord, credential, mapAdvertiser);
        }
        return null;
    }

    /*********************************************************************************************************************************
    @ Method:         createProposalLineItemParser
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        method to call to create propsoal lineitem parser
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Create method. US-0009927 - Update PG Opportunity Flow 
    *********************************************************************************************************************************/
    public DART6Parser.IDARTParser createProposalLineItemParser(AdServer_Login__c credential, String dartVersion, SObject contextRecord, Map<String, Advertiser__c> mapAdvertiser) {
        if (DARTUtil.DART6.equals(dartVersion)) {
            return new DART6Parser.DFPResponseToProposalLineitemParser(contextRecord, credential, mapAdvertiser);
        }
        return null;
    }

    /**
     * Forecast Parser
     * @param Dart version
     * @param QuoteLineItem
     * @param IDARTParser 
     */
    public DART6Parser.IDARTParser createForecastParser(String dartVersion, SObject contextRecord) {
        if (DARTUtil.DART6.equals(dartVersion)) {
            return new DART6Parser.DFPResponseToForecastParser(contextRecord);
        }
        return null;
    }

    /** -------------------------------- 
        Delivery Parser Migrate FROM EU
    ------------------------------- */
    public DART6Parser.IDARTParser createDeliveryParser_EU(String dartVersion, String sobjType)
    {
        if(DARTUtil.DART6.equals(dartVersion))  
        {  
            return new DART6Parser.CSV6ToDeliverParser(sobjType);
        } 
        return null;
    }

}