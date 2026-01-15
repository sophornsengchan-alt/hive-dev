/*********************************************************************************************************************************
@ Class:          ContractPricingMatrixTriggerHandler
@ Author:         Mony Nou
@ Purpose:        Handler trigger for ContractCategory
@ Change history: 24.01.2025 / Mony Nou / Class Creation
*********************************************************************************************************************************/
public with sharing class ContractPricingMatrixTriggerHandler {

    private static final String CPM_VIPCUSTOMRECORDTYPE = 'VIP_Custom';
    private static final String CONTRACT_STATUS_DRAFT = 'Draft';
    private final static String CPM_VIPCUSTOM_RECORDTYPEID = ApexUtil.getRecordTypeByName('EBH_ContractPricingMatrix__c',CPM_VIPCUSTOMRECORDTYPE).Id;

    /*****************************************************************************************************************************
    @ Method:   validateVIPCustomCPM
    @ Author: 	Mony Nou
    @ Purpose:	US-0015673 - Update the existing Contract Manager permission set to allow creation of CPM records
	@ Event:	before update
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 24.01.2025 / Mony Nou / Method Created.
	*****************************************************************************************************************************/
    public static void validateVIPCustomCPM(Map<Id, EBH_ContractPricingMatrix__c> newMap) {

        Boolean isAdmin = (new Set<Id>{ApexUtil.ADMIN_PROFILE_ID,ApexUtil.ADMIN_LT_PRIV_PROFILE_ID}).contains(Userinfo.getprofileId());

        // If user is admin or does not have custom permission "Contract Manager", return
        if (isAdmin || !FeatureManagement.checkPermission('Contract_Manager')) { return; }
        Set<Id> sCPMIds = new Set<Id>();
        
        for (EBH_ContractPricingMatrix__c cpm : newMap.values()) {
            if (cpm.RecordTypeId == CPM_VIPCUSTOM_RECORDTYPEID) {
                sCPMIds.add(cpm.Id);
            }
        }

        if (sCPMIds.isEmpty()) { return; } // No VIP Custom CPMs to process 

        String soql = 'SELECT Id FROM EBH_ContractPricingMatrix__c WHERE Id IN:sCPMIds AND Id IN (SELECT EBH_ContractPricingMatrix__c FROM EBH_Pricing__c WHERE EBH_ContractId__r.Status <>:CONTRACT_STATUS_DRAFT)';
        Map<Id, EBH_ContractPricingMatrix__c> mLockCPM = new Map<Id, EBH_ContractPricingMatrix__c>((List<EBH_ContractPricingMatrix__c>)ApexSafe.query().doQuery(soql,new Map<String, Object> {'sCPMIds' => sCPMIds, 'CONTRACT_STATUS_DRAFT' => CONTRACT_STATUS_DRAFT}));

        if (mLockCPM.isEmpty()) { return; } // No VIP Custom CPMs to process

        for (Id cpmId : sCPMIds) {
            if (mLockCPM.containsKey(cpmId)) {
                // Add error message when CPM record link to Pricing record that has contract status not Draft
                newMap.get(cpmId).addError(System.Label.ErrorUpdateCPMRecordNotStageDraft); 
                
            }
        }

    }

}