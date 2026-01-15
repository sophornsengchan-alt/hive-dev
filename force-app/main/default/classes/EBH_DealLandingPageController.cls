/*********************************************************************************************************************************
@ Class:        EBH_DealLandingPageController
@ Version:      1.0
@ Author:       Acmatac Seing (acmatac.seing@gaea-sys.com)
@ Purpose:      Controller for VF Page : EBH_ClarificationRequiredPage, EBH_InvoiceUploadLandingPage.
				EPH-7407 Landing Pages (Salesforce sites) for Invoice Upload and Clarification Required
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.13.2019 / Acmatac Seing (acmatac.seing@gaea-sys.com) / Created the class.
@				: 29.12.2020/ Vadhanak Voun/ US-0008730 - Deals Invoicing - UK VAT ID (Update)
@				: 25.01.2021/ Vadhanak Voun/ US-0009031 - Regression BUG - Deal Invoice not be able to upload from Email
@				: 05.05.2021 / Acmatac Seing (acmatac.seing@gaea-sys.com) / US-0009490 - BUG - Button " Submit" in Deal invoice landing page is still click able
@				: 07.06.2021 / Sophal Noch / US-0009395 - {Hypercare} - [Deals] - Seller able to update to previous status
@				: 19.10.2021 / Sophal Noch / US-0010546 - [DE-Deals-Fulfillment] Fulfillment proposal email actions
@				:   05.05.2022 / Loumang SENG /US-0011260 - TECHDEBT: Reflected XSS
*********************************************************************************************************************************/

