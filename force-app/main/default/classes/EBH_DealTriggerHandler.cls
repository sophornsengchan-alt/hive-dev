/** - vadhanak.voun@gaea-sys.com 25/09/2017
- #12536
- summary: For the trigger we can add additional criteria to limit the number of recalculations. 
E.g. the job only has to be executed when one of the following fields is changed: EBH_DealStartDate__c, Deal_Price__c, EBH_Status__c
Only Deals_Budget_Month__c records have to be re-calculated where:
+ Month(Deals_Budget_Month__c.Month__c)=Month(EBH_Deal__c.EBH_DealStartDate__c)  AND
+ Year(Deals_Budget_Month__c.Month__c)=Year(EBH_Deal__c.EBH_DealStartDate__c) AND
+ Deals_Budget_Month__c.Deals_Budget__r.Vertical__c=EBH_Deal__c.Vertical__c

It should trigger when deals get created, updated or deleted.

Formula:
Target Field                                Source Field                    Filter Criteria
Deals_Budget_Month__c.Subsidy_Paid__c       EBH_Deal__c.Subsidy_Final__c        Month(Deals_Budget_Month__c.Month__c)=Month(EBH_Deal__c.EBH_DealStartDate__c) AND Year(Deals_Budget_Month__c.Month__c)=Year(EBH_Deal__c.EBH_DealStartDate__c) AND Deals_Budget_Month__c.Deals_Budget__r.Vertical__c=EBH_Deal__c.Vertical__c AND (EBH_Deal__c.EBH_Status__c = "Ready for Payment" OR "Paid")
Deals_Budget_Month__c.Subsidy_Forecast__c   EBH_Deal__c.Subsidy_Forecast__c     Month(Deals_Budget_Month__c.Month__c)=Month(EBH_Deal__c.EBH_DealStartDate__c) AND Year(Deals_Budget_Month__c.Month__c)=Year(EBH_Deal__c.EBH_DealStartDate__c) AND Deals_Budget_Month__c.Deals_Budget__r.Vertical__c=EBH_Deal__c.Vertical__c AND EBH_Deal__c.EBH_Status__c = "Executed"
Deals_Budget_Month__c.Subsidy_Max__c        EBH_Deal__c.Subsidy_Max__c          Month(Deals_Budget_Month__c.Month__c)=Month(EBH_Deal__c.EBH_DealStartDate__c) AND Year(Deals_Budget_Month__c.Month__c)=Year(EBH_Deal__c.EBH_DealStartDate__c) AND Deals_Budget_Month__c.Deals_Budget__r.Vertical__c=EBH_Deal__c.Vertical__c AND (EBH_Deal__c.EBH_Status__c = " Planned" OR "Deal Agreed" OR "Running")
------------------------------------------------------------------------------------------------------------------------------------------------
-03/10/2017:NK: updated new calculation (v2):
Target Field                                Source Field                    Filter Criteria
Deals_Budget_Month__c.Subsidy_Paid__c       EBH_Deal__c.Subsidy_Final__c        Month(Deals_Budget_Month__c.Month__c)=Month(EBH_Deal__c.EBH_DealStartDate__c) AND Year(Deals_Budget_Month__c.Month__c)=Year(EBH_Deal__c.EBH_DealStartDate__c) AND Deals_Budget_Month__c.Deals_Budget__r.Vertical__c=EBH_Deal__c.Vertical__c AND (EBH_Deal__c.EBH_Status__c = "Paid")
Deals_Budget_Month__c.Subsidy_Invoiced__c   EBH_Deal__c.Subsidy_Final__c        Month(Deals_Budget_Month__c.Month__c)=Month(EBH_Deal__c.EBH_DealStartDate__c) AND Year(Deals_Budget_Month__c.Month__c)=Year(EBH_Deal__c.EBH_DealStartDate__c) AND Deals_Budget_Month__c.Deals_Budget__r.Vertical__c=EBH_Deal__c.Vertical__c AND (EBH_Deal__c.EBH_Status__c = "Ready for Payment")
Deals_Budget_Month__c.Subsidy_Forecast__c   EBH_Deal__c.Subsidy_Forecast__c     Month(Deals_Budget_Month__c.Month__c)=Month(EBH_Deal__c.EBH_DealStartDate__c) AND Year(Deals_Budget_Month__c.Month__c)=Year(EBH_Deal__c.EBH_DealStartDate__c) AND Deals_Budget_Month__c.Deals_Budget__r.Vertical__c=EBH_Deal__c.Vertical__c AND EBH_Deal__c.EBH_Status__c = "Executed"
Deals_Budget_Month__c.Subsidy_Max__c        EBH_Deal__c.Subsidy_Max__c          Month(Deals_Budget_Month__c.Month__c)=Month(EBH_Deal__c.EBH_DealStartDate__c) AND Year(Deals_Budget_Month__c.Month__c)=Year(EBH_Deal__c.EBH_DealStartDate__c) AND Deals_Budget_Month__c.Deals_Budget__r.Vertical__c=EBH_Deal__c.Vertical__c AND (EBH_Deal__c.EBH_Status__c = " Planned" OR "Deal Agreed" OR "Running")

Changes:
- 03/10/2017:NK:
The sum from EBH_Deal__c.Subsidy_Final__c into Deals_Budget_Month__c.Subsidy_Paid__c has to be split into two fields depending on the EBH_Status__c criteria.
Target Field                                Source Field                    Filter Criteria
Deals_Budget_Month__c.Subsidy_Paid__c       EBH_Deal__c.Subsidy_Final__c        Month(Deals_Budget_Month__c.Month__c)=Month(EBH_Deal__c.EBH_DealStartDate__c) AND Year(Deals_Budget_Month__c.Month__c)=Year(EBH_Deal__c.EBH_DealStartDate__c) AND Deals_Budget_Month__c.Deals_Budget__r.Vertical__c=EBH_Deal__c.Vertical__c AND (EBH_Deal__c.EBH_Status__c = "Paid")
Deals_Budget_Month__c.Subsidy_Invoiced__c   EBH_Deal__c.Subsidy_Final__c        Month(Deals_Budget_Month__c.Month__c)=Month(EBH_Deal__c.EBH_DealStartDate__c) AND Year(Deals_Budget_Month__c.Month__c)=Year(EBH_Deal__c.EBH_DealStartDate__c) AND Deals_Budget_Month__c.Deals_Budget__r.Vertical__c=EBH_Deal__c.Vertical__c AND (EBH_Deal__c.EBH_Status__c = "Ready for Payment")

- 08/10/2017:NK:
Requirement:
1) When a deal record gets saved and EBH_Status__c = "Planned" or "Deal Agreed" or "Running" or "Executed" or "Ready for Payment" or "Paid" 
find Deal_Slot_Allocation__c record where Deal_Slot_Allocation__c.UID__c = EBH_Deal__c.UID__c and put Deal_Slot_Allocation__c.Id into EBH_Deal__c.Deal_Slot_Allocation__c (Lookup). If you don't get a result just skip.
2) When a deal record gets saved and EBH_Status__c = "New" or "Negotiating" or "Rejected" change EBH_Deal__c.Deal_Slot_Allocation__c to null

- 17/10/2017:NK:
+ one small addition for the trigger: for the deals budget calculation it should also trigger when the field Quantity__c on the deals record is changed.
+ - Adslot allocation for triggering: EBH_Status__c, Deal_Format__c, EBH_DealStartDate__c

- 02/04/2018: NK: added method handleAvailableSlot 
+ Deal insert/delete/update/undelete: Then the field "Open Slots Available" will update to = "Slots" - (# of Deals related to the Deal Slot Allocation that are NOT in status "New", "Negotiating", or "Rejected")

- 09/09/2022: TH: updated on methode checkDuplicate : US-0012281 - Validation and upload of Deals
+ Add condition to specific recordtype : PM_Dea
/**
 * 
 * Commented 3 methods in order to make the trigger work
 * commented sumdeal and sumdealbudget / sumdealbudgetmonth
 
- 17/10/2022/ Sovantheany Dim / US-0012629 - Hide Standard Deals (V1 deals) on the Seller Portal for AU Seller
- 09/01/2023 / Bora Chhorn / US-0013053 - Deal Price should be stamped on Seller Price for Un-Sub Deals
- 02/02/2023 / Sovantheany dim / US-0013020 - Remove negotiating picklist from the Deal V1 record type
- 13/03/2023 / Mony Nou / US-0012628 - Seller Deal Cancellation - on Seller Portal

- 14/03/2023 / Bora Chhorn / US-0013086 - Hide Deal V1 for AU, IT and FR Sellers
- 31/03/2023 / Sovantheany Dim / US-0013466 - Validation of PM Deals check duing upload
- 26/05/3034 / Sambath Seng / US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
- 31.08.2023 / SRONG TIN / US-0014018 - 2 - IT Launch - Deal V3 default status should be Processing
- 28.09.2023 / SRONG TIN / US-0012499 - Processed deals shouldn't be deleted
- 08.01.2024/ vadhanak voun/ US-0014643 - Hyperforce - Remove hard-coded instance references
- 12.01.2024 / Sambath Seng / US-0013136 - Seller_Portal_Status__c - Deprecate
- 21/03/2025 / Vimean Heng / US-0016717 - Contract Amendment Process - No Change in Subsidy
- 31.03.2025 / Vimean Heng / US-0016745 - Deals upload and Management - Testing Feedback
*/



