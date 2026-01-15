/*********************************************************************************************************************************
@ Class:          SubsidizeDCAContractDownloadController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Controller vf page: SubsidizeDCAContractDownloadPage
@                 US-0016373 - 14 - Seller Portal - Contract Sign Off 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.03.2025 / Sovantheany Dim / Created the class.
*********************************************************************************************************************************/
public with sharing class SubsidizeDCAContractDownloadController {
    public String dcaId {get;set;}
    public String htmlContent {get;set;}
    private Static Final String SUBSIDIZE_DCA_TERM_DOWNLOAD_SEP = 'Subsidize_DCA_Term_Download_SEP';
    private String soqlDCA = 'SELECT Name, Id FROM Deal_Contract_Agreement__c WHERE Id=:dcaId';
    private String soqlEmailTemplate = 'Select Id,HtmlValue From EmailTemplate WHERE DeveloperName =: emailTemplateName';
    public SubsidizeDCAContractDownloadController() {
        dcaId  =  String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')==null?'':ApexPages.currentPage().getParameters().get('id'));
        Deal_Contract_Agreement__c dca = new Deal_Contract_Agreement__c();
        for (Deal_Contract_Agreement__c tmp : (List<Deal_Contract_Agreement__c>) ApexSafe.query().doQuery(soqlDCA,new Map<String, Object> {'dcaId' => dcaId})){ dca = tmp; }
        
        List<EmailTemplate> lstEmailTemplate = (List<EmailTemplate>) ApexSafe.query().secCheck(false).doQuery(soqlEmailTemplate,new Map<String, Object> {'emailTemplateName' => SUBSIDIZE_DCA_TERM_DOWNLOAD_SEP});
        EmailTemplate emp = lstEmailTemplate.isEmpty()?new EmailTemplate():lstEmailTemplate[0];
        htmlContent = emp.HtmlValue;
        htmlContent = mergeFieldsSubsidizeDealContract(htmlContent, dca);
    }

    /*****************************************************************************************************************************
    @ Method:         mergeFieldsSubsidizeDealContract
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0016373 - 14 - Seller Portal - Contract Sign Off 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String s, Deal_Contract_Agreement__c dca
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.03.2025 / Sovantheany Dim / Create the method
    *****************************************************************************************************************************/
    public static String mergeFieldsSubsidizeDealContract(String s, Deal_Contract_Agreement__c dca) 
 	{
        return s==null?'':s
        .replace('{DCAIDLink}',Site.getBaseCustomUrl()+'/s/deal-list-view?id='+dca.Id+'&tabset=Approved Deals')
        .replace('{DCA_Name}',dca.Name)
        ;
 	}

    /*****************************************************************************************************************************
    @ Method:         createAttachment
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0016373 - 14 - Seller Portal - Contract Sign Off 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.03.2025 / Sovantheany Dim / Create the method
    *****************************************************************************************************************************/
    public static Map<String,String> createAttachment(Deal_Contract_Agreement__c dca)
    {
        Pagereference pdfPage = Page.SubsidizeDCAContractDownloadPage;
        pdfPage.getParameters().put('id',dca.Id);
        
        try {   

            Blob pdfContent = !Test.isRunningTest()?pdfPage.getContent():Blob.valueOf('test');
            
            //Insert ContentVersion
            String pdfName = getPDFName(dca);
            ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersion.PathOnClient = pdfName;//File name with extention
            cVersion.Origin = 'C';//C-Content Origin. H-Chatter Origin.
            cVersion.OwnerId = UserInfo.getUserId();//Owner of the file
            cVersion.Title = pdfName;//Name of the file
            cVersion.VersionData = pdfContent;//File content
            cVersion.Description = 'SEP Auto Generated';

            //Populate NetworkId field in ContentVersion creation for Test Running context to avoid below error
            //Error: INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.: [NetworkId]
            if (Test.isRunningTest()) {
                Id networkId = [SELECT Id FROM Network LIMIT 1].Id;
                cVersion.NetworkId = networkId;
            }

            ApexSafe.dml().secCheck(false).doInsert(new List<ContentVersion>{cVersion},true);
            
            //After saved the Content Verison, get the ContentDocumentId
            String conVersionSoql = 'SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersionId';
            List<ContentVersion> lstConVersionSoql = (List<ContentVersion>) ApexSafe.query().secCheck(false).doQuery(conVersionSoql,new Map<String, Object> {'cVersionId' => cVersion.id});
            Id conDocument = lstConVersionSoql[0].ContentDocumentId;
            
            ContentDocumentLink cDocLink = new ContentDocumentLink();
            cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
            cDocLink.LinkedEntityId = dca.Id;//Add attachment parentId
            cDocLink.ShareType = 'V';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
             
            ApexSafe.dml().secCheck(false).doInsert(new List<ContentDocumentLink>{cDocLink},true);

            return new Map<String,String>{'id'=>cVersion.Id,'name'=>pdfName};

        } catch (DMLException dex) 
        {
            throw new ContractDownloadException(dex.getDmlMessage(0));
        }
        
    }

    private static String getPDFName(Deal_Contract_Agreement__c dca)
    {
        String pdfName = 'Deals Agreement_' + dca.Name + '_' + dca.Title__c + '_' + dca.CreatedDate + '.pdf';
        return pdfName;
        
    }

    class ContractDownloadException extends Exception{}
}