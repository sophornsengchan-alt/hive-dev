/*********************************************************************************************************************************
@ Class:          SEPDCADownloadController
@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal 
                  Controller vf page: SEPDCADownload
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.05.2023 / Sambath Seng / Created the class.
@               : 15.02.2024 / Mony Nou / US-0014491 - [Tech Debt] Remove dependency from URL Domain and replace with SP Main Domain Field in SEP Features
*********************************************************************************************************************************/
public with sharing class SEPDCADownloadController {

    public String dcaId {get;set;}
    public String htmlContent {get;set;}
    private static String currentDomain {get;set;}
    private final static String SEP_DOMAIN_IT = SEP_Helper.SEP_Domain_IT;
    private final static String EMAIL_DCA_IT = 'IT_DCA_Download_SEP';
    private final static String SOQL_DEAL = 'Select EBH_eBayItemID__c,eBay_Seller_Name__c,EBH_ProductTitle__c,EBH_Quantity__c,EBH_DealPrice__c,EBH_SellerPrice__c,EBH_Subsidy__c,Subsidy_Planned_Gross__c,Deal_Start_Date_Time__c,Deal_End_Date_Time__c From EBH_Deal__c ';
    private final static Map<String,String> MAP_EMAILEMPLATE_DOMAIN = new Map<String,String>{
        SEP_DOMAIN_IT => EMAIL_DCA_IT
    };
    private static map <String, String> mPDFPrefix = new Map<String, String>{
        SEP_DOMAIN_IT => 'Contratto_Offerte_Imperdibili_'
    };
    private final static String SOQL_DCA = 'Select Id,Name,CreatedDate,CreatedBy.Name From Deal_Contract_Agreement__c ' ;
    private final static String Deals_Table_Template_Header = '<table border="1" class="ql-table" style="border-collapse: collapse;margin-bottom:20px">{!row}</table>';

    public SEPDCADownloadController(){

        dcaId = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')==null?'':ApexPages.currentPage().getParameters().get('id')); 
    
        Deal_Contract_Agreement__c dca = getDCA(dcaId);
        List<EBH_Deal__c> lstDeals = getDealRecords(dcaId);
        //currentDomain = SEP_Helper.getCurrentDomain(); //MN-15022024-US-0014491
        currentDomain = SEP_Helper.getSPMainDomain(); //MN-15022024-US-0014491
        String templateName = MAP_EMAILEMPLATE_DOMAIN.get(currentDomain) != null ? MAP_EMAILEMPLATE_DOMAIN.get(currentDomain):EMAIL_DCA_IT;
        EmailTemplate emp = [Select Id,HtmlValue From EmailTemplate WHERE DeveloperName =:templateName];
        htmlContent = emp.HtmlValue;
        htmlContent = htmlContent
        .replace('{HTML_TABLE_CONTENT}', generateHtmlContentTable(lstDeals))
        .replace('{!dcaSignBy}', dca.CreatedBy.Name)
        .replace('{!dcaSignDateTime}', dca.CreatedDate.format())
        ;

    }

    /*****************************************************************************************************************************
    @ Method:         getDealRecords
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dcaId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.05.2023 / Sambath Seng / Create method
    *****************************************************************************************************************************/
    private static List<EBH_Deal__c> getDealRecords(String dcaId){
        return Database.query(SOQL_DEAL + 'WHERE Deal_Contract_Agreement__c =: dcaId');
    }

    /*****************************************************************************************************************************
    @ Method:         generateHtmlContentTable
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<EBH_Deal__c> lstDeals
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.05.2023 / Sambath Seng / Create method
    *****************************************************************************************************************************/
    private static String generateHtmlContentTable(List<EBH_Deal__c> lstDeals){
        if(lstDeals==null) return '';

 		String htmlTableTemplate = System.label.SEPDCADownload_HtmlTableTemplate;
        String htmlString = '';
        for(EBH_Deal__c oDeal : lstDeals){
            htmlString += '<table border="1" class="ql-table" style="border-collapse: collapse;margin-top:27px;margin-bottom:27px;">' + htmlTableTemplate
            .replace('{!ebayItemID}',ApexUtil.checkNull(oDeal.EBH_eBayItemID__c) + '')
            .replace('{!sellerName}',ApexUtil.checkNull(oDeal.eBay_Seller_Name__c) + '')
            .replace('{!productTitle}',ApexUtil.checkNull(oDeal.EBH_ProductTitle__c) + '')
            .replace('{!quantity}',ApexUtil.checkNull(oDeal.EBH_Quantity__c) + '')
            .replace('{!dealPrice}',ApexUtil.checkNull(oDeal.EBH_DealPrice__c) + '')
            .replace('{!sellerPrice}',ApexUtil.checkNull(oDeal.EBH_SellerPrice__c) + '')
            .replace('{!subsidyPerSoldItem}',ApexUtil.checkNull(oDeal.EBH_Subsidy__c) + '')
            .replace('{!subsidyPlannedGross}',ApexUtil.checkNull(oDeal.Subsidy_Planned_Gross__c) + '')
            .replace('{!dealStartDateTime}',oDeal.Deal_Start_Date_Time__c)
            .replace('{!dealEndDateTime}',oDeal.Deal_End_Date_Time__c) 
            + '</table>'
            ;
        }
 		return htmlString;
    }

    /*****************************************************************************************************************************
    @ Method:         createAttachment
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Deal_Contract_Agreement__c dca
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.05.2023 / Sambath Seng / Create method
    *****************************************************************************************************************************/
    public static Map<String,String> createAttachment(Deal_Contract_Agreement__c dca)
    {
        Pagereference pdfPage = Page.SEPDCADownloadPage;
        pdfPage.getParameters().put('id',dca.Id);

        try 
        {   
            Blob pdfContent = !Test.isRunningTest()?pdfPage.getContent():Blob.valueOf('test');

            String pdfName = getPDFName(dca);
            ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersion.PathOnClient = pdfName;//File name with extention
            cVersion.Origin = 'C';//C-Content Origin. H-Chatter Origin.
            cVersion.OwnerId = UserInfo.getUserId();//Owner of the file
            cVersion.Title = pdfName;//Name of the file
            cVersion.VersionData = pdfContent;//File content
            cVersion.Description = 'SEP Auto Generated';

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
            cDocLink.LinkedEntityId = dca.Id;//Add attachment parentId
            cDocLink.ShareType = 'V';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
             
            WithoutSharing.doInsert(new ContentDocumentLink[]{cDocLink});

            return new Map<String,String>{'id'=>cVersion.Id,'name'=>pdfName};
        } catch (DMLException dex) 
        {
            system.debug(dex);throw new DCADownloadException(dex.getDmlMessage(0));
        }
        
    }

    /*****************************************************************************************************************************
    @ Method:         getPDFName
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ purpose:        US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Deal_Contract_Agreement__c dca
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.05.2023 / Sambath Seng / Create method
    *****************************************************************************************************************************/
    private static String getPDFName(Deal_Contract_Agreement__c dca)
    {
        String pdfName = (mPDFPrefix.containsKey(currentDomain))?mPDFPrefix.get(currentDomain):'Contratto_Offerte_Imperdibili_';
        pdfName += dca.Name + '_' + dca.CreatedDate + '.pdf';
        return pdfName;
    }


    /*****************************************************************************************************************************
    @ Method:         getDCA
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dcaId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.05.2023 / Sambath Seng / Create method
    *****************************************************************************************************************************/
    public static Deal_Contract_Agreement__c getDCA(String dcaId){
        return Database.query(SOQL_DCA + ' WHERE Id =: dcaId LIMIT 1');
    }

    class DCADownloadException extends Exception{}
}