public without sharing class EBH_DealTriggerHandler {

    //NK:20/10/2010:US-0008130
    public static boolean FROM_APPROVE_FORM = false;
    private static Set<String> IGNORE_CHECK_FROM_APPROVE =new Set<String>{'Seller_Email__c','Comment_from_Seller__c','Seller_accepted_from__c','Seller_Name__c','Seller_Response_Time__c'};

    /************************************* CONSTANT DEFINITION *************************************************/
    
    public static final string EMAILTEMPLATE_DE_WITH_SUBSIDY = 'DE_EBH_MassAcceptanceofDealswithSubsidy';
    public static final string EMAILTEMPLATE_DE_WITHOUT_SUBSIDY = 'DE_EBH_MassAcceptanceofDealswithoutSubsidy';
    public static final string EMAILTEMPLATE_UK_WITH_SUBSIDY = 'UK_EBH_MassAcceptanceofDealswithSubsidy';
    public static final string EMAILTEMPLATE_UK_WITHOUT_SUBSIDY = 'UK_EBH_MassAcceptanceofDealswithoutSubsidy';
    public static final string EMAILTEMPLATE_FR_WITH_SUBSIDY = 'FR_EBH_MassAcceptanceofDealswithSubsidy';
    public static final string EMAILTEMPLATE_FR_WITHOUT_SUBSIDY = 'FR_EBH_MassAcceptanceofDealswithoutSubsidy';
    public static final string EMAILTEMPLATE_IT_WITH_SUBSIDY = 'IT_EBH_MassAcceptanceofDealswithSubsidy';
    public static final string EMAILTEMPLATE_IT_WITHOUT_SUBSIDY = 'IT_EBH_MassAcceptanceofDealswithoutSubsidy';
    public static final string EMAILTEMPLATE_ES_WITH_SUBSIDY = 'ES_EBH_MassAcceptanceofDealswithSubsidy';
    public static final string EMAILTEMPLATE_ES_WITHOUT_SUBSIDY = 'ES_EBH_MassAcceptanceofDealswithoutSubsidy';
    public static final string EMAILTEMPLATE_AU_WITH_SUBSIDY = 'AU_Deal_Template_with_Subsidy';
    public static final string EMAILTEMPLATE_AU_WITHOUT_SUBSIDY = 'AU_Deal_Template_without_Subsidy';
    public static final string EMAILTEMPLATE_DE_SELLER_INVITE = 'DE_Deal_Seller_Invite'; //SB 19/10/2021 US-0010595
    // SRONG TIN - 17/03/2022 : US-0011338 - System allowing Deals with same item ID & overlapping dates
    public static Boolean isFromBulkUpload_DE = false; 
    public static Boolean isFromUpdateDealToPlannedList = false; 
    public static Boolean isFromUpdateDealToPlanned_Duplicated = false; 
    private static final string DRC_STANDARD_COMPAIGN = 'Deal_Campaign_V1';
    //TH: 07/10/2020 : US-0008088 - [US]* Bulk Creation of Deal Records from CSV Upload
	//public static final string DEAL_SOQL = 'SELECT EBH_eBayItemID__c, RecordTypeId, EBH_DealStartDate__c, EBH_DealEndDate__c FROM EBH_Deal__c ';
    public final static String DEAL_SOQL = 'Select SellerVATNumber__c,YourFundingAmountPerUnit__c,SellerAddress__c,RecordTypeId,EBH_MarketingTitle__c,EBH_CommentfromeBaySourcer__c,Subsidy_Planned_Gross__c,EBH_SellerPrice__c,CompanyName__c,EBH_BusinessName__r.Name, EBH_BusinessName__r.ParentId,EBH_BusinessName__r.EBH_ParentAccount__c,EBH_BusinessName__r.EBH_VATNumber__c,EBH_BusinessName__r.Parent.EBH_BillingStreet__c,EBH_BusinessName__r.Parent.EBH_BillingCountry__c,EBH_BusinessName__r.Parent.EBH_BillingPostalCode__c,EBH_BusinessName__r.Parent.EBH_BillingCity__c,EBH_MaximumPurchases__c, EBH_Quantity__c,EBH_RRPWASPrice__c,EBH_DealPrice__c,EBH_EAN__c,Additional_Terms_Override_Of_Agreement__c, Shipping_Rate_Funding__c,EBH_BusinessName__c, EBH_DealStartTime__c, EBH_DealEndTime__c, EBH_SpotlightCategory__r.Active__c,EBH_SpotlightCategory__c,EBH_SpotlightCategory__r.Name,NumberOfDaysSinceDealEnd__c,EBH_Status__c,Id,Owner.Email,EBH_SellerEmail__c,VAT_N__c,Subsidy_Final_Net__c,EBH_Subsidy__c,EBH_Payout_SI_calc__c,EBH_LocalDealFormat__c,EBH_eBayItemID__c,EBH_ProductTitle__c,EBH_DealSiteId__c,EBH_DealStartDate__c,EBH_DealEndDate__c,EBH_StartDateMonthYear__c,EBH_Vertical__c, Subsidy_Running__c, EBH_SubsidyForecast__c, EBH_SubsidyFinal__c, EBH_SubsidyMax__c From EBH_Deal__c ';
	//end US-0008088
	
    // define mapping country and subsidy to email template name
    public static final Map<String,String> mapDealEmailTemplates = new Map<String,String>{
        '77_true'=> EMAILTEMPLATE_DE_WITH_SUBSIDY, 
        '77_false'=> EMAILTEMPLATE_DE_WITHOUT_SUBSIDY,
        '77_Seller Invite'=> EMAILTEMPLATE_DE_SELLER_INVITE, //SB 19/10/2021 US-0010595
        '3_true'=> EMAILTEMPLATE_UK_WITH_SUBSIDY, 
        '3_false'=> EMAILTEMPLATE_UK_WITHOUT_SUBSIDY,
        '71_true'=> EMAILTEMPLATE_FR_WITH_SUBSIDY, 
        '71_false'=> EMAILTEMPLATE_FR_WITHOUT_SUBSIDY,
        '101_true'=> EMAILTEMPLATE_IT_WITH_SUBSIDY,
        '101_false'=> EMAILTEMPLATE_IT_WITHOUT_SUBSIDY,
        '186_true'=> EMAILTEMPLATE_ES_WITH_SUBSIDY, 
        '186_false'=> EMAILTEMPLATE_ES_WITHOUT_SUBSIDY,
        '15_true'=> EMAILTEMPLATE_AU_WITH_SUBSIDY, 
        '15_false'=> EMAILTEMPLATE_AU_WITHOUT_SUBSIDY
    };

    // 16.03.2021 / Acmatac SEING / US-0009296
    public final static String ADMIN_PROFILE_ID = '00e6A000000HNzwQAG';
    public final static String ADMIN_PRIVILEGE_PROFILE_ID = '00e3u000000S5pPAAS';
    public static final string DEAL_STATUS_PLANNED = 'Planned';
    // END US-0009296

    // US-0009563 Acmatac 19/05/2021
    public static final String DEAL_QUEUE_ID= '00G6A000000RndBUAS';
    public static Id STANDARD_DEAL_RTID = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V1').Id;
    public static Id NA_DEAL_RTID = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id;
    // END US-0009563

    // US-0009558 Acmatac 25/05/2021
    private static Map<String, Schema.DescribeFieldResult> mapFieldResult;
    // END US-0009558

    // US-0010019 Mony 06/09/2021
    private final static String NA_DEAL_LOCK_ERROR_MSG = 'Amendment Deal is locked while in Status New.';
    private final static String DEAL_LOCK_ERROR_MSG = 'Deal is locked while in Negotiating.'; //MN-06092021-Moved from EBH_ConstantsUtility.cls
    // END US-0010019 

    /************************************ END OF CONSTANT DEFINITION*******************************************/
    
    static Set<String> AVAIL_STATUS = new Set<String>();//{'Ready for Payment','Paid','Executed','Planned','Deal Agreed','Running'}; 
    static Set<String> STATUS_SLOT_ALLOC_NULL = new Set<String>();//{'New','Negotiating','Rejected'};

    public static Id NA_UNSUB_DEAL_RTID = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V3').Id;// SRONG TIN 09-July-2021, US-0009650
    public static Id PM_DEAL_RTID = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'PM_Deal').Id;//TH:US-0012281 :08/09/2022

    public final static String KEY_STATUS_FINAL = 's_final';
    public final static String KEY_STATUS_INVOICED = 's_invoiced';
    public final static String KEY_STATUS_FORECAST = 's_forecast';
    public final static String KEY_STATUS_MAX = 's_max';
    public static Boolean UPDATE_STATUS_SYS = false;

    public static final string NA_DEAL_RECORDTYPE_API_NAME = 'Deal_V2';

    static Map<String,String>  MAP_STATUS_TYPE  = new Map<String,String>();
    //{
    //'Paid'=>KEY_STATUS_FINAL,
    //'Ready for Payment'=>KEY_STATUS_INVOICED,
    //'Executed'=>KEY_STATUS_FORECAST,
    //'Planned'=>KEY_STATUS_MAX,'Deal Agreed'=>KEY_STATUS_MAX,'Running'=>KEY_STATUS_MAX
    //};

    public static Deal_Timezone__c dealTimezone = Deal_Timezone__c.getInstance();
    private static final Set<String> PROFILE_CAN_UPDATE_DEALS = new Set<String> {'System Administrator','System Administrator - Limited Privileges'};
    private static final Set<String> STATUS_ALLOW_TO_CANCEL = new Set<String>{'Seller Approved','Completed','Running'};
    public static Set<String> sStatus = new Set<String>{'Expired','In Approval','Internally Approved','Sent to Seller','Seller Approved','Running','Completed'};
    public static Set<String> fieldDealPrice = new Set<String>{'EBH_DealPrice__c','EBH_SellerPrice__c','EBH_Quantity__c'};
    public static Set<String> fieldnames = new Set<String>{'EBH_BusinessName__c','EBH_ProductTitle__c','EBH_Vertical__c','EBH_DealStartDate__c','EBH_SoldItemsForecast__c'};
    public static final String STATUS_IN_REVISION = 'In Revision';
    private final static Set<String> SET_STATUS_APPROVED_REJECTED = new Set<String>{'Internally Approved','Internally Rejected'};
    
    //Start-SB 19/10/2021 US-0010595
    private static final string DEAL_STATUS_SELLERINVITE = 'Seller Invite';
    private static final String SITE_DE = '77';
    //End-SB 19/10/2021 US-0010595
    
    //public static final String DEAL_STATUS_PLANNED = 'Planned';
    public static final String DEAL_STATUS_DEAL_AGREED = 'Deal Agreed';
    public static final String DEAL_STATUS_RUNNING = 'Running';
    public static final String DEAL_STATUS_EXECUTED = 'Executed';
    public static final String DEAL_STATUS_REJECTED = 'Rejected';
    public static final String DEAL_STATUS_IN_AMENDMENT = 'In Amendment';
    public static final String DEAL_STATUS_VERIFY_INVOICE = 'Verify Invoice';
    public static final String DEAL_STATUS_VERIFY_STATEMENT = 'Verify Statement';
    public static final String DEAL_STATUS_CLARIFICATION_REQUIRED = 'Clarification Required';
    public static final String DEAL_STATUS_STATEMENT_VERIFIED = 'Statement Verified';
    public static final String DEAL_STATUS_INVOICE_REJECTED = 'Invoice Rejected (Email resend to Seller)';
    public static final String DEAL_STATUS_READY_FOR_PAYMENT = 'Ready for Payment';
    public static final String DEAL_STATUS_PAYMENT_SENT = 'Payment Sent';
    public static final String DEAL_STATUS_PAYMENT_COMPLETED = 'Payment Completed';
    public static final String DEAL_STATUS_PAYMENT_REJECTED = 'Payment Rejected';
    public static final String DEAL_STATUS_CLOSED = 'Closed';
    public static final String DEAL_STATUS_NEW = 'New';
    public static final String DEAL_STATUS_NEGOTIATING = 'Negotiating';
    public static final String DEAL_STATUS_NEGOTIATING_AMENDED = 'Negotiating Amended';
    public static final String DEAL_STATUS_SELLER_INVITE = 'Seller Invite';
    public static final String DCA_STATUS_CANCELLED = 'Cancelled';//TH-31-03-2023
    public static final String DEAL_STATUS_CANCELLED = 'Cancelled';//LA-03-06-2022
    public static final String DEAL_STATUS_PROCESSING = 'Processing';//LA-03-06-2022
    public static final String DEAL_STATUS_OPS_REVIEW = 'Ops Review';//LA-03-06-2022
    public static final String DEAL_STATUS_INCOMPLETE_DATA = 'Incomplete Data';//LA-03-06-2022
    public static final String DEAL_STATUS_CM_REVIEW = 'CM Review';//LA-03-06-2022
    public static final String DEAL_STATUS_SCHEDULE = 'Scheduled';//LA-03-06-2022
    public static final String DEAL_STATUS_COMPLETED = 'Completed';//LA-03-06-2022
    public static final String DEAL_STATUS_SELLER_CANCELLED = 'Seller Cancelled';//MN-13032023-US-0012628
    public static final String DEAL_STATUS_SELLER_REJECTED = 'Seller Rejected';//MN-22032023-US-0012628
    public static final String DEAL_STATUS_INTERNALLY_REJECTED = 'Internally Rejected';//MN-22032023-US-0012628
    public static final String DEAL_STATUS_EXPIRED = 'Expired';//MN-22032023-US-0012628
    public static final String DEAL_STATUS_SENT_TO_SELLER = 'Sent to Seller';//SB 26.05.2023 US-0013450
    public static final String DEAL_STATUS_SELLER_APPROVED = 'Seller Approved';//SB 26.05.2023 US-0013450

    public static final String DEAL_SEP_STATUS_PLEASE_AGREE_ON_THE_PROPOSED_DEAL = 'Please agree on the proposed Deal';
    public static final String DEAL_SEP_STATUS_DEAL_AGREED = 'Deal agreed';
    public static final String DEAL_SEP_STATUS_DEAL_IN_EXECUTION = 'Deal in execution';
    public static final String DEAL_SEP_STATUS_DEAL_ENDED = 'Deal ended';
    public static final String DEAL_SEP_STATUS_DEAL_PROPOSAL_REJECTED = 'Deal proposal rejected';
    public static final String DEAL_SEP_STATUS_INVOICE_VERIFICATION_IN_PROCESS_BY_EBAY = 'Invoice verification in process by eBay';
    public static final String DEAL_SEP_STATUS_INVOICING_IN_PROCESS = 'Invoicing in process';
    public static final String DEAL_SEP_STATUS_CLARIFICATION_ON_INVOICING = 'Clarification on invoicing';
    public static final String DEAL_SEP_STATUS_PLEASE_PROVIDE_AN_INVOICE = 'Please provide an invoice';
    public static final String DEAL_SEP_STATUS_INVOICE_REJECTED_PLEASE_VERIFY = 'Invoice rejected, please verify';
    public static final String DEAL_SEP_STATUS_PAYMENT_IN_PROCESS = 'Payment in process';
    public static final String DEAL_SEP_STATUS_DEAL_SENT_FOR_PAYMENT = 'Deal sent for payment';
    public static final String DEAL_SEP_STATUS_PAYMENT_COMPLETED = 'Payment completed';
    public static final String DEAL_SEP_STATUS_PAYMENT_REJECTED = 'Payment rejected';
    public static final String DEAL_SEP_STATUS_DEAL_CLOSED = 'Deal closed';
    public static final String DEAL_SEP_STATUS_NEW_DEAL_PROPOSED_TO_EBAY = 'New Deal proposed to eBay';
    public static final String DEAL_SEP_STATUS_NEGOTIATION = 'Negotiation';
    public static final String DEAL_SEP_STATUS_NEGOTIATION_AMENDED = 'Negotiation Amended';
    public static final String DEAL_SEP_STATUS_EBAY_DEAL_INVITATION = 'Invitation to Deals';
    public static final String DEAL_SEP_STATUS_PENDING_REVIEW = 'Pending Review';//LA-03-06-2022
    public static final String DEAL_SEP_STATUS_EDITABLE = 'Editable';//LA-03-06-2022
    public static final String DEAL_SEP_STATUS_CONTRACT_APPROVAL_REQUIRED = 'Contract Approval Required';//SB 26.05.2023 US-0013450
    public static final String DEAL_SEP_STATUS_CONTRACT_APPROVED = 'Contract Approved';//SB 26.05.2023 US-0013450
    public static final String DEAL_SEP_STATUS_CONTRACT_REJECTED = 'Contract Rejected';//SB 26.05.2023 US-0013450
    private final static String EXCEL = 'Excel';
    // SB 12.01.2024 US-0013136
    /*public static final Map<String, String> DEAL_STATUS_SEP_MAPPING = new Map<String, String> {
        DEAL_STATUS_PLANNED => DEAL_SEP_STATUS_PLEASE_AGREE_ON_THE_PROPOSED_DEAL,
        DEAL_STATUS_DEAL_AGREED => DEAL_SEP_STATUS_DEAL_AGREED,
        DEAL_STATUS_RUNNING => DEAL_SEP_STATUS_DEAL_IN_EXECUTION,
        DEAL_STATUS_EXECUTED => DEAL_SEP_STATUS_DEAL_ENDED,
        DEAL_STATUS_REJECTED => DEAL_SEP_STATUS_DEAL_PROPOSAL_REJECTED,
        DEAL_STATUS_VERIFY_INVOICE => DEAL_SEP_STATUS_INVOICE_VERIFICATION_IN_PROCESS_BY_EBAY,
        DEAL_STATUS_VERIFY_STATEMENT => DEAL_SEP_STATUS_INVOICING_IN_PROCESS,
        DEAL_STATUS_CLARIFICATION_REQUIRED => DEAL_SEP_STATUS_CLARIFICATION_ON_INVOICING,
        DEAL_STATUS_STATEMENT_VERIFIED => DEAL_SEP_STATUS_PLEASE_PROVIDE_AN_INVOICE,
        DEAL_STATUS_INVOICE_REJECTED => DEAL_SEP_STATUS_INVOICE_REJECTED_PLEASE_VERIFY,
        DEAL_STATUS_READY_FOR_PAYMENT => DEAL_SEP_STATUS_PAYMENT_IN_PROCESS,
        DEAL_STATUS_PAYMENT_SENT => DEAL_SEP_STATUS_DEAL_SENT_FOR_PAYMENT,
        DEAL_STATUS_PAYMENT_COMPLETED => DEAL_SEP_STATUS_PAYMENT_COMPLETED,
        DEAL_STATUS_PAYMENT_REJECTED => DEAL_SEP_STATUS_PAYMENT_REJECTED,
        DEAL_STATUS_CLOSED => DEAL_SEP_STATUS_DEAL_CLOSED,
        DEAL_STATUS_NEW => DEAL_SEP_STATUS_NEW_DEAL_PROPOSED_TO_EBAY,
        DEAL_STATUS_NEGOTIATING => DEAL_SEP_STATUS_NEGOTIATION,
        DEAL_STATUS_NEGOTIATING_AMENDED => DEAL_SEP_STATUS_NEGOTIATION_AMENDED,
        DEAL_STATUS_SELLER_INVITE => DEAL_SEP_STATUS_EBAY_DEAL_INVITATION, //TH:07/02/2022:US-0011045: [SP - EU Deals] Map New Hive Statuses to Seller Status
        DEAL_STATUS_SELLER_CANCELLED => DEAL_STATUS_SELLER_CANCELLED //MN-13032023-US-0012628
    };

    public static final Map<String, String> SELLER_PORTAL_STATUS_MAPPING = new Map<String, String> {
        DEAL_STATUS_REJECTED 		=> 	DEAL_STATUS_REJECTED,
		DEAL_STATUS_CANCELLED 		=> 	DEAL_STATUS_CANCELLED,
		DEAL_STATUS_PROCESSING 		=> 	DEAL_SEP_STATUS_EDITABLE,
		DEAL_STATUS_OPS_REVIEW 		=> 	DEAL_SEP_STATUS_EDITABLE,
		DEAL_STATUS_INCOMPLETE_DATA => 	DEAL_SEP_STATUS_PENDING_REVIEW,
		DEAL_STATUS_CM_REVIEW 		=> 	DEAL_SEP_STATUS_PENDING_REVIEW,
		DEAL_STATUS_SCHEDULE 		=> 	DEAL_STATUS_SCHEDULE,
		DEAL_STATUS_RUNNING			=> 	DEAL_STATUS_RUNNING,
		DEAL_STATUS_COMPLETED 		=> 	DEAL_STATUS_COMPLETED,
        DEAL_STATUS_SELLER_CANCELLED => DEAL_STATUS_SELLER_CANCELLED //MN-15032023-US-0012628 
    };

    //SB 26.05.2023 US-0013450
    public static final Map<String, String> SUBSIDISED_SELLER_PORTAL_STATUS_MAPPING = new Map<String, String> {
        DEAL_STATUS_NEW => DEAL_SEP_STATUS_NEW_DEAL_PROPOSED_TO_EBAY,
        DEAL_STATUS_SENT_TO_SELLER => DEAL_SEP_STATUS_CONTRACT_APPROVAL_REQUIRED,
        DEAL_STATUS_SELLER_APPROVED => DEAL_SEP_STATUS_CONTRACT_APPROVED,
        DEAL_STATUS_SELLER_REJECTED => DEAL_SEP_STATUS_CONTRACT_REJECTED
    };*/

    //preparing all using status from custom setting into set/map
    static{
        prepareStatus('AVAIL_STATUS',AVAIL_STATUS);
        prepareStatus('STATUS_SLOT_ALLOC_NULL',STATUS_SLOT_ALLOC_NULL);
        
        prepareStatusMap(KEY_STATUS_FINAL);
        prepareStatusMap(KEY_STATUS_INVOICED);
        prepareStatusMap(KEY_STATUS_FORECAST);
        prepareStatusMap(KEY_STATUS_MAX);
    } 
    static void prepareStatusMap(String nameKey)
    {
        EBH_DealStatus__c status_CS = EBH_DealStatus__c.getInstance(nameKey);
        
        if(status_CS <> null)
        {   String statusSet = status_CS.EBH_StatusSet__c;
         for(String status : (status_CS.EBH_StatusSet__c+'').replace('null','').split(','))
         {
             MAP_STATUS_TYPE.put(status,nameKey);
         }
        }
    }
    static void prepareStatus(String nameKey,Set<String>  setToPopulate)
    {
        EBH_DealStatus__c status_CS = EBH_DealStatus__c.getInstance(nameKey);
        
        if(status_CS <> null)
        {   String statusSet = status_CS.EBH_StatusSet__c;
         for(String status : (status_CS.EBH_StatusSet__c+'').replace('null','').split(','))
         {
             setToPopulate.add(status);
         }
        }
    }

    //private static final Set<String> SET_SKIPPED_COUNT_STATUS = new Set<String>{'New','Negotiating','Rejected'};//TH:US-0013020 - comment out
    //private static final Set<String> SET_SKIPPED_COUNT_STATUS = new Set<String>{'New','Rejected'};////TH:US-0013020 - remove 'Negotiating'
    private static final Set<String> SET_SKIPPED_COUNT_STATUS = new Set<String>{DEAL_STATUS_NEW,DEAL_STATUS_REJECTED, DEAL_STATUS_SELLER_CANCELLED};//MN-22032023-US-0012628-Add Seller Cancelled 
    private static final String SOQL_COUNT_DEAL = 'Select Count(Id) countDeal, EBH_DealRetailCampaign__c slotId from EBH_Deal__c';
    
    /*****************************************************************************************************************************
@ Method:        setNonPayOutItemEstimate
@ Version:       1.0
@ Author:          
@ Purpose:       set NonPayOutItemEstimate for deal from DealBudget by month year
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:  Boolean isUpdate,List<EBH_Deal__c> listDealOld,List<EBH_Deal__c> listDealNew       
@   event   : before insert, before update
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03/07/2019 / Sovantheany Dim  / Created the  Method.
*****************************************************************************************************************************/
    public static void setNonPayOutItemEstimate(Map<Id,EBH_Deal__c> mapDealOld,List<EBH_Deal__c> listDealNew){
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        if(!isDeal_V1(listDealNew)) return;

        Set<String> setQuarter = new Set<String>();
        Set<String> setYear = new Set<String>();
        Set<String> setVertical = new Set<String>();
        Set<String> setSite = new Set<String>();
        Map<String,List<EBH_Deal__c>> mapDeal = new Map<String,List<EBH_Deal__c>>();
        for(EBH_Deal__c dealNew: listDealNew)
        {
            if(dealNew.EBH_DealStartDate__c == null || dealNew.EBH_Vertical__c == null || dealNew.EBH_DealSiteId__c == null) continue;
            if((trigger.isUpdate && (mapDealOld.get(dealNew.Id).EBH_DealStartDate__c <> dealNew.EBH_DealStartDate__c || mapDealOld.get(dealNew.Id).EBH_Vertical__c <> dealNew.EBH_Vertical__c || mapDealOld.get(dealNew.Id).EBH_DealSiteId__c <> dealNew.EBH_DealSiteId__c)) || trigger.isInsert){
                String quarter = getQuarterNumber(dealNew.EBH_DealStartDate__c);
                String year = String.valueOf(dealNew.EBH_DealStartDate__c.year());
                setQuarter.add(quarter);
                setYear.add(year);
                setVertical.add(dealNew.EBH_Vertical__c);
                setSite.add(dealNew.EBH_DealSiteId__c);
                String key = quarter+year+dealNew.EBH_Vertical__c+dealNew.EBH_DealSiteId__c;
                List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
                if(mapDeal.containsKey(key)) lstDeal = mapDeal.get(key);
                lstDeal.add(dealNew);
                mapDeal.put(key,lstDeal);
            }
        }
        
        if(setQuarter.isEmpty() || setYear.isEmpty() || setVertical.isEmpty() || setSite.isEmpty()) return;
        String whereString = ' where EBH_Quarter__c IN: setQuarter and Year__c IN: setYear and Non_Payout_Items_Estimate__c <> null and EBH_Vertical__c IN: setVertical and Deal_Site__c IN: setSite';
        for(EBH_DealsBudget__c dealBudget : Database.query(EBH_ConstantsUtility.SOQL_DEALBUDGET + whereString)){
            String key = dealBudget.EBH_Quarter__c+''+dealBudget.Year__c+''+dealBudget.EBH_Vertical__c+dealBudget.Deal_Site__c;
            if(!mapDeal.containsKey(key)) continue;
            for(EBH_Deal__c deal : mapDeal.get(key)){
                deal.Non_Payout_Items_Estimate_N__c = dealBudget.Non_Payout_Items_Estimate__c;
            }
        } 
    }
    
    /*****************************************************************************************************************************
@ Method:        sumDealForDealBudget
@ Version:       1.0
@ Author:          
@ Purpose:       EPH-7467 Deal Budget -Object - Redesign
Subsidy Planned = Sum of Subsidy Planned from related deals records
Subsidy Running = Sum of Subsidy Running from related deals records
Subsidy Forecast = Sum of Subsidy Forecast from related deals records
Subsidy Final = Sum of Subsidy Final from related deals records
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:  Boolean isUpdate,Boolean isDelete, Map<Id,EBH_Deal__c> mapDealOld,Map<Id,EBH_Deal__c> mapDealNew       
@   event   : after insert, after update, after delete, after undelete
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02/07/2019 / Sovantheany Dim  / Created the  Method.
*****************************************************************************************************************************/
/*

    public static void sumDealForDealBudget(Boolean isUpdate,Boolean isDelete, Map<Id,EBH_Deal__c> mapDealOld,Map<Id,EBH_Deal__c> mapDealNew){
        sumDeal(true,isUpdate,isDelete,mapDealOld,mapDealNew);
    }
  */  
    /*****************************************************************************************************************************
@ Method:        sumDealForDealBudgetMonth
@ Version:       1.0
@ Author:          
@ Purpose:       EPH-7599 Deal Month Object for Invoice Redesign
Subsidy Planned = Sum of Subsidy Planned from related deals records
Subsidy Running = Sum of Subsidy Running from related deals records
Subsidy Forecast = Sum of Subsidy Forecast from related deals records
Subsidy Final = Sum of Subsidy Final from related deals records
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:  Boolean isUpdate,Boolean isDelete, Map<Id,EBH_Deal__c> mapDealOld,Map<Id,EBH_Deal__c> mapDealNew       
@   event   : after insert, after update, after delete, after undelete
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02/07/2019 / Sovantheany Dim  / Created the  Method.
*****************************************************************************************************************************/

