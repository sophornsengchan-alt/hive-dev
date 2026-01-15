/*********************************************************************************************************************************
@ Class:          DealInvoiceVerificationController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        EPH-7617 Create Visual Force Page - Deals invoice
@				 Controller for Aura: DealInvoiceVerification
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.06.2019 / Vadhanak Voun / Created the class.
@				  20.05.2021 / Mony Nou / US-0009471 - Invoice Number & Invoice Date on Deals & Deal Invoice Objects
@				  27.07.2023 / SRONG TIN / US-0013820 - DE Deal Email template footer display with incorrect [Years]
@				  10.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
*********************************************************************************************************************************/
public without sharing class DealInvoiceVerificationController {
    

	public final static String DEAL_STATUS_READY_PAYMENT = 'Ready for Payment';
	public final static String DEAL_INVOICE_STATUS_READY_PAYMENT = 'Ready for Payment';
	public final static String DEAL_INVOICE_STATUS_REJECTED  = 'Invoice Rejected';
	public final static String DEAL_STATUS_INV_REJECT = 'Invoice Rejected (Email resend to Seller)';
	public final static String ADMIN_PROFILE_ID = ApexUtil.ADMIN_PROFILE_ID; //'00e6A000000HNzwQAG';
	public final static String PERMISSION_SET_PROMO = 'Promotions_User'; 
	//27.07.2023 / SRONG TIN / US-0013820 added field: Current_Year__c
	public final static String SOQL_DEAL = 'Select EBH_MarketingTitle__c,EBH_CommentfromeBaySourcer__c,Subsidy_Planned_Gross__c,EBH_SellerPrice__c,CompanyName__c,EBH_BusinessName__r.Name, EBH_BusinessName__r.ParentId,EBH_BusinessName__r.EBH_ParentAccount__c,EBH_BusinessName__r.EBH_VATNumber__c,EBH_BusinessName__r.Parent.EBH_BillingStreet__c,EBH_BusinessName__r.Parent.EBH_BillingCountry__c,EBH_BusinessName__r.Parent.EBH_BillingPostalCode__c,EBH_BusinessName__r.Parent.EBH_BillingCity__c,EBH_MaximumPurchases__c, EBH_Quantity__c,EBH_RRPWASPrice__c,EBH_DealPrice__c,EBH_EAN__c,Additional_Terms_Override_Of_Agreement__c, Shipping_Rate_Funding__c,EBH_BusinessName__c, EBH_DealStartTime__c, EBH_DealEndTime__c, EBH_SpotlightCategory__r.Active__c,EBH_SpotlightCategory__c,EBH_SpotlightCategory__r.Name,NumberOfDaysSinceDealEnd__c,EBH_Status__c,Id,Owner.Email,EBH_SellerEmail__c,VAT_N__c,Subsidy_Final_Net__c,EBH_Subsidy__c,EBH_Payout_SI_calc__c,EBH_LocalDealFormat__c,EBH_eBayItemID__c,EBH_ProductTitle__c,EBH_DealSiteId__c,EBH_DealStartDate__c,EBH_DealEndDate__c,EBH_StartDateMonthYear__c,EBH_Vertical__c, Subsidy_Running__c, EBH_SubsidyForecast__c, EBH_SubsidyFinal__c, EBH_SubsidyMax__c, Current_Year__c From EBH_Deal__c ';
	public final static String SOQL_BOB_USER_BY_ID  = 'Select isActive,Id,Name,Email From User Where Id IN:setUserId'; //NK:10/06/2024:US-0015255 - BoB_Country__c
	public final static String SOQLEMAIL_TEMPLATES = 'Select Body,Id,DeveloperName,Subject,HtmlValue from emailTemplate ';
	public final static String EMAILTEMPLATE_UK_DEAL_INVOICE_REJECT = 'UK_Deal_Invoice_Reject';
	public final static String EMAILTEMPLATE_DE_DEAL_INVOICE_REJECT = 'DE_Deal_Invoice_Reject';
	public final static String EMAILTEMPLATE_FR_DEAL_INVOICE_REJECT = 'FR_Deal_Invoice_Reject';
	public final static String EMAILTEMPLATE_IT_DEAL_INVOICE_REJECT = 'IT_Deal_Invoice_Reject';
	public final static String EMAILTEMPLATE_ES_DEAL_INVOICE_REJECT = 'ES_Deal_Invoice_Reject';
	public final static String SITE_DE = '77';

     /*****************************************************************************************************************************
	@ Method:   apexInit
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  describe field labels to the component
	------------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 21.06.2019 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexInit(String parentId)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
    	Map<String,String> mapLabel = new Map<String,String>();
    	
    	Map<String, Schema.SObjectField> fieldsMap = EBH_DealInvoice__c.getSObjectType().getDescribe().fields.getMap();

		for(SObjectField sf : fieldsMap.values()){
			Schema.DescribeFieldResult f = sf.getDescribe();
			mapLabel.put(f.getName(),f.getLabel());
			 
		}
		String soqlDealInvoice = 'Select '+String.join(new List<String>(mapLabel.keySet()),',') +' From EBH_DealInvoice__c Where Id=:parentId';
		EBH_DealInvoice__c dealInvoice = Database.query(soqlDealInvoice);
		
    	mapResult.put('mapLabel',mapLabel);
    	mapResult.put('dealInvoice',dealInvoice);
    	
    	return mapResult;
    }
    
    /*****************************************************************************************************************************
	@ Method:   apexReadyPayment
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-7617: 
	@				AC5) When User clicks on button "Ready for Payment" this will move the related Deal Object record to status "READY FOR PAYMENT"
	------------------------------------------------------------------------------------------------------------------------------
	@ Param : parentId: parent deal Id
	@		: recordId: current deal invoice id  
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 21.06.2019 / Vadhanak Voun / Created the  Method.			
	@ 				  20.05.2021 / Mony Nou / US-0009471 - AC4) When the Deal Invoice Status is updated to Ready for Payment then update the parent Deal object fields Invoice_Number__c and Invoice_Date__c
														 - AC5) Update the previous Deal Invoice Status to "Invoice Rejected" if it is "Ready for Payment", 
																When a new Deal Invoice Status is updated to Ready For Payment for a particular Deal.	  
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexReadyPayment(String parentId,String recordId)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
    	try
    	{
			// MN-20052021-US-0009471
			List<EBH_DealInvoice__c> lstDealInvoice = new List<EBH_DealInvoice__c>();
			EBH_Deal__c deal = new EBH_Deal__c(Id=parentId,EBH_Status__c= DEAL_STATUS_READY_PAYMENT);
			
			for (EBH_DealInvoice__c di : [SELECT Invoice_Date__c, Invoice_Number__c FROM EBH_DealInvoice__c WHERE EBH_Deal__c=:parentId AND Id=:recordId]) {
			
				// 1- Update Deal fields with the current Deal Invoice's infor
				deal.Invoice_Date__c = di.Invoice_Date__c;
				deal.Invoice_Number__c = di.Invoice_Number__c;
				
				// 2- Update additional information for the current Deal Invoice
				lstDealInvoice.add(new EBH_DealInvoice__c(Id=di.Id, Invoice_Verified__c=true, Deal_Invoice_Status__c=DEAL_INVOICE_STATUS_READY_PAYMENT));

			}
			
			update deal;
			update lstDealInvoice;

			//---- MN-20052021-US-0009471

			/* MN-20052021 - Old logic
    		EBH_Deal__c deal = new EBH_Deal__c(Id=parentId,EBH_Status__c= EBH_ConstantsUtility.DEAL_STATUS_READY_PAYMENT);
    		update deal;
    		
    		EBH_DealInvoice__c div = new EBH_DealInvoice__c(Id=recordId,Invoice_Verified__c=true,Deal_Invoice_Status__c=EBH_ConstantsUtility.DEAL_INVOICE_STATUS_READY_PAYMENT);
    		update div;
    		*/
    		mapResult.put('status','ok'); 
    	}catch(Exception ex)
    	{
    		System.debug(ex);mapResult.put('status','ko');mapResult.put('error',ex.getMessage());
    	}
    	
    	return mapResult;
    }
    
    /*****************************************************************************************************************************
	@ Method:   apexReject
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-7617: 
	@				AC6) When User clicks on button "Reject Invoice" this will move the related Deal Object record back to status  to status "Statement Verified (Trigger Email to Seller)"
	------------------------------------------------------------------------------------------------------------------------------
	@ Param : parentId: parent deal Id
			: comments: rejection comments
	@		: recordId: current deal invoice id  
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 21.06.2019 / Vadhanak Voun / Created the  Method.
	@				: 19.08.2019/ Vadhanak Voun/ EPH-7940 Deals Invoice - Rejection VAT Invoice email w/ Reason
	@				: 24.10.2019/Sovantheany Dim/US-0009403 Deals Invoice VAT - Rejection Email template localization for UK, FR, IT & ES
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexReject(String parentId,String comments,String recordId)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
    	
    	try
    	{
    		Boolean isAdmin = UserInfo.getProfileId().equals(ADMIN_PROFILE_ID);
    		Boolean isPromoUser = ApexUtil.checkPermissionSet(new Set<String>{PERMISSION_SET_PROMO});
    		if(isAdmin || isPromoUser)
    		{
    			//EBH_Deal__c deal = new EBH_Deal__c(Id=parentId,EBH_Status__c= EBH_ConstantsUtility.DEAL_STATUS_STATEMENT_VERIFIED);
    			
    			EBH_Deal__c deal = Database.query(SOQL_DEAL +' Where Id=:parentId' );
    			deal.EBH_Status__c= DEAL_STATUS_INV_REJECT;
	    		update deal;
	    		
	    		EBH_DealInvoice__c div = new EBH_DealInvoice__c(Id=recordId,Reject_Invoice_Comment__c=comments,Deal_Invoice_Status__c=DEAL_INVOICE_STATUS_REJECTED,Rejected_DateTime__c=System.now());
	    		update div; 
	    		
	    		 Set<String> setUserId = new Set<String>{UserInfo.getUserId()};
	        	User currentUser = Database.query(SOQL_BOB_USER_BY_ID);
	        	
	        	Map<String,String> map_code_to_EmailTemplate  = new Map<String,String>{
	        		'3'=> EMAILTEMPLATE_UK_DEAL_INVOICE_REJECT,
	        		'77'=> EMAILTEMPLATE_DE_DEAL_INVOICE_REJECT,
	        		'71'=> EMAILTEMPLATE_FR_DEAL_INVOICE_REJECT,
	        		'101'=> EMAILTEMPLATE_IT_DEAL_INVOICE_REJECT,
	        		'186'=> EMAILTEMPLATE_ES_DEAL_INVOICE_REJECT};
	        	
	        	if(!map_code_to_EmailTemplate.containskey(deal.EBH_DealSiteId__c)){
	    			mapResult.put('status','ko'); 
    				mapResult.put('error','No Email Template found!\nPlease check deal site.');
	    		}else{
	    			String rejectTemplate = map_code_to_EmailTemplate.get(deal.EBH_DealSiteId__c);
	    			List<EmailTemplate> emailTemplates = Database.query(SOQLEMAIL_TEMPLATES+' Where DeveloperName =:rejectTemplate');
	    			String htmlBody = mergeBody(deal,emailTemplates[0].HtmlValue,comments);
		    		String subject = mergeSubject(deal,emailTemplates[0].Subject);
		    		
		    		//SRONG:18-06-2021: US-0009575 
                    OrgWideEmailAddress orgWide = ApexUtil.getOWDbyAddress(System.label.OWA_EBAY_WOW_DEAL);
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[]{deal.EBH_SellerEmail__c});
                    mail.setCCAddresses(new String[]{deal.Owner.Email}); 
                    //mail.setSenderDisplayName(currentUser.Name);
                    mail.setSubject(subject);
                    mail.setBccSender(false);
                    mail.setUseSignature(false); 
                    mail.setHtmlBody(htmlBody);
                    //Srong:18-06-2021: US-0009575 
                    if (orgWide != null && deal.EBH_DealSiteId__c==SITE_DE){
                        mail.setOrgWideEmailAddressId(orgWide.Id);
                    }else {
                        mail.setSenderDisplayName(currentUser.Name);
                    }
                    if(!test.isrunningtest()) Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {mail});
                    mapResult.put('status','ok');
	    		}
    		}else
    		{
    			mapResult.put('status','ko'); 
    			mapResult.put('error','Not Promotion User!\nPlease check permission set assignment.');
    		}
    		
    	}catch(Exception ex)
    	{
    		System.debug(ex);mapResult.put('status','ko');mapResult.put('error',ex.getMessage());
    	}
    	
    	return mapResult;
    }
    private static String mergeSubject(EBH_Deal__c deal,String subject)
    {
    	return subject.replace('{!DealStartDate}',deal.EBH_DealStartDate__c==null?'':deal.EBH_DealStartDate__c.format());
    }
    
    private static String mergeBody(EBH_Deal__c deal,String htmlBody,String rejectComment)
    {
    	return htmlBody.replace('{!DealStartDate}',deal.EBH_DealStartDate__c==null?'':deal.EBH_DealStartDate__c.format())
    	.replace('{!DealEndDate}',deal.EBH_DealEndDate__c==null?'':deal.EBH_DealEndDate__c.format())
    	.replace('{!RejectionComment}',rejectComment==null?'':rejectComment)
    	.replace('{!ProductTitle}',deal.EBH_ProductTitle__c==null?'':deal.EBH_ProductTitle__c)
    	.replace('{!eBayItemId}',deal.EBH_eBayItemID__c==null?'':deal.EBH_eBayItemID__c+'')
    	.replace('{!LocalDealFormat}',deal.EBH_LocalDealFormat__c==null?'':deal.EBH_LocalDealFormat__c+'')
    	.replace('{!PayoutSICalc}',deal.EBH_Payout_SI_calc__c==null?'':deal.EBH_Payout_SI_calc__c+'')
    	.replace('{!Subsidy}',deal.EBH_Subsidy__c==null?'':deal.EBH_Subsidy__c +' EUR')
    	.replace('{!SubsidyFinalNet}',deal.Subsidy_Final_Net__c==null?'':deal.Subsidy_Final_Net__c+' EUR')
    	.replace('{!VAT_N}',deal.VAT_N__c==null?'':deal.VAT_N__c+' %')
    	.replace('{!SubsidyFinal}',deal.EBH_SubsidyFinal__c==null?'':deal.EBH_SubsidyFinal__c+' EUR')
    	.replace('{!UrlInvoiceUpload}',ApexUtil.getSiteUrl('Deal_Acceptance')+'/EBH_InvoiceUploadLandingPage?id='+deal.Id)
    	.replace('{!UrlClarification}',ApexUtil.getSiteUrl('Deal_Acceptance')+'/EBH_ClarificationRequiredPage?id='+deal.Id)
		.replace('{!CurrentYear}',deal.Current_Year__c+'') //27.07.2023 / SRONG TIN / US-0013820
    	;
    }
}