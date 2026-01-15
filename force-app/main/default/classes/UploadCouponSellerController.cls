/*********************************************************************************************************************************
@ Method:         UploadCouponSellerController
@ Version:        1.0
@ Author:         Chetra Sarom (chetra.sarom@gaea-sys.com)
@ Purpose:        US-0012713 - Seller Bulk Upload functionality - Extend excel copy paste feature
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  01.02.2023 / Chetra Sarom / Created the method.
@               :  02.03.2023 / Sophal Noch / US-0013300 - Missing Validation Rule in Bulk Upload Coupon Seller Component
@               :  20.04.2023 / Sambath Seng / US-0013273 - [AU Launch] Coupon Seller Validations
@               :  05.05.2034 / Sophal Noch / US-0013620 - Bulk Upload Coupon Seller feature behaving strangely
@               :  02.06.2023 / Sophal Noch / US-0012597 - [IT] Accessibility Configurations - Cannot deploy before launch
@               :  12.06.2023 / Sophal Noch / US-0013666 - Ability to restrict number of items per seller to be uploaded against item based coupon
@               :  07.12.2023 / Mony Nou / US-0014106 - UX Changes for Coupon Seller Bulk Upload Component v2
@               :  09.01.2024 / LoumAng SENG / US-0014561 - Coupon Seller - Record Trigger Flow - After Context   -Exception
@               :  29.01.2024 / Mony Nou / US-0014758 - Share% column should accept decimal values on Bulk Upload Coupon Seller Component
@               :  27.02.2024 / SRONG TIN / US-0014840 - Ability to download errors at step 2 for Bulk Seller Upload
@               :  14.03.2024 / Srong Tin / US-0014857 - Auto generate Coupon Seller - Navigate to Seller Tool
@               :  22.04.2024 / Mony Nou / US-0015008 - Map Hive Coupon and Category fields to Sales Tool
@				:  22.04.2024/ Veenus Gollapalli / US-0015068 - Auto populate Coupon Seller Owner on bulk upload
@               :  29.04.2024 / Loumang SENG / US-0014956 - Auto enable SP eligibility(AC2)
@               :  28.04.2025 / Loumang SENG / US-0016656 - Improve the "Bulk Contract Send" process for Coupon Sellers to process as many eligible records as possible
@				:  30.04.2025 / Sothea Horn / US-0017159 - Replace OwnerId with Account_Manager__c for Coupon Related Class
*********************************************************************************************************************************/

public with sharing class UploadCouponSellerController implements Callable{
    private static final String TXT_START_INDEX = 'startIndex';
    private static final String TXT_IMPORT_COUPON_SELLER = 'importCSPreDML';
    private static final String TXT_METHOD_NOT_IMPLEMENTED = 'Method not implemented';
    private static final String TXT_STATUS = 'status';
    private static final String TXT_LIST_RECORD = 'listRecord';
    private static final String TXT_MAP_INDEX_TO_ERROR_MSG = 'mapIndexToErrMsg';
    private static final String ERROR_TXT_ORACLE_ID_NOT_FOUND = 'Oracle Id Not Found: "{0}" At Row: {1} in excel file'; //MN-19122023-US-0014106 Added "in excel file" to the end of the error message

    //private final static String SOQL_COUPON_SELLER_2 = 'Select Coupon__r.Couponsite_s__c,Seller__r.Strategic_Seller_Share_w__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Language__c, Date_4days_Sent__c, Date_34_days_Sent__c, TriggerEmailManhattan__c, Id,Seller__c,Seller__r.EBH_OracleID__c,Coupon__c,Coupon_Seller_Stage__c,Coupon__r.RecordTypeID,Coupon__r.RecordType.DeveloperName,Coupon__r.Stage__c,SellerShareHolder__c From Coupon_Seller__c' ;
    // private final static String SOQL_COUPON_SELLER = 'Select Coupon__r.Coupon_Subtitle_Copy__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Contract_Language__c,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ;
    private final static String SOQL_COUPON = 'Select Id, Main_Coupon_Site__c, RecordType.DeveloperName FROM Coupon__c'; //MN-29062022-US-0011760-Added Main_Coupon_Site__c
    // 30/04/2025 US-0017159 - Replace OwnerId with Account_Manager__c
    private final static String SOQL_SELLER = 'Select EBH_Status__c,Owner.IsActive,Outreach_Manager__r.IsActive,EBH_BOBManaged__c,Account_Manager__c,Account_Manager__r.IsActive,Outreach_Manager__c, Coupon_Promotions_Participation__c, Coupon_Promotion_Types__c, Coupon_Discount_Rate__c, Coupon_Funding_Preference__c, Id,EBH_OracleID__c, SP_Coupons__c, EBH_RevRollup__c, Seller_Portal_Group__r.SP_Coupons__c From Account ' ;
    private final static String SOQL_USER = 'select Id, FederationIdentifier,IsActive from User';
    private final static String SOQL_COUPON_SELLER = 'Select Id, Coupon__c, Seller__c, Seller__r.EBH_Status__c, Seller__r.EBH_OracleID__c From Coupon_Seller__c';

    private final static String POPCPN_RECTYPE = 'Pop_Coupon';
    private final static String COUPONSELLER_MANHATTAN_RECORDTYPE = 'Manhattan_Coupon';

    private final static set<String> SPOP_COUPON_STAGE = new set<String>{'Declined','Contract Appended','Contract Terminated'};
    
    private static final String NA_PROFILE = 'NA Standard User Base'; //MN-29062022-US-0011760


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
    private final static String SELLER_REVROLLUP_AU = 'AU'; //SB 20.04.2023 US-0013273 - [AU Launch] Coupon Seller Validations

    //MN-29062022-US-0011760
    private static final String NAprofile = ApexUtil.getProfileByName(NA_PROFILE).Id;
    private static final Boolean isNA = UserInfo.getProfileId().equals(NAprofile);
    //END - MN-29062022-US-0011760

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
		SELLER_REVROLLUP_UK, //MN-15122022-US-0012734
		SELLER_REVROLLUP_AU //SB 20.04.2023 US-0013273 - [AU Launch] Coupon Seller Validations
	};
	//END BR-03-11-2022-US-0012744

    //MN-15122022-US-0012734
	private static final String COUPONSITE_US = 'ebay.com'; 
	private final static String COUPONSITE_DE = 'ebay.de'; 
	private final static String COUPONSITE_UK = 'ebay.co.uk'; 
	private final static String COUPONSITE_FR = 'ebay.fr'; //MN-11012023-US-0012694
    private final static String COUPONSITE_AU = 'ebay.com.au'; //SB 20.04.2023 US-0013273 - [AU Launch] Coupon Seller Validations
    private final static String COUPONSITE_IT = 'ebay.it'; //SP-02062023-US-0012597
	private final static String COUPONSITE_ES = 'ebay.es';//SRONG TIN 14.03.2024 US-0014857


    private final static String FLD_APINAME_ITEM_LIMIT = 'item_limit__c'; // 12.06.2023 / Sophal Noch / US-0013666

    //SRONG TIN 14.03.2024 US-0014857
    private final static Map<String, String> COUPON_MAINSITE_MAPPING = new Map<String, String> {
        COUPONSITE_DE => 'DE',
        COUPONSITE_UK => 'UK',
        COUPONSITE_FR => 'FR',
        COUPONSITE_IT => 'IT',
        COUPONSITE_AU => 'AU',
        COUPONSITE_ES => 'ES',
        COUPONSITE_US => 'US'      
    };

    private final static String SELLER_STATUS_CONFIRMED = 'Confirmed';//LA-23-04-2025-US-0016656

    /*********************************************************************************************************************************
    @ Method:         importCSPreDML
    @ Version:        1.0
    @ Author:         Chetra Sarom (chetra.sarom@gaea-sys.com)
    @ Purpose:        US-0012713 - Seller Bulk Upload functionality - Extend excel copy paste feature
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.02.2023 / Chetra Sarom / Created the method.
    @               :  02.03.2023 / Sophal Noch / US-0013300 - Missing Validation Rule in Bulk Upload Coupon Seller Component
    @               :  20.04.2023 / Sambath Seng / US-0013273 - [AU Launch] Coupon Seller Validations
    @               :  05.05.2034 / Sophal Noch / US-0013620 - Bulk Upload Coupon Seller feature behaving strangely
    @               :  02.06.2023 / Sophal Noch / US-0012597 - [IT] Accessibility Configurations - Cannot deploy before launch
    @               :  12.06.2023 / Sophal Noch / US-0013666 - Ability to restrict number of items per seller to be uploaded against item based coupon
    @               :  07.12.2023 / Mony Nou / US-0014106 - UX Changes for Coupon Seller Bulk Upload Component v2
    @               :  09.01.2024 / LoumAng SENG / US-0014561 - Coupon Seller - Record Trigger Flow - After Context   -Exception
    @               :  27.02.2024 / SRONG TIN / US-0014840 - Ability to download errors at step 2 for Bulk Seller Upload
    @			    : 30.04.2025 / Sothea Horn / US-0017159 - Replace OwnerId with Account_Manager__c for Coupon Related Class
    *********************************************************************************************************************************/
    @testVisible
    private Map<String,Object> importCSPreDML(Map<String,Object> mapArgs){

        Map<String, Object> mapResult = new Map<String, Object>();
        List<Map<String,String>> listRecord = (List<Map<String,String>>)(JSON.deserialize(JSON.serialize(mapArgs.get(TXT_LIST_RECORD)), List<Map<String,String>>.class));

        Integer startIndex = Integer.valueOf(mapArgs.get(TXT_START_INDEX));

        String couponId  =  String.valueOf(mapArgs.get('parentId'));

        Boolean hasHeader = Boolean.valueOf(mapArgs.get('hasHeader')); //MN-19122023-US-0014106
        Boolean isExcelImporterV2 =   Boolean.valueOf(mapArgs.get('isExcelImporterV2')); //MN-19122023-US-0014106

        Integer maxCoInvestPerCoupon = Integer.valueOf(Label.MAX_COINVEST_PER_COUPON);  // 12.06.2023 / Sophal Noch / US-0013666

        Map<Integer, String> mapIndexToErrMsg = new  Map<Integer, String>();
        
        Set<String> sellerIds = new Set<String>();
        Set<String> setOracleId = new Set<String>();
        Set<String> setFederationId = new Set<String>();
        Map<String,Account> mapSeller = new Map<String,Account>();
        // Map<String,String> mapFederate = new Map<String,String>();//LA-09-01-2024-US-0014561
        Map<String,User> mapFederate = new Map<String,User>();//LA-09-01-2024-US-0014561
        // String errMsg = ''; // 05.05.2034 / Sophal Noch / US-0013620
        Coupon__c coupon = Database.query(SOQL_COUPON + ' where Id = :couponId');
        Boolean isNASite = (coupon.Main_Coupon_Site__c == COUPON_NA_SITE); //MN-29062022-US-0011760

        // List<String> lstOracleIdnRecUrl = new List<String>(); // SB 01.07.2022 US-0011998 AC1
 		
        for(Map<String,String> mapObj : listRecord){
            String oracleId = mapObj.get('oracle_id__c');
            String federationId = mapObj.get('ebh_couponsellerowner__c');
            if(String.isNotBlank(oracleId)) setOracleId.add(oracleId.trim()); //SRONG/27.02.2024/US-0014840
            if(String.isNotBlank(federationId)) setFederationId.add(federationId);
        }
        
        String sWhere = ' where EBH_OracleID__c IN: setOracleId and RecordType.DeveloperName = \'EBH_Seller\'';
        for(Account es: Database.query(SOQL_SELLER+sWhere)){ 
            mapSeller.put(es.EBH_OracleID__c,es);
            sellerIds.add(es.Id);
        }

        //LA-23-04-2025-US-0016656-ApexCRUDViolation -- START
        String sWhereUserCondition = ' Where FederationIdentifier IN: setFederationId';
        List<User> listUser = ApexSafe.query().secCheck(false).doQuery(SOQL_USER+sWhereUserCondition, new Map<String, Object> {'setFederationId' => setFederationId});
        //for(User user : [Select Id, FederationIdentifier,IsActive From User Where FederationIdentifier IN: setFederationId]){
        //LA-23-04-2025-US-0016656-ApexCRUDViolation -- END
        for(User user : listUser){
            //mapFederate.put(user.FederationIdentifier, user.Id);//LA-09-01-2024-US-0014561
            mapFederate.put(user.FederationIdentifier, user);//LA-09-01-2024-US-0014561
            
        }

        // 02.03.2023 / Sophal Noch / US-0013300 : query coupon seller to get exist accounts to check for duplication. this validation is originated from user story US-0010617.
        Map<Id,Account> mapAccOfCSeller = new Map<Id,Account>();
        if(!sellerIds.isEmpty()){
            //LA-23-04-2025-US-0016656-ApexCRUDViolation -- START
            String sWhereCS = ' where Coupon__c =: couponId and Seller__c IN: sellerIds and RecordType.DeveloperName !=: POPCPN_RECTYPE';
            List<Coupon_Seller__c> listCouponSeller = ApexSafe.query().secCheck(false).doQuery(SOQL_COUPON_SELLER+sWhereCS, new Map<String, Object> {'couponId' => couponId, 'sellerIds' => sellerIds, 'POPCPN_RECTYPE' => POPCPN_RECTYPE});
            //for(Coupon_Seller__c cs : [Select Seller__c,Seller__r.EBH_Status__c, Seller__r.EBH_OracleID__c From Coupon_Seller__c  where Coupon__c =: couponId and Seller__c IN: sellerIds and (RecordType.DeveloperName !=: POPCPN_RECTYPE OR (RecordType.DeveloperName =: POPCPN_RECTYPE AND Coupon_Seller_Stage__c NOT IN: SPOP_COUPON_STAGE))]){
            
            for(Coupon_Seller__c cs : listCouponSeller){//LA-23-04-2025-US-0016656-ApexCRUDViolation -- START
                mapAccOfCSeller.put(cs.Seller__c, cs.Seller__r);
            }
        }
        
        for(Integer i = 0; i < listRecord.size(); i++){
            String errMsg = ''; // 05.05.2034 / Sophal Noch / US-0013620
            Integer rowIndex = startIndex + i; // each chunk of record/batch run this method, startIndex tracks where the current index of chunk of record/batch
            Integer rowNum = rowIndex + 1;

            listRecord[i].put('Coupon__c', couponId);
            String oracaleId = String.isNotBlank(listRecord[i].get('oracle_id__c'))?listRecord[i].get('oracle_id__c').trim():'';

            Account seller = mapSeller.get(oracaleId);
            String sellerId = seller?.Id;

            Boolean isSellerConfirmed = false;//LA-23-04-2025-US-0016656
            if(seller != null && (seller.EBH_Status__c == SELLER_STATUS_CONFIRMED)){ isSellerConfirmed = true; } //LA-23-04-2025-US-0016656

            
            if(sellerId == null){ // throw when seller is not found.
                Integer tmp = rowNum; //MN-19122023-US-0014106
                if(isExcelImporterV2 && hasHeader) tmp = rowNum + 1; //MN-19122023-US-0014106
                if(String.isBlank(oracaleId)){
                    //SRONG/27.02.2024/US-0014840
                    errMsg = String.format('Oracle ID '+Label.ExcelImporter_Label_9, new String[]{(oracaleId != null ? oracaleId : ''), String.valueOf(tmp)});
                }else{
                    errMsg = String.format(ERROR_TXT_ORACLE_ID_NOT_FOUND, new String[]{(oracaleId != null ? oracaleId : ''), String.valueOf(tmp)}); //MN-19122023-US-0014106: replace rowNum with tmp variable
                }
                
                mapIndexToErrMsg.put(rowIndex, errMsg); continue;
            }else{
                if(!isSellerConfirmed){//LA-23-04-2025-US-0016656
                    errMsg = Label.ErrorSellerStatusNotConfirmed;
                    mapIndexToErrMsg.put(rowIndex, errMsg); continue;
                }else{
                    listRecord[i].put('Seller__c', sellerId);
                }
            }

            // 12.06.2023 / Sophal Noch / US-0013666 : validate field item_limit__c value > 5000
            String itemLimit = listRecord[i].get(FLD_APINAME_ITEM_LIMIT);
            //MN-14122023-US-0014106: Added itemLimit.length() > 4 into below IF condition in case user entry value that is larger than the maximum value that an Integer can hold in Apex which is 2147483647. Ex: 6666666666
            if(String.isNotBlank(itemLimit) && itemLimit.isNumeric() && (itemLimit.length() > 4 || Integer.valueOf(itemLimit) > maxCoInvestPerCoupon)){
                mapIndexToErrMsg.put(rowIndex, Label.Error_CouponSeller_ItemLimit_MoreThan_5000); continue;
            }
            
            String federationId = listRecord[i].get('ebh_couponsellerowner__c');
            //LA-09-01-2024-US-0014561: Validate field ebh_couponsellerowner__c to prevent Inactive user
           // String userId = mapFederate.get(federationId);//LA-09-01-2024-US-0014561
           User user = mapFederate.get(federationId);//LA-09-01-2024-US-0014561
           if(user != null){
                if(!user.IsActive){ // /LA-09-01-2024-US-0014561 : Check Inactive User
                    listRecord[i].put('ebh_couponsellerowner__c',Userinfo.getUserId()); //LA-22-04-2024-US-0015068 :Auto populate Coupon Seller Owner on bulk upload
                }else{
                    listRecord[i].put('ebh_couponsellerowner__c', user.Id);
                }
            }else {
                if (isNA && isNASite) { //MN-29062022-US-0011760			
                    listRecord[i].put('ebh_couponsellerowner__c', Userinfo.getUserId());
                } else {
                    if(seller.EBH_BOBManaged__c){
                        if(String.isNotBlank(seller.Account_Manager__c) && !seller.Account_Manager__r.IsActive){ ///LA-09-01-2024-US-0014561: Check Inactive Seller Owner
                            listRecord[i].put('ebh_couponsellerowner__c',Userinfo.getUserId());//LA-22-04-2024-US-0015068:Auto populate Coupon Seller Owner on bulk upload
                        }else{
                            // 30/04/2025 - US-0017159 - Replace OwnerId with Account_Manager__c. If Account.Account_Manager__c has null value and we need value from it to populate other field, use value IntegrationUserId (0056A000000zaxM) to populate to other field
                            // listRecord[i].put('ebh_couponsellerowner__c', seller.OwnerId);
                            listRecord[i].put('ebh_couponsellerowner__c', String.isNotBlank(seller.Account_Manager__c) ? seller.Account_Manager__c : ApexUtil.INTEGRATION_USER_ID);
                        }
                    }else{ 
                        if(seller.Outreach_Manager__c != null){ ///LA-09-01-2024-US-0014561: Check Inactive Seller Outreach Manager
                            if(!seller.Outreach_Manager__r.IsActive){
                                listRecord[i].put('ebh_couponsellerowner__c',Userinfo.getUserId());//LA-22-04-2024-US-0015068:Auto populate Coupon Seller Owner on bulk upload
                            }else{
                                listRecord[i].put('ebh_couponsellerowner__c', seller.Outreach_Manager__c);
                            }
                            
                        }else{
                            listRecord[i].put('ebh_couponsellerowner__c',Userinfo.getUserId());
                        }
                    }
                }
            }
            

            String sellerShare = listRecord[i].get('sellershareholder__c');
			if (String.isNotBlank(sellerShare)) {
                
                //MN-07122023-US-0014106: AC2: Remove % sign from seller share so The system must accept funding split values to be uploaded with or without % character at the end
                sellerShare = sellerShare.replace('%', ''); 
                listRecord[i].put('sellershareholder__c', sellerShare);
                //--END

                /* MN-29012024-US-0014758: Comment this codes because We have to allow decimal value
                //MN-11122023-US-0014106: Check if Seller Share is valid number
                if (!sellerShare.isNumeric()) {
                    errMsg = 'Invalid number for Share%: ' + sellerShare + ' \n';
                    mapIndexToErrMsg.put(rowIndex, errMsg); continue; 
                }
                */ 
                
                try {//MN-29012024-US-0014758: Added try catch to handle invalid number

                    Decimal tmp = Decimal.valueOf(sellerShare);
                    if (tmp > 100){
                        errMsg = 'Seller share% should not be more than 100% \n';
                        mapIndexToErrMsg.put(rowIndex, errMsg); continue;
                    }
                    
                }catch(Exception ex) {
                    errMsg = 'Invalid number for Share%: ' + sellerShare + ' \n';
                    mapIndexToErrMsg.put(rowIndex, errMsg); continue; 
                }
                
			}

            //MN-11122023-US-0014106: Check if for valid number
            String ebayCoFundMax = listRecord[i].get('ebay_co_fund_max__c');
            if (String.isNotBlank(ebayCoFundMax) && !ebayCoFundMax.isNumeric()) {
                
                errMsg = 'Invalid number for eBay Co-fund Max: ' + ebayCoFundMax + ' \n';
                mapIndexToErrMsg.put(rowIndex, errMsg); continue; 
                            
            }
            
            if(String.isNotBlank(itemLimit) && !itemLimit.isNumeric()){
                errMsg = 'Invalid number for Item Limit: ' + itemLimit + ' \n';
                mapIndexToErrMsg.put(rowIndex, errMsg); continue; 
            }

            //--END

            //MN-15122022-US-0012734 - Move all fixed Main Coupon Site from below IF criteria into SET variable instead
            Set<String> sMainCouponSite = new Set<String>{
                COUPONSITE_DE,
                COUPONSITE_US,
                COUPONSITE_UK,
                COUPONSITE_FR, //MN-11012023-US-0012694
                COUPONSITE_AU, //SB 20.04.2023 US-0013273 - [AU Launch] Coupon Seller Validations
                COUPONSITE_IT  //SP-02062023-US-0012597
            };
            //START : LA-29-04-2024:US-0014956
            //String oracleIdRecUrl;
            
            //System.debug('error site >>>>>>>>>>>>>>>>'+seller.EBH_RevRollup__c);
            //MN-15122022-US-0012734 - Change criteria to use with multiple OR into checking with SET variable instead
			/*if (sMainCouponSite.contains(coupon.Main_Coupon_Site__c) && SET_REV_ROLL_UP.contains(seller.EBH_RevRollup__c) && (seller.SP_Coupons__c != SP_COUPON_FULL_ACCESS && seller.Seller_Portal_Group__r.SP_Coupons__c != SP_COUPON_ALLOWED)){
                //
                // lstOracleIdnRecUrl.add('<a class="errorMsg" href=\''+getSellerRecordUrl(seller.Id)+'\' target=\'_blank\'>'+seller.EBH_OracleID__c+'</a>');
                //lstOracleIdnRecUrl.add(seller.Id);
                
                // 02.03.2023 / Sophal Noch / US-0013300 : no need to store error message oracleIdRecUrl in list because we use mapIndexToErrMsg to store each row error message now.
                oracleIdRecUrl = '<a class="errorMsg" href=\''+getSellerRecordUrl(seller.Id)+'\' target=\'_blank\'>'+seller.EBH_OracleID__c+'</a>';
            }*/
            ////End SB 01.07.2022 US-0011998 AC1
            //END :LA-29-04-2024:US-0014956   
            //Start SB 01.07.2022 US-0011998 AC1
            // if(!lstOracleIdnRecUrl.isEmpty()){
            //START : LA-29-04-2024:US-0014956
            /*if(String.isNotBlank(oracleIdRecUrl)){
                String errorMsg = System.Label.Coupon_Eligibility_Error_Message;
                // errMsg = errorMsg.replace('{oracleId}', String.join(lstOracleIdnRecUrl, ', '));
                errMsg = errorMsg.replace('{oracleId}', oracleIdRecUrl);
                mapIndexToErrMsg.put(rowIndex, errMsg); continue;
            }*/
            //End SB 01.07.2022 US-0011998 AC1
            //END :LA-29-04-2024:US-0014956  
            //TH: 05/11/2021: US-0010617 - For Pop Coupon Seller with Stage__c = "contract appended" or "declined" or "contract terminated" , we don't need to check Duplicate seller
            // set<String> sPopCouponStage = new set<String>{'Declined','Contract Appended','Contract Terminated'};
            // String whereCs = ' where Coupon__c =: couponId and Seller__c IN: sellerIds and (RecordType.DeveloperName !=: POPCPN_RECTYPE OR (RecordType.DeveloperName =: POPCPN_RECTYPE AND Coupon_Seller_Stage__c NOT IN: sPopCouponStage))';
            // List<Coupon_Seller__c> lstCsSeller = Database.query(SOQL_COUPON_SELLER_2+whereCs);
            // if(!lstCsSeller.isEmpty()){
                
            Account accOfCS = mapAccOfCSeller.get(sellerId); // 02.03.2023 / Sophal Noch / US-0013300
            if(accOfCS != null){

                //TH:26/11/2021:move to custom label
                //error += 'You cannot add the same seller to the same coupon twice. Some sellers couldn\'t be uploaded:\n';
                errMsg += System.label.msg_duplicateCouponSeller+'\n';
                // for(Coupon_Seller__c cSeller : lstCsSeller){
                //     errMsg += cSeller.Seller__r.EBH_OracleID__c+'\n';
                // }
                errMsg += accOfCS.EBH_OracleID__c; // 02.03.2023 / Sophal Noch / US-0013300
                mapIndexToErrMsg.put(rowIndex, errMsg); continue;
            }        
        }


        mapResult.put(TXT_STATUS,'ok');
        mapResult.put(TXT_LIST_RECORD,listRecord);
        mapResult.put(TXT_MAP_INDEX_TO_ERROR_MSG,mapIndexToErrMsg);
        return mapResult;
    }


    /*****************************************************************************************************************************
    @ Method:       getCouponCategories
    @ Author:       SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:      US-0014857 - Auto generate Coupon Seller - Navigate to Seller Tool
    @ Event:		
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	parentId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.03.2024  / SRONG TIN / Created the method.
    @*****************************************************************************************************************************/
    
    /* MN-22042024-US-0015008: Comment this method because it's not used
    @AuraEnabled
    public static Map<String, Object> getCouponCategories(String parentId){
        
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            String categories = '';
            String couponMinSite = '';
            List<Coupon__c> coupons = [select Id, Main_Coupon_Site__c, (select Id from Coupon_Categories__r limit 1) from Coupon__c where Id =:parentId];
            couponMinSite = COUPON_MAINSITE_MAPPING.get(coupons[0].Main_Coupon_Site__c);
            if(!coupons[0].Coupon_Categories__r.isEmpty()){
                List<String> listCategory = new List<String>();
                for (AggregateResult aggres : [select Category__r.Name cat_name from Coupon_Category__c Where Coupon__c =:parentId group by Category__r.Name]) {
                    listCategory.add(String.valueOf(aggres.get('cat_name')));
                }
                categories = String.join(listCategory,',');
            }
            mapResult.put('couponMinSite', couponMinSite);
            mapResult.put('couponCategories', categories);
            mapResult.put('status', 'ok');
        }catch(Exception ex){mapResult.put('status','ko'); mapResult.put('error',ex.getMessage()); return mapResult;}

        return mapResult;
        
    }
    */

    /*****************************************************************************************************************************
    @ Method:       generateSellerToolURLParam
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      US-0015008 - Map Hive Coupon and Category fields to Sales Tool
    @ Event:		
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	couponId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.04.2024  / Mony Nou / Created the method.
    @*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> generateSellerToolURLParam(String couponId) {

        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            String couponMinSite = '';
            String couponCode = '';
            String query_coupon = 'select Coupon_ID__c, Main_Coupon_Site__c, (select Id from Coupon_Categories__r limit 1) from Coupon__c where Id =:cpId';
            List<Coupon__c> coupons = (List<Coupon__c>) ApexSafe.query().doQuery(query_coupon,new Map<String, Object> {'cpId' => couponId});
            
            couponMinSite = (coupons[0].Main_Coupon_Site__c == COUPONSITE_US)?'0':ApexUtil.MAP_COUNTRY_CODE.get(COUPON_MAINSITE_MAPPING.get(coupons[0].Main_Coupon_Site__c));
            couponCode = coupons[0].Coupon_ID__c;

            if(!coupons[0].Coupon_Categories__r.isEmpty()){

                String query_category = 'select id, Category__r.Level__c, Category__r.Name, Category__r.Note_ID__c, Category__r.Note_ID__r.Name, Category__r.Note_ID__r.Note_ID__r.Name, Category__r.Note_ID__r.Note_ID__r.Note_ID__r.Name from Coupon_Category__c where Coupon__c =:cpId and Category__r.Level__c >=1 and Category__r.Level__c  <=4 order by Category__r.Level__c';
                List<Coupon_Category__c> lstCategories = (List<Coupon_Category__c>) ApexSafe.query().doQuery(query_category,new Map<String, Object> {'cpId' => couponId});
                Map<Integer, Set<String>> mLevelCategories = new Map<Integer, Set<String>>{
                    1 => new Set<String>(), //meta
                    2 => new Set<String>(), //l2
                    3 => new Set<String>(), //l3
                    4 => new Set<String>()  //l4
                };

                for (Coupon_Category__c cat : lstCategories) {
                    
                    Integer cur_level = Integer.valueOf(cat.Category__r.Level__c);
                    mLevelCategories.get(cur_level).add(cat.Category__r.Name); //Add current level


                    /*
                        If Category level = 4 then
                            - Add parent level 3 (cur_level - 1) 
                            - Add parent level 2 (cur_level - 2)
                            - Add parent level 1 [Meta] (cur_level - 3)
                        If Category level = 3 then
                            - Add parent level 2 (cur_level - 1)
                            - Add parent level 1 [Meta] (cur_level - 2)
                            - The thired IF Condition won't sastisfied => skip
                        If Category level = 2 then
                            - Add parent level 1 [Meta] (cur_level - 1)
                            - The second IF Condition won't sastisfied => skip
                            - The thired IF Condition won't sastisfied => skip
                        If Category level = 1 then
                            - Do nothing because it doesn't sastisfied below IF condition
                    */
                    if (mLevelCategories.containsKey(cur_level - 1) && String.isNotBlank(cat.Category__r.Note_ID__r.Name)) { //Check heirachy node 1 (Ex: if current category level = 4 => check category level 3)
                        mLevelCategories.get(cur_level - 1).add(cat.Category__r.Note_ID__r.Name); //Add parent level
                    }

                    if (mLevelCategories.containsKey(cur_level - 2) && String.isNotBlank(cat.Category__r.Note_ID__r.Note_ID__r.Name)) { //Check heirachy node 2 (Ex: if current category level = 4 => check category level 2)
                        mLevelCategories.get(cur_level - 2).add(cat.Category__r.Note_ID__r.Note_ID__r.Name); //Add parent level
                    }

                    if (mLevelCategories.containsKey(cur_level - 3) && String.isNotBlank(cat.Category__r.Note_ID__r.Note_ID__r.Note_ID__r.Name)) { //Check heirachy node 3 (Ex: if current category level = 4 => check category level 1 [meta])
                        mLevelCategories.get(cur_level - 3).add(cat.Category__r.Note_ID__r.Note_ID__r.Note_ID__r.Name); //Add parent level
                    }

                }

                mapResult.put('mapCategory', mLevelCategories);
                
            }
            mapResult.put('couponMinSite', couponMinSite);
            mapResult.put('couponCode', couponCode);
            
            mapResult.put('status', 'ok');
        }catch(Exception ex){mapResult.put('status','ko'); mapResult.put('error',ex.getMessage()); return mapResult;}

        return mapResult;
    }

    

   
    

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

    /*********************************************************************************************************************************
    @ Method:         call
    @ Version:        1.0
    @ Author:         Chetra Sarom (chetra.sarom@gaea-sys.com)
    @ Purpose:        US-0012713 - Seller Bulk Upload functionality - Extend excel copy paste feature
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.02.2023 / Chetra Sarom / Created the method.
    *********************************************************************************************************************************/
    public Object call(String action, Map<String, Object> args) {
        // when class is implemented Callable, method "call" must also be implement.
        if(action == TXT_IMPORT_COUPON_SELLER) { 
            return this.importCSPreDML(args);
        }
        else{
            throw new CallableClassException(TXT_METHOD_NOT_IMPLEMENTED);
        }
    }


    private class CallableClassException extends Exception {}
}