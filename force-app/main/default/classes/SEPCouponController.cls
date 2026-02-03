/*********************************************************************************************************************************@ Class:          SEPCouponController@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        Controller class for “Coupon Feature in SEP”
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.5.2022 / Sambath Seng / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.5.2022 / Mony Nou / US-0010656 - Ability to upload/manage items to item based coupons
@ Change history: 16.06.2022 / Chetra Sarom / US-0010436 - Ability to decline single coupon participation
@ Change history: 20.06.2022 / Sambath Seng / US-0010429 - Ability to sign Agreement in portal
@ Change history: 23.06.2022 / Chetra Sarom / US-0011912 - Bug: Remove Item List visibility for coupon seller in preparation
@ Change history: 28.06.2022 / SRONG TIN / US-0011918 - Enable deletion of Co-Invest records if not owner
@ Change history: 25.07.2022 / Mony Nou / US-0012015 - NA Localization for Coupon Contract
@ Change history: 10.08.2022 / US-0012207 - Changes to contract PDF Download - requested from legal
@ Change history: 16.08.2022 / Mony Nou / US-0012216 - NA Coupons: Downloading /storing Coupon Contract on Portal and in Hive
@               : 05.11.2022/ vadhanak voun/ US-0012034 - [UK] Localization for Coupon Contract
@               : 22.11.2022/ SRONG TIN / US-0012185 - [FR] Downloading /storing Coupon Contract on Portal and in Hive 
@               : 23.11.2022 / Loumang SENG / US-0012025 - [FR] Localization for Coupon Contract
@               : 24.11.2022 / Loumang SENG / US-0012029 - [IT] Localization for Coupon Contractt
@               31.01/2023/ vadhanak voun /  US-0013170 - Wrongly displayed time and date format
@               20.02/2023/ Mony Nou / US-0012748 - [AU] Localization for Coupon Contract
@               24.02.2023 / Sambath Seng / US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
@               : 05.06.2023 / Loumang SENG / US-0013029 - Streamline of coupon seller statuses & retiring coupon fields
@               : 13.06.2023/vadhanak voun/US-0013528 - Allow seller to sign contract after declining until contract due date
@               : 10.07.2023 / Mony Nou / US-0012496 - Allow declining of coupon at Negotiation
@               : 12.07.2022/ SRONG TIN / US-0013632 - Ability to preview contract before moving coupon seller to contract signature
@               : 15.08.2023 / Sovantheany Dim / US-0011560 - Make Coupon Transaction file available for download in portal
@               : 16.08.2023 / Sambath Seng / US-0013971 - Ensure date format on coupon contract preview is in same format as on contract
@               : 23.08.2023 / Sambath Seng / US-0014046 - Can not Sign Coupon Contract on SEP
@               : 14.09.2023 / Sambath Seng / US-0014083 - Change the Coupon Transaction file access
@               : 21.09.2023 / Loumang SENG / US-0014149 - Categories list component on SCMC Coupon seller page in SEP
@ 				: 28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
@ 				: 18.10.2023 / Loumang SENG / US-0014190 - Coupon performance on Seller Portal (AC3)
@               : 24.11.2023 / Sambath Seng / US-0014448 - Coupon Performance enhancements
@               : 05.01.2024 / Loumang SENG / US-0014486 - Add T&Cs to terms sheet
@               : 05/06/2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
@               : 01/08/2024 / Mony Nou / US-0015661 - Error message given when seller tries to accept coupon contract
@               08/14/2025 / SRONG TIN / US-0033261 - CA SP - Contract T&Cs View and Download
@               02.09.2025 / Loumang SENG / US-0033254 - POP - SP - Ability to Accept/Decline Coupon Seller Contract
@               : 25/09/2025 / Davy SORN / US-0033398 - POP - SP - Ability to view related child Coupons and Item List | Incl Opt Out Part 2
@               : 20/11/2025 / Mony Nou / US-0033542 - POP - SP - Display Signed Contract Thank you confirmation text on Seller Portal 
@               : 10/12/2025 / Sovantheany Dim / US-0033746 - POP - Trigger to update status of Program Seller to Opt-Out - instead of Seller Declined 
@               : 12/12/2025 / SENG Chan Sophorn / US-0033567 - POP - SP - Add Button, New Field and update text on Program Coupon Layout - view Master Agreement
@               : 08/01/2026 / SENG Chan Sophorn / US-0033468 - POP - SP - Populate Program Coupon info on Master Coupon Agreement Contract (Part 2) 
@               : 19/01/2026 / Mony Nou / US-0033366 - POP - SP - Ability for Sellers to Upload Coupon Item Exclusions in Seller Portal 
*********************************************************************************************************************************/
public with sharing class SEPCouponController {

    //MN-25072022-US-0012015-Added SellerShareHolder__c,eBay_Co_fund_Max__c into query
    //MN-21022023US-0012748-Added Additional_Terms_Override_of_Agreement__c into query
    //12.07.2022/ SRONG TIN / US-0013632 Seller_r.PrimaryContact__c into query
    //16.08.2023 / Sambath Seng / US-0013971 add Seller_Contact__r.Community_User__c into query
    //23.08.2023 / Sambath Seng / US-0014046 add Seller__r.Seller_Portal_Group__c,Seller__r.Seller_Portal_Group__r.SP_Main_Domain__c,Seller__r.SP_Main_Domain__c into query
    //LA-28-09-2023: US-0013980 : Add Seller__r.EBH_RevRollup__c into query
    // 12/12/2025 / CSP:US-0033567
    private final static String SOQL_COUPON_SELLER = 'Select Coupon__c,Seller__c,Seller__r.Id, RecordType.DeveloperName, SellerMaximumContribution__c,Max_items_per_redemption__c,Contra_LC__c,GMV_LC__c,Last_Sales_Date__c,Last_Refresh_Date__c,Cost_Share_Seller_LC__c, Seller__r.EBH_RevRollup__c,Additional_Terms_Override_of_Agreement__c,Main_Coupon_Site__c,Coupon_Code__c, Name, Coupon_ID__c, Coupon_Start_Date__c, Coupon_End_Date__c, Legal_Entity_Name_w__c, Legal_Entity_Street_w__c, Legal_Entity_Zip_w__c, Seller__r.Parent.EBH_BillingCity__c, Seller__r.Name, Coupon_Start_Time__c, Coupon_End_Time__c, Additional_Terms__c, Seller__r.Parent.EBH_BillingCountry__c, Coupon__r.Couponsite_s__c, Marketing_Coupon_Name__c, Contract_Language__c, CurrencyIsoCode, Min_Transaction_Value__c, SP_Coupon_Discount_Rate__c, Coupon_Site__c, Max_Redemptions__c, Coupon_Discount_Amount__c, Legal_Entity_City__c, Maximum_Discount_Value__c, Coupon_Contract_Due_Date__c, Coupon_Seller_Stage__c, Contract_Accept_Date__c, Contract_Accepted_From__c, Contract_Signed_Declined_By__c, Legal_Entity_Country__c, Coupon_Type__c, Allow_reaccept_contract__c, Coupon_Seller_Stage_Portal__c, SellerShareHolder__c,eBay_Co_fund_Max__c,Negotiation_End_Date__c,Seller__r.Primary_Contact__c,Seller_Contact__r.Community_User__c,Seller__r.Seller_Portal_Group__c,Seller__r.Seller_Portal_Group__r.SP_Main_Domain__c,Seller__r.SP_Main_Domain__c,Master_Agreement_Coupon_Seller__c,Master_Agreement_Coupon_Seller__r.Name,CoInvestFileSFID__c From Coupon_Seller__c ' ; //SB 23.6.2022 US-0011958 - Change Requests Focus 75 // 10-10-2022/ Chetra Sarom / US-0012679 - Coupons Item Upload deadline Note on Seller portal
    //MN-21022023-US-0012748-Added Seller_Funding__c into query
    private final static String SOQL_COUPONCOINVEST = 'select Item_ID__c,Item_Title__c,Category__c, Coupon_Seller__c, Co_Invest__c, Category_ID__c, Coupon_Category__r.Name, Seller_Funding__c from Coupon_Co_Invest__c';
    private final static String SOQL_PROGCOPOUNSELLER = 'Select Id, Coupon_End_Date__c, Marketing_Coupon_Name__c From Coupon_Seller__c'; //MN-25112025-US-0033542
    private final static String SOQL_SEPCONTRACTPROGCOPOUNSELLER = 'Select Id, Seller__c,Seller__r.Id, Coupon__c, Coupon_ID__c ,MasterCouponId__c, Marketing_Coupon_Name__c,Coupon_Start_Time__c ,Coupon_Start_Date__c ,Coupon_End_Time__c,Coupon_End_Date__c, Additional_Terms__c From Coupon_Seller__c'; // 08012026:CSP/US-0033468
    private final static String EMAIL_COUPON_CONTRACT_DE_ITEM_SEP = 'DE_Item_Coupon_Contract_SEP';
    private final static String EMAIL_COUPON_CONTRACT_DE_CAT_SEP = 'DE_Category_Coupon_Contract_SEP';
    private final static String EMAIL_COUPON_CONTRACT_DE_MC_SEP = 'DE_Master_Coupon_Agreement_Contract_SEP';
    private final static String PROGRAM_COUPON_SELLER_REC_TYPE = 'Program_Coupon_Seller';
    private final static String MASTER_AGREEMENT_SELLER_REC_TYPE = 'Master_Agreement_Seller';
    
    private final static String STR_QUERY_COUPON_SELLER = 'SELECT Id, (SELECT Id,Co_Invest__c FROM Coupon_Co_Invests__r WHERE Co_Invest__c = null OR Co_Invest__c >=0 ORDER BY Co_Invest__c ASC NULLS FIRST LIMIT 1) FROM Coupon_Seller__c WHERE Id =:csId';
    private final static String STR_QUERY_CURRENT_USER  = 'SELECT Contact.Account.SP_Coupons__c, Profile.Name FROM User WHERE Id =:userId';
    private final static String STR_QUERY_DOCUMENT_LINK = 'Select Id,ContentDocumentId From ContentDocumentLink where LinkedEntityId=:csId AND ContentDocument.Description like :pDescription ORDER BY ContentDocument.CreatedDate DESC Limit 1';
    private final static String STR_QUERY_CONTENT_VERSION = 'Select Id,Title From ContentVersion Where ContentDocumentId =:cdId ORDER BY CreatedDate DESC Limit 1';

    //MN-25112025-US-0033542 - Conditional Display Block Constants
    private final static String START_DISPLAY_FOR = 'START_DISPLAY_FOR#';
    private final static String END_DISPLAY_FOR = 'END_DISPLAY_FOR#';

    //NK:05/11/2022:US-0012034/maping by main site Main_Coupon_Site__c
    private final static Map<String,String> MAP_CONTRACT_LOCALIZE = new Map<String,String>{
        'ebay.co.uk-Category Based'=>'UK_Category_Coupon_Contract_SEP',
        'ebay.co.uk-Item Based'=>'UK_Item_Coupon_Contract_SEP',
        'ebay.fr-Category Based'=>'FR_Category_Coupon_Contract_SEP', //LA-US-0012025
        'ebay.fr-Item Based'=>'FR_Item_Coupon_Contract_SEP', //LA-US-0012025
        'ebay.it-Category Based'=>'IT_Category_Coupon_Contract_SEP', //US-0012029
        'ebay.it-Item Based'=>'IT_Item_Coupon_Contract_SEP', //US-0012029
        'ebay.ca-Category Based'=>'CA_Category_Coupon_Contract_SEP', //US-0033261
        'ebay.ca-Item Based'=>'CA_Item_Coupon_Contract_SEP' //US-0033261
    };

    //MN-25072022-US-0012015
    private final static String EMAIL_COUPON_CONTRACT_NA_ITEM_SEP = 'NA_Item_Coupon_Contract_SEP';
    private final static String EMAIL_COUPON_CONTRACT_NA_CAT_SEP = 'NA_Category_Coupon_Contract_SEP';
    
    //MN-20022023-US-0012748
    private final static String EMAIL_COUPON_CONTRACT_AU_ITEM_SEP = 'AU_Item_Coupon_Contract_SEP';
    private final static String EMAIL_COUPON_CONTRACT_AU_CAT_SEP = 'AU_Category_Coupon_Contract_SEP';

    private final static String SOQLEMAIL_TEMPLATES = 'Select Body,Id,DeveloperName,Subject,HtmlValue from emailTemplate ';
    public final static String COUPON_CATEGORYBASE = 'Category Based';
    public final static String COUPON_ITEMBASE = 'Item Based';
    public final static String COUPON_SCMC ='SCMC Store-wide/Category'; //LA-21-09-2023-US-0014149
    private static String htmlTableTemplate = '<table>{!tableHeader}{!rows}</tbody></table>';
    private static String htmlHeadTemplateDE = '<thead><tr><td><strong>Kategorie</strong></td><td><strong>Kategorie-ID</strong></td><td><strong>Erfolgsprämie (%)</strong></td></tr></thead><tbody>';
    //MN-29072022-US-0012015
    private static String htmlHeadTemplateNA = '<thead><tr><td><strong>Categories</strong></td><td><strong>Category-ID</strong></td><td><strong>Co-Invest (%)</strong></td></tr></thead><tbody>';

    private static String htmlRowTemplate = '<tr><td style="width: 250px;">{!catName}</td><td style="width: 250px;">{!catId}</td><td style="width: 250px;">{!coinvest%}</td></tr>'; //SB 22.06.2022 US-0010429 change table head width
    private static String htmlProgramTableTemplate = '<table style="width: 100%; border-collapse: collapse" border="1" cellspacing="0" cellpadding="5"><tbody><tr><td style="width: 350px;"><strong>Gutscheincode #{!index}</strong></td><td> {!CouponCode} </td></tr><tr><td> <strong>Gutscheinname</strong> </td><td>{!MarketingCouponName}</td></tr><tr><td><strong>Gültigkeitsdauer des Gutscheins</strong></td><td>{!CouponStartTime} {!CouponStartDate} bis {!CouponEndTime} {!CouponEndDate} (MEZ)</td></tr><tr><td><strong>Sonstiges</strong></td><td>{!AdditionalArrangement}</td></tr></tbody></table> <br>'; // 08012026:CSP/US-0033468
    private final static String DF_DD_MM_YYYY = 'dd/MM/yyyy';
    private final static String COUPON_SELLER_STAGE_CONTRACT_SIGNED= 'Contract Signed';
    private final static String COUPON_SELLER_STAGE_CONTRACT_SEND= 'Contract Send';
    private final static String COUPON_SELLER_STAGE_SELLER_DECLINED= 'Seller Declined';
    private final static String PROGRAM_COUPON_SELLER_STAGE_SELLER_OPT_OUT = 'Opted-Out';//TH:US-0033746:Update to Opt-Out
    private final static String PROGRAM_COUPON_SELLER_STAGE_DRAFT = 'Draft';//MN-19012026-US-0033366
    private final static String PROGRAM_COUPON_SELLER_STAGE_OPTED_IN = 'Opted-In';//MN-19012026-US-0033366
    private final static String COUPON_SELLER_STAGE_NEGO= 'Contract Negotiation';
    private final static String COUPON_SELLER_STAGE_REVIEW_SEP= 'Items in Review';//SB 23.6.2022 US-0011958 - Change Requests Focus 75
    private final static String COUPON_SELLER_STAGE_STATEMENT_GENERATED = 'T34 Statement Send';//TH:US-0011560 

    private final static String SP_COUPON_FULL_ACCESS = 'Full Access';// US-0011991 - Acmatac SEING
    private final static String SP_COUPON_READ_ONLY = 'Read Only';// US-0011991 - Acmatac SEING
    private final static String SP_COUPON_ALLOWED = 'Allowed';// US-0011991 - Acmatac SEING

    //MN-25072022-US-0012015
    private final static String PROF_SEP_DE = 'DE - Seller Portal';
    private final static String PROF_SEP_NA = 'NA - Seller Portal';
    private final static String PROF_SEP_AU = 'AU - Seller Portal'; //MN-20022023-US-0012748
    
    private final static String DD_MM_YYYY_HH_MM = 'dd/MM/yyyy hh:mm'; // 10-10-2022/ Chetra Sarom / US-0012679 
    private final static String COUPON_SELLER_STAGE_RUNNING= 'Coupon Running'; //LA-18-10-2023:US-0014190
    private final static String COUPON_SELLER_STAGE_EXCECUTED= 'Coupon executed'; //SB 24.11.2023 US-0014448

    /*****************************************************************************************************************************
    @ Method:         fetchSingleSEPGlobalVar
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0010431 - Create Coupon details view on portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String prefix
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.5.2022 / Sambath Seng / Create the method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.06.2022 / Mony Nou / US-0011863
    *****************************************************************************************************************************/
    @AuraEnabled ( cacheable=true )   
    public static Seller_Portal_Global_Variables__mdt fetchSingleSEPGlobalVar(String prefix) {        
        //MN-10062022-US-0011863- Added Value_Big__c into the query => In case field Value__c is empty then showing text from Value_Big__c instead
        Seller_Portal_Global_Variables__mdt fetchMeta = [SELECT Id, Value__c, Value_Big__c, Value_in_German__c, DeveloperName FROM Seller_Portal_Global_Variables__mdt WHERE DeveloperName =: prefix];
        return fetchMeta;
    }


    /*****************************************************************************************************************************
    @ Method:         doDeleteCouponCoInvest
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nouseng@gaea-sys.com)
    @ Purpose:        US-0010656 - Ability to upload/manage items to item based coupons
    @                    - To delete selected coupon co-invest from Coupon Seller Detail Page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String cciIds - Array of selected Coupon Co-Invest's Id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.05.2022 / Mony Nou / Create the method
    @               : 28.06.2022 / SRONG TIN / Update the method US-0011918
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Object doDeleteCouponCoInvest(List<String> cciIds) {
        
        Map<String,Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{

            if (!cciIds.isEmpty()) {

                //SRONG:28.06.2022:US-0011918
                WithoutSharing.doDelete([select id from Coupon_Co_Invest__c where id IN:cciIds]);

                mResult.put('status', 'success');
            }
            

        } catch ( Exception ex) {
            System.debug('@@@@@messgee'+ex);
            mResult.put('message', 'Error:'+ex.getLineNumber()+':'+ ex.getMessage());
        }

        return mResult;
    }

    /*****************************************************************************************************************************
    @ Method:         updateCouponSellerStage2Review
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nouseng@gaea-sys.com)
    @ Purpose:        US-0010656 - Ability to upload/manage items to item based coupons
    @                    - Change Coupon Seller Stage to Review
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String csId - Coupon Seller's Id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.05.2022 / Mony Nou / Create the method
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Object updateCouponSellerStage2Review(String csId) {
        
        Map<String,Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{

            if (String.isNotBlank(csId)) {

                Coupon_Seller__c cs = new Coupon_Seller__c(
                    Id = csId,
                    Coupon_Seller_Stage__c = 'Review'
                );

                update cs;

                mResult.put('status', 'success');
            }
            

        } catch ( Exception ex) { mResult.put('message', 'Error:'+ex.getLineNumber()+':'+ ex.getMessage()); }

        return mResult;
    }

    /*****************************************************************************************************************************
    @ Method:         getCouponContractTemplate
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0010429 - Ability to sign Agreement in portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String csId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2022 / Sambath Seng / Create the method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.07.2022 / Mony Nou / US-0012015
    @               : 05.11.2022/vadhanak voun/US-0012034 - [UK] Localization for Coupon Contract
    @               : 12.07.2022/ SRONG TIN / US-0013632 - Ability to preview contract before moving coupon seller to contract signature
    @               : 05/06/2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
    @               : 25/11/2025 / Mony Nou / changed cacheable to false
    @               : 08/01/2026 / Chan Sophorn / US-0033468 - POP - SP - Populate Program Coupon info on Master Coupon Agreement Contract (Part 2) 
    *****************************************************************************************************************************/
    @AuraEnabled(cacheable=false)
    public static String getCouponContractTemplate(String csId)
    {
    	Map<Id,Coupon_Seller__c> mapCouponSeller = new Map<Id,Coupon_Seller__c>();
        String htmlBody = '';
        Coupon_Seller__c cs = getCS(csId);
        List<Coupon_Co_Invest__c> listCoInvest = getListCoinvest(csId);


        /* MN-25072022-US-0012015
        Set<String> setEmailTemplates = new Set<String>{
                EMAIL_COUPON_CONTRACT_DE_ITEM_SEP,
                EMAIL_COUPON_CONTRACT_DE_CAT_SEP
        };
        
        Map<String,EmailTemplate> mapEmailTemplate = new Map<String,EmailTemplate>();
        for(EmailTemplate emt : Database.query(SOQLEMAIL_TEMPLATES +' Where DeveloperName IN :setEmailTemplates'))
        {
            if(emt.DeveloperName == EMAIL_COUPON_CONTRACT_DE_ITEM_SEP){
                mapEmailTemplate.put(COUPON_ITEMBASE,emt);
            }else if(emt.DeveloperName == EMAIL_COUPON_CONTRACT_DE_CAT_SEP){
                mapEmailTemplate.put(COUPON_CATEGORYBASE,emt);
            }
            
        }

        EmailTemplate empt = (mapEmailTemplate.containsKey(cs.Coupon_Type__c)?mapEmailTemplate.get(cs.Coupon_Type__c):null);

        if(empt!=null){
                String htmlValue = empt.HtmlValue != null ? empt.HtmlValue : null; 
                htmlBody += mergeFieldsContractCoupon(htmlValue,cs);
                htmlBody = htmlBody.contains('{!catTable}')?htmlBody.replace('{!catTable}',generateHTMLTable(listCoInvest,htmlRowTemplate,false,empt)):htmlBody;			 
        }

        */

        /* MN-05062024-US-0015298: No longer use with Profile Name
            //MN-25072022-US-0012015
            Map<String, Map<String, String>> mProfEmailTemp = new Map<String, Map<String,String>> {
                PROF_SEP_DE => new Map<String, String>{
                    COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_DE_ITEM_SEP,
                    COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_DE_CAT_SEP
                },
                PROF_SEP_NA => new Map<String, String>{
                    COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_NA_ITEM_SEP,
                    COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_NA_CAT_SEP
                },
                PROF_SEP_AU => new Map<String, String>{ //MN-20022023-US-0012748
                    COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_AU_ITEM_SEP,
                    COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_AU_CAT_SEP
                }
            };
        */

        //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name
        Map<String, Map<String, String>> mSPMainDomainEmailTemp = new Map<String, Map<String,String>> {
            SEP_Helper.SEP_Domain_DE => new Map<String, String>{
                COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_DE_ITEM_SEP,
                COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_DE_CAT_SEP,
                COUPON_SCMC => EMAIL_COUPON_CONTRACT_DE_MC_SEP //LA-03-09-2025-US-0033254
            },
            SEP_Helper.SEP_Domain_NA => new Map<String, String>{
                COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_NA_ITEM_SEP,
                COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_NA_CAT_SEP
            },
            SEP_Helper.SEP_Domain_AU => new Map<String, String>{
                COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_AU_ITEM_SEP,
                COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_AU_CAT_SEP
            }
        };

        //12.07.2022/ SRONG TIN / US-0013632
        //User currentUser = [SELECT Contact.Account.SP_Coupons__c, Profile.Name,ContactId FROM User WHERE Id =: UserInfo.getUserId()]; //MN-01082024-US-0015661: Fixed ApexCRUDViolation from Apex PMD Scan

        //START--MN-01082024-US-0015661: Fixed ApexCRUDViolation from Apex PMD Scan
        String userQuery = 'SELECT Contact.Account.SP_Coupons__c, Profile.Name,ContactId FROM User WHERE Id =:UserId';
        List <User> lstUser = ApexSafe.query().secCheck(false).doQuery(userQuery, new Map<String, Object> {'UserId' => UserInfo.getUserId()});
        User currentUser = new User();
        for (User usr: lstUser) { currentUser = usr; }
        //--END

        Boolean isFromHive = false;
        if(currentUser.ContactId == null){
            // from Hive
            isFromHive = true;
        }
        
        //NK:05/11/2022:US-0012034
        Boolean isLocalize = MAP_CONTRACT_LOCALIZE.containsKey(cs.Main_Coupon_Site__c+'-'+cs.Coupon_Type__c);

        String spMainDomain = (SEP_Helper.sepUser.isEU() && !SEP_Helper.sepUser.isDE() && !islocalize)?SEP_Helper.SEP_Domain_DE:SEP_Helper.sepUser.domain; //MN-01082024-US-0015661: To allow EU SP Domain to sign DE Coupon Seller

        //if (String.isNotBlank(currentUser.Profile.Name) && mProfEmailTemp.containsKey(currentUser.Profile.Name) && String.isNotBlank(cs.Coupon_Type__c) || isLocalize || isFromHive) { //MN-05062024-US-0015298
        //if (mSPMainDomainEmailTemp.containsKey(SEP_Helper.sepUser.domain) && String.isNotBlank(cs.Coupon_Type__c) || isLocalize || isFromHive) { //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name //MN-01082024-US-0015661
        if (mSPMainDomainEmailTemp.containsKey(spMainDomain) && String.isNotBlank(cs.Coupon_Type__c) || isLocalize || isFromHive) { //MN-01082024-US-0015661: To allow EU SP Domain to sign DE Coupon Seller
            
            //12.07.2022/ SRONG TIN / US-0013632
            String emTDevName = '';
            if(!isLocalize && isFromHive){
                /*
                Map<String, String> profileSEP = new Map<String, String> {
                    'ebay.de' => PROF_SEP_DE,
                    'ebay.com' => PROF_SEP_NA,
                    'ebay.com.au'=> PROF_SEP_AU
                };
                String prfileName = profileSEP.get(cs.Main_Coupon_Site__c);
                emTDevName = mProfEmailTemp.get(prfileName).get(cs.Coupon_Type__c);
                */

                //START--MN-05062024-US-0015298
                Map<String, String> mCSSite2SPMainDomain = new Map<String, String> {
                    'ebay.de' => SEP_Helper.SEP_Domain_DE,
                    'ebay.com' => SEP_Helper.SEP_Domain_NA,
                    'ebay.com.au'=> SEP_Helper.SEP_Domain_AU
                };
                String domain = mCSSite2SPMainDomain.get(cs.Main_Coupon_Site__c);
                emTDevName = mSPMainDomainEmailTemp.get(domain).get(cs.Coupon_Type__c);
                //END

                
            }else{
                //emTDevName = isLocalize? MAP_CONTRACT_LOCALIZE.get(cs.Main_Coupon_Site__c+'-'+cs.Coupon_Type__c) : mProfEmailTemp.get(currentUser.Profile.Name).get(cs.Coupon_Type__c); //MN-05062024-US-0015298
                //emTDevName = isLocalize? MAP_CONTRACT_LOCALIZE.get(cs.Main_Coupon_Site__c+'-'+cs.Coupon_Type__c) : mSPMainDomainEmailTemp.get(SEP_Helper.sepUser.domain).get(cs.Coupon_Type__c); //MN-05062024-US-0015298 //MN-01082024-US-0015661
                emTDevName = isLocalize? MAP_CONTRACT_LOCALIZE.get(cs.Main_Coupon_Site__c+'-'+cs.Coupon_Type__c) : mSPMainDomainEmailTemp.get(spMainDomain).get(cs.Coupon_Type__c); //MN-01082024-US-0015661: To allow EU SP Domain to sign DE Coupon Seller
            }

            List<Coupon_Seller__c> listProgramCS;

            if (cs.RecordType.DeveloperName == MASTER_AGREEMENT_SELLER_REC_TYPE) {
              String masterCouponId = String.valueOf(cs.Coupon__c).substring(0,15); // 08012026:CSP/US-0033468
              listProgramCS = getSEPContractListProgramCouponSeller(masterCouponId, cs.Seller__r.Id); // 08012026:CSP/US-0033468
            }
            


            for (EmailTemplate empt : Database.query(SOQLEMAIL_TEMPLATES +' Where DeveloperName  =:emTDevName')) {
                String htmlValue = empt.HtmlValue != null ? empt.HtmlValue : null; 
                htmlBody += mergeFieldsContractCoupon(htmlValue,cs);
                htmlBody = htmlBody.contains('{!catTable}')?htmlBody.replace('{!catTable}',generateHTMLTable(listCoInvest,htmlRowTemplate,false,empt,currentUser.Profile.Name)):htmlBody;
                
                
                if (cs.RecordType.DeveloperName == MASTER_AGREEMENT_SELLER_REC_TYPE) {
                    htmlBody = htmlBody.contains('{!programCouponSellerTables}')?htmlBody.replace('{!programCouponSellerTables}',generateProgramCouponSellerHTMLTable(listProgramCS,htmlProgramTableTemplate,empt)):htmlBody;// 08012026:CSP/US-0033468
                }

                //MN-21022023-US-0012748 - Replace {CouponCoInvest_SellerFunding} with field Seller_Funding__c from the first Co-Invest record
                //if (currentUser.Profile.Name == PROF_SEP_AU) { //MN-05062024-US-0015298
                if (SEP_Helper.sepUser.isAU()) { //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name
                    String selFund = (listCoInvest.isEmpty())?'0':listCoInvest.get(0).Seller_Funding__c+'';
                    htmlBody = htmlBody.replace('{CouponCoInvest_SellerFunding}', selFund);
                }

            }

            

        }
        
        return htmlBody;
    }
     

    /*****************************************************************************************************************************
    @ Method:         mergeFieldsContractCoupon
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0010429 - Ability to sign Agreement in portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String s, Coupon_Seller__c cs
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2022 / Sambath Seng / Create the method
    @               : 17.06.2022 / Loumang SENG / update to call SEPDownloadController.CouponSellerWrapper
    @               : 10.08.2022 / Sophal Noch / US-0012207 - Changes to contract PDF Download - requested from legal
    @               : 16.08.2022 / Mony Nou / US-0012216 - NA Coupons: Downloading /storing Coupon Contract on Portal and in Hive
    @               : 22.11.2022/ SRONG TIN / US-0012185 - [FR] Downloading /storing Coupon Contract on Portal and in Hive
    @               : 28.02.2023 / Sambath Seng / US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
    @               : 05.01.2024 / Loumang SENG / US-0014486 - Add T&Cs to terms sheet
    @               : 02.09.2025 / Loumang SENG / 03.09.2025 / Loumang SENG / US-0033254 - POP - SP - Ability to Accept/Decline Coupon Seller Contract
    @               : 25.11.2025 / Mony Nou / US-0033542 - POP - SP - Display Signed Contract Thank you confirmation text on Seller Portal
    *****************************************************************************************************************************/
    public static String mergeFieldsContractCoupon(String s, Coupon_Seller__c cs) 
 	{
        SEPDownloadController.CouponSellerWrapper csw = new SEPDownloadController.CouponSellerWrapper(cs);
        //MN-25112025-US-0033542:START--
        s = processConditionalDisplayBlocks(s, cs.Coupon_Seller_Stage__c);
        //--END
        return s==null?'':s
        .replace('{Max_Redemptions__c}',csw.maxRedmeptions)
        .replace('{LegalEntity}',csw.legalEntity)
        .replace('{StreetName}',csw.streetName)
        .replace('{Zip}',csw.zip)
        .replace('{City}',csw.city) 
        .replace('{eBaySellerID}',csw.eBaySellerID)
        .replace('{CouponSites}',csw.couponSites)
        .replace('{CouponStartTime}',csw.couponStartTime)
        .replace('{CouponStartDate}',csw.formatcouponStartDate)
        .replace('{CouponEndTime}',csw.couponEndTime)
        // .replace('{CouponDiscount%}',csw.couponDiscount)
        // .replace('{CouponDiscountAmount}',csw.couponDiscountAmount) 
        .replace('{CouponDiscount%}{CouponDiscountAmount}',csw.couponDiscountAndDiscountAmount) 
        .replace('{CouponCap}',csw.maxDisc) 
        .replace('{CouponEndDate}',csw.formatcouponEndDate)
        .replace('{AdditionalArrangement}',csw.additionalArrangement)
        .replace('{Marketing_Coupon_Name__c}',csw.marketingName)
        .replace('{Minimum_Transaction_Value__c}',csw.minTransactionVal)
        .replace('{Country}',csw.country)
        .replace('{CouponCode}',csw.couponCode) //SB 30.6.2022 US-0011998 - Business Feedback Focus 75 AC4
        .replace('{SellerShareHolder__c}', csw.sellerShareHolder) //MN-25072022-US-0012015
        .replace('{eBay_Co_fund_Max__c}', csw.eBayCofundMax) //MN-25072022-US-0012015
        .replace('{eBay_Co_fund_Max_Text}', csw.eBayCofundMaxText) //MN-16082022-US-0012216
        .replace('{ContractSignatureDate}',csw.formatContractAcceptDate) // 10.08.2022 / Sophal Noch / US-0012207
        .replace('{ContractSignatureDate}',csw.formatContractAcceptDate)
        .replace('{ContractDueDate}',csw.couponDueDate)
        .replace('{Coupon_Additional_Terms__c}',csw.additionalArrangement)
        .replace('{MainCouponSite}',csw.mainCouponSite)//LA:25/11/2022:US-0012029
        .replace('{FR_Minimum_Transaction_Value__c}',csw.minTransactionValFr)//LA-30-11-2022-US-0012025 // FR contract use symbol on the right. e.g. after 50.00€
        .replace('{FR_CouponCap}',csw.maxDiscFr) //LA-30-11-2022-US-0012025 // FR contract use symbol on the right. e.g. after 50.00€
        .replace('{FR_CouponDiscount%_Amount}',csw.couponDiscountAndDiscountAmountFr) //LA-30-11-2022-US-0012025 // FR contract use symbol on the right. e.g. after 50.00€
        .replace('{LegalEntity}',csw.legalEntity) //MN-21022023-US-0012748
        .replace('{AdditionalArrangementOverride}', csw.additionalArrangementOverride) //MN-21022023-US-0012748
        .replace('{CouponCoInvest_SellerFunding}', csw.sellerFundingRate) //SB-28.02.2023-US-0012755
        .replace('{MaxItemsPerRedemption}', csw.maxItemsPerRedemption) //LA-05-01-2024-US-0014486
        .replace('{!SellerMaxContribution__c}', csw.sellerMaxContribution) //LA-02-09-2025-US-0033254
        .replace('{formatProgCouponEndDate}', csw.formatProgCouponEndDate) //MN-25112025-US-0033542
        .replace('{progMarketingName}', csw.progMarketingName) //MN-25112025-US-0033542
        ;
 	}
    
    /*****************************************************************************************************************************
    @ Method:         processConditionalDisplayBlocks
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        US-0033542 - POP - SP - Display Signed Contract Thank you confirmation text on Seller Portal
    @                   - Process Conditional Display Blocks in Coupon Contract Template
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String s, String csStage
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.11.2025 / Mony Nou / Create the method
    *****************************************************************************************************************************/
    @testVisible
    private static String processConditionalDisplayBlocks (String s, String csStage) {
        // Early exit if input doesn't contain conditional display patterns
        if (String.isBlank(s) || !s.contains('{' + START_DISPLAY_FOR)) {
            return s;
        }
        
        String result = s;
        
        // Find all START tags first to identify all stage names
        String startPattern = '\\{' + START_DISPLAY_FOR + '([^}]+)\\}';
        Pattern pattern = Pattern.compile(startPattern);
        Matcher matcher = pattern.matcher(s);
        
        Set<String> foundStages = new Set<String>();
        
        // Collect all unique stage names first
        while (matcher.find()) {
            String stageName = matcher.group(1);
            foundStages.add(stageName);
        }
        
        // Process each stage separately using regex for efficiency
        for (String stageName : foundStages) {
            // Use DOTALL flag to match across newlines
            String stagePattern = '(?s)\\{' + START_DISPLAY_FOR + stageName + '\\}(.*?)\\{' + END_DISPLAY_FOR + stageName + '\\}';
            
            if (stageName.equals(csStage)) {
                // For matching stage: replace blocks with content only (remove tags)
                result = result.replaceAll(stagePattern, '$1');
            } else {
                // For non-matching stage: remove entire blocks
                result = result.replaceAll(stagePattern, '');
            }
        }
        
        return result;
    }
    
    /*****************************************************************************************************************************
    @ Method:         getListProgramCouponSeller
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        US-0033542 - POP - SP - Display Signed Contract Thank you confirmation text on Seller Portal 
    @                - To get list of Program Coupon Seller by Master Coupon Id with limit size
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String csId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.11.2025 / Mony Nou / Create the method
    *****************************************************************************************************************************/
    public static List<Coupon_Seller__c> getListProgramCouponSeller(String masterCouponId, Integer limitSize){
        String query = SOQL_PROGCOPOUNSELLER+' Where MasterCouponId__c =:masterCouponId Order By CreatedDate LIMIT :limitSize';
        return ApexSafe.query().secCheck(true).doQuery(query, new Map<String, Object>{'masterCouponId' => masterCouponId, 'limitSize' => limitSize});
    }

    /*****************************************************************************************************************************
    @ Method:         getSEPContractListProgramCouponSeller
    @ Version:        1.0
    @ Author:         SENG Chan Sophorn
    @ Purpose:        08/01/2026 / Chan Sophorn / US-0033468 - POP - SP - Populate Program Coupon info on Master Coupon Agreement Contract (Part 2) 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String csId
    *****************************************************************************************************************************/
    public static List<Coupon_Seller__c> getSEPContractListProgramCouponSeller(String masterCouponId, String SellerId){
        String query = SOQL_SEPCONTRACTPROGCOPOUNSELLER+' Where MasterCouponId__c =:masterCouponId and Seller__r.Id =:SellerId  Order By CreatedDate';
        // return ApexSafe.query().secCheck(true).doQuery(query, new Map<String, Object>{'masterCouponId' => masterCouponId}); 
        return ApexSafe.query().secCheck(true).doQuery(query, new Map<String, Object>{'masterCouponId' => masterCouponId, 'SellerId' => SellerId});
    }

    /*****************************************************************************************************************************
    @ Method:         getListCoinvest
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0010429 - Ability to sign Agreement in portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String csId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2022 / Sambath Seng / Create the method
    *****************************************************************************************************************************/
    public static List<Coupon_Co_Invest__c> getListCoinvest(String csId){
    	return Database.query(SOQL_COUPONCOINVEST+' Where Coupon_Seller__c =:csId');
    }

    /*****************************************************************************************************************************
    @ Method:         generateHTMLTable
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0010429 - Ability to sign Agreement in portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<Coupon_Co_Invest__c> listCovinvest,String htmlRowStringTemplate,Boolean istext,EmailTemplate emt, String userProf
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2022 / Sambath Seng / Create the method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.07.2022 / Mony Nou / US-0012015 - NA Localization for Coupon Contract
    *****************************************************************************************************************************/
    private static String generateHTMLTable(List<Coupon_Co_Invest__c> listCovinvest,String htmlRowStringTemplate,Boolean istext,EmailTemplate emt, String userProf)
 	{ 
 		if(listCovinvest==null || (listCovinvest <>null && listCovinvest.isEmpty()))return '';
        
        /* MN-05062024-US-0015298: No longer use with Profile Name
        //MN-29072022-US-0012015
        Map<String, String> mHTMLHeader = new Map<String, String>{
            PROF_SEP_DE => htmlHeadTemplateDE,
            PROF_SEP_NA => htmlHeadTemplateNA
        };
        */

        //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name
        Map<String, String> mHTMLHeader = new Map<String, String>{
            SEP_HELPER.SEP_Domain_DE => htmlHeadTemplateDE,
            SEP_HELPER.SEP_Domain_NA => htmlHeadTemplateNA
        };

 		String htmlString = htmlTableTemplate;
        // String htmlHeadString = htmlHeadTemplateDE; //MN-29072022-US-0012015
        //MN-29072022-US-0012015
        //String htmlHeadString = (mHTMLHeader.containsKey(userProf))?mHTMLHeader.get(userProf):''; //MN-05062024-US-0015298: No longer use with Profile Name
        String htmlHeadString = (mHTMLHeader.containsKey(SEP_Helper.sepUser.domain))?mHTMLHeader.get(SEP_Helper.sepUser.domain):''; //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name

 		String htmlRowString  = '';
 		for(Coupon_Co_Invest__c cci : listCovinvest)
 		{
 			htmlRowString = htmlRowString + htmlRowStringTemplate
 			.replace('{!catName}', cci.Category__c == null ? 'N/A' : cci.Category__c)
 			.replace('{!catId}', String.isBlank(cci.Category_ID__c) ? 'N/A' : cci.Category_ID__c)
 			.replace('{!coinvest%}', cci.Co_Invest__c == null ? 'N/A' : cci.Co_Invest__c + '%');
 		}
 		htmlString = istext ? htmlRowString : htmlString.replace('{!rows}',htmlRowString).replace('{!tableHeader}',htmlHeadString);
 		return htmlString;
 	}

    /*****************************************************************************************************************************
    @ Method:         generateProgramCouponSellerHTMLTable
    @ Version:        1.0
    @ Author:         SENG Chan Sophorn
    @ Purpose:        US-0033468 - POP - SP - Populate Program Coupon info on Master Coupon Agreement Contract (Part 2) 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<Coupon_Seller__c>  listProgramCS,String htmltableStringTemplate,EmailTemplate emt
    *****************************************************************************************************************************/
    public static String generateProgramCouponSellerHTMLTable(List<Coupon_Seller__c>  listProgramCS,String htmltableStringTemplate, EmailTemplate emt)
 	{ 

 		if(listProgramCS==null || (listProgramCS <>null && listProgramCS.isEmpty()))return '';

        Map<String, String> mHTMLHeader = new Map<String, String>{
            SEP_HELPER.SEP_Domain_DE => htmlHeadTemplateDE
        };

 		String htmlString  = '';
        Integer index = 1;
 		for(Coupon_Seller__c proCouponSeller : listProgramCS)
 		{
            DateTime couponStartDate = Datetime.newInstance(proCouponSeller.Coupon_Start_Date__c.Year(),proCouponSeller.Coupon_Start_Date__c.Month(),proCouponSeller.Coupon_Start_Date__c.Day());
            DateTime couponEndDate = Datetime.newInstance(proCouponSeller.Coupon_End_Date__c.Year(),proCouponSeller.Coupon_End_Date__c.Month(),proCouponSeller.Coupon_End_Date__c.Day());
            String couponStartTime = ApexUtil.formatTime24h(proCouponSeller.Coupon_Start_Time__c); 
            String couponEndTime = ApexUtil.formatTime24h(proCouponSeller.Coupon_End_Time__c); 

 			htmlString = htmlString + htmltableStringTemplate
 			.replace('{!index}',String.valueOf(index))
 			.replace('{!CouponCode} ', proCouponSeller.Coupon_ID__c == null ? '' : String.valueOf(proCouponSeller.Coupon_ID__c))
 			.replace('{!MarketingCouponName}', proCouponSeller.Marketing_Coupon_Name__c == null ? '' : String.valueOf(proCouponSeller.Marketing_Coupon_Name__c))
 			.replace('{!CouponStartTime}', couponStartTime)
 			.replace('{!CouponStartDate}', String.valueOf(couponStartDate.format(DF_DD_MM_YYYY)))
 			.replace('{!CouponEndTime}', couponEndTime)
 			.replace('{!CouponEndDate}', String.valueOf(couponEndDate.format(DF_DD_MM_YYYY)))
 			.replace('{!AdditionalArrangement}', String.isBlank(proCouponSeller.Additional_Terms__c) ? '' : proCouponSeller.Additional_Terms__c);
            index++;
 		}
 		return htmlString;
 	}
   

    /*****************************************************************************************************************************
    @ Method:         getCS
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0010429 - Ability to sign Agreement in portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String csId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.06.2022 / Sambath Seng / Create the method
    *****************************************************************************************************************************/
    public static Coupon_Seller__c getCS(String csId)
    {  
        return Database.query(SOQL_COUPON_SELLER+' WHERE Id =:csId');
    }

    /*****************************************************************************************************************************
    @ Method:         handleContractCouponSellerAgree
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0010429 - Ability to sign Agreement in portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String csId, String userId, String currentContactId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.06.2022 / Sambath Seng / Create the method
    @               : 24.04.2023 / Sambath Seng / US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
    @               : 13.06.2023/vadhanak voun/US-0013528 - Allow seller to sign contract after declining until contract due date
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> handleContractCouponSellerAgree(String csId, String userId, String currentContactId)
 	{
        Map<String,Object> mapResult = new Map<String,Object>();
        Savepoint sp = Database.setSavepoint();
        try{
            // String couponSellerId = csId;
            // String curUId = userId;
            // String curCId = currentContactId;
            csId = String.escapeSingleQuotes(csId);// SB 24.02.2023 US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
            if(String.isNotBlank(csId))
            {
                Coupon_Seller__c cs = getCS(csId);
                 
                cs.Coupon_Seller_Stage__c = COUPON_SELLER_STAGE_CONTRACT_SIGNED;
                cs.Contract_Accept_Date__c = System.now();
                cs.Contract_Accepted_From__c = !Test.isRunningTest() ? Auth.SessionManagement.getCurrentSession().get('SourceIp') : '';
                cs.Contract_Signed_Declined_By__c = currentContactId;
                CouponSellerTriggerHandler.isUpdatedSellerStage = true;
                CouponSellerTriggerHandler.currUserId = userId;

                //NK:13/06/2023/US-0013528 - clear the decline reason - incase re-accept
                cs.Seller_Declined_Reasons__c = '';
                cs.Comment__c = '';

                update cs;

                // User currentUser = [SELECT Profile.Name FROM User WHERE Id =: UserInfo.getUserId()];
                //MN-21022023-US-0012748-Skip Create Downloaded PDF For now, this criteria can be removed once we have story to create downloaded PDF for AU
                // SB 24.02.2023 US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
                // if (currentUser.Profile.Name != PROF_SEP_AU) { 
                    Map<String,String> resultAtt = SEPCouponContractDownloadController.createAttachment(cs);
                    mapResult.put('attachmentId',resultAtt.get('id'));
                    mapResult.put('fileNamePDF',resultAtt.get('name'));                
                // }
                
                 
            }
            mapResult.put('status','ok');
        }catch(DMLException dex)
    	{	Database.rollback(sp);mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}catch(Exception ex)
    	{   Database.rollback(sp);mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());	}

        return mapResult;
        
 	}

     /*****************************************************************************************************************************
    @ Method:         getAllPickListValue
    @ Version:        1.0
    @ Author:         Chetra Sarom (chetra.sarom@gaea-sys.com)
    @ Purpose:        US-0010436 - Ability to decline single coupon participation
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String csId, String rejectionReasons, String reasonsComments, String contactId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.06.2022 / Chetra Sarom / Create the method
                      30.09.2025 / Davy Sorn / US-0033398
                      : 10/12/2025 / Sovantheany Dim / US-0033746 - POP - Trigger to update status of Program Seller to Opt-Out - instead of Seller Declined 
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> handleUpdateCouponSellerStage(String csId, String rejectionReasons, String reasonsComments, String contactId)
 	{
        Map<String,Object> mapResult = new Map<String,Object>();
        Savepoint sp = Database.setSavepoint();
        Coupon_Seller__c cs = getCS(csId);
        if(cs!=null)
        {   // Program Coupon Record Type: Declined; Others: Seller Declined
            cs.Coupon_Seller_Stage__c = cs.RecordType.DeveloperName == PROGRAM_COUPON_SELLER_REC_TYPE ? PROGRAM_COUPON_SELLER_STAGE_SELLER_OPT_OUT : COUPON_SELLER_STAGE_SELLER_DECLINED; // DS 30/09/2025 US-0033398 //TH:US-0033746 change PROGRAM_COUPON_SELLER_STAGE_SELLER_DELINED to PROGRAM_COUPON_SELLER_STAGE_SELLER_OPT_OUT
            cs.Contract_Signed_Declined_By__c = contactId;
            cs.Seller_Declined_Reasons__c = rejectionReasons;
            cs.Comment__c = reasonsComments;
            try
            {	
                Database.SaveResult[] result = ApexSafe.dml().secCheck(false).doUpdate(new List<Coupon_Seller__c>{cs}, true); // DS 30/09/2025 US-0033398 using ApexSafe
                if (result[0].isSuccess()) {
                    mapResult.put('results',cs);
                    mapResult.put('status','ok');
                } else {
                    mapResult.put('status','ko'); mapResult.put('error',result[0].getErrors()[0].getMessage()); mapResult.put('error_detail',result[0].getErrors()[0].getMessage());
                }
            }catch(DMLException dex)
            {	Database.rollback(sp);mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
            }catch(Exception ex)
            {   Database.rollback(sp);mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());	}
           
        } 
        return mapResult;
        
 	}

    /*****************************************************************************************************************************
    @ Method:   getAllPickListValue
    @ Version:  1.0
    @ Author:         Chetra Sarom (chetra.sarom@gaea-sys.com)
    @ Purpose:        US-0010436 - Ability to decline single coupon participation
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      sObject's API Name , API Name 
    ------------------------------------------------------------------------------------------------------------------------------
     @ Change history: 16.06.2022 / Chetra Sarom / Create the method
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> getAllPickListValue(String objectApiName, String field_name)
 	{
        Set<String> validPicklist = new Set<String>{
			'Seller did not respond',
            'Contract Breach',
            'Contract Voided',
            'Seller not reached',
            'Seller added to coupon by mistake'
		};
        Map<String, String> mapPickListValues = new Map<String, String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        Map<String, String> picklistFieldValues = new Map<String, String>();

        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(field_name).getDescribe().getPickListValues();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            if (!validPicklist.contains(objPickList.getValue())) {
                picklistFieldValues.put(objPickList.getLabel(), objPickList.getValue());
            }
        }

        return picklistFieldValues;
 	}



    private final static Set<String> SET_STAGE_SHOW_DOWNLOAD_CONTRACT  = new Set<String>{
        'Contract Signed','Coupon Running','Coupon executed','T34 Statement Send'
        //'Contract Signed','Coupon Running','Coupon executed','T4 Statement Send','T34 Statement Send','Invoice paid'           
    };//LA-05-06-2023-US-0013029: Retire picklist value 'T4 Statement Send' , 'Invoice paid'
    private final static Set<String> SET_STAGE_SHOW_TAB  = new Set<String>{
        'Contract Send','Contract Signed','Coupon Running','Coupon executed','T34 Statement Send'
        //'Contract Send','Contract Signed','Coupon Running','Coupon executed','T4 Statement Send','T34 Statement Send','Invoice paid'
    }; // SB 20.6.2022 US-0010429 Change variable name //LA-05-06-2023-US-0013029: Retire picklist value 'T4 Statement Send' , 'Invoice paid'

    private final static Set<String> SET_STAGE_HIDE_TAB_ARTICLE  = new Set<String>{
        'Targeted','Reached'
        //'Targeted','Reached','Commited'
    }; // CT 23.06.2022 / Chetra Sarom / US-0011912 //LA-05-06-2023-US-0013029: Retire picklist value 'Commited'

    private final static Set<String> SET_STAGE_SHOW_EXCLUSION_TAB = new Set<String>{
        PROGRAM_COUPON_SELLER_STAGE_DRAFT, PROGRAM_COUPON_SELLER_STAGE_OPTED_IN
    }; // MN-19012026-US-0033366

   
     /*****************************************************************************************************************************
    @ Method:         getCouponSeller
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0010429 - Ability to sign Agreement in portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.06.2022 / Sambath Seng / Create the method
    @               29.06.2022 / Acmatac SEING / US-0011991 - Fixing issues for Coupon Linked Accounts
    @               31.01/2023/ vadhanak voun /  US-0013170 - Wrongly displayed time and date format
    @               20.02/2023/ Mony Nou /  US-0012748 - [AU] Localization for Coupon Contract
    @               13.06.2023/vadhanak voun/US-0013528 - Allow seller to sign contract after declining until contract due date
    @               10.07.2023 / Mony Nou / US-0012496 - Allow declining of coupon at Negotiation
    @               14.09.2023 / Sambath Seng / US-0014083 - Change the Coupon Transaction file access
    @               21.09.2023 / Loumang SENG / US-0014149 - Categories list component on SCMC Coupon seller page in SEP
    @               24.11.2023 / Sambath Seng / US-0014448 - Coupon Performance enhancements
    @               05/06/2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
    @               08/14/2025 / SRONG TIN / US-0033261 - CA SP - Contract T&Cs View and Download
    @               02.09.2025 / Loumang SENG / US-0033254 - POP - SP - Ability to Accept/Decline Coupon Seller Contract
    @               25/09/2025 / Davy SORN / US-0033398 - POP - SP - Ability to view related child Coupons and Item List | Incl Opt Out Part 2
    @               12/12/2025 / SENG Chan Sophorn / US-0033567 - POP - SP - Add Button, New Field and update text on Program Coupon Layout - view Master Agreement
    @               19/01/2026 / Mony Nou / US-0033366 - POP - SP - Ability for Sellers to Upload Coupon Item Exclusions in Seller Portal 
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getCouponSeller2(String csId)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        Coupon_Seller__c cs = getCS(csId);

        Boolean isNegotiation = cs.Coupon_Seller_Stage__c== COUPON_SELLER_STAGE_NEGO;
        Boolean isItemBase = (cs.Coupon_Type__c==COUPON_ITEMBASE && !SET_STAGE_HIDE_TAB_ARTICLE.contains(cs.Coupon_Seller_Stage__c));

        // START 26/09/2025 / Davy SORN / US-0033398
        String strCouponStartDateTime = cs.Coupon_Start_Date__c + ' ' + cs.Coupon_Start_Time__c;
        strCouponStartDateTime = strCouponStartDateTime.replace('.000Z',''); // "2025-09-22 00:00:00"
        Datetime couponStartDateTime = Datetime.valueOfGmt(strCouponStartDateTime);
        Datetime currentDateTime = Datetime.now();
        Boolean isVisibleOptOutButton = true;
        Boolean isProgramCouponSeller = cs.RecordType.DeveloperName == PROGRAM_COUPON_SELLER_REC_TYPE;
        if (currentDateTime >= couponStartDateTime) {
            isVisibleOptOutButton = false;
        }
        mapResult.put('isVisibleOptOutButton', isVisibleOptOutButton);
        mapResult.put('isProgramCouponSeller', isProgramCouponSeller);
        mapResult.put('coInvestFileId', cs.CoInvestFileSFID__c);
        // END 26/09/2025 / Davy SORN / US-0033398

        // START 19/01/2026 / Mony Nou / US-0033366
        Boolean isShowExclusionTab = isProgramCouponSeller 
            && SET_STAGE_SHOW_EXCLUSION_TAB.contains(cs.Coupon_Seller_Stage__c) 
            && couponStartDateTime.addHours(-48) > currentDateTime;
        mapResult.put('isShowExclusionTab', isShowExclusionTab);
        // END 19/01/2026 / Mony Nou / US-0033366

        // START 01/10/2025 / Davy SORN / US-0033174
        Boolean isMasterCoupon = cs.RecordType.DeveloperName == MASTER_AGREEMENT_SELLER_REC_TYPE;
        mapResult.put('isMasterCoupon', isMasterCoupon);
        // END US-0033174

        mapResult.put('cs', cs);
        mapResult.put('sellerCouponType',cs.Coupon_Type__c);        
        // mapResult.put('isShowContract',SET_STAGE_SHOW_TAB.contains(cs.Coupon_Seller_Stage__c));
        mapResult.put('isCategoryBase',(cs.Coupon_Type__c==COUPON_CATEGORYBASE || cs.Coupon_Type__c==COUPON_SCMC));//LA-21-09-2023-US-0014149: Add condition for SCMC coupon type
        mapResult.put('isNegotiation', isNegotiation);
        //NK:13/06/.2023/US-0013528
        Date tDay = System.today();
        Boolean declineButCanAccept = (cs.Coupon_Seller_Stage__c ==COUPON_SELLER_STAGE_SELLER_DECLINED && cs.Coupon_Contract_Due_Date__c >= tDay);
        //MN-10072023-US-0012496 -- START
        // Seller able to decline Coupon Seller in stage Negotiation only when there is no Coupon Co-Invest 
        // Also add additaionl criteria on US-0013528: to only display contract tab only when there is Coupon Co-Invest

        //25/09/2025 / Davy SORN / US-0033398 Use ApexSafe instead - fixed PMD error
        List<Coupon_Seller__c> lsCouponSeller = ApexSafe.query().doQuery(STR_QUERY_COUPON_SELLER, new Map<String, Object> {'csId' => csId});
        for (Coupon_Seller__c tmp : lsCouponSeller) {
            mapResult.put('canDeclineAtNegotiation', isNegotiation && tmp.Coupon_Co_Invests__r.isEmpty());
            mapResult.put('isDeclineAtNegotiation', (cs.Coupon_Seller_Stage__c ==COUPON_SELLER_STAGE_SELLER_DECLINED && tmp.Coupon_Co_Invests__r.isEmpty()));
            declineButCanAccept = declineButCanAccept && !tmp.Coupon_Co_Invests__r.isEmpty();
        }
        //--END-MN-10072023-US-0012496

        //mapResult.put('isShowContractAgreeButton',cs.Coupon_Seller_Stage__c== COUPON_SELLER_STAGE_CONTRACT_SEND); // SB 20.6.2022 US-0010429
        mapResult.put('isShowContractAgreeButton',(cs.Coupon_Seller_Stage__c== COUPON_SELLER_STAGE_CONTRACT_SEND || declineButCanAccept)); // SB 20.6.2022 US-0010429

        mapResult.put('isCouponSellerStageNotContractSend',(cs.Coupon_Seller_Stage__c <> COUPON_SELLER_STAGE_CONTRACT_SEND));
        mapResult.put('isItemInReview',(cs.Coupon_Seller_Stage_Portal__c == COUPON_SELLER_STAGE_REVIEW_SEP));//SB 23.6.2022 US-0011958 - Change Requests Focus 75
        
        // US-0011991 - Fixing issues for Coupon Linked Accounts
        Set<String> sp_Coupon_AllowTo_UploadItems = new Set<String>{SP_COUPON_FULL_ACCESS, SP_COUPON_READ_ONLY, SP_COUPON_ALLOWED};
        
        //25/09/2025 / Davy SORN / US-0033398 Use ApexSafe instead - fixed PMD error
        List<User> lsUser = ApexSafe.query().secCheck(false).doQuery(STR_QUERY_CURRENT_USER, new Map<String, Object> {'userId' => UserInfo.getUserId()});
        User currentUser = lsUser[0];
        mapResult.put('spCouponValue', currentUser.Contact.Account.SP_Coupons__c);
        mapResult.put('profileName', currentUser.Profile.Name);
        mapResult.put('isEUDomain', SEP_Helper.sepUser.isEU()); //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name
        mapResult.put('isNADomain', SEP_Helper.sepUser.isNA()); //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name
        mapResult.put('hasUploadItemsAccess', sp_Coupon_AllowTo_UploadItems.contains(currentUser.Contact.Account.SP_Coupons__c) && isNegotiation && isItemBase);
        mapResult.put('isSPCouponReadOnly', currentUser.Contact.Account.SP_Coupons__c == SP_COUPON_READ_ONLY);
        //NK:13/06/.2023/US-0013528 - declineButCanAccept
        Boolean isContractAvailable = !isProgramCouponSeller && (declineButCanAccept || SET_STAGE_SHOW_TAB.contains(cs.Coupon_Seller_Stage__c)) && (currentUser.Contact.Account.SP_Coupons__c == SP_COUPON_FULL_ACCESS || currentUser.Contact.Account.SP_Coupons__c == SP_COUPON_ALLOWED);
        mapResult.put('isContractAvailable', isContractAvailable);
        mapResult.put('isNegoFullAccessOrAllowed', isNegotiation && (currentUser.Contact.Account.SP_Coupons__c == SP_COUPON_FULL_ACCESS || currentUser.Contact.Account.SP_Coupons__c == SP_COUPON_ALLOWED));//SB 05.07.2022 US-0011958 - Change Requests Focus
        
        
        //NK:13/06/.2023/US-0013528 - declineButCanAccept
        Boolean showViewAgreement = (declineButCanAccept)|| (cs.Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_CONTRACT_SEND && (cs.Coupon_Contract_Due_Date__c >= tDay || (cs.Coupon_Contract_Due_Date__c < tDay && cs.Allow_reaccept_contract__c))
                                                            && (currentUser.Contact.Account.SP_Coupons__c == SP_COUPON_FULL_ACCESS || currentUser.Contact.Account.SP_Coupons__c == SP_COUPON_ALLOWED));
        mapResult.put('showViewAgreement', showViewAgreement);
        //12.07.2022/ SRONG TIN / US-0013632
        //Boolean isDEPortalProfile = currentUser.Profile.Name == PROF_SEP_DE; //MN-05062024-US-0015298
        Boolean isDEPortalProfile = SEP_Helper.sepUser.isEU(); //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name

        //From Hive
        if(currentUser.ContactId == null && cs.Main_Coupon_Site__c == 'ebay.de'){
            isDEPortalProfile = true;
        }
        //17.07.2022/ SRONG TIN / US-0013632
        if(currentUser.ContactId == null && cs.Coupon_Type__c==COUPON_ITEMBASE){
            isItemBase = true;
        }
        mapResult.put('isItemBased', isItemBase); // CT 23.06.2022 / Chetra Sarom / US-0011912
        mapResult.put('isMcCoupon', cs.Coupon_Type__c==COUPON_SCMC);//LA-02-09-2025-US-0033254
        //To check mainsite for preview contract
        Set<String> mainSite = new Set<String>{'ebay.co.uk','ebay.fr','ebay.it','ebay.com.au','ebay.ca'};
        mapResult.put('isDEPortalProfile', isDEPortalProfile);
        mapResult.put('isUK', cs.Main_Coupon_Site__c == 'ebay.co.uk');
        mapResult.put('isFR', cs.Main_Coupon_Site__c == 'ebay.fr');//LA-US-0012025
        mapResult.put('isIT', cs.Main_Coupon_Site__c == 'ebay.it');//LA-US-0012029
        mapResult.put('isAU', cs.Main_Coupon_Site__c == 'ebay.com.au'); //MN-20022023-US-0012748
        mapResult.put('isCA', cs.Main_Coupon_Site__c == 'ebay.ca'); //SRONG TIN - US-0033261
        mapResult.put('isDefault', !mainSite.contains(cs.Main_Coupon_Site__c));
        //10-10-2022/ Chetra Sarom / US-0012679 - Coupons Item Upload deadline Note on Seller portal
        DateTime negotiationEndDate = Datetime.valueOf(cs.Negotiation_End_Date__c);

        //mapResult.put('negotiationEndDate',  negotiationEndDate.format(DD_MM_YYYY_HH_MM));
        //NK:31/01/2023:US-0013170
        mapResult.put('negotiationEndDate', negotiationEndDate == null ? '' : negotiationEndDate.format(ApexUtil.MAP_LOCALE_DATEFORMAT().get(UserInfo.getLocale())));//LA-21-09-2023-US-0014149: prevent error when SCMC coupon type with negotiationEndDate == null

        // end 10-10-2022/ Chetra Sarom / US-0012679 - Coupons Item Upload deadline Note on Seller portal
        // List<Attachment> listAtt = [Select Id,Name From Attachment where ParentId=:csId ORDER BY CreatedDate DESC Limit 1];
        // if(SET_STAGE_SHOW_DOWNLOAD_CONTRACT.contains(cs.Coupon_Seller_Stage__c) && !listAtt.isEmpty())
        // {            
        //     mapResult.put('attachmentId',listAtt[0].Id);
        //     mapResult.put('fileNamePDF',listAtt[0].Name);      
            
        //     mapResult.put('showDownlaodPDF',SET_STAGE_SHOW_DOWNLOAD_CONTRACT.contains(cs.Coupon_Seller_Stage__c));
        // }
        
        // SB 14.09.2023 US-0014083 add condition for description = System.label.CS_GeneratePDFFileDesc
        //25/09/2025 / Davy SORN / US-0033398 Use ApexSafe instead - fixed PMD error
        List<ContentDocumentLink> listAtt = ApexSafe.query().doQuery(STR_QUERY_DOCUMENT_LINK, new Map<String, Object> {'csId' => csId, 'pDescription' => System.label.CS_GeneratePDFFileDesc});
        if(SET_STAGE_SHOW_DOWNLOAD_CONTRACT.contains(cs.Coupon_Seller_Stage__c) && !listAtt.isEmpty()) {
            //25/09/2025 / Davy SORN / US-0033398 Use ApexSafe instead - fixed PMD error
            List<ContentVersion> cv = ApexSafe.query().doQuery(STR_QUERY_CONTENT_VERSION, new Map<String, Object> {'cdId' => listAtt[0].ContentDocumentId});
            mapResult.put('attachmentId',cv[0].Id);
            mapResult.put('contentDocumentId', listAtt[0].ContentDocumentId); // TH: US-0034229 - Add ContentDocumentId for file preview
            mapResult.put('fileNamePDF',cv[0].Title);
            mapResult.put('showDownlaodPDF',SET_STAGE_SHOW_DOWNLOAD_CONTRACT.contains(cs.Coupon_Seller_Stage__c));
        }

        //TH:US-0011560
        if(cs.Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_STATEMENT_GENERATED){
            //25/09/2025 / Davy SORN / US-0033398 Use ApexSafe instead - fixed PMD error
            List<ContentDocumentLink> listAtt2 = ApexSafe.query().doQuery(STR_QUERY_DOCUMENT_LINK, new Map<String, Object> {'csId' => csId, 'pDescription' => System.label.CS_GenerateStatementFileDesc});
            if(!listAtt2.isEmpty()){
                //25/09/2025 / Davy SORN / US-0033398 Use ApexSafe instead - fixed PMD error
                ContentVersion[] cv = ApexSafe.query().doQuery(STR_QUERY_CONTENT_VERSION, new Map<String, Object> {'cdId' => listAtt2[0].ContentDocumentId});
                mapResult.put('relatedFileId',cv[0].Id);
                mapResult.put('relatedFileName',cv[0].Title); 
                mapResult.put('isVisible',true);
            }else{
                mapResult.put('isVisible',false);
            }
        }

        // SB 24.11.2023 US-0014448
        Set<String> showCouponPerformanceStage = new Set<String>{
            COUPON_SELLER_STAGE_RUNNING,
            COUPON_SELLER_STAGE_EXCECUTED,
            COUPON_SELLER_STAGE_STATEMENT_GENERATED
        };

        mapResult.put('showCouponPerformanceSection',showCouponPerformanceStage.contains(cs.Coupon_Seller_Stage__c));//LA-18-10-2023:US-0014190,SB 24.11.2023 US-0014448

        // 12/12/2025 / CSP:US-0033567
        String targetUrlMasterAgreementCouponSeller = getUrlMasterAgreementCouponSeller( cs.Master_Agreement_Coupon_Seller__c, cs.Master_Agreement_Coupon_Seller__r.Name);
        mapResult.put('targetUrlMasterAgreementCouponSeller', targetUrlMasterAgreementCouponSeller);

        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method        : getFieldSet
    @ Version       : 1.0
    @ Author        : LoumAng SENG (loumang.seng@gaea-sys.com)
    @ Purpose       : US-0014190 - Coupon performance on Seller Portal (AC3)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter     : String sObjectName, String fieldSetName 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.10.2023 / LoumAng SENG / Create the method
    *****************************************************************************************************************************/
    @AuraEnabled
    public static String getFieldSet(String sObjectName, String fieldSetName) {
        return ApexUtil.getFieldSet(sObjectName,fieldSetName);        
    }
    

    /*****************************************************************************************************************************
    @ Method        : getUrlMasterAgreementCouponSeller
    @ Version       : 1.0
    @ Author        : Seng Chan Sophorn
    @ Purpose       : US-0033567 - POP - SP - Add Button, New Field and update text on Program Coupon Layout - view Master Agreement
    ------------------------------------------------------------------------------------------------------------------------------
    @Parameter     : Boolean isContractAvailable, Id masterAgreementCouponSellerId, String masterAgreementCouponSellerName
    *****************************************************************************************************************************/
    @AuraEnabled
    public static String getUrlMasterAgreementCouponSeller(Id masterAgreementCouponSellerId, String masterAgreementCouponSellerName) {

        if (masterAgreementCouponSellerId == null || masterAgreementCouponSellerName == null) {
            return ''; 
        }

        String masterCouponSellerName = masterAgreementCouponSellerName.replaceAll('-', '');
        String targetUrlMasterAgreementCouponSeller = String.format(
            '/s/coupon-seller/{0}/{1}?tabset=tab2', 
            new List<Object>{ masterAgreementCouponSellerId, masterCouponSellerName }
        );
        return targetUrlMasterAgreementCouponSeller;        
    }
}