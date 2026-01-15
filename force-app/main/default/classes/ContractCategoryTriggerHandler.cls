/*********************************************************************************************************************************
@ Class:          ContractCategoryTriggerHandler
@ Version:        1.0
@ Author:         SRONG TIN
@ Purpose:        Handler trigger for ContractCategory
US-0016063 - Pricing Configuration Record Lock - Contract & Pricing
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.01.2025 / SRONG TIN / Created the class.
@                 01.08.2025 / Mony Nou / US-0033150 - Ability to manage Pricing and Fee Type for VIP & Add New Fee Type 
*********************************************************************************************************************************/
public with sharing class ContractCategoryTriggerHandler {
    
    private static final String CONTRACTCATEGORY_PRICING         = 'Pricing_Contract_Category';
    private static final String CONTRACTCATEGORY_PRICINGID       =  ApexUtil.getRecordTypeByName('Contract_Category__c',CONTRACTCATEGORY_PRICING).Id;
    private static final String CONTRACTCATEGORY_VIP             = 'VIP_Contract_Category';
    private static final String CONTRACTCATEGORY_VIPID           =  ApexUtil.getRecordTypeByName('Contract_Category__c',CONTRACTCATEGORY_VIP).Id;
    private static final String CONTRACT_LISTINGRECORDTYPE       = 'EBH_ListingAgreement';
    private static final String CONTRACT_ACPRECORDTYPE           = 'EBH_ACP';
    private static final String CONTRACT_VIPRECORDTYPE           = 'VIP_Contracts';
    private final static String CONTRACT_STATUS_PRICING_CONFIGURATION = 'Pricing Configuration';
    private final static String CONTRACT_VIP_RECORDTYPEID = ApexUtil.getRecordTypeByName('Contract',CONTRACT_VIPRECORDTYPE).Id;
    public static final String CONTRACT_LISTING_AGREEMENT_RECORDTYPEID = ApexUtil.getRecordTypeByName('Contract',CONTRACT_LISTINGRECORDTYPE).Id;
    public static final String CONTRACT_ACP_RECORDTYPEID = ApexUtil.getRecordTypeByName('Contract',CONTRACT_ACPRECORDTYPE).Id;
    private final static List<String> CONTRACT_RECORDTYPEIDS = new List<String>{
        CONTRACT_VIP_RECORDTYPEID,
        CONTRACT_LISTING_AGREEMENT_RECORDTYPEID,
        CONTRACT_ACP_RECORDTYPEID
    }; 
	
    /*****************************************************************************************************************************
    @ Method:   validateLockedFieldsUpdate
    @ Author: 	SRONG TIN
    @ Purpose:	US-0016063 - Pricing Configuration Record Lock - Contract & Pricing
	@ Event:	before update
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 15.01.2025 / SRONG TIN / Method Created.
	*****************************************************************************************************************************/
    public static void validateLockedFieldsUpdate(Map<Id, Contract_Category__c> oldMap, Map<Id, Contract_Category__c> newMap) {

        // Check if user has custom permission to bypass locked Record
        If(FeatureManagement.checkPermission('BypassLockedPricingConfiguration')){
            return;
        }
        Set<Id> contrIdsToLocked = new Set<Id>();
        Set<Id> contrIds = new Set<Id>();
        for(Id conCatId : newMap.keySet()){
            Contract_Category__c newContr = newMap.get(conCatId);
            Contract_Category__c oldContr = oldMap.get(conCatId);
            contrIds.add(newContr.Contract__c);
            contrIds.add(oldContr.Contract__c);
        }
        //Get Contract Id base on Status and Record Type
        String soql = 'Select Id From Contract Where Id In :contrIds AND Status = :CONTRACT_STATUS_PRICING_CONFIGURATION AND RecordTypeId IN :CONTRACT_RECORDTYPEIDS';
        List<Contract> contrList = ApexSafe.query().doQuery(soql,new Map<String, Object> {'contrIds' => contrIds, 'CONTRACT_STATUS_PRICING_CONFIGURATION' => CONTRACT_STATUS_PRICING_CONFIGURATION, 'CONTRACT_RECORDTYPEIDS' => CONTRACT_RECORDTYPEIDS});
        Map<Id, Contract> contrMap = new Map<Id, Contract>(contrList);
        //Locked Record base on contrIdsToLocked
        for(Id conCatId : newMap.keySet()){
            Contract_Category__c newContr = newMap.get(conCatId);
            Contract_Category__c oldContr = oldMap.get(conCatId);
            if ( contrMap.containskey(newContr.Contract__c) || contrMap.containskey(oldContr.Contract__c)) {
            	newContr.addError(System.Label.PricingConfigurationLockedFieldsMessage);
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:   validateLockedFieldsInsert
    @ Author: 	SRONG TIN
    @ Purpose:	US-0016063 - Pricing Configuration Record Lock - Contract & Pricing
	@ Event:	before Insert
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 15.01.2025 / SRONG TIN / Method Created.
	*****************************************************************************************************************************/
    public static void validateLockedFieldsInsertDelete(List<Contract_Category__c> listNewConCat, List<Contract_Category__c> listOldConCat) {

        // Check if user has custom permission to bypass locked Record
        If(FeatureManagement.checkPermission('BypassLockedPricingConfiguration')){
            return;
        }
        Set<Id> contrIdsToLocked = new Set<Id>();
        Set<Id> contrIds = new Set<Id>();
        List<Contract_Category__c> listConCat = new List<Contract_Category__c>();
        listConCat.addAll(listNewConCat);
        listConCat.addAll(listOldConCat);
        for(Contract_Category__c conCat : listConCat){
            contrIds.add(conCat.Contract__c);
        }

        //Get Contract Id base on Status and Record Type
        String soql = 'Select Id From Contract Where Id In :contrIds AND Status = :CONTRACT_STATUS_PRICING_CONFIGURATION AND RecordTypeId IN :CONTRACT_RECORDTYPEIDS';
        List<Contract> contrList = ApexSafe.query().doQuery(soql,new Map<String, Object> {'contrIds' => contrIds, 'CONTRACT_STATUS_PRICING_CONFIGURATION' => CONTRACT_STATUS_PRICING_CONFIGURATION, 'CONTRACT_RECORDTYPEIDS' => CONTRACT_RECORDTYPEIDS});
        Map<Id, Contract> contrMap = new Map<Id, Contract>(contrList);
        //Locked Record base on contrIdsToLocked
        for (Contract_Category__c conCat : listConCat) {
            if ( contrMap.containskey(conCat.Contract__c)) {
            	conCat.addError(System.Label.PricingConfigurationLockedFieldsMessage);
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:   deleteMatchingVIPContractCategory
    @ Author: 	Mony Nou
    @ Purpose:	US-0033150 - Ability to manage Pricing and Fee Type for VIP & Add New Fee Type 
	@ Event:	After Delete
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 01.08.2025 / Mony Nou / Method Created.
	*****************************************************************************************************************************/
    public static void deleteMatchingVIPContractCategory(List<Contract_Category__c> oldList) {
        Set<Id> sContractId = new Set<Id>();
        Set<Id> sCPMId = new Set<Id>();
        Set<String> sKey2Delete = new Set<String>();
        List<Contract_Category__c> lstToDelete = new List<Contract_Category__c>();

        for (Contract_Category__c cc : oldList) {
            if (cc.RecordTypeId == CONTRACTCATEGORY_PRICINGID) {
                sContractId.add(cc.Contract__c);
                sCPMId.add(cc.Contract_Pricing_Matrix__c);
                String key = cc.Contract__c + '#' + cc.Contract_Pricing_Matrix__c + '#' + cc.Category__c; 
                sKey2Delete.add(key);
            }
        }

        if (sKey2Delete.isEmpty()) { return; }

        String query = 'SELECT Id, Contract__c, Contract_Pricing_Matrix__c, Category__c FROM Contract_Category__c WHERE RecordTypeId = :CONTRACTCATEGORY_VIPID AND Contract__c IN :sContractId AND Contract_Pricing_Matrix__c IN :sCPMId';
        List<Contract_Category__c> lstVIPContCate = ApexSafe.query().doQuery(query, new Map<String, Object> {
            'CONTRACTCATEGORY_VIPID' => CONTRACTCATEGORY_VIPID,
            'sContractId' => sContractId,
            'sCPMId' => sCPMId
        });

        for (Contract_Category__c vipCC : lstVIPContCate) {
            String key = vipCC.Contract__c + '#' + vipCC.Contract_Pricing_Matrix__c + '#' + vipCC.Category__c;
            if (sKey2Delete.contains(key)) { lstToDelete.add(vipCC); }
        }

        Database.DeleteResult[] deleteResult = ApexSafe.dml().doDelete(lstToDelete,false); //false for partial success
        List<Database.Error> listErrors = new List<Database.Error>();
        for (Database.DeleteResult sr : deleteResult) 
        {
            if (!sr.isSuccess()) { listErrors.addAll(sr.getErrors()); }
        }

        if(!listErrors.isEmpty()) { EBH_ApexLogger.logError(listErrors, 'ContractCategoryTriggerHandler','deleteMatchingVIPContractCategory'); }

    }
}