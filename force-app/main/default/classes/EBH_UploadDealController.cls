/**
  -changed log:
   + NK:31/10/2017: https://gaeasys.plan.io/issues/11788?pn=1#note-59
     The format for the date is causing quite a few issues for the csv file formatting. 
     We therefore require the date format to be changed to allow only the date in the format - dd/mm/yyyy
   + Fixed empty row that causes to fail upload.
   
   + 08/11/2017(11788?pn=1#note-64):
     1) Ensure that all fields that are mandatory for creating a new deal are also mandatory in the csv import - i.e. - Product Title, Category, Quantity, Seller Price, Seller Email - please can you check the logic in the CSV importer especially -> at the moment if the Quantity and Seller Price are blank in the CSV import it adds a zero to the deal record.
    2) For deals uploaded via the CSV importer can we set 'deal price' field in the deal object = 'seller price' first when uploading proposals? Deal price can be edited afterwards, but in many cases it stays equal to 'seller price'. The 'seller price' field needs also to be populated as it is now.

	+ 13/06/2019: NK: EPH-7247 Deals Object - Make field "Product title" mandatory in bulk upload
	+ 14/06/2019: NK: EPH-7502 Deal Bulk Upload - add addtional fields to bulk upload file (compartible with existing csv)
	+ 08/02/2021 : TH :US-0008668 : [US] Bulk Upload field mapping CSV verification
  + 28.March.2022 / Acmatac SEING / US-0011204 - Fix new line break problem when upload
  + 21.November.2022 / Bora CHHORN / US-0012791 - Standard Deal upload V1 should only validate the Business name against Account record with Seller Record Type
  + 12.December.2022/ Sophal Noch / US-0012119 - Standard Deal (V1) Upload functionality - Extend excel copy paste feature
  + 06.02.2023 / SRONG TIN / US-0013067 - Uploading Un-Sub Deals component, replace it with xl copy, paste feature
  + 06.06.2023 / Mony Nou / US-0013721 - SP - IT Deals UAT issue fixes
  + 31.08.2023 / Mony Nou / US-0013600 - 1 IT Launch - Deals Bulk Upload component access for IT BU team
  + 20.10.2023 / Sambath Seng / US-0013554 - Deal (V2) Upload functionality to be replaced with Copy paste feature
  + 17.01.2024 / Sambath Seng / US-0014528 - NA Region (US) Increase character limit on Product title field
  + 25.01.2024 / Mony Nou / US-0014653 - Mark fields as optional as part of the deal upload copy and past functionality for V2
  + 25.01.2024 / LoumAng SENG / US-0014680 - Update field level mapping for List Price to map to RRP/WAS price on copy and paste functionality for Deal V2
  + 15.01.2025 / vadhanak voun / US-0016265 - (2) Upload Sub Deals in Hive
  + 31/1/2025 / Vimean Heng / US-0016639 - Testing Feedback fixes - Deals - Sprint 117
  + 31/03/2025 / Vimean Heng / US-0016745 - Deals upload and Management - Testing Feedback
  + 09/05/2025 / Sovantheany Dim / US-0025958 - Launch - PROD E2E testing feedback
*/
public class EBH_UploadDealController {
    private final static String DATA_TYPE_STRING ='String',DATA_TYPE_DECIMAL = 'Decimal',DATA_TYPE_NUMBER='Number',DATA_TYPE_DATE = 'Date',DATA_TYPE_TIME='Time',
													DATA_TYPE_PICKLIST='Picklist',DATA_TYPE_URL='URL',DATA_TYPE_REF='Reference',DATA_TYPE_EMAIL='Email',
                          DATA_TYPE_CURRENCY = 'Currency';
													
    //NK:13/06/2019:EPH-7247  additional required field
    private static Set<String> setRequiredFields = new Set<String>
    {
    	'EBH_ProductTitle__c','EBH_DealStartDate__c','EBH_DealStartTime__c','EBH_DealEndDate__c','EBH_DealEndTime__c'
    };
    
    private static Map<Integer, MappedField>mappedIndexColName = new Map<Integer, MappedField>{
        0 => new MappedField('EBH_eBayItemID__c', DATA_TYPE_STRING),
        1 => new MappedField('', ''),
        2 => new MappedField('EBH_ProductTitle__c', DATA_TYPE_STRING),
        3 => new MappedField('EBH_EAN__c', DATA_TYPE_STRING),
        // 4 => new MappedField('EBH_SellerPrice__c', DATA_TYPE_DECIMAL),
        4 => new MappedField('EBH_SellerPrice__c', DATA_TYPE_CURRENCY),
        5 => new MappedField('EBH_RecommendedRetailPriceWAS__c', DATA_TYPE_PICKLIST),
        // 6 => new MappedField('EBH_RRPWASPrice__c', DATA_TYPE_DECIMAL),
        6 => new MappedField('EBH_RRPWASPrice__c', DATA_TYPE_CURRENCY),
        7 => new MappedField('EBH_Quantity__c', DATA_TYPE_NUMBER),
        8 => new MappedField('EBH_Dealdateearliestpossible__c', DATA_TYPE_DATE),
        9 => new MappedField('EBH_DealFormat__c', DATA_TYPE_PICKLIST),
        10 => new MappedField('EBH_IdealoLink__c', DATA_TYPE_URL),
        11 => new MappedField('EBH_AmazonLink__c', DATA_TYPE_URL),
        //12 => new MappedField('EBH_ebayLink__c', DATA_TYPE_URL), //field changed to formula
        12 => new MappedField('', ''), 
        13 => new MappedField('EBH_PictureLink__c', DATA_TYPE_URL),
        14 => new MappedField('EBH_CommentfromeBaySourcer__c', DATA_TYPE_STRING),
        15 => new MappedField('EBH_CommentfromSeller__c', DATA_TYPE_STRING),
        16 => new MappedField('EBH_Category__c', DATA_TYPE_STRING),
        17 => new MappedField('', ''),
        18 => new MappedField('EBH_SellerEmail__c', DATA_TYPE_EMAIL),
        
        19 => new MappedField('EBH_DealSiteId__c', DATA_TYPE_PICKLIST), //EPH-5771 
        
        //NK:13/06/2019:EPH-7247 
        20 => new MappedField('EBH_DealStartTime__c', DATA_TYPE_TIME),  
        21 => new MappedField('EBH_DealEndTime__c', DATA_TYPE_TIME)  
        
    };
    
    private static Map<Integer, MappedField>mappedIndexColName_v2 = new Map<Integer, MappedField>{
        0 => new MappedField('EBH_eBayItemID__c', DATA_TYPE_STRING),
        1 => new MappedField('', ''), //seller name to look for id
        2 => new MappedField('EBH_ProductTitle__c', DATA_TYPE_STRING),
        3 => new MappedField('EBH_EAN__c', DATA_TYPE_STRING),
        // 4 => new MappedField('EBH_SellerPrice__c', DATA_TYPE_DECIMAL),
        4 => new MappedField('EBH_SellerPrice__c', DATA_TYPE_CURRENCY),
        // 5 => new MappedField('EBH_DealPrice__c', DATA_TYPE_DECIMAL),
        5 => new MappedField('EBH_DealPrice__c', DATA_TYPE_CURRENCY),
        6 => new MappedField('EBH_DealStartDate__c',DATA_TYPE_DATE),
        7 => new MappedField('EBH_DealStartTime__c', DATA_TYPE_TIME),  
        8 => new MappedField('EBH_DealEndDate__c',DATA_TYPE_DATE),
        9 => new MappedField('EBH_DealEndTime__c', DATA_TYPE_TIME),  
        10 => new MappedField('EBH_RecommendedRetailPriceWAS__c', DATA_TYPE_PICKLIST),
        // 11 => new MappedField('EBH_RRPWASPrice__c', DATA_TYPE_DECIMAL),
        11 => new MappedField('EBH_RRPWASPrice__c', DATA_TYPE_CURRENCY),
        12 => new MappedField('EBH_Quantity__c', DATA_TYPE_NUMBER),
        13 => new MappedField('EBH_Dealdateearliestpossible__c', DATA_TYPE_DATE),
        14 => new MappedField('EBH_DealFormat__c', DATA_TYPE_PICKLIST),
        15 => new MappedField('EBH_SpotlightCategory__c',DATA_TYPE_STRING),//DATA_TYPE_REF),        
        16 => new MappedField('EBH_IdealoLink__c', DATA_TYPE_URL),
        17 => new MappedField('EBH_AmazonLink__c', DATA_TYPE_URL),
        18 => new MappedField('', ''),  //ebay url
        19 => new MappedField('EBH_PictureLink__c', DATA_TYPE_URL),
        20 => new MappedField('EBH_CommentfromeBaySourcer__c', DATA_TYPE_STRING),
        21 => new MappedField('EBH_CommentfromSeller__c', DATA_TYPE_STRING),
        22 => new MappedField('EBH_Category__c', DATA_TYPE_STRING),
        23 => new MappedField('EBH_DealRetailCampaign__c',DATA_TYPE_STRING),//DATA_TYPE_REF),
        24 => new MappedField('EBH_SellerEmail__c', DATA_TYPE_EMAIL),
        25 => new MappedField('EBH_DealSiteId__c', DATA_TYPE_PICKLIST), //EPH-5771 
        26 => new MappedField('OwnerId',DATA_TYPE_STRING),//DATA_TYPE_REF)
        27 => new MappedField('List_Price__c', DATA_TYPE_CURRENCY), //MN-06062023-US-0013721
        28 => new MappedField('EBH_MaximumPurchases__c', DATA_TYPE_NUMBER), //MN-06062023-US-0013721 
        29 => new MappedField('SellersDealPriceMSKULower__c', DATA_TYPE_DECIMAL), //MN-06062023-US-0013721 
        30 => new MappedField('SellersDealPriceMSKUUpper__c', DATA_TYPE_DECIMAL), //MN-06062023-US-0013721 
        31 => new MappedField('ListPriceMSKULower__c', DATA_TYPE_DECIMAL), //MN-06062023-US-0013721 
        32 => new MappedField('ListPriceMSKUUpper__c', DATA_TYPE_DECIMAL), //MN-06062023-US-0013721 
        // SB 20.10.2023 US-0013554
        33 => new MappedField('Seller_Approver_1__c', DATA_TYPE_EMAIL),
        34 => new MappedField('Seller_Approver_2__c', DATA_TYPE_EMAIL),
        35 => new MappedField('Seller_Approver_3__c', DATA_TYPE_EMAIL),
        36 => new MappedField('Seller_Approver_4__c', DATA_TYPE_EMAIL),
        37 => new MappedField('Seller_Approver_5__c', DATA_TYPE_EMAIL),
        38 => new MappedField('EBH_Vertical__c', DATA_TYPE_PICKLIST),
        39 => new MappedField('EBH_Category__c', DATA_TYPE_PICKLIST),
        40 => new MappedField('SellersOfferPriceMSKULower__c', DATA_TYPE_DECIMAL),
        41 => new MappedField('SellersOfferPriceMSKUUpper__c', DATA_TYPE_DECIMAL)
    };
    
    private static Integer minColumnNumber = 20;
    //NK:06/10/2017:added 4 DE months: Mär Mai Okt Dez, the rest are the same
    private static Map<String, Integer>mMonth = new Map<String, Integer>{
        'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Mär' => 3,  'Apr' => 4,
        'May' => 5, 'Mai' => 5, 'Jun' => 6, 'Jul' => 7,  'Aug' => 8,
        'Sep' => 9, 'Oct' => 10, 'Okt' => 10,'Nov' => 11,'Dec' => 12,
        'Dez' => 12
    };
   
    
    private static Map<String, String>mDealFormat = new Map<String, String>{
        'Value Hero' => 'Featured', 'Basket Item' => 'Core'
    };
    private static String locale;
    public String referrer{get{return ApexPages.currentPage().getHeaders().get('Referer');} set;}
    private static final String SELLER_RECORDTYPE = 'EBH_Seller';//BR-21-11-22-US-0012791

    // 12.12.2022 / Sophal Noch / US-0012119 :
    private static final String TXT_START_INDEX = 'startIndex';
    private static final String TXT_STATUS = 'status';
    private static final String TXT_LIST_RECORD = 'listRecord';
    private static final String TXT_MAP_INDEX_TO_ERROR_MSG = 'mapIndexToErrMsg';
    private static final String TXT_IMPORT_DEAL_PRE_DML = 'importDealPreDML';
    // 06.02.2023 / SRONG TIN / US-0013067
    private static final String TXT_IMPORT_UN_SUB_DEAL_PRE_DML = 'importUnSubDealPreDML';
    private static final String TXT_METHOD_NOT_IMPLEMENTED = 'Method not implemented';
    private static final String NA_Unsub_Deal = 'Deal_V3';
    private static final String TXT_DE = 'DE';
    private static final String SUBSIDISED_DEAL = 'Deal_V2'; //MN-31082023-US-0013600
    
    private static final String ERROR_TXT_SELLER_NOT_FOUND = 'Seller Not Found: "{0}" At Row: {1}';
    private static final String ERROR_TXT_SELLERCONTACT_NOT_FOUND = 'Seller Contact Not Found: "{0}" At Row: {1}'; //MN-07062023-US-0013721 
    private static final String ERROR_TXT_REQUIRED_FIELD = 'Required field missing value({0}). At row: {1}, col: {2}';
    private static final String ERROR_TXT_SLCATE_NOT_FOUND = 'Spotlight Category is not found: ({0}). At row: {1}, col: {2}';
    private static final String ERROR_TXT_DRC_NOT_FOUND = 'Deal Retail Campaign is not found: ({0}). At row: {1}, col: {2}';
    private static final String ERROR_TXT_INCORRECT_FIELD_TYPE = '{0} At Row:{1}, col: {2}';
    private static final String ERROR_TXT_INVALID_PRICE_FORMAT = 'Invalid Price Format: "{0}".';
    private static final String ERROR_TXT_INVALID_FORMAT = 'Invalid Format: "{0}".';
    private static final String ERROR_TXT_INVALID_DATE_FORMAT1 = 'Invalid Date Format: "{0}".';
    private static final String ERROR_TXT_INVALID_DATE_FORMAT2 = 'Invalid Date Format: "{0}". Expected: dd/mm/yyyy.';
    private static final String ERROR_TXT_INVALID_DATE_FORMAT3 = 'Invalid Date Format: "{0}". Expected: dd.mm.yyyy.';


    private static final String SOBJ_APINAME_DEAL = 'EBH_Deal__c';
    private static final String FLD_APINAME_BUSINESSNAME = 'ebh_businessname__c';
    private static final String FLD_APINAME_SPOTLIGHTCATEGORY = 'ebh_spotlightcategory__c';
    private static final String FLD_APINAME_DEALRETAILCAMPAIGN = 'ebh_dealretailcampaign__c';
    private static final String FLD_APINAME_DEALFORMAT = 'ebh_dealformat__c';
    private static final String FLD_APINAME_DEALPRICE = 'ebh_dealprice__c';
    private static final String FLD_APINAME_SELLERPRICE = 'ebh_sellerprice__c';
    private static final String FLD_APINAME_DEALSITEID = 'ebh_dealsiteid__c';
    private static final String FLD_APINAME_SELLEREMAIL = 'ebh_selleremail__c';
    private static final String FLD_APINAME_SELLERCONTACT = 'seller_contact__c';
    private static final String FLD_APINAME_QUANTITY = 'ebh_quantity__c';//TH:US-0025958
    // 06.02.2023 / SRONG TIN / US-0013067
    private static final String FLD_APINAME_DEALSTARTDATE = 'EBH_DealStartDate__c';
    private static final String FLD_APINAME_DEALSTARTTIME = 'EBH_DealStartTime__c';
    private static final String FLD_APINAME_DEALENDDATE = 'EBH_DealEndDate__c';
    private static final String FLD_APINAME_DEALENDTIME = 'EBH_DealEndTime__c';
    private static final String FLD_APINAME_STATUS = 'EBH_Status__c';
    private static final String FLD_APINAME_RECOMMENDEDRETAILPRICEWAS = 'EBH_RecommendedRetailPriceWAS__c';
    private static final String FLD_APINAME_DEALRECORDTYPEID = 'RecordTypeId';
    
    private static final String FLD_VALUE_STATUS = 'Processing';
    private static final String FLD_VALUE_RECOMMENDEDRETAILPRICEWAS = 'RRP';

    // SB 20.10.2023 US-0013554
    private static final String TXT_IMPORT_SUB_DEAL_PRE_DML = 'importSubDealPreDML';
    private static final String TXT_IMPORT_SUB_DEAL_PRE_DMLDCA = 'importSubDealPreDMLDCA'; //NK:14/01/2025:US-0016265
    private static final String TXT_IMPORT_SUB_DEAL_PRE_DMLDCA_RELATED_LIST = 'importSubDealPreDMLDCARelatedList'; //VM:16/01/2025:US-0016530
    private static final String FLD_APINAME_SELLERAPPROVER = 'seller_approver_';
    private static final String FLD_APINAME_SELLERAPPROVER1 = 'seller_approver_1__c';
    private static final String FLD_APINAME_SELLERAPPROVER2 = 'seller_approver_2__c';
    private static final String FLD_APINAME_SELLERAPPROVER3 = 'seller_approver_3__c';
    private static final String FLD_APINAME_SELLERAPPROVER4 = 'seller_approver_4__c';
    private static final String FLD_APINAME_SELLERAPPROVER5 = 'seller_approver_5__c';
    private static final String FLD_APINAME_LISTPRICE = 'list_price__c';
    private static final String FLD_APINAME_VERTICAL = 'ebh_vertical__c';
    private static final String FLD_APINAME_CATEGORY = 'ebh_category__c';
    private static final String CONTACT_DWH_RECORDTYPE = 'EBH_DWH';
    private static final String CONTACT_MANUAL_RECORDTYPE = 'EBH_MANUAL';
    private static final String FLD_APINAME_SELLERSDEALMSKULOWER = 'sellersdealpricemskulower__c';
    private static final String FLD_APINAME_SELLERSDEALMSKUUPPER = 'sellersdealpricemskuupper__c';
    private static final String FLD_APINAME_SELLERSOFFERMSKULOWER = 'sellersofferpricemskulower__c';
    private static final String FLD_APINAME_SELLERSOFFERMSKUUPPER = 'sellersofferpricemskuupper__c';
    private static final String FLD_APINAME_LISTPRICEMSKULOWER = 'listpricemskulower__c';
    private static final String FLD_APINAME_LISTPRICEMSKUUPPER = 'listpricemskuupper__c';
    private static final String FLD_APINAME_EBAYITEMID = 'ebh_ebayitemid__c';
    private static final String TXT_US = 'US';
    private static final String ERROR_TXT_INVALID_VERTICAL = 'Invalid Deal, Vertical is not a recognized value: "{0}".';
    private static final String ERROR_TXT_INVALID_CATEGORY = 'Invalid Deal, Category is not a recognized value: "{0}".';
    private static final String ERROR_TXT_DEALPRICE_LESS_THAN_SELLERPRICE = 'Deal Price must be less than Seller Price.';
    private static final String ERROR_TXT_LESS_UPPER_SKU = 'Upper SKU fields must have a larger than than the Lower SKU fields.';
    private static final String ERROR_TXT_REQUIRED_ALL_MSKU = 'All Seller and Deal Price Multi SKU information must be populated.';
    private static final String ERROR_TXT_INVALID_LISTING_ID = 'Listing ID must be numeric and 12 characters in length.';
    private static final String ERROR_TXT_REQUIRED_SELLER_APPROVER = 'At least 1 Seller Aprrover must be populated. On Salesforce Fields: Seller_Approver_1__c';
    private static final String ERROR_TXT_INVALID_SELLER_APPROVER = 'Value "{0}" on "{1}" is not found.';
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
    
    private static final Set<String> SET_OPTIONAL_FIELD = new Set<String>{'ownerid'};
    private static final Set<String> SET_REQUIRED_FIELD = new Set<String>{'ebh_producttitle__c'};

    private static final String FLD_APINAME_PRODUCTTITLE = 'ebh_producttitle__c'; // SB 17.01.2024 US-0014528
    private static final String FLD_APINAME_OWNERID = 'ownerid'; //MN-25012024-US-0014653

    private static final Decimal SAMPLE_DECIMAL_VALUE = 1000.10;
    private static final String FLD_APINAME_RRPWASPRICE = 'ebh_rrpwasprice__c';//LA-25-01-2024-US-0014680

    /*********************************************************************************************************************************
    @ Change history: 28.March.2022 / Acmatac SEING / US-0011204 - Fix new line break problem when upload
    @ Change history: 03.June.2022 / Sophal Noch / US-0011721 - AU Standard Deal - Bulk Upload is not mapping to AU site
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> createDealFromCSV(String parentId, String filename, String contentfile,String separator,String numFormat, Boolean isPreview){
      locale = numFormat;
      
        Map<String, Object>mResult = new Map<String, Object>{
            'isSuccess' => true,
            'successRecord' => new List<EBH_Deal__c>()  
        };
        
        try{
            //windows: \n\r, unix: \r
            // US-0011204 START
            // contentfile = contentfile.replace('\n',''); STOP USING IT
            String newLineToUse =  Batch_BobSellerBulkCSV.NEWLINE_LF;
            if(contentfile.contains(Batch_BobSellerBulkCSV.NEWLINE_CR)){
              newLineToUse = Batch_BobSellerBulkCSV.NEWLINE_CR;
              contentfile =  contentfile.replace('\n','');
            }
            // US-0011204 END

            OpenCSVParser parser = new OpenCSVParser(separator,OpenCSVParser.DEFAULT_QUOTE_CHARACTER, OpenCSVParser.DEFAULT_ESCAPE_CHARACTER,OpenCSVParser.DEFAULT_STRICT_QUOTES, OpenCSVParser.DEFAULT_IGNORE_LEADING_WHITESPACE);
            
            //NK:27/09/2019:US-0009342: set to "fasle" to solve in-string comma: "TV, audio e video" 
            OpenCSVReader reader = new OpenCSVReader(parser,contentfile,newLineToUse,false);//unix user only \r
            List<List<String>>lstDataRow = reader.readAll();
            
            //TH:06/09/2021:US-0010030:Check column number
            Integer columnNumber = lstDataRow[0].size();
            if(columnNumber < minColumnNumber){
            	mResult = new Map<String, Object>{'isSuccess' => false,'errMsg' => System.label.Error_upload_Deal_Format};
            	return mResult;
            }
            //END US-0010030
            
            //TH: 08/02/2021 : US-0008668
            List<String> listCsvColumnNames = lstDataRow[0];
            listCsvColumnNames.add('Status');
            //END TH: 08/02/2021 : US-0008668
            
            lstDataRow.remove(0); //remove header
            //TH: 08/02/2021 : US-0008668
            if(isPreview){
            	List<List<String>> lstDataRowToProceed = new List<List<String>>();
		    	Integer counter = 0;
		    	while(counter<MassUploadObjectController.RECORD_LIMIT_FOR_PReVIEW && counter<lstDataRow.size()) {
		    		lstDataRowToProceed.add(lstDataRow[counter]);
		    		counter++;
		    	}
		    	
		    	createRecordsFromCSVFile(parentId, lstDataRowToProceed);
		    	
		    	List<MassUploadObjectController.ObjDTO> listSObjectDTO = new List<MassUploadObjectController.ObjDTO>();
		    
		    	integer rowNum = 0;
		    	for(List<String> dataRow : lstDataRowToProceed){
		    		rowNum++;
		    		MassUploadObjectController.ObjDTO sObjectDTO = new MassUploadObjectController.ObjDTO();
					sObjectDTO.lstCell = dataRow;
					if(mapError.containsKey(rowNum)){
						sObjectDTO.status = toFormatString(mapError.get(rowNum)).replace('<br/>',' ; ');
					}else{
						sObjectDTO.status = 'OK';
					}
					listSObjectDTO.add(sObjectDTO);
		    	}
		    	mResult.put('data', listSObjectDTO); 
            }//END TH: 08/02/2021 : US-0008668
            else{
            	List<EBH_Deal__c>lst2Insert = createRecordsFromCSVFile(parentId, lstDataRow);
	        	 if(!lst2Insert.isEmpty()){
	           		insert lst2Insert;
	        	}
	        	
	        	mResult.put('successRecord', lst2Insert.size());             
	            mResult.put('lstRecord', lst2Insert);
	            mResult.put('listError', toFormatString(listError));
	            mResult.put('errorSome', !listError.isEmpty());
            
            }
            mResult.put('columns', listCsvColumnNames);
        }catch(Exception ex){mResult = new Map<String, Object>{'isSuccess' => false,'errMsg' => ex.getMessage()  +' '+ ex.getStackTraceString()};
        }
        return mResult;
            
    }
    
    private static String toFormatString(String[] listStr)
    {  
      String str = '';
      for(String s : listStr)
      {
        str+=s+'<br/>';
      }
      
      return str;
      
    }
    static List<String> listError;
    static Map<Integer, List<String>> mapError;
    /*********************************************************************************************************************************
    @ Change history: 21.11.2022 / Bora CHHORN / US-0012791 - Standard Deal upload V1 should only validate the Business name against Account record with Seller Record Type
    *********************************************************************************************************************************/
    private static List<EBH_Deal__c> createRecordsFromCSVFile(String parentId, List<List<String>>lstDataRow){
        List<EBH_Deal__c>lstRecord = new List<EBH_Deal__c>();
        Map<String,String> mapSeller = new Map<String,String>();
        Set<String> setSeller = new Set<String>();
        Set<String> setSpotLightEXT = new Set<String>();
        
        //check which template to use, old or new
        Integer templateVersion = lstDataRow[0].size() <= (mappedIndexColName.size()+1)? 1: 2;
        Map<Integer, MappedField> mapRealFieldColumn = (templateVersion == 1 ?mappedIndexColName : mappedIndexColName_v2);
        
        for(List<String>dataRow : lstDataRow){
          setSeller.add(dataRow[1]);
          
          if(templateVersion==2 && String.isNotBlank(dataRow[15]))
          {
          	setSpotLightEXT.add(dataRow[15].trim());
          }
        }
        
        Map<String,String> mapSpotLight =  findSpotLight(setSpotLightEXT);
        
        for(Account es:[SELECT Id, Name FROM Account WHERE RecordType.DeveloperName =: SELLER_RECORDTYPE AND Name IN:setSeller]) //BR-21-11-22-US-0012791
        {
          mapSeller.put(es.Name,es.Id);
        }
        listError = new List<String> ();
        mapError = new Map<Integer, List<String>>();
        integer rowNum = 0;
        
        
        for(List<String> dataRow : lstDataRow){
        	
          rowNum++;
          
          if(isEmptyRow(dataRow))
          {
            continue;
          }
            //Deal__c deal = new Deal__c(Account= parentId);
            String realSellerId = mapSeller.get(dataRow[1]);
             if(realSellerId==null)
             {
             	String errorMss = 'Seller Not Found:"'+dataRow[1]+'" At Row:'+rowNum;
               listError.add(errorMss);
               mapMessageError(rowNum, errorMss);//TH: 08/02/2021 : US-0008668
               continue;
             }
            EBH_Deal__c deal = new EBH_Deal__c(EBH_BusinessName__c = realSellerId);
            Boolean hasError = false;
            for(Integer i=0;i<dataRow.size();i++){
                String strValue = dataRow[i];
                MappedField mapField = mapRealFieldColumn.get(i);//mappedIndexColName.get(i);
                if(mapField == null || String.isBlank(mapField.fieldName)) continue;
                
                //NK:08/11/2017
                if(String.isBlank(strValue) && isRequired(mapField.fieldName))
                {
                  hasError = true;
                  String errorMss = 'Required field missing value('+mapField.fieldName+'). At row: '+rowNum+', col: '+(i+1);
                  listError.add(errorMss);
                  mapMessageError(rowNum, errorMss);//TH: 08/02/2021 : US-0008668 
                  continue;
                }
                Object dataValue;
                try 
                {
                  // dataValue = getValueByType(mapField.fieldType, strValue);
                  dataValue = getValueByType(mapField.fieldType, strValue, null, null); //13.01.2023 / Sophal Noch / US-0012119 adjust param so old logic from old component can still work
                }catch(Exception ex)
                {
                  hasError = true;
                  String errorMss = ex.getMessage()+'" At Row:'+rowNum+', col: '+(i+1);
                  listError.add(errorMss);
                  mapMessageError(rowNum,errorMss);//TH: 08/02/2021 : US-0008668 
                  //break; //go to next row
                }
                
                if(mapField.fieldName == 'EBH_SpotlightCategory__c')
                {
                	//spotlight cat ext id provided but not found in the system
                	if(String.isNotBlank(strValue) && !mapSpotLight.containsKey(strValue.trim()))
                	{
                		hasError = true;
                		String errorMss = 'Spotlight Category is not found: ('+strValue+'). At row: '+rowNum+', col: '+(i+1);
	                  	listError.add(errorMss);
	                  	mapMessageError(rowNum,errorMss);//TH: 08/02/2021 : US-0008668 
	                  	continue;
                	}
                	dataValue = mapSpotLight.get(strValue.trim());
                }
                
                if(mapField.fieldName == 'EBH_DealFormat__c') dataValue = mDealFormat.containsKey(strValue) ? mDealFormat.get(strValue) : strValue;
                deal.put(mapField.fieldName, dataValue);
            }
            //if(String.isEmpty(deal.EBH_eBayItemID__c)) continue;
           
            if(!hasError)
            {
              deal.EBH_DealPrice__c = (templateVersion==1? deal.EBH_SellerPrice__c:deal.EBH_DealPrice__c);//NK:19/06/2019: EPH-7502: keep the old logic for old template
              //NK:25/05/2018: //EPH-5771
              // deal.EBH_DealSiteId__c =  EBH_ConstantsUtility.MAP_SITE_CODE_ID.containsKey((deal.EBH_DealSiteId__c+'').toUpperCase()) ? 
	            //   EBH_ConstantsUtility.MAP_SITE_CODE_ID.get((deal.EBH_DealSiteId__c+'').toUpperCase())
	            //   :EBH_ConstantsUtility.MAP_SITE_CODE_ID.get('DE'); //default DE

              // 03.06.2022 / Sophal Noch / US-0011721 :
              deal.EBH_DealSiteId__c =  String.isNotBlank(deal.EBH_DealSiteId__c) && deal.EBH_DealSiteId__c.isNumeric() ? deal.EBH_DealSiteId__c 
                : (ApexUtil.MAP_COUNTRY_CODE.containsKey((deal.EBH_DealSiteId__c+'').toUpperCase()) ? ApexUtil.MAP_COUNTRY_CODE.get((deal.EBH_DealSiteId__c+'').toUpperCase()) : ApexUtil.MAP_COUNTRY_CODE.get('DE')); //default DE
              
              lstRecord.add(deal);
              
            }
        }
        return lstRecord;
    }
    private static Object getValueByType(String fieldType, String fieldValue, String decimalPoint, String dateSeperator){
      return doGetValueByType(fieldType,fieldValue,decimalPoint,dateSeperator,false);
    }
    /*=======================================================================================================
    @ @change history:  31/1/2025 / Vimean Heng / US-0016639 - Testing Feedback fixes - Deals - Sprint 117 / import date follow user locale
    ========================================================================================================*/
    private static Object doGetValueByType(String fieldType, String fieldValue, String decimalPoint, String dateSeperator,Boolean useUserLocal){

        Boolean isEmpty = String.isEmpty(fieldValue);
        if(fieldType == DATA_TYPE_DECIMAL || fieldType == DATA_TYPE_CURRENCY) {

            if(String.isBlank(decimalPoint)){
              //13.01.2023 / Sophal Noch / US-0012119 make sure old logic from old component can still work
              fieldValue = fieldValue.replaceAll('[^0-9.,]', '');
              fieldValue = locale=='en'?fieldValue.replace(',',''):fieldValue.replace('.','').replace(',','.'); //convert number with format to system number
              return isEmpty ? null : Decimal.valueOf(fieldValue);//NK :08/11/2017:changed from zero to null
            }else{

              if(String.isBlank(fieldValue)) return null;
              fieldValue = fieldValue.trim();

              //13.01.2023 / Sophal Noch / US-0012119 throw error when has character in price or throw error when format is incorrect based on user locale
              if((fieldValue != fieldValue.replaceAll('[^0-9.,]', '')) || (decimalPoint == '.' && fieldValue.contains(',')) || (decimalPoint == ',' && fieldValue.contains('.'))){
                if(fieldType == DATA_TYPE_CURRENCY){
                  throw new FieldFormatException(String.format(ERROR_TXT_INVALID_PRICE_FORMAT, new String[]{fieldValue}));
                }else{
                  throw new FieldFormatException(String.format(ERROR_TXT_INVALID_FORMAT, new String[]{fieldValue}));
                }
              } 

              fieldValue = decimalPoint == ',' ? fieldValue.replace(',','.') : fieldValue;
              return Decimal.valueOf(fieldValue);    
              
            }
            
        //16. Feb 17
        }else if(fieldType == DATA_TYPE_DATE){
            if(isEmpty) return null; //NK:changed from Date.today() to null
            
            List<String>dateSplit = new List<String>();
            //if(fieldValue.contains('.')) dateSplit = fieldValue.replace('.', '').split(' ');
            //else if(fieldValue.contains('-')) dateSplit = fieldValue.split('-');
            //else if(fieldValue.contains('/')) dateSplit = fieldValue.split('/');
            
            if(String.isBlank(dateSeperator)){
              //18.01.2023 / Sophal Noch / US-0012119 make sure old logic from old component can still work
              if(!isValidDate(fieldValue))
              {
                throw new FieldFormatException('Invalid Date Format: "'+fieldValue+'". Expected: dd/mm/yyyy.');
              }
              dateSplit = fieldValue.split('/');

            }else{
              //18.01.2023 / Sophal Noch / US-0012119 when date value and user local are different, throw error accordingly
              if((dateSeperator == '/' && fieldValue.contains('.')) || (dateSeperator == '.' && fieldValue.contains('/'))){
                if(dateSeperator == '/'){
                  throw new FieldFormatException(String.format(ERROR_TXT_INVALID_DATE_FORMAT2, new String[]{fieldValue}));
                }else{
                  throw new FieldFormatException(String.format(ERROR_TXT_INVALID_DATE_FORMAT3, new String[]{fieldValue}));
                }
              }
              dateSeperator = dateSeperator == '.' ? '\\.' : dateSeperator;
              dateSplit = fieldValue.split(dateSeperator);
              if(dateSplit.size() != 3 || (!fieldValue.contains('/') && !fieldValue.contains('.'))){throw new FieldFormatException(String.format(ERROR_TXT_INVALID_DATE_FORMAT1, new String[]{fieldValue}));}
            }
            Integer  inD = 0;
            Integer  inM = 1;
            Integer  inY = 2;
            if(useUserLocal){
              ApexUtil.UserFormatIndex userFI = ApexUtil.getIndexOfUserDateFormat(dateSeperator);
              inD = userFI.dateIndex;
              inM = userFI.monthIndex;
              inY = userFI.yearIndex; 
            }
            String yearString = dateSplit[inY].length() == 2 ? '20' + dateSplit[inY] : dateSplit[inY];
            Integer year = Integer.valueOf(yearString.trim());
            Integer month = Integer.valueOf(dateSplit[inM].trim());  //no mapping need since restricted format
            Integer day = Integer.valueOf(dateSplit[inD].trim());
            /*
            String yearString = dateSplit[2].length() == 2 ? '20' + dateSplit[2] : dateSplit[2];
            Integer year = Integer.valueOf(yearString.trim());
            //Integer month = mMonth.get(dateSplit[1].trim());
            Integer month = Integer.valueOf(dateSplit[1].trim());  //no mapping need since restricted format
            Integer day = Integer.valueOf(dateSplit[0].trim());
            */
            return Date.newInstance(year, month, day);
            
        }else if(fieldType == DATA_TYPE_TIME)//NK:13/06/2019:EPH-7247
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
            return isEmpty ? null : Integer.valueOf(fieldValue); //NK :08/11/2017:changed from zero to null
        }
        return fieldValue;
    }
    // dd/mm/yyyy
    private static Boolean isValidDate(String strDate)
    {
      String[] dateStrArr = strDate.split('/');
       
        return dateStrArr.size()==3;
      
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
    //check row is empty
    private static Boolean isEmptyRow(String[] rowData)
    {
      String s = String.join(rowData,'').trim();
       
    return String.isEmpty(s) ;
    }
    public class MappedField{
        public String fieldName;
        public String fieldType;
        public MappedField(String fieldName, String fieldType){
            this.fieldName = fieldName;
            this.fieldType = fieldType;
        }       
    }
  
  //NK:08/11/2017
  static Map<String, Schema.SObjectField> allFieldDes = Schema.getGlobalDescribe().get('EBH_Deal__c').getDescribe().fields.getMap();
  public static Boolean isRequired(String fName)
  {
    return !allFieldDes.get(fName).getDescribe().isNillable() || setRequiredFields.contains(fName);
       
  }
  
  //NK:08/07/2019: EPH-7761
  public static Map<String,String> findSpotLight(Set<String> setExtId)
  {
  	 Map<String,String> mapResult = new Map<String,String>();
  	 for(EBH_SpotlightCategory__c sc: Database.query(EBH_ConstantsUtility.SOQL_SPOTLIGHT_CAT + ' Where EBH_SpotlightCategoryID__c IN:setExtId'))
  	 {
  	 	mapResult.put(sc.EBH_SpotlightCategoryID__c,sc.Id);
  	 }
  	 
  	 return mapResult;
  }

  private static Map<String,String> findDealRetailCampaign(Set<String> setDCRName)
  {
    Map<String,String> mapResult = new Map<String,String>();
    for(EBH_DealRetailCampaign__c drc: [Select Id,Name From EBH_DealRetailCampaign__c Where Name IN :setDCRName OR Id IN :setDCRName])
    {
      mapResult.put(drc.Name,drc.Id);
      mapResult.put(drc.Id,drc.Id);
    }
    return mapResult;
  }
  
  //TH : 08/02/2021: US-0008668 
  private static void mapMessageError(Integer rowNum, String mssg){
  	 List<String> lstError = (mapError.containsKey(rowNum)) ? mapError.get(rowNum) : new List<String>();
  	 lstError.add(mssg);
  	 mapError.put(rowNum,lstError);      
  }

  /*********************************************************************************************************************************
    @ Method:         checkDependency
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0013554 - Deal (V2) Upload functionality to be replaced with Copy paste feature
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.10.2023 / Sambath Seng / Created the method.
    *********************************************************************************************************************************/
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
 
  class FieldFormatException extends Exception{}    

  /*********************************************************************************************************************************
  @ Class:          EBH_UploadDealController.DealImport
  @ Version:        1.0
  @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
  @ Purpose:        US-0012119 - Standard Deal (V1) Upload functionality - Extend excel copy paste feature
  ----------------------------------------------------------------------------------------------------------------------------------
  @ Change history:  12.12.2022 / Sophal Noch / Created the class.
  *********************************************************************************************************************************/
  public class DealImport implements Callable {
  // implement callable so it be called dynamically from ExcelImporterController.serverSidePreDMLCheck

      /*********************************************************************************************************************************
      @ Method:         importDealPreDML
      @ Version:        1.0
      @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
      @ Purpose:        US-0012119 - Standard Deal (V1) Upload functionality - Extend excel copy paste feature
      ----------------------------------------------------------------------------------------------------------------------------------
      @ Change history:  12.12.2022 / Sophal Noch / Created the method.
      @                  31.08.2023 / Mony Nou / US-0013600 - 1 IT Launch - Deals Bulk Upload component access for IT BU team
      @                  17.01.2024 / Sambath Seng / US-0014528 - NA Region (US) Increase character limit on Product title field
    *********************************************************************************************************************************/
      
    @testVisible
    private Map<String,Object> importDealPreDML(Map<String,Object> mapArgs){

        // method to validate and populate fields on deal records, this method run before deal records are uploaded.
        // some method that are called here are from exist method of parent class EBH_UploadDealController

        Map<String, Object> mapResult = new Map<String, Object>();

        List<Map<String,String>> listRecord = (List<Map<String,String>>)(JSON.deserialize(JSON.serialize(mapArgs.get(TXT_LIST_RECORD)), List<Map<String,String>>.class));

        Integer startIndex = Integer.valueOf(mapArgs.get(TXT_START_INDEX));

        String formattedValue = SAMPLE_DECIMAL_VALUE.format(); // example: value = 1000.10. User Locale DE,  it is formatted to 1000,10. User Locale EN, It is formatted to 1000.10
        String decimalPoint = formattedValue.substring(5,6); // get the decimal point from formatted price.

        String todayDateFormat = Date.today().format();
        todayDateFormat = todayDateFormat.replaceAll('[0-9]',''); // remove all numbers from string format of date
        String dateSeperator  = String.isNotEmpty(todayDateFormat) ? todayDateFormat.substring(0,1) : '/'; // example value = 01/02/2023, then the user locale date seperator is "/".

        Integer templateVersion = listRecord[0].size() <= (mappedIndexColName.size()+1) ? 1: 2;

        Map<Integer, String> mapIndexToErrMsg = new  Map<Integer, String>();
        Set<String> setFldIsReq = new Set<String>();
        Map<String, String> mapApiNameToLabel = new  Map<String, String>();

        Map<String,Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(SOBJ_APINAME_DEAL).getDescribe().fields.getMap();
        for(SObjectField sobjField : mfields.values()){
            DescribeFieldResult descFldResult = sobjField.getDescribe();
            String fieldApiName = descFldResult.getName().toLowerCase();
            mapApiNameToLabel.put(fieldApiName, descFldResult.getLabel());
            if(SET_REQUIRED_FIELD.contains(fieldApiName) || (!SET_OPTIONAL_FIELD.contains(fieldApiName) && !descFldResult.isNillable())){setFldIsReq.add(fieldApiName);}  // store map of required field
        }

        Map<String,String> mapFNameToFType = new Map<String,String>();
        for(MappedField mappedField : mappedIndexColName_v2.values()){
            if(String.isNotBlank(mappedField.fieldName) && String.isNotBlank(mappedField.fieldType)){
                mapFNameToFType.put(mappedField.fieldName.toLowerCase(), mappedField.fieldType);
            }
        }

        Set<String> setSeller = new Set<String>();
        Set<String> setSpotLightEXT = new Set<String>();
        Set<String> setDCRName = new Set<String>();
        Set<String> setSellerEmail = new Set<String>();
        Map<String,Account> mapSeller = new Map<String,Account>();
        

        for(Map<String,String> mapObj : listRecord){

            String sellerName = mapObj.get(FLD_APINAME_BUSINESSNAME);
            if(String.isNotBlank(sellerName)) setSeller.add(sellerName);

            String sellerEmail = mapObj.get(FLD_APINAME_SELLEREMAIL);
            if(String.isNotBlank(sellerEmail)) setSellerEmail.add(sellerEmail);

            String splCate = mapObj.get(FLD_APINAME_SPOTLIGHTCATEGORY);
            if(String.isNotBlank(splCate)) setSpotLightEXT.add(splCate);

            String drcName = mapObj.get(FLD_APINAME_DEALRETAILCAMPAIGN);
            if(String.isNotBlank(drcName)) setDCRName.add(drcName);
        }
        
        Map<String,String> mapSpotLight = findSpotLight(setSpotLightEXT);

        Map<String,String> mapDCR = findDealRetailCampaign(setDCRName);

        Set<Id> setSellerId = new Set<Id>();
        Set<Id> setSellerGroupId = new Set<Id>();
        for(Account es:[SELECT Id, Name, Seller_Portal_Group__c FROM Account WHERE RecordType.DeveloperName =: SELLER_RECORDTYPE AND Name IN:setSeller]) //BR-21-11-22-US-0012791
        {
          mapSeller.put(es.Name,es);
          setSellerId.add(es.Id); // store seller id to find contact below
          if(es.Seller_Portal_Group__c != null){ 
            setSellerGroupId.add(es.Seller_Portal_Group__c); // store group id when seller is in linked account in order to find contact in linked account
          }
        }

        // find contact by email and seller id
        Map<String, Id> mapAccEmailKeyToContactId = new Map<String,Id> ();
        if(!setSellerEmail.isEmpty()){
          for(Contact cont : [Select id, Email,  AccountId From Contact Where Email IN: setSellerEmail AND AccountId IN : setSellerId]){
            String accEmailKey = cont.AccountId + cont.Email;
            if(!mapAccEmailKeyToContactId.containsKey(accEmailKey)) mapAccEmailKeyToContactId.put(accEmailKey, cont.Id);
          }
  
         // find contact by email and seller in linked account 
          if(!setSellerGroupId.isEmpty()){
            for(AccountContactRelation acr : [Select Id, AccountId, ContactId, Contact.Email From AccountContactRelation Where Contact.Email IN : setSellerEmail AND AccountId IN: setSellerGroupId]){
              String accEmailKey = acr.AccountId + acr.Contact.Email;
              if(!mapAccEmailKeyToContactId.containsKey(accEmailKey)) mapAccEmailKeyToContactId.put(accEmailKey, acr.ContactId);
            }
          }
        }

        //MN-31082023-US-0013600
        Id subDealRecordTypeId =  ApexUtil.getRecordTypeByName(SOBJ_APINAME_DEAL, SUBSIDISED_DEAL).Id;
        
        for(Integer i = 0; i < listRecord.size(); i++){

            Integer rowIndex = startIndex + i; // each chunk of record/batch run this method, startIndex tracks where the current index of chunk of record/batch
            Integer rowNum = rowIndex + 1; // +1 because it include column heder

            Map<String,String> mapObj = listRecord[i];
            Account seller =  mapSeller.get(mapObj.get(FLD_APINAME_BUSINESSNAME));
            String sellerId = seller?.Id;

            if(sellerId == null){ // throw when seller is not found.
                String errMsg = String.format(ERROR_TXT_SELLER_NOT_FOUND, new String[]{mapObj.get(FLD_APINAME_BUSINESSNAME), String.valueOf(rowNum)});
                mapIndexToErrMsg.put(rowIndex, errMsg); continue;
            }else{
                mapObj.put(FLD_APINAME_BUSINESSNAME, sellerId);
            }

            // auto-populate seller_contact__c 
            String sellerEmail = mapObj.get(FLD_APINAME_SELLEREMAIL);
            if(sellerId != null && String.isNotBlank(sellerEmail) && !mapAccEmailKeyToContactId.isEmpty()){
              
              Id sellerContId  = mapAccEmailKeyToContactId.get(sellerId + sellerEmail); // populate with contact in seller
              String sellerGroupId = seller.Seller_Portal_Group__c != null ? seller.Seller_Portal_Group__c : null;

              // if can not find contact in seller,then find contact in linked account
              sellerContId  = (sellerContId == null && String.isNotBlank(sellerGroupId)) ? mapAccEmailKeyToContactId.get(sellerGroupId + sellerEmail) : sellerContId;
              if(sellerContId != null){
                mapObj.put(FLD_APINAME_SELLERCONTACT, sellerContId);
              }  
            }

            for(String key : mapObj.keySet()){

                if(mapFNameToFType.containsKey(key)){

                    String fieldType = mapFNameToFType.get(key);

                    String strValue = mapObj.get(key);
                    strValue = strValue != null ? strValue : '';

                    if(String.isBlank(strValue.trim()) && SET_OPTIONAL_FIELD.contains(key)){ continue;}

                    if(String.isBlank(strValue) && setFldIsReq.contains(key)){ // throw when required field is blank
                        String errMsg = String.format(ERROR_TXT_REQUIRED_FIELD, new String[]{key, String.valueOf(rowNum), mapApiNameToLabel.get(key)});
                        mapIndexToErrMsg.put(rowIndex, errMsg);
                        continue;
                    }

                    Object dataValue;
                    try {
                        dataValue = getValueByType(fieldType, strValue, decimalPoint, dateSeperator);
                    }catch(Exception ex){ // throw when there is error when field is converted to its type.
                        String errMsg = String.format(ERROR_TXT_INCORRECT_FIELD_TYPE, new String[]{ex.getMessage(), String.valueOf(rowNum), mapApiNameToLabel.get(key)});
                        mapIndexToErrMsg.put(rowIndex, errMsg); continue;
                    }
                    
                    //MN-31082023-US-0013600
                    if (key == FLD_APINAME_DEALSTARTDATE || key == FLD_APINAME_DEALENDDATE) {

                      //Check if DealSite = IT => Start Date and End Date cannot blank.
                      String dealSiteId = mapObj.get(FLD_APINAME_DEALSITEID);
                      if ((dealSiteId == ApexUtil.MAP_COUNTRY_CODE.get('IT') || dealSiteId == ApexUtil.MAP_COUNTRY_CODE.get('101')) && String.isBlank(strValue)) {
                        String errMsg = String.format(ERROR_TXT_REQUIRED_FIELD, new String[]{key, String.valueOf(rowNum), mapApiNameToLabel.get(key)});
                        mapIndexToErrMsg.put(rowIndex, errMsg);
                        continue;
                      }

                    }

                    if(key == FLD_APINAME_SPOTLIGHTCATEGORY){
                        if(String.isNotBlank(strValue) && !mapSpotLight.containsKey(strValue.trim())){  // throw when spotlight category is not found.
                            String errMsg = String.format(ERROR_TXT_SLCATE_NOT_FOUND, new String[]{mapObj.get(FLD_APINAME_SPOTLIGHTCATEGORY), String.valueOf(rowNum), mapApiNameToLabel.get(key)});
                            mapIndexToErrMsg.put(rowIndex, errMsg); continue;
                        }
                        dataValue = mapSpotLight.get(strValue.trim());
                    }
                    
                    if(key == FLD_APINAME_DEALRETAILCAMPAIGN){
                      if(String.isNotBlank(strValue) && !mapDCR.containsKey(strValue.trim())){  // throw when spotlight category is not found.
                          String errMsg = String.format(ERROR_TXT_DRC_NOT_FOUND, new String[]{mapObj.get(FLD_APINAME_DEALRETAILCAMPAIGN), String.valueOf(rowNum), mapApiNameToLabel.get(key)});
                          mapIndexToErrMsg.put(rowIndex, errMsg); continue;
                      }
                      dataValue = mapDCR.get(strValue.trim());
                    }

                    if(key == FLD_APINAME_DEALFORMAT) dataValue = mDealFormat.containsKey(strValue) ? mDealFormat.get(strValue) : strValue;

                    mapObj.put(key, dataValue == null ? null : String.valueOf(dataValue));
                }

            }

            if(!mapIndexToErrMsg.containsKey(rowIndex)){  // proceed when there is no error.
                if(templateVersion==1) mapObj.put(FLD_APINAME_DEALPRICE, mapObj.get(FLD_APINAME_SELLERPRICE));
                String dealSiteId = mapObj.get(FLD_APINAME_DEALSITEID);
                if(String.isNotBlank(dealSiteId) && !dealSiteId.isNumeric()){

                    //MN-31082023-US-0013600
                    //mapObj.put(FLD_APINAME_DEALSITEID,  (ApexUtil.MAP_COUNTRY_CODE.containsKey(dealSiteId.toUpperCase()) ? ApexUtil.MAP_COUNTRY_CODE.get(dealSiteId.toUpperCase().toUpperCase()) : ApexUtil.MAP_COUNTRY_CODE.get(TXT_DE)));
                    dealSiteId = (ApexUtil.MAP_COUNTRY_CODE.containsKey(dealSiteId.toUpperCase()) ? ApexUtil.MAP_COUNTRY_CODE.get(dealSiteId.toUpperCase().toUpperCase()) : ApexUtil.MAP_COUNTRY_CODE.get(TXT_DE));
                    mapObj.put(FLD_APINAME_DEALSITEID, dealSiteId);
                    
                }else if(String.isBlank(dealSiteId)){
                    mapObj.put(FLD_APINAME_DEALSITEID, ApexUtil.MAP_COUNTRY_CODE.get(TXT_DE));
                }

                //MN-31082023-US-0013600: If Deal Site = IT => Set RecordType to Deal_V2 instead
                if (dealSiteId == ApexUtil.MAP_COUNTRY_CODE.get('IT')) {
                    mapObj.put(FLD_APINAME_DEALRECORDTYPEID, subDealRecordTypeId);
                }

                // SB 17.01.2024 US-0014528
                String productTitle = mapObj.get(FLD_APINAME_PRODUCTTITLE);
                if (String.isNotBlank(productTitle) && productTitle.length() > 255) {
                  mapObj.put(FLD_APINAME_PRODUCTTITLE, mapObj.get(FLD_APINAME_PRODUCTTITLE).substring(0, 255));
                }
            }

        }

        mapResult.put(TXT_STATUS,'ok');
        mapResult.put(TXT_LIST_RECORD,listRecord);
        mapResult.put(TXT_MAP_INDEX_TO_ERROR_MSG,mapIndexToErrMsg);
        return mapResult;
  
    }

    /*********************************************************************************************************************************
        @ Method:         importUnSubDealPreDML
        @ Version:        1.0
        @ Author:         SRONG TIN (srong.tin@gaea-sys.com)
        @ Purpose:        US-0013067 - Uploading Un-Sub Deals component, replace it with xl copy, paste feature
        ----------------------------------------------------------------------------------------------------------------------------------
        @ Change history:  06.02.2023 / SRONG TIN / Created the method.
        @                  06.06.2023 / Mony Nou / US-0013721 - SP - IT Deals UAT issue fixes
        @                  17.01.2024 / Sambath Seng / US-0014528 - NA Region (US) Increase character limit on Product title field
      *********************************************************************************************************************************/

    @testVisible
    private Map<String,Object> importUnSubDealPreDML(Map<String,Object> mapArgs){
  
          // method to validate and populate fields on deal records, this method run before deal records are uploaded.
          // some method that are called here are from exist method of parent class EBH_UploadDealController
  
          Map<String, Object> mapResult = new Map<String, Object>();
  
          List<Map<String,String>> listRecord = (List<Map<String,String>>)(JSON.deserialize(JSON.serialize(mapArgs.get(TXT_LIST_RECORD)), List<Map<String,String>>.class));
  
          Integer startIndex = Integer.valueOf(mapArgs.get(TXT_START_INDEX));
          String dealRetailCampaignId = String.valueOf(mapArgs.get('parentId'));
  
          String formattedValue = SAMPLE_DECIMAL_VALUE.format(); // example: value = 1000.10. User Locale DE,  it is formatted to 1000,10. User Locale EN, It is formatted to 1000.10
          String decimalPoint = formattedValue.substring(5,6); // get the decimal point from formatted price.
  
          String todayDateFormat = Date.today().format();
          todayDateFormat = todayDateFormat.replaceAll('[0-9]',''); // remove all numbers from string format of date
          String dateSeperator  = String.isNotEmpty(todayDateFormat) ? todayDateFormat.substring(0,1) : '/'; // example value = 01/02/2023, then the user locale date seperator is "/".
  
          Map<Integer, String> mapIndexToErrMsg = new  Map<Integer, String>();
          Set<String> setFldIsReq = new Set<String>();
          Map<String, String> mapApiNameToLabel = new  Map<String, String>();
  
          Map<String,Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(SOBJ_APINAME_DEAL).getDescribe().fields.getMap();
          for(SObjectField sobjField : mfields.values()){
              DescribeFieldResult descFldResult = sobjField.getDescribe();
              String fieldApiName = descFldResult.getName().toLowerCase();
              mapApiNameToLabel.put(fieldApiName, descFldResult.getLabel());
              if(SET_REQUIRED_FIELD.contains(fieldApiName) || (!SET_OPTIONAL_FIELD.contains(fieldApiName) && !descFldResult.isNillable())){setFldIsReq.add(fieldApiName);}  // store map of required field
          }
  
          Map<String,String> mapFNameToFType = new Map<String,String>();
          for(MappedField mappedField : mappedIndexColName_v2.values()){
              if(String.isNotBlank(mappedField.fieldName) && String.isNotBlank(mappedField.fieldType)){
                  mapFNameToFType.put(mappedField.fieldName.toLowerCase(), mappedField.fieldType);
              }
          }
  
          Set<String> setSeller = new Set<String>();
          Map<String,Account> mapSeller = new Map<String,Account>();

          //MN-06062023-US-0013721---START
          Set<String> setSellerContactName = new Set<String>();
          Map<String, String> mAccSellerContName = new Map<String, String>();
          Set<Id> setSellerId = new Set<Id>();
          Set<Id> setSellerGroupId = new Set<Id>();
          //END---MN-06062023-US-0013721

          //start SRONG TIN 09-July-2021 : upate deals record with value from Deal Retail Campaign US-0009650 (Deals RecordType NA Unsub Deal)
          List<EBH_DealRetailCampaign__c> drcLst = new List<EBH_DealRetailCampaign__c>();
          if(String.isNotBlank(dealRetailCampaignId)){

            drcLst = [SELECT Id,Name,EBH_Date__c,Start_Time__c,EPH_EndDate__c,End_Time__c,EBH_Country__c FROM EBH_DealRetailCampaign__c WHERE Id = :dealRetailCampaignId];
            
          }
          Id dealRecordTypeId =  ApexUtil.getRecordTypeByName(SOBJ_APINAME_DEAL, NA_Unsub_Deal).Id;
          for(Map<String,String> mapObj : listRecord){

              if(String.isNotBlank(dealRetailCampaignId) && !drcLst.isEmpty()){
                mapObj.put(FLD_APINAME_DEALRETAILCAMPAIGN, dealRetailCampaignId);
                mapObj.put(FLD_APINAME_DEALRECORDTYPEID, dealRecordTypeId);
                mapObj.put(FLD_APINAME_DEALSTARTDATE,String.valueOf(drcLst[0].EBH_Date__c));
                mapObj.put(FLD_APINAME_DEALSTARTTIME,String.valueOf(drcLst[0].Start_Time__c));
                mapObj.put(FLD_APINAME_DEALENDDATE,String.valueOf(drcLst[0].EPH_EndDate__c));
                mapObj.put(FLD_APINAME_DEALENDTIME,String.valueOf(drcLst[0].End_Time__c));
                mapObj.put(FLD_APINAME_STATUS,FLD_VALUE_STATUS);
                //SRONG TIN 21-July-2021
                mapObj.put(FLD_APINAME_RECOMMENDEDRETAILPRICEWAS,FLD_VALUE_RECOMMENDEDRETAILPRICEWAS);
                mapObj.put(FLD_APINAME_DEALSITEID,String.valueOf(drcLst[0].EBH_Country__c));
                //end SRONG : US-0009650 

                /* MN-14062023-US-0013721-Move this bit of logic into below line because we need to auto populate after validate the value
                //BR 09-01-2023-US-0013053
                //Check Deal Bulk Upload of Internal HIVE for NA & AU for Deal_V3 ONLY
                String dealPrice = String.valueOf(mapObj.get(FLD_APINAME_DEALPRICE));
                if(String.isNotBlank(dealPrice)){
                  // Assign Seller Price in Internal HIVE
                  mapObj.put(FLD_APINAME_SELLERPRICE, dealPrice);
                }
                */

              }
              String sellerName = mapObj.get(FLD_APINAME_BUSINESSNAME);
              if(String.isNotBlank(sellerName)) setSeller.add(sellerName);

              //MN-06062023-US-0013721
              String sellerContactName = mapObj.get(FLD_APINAME_SELLERCONTACT);
              if (String.isNotBlank(sellerContactName)) {
                
                List<String> lstTmp = sellerContactName.split(' '); //Since we cannot use Name field that has Middle Name value in it => we need to split and use LIKE instead
                String sellerContNameClause = lstTmp.get(0) + ((lstTmp.size() > 1)?'%'+lstTmp.get((lstTmp.size()-1)):'');
                setSellerContactName.add(sellerContNameClause);
                mAccSellerContName.put(sellerName, sellerContactName);

              }
              
              

          }
          
          for(Account es:[SELECT Id, Name, Seller_Portal_Group__c FROM Account WHERE RecordType.DeveloperName =: SELLER_RECORDTYPE AND Name IN:setSeller]) //BR-21-11-22-US-0012791
          {
            mapSeller.put(es.Name,es);
            
            //MN-06062023-US-0013721---START
            setSellerId.add(es.Id); //Store Seller Id to Find the Contact below
            if(es.Seller_Portal_Group__c != null) setSellerGroupId.add(es.Seller_Portal_Group__c); // store group id when seller is in linked account in order to find contact in linked account
            //END---MN-06062023-US-0013721
          
          }
          //MN-06062023-US-0013721---START
          // find contact by email and seller id
          Map<String, Id> mapAccContNameKeyToContactId = new Map<String,Id> ();
          if(!setSellerContactName.isEmpty()) {

              for(Contact cont : [Select Email, Name, AccountId, Account.Name From Contact Where Name LIKE:setSellerContactName AND AccountId IN : setSellerId]){
                String accContNameKey = cont.AccountId + cont.Name;
                //1ST CLAUSE: For new entry; 2nd CLAUSE: In case there are multiple Contacts Founds, then we will choose the Contact that has Name == value in Seller Contact Column
                if(!mapAccContNameKeyToContactId.containsKey(accContNameKey) || (mAccSellerContName.containsKey(cont.Account.Name) && mAccSellerContName.get(cont.Account.Name) == cont.Name)) {
                  mapAccContNameKeyToContactId.put(accContNameKey, cont.Id);
                }
              }
      
              // find contact by email and seller in linked account 
              if(!setSellerGroupId.isEmpty()){
                for(AccountContactRelation acr : [Select AccountId,Account.Name, ContactId, Contact.Name, Contact.Email From AccountContactRelation Where Contact.Name IN : setSellerContactName AND AccountId IN: setSellerGroupId]){
                  String accContNameKey = acr.AccountId + acr.Contact.Name;
                  
                  //1ST CLAUSE: For new entry; 2nd CLAUSE: In case there are multiple Contacts Founds, then we will choose the Contact that has Name == value in Seller Contact Column
                  if(!mapAccContNameKeyToContactId.containsKey(accContNameKey) || (mAccSellerContName.containsKey(acr.Account.Name) && mAccSellerContName.get(acr.Account.Name) == acr.Contact.Name)) {
                    mapAccContNameKeyToContactId.put(accContNameKey, acr.ContactId);
                  }
                  
                }
              }
              
          }
          //END---MN-06062023-US-0013721

          for(Integer i = 0; i < listRecord.size(); i++){
  
              Integer rowIndex = startIndex + i; // each chunk of record/batch run this method, startIndex tracks where the current index of chunk of record/batch
              Integer rowNum = rowIndex + 1; // +1 because it include column heder
  
              Map<String,String> mapObj = listRecord[i];
              Account seller =  mapSeller.get(mapObj.get(FLD_APINAME_BUSINESSNAME));
              String sellerId = seller?.Id;
  
              if(sellerId == null){ // throw when seller is not found.
                  String errMsg = String.format(ERROR_TXT_SELLER_NOT_FOUND, new String[]{mapObj.get(FLD_APINAME_BUSINESSNAME), String.valueOf(rowNum)});
                  mapIndexToErrMsg.put(rowIndex, errMsg); continue;
              }else{
                  mapObj.put(FLD_APINAME_BUSINESSNAME, sellerId);
              }

              //MN-06062023-US-0013721---START - Auto populated Seller_Contact__c field
              String sellerContactName = mapObj.get(FLD_APINAME_SELLERCONTACT);
              if(String.isNotBlank(sellerId) && String.isNotBlank(sellerContactName)){
              
                String accContNameKey = sellerId + sellerContactName;

                Id sellerContId;
                
                if (mapAccContNameKeyToContactId.containsKey(accContNameKey)) sellerContId = mapAccContNameKeyToContactId.get(accContNameKey); // populate with contact in seller

                // if can not find contact in seller,then find contact in linked account
                if (String.isBlank(sellerContId)) {

                  String sellerGroupId = seller.Seller_Portal_Group__c;
                  accContNameKey = sellerGroupId + sellerContactName;

                  if (String.isNotBlank(sellerGroupId) && mapAccContNameKeyToContactId.containsKey(accContNameKey)) sellerContId = mapAccContNameKeyToContactId.get(accContNameKey);
                  
                }
                
                if(sellerContId == null){ // throw when seller contact is not found.
                    String errMsg = String.format(ERROR_TXT_SELLERCONTACT_NOT_FOUND, new String[]{mapObj.get(FLD_APINAME_SELLERCONTACT), String.valueOf(rowNum)});
                    mapIndexToErrMsg.put(rowIndex, errMsg); continue;
                }else{
                  mapObj.put(FLD_APINAME_SELLERCONTACT, sellerContId);
                }

                //if (String.isNotBlank(sellerContId)) mapObj.put(FLD_APINAME_SELLERCONTACT, sellerContId);
                
              }
              //END---MN-06062023-US-0013721

              for(String key : mapObj.keySet()){
  
                  if(mapFNameToFType.containsKey(key)){
  
                      String fieldType = mapFNameToFType.get(key);
  
                      String strValue = mapObj.get(key);
                      strValue = strValue != null ? strValue : '';
  
                      if(String.isBlank(strValue.trim()) && SET_OPTIONAL_FIELD.contains(key)){ continue;}
  
                      if(String.isBlank(strValue) && setFldIsReq.contains(key)){ // throw when required field is blank
                          String errMsg = String.format(ERROR_TXT_REQUIRED_FIELD, new String[]{key, String.valueOf(rowNum), mapApiNameToLabel.get(key)});
                          mapIndexToErrMsg.put(rowIndex, errMsg);
                          continue;
                      }
  
                      Object dataValue;
                      try {
                          dataValue = getValueByType(fieldType, strValue, decimalPoint, dateSeperator);

                          
                      }catch(Exception ex){ // throw when there is error when field is converted to its type.
                          String errMsg = String.format(ERROR_TXT_INCORRECT_FIELD_TYPE, new String[]{ex.getMessage(), String.valueOf(rowNum), mapApiNameToLabel.get(key)});
                          mapIndexToErrMsg.put(rowIndex, errMsg); continue;
                      }

                      mapObj.put(key, dataValue == null ? null : String.valueOf(dataValue));

                      //MN-14062023-US-0013721: Move logic from above to here so that we can auto populuate value after value is validated
                      //US-0013053: Check Deal Bulk Upload of Internal HIVE for NA & AU for Deal_V3 ONLY
                      if (key == FLD_APINAME_DEALPRICE && dataValue != null) {
                          // Assign Seller Price in Internal HIVE
                          mapObj.put(FLD_APINAME_SELLERPRICE, String.valueOf(dataValue));
                      }

                      // SB 17.01.2024 US-0014528
                      String productTitle = mapObj.get(FLD_APINAME_PRODUCTTITLE);
                      if (String.isNotBlank(productTitle) && productTitle.length() > 255) {
                        mapObj.put(FLD_APINAME_PRODUCTTITLE, mapObj.get(FLD_APINAME_PRODUCTTITLE).substring(0, 255));
                      }
                  }
  
              }
  
          }
          mapResult.put(TXT_STATUS,'ok');
          mapResult.put(TXT_LIST_RECORD,listRecord);
          mapResult.put(TXT_MAP_INDEX_TO_ERROR_MSG,mapIndexToErrMsg);
          return mapResult;
    
    }

    /*********************************************************************************************************************************
    @ Method:         importSubDealPreDML
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0013554 - Deal (V2) Upload functionality to be replaced with Copy paste feature
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.10.2023 / Sambath Seng / Created the method.
    @                 17.01.2024 / Sambath Seng / US-0014528 - NA Region (US) Increase character limit on Product title field
    @                 25.02.2024 / Mony Nou / US-0014653 - Mark fields as optional as part of the deal upload copy and past functionality for V2
    @                 25.01.2024 / LoumAng SENG / US-0014680 - Update field level mapping for List Price to map to RRP/WAS price on copy and paste functionality for Deal V2
    @                 15.01.2025 / vadhanak voun / US-0016265 - (2) Upload Sub Deals in Hive. moved to sub-class SubDealPreDML
    *********************************************************************************************************************************/
    @testVisible
    private Map<String,Object> importSubDealPreDML(Map<String,Object> mapArgs){
        
        preDealDML.setMapArg(mapArgs);
      
        return preDealDML.doPreDML();
  
    }

    IPreDML preDealDML;

  /*********************************************************************************************************************************
  @ Method:         call
  @ Version:        1.0
  @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
  @ Purpose:        US-0012119 - Standard Deal (V1) Upload functionality - Extend excel copy paste feature
  ----------------------------------------------------------------------------------------------------------------------------------
  @ Change history:  12.12.2022 / Sophal Noch / Created the method.
  *********************************************************************************************************************************/
    public Object call(String action, Map<String, Object> args) {
      // when class is implemented Callable, method "call" must also be implement.
      // 06.02.2023 / SRONG TIN / US-0013067
      if(action == TXT_IMPORT_DEAL_PRE_DML) { return this.importDealPreDML(args);}
      else if(action == TXT_IMPORT_UN_SUB_DEAL_PRE_DML) { return this.importUnSubDealPreDML(args);}
      else if(action == TXT_IMPORT_SUB_DEAL_PRE_DML) {preDealDML = new SubDealPreDML(); return this.importSubDealPreDML(args);} //SB,NK:14/01/2025:US-0016265
      else if(action == TXT_IMPORT_SUB_DEAL_PRE_DMLDCA) {preDealDML = new SubDealPreDMLFromDCA(); return this.importSubDealPreDML(args);} //NK:14/01/2025:US-0016265
      else if(action == TXT_IMPORT_SUB_DEAL_PRE_DMLDCA_RELATED_LIST) {preDealDML = new SubDealPreDMLFromDCARelatedList(); return this.importSubDealPreDML(args);} //VM:16/01/2025:US-0016530
      else{throw new CallableClassException(TXT_METHOD_NOT_IMPLEMENTED);}
    }
  }
  private class CallableClassException extends Exception {}
   

  interface IPreDML{
		void setMapArg(Map<String, Object> args);
		Map<String, Object> doPreDML(); 
	 
	}

  virtual class SubDealPreDML implements IPreDML{
    protected Map<String, Object> mapResult;
    protected List<Map<String,String>> listRecord;
    protected Map<String,Object> mapArgs;
    protected Map<Integer, String> mapIndexToErrMsg;
    protected Set<String> setFldIsReq;
    protected Map<String, String> mapApiNameToLabel;
    protected Map<String,String> mapFNameToFType;
    protected Set<String> setSeller;
    protected List<String> lstApproverEmails;
    protected Set<Id> setSellerGroupId;
    protected Set<Id> setSellerId;
    protected Map<String, Id> mapAccEmailKeyToContactId;
    protected Boolean useUserLocalDF = false;
    public SubDealPreDML()
    {
    }
    
    public void setMapArg(Map<String,Object> mapArgs)
    {
      this.mapArgs= mapArgs;
    }
    
    protected virtual void addPreData(){} //to be overriden
    protected virtual Boolean additionalValidate(Integer rowIndex,String fieldName,Map<String,String> mapObj){return true;}//to be overriden
    
    protected List<Contact> queryRelatedContacts()
    {
      return [Select Id, Email, AccountId From Contact Where RecordType.DeveloperName IN(:CONTACT_DWH_RECORDTYPE,:CONTACT_MANUAL_RECORDTYPE) AND Email IN: lstApproverEmails AND AccountId IN : setSellerId];
    }
    protected List<AccountContactRelation> queryRelatedAccountContactRelations()
    {
      return [Select Id, AccountId, ContactId, Contact.Email From AccountContactRelation Where Contact.RecordType.DeveloperName IN (:CONTACT_DWH_RECORDTYPE,:CONTACT_MANUAL_RECORDTYPE) AND Contact.Email IN : lstApproverEmails AND AccountId IN: setSellerGroupId];
    }

    protected virtual void mapAccountContactEmail()
    {      
      mapAccEmailKeyToContactId = new Map<String,Id> ();
      if(!lstApproverEmails.isEmpty()){
        doMapAccEmail();
      }
    }
    protected void doMapAccEmail()
    {
      for(Contact oCon : queryRelatedContacts()){
        String accEmailKey = oCon.AccountId + oCon.Email;
        if(!mapAccEmailKeyToContactId.containsKey(accEmailKey)) mapAccEmailKeyToContactId.put(accEmailKey, oCon.Id);
      }

      // find contact by email and seller in linked account 
      if(!setSellerGroupId.isEmpty()){
        for(AccountContactRelation oAcr : queryRelatedAccountContactRelations()){
          String accEmailKey = oAcr.AccountId + oAcr.Contact.Email;
          if(!mapAccEmailKeyToContactId.containsKey(accEmailKey)) mapAccEmailKeyToContactId.put(accEmailKey, oAcr.ContactId);
        }
      }
    }
    protected virtual void validateApprovers(Integer rowIndex,Map<String,String> mapObj,String sellerId,Account seller)
    {
        if(sellerId != null && !mapAccEmailKeyToContactId.isEmpty()){ 
          List<String> lstTempEmail = new List<String>();
          for(Integer j = 1; j <= 5; j++){
            String sellerApproverEmail = mapObj.get(FLD_APINAME_SELLERAPPROVER + j + '__c');
            if(sellerApproverEmail != null){
              lstTempEmail.add(sellerApproverEmail);
              Id sellerApproverContId = mapAccEmailKeyToContactId.get(sellerId + sellerApproverEmail);
              String sellerGroupId = seller.Seller_Portal_Group__c != null ? seller.Seller_Portal_Group__c : null;
              // if can not find contact in seller,then find contact in linked account
              sellerApproverContId  = (sellerApproverContId == null && String.isNotBlank(sellerGroupId)) ? mapAccEmailKeyToContactId.get(sellerGroupId + sellerApproverEmail) : sellerApproverContId;
              if(sellerApproverContId != null){
                mapObj.put(FLD_APINAME_SELLERAPPROVER + j + '__c', sellerApproverContId);
              } else {
                String errMsg = String.format(ERROR_TXT_INVALID_SELLER_APPROVER, new String[]{sellerApproverEmail,FLD_APINAME_SELLERAPPROVER + j});
                mapIndexToErrMsg.put(rowIndex, errMsg); 
              }
            }
          }
        } else {
          String errMsg = ERROR_TXT_REQUIRED_SELLER_APPROVER;
          mapIndexToErrMsg.put(rowIndex, errMsg);
        }
    }

    public Map<String, Object> doPreDML()
    {
      mapResult = new Map<String, Object>();
  
          listRecord = (List<Map<String,String>>)(JSON.deserialize(JSON.serialize(mapArgs.get(TXT_LIST_RECORD)), List<Map<String,String>>.class));
  
          Integer startIndex = Integer.valueOf(mapArgs.get(TXT_START_INDEX));
  
          String formattedValue = SAMPLE_DECIMAL_VALUE.format(); // example: value = 1000.10. User Locale DE,  it is formatted to 1000,10. User Locale EN, It is formatted to 1000.10
          String decimalPoint = formattedValue.substring(5,6); // get the decimal point from formatted price.
  
          String todayDateFormat = Date.today().format();
          todayDateFormat = todayDateFormat.replaceAll('[0-9]',''); // remove all numbers from string format of date
          String dateSeperator  = String.isNotEmpty(todayDateFormat) ? todayDateFormat.substring(0,1) : '/'; // example value = 01/02/2023, then the user locale date seperator is "/".
  
          mapIndexToErrMsg = new Map<Integer, String>();
          setFldIsReq = new Set<String>();
          mapApiNameToLabel = new  Map<String, String>();
          mapFNameToFType = new Map<String,String>();
          Map<String,Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(SOBJ_APINAME_DEAL).getDescribe().fields.getMap();
      
      //override to add action
      addPreData();
      
          for(SObjectField sobjField : mfields.values()){
              DescribeFieldResult descFldResult = sobjField.getDescribe();
              String fieldApiName = descFldResult.getName().toLowerCase();
              mapApiNameToLabel.put(fieldApiName, descFldResult.getLabel());
              if(SET_REQUIRED_FIELD.contains(fieldApiName) || (!SET_OPTIONAL_FIELD.contains(fieldApiName) && !descFldResult.isNillable())){setFldIsReq.add(fieldApiName);}  // store map of required field
          }
  
          for(MappedField mappedField : mappedIndexColName_v2.values()){
              if(String.isNotBlank(mappedField.fieldName) && String.isNotBlank(mappedField.fieldType)){
                  mapFNameToFType.put(mappedField.fieldName.toLowerCase(), mappedField.fieldType);
              }
          }
  
          // Get dependency vertical and category
          Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDepVertical  = ApexUtil.getDependentMap(EBH_Deal__c.getSObjectType(),'EBH_DealSiteId__c','EBH_Vertical__c');
          Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDepCategory  = ApexUtil.getDependentMap(EBH_Deal__c.getSObjectType(),'EBH_DealSiteId__c','EBH_Category__c');
          Set<String> sdepVertical = checkDependency(pklDepVertical);
          Set<String> sdepCategory = checkDependency(pklDepCategory);
  
          setSeller = new Set<String>();
          Map<String,Account> mapSeller = new Map<String,Account>();
          lstApproverEmails = new List<String>();
          
          for(Map<String,String> mapObj : listRecord){
            String sellerName = mapObj.get(FLD_APINAME_BUSINESSNAME);
            if(String.isNotBlank(sellerName)) setSeller.add(sellerName);
  
            for (Integer i = 1; i <= 5; i++) {
              String sellerApproverEmail = mapObj.get(FLD_APINAME_SELLERAPPROVER + i + '__c');
              if (sellerApproverEmail != null && !lstApproverEmails.contains(sellerApproverEmail)) {
                lstApproverEmails.add(sellerApproverEmail);
              }
            }
          }
          
          setSellerId = new Set<Id>();
          setSellerGroupId = new Set<Id>();
          for(Account oSeller : [SELECT Id, Name, Seller_Portal_Group__c FROM Account WHERE RecordType.DeveloperName =: SELLER_RECORDTYPE AND Name IN:setSeller])
          {
            mapSeller.put(oSeller.Name,oSeller);
            setSellerId.add(oSeller.Id); // store seller id to find contact below
            if(oSeller.Seller_Portal_Group__c != null){ 
              setSellerGroupId.add(oSeller.Seller_Portal_Group__c); // store group id when seller is in linked account in order to find contact in linked account
            }
          }
  
          // find contact by email and seller id
          mapAccountContactEmail();

         
          
          for(Integer i = 0; i < listRecord.size(); i++){
            
            Integer rowIndex = startIndex + i; // each chunk of record/batch run this method, startIndex tracks where the current index of chunk of record/batch
            Integer rowNum = rowIndex + 1; // +1 because it include column heder
  
            Map<String,String> mapObj = listRecord[i];
            Account seller = mapSeller.get(mapObj.get(FLD_APINAME_BUSINESSNAME));
            String sellerId = seller?.Id;
            
            if(sellerId == null){ // throw when seller is not found.
                String errMsg = String.format(ERROR_TXT_SELLER_NOT_FOUND, new String[]{mapObj.get(FLD_APINAME_BUSINESSNAME), String.valueOf(rowNum)});
                mapIndexToErrMsg.put(rowIndex, errMsg); continue;
            }else{
                mapObj.put(FLD_APINAME_BUSINESSNAME, sellerId);
            }
  
            Id subDealRecordTypeId =  ApexUtil.getRecordTypeByName(SOBJ_APINAME_DEAL, SUBSIDISED_DEAL).Id;
  
            mapObj.put(FLD_APINAME_DEALRECORDTYPEID, subDealRecordTypeId);
            //LA-25-01-2024-US-0014680: Change mapping from List Price to RRP/Was Price(EBH_RRPWASPrice__c)
            //String listPrice = String.isNotBlank(mapObj.get(FLD_APINAME_LISTPRICE)) ? mapObj.get(FLD_APINAME_LISTPRICE) : '';
            String listPrice = String.isNotBlank(mapObj.get(FLD_APINAME_RRPWASPRICE)) ? mapObj.get(FLD_APINAME_RRPWASPRICE) : '';
            if(String.isNotBlank(listPrice)){
              //LA-25-01-2024-US-0014680
              //mapObj.put(FLD_APINAME_LISTPRICE, listPrice.replaceAll('[^0-9.]', ''));
              mapObj.put(FLD_APINAME_RRPWASPRICE, listPrice.replaceAll('[^0-9.]', ''));
            }
  
            // auto-populate seller_approver            
             validateApprovers(rowIndex, mapObj, sellerId,seller);          
  
            for(String key : mapObj.keySet()){
              
              if(mapFNameToFType.containsKey(key)){
                String fieldType = mapFNameToFType.get(key);
                String strValue = mapObj.get(key);
                strValue = strValue != null ? strValue : '';
                
                if(String.isBlank(strValue) && setFldIsReq.contains(key)){ // throw when required field is blank
                  String errMsg = String.format(ERROR_TXT_REQUIRED_FIELD, new String[]{key, String.valueOf(rowNum), mapApiNameToLabel.get(key)});
                  mapIndexToErrMsg.put(rowIndex, errMsg);
                  continue;
                }
  
                if (key == FLD_APINAME_EBAYITEMID) {
                  if(String.isBlank(strValue) && (!strValue.isNumeric() || strValue.length() != 12)){
                    String errMsg = ERROR_TXT_INVALID_LISTING_ID;
                    mapIndexToErrMsg.put(rowIndex, errMsg);
                    continue;                
                  }
                }
                
                Object dataValue;
                try {
                    dataValue = doGetValueByType(fieldType, strValue, decimalPoint, dateSeperator,useUserLocalDF);
                    
                }catch(Exception ex){ // throw when there is error when field is converted to its type.
                    String errMsg = String.format(ERROR_TXT_INCORRECT_FIELD_TYPE, new String[]{ex.getMessage(), String.valueOf(rowNum), mapApiNameToLabel.get(key)});
                    mapIndexToErrMsg.put(rowIndex, errMsg); continue;
                }
  
                if (key == FLD_APINAME_VERTICAL) {
                  String dealSiteApi = MAP_SITE_CODE.get(mapObj.get(FLD_APINAME_DEALSITEID));
                  if(!String.isBlank(strValue) && sdepVertical != null && !sdepVertical.contains(dealSiteApi + '_'+ strValue)){
                    String errMsg = String.format(ERROR_TXT_INVALID_VERTICAL, new String[]{strValue});
                    mapIndexToErrMsg.put(rowIndex, errMsg);
                    continue;
                  }
                }
  
                if (key == FLD_APINAME_CATEGORY) {
                  String dealSiteApi = MAP_SITE_CODE.get(mapObj.get(FLD_APINAME_DEALSITEID));
                  if(!String.isBlank(strValue) && sdepVertical != null && !sdepCategory.contains(dealSiteApi + '_'+ strValue)){
                    String errMsg = String.format(ERROR_TXT_INVALID_CATEGORY, new String[]{strValue});
                    mapIndexToErrMsg.put(rowIndex, errMsg);
                    continue;
                  }
                }
  
                if (key == FLD_APINAME_DEALPRICE){
                  Decimal dealPrice = mapObj.get(FLD_APINAME_DEALPRICE) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_DEALPRICE)) : null;
                  Decimal sellerPrice = mapObj.get(FLD_APINAME_SELLERPRICE) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_SELLERPRICE)) : null;
                  if(dealPrice != null && sellerPrice != null && dealPrice > sellerPrice){
                    String errMsg = ERROR_TXT_DEALPRICE_LESS_THAN_SELLERPRICE;
                    mapIndexToErrMsg.put(rowIndex, errMsg);
                    continue;
                  }
                }
  
                /* //MN-25012024-0014653: All Seller and Deal Price Multi SKU columns are no longer required
                if(key == FLD_APINAME_SELLERSDEALMSKULOWER || key == FLD_APINAME_SELLERSDEALMSKUUPPER || key == FLD_APINAME_SELLERSOFFERMSKULOWER || key == FLD_APINAME_SELLERSOFFERMSKUUPPER){
                  if(String.isBlank(strValue)){
                    String errMsg = ERROR_TXT_REQUIRED_ALL_MSKU;
                    mapIndexToErrMsg.put(rowIndex, errMsg);
                    continue;
                  }
                }
                */
                //TH:US-0025958
                Boolean isValueValid = additionalValidate(rowIndex,key, mapObj);
                if(!isValueValid){
                  continue;
                }
                if(key == FLD_APINAME_SELLERSDEALMSKUUPPER || key == FLD_APINAME_SELLERSOFFERMSKUUPPER || key == FLD_APINAME_LISTPRICEMSKUUPPER){
                  Decimal sellersDealMSKULower = mapObj.get(FLD_APINAME_SELLERSDEALMSKULOWER) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_SELLERSDEALMSKULOWER)) : null;
                  Decimal sellersDealMSKUUpper = mapObj.get(FLD_APINAME_SELLERSDEALMSKUUPPER) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_SELLERSDEALMSKUUPPER)) : null;
                  Decimal sellersOfferMSKULower = mapObj.get(FLD_APINAME_SELLERSOFFERMSKULOWER) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_SELLERSOFFERMSKULOWER)) : null;
                  Decimal sellersOfferMSKUUpper = mapObj.get(FLD_APINAME_SELLERSOFFERMSKUUPPER) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_SELLERSOFFERMSKUUPPER)) : null;
                  Decimal listPriceMSKULower = mapObj.get(FLD_APINAME_LISTPRICEMSKULOWER) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_LISTPRICEMSKULOWER)) : null;
                  Decimal listPriceMSKUUpper = mapObj.get(FLD_APINAME_LISTPRICEMSKUUPPER) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_LISTPRICEMSKUUPPER)) : null;
                  if ((sellersDealMSKULower != null && sellersDealMSKUUpper != null && sellersDealMSKULower > sellersDealMSKUUpper) || (sellersOfferMSKULower != null && sellersOfferMSKUUpper != null && sellersOfferMSKULower > sellersOfferMSKUUpper) || (listPriceMSKULower != null && listPriceMSKUUpper != null && listPriceMSKULower > listPriceMSKUUpper)){
                    String errMsg = ERROR_TXT_LESS_UPPER_SKU;
                    mapIndexToErrMsg.put(rowIndex, errMsg);
                    continue;
                  }
                }
                
                if(key == FLD_APINAME_DEALFORMAT) dataValue = mDealFormat.containsKey(strValue) ? mDealFormat.get(strValue) : strValue;
  
                mapObj.put(key, dataValue == null ? null : String.valueOf(dataValue));
              }
            }
  
            if(!mapIndexToErrMsg.containsKey(rowIndex)){  // proceed when there is no error.
              String dealSiteId = mapObj.get(FLD_APINAME_DEALSITEID);
              
              if(String.isNotBlank(dealSiteId) && !dealSiteId.isNumeric()){
  
                  dealSiteId = (MAP_SITE_CODE.containsKey(dealSiteId.toUpperCase()) ? MAP_SITE_CODE.get(dealSiteId.toUpperCase().toUpperCase()) : MAP_SITE_CODE.get(dealSiteId));
                  mapObj.put(FLD_APINAME_DEALSITEID, dealSiteId);
                  
              }else if(String.isBlank(dealSiteId)){
                  mapObj.put(FLD_APINAME_DEALSITEID, MAP_SITE_CODE.get(dealSiteId));
              }
  
              // SB 17.01.2024 US-0014528
              String productTitle = mapObj.get(FLD_APINAME_PRODUCTTITLE);
              if (String.isNotBlank(productTitle) && productTitle.length() > 255) { mapObj.put(FLD_APINAME_PRODUCTTITLE, mapObj.get(FLD_APINAME_PRODUCTTITLE).substring(0, 255)); }
  
              //MN-25012024-0014653: AC1-If bLank should default to user performing the upload
              String ownerId = mapObj.get(FLD_APINAME_OWNERID);
              if (String.isBlank(ownerId)) { mapObj.put(FLD_APINAME_OWNERID, UserInfo.getUserId()); }
  
            }
          }
  
          mapResult.put(TXT_STATUS,'ok');
          mapResult.put(TXT_LIST_RECORD,listRecord);
          mapResult.put(TXT_MAP_INDEX_TO_ERROR_MSG,mapIndexToErrMsg);
          return mapResult;		
      }
    
    }
    //end of class SubDealPreDML
      /*=======================================================================================================================================================================
       @change history:  31/03/2025 / Vimean Heng / US-0016745 - Deals upload and Management - Testing Feedback
       @              :  09/05/2025 / Sovantheany Dim / US-0025958 - Launch - PROD E2E testing feedback
      =======================================================================================================================================================================*/
    class SubDealPreDMLFromDCA extends SubDealPreDML{
	
      public SubDealPreDMLFromDCA(){
        useUserLocalDF = true;
      }      
      protected override void addPreData()
      {
        String dcaId = (String)mapArgs.get('parentId');
        String soqlDCA = 'SELECT Id, Category__c,Vertical__c,eBay_Seller__c,eBay_Seller__r.Name,eBay_Seller__r.Seller_Portal_Group__c ,Deal_Site__c FROM Deal_Contract_Agreement__c WHERE Id = :dcaId';
        List<Deal_Contract_Agreement__c> dca = ( List<Deal_Contract_Agreement__c>)ApexSafe.query().secCheck(false).doQuery(soqlDCA, new Map<String,Object>{'dcaId' => dcaId});
        String sellerId = dca[0].eBay_Seller__c;       

        for(Map<String,String> mapObj : listRecord)
        {          
            mapObj.put(FLD_APINAME_BUSINESSNAME,dca[0].eBay_Seller__r.Name);
            mapObj.put('EBH_DealSiteId__c',dca[0].Deal_Site__c);
            mapObj.put('EBH_Vertical__c',dca[0].Vertical__c);
            mapObj.put('EBH_Category__c',dca[0].Category__c);
            mapObj.put('Deal_Contract_Agreement__c',dcaId);     
            mapObj.put('RecordTypeId',ApexUtil.getRecordTypeByName(SOBJ_APINAME_DEAL, SUBSIDISED_DEAL).Id);   
            mapObj.put('EBH_Status__c','New');            
            mapObj.put('Uploaded_By_DCA__c','true');     
              
        }

          //system.debug('-----:'+super.mapArgs);
      }
      protected override void validateApprovers(Integer rowIndex,Map<String,String> mapObj,String sellerId,Account seller)
      {

      }
      //TH:US-0025958 - additional validation rule for DCA upload
      protected override Boolean additionalValidate(Integer rowIndex,String key,Map<String,String> mapObj){
        if (key == FLD_APINAME_DEALPRICE){
          Decimal dealPrice = mapObj.get(FLD_APINAME_DEALPRICE) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_DEALPRICE)) : null;
          if(dealPrice != null && dealPrice <= 0){
            String errMsg = system.label.dealBulkUploadDCASub_Error_LP_SP_DP_Negative_Null;
            mapIndexToErrMsg.put(rowIndex, errMsg);
            return false;
          }
        }
        if (key == FLD_APINAME_SELLERPRICE){
          Decimal sellerPrice = mapObj.get(FLD_APINAME_SELLERPRICE) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_SELLERPRICE)) : null;
          if(sellerPrice != null && sellerPrice <= 0){
            String errMsg = system.label.dealBulkUploadDCASub_Error_LP_SP_DP_Negative_Null;
            mapIndexToErrMsg.put(rowIndex, errMsg);
            return false;
          }
        }
        if (key == FLD_APINAME_RRPWASPRICE){
          Decimal dealPrice = mapObj.get(FLD_APINAME_DEALPRICE) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_DEALPRICE)) : null;
          Decimal listPrice = mapObj.get(FLD_APINAME_RRPWASPRICE) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_RRPWASPRICE)) : null;
          if(listPrice != null && listPrice <= 0){
            String errMsg = system.label.dealBulkUploadDCASub_Error_LP_SP_DP_Negative_Null;
            mapIndexToErrMsg.put(rowIndex, errMsg);
            return false;
          }else if(dealPrice != null && listPrice != null && listPrice < dealPrice){
            String errMsg = system.label.dealBulkUploadDCASub_Error_ListPriceLessThanDeal;
            mapIndexToErrMsg.put(rowIndex, errMsg);
            return false;
          }
        }
        if (key == FLD_APINAME_QUANTITY){
          Decimal quantity = mapObj.get(FLD_APINAME_QUANTITY) != null ? Decimal.valueOf(mapObj.get(FLD_APINAME_QUANTITY)) : null;
          if(quantity != null && quantity <= 0){
            String errMsg = system.label.dealBulkUploadDCASub_Error_QTY_Negative_Null;
            mapIndexToErrMsg.put(rowIndex, errMsg);
            return false;
          }
        }
        return true;
      }

    }
       //end of class SubDealPreDMLFromDCA
       /*=======================================================================================================================================================================
       @change history:  15/1/2025 / Vimean Heng / US-0016530 - (3.1) Deals Import from Deal Contract Agreement
       @change history:  31/1/2025 / Vimean Heng / US-0016639 - Testing Feedback fixes - Deals - Sprint 117
        =======================================================================================================================================================================*/
    class SubDealPreDMLFromDCARelatedList extends SubDealPreDML{
      public SubDealPreDMLFromDCARelatedList(){
        useUserLocalDF = true;
      }      
      protected override void validateApprovers(Integer rowIndex,Map<String,String> mapObj,String sellerId,Account seller)
      {
            if(mapObj.get('ebh_status__c') != 'New' && mapObj.get('ebh_status__c') != 'Internally Rejected'){
              //errMsg will be provided by Amruntha
              //String errMsg = 'Deals of only status = "New" and "Internally Rejected" can be updated';
              String errMsg = String.format(ERROR_TXT_INCORRECT_FIELD_TYPE, new String[]{'Incorrect Value', String.valueOf(rowIndex+1), mapApiNameToLabel.get('ebh_status__c')});
              mapIndexToErrMsg.put(rowIndex, errMsg);
            }
      }
      protected override void addPreData()
        {
          String dcaId = (String)mapArgs.get('parentId');
          Map<String,Map<String,String>> mapObjAddData = new Map<String,Map<String,String>>();
          for(Map<String,String> mapObj : listRecord){
            mapObjAddData.put(mapObj.get('name'),mapObj);
          }
          String soqlDeal = 'SELECT Id,Name,EBH_Status__c from EBH_Deal__c WHERE Name IN :dealNames AND Deal_Contract_Agreement__c = :dcaId';
          List<EBH_Deal__c> lsDeal = (List<EBH_Deal__c>)ApexSafe.query().secCheck(false).doQuery(soqlDeal, new Map<String,Object>{'dealNames'=>mapObjAddData.keySet(),'dcaId'=>dcaId});
          for(EBH_Deal__c deal : lsDeal){
            mapObjAddData.get(deal.Name).put('Id',deal.Id);
          } 
        }
    
    }
    //end of class SubDealPreDMLFromDCARelatedList
}