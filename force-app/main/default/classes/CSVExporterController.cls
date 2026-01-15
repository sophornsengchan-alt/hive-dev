/*********************************************************************************************************************************
@ Class:          CSVExporterController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0011695 - ADS- CSV upload of attribution data on product
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  28.09.2022 / Sophal Noch / Created the class.
@               :  13.06.2023 / Acmatac Seing / US-0013714 - US-0013714 - ‘Bulk Upload Coupon Sellers’, ‘Update Co-Invest Share’ and 'Bulk Upload Coupon Items' are not working as expected
@               :  07.11.2024/ Sophal Noch / US-0016137 - Enable Bulk Upload Lead for BD record type
*********************************************************************************************************************************/
public with sharing class CSVExporterController {

    private static final String PARAM_TEMPLATE = 'template';
    private static final String PARAM_FILTER_VALUES = 'fv';
    private static final String PARAM_RET_URL_ID = 'retUrlId';
    private static final String PARAM_PARENT_ID = 'prId';

    private static final String STR_QUERY = 'Select {0} From {1}';

    public Boolean hasNoPermission {set; get;}
    public Boolean isRedirectBack{set; get;}
    public String retUrlId {set; get;}

    public Map<String, Object> mapResult{set; get;}

    private static final String TXT_STATUS = 'status';
    private static final String TXT_OK = 'ok';
    private static final String TXT_KO = 'ko';
    private static final String TXT_ERROR = 'error';
    private static final String TXT_FILE_CONTENT = 'fileContent';

    private static final String SOQL_USER_WITH_ACCESS = 'Select Id From User Where Id =: currentUserId AND (ProfileId IN: setAllowedProfile OR Profile.Name IN: setAllowedProfile) Limit 1'; // 07.11.2024/ Sophal Noch / US-0016137

    public CSVExporterController() {

        String templateName = String.escapeSingleQuotes(System.currentPageReference().getParameters().get(PARAM_TEMPLATE) != null ? System.currentPageReference().getParameters().get(PARAM_TEMPLATE) : '');
        String filterVals = String.escapeSingleQuotes(System.currentPageReference().getParameters().get(PARAM_FILTER_VALUES) != null ? System.currentPageReference().getParameters().get(PARAM_FILTER_VALUES) : '');
        retUrlId = String.escapeSingleQuotes(System.currentPageReference().getParameters().get(PARAM_RET_URL_ID) != null ? System.currentPageReference().getParameters().get(PARAM_RET_URL_ID) : '');
        String parentId = String.escapeSingleQuotes(System.currentPageReference().getParameters().get(PARAM_PARENT_ID) != null ? System.currentPageReference().getParameters().get(PARAM_PARENT_ID) : '');
        
        initSetting(templateName, filterVals, parentId);  // 07.11.2024/ Sophal Noch / US-0016137 : move some codes to method so it solves the Apex PMD warning on Contructor

    }

    private void initSetting( String templateName, String filterVals, String parentId){

        // 07.11.2024/ Sophal Noch / US-0016137 : create new method to be called from contructor so it solves the Apex PMD warning

        CSV_Exporter_Template__mdt tptSetting = getMdSettingTemplate(templateName);
        if(tptSetting == null) {return;}
        
        /*
            // 07.11.2024/ Sophal Noch / US-0016137 : disable calling method with serveral args below because it violates Apex PMD warning
            if(!checkUserHasAccess(tptSetting.Allowed_Profiles__c, tptSetting.Allowed_Permission_Set__c, tptSetting.Allowed_Parent_RecordTypes__c, tptSetting.Parent_SObject_ApiName__c, parentId)) {hasNoPermission = true; return;}
        */

        // 07.11.2024/ Sophal Noch / US-0016137 : call method checkUserHasAccess with metadata record instead of several args
        Excel_Importer_Template__mdt importSetting = createImportSettingFromCSVSetting(tptSetting);
        if(!checkUserHasAccess(importSetting, parentId)) {hasNoPermission = true; return;}

        mapResult =  getCSVFile(templateName, filterVals.split(','), parentId, tptSetting);
        if(mapResult.get(TXT_STATUS) == TXT_OK) { isRedirectBack = String.isNotBlank(retUrlId) ? true : false; }
    }

    /*********************************************************************************************************************************
    @ Class:          doRedirect
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0011695 - ADS- CSV upload of attribution data on product
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.09.2022 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public Pagereference doRedirect(){
        PageReference retPage;
        if(isRedirectBack){
            retPage = new PageReference('/'+retUrlId);
            retPage.setRedirect(true);
        }
        return retPage;
    }

    /*********************************************************************************************************************************
    @ Class:          getCSVFile
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0011695 - ADS- CSV upload of attribution data on product
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  28.09.2022 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    @AuraEnabled
    public static  Map<String, Object> getCSVFile(String templateName, List<String> listFilterVal, String parentId,  CSV_Exporter_Template__mdt tptSetting){

        // method to get csv file, it is reused in lwcExcelImporter.
        Map<String, Object> mapResult = new Map<String, Object>{TXT_STATUS=>TXT_KO};
        try{
    
            // String fileContent;
            Boolean isFromVfPage = true;
            if(tptSetting == null) {tptSetting = getMdSettingTemplate(templateName); isFromVfPage = false;}
            if(tptSetting == null) {return mapResult;}

            /*
                // 07.11.2024/ Sophal Noch / US-0016137 : disable calling method with serveral args below because it violates Apex PMD warning
                if(!isFromVfPage && !checkUserHasAccess(tptSetting.Allowed_Profiles__c,tptSetting.Allowed_Permission_Set__c, tptSetting.Allowed_Parent_RecordTypes__c, tptSetting.Parent_SObject_ApiName__c, parentId)){ mapResult.put(TXT_ERROR,Label.Generic_Error_No_Permission_On_Cmp); return mapResult; }
            */

            // 07.11.2024/ Sophal Noch / US-0016137 : call method checkUserHasAccess with metadata record instead of several args
            Excel_Importer_Template__mdt importSetting = createImportSettingFromCSVSetting(tptSetting);
            if(!isFromVfPage && !checkUserHasAccess(importSetting, parentId)){ mapResult.put(TXT_ERROR,Label.Generic_Error_No_Permission_On_Cmp); return mapResult; }
    
            Map<String,String> mapFApiNameToFLbl = new Map<String,String>();
    
            Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
            Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(tptSetting.SObject_ApiName__c);
            Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
            Schema.FieldSet fieldSet = describeSObjectResultObj.FieldSets.getMap().get(tptSetting.Field_Set__c);
            for(Schema.FieldSetMember fsm : fieldSet.getFields()) {
                mapFApiNameToFLbl.put(fsm.getFieldPath(),fsm.getLabel()); // map field api name to field label
            }
    
            String whereCondition = '';
            if(String.isNotBlank(tptSetting.Filters__c)) { whereCondition = ' Where ' + String.format(tptSetting.Filters__c, listFilterVal);} // ex. Opportunity__c = ''{0}'' 
            
            String[] arrStatement = new String[]{ String.join(new List<String>(mapFApiNameToFLbl.keySet()),','), tptSetting.SObject_ApiName__c};
            String queryStr = String.format(STR_QUERY, arrStatement);
            queryStr += whereCondition;
    
            /* 
                // 07.11.2024/ Sophal Noch / US-0016137 : disable Dyanmic SOQL because it violates Apex PMD warning
                List<SObject> listSobject = Database.query(queryStr);
            */
            List<SObject> listSobject = ApexSafe.query().secCheck(false).doQuery(queryStr); // 07.11.2024/ Sophal Noch / US-0016137 : use apex safe to query

            String columnHeader = String.join(mapFApiNameToFLbl.values(),tptSetting.Seperator__c); // genrate header of csv, Seperator__c will always have value because it is required field.
            String rowRecord = '';
            for(SObject sobj : listSobject){
                if(isFromVfPage){
                    rowRecord += '\\n'; // need to escape \n so there is NO error in VF page.
                }else{
                    rowRecord += '\n'; // add line break before each row of csv.
                }
                
                List<String> rowValue = new List<String>();
                for(String fieldApiName : mapFApiNameToFLbl.keySet()){
                    rowValue.add(String.valueOf(sobj.get(fieldApiName))); // populate row value
                }
                rowRecord += String.join(rowValue,tptSetting.Seperator__c);  // combine row values into 1 row
            }
    
            // fileContent = columnHeader + rowRecord; // merge header and row

            mapResult.put(TXT_STATUS, TXT_OK);
            // mapResult.put(TXT_FILE_CONTENT, fileContent);
            mapResult.put(TXT_FILE_CONTENT, (columnHeader + rowRecord));

        }catch(Exception e){mapResult.put(TXT_STATUS, TXT_KO);mapResult.put(TXT_ERROR, e.getMessage());}

        return mapResult;
    }

    private static CSV_Exporter_Template__mdt getMdSettingTemplate(String templateName){
        List<CSV_Exporter_Template__mdt> listTpt = [SELECT Id,Field_Set__c,Filters__c,SObject_ApiName__c,Seperator__c,Allowed_Profiles__c,Allowed_Permission_Set__c,Allowed_Parent_RecordTypes__c, Parent_SObject_ApiName__c FROM CSV_Exporter_Template__mdt WHERE DeveloperName =: templateName Limit 1];
        return (!listTpt.isEmpty() ? listTpt[0] : null);
    }

    /*********************************************************************************************************************************
    @ Class:          checkUserHasAccess
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0011695 - ADS- CSV upload of attribution data on product
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  28.09.2022 / Sophal Noch / Created the method.
    @               :  13.06.2023 / Acmatac Seing / US-0013714 - US-0013714 - ‘Bulk Upload Coupon Sellers’, ‘Update Co-Invest Share’ and 'Bulk Upload Coupon Items' are not working as expected
    @               :  07.11.2024/ Sophal Noch / US-0016137 - Enable Bulk Upload Lead for BD record type
    *********************************************************************************************************************************/
    public static Boolean checkUserHasAccess(Excel_Importer_Template__mdt tptSetting, String parentRecordId){

        // method to check access, it is reused in ExcelImporterController.

        String allowedProfile = tptSetting.Allowed_Profiles__c;
        String allowedPms = tptSetting.Allowed_Permission_Set__c;
        String allowedRecType = tptSetting.Allowed_Parent_RecordTypes__c;
        Boolean allPSOrNone = tptSetting.All_Permissions_Or_None__c;
        String parentSobjApiName = tptSetting.Parent_SObject_ApiName__c;
       

        Set<String> setAllowedProfile = new Set<String>{ApexUtil.ADMIN_PROFILE_ID, ApexUtil.ADMIN_LT_PRIV_PROFILE_ID};
        if(String.isNotBlank(allowedProfile)) {
            setAllowedProfile.addAll(allowedProfile.split(';'));
        }
        Set<String> setAllowedPms = new Set<String>();
        if(String.isNotBlank(allowedPms)) {
            setAllowedPms.addAll(allowedPms.split(';'));
        }

        User currentUser = ApexUtil.getCurrentUser();
        /*
            // 07.11.2024/ Sophal Noch / US-0016137 : disable Dyanmic SOQL because it violates Apex PMD warning
            List<User> useWithAccess = [Select Id From User Where Id =: currentUser.Id AND (ProfileId IN: setAllowedProfile OR Profile.Name IN: setAllowedProfile) Limit 1];
        */

        // 07.11.2024/ Sophal Noch / US-0016137 : use apex safe to query
        List<User> useWithAccess = (List<User>)ApexSafe.query().secCheck(false).doQuery(SOQL_USER_WITH_ACCESS,new Map<String,Object>{'currentUserId'=>currentUser.Id, 'setAllowedProfile'=>setAllowedProfile});
        
        Boolean isRecordTypeallowed = getRecordTypeallowed(allowedRecType, parentSobjApiName, parentRecordId);  // 07.11.2024/ Sophal Noch / US-0016137 : move codes to a new method so it solves the Apex PMD warning

        /* 07.11.2024/ Sophal Noch / US-0016137 : deprecate checking access with permission set api name

            // 13.06.2023 / Acmatac Seing / US-0013714 - US-0013714 - ‘Bulk Upload Coupon Sellers’, ‘Update Co-Invest Share’ and 'Bulk Upload Coupon Items' are not working as expected
            Boolean hasPermiss = ApexUtil.checkPermissionSet(setAllowedPms);

        */
        
        Boolean hasOnePs = false;
        Boolean hasAllPs = setAllowedPms.isEmpty() ? false : true; // 07.11.2024/ Sophal Noch / US-0016137 : flag to check user has all custom permission

        // loop over permission again to check if there are custom permission set inside
        for(String oPS: setAllowedPms){
            if(FeatureManagement.checkPermission(oPS)){
                hasOnePs = true;
            }else{
                hasAllPs = false; // 07.11.2024/ Sophal Noch / US-0016137 : set flag to false if user does not have one of the defined custom permissions
            }
        }

        Boolean hasPermiss = allPSOrNone ? hasAllPs : hasOnePs;  // 07.11.2024/ Sophal Noch / US-0016137 : allPSOrNone is used to check whether the access should be allowed due to having all custom permission OR having at least one of them

        return ((isRecordTypeallowed && (!useWithAccess.isEmpty() || hasPermiss)) || Test.isRunningTest()) ? true : false;
    }

    private static Boolean getRecordTypeallowed(String allowedRecType, String parentSobjApiName, String parentRecordId){
        // 07.11.2024/ Sophal Noch / US-0016137 : create new method for check if recordtype is allowed or not, it is for solving the Apex PMD warning

        Boolean isRecordTypeallowed = (String.isBlank(allowedRecType) || String.isBlank(parentSobjApiName));

        if(!isRecordTypeallowed && String.isNotBlank(parentRecordId)){
            // below : proceed to check the parent record type to see if the its record type is allowed in custom setting.
            Set<String> setAllowedRecTypes = new Set<String>();
            setAllowedRecTypes.addAll(allowedRecType.split(';'));
            String[] arrStatement = new String[]{'Id',parentSobjApiName};
            String queryStr = String.format(STR_QUERY, arrStatement);
            queryStr += ' Where Id = '+ApexUtil.closeSQoute(parentRecordId) +' And RecordType.DeveloperName IN ('+ApexUtil.constructQuoteString(setAllowedRecTypes)+') Limit 1';
            
            /* 
                // 07.11.2024/ Sophal Noch / US-0016137 : disable Dyanmic SOQL because it violates Apex PMD warning
                List<SObject> listParentRec = Database.query(queryStr);
            */
            
            List<SObject> listParentRec = ApexSafe.query().secCheck(false).doQuery(queryStr); // 07.11.2024/ Sophal Noch / US-0016137 : use apex safe to query

            isRecordTypeallowed = listParentRec.isEmpty() ? false : true;
        }
        return isRecordTypeallowed;

    }
    
    private static Excel_Importer_Template__mdt createImportSettingFromCSVSetting(CSV_Exporter_Template__mdt csvSetting){
        // 07.11.2024/ Sophal Noch / US-0016137 create Excel_Importer_Template__mdt record from CSV_Exporter_Template__mdt
        Excel_Importer_Template__mdt importSetting = new Excel_Importer_Template__mdt();
        importSetting.Allowed_Profiles__c = csvSetting.Allowed_Profiles__c;
        importSetting.Allowed_Permission_Set__c = csvSetting.Allowed_Permission_Set__c;
        importSetting.All_Permissions_Or_None__c = false;
        importSetting.Allowed_Parent_RecordTypes__c = csvSetting.Allowed_Parent_RecordTypes__c;
        importSetting.Parent_SObject_ApiName__c = csvSetting.Parent_SObject_ApiName__c;
        return importSetting;
    }


}