public without sharing class EBH_DealLandingPageController {
	
	private final static String DEAL_QUERY = 'SELECT EBH_DealStartDate__c, EBH_LocalDealFormat__c, EBH_ProductTitle__c, EBH_DealSiteId__c, toLabel(EBH_DealSiteId__c)SiteLabel, EBH_Status__c, Invoice_Comment_From_Seller__c, Invoice_Number__c FROM EBH_Deal__c ';

    public static final String DEAL_STATUS_VERIFY_INVOICE {get{
      return EBH_ConstantsUtility.DEAL_STATUS_VERIFY_INVOICE;  
    }set;}
    
    public static final String DEAL_STATUS_CLARIFICATION_REQUIRED {get{
       return EBH_ConstantsUtility.DEAL_STATUS_CLARIFICATION_REQUIRED; 
    }set;} 
	
	public static final String DEAL_STATUS_STATEMENT_VERIFIED {get{
		return EBH_ConstantsUtility.DEAL_STATUS_STATEMENT_VERIFIED; 
	 }set;}

	public static final String DEAL_STATUS_INV_REJECT {get{
	return EBH_ConstantsUtility.DEAL_STATUS_INV_REJECT; 
	}set;}

	public static final String DEAL_STATUS_SELLER_INVITE {get{
		return 'Seller Invite'; 
	 }set;}

	private static final String DEAL_STATUS_NEW = 'New';

	public DealWrapper dealWrap{get;set;}

	private UploadInvoice_ClarifyDeal_Setting__mdt setting;
	private Set<String> allowedSites = new Set<String>();
	private Set<String> allowedStages = new Set<String>();
	private final static String SITE_DE = '77';
	private static final String SETTING_NAME = 'EU_Deal';
	private static final String UPLOAD_INVOICE_PAGENAME = 'EBH_InvoiceUploadLandingPage';
	private static final String CLARIFICATION_REQUIRED_PAGENAME = 'EBH_ClarificationRequiredPage';
	private static final String FULFILLMENT_PROPOSAL_PAGENAME = 'FulfillmentProposalPage';

	private static final String ERR_INVALID_INTEGER = 'Invalid integer';

    
	// US-0009490, @amt updated it from PUBLIC => PRIVATE
	@testVisible
    private EBH_Deal__c sDeal  				{get; set;}
	public Boolean loadSuccess  			{get; set;}
	public String dealSite  				{get; set;}
	public String dealSiteId 				{get; set;}
	public String dealId  					{get; set;}
	public Map<String, Object> submitResult {get; set;}
	public Map<String, Object> initResult {get; set;}
	public String comment {get; set;}
	private Boolean hasInitError = false;
	public List<String> listErrorMsg {get{return listErrorMsg = (listErrorMsg != null ? listErrorMsg : new List<String>());} set;}  	

	public String invoiceNumber {get;set;} //NK:25.01.2021:US-0009031

	public String sellerPrice {get;set;}
	public String quantity {get;set;}
	public String dealDate {get;set;}
	public String cmtFromSeller {get;set;}

	public Boolean isSellerPriceBlank {get{return isSellerPriceBlank = (isSellerPriceBlank != null ? isSellerPriceBlank : false);} set;}
	public Boolean isQuantityBlank{get{return isQuantityBlank = (isQuantityBlank != null ? isQuantityBlank : false);} set;}
	public Boolean isDealDateBlank {get{return isDealDateBlank = (isDealDateBlank != null ? isDealDateBlank : false);} set;}

    public Attachment attachment {
        get {
            if (attachment == null)
                attachment = new Attachment();
            return attachment;
        }
        set;
    }
    
    /*
		AC2) We will have localized versions for these landing pages, the country will be determinded by the DEALS SITE from Deal Object
    */
	//public EBH_DealLandingPageController(ApexPages.StandardController controller){
	public EBH_DealLandingPageController(){

        try{
			
			 initSetting(); // 07.06.2021 / Sophal Noch / US-0009395 use custom metadata to store avaiable site and status for uploading invoice and comment on deal
			 
			 String url = ApexPages.currentPage().getUrl();
			 Boolean isInvoiceUploadPage = url.contains(UPLOAD_INVOICE_PAGENAME) ? true : false;
			 Boolean isClarificationRequiredPage = url.contains(CLARIFICATION_REQUIRED_PAGENAME) ? true : false;
			 Boolean isFulFillmentProposalPage = url.contains(FULFILLMENT_PROPOSAL_PAGENAME) ? true : false;

			 //dealId = ApexPages.currentPage().getParameters().get('id');
			 //dealId = String.escapeSingleQuotes(dealId);
			 dealId = String.escapeSingleQuotes(String.isBlank(ApexPages.currentPage().getParameters().get('id')) ? '': ApexPages.currentPage().getParameters().get('id')); //LA-05-05-2022:US-0011260
			 dealId = EncodingUtil.urlEncode(dealId, 'UTF-8');		 
             sDeal = getDeal();
			 dealWrap = new DealWrapper(sDeal);
			 //dealSite = String.valueOf(sDeal.get('SiteLabel'));
			 dealSite = ApexUtil.MAP_CODE_LANG.containsKey(sDeal.EBH_DealSiteId__c)?ApexUtil.MAP_CODE_LANG.get(sDeal.EBH_DealSiteId__c):'en';
			 dealSiteId = sDeal.EBH_DealSiteId__c;

			 // 07.06.2021 / Sophal Noch / US-0009395 if deal site or status is incorrect, throw error.
			 if(
				 (!allowedSites.contains(sDeal.EBH_DealSiteId__c) || !allowedStages.contains(sDeal.EBH_Status__c))
				 || (isInvoiceUploadPage && !isUploadInvoiceAllowed())
				 // 18.10.2021 / Sophal Noch / US-0010546 :
				 || (isClarificationRequiredPage && (sDeal.EBH_Status__c == DEAL_STATUS_CLARIFICATION_REQUIRED || sDeal.EBH_Status__c == DEAL_STATUS_SELLER_INVITE))
				 || (isFulFillmentProposalPage && sDeal.EBH_Status__c <> DEAL_STATUS_SELLER_INVITE)
			 ){
				 dealWrap = null; loadSuccess = false; hasInitError = true; return;
			 }
			 
			 loadSuccess = true;
			 invoiceNumber = sDeal.Invoice_Number__c;
            
        }catch(Exception e) {
			//System.debug('Error : ' + e.getMessage());      
        }
	}

	/*
		Test class purpose. Acmatac SEING, May-06-2021, US-0009490
    */
	// @testVisible
	// private EBH_DealLandingPageController(Id dId){
    //     try{
	// 		 dealId = EncodingUtil.urlEncode(dId, 'UTF-8');		 
    //          sDeal = getDeal();
	// 		 dealWrap = new DealWrapper(sDeal);
	// 		 //dealSite = String.valueOf(sDeal.get('SiteLabel'));
	// 		 dealSite = ApexUtil.MAP_CODE_LANG.containsKey(sDeal.EBH_DealSiteId__c)?ApexUtil.MAP_CODE_LANG.get(sDeal.EBH_DealSiteId__c):'en';
	// 		 dealSiteId = sDeal.EBH_DealSiteId__c;
    //          loadSuccess = true;
	// 		 invoiceNumber = sDeal.Invoice_Number__c;
            
    //     }catch(Exception e) {
	// 		//System.debug('Error : ' + e.getMessage());      
    //     }
	// }
	
	/*
		- Once the user clicked on button " then this will change the Status of the related Deals Record to "CLARIFICATION REQUIRED" 
		- and will write the value from comment box to field "INVOICE COMMENT FROM SELLER" (EPH-7409)
	*/

	// @RemoteAction
	// public static Map<String, Object> updateDealComment(String dealId, String comment){
	public void updateDealComment(){
		try{

			sDeal = null; // 07.06.2021 / Sophal Noch / US-0009395 so getDeal() method get up-to-date deal record values from database
			EBH_Deal__c deal = getDeal();

			// 07.06.2021 / Sophal Noch / US-0009395 if deal site or status is incorrect, throw error
			// 18.10.2021 / Sophal Noch / US-0010546 prevent Status 'Seller Invite' to be updated.
			if(sDeal.EBH_Status__c == DEAL_STATUS_CLARIFICATION_REQUIRED || sDeal.EBH_Status__c == DEAL_STATUS_SELLER_INVITE || !allowedSites.contains(sDeal.EBH_DealSiteId__c) || !allowedStages.contains(sDeal.EBH_Status__c)){submitResult = new Map<String, Object>{'isSuccess' => false, 'msg'=> System.Label.UploadInvoice_ClarifyDeal_Link_Not_Found}; return;}

			deal.Invoice_Comment_From_Seller__c = comment;
			deal.EBH_Status__c = DEAL_STATUS_CLARIFICATION_REQUIRED;
			EBH_DealTriggerHandler.UPDATE_STATUS_SYS = true;
			update deal;
			dealWrap.status = DEAL_STATUS_CLARIFICATION_REQUIRED;
			submitResult = new Map<String, Object>{'isSuccess' => true, 'msg'=> System.Label.Upload_Invoice_Success};
			
		}catch(Exception ex){
			submitResult = new Map<String, Object>{'isSuccess' => false, 'msg'=> ex.getMessage()};
		}
	}
    
	/*
		- There will be a verification rule: If invoice number not NULL and document uploaded then allow to submit else show error message
		- Once the user uploaded the document and Invoice Number and clicked on submit this will change the status of the related Deals record to "VERIFY INVOICE"
		- Once the user uploaded the document this will be attached to to deals record
		Changes: 03/03/2020 : US-0007146 : Deals - Invoice - additional condition to block seller to upload invoice again
							  AC) For Deal Invoice process when seller (guest user) wants to upload the invoice when not in status Statement Verified (Trigger Email to Seller) 
							  we will block (i.e. we not only allow upload once but also only allow upload in status Statement Verified (Trigger Email to Seller)
	*/
	public void updateDealUpload(){
		try{

			sDeal = null;  // 07.06.2021 / Sophal Noch / US-0009395 so getDeal() method get up-to-date deal record values from database
			sDeal = getDeal();

			// 07.06.2021 / Sophal Noch / US-0009395 if deal site or status is incorrect, throw error.
			if(!allowedSites.contains(sDeal.EBH_DealSiteId__c) || !allowedStages.contains(sDeal.EBH_Status__c)){submitResult = new Map<String, Object>{'isSuccess' => false, 'msg'=> System.Label.UploadInvoice_ClarifyDeal_Link_Not_Found}; return;}

			if (isUploadInvoiceAllowed()) { // allow seller upload invoice only deal status = Statement Verified
				sDeal.EBH_Status__c = DEAL_STATUS_VERIFY_INVOICE;
				update sDeal;
				
				//EPH-7579, Attach Invoice to New Object DEAL INVOICE and not to Notes and Attachements
				EBH_DealInvoice__c dealInv = new EBH_DealInvoice__c();
				dealInv.Name = invoiceNumber;//sDeal.Invoice_Number__c;
				dealInv.EBH_Deal__c = sDeal.Id;
				dealInv.Invoice_Number__c = invoiceNumber;//sDeal.Invoice_Number__c;
				dealInv.Statement_Accepted_by_Seller__c = System.now();
				insert dealInv;
				
				attachment.OwnerId = UserInfo.getUserId();
				attachment.ParentId = dealInv.Id;
				attachment.IsPrivate = false;
				insert attachment;

				//refresh file (state view limit issue)
				attachment = new attachment();
				dealWrap.status = DEAL_STATUS_VERIFY_INVOICE;
                submitResult = new Map<String, Object>{'isSuccess' => true, 'msg'=> System.Label.Upload_Invoice_Success};
			}
			else {
				submitResult = new Map<String, Object>{'isSuccess' => false, 'msg'=> System.Label.Upload_Invoice_Fail_Wrong_Stage};
			}
			
		}
		catch(Exception ex){
			submitResult = new Map<String, Object>{'isSuccess' => false, 'msg'=> ex.getMessage()};
		}
	}

	/*****************************************************************************************************************************
	@ Method:       proposeDeal
	@ Version:      1.0
	@ Author:       Sophal Noch
	@ Purpose:      US-0010546 - [DE-Deals-Fulfillment] Fulfillment proposal email actions
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 18.10.2021 / Sophal Noch  / Created the  Method.
	*****************************************************************************************************************************/
	public void proposeDeal(){

		try{

			isSellerPriceBlank = false;
			isQuantityBlank = false;
			isDealDateBlank = false;
			listErrorMsg.clear();

			sDeal = null; // null the variable so method getDeal() will query latest state of the deal record
			getDeal();

			if(sDeal.EBH_Status__c != DEAL_STATUS_SELLER_INVITE || sDeal.EBH_DealSiteId__c != SITE_DE){submitResult = new Map<String, Object>{'isSuccess' => false, 'msg'=> System.Label.UploadInvoice_ClarifyDeal_Link_Not_Found}; return;}

			if(String.isBlank(sellerPrice)){isSellerPriceBlank = true; listErrorMsg.add(System.Label.Error_Seller_Price_Is_Required);}
			if(String.isBlank(quantity)){isQuantityBlank = true; listErrorMsg.add(System.Label.Error_Quantity_Is_Required);}
			if(String.isBlank(dealDate)){isDealDateBlank = true; listErrorMsg.add(System.Label.Error_DealDate_Is_Required);}

			if(isSellerPriceBlank || isQuantityBlank || isDealDateBlank){submitResult = new Map<String, Object>{'isSuccess' => false, 'msg'=> ''}; return;}

			Date dealDateEarliestPossible = Date.valueOf(dealDate);
			Date todayDate = Date.today();

			if(dealDateEarliestPossible < todayDate){isDealDateBlank = true; submitResult = new Map<String, Object>{'isSuccess' => false, 'msg'=> System.Label.Error_DealDate_Not_CurrentOrFuture}; return;}

			sDeal.EBH_SellerPrice__c = Decimal.valueOf(sellerPrice);
			sDeal.EBH_DealPrice__c = Decimal.valueOf(sellerPrice);
			sDeal.EBH_Quantity__c = Integer.valueOf(quantity);
			sDeal.EBH_Dealdateearliestpossible__c = dealDateEarliestPossible;
			sDeal.EBH_CommentfromSeller__c = cmtFromSeller;
			sDeal.EBH_Status__c = DEAL_STATUS_NEW;

			update sDeal;
			dealWrap.status = DEAL_STATUS_NEW;
			submitResult = new Map<String, Object>{'isSuccess' => true, 'msg'=> System.Label.Success_Send_Deal_Proposal};

		}catch(Exception ex){submitResult = new Map<String, Object>{'isSuccess' => false, 'msg'=> ex.getMessage().replace(ERR_INVALID_INTEGER, System.Label.Error_Invalid_Integer)};}
		
	}



	public void handleDealAgree() {
		if(String.isNotBlank(dealId)){
			EBH_Deal__c sDeal = getDeal();
			sDeal.Statement_Accepted_by_Seller__c = System.now();
	        sDeal.Statement_Accepted_From_by_Seller__c = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
            update sDeal;
		}

		 // 10.06.2021 / Sophal Noch / US-0009395 use here so custom label can be translated.
		if(hasInitError) { initResult = new Map<String, Object>{'isSuccess' => false, 'msg'=> System.Label.UploadInvoice_ClarifyDeal_Link_Not_Found}; return; }
		
	}


	/*****************************************************************************************************************************
	@ Method:        getDeal
	@ Version:       1.0
	@ Author:          
	@ Purpose:      US-0008590 - Improve Deal Invoice Upload Process
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 06/11/2020 / Vadhanak Voun  / Created the  Method.
	*****************************************************************************************************************************/
	private EBH_Deal__c getDeal()
	{
		if(sDeal==null)
		{
			String sWehre = ApexUtil.validSFId(dealId)? ' Where Id =:dealId':' Where(Unique_Id_Ext__c <> NULL AND Unique_Id_Ext__c =:dealId)';
			sDeal = Database.query(DEAL_QUERY+sWehre);
		}

		return sDeal ;
	}

	// US-0009490 - BUG - Button " Submit" in Deal invoice landing page is still click able
	public class DealWrapper {
		public String status{get;set;}
		public Date startDate{get;set;}
		public String localFormate{get;set;}
		public String productTitle{get;set;}

		public DealWrapper(){}

		public DealWrapper(EBH_Deal__c oD){
			this.status = oD.EBH_Status__c;
			this.startDate = oD.EBH_DealStartDate__c;
			this.localFormate = oD.EBH_LocalDealFormat__c;
			this.productTitle = oD.EBH_ProductTitle__c;
		}
	}
	// END OF US-0009490


	private void initSetting(){
		 // 07.06.2021 / Sophal Noch / US-0009395 query custom metadata that has deal available sites and statuses
		setting = setting == null ? [SELECT Allowed_Sites__c,Allowed_Stages__c From UploadInvoice_ClarifyDeal_Setting__mdt where DeveloperName =: SETTING_NAME LIMIT 1] : setting;
		if(allowedSites.isEmpty()) allowedSites.addAll(setting.Allowed_Sites__c.split(','));
		if(allowedStages.isEmpty()) allowedStages.addAll(setting.Allowed_Stages__c.split(','));

	}

	private Boolean isUploadInvoiceAllowed(){
		return sDeal.EBH_Status__c == DEAL_STATUS_STATEMENT_VERIFIED || sDeal.EBH_Status__c == DEAL_STATUS_INV_REJECT;
	}
}