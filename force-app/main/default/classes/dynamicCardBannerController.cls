/*****************************************************************************************************************************
@ Method:         dynamicCardBannerController
@ Version:        1.0
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16-12-2021 / Sambath Seng / US-0010845 - [AM] AM Useful links / Landing Page Layout
*****************************************************************************************************************************/
public with sharing class dynamicCardBannerController {
    @AuraEnabled(cacheable=true) 
    public static Card_Banner__mdt pageBannerMetadata(String metadataName){
     
     return [SELECT button_content__c,Button_Label_Name__c,card_background_image__c,card_text_content__c,card_url_link__c,DeveloperName,
              heading_content__c,Id FROM Card_Banner__mdt WHERE DeveloperName =: metadataName];
    }
    /*****************************************************************************************************************************
    @ Method:         sidebarMetadata
    @ Version:        1.0
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String region, String page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16-12-2021 / Sambath Seng / US-0010845 - [AM] AM Useful links / Landing Page Layout
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07-02-2022 / Mony Nou / US-0010884 - [SP] Refactor Useful Links Component
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18-3-2022 / Sambath Seng / US-0011390 - Refactor Useful Links for new Permission Model
    ------------------------------------------------------------------------------------------------------------------------------
    *****************************************************************************************************************************/
    @AuraEnabled(cacheable=true) 
    public static List<Sidebar_Card__mdt> sidebarMetadata(String region, String feature){

        /* MN-07022022-US-0010884
        List<Sidebar_Card__mdt> lstDefaultUsefulLink = [SELECT Is_Mail_To__c,MasterLabel, enable_link__c,main_text__c,redirect_url__c,subtitle_text__c,DeveloperName,
        Id FROM Sidebar_Card__mdt WHERE Region__c=:region AND Available_For_Page__c=''];
        
        List<Sidebar_Card__mdt> lstUsefulLinkForSpecificPage = [SELECT Is_Mail_To__c,MasterLabel, enable_link__c,main_text__c,redirect_url__c,subtitle_text__c,DeveloperName,
        Id FROM Sidebar_Card__mdt WHERE Region__c=:region AND Available_For_Page__c=:page];
        return (!lstUsefulLinkForSpecificPage.isEmpty()) ? lstUsefulLinkForSpecificPage : lstDefaultUsefulLink;
        */

        //MN-07022022-US-0010884
        // Start SB 18-3-2022 US-0011390 - Refactor Useful Links for new Permission Model 
        // Set<String> curUserPMS = new Set<String>();
        // for(PermissionSetAssignment psa: [Select PermissionSet.Name, PermissionSetId, AssigneeId from PermissionSetAssignment Where AssigneeId=:UserInfo.getUserId()]) { curUserPMS.add(psa.PermissionSet.Name); }

        // List<Sidebar_Card__mdt> lstDefUsefulLink = new List<Sidebar_Card__mdt>();
        List<Sidebar_Card__mdt> lstSpecUsefulLink = new List<Sidebar_Card__mdt>();

        List<String> lstFeature = feature != '' ? feature.trim().split('\\s*,[,\\s]*') : new List<String>{};
        // if (String.isNotBlank(page)) lstPages.add(page);
        
        if(!lstFeature.isEmpty()){
            for (Sidebar_Card__mdt sc : [SELECT Display_Order__c, Is_Mail_To__c,MasterLabel, enable_link__c,redirect_url__c,subtitle_text__c,DeveloperName, Id 
                                            FROM Sidebar_Card__mdt WHERE Region__c=:region AND Feature__c IN:lstFeature ORDER BY Display_Order__c ASC NULLS LAST]) {

                //Check if UsefulLink is available for current user's assigned permission set
                // Boolean isValid = true;
                // if (String.isNotBlank(sc.Available_for_Permission_Set__c)) {
                //     for (String pms : curUserPMS) {
                //         isValid = sc.Available_for_Permission_Set__c.contains(pms);
                //         if (isValid) break;
                //     }
                // }
                
                // if (!isValid) continue;

                // if (String.isNotBlank(sc.Available_For_Page__c)) lstSpecUsefulLink.add(sc);
                // else if (lstSpecUsefulLink.isEmpty()) lstDefUsefulLink.add(sc); 
                lstSpecUsefulLink.add(sc);

            }
        }    
        
        return (!lstSpecUsefulLink.isEmpty())?lstSpecUsefulLink:new List<Sidebar_Card__mdt>();
        // End SB 18-3-2022 US-0011390 - Refactor Useful Links for new Permission Model
    }
}