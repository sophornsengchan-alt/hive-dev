/*********************************************************************************************************************************
@ Class:          ExcelImporterControllerSEP
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0013657 - Bulk Upload - Copy Paste Functionality in Seller Portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 07.06.2023 / Sophal Noch / Create Class
@               : 07.11.2024/ Sophal Noch / US-0016137 - Enable Bulk Upload Lead for BD record type
@               : 22/02/2025 / vadhanak voun / US-0016262 - 10 - Seller Portal - Upload Sub Deals
*********************************************************************************************************************************/
public with sharing class ExcelImporterControllerSEP extends ExcelImporterController{
 
    private static final String SOQL_IMPORTER = 'SELECT Id,MasterLabel, Subtitle__c, DeveloperName, Input_Placeholder__c,'
                                            + 'Sobject_Api_Name__c, Allowed_Profiles__c,Allowed_Permission_Set__c,Allowed_Parent_RecordTypes__c, Parent_SObject_ApiName__c, All_Permissions_Or_None__c'
                                            + ' FROM Excel_Importer_Template__mdt WHERE DeveloperName =: templateName'; // 07.11.2024/ Sophal Noch / US-0016137

    /*********************************************************************************************************************************
    @ Method:         getExcelImporterTemplate
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0013657 - Bulk Upload - Copy Paste Functionality in Seller Portal
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.06.2023 / Sophal Noch / Create Method
    @               : 07.11.2024/ Sophal Noch / US-0016137 - Enable Bulk Upload Lead for BD record type
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> getExcelImporterTemplate(String templateName, String parentId){

        // get data from custom metdata Excel_Importer_Template__mdt to build lwc component copy/paste

        Map<String,Object> mapResult = new Map<String,Object>();
        Map<String,Excel_Importer_Template__mdt> mapExcelImportTemp = new Map<String,Excel_Importer_Template__mdt>();
        /*
            //  07.11.2024/ Sophal Noch / US-0016137 : disable Static SOQL
            for(Excel_Importer_Template__mdt temp : [SELECT Id,MasterLabel, Subtitle__c, DeveloperName, Input_Placeholder__c,
                Sobject_Api_Name__c, Allowed_Profiles__c,Allowed_Permission_Set__c,Allowed_Parent_RecordTypes__c, Parent_SObject_ApiName__c, All_Permissions_Or_None__c
                FROM Excel_Importer_Template__mdt WHERE DeveloperName =: templateName]){ 
                mapExcelImportTemp.put(temp.DeveloperName, temp);
            }
        */

        //  07.11.2024/ Sophal Noch / US-0016137 : use apex safe to query 
        for(Excel_Importer_Template__mdt temp : (List<Excel_Importer_Template__mdt>)ApexSafe.query().secCheck(false).doQuery(SOQL_IMPORTER,new Map<String,Object>{'templateName'=>templateName})){
            mapExcelImportTemp.put(temp.DeveloperName, temp);
        }

        if(!mapExcelImportTemp.isEmpty()){

            Excel_Importer_Template__mdt temp = mapExcelImportTemp.values()[0];

            //  07.11.2024/ Sophal Noch / US-0016137 : disable calling method with serveral below args because it violates Apex PMD warning
            // if(!CSVExporterController.checkUserHasAccess(temp.Allowed_Profiles__c,temp.Allowed_Permission_Set__c, temp.Allowed_Parent_RecordTypes__c, temp.Parent_SObject_ApiName__c, parentId)){mapResult.put('hasNoPermission',true); return mapResult;}
            
            if(!CSVExporterController.checkUserHasAccess(temp, parentId)){mapResult.put('hasNoPermission',true); return mapResult;}  // 07.11.2024/ Sophal Noch / US-0016137 : call method with metadata record instead of serveral args
            
            mapResult.put('mapExcelImportTemp',mapExcelImportTemp);
        }


        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:       processPostDML
    @ Author:       vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      fr POST DML/Process after upload completed successfully from SEP
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	postData, Post DML method name : templateName
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.02.2025  / vadhanak voun / Created the method.
    @                                             / US-0016262 - 10 - Seller Portal - Upload Sub Deals. 
    @                                             / DealBulkUploadDcaSubController.SubDealUploadDCAPostDMLSEP
    @*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexProcessPostDMLSEP(Map<String,String>postData,String templateName)
    {
        return  ExcelImporterController.apexProcessPostDML(postData, templateName);
    }
     
}