/*********************************************************************************************************************************
@ Class:          LwcSPEligibilityController
@ Author:         Chetra Sarom (chetra.sarom@gaea-sys.com)
@ Purpose:        US-0012308 - Can't give sellers access to seller portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  08.08.2022 / Chetra Sarom / Created the method.
                   02.09.2022 / Sophal Noch / US-0012170 - Manual Provisioning for Seller Portal PM Deals
                   12.12.2022 / Sambath Seng / US-0013001 - Domain Selection for SP Eligible Sellers
                   31.08.2023 / Bora Chhorn / US-0014084 - SP Account Management Eligibility flag
                   22.02.2024 / Sambath Seng / US-0014476 - Block Seller Portal whitelisting for NZ sellers
*********************************************************************************************************************************/

public with sharing class LwcSPEligibilityController {
    private static Boolean adminProfile = false;
    private static String PERMISSION_SELLER_PORTAL_SELLERS_ELIGIBLE_FOR_COUPONS = 'Seller_Portal_Sellers_Eligible_for_Coupons';
    private static String PERMISSION_SELLER_PORTAL_SELLERS_ELIGIBLE_FOR_DEALS = 'Seller_Portal_Sellers_Eligible_for_Deals';

    private static final String SP_ACCOUNT_MANAGEMENT = 'SP_Account_Management__c'; // BR 31.08.2023 US-0014084 - SP Account Management Eligibility flag
    private static final String SP_COUPONS = 'SP_Coupons__c';
    private static final String SP_DEALS = 'SP_Deals__c';
    private static final String SP_PROMOTIONS_MANAGER = 'SP_Promotions_Manager__c';
    private static final String SP_MAIN_DOMAIN = 'SP_Main_Domain__c';// SB 12.12.2022 US-0013001 - Domain Selection for SP Eligible Sellers
    private final static String SOQL_SELLER = 'Select EBH_RevRollup__c,SP_Main_Domain__c From Account ' ;
    private static final String REVROLLUP_NZ = 'NZ';// SB 22.2.2024 US-0014476

    /*********************************************************************************************************************************
    @ Method:         getSPEligibility
    @ Author:         Chetra Sarom (chetra.sarom@gaea-sys.com)
    @ Purpose:        US-0012308 - Can't give sellers access to seller portal
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  08.08.2022 / Chetra Sarom / Created the method.
    @ Change history:  02.09.2022 / Sophal Noch / US-0012170 - Manual Provisioning for Seller Portal PM Deals
    @ Change history:  06.01.2023 / Sambath Seng / US-0013001 - Domain Selection for SP Eligible Sellers
    @               :  22.02.2024 / Sambath Seng / US-0014476 - Block Seller Portal whitelisting for NZ sellers
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getSPEligibility(Id sellerId){ 
        Set<String> VALID_ADMIN_PROFILES = new Set<String>{
            'System Administrator',
            'Business Admin',
            'System Administrator - Limited Privileges'
        };

        // Boolean hasPermissionSellersEligibleforCoupons = ApexUtil.checkPermissionSet(new Set<String>{PERMISSION_SELLER_PORTAL_SELLERS_ELIGIBLE_FOR_COUPONS});
        // Boolean hasPermissionSellersEligibleforDeals = ApexUtil.checkPermissionSet(new Set<String>{PERMISSION_SELLER_PORTAL_SELLERS_ELIGIBLE_FOR_DEALS}); 

        Map<String,Object> mResult = new Map<String,Object>();
        Profile userProfile = [SELECT name, id from Profile where id = :UserInfo.getProfileId()];
        if(VALID_ADMIN_PROFILES.contains(userProfile.Name)){
            adminProfile = true;
        }

        Account seller = getSeller(sellerId);

        // SB 22.2.2024 US-0014476 
        if(seller.EBH_RevRollup__c == REVROLLUP_NZ) {
            mResult.put('isBlocked', true);
            return mResult;
        }

        // Boolean spCouponOK = Schema.SObjectType.Account.fields.getMap().get(SP_COUPONS).getDescribe().isAccessible() && Schema.SObjectType.Account.fields.getMap().get(SP_COUPONS).getDescribe().isUpdateable();
        // Boolean spDealOK = Schema.SObjectType.Account.fields.getMap().get(SP_DEALS).getDescribe().isAccessible() && Schema.SObjectType.Account.fields.getMap().get(SP_DEALS).getDescribe().isUpdateable();

        // 02.09.2022 / Sophal Noch / US-0012170 :
        Boolean spCouponOK = Schema.SObjectType.Account.fields.getMap().get(SP_COUPONS).getDescribe().isUpdateable();
        Boolean spDealOK = Schema.SObjectType.Account.fields.getMap().get(SP_DEALS).getDescribe().isUpdateable();
        Boolean spProManageOK = Schema.SObjectType.Account.fields.getMap().get(SP_PROMOTIONS_MANAGER).getDescribe().isUpdateable();
        Boolean spMainDomainOK = Schema.SObjectType.Account.fields.getMap().get(SP_MAIN_DOMAIN).getDescribe().isUpdateable();// SB 12.12.2022 US-0013001 - Domain Selection for SP Eligible Sellers
        Boolean spAccManagementOK = Schema.SObjectType.Account.fields.getMap().get(SP_ACCOUNT_MANAGEMENT).getDescribe().isUpdateable();// BR 31.08.2023 US-0014084 - SP Account Management Eligibility flag

        mResult.put('SellersEligibleforCoupons', spCouponOK);
        mResult.put('SellersEligibleforDeals', spDealOK);
        mResult.put('SellersEligibleforProManage', spProManageOK); // 02.09.2022 / Sophal Noch / US-0012170
        mResult.put('adminProfile', adminProfile);
        // Start SB 5.1.2023 US-0013001 - Domain Selection for SP Eligible Sellers
        mResult.put('SPMainDomain', spMainDomainOK); 
        // BR 31.08.2023 US-0014084 - SP Account Management Eligibility flag
        mResult.put('SellersEligibleForAccountManagement', spAccManagementOK); 

        Map<String, Set<String>> SP_MAIN_DOMAIN_MAPPING = SEP_Helper.SP_MAIN_DOMAIN_MAPPING;
        List<ApexUtil.PicklistEntryWrapper> lstPklValue = new List<ApexUtil.PicklistEntryWrapper>();
        for( Schema.PicklistEntry pickListVal : Account.SP_Main_Domain__c.getDescribe().getPicklistValues()){
            ApexUtil.PicklistEntryWrapper pklValue = new ApexUtil.PicklistEntryWrapper();
            Boolean isContainDomainValue = pickListVal.getValue() == seller.SP_Main_Domain__c;
            if(String.isNotBlank(seller.EBH_RevRollup__c) && SP_MAIN_DOMAIN_MAPPING.get(seller.EBH_RevRollup__c).contains(pickListVal.getValue()) || isContainDomainValue){
                pklValue.label = pickListVal.getLabel();
                pklValue.value = pickListVal.getValue();
                lstPklValue.add(pklValue);
            }
        }
        mResult.put('pklDepSPMainDomain',lstPklValue);
        mResult.put('SPMainDomainVal', seller.SP_Main_Domain__c);
        // End SB 5.1.2023 US-0013001 - Domain Selection for SP Eligible Sellers

        return mResult;
    }

    public static Account getSeller(String sellerId)
    {  
        return Database.query(SOQL_SELLER+' WHERE Id =:sellerId');
    }
}