/*********************************************************************************************************************************
@ Class:         Subscription_Request_TriggerHandler
@ Version:       1.0
@ Author:       vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:     handle for trigger: Subscription_Request_Trigger object (Subscription_Request__c)   
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.12.2021 / vadhanak.voun (vadhanak.voun@gaea-sys.com) / US-0010561 - [AM] Store Account Manager Subscription Requests in Hive
@               : 10.03.2023 / Mony Nou / US-0013309 - [AM] Opt-In Date and Opt-In Effective Date functionality change
@               : 31/08/2023 / Sovantheany Dim / US-0014006 - Updates needed on Subscription Request Record
@               : 29/01/2024 / Sovantheany Dim / US-0014304 - Earliest unsubscribe Date is not updating when the Opt In Effective Date is changed
@               : 09.05.2024 / Bora Chhorn / US-0015148 - PT+ Region Differentiating field on Subscription Request
*********************************************************************************************************************************/
public with sharing class Subscription_Request_TriggerHandler {
    
    final static String STATUS_SUBSCRIBED = 'Subscribed';
    //BR-09-05-2024-US-0015148
    private final static String SOQL_SELLER = 'SELECT Id, SP_Main_Domain__c From Account WHERE Id = :accIds';
    /*****************************************************************************************************************************
    @ Method:   populateFields
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0010561 - [AM] Store Account Manager Subscription Requests in Hive
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: listNew, mapOld
    ------------------------------------------------------------------------------------------------------------------------------
    @ event: before update , before insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.12.2021 / vadhanak.voun (vadhanak.voun@gaea-sys.com) / US-0010561 - [AM] Store Account Manager Subscription Requests in Hive
    @                           / Earliest_Unsubscribe_Date__c is set to the last day of the third calendar month after the opt-in date
    @               : 10.03.2023 / Mony Nou / US-0013309 - [AM] Opt-In Date and Opt-In Effective Date functionality change
    @               : 31/08/2023 / Sovantheany Dim / US-0014006 - Updates needed on Subscription Request Record
    @               : 29/01/2024 / Sovantheany Dim / US-0014304 - Earliest unsubscribe Date is not updating when the Opt In Effective Date is changed  
    @               : 09.05.2024 / Bora Chhorn / US-0015148 - PT+ Region Differentiating field on Subscription Request 
    *****************************************************************************************************************************/
    public static void populateFields(List<Subscription_Request__c> listNew,Map<Id,Subscription_Request__c> mapOld)
    {
        List<Subscription_Request__c> listSub = new List<Subscription_Request__c>(); //BR-09-05-2024-US-0015148
        Boolean isNew = (mapOld==null);//TH:US-0014304 : add on Create new Subscription Request
        RecordType rt_AM = ApexUtil.getRecordTypeByName('Subscription_Request__c', 'Account_Manager');
        for(Subscription_Request__c sub: listNew)
        {
            //BR-09-05-2024-US-0015148
            if(isNew && sub.RecordTypeId == rt_AM.Id){
                listSub.add(sub);
            }
            /* MN-10032023-US-0013309
            if(sub.Opt_In_Date__c <> null && sub.Opt_In_Date__c <> subOld.Opt_In_Date__c <> null && sub.Earliest_Unsubscribe_Date__c == null && sub.RecordTypeId == rt_AM.Id)
            {
                sub.Earliest_Unsubscribe_Date__c = sub.Opt_In_Date__c.addMonths(4).toStartOfMonth().addDays(-1);    // is set to the last day of the third calendar month after the opt-in date
            }
            */
            //MN-10032023-US-0013309
            //if (sub.Opt_In_Effective_Date__c != subOld.Opt_In_Effective_Date__c && sub.Earliest_Unsubscribe_Date__c == null && sub.RecordTypeId == rt_AM.Id ) {
            //TH:US-0014304
            if (((isNew && sub.Opt_In_Effective_Date__c != null) || (!isNew && sub.Opt_In_Effective_Date__c != null && sub.Opt_In_Effective_Date__c != mapOld.get(sub.Id).Opt_In_Effective_Date__c)) && sub.RecordTypeId == rt_AM.Id) {
                
                sub.Earliest_Unsubscribe_Date__c = sub.Opt_In_Effective_Date__c.addMonths(3).addDays(-1);
            }

            if(!isNew && sub.Status__c == STATUS_SUBSCRIBED && sub.Status__c <> mapOld.get(sub.Id).Status__c && sub.RecordTypeId == rt_AM.Id)
            {
                //sub.Opt_In_Effective_Date__c = Date.today(); //MN-10032023-US-0013309:AC3 Remove it
                sub.Opt_In_Date__c = Date.today(); //MN-10032023-US-0013309
                //BR-09-05-2024-US-0015148
                if(sub.Region__c == ApexUtil.MAP_COUNTRY_CODE.get('DE')){
                    sub.Monthly_Subscription_Fee__c = Decimal.valueOf(System.Label.SR_Monthly_Subscription_Fee); //TH:US-0014006
                } else if (sub.Region__c == ApexUtil.MAP_COUNTRY_CODE.get('UK')){
                    sub.Monthly_Subscription_Fee__c = Decimal.valueOf(System.Label.SR_Monthly_Subscription_Fee_UK); //BR-09-05-2024-US-0015148
                }
            }
        }
        //BR-09-05-2024-US-0015148
        if(!listSub.isEmpty()){
            populateFieldsBaseOnSPDomain(listSub);
        }
    }

    /*****************************************************************************************************************************
    @ Method:   prePopulateFields
    @ Version:  1.0
    @ Author:   Bora Chhorn (bora.chhorn@gaea-sys.com)
    @ Purpose:  US-0015148 - PT+ Region Differentiating field on Subscription Request
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: listNew
    ------------------------------------------------------------------------------------------------------------------------------
    @ event: before insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: Bora Chhorn / Create method   
    *****************************************************************************************************************************/
    private static void populateFieldsBaseOnSPDomain(List<Subscription_Request__c> listNew){

        Set<Id> accIds = new Set<Id>();
        for(Subscription_Request__c sub : listNew){
            accIds.add(sub.Seller__c);
        }

        List<Account> lstAccount = (List<Account>) ApexSafe.query().doQuery(SOQL_SELLER, new Map<String, Object>{'accIds' => accIds});
        Map<Id, Account> accountMap = new Map<Id, Account>(lstAccount);

        for(Subscription_Request__c subReq : listNew){
            Account acc = accountMap.get(subReq.Seller__c);
            if(acc.SP_Main_Domain__c == SEP_Helper.SEP_Domain_DE){
                subReq.Region__c = ApexUtil.MAP_COUNTRY_CODE.get('DE');
                subReq.Monthly_Subscription_Fee__c = Decimal.valueOf(System.Label.SR_Monthly_Subscription_Fee);
                subReq.CurrencyIsoCode = 'EUR';
            } else if(acc.SP_Main_Domain__c == SEP_Helper.SEP_Domain_UK){
                subReq.Region__c = ApexUtil.MAP_COUNTRY_CODE.get('UK');
                subReq.Monthly_Subscription_Fee__c = Decimal.valueOf(System.Label.SR_Monthly_Subscription_Fee_UK);
                subReq.CurrencyIsoCode = 'GBP';
            }
        }
    }
}