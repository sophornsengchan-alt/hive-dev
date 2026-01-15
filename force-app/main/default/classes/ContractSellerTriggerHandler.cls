/*********************************************************************************************************************************
@ Class:          ContractSellerTriggerHandler
@ Author:         Acmatac Seing
@ Purpose:        US-0015385 - Class handler for ContractSellerTrigger.trigger
@ Change history: 17.05.2024 / Acmatac Seing / Class Creation
                : 09.01.2025 / Sambath Seng / US-0016114 - Pricing Configuration Record Lock - CPM, Contract other
                : 17.01.2025 / Mony Nou / US-0016395 - Set initiating contract seller as primary
*********************************************************************************************************************************/
public with sharing class ContractSellerTriggerHandler {
    private final static String CONTRACT_RECORDTYPE_3PP = 'Three_PP_Pricing_Program';
    public final static String CONTRACT_SELLER_STATUS_ACTIVE = 'Active';
    public final static String CONTRACT_SELLER_STATUS_INACTIVE = 'Inactive';
    public final static String CONTRACT_SELLER_SOQL = 'SELECT Id, EBH_BusinessName__c, StartDate__c FROM EBH_ContractSeller__c';
    public final static String CONTRACT_SOQL = 'SELECT Id, Status, RecordType.DeveloperName FROM Contract'; // SB 09.01.2025 US-0016114
    private final static String CONTRACT_STATUS_PRICING_CONFIGURATION = 'Pricing Configuration'; // SB 09.01.2025 US-0016114
    private final static String CONTRACT_RECORDTYPE_VIP = 'VIP_Contracts'; // SB 09.01.2025 US-0016114
    private final static String CONTRACT_RECORDTYPE_LA = 'EBH_ListingAgreement'; // SB 09.01.2025 US-0016114
    private final static String CONTRACT_RECORDTYPE_ACP = 'EBH_ACP'; // SB 09.01.2025 US-0016114
    private final static Set<String> CONTRACT_RECORDTYPE_FOR_PRICING_CONFIGURATION = new Set<String>{
        CONTRACT_RECORDTYPE_VIP,
        CONTRACT_RECORDTYPE_LA,
        CONTRACT_RECORDTYPE_ACP
    };
    /*****************************************************************************************************************************
    @ Method:   validate3PPContractSeller
    @ Author: 	Acmatac Seing
    @ Purpose:	US-0015385 - Validates that for there is no existing active or inactive contract seller 
                with the same seller and a start date that falls within the same range. 
	@ Event:	after insert , after update
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 17.05.2024 / Acmatac Seing / Method Creation
	*****************************************************************************************************************************/
    public static void validate3PPContractSeller(Map<Id,EBH_ContractSeller__c> oldMap, Map<Id,EBH_ContractSeller__c> newMap){
        Set<Date> csStartDates = new Set<Date>();
        Set<Id> csIds = new Set<Id>();
        Set<Id> csSellerIds = new Set<Id>();
        Set<Id> duplicatedCSIds = new Set<Id>();
        for(EBH_ContractSeller__c newCS : newMap.values()){
            if(newCS.Contract_Record_Type_DeveloperName__c != CONTRACT_RECORDTYPE_3PP || newCS.StartDate__c == null ) {
                return;
            }
            if(String.isNotBlank(newCS.EBH_BusinessName__c) && String.isNotBlank(newCS.EBH_ContractNumber__c) 
                && (newCS.Status__c == CONTRACT_SELLER_STATUS_ACTIVE || newCS.Status__c == CONTRACT_SELLER_STATUS_INACTIVE)){
                // Insert Context
                if(oldMap == null){
                    csStartDates.add(newCS.StartDate__c);
                    csIds.add(newCS.Id);
                    csSellerIds.add(newCS.EBH_BusinessName__c);
                }
                // Update Context
                else{
                    EBH_ContractSeller__c oldCS = oldMap.get(newCS.Id);
                    if(oldCS.EBH_BusinessName__c != newCS.EBH_BusinessName__c || oldCS.StartDate__c != newCS.StartDate__c){
                        csStartDates.add(newCS.StartDate__c);
                        csIds.add(newCS.Id);
                        csSellerIds.add(newCS.EBH_BusinessName__c);
                    }
                }
            }
		}

        if(csIds.isEmpty()) {
            return;
        }

        String csSOQL = CONTRACT_SELLER_SOQL + ' WHERE EBH_BusinessName__c IN: csSellerIds AND Id !=: csIds AND (StartDate__c <=: csStartDates AND ((EndDate__c != null AND EndDate__c >: csStartDates) OR (EndDate__c = null AND EBH_ContractNumber__r.EndDate >: csStartDates)))';
        for(EBH_ContractSeller__c cs: (List<EBH_ContractSeller__c>) ApexSafe.query().doQuery(csSOQL,new Map<String, Object> {'csSellerIds' => csSellerIds, 'csIds' => csIds, 'csStartDates' => csStartDates})){
            duplicatedCSIds.add(cs.EBH_BusinessName__c);
        }
        for(EBH_ContractSeller__c newCS : newMap.values()){
            if(duplicatedCSIds.contains(newCS.EBH_BusinessName__c)) {
                newMap.get(newCS.Id).addError(Label.Duplicate_3PPContractSeller_ErrorMessage);
            }
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:   validateLockedFields
    @ Author: 	Sambath Seng
    @ Purpose:	US-0016114 - Pricing Configuration Record Lock - CPM, Contract other
	@ Event:	before update
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 09.01.2025 / Sambath Seng / Method Creation
	*****************************************************************************************************************************/
    public static void validateLockedFields(Map<Id, EBH_ContractSeller__c> oldMap, Map<Id, EBH_ContractSeller__c> newMap) {

        // Check if user has custom permission to bypass locked fields
        If(FeatureManagement.checkPermission('BypassLockedPricingConfiguration')) return;
        
        List<Schema.FieldSetMember> lockedFieldSet = SObjectType.EBH_ContractSeller__c.FieldSets.PricingConfigurationFieldsLocked.getFields();
        Set<String> lockedFieldNames = new Set<String>();
        for (Schema.FieldSetMember field : lockedFieldSet) {
            lockedFieldNames.add(field.getFieldPath());
        }

        // Collect contract IDs
        Set<Id> contractIds = new Set<Id>();
        for (EBH_ContractSeller__c newCS : newMap.values()) {
            contractIds.add(newCS.EBH_ContractNumber__c);
        }

        // Query contracts
        List<Contract> contractsList = ApexSafe.query().doQuery(CONTRACT_SOQL + ' WHERE Id IN :contractIds AND RecordType.DeveloperName IN :recordtypeSet', new Map<String, Object> {'contractIds' => contractIds, 'recordtypeSet' => CONTRACT_RECORDTYPE_FOR_PRICING_CONFIGURATION});
        Map<Id, Contract> contractMap = new Map<Id, Contract>(contractsList);

        // Check for locked fields
        Set<Id> csIdsToError = checkForContractSellerLockedFields(oldMap, newMap, contractMap, lockedFieldNames);

        // Add errors to the records
        for (Id csId : csIdsToError) {
            EBH_ContractSeller__c newCS = newMap.get(csId);
            newCS.addError(System.Label.PricingConfigurationLockedFieldsMessage);
        }
    }

    /*****************************************************************************************************************************
    @ Method:   validatePrimarySeller
    @ Author: 	Mony Nou
    @ Purpose:	US-0016395 - Set initiating contract seller as primary
	@ Event:	before update
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 17.01.2025 / Mony Nou / Method Creation
	*****************************************************************************************************************************/
    public static void validatePrimarySeller(Map<Id, EBH_ContractSeller__c> oldMap, Map<Id, EBH_ContractSeller__c> newMap) {

        // Collect contract seller IDs & contract IDs
        Set<Id> sCSIds = new Set<Id>();
        Set<Id> sContractIds = new Set<Id>();
        for (EBH_ContractSeller__c newCS : newMap.values()) {
            // Check if the Primary Seller field is being set to false
            if (!newCS.PrimarySeller__c && oldMap.get(newCS.Id).PrimarySeller__c) {
                sCSIds.add(newCS.Id);
                sContractIds.add(newCS.EBH_ContractNumber__c);
            }
        }

        if (sCSIds.isEmpty()) { return; }

        // Query contracts with Primary Seller
        List<Contract> contractsList = ApexSafe.query().doQuery(CONTRACT_SOQL + ' WHERE Id IN:sContractIds AND RecordType.DeveloperName IN :recordtypeSet AND Id IN (SELECT EBH_ContractNumber__c FROM EBH_ContractSeller__c WHERE Id NOT IN:sCSIds AND PrimarySeller__c = TRUE)', new Map<String, Object> {'sContractIds' => sContractIds, 'recordtypeSet' => CONTRACT_RECORDTYPE_FOR_PRICING_CONFIGURATION, 'sCSIds' => sCSIds});
        Map<Id, Contract> contractMap = new Map<Id, Contract>(contractsList);

        // Add errors to the records if the contract does not have a primary seller
        for (Id csId : sCSIds) {
            if (!contractMap.containsKey(newMap.get(csId).EBH_ContractNumber__c)) {
                newMap.get(csId).addError(System.Label.ErrMSG_CS_NoPrimarySeller);
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:   checkForContractSellerLockedFields
    @ Author: 	Sambath Seng
    @ Purpose:	US-0016114 - Pricing Configuration Record Lock - CPM, Contract other
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 21.01.2025 / Sambath Seng / Method Creation
	*****************************************************************************************************************************/
    private static Set<Id> checkForContractSellerLockedFields(Map<Id, EBH_ContractSeller__c> oldMap, Map<Id, EBH_ContractSeller__c> newMap, Map<Id, Contract> contractMap, Set<String> lockedFieldNames) {
        Set<Id> csIdsToError = new Set<Id>();
        for (Id csId : newMap.keySet()) {
            EBH_ContractSeller__c oldCS = oldMap.get(csId);
            EBH_ContractSeller__c newCS = newMap.get(csId);

            if (oldCS != null && newCS != null) {
                Contract parentContract = contractMap.get(newCS.EBH_ContractNumber__c);
                if (parentContract != null && parentContract.Status == CONTRACT_STATUS_PRICING_CONFIGURATION) {
                    for (String fieldName : lockedFieldNames) {
                        Object oldValue = oldCS.get(fieldName);
                        Object newValue = newCS.get(fieldName);

                        if (oldValue != newValue) {
                            csIdsToError.add(csId);
                            break; // Exit the loop as soon as a locked field is detected
                        }
                    }
                }
            }
        }
        return csIdsToError;
    }
}