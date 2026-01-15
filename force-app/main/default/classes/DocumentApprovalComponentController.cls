/*************************************************************************************************************************************
@ Class:          DocumentApprovalComponentController
@ Version:        1.0
@ Author:         LoumAng SENG (loumang.seng@gaea-sys.com)
@ Purpose:        US-0008841 - [NA] Migrate JOIN NA Deals Workflow Rules and convert to Process Builder in Hive             
--------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.12.2020 / LoumAng SENG (loumang.seng@gaea-sys.com) / moved from join instance
--------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 28.02.2022 / Mony Nou (mony.nou@gaea-sys.com) / Updated the class for US-0010984 - Emails are sent to other sellers when cancelling Subsidized deals
@                 10.01.2024 / Sambath Seng / US-0014252 - NA Region (US): New field on Deal record & Contract agreement to determine subsidy type
--------------------------------------------------------------------------------------------------------------------------------------
*/
public class DocumentApprovalComponentController {
    public String dealStatus {get;set;}
    public String dealAgreementlId {get;set;}
    public String dealId {get;set;}
    public Boolean isPreview {get;set;} //MN-28022022-US-0010984

    public List<DocumentApprovalController.DealWrapper> getdealsWrapper(){
        List<EBH_Deal__c> deals = new List<EBH_Deal__c>();
        if(dealId==null){

            //MN-28022022-US-0010984===
            String query = 'Select d.Id, d.EBH_Quantity__c,d.EBH_MaximumPurchases__c,d.EBH_RRPWASPrice__c,d.EBH_eBayLink__c, d.EBH_BusinessName__c, d.EBH_CommentfromeBaySourcer__c,Seller_Approver_1__c,d.EBH_ProductTitle__c, d.EBH_DealEndDate__c, d.EBH_DealStartDate__c,'
            + 'd.EBH_DealEndTime__c, EBH_DealStartTime__c,d.eBay_Seller_Name__c, d.EBH_eBayItemID__c, d.EBH_Vertical__c, d.EBH_DealCalendarDescription__c, d.EBH_CommentfromSeller__c, d.EBH_Status__c,d.EBH_Category__c, d.Deal_Contract_Agreement__c,d.Deal_Contract_Agreement__r.CreatedById,'
            + 'd.Quantity_Limitation_per_Purchaser__c, d.EBH_DealFormat__c, d.EBH_DealPrice__c,d.List_Price__c,d.EBH_SellerPrice__c,d.EBH_Subsidy__c,d.ListPriceMSKULower__c,d.ListPriceMSKUUpper__c,d.SellersDealPriceMSKULower__c,d.SellersDealPriceMSKUUpper__c,'
            + 'd.SellersOfferPriceMSKULower__c,d.SellersOfferPriceMSKUUpper__c,d.Deal_Contract_Agreement__r.Current_Digest__c,d.Deal_Contract_agreement__r.Name,d.Seller_Approver_1_Email__c,d.Seller_Approver_2_Email__c,d.Seller_Approver_3_Email__c,d.Seller_Approver_4_Email__c,d.Seller_Approver_5_Email__c,'
            + 'd.Name,d.Cancellation_Date_Time__c,d.Optional_Notes__c,d.Preview_Date_Time__c,d.EBH_SubsidyP__c,d.Subsidy_Type__c From EBH_Deal__c d where Deal_Contract_Agreement__c =: dealAgreementlId';

            if (!isPreview) query = query + ' AND d.EBH_Status__c = :dealStatus';
            if (isPreview) query = query + ' AND d.Preview_Date_Time__c != NULL';
            

            deals = Database.query(query);

            //===MN-28022022-US-0010984

        }
        else if(dealid != null){
            deals  = [Select d.Id, d.EBH_Quantity__c,d.EBH_MaximumPurchases__c,d.EBH_RRPWASPrice__c,d.EBH_eBayLink__c, d.EBH_BusinessName__c, d.EBH_CommentfromeBaySourcer__c,Seller_Approver_1__c,
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
                                                d.Deal_Contract_Agreement__r.Current_Digest__c,
                                                d.Deal_Contract_agreement__r.Name,
                                                d.Seller_Approver_1_Email__c,
                                                d.Seller_Approver_2_Email__c,
                                                d.Seller_Approver_3_Email__c,
                                                d.Seller_Approver_4_Email__c,
                                                d.Seller_Approver_5_Email__c,
                                                d.Name,
                      							d.Cancellation_Date_Time__c,
                                                d.Optional_Notes__c,
                                                d.EBH_SubsidyP__c,
                                                d.Subsidy_Type__c
                                                From EBH_Deal__c d 
                                                where Id =:dealId
                                                ];       
        }
        if (deals.isEmpty()) {
            throw new DocumentApprovalController.DocumentApprovalException('No agreement found');
        }
        List<DocumentApprovalController.DealWrapper> dlWrapper = new List<DocumentApprovalController.DealWrapper>();
        
        for(EBH_Deal__c d: deals){
            
            if((isPreview && d.Preview_Date_Time__c != null && d.Preview_Date_Time__c.issameday(System.Now())) || d.Cancellation_Date_time__c.issameday(System.Now())){ //MN-28022022-US-0010984
                // if(isPreview || d.Cancellation_Date_time__c.issameday(System.Now())){ //MN-28022022-US-0010984
                dlWrapper.add(new DocumentApprovalController.DealWrapper(d.Id, 
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
                                        //d.Quantity_Limitation_per_Purchaser__c,//TH:replace to Maximum Purchases  : US-0009505 : 05/03/2021
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
                                       	//d.List_Price__c,//TH:replace to RRP/WAS Price  : US-0009505 : 05/03/2021
                                       	d.EBH_RRPWASPrice__c,
                                        d.Optional_Notes__c,
                                        //SB 10.01.2024 US-0014252
                                        d.EBH_SubsidyP__c,
                                        d.Subsidy_Type__c));
            }              
        }
        
        //throw new DocumentApprovalController.DocumentApprovalException('<<<<'+dlWrapper);
        return dlWrapper;
    }
}