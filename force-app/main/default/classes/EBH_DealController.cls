/*********************************************************************************************************************************@ Class:          EBH_DealController@ Version:        1.0
@ Author:         
@ Purpose:        Controller Class for Deal list view buttons pages
@                  EPH-31 : Campaign Review and Measurement
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.11.2017 /  / Created the class.
@				  27.02.2018 / DHE / Story eph-5347
@				  07/06/2018 / Vadhanak / [#EPH-5741] Negotiate deals with sellers (Edit Feature)		
@				  11/08/2022 / Mony Nou / US-0011136 - 'Rejecting' AU Unsub Deal in Deal Window Related List
@                 16/08/2022 / Sovantheany Dim / US-0011469 - AU Unsub Approval for Deals in Deal Window Related List
@                 31/10/2022 / Loumang SENG / US-0012869 - Time value adjustment in DE Deals Contract/ Spotlight Export.
@                 01/02/2023 / Sovantheany Dim / US-0013020 - Remove negotiating picklist from the Deal V1 record type
@                 20/04/2023 / Loumang SENG / US-0013361 - Updates for Reason for Rejection picklists
@                 16/05/2023 / Mony Nou / US-0013603 - IT Deals Team - Need access to all the process in the Un-Sub Deals process for Deal Site = IT
@                 17/05/2023 / Mony Nou / US-0013508 - Approve Button - Deal Window
@                 16/01/2025 / Chan Sophorn SENG / US-0016379 - 4 - Category Manager's Ability to reject deals on the DCA
@                 30.01.2025 / Sovantheany Dim / US-0016603 - 7.1 - BOND Team - Rejecting Deals in In Approval process
@                 04.04.2025 / Chan Sophorn SENG  / US-0016808 - Removing Double confirmation Reject screen - Sprint review feedback
@                 06.06.2025 / Sovantheany Dim / US-0032896 - When Accept functionality used for deals which are of Deals site other than, DE throw error
@                  08.08.2025 / vadhanak voun / US-0033284 - User is not able to accept Deal
*********************************************************************************************************************************/
public with sharing class EBH_DealController { 
    public String negotiationComment {get;set;}
    //public List<EBH_Deal__c> listInvalidDeals{get;set;} //accept only  "New" or "Negotiating Amended"//TH:US-0013020:comment Out
	
    public static String DATE_FORMAT = 'yyyy-MM-dd';
    public EBH_Deal__c deal{get;set;}
    public List<EBH_Deal__c>selectedDeal{get;set;}
    public String csvData{get;set;}
    public String reUrl{get;set;}
    ApexPages.StandardSetController setCon;
    public boolean DontSendEmail{get;set;}
    public String timeStamp{get{return System.now().format('YYYY-MM-dd_hh.mm.ss');}set;}
    public String reasonExt{get;set;}
    public List<DTODeal> listSiteDeal{get;set;}
    private Map<String,DTODeal> mapDealsDTO;
    public static final String RECORDTYPE_UNSUBDEAL = 'Deal_V3';
    public static final String RECORDTYPE_NA_DEAL = 'Deal_V2';
    public static final String RECORDTYPE_SUBSIDIZED_DCA = 'Subsidized_Deals';//TH:US-0016603
    private static final String SITE_US = '0';
    private static final String SITE_AU = '15'; //MN-11082022-US-0011136 
    private static final String SITE_IT = '101'; //LA-20-04-2023-US-0013361 
    public static Set<String> allowedAcceptSites = new Set<String>{SITE_US, SITE_AU, SITE_IT};//TH:16/08/2022:US-0011469 //MN-16052023-US-0013603:Added site IT
    public Boolean isErrorMsg {get;set;}
    //private static final String  NOT_SAME_STATUS_ERROR ='You can only approve Deals with Status \'Ops Review\' and \'CM Review\'. Selected deals must have the same Status value';
    //private static final String  NO_SPOTLIGHT_CATE_ERROR ='Spotlight Category cannot blank.';
    public static final String  STATUS_PLANNED ='Planned';
    private static final String  STATUS_CM_REVIEW ='CM Review';
    private static final String  STATUS_OPS_REVIEW ='Ops Review';
    private static final String  STATUS_INCOMPLETE_DATA ='Incomplete Data';
    private static final String  STATUS_SCHEDULED ='Scheduled';
    public static final String STATUS_IN_APPROVAL = 'In Approval';//TH:US-0016603
    private final String EMAIL_TMP = 'Subsidized_DCA_Internally_Rejected_The_Selected_Deals_Email_Template';
    //private static final String  NOT_DEALSITE_US_ERROR ='NA Unsub Deal site should be US only.';
    public EBH_Deal__c spotlightDeal{get;set;}
    public Boolean isSpotlightError {get;set;}
    private final static String PERMISSION_NA_MANAGE_DEAL = 'US_Manage_Deals';
    private final static String PERMISSION_NA_UNSUB_DEAL = 'eBay_NA_Manage_Unsub_Deals';
    public static final String NA_PROFILE = 'NA Standard User Base';
    public Boolean isError {get;set;}
    public String errorMsg {get;set;}
    public Boolean isLabelContinue {get;set;}
    // SRONG TIN 09.08.2021 : US-0009958 Confirmation Pop-up when Cancelling or Rejecting or Approving Dels
    public Boolean displayPopup {get; set;}
    public static final String SOQL_DEAL = 'Select Id,Deal_Contract_Agreement__r.Owner.Email,Deal_Contract_Agreement__c,Deal_Contract_Agreement__r.Title__c,Deal_Contract_Agreement__r.RecordType.DeveloperName,RecordType.DeveloperName, RecordTypeId, EBH_CommentfromeBaySourcer__c,DateAcceptSend__c,Name, EBH_BusinessName__r.Name, EBH_SpotlightCategory__c, EBH_SpotlightFeaturedID__c, Owner.Alias,'
        +' EBH_eBayLink__c, EBH_eBayItemID__c, EBH_DealPrice__c, EBH_RRPWASPrice__c, EBH_ProductTitle__c, EBH_RecommendedRetailPriceWAS__c, EBH_Subsidy__c, EBH_MarketingTitle__c, EBH_DealFormat__c,'
        +' EBH_DealStartDate__c, EBH_DealEndDate__c, EBH_MaximumPurchases__c,EBH_DealSiteId__c , toLabel(EBH_DealSiteId__c)SiteLabel, EBH_ReasonforRejection__c,EBH_ReasonforRejectionextd__c,EBH_Status__c, Rank__c From EBH_Deal__c';
	private Boolean isDealRetailCampaign = false;
    public String dealRetailCampaingID {get; set;}
    public static Set<String> allowedStatus = new Set<String>{STATUS_OPS_REVIEW, STATUS_CM_REVIEW,STATUS_INCOMPLETE_DATA};
    public static Set<String> allowedStatusAU = new Set<String>{STATUS_OPS_REVIEW,STATUS_INCOMPLETE_DATA};
    public static final String RECORDTYPE_DEAL_V1= 'Deal_V1';//LA:31-10-2022-US-0012869
    private final String SITE_DE= '77';//LA:31-10-2022-US-0012869

    public static final String SOQL_PARENT_DEAL = 'SELECT Id,RecordType.DeveloperName, Status__c,eBay_Seller__c FROM Deal_Contract_Agreement__c where id=: parentRecId Limit 1';//US-0016379
    PageReference pgCurrent = ApexPages.currentPage();
    public String parentRecId = String.isBlank(pgCurrent.getParameters().get('Id')) ? '' : String.escapeSingleQuotes(pgCurrent.getParameters().get('Id'));//US-0016379
    public Map<String,String> mapDCASellerId {get; set;}//US-0016379
    public Boolean isSUBSIDIZED_DCA {get; set;}


    /*****************************************************************************************************************************
    @ Method:         EBH_DealController
    @ Version:        1.0
    @ Author:          
    @ Purpose:        Constructor
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      ApexPages.StandardController controller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.11.2017 /   / Created the  Method.
    @ Change history: 03.March.2020 / Acmatac SEING  / Updated the  Method. [US-0006969] : Deals - Add Spotlight Rank to Spotligh Export txt. file
                                                    AC) When I go to any Deal Object list view and click on Top right corner "EXPORT" then the file will also include the field Rank__c                     
    *****************************************************************************************************************************/
    public EBH_DealController(ApexPages.StandardSetController controller){
        setCon = controller;
        //selectedDeal = (List<EBH_Deal__c>)controller.getSelected();
        selectedDeal = controller.getSelected();

        selectedDeal = Database.query(SOQL_DEAL+' Where Id IN :selectedDeal');
        csvData = buildCSVData(selectedDeal);
        //reUrl = controller.cancel().getUrl();
        spotlightDeal = new EBH_Deal__c(EBH_SpotlightCategory__c=null);
        isSpotlightError = false;
        if (TEst.isRunningTest()){
            DontSendEmail=false;
        }
         
        init();
    }
    
    /*****************************************************************************************************************************
    @ Method:         EBH_DealController
    @ Version:        1.0
    @ Author:          
    @ Purpose:        Constructor
    US-0010082 - [SEP] Generate Spotlight Export file from Deal Window
    AC1) As an NA Unsub Deal Manager, I want to be able to use the button 'Export' on the Deal Window which will generate a Spotlight Export file for all Deals in the Deal Window which have a Status = Scheduled or Running.
    (Rejected and Cancelled Deals are excluded)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      ApexPages.StandardController controller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.08.2021 / Sovantheany Dim / Created the  Method.
    @ Change history: 29.11.2021 / Sovantheany Dim / Update Method US-0010920 - Unable to export weekly submissions/selections.
    *****************************************************************************************************************************/
    public EBH_DealController(ApexPages.StandardController controller){
        //TH:29/11/2021:US-0010920:comment out and move to Export by Report
    	//isDealRetailCampaign = true;
        //String dealRetailCampaingID = controller.getRecord().id;
    	//Set<String> sStatus = new Set<String>{'Scheduled','Running'};
        //selectedDeal = Database.query(SOQL_DEAL+' Where EBH_DealRetailCampaign__c =: dealRetailCampaign_id AND EBH_Status__c IN: sStatus');
        //csvData = buildCSVData(selectedDeal);

        //TH:29/11/2021:US-0010920 : get content from report
        dealRetailCampaingID = controller.getRecord().id;
        PageReference returnURL = new PageReference('/'+System.label.Report_Deals_with_Deal_Retail_Campaign+'?isdtp=nv&enc=UTF-8&xf=localecsv&export=Export&co=1&format=tt&pc0=FK_CUSTENT_ID&pn0=eq&pv0='+dealRetailCampaingID.substring(0, 15)+'&pc1=00N6A00000ASU4K&pn1=co&pv1='+ EncodingUtil.urlEncode(System.Label.DRC_Export_ReportStatus_Filter, 'UTF-8') +'&lexExport=true');
        csvData = Test.isRunningTest()?'':returnURL.getContent().toString();
    }

     /*****************************************************************************************************************************
    @ Method:         init
    @ Version:        1.0
    @ Author:          
    @ Purpose:        initialize data for vf view
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      ApexPages.StandardController controller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.03.2018 / Vadhanak.Voun  / Created the  Method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.08.2022 / Mony Nou  / US-0011136 - 'Rejecting' AU Unsub Deal in Deal Window Related List
    @                 16/01/2025 / Chan Sophorn SENG / US-0016379 - 4 - Category Manager's Ability to reject deals on the DCA

    *****************************************************************************************************************************/
    private void init()
    {

        // CSP:US-0016379
        isSUBSIDIZED_DCA=false;
        List<Deal_Contract_Agreement__c> dealContactAgreement = ApexSafe.query().secCheck(false).doQuery(
            SOQL_PARENT_DEAL,
            new Map<String, Object>{'parentRecId' => parentRecId}
        );

        mapDCASellerId = new Map<String,String>();
        for(Deal_Contract_Agreement__c dca : dealContactAgreement){
            isSUBSIDIZED_DCA= dca.RecordType.DeveloperName == RECORDTYPE_SUBSIDIZED_DCA ? true : false;
            mapDCASellerId.put(dca.Id,dca.eBay_Seller__c);
        }

        
		//listInvalidDeals = new List<EBH_Deal__c>();//TH:US-0013020:comment Out
		Map<String,String> mapDeals = new Map<String,String>();
        Id recordTypeId;
        isLabelContinue = false;
        for(EBH_Deal__c d: selectedDeal)
        {
			 //LA:28-06-2021-US-0009750: [SEP] US - NA Unsub Deal - 'Rejecting' Deals in Deal Window Related List
             //MN-11082022-US-0011136 : Enabled AU Site in below condition
             //LA-20-04-2023-US-0013361 : Enabled IT Site in below condition
            if(recordTypeId== null && (d.EBH_DealSiteId__c==SITE_US || d.EBH_DealSiteId__c==SITE_AU || d.EBH_DealSiteId__c==SITE_IT) && d.RecordType.DeveloperName==RECORDTYPE_UNSUBDEAL){
                recordTypeId= d.RecordTypeId;
                isLabelContinue = true;
            //CSP-160125 | US-0016379
            } else if (recordTypeId== null && d.EBH_DealSiteId__c==SITE_US && d.RecordType.DeveloperName==RECORDTYPE_NA_DEAL){
                recordTypeId= d.RecordTypeId;
                isLabelContinue = true;
            }

            mapDeals.put(d.EBH_DealSiteId__c,d.get('SiteLabel')+'');
            //TH:US-0013020:comment out
			/*if(!EBH_ConstantsUtility.DEAL_NEGOTIATION_STATUS.contains(d.EBH_Status__c))
        	{
        		listInvalidDeals.add(d);
        	}*/
            
        }
        listSiteDeal = new List<DTODeal>(); 
        for(String s: mapDeals.keySet())
        {
            EBH_Deal__c deal = new EBH_Deal__c(EBH_DealSiteId__c=s);
            if(deal.EBH_DealSiteId__c == SITE_US || deal.EBH_DealSiteId__c == SITE_AU || deal.EBH_DealSiteId__c == SITE_IT){//LA:28-06-2021-US-0009750 //MN-11082022-US-0011136 
                deal.RecordTypeId = recordTypeId;
            }
            
            listSiteDeal.add(new DTODeal(mapDeals.get(s),deal));
        }
        mapDealsDTO = new Map<String,DTODeal>();
        for(DTODeal d: listSiteDeal)
        {
            mapDealsDTO.put(d.deal.EBH_DealSiteId__c,d);
        }
    }
    /*****************************************************************************************************************************
    @ Method:         buildCSVData
    @ Version:        1.0
    @ Author:          
    @ Purpose:        Export deals
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<EBH_Deal__c>deals
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.11.2017 /   / Created the  Method.
    @ Change history: 13.11.2017 / ASHISH BARANWAL  / Updated the  Method.
    @ Change history: 03.March.2020 / Acmatac SEING  / Updated the  Method. [US-0006969] : Deals - Add Spotlight Rank to Spotligh Export txt. file
                                                    AC) When I go to any Deal Object list view and click on Top right corner "EXPORT" then the file will also include the field Rank__c                     
    @ Change history: 23.Aug.2021 / Sovantheany Dim / US-0010082 - add in the column headers
    @ Change history: 31/10/2022 / Loumang SENG / US-0012869 - Time value adjustment in DE Deals Contract/ Spotlight Export.
    *****************************************************************************************************************************/
    public String buildCSVData(List<EBH_Deal__c>deals){
        //TH:29/11/2021:US-0010920 : stop using
        /*
        //TH:US-0010082:23.Aug.2021
    	String delimited = isDealRetailCampaign ? ',':'|';
        //TH:reserve blank column:US-0010268 - Missing column in spotlight export file
        Set<String> sHeader = new Set<String>{'eBay Item ID','Rank','Deal Price','','RRP/WAS Price','Recommended Retail Price / WAS','Subsidy per Sold Item','Maximum Purchases','Marketing Title','Deal Format','Spotlight Featured ID','Deal Start Date','Deal End Date'};
        String csvData = !isDealRetailCampaign ? '' : String.join(new List<String>(sHeader),delimited) + delimited+'\n';
        //End US-0010082
        
        */
        String csvData = '';
        for(EBH_Deal__c d : deals) {
            String startTime = (d.RecordType.DeveloperName==RECORDTYPE_DEAL_V1 && d.EBH_DealSiteId__c==SITE_DE)? System.label.Start_Time_Site_DE : System.label.Start_Time_Not_Site_DE;//LA:31-10-2022-US-0012869
            String endTime = (d.RecordType.DeveloperName==RECORDTYPE_DEAL_V1 && d.EBH_DealSiteId__c==SITE_DE)? System.label.End_Time_Site_DE : System.label.End_Time_Not_Site_DE;//LA:31-10-2022-US-0012869
            List<String> rowData = new List<String>();
            rowData.add(getObjectValue(d.EBH_eBayItemID__c));
            rowData.add(getObjectValue(d.Rank__c));
            //TH:reserve blank column:US-0010268 - Missing column in spotlight export file
           	rowData.add(getObjectValue(d.EBH_DealPrice__c) + '|');
            //rowData.add(getObjectValue(d.EBH_DealPrice__c) + delimited);
            rowData.add(getObjectValue(d.EBH_RRPWASPrice__c));
            rowData.add(getObjectValue(d.EBH_RecommendedRetailPriceWAS__c));
            rowData.add(getObjectValue(d.EBH_Subsidy__c));
            //update by ASHISH BARANWAL
            rowData.add(getObjectValue(d.EBH_MaximumPurchases__c));
            //update by ASHISH BARANWAL
            rowData.add(getObjectValue(d.EBH_MarketingTitle__c));
            rowData.add(getObjectValue(d.EBH_DealFormat__c));
            rowData.add(getObjectValue(d.EBH_SpotlightFeaturedID__c));
            // rowData.add(getObjectValue(d.EBH_DealStartDate__c) + ' 08:00');//LA:31-10-2022-US-0012869
            // rowData.add(getObjectValue(d.EBH_DealEndDate__c) + '  07:59');//LA:31-10-2022-US-0012869
            rowData.add(getObjectValue(d.EBH_DealStartDate__c)+ ' ' + startTime);//LA:31-10-2022-US-0012869
            rowData.add(getObjectValue(d.EBH_DealEndDate__c) + ' ' + endTime);//LA:31-10-2022-US-0012869
            csvData += String.join(rowData, '|') + '|' + '\n';
        }
        return csvData.trim();
    }
    
    /*****************************************************************************************************************************
    @ Method:         getObjectValue
    @ Version:        1.0
    @ Author:          
    @ Purpose:        Return String value by its type
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Object obj
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.11.2017 /  / Created the  Method.
    @               : 28.11.2017/ Vadhanak Voun     / #13621: removed thousands separator for any number
    *****************************************************************************************************************************/
    private String getObjectValue(Object obj){
        if(obj==null)return '';
        if(obj instanceof Date) return convertDate((Date)obj);
        if(obj instanceof DateTime) return ((DateTime)obj).format(DATE_FORMAT);
        //if(obj instanceof Decimal) return formatNumber((Decimal) obj,',','.',((Decimal) obj).scale());
        if(obj instanceof Decimal) return formatNumber((Decimal) obj,'','.',((Decimal) obj).scale());
        return obj + '';
    }
    
    /*****************************************************************************************************************************
    @ Method:         convertDate
    @ Version:        1.0
    @ Author:         
    @ Purpose:        Convert date with format defined
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Date dateValue
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.11.2017 /   / Created the  Method.
    *****************************************************************************************************************************/
    private String convertDate(Date dateValue) {
        DateTime dt = DateTime.newInstance(dateValue.year(), dateValue.month(), dateValue.day());
        return dt.format(DATE_FORMAT);
    }
    
    /*****************************************************************************************************************************
    @ Method:         initRejecting
    @ Version:        1.0
    @ Author:         
    @ Purpose:        US-0009944: initialize error message for vf EBH_RejectDeal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      ApexPages.StandardController controller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.07.2021 / Loumang SENG / Created the  Method.
    *****************************************************************************************************************************/
    public PageReference initRejecting(){
        
        if(selectedDeal.isEmpty()){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, System.Label.NA_CANCEL_FUNC_ERR3));
            errorMsg = System.Label.NA_CANCEL_FUNC_ERR3;
            isError = true;
            displayPopUp = false;
            return null;
        }

        String naProfile = ApexUtil.getProfileByName(NA_PROFILE).Id;
        Boolean isNA = UserInfo.getProfileId().equals(naProfile);
        Boolean isPSNaUnSubDeal = ApexUtil.checkPermissionSet(new Set<String>{PERMISSION_NA_UNSUB_DEAL});
         //CSP-160125 | US-0016379
        Boolean isPSNaSubDeal = ApexUtil.checkPermissionSet(new Set<String>{PERMISSION_NA_MANAGE_DEAL});

        String firstRcordtype = selectedDeal[0].RecordType.DeveloperName;
        Set<String> allowedRecordType= new Set<String>{RECORDTYPE_UNSUBDEAL, RECORDTYPE_NA_DEAL};

        //LA:16-07-2021:US-0009944:block reject button for Profile NA without permission set NA Manage Unsub Deals
        //CSP-160125 | US-0016379
        if(isNA && !isPSNaUnSubDeal && !isPSNaSubDeal){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, System.Label.THIS_FUNCTIONALITY_IS_NOT_AVAILABLE_TO_YOUR_REGION));
            errorMsg = System.Label.THIS_FUNCTIONALITY_IS_NOT_AVAILABLE_TO_YOUR_REGION;
            isError = true;
            displayPopUp = false;
            return null;
        }

        for(EBH_Deal__c d: selectedDeal)
        {
            
            //LA:16-07-2021: block rejected deals with different recordtypes or recordtype != NA Unsub Deal when user has permission set NA Manage Unsub Deals
            //CSP-200125 | US-0016379
            if(
                (firstRcordtype != d.RecordType.DeveloperName || !allowedRecordType.contains(d.RecordType.DeveloperName)) 
                && (isPSNaUnSubDeal || isPSNaSubDeal)){
                d.RecordType.DeveloperName.addError(System.Label.UNSUB_DEAL_RECORDTYPE_ERROR);
                errorMsg = System.Label.UNSUB_DEAL_RECORDTYPE_ERROR;
                isError = true;
                displayPopUp = false;
                return null;
            }
        }
        return null;

    }

    /*****************************************************************************************************************************
    @ Method:         rejectDeal
    @ Version:        1.0
    @ Author:          
    @ Purpose:        Reject selected Deal from listview
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.11.2017 /   / Created the  Method.
    @				: 22/03/2018/ Vadhanak Voun / updated to handle multiple site rejection
    @               06.05.2022 / Acmatac SEING / US-0011577 - UAT Feedback for NA Deals Custom List view
    @               16.01.2025 / Chan Sophorn SENG / US-0016379 - 4 - Category Manager's Ability to reject deals on the DCA
    @               30.01.2025 / Sovantheany Dim / US-0016603 - 7.1 - BOND Team - Rejecting Deals in In Approval process
    *****************************************************************************************************************************/
    public PageReference rejectDeal(){
        if(!selectedDeal.isEmpty()){
            try{
                Boolean isReasonforRejectionError = false;
                for(DTODeal dto : listSiteDeal) {
                    if(String.isEmpty(dto.deal.EBH_ReasonforRejection__c)){
                        dto.deal.EBH_ReasonforRejection__c.addError('Please select a reason for rejection.');
                        isReasonforRejectionError = true;
                    }
                }
              
                if(isReasonforRejectionError) {return null;}

                Boolean allRegeted = true;

                Set<String> sDCAIds = new Set<String>();
                
                for(EBH_Deal__c d : selectedDeal) {
                    // CSP:US-0016379
                    if (d.EBH_Status__c != 'Rejected') { allRegeted = false;}
                    //TH:US-0016603 : transition from "In Approval" to Internally Rejected, on deals which is related to Deal_V2 and only when it is related to Deal Contract Agreement of Subsidized Type
                    if(d.Deal_Contract_Agreement__r.RecordType.DeveloperName == RECORDTYPE_SUBSIDIZED_DCA && d.RecordType.DeveloperName == RECORDTYPE_NA_DEAL && d.EBH_Status__c == STATUS_IN_APPROVAL){
                        d.EBH_Status__c = 'Internally Rejected';
                        sDCAIds.add(d.Deal_Contract_Agreement__c);
                    }else{
                        d.EBH_Status__c = 'Rejected';
                    }
                    d.EBH_ReasonforRejection__c = mapDealsDTO.get(d.EBH_DealSiteId__c).deal.EBH_ReasonforRejection__c;
                    d.EBH_ReasonforRejectionextd__c = reasonExt;

                    //CSP-160125 | US-0016379
                    if (d.RecordType.DeveloperName ==RECORDTYPE_NA_DEAL) {
                        d.EBH_Don_t_send_email_to_sellers__c=false; 
                    } else {
                        d.EBH_Don_t_send_email_to_sellers__c=DontSendEmail; // Added by DHE 2018/02/26
                    }
                }

                //update selectedDeal;                 
                List<Database.SaveResult> listResult = ApexSafe.dml().secCheck(false).doUpdate(selectedDeal, true);

                //TH:US-0016603 : Send Email to DCA Owner
                if(!sDCAIds.isEmpty()){
                    callFlow(sDCAIds);
                }
                // CSP:US-0016379: Send Email to seller of DCA
                else if(!mapDCASellerId.isEmpty() && isSUBSIDIZED_DCA&&!allRegeted) {
                    String sComName = 'Send Reject Sub - Deals Notificaiton to Seller - US';
                    String emailTemplate = 'US Subsidized Deals Rejection';
                    DealContractAgreementTriggerHandler.createSellerComsByDCA(
                        'Deals',
                        mapDCASellerId,
                        sComName, 
                        emailTemplate
                    );
                } 

                // US-0011577 - UAT Feedback for NA Deals Custom List view
                String parentRecId = CustomRelatedListController.checkIfFromCustomRelatedList_ThenReturnParentId();
                if(String.isNotBlank(parentRecId)){
                    PageReference pg = new PageReference('/'+parentRecId);
                    pg.setRedirect(true);
                    return pg;
                }

                return setCon.cancel();

            }catch(Exception ex){
                isError = true;
                displayPopUp = false;
                // ApexPages.addMessages(ex);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                //errorMsg = System.Label.NA_CANCEL_FUNC_ERR3;
                errorMsg = ex.getMessage();
            }
        }
        //return new PageReference(reUrl);
        return null; 
    }

    /*****************************************************************************************************************************
    @ Method:         callFlow
    @ Version:        1.0
    @ Author:         Sovantheany Dim
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.02.2025 / Sovantheany dim  / Created the  Method.
    *****************************************************************************************************************************/
    public void callFlow(Set<String> sDCAIds) {
        // Prepare the Flow variables
        Map<String, Object> params = new Map<String, Object>();
        params.put('recordIds', sDCAIds);
        
        // Instantiate and start the Flow
        Flow.Interview.Notify_DCA_Owner_on_Deal_Internally_Rejected yourFlow = new Flow.Interview.Notify_DCA_Owner_on_Deal_Internally_Rejected(params);
        yourFlow.start();
    }

    /*****************************************************************************************************************************
    @ Method:         backToListView
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL 
    @ Purpose:        Return to page url
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.11.2017 / ASHISH BARANWAL  / Created the  Method.
    @               06.05.2022 / Acmatac SEING / US-0011577 - UAT Feedback for NA Deals Custom List view
    *****************************************************************************************************************************/
    public PageReference backToListView(){
        //return new PageReference(reUrl);
        
        
        // US-0011577 - UAT Feedback for NA Deals Custom List view
        // String parentRecIdUrl = CustomRelatedListController.checkIfFromCustomRelatedList_ThenReturnParentId();
        if(String.isNotBlank(parentRecId)){
            PageReference pg = new PageReference('/'+parentRecId);
            pg.setRedirect(true);
            return pg;
        }

        return setCon.cancel();
    }

    /*****************************************************************************************************************************
    @ Method:         confirmAcceptDeal
    @ Version:        1.0
    @ Author:         SRONG TIN
    @ Purpose:        To alert message confirm popup 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.09.2021 / SRONG TIN  / Created the  Method.
                      13.10.2021 / SRONG TIN / Update the Method. [EU Deal] Wrong page displayed when click Accept/ Reject Standard Deal
                      22.10.2021 / SRONG TIN / Update the Method. US-0010303
    *****************************************************************************************************************************/
    public PageReference confirmAcceptDeal(){
        if(!selectedDeal.isEmpty()) {
            isSpotlightError = false;
            isErrorMsg = false;
            String firstStatus = selectedDeal[0].EBH_Status__c;
            //Set<String> allowedStatus = new Set<String>{STATUS_OPS_REVIEW, STATUS_CM_REVIEW,STATUS_INCOMPLETE_DATA};
            // SRONG TIN : 13.10.2021 | US-0010303
            Boolean isNAUnsubDeal = false;
            Boolean isNAsubDeal = false;
            for(EBH_Deal__c d : selectedDeal) {
                if(d.RecordType.DeveloperName==RECORDTYPE_UNSUBDEAL){
                    isNAUnsubDeal = true;
            	} 
                if(!acceptDealValidation(d,firstStatus,spotlightDeal,isErrorMsg,isSpotlightError)) return null;

            }
            // SRONG TIN : 13.10.2021 | US-0010303
            if(!isNAUnsubDeal ){
                // SRONG TIN : 22.10.2021 | US-0010303
                return acceptDeal();
            }else{
                displayPopup = true;
                return null;
            }
            
        }
        return setCon.cancel();
    }
    /*****************************************************************************************************************************
    @ Method:         confirmRejectDeal
    @ Version:        1.0
    @ Author:         SRONG TIN
    @ Purpose:        To alert message confirm popup 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.09.2021 / SRONG TIN  / Created the  Method.
                      13.10.2021 / SRONG TIN /  Update the method. US-0010303 - [EU Deal] Wrong page displayed when click Accept/ Reject Standard Deal
                      22.10.2021 / SRONG TIN / Update the Method. US-0010303
    @                 16.01.2025 / Chan Sophorn SENG / US-0016379 - 4 - Category Manager's Ability to reject deals on the DCA
    @                 04.04.2025 / Chan Sophorn SENG / US-0016808 - Removing Double confirmation Reject screen - Sprint review feedback
    *****************************************************************************************************************************/
    public PageReference confirmRejectDeal(){
        
        if(!selectedDeal.isEmpty()) {
            Boolean isReasonforRejectionError = false;
            // SRONG TIN : 13.10.2021 | US-0010303
            Boolean isNAUnsubDeal = false;
            Boolean isNAsubDeal = false;
            for(EBH_Deal__c d: selectedDeal){
             	if(d.RecordType.DeveloperName==RECORDTYPE_UNSUBDEAL){
                    isNAUnsubDeal = true;
                    break;
                //CSP-160125 | US-0016379
            	} else if(d.RecordType.DeveloperName==RECORDTYPE_NA_DEAL) {
                    isNAsubDeal = true;
                    break;
                }
        	}
            for(DTODeal dto : listSiteDeal) {
                if(String.isEmpty(dto.deal.EBH_ReasonforRejection__c)){
                    dto.deal.EBH_ReasonforRejection__c.addError('Please select a reason for rejection.');
                    isReasonforRejectionError = true;
                }
            }
            if(isReasonforRejectionError)return null;
            

            //CSP-040425 | US-0016808
            return rejectDeal();

            // SRONG TIN : 13.10.2021 | US-0010303
            //CSP-160125 | US-0016379
            // if(!isNAUnsubDeal && !isNAsubDeal){
            //     // SRONG TIN : 22.10.2021 | US-0010303
            //     return rejectDeal();
            // }else{
            //   displayPopup = true;
            // 	 return null;  
            // }   
            
        }
        return setCon.cancel();
    }
    
    /*****************************************************************************************************************************
    @ Method:         AcceptDeal
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL 
    @ Purpose:        Accept selected Deal from listview
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.11.2017 / ASHISH BARANWAL  / Created the  Method.
    @ Change history: 25/12/2019 / Sovantheany Dim / Updated methode : add DateAcceptSend__c US-0006971
    @ Change history: 05/07/2021 / Loumang SENG / Updated methode : US-0009748: for recordtype NA Unsub Deal
    @                 16/08/2022 / Sovantheany Dim / US-0011469 - AU Unsub Approval for Deals in Deal Window Related List
    @                 17/05/2023 / Mony Nou / US-0013508 - Approve Button - Deal Window
    *****************************************************************************************************************************/
    public PageReference acceptDeal(){
        if(!selectedDeal.isEmpty()) {
            isSpotlightError = false;
            isErrorMsg = false;
            String firstStatus = selectedDeal[0].EBH_Status__c;
            //Set<String> allowedStatus = new Set<String>{STATUS_OPS_REVIEW, STATUS_CM_REVIEW,STATUS_INCOMPLETE_DATA};
            for(EBH_Deal__c d : selectedDeal) {
                if(!acceptDealValidation(d,firstStatus,spotlightDeal,isErrorMsg,isSpotlightError)) return null;

            }
            for(EBH_Deal__c d : selectedDeal) {

                //MN-17052023-US-0013508: "CM Review" is going to retired so NA will behave the same as AU & IT
                if (d.RecordType.DeveloperName==RECORDTYPE_UNSUBDEAL) {
                    
                    if(d.EBH_Status__c == STATUS_OPS_REVIEW){
                        d.EBH_Status__c = STATUS_SCHEDULED;
                    }
                    else if(d.EBH_Status__c == STATUS_INCOMPLETE_DATA){
                        d.EBH_Status__c = STATUS_OPS_REVIEW;
                    }
                }/**US-0032896: TH: move logic to  acceptDealV1() */
                //else {
                    
                    // d.OwnerId = UserInfo.getUserId();
                    // d.EBH_Status__c = STATUS_PLANNED;
                    // d.DateAcceptSend__c = system.now();

                //} 
            }
            
            try
            {	
                // SRONG TIN - 21/03/2022 : US-0011338 System allowing Deals with same item ID & overlapping dates
                EBH_DealTriggerHandler.isFromUpdateDealToPlannedList = true;
                
            	update selectedDeal;
            }catch(DMLException dmx)
            {
                // SRONG TIN - 17/03/2022 : US-0011338 System allowing Deals with same item ID & overlapping dates
                if(!EBH_DealTriggerHandler.isFromUpdateDealToPlanned_Duplicated){
                    ApexPages.addMessages(dmx);
                }
            	return null;
            }
            
        }
        //return new PageReference(reUrl);
        //return setCon.cancel();
        return backToListView(); //MN-19052023-US-0013508:Fixed issue that not return to main page 
    }
    
    /*****************************************************************************************************************************
    @ Method:         acceptDealV1
    @ Version:        1.0
    @ Author:         Sovantheany dim 
    @ Purpose:        Accept selected Deal from listview (Updated "EBH_Accept" Deal Button with New VF page "AccepDealPage")
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2025 / Sovantheany Dim/ US-0032896 - When Accept functionality used for deals which are of Deals site other than, DE throw error
    @                 08.08.2025 / vadhanak voun / US-0033284 - User is not able to accept Deal
    *****************************************************************************************************************************/
    public PageReference acceptDealV1(){
        if(!selectedDeal.isEmpty()) {
            for(EBH_Deal__c d : selectedDeal) {
                if(d.RecordType.DeveloperName != RECORDTYPE_DEAL_V1){
                    //d.addError('This process is used only for Deal Site = DE (Standard Deal Type)');
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, System.label.AcceptDealProcessMsg));
                    return null;
                }
                d.OwnerId = UserInfo.getUserId();
                d.EBH_Status__c = STATUS_PLANNED;
                d.DateAcceptSend__c = system.now();
            }
            try
            {
                EBH_DealTriggerHandler.isFromUpdateDealToPlannedList = true;
                ApexSafe.SafeDML safeDml = ApexSafe.dml().secCheck(false);//NK:08/08/2025:US-0033284
                safeDml.doUpdate(selectedDeal, true);
            }catch(DMLException dmx)
                {
                    if(!EBH_DealTriggerHandler.isFromUpdateDealToPlanned_Duplicated){
                        ApexPages.addMessages(dmx);
                    }
                    return null;
                }   
        }
        return backToListView();
    }

    /*****************************************************************************************************************************
    @ Method:         acceptDealValidation
    @ Version:        1.0
    @ Author:         Sovantheany Dim
    @ Purpose:        To validate before Accept Deal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      EBH_Deal__c d,String firstStatus,EBH_Deal__c spotlightDeal, Boolean isErrorMsg, Boolean isSpotlightError
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.08.2022 / Sovantheany Dim  / Created the  Method.
    @                 17/05/2023 / Mony Nou / US-0013508 - Approve Button - Deal Window
    *****************************************************************************************************************************/
    private static Boolean acceptDealValidation(EBH_Deal__c d, String firstStatus,EBH_Deal__c spotlightDeal, Boolean isErrorMsg, Boolean isSpotlightError){
        //if(d.EBH_DealSiteId__c != SITE_US && d.RecordType.DeveloperName==RECORDTYPE_UNSUBDEAL){
        if(d.RecordType.DeveloperName==RECORDTYPE_UNSUBDEAL){
            //TH:16/08/2022:US-0011469:add Au Site condition
            if(!allowedAcceptSites.contains(d.EBH_DealSiteId__c)){
                d.EBH_DealSiteId__c.addError(System.Label.NOT_DEALSITE_US_ERROR);isErrorMsg = true; return false;
            }

            //MN-17052023-US-0013508: "CM Review" is going to retired so NA will behave the same as AU & IT
            if (firstStatus != d.EBH_Status__c || !allowedStatusAU.contains(d.EBH_Status__c)) {
                d.EBH_Status__c.addError(System.Label.NOT_SAME_STATUS_ERROR_AU);isErrorMsg = true;return false;
            }

            //MN-17052023-US-0013508: "CM Review" is going to retired so NA will behave the same as AU & IT
            if(d.EBH_Status__c == STATUS_OPS_REVIEW){
                d.EBH_SpotlightCategory__c = d.EBH_SpotlightCategory__c != null ? d.EBH_SpotlightCategory__c : spotlightDeal.EBH_SpotlightCategory__c;
                if(String.isEmpty(d.EBH_SpotlightCategory__c)){
                    d.EBH_SpotlightCategory__c.addError(System.Label.NO_SPOTLIGHT_CATE_ERROR);isErrorMsg = true;isSpotlightError = true;return false;
                }
            } 
        }
        return true;
    }
    
    /*****************************************************************************************************************************
    @ Method:         negotiateDeals
    @ Version:        1.0
    @ Author:         Vadhanak Voun 
    @ Purpose:        [#EPH-5741] Negotiate deals with sellers (Edit Feature)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.6.2018 / Vadhanak Voun  / Created the  Method.
    @				: 22.01.2020/ Vadhanak Voun / US-0007091 Empty value on field " Comment from eBay / Sourcer " from Negotiate page override value on deal detail
    @				: 		do not update comment if blank
    @               : 01/02/2023 / Sovantheany Dim / US-0013020 - Remove negotiating picklist from the Deal V1 record type
    *****************************************************************************************************************************/
    /*public PageReference negotiateDeals(){
    	if(!selectedDeal.isEmpty()) {
            
            try
            {
            	for(EBH_Deal__c d : selectedDeal) {
                	d.EBH_CommentfromeBaySourcer__c = String.isBlank(negotiationComment)?d.EBH_CommentfromeBaySourcer__c:negotiationComment;
                	d.EBH_Status__c = EBH_ConstantsUtility.DEAL_STATUS_NEGOTIATING;
            	}
            
            	update selectedDeal;
            }catch(DMLException dmx){ApexPages.addMessages(dmx);return null;}
        }
        //return new PageReference(reUrl);
        return setCon.cancel();
    }*/
	
    /*****************************************************************************************************************************
    @ Method:         formatNumber
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL 
    @ Purpose:        format number
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Decimal val, String osep, String nsep, Integer sclVal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.11.2017 / ASHISH BARANWAL  / Created the  Method.
    @               : 28.11.2017/ Vadhanak Voun     / handle osep when empty. eg. no thousand separater reqired
    *****************************************************************************************************************************/
    public static String formatNumber(Decimal val, String osep, String nsep, Integer sclVal){
        
        osep =  String.isEmpty(osep)?'!*!':osep;
        if(val == null){val = 0;}
        String s, tmp; Integer i = (sclVal==0?3:6);
        s = val.setScale(sclVal).toPlainString().replace(osep, nsep);
        String negSign = s.startsWith('-')?'-':''; //preserve the minus sign
        s = s.replace('-',''); //remove it for cal then add later
        osep = osep.replace('!*!','');
        while(s.length() > i)
        {
            tmp = s.substring(0, s.length() - i) + osep + s.substring(s.length() - i);
            s = tmp;
            i += 4;
        }
        return negSign+s;
    }
    
    /*****************************************************************************************************************************
    @ Class:          DTODeal 
    @ Version:        1.0
    @ Author:         Vadhanak Voun 
    @ Purpose:        internal wrapper
    ------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.11.2017/ Vadhanak Voun/ wrarpper to handle more varibles 
    *****************************************************************************************************************************/
    class DTODeal{
    	public String label{get;set;}
    	public EBH_Deal__c deal{get;set;}
    	public DTODeal(String label, EBH_Deal__c deal)
    	{
    		this.label = label; 
    		this.deal = deal;
    	}
    }            
}