/*********************************************************************************************************************************
@ Class:          SEPDCAContractDownloadController
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        Controller vf page: SEPDCAContractDownloadPage
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.09.2022 / Mony Nou / Created the class.
@                 06/06/2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
@                 17/10/2025 / Mony Nou / US-0033377 - US PM Deals Seller Contract Update
*********************************************************************************************************************************/
public with sharing class SEPDCAContractDownloadController {

    public String dcaId {get;set;}
    public String htmlContent {get;set;}

    private final static String PROF_SEP_NA = 'NA - Seller Portal';
    private final static String EMAIL_PMDEAL_CONTRACT_NA = 'NA_PMDeal_Contract_SEP_Download';
    private final static String QUERYDCA = 'SELECT PM_Id__c, eBay_Seller__r.Name, eBay_Seller__r.EBH_RevRollup__c, Title__c, eBay_Funding__c, Deal_Page_Placement__c, Deal_Start_Date__c, Deal_Start_Time__c, Deal_End_Date__c, Deal_End_Time__c, Discount_Applied_in_Cart__c, Max_Total_Subsidy__c, Max_Unit_Subsidy__c, CurrencyIsoCode FROM Deal_Contract_Agreement__c WHERE Id=:dcaId';

    /* MN-06062024-US-0015298: No longer use Profile Name
    Map<String, String> mProfEmailTemp = new Map<String, String> {
        PROF_SEP_NA => EMAIL_PMDEAL_CONTRACT_NA
    };
    */

    //MN-06062024-US-0015298: Use SP Main Domain instead of Profile Name
    Map<String, String> mSPMainDomainEmailTemp = new Map<String, String> {
        SEP_Helper.SEP_Domain_NA => EMAIL_PMDEAL_CONTRACT_NA
    };

    private static String userProf {
        
        get {

            if (String.isBlank(userProf)) {
                for (User u: [SELECT Profile.Name FROM User WHERE Id=:UserInfo.getUserId()]) { userProf = u.Profile.Name; }
            }

            return userProf;
        }

        private set;
    }  

    public SEPDCAContractDownloadController() {

        dcaId  =  String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')==null?'':ApexPages.currentPage().getParameters().get('id'));
        if(String.isBlank(dcaId)) { throw new ContractDownloadException('Invalid PM Deal Id'); } 
        
        Deal_Contract_Agreement__c dca = new Deal_Contract_Agreement__c();

        //MN-17102025-US-0033377: Added field PM_Id__c and use ApexSafe.query() instead of direct SOQL
        for (Deal_Contract_Agreement__c tmp : (List<Deal_Contract_Agreement__c>) ApexSafe.query().doQuery(QUERYDCA, new Map<String, Object> {'dcaId' => dcaId})) { dca = tmp; }
        
        String templateName = (mSPMainDomainEmailTemp.containsKey(SEP_Helper.sepUser.domain))?mSPMainDomainEmailTemp.get(SEP_Helper.sepUser.domain):EMAIL_PMDEAL_CONTRACT_NA; //MN-06062024-US-0015298: Use SP Main Domain instead of Profile Name
        String query = 'Select Id,HtmlValue From EmailTemplate WHERE DeveloperName =:templateName';
        List<EmailTemplate> empList = (List<EmailTemplate>) ApexSafe.query().secCheck(false).doQuery(query, new Map<String, Object> {'templateName' => templateName});

        htmlContent = (!empList.isEmpty())?empList[0].HtmlValue:'';
        htmlContent = mergeFieldsPMDealContract(htmlContent, dca);
    }


    /*****************************************************************************************************************************
    @ Method:         mergeFieldsPMDealContract
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        US-0012359 - PM Deals: Downloading /storing Deal Contract on Portal and in Hive
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String s, Deal_Contract_Agreement__c dca
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.09.2022 / Mony Nou / Create the method
    @                 17.10.2025 / Mony Nou / US-0033377 - US PM Deals Seller Contract Update
    *****************************************************************************************************************************/
    public static String mergeFieldsPMDealContract(String s, Deal_Contract_Agreement__c dca) 
 	{
        SEPDownloadController.DCAWrapper dw = new SEPDownloadController.DCAWrapper(dca);
        return s==null?'':s
        .replace('{eBaySellerID}',dw.eBaySellerID)
        .replace('{Title}',dw.title)
        .replace('{eBayFunding}',dw.eBayFunding)
        .replace('{DealPagePlacement}',dw.dealPagePlacement)
        .replace('{DealStartDate}',dw.formatDealStartDate) 
        .replace('{DealStartTime}',dw.dealStartTime) 
        .replace('{DealEndDate}',dw.formatDealEndDate) 
        .replace('{DealEndTime}',dw.dealEndime)
        .replace('{DiscountAppliedinCart}',dw.discountAppliedinCart)
        .replace('{MaxTotalSubsidy}',dw.maxTotalSubsidy)
        .replace('{MaxUnitSubsidy}',dw.maxUnitSubsidy)
        .replace('{PMContractNo}',dw.pmId) //MN-17102025-US-0033377
        .replace('{PMContractLink}',dw.pmIdLink) //MN-17102025-US-0033377
        ;
 	}

    /*****************************************************************************************************************************
    @ Method:         createAttachment
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        US-0012359 - PM Deals: Downloading /storing Deal Contract on Portal and in Hive
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.09.2022 / Mony Nou / Create the method
    *****************************************************************************************************************************/
    public static Map<String,String> createAttachment(Deal_Contract_Agreement__c dca)
    {
        Pagereference pdfPage = Page.SEPDCAContractDownloadPage;
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
            system.debug(dex);throw new ContractDownloadException(dex.getDmlMessage(0));
        }
        
    }

    
    private static String getPDFName(Deal_Contract_Agreement__c dca)
    {
        
        String pdfName = '';

        //if(userProf.equals(PROF_SEP_NA)) pdfName += dca.Title__c + '_' + dca.eBay_Seller__r.Name + '_' + dca.Deal_Start_Date__c.format().replace('/','-') + ' - ' + dca.Deal_End_Date__c.format().replace('/','-')+'.pdf'; //MN-06062024-US-0015298: No longer use Profile Name
        if(SEP_Helper.sepUser.isNA()) pdfName += dca.Title__c + '_' + dca.eBay_Seller__r.Name + '_' + dca.Deal_Start_Date__c.format().replace('/','-') + ' - ' + dca.Deal_End_Date__c.format().replace('/','-')+'.pdf'; //MN-06062024-US-0015298: Use SP Main Domain instead of Profile Name
        
        return pdfName;
        
    }

    class ContractDownloadException extends Exception{}
}