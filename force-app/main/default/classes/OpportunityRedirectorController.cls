/*********************************************************************************************************************************
@ Class:          OpportunityRedirectorController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0008557 - [NA] Opportunity Layout "Details" and "Related" sections
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.11.2020 / Sovantheany Dim / Created the class.
@ Change history: 16.06.2021 / Mony Nou / US-0009693 - Modify Clone Quote Functionality.     
@ Change history: 11.07.2024 / Sophal Noch / US-0015348 - Opportunities - (part 2) Permission Set, Fields and Page Layout for BD teams    
@ Change history: 13.08.2024 / Sovantheany Dim / US-0015571 - Remove ability to create new opp from opp object directly for permission set 'Opportunity - eBay Business Development
@ Change history: 24.09.2024 / Bora Chhorn / US-0015916 - Post DE launch Fixes - BD Layouts (Part 2)
@                 09.10.2024 / Acmatac Seing / US-0016028 Logic to block BD user from creating Opportunity right away not working as expected
@                 07.01.2025 / Bora Chhorn / US-0016403 - Ability to create Opportunities on existing Legal Entities
@                 23.04.2025 / Sothea Horn / US-0016756 - Users with "Business Development Base Access" and "MIS Base Access" should be able to create Oppty from Oppty Tab and LE
*********************************************************************************************************************************/
public class OpportunityRedirectorController {
    private static set<String> sPermissionSet = new Set<String>{'US_CA_Standard_user','NA_Sales_Ops_Admin'};
    private final static String NAPROFILE = 'NA Standard User Base';
    private final static String OPPORTUNITY_BD_PERMISSION = 'Opportunity_Business_Development_Base_Access_Permission';
    private final static Set<String> CUSTOM_PERMISSION_BD_FEATURE_SET = new Set<String>{OPPORTUNITY_BD_PERMISSION,'Project_Integration_Help_Manager','Support_Request_Integration_Help_Manager'};

    @AuraEnabled
    public static Map<String, Object> validatedOpportunity(String recordtypeId) {
        Map<String, Object> mResult = new Map<String, Object>();
        try{
            Boolean isNAUser = UserInfo.getProfileId() == ApexUtil.NA_STANDARD_USER_PROFILE_ID;
            // if NA profile : Check if user has permission  "US & CA standard user", "NA Data Loader & Sales Ops Admin" 
            Boolean isUSNAuserPermission = ApexUtil.checkPermissionSet(sPermissionSet);
            if(isNAUser && isUSNAuserPermission || !isNAUser) {
                mResult.put('isSuccess', true);
            }
            else if(isNAUser && !isUSNAuserPermission) {
                mResult.put('isSuccess', false);
                mResult.put('msg', System.label.Validated_NAUserPermission_on_Opportunity);
            }
            
            // 11.07.2024 / Sophal Noch / US-0015348 :
            String oppDefaultRtypeId;
            Schema.DescribeSObjectResult oppDesSobjResult = Opportunity.SObjectType.getDescribe();
            List<Schema.RecordTypeInfo> listRtypeInfo = oppDesSobjResult.getRecordTypeInfos();
            for (Schema.RecordTypeInfo rtypeInfo : listRtypeInfo) {
                if (rtypeInfo.isAvailable()){
                    oppDefaultRtypeId = rtypeInfo.getRecordTypeId();
                    mResult.put('oppDefaultRtypeId', oppDefaultRtypeId);
                    break;
                }
            }
            //TH:US-0015571:if user with permission set 'Opportunity - eBay Business Development', Could not create new opp
            //BR:US-0015916: Added 2 permission set into Set<String>
            // 09.10.2024 / Acmatac Seing / US-0016028 Replace ApexUtil.checkPermissionSet with FeatureManagement
            // 23.04.2025 / Sothea Horn / US-0016756 - Users with "Business Development Base Access" and "MIS Base Access" should be able to create Oppty from Oppty Tab and LE
            if (isCreateBDOpportunity(recordtypeId, oppDefaultRtypeId)) {
                for (String permissionName: CUSTOM_PERMISSION_BD_FEATURE_SET) {
                    if (FeatureManagement.checkPermission(permissionName)) {
                        //US-0016756 - if user has "Business Development Base Access" Permission, then allow to create Oppty from Existing Legal Entity and from Oppty tab
                        if (permissionName == OPPORTUNITY_BD_PERMISSION) {
                            mResult.put('isSuccess', true);
                        } else {
                            mResult.put('isSuccess', false);
                            mResult.put('msg', system.label.Validated_eBay_Business_Development_on_Opportunity_2);
                        }
                        break;
                    }
                }
            }
        }catch (Exception ex) { mResult.put('isSuccess', false);mResult.put('msg', ex.getMessage());}
        return mResult;
    }

    private static Boolean isCreateBDOpportunity(String recordTypeId, String defaultRecordTypeId) {
        RecordType oppBDRecordType = ApexUtil.getRecordTypeByName('Opportunity', 'eBay_Business_Development');
        return (recordTypeId == oppBDRecordType.Id || defaultRecordTypeId == oppBDRecordType.Id);
    }

    //MN-16062021-US-0009693 - Modify Clone Quote Functionality.
    @AuraEnabled
    public static Map<String, Object> validateCloneQuoteButton() {
        Map<String, Object> mResult = new Map<String, Object>();
        try{
            
            Boolean isValid = CloneQuoteController.isValid();
            mResult.put('isSuccess', isValid);
            if (!isValid) {mResult.put('msg', Label.Error_No_Permission_To_CloneQuote);}
            
        }catch (Exception ex) { mResult.put('isSuccess', false);mResult.put('msg', ex.getMessage());}
        return mResult;
    }
}