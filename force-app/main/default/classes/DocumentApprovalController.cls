/**
Update the page https://.../deals/DocumentApproval?id=a2f4aac0-3b6d-4779-9d3c-3cf46b24e2fd

Dynamically take id parameter which will be encryption of the Deal Contract Agreement ID.

Take the tables and make into dynamic repeat of all Deals related to the Deal Contract Agreement ID in the id parameter. Align center as opposed to left currently.

Convert all text to be in custom labels

User must select Approve/Decline on each Deal. If they select Decline they must provide reason populate Comment from Seller. 
Approve = Deal Status Planned 
Declined = Deal Status Rejected

User must also provide name and email address

Once user clicks sign and all information required above is populated then update all relevant deals


*/
/*************************************************************************************************************************************
    @ Class:          DocumentApprovalController
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        US-0008130 - [US]* Deals External Seller Bulk/Mass Approval Functionality             
    --------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.10.2020 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / moved from join instance
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.11.2020 / Sophal Noch / US-0008605 Update the class.
                        08.02.2021 / Acmatac SEING / US-0008816 - [NA] Deal Term Agreements - Display EST for Canada Site Deals
                        25.02.2021 / Mony NOU / US-0009152 - [NA] Include Full Deals Agreement in Contract PDF sent to Seller
                        26.02.2021 / Mony NOU / US-0009153 - [NA] Attach copy of accepted Deals Agreement to 'Deal Contract Agreement'
                        02.04.2021 / Mony NOU / US-0009333 - [NA] Update Contracts content for Seller Approval Microsite Page
                        06.04.2021 / Mony NOU / US-0009320 - [NA] Make changes to Seller Deal Approval Microsite
                        13.05.2021 / Mony NOU / US-0009532 - BUG: Email notification to Seller 'from' needs to be changed
                        12.01.2021 / Sovantheany Dim/ US-0010648 - [BUG][NA DEALS] Canada Contracts on microsite and PDF Attachment showing incorrect EST times
                        14.03.2023 / Loumang SENG / US-0013384 - Change the AU FROM email address from NA Contract email
                        08.01.2024/ vadhanak voun/ US-0014643 - Hyperforce - Remove hard-coded instance references
                        08.01.2024 / SRONG TIN / US-0014252 - NA Region (US): New field on Deal record & Contract agreement to determine subsidy type
**************************************************************************************************************************************/
public without sharing  virtual class DocumentApprovalController {

  public boolean rendered       {get; private set;}
  public String  emailAddress   {get; set;}
  public static String  signerName     {get; set;}
  public String  ipAddress      {get; private set;}
  public string recordId {get;set;}
  public String dcaidencrypted {get;set;}
  public String approverToken {get;set;} //US-0008605 token identify the approver
  private Set<Id> setDealIdInWrapper;
  
  public List<EBH_Deal__c> deals {get;set;}
  public Deal_Contract_Agreement__c dca {get;set;}
  public List<DealWrapper> dealsWrapper {get;set;}
  public String dealsJSON {get;set;}
  public Boolean agreementsigned {get{return agreementsigned = (agreementsigned !=null ? agreementsigned : false);} set;}  
  public Boolean incorrecturl {get;set;}
  public Boolean alreadyreplied {get;set;}
  public Boolean latereply {get;set;}
  
  
  public String replicate_status{get;set;}
  public String replicate_reason{get;set;}
  public Boolean hasApprovalOrRejected{get;set;}
    
  public Boolean documentApprovalCheck{get;set;}

  public Boolean hasBeenApprovedOrDeclined{get;set;}

  private Boolean hasBeenCheckedBeforeSave = false;

  public Boolean canContinueSaving{get{return canContinueSaving = (canContinueSaving !=null ? canContinueSaving : false);} set;}  

  private Integer dwChunkIndex = 0;


  private Integer dwChunkSizeLimit = 25;

  private Integer dwSize = 0;

  public String lsterrorMessage{get;set;}
  // statefull 
   public String ids {get;set;}
   public String dealcontract {get;set;}
   public String dealcontractname {get;set;}
   public String sellerName {get;set;}
   public String sellerId {get;set;}
   

   private static final String STATUS_SENT_TO_SEELLER ='Sent to Seller';
   private static final String STATUS_EXPIRED ='Expired'; // 28.05.2021 / Sophal Noch / US-0009533
   
   public List<String> emailsapprovers {get;set;}

   private Map<String,String> mDealAgreementPage = new Map<String, String>{ //KEY:Account.PrimarySite#Account.NAContractType => Value:VFComponent //MN-01032021-US-0009152 -US-0009153
        'Ebay#Standard'             => 'Deal_Agreement_US_Standard',
        'Canada#Standard'           => 'Deal_Agreement_CA_Standard',
        'Canada (French)#Standard'  => 'Deal_Agreement_CA_Standard'
        // 'Canada#CA-Quebec'          => DealAgreementPDFController.VFCMP_Deal_Agreement_CA_Quebec, //MN-02042021 - US-0009333 - No longer use this one
        // 'Canada (French)#CA-Quebec' => DealAgreementPDFController.VFCMP_Deal_Agreement_CA_Quebec //MN-02042021 - US-0009333 - No longer use this one
    };
    
    public Boolean isPDF {get;set;}
    private String mapkey = '#'; //MN-01032021-US-0009152 -US-0009153
    public String vfcmp_val {get;set;} //MN-01032021-US-0009152 -US-0009153
    private static String vfcmp_param = '?vfcmp='; //MN-01032021-US-0009152 -US-0009153
    private static String urlparam = '';
    
    // US-0009150 - 2/March/21 Acmatac SEING
    public Boolean isCheckedAgree {get;set;}
    public String sellerAgreementAddendum {get;set;}
    public String sellerFullAddress {get;set;}
    public DocumentApprovalController documentApprovalCont {get {return this;}}
    // END of US-0009150

    // US-0009333 - 02/April/2021 Mony Nou
    public Account seller {get;set;}
    // End of US-0009333

    // US-0010019 - 08/Sep/2021 Mony Nou
    private static final string NA_DEAL_RECORDTYPE = 'Deal_V2';
    // End of US-0010019 

    private final static Set<String> SET_APPROVAL_STATUS = new Set<String>{'Seller Approved', 'Seller Rejected', 'Running', 'Completed'};
    private final static String RELATED_OBJ_ACC = 'EBH_BusinessName__r';
    private final static String PERM_SET_NA_MANAGED_DEAL = 'US_Manage_Deals';

    public DocumentApprovalController() {
        ipAddress = getIPAddress(); 
        ipAddress = String.isBlank(ipAddress) ? null : String.escapeSingleQuotes(ipAddress); // EscapeSingleQuotes, Acmatac SEING March/05/2021, Prevent SQL Injection
        dealsWrapper = new List<DealWrapper>();

        // use https://.../a051F0000003lw9
        rendered = true;
        agreementsigned = false;
        hasApprovalOrRejected = false;
        documentApprovalCheck = false;

        vfcmp_val = '';

        isPDF = false;

        seller = new Account();
        lsterrorMessage = '';
    }

    /***************************************************************************************************************************************
	@ Constructor:   DocumentApprovalController
	@ Version:       1.0
	@ Author:        Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:       US-0010859 - Enable user with 'NA Manage Deals' permission set to resend the Deal pdf file
	-----------------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 03.03.2022 / Sophal Noch / Created the method.
	-----------------------------------------------------------------------------------------------------------------------------------------*/	 
    public DocumentApprovalController(EBH_Deal__c deal, Integer numOfDeals){
        
        // new constructor for resend PDF purpose

        String key = deal.EBH_BusinessName__r.EBH_PrimarySite__c + mapkey + deal.EBH_BusinessName__r.NA_Contract_Type__c;
        if(mDealAgreementPage.containsKey(key)) vfcmp_val = mDealAgreementPage.get(key);
        if (String.isNotBlank(vfcmp_val)) urlparam = vfcmp_param + vfcmp_val;
        
        seller = (Account)deal.getSobject(RELATED_OBJ_ACC);
        if (seller != null && seller.Id != null) accountId = seller.Id;

        no_of_deals = numOfDeals;
        hasApprovalOrRejected = true;
    }

    /**
    Dynamically take id parameter which will be encryption of the Deal Contract Agreement ID.
    **/
  public PageReference checkDCAID() {
   
    rendered = true;
    agreementsigned = false;
    alreadyreplied = false;
    incorrecturl = false;
    dcaidencrypted = ApexPages.currentPage().getParameters().get('id'); 
    dcaidencrypted = String.isBlank(dcaidencrypted) ? null : String.escapeSingleQuotes(dcaidencrypted); // EscapeSingleQuotes, Acmatac SEING March/05/2021, Prevent SQL Injection

    approverToken = ApexPages.currentPage().getParameters().get('approver'); 
    approverToken = String.isBlank(approverToken) ? null : String.escapeSingleQuotes(approverToken); // EscapeSingleQuotes, Acmatac SEING March/05/2021, Prevent SQL Injection
    setDealIdInWrapper = new Set<Id>();
    try {
        
            //dcaidencrypted = EncodingUtil.urlDecode(dcaidencrypted, 'UTF-8');

            // 28.05.2021 / Sophal Noch / US-0009533
            Deal_Timezone__c dealTimezone = Deal_Timezone__c.getInstance();
            Timezone tz = Timezone.getTimeZone(dealTimezone.TimeZone__c);
            Datetime currentDateTime =  DateTime.newInstance(System.Now().getTime() + tz.getOffset(System.Now()));
            // SRONG/08.01.2024/US-0014252
            deals  = [Select d.EBH_Quantity__c,d.EBH_MaximumPurchases__c,d.EBH_RRPWASPrice__c, d.EBH_eBayLink__c, d.EBH_BusinessName__c, d.EBH_CommentfromeBaySourcer__c,
                                                d.EBH_BusinessName__r.EBH_PrimarySite__c, d.EBH_BusinessName__r.NA_Contract_Type__c, //MN-01032021-US-0009152-US-0009153
                                                d.EBH_BusinessName__r.Id, d.EBH_BusinessName__r.Name, d.EBH_BusinessName__r.EBH_FullBillingAddress__c, //MN-06032021-US-0009320
                                                d.EBH_ProductTitle__c, 
                                                d.EBH_DealEndDate__c, d.EBH_DealStartDate__c,
                                                d.EBH_DealEndTime__c, EBH_DealStartTime__c,
                                                d.eBay_Seller_Name__c, d.EBH_eBayItemID__c, d.EBH_Vertical__c, 
                                                d.EBH_DealCalendarDescription__c, d.EBH_CommentfromSeller__c, 
                                                d.EBH_Status__c,
                                                d.EBH_Category__c, 
                                                d.Deal_Contract_Agreement__c,
                                                d.Deal_Contract_Agreement__r.CreatedById,
                                                d.Quantity_Limitation_per_Purchaser__c,
                                                d.EBH_DealFormat__c,
                                                d.EBH_DealPrice__c,d.List_Price__c,
                                                d.EBH_SellerPrice__c,
                                                d.Seller_Approver_1_Email__c,
                                                d.Seller_Approver_2_Email__c,
                                                d.Seller_Approver_3_Email__c,
                                                d.Seller_Approver_4_Email__c,
                                                d.Seller_Approver_5_Email__c,
                                                d.EBH_Subsidy__c,
                                                d.Deal_Contract_Agreement__r.Current_Digest__c,
                                                d.Deal_Contract_Agreement__r.Name,
                                                d.Name,
                                                d.Optional_Notes__c,
                                                d.EBH_BusinessName__r.Agreement_Addendum__c,
                                                d.EBH_SubsidyP__c,
                                                d.Subsidy_Type__c
                                                From EBH_Deal__c d 
                                                where Deal_Contract_Agreement__r.Current_Digest__c=:dcaidencrypted];
        
            if (deals.isEmpty()) { throw new DocumentApprovalException('No agreement found'); }
            
              //If all the Deals have been cancelled because of missing the start time (i.e. cancellation reason = "seller missed approval window") then shown message "Contract not approved on time. Please contact your ebay representative."
            List<EBH_Deal__c> dealsall  = [Select id,
                                                EBH_DealStartDate__c, // 28.05.2021 / Sophal Noch / US-0009533
                                                EBH_DealStartTime__c // 28.05.2021 / Sophal Noch / US-0009533
                                                From EBH_Deal__c d 
                                                where Deal_Contract_Agreement__r.Current_Digest__c=:dcaidencrypted 
                                                ];
             
             /*List<EBH_Deal__c> dealsallcancelled  = [Select id
                                                From EBH_Deal__c d 
                                                where Deal_Contract_Agreement__r.Current_Digest__c=:dcaidencrypted and
                                                d.EBH_Status__c = 'Cancelled' and
                                                d.Cancellation_Reason__c='Seller missed approval window'
                                                ];*/

            // 04.06.2021 / Sophal Noch / US-0009649
            // Set<Id> startDateInPastDealIds = new Set<Id>(); // 28.05.2021 / Sophal Noch / US-0009533

            List<EBH_Deal__c> dealsallexpired  = [Select id
                                                From EBH_Deal__c d 
                                                where Deal_Contract_Agreement__r.Current_Digest__c=:dcaidencrypted and
                                                d.EBH_Status__c =: STATUS_EXPIRED
                                                ];
            
            /* 04.06.2021 / Sophal Noch / US-0009649 disable because of this.

                for(EBH_Deal__c deal : dealsallexpired){ // 28.05.2021 / Sophal Noch / US-0009533
                    startDateInPastDealIds.add(deal.Id);
                }
            

                for(EBH_Deal__c deal : dealsall){ // 28.05.2021 / Sophal Noch / US-0009533
                    if(!startDateInPastDealIds.contains(deal.Id) && DD_SendToSellerHelper.checkExpiredDeal(deal,currentDateTime)){
                        startDateInPastDealIds.add(deal.Id);
                    }
                }
            */

            List<EBH_Deal__c> dealsinternalapproved  = [Select id
                                                From EBH_Deal__c d 
                                                where Deal_Contract_Agreement__r.Current_Digest__c=:dcaidencrypted and
                                                d.EBH_Status__c = 'Internal Approval'
                                                ];

             if (dealsall.size()==dealsallexpired.size() 
                // || dealsall.size() == startDateInPastDealIds.size() // 28.05.2021 / Sophal Noch / US-0009533
             ) {
                rendered = false;
                latereply = true;
                return null;
             }

             if (dealsall.size()==dealsinternalapproved.size()) {
                rendered = false;
                incorrecturl = true;
                return null;
             }
                        
            
            // check now with the record if the digest match with the record id
            EBH_Deal__c dd =  deals.get(0);
            /*Theany String pkey = dd.Deal_Contract_Agreement__r.CreatedById;
            String recId = DD_Utils.doDecrypt(dcaidencrypted,pkey.substring(0,16));
            
            if (recId!=dd.Deal_Contract_Agreement__c) {                 
                // throw exception 
                throw new DocumentApprovalException('digest does not match');
                
            }*/

            //** MN-01032021-US-0009152-US-0009153 */ Check Customer.PrimarySite & Customer.NAContractType to get the correct Deal Agreement (VF Components)
            String key = dd.EBH_BusinessName__r.EBH_PrimarySite__c + mapkey + dd.EBH_BusinessName__r.NA_Contract_Type__c;
            // System.debug('#### key :: ' + key);
            if (mDealAgreementPage.containsKey(key)) { vfcmp_val = mDealAgreementPage.get(key); }
            else{
                isCheckedAgree = true; //US-0009150 - 2/March/21 Acmatac SEING
            }
            //** MN-01032021-US-0009152-US-0009153

            // US-0009151 - 2/March/21 Acmatac SEING, AC6) 'Contract Addendum' is appended to Agreement if the Seller Account has text in the 'Contract Addendum' field. This would just be added at the end of the Standard text; all is within the scrolling window.
            sellerAgreementAddendum = dd.EBH_BusinessName__r.Agreement_Addendum__c;
            // END of US-0009151

            // US-0009333 - 02/April/21 Mony Nou 
            // seller.Agreement_Addendum__c = dd.EBH_BusinessName__r.Agreement_Addendum__c; //MN-06042021 - Move to use with getSobject('EBH_BusinessName__r') instead
            // END of US-0009333

            // US-0009320 - 06/April/21 Mony Nou
            seller = (Account) dd.getSobject(RELATED_OBJ_ACC);
            sellerName = dd.EBH_BusinessName__r.Name;
            sellerFullAddress = dd.EBH_BusinessName__r.EBH_FullBillingAddress__c;
            //END of US-0009320

            // now check the status if the deals
            dca = new Deal_Contract_Agreement__c(id=dd.Deal_Contract_Agreement__c);
            // SRONG/08.01.2024/US-0014252
            deals  = [Select d.Id, d.EBH_Quantity__c,d.EBH_MaximumPurchases__c,d.EBH_RRPWASPrice__c, d.EBH_eBayLink__c, d.EBH_BusinessName__c, d.EBH_CommentfromeBaySourcer__c,Seller_Approver_1__c,
                                                d.EBH_ProductTitle__c, 
                                                d.EBH_DealEndDate__c, d.EBH_DealStartDate__c,
                                                d.EBH_DealEndTime__c, EBH_DealStartTime__c,
                                                d.eBay_Seller_Name__c, d.EBH_eBayItemID__c, d.EBH_Vertical__c, 
                                                d.EBH_DealCalendarDescription__c, d.EBH_CommentfromSeller__c, 
                                                d.EBH_Status__c,
                                                d.EBH_Category__c, 
                                                d.Deal_Contract_Agreement__c,
                                                d.Deal_Contract_Agreement__r.CreatedById,
                                                d.Quantity_Limitation_per_Purchaser__c,
                                                d.EBH_DealFormat__c,
                                                d.EBH_DealPrice__c,d.List_Price__c,
                                                d.EBH_SellerPrice__c,
                                                d.EBH_Subsidy__c,
                                                d.ListPriceMSKULower__c,
                                                d.ListPriceMSKUUpper__c,
                                                d.SellersDealPriceMSKULower__c,
                                                d.SellersDealPriceMSKUUpper__c,
                                                d.SellersOfferPriceMSKULower__c,
                                                d.SellersOfferPriceMSKUUpper__c,
                                                d.Deal_Contract_Agreement__r.Current_Digest__c,
                                                d.Deal_Contract_agreement__r.Name,
                                                d.Seller_Approver_1_Email__c,
                                                d.Seller_Approver_2_Email__c,
                                                d.Seller_Approver_3_Email__c,
                                                d.Seller_Approver_4_Email__c,
                                                d.Seller_Approver_5_Email__c,
                                                d.Name,
                                                d.Optional_Notes__c,
                                                d.EBH_DealSiteId__c,
                                                d.EBH_SubsidyP__c,
                                                d.Subsidy_Type__c
                                                From EBH_Deal__c d 
                                                where Deal_Contract_Agreement__r.Current_Digest__c=:dcaidencrypted and
                                                d.EBH_Status__c = :STATUS_SENT_TO_SEELLER
                                                // AND Id NOT IN: startDateInPastDealIds // 28.05.2021 / Sophal Noch / US-0009533, 04.06.2021 / Sophal Noch / US-0009649
                                                ];
          
            if (deals.isEmpty()) {
                rendered = false;
                alreadyreplied = true;
                return null;
            }
            
            
            // Deal_Timezone__c dealTimezone = Deal_Timezone__c.getInstance();
            // Timezone tz = Timezone.getTimeZone(dealTimezone.TimeZone__c);
            // Datetime dNow =  DateTime.newInstance(System.Now().getTime() + tz.getOffset(System.Now()));
            
            // populate the wrapper to be displayed
            for(EBH_Deal__c d: deals){
                if(d.EBH_DealStartDate__c!=null && d.EBH_DealStartTime__c!=null){
                    //Datetime dealStartDate = Datetime.newInstance(d.EBH_DealStartDate__c,d.EBH_DealStartTime__c);
                    //if(dealStartDate.getTime()>dNow.getTime()||d.Deal_Revised__c==true){

                        setDealIdInWrapper.add(d.Id);
                        // SRONG/08.01.2024/US-0014252
                        dealsWrapper.add(new DealWrapper(d.Id, 
                                    d.eBay_Seller_Name__c, 
                                    d.EBH_eBayItemID__c,
                                    d.EBH_ProductTitle__c, 
                                    d.EBH_Quantity__c,
                                    d.EBH_Status__c, 
                                    d.EBH_CommentfromSeller__c, 
                                    d.EBH_DealStartDate__c,
                                    d.EBH_DealEndDate__c, 
                                    d.EBH_DealStartTime__c,
                                    d.EBH_DealEndTime__c,                                    
                                    //d.Quantity_Limitation_per_Purchaser__c,//TH:replace to Maximum Purchases  : US-0009488 : 05/03/2021
                                    d.EBH_MaximumPurchases__c,
                                    d.EBH_DealFormat__c,
                                    d.EBH_DealPrice__c,
                                    d.ListPriceMSKULower__c,
                                    d.ListPriceMSKUUpper__c,
                                    d.SellersDealPriceMSKULower__c,
                                    d.SellersDealPriceMSKUUpper__c,
                                    d.SellersOfferPriceMSKULower__c,
                                    d.SellersOfferPriceMSKUUpper__c,
                                    d.EBH_SellerPrice__c,                                   
                                    d.Name,
                                    d.EBH_Subsidy__c, 
                                    //d.List_Price__c,//TH:replace to RRP/WAS Price  : US-0009488 : 05/03/2021
                                    d.EBH_RRPWASPrice__c,
                                    d.Optional_Notes__c,
                                    d.EBH_DealSiteId__c,
                                    d.EBH_SubsidyP__c,
                                    d.Subsidy_Type__c)); 
                    //}
                }
            }

            dwSize = dealsWrapper.size(); // Sophal:29/04/2021: US-0009476
           
            // for debugging
            //dealsJSON = JSON.serialize(deals);

                                                
        }
        catch (Exception ex) {lsterrorMessage += ex.getMessage()+'\n';incorrecturl = true;rendered = false;System.debug(ex);ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, 'Incorrect URL'+ex.getMessage()));}
    return null;
    
  }
  
  /**
  * User clicks on Sign Agreement 
  */

  public PageReference checkNotSentToSeller(){
       // Sophal:29/04/2021: US-0009476
    try{

        List<Id> ids = new List<Id>();
        for(EBH_Deal__c dSel : deals){
            if( setDealIdInWrapper.contains(dSel.Id) ){ getSellerApprovalEmail(dSel); } // US-0008605
            ids.add(dSel.Id);
        }

        String errorMessage = Label.Error_Deals_Have_Been_Approved_Or_Declined;

        Boolean hasDealNotSentToSeller = false;

        for(EBH_Deal__c d : [Select Id, EBH_Status__c From EBH_Deal__c Where Id in :ids AND EBH_Status__c != :STATUS_SENT_TO_SEELLER]){ // 28.05.2021 / Sophal Noch / US-0009533
            hasDealNotSentToSeller = true;
            if(d.EBH_Status__c == STATUS_EXPIRED){errorMessage = Label.DD_Contract_not_approved_on_time;}
        }
        
        if(hasDealNotSentToSeller){

            documentApprovalCheck = true;
            rendered = false;
            canContinueSaving = false;
            
            // 28.05.2021 / Sophal Noch / US-0009533
            if(errorMessage == Label.DD_Contract_not_approved_on_time){
                latereply = true;
            }else{ 
                hasBeenApprovedOrDeclined = true;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMessage));
           
        }else{
            canContinueSaving = true;
            hasBeenCheckedBeforeSave = true;
        }



    }catch(Exception e){lsterrorMessage += e.getMessage()+'\n';ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));}


    return null;

  }

    
  public PageReference doSave() {
    // System.debug('nsp: doSave here ---- '+dwChunkIndex);
      Savepoint sp = Database.setSavepoint();

        try{

            // System.debug('nsp: doSave here');

            Map<Id,EBH_Deal__c> mapDealUpdate= updateSellerInfo();

            List<Id> ids = new List<Id>();

            for(EBH_Deal__c dSel : mapDealUpdate.values()){
                // if( setDealIdInWrapper.contains(dSel.Id) ){ getSellerApprovalEmail(dSel); } // US-0008605
                ids.add(dSel.Id);
            }
           
            List<EBH_Deal__c> dealList = [Select Id, EBH_Status__c From EBH_Deal__c Where Id in :ids AND EBH_Status__c != :STATUS_SENT_TO_SEELLER];
            
            if(!dealList.isEmpty() || !hasBeenCheckedBeforeSave){

                if(!dealList.isEmpty()){ documentApprovalCheck = true;}

                rendered = false;
                canContinueSaving = false;
                return null;
            }
            
            EBH_DealTriggerHandler.FROM_APPROVE_FORM=true;
            //update comment and approval timestamp
           
              
            // System.debug('<<<<dca='+dca);
            // save DCA 
            update dca;
            
            // System.debug('<<<<deals='+lstUpdate);
            
            // save deals info
            update mapDealUpdate.values();
            // System.debug('<<<< updated deals='+deals);
            
            emailsapprovers = new List<String>();
           
            //ids = '';
            
           
            for(EBH_Deal__c dSel : deals){

                if(mapDealUpdate.containsKey(dSel.Id)){

                     // Sophal:29/04/2021: US-0009476

                    // System.debug('<<<<<dSel='+dSel);
                    if(dSel.EBH_Status__c == 'Seller Approved' || dSel.EBH_Status__c == 'Seller Rejected'){
                        hasApprovalOrRejected = true;
                        
                        
                        // SPP not required anymore, we will pass the dca id and will filterd Sel.EBH_Status__c == 'Planned'
                        //ids += dSel.Id+'&';
                        
                        dealcontract = dSel.Deal_Contract_Agreement__c;
                        sellerName = dSel.eBay_Seller_Name__c;
                        sellerId = dSel.EBH_BusinessName__c;
                        
                        dealcontractname = dSel.Deal_Contract_Agreement__r.Name;
                        
                        // Sophal:03/03/2022:US-0010859 move code below to a method for reusibility 
                        // if (String.isNotBlank(dSel.Seller_Approver_1_Email__c)&&!emailsapprovers.contains(dSel.Seller_Approver_1_Email__c)) {
                        //     emailsapprovers.add(dSel.Seller_Approver_1_Email__c);
                        // }
                        // if (String.isNotBlank(dSel.Seller_Approver_2_Email__c)&&!emailsapprovers.contains(dSel.Seller_Approver_2_Email__c)) {
                        //     emailsapprovers.add(dSel.Seller_Approver_2_Email__c);
                        // }
                        // if (String.isNotBlank(dSel.Seller_Approver_3_Email__c)&&!emailsapprovers.contains(dSel.Seller_Approver_3_Email__c)) {
                        //     emailsapprovers.add(dSel.Seller_Approver_3_Email__c);
                        // }
                        // if (String.isNotBlank(dSel.Seller_Approver_4_Email__c)&&!emailsapprovers.contains(dSel.Seller_Approver_4_Email__c)) {
                        //     emailsapprovers.add(dSel.Seller_Approver_4_Email__c);
                        // }
                        // if (String.isNotBlank(dSel.Seller_Approver_5_Email__c)&&!emailsapprovers.contains(dSel.Seller_Approver_5_Email__c)) {
                        //     emailsapprovers.add(dSel.Seller_Approver_5_Email__c);
                        // }
                        populateEmailsapprovers(dSel, emailsapprovers);
                    }


                }
                                

            }


            
           //if(hasApprovalOrRejected) sendPDf(ids,dealcontract,dealcontractName,sellerName,emailsapprovers);
              // Agreement signed 
            rendered = false;

            if(dwChunkIndex >= dwSize){

                agreementsigned = true;
                canContinueSaving = false;
                hasBeenCheckedBeforeSave = false;
            }
        }catch(DmlException e){lsterrorMessage += e.getMessage()+'\n';canContinueSaving = false;hasBeenCheckedBeforeSave = false;Database.rollback(sp);System.debug(e);ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getDmlMessage(0)));return null;
        }finally{
            EBH_DealTriggerHandler.FROM_APPROVE_FORM=false;
        }
        
        return null;
    }

    /***************************************************************************************************************************************
	@ Method:        populateEmailsapprovers
	@ Version:       1.0
	@ Author:        Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:       US-0010859 - Enable user with 'NA Manage Deals' permission set to resend the Deal pdf file
	-----------------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 03.03.2022 / Sophal Noch / Created the method.
	-----------------------------------------------------------------------------------------------------------------------------------------*/	 
    private static void populateEmailsapprovers(EBH_Deal__c dSel, List<String> emailsapprovers){
        
        if (String.isNotBlank(dSel.Seller_Approver_1_Email__c)&&!emailsapprovers.contains(dSel.Seller_Approver_1_Email__c)) {
            emailsapprovers.add(dSel.Seller_Approver_1_Email__c);
        }
        if (String.isNotBlank(dSel.Seller_Approver_2_Email__c)&&!emailsapprovers.contains(dSel.Seller_Approver_2_Email__c)) {
            emailsapprovers.add(dSel.Seller_Approver_2_Email__c);
        }
        if (String.isNotBlank(dSel.Seller_Approver_3_Email__c)&&!emailsapprovers.contains(dSel.Seller_Approver_3_Email__c)) {
            emailsapprovers.add(dSel.Seller_Approver_3_Email__c);
        }
        if (String.isNotBlank(dSel.Seller_Approver_4_Email__c)&&!emailsapprovers.contains(dSel.Seller_Approver_4_Email__c)) {
            emailsapprovers.add(dSel.Seller_Approver_4_Email__c);
        }
        if (String.isNotBlank(dSel.Seller_Approver_5_Email__c)&&!emailsapprovers.contains(dSel.Seller_Approver_5_Email__c)) {
            emailsapprovers.add(dSel.Seller_Approver_5_Email__c);
        }
    }

    private void getSellerApprovalEmail(EBH_Deal__c deal){
        //US-0008605 compare approver token to get approver's email
        String currentDigest = deal.Deal_Contract_Agreement__r.Current_Digest__c;
        if(String.isNotBlank(deal.Seller_Approver_1_Email__c) && approverToken == DD_SendToSellerHelper.generateSellerApproverToken(currentDigest+deal.Seller_Approver_1_Email__c)) emailAddress = deal.Seller_Approver_1_Email__c;
        if(String.isNotBlank(deal.Seller_Approver_2_Email__c) && approverToken == DD_SendToSellerHelper.generateSellerApproverToken(currentDigest+deal.Seller_Approver_2_Email__c)) emailAddress = deal.Seller_Approver_2_Email__c;
        if(String.isNotBlank(deal.Seller_Approver_3_Email__c) && approverToken == DD_SendToSellerHelper.generateSellerApproverToken(currentDigest+deal.Seller_Approver_3_Email__c)) emailAddress = deal.Seller_Approver_3_Email__c;
        if(String.isNotBlank(deal.Seller_Approver_4_Email__c) && approverToken == DD_SendToSellerHelper.generateSellerApproverToken(currentDigest+deal.Seller_Approver_4_Email__c)) emailAddress = deal.Seller_Approver_4_Email__c;
        if(String.isNotBlank(deal.Seller_Approver_5_Email__c) && approverToken == DD_SendToSellerHelper.generateSellerApproverToken(currentDigest+deal.Seller_Approver_5_Email__c)) emailAddress = deal.Seller_Approver_5_Email__c;
    }
    
    public PageReference sendPDF()
    {
        try{
            System.AssertEquals(hasApprovalOrRejected,true);
            if (hasApprovalOrRejected) {
                if (String.isNotBlank(vfcmp_val)) urlparam = vfcmp_param + vfcmp_val;
                if (seller != null && seller.Id != null) accountId = seller.Id; //MN-08042021-US-0009333 //need to get AccountId to pass to DealAgreementPDF
                no_of_deals = dealsWrapper.size(); //MN-08092021-US-0010019
                generatePdf(dca.id,dealcontractname,dealcontract,sellerId,sellerName,emailsapprovers);
            }

        }catch(DmlException e){System.debug(e);ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getDmlMessage(0)));}
        return null;
    }

    /***************************************************************************************************************************************
	@ Method:        resendPDF
	@ Version:       1.0
	@ Author:        Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:       US-0010859 - Enable user with 'NA Manage Deals' permission set to resend the Deal pdf file
	-----------------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 03.03.2022 / Sophal Noch / Created the method.
	-----------------------------------------------------------------------------------------------------------------------------------------*/	 
    @AuraEnabled
    public static Map<String,String> resendPDF(String dcaId){

        Map<String,string>  mapResult = new Map<String,string>();
        try{

            Id profileId = Userinfo.getprofileId();
            if(profileId == EBH_ConstantsUtility.ADMIN_PROFILE_ID || ApexUtil.checkPermissionSet(new Set<String>{PERM_SET_NA_MANAGED_DEAL})){
                EBH_Deal__c firstDeal;
                String dealcontract;
                String sellerId;
                String sellerName;
                String dealcontractname;
                Integer numOfDeals = 0;

                List<String> emailsapprovers  = new List<String>();
                for(EBH_Deal__c deal : [Select
                                        Id,
                                        EBH_DealStartDate__c,
                                        EBH_DealStartTime__c,
                                        Deal_Contract_Agreement__c,
                                        Deal_Contract_Agreement__r.Id,
                                        Deal_Contract_Agreement__r.Name,
                                        Deal_Contract_Agreement__r.Current_Digest__c,
                                        EBH_Status__c,
                                        eBay_Seller_Name__c,
                                        EBH_BusinessName__c,
                                        EBH_BusinessName__r.Id,
                                        EBH_BusinessName__r.EBH_PrimarySite__c, 
                                        EBH_BusinessName__r.NA_Contract_Type__c,
                                        Seller_Approver_1_Email__c,
                                        Seller_Approver_2_Email__c,
                                        Seller_Approver_3_Email__c,
                                        Seller_Approver_4_Email__c,
                                        Seller_Approver_5_Email__c
                                    From EBH_Deal__c 
                                    Where Deal_Contract_Agreement__r.Id=:dcaId]){

                    if(firstDeal == null) firstDeal = deal;

                    if(SET_APPROVAL_STATUS.contains(deal.EBH_Status__c) && deal.EBH_DealStartDate__c != null && deal.EBH_DealStartTime__c != null){
                            
                        dealcontract = deal.Deal_Contract_Agreement__c;
                        sellerName = deal.eBay_Seller_Name__c;
                        sellerId = deal.EBH_BusinessName__c;
                        dealcontractname = deal.Deal_Contract_Agreement__r.Name;

                        populateEmailsapprovers(deal,emailsapprovers);
                        numOfDeals ++; // total numbers of approved and rejected deals
                    }
                    
                }

                if(numOfDeals > 0){
                    DocumentApprovalController daCtr = new DocumentApprovalController(firstDeal, numOfDeals);
                    daCtr.handleGeneratePdf(dcaId, dealcontractname, dealcontract, sellerId, sellerName, emailsapprovers);
                }
            }

            mapResult.put('status','ok');


        }catch(Exception ex){ mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}
        return mapResult;
    }

    public void handleGeneratePdf(String dcId, String Dealcontractname, String dealcontract, String sellerId, String sellerName, List<String> emailsapprovers){        
        generatePdf(dcId, Dealcontractname, dealcontract, sellerId, sellerName, emailsapprovers);
    }

    private static String accountId;
    private static Integer no_of_deals;
    private static void generatePdf(String dcId,String Dealcontractname, String dealcontract, String sellerId, String sellerName, List<String> emailsapprovers){

        //MN-08092021-US-0010019 Check if there are NA Amendment Deal associated with that DCA then we will send another email template + attachment body
        List<EBH_Deal__c> lstADeals = new List<EBH_Deal__c>();
        for (EBH_Deal__c d : [SELECT Id FROM EBH_Deal__c 
                                WHERE RecordType.DeveloperName =:NA_DEAL_RECORDTYPE AND Deal_Contract_Agreement__c =:dcId 
                                AND Originating_Deal__c != NULL AND Amendment_Date__c != NULL]) { lstADeals.add(d); }
        
        

        

        List<Attachment> lstAttach = new List<Attachment>();//MN-25022021-US-0009152
        List<ContentVersion> lstCont = new List<ContentVersion>(); //MN-25022021-US-0009152
        
        Blob b;
        Blob b_agreement;
        Blob aB;

        String filename;
        String filename_agreement;
        String aFilename;

        Attachment attach;
        Attachment attach_ada;
        Attachment aAttach;

        // MN-08042021-US-0009333
        Boolean isSendDealAgreement = String.isNotBlank(urlparam); //if urlparam has value that mean it need to send Deal Agreement to Seller

        if (lstADeals.isEmpty() || no_of_deals > lstADeals.size()) { //MN-08092021-US-0010019 If there is no NA Amendment Deal or has some of it, then keep the existed process as is
            // SPP - replace by dca id
            PageReference pDF = Page.DocumentApprovalPDF;
            pDF.getParameters().put('dcaid',dcId);
            /* //MN-05032021-Shortening IF conditions
            Blob b;
            if(!Test.isRunningTest()){
                b = pDF.getContentAsPDF();
            }else{
                b = Blob.valueOf('testBody');
            }
            */
            b = (Test.isRunningTest())?Blob.valueOf('testBody'):pDF.getContentAsPDF();
            filename = 'DailyDeals_ContractAgreement_'+Dealcontractname+'_'+System.today().format();
            //MN-050320201 - Create via new method instead
            attach = createAttachment(b, filename, 'pdf', false, dealcontract);
            lstAttach.add(attach); //MN-25022021-US-0009152
            //create attachement
            /* //MN-05032021 - Move to method
            Attachment attach = new Attachment();
            attach.Body = b;
            attach.Name = filename+'.pdf';
            attach.IsPrivate = false;
            attach.ParentId = dealcontract;
            // insert attach;
            */
            
            if (isSendDealAgreement && String.isNotBlank(accountId)) { //MN-08042021-US-0009333 send agreement only when eBay Seller has Primary Site = US and Canada
                
                urlparam += ('&accid=' + String.escapeSingleQuotes(accountId)); //pass account's id to DealAgreementPDF
                
                //***** MN-25022021-US-0009152
                pDF = new PageReference('/apex/DealAgreementPDF' + (String.isNotBlank(urlparam)?urlparam:''));
                b_agreement = (Test.isRunningTest())?Blob.valueOf('testBody'):pDF.getContentAsPDF();
                filename_agreement = 'Deals Agreement';
                attach_ada = createAttachment(b_agreement, filename_agreement, 'pdf', false, dealcontract);
                lstAttach.add(attach_ada);
                //***** MN-25022021-US-0009152
            }
        }

        //MN-08092021-US-0010019 - For NA Amendment Deal 
        if (!lstADeals.isEmpty()) {

            PageReference aPDF = Page.DocumentApprovalPDF;
            aPDF.getParameters().put('dcaid',dcId);
            aPDF.getParameters().put('is_ad','1'); //ad = Amendment Deal (1=true)

            aB = (Test.isRunningTest())?Blob.valueOf('testBody'):aPDF.getContentAsPDF();
            aFilename = 'Deals_Subsidy_Contract_Amendment_Notice' + '_' + System.today().format();
            aAttach = createAttachment(aB, aFilename, 'pdf', false, dealcontract);
            lstAttach.add(aAttach); 
        
        }


        insert lstAttach;
        

        if (lstADeals.isEmpty() || no_of_deals > lstADeals.size()) { //MN-08092021-US-0010019 If there is no NA Amendment Deal or has some of it, then keep the existed process as is
            // create contentversion 
            // When the PDF is created we need to store the PDF in SF for lightning 
            // lets create as chatter file and link to each deal record that has just been approved. 
            // Keep the same naming convention as what is sent out to the seller.
            /* //MN-05032021 - Move to method
            ContentVersion cont = new ContentVersion();
            cont.Title = filename;
            cont.PathOnClient = filename + '.pdf';
            cont.VersionData = b;
            cont.Origin = 'H';
            cont.FirstPublishLocationId = sellerId;
            */
            ContentVersion cont = createContentVersion(b, filename, 'pdf', sellerId);
            //insert cont;     
            lstCont.add(cont); //MN-25022021-US-0009152
            
            if (isSendDealAgreement) { //MN-08042021-US-0009333 only process when eBay Seller has Primary Site = US and Canada
                //***** MN-25022021-US-0009152
                ContentVersion cont_agreement = createContentVersion(b_agreement, filename_agreement, 'pdf', sellerId);
                lstCont.add(cont_agreement);
                //***** MN-25022021-US-0009152
            }
        }

        //MN-08092021-US-0010019 - For NA Amendment Deal 
        if (!lstADeals.isEmpty()) {
            ContentVersion aCont = createContentVersion(aB, aFilename, 'pdf', sellerId);
            lstCont.add(aCont); //MN-25022021-US-0009152
        }
        


        insert lstCont;

        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>(); //MN-08092021-US-0010019
        
        if (lstADeals.isEmpty() || no_of_deals > lstADeals.size()) { //MN-08092021-US-0010019 If there is no NA Amendment Deal or has some of it, then keep the existed process as is
            // send email
            List<Messaging.EmailFileAttachment> lstEFA = new List<Messaging.EmailFileAttachment>(); //MN-25022021-US-0009152
            /* //MN-05032021 - Move to method
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setContentType('application/pdf');
            efa.setFileName(attach.Name);
            efa.setBody(attach.Body);
            */

            Messaging.EmailFileAttachment efa = createEmailFileAttachment(attach.Body, 'application/pdf', attach.Name);
            lstEFA.add(efa);

            if (isSendDealAgreement) { //MN-08042021-US-0009333 only process when eBay Seller has Primary Site = US and Canada
                //***** MN-25022021-US-0009152
                Messaging.EmailFileAttachment efa_agreement = createEmailFileAttachment(attach_ada.Body, 'application/pdf', attach_ada.Name);
                lstEFA.add(efa_agreement);
                //***** MN-25022021-US-0009152
            }
            
            EmailTemplate emailTemplate = [Select e.HtmlValue, e.DeveloperName,Subject From EmailTemplate e where DeveloperName = 'NA_Deals_Send_PDF'];
            String body = emailTemplate.HtmlValue.replace('{!Deal_Contract_Agreement__c.Seller_Name__c}',sellerName);
            String subject = emailTemplate.Subject;
            //List<String> listCCAddresses = new List<String>{Label.DD_SubsidyDL}; //LA-14-03-2023-US-0013384
            
            Messaging.SingleEmailMessage emailTobeSent = new Messaging.SingleEmailMessage();
            emailTobeSent.setSubject(subject);
            emailTobeSent.setHtmlBody(body); 
            emailTobeSent.setToAddresses(emailsapprovers);
            //emailToBeSent.setCcAddresses(listCCAddresses); //LA-14-03-2023-US-0013384

            OrgWideEmailAddress orgWide = ApexUtil.getOWDbyAddress(System.label.OWD_Deal_NA);
            if(orgWide != null) emailToBeSent.setOrgWideEmailAddressId(orgWide.Id);
            //emailToBeSent.setReplyTo(replyTo);
            //emailTobeSent.setFileAttachments(new Messaging.EmailFileAttachment[] {efa}); // Sends the email //MN-25022021-US-0009152
            emailTobeSent.setFileAttachments(lstEFA); // Sends the email //MN-25022021-US-0009152

            //emailTobeSent.setTemplateId(emailTemplate.Id);
            //emailTobeSent.setTargetObjectId(UserInfo.getUserId());
            //emailTobeSent.setWhatId(dealcontract);
            //emailTobeSent.setSaveAsActivity(false);

            lstEmails.add(emailTobeSent); //MN-08092021-US-0010019
        }
         
        //MN-08092021-US-0010019 - Send Email to Seller for NA Amendment Deal 
        if (!lstADeals.isEmpty()) {

            List<Messaging.EmailFileAttachment> lstEFA = new List<Messaging.EmailFileAttachment>();
            Messaging.EmailFileAttachment efa = createEmailFileAttachment(aAttach.Body, 'application/pdf', aAttach.Name);
            lstEFA.add(efa);

            EmailTemplate emailTemplate = [Select e.HtmlValue, e.DeveloperName,Subject From EmailTemplate e where DeveloperName = 'NA_Amendment_Deals_Send_PDF'];
            String body = emailTemplate.HtmlValue.replace('{!Deal_Contract_Agreement__c.Seller_Name__c}',sellerName);
            String subject = emailTemplate.Subject;
            //List<String> listCCAddresses = new List<String>{Label.DD_SubsidyDL}; //LA-14-03-2023-US-0013384
            
            Messaging.SingleEmailMessage emailTobeSent = new Messaging.SingleEmailMessage();
            emailTobeSent.setSubject(subject);
            emailTobeSent.setHtmlBody(body); 
            emailTobeSent.setToAddresses(emailsapprovers);
            //emailToBeSent.setCcAddresses(listCCAddresses); //LA-14-03-2023-US-0013384

            OrgWideEmailAddress orgWide = ApexUtil.getOWDbyAddress(System.label.OWD_Deal_NA);
            if(orgWide != null) emailToBeSent.setOrgWideEmailAddressId(orgWide.Id);
            emailTobeSent.setFileAttachments(lstEFA); // Sends the email //MN-25022021-US-0009152

            lstEmails.add(emailTobeSent); //MN-08092021-US-0010019
        }

        if(!Test.isRunningTest()){
            //Messaging.SendEmailResult [] r1 = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailTobeSent}); //MN-08092021-US-0010019
            Messaging.SendEmailResult [] r1 = Messaging.sendEmail(lstEmails); //MN-08092021-US-0010019
        }
    }

    private static Attachment createAttachment(Blob body, String fileName, String fileExt, Boolean isPrivate, Id parentId) {
        Attachment att = new Attachment();
        att.Body = body;
        att.Name = fileName + (String.isNotBlank(fileExt)?'.':'') + fileExt;
        att.IsPrivate = isPrivate;
        att.ParentId = parentId;
        return att;
    }

    private static ContentVersion createContentVersion(Blob body, String fileName, String fileExt, Id locationId) {
        ContentVersion conver = new ContentVersion();
        conver.Title = fileName;
        conver.PathOnClient = fileName + (String.isNotBlank(fileExt)?'.':'') + fileExt;
        conver.VersionData = body;
        conver.Origin = 'H';
        conver.FirstPublishLocationId = locationId;
        return conver;
    }

    private static Messaging.EmailFileAttachment createEmailFileAttachment(Blob body, String contentType, String fileName) {
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setContentType(contentType);
        efa.setFileName(fileName);
        efa.setBody(body);
        return efa;
    }
    
    private Map<Id,EBH_Deal__c> updateSellerInfo(){
        // List<EBH_Deal__c> lstUpdate = new List<EBH_Deal__c>();
        // Integer i = 0;
        // for(DealWrapper dw : dealsWrapper){
        //     EBH_Deal__c d = new EBH_Deal__c(Id=deals.get(i).Id);
        //     deals.get(i).EBH_CommentfromSeller__c = dw.Comment;
        //     deals.get(i).EBH_SellerEmail__c = emailAddress;
        //     deals.get(i).EBH_SellerAcceptedFrom__c = ipAddress;
        //     deals.get(i).Seller_Name__c = signerName;
        //     deals.get(i).EBH_eBayItemID__c = dw.eBay_Item_ID;
        //     deals.get(i).Seller_Response_Time__c = System.Now();
        //     deals.get(i).EBH_Status__c = dw.Status;
        //     d.EBH_CommentfromSeller__c = dw.Comment;
        //     d.EBH_SellerEmail__c  = emailAddress;
        //     d.EBH_SellerAcceptedFrom__c= ipAddress;
        //     d.Seller_Name__c = signerName;
        //     d.EBH_eBayItemID__c = dw.eBay_Item_ID;
        //     d.Seller_Response_Time__c = System.Now();
        //     d.EBH_Status__c = dw.Status;
        //     if(dw.Status == 'Seller Approved')d.Seller_Approved__c = true;
        //     lstUpdate.add(d);
        //     // todo : we delete the digest
        //     i++;
        // }
          //  System.debug('<<<<Deal updateSellerInfo='+deals);

           // Sophal:29/04/2021: US-0009476

        Map<Id,EBH_Deal__c> mapDealUpdate = new Map<Id,EBH_Deal__c>();

        Integer index = dwChunkIndex;
        Integer dealToWrap = 0;

        for(Integer i = dwChunkIndex; i < dwSize; i ++ ){

            getSellerApprovalEmail(deals.get(i)); // US-0008605

            EBH_Deal__c d = new EBH_Deal__c(Id=deals.get(i).Id);

            deals.get(i).EBH_CommentfromSeller__c = dealsWrapper[i].Comment;
            deals.get(i).EBH_SellerEmail__c = emailAddress;
            deals.get(i).EBH_SellerAcceptedFrom__c = ipAddress;
            deals.get(i).Seller_Name__c = signerName;
            deals.get(i).EBH_eBayItemID__c = dealsWrapper[i].eBay_Item_ID;
            deals.get(i).Seller_Response_Time__c = System.Now();
            deals.get(i).EBH_Status__c = dealsWrapper[i].Status;
            d.EBH_CommentfromSeller__c = dealsWrapper[i].Comment;
            d.EBH_SellerEmail__c  = emailAddress;
            d.EBH_SellerAcceptedFrom__c= ipAddress;
            d.Seller_Name__c = signerName;
            d.EBH_eBayItemID__c = dealsWrapper[i].eBay_Item_ID;
            d.Seller_Response_Time__c = System.Now();
            d.EBH_Status__c = dealsWrapper[i].Status;
            if(dealsWrapper[i].Status == 'Seller Approved')d.Seller_Approved__c = true;
            mapDealUpdate.put(d.Id,d);
            // todo : we delete the digest

        
            index++;
            dealToWrap ++;

            if(dealToWrap >= dwChunkSizeLimit){
                break;
            }



        }

        dwChunkIndex = index;

        return mapDealUpdate;
    }
    

    public String getIPAddress() {
        //Map to hold current URL header parameters
        Map<String, String> mapHeaders = ApexPages.currentPage().getHeaders();   

        //Proceed further only and only if map of header parameter have not null value with it
        if(mapHeaders != null) {

            String ipAddress = mapHeaders.get('True-Client-IP');
            if(ipAddress == null){
                ipAddress = mapHeaders.get('X-Salesforce-SIP');
            }
            
            return ipAddress;
        }
        
        return null;
    }
    
    /**
    * User Accept/Reject
    */
    public PageReference changeStatus(){
        try{
            String d_status = Apexpages.currentPage().getParameters().get('status');
            d_status = String.isBlank(d_status) ? null : String.escapeSingleQuotes(d_status); // EscapeSingleQuotes, Acmatac SEING March/05/2021, Prevent SQL Injection

            String d_index_str = Apexpages.currentPage().getParameters().get('index');
            d_index_str = String.isBlank(d_index_str) ? null : String.escapeSingleQuotes(d_index_str); // EscapeSingleQuotes, Acmatac SEING March/05/2021, Prevent SQL Injection
            if(!d_index_str.isNumeric()){
                return null;
            }
            Integer d_index = Integer.valueOf(d_index_str); 
            deals.get(d_index).EBH_Status__c = d_status;
            
            // for debugginh
            //dealsJSON = JSON.serialize(deals);
            
            return null;
        }catch(DmlException e){System.debug(e);ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getDmlMessage(0)));return null;
        }
    }
    
    /**
    * User change mass status for Accept/Reject
    */
    public PageReference changeReplicateStatus() {
        for(DealWrapper dw : dealsWrapper){
            dw.Status = replicate_status;
        }
        return null;
    }
    
    /**
    * User update mass comment
    */
    public PageReference doChangeReplicateReason(){
        for(DealWrapper dw : dealsWrapper){
            dw.Comment = replicate_reason;
        }
        return null;
    }
    
    public class DocumentApprovalException extends Exception {}
    
    public class DealWrapper {
        
        public String dId {get;set;}
        public String eBay_Seller {get;set;}
        public String eBay_Item_ID {get;set;}
        public String Description {get;set;}
        public Decimal Quantity {get;set;}
        public String Status {get;set;}
        public String Comment {get;set;}
        public Date Deal_Start_Date{get;set;}
        public Date Deal_End_Date{get;set;}
        
        public Time Deal_Start_Time{get;set;}
        public Time Deal_End_Time{get;set;}
        
        public Decimal QuantityLimit {get;set;}
        public String PagePlacement {get;set;}
        public Decimal Deal_Price {get;set;}
        public String Optional_Notes {get;set;}
        //public String Deal_Price_Multi_SKU {get;set;}
        //public String Seller_Price_Multi_SKU {get;set;}
        //public String List_Price_Multi_SKU {get;set;}
        
        public Decimal List_Price_MSKU_Lower {get;set;}
        public Decimal List_Price_MSKU_Upper {get;set;}

        public Decimal Sellers_Deal_Price_MSKU_Lower {get;set;}
        public Decimal Sellers_Deal_Price_MSKU_Upper {get;set;}

        public Decimal Sellers_Offer_Price_MSKU_Lower {get;set;}
        public Decimal Sellers_Offer_Price_MSKU_Upper {get;set;}
        
        
        public Decimal Seller_Price {get;set;}       
        public Decimal Subsidy {get;set;}
        public Decimal ListPrice {get;set;}
        public String DealName {get;set;}

        public String DealSite {get;set;}
        // SRONG/08.01.2024/US-0014252
        public Decimal SubsidyP {get;set;}
        public String SubsidyType {get;set;}

        public String reason_amendment {get;set;} //MN-08092021-US-0010019
        public String original_dca {get;set;} //MN-08092021-US-0010019
        
        public DealWrapper(String di, String es, String eii, String des, Decimal qty, String s, String c, 
                            Date sd, Date ed, 
                            Time sdt, Time edt,                             
                            Decimal qtyl, String place, Decimal dp,
                            Decimal priceskulow, Decimal priceskuupper,
                            Decimal dealskulow, Decimal dealskuupper,
                            Decimal offerskulow, Decimal offerskuupper,
                            Decimal sp, String Name, Decimal sub, Decimal lp,String OpNote, String dealSite,Decimal subsidyP,String SubsidyType){
            //                                
            construct(di, es, eii, des, qty, s, c, sd, ed, sdt, edt, qtyl, place, dp, priceskulow, priceskuupper, dealskulow, dealskuupper, offerskulow, offerskuupper, sp, Name, sub, lp, OpNote, dealSite,subsidyP,SubsidyType); 
        }

        public DealWrapper(String di, String es, String eii, String des, Decimal qty, String s, String c, 
                            Date sd, Date ed, 
                            Time sdt, Time edt,                             
                            Decimal qtyl, String place, Decimal dp,
                            Decimal priceskulow, Decimal priceskuupper,
                            Decimal dealskulow, Decimal dealskuupper,
                            Decimal offerskulow, Decimal offerskuupper,
                            Decimal sp, String Name, Decimal sub, Decimal lp,String OpNote,Decimal subsidyP,String SubsidyType){
            //                    
            construct(di, es, eii, des, qty, s, c, sd, ed, sdt, edt, qtyl, place, dp, priceskulow, priceskuupper, dealskulow, dealskuupper, offerskulow, offerskuupper, sp, Name, sub, lp, OpNote, '',subsidyP,SubsidyType); 
        }

        private void construct(String di, String es, String eii, String des, Decimal qty, String s, String c, 
                            Date sd, Date ed, 
                            Time sdt, Time edt,                             
                            Decimal qtyl, String place, Decimal dp,
                            Decimal priceskulow, Decimal priceskuupper,
                            Decimal dealskulow, Decimal dealskuupper,
                            Decimal offerskulow, Decimal offerskuupper,
                            Decimal sp, String Name, Decimal sub, Decimal lp,String OpNote, String dealSite,Decimal subsidyP,String SubsidyType){
            this.dId = di;
            this.eBay_Seller = es;
            this.eBay_Item_ID = eii;
            this.Description = des;
            this.Quantity = qty;
            this.Status = s;
            this.Comment = c;
            this.Deal_Start_Date = sd;
            this.Deal_End_Date = ed;
            this.Deal_Start_Time = sdt;
            this.Deal_End_Time = edt;
            this.QuantityLimit = qtyl;
            this.PagePlacement = place;
            this.Deal_Price = dp;
            this.Optional_Notes = OpNote;
            this.List_Price_MSKU_Lower = priceskulow;
            this.List_Price_MSKU_Upper = priceskuupper;
            this.Sellers_Deal_Price_MSKU_Lower = dealskulow;
            this.Sellers_Deal_Price_MSKU_Upper = dealskuupper;
            this.Sellers_Offer_Price_MSKU_Lower = offerskulow;
            this.Sellers_Offer_Price_MSKU_Upper = offerskuupper;
            this.Seller_Price = sp;
            this.DealName = Name;
            this.Subsidy = sub;
            this.SubsidyP = subsidyP;
            this.SubsidyType = SubsidyType;
            this.ListPrice = lp;
            this.DealSite = dealSite;
            this.reason_amendment = ''; //MN-08092021-US-0010019
            this.original_dca = ''; //MN-08092021-US-0010019
            
        }
        
        public String getDisplayDealStartTime() {
            return getDisplayTime(Deal_Start_Time);
        }
        
        public String getDisplayDealEndTime() {
            return getDisplayTime(Deal_End_Time);
        }

        private String getDisplayTime(Time t){
            if(t == null) return '';
            return String.valueOf(Datetime.newInstance(2018, 01, 01, t.hour(), t.minute(), t.second()).format('HH:mm'));
        }
        
        // US-0010648 12/01/2022 Sovantheany Dim
        public String getDeal_Start_Date_Time_PST() {
            Datetime dealStartDateTime = ApexUtil.gmtDateToDTZone(this.Deal_Start_Date, this.Deal_Start_Time, 'PST');
            return dealStartDateTime == null ? '' : dealStartDateTime.format('MM/dd/yy HH:mm z', 'PST');     
        }
        // US-0010648 12/01/2022 Sovantheany Dim
        public String getDeal_End_Date_Time_PST() {
            Datetime dealEndDateTime = ApexUtil.gmtDateToDTZone(this.Deal_End_Date, this.Deal_End_Time, 'PST');
            return dealEndDateTime == null ? '' : dealEndDateTime.format('MM/dd/yy HH:mm z', 'PST');                                        
        }

        // US-0008816 08.02.2021 Acmatac SEING
        // US-0010648 31/01/2022 Sovantheany Dim
        public String getDeal_Start_Date_Time_EST() {
            Datetime dealStartDateTime = ApexUtil.gmtDateToDTZone(this.Deal_Start_Date, this.Deal_Start_Time, 'PST');
            return dealStartDateTime == null ? '' : dealStartDateTime.format('MM/dd/yy HH:mm z', 'EST');     
        }
        // US-0008816 08.02.2021 Acmatac SEING
        // US-0010648 31/01/2022 Sovantheany Dim
        public String getDeal_End_Date_Time_EST() {
            Datetime dealEndDateTime = ApexUtil.gmtDateToDTZone(this.Deal_End_Date, this.Deal_End_Time, 'PST');
            return dealEndDateTime == null ? '' : dealEndDateTime.format('MM/dd/yy HH:mm z', 'EST');                                
        }
    }
}