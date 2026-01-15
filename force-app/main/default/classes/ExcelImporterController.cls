/*********************************************************************************************************************************
@ Class:          ExcelImporterController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0011643 - SPIKE Implement Excel import module using JS to support copy paste
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  17.06.2022 / Sophal Noch / Created the class.
@ Change history:  12.12.2022 / Sophal Noch / US-0012119 - Standard Deal (V1) Upload functionality - Extend excel copy paste feature
@ Change history:  01.02.2023 / Chetra Sarom / US-0012119 - US-0012713 - Seller Bulk Upload functionality - Extend excel copy paste feature
@               :  19.05.2023 / Sophal Noch / US-0013298 - Bulk Upload Lead, replace it with xl copy, paste feature
@               :  07.06.2023 / Sophal Noch / US-0013657 - Bulk Upload - Copy Paste Functionality in Seller Portal
@               :  24.07.2023 / Sovantheany Dim / US-0013870 - Change cohort bulk upload file to new Bulk Upload type (like we have for coupons)
@               :  25.09.2023 / Sophal Noch / US-0014118 - ADS - New Cohort seller bulk upload template
@               :  17.10.2023 / Sophal Noch / US-0014165 - Cohort - Bulk export functionality
@               :  26.10.2023 / Sambath Seng / US-0013554 - Deal (V2) Upload functionality to be replaced with Copy paste feature
@               :  23.11.2023 / Mony Nou / US-0014106 - UX Changes for Coupon Seller Bulk Upload Component v2
@               :  09.12.2023 / Mony Nou / US-0014505 - Block Users from sending FVF contracts for approval that have more than 10k listings
@               :  24.09.2024/ vadhanak voun/ US-0015465 - Cohort bulk upload - fail scenario messages
@               :  07.11.2024/ Sophal Noch / US-0016137 - Enable Bulk Upload Lead for BD record type
@               :  14/01/2025 / Sovantheany Dim / US-0016358 - (3) Data Import and Export from Deal Contract Agreement
@               :  15/01/2025 / vadhanak voun / US-0016265 - (2) Upload Sub Deals in Hive
@               :  22/02/2025 / vadhanak voun / US-0016262 - 10 - Seller Portal - Upload Sub Deals
@               :  03/07/2025 / Chansophorn Seng/ US-0033008 - Upload Deals functionality in DCA Sub Deals is ignoring the non copied columns
@               :  21/07/2025 / Chansophorn Seng/ US-0033145 - Missing Owner name in email when Seller Signed Contract
@               :  11/12/2025 / Mony Nou / US-0033626 - POP - Ability for Coupon Managers to Upload Coupon Item Exclusions in HIVE
*********************************************************************************************************************************/
public with sharing virtual class ExcelImporterController {

    private static final String DML_INSERT = 'Insert';
    private static final String DML_UPDATE = 'Update';
    private static final String DML_UPSERT = 'Upsert';

    private static String TXT_LIST_RESULT = 'listResult';

    private static String SUCCESS_MSG_TEMPLATE = '{0} Success.';
    private static String ERROR_MSG_TEMPLATE = '{0} Failed. Error : {1}';
    private static final String STR_QUERY = 'Select {0} From {1}';

    public String templateName {set; get;}
    public Boolean hideTemplateName {set; get;}
    public Boolean hideActionBtns {set; get;}
    public Boolean hideListTable {set; get;}

    // 19.05.2023 / Sophal Noch / US-0013298 : add boolean data type
    private final static String DATA_TYPE_DECIMAL = 'decimal', DATA_TYPE_NUMBER='number', DATA_TYPE_DATE='date', DATA_TYPE_TIME='time', DATA_TYPE_BOOLEAN='boolean';
    // SB 26.10.2023 US-0013554
    private final static String SOQL_EMAIL_TEMPLATE = 'Select Id,Subject,HtmlValue from emailTemplate where DeveloperName=:templateName'; 
    
    public ExcelImporterController(){
        templateName = String.escapeSingleQuotes(System.currentPageReference().getParameters().get('template') != null ? System.currentPageReference().getParameters().get('template') : '');
        hideTemplateName = Boolean.valueOf(String.escapeSingleQuotes(System.currentPageReference().getParameters().get('hName') != null ? System.currentPageReference().getParameters().get('hName') : ''));
        hideActionBtns =  Boolean.valueOf(String.escapeSingleQuotes(System.currentPageReference().getParameters().get('hBtns') != null ? System.currentPageReference().getParameters().get('hBtns') : ''));
        hideListTable = Boolean.valueOf(String.escapeSingleQuotes(System.currentPageReference().getParameters().get('hTable') != null ? System.currentPageReference().getParameters().get('hTable') : ''));
    }

    /*****************************************************************************************************************************
    @ Method:       getExcelImporterTemplate
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0011643 - SPIKE Implement Excel import module using JS to support copy paste
    @ Event:		when init lwcExcelImporter page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	Excel_Importer_Template__mdt api name : templateName
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.06.2022  / Sophal Noch / Created the method.
    @ Change history: 26.09.2022 / Sophal Noch / US-0011695 - ADS- CSV upload of attribution data on product
    @ Change history: 12.12.2022 / Sophal Noch / US-0012119 - Standard Deal (V1) Upload functionality - Extend excel copy paste feature
    @ Change history: 01.02.2023 / Chetra Sarom / US-0012119 - US-0012713 - Seller Bulk Upload functionality - Extend excel copy paste feature
    @               : 07.06.2023 / Sophal Noch / US-0013657 - Bulk Upload - Copy Paste Functionality in Seller Portal
    @               : 23.11.2023 / Mony Nou / US-0014106 - UX Changes for Coupon Seller Bulk Upload Component v2
    @               : 09.12.2023 / Mony Nou / US-0014505 - Block Users from sending FVF contracts for approval that have more than 10k listings
    @               : 24.09.2024/ vadhanak voun/ US-0015465 - Cohort bulk upload - fail scenario messages
    @               : 07.11.2024/ Sophal Noch / US-0016137 - Enable Bulk Upload Lead for BD record type
    @               : 15/01/2025 / vadhanak voun / US-0016265 - (2) Upload Sub Deals in Hive
    @               : 03/07/2025 / Chansophorn Seng/ US-0033008 - Upload Deals functionality in DCA Sub Deals is ignoring the non copied columns
    @               : 11/12/2025 / Mony Nou / US-0033626 - POP - Ability for Coupon Managers to Upload Coupon Item Exclusions in HIVE
    @*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> getExcelImporterTemplate(String templateName, String parentId){
        Map<String,Object> mapResult = new Map<String,Object>();

        Map<String,Excel_Importer_Template__mdt> mapExcelImportTemp = new Map<String,Excel_Importer_Template__mdt>();
        Map<String,String> mapFldApiNameToFldLabel = new Map<String,String>();
        //NK:24/09/2024:US-0015465, NK:15/01/2025:US-0016265: Server_side_Post_DML__c, CSP:03/07/2025:US-0033008
        for(Excel_Importer_Template__mdt temp : (Excel_Importer_Template__mdt[])ApexSafe.query().secCheck(false).doQuery('SELECT Id,Server_side_Post_DML__c,MasterLabel, Subtitle__c, DeveloperName,'+
            'Excel_Column_Names__c,Use_Excel_Column_Header_Mapping__c,Mapped_Field_Names__c,'+
            'Sobject_Api_Name__c,Operator__c,Batch_Size__c,Description__c, Input_Placeholder__c,  '+
            'Allowed_Profiles__c,Allowed_Permission_Set__c,Allowed_Parent_RecordTypes__c, Parent_SObject_ApiName__c, All_Permissions_Or_None__c,'+ // 07.11.2024/ Sophal Noch / US-0016137 : add All_Permissions_Or_None__c
            'Required_Fields__c,Duplicated_Fields__c,Server_Side_Pre_DML_Check__c,  '+
            'Hide_Action_Buttons__c, Hide_Back_Button__c, Hide_Description__c, Hide_List_Table__c, Hide_Reset_Button__c, Hide_Template_Name__c, Hide_Upload_Button__c '+
            ', Use_Version_2__c, Step_1_Detail__c, Field_Guidance_Title__c, Field_Guidance_Detail__c, Step_2_Detail__c, Step_3_Detail__c, Step_3_Common_Error_Table__c, Step_4_Detail__c, Step_4_Common_Error_Table__c, Failed_File_Name__c'+
            ', Maximum_Records__c, Exceed_Maximum_Message__c,Validate_Header_Columns__c,Template_Link__c, Validate_Header_Columns_Client_Side__c, Validate_Header_Client_Side_Error_Msg__c, HideSwitch__c, MainTitle__c'+
            ' FROM Excel_Importer_Template__mdt WHERE DeveloperName =: templateName',new Map<String,Object>{'templateName'=>templateName})){ 
            mapExcelImportTemp.put(temp.DeveloperName, temp);
        }

        //  07.11.2024/ Sophal Noch / US-0016137 : move mapResult populations and empty check method to here to fix Apex PMD warning
        mapResult.put('mapExcelImportTemp',mapExcelImportTemp);
        mapResult.put('mapFldApiNameToFldLabel',mapFldApiNameToFldLabel);
        if(mapExcelImportTemp.isEmpty()){return mapResult;}

        Excel_Importer_Template__mdt temp = mapExcelImportTemp.values()[0];
        
        /*
            // 07.11.2024/ Sophal Noch / US-0016137 : disable calling method with serveral args below because it violates Apex PMD warning
            if(!isFromVfPage && !checkUserHasAccess(tptSetting.Allowed_Profiles__c,tptSetting.Allowed_Permission_Set__c, tptSetting.Allowed_Parent_RecordTypes__c, tptSetting.Parent_SObject_ApiName__c, parentId)){ mapResult.put(TXT_ERROR,Label.Generic_Error_No_Permission_On_Cmp); return mapResult; }
        */

        // 07.11.2024/ Sophal Noch / US-0016137 : call method checkUserHasAccess with metadata record instead of several args
        if(!mapExcelImportTemp.isEmpty() && !CSVExporterController.checkUserHasAccess(temp, parentId)){mapResult.put('hasNoPermission',true); return mapResult;}


        Map<String, String> mapApiFields = new  Map<String, String>();
        SObjectType sobjectType = Schema.getGlobalDescribe().get(temp.Sobject_Api_Name__c);
        Map<String,Schema.SObjectField> mfields = sobjectType.getDescribe().fields.getMap();
        for(String fieldApiName : mfields.keySet()){
            SObjectField sobjField = mfields.get(fieldApiName);
            String fieldLabel = sobjField.getDescribe().getlabel();
            mapApiFields.put(fieldApiName.toLowerCase(), fieldLabel); // 26.09.2022 / Sophal Noch / US-0011695 : get Label from salesforce by field api name
        }
        
        Set<String> setFldApiName = new Set<String>();
        for(String fieldApiName : temp.Mapped_Field_Names__c.split(';')){
            fieldApiName = fieldApiName.trim();
            String lowerCaseApiName = fieldApiName.toLowerCase();
            String fieldLabel = mapApiFields.get(lowerCaseApiName);
            if(String.isNotBlank(fieldLabel)){ // 26.09.2022 / Sophal Noch / US-0011695 : if field api name is matched, store Salesfore Field Label in Map Value
                mapFldApiNameToFldLabel.put(lowerCaseApiName, fieldLabel);
            }else{ // 26.09.2022 / Sophal Noch / US-0011695 : if field api name is not found, store original field label from custom meta data in Map Value
                mapFldApiNameToFldLabel.put(lowerCaseApiName, fieldApiName);
            }
        }
        
        //MN-24112023-US-0014106--START
        if (temp.Use_Version_2__c) { 
            String parentObjectLabel = Id.valueOf(parentId).getSObjectType().getDescribe().getLabel();
            mapResult.put('parentObjectLabel',parentObjectLabel);
        }
        //--END
        
        //MN-09122023-US-0014505 -- START
        if (temp.Maximum_Records__c > 0) {
            parentId = String.escapeSingleQuotes(parentId);
            String countQuery = 'SELECT COUNT() FROM ' + temp.Sobject_Api_Name__c + ' WHERE ' + temp.Parent_SObject_ApiName__c + ' = \'' + parentId + '\''; 
            //Integer count = Database.countQuery(countQuery);
            //NK:24/09/2024:US-0015465
            Integer count = ApexSafe.query().secCheck(false).doCount(countQuery);
            mapResult.put('existedRecords', count);
        } 
        //-- END

        return mapResult;
    }
    
    /*****************************************************************************************************************************
    @ Method:       getExcelImporterTemplate
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0011643 - SPIKE Implement Excel import module using JS to support copy paste
    @ Event:		when Upload from lwcExcelImporter page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	name of object : sobjectApiName, dml operator : operator, List of records to save : listRecord
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.06.2022  / Sophal Noch / Created the method.
    @ Change history: 26.09.2022 / Sophal Noch / US-0011695 - ADS- CSV upload of attribution data on product
    @               : 19.05.2023 / Sophal Noch / US-0013298 - Bulk Upload Lead, replace it with xl copy, paste feature
    @               : 24.07.2023 / sovantheany dim / US-0013870 - Change cohort bulk upload file to new Bulk Upload type (like we have for coupons)
    @               : 25.09.2023 / Sophal Noch / US-0014118 - ADS - New Cohort seller bulk upload template
    @               : 07.11.2024/ Sophal Noch / US-0016137 - Enable Bulk Upload Lead for BD record type
    @*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> saveRecords(String sobjectApiName, String operator, List<Map<String,String>> listRecord, String templateName){
        Map<String,Object> mapResult = new Map<String,Object>();
        Savepoint sp = Database.setSavepoint();
        
        try{
            // 19.05.2023 / Sophal Noch / US-0013298 : add field Default_Values__c to query
            // 24.07.2023:TH:US-0013870 - add field Unique_key__c to query
            // 25.09.2023 / Sophal Noch / US-0014118 : add Enable_WithoutSharing__c to query

            /* 
                 //  07.11.2024/ Sophal Noch / US-0016137 : disable Static SOQL
                 List<Excel_Importer_Template__mdt> temp = [SELECT Id,Skipped_Field_Names__c,Mapped_Field_Types__c, Default_Values__c,Unique_key__c, Enable_WithoutSharing__c FROM Excel_Importer_Template__mdt WHERE DeveloperName =: templateName];
            */
            
            //  07.11.2024/ Sophal Noch / US-0016137 : use apex safe to query 
            List<Excel_Importer_Template__mdt> temp = (List<Excel_Importer_Template__mdt>)ApexSafe.query().secCheck(false).doQuery('SELECT Id,Skipped_Field_Names__c,Mapped_Field_Types__c, Default_Values__c,Unique_key__c, Enable_WithoutSharing__c FROM Excel_Importer_Template__mdt WHERE DeveloperName =: templateName',new Map<String,Object>{'templateName'=>templateName});
            
            Set<String> setSkippedFields = new Set<String>();
            if(!temp.isEmpty() && String.isNotBlank(temp[0].Skipped_Field_Names__c)){
                for(String skippedField : temp[0].Skipped_Field_Names__c.split(';')){
                    if(String.isNotBlank(skippedField)) { setSkippedFields.add(skippedField.trim().toLowerCase()); }   // 26.09.2022 / Sophal Noch / US-0011695 : store fields that are skipped in DML
                }
            }

            Map<String,String> mapFieldToType = new Map<String,String>();
            if(!temp.isEmpty() && String.isNotBlank(temp[0].Mapped_Field_Types__c)){
                for(String mapFiedlType : temp[0].Mapped_Field_Types__c.split(';')){
                    List<String> fieldTypes = mapFiedlType.split(':');  // 12.12.2022 / Sophal Noch / US-0012119 fix issue when there are mutliple field types
                    mapFieldToType.put(fieldTypes[0].trim().toLowerCase(),fieldTypes[1].trim().toLowerCase()); // 26.09.2022 / Sophal Noch / US-0011695 : store fields types, so field value are formatted with correct type of value.
                }
            }

            Map<String,String> mapFieldToDefaultVals = new Map<String,String>(); // 19.05.2023 / Sophal Noch / US-0013298 : get default values from custom metadata type to populate on fields
            if(!temp.isEmpty() && String.isNotBlank(temp[0].Default_Values__c)){
                for(String mapFiedlVal : temp[0].Default_Values__c.split(';')){
                    List<String> fieldDefaultVal = mapFiedlVal.split(':');
                    mapFieldToDefaultVals.put(fieldDefaultVal[0].trim().toLowerCase(),fieldDefaultVal[1].trim()); //  07.11.2024/ Sophal Noch / US-0016137 : remove lowercase on fieldDefaultVal[0] so that there is no error for field RecordTypeId
                }
            }

            List<SObject> listSobject = new List<SObject>();
            SObject newObj = Schema.getGlobalDescribe().get(sobjectApiName).newSObject();
            List<List<String>> listInitSObjResult = new List<List<String>>();
            for(Map<String,String> mapObj : listRecord){
                SObject eachSobject = newObj.clone(false,false,false,false);
                try{
                    for(String key : mapObj.keySet()){
                        String fieldApiName = key.toLowerCase().trim();
                        if(!setSkippedFields.contains(fieldApiName)){
                            // for upsert dml, skip when id column exists but id field value is blank to avoid upserting error.
                            if(operator == DML_UPSERT && fieldApiName == 'id' && String.isBlank(String.valueOf(mapObj.get(key)))) {continue;}
                            eachSobject.put(key.trim(), getValueByType(mapFieldToType.get(fieldApiName), mapObj.get(key)));  // 26.09.2022 / Sophal Noch / US-0011695 : use method getValueByType to covert value to correct type.
                        }
                        if(!mapFieldToDefaultVals.isEmpty()){mapFieldToDefaultVals.remove(fieldApiName);} // 19.05.2023 / Sophal Noch / US-0013298 : if field is included in excel file, remove field from map default value to avoid overriding excel field
                    }
                    if(operator == DML_INSERT && !mapFieldToDefaultVals.isEmpty()){  // 19.05.2023 / Sophal Noch / US-0013298 : populate default value when operator is insert.
                        for(String fieldApiName : mapFieldToDefaultVals.keySet()){
                            eachSobject.put(fieldApiName, getValueByType(mapFieldToType.get(fieldApiName), mapFieldToDefaultVals.get(fieldApiName)));
                        }
                    }
                    listSobject.add(eachSobject);
                    listInitSObjResult.add(new List<String>{null, String.valueOf(listSobject.size()-1)});  // 27.09.2022 / Sophal Noch / US-0011695 : When No Error With Field Value Type, listInitSObjResult index 0 is null and listInitSObjResult index 1 has index of listInitSObjResult 
                }catch(Exception e){ listInitSObjResult.add(new List<String>{e.getMessage(), null}); } // 27.09.2022 / Sophal Noch / US-0011695 : When Error with Field Value Type, listInitSObjResult index 0 is error message and listInitSObjResult index 1 = null
            }
            List<Map<String,Object>> listResult = new List<Map<String,Object>>();
            List<Database.SaveResult> listSaveResult = new List<Database.SaveResult>();
            List<Database.UpsertResult> listUpsertResult = new List<Database.UpsertResult>();
            if(!listSobject.isEmpty()){
                if(operator == DML_INSERT || operator == DML_UPDATE){
                    if(operator == DML_INSERT){
                        if(!temp.isEmpty() && temp[0].Enable_WithoutSharing__c){ // 25.09.2023 / Sophal Noch / US-0014118 : add without sharing insert to bypass record access error like "ViewAllData or ViewAllRecords required to access" ... etc
                            listSaveResult = WithoutSharing.doInsert(listSobject, false);
                        }else{
                            listSaveResult = Database.insert(listSobject, false);
                        }
                        
                    }else if(operator == DML_UPDATE){ 
                        if(!temp.isEmpty() && temp[0].Enable_WithoutSharing__c){ // 25.09.2023 / Sophal Noch / US-0014118 : add without sharing update to bypass record access error like "ViewAllData or ViewAllRecords required to access" ... etc
                            listSaveResult = WithoutSharing.doUpdate(listSobject, false);
                        }else{
                            listSaveResult = Database.update(listSobject, false);
                        }
                        
                    }
                }
                else if(operator == DML_UPSERT){

                    //24.07.2023:TH:US-0013870 - get Unique_key__c for upsert if not empty
                    String strId= 'Id';
                    if(!temp.isEmpty() && String.isNotBlank(temp[0].Unique_key__c)){
                        strId = temp[0].Unique_key__c;
                    }
                    Schema.SObjectField uniqueId = Schema.getGlobalDescribe().get(sobjectApiName).getDescribe().fields.getMap().get(strId);
                    //set to true, so Account_Manager__c is auto populate from parent in BoBSellerTriggerHandler.populateBobSeller, if bobSeller.Account_Manager__c == null
                    if(sobjectApiName == 'BoB_Seller__c') Batch_BobSellerBulkCSV.isBatchBobSeller = true;
                    //End US-0013870

                    //listUpsertResult = Database.upsert(listSobject,false);
                    if(!temp.isEmpty() && temp[0].Enable_WithoutSharing__c){ // 25.09.2023 / Sophal Noch / US-0014118 : add without sharing upsert to bypass record access error like "ViewAllData or ViewAllRecords required to access" ... etc
                        listUpsertResult = WithoutSharing.doUpsert(listSobject, uniqueId, false);
                    }else{
                        listUpsertResult = Database.upsert(listSobject,uniqueId, false);
                    }
                    
                } 
            }

            for(List<String> initResult : listInitSObjResult){
                if(initResult[0] != null){  // 27.09.2022 / Sophal Noch / US-0011695 : this error is not from DML, it is from field value has incorrect type
                    populateResultMsg(operator, false, initResult[0], listResult);   
                }else if((operator == DML_INSERT || operator == DML_UPDATE) && !listSaveResult.isEmpty()){
                    Database.SaveResult result = listSaveResult[Integer.valueOf(initResult[1])];
                    populateResultMsg(operator, result.isSuccess(), (result.isSuccess() ? null : result.getErrors()[0].getMessage()), listResult);
                }else if(operator == DML_UPSERT && !listUpsertResult.isEmpty()){
                    Database.UpsertResult result = listUpsertResult[Integer.valueOf(initResult[1])];
                    String upsertOperator = result.isCreated() ? 'Insert' : 'Update';//TH:US-0013870 : add Operator insert/Update for Upsert result
                    populateResultMsg(upsertOperator, result.isSuccess(), (result.isSuccess() ? null : result.getErrors()[0].getMessage()), listResult);
                }
                mapResult.put(TXT_LIST_RESULT,listResult); // return result of upsert
            }

            if(listResult.isEmpty()){mapResult.put('status','ko'); mapResult.put('error',Label.ExcelImporter_Error_NoSaveResult);  return mapResult;}
            mapResult.put('status','ok');
            
        }catch(Exception ex){ Database.rollback(sp); mapResult.put('status','ko'); mapResult.put('error',ex.getMessage());}
        return mapResult;
    }

    private static void populateResultMsg(String operator, Boolean isSuccess, String msg, List<Map<String,Object>> listResult){
        if (isSuccess) {
            listResult.add(new Map<String,Object>{'isSucess'=>true,'msg'=>String.format(SUCCESS_MSG_TEMPLATE, new String[]{operator})});
        }else {
            listResult.add(new Map<String,Object>{'isSucess'=>false,'msg'=>String.format(ERROR_MSG_TEMPLATE, new String[]{operator,msg})});
        }
    }

    private static Object getValueByType(String fieldType, String fieldValue){
        // 26.09.2022 / Sophal Noch / US-0011695 :
        Boolean isEmpty = String.isEmpty(fieldValue);
        Object returnFieldVal = fieldValue;
        if(fieldType == DATA_TYPE_DECIMAL) { returnFieldVal = isEmpty ? null : Decimal.valueOf(fieldValue); }
        else if(fieldType == DATA_TYPE_NUMBER) { returnFieldVal = isEmpty ? null : Integer.valueOf(fieldValue); }
        else if(fieldType == DATA_TYPE_DATE) { returnFieldVal = isEmpty ? null : Date.valueOf(fieldValue); }  // 12.12.2022 / Sophal Noch / US-0012119
        else if(fieldType == DATA_TYPE_TIME && !isEmpty) { returnFieldVal = isEmpty ? null : (Time.newInstance(Integer.valueOf(fieldValue.split(':')[0]),Integer.valueOf(fieldValue.split(':')[1]),0,0)); }  // 12.12.2022 / Sophal Noch / US-0012119
        else if(fieldType == DATA_TYPE_BOOLEAN) { returnFieldVal = isEmpty ? false : Boolean.valueOf(fieldValue); } // 19.05.2023 / Sophal Noch / US-0013298
        return returnFieldVal;
    }

    /*****************************************************************************************************************************
    @ Method:       serverSidePreDMLCheck
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0012119 - Standard Deal (V1) Upload functionality - Extend excel copy paste feature
    @ Event:		when Upload from lwcExcelImporter page but before DML method is callled
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	apex class name to call : className, apex method name to call : methodName, method arguments as a map collection: mapArgs
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.12.2022  / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> serverSidePreDMLCheck(String className, String methodName, Map<String, Object> mapArgs){
        
        // method to call any other methods to validate and populate fields on a list of records before DML operation
        // What Method to call is defined in Custom Metadata Type Named "Excel Importer Template", so it can call dynamically for each custom metadata type.
        
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            Callable extension = (Callable) Type.forName(className).newInstance();
            mapResult = (Map<String, Object>) extension.call(methodName, mapArgs);
        }catch(Exception ex){mapResult.put('status','ko'); mapResult.put('error',ex.getMessage()); return mapResult;}

        return mapResult;
        
    }

    /*********************************************************************************************************************************
    @ Method:         bulkExport
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014165 - Cohort - Bulk export functionality
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  17.10.2023 / Sophal Noch / Created the method.
                    :  14/01/2025 / Sovantheany Dim / US-0016358 - (3) Data Import and Export from Deal Contract Agreement
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> bulkExport(String templateName, String parentId){
        Map<String, Object> mapResult = new Map<String, Object>();
        try{

            //Excel_Importer_Template__mdt template = [SELECT Id, Export_Name__c, Sobject_Api_Name__c, Excel_Column_Names__c, Mapped_Field_Names__c, Export_Filter__c, Export_Separator__c, Export_Replacing_Field__c FROM Excel_Importer_Template__mdt WHERE DeveloperName =: templateName Limit 1];
            Excel_Importer_Template__mdt[] templates = (Excel_Importer_Template__mdt[]) ApexSafe.query().secCheck(false).doQuery('SELECT Id, Export_Name__c, Sobject_Api_Name__c, Excel_Column_Names__c, Mapped_Field_Names__c, Export_Filter__c, Export_Separator__c, Export_Replacing_Field__c,Mapped_Field_Types__c FROM Excel_Importer_Template__mdt WHERE DeveloperName =: templateName Limit 1',new Map<String,Object>{'templateName'=>templateName});
            Excel_Importer_Template__mdt template = templates[0];

            String separator = String.isNotBlank(template.Export_Separator__c) ? template.Export_Separator__c : ',';

            List<String> listColHeaderStr = template.Excel_Column_Names__c.split(';');
            String columnHeader = String.join(listColHeaderStr, separator); // use exist header from bulk import for exporting csv header
            
            //TH:14/01/2024:US-0016358 : map field API with Field type
            Map<String,String> mapFieldToFormat = new Map<String,String>();
            // set<String> soqlQueryTypeToFormats = new set<String>{'time','date'};
            set<String> soqlQueryTypeToFormats = new set<String>{'date'};
            if(String.isNotBlank(template.Mapped_Field_Types__c)){
                for(String mapFiedlType : template.Mapped_Field_Types__c.split(';')){
                    List<String> fieldTypes = mapFiedlType.split(':');
                    //get field api with type = date or time
                    if(soqlQueryTypeToFormats.contains(fieldTypes[1].trim().toLowerCase())) {
                        mapFieldToFormat.put(fieldTypes[0].trim().toLowerCase(),fieldTypes[1].trim().toLowerCase());
                    }
                }
            }
            //End : US-0016358 : map field type

            List<String> listMappedField = new List<String>();
            Set<String> setFieldToQuery = new Set<String>();
            Map<String,String> mapFieldColHeader = new Map<String,String>();//TH:14/01/2024:US-0016358: Mapped Field API with Excel Column Name
            Integer i = 0;//TH:14/01/2024:US-0016358
            for(String mappedFieldName : template.Mapped_Field_Names__c.split(';')){ // use exist mapped fields from bulk import for exporting csv rows
                listMappedField.add(mappedFieldName);
                
                //TH:14/01/2024:US-0016358 : format field in SOQL query : EX : select format(EBH_DealStartDate__c) ,format(EBH_DealEndTime__c) from EBH_Deal__c
                if(mapFieldToFormat.containsKey(mappedFieldName.trim().toLowerCase())){
                    setFieldToQuery.add('format('+mappedFieldName+')');//format to get User local format
                }else{
                    setFieldToQuery.add(mappedFieldName);
                }
                //END : US-0016358 : format field in SOQL query
                mapFieldColHeader.put(mappedFieldName,listColHeaderStr[i]);//TH:14/01/2024:US-0016358: Mapped Field API with Excel Column Name
                i++;
            }

            Map<String,String> mapFieldToExportField = new Map<String,String>();
            if(String.isNotBlank(template.Export_Replacing_Field__c)){  // get fields to replace fields from mapped fields / csv rows
                for(String replaceFields : template.Export_Replacing_Field__c.split(';')){
                    String field = replaceFields.split(':')[0];
                    String exportField = replaceFields.split(':')[1];
                    mapFieldToExportField.put(field, exportField);
                    if(!setFieldToQuery.contains(exportField)){
                        setFieldToQuery.add(exportField);
                    }
    
                }
            }

            List<String> listFieldToQuery = new List<String>();
            listFieldToQuery.addAll(setFieldToQuery);
            String queryField = String.join(listFieldToQuery, ',');
            String[] arrStatement = new String[]{ queryField, template.Sobject_Api_Name__c};
            String queryStr = String.format(STR_QUERY, arrStatement);

            String whereCondition = '';
            if(String.isNotBlank(template.Export_Filter__c)) { whereCondition = ' Where ' + String.format(template.Export_Filter__c, new String[]{parentId});}

            queryStr = queryStr + whereCondition;

            String rowRecord = '';

            List<Map<String,Object>> lstSobjectNew = new List<Map<String,Object>>();//TH:14/01/2024:US-0016358: Mapped Field API and feild value

            //List<SObject> listSobject = Database.query(queryStr);
            List<SObject> listSobject = ApexSafe.query().secCheck(false).doQuery(queryStr);
            for(SObject sobj : listSobject){
                Map<String,Object> sObjectNew = new Map<String,Object>(); //TH:14/01/2024:US-0016358: New Map Field API and feild value
                rowRecord += '\n';
            
                List<String> rowValue = new List<String>();
                for(String fieldApiName : listMappedField){

                    String fieldToExport = mapFieldToExportField.containsKey(fieldApiName) ? mapFieldToExportField.get(fieldApiName) : fieldApiName; // replace mapped field with field to export. example : Account_Manager__c -> Account_Manager__r.FederationIdentifier
                    
                    Object fieldValObj = ApexUtil.getValue(fieldToExport, sobj);
                    String fieldValStr = fieldValObj != null ? String.valueOf(fieldValObj) : '';
                    rowValue.add(fieldValStr); // populate row value

                    //TH:14/01/2024:US-0016358: Mapped Field API and feild value
                    sObjectNew.put(fieldApiName,fieldValObj != null ? fieldValObj : '');
                    //END:US-0016358:Mapped Field API and field value
                }
                rowRecord += String.join(rowValue, separator);  // combine row values into 1 row
                lstSobjectNew.add(sObjectNew);//TH:14/01/2024:US-0016358
            }
    

            mapResult.put('status', 'ok');
            mapResult.put('content', (columnHeader + rowRecord));
            mapResult.put('exportName', template.Export_Name__c);

            //TH:14/01/2024:US-0016358
            mapResult.put('lstSobjectNew', lstSobjectNew);
            mapResult.put('mapFieldColHeader', mapFieldColHeader);
            //End:US-0016358

        }catch(Exception e){ mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}

        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         sendEmailResult
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0013554 - Deal (V2) Upload functionality to be replaced with Copy paste feature
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  26.10.2023 / Sambath Seng / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    @AuraEnabled
    public static void sendEmailResult(Integer insertedCount, List<String> listError){
    	User currentUser = ApexUtil.getCurrentUser();
    	String templateName = 'Deal_Bulk_Upload_Result';
    	List<EmailTemplate>  empt = Database.query(SOQL_EMAIL_TEMPLATE);
    	
    	String htmlBody = empt[0].HtmlValue.replace('{UploadUser}',currentUser.Name)
				.replace('{DateTimeUploading}',System.now().format())
				.replace('{totalSuccessDeals}',String.valueOf(insertedCount))
				.replace('{listRecordsFail}',String.join(listError,'<br/>'))
				.replace('{isError}',listError.size()>0 ? 'block':'none');	
    	
	    if(!Test.isRunningTest()) ApexUtil.doSend(empt[0].subject,currentUser.Email,htmlBody);
    }


    private static List<Excel_Importer_Template__mdt> getMetadata(String templateName)
    {
        return  (List<Excel_Importer_Template__mdt>)ApexSafe.query().secCheck(false).doQuery('SELECT Id,Server_side_Post_DML__c,Skipped_Field_Names__c,Mapped_Field_Types__c, Default_Values__c,Unique_key__c, Enable_WithoutSharing__c FROM Excel_Importer_Template__mdt WHERE DeveloperName =: templateName',new Map<String,Object>{'templateName'=>templateName});
    }
   


    /*****************************************************************************************************************************
    @ Method:       processPostDML
    @ Author:       vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      US-0016265 - (2) Upload Sub Deals in Hive
    @ Event:		after SaveRecord completed successfully
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	postData, Post DML method name : templateName
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.01.2025  / vadhanak voun / Created the method.
    @*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexProcessPostDML(Map<String,String>postData,String templateName)
    {
        List<Excel_Importer_Template__mdt> impMeta = getMetadata(templateName);
        if(String.isNotBlank(impMeta[0].Server_side_Post_DML__c))
        {
            IPostDML postDML = (IPostDML)ApexUtil.getInstance(null, impMeta[0].Server_side_Post_DML__c);
            if(postDML != null)
            {
                return ((PostDMLBase)postDML).assignData(postData,impMeta[0]).doPostDML();
            }
        }
        return  new Map<String,Object>{'status'=>'ko','error'=>'No Server_side_Post_DML__c'};
    }

    public interface IPostDML{
        Map<String,Object> doPostDML();
    }

    //NK:22/02/2025:US-0016262. to public
    public abstract class PostDMLBase implements IPostDML{
        protected Excel_Importer_Template__mdt impMeta;
        protected Map<String,String> postData;

        public PostDMLBase assignData(Map<String,String>postData,Excel_Importer_Template__mdt impMeta)
        {
            this.impMeta = impMeta;
            this.postData = postData;
            return this;
        }
        public abstract Map<String,Object> doPostDML();
    }  

    // CSP:21/07/2025:US-0033145. assign ebay seller name to seller name field.
    public class SubDealUploadDCAPostDML extends PostDMLBase{

        public override Map<String,Object> doPostDML()
        {
            Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
            String dcaId = postData.get('parentId');
            try 
            {
                //CSP:21/07/2025:US-0033145 start
                String soqlDCA = 'Select eBay_Seller__c,eBay_Seller__r.Name From  Deal_Contract_Agreement__c Where Id=:dcaId';
                List<Deal_Contract_Agreement__c> listDCA = (Deal_Contract_Agreement__c[])ApexSafe.query(true).secCheck(false).doQuery(soqlDCA,new Map<String,Object>{'dcaId'=>dcaId});
                //CSP:21/07/2025:US-0033145 end
                Deal_Contract_Agreement__c dcaToUpdate = new Deal_Contract_Agreement__c(
                    Id = dcaId,
                    Status__c ='In Progress', 
                    Seller_Name__c = listDCA[0].eBay_Seller__r.Name //CSP:21/07/2025:US-0033145
                );
                ApexSafe.dml().doUpdate(new List<Deal_Contract_Agreement__c>{dcaToUpdate}, true);

            } catch (DmlException dex) 
            {
                mapResult.put('status','ko');mapResult.put('error',dex.getMessage());mapResult.put('detail',dex.getStackTraceString()); System.debug(LoggingLevel.Error, dex.getStackTraceString());
            }
            return mapResult;
        }
    }
}