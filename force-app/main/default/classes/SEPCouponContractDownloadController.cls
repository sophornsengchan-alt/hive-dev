/*********************************************************************************************************************************
@ Class:          SEPCouponContractDownloadController
@ Version:        1.0
@ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Controller vf page: SEPCouponContractDownloadPage
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.06.2022 / vadhanak / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.08.2022 / Mony Nou / US-0012216 - NA Coupons: Downloading /storing Coupon Contract on Portal and in Hive
@ Change history: 11.08.2022 / Sophal Noch / US-0012207 - Changes to contract PDF Download - requested from legal
@               : 22.11.2022/vadhanak voun/ US-0012187 - [UK] Downloading /storing Coupon Contract on Portal and in Hive
@               : 22.11.2022/ SRONG TIN / US-0012185 - [FR] Downloading /storing Coupon Contract on Portal and in Hive
@               : 22.11.2022/ SRONG TIN / US-0012186 - [IT] Downloading /storing Coupon Contract on Portal and in Hive
@               : 24.02.2023 / Sambath Seng / US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
@               : 02.04.2023 / Sambath Seng / US-0013377 - AU Champion UAT Fixes
@               : 11.07.2023 / Sambath Seng / US-0012639 - Allow contract download at contract send, before contract is signed
@               : 06/06/2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c 
@               : 01/08/2024 / Mony Nou / US-0015661 - Error message given when seller tries to accept coupon contract
@               : 08/18/2025 / SRONG TIN / US-0033261 - CA SP - Contract T&Cs View and Download
@               : 03.09.2025 / Loumang SENG / US-0033254 - POP - SP - Ability to Accept/Decline Coupon Seller Contract
@               : 08/01/2026 / SENG Chan Sophorn / US-0033468 - POP - SP - Populate Program Coupon info on Master Coupon Agreement Contract (Part 2) 

*********************************************************************************************************************************/
public with sharing class SEPCouponContractDownloadController {

    public String renderAsType {get;set;}

    //EMAIL tempalte name 
    final String TEMPLATE_ITEM = 'DE_Item_Coupon_Contract_SEP_Download';
    final String TEMPLATE_CAT = 'DE_Category_Coupon_Contract_SEP_Download';

    public String csId {get;set;}
    public String watermarkUrl {get;set;} // SB 11.07.2023 US-0012639
    public Boolean isDraft {get;set;} // SB 11.07.2023 US-0012639
    
    public String htmlContent {get;set;}
   
    // private final static String HTML_ROW_TEMPLATE_CAT = '<tr class=""><td> {Coupon_Category__c} </td><td> {Category_ID__c} </td><td> {Co_Invest__c} </td></tr>';
    private final static String HTML_ROW_TEMPLATE_CAT = '<tr class=""><td> {Category_ID__c} </td><td> {Coupon_Category__c} </td><td> {Co_Invest__c} </td></tr>'; // 17.08.2022 / Sophal Noch / US-0012207
    private final static String HTML_ROW_TEMPLATE_EMPTY = '<tr><td></td><td></td><td></td></tr>';
    private final static String HTML_ROW_TEMPLATE_ITEM = '<tr class=""><td> {Item_ID__c} </td><td> {Item_Title__c} </td><td> {Co_Invest__c} </td></tr>';
    private final static String HTML_ROW_TEMPLATE_CAT_AU = '<tr class=""><td> {Category_ID__c} </td><td> {Coupon_Category__c} </td><td> {Seller_Funding__c} </td></tr>';// SB 24.02.2023 US-0012755
    private final static String HTML_ROW_TEMPLATE_ITEM_AU = '<tr class=""><td> {Item_ID__c} </td><td> {Item_Title__c} </td><td> {Seller_Funding__c} </td></tr>';// SB 24.02.2023 US-0012755
    private static String htmlProgramTableTemplate = '<table style="width: 100%; border-collapse: collapse" border="1" cellspacing="0" cellpadding="5"><tbody><tr><td style="width: 350px;"><strong>Gutscheincode #{!index}</strong></td><td> {!CouponCode} </td></tr><tr><td> <strong>Gutscheinname</strong> </td><td>{!MarketingCouponName}</td></tr><tr><td><strong>Gültigkeitsdauer des Gutscheins</strong></td><td>{!CouponStartTime} {!CouponStartDate} bis {!CouponEndTime} {!CouponEndDate} (MEZ)</td></tr><tr><td><strong>Sonstiges</strong></td><td>{!AdditionalArrangement}</td></tr></tbody></table> <br>'; // 08012026:CSP/US-0033468

    //MN-05082022-US-0012216
    private final static String PROF_SEP_DE = 'DE - Seller Portal';
    private final static String PROF_SEP_NA = 'NA - Seller Portal';
    private final static String PROF_SEP_AU = 'AU - Seller Portal';// SB 24.02.2023 US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
    private final static String COUPON_CATEGORYBASE = 'Category Based';
    private final static String COUPON_ITEMBASE = 'Item Based';
    private final static String COUPON_SITE_AU = 'ebay.com.au';// SB 24.02.2023 US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive

    private final static String EMAIL_COUPON_CONTRACT_DE_ITEM_SEP = 'DE_Item_Coupon_Contract_SEP_Download';
    private final static String EMAIL_COUPON_CONTRACT_DE_CAT_SEP = 'DE_Category_Coupon_Contract_SEP_Download';
    private final static String EMAIL_COUPON_CONTRACT_NA_ITEM_SEP = 'NA_Item_Coupon_Contract_SEP_Download';
    private final static String EMAIL_COUPON_CONTRACT_NA_CAT_SEP = 'NA_Category_Coupon_Contract_SEP_Download';

    //NK:22/11/2022:US-0012187
    private final static String EMAIL_COUPON_CONTRACT_UK_CAT_SEP = 'UK_Category_Coupon_Contract_SEP_Download';
    private final static String EMAIL_COUPON_CONTRACT_UK_ITEM_SEP = 'UK_Item_Coupon_Contract_SEP_Download';
    //SRONG-22.11.2022-US-0012185
    private final static String EMAIL_COUPON_CONTRACT_FR_CAT_SEP = 'FR_Category_Coupon_Contract_SEP_Download';
    private final static String EMAIL_COUPON_CONTRACT_FR_ITEM_SEP = 'FR_Item_Coupon_Contract_SEP_Download';
    //SRONG-22.11.2022-US-0012186
    private final static String EMAIL_COUPON_CONTRACT_IT_CAT_SEP = 'IT_Category_Coupon_Contract_SEP_Download';
    private final static String EMAIL_COUPON_CONTRACT_IT_ITEM_SEP = 'IT_Item_Coupon_Contract_SEP_Download';
    //SB-24.02.2023-US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
    private final static String EMAIL_COUPON_CONTRACT_AU_CAT_SEP = 'AU_Category_Coupon_Contract_SEP_Download';
    private final static String EMAIL_COUPON_CONTRACT_AU_ITEM_SEP = 'AU_Item_Coupon_Contract_SEP_Download';
    //SB-11.07.2023-US-0012639 - Allow contract download at contract send, before contract is signed
    private final static String EMAIL_COUPON_CONTRACT_DE_CAT_SEP_DRAFT = 'DE_Draft_Category_Coupon_Contract_SEP_Download';
    private final static String EMAIL_COUPON_CONTRACT_DE_ITEM_SEP_DRAFT = 'DE_Draft_Item_Coupon_Contract_SEP_Download';
    private final static String EMAIL_COUPON_CONTRACT_DE_MC_SEP_DRAFT = 'DE_Draft_Master_Coupon_Agreement_Contract_SEP_Download';

    //SRONG-18.08.2025-US-0033261
    private final static String EMAIL_COUPON_CONTRACT_CA_CAT_SEP = 'CA_Category_Coupon_Contract_SEP_Download';
    private final static String EMAIL_COUPON_CONTRACT_CA_ITEM_SEP = 'CA_Item_Coupon_Contract_SEP_Download';
    
    private final static String EMAIL_COUPON_CONTRACT_DE_MC_SEP = 'DE_Master_Coupon_Agreement_Contract_SEP_Download';//LA-03-09-2025-US-0033254
    
    private final static Map<String,String> MAP_CONTRACT_LOCALIZE = new Map<String,String>{
        'ebay.co.uk-Category Based'=>EMAIL_COUPON_CONTRACT_UK_CAT_SEP,
        'ebay.co.uk-Item Based'=>EMAIL_COUPON_CONTRACT_UK_ITEM_SEP,
        'ebay.fr-Category Based'=>EMAIL_COUPON_CONTRACT_FR_CAT_SEP,
        'ebay.fr-Item Based'=>EMAIL_COUPON_CONTRACT_FR_ITEM_SEP,
        'ebay.it-Category Based'=>EMAIL_COUPON_CONTRACT_IT_CAT_SEP,
        'ebay.it-Item Based'=>EMAIL_COUPON_CONTRACT_IT_ITEM_SEP,
        'ebay.ca-Category Based'=>EMAIL_COUPON_CONTRACT_CA_CAT_SEP,//SRONG-18.08.2025-US-0033261
        'ebay.ca-Item Based'=>EMAIL_COUPON_CONTRACT_CA_ITEM_SEP //SRONG-18.08.2025-US-0033261
    };
    private final static String SITE_NAME_UK = 'ebay.co.uk';
    private final static String SITE_NAME_FR = 'ebay.fr';
    private final static String SITE_NAME_IT = 'ebay.it';

    /* MN-06062024-US-0015298: No longer use Profile Name
    Map<String, Map<String, String>> mProfEmailTemp = new Map<String, Map<String,String>> {
        PROF_SEP_DE => new Map<String, String>{
            COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_DE_ITEM_SEP,
            COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_DE_CAT_SEP
        },
        PROF_SEP_NA => new Map<String, String>{
            COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_NA_ITEM_SEP,
            COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_NA_CAT_SEP
        },
        PROF_SEP_AU => new Map<String, String>{// SB 24.02.2023 US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
            COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_AU_ITEM_SEP,
            COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_AU_CAT_SEP
        }
    };
    */

    //MN-06062024-US-0015298: use SP Main Domain instead of Profile Name
    Map<String, Map<String, String>> mSPMainDomainEmailTemp = new Map<String, Map<String,String>> {
        SEP_Helper.SEP_Domain_DE => new Map<String, String>{
            COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_DE_ITEM_SEP,
            COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_DE_CAT_SEP,
            SEPCouponController.COUPON_SCMC => EMAIL_COUPON_CONTRACT_DE_MC_SEP //LA-03-09-2025-US-0033254

        },
        SEP_Helper.SEP_Domain_NA => new Map<String, String>{
            COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_NA_ITEM_SEP,
            COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_NA_CAT_SEP
        },
        SEP_Helper.SEP_Domain_AU => new Map<String, String>{// SB 24.02.2023 US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
            COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_AU_ITEM_SEP,
            COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_AU_CAT_SEP
        }
    };

    // SB 11.07.2023 US-0012639 - Allow contract download at contract send, before contract is signed
    Map<String,String> mapDEDraftTemplate = new Map<String,String> {
        COUPON_ITEMBASE => EMAIL_COUPON_CONTRACT_DE_ITEM_SEP_DRAFT,
        COUPON_CATEGORYBASE => EMAIL_COUPON_CONTRACT_DE_CAT_SEP_DRAFT,
        SEPCouponController.COUPON_SCMC => EMAIL_COUPON_CONTRACT_DE_MC_SEP_DRAFT //LA-03-09-2025-US-0033254
    };

    private final static String DE_DRAFT_WATERMARK = PageReference.forResource('SEP_Watermark_Draft_DE').getUrl();
    private final static String NA_DRAFT_WATERMARK = PageReference.forResource('SEP_Watermark_Draft_NA').getUrl();
    private final static String FR_DRAFT_WATERMARK = PageReference.forResource('SEP_Watermark_Draft_FR').getUrl();
    private final static String IT_DRAFT_WATERMARK = PageReference.forResource('SEP_Watermark_Draft_IT').getUrl();

    Map<String,String> mapWatermark = new Map<String,String> {
        EMAIL_COUPON_CONTRACT_NA_ITEM_SEP => NA_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_NA_CAT_SEP => NA_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_CA_ITEM_SEP => NA_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_CA_CAT_SEP => NA_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_UK_CAT_SEP => NA_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_UK_ITEM_SEP => NA_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_FR_CAT_SEP => FR_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_FR_ITEM_SEP => FR_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_IT_CAT_SEP => IT_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_IT_ITEM_SEP => IT_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_AU_CAT_SEP => NA_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_AU_ITEM_SEP => NA_DRAFT_WATERMARK,
        EMAIL_COUPON_CONTRACT_DE_CAT_SEP_DRAFT => DE_DRAFT_WATERMARK, //SRONG-18.08.2025-US-0033261
        EMAIL_COUPON_CONTRACT_DE_ITEM_SEP_DRAFT => DE_DRAFT_WATERMARK, //SRONG-18.08.2025-US-0033261
        EMAIL_COUPON_CONTRACT_DE_MC_SEP_DRAFT => DE_DRAFT_WATERMARK //LA-03-09-2025-US-0033254
    };

    /* MN-06062024-US-0015298: No longer use Profile Name
    private static String userProf {
        
        get {

            if (String.isBlank(userProf)) {
                for (User u: [SELECT Profile.Name FROM User WHERE Id=:UserInfo.getUserId()]) { userProf = u.Profile.Name; }
            }

            return userProf;
        }

        private set;
    }
    */
    //------MN-05082022-US-0012216

    public String dtNow {get;set;}
    public SEPCouponContractDownloadController()
    {
        renderAsType = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('renderAs')==null?'pdf':ApexPages.currentPage().getParameters().get('renderAs'));//NK:12/02/2022:US-0012187 

        dtNow = System.now().format('M/dd/yyyy, hh:mm a');
        csId  =  String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')==null?'':ApexPages.currentPage().getParameters().get('id'));
        String domain = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('domain')==null?'':ApexPages.currentPage().getParameters().get('domain'));
        String contractAcceptDate = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('contractAcceptDate')==null?'':ApexPages.currentPage().getParameters().get('contractAcceptDate'));  // 11.08.2022 / Sophal Noch / US-0012207
        isDraft = ApexPages.currentPage().getParameters().get('isdraft')=='true' ? true : false;// SB 11.07.2023 US-0012639
        //export pdf as file (save)
        // String asFile = ApexPages.currentPage().getParameters().get('asfile')==null?'':ApexPages.currentPage().getParameters().get('asfile');
        if(String.isBlank(csId))
        {
            throw new ContractDownloadException('Invalid CS Id');
        }        
        Coupon_Seller__c cs = SEPCouponController.getCS(csId);

        // 11.08.2022 / Sophal Noch / US-0012207 : vfpage.getContent() is being run on this vf page and Coupon_Seller__c.Contract_Accept_Date__c. updated previously is also in this same tranaction.
        //                                         vfpage.getContent() does Not get latest record field value until database changes are committed so use contractAcceptDate parameter to populate here to get latest field value.
        cs.Contract_Accept_Date__c = String.isNotBlank(contractAcceptDate) ? Datetime.valueOfGMT(contractAcceptDate) : cs.Contract_Accept_Date__c;
       
        Boolean isCat = cs.Coupon_Type__c==SEPCouponController.COUPON_CATEGORYBASE;

        // String templateName = isCat ? TEMPLATE_CAT : TEMPLATE_ITEM; //MN-05082022-US-0012216        
        // String templateName = mProfEmailTemp.get(userProf).get(cs.Coupon_Type__c); //MN-05082022-US-0012216
        String templateName = '';

        //if(isDraft && userProf == PROF_SEP_DE) { /MN-06062024-US-0015298
        //if(isDraft && SEP_Helper.sepUser.isDE()) { //MN-06062024-US-0015298: use SP Main Domain instead of Profile Name //MN-01082024-US-0015661
        if(isDraft && SEP_Helper.sepUser.isEU()) { //MN-01082024-US-0015661: To allow EU SP Domain to sign DE Coupon Seller
            templateName = mapDEDraftTemplate.get(cs.Coupon_Type__c);
        } else if (mSPMainDomainEmailTemp.containsKey(SEP_Helper.sepUser.domain)) { //MN-14062024-US-0015298
            //templateName = mProfEmailTemp.get(userProf).get(cs.Coupon_Type__c); /MN-06062024-US-0015298
           templateName = mSPMainDomainEmailTemp.get(SEP_Helper.sepUser.domain).get(cs.Coupon_Type__c); //MN-06062024-US-0015298: use SP Main Domain instead of Profile Name 
           
        } 
        //START--MN-01082024-US-0015661: To allow EU SP Domain to sign DE Coupon Seller
        else if (SEP_Helper.sepUser.isEU() && !SEP_Helper.sepUser.isDE()) { 
            templateName = mSPMainDomainEmailTemp.get(SEP_Helper.SEP_Domain_DE).get(cs.Coupon_Type__c);
        }
        //--END

        //NK:22/11/2022:US-0012187
        Boolean isLocalize = MAP_CONTRACT_LOCALIZE.containsKey(cs.Main_Coupon_Site__c+'-'+cs.Coupon_Type__c);
        templateName = isLocalize? MAP_CONTRACT_LOCALIZE.get(cs.Main_Coupon_Site__c+'-'+cs.Coupon_Type__c) :templateName;

        /* MN-01082024-US-0015661: Fixed ApexCRUDViolation from Apex PMD Scan
        EmailTemplate emp = [Select Id,HtmlValue From EmailTemplate WHERE DeveloperName =:templateName];
        htmlContent = emp.HtmlValue;
        */

        String masterCouponId = String.valueOf(cs.Coupon__c).substring(0,15); // 08012026:CSP/US-0033468
        List<Coupon_Seller__c> listProgramCS = SEPCouponController.getSEPContractListProgramCouponSeller(masterCouponId); // 08012026:CSP/US-0033468


        //START--MN-01082024-US-0015661: Fixed ApexCRUDViolation from Apex PMD Scan
        String empQuery = 'Select Id,HtmlValue From EmailTemplate WHERE DeveloperName =:templateName';
        List<EmailTemplate> emailTemplates = ApexSafe.query().secCheck(false).doQuery(empQuery, new Map<String, Object> {'templateName' => templateName});
        for (EmailTemplate emp : emailTemplates) {
            htmlContent = emp.HtmlValue;

            // Start 08012026:CSP/US-0033468
            if(htmlContent.contains('{!programCouponSellerTables}')) {
                String programCouponSellerTables = SEPCouponController.generateProgramCouponSellerHTMLTable(listProgramCS,htmlProgramTableTemplate,emp);
                htmlContent = htmlContent.replace('{!programCouponSellerTables}', programCouponSellerTables);
            }
            //End 08012026:CSP/US-0033468
        }

        htmlContent = htmlContent.replace('{!recordURL}', domain+'/coupon-seller/'+csId);
        
        htmlContent = SEPCouponController.mergeFieldsContractCoupon(htmlContent, cs);
        List<Coupon_Co_Invest__c> listCInvest = SEPCouponController.getListCoinvest(csId);

        String allHtmlRows = populateCatTable(htmlContent,listCInvest,isCat,cs.Main_Coupon_Site__c);// SB 24.02.2023 US-0012755

          //populate table of categories into html table
        htmlContent = htmlContent.replace('{CAT_TABLE_ROWS}',allHtmlRows);        
        //NK:05/02/2022:US-0012187-pdf style border issue. item list (item base) page break at row 30+
        htmlContent = (cs.Coupon_Type__c==COUPON_ITEMBASE && listCInvest.size() <= 29 ? htmlContent.replace('tableHasPaginate',''):htmlContent  );
        //request as file download
        // if(asfile=='1')
        // {            
        //     Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename='+getPDFName(cs.Name));
        // }

        // SB 11.07.2023 US-0012639
        if(isDraft) { watermarkUrl = mapWatermark.get(templateName); }
        
    }

    private static String populateCatTable(String htmlContent,List<Coupon_Co_Invest__c> listCInvest,Boolean isCat,String csSite)
    {
        
        String allHtmlRows = '';
        if(!listCInvest.isEmpty())
        {
            
            for(Coupon_Co_Invest__c cinv : listCInvest)
            {                
                String row = '';
                //Start SB 24.02.2023 US-0012755
                if(csSite == COUPON_SITE_AU){
                    row += doMergeFields(cinv,isCat?HTML_ROW_TEMPLATE_CAT_AU:HTML_ROW_TEMPLATE_ITEM_AU);
                } else {
                    row += doMergeFields(cinv,isCat?HTML_ROW_TEMPLATE_CAT:HTML_ROW_TEMPLATE_ITEM);
                }           
                //End SB 24.02.2023 US-0012755
                allHtmlRows += row;
            } 

        }else
        {
            allHtmlRows = HTML_ROW_TEMPLATE_EMPTY;
        }
        return allHtmlRows;     
    }

    private static String doMergeFields(Coupon_Co_Invest__c cinv,String template)
    {
        String row = template;
        return row.replace('{Coupon_Category__c}',ApexUtil.checkNull(cinv.Category__c)+'')
        .replace('{Category_ID__c}',ApexUtil.checkNull(cinv.Category_ID__c)+'')
        .replace('{Co_Invest__c}',(cinv.Co_Invest__c==null?'':cinv.Co_Invest__c.format()+'%'))
        .replace('{Item_ID__c}',ApexUtil.checkNull(cinv.Item_ID__c)+'')
        .replace('{Item_Title__c}',ApexUtil.checkNull(cinv.Item_Title__c)+'')
        .replace('{Seller_Funding__c}',(cinv.Seller_Funding__c==null?'':cinv.Seller_Funding__c.format()+'%'))// SB 24.02.2023 US-0012755
        ;
    }

    // public Pagereference pageAction()
    // {
    //     String lastatt  = String.escapeSingleQuotes((ApexPages.currentPage().getParameters().get('lastatt')==null?'':ApexPages.currentPage().getParameters().get('lastatt')));
    //     String csId  = String.escapeSingleQuotes((ApexPages.currentPage().getParameters().get('id')==null?'':ApexPages.currentPage().getParameters().get('id')));
    //    if(lastatt=='1' && String.isNotBlank(csId))
    //    { 
    //         String soql = 'Select Id,Name From Attachment ';
    //         String sWhere = 'where ParentId='+ApexUtil.closeSQoute(csId)+' ORDER BY CreatedDate DESC Limit 1';
    //         List<Attachment> listAtt = WithoutSharing.doQuery(soql, sWhere, '');
    //         if(!listAtt.isEmpty())
    //         {
    //             Pagereference pageAtt = new Pagereference('/servlet/servlet.FileDownload?file='+listAtt[0].Id);
    //             pageAtt.getHeaders().put('content-disposition', 'attachment; filename='+listAtt[0].Name);
    //             pageAtt.setRedirect(true);
    //             return pageAtt;
    //         }
            
    //    }

    //     return null;
    // }
    
    /*****************************************************************************************************************************
    @ Method:         createAttachment
    @ Version:        1.0
    @ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        US-0010429 - Ability to sign Agreement in portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.06.2022 / Sambath Seng / US-0010536 - Downloading /storing Coupon Contract on Portal and in Hive
    @ Change history: 11.08.2022 / Sophal Noch / US-0012207 - Changes to contract PDF Download - requested from legal
    @               : 22.11.2022/ SRONG TIN / US-0012185 - [FR] Downloading /storing Coupon Contract on Portal and in Hive
    @               : 11.07.2023 / Sambath Seng / US-0012639 - Allow contract download at contract send, before contract is signed
    *****************************************************************************************************************************/
    public static Map<String,String> createAttachment(Coupon_Seller__c cs)
    {
        Pagereference pdfPage = Page.SEPCouponContractDownloadPage;
        pdfPage.getParameters().put('id',cs.Id);
        pdfPage.getParameters().put('domain',Site.getBaseCustomUrl());
        pdfPage.getParameters().put('contractAcceptDate',(cs.Contract_Accept_Date__c != null ? String.valueOfGMT(cs.Contract_Accept_Date__c ) : '')); // 11.08.2022 / Sophal Noch / US-0012207 send as parameter to vf page to replace value in Coupon_Seller__c.Contract_Accept_Date__c because vfpage.getContent() does Not get latest field value until database changes are committed.
        pdfPage.getParameters().put('isdraft','false');// SB 11.07.2023 US-0012639
        // Blob pageBlob = pdfPage.getContent();
        try 
        {   
            Blob pdfContent = !Test.isRunningTest()?pdfPage.getContent():Blob.valueOf('test');
            //Attachment att = new Attachment(Name=getPDFName(cs),Body=pdfContent,ParentId=cs.Id,Description='SEP Autogenerated',ContentType ='application/pdf'); 
            //WithoutSharing.doInsert(new List<Attachment>{att});
            
            //Attachment attach = [SELECT Id, Name, Body, ContentType, ParentId From Attachment LIMIT 1];
 
            //Insert ContentVersion
            String pdfName = getPDFName(cs);
            ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersion.PathOnClient = pdfName;//File name with extention
            cVersion.Origin = 'C';//C-Content Origin. H-Chatter Origin.
            cVersion.OwnerId = UserInfo.getUserId();//Owner of the file
            cVersion.Title = pdfName;//Name of the file
            cVersion.VersionData = pdfContent;//File content
            cVersion.Description = 'SEP Auto Generated';

            //MN-08082022-US-0012216-Populate NetworkId field in ContentVersion creation for Test Running context to avoid below error
            //Error: INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.: [NetworkId]
            if (Test.isRunningTest()) {
                Id networkId = [SELECT Id FROM Network LIMIT 1].Id;
                cVersion.NetworkId = networkId;
            }

            WithoutSharing.doInsert(new ContentVersion[]{cVersion});
            //After saved the Content Verison, get the ContentDocumentId
            Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
            
            //Insert ContentDocumentLink
            ContentDocumentLink cDocLink = new ContentDocumentLink();
            cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
            cDocLink.LinkedEntityId = cs.Id;//Add attachment parentId
            cDocLink.ShareType = 'V';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            //cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
             
            WithoutSharing.doInsert(new ContentDocumentLink[]{cDocLink});

            return new Map<String,String>{'id'=>cVersion.Id,'name'=>pdfName};
        } catch (DMLException dex) 
        {
            system.debug(dex);throw new ContractDownloadException(dex.getDmlMessage(0));
        }
        
    }

    /*****************************************************************************************************************************
    @ Method:         downloadDraftContractPdf
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0012639 - Allow contract download at contract send, before contract is signed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.07.2023 / Sambath Seng / Create the method
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> downloadDraftContractPdf(String csId,String isDraft)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        try {
            Coupon_Seller__c cs = SEPCouponController.getCS(csId);
            Pagereference pdfPage = Page.SEPCouponContractDownloadPage;
            pdfPage.getParameters().put('id',cs.Id);
            pdfPage.getParameters().put('domain',Site.getBaseCustomUrl());
            pdfPage.getParameters().put('contractAcceptDate',(cs.Contract_Accept_Date__c != null ? String.valueOfGMT(cs.Contract_Accept_Date__c ) : '')); // 11.08.2022 / Sophal Noch / US-0012207 send as parameter to vf page to replace value in Coupon_Seller__c.Contract_Accept_Date__c because vfpage.getContent() does Not get latest field value until database changes are committed.
            pdfPage.getParameters().put('isdraft',isDraft);
            String pdfName = getPDFName(cs);
            mapResult.put('downloadContent', EncodingUtil.base64encode(!Test.isRunningTest() ? pdfPage.getContentAsPdf() : Blob.valueOf('test'))); 
            mapResult.put('fileName',pdfName);

            mapResult.put('status','ok');

        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }

        return mapResult;
        
    }

    /* MN-06062024-US-0015298: No longer use Profile Name
    //MN-25072022-US-0012015
    private static map <String, String> mPDFPrefix = new Map<String, String>{
        // PROF_SEP_DE => 'Coupon-Aktion_',
        PROF_SEP_DE => 'Gutscheinaktion_',// 17.08.2022 / Sophal Noch / US-0012207
        PROF_SEP_NA => 'Coupon-contract_',
        PROF_SEP_DE+'ebay.co.uk' => 'Coupon-contract_', //NK:23/11/2022:US-0012187 - UK to follow NA
        PROF_SEP_DE+'ebay.fr' => 'Bon d\'achat_', //SRONG-22.11.2022-US-0012185
        PROF_SEP_DE+'ebay.it' => 'Coupon_', //SRONG-22.11.2022-US-0012186
        // PROF_SEP_AU => 'Coupon-Contract_'// SB 24.02.2023 US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
        PROF_SEP_AU => 'Coupon Participation accepted_'// SB 02.04.2023 US-0013377 - AU Champion UAT Fixes
    };
    */

    //MN-06062024-US-0015298: Use SP Main Domain instead of Profile Name
    private static map <String, String> mPDFPrefix = new Map<String, String>{
        SEP_Helper.SEP_Domain_DE => 'Gutscheinaktion_',
        SEP_Helper.SEP_Domain_NA => 'Coupon-contract_',
        'ebay.co.uk' => 'Coupon-contract_', 
        'ebay.fr' => 'Bon d\'achat_', 
        'ebay.it' => 'Coupon_', 
        SEP_Helper.SEP_Domain_AU => 'Coupon Participation accepted_'
    };

    /*****************************************************************************************************************************
    @ Method:         getPDFName
    @ Version:        1.0
    @ purpose:         Coupon-Aktion | [Business Name] | [Coupon_ID] | [Marketing Name] | [Start Date]- [End Date]
    @ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)   
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history  : 23.11.2022/vadhank voun/ US-0012187 - [UK] Downloading /storing Coupon Contract on Portal and in Hive
    @                                       File Name: [same file name structure as for NA]
    @                 : 22.11.2022/ SRONG TIN / US-0012186 - [IT] Downloading /storing Coupon Contract on Portal and in Hive
    @                 : 24.02.2023 / Sambath Seng / US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
    @                 : 02.04.2023 / Sambath Seng / US-0013377 - AU Champion UAT Fixes
    *****************************************************************************************************************************/
    private static String getPDFName(Coupon_Seller__c cs)
    {
        
        
        /* MN-06062024-US-0015298: No longer use Profile Name

        //MN-25072022-US-0012015----
        String pdfName = (mPDFPrefix.containsKey(userProf))?mPDFPrefix.get(userProf):'';
        pdfName = mPDFPrefix.containsKey(userProf+cs.Main_Coupon_Site__c)? mPDFPrefix.get(userProf+cs.Main_Coupon_Site__c) : pdfName;

        if(userProf.equals(PROF_SEP_NA) || (SITE_NAME_UK == cs.Main_Coupon_Site__c)){//NK:US-0012187- UK to follow NA format
            pdfName += cs.Seller__r.Name + '_' + cs.Marketing_Coupon_Name__c + '_' + cs.Coupon_Start_Date__c.format().replace('/','-') + ' - ' + cs.Coupon_End_Date__c.format().replace('/','-')+'.pdf';

        }else if (userProf.equals(PROF_SEP_DE)  ){
            //SRONG-22.11.2022-US-0012185
            if(SITE_NAME_FR == cs.Main_Coupon_Site__c){ //here for FR only
                pdfName += cs.Seller__r.Name + '_' + cs.Marketing_Coupon_Name__c+'.pdf';
            //SRONG-22.11.2022-US-0012186
            }else if(SITE_NAME_IT == cs.Main_Coupon_Site__c){ // her for IT only
                pdfName += cs.Seller__r.Name + '_' + cs.Coupon_ID__c + '_'+ cs.Marketing_Coupon_Name__c + '_' + cs.Coupon_Start_Date__c.format().replace('/','-') + ' - ' + cs.Coupon_End_Date__c.format().replace('/','-')+'.pdf';
            }else{
                pdfName += cs.Seller__r.Name + '_' + cs.Coupon_ID__c + '_' + cs.Marketing_Coupon_Name__c + '_' + cs.Coupon_Start_Date__c.format().replace('/','-') + ' - ' + cs.Coupon_End_Date__c.format().replace('/','-')+'.pdf';
            }
            
        } else if (userProf.equals(PROF_SEP_AU)){// SB 24.02.2023 US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
            // pdfName += cs.Seller__r.Name + '_' + cs.Coupon_ID__c + '_' + cs.Marketing_Coupon_Name__c + '_' + cs.Coupon_Start_Date__c.format().replace('/','-') + ' - ' + cs.Coupon_End_Date__c.format().replace('/','-')+'.pdf';
            pdfName += cs.Marketing_Coupon_Name__c + '_' + cs.Seller__r.Name + '_' + cs.Coupon_Start_Date__c.format().replace('/','-') + ' - ' + cs.Coupon_End_Date__c.format().replace('/','-')+'.pdf';// SB 02.04.2023 US-0013377 - AU Champion UAT Fixes
        }
        //----MN-25072022-US-0012015
        */

        String pdfName = (mPDFPrefix.containsKey(SEP_Helper.sepUser.domain))?mPDFPrefix.get(SEP_Helper.sepUser.domain):''; //MN-06062024-US-0015298: use SP Main Domain instead of Profile Name
        pdfName = (SEP_Helper.sepUser.isEU() && mPDFPrefix.containsKey(cs.Main_Coupon_Site__c))? mPDFPrefix.get(cs.Main_Coupon_Site__c) : pdfName; //MN-06062024-US-0015298

        if(SEP_Helper.sepUser.isNA() || (SITE_NAME_UK == cs.Main_Coupon_Site__c)){
            pdfName += cs.Seller__r.Name + '_' + cs.Marketing_Coupon_Name__c + '_' + cs.Coupon_Start_Date__c.format().replace('/','-') + ' - ' + cs.Coupon_End_Date__c.format().replace('/','-')+'.pdf';
        }
        else if ( SEP_Helper.sepUser.isEU()) {

            if(SITE_NAME_FR == cs.Main_Coupon_Site__c){ //here for FR only
                pdfName += cs.Seller__r.Name + '_' + cs.Marketing_Coupon_Name__c+'.pdf';
            
            }else if(SITE_NAME_IT == cs.Main_Coupon_Site__c){ // her for IT only
                pdfName += cs.Seller__r.Name + '_' + cs.Coupon_ID__c + '_'+ cs.Marketing_Coupon_Name__c + '_' + cs.Coupon_Start_Date__c.format().replace('/','-') + ' - ' + cs.Coupon_End_Date__c.format().replace('/','-')+'.pdf';
            }else{
                pdfName += cs.Seller__r.Name + '_' + cs.Coupon_ID__c + '_' + cs.Marketing_Coupon_Name__c + '_' + cs.Coupon_Start_Date__c.format().replace('/','-') + ' - ' + cs.Coupon_End_Date__c.format().replace('/','-')+'.pdf';
            }
            
        }
        else if (SEP_Helper.sepUser.isAU()){
            pdfName += cs.Marketing_Coupon_Name__c + '_' + cs.Seller__r.Name + '_' + cs.Coupon_Start_Date__c.format().replace('/','-') + ' - ' + cs.Coupon_End_Date__c.format().replace('/','-')+'.pdf';
        }

        return pdfName;
        

        //MN-25072022-US-0012015
        //return 'Coupon-Aktion_'+cs.Seller__r.Name+'_'+cs.Coupon_ID__c+'_'+cs.Marketing_Coupon_Name__c+'_'+cs.Coupon_Start_Date__c.format().replace('/','-')+' - '+cs.Coupon_End_Date__c.format().replace('/','-')+'.pdf';
        //return csName+'-'+System.now().format('MMddyyyyhhmmss')+'.pdf';
    }
   

    class ContractDownloadException extends Exception{}
}