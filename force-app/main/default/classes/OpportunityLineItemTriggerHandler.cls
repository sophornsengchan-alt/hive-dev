/*********************************************************************************************************************************
@ Class:          OpportunityLineItemTriggerHandler
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        Handler Class for OpportunityLineItem 
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.11.2024 / Mony Nou / Created the class.
@               : 04.11.2024 / Mony Nou / US-0016092 - Certilogo - Approval Process for Pricing Variations
@                 13.11.2024 / Loumang SENG / US-0016115 - Certilogo - Invoice Creation Process - part 2 - data creation
@                 22.11.2024 / Mony Nou / US-0016281 - Certilogo - general usability updates after initial testing
@                 04.12.2024 / Mony Nou / US-0016425 - Error when approving MS&O opportunity
@                 10.03.2025 / Mony Nou / US-0016856 - Certilogo - Cannot Add Shipping Details when Approved
*********************************************************************************************************************************/
public with sharing class OpportunityLineItemTriggerHandler {
    
    private static final String SOQL_OPPORTUNITY_CERTILOGO = 'SELECT Id, Approval_Status__c FROM Opportunity WHERE Id IN:sOppIds AND RecordType.DeveloperName=:OPPRT_CERTILOGO';
    private static final String SOQL_OPPORTUNITYPROD_CERTILOGO = 'SELECT Id FROM OpportunityLineItem WHERE Id IN:oppLineIds AND Opportunity.RecordType.DeveloperName=:OPPRT_CERTILOGO'; //MN-22112024-US-0016281
    private static final String OPPRT_CERTILOGO = 'Certilogo';
    private static final String OPP_APPROVALSTAUS_APPROVED = 'Approved';
    private static final String OPP_APPROVALSTAUS_REJECTED = 'Rejected';
    private static final String OPP_APPROVALSTAUS_PENDING = 'Pending Approval';
    private static final String OPP_APPROVALSTAUS_REQUIRE = 'Requires Approval';
    private static final String OPP_APPROVALSTAUS_NOTREQUIRE = 'Not Required';
    private static final String CUSTOMPERMISSION_CERTILOGOSTDSER = 'Certilogo_Standard_User'; //MN-22112024-US-0016281

    /*****************************************************************************************************************************
    @ Method:   certilogoPreventDeleteFromStandardButton
    @ Author:   Mony Nou (mony.nou@gaea-sys.com)
    @ Event :   Before Delete
    @ Param:    Map<Id,OpportunityLineItem> mapOld
    @ Purpose:  Prevent delete OpportunityLineItem from Standard Button for Certilogo Opportunity
    ----------------------------------------------------------------------------------------------------------------
    @ Change history: 22.11.2024 / Mony Nou / Create method / US-0016281 - Certilogo - general usability updates after initial testing
    @*****************************************************************************************************************************/
    public static boolean isDeleteViaProductConfiguration = false;
    public static boolean isUnlockProduct = false; //MN-10032025-US-0016856
    // public static Set<String> sValidDeletedOppLineIds = new Set<String>();
    public static void certilogoPreventDeleteFromStandardButton (Map<Id,OpportunityLineItem> mapOld) {
        
        Boolean isCertilogoStdUser = FeatureManagement.checkPermission(CUSTOMPERMISSION_CERTILOGOSTDSER);
        if (isDeleteViaProductConfiguration || !isCertilogoStdUser) { return; } //Skip if the delete is via Product Configuration

        List<OpportunityLineItem> certilogoOppLine = new List<OpportunityLineItem>();
        certilogoOppLine = (List<OpportunityLineItem>) ApexSafe.query().doQuery(SOQL_OPPORTUNITYPROD_CERTILOGO, new Map<String, Object> {'oppLineIds' => mapOld.keySet(), 'OPPRT_CERTILOGO' => OPPRT_CERTILOGO});
        
        for (OpportunityLineItem oli : certilogoOppLine) {
            mapOld.get(oli.Id).addError(System.Label.Certilogo_Lock_Product_Error_Message_Delete1);
        }
       
        isDeleteViaProductConfiguration = false; //Reset the flag
    }

    /*****************************************************************************************************************************
    @ Method:   lockProductsOnCertilogoOpportunity
    @ Author:   Mony Nou (mony.nou@gaea-sys.com)
    @ Event :   Before Insert, Before Update, Before Delete
    @ Param:    List<OpportunityLineItem> newList, Map<Id,OpportunityLineItem> mapOld, Boolean isDelete
    @ Purpose:  04.11.2024 / Mony Nou / US-0016092 - Certilogo - Approval Process for Pricing Variations          
    ----------------------------------------------------------------------------------------------------------------
    @ Change history: 04.11.2024 / Mony Nou / US-0016092 - Certilogo - Approval Process for Pricing Variations
    @                 13.11.2024 / Loumang SENG / US-0016115 - Certilogo - Invoice Creation Process - part 2 - data creation
    @                 04.12.2024 / Mony Nou / US-0016425 - Error when approving MS&O opportunity
    @*****************************************************************************************************************************/
    public static void lockProductsOnCertilogoOpportunity(List<OpportunityLineItem> newList, Map<Id,OpportunityLineItem> mapOld, Boolean isDelete) {
        
        Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID) || (Userinfo.getprofileId()==ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
        
        if (isAdmin || isUnlockProduct) { return; } //Finish if the user is Admin

        List<OpportunityLineItem> tmpOppLines = (isDelete) ? mapOld.values() : newList;
        Set<Id> sSkipOppIds = new Set<Id>();

        //Check if it Opportunity Product is update field InvoiceStatus__c
        if (!isDelete && mapOld != null) {
            for (OpportunityLineItem oli : tmpOppLines) {
                if ((oli.InvoiceStatus__c != mapOld.get(oli.Id).InvoiceStatus__c) || (oli.LastBilledDate__c != mapOld.get(oli.Id).LastBilledDate__c)) { sSkipOppIds.add(oli.Id); }//LA-13-11-2024-US-0016115: bypass the OpportunityLineItem.LastBilledDate__c
            }
        }
        
        Map<Id, List<OpportunityLineItem>> mOppOppLineItems = groupLineItemsByOpportunityId(tmpOppLines);
        
        //Find the Opporunity with RecordType = Certilogo and Approval Status = Approved or Pending Approval
        String clause = ' AND Approval_Status__c IN:sApprovalStatus';
        Map<Id, Opportunity> mOpps = new Map<Id, Opportunity>((List<Opportunity>) ApexSafe.query().secCheck(false).doQuery(SOQL_OPPORTUNITY_CERTILOGO + clause, new Map<String, Object> {'sOppIds' => mOppOppLineItems.keySet(), 'OPPRT_CERTILOGO' => OPPRT_CERTILOGO, 'sApprovalStatus' => new List<String>{OPP_APPROVALSTAUS_APPROVED, OPP_APPROVALSTAUS_PENDING}}));

        if (!mOpps.isEmpty()) { 
            for (Id oppId : mOpps.keySet()) {
                for (OpportunityLineItem oli : mOppOppLineItems.get(oppId)) {
                    if (sSkipOppIds.contains(oli.Id)) { continue; } //Skip if the OpportunityLineItem is update field InvoiceStatus__c
                    String errMsg = (isDelete) ? System.Label.Certilogo_Lock_Product_Error_Message_Delete : System.Label.Certilogo_Lock_Product_Error_Message;
                    oli.addError(errMsg);
                }
            }
        }
        
    }

    /*****************************************************************************************************************************
    @ Method:   checkDiscountProductOnCertilogoOpportunity
    @ Author:   Mony Nou (mony.nou@gaea-sys.com)
    @ Event :   After Insert, After Update, After Delete
    @ Param:    List<OpportunityLineItem> newList, Map<Id,OpportunityLineItem> mapOld, Boolean isDelete
    @ Purpose:  04.11.2024 / Mony Nou / US-0016092 - Certilogo - Approval Process for Pricing Variations          
    ----------------------------------------------------------------------------------------------------------------
    @ Change history: 04.11.2024 / Mony Nou / US-0016092 - Certilogo - Approval Process for Pricing Variations  
    @                 04.12.2024 / Mony Nou / US-0016425 - Error when approving MS&O opportunity
    @*****************************************************************************************************************************/
    public static void checkDiscountProductOnCertilogoOpportunity(List<OpportunityLineItem> newList, Map<Id,OpportunityLineItem> mapOld, Boolean isDelete) {

        //Get the list of OpportunityLineItem to process
        List<OpportunityLineItem> tmpOppLines = (isDelete) ? mapOld.values() : newList; 
        
        Map<Id, List<OpportunityLineItem>> mOppOppLineItems = new Map<Id, List<OpportunityLineItem>>();
        
        for (OpportunityLineItem oli : tmpOppLines) {
            if (isDelete || (mapOld == null || oli.OpportunityId != mapOld.get(oli.Id).OpportunityId || oli.Product2Id != mapOld.get(oli.Id).Product2Id)){ //Check if the OpportunityLineItem is delete, new or the OpportunityId is changed
                //Only process with OpportunityLineItem that is from delete, new or the OpportunityId is changed
                if (!mOppOppLineItems.containsKey(oli.OpportunityId)) { mOppOppLineItems.put(oli.OpportunityId, new List<OpportunityLineItem>()); }
                mOppOppLineItems.get(oli.OpportunityId).add(oli);
            }
        }

        if (mOppOppLineItems.isEmpty()) { return; } //Finish if there is no OpportunityLineItem to process

        //Find the Opporunity with RecordType = Certilogo with OpportunityLineItem with Discount
        String query = 'SELECT Id, Approval_Status__c, (SELECT Id FROM OpportunityLineItems WHERE Product2.IsDiscount__c = true) FROM Opportunity WHERE Id IN:oppIds AND RecordType.DeveloperName=:OPPRT_CERTILOGO';
        List<Opportunity> opps = (List<Opportunity>) ApexSafe.query().secCheck(false).doQuery(query, new Map<String, Object> {'oppIds' => mOppOppLineItems.keySet(), 'OPPRT_CERTILOGO' => OPPRT_CERTILOGO});

        //Finish if there is no Opportunity to process
        if (opps.isEmpty()) { return; }

        //Find the OpportunityLineItem with Discount
        List<Opportunity> lstOpp2Update = new List<Opportunity>();
        for (Opportunity opp : opps) {
            
            Integer numDisLineItem = opp.OpportunityLineItems.size();

            //Flag to update Opportunity when the number of OpportunityLineItem with Discount is greater than 0 or if no OpportunityLineItem with Discount but the Approval Status is Require Approval or Rejected
            Boolean toUpdate = (numDisLineItem > 0 || opp.Approval_Status__c == OPP_APPROVALSTAUS_REQUIRE || opp.Approval_Status__c == OPP_APPROVALSTAUS_REJECTED);
            String newStatus = (numDisLineItem > 0) ? OPP_APPROVALSTAUS_REQUIRE : OPP_APPROVALSTAUS_NOTREQUIRE;
            if (toUpdate && opp.Approval_Status__c != newStatus) { 
                opp.Approval_Status__c = newStatus; //Update Approval Status
                lstOpp2Update.add(opp);
            }
        }
        
        try {
            //Update Opportunity
            ApexSafe.dml().secCheck(false).doUpdate(lstOpp2Update, true);

        }catch(Exception e){ EBH_ApexLogger.logError(new List<Exception> { e }, 'OpportunityLineItemTriggerHandler','checkDiscountProductOnCertilogoOpportunity'); }
        

    }

    /*****************************************************************************************************************************
    @ Method:   groupLineItemsByOpportunityId
    @ Author:   Mony Nou (
    @ Param:    List<OpportunityLineItem> oppLineItems
    @ Purpose:  group OpportunityLineItem by OpportunityId
    ----------------------------------------------------------------------------------------------------------------
    @ Change history: 05.11.2024 / Mony Nou / create method
    @*****************************************************************************************************************************/
    private static Map<Id, List<OpportunityLineItem>> groupLineItemsByOpportunityId (List<OpportunityLineItem> oppLineItems) {
        Map<Id, List<OpportunityLineItem>> mOppOppLineItems = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli :oppLineItems) {
            if (!mOppOppLineItems.containsKey(oli.OpportunityId)) { mOppOppLineItems.put(oli.OpportunityId, new List<OpportunityLineItem>()); }
            mOppOppLineItems.get(oli.OpportunityId).add(oli);
        }
        return mOppOppLineItems;
    }

}