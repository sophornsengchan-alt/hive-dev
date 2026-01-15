/*

When a seller is approving their deal(s). A PDF version of the Seller Approval page should be created and an email sent to the person that signed the approval page.

*/
/*************************************************************************************************************************************
@ Class:          DocumentApprovalControllerPDF
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0008130 - [US]* Deals External Seller Bulk/Mass Approval Functionality
@ TestClass       DocumentApprovalControllerTest                      
--------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.10.2020 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / moved from join instance
--------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 07.09.2021 / Mony Nou (mony.nou@gaea-sys.com) / US-0010019 - [NA] Subsidized Deals Contract Amendment Process
@               : 08.01.2024 / SRONG TIN / US-0014252 - NA Region (US): New field on Deal record & Contract agreement to determine subsidy type
@               : 08.03.2024 / Mony Nou / US-0014252 - NA Region (US Only): New field on Deal record & Contract agreement to determine subsidy type
@               : 28.03.2024 / Mony Nou / US-0015032 - Additional Logic to support the release process for US-0014252 & US-0014788
**************************************************************************************************************************************
*/
public class DocumentApprovalControllerPDF extends DocumentApprovalController{

    public boolean isAmendmentDeal {get;set;}

    public boolean isNA {get;set;}

    public boolean hasSubsidyPercentage {get;set;} //MN-28032024-US-0015032

    private final static Set<String> SET_APPROVAL_STATUS = new Set<String>{'Seller Approved', 'Seller Rejected', 'Running', 'Completed'};

    public DocumentApprovalControllerPDF(){

        // we use dca id and we filter on deals planned     
        //String dcaid = ApexPages.currentPage().getParameters().get('dcaid'); //MN-08092021 - Change to use with proper method:getParamValue()
        String dcaid = getParamValue('dcaid'); //MN-08092021
        String is_ad = getParamValue('is_ad'); //MN-08092021-US-0010019

        isAmendmentDeal = (String.isNotBlank(is_ad) && is_ad.equalsIgnoreCase('1'));

        hasSubsidyPercentage = false; //MN-28032024-US-0015032
        isNA = false; //MN-28032024-US-0015032

        getDealRecords(dcaid);
        
    }
    
    private String getParamValue(String urlparam) {
        String val = '';
        if (ApexPages.currentPage().getParameters().containsKey(urlparam)) {
            String tmp = ApexPages.currentPage().getParameters().get(urlparam);
            if (String.isNotBlank(tmp)) val = String.escapeSingleQuotes(tmp); 
        }
        
        return val;
    }

    //MN-08092021-US-0010019 - New method so it could work for both normal Deals & Amendment Deals
    public void getDealRecords(String dcaid){

        String NA_DEAL_RECORDTYPE = 'Deal_V2';
        String ORIGINAL_DCA = '{ORIGINAL_DCA}';
        // SRONG/08.01.2024/US-0014252 
        String query = 'Select d.EBH_Quantity__c,d.EBH_MaximumPurchases__c,d.EBH_RRPWASPrice__c, d.EBH_eBayLink__c, d.EBH_BusinessName__c, d.EBH_CommentfromeBaySourcer__c,' +
        'd.EBH_ProductTitle__c, d.EBH_DealEndDate__c, d.EBH_DealStartDate__c, d.EBH_DealEndTime__c, EBH_DealStartTime__c,d.eBay_Seller_Name__c, d.EBH_eBayItemID__c, d.EBH_Vertical__c,' +
        'd.EBH_DealCalendarDescription__c, d.EBH_CommentfromSeller__c, d.EBH_Status__c, d.EBH_Category__c, d.Deal_Contract_Agreement__c, d.Deal_Contract_Agreement__r.CreatedById,' +
        'd.Quantity_Limitation_per_Purchaser__c, d.EBH_DealFormat__c, d.EBH_DealPrice__c,d.List_Price__c, d.EBH_SellerPrice__c, d.EBH_Subsidy__c, d.ListPriceMSKULower__c, ' + 
        'd.ListPriceMSKUUpper__c, d.SellersDealPriceMSKULower__c, d.SellersDealPriceMSKUUpper__c, d.SellersOfferPriceMSKULower__c, d.SellersOfferPriceMSKUUpper__c, Deal_Contract_Agreement__r.Current_Digest__c, ' + 
        'd.Name, d.Optional_Notes__c, d.EBH_DealSiteId__c, d.Amendment_Date__c, d.Originating_Deal__c,d.Originating_Deal__r.Deal_Contract_Agreement__r.Name, d.Reason_for_Amendment__c, d.RecordType.DeveloperName, d.EBH_SubsidyP__c, d.Subsidy_Type__c ' +
        'From EBH_Deal__c d where Deal_Contract_Agreement__c =:dcaid and EBH_Status__c IN: SET_APPROVAL_STATUS'; // 21.12.2021 / Sophal Noch / US-0010858 include status = 'Running', 'Completed' in query

        query += (this.isAmendmentDeal)?' AND RecordType.DeveloperName=:NA_DEAL_RECORDTYPE AND Originating_Deal__c != NULL AND Amendment_Date__c != NULL':' AND Amendment_Date__c = NULL';

        List<EBH_Deal__c> deals = (List<EBH_Deal__c>) Database.query(query);
        Integer count = 0;
        for(EBH_Deal__c d: deals){

            if (count == 0) { //MN-08032024-US-0014252:AC2: Only check once
                this.isNA = (d.EBH_DealSiteId__c == '0'); 
                count++; 
            }

            //MN-28032024-US-0015032: Check Subsidy Type = Percentage for NA region only
            if (this.isNA && !this.hasSubsidyPercentage && String.isNotBlank(d.Subsidy_Type__c) && d.Subsidy_Type__c == 'Percentage') this.hasSubsidyPercentage = true; 

            DealWrapper dw = new DealWrapper(d.Id, 
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
                                                d.EBH_RRPWASPrice__c,
                                                d.Optional_Notes__c, 
                                                d.EBH_DealSiteId__c,
                                                d.EBH_SubsidyP__c,
                                                d.Subsidy_Type__c);

            if (this.isAmendmentDeal) {
                dw.reason_amendment = d.Reason_for_Amendment__c;
                String tmp = Label.DD_AmendmentDeal_Form;
                dw.original_dca = tmp.replace(ORIGINAL_DCA, d.Originating_Deal__r.Deal_Contract_Agreement__r.Name);
            }
            
            dealsWrapper.add(dw);
        }  
    }

    //MN-28032024-US-0015032: Show new version for NA region only and only when at least a deal has Subsidy Type = Percentage
    public Boolean getShowVersion2() {
        return this.isNA && this.hasSubsidyPercentage;
    }
    
    /* MN-08092021-US-0010019
    public void getDealRecords(String dcaid){
        
        List<EBH_Deal__c> deals = [Select d.EBH_Quantity__c,d.EBH_MaximumPurchases__c,d.EBH_RRPWASPrice__c, d.EBH_eBayLink__c, d.EBH_BusinessName__c, d.EBH_CommentfromeBaySourcer__c,
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
                                Deal_Contract_Agreement__r.Current_Digest__c,
                                d.Name,
                                d.Optional_Notes__c,
                                d.EBH_DealSiteId__c,
                                d.Amendment_Date__c, d.Originating_Deal__c, d.RecordType.DeveloperName //MN-07092021-US-0010019
                                From EBH_Deal__c d 
                                where Deal_Contract_Agreement__c =:dcaid
                                and (EBH_Status__c = 'Seller Approved' OR EBH_Status__c = 'Seller Rejected')
                                ];
                                
        // populate the wrapper to be displayed
       // System.debug('<<<<<DealsPDF page='+deals);
        for(EBH_Deal__c d: deals){
            
            //MN-07092021-US-0010019
            DealWrapper dw = new DealWrapper(d.Id, 
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
                                                d.Optional_Notes__c, d.EBH_DealSiteId__c);
            
            dw.isNAAmendmentDeal = (d.RecordType.DeveloperName == 'Deal_V2' && d.Originating_Deal__c != null && d.Amendment_Date__c != null); 
            dealsWrapper.add(dw);
        }  
       // System.debug('<<<<<dealsWrapper='+dealsWrapper);             
    }
    */
}