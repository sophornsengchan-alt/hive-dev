/*********************************************************************************************************************************
 @ Class:          CouponSellerTriggerHandler
 @ Version:        1.0
 @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Handler Class for trigger Coupon Seller
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.04.2019 /  / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.08.2021 / Mony Nou  / US-0009746 - Coupon - enable deletion of coupon related records
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 30.08.2021 / Mony Nou  / US-0009948 - Replace Email field with a Contact lookup field on Coupon Seller object 
                                                            and use it in communication to sellers.
@ Change history: 20.09.2021 / Sovantheany Dim  / US-0010302 - Coupon seller: Generate and attach a summary of seller contract confirmation                                                     
@ Change history: 03.11.2021 / Sambath Seng  / US-0010476 - US-0010476 - AU Coupon email template content update                                                        
@ Change history: 11.02.2022 / Loumang SENG  / US-0010777 - External Sharing for Coupon Seller Object           
@ Change history: 16.03.2022 / Chetra Sarom / US-0010643 - Coupon seller record deletion error message update   
@ Change history: 12.05.2022 / Sambath Seng / US-0010431 - Create Coupon details view on portal
@ Change history: 19.05.2022 / Mony Nou / US-0010656 - Ability to upload/manage items to item based coupons - AC6
@ Change history: 08.06.2022 / Mony Nou / US-0011834 - Add 'Coupon Additional Term' field into UK contract template
@ Change history: 01.06.2022 / Sambath Seng / US-0011998 - Business Feedback Focus 75 AC3
@ Change history: 08.08.2022 / Bora Chhorn / US-0012236 - Set NA coupon seller stage seller declined if contract not accepted Focus 78 AC2
@ Change history: 25.08.2022 / Mony Nou / US-0012276 - Disable the US contract emails for Seller's inbox
@ Change history: 29.08.2022 / Loumang SENG / US-0012338 - Auto update coupon seller stage if Coupon at Seller Negotiation
@ Change history: 30.08.2022 / Bora Chhorn / US-0011942 - [DE Launch] Deactivate existing coupon seller email flows for launch
@ Change history: 02.09.2022 / Chetra Sarom / US-0012067 - Deactivate automatic task "Urgent Action Required - Call the Seller"
@ Change history: 16.09.2022 / Sambath Seng / US-0012633 - Ignore other ebay sites email processes if main site is ebay.de
@ Change history: 27.10.2022 / Sovantheany Dim / US-0012864 - Move coupon seller owner in BCC for coupon launch reminder communication
@ Change history: 15.12.2022 / Mony Nou / US-0012734 - [UK] Accessibility Configurations - Cannot deploy before launch
@ Change history: 10.01.2023 / Loumang SENG / US-0012995 - Additional safeguarding for coupon seller automation
@ Change history: 11.01.2023 / Mony Nou / US-0012694 - [FR] Accessibility Configurations - Cannot deploy before launch
@ Change history: 16.01.2023 / Sambath Seng / US-0012735 - Migrate coupon start reminder to seller communication records
@               : 02.02.2023/vadhanak voun  / US-0013147 - Amend UK approval process for seller portal launch
@               : 08.02.2023 / Sophal Noch / US-0013047 - Change recipient of IT contract signature confirmation email
@               : 22.02.2023 / Sophal Noch / US-0012801 - Accessibility Configurations
@               : 22.02.2023 / Sophal Noch / US-0013293 - [UK Launch] Deactivate old contract signature email
@               : 09.03.2023 / Sophal Noch / US-0013152 - [Launch] FR Preparation for launch
@               : 13.03.2023/ vadhanak voun/ US-0013328 - Amend validation rule for 0% co-invest records
@               : 17.03.2023/ Mony Nou / US-0013114 - System Admin Limited privileges profiles can't delete Coupon Sellers
@               : 05.04.2023 / Sophal Noch / US-0013235 - [UK only] Only allow certain users to move coupon seller to contract send
@               : 24.04.2023 / Loumang SENG / US-0012802 - [Launch Day] Remove BETA criteria for coupon emails + deactivate old flows
@               : 02.06.2023 / Sophal Noch / US-0012597 - [IT] Accessibility Configurations - Cannot deploy before launch
@               : 02.06.2023 / Sambath SENG / US-0013153 - [Launch] IT Launch Preparation
@               : 06.06.2023 / Loumang SENG / US-0013029 - Streamline of coupon seller statuses & retiring coupon fields
@               : 15.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
@               : 21.08.2023 / Sambath Seng / US-0013978 - Introduce new Coupon Seller type for Long term Coupons
@               : 22.08.2023 / LoumAng SENG/ US-0013973 - Introduce new coupon type for Long Term Coupons
@               : 05.09.2023 / Mony Nou / US-0013979 - Long Term Coupons Visible on Portal (Seller Facing)
@               : 05.09.2022 / Sambath Seng / US-0014083 - Change the Coupon Transaction file access
@               : 25.09.2023 / Sambath Seng / US-0014201 - Coupon transaction file - access change
@               : 28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
@               : 2.10.2023 / Sambath Seng / US-0012340 - Destruction of Coupon Item Object
@               : 23.11.2023 / Sambath Seng / US-0014433 - Coupon Seller Delete trigger-Null Pointer exception
@               : 02.04.2024 / Mony Nou / US-0014557 - Bulk Coupon Approval process for NA
@               : 25.04.2024 / Loumang SENG / US-0014956 - Auto enable SP eligibility (AC3 & AC4)
@               : 09.05.2024 / Loumang Seng / US-0015268 - Auto enable SP eligibility for Item Based Coupons
@               : 09.05.2024 / David Herrero / US-0015269 - Bypass for deleting records
@               : 14.05.2024 / Sophal Noch / US-0015242 - Fix Account Owner Updating to Integration User Issue
@               : 30.04.2025 / Sothea Horn / US-0017159 - Replace OwnerId with Account_Manager__c for Coupon Related Class
@               : 16.06.2025 / Sambath Seng / US-0012493 - Update Error Message with correct details on Coupon(Seller) approve stage update
@               : 10.09.2025 / Leon Morocki / US-0033151 - POP - Coupon Seller - Create New Record Type (Program Coupon Seller)
@               : 16.10.2025 / SENG Chan Sophorn / US-0033614 - POP - Trigger to update status of Program Seller to Opt- in - instead of Contract signed
@               : 20.11.2025 / Leon Morocki / US-0033952 - CA Seller Portal Users created with DE Settings
@               : 26.11.2025 / Loumang SENG  / US-0033705 - POP - SP - POP Coupons to be Visible on Portal (Seller Facing)
@               : 10.12.2025 / Loumang SENG  / US-0033512 - POP - Create Master Coupon Seller Automation Trigger
@               : 15.12.2025 / Leon Morocki  / US-0033470 - POP - SP - Download Item file attached to Coupon Seller record
*********************************************************************************************************************************/
public without sharing class CouponSellerTriggerHandler {
    /****************************************************************************************************************************
    * CONSTANTS DEFINITION
    *****************************************************************************************************************************/
    private static String EMAIL_COUPON_LAUNCH_REMINDER_TEMPLATE = 'UK_Coupon_Launch_Reminder_Templates';
    private static String EMAIL_COUPON_CONTRACT_ES_CAT = 'ES_Category_Coupon_Contract';
    private static String EMAIL_COUPON_CONTRACT_ES_ITEM = 'ES_Item_Coupon_Contract';
    private static String EMAIL_COUPON_CONTRACT_ACCEPTANCE_TEMPLATE = 'Coupons_Contract_Acceptance';
    
    private static String COUPON_SELLER_STAGE_CONTRACT_SIGNED = 'Contract Signed';
    private static String COUPON_SELLER_STAGE_CONTRACT_TARGETED     = 'Targeted'; //MN-06082021-US-0009746
    private static String COUPON_SELLER_STAGE_CONTRACT_REACHED      = 'Reached'; //MN-06082021-US-0009746
    //private static String COUPON_SELLER_STAGE_CONTRACT_COMMITED       = 'Commited'; //MN-06082021-US-0009746 //LA-06-06-2023-US-0013029
    private static String COUPON_SELLER_STAGE_CONTRACT_NEGOTIATION  = 'Contract Negotiation'; //MN-06082021-US-0009746
    
    private static String COUPON_STAGE_DRAFT                = 'Draft'; //MN-06082021-US-0009746
    private static String COUPON_STAGE_SELLERNEGOTIATION    = 'Seller Negotiation'; //MN-06082021-US-0009746

    private static String COUPON_TEMPLATE_LANGUAGE_AU = 'AU';
    private final static String SOQL_COUPON_SELLER = 'Select (select id from Coupon_Co_Invests__r limit 1),Main_Coupon_Site__c,Coupon__r.Coupon_Additional_Terms__c,Coupon__r.Sellers_Targeted2__c,Coupon__r.Sellers_Contract_Send2__c,Coupon__r.Sellers_Contract_Signed2__c, Coupon__r.Main_Coupon_Site__c,SiteURL__c,Contract_Accepted_From_Z__c,Contract_Accept_Date_Z__c,SellerShareHolder__c,Coupon__r.Stage__c,Coupon__r.RecordTypeID,Seller__r.EBH_OracleID__c,TriggerEmailManhattan__c,Date_34_days_Sent__c,Date_4days_Sent__c,Seller__r.Strategic_Seller_Share_w__c,Coupon__r.Coupon_Subtitle_Copy__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,MC_Whitelisted__c,Seller_Contact__r.Email,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_City__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c,Is_Coupon_Stage_Nego_Running__c From Coupon_Seller__c ';//MN-30082021-US-0009948
    //private final static String SOQL_COUPON_SELLER = 'Select (select id from Coupon_Items__r limit 1), (select id from Coupon_Co_Invests__r limit 1), Coupon__r.Main_Coupon_Site__c,SiteURL__c,Contract_Accepted_From_Z__c,Contract_Accept_Date_Z__c,SellerShareHolder__c,Coupon__r.Stage__c,Coupon__r.RecordTypeID,Seller__r.EBH_OracleID__c,TriggerEmailManhattan__c,Date_34_days_Sent__c,Date_4days_Sent__c,Seller__r.Strategic_Seller_Share_w__c,Coupon__r.Coupon_Subtitle_Copy__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Contract_Language__c,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Email_Adress__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ; //MN-30082021-US-0009948
    private final static String SOQLEMAIL_TEMPLATES = 'Select Body,Id,DeveloperName,Subject,HtmlValue from emailTemplate ';
    private static String EMAIL_COUPON_CONTRACT_IT_ITEM = 'IT_Item_Coupon_Contract';
    private static String EMAIL_COUPON_CONTRACT_IT_CAT = 'IT_Category_Coupon_Contract';
    
    //'Coupon_Seller__r.Coupon__r.Name','Coupon_Seller__r.Coupon__r.Coupon_Start_Date__c','Coupon_Seller__r.Coupon__r.Coupon_End_Date__c','Coupon_Seller__r.Coupon__r.Main_Coupon_Site__c','Coupon_Seller__r.Seller__c','Coupon_Seller__r.Contract_Accept_Date__c','Coupon_Seller__r.Contract_Accepted_From__c'
    private final static String SOQL_COUPONCOINVEST = 'select Coupon_Seller__r.Coupon__r.Coupon_ID__c,Coupon_Seller__r.Coupon__r.Coupon_Start_Date__c,Coupon_Seller__r.Coupon__r.Coupon_End_Date__c,Coupon_Seller__r.Coupon__r.Couponsite_s__c,Coupon_Seller__r.Seller__r.Name,Coupon_Seller__r.Contract_Accept_Date__c,Coupon_Seller__r.Contract_Accepted_From__c, Seller_Funding__c, Coupon_Name__c,OwnerId, Coupon_Seller__r.Coupon_Seller_Stage__c,Coupon_Seller__r.Coupon__r.Main_Coupon_Site__c,id,Site__c,Category__c,Category_ID__c,Co_Invest__c, Item_ID__c, Coupon_Seller__c, Coupon_Category__c from Coupon_Co_Invest__c';
    private final static String DF_DD_MM_YYYY = 'dd/MM/yyyy';//SB 3.11.2021 US-0010476 - AU Coupon email template content update

    // 30/04/2025 US-0017159 - Replace OwnerId with Account_Manager__c
    private final static String QUERY_ACCOUNTEROWNER_FROMSELLER = 'SELECT Outreach_Manager__c, Account_Manager__c FROM Account WHERE Id IN: sSellerId';

    private final static String COUPON_LAUNCH_REMINDER ='Coupon_Launch_Reminder';

    public static Boolean IS_UPDATED_BY_SYSTEM = false; // 05.04.2023 / Sophal Noch / US-0013235

    public static Boolean sendReminder;
    private static Switch_services__mdt setting;
    //LA-06-06-2023-US-0013029
    //public static final Set<String> SET_COUPONSELLER_STAGE = new Set<String>{'Contract Send', 'Contract Signed', 'Coupon Running' , 'Coupon executed', 'T4 Statement Send', 'T34 Statement Send', 'Invoice paid'};
    public static final Set<String> SET_COUPONSELLER_STAGE = new Set<String>{'Contract Send', 'Contract Signed', 'Coupon Running' , 'Coupon executed', 'T34 Statement Send'}; //LA-06-06-2023-US-0013029
    public final static String COUNT_COUPON_SELLER = 'csCountSeller';
    public final static String COUNT_COUPON_SELLER_STAGE = 'csCountStage';
    public final static String COUNT_COUPON_SELLER_ACCEPT_DATE = 'csCountDate';
    private final static String KEY_CID = 'cId';

    //@ Change history: 16.03.2022 / Chetra Sarom  / US-0010643 - Coupon seller record deletion error message update    
    @testvisible
    private final static String COUPON_ITEMBASE = 'Item_Based';
    @testvisible
    private final static String POP_COUPON = 'Pop_Coupon';
    @testvisible
    private final static String COUPON_POP_RECORDTYPE = 'Pop_Coupon';
    @testvisible
    private final static String COUPONSELLER_MANHATTAN_RECORDTYPE = 'Manhattan_Coupon';
    private final static String COUPONSELLER_SCMC_RECORDTYPE = 'SCMC_Seller';
    // US-0010643 END

    // SB US-0010432 12-5-2022
    public static final String COUPON_SELLER_TYPE_ITEM = 'Item Based';
    public static final String COUPON_SELLER_STAGE_REVIEW = 'Review';
    public static final String COUPON_SELLER_STAGE_APPROVED = 'Approved';
    public static final String COUPON_SELLER_STAGE_CONTRACT_SEND = 'Contract Send';
    public static final String COUPON_SELLER_STAGE_COUPON_RUNNING = 'Coupon Running';
    public static final String COUPON_SELLER_STAGE_COUPON_EXECUTED = 'Coupon executed';
    //public static final String COUPON_SELLER_STAGE_T4 = 'T4 Statement Send'; //LA-06-06-2023-US-0013029
    public static final String COUPON_SELLER_STAGE_T40 = 'T34 Statement Send';
    //public static final String COUPON_SELLER_STAGE_INVOICE_PAID = 'Invoice paid';//LA-06-06-2023-US-0013029
    public static final String COUPON_SELLER_STAGE_SELLER_DELINED = 'Seller Declined';
    public static final String COUPON_SELLER_STAGE_DECLINED = 'Declined'; //MN-07092023-US-0013979
    public static final String COUPON_SELLER_STAGE_SENTFORAPPROVAL = 'Sent for Approval'; //MN-21072022-US-0011728  
    
    public static final String COUPON_SELLER_SEP_STATUS_UPCOMING = 'Upcoming';
    public static final String COUPON_SELLER_SEP_STATUS_IN_NEGOTIATION = 'In Negotiation';
    public static final String COUPON_SELLER_SEP_STATUS_REVIEW = 'Items in Review';
    public static final String COUPON_SELLER_SEP_STATUS_UPLOAD = 'Item Upload';
    public static final String COUPON_SELLER_SEP_STATUS_APPROVED = 'Approved';
    public static final String COUPON_SELLER_SEP_STATUS_AWAITING_SIGNATURE = 'Awaiting Signature';
    public static final String COUPON_SELLER_SEP_STATUS_SIGNED = 'Signed';
    public static final String COUPON_SELLER_SEP_STATUS_RUNNING = 'Running';
    public static final String COUPON_SELLER_SEP_STATUS_ENDED = 'Ended';
    public static final String COUPON_SELLER_SEP_STATUS_DECLINED = 'Declined';
    private static final String COUPON_SELLER_STATUS_STATEMENT_READY = 'Statement Ready'; //LA-26-11-2025-US-0033705
    private static final String COUPON_SELLER_SEP_STATUS_PLANNED = 'Planned'; //LA-26-11-2025-US-0033705
    private static final String COUPON_SELLER_SEP_STATUS_OPTED_IN = 'Opted-In'; //LA-26-11-2025-US-0033705
    private static final String COUPON_SELLER_SEP_STATUS_OPTED_OUT = 'Opted-Out'; //LA-26-11-2025-US-0033705
    private static final String COUPON_SELLER_STAGE_COMPLETED = 'Completed'; //LA-26-11-2025-US-0033705
    private static final String RT_SCMC_SELLER = 'SCMC_Seller';// SB 21.08.2023 US-0013978
    private static final Set<String> SET_CHANGE_FILE_ACCESS_STAGE = new Set<String>{'Coupon Running','Coupon executed','T34 Statement Send','T4 Statement Send','Contract Appended'}; //SB US-0014083 6.9.2023
    
    // BR-08.08.2023-US-0012236
    public static final Map<String, String> COUPON_SELLER_STATUS_SEP_MAPPING = new Map<String, String> {
        COUPON_SELLER_STAGE_CONTRACT_TARGETED => COUPON_SELLER_SEP_STATUS_UPCOMING,
        COUPON_SELLER_STAGE_CONTRACT_REACHED => COUPON_SELLER_SEP_STATUS_UPCOMING,
        //COUPON_SELLER_STAGE_CONTRACT_COMMITED => COUPON_SELLER_SEP_STATUS_UPCOMING, //LA-06-06-2023-US-0013029
        COUPON_SELLER_STAGE_CONTRACT_NEGOTIATION => COUPON_SELLER_SEP_STATUS_IN_NEGOTIATION,
        COUPON_SELLER_STAGE_REVIEW => COUPON_SELLER_SEP_STATUS_REVIEW,
        // BR-08.08.2023-US-0012236
        //COUPON_SELLER_STAGE_APPROVED => COUPON_SELLER_SEP_STATUS_APPROVED,
        COUPON_SELLER_STAGE_APPROVED => COUPON_SELLER_SEP_STATUS_REVIEW,
        // BR-08.08.2023-US-0012236 END
        COUPON_SELLER_STAGE_CONTRACT_SEND => COUPON_SELLER_SEP_STATUS_AWAITING_SIGNATURE,
        COUPON_SELLER_STAGE_CONTRACT_SIGNED => COUPON_SELLER_SEP_STATUS_SIGNED,
        COUPON_SELLER_STAGE_COUPON_RUNNING => COUPON_SELLER_SEP_STATUS_RUNNING,
        COUPON_SELLER_STAGE_COUPON_EXECUTED => COUPON_SELLER_SEP_STATUS_ENDED,
        //COUPON_SELLER_STAGE_T4 => COUPON_SELLER_SEP_STATUS_ENDED, //LA-06-06-2023-US-0013029
        COUPON_SELLER_STAGE_T40 => COUPON_SELLER_SEP_STATUS_ENDED,
        //COUPON_SELLER_STAGE_INVOICE_PAID => COUPON_SELLER_SEP_STATUS_ENDED, //LA-06-06-2023-US-0013029
        COUPON_SELLER_STAGE_SELLER_DELINED => COUPON_SELLER_SEP_STATUS_DECLINED,
        COUPON_SELLER_STAGE_DECLINED => COUPON_SELLER_SEP_STATUS_DECLINED, //MN-07092023-US-0013979
        COUPON_SELLER_STAGE_SENTFORAPPROVAL => COUPON_SELLER_SEP_STATUS_REVIEW, //MN-21072022-US-0011728
        COUPON_STAGE_DRAFT => COUPON_SELLER_SEP_STATUS_PLANNED, //LA-26-11-2025-US-0033705
        COUPON_SELLER_SEP_STATUS_OPTED_IN => COUPON_SELLER_SEP_STATUS_OPTED_IN, //LA-26-11-2025-US-0033705
        COUPON_SELLER_SEP_STATUS_RUNNING => COUPON_SELLER_SEP_STATUS_RUNNING, //LA-26-11-2025-US-0033705
        COUPON_SELLER_SEP_STATUS_OPTED_OUT => COUPON_SELLER_SEP_STATUS_OPTED_OUT, //LA-26-11-2025-US-0033705
        COUPON_SELLER_STATUS_STATEMENT_READY => COUPON_SELLER_SEP_STATUS_ENDED, //LA-26-11-2025-US-0033705
        COUPON_SELLER_STAGE_COMPLETED => COUPON_SELLER_SEP_STATUS_ENDED //LA-26-11-2025-US-0033705
    };
    // END SB US-0010432 12-5-2022

    private static final String COUPONSITE_US = 'ebay.com'; //MN-25082022-US-0012276
    private final static String COUPONSITE_DE = 'ebay.de'; //LA 29.08.2022
    private final static String COUPONSITE_UK = 'ebay.co.uk'; //MN-15122022-US-0012734
    private final static String COUPONSITE_FR = 'ebay.fr'; //MN-11012023-US-0012694
    private final static String COUPONSITE_IT = 'ebay.it'; //SP-08022023-US-0013047
    private final static String COUPONSITE_AU = 'ebay.com.au'; //SP-22022023-US-0012801
    private final static String COUPONSITE_ES = 'ebay.es';//LA-28-09-2023
    private final static String COUPONSITE_CA = 'ebay.ca';//LM-20-10-2025 US-0033952

    public static final String INTEGRATION_USER = '0056A000000zaxMQAQ';
    public static final String DEPLOYMENT_USER = '0056A000000yx6iQAA';
    private static final String DEACTIVATION_USER_ID = (String)(Label.Cohort_Deactivation_UserId); // 14.05.2024 / Sophal Noch / US-0015242
    public static Set<String> IntegrationAndDeploymentUser = new set <String>{INTEGRATION_USER,DEPLOYMENT_USER, DEACTIVATION_USER_ID}; // 14.05.2024 / Sophal Noch / US-0015242 : add DEACTIVATION_USER_ID to exist Set<String>
    private final static Set<Id> SET_ADMIN_PROFILE_ID = new Set<Id>{ApexUtil.ADMIN_PROFILE_ID,ApexUtil.ADMIN_LT_PRIV_PROFILE_ID}; //LA-10-01-2023-US-0012995
    private final static String CPNSLR_CPNCOINVSQL = 'SELECT Id, (SELECT Id,Co_Invest__c FROM Coupon_Co_Invests__r WHERE Co_Invest__c = null OR Co_Invest__c >=0 ORDER BY Co_Invest__c ASC NULLS FIRST LIMIT 1) FROM Coupon_Seller__c WHERE Id IN:sCpnSlrId';
    private final static String COUPON_CATEGORYBASE = 'Category_Based';//LA-22-08-2023-US-0013973
    private final static String COUPON_SCMC_CATEGORYBASE = 'Single_Contract_Multi_Coupon_SCMC_Category_Based';//LA-22-08-2023-US-0013973
    private final static String SP_COUPON_FULL_ACCESS ='Full Access';
    private final static RecordType RT_MANHATTAN = ApexUtil.getRecordTypeByName('Coupon_Seller__c',COUPONSELLER_MANHATTAN_RECORDTYPE); 
    private final static RecordType RT_SCMC = ApexUtil.getRecordTypeByName('Coupon_Seller__c',COUPONSELLER_SCMC_RECORDTYPE);
    private final static Set<Id> SET_INCLUDE_RT = new Set<Id>{RT_MANHATTAN.Id,RT_SCMC.Id};
    private static final String ACCOUNT_QUERY = 'Select Id, SP_Coupons__c, SP_Main_Domain__c from Account Where Id IN : setAccId AND (SP_Coupons__c != :SP_COUPON_FULL_ACCESS OR SP_Main_Domain__c = null) Order By Id ASC';
    private final static String COUPON_SELLER_STAGE_OPTED_IN= 'Opted-In'; //CSP : US-0033614 : 16/10/2025
    private static final RecordType RT_MASTERAGREEMENTSELLER = ApexUtil.getRecordTypeByName('Coupon_Seller__c','Master_Agreement_Seller');//LA-26-11-2025-US-0033705
    private static final RecordType RT_PROGRAMCOUPONSELLER = ApexUtil.getRecordTypeByName('Coupon_Seller__c','Program_Coupon_Seller');//LA-26-11-2025-US-0033705
    private final static Set<Id> SET_COUPONSELLER_RT_ID = new Set<Id>{RT_MANHATTAN.Id,RT_SCMC.Id,RT_MASTERAGREEMENTSELLER.Id,RT_PROGRAMCOUPONSELLER.Id};//LA-26-11-2025-US-0033705
    private final static String BLANKVALUE = '';
    private final static String QUERY_COUPON = 'SELECT Id,Master_Coupon__c FROM coupon__c';
    //LA-28-09-2023: US-0013980 mapping by coupon mainsite
    private final static Map<String, String> COUPON_MAINSITE_MAPPING = new Map<String, String> {
            COUPONSITE_DE => 'DE',
            COUPONSITE_UK => 'UK',
            COUPONSITE_FR => 'FR',
            COUPONSITE_IT => 'IT',
            COUPONSITE_AU => 'AU',
            COUPONSITE_ES => 'ES',
            COUPONSITE_US => 'US',
            COUPONSITE_CA => 'CA'
            
    };
    private final static Map<String, String> SP_MAINDOMAIN_MAPPING = new Map<String, String> {
            COUPONSITE_DE => 'wachstumsportal.ebay.de',
            COUPONSITE_UK => 'sellerportal.ebay.co.uk',
            COUPONSITE_FR => 'portaildecroissance.ebay.fr',
            COUPONSITE_IT => 'portalecrescita.ebay.it',
            COUPONSITE_AU => 'sellerportal.ebay.com.au',
            COUPONSITE_US => 'sellerportal.ebay.com',
            COUPONSITE_CA => 'sellerportal.ebay.com'
            
    };
    
    /************************************END CONSTANTS DEFINITION*************************************************************/
    
    //dynamically pickup the correct site url (sandbox or prod)
    // public String couponContractClickMeUrl = ApexUtil.getSiteUrl('Deal_Acceptance')+'?restype='+EBH_TrackingResponseController.CONRACT_COUPON_URL_TYPE+'&csid=%csid%&';//+EBH_TrackingResponseController.REDIRECT_URL;
    // public String retUrl;
    /*****************************************************************************************************************************
    @ Method:   createCoInvest
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  EPH-7288 Coupon Seller Object - Add bulk Upload feature for Items on Details Page
    @           AC2) When Users set coupon seller record status to "Contract Negotiation" then this will create the Coupon Co-Invest Object and user can enter co-invest
    @ Event:    After Insert, After Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Seller__c> listNew,Map<Id,Coupon_Seller__c>mapOld
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.04.2019 / Vadhanak Voun / Created the  Method.
    @ Change history: 10.04.2019 / Sovantheany Dim / update Co invest record type
    @ Change history: 26.04.2019 / Sovantheany Dim / Comment this methode out, EPH-7387
    *****************************************************************************************************************************/
    /*public static void createCoInvest(List<Coupon_Seller__c> listNew,Map<Id,Coupon_Seller__c>mapOld)
    {
        Boolean isNew = (mapOld==null);
        List<Coupon_Co_Invest__c> listCoInvest = new List<Coupon_Co_Invest__c>();
        for(Coupon_Seller__c cs: listNew)
        {
            if(cs.Coupon_Seller_Stage__c == EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO
                && (isNew ||  (!isNew && cs.Coupon_Seller_Stage__c <> mapOld.get(cs.Id).Coupon_Seller_Stage__c)))
            {
                listCoInvest.add(newCoInvest(cs));
            }
        }
        if(!listCoInvest.isEmpty())
        {
            insert listCoInvest;
        }
    }*/

    /*****************************************************************************************************************************
    @ Method:   preventRecordDeletion
    @ Version:  1.0
    @ Author:   Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:  US-0009746 - Coupon - enable deletion of coupon related records
    @ Event:    Before Delete
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: Map<Id, Coupon_Seller__c> oldMap  
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.08.2021 / Mony / Created the  Method
    @ Change history: 16.03.2022 / Chetra Sarom  / US-0010643 - Coupon seller record deletion error message update     
    @ Change history: 17.03.2022 / Mony Nou  / US-0013114 - System Admin Limited privileges profiles can't delete Coupon Sellers
    *****************************************************************************************************************************/
    public static void preventRecordDeletion(Map<Id, Coupon_Seller__c> oldMap) {

        Set<String> validDeleteCouponSellerStage = new Set<String>{
            COUPON_SELLER_STAGE_CONTRACT_TARGETED,
            COUPON_SELLER_STAGE_CONTRACT_REACHED,
            //COUPON_SELLER_STAGE_CONTRACT_COMMITED, //LA-06-06-2023-US-0013029
            COUPON_SELLER_STAGE_CONTRACT_NEGOTIATION
        };

        Set<String> validDeleteCouponStage = new Set<String>{
            COUPON_STAGE_DRAFT,
            COUPON_STAGE_SELLERNEGOTIATION
        };

        //MN-17032023-US-0013114
        Set<String> sAdminsProfId = new Set<String> {ApexUtil.ADMIN_PROFILE_ID, ApexUtil.ADMIN_LT_PRIV_PROFILE_ID}; 
        
        //MN-17032023-US-0013114
        Boolean isAdmin = sAdminsProfId.contains(Userinfo.getprofileId());
        //Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID);
        
        Map<Integer, String> mErrorMsg = new Map<Integer,String> {
            1 => System.Label.Prevent_Deletion_of_Coupon_Seller_Item_Category,
            2 => System.Label.Prevent_Deletion_of_Coupon_Seller,
            3 => System.Label.Prevent_Deletion_of_Pop_Coupon_Seller
        };

        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',COUPONSELLER_MANHATTAN_RECORDTYPE); // Chetra Sarom / US-0010643
        RecordType couponPopCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',COUPON_POP_RECORDTYPE); // Chetra Sarom / US-0010643

        Set<Id> sCSIds = new Set<Id>();

        byPass__c bp = byPass__c.getInstance(UserInfo.getUserId()); //initiate bypass trigger

        if (bp!=null && bp.byPass_Trigger__c && !String.isBlank(bp.triggerObjects__c) && bp.triggerObjects__c.containsIgnoreCase('Coupon_Seller__c')) return;
        
        for (Coupon_Seller__c cs : [SELECT RecordTypeId,EBH_CouponSellerOwner__c, Coupon_Seller_Stage__c, Coupon__r.OwnerId, Coupon__r.Stage__c FROM Coupon_Seller__c WHERE Id IN:oldMap.keySet()]) {
            //Integer msg_idx = ((!isAdmin && Userinfo.getUserId() != cs.EBH_CouponSellerOwner__c && Userinfo.getUserId() != cs.Coupon__r.OwnerId)?1:((!validDeleteCouponStage.contains(cs.Coupon__r.Stage__c) || !validDeleteCouponSellerStage.contains(cs.Coupon_Seller_Stage__c))?2:0));         
            
            Integer msg_idx = ((!bp.byPass_Trigger__c &&  !isAdmin && Userinfo.getUserId() != cs.EBH_CouponSellerOwner__c && Userinfo.getUserId() != cs.Coupon__r.OwnerId)?1:((!validDeleteCouponStage.contains(cs.Coupon__r.Stage__c) || !validDeleteCouponSellerStage.contains(cs.Coupon_Seller_Stage__c))?2:0));
            // Change history: 16.03.2022 / Chetra Sarom  / US-0010643 / When user tries to delete a Coupon_Seller__c (record type Manhattan) with stage prior to "contract send" and Coupon__c.Stage__c is not "draft"
            if (mErrorMsg.containsKey(msg_idx) && cs.RecordTypeId == manhattanCouponSellerRecordType.Id) {
                oldMap.get(cs.Id).addError(mErrorMsg.get(msg_idx));
            }
            // Chetra Sarom  / US-0010643 / When user tries to delete a Coupon_Seller__c record type = Pop_Coupon
            else if (cs.RecordTypeId == couponPopCouponSellerRecordType.Id){
                oldMap.get(cs.Id).addError(mErrorMsg.get(3));
            } 
            // US-0010643 END
            else {
                sCSIds.add(cs.Id);
            }
            
        }

        if (sCSIds.isEmpty()) return;

        //Find all Coupon_Co_Invest__c related to those deleting Coupon Seller then delete it
        delete [SELECT Id FROM Coupon_Co_Invest__c WHERE Coupon_Seller__c IN:sCSIds];

    }
    
    /*****************************************************************************************************************************
    @ Method:   createCoInvest
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  
                [#EPH-7253] Object_ Coupon Co-Invest
                iii)Pagelayout Coupon Co-Invest Item (Record Type)

                Automatically create Coupon co-invest record type = Coupon Co-Invest Item if:
                Coupon type = Item Based
                Create Coupon Seller linked to coupon
                min 1 Item has been uploaded to Coupon Sellers
                User update Coupon Seller stage to = Contract Negotiation
                Once user changed the linked coupon seller status, Co-invest type Coupon Co-Invest Item will be created automatically
                
    @ Event:    After Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Seller__c> listNew,Map<Id,Coupon_Seller__c>mapOld
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.04.2019 / Sovantheany Dim / Created the  Method
    @ Change history: 12.12.2019 / Sreymeas Nao / US-0006480 Coupon Items - Ability to bulk upload seller share with items (added seller share).
    @               : 2.10.2023 / Sambath Seng / US-0012340 - Destruction of Coupon Item Object
    *****************************************************************************************************************************/
    // public static void createCoInvest2(List<Coupon_Seller__c> listNew,Map<Id,Coupon_Seller__c>mapOld)
    // {
    //  Set<Id> sCouponId = new Set<Id>();
    //  Map<Id, Coupon_Seller__c> mapCouponSeller = new Map<Id,Coupon_Seller__c>();
    //  Set<Id> sCouponSellerId = new Set<Id>();
    //  String whereCl = ' where ID IN: listNew';
    //  for(Coupon_Seller__c cs : Database.query(SOQL_COUPON_SELLER + whereCl)){
    //      if(cs.Coupon_Seller_Stage__c == EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO && cs.Coupon_Seller_Stage__c != mapOld.get(cs.Id).Coupon_Seller_Stage__c){
    //          mapCouponSeller.put(cs.Id,cs);
    //          sCouponSellerId.add(cs.Id);
    //          sCouponId.add(cs.Coupon__c);
    //      }
    //  }
    //  if(mapCouponSeller.isEmpty()) return;
        
    //  List<Coupon_Co_Invest__c> lstCoInvest = CouponTriggerHandler.newListCoInvestToCreatedForItemBase(mapCouponSeller);
    //  //Th:10/02/2020: move code to CouponTriggerHandler.newListCoInvestToCreatedForItemBase();
    //  /*RecordType coInvestItemRecordType = ApexUtil.getRecordTypeByName('Coupon_Co_Invest__c',EBH_ConstantsUtility.CO_INVEST_ITEM);
    //  String wherecls = ' where Coupon_Seller_ID__c IN: sCouponSellerId and Coupon_Seller_ID__r.Coupon__r.RecordType.DeveloperName = \'Item_Based\'';
    //  List<Coupon_Co_Invest__c> lstCoInvest = new List<Coupon_Co_Invest__c>();
    //  for(Coupon_Item__c item : Database.query(EBH_ConstantsUtility.SOQL_COUPONITEM + wherecls)){
    //      Coupon_Seller__c couponSeller = mapCouponSeller.get(item.Coupon_Seller_ID__c);

    //      Coupon_Co_Invest__c coInvest = newCoInvest(couponSeller,item,coInvestItemRecordType.Id);
    //      //Th:10/02/2020:comment out bellow code: move all to method newCoInvest
    //      //coInvest.Item_ID__c = item.Item_ID__c;
    //      //SRM US-0006480 Coupon Items - Ability to bulk upload seller share with items
    //      //coInvest.Co_Invest__c = item.Seller_Share__c;
    //      //coInvest.RecordTypeID = coInvestItemRecordType.Id;
    //      lstCoInvest.add(coInvest);
    //  }*/
    //  List<Coupon_Co_Invest__c> lstCoInvestToCreated = CouponTriggerHandler.checkDuplicatedCoInvest(lstCoInvest,sCouponId);
    //  if(!lstCoInvestToCreated.isEmpty())
    //  {
    //      insert lstCoInvestToCreated;
    //  }
        
    // }
    
    /*****************************************************************************************************************************
    @ Method:   createCoInvestOnceCouponSellerCreated
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  
                [#EPH-7253] Object_ Coupon Co-Invest
                
                i)Pagelayout Coupon Co-Invest Seller (Record Type)

                Automatically create Coupon co-invest record type = Coupon Co-Invest Seller if:
                Coupon type = Seller / Category Based (From Object Coupon__C)
                Coupon Category is added with category level = 0 (From Object Coupon_Category_c) 
                Coupon Seller is created and linked to Coupon
                User update Coupon stage to = Seller Negotiation (From Object Coupon__C)
                Once user changed the status, Co-invest type Coupon Co-Invest Seller will be created automatically with all fields populated and read only except field Co-Invest % which is editable
                
                ii)Pagelayout Coupon Co-Invest Category (Record type)
                
                Automatically create Coupon co-invest record type = Coupon Co-Invest Category if:
                
                Coupon type = Seller / Category Based  (From Object Coupon__C)
                Coupon Category is added with category level > 0  (From Object Coupon_Category_c) 
                Coupon Seller is created and linked to Coupon
                User update Coupon stage to = Seller Negotiation (From Object Coupon__C)
                Once user changed the status, Co-invest type Coupon Co-Invest Category will be created automatically with all fields populated and read only except field Co-Invest % which is editable
                
    @ Event:    After Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Seller__c> listNew
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.04.2019 / Sovantheany Dim / Created the  Method
                        22/10/2020/ Acmatac SEING / US-0007666 include 1 more status into the trigger (Coupon Running). 
                    : 22.08.2023/ LoumAng SENG/ US-0013973 - Introduce new coupon type for Long Term Coupons    
    *****************************************************************************************************************************/
    public static void createCoInvestOnceCouponSellerCreated(List<Coupon_Seller__c> listNewSeller)
    {
        Map<ID,List<Coupon_Seller__c>> mapCouponSeller = new Map<ID,List<Coupon_Seller__c>>();
        String whereCl = ' where ID IN: listNewSeller';
        Set<String> sValidCouponRT = new Set<String>{COUPON_CATEGORYBASE,COUPON_SCMC_CATEGORYBASE};//LA-22-08-2023-US-0013973
        for(Coupon_Seller__c coSeller : Database.query(SOQL_COUPON_SELLER + whereCl)){
            //LA-22-08-2023-US-0013973: add new Coupon recordtype SCMC to condition
            //if(coSeller.Coupon__c != null && coSeller.Coupon__r.RecordType.DeveloperName == EBH_ConstantsUtility.COUPON_CATEGORYBASE && (coSeller.Coupon__r.Stage__c == CouponTriggerHandler.COUPON_SELLER_NEGOTIATION_STAGE || coSeller.Coupon__r.Stage__c == CouponTriggerHandler.COUPON_RUNNING_STAGE)){   
            if(coSeller.Coupon__c != null && sValidCouponRT.contains(coSeller.Coupon__r.RecordType.DeveloperName) && (coSeller.Coupon__r.Stage__c == CouponTriggerHandler.COUPON_SELLER_NEGOTIATION_STAGE || coSeller.Coupon__r.Stage__c == CouponTriggerHandler.COUPON_RUNNING_STAGE)){    
                List<Coupon_Seller__c> lstCouponSeller = new List<Coupon_Seller__c>();
                if(mapCouponSeller.containskey(coSeller.Coupon__c)) lstCouponSeller = mapCouponSeller.get(coSeller.Coupon__c);
                lstCouponSeller.add(coSeller);
                mapCouponSeller.put(coSeller.Coupon__c,lstCouponSeller);
            }
        }
        if(mapCouponSeller.isEmpty()) return;
        Set<ID> sCoupon = mapCouponSeller.keySet();
        List<Coupon_Co_Invest__c> lstCoInvestToCreated = CouponTriggerHandler.newListCoInvestToCreated(mapCouponSeller,sCoupon);
        
        if(!lstCoInvestToCreated.isEmpty()){
            insert lstCoInvestToCreated;
        }
    }
    private static Map<String,List<Coupon_Co_Invest__c>> getListCoinvest(Set<String> setCSId){
        Map<String,List<Coupon_Co_Invest__c>> mapListCoInvest = new Map<String,List<Coupon_Co_Invest__c>>();
            String sWhereCoInvest = ' Where Coupon_Seller__c IN:setCSId';
            for(Coupon_Co_Invest__c cci : Database.query(SOQL_COUPONCOINVEST+sWhereCoInvest))
            {
                if(!mapListCoInvest.containsKey(cci.Coupon_Seller__c))
                {
                    mapListCoInvest.put(cci.Coupon_Seller__c,new List<Coupon_Co_Invest__c>());
                }
                mapListCoInvest.get(cci.Coupon_Seller__c).add(cci);
            }
        return mapListCoInvest;
    }
    //display: {!IF({!Coupon_Seller__c.Free_Subtitles__c} = true, '' , 'none')}
    private static String htmlTableTemplate = '<table><tbody>{!rows}</tbody></table>';
    private static String htmlRowTemplate = '<tr><td style="width: 550px;">{!catName} {!catId}:</td><td>{!coinvest%}</td></tr>';
    private static String htmlRowTemplateUK = '<tr><td style="width: 193.333px;">{!catName} {!catId}</td></tr>';
    //TH: 29/04/2021: US-0009000 - Coupon seller template remove column free subtitle
    //private static String htmlRowFreeSubtitle = '<tr style="height: 16px;"><td style="width: 250.222px; height: 16px;"><strong>'+System.Label.Label_FreeSubtitle+' </strong></td><td colspan="2" style="width: 674.778px; height: 16px;">{FreeSubtitleParagraph2}</td></tr>';
    private static String htmlAdvertising = '<tr style="height: 16px;"><td style="width: 250.222px; height: 16px;"><strong>'+System.Label.Label_Advertising+' <td colspan="2" style="width: 674.778px; height: 16px;">{AdSpendAmount} <br /> {AdSpendDate} <p>'+System.Label.Text_Advertising+'</p></td></tr>';
    private static Map<String,String[]> mapHeaderCol = new Map<String,String[]>
    {
        'DE_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFArtikelnummer','Von Verkäufer an eBay zu entrichtende Erfolgsprämie%'},
        'DE_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'\uFEFFKategorie Seite','Kategorie Name','Kategorie ID','Von Verkäufer an eBay zu entrichtende Erfolgsprämie%'},
        'UK_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFItem Id','Seller Share %'},
        'UK_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'\uFEFFSite','Category Name','Category ID','Seller Share %'},
        'FR_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFNuméro de l\'objet','Frais dus par le vendeur à eBay en cas de vente avec les bons d’achat'},
        'AU_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFItem Id','Seller Funding %'},
        'AU_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'\uFEFFSite','Category Name','Category ID','Seller Funding %'},
        'ES_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFartículo','Comisión del vendedor abonable a eBay %'},
        'ES_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'\uFEFFSitio','Nombre de la Categoría','ID de la Categoría','Porción que el vendedor abonará a eBay %'},
        'IT_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFCodice articolo (ID)','Quota Venditore%'},
        'IT_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'\uFEFFPagina della categoria','Nome della categoria','Codice categoria(ID)','Quota Venditore%'}
    };
    //US-0010302:TH: 20/09/2021
    private static Map<String,String[]> mapHeaderColForAttachement = new Map<String,String[]>
    {
        'DE_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFGutscheincode','Gutschein-Startdatum','Gutschein-Enddatum','eBay-Website(s)','Nutzername des Verkäufers','Datum der Vertragsunterzeichnung','IP-Adresse','Artikelnummer','Von Verkäufer an eBay zu entrichtende Erfolgsprämie%'},
        'DE_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'\uFEFFGutscheincode','Gutschein-Startdatum','Gutschein-Enddatum','eBay-Website(s)','Nutzername des Verkäufers','Datum der Vertragsunterzeichnung','IP-Adresse','Kategorie Seite','Kategorie Name','Kategorie ID','Von Verkäufer an eBay zu entrichtende Erfolgsprämie%'},
        'UK_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFCoupon Code','Coupon Start Date','Coupon End Date','Couponsite(s)','Seller','Contract Accept Date','Contract Accepted From','Item Id','Seller Share %'},
        'UK_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'\uFEFFCoupon Code','Coupon Start Date','Coupon End Date','Couponsite(s)','Seller','Contract Accept Date','Contract Accepted From','Site','Category Name','Category ID','Seller Share %'},
        'FR_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFCode du bon d’achat','Date de début du coupon','Date de fin du coupon','Site(s) eBay','Pseudo du vendeur','Date de signature du contrat','Adresse IP','Numéro de l\'objet','Frais dus par le vendeur à eBay en cas de vente avec les bons d’achat'},
        'AU_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFCoupon Code','Coupon Start Date','Coupon End Date','Couponsite(s)','Seller','Contract Accept Date','Contract Accepted From','Item Id','Seller Funding %'},
        'AU_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'\uFEFFCoupon Code','Coupon Start Date','Coupon End Date','Couponsite(s)','Seller','Contract Accept Date','Contract Accepted From','Site','Category Name','Category ID','Seller Funding %'},
        'ES_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFCódigo promocional','Fecha de inicio del cupón','Fecha de finalización del cupón','Sitios web de eBay','Nombre de usuario del vendedor','Fecha en que se firmó el contrato','Dirección IP','artículo','Comisión del vendedor abonable a eBay %'},
        'ES_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'\uFEFFCódigo promocional','Fecha de inicio del cupón','Fecha de finalización del cupón','Sitios web de eBay','Nombre de usuario del vendedor','Fecha en que se firmó el contrato','Dirección IP','Sitio','Nombre de la Categoría','ID de la Categoría','Porción que el vendedor abonará a eBay %'},
        'IT_'+EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'\uFEFFCodice coupon','Data di inizio del coupon','Data di fine del coupon','Sito/i eBay','Nome utente del venditore','Data in cui è stato firmato il contratto','Indirizzo IP','Codice articolo (ID)','Quota Venditore%'},
        'IT_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'\uFEFFCodice coupon','Data di inizio del coupon','Data di fine del coupon','Sito/i eBay','Nome utente del venditore','Data in cui è stato firmato il contratto','Indirizzo IP','Pagina della categoria','Nome della categoria','Codice categoria(ID)','Quota Venditore%'}
    };
    //End US-0010302:TH: 20/09/2021
    private static Map<String,String[]> mapFields = new Map<String,String[]>{
        EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'Item_ID__c','Co_Invest__c'},
        EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'Site__c','Category__c','Category_ID__c','Co_Invest__c'}
    };
    private static Map<String,String[]> mapFieldsAU = new Map<String,String[]>{
        EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'Item_ID__c','Seller_Funding__c'},
        EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'Site__c','Category__c','Category_ID__c','Seller_Funding__c'}
    };
    //US-0010302:TH: 20/09/2021
    private static Map<String,String[]> mapFieldsForAttachement = new Map<String,String[]>{
        EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'Coupon_Seller__r.Coupon__r.Coupon_ID__c','Coupon_Seller__r.Coupon__r.Coupon_Start_Date__c','Coupon_Seller__r.Coupon__r.Coupon_End_Date__c','Coupon_Seller__r.Coupon__r.Couponsite_s__c','Coupon_Seller__r.Seller__r.Name','Coupon_Seller__r.Contract_Accept_Date__c','Coupon_Seller__r.Contract_Accepted_From__c','Item_ID__c','Co_Invest__c'},
        EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'Coupon_Seller__r.Coupon__r.Coupon_ID__c','Coupon_Seller__r.Coupon__r.Coupon_Start_Date__c','Coupon_Seller__r.Coupon__r.Coupon_End_Date__c','Coupon_Seller__r.Coupon__r.Couponsite_s__c','Coupon_Seller__r.Seller__r.Name','Coupon_Seller__r.Contract_Accept_Date__c','Coupon_Seller__r.Contract_Accepted_From__c','Site__c','Category__c','Category_ID__c','Co_Invest__c'}
    };
    private static Map<String,String[]> mapFieldsAUForAttachement = new Map<String,String[]>{
        EBH_ConstantsUtility.COUPON_ITEMBASE=>new String[]{'Coupon_Seller__r.Coupon__r.Coupon_ID__c','Coupon_Seller__r.Coupon__r.Coupon_Start_Date__c','Coupon_Seller__r.Coupon__r.Coupon_End_Date__c','Coupon_Seller__r.Coupon__r.Couponsite_s__c','Coupon_Seller__r.Seller__c','Coupon_Seller__r.Contract_Accept_Date__c','Coupon_Seller__r.Contract_Accepted_From__c','Item_ID__c','Seller_Funding__c'},
        EBH_ConstantsUtility.COUPON_CATEGORYBASE=>new String[]{'Coupon_Seller__r.Coupon__r.Coupon_ID__c','Coupon_Seller__r.Coupon__r.Coupon_Start_Date__c','Coupon_Seller__r.Coupon__r.Coupon_End_Date__c','Coupon_Seller__r.Coupon__r.Couponsite_s__c','Coupon_Seller__r.Seller__c','Coupon_Seller__r.Contract_Accept_Date__c','Coupon_Seller__r.Contract_Accepted_From__c','Site__c','Category__c','Category_ID__c','Seller_Funding__c'}
    };
    //End US-0010302:TH: 20/09/2021
    //private static Map<String,String> mapOrgWideAdd = new Map<string,String>{'AU'=>System.label.OWD_MKT_REP,'UK'=>System.label.OWD_MKT_REP_UK};
    private static Map<String,String> mapOrgWideAdd = new Map<string,String>{COUPONSITE_AU=>System.label.OWD_MKT_REP,COUPONSITE_UK=>System.label.OWD_MKT_REP_UK};
    /*****************************************************************************************************************************
    @ Method:   createCoInvest
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  EPH-7258 Coupon Seller Email Contracts
    @           AC1) As any user with permission set promotions In Coupon Seller Object when I set stage to "Contract Send" then we will send click contracts.
    @           The three Contract types are defined by the following criteria
    @               Use Contracttype Item when:
    @                   Coupon Object Record Type = Item Based
    @               Use Contracttype Category when:
    @                   Coupon Object Record Type = Item Based and Category Object Level = Category
    @               Use Contracttype Seller when:
    @                       Coupon Object Record Type = Item Based and Category Object Level = Category
    @
    @ Event:    After Insert, After Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Seller__c> listNew,Map<Id,Coupon_Seller__c>mapOld
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.05.2019 / Vadhanak Voun / Created the  Method.
    @               : 30.07.2019/ Vadhanak Voun / EPH-7604 Coupon Contract Localization for UK
    @               : 20.08.2019/ Vadhanak Voun / EPH-7935 Coupon Object - Adjust UK Coupon Contracts
    @               : 26/08/2019/ Sovantheany Dim/ EPH-7946 Coupon Seller - attach the excel to the related
    @               : 13/02/2020 / Sovantheany Dim / US-0007025 Coupon - Change to UK contract template
    @               AC1) When any user is choosing Site level for a category based contract for UK we will replace the N/A in any classic template
    @               : 01/12/2020/ Sovantheany Dim / US-0008262 - [ES] Coupon Seller contract templates and T&Cs
    @               : 06/05/2021 / Sovantheany Dim / US-0009459 - Coupon seller: block sending contract if Coupon Item not included
    @               Given that Coupon__c record type is Item Based
    @               When Coupon_Seller_Stage__c is moved to "contract send" OR when user clicks "send bulk contract" button
    @               Trigger must check number of related Coupon_Co_Invest__c OR number of related Coupon_Item__c
    @               If related Coupon_Item__c or Coupon_Co_Invest__c = Null
    @               Then show error message :
    @               Please make sure to upload Coupon Items before sending the contract.
    @               : Acmatac SEING, 04-06-2021, US-0009620 - UK Coupon: hide coupon seller owner details in cc, and set it to bcc
    @               Acmatac SEING, US-0010176 - MC: Coupon email notifications to external users
    @               : 30.08.2021 / Mony Nou / US-0009948 - Replace Email field with a Contact lookup field on Coupon Seller object and use it in communication to sellers.
    @               : 19.05.2022 / Mony Nou / US-0010656 - Ability to upload/manage items to item based coupons - AC6
    @               : 25.08.2022 / Mony Nou / US-0012276 - Disable the US contract emails for Seller's inbox 
    @               : 30.08.2022 / Bora Chhorn / US-0011942 - [DE Launch] Deactivate existing coupon seller email flows for launch
    @               : 16.09.2022 / Sambath Seng / US-0012633 - Ignore other ebay sites email processes if main site is ebay.de
    @               : 08.02.2023 / Sophal Noch / US-0013047 - Change recipient of IT contract signature confirmation email
    @               : 22.02.2023 / Sophal Noch / US-0013293 - [UK Launch] Deactivate old contract signature email
    @               : 09.03.2023 / Sophal Noch / US-0013152 - [Launch] FR Preparation for launch
    @               : 24.04.2023 / Loumang SENG / US-0012802 - [Launch Day] Remove BETA criteria for coupon emails + deactivate old flows (AC2)
    @               : 02.06.2023 / Sambath SENG / US-0013153 - [Launch] IT Launch Preparation
    *****************************************************************************************************************************/
    public static void sendContract(List<Coupon_Seller__c> listNew,Map<Id,Coupon_Seller__c>mapOld)
    {
        //BR-30-08-2022-US-0011942
        //LA-24-04-2023-US-0012802 : Skip for Site AU
        //SB 2.6.2023 US-0013153 - [Launch] IT Launch Preparation
        Set<String> setSkipRegion = new Set<String>{
            COUPONSITE_DE,
            COUPONSITE_US,
            COUPONSITE_AU,
            COUPONSITE_IT
        };
        
        Set<String> setCSId = new Set<String>();
        Boolean isNew = mapOld==null; 
        Map<Id,Coupon_Seller__c> mapCouponSeller = new Map<Id,Coupon_Seller__c>();

        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',COUPONSELLER_MANHATTAN_RECORDTYPE); //MN-25082022-US-0012276

        for(Coupon_Seller__c cs: listNew)
        {
            // US-0010176 - Acmatac SEING, Send email only MC_Whitelisted__c = False
            //MN-25082022-US-0012276 - Skip for Site US and for both Item/Category Coupon
            // if(cs.MC_Whitelisted__c || (cs.RecordTypeId == manhattanCouponSellerRecordType.Id && String.isNotBlank(cs.Coupon_site__c) && setSkipRegion.contains(cs.Coupon_site__c.trim()))){
            // Sambath Seng 16.09.2022 US-0012633 - Ignore other ebay sites email processes if main site is ebay.de

            if(cs.MC_Whitelisted__c || (cs.RecordTypeId == manhattanCouponSellerRecordType.Id && String.isNotBlank(cs.Main_Coupon_Site__c) && setSkipRegion.contains(cs.Main_Coupon_Site__c))){
                continue;
            }

            if(cs.Coupon_Seller_Stage__c == EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND 
                && (isNew || (!isNew &&  cs.Coupon_Seller_Stage__c <> mapOld.get(cs.Id).Coupon_Seller_Stage__c)))
            {
                setCSId.add(cs.Id);
                mapCouponSeller.put(cs.Id,cs);
                //if(cs.Coupon__r.RecordTypeId == couponRecordTypeItem.id) cs.addError('Please make sure to upload Coupon Items before sending the contract.');
            }
        }
        if(!setCSId.isEmpty())
        {
            String couponContractClickMeUrl = ApexUtil.getSiteUrl('Deal_Acceptance')+'?restype='+EBH_TrackingResponseController.CONRACT_COUPON_URL_TYPE+'&csid=%csid%&';//+EBH_TrackingResponseController.REDIRECT_URL;
            //Th 15/11/2019 : US-0018713
            String couponContractTermConditionUrl = ApexUtil.getSiteUrl('Deal_Acceptance')+'/apex/Coupon_Terms_and_Conditions'+'?csid=%csid%';
            String sWhere = ' Where Id IN:setCSId';
            Map<String,Coupon_Seller__c> mapCS = new Map<String,Coupon_Seller__c>();
            List<Coupon_Seller__c> listCSSellect = Database.query(SOQL_COUPON_SELLER+sWhere);
            
            Map<String,List<Coupon_Co_Invest__c>> mapListCoInvest = getListCoinvest(setCSId);
            /*Map<String,List<Coupon_Co_Invest__c>> mapListCoInvest = new Map<String,List<Coupon_Co_Invest__c>>();
            String sWhereCoInvest = ' Where Coupon_Seller__c IN:setCSId';
            for(Coupon_Co_Invest__c cci : Database.query(EBH_ConstantsUtility.SOQL_COUPONCOINVEST+sWhereCoInvest))
            {
                if(!mapListCoInvest.containsKey(cci.Coupon_Seller__c))
                {
                    mapListCoInvest.put(cci.Coupon_Seller__c,new List<Coupon_Co_Invest__c>());
                }
                mapListCoInvest.get(cci.Coupon_Seller__c).add(cci);
            }*/
            //system.debug('>>>mapListCoInvest: '+mapListCoInvest);
            Set<String> setEmailTemplates = new Set<String>{
                    EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_DE_ITEM,
                    EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_DE_CAT,
                    // EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_UK_ITEM, // 22.02.2023 / Sophal Noch / US-0013293
                    // EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_UK_CAT,  // 22.02.2023 / Sophal Noch / US-0013293
                    // EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_FR_CAT, // 09.03.2023 / Sophal Noch / US-0013152
                    // EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_FR_ITEM, // 09.03.2023 / Sophal Noch / US-0013152
                    // EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_AU,
                    // EBH_ConstantsUtility.EMAIL_COUPON_ITEM_CONTRACT_AU,
                    EMAIL_COUPON_CONTRACT_ES_CAT,
                    EMAIL_COUPON_CONTRACT_ES_ITEM
                    // EMAIL_COUPON_CONTRACT_IT_CAT, //SB 2.6.2023 US-0013153 - [Launch] IT Launch Preparation
                    // EMAIL_COUPON_CONTRACT_IT_ITEM //SB 2.6.2023 US-0013153 - [Launch] IT Launch Preparation
                };  
            Map<String,EmailTemplate> mapEmailTemplate = new Map<String,EmailTemplate>();
            for(EmailTemplate emt : Database.query(EBH_ConstantsUtility.SOQLEMAIL_TEMPLATES +' Where DeveloperName IN :setEmailTemplates'))
            {
                if(emt.DeveloperName == EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_DE_ITEM){
                    mapEmailTemplate.put('DE_'+EBH_ConstantsUtility.COUPON_ITEMBASE,emt);
                }else if(emt.DeveloperName == EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_DE_CAT){
                    mapEmailTemplate.put('DE_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE,emt);
                }
                // 22.02.2023 / Sophal Noch / US-0013293 :
                // else if(emt.DeveloperName == EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_UK_ITEM){
                //  mapEmailTemplate.put('UK_'+EBH_ConstantsUtility.COUPON_ITEMBASE,emt);
                // }
                // else if(emt.DeveloperName == EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_UK_CAT){
                //  mapEmailTemplate.put('UK_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE,emt);
                // }
                
                // 09.03.2023 / Sophal Noch / US-0013152 :
                // else if(emt.DeveloperName == EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_FR_CAT){
                //  mapEmailTemplate.put('FR_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE,emt);
                // }else if(emt.DeveloperName == EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_FR_ITEM){
                //  mapEmailTemplate.put('FR_'+EBH_ConstantsUtility.COUPON_ITEMBASE,emt);
                // }

                // else if(emt.DeveloperName == EBH_ConstantsUtility.EMAIL_COUPON_ITEM_CONTRACT_AU){
                //  mapEmailTemplate.put('AU_'+EBH_ConstantsUtility.COUPON_ITEMBASE,emt);
                // }else if(emt.DeveloperName == EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_AU){
                //  mapEmailTemplate.put('AU_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE,emt);
                // }
                else if(emt.DeveloperName == EMAIL_COUPON_CONTRACT_ES_CAT){
                    mapEmailTemplate.put('ES_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE,emt);
                }else if(emt.DeveloperName == EMAIL_COUPON_CONTRACT_ES_ITEM){
                    mapEmailTemplate.put('ES_'+EBH_ConstantsUtility.COUPON_ITEMBASE,emt);
                }
                
                // SB 2.6.2023 US-0013153 - [Launch] IT Launch Preparation
                // else if(emt.DeveloperName == EMAIL_COUPON_CONTRACT_IT_CAT){
                //  mapEmailTemplate.put('IT_'+EBH_ConstantsUtility.COUPON_CATEGORYBASE,emt);
                // }else if(emt.DeveloperName == EMAIL_COUPON_CONTRACT_IT_ITEM){
                //  mapEmailTemplate.put('IT_'+EBH_ConstantsUtility.COUPON_ITEMBASE,emt);
                // }
                
            }
            Map<String,List<Messaging.EmailFileAttachment>> mapListAtt = new Map<String,List<Messaging.EmailFileAttachment>>();
            Map<String,String> mapEmailBody = new Map<String,String>();
            Map<String,String> mapEmailSubject = new Map<String,String>();
            
            List<Messaging.SingleEmailMessage> listEmail = new List<Messaging.SingleEmailMessage>(); 
            List<Attachment> lstAtt = new List<Attachment>();
            List<Task> lstTask = new List<Task>();
            String couponRecordTypeItemId = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE).Id;
            //construct csv attachment
            for(Coupon_Seller__c cs: listCSSellect)
            {
                //TH:07/05/2021:US-0009459
                //if(cs.Coupon__r.RecordTypeId == couponRecordTypeItemId && (cs.Coupon_Items__r.isEmpty() || cs.Coupon_Co_Invests__r.isEmpty())){
                if(cs.Coupon__r.RecordTypeId == couponRecordTypeItemId && (cs.Coupon_Co_Invests__r.isEmpty())){ //MN-19052022-US-0010656-AC6
                    mapCouponSeller.get(cs.Id).addError(system.label.error_CouponItem_notExist);
                }
                //End TH:07/05/2021:US-0009459
                
                //LA-28-09-2023: US-0013980 : Replace Coupon__r.Contract_Language__c in Coupon__r.Main_Coupon_Site__c
                //String mappingKey = cs.Coupon__r.Contract_Language__c+'_'+cs.Coupon__r.RecordType.DeveloperName;
                String couponMainSite = COUPON_MAINSITE_MAPPING.get(cs.Coupon__r.Main_Coupon_Site__c);
                String mappingKey = couponMainSite+'_'+cs.Coupon__r.RecordType.DeveloperName;
                EmailTemplate empt = (mapEmailTemplate.containsKey(mappingKey)?mapEmailTemplate.get(mappingKey):mapEmailTemplate.get('UK_'+cs.Coupon__r.RecordType.DeveloperName)); //uk default
                //mapEmailTemplate.get(cs.Coupon__r.RecordType.DeveloperName);
                if(empt==null) continue;
                String[] listHeader = mapHeaderCol.containsKey(mappingKey)?mapHeaderCol.get(mappingKey):null;//mapHeaderCol.get('UK_'+cs.Coupon__r.RecordType.DeveloperName);//default UK
                 //mapHeaderCol.get(cs.Coupon__r.RecordType.DeveloperName);
                 List<Messaging.EmailFileAttachment> listAtt = null;
                if(mapListCoInvest.containsKey(cs.Id) && listHeader <> null)
                {
                    //LA-28-09-2023: US-0013980 : Replace Coupon__r.Contract_Language__c in Coupon__r.Main_Coupon_Site__c
                    //if(cs.Coupon__r.Contract_Language__c == 'AU') listAtt = generateCSAttachments(cs,mapListCoInvest.get(cs.Id),listHeader, mapFieldsAU);
                    if(cs.Coupon__r.Main_Coupon_Site__c == COUPONSITE_AU) listAtt = generateCSAttachments(cs,mapListCoInvest.get(cs.Id),listHeader, mapFieldsAU);
                    else listAtt = generateCSAttachments(cs,mapListCoInvest.get(cs.Id),listHeader, mapFields);
                    mapListAtt.put(cs.Id,listAtt);
                }
                //Th: US-0007064 : 28/01/2020
                String htmlValue = empt.HtmlValue != null ? (empt.HtmlValue.contains('{!tableRowAdvertising}')?(cs.Advertising_Promotion__c == 'Yes' ? empt.HtmlValue.replace('{!tableRowAdvertising}',htmlAdvertising):empt.HtmlValue.replace('{!tableRowAdvertising}','')):empt.HtmlValue) : null;
                //TH: 29/04/2021: US-0009000 - Coupon seller template remove column free subtitle
                //htmlValue = htmlValue != null ? (htmlValue.contains('{!tableRowFreeSutitle}')?(cs.Free_Subtitles__c == 'Yes' ? htmlValue.replace('{!tableRowFreeSutitle}',htmlRowFreeSubtitle) : htmlValue.replace('{!tableRowFreeSutitle}','')):htmlValue) : null;
                
                String textValue = empt.Body != null ? (empt.Body.contains('{!tableRowAdvertising}')?(cs.Advertising_Promotion__c == 'Yes'?empt.Body.replace('{!tableRowAdvertising}',htmlAdvertising) : empt.Body.replace('{!tableRowAdvertising}','')):empt.Body) : null;
                //TH: 29/04/2021: US-0009000 - Coupon seller template remove column free subtitle
                //textValue = textValue != null ? (textValue.contains('{!tableRowFreeSutitle}')?(cs.Free_Subtitles__c == 'Yes'?textValue.replace('{!tableRowFreeSutitle}',htmlRowFreeSubtitle) : textValue.replace('{!tableRowFreeSutitle}','')):textValue) : null;
                //End US-0007064 : 28/01/2020
                
                //LA-28-09-2023: US-0013980 : Replace Coupon__r.Contract_Language__c in Coupon__r.Main_Coupon_Site__c
                //String retUrl = mapRetURL.containsKey(cs.Coupon__r.Contract_Language__c)?mapRetURL.get(cs.Coupon__r.Contract_Language__c):mapRetURL.get('US');
                String retUrl = mapRetURL.containsKey(couponMainSite)?mapRetURL.get(couponMainSite):mapRetURL.get('US');
                String subject = mergSubjectContract(empt.Subject,cs);
                String htmlBody = mergeFieldsContractCoupon(htmlValue,cs,mapListCoInvest).replace('{clickMeUrl}',couponContractClickMeUrl.replace('%csid%',cs.Id+'')+retUrl);
                String textBody = mergeFieldsContractCoupon(textValue,cs,mapListCoInvest).replace('{clickMeUrl}',couponContractClickMeUrl.replace('%csid%',cs.Id+'')+retUrl);
                
                //NK:03/06/2019:EPH-7582
                htmlBody = htmlBody.contains('{!catTable}')?htmlBody.replace('{!catTable}',generateHTMLTable(mapListCoInvest.get(cs.Id),htmlRowTemplate,false,empt)):htmlBody;
                htmlBody = htmlBody.contains('{!CatNameIdTable}')?htmlBody.replace('{!CatNameIdTable}',generateHTMLTable(mapListCoInvest.get(cs.Id),htmlRowTemplateUK,false,empt)):htmlBody;
                //htmlBody = htmlBody.contains('{!tableRowAdvertising}') && cs.Advertising_Promotion__c == 'Yes'?htmlBody.replace('{!tableRowAdvertising}',htmlAdvertising):htmlBody;
                //htmlBody = htmlBody.contains('{!tableRowFreeSutitle}') && cs.Free_Subtitles__c=='Yes'?htmlBody.replace('{!tableRowFreeSutitle}',htmlRowFreeSubtitle):htmlBody;
                
                textBody = textBody.contains('{!catTable}')?textBody.replace('{!catTable}',generateHTMLTable(mapListCoInvest.get(cs.Id),'{!catName} {!catId}: {!coinvest%} \n',true,empt)):textBody;
                textBody = textBody.contains('{!CatNameIdTable}')?textBody.replace('{!CatNameIdTable}',generateHTMLTable(mapListCoInvest.get(cs.Id),'{!catName} {!catId} \n',true,empt)):textBody;
                //textBody = textBody.contains('{!tableRowAdvertising}') && cs.Advertising_Promotion__c == 'Yes'?textBody.replace('{!tableRowAdvertising}',htmlAdvertising):textBody;
                //textBody = textBody.contains('{!tableRowFreeSutitle}') && cs.Free_Subtitles__c == 'Yes'?textBody.replace('{!tableRowFreeSutitle}',htmlRowFreeSubtitle):textBody;
                
                //Th : 15/11/2019: US-0018713
                htmlBody = htmlBody.contains('{termConditionUrl}')?htmlBody.replace('{termConditionUrl}',couponContractTermConditionUrl.replace('%csid%',cs.Id+'')):htmlBody;
                textBody = textBody.contains('{termConditionUrl}')?textBody.replace('{termConditionUrl}',couponContractTermConditionUrl.replace('%csid%',cs.Id+'')):textBody;
                
                mapEmailBody.put(cs.Id,htmlBody);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{cs.Seller_Contact__r.Email}); //MN-30082021-US-0009948
                //mail.setToAddresses(new String[]{cs.Email_Adress__c}); //MN-30082021-US-0009948
                //mail.setccAddresses(new String[]{Test.isRunningTest()?'test@test.com': cs.Coupon__r.Owner.Email});
                //NK:24/06/2019: EPH-7592
                if(cs.EBH_CouponSellerOwner__c <> null)
                {
                    // Acmatac SEING, 04-06-2021, US-0009620 - UK Coupon: hide coupon seller owner details in cc, and set it to bcc
                    // if(cs.Coupon__r.Contract_Language__c == 'UK'){
                    //LA-28-09-2023: US-0013980 : Replace Coupon__r.Contract_Language__c in oupon__r.Main_Coupon_Site__c    
                    if(cs.Coupon__r.Main_Coupon_Site__c == COUPONSITE_UK || cs.Coupon__r.Main_Coupon_Site__c == COUPONSITE_IT){ // 08.02.2023 / Sophal Noch / US-0013047
                        mail.setBccAddresses(new String[]{Test.isRunningTest()?'test@test.com': cs.EBH_CouponSellerOwner__r.Email});
                    }else{
                        mail.setBccSender(false);
                        mail.setccAddresses(new String[]{Test.isRunningTest()?'test@test.com': cs.EBH_CouponSellerOwner__r.Email});
                    }
                }
                
                //NK:25/07/2019: EPH-7851 show coupon seller owner
                //mail.setSenderDisplayName(cs.EBH_CouponSellerOwner__c <> null?cs.EBH_CouponSellerOwner__r.Name:cs.Coupon__r.Owner.Name);
                mail.setSubject(subject);
                mail.setUseSignature(false); 
                mail.setHtmlBody(htmlBody);
                //TH: 20/10/2020: US-0008543 - Set OrgWideDefault Address
                    String replyto = (cs.EBH_CouponSellerOwner__c <> null && cs.EBH_CouponSellerOwner__r.Email <> null)?cs.EBH_CouponSellerOwner__r.Email:cs.Coupon__r.Owner.Email;
                // Acmatac SEING, 04-06-2021, US-0009620. If UK we put OWD email.
                //LA-28-09-2023: US-0013980: Replace all cs.Coupon__r.Contract_Language__c to cs.Coupon__r.Main_Coupon_Site__c 
                //if(cs.Coupon__r.Main_Coupon_Site__c == COUPONSITE_UK){
                if(cs.Coupon__r.Main_Coupon_Site__c == COUPONSITE_UK){ 
                    replyto = mapOrgWideAdd.get(cs.Coupon__r.Main_Coupon_Site__c);
                }
                    /*TH: 03/12/2020:US-0008524 - AU & UK Coupon : Change DL for Bulk Email Send*/
                    //if AU Email must be sent via retailpromotions@ebay.com and UK sent via dealnominations@ebay.com
                    if(mapOrgWideAdd.containsKey(cs.Coupon__r.Main_Coupon_Site__c)){
                        setOrgWideAddress(mail,replyto,mapOrgWideAdd.get(cs.Coupon__r.Main_Coupon_Site__c));
                    }//if DE sent by user who clicked on the "Send Bulk Contract" button email
                    else {
                        mail.setSenderDisplayName(UserInfo.getName());
                    }
                    /*END : TH: 03/12/2020:US-0008524*/
                    //End US-0008543
                //NK:18/06/2019: EPH-7589 
                //mail.setWhatId(cs.Id);
                
                //Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
                //fileAttachment.setBody(Blob.valueOf(csvBody));
                //fileAttachment.setFileName(fileName);  
                if(listAtt <> null)
                {
                    mail.setFileAttachments(listAtt); 
                }
                 
                listEmail.add(mail);
                //TH: 26/08/2019: EPH-7946 Coupon Seller - attach the excel to the related
                String fileName = '';
                if(listAtt != null && !listAtt.isEmpty()){
                    for(Messaging.EmailFileAttachment fileAtt : listAtt){
                    fileName += ' '+fileAtt.filename+',';
                    }
                    fileName = fileName.removeEnd(',');
                }
                // String description = 'To: '+cs.Email_Adress__c+'\n'+ //MN-30082021-US-0009948
                // String description = 'To: ' + cs.Seller_Contact__r.Email + '\n' + //MN-30082021-US-0009948
                // 'CC: '+cs.EBH_CouponSellerOwner__r.Email+'\n'+
                // 'BCC: \n'+
                // 'Attachment:'+fileName+'\n\n'+
                // 'Subject: '+subject+'\n'+
                // 'Body: \n'+textBody;
                // 08.02.2023 / Sophal Noch / US-0013047 :
                String description = 'To: ' + cs.Seller_Contact__r.Email + '\n';
                description += cs.Coupon__r.Main_Coupon_Site__c == COUPONSITE_IT ? 'CC: \n' : 'CC: '+cs.EBH_CouponSellerOwner__r.Email+'\n';
                description += cs.Coupon__r.Main_Coupon_Site__c == COUPONSITE_IT ? 'BCC: '+cs.EBH_CouponSellerOwner__r.Email+'\n' : 'BCC: \n';
                description += 'Attachment:'+fileName+'\n\n';
                description += 'Subject: '+subject+'\n';
                description += 'Body: \n'+textBody;
                Task t = createTask(subject,cs,description);
                lstTask.add(t);
            }                
              
            //NK:18/06/2019:prevent funny null pointer in test   
            if(!Test.isRunningTest() && !listEmail.isEmpty())
            {
                Messaging.sendEmail(listEmail);
            }
            if(!lstTask.isEmpty()) 
            {
                insert lstTask;
                List<Attachment> listTaskAtt = new List<Attachment>();
                for(Task t: lstTask)
                {   
                    List<Messaging.EmailFileAttachment> listEFA = mapListAtt.get(t.WhatId);
                    if(listEFA <> null)
                    {
                        for(Messaging.EmailFileAttachment efa: listEFA) //xls body, and pdf body from sent email attament and attach to Task
                        {
                            Attachment att = new Attachment(ParentId=t.Id,Name=efa.FileName,Body=efa.Body,ContentType=efa.ContentType);
                            listTaskAtt.add(att);
                        } 
                    }
                }
                if(!listTaskAtt.isEmpty())
                {
                    insert listTaskAtt;
                }
            }
        }
    }
    
    /*****************************************************************************************************************************
    @ Method    :   addFileAttachment
    @ Version   :   1.0
    @ Author    :   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose   :   US-0010302 - Coupon seller: Generate and attach a summary of seller contract confirmation
    @ Trigger   :   after Insert, update
    @ Param     :   List<Coupon_Seller__c> listNew,Map<Id,Coupon_Seller__c>mapOld
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.09.2021 / Sovantheany Dim / Method Creation
    *****************************************************************************************************************************/
    public static void addFileAttachment(List<Coupon_Seller__c> listNew,Map<Id,Coupon_Seller__c>mapOld)
    {
        Boolean isNew = mapOld==null; 
        Map<String,Coupon_Seller__c> mapCouponSeller = new Map<String,Coupon_Seller__c>();
        for(Coupon_Seller__c cs: listNew)
        {
            if(cs.MC_Whitelisted__c && cs.Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_CONTRACT_SIGNED && (isNew || (!isNew &&  cs.Coupon_Seller_Stage__c <> mapOld.get(cs.Id).Coupon_Seller_Stage__c))){
                mapCouponSeller.put(cs.Id,cs);
            }
        }
        if(!mapCouponSeller.isEmpty()){
            Set<String> sCpnSellerId = mapCouponSeller.keySet();
            Map<String,List<Coupon_Co_Invest__c>> mapListCoInvest = getListCoinvest(sCpnSellerId);
            List<Attachment> listCsAtt = new List<Attachment>();
            String sWhere = ' Where Id IN:sCpnSellerId';
            List<Coupon_Seller__c> listCSSellect = Database.query(SOQL_COUPON_SELLER+sWhere);
            for(Coupon_Seller__c cs : listCSSellect){
                
                String couponMainsite = COUPON_MAINSITE_MAPPING.get(cs.Coupon__r.Main_Coupon_Site__c);//LA-28-09-2023: US-0013980
                //String mappingKey = cs.Coupon__r.Contract_Language__c+'_'+cs.Coupon__r.RecordType.DeveloperName;
                String mappingKey = couponMainsite+'_'+cs.Coupon__r.RecordType.DeveloperName;
                String[] listHeader = mapHeaderColForAttachement.containsKey(mappingKey)?mapHeaderColForAttachement.get(mappingKey):null;
                List<Messaging.EmailFileAttachment> listAtt = null;
                if(mapListCoInvest.containsKey(cs.Id) && listHeader <> null)
                {
                    //LA-28-09-2023: US-0013980
                    // if(cs.Coupon__r.Contract_Language__c == 'AU') listAtt = generateCSAttachments(cs,mapListCoInvest.get(cs.Id),listHeader, mapFieldsAUForAttachement);
                    if(cs.Coupon__r.Main_Coupon_Site__c == COUPONSITE_AU) listAtt = generateCSAttachments(cs,mapListCoInvest.get(cs.Id),listHeader, mapFieldsAUForAttachement);
                    else listAtt = generateCSAttachments(cs,mapListCoInvest.get(cs.Id),listHeader, mapFieldsForAttachement);
                    //mapListAtt.put(cs.Id,listAtt);
                    for(Messaging.EmailFileAttachment efa : listAtt){
                        Attachment att = new Attachment(ParentId=cs.Id,Name=efa.FileName,Body=efa.Body,ContentType=efa.ContentType);
                        listCsAtt.add(att);
                    }
                }
            }
            if(!listCsAtt.isEmpty())
            {
                insert listCsAtt;
            }
        }
    }
    
    private static Map<String,String> mapRetURL = new Map<String,String>{'DE'=>'reURL=www.ebay.de','UK'=>'reURL=www.ebay.co.uk','FR'=>'reURL=www.ebay.fr','US'=>'reURL=www.ebay.com'};
    
    private static Task createTask(String subject,Coupon_Seller__c cs,String htmlBody){
        Task t = new Task();
        t.Subject = 'Email: '+subject;
        t.WhatId = cs.Id;
        t.Status = 'Completed';
        if(currUserId!=''){
            t.OwnerId = currUserId;
        }
        
        t.ActivityDate = System.today();
        t.Description = htmlBody;
        t.IsVisibleInSelfService = false;
        t.TaskSubtype = 'Email';
        t.RecordTypeId = ApexUtil.getRecordTypeByName('Task','Standard_Task').Id;
        t.Log_Task__c = true;
        
        return t;
    }
    
    /******************************************************************************************************************************
    @ Change history: 8.11.2021 / Sambath Seng / US-0010476 - AU Coupon email template content update
    *****************************************************************************************************************************/
    private static String mergSubjectContract(String s, Coupon_Seller__c cs)
    {
        //Start SB 8.10.2021 US-001047 US-0010476 - AU Coupon email template content update
        DateTime couponStartDate = Datetime.newInstance(cs.Coupon__r.Coupon_Start_Date__c.Year(),cs.Coupon__r.Coupon_Start_Date__c.Month(),cs.Coupon__r.Coupon_Start_Date__c.Day());
        DateTime couponEndDate = Datetime.newInstance(cs.Coupon__r.Coupon_End_Date__c.Year(),cs.Coupon__r.Coupon_End_Date__c.Month(),cs.Coupon__r.Coupon_End_Date__c.Day());
        //End SB 8.10.2021 US-001047 US-0010476 - AU Coupon email template content update
        return s==null?'':s.replace('{eBaySellerID}',cs.Seller__r.Name+'')
                .replace('{Coupon_ID__c}',cs.Coupon_ID__c+'')
                .replace('{!CouponName}',cs.Coupon__r.Name)
                .replace('{!Coupon_Seller__c.Coupon_ID__c}',cs.Coupon_ID__c+'')
                .replace('{CouponNameM}',cs.Coupon__r.Marketing_Coupon_Name__c+'')
                .replace('{CouponStartDate}',cs.Coupon__r.Coupon_Start_Date__c.format())
                .replace('{!Coupon_Seller__c.Coupon_Start_Date__c}',couponStartDate == null ? '' : couponStartDate.format(DF_DD_MM_YYYY))//SB 8.10.2021 US-001047 US-0010476 - Change date format to dd/mm/yyyy
                .replace('{CouponEndDate}',cs.Coupon__r.Coupon_End_Date__c.format())
                .replace('{!Coupon_Seller__c.Coupon_End_Date__c}',couponEndDate == null ? '' : couponEndDate.format(DF_DD_MM_YYYY))//SB 8.10.2021 US-001047 US-0010476 - Change date format to dd/mm/yyyy
                ;       
    }
    
    /******************************************************************************************************************************
    @ Change history: 8.11.2021 / Sambath Seng / US-0010476 - AU Coupon email template content update
    *****************************************************************************************************************************/
    public static String mergeFieldsContractCoupon(String s, Coupon_Seller__c cs, Map<String,List<Coupon_Co_Invest__c>> mapListCoInvest) 
    {
        String categories = '';
        //Start SB 3.11.2021 US-0010476 - AU Coupon email template content update
        //LA:10/12/2020: US-0008237- declare this string to replace in {UKFreeSubtitle}
        String textUKFreeSubtitle1 = System.Label.UKFreeSubtitle1;
        String textUKFreeSubtitle2 = System.Label.UKFreeSubtitle2;
        String textUKFreeSubtitle3 = System.Label.UKFreeSubtitle3;
        String textUKFreeSubtitle4 = System.Label.UKFreeSubtitle4;
        //End US-0008237
        String couponMainsite = COUPON_MAINSITE_MAPPING.get(cs.Coupon__r.Main_Coupon_Site__c);//LA-28-09-2023: US-0013980
        DateTime couponStartDate = Datetime.newInstance(cs.Coupon__r.Coupon_Start_Date__c.Year(),cs.Coupon__r.Coupon_Start_Date__c.Month(),cs.Coupon__r.Coupon_Start_Date__c.Day());
        DateTime couponEndDate = Datetime.newInstance(cs.Coupon__r.Coupon_End_Date__c.Year(),cs.Coupon__r.Coupon_End_Date__c.Month(),cs.Coupon__r.Coupon_End_Date__c.Day());
        DateTime contractDueDate = Datetime.newInstance(cs.Coupon__r.Contract_Due_Date__c.Year(),cs.Coupon__r.Contract_Due_Date__c.Month(),cs.Coupon__r.Contract_Due_Date__c.Day());
        //End SB 1.10.2021 US-001047 US-0010476 - AU Coupon email template content update
        Map<Integer,String> mapCategories = new Map<Integer,String>();
        if(cs != null && mapListCoInvest != null && mapListCoInvest.containsKey(cs.Id)){
            for(Coupon_Co_Invest__c coInvest : mapListCoInvest.get(cs.Id)){
                if(coInvest.Category__c == null) continue;
                if(coInvest.Category__c == 'Australia (Site Level)'){
                    mapCategories.put(1,System.Label.AU_Category + '<br/>');
                }else{
                    mapCategories.put(2,System.Label.Not_AU_Category + '<br/>');
                }
            }
        }
        
        if(!mapCategories.isEmpty()){
            List<Integer> listOrder = new List<Integer>();
            listOrder.addAll(mapCategories.keySet());
            listOrder.sort();
            for(Integer i : listOrder){
                categories += mapCategories.get(i);
            }
        }
        return s==null?'':s
        //TH: 29/04/2021: US-0009000 - Coupon seller template remove column free subtitle
        //.replace('{FreeSubtitleParagraph}',cs.Free_Subtitles__c=='Yes'?System.Label.UK_FreeSubtitleParagraph.replace('\n','<br/>'):'')
        .replace('{Max_Redemptions__c}',cs.Coupon__r.Max_Redemptions__c==null?'':ApexUtil.formatNumber(cs.Coupon__r.Max_Redemptions__c,0,couponMainsite))
        .replace('{CouponName}',cs.Coupon__r.Name)
        .replace('{CouponNameM}',cs.Coupon__r.Marketing_Coupon_Name__c+'')
        .replace('{LegalEntity}',ApexUtil.checkNull(cs.Legal_Entity_Name_w__c)+'')
        .replace('{StreetName}',ApexUtil.checkNull(cs.Legal_Entity_Street_w__c)+'')
        .replace('{Zip}',ApexUtil.checkNull(cs.Legal_Entity_Zip_w__c)+'')
        .replace('{City}',ApexUtil.checkNull(cs.Seller__r.Parent.EBH_BillingCity__c)+'') 
        .replace('{CityForSiteDE}',ApexUtil.checkNull(cs.Legal_Entity_City__c)+'') //LA-22-2-2022-US-0011286: Only for site DE 
        .replace('{eBaySellerID}',cs.Seller__r.Name+'')
        .replace('{CouponSites}',ApexUtil.checkNull(cs.Coupon__r.Couponsite_s__c)+'')
        .replace('{PayPalAdress}',ApexUtil.checkNull(cs.PayPal_adress_N__c)+'')
        .replace('{CouponStartTime}',ApexUtil.formatTime(cs.Coupon__r.Coupon_Start_Time__c))
        .replace('{CouponStartDate}',couponStartDate == null ? '' : couponStartDate.format(DF_DD_MM_YYYY))//SB 1.11.2021 US-0010476 Change date format to dd/mm/yyyy
        .replace('{CouponEndTime}',ApexUtil.formatTime(cs.Coupon__r.Coupon_end_Time__c))
        .replace('{CouponEndDate}',couponEndDate == null ? '' : couponEndDate.format(DF_DD_MM_YYYY))//SB 1.11.2021 US-0010476 Change date format to dd/mm/yyyy
        .replace('{CouponDiscount%}',cs.Coupon__r.Coupon_Discount__c==null?'':ApexUtil.formatNumber(cs.Coupon__r.Coupon_Discount__c,2,couponMainsite)+'%')
        .replace('{CouponDiscountAmount}',cs.Coupon__r.Coupon_Discount_Amount__c==null?'':ApexUtil.mapCurrencySign.get(cs.Coupon__r.CurrencyIsoCode)+ApexUtil.formatNumber(cs.Coupon__r.Coupon_Discount_Amount__c,3,couponMainsite)) 
        .replace('{CouponCap}',cs.Coupon__r.Coupon_Cap__c==null?'N/A':ApexUtil.mapCurrencySign.get(cs.Coupon__r.CurrencyIsoCode)+ApexUtil.formatNumber(cs.Coupon__r.Coupon_Cap__c,2,couponMainsite)) 
        //.replace('{TCsURL}',cs.Coupon__r.T_Cs_URL__c==null?'':cs.Coupon__r.T_Cs_URL__c)
        .replace('{AdditionalArrangement}',cs.Additional_Terms__c==null?'':cs.Additional_Terms__c+'')
        .replace('{Minimum_Transaction_Value__c}',cs.Coupon__r.Minimum_Transaction_Value__c==null?'N/A':ApexUtil.mapCurrencySign.get(cs.Coupon__r.CurrencyIsoCode)+ApexUtil.formatNumber(cs.Coupon__r.Minimum_Transaction_Value__c,2,couponMainsite))
        .replace('{!ContractDueDate}',cs.Coupon__r.Contract_Due_Date__c==null?'':cs.Coupon__r.Contract_Due_Date__c.format())
        .replace('{ContractDueDate}',contractDueDate == null ? '' : contractDueDate.format(DF_DD_MM_YYYY))//SB 1.11.2021 US-0010476 Change date format to dd/mm/yyyy
        .replace('{Coupon_ID__c}',cs.Coupon_ID__c+'')
        .replace('{ABNVATNumber}',ApexUtil.checkNull(cs.Seller__r.EBH_VATNumber__c)+'')
        .replace('{Country}',ApexUtil.checkNull(cs.Seller__r.Parent.EBH_BillingCountry__c)+'')
        .replace('{AdSpendDate}',cs.Ad_Spend_Date__c == null?'':cs.Ad_Spend_Date__c.format())
        .replace('{AdSpendAmount}',cs.Advertising_Amount__c==null?'':ApexUtil.mapCurrencySign.get(cs.CurrencyIsoCode)+ApexUtil.formatNumber(cs.Advertising_Amount__c,3,couponMainsite))
        //TH: 29/04/2021: US-0009000 - Coupon seller template remove column free subtitle
        //.replace('{FreeSubtitleParagraph2}',cs.Free_Subtitles__c=='Yes'?System.Label.AU_FreeSubtitleParagraph:'')
        .replace('{AdditionalTermsOverrideofAgreement}',cs.Additional_Terms_Override_of_Agreement__c==null?'':cs.Additional_Terms_Override_of_Agreement__c+'')
        .replace('{type}',categories)
        
        .replace('{!Coupon_Seller__c.Coupon_ID__c}',cs.Coupon_ID__c+'')
        .replace('{!CurrentYear}',System.now().format('YYYY'))
        .replace('{!Coupon_Seller__c.Coupon_Start_Date__c}',cs.Coupon__r.Coupon_Start_Date__c==null?'':cs.Coupon__r.Coupon_Start_Date__c.format())
        .replace('{!Coupon_Seller__c.Coupon_End_Date__c}',cs.Coupon__r.Coupon_End_Date__c==null?'':cs.Coupon__r.Coupon_End_Date__c.format())
        .replace('{!Coupon_Seller__c.Cost_Share_Seller_LC__c}',cs.Cost_Share_Seller_LC__c==null?'':ApexUtil.formatNumber(cs.Cost_Share_Seller_LC__c,2,couponMainsite)) 
        .replace('{!Coupon_Seller__c.Contra_LC__c}',cs.Contra_LC__c==null?'':ApexUtil.formatNumber(cs.Contra_LC__c,2,couponMainsite))
        .replace('{!Coupon_Seller__c.GMV_LC__c}',cs.GMV_LC__c==null?'':ApexUtil.formatNumber(cs.GMV_LC__c,2,couponMainsite))
        
        .replace('{CONTRACT_ACCEPT_DATE}',cs.Contract_Accept_Date_Z__c==null ? '' : cs.Contract_Accept_Date_Z__c.format())
        .replace('{COUPON_SUBTITLE_COPY}',ApexUtil.checkNull(cs.Coupon__r.Coupon_Subtitle_Copy__c)+'')
        //LA:10/12/2020: US-0008237- display {UKFreeSubtitle} if Coupon_Seller.Free_Subtitles__c = 'Yes'
        //TH:US-0009000 :comment Out.replace('{UKFreeSubtitle}',cs.Free_Subtitles__c=='Yes'?textUKFreeSubtitle1+'<br/>'+ApexUtil.checkNull(cs.Coupon__r.Coupon_Subtitle_Copy__c)+'<br/>'+textUKFreeSubtitle2+ApexUtil.formatTime(cs.Coupon__r.Coupon_Start_Time__c)+' on '+cs.Coupon__r.Coupon_Start_Date__c.format()+textUKFreeSubtitle3+ApexUtil.formatTime(cs.Coupon__r.Coupon_end_Time__c)+' on '+cs.Coupon__r.Coupon_End_Date__c.format()+textUKFreeSubtitle4:'')
        .replace('{!Coupon_Seller__c.Id}',cs.Id==null?'':cs.Id)
        .replace('{!url}',System.URL.getOrgDomainUrl().toExternalForm())
        .replace('{ACCEPTED_FROM}',cs.Contract_Accepted_From_Z__c==null ? '' : cs.Contract_Accepted_From_Z__c)
        .replace('{!Coupon_Seller__c.SiteURL__c}',cs.SiteURL__c==null ? '' : cs.SiteURL__c)
        .replace('{MainCouponSite}',ApexUtil.checkNull(cs.Coupon__r.Main_Coupon_Site__c)+'')
        .replace('{SellerFundingRate%}',mapListCoInvest == null || !mapListCoInvest.containsKey(cs.Id) ? '' : mapListCoInvest.get(cs.Id)[0].Seller_Funding__c+'%')//SB 1/11/2021 US-0010476 - Add more field to email template
        .replace('{Coupon_Additional_Terms__c}',cs.Coupon__r.Coupon_Additional_Terms__c==null ? '' : cs.Coupon__r.Coupon_Additional_Terms__c) //MN-08062022-US-0011834
        ;
    }   
    
    //NK:EPH-7582: add table to col: {Category Name} ({Category ID}): {Seller Share %}
    private static String generateHTMLTable(Coupon_Co_Invest__c[] listCovinvest,String htmlRowStringTemplate,Boolean istext,EmailTemplate emt)
    { 
        if(listCovinvest==null || (listCovinvest <>null && listCovinvest.isEmpty()))return '';
        
        String htmlString = htmlTableTemplate;
        String htmlRowString  = '';
        for(Coupon_Co_Invest__c cci : listCovinvest)
        { 
            //LA-28-09-2023: US-0013980: Replace all Contract_Language__c to Main_Coupon_Site__c
            String couponMainsite = COUPON_MAINSITE_MAPPING.get(cci.Coupon_Seller__r.Coupon__r.Main_Coupon_Site__c);
            String coInvest = cci.Co_Invest__c==null?'N/A':ApexUtil.formatNumber(cci.Co_Invest__c,2,couponMainsite)+'%';
            String sellerFunding = cci.Seller_Funding__c==null?'N/A':ApexUtil.formatNumber(cci.Seller_Funding__c,2,couponMainsite)+'%';
            String columnCoInvestValue = cci.Coupon_Seller__r.Coupon__r.Main_Coupon_Site__c==COUPONSITE_AU?sellerFunding:coInvest;
            
            htmlRowString = htmlRowString + htmlRowStringTemplate
            // 22.02.2023 / Sophal Noch / US-0013293 :
            // .replace('{!catName}',cci.Category__c==null?'N/A':(cci.Category__c.containsIgnoreCase('UK (Site level)') && String.isBlank(cci.Category_ID__c) && (emt.DeveloperName == EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_UK_CAT))?System.label.Coupon_Category_Label : cci.Category__c+'')
            .replace('{!catName}',cci.Category__c==null?'N/A': cci.Category__c+'') 
            // 22.02.2023 / Sophal Noch / US-0013293 :
            // .replace('{!catId}',+String.isBlank(cci.Category_ID__c)?(emt.DeveloperName == EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_UK_CAT?'':' (N/A)'):' ('+cci.Category_ID__c+')')
            .replace('{!catId}',+String.isBlank(cci.Category_ID__c) ? ' (N/A)':' ('+cci.Category_ID__c+')') 
            .replace('{!coinvest%}',+columnCoInvestValue);
            //cs.Coupon__r.Coupon_Discount__c==null?'':ApexUtil.formatNumber(cs.Coupon__r.Coupon_Discount__c,2,cs.Coupon__r.Contract_Language__c)+'%')
        }
        //(cci.Category__c+''.containsIgnoreCase('UK (Site level)') && String.isBlank(cci.Category_ID__c) && (emt.DeveloperName == EBH_ConstantsUtility.EMAIL_COUPON_CONTRACT_UK_CAT))? System.label.Coupon_Category_Label : cci.Category__c+'')
        htmlString = istext ? htmlRowString : htmlString.replace('{!rows}',htmlRowString);
        return htmlString;
    }
    
    /*****************************************************************************************************************************
    @ Method:   setEmailAddress
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  
                EPH-7482 Object Coupon seller - New rule for field email adress
                AC1) When I go to any coupon seller record I will see the field email adress Email_Adress__c
                automatically populated from sellers related contact record. Having the following rule:
                Case
                When related contact field EBH_Decision_Maker_Role__c contains value "COUPON" then add email from contact and populate
                else take email from sellers related contact record type = DWH
                
                *The field will always be editable (RW) so that user can still change it in the coupon seller record
                
    @ Event:    Before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Seller__c> listNew
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2019 / Sovantheany Dim / Created the Method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 30.08.2021 / Mony Nou / US-0009948 - Replace Email field with a Contact lookup field on Coupon Seller object and use it in communication to sellers.
    *****************************************************************************************************************************/
    public static void setEmailAddress(List<Coupon_Seller__c> listNewSeller)
    {
        Set<Id> sSellerIds = new Set<Id>();
        for(Coupon_Seller__c couponSeller : listNewSeller){
            if(couponSeller.Seller__c == null) continue;
            sSellerIds.add(couponSeller.Seller__c);
        }
        
        if(sSellerIds.isEmpty()) return;
        
        Map<String,String> mapSellerAndEmail = new Map<String,String>();
        Set<String> sDecision = new Set<String>();
        String sWhere = ' where AccountId IN: sSellerIds';
        for(Contact con : Database.query(EBH_ConstantsUtility.SOQL_CONTACT+sWhere)){
            if(mapSellerAndEmail.containsKey(con.AccountId) && sDecision.contains(con.AccountId+'true')) continue;
            if(con.EBH_Decision_Maker_Role__c != null && con.EBH_Decision_Maker_Role__c.contains(EBH_ConstantsUtility.DECISION_MAKER_ROLE)){
                //mapSellerAndEmail.put(con.AccountId,con.Email); //MN-30082021-US-0009948
                mapSellerAndEmail.put(con.AccountId,con.Id); //MN-30082021-US-0009948
                sDecision.add(con.AccountId+'true');
            }else if(con.RecordType.DeveloperName == EBH_ConstantsUtility.CONTACT_RECORDTYPE_DWH){
                // mapSellerAndEmail.put(con.AccountId,con.Email); //MN-30082021-US-0009948
                mapSellerAndEmail.put(con.AccountId,con.Id); //MN-30082021-US-0009948
                sDecision.add(con.AccountId+'false');
            }
        }
        
        for(Coupon_Seller__c couponSeller : listNewSeller){
            if(couponSeller.Seller__c == null || !mapSellerAndEmail.containsKey(couponSeller.Seller__c)) continue;
            //couponSeller.Email_Adress__c = mapSellerAndEmail.get(couponSeller.Seller__c); //MN-30082021-US-0009948
            couponSeller.Seller_Contact__c = mapSellerAndEmail.get(couponSeller.Seller__c); //MN-30082021-US-0009948
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:   prepopulateOwnerFromSeller
    @ Version:  1.0
    @ Author:   Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:  EPH-7591 Add new field Owner to Coupon Seller Object and Coupon Co-Invest Object
                US-0015697 New Coupon Promotion preference fields on Customer Object
    @ Event:    After Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Seller__c> listNewCouponSeller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2019 / Acmatac Seing / Created the Method
    @ Change history: 03.10.2019 / Sovantheany Dim / Update the Method US-0015697
                      08.11.2022 / David Herrero / Update the method - US-0012680 . Instead of account owner we will use current user
                      30.04.2025 / Sothea Horn / US-0017159 - Replace OwnerId with Account_Manager__c for Coupon Related Class
    *****************************************************************************************************************************/
    public static void prepopulateOwnerFromSeller(List<Coupon_Seller__c> listNewCouponSeller)
    {
        List<Coupon_Seller__c> lstCS = new List<Coupon_Seller__c>();
        Set<Id> sSellerId = new Set<Id>();
        
        for(Coupon_Seller__c sCSeller : listNewCouponSeller){
            if(String.isBlank(sCSeller.EBH_CouponSellerOwner__c) && String.isNotBlank(sCSeller.Seller__c)){
                sSellerId.add(sCSeller.Seller__c);
                lstCS.add(sCSeller);
            }
        }
        
        if(!lstCS.isEmpty()){
            Map<Id, Id> mapAccOwner = new  Map<Id, Id>();
            for(Account sAcc : Database.query(QUERY_ACCOUNTEROWNER_FROMSELLER)){
                if(sAcc.Outreach_Manager__c != null){
                    mapAccOwner.put(sAcc.Id,sAcc.Outreach_Manager__c);
                }else{
                    //mapAccOwner.put(sAcc.Id, sAcc.OwnerId);
                    //US-0012680 
                    // 30/04/2025 - US-0017159 - Replace OwnerId with Account_Manager__c. If Account.Account_Manager__c has null value and we need value from it to populate other field, use value IntegrationUserId (0056A000000zaxM) to populate to other field
                    // mapAccOwner.put(sAcc.Id, IntegrationAndDeploymentUser.contains(sAcc.OwnerId)? UserInfo.getUserId():sAcc.OwnerId);
                    String accManager = String.isNotBlank(sAcc.Account_Manager__c) ? sAcc.Account_Manager__c : ApexUtil.INTEGRATION_USER_ID;
                    mapAccOwner.put(sAcc.Id, IntegrationAndDeploymentUser.contains(accManager) ? UserInfo.getUserId() : accManager);
                }
            }
            for(Coupon_Seller__c sCSeller : lstCS){
                sCSeller.EBH_CouponSellerOwner__c = mapAccOwner.get(sCSeller.Seller__c);
            }
        }
        
    }
    
    /*****************************************************************************************************************************
    @ Method:   setEmailManhattan
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  EPH-7565 Coupon - Manhattan Invoice Statment send to coupon seller
                
    @ Event:    Before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Seller__c> listNewCouponSeller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.07.2019 / Sovantheany Dim / Created the Method
    *****************************************************************************************************************************/
    public static void setEmailManhattan(List<Coupon_Seller__c> listNewCouponSeller)
    {
        for(Coupon_Seller__c couponSeller : listNewCouponSeller){
            if(couponSeller.Coupon_End_Date__c != null)
            {
                couponSeller.TriggerEmailManhattan__c = true;
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:   synCurrencyValueFrom_Coupon
    @ Version:  1.0
    @ Author:   Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:  EPH-7896 Coupon Seller and Coupon Co-Invest - Take the Currency value from related Coupon Object
                
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.08.2019 / Acmatac Seing / Method Creation
    *****************************************************************************************************************************/
    public static void synCurrencyValueFrom_Coupon(Map<Id, Coupon_Seller__c> mOldCpnSelr, List<Coupon_Seller__c> lstNew){

        Set<Id> sCpnId = new Set<Id>();
        // Is Insert
        if(mOldCpnSelr == null){
            for(Coupon_Seller__c aCpnSelr : lstNew){
                if(String.isNotBlank(aCpnSelr.Coupon__c)){
                    sCpnId.add(aCpnSelr.Coupon__c);
                }
            }
        }
        // Is Update
        else{
            Map<Id, Coupon_Seller__c> mNewCpnSelr = new Map<Id, Coupon_Seller__c>(lstNew);
            for(Id cpnCoInvId : mOldCpnSelr.keySet()){
                Coupon_Seller__c oldCpnSelr = mOldCpnSelr.get(cpnCoInvId);
                Coupon_Seller__c newCpnSelr = mNewCpnSelr.get(cpnCoInvId);
                if(oldCpnSelr.CurrencyIsoCode != newCpnSelr.CurrencyIsoCode && String.isNotBlank(newCpnSelr.Coupon__c)){
                    sCpnId.add(newCpnSelr.Coupon__c);
                }
            }
        }

        Map<Id, String> mCpnCurrencyVal = new Map<Id, String>();
        String cpnSQL = EBH_ConstantsUtility.COUPON_SQL.replace('[EXTRA_CLAUSE]','CurrencyIsoCode') + ' WHERE Id IN: sCpnId';
        for(Coupon__c aCpn : Database.query(cpnSQL)){
            mCpnCurrencyVal.put(aCpn.Id, aCpn.CurrencyIsoCode);
        }

        for(Coupon_Seller__c aCpnSelr : lstNew){
            if(String.isNotBlank(aCpnSelr.Coupon__c) && mCpnCurrencyVal.containsKey(aCpnSelr.Coupon__c)){
                aCpnSelr.CurrencyIsoCode = mCpnCurrencyVal.get(aCpnSelr.Coupon__c);
            }
        }

    }
    //LA-06-06-2023-US-0013029
    //private static set<String> sCouponSellerStage = new Set<String>{'Contract Signed','Coupon Running','Coupon executed','T4 Statement Send','T34 Statement Send'};
    private static set<String> sCouponSellerStage = new Set<String>{'Contract Signed','Coupon Running','Coupon executed','T34 Statement Send'};
    public static Boolean isUpdatedSellerStage = false;
    public static String currUserId = '';
    /*****************************************************************************************************************************
    @ Method:   blockManualSetStage
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  EPH-7880 Coupon Seller - Block any user to set stages running, executed, staements send (i.e. fields that are updated by Trigger)
    @ Trigger : before insert , before updated
    @ Param : List<Coupon_Seller__c> newCouponSeller,Map<Id, Coupon_Seller__c> mOldnCouponSeller            
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.08.2019 / Sovantheany Dim / Method Creation
    @ Change history: 13.01.2023 / Sovantheany Dim / US-0012310 - Errors while updating Coupon Seller Stage
    @               : 02.02.2023/vadhanak voun  / US-0013147 - Amend UK approval process for seller portal launch
    @               : 05.04.2023 / Sophal Noch / US-0013235 - [UK only] Only allow certain users to move coupon seller to contract send
    @               : 15.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
    @               : 21.08.2023 / Sambath Seng / US-0013978 - Introduce new Coupon Seller type for Long term Coupons
    *****************************************************************************************************************************/
    public static void blockManualSetStage(List<Coupon_Seller__c> newCouponSellers,Map<Id, Coupon_Seller__c> mOldnCouponSeller){
        Boolean isAdmin = (Userinfo.getprofileId() == ApexUtil.ADMIN_PROFILE_ID || Userinfo.getprofileId() == ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
        Map<Id,User> mapCSApprovers = ApexUtil.getUsersMemberByGroup(new Set<String>{'UK_Coupon_Seller_Approvers'});//NK:02/02/2023:US-0013147
        Boolean validUKApprover = mapCSApprovers.containsKey(UserInfo.getUserId());
        // 15.06.2023 / Acmatac Seing / US-0013714 No need to check anymore
        // Boolean isPromo = ApexUtil.checkPermissionSet(new Set<String>{'Promotions_User'});
        Set<String> setStageSendApprove = new Set<String>{COUPON_SELLER_STAGE_CONTRACT_SEND,COUPON_SELLER_SEP_STATUS_APPROVED};

        // SB 21.08.2023 US-0013978
        String scmcRecordTypeId = Schema.sObjectType.Coupon_Seller__c.getRecordTypeInfosByDeveloperName().get(RT_SCMC_SELLER).getRecordTypeId();

        for(Coupon_Seller__c newCouponSeller : newCouponSellers){

            // SB 21.08.2023 US-0013978
            if(newCouponSeller.RecordTypeId == scmcRecordTypeId) continue;
            
            //avoid issue in : EPH-8030 Issue in user story EPH-7258 and to avoid error on workflow Coupon Executed and Coupon Running
            if(isUpdatedSellerStage || (newCouponSeller.TriggerStageUpdatedDate__c != null && newCouponSeller.TriggerStageUpdatedDate__c != mOldnCouponSeller.get(newCouponSeller.Id).TriggerStageUpdatedDate__c)) continue;
            //--NK:02/02/2023:US-0013147--start
            //UK: only admins/group approvers are allowed to move from Targeted to other stages
            if(!isAdmin && newCouponSeller.Main_Coupon_Site__c==COUPONSITE_UK && isChangeFromTargeted(mOldnCouponSeller,newCouponSeller) && !validUKApprover)
            {
                newCouponSeller.Coupon_Seller_Stage__c.adderror(System.Label.ErrMSG_CS_StageRestricFromTargeted);
                continue;
            }

            // -- 05.04.2023 / Sophal Noch / US-0013235 : validate when UK coupon seller stage is updated to 'Contract Send' --start
            if(!isAdmin && !IS_UPDATED_BY_SYSTEM && newCouponSeller.Main_Coupon_Site__c==COUPONSITE_UK && isChangeToContractSend(mOldnCouponSeller,newCouponSeller) && !validUKApprover)
            {
                newCouponSeller.Coupon_Seller_Stage__c.adderror(System.Label.ErrMSG_CS_StageRestricFromTargeted);
                continue;
            }
            // -- 05.04.2023 / Sophal Noch / US-0013235 --end

            // 15.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
            //UK promotion user can change to conntract send or approve - After approver moved from Targeted (above) to other stage
            // if(Trigger.isUpdate && newCouponSeller.Main_Coupon_Site__c==COUPONSITE_UK && (isAdmin || isPromo) && (newCouponSeller.Coupon_Seller_Stage__c <> mOldnCouponSeller.get(newCouponSeller.Id).Coupon_Seller_Stage__c && setStageSendApprove.contains(newCouponSeller.Coupon_Seller_Stage__c)) )
            // {
            //  continue;
            // }
            //--NK:02/02/2023:US-0013147--end

            if(!isAdmin && newCouponSeller.Coupon_Seller_Stage__c != null && sCouponSellerStage.contains(newCouponSeller.Coupon_Seller_Stage__c) && (trigger.isInsert || (trigger.isUpdate && newCouponSeller.Coupon_Seller_Stage__c != mOldnCouponSeller.get(newCouponSeller.Id).Coupon_Seller_Stage__c))){
                newCouponSeller.Coupon_Seller_Stage__c.adderror(System.Label.ErrMSG_CS_StageRestricManual);//NK:02/02/2023:US-0013147 - replaced by cusstom label
            }

        }
    }

    /*****************************************************************************************************************************
    @ Method:   isChangeFromTargeted
    @ Version:  1.0
    @ Author:   vadhanak (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0013147 - Amend UK approval process for seller portal launch
    @ Trigger : before insert , before updated
    @ Param : Coupon_Seller__c csOld, Coupon_Seller__c csNew        
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.02.2023 / vadhanak / Method Creation
    *****************************************************************************************************************************/
    private static Boolean isChangeFromTargeted(Map<Id, Coupon_Seller__c> mOldnCouponSeller, Coupon_Seller__c csNew)
    {
        //create new with Targeted 
        //or move from Targeted to any
        //return (Trigger.isInsert && csNew.Coupon_Seller_Stage__c==COUPON_SELLER_STAGE_CONTRACT_TARGETED) || 
        return (Trigger.isUpdate && mOldnCouponSeller.get(csNew.Id).Coupon_Seller_Stage__c==COUPON_SELLER_STAGE_CONTRACT_TARGETED && csNew.Coupon_Seller_Stage__c<>COUPON_SELLER_STAGE_CONTRACT_TARGETED);
    }

    /*****************************************************************************************************************************
    @ Method:   isChangeToContractSend
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  US-0013235 - [UK only] Only allow certain users to move coupon seller to contract send
    @ Trigger : before insert , before updated
    @ Param : Coupon_Seller__c csOld, Coupon_Seller__c csNew        
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.04.2023 / Sophal Noch / Method Creation
    *****************************************************************************************************************************/
    private static Boolean isChangeToContractSend(Map<Id, Coupon_Seller__c> mOldnCouponSeller, Coupon_Seller__c csNew)
    {
        return (Trigger.isUpdate && csNew.Coupon_Seller_Stage__c==COUPON_SELLER_STAGE_CONTRACT_SEND && csNew.Coupon_Seller_Stage__c != mOldnCouponSeller.get(csNew.Id).Coupon_Seller_Stage__c);
    }

    private static String htmlTemplate = '<html><head><meta http-equiv="Content-Type" content="text/HTML;charset=UTF-8" /></head><body>{!body}</body></html>';
    private static String htmlTableTemplate2 = '<table border="1"  width="100%" cellspacing="0" cellpadding="2"><tbody>{!rows}</tbody></table>';
    private static String htmlTableTR_Template = '<tr style="font-size: 8px;">{!tr}</tr>';
    private static String htmlTableTD_Template = '<td>{!td}</td>';
    /*****************************************************************************************************************************
    @ Method:   generateCSAttachments
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  EPH-7781 Coupon Contract Attachement - change form csv to Excel and pdf
    @ Trigger : called from method: sendContract()
    @ Param :   
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.08.2019 / Vadhanak Voun  / Method Creation
    *****************************************************************************************************************************/
    private static List<Messaging.EmailFileAttachment> generateCSAttachments(Coupon_Seller__c cs,List<Coupon_Co_Invest__c> listCoInvest,List<String> listHeader,Map<String,String[]> mapFields)
    {
        List<Messaging.EmailFileAttachment> listAtt = new List<Messaging.EmailFileAttachment>();
        List<List<String>> listRows = new List<List<String>>{listHeader};
        
        //col heade for pdf
        String trs = '';
        String tdH = '';
        for(String h : listHeader)
        {
            tdH += htmlTableTD_Template.replace('{!td}',h);
        }
        trs += htmlTableTR_Template.replace('{!tr}',tdH); 
        
        for(Coupon_Co_Invest__c cci : listCoInvest)
        {
            String tds = '';
            List<String> listCells = new List<String>();
            for(String f: mapFields.get(cs.Coupon__r.RecordType.DeveloperName))
            {
                Object s = ApexUtil.getValue(f,cci); 
                s = (f=='Site__c'?EBH_ConstantsUtility.MAP_CODE_TO_COUNTRY.get(s+''):s); //NK:29/05/2019: EPH-7557  
                //TH: 22/09/2021 : US-0010302
                if((f == 'Coupon_Seller__r.Coupon__r.Coupon_Start_Date__c') || (f == 'Coupon_Seller__r.Coupon__r.Coupon_End_Date__c')){
                    Date d = (Date) s;
                    s = d.format();
                }
                //End TH: 22/09/2021 : US-0010302
                listCells.add(s==null?'':s+'');
                tds += htmlTableTD_Template.replace('{!td}',s==null?'':s+'');
            }
            trs += htmlTableTR_Template.replace('{!tr}',tds); 
             listRows.add(listCells);
        }
        String htmlAtt = htmlTemplate.replace('{!body}',htmlTableTemplate2.replace('{!rows}',trs));
         
        ExcelGenerator.xSheet sheet1 = new ExcelGenerator.xSheet('Sheet1',listRows);
        List<ExcelGenerator.xSheet> listSheets = new  List<ExcelGenerator.xSheet>();
        listSheets.add(sheet1);
        
        ExcelGenerator generator = new ExcelGenerator('Apex',listSheets); 
        generator.generateWorkBook();
        String xml = generator.getWorkbookXML();
        //LA-28-09-2023: US-0013980 : Replace Coupon__r.Contract_Language__c in Coupon__r.Main_Coupon_Site__c
        //String fileName = cs.Coupon__r.Contract_Language__c=='DE'?'Email Anhang.xls':'Co-Invests.xls';
        //String fileNamePDF = cs.Coupon__r.Contract_Language__c=='DE'?'Email Anhang.pdf':'Co-Invests.pdf';
        String fileName = cs.Coupon__r.Main_Coupon_Site__c == COUPONSITE_DE?'Email Anhang.xls':'Co-Invests.xls';
        String fileNamePDF = cs.Coupon__r.Main_Coupon_Site__c == COUPONSITE_DE?'Email Anhang.pdf':'Co-Invests.pdf';
        
        listAtt.add(createFileAtt(fileName,'application/vnd.ms-excel',Blob.valueOf(xml)));  //csv
        listAtt.add(createFileAtt(fileNamePDF,'application/pdf',Blob.toPDF(htmlAtt)));      //pdf
                
        return listAtt;
    }
    
    private static Messaging.EmailFileAttachment createFileAtt(String fName,String contentType,Blob body)
    {
        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
        fileAttachment.setBody(body);
        fileAttachment.setFileName(fName); 
        fileAttachment.setContentType(contentType);
        return fileAttachment;
    }
    
    /*****************************************************************************************************************************
    @ Method:   blockDuplicatedSeller
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  EPH-7967 Coupon Seller Object - Validation Rule: Block creation of duplicate sellers
    @ Trigger : before insert , before updated
    @ Param : List<Coupon_Seller__c> newCouponSeller,Map<Id, Coupon_Seller__c> mOldnCouponSeller            
    ------------------------------------------------------------------------------------------------------------------------------
       @ Change history: 18.09.2019 / Sovantheany Dim / Method Creation
                         04.11.2021 / Sovantheany Dim / Update US-0010617 - DE POP COUPON contract renewal: adding existing sellers to a promo
    *****************************************************************************************************************************/
    public static void blockDuplicatedSeller(List<Coupon_Seller__c> newCouponSellers,Map<Id, Coupon_Seller__c> mOldnCouponSeller){
        String popRecordTypeId = ApexUtil.getRecordTypeByName('Coupon_Seller__c','Pop_Coupon').Id;
        //LA-05-06-2023-US-0013029-Retiring Picklist value 'Commited'
        //set<String> sStage = new set<String>{'New','Pitch Ready','Reached','Commited','Contract Send','Contract Accepted','Running'};
        set<String> sStage = new set<String>{'New','Pitch Ready','Reached','Contract Send','Contract Accepted','Running'};
        for(Coupon_Seller__c newCouponSeller : newCouponSellers){
            if(trigger.isInsert || (trigger.isUpdate && ((newCouponSeller.Coupon__c != mOldnCouponSeller.get(newCouponSeller.Id).Coupon__c) || (newCouponSeller.Seller__c != mOldnCouponSeller.get(newCouponSeller.Id).Seller__c) || (newCouponSeller.recordTypeId == popRecordTypeId && newCouponSeller.Coupon_Seller_Stage__c != mOldnCouponSeller.get(newCouponSeller.Id).Coupon_Seller_Stage__c)))){
                if(newCouponSeller.recordTypeId != popRecordTypeId) newCouponSeller.Coupon_Seller_ID_2__c = newCouponSeller.Coupon__c +'/'+ newCouponSeller.Seller__c;
                //TH: 04.11.2021: US-0010617
                else{
                    newCouponSeller.Coupon_Seller_ID_2__c = (sStage.contains(newCouponSeller.Coupon_Seller_Stage__c))?newCouponSeller.Coupon__c +'/'+ newCouponSeller.Seller__c : null;
                }
            }
        }
        
    }
    
     /*****************************************************************************************************************************
    @ Method:   sendT4_T34Email
    @ Version:  1.0
    @ Author:   vadhanak.voun@gaea-sys.com
    @ Purpose:  US-0018725  Coupon Seller - Add condition to workflow for stage T4Statement and T40 Statement
    @           Moved from workflow, as the story need to check status before sending email/update
    @           fields updated from timebase workflow to trigger this method
    @ Trigger : //before updated. called from Coupon trigger
    @ Param : List<Coupon_Seller__c> newCouponSeller,Map<Id, Coupon_Seller__c> mOldnCouponSeller            
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 01.10.2019 / Vadhanak Voun / Method Creation
    @               : 10.03.2020/  Vadhanak Voun / US-0007219 US-0007219 - Coupon & Coupon Seller - attach T4 and T40 statement & custom flag
    @                           added flag to custom setting and to allow send email or not
    @               : 30.08.2021 / Acmatac SEING / US-0010176 - MC: Coupon email notifications to external users
    @               : 05.06.2023 / Loumang SENG / US-0013029 - Streamline of coupon seller statuses & retiring coupon fields
    *****************************************************************************************************************************/
    public static void sendT4_T34Email(List<Coupon_Seller__c> listNew,Map<Id,Coupon_Seller__c>mapOld)
    {
        Map<String,String> mapEmail_CSId = new Map<String,String>();
        List<Coupon_Seller__c> listCSSellect = new List<Coupon_Seller__c>();
        for(Coupon_Seller__c cs: listNew)
        {
            // US-0010176 - Acmatac SEING, Send email only MC_Whitelisted__c = False
            if(cs.MC_Whitelisted__c){ 
                continue;
            }
            //LA-06-06-2023-US-0013029
            /*if(
                (cs.Day4AfterCouponEnd_Trigger_DE__c <>  mapOld.get(cs.Id).Day4AfterCouponEnd_Trigger_DE__c && cs.Day4AfterCouponEnd_Trigger_DE__c <> null) &&
                 cs.Coupon_Seller_Stage__c == EBH_ConstantsUtility.COUPON_SELLER_STAGE_EXEC && cs.Contract_Accept_Date__c <> null && cs.Contract_Language__c == 'DE')
            {
                cs.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_T4;
                mapEmail_CSId.put(cs.Id,EBH_ConstantsUtility.EMAIL_TEMPLATE_CS_T4_DE);
                listCSSellect.add(cs);
            }else if( (cs.Day34AfterCouponEnd_Trigger_DE__c <>  mapOld.get(cs.Id).Day34AfterCouponEnd_Trigger_DE__c && cs.Day34AfterCouponEnd_Trigger_DE__c <> null) &&
                cs.Coupon_Seller_Stage__c == EBH_ConstantsUtility.COUPON_SELLER_STAGE_T4 && cs.Contract_Accept_Date__c <> null && cs.Contract_Language__c == 'DE')
            */
            if(
                (cs.Day34AfterCouponEnd_Trigger_DE__c <>  mapOld.get(cs.Id).Day34AfterCouponEnd_Trigger_DE__c && cs.Day34AfterCouponEnd_Trigger_DE__c <> null) &&
                cs.Coupon_Seller_Stage__c == EBH_ConstantsUtility.COUPON_SELLER_STAGE_EXEC && cs.Contract_Accept_Date__c <> null && cs.Coupon__r.Main_Coupon_Site__c == COUPONSITE_DE)
            {
                cs.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_34;
                mapEmail_CSId.put(cs.Id,EBH_ConstantsUtility.EMAIL_TEMPLATE_CS_T34_DE);
                listCSSellect.add(cs);
            }
        }
        if(!mapEmail_CSId.isEmpty())
        {
            //NK:10/03/2020:US-0007219
            if(EBH_ActiveTriggers__c.getInstance(EBH_ConstantsUtility.TRIGGERCONTROLLER).Coupon_Seller_Send_T4_T40_to_seller__c)
            {
            sendTX_Mail(mapEmail_CSId);
        }
            
        }
    }
    
    private static void sendTX_Mail(Map<String,String> mapEmail_CSId)
    {
        Set<String> setCSId = mapEmail_CSId.keySet();
        Set<String> setTemplates = new Set<String>{EBH_ConstantsUtility.EMAIL_TEMPLATE_CS_T4_DE,EBH_ConstantsUtility.EMAIL_TEMPLATE_CS_T34_DE};
        String sWhere = ' Where Id IN:setCSId';
        Map<String,EmailTemplate> mapEmailTemplate = new Map<String,EmailTemplate>();
        for(emailTemplate et: Database.query(EBH_ConstantsUtility.SOQLEMAIL_TEMPLATES+' Where DeveloperName IN:setTemplates'))
        {
            mapEmailTemplate.put(et.DeveloperName,et);
        }
         
        List<Coupon_Seller__c> listCSSellect = Database.query(SOQL_COUPON_SELLER+sWhere);
        List<Messaging.SingleEmailMessage> listSendMail = new List<Messaging.SingleEmailMessage>();
        
        for(Coupon_Seller__c cs: listCSSellect)
        {   

            if(cs.Seller_Contact__c == null || cs.Seller_Contact__r.Email == null){ //MN-30082021-US-0009948
                continue;
            }

            EmailTemplate et = mapEmailTemplate.get(mapEmail_CSId.get(cs.Id));
            String subject = mergSubjectContract(et.Subject,cs);
            String htmlBody = mergeFieldsContractCoupon(et.HtmlValue,cs, null);
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            mail.setToAddresses(new String[]{cs.Seller_Contact__r.Email}); //MN-30082021-US-0009948
            // mail.setToAddresses(new String[]{cs.Email_Adress__c}); //MN-30082021-US-0009948
            if(cs.EBH_CouponSellerOwner__c <> null)
            {
                mail.setccAddresses(new String[]{Test.isRunningTest()?'test@test.com': cs.EBH_CouponSellerOwner__r.Email});
            }
            //mail.setSenderDisplayName(cs.EBH_CouponSellerOwner__c <> null?cs.EBH_CouponSellerOwner__r.Name:cs.Coupon__r.Owner.Name);
            mail.setSubject(subject);
            mail.setBccSender(false);
            mail.setUseSignature(false); 
            mail.setHtmlBody(htmlBody);
            //TH: 20/10/2020: US-0008543 - Set OrgWideDefault Address
            String replyto = (cs.EBH_CouponSellerOwner__c <> null && cs.EBH_CouponSellerOwner__r.Email <> null)?cs.EBH_CouponSellerOwner__r.Email:cs.Coupon__r.Owner.Email;
            setOrgWideAddress(mail,replyto,System.label.OWD_MKT_REP);
            //End US-0008543
            listSendMail.add(mail);
        }   
        if(!listSendMail.isEmpty() && !Test.isRunningTest())
        {
            Messaging.sendEmail(listSendMail);
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:   setCouponPromotionPreferences
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  US-0015696 [AU] "Coupon Promotion Preferences" to be updated in Coupon Seller
                
    @ Event:    Before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Seller__c> listNewCouponSeller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.11.2019 / Sovantheany Dim / Created the Method
    *****************************************************************************************************************************/
    public static void setCouponPromotionPreferences(List<Coupon_Seller__c> listNewCouponSeller)
    {
        Set<String> sSeller = new Set<String>();
        List<Coupon_Seller__c> lstCouponSeller = new List<Coupon_Seller__c>();
        for(Coupon_Seller__c couponSeller : listNewCouponSeller){
            if(couponSeller.Seller__c != null)
            {
                sSeller.add(couponSeller.Seller__c);
                lstCouponSeller.add(couponSeller);
            }
        }
        if(sSeller.isEmpty()) return;
        String sWhere = ' where id IN: sSeller';
        Map<Id,Account> mapSeller = new Map<Id,Account>((List<Account>) Database.query(EBH_ConstantsUtility.SOQL_SELLER+sWhere));
        for(Coupon_Seller__c cs : lstCouponSeller){
            if(!mapSeller.containsKey(cs.Seller__c)) return;
            Account acc = mapSeller.get(cs.Seller__c);
            cs.Outreach_Manager__c = acc.Outreach_Manager__c;
            cs.Coupon_Promotions_Participation__c = acc.Coupon_Promotions_Participation__c;
            cs.Coupon_Promotion_Types__c = acc.Coupon_Promotion_Types__c;
            cs.Coupon_Discount_Rate__c = acc.Coupon_Discount_Rate__c;
            cs.Coupon_Funding_Preference__c = acc.Coupon_Funding_Preference__c;
        }
    }
    
     
    /*****************************************************************************************************************************
    @ Method:   couponSellerContractReminderAU
    @ Version:  1.0
    @ Author:   LoumAng SENG (loumang.seng@gaea-sys.com)
    @ Purpose:  US-0006337 - [AU] Contract Reminder Email notification to all AU Coupon Sellers
                
    @ Event:    After Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Seller__c> listNewCseller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.11.2019 / LoumAng SENG / Created the Method
    @ Change history: 02.09.2022 / Chetra Sarom / US-0012067 - Deactivate automatic task "Urgent Action Required - Call the Seller"
    ****************************************************************************************************************************/
    // US-0012067 - Deactivate automatic task "Urgent Action Required - Call the Seller"
    //  public static void couponSellerContractReminderAU(List<Coupon_Seller__c> listNewCseller, Map<Id,Coupon_Seller__c>mapOldCseller)
    // {
            
    //      List<Task> lstTask = new List<Task>();
    //      for(Coupon_Seller__c cs : listNewCseller){
    //          if(cs.Day_1_Alert__c <> mapOldCseller.get(cs.Id).Day_1_Alert__c)
    //          {
    //              lstTask.add(createTaskAU(cs)); 
    //          }
    //      }
    //      if(!lstTask.isEmpty()){
                
    //          insert lstTask;
    //      }
    // }
    // end US-0012067 - Deactivate automatic task "Urgent Action Required - Call the Seller"

    /*****************************************************************************************************************************
    @ Method    :   couponSellerStageApproved_OnlySpecialPermiss
    @ Version   :   1.0
    @ Author    :   Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose   :   US-0005984 Only user with special permission can move stage to 'Approved'
    @ Trigger   :   before insert, before update
    @ Param     :   Map<Id, Coupon_Seller__c> mOldnCouponSlr, List<Coupon_Seller__c> lstCpnSlr
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.10.2019 / Acmatac SEING / Method Creation
    @               : 02.02.2023/vadhanak voun  / US-0013147 - Amend UK approval process for seller portal launch
    @               : 15.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
    @               : 02.04.2024 / Mony Nou / US-0014557 - Bulk Coupon Approval process for NA
    @               : 16.06.2025 / Sambath Seng / US-0012493 - Update Error Message with correct details on Coupon(Seller) approve stage update
    *****************************************************************************************************************************/
    public static void couponSellerStageApproved_OnlySpecialPermiss(Map<Id, Coupon_Seller__c> mOldnCouponSlr, List<Coupon_Seller__c> lstCpnSlr){
        //String couponSpecailPermission = EBH_ConstantsUtility.PERMISSION_COUPONSPECIALPERMISSION;
        //String CouponSellerStage_Negotiation = EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO;
        //String CouponSellerStage_Approved = EBH_ConstantsUtility.COUPONSELLER_STAGE_APPROVED;

        Boolean isAdmin = (Userinfo.getprofileId() == ApexUtil.ADMIN_PROFILE_ID || Userinfo.getprofileId() == ApexUtil.ADMIN_LT_PRIV_PROFILE_ID); 
        if(isAdmin)return;

        // 15.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
        Boolean hasPermis = ApexUtil.checkPermissionSet(new Set<String>{'Coupon_Special_Permission'}) || FeatureManagement.checkPermission(ApexUtil.COUPON_BULK_EDITS_CUSTOM_PERMISSION);
        Boolean isInsert = mOldnCouponSlr == null;

        //MN-02042024-US-0014557--START: Get Bond Team's user infor
        Set<String> sCouponSellerBondTeamQueue = new Set<String>(System.label.CouponSellerNABondTeamQueue.split(','));
        Map<Id, User> mBondTeam = ApexUtil.getUsersMemberByGroup(sCouponSellerBondTeamQueue);
        Boolean isBondTeam = !mBondTeam.isEmpty() && mBondTeam.containsKey(UserInfo.getUserId());
        //MN-02042024-US-0014557--STOP
        
        for(Coupon_Seller__c cpnSlr : lstCpnSlr){
            
            if(cpnSlr.Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_APPROVED 
                && cpnSlr.Main_Coupon_Site__c==COUPONSITE_UK 
                    && (Trigger.isInsert || (Trigger.isUpdate && cpnSlr.Coupon_Seller_Stage__c<>mOldnCouponSlr.get(cpnSlr.Id).Coupon_Seller_Stage__c)) 
                        && hasPermis)continue; //NK:02/02/2023:US-0013147
            
            //MN-02042024-US-0014557--START: FOR US Coupon Seller, only Bond Team member that able to change stage to "Approved"
            if (cpnSlr.Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_APPROVED && cpnSlr.Main_Coupon_Site__c==COUPONSITE_US) {
                hasPermis = isBondTeam;
            }
            //MN-02042024-US-0014557--STOP  

            if(isInsert){
                if(cpnSlr.Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_APPROVED && !hasPermis){
                    // cpnSlr.addError(Label.Label_Only_users_with_Coupon_Special_Permission_can_approve);
                    cpnSlr.addError(Label.MissingCouponSellerApproverGroup); //SB 16.06.2025 US-0012493
                }
            }else{
                Coupon_Seller__c oldCpnSlr = mOldnCouponSlr.get(cpnSlr.Id);
                Boolean checkCondit = oldCpnSlr.Coupon_Seller_Stage__c != cpnSlr.Coupon_Seller_Stage__c;
                checkCondit = checkCondit && cpnSlr.Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_APPROVED && !hasPermis;
                if(checkCondit){
                    // cpnSlr.addError(Label.Label_Only_users_with_Coupon_Special_Permission_can_approve);
                    cpnSlr.addError(Label.MissingCouponSellerApproverGroup); //SB 16.06.2025 US-0012493
                }
            }
            
        }
    }

    /*****************************************************************************************************************************
    @ Method    :   validateCoInv_SellerShareAndCompanyDetail
    @ Version   :   1.0
    @ Author    :   Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose   :   US-0006335 Coupon - Validation Rules not to allow coinvest and company details empty for contract send out
    @ Trigger   :   before update
    @ Param     :   Map<Id, Coupon_Seller__c> mOldCpnSlr, Map<Id, Coupon_Seller__c> mNewCpnSlr
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.02.2020 / Acmatac SEING / Method Creation
                      13.02.2020 / Acmatac SEING / Move AC2 to Validation Rule -> Validate_CompanyDetailForContractSend   
                      10.01.2023 / Loumang SENG / US-0012995 :US-0012995 - Additional safeguarding for coupon seller automation
                      13.03.2023/ vadhanak voun/ US-0013328 - Amend validation rule for 0% co-invest records
    *****************************************************************************************************************************/
    public static void validateCoInv_SellerShareAndCompanyDetail(Map<Id, Coupon_Seller__c> mOldnCpnSlr, Map<Id, Coupon_Seller__c> mNewCpnSlr){
        Boolean isAdmin = (SET_ADMIN_PROFILE_ID.contains(Userinfo.getprofileId())); //LA-10-01-2023-US-0012995
        Set<String> sCpnSlrId = new Set<String>();
        for(Coupon_Seller__c newCpnSlr : mNewCpnSlr.values()){
            // As any user when I click on stage CONTRACT SEND on any coupon seller record
            if(!isAdmin && mOldnCpnSlr.get(newCpnSlr.Id).Coupon_Seller_Stage__c != newCpnSlr.Coupon_Seller_Stage__c 
                && newCpnSlr.Coupon_Seller_Stage__c == EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND){
                // AC2) As any user when I click on stage CONTRACT SEND on any coupon seller record there will be a validation rule if there are any related co-invest records that have a NULL Value for
                // Legal Entity Company
                // Legal Entity Street
                // Legal Entity ZIP
                // if(String.isBlank(newCpnSlr.Legal_Entity_Name_w__c) || String.isBlank(newCpnSlr.Legal_Entity_Street_w__c) || String.isBlank(newCpnSlr.Legal_Entity_Zip_w__c)){
                //  newCpnSlr.addError(Label.CouponSellerStageContractSend_Error1);
                // }else{
                //  sCpnSlrId.add(newCpnSlr.Id);
                // }
                sCpnSlrId.add(newCpnSlr.Id);
            }
        }

        if(!sCpnSlrId.isEmpty()){
            //LA-10-01-2023:US-0012995
            // for(Coupon_Seller__c cpnSlr : Database.query(EBH_ConstantsUtility.CPNSLR_CPNCOINVSQL)){
            for(Coupon_Seller__c cpnSlr : Database.query(CPNSLR_CPNCOINVSQL)){
                // AC1) As any user when I click on stage CONTRACT SEND on any coupon seller record there will be a validation rule 
                // If there are any related coinvest records that have a NULL Value for SELLER SHARE %.
                //LA-10-01-2023:US-0012995
                if(cpnSlr.Coupon_Co_Invests__r.isEmpty()){//validate null related coinvest records
                    mNewCpnSlr.get(cpnSlr.Id).addError(Label.CouponSellerStageContractSend_NullCoInvestRecordError);
                //}else if(cpnSlr.Coupon_Co_Invests__r[0].Co_Invest__c == null || cpnSlr.Coupon_Co_Invests__r[0].Co_Invest__c == 0){//validate any related coinvest records that have a NULL Value for SELLER SHARE %
                //NK:13/02/2023:US-0013328-allow zero. check only null
                }else if(cpnSlr.Coupon_Co_Invests__r[0].Co_Invest__c == null){//validate any related coinvest records that have a NULL Value for SELLER SHARE %
                    mNewCpnSlr.get(cpnSlr.Id).addError(Label.CouponSellerStageContractSend_Error2);
                }
            
            }

        }
        
    }

    // US-0012067 - Deactivate automatic task "Urgent Action Required - Call the Seller"
    // private static Task createTaskAU(Coupon_Seller__c cs){
    //     Task t = new Task();
    //     t.Subject = 'Urgent Action Required - Call the Seller';
    //     t.Priority = 'High';
    //     t.Type = 'Call';
    //     t.Status = 'Open';
    //     t.WhatId = cs.Id;
    //  t.IsVisibleInSelfService = false;
    //     t.OwnerId = cs.EBH_CouponSellerOwner__c;
    //     t.ActivityDate = cs.Coupon_Contract_Due_Date__c;
    //     return t;
    // }
    // end US-0012067 - Deactivate automatic task "Urgent Action Required - Call the Seller"
    
    /*****************************************************************************************************************************
    @ Method    :   sendCouponLaunchReminderTemplates
    @ Version   :   1.0
    @ Author    :   Sovantheany.dim (sovantheany.dim@gaea-sys.com)
    @ Purpose   :   US-0007639 - Coupon Launch Reminder Templates
    @ Trigger   :   after updated
    @ Param     :   Map<Id, Coupon_Seller__c> mOldnCouponSeller, Map<Id, Coupon_Seller__c> mNewCouponSeller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.07.2020 / Sovantheany.dim / Method Creation
@                   08/06/2021 / Sovantheany dim/ update Method : US-0008623 - [Coupon] AU Retail Promotions DL being used incorrectly for UK, DE
@                   Lets make sure for coupon contract and for Coupon reminder emails
@                       if Contract_Language__c = 'AU', then the 'from' email address must be retailpromotions@ebay.com
@                       if Contract_Language__c = 'UK', then the 'from' email address must be dealnominations@ebay.com

     ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 30.08.2021 / Mony Nou / US-0009948 - Replace Email field with a Contact lookup field on Coupon Seller object and use it in communication to sellers.
    @               : 30.08.2021 / Acmatac SEING / US-0010176 - MC: Coupon email notifications to external users
    @               : 27.10.2022 / Sovantheany Dim / US-0012864 - Move coupon seller owner in BCC for coupon launch reminder communication
    @               : 16.01.2023 / Sambath Seng / US-0012735 - Migrate coupon start reminder to seller communication records
    *****************************************************************************************************************************/
    // commented by DHE
    // uncommented by Ratha Sim on 2020-09-09 because of US-0008170
    // Adding the posibility to active / deactivate this feature US-0011031 
    // commented by 16.01.2023 / Sambath Seng / US-0012735 - Migrate coupon start reminder to seller communication records
    /* public static void sendCouponLaunchReminderTemplates(Map<Id, Coupon_Seller__c> mOldnCouponSeller, List<Coupon_Seller__c> newCouponSellers){
        try{

            initSettings();
            if (!sendReminder){
                return; // if the switch exist and is not active, exit from the method
            }
        Set<String> sCpnSellerId = new Set<String>();
        for(Coupon_Seller__c newCouponSeller : newCouponSellers){
            Coupon_Seller__c oldCpnSeller = mOldnCouponSeller.get(newCouponSeller.Id);

            // US-0010176 - Acmatac SEING, Send email only MC_Whitelisted__c = False
            if(newCouponSeller.MC_Whitelisted__c){
                continue;
            }

            if(newCouponSeller.UK_Coupon_Launch_Reminder_Date__c != null && oldCpnSeller.UK_Coupon_Launch_Reminder_Date__c != newCouponSeller.UK_Coupon_Launch_Reminder_Date__c){
                sCpnSellerId.add(newCouponSeller.Id);
            }
        }
        //System.debug('<<<<<sCpnSellerId='+sCpnSellerId);
        if(!sCpnSellerId.isEmpty()){
            Map<String,List<Coupon_Co_Invest__c>> mapListCoInvest = getListCoinvest(sCpnSellerId);
            Set<String> setEmailTemplates = new Set<String>{EMAIL_COUPON_LAUNCH_REMINDER_TEMPLATE};
            List<EmailTemplate> emts = Database.query(EBH_ConstantsUtility.SOQLEMAIL_TEMPLATES +' Where DeveloperName IN :setEmailTemplates');
            if(emts.isEmpty()) return;
            
            String sWhere = ' Where Id IN:sCpnSellerId';
            Map<String,Coupon_Seller__c> mapCS = new Map<String,Coupon_Seller__c>();
            List<Coupon_Seller__c> listCSSellect = Database.query(SOQL_COUPON_SELLER+sWhere);
            List<Messaging.SingleEmailMessage> listSendMail = new List<Messaging.SingleEmailMessage>();
            List<Task> lstTask = new List<Task>();
            Map<String,List<Messaging.EmailFileAttachment>> mapListAtt = new Map<String,List<Messaging.EmailFileAttachment>>();
            
            for(Coupon_Seller__c cs: listCSSellect)
            {
                String mappingKey = cs.Coupon__r.Contract_Language__c+'_'+cs.Coupon__r.RecordType.DeveloperName;
                String[] listHeader = mapHeaderCol.containsKey(mappingKey)?mapHeaderCol.get(mappingKey):null;
                List<Messaging.EmailFileAttachment> listAtt = null;
                if(mapListCoInvest.containsKey(cs.Id) && listHeader <> null)
                {
                    if(cs.Coupon__r.Contract_Language__c == 'AU') listAtt = generateCSAttachments(cs,mapListCoInvest.get(cs.Id),listHeader, mapFieldsAU);
                    else listAtt = generateCSAttachments(cs,mapListCoInvest.get(cs.Id),listHeader, mapFields);
                    mapListAtt.put(cs.Id,listAtt);
                }
                
                String subject = mergSubjectContract(emts[0].Subject,cs);
                String htmlBody = mergeFieldsContractCoupon(emts[0].HtmlValue,cs,null);
                String textBody = mergeFieldsContractCoupon(emts[0].Body,cs,null);
                
                htmlBody = htmlBody.contains('{!CatNameIdTable}')?htmlBody.replace('{!CatNameIdTable}',generateHTMLTable(mapListCoInvest.get(cs.Id),htmlRowTemplateUK,false,emts[0])):htmlBody;
                textBody = textBody.contains('{!CatNameIdTable}')?textBody.replace('{!CatNameIdTable}',generateHTMLTable(mapListCoInvest.get(cs.Id),'{!catName} {!catId} \n',true,emts[0])):textBody;
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{cs.Seller_Contact__r.Email}); //MN-30082021-US-0009948
                //mail.setToAddresses(new String[]{cs.Email_Adress__c}); //MN-30082021-US-0009948
                if(cs.EBH_CouponSellerOwner__c <> null)
                {
                    //TH: 27/10/2022: US-0012864 - Move coupon seller owner in BCC for coupon launch reminder communication
                    //mail.setccAddresses(new String[]{Test.isRunningTest()?'test@test.com': cs.EBH_CouponSellerOwner__r.Email});
                    mail.setBccAddresses(new String[]{Test.isRunningTest()?'test@test.com': cs.EBH_CouponSellerOwner__r.Email});
                }
                //TH: 20/10/2020: US-0008543 mail.setSenderDisplayName(cs.EBH_CouponSellerOwner__c <> null?cs.EBH_CouponSellerOwner__r.Name:cs.Coupon__r.Owner.Name);
                mail.setSubject(subject);
                mail.setBccSender(false);
                mail.setUseSignature(false); 
                mail.setHtmlBody(htmlBody);
                //TH: 20/10/2020: US-0008543 - Set OrgWideDefault Address
                String replyto = (cs.EBH_CouponSellerOwner__c <> null && cs.EBH_CouponSellerOwner__r.Email <> null)?cs.EBH_CouponSellerOwner__r.Email:cs.Coupon__r.Owner.Email;
                //setOrgWideAddress(mail,replyto,System.label.OWD_MKT_REP);//comment out :TH:08/06/2021:US-0008623
                //if AU Email must be sent via retailpromotions@ebay.com and UK sent via dealnominations@ebay.com
                if(mapOrgWideAdd.containsKey(cs.Coupon__r.Contract_Language__c)){
                    setOrgWideAddress(mail,replyto,mapOrgWideAdd.get(cs.Coupon__r.Contract_Language__c));
                }//if DE sent from current user
                else {
                    mail.setSenderDisplayName(UserInfo.getName());
                }
                //End US-0008543
                
                if(listAtt <> null)
                {
                    mail.setFileAttachments(listAtt); 
                }
                listSendMail.add(mail);
                
                String fileName = '';
                if(listAtt != null && !listAtt.isEmpty()){
                    for(Messaging.EmailFileAttachment fileAtt : listAtt){
                    fileName += ' '+fileAtt.filename+',';
                    }
                    fileName = fileName.removeEnd(',');
                }
                //String description = 'To: '+cs.Email_Adress__c+'\n'+ //MN-30082021-US-0009948
                String description = 'To: ' + cs.Seller_Contact__r.Email + '\n' + //MN-30082021-US-0009948
                'CC: '+cs.EBH_CouponSellerOwner__r.Email+'\n'+
                'BCC: \n'+
                'Attachment:'+fileName+'\n\n'+
                'Subject: '+subject+'\n'+
                'Body: \n'+textBody;
                Task t = createTask(subject,cs,description);
                lstTask.add(t);
            }


            if(!listSendMail.isEmpty() && !Test.isRunningTest()) Messaging.sendEmail(listSendMail);
            
            if(!lstTask.isEmpty()) 
            {
                insert lstTask;
                List<Attachment> listTaskAtt = new List<Attachment>();
                for(Task t: lstTask)
                {   
                    List<Messaging.EmailFileAttachment> listEFA = mapListAtt.get(t.WhatId);
                    if(listEFA <> null)
                    {
                        for(Messaging.EmailFileAttachment efa: listEFA) //xls body, and pdf body from sent email attament and attach to Task
                        {
                            Attachment att = new Attachment(ParentId=t.Id,Name=efa.FileName,Body=efa.Body,ContentType=efa.ContentType);
                            listTaskAtt.add(att);
                        } 
                    }
                }
                if(!listTaskAtt.isEmpty())
                {
                    insert listTaskAtt;
                }
            }
            
        }
        }catch(Exception e){
            EBH_ApexLogger.logError(new List<Exception> { e }, 'CouponSellerTriggerHandler','sendCouponLaunchReminderTemplates');
        }
        
    } */
    
    //TH: 20/10/2020: US-0008543 - Set OrgWideDefault Address
    public static void setOrgWideAddress(Messaging.SingleEmailMessage mail,String replyTo, String orgAdd){
        OrgWideEmailAddress orgWide = ApexUtil.getOWDbyAddress(orgAdd);
        if(orgWide != null) mail.setOrgWideEmailAddressId(orgWide.Id);
         mail.setReplyTo(replyTo);
    }
    
    /*****************************************************************************************************************************
    @ Method    :   sendCpnAcceptOfCpnContr
    @ Version   :   1.0
    @ Author    :   sreymeas.nao (sreymeas.nao@gaea-sys.com)
    @ Purpose   :   US-0007771 - [AU] Additional Coupon Confirmation email post acceptance of Coupon Contract
    @ Trigger   :   after updated
    @ Param     :   Map<Id, Coupon_Seller__c> mOldnCouponSeller, Map<Id, Coupon_Seller__c> mNewCouponSeller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 03.08.2020 / Sreymeas Nao / Method Creation
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 30.08.2021 / Mony Nou / US-0009948 - Replace Email field with a Contact lookup field on Coupon Seller object and use it in communication to sellers.
    @               : 30.08.2021 / Acmatac SEING / US-0010176 - MC: Coupon email notifications to external users
    @               : 24.04.2023 / Loumang SENG / US-0012802 - [Launch Day] Remove BETA criteria for coupon emails + deactivate old flows (AC3)
    *****************************************************************************************************************************/
    /*public static void sendCpnAcceptOfCpnContr(Map<Id, Coupon_Seller__c> mOldnCouponSeller, List<Coupon_Seller__c> newCouponSellers){
        try {
            Set<String> sCpnSellerId = new Set<String>();
            Set<String> sCpnContrtemp = new Set<String>();
            for(Coupon_Seller__c newCouponSeller : newCouponSellers){
                Coupon_Seller__c oldCpnSeller = mOldnCouponSeller.get(newCouponSeller.Id);
                // US-0010176 - Acmatac SEING, Send email only MC_Whitelisted__c = False
                if(newCouponSeller.MC_Whitelisted__c){
                    continue;
                }

                if(newCouponSeller.Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_CONTRACT_SIGNED  && oldCpnSeller.Coupon_Seller_Stage__c != newCouponSeller.Coupon_Seller_Stage__c){
                    sCpnSellerId.add(newCouponSeller.Id);
                }
            }
            List<Coupon_Seller__c> lstCpn = [select Id,Coupon__r.Contract_Language__c from Coupon_Seller__c where Id IN :sCpnSellerId];
            for (Coupon_Seller__c cpns : lstCpn) {
                if (cpns.Coupon__r.Contract_Language__c==COUPON_TEMPLATE_LANGUAGE_AU) {
                    sCpnContrtemp.add(cpns.Coupon__r.Contract_Language__c);
                }
            }

            if(!sCpnSellerId.isEmpty()&&!sCpnContrtemp.isEmpty()){
                Set<String> setEmailTemplates = new Set<String>{EMAIL_COUPON_CONTRACT_ACCEPTANCE_TEMPLATE};
                List<EmailTemplate> emts = Database.query(SOQLEMAIL_TEMPLATES +' Where DeveloperName IN :setEmailTemplates');
                if(emts.isEmpty()) return;
            
                String sWhere = ' Where Id IN:sCpnSellerId';
                Map<String,Coupon_Seller__c> mapCS = new Map<String,Coupon_Seller__c>();
                List<Coupon_Seller__c> listCSSellect = Database.query(SOQL_COUPON_SELLER+sWhere);
                List<Messaging.SingleEmailMessage> listSendMail = new List<Messaging.SingleEmailMessage>();
                List<Task> lstTask = new List<Task>();
                Map<String,List<Messaging.EmailFileAttachment>> mapListAtt = new Map<String,List<Messaging.EmailFileAttachment>>();
                
                for(Coupon_Seller__c cs: listCSSellect){
                    String subject = mergSubjectContract(emts[0].Subject,cs);
                    String htmlBody = mergeFieldsContractCoupon(emts[0].HtmlValue,cs,null);
                    String textBody = mergeFieldsContractCoupon(emts[0].Body,cs,null);

                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[]{cs.Seller_Contact__r.Email}); //MN-30082021-US-0009948
                    //mail.setToAddresses(new String[]{cs.Email_Adress__c}); //MN-30082021-US-0009948
                    if(cs.EBH_CouponSellerOwner__c <> null)
                    {
                        mail.setccAddresses(new String[]{Test.isRunningTest()?'test@test.com': cs.EBH_CouponSellerOwner__r.Email});
                    }
                    //mail.setSenderDisplayName(cs.EBH_CouponSellerOwner__c <> null?cs.EBH_CouponSellerOwner__r.Name:cs.Coupon__r.Owner.Name);
                    mail.setSubject(subject);
                    mail.setBccSender(false);
                    mail.setUseSignature(false); 
                    mail.setHtmlBody(htmlBody);
                    //TH: 20/10/2020: US-0008543 - Set OrgWideDefault Address
                    String replyto = (cs.EBH_CouponSellerOwner__c <> null && cs.EBH_CouponSellerOwner__r.Email <> null)?cs.EBH_CouponSellerOwner__r.Email:cs.Coupon__r.Owner.Email;
                    setOrgWideAddress(mail,replyto,System.label.OWD_MKT_REP);
                    //End US-0008543
                    //String description = 'To: '+cs.Email_Adress__c+'\n'+ //MN-30082021-US-0009948
                    String description = 'To: ' + cs.Seller_Contact__r.Email + '\n' + //MN-30082021-US-0009948
                    'CC: '+cs.EBH_CouponSellerOwner__r.Email+'\n'+
                    'Subject: '+subject+'\n'+
                    'Body: \n'+textBody;

                    listSendMail.add(mail);
                    Task t = createTask(subject,cs,description);
                    lstTask.add(t);
                }

                if(!listSendMail.isEmpty() && !Test.isRunningTest()) Messaging.sendEmail(listSendMail);
                if(!lstTask.isEmpty()) {
                    insert lstTask;
                }
            }
        } catch (Exception e) {
            EBH_ApexLogger.logError(new List<Exception> { e }, 'CouponSellerTriggerHandler','sendCouponLaunchReminderTemplates');
        }
    }*/

    /*****************************************************************************************************************************
    @ Method    :   assignSiteUrl
    @ Version   :   1.0
    @ Author    :   sreymeas.nao (sreymeas.nao@gaea-sys.com)
    @ Purpose   :   US-0008290 - Wrong URL for Coupon Agreement
    @ Trigger   :   before Insert, update
    @ Param     :   List<Coupon_Seller__c> listCpnSellerNew
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.09.2020 / Sreymeas Nao / Method Creation
    *****************************************************************************************************************************/
    public static void assignSiteUrl(List<Coupon_Seller__c> listCpnSellerNew)
    {
        for(Coupon_Seller__c cpnseller: listCpnSellerNew)
        {
            if(cpnseller.SiteURL__c == null) cpnseller.SiteURL__c = ApexUtil.getSiteUrl('Deal_Acceptance');
        }
    }   
    
    /*****************************************************************************************************************************
    @ Method    :   assignSPRule
    @ Version   :   1.0
    @ Author    :   vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose   :   US-0012593 - Remove targeted coupon seller records from global search
    @ Trigger   :   before Insert, update
    @ Param     :   List<Coupon_Seller__c> listCpnSellerNew
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.09.2022 /vadhanak voun / Method Creation
    *****************************************************************************************************************************/
    public static void assignSPRule(List<Coupon_Seller__c> listCpnSellerNew)
    {
        for(Coupon_Seller__c cs: listCpnSellerNew)
        {
             cs.SP_Rule_Allowed__c = (cs.Coupon_Seller_Stage__c <> COUPON_SELLER_STAGE_CONTRACT_TARGETED);
        }
    }

    //DHE Initialize settings for custom metadata types
private static void initSettings(){
    setting = setting == null ? [SELECT Active__c  From Switch_services__mdt where DeveloperName =: COUPON_LAUNCH_REMINDER LIMIT 1] : setting;
    sendReminder = setting.Active__c;
    if (Test.isRunningTest()){
        sendReminder=true;
    }

}

    /*****************************************************************************************************************************
    @ Method    :   calculateCouponSeller
    @ Version   :   1.0
    @ Author    :   Loumang SENG (loumang.seng@gaea-sys.com)
    @ Purpose   :   US-0010777 - External Sharing for Coupon Seller Object
    @ Trigger   :   After Insert,After Update
    @ Param     :   List<Coupon_Seller__c> listCpnSeller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.02.2022 / Loumang SENG / Method Creation
    *****************************************************************************************************************************/
    public static void calculateCouponSeller(List<Coupon_Seller__c> listNew,Map<Id,Coupon_Seller__c>mapOld)
    {
        Boolean isNew = (mapOld==null);
        Map<Id,Coupon__c> mapCouponUpdate = new Map<Id,Coupon__c>();

        Set<Id> setCountSeller = new Set<Id>();
        Set<Id> setCountStage = new Set<Id>();
        Set<Id> setCountDate = new Set<Id>();

        for(Coupon_Seller__c cs : listNew){
            
            Coupon__c couponToUpdate = mapCouponUpdate.get(cs.Coupon__c);
            if(couponToUpdate == null) couponToUpdate = new Coupon__c(Id=cs.Coupon__c);
            
            if(isNew && (cs.coupon__c != null)){
                couponToUpdate.Sellers_Targeted2__c = 0;
                setCountSeller.add(cs.coupon__c);
            }
            if(!isNew && (cs.Coupon_Seller_Stage__c != mapOld.get(cs.Id).Coupon_Seller_Stage__c) && (SET_COUPONSELLER_STAGE.contains(mapOld.get(cs.Id).Coupon_Seller_Stage__c) || SET_COUPONSELLER_STAGE.contains(cs.Coupon_Seller_Stage__c))){
                couponToUpdate.Sellers_Contract_Send2__c = 0;
                setCountStage.add(cs.coupon__c);
            }
            if(!isNew && (cs.Contract_Accept_Date__c != mapOld.get(cs.Id).Contract_Accept_Date__c)){
                couponToUpdate.Sellers_Contract_Signed2__c = 0;
                setCountDate.add(cs.coupon__c);
            }

            if(couponToUpdate.Sellers_Targeted2__c != null || couponToUpdate.Sellers_Contract_Send2__c != null || couponToUpdate.Sellers_Contract_Signed2__c != null){
                mapCouponUpdate.put(couponToUpdate.Id, couponToUpdate);
            }
        }

        if(!mapCouponUpdate.isEmpty()){
            // Count all coupon seller records to populate in Coupon__c.Sellers_Targeted2__c
            if(!setCountSeller.isEmpty()){
                populateCouponCounts([SELECT coupon__c cId, count(Id) csCountSeller FROM Coupon_Seller__c WHERE coupon__c IN: setCountSeller Group by coupon__c]
                                    ,mapCouponUpdate
                                    ,COUNT_COUPON_SELLER);
            }
            // Count Coupon_Seller_Stage__c from 'Contract Send' until 'Invoice Paid' to populate in Coupon__c.Sellers_Contract_Send2__c
            if(!setCountStage.isEmpty()){
                populateCouponCounts([SELECT coupon__c cId, count(Coupon_Seller_Stage__c) csCountStage FROM Coupon_Seller__c WHERE coupon__c IN: setCountStage AND Coupon_Seller_Stage__c IN:SET_COUPONSELLER_STAGE Group by coupon__c]
                                    ,mapCouponUpdate
                                    ,COUNT_COUPON_SELLER_STAGE);
            }
            // Count Contract_Accept_Date__c != null  to populate in Coupon__c.Sellers_Contract_Signed2__c
            if(!setCountDate.isEmpty()){
                populateCouponCounts([SELECT coupon__c cId, count(Contract_Accept_Date__c) csCountDate FROM Coupon_Seller__c WHERE coupon__c IN: setCountDate AND Contract_Accept_Date__c <> null Group by coupon__c]
                                    ,mapCouponUpdate
                                    ,COUNT_COUPON_SELLER_ACCEPT_DATE);
            }

            update mapCouponUpdate.values();
        }
        
    }

    public static void populateCouponCounts(List<AggregateResult> listCounts, Map<Id,Coupon__c> mapCoupon, String fieldNameCount){

        for(AggregateResult aggr : listCounts){
            Id cId = (Id)aggr.get(KEY_CID);
            Coupon__c coupon = mapCoupon.get(cId);
            if(fieldNameCount == COUNT_COUPON_SELLER) coupon.Sellers_Targeted2__c = (Integer)aggr.get(COUNT_COUPON_SELLER);
            if(fieldNameCount == COUNT_COUPON_SELLER_STAGE) coupon.Sellers_Contract_Send2__c = (Integer)aggr.get(COUNT_COUPON_SELLER_STAGE);
            if(fieldNameCount == COUNT_COUPON_SELLER_ACCEPT_DATE) coupon.Sellers_Contract_Signed2__c = (Integer)aggr.get(COUNT_COUPON_SELLER_ACCEPT_DATE);
        }

    }



    /*****************************************************************************************************************************
    @ Method:   resetCouponFields
    @ Version:  1.0
    @ Author:   Loumang SENG (loumang.seng@gaea-sys.com)
    @ Purpose:  US-0010777 - External Sharing for Coupon Seller Object
    @ Event:    Before Delete
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: Map<Id, Coupon_Seller__c> oldCouonSeller 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.02.2022 / Loumang SENG / Method Creation
    @               : 23.11.2023 / Sambath Seng / US-0014433 - Coupon Seller Delete trigger-Null Pointer exception
    *****************************************************************************************************************************/
    public static void resetCouponFields(Map<Id, Coupon_Seller__c> oldCouonSeller)
    {
        Set<String> setCSId = new Set<String>();
        Map<Id,Coupon__c> mapCoupon = new Map<Id,Coupon__c>();
        for (Coupon_Seller__c cs : [SELECT Id,Contract_Accept_Date__c,Coupon__c,Coupon__r.Sellers_Targeted2__c, Coupon_Seller_Stage__c, Coupon__r.Sellers_Contract_Send2__c,Coupon__r.Sellers_Contract_Signed2__c FROM Coupon_Seller__c WHERE Id IN:oldCouonSeller.keySet()]) {
            //SB 23.11.2023 US-0014433 - Coupon Seller Delete trigger-Null Pointer exception
            /* Coupon__c coupon = mapCoupon.get(cs.Coupon__c);
            if(coupon == null){
                coupon = cs.Coupon__r;
                mapCoupon.put(cs.Coupon__c,coupon);
            }
            coupon.Sellers_Targeted2__c = ((coupon.Sellers_Targeted2__c == null)? 0:coupon.Sellers_Targeted2__c-1);
            coupon.Sellers_Contract_Send2__c = (coupon.Sellers_Contract_Send2__c==null?0:(!SET_COUPONSELLER_STAGE.contains(cs.Coupon_Seller_Stage__c)?coupon.Sellers_Contract_Send2__c:coupon.Sellers_Contract_Send2__c-1));
            coupon.Sellers_Contract_Signed2__c = (coupon.Sellers_Contract_Signed2__c==null?0:(cs.Contract_Accept_Date__c == null?coupon.Sellers_Contract_Signed2__c:coupon.Sellers_Contract_Signed2__c-1));
            */
            if(cs.Coupon__c != null){
                Coupon__c coupon = new Coupon__c();
                if(mapCoupon.containskey(cs.Coupon__c)) coupon = mapCoupon.get(cs.Coupon__c);
                else coupon = cs.Coupon__r;
                
                coupon.Sellers_Targeted2__c = ((coupon.Sellers_Targeted2__c == null)? 0:coupon.Sellers_Targeted2__c-1);
                coupon.Sellers_Contract_Send2__c = (coupon.Sellers_Contract_Send2__c==null?0:(!SET_COUPONSELLER_STAGE.contains(cs.Coupon_Seller_Stage__c)?coupon.Sellers_Contract_Send2__c:coupon.Sellers_Contract_Send2__c-1));
                coupon.Sellers_Contract_Signed2__c = (coupon.Sellers_Contract_Signed2__c==null?0:(cs.Contract_Accept_Date__c == null?coupon.Sellers_Contract_Signed2__c:coupon.Sellers_Contract_Signed2__c-1));
                
                mapCoupon.put(cs.Coupon__c,coupon);
            }
        }
        update mapCoupon.values();
    }

    /*********************************************************************************************************************************
    @ Method:         couponSellerStatusMappingWithSEP
    @ Version:        1.0
    @ Author:         Sambath SENG (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0010431 - Create Coupon details view on portal
    @ Event:          before insert, before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<EBH_Deal__c> newCS, Map<Id,EBH_Deal__c> oldMap
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  12.05.2022 / Sambath Seng / Created the method
    @                  05.09.2023 / Mony Nou / US-0013979 - Long Term Coupons Visible on Portal (Seller Facing): AC3
    @                  26.11.2025 / LoumAng SENG / US-0033705 - POP - SP - POP Coupons to be Visible on Portal (Seller Facing)
    *********************************************************************************************************************************/
    public static void couponSellerStatusMappingWithSEP(List<Coupon_Seller__c> newCS, Map<Id,Coupon_Seller__c> oldMap){
        //LA-26-11-2025-US-0033705: move recordtype Manhattan and SCMC to constant SET_COUPONSELLER_RT_ID
        //RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',COUPONSELLER_MANHATTAN_RECORDTYPE);
        //RecordType scmcCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',COUPONSELLER_SCMC_RECORDTYPE); //MN-05092023-US-0013979
        for(Coupon_Seller__c cs: newCS){
            Coupon_Seller__c oldCS = oldMap != null ? oldMap.get(cs.Id) : new Coupon_Seller__c();
            //LA-26-11-2025-US-0033705: add SET_COUPONSELLER_RT_ID in below criteria
            //MN-05092023-US-0013979: Add SCMC recordtype in below criteria
            if(SET_COUPONSELLER_RT_ID.contains(cs.RecordTypeId) && String.isNotBlank(cs.Coupon_Seller_Stage__c) && isStageChange(cs,oldCS) && COUPON_SELLER_STATUS_SEP_MAPPING.containsKey(cs.Coupon_Seller_Stage__c)){
                if(cs.Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_CONTRACT_NEGOTIATION && cs.Coupon_Type__c == COUPON_SELLER_TYPE_ITEM){
                    cs.Coupon_Seller_Stage_Portal__c = COUPON_SELLER_SEP_STATUS_UPLOAD;
                } else {
                    
                    //LA-26-11-2025-US-0033705: set empty value to seller portal coupon seller status for Master Agreement Seller Record Type and stage Contract Reached or Draft
                    if(cs.RecordTypeId==RT_MASTERAGREEMENTSELLER.Id && cs.Coupon_Seller_Stage__c==COUPON_STAGE_DRAFT){
                        
                        cs.Coupon_Seller_Stage_Portal__c = BLANKVALUE;
                    } else {
                        
                        cs.Coupon_Seller_Stage_Portal__c = COUPON_SELLER_STATUS_SEP_MAPPING.get(cs.Coupon_Seller_Stage__c);
                    }
                    
                }
            }
        }
    }

    /*********************************************************************************************************************************
    @ Method:         isStageChange
    @ Version:        1.0
    @ Author:         Sambath SENG (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0010431 - Create Coupon details view on portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Coupon_Seller__c csNew, Coupon_Seller__c csOld
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  23.5.2022 / Sambath Seng / Created the method
    *********************************************************************************************************************************/
    private static boolean isStageChange(Coupon_Seller__c csNew, Coupon_Seller__c csOld){
        return csOld==null || (csOld != null && csNew.Coupon_Seller_Stage__c != csOld.Coupon_Seller_Stage__c);
    }

    //Comment by Sambath Seng - 29.07.2022 US-0011998 BA want to Exclude from Production
    /*********************************************************************************************************************************
    @ Method:         updateCSStageWhenCouponIsNegoOrRunning
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0011998 - Business Feedback Focus 75 AC3
    @ Parameter:      List<Coupon_Seller__c> newCS
    @ Event:          before insert
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 01.06.2022 / Sambath Seng / Created the method.
    @               : 29.08.2022 / Loumang SENG / US-0012338 - Auto update coupon seller stage if Coupon at Seller Negotiation
    @               : 15.12.2033 / Mony Nou / US-0012734 - [UK] Accessibility Configurations - Cannot deploy before launch
    @               : 11.01.2023 / Mony Nou / US-0012694 - [FR] Accessibility Configurations - Cannot deploy before launch
    @               : 22.02.2023 / Sophal Noch / US-0012801 - Accessibility Configurations
    @               : 02.06.2023 / Sophal Noch / US-0012597 - [IT] Accessibility Configurations - Cannot deploy before launch
    @               : 26.11.2025 / LoumAng SENG / US-0033705 - POP - SP - POP Coupons to be Visible on Portal (Seller Facing)
    *********************************************************************************************************************************/
    public static void updateCSStageWhenCouponIsNegoOrRunning(List<Coupon_Seller__c> newCS){

        Set<Id> cId = new Set<Id>();
        List<Coupon_Seller__c> listCsToUpdate = new List<Coupon_Seller__c>();

        for(Coupon_Seller__c oCS : newCS){
            //Start-LA 30.08.2022 US-0012338(AC2)
            // if(oCS.Is_Coupon_Stage_Nego_Running__c){
            //  oCS.Coupon_Seller_Stage__c = COUPON_SELLER_STAGE_CONTRACT_REACHED;
            // }
            //LA-26-11-2025-US-0033705: Exclude Master and Program Coupon Seller Record Type
            //if(oCS.Coupon__c == null) continue;
            if(oCS.Coupon__c == null || oCS.recordTypeId == RT_PROGRAMCOUPONSELLER.Id || oCS.recordTypeId == RT_MASTERAGREEMENTSELLER.Id) continue;
            cId.add(oCS.Coupon__c);
            listCsToUpdate.add(oCS);
        }

        if(listCsToUpdate.isEmpty()) return;
        
        Map<ID,Coupon__c> mapCoupon = new Map<ID,Coupon__c>([Select Id, Main_Coupon_Site__c from Coupon__c Where Id IN :cId]);

        //MN-15122022-US-0012734 - Key: Main Coupon Site => Stage
        Map<String, String> mSiteCSStage = new Map<String, String> {
            COUPONSITE_DE => COUPON_SELLER_STAGE_CONTRACT_REACHED,
            COUPONSITE_US => COUPON_SELLER_STAGE_CONTRACT_REACHED,
            COUPONSITE_UK => COUPON_SELLER_STAGE_CONTRACT_TARGETED,
            COUPONSITE_FR => COUPON_SELLER_STAGE_CONTRACT_REACHED, //MN-11012023-US-0012694
            COUPONSITE_AU => COUPON_SELLER_STAGE_CONTRACT_REACHED, //SP-22022023-US-0012801
            COUPONSITE_IT => COUPON_SELLER_STAGE_CONTRACT_REACHED  //SP-02062023-US-0012597
        };

        for(Coupon_Seller__c cs : listCsToUpdate){
 
            Coupon__c coupon = mapCoupon.get(cs.Coupon__c);
            
            /* MN-15122022-US-0012734
            if(cs.Is_Coupon_Stage_Nego_Running__c && coupon != null && (coupon.Main_Coupon_Site__c == COUPONSITE_DE || coupon.Main_Coupon_Site__c == COUPONSITE_US)){
                cs.Coupon_Seller_Stage__c = COUPON_SELLER_STAGE_CONTRACT_REACHED;
            }
            */ 

            //MN-15122022-US-0012734
            if (cs.Is_Coupon_Stage_Nego_Running__c && coupon != null && String.isNotBlank(coupon.Main_Coupon_Site__c) && mSiteCSStage.containsKey(coupon.Main_Coupon_Site__c)) {
                cs.Coupon_Seller_Stage__c = mSiteCSStage.get(coupon.Main_Coupon_Site__c);
            }   
            

            

        } //END LA-30.08.2022 US-0012338(AC2)
    }
    
    /*****************************************************************************************************************************
    @ Method:   updateTransFileAccess
    @ Version:  1.0
    @ Author:   Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:  US-0014083 - Change the Coupon Transaction file access
    @ Event:    Before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: List<Coupon_Seller__c> newCS, Map<Id, Coupon_Seller__c> oldMap
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.09.2023 / Sambath Seng / Method Creation
    @               : 25.09.2023 / Sambath Seng / US-0014201 - Coupon transaction file - access change
    *****************************************************************************************************************************/
    public static void updateTransFileAccess(List<Coupon_Seller__c> newCS, Map<Id, Coupon_Seller__c> oldMap)
    {
        Map<Id,String> mapTransFileCSId = new Map<Id,String>();
        Map<Id,String> mapCDCSId = new Map<Id,String>();
        for(Coupon_Seller__c cs : newCS){
            if(cs.Trans_File_SF_ID__c != null && cs.Trans_File_SF_ID__c != oldMap.get(cs.Id).Trans_File_SF_ID__c && SET_CHANGE_FILE_ACCESS_STAGE.contains(cs.Coupon_Seller_Stage__c)){
                mapTransFileCSId.put(cs.Trans_File_SF_ID__c,cs.Id);
            }
        }

        //SB 25.09.2023 US-0014201 Add ContentDocument query and add it to new map
        if(mapTransFileCSId.isEmpty()) return;

        for(ContentDocument cd : [SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE LatestPublishedVersionId IN :mapTransFileCSId.keyset()]){
            mapCDCSId.put(cd.Id,mapTransFileCSId.get(cd.LatestPublishedVersionId));
        }

        if(!mapCDCSId.isEmpty()){

            List<ContentDocumentLink> lstCDLToUpdate = new List<ContentDocumentLink>();
            //SB 25.09.2023 US-0014201 Using new map mapCDCSId
            for(ContentDocumentLink cdl : [SELECT LinkedEntityId, ContentDocumentId, Visibility FROM ContentDocumentLink WHERE ContentDocumentId IN :mapCDCSId.keySet()]){
                if(cdl.LinkedEntityId == mapCDCSId.get(cdl.ContentDocumentId) && cdl.Visibility != 'AllUsers'){
                    cdl.Visibility = 'AllUsers';
                    lstCDLToUpdate.add(cdl);
                }
            }

            if(!lstCDLToUpdate.isEmpty()){
                update lstCDLToUpdate;
            }
        }

    }

    /*****************************************************************************************************************************
    @ Method:   updateCoInvestFileAccess
    @ Version:  1.0
    @ Author:   Leon Morocki
    @ Purpose:  US-0033470 - POP - SP - Download Item file attached to Coupon Seller record
    @ Event:    Before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: List<Coupon_Seller__c> newCS, Map<Id, Coupon_Seller__c> oldMap
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.12.2025 / Leon Morocki / Method Creation
    *****************************************************************************************************************************/
    public static void updateCoInvestFileAccess(List<Coupon_Seller__c> newCS, Map<Id, Coupon_Seller__c> oldMap)
    {
        Map<Id,String> mapCoInvestFileCSId = new Map<Id,String>();
        Map<Id,String> mapCDCSId = new Map<Id,String>();
        for(Coupon_Seller__c cs : newCS){
            if(cs.CoInvestFileSFID__c != null && cs.CoInvestFileSFID__c != oldMap.get(cs.Id).CoInvestFileSFID__c){
                mapCoInvestFileCSId.put(cs.CoInvestFileSFID__c,cs.Id);
            }
        }

        if(mapCoInvestFileCSId.isEmpty()) return;

        String contentVersionQuery = 'SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :mapCoInvestFileCSId';
        Map<String, Object> contentVersionBindVars = new Map<String, Object> {'mapCoInvestFileCSId' => mapCoInvestFileCSId.keySet()};
        List<ContentVersion> contentVersions = (List<ContentVersion>) ApexSafe.query().secCheck(false).doQuery(contentVersionQuery, contentVersionBindVars);

        for(ContentVersion cv : contentVersions){
            mapCDCSId.put(cv.ContentDocumentId,mapCoInvestFileCSId.get(cv.Id));
        }

        if(!mapCDCSId.isEmpty()){

            List<ContentDocumentLink> lstCDLToUpdate = new List<ContentDocumentLink>();
            String contentDocumentLinkQuery = 'SELECT LinkedEntityId, ContentDocumentId, Visibility FROM ContentDocumentLink WHERE ContentDocumentId IN :mapCDCSId';
            Map<String, Object> contentDocumentLinkBindVars = new Map<String, Object> {'mapCDCSId' => mapCDCSId.keySet()};
            List<ContentDocumentLink> contentDocumentLinks = (List<ContentDocumentLink>) ApexSafe.query().secCheck(false).doQuery(contentDocumentLinkQuery, contentDocumentLinkBindVars);

            for(ContentDocumentLink cdl : contentDocumentLinks){
                if(cdl.LinkedEntityId == mapCDCSId.get(cdl.ContentDocumentId) && cdl.Visibility != 'AllUsers'){
                    cdl.Visibility = 'AllUsers';
                    lstCDLToUpdate.add(cdl);
                }
            }

            if(!lstCDLToUpdate.isEmpty()){
                ApexSafe.dml().secCheck(false).doUpdate(lstCDLToUpdate, true);
            }
        }

    }

    /*****************************************************************************************************************************
    @ Method:   updateEligibility
    @ Version:  1.0
    @ Author:   Loumang Seng (loumang.seng@gaea-sys.com)
    @ Purpose:  US-0014956 - Auto enable SP eligibility (AC3 & AC4)
    @ Event:    After update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: List<Coupon_Seller__c> newCS, Map<Id, Coupon_Seller__c> oldMap
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.04.2024 / Loumang Seng / Method Creation
    @               : 09.05.2024 / Loumang Seng / US-0015268 - Auto enable SP eligibility for Item Based Coupons
    *****************************************************************************************************************************/
    public static void updateSPEligibility(List<Coupon_Seller__c> newCS, Map<Id, Coupon_Seller__c> oldMap)
    {
        Map<Id, String> mapSellerIdToSPDomain = new Map<Id,String>();
        
        for(Coupon_Seller__c cs : newCS){

            Coupon_Seller__c oldCs = oldMap.get(cs.Id);

            if(cs.Coupon_Seller_Stage__c != oldCs.Coupon_Seller_Stage__c && 
               ( (SET_INCLUDE_RT.contains(cs.RecordTypeId) && cs.Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_CONTRACT_SEND) ||
                 (cs.Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_CONTRACT_NEGOTIATION && cs.Coupon_Type__c == COUPON_SELLER_TYPE_ITEM) )) //LA-09.05.2024 US-0015268: Add condition for Item Based Coupons when stage changed to Negotiation
             {

                if(cs.Seller__c == null) continue;

                if(String.isNotBlank(cs.Main_Coupon_Site__c)){
                    String mainDomain = SP_MAINDOMAIN_MAPPING.containsKey(cs.Main_Coupon_Site__c)?SP_MAINDOMAIN_MAPPING.get(cs.Main_Coupon_Site__c):SP_MAINDOMAIN_MAPPING.get(COUPONSITE_DE);
                    mapSellerIdToSPDomain.put(cs.Seller__c, mainDomain);                    
                }
                
                

            }
        }

        if(!mapSellerIdToSPDomain.isEmpty() ){

            Set<Id> setAccId = mapSellerIdToSPDomain.keySet();
            Map<String, Object> mapBind = new Map<String, Object> {'setAccId' => setAccId, 'SP_COUPON_FULL_ACCESS' => SP_COUPON_FULL_ACCESS};
            List<Account> listSellers =(List<Account>) ApexSafe.query().secCheck(false).doQuery(ACCOUNT_QUERY,mapBind);
            List<Account> listSellerToUpdate = new List<Account>();

            for(Account seller : listSellers){

                if(seller.SP_Coupons__c != SP_COUPON_FULL_ACCESS){
                    seller.SP_Coupons__c = SP_COUPON_FULL_ACCESS;
                }

                if(seller.SP_Main_Domain__c == null && mapSellerIdToSPDomain.containsKey(seller.Id)){
                    seller.SP_Main_Domain__c = mapSellerIdToSPDomain.get(seller.id);
                }
                
                listSellerToUpdate.add(seller);
            }

            if(!listSellerToUpdate.isEmpty()){
                Database.SaveResult[] results = ApexSafe.dml().secCheck(false).doUpdate(listSellerToUpdate,true);
                List<Database.Error> dbError = new List<Database.Error>();
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess() && !Test.isRunningTest()){ dbError.addAll(result.getErrors()); }
                }
                if (!dbError.isEmpty()) EBH_ApexLogger.logError(dbError, 'CouponSellerTriggerHandler','updateSPEligibility');
            }
            
        }

    }

    /*********************************************************************************************************************************
    @ Method:         autoUpdateProgramCouponSellersWhenMasterContractSigned
    @ Version:        1.0
    @ Author:         Leon Morocki / GitHub Copilot
    @ Purpose:        US-0033151 AC4 - Auto-update Program Coupon Sellers when Master Agreement Contract is signed
    @ Event:          after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<Coupon_Seller__c> lstNewCS, Map<Id,Coupon_Seller__c> mapOldCS
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  TDD implementation for US-0033151 AC4 requirement
    *********************************************************************************************************************************/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static void autoUpdateProgramCouponSellersWhenMasterContractSigned(List<Coupon_Seller__c> lstNewCS, Map<Id,Coupon_Seller__c> mapOldCS) {
        try {
            Set<Id> potentialMasterAgreementIds = new Set<Id>();
            
            // Find Coupon Sellers that changed to Contract Signed
            for(Coupon_Seller__c newCS : lstNewCS) {
                Coupon_Seller__c oldCS = mapOldCS?.get(newCS.Id);
                
                // Check if stage changed to Contract Signed
                if(oldCS != null 
                   && newCS.Coupon_Seller_Stage__c == EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED 
                   && oldCS.Coupon_Seller_Stage__c != EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED) {
                    potentialMasterAgreementIds.add(newCS.Id);
                }
            }
            
            if(!potentialMasterAgreementIds.isEmpty()) {
                // Query to verify which ones are Master Agreement Coupon Sellers
                List<Coupon_Seller__c> masterAgreementCouponSellers = [
                    SELECT Id, Coupon__c, Coupon__r.RecordTypeId
                    FROM Coupon_Seller__c 
                    WHERE Id IN :potentialMasterAgreementIds
                    AND Coupon__r.RecordTypeId = :Schema.SObjectType.Coupon__c.getRecordTypeInfosByDeveloperName().get(EBH_ConstantsUtility.COUPON_MASTER_RECORDTYPE).getRecordTypeId()
                ];
                
                Set<Id> confirmedMasterAgreementIds = new Set<Id>();
                for(Coupon_Seller__c masterCS : masterAgreementCouponSellers) {
                    confirmedMasterAgreementIds.add(masterCS.Id);
                }
                
                if(!confirmedMasterAgreementIds.isEmpty()) {
                    // Find all Program Coupon Sellers linked to these Master Agreements
                    List<Coupon_Seller__c> programCouponSellersToUpdate = [
                        SELECT Id, Coupon_Seller_Stage__c, Master_Agreement_Coupon_Seller__c
                        FROM Coupon_Seller__c 
                        WHERE Master_Agreement_Coupon_Seller__c IN :confirmedMasterAgreementIds
                        AND Coupon_Seller_Stage__c != :EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED
                    ];
                    
                    // Update their stages to Contract Signed
                    for(Coupon_Seller__c programCS : programCouponSellersToUpdate) {
                        programCS.Coupon_Seller_Stage__c = COUPON_SELLER_STAGE_OPTED_IN; // CSP-16102025:US-0033614
                    }

                    if(!programCouponSellersToUpdate.isEmpty()) {
                        ApexSafe.dml().secCheck(false).doUpdate(programCouponSellersToUpdate,true);
                    }
                }
            }
        } catch(Exception e) {
            System.debug('Error in autoUpdateProgramCouponSellersWhenMasterContractSigned: ' + e.getMessage());
        }
    }
    

    /*****************************************************************************************************************************
    @ Method:   populateMasterAgreementCouponSellerField
    @ Version:  1.0
    @ Author:   Loumang Seng (loumang.seng@gaea-sys.com)
    @ Purpose:  US-0033512 - POP - Create Master Coupon Seller Automation Trigger
    @ Event:    Before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: List<Coupon_Seller__c> listNewCS
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.12.2025 / Loumang SENG  / Method Creation
    *****************************************************************************************************************************/
    public static void populateMasterAgreementCouponSellerField(List<Coupon_Seller__c> listNewCS) {

        Set<Id> setSellerIds = new Set<Id>();
        Set<Id> setProgramCIds = new Set<Id>();
        List<Coupon_Seller__c> listProgramCS = new List<Coupon_Seller__c>();
        
        for(Coupon_Seller__c cs : listNewCS) {

            if(cs.RecordTypeId == RT_PROGRAMCOUPONSELLER.Id && cs.Seller__c != null && cs.Coupon__c != null && cs.CoInvestFileSFID__c != null) {
                setSellerIds.add(cs.Seller__c);
                setProgramCIds.add(cs.Coupon__c);
                listProgramCS.add(cs);
            }
        }
        if(!setSellerIds.isEmpty() && !setProgramCIds.isEmpty() && !listProgramCS.isEmpty()) {

            // Get Program Coupon records to retrieve Master Coupon Ids
            Set<Id> setMasterCIds = new Set<Id>();
            Map<Id, Id> mapProgramCIdToMasterCId = new Map<Id, Id>();
            String sWhereCoupon = ' WHERE Id IN :setProgramCIds';
            List<Coupon__c> listProgramCoupon = (List<Coupon__c>) ApexSafe.query().secCheck(false).doQuery(QUERY_COUPON+sWhereCoupon,new Map<String, Object> {'setProgramCIds' => setProgramCIds});

            for(Coupon__c coupon : listProgramCoupon) {
                
                if(coupon.Master_Coupon__c != null) {
                    setMasterCIds.add(coupon.Master_Coupon__c);
                    mapProgramCIdToMasterCId.put(coupon.Id, coupon.Master_Coupon__c);
                }
            }
            if(!setMasterCIds.isEmpty()){

                // Get Master Agreement Coupon Seller records via setSellerIds and setMasterCIds
                Id masterRTId = RT_MASTERAGREEMENTSELLER.Id;
                String sWhereCS = ' WHERE Seller__c IN :setSellerIds AND Coupon__c IN:setMasterCIds AND RecordTypeId = :masterRTId';
                List<Coupon_Seller__c> listMasterCS = (List<Coupon_Seller__c>) ApexSafe.query().secCheck(false).doQuery(SOQL_COUPON_SELLER+sWhereCS,new Map<String, Object> {'setSellerIds' => setSellerIds, 'setMasterCIds' => setMasterCIds,'masterRTId' => masterRTId});
                Map<String, Coupon_Seller__c> mapSellerMasterCouponToMasterCS = new Map<String, Coupon_Seller__c>();

                // Mapping seller + master coupon combination to master agreement coupon seller id
                for(Coupon_Seller__c masterCS : listMasterCS) {

                    String mappingKey = masterCS.Seller__c + '_' + masterCS.Coupon__c;
                    mapSellerMasterCouponToMasterCS.put(mappingKey, masterCS);
                }

                // Track missing Master Agreement Coupon Sellers that need to be created
                List<Coupon_Seller__c> listMasterCSToCreate = new List<Coupon_Seller__c>();
                List<Coupon_Seller__c> listProgramCSNoMasterCS = new List<Coupon_Seller__c>();

                // Populate Master Agreement Coupon Seller on Program Coupon Seller field
                for(Coupon_Seller__c programCS : listProgramCS) {
                    
                    // Get the master coupon id for this program coupon
                    Id masterCouponId = mapProgramCIdToMasterCId.get(programCS.Coupon__c);
                    
                    if(masterCouponId != null) {

                        String mappingKey = programCS.Seller__c + '_' + masterCouponId;
                        if(mapSellerMasterCouponToMasterCS.containsKey(mappingKey)){

                            if(mapSellerMasterCouponToMasterCS.get(mappingKey).Coupon_Seller_Stage__c == COUPON_SELLER_STAGE_CONTRACT_SIGNED) {
                                // If Master Agreement Coupon Seller is Opted In, map it directly
                                programCS.Coupon_Seller_Stage__c = COUPON_SELLER_STAGE_OPTED_IN;
                                programCS.Coupon_Seller_Stage_Portal__c = COUPON_SELLER_STAGE_OPTED_IN;

                            }
                            // Master Agreement Coupon Seller exists, populate the lookup field
                            programCS.Master_Agreement_Coupon_Seller__c = mapSellerMasterCouponToMasterCS.get(mappingKey).Id;

                        } else {

                            // Master Agreement Coupon Seller doesn't exist, create new one
                            //Boolean isOptedIn = (programCS.Coupon_Seller_Stage__c==COUPON_SELLER_STAGE_OPTED_IN);
                            Coupon_Seller__c newMasterCS = setMasterCouponSeller(programCS.Seller__c,masterCouponId);
                            listMasterCSToCreate.add(newMasterCS);
                            listProgramCSNoMasterCS.add(programCS);
                        }
                    }
                }

                // Insert new Master Agreement Coupon Seller records and populate the lookup field on Program Coupon Sellers
                if(!listMasterCSToCreate.isEmpty() && !listProgramCSNoMasterCS.isEmpty()) {
                    try {

                        List<Database.SaveResult> listMasterCSResult = ApexSafe.dml().secCheck(false).doInsert(listMasterCSToCreate, true);
                        List<Database.Error> dbError = new List<Database.Error>();
                        Map<String, Id> mapSellerToNewMasterCSId = new Map<String, Id>();
                        // Map the successfully created Master Agreement Coupon Sellers back to Program Coupon Sellers
                        for(Integer i = 0; i < listMasterCSResult.size(); i++) {

                            if(listMasterCSResult[i].isSuccess()) {

                                Coupon_Seller__c createdMasterCS = listMasterCSToCreate[i];
                                String keySellerMC = createdMasterCS.Seller__c + '_' + createdMasterCS.Coupon__c;
                                mapSellerToNewMasterCSId.put(keySellerMC, listMasterCSResult[i].getId());

                            }else { dbError.addAll(listMasterCSResult[i].getErrors());}
                        }

                        if (!dbError.isEmpty()) { EBH_ApexLogger.logError(dbError, 'CouponSellerTriggerHandler','populateMasterAgreementCouponSellerField'); }

                        // Now populate the lookup field for Program Coupon Sellers that didn't have existing Master Agreement records
                        for(Coupon_Seller__c programCS : listProgramCSNoMasterCS) {

                            if(programCS.Master_Agreement_Coupon_Seller__c == null) {

                                Id masterCouponId = mapProgramCIdToMasterCId.get(programCS.Coupon__c);
                                if(masterCouponId != null) {

                                    String keySellerMC = programCS.Seller__c + '_' + masterCouponId;

                                    if(mapSellerToNewMasterCSId.containsKey(keySellerMC)){

                                        programCS.Master_Agreement_Coupon_Seller__c = mapSellerToNewMasterCSId.get(keySellerMC);
                                    }
                                }
                            }
                        }
                    } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, 'CouponSellerTriggerHandler','populateMasterAgreementCouponSellerField');}
                }
            }
        }

    }

    // This method is used to set Master Agreement Coupon Seller data
    private static Coupon_Seller__c setMasterCouponSeller(Id sellerId, Id masterCouponId) {

        Coupon_Seller__c newMasterCS = new Coupon_Seller__c();
        newMasterCS.RecordTypeId = RT_MASTERAGREEMENTSELLER.Id;
        newMasterCS.Seller__c = sellerId;
        newMasterCS.Coupon__c = masterCouponId;
        newMasterCS.Coupon_Seller_Stage__c = COUPON_SELLER_STAGE_CONTRACT_SEND;
        //newMasterCS.Coupon_Seller_Stage__c = isOptedIn?COUPON_SELLER_STAGE_CONTRACT_SEND:COUPON_STAGE_DRAFT;

        return newMasterCS;
        
    }
    

}