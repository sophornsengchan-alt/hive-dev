/*********************************************************************************************************************************
@ Class:         CustomRelatedListController
@ Author:        Acmatac SEING
@ Purpose:       US-0010792 - New Custom Related List component to replace standard related list on "Deal Window" for Deals
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17/02/2022 / Acmatac SEING / Created the class.
@               : 06/11/2023 / Sovantheany Dim / US-0014273 - Add Account Manager/ Status field in filter in Bulk Select Cohort Seller Page
*********************************************************************************************************************************/

public with sharing class CustomRelatedListController {
    public String mainObject {get;set;}

    public List<WebLinkWrapper> lstWebLink {get;set;}
    public final static String REFERENCE_FIELD_SUFFIX = '__c';
    public final static String DEPENDANT_VALUE_SEPERATOR = '=';
    public final static String ARRAY_VALUE_SEPERATOR = ';';
    public final static String PARAMETER_IS_FROM_CUSTOM_RELATEDLIST = 'from_custom_related_list';
	
    public void initVFPage(){
        lstWebLink = new List<WebLinkWrapper>();
        String metadataRecordName = Apexpages.currentpage().getparameters().get('metadata_record_name');
        Custom_Related_List_Metadata__mdt crlm = [SELECT DeveloperName
                                                    , Column_FieldSet__c
                                                    , Filter_FieldSet__c
                                                    , Child_Object__c
                                                    , Parent_Object__c
                                                    , Lookup_Field__c
                                                    , Visible_Custom_Buttons__c
                                                FROM Custom_Related_List_Metadata__mdt WHERE DeveloperName =: metadataRecordName];

        this.mainObject = crlm.Child_Object__c;
        Set<String> lstVisibleCustomButtonName = new Set<String>();
        for(String vcb : crlm.Visible_Custom_Buttons__c.split(ARRAY_VALUE_SEPERATOR)){
            if(String.isNotBlank(vcb)){
                lstVisibleCustomButtonName.add(vcb.trim());
            }
            
        }
        for(WebLink wl : [SELECT Id, Name, MasterLabel, RequireRowSelection FROM WebLink WHERE PageOrSobjectType =: crlm.Child_Object__c AND Name IN: lstVisibleCustomButtonName]){
            WebLinkWrapper oWeblink = new WebLinkWrapper();
            oWeblink.name = wl.Name;
            oWeblink.masterLabel = wl.MasterLabel;
            oWeblink.requireRowSelection = wl.RequireRowSelection;
            lstWebLink.add(oWeblink);
        }
    }
    
    
    /*********************************************************************************************************************************
    @ Change history: 28/04/2022 / Acmatac SEING / US-0011577 - UAT Feedback for NA Deals Custom List view
    @               : 06/11/2023 / Sovantheany Dim / US-0014273 - Add Account Manager/ Status field in filter in Bulk Select Cohort Seller Page
    *********************************************************************************************************************************/
    @AuraEnabled
    public static RemoteResponse apexInit(String settingRecordName, String parentRecordId){
        RemoteResponse rrs = new RemoteResponse();
        try {
            Custom_Related_List_Metadata__mdt crlc = [SELECT DeveloperName
                                                    , Column_FieldSet__c
                                                    , Filter_FieldSet__c
                                                    , Child_Object__c
                                                    , Parent_Object__c
                                                    , Lookup_Field__c
                                                    , Dependent_Picklist__c
                                                FROM Custom_Related_List_Metadata__mdt WHERE DeveloperName =: settingRecordName];
            //
            // US-0011577: Show dependent picklist value, value example: EBH_Country__c=EBH_Category__c	
            Map<String, String> mDependentField = new Map<String, String>();
            if(String.isNotBlank(crlc.Dependent_Picklist__c)){
                for(String dpVal: crlc.Dependent_Picklist__c.deleteWhitespace().split(ARRAY_VALUE_SEPERATOR)){
                    String[] val = dpVal.split(DEPENDANT_VALUE_SEPERATOR);
                    mDependentField.put(val[1], val[0]);
                }
            }

            List<TableColumn> listTableColumn = new List<TableColumn>();
            Set<String> sObjFields = new Set<String>();
            Set<String> controllingFields = new Set<String>();

            Schema.DescribeSObjectResult objDescr = Schema.getGlobalDescribe().get(crlc.Child_Object__c).getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objDescr.fields.getMap();
            for(Schema.FieldSetMember fieldSetMemberObj : objDescr.FieldSets.getMap().get(crlc.Column_FieldSet__c).getFields()){
                Schema.DescribeFieldResult fieldRES = fieldMap.get(fieldSetMemberObj.getFieldPath()).getDescribe();

                TableColumn tblCol = new TableColumn();
                tblCol.label = fieldSetMemberObj.getLabel();
                tblCol.developerName = fieldSetMemberObj.getFieldPath(); //api name
                tblCol.type = String.valueOf(fieldSetMemberObj.getType()); //type - STRING,PICKLIST
                tblCol.isCustom = fieldRES.isCustom();
                tblCol.isNameField = fieldRES.isNameField();
                
                if(tblCol.type.equals(String.valueOf(Schema.DisplayType.REFERENCE))){
                    String fAPI = tblCol.developerName;
                    if(fieldRES.isCustom()){
                        // Add Id to Query, prevent SOQL not SELECT ID causing Null
                        sObjFields.add(fAPI.replace(REFERENCE_FIELD_SUFFIX,'__r.Id'));

                        fAPI = fAPI.replace(REFERENCE_FIELD_SUFFIX,'__r.Name');
                    }else{
                        // Add Id to Query, prevent SOQL not SELECT ID causing Null
                        sObjFields.add(fAPI+'.Id');
                        
                        fAPI += '.Name';
                    }
                    tblCol.developerName = fAPI;
                }

                if(fieldRES.isDependentPicklist() && mDependentField.containsKey(tblCol.developerName)){
                    controllingFields.add(fieldRES.getController().getDescribe().getName());
                }

                listTableColumn.add(tblCol);
                //sObjFields.add(tblCol.developerName);
                //TH:US-0014273: if field is picklist, then use toLabel() to get the label
                sObjFields.add(tblCol.type.equals(String.valueOf(Schema.DisplayType.PICKLIST)) ? 'toLabel('+tblCol.developerName+')' : tblCol.developerName);
            }

            Set<String> dependentFields = new Set<String>(mDependentField.values());
            SObject parentRecordSobj = Database.Query('SELECT Name'+(dependentFields.isEmpty()?'':',')+String.join((Iterable<String>)dependentFields, ',')+' FROM '+crlc.Parent_Object__c+' WHERE Id =: parentRecordId LIMIT 1');

            // Get all Filter fields
            List<Map<String,String>> listFilterFields = new List<Map<String,String>>();
            
            Map<String, List<Map<String,String>>> mapPicklistVal = new Map<String, List<Map<String,String>>>();
            for(Schema.FieldSetMember f : objDescr.FieldSets.getMap().get(crlc.Filter_FieldSet__c).getFields()) {
                Schema.DescribeFieldResult fieldRES = fieldMap.get(f.getFieldPath()).getDescribe();

                String fLabel = f.getLabel();
                String fAPI = f.getFieldPath();
                String fType = String.valueOf(f.getType());

                // Acmatac SEING, 28/04/2022, US-0011577 - Make lookup field can search in filter
                if(String.valueOf(f.getType()).equals(String.valueOf(Schema.DisplayType.REFERENCE))){
                    // fType = 'STRING';
                    if(fieldRES.isCustom()){
                        fAPI = fAPI.replace(REFERENCE_FIELD_SUFFIX,'__r.Name');
                    }else{
                        fAPI += '.Name';
                    }
                }
                listFilterFields.add(new Map<String,String>{
                    'label' =>  fLabel,
                    'value' =>  fAPI,
                    'type'  =>  fType
                });

                // Display picklist value for selection
                if(f.getType() == Schema.DisplayType.Picklist || f.getType() == Schema.DisplayType.MultiPicklist){
                    // Do get dependent picklist
                    if(fieldRES.isDependentPicklist() && mDependentField.containsKey(fAPI)){
                        String control_field = fieldRES.getController().getDescribe().getName();
                        Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDepPicklistVal = ApexUtil.getDependentMap(((SObject) Type.forName(crlc.Child_Object__c).newInstance()).getSObjectType(), control_field, fAPI);

                        if (pklDepPicklistVal.containsKey(String.valueOf(parentRecordSobj.get(mDependentField.get(fAPI))))) {
                            for (ApexUtil.PicklistEntryWrapper plew : pklDepPicklistVal.get(String.valueOf(parentRecordSobj.get(mDependentField.get(fAPI))))) {
                                if(!mapPicklistVal.containsKey(f.getFieldPath())) {
                                    mapPicklistVal.put(f.getFieldPath(),new List<Map<String,String>>());
                                }
                                mapPicklistVal.get(f.getFieldPath()).add(new Map<String,String>{'label'=>plew.label,'value'=>String.isBlank(plew.value)?'':String.escapeSingleQuotes(plew.value)});
                            }
                        }
                    }else{
                        for(Schema.PicklistEntry pkl: fieldRES.getPicklistValues())
                        {
                            if(!mapPicklistVal.containsKey(f.getFieldPath()))
                            {
                                mapPicklistVal.put(f.getFieldPath(),new List<Map<String,String>>());
                            }
                            mapPicklistVal.get(f.getFieldPath()).add(new Map<String,String>{'label'=>pkl.getLabel(),'value'=>String.isBlank(pkl.getValue())?'':String.escapeSingleQuotes(pkl.getValue())});
                        }
                    }
                }

            }
            
            Map<String, EntityDefinition> mapObjDefinition = getObjectDefinition(new Set<String>{crlc.Parent_Object__c, crlc.Child_Object__c});

            String baseSOQL = 'SELECT Id,'+String.join((Iterable<String>)sObjFields, ',')+' FROM '+crlc.Child_Object__c+' ';
            String whereSOQL = ' WHERE '+crlc.Lookup_Field__c+'=\''+String.escapeSingleQuotes(parentRecordId)+'\' ';

            Map<String, Object> mResult = new Map<String, Object>();
            mResult.put('baseSOQL', baseSOQL);
            mResult.put('whereSOQL', whereSOQL);
            mResult.put('column', listTableColumn);
            mResult.put('parentRecordName', parentRecordSobj.get('Name'));
            mResult.put('metaDataObj', crlc);
            mResult.put('listFilterFields', listFilterFields);
            mResult.put('mapPicklistVal', mapPicklistVal);
            mResult.put('mapParentObjDefinition', mapObjDefinition.containsKey(crlc.Parent_Object__c) ? (Object) mapObjDefinition.get(crlc.Parent_Object__c) : '');
            mResult.put('mapChildObjDefinition', mapObjDefinition.containsKey(crlc.Child_Object__c) ? (Object) mapObjDefinition.get(crlc.Child_Object__c) : '');

            rrs.statusCode = RemoteResponse.STATUSCODE_OK;
            rrs.content = mResult;
            rrs.message = 'successed';
        } catch (Exception e) {
            rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;
            rrs.message = e.getMessage();
            rrs.debug = e.getMessage() + ':' + e.getStackTraceString();
        }
        return rrs;
    }
	
    @AuraEnabled
    public static RemoteResponse deleteRecord(Id recId){
        RemoteResponse rrs = new RemoteResponse();
        try {
            if(String.isNotBlank(recId)){
                Database.delete(recId);
            }
	        rrs.statusCode = RemoteResponse.STATUSCODE_OK;
            rrs.message = 'successed';
        } catch (Exception e) {
            rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;
            rrs.message = e.getMessage();
            rrs.debug = e.getMessage() + ':' + e.getStackTraceString();
        }
        return rrs;
    }
    
    public static String checkIfFromCustomRelatedList_ThenReturnParentId(){
        if(Test.isRunningTest()) return null;
        PageReference pgCurrent = ApexPages.currentPage();
        String urlVal = String.isBlank(pgCurrent.getParameters().get('retURL')) ? '' : String.escapeSingleQuotes(pgCurrent.getParameters().get('retURL'));
        String parentRecId = String.isBlank(pgCurrent.getParameters().get('Id')) ? '' : String.escapeSingleQuotes(pgCurrent.getParameters().get('Id'));
        
        if(String.isNotBlank(urlVal) && urlVal.contains(CustomRelatedListController.PARAMETER_IS_FROM_CUSTOM_RELATEDLIST) && String.isNotBlank(parentRecId)){
            return parentRecId;
        }else{
            return null;
        }
    }

    private static Map<String, EntityDefinition> getObjectDefinition(Set<String> objectAPINames){
        Map<String, EntityDefinition> mEnityDef = new Map<String, EntityDefinition>();
        for(EntityDefinition ed : [SELECT QualifiedApiName, DeveloperName, Label, PluralLabel, MasterLabel FROM EntityDefinition WHERE QualifiedApiName IN: objectAPINames]){
            mEnityDef.put(ed.QualifiedApiName, ed);
        }
        return mEnityDef;
    }

    public class WebLinkWrapper {
        public String name {get;set;}
        public String masterLabel {get;set;}
        public Boolean requireRowSelection {get;set;}
    }

    public class TableColumn {
        @AuraEnabled
        public String label {get; set;}

        @AuraEnabled
        public String developerName {get; set;}

        @AuraEnabled
        public String type {get; set;}

        @AuraEnabled
        public Boolean isCustom {get; set;}

        @AuraEnabled
        public Boolean isNameField {get; set;}
        
    }
}