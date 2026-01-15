/*****************************************************************************************************************************
@ Method:         dynamicHelpTextController
@ Version:        1.0
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16-12-2021 / Sambath Seng / US-0010845 - [AM] AM Useful links / Landing Page Layout
07-11-2023 / Sharath / US-0012584 - ✓[TS]Delete Metadata created for Trusted Shops
4/7/2024 / Sovantheany Dim/ US-0015332 - Update the Account Management ineligible message
******************************************************************************************************************************/
public with sharing class dynamicHelpTextController {
   @AuraEnabled(cacheable=true) 
    public static Component_help_text_setting__mdt helpTextMetadata(String metadataName){
     //TH: US-0015332 add Bigger_Body_Test__c
     return [SELECT Help_Text__c,DeveloperName,Heading__c,Inner_Help_Text__c,Bigger_Body_Test__c,
              Id FROM Component_help_text_setting__mdt where DeveloperName=:metadataName];
    }
    
    @AuraEnabled(cacheable=true) 
    public static list<Component_help_text_setting__mdt> accountManagementMetadata(String firstMetadataName, String secondMetadataName, String thirdMetadataName){
        return [SELECT DeveloperName,Help_Text__c,Bigger_Body_Test__c,Id FROM Component_help_text_setting__mdt where DeveloperName=:firstMetadataName OR DeveloperName=:secondMetadataName OR DeveloperName=:thirdMetadataName ORDER BY DeveloperName ASC];
    }
}