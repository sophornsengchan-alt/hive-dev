/*********************************************************************************************************************************
@ Class:          MassUploadObjectController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Controller Class for MassUploadObject.page and MassUploadObject.cmp
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  14.09.2020 / Sophal Noch / Created the class.
					30/09/2020 / Sovantheany Dim / Update the class for US-0008088
                    30/12/2020 / sovantheany dim / get only seller approval related to seller US-0008904
                    05/02/2021 / Mony Nou / US-0009001
                    05/02/2021 / Sovantheany Dim / US-0008668 [US] Bulk Upload field mapping CSV verification
                    24/11/2021 / Sophal Noch / US-0010754 - [NA Deals] When Deals are created via Bulk Upload, use recordtype to identify correct Account
                    08/02/2022 / Sovantheany Dim / US-0011027 - Ability for System to default to the DWH Contact when internally Bulk Uploading
                    05/05/2022 / Loumang SENG / US-0011260 - TECHDEBT: Reflected XSS
                    09/01/2023 / Bora Chhorn / US-0013053 - Deal Price should be stamped on Seller Price for Un-Sub Deals
                    06/02/2023 / Sophal Noch / US-0013168 - Deal V2 bulk upload of Deals, contact columns should look up for only Manual and DWH contact
                    06/06/2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c 
*********************************************************************************************************************************/
public without sharing class MassUploadObjectController {

   
    // variable for vf page MassUploadObject.page
    public Boolean isInvalidSetting{ set; get;}
    public String settingName { set; get;}
    public String lkf { set; get;}
    public String defVal { set; get;}
    public Boolean sendResult { set; get;}
    public Boolean isLightningReady{ set; get;}
    public String fieldsiteColIndex { set; get;}
    public String colVerticalIndex { set; get;}
    public String colCategoryIndex { set; get;}
    
    // variable for lightning component MassUploadObject.cmp
    private final static String PERMISSION_BULK_UPLOAD_LEADS = 'Bulk_Upload_Leads';
    private final static String PERMISSION_BULK_UPLOAD_DEAL_US = 'US_Manage_Deals';
    // SRONG TIN 13-July-2021, US-0009650
    private final static String PERMISSION_BULK_UPLOAD_NA_UNSUB_DEAL_US = 'eBay_NA_Manage_Unsub_Deals';
    private final static String PERMISSION_BULK_UPLOAD_DEAL_DATE_TIME = 'Deal_Start_End_time_fileds';
    private final static String DEAL_SOBJECT = 'EBH_Deal__c';
    private final static String LEAD_SOBJECT = 'Lead'; //MN-05022021
    
    private final static String DATA_TYPE_STRING ='string',DATA_TYPE_DECIMAL = 'decimal',DATA_TYPE_NUMBER='number',DATA_TYPE_DATE = 'date',DATA_TYPE_TIME='time',
    DATA_TYPE_PICKLIST='pickist',DATA_TYPE_URL='url',DATA_TYPE_REF='reference',DATA_TYPE_EMAIL='email';

    private final static String SEMI_COLON_SIGN = ';';

    private final static String ROW_ERROR_MSG_TEMPLATE = '- Row number : {!rowNum}. Error: {!err}.';

    private final static String  LEAD_DOC_NAME = 'MASS_UPLOAD_LEAD_CSV';
    private final static String  DEAL_DOC_NAME = 'MASS_UPLOAD_DEAL_CSV';
    // SRONG TIN 09-July-2021, US-0009650
    private final static String  NA_UNSUB_DEAL_INTERNAL_DOC_NAME = 'MASS_UPLOAD_DEAL_V4_INTERNAL_CSV';
    private final static String  NA_UNSUB_DEAL_SELLER_DOC_NAME = 'MASS_UPLOAD_DEAL_V3_SELLER_CSV';
    //private final static String  TICKET_NA_SELLER_PORTAL_PROFILE  = 'NA - Seller Portal';  //MN-06062024-US-0015298:No longer use Profile Name
    // SRONG TIN 21-July-2021, US-0009650
    private final static String  NA_Unsub_Deal_Internal  = 'NA_Unsub_Deal_Internal'; 
    private final static String  NA_Unsub_Deal_Seller  = 'NA_Unsub_Deal_Seller'; 
    // SRONG TIN 13-July-2021 added PERMISSION_BULK_UPLOAD_NA_UNSUB_DEAL_US
    private static Set<String> sPermissionDeal = new Set<String>{PERMISSION_BULK_UPLOAD_DEAL_US,PERMISSION_BULK_UPLOAD_DEAL_DATE_TIME,PERMISSION_BULK_UPLOAD_NA_UNSUB_DEAL_US};
    private static Set<String> sPermissionLead = new Set<String>{PERMISSION_BULK_UPLOAD_LEADS};
    
    private final static String  RECORD_TYPE_ID_FIELD = 'recordtypeid';

    //private final static Integer  RECORD_LIMIT_PER_TRANS = 1000; // cpu limit happened
    // private final static Integer  RECORD_LIMIT_PER_TRANS = 500;
    //private final static Integer  RECORD_LIMIT_PER_TRANS = 200;// cpu limit happened
    private final static Integer  RECORD_LIMIT_PER_TRANS = 50;
    public final static Integer  RECORD_LIMIT_FOR_PReVIEW = 5;

    private static Map<Integer, String> mapIndexCsvColName = new Map<Integer, String>();
    private static Map<String, MappedField> mapCsvColNameToSfField= new Map<String, MappedField>();
    private static Map<String,String> mapFormatSep = new Map<String,String> {
        'MM/dd/yyyy' => '/',
        'dd/MM/yyyy' => '/',
        'yyyy/MM/dd' => '/',
        'yyyy-MM-dd' => '-',
        'dd.MM.yyyy' => '[\\.]'
    };
    private static Map<String,Integer[]> mapFormatIndex = new Map<String,Integer[]> {
        'MM/dd/yyyy' => new Integer[]{2,0,1},	//12/17/2020
        'dd/MM/yyyy' => new Integer[]{2,1,0}, //17/12/2020
        'yyyy/MM/dd' => new Integer[]{0,1,2}, //2020/12/17
        'yyyy-MM-dd' => new Integer[]{0,1,2}, //2020-12-17
        'dd.MM.yyyy' => new Integer[]{2,1,0} //17.12.2020
    };
    
    private static Map<String,String> MAP_SITE_CODE = new Map<String,String>
    {
        'IT'=>'101',
         'ES'=>'186',
         'UK'=>'3',
         'FR'=>'71',
         'DE'=>'77',
         'AU' => '15',
         'US' => '0',
         'CA' => '2'
    };

    /*****************************************************************************************************************************
    @ Method:       MassUploadObjectController
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008027 
    @               As a...
    @               any User with a specific permission set
    @               Want to...
    @               be able to bulk upload a list of leads to Hive via CSV / Excel Spreadsheet
    @               So that...
    @               multiple lead records can be created and distributed to teams
    @               Description
    @               Summary: New Permission Set ('Bulk Upload Leads'), New Button, Bulk Upload to create new records
    @               AC 1:
    @               Given that I am any user with the 'Bulk Upload Leads' permission set
    @               When I go to the Lead object (Lead) and Select any Leads List View,
    @               From the drop-down box, I can see a new button called 'Upload Leads' (similar to deals)
    @               image.png
    @               TC 1: 
    @               The button should enable creation of duplicate leads
    @               AC 2:
    @               As any User with the 'Bulk Upload Leads' permission set
    @               When I go to the Leads> Lead List View> and Click the button 'Upload Leads' and am able to upload a CSV file.
    @               I see a similar screen with the title 'Bulk Upload Leads (instead of Bulk Upload Nominated Item displayed below)
    @               The message near Upload button should read "Bulk Upload Leads" (instead of Bulk Upload Nominated Item)
    @               The Attention message should read "Use this .csv template to upload and create Lead records" and include a link to the following file.
    @               image.png
    @               TC 2:
    @               The upload must be able to accept .csv in both comma separated and semi-colon separated formats. If the file is not of these formats the upload process should fail and no records should be created. 
    @               AC 3:
    @               All leads by default should have a Lead Status (Status) as "New lead"
    @               The owner of the newly created leads 'Lead Owner" (OwnerId) should be the user who uploaded /created the lead. 
    @               AC 4:
    @               As any other user without the Permission set "Bulk Upload Leads" tries to click on the "Bulk Upload Leads" button,
    @               the user should see a pop-up error message that should read "You do not have the permission to bulk upload leads. Please contact Admin" on the center of the page.
    @               AC 5:
    @               As a US Standard User with the 'Bulk Upload Leads' permission set,
    @               When I go to the Leads> Lead List View> and Click the button 'Upload Leads' and am able to upload a CSV file.
    @               Uploaded CSV file automatically will create new records of the record type "New Seller Registration Process" (file attached)
    @               Additional details:
    @               Typical amount of lead records uploaded can be from ~ 30 to ~750 in one upload/insert
    @ Event:		after MassUploadObject.page init
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.09.2020 / Sophal Noch / Created the method.
    @               : 05.05.2022 / Loumang SENG /US-0011260 - TECHDEBT: Reflected XSS
    @*****************************************************************************************************************************/
    public MassUploadObjectController() {
        // settingName = System.currentPageReference().getParameters().get('setting');
        // lkf = System.currentPageReference().getParameters().get('lkf');
        // defVal = System.currentPageReference().getParameters().get('defVal');
        // String sendResultStr = System.currentPageReference().getParameters().get('sendResult');
        // sendResult = (String.isNotBlank(sendResultStr)) ? Boolean.valueOf(sendResultStr) : false;
        // fieldsiteColIndex = System.currentPageReference().getParameters().get('fieldsiteColIndex');
        // colVerticalIndex = System.currentPageReference().getParameters().get('colVerticalIndex');
        // colCategoryIndex = System.currentPageReference().getParameters().get('colCategoryIndex');
        // if(String.isBlank(settingName) || String.escapeSingleQuotes(settingName) == null || String.escapeSingleQuotes(settingName) != settingName){isInvalidSetting = true;}
        // else{isLightningReady = true; settingName = String.escapeSingleQuotes(settingName);}
        
        //LA-04-05-2022:US-0011260
        settingName = String.escapeSingleQuotes(String.isBlank(System.currentPageReference().getParameters().get('setting')) ? '': System.currentPageReference().getParameters().get('setting'));
        lkf = String.escapeSingleQuotes(String.isBlank(System.currentPageReference().getParameters().get('lkf')) ? '': System.currentPageReference().getParameters().get('lkf'));
        defVal = String.escapeSingleQuotes(String.isBlank(System.currentPageReference().getParameters().get('defVal')) ? '': System.currentPageReference().getParameters().get('defVal'));
        String sendResultStr = String.escapeSingleQuotes(String.isBlank(System.currentPageReference().getParameters().get('sendResult')) ? '': System.currentPageReference().getParameters().get('sendResult'));
        sendResult = (String.isNotBlank(sendResultStr)) ? Boolean.valueOf(sendResultStr) : false;
        fieldsiteColIndex = String.escapeSingleQuotes(String.isBlank(System.currentPageReference().getParameters().get('fieldsiteColIndex')) ? '': System.currentPageReference().getParameters().get('fieldsiteColIndex'));
        colVerticalIndex = String.escapeSingleQuotes(String.isBlank(System.currentPageReference().getParameters().get('colVerticalIndex')) ? '': System.currentPageReference().getParameters().get('colVerticalIndex'));
        colCategoryIndex = String.escapeSingleQuotes(String.isBlank(System.currentPageReference().getParameters().get('colCategoryIndex')) ? '': System.currentPageReference().getParameters().get('colCategoryIndex'));
        if(String.isBlank(settingName)){isInvalidSetting = true;}
        else{isLightningReady = true;}
    
    }


    /*****************************************************************************************************************************
    @ Method:       MassUploadObjectController
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008027 
    @ Event:		after MassUploadObjectController.cmp init
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	Mass_Upload_Setting__mdt api name
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.09.2020 / Sophal Noch / Created the method.
    @ Change history: 21.07.2021 / SRONG TIN / added parameter: drcId US-0009650 
    @*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexInit(String settingName,Id drcId) {

        // SRONG TIN 21-July-2021 : check profile is Seller Portal US-0009650
        User currentUser = [Select Id,PRofile.Name,ContactId, Contact.AccountId From User Where Id =:UserInfo.getUserId()];

        //Boolean isSellerPortalProfile = currentUser.PRofile.Name == TICKET_NA_SELLER_PORTAL_PROFILE; //MN-06062024-US-0015298:No longer use with Profile Name
        Boolean isSellerPortalProfile = SEP_Helper.sepUser.isNA(); //MN-06062024-US-0015298:Use SP Main Domain instead of Profile Name

        if(String.isNotBlank(drcId) && !isSellerPortalProfile){
            settingName = NA_Unsub_Deal_Internal;
        }else if(String.isNotBlank(drcId) && isSellerPortalProfile){
            settingName = NA_Unsub_Deal_Seller;
        }
        // System.debug('nsp settingName '+settingName);
        String recordTypeId;
        Map<String,Object> mapResult = new Map<String,Object>();
        try
    	{

            
            List<Mass_Upload_Setting__mdt> listMassUploadSetting = [
                SELECT DeveloperName, Object_Name__c,RecordTypeID__c,RecordTypeApiName__c,CSV_Column_Names__c,CSV_Column_Types__c,Field_API_Names__c,Description__c,Required_Field_API_Names__c 
                From Mass_Upload_Setting__mdt where DeveloperName =: settingName LIMIT 1
            ];
            if(listMassUploadSetting.isEmpty()){ mapResult.put('status','ko'); mapResult.put('error',System.Label.ErrorMassUploadSettingNotFound); return mapResult; }

            if(String.isBlank(listMassUploadSetting[0].Object_Name__c)){ mapResult.put('status','ko'); mapResult.put('error',System.Label.ErrorSobjectInMassUploadSettingNotFound); return mapResult; }

            //check permission set
            //TH:30/09/2020 : US-0008088 : add check condition for EBH_Deal__c object
            Set<String> sPermissionset = new Set<String>();
            if(listMassUploadSetting[0].Object_Name__c == DEAL_SOBJECT){
            	sPermissionset.addAll(sPermissionDeal);
            	//TH: get field value dependency : 27/04/2021 : US-0009439 - [NA] NA Deals Bulk Upload Validation Rules for Vertical and Category
            	Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDepVertical  = ApexUtil.getDependentMap(EBH_Deal__c.getSObjectType(),'EBH_DealSiteId__c','EBH_Vertical__c');
            	Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDepCategory  = ApexUtil.getDependentMap(EBH_Deal__c.getSObjectType(),'EBH_DealSiteId__c','EBH_Category__c');
            	mapResult.put('pklDepVertical',pklDepVertical);
            	mapResult.put('pklDepCategory',pklDepCategory);
            	//End US-0009439
            }else{
            	sPermissionset.addAll(sPermissionLead);
            }
            Boolean hasBulkUploadPermission = ApexUtil.checkPermissionSet(sPermissionset);
            Boolean isAdmin = Userinfo.getprofileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID;
    
            if(!hasBulkUploadPermission && !isAdmin){ mapResult.put('status','ko'); mapResult.put('error',listMassUploadSetting[0].Object_Name__c == DEAL_SOBJECT ? System.Label.ErrorBulkUploadDeals : System.Label.ErrorBulkUploadLeads); return mapResult;}
            
            SObjectType sObjectType = Schema.getGlobalDescribe().get(listMassUploadSetting[0].Object_Name__c);
            if(sObjectType == null){ mapResult.put('status','ko'); mapResult.put('error',System.Label.ErrorSobjectInMassUploadSettingNotFound); return mapResult; }

            if(compareMassUploadSettingFields( listMassUploadSetting[0].CSV_Column_Names__c , null )){ mapResult.put('status','ko'); mapResult.put('error',System.Label.ErrorCsvColumnNamesInvalid); return mapResult;}

            if(compareMassUploadSettingFields( listMassUploadSetting[0].CSV_Column_Names__c , listMassUploadSetting[0].CSV_Column_Types__c )){ mapResult.put('status','ko'); mapResult.put('error',System.Label.ErrorCsvColumnTypesInvalid); return mapResult;}

            if(compareMassUploadSettingFields( listMassUploadSetting[0].CSV_Column_Names__c , listMassUploadSetting[0].Field_API_Names__c )){ mapResult.put('status','ko'); mapResult.put('error',System.Label.ErrorFieldAPINamesInvalid); return mapResult;}

            if(!String.isBlank(listMassUploadSetting[0].RecordTypeID__c)) {
                recordTypeId = listMassUploadSetting[0].RecordTypeID__c;
            }
            if(String.isBlank(listMassUploadSetting[0].RecordTypeID__c) && !String.isBlank(listMassUploadSetting[0].RecordTypeApiName__c)) {
                recordTypeId = ApexUtil.getRecordTypeByName(listMassUploadSetting[0].Object_Name__c , listMassUploadSetting[0].RecordTypeApiName__c).Id;
            }
            
            CustomUploadSetting massUploadObject =  new CustomUploadSetting();
            massUploadObject.sobjectName = sObjectType.getDescribe().getLabel();
            massUploadObject.sobjectApiName = sObjectType.getDescribe().getName();
            massUploadObject.recordTypeId = recordTypeId;
            massUploadObject.csvColumnNames = listMassUploadSetting[0].CSV_Column_Names__c;
            massUploadObject.csvColumnTypes = listMassUploadSetting[0].CSV_Column_Types__c;
            massUploadObject.fieldApiName = listMassUploadSetting[0].Field_API_Names__c;
            massUploadObject.reqFieldApiName = listMassUploadSetting[0].Required_Field_API_Names__c; //MN-05022021-US-0009001
            massUploadObject.description = listMassUploadSetting[0].Description__c;
            massUploadObject.standardDateFormats = getStandardDateFormatsIndex();
            List<String> listCsvSettingColumnNames = massUploadObject.csvColumnNames.split(SEMI_COLON_SIGN);
             //TH: US-0008668 - getCSVColumnName : 05/02/2021
            List<String> listCsvColumnNames = new List<String>();
            listCsvColumnNames.addAll(listCsvSettingColumnNames);
            listCsvColumnNames.add('Status');
            List<String> listFieldApiName = massUploadObject.fieldApiName.split(SEMI_COLON_SIGN);
            //End TH: US-0008668
            
            mapResult.put('status','ok');
            mapResult.put('massUploadObject',massUploadObject);
            mapResult.put('columns',listCsvColumnNames);
            mapResult.put('csvSettingcolumns',listCsvSettingColumnNames);
            mapResult.put('FieldAPINames',listFieldApiName);

        }catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
        catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}



         return mapResult;
    }

    private static Boolean compareMassUploadSettingFields(String field1,String field2){

        Boolean isError = false;

        if(field2 == null){ 
            isError = String.isBlank(field1) ? true : false;
        }else{
            isError = (String.isBlank(field1) || String.isBlank(field2)) ? true : false;
            if(!isError){
                isError = field1.split(SEMI_COLON_SIGN).size() != field2.split(SEMI_COLON_SIGN).size() ? true : false;
            }
        } 

        return isError;

    }
    
    /*****************************************************************************************************************************
    @ Method:       chunkRecords
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008027
    @               chunk row in csv to small
    @ Event:		when user upload csv in MassUploadObject.page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	csvString : csv content, 
    @               numFormat : format number such as en or de. dot or comma,
    @               seperator : seprate to split each columns of row to get value,
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.09.2020 / Sophal Noch / Created the method.
    @                   17.03.2022 / Sovantheany Dim / move to MassUploadObjectHelper.js : US-0011389 - Bulk Upload 1500 NA Deals record upload failed
    @*****************************************************************************************************************************/    
    /*@AuraEnabled
    public static Map<String,Object> chunkRecords(String csvString, String numFormat, String seperator, Boolean isPreview){
        Map<String,Object> mapResult = new Map<String,Object>();
        try
    	{
    		
            String contentfile = csvString.replace('\n','');
            OpenCSVParser parser = new OpenCSVParser(seperator,OpenCSVParser.DEFAULT_QUOTE_CHARACTER, OpenCSVParser.DEFAULT_ESCAPE_CHARACTER,OpenCSVParser.DEFAULT_STRICT_QUOTES, OpenCSVParser.DEFAULT_IGNORE_LEADING_WHITESPACE);
            OpenCSVReader reader = new OpenCSVReader(parser,contentfile,'\r',false);//unix user only \r
            List<List<String>>lstDataRow = reader.readAll();

            List<String> rowColumns = lstDataRow[0];
            lstDataRow.remove(0);
            
            List<List<List<String>>> listAllChunk = new List<List<List<String>>>();
            
            
            //TH: US-0008668 : 05/02/2021
            if(isPreview){
            	
            	List<List<String>> lstDataRowForPreview = new List<List<String>>();
            	Integer counter = 0;
            	while(counter<RECORD_LIMIT_FOR_PReVIEW && counter<lstDataRow.size()) {
            		lstDataRowForPreview.add(lstDataRow[counter]);
            		counter++;
            	}
	            listAllChunk.add(lstDataRowForPreview);
	            
	            mapResult.put('totalRow',lstDataRowForPreview.size());
	        //END TH: US-0008668  
	        
            }else{
            	Integer rowLimit = (Test.isRunningTest()?1:RECORD_LIMIT_PER_TRANS);
	            Decimal d = Decimal.valueOf(lstDataRow.size()) / Decimal.valueOf(rowLimit);
	 			Integer numOfChunk = d.round(System.RoundingMode.CEILING).intValue();
	
	            if(lstDataRow.size()<=rowLimit){
	                listAllChunk.add(lstDataRow);
	            }else{
	
	                for(Integer i=0;i<numOfChunk;i++){
	                    Integer startIndex = i == 0 ? 0 : i*rowLimit;
	                    Integer endIndex = i==0?rowLimit: (i*rowLimit)+rowLimit;
	                    endIndex = endIndex > lstDataRow.size()?lstDataRow.size():endIndex;
	
	                    List<List<String>> listChunk = new List<List<String>>();
	                    for(Integer j = startIndex;j< endIndex;j++)
	                    {
	                        listChunk.add(lstDataRow[j]);
	                    }
	                    listAllChunk.add(listChunk);
	
	                }
	            }
	            mapResult.put('totalRow',lstDataRow.size());
            }
            

            mapResult.put('chunk',listAllChunk.size());
            mapResult.put('listAllChunk',listAllChunk);
            mapResult.put('rowColumns',rowColumns);
            mapResult.put('status','ok');
            
        }catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
        catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}       
        
        return mapResult;
    }*/


    /*****************************************************************************************************************************
    @ Method:       doSaveChunkRecords
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008027
    @               loop over csv to generate sobject, then insert those sobject
    @ Event:		when user upload csv in MassUploadObject.page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	listChunk : list Of Chunk Of csv row, 
    @               rowColumns : column header,
    @               csvRowCount : count each row being process,
    @               numFormat : format number such as en or de. dot or comma,
    @               setting   : name and api name of sobject that is used to insert and setting of custom metadata type of Mass_Upload_Setting__mdt
    @				paramVal : param from url : eg :lkf=Contact:Email:28,29,30,31,32*Account:Name:7')
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.09.2020 / Sophal Noch / Created the method.
    					30.09.2020 / Sovantheany Dim / Update the method. US-0008088
                        09.07.2021 / SRONG TIN / Update the method. US-0009650 : added parameter sobjectApiName drcId
    @*****************************************************************************************************************************/    
    @AuraEnabled
    public static Map<String,Object> doSaveChunkRecords(List<List<String>> listChunk, List<String> rowColumns, Integer csvRowCount, String numFormat, Object setting, String paramVal, String defVal,Boolean sendResult, String dateFormat,Boolean isPreview,String fieldsiteColIndex, String colVerticalIndex, String colCategoryIndex, Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDepVertical, Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDepCategory,Id drcId){
        Map<String,Object> mapResult = new Map<String,Object>();
        List<String> listError = new  List<String>();
        Map<Integer,String> mapError = new Map<Integer,String>();
        try
        {
        	// SRONG TIN 12-July-2021 : check profile is Seller Portal US-0009650
            User currentUser = [Select Id,PRofile.Name,ContactId, Contact.AccountId From User Where Id =:UserInfo.getUserId()];
            
            //Boolean isSellerPortalProfile = currentUser.PRofile.Name == TICKET_NA_SELLER_PORTAL_PROFILE; //MN-06062024-US-0015298:No longer use with Profile Name
            Boolean isSellerPortalProfile = SEP_Helper.sepUser.isNA(); //MN-06062024-US-0015298:Use SP Main Domain instead of Profile Name

            //TH: 30/09/2020 : US-0008088
        	Boolean hasLookup = String.isNotBlank(paramVal);
        	Map<Integer,LookUpObject> mapLKO = new Map<Integer,LookUpObject>();
        	if(hasLookup)
        	{
        		mapLKO = populateLKO(paramVal,listChunk);
        	}
        	
        	Boolean hasDefault = String.isNotBlank(defVal);
        	DefaultField defField ; 
        	if(hasDefault){
        		
        		defField = new DefaultField(defVal.split(':')[0],defVal.split(':')[1]);
        	}
            //end TH: US-0008088 
            
            CustomUploadSetting customUploadSetting = (CustomUploadSetting) System.JSON.deserialize(JSON.serialize(setting), CustomUploadSetting.class);
            Map<String, Schema.SObjectField> allFieldDes = Schema.getGlobalDescribe().get(customUploadSetting.sobjectApiName).getDescribe().fields.getMap();
            setUpMapCsvColNameToSfField(rowColumns,customUploadSetting);

            // SRONG TIN 12-July-2021 : check profile is Seller Portal US-0009650
            Boolean isPortalUpload = String.isNotBlank(drcId) && customUploadSetting.sobjectApiName.equals(DEAL_SOBJECT) && isSellerPortalProfile;

            //MN: 09/02/2021 : US-0009001
            Set<String> sRequiredFields = new Set<String>();
            if (String.isNotBlank(customUploadSetting.reqFieldApiName)) sRequiredFields.addAll(customUploadSetting.reqFieldApiName.toLowerCase().split(';'));
            //end MN: US-0009001
            
            List<Messaging.SingleEmailMessage> listEmail = new List<Messaging.SingleEmailMessage>(); 
            
            List<SObject> listToSave = new List<SObject>();
            List<Integer> listCsvRow = new List<Integer>();
            List<String> listListingId = new List<String>();

            Map<Integer,Integer> mObjectValidateScore = new Map<Integer, Integer>();
            List<ObjDTO> listSObjectDTO = new List<ObjDTO>();

            //TH: 27/04/2021 : US-0009439 - [NA] NA Deals Bulk Upload Validation Rules for Vertical and Category
            Set<String> sdepVertical = checkDependency(pklDepVertical);
            Set<String> sdepCategory = checkDependency(pklDepCategory);
            //End US-0009439


            Boolean isFieldError = false;
            for(List<String> row : listChunk)
            {
            	ObjDTO sObjectDTO = new ObjDTO();
	           	sObjectDTO.lstCell = row;
	            	
                csvRowCount ++;
                
                try 
                {
                    SObject eachSobject = Schema.getGlobalDescribe().get(customUploadSetting.sobjectApiName).newSObject();
                    if(!String.isBlank(customUploadSetting.recordTypeId)){eachSobject.put(RECORD_TYPE_ID_FIELD,customUploadSetting.recordTypeId);}
                    
                    //TH: 30/09/2020 : US-0008088 : set default status to new
	            	if(defField != null){
	            		eachSobject.put(defField.fieldName,defField.fieldValue);
	            	}
                    //end TH: US-0008088 
                    
                    //TH:09/03/2021 : US-0009271 : Regression Bug - Upload NA Deal records showing duplicate site value
                    //'EBH_DealSiteId__c:1'
                    if(String.isNotBlank(fieldsiteColIndex)){
                    	Integer fieldsiteColIndexInt = Integer.valueOf(fieldsiteColIndex);
                    	String colSiteValue = row[fieldsiteColIndexInt].toUpperCase();
                    	row[fieldsiteColIndexInt] = MAP_SITE_CODE.containsKey(colSiteValue) ? MAP_SITE_CODE.get(colSiteValue) :  MAP_SITE_CODE.get('US');//default US
                    	String siteApi = row[fieldsiteColIndexInt];
                    	//TH: 27/04/2021 : US-0009439 - [NA] NA Deals Bulk Upload Validation Rules for Vertical and Category
                    	//check if Collumn Vertical is the correct dependency value
                    	if(String.isNotBlank(colVerticalIndex)){
                    		Integer colVerticalIndexInt = Integer.valueOf(colVerticalIndex);
                    		String verticalValue = row[colVerticalIndexInt];
                    		if(!String.isBlank(verticalValue) && sdepVertical != null && !sdepVertical.contains( siteApi + '_'+ verticalValue)) throw new FieldFormatException('Invalid Deal, Vertical is not a recognized value: ' + verticalValue);
                    	}
                    	//check if Collumn Category is the correct dependency value
                    	if(String.isNotBlank(colCategoryIndex)){
                    		Integer colCategoryIndexInt = Integer.valueOf(colCategoryIndex);
                    		String categoryValue = row[colCategoryIndexInt];
                    		if(!String.isBlank(categoryValue) && sdepCategory != null && !sdepCategory.contains( siteApi + '_'+ categoryValue)) throw new FieldFormatException('Invalid Deal, Category is not a recognized value: ' + categoryValue);
                    	}
	                    //End US-0009439
                    }
                    //END : TH: US-0009271
                    for(Integer i = 0; i < row.size(); i++){
                        String fieldValue = String.isBlank(row[i])?'':row[i].trim();
                        String csvColName = mapIndexCsvColName.get(i);
                        MappedField mapField = mapCsvColNameToSfField.get(csvColName);

                        if(mapField != null){
                        	//TH: 26/10/2020 : US-0008088: if Owner is NULL/blank, that the system will default the owner to the User who is doing the upload
                            if(mapField.fieldName == 'OwnerId' && String.isBlank(fieldValue)){
                            	fieldValue = UserInfo.getUserId();
                            }
                            //end US-0008088

                            // SRONG TIN 12-July-2021 : check profile is Seller Portal US-0009650
                            if(isPortalUpload){
                                if(mapField.fieldName == 'EBH_BusinessName__c'){
                                    fieldValue = currentUser.Contact.AccountId;
                                }else if(mapField.fieldName == 'Seller_Contact__c'){
                                    fieldValue = currentUser.ContactId;
                                }
                            }
                            // end US-0009650
                            //BR 09-01-2023-US-0013053
                            //Check Deal Bulk Upload of Internal HIVE for NA & AU for Deal_V3 ONLY
                            if(String.isNotBlank(drcId) && !isSellerPortalProfile && mapField.fieldName == 'EBH_DealPrice__c'){
                                // Assign Seller Price in Internal HIVE
                                eachSobject.put('EBH_SellerPrice__c', Decimal.valueOf(fieldValue));
                            }
                            //MN: 09/02/2021 : US-0009001: Update existing condition to also Check fields required that listed in Mass_Upload_Setting__mdt.Required_Field_API_Names__c
                            if(String.isBlank(fieldValue) && (isRequired(mapField.fieldName, allFieldDes) || (!sRequiredFields.isEmpty() && sRequiredFields.contains(mapField.fieldName)))){ throw new FieldFormatException('Required field '+mapField.fieldName+' missing value'); }
                            
                            Object dataValue = getValueByType(mapField.fieldType, fieldValue, numFormat, dateFormat);
                            
                            //TH: 30/09/2020 : US-0008088 : set look up value
                            if(mapLKO.containsKey(i) && String.isNotBlank(fieldValue)){
                            	LookUpObject lObject = mapLKO.get(i);
                            	Map<String,String> mapLookupResult = lObject.mapLookupResult;
                            	String key = fieldValue;
                            	//TH: US-0008904 : example: Key = Email_AccountName for seller Approval lookup
                            	if(!String.isBlank(lObject.addIndext)) key += '_'+row[Integer.valueOf(lObject.addIndext)].trim();
                            	if(mapLookupResult.containsKey(key)){
                                    dataValue = mapLookupResult.get(key);
                                    //TH:08/Feb/2022:US-0011027
                                    Map<String,String> mapRelatedLookupResult = lObject.mapRelatedLookupResult;
                                    if(mapRelatedLookupResult != null && mapRelatedLookupResult.containsKey(fieldValue)) eachSobject.put('Seller_Contact__c',mapRelatedLookupResult.get(fieldValue));
                                    //End US-0011027
                                }
                            	else {
                            		//Database.rollback(sp);
                            		throw new FieldFormatException('Value '+fieldValue+' on '+csvColName+' is not found.');
                            		
                            	}
                            	
                            }
                            //end TH : US-0008088
                            eachSobject.put(mapField.fieldName,dataValue);
                        }

                       
                    }
                    
                    //MN-05022021 US-0009001
                    if (customUploadSetting.sobjectApiName.equals(LEAD_SOBJECT)) { eachSobject.put('isSkipDupRule__c',true); }

                    //start SRONG TIN 09-July-2021 : upate deals record with value from Deal Retail Campaign US-0009650 (Deals RecordType NA Unsub Deal)
                    if(String.isNotBlank(drcId) && customUploadSetting.sobjectApiName.equals(DEAL_SOBJECT)){
                        EBH_DealRetailCampaign__c drc = [SELECT Id,Name,EBH_Date__c,Start_Time__c,EPH_EndDate__c,End_Time__c,EBH_Country__c FROM EBH_DealRetailCampaign__c WHERE Id = :drcId];
                        eachSobject.put('EBH_DealRetailCampaign__c',drc.Id);
                        eachSobject.put('EBH_DealStartDate__c',drc.EBH_Date__c);
                        eachSobject.put('EBH_DealStartTime__c',drc.Start_Time__c);
                        eachSobject.put('EBH_DealEndDate__c',drc.EPH_EndDate__c);
                        eachSobject.put('EBH_DealEndTime__c',drc.End_Time__c);
                        eachSobject.put('EBH_Status__c','Processing');
                        //SRONG TIN 21-July-2021
                        eachSobject.put('EBH_RecommendedRetailPriceWAS__c','RRP');
                        eachSobject.put('EBH_DealSiteId__c',drc.EBH_Country__c);
                    }
                    //end SRONG : US-0009650 
                    
                    listToSave.add(eachSobject);
                    listCsvRow.add(csvRowCount);
                    sObjectDTO.status = 'OK';//TH : US-0008668
                  
                }catch(Exception ex)
                {   
                    //listError.add(ROW_ERROR_MSG_TEMPLATE.replace('{!rowNum}', csvRowCount+'').replace('{!err}',ex.getMessage())); // US-0008027 stote error of any fail row of csv
                	mapError.put(csvRowCount,ROW_ERROR_MSG_TEMPLATE.replace('{!rowNum}', csvRowCount+'').replace('{!err}',ex.getMessage()));
                	sObjectDTO.status = ex.getMessage();//TH : US-0008668

                	isFieldError = true;//TH : US-0008668
                }
                

                listSObjectDTO.add(sObjectDTO);//TH : US-0008668
            }
            listChunk.clear();
            
            Integer insertedCount = 0;
            if(!isPreview){
	            if(!listToSave.isEmpty()){
	            	
	                Database.SaveResult[] srList = Database.insert(listToSave, false);
	                listToSave.clear();
	                Integer index = 0;
	                for (Database.SaveResult sr : srList) {
	    
	                    if (sr.isSuccess()) {
	                            insertedCount ++ ;
	                    }else{
	    
	                        String fieldErrorMsg = '';
	                        if(!sr.getErrors()[0].getFields().isEmpty()){
	    
	                            fieldErrorMsg = '. On Salesforce Fields:';
	                            for(String eachErrorField : sr.getErrors()[0].getFields()){
	                                fieldErrorMsg += ' '+eachErrorField;
	                            }
	    
	                        }
	    
	                        // US-0008027  stote error of any fail insert record
	                        //listError.add(ROW_ERROR_MSG_TEMPLATE.replace('{!rowNum}', listCsvRow[index]+'').replace('{!err}',sr.getErrors()[0].getMessage()+fieldErrorMsg));
	                    	mapError.put(listCsvRow[index],ROW_ERROR_MSG_TEMPLATE.replace('{!rowNum}', listCsvRow[index]+'').replace('{!err}',sr.getErrors()[0].getMessage()+fieldErrorMsg));
	                    }
	                    index++;
	                }
	
	            }
	            
	            //TH:06/04/2021:sort List error : US-0009307
	            if(!mapError.isEmpty()){
	            	List<Integer> lstRowError = new List<Integer>();
	            	lstRowError.addAll(mapError.keySet());
	            	//now sort them
	            	lstRowError.sort();
		            for(Integer i : lstRowError){
		            	listError.add(mapError.get(i));
		            }




	            }
	            //End US-0009307
	            
	            //TH: 30/09/2020 : US-0008088 : AC 6 : After bulk upload has been completed, send an email
	            //move send result to auracomponent:MassUploadObject
	        	//if(sendResult){
	        		//handleSendResult(insertedCount,listError);
	        	//}
				//end TH: US-0008088 
            }
            
			mapResult.put('insertedCount', insertedCount);
            mapResult.put('listError',listError);
            mapResult.put('csvRowCount',csvRowCount);
			mapResult.put('status','ok');
			mapResult.put('data', listSObjectDTO);


			mapResult.put('isFieldError', isFieldError);
        }catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
        catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}

        return mapResult;
    }
    
    /*****************************************************************************************************************************
    @ Method:       checkDependency
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0009439 - [NA] NA Deals Bulk Upload Validation Rules for Vertical and Categor
    @ Event:		check if contain dependency value on Category or Vertical for bulk upload
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDependancy
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.04.2021 / Sovantheany Dim / Create methode
    @*****************************************************************************************************************************/  
    private static Set<String> checkDependency(Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDependancy){
    	if(pklDependancy == null) return null;
    	Set<String> setValPKL = new Set<String>();
        for(String contField: pklDependancy.keySet())
		{
			List<ApexUtil.PicklistEntryWrapper> lstDep = pklDependancy.get(contField);
			for(ApexUtil.PicklistEntryWrapper pickValue : lstDep)
			{		 
				setValPKL.add(contField+'_'+pickValue.value);
			}
		}
		return setValPKL;	
    }
    
    @AuraEnabled
    public static void handleSendResult(Integer insertedCount, List<String> listError){
    	User currentUser = ApexUtil.getCurrentUser();
    	String templateName = 'Deal_Bulk_Upload_Result';
    	List<EmailTemplate>  empt = Database.query(EBH_ConstantsUtility.SOQL_BOB_EMAIL_TEMPLATE);
    	
    	String htmlBody = empt[0].HtmlValue.replace('{UploadUser}',currentUser.Name)
				.replace('{DateTimeUploading}',System.now().format())
				.replace('{totalSuccessDeals}',String.valueOf(insertedCount))
				.replace('{listRecordsFail}',String.join(listError,'<br/>'))
				.replace('{isError}',listError.size()>0 ? 'block':'none');	
    	
	    if(!Test.isRunningTest()) ApexUtil.doSend(empt[0].subject,currentUser.Email,htmlBody);
    }
    
    private static void setUpMapCsvColNameToSfField(List<String> csvColumns, CustomUploadSetting customUploadSetting){

        mapIndexCsvColName.clear();
        mapCsvColNameToSfField.clear();

        for(Integer i = 0; i < csvColumns.size(); i++){
            
            mapIndexCsvColName.put(i,csvColumns[i].trim().toLowerCase());
            
        }

        List<String> listCsvColumnNames = customUploadSetting.csvColumnNames.split(SEMI_COLON_SIGN);
        List<String> listCsvColumnTypes = customUploadSetting.csvColumnTypes.split(SEMI_COLON_SIGN);
        List<String> listFieldApiName = customUploadSetting.fieldApiName.split(SEMI_COLON_SIGN);

       for(Integer i = 0; i < listCsvColumnNames.size(); i++ ){

           
            mapCsvColNameToSfField.put(
                listCsvColumnNames[i].trim().toLowerCase(),
                new MappedField( listFieldApiName[i].trim().toLowerCase(), listCsvColumnTypes[i].trim().toLowerCase() )
            );


       }

    }

    // private static String toFormatString(String[] listStr)
    // {  
    //   String str = '';
    //   for(String s : listStr)
    //   {
    //     str+=s+'<br/>';
    //   }
      
    //   return str;
      
    // }

    public static Object getValueByType(String fieldType, String fieldValue, String locale,String dateLocalFormat){

        Boolean isEmpty = String.isEmpty(fieldValue);
        if(fieldType == DATA_TYPE_DECIMAL) {
            fieldValue = fieldValue.replaceAll('[^0-9.,]', '');
            fieldValue = locale=='en'?fieldValue.replace(',',''):fieldValue.replace('.','').replace(',','.'); //convert number with format to system number
            return isEmpty ? null : Decimal.valueOf(fieldValue);// :changed from zero to null
        }else if(fieldType == DATA_TYPE_DATE){
            
            if(String.isEmpty(fieldValue)) {
                return null;
            }
            try{
                String[] ds = fieldValue.split(mapFormatSep.get(dateLocalFormat));
                //newinstance: yyyy,MM,dd
                return date.newinstance(Integer.valueOf(ds[mapFormatIndex.get(dateLocalFormat)[0]]),Integer.valueOf(ds[mapFormatIndex.get(dateLocalFormat)[1]]),Integer.valueOf(ds[mapFormatIndex.get(dateLocalFormat)[2]])); 
            }catch(Exception ex)
            {
                throw new FieldFormatException('Invalid Date Format: "'+ fieldValue +'". Expected: '+ dateLocalFormat.toUpperCase() +' ');
            }
            
        }else if(fieldType == DATA_TYPE_TIME)
        {
        	 if(isEmpty) return null;
        	 Time t = isValidTime(fieldValue);
        	 if(t==null)
        	 {
        	 	throw new FieldFormatException('Invalid Time Format: "'+fieldValue+'". Expected: HH:MM.');
        	 }
        	 return t;
        }        
        else if(fieldType == DATA_TYPE_NUMBER){
            fieldValue = fieldValue.replaceAll('[^0-9]', '');
            return isEmpty ? null : Integer.valueOf(fieldValue); //changed from zero to null
        }
        return fieldValue;
    }

    //valid time: 10:00, 20:00,... HH:MM
    private static Time isValidTime(String strTime)
    {
    	strTime = strTime.trim();
    	if(strTime.contains(' ') || !strTime.contains(':')) //10:00 AM? 
    	{
    		return null;
    	}
    	String[] strTimes = strTime.split(':');
    	Time myTime = null;
    	
    	try
    	{
    		myTime = Time.newInstance(ApexUtil.toInteger(strTimes[0]),ApexUtil.toInteger(strTimes[1]),0,0);
    	}catch(Exception ex)
    	{
	   		System.debug(ex);
    	}
    	
    	return myTime;
    	 
    }
   
    public static Boolean isRequired(String fName,Map<String, Schema.SObjectField> allFieldDes )
    {
      return !allFieldDes.get(fName).getDescribe().isNillable();
         
    }

    private static Map<Integer,LookUpObject> populateLKO(String paramVal,List<List<String>> listChunk)
    {
    	Map<Integer,LookUpObject> mapLKO = new Map<Integer,LookUpObject>();

    	//Account:Name:7*Contact:Email:28,29,30,31,32_Account.Name:7 // (old NA Deal params)

        // 24.11.2021 / Sophal Noch / US-0010754 add recordtype params : (old NA Deal params)
        //Account:Name:7:RecordTypeId:0126A000000M9xLQAS*Contact:Email:28,29,30,31,32:Account.RecordTypeId:0126A000000M9xLQAS_Account.Name:7
        
        for(String  p1 : paramVal.split('[*]'))
    	{
    		LookUpObject lko = new LookUpObject();
            List<String> lstP1 = new List<String>();
            String p0 = '';
            if(p1.contains('-')){//TH:07/Feb/2022:US-0011027 - Ability for System to default to the DWH Contact when internally Bulk Uploading
                lko.relatedObjName = p1.split('-')[1].split(',')[0];
                lko.relatedFieldName = p1.split('-')[1].split(',')[1];
                lko.rtIdRelatedFieldName = p1.split('-')[1].split(',')[2];
                lko.rtIdRelatedFieldVal = p1.split('-')[1].split(',')[3];
                lko.rtIdParentFieldName = p1.split('-')[1].split(',')[4];
                lko.rtIdParentFieldVal = p1.split('-')[1].split(',')[5];
                p0 = p1.split('-')[0];
            }else{
                p0 = p1;
            }
    		if(p0.contains('_')){
    			lstP1 = p0.split('_')[0].split(':');
    			lko.additionFieldName = p0.split('_')[1].split(':')[0];
    			lko.addIndext = p0.split('_')[1].split(':')[1];
    		}else{
    			lstP1 = p0.split(':');
            }
            
    		lko.objName = lstP1[0];
    		lko.fieldName = lstP1[1];
    		lko.setIndex = new Set<String>(lstP1[2].split(','));
            
            // 24.11.2021 / Sophal Noch / US-0010754 use recordtype params for filtering record
            // if(lstP1.size() > 4){
            //     lko.rtIdFieldName = lstP1[3];
            //     lko.rtIdFieldVal = lstP1[4];
            // }

            // 06/02/2023 / Sophal Noch / US-0013168 :
            // Contact:Email:28,29,30,31,32:Account.RecordTypeId:0126A000000M9xLQAS:RecordTypeId:0126A000000T3OOQA0,0126A000000T3OQQA0_Account.Name:7*Account:Name:7:RecordTypeId:0126A000000M9xLQAS
            // Url is splitted into list string and below is what index is maped to value :
            // index 3 = Account.RecordTypeId
            // index 4 = 0126A000000M9xLQAS
            // index 5 = :RecordTypeId
            // index 6 = :0126A000000T3OOQA0,0126A000000T3OQQA0
            Integer stIndex = 4; 
            if(lstP1.size() > stIndex){
                 // loop 2 items per time, per loop has field name and field value
                for(Integer i = stIndex; i < lstP1.size(); i+=2){

                    lko.listCdtFieldName.add(lstP1[i-1]);

                    List<String> listVal = new List<String>();
                    for(String val : lstP1[i].split(',')){
                        listVal.add(String.escapeSingleQuotes(val));
                    }
                    lko.listCdtFieldVal.add(ApexUtil.closeSQoute(String.join(listVal, '\',\'')));
                    
                }
            }
            

    		//lko.setValue = setValue;
    		//lko.doQuery();
    		for(String s_index: lko.setIndex)
    		{
    			mapLKO.put(Integer.valueOf(s_index),lko); //column index must be unique 
    		}        
    	}
    	
    	//assign value from csv into Set to be queried as filter
    	Map<Integer,Set<String>> mapSetValue = new Map<Integer,Set<String>>();
    	for(List<String> row : listChunk)
    	{  
    		for(Integer i = 0; i < row.size(); i++)
    		{
    			if(String.isBlank(row[i])) continue;
    			if(mapLKO.containsKey(i)) //find value for the index (col) to be queried later
    			{
    				if(!mapSetValue.containsKey(i))
    				{
    					mapSetValue.put(i,new Set<String>());
    				}
    				mapSetValue.get(i).add(row[i]+''.trim());
    			}
    		}
    	}
    	
    	//different index, but could be same object. here to avoid qurey same object
    	Map<String,LookUpObject> mapQuery = new Map<String,LookUpObject>();
    	for(LookUpObject lko : mapLKO.values())
    	{
    		mapQuery.put(lko.objName,lko);
    	}
    	//setting value for qury for each object
    	for(LookUpObject lko : mapQuery.values())
    	{
    		Set<String> sValue = new Set<String>();
    		for(String index : lko.setIndex){
    			if(!mapSetValue.containsKey(Integer.valueOf(index))) continue;
    			Set<String> sEachColumnValue = mapSetValue.get(Integer.valueOf(index));
    			sValue.addAll(sEachColumnValue);
    		}
    		Set<string> sAdditionalValue = new Set<String>();
    		if(!String.isEmpty(lko.addIndext)){
    			Integer index = Integer.valueOf(lko.addIndext);
    			if(mapSetValue.containsKey(index)) sAdditionalValue.addAll(mapSetValue.get(index));
    		}
    		//String firstIndex = (new list<string>(lko.setIndex) )[0];
    		lko.setValue = sValue;
    		lko.setAdditionValue = sAdditionalValue;
    		lko.doQuery(); 
    	}
    	
    	//assign result to each same objects but diffent index
    	for(LookUpObject lko : mapLKO.values())
    	{
    		lko.mapLookupResult = mapQuery.get(lko.objName).mapLookupResult;
    	}
    	return mapLKO;
    }
    
    /*****************************************************************************************************************************
    @ Method:       getDocumentUrl
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008027
    @               get sample of csv
    @ Event:		when user click link in MassUploadObject.page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	String sobjectApiName
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.09.2020 / Sophal Noch / Created the method.
    				25.09.2020 / Sovantheany Dim / Update the method. US-0008088 : add parameter sobjectApiName
                    09.07.2021 / SRONG TIN / Update the method. US-0009650 : added parameter sobjectApiName isDealRetailCampaign
    @*****************************************************************************************************************************/   

    @AuraEnabled
	public static string getDocumentUrl(String sobjectApiName,Boolean isDealRetailCampaign){
        // SRONG TIN 21-July-2021 : check profile is Seller Portal US-0009650
        User currentUser = [Select Id,PRofile.Name,ContactId, Contact.AccountId From User Where Id =:UserInfo.getUserId()];
        
        //Boolean isSellerPortalProfile = currentUser.PRofile.Name == TICKET_NA_SELLER_PORTAL_PROFILE; //MN-06062024-US-0015298:No longer use with Profile Name
        Boolean isSellerPortalProfile = SEP_Helper.sepUser.isNA(); //MN-06062024-US-0015298:Use SP Main Domain instead of Profile Name

        // end 
        String urlId;
		String docName = '';
		if(sobjectApiName == 'Lead') docName = LEAD_DOC_NAME;
		else if(sobjectApiName == DEAL_SOBJECT && !isDealRetailCampaign) docName = DEAL_DOC_NAME;
        else if(sobjectApiName == DEAL_SOBJECT && isDealRetailCampaign && !isSellerPortalProfile) docName = NA_UNSUB_DEAL_INTERNAL_DOC_NAME; // SRONG TIN 09-July-2021, US-0009650, 
		else if(sobjectApiName == DEAL_SOBJECT && isDealRetailCampaign && isSellerPortalProfile) docName = NA_UNSUB_DEAL_SELLER_DOC_NAME; // SRONG TIN 21-July-2021, US-0009650, 
        
        // Acmatac SEING, 17/03/2022 US-0011204 - Use binding variable instead of dynamic.
        //String whereCl = ' where DeveloperName=\''+docName+'\'';
        String whereCl = ' where DeveloperName=:docName';
		for (Document oneId : Database.query(EBH_ConstantsUtility.SOQL_DOC+whereCl)) {
			urlId = oneId.Id;
		}
		String urlInstance=URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file='+urlId;
		return urlInstance;
	}
    
    public class MappedField{
        public String fieldName;
        public String fieldType;
        public MappedField(String fieldName, String fieldType){
            this.fieldName = fieldName;
            this.fieldType = fieldType;
        }       
    }
    
    public class DefaultField{
        public String fieldName;
        public String fieldValue;
        public DefaultField(String fieldName, String fieldValue){
            this.fieldName = fieldName;
            this.fieldValue = fieldValue;
        }       
    }
    
    public class CustomUploadSetting{
        @AuraEnabled public String csvColumnNames;
        @AuraEnabled public String csvColumnTypes;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String reqFieldApiName; //MN-05022021-US-0009001
        @AuraEnabled public String recordTypeId;
        @AuraEnabled public String sobjectApiName;
        @AuraEnabled public String sobjectName;
        @AuraEnabled public String description;
        @AuraEnabled public List<StandardDate> standardDateFormats;
    }
    
    public class LookUpObject{
    	public String objName; // object to lookup to
    	public String fieldName; // field name to query
    	public String additionFieldName;
    	public String addIndext;
    	public Set<String> setIndex; // all indexes of the column if in the same object
    	
    	public Map<String,String> mapLookupResult;
    	public Set<String> setValue;//populate from csv to be queried
    	public Set<String> setAdditionValue;
        // public String rtIdFieldName;
        // public String rtIdFieldVal;
        public List<String> listCdtFieldName = new List<String>();
        public List<String> listCdtFieldVal = new List<String>();


        public String relatedObjName;
        public String relatedFieldName;
        public String rtIdRelatedFieldName;
        public String rtIdRelatedFieldVal;
        public String rtIdParentFieldName;
        public String rtIdParentFieldVal;

        public Map<String,String> mapRelatedLookupResult;

    	public LookUpObject()
    	{
    	
    	}
    	
        // Acmatac SEING, 17/03/2022 US-0011204 - TECHDEBT: SOQL SOSL Injection - Add escapeSingleQuotes and DeleteWhitespace() to WHERE SOQL Query String
    	public void doQuery()
    	{
    		String fieldToQuery = fieldName;
    		String wherecls = fieldName+' IN :setValue';

            // 24.11.2021 / Sophal Noch / US-0010754 add recordtype condition to query
            // if(String.isNotBlank(rtIdFieldName) && String.isNotBlank(rtIdFieldVal)){
            //     wherecls += ' and ' + rtIdFieldName + ' = \'' + String.escapeSingleQuotes(rtIdFieldVal) + '\'';
            // }

            // 06/02/2023 / Sophal Noch / US-0013168 :
            if(!listCdtFieldName.isEmpty() && !listCdtFieldVal.isEmpty() && listCdtFieldName.size() == listCdtFieldVal.size()){
                for(Integer i = 0; i < listCdtFieldName.size(); i++){
                    wherecls += ' and ' + listCdtFieldName[i] + ' IN (' + listCdtFieldVal[i] + ')';
                }
            }
            
    		//TH: US-0008904
    		if(!String.isBlank(additionFieldName)){
    			fieldToQuery += ','+additionFieldName;
    			wherecls += ' and '+additionFieldName+' IN :setAdditionValue';
    		}

    		String soql = 'Select Id, '+fieldToQuery+' From '+objName+' Where '+wherecls;
    		mapLookupResult = new Map<String,String>();
    		for(SObject sobj: Database.query(soql))
    		{
    			String key = '';
    			for(String fieldName : fieldToQuery.split(',')){
    				key += ApexUtil.getValue(fieldName,sobj)+'_';
    			}
    			key = key.removeEnd('_');
    			mapLookupResult.put(key,sobj.get('Id')+'');
            }
            //TH:07/Feb/2022:US-0011027 - query for related object
            if(!String.isBlank(relatedObjName)){
                mapRelatedLookupResult = new Map<String,String>();
                String relatedSoql = 'Select Id, '+relatedFieldName+' From '+relatedObjName;
                String whereclsRelatedObj = ' Where '+relatedFieldName.deleteWhitespace()+' IN :setValue';
                if(String.isNotBlank(rtIdRelatedFieldName) && String.isNotBlank(rtIdRelatedFieldVal)){
                    whereclsRelatedObj += ' AND ' +rtIdRelatedFieldName.deleteWhitespace()+ ' = \'' + String.escapeSingleQuotes(rtIdRelatedFieldVal) + '\'';
                }
                if(String.isNotBlank(rtIdParentFieldName) && String.isNotBlank(rtIdParentFieldVal)){
                    whereclsRelatedObj += ' AND ' +rtIdParentFieldName.deleteWhitespace()+ ' = \'' + String.escapeSingleQuotes(rtIdParentFieldVal) + '\'';
                }
                for(SObject sobj: Database.query(relatedSoql+whereclsRelatedObj)){
                    String key = ApexUtil.getValue(relatedFieldName,sobj)+'';
                    mapRelatedLookupResult.put(key,sobj.get('Id')+'');
                }
            }

    	}
    }

    class FieldFormatException extends Exception {} 
    
    /*****************************************************************************************************************************
    @ Method:       getStandardDateFormatsIndex
    @ Author:       Ratha Sim (ratha.sim@gaea-sys.com)
    @ Purpose:      US-0008637
    @               get sample of csv
    @ Event:		Load standard date format of csv
    ------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.12.2020 / Ratha Sim / Created the method.
    @*****************************************************************************************************************************/   
    private static List<StandardDate> getStandardDateFormatsIndex() {

        String userDateFormat = standardDateFormats().contains(getUserDateFormat()) ? getUserDateFormat() : 'dd/MM/yyyy';
        List<StandardDate> StandardDates = new List<StandardDate>(); 
        for (String  dtFm : standardDateFormats()) {
            StandardDates.add(new StandardDate(
                dtFm.toUpperCase(),
                dtFm,
                dtFm.equalsIgnoreCase(userDateFormat)
            ));
        }        
        return StandardDates;
    }

    private static List<String> standardDateFormats() {
        return new List<String> {
            'MM/dd/yyyy',
            'dd/MM/yyyy',
            'yyyy/MM/dd',
            'yyyy-MM-dd',
            'dd.MM.yyyy'    
        };
    }
    
    private static String getUserDateFormat() {
        String  userLocale  = UserInfo.getLocale();
        Map<String,String> localeToDateTimeFmtMap = ApexUtil.MAP_LOCALE_DATEFORMAT();
        if (!localeToDateTimeFmtMap.containsKey(userLocale))return 'dd/MM/yyyy';
        return localeToDateTimeFmtMap.get(userLocale).substringBefore(' ');
    }

    public class StandardDate {

        public StandardDate(String label, String value, Boolean selected) {

            this.label = label;
            this.selected = selected;
            this.value = value;
        }

        @AuraEnabled
        public String label {set; get;}
        @AuraEnabled
        public String value {set; get;}
        @AuraEnabled
        public Boolean selected {set; get;}
    }
    
    static Map<String, Set<String>> lightningToApexDataTypeMap = new Map<String, Set<String>>{
                'text' => new Set<String>{'address', 'id', 'phone', 'email', 'string', 'textarea', 'reference', 'picklist'},
                'date' => new Set<String>{'date', 'datetime', 'time'},
                'number' => new Set<String>{'double', 'integer','decimal'},
                'percent' => new Set<String>{'percent'},
                'currency' => new Set<String>{'currency'},
                'url' => new Set<String>{'url'}
        };
     public class ColName{
    	@AuraEnabled
    	public String label;
    	
    	@AuraEnabled
    	public String fieldName;
      
        @AuraEnabled
    	public String type;
    	
        @AuraEnabled
        public Boolean sortable = true;
        
        
    	
    	
    	@AuraEnabled
    	public Map<String,Object> typeAttributes;
    	
    	public ColName(String label,String fieldName,String type)
    	{
            
    		this.label = label;
    		this.fieldName = fieldName;
    		this.type = type.toLowerCase();
    		for (String typeMap : lightningToApexDataTypeMap.keySet()) {
	            if (lightningToApexDataTypeMap.get(typeMap).contains(this.type)) {
	                this.type = typeMap;
	                break;
	            }
	        }
    	}
    }
    
    public class ObjDTO{
    	
    	@AuraEnabled
    	public List<String> lstCell;
    	
    	@AuraEnabled
    	public String status;
    	
    	public ObjDTO()
    	{
    		lstCell = new List<String>();
    	}
    }
}