/*
    public static void sumDealForDealBudgetMonth(Boolean isUpdate,Boolean isDelete, Map<Id,EBH_Deal__c> mapDealOld,Map<Id,EBH_Deal__c> mapDealNew){
        sumDeal(false,isUpdate,isDelete,mapDealOld,mapDealNew);
    }
    
    private static void sumDeal(Boolean isDealBudget, Boolean isUpdate,Boolean isDelete, Map<Id,EBH_Deal__c> mapDealOld,Map<Id,EBH_Deal__c> mapDealNew){
        Set<String> setQuarter = new Set<String>();
        Set<String> setYear = new Set<String>();
        Set<String> setVertical = new Set<String>();
        Set<String> setSite = new Set<String>();
        Set<String> sMonthYear = new Set<String>();
        Map<String,Subsidy> mapSumSubsidy = new Map<String,Subsidy>();
        for(EBH_Deal__c dOld: mapDealOld==null || mapDealOld.isEmpty()?mapDealNew.values():mapDealOld.values()){
            EBH_Deal__c rightDeal = null;
            String quarter = '';
            String year = '';
            String vertical = '';
            String site = '';
            //update
            if(isUpdate){
                EBH_Deal__c dNew = mapDealNew.get(dOld.Id);
                if(dNew.EBH_DealStartDate__c <> null && dNew.EBH_Vertical__c <> null && dNew.EBH_DealSiteId__c <> null && (dOld.EBH_DealStartDate__c <> dNew.EBH_DealStartDate__c || dOld.Subsidy_Running__c <> dNew.Subsidy_Running__c ||
                                                                                                                           dOld.EBH_SubsidyForecast__c <> dNew.EBH_SubsidyForecast__c || dOld.EBH_SubsidyFinal__c <> dNew.EBH_SubsidyFinal__c ||
                                                                                                                           dOld.EBH_SubsidyMax__c <> dNew.EBH_SubsidyMax__c || dOld.EBH_Vertical__c <> dNew.EBH_Vertical__c || dOld.EBH_DealSiteId__c <> dNew.EBH_DealSiteId__c)){
                                                                                                                               rightDeal = dNew;
                                                                                                                               if(dOld.EBH_DealStartDate__c != null && dOld.EBH_Vertical__c != null && dOld.EBH_DealSiteId__c != null){
                                                                                                                                   
                                                                                                                                   if(isDealBudget){
                                                                                                                                       quarter = getQuarterNumber(dOld.EBH_DealStartDate__c);
                                                                                                                                       year = String.valueOf(dOld.EBH_DealStartDate__c.year());
                                                                                                                                       setQuarter.add(quarter);
                                                                                                                                       setYear.add(year);
                                                                                                                                       mapSumSubsidy.put(quarter+year+dOld.EBH_Vertical__c+dOld.EBH_DealSiteId__c,new Subsidy(0,0,0,0));
                                                                                                                                       //set month year of each quarter
                                                                                                                                       if(mMonthQ.containsKey(quarter)){
                                                                                                                                           set<Integer> sMonth = mMonthQ.get(quarter);
                                                                                                                                           for(Integer i : sMonth){
                                                                                                                                               sMonthYear.add(i+''+year);
                                                                                                                                           }
                                                                                                                                       }
                                                                                                                                       
                                                                                                                                   }else{
                                                                                                                                       sMonthYear.add(dOld.EBH_StartDateMonthYear__c);
                                                                                                                                       mapSumSubsidy.put(dOld.EBH_StartDateMonthYear__c+dOld.EBH_Vertical__c+dOld.EBH_DealSiteId__c,new Subsidy(0,0,0,0));
                                                                                                                                   }
                                                                                                                                   setVertical.add(dOld.EBH_Vertical__c);
                                                                                                                                   setSite.add(dOld.EBH_DealSiteId__c);
                                                                                                                               }
                                                                                                                           }
            }else//insert/delete/undelete
            {   //delete needs old trigger
                EBH_Deal__c tmp =  isDelete?dOld:mapDealNew.get(dOld.Id);
                if(tmp.EBH_DealStartDate__c <> null && tmp.EBH_Vertical__c <> null && tmp.EBH_DealSiteId__c <> null){
                    rightDeal = tmp;
                }
            }
            
            if(rightDeal==null)continue;
            
            if(isDealBudget){
                quarter = getQuarterNumber(rightDeal.EBH_DealStartDate__c);
                year = String.valueOf(rightDeal.EBH_DealStartDate__c.year());
                setQuarter.add(quarter);
                setYear.add(year);
                mapSumSubsidy.put(quarter+year+rightDeal.EBH_Vertical__c+rightDeal.EBH_DealSiteId__c,new Subsidy(0,0,0,0));
                //set month year of each quarter
                if(mMonthQ.containsKey(quarter)){
                    set<Integer> sMonth = mMonthQ.get(quarter);
                    for(Integer i : sMonth){
                        sMonthYear.add(i+''+year);
                    }
                }
            }else{
                sMonthYear.add(rightDeal.EBH_StartDateMonthYear__c);
                mapSumSubsidy.put(rightDeal.EBH_StartDateMonthYear__c+rightDeal.EBH_Vertical__c+rightDeal.EBH_DealSiteId__c,new Subsidy(0,0,0,0));
            }
            setVertical.add(rightDeal.EBH_Vertical__c);
            setSite.add(rightDeal.EBH_DealSiteId__c);
        }
        
        if(sMonthYear.isEmpty() || setVertical.isEmpty() || setSite.isEmpty()) return;
        
        String whereDealString = ' where EBH_StartDateMonthYear__c IN: sMonthYear and EBH_Vertical__c IN: setVertical and EBH_DealSiteId__c IN: setSite';
        for(EBH_Deal__c deal : Database.query(EBH_ConstantsUtility.SOQL_DEAL + whereDealString)){
            String key = '';
            if(isDealBudget){
                String quarter = getQuarterNumber(deal.EBH_DealStartDate__c);
                Integer year = deal.EBH_DealStartDate__c.year();
                key = quarter + year + deal.EBH_Vertical__c + deal.EBH_DealSiteId__c;
            }else{
                key = deal.EBH_StartDateMonthYear__c + deal.EBH_Vertical__c + deal.EBH_DealSiteId__c;
            }
            Double Subsidy_Running = (deal.Subsidy_Running__c <> null ? deal.Subsidy_Running__c : 0);
            Double Subsidy_Forecast = (deal.EBH_SubsidyForecast__c <> null ? deal.EBH_SubsidyForecast__c : 0);
            Double Subsidy_Final = (deal.EBH_SubsidyFinal__c <> null ? deal.EBH_SubsidyFinal__c : 0);
            Double Subsidy_Planned = (deal.EBH_SubsidyMax__c <> null ? deal.EBH_SubsidyMax__c : 0);
            Subsidy subsidy = new Subsidy(Subsidy_Running,Subsidy_Forecast,Subsidy_Final,Subsidy_Planned);
            
            if(mapSumSubsidy.containsKey(key)){
                subsidy = mapSumSubsidy.get(key);
                subsidy.Subsidy_Running += Subsidy_Running;
                subsidy.Subsidy_Forecast += Subsidy_Forecast;
                subsidy.Subsidy_Final += Subsidy_Final;
                subsidy.Subsidy_Planned += Subsidy_Planned;
            }
            mapSumSubsidy.put(key,subsidy);
        }
        if(isDealBudget){
            String whereString = ' where EBH_Quarter__c IN: setQuarter and Year__c IN: setYear and EBH_Vertical__c IN: setVertical and Deal_Site__c IN: setSite';
            List<EBH_DealsBudget__c> dealBudgets = new List<EBH_DealsBudget__c>();
            for(EBH_DealsBudget__c dealBudget : Database.query(EBH_ConstantsUtility.SOQL_DEALBUDGET + whereString)){
                String key = dealBudget.EBH_Quarter__c+''+dealBudget.Year__c+''+dealBudget.EBH_Vertical__c+''+dealBudget.Deal_Site__c;
                if(!mapSumSubsidy.containsKey(key)) continue;
                Subsidy subsidy = mapSumSubsidy.get(key);
                dealBudget.Subsidy_Running__c = subsidy.Subsidy_Running;
                dealBudget.Subsidy_Forecast__c = subsidy.Subsidy_Forecast;
                dealBudget.Subsidy_Final__c = subsidy.Subsidy_Final;
                dealBudget.Subsidy_Planned__c = subsidy.Subsidy_Planned;
                dealBudgets.add(dealBudget);
            } 
            if(!dealBudgets.isEmpty()) update dealBudgets;
        }else{
            String whereBudgetMonthString = ' where EBH_MonthYear__c IN: sMonthYear and EBH_DealsBudget__r.EBH_Vertical__c IN: setVertical and EBH_DealsBudget__r.Deal_Site__c IN: setSite';
            List<EBH_DealsBudgetMonth__c> dealBudgetMonths = new List<EBH_DealsBudgetMonth__c>();
            for(EBH_DealsBudgetMonth__c dealBudgetMonth : Database.query(EBH_ConstantsUtility.SOQL_DEALBUDGETMONTH + whereBudgetMonthString)){
                String key = dealBudgetMonth.EBH_MonthYear__c+dealBudgetMonth.EBH_DealsBudget__r.EBH_Vertical__c+dealBudgetMonth.EBH_DealsBudget__r.Deal_Site__c;
                if(!mapSumSubsidy.containsKey(key)) continue;
                Subsidy subsidy = mapSumSubsidy.get(key);
                dealBudgetMonth.Subsidy_Running__c = subsidy.Subsidy_Running;
                dealBudgetMonth.EBH_SubsidyForecast__c = subsidy.Subsidy_Forecast;
                dealBudgetMonth.Subsidy_Final__c = subsidy.Subsidy_Final;
                dealBudgetMonth.Subsidy_Planned__c = subsidy.Subsidy_Planned;
                dealBudgetMonths.add(dealBudgetMonth);
            }
            if(!dealBudgetMonths.isEmpty()) update dealBudgetMonths;
        }
    }
    */

    //TH: US-0010550 10/11/2021 : Don't use , depreciated it to increase code coverage
    /*private class Subsidy{
        Double Subsidy_Running;
        Double Subsidy_Forecast;
        Double Subsidy_Final;
        Double Subsidy_Planned; 
        private Subsidy(Double Subsidy_Running,Double Subsidy_Forecast,Double Subsidy_Final,Double Subsidy_Planned){
            this.Subsidy_Running = Subsidy_Running;
            this.Subsidy_Forecast = Subsidy_Forecast;
            this.Subsidy_Final = Subsidy_Final;
            this.Subsidy_Planned = Subsidy_Planned;
        }
    }*/
    
    private static Map<String, set<Integer>> mMonthQ = new Map<String, set<Integer>>{
        'Q1'=> new set<Integer>{1,2,3},
            'Q2'=> new set<Integer>{4,5,6},
                'Q3'=> new set<Integer>{7,8,9},
                    'Q4'=> new set<Integer>{10,11,12}
    };
        
        private static String getQuarterNumber(Date d) {
            if(d.month() >= 1 && d.month() <= 3)
                return 'Q1';
            else if (d.month() >= 4 && d.month() <= 6)
                return 'Q2';
            else if (d.month() >= 7 && d.month() <= 9)
                return 'Q3';
            else 
                return 'Q4';
        }
    //TH: US-0010550 10/11/2021 : don't use anywhere so depreciated it to increase code coverage
    //called from trigger
    /*public static void calculateDeals(Boolean isUpdate,Boolean isDelete,Boolean isInsert,Map<Id,EBH_Deal__c> mapDealOld,Map<Id,EBH_Deal__c> mapDealNew)
    {
        Set<String> setMonthYear = new Set<String>();
        Set<String> setVertical = new Set<String>();    
        //filter deals
        for(EBH_Deal__c dOld: (mapDealOld==null || mapDealOld.isEmpty() ?mapDealNew.values():mapDealOld.values()))
        {
            EBH_Deal__c rightDeal = null;
            //update 
            if(isUpdate)
            {
                EBH_Deal__c dNew = mapDealNew.get(dOld.Id);
                if(((dOld.EBH_DealStartDate__c <> dNew.EBH_DealStartDate__c)
                    || (dOld.EBH_DealPrice__c <> dNew.EBH_DealPrice__c)
                    || (dOld.EBH_Status__c <> dNew.EBH_Status__c)
                    || (dOld.EBH_Quantity__c <> dNew.EBH_Quantity__c)
                   )
                   &&  dNew.EBH_DealStartDate__c <> null
                   && AVAIL_STATUS.contains(dNew.EBH_Status__c)
                  )
                {
                    rightDeal = dNew;
                    
                }
            }else//insert/delete/undelete
            {   //delete needs old trigger
                EBH_Deal__c tmp =  isDelete?dOld:mapDealNew.get(dOld.Id);
                
                if(tmp.EBH_DealStartDate__c <> null && AVAIL_STATUS.contains(tmp.EBH_Status__c))
                {
                    rightDeal = tmp;
                }
            }
            if(rightDeal==null)continue;
            String my = rightDeal.EBH_DealStartDate__c.month()+''+rightDeal.EBH_DealStartDate__c.year();
            setMonthYear.add(my);
            setVertical.add(rightDeal.EBH_Vertical__c);
        }
        if(!setMonthYear.isEmpty() || !setVertical.isEmpty())
        {
            //Deals_Budget_Month__c
            //Deals_Budget_Month__c.Deals_Budget__r.Vertical__c
            Map<String,EBH_DealsBudgetMonth__c> mapDBM = new Map<String,EBH_DealsBudgetMonth__c>();
            for(EBH_DealsBudgetMonth__c dbm:[Select Id,EBH_MonthYear__c,EBH_DealsBudget__r.EBH_Vertical__c From EBH_DealsBudgetMonth__c WHERE EBH_MonthYear__c IN:setMonthYear AND EBH_DealsBudget__r.EBH_Vertical__c IN:setVertical])
            {
                mapDBM.put(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c,dbm);
            }
            if(!mapDBM.isEmpty())
            {
                doCalculateDeals(mapDBM,[Select Id,EBH_Vertical__c,EBH_Status__c,EBH_SubsidyFinal__c,EBH_SubsidyForecast__c,EBH_SubsidyMax__c,EBH_StartDateMonthYear__c FROM EBH_Deal__c Where EBH_StartDateMonthYear__c IN:setMonthYear AND EBH_Vertical__c IN:setVertical AND EBH_Status__c IN:AVAIL_STATUS],true);    
            } 
        }  
    } */
    
    public static void doCalculateDeals(Map<String,EBH_DealsBudgetMonth__c> mapDBM,List<EBH_Deal__c> listDeal,Boolean updateDMB)
    {
        
        Map<String,Double> monthYearDeals = new Map<String,Double>();
        for(EBH_Deal__c deal: listDeal)
        {   
            String sType = MAP_STATUS_TYPE.get(deal.EBH_Status__c);
            //s_Final,s_invoiced, s_Forecast, s_Max
            
            Double val = monthYearDeals.get(deal.EBH_StartDateMonthYear__c+''+deal.EBH_Vertical__c+''+sType);
            
            
            val = val==null?0:val;
            
            if(sType == KEY_STATUS_FINAL || sType == KEY_STATUS_INVOICED)
            {
                val+=deal.EBH_SubsidyFinal__c==null?0:deal.EBH_SubsidyFinal__c;
            }
            /*//TH: EPH-7468 change to new formula On EBH_DealTriggerHandler.sumDealForDealBudgetMonth
else if(sType == KEY_STATUS_FORECAST)
{
val+=deal.EBH_SubsidyForecast__c==null?0:deal.EBH_SubsidyForecast__c;
}
*/
            else if(sType == KEY_STATUS_MAX)
            {
                val+=deal.EBH_SubsidyMax__c ==null?0:deal.EBH_SubsidyMax__c;
            }
            monthYearDeals.put(deal.EBH_StartDateMonthYear__c+''+deal.EBH_Vertical__c+''+sType,val);
        }
        
        for(EBH_DealsBudgetMonth__c dbm: mapDBM.values())
        {
            dbm.EBH_SubsidyPaid__c = monthYearDeals.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+KEY_STATUS_FINAL);
            dbm.EBH_SubsidyInvoiced__c = monthYearDeals.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+KEY_STATUS_INVOICED);
            //TH: EPH-7468 change to new formula On EBH_DealTriggerHandler.sumDealForDealBudgetMonth
            //dbm.EBH_SubsidyForecast__c = monthYearDeals.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+KEY_STATUS_FORECAST);
            
            dbm.EBH_SubsidyMax__c  = monthYearDeals.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+KEY_STATUS_MAX);
            
        }
        
        if(updateDMB) update    mapDBM.values();    
        
    }
    
    
    
    /**NK:09/10/2017
1) When a deal record gets saved and EBH_Status__c = "Planned" or "Deal Agreed" or "Running" or "Executed" or "Ready for Payment" or "Paid" 
find Deal_Slot_Allocation__c record where Deal_Slot_Allocation__c.UID__c = EBH_Deal__c.UID__c and put Deal_Slot_Allocation__c.Id into EBH_Deal__c.Deal_Slot_Allocation__c (Lookup). If you don't get a result just skip.
2) When a deal record gets saved and EBH_Status__c = "New" or "Negotiating" or "Rejected" change EBH_Deal__c.Deal_Slot_Allocation__c to null

trigger event: before udpate/before insert EBH_Deal__c
*/
    public static void handleDealSlotAllocation(Boolean isUpdate,List<EBH_Deal__c> listDealOld,List<EBH_Deal__c> listDealNew)
    {
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        if(!isDeal_V1(listDealNew)) return;

        Map<EBH_Deal__c,String> mapDealToAddSlot = new Map<EBH_Deal__c,String>();
        integer i =0;
        for(EBH_Deal__c dealNew: listDealNew)
        {
            if(isUpdate && !listDealOld.isEmpty())
            {
                if((listDealOld[i].EBH_Status__c <> dealNew.EBH_Status__c
                    || listDealOld[i].EBH_DealFormat__c <> dealNew.EBH_DealFormat__c
                    || listDealOld[i].EBH_DealStartDate__c <>  dealNew.EBH_DealStartDate__c
                   )
                   && AVAIL_STATUS.contains(dealNew.EBH_Status__c))
                {
                    mapDealToAddSlot.put(dealNew,dealNew.EBH_UID__c);
                }else if(listDealOld[i].EBH_Status__c <> dealNew.EBH_Status__c && STATUS_SLOT_ALLOC_NULL.contains(dealNew.EBH_Status__c))
                {
                    dealNew.EBH_DealSlotAllocation__c = null;
                }
                
                
            }else //insert
            {
                if(AVAIL_STATUS.contains(dealNew.EBH_Status__c))
                {
                    mapDealToAddSlot.put(dealNew,dealNew.EBH_UID__c);
                }else if(STATUS_SLOT_ALLOC_NULL.contains(dealNew.EBH_Status__c))
                {
                    dealNew.EBH_DealSlotAllocation__c = null;
                }
            }
            
            i++;
        }
        
        if(!mapDealToAddSlot.isEmpty())
        {
            Map<String,EBH_DealSlotAllocation__c> mapDSA = new Map<String,EBH_DealSlotAllocation__c>();
            for(EBH_DealSlotAllocation__c dsa:[Select Id,EBH_UID__c From EBH_DealSlotAllocation__c where EBH_UID__c IN:mapDealToAddSlot.values()])
            {
                mapDSA.put(dsa.EBH_UID__c,dsa);
            }   
            for(EBH_Deal__c deal: mapDealToAddSlot.keySet())
            {
                deal.EBH_DealSlotAllocation__c = mapDSA.containsKey(deal.EBH_UID__c)?mapDSA.get(deal.EBH_UID__c).Id:null;
            }
        }
    }
    /*****************************************************************************************************************************
@ Method:         handleAvailableSlot
@ Version:        1.0
@ Author:          
@ Purpose:        EPH-5465
@                 When Deal insert/delete/update/undelete: 
@                 Then the field "Open Slots Available" will update to = "Slots" - (# of Deals related to the Deal Slot Allocation that are NOT in status "New", "Negotiating", or "Rejected")
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:        isUpdate: isUpdate trigger
@                   mapDealOld: trigger.oldMap
@                   mapDealNew: trigger.newMap
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02/04/2018 / Vadhanak Voun  / Created the  Method.
@ Change history: 24/06/2022 / Sophal Noch  / US-0011987 - Too many query rows: 50001 when executing BatchDealVerifyStatement
*****************************************************************************************************************************/
    public static void handleAvailableSlot(Boolean isUpdate,Map<Id,EBH_Deal__c> mapDealOld,Map<Id,EBH_Deal__c> mapDealNew)
    {
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        if(!isDeal_V1(mapDealNew.values())) return;

        Set<String> setAlloc = new Set<String>();
        for(EBH_Deal__c deal:mapDealNew.values())
        {

            if(deal.EBH_DealRetailCampaign__c == null) continue; // 24.06.2022 / Sophal Noch / US-0011987 : skip null EBH_DealRetailCampaign__c in order to avoid using in AggregateResult query below

            if(isUpdate)
            {
                if(mapDealOld.get(deal.id).EBH_Status__c <> deal.EBH_Status__c) //status change?
                {
                    setAlloc.add(deal.EBH_DealRetailCampaign__c);
                }
            } else //insert delete undelete
            {
                setAlloc.add(deal.EBH_DealRetailCampaign__c);
            }
        }
        
        if(!setAlloc.isEmpty())
        {
            // Map<String,EBH_DealRetailCampaign__c> mapSlot = new Map<String,EBH_DealRetailCampaign__c>();
            // for(EBH_DealRetailCampaign__c slot: [Select Id, EBH_Slots__c, (Select Id From Deals__r WHERE EBH_Status__c NOT IN:EBH_ConstantsUtility.SET_AVAIL_SLOT_COUNT) From EBH_DealRetailCampaign__c  where Id IN:setAlloc])
            // {
            //     Integer countChild = 0;
            //     for(EBH_Deal__c d : slot.Deals__r)
            //     {
            //         countChild++;
            //     }
            //     if (slot.EBH_Slots__c!=null){
            //         slot.EBH_OpenSeatsAvailable__c = slot.EBH_Slots__c - countChild;
            //     }
            //     else {slot.EBH_OpenSeatsAvailable__c = null;}
            //     mapSlot.put(slot.Id,slot);
            // }
            // update mapSlot.values();

            Map<Id,EBH_DealRetailCampaign__c> mapSlot = new Map<Id,EBH_DealRetailCampaign__c>([Select Id, EBH_Slots__c From EBH_DealRetailCampaign__c  where Id IN:setAlloc]);
            Map<Id,Integer> mapSlotIdToCountDeal= new  Map<Id,Integer>();
            // 24.06.2022 / Sophal Noch / US-0011987 : fix "Too many query rows: 50001" error by using AggregateResult to count deal records instead of using inner deal soql inside EBH_DealRetailCampaign__c soql
            for(AggregateResult aggr : Database.query(SOQL_COUNT_DEAL + ' Where EBH_Status__c NOT IN :SET_SKIPPED_COUNT_STATUS AND EBH_DealRetailCampaign__c IN:setAlloc Group By EBH_DealRetailCampaign__c')){
                mapSlotIdToCountDeal.put(Id.valueOf(aggr.get('slotId')+''), Integer.valueOf(aggr.get('countDeal')));
            }
            for(Id slotId : mapSlot.keySet()){
                EBH_DealRetailCampaign__c slot = mapSlot.get(slotId);
                Integer countDeal = mapSlotIdToCountDeal.get(slotId);
                countDeal = countDeal != null ? countDeal : 0;
                slot.EBH_OpenSeatsAvailable__c = slot.EBH_Slots__c != null ? (slot.EBH_Slots__c - countDeal) : null;
            }
            
            update mapSlot.values();


        }
    }
    
/*****************************************************************************************************************************
@ Method:        lockDeals
@ Version:       1.0
@ Author:          
@ Purpose:      [#EPH-5741] Negotiate deals with sellers (Edit Feature)
@                  
@               Then the Status of the Deal changes to "Negotiating" And:
@               If Comments were not provided, than no change to the existing Comments field
@               If Comments were provided, than change the existing Comments field to the new value
@               And the Deal record will be locked for Deal Manager to edit
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:        isUpdate: isUpdate trigger
@                   mapDealOld: trigger.oldMap
@                   listDealNew: trigger.new
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11/06/2018 / Vadhanak Voun  / Created the  Method.
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06/09/2021 / Mony Nou  / US-0010019 - [NA] Subsidized Deals Contract Amendment Process
                                            + ONLY enable this method for Amendment NA Deal with status = "New"
@                : 02/02/2023/ Sovantheany dim / US-0013020 - Remove negotiating picklist from the Deal V1 record type
*****************************************************************************************************************************/
    public static void lockDeals(Boolean isUpdate,Map<Id,EBH_Deal__c> mapDealOld,List<EBH_Deal__c> listDealNew)
    {
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        // if(!isDeal_V1(listDealNew)) return; //MN-06092021-US-0010019
        //TH:US-0013020:comment out
        //if(!isDeal_V1(listDealNew) && !isDeal_V2(listDealNew)) return; //MN-06092021-US-0010019 - Only enable lock deal for NA Amendment Deal with status = New 
        if(!isDeal_V2(listDealNew)) return;//TH:US-0013020 - remove !isDeal_V1(listDealNew)
        Set<String> setProfileNames = EBH_ConstantsUtility.DEAL_NEGOTIATION_IGNORE_PROFILES;
        for(Profile p : Database.query(EBH_ConstantsUtility.SOQL_PROFILE+' WHERE NAME IN:setProfileNames'))  
        {
            if(p.Id == userInfo.getProfileId()) return;
            
        }
        if(isUpdate)
        {
            // Acmatac SEING, 19 May 2021, Update from describe object to ApexUtil.getRecordTypeByName
            // Id dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get(NA_DEAL_RECORDTYPE_API_NAME).getRecordTypeId();
            // Id dealNARecordTypeId = NA_DEAL_RTID; //MN-06092021-US-0010019 

            for(EBH_Deal__c deal: listDealNew)
            {
                // if(deal.RecordTypeId == dealNARecordTypeId){continue;}  //MN-06092021-US-0010019 
                
                //TH:US-0013020:comment out
                /*if (deal.RecordTypeId != NA_DEAL_RTID) { //MN-06092021 - for Deal_V1 
                if( (mapDealOld.get(deal.Id).EBH_Status__c <> 'Negotiating' && deal.EBH_Status__c =='Negotiating') // change to Negotiating
                   || (mapDealOld.get(deal.Id).OwnerId <> deal.OwnerId && deal.OwnerId == UserInfo.getUserId()) ) //NK:19/06/2018: to match EPH-5266 
                    { continue; }
                    else if( mapDealOld.get(deal.Id).EBH_Status__c == 'Negotiating' &&  deal.EBH_Status__c <> 'Negotiating' )//change from Negotiating
                    { deal.addError(DEAL_LOCK_ERROR_MSG); }

                    if(deal.EBH_Status__c =='Negotiating') { deal.addError(DEAL_LOCK_ERROR_MSG); }
                }
                //MN-06092021-US-0010019 - for Deal_V2 that is Amendment Deal with Status = New only
                else if (deal.EBH_Status__c == 'New' && deal.Originating_Deal__c != null && deal.Amendment_Date__c != null) { deal.addError(NA_DEAL_LOCK_ERROR_MSG); }
                */
                //TH:US-0013020:add - deal.RecordTypeId == NA_DEAL_RTID
                if (deal.RecordTypeId == NA_DEAL_RTID && deal.EBH_Status__c == 'New' && deal.Originating_Deal__c != null && deal.Amendment_Date__c != null) { deal.addError(NA_DEAL_LOCK_ERROR_MSG); }
            }
            
        }
        
    }
    
    /*****************************************************************************************************************************
@ Method:        checkDealNotification
@ Version:       1.0
@ Author:          
@ Purpose:      EPH-6986 Deals - Reminder email to agree on planned deal
@               AC1) Send three reminder emails to seller and deal owner to increase likelihood that seller will click on "i agree" and we are legally complaint to execute the deal.
@               Triggerules:
@               When
@                   EBH_Status__c = Planned
@                   And EBH_DEALSITEID__C = 77
@                   And seller did not click on "i agree" (="Ich stimme zu" in the emails attached)
@                   And EBH_DealStartDate__c
@                       =48 hours before deal start date
@                       =24 hours before deals start date
@                       =12 hours before deal start date
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:    listDealNew: trigger.oldMap      
@               mapDealOld: trigger.new 
@   event   : before update
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12/03/2019 / Vadhanak Voun  / Created the  Method.
*****************************************************************************************************************************/
    public static void checkDealNotification(List<EBH_Deal__c> listDealNew,Map<Id,EBH_Deal__c> mapDealOld)
    {
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        if(!isDeal_V1(listDealNew)) return;
        
        List<EBH_Deal__c> listDealToSendMail = new List<EBH_Deal__c>();
        Long min12H = Long.valueOf(System.Label.Deal_Limit_Notification.split('_')[0]); //12h  
        Long max48H = Long.valueOf(System.Label.Deal_Limit_Notification.split('_')[1]); //48h  
        Set<String> setDealIdsForNext12H = new Set<String>(); 
        for(EBH_Deal__c deal : listDealNew)
        {   //1, Planned starts  
            if(deal.EBH_Status__c <>  mapDealOld.get(deal.Id).EBH_Status__c
               && (deal.EBH_DEALSITEID__c == '77' 
                   && deal.EBH_Status__c == EBH_ConstantsUtility.DEAL_STATUS_PLANNED 
                   && (deal.EBH_DealStartDate__c <> null && deal.EBH_DealStartDate__c >= Date.today()) //only furture deal
                  )
              )
            {  
                //deal.Trigger_Time_05__c = system.now().addHours(-1).addMinutes(4); //temp field to test
                
                deal.Check_Reminder__c = true; //trigger workflow for next 12H
                deal.Date_Planned__c = System.now(); // for tracking when deal becomes planned
                
            }else if(deal.Notify_Counter__c <> mapDealOld.get(deal.Id).Notify_Counter__c && deal.Notify_Counter__c>0  //from workflow after 12H
                     && deal.EBH_DEALSITEID__c == '77' 
                     && deal.EBH_Status__c == EBH_ConstantsUtility.DEAL_STATUS_PLANNED  //still not agree
                     && (deal.EBH_DealStartDate__c <> null && deal.EBH_DealStartDate__c >= Date.today()) //ensure Deal date/time not yet pass
                    )
            {
                Long durationInH = getDurationHour(deal); //between Now and DealStart DateTime 
                if(durationInH >= min12H && durationInH <=max48H) //in case Planned started then deal start in next 12h, then send mail 1 now 
                {
                    listDealToSendMail.add(deal);
                } 
                //deal.Trigger_Time_05__c = system.now().addHours(-1).addMinutes(4);  // temp field to test
                deal.Check_Reminder__c = false; //so furture can set to true
                deal.Date_LastCheck__c = System.now(); // for tracking
                setDealIdsForNext12H.add(deal.Id);
                
            }
        }
        
        if(!listDealToSendMail.isEmpty())
        {
            for(EBH_Deal__c deal : listDealToSendMail)
            {
                //trigger email alert from workflow
                if(deal.EBH_Subsidy__c <> null && deal.EBH_Subsidy__c >0)
                {
                    deal.TriggerEmailSubsidy__c = System.now(); 
                }else
                {
                    deal.TriggerEmailNoSubsidy__c = System.now();
                }
            }
        }
        
        if(!setDealIdsForNext12H.isEmpty())
        {
            checkReminder(setDealIdsForNext12H);
        }
    } 
    
    @future private static void checkReminder(Set<String> setDealIdsForNext12H)
    {
        List<EBH_Deal__c> listDeal = new List<EBH_Deal__c>();
        for(String dealId: setDealIdsForNext12H)
        {
            listDeal.add(new EBH_Deal__c(Id=dealId,Check_Reminder__c=true )); //trigger the workflow for next 12h
            
        }
        update listDeal;
    } 
    
    private static Long getDurationHour(EBH_Deal__c deal)
    {
        if(deal.EBH_DealStartDate__c <> null && deal.EBH_DealStartTime__c <> null)
        {
            DateTime dealStartDT = DateTime.newInstanceGmt(deal.EBH_DealStartDate__c, deal.EBH_DealStartTime__c); //GMT, to follow field Time.
            Long durationInMin = (((dealStartDT.getTime() - System.now().getTime()) /1000)/60)/60;  // to hour
            
            return  durationInMin;
        } 
        
        return -1;
    }
    
    /*****************************************************************************************************************************
@ Method:        assignSiteUrl
@ Version:       1.0
@ Author:          
@ Purpose:     save the Site URL to Deal field for workflow reference to send the link. e.g. EPH-7342 Deals Invoice Statement...
@               : e.g. https://.../response
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:    listDealNew: trigger.new     
@   event   : before insert, before update
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17/05/2019 / Vadhanak Voun  / Created the  Method.
@               : 06/11/2020 / Vadhanak Voun / US-0008590 - Improve Deal Invoice Upload Process
@                                           / Unique_Id_Ext__c: unique id using for external site
@               : 10/11/2021/ Sovantheany Dim / US-0010550 - [AU-Deals] AU Deal Start Time and End time
@               : 17/10/2022/ Sovantheany Dim / US-0012629 - Hide Standard Deals (V1 deals) on the Seller Portal for AU Seller
@               : 14/03/2023 / Bora Chhorn / US-0013086 - Hide Deal V1 for AU, IT and FR Sellers
*****************************************************************************************************************************/
    public static void assignSiteUrl(List<EBH_Deal__c> listDealNew)
    {
        String v1RecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V1').Id;
        for(EBH_Deal__c d: listDealNew)
        {
            if(d.SiteURL__c == null) d.SiteURL__c = ApexUtil.getSiteUrl('Deal_Acceptance');
            if(d.Unique_Id_Ext__c == null) d.Unique_Id_Ext__c = EncodingUtil.urlEncode(ApexUtil.genUniqueString(30), 'UTF-8');
            // 28/07/2021 / SRONG TIN / US-0009957 [SEP] NA Unsub Deal: New field for Deal Window custom related List
            d.Sub_Category_f__c = d.Sub_Category__c;
            //TH: US-0010550 : Set default time for AU deal
            if(trigger.isInsert && d.EBH_DealSiteId__c == '15'){
                d.EBH_DealStartTime__c = Time.newInstance(10, 0, 0, 0);
                d.EBH_DealEndTime__c = Time.newInstance(23, 59, 0, 0);
                //TH:US-0012629:update the field Hide in Seller Portal to True when the Deal V1 for Deal Site AU is created
                // BR-14-03-2023-US-0013086
                // if(d.RecordTypeId == v1RecordTypeId){
                //     d.Hide_in_Seller_Portal__c = true;
                // }
            }
        }
    }
    
    /*****************************************************************************************************************************
@ Method: blockDealStatus
@ Version: 1.0
@ Author:          
@ Purpose:  Block user from changing Deal Status to Verify Statement or Clarification Required Manually   
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:  Map<Id,EBH_Deal__c> oldMap, Map<Id,EBH_Deal__c> newMap
@ event : before insert, before update
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 28/08/2019 / Sreymeas Nao / Created the  Method.
*****************************************************************************************************************************/
    public static void blockDealStatus(Map<Id,EBH_Deal__c> oldMap, List<EBH_Deal__c> newlist){
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        if(!isDeal_V1(newlist)) return;

        Boolean isAdmin = (Userinfo.getprofileId()==EBH_ConstantsUtility.ADMIN_PROFILE_ID);
        if (oldMap != null && !oldMap.isEmpty()) {
            for (Id dealId : oldMap.keySet()) {
                EBH_Deal__c oldDeal = oldMap.get(dealId);
                EBH_Deal__c newDeal = new Map<Id,EBH_Deal__c>(newList).get(dealId);
                
                if (!isAdmin && !UPDATE_STATUS_SYS && oldDeal.EBH_Status__c != newDeal.EBH_Status__c && (newDeal.EBH_Status__c=='Verify Statement' || newDeal.EBH_Status__c=='Clarification Required')) {
                    newDeal.addError('You cannot manually change the deal status to Verify Statement or Clarification Required');
                }
            }
        }else{
            for (EBH_Deal__c oneLst : newList) {
                if (!isAdmin && !UPDATE_STATUS_SYS && (oneLst.EBH_Status__c=='Verify Statement' || oneLst.EBH_Status__c=='Clarification Required')) {
                    oneLst.addError('You cannot manually change the deal status to Verify Statement or Clarification Required');
                }
            }
        }
    }
    
    /*****************************************************************************************************************************
	@ Method: checkDealIdChanged
	@ Version: 1.0
	@ Author:          
	@ Purpose:  Get Images from ebay
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:  Map<Id,EBH_Deal__c> oldMap, Map<Id,EBH_Deal__c> newMap
	@ event : after insert, after update
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 2019 09 24 / DHE / Created the  Method.
	@				: 21/02/2020/ Vadhanak Voun / US-0007055 AU and EU] API Call to auto populate "Current seller price" in Deal
	@							separated the method for sharable
	*****************************************************************************************************************************/
    public static void checkDealIdChanged(List<EBH_Deal__c> newlist,map<id,EBH_Deal__c>oldMap){
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        if(!isDeal_V1(newlist)) return;

    	Boolean isNew = (oldMap==null || oldMap.isEmpty());
        map<id,EBH_Deal__c> mapDealImages = new map<id,EBH_Deal__c>();
        
        for (EBH_Deal__c d : newlist){
            
            if ((isNew && d.EBH_eBayItemID__c !=null) ||  //new 
                (!isNew && oldMap.containsKey(d.id) && d.EBH_eBayItemID__c != oldMap.get(d.id).EBH_eBayItemID__c && d.EBH_eBayItemID__c !=null)) // or update
            {
                mapdealimages.put(d.id,d);
            }
            
        }
        if(!mapdealimages.isEmpty())
        {
        	doProcessDealItems(mapDealImages.values());
        }
        
    }

    /*****************************************************************************************************************************
    @ Method:         updateDealInvoiceIsDealSiteUK
    @ Version:        1.0
    @ Author:         SRONG TIN
    @ Purpose:        US-0010453 - [UK-Deals] Deal Invoice - eBay billing address and VAT changes
    @ Event:		  isAfter update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<EBH_Deal__c> newlist,map<id,EBH_Deal__c>oldMap
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.10.2021 / SRONG TIN / Created the  Method.
                      19.10.2021 / SRONG TIN / US-0010453 / update the method.
    *****************************************************************************************************************************/
    public static void updateDealInvoiceIsDealSiteUK(List<EBH_Deal__c> newlist, Map<id,EBH_Deal__c>oldMap){
        Boolean isNew = (oldMap==null);
        Set<Id> dealIds = new Set<Id>();
        for (EBH_Deal__c d : newlist){
            if ((isNew && d.EBH_DealSiteId__c == '3' ) ||  //new 
                (!isNew && oldMap.containsKey(d.id) && d.EBH_DealSiteId__c != oldMap.get(d.id).EBH_DealSiteId__c && d.EBH_DealSiteId__c == '3')){
                    
                    dealIds.add(d.Id);
            }
            
        }
        List<EBH_DealInvoice__c> lstDealInvoice = new List<EBH_DealInvoice__c>();
        String vadId = System.Label.EBAY_VAT_FOR_UK;
        String address = System.Label.EBAY_BILLING_ADDRESS;
        for(EBH_DealInvoice__c dv: [select Id,eBay_VAT__c from EBH_DealInvoice__c where EBH_Deal__c IN :dealIds AND (eBay_VAT__c != :vadId OR eBay_Billing_address__c != :address)]){
            
            dv.eBay_VAT__c = vadId;
            //19.10.2021 / SRONG TIN :US-0010453
            dv.eBay_Billing_address__c = address;
            lstDealInvoice.add(dv);
            
        }
        if(!lstDealInvoice.isEmpty()){
            update lstDealInvoice;
        }
        
    }
    
    /*****************************************************************************************************************************
	@ Method: doProcessDealItems
	@ Version: 1.0
	@ Author:  vadhanak.voun        
	@ Purpose:  US-0007055 AU and EU] API Call to auto populate "Current seller price" in Deal
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:  List EBH_Deal__c
	@ event : sharing method for trigger and batch
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 2019 09 24 / DHE / Created the  Method.
	@				: 24/02/2020/ Vadhanak Voun / US-0007055 AU and EU] API Call to auto populate "Current seller price" in Deal
	@							/ moved into separated method for sharing
	*****************************************************************************************************************************/
    public static void doProcessDealItems(List<EBH_Deal__c> listDeals)
    {
    	 //maximum 20 calls per iteration
        Integer i=0;
        Map<Id,MiniDeal> tempMap = new map<id,MiniDeal>();
       
        for (EBH_Deal__c d:listDeals){
             
            tempmap.put(d.Id, new MiniDeal(d.Id,d.EBH_eBayItemID__c,d.EBH_DealSiteId__c,d.EBH_DealPrice__c)); 
            if (i++==20){
                call_eBayItemService(Json.serialize(tempMap));
                i=0;
                tempMap= new Map<id,MiniDeal>();
            }
        }
        if (!tempMap.isempty()){
            call_eBayItemService(Json.serialize(tempMap));
        }
    }
    
    //handle the type of the method to call asyn or directly to method
    // to avoid error furetur from batch, future from future...
    private static void call_eBayItemService (String serializezMap)
    {
    	if(System.isBatch() || System.isFuture() || System.isQueueable())
    	{
    		docall_eBayItemService(serializezMap);
    	}else
    	{
    		call_eBayItemServiceAsyn(serializezMap);
    	}
    }
    
    @future(callout=true)
    private static void call_eBayItemServiceAsyn (String serializezMap)
    {
    	docall_eBayItemService(serializezMap);
    }
    private static void docall_eBayItemService(String serializezMap)
    {
    	Map<Id,MiniDeal> tempMap = (Map<id,MiniDeal>)Json.deserialize(serializezMap, Map<id,MiniDeal>.class);
        Map<String,MiniDeal> reversemap = new map<string,MiniDeal>();
        String ItemIdsString ='';
        for (Id dealid : tempMap.keyset()){
            reverseMap.put(tempMap.get(dealId).itemId,tempMap.get(dealid));
        }
        for (String s : reversemap.keySet()){
            ItemIdsString+=s +',';
        }
        String siteId = reversemap.values()[0].siteId;
        ItemIdsString=ItemIdsString.substring(0,ItemIdsString.length()-1);

        //MN-10102022-US-0009568: This api now need to pass ebay token
        String eToken = (new EbayService.Access()).request_token(); 
        //https://open.api.ebay.com/shopping?callname=GetMultipleItems&responseencoding=JSON&appid=nocompan-0d57-4393-8376-d4b8cd404f63&siteid=77&version=967&ItemID=233121274562,372698562338
        HTTPWrapper.IRequest reqItem = new HTTPWrapper.SimpleRequest(Label.eBayImageService + '&siteid='+siteId+'&ItemID='+ ItemIdsString,'GET','',new Map<String,String>{'X-EBAY-API-IAF-TOKEN'=>eToken});
        // HTTPWrapper.IRequest reqItem = new HTTPWrapper.SimpleRequest(Label.eBayImageService + '&siteid='+siteId+'&ItemID='+ ItemIdsString,'GET','');
        //=====MN-10102022-US-0009568

    	SimpleeBayResponse respItem = new SimpleeBayResponse(reqItem);
    
        List<EBH_Deal__c> DealsToUpdate= new List<EBH_Deal__c>();
        
        if (respItem.statusCode==200){ 
            DealsToUpdate= processCallout(respItem.getResBody(),reversemap);
            
        }
        try{
            if (!DealsToUpdate.isempty()){
                update dealstoupdate;
            }
        }catch(Exception e){System.debug('Exception saving deals '  + e.getMessage());}
    }

    
    private static  List<EBH_Deal__c> processCallout(String resBody,Map<String,MiniDeal> reversemap){
        List<EBH_Deal__c> DealsToUpdate= new List<EBH_Deal__c>();
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(resBody);
        System.debug('**** results :: ' + results);
        if(results.get('Ack')+''=='Success')
        {
        	List<Object> items = (List<Object> )results.get(EBH_ConstantsUtility.DEALS_IMAGES_ITEM);
	        for (Object o : items){
	        	Map<String, Object> jItem = (Map<String, Object>) o;
            	String spictureURL;
	            String curPrice = ((Map<String, Object>)jItem.get('ConvertedCurrentPrice')).get('Value')+''; 
	            
	            String sitemId=(String)jItem.get(EBH_ConstantsUtility.DEALS_IMAGES_ITEMID);
	            String sgalleryURL=(String)jItem.get(EBH_ConstantsUtility.DEALS_IMAGES_GALLERYURL);
	            List<Object> pictures = (List<Object> )jItem.get(EBH_ConstantsUtility.DEALS_IMAGES_PICTUREURL);
	            if (pictures!=null && !pictures.isEmpty()){
	                spictureURL=(String)pictures.get(0);
	            }       
	            
	            if(reversemap.containsKey(sitemId))
	            {
	            	String dealID=reversemap.get(sitemId).dealId;
	            	Decimal dealPrice = reversemap.get(sitemId).dealPrice;
	            	DealsToUpdate.add (
	            			new EBH_Deal__c(
	            				id=dealID,GalleryURL__c=sgalleryURL,
	            				PictureURL__c=spictureURL,
	            				Current_Seller_Price__c=Decimal.valueOf(curPrice),
	            				EBH_Pricenotmatching__c = (dealPrice<>null && dealPrice <> Decimal.valueOf(curPrice))
	            				)
	            	); //NK:21/02/2020:US-0007055
	            }
	            
	        }
        }
        //MN-17102022-US-0009568
        else if (System.isBatch() && results.get('Ack')+''=='Failure') {

            List<Object> errors = (List<Object> ) results.get('Errors');
            
            for (Object o : errors) {

                Map<String, Object> obj_err = (Map<String, Object>) o;
                String errorMsg = (String) obj_err.get('LongMessage');

                throw new EBH_ScrapDeal.PriceMatchingAPIException(''+ errorMsg);                

            }
            
        }
        
        
        return DealsToUpdate;
    }
    
    /*****************************************************************************************************************************
@ Method:   sendClickAcceptDeal
@ Version:  1.0
@ Author: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:	US-0006971 [AU] Deals Accept - Send Deals Accept with/without Subsidy Template to AU Sellers
@ Logic 1 (Deal: StatusEQUALSPlanned) AND (Deal: Subsidy per Sold ItemGREATER THAN0) AND (Deal Site = AU)
@ THEN
@ send Email Template “AU Deal Template with Subsidy” to the AU Sellers and CC ->Record owner for all the Deals (1 or many) selected .
@ Logic 2 (Deal: StatusEQUALSPlanned) AND (Deal: Subsidy per Sold Item EQUALS 0) AND (Deal Site = AU)
@ THEN 
@ send Email Template “AU Deal Template without Subsidy” to the AU Sellers and CC ->Record owner for all the Deals (1 or many) selected.
@ Event:	Before Update
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:     List<EBH_Deal__c> listNew , Map<Id,EBH_Deal__c> mapOld
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.12.2019 / Sovantheany dim / Created the  Method
					19/02/2021 / Sovantheany dim/ move logic to process builder "Deals Emails In Local Language": US-0009158 - [Hypercare] [AU] [Deals] Send Deal Contract email to the seller when changing the status to Planned
*****************************************************************************************************************************/
    /*public static void sendClickAcceptDeal(List<EBH_Deal__c> listNew, Map<Id,EBH_Deal__c> mapOld)
    {
        Set<String> sDealId = new Set<String>();
        for(EBH_Deal__c deal : listNew)
        {
        	System.debug('<<<deal:'+deal);
            EBH_Deal__c oldDeal = mapOld.get(deal.Id);
            if(deal.EBH_Status__c != oldDeal.EBH_Status__c && deal.EBH_Status__c == EBH_ConstantsUtility.DEAL_STATUS_PLANNED &&
               deal.DateAcceptSend__c != null && deal.DateAcceptSend__c != oldDeal.DateAcceptSend__c &&
               deal.EBH_Subsidy__c != null && deal.EBH_DealSiteId__c == '15'){
                   sDealId.add(deal.Id);
               }
        }
        System.debug('<<<sDealId:'+sDealId);
        if(sDealId.isEmpty()) return;
        Set<String> sEmailTemplate = new Set<String>{EBH_ConstantsUtility.EMAILTEMPLATE_AU_WIHT_SUBSIDY,EBH_ConstantsUtility.EMAILTEMPLATE_AU_WIHTOUT_SUBSIDY};
            String sWhere = ' Where DeveloperName IN: sEmailTemplate';
        Map<String,EmailTemplate> mapEmailTemplates = new Map<String,EmailTemplate>();
        String bodyText;
        for(EmailTemplate et : Database.query(EBH_ConstantsUtility.SOQLEMAIL_TEMPLATES+sWhere)){
            mapEmailTemplates.put(et.DeveloperName,et);
            bodyText = et.Body;
        }
        
        if(mapEmailTemplates.isEmpty()) return;
        List<Messaging.SingleEmailMessage> listEmail = new List<Messaging.SingleEmailMessage>();
        String whereDealString = ' where id IN: sDealId';
        List<Task> lstTask = new List<Task>();
        for(EBH_Deal__c deal : Database.query(EBH_ConstantsUtility.SOQL_DEAL + whereDealString)){
            EmailTemplate et = deal.EBH_Subsidy__c > 0 ? mapEmailTemplates.get(EBH_ConstantsUtility.EMAILTEMPLATE_AU_WIHT_SUBSIDY) : mapEmailTemplates.get(EBH_ConstantsUtility.EMAILTEMPLATE_AU_WIHTOUT_SUBSIDY);
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{Test.isRunningTest()?'test@test.com':deal.EBH_SellerEmail__c});
            mail.setCcAddresses(new String[]{Test.isRunningTest()?'test2@test.com':deal.Owner.Email});
            mail.setSenderDisplayName('Hive Support');
            mail.setSubject(et.subject);
            mail.setBccSender(false);
            mail.setUseSignature(false); 
            String bodyHtml = doMearchClickDealBody(deal,et.HtmlValue);
            mail.setHtmlBody(bodyHtml);
            listEmail.add(mail);
            lstTask.add(createTaskLogDeal(deal,doMearchClickDealBody(deal,bodyText),deal.EBH_SellerEmail__c,deal.Owner.Email,et.subject));
        }
        System.debug('<<<listEmail:'+listEmail);
        if(!listEmail.isEmpty())
        {
            Messaging.sendEmail(listEmail);
            insert lstTask;
        }
    }*/
    
    private static String doMearchClickDealBody(EBH_Deal__c deal,String htmlBody)
    { 
        String acceptURl = ApexUtil.getSiteUrl('Deal_Acceptance')+'?restype='+EBH_TrackingResponseController.CONRACT_DEAL_URL_TYPE+'&id='+deal.Id+'&'+EBH_TrackingResponseController.REDIRECT_URL;
        return htmlBody.replace('{eBaySellerID}',deal.EBH_BusinessName__c != null ? deal.EBH_BusinessName__r.Name+'':'')
            .replace('{DealStartTime}',ApexUtil.formatTime(deal.EBH_DealStartTime__c)+'')
            .replace('{DealEndTime}',ApexUtil.formatTime(deal.EBH_DealEndTime__c)+'')
            .replace('{DealStartDate}',deal.EBH_DealStartDate__c == null ? '' : deal.EBH_DealStartDate__c.format())
            .replace('{DealEndDate}',deal.EBH_DealEndDate__c == null ? '' : deal.EBH_DealEndDate__c.format())
            .replace('{!EBH_Deal__c.Shipping_Rate_Funding__c}',ApexUtil.checkNull(deal.Shipping_Rate_Funding__c)+'')
            .replace('{!EBH_Deal__c.Additional_Terms_Override_Of_Agreement__c}',ApexUtil.checkNull(deal.Additional_Terms_Override_Of_Agreement__c)+'')
            .replace('{!EBH_Deal__c.EBH_ProductTitle__c}',ApexUtil.checkNull(deal.EBH_ProductTitle__c)+'')
            .replace('{!EBH_Deal__c.EBH_EAN__c}',ApexUtil.checkNull(deal.EBH_EAN__c)+'')
            .replace('{!EBH_Deal__c.EBH_DealPrice__c}',ApexUtil.checkNull(deal.EBH_DealPrice__c)+'')
            .replace('{!EBH_Deal__c.EBH_RRPWASPrice__c}',ApexUtil.checkNull(deal.EBH_RRPWASPrice__c)+'')
            .replace('{!EBH_Deal__c.EBH_Quantity__c}',ApexUtil.checkNull(deal.EBH_Quantity__c)+'')
            .replace('{!EBH_Deal__c.EBH_Subsidy__c}',ApexUtil.checkNull(deal.EBH_Subsidy__c)+'')
            .replace('{!EBH_Deal__c.EBH_MaximumPurchases__c}',ApexUtil.checkNull(deal.EBH_MaximumPurchases__c)+'')
            .replace('{LegalEntity}', ApexUtil.checkNull(deal.CompanyName__c)+'')
            .replace('{ABNVATNumber}', deal.EBH_BusinessName__c != null && deal.EBH_BusinessName__r.EBH_VATNumber__c != null ? deal.EBH_BusinessName__r.EBH_VATNumber__c +'': '')
            .replace('{StreetName}', deal.EBH_BusinessName__c != null && deal.EBH_BusinessName__r.ParentId != null && deal.EBH_BusinessName__r.Parent.EBH_BillingStreet__c != null ? deal.EBH_BusinessName__r.Parent.EBH_BillingStreet__c : '')
            .replace('{City}', deal.EBH_BusinessName__c != null && deal.EBH_BusinessName__r.ParentId != null && deal.EBH_BusinessName__r.Parent.EBH_BillingCity__c != null ? deal.EBH_BusinessName__r.Parent.EBH_BillingCity__c : '')
            .replace('{Zip}', deal.EBH_BusinessName__c != null && deal.EBH_BusinessName__r.ParentId != null && deal.EBH_BusinessName__r.Parent.EBH_BillingPostalCode__c != null ? deal.EBH_BusinessName__r.Parent.EBH_BillingPostalCode__c : '')
            .replace('{Country}', deal.EBH_BusinessName__c != null && deal.EBH_BusinessName__r.ParentId != null && deal.EBH_BusinessName__r.Parent.EBH_BillingCountry__c != null ? deal.EBH_BusinessName__r.Parent.EBH_BillingCountry__c : '')
            .replace('{clickMeUrl}',acceptURl)
            .replace('{!EBH_Deal__c.EBH_LocalDealFormat__c}',deal.EBH_LocalDealFormat__c == null ? '':deal.EBH_LocalDealFormat__c+'')
            .replace('{!EBH_Deal__c.EBH_ProductTitle__c}',deal.EBH_ProductTitle__c == null ? '':deal.EBH_ProductTitle__c+'')
            .replace('{!EBH_Deal__c.EBH_eBayItemID__c}',deal.EBH_eBayItemID__c == null ? '':deal.EBH_eBayItemID__c+'')
            .replace('{!EBH_Deal__c.EBH_DealStartDate__c}',deal.EBH_DealStartDate__c == null ? '':deal.EBH_DealStartDate__c.format())
            .replace('{!EBH_Deal__c.Id}',deal.Id)
            .replace('!EBH_Deal__c.Id',deal.Id)
            .replace('{!EBH_Deal__c.EBH_BusinessName__c}',deal.EBH_BusinessName__c == null ? '':deal.EBH_BusinessName__r.Name+'')
            .replace('{!EBH_Deal__c.EBH_Quantity__c}',ApexUtil.checkNull(deal.EBH_Quantity__c)+'')
            .replace('{!EBH_Deal__c.EBH_DealEndDate__c}',deal.EBH_DealEndDate__c==null ? '':deal.EBH_DealEndDate__c.format())
            .replace('{!EBH_Deal__c.EBH_RRPWASPrice__c}',ApexUtil.checkNull(deal.EBH_RRPWASPrice__c)+'')
            .replace('{!EBH_Deal__c.EBH_SellerPrice__c}',ApexUtil.checkNull(deal.EBH_SellerPrice__c)+'')
            .replace('{!EBH_Deal__c.EBH_DealPrice__c}',ApexUtil.checkNull(deal.EBH_DealPrice__c)+'')
            .replace('{!EBH_Deal__c.EBH_Subsidy__c}',ApexUtil.checkNull(deal.EBH_Subsidy__c)+'')
            .replace('{!EBH_Deal__c.Subsidy_Planned_Gross__c}',ApexUtil.checkNull(deal.Subsidy_Planned_Gross__c)+'')
            .replace('{!EBH_Deal__c.EBH_CommentfromeBaySourcer__c}',deal.EBH_CommentfromeBaySourcer__c==null ? '':deal.EBH_CommentfromeBaySourcer__c+'')
            .replace('{!EBH_Deal__c.EBH_MarketingTitle__c}',deal.EBH_MarketingTitle__c==null ? '':deal.EBH_MarketingTitle__c)
            .replace('{!EBH_Deal__c.EBH_SubsidyMax__c}',ApexUtil.checkNull(deal.EBH_SubsidyMax__c)+'')
            .replace('{!EBH_Deal__c.CompanyName__c}',ApexUtil.checkNull(deal.CompanyName__c)+'')
            .replace('{!EBH_Deal__c.EBH_DealStartTime__c}',ApexUtil.formatTime(deal.EBH_DealStartTime__c)+'')
            .replace('{!EBH_Deal__c.EBH_DealEndTime__c}',ApexUtil.formatTime(deal.EBH_DealEndTime__c)+'')
            .replace('{!EBH_Deal__c.eBay_Seller_Name__c}',deal.EBH_BusinessName__c != null ? deal.EBH_BusinessName__r.Name+'':'')
            .replace('{!EBH_Deal__c.SellerVATNumber__c}',deal.SellerVATNumber__c == null ? '':deal.SellerVATNumber__c+'')
            .replace('{!EBH_Deal__c.SellerAddress__c}',deal.SellerAddress__c == '<br><br><br>' ? '':(deal.SellerAddress__c.replace('<br>', '\n'))+'')
            .replace('{!EBH_Deal__c.YourFundingAmountPerUnit__c}',ApexUtil.checkNull(deal.YourFundingAmountPerUnit__c)+'')//LA:16-09-2021:US-0010358 
            ;
    }
    
    /*
https://hive.lightning.force.com/apex/GoToUserStory?US-0007145
*/
    public static void OverwriteClone(List<EBH_Deal__c> newList){
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        if(!isDeal_V1(newList)) return;

        for (EBH_Deal__c d : newList){
            if (d.isClone()){
                  d=CloneDealCustom(d);
            }
        }
        
    }
    
    @TestVisible
    private static EBH_Deal__c CloneDealCustom (EBH_Deal__c d){
        
        String[] types = new String[]{'EBH_Deal__c'};            
            Set<String> NoCopyFields = new set<String>{'EBH_DealPrice__c'.toUpperCase()};
                Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> M = Schema.SObjectType.EBH_Deal__c.fields.getMap();
        
        
        EBH_Deal__c cloned = new EBH_Deal__c();
        for (String s : M.keyset()){
            Schema.DescribeFieldResult obj= M.get( s ).getDescribe();
            String fieldName=obj.getName();
            if (EBH_ConstantsUtility.DEAL_CLONE_FIELDS_TO_COPY.contains(fieldName) && obj.isUpdateable ()){      
                cloned.put(fieldName,d.get(fieldName));
            }else{
                if (obj.isUpdateable() ){
                    cloned.put(fieldName,obj.defaultvalue);  
                }
                
                
            }
        }
        cloned.EBH_Status__c=EBH_ConstantsUtility.DEAL_STATUS_NEW;
        
        return cloned;
    }
    
   class MiniDeal{
    	String dealId;
    	String itemId;
    	String siteId;
    	Decimal dealPrice;
    	public MiniDeal(String dealId,String itemId,String siteId,Decimal dealPrice)
    	{
    		this.itemId = itemId;
    		this.siteId = siteId;
    		this.dealId = dealId;
    		this.dealPrice = dealPrice;
    	}
    }
    
    class SimpleeBayResponse extends HTTPWrapper.AbstractResponse{
        
        public SimpleeBayResponse(HTTPWrapper.IRequest req)
        {
            super(req); 
            excecute();
        }
        public override String getMockedBody()
        {
            return 
			'{"Timestamp":"2020-02-24T12:24:49.439Z","Ack":"Success","Build":"E1139_CORE_APILW_19143404_R1","Version":"1139","Item":[{"ItemID":"233121274562","EndTime":"2020-03-04T13:17:38.000Z","ViewItemURLForNaturalSearch":"https://www.ebay.de/itm/Oberhitzegrill-Hochtemperaturgrill-Gasgrill-Steakgriller-BEEF-BBQ-800-Edelstahl-/233121274562","ListingType":"FixedPriceItem","Location":"Bad Segeberg","GalleryURL":"https://thumbs3.ebaystatic.com/pict/2331212745628080_88.jpg","PictureURL":["https://i.ebayimg.com/00/s/MTQxN1gxNDE3/z/pNAAAOSwxaNeQ65v/$_1.JPG?set_id=2","https://i.ebayimg.com/00/s/MTQxN1gxNDE3/z/QisAAOSwaSheQ65y/$_1.JPG?set_id=2","https://i.ebayimg.com/00/s/MTQxN1gxNDE3/z/XgAAAOSwxOReQ651/$_1.JPG?set_id=2","https://i.ebayimg.com/00/s/MTQxN1gxNDE3/z/QMsAAOSwhLReQ654/$_1.JPG?set_id=2","https://i.ebayimg.com/00/s/MTQxN1gxNDE3/z/gHYAAOSw7FFeQ657/$_1.JPG?set_id=2","https://i.ebayimg.com/00/s/MTQxN1gxNDE3/z/socAAOSwkNReQ65-/$_1.JPG?set_id=2","https://i.ebayimg.com/00/s/MTQxN1gxNDE3/z/q4YAAOSwOHVeQ66C/$_1.JPG?set_id=2","https://i.ebayimg.com/00/s/MTQxN1gxNDE3/z/LI0AAOSwYPpeQ66F/$_1.JPG?set_id=2","https://i.ebayimg.com/00/s/MTQxN1gxNDE3/z/8NkAAOSwgqZeQ66J/$_1.JPG?set_id=2","https://i.ebayimg.com/00/s/MTQxN1gxNDE3/z/YUcAAOSwfiReQ66M/$_1.JPG?set_id=2","https://i.ebayimg.com/00/s/MTQxN1gxNDE3/z/9gcAAOSwVR9eQ66a/$_1.JPG?set_id=2"],"PrimaryCategoryID":"151621","PrimaryCategoryName":"Garten & Terrasse:Grills, Heizstrahler & Picknickzubehör:Grills","BidCount":0,"ConvertedCurrentPrice":{"Value":109.99,"CurrencyID":"EUR"},"ListingStatus":"Active","TimeLeft":"P9DT52M49S","Title":"Oberhitzegrill Hochtemperaturgrill Gasgrill Steakgriller BEEF BBQ 800° Edelstahl","HitCount":1088586,"Country":"DE","AutoPay":false,"ConditionID":1000,"ConditionDisplayName":"Neu","QuantityAvailableHint":"MoreThan","QuantityThreshold":10,"DiscountPriceInfo":{"OriginalRetailPrice":{"Value":499.99,"CurrencyID":"EUR"},"PricingTreatment":"STP","SoldOneBay":false,"SoldOffeBay":false}}]}';
        }
		
    } 

    // SRM US-0006911 - Deals - Attach Deals Contracts to Deal Record
    private static Task createTaskLogDeal(EBH_Deal__c deal, String bodyText, String addr, String cc, String Subject) {
        String description;
        if(cc==null){
            description = 'To: '+addr+'\n'+
            'Subject: '+Subject+'\n'+
            'Body: \n'+bodyText;
        }else{
            description = 'To: '+addr+'\n'+
            'CC: '+ cc +'\n'+ 
            'Subject: '+Subject+'\n'+
            'Body: \n'+bodyText;
        }
		
		Task t = new Task();
    	t.Subject = 'Email: '+Subject;
    	t.WhatId = deal.Id;
    	t.Status = 'Completed';
    	t.ActivityDate = System.today();
    	t.Description = description;
    	t.IsVisibleInSelfService = false;
    	t.TaskSubtype = 'Email';
    	t.RecordTypeId = ApexUtil.getRecordTypeByName('Task','Standard_Task').Id;
		t.Log_Task__c = true;

		return t;
    }
    
    /*****************************************************************************************************************************
    @ Method:   createEmailLog
    @ Version:  1.0
    @ Author: 	Sreymeas Nao (sreymeas.nao@gaea-sys.com)
    @ Purpose:	AC1) As any user when I am on a deal record and send out a classic template 
    @           we ensure that this is saved as an activity on the deal record (see pagelayout mock up) 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<EBH_Deal__c> listNew
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 07.05.2020 / Sreymeas Nao / Created the  Method
                      19.10.2021 / Sambath Seng / Add more condition for Status Seller Invite US-0010595 - [DE-Deals-Fulfillment] Attach email in activity history when the status is set to Fulfillment Invite
    *****************************************************************************************************************************/
    @InvocableMethod
    public static void createEmailLog(List<EBH_Deal__c> listNew) {
        List<Task> lstTask = new List<Task>();
        Set<Id> dealId = new Set<Id>();
        //find the email template name to query from the list of deals
        Set<String> setTemplateToQuery = new Set<String>();
        for(EBH_Deal__c deal : listNew){
            //Start-SB 19/10/2021 US-0010595
            String keyMap = '';
            if(deal.EBH_DealSiteId__c == SITE_DE && deal.EBH_Status__c == DEAL_STATUS_SELLERINVITE){
                keyMap = deal.EBH_DealSiteId__c + '_'+ deal.EBH_Status__c;
            } else {
                keyMap = deal.EBH_DealSiteId__c + '_'+ (deal.EBH_Subsidy__c > 0);
            }
            if(mapDealEmailTemplates.containsKey(keyMap)){
                setTemplateToQuery.add(mapDealEmailTemplates.get(keyMap));
                dealId.add(deal.Id);
            }
            //End-SB 19/10/2021 US-0010595
        }

        //query coressponding template
        Map<String,EmailTemplate> mapTemplate = new Map<String,EmailTemplate>();
        for(EmailTemplate et: Database.query(EBH_ConstantsUtility.SOQLEMAIL_TEMPLATES+' where DeveloperName IN: setTemplateToQuery')){
            mapTemplate.put(et.DeveloperName,et);
        }

        //process task creation from list deal with correct template
        //old sql EBH_ConstantsUtility.SOQL_DEAL 
        for(EBH_Deal__c deal : Database.query(DEAL_SOQL+ ' where Id IN :dealId')){
            //Start-SB 19/10/2021 US-0010595
            String keyMap = '';
            String templateName = '';
            if(deal.EBH_DealSiteId__c == SITE_DE && deal.EBH_Status__c == DEAL_STATUS_SELLERINVITE){
                keyMap = deal.EBH_DealSiteId__c + '_'+ deal.EBH_Status__c;
                templateName = mapDealEmailTemplates.get(keyMap);
            }else{
                keyMap = deal.EBH_DealSiteId__c + '_'+ (deal.EBH_Subsidy__c > 0);
                templateName = mapDealEmailTemplates.get(keyMap);
            }
            if(mapTemplate.containsKey(templateName)){
                EmailTemplate et =  mapTemplate.get(templateName);
                lstTask.add(createTaskLogDeal(deal,doMearchClickDealBody(deal,et.body),deal.EBH_SellerEmail__c,deal.Owner.Email,doMearchClickDealBody(deal,et.subject)));
            }	
            //End-SB 19/10/2021 US-0010595
        }

        insert lstTask;
    }


    
    /*****************************************************************************************************************************
    @ Method:   checkDuplicateListingId
    @ Author: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	US-0008088 - [US]* Bulk Creation of Deal Records from CSV Upload
	@		    
    @ Event:	Before Update, Before Create
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     Map<Id, EBH_Deal__c> mOldDeal, List<EBH_Deal__c> newDeal
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 07/10/2020 / Sovantheany Dim / Created the  Method
   	@ 28/12/2020 : move logic to checkDuplicate()
    *****************************************************************************************************************************/
    /*public static void checkDuplicateListingId(Map<Id, EBH_Deal__c> mOldDeal, List<EBH_Deal__c> newDeals){
    	Boolean isNew = (mOldDeal==null || mOldDeal.isEmpty());
    	Id dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get(NA_DEAL_RECORDTYPE_API_NAME).getRecordTypeId();
    	set<Date> sdealStartDate = new set<Date>();
    	set<Date> sdealEndDate = new set<Date>();
    	set<String> sdealeBayItemId = new set<String>();
    	List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
    	for(EBH_Deal__c newDeal : newDeals){
    		if(newDeal.RecordTypeId != dealNARecordTypeId || newDeal.EBH_eBayItemID__c == null) continue;
    		if((isNew) || 
    		(!isNew && mOldDeal.containsKey(newDeal.Id) && (mOldDeal.get(newDeal.Id).EBH_eBayItemID__c != newDeal.EBH_eBayItemID__c 
    		|| mOldDeal.get(newDeal.Id).RecordTypeId != newDeal.RecordTypeId
    		|| mOldDeal.get(newDeal.Id).EBH_DealStartDate__c != newDeal.EBH_DealStartDate__c 
    		|| mOldDeal.get(newDeal.Id).EBH_DealEndDate__c != newDeal.EBH_DealEndDate__c))){
    			sdealStartDate.add(newDeal.EBH_DealStartDate__c);
    			sdealEndDate.add(newDeal.EBH_DealEndDate__c);
    			sdealeBayItemId.add(newDeal.EBH_eBayItemID__c);
    			lstDeal.add(newDeal);
    		}
    	}
    	Map<String,EBH_Deal__c> mapDeal = new Map<String,EBH_Deal__c>();
    	String whereStr = ' where RecordTypeId =: dealNARecordTypeId AND EBH_eBayItemID__c IN: sdealeBayItemId AND EBH_DealStartDate__c IN: sdealStartDate AND EBH_DealEndDate__c IN: sdealEndDate';
    	for(EBH_Deal__c deal : Database.query(DEAL_SOQL+whereStr)){
    		String key = deal.RecordTypeId+'_'+deal.EBH_eBayItemID__c+'_'+deal.EBH_DealStartDate__c+'_'+deal.EBH_DealEndDate__c;
    		mapDeal.put(key,deal);
    	}
    	if(!mapDeal.isEmpty()){
    		for(EBH_Deal__c deal : lstDeal){
    			String key = deal.RecordTypeId+'_'+deal.EBH_eBayItemID__c+'_'+deal.EBH_DealStartDate__c+'_'+deal.EBH_DealEndDate__c;
    			if(mapDeal.containskey(key)){
    				deal.addError(System.label.Error_Duplicate_Listing_Id+deal.EBH_eBayItemID__c);
    			}
    		}
    	}
    }*/
    

        /*
    29/3/2018
    When Deal Status updated to In Approval
    Notify Merchant Approver on the Deal that a Deal(s) are ready for approval
    If there are multiple deals for same Approver only send one notification
    Use NA_Deals_Notify_Approvals for the email tempalte
    */
    /*********************************************************************************************************************************
    @ Method:         notifyMerchantApproverDealsReady4approval
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008230
    @                 It was migrated from join instance with original name: Deal_Handler.notifyMerchantApproverDealsReady4approval
    @                 send email to Merchant approver when status = 'In Approval'
    @ Event:		  after update of trigger
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	oldDealMap: old deal record, newDealMap: new deal record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.10.2020 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.10.2020 / Sophal Noch / US-0008618 update the method by calling other class method, SubmitForApprovalController.sendEmaiToApprovers.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06.04.2021 / Sophal Noch / US-0009353 disable because we use apex controller 'SubmitForApprovalController' to handler 
    *********************************************************************************************************************************/
    // public static void notifyMerchantApproverDealsReady4approval(Map<Id, EBH_Deal__c> oldDealMap, Map<Id, EBH_Deal__c> newDealMap) {
    //     // SetId Of Merchant Approver
    //     Set<Id> setApproverId = new Set<Id>();
    //     Map<Id,SubmitForApprovalController.UserApprovalDetail> mapUserIdToDeal = new map<Id,SubmitForApprovalController.UserApprovalDetail>();
    //     for (Id dId : oldDealMap.keySet()) {
    //         EBH_Deal__c oldDeal = oldDealMap.get(dId);
    //         EBH_Deal__c newDeal = newDealMap.get(dId);
    //         if (oldDeal.EBH_Status__c != newDeal.EBH_Status__c && newDeal.EBH_Status__c == SubmitForApprovalController.DEAL_IN_APPROVAL_STATUS) {
    //             if(newDeal.Merchant_Approver__c != null){
    //                 setApproverId.add(newDeal.Merchant_Approver__c);
    //                 mapUserIdToDeal = SubmitForApprovalController.setUpUserApprovalDetail(newDeal.Merchant_Approver__c,newDeal,mapUserIdToDeal);
    //             }
                
    //         }
    //     }

    //     if(!setApproverId.isEmpty()){
    //         SubmitForApprovalController.sendEmaiToApprovers(setApproverId,mapUserIdToDeal); //US-0008618 reuse from other class method
    //     }

    // }
    
    /*********************************************************************************************************************************
    @ Method:         checkDuplicate
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0008846 - [NA] Migrate JOIN NA Deals Trigger and related Classes to Hive
    @ Event:		  before insert, before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	oldDealMap: old deal record, newDealMap: new deal record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  28.12.2020 / Sovantheany Dim / Created the method, migrated from join instance 
                       23-11-2021 / SRONG TIN / Update the Method : US-0010751 - [NA Deals] Subsidized Deals will override Unsubsidized Deals
                       18-03-2022 / Sovantheany Dim / update the Method: US-0010138 - enabling Sellers to create new Deal for rejected existing Deal with Item ID
                       08/09/2022 / Sovantheany Dim / update the Method: US-0012281 - Validation and upload of Deals
                       30/11/2022 / Sovantheany Dim / update the Method: US-0012975 - Validation of Deals
                       31/03/2023 / Sovantheany Dim / US-0013466 - Validation of PM Deals check duing upload
                       21/03/2025 / Vimean Heng / US-0016717 - Contract Amendment Process - No Change in Subsidy
    *********************************************************************************************************************************/
    public static void checkDuplicate(List<EBH_Deal__c> newDeals, Map<id,EBH_Deal__c>oldDealsMap) {
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        // SRONG TIN 09-July-2021, US-0009650, , Adding condition to specific recordtype of method : isDeal_V3
        //TH:08/09/2022:US-0012281 : Adding condition to specific recordtype of method : isDeal_PM
        if(!isDeal_V2(newDeals) && !isDeal_V3(newDeals) && !isDeal_PM(newDeals)) return;
    	Boolean isNew = (oldDealsMap==null || oldDealsMap.isEmpty());
    	Map<Id,List<EBH_Deal__c>> dealstocheck = new Map<Id,List<EBH_Deal__c>>();
        Set<String> itemids = new Set<String>();
        Set<String> dealIds = new Set<String>();
        Map<String,EBH_Deal__c> mapDuplDeal = new Map<String,EBH_Deal__c>();
        Date MaxDate;
        Date MinDate;      
    	for (EBH_Deal__c d : newDeals) {
            // SRONG TIN | 23.11.2021 | US-0010751
            dealIds.add(d.Id);

    		if (d.EBH_BusinessName__c != null && d.EBH_eBayItemID__c != null && d.EBH_DealStartDate__c != null && d.EBH_DealEndDate__c != null) {
    			if(isNew || (!isNew && (d.EBH_eBayItemID__c != oldDealsMap.get(d.Id).EBH_eBayItemID__c 
    			|| d.EBH_DealStartDate__c != oldDealsMap.get(d.Id).EBH_DealStartDate__c || d.EBH_DealStartTime__c != oldDealsMap.get(d.Id).EBH_DealStartTime__c 
    			|| d.EBH_DealEndDate__c != oldDealsMap.get(d.Id).EBH_DealEndDate__c || d.EBH_DealEndTime__c != oldDealsMap.get(d.Id).EBH_DealEndTime__c))){
    				DateTime dStart = getDateTime(d.EBH_DealStartDate__c, d.EBH_DealStartTime__c);
                    DateTime dEnd = getDateTime(d.EBH_DealEndDate__c, d.EBH_DealEndTime__c);
                    
                    //check duplicated on current Created record if we mass insert
                    String keyDup = d.EBH_BusinessName__c + '/' + d.EBH_eBayItemID__c;
                    if(mapDuplDeal.containsKey(keyDup)){
                        EBH_Deal__c dupDeal = mapDuplDeal.get(keyDup);
                        
                        DateTime dupStart = getDateTime(dupDeal.EBH_DealStartDate__c, dupDeal.EBH_DealStartTime__c);
                        DateTime dupEnd = getDateTime(dupDeal.EBH_DealEndDate__c, dupDeal.EBH_DealEndTime__c);

                        if(d.EBH_DealStartDate__c != null && d.EBH_DealEndDate__c != null && dupDeal.EBH_DealStartDate__c != null && dupDeal.EBH_DealEndDate__c != null &&
                        ((dStart >= dupStart && dStart <= dupEnd) || 
                         (dEnd   >= dupStart && dEnd   <= dupEnd) || 
                         (dStart <= dupStart && dEnd   >= dupEnd) 
                        )){     
                            d.addError(Label.DD_DuplicateError);
                        }
                    }
                    mapDuplDeal.put(keyDup,d);
                    if(Mindate == null || d.EBH_DealStartDate__c < Mindate) MinDate = d.EBH_DealStartDate__c;
                    if(MaxDate == null || d.EBH_DealEndDate__c > MaxDate) MaxDate = d.EBH_DealEndDate__c;                   
                            
                    // eBay_Seller__c
                    String key = d.EBH_BusinessName__c;
                    List<EBH_Deal__c> deals = dealstocheck.get(key);
                    if (deals==null) {
                        deals = new List<EBH_Deal__c>();
                        
                    }
                    deals.add(d);
                    dealstocheck.put(key,deals);
                    
                    // add the items id
                    itemids.add(d.EBH_eBayItemID__c);
    			}
    		}
            
    	}
    	// load all deals with same dealers
        if (!dealstocheck.keyset().isEmpty()) {
            // SRONG TIN | 23.11.2021 | US-0010751 // TH: 18-03-2022:US-0010138:add Reject in Query
            Set<Id> idsNaUnsubDeals = new Set<Id>();
            //MN-22032023-US-0012628 - Including status "Seller Cancelled" into the excluding status and move fixed status text into SET variables
            Set<String> sStatusToExclude = new Set<String> {
                DEAL_STATUS_CANCELLED, DEAL_STATUS_REJECTED, DEAL_STATUS_SELLER_REJECTED, DEAL_STATUS_INTERNALLY_REJECTED, DEAL_STATUS_EXPIRED, DEAL_STATUS_SELLER_CANCELLED
            };
            //TH:US-0013466 - add condition : PM_Status__c !=: DCA_STATUS_CANCELLED
        	for (EBH_Deal__c d : [Select Id, RecordTypeId, Name, EBH_BusinessName__c, EBH_eBayItemID__c, EBH_DealStartDate__c, EBH_DealEndDate__c, EBH_DealStartTime__c, EBH_DealEndTime__c, EBH_Status__c, Cancellation_Reason__c
                                from EBH_Deal__c 
                                where Id not in:dealIds and EBH_eBayItemID__c in:itemids and EBH_BusinessName__c in : dealstocheck.keyset() and EBH_DealEndDate__c != null and EBH_DealStartDate__c != null and
                                    (EBH_DealEndDate__c >= :MinDate OR (EBH_DealStartDate__c >= :MinDate AND EBH_DealStartDate__c <= :MaxDate)) and
                                    EBH_Status__c NOT IN:sStatusToExclude and PM_Status__c !=: DCA_STATUS_CANCELLED LIMIT 50000]) 
                                    //EBH_Status__c NOT IN ('Cancelled','Rejected', 'Seller Rejected', 'Internally Rejected' ,'Expired') LIMIT 50000]) 
            {
            	String key = d.EBH_BusinessName__c;
                
                DateTime dStart = getDateTime(d.EBH_DealStartDate__c, d.EBH_DealStartTime__c);
                DateTime dEnd = getDateTime(d.EBH_DealEndDate__c, d.EBH_DealEndTime__c);
                
                 
                List<EBH_Deal__c> deals = dealstocheck.get(key);
                                    	
                for (EBH_Deal__c newdeal : deals) {
                    
                    DateTime newDealStart = getDateTime(newdeal.EBH_DealStartDate__c, newdeal.EBH_DealStartTime__c);
                    DateTime newDealEnd   = getDateTime(newdeal.EBH_DealEndDate__c, newdeal.EBH_DealEndTime__c);
                    
                    if (newdeal.EBH_Status__c != DEAL_STATUS_IN_AMENDMENT && newdeal.EBH_DealStartDate__c != null && 
                        newdeal.EBH_DealEndDate__c != null &&
                        newdeal.EBH_eBayItemID__c == d.EBH_eBayItemID__c && 
                        ((newDealStart >= dStart && newDealStart <= dEnd) || 
                         (newDealEnd   >= dStart && newDealEnd   <= dEnd) || 
                         (newDealStart <= dStart && newDealEnd   >= dEnd) 
                        ) 
                        //&&                            
                        //newdeal.Id != d.Id
                    ) {
                        if (newdeal.RecordTypeId == NA_DEAL_RTID && newdeal.Originating_Deal__c == d.Id && newdeal.Amendment_Date__c != null) continue; //MN-06092021-US-0010019 - skip if it is NA Amendment Deal
                        //TH:US-0012975-skip overlapped with an existing UnSubsidized Deal\
                        if (newdeal.RecordTypeId == PM_DEAL_RTID && d.RecordTypeId == NA_UNSUB_DEAL_RTID) continue;
                        // SRONG TIN | 23.11.2021 | US-0010751
                        if(newdeal.RecordTypeId == NA_DEAL_RTID && d.RecordTypeId == NA_UNSUB_DEAL_RTID ){
                            // SRONG TIN | 29.11.2021 | US-0010751
                            if(d.EBH_Status__c != DEAL_STATUS_REJECTED){
                                idsNaUnsubDeals.add(d.Id);
                            }
                            
                           continue;
                        }
                        //TH:08/09/2022:US-0012281 : add message error for PM_DEAL_RTID
                        newdeal.addError(newdeal.RecordTypeId == PM_DEAL_RTID ? Label.PM_Duplicate_Error : Label.DD_DuplicateError + ' (' + d.Name + ')');
                    }
                }                    
                                    	
            }
            // SRONG TIN | 23.11.2021 | US-0010751
            if(!idsNaUnsubDeals.isEmpty()){
                Boolean isNotFromFuture = (System.isFuture() || System.isBatch() || System.isQueueable()) ? false : true;
                if (isNotFromFuture && !Test.isRunningTest()){
                    futureUpdateNAUnsubDealsHandler(idsNaUnsubDeals);
                }else{
                    nonfutureUpdateNAUnsubDealsHandler(idsNaUnsubDeals);
                }
                
            }
        }
    }
    /******************************************** 
    @ Method:         futureUpdateNAUnsubDealsHandler 
    @ Version:        1.0 
    @ Author:         SRONG TIN 
    @ Purpose:        US-0010751 - [NA Deals] Subsidized Deals will override Unsubsidized Deals
    @ Even:
    ----------------------------------------------- 
    @ Parameter:      String dealIdsJson
    ------------------------------------------------ 
    @ Change history: 23.11.2021 / SRONG TIN / Created the  Method.
    ******************************************************/ 
    @future
    private static void futureUpdateNAUnsubDealsHandler (Set<Id> ids) {
        nonfutureUpdateNAUnsubDealsHandler(ids);
    }

    /******************************************** 
    @ Method:         nonfutureUpdateNAUnsubDealsHandler 
    @ Version:        1.0 
    @ Author:         SRONG TIN 
    @ Purpose:        US-0010751 - [NA Deals] Subsidized Deals will override Unsubsidized Deals
    @ Even:
    ----------------------------------------------- 
    @ Parameter:      Set<Id> dealIdsJson
    ------------------------------------------------ 
    @ Change history: 23.11.2021 / SRONG TIN / Created the  Method.
    ******************************************************/ 
    private static void nonfutureUpdateNAUnsubDealsHandler (Set<Id> ids) {
        List<EBH_Deal__c> deals = new List<EBH_Deal__c>();
        for(Id id: ids){
            EBH_Deal__c oneDeal = new EBH_Deal__c();
            oneDeal.Id = id;
            oneDeal.EBH_Status__c = 'Cancelled';
            oneDeal.Cancellation_Reason__c = System.Label.Subsidized_Deal_Exists;
            oneDeal.Cancellation_Date_Time__c = System.Now();
            oneDeal.Cancelled_Deal__c = true;
            deals.add(oneDeal);
        }
        // update NA Unsub Deal
        update deals;
    }
    
    private static DateTime getDateTime(Date d, Time t) {
        
        if (t == null) t = Time.newInstance(0,0,0,0);
        return DateTime.newInstance(d.year(), d.month(), d.day(), t.hour(), t.minute(), t.second()); 
        
    }
    
    /*********************************************************************************************************************************
    @ Method:         newDealNotBackDate
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0008846 - [NA] Migrate JOIN NA Deals Trigger and related Classes to Hive
    Create trigger method that checks for the current time and compares against a datetime version of Start Date and Start Time. If the current time is later than that merge value then throw user an error saying 'New Deal cannot be backdated'
    @ Event:		  before insert, before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	oldDealMap: old deal record, newDealMap: new deal record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  28.12.2020 / Sovantheany Dim / Created the method, migrated from join instance 
                       16.03.2021 / Acmatac SEING / US-0009296 - Exclude Admin and Admin with Limited privileges profiles from the Deal Trigger validation for Start Date in the Past
                       31.03.2025 / Vimean Heng / US-0016745 - Deals upload and Management - Testing Feedback
    *********************************************************************************************************************************/
    public static void newDealNotBackDate(List<EBH_Deal__c> newDeals, Map<id,EBH_Deal__c> oldDealsMap){
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        if(!isDeal_V2(newDeals)) return;
        // US-0009296 - Exclude Admin and Admin with Limited privileges profiles from the Deal Trigger validation for Start Date in the Past 
        if(Userinfo.getprofileId()==ADMIN_PROFILE_ID || Userinfo.getprofileId()==ADMIN_PRIVILEGE_PROFILE_ID){
            return;
        }

    	Boolean isNew = (oldDealsMap==null || oldDealsMap.isEmpty());
        Timezone tz = Timezone.getTimeZone(dealTimezone.TimeZone__c);
        Datetime dNow =  DateTime.newInstance(System.Now().getTime() + tz.getOffset(System.Now()));
        for(EBH_Deal__c d:newDeals){      
            //bypass amend upload deal(Time diference in millisecond)
            if(isNew && d.EBH_DealStartDate__c!=null && d.EBH_DealStartDate__c==dNow.dateGMT() && d.Created_From__c==EXCEl && d.EBH_Status__c == DEAL_STATUS_IN_AMENDMENT){
                continue;
            }
            if(d.EBH_DealStartDate__c!=null && d.EBH_DealStartTime__c!=null && d.backdated_deal__c == false && d.Cancelled_Deal__c == false && (isNew || (!isNew && (d.EBH_DealStartDate__c != olddealsMap.get(d.id).EBH_DealStartDate__c || d.EBH_DealStartTime__c != olddealsMap.get(d.id).EBH_DealStartTime__c)))){                
                if(d.EBH_DealStartDate__c <dNow.dateGMT()|| (d.EBH_DealStartDate__c==dNow.dateGMT() && d.EBH_DealStartTime__c<dNow.timeGMT())){
                    d.addError(Label.NEW_DEAL_CANNOT_BE_BACKDATED);
                }                
            }            
        }
    }
    
    /*********************************************************************************************************************************
    @ Method:         lockCompletedDeals
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0008846 - [NA] Migrate JOIN NA Deals Trigger and related Classes to Hive
    Check that when a Deal is being edited if the Deal has Status 'Completed' and Deal End Date/Time is over a week than current time.
    
    If its over that time frame only the following users can edit the Deal - System Admin, System Admin - Limited, API - Seller data profiles and anyone in the Group/Queue - Daily Deals Team
    
    Create method on deal statement that updates any related Deal records with 'Disputed' as Status back to 'Completed' when the Deal Statement Status moved to 'Dispute Payout Approved'
    @ Event:		  before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	oldMapDeals: old deal record, newMapDeals: new deal record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  28.12.2020 / Sovantheany Dim / Created the method, migrated from join instance 
    @                21/03/2025 / Vimean Heng / US-0016717 - Contract Amendment Process - No Change in Subsidy
    *********************************************************************************************************************************/
    public static void lockCompletedDeals(Map<Id,EBH_Deal__c> newMapDeals,Map<Id,EBH_Deal__c> oldMapDeals ){
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        if(!isDeal_V2(newMapDeals.values())) return;

        //Set<String> profiles = new Set<String> {'System Administrator','System Administrator - Limited Privileges','API - SellerData'};  
        if(oldMapDeals != null && !oldMapDeals.isEmpty() && newMapDeals!=null && !newMapDeals.isEmpty()){
         
          
          User currentUser = [Select Id, Profile.Name From User Where Id =:userinfo.getuserid()];
          Date currentDate = System.Today();
          Integer currentDay = System.Today().day();
          //only group=NA_DD_SCC or Daily_Deals_BU can update deal all fields
          List<GroupMember> groupMem = [SELECT Group.Name, Group.DeveloperName FROM GroupMember WHERE Group.DeveloperName in ('Daily_Deals_BU','NA_DD_SCC') and UserOrGroupId =: UserInfo.getUserId()];
          if(!PROFILE_CAN_UPDATE_DEALS.contains(currentUser.Profile.Name) && (groupMem == null || groupMem.isEmpty())){
            //add error for deal when not valid 
            for(Id key: newMapDeals.keySet()){
                 EBH_Deal__c oldDeal = oldMapDeals.get(key);
                 EBH_Deal__c newDeal = newMapDeals.get(key);
                 Boolean isNotChangeOnlyStatus = isNotChangeOnlyStatus(getDealFieldResult(),oldDeal,newDeal);
                 Integer monthsbetween = oldDeal.EBH_DealEndDate__c.monthsBetween(currentDate);
                 if(oldDeal.EBH_Status__c != newDeal.EBH_Status__c){
	                 if(oldDeal.EBH_Status__c == 'Completed'&& ((monthsbetween == 1 && currentDay > 7) || monthsbetween>1)){
	                    //Check that when a Deal is being edited if the Deal has Status 'Completed' and Deal End Date/Time is over a week than current time.
	                    newDeal.addError(Label.DD_DealUpdate_Lock_Completed_Message,false);
	                 }else if(STATUS_ALLOW_TO_CANCEL.contains(oldDeal.EBH_Status__c) && newDeal.EBH_Status__c !=  DEAL_STATUS_IN_AMENDMENT){ //NK:24/03/2025: US-0016717
	                        //If Deal Status 'Seller Approved' 'Running' AND 'Completed' if Deal End Date is within 1 week of Current Date. 
	                        //Status is only allowed to be changed to Cancelled for all users and no other fields can change
	                        if(isNotChangeOnlyStatus|| newDeal.EBH_Status__c != 'Cancelled'){
	                            newDeal.addError(Label.DD_Cancelled_Lock_Message,false);
	                        }
	                  }else if(oldDeal.EBH_Status__c == 'Sent to Seller' && isNotChangeOnlyStatus){
	                        //Deal Status 'Sent to Seller': Only Status is always allowed to change for all users but ONLY Status can change
	                        newDeal.addError(Label.DD_Sent_to_Seller_Lock_Message,false);
	                  }
                 }
              } 
             
          }
          
      }
    }
    // Acmatac, 25 May 2021 Updated FieldDescribe function.
    /*********************************************************************************************************************************
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  25.May.2021 / Acmatac Seing / US-0009558 - Stop using getDescribe() method in Deal Trigger.
    *********************************************************************************************************************************/
    private static Boolean isNotChangeOnlyStatus(Map<String, Schema.DescribeFieldResult> mapFieldResult,EBH_Deal__c oldDeal,EBH_Deal__c newDeal){
        for(String f:mapFieldResult.keySet()){
            //ignore check seller info's fields from aprrove screen
            if(FROM_APPROVE_FORM && IGNORE_CHECK_FROM_APPROVE.contains(f)) continue;
            if(mapFieldResult.get(f).isUpdateable()){
                if(f!='EBH_Status__c' && f!='Cancellation_Reason__c' && f!='Cancellation_Date_Time__c' && f!='cancelled_deal__c' && f!='Preview_Date_Time__c' && oldDeal.get(f)!=newDeal.get(f)){
                    return true;
                }
            }
        }
        return false;
    }
    
    /*********************************************************************************************************************************
    @ Method:         changeAllowed
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0008846 - [NA] Migrate JOIN NA Deals Trigger and related Classes to Hive
     * The following logic should apply if deal Status is planned(accepted) or running:
     * if item id changes user is unable to change - error message ‘Unable to change Deal Item Id when Deal has been approved, please cancel this Deal and create a new Deal record’
     * if Deal Price, Seller Price or Sold Items (Forecast) changes - error message ‘Unable to update pricing please end current deal and create a new Deal’
     * if any fields changed are in the column D update status to ‘In Revision’
    @ Event:		  before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	oldMapDeals: old deal record, newMapDeals: new deal record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  28.12.2020 / Sovantheany Dim / Created the method, migrated from join instance 
                       05.12.2025 / David Herrero / Added bypass functionality
    *********************************************************************************************************************************/
    public static void changeAllowed(List<EBH_Deal__c> newDeals, Map<Id,EBH_Deal__c> mOldDeals){
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        if(!isDeal_V2(newDeals)) return;
        byPass__c bp = byPass__c.getInstance(UserInfo.getUserId()); // get an instance of the bypass custom settings

        if (bp != null && bp.byPass_Trigger__c && !String.isBlank(bp.triggerObjects__c)
            && bp.triggerObjects__c.containsIgnoreCase('EBH_Deal__c')) {
            return; // Adding ByPass to this validation
        }
    	for(EBH_Deal__c newdeal : newDeals){
                EBH_Deal__c olddeal = mOldDeals.get(newdeal.Id);
                    Boolean isStartDateChangeInSameWeek = false;
                    Boolean isNotChangeOnlyStatus = isNotChangeOnlyStatus(getDealFieldResult(),oldDeal,newDeal);
                    
                    if(sStatus.contains(newdeal.EBH_Status__c) && isNotChangeOnlyStatus){
                            Set<String> isItemUpdated = hasAnyFieldChanged(new Set<String>{'EBH_eBayItemID__c'},newdeal,olddeal);
                            Set<String> isDealPriceUpdated = hasAnyFieldChanged(fieldDealPrice,newdeal,olddeal);
                            Set<String> isFieldsUpdated = hasAnyFieldChanged(fieldnames,newdeal,olddeal);
                            isItemUpdated.retainAll(new Set<String>{'EBH_eBayItemID__c'});
                            isDealPriceUpdated.retainAll(fieldDealPrice);
                            isFieldsUpdated.retainAll(fieldnames);
                            
                            if(!isItemUpdated.isempty()){
                                    newdeal.addError(Label.DD_ApprovedChangeError_ItemId);
                            }else if(!isDealPriceUpdated.isempty()){
                                    newdeal.addError(Label.DD_ApprovedChangeError_Pricing);
                            }else if(!isFieldsUpdated.isempty()){  
                                              
                                if(isFieldsUpdated.contains('EBH_DealStartDate__c') && isFieldsUpdated.size() == 1){
                                    Date oldStartWeek = oldDeal.EBH_DealStartDate__c.toStartofWeek();
                                    Date newStartWeek = newDeal.EBH_DealStartDate__c.toStartofWeek();
                                    if(oldStartWeek==newStartWeek){
                                        isStartDateChangeInSameWeek=true;
                                    } 
                                         
                                    if(isStartDateChangeInSameWeek == false){
                                        newdeal.EBH_Status__c = STATUS_IN_REVISION;
                                        newDeal.Deal_Revised__c = true;                                         
                                    }
                                }else{
                                    newdeal.EBH_Status__c = STATUS_IN_REVISION;
                                    newDeal.Deal_Revised__c = true;                                         
                                }      
                                        
                            }
                        }
                    
                }
    }
    
    private static Set<String> hasAnyFieldChanged(Set<string> fieldnames, EBH_Deal__c newObj, EBH_Deal__c oldObj)
    {

        Set<String> setFieldsChanged = new Set<String>();
        for(string dealField : fieldnames){
            if(oldObj.get(dealField) != newObj.get(dealField)){
                setFieldsChanged.add(dealField);
            }
        }
        
        return setFieldsChanged;
    }
    
    /*********************************************************************************************************************************
    @ Method:         rollUpDisputeAmountForDealStatement
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0008846 - [NA] Migrate JOIN NA Deals Trigger and related Classes to Hive
     Create a new trigger method to roll up dispute amounts from Deal record to Deal Statement
     When Sold Item Disputes and Sold Items Further Disputes is populated or changed update Dispute Payout and further dispute payout on Deal Statement related record. If changed subtract old value and add new value.
    @ Event:		  after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	oldMap: old deal record, newDeals: new deal record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  28.12.2020 / Sovantheany Dim / Created the method, migrated from join instance 
    *********************************************************************************************************************************/
    public static void rollUpDisputeAmountForDealStatement(Map<Id,EBH_Deal__c> oldMap,List<EBH_Deal__c> newDeals){
        // Acmatac SEING 20-May-2021, US-0009558, Adding condition to specific recordtype of method
        if(!isDeal_V2(newDeals)) return;

        Set<Id> dsToUpdate = new Set<Id>();
        for(EBH_Deal__c newDeal : newDeals){
        	EBH_Deal__c oldDeal = oldMap.get(newDeal.Id);
        	if(newDeal.Deal_Statement__c != oldDeal.Deal_Statement__c 
        	|| newDeal.Subsidy_Due_Disputes__c != oldDeal.Subsidy_Due_Disputes__c 
        	|| newDeal.Subsidy_Due_Further_Dispute__c != oldDeal.Subsidy_Due_Further_Dispute__c){
        		if(newDeal.Deal_Statement__c != null) dsToUpdate.add(newDeal.Deal_Statement__c);
        		if(oldDeal.Deal_Statement__c != null) dsToUpdate.add(oldDeal.Deal_Statement__c);
        	}
        }
        
        if(!dsToUpdate.isEmpty()){
            List<Deal_Statement__c> lst = new List<Deal_Statement__c>();
            for(SObject obj:[Select Deal_Statement__c, sum(Subsidy_Due_Disputes__c) Dispute, sum(Subsidy_Due_Further_Dispute__c) Subsidy_Due_Further_Dispute__c from EBH_Deal__c where Deal_Statement__c in :dsToUpdate  group by Deal_Statement__c]){
                Deal_Statement__c ds = new Deal_Statement__c();
                ds.Id = (Id)obj.get('Deal_Statement__c');
                ds.Disputes_Payout__c = (Decimal)obj.get('Dispute');
                ds.Further_Dispute_Payout__c = (Decimal)obj.get('Subsidy_Due_Further_Dispute__c');
                lst.add(ds);
            }
            update lst;
        }
        
    }

    // Acmatac SEING, 19.05.2021
    public static Boolean isDeal_V1(List<EBH_Deal__c> lstDeal){
        return lstDeal.isEmpty() ? false : lstDeal[0].RecordTypeId == STANDARD_DEAL_RTID ? true : false;
    }

    // Acmatac SEING, 19.05.2021
    public static Boolean isDeal_V2(List<EBH_Deal__c> lstDeal){
        return lstDeal.isEmpty() ? false : lstDeal[0].RecordTypeId == NA_DEAL_RTID ? true : false;
    }
    // SRONG TIN 09-July-2021, US-0009650
    public static Boolean isDeal_V3(List<EBH_Deal__c> lstDeal){
        return lstDeal.isEmpty() ? false : lstDeal[0].RecordTypeId == NA_UNSUB_DEAL_RTID ? true : false;
    }
    public static Boolean isDeal_PM(List<EBH_Deal__c> lstDeal){
        return lstDeal.isEmpty() ? false : lstDeal[0].RecordTypeId == PM_DEAL_RTID ? true : false;
    }
    
    
    /*********************************************************************************************************************************
    @ Purpose: Get Deal Field Result
    @ Change history:  Acmatac SEING / 25 May 2021 / Created the method.
    *********************************************************************************************************************************/
    private static Map<String, Schema.DescribeFieldResult> getDealFieldResult(){
        if(mapFieldResult == null){
            mapFieldResult = new Map<String, Schema.DescribeFieldResult>();
            Map<String, Schema.SObjectField> mapFields = Schema.SObjectType.EBH_Deal__c.fields.getMap(); 
            
            for(String f: mapFields.keySet()){
                mapFieldResult.put(f, mapFields.get(f).getDescribe());
            }
        }
        return mapFieldResult;
    }

    // public static void populateStartDateTime(List<EBH_Deal__c> newDeals, Map<Id,EBH_Deal__c> oldMap){
    //     // 28.05.2021 / Sophal Noch / US-0009533
        
    //     // Deal_Timezone__c dealTimezone = Deal_Timezone__c.getInstance();
    //     // Timezone tz = Timezone.getTimeZone(dealTimezone.TimeZone__c);

    //     for(EBH_Deal__c deal : newDeals){

    //         if(oldMap == null 
    //         || (deal.EBH_DealStartDate__c != oldMap.get(deal.Id).EBH_DealStartDate__c  || deal.EBH_DealStartTime__c != oldMap.get(deal.Id).EBH_DealStartTime__c)
    //         || (oldMap.get(deal.Id).Deal_Start_Date_Time2__c == null && deal.Deal_Start_Date_Time2__c == null)
    //         ){

    //             if(deal.EBH_DealStartDate__c == null || deal.EBH_DealStartTime__c == null){deal.Deal_Start_Date_Time2__c = null;}
    //             else{
    //                 Datetime startTime = DateTime.newInstance(deal.EBH_DealStartDate__c, deal.EBH_DealStartTime__c);
    //                 // startTime =  DateTime.newInstance(startTime.getTime() + tz.getOffset(startTime));
    //                 deal.Deal_Start_Date_Time2__c = startTime;
    //             }
    //         }
            
    //     }
    // }



     /*********************************************************************************************************************************
    @ Method:         afterUpdate
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0010285 - BUG - Standard approval of Finance Approver not sending email.
    @ Event:		  after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	 newDeals: new deal record, oldMap: old deal record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.09.2021 / Sophal Noch / Created the method
    *********************************************************************************************************************************/
    public static void afterUpdate(List<EBH_Deal__c> newDeals, Map<Id,EBH_Deal__c> oldMap){
        Set<Id> setDealApprovedOrRejectedId = new Set<Id>();
        for(EBH_Deal__c deal : newDeals){
            if(deal.RecordTypeId == NA_DEAL_RTID && SET_STATUS_APPROVED_REJECTED.contains(deal.EBH_Status__c) && deal.EBH_Status__c != oldMap.get(deal.Id).EBH_Status__c){
                setDealApprovedOrRejectedId.add(deal.Id);
            }
        }

        if(!setDealApprovedOrRejectedId.isEmpty()){
            if(System.isFuture() || System.isBatch()){
                reTriggerProBuilderToSendEmail(setDealApprovedOrRejectedId);
            }else{
                futureReTriggerProBuilderToSendEmail(setDealApprovedOrRejectedId);
            }
        }
    }

    @future
    private static void futureReTriggerProBuilderToSendEmail(Set<Id> setDealId) {
        reTriggerProBuilderToSendEmail(setDealId);
    }

    private static void reTriggerProBuilderToSendEmail(Set<Id> setDealId) {
        // Sophal:01/09/2021:US-0010285 make Deal process builder 'eBay NA Deals' run so email can be send
        if(!setDealId.isEmpty()){
            List<EBH_Deal__c> listDealToUpdate = new List<EBH_Deal__c>();
            Datetime currentTime = Datetime.now();
            for(Id dealId : setDealId){
                listDealToUpdate.add(new EBH_Deal__c(Id=dealId,Internally_Approved_Rejected_Timestamp__c=currentTime));
            }
            update listDealToUpdate;
        }
    
    }
  
    /*********************************************************************************************************************************
    @ Method:         dealStatusMappingWithSEP
    @ Version:        1.0
    @ Author:         Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0010485 - [SP - EU Deals] Stamping Seller Price value into Deal Price field in Hive when deal record is created
    @ Event:		  before insert, before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	  List<EBH_Deal__c> newDeals, Map<Id,EBH_Deal__c> oldMap
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.11.2021 / Acmatac Seing / Created the method
    17.03.2022 / SRONG TIN / Update the method: US-0011338 - System allowing Deals with same item ID & overlapping dates
                       29.03.2022 / SRONG TIN / Update the method: US-0011338 - System allowing Deals with same item ID & overlapping dates
                       04.04.2022 / SRONG TIN / Update the method: US-0011589 - Planned shouldn't happen on overlapping date/time
                       19.04.2022 / SRONG TIN / Update the method: US-0011589 - Planned shouldn't happen on overlapping date/time
    *********************************************************************************************************************************/
    
    public static void dealStatusMappingWithSEP(List<EBH_Deal__c> newDeals, Map<Id,EBH_Deal__c> oldMap){
        if(!isDeal_V1(newDeals)) return;
        // SRONG TIN - 17/03/2022 : US-0011338
        Set<String> eBayItemIds = new Set<String>();
        Set<String> eBay_ItemIds = new Set<String>();
        Map<String,List<EBH_Deal__c>> existingDeals = new Map<String,List<EBH_Deal__c>>();
        String dealReatilCampaingId = '';
        Set<Id> dealIds = new Set<Id>();
        // is insert
        if(oldMap == null){
            for(EBH_Deal__c newDeal: newDeals){
                // SB 12.01.2024 US-0013136
                /* if(String.isNotBlank(newDeal.EBH_Status__c) && DEAL_STATUS_SEP_MAPPING.keySet().contains(newDeal.EBH_Status__c)){
                    newDeal.Seller_Portal_Status__c = DEAL_STATUS_SEP_MAPPING.get(newDeal.EBH_Status__c);
                }*/
                // SRONG TIN - 17/03/2022 : US-0011338
                if(isFromBulkUpload_DE){
                    if(String.isNotBlank(newDeal.EBH_DealRetailCampaign__c)){
                        dealReatilCampaingId = newDeal.EBH_DealRetailCampaign__c;
                    }
                    eBay_ItemIds.add(newDeal.EBH_eBayItemID__c); 
                }else
                // SRONG TIN - 21/04/2022 US-0011589 update feedback
                if( newDeal.EBH_Status__c == DEAL_STATUS_PLANNED &&
                    newDeal.EBH_DealSiteId__c == SITE_DE &&
                    newDeal.EBH_DealStartDate__c != null && 
                    newDeal.EBH_DealEndDate__c != null){
                    eBayItemIds.add(newDeal.EBH_eBayItemID__c); 
                }
            }
        }
        // is update
        else{
            // SRONG TIN - 04/04/2022 : US-0011589
            // if selected deals duplicate with another selected deals
            Map<String,EBH_Deal__c> selectedDealMap = new Map<String,EBH_Deal__c>();
            
            for(EBH_Deal__c newDeal: newDeals){
                EBH_Deal__c oldDeal = oldMap.get(newDeal.Id);
                // SB 12.01.2024 US-0013136
                /*if(String.isNotBlank(newDeal.EBH_Status__c) && oldDeal.EBH_Status__c != newDeal.EBH_Status__c && DEAL_STATUS_SEP_MAPPING.keySet().contains(newDeal.EBH_Status__c)){
                    newDeal.Seller_Portal_Status__c = DEAL_STATUS_SEP_MAPPING.get(newDeal.EBH_Status__c);
                }*/
                // SRONG TIN - 04/04/2022 : US-0011589
                if( String.isNotBlank(newDeal.EBH_Status__c) && 
                    oldDeal.EBH_Status__c != newDeal.EBH_Status__c && 
                    newDeal.EBH_Status__c == DEAL_STATUS_PLANNED &&
                    (newDeal.EBH_eBayItemID__c != null && newDeal.EBH_eBayItemID__c != '') &&
                    newDeal.EBH_DealSiteId__c == SITE_DE &&
                    newDeal.EBH_DealStartDate__c != null && 
                    newDeal.EBH_DealEndDate__c != null)
                {
                    // check if selected also have duplicated
                    if(selectedDealMap.get(newDeal.EBH_eBayItemID__c) != null){
                        EBH_Deal__c duplicatedDeal = selectedDealMap.get(newDeal.EBH_eBayItemID__c);
                        //SRONG TIN - 19/04/2022 : US-0011589 update feedback
                        EBH_Deal__c d1 = newDeal;
                        EBH_Deal__c d2 = duplicatedDeal;
                        if(newDeal.EBH_DealEndDate__c < duplicatedDeal.EBH_DealEndDate__c){
                            d1 = duplicatedDeal;
                            d2 = newDeal;
                        }
                        // SRONG TIN - 20/04/2022 US-0011589 update feedback
                        DateTime d1Start = getDateTime(d1.EBH_DealStartDate__c, d1.EBH_DealStartTime__c);
                        DateTime d1End   = getDateTime(d1.EBH_DealEndDate__c, d1.EBH_DealEndTime__c);

                        DateTime d2Start = getDateTime(d2.EBH_DealStartDate__c, d2.EBH_DealStartTime__c);
                        DateTime d2End   = getDateTime(d2.EBH_DealEndDate__c, d2.EBH_DealEndTime__c);
                        if( 
                            (   (d2Start >= d1Start && d2Start <= d1End) || 
                                (d2End   >= d1Start && d2End   <= d1End) || 
                                (d2Start <= d1Start && d2End   >= d1End)
                            ) &&
                            d1.Id != d2.Id
                        ){
                            List<EBH_Deal__c> lstDeals = existingDeals.get(newDeal.EBH_eBayItemID__c);
                            lstDeals.add(newDeal);
                            existingDeals.put(newDeal.EBH_eBayItemID__c,lstDeals);
                        }

                    }else{
                        // add to map and set
                      
                        eBayItemIds.add(newDeal.EBH_eBayItemID__c);
                        selectedDealMap.put(newDeal.EBH_eBayItemID__c,newDeal);
                        List<EBH_Deal__c> lstDeals = new List<EBH_Deal__c>();
                        lstDeals.add(newDeal);
                        existingDeals.put(newDeal.EBH_eBayItemID__c,lstDeals);
                    }
                }
            }
        }
        // SRONG TIN - 17/03/2022 : US-0011338 for AC2
        if(isFromBulkUpload_DE){

            List<EBH_Deal__c> dealToInsert = new List<EBH_Deal__c>();
            Id drcRecordTypeId = Schema.SObjectType.EBH_DealRetailCampaign__c.getRecordTypeInfosByDeveloperName().get(DRC_STANDARD_COMPAIGN).getRecordTypeId();
            Map<String,String> mapIds = new Map<String,String>();
            
            //MN-22032023-US-0012628 - Including status "Seller Cancelled" into the excluding status and move fixed status text into SET variables
            Set<String> sStatusToExclude = new Set<String>{
                DEAL_STATUS_REJECTED, DEAL_STATUS_SELLER_CANCELLED
            };

            //for(EBH_Deal__c d: [Select Id,EBH_eBayItemID__c from EBH_Deal__c where EBH_eBayItemID__c in :eBay_ItemIds and ( EBH_DealRetailCampaign__c = :dealReatilCampaingId and EBH_DealRetailCampaign__r.RecordTypeId = :drcRecordTypeId and EBH_DealRetailCampaign__r.EBH_Country__c = :SITE_DE ) and EBH_Status__c NOT IN ('Rejected') LIMIT 50000]){
            for(EBH_Deal__c d: [Select Id,EBH_eBayItemID__c from EBH_Deal__c where EBH_eBayItemID__c in :eBay_ItemIds and ( EBH_DealRetailCampaign__c = :dealReatilCampaingId and EBH_DealRetailCampaign__r.RecordTypeId = :drcRecordTypeId and EBH_DealRetailCampaign__r.EBH_Country__c = :SITE_DE ) and EBH_Status__c NOT IN:sStatusToExclude LIMIT 50000]){
                mapIds.put(d.EBH_eBayItemID__c, d.EBH_eBayItemID__c);
            } 
            for(EBH_Deal__c d:newDeals){
                if(mapIds.get(d.EBH_eBayItemID__c) != null){
                    d.addError(Label.LWCCreateSingleSameEbayIdDuplicated);
                }
            }
        }

        // SRONG TIN - 04/04/2022 : US-0011589
        if(!eBayItemIds.isEmpty() || existingDeals != null){
            Set<Id> ids = oldMap != null?oldMap.keySet():new Set<Id>();
            //MN-22032023-US-0012628 - Including status "Seller Cancelled" into the excluding status and move fixed status text into SET variables
            Set<String> sStatusToExclude = new Set<String>{
                DEAL_STATUS_REJECTED, DEAL_STATUS_NEW, DEAL_STATUS_SELLER_CANCELLED
            };
            if(!eBayItemIds.isEmpty()){
                for(EBH_Deal__c d: [Select  Id,
                                        EBH_eBayItemID__c,
                                        EBH_DealStartDate__c,
                                        EBH_DealStartTime__c,
                                        EBH_DealEndDate__c,
                                        EBH_DealEndTime__c 
                                from EBH_Deal__c 
                                where   Id NOT IN :ids and 
                                        EBH_eBayItemID__c in :eBayItemIds and 
                                        EBH_eBayItemID__c != null and
                                        EBH_DealStartDate__c != null and 
                                        EBH_DealEndDate__c != null and 
                                        EBH_Status__c NOT IN:sStatusToExclude LIMIT 50000]
                                            //EBH_Status__c NOT IN ('Rejected','New') LIMIT 50000]
                ){
                    //SRONG TIN - 19/04/2022 : US-0011589 update feedback
                    List<EBH_Deal__c> lstDeals = existingDeals.get(d.EBH_eBayItemID__c);
                    if(lstDeals == null){
                        lstDeals = new List<EBH_Deal__c>();
                    }
                    lstDeals.add(d);
                    existingDeals.put(d.EBH_eBayItemID__c,lstDeals);

                } 
            }
            
            
            for(EBH_Deal__c newDeal:newDeals){
                if(existingDeals.get(newDeal.EBH_eBayItemID__c) != null){
                    //SRONG TIN - 19/04/2022 : US-0011589 update feedback
                    List<EBH_Deal__c> deals = existingDeals.get(newDeal.EBH_eBayItemID__c);
                    for(EBH_Deal__c duplicatedDeal: deals){
                        EBH_Deal__c d1 = newDeal;
                        EBH_Deal__c d2 = duplicatedDeal;
                        if(newDeal.EBH_DealEndDate__c < duplicatedDeal.EBH_DealEndDate__c){
                            d1 = duplicatedDeal;
                            d2 = newDeal;
                        }
                        // SRONG TIN - 20/04/2022 US-0011589 update feedback
                        DateTime d1Start = getDateTime(d1.EBH_DealStartDate__c, d1.EBH_DealStartTime__c);
                        DateTime d1End   = getDateTime(d1.EBH_DealEndDate__c, d1.EBH_DealEndTime__c);

                        DateTime d2Start = getDateTime(d2.EBH_DealStartDate__c, d2.EBH_DealStartTime__c);
                        DateTime d2End   = getDateTime(d2.EBH_DealEndDate__c, d2.EBH_DealEndTime__c);

                        if( (   (d2Start >= d1Start && d2Start <= d1End) || 
                                (d2End   >= d1Start && d2End   <= d1End) || 
                                (d2Start <= d1Start && d2End   >= d1End)
                            ) &&
                            d1.Id != d2.Id
                        ){
                            String link = '<a href=/'+ newDeal.Id +'>EBay Item ID </a>';
                            String link2 = '<a href=/'+ duplicatedDeal.Id +'>WoW Deal ID </a>';
                            String errorMessage = '';
                            if(!isFromUpdateDealToPlannedList){
                                link = duplicatedDeal.Id;
                                errorMessage = Label.LWCDealToPlannedDuplicatedEbayItemId+link+Label.LWCDealToPlannedDuplicatedEbayItemId2;
                            }else{
                                errorMessage = 'This EBay Item ID ('+link+') is already Planned with the same Deal Period ('+link2+Label.LWCDealToPlannedDuplicatedEbayItemId2;
                            }
                            isFromUpdateDealToPlanned_Duplicated = true;
                            newDeal.addError(errorMessage,false);
                            break;
                        }
                    }
                    
                }
            }
        }
        
    }

    /*********************************************************************************************************************************
    @ Method:         setDealPrice
    @ Version:        1.0
    @ Author:         Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0010485 - [SP - EU Deals] Stamping Seller Price value into Deal Price field in Hive when deal record is created
    @ Event:		  after insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	  List<EBH_Deal__c> newDeals
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.11.2021 / Acmatac Seing / Created the method
    *********************************************************************************************************************************/
    
    public static void setDealPrice(List<EBH_Deal__c> newDeals){
        if(!isDeal_V1(newDeals)) return;

        Set<Id> createdByIds = new Set<Id>();
        for(EBH_Deal__c oDl: newDeals){
            createdByIds.add(oDl.CreatedById);
        }

        Set<Id> powerCustomerSuccessUserIds = new Set<Id>();

        for(User oUsr: [SELECT Id FROM User WHERE UserType =: Label.USER_TYPE_POWER_CUSTOMER_SUCCESS AND Id IN: createdByIds]){
            powerCustomerSuccessUserIds.add(oUsr.Id);
        }
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
        for(EBH_Deal__c oDl: newDeals){
            if(powerCustomerSuccessUserIds.contains(oDl.CreatedById)){
                lstDeal.add(new EBH_Deal__c(
                    Id = oDl.Id,
                    EBH_DealPrice__c = oDl.EBH_SellerPrice__c
                ));
            }
        }
        if(!lstDeal.isEmpty()) update lstDeal;
    }

    /*********************************************************************************************************************************
    @ Method:         dealNAUnsubStatusMappingWithSEP
    @ Version:        1.0
    @ Author:         Loumang SENG(loumang.seng@gaea-sys.com)
    @ Purpose:        US-0011668 - Migrate to Picklist Field for NA Deal Status
    @ Event:		  before insert, before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	  List<EBH_Deal__c> newDeals, Map<Id,EBH_Deal__c> oldMap
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06.06.2022 / Loumang SENG / Created the method
    @               :  12.01.2024 / Sambath Seng / US-0013136 - Seller_Portal_Status__c - Deprecate
    *********************************************************************************************************************************/
    /*public static void dealNAUnsubStatusMappingWithSEP(List<EBH_Deal__c> newDeals, Map<Id,EBH_Deal__c> oldMap){
        if(!isDeal_V3(newDeals)) return;
        Boolean isNew = (oldMap==null);
		for(EBH_Deal__c newDeal : newDeals){

            if((isNew || (!isNew && newDeal.EBH_Status__c <> oldMap.get(newDeal.Id).EBH_Status__c)) &&
                String.isNotBlank(newDeal.EBH_Status__c) && SELLER_PORTAL_STATUS_MAPPING.containsKey(newDeal.EBH_Status__c)){   
                newDeal.Seller_Portal_Status__c = SELLER_PORTAL_STATUS_MAPPING.get(newDeal.EBH_Status__c);
            }
		}
        
	}*/

    /*********************************************************************************************************************************
    @ Method:         dealNAUnsubStatusMappingWithDRC
    @ Version:        1.0
    @ Author:         TIN SRONG(srong.tin@gaea-sys.com)
    @ Purpose:        US-0014018 - 2 - IT Launch - Deal V3 default status should be Processing
    @ Event:		  before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	  List<EBH_Deal__c> newDeals, Map<Id,EBH_Deal__c> oldMap
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  31.08.2023 / SRONG TIN / Created the method
    *********************************************************************************************************************************/
    public static void dealNAUnsubStatusMappingWithDRC(List<EBH_Deal__c> newDeals, Map<Id,EBH_Deal__c> mapOld){
        if(!isDeal_V3(newDeals)) return;
        Set<Id> drcIds = new Set<Id>();
		for(EBH_Deal__c deal : newDeals){
            if(deal.EBH_Status__c != mapOld.get(deal.Id).EBH_Status__c && deal.EBH_Status__c == DEAL_STATUS_OPS_REVIEW) {
                drcIds.add(deal.EBH_DealRetailCampaign__c);
            }
		}
        if(!drcIds.isEmpty()){
            Map<Id,EBH_DealRetailCampaign__c> drcMap = new Map<Id,EBH_DealRetailCampaign__c>([Select Id,Status__c From EBH_DealRetailCampaign__c Where Id in:drcIds]);
            // Update Status to running
            for(EBH_Deal__c deal : newDeals){
                EBH_DealRetailCampaign__c drc = drcMap.get(deal.EBH_DealRetailCampaign__c);
                if(drc != null && drc.Status__c == DEAL_STATUS_RUNNING && deal.EBH_Status__c == DEAL_STATUS_OPS_REVIEW){
                    deal.EBH_Status__c = DEAL_STATUS_RUNNING;
                }
            }
        }
        
	}

    /*********************************************************************************************************************************
    @ Method:         subsidisedDealStatusMappingWithSEP
    @ Version:        1.0
    @ Author:         Sambath Seng(sambath.seng@gaea-sys.com)
    @ Purpose:        US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
    @ Event:		  before insert, before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	  List<EBH_Deal__c> newDeals, Map<Id,EBH_Deal__c> oldMap
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  27.05.2023 / Sambath Seng / Created the method
    @               :  12.01.2024 / Sambath Seng / US-0013136 - Seller_Portal_Status__c - Deprecate
    *********************************************************************************************************************************/
    /*public static void subsidisedDealStatusMappingWithSEP(List<EBH_Deal__c> newDeals, Map<Id,EBH_Deal__c> oldMap){
        if(!isDeal_V2(newDeals)) return;
        Boolean isNew = (oldMap==null);
		for(EBH_Deal__c newDeal : newDeals){
            if((isNew || (!isNew && newDeal.EBH_Status__c <> oldMap.get(newDeal.Id).EBH_Status__c)) &&
                String.isNotBlank(newDeal.EBH_Status__c) && SUBSIDISED_SELLER_PORTAL_STATUS_MAPPING.containsKey(newDeal.EBH_Status__c)){   
                newDeal.Seller_Portal_Status__c = SUBSIDISED_SELLER_PORTAL_STATUS_MAPPING.get(newDeal.EBH_Status__c);
            }
		}
	}*/

    /*********************************************************************************************************************************
    @ Method:         prePopulateDeal
    @ Version:        1.0
    @ Author:         Mony Nou(mony.nou@gaea-sys.com)
    @ Purpose:        US-0011637 - Need to update the Deals with DRC Start Date and End Date
    @ Event:		  before insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	  List<EBH_Deal__c> newDeals
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  05.09.2022 / Mony Nou / Created the method
    *********************************************************************************************************************************/
    public static void prePopulateDeal (List<EBH_Deal__c> newDeals) {

        //Currently enable for Deal_V1 
        if(!isDeal_V1(newDeals)) return; 
        
        Set<Id> sDRCIds = new Set<Id>();
        List<EBH_Deal__c> lstDeals = new List<EBH_Deal__c>();

        for (EBH_Deal__c deal : newDeals) {

            if (deal.EBH_DealRetailCampaign__c != null && deal.EBH_DealStartDate__c == null && deal.EBH_DealEndDate__c == null) { 
                sDRCIds.add(deal.EBH_DealRetailCampaign__c); 
                lstDeals.add(deal);
            }
        }

        if (!sDRCIds.isEmpty()) {

            Map<Id, EBH_DealRetailCampaign__c> mDRC = new Map<Id, EBH_DealRetailCampaign__c>([SELECT EBH_Date__c, Start_Time__c, EPH_EndDate__c, End_Time__c FROM EBH_DealRetailCampaign__c WHERE Id IN:sDRCIds]);
        
            for (EBH_Deal__c deal : lstDeals) {
                if (deal.EBH_DealRetailCampaign__c != null && mDRC.containsKey(deal.EBH_DealRetailCampaign__c)) {

                    EBH_DealRetailCampaign__c drc = mDRC.get(deal.EBH_DealRetailCampaign__c);

                    deal.EBH_DealStartDate__c = drc.EBH_Date__c;
                    deal.EBH_DealStartTime__c = drc.Start_Time__c;

                    deal.EBH_DealEndDate__c = drc.EPH_EndDate__c;
                    deal.EBH_DealEndTime__c = drc.End_Time__c;
                    
                }
            }
        }
    }
    /*********************************************************************************************************************************
    @ Method:         prePopulateSellerPrice
    @ Version:        1.0
    @ Author:         Bora Chhorn(bora.chhorn@gaea-sys.com)
    @ Purpose:        US-0013053 - Deal Price should be stamped on Seller Price for Un-Sub Deals
    @ Event:		  before insert, before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	  List<EBH_Deal__c> newDeals
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  11.01.2023 / Bora Chhorn / Created the method
    *********************************************************************************************************************************/
    public static void prePopulateSellerPrice (List<EBH_Deal__c> newDeals) {
        //Currently enable for Deal_V3 
        if(!isDeal_V3(newDeals)) return;
        
        for (EBH_Deal__c deal : newDeals) {
            if (deal.EBH_DealRetailCampaign__c != null) {
                if(deal.RecordTypeId == NA_UNSUB_DEAL_RTID && (deal.EBH_SellerPrice__c == NULL || deal.EBH_SellerPrice__c == 0)){
                    deal.EBH_SellerPrice__c = deal.EBH_DealPrice__c;
                }
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:        blockDeletationDeals
    @ Version:       1.0
    @ Author:          
    @ Purpose:       US-0012499 - Processed deals shouldn't be deleted
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<EBH_Deal__c> listOldDeals  
    @ event    :     before delete
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27/09/2023 / SRONG TIN / Created the  Method.
    *****************************************************************************************************************************/
    public static void blockDeletationDeals(List<EBH_Deal__c> listOldDeals)
    {
        Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID);
        Boolean isAdminPre = (Userinfo.getprofileId()==ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
        byPass__c bp = byPass__c.getInstance(UserInfo.getUserId()); // get an isntance of the bypass custom settings
        
        if (bp!=null && bp.byPass_Trigger__c && !String.isBlank(bp.triggerObjects__c)
            && bp.triggerObjects__c.containsIgnoreCase('EBH_Deal__c')) {return;} // Adding ByPass to this validation
        
        if(isAdmin || isAdminPre) return;
        for(EBH_Deal__c d: listOldDeals)
        {
            if(d.EBH_SoldItems__c > 0 || d.EBH_Status__c != DEAL_STATUS_NEW){
                d.addError(System.Label.Block_Deletation_Deals_Message);
            }
        }
    }
}