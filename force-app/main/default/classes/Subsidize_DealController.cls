/*********************************************************************************************************************************
@ Class:        Subsidize_DealController
@ Version:      1.0
@ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:      controller for aura: Subsidize_Deal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.01.2022  / Vadhanak Voun / Created the Class.
@ Change history: 14.01.2022 / Vadhanak Voun / US-0010894 - Ability for CM to convert Unsubsidized Deal to Subsidized Deal
@ Change history: 08.06.2022 / Mony Nou / US-0011648 - PayPal validation for Unsub to Sub Deal and new picklist values for Vertical/catogery
@                 20.04.2023 / Sambath Seng / US-0013364 - Existing Deal_V2 Validation Rules require updates
*********************************************************************************************************************************/
public with sharing class Subsidize_DealController {

    private final static String DEAL_SITE_US = '0'; // Sambath Seng 20.04.2023 US-0013364 - Existing Deal_V2 Validation Rules require updates
    private final static String DEAL_SITE_CA = '2'; // Sambath Seng 20.04.2023 US-0013364 - Existing Deal_V2 Validation Rules require updates
     
     /*****************************************************************************************************************************
    @ Method:   apexInit
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:  String window_id, String selectedId (single selected unsub deal id)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.01.2022 / Vadhanak Voun / US-0010894 - Ability for CM to convert Unsubsidized Deal to Subsidized Deal
    @               : 01.04.2022 / SRONG TIN / US-0011448 - Additional validation for NA un-sub to sub conversion rule
    @               : 08.06.2022 / Mony Nou / US-0011648 - PayPal validation for Unsub to Sub Deal and new picklist values for Vertical/catogery
    @               : 20.04.2023 / Sambath Seng / US-0013364 - Existing Deal_V2 Validation Rules require updates
@               : 17.01.2024 / Venkata Sharath Simhadri / US-0014529
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexInit(String window_id,String selectedId)
    {
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok','id'=>selectedId};
        EBH_Deal__c deal = [Select Id,RecordType.DeveloperName,EBH_DealPrice__c,EBH_Status__c,EBH_BusinessName__c,EBH_BusinessName__r.NA_Deals_Subsidy_PayPal_Email__c,EBH_BusinessName__r.NA_Deal_Program_Vetted__c,EBH_DealSiteId__c from EBH_Deal__c Where Id=:selectedId];
        String errorMsg = '';
        Set<String> setAllow = new Set<String>{'Ops Review','CM Review'};

        //If the Account for the Deal has: [ 'NA Deals Subsidy Paypal Email' = NULL ], system will return message 'This Seller is not eligible to receive subsidy.'
        //VS-01172024-US-0014529 - Add EBH_DealSiteId__c into IF Condition
        if(deal.EBH_BusinessName__r.NA_Deals_Subsidy_PayPal_Email__c==null && deal.EBH_DealSiteId__c != DEAL_SITE_US)
        {
            errorMsg = System.Label.Subsidize_Deal_Msg_noteligible +'\n';
        }

        //rt_Unsub 'Deal_V3'
        //If Deals status != 'Ops Review' or 'CM Review', system will return message 'This Deal is not eligible to be converted. You can create a subsidized Deal with the standard process if needed.'
        // SRONG TIN - 01.04.2022 : US-0011448 for ac2
        //MN-08062022-US-0011648- Add EBH_BusinessName__r.NA_Deals_Subsidy_PayPal_Email__c into IF Condition 
        //VS-01172024-US-0014529 - Add EBH_DealSiteId__c into IF Condition
        if(!setAllow.contains(deal.EBH_Status__c) || deal.RecordType.DeveloperName <> 'Deal_V3' || !deal.EBH_BusinessName__r.NA_Deal_Program_Vetted__c || (String.isBlank(deal.EBH_BusinessName__r.NA_Deals_Subsidy_PayPal_Email__c) && deal.EBH_DealSiteId__c != DEAL_SITE_US))
        {
            errorMsg = System.Label.Subsidize_Deal_Msg_noteligible2 +'\n';
            // SRONG TIN - 01.04.2022 : US-0011448 for ac2
            // if(!deal.EBH_BusinessName__r.NA_Deal_Program_Vetted__c){  //MN-08062022-US-0011648-
            //MN-08062022-US-0011648- Add EBH_BusinessName__r.NA_Deals_Subsidy_PayPal_Email__c into IF Condition 
            //VS-01172024-US-0014529 - Add EBH_DealSiteId__c into IF Condition
            if(!deal.EBH_BusinessName__r.NA_Deal_Program_Vetted__c || (String.isBlank(deal.EBH_BusinessName__r.NA_Deals_Subsidy_PayPal_Email__c) && deal.EBH_DealSiteId__c != DEAL_SITE_US)){
                errorMsg += System.Label.Subsidize_Deal_Msg_noteligible3 +'\n';
            }
        }

        List<Contact> listCon = [Select Id,Name from Contact Where AccountId=:deal.EBH_BusinessName__c AND Contact_Role__c INCLUDES('Deals') Limit 1]; //NA Deals Contracts
        if(listCon.isEmpty())
        {
            errorMsg += System.Label.Subsidize_Deal_Msg_invalidContact;
        }

        if(String.isNotBlank(errorMsg))
        {
            mapResult.put('status','ko');mapResult.put('error',errorMsg);         
        } else
        {   
            User curUser = [Select Id,ManagerId From User Where Id=: UserInfo.getUserId()];
            
            deal.OwnerId = UserInfo.getUserId();
            deal.RecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2').Id;
            deal.EBH_DealRetailCampaign__c = null;
            deal.EBH_SellerPrice__c = deal.EBH_DealPrice__c;
            deal.EBH_Status__c = 'New'; 
            // Sambath Seng 20.04.2023 US-0013364 - Existing Deal_V2 Validation Rules require updates
            if(deal.EBH_DealSiteId__c == DEAL_SITE_US || deal.EBH_DealSiteId__c == DEAL_SITE_CA){
                deal.Merchant_Approver__c = curUser.ManagerId;
                deal.Director__c = curUser.ManagerId;      
            }
            deal.Seller_Approver_1__c  =  listCon.isEmpty()?null:listCon[0].Id;

            try {               
              
                update deal;             

            }catch(DMLException dex) {mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
            

        }
        return mapResult;
    }

     
}