/*********************************************************************************************************************************
@ Class:          PMDealItemDownloadController
@ Version:        1.0
@ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
@ Purpose:        Controller vf page: PMDealItemDownloadPage
                  US-0012283 - Submit Deal Contract Agreement(AC2)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.06.2022 / Loumang SENG / Created the class.
@               : 28.09.2022 / SRONG TIN / US-0012275 - Ability to View Deals Uploaded against a Contract Agreement
@               : 07.10.2022 / Sovantheany Dim / US-0012741 - New column to upload Deals to Deal Contract Agreement
@               : 10.10.2022 / vadhanak voun/ US-0012764 - [Bug] Download of items - PM Deals
@               : 27.10.2022 / Mony Nou/ US-0012841 - Download Items PM Deals
@               : 07.06.2023 / Sambath Seng / US-0013316 - Cancelled Items - Seller Portal
@               : 05-12-2023 /SRONG TIN/ US-0014342 - Regression test issue on DE / NA Feature process
*********************************************************************************************************************************/
public with sharing class PMDealItemDownloadController {
    public string xmlheader{ get{return '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';}}
    public string currentUser{get;set;}
    //private List<EBH_Deal__c> listDeals {get;set;}
    private final static String IN_REVIEW_STATUS = 'In Review';
    private final static String PM_DEAL_RECORDTYPE = 'Promotions_Manager_Deals';
    //MN-27102022-US-0012841-Added field Deal_Contract_Agreement__r.PM_Id__c into below query
    // SB 7.6.2023 US-0013316 Added field Cancellation_Reason__c to query
    private final static String SOQL_PM_DEAL = 'SELECT Id,EBH_ProductTitle__c,EBH_Quantity__c,EBH_eBayItemID__c,EBH_SellerPrice__c,EBH_RRPWASPrice__c,Deal_Price_Seller_Portal__c, Deal_Contract_Agreement__r.PM_Id__c,Cancellation_Reason__c FROM EBH_Deal__c';//TH:US-0012741: add EBH_RRPWASPrice__c

    private final Integer ROW_LIMIT = 1000; //apex:repeat limit 1000
    public List<List<EBH_Deal__c>> listChunkDeals{get;set;}

    public String dca_PMID {get;set;} //MN-27102022-US-0012841

    public PMDealItemDownloadController(){
        String dcaId = String.escapeSingleQuotes(String.isBlank(ApexPages.currentPage().getParameters().get('id')) ? '': ApexPages.currentPage().getParameters().get('id'));
        currentUser = UserInfo.getUserName();
        
        listChunkDeals = new List<List<EBH_Deal__c>>();
        if(String.isNotBlank(dcaId)){
            List<EBH_Deal__c> listDeals = getPMDeals(dcaId);
            if (!listDeals.isEmpty()) dca_PMID = listDeals[0].Deal_Contract_Agreement__r.PM_Id__c; //MN-27102022-US-0012841

            Map<String,Object> mapResult = ApexUtil.chunkListSOBJ(listDeals, ROW_LIMIT);

            listChunkDeals = (List<List<EBH_Deal__c>>)mapResult.get('listAllChunk');
             
        }

    }    
     

    /*****************************************************************************************************************************
    @ Method:         getPMDeals
    @ Version:        1.0
    @ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
    @ Purpose:        US-0012283 - Submit Deal Contract Agreement
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dcaId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.09.2022 / Loumang SENG / Created the method
    @               : 28.09.2022 / SRONG TIN / US-0012275 - Ability to View Deals Uploaded against a Contract Agreement
    *****************************************************************************************************************************/
    private static List<EBH_Deal__c> getPMDeals(String dcaId){
        // SRONG TIN / 28.09.2022 / US-0012275 
        //' AND Deal_Contract_Agreement__r.SellerPortal_Status__c =' + ApexUtil.closeSQoute(IN_REVIEW_STATUS) +
        String sWhere = ' WHERE Deal_Contract_Agreement__c ='+ ApexUtil.closeSQoute(dcaId) + ' AND Deal_Contract_Agreement__r.RecordType.DeveloperName=' + ApexUtil.closeSQoute(PM_DEAL_RECORDTYPE);
        return Database.query(SOQL_PM_DEAL+sWhere);
    }

    /*****************************************************************************************************************************
    @ Method:         getPMDealItemDownloadExcel
    @ Version:        1.0
    @ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
    @ Purpose:        US-0012283 - Submit Deal Contract Agreement
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dcaId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.09.2022 / Loumang SENG / Created the method
    @               : 05-12-2023 /SRONG TIN/ US-0014342 - Regression test issue on DE / NA Feature process
    *****************************************************************************************************************************/
    @AuraEnabled
    public static List<DealItemsDTO> getPMDealItemDownloadExcel(String dcaId) {
        List<DealItemsDTO> dealsItems = new List<DealItemsDTO>();
        Integer ROW_LIMIT = 1000;
        if(String.isNotBlank(dcaId)){
            List<EBH_Deal__c> listDeals = getPMDeals(dcaId); 
            for(EBH_Deal__c deal: listDeals){
                dealsItems.add(new DealItemsDTO(deal));
            }
        }
        return dealsItems;
    }

    public class DealItemsDTO{
        @AuraEnabled
        public String eBayItemID{get;set;}
        @AuraEnabled
        public String itemTitle{get;set;}
        @AuraEnabled
        public Decimal sellerPrice{get;set;}
        @AuraEnabled
        public Decimal rRPPrice{get;set;}
        @AuraEnabled
        public Decimal dealPrice{get;set;}
        @AuraEnabled
        public Decimal quantity{get;set;}
        @AuraEnabled
        public String cancellationReason{get;set;}
        
        public DealItemsDTO(EBH_Deal__c deal){
            this.eBayItemID = deal.EBH_eBayItemID__c;
            this.itemTitle = deal.EBH_ProductTitle__c;
            this.sellerPrice = deal.EBH_SellerPrice__c;
            this.rRPPrice = deal.EBH_RRPWASPrice__c;
            this.dealPrice = deal.Deal_Price_Seller_Portal__c;
            this.quantity = deal.EBH_Quantity__c;
            this.cancellationReason = deal.Cancellation_Reason__c;  
        }
    }

}