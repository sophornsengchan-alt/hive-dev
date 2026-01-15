/*********************************************************************************************************************************@ Class:          EBH_ContractTriggerHandler
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Handler Class for Contract Trigger
EPH-6, EPH-14 : Contract Management and Contract Approval
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.05.2017 / NEHA LUND / Created the class.
@ Change history: 24.05.2018 / David Herrero / Commented unused methods
@ Change history: 08.08.2022 / Sambath Seng / US-0011127 - IT Email Notification for Contract Status= "Program Cancelled"
@ Change history: 10.08.2022 / Sambath Seng / US-0012309 - [Refurb] Allow user to update DeclinedReason & ContractEndDate at the specific contract stage
@ Change history: 29.08.2022 / CHETRA SAROM / US-0011289 - FR Email Notification for Contract Status= "Program Cancelled"
@ Change history: 02.09.2022 / Sambath Seng / US-0011288 - FR Email Notification for Contract Status = "eBay Declined"
@ Change history: 05.01.2023 / Bora Chhorn / US-0013027 - Add System Admin limited privileges to profiles who can edit contracts
@ Change history: 12.06.2023 / CHETRA SAROM / US-0013743 - New Record Type Certified Recycler Contracts
@                 29.06.2023 / Mony Nou / US-0013732 - Send Click Contracts for FR Certified Recycler Contracts
@                 30.06.2023 / Mony Nou/ US-0013756 - Send Contract Acceptance email to Seller for FR Certified Recycler Contracts
@                 16.08.2023 / vadhanak voun/ US-0013999 - Tech Debt: fix hardcoded Id (part 1)
@                 02.11.2023 / Mony Nou/ US-0014288 - New Pre-Loved Partner Contract type
@                 06.11.2023 / Loumang SENG/ US-0014286 - Allow signatory changes post approval in contracts
@                 17.05.2024 / Loumang SENG/ US-0015042 - ACP Contract & Pricing thresholds with percentage and amount options
@                 27.06.2024 / Sophal Noch / US-0015431 - (Part 2) Contract for 3PP Partner Campaigns/Agreements in Hive
@                 01.07.2024 / Loumang SENG/ US-0015323 - Calculate Amount if % threshold is populated on ACP
@                 23.07.2024 / Loumang SENG/ US-0015533 - Generic Contract Type
@                 26.09.2024 / Sothea Horn / US-0015895 - UK/US UAT Bug Fixes
@                 05.11.2024 / Mony Nou / US-0015532 - Extend Pre-Loved Partner Contract type to AU
@                 04.12.2024 / LoumAng SENG / US-0016040: VIP Pricing Guided flow to support custom template creation
@                 09.01.2025 / Sambath Seng / US-0016114 - Pricing Configuration Record Lock - CPM, Contract other
@                 30.01.2025 / Sambath Seng / US-0016434 - Contract flow- Null point Exception
@                 30.01.2025 / LoumAng SENG / US-0016611 - Extend Pre-Loved Partner Contract type to US
@                 13.02.2025 / Mony Nou / US-0016709 - Error: You cannot edit an approved contract. Please recall to make changes and then resubmit for approval.
@				  20.02.2025 / Veenus Gollapalli / US-0016678 - Automatically update Pricing start date for contracts with start dates in the past
@                 21.02.2025 / Sambath Seng / US-0016707 - eBay Signed Date field to be populated when the contract is in signed status Executed
@                 24.02.2025 / LoumAng SENG / US-0016675 - Monetisation bypass for Plutus pricing comparison mismatch
@                 07.03.2025 / Sambath Seng / US-0016908 - Link not work on Refurbished contract when seller clicks to agree
@				  13.03.2025 / Veenus Gollapalli / US-0016935 - Preloved contract is hitting validation rule when change status to executed
@				  04.04.2025 / LoumAng SENG / US-0016860 - UAT - Testing Feedback - Placeholder
@                 14.05.2025 / LoumAng SENG / US-0026079 - Controlled Manual Contract Status changes
@                 11.06.2025 / SRONG TIN / US-0011975 - Extend Pre-Loved Partner Contract type to DE
@                 02.07.2025 / Sambath Seng / US-0032991 Allow Contract Manager to Change status from Pricing Config to Draft
@                 29.08.2025 / Mony Nou / US-0033092 - eBay Live: Contract Approval Process & other enhancements - Prt 1
@                 22.09.2025 / vadhanak voun / US-0033551 - eBay Live - BD User getting exception when submitting eBay Live Activation request
@                 10.10.2025 / Sovantheany Dim / US-0033588 - eBay Live: Feedback Enhancements 2  
@                 22.10.2025 / Sothea Horn / US-0033244 - Auto-Populate Master Contract Data in Amendments
@                 30.10.2025 / Mony Nou / US-0033722 - eBay Live: DE Contract Guided Flow from Opportunity 
@                 26.11.2025 / Mony Nou / US-0033676 - Extend Certified Recycler Contract Flow to Italy with Italian Email Templates prt 1 
@                 02.12.2025 / Leon Morocki / US-0033985 - Correct Pricing Timestamp for Daylight Savings on Hive
*********************************************************************************************************************************/
public without sharing class EBH_ContractTriggerHandler {
    /************************************* CONSTANT DEFINITION *************************************************/
    static final String ContrFinancePostCheck = 'Sent for Finance Post-check';
    static final String CONTRACT_SEND_STATUS = 'Contract Send';
    static final String CONTRACT_LISTINGRECORDTYPE       = 'EBH_ListingAgreement';
    static final String CONTRACT_ACPRECORDTYPE           = 'EBH_ACP';
    static final String CONTRACT_RSRECORDTYPE            = 'EBH_RevenueShare';
    static final String CONTRACT_VIPRECORDTYPE           = 'VIP_Contracts';
    static final String CONTRACT_FVFDISCOUNT_RECORDTYPE  = 'FVF_Discount_Contract'; //MN-03092025-
    static final String TARGETTYPE_AMOUNT = 'Amount'; //LA-17/05/2024-US-0015042
    static final String TARGETTYPE_PERCENTAGE = 'Percentage'; //LA-01/07/2024-US-0015323
     static final String AMENDMENT_CONTRACT = 'Amendment'; // SOTHEA HORN 22/10/2025 US-00332444
    
    public static final String CONTRACT_STATUS_DRAFT = 'Draft';
    public static final String CONTRACT_STATUS_CONTRACTACCEPTED = 'Contract Accepted'; //MN-30062023-US-0013756
    public static final String CONTRACT_LISTING_AGREEMENT_RECORDTYPEID = ApexUtil.getRecordTypeByName('Contract',CONTRACT_LISTINGRECORDTYPE).Id;//'0126A000000M9xVQAS';   //NK:16/08/2023:US-0013999
    public static final String CONTRACT_ACP_RECORDTYPEID = ApexUtil.getRecordTypeByName('Contract',CONTRACT_ACPRECORDTYPE).Id;//'0126A000000M9x9QAC'; //NK:16/08/2023:US-0013999
    private final static String CONTRACT_STATUS_PRICING_CONFIGURATION = 'Pricing Configuration'; // SB 09.01.2025 US-0016114
    private final static String CONTRACT_VIP_RECORDTYPEID = ApexUtil.getRecordTypeByName('Contract',CONTRACT_VIPRECORDTYPE).Id; // SB 09.01.2025 US-0016114
    private final static String CONTRACT_RSRECORDTYPE_ID = ApexUtil.getRecordTypeByName('Contract',CONTRACT_RSRECORDTYPE).Id; // LA-14-05-2025-US-US-0026079
    private final static String CONTRACT_FVFDISCOUNT_RECORDTYPEID = ApexUtil.getRecordTypeByName('Contract',CONTRACT_FVFDISCOUNT_RECORDTYPE).Id; // MN-03092025-US-0033092
    private final static Set<String> CONTRACT_RECORDTYPEID_FOR_PRICING_CONFIGURATION = new Set<String>{
        CONTRACT_VIP_RECORDTYPEID,
        CONTRACT_LISTING_AGREEMENT_RECORDTYPEID,
        CONTRACT_ACP_RECORDTYPEID
    }; // SB 09.01.2025 US-0016114
    private static final String CONTRACT_STATUS_VOIDED = 'Voided'; // SB 23.01.2025 US-0016114
    private static final String CONTRACT_STATUS_PRICING_PUBLICATION = 'Pricing Publication'; // SB 23.01.2025 US-0016114	
    private static final String CONTRACT_STATUS_READY_FOR_SIGNATURE = 'Ready for eBay Signature'; // SB 23.01.2025 US-0016114
    private static final String PLUTUS_API_PERMSET = 'Plutus_Inbound_API_Only'; //MN-13022025-US-0016709

    
    
    private static final String QUERY_CONTACT  = 'Select Id, FirstName, LastName, Email from Contact where Id in :contactidset';//LA-14-05-2025-US-0026079
    private static final Set<String> OLD_STATUSES_ALLOW = new Set<String>{'In Negotiation', 'Sent for Finance Pre-check', 'Sent for Finance Post-check', 'Approved', 'Pending Approval', 'Ready for eBay Signature'};//LA-14-05-2025-US-0026079
    private static final Set<String> OLD_STATUSES_FILTER = new Set<String>{'Pricing Configuration','Sent for eBay Signature','Pricing Publication', 'Executed', 'Voided'};//LA-14-05-2025-US-0026079 - add 'Pricing Publication', 'Pricing Publication' to the filter list
    // PRIVATE PART
    
    /************************************ END OF CONSTANT DEFINITION*******************************************/

    //To get the Pre-Approved Template rules
    static Map<String, EBH_ContractPreApprovedRules__c> rulesMap = new Map<String, EBH_ContractPreApprovedRules__c>();
    static Map<Id, String> recordTypeMap = new Map<Id, String>();
    //to store the developer name for the record types
    static Map<Id, String> recordTypeDeveloperMap = new Map<Id, String>();
    static Set<Id> contractPricingRTIds = new Set<Id>();
    
    static String RT_REFURB_NAME = 'Refurbished';
    static Id RT_REFURB_ID = ApexUtil.getRecordTypeByName('Contract',RT_REFURB_NAME).Id;

    static String RT_CERTIFIED_RECYCLER = 'Certified_Recycler'; // 12.06.2023 / CHETRA SAROM / US-0013743
    static Id RT_CERTIFIED_RECYCLER_ID = ApexUtil.getRecordTypeByName('Contract',RT_CERTIFIED_RECYCLER).Id; // 12.06.2023 / CHETRA SAROM / US-0013743
    
    //MN-02112023-US-0014288
    static String RT_PRELOVED_NAME = 'Pre_Loved_Partner_Program';
    static Id RT_PRELOVED_ID = ApexUtil.getRecordTypeByName('Contract',RT_PRELOVED_NAME).Id;

    //27.06.2024 / Sophal Noch / US-0015431 :
    private static String RT_3PP = 'Three_PP_Pricing_Program';
    private static Id RT_3PP_ID = ApexUtil.getRecordTypeByName('Contract',RT_3PP).Id;
    
    private static String RT_EBAY_GENERAL_CONTRACT = 'eBay_General_Contract';//LA-23-07-2024-US-0015533
    private static Id RT_EBAY_GENERAL_CONTRACT_ID = ApexUtil.getRecordTypeByName('Contract', RT_EBAY_GENERAL_CONTRACT).Id;//LA-23-07-2024-US-0015533

    private static String RT_TERMSCONDITIONS = 'TermsConditions'; //MN-30102025-US-0033722
    private static Id RT_TERMSCONDITIONS_ID = ApexUtil.getRecordTypeByName('Contract', RT_TERMSCONDITIONS).Id;//MN-30102025-US-0033722

    //LA-23-07-2024-US-0015533: Added RT "eBay_General_Contract" into below set
    //MN-02112023-US-0014288: Added RT "Pre_Loved_Partner_Program" into below set
    //MN-30102025-US-0033722: Added RT "TermsConditions" into below set
    static Set<Id> SET_RT_ID_NO_PRICING = new Set<Id>{RT_REFURB_ID, RT_CERTIFIED_RECYCLER_ID, RT_PRELOVED_ID, RT_3PP_ID, RT_EBAY_GENERAL_CONTRACT_ID, RT_TERMSCONDITIONS_ID}; //12.06.2023 / CHETRA SAROM / US-0013743. //27.06.2024 / Sophal Noch / US-0015431 :

    //26.09.2024 / Sothea Horn / US-0015895 - UK/US UAT Bug Fixes
    private static String RT_OPPORTUNITY_EBAY_BUSINESS_DEVELOPMENT = 'eBay_Business_Development';
    private static Id RT_OPPORTUNITY_EBAY_BUSINESS_DEVELOPMENT_ID = ApexUtil.getRecordTypeByName('Opportunity', RT_OPPORTUNITY_EBAY_BUSINESS_DEVELOPMENT).Id;

    static String PRO_CANCELLED_STATUS = 'Program Cancelled';
    static String EBAY_DECLINED_STATUS = 'eBay Declined';
    static String DE_COUNTRY = 'DE';
    static String UK_COUNTRY = 'UK'; //SB 29/10/2021 US-0010606
    static String AU_COUNTRY = 'AU'; //MN-05112024-US-0015532
    static String US_COUNTRY = 'US'; //LA-01-30-2025-US-0016611

    // Sophal:03/02/2022:US-0011123
    static String IT_COUNTRY = 'IT';
    static String FR_COUNTRY = 'FR';

    //MN-26112025-US-0033676
    static Map<String, String> MAP_COUNTRY_RETURNURL = new Map<String, String> {
        FR_COUNTRY => 'www.ebay.fr',
        IT_COUNTRY => 'www.ebay.it'
    };

    static Map<String,String> MAP_COUNTRY_TO_OWD_EMAIL = new Map<String,String>{ 
        DE_COUNTRY => Label.Refurb_DE_OWD_Email,
        IT_COUNTRY => Label.Refurb_IT_OWD_Email, // Sophal:04/02/2022:US-0011141
        FR_COUNTRY => Label.Refurb_FR_OWD_Email // Sambath Seng - 25.08.2022 - US-0011288 - FR Email Notification for Contract Status = "eBay Declined"
    };
    static Map<String,String> MAP_COUNTRY_STATUS_TO_EMAILTEMPLATE = new Map<String,String>{ 
        DE_COUNTRY+'_'+PRO_CANCELLED_STATUS => 'DE_Refurb_Program_Cancelled_Notification',
        DE_COUNTRY+'_'+EBAY_DECLINED_STATUS => 'DE_Refurb_eBay_Declined_Notification',
        IT_COUNTRY+'_'+EBAY_DECLINED_STATUS => 'IT_Refurb_eBay_Declined_Notification', // Sophal:04/02/2022:US-0011141
        IT_COUNTRY+'_'+PRO_CANCELLED_STATUS => 'IT_Refurb_Program_Cancelled_Notification', // Sambath Seng 05.08.2022 US-0011127 - IT Email Notification for Contract Status= "Program Cancelled"
        FR_COUNTRY+'_'+EBAY_DECLINED_STATUS => 'FR_Refurb_eBay_Declined_Notification', // Sambath Seng - 25.08.2022 - US-0011288 - FR Email Notification for Contract Status = "eBay Declined"
        FR_COUNTRY+'_'+PRO_CANCELLED_STATUS => 'FR_Refurb_Program_Cancelled_Notification' // CHETRA SAROM - 29.08.2022 - US-0011289 - FR Email Notification for Contract Status= "Program Cancelled"
    };
    //Start - SB 29/10/2021 US-0010606 Create new map to store Seller refurb contract email template
    static Map<String,String> MAP_COUNTRY_STATUS_TO_CSELLER_EMAILTEMPLATE = new Map<String,String>{ 
        DE_COUNTRY+'_'+CONTRACT_SEND_STATUS => 'Seller_Refurb_Contract_DE',
        UK_COUNTRY+'_'+CONTRACT_SEND_STATUS => 'Seller_Refurb_Contract_UK',
        // Sophal:03/02/2022:US-0011123
        IT_COUNTRY+'_'+CONTRACT_SEND_STATUS => 'Seller_Refurb_Contract_IT',
        FR_COUNTRY+'_'+CONTRACT_SEND_STATUS => 'Seller_Refurb_Contract_FR'
    };
    //End - SB 29/10/2021 US-0010606 Create new map to store Seller refurb contract email template

    //MN-29062023-US-0013732
    static Map<String, String> MAP_COUNTRY_STATUS_CERTIFIEDRECYCLER_EMAILTEMPLATE = new Map<String, String> {
        FR_COUNTRY + '_' + CONTRACT_SEND_STATUS => 'Seller_Certified_Recycler_Contract_FR'
        , FR_COUNTRY + '_' + CONTRACT_STATUS_CONTRACTACCEPTED => 'Seller_Certified_Recycler_ContractAcceptance_FR' //MN-30062023-US-0013756
        , IT_COUNTRY + '_' + CONTRACT_SEND_STATUS => 'Seller_Certified_Recycler_Contract_IT' //MN-26112025-US-0033676
        , IT_COUNTRY + '_' + CONTRACT_STATUS_CONTRACTACCEPTED => 'Seller_Certified_Recycler_ContractAcceptance_IT' //MN-26112025-US-0033676
    };

    //MN-29062023-US-0013732
    static Map<String, String> MAP_COUNTRY_CERTIFIEDRECYCLER_OWD = new Map<String, String> {
        FR_COUNTRY => Label.Contract_CertifiedRecycler_OWD_FR,
        IT_COUNTRY => Label.Contract_CertifiedRecycler_OWD_IT //MN-26112025-US-0033676
    };

    //MN-06112023-US-0014288
    static Map<String, String> MAP_COUNTRY_STATUS_PRELOVEDPARTNER_EMAILTEMPLATE = new Map<String, String> {
        UK_COUNTRY + '_' + CONTRACT_SEND_STATUS => 'Seller_Pre_loved_Contract_UK'
        , AU_COUNTRY + '_' + CONTRACT_SEND_STATUS => 'Seller_Pre_loved_Contract_AU' //MN-05112024-US-0015532
        , US_COUNTRY + '_' + CONTRACT_SEND_STATUS => 'Seller_Pre_loved_Contract_US' //LA-01-30-2025-US-0016611
        , DE_COUNTRY + '_' + CONTRACT_SEND_STATUS => 'Seller_Pre_loved_Contract_DE' //SRONG-06-11-2025:US-0011975
    };

    static String EMT_TCS_URL = '{!TCs_URL__c}';
    static String EMT_STARTDATE = '{!StartDate}';
    static String EMT_ENDDATE = '{!EndDate}';
    static String EMT_ACCOUNT_NAME = '{!Account.Name}';
    static String EMT_BC_MAILING_ADRESS = '{!Business_Contact__r.EBH_MailingAddress__c}';
    static String EMT_BC_MAILING_STREET = '{!Business_Contact__r.EBH_MailingStreet__c}';
    static String EMT_BC_MAILING_POSTAL_CODE = '{!Business_Contact__r.EBH_MailingPostalCode__c}';
    static String EMT_BC_MAILING_CITY = '{!Business_Contact__r.EBH_MailingCity__c}';
    static String EMT_CS_BUSINESS_NAME = '{!EBH_ContractsForSeller__r.EBH_BusinessName__c}';
    //Start - SB 29/10/2021 US-0010606 Add more field from Email Template
	static String EMT_CONTRACT_ACCOUNT = '{!Contract.Account}';
    static String EMT_BUSINESS_CONTACT_STREET = '{!Contract.BusinessContactStreet__c}';
    static String EMT_BUSINESS_CONTACT_POSTAL_CODE = '{!Contract.BusinessContactPostalCode__c}';
    static String EMT_BUSINESS_CONTACT_CITY = '{!Contract.BusinessContactCity__c}';
    static String EMT_BUSINESS_NAME = '{!EBH_ContractSeller__c.EBH_BusinessName__c}';
    static String EMT_START_DATE ='{!Contract.StartDate}';
    static String EMT_CONTRACT_SEND_DATE = '{!Contract.Contract_Send_Date__c}'; // Sophal:03/02/2022:US-0011123
    //End - SB 29/10/2021 US-0010606 Add more field from Email Template

    static String EMT_CONTRACT_BUSINESSCONTACTADDRESS = '{!Contract.BusinessContactAddress__c}'; // CHETRA SAROM / US-0011289 - FR Email Notification for Contract Status= "Program Cancelled"

    static String EMT_SITEURL_FOR_CERTIFIEDRECYCLER = '{!SITEURL}'; //MN-30062023-US-0013732

    

    /*****************************************************************************************************************************
@ Method:         validatePreApprovedTemplate
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Validates Pre-Approved Template checkbox on Contract based on the following field combination
- Site
- Language &
- Contract Record Type  
Custom Settings will store the combination of Site, Language & Contract Record Type and 
if Contract's details are matched, then Pre-Approved Template checkbox should be checked.
Otherwise Pre-Approved Template checkbox will be unchecked.
If the value is not as PAT matrix then throw an error to the user
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Contracts:      Contracts from the trigger scope
ContractOldMap: Contracts old map from the trigger scope
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.05.2017 / NEHA LUND / Created the  Method.
*****************************************************************************************************************************/
    public static void validatePreApprovedTemplate(List<Contract> contracts, Map<Id, Contract> contractOldMap) {
        
        //To only initialize once, so that custom settings and record types are not queried again
        if(rulesMap.isEmpty()) {
            
            //To get the custom settings data and store in the map
            for(EBH_ContractPreApprovedRules__c rule: EBH_ContractPreApprovedRules__c.getAll().values()) {
                
                rulesMap.put(rule.EBH_RecordType__c + EBH_ConstantsUtility.HYPHEN_KEY + rule.EBH_Site__c 
                             + EBH_ConstantsUtility.HYPHEN_KEY + rule.EBH_Language__c, rule);
            }
            
            //To get record type name from the record type ID
            for(RecordType rt: Database.query(EBH_ConstantsUtility.CTH_CONTRECTYPEQUERY)) {
                
                recordTypeMap.put(rt.id, rt.Name);
                
                recordTypeDeveloperMap.put(rt.id, rt.DeveloperName);
                
                if( rt.DeveloperName == CONTRACT_LISTINGRECORDTYPE || 
                   rt.DeveloperName == CONTRACT_ACPRECORDTYPE     ||
                   rt.DeveloperName == CONTRACT_RSRECORDTYPE ) {
                       
                       contractPricingRTIds.add(rt.Id);
                   }
                
            }
        }
        
        //parse through contracts of the trigger scope
        for(Contract cont : contracts) {
            
            if(hasPreApprovedParametersChanged(cont, contractOldMap)) {
                if(cont.EBH_PreApprovedTemplate__c != rulesMap.containsKey(RecordTypeMap.get(cont.RecordTypeId) 
                                                                           + EBH_ConstantsUtility.HYPHEN_KEY + cont.EBH_Site__c 
                                                                           + EBH_ConstantsUtility.HYPHEN_KEY + cont.EBH_Language__c)){
                                                                               
                                                                               cont.addError(Label.EBH_PreapprovedTemplateError);
                                                                           }             
            }
        }
    }
    
    /*****************************************************************************************************************************
@ Method:         setBUApprover
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        EBH-4032: To update Legal Approver and Finance Pre-Check approvers based on the Contract Matrix approval 
rules defined.
For every Site - we have Legal Approver and Finance Pre-Check approvers defined in 
Contract Matrix Approval rules 
- Every Contract Matrix Approval object will have related Contract Approval Hierarchy records
- Finance Approver
- Controlling Approver
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Contracts:      Contracts from the trigger scope
ContractOldMap: Contracts old map from the trigger scope
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.01.2017 / NEHA LUND / Created the  Method.
*****************************************************************************************************************************/
    /*  public static void setBUApprover(List<Contract> contracts, Map<Id, Contract> contractOldMap) {

Set<String> buApprovers = new Set<String>();
List<Contract> contractsToBeApproved = new List<Contract>();
Map<String,Id> groupIds = new Map<String, Id>();

for(Contract con: contracts) {

if(con.EBH_ControllingApproved__c != contractOldMap.get(con.Id).EBH_ControllingApproved__c &&
con.EBH_ControllingApproved__c && !String.isBlank(con.EBH_BUApproverGroup__c)){

buApprovers.add(con.EBH_BUApproverGroup__c);
contractsToBeApproved.add(con);
}

if(con.EBH_FinancePostCheckDone__c != contractOldMap.get(con.Id).EBH_FinancePostCheckDone__c && 
con.EBH_FinancePostCheckDone__c){

contractsToBeApproved.add(con);

}
}

if(!buApprovers.isEmpty()) {            

for(Group pg: [SELECT id, Name from Group where Name in :buApprovers]) {
groupIds.put(pg.Name,pg.Id);
}            
}

if(!contractsToBeApproved.isEmpty()){

for(Contract con: contractsToBeApproved){

//  if(!string.isBlank(con.EBH_BUApproverGroup__c) && groupIds.containsKey(con.EBH_BUApproverGroup__c)){
Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
req1.setObjectId(con.Id);
//Set the approver as public group ID
if(groupIds.containsKey(con.EBH_BUApproverGroup__c))
req1.setNextApproverIds(new Id[] {groupIds.get(con.EBH_BUApproverGroup__c)});
Approval.ProcessResult result = Approval.process(req1);
//  }                
}
}
}
*/
    /*****************************************************************************************************************************
@ Method:         updateApprovers
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        To update Legal Approver and Finance Pre-Check approvers based on the Contract Matrix approval rules defined 
For every Site - we have Legal Approver and Finance Pre-Check approvers defined in 
Contract Matrix Approval rules 
- Every Contract Matrix Approval object will have related Contract Approval Hierarchy records
- Finance Approver
- Controlling Approver
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Contracts:      Contracts from the trigger scope
ContractOldMap: Contracts old map from the trigger scope
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.05.2017 / NEHA LUND / Created the  Method.
*****************************************************************************************************************************/
    public static void updateApprovers(List<Contract> contracts, Map<Id, Contract> contractOldMap) {
        
        //dynamic approvers on the Contract
        Map<String, EBH_ContractApprovalMatrix__c> approvalMatrices = new Map<String, EBH_ContractApprovalMatrix__c>();
        EBH_CurrencyConverter cConverter = new EBH_CurrencyConverter();
        
        //get the Contract Approval Matrix rules by Site
        for(EBH_ContractApprovalMatrix__c rule : Database.query(EBH_ConstantsUtility.CTH_APPMTRXQUERY)) {
            approvalMatrices.put(rule.EBH_Site__c, rule);
        }
        Set<ID> accountIds = new Set<ID>();
        for(Contract cont : contracts) {
            accountIds.add(cont.AccountId);
        }
        Map<ID, account> accountMap = new Map<ID, Account>(
            [SELECT ID, EBH_BillingCountry__c from Account where ID IN :accountIds]);
        
        String country ='';
        String accountCountry ='';
        
        //parse through contracts of the trigger scope
        for(Contract cont : contracts) {
            country = cont.EBH_Country__c;
            accountCountry = accountMap.get(cont.accountID).EBH_BillingCountry__c;
            
            if( accountCountry == 'Germany' || accountCountry == 'DE'){
                country = 'DE';
            } else if( accountCountry == 'Spain' || accountCountry == 'ES'){
                country = 'ES';
            } else if( accountCountry == 'France' || accountCountry == 'FR'){
                country = 'FR';
            } else if( accountCountry == 'Italy' || accountCountry == 'IT'){
                country = 'IT';
            } else if( accountCountry == 'United Kingdom' || accountCountry == 'UK' || accountCountry == 'GB'){
                country = 'UK';
            } else{
                country = 'Rest of Europe';
            }
            
            //if site or value has changed or the record is new
            if( approvalMatrices.containsKey(country)) {
                
                cont.EBH_LegalApprover__c = null;
                cont.EBH_LegalApprover__c = approvalMatrices.get(country).EBH_LegalApprover__c;
                
            }
            //if site or value has changed or the record is new
            if( approvalMatrices.containsKey(country)) {
                
                cont.EBH_BUApproverGroup__c = cont.EBH_FinancePreCheckApprover__c = cont.EBH_ControllingApprover__c =
                    cont.EBH_FinanceApprover__c = null;
                cont.EBH_FinancePreCheckApprover__c = approvalMatrices.get(country).EBH_FinancePreCheckApprover__c;
                
                //loop through the approval matrix of the current contract site and find the approver to populate
                for(EBH_ContractApprovalHierarchy__c ah : 
                    
                    approvalMatrices.get(country).EBH_ContractApprovalHierarchies__r) {
                        
                        Decimal contractValue = cConverter.convert(cont.EBH_ContractValue__c, cont.CurrencyISOCode,ah.CurrencyISOcode);
                        Decimal exposureValue = cConverter.convert(cont.EBH_ContractExposure__c,cont.CurrencYISOcode ,ah.CurrencyISOcode) ;
                        
                        if(recordTypeDeveloperMap.get(ah.RecordTypeId) == EBH_ConstantsUtility.HIERARCHY_CONTROLLING) {
                            if(contractValue >= ah.EBH_Threshold__c && cont.EBH_ControllingApprover__c == null ) {
                                cont.EBH_ControllingApprover__c = ah.EBH_Approver__c;
                            }
                        } else if(recordTypeDeveloperMap.get(ah.RecordTypeId) == EBH_ConstantsUtility.HIERARCHY_FINANCE) {
                            if(exposureValue >= ah.EBH_Threshold__c && cont.EBH_FinanceApprover__c == null) {
                                cont.EBH_FinanceApprover__c = ah.EBH_Approver__c;
                            }
                        }else if(recordTypeDeveloperMap.get(ah.RecordTypeId) == EBH_ConstantsUtility.HIERARCHY_BUAPPROVER) {
                            if(contractValue >= ah.EBH_Threshold__c && cont.EBH_BUApproverGroup__c == null) {
                                cont.EBH_BUApproverGroup__c = ah.EBH_BUApproverGroup__c;
                            }
                        }
                        
                        
                    }
            } else {                
                //To Do: what should be the default approver
            }
        } 
    } 
    
    /*****************************************************************************************************************************
@ Method:         updateContractValueExposure
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        To update Contract Value & Exposure when the below Contract parameters are changed = 
US:0017
- Value & Exposure for Listing is summation of Value of Listing Record Type 
Pricing records plus Store subscription Fees based on the Store Subscription value
driven by contract

- Value & Exposure for ACP is summation of Value of ACP Record Type
Pricing records plus Average Take rate & Rebate Tier Rate is being
controlled by Contract

- Value & Exposure for Revenue Share is summation of Value of Revenue Share 
Record Type Pricing records plus Average Take rate & Rebate Tier 
Rate is being controlled by Contract
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Contracts:      Contracts from the trigger scope
ContractOldMap: Contracts old map from the trigger scope
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.05.2017 / NEHA LUND / Created the  Method.
*****************************************************************************************************************************/
public static void updateContractValueExposure(List<Contract> contracts, Map<Id, Contract> contractOldMap) {
        
    // Sophal: 19/08/2021: US-0010203 get RecordType refurbished 
    // setRtIdNoPricing = setRtIdNoPricing != null ? setRtIdNoPricing : new Set<Id>{ApexUtil.getRecordTypeByName('Contract',RT_REFURB_NAME).Id};

    List<Contract> contractsToBeUpdated = new List<Contract>();
    
    //parse through contracts of the trigger scope
    for(Contract cont : contracts) {
        //if controlling parameters on Contract are changed, then value & 
        //exposure needs to be updated along with approvers information
        /* if(hasPricingParametersChanged(cont, contractOldMap) 
|| hasSiteChanged(cont, contractOldMap)  
|| hasSiteOrValueChanged(cont, contractOldMap)) {*/
        //if( cont.status != EBH_ConstantsUtility.CONTRACT_READYFOREBAYSIGNATURE &&
        //   cont.status != 'Sent for eBay Signature')
        if(!EBH_ConstantsUtility.SET_EXCLUDE_CONTRACT.contains(cont.status) //NK:12/06/2018: EPH-5605: exclude: Executed / Voided/Signature
            && !SET_RT_ID_NO_PRICING.contains(cont.RecordTypeId)   // Sophal: 19/08/2021: US-0010203 reburb contract has no pricing, it can skipped
            //&& cont.RecordTypeId != CONTRACT_FVFDISCOUNT_RECORDTYPEID //TH:US-0033097: Comment out : allow automation update Exposure for FVFDscount record type, //MN-03092025-US-0033092: Allow user to manually update Value & Exposure for FVF Discount Contract
        ) { contractsToBeUpdated.add(cont); }
                 
        //}
    }
    
    if( ! contractsToBeUpdated.isEmpty() ){
        //update Approvers if Value/Exposure is updated
        updateApprovers( EBH_PricingTriggerHandler.updateContractValueExposure(contractsToBeUpdated, false), contractOldMap);
    }
}
    
    /*****************************************************************************************************************************
@ Method:         updateTakeRate
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        EPH-89 : To update the average take rate on Contract based on the combination of -
- Site
- Main Vertical
- Record Type 
Combinations are stored in Contract Take Rate Mapping
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Contracts:      Contracts from the trigger scope
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.10.2017 / NEHA LUND / Created the  Method.
@                 22.10.2025 / Sothea Horn / US-0033244 - Auto-Populate Master Contract Data in Amendments 
*****************************************************************************************************************************/
    public static void updateTakeRate(List<Contract> contractRecords, Map<Id, Contract> contractOldMap ) {
        
        //To only initialize once, so that custom settings and record types are not queried again
        
        Map<String, Decimal> takeRateRules = new Map<String, Decimal>();
        
        //To get the custom settings data and store in the map
        for(EBH_ContractTakeRateMapping__c rule: EBH_ContractTakeRateMapping__c.getAll().values()) {
            
            if( rule.EBH_RecordType__c == null) 
                rule.EBH_RecordType__c = EBH_ConstantsUtility.CONTRACT_NULL;
            
            takeRateRules.put(rule.EBH_Site__c + rule.EBH_MainVertical__c + rule.EBH_RecordType__c, rule.EBH_TakeRate__c);
        }
        
        //To get record type name from the record type ID
        for(RecordType rt: Database.query(EBH_ConstantsUtility.CTH_CONTRECTYPEQUERY)) {
            
            recordTypeMap.put(rt.id, rt.Name);              
        }
        
        String key, defaultKey, defaultVertical, defaultRecordType;
        
        //parse through contracts of the trigger scope
        for(Contract cont : contractRecords) {

            // 22.10.2025 / Sothea Horn / US-0033244 - Skip update average take rate for amendment contract since it will auto-populate from Master Contract
            if (cont.EBH_ContractAmendment__c == AMENDMENT_CONTRACT && 
                (cont.recordTypeId == CONTRACT_LISTING_AGREEMENT_RECORDTYPEID || 
                 cont.recordTypeId == CONTRACT_ACP_RECORDTYPEID ||
                 cont.recordTypeId == CONTRACT_VIP_RECORDTYPEID ||
                 cont.recordTypeId == CONTRACT_FVFDISCOUNT_RECORDTYPEID) ) {
                continue;
            }

            key = cont.EBH_Site__c + EBH_ConstantsUtility.CTH_DEFAULTVALUE ;
            defaultkey = cont.EBH_Site__c + cont.EBH_MainVertical__c ;
            defaultRecordType = cont.EBH_Site__c + EBH_ConstantsUtility.CTH_DEFAULTVALUE + recordTypeMap.get(cont.recordTypeId);
            
            //System.debug('#####'+key+'Default'+defaultKey+'###'+defaultREcordType);
            
            if(hasTakeRateParametersChanged(cont, contractOldMap)) {
                cont.EBH_AverageTakeRate__c = takeRateRules.containsKey(defaultRecordType) ? takeRateRules.get(defaultRecordType) :
                takeRateRules.containsKey(defaultKey) ? takeRateRules.get(defaultKey) :
                takeRateRules.get(key);
            }                                                
        }       
    }
    
    /*****************************************************************************************************************************
@ Method:         updateContractDates
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        To update the date fields when the Contract passes through a specific status changes 
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Contracts:      Contracts from the trigger scope
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.05.2017 / NEHA LUND / Created the  Method.
@ Change history: 10.07.2018 / David Herrero / Added clause when contract is clonned
@ Change history: 09.08.2021 / Sovantheany Dim / US-0009871 - [Refurb] Send Click Agreements to Contract Sellers
                : 30.01.2025 / Sambath Seng / US-0016434 - Contract flow- Null point Exception
                : 21.02.2025 / Sambath Seng / US-0016707 - eBay Signed Date field to be populated when the contract is in signed status Executed
                : 07.03.2025 / Sambath Seng / US-0016908 - Link not work on Refurbished contract when seller clicks to agree
                : 04.04.2025 / LoumAng SENG / US-0016860 - UAT - Testing Feedback - Placeholder
                : 03.09.2025 / Mony Nou / US-0033092 - eBay Live: Contract Approval Process & other enhancements - Prt 1
*****************************************************************************************************************************/
    public static void updateContractDates(List<Contract> contractRecords, Map<Id, Contract> contractOldMap ) {
        
        Set<Id> contrRecTypeIdForAutoPopulateDate = new Set<Id>{
            RT_REFURB_ID,
            RT_CERTIFIED_RECYCLER_ID,
            RT_PRELOVED_ID,
            RT_3PP_ID,
            RT_EBAY_GENERAL_CONTRACT_ID
        };
        // Start - SB 25.02.2025 US-0016707
        Set<String> contrRecTypeIdForPricingPublicSignDate = new Set<String>{
            CONTRACT_VIP_RECORDTYPEID,
            CONTRACT_LISTING_AGREEMENT_RECORDTYPEID,
            CONTRACT_FVFDISCOUNT_RECORDTYPEID //MN-03092025-US-0033092
        };
        
        Set<Id> contractIds = new Set<Id>();
        for (Contract con : contractRecords) {
            If(con.RecordTypeId == CONTRACT_ACP_RECORDTYPEID){ // Start - LA 04.04.2025 - US-0016860
                contractIds.add(con.Id);
            }
        }

        Set<Id> contractToACPNonFeatureFee = new Set<Id>();
        if(!contractIds.isEmpty()){
            String soql = 'SELECT Id, (SELECT Id FROM FeeTypes__r Limit 1) FROM Contract WHERE Id IN :contractIds';
            List<Contract> listCon = ApexSafe.query().secCheck(false).doQuery(soql,new Map<String, Object> {'contractIds' => contractIds});
            for (Contract contract : listCon) {

                // check if ACP contract has no FeeType record then it is NonFeatureFee
                if(contract.FeeTypes__r.isEmpty()){
                    contractToACPNonFeatureFee.add(contract.Id);

                }
            }
        }
        //String soql = 'select id from Contract where Id in:contractIds and Id in (SELECT EBH_ContractId__c FROM EBH_Pricing__c WHERE EBH_InsertionFees__c = null AND EBH_Subtitle__c = null AND EBH_GalleryPlus__c = null AND BoldTitle__c = null AND EBH_InternationalSiteVisibility__c = null AND EBH_PicturePack1_12__c = null AND FVF2OrderLevelFixed__c = null)';
        //SB 07.03.2025 US-0016908 - Link not work on Refurbished contract when seller clicks to agree
        //Map <Id, Contract> contractToACPNonFeatureMap = new Map<Id, Contract>((List<Contract>)ApexSafe.query().secCheck(false).doQuery(soql,new Map<String, Object> {'contractIds' => contractIds}));
        // End - SB 25.02.2025 - US-0016707
        // End - LA 04.04.2025 - US-0016860
        List<Contract> contracts = new List<Contract>();
        for( Contract con : contractRecords ){
            if((contractOldMap != null && con.Status != contractOldMap.get(con.id).Status) 
            || (!String.isBlank(con.Status) && contractOldMap == null) 
            || ((con.StartDate == null || con.EndDate == null) && contrRecTypeIdForAutoPopulateDate.contains(con.RecordTypeId)) // SB 30.01.2025 US-0016434
            ){
                // Start - // SB 30.01.2025 US-0016434
                if(contrRecTypeIdForAutoPopulateDate.contains(con.RecordTypeId)){
                    if (con.StartDate == null) {
                        con.StartDate = Date.newInstance(2000, 1, 1);
                    }
                    if (con.EndDate == null) {
                        con.EndDate = Date.newInstance(2099, 12, 31);
                    }
                }
                // End - // SB 30.01.2025 US-0016434
                if( con.Status.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_SentFinancePreChecked ) ){
                    con.EBH_DateSentforFinancePrecheck__c = Date.Today();
                } else if( con.Status.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_InNegotiation)  && 
                contractOldMap.get(con.id).Status == EBH_ConstantsUtility.CONTRACT_SentFinancePreChecked){
                    con.EBH_DateFinancePrechecked__c = Date.Today();
                } else if ( con.Status.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_InNegotiation) ) {
                    con.EBH_DateSentforNegotiation__c = Date.Today();
                } else  if ( con.Status.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_PendingApproval) ) {
                    con.EBH_DateSentforFirstApproval__c = Date.Today();
                } else if ( con.Status.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_Approved) ) {
                    con.EBH_DateApproved__c = Date.Today(); 
                } 
                //TH:09/08/2021:US-0009871 : autopopulate Contract Send Date when Contract is sent for Seller acceptance
                else if ( con.Status.equalsIgnoreCase(CONTRACT_SEND_STATUS) ) {
                con.Contract_Send_Date__c = Date.Today();
                }else if ( con.Status.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_SellerSignature ) ) {
                    con.EBH_DateSentforCustomerSignature__c = Date.Today();
                } else if ( con.Status.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_SellerSignatureProvided ) ) {
                    con.EBH_DateCustomerSignatureReturned__c = Date.Today();
                } else if( con.status.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_eBaySignatureSent) ){
                    con.CustomerSignedDate = Date.Today();
                } 
                // SB 21.02.2025 US-0016707
                else if (
                    // Start - LA 04.04.2025 - US-0016860
                    //(contrRecTypeIdForPricingPublicSignDate.contains(con.RecordTypeId) || (con.RecordTypeId == CONTRACT_ACP_RECORDTYPEID && !contractToACPNonFeatureMap.containsKey(con.Id))) && con.status.equalsIgnoreCase(CONTRACT_STATUS_PRICING_PUBLICATION) || 
                    //(!contrRecTypeIdForPricingPublicSignDate.contains(con.RecordTypeId) || contractToACPNonFeatureMap.containsKey(con.Id)) && con.status.equalsIgnoreCase('Executed'))
                    (contrRecTypeIdForPricingPublicSignDate.contains(con.RecordTypeId) || (con.RecordTypeId == CONTRACT_ACP_RECORDTYPEID && !contractToACPNonFeatureFee.contains(con.Id))) && con.status.equalsIgnoreCase(CONTRACT_STATUS_PRICING_PUBLICATION) || 
                    (!contrRecTypeIdForPricingPublicSignDate.contains(con.RecordTypeId) || contractToACPNonFeatureFee.contains(con.Id)) && con.status.equalsIgnoreCase('Executed'))
                    // End - LA 04.04.2025-US-0016860
                {
                    con.CompanySignedDate = Date.Today();
                }
                   
                contracts.add( con);
            }
        }
    }
    
    /*****************************************************************************************************************************
@ Method:         updateApprovalComments
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        To update Cancellation Reason, when the request is rejected
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Contracts:      Contracts from the trigger scope
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.05.2017 / NEHA LUND / Created the  Method.
*****************************************************************************************************************************/
    @future
    public static void updateApprovalComments(Set <ID> contracts) {
        
        Map<Id,Contract> contractMap  =  new Map<Id,Contract>((List<Contract>)
                                                              Database.query(EBH_ConstantsUtility.CTH_CONTRACTMAPQUERY));
        List<Contract> updateContracts = new List<Contract>();
        
        for(Contract contractRecord : contractMap.values()) {
            //if it matches any of the approval criteria and rejected then populate the comments
            if (!contractMap.get(contractRecord.id).ProcessSteps.isEmpty()  
                && (contractRecord.Status.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_DRAFTSTATUS) 
                    || contractRecord.Status.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_NEGOTIATIONSTATUS))) {
                        if( contractMap.get(contractRecord.id).ProcessSteps[0].StepStatus =='Rejected'){
                            contractRecord.EBH_CancellationReason__c = contractMap.get(contractRecord.id).ProcessSteps[0].Comments;
                            updateContracts.add(contractRecord);
                            break;
                        }
                    }
        }
        
        if(!updateContracts.isEmpty()){
            try{
                update updateContracts;
            } catch(Exception ex) {
                EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.CTH_CONTRACTCLASS, EBH_ConstantsUtility.CTH_METHOD);
            }
        }
    }
    
    /*****************************************************************************************************************************
@ Method:         hasTakeRateParametersChanged
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        EPH-89 : To check if the Contract's any of the deciding take rate parameters have changed, or when contract 
is created
@ Parameter:      contract:           contract to check field(s) change for Site, Language & Record Type
contractOldMap:     contract old map from trigger scope to compare
------------------------------------------------------------------------------------------------------------------------------
@ Returns:        Boolean: True if any of the field changed
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.05.2017 / NEHA LUND / Created the  Method.
*****************************************************************************************************************************/
    public static Boolean hasTakeRateParametersChanged( Contract contract, Map<Id, Contract> contractOldMap) {
        
        Contract oldCon = contractOldMap != Null ? contractOldMap.get(contract.Id) : contract;
        
        return contract.EBH_Site__c != oldCon.EBH_Site__c ||
            contract.EBH_MainVertical__c != oldCon.EBH_MainVertical__c ||
            contract.RecordTypeId != oldCon.RecordTypeId ||
            contractOldMap == null;
    }
    
    /*****************************************************************************************************************************
@ Method:         hasPreApprovedParametersChanged
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        To check if the Contract's any of the deciding pre-approved parameters have changed, or when contract 
is created
@ Parameter:      contract:           contract to check field(s) change for Site, Language & Record Type
contractOldMap:     contract old map from trigger scope to compare
------------------------------------------------------------------------------------------------------------------------------
@ Returns:        Boolean: True if any of the field changed
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.05.2017 / NEHA LUND / Created the  Method.
*****************************************************************************************************************************/
    public static Boolean hasPreApprovedParametersChanged( Contract contract, Map<Id, Contract> contractOldMap) {
        
        Contract oldCon = contractOldMap != Null ? contractOldMap.get(contract.Id) : contract;
        
        return (contract.EBH_Site__c != oldCon.EBH_Site__c ||
                contract.EBH_Language__c != oldCon.EBH_Language__c ||
                contract.RecordTypeId != oldCon.RecordTypeId ||
                contract.EBH_PreApprovedTemplate__c != oldCon.EBH_PreApprovedTemplate__c ||
                contractOldMap == null) && 
            contract.EBH_PreApprovedTemplate__c;
    }
    
    /*****************************************************************************************************************************
@ Method:         hasSiteChanged
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        To check if the Contract's Site is changed, then Approvers will be changed, Legal Approver 
If Contract Value is changed, then following fields will change
- Legal Approver
@ Parameter:      contract:           contract to check field(s) change for Site, Language & Record Type
contractOldMap:     contract old map from trigger scope to compare
------------------------------------------------------------------------------------------------------------------------------
@ Returns:        Boolean: True if any of the field changed
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.05.2017 / NEHA LUND / Created the  Method.
*****************************************************************************************************************************/
    /*   public static Boolean hasSiteChanged(Contract contract, Map<Id, Contract> contractOldMap) {

Contract oldCon = contractOldMap != Null ? contractOldMap.get(contract.Id) : contract;

return contract.EBH_Site__c != oldCon.EBH_Site__c || contractOldMap == null;               
}
*/ 
    /*****************************************************************************************************************************
@ Method:         hasPricingParametersChanged
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        To check if the Contract's controlling fields are changed
@ Parameter:      contract:           contract to check field(s) 
contractOldMap:     contract old map from trigger scope to compare
- Store Subscription
- Average Take Rate
- Rebate Tier Rebate
- Revenue Share Rate
------------------------------------------------------------------------------------------------------------------------------
@ Returns:        Boolean: True if any of the field changed
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.05.2017 / NEHA LUND / Created the  Method.
*****************************************************************************************************************************/
    /*   public static Boolean hasPricingParametersChanged(Contract contract, Map<Id, Contract> contractOldMap) {

Contract oldCon = contractOldMap != Null ? contractOldMap.get(contract.Id) : contract;

return contract.EBH_StoreSubscription__c != oldCon.EBH_StoreSubscription__c ||
contract.EBH_AverageTakeRate__c != oldCon.EBH_AverageTakeRate__c ||
contract.EBH_RebateTierrebate__c != oldCon.EBH_RebateTierrebate__c ||
contract.EBH_RevenueShareRate__c != oldCon.EBH_RevenueShareRate__c;

}
*/
    /*****************************************************************************************************************************
@ Method:         hasSiteOrValueChanged
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        To check if the Contract's Site is changed, then Approvers will be changed, Legal Approver and Finance 
Pre-check approver
If Contract Value is changed, then following fields will change
- Controlling Approver
- Finance Pre-check Approver
@ Parameter:      contract:           contract to check field(s) change for Site, Language & Record Type
contractOldMap:     contract old map from trigger scope to compare
------------------------------------------------------------------------------------------------------------------------------
@ Returns:        Boolean: True if any of the field changed
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.05.2017 / NEHA LUND / Created the  Method.
*****************************************************************************************************************************/
    /*  public static Boolean hasSiteOrValueChanged(Contract contract, Map<Id, Contract> contractOldMap) {

Contract oldCon = contractOldMap != Null ? contractOldMap.get(contract.Id) : contract;

return contract.EBH_Site__c != oldCon.EBH_Site__c ||
contract.EBH_ContractValue__c != oldCon.EBH_ContractValue__c ||
contract.EBH_ContractExposure__c != oldCon.EBH_ContractExposure__c ||
contract.RecordTypeId != oldCon.RecordTypeId ||
(contractOldMap == null && 
contractPricingRTIds.contains(contract.RecordTypeId));
}  
*/
    /*****************************************************************************************************************************
@ Method:         lockContractUpdate
@ Version:        1.0
@ Author:         ASHISH BARANWAL
@ Purpose:        [EBH] (EPH-4159) - To lock the update of Contract when status id Ready for eBay Signature
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Contracts:      Contracts from the trigger scope
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.11.2017 / ASHISH BARANWAL / Created the  Method.
05.02.2018 / David Herrero / Added list of exclusions to be able to edit Some fields
06/02/2018 / Vadhanak Voun / EPH-5367: Added "isBUPending" check to ensure that record under BU Approval must be locked
17/04/2018 / David Herrero / Add exclusions to lockContractUpdate
28/03/2022 / Acmatac SEING / US-0011334 - "Reset to Draft" Capabilities for Contract owners and validations
10.8.2022 / Sambath Seng / US-0012309 - [Refurb] Allow user to update DeclinedReason & ContractEndDate at the specific contract stage
06.11.2023 / Loumang SENG/ US-0014286 - Allow signatory changes post approval in contracts
22.08.2024 / Sambath Seng / US-0015609 - DocuSign - Contract - Upgrade and Enhance DocuSign
13.02.2025 / Mony Nou / US-0016709 - Error: You cannot edit an approved contract. Please recall to make changes and then resubmit for approval.
24.02.2025 / LoumAng SENG / US-0016675 - Monetisation bypass for Plutus pricing comparison mismatch
11.04.2025 / Mony Nou / US-0016860 - UAT - Testing Feedback - Placeholder
12.05.2025 / LoumAng SENG / US-0026079 - Controlled Manual Contract Status changes
11.06.2025 / SRONG TIN / US-0011975 - Extend Pre-Loved Partner Contract type to DE
22.09.2025 / vadhanak voun / US-0033551 - eBay Live - BD User getting exception when submitting eBay Live Activation request 
*****************************************************************************************************************************/
    public static void lockContractUpdate (List<Contract> contracts, Map<Id, Contract> contractOldMap) {
        
        Map<String, Schema.SObjectField> contractFields 
            = Schema.getGlobalDescribe().get(EBH_ConstantsUtility.CONTRACT_CONTAPINAME).getDescribe().fields.getMap();

        // List<PermissionSetAssignment> ps = [SELECT id  from PermissionSetAssignment where AssigneeId = :USerInfo.getUserId() 
        // and PermissionSet.Name = 'EBH_ContractAdmin'];        //DHE 2018/04/17

        Boolean isContractAdmin = FeatureManagement.checkPermission('EBH_ContractAdmin');
        
        Boolean isPricingManager = FeatureManagement.checkPermission('Pricing_Manager'); //MN-11042025-US-0016860-AC13.1

        //Since this permission set uses "Salesforce API Integration" license, we couldn't assign Custom Permission to it so we have to check with PermissionSetAssignment
        Boolean isPlutusAPI = ApexUtil.checkPermissionSet(new Set<String>{PLUTUS_API_PERMSET}); //MN-13022025-US-0016709

        set<String> allowedProfiles = new set<String>{'System Administrator','Business Admin', 'AutomatedProcess'}; //DHE 2018/04/17 //MN-02092025-US-0033092: Added AutomatedProcess

        //MN-20082025-US-0033092--START
        Boolean isAutomatedUser = UserInfo.getUserType() == 'AutomatedProcess'; //Flow Approval Process is using Automated Process User so we need to account for that
        String profileName = (isAutomatedUser)?'AutomatedProcess':'';
        if (String.isBlank(profileName)) {
            String query = 'SELECT Id, Profile.Name FROM User WHERE Id=:userId';
            List<User> user  = (List<User>)ApexSafe.query().secCheck(false).doQuery(query,new Map<String, Object> {'userId' => UserInfo.getUserId()}); 
            profileName = user[0].Profile.Name;
            // profileName=[select Name from profile where id=:UserInfo.getProfileId()].Name;//DHE 2018/04/17
        }
        //MN-20082025-US-0033092--END
        

        //String profileName=[select Name from profile where id=:UserInfo.getProfileId()].Name;//DHE 2018/04/17

        
        

        ////MN-13022025-US-0016709: Skip this validation for the following criterias
       if (isPlutusAPI || allowedProfiles.contains(profileName) || isContractAdmin) { return; }


        List<String> fieldExceptions = new List<String>{'Actual_approver__c',
            'CompanySignedDate',
            'CustomerSignedDate',
            'Reminder_Email_Send_Date__c',//SRONG-06-11-2025:US-0011975
            'EBH_ApprovalProcessControl__c',
            'EBH_Approved__c',
            'EBH_AttachmentCheck__c',
            'EBH_BUApproverGroup__c',
            'EBH_CancellationReason__c',
            'EBH_ContractExposure__c',
            'EBH_ContractValue__c',
            'EBH_DateApproved__c',
            'EBH_ApprovalProcessControl',
            'EBH_DateCustomerSignatureReturned__c',
            'EBH_DateSentforCustomerSignature__c',
            'EBH_DateSentforFirstApproval__c',
            'EBH_DateSentforNegotiation__c',
            'EBH_EUSignNotes__c',
            'EBH_FinanceApprover__c',
            'EBH_FinancePostCheckDone__c',
            'EBH_FinancePreCheckApprover__c',
            'EBH_LegalApprover__c',
            'EBH_LegalApprover__c',
            'EndDate',
            'LastModifiedById',
            'LastModifiedDate',
            'List_Control_Values__c',            
            'StatusCode',
            'SystemModstamp',
            'Contract_Signed_by__c',
            'Contract_Accept_Date__c',
            'Contract_Send_Date__c',
            'Reminder_Period__c', //Sambath Seng 10.8.2022 US-0012309 - [Refurb] Allow user to update DeclinedReason & ContractEndDate at the specific contract stage
            'Declined_Reason__c', //Sambath Seng 10.8.2022 US-0012309 - [Refurb] Allow user to update DeclinedReason & ContractEndDate at the specific contract stage
            'Business_Contact__c', //LA-06.11.2023-US-0014286 - Allow signatory changes post approval in contracts
            'UpdatedByDocusign__c', //Sambath Seng 22.8.2024 US-0015609
            'BypassOn__c',//LA-24-02-2025-US-0016675
            'ReasonforBypass__c' //LA-24-02-2025-US-0016675

        };
                
                for(Contract con : contracts) {  
                    //this contract is marked as changed from system, so bypass the validation
                    if(con.SystemChanged__c <> contractOldMap.get(con.id).SystemChanged__c)continue;//NK:22/09/2025: US-0033551

                    if(
                        // isBUPending(contracts, con) || //vadhanak:06/02/2018
                        // Sambath Seng 22.8.2024 US-0015609 add con.UpdatedByDocusign__c == false to bypass when update by Docusign
                        (con.UpdatedByDocusign__c == false && con.Status != 'Draft' &&	con.Status != 'In Negotiation' && contractOldMap.get(con.id).Status != 'Draft') || //DHE 2018/04/17
                        
                        (contractOldMap.get(con.id).Status == 'Approved'||
                        contractOldMap.get(con.id).Status == 'Sent for Seller Signature'   ||

                        contractOldMap.get(con.id).Status == EBH_ConstantsUtility.CONTRACT_READYFOREBAYSIGNATURE ||
                        contractOldMap.get(con.id).Status == EBH_ConstantsUtility.CONTRACT_VOIDEDSTATUS ) && con.Status != 'Draft' && con.OwnerId != UserInfo.getUserId()) { //US-0011334 - Acmatac SEING - "Reset to Draft" Capabilities for Contract owners and validations                
                            
                            for(Schema.SObjectField fld : contractFields.values()) {
                                
                                String fldName = fld.getDescribe().getName();
                                //System.debug('#####' + fldName);

                                //MN-11042025-US-0016860-AC13.1: Skip this validation when Pricing Manager update field Pricing_Configured__c in "Pricing Configuration" Status
                                if (fldName == 'Pricing_Configured__c' && isPricingManager && con.Status == CONTRACT_STATUS_PRICING_CONFIGURATION) { continue; }


                                if(fldName != EBH_ConstantsUtility.CONTRACT_CONTSTATUSAPINAME &&
                                   !fieldExceptions.contains(fldName) &&
                                   //need to move into constant utility call 
                                   con.get(fldName) != contractOldMap.get(con.id).get(fldName)
                                   && !allowedProfiles.contains(profileName)//DHE 2018/04/17
                                   && !isContractAdmin
                                  ) {
                                      
                                      //System.debug('fldName 2>> ' + fldName);
                                      con.addError(  EBH_ConstantsUtility.CONTRACT_LOCKERROR +' {errCode: _Con800_Apex001}');
                                  }
                            }
                        }
                }
    }
    
    /*****************************************************************************************************************************
@ Method:         isBUPending
@ Version:        1.0
@ Author:         Vadhanak Voun	
@ Purpose:        EPH-5367 - For unknown reason, Contract is not locked by standard Approval process. 
@							 This trigger to support (lockContractUpdate) when approval stage is under BU Approval pending, then lock the record.
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Contracts:      List of Contracts from the trigger scope
@				  Contract		  Single contract to check the approval stage
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.02.2018 / Vadhanak Voun / Created the  Method.

*****************************************************************************************************************************/
    /*private static Set<String> setBUPending;
private static Boolean isBUPending(List<Contract> listContract,Contract con){
if(setBUPending==null){
setBUPending = new Set<String>();
Set<String> contractIds = new Set<String>();

for(Contract c: listContract){
contractIds.add(c.Id);		
}

for(ProcessInstanceNode pNode : Database.query(EBH_ConstantsUtility.SOQL_PROCESSINTANCE_NODE_BY_CONTRACT)){
setBUPending.add(pNode.ProcessInstance.TargetObjectId);		
}
}

return setBUPending.contains(con.Id);	
}
*/
    
    /*****************************************************************************************************************************
@ Method:         validateNotSubmittingWithZeroPricing
@ Version:        1.0
@ Author:         David Herrero	
@ Purpose:        Not Allow any user to submit a Contract into the approval process if it has not at lest 1 pricing attached to the contract
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Contracts:      List of Contracts from the trigger scope

------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.05.2018 / David Herrero / Created the  Method.
*****************************************************************************************************************************
@ Change history: 19.06.2020 / Sophal Noch / Update the  Method.
@ Purpose:         US-0007662 To throw the below existing error message when contract is submitted for Approval 
@                   for reaching the stage "Finance Post Check" and Contract.Number_of_Pricing_records__c==0 .
@                   Not to be thrown for the stages "Draft","In Negotiation" or "Finance Pre check" or "Voided".
@                   Basically, Adding In Negotiation and Sent for Finance Pre-check Status to Condition
@*****************************************************************************************************************************
@ Change history: 06.08.2021 / Sophal Noch / US-0009896 Update the  Method.              
*****************************************************************************************************************************/    
    public static void validateNotSubmittingWithZeroPricing(List<Contract>listContracts)   {

        // Sophal: 06/08/2021: US-0009896 get RecordType refurbished 
        // setRtIdNoPricing = setRtIdNoPricing != null ? setRtIdNoPricing : new Set<Id>{ApexUtil.getRecordTypeByName('Contract',RT_REFURB_NAME).Id};

        for (Contract c:listContracts){
            if(c.Status!=EBH_ConstantsUtility.CONTRACT_DRAFTSTATUS 
                && c.Status!=EBH_ConstantsUtility.CONTRACT_VOIDEDSTATUS 
                && c.Status!= EBH_ConstantsUtility.CONTRACT_InNegotiation
                && c.Status!= EBH_ConstantsUtility.CONTRACT_SentFinancePreChecked
                && c.Number_of_Pricing_records__c==0 
                && !SET_RT_ID_NO_PRICING.contains(c.RecordTypeId) // Sophal: 06/08/2021: US-0009896 skip if recordtype is refurbished
                && !test.isRunningTest()
            ){
                c.addError(Label.Not_Submit_Without_Pricing);
            }
        }
        
    }

 /*****************************************************************************************************************************
@ Method:         resetFieldsOnInsert
@ Version:        1.0
@ Author:         David Herrero	
@ Purpose:        Not Allow any user to submit a Contract into the approval process if it has not at lest 1 pricing attached to the contract
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Contracts:      List of Contracts from the trigger scope

------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.05.2018 / David Herrero / Created the  Method.
                  26.09.2024 / Sothea Horn / modified method to bypass set the status back to draft 
                  and do not blank when Global contract created from BD opportunity (US-0015895 - UK/US UAT Bug Fixes)
                  25.09.2025 / Sovantheany Dim / US-0033097 - eBay Live: Feedback Enhancements 
*****************************************************************************************************************************/    
    public static void resetFieldsOnInsert(List<Contract> listContracts ){ 
        //SH: US-0015895 - UK/US UAT Bug Fixes 
        //store the related opportunity Id in a set
        Set<Id> oppIdsSet = new  Set<Id>();
        for (Contract con : listContracts){
            oppIdsSet.add(con.Opportunity__c);
        }
        //get the related opportunity recordTypeId and store as map
        Map<String, String> mapOppRecordTypeIds = new Map<String, String> ();
        List<Opportunity> oppList = ApexSafe.query().doQuery('select Id, RecordTypeId from Opportunity where Id IN:oppIdsSet',new Map<String, Object> {'oppIdsSet' => oppIdsSet});
        for (Opportunity opp : oppList) {
            mapOppRecordTypeIds.put(opp.Id, opp.RecordTypeId);
        }
        for (Contract con : listContracts){
            //SH - 27.09.2024 : US-0015895 - UK/US UAT Bug Fixes : bypass set the status back to draft and do not blank when Global contract created from BD opportunity
            String oppRecordTypeId = mapOppRecordTypeIds.get(con.Opportunity__c);            
            if(con.RecordTypeId == RT_EBAY_GENERAL_CONTRACT_ID && oppRecordTypeId == RT_OPPORTUNITY_EBAY_BUSINESS_DEVELOPMENT_ID){
                continue;
            }
            
            con.status = CONTRACT_STATUS_DRAFT;
            con.CompanySignedDate = null;
            con.CustomerSignedDate = null;        
            con.EBH_DateSentforCustomerSignature__c=null;
            con.EBH_DateSentforFinancePrecheck__c=null;
            con.EBH_DateSentforNegotiation__c=null;
            con.EBH_DateApproved__c=null;
            con.EBH_DateCustomerSignatureReturned__c=null;
            con.EBH_DateFinancePrechecked__c=null;
            con.EBH_DateSentforFirstApproval__c=null;
            con.EBH_eBaySignedBy__c=null;
            //Move the populate logic from Workflow Rule "EPH_ContractCloneReset" and deactivate them:
            //[EBH] (EPH-57) - To reset the Contract Finance Agrees in Principle whenever the Contract is created
            con.EBH_FinanceAgreesinPrincipal__c = false;
            con.EBH_ContractExposure__c = null;
            //TH:US-0033097: Skip setting Contract Value to null for FVF Discount contract as FVF Discount contract value is auto populate from Contract guided flow
            con.EBH_ContractValue__c = con.RecordTypeId == CONTRACT_FVFDISCOUNT_RECORDTYPEID ? con.EBH_ContractValue__c: null;
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         validatePricingDate
    @ Version:        1.0
    @ Author:         Dim sovantheany(sovantheany.dim@gaea-sys.com)	
    @ Purpose:        US-0007005 [Contracts] Pricing Fields to be exposed in Contracts
    @ Validation 1 – Object “Contract”
    @ Note - This rule alone should exclude System Admin and Integration users profiles
    @ Throw error message if Any other standard user profile user other than contract owner without "Contract Admin" permission set tries to edit the pricing dates in Contract record
    @ “Only Contract Owner or users with "Contract Admin" permission can edit the Pricing Start/End dates”
    @
    @ Validation 2 – Pricing Start Date must be >= Contract Start Date and <=Contract End Date
    @ When the Contract owner or ant user with "Contract Admin" permission edits the Pricing Start date field in Contract and if the date value does not meet the above criteria throw an error message
    @ “Pricing Start Date must be >= Contract Start Date AND <=Contract End Date”
    @
    @ Validation 3 - Pricing End Date must be > Contract Start Date and <= Contract End Date
    @ When the Contract owner or ant user with "Contract Admin" permission edits the Pricing End date field in Contract and if the date value does not meet the above criteria throw an error message
    @ “Pricing End Date must be >= Contract Start Date AND <=Contract End Date”
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    newContracts : List<Contract>
    				oldMapContracts : Map<Id,Contract>
    ------------------------------------------------------------------------------------------------------------------------------				
   	@ Event		: Before Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.01.2020 / Dim sovantheany / Created the Method.
    @ Change history: 05.01.2023 / Bora Chhorn / US-0013027 - Add System Admin limited privileges to profiles who can edit contracts
    @ Change history: 20.02.2025 / Veenus Gollapalli / US-0016678 - Automatically update Pricing start date for contracts with start dates in the past
    @ Change history: 13.03.2025 / Veenus Gollapalli / US-0016935 - Preloved contract is hitting validation rule when change status to executed
    *****************************************************************************************************************************/    
    public static void validatePricingDate(List<Contract> newContracts, Map<Id, Contract> oldMapContracts){
        // BR-05-01-23
        // Boolean isAdmin = (Userinfo.getprofileId()==EBH_ConstantsUtility.ADMIN_PROFILE_ID);
        // Boolean isStandard = (Userinfo.getprofileId()==EBH_ConstantsUtility.PROFILE_ID_STANDARD);
        Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID);
		// VG-20-02-2025
        Boolean isStandard = (Userinfo.getprofileId()==ApexUtil.PROFILE_ID_STANDARD)||(UserInfo.getProfileId() == ApexUtil.NA_STANDARD_USER_PROFILE_ID);
        Boolean isAdminPriv = (Userinfo.getprofileId()==ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
         
        // END BR-05-01-23
        Boolean isContractAdmin = ApexUtil.checkPermissionSet(new Set<String>{EBH_ConstantsUtility.PERMISSION_SET_CONTRACT_ADMIN});
    	String currentUser = UserInfo.getUserId();
    	 
        for (Contract con : newContracts){
        	Contract oldCon = oldMapContracts.get(con.Id);
        	if((con.EBH_PricingStartDate__c != oldCon.EBH_PricingStartDate__c) || con.EBH_PricingEndDate__c != oldCon.EBH_PricingEndDate__c){
                // VG-26-02-2025
				// VG-13-03-2025
        		if(!isAdmin && !isStandard && !isAdminPriv || (isStandard && currentUser != con.OwnerId && !isContractAdmin && !(con.UpdatedByDocusign__c == true && con.Status == 'Executed' && con.Status != oldCon.Status && CONTRACT_RECORDTYPEID_FOR_PRICING_CONFIGURATION.contains(con.RecordTypeId)))){
        			con.addError(Label.Err_Contract_Pricing_Date);
        		}else if(con.EBH_PricingStartDate__c > con.EndDate || con.EBH_PricingStartDate__c < con.StartDate){
        			con.addError(Label.Err_Contract_Pricing_Start_Date);
        		}else if(con.EBH_PricingEndDate__c > con.EndDate || con.EBH_PricingEndDate__c < con.StartDate){
        			con.addError(Label.Err_Contract_Pricing_End_Date);
        		}
        	}
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         setDefaultPricingDate
    @ Version:        1.0
    @ Author:         Dim sovantheany(sovantheany.dim@gaea-sys.com)	
    @ Purpose:        US-0007167
    @ Description:
    @ Expected - On Creation of ACP, Listing Agreement or Revenue share contracts
    @ The Pricing Start Date and Pricing End Date in Contract should default to "Contract Start Date" and "Contract End Date"
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    newContracts : List<Contract>
    ------------------------------------------------------------------------------------------------------------------------------				
   	@ Event		: Before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.02.2020 / Dim sovantheany / Created the Method.
    @               : 04.12.2024 / LoumAng SENG / US-0016040: VIP Pricing Guided flow to support custom template creation
    *****************************************************************************************************************************/
    public static void setDefaultPricingDate(List<Contract> newContracts){ 
    	set<String> sContractRecordType = new Set<String>{ApexUtil.getRecordTypeByName('Contract',CONTRACT_ACPRECORDTYPE).Id, ApexUtil.getRecordTypeByName('Contract',CONTRACT_LISTINGRECORDTYPE).Id,ApexUtil.getRecordTypeByName('Contract',CONTRACT_RSRECORDTYPE).Id,ApexUtil.getRecordTypeByName('Contract',CONTRACT_VIPRECORDTYPE).Id};
    	for(Contract contr : newContracts){
    		if(!sContractRecordType.Contains(contr.RecordTypeId)) continue;
    		contr.EBH_PricingStartDate__c = contr.StartDate;
    		contr.EBH_PricingEndDate__c = contr.EndDate;
    	}
    }

    /*****************************************************************************************************************************
    @ Method:         validateBeforeSubmittingForPostCheck
    @ Version:        1.0
    @ Author:         Sreymeas Nao(sreymeas.nao@gaea-sys.com)	
    @ Purpose:        US-0007544 - [Contracts] Contract Sellers to be made mandatory at stage "Finance Post check"
    @ Description:
    @ Contract.record type = "ACP" or "Listing Agreement" Or "Revenue Share" or "VIP Contract"
    @ When Contract Owner submits for Finance post check Approval ( Contract.Status = "Sent for Finance Post-check" )
    @ Query if there are related EBH_ContractSeller__c records associated with the Contract >0
    @ then allow the submission for Approval to proceed else throw the below error message
    @ ---------------------------------------------------------------------------------------------------------------------------
    @ US-0010190 - [Docusign] Validations to ensure Contract Document is attached before submitting for post check approval
    @ Given that I am any user
    @ when I select a Contract (record type = ACP or Listing Agreement or Revenue share) and click "Submit for Approval" for Post check approval
    @ CHECK if ".pdf" document is attached , if no document attached
    @ throw an error message
    @ "Please attach the right contract document before submitting for approval"
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    List<Contract> newContracts, Map<Id,Contract> oldContracts
    ------------------------------------------------------------------------------------------------------------------------------				
   	@ Event		: Before Insert, Before Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.05.2020 / Sreymeas Nao / Created the Method.
    @ Change history: 30.08.2021 / Sovantheany Dim / Update the Method.	US-0010190
	@ Change history: 05.06.2024 / Veenus Gollapalli / Update the Method. US-0015174
	@ Change history: 08.07.2024 / Veenus Gollapalli / Update the Method. US-0015324
    @               : 14.05.2025 / LoumAng SENG / US-0026079 - Controlled Manual Contract Status changes
    @               : 10.10.2025 / Sovantheany Dim / US-0033588 - add FVF Discount Record type
    *****************************************************************************************************************************/
    
    public static void validateBeforeSubmittingForPostCheck(List<Contract> newContracts, Map<Id,Contract> oldContracts){
        set<String> sContractRecordType = new Set<String>{CONTRACT_ACP_RECORDTYPEID, CONTRACT_LISTING_AGREEMENT_RECORDTYPEID, CONTRACT_RSRECORDTYPE_ID, CONTRACT_VIP_RECORDTYPEID, CONTRACT_FVFDISCOUNT_RECORDTYPEID};
        //VG: US-0015324 - Seller signatory required for Listing agreement - remove
        Set<Id> contactidset = new Set<Id>();
        Map<Id,Contact> buisnessContactmap = new Map<Id,Contact>();
        for (Contract contract : newContracts) {
            if(sContractRecordType.contains(contract.RecordTypeId) && contract.Business_Contact__c != null){
                contactidset.add(contract.Business_Contact__c);
            }
        }
        if(!Contactidset.isempty()){
            //--START--LA-14-05-2025-US-0026079 - prevent ApexCRUDViolation
            List<Contact> listContact = ApexSafe.query().secCheck(false).doQuery(QUERY_CONTACT, new Map<String, Object> {'contactidset' => contactidset});
            for(Contact con: listContact){
            //for(Contact con: [Select FirstName,LastName,Email from Contact where Id in :contactidset]){ //--END-- LA-14-05-2025-US-0026079 - prevent ApexCRUDViolation
                buisnessContactmap.put(con.Id,con);
            } 
        }
		//VG: US-0015324
        for (Contract contr : newContracts) {
            if (oldContracts<>null && contr.Status <> oldContracts.get(contr.Id).Status && contr.Status==contrFinancePostCheck && sContractRecordType.contains(contr.RecordTypeId)){
                if(contr.Number_of_sellers__c == 0) contr.addError(Label.Not_Submit_Contract_Without_Contract_Seller);
                
                //LA-14-05-2025-US-0026079 - only allow to change stage from Draft to Final Approval for LA/ACP/VIP contracts
                if(oldContracts.get(contr.Id).Status != CONTRACT_STATUS_DRAFT && contr.RecordTypeId != CONTRACT_RSRECORDTYPE_ID){ contr.addError(Label.FinalApprovalStageValidate); }
                
                //TH: US-0010190: Validations to ensure Contract Document is attached before submitting for post check approval
                if(!contr.EBH_AttachmentCheck__c) contr.addError(Label.Not_Submit_Contract_Without_PDF_Att);   
                //VG: US-0015324 - Seller signatory required for Listing agreement - remove
                if(contr.Business_Contact__c != null){
                    Contact bContact = buisnessContactmap.get(contr.Business_Contact__c);
                    if(bContact!=null){
                        if(bContact.FirstName == null ||bContact.LastName == null ||bContact.Email == null){
                            contr.addError(Label.BusinessContactValidation);
                        }  
                    }                        
                }else{
                    contr.addError(Label.BusinessContactValidation); 
                }
                
            }
        }
    }
    
    /*****************************************************************************************************************************
	 @ Method:         assignUniqueKey
	 @ Version:        1.0
	 @ Author:         Sovantheany Dim
	 @ Purpose:        US-0009871 - [Refurb] Send Click Agreements to Contract Sellers
     @ Event:          before insert,before update
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Returns:        void
	 ------------------------------------------------------------------------------------------------------------------------------
	 @ Change history:  16.08.2021 / Sovantheany Dim /Created the Method.
	 *****************************************************************************************************************************/	
	 public static void assignUniqueKey(List<Contract> listNew)
    {
        for(Contract c: listNew)
        {
            if(c.Unique_Id__c == null)
            {                 
                c.Unique_Id__c = ApexUtil.doEncrypt(System.now().formatLong()+'',ApexUtil.encryptionkey).left(30).replace('+','');//url decode + to space. 
            }
        }
    }


    /*********************************************************************************************************************************
    @ Method:         sendCertifiedRecyclerEmail
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Event:		  after update
    @ Purpose:        US-0013732 - Send Click Contracts for FR Certified Recycler Contracts
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  29.06.2023 / Mony Nou / Create the method
    @                  26.11.2025 / Mony Nou / US-0033676 - Extend Certified Recycler Contract Flow to Italy with Italian Email Templates prt 1 
    *********************************************************************************************************************************/
    public static void sendCertifiedRecyclerEmail(List<Contract> newContracts, Map<Id,Contract> oldContracts){

        Set<Id> contrToSendEmail = new Set<Id>();

        for(Contract contr : newContracts){

            if(contr.RecordTypeId == RT_CERTIFIED_RECYCLER_ID
               && MAP_COUNTRY_STATUS_CERTIFIEDRECYCLER_EMAILTEMPLATE.containsKey(contr.EBH_Site__c + '_' + contr.Status)
               && contr.Status != oldContracts.get(contr.Id).Status)
            {
                contrToSendEmail.add(contr.Id);
            }

        }

        if(!contrToSendEmail.isEmpty()) {
            try {

                String query = 'Select Id,Subject,Body, HtmlValue, DeveloperName from EmailTemplate Where DeveloperName IN: MAP_COUNTRY_STATUS_CERTIFIEDRECYCLER_EMAILTEMPLATE';
                List<EmailTemplate> emailTemplates = (List<EmailTemplate>)ApexSafe.query().secCheck(false).doQuery(query,new Map<String, Object> {'MAP_COUNTRY_STATUS_CERTIFIEDRECYCLER_EMAILTEMPLATE' => MAP_COUNTRY_STATUS_CERTIFIEDRECYCLER_EMAILTEMPLATE.values()});
            
                Map<String, EmailTemplate> mapApiNameToEmailTemplate = new Map<String, EmailTemplate>();
                for(EmailTemplate emt : emailTemplates){
                    mapApiNameToEmailTemplate.put(emt.DeveloperName, emt);
                }

                List<Messaging.SingleEmailMessage> listMailToSend = new List<Messaging.SingleEmailMessage>();
                List<Task> listTask = new List<Task>();

                query = 'Select Id, Status, EBH_Site__c, EBH_Country__c, TCs_URL__c, Unique_Id__c, StartDate, EndDate, Account.Name, Owner.Email, Business_Contact__r.Email, BusinessContactAddress__c, BusinessContactStreet__c, BusinessContactPostalCode__c, BusinessContactCity__c, Contract_Send_Date__c, Business_Contact__r.EBH_MailingAddress__c, Business_Contact__r.EBH_MailingStreet__c, Business_Contact__r.EBH_MailingPostalCode__c, Business_Contact__r.EBH_MailingCity__c'
                                + ' From Contract Where Id IN: contrToSendEmail';
                List<Contract> contractList = (List<Contract>)ApexSafe.query().secCheck(false).doQuery(query,new Map<String, Object> {'contrToSendEmail' => contrToSendEmail});
                
                for (Contract contr : contractList) {
                    
                    String key = contr.EBH_Site__c + '_' + contr.Status;
                    
                    if (!MAP_COUNTRY_CERTIFIEDRECYCLER_OWD.containsKey(contr.EBH_Site__c) || !MAP_COUNTRY_STATUS_CERTIFIEDRECYCLER_EMAILTEMPLATE.containsKey(key) || !mapApiNameToEmailTemplate.containsKey(MAP_COUNTRY_STATUS_CERTIFIEDRECYCLER_EMAILTEMPLATE.get(key))) { continue; }

                    EmailTemplate emt = mapApiNameToEmailTemplate.get(MAP_COUNTRY_STATUS_CERTIFIEDRECYCLER_EMAILTEMPLATE.get(key));
                    
                    String subject = emt.Subject;
                    String htmlBody = emt.HtmlValue;
                    String plainTxtBody = emt.Body;

                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                    String owdEmail = MAP_COUNTRY_CERTIFIEDRECYCLER_OWD.get(contr.EBH_Site__c);
                    OrgWideEmailAddress orgWide = ApexUtil.getOWDbyAddress(owdEmail);

                    String reURL = MAP_COUNTRY_RETURNURL.containsKey(contr.EBH_Site__c) ? MAP_COUNTRY_RETURNURL.get(contr.EBH_Site__c) : ''; //MN-26112025-US-0033676
                    
                    String ccAddress = (contr.EBH_Site__c != IT_COUNTRY)?owdEmail:'';
                    String siteUrl = System.Label.SiteURL + '?restype=contract&id=' + contr.Unique_Id__c + '&reURL=' + reURL;

                    htmlBody = htmlBody.replace(EMT_SITEURL_FOR_CERTIFIEDRECYCLER, siteUrl);
                    plainTxtBody = plainTxtBody.replace(EMT_SITEURL_FOR_CERTIFIEDRECYCLER, siteUrl);

                    htmlBody = mergeBodyContractSend(htmlBody, contr, null);
                    plainTxtBody = mergeBodyContractSend(plainTxtBody, contr, null);

                    mail.setSubject(subject);
                    mail.setHtmlBody(htmlBody);
                    mail.setToAddresses(new String[]{contr.Business_Contact__r.Email}); 
                    
                    if (String.isNotBlank(ccAddress)) { mail.setCcAddresses(new String[]{ccAddress}); } //MN-26112025-US-0033676

                    if (orgWide != null) { mail.setOrgWideEmailAddressId(orgWide.Id); }
                
                    listMailToSend.add(mail);

                    String description = 'To: ' + contr.Business_Contact__r.Email + '\n' +
                    'CC: '+ccAddress+'\n'+
                    'Subject: '+subject+'\n'+
                    'Body: \n'+plainTxtBody;
                    Task t = createTask(subject,contr,description); 
                    listTask.add(t);

                }

                if(!listMailToSend.isEmpty()){
                    if(!Test.isRunningTest()) { ApexUtil.sendEmail(listMailToSend); }
                    ApexSafe.dml().secCheck(false).doInsert(listTask,false);
                }
            } catch (Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, 'EBH_ContractTriggerHandler','sendCertifiedRecyclerEmail'); }
        }
    }

    /*********************************************************************************************************************************
    @ Method:         sendRefurbEmail
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Event:		  after update
    @ Purpose:        US-0010204 - [Refurb] Email Notification when Contract Status is set to "Program Cancelled"
    @                 US-0010205 - [Refurb] Email Notification when Contract Status is set  to "eBay Declined"
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.09.2021 / Sophal Noch / US-0010204, 0010205 create the method
					31.10.2021 / Sambath Seng / US-0010606, Add more condition to check status
                    15.11.2021 / Sophal Noch / US-0010851, use EBH_Site__c instead of EBH_Country__c
                    04.02.2022 / Sophal Noch / US-0011141, send email for EBH_Site__c = 'IT' and Status = 'eBay Declined'
                    08.08.2022 / Sambath Seng / US-0011127 - IT Email Notification for Contract Status= "Program Cancelled"
                    25.08.2022 / Sambath Seng / US-0011288 - FR Email Notification for Contract Status = "eBay Declined"
                    29.08.2022 / CHETRA SAROM / US-0011289 - FR Email Notification for Contract Status= "Program Cancelled"
    *********************************************************************************************************************************/
    public static void sendRefurbEmail(List<Contract> newContracts, Map<Id,Contract> oldContracts){

        Set<Id> contrToSendEmail = new Set<Id>();

        for(Contract contr : newContracts){

            // Sophal / 07.09.2021 / US-0010204, 0010205 : only status in ('Program Cancelled', 'eBay Declined') and Contract.EBH_Country__c == 'DE'. 
            if(contr.RecordTypeId == RT_REFURB_ID
               //&& MAP_COUNTRY_STATUS_TO_EMAILTEMPLATE.containsKey(contr.EBH_Country__c + '_' + contr.Status)
               && MAP_COUNTRY_STATUS_TO_EMAILTEMPLATE.containsKey(contr.EBH_Site__c + '_' + contr.Status) // Sophal Noch / 15.11.2021 / US-0010851 : get Template name by EBH_Site__c
               && contr.Status != oldContracts.get(contr.Id).Status)
            {
                contrToSendEmail.add(contr.Id);
            }

        }

        if(!contrToSendEmail.isEmpty()){

            Map<String, EmailTemplate> mapApiNameToEmailTemplate = new Map<String, EmailTemplate>();
            for(EmailTemplate emt : [Select Id,Subject,Body, HtmlValue, DeveloperName from EmailTemplate Where DeveloperName IN: MAP_COUNTRY_STATUS_TO_EMAILTEMPLATE.values()]){
                mapApiNameToEmailTemplate.put(emt.DeveloperName, emt);
            }

            List<Messaging.SingleEmailMessage> listMailToSend = new List<Messaging.SingleEmailMessage>();
            List<Task> listTask = new List<Task>();

            for(Contract contr : [Select Id, Status, EBH_Site__c, EBH_Country__c, TCs_URL__c, StartDate, EndDate, Account.Name, Owner.Email, 
                                Business_Contact__r.Email, BusinessContactAddress__c, BusinessContactStreet__c, BusinessContactPostalCode__c, BusinessContactCity__c, Contract_Send_Date__c,
                                Business_Contact__r.EBH_MailingAddress__c, Business_Contact__r.EBH_MailingStreet__c, Business_Contact__r.EBH_MailingPostalCode__c, Business_Contact__r.EBH_MailingCity__c,
                                (Select Id, EBH_BusinessName__r.Name From EBH_ContractsForSeller__r Order By Id ASC Limit 1)
                                From Contract Where Id IN: contrToSendEmail]){
                
                // Sophal / 07.09.2021 / US-0010204, 0010205 : MAP_COUNTRY_STATUS_TO_EMAILTEMPLATE return the EmailTemplate DeveloperName text and then use it to find EmailTemplate in mapApiNameToEmailTemplate.
                // EmailTemplate emt = mapApiNameToEmailTemplate.get(MAP_COUNTRY_STATUS_TO_EMAILTEMPLATE.get(contr.EBH_Country__c + '_' + contr.Status));
                EmailTemplate emt = mapApiNameToEmailTemplate.get(MAP_COUNTRY_STATUS_TO_EMAILTEMPLATE.get(contr.EBH_Site__c + '_' + contr.Status)); // Sophal Noch / 15.11.2021 / US-0010851 : get Template record by EBH_Site__c

                if(emt != null){

                    String subject = emt.Subject;
                    String htmlBody = emt.HtmlValue;
                    String plainTxtBody = emt.Body;

                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                    // Sophal / 07.09.2021 / US-0010204, 0010205 : need only the first contract seller of contract
                    String firstCsellerBusiName = (contr.EBH_ContractsForSeller__r.isEmpty() ? '' : contr.EBH_ContractsForSeller__r[0].EBH_BusinessName__r.Name);
                    
                    String ccAddress = contr.Owner.Email;// Sambath Seng 02.09.2022 US-0011288
                    
                    subject = subject.replace(EMT_CS_BUSINESS_NAME, firstCsellerBusiName);

                    // if(contr.EBH_Country__c == DE_COUNTRY && contr.Status == PRO_CANCELLED_STATUS){
                    if(contr.EBH_Site__c == DE_COUNTRY && contr.Status == PRO_CANCELLED_STATUS){ // Sophal Noch / 15.11.2021 / US-0010851

                        // Sophal / 07.09.2021 / US-0010204 : status = 'Program Cancelled'

                        // subject = subject.replace(EMT_CS_BUSINESS_NAME, firstCsellerBusiName);
                        subject = subject.replace(EMT_ENDDATE, contr.EndDate == null ? '' : contr.EndDate.format());//SB 1.11.2021 Add Condition to check if EndDate is null
                        
                        htmlBody = mergeBodyDEProCancelled(htmlBody, contr, firstCsellerBusiName);
                        plainTxtBody = mergeBodyDEProCancelled(plainTxtBody, contr, firstCsellerBusiName);

                    // }else if(contr.EBH_Country__c == DE_COUNTRY && contr.Status == EBAY_DECLINED_STATUS){
                    }else if(contr.EBH_Site__c == DE_COUNTRY && contr.Status == EBAY_DECLINED_STATUS){ // Sophal Noch / 15.11.2021 / US-0010851

                        // Sophal / 07.09.2021 / US-0010205 : status = 'eBay Declined'

                        // subject = subject.replace(EMT_CS_BUSINESS_NAME, firstCsellerBusiName);
                        subject = subject.replace(EMT_STARTDATE, contr.StartDate.format());

                        htmlBody = htmlBody.replace(EMT_TCS_URL, contr.TCs_URL__c);
                        plainTxtBody = plainTxtBody.replace(EMT_TCS_URL, contr.TCs_URL__c);

                    }else if(contr.EBH_Site__c == IT_COUNTRY && contr.Status == EBAY_DECLINED_STATUS){ // Sophal:04/02/2022:US-0011141
                        subject = subject.replace(EMT_ENDDATE, contr.EndDate == null ? '' : contr.EndDate.format());
                        htmlBody = htmlBody.replace(EMT_TCS_URL, contr.TCs_URL__c);
                        plainTxtBody = plainTxtBody.replace(EMT_TCS_URL, contr.TCs_URL__c);
                    }
                    //Start - Sambath Seng 08.08.2022 US-0011127 - IT Email Notification for Contract Status= "Program Cancelled"
                    else if(contr.EBH_Site__c == IT_COUNTRY && contr.Status == PRO_CANCELLED_STATUS){
                        subject = mergeBodyContractSend(subject, contr, firstCsellerBusiName);
                        htmlBody = mergeBodyContractSend(htmlBody, contr, firstCsellerBusiName);
                        plainTxtBody = mergeBodyContractSend(plainTxtBody, contr, firstCsellerBusiName);
                    }
                    //End - Sambath Seng 08.08.2022 US-0011127 - IT Email Notification for Contract Status= "Program Cancelled"
                    
                    //Start - Chetra Sarom 29.08.2022 US-US-0011289 
                    else if(contr.EBH_Site__c == FR_COUNTRY && contr.Status == PRO_CANCELLED_STATUS){
                        ccAddress = Label.Refurb_FR_OWD_Email;
                        subject = mergeBodyContractSend(subject, contr, firstCsellerBusiName);
                        htmlBody = mergeBodyContractSend(htmlBody, contr, firstCsellerBusiName);
                        plainTxtBody = mergeBodyContractSend(plainTxtBody, contr, firstCsellerBusiName);
                    }
                    //End - Chetra Sarom 29.08.2022 US-0011289 
                    
                    //Start - Sambath Seng - 25.08.2022 - US-0011288 - FR Email Notification for Contract Status = "eBay Declined"
                    else if(contr.EBH_Site__c == FR_COUNTRY && contr.Status == EBAY_DECLINED_STATUS){
                        ccAddress = Label.Refurb_FR_OWD_Email;// Sambath Seng 02.09.2022 US-0011288
                        htmlBody = htmlBody.replace(EMT_TCS_URL, contr.TCs_URL__c);
                        plainTxtBody = plainTxtBody.replace(EMT_TCS_URL, contr.TCs_URL__c);
                    }
                    //End - Sambath Seng - 25.08.2022 - US-0011288 - FR Email Notification for Contract Status = "eBay Declined"

                    mail.setSubject(subject);
                    mail.setHtmlBody(htmlBody);
                    mail.setToAddresses(new String[]{contr.Business_Contact__r.Email}); 
                    //mail.setccAddresses(new String[]{contr.Owner.Email});
                    mail.setccAddresses(new String[]{ccAddress});// Sambath Seng 02.09.2022 US-0011288

                    // Sophal / 07.09.2021 / US-0010204, US-0010205: set OrgWideEmail depending on Country
                    // String owdEmail = MAP_COUNTRY_TO_OWD_EMAIL.get(contr.EBH_Country__c);
                    String owdEmail = MAP_COUNTRY_TO_OWD_EMAIL.get(contr.EBH_Site__c); // Sophal Noch / 15.11.2021 / US-0010851 get Org-Wide Email by EBH_Site__c
                    OrgWideEmailAddress orgWide = ApexUtil.getOWDbyAddress(owdEmail);
                    if(orgWide != null) mail.setOrgWideEmailAddressId(orgWide.Id);
                    listMailToSend.add(mail);

                    String description = 'To: ' + contr.Business_Contact__r.Email + '\n' +
                    //'CC: '+contr.Owner.Email+'\n'+
                    'CC: '+ccAddress+'\n'+// Sambath Seng 02.09.2022 US-0011288
                    'Subject: '+subject+'\n'+
                    'Body: \n'+plainTxtBody;
                    Task t = createTask(subject,contr,description); // Sophal / 07.09.2021 / US-0010204, US-0010205 create task with description = email content
                    listTask.add(t);

                }


            }

            if(!listMailToSend.isEmpty()){
                if(!Test.isRunningTest()) ApexUtil.sendEmail(listMailToSend);
                insert listTask;
            }
                
        }

    }

    private static Task createTask(String subject,Contract contr,String description){
    	Task t = new Task();
    	t.Subject = 'Email: '+subject;
    	t.WhatId = contr.Id;
        t.ActivityDate = System.today();
        t.Status = 'Completed';
        t.TaskSubtype = 'Email';
        t.IsVisibleInSelfService = false;
    	t.Description = description;
    	t.RecordTypeId = ApexUtil.getRecordTypeByName('Task','Standard_Task').Id;
    	t.Log_Task__c = true;
    	
    	return t;
    }


    private static String mergeBodyDEProCancelled(String body, Contract contr, String firstCsellerBusiName){

        body = body.replace(EMT_TCS_URL, contr.TCs_URL__c);
        body = body.replace(EMT_ENDDATE, contr.EndDate == null ? '' : contr.EndDate.format());//SB 1.11.2021 Add condition to check if it null
        body = body.replace(EMT_ACCOUNT_NAME, contr.Account.Name);
        body = body.replace(EMT_BC_MAILING_ADRESS, contr.Business_Contact__r.EBH_MailingAddress__c);
        body = body.replace(EMT_BC_MAILING_STREET, contr.Business_Contact__r.EBH_MailingStreet__c);
        body = body.replace(EMT_BC_MAILING_POSTAL_CODE, contr.Business_Contact__r.EBH_MailingPostalCode__c);
        body = body.replace(EMT_BC_MAILING_CITY, contr.Business_Contact__r.EBH_MailingCity__c);
        body = body.replace(EMT_CS_BUSINESS_NAME, firstCsellerBusiName);
        
        return body;
    }

    /*****************************************************************************************************************************
    @ Method:   createTaskContractSend
    @ Version:  1.0
    @ Author: 	Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:	US-0010606 - [Refurb]Click Contract Emails to be tracked as Activities in Activity Related List
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Contract> lstContract
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 29.10.2021 / Sambath Seng / Created the method
    @               : 06.11.2023 / Mony Nou / US-0014288 - New Pre-Loved Partner Contract type - AC7
    @                                           - Adjust the existing method so that it works for both Refurbish and Pre-Loved Partner record types
    *****************************************************************************************************************************/
    @InvocableMethod
    public static void createTaskContractSend(List<Contract> lstContract) {
        
        //Set<Id> contIds = new Set<Id>(); //MN-06112023-US-0014288
        Map<Id, String> mContEmailTemplate = new Map<Id, String>(); //MN-06112023-US-0014288

        for(Contract oCont : lstContract){

            String key = oCont.EBH_Site__c + '_' + oCont.Status;

            //MN-06112023-US-0014288 - Check if it is Pre-Loved Partner RecordType
            if (oCont.RecordTypeId == RT_PRELOVED_ID && MAP_COUNTRY_STATUS_PRELOVEDPARTNER_EMAILTEMPLATE.containsKey(key)) {
                mContEmailTemplate.put(oCont.Id, MAP_COUNTRY_STATUS_PRELOVEDPARTNER_EMAILTEMPLATE.get(key));
            } else if (MAP_COUNTRY_STATUS_TO_CSELLER_EMAILTEMPLATE.containsKey(key)) {
                mContEmailTemplate.put(oCont.Id, MAP_COUNTRY_STATUS_TO_CSELLER_EMAILTEMPLATE.get(key));
            }


            /* //MN-06112023-US-0014288
            if(MAP_COUNTRY_STATUS_TO_CSELLER_EMAILTEMPLATE.containsKey(oCont.EBH_Site__c + '_' + oCont.Status))
            {
                contIds.add(oCont.Id);
            }
            */
        }

        //if(!contIds.isEmpty()){  //MN-06112023-US-0014288
        if (!mContEmailTemplate.isEmpty()) { //MN-06112023-US-0014288

            Map<String, EmailTemplate> mapApiNameToEmailTemplate = new Map<String, EmailTemplate>();
            //for(EmailTemplate emt : [Select Id,Subject,Body, HtmlValue, DeveloperName from EmailTemplate Where DeveloperName IN: MAP_COUNTRY_STATUS_TO_CSELLER_EMAILTEMPLATE.values()]){ //MN-06112023-US-0014288
                for(EmailTemplate emt : [Select Id,Subject,Body, HtmlValue, DeveloperName from EmailTemplate Where DeveloperName IN:mContEmailTemplate.values()]){
                mapApiNameToEmailTemplate.put(emt.DeveloperName, emt);
            }
            List<Task> listTask = new List<Task>();
            //MN-06112023-US-0014288: Added RecordTypeId into below query
            for(Contract oCont : [Select Id, Status, EBH_Site__c, StartDate, EndDate, TCs_URL__c, Account.Name, Owner.Email, Contract_Send_Date__c, RecordTypeId,
                                Business_Contact__r.Email,BusinessContactAddress__c, BusinessContactStreet__c, BusinessContactPostalCode__c, BusinessContactCity__c,
                                (Select Id, EBH_BusinessName__r.Name From EBH_ContractsForSeller__r Order By Id ASC Limit 1)
                                From Contract Where Id IN: mContEmailTemplate.keySet()]){
                                //From Contract Where Id IN: contIds]){
                
                //EmailTemplate emt = mapApiNameToEmailTemplate.get(MAP_COUNTRY_STATUS_TO_CSELLER_EMAILTEMPLATE.get(oCont.EBH_Site__c + '_' + oCont.Status)); //MN-06112023-US-0014288
                EmailTemplate emt = mapApiNameToEmailTemplate.get(mContEmailTemplate.get(oCont.Id)); //MN-06112023-US-0014288
                
                if(emt != null){
                    String subject = emt.Subject;
                    String htmlBody = emt.Body;
                    //String csBusinessName = (oCont.EBH_ContractsForSeller__r.isEmpty() ? '' : oCont.EBH_ContractsForSeller__r[0].EBH_BusinessName__r.Name); //MN-06112023-US-0014288:
                    //MN-06112023-US-0014288:
                    String csBusinessName = (oCont.RecordTypeId == RT_PRELOVED_ID)?oCont.Account.Name:(oCont.EBH_ContractsForSeller__r.isEmpty() ? '' : oCont.EBH_ContractsForSeller__r[0].EBH_BusinessName__r.Name); //MN-06112023-US-0014288 

                    subject = mergeBodyContractSend(subject, oCont, csBusinessName);
                    htmlBody = mergeBodyContractSend(htmlBody, oCont, csBusinessName);
                    
                    String description = 'To: ' + oCont.Business_Contact__r.Email + '\n' + //
                    'CC: '+oCont.Owner.Email+'\n'+
                    'Subject: '+subject+'\n'+
                    'Body: \n'+htmlBody;
                    Task t = createTask(subject,oCont,description);
                    listTask.add(t);
                }
            }
            if(!listTask.isEmpty()){
                insert listTask;
            }   
        }
    }

    /*****************************************************************************************************************************
    @ Method:   resetContractStatus
    @ Version:  1.0
    @ Author: 	Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:	US-0011334 - "Reset to Draft" Capabilities for Contract owners and validations
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 22.03.2022 / Acmatac SEING / Created the method
    @               : 14.05.2025 / LoumAng SENG / US-0026079 - Controlled Manual Contract Status changes
    @               : 03.07.2025 / Sambath Seng / US-0032991 Allow Contract Manager to Change status from Pricing Config to Draft
    @               : 13.10.2025 / Sovantheany / US-0033588 - eBay Live: Feedback Enhancements 2  
    *****************************************************************************************************************************/
    public static void resetContractStatus(Map<Id,Contract> oldContract, Map<Id,Contract> newContract) {

        Boolean hasManagerPermission = FeatureManagement.checkPermission('Pricing_Manager') || FeatureManagement.checkPermission('Contract_Manager') || FeatureManagement.checkPermission('Can_Create_eBay_Live_Contracts'); //SB 02.07.2025-US-0032991//TH 15.10.2025-US-0033588:add eBay_Live_Contract_Manager

        // Exclude Admin
        if(Userinfo.getprofileId() == EBH_DealTriggerHandler.ADMIN_PROFILE_ID || Userinfo.getprofileId() == EBH_DealTriggerHandler.ADMIN_PRIVILEGE_PROFILE_ID){
            return;
        }
        Set<Id> contIds = new Set<Id>();
        List<Contract> lstContr = new List<Contract>();
        for(Contract oldContr : oldContract.values()) {
            Contract newContr = newContract.get(oldContr.Id);

            //US-0033588: add FVFDISCOUNT record type
            if(oldContr.Status != newContr.Status
                && ((newContr.RecordTypeId == CONTRACT_LISTING_AGREEMENT_RECORDTYPEID || newContr.RecordTypeId == CONTRACT_ACP_RECORDTYPEID || newContr.RecordTypeId == CONTRACT_FVFDISCOUNT_RECORDTYPEID)
                && newContr.Status == CONTRACT_STATUS_DRAFT)
            ){
                if(UserInfo.getUserId() == newContr.OwnerId && OLD_STATUSES_ALLOW.contains(oldContr.Status)){
                    // Reset all flags so records can resubmit for approval
                    newContr.EBH_FinancePostCheckDone__c = false;
                    newContr.EBH_FinanceApproved__c = false;
                    newContr.EBH_Approved__c = false;
                }

                //SB 03.07.2025-US-0032991
                if(hasManagerPermission && oldContr.Status == CONTRACT_STATUS_PRICING_CONFIGURATION && newContr.Status == CONTRACT_STATUS_DRAFT){
                    continue;
                }
                if(OLD_STATUSES_FILTER.contains(oldContr.Status)){
                    newContr.addError(Label.CONTRACT_SET_TO_DRAFT_ERROR_MSG);
                }
            }
        }
    }
    /*****************************************************************************************************************************
    @ Method:   mergeBodyContractSend
    @ Version:  1.0
    @ Author: 	Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:	US-0010606 - [Refurb]Click Contract Emails to be tracked as Activities in Activity Related List
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     String body, Contract contr, String csBusinessName
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 31.10.2021 / Sambath Seng / Created the method
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 03.02.2022 / Sophal Noch / US-0011123 - IT/FR Refurb Click Contracts Emails
                      08.08.2022 / Sambath Seng / US-0011127 - IT Email Notification for Contract Status= "Program Cancelled"
    @ Change history: 29.08.2022 / CHETRA SAROM / US-0011289 - FR Email Notification for Contract Status= "Program Cancelled"                  
    *****************************************************************************************************************************/
    private static String mergeBodyContractSend(String body, Contract contr, String csBusinessName){
        body = body.replace(EMT_CONTRACT_ACCOUNT, contr.Account.Name == null ? '' : contr.Account.Name);
        body = body.replace(EMT_BUSINESS_CONTACT_STREET, contr.BusinessContactStreet__c == null ? '' : contr.BusinessContactStreet__c);
        body = body.replace(EMT_BUSINESS_CONTACT_POSTAL_CODE, contr.BusinessContactPostalCode__c == null ? '' : contr.BusinessContactPostalCode__c);
        body = body.replace(EMT_BUSINESS_CONTACT_CITY, contr.BusinessContactCity__c == null ? '' : contr.BusinessContactCity__c);
        body = body.replace(EMT_BUSINESS_NAME, csBusinessName == null ? '' : csBusinessName);
        body = body.replace(EMT_START_DATE, contr.StartDate == null ? '' : contr.StartDate.format());
        body = body.replace(EMT_CONTRACT_SEND_DATE, contr.Contract_Send_Date__c == null ? '' : contr.Contract_Send_Date__c.format()); // Sophal:03/02/2022:US-0011123
        body = body.replace(EMT_ENDDATE, contr.EndDate == null ? '' : contr.EndDate.format()); // Sambath Seng 08.08.2022 US-0011127 - IT Email Notification for Contract Status= "Program Cancelled"
        body = body.replace(EMT_TCS_URL, contr.TCs_URL__c == null ? '' : contr.TCs_URL__c); // Sambath Seng 08.08.2022 US-0011127 - IT Email Notification for Contract Status= "Program Cancelled" //MN-06112023-US-0014288: Fixed error when this field is null
        body = body.replace(EMT_CONTRACT_BUSINESSCONTACTADDRESS, contr.BusinessContactAddress__c == null ? '' : contr.BusinessContactAddress__c); // CHETRA SAROM / US-0011289 - FR Email Notification for Contract Status= "Program Cancelled"
        
        return body;
    }

    /*****************************************************************************************************************************
    @ Method:   calculateThresholdFields
    @ Version:  1.0
    @ Author: 	Loumang Seng (loumang.seng@gaea-sys.com)
    @ Purpose:	US-0015042 - ACP Contract & Pricing thresholds with percentage and amount options (AC5)
	@ Event:	before insert , before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: List<Contract> newContr, Map<Id,Contract> oldMap
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 17.05.2024 / Loumang Seng / Method Creation
    @               : 01.07.2024 / Loumang Seng / US-0015323 - Calculate Amount if % threshold is populated on ACP
	*****************************************************************************************************************************/
    public static void calculateThresholdFields(List<Contract> newContr, Map<Id,Contract> oldMap){

        Boolean isNew = (oldMap==null || oldMap.isEmpty());
		for(Contract contr: newContr){

            //TargetType__c is amount then calculate Threshold percentage
			if(contr.RecordTypeId == CONTRACT_ACP_RECORDTYPEID && contr.TargetType__c == TARGETTYPE_AMOUNT && contr.EBH_GMVforContractPeriod__c != null && contr.AcceleratorTierThresholdAmount__c != null && contr.DeceleratorTierThresholdAmount__c != null && contr.MainTierThresholdAmount__c != null){
            
                Decimal acceleratorThreshold = (contr.EBH_GMVforContractPeriod__c== 0)? 0 : ((contr.AcceleratorTierThresholdAmount__c/contr.EBH_GMVforContractPeriod__c)*100).setScale(2);
                Decimal deceleratorThreshold = (contr.EBH_GMVforContractPeriod__c== 0)? 0 :((contr.DeceleratorTierThresholdAmount__c/contr.EBH_GMVforContractPeriod__c)*100).setScale(2);
                Decimal mainTierThreshold = (contr.EBH_GMVforContractPeriod__c== 0)? 0 : ((contr.MainTierThresholdAmount__c/contr.EBH_GMVforContractPeriod__c)*100).setScale(2);
                
                if(isNew){ // When new record is created

                    contr.EBH_AcceleratorThreshold__c = acceleratorThreshold;
                    contr.EBH_DeceleratorThreshold__c = deceleratorThreshold;
                    contr.EBH_MainTierThresholdofTarget__c = mainTierThreshold;

                }
                else if (!isNew){// When Record is updated 
                
                    if(contr.AcceleratorTierThresholdAmount__c != oldMap.get(contr.Id).AcceleratorTierThresholdAmount__c){// When updated AcceleratorTierThresholdAmount__c

                        contr.EBH_AcceleratorThreshold__c = acceleratorThreshold;
                    }
                    if(contr.DeceleratorTierThresholdAmount__c != oldMap.get(contr.Id).DeceleratorTierThresholdAmount__c){ // When updated DeceleratorTierThresholdAmount__c

                        contr.EBH_DeceleratorThreshold__c =  deceleratorThreshold;
                    }
                    if(contr.MainTierThresholdAmount__c != oldMap.get(contr.Id).MainTierThresholdAmount__c){ // When updated 
                    
                        contr.EBH_MainTierThresholdofTarget__c = mainTierThreshold;
                    }
                    if(contr.EBH_GMVforContractPeriod__c != oldMap.get(contr.Id).EBH_GMVforContractPeriod__c){// When EBH_GMVforContractPeriod__c is updated. EBH_GMVforContractPeriod__c field is a formular field to sum all EBH_GMVTarget__c pricing.
                                           
                        contr.EBH_AcceleratorThreshold__c = acceleratorThreshold;
                        contr.EBH_DeceleratorThreshold__c = deceleratorThreshold;
                        contr.EBH_MainTierThresholdofTarget__c = mainTierThreshold;    
                    }
                }                
                
			}
            
            //TargetType__c is Percentage then calculate Threshold amount
            else if(contr.RecordTypeId == CONTRACT_ACP_RECORDTYPEID && contr.TargetType__c == TARGETTYPE_PERCENTAGE && contr.EBH_GMVforContractPeriod__c != null && contr.EBH_AcceleratorThreshold__c != null && contr.EBH_DeceleratorThreshold__c != null && contr.EBH_MainTierThresholdofTarget__c != null){
                
                Decimal acceleratorThresholdAmount = (contr.EBH_AcceleratorThreshold__c*contr.EBH_GMVforContractPeriod__c)/100;
                Decimal deceleratorThresholdAmount = (contr.EBH_DeceleratorThreshold__c*contr.EBH_GMVforContractPeriod__c)/100;
                Decimal mainTierThresholdAmount = (contr.EBH_MainTierThresholdofTarget__c*contr.EBH_GMVforContractPeriod__c)/100;
                if(isNew){ // When new record is created

                    contr.AcceleratorTierThresholdAmount__c = acceleratorThresholdAmount;
                    contr.DeceleratorTierThresholdAmount__c = deceleratorThresholdAmount;
                    contr.MainTierThresholdAmount__c = mainTierThresholdAmount;

                }
                else if (!isNew){// When Record is updated

                    if(contr.EBH_AcceleratorThreshold__c != oldMap.get(contr.Id).EBH_AcceleratorThreshold__c){// When updated EBH_AcceleratorThreshold__c

                        contr.AcceleratorTierThresholdAmount__c = acceleratorThresholdAmount;
                    }
                    if(contr.EBH_DeceleratorThreshold__c != oldMap.get(contr.Id).EBH_DeceleratorThreshold__c){ // When updated EBH_DeceleratorThreshold__c

                        contr.DeceleratorTierThresholdAmount__c =  deceleratorThresholdAmount;
                    }
                    if(contr.EBH_MainTierThresholdofTarget__c != oldMap.get(contr.Id).EBH_MainTierThresholdofTarget__c){ // When updated 
                    
                        contr.MainTierThresholdAmount__c = mainTierThresholdAmount;
                    }
                    if(contr.EBH_GMVforContractPeriod__c != oldMap.get(contr.Id).EBH_GMVforContractPeriod__c){// When EBH_GMVforContractPeriod__c is updated. EBH_GMVforContractPeriod__c field is a formular field to sum all EBH_GMVTarget__c pricing.
                                           
                        contr.AcceleratorTierThresholdAmount__c = acceleratorThresholdAmount;
                        contr.DeceleratorTierThresholdAmount__c = deceleratorThresholdAmount;
                        contr.MainTierThresholdAmount__c = mainTierThresholdAmount;    
                    }

                }
            }
		}
	}

    /*****************************************************************************************************************************
    @ Method:   validateLockedFields
    @ Author: 	Sambath Seng
    @ Purpose:	US-0016114 - Pricing Configuration Record Lock - CPM, Contract other
	@ Event:	before update
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 09.01.2025 / Sambath Seng / Method Creation
	*****************************************************************************************************************************/
    public static void validateLockedFields(Map<Id, Contract> oldMap, Map<Id, Contract> newMap) {

        // Check if user has custom permission to bypass locked fields
        If(FeatureManagement.checkPermission('BypassLockedPricingConfiguration')) return;
        
        List<Schema.FieldSetMember> lockedFieldSet = SObjectType.Contract.FieldSets.PricingConfigurationFieldsLocked.getFields();
        Set<String> lockedFieldNames = new Set<String>();
        for (Schema.FieldSetMember field : lockedFieldSet) {
            lockedFieldNames.add(field.getFieldPath());
        }

        // Check for locked fields
        Set<Id> contrIdsToError = checkForContractLockedFields(oldMap, newMap, lockedFieldNames);

        // Add errors to the records
        for (Id contrId : contrIdsToError) {
            Contract newContr = newMap.get(contrId);
            newContr.addError(System.Label.PricingConfigurationLockedFieldsMessage);
        }
    }

    /*****************************************************************************************************************************
    @ Method:   checkForContractLockedFields
    @ Author: 	Sambath Seng
    @ Purpose:	US-0016114 - Pricing Configuration Record Lock - CPM, Contract other
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 21.01.2025 / Sambath Seng / Method Creation
    @               : 14.05.2025 / Loumang Seng / US-0026079 - Controlled Manual Contract Status changes
    @               : 02.07.2025 / Sambath Seng / US-0032991 Allow Contract Manager to Change status from Pricing Config to Draft
	*****************************************************************************************************************************/
    private static Set<Id> checkForContractLockedFields(Map<Id, Contract> oldMap, Map<Id, Contract> newMap, Set<String> lockedFieldNames) {
        Boolean hasManagerPermission = FeatureManagement.checkPermission('Pricing_Manager') || FeatureManagement.checkPermission('Contract_Manager'); //SB 02.07.2025-US-0032991
        Set<String> contractBypassStatus = new Set<String>{
            CONTRACT_STATUS_DRAFT, //LA-13-05-2025-US-0026079 //SB 02.07.2025-US-0032991 uncomment draft status
            CONTRACT_STATUS_VOIDED,
            CONTRACT_STATUS_READY_FOR_SIGNATURE
        };
        Set<Id> contrIdsToError = new Set<Id>();
        for (Id contrId : newMap.keySet()) {
            Contract newContr = newMap.get(contrId);
            Contract oldContr = oldMap.get(contrId);

            if(hasManagerPermission && oldContr.Status == CONTRACT_STATUS_PRICING_CONFIGURATION && contractBypassStatus.contains(newContr.Status)) {
                return contrIdsToError;
            }

            if (oldContr != null && newContr != null && oldContr.Status == CONTRACT_STATUS_PRICING_CONFIGURATION && CONTRACT_RECORDTYPEID_FOR_PRICING_CONFIGURATION.contains(oldContr.RecordTypeId)
            ) {
                for (String fieldName : lockedFieldNames) {
                    Object oldValue = oldContr.get(fieldName);
                    Object newValue = newContr.get(fieldName);

                    if (oldValue != newValue) {
                        contrIdsToError.add(contrId);
                        break; // Exit the loop as soon as a locked field is detected
                    }
                }
            }
        }
        return contrIdsToError;
    }

    /*****************************************************************************************************************************
    @ Method:         populateTimezoneOffsets
    @ Version:        1.0
    @ Author:         GitHub Copilot
    @ Purpose:        US-0033985: Populate Start Date Offset and End Date Offset fields based on EBH_Site__c using timezone names to handle DST
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2025 / GitHub Copilot / Method Creation - Updated to use timezone names and handle DST
    *****************************************************************************************************************************/
    public static void populateTimezoneOffsets(List<Contract> newContracts, Map<Id, Contract> oldMap) {
        for (Contract contract : newContracts) {
            Contract oldContract = oldMap?.get(contract.Id);
            
            // Check and populate Start Date Offset
            if (contract.StartDate != null && 
                (oldContract == null || 
                 contract.EBH_Site__c != oldContract.EBH_Site__c ||
                 contract.StartDate != oldContract.StartDate ||
                 contract.StartDateOffset__c == null)) {
                contract.StartDateOffset__c = ApexUtil.getDateTimezoneOffsetForSite(contract.StartDate, contract.EBH_Site__c);
            }
            
            // Check and populate End Date Offset
            if (contract.EndDate != null && 
                (oldContract == null || 
                 contract.EBH_Site__c != oldContract.EBH_Site__c ||
                 contract.EndDate != oldContract.EndDate ||
                 contract.EndDateOffset__c == null)) {
                contract.EndDateOffset__c = ApexUtil.getDateTimezoneOffsetForSite(contract.EndDate, contract.EBH_Site__c);
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:         updateChildTimezoneOffsets
    @ Version:        1.0
    @ Author:         GitHub Copilot
    @ Purpose:        US-0033985: Update child Pricing and FeeType timezone offset fields when Contract StartDate or EndDate changes
                      This is needed because child offset calculations are based on Contract dates
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2025 / GitHub Copilot / Method Creation - Update child records when Contract dates change
    *****************************************************************************************************************************/
    public static void updateChildTimezoneOffsets(List<Contract> newContracts, Map<Id, Contract> oldMap) {
        Set<Id> contractIdsToUpdate = new Set<Id>();
        
        // Identify contracts where StartDate or EndDate changed
        for (Contract contract : newContracts) {
            Contract oldContract = oldMap?.get(contract.Id);
            
                     system.debug('AAA ' + contract?.StartDate + ' ' + oldContract?.StartDate);
            if (oldContract != null && 
                (contract.StartDate != oldContract.StartDate || 
                 contract.EndDate != oldContract.EndDate)) {
                contractIdsToUpdate.add(contract.Id);
            }
        }
        
        if (!contractIdsToUpdate.isEmpty()) {
            // Query child Pricing records
            String pricingQuery = 'SELECT Id, EBH_Site__c, EBH_ContractId__c FROM EBH_Pricing__c WHERE EBH_ContractId__c IN :contractIdsToUpdate AND EBH_Site__c != null';
            List<EBH_Pricing__c> pricingsToUpdate = ApexSafe.query().secCheck(false).doQuery(pricingQuery, new Map<String, Object> {'contractIdsToUpdate' => contractIdsToUpdate});
            
            // Query child FeeType records
            String feeTypeQuery = 'SELECT Id, PrimarySite__c, RelatedContract__c FROM FeeType__c WHERE RelatedContract__c IN :contractIdsToUpdate AND PrimarySite__c != null';
            List<FeeType__c> feeTypesToUpdate = ApexSafe.query().secCheck(false).doQuery(feeTypeQuery, new Map<String, Object> {'contractIdsToUpdate' => contractIdsToUpdate});
            
            // Create maps for new contract data
            Map<Id, Contract> contractMap = new Map<Id, Contract>(newContracts);
            
            // Update Pricing offset fields
            for (EBH_Pricing__c pricing : pricingsToUpdate) {
                Contract relatedContract = contractMap.get(pricing.EBH_ContractId__c);
                if (relatedContract != null) {
                    if (relatedContract.StartDate != null) {
                        pricing.StartDateOffset__c = ApexUtil.getDateTimezoneOffsetForSite(relatedContract.StartDate, pricing.EBH_Site__c);
                    }
                    if (relatedContract.EndDate != null) {
                        pricing.EndDateOffset__c = ApexUtil.getDateTimezoneOffsetForSite(relatedContract.EndDate, pricing.EBH_Site__c);
                    }
                }
            }
            
            // Update FeeType offset fields
            for (FeeType__c feeType : feeTypesToUpdate) {
                Contract relatedContract = contractMap.get(feeType.RelatedContract__c);
                if (relatedContract != null) {
                    if (relatedContract.StartDate != null) {
                        feeType.StartDateOffset__c = ApexUtil.getDateTimezoneOffsetForSite(relatedContract.StartDate, feeType.PrimarySite__c);
                    }
                    if (relatedContract.EndDate != null) {
                        feeType.EndDateOffset__c = ApexUtil.getDateTimezoneOffsetForSite(relatedContract.EndDate, feeType.PrimarySite__c);
                    }
                }
            }
            
            // Update the child records
            List<SObject> recordsToUpdate = new List<SObject>();
            recordsToUpdate.addAll(pricingsToUpdate);
            recordsToUpdate.addAll(feeTypesToUpdate);
            
            if (!recordsToUpdate.isEmpty()) {
                ApexSafe.dml().secCheck(false).doUpdate(recordsToUpdate,false); // Use allOrNone=false to avoid blocking Contract update if child update fails
            }
        }
    }

}