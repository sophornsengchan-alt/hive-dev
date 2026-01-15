/*********************************************************************************************************************************
@ Class:          GleanAssistantController
@ Version:        1.0
@ Author:         Sovantheany Dim
@ Purpose:        US-0016843 - Integration of Glean with Seller CRM via Salesforce Chat Component
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.04.2025 / Sovantheany Dim / Created the class.
*********************************************************************************************************************************/
public with sharing class GleanAssistantController {
    public String applicationId{get; set;}
    public GleanAssistantController(){
        applicationId = ApexPages.currentPage().getParameters().get('applicationID');
        applicationId= String.isBlank(applicationId)?'': String.escapeSingleQuotes(applicationId);
    }
    /*********************************************************************************************************************************
    @ Method:          fetchActionMetadata
    @ Parameter :      String objectAPIName
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.02.2025 / Sovantheany Dim / US-0016318 - 9.1 - Seller Portal - My Subsidized Deal Contract Agreements Page
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=true) 
    public static String fetchGleanAssistantMetadata(String objectAPIName){
        Set<string> setObjectAPIName = new Set<string>{'Default'};
        setObjectAPIName.add(objectAPIName);
        String soqlMDT = 'select Application_Id__c,Object_Name__c from Glean_Assistant__mdt where Object_Name__c in :setObjectAPIName';
        Map<String,String> mapMdt = new Map<String,String>();
        for(Glean_Assistant__mdt mdta : (List<Glean_Assistant__mdt>) ApexSafe.query().secCheck(false).doQuery(soqlMDT,new Map<String, Object> {'setObjectAPIName' => setObjectAPIName})){
            if (String.isNotBlank(mdta.Application_Id__c)){
                mapMdt.put(mdta.Object_Name__c,mdta.Application_Id__c);
            }
        }
        return mapMdt.containsKey(objectAPIName) ? mapMdt.get(objectAPIName) : mapMdt.get('Default');
    }
}