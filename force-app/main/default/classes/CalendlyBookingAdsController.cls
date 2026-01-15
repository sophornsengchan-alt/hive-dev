/*********************************************************************************************************************************
@ Class:          CalendlyBookingAdsController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.Oct.2024 / Sovantheany Dim / US-0015390 - ADS - Create an Advertising program component for Bookings
*********************************************************************************************************************************/
public with sharing class CalendlyBookingAdsController {
    public final static String SOQL_SELLER = 'SELECT Id, Name, Brand_Engagement_Lead__c FROM Account Where Id =: sellerId Limit 1';   
    public final static String SOQL_CURRENTUSER= 'SELECT Id, Name, Contact.Name, Contact.Email, Contact.Account.Name, Contact.Phone, ContactId FROM User WHERE Id=: currentUserId';
    public final static String ELIGIBLE_FOR_ADS_ACCOUNT_MANAGER = 'Booking_Portal_Eligibility';
    private final static String ACCOUNT_RT_SELLER = 'EBH_Seller';
    public final static String SOQL_COHORT_SELLER = 'SELECT Id, Name, Seller__c, Seller_Name__c, Ads_Partner_Manager__c FROM BoB_Seller__c';
    private final static String  ELIGIBLE_PORTAL_MDT = 'SELECT Id,DeveloperName,Eligibility_Criteria__c FROM Portal_Eligibility__mdt WHERE DeveloperName IN:metaDataRecord';
    private final static String SOQL_ACCOUNT_CONTACT_RELATION = 'Select Id,AccountId,Account.Name From AccountContactRelation';

    /*****************************************************************************************************************************
    @ Method:   getAllAccountIdsRelated
    @ Version:  1.0
    @ Author:   sovantheany dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  US-0015390 - ADS - Create an Advertising program component for Bookings
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.10.2024 / sovantheany dim / US-0015390 - ADS - Create an Advertising program component for Bookings
    *****************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getAllAccountIdsRelated()
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        
        User currentUser = new User();
        String soql = 'Select Id,ContactId From User Where Id=:userId';
        List<User> lstUsers = (List<User>) ApexSafe.query().doQuery(soql,new Map<String, Object> {'userId' => UserInfo.getUserId()});
        if (!lstUsers.isEmpty()) {currentUser = lstUsers[0];}
        Id contactId = currentUser.ContactId;
        List<Account> lstAcc = new List<Account>();
        Map<Id, BoB_Seller__c> mapResultEligibleCohortSeller = new Map<Id,BoB_Seller__c>();
        if (String.isNotBlank(contactId)) {

            Set<String> accountIdsRelated = new Set<String>();
            String sWhere = ' Where Account.RecordType.DeveloperName ='+ApexUtil.closeSQoute(ACCOUNT_RT_SELLER)+' and ContactId='+ApexUtil.closeSQoute(contactId);

            soql = SOQL_ACCOUNT_CONTACT_RELATION + sWhere;
            List<AccountContactRelation> lstAccConRel = (List<AccountContactRelation>) ApexSafe.query().doQuery(soql);
        
            for(AccountContactRelation acr : lstAccConRel) {
                accountIdsRelated.add(acr.AccountId);
                lstAcc.add(new Account(Id = acr.AccountId, Name = acr.Account.Name));
            }
            mapResultEligibleCohortSeller = getEligibleCohortSeller(accountIdsRelated ,ELIGIBLE_FOR_ADS_ACCOUNT_MANAGER);
            
        }
        mapResult.put('listRelatedAccounts', lstAcc);
        mapResult.put('mapResultEligibleCohortSeller', mapResultEligibleCohortSeller);
        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:   getEligibleCohortSeller
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  US-0015390 - ADS - Create an Advertising program component for Bookings
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.Oct.2024 / Sovantheany Dim / US-0015390 - ADS - Create an Advertising program component for Bookings
    *****************************************************************************************************************************/
    private static  Map<Id, BoB_Seller__c> getEligibleCohortSeller(Set<String> sellerIds, String elibibleMDT){
        Map<String, Portal_Eligibility__mdt> mapEligibleAccounts = getBookingPortalMetadata(new Set<String>{elibibleMDT});
        Map<Id, BoB_Seller__c> mapCohortSeller = new Map<Id, BoB_Seller__c>();
        if(mapEligibleAccounts.containsKey(elibibleMDT)){

            Portal_Eligibility__mdt bookingPortalEligible = mapEligibleAccounts.get(elibibleMDT);

            String soql = SOQL_COHORT_SELLER + ' WHERE (' + bookingPortalEligible.Eligibility_Criteria__c + ' ) AND Seller__c IN: sellerIds';
         
            List<BoB_Seller__c> lstBobSeller = (List<BoB_Seller__c>) ApexSafe.query().doQuery(soql, new Map<String, Object>{'sellerIds' => sellerIds});
            for(BoB_Seller__c oBS: lstBobSeller) {
                mapCohortSeller.put(oBS.Seller__c, oBS);
            }
        }
        return mapCohortSeller;
    }

    /*****************************************************************************************************************************
    @ Method:   getBookingPortalMetadata
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  US-0015390 - ADS - Create an Advertising program component for Bookings
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.Oct.2024 / Sovantheany Dim / US-0015390 - ADS - Create an Advertising program component for Bookings
    *****************************************************************************************************************************/
    public static Map<String, Portal_Eligibility__mdt> getBookingPortalMetadata(Set<String> metaDataRecord){
        Map<String, Portal_Eligibility__mdt> mapEligibleAccounts = new Map<String, Portal_Eligibility__mdt>();
        if (!metaDataRecord.isEmpty()) {
            for(Portal_Eligibility__mdt portalEligible: (List<Portal_Eligibility__mdt>) ApexSafe.query().secCheck(false).doQuery(ELIGIBLE_PORTAL_MDT, new Map<String, Object>{'metaDataRecord' => metaDataRecord})){
                mapEligibleAccounts.put(portalEligible.DeveloperName, portalEligible);
            }
        }
        return mapEligibleAccounts;
    }

    /*********************************************************************************************************************************
    @ Method:       initData
    @ Version:      1.0
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0015390 - ADS - Create an Advertising program component for Bookings
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.Oct.2024 / Sovantheany Dim / Created the Method.
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> initData(String cohortSellerId){
        Map<String,Object> mapResult = new Map<String,Object>();
        String accManagerId = '';
        String accManagerName = '';
        String accManagerEmail = '';
        String accManagerImage = '';
        String accManagerCalendlyLink = '';
        ProTraderSellerDashboardController.ProTraderSellerDashboardWrapperClass cohortSellerData = new ProTraderSellerDashboardController.ProTraderSellerDashboardWrapperClass();
        Id currentUserId = UserInfo.getUserId();
        List<User> currentUsers = (List<User>) ApexSafe.query().doQuery(SOQL_CURRENTUSER,new Map<String, Object> {'currentUserId' => currentUserId});
        String soql = SOQL_COHORT_SELLER + ' Where Id =: cohortSellerId';
        for(BoB_Seller__c bs : (List<BoB_Seller__c>) ApexSafe.query().doQuery(soql, new Map<String, Object>{'cohortSellerId' => cohortSellerId})){
            cohortSellerData.cohortSellerParentSellerName = bs.Seller_Name__c;
            accManagerId = bs.Ads_Partner_Manager__c;

        }
        if(String.isNotBlank(accManagerId)){
            for(User oAccManager : (List<User>) DataCreator.getRecordbyId(User.sObjectType, accManagerId)){
                accManagerName = oAccManager.Name;
                accManagerEmail = oAccManager.Customer_facing_eMail__c;
                accManagerImage = oAccManager.MediumPhotoUrl;
                accManagerCalendlyLink = oAccManager.Calendly__CalendlyLink__c;
            }
        }
        mapResult.put('accManagerName', accManagerName);
        mapResult.put('accManagerEmail', accManagerEmail);
        mapResult.put('accManagerImage', accManagerImage);
        mapResult.put('accManagerCalendlyLink', accManagerCalendlyLink);
        mapResult.put('currentUser', currentUsers[0]);
        mapResult.put('cohortSellerData', cohortSellerData);
        return mapResult;
    }
}