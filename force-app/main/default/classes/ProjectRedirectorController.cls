/*********************************************************************************************************************************
@ Class:          ProjectRedirectorController
@ Version:        1.0
@ Author:         Sothea Horn (sohorn@ebay.com)
@ Created Date:   25 Nov 2024
@ Purpose:        US-0015912 - Remove ability to create new project for BD and MIS
@                 Override standard list view "New" button on Porject object
----------------------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************************/
public class ProjectRedirectorController {
    private final static String PROJECT_OBJECT_NAME = 'EBH_Project__c';
    private final static String INTEGRATION_HELP_RECORTTYPE_NAME = 'Integration_Help';
    //The custom label storing permissionset name by comma separator. If in the future they wants to add/remove any PSs, we dont need to update the code
    private final static Set<String> CUSTOM_PERMISSION_BD_FEATURE_SET = new Set<String>(
        System.label.New_eBay_Business_Development_Project_PermissionSets.split(',')
    );

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> validateProject (String recordTypeId) {
        Map<String, Object> mResult = new Map<String, Object>();
        mResult.put('isSuccess', true);
        try{
            //Check if the invoke user has permission to create eBay Business Developmen project manually (clicking New butoon from project object list view)
            //If yes, retrict user from creating a project and show error message.
            Boolean hasBDPermission = checkNewBDProjectPermission();
            RecordType recordTypeIntegrationHelp = ApexUtil.getRecordTypeByName(PROJECT_OBJECT_NAME, INTEGRATION_HELP_RECORTTYPE_NAME);
            if(hasBDPermission && (recordTypeId == recordTypeIntegrationHelp.Id)) {
                mResult.put('isSuccess', false);
                mResult.put('msgTitle', System.label.Failed_New_BD_Project_Title);
                mResult.put('msg', System.label.Validated_New_eBay_Business_Development_Project);
            }
        } catch (Exception ex) { 
            mResult.put('isSuccess', false);mResult.put('msg', ex.getMessage());
        }
        return mResult;
    }

    // Return true if the invoked user has BD permission
    private static Boolean checkNewBDProjectPermission () {
        for(String permissionName: CUSTOM_PERMISSION_BD_FEATURE_SET) {
            if(FeatureManagement.checkPermission(permissionName)) {
               return true;
            }
        }
        return false;
    }
}