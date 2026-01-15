/*********************************************************************************************************************************
@ Class:        ProTraderRegistrationController
@ Version:      1.0
@ Author:       Acmatac Seing (acmatac.seing@gaea-sys.com)
@ Purpose:      Controller for proTraderRegistration lwc  
@               US-0014258 - Ph 1 - 3 Pro Trader Registration Page - Registration availability and non-availability
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.11.2023 / Acmatac Seing / Created the class.
*********************************************************************************************************************************/
public with sharing class ProTraderRegistrationController {

    /*********************************************************************************************************************************
    @ Method:       initData
    @ Version:      1.0
    @ Author:       Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:      US-0014258 - Init Data for proTraderRegistration lwc
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.11.2023 / Acmatac Seing / Created the Method.
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> initData(String cohortSellerId){
        Map<String,Object> mapResult = new Map<String,Object>();
        User currentUser = [SELECT Id, Name, Contact.Name, Contact.Email, Contact.Account.Name, Contact.Phone, ContactId FROM User WHERE Id=:UserInfo.getUserId()];
        Date currentDate = Date.today();
        String accManagerId = '';
        String accManagerCalendlyLink = '';
        String accManagerName = '';
        String accManagerEmail = '';
        String accManagerImage = '';
        Boolean registrationIsOver = false;
        for(BoB_Seller__c oBs: Database.query(AccountManagementController.SOQL_COHORT_SELLER+' WHERE Id = :cohortSellerId')){
            registrationIsOver = oBs.RegistrationCloseDate__c <= currentDate;
            accManagerId = oBs.Account_Manager__c;
            accManagerCalendlyLink = oBs.Account_Manager_CalendlyLink__c;
        }
        Boolean isEligibleFor_CatDashboard = AccountManagementController.checkEligibilityFor_CatDashboard(cohortSellerId);
        Boolean isEligibleFor_RegistrationCat = AccountManagementController.checkEligibilityFor_RegistrationCat(cohortSellerId);
        if(String.isNotBlank(accManagerId)){
            for(User oAccManager : (List<User>) DataCreator.getRecordbyId(User.sObjectType, accManagerId)){
                accManagerName = oAccManager.Name;
                accManagerEmail = oAccManager.Customer_facing_eMail__c;
                accManagerImage = oAccManager.MediumPhotoUrl;
            }
        }

        mapResult.put('registrationIsOver', registrationIsOver);
        mapResult.put('accManagerId', accManagerId);
        mapResult.put('accManagerCalendlyLink', accManagerCalendlyLink);
        mapResult.put('accManagerName', accManagerName);
        mapResult.put('accManagerEmail', accManagerEmail);
        mapResult.put('accManagerImage', accManagerImage);
        mapResult.put('isEligibleFor_CatDashboard', isEligibleFor_CatDashboard);
        mapResult.put('isEligibleFor_RegistrationCat', isEligibleFor_RegistrationCat);
        mapResult.put('currentUser', currentUser);
        
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:       getProTraderProgramEligibility
    @ Version:      1.0
    @ Author:       Acmatac Seing
    @ Purpose:      US-0014258 - Init Data for proTraderRegistration lwc
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.12.2023 / Acmatac Seing / Created the Method.
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getProTraderProgramEligibility(String sellerId){
        Map<String,Object> mapResult = new Map<String,Object>();
        try{
            Map<String, Seller_Portal_Setting__mdt> mapEligibleAccounts = AccountManagementController.getSPMetadata(new Set<String>{AccountManagementController.ELIGIBLE_FOR_PROTRADER_PROGRAM});
            Map<Id, BoB_Seller__c> mapCohortSeller = new Map<Id, BoB_Seller__c>();
            BoB_Seller__c cohortSeller = new BoB_Seller__c();
            Boolean isEligibleFor_Protrader_Program = false;
            if(mapEligibleAccounts.containsKey(AccountManagementController.ELIGIBLE_FOR_PROTRADER_PROGRAM)){
                Seller_Portal_Setting__mdt spsProtraderEligible = mapEligibleAccounts.get(AccountManagementController.ELIGIBLE_FOR_PROTRADER_PROGRAM);
                for(BoB_Seller__c oBS: Database.query(AccountManagementController.SOQL_COHORT_SELLER + ' WHERE ' + spsProtraderEligible.Filter_Values__c + ' AND Seller__c =:sellerId LIMIT 1')){
                    cohortSeller = oBS;
                    isEligibleFor_Protrader_Program = true;
                }

            }
            Boolean isEligibleFor_CatDashboard = isEligibleFor_Protrader_Program ? AccountManagementController.checkEligibilityFor_CatDashboard(cohortSeller.Id) : false;
            Boolean isEligibleFor_RegistrationCat = isEligibleFor_Protrader_Program ? AccountManagementController.checkEligibilityFor_RegistrationCat(cohortSeller.Id) : false;

            mapResult.put('cohortSeller', cohortSeller);
            mapResult.put('isEligibleFor_Protrader_Program', isEligibleFor_Protrader_Program);
            mapResult.put('isEligibleFor_CatDashboard', isEligibleFor_CatDashboard);
            mapResult.put('isEligibleFor_RegistrationCat', isEligibleFor_RegistrationCat);

            mapResult.put('status','ok');
        }catch(Exception ex)
        {
            mapResult.put('status','ko'); mapResult.put('error',ex.getMessage()); mapResult.put('error_detail',ex.getStackTraceString());
        }
        return mapResult;
    }
}