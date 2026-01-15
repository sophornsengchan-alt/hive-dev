/**
 * @description class controller of Deal Retail Campaign LWC
 * @date        09/09/2021
 * @author      Samnang MUONG
 */
/*********************************************************************************************************************************
@ Class:         DealRetailCampaignCtrl
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 07.12.2021 / Sambath SENG / US-0010837 - [SP - EU Deals] Include start and end date in DRC picklist
*********************************************************************************************************************************/
public with sharing class DealRetailCampaignCtrl {
    //commented as per PHIM-625 requirement
    // @AuraEnabled(cacheable=true)   
    // public static List<EBH_DealRetailCampaign__c> fetchDealRetailCampaign(String siteNumber) {

    //     String sql = 'SELECT Id, Name, EBH_DealTitle__c, EBH_OpenSeatsAvailable__c FROM EBH_DealRetailCampaign__c';
        
    //     if (String.isNotBlank(siteNumber)) sql += ' WHERE RecordType.DeveloperName = \'Deal_Campaign_V3\' AND Status_Seller_Portal__c != \'Draft\' AND Status_Seller_Portal__c != \'New\' AND EBH_Country__c = \''+siteNumber+'\'';

    //     return Database.query(sql);

    // }
    // to get the CDR on the basis of site.
    /*********************************************************************************************************************************
    @ Method:         fetchDealRetailCampaignBySite
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.12.2021 / Sambath SENG / US-0010837 - [SP - EU Deals] Include start and end date in DRC picklist
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=true)   
    public static List<EBH_DealRetailCampaign__c> fetchDealRetailCampaignBySite(String siteNumber) {

        // String sql = 'SELECT Id, Name, EBH_DealTitle__c, EBH_OpenSeatsAvailable__c, EBH_Country__c, EBH_AcceptProposalsStart__c, EBH_AcceptProposalsEnd__c, EBH_DealSlotDisabled__c, EBH_Date__c, EPH_EndDate__c FROM EBH_DealRetailCampaign__c'; //Sambath Seng - 07/12/2021 - US-0010837 add start date & end date field to query
        
        //EBH_Country__c, EBH_AcceptProposalsStart__c
        // String DRC_Record_Type_Id = Schema.SObjectType.EBH_DealRetailCampaign__c.getRecordTypeInfosByName().get('Standard Campaign').getRecordTypeId();
        //Date toDay = date.parse(todaysDateStr);
        // if (String.isNotBlank(siteNumber)) sql += ' WHERE EBH_Country__c =:siteNumber  AND RecordType.DeveloperName =:rtName AND EBH_DealSlotDisabled__c= false AND EBH_AcceptProposalsStart__c <= TODAY AND EBH_AcceptProposalsEnd__c >= TODAY AND EBH_OpenSeatsAvailable__c > 0 ';
        // System.debug('@@@@@sql'+sql);
        //Status_Seller_Portal__c != \'New\' AND 
        List<Seller_Portal_Global_Variables__mdt> lstSql = [SELECT Value_Big__c, DeveloperName FROM Seller_Portal_Global_Variables__mdt WHERE DeveloperName = 'DRC_Picklist_By_Site'];//Sambath Seng - 07/12/2021 - US-0010837
        return (!lstSql.isEmpty() && String.isNotBlank(lstSql[0].Value_Big__c) ? Database.query(lstSql[0].Value_Big__c) : new List<EBH_DealRetailCampaign__c>());//Sambath Seng - 07/12/2021 - US-0010837

    }
}