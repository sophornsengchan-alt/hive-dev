/*********************************************************************************************************************************
@ Class:          EBH_TrackingResponseController
@ Version:        1.0
@ Author:         
@ Purpose:        Controller Class for EBH_TrackingResponse site page
                  [EBH] (EPH-4171) - Mass Acceptance of Deals with/without Subsidy
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.11.2017 /  / Created the class.
@               : 16.11.2020 / vadhanak voun/ US-0008635 - Hypercare - Deals - Seller can "agree" to contract even when contract is executed
@               : 24.05.2020 / vadhanak voun / US-0009366 - [Export Reports] - Manage PII access within Hive in a SOX compliant manner
@				: 31.08.2021 / Mony Nou / US-0009948 - Replace Email field with a Contact lookup field on Coupon Seller object and use it in communication to sellers.
@				: 18.10.2021 / Sophal Noch / US-0010546 - [DE-Deals-Fulfillment] Fulfillment proposal email actions.
@				: 12.05.2022 / Mony Nou / US-0011663 - Seller Coupon Acceptance and Rejection Landing Page
@               : 22.11.2022 / Sovantheany Dim / US-0012957 - Prevent FVF Contract Confirmation Email Sending Out mutiple times
@               : 26.04.2023 / Bora Chhorn / US-0013524 - Block sellers to sign FVF contract
@ 				: 28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
@ 				: 05.12.2023 / Loumang SENG / US-0014231 - Retire/Remove any custom code for Growth Portal functionality
@               : 02.12.2025 / Sovantheany Dim / US-0033791 - eBay Live: UAT Feedback
*********************************************************************************************************************************/
public without sharing class EBH_TrackingResponseController {
  
    public String reUrl {get;set;}
    public String language {get;set;}
    public final static String CONRACT_COUPON_URL_TYPE = 'cscontract';
    public final static String CONRACT_FVF_URL_TYPE = 'fvfcontract';
    public final static String CONRACT_FVF_PARAM_FVFID = 'fvfid';
    public final static String CONRACT_DEAL_URL_TYPE = 'acceptdeal';
    public final static String CONRACT_URL_TYPE = 'contract';
    public final static String CONRACT_TICKET_URL_TYPE_PII = 'pii';
    public final static String RESPONSE_TYPE  = 'restype';
    public final static String REDIRECT_URL  = 'reURL=www.ebay.de';
    public final static String RT_REFURB_NAME = 'Refurbished';
    public final static String RT_TERMS_NAME = 'TermsConditions';
    public final static String CONTRACT_VOIDEDSTATUS = 'Voided';

    private final static String STATUS_AGREE = 'Deal Agreed'; 
    private final static String STATUS_PLANNED = 'Planned'; 
    private final static String STATUS_SELLERINVITE = 'Seller Invite';
    private final static String SITE_DE = '77';
    private final static Map<String,Set<String>> MAP_DEAL_SITE_TO_AGREEABLE_STATUS = new Map<String,Set<String>>{
        SITE_DE => new Set<String>{STATUS_PLANNED,STATUS_SELLERINVITE}
    };

    public boolean isError {get;set;}
    public String errMsg {get;set;} // error from catch
    Map<String,String> mapLangKey = new Map<String,String>{'US'=>'en','UK'=>'en','AU'=>'en','DE'=>'de','IT'=>'it','ES'=>'es','FR'=>'fr'};   //from country code to language code
    public String langKey {get;set;}    //for page language
    public String labelErrorName {get;set;} //custom label name for translation at vf (error area)
    public String labelSuccessName {get;set;}  //for success area
    private final static String SOQL_CONTRACT = 'select Status, Business_Contact__c, Contract_Accept_Date__c, Contract_Signed_by__c, EBH_Site__c,id,RecordType.DeveloperName from Contract';
    //LA-28-09-2023: US-0013980 : Add Seller__r.EBH_RevRollup__c into query
    //private final static String SOQL_COUPON_SELLER = 'Select RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Contract_Language__c,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ; //MN-31082021-US-0009948
    private final static String SOQL_COUPON_SELLER = 'Select Seller__r.EBH_RevRollup__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ;
	private final static String CONTRACT_ACCEPTED_STATUS = 'Contract Accepted';
    private final static String CONTRACT_EXECUTED_STATUS = 'Executed'; //US-0033791
    private final static string FVF_CONTRACT_SIGNED = 'Contract Signed';//TH:US-0012957 - Prevent FVF Contract Confirmation Email Sending Out mutiple times
    private final static string FVF_CONTRACT_SENT = 'Contract Sent';//TH:US-0012957 - Prevent FVF Contract Confirmation Email Sending Out mutiple times
    
    /*****************************************************************************************************************************
    @ Method:         checkResponse
    @ Version:        1.0
    @ Author:          
    @ Purpose:        page action method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.11.2017 /   / Created the  Method.
    @				: 13.02.2019/ Vadhanak Voun/ EPH-6984 Deals - Update defined fields when re-plan a deal with new conditions
    @										   / Always update
    @				: 29.07.2019/Vadhanak Voun/ EPH-7608 Send click contract to a seller as part of FVF process
    @               : 24.05.2020 / vadhanak voun / US-0009366 - [Export Reports] - Manage PII access within Hive in a SOX compliant manner
    @				: 10/08/2021 / Sovantheany Dim / US-0009871 - [Refurb] Send Click Agreements to Contract Sellers
    *****************************************************************************************************************************/
    public Pagereference checkResponse() 
    {
        reUrl = ApexPages.currentPage().getParameters().get('reURL');
        reUrl = reUrl==null?null:String.escapeSingleQuotes(reUrl);
        
        if(reUrl <> null && !reUrl.startsWith('http')) 
        {
            reUrl='http://'+reUrl;
        }
		
        String responseType = ApexPages.currentPage().getParameters().get(RESPONSE_TYPE);
        if(CONRACT_COUPON_URL_TYPE==responseType)
        {
        	handleContractCouponSellerAggree();
        }else if(CONRACT_FVF_URL_TYPE==responseType)
        {
        	handleContractFVFAggree();
        }
        else if( CONRACT_TICKET_URL_TYPE_PII == responseType) //US-0009366
        {
            handleTicketSOS_Contract();
        }
        else if( CONRACT_URL_TYPE == responseType) //US-0009871
        {
            handleContractAgree();
        }
        else
        {	
        	//existing deal function
        	handleDealAgree();
        }

        /* MN-12052022-US-0011663
        //success message to the page base on language (AU exclusive has it own custom label)
        labelSuccessName = language=='AU'?'EBH_AUTrackingResponse':'EBH_UKTrackingResponse';
        */
        
        //MN-12052022-US-0011663
        if (String.isBlank(labelSuccessName)) labelSuccessName = language=='AU'?'EBH_AUTrackingResponse':'EBH_UKTrackingResponse';
        return null;
    }
    
    private void handleDealAgree()
    {
    	try 
        {
            String dealId = ApexPages.currentPage().getParameters().get('id');
            dealId =  dealId==null?null:String.escapeSingleQuotes(dealId);
            if(String.isBlank(dealId)) 
            {
                isError = true; labelErrorName = 'Err_Invalid_Deal'; return;
            }
            //LA:05-12-2023-US-0014231: remove EBH_BusinessName__r.EBH_GBCulture__c from query
            EBH_Deal__c[]  deals = [Select EBH_DealSiteId__c,EBH_Status__c, Id,EBH_SellerAccepted__c, EBH_SellerAcceptedFrom__c from EBH_Deal__c Where Id=:dealId];
            //if(!deals.isEmpty() && deals[0].EBH_SellerAccepted__c == null) {
            if(!deals.isEmpty()) 
            { //NK:13/02/2019: override for: EPH-6984
                //language = deals[0].EBH_BusinessName__r.EBH_GBCulture__c;
                //TH: 24/12/2019 override for : US-0006971 : because no "AU" in field EBH_GBCulture__c
                language = EBH_ConstantsUtility.MAP_CODE_TO_COUNTRY.get(deals[0].EBH_DealSiteId__c);
                language = (language==null|| language=='UK')?'en-GB':language; 
                langKey = mapLangKey.containsKey(language) ? mapLangKey.get(language): mapLangKey.get('US');

                // 18.10.2021 / Sophal Noch / US-0010546 : modified condition below to check when Deal Site is 'DE' and Status is not 'Seller Invite' or 'Planned'
                // if(deals[0].EBH_Status__c <> STATUS_PLANNED){labelErrorName = 'Err_Deal_Already_Agree'; isError = true; return;}
                Set<String> setValidStatus = MAP_DEAL_SITE_TO_AGREEABLE_STATUS.containsKey(deals[0].EBH_DealSiteId__c) ? MAP_DEAL_SITE_TO_AGREEABLE_STATUS.get(deals[0].EBH_DealSiteId__c) : new Set<String>();
                if((setValidStatus.isEmpty() && deals[0].EBH_Status__c <> STATUS_PLANNED) || (!setValidStatus.isEmpty() && !setValidStatus.contains(deals[0].EBH_Status__c))){labelErrorName = 'Err_Deal_Already_Agree'; isError = true; return;}
                
                deals[0].EBH_SellerAccepted__c = System.now();
                deals[0].EBH_SellerAcceptedFrom__c = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
                deals[0].EBH_Status__c = STATUS_AGREE;
                update deals[0];
            }
        }catch(Exception ex){isError = true;EBH_ApexLogger.logError(new List<Exception> { ex }, 'EBH_TrackingResponseController','handleDealAgree'); errMsg = ex.getMessage();}
    }
    
    
    /*****************************************************************************************************************************
    @ Method:         handleContractCouponSellerAggree
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        [#EPH-7258] Coupon Seller Email Contracts
    @                 AC2) When seller receives clicks on email "I agree" (In german "Ich stimme zu) the following will happen:
	@					i) Coupon_Seller_Stage__c will be set to "CONTRACT SIGNED"
	@					ii) fields in coupon seller will be filled out
	@					
	@					Contract Accept Date Contract_Accept_Date__c
	@					Contract Accepted from (IP adress) Contract_Accepted_From__c
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.05.2019 / Vadhanak Voun /Created the Method. 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  12.05.2022 / Mony Nou /US-0011663 - Seller Coupon Acceptance and Rejection Landing Page
    *****************************************************************************************************************************/
 	private void handleContractCouponSellerAggree()
 	{
 		try
 		{
             String couponSellerId = ApexPages.currentPage().getParameters().get('csid');
             String curUId = ApexPages.currentPage().getParameters().get('uid');
	 		couponSellerId = couponSellerId==null?null:String.escapeSingleQuotes(couponSellerId);
	 		if(couponSellerId <> null)
	 		{
	 			String sWhere = ' Where Id =:couponSellerId';
	 			List<Coupon_Seller__c> listCS = Database.query(SOQL_COUPON_SELLER+sWhere);
	 			if(!listCS.isEmpty())
	 			{
                    //LA-28-09-2023-US-0013980: Replace Coupon__r.Contract_Language__c to Seller__r.EBH_RevRollup__c
	 				//NK:08/08/2019: correct lanaguage
	 				//language = listCS[0].Coupon__r.Contract_Language__c;
                    language = listCS[0].Seller__r.EBH_RevRollup__c;

                    //MN-12052022-US-0011663 
                    if (language == 'UK') labelSuccessName = 'EBH_UKSellerCouponTrackingResponse';

	 				language = (language==null|| language=='UK')?'en-GB':language;	 				
	 				langKey = mapLangKey.containsKey(language) ? mapLangKey.get(language): mapLangKey.get('US');
	 				//THeany 30/01/2020 : US-0007038 Coupon - Allow seller to accept contract after contract due date
	 				if(!listCS[0].Allow_reaccept_contract__c && listCS[0].Coupon__r.Contract_Due_Date__c < System.today()){
                        labelErrorName = language == 'AU'?'Err_Coupon_Contract_Due_Date_AU':'Err_Coupon_Contract_Due_Date'; isError = true; 
                        return;
	 				}
					
	 				listCS[0].Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED;
	 				listCS[0].Contract_Accept_Date__c = System.now();
	 				listCS[0].Contract_Accepted_From__c = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
                    CouponSellerTriggerHandler.isUpdatedSellerStage = true;
                    CouponSellerTriggerHandler.currUserId = curUId;
	 				update listCS;

                    
	 			} 
	 		}
 		}catch(Exception ex){isError = true; EBH_ApexLogger.logError(new List<Exception> { ex }, 'EBH_TrackingResponseController','handleContractCouponSellerAggree');errMsg = ex.getMessage();}
 	}
    
    /*****************************************************************************************************************************
    @ Method:         handleContractAgree
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
	@ Purpose:        US-0009871 - [Refurb] Send Click Agreements to Contract Sellers
	When Seller receives the Click Contract via eMail and Clicks "I Agree"
	System to autopopulate below fields in the Contract Seller
	Contract .Contract Accept Date = Date when Contract is accepted by Seller and
	Contract .Contract Signed By = User Name who Accepted the Contract
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  10.08.2021 / Sovantheany Dim /Created the Method. 
    @                  26.04.2022 / Acmatac SEING / US-0011627 - Refurb Contracts Void Contract message to Sellers
    @                   02.12.2025 / Sovantheany Dim / US-0033791 - eBay Live: UAT Feedback 
    *****************************************************************************************************************************/
 	private void handleContractAgree()
 	{
 		try
 		{
 			String contractId = ApexPages.currentPage().getParameters().get('id');
 			contractId = contractId == null ? null : EncodingUtil.urlDecode(String.escapeSingleQuotes(contractId),'UTF-8');
	 		if(String.isBlank(contractId)) 
            {
                isError = true; labelErrorName = 'Err_Invalid_Contract'; return;
            }else
	 		{
	 			String sWhere = ' Where Unique_Id__c =:contractId';
	 			List<Contract> listCtr =  ApexSafe.query().secCheck(false).doQuery(SOQL_CONTRACT+sWhere,new Map<String, Object> {'contractId' => contractId});
                //Database.query(SOQL_CONTRACT+sWhere);
	 			if(!listCtr.isEmpty())
	 			{
	 				language = listCtr[0].EBH_Site__c;
			 		language = (language==null|| language=='UK')?'en-GB':language;	 				
			 		langKey = mapLangKey.containsKey(language) ? mapLangKey.get(language): mapLangKey.get('US');

                    // Acmatac SEING - 26/04/2022 - US-0011627 - Refurb Contracts Void Contract message to Sellers
                    if(listCtr[0].RecordType.DeveloperName == RT_REFURB_NAME && listCtr[0].Status == CONTRACT_VOIDEDSTATUS){
                        isError = true; 
                        labelErrorName = 'ERR_VOIDED_CONTRACT_CANT_ACCEPT'; 
                        return;
                    }

	 				listCtr[0].Contract_Accept_Date__c = Date.today();
	 				listCtr[0].Contract_Signed_by__c = listCtr[0].Business_Contact__c;
	 				listCtr[0].Status = CONTRACT_ACCEPTED_STATUS;

                    // TH: US-0033791 Set the Terms and Conditions Contract
                    if(listCtr[0].RecordType.DeveloperName == RT_TERMS_NAME){
                        listCtr[0].Status = CONTRACT_EXECUTED_STATUS;
                        listCtr[0].StartDate = Date.today();
                        listCtr[0].SystemChanged__c = System.now();
                    }
	 				//update listCtr;
                    ApexSafe.dml().secCheck(false).doUpdate(listCtr,true);
	 			}
	 		}
 		}catch(Exception ex){isError = true; EBH_ApexLogger.logError(new List<Exception> { ex }, 'EBH_TrackingResponseController','handleContractAgree');errMsg = ex.getMessage();}
 	}
 	
    /*****************************************************************************************************************************
    @ Method:         handleContractFVFAggree
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:        EPH-7608 Send click contract to a seller as part of FVF process
    @                 AC4) When seller receives clicks on email "I agree" (In german "Ich stimme zu) the following will happen:
	@					When a person to whom contract was sent clicks on "I agree" the following will happen:
	@					FVF_Status = "Contract Signed"
	@					Contract Accept Date = Today
	@					Contract Accepted From = IP adress from where contract was signed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  29.07.2019 / Vadhanak Voun /Created the Method. 
    @               : 22/11/2022 / Sovantheany Dim / US-0012957 - Prevent FVF Contract Confirmation Email Sending Out mutiple times
    @               : 26/04/2023 / Bora Chhorn / US-0013524 - Block sellers to sign FVF contract
    *****************************************************************************************************************************/
 	private void handleContractFVFAggree()
 	{
 		String fvfId = ApexPages.currentPage().getParameters().get(CONRACT_FVF_PARAM_FVFID);
 		fvfId = fvfId==null?null:String.escapeSingleQuotes(fvfId);
 		if(fvfId <> null)
 		{
 			try
	 		{
               Set<String> setFvFIds = new Set<String>{fvfId};
	 			List<Final_Value_Fee_FVF__c> listFvF = Database.query(EBH_ConstantsUtility.SOQL_FVF + ' Where Id IN:setFvFIds');
	 			language = listFvF[0].Seller_Name__r.EBH_RevRollup__c;
                language = (language=='UK'?'en-GB':language); //page uses: en-GB
                langKey = mapLangKey.containsKey(language) ? mapLangKey.get(language): mapLangKey.get('US');
                //US-0007977 - FVF. Restriction
	 			if (System.today()>listFvF[0].Start_Date_w__c) {
                    labelErrorName = 'ERR_FVF_RESTRICTION'; isError = true;
                    return;
                }else{
                    //TH:22/11/22:US-0012957 - Prevent FVF Contract Confirmation Email Sending Out mutiple times
                    if(listFvF[0].Final_Value_Fee_Stage__c == FVF_CONTRACT_SENT){
                        listFvF[0].Final_Value_Fee_Stage__c = FVF_CONTRACT_SIGNED;
                        listFvF[0].Contract_Accept_Date__c = System.now();
                        listFvF[0].Contract_Accepted_From__c = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
                        update listFvF[0];
                    }
                    //BR-26-04-2023-US-0013524
                    else {
                        isError = true;
                        labelErrorName = 'CONTRACT_CANNOT_BE_SIGNED';
                    }
                    //END-BR-26-04-2023-US-0013524
                }
	 			
	 		}catch(Exception ex){isError = true; EBH_ApexLogger.logError(new List<Exception> { ex }, 'EBH_TrackingResponseController','handleContractFVFAggree');errMsg = ex.getMessage();}
 		}
 	}

    /****************************************************************************************************************************
    @ Method:         handleTicketSOS_Contract
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:        US-0009366 - [Export Reports] - Manage PII access within Hive in a SOX compliant manner  
    -----------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.05.2021 / Vadhanak Voun /Created the Method. 
    *****************************************************************************************************************************/
    private void handleTicketSOS_Contract()
    {
        String caseUid = ApexPages.currentPage().getParameters().get('id');
        caseUid = caseUid==null?null: EncodingUtil.urlDecode(String.escapeSingleQuotes(caseUid),'UTF-8'); system.debug('-----handleTicketSOS_Contract caseUid: '+caseUid);
        isError = false;
        if(caseUid <> null)
        {
            try
	 		{   
                List<Case> css = [Select Id,Terms_Signed_Date__c From Case Where Unique_Id__c =:caseUid];
                if(!css.isEmpty() && css[0].Terms_Signed_Date__c ==null)
                {
                    css[0].Terms_Signed_Date__c = System.now();
                    css[0].Status = CaseTriggerHandler.STATUS_INPROGRESS ;
                    update css[0];
                }
                
            }catch(Exception ex){isError = true; EBH_ApexLogger.logError(new List<Exception> { ex }, 'EBH_TrackingResponseController','handleTicketSOS_Contract');errMsg = ex.getMessage();}
        }else { isError = true; errMsg = System.Label.InvalidParam;}
    }
    
}