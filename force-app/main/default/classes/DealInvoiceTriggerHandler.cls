/*********************************************************************************************************************************
@ Class:          DealInvoiceTriggerHandler
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Trigger Handler for object: EBH_DealInvoice__c
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.07.2019 / Vadhanak Voun / Created the class.
*********************************************************************************************************************************/
public without sharing class DealInvoiceTriggerHandler {

    /*****************************************************************************************************************************
    @ Method:         setDefaultCurrency
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        EPH-7758 Deal Invoice.Currency should be Euro by default
    @ Event:		  Before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<EBH_DealInvoice__c> list EBH_DealInvoice__c
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.07.2019 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    public static void setDefaultCurrency(List<EBH_DealInvoice__c> listNew)
    {
    	for(EBH_DealInvoice__c di : listNew)
    	{
    		di.CurrencyIsoCode = 'EUR';
    	}
    }
	
	/*****************************************************************************************************************************
    @ Method:         changeDealStatus
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        EPH-7939 Deals VAT Invoice Process - Rejection Flow + Validations Rule
    @ Event:		  After Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<EBH_DealInvoice__c> lst
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.08.2019 / Sreymeas Nao / Created the  Method.
    *****************************************************************************************************************************/
    public static List<EBH_Deal__c> changeDealStatus(List<EBH_DealInvoice__c> lst){
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
        Set<Id> dealId = new Set<Id>();
        for(EBH_DealInvoice__c oneLst : lst){
            dealId.add(oneLst.EBH_Deal__c);
        }

        lstDeal = [select EBH_Status__c from EBH_Deal__c where Id = :dealId];

        for(EBH_DealInvoice__c oneLst : lst){
            for(EBH_Deal__c oneDeal : lstDeal){
                if (oneLst.Deal_Invoice_Status__c == 'Invoice Rejected') {
                    oneDeal.EBH_Status__c = 'Invoice Rejected (Email resend to Seller)';
                }
            }
        }

        update lstDeal;
        return lstDeal;
    }

    /*****************************************************************************************************************************
    @ Method:         updateEbayVATIsUK
    @ Version:        1.0
    @ Author:         SRONG TIN
    @ Purpose:        US-0010453 - [UK-Deals] Deal Invoice - eBay billing address and VAT changes
    @ Event:		  before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<EBH_DealInvoice__c> lst
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.10.2021 / SRONG TIN / Created the  Method.
                      19.10.2021 / SRONG TIN / US-0010453 / update the method. 
    *****************************************************************************************************************************/
    public static void updateEbayVATIsUK(List<EBH_DealInvoice__c> lst){
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
        Map<String,EBH_DealInvoice__c> dealInvoiceMap = new Map<String,EBH_DealInvoice__c>();
        Set<Id> dealIds = new Set<Id>();
        for(EBH_DealInvoice__c oneLst : lst){
            dealIds.add(oneLst.EBH_Deal__c);
            dealInvoiceMap.put(oneLst.EBH_Deal__c,oneLst);
        }
        // add deal to map
        for(EBH_Deal__c deal: [select Id,EBH_DealSiteId__c from EBH_Deal__c where Id IN :dealIds]){
            EBH_DealInvoice__c oneDealInvoice = dealInvoiceMap.get(deal.Id);
            if(deal.EBH_DealSiteId__c == '3'){// 3 == UK
                oneDealInvoice.eBay_VAT__c = System.Label.EBAY_VAT_FOR_UK;
                //19.10.2021 / SRONG TIN :US-0010453
                oneDealInvoice.eBay_Billing_address__c = System.Label.EBAY_BILLING_ADDRESS;
            }
        }
    }
}