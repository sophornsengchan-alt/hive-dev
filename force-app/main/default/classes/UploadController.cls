/*********************************************************************************************************************************
@ Class:          UploadController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Controller for aura: Uploader (CouponItemUploader)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.04.2019 / Vadhanak Voun / Created the class.
********************************************************************************************************************************
@ Change history: 18.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / add method apexImportManagedPaymentProject. 
********************************************************************************************************************************
@ Change history: 31.08.202! / Mony Nou (mony.nou@gaea-sys.com) / US-0009948 - remove field Email_Adress__c from query string line 28
@ Change history : 05/11/2021 /Sovantheany Dim / US-0010212 - Coupon Seller: Validation rule Rev. roll up vs coupon main site
@ Change history : 05/11/2021 /Sovantheany Dim / US-0010617 - DE POP COUPON contract renewal: adding existing sellers to a promo
@ Change history : 10/06/2022 /Bora Chhorn / US-0011862 - Prevent and warn users from adding more than 10.000 Nominated Items to FVF
@ Change history : 29/06/2022 /Mony Nou / US-0011760 - Bulk upload enhancements for Coupons
@ Change history : 30.06.2022 / Sambath Seng / US-0011998 - Business Feedback Focus 75 AC1
@ Change history : 31.08.2022 / Bora Chhorn / US-0012305 - [DE Launch] Deploy missing ACs from US-0011998
@ Change history : 19.09.2022 / Mony Nou / US-0010910 - Amend Bulk Upload Logic to ignore Coupon Item Object
@ Change history : 03.11.2022 / Bora Chhorn / US-0012744 - Extend DE auto-provisioning to other EU countries
				 : 18.11.2022 / Acmatac SEING / US-0012958 Add missing criteria for VR "Prevent_Coupon_Seller_Creation_DE_Seller"
				 : 29.11.2022/ Bora CHHORN (bora.chhorn@gaea-sys.com) / US-0012663 - Remove "create action" "create category" "bulk upload cohort seller" from permission set "Growth Coaching"
@ Change history : 15.12.2022 / Mony Nou / US-0012734 - [UK] Accessibility Configurations - Cannot deploy before launch
@ Change history : 11.01.2023 / Mony Nou / US-0012694 - [FR] Accessibility Configurations - Cannot deploy before launch
@				 : 01.02.2023 / SRONG TIN / US-0013124 - Users with "Nominated Item Editable" permission unable to upload FVF listings
@				 : 13.06.2023 / Acmatac Seing / US-0013714 - ‘Bulk Upload Coupon Sellers’, ‘Update Co-Invest Share’ and 'Bulk Upload Coupon Items' are not working as
@				 : 30.06.2023 / Chetra Sarom / US-0013306 - Retirement of Managed Payment Solution (Technical Debt3)
@				 : 21/07/2023 / Sovantheany Dim / US-0013870 - Change cohort bulk upload file to new Bulk Upload type (like we have for coupons)
@				 : 14/08/2023 / Mony Nou / US-0013630 - Bulk Upload FVF, replace it with xl copy, paste feature
@				 : 06/09/2023 / Mony Nou / US-0014119 - FVF Bulk Upload functionality is failing 
@				 : 22.09.2023 / Sophal Noch / US-0014118 - ADS - New Cohort seller bulk upload template
@				 : 28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
@				 : 29.04.2024 / Loumang SENG / US-0014956 - Auto enable SP eligibility(AC2)
@				 : 13/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
@				 : 24.09.2024/ vadhanak voun/ US-0015465 - Cohort bulk upload - fail scenario messages
@				 : 30.04.2025 / Sothea Horn / US-0017159 - Replace OwnerId with Account_Manager__c for Coupon Related Class
@				 : 07.07.2025 / Sophal Noch / US-0032982 - GSD: Enable to remove Account managers from cohort in Bulk
*********************************************************************************************************************************/

public with sharing class UploadController { 
	/****************************************************************************************************************************
	* CONSTANTS DEFINITION
	*****************************************************************************************************************************/
    private final static String DATA_TYPE_DECIMAL = 'Decimal',DATA_TYPE_STRING ='String';
	private static String locale;
	public final static String DOC_NAME_MANAGED_PAYMENTS_BULK_UPLOAD = 'MANAGED_PAYMENTS_BULK_UPLOAD';
	//public final static String DOC_NAME_COUPON_SELLER_BULK_UPLOAD = 'MASS_UPLOAD_COUPON_SELLER_CSV_1';
	public final static String DOC_NAME_COUPON_SELLER_BULK_UPLOAD = 'MASS_UPLOAD_COUPON_SELLER_CSV_2';//TH:29/04/2021:US-0009000 - Coupon seller template remove column free subtitle

	public final static String DOC_NAME_COUPON_ITEM_BULK_UPLOAD = 'MASS_UPLOAD_COUPON_ITEM_CSV';

	private final static Integer FVF_NOMINATED_ITEM_MAXIMUM = 10000;
	//LA-28-09-2023: US-0013980 : Remove Coupon__r.Contract_Language__c from query
	//private final static String SOQL_COUPON_SELLER_2 = 'Select Coupon__r.Couponsite_s__c,Seller__r.Strategic_Seller_Share_w__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Language__c, Date_4days_Sent__c, Date_34_days_Sent__c, TriggerEmailManhattan__c, Id,Seller__c,Seller__r.EBH_OracleID__c,Coupon__c,Coupon_Seller_Stage__c,Coupon__r.RecordTypeID,Coupon__r.RecordType.DeveloperName,Coupon__r.Stage__c,SellerShareHolder__c From Coupon_Seller__c' ;
	//private final static String SOQL_COUPON_SELLER = 'Select Coupon__r.Coupon_Subtitle_Copy__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Contract_Language__c,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ;
	private final static String SOQL_COUPON_SELLER_2 = 'Select Coupon__r.Couponsite_s__c,Seller__r.Strategic_Seller_Share_w__c,Coupon__r.Seller_Co_funding_share_forecast__c, Date_4days_Sent__c, Date_34_days_Sent__c, TriggerEmailManhattan__c, Id,Seller__c,Seller__r.EBH_OracleID__c,Coupon__c,Coupon_Seller_Stage__c,Coupon__r.RecordTypeID,Coupon__r.RecordType.DeveloperName,Coupon__r.Stage__c,SellerShareHolder__c From Coupon_Seller__c' ;
	private final static String SOQL_COUPON_SELLER = 'Select Coupon__r.Coupon_Subtitle_Copy__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ;
	private final static String SOQL_COUPON = 'Select Id, Main_Coupon_Site__c, RecordType.DeveloperName FROM Coupon__c'; //MN-29062022-US-0011760-Added Main_Coupon_Site__c
	private final static String SOQL_USER = 'select FederationIdentifier from User';
	private final static String POPCPN_RECTYPE = 'Pop_Coupon';
	// 30/04/2025 US-0017159 - Replace OwnerId with Account_Manager__c
	public final static String SOQL_SELLER = 'Select EBH_BOBManaged__c,Account_Manager__c,Outreach_Manager__c, Coupon_Promotions_Participation__c, Coupon_Promotion_Types__c, Coupon_Discount_Rate__c, Coupon_Funding_Preference__c, Id,EBH_OracleID__c, SP_Coupons__c, EBH_RevRollup__c, Seller_Portal_Group__r.SP_Coupons__c From Account ' ;
	private static final String NA_PROFILE = 'NA Standard User Base'; //MN-29062022-US-0011760
	// private final static String ITEMBASE_RECTYPE = 'Item_Based'; //MN-29062022-US-0011760
	private final static String COUPON_NA_SITE = 'ebay.com';//MN-29062022-US-0011760
	private final static String SP_COUPON_FULL_ACCESS = 'Full Access';// SB 01.07.2022 US-0011998 AC1
	private final static String SP_COUPON_ALLOWED = 'Allowed';// SB 01.07.2022 US-0011998 AC1
	private final static String SELLER_REVROLLUP_DE = 'DE';// SB 01.07.2022 US-0011998 AC1
	private final static String SELLER_REVROLLUP_US = 'US';//MN-21072022-US-0011728 AC8
	//BR-03-11-2022-US-0012744
	private final static String SELLER_REVROLLUP_PL = 'PL';
	private final static String SELLER_REVROLLUP_NL = 'NL';
	private final static String SELLER_REVROLLUP_SE = 'SE';
	private final static String SELLER_REVROLLUP_AT = 'AT';
	private final static String SELLER_REVROLLUP_IT = 'IT';
	private final static String SELLER_REVROLLUP_FR = 'FR';
	private final static String SELLER_REVROLLUP_BE = 'BE';
	private final static String SELLER_REVROLLUP_CZ = 'CZ';
	private final static String SELLER_REVROLLUP_DK = 'DK';
	private final static String SELLER_REVROLLUP_GR = 'GR';
	private final static String SELLER_REVROLLUP_HU = 'HU';
	private final static String SELLER_REVROLLUP_IE = 'IE';
	private final static String SELLER_REVROLLUP_LU = 'LU';
	private final static String SELLER_REVROLLUP_PT = 'PT';
	private final static String SELLER_REVROLLUP_RO = 'RO';
	private final static String SELLER_REVROLLUP_SK = 'SK';
	private final static String SELLER_REVROLLUP_ES = 'ES';
	private final static String SELLER_REVROLLUP_ROE_OTHER = 'ROE -Other';
	private final static String SELLER_REVROLLUP_UK = 'UK'; //MN-15122022-US-0012734
	//01.02.2023 / SRONG TIN / US-0013124
	private final static String FVF_User = 'FVF_User';

	//21.07.2023 / TH : US-0013870
	private static final String TXT_STATUS = 'status';
	private static final String TXT_START_INDEX = 'startIndex';
	private static final String TXT_LIST_RECORD = 'listRecord';
	private static final String TXT_MAP_INDEX_TO_ERROR_MSG = 'mapIndexToErrMsg';
	private static final String TXT_IMPORT_COHORT_SELLER_PRE_DML = 'importCohortSellerPreDML';
	private static final String TXT_IMPORT_NOMINATED_ITEM_PRE_DML = 'importNominatedItemPreDML'; //MN-14082023-US-0013630
	private static final String TXT_METHOD_NOT_IMPLEMENTED = 'Method not implemented';
	private static final String TXT_MAP_EXISTING_LISTINGID = 'mapExistListingId'; //MN-18082023-US-0013630
	private static final String ERROR_TXT_ORACLE_ID_NOT_FOUND = 'Oracle Id Not Found: "{0}" At Row: {1}';
	private static final String ERROR_TXT_CORP_ID_NOT_FOUND = 'User Not Found: "{0}" At Row: {1}';
	private static final String ERROR_TXT_DUPLICATE_ORACLE_ID = 'Duplicate Oracle Id Found: "{0}" At Row: {1}';
	private static final String ERROR_TXT_INVALID_PRICE_FORMAT = 'Invalid Price Format: "{0}".'; //MN-14082023-US-0013630
	private static final String INFORM_TXT_EXISTED_LISTINGID = 'Item ID is already added to the current FVF Promotion.'; //MN-18082023-US-0013630
	private static final Decimal SAMPLE_DECIMAL_VALUE = 1000.10; //MN-15082023-US-0013630
	public static Boolean isBulkBobSeller = false;
	private static final String SELLER_RECORDTYPE = 'EBH_Seller';

	private static final Map<String,String> MAP_MANAGED_SEGMENT_PKVAL = new Map<String,String>{
		'LTAM' => 'PT LTAM',
		'Pro-Trader Category' => 'Pro-Trader Cat'
	};//LA-03-11-2022-US-0012749
	
	private static Set<String> SET_REV_ROLL_UP = new Set<String>{
		SELLER_REVROLLUP_DE, 
		SELLER_REVROLLUP_US,
		SELLER_REVROLLUP_PL,
		SELLER_REVROLLUP_NL,
		SELLER_REVROLLUP_SE,
		SELLER_REVROLLUP_AT,
		SELLER_REVROLLUP_IT,
		SELLER_REVROLLUP_FR,
		SELLER_REVROLLUP_BE,
		SELLER_REVROLLUP_CZ,
		SELLER_REVROLLUP_DK,
		SELLER_REVROLLUP_GR,
		SELLER_REVROLLUP_HU,
		SELLER_REVROLLUP_IE,
		SELLER_REVROLLUP_LU,
		SELLER_REVROLLUP_PT,
		SELLER_REVROLLUP_RO,
		SELLER_REVROLLUP_SK,
		SELLER_REVROLLUP_ES,
		SELLER_REVROLLUP_ROE_OTHER,
		SELLER_REVROLLUP_UK //MN-15122022-US-0012734
		
	};
	//END BR-03-11-2022-US-0012744

	//MN-15122022-US-0012734
	private static final String COUPONSITE_US = 'ebay.com'; 
	private final static String COUPONSITE_DE = 'ebay.de'; 
	private final static String COUPONSITE_UK = 'ebay.co.uk'; 
	private final static String COUPONSITE_FR = 'ebay.fr'; //MN-10032023-US-0012694

	private final static Integer ITEM_PER_TRANS = 1000; //MN-19092022-US-0010910: Moved from EBH_ConstantUtility.cls
	private final static String CO_INVEST_ITEM = 'Coupon_Co_Invest_Item'; //MN-22092022-US-0010910: Moved from EBH_ConstantUtility.cls

	private static final String BOB_LTTM_RECORDTYPE = 'Light_Touch_Category_Cohort'; // 22.09.2023 / Sophal Noch / US-0014118
	private static final String BOB_ADS_RECORDTYPE = 'Advertising_Cohort'; // 22.09.2023 / Sophal Noch / US-0014118

	// 07.07.2025 / Sophal Noch / US-0032982 : create constants below for Account Manager and TTEC Manager
	private static final String BS_FLD_ACC_MGN = 'account_manager__c'; 
	private static final String BS_FLD_TTEC_MGN = 'ttec_manager__c'; 

	/************************************END CONSTANTS DEFINITION*************************************************************/

	/**************
	* Public Method
	**************/
    @AuraEnabled
    public static Map<String,Object> apexInit()
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
    	Boolean isAdmin = (Userinfo.getprofileId()==EBH_ConstantsUtility.ADMIN_PROFILE_ID);
		// 13.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
    	// Boolean isPromoUser = ApexUtil.checkPermissionSet(new Set<String>{EBH_ConstantsUtility.PERMISSION_SET_PROMO});
		Boolean isPromoUser = FeatureManagement.checkPermission(ApexUtil.COUPON_BULK_EDITS_CUSTOM_PERMISSION);
    	mapResult.put('isPromo',(isPromoUser || isAdmin )+'');
    	mapResult.put('status','ok');
    	return mapResult;
    }

	//01.02.2023 / SRONG TIN / US-0013124
	@AuraEnabled
    public static Map<String,Object> checkPermissionFVFUser()
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
		Boolean isFVFUser = ApexUtil.checkPermissionSet(new Set<String>{FVF_User});
		Boolean isAdminPre = (Userinfo.getprofileId()==ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
		Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID);
    	mapResult.put('isUserHasFVF_User_Permission',(isAdmin || isFVFUser || isAdminPre)+'');
    	mapResult.put('status','ok');
    	return mapResult;
    }
 	
	/*****************************************************************************************************************************
    @ Method:   apexCouponCoInvestImport
    @ Version:  1.0
    @ Author: 	Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:	US-0010910 - Amend Bulk Upload Logic to ignore Coupon Item Object
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history:19.09.2022 / Mony Nou  / Created the method.
    *****************************************************************************************************************************/
	@AuraEnabled
    public static Map<String,Object> apexCouponCoInvestImport(String parentId, String csvString,List<List<Coupon_Co_Invest__c>> listAllChunk,Integer listIndex,String csvFormat,String numFormat)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
    	List<String> listError = new  List<String>();
    	try
    	{
    		String sWhere = ' WHERE ID =:parentId';
    		Coupon_Seller__c cs = Database.query(SOQL_COUPON_SELLER+sWhere);

    		if(cs.Seller__c==null || cs.Coupon__c==null)
    		{
    			mapResult.put('status','ko');mapResult.put('error','No Seller or Coupon Selected!');
    		}else
    		{
				if(csvString <> null)
				{//first tran
					
					List<Coupon_Co_Invest__c> listItem = csvToCouponCoInvests(cs.Seller__c,parentId,cs.Coupon__c,csvString,csvFormat,numFormat);
					Integer rowLimit = (Test.isRunningTest()?1:ITEM_PER_TRANS);
					Decimal d = Decimal.valueOf(listItem.size()) / Decimal.valueOf(rowLimit);
	 				Integer numOfChunk = d.round(System.RoundingMode.CEILING).intValue();
	 				listAllChunk = new List<List<Coupon_Co_Invest__c>>();

	 				if(listItem.size()<=rowLimit)
			    	{
			    		listAllChunk.add(listItem);
			    		mapResult.put('more',false);
			    	}else{
			    		for(Integer i=0;i<numOfChunk;i++)
					 	{
					 		Integer startIndex = i==0?0:i*rowLimit;
					 		Integer endIndex = i==0?rowLimit: (i*rowLimit)+rowLimit;
					 		endIndex = endIndex > listItem.size()?listItem.size():endIndex;

					 		List<Coupon_Co_Invest__c> listChunk = new List<Coupon_Co_Invest__c>();
					 		for(Integer j = startIndex;j<endIndex;j++)
					 		{
					 			listChunk.add(listItem[j]);
					 		}
					 		listAllChunk.add(listChunk);
					 	}
					 	mapResult.put('more',true);

			    	}
			    	listIndex = 0;
			    	mapResult.put('totalRow',listItem.size());
			    	mapResult.put('chunk',listAllChunk.size());


				}else
				{//second tran
					if(listIndex+1 < listAllChunk.size())
					{
						mapResult.put('more',true);
					}else
					{
						mapResult.put('more',false);
					}
				}
				mapResult.put('listAllChunk',listAllChunk);
				mapResult.put('listIndex',listIndex);
				List<Coupon_Co_Invest__c> listToSave = listAllChunk[listIndex];
				
				Integer insertedCount = 0;
				if(!listToSave.isEmpty())
				{
					//insert listToSave;
					Database.SaveResult[] srList = Database.insert(listToSave, false);
					Integer index = 0;
					String errorDupInFile = System.label.Error_Duplicate_Coupon_Item_In_File;
					String errorDupInSystem = System.label.Error_Duplicate_Coupon_Item;
					Boolean isHaveDupInFile = false;
					Boolean isHaveDupInSystem = false;
	                for (Database.SaveResult sr : srList) {
	    
	                    if (sr.isSuccess()) {
	                            insertedCount ++ ;
	                    }else{
	                        String message = sr.getErrors()[0].getMessage();
	                        if(message.contains(System.label.Error_Duplicate_Coupon_Item_In_File)){
	                        	isHaveDupInFile = true;
	                        	errorDupInFile += message.split(':')[1]+',';
	                        }else if(message.contains(System.label.Error_Duplicate_Coupon_Item)){
	                        	isHaveDupInSystem = true;
	                        	errorDupInSystem += message.split(':')[1]+',';
	                        }
	                    }
	                    index++;
	                }
	                if(isHaveDupInFile) listError.add(errorDupInFile.removeEnd(','));
	                if(isHaveDupInSystem) listError.add(errorDupInSystem.removeEnd(','));
				}
    			mapResult.put('status','ok');
    			mapResult.put('recordSize',listToSave.size()+'');
    			mapResult.put('insertedCount', insertedCount);
            	mapResult.put('listError',listError);
    		}


    	}catch(Exception ex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
    	}

    	return mapResult;
    }

	@AuraEnabled
    public static Map<String,Object> apexCouponSellerImport(String parentId, String csvString, List<List<Coupon_Seller__c>> listAllChunk,Integer listIndex, String csvFormat, String numFormat)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
		List<String> listError = new  List<String>();
		CouponSellerWrapper cw = new CouponSellerWrapper();// SB 05.07.2022 US-0011998 AC1
    	try
    	{
    		if(csvString <> null){//first tran
    			// List<Coupon_Seller__c> listCouponSeller = csvToSeller(parentId,csvString,csvFormat,numFormat);
				cw = csvToSeller(parentId,csvString,csvFormat,numFormat);// SB 05.07.2022 US-0011998 AC1
    			List<Coupon_Seller__c> listCouponSeller = cw.listCouponSeller;// SB 05.07.2022 US-0011998 AC1
				Integer rowLimit = (Test.isRunningTest()?1:EBH_ConstantsUtility.ITEM_PER_TRANS);
    			Decimal d = Decimal.valueOf(listCouponSeller.size()) / Decimal.valueOf(rowLimit);
 				Integer numOfChunk = d.round(System.RoundingMode.CEILING).intValue();
 				listAllChunk = new List<List<Coupon_Seller__c>>();

 				if(listCouponSeller.size()<=rowLimit){
 					listAllChunk.add(listCouponSeller);
 					mapResult.put('more',false);
 				}else{
 					for(Integer i=0;i<numOfChunk;i++){
 						Integer startIndex = i == 0 ? 0 : i*rowLimit;
 						Integer endIndex = i==0?rowLimit: (i*rowLimit)+rowLimit;
 						endIndex = endIndex > listCouponSeller.size()?listCouponSeller.size():endIndex;

 						List<Coupon_Seller__c> listChunk = new List<Coupon_Seller__c>();
				 		for(Integer j = startIndex;j<endIndex;j++)
				 		{
				 			listChunk.add(listCouponSeller[j]);
				 		}
				 		listAllChunk.add(listChunk);

 					}
 					mapResult.put('more',true);
 				}
 				listIndex = 0;
		    	mapResult.put('totalRow',listCouponSeller.size());
		    	mapResult.put('chunk',listAllChunk.size());
    		}else{//second tran
				if(listIndex+1 < listAllChunk.size())
				{
					mapResult.put('more',true);
				}else
				{
					mapResult.put('more',false);
				}
    		}

    		mapResult.put('listAllChunk',listAllChunk);
			mapResult.put('listIndex',listIndex);
			List<Coupon_Seller__c> listToSave = listAllChunk[listIndex];
			Integer insertedCount = 0;
			Integer errorRevRollUpCount = 0;
			Integer otherError = 0;
			if(!listToSave.isEmpty())
			{
				//insert listToSave;
				//TH: 05/11/2021 : US-0010212 - Coupon Seller: Validation rule Rev. roll up vs coupon main site
				Database.SaveResult[] srList = Database.insert(listToSave, false);
				for (Database.SaveResult sr : srList) {
					if (sr.isSuccess()) {
						insertedCount ++ ;
					}else{
						String message = sr.getErrors()[0].getMessage();
						// TH: 05/11/2021 : US-0010212 : validation rule : 'Validate_Rev_rollUp_VS_MainCouponSite'
						if(message.contains('This seller is not eligible to participate to this coupon promotions due to Revenue Roll up reasons')){
							errorRevRollUpCount ++;
						}
						//Start SB 05.07.2022 US-0011998 AC1
						// else if(message.contains('This seller is not eligible to participate in Coupons. Please update their eligibility to Coupons in the Seller Portal and try again.')){
						// 	continue;
						// }
						//End SB 05.07.2022 US-0011998 AC1
						else{
							listError.add(message);
							otherError ++;
						}
					}
				}
			}

			mapResult.put('status','ok');
			mapResult.put('recordSize',listToSave.size()+'');
			mapResult.put('insertedCount',insertedCount);
			mapResult.put('errorRevRollUpCount',errorRevRollUpCount);
			mapResult.put('otherError',otherError);
			mapResult.put('listError',listError);
			//LA-29-04-2024:US-0014956
			//mapResult.put('ceErrorMessage',cw.ceErrorMessage);// SB 05.07.2022 US-0011998 AC1
    	}catch(DMLException dex){
    		mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}
		catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}

    	return mapResult;
    }

	@AuraEnabled
    public static Map<String,Object> apexNominatedItemImport(String parentId, String csvString, List<List<Nominated_Item__c>> listAllChunk,Integer listIndex, Boolean isProductsUpload, Boolean allowOverrideListingId, String numFormat, String seperator)
    {
		return UploadController.doNominatedItemImport(parentId, csvString, listAllChunk, listIndex, isProductsUpload, allowOverrideListingId, numFormat, seperator);
    }

	/*****************************************************************************************************************************
    @ Method:   doImportSellerAndNominatedItemForFVFCampaign
    @ Version:  1.0
    @ Author: 	vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	US-0006998 Bulk Upload FVF Campaign
    @ Parameter:   	parentId: fvf campaign id who uploading the csv
    @				csvString: content of csv
    @				numFormat: format number, en or de. dot or comma
    @				seperator: comma or semi-column
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history:13.02.2020 /vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/
	@AuraEnabled
	public static Map<String, Object> apexFVFCampaignInit(String parentId)
	{
		Map<String, Object> mapResult = new Map<String, Object>();
		String sWhere = ' Where Id=:parentId ';
		Final_Value_Fee_FVF__c fvf = Database.query(EBH_ConstantsUtility.SOQL_FVF+sWhere);

		mapResult.put('status','ok');
		mapResult.put('showUpload',(fvf.Final_Value_Fee_Stage__c==EBH_ConstantsUtility.FVF_STAGE_DRAFT)+'');

		return mapResult;
	}


	/*****************************************************************************************************************************
    @ Method:   apexBobInit
    @ Version:  1.0
    @ Author: 	sovantheany dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	US-0007333 - LTTM - Bulk Upload BoB Sellers
    @ Parameter:   	parentId: bob id who uploading the csv
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history:31.03.2020 /sovantheany dim (sovantheany.dim@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/
	@AuraEnabled
	public static Map<String, Object> apexBobInit(String parentId)
	{
		Map<String, Object> mapResult = new Map<String, Object>();
		String sWhere = ' Where Id=:parentId ';
		BoB__c bob = Database.query(EBH_ConstantsUtility.SOQL_BOB_1+sWhere);

		mapResult.put('status','ok');
		mapResult.put('showUpload',(bob.Status__c==EBH_ConstantsUtility.BOB_STATUS_DRAFT || bob.Status__c==EBH_ConstantsUtility.BOB_STATUS_ACTIVE)+'');

		return mapResult;
	}

	/*****************************************************************************************************************************
    @ Method:   doImportSellerAndNominatedItemForFVFCampaign
    @ Version:  1.0
    @ Author: 	vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	US-0006998 Bulk Upload FVF Campaign
    @ Parameter:   	parentId: fvf campaign id who uploading the csv
    @				csvString: content of csv
    @				numFormat: format number, en or de. dot or comma
    @				seperator: comma or semi-column
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history:13.02.2020 /vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/
	@AuraEnabled
	public static Map<String, Object> apexImportSellerAndNominatedItemForFVFCampaign(String parentId, String csvString, String numFormat, String seperator)
	{
		Map<String, Object> mapResult = new Map<String, Object>();
		 try
		 {
		 	String uniqueName = ApexUtil.genUniqueString(10);

	    	//temporary doc. to be processed by Batch + String Iterator. then delete on finish
	    	Document doc=new Document(Name=uniqueName,Body=Blob.valueOf(csvString+''),FolderId=UserInfo.getUserId());
	        insert doc;
	        //process bulk csv extract and process the logic import in backgroun. send email notificaiton when done
	        Batch_FVFCampaignBulkCSV b = new Batch_FVFCampaignBulkCSV(parentId,uniqueName,numFormat,seperator);
	        Database.executeBatch(b);

        	mapResult.put('status','ok');
		 }catch(Exception ex)
		 {
		 	mapResult.put('status','ko');mapResult.put('error',ex.getMessage());
		 }

		return 	mapResult;
	}


	/*****************************************************************************************************************************
    @ Method:   apexImportBobSeller
    @ Version:  1.0
    @ Author: 	sovantheany dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	US-0007333 - LTTM - Bulk Upload BoB Sellers
    @ Parameter:   	parentId: fvf campaign id who uploading the csv
    @				csvString: content of csv
    @				numFormat: format number, en or de. dot or comma
    @				seperator: comma or semi-column
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history:27.03.2020 /sovantheany dim (sovantheany.dim@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/
	@AuraEnabled
	public static Map<String, Object> apexImportBobSeller(String parentId, String csvString, String numFormat, String seperator)
	{
		Map<String, Object> mapResult = new Map<String, Object>();
		 try
		 {
		 	Map<String,Integer> jobCounter  = ApexUtil.countRunningBatch(new Set<String> {'Batch_BobSellerBulkCSV'});
		 	if(jobCounter.get('Batch_BobSellerBulkCSV')>0){
		 		mapResult.put('status','ko');mapResult.put('error','Upload already in progress');
		 		return mapResult;
		 	}

		 	String uniqueName = ApexUtil.genUniqueString(10);

	    	//temporary doc. to be processed by Batch + String Iterator. then delete on finish
	    	Document doc=new Document(Name=uniqueName,Body=Blob.valueOf(csvString+''),FolderId=UserInfo.getUserId());
	        insert doc;
	        // system.debug('nsp doc id: '+doc.Id);
	        //process bulk csv extract and process the logic import in backgroun. send email notificaiton when done
	        Batch_BobSellerBulkCSV b = new Batch_BobSellerBulkCSV(parentId,uniqueName,numFormat,seperator);
	        Database.executeBatch(b);

        	mapResult.put('status','ok');
		 }catch(Exception ex)
		 {
		 	mapResult.put('status','ko');mapResult.put('error',ex.getMessage());
		 }

		return 	mapResult;
	}



	

	/*****************************************************************************************************************************
    @ Method:   getDocumentUrl
    @ Version:  1.0
    @ Author: 	Sreymeas Nao (sreymeas.nao@gaea-sys.com)
    @ Purpose:	US-0015725 Attach csv tempaltes for FVF
	@		    AC1: Given that I am Any User When I go to FVF record and press on "Bulk Upload Nominated Items", Listings
				Then in the pop-up window I can see a link to the csv. template (similar to Trading Engine)
				Template is a csv file with two columns: Listing Id and Price (target)
				AC2: Given that I am Any User When I go to FVF record and press on "Bulk Upload Nominated Items", Products
				Then in the pop-up window I can see a link to the csv. template (similar to Trading Engine)
				Template is a csv file with two columns: EAN and Price (target)
    @ Parameter:     Boolean isBtnProduct
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history:15.11.2019 / Sreymeas Nao / Created the  Method
    *****************************************************************************************************************************/
	@AuraEnabled
	public static string getDocumentUrl(Boolean isBtnProduct, String isfvfCampaign){
		String urlId;
		String whereCl = ' where DeveloperName=\''+EBH_ConstantsUtility.DOC_NAME_LISTING+'\'';
		if (isBtnProduct != null && isBtnProduct) {
			whereCl = ' where DeveloperName=\''+EBH_ConstantsUtility.DOC_NAME_PRODUCT+'\'';
		}else if(isfvfCampaign == 'fvfcampaign'){
			whereCl = ' where DeveloperName=\''+EBH_ConstantsUtility.DOC_NAME_FVFCAMPAIGN+'\'';
		}else if(isfvfCampaign == 'bobSeller'){//TH : 27.03.2020 : US-0007333 - LTTM - Bulk Upload BoB Sellers
			whereCl = ' where DeveloperName=\''+EBH_ConstantsUtility.BULK_BOBSELLER_DOC+'\'';
		}else if(isfvfCampaign == 'EBH_Project__c'){
			whereCl = ' where DeveloperName=\''+DOC_NAME_MANAGED_PAYMENTS_BULK_UPLOAD+'\'';

		}else if(isfvfCampaign == 'couponSeller'){//TH: US-0000145 : 15/03/2021
			whereCl = ' where DeveloperName=\''+DOC_NAME_COUPON_SELLER_BULK_UPLOAD+'\'';
		}else if(isfvfCampaign == 'couponItem'){//TH: US-0009129 - Coupon Seller Object - Template for CSV Bulk Upload Coupon items 16/03/2021:
			whereCl = ' where DeveloperName=\''+DOC_NAME_COUPON_ITEM_BULK_UPLOAD+'\'';

		}

		for (Document oneId : Database.query(EBH_ConstantsUtility.SOQL_DOC+whereCl)) {
			urlId = oneId.Id;
		}
		String urlInstance=URL.getOrgDomainUrl().toExternalForm() + '/servlet/servlet.FileDownload?file='+urlId;

		return urlInstance;
	}

	// AC3, US-0018681 : @amt:18-11-19
	@AuraEnabled
	public static Map<String, Object> doSendEmailForReachingMaxRecord(String itemId, String insertCount, String updateCount){
		Map<String, Object> mapResult = new Map<String, Object>();
		try {
			String fvfName = [SELECT Name FROM Final_Value_Fee_FVF__c WHERE Id =: itemId].Name;
			String itemLink = URL.getOrgDomainUrl().toExternalForm() + '/' + itemId;
			String body = '<p>Upload of the Nominated items for <a href=' + itemLink + '>'+ fvfName +'</a> is successfully completed.</p>' +
						'<p>'+ insertCount +' number of items have been update</p>' +
						'<p>'+ updateCount +' number of items has been created</p>';
			String email = UserInfo.getUserEmail();
			ApexUtil.doSend('Upload of the Nominated items notification', email, body);
			mapResult.put('status', 'ok');
		} catch (Exception ex) {
			mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
		}
		return mapResult;
	}

	/**************
	* Public Method END
	**************/

	/**************
	* Private Method
	**************/

    private static Map<String,Object> doNominatedItemImport(String parentId, String csvString, List<List<Nominated_Item__c>> listAllChunk, Integer listIndex, Boolean isProductsUpload, Boolean allowOverrideListingId, String numFormat, String seperator){
        Map<String,Object> mapResult = new Map<String,Object>();
    	locale = numFormat;

		// AC2 : US-0011862 : @BR:10-06-22
		Integer nominateItemRelatedSize = [SELECT Count() FROM Nominated_Item__c where Final_Value_Fee_FVF__c =: parentId];

    	try
    	{
    		if(csvString <> null){//first tran
				NominatedItemWrapper nomItemWrapp = csvToNominatedItem(parentId, csvString, isProductsUpload, allowOverrideListingId,numFormat, seperator);

				// AC2 : US-0011862 : @BR:10-06-22 , Prevent and warn users from adding more than 10.000 Nominated Items to FVF
				if((nominateItemRelatedSize + nomItemWrapp.insertSize) > FVF_NOMINATED_ITEM_MAXIMUM) {
                    mapResult.put('status', 'reachedLimit');
                    return mapResult;
                }
				
				//  AC2, US-0018681 : @amt:18-11-19 , When there are duplicates existing ListingId then confirming user on yes/no modal
				if(String.isNotBlank(nomItemWrapp.confirmMsg)){
					mapResult.put('status', 'confirmExistListingId');
					mapResult.put('confirmMsg', nomItemWrapp.confirmMsg);
					return mapResult;
				}

    			List<Nominated_Item__c> listItem = nomItemWrapp.listNominatedItem;
    			Integer rowLimit = (Test.isRunningTest()?1:EBH_ConstantsUtility.ITEM_PER_TRANS);
    			Decimal d = Decimal.valueOf(listItem.size()) / Decimal.valueOf(rowLimit);
 				Integer numOfChunk = d.round(System.RoundingMode.CEILING).intValue();
 				listAllChunk = new List<List<Nominated_Item__c>>();

 				if(listItem.size()<=rowLimit){
 					listAllChunk.add(listItem);
 					mapResult.put('more',false);
 				}else{
 					for(Integer i=0;i<numOfChunk;i++){
 						Integer startIndex = i == 0 ? 0 : i*rowLimit;
 						Integer endIndex = i==0?rowLimit: (i*rowLimit)+rowLimit;
 						endIndex = endIndex > listItem.size()?listItem.size():endIndex;

 						List<Nominated_Item__c> listChunk = new List<Nominated_Item__c>();
				 		for(Integer j = startIndex;j<endIndex;j++)
				 		{
				 			listChunk.add(listItem[j]);
				 		}
				 		listAllChunk.add(listChunk);

 					}
 					mapResult.put('more',true);
 				}
 				listIndex = 0;
		    	mapResult.put('totalRow',listItem.size());
		    	mapResult.put('chunk',listAllChunk.size());
    		}else{//second tran
				if(listIndex+1 < listAllChunk.size())
				{
					mapResult.put('more',true);
				}else
				{
					mapResult.put('more',false);
				}
    		}



			
    		mapResult.put('listAllChunk',listAllChunk);
			mapResult.put('listIndex',listIndex);
			List<Nominated_Item__c> listToSave = listAllChunk[listIndex];
			Integer insertedCount = 0, updatedCount = 0;
			if(!listToSave.isEmpty())
			{
				Database.UpsertResult[] srList = Database.upsert(listToSave);
				for (Database.UpsertResult sr : srList) {
					if (sr.isSuccess()) {
						if(sr.isCreated()){
							insertedCount++;
						}else{
							updatedCount++;
						}
					}
				}
			}
			mapResult.put('insertedCount', insertedCount);
			mapResult.put('updatedCount', updatedCount);
			mapResult.put('status','ok');
			mapResult.put('recordSize',listToSave.size()+'');
    	}catch(DMLException dex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}
    	catch(Exception ex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
    	}

    	return mapResult;
    }
	/*****************************************************************************************************************************
    @ Method:   csvToNominatedItem
    @ Version:  1.0
    @ Author:   ...
	@ Purpose: 	...
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     ... 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: ...
	@ 				: 13/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
    *****************************************************************************************************************************/
	private static NominatedItemWrapper csvToNominatedItem(String parentId, String contentfile, Boolean isProductsUpload, Boolean allowOverrideListingId, String numFormat, String seperator)
    {
		NominatedItemWrapper nomItemWrapp = new NominatedItemWrapper();

    	contentfile = contentfile.replace('\n','');
    	OpenCSVParser parser = new OpenCSVParser(seperator,OpenCSVParser.DEFAULT_QUOTE_CHARACTER, OpenCSVParser.DEFAULT_ESCAPE_CHARACTER,OpenCSVParser.DEFAULT_STRICT_QUOTES, OpenCSVParser.DEFAULT_IGNORE_LEADING_WHITESPACE);
    	OpenCSVReader reader = new OpenCSVReader(parser,contentfile,'\r',false);//unix user only \r
    	List<List<String>>lstDataRow = reader.readAll();
    	if(!lstDataRow.isEmpty())
        {
        	lstDataRow.remove(0); //remove header
        }
        Integer rowIndex = 1;
        String error = '';
        List<Nominated_Item__c> lstNominateItem = new List<Nominated_Item__c>();
        List<Nominated_Item__c> lstNominateItem_prodtt = new List<Nominated_Item__c>();
		Set<String> setListingIds = new Set<String>();
        //Set<String> sProdTitle = new Set<String>();

		Set<String> sExcelDuplicateListingId = new Set<String>();
		Map<String, String> mExistListingId = new Map<String, String>();
		Set<String> sInvalidListingId = new Set<String>();

        for(List<String> row : lstDataRow)
        {
        	rowIndex++;
        	Decimal prodTargetPrice;
			String priceVal, prodTitle, prodEAN;
        	String col1 = row[0];
            if(isProductsUpload){
            	if(row.size() != 2 && row.size() !=3){
            		throw new CouponException('Invalid data');
            	}
				if (row.size() ==3) {
					prodTitle = row[0];
					prodEAN = row[1];
					priceVal = row[2];
				}else{
					prodEAN = row[0];
					priceVal = row[1];
				}
                prodTargetPrice = Decimal.valueOf(getPriceByLocale(priceVal, locale));
                lstNominateItem.add(new Nominated_Item__c(From_Upload__c = true, Final_Value_Fee_FVF__c = parentId, Product_Name__c = prodTitle, EAN_w__c = prodEAN, Price_target_w__c = prodTargetPrice));
                //lstNominateItem_prodtt.add(new Nominated_Item__c(From_Upload__c=true,Final_Value_Fee_FVF__c = parentId, Product_Name__c = prodTitle, EAN_w__c = prodEAN, Price_target_w__c = prodTargetPrice));
                //sProdTitle.add(prodTitle);
            }else {
            	if(row.size() != 2){
            		throw new CouponException('Invalid data');
            	}
                String listingId = row[0];
				priceVal = row[1];
				//prodTargetPrice = Decimal.valueOf(priceVal);
                prodTargetPrice = Decimal.valueOf(getPriceByLocale(priceVal, locale));
                if(String.isBlank(listingId)){
                	error+='Invalid Listing ID on row: '+rowIndex+' : '+row[0]+'\n';
                }else {
					// AC4, US-0018681 : @amt:18-11-19
					if(!listingId.isNumeric() || (listingId.length() < 9 || listingId.length() > 16)){
						sInvalidListingId.add(listingId);
					}
					// AC1, US-0018681 : @amt:18-11-19
					if(setListingIds.contains(listingId)){
						sExcelDuplicateListingId.add(listingId);
					}
                	    					lstNominateItem.add(new Nominated_Item__c(From_Upload__c=true,Final_Value_Fee_FVF__c = parentId, Listing_ID_w__c = listingId, Price_target_w__c = prodTargetPrice));
					setListingIds.add(listingId);
                }

            }
        }
       
		if(!isProductsUpload){
			// AC4, US-0018681 : @amt:18-11-19
			if(!sInvalidListingId.isEmpty()){
				throw new CouponException(System.Label.UPLOADING_INVALID_LISTINGID_MSG + '\n' + String.join((Iterable<String>)sInvalidListingId, ',\n'));
			}

			// AC1, US-0018681 : @amt:18-11-19
			if(!sExcelDuplicateListingId.isEmpty()){
				throw new CouponException(System.Label.UPLOADING_EXCEL_DUPLICATEID_MSG + '\n' + String.join((Iterable<String>)sExcelDuplicateListingId, ',\n'));
			}

			// AC2, US-0018681 : @amt:18-11-19
			String sWhere = ' WHERE Final_Value_Fee_FVF__c =: parentId AND Listing_ID_w__c IN: setListingIds';
			for(Nominated_Item__c oneItem : Database.query(EBH_ConstantsUtility.SOQL_NOMINATED_ITEMS + sWhere)){
				mExistListingId.put(oneItem.Listing_ID_w__c, oneItem.Id);
			}
			if(!allowOverrideListingId){
				nomItemWrapp.insertSize = setListingIds.size();
				if(!mExistListingId.isEmpty()){
					nomItemWrapp.insertSize -= mExistListingId.keySet().size();
					nomItemWrapp.confirmMsg = System.Label.UPLOADING_EXISTING_DUPLICATEID_MSG + '\n' + String.join((Iterable<String>)mExistListingId.keySet(), ',\n');
					return nomItemWrapp;
				}
			}

			for(Nominated_Item__c item : lstNominateItem){
				// AC2, US-0018681 : @amt:18-11-19
				// If Listing is existing then Update record
				if(mExistListingId.containsKey(item.Listing_ID_w__c)){
					item.Id = mExistListingId.get(item.Listing_ID_w__c);
				}

			}
        }

        if(String.isNotBlank(error))
        {
        	throw new CouponException(error);
        }

		nomItemWrapp.listNominatedItem = lstNominateItem;
        return nomItemWrapp;
    }
 

	/*****************************************************************************************************************************
    @ Method:         csvToCouponCoInvests
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        US-0010910 - Amend Bulk Upload Logic to ignore Coupon Item Object
    @------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.09.2012 / Mony Nou / Create method
	*****************************************************************************************************************************/
    private static List<Coupon_Co_Invest__c> csvToCouponCoInvests(String sellerId, String parentId,String couponId,String contentfile,String csvFormat,String numFormat)
    {
		contentfile = contentfile.replace('\n','');
        OpenCSVParser parser = new OpenCSVParser(csvFormat,OpenCSVParser.DEFAULT_QUOTE_CHARACTER, OpenCSVParser.DEFAULT_ESCAPE_CHARACTER,OpenCSVParser.DEFAULT_STRICT_QUOTES, OpenCSVParser.DEFAULT_IGNORE_LEADING_WHITESPACE);
        OpenCSVReader reader = new OpenCSVReader(parser,contentfile,'\r',false);//unix user only \r
        List<List<String>>lstDataRow = reader.readAll();
        if(!lstDataRow.isEmpty())
        {
        	lstDataRow.remove(0); //remove header
        }
        List<Coupon_Co_Invest__c> listItem = new List<Coupon_Co_Invest__c>();
        Integer rowIndex = 1;
        
        Set<String> sItemWrongFormat = new Set<String>();
        String error = '';

		RecordType coInvestItemRecordType = ApexUtil.getRecordTypeByName('Coupon_Co_Invest__c',CO_INVEST_ITEM);
		

        for(List<String> row : lstDataRow)
        {
        	rowIndex++;
        	
        	String itemId = row[0].trim();
			String itemTitle;
			String sellerShare;
			
			if(row.size() == 3){

				itemTitle = row[1].trim();

				sellerShare = row[2].trim();
				sellerShare = getPriceByLocale(sellerShare, numFormat);
			}

        	if(String.isBlank(itemId) || itemId == null || String.isEmpty(itemId)) continue;

			if(!itemId.isNumeric() || itemId.length() < 9 || itemId.length() > 16){ sItemWrongFormat.add(itemId); }
			
			
			if(String.isNotBlank(sellerShare)){

				Decimal tmp = Decimal.valueOf(sellerShare);
				if (tmp > 100) error += 'Seller share% should not be more than 100% on row: ' + rowIndex + ' : ' + sellerShare + '\n';
				else{
					listItem.add( new Coupon_Co_Invest__c(RecordTypeId=coInvestItemRecordType.Id, Seller_Name__c=sellerId, Coupon_Name__c=couponId, Coupon_Seller__c=parentId, Item_ID__c=itemId, Item_Title__c = itemTitle, Co_Invest__c=decimal.valueOf(sellerShare)));
				}
			
			}else{
				listItem.add( new Coupon_Co_Invest__c(RecordTypeId=coInvestItemRecordType.Id, Seller_Name__c=sellerId, Coupon_Name__c=couponId, Coupon_Seller__c=parentId,Item_ID__c=itemId, Item_Title__c = itemTitle));
			}

			

        }

        if(!sItemWrongFormat.isEmpty()){
        	error+= 'The item ID you tried to add is in wrong format or not an item Id. Please check the following entries and correct before uploading:\n';
        	for(String wrongFormatItem : sItemWrongFormat){
        		error+= wrongFormatItem+'\n';
        	}
        }
        
        if(String.isNotBlank(error))
        {
        	throw new CouponException(error);
        }

        return listItem;
    }

	/*** @ Change history: 18.02.2020 / Sreymeas Nao / US-0007139: Coupon : Give a possibility to upload Coupon Sellers, Share & subtitle indication in right format
	     @ Change history: 26.08.2020 / Sreymeas Nao / US-0007453: [POP Coupon] - CORRECTIONS 
		 @ Change history: 15/03/2021 / Sovantheany Dim / US-0000145 - Coupon Object - Template for CSV Bulk Upload Coupon sellers in section
		 @ Change history: 26/11/2021 / Sovantheany Dim / US-0010617 - DE POP COUPON contract renewal: adding existing sellers to a promo
		 @ Change history: 29/06/2022 / Mony Nou / US-0011760 - Bulk upload enhancements for Coupons
		 @ Change history: 06/07/2022 / Sambath Seng / US-0011998 - Business Feedback Focus 75 AC1
		 @ Change history : 03.11.2022 / Bora Chhorn / US-0012744 - Extend DE auto-provisioning to other EU countries
		 				  : 18.11.2022 / Acmatac SEING / US-0012958 Add missing criteria for VR "Prevent_Coupon_Seller_Creation_DE_Seller"
		 @				  : 30.04.2025 / Sothea Horn / US-0017159 - Replace OwnerId with Account_Manager__c for Coupon Related Class

 ***/
	private static CouponSellerWrapper csvToSeller(String parentId,String contentfile,String csvFormat,String numFormat)
    {
        contentfile = contentfile.replace('\n','');
    	OpenCSVParser parser = new OpenCSVParser(csvFormat,OpenCSVParser.DEFAULT_QUOTE_CHARACTER, OpenCSVParser.DEFAULT_ESCAPE_CHARACTER,OpenCSVParser.DEFAULT_STRICT_QUOTES, OpenCSVParser.DEFAULT_IGNORE_LEADING_WHITESPACE);
    	OpenCSVReader reader = new OpenCSVReader(parser,contentfile,'\r',false);//unix user only \r
		List<List<String>>lstDataRow = reader.readAll();
		Coupon__c popCpn = Database.query(SOQL_COUPON + ' where Id = :parentId');
		Boolean isPopCpn = (popCpn.RecordType.DeveloperName == POPCPN_RECTYPE);
		// Boolean isItmBas = (popCpn.RecordType.DeveloperName == ITEMBASE_RECTYPE); //MN-29062022-US-0011760
		Boolean isNASite = (popCpn.Main_Coupon_Site__c == COUPON_NA_SITE); //MN-29062022-US-0011760
		RecordType cpsRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',POPCPN_RECTYPE);
		RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
    	if(!lstDataRow.isEmpty())
        {
        	lstDataRow.remove(0); //remove header
        }
		
        Integer rowIndex = 1;
		String error = '';
		Map<String,Integer> mapOracleIds = new Map<String,Integer>();
		Map<Integer,String> mapFreeSub = new Map<Integer,String>();
        Set<String> sOracleIdInFile = new set<String>();
		Set<String> sDubOracleIdInFile = new set<String>();
		Map<String,CSVData> newCs = new Map<String,CSVData>();
		CSVData newCSData;
		set<String> sOwner = new Set<String>();
		//LA-29-04-2024:US-0014956
		//List<String> lstOracleIdnRecUrl = new List<String>(); // SB 01.07.2022 US-0011998 AC1
		CouponSellerWrapper cw = new CouponSellerWrapper();// SB 01.07.2022 US-0011998 AC1
		//String ceError = '';// SB 01.07.2022 US-0011998 AC1 // LA-29-04-2024:US-0014956
        for(List<String> row : lstDataRow)
        {
        	rowIndex++;
			String oracleId = row[0].trim();

			newCSData = new CSVData(row,numFormat);
			if(!String.isBlank(newCSData.owner)) sOwner.add(newCSData.owner); //TH: US-0000145 : 15/03/2021
        	if(String.isBlank(oracleId))
        	{
        		error+='Invalid Oracle Id on row: '+rowIndex+' : '+row[0]+'\n';
        	}else
        	{
 				if(sOracleIdInFile.contains(oracleId)){
        			sDubOracleIdInFile.add(oracleId);
        			continue;
        		}
        		sOracleIdInFile.add(oracleId);
				mapOracleIds.put(oracleId,rowIndex);
				newCs.put(oracleId,newCSData);
			}

			// if (isItmBas) { //MN-29062022-US-0011760
			String sellerShare = row[1].trim();
			sellerShare = getPriceByLocale(sellerShare, numFormat);

			if (String.isNotBlank(sellerShare)) {
				
				Decimal tmp = Decimal.valueOf(sellerShare);
				if (tmp > 100) error += 'Seller share% should not be more than 100% on row: ' + rowIndex + ' : ' + row[1]+ '\n';
				
			}
			

				
			// }

			
		}
        if(mapOracleIds.isEmpty()) return new CouponSellerWrapper();


        if(!sDubOracleIdInFile.isEmpty()){
        	error+= 'Your file includes duplicate Oracle ID entries. Please deduce the following Oracle IDs in your file before uploading the file:\n';
        	for(String dupItemId : sDubOracleIdInFile){
        		error+= dupItemId+'\n';
        	}
        }
       	//TH: 04/03/2020 : US-0007259 POP COUPON - NEW RECORD TYPE COUPON OBJECT
        /*RecordType popCouponRecordType = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_POP_RECORDTYPE);
        RecordType popCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPON_POP_RECORDTYPE);
        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
        List<Coupon__c> coupons = Database.query(EBH_ConstantsUtility.SOQL_COUPON + ' where id =: parentId');
        String csellerRecordTypeId = coupons[0].RecordTypeId == popCouponRecordType.Id ? popCouponSellerRecordType.Id : manhattanCouponSellerRecordType.Id;*/
        //End US-0007259 POP COUPON - NEW RECORD TYPE COUPON OBJECT
        
        //TH: US-0000145 : 15/03/2021
        Map<String,String> mapOwner = new Map<String,String>();
        for(User user : Database.query(SOQL_USER+' where FederationIdentifier IN: sOwner')){
        	mapOwner.put(user.FederationIdentifier, user.Id);
        }
        //End US-0000145 : 15/03/2021
        Set<String> setOraclIds = mapOracleIds.keySet();
        List<Coupon_Seller__c> lstCouponSeller = new List<Coupon_Seller__c>();
        Set<String> sellerIds = new Set<String>();
		String sWhere = ' where EBH_OracleID__c IN: setOraclIds and RecordType.DeveloperName = \'EBH_Seller\'';

		//MN-29062022-US-0011760
		String NAprofile = ApexUtil.getProfileByName(NA_PROFILE).Id;
        Boolean isNA = UserInfo.getProfileId().equals(NAprofile);
        //END - MN-29062022-US-0011760

		//MN-15122022-US-0012734 - Move all fixed Main Coupon Site from below IF criteria into SET variable instead
		Set<String> sMainCouponSite = new Set<String>{
			COUPONSITE_DE,
			COUPONSITE_US,
			COUPONSITE_UK,
			COUPONSITE_FR //MN-10032023-US-0012694
		};

        for(Account seller : Database.query(SOQL_SELLER+sWhere)){
        	if(mapOracleIds.containsKey(seller.EBH_OracleID__c)) {
        		mapOracleIds.remove(seller.EBH_OracleID__c);
        	}
			
			
            // Commented by Acmatac SEING, 4-Aug-2022, US-0012269
			////Start SB 01.07.2022 US-0011998 AC1
			//MN-21072022-US-0011728 - Added RevRollup = "US" into condition
			//BR-31-08-2022-US-0012305 - [DE Launch] Deploy missing ACs from US-0011998
			//BR-03-11-2022-US-0012744
			
			//if((popCpn.Main_Coupon_Site__c == 'ebay.de' || popCpn.Main_Coupon_Site__c == 'ebay.com' || popCpn.Main_Coupon_Site__c == 'ebay.co.uk') && //US-0012958 Add missing criteria for VR "Prevent_Coupon_Seller_Creation_DE_Seller"
			//MN-15122022-US-0012734 - Change criteria to use with multiple OR into checking with SET variable instead
			// LA:29-04-2024: US-0014956
			/*if (sMainCouponSite.contains(popCpn.Main_Coupon_Site__c) &&
				SET_REV_ROLL_UP.contains(seller.EBH_RevRollup__c) && (seller.SP_Coupons__c != SP_COUPON_FULL_ACCESS && seller.Seller_Portal_Group__r.SP_Coupons__c != SP_COUPON_ALLOWED)){
				//
				lstOracleIdnRecUrl.add('<a class="errorMsg" href=\''+getSellerRecordUrl(seller.Id)+'\' target=\'_blank\'>'+seller.EBH_OracleID__c+'</a>');
			}*/
			////End SB 01.07.2022 US-0011998 AC1
			//LA-29-04-2024:US-0014956

			sellerIds.add(seller.Id);
			//if coupon recortype is pop coupon then coupon seller must be pop coupon also.
			Coupon_Seller__c cs = new Coupon_Seller__c(Coupon__c = parentId,Seller__c = seller.Id,RecordTypeId=isPopCpn?cpsRecordType.Id:manhattanCouponSellerRecordType.Id);//,RecordTypeId = csellerRecordTypeId);
			if (newCs.containsKey(seller.EBH_OracleID__c)) {
				if(!String.isBlank(newCs.get(seller.EBH_OracleID__c).sellerShare)){
					cs.SellerShareHolder__c = decimal.valueOf(newCs.get(seller.EBH_OracleID__c).sellerShare);
				}
				//TH:29/04/2021:US-0009000 : remove free subtitle
				/*if(!String.isBlank(newCs.get(seller.EBH_OracleID__c).freeSub)){
					cs.Free_Subtitles__c = newCs.get(seller.EBH_OracleID__c).freeSub;
				}*/
				
				//TH: US-0000145 : 15/03/2021
				String owner = newCs.get(seller.EBH_OracleID__c).owner;
				//LA:03-05-2021-US-0009466
				//LA:16-06-2021-US-0009645
				if(mapOwner.containsKey(owner)){
					cs.EBH_CouponSellerOwner__c =  mapOwner.get(owner);
				}else{
					if (isNA && isNASite) { //MN-29062022-US-0011760
						
						cs.EBH_CouponSellerOwner__c = Userinfo.getUserId();
					
					} else { 
						if(seller.EBH_BOBManaged__c){
							// 30/04/2025 - US-0017159 - Replace OwnerId with Account_Manager__c. If Account.Account_Manager__c has null value and we need value from it to populate other field, use value IntegrationUserId (0056A000000zaxM) to populate to other field
							// cs.EBH_CouponSellerOwner__c = seller.OwnerId;
							cs.EBH_CouponSellerOwner__c = String.isNotBlank(seller.Account_Manager__c) ? seller.Account_Manager__c : ApexUtil.INTEGRATION_USER_ID;
						}else{
							cs.EBH_CouponSellerOwner__c= (seller.Outreach_Manager__c != null)?seller.Outreach_Manager__c:Userinfo.getUserId();
						}
						//cs.EBH_CouponSellerOwner__c = mapOwner.containsKey(owner)? mapOwner.get(owner) : Userinfo.getUserId();

					}

					
				}
				//End US-0000145 : 15/03/2021
			}

			lstCouponSeller.add(cs);
		}
        for(String key : mapOracleIds.keySet()){
        	Integer rowIndex1 = mapOracleIds.get(key);
        	error+='No Seller found on row: '+rowIndex1+' : '+key+'\n';
        }

		//TH: 05/11/2021: US-0010617 - For Pop Coupon Seller with Stage__c = "contract appended" or "declined" or "contract terminated" , we don't need to check Duplicate seller
		set<String> sPopCouponStage = new set<String>{'Declined','Contract Appended','Contract Terminated'};
        String whereCs = ' where Coupon__c =: parentId and Seller__c IN: sellerIds and (RecordType.DeveloperName !=: POPCPN_RECTYPE OR (RecordType.DeveloperName =: POPCPN_RECTYPE AND Coupon_Seller_Stage__c NOT IN: sPopCouponStage))';

        List<Coupon_Seller__c> lstCsSeller = Database.query(SOQL_COUPON_SELLER_2+whereCs);
        if(!lstCsSeller.isEmpty()){
			//TH:26/11/2021:move to custom label
			//error += 'You cannot add the same seller to the same coupon twice. Some sellers couldn\'t be uploaded:\n';
			error += System.label.msg_duplicateCouponSeller+'\n';
        	for(Coupon_Seller__c cSeller : lstCsSeller){
        		error += cSeller.Seller__r.EBH_OracleID__c+'\n';
        	}
        }

        if(String.isNotBlank(error))
        {
        	throw new CouponException(error);
        }
		//LA:29-04-2024:US-0014956
		//Start SB 01.07.2022 US-0011998 AC1
		/*if(!lstOracleIdnRecUrl.isEmpty()){
			String errorMsg = System.Label.Coupon_Eligibility_Error_Message;
			ceError += errorMsg.replace('{oracleId}', String.join(lstOracleIdnRecUrl, ', '));
		}*/
		cw.listCouponSeller = lstCouponSeller;
		//cw.ceErrorMessage = ceError;//LA-29-04-2024: US-0014956
		//End SB 01.07.2022 US-0011998 AC1

		return cw;
    }

	private static String getPriceByLocale(String value, String locale){
		return ApexUtil.fixNumber(value, locale);
	}

	/**************
	* Private Method END
	**************/

	public class NominatedItemWrapper {
		public String confirmMsg;
		public List<Nominated_Item__c> listNominatedItem;
		public Integer insertSize = 0;

		public NominatedItemWrapper(){
			this.listNominatedItem = new List<Nominated_Item__c>();
			this.confirmMsg = '';
		}
	}

	// upload seller share to coupon co-invest and free subtitle to coupon seller
	private class CSVData {
		public String oracleId;
		public String sellerShare;
		//public String freeSub;//TH:29/04/2021:US-0009000 : remove free subtitle
		public String owner;

		public CSVData(List<String> col, String numFormat){
				this.oracleId = col[0].trim();

				//NK:22/06/2020: US-0007733 - Hypercare - Bulk coupon seller upload not possible
				// when there is only single column
				this.sellerShare = col.size()>1? getPriceByLocale(col[1].trim(),numFormat):this.sellerShare;
				//this.freeSub = col.size()>2?col[2].trim():this.freeSub;//TH:29/04/2021:US-0009000 : remove free subtitle
				
				//TH:15/03/2021:US-0000145 - Coupon Object - Template for CSV Bulk Upload Coupon sellers in section
				//this.owner = col.size()>3?col[3].trim():this.owner;//TH:29/04/2021:US-0009000 : remove free subtitle column
				this.owner = col.size()>2?col[2].trim():this.owner;
		}
	}

    class CouponException extends Exception{}

	/*****************************************************************************************************************************
    @ Method:         getSellerRecordUrl
    @ Version:        1.0
    @ Author:         Sambath Seng
    @ Purpose:        US-0011998 - Business Feedback Focus 75 AC1
    @------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 01.07.2022 / Sambath Seng / Create the method
	@               : 29.04.2024 / Loumang SENG / Comment this method
    *****************************************************************************************************************************/
	/*private static String getSellerRecordUrl(Id recordId){
		return URL.getSalesforceBaseUrl().toExternalForm()+'/'+recordId;
	}*/

	private class CouponSellerWrapper {
		public String ceErrorMessage{get;set;}
		public List<Coupon_Seller__c> listCouponSeller{ get; set;}
	}

	/*********************************************************************************************************************************
  @ Class:          UploadController.CohortSellerImport
  @ Version:        1.0
  @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
  @ Purpose:        US-0013870 - Change cohort bulk upload file to new Bulk Upload type (like we have for coupons)
  ----------------------------------------------------------------------------------------------------------------------------------
  @ Change history:  21.07.2023 / Sovantheany Dim / Created the class.
  @ 			  :  22.09.2023 / Sophal Noch / US-0014118
  *********************************************************************************************************************************/
  public class CohortSellerImport implements Callable {
		// implement callable so it be called dynamically from ExcelImporterController.serverSidePreDMLCheck
	
		/*********************************************************************************************************************************
		@ Method:         importCohortSellerPreDML
		@ Version:        1.0
		@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
		@ Purpose:        US-0013870 - Change cohort bulk upload file to new Bulk Upload type (like we have for coupons)
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history: 21.07.2023 / Sovantheany Dim / Created the method.
		@ 			    : 22.09.2023 / Sophal Noch / US-0014118
		@				: 24.09.2024/ vadhanak voun/ US-0015465 - Cohort bulk upload - fail scenario messages
		*********************************************************************************************************************************/		
		@testVisible
		private Map<String,Object> importCohortSellerPreDML(Map<String,Object> mapArgs){

			//NK:24/09/2024:US-0015465
			//The very first validation failed - Header column validation
			Boolean neeHeaderValidation = (Boolean)mapArgs.get('vadlidateHeader');
			neeHeaderValidation = neeHeaderValidation == null ? false : neeHeaderValidation;
			if(neeHeaderValidation && !validateHeader(mapArgs))
			{	
				String templateLInk = (String)mapArgs.get('templateLink');
				return new Map<String,Object>{'status' => 'ko',	
					'error' => System.Label.UploadCohort_ErrMsg_InvalidColName.replace('{0}',templateLInk+'')
				};
			} 
			Map<String, Object> mapResult =  new Map<String, Object>();
			List<Map<String,String>> listRecord = (List<Map<String,String>>)(JSON.deserialize(JSON.serialize(mapArgs.get(TXT_LIST_RECORD)), List<Map<String,String>>.class));

			Integer startIndex = Integer.valueOf(mapArgs.get(TXT_START_INDEX));

			String bobId  =  String.valueOf(mapArgs.get('parentId'));			
			//Bob__c bob = [Select Id, RecordType.DeveloperName From Bob__c Where Id =: bobId Limit 1]; // 22.09.2023 / Sophal Noch / US-0014118
			//NK:24/09/2024:US-0015465
			Bob__c bob = ((Bob__c[])ApexSafe.query().doQuery('Select Id, RecordType.DeveloperName From Bob__c Where Id =: bobId Limit 1', new Map<String, Object>{'bobId' => bobId}))[0];
			
			Map<Integer, String> mapIndexToErrMsg = new  Map<Integer, String>();
			Map<String,Account> mapSeller = new Map<String,Account>();
			Set<String> setOracleId = new Set<String>();
			Set<String> setFederationId = new Set<String>();
			Set<String> sellerIds = new Set<String>();
			Map<String,String> mapFederate = new Map<String,String>();

			for(Map<String,String> mapObj : listRecord){
				String oracleId = mapObj.get('oracle_id__c');
				// String parentOracleId = mapObj.get('parent_seller__c');
				String federationIdACManager = mapObj.get(BS_FLD_ACC_MGN); //  07.07.2025 / Sophal Noch / US-0032982 : change string literals to constant
				// String federationIdSecondAM = mapObj.get('ttec_manager__c');
				if(String.isNotBlank(oracleId)) setOracleId.add(oracleId);
				// if(String.isNotBlank(parentOracleId)) setOracleId.add(parentOracleId);
				if(String.isNotBlank(federationIdACManager)) setFederationId.add(federationIdACManager);
				// if(String.isNotBlank(federationIdSecondAM)) setFederationId.add(federationIdSecondAM);

				if(bob.RecordType.DeveloperName == BOB_LTTM_RECORDTYPE){ // 22.09.2023 / Sophal Noch / US-0014118 : field to be populated for Lttm

					String parentOracleId = mapObj.get('parent_seller__c');
					if(String.isNotBlank(parentOracleId)) setOracleId.add(parentOracleId);
					String federationIdSecondAM = mapObj.get(BS_FLD_TTEC_MGN); //  07.07.2025 / Sophal Noch / US-0032982 : change string literals to constant
					if(String.isNotBlank(federationIdSecondAM)) setFederationId.add(federationIdSecondAM);

				}else if(bob.RecordType.DeveloperName == BOB_ADS_RECORDTYPE){ // 22.09.2023 / Sophal Noch / US-0014118 : field to be populated for Advertising 

					String federationIdAdsManager = mapObj.get('ads_partner_manager__c');
					if(String.isNotBlank(federationIdAdsManager)) setFederationId.add(federationIdAdsManager);

				}
			}
			
			String soql_SELLER4Cohort = 'Select EBH_BOBManaged__c,Outreach_Manager__c, Id,EBH_OracleID__c From Account ' ;
			String sWhere = ' where EBH_OracleID__c IN: setOracleId and RecordType.DeveloperName =: SELLER_RECORDTYPE';
			//for(Account es: Database.query(SOQL_SELLER+sWhere)){ 
			//NK:24/09/2024:US-0015465
			for(Account es: (Account[])ApexSafe.query().doQuery(soql_SELLER4Cohort+sWhere,new Map<String, Object>{'setOracleId' => setOracleId, 'SELLER_RECORDTYPE' => SELLER_RECORDTYPE}))
			{			
				mapSeller.put(es.EBH_OracleID__c,es);
				sellerIds.add(es.Id);
			}
			// for(User user : [Select Id, FederationIdentifier From User Where FederationIdentifier IN: setFederationId]){
			for(User user : (User[])ApexSafe.query().doQuery('Select Id, FederationIdentifier From User Where IsActive=TRUE AND FederationIdentifier IN: setFederationId',new Map<String, Object>{'setFederationId' => setFederationId}))
			{
				mapFederate.put(user.FederationIdentifier, user.Id);
			}

			// RecordType lttmRecordType = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
			// 22.09.2023 / Sophal Noch / US-0014118 : populate cohort seller record type depending on parent bob record type
			RecordType bsRecortType;
			if(bob.RecordType.DeveloperName == BOB_LTTM_RECORDTYPE){
				bsRecortType = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
			}else if(bob.RecordType.DeveloperName == BOB_ADS_RECORDTYPE){
				bsRecortType = ApexUtil.getRecordTypeByName('BoB_Seller__c','Advertising');
			}

			for(Integer i = 0; i < listRecord.size(); i++){
				String errMsg = '';
				Integer rowIndex = startIndex + i;
				Integer rowNum = rowIndex + 1;
				
				String oracaleId = listRecord[i].get('oracle_id__c');
				String uniqueKey = bobId+'_'+oracaleId;
				
				listRecord[i].put('BoB__c', bobId);
				listRecord[i].put('Unique_Id__c', uniqueKey);
				// listRecord[i].put('RecordTypeID', lttmRecordType.Id);
				listRecord[i].put('RecordTypeID', bsRecortType.Id); // 22.09.2023 / Sophal Noch / US-0014118

				//Oracle Id
				Account seller = mapSeller.get(oracaleId);
				String sellerId = seller?.Id;
				if(sellerId == null){
					//NK:24/09/2024:US-0015465
					// errMsg = String.format(ERROR_TXT_ORACLE_ID_NOT_FOUND, new String[]{(oracaleId != null ? oracaleId : ''), String.valueOf(rowNum)});
					errMsg = String.format(System.Label.UploadCohort_ErrMsg_InvalidOracle, new String[]{(oracaleId != null ? oracaleId : ''), String.valueOf(rowNum)});					
					mapIndexToErrMsg.put(rowIndex, errMsg); continue;
				}else{
					listRecord[i].put('Seller__c', sellerId);
				}

				//Account Manager User ID
				String corpAccManagerId = listRecord[i].get(BS_FLD_ACC_MGN); //  07.07.2025 / Sophal Noch / US-0032982 : change string literals to constant
				if(String.isNotBlank(corpAccManagerId)){
					String userAccManagerId = mapFederate.get(corpAccManagerId);
					if(String.isBlank(userAccManagerId)){
						//errMsg = String.format(ERROR_TXT_CORP_ID_NOT_FOUND, new String[]{(corpAccManagerId != null ? corpAccManagerId : ''), String.valueOf(rowNum)});
						//NK:24/09/2024:US-0015465
						errMsg = String.format(System.Label.UploadCohort_ErrMsg_InvalidCorp, new String[]{(corpAccManagerId != null ? corpAccManagerId : ''), String.valueOf(rowNum)});
						mapIndexToErrMsg.put(rowIndex, errMsg); continue;
					}else{
						listRecord[i].put(BS_FLD_ACC_MGN, userAccManagerId); //  07.07.2025 / Sophal Noch / US-0032982 : change string literals to constant
					}
				}else{
					if(bob.RecordType.DeveloperName == BOB_LTTM_RECORDTYPE){
						listRecord[i].put(BS_FLD_ACC_MGN, ''); //  07.07.2025 / Sophal Noch / US-0032982 : update to empty if value is not provided from excel
					}
				}

				if(bob.RecordType.DeveloperName == BOB_LTTM_RECORDTYPE){ // 22.09.2023 / Sophal Noch / US-0014118

					//Parent Seller Oracle Id
					String parentOracaleId = listRecord[i].get('parent_seller__c');
					if(String.isNotBlank(parentOracaleId)){
						Account parentSeller = mapSeller.get(parentOracaleId);
						String parentSellerId = parentSeller?.Id;
						if(parentSellerId == null){
							//NK:24/09/2024:US-0015465
							// errMsg = String.format(ERROR_TXT_ORACLE_ID_NOT_FOUND, new String[]{(parentOracaleId != null ? parentOracaleId : ''), String.valueOf(rowNum)});
							errMsg = String.format(System.Label.UploadCohort_ErrMsg_InvalidOracle, new String[]{(parentOracaleId != null ? parentOracaleId : ''), String.valueOf(rowNum)});
							mapIndexToErrMsg.put(rowIndex, errMsg); continue;
						}else{
							listRecord[i].put('parent_seller__c', parentSellerId);
						}
					}

					//Secondary AM User ID
					String corp2AMId = listRecord[i].get(BS_FLD_TTEC_MGN); //  07.07.2025 / Sophal Noch / US-0032982 : change string literals to constant
					if(String.isNotBlank(corp2AMId)){
						String user2AMId = mapFederate.get(corp2AMId);
						if(String.isBlank(user2AMId)){
							//NK:24/09/2024:US-0015465
							// errMsg = String.format(ERROR_TXT_CORP_ID_NOT_FOUND, new String[]{(corp2AMId != null ? corp2AMId : ''), String.valueOf(rowNum)});
							errMsg = String.format(System.Label.UploadCohort_ErrMsg_InvalidCorp, new String[]{(corp2AMId != null ? corp2AMId : ''), String.valueOf(rowNum)});
							mapIndexToErrMsg.put(rowIndex, errMsg); continue;
						}else{
							listRecord[i].put(BS_FLD_TTEC_MGN, user2AMId); //  07.07.2025 / Sophal Noch / US-0032982 : change string literals to constant
						}
					}else{
						listRecord[i].put(BS_FLD_TTEC_MGN, ''); //  07.07.2025 / Sophal Noch / US-0032982 : update to empty if value is not provided from excel
					}

					//Managed Segment
					String managedSegment = listRecord[i].get('ebh_bobsegment__c');
					if(String.isNotBlank(managedSegment)){
						if(MAP_MANAGED_SEGMENT_PKVAL.containsKey(managedSegment)) managedSegment = MAP_MANAGED_SEGMENT_PKVAL.get(managedSegment);//LA-03-11-2022-US-0012749
						listRecord[i].put('ebh_bobsegment__c', managedSegment);
					}

				}else if(bob.RecordType.DeveloperName == BOB_ADS_RECORDTYPE){ // 22.09.2023 / Sophal Noch / US-0014118

					String corpAdsManagerId = listRecord[i].get('ads_partner_manager__c');
					if(String.isNotBlank(corpAdsManagerId)){
						String userAccManagerId = mapFederate.get(corpAdsManagerId);
						if(String.isBlank(userAccManagerId)){
							//NK:24/09/2024:US-0015465
							// errMsg = String.format(ERROR_TXT_CORP_ID_NOT_FOUND, new String[]{(corpAdsManagerId != null ? corpAdsManagerId : ''), String.valueOf(rowNum)});
							errMsg = String.format(System.Label.UploadCohort_ErrMsg_InvalidCorp, new String[]{(corpAdsManagerId != null ? corpAdsManagerId : ''), String.valueOf(rowNum)});
							mapIndexToErrMsg.put(rowIndex, errMsg); continue;
						}else{
							listRecord[i].put('ads_partner_manager__c', userAccManagerId);
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
		@ Method:         validateHeader
		@ Version:        1.0
		@ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
		@ Purpose:        US-0015465 - Cohort bulk upload - fail scenario messages
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history:  25.09.2024 / vadhanak voun / Created the method.
		*********************************************************************************************************************************/
		private Boolean validateHeader(Map<String,Object> mapArgs)
		{
			//Map<String, Object> mapResult = null;
			List<String> listHeaderMeta = (List<String>)(JSON.deserialize(JSON.serialize(mapArgs.get('colHeadersMeta')), List<String>.class));
			List<String> listHeaderExel = (List<String>)(JSON.deserialize(JSON.serialize(mapArgs.get('colHeadersExcel')), List<String>.class));
			system.debug('listHeaderMeta: '+listHeaderMeta);
			system.debug('listHeaderExel: '+listHeaderExel);
			if((listHeaderMeta==null || listHeaderExel ==null) || (listHeaderMeta!=null &&  listHeaderExel !=null && String.join(listHeaderMeta,'').trim() != String.join(listHeaderExel,'').trim()))
			{
				return false;
			}
			return true;
		}

		/*********************************************************************************************************************************
		@ Method:         call
		@ Version:        1.0
		@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
		@ Purpose:        US-0013870 - Change cohort bulk upload file to new Bulk Upload type (like we have for coupons)
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history:  21.07.2023 / Sovantheany Dim / Created the method.
		*********************************************************************************************************************************/
		public Object call(String action, Map<String, Object> args) {
			// when class is implemented Callable, method "call" must also be implement.
			if(action == TXT_IMPORT_COHORT_SELLER_PRE_DML) { return this.importCohortSellerPreDML(args);}
			else{throw new CallableClassException(TXT_METHOD_NOT_IMPLEMENTED);}
		}
	}

	
	/*********************************************************************************************************************************
	@ Class:          UploadController.NominatedItemImport
	@ Version:        1.0
	@ Author:         Mony Nou (mony.nou@gaea-sys.com)
	@ Purpose:        US-0013630 - Bulk Upload FVF, replace it with xl copy, paste feature
	@					- implement callable so it be called dynamically from ExcelImporterController.serverSidePreDMLCheck
	----------------------------------------------------------------------------------------------------------------------------------
	@ Change history:  14.08.2023 / Mony Nou / Created the class.
	*********************************************************************************************************************************/
	public class NominatedItemImport implements Callable { 

		/*********************************************************************************************************************************
		@ Method:         importNominatedItemPreDML
		@ Version:        1.0
		@ Author:         Mony Nou (mony.nou@gaea-sys.com)
		@ Purpose:        US-0013630 - Bulk Upload FVF, replace it with xl copy, paste feature
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history:  14.08.2023 / Mony Nou / Created the method.
		@				   06.09.2023 / Mony Nou / US-0014119 - FVF Bulk Upload functionality is failing
		*********************************************************************************************************************************/
		@testVisible
		private Map<String,Object> importNominatedItemPreDML(Map<String,Object> mapArgs){

			Map<String, Object> mapResult = new Map<String, Object>();
			List<Map<String,String>> listRecord = (List<Map<String,String>>)(JSON.deserialize(JSON.serialize(mapArgs.get(TXT_LIST_RECORD)), List<Map<String,String>>.class));

			Integer startIndex = Integer.valueOf(mapArgs.get(TXT_START_INDEX));
			String formattedValue = SAMPLE_DECIMAL_VALUE.format(); // example: value = 1000.10. User Locale DE,  it is formatted to 1000,10. User Locale EN, It is formatted to 1000.10
        	String decimalPoint = formattedValue.substring(5,6); // get the decimal point from formatted price.
			
			String fvfId  =  String.valueOf(mapArgs.get('parentId'));
			
			Map<Integer, String> mapIndexToErrMsg = new  Map<Integer, String>();
			// Map<Integer, String> mapIndexToInforMsg = new  Map<Integer, String>();
			Map<Integer, List<String>> mapIndexToErrMsgs = new  Map<Integer, List<String>>();
			Set<String> setListingIds = new Set<String>();
			Map<String, String> mapExistListingId = new Map<String, String>();
			Map<String, Integer> mapListingIdWithIndex = new Map<String, Integer>();

			for(Integer i = 0; i < listRecord.size(); i++) {

				String errMsg = '';
				Integer rowIndex = startIndex + i;
				Integer rowNum = rowIndex + 1;

				//Validate listing_id_w__c
				String listingId = listRecord.get(i).get('listing_id_w__c');
				if(!listingId.isNumeric() || (listingId.length() < 9 || listingId.length() > 16)){

					errMsg = String.format(Label.UPLOADING_INVALID_LISTINGID_MSG, new String[]{(listingId != null ? listingId : ''), String.valueOf(rowNum)});
					mapIndexToErrMsg.put(rowIndex, errMsg); 
					if (!mapIndexToErrMsgs.containsKey(rowIndex)) mapIndexToErrMsgs.put(rowIndex, new List<String>());
					mapIndexToErrMsgs.get(rowIndex).add(errMsg);
				}
				else if (setListingIds.contains(listingId)) {
					
					errMsg = Label.UPLOADING_EXCEL_DUPLICATEID_MSG;
					errMsg = errMsg.replace('X', String.valueOf(mapListingIdWithIndex.get(listingId))).replace('Y', String.valueOf(rowNum));
					mapIndexToErrMsg.put(rowIndex, errMsg); 

					if (!mapIndexToErrMsgs.containsKey(rowIndex)) mapIndexToErrMsgs.put(rowIndex, new List<String>());
					mapIndexToErrMsgs.get(rowIndex).add(errMsg);
				} 
				else {

					setListingIds.add(listingId);
					mapListingIdWithIndex.put(listingId, (rowIndex + 1));
				}

				//Validate price_target_w__c
				String priceTarget = listRecord.get(i).get('price_target_w__c');
				priceTarget = priceTarget.trim();
				if((priceTarget != priceTarget.replaceAll('[^0-9.,]', '')) || (decimalPoint == '.' && priceTarget.contains(',')) || (decimalPoint == ',' && priceTarget.contains('.'))){

					errMsg = String.format(ERROR_TXT_INVALID_PRICE_FORMAT, new String[]{(priceTarget != null ? priceTarget : ''), String.valueOf(rowNum)});
					mapIndexToErrMsg.put(rowIndex, errMsg);
					if (!mapIndexToErrMsgs.containsKey(rowIndex)) mapIndexToErrMsgs.put(rowIndex, new List<String>());
					mapIndexToErrMsgs.get(rowIndex).add(errMsg);
				
				} 
				else { //MN-06092023-US-0014119: Fixing error uploading with "," as decimal points for EU countries
					
					priceTarget = decimalPoint == ',' ? priceTarget.replace(',','.') : priceTarget; //convert number with format to system number
					listRecord[i].put('price_target_w__c', priceTarget);
				}

				if (mapIndexToErrMsgs.containsKey(rowIndex) && !mapIndexToErrMsgs.get(rowIndex).isEmpty()) mapIndexToErrMsg.put(rowIndex, String.join(mapIndexToErrMsgs.get(rowIndex), '<br/>'));

				listRecord[i].put('Final_Value_Fee_FVF__c', fvfId);
			}

			//Check the uploaded ListingID against the existed records
			for (Nominated_Item__c ni : [SELECT Listing_ID_w__c FROM Nominated_Item__c WHERE Final_Value_Fee_FVF__c =:fvfId AND Listing_ID_w__c IN:setListingIds]) {
				mapExistListingId.put(ni.Listing_ID_w__c, ni.Id);
			}

			if (!mapExistListingId.isEmpty()) {
				
				for(Integer i = 0; i < listRecord.size(); i++) {
					
					Integer rowIndex = startIndex + i;
					Integer rowNum = rowIndex + 1;

					String listingId = listRecord.get(i).get('listing_id_w__c');
					if (mapExistListingId.containsKey(listingId)) {
						listRecord.get(i).put('Id',mapExistListingId.get(listingId));
					}
					
				}

				String tmp = Label.UPLOADING_EXISTING_DUPLICATEID_MSG + '\n';
				mapResult.put('showConfirm',tmp);
				
			}

			mapResult.put(TXT_STATUS,'ok');
			mapResult.put(TXT_LIST_RECORD,listRecord);
			mapResult.put(TXT_MAP_INDEX_TO_ERROR_MSG,mapIndexToErrMsg);
			mapResult.put(TXT_MAP_EXISTING_LISTINGID,mapExistListingId);
			
			return mapResult;

		}

		/*********************************************************************************************************************************
		@ Method:         call
		@ Version:        1.0
		@ Author:         Mony Nou (mony.nou@gaea-sys.com)
		@ Purpose:        US-0013630 - Bulk Upload FVF, replace it with xl copy, paste feature
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history:  14.08.2023 / Mony Nou / Created the method.
		*********************************************************************************************************************************/
		public Object call(String action, Map<String, Object> args) {
			// when class is implemented Callable, method "call" must also be implement.
			if(action == TXT_IMPORT_NOMINATED_ITEM_PRE_DML) { return this.importNominatedItemPreDML(args);}
			else{throw new CallableClassException(TXT_METHOD_NOT_IMPLEMENTED);}
		}

	}

	private class CallableClassException extends Exception {}
	
}