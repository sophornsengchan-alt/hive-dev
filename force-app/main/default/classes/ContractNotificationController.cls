/*********************************************************************************************************************************
@ Class:          

@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        US-0015123 - Existing Contracts, Seller check
@ Change history: 20.05.2024 / SRONG TIN / Created the class.
*********************************************************************************************************************************/
public with sharing class ContractNotificationController {
    public final static string STATUS_EXECUTED = 'Executed';
    public final static string RECORDTYPE_ACP = 'EBH_ACP';
    public final static string RECORDTYPE_LISTING_AGREEMENT = 'EBH_ListingAgreement';
    public final static string RECORDTYPE_VIP_CONTRACTS = 'VIP_Contracts';
    private final static string CONTRACT_MANAGER = 'Contract_Manager';

    /*    
    @ Method: checkAccountExistingExecutedContract
    @ Version:  1.0
    @ Author:   SRONG TIN       
    @ Purpose:  US-0015123 - Existing Contracts, Seller check
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:  Map<Id,EBH_ContractSeller__c> oldMap, Map<Id,EBH_ContractSeller__c> newMap
    @ event : before insert, before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.05.2024 / SRONG TIN / Created the  Method.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> checkAccountExistingExecutedContract(String contractId){
        Map<String,Object>  mapResult = new Map<String,Object>();
        mapResult.put('data','');
        List<String> accIds = new List<String>();
        //get account from current contract
        if(String.isNotBlank(contractId)){
            String cQuery = 'Select Id,EBH_BusinessName__c From EBH_ContractSeller__c';
            List<String> recordTypeList = new List<String>{RECORDTYPE_ACP,RECORDTYPE_LISTING_AGREEMENT,RECORDTYPE_VIP_CONTRACTS};
            String cWhere = ' where EBH_ContractNumber__c =:contractId AND EBH_ContractNumber__r.RecordType.DeveloperName IN :recordTypeList';
            Map<String, Object> mapBind = new Map<String, Object> {'contractId' => contractId, 'recordTypeList' => recordTypeList};
            List<EBH_ContractSeller__c> currentContractSeller = (List<EBH_ContractSeller__c>)  ApexSafe.query().secCheck(false).doQuery(cQuery + cWhere,mapBind);
            for(EBH_ContractSeller__c cs: currentContractSeller){
                accIds.add(cs.EBH_BusinessName__c);
            }
        }
        //get executed contract from other contract by account
        if(!accIds.isEmpty()){
            String cQuery = 'Select Id,EBH_BusinessName__r.Name,EBH_ContractNumber__r.ContractNumber, EBH_ContractNumber__r.RecordType.Name,EBH_ContractNumber__r.StartDate, EBH_ContractNumber__r.EndDate From EBH_ContractSeller__c';
            String cWhere = ' where EBH_ContractNumber__r.Status = :STATUS_EXECUTED AND EBH_ContractNumber__c !=:contractId AND EBH_BusinessName__c IN :accIds';
            Map<String, Object> mapBind = new Map<String, Object> {'STATUS_EXECUTED' => STATUS_EXECUTED, 'contractId' => contractId, 'accIds' => accIds};
            List<EBH_ContractSeller__c> existingExecutedContractSeller = (List<EBH_ContractSeller__c>)  ApexSafe.query().secCheck(false).doQuery(cQuery + cWhere,mapBind);
            if(!existingExecutedContractSeller.isEmpty()){
                mapResult.put('data',existingExecutedContractSeller);   
            }
        }

        return mapResult;
    }
    
    
}