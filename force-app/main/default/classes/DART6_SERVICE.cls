/*
*   2020-09-23 - US-0008273 Acmatac SEING -> Update DFP version to v202008
*   2021-07-27 - US-0009961 Acmatac SEING -> Update DFP version to v202105
*   2022-03-11 - US-0011408 Loumang SENG  -> Update DFP version to v202202
*   2022-11-21 - US-0012883 Sophal Noch   -> Upgrade GAM version to v202211
*   2023.07.11 - US-0013954 Sophal Noch   -> Upgrade GAM version to v202305
*   2024-02-19 - US-0014655 Sophal Noch   -> Upgrade GAM version from v202305 to v202402 
*/
public with sharing class DART6_SERVICE {
	public static final String DFP_API_ENDPOINT_PREFIX = 'https://ads.google.com/apis/ads/publisher/';
    public static final String DFP_XML_ENDPOINT_PREFIX = 'https://www.google.com/apis/ads/publisher/';
   //public static final String DFP_API_VER = 'v202105';
    // public static final String DFP_API_VER = 'v202202'; // v202202
    // public static final String DFP_API_VER = 'v202211';  // 2022-11-21 / Sophal Noch / US-0012883
    // public static final String DFP_API_VER = 'v202305'; //  2023.07.11 / Sophal Noch / US-0013954
    public static final String DFP_API_VER = 'v202402'; // 2024.02.19 / Sophal Noch / US-0014655

    //public static final String DFP_API_ENDPOINT = DFP_API_ENDPOINT_PREFIX + DFP_API_VER;
    //public static final String DFP_XML_NS = DFP_XML_ENDPOINT_PREFIX + DFP_API_VER;

    static Map<String, Webservice_Settings__c> mpWS = Webservice_Settings__c.getall();
    public static final string CUSTOMSETTING_NAME_API = 'DFP_API_ENDPOINT';
    static final string CUSTOMSETTING_NAME_XML = 'DFP_XML_NAMESPACE';
    
    public static final String DFP_API_ENDPOINT = mpWS.containsKey(CUSTOMSETTING_NAME_API) && String.isNotBlank(mpWS.get(CUSTOMSETTING_NAME_API).Endpoint__c) ? mpWS.get(CUSTOMSETTING_NAME_API).Endpoint__c : DFP_API_ENDPOINT_PREFIX + DFP_API_VER;
    public static final String DFP_XML_NS = mpWS.containsKey(CUSTOMSETTING_NAME_XML) && String.isNotBlank(mpWS.get(CUSTOMSETTING_NAME_XML).Endpoint__c) ? mpWS.get(CUSTOMSETTING_NAME_XML).Endpoint__c : DFP_XML_ENDPOINT_PREFIX + DFP_API_VER;
}