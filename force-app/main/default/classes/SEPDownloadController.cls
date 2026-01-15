/*********************************************************************************************************************************
@ Class:          SEPDownloadController
@ Version:        1.0
@ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
@ Purpose:        Controller vf page: SEPDownloadPage
                  US-0010534 - Downloadable item list in .xls file from portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.06.2022 / Loumang SENG / Created the class.
                  22.06.2o22 / Sambath Seng / US-0010429 - Ability to sign Agreement in portal
                  25.07.2022 / Mony Nou / US-0012015 - NA Localization for Coupon Contract
                  10.08.2022 / Sophal Noch / US-0012207 - Changes to contract PDF Download - requested from legal
                  16.08.2022 / Mony Nou / US-0012216 - NA Coupons: Downloading /storing Coupon Contract on Portal and in Hive
                  01.08.2022 / Sovantheany Dim / US-0012534 - Download Items for NA Seller Portal + Internal missing features
                  19.09.2022 / Mony Nou / US-0012359 - PM Deals: Downloading /storing Deal Contract on Portal and in Hive
                  10.10.2022 / Mony Nou / US-0012630 - Change time format for DE coupons in portal
                  31.10.2022 / Mony Nou / US-0012856 - Corrections- PM Agreement in Seller Portal
                  24.11.2022 / Loumang SENG / US-0012029 - [IT] Localization for Coupon Contractt
                  21.02.2023/ Mony Nou / US-0012748 - [AU] Localization for Coupon Contract
                  28.02.2023 / Sambath Seng / US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
                  16.03.2023 / SRONG TIN / US-0013215 - Include ‘Additional Terms Override of Agreement’ field on US coupon contract
                  15.08.2023 / Sambath Seng / US-0013971 - Ensure date format on coupon contract preview is in same format as on contract
                  23.08.2023 / Sambath Seng / US-0014046 - Can not Sign Coupon Contract on SEP
 				  28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
				  04.01.2024 / Loumang SENG / US-0014486 - Add T&Cs to terms sheet
                  03.04.2024 / Mony Nou / US-0014909 - NA SFC Contract Update
                  06.06.2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
                  03.09.2025 / Loumang SENG / US-0033254 - POP - SP - Ability to Accept/Decline Coupon Seller Contract
                  13.10.2025 / Davy SORN / US-0033595 - CA SP - Fix SP UI Contract Display Issues
                  17.10.2025 / Mony Nou / US-0033377 - US PM Deals Seller Contract Update
                  20.11.2025 / Mony Nou / US-0033542 - POP - SP - Display Signed Contract Thank you confirmation text on Seller Portal
*********************************************************************************************************************************/
public with sharing class SEPDownloadController {
    public string currentUser{get;set;}
    public static string currentDate{get;set;}
    //public List<Coupon_Co_Invest__c> coInvests {get;set;}
    private final Integer ROW_LIMIT = 1000; //apex:repeat limit 1000
    public List<List<Coupon_Co_Invest__c>> listChunkcoInvests{get;set;}
    public CouponSellerWrapper cs {get;set;}
    private final static String RT_COUPON_CO_INVEST_ITEM = 'Coupon_Co_Invest_Item';
    private final static String RT_COUPON_SELLER_MASTER = 'Master_Agreement_Seller'; //MN-251125-US-0033542
    private final static String DF_DD_MM_YYYY = 'dd/MM/yyyy';
    private final static String DF_MM_DD_YYYY = 'MM/dd/yyyy'; //MN-23082022-US-0012216

    private final static String SOQL_COUPONCOINVEST = 'select Item_ID__c,Item_Title__c,Category__c, Coupon_Seller__c, Co_Invest__c, Category_ID__c, Coupon_Category__r.Name, Seller_Funding__c from Coupon_Co_Invest__c';//SB 28.02.2023 US-0012755
    public string xmlheader{ get{return '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';}}
    private final static String SOQL_COUPONCATEGORY = 'select Id,Name from Coupon_Category__c';

    //MN-23082022-US-0012216
    private final static String PROF_SEP_DE = 'DE - Seller Portal';
    private final static String PROF_SEP_NA = 'NA - Seller Portal';
    private final static String PROF_SEP_AU = 'AU - Seller Portal';
    private final static String COUPON_MAINSITE_AU = 'ebay.com.au';//LA-04-01-2024-US-0014486
    private final static String NO_MIN_SPEND_AU = 'No min spend';//LA-04-01-2024-US-0014486

    /* MN-06062024-US-0015298: No longer use Profile Name
    private static Map<String, String> mProfDF = new Map<String, String> {
        PROF_SEP_DE => DF_DD_MM_YYYY,
        PROF_SEP_NA => DF_MM_DD_YYYY
    };
    */

	//TH:US-0012534
    public static Boolean isNA{get;set;}
    public static Boolean isDE{get;set;}
    public static Boolean isAU{get;set;}

    // SB 23.08.2023 US-0014049
    private static Map<String, String> mSPDomainDateFormat = new Map<String, String> {
        SEP_Helper.SEP_Domain_DE => DF_DD_MM_YYYY,
        SEP_Helper.SEP_Domain_FR => DF_DD_MM_YYYY,
        SEP_Helper.SEP_Domain_IT => DF_DD_MM_YYYY,
        SEP_Helper.SEP_Domain_UK => DF_DD_MM_YYYY,
        SEP_Helper.SEP_Domain_NA => DF_MM_DD_YYYY,
        SEP_Helper.SEP_Domain_CA => DF_MM_DD_YYYY //DS US-0033595 - CA SP - Fix SP UI Contract Display Issues
    };

    //LA-28-09-2023: US-0013980 mapping by coupon mainsite
    //DS 13/10/2025: US-0033595 - CA SP - Fix SP UI Contract Display Issues
	private final static Map<String, String> COUPON_MAINSITE_MAPPING = new Map<String, String> {
			'ebay.de'       => 'DE',
			'ebay.co.uk'    => 'UK',
			'ebay.fr'       => 'FR',
			'ebay.it'       => 'IT',
			'ebay.com.au'   => 'AU',
			'ebay.es'       => 'ES',
			'ebay.com'      => 'US',
            'ebay.ca'       => 'CA'
	};
    
    public SEPDownloadController(){
        String csId = String.escapeSingleQuotes(String.isBlank(ApexPages.currentPage().getParameters().get('id')) ? '': ApexPages.currentPage().getParameters().get('id'));
        currentUser = UserInfo.getUserName();
        //currentDate = Datetime.now().format(DF_DD_MM_YYYY);
        listChunkcoInvests = new List<List<Coupon_Co_Invest__c>>();
        if(String.isNotBlank(csId)){
            cs = new CouponSellerWrapper(SEPCouponController.getCS(csId));
            List<Coupon_Co_Invest__c> lstcoInvests = getCouponCoInvestItems(csId);
            Map<String,Object> mapResult = ApexUtil.chunkListSOBJ(lstcoInvests, ROW_LIMIT);
            listChunkcoInvests = (List<List<Coupon_Co_Invest__c>>) mapResult.get('listAllChunk');
        }       
    }
  
    /*********************************************************************************************************************************
    @ method:         getCouponCoInvestItems
    @ Version:        1.0
    @ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
    @ Purpose:        US-0010534 - Downloadable item list in .xls file from portal
    @ Parameter:      String csId
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.06.2022 / Loumang SENG / Created the method.
    @               : 16.03.2023 / SRONG TIN / US-0013215 - Include ‘Additional Terms Override of Agreement’ field on US coupon contract
    *********************************************************************************************************************************/
    public static List<Coupon_Co_Invest__c> getCouponCoInvestItems(String csId){
        return Database.query(SOQL_COUPONCOINVEST+' Where RecordType.DeveloperName=:RT_COUPON_CO_INVEST_ITEM AND Coupon_Seller__c =:csId');
    }

    /*********************************************************************************************************************************
    @ Class:          CouponSellerWrapper
    @ Version:        1.0
    @ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
    @ Purpose:        Reduce coding to mapping coupon seller fields for SEPDownloadController and SEPCouponController
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.06.2022 / Loumang SENG / Created the class.
                      22.06.2o22 / Sambath Seng / US-0010429 - Ability to sign Agreement in portal
                      25.07.2022 / Mony Nou / US-0012015 - NA Localization for Coupon Contract
                      10.08.2022 / Sophal Noch / US-0012207 - Changes to contract PDF Download - requested from legal
                      01.08.2022 / Sovantheany Dim / US-0012534 - Download Items for NA Seller Portal + Internal missing features
                      05.11.2022/ vadhanak voun///NK:05/11/US-0012034 - [UK] Localization for Coupon Contract
                      24.11.2022/ Loumang SENG / US-0012029 - [IT] Localization for Coupon Contractt
                      30.11.2022/ Loumang SENG / US-0012025 - [FR] Localization for Coupon Contract
                      21.02.2023/ Mony Nou / US-0012748 - [AU] Localization for Coupon Contract
                      28.02.2023 / Sambath Seng / US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
                      23.08.2023 / Sambath Seng / US-0014046 - Can not Sign Coupon Contract on SEP
     				  28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
					  04.01.2024 / Loumang SENG / US-0014486 - Add T&Cs to terms sheet
                      03.09.2025 / Loumang SENG / US-0033254 - POP - SP - Ability to Accept/Decline Coupon Seller Contract
                      20.11.2025 / Mony Nou / US-0033542 - POP - SP - Display Signed Contract Thank you confirmation text on Seller Portal
    *********************************************************************************************************************************/
    public class CouponSellerWrapper {
        public String maxRedmeptions{get;set;}
        public DateTime couponStartDate{get;set;}
        public DateTime couponEndDate{get;set;}
        public DateTime couponDueDateDT{get;set;} //NK:05/11/2022:US-0012034

        public String legalEntity{get;set;}
        public String streetName{get;set;}
        public String zip{get;set;}
        public String city{get;set;}
        public String country{get;set;}
        public String eBaySellerID{get;set;}
        public String couponSites{get;set;}
        public String couponCode{get;set;}
        public String formatcouponStartDate{get;set;}
        public String formatcouponEndDate{get;set;}
        public String couponStartTime{get;set;}
        public String couponEndTime{get;set;}
        // public String couponDiscount{get;set;}
        public String marketingName{get;set;}
        public String minTransactionVal{get;set;}
        public String maxDisc{get;set;}
        public String additionalArrangement{get;set;}
        // public String couponDiscountAmount{get;set;}
        public String couponName{get;set;}
        public String couponDiscountAndDiscountAmount{get;set;}

        public String sellerShareHolder {get;set;} //MN-25072022-US-0012015
        public String eBayCofundMax {get;set;} //MN-25072022-US-0012015
        public String eBayCofundMaxText {get;set;} //MN-16082022-US-0012216
        
        public String formatContractAcceptDate{get;set;} // 10.08.2022 / Sophal Noch / US-0012207

        public String couponDueDate{get;set;}//NK:05/11/2022:US-0012034

        public String mainCouponSite{get;set;}//LA:25/11/2022:US-0012029

        public String minTransactionValFr{get;set;} //LA-30-11-2022-US-0012025
        public String maxDiscFr{get;set;} //LA-30-11-2022-US-0012025
        public String couponDiscountAndDiscountAmountFr{get;set;} //LA-30-11-2022-US-0012025

        public String additionalArrangementOverride {get;set;} //MN-21022023-US-0012748
        public String sellerFundingRate {get;set;} //SB-28022023-US-0012755
        public String maxItemsPerRedemption {get;set;} //LA-05-01-2024-US-0014486
        public String sellerMaxContribution {get;set;} //LA-03-09-2025-US-0033254
        
        public DateTime progCouponEndDate {get;set;} //MN-20112025-US-0033542
        public String formatProgCouponEndDate{get;set;} //MN-20112025-US-0033542
        public String progMarketingName {get;set;} //MN-20112025-US-0033542
 
        public CouponSellerWrapper(Coupon_Seller__c cs){

            String couponMainSite = COUPON_MAINSITE_MAPPING.get(cs.Main_Coupon_Site__c);//LA-28-09-2023: US-0013980 : Replace Contract_Language__c in Main_Coupon_Site__c
            // String userId = (Test.isRunningTest() && (String.isBlank(cs.Seller_Contact__r.Community_User__c)) ? UserInfo.getUserId() : UserInfo.getUserId() == cs.Seller_Contact__r.Community_User__c ? UserInfo.getUserId() : cs.Seller_Contact__r.Community_User__c);//SB 16.08.2023 US-0013971
            //User currentUser = [SELECT Contact.Account.SP_Coupons__c, Profile.Name FROM User WHERE Id =: UserInfo.getUserId()]; //MN-23082022-US-0012216 //MN-06062024-US-0015298
            // User currentUser = [SELECT Contact.Account.SP_Coupons__c, Profile.Name FROM User WHERE Id =: userId];//SB 16.08.2023 US-0013971
            // String profDF = (mProfDF.containsKey(currentUser.Profile.Name))?mProfDF.get(currentUser.Profile.Name):DF_DD_MM_YYYY; //MN-23082022-US-0012216 - Default with dd/MM/yyyy
            // Start SB 23.08.2023 US-0014046
            String profDF = '';
            Boolean isGroupAccount = (String.isNotBlank(cs.Seller__r.Seller_Portal_Group__c)) ? true : false;
            Boolean isCA = SEP_Helper.sepUser.isCARRU(); //DS US-0033595 - CA SP - Fix SP UI Contract Display Issues
            if(isGroupAccount && String.isNotBlank(cs.Seller__r.Seller_Portal_Group__r.SP_Main_Domain__c) && mSPDomainDateFormat.containsKey(cs.Seller__r.Seller_Portal_Group__r.SP_Main_Domain__c)){
                profDF = isCA ? mSPDomainDateFormat.get(SEP_Helper.SEP_Domain_CA) : mSPDomainDateFormat.get(cs.Seller__r.Seller_Portal_Group__r.SP_Main_Domain__c); //DS US-0033595 - CA SP - Fix SP UI Contract Display Issues
            } else if (String.isNotBlank(cs.Seller__r.SP_Main_Domain__c) && mSPDomainDateFormat.containsKey(cs.Seller__r.SP_Main_Domain__c)) {
                profDF = isCA ? mSPDomainDateFormat.get(SEP_Helper.SEP_Domain_CA) : mSPDomainDateFormat.get(cs.Seller__r.SP_Main_Domain__c); //DS US-0033595 - CA SP - Fix SP UI Contract Display Issues
            } else {
                profDF = DF_DD_MM_YYYY;
            }
            // End SB 23.08.2023 US-0014046

            List<Coupon_Co_Invest__c> listCoInvest = SEPCouponController.getListCoinvest(cs.Id);//SB-28022023-US-0012755

            /* MN-06062024-US-0015298: No longer use Profile Name
            //TH:US-0012534:check profile name
            isNA = PROF_SEP_NA.equalsIgnoreCase(currentUser.Profile.Name) ? true : false;
            isDE = PROF_SEP_DE.equalsIgnoreCase(currentUser.Profile.Name) ? true : false;
            isAU = PROF_SEP_AU.equalsIgnoreCase(currentUser.Profile.Name) ? true : false;
            */

            isNA = SEP_Helper.sepUser.isNA(); //MN-06062024-US-0015298
            isDE = SEP_Helper.sepUser.isEU(); //MN-06062024-US-0015298
            isAU = SEP_Helper.sepUser.isAU(); //MN-06062024-US-0015298

            currentDate = Datetime.now().format(profDF);//TH:US-0012534:The download Date format should be mm/dd/yyyy for NA

            couponName = cs.Name;
            couponCode = ApexUtil.checkNull(cs.Coupon_ID__c)+'';//LA-29-06-2022: US-0010429
            couponStartDate = Datetime.newInstance(cs.Coupon_Start_Date__c.Year(),cs.Coupon_Start_Date__c.Month(),cs.Coupon_Start_Date__c.Day());
		    couponEndDate = Datetime.newInstance(cs.Coupon_End_Date__c.Year(),cs.Coupon_End_Date__c.Month(),cs.Coupon_End_Date__c.Day());
            couponDueDateDT = Datetime.newInstance(cs.Coupon_Contract_Due_Date__c.Year(),cs.Coupon_Contract_Due_Date__c.Month(),cs.Coupon_Contract_Due_Date__c.Day());
            //maxRedmeptions = cs.Max_Redemptions__c==null?'N/A':ApexUtil.formatNumber(cs.Max_Redemptions__c,0,cs.Contract_Language__c);//SB 22.6.2022 US-0010429 - Ability to sign Agreement in portal
            maxRedmeptions = cs.Max_Redemptions__c==null?'N/A':ApexUtil.formatNumber(cs.Max_Redemptions__c,0,couponMainSite);
            legalEntity = ApexUtil.checkNull(cs.Legal_Entity_Name_w__c)+'';
            streetName = ApexUtil.checkNull(cs.Legal_Entity_Street_w__c)+'';
            zip = ApexUtil.checkNull(cs.Legal_Entity_Zip_w__c)+'';
            city = ApexUtil.checkNull(cs.Legal_Entity_City__c)+'';
            eBaySellerID = cs.Seller__r.Name;
            couponSites = ApexUtil.checkNull(cs.Coupon_Site__c)+'';
            // couponStartTime = ApexUtil.formatTime(cs.Coupon_Start_Time__c);//MN-10102022-US-0012630
            couponStartTime = (isDE)?ApexUtil.formatTime24h(cs.Coupon_Start_Time__c):ApexUtil.formatTime(cs.Coupon_Start_Time__c); //MN-10102022-US-0012630-For DE, Time will display with 24h format
            // formatcouponStartDate = couponStartDate == null ? '' : couponStartDate.format(DF_DD_MM_YYYY); //MN-23082022-US-0012216
            formatcouponStartDate = couponStartDate == null ? '' : couponStartDate.format(profDF); //MN-23082022-US-0012216
            // couponEndTime = ApexUtil.formatTime(cs.Coupon_End_Time__c); //MN-10102022-US-0012630
            couponEndTime = (isDE)?ApexUtil.formatTime24h(cs.Coupon_End_Time__c):ApexUtil.formatTime(cs.Coupon_End_Time__c); //MN-10102022-US-0012630-For DE, Time will display with 24h format
            // formatcouponEndDate = couponEndDate == null ? '' : couponEndDate.format(DF_DD_MM_YYYY); //MN-23082022-US-0012216
            formatcouponEndDate = couponEndDate == null ? '' : couponEndDate.format(profDF);
            // couponDiscount = cs.SP_Coupon_Discount_Rate__c==null?'':ApexUtil.formatNumber(cs.SP_Coupon_Discount_Rate__c,2,cs.Contract_Language__c)+'%';//SB 22.6.2022 US-0010429 - Ability to sign Agreement in portal
            // couponDiscountAmount = cs.Coupon_Discount_Amount__c==null?'':ApexUtil.mapCurrencySign.get(cs.CurrencyIsoCode)+ApexUtil.formatNumber(cs.Coupon_Discount_Amount__c,3,cs.Contract_Language__c);//SB 22.6.2022 US-0010429 - Ability to sign Agreement in portal
            //LA-05-07-2022-US-0011917: chnge formula field type number to percentage for field 'Coupon Discount (%)' and update mappingg field from(cs.SP_Coupon_Discount_Rate__c*100) to cs.SP_Coupon_Discount_Rate__c
            couponDiscountAndDiscountAmount = (cs.SP_Coupon_Discount_Rate__c==null && cs.Coupon_Discount_Amount__c==null)?'N/A':(cs.SP_Coupon_Discount_Rate__c==null?ApexUtil.mapCurrencySign.get(cs.CurrencyIsoCode)+ApexUtil.formatNumber(cs.Coupon_Discount_Amount__c,2,couponMainSite):ApexUtil.formatNumber(cs.SP_Coupon_Discount_Rate__c,2,couponMainSite)+'%');//SB 27.6.2022 US-0010429 - Ability to sign Agreement in portal 
            maxDisc = cs.Maximum_Discount_Value__c ==null?'N/A':ApexUtil.mapCurrencySign.get(cs.CurrencyIsoCode)+ApexUtil.formatNumber(cs.Maximum_Discount_Value__c ,2,couponMainSite);
            additionalArrangement = cs.Additional_Terms__c==null?'':cs.Additional_Terms__c;
            if(isNA){additionalArrangement = additionalArrangement == ''?'N/A':additionalArrangement;}//SRO 17-03-2023:US-0013215
            marketingName = ApexUtil.checkNull(cs.Marketing_Coupon_Name__c)+'';
            //LA-04-01-2024-US-0014486 : Update minTransactionVal to check condition for site AU
            minTransactionVal = cs.Min_Transaction_Value__c==null?(cs.Main_Coupon_Site__c==COUPON_MAINSITE_AU?NO_MIN_SPEND_AU:'N/A'):ApexUtil.mapCurrencySign.get(cs.CurrencyIsoCode)+ApexUtil.formatNumber(cs.Min_Transaction_Value__c,2,couponMainSite);
            country = ApexUtil.checkNull(cs.Legal_Entity_Country__c)+'';
            
            //MN-25072022-US-0012015
            sellerShareHolder = (cs.SellerShareHolder__c==null)?'N/A':ApexUtil.formatNumber(cs.SellerShareHolder__c,2,couponMainSite)+'%';
            eBayCofundMax = (cs.eBay_Co_fund_Max__c==null)?'N/A':ApexUtil.formatNumber(cs.eBay_Co_fund_Max__c,2,couponMainSite);
            eBayCofundMaxText = (cs.eBay_Co_fund_Max__c==null)?'N/A':ApexUtil.numberToWordsCurrency(cs.eBay_Co_fund_Max__c); //MN-16082022-US-0012216 //MN-03042024-US-0014909: Changed from Zero to N/A
            // formatContractAcceptDate = cs.Contract_Accept_Date__c == null ? '' : cs.Contract_Accept_Date__c.format(DF_DD_MM_YYYY); // 10.08.2022 / Sophal Noch / US-0012207 : //MN-16082022-US-0012216
            formatContractAcceptDate = cs.Contract_Accept_Date__c == null ? '' : cs.Contract_Accept_Date__c.format(profDF); // 10.08.2022 / Sophal Noch / US-0012207 : //MN-16082022-US-0012216
            couponDueDate = cs.Coupon_Contract_Due_Date__c==null?'':couponDueDateDT.format(profDF); //NK:05/11/2022:US-0012034
            mainCouponSite = ApexUtil.checkNull(cs.Main_Coupon_Site__c)+'';//LA:25/11/2022:US-0012029
            maxDiscFr = cs.Maximum_Discount_Value__c ==null?'N/A':ApexUtil.formatNumber(cs.Maximum_Discount_Value__c ,2,couponMainSite)+ApexUtil.mapCurrencySign.get(cs.CurrencyIsoCode); //LA-30-11-2022-US-0012025 //FR contract use symbol on the right. e.g. after 50.00€
            minTransactionValFr = cs.Min_Transaction_Value__c==null?'N/A':ApexUtil.formatNumber(cs.Min_Transaction_Value__c,2,couponMainSite)+ApexUtil.mapCurrencySign.get(cs.CurrencyIsoCode); //LA-30-11-2022-US-0012025 //FR contract use symbol on the right. e.g. after 50.00€
            couponDiscountAndDiscountAmountFr = (cs.SP_Coupon_Discount_Rate__c==null && cs.Coupon_Discount_Amount__c==null)?'N/A':(cs.SP_Coupon_Discount_Rate__c==null?ApexUtil.formatNumber(cs.Coupon_Discount_Amount__c,2,couponMainSite)+ApexUtil.mapCurrencySign.get(cs.CurrencyIsoCode):ApexUtil.formatNumber(cs.SP_Coupon_Discount_Rate__c,2,couponMainSite)+'%');//LA-30-11-2022-US-0012025 //FR contract use symbol on the right. e.g. after 50.00€

            //MN-21022023-US-0012748
            additionalArrangementOverride = ApexUtil.checkNull(cs.Additional_Terms_Override_of_Agreement__c)+'';
            //if(isNA){additionalArrangementOverride = additionalArrangementOverride == ''?'N/A':additionalArrangementOverride;}//SRO 16-03-2023:US-0013215
            sellerFundingRate = (listCoInvest.isEmpty())?'0':listCoInvest.get(0).Seller_Funding__c+'';//SB-28.02.2023-US-0012755
            maxItemsPerRedemption = ApexUtil.checkNull(cs.Max_items_per_redemption__c)+'';//LA-05-01-2024-US-0014486
            sellerMaxContribution = ApexUtil.checkNull(cs.SellerMaximumContribution__c)+'';//LA-03-09-2025-US-0033254

            //MN-20112025-US-0033542: Get 1st Program Coupon Seller end date
            formatProgCouponEndDate = '';
            progMarketingName = '';
            if (cs.RecordType.DeveloperName == RT_COUPON_SELLER_MASTER && cs.Coupon__c != null) {
                String masterCouponId = String.valueOf(cs.Coupon__c).substring(0,15);
                List<Coupon_Seller__c> lstProgCS = SEPCouponController.getListProgramCouponSeller(masterCouponId, 1);
                if (!lstProgCS.isEmpty()) {
                    Coupon_Seller__c progCS = lstProgCS[0];
                    progCouponEndDate = (progCS.Coupon_End_Date__c != null) ? Datetime.newInstance(progCS.Coupon_End_Date__c.Year(), progCS.Coupon_End_Date__c.Month(), progCS.Coupon_End_Date__c.Day()) : null;
                    formatProgCouponEndDate = (progCouponEndDate != null) ? progCouponEndDate.format(profDF) : '';
                    progMarketingName = ApexUtil.checkNull(progCS.Marketing_Coupon_Name__c) + ''; //MN-20112025-US-0033542
                }
            }
        }
    }

    /*********************************************************************************************************************************
    @ Class:          DCAWrapper
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        Reduce coding to mapping Deal Contract Agreement fields for SEPDCAContractDownloadController
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.09.2022 / Mony Nou / US-0012359 / Created the wrapper class.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.10.2022 / Mony Nou / US-0012856 - Corrections- PM Agreement in Seller Portal
    @                 17.10.2025 / Mony Nou / US-0033377 - US PM Deals Seller Contract Update
    *********************************************************************************************************************************/
    public class DCAWrapper {
        
        public String eBaySellerID{get;set;}
        public String title {get;set;}
        public String eBayFunding {get;set;}
        public String dealPagePlacement {get;set;}
        public Datetime dealStartDate {get;set;}
        public String dealStartTime {get;set;}
        public Datetime dealEndDate {get;set;}
        public String dealEndime {get;set;}
        public String formatDealStartDate{get;set;}
        public String formatDealEndDate{get;set;}
        public String discountAppliedinCart {get;set;}
        public String maxTotalSubsidy {get;set;}
        public String maxUnitSubsidy {get;set;}
        public String pmId {get; set;} //MN-17102025-US-0033377
        public String pmIdLink {get; set;} //MN-22102025-US-0033377

        public DCAWrapper(Deal_Contract_Agreement__c dca){
            
            //User currentUser = [SELECT Contact.Account.SP_Coupons__c, Profile.Name FROM User WHERE Id =: UserInfo.getUserId()]; //MN-23082022-US-0012216 //MN-06062024-US-0015298:Not using
            
            //String profDF = (mProfDF.containsKey(currentUser.Profile.Name))?mProfDF.get(currentUser.Profile.Name):DF_DD_MM_YYYY; //MN-23082022-US-0012216 - Default with dd/MM/yyyy //MN-06062024-US-0015298
            String dateFormat = (mSPDomainDateFormat.containsKey(SEP_Helper.sepUser.domain))?mSPDomainDateFormat.get(SEP_Helper.sepUser.domain):DF_DD_MM_YYYY; //MN-06062024-US-0015298: Use SP Main Domain to get date format

            eBaySellerID = dca.eBay_Seller__r.Name;
            title = dca.Title__c;
            eBayFunding = (dca.eBay_Funding__c==null)?'N/A':ApexUtil.formatNumber(dca.eBay_Funding__c,2,dca.eBay_Seller__r.EBH_RevRollup__c)+'%';
            dealPagePlacement = dca.Deal_Page_Placement__c;

            dealStartDate = Datetime.newInstance(dca.Deal_Start_Date__c.Year(),dca.Deal_Start_Date__c.Month(),dca.Deal_Start_Date__c.Day());
            dealStartTime = ApexUtil.formatTime(dca.Deal_Start_Time__c);

            dealEndDate = Datetime.newInstance(dca.Deal_End_Date__c.Year(),dca.Deal_End_Date__c.Month(),dca.Deal_End_Date__c.Day());
            dealEndime = ApexUtil.formatTime(dca.Deal_End_Time__c);

            discountAppliedinCart = (dca.Discount_Applied_in_Cart__c)?'Yes':'No';
            /* MN-31102022-US-0012856
            maxTotalSubsidy = (dca.Max_Total_Subsidy__c==null)?'N/A':ApexUtil.mapCurrencySign.get(dca.CurrencyIsoCode)+ApexUtil.formatNumber(dca.Max_Total_Subsidy__c ,2,dca.eBay_Seller__r.EBH_RevRollup__c);
            maxUnitSubsidy = (dca.Max_Unit_Subsidy__c==null)?'N/A':ApexUtil.mapCurrencySign.get(dca.CurrencyIsoCode)+ApexUtil.formatNumber(dca.Max_Unit_Subsidy__c ,2,dca.eBay_Seller__r.EBH_RevRollup__c);
            */
            //MN-31102022-US-0012856 : Display Currency Code (Ex: USD) rather than Currency Sign (Ex: $)
            maxTotalSubsidy = (dca.Max_Total_Subsidy__c==null)?'N/A':dca.CurrencyIsoCode + ' ' + ApexUtil.formatNumber(dca.Max_Total_Subsidy__c ,2,dca.eBay_Seller__r.EBH_RevRollup__c);
            maxUnitSubsidy = (dca.Max_Unit_Subsidy__c==null)?'N/A':dca.CurrencyIsoCode + ' ' + ApexUtil.formatNumber(dca.Max_Unit_Subsidy__c ,2,dca.eBay_Seller__r.EBH_RevRollup__c);

            /* MN-06062024-US-0015298
            formatDealStartDate = dealStartDate == null ? '' : dealStartDate.format(profDF);
            formatDealEndDate = dealEndDate == null ? '' : dealEndDate.format(profDF);
            */

            formatDealStartDate = dealStartDate == null ? '' : dealStartDate.format(dateFormat); //MN-06062024-US-0015298
            formatDealEndDate = dealEndDate == null ? '' : dealEndDate.format(dateFormat); //MN-06062024-US-0015298

            pmId = dca.PM_ID__c; //MN-17102025-US-0033377
            pmIdLink = Site.getBaseCustomUrl()+'/s/deal-contract-agreement/'+dca.Id; //MN-22102025-US-0033377

        }

    }

    /*********************************************************************************************************************************
    @ method:         getDownloadExcel
    @ Version:        1.0
    @ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
    @ Purpose:        US-0010534 - Downloadable item list in .xls file from portal
    @ Parameter:      String csId
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.06.2022 / Loumang SENG / Created the method.
    *********************************************************************************************************************************/
    @AuraEnabled
    public static String getDownloadExcel(String csId) {
        PageReference xlsGenerater = new PageReference('/apex/SEPDownloadPage');
        xlsGenerater.getParameters().put('id',csId);
        return  EncodingUtil.base64encode(!Test.isRunningTest() ? xlsGenerater.getContent() : Blob.valueOf('test'));
    }
    
}