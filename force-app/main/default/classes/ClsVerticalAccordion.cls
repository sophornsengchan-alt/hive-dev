/*********************************************************************************************************************************
@ Class:          ClsVerticalAccordion
@ Version:        1.0
@ Author:         Sochettra Saing
@ Purpose:        Ability to display Deal List View(EBAY-226)
@ ClsVerticalAccordion for LWC lwcListView
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.07.2021 / Sochettra Saing / Created the class.
@                 10.06.2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
*********************************************************************************************************************************/
public with sharing class ClsVerticalAccordion {
    
    @AuraEnabled
    public static Map<String, Object> getSettings(String mdtName){
        Map<String, Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{
            String message = '';
            Seller_Portal_Setting__mdt spsMdt = readMtdObject(mdtName);
            if(checkIsInValid(spsMdt)){
                mResult.put('message', 'Missing FiledSet or Object Name!');
            } else {
                Map<String, Object> mHighlightFields = readFieldSet(spsMdt.Field_Set_Name__c, spsMdt.Object_API_Name__c);
                //System.debug('mHighlightFields: '+mHighlightFields);
                //Map<String, Object> mDetailFields = readFieldSet(spsMdt.Field_Set_Detail_Name__c, spsMdt.Object_API_Name__c);
                
                Set<String> allFieldsAPI = new Set<String>();
                allFieldsAPI.addAll((Set<String>) mHighlightFields.get('allFields'));
                //allFieldsAPI.addAll((Set<String>) mDetailFields.get('allFields'));
                //String query = buildQuery(spsMdt, allFieldsAPI);
                //System.debug('query: '+query);
                User u = [SELECT Id, Profile.Name FROM User WHERE Id =: UserInfo.getUserID()];
                mResult.put('userProfile', u.Profile.Name);
                mResult.put('sepDomain', SEP_Helper.sepUser.domain); //MN-10062024-US-0015298
                mResult.put('highlightFields', mHighlightFields.get('allFieldsObj'));
                //mResult.put('detailFields', mDetailFields.get('allFieldsObj'));
                mResult.put('numberOfRecordsPerPage', spsMdt.Number_Of_Records_To_Display__c);
                //mResult.put('soql', query);
                //mResult.put('listRecord', Database.query(query));
                mResult.put('message', 'load setting successfully!');
                mResult.put('status', 'success');
            }
            
        } catch( Exception ex){
            mResult.put('message', 'Error:'+ex.getLineNumber()+ ex.getMessage());
        }
        
        return mResult;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getExistingRecords(String searchKey, String sortedBy, String sortedDirection, String settingName){
        Map<String,Object> mResult = new Map<String,Object>();
        mResult.put('status','error');
        try{
            Seller_Portal_Setting__mdt spsMdt = readMtdObject(settingName);
            String query = buildQuery(spsMdt, searchKey);

            String key = ''; 
            if(String.isNotBlank(searchKey)){
                key = '%' + searchKey + '%';
            }
            
            //query += (String.isNotBlank(sortedBy)? ' ORDER BY '+sortedBy +(String.isNotBlank(sortedDirection)? ' ' +sortedDirection +' ': ' asc ') :'');
            if(String.isNotBlank(sortedBy)){
                query += ' ORDER BY '+sortedBy +(String.isNotBlank(sortedDirection)? ' ' +sortedDirection +' ': ' asc ');
            } else if(String.isNotBlank(spsMdt.Order_Fields__c)) {
                query += ' ORDER BY ' + spsMdt.Order_Fields__c;
            }

            mResult.put('query', query);
            List<SObject> drcs = Database.query(query);
            List<Id> junctionIds = new List<Id>();
            for(SObject drcObj:drcs){
                EBH_DealRetailCampaign__c drc = (EBH_DealRetailCampaign__c) drcObj;
                for(NA_Deal_Window_Retail_Campaign_Junction__c junction:drc.Deal_Window_Items__r){
                    junctionIds.add(junction.Id);
                }
            }
            System.debug('QQ: '+[SELECT Id, Deal_Retail_Campaign__c, Deal_Retail_Campaign__r.EBH_DealTitle__c, Deal_Retail_Campaign__r.EBH_Date__c, Deal_Retail_Campaign__r.EPH_EndDate__c FROM NA_Deal_Window_Retail_Campaign_Junction__c WHERE Id IN :junctionIds]);

            mResult.put('listRecord', drcs);
            mResult.put('status','success');
        } catch( Exception ex){
            mResult.put('message', 'Error:'+ex.getLineNumber()+ ex.getMessage());
        }
        System.debug('data: '+mResult);
        return mResult;
    }

    private static void getDealRetailCampaigns(){

    }

    private static Boolean checkIsInValid(Seller_Portal_Setting__mdt spsMdt) {
        Boolean isInValid = false;
        if(String.isBlank(spsMdt.Field_Set_Name__c) || String.isBlank(spsMdt.Object_API_Name__c)) isInValid = true;
        return isInValid;
    }

    private static String buildQuery(Seller_Portal_Setting__mdt spsMdt, String searchKey) {
        String query = ''; 

        if(checkIsInValid(spsMdt)){
            return 'Missing FiledSet or Object Name!';
        } else {
            Map<String, Object> mHighlightFields = readFieldSet(spsMdt.Field_Set_Name__c, spsMdt.Object_API_Name__c);
            Set<String> allFieldsAPI = new Set<String>();
            allFieldsAPI.addAll((Set<String>) mHighlightFields.get('allFields'));
            allFieldsAPI.add('EBH_Country__c');

            String selectedField = String.join(new List<String>(allFieldsAPI), ', ');
            selectedField = selectedField+', (SELECT Id, EBH_DealTitle__c, Status_Seller_Portal__c, EBH_Date__c, EPH_EndDate__c FROM Deal_Retail_Campaigns__r WHERE RecordType.Name = \'Deal Window Campaign\') ';
            User u = new User();
            for(User us: [SELECT Id, Country, TimeZoneSidKey, UserType, ContactId, AccountId FROM User WHERE Id =: UserInfo.getUserID() limit 1]){
                u = us;
            }

            String filters = (String.isNotBlank(spsMdt.Filter_Values__c) ? spsMdt.Filter_Values__c : '');

            filters = (filters.containsIgnoreCase('{$User.Id}') ?filters.replace('{$User.Id}', '\''+u.Id +'\'') : filters);
            filters = (filters.containsIgnoreCase('{$User.Country}') ?filters.replace('{$User.Country}', '\''+u.Country +'\'') : filters);
            //                                                        filters + ' AND OwnerId='+'\''+userId +'\'');
            if(String.isNotBlank(searchKey)){
                filters += (String.isNotBlank(spsMdt.Specific_Search_Field__c)? ( String.isNotBlank(filters) ? ' AND ( '+spsMdt.Specific_Search_Field__c  + ' ) ': spsMdt.Specific_Search_Field__c) : filters);
            }
            String junctionQuery = ', (SELECT Id,NA_Retail_Campaign_Description__c,NA_Retail_Campaign_Start_Date__c, NA_Retail_Campaign_End_Date__c, NA_Retail_Campaign_Title__c, Deal_Retail_Campaign__c FROM Deal_Window_Items__r WHERE NA_Retail_Campaign_Start_Date__c != NULL AND NA_Retail_Campaign_End_Date__c != NULL AND NA_Retail_Campaign_Title__c != NULL)';
            query = 'SELECT '+selectedField+junctionQuery+' FROM '+spsMdt.Object_API_Name__c+(String.isNotBlank(filters)? ' WHERE '+filters : '');
        }
        System.debug('query: '+query);
        return query;
    }

    private static Map<String, Object> readFieldSet(String fieldSetName, String ObjectName) {
        Map<String, Object> mFieldSet = new Map<String,Object>();

        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

        //system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName));

        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

        //List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        //system.debug('fieldSetMemberList ====>' + fieldSetMemberList); 
        List<Map<String,String>> allFieldsObj = new List<Map<String,String>>();
        Set<String> allFields = new Set<String>();
        for(Schema.FieldSetMember fsm : fieldSetObj.getFields()) {
            //system.debug('API Name ====>' + fieldSetMemberObj.getFieldPath()); //api name
            //system.debug('Label ====>' + fieldSetMemberObj.getLabel());
            //system.debug('Required ====>' + fieldSetMemberObj.getRequired());
            //system.debug('DbRequired ====>' + fieldSetMemberObj.getDbRequired());
            //system.debug('Type ====>' + fieldSetMemberObj.getType());   //type - STRING,PICKLIST
            //lstFields.add(fieldSetMemberObj.getFieldPath());
            Map<String,String> mObj = new Map<String,String>();
            mObj.put('fieldName',fsm.getFieldPath());
            mObj.put('label',fsm.getLabel());
            mObj.put('type',String.valueOf(fsm.getType()));
            allFieldsObj.add(mObj);

            allFields.add(fsm.getFieldPath());
            
        }
        mFieldSet.put('allFields', allFields);
        mFieldSet.put('allFieldsObj', allFieldsObj);

        return mFieldSet; 
    }  

    private static Seller_Portal_Setting__mdt readMtdObject(String mdtName) {
        Seller_Portal_Setting__mdt spsMdt = new Seller_Portal_Setting__mdt();
        for(Seller_Portal_Setting__mdt mdt : [SELECT DeveloperName, Field_Set_Name__c, Field_Set_Detail_Name__c, Object_API_Name__c, Filter_Values__c, Number_Of_Records_To_Display__c, Order_Fields__c, Maximum_Records__c, Specific_Search_Field__c FROM Seller_Portal_Setting__mdt WHERE DeveloperName =: mdtName]){
            spsMdt = mdt;
        }

        return spsMdt;
    }
}