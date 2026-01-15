/*********************************************************************************************************************************
@ Class:        PaidProgramController
@ Version:      1.0
@ Author:       Sophal Noch
@ Purpose:      07.01.2026 / Sophal Noch / US-0033990 - UK Paid Programs - Current Subscription Overview (Step 1)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 07.01.2026 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
public with sharing class PaidProgramController {

    private final static String CLASS_NAME = 'PaidProgramController';
    private final static String MT_NAME_INIT_DATA = 'initData';
    private final static String PAGE_NAME = 'Account Manager';

    private final static String MNG_SGM_PAID_PRGM_TIER_1 = 'Paid Program - Tier 1';
    private final static String MNG_SGM_PAID_PRGM_TIER_2 = 'Paid Program - Tier 2';

    private final static String ELIGIBLE_FOR_PAID_PROGRAM = 'Eligible_for_Paid_Program';

    private final static String SOQL_QUERY_BS = 'SELECT BoB__r.Managed_Segment__c FROM BoB_Seller__c';
    private final static String SOQL_WHERE = ' WHERE Id = ';
    private final static String SOQL_LIMIT_1 = ' Limit 1';

    @AuraEnabled(cacheable=true)
    public static Map<String,Object> initData(String sellerId){
        Map<String,Object> mapResult = new Map<String,Object>();
        try{
            Map<String, Seller_Portal_Setting__mdt> mapEligibleAccounts = AccountManagementController.getSPMetadata(new Set<String>{ELIGIBLE_FOR_PAID_PROGRAM});
            Map<Id, BoB_Seller__c> mapBoBSeller = AccountManagementController.getSellerCohort(mapEligibleAccounts, new Set<Id>{sellerId}, ELIGIBLE_FOR_PAID_PROGRAM);
            Boolean isPaidPrgmTier1 = false;
            Boolean isPaidPrgmTier2 = false;
            if(!mapBoBSeller.isEmpty()){ // check if it is eligible and also need bob seller Id
                String sWhere = SOQL_WHERE + ApexUtil.closeSQoute(mapBoBSeller.get(sellerId).Id);
                List<BoB_Seller__c> listBoBSeller = WithoutSharing.doQuery(SOQL_QUERY_BS, sWhere, SOQL_LIMIT_1); // need without sharing because seller portal does not have access to BoB__C sobject
                String managedSegment = !listBoBSeller.isEmpty() ? listBoBSeller[0].BoB__r?.Managed_Segment__c : null;
                isPaidPrgmTier1 = managedSegment == MNG_SGM_PAID_PRGM_TIER_1 ? true : false;
                isPaidPrgmTier2 = managedSegment == MNG_SGM_PAID_PRGM_TIER_2 ? true : false;
            }

            mapResult.put('isPaidPrgmTier1',isPaidPrgmTier1);
            mapResult.put('isPaidPrgmTier2',isPaidPrgmTier2);
            mapResult.put('status','ok');

        }catch(Exception ex){
            mapResult.put('status','ko');
            EBH_ApexLogger.logSellerPortal('create', sellerId, '', '', PAGE_NAME, ex.getMessage(), URL.getOrgDomainUrl().toExternalForm(), CLASS_NAME + '.' + MT_NAME_INIT_DATA);
        }
        return mapResult;
    }
}