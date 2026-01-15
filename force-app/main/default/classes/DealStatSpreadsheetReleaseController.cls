/*****************************************************************************************************************************
@ Class:        DealStatSpreadsheetReleaseController
@ Version:      1.0
@ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:      US-0008786 get all Deal_Statement__c records has status = 1st Payout Approved or = 2nd Payout Approved.
@               It is migrated from JOIN instance. the class name is DD_DealStatSpreadsheetReleaseController in the JOIN.
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.01.2021 / Sophal Noch / Created the class.
@               : 21.08.2023 / Sovantheany Dim / US-0012678 - [NA] Mass Send Deal Statements to Sellers
@               : 19.02.2024 / SRONG TIN / US-0014635 - [Tech Debt] Update DealStatSpreadsheetReleaseController checkUserPermission() to use custom permission
*****************************************************************************************************************************/
public without sharing class DealStatSpreadsheetReleaseController {
    
    static Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
    
    final static String ST_STATEMENT_SENT_OUT = 'St_Statement_Sent_out';
    final static String ND_STATEMENT_SENT_OUT = 'Nd_Statement_Sent_Out';
    final static String AD_STATEMENT_SENT_OUT = 'Adj_Statement_Sent_Out';
    final static String DS_NAME = 'Deal_Statement__c';
    final static String DS_STATUS_FNAME = 'Status__c';

    final static String DS_EBAYSELLER_FNAME = 'eBay_Seller__c';
    final static String DS_EBAYSELLER_NAME_FNAME = 'eBay_Seller__r.Name';
    
    static Map<String,String> mapFixLabel = new Map<String,String>{'RecordType.Name'=>'Record Type'};//TH: US-0012678
    static Set<String> sRecordType = new set<String>{'Promotion_Manager_Deals','Subsidised_Deals'};

    final static Set<String> SET_PNAME = new Set<String>{
        'eBay_NA_Deals_Statements_Disputes','US_CA_Standard_user','US_Manage_Deals', 'Deal_Start_End_time_fileds'
    };

    private static final String PERM_DEAL_STATEMENT_RELEASE_PERMISSION = 'Deal_Statement_Release_Permission';//SRONG:19.02.24:US-0014635
    
    final static String ADMIN_PROFILE_ID = '00e6A000000HNzwQAG';

    final static String NA_PROFILE = 'NA Standard User Base';

    final static String ISSUCCESS_TXT = 'isSuccess';
    final static String MSG_TXT = 'message';
    
    public class ColData {
        @AuraEnabled public string value {set; get;}
        @AuraEnabled public string colApiName {set; get;}
        @AuraEnabled public string colType {set; get;}        
        @AuraEnabled public boolean required {set; get;}
        @AuraEnabled public string colDisplayType {set; get;}
        @AuraEnabled public boolean checked {set; get;}
    } 
    
    public class RowData {
        
        @AuraEnabled public ColData[] rowData {set; get;}
        @AuraEnabled public String recordid {set; get;}
        
        
        public RowData(Deal_Statement__c deal, Schema.FieldSetMember[] flst) {
            rowData = new List<ColData>(); 
            for(Schema.FieldSetMember f: flst){
                ColData coldata = new ColData();
                // US-0012043 : @BR:30-06-22
                coldata.value = String.valueOf(ApexUtil.getValue(f.getFieldPath(),deal));
                coldata.colApiName = f.getFieldPath();
                coldata.required = false;
                coldata.checked = false;
                coldata.colType = f.getType() + '';
                
                if (coldata.colApiName == DS_EBAYSELLER_FNAME) {
                    coldata.value = String.valueOf(deal.eBay_Seller__r.Name);
                }
                
                rowData.add(coldata);
            }
        }
    } 
    
    public class ColHearderData {
        @AuraEnabled public string label {set; get;}
        @AuraEnabled public string colApiName {set; get;}
        @AuraEnabled public boolean iconSort {set; get;}
    }
    
    public class RowHeaderData {
        @AuraEnabled public ColHearderData headerData {set; get;}
        public RowHeaderData(String api, String label) { 
            headerData = new ColHearderData();
            headerData.colApiName = api;
            if (headerData.colApiName == DS_EBAYSELLER_FNAME) {
                headerData.colApiName = DS_EBAYSELLER_NAME_FNAME;
            }
            headerData.label = label;
            headerData.iconSort = false;
        }    
    } 
    
    /**
    * constructor
    * @params  String fieldApiName
    * @params  String fieldLabel
    * @params  Schema.DisplayType fieldDataType
    * @params  List<String> fieldValues
    */ 

    
    @AuraEnabled
    public static Map<String, Object> getSearchDealStatement(String status, Integer ofst, Integer lmt, String search, String sortByCol,String colName, Boolean sortAction, List<string > listSentDs){                              
         try {             
            String nameFieldSet = ''; 
            Map<String, Object> mpRes = new Map<String, Object>{ISSUCCESS_TXT => true, MSG_TXT=> 'success'};
            Schema.SObjectType convertType = gd.get(DS_NAME);
            
            Map<String, Schema.FieldSet> fieldSetNameMapToFieldSet = convertType.getDescribe().fieldSets.getMap();  
             if (!String.isEmpty(status)) {
                 switch on status {
                    when '1st Payout Approved' {        // when block 1
                        nameFieldSet = ST_STATEMENT_SENT_OUT;
                    }
                    when '2nd Payout Approved' {        // when block 2
                        nameFieldSet = ND_STATEMENT_SENT_OUT;
                    }
                    when 'Dispute Payout Approved' { //MN-15102021-US-0010374
                        nameFieldSet = AD_STATEMENT_SENT_OUT;
                    }                   
                }
             } 
             
            Schema.FieldSetMember[] flst = fieldSetNameMapToFieldSet.get(nameFieldSet).getFields();
            String query = 'SELECT ';
            String selectTotalRec = 'SELECT ';
            List<Object> labels = new List<Object>();
             
            for(Schema.FieldSetMember f: flst){
                if (f.getFieldPath() != 'Id') {
                    query += f.getFieldPath() + ', ' ;
                    selectTotalRec += f.getFieldPath() + ', ' ;
                    
                    //TH:US-0012678
                    String filedLabel = mapFixLabel.containsKey(f.getFieldPath())? mapFixLabel.get(f.getFieldPath()): f.getLabel();

                    RowHeaderData labelData = new RowHeaderData(f.getFieldPath(), filedLabel);
                    labels.add(labelData);
                }
                    
            }
             String searchName= '%'+search+'%';
             Decimal searchNumber = 0;
            selectTotalRec += DS_EBAYSELLER_NAME_FNAME + ', Id FROM '+DS_NAME+' WHERE '+DS_STATUS_FNAME+' =: status'; 

            String condition = ' WHERE '+DS_STATUS_FNAME+' =: status';
            if(listSentDs != null && !listSentDs.isEmpty()){  //Sophal:11/05/2021:US-0009424
                condition += ' AND Id Not IN: listSentDs';
            }
            if(String.isNotBlank(search)){
                query += DS_EBAYSELLER_NAME_FNAME + ', Id FROM '+DS_NAME + condition + ' AND ';
                if(search.replaceFirst('\\.','').isNumeric()){
                searchNumber = Decimal.valueOf(search);
                query += colName+ ' =:searchNumber';
                }else{
                query += colName+ ' Like:searchName';
                }
                
            }else {
                // query += DS_EBAYSELLER_NAME_FNAME + ', Id FROM '+DS_NAME + condition + ' LIMIT :lmt OFFSET :ofst'; //MN-15102021-US-0010374 - Fixed Incorrect query, LIMIT/OFFSET need to be at the last 
                query += DS_EBAYSELLER_NAME_FNAME + ', Id FROM '+DS_NAME + condition;
            }
            
            if (sortByCol != null) {
                if (Boolean.valueOf(sortAction)){
                    query += ' ORDER BY ' +sortByCol+ ' DESC';
                }else {
                    query += ' ORDER BY ' +sortByCol+ ' ASC';
                }
                
            }

            //MN-15102021-US-0010374 - Fixed Incorrect query, LIMIT/OFFSET need to be at the last 
            query += ' LIMIT :lmt OFFSET :ofst'; 

            List<Deal_Statement__c> dealStaLst = Database.query(query); 
            RowData[] rowLst = new List<RowData>();
            for (Deal_Statement__c dealSta : dealStaLst) {
                
    
                RowData rd = new RowData(dealSta,flst);
                rd.recordid = dealSta.Id;
                rowLst.add(rd);
            }
             
            // List<Deal_Statement__c> dealStaLstAll = Database.query(selectTotalRec);
            // Integer allDsSize = dealStaLstAll.size();

            String dsSoqlCount = 'Select Count() FROM '+DS_NAME+' WHERE '+DS_STATUS_FNAME+' =: status';
            Integer allDsSize = Database.countQuery(dsSoqlCount);

            mpRes.put('total', allDsSize);
            mpRes.put('label', labels);
            mpRes.put('dealList', rowLst);
            
            return mpRes;
        } catch(Exception ex) {
            System.debug(LoggingLevel.Error, 'ERROR ' + ex);
            AuraHandledException auraError = new AuraHandledException(ex.getMessage() + ex.getStackTraceString());
            auraError.setMessage(ex.getMessage() + ex.getStackTraceString());
            throw auraError;
        }
    }  
    
    /**
    * constructor
    * @params  String fieldApiName
    * @params  String fieldLabel
    * @params  Schema.DisplayType fieldDataType
    * @params  List<String> fieldValues
    */ 
   
    
    @AuraEnabled
    public static Map<String, Object> getDealStatement(String status, Integer ofst, Integer lmt, List<string > listSentDs, String defRecordType){                            
         try {             
            String nameFieldSet = ''; 
            Map<String, Object> mpRes = new Map<String, Object>{ISSUCCESS_TXT => true, MSG_TXT => 'success'};
            Schema.SObjectType convertType = gd.get(DS_NAME);
             
            Map<String, Schema.FieldSet> fieldSetNameMapToFieldSet = convertType.getDescribe().fieldSets.getMap();  
             if (!String.isEmpty(status)) {
                 switch on status {
                    when '1st Payout Approved' {        // when block 1
                        nameFieldSet = ST_STATEMENT_SENT_OUT;
                    }
                    when '2nd Payout Approved' {        // when block 2
                        nameFieldSet = ND_STATEMENT_SENT_OUT;
                    }
                    when 'Dispute Payout Approved' { //MN-15102021-US-0010374
                        nameFieldSet = AD_STATEMENT_SENT_OUT; 
                    }                 
                }
             } 
             
            Schema.FieldSetMember[] flst = fieldSetNameMapToFieldSet.get(nameFieldSet).getFields();
            String query = 'SELECT ';
            String selectTotalRec = 'SELECT ';
             
            List<Object> labels = new List<Object>();
             
            for(Schema.FieldSetMember f: flst){
                if (f.getFieldPath() != 'Id') {
                    query += f.getFieldPath() + ', ' ;
                    selectTotalRec += f.getFieldPath() + ', ' ;
                    //TH:US-0012678
                    String filedLabel = mapFixLabel.containsKey(f.getFieldPath())? mapFixLabel.get(f.getFieldPath()): f.getLabel();

                    RowHeaderData labelData = new RowHeaderData(f.getFieldPath(), filedLabel);
                    labels.add(labelData);
                }
                    
            }
             
            selectTotalRec += DS_EBAYSELLER_NAME_FNAME + ', Id FROM '+DS_NAME+' WHERE '+DS_STATUS_FNAME+' =: status';

            String condition = ' WHERE '+DS_STATUS_FNAME+' =: status';
            if(listSentDs != null && !listSentDs.isEmpty()){  //Sophal:11/05/2021:US-0009424
                condition += ' AND Id Not IN: listSentDs';
            }
            //TH:US-0012678:23/08/2023
            if(String.isNotBlank(defRecordType)){
                condition += ' AND RecordType.DeveloperName =: defRecordType';
            }

            query += DS_EBAYSELLER_NAME_FNAME + ', Id FROM ' + DS_NAME + condition + ' LIMIT :lmt OFFSET :ofst';
             
            List<Deal_Statement__c> dealStaLst = Database.query(query); 
            RowData[] rowLst = new List<RowData>();
            for (Deal_Statement__c dealSta : dealStaLst) {
                
                
                RowData rd = new RowData(dealSta,flst);
                rd.recordid = dealSta.Id;
                rowLst.add(rd);
            }
             
            // List<Deal_Statement__c> dealStaLstAll = Database.query(selectTotalRec);
            // Integer allDsSize = dealStaLstAll.size();

            String dsSoqlCount = 'Select Count() FROM '+DS_NAME+' WHERE '+DS_STATUS_FNAME+' =: status';
            Integer allDsSize = Database.countQuery(dsSoqlCount);
             
            mpRes.put('total', allDsSize);
            mpRes.put('label', labels);
            mpRes.put('dealList', rowLst);
            
            return mpRes;
        } catch(Exception ex) {
            throw new AuraHandledException(ex + ' : ' + ex.getStackTraceString());
        }
    }  
    
    
    @AuraEnabled
    public static Map<String, Object> sendExcel(List<string > listId){
        try {

            Map<String, Object> mpRes = checkUserPermission();

            if(Boolean.valueOf(mpRes.get(ISSUCCESS_TXT))){
                Database.executeBatch(new DD_DealStatementSpreadsheetBatch( listId),1);
            }

            return mpRes;
            
        } catch(Exception ex) {
            throw new AuraHandledException(ex + ' : ' + ex.getStackTraceString());
        }
        
    }

    @AuraEnabled
    public static Map<String, Object> checkUserPermission(){

        Map<String, Object> mpRes = new Map<String, Object>{ISSUCCESS_TXT => false, MSG_TXT => Label.Error_No_Permission_Send_DealStatements_To_Sellers};

        Id userProifleId = Userinfo.getprofileId();
        Id userId = UserInfo.getUserId();

        Boolean isAdmin =  userProifleId == ADMIN_PROFILE_ID ? true : false;
      
        List<PermissionSetAssignment> listPSA = new List<PermissionSetAssignment>();
        
        if(Test.isRunningTest() || !isAdmin){
            listPSA = [
                Select Id FROM PermissionSetAssignment 
                Where PermissionSet.Name IN :SET_PNAME 
                AND AssigneeId IN (SELECT Id FROM User WHERE Id =:userId AND Profile.Name =: NA_PROFILE)
            ];
        }
        //SRONG:19.02.24:US-0014635
        Boolean hasDealReleasePerm = FeatureManagement.checkPermission(PERM_DEAL_STATEMENT_RELEASE_PERMISSION);
        if(Test.isRunningTest() || isAdmin || hasDealReleasePerm || listPSA.size() == SET_PNAME.size()){
            mpRes.put(ISSUCCESS_TXT,true); mpRes.put(MSG_TXT,'success');
        }

        return mpRes;

    }

    /*****************************************************************************************************************************
    @ Class:        fetchRecordType
    @ Version:      1.0
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0012678 - [NA] Mass Send Deal Statements to Sellers
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.08.2023 / Sovantheany Dim / Created the class.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> fetchRecordType(){
        Map<String,Object> mapResult = new Map<String,Object>();
		try
	 	{
            List<Map<String,String>> recordtypemap = new List<Map<String,String>>(); 
            for(RecordType rt : [SELECT Id,Name,DeveloperName FROM RecordType WHERE SobjectType='Deal_Statement__c' and DeveloperName IN: sRecordType]){
                recordtypemap.add(new Map<String,String>{'label'=>rt.Name,'value'=>rt.DeveloperName});   
            }        
			mapResult.put('status','ok');
			mapResult.put('lstRecordType',recordtypemap);
	 	}catch(Exception ex){
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
        }
        return mapResult;
    }

}