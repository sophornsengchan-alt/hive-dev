/**
 * Factory to create DFP request
 */
public without sharing class FactoryDARTRequest {

    private static FactoryDARTRequest instance;

    private FactoryDARTRequest() {}

    public static FactoryDARTRequest getInstance() {
        if (instance == null) {
            instance = new FactoryDARTRequest();
        }

        return instance;
    }

    /** 
     * Company/Advertiser Request
     * @param AdserverLogin
     * @param OpportunityLineItem
     * @param Account
     * @return IGenericRequest
     */
    public HTTPWrapper.IGenericRequest createDARTSubmitAdvertiserRequest(AdServer_Login__c credential, Account acc) {
        // new version
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPCompanyRequest(acc, credential);
        }
        return null;
    }

    /**
     * Oreder Request
     * @param AdserverLogin
     * @param Opportunity
     * @param OpportunityLineItem
     * @param mapDartUser
     * @param mapAdvertiser
     * @return IGenericRequest
     */
    public HTTPWrapper.IGenericRequest createDARTSubmitOrderRequest(AdServer_Login__c credential, String dartVerCountry, SObject parentRecord, SObject lineItemRecord, Map<String, DARTObject.DARTPerson> mapDartUser, Map<String, Advertiser__c> mapAdvertiser) {
        // new version
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPOrderRequest(credential, dartVerCountry, parentRecord, lineItemRecord, mapDartUser, mapAdvertiser);
        }
        return null;
    }

    /*********************************************************************************************************************************
    @ Class:          createDARTSubmitProposalRequest
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        method to call submit proposal to GAM
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Create method. US-0009927 - Update PG Opportunity Flow 
    *********************************************************************************************************************************/
    public HTTPWrapper.IGenericRequest createDARTSubmitProposalRequest(AdServer_Login__c credential, String dartVerCountry, SObject parentRecord, SObject lineItemRecord, Map<String, DARTObject.DARTPerson> mapDartUser, Map<String, Advertiser__c> mapAdvertiser) {
        // new version
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPProposalRequest(credential, dartVerCountry, parentRecord, lineItemRecord, mapDartUser, mapAdvertiser);
        }
        return null;
    }

    /**
     * Ads/LineItem Request
     * @param AdserverLogin
     * @param OpportunityLineItem
     * @param dartOrder
     * @return IGenericRequest
     */
    public HTTPWrapper.IGenericRequest createDARTSubmitAdsRequest(AdServer_Login__c credential, SObject contextRecord, DARTObject.IDARTObjectOrder dartOrder) {
        // new version
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPAdsRequest(credential, contextRecord, dartOrder);
        }
        return null;
        //return new DARTMessage.DARTSubmitAdsRequest(listDartAds);
    }

    /*********************************************************************************************************************************
    @ Class:          createDARTSubmitProposalLineitemsRequest
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        method to call submit proposal to GAM
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Create method. US-0009927 - Update PG Opportunity Flow 
    *********************************************************************************************************************************/
    public HTTPWrapper.IGenericRequest createDARTSubmitProposalLineitemsRequest(AdServer_Login__c credential, SObject contextRecord, DARTObject.IDARTObjectOrder dartProposal) {
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPAdsRequest(credential, contextRecord, dartProposal, true); // use new constructor to flag proposal lineitem request
        }
        return null;
    }

    /**
     * Salesperson/DartUser Request
     * @param userRoleId
     * @param AdserverLogin
     * @param OpportunityLineItem
     * @param Opportunity
     * @return DART6Message.DFPSalespersonRequest
     */
    public HTTPWrapper.IGenericRequest createDartSubmitSalePersonRequest(AdServer_Login__c credential, SObject parentRecord) {
        // new version
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPSalespersonRequest(credential, parentRecord);
        }
        return null;
        //return new DARTMessage.DARTSalePersonListRequest();
    }

    /**
     * Forecast Request
     * @param AdserverLogin
     * @param QuoteLineItem
     * @return DART6Message.DFPForecastRequest
     */

    public HTTPWrapper.IGenericRequest createDartForecastRequest(AdServer_Login__c credential, QuoteLineItem qli) {
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPForecastRequest(qli);
        }
        return null;
    }

    /** 
     * Request to get Advertiser(DFP)
     * @param AdserverLogin
     * @param OpportunityLineItem
     * @param Account
     * @return DART6Message.DFPGetAdvertiserRequest
     */
    public HTTPWrapper.IGenericRequest createDartGetAdvertiserRequest(AdServer_Login__c credential, SObject contextRecord, Account acc, String dartCountry) {
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPGetAdvertiserRequest(contextRecord, acc, dartCountry);
        }
        return null;
    }

    /**
     * Delivery Request
     * @param AdserverLogin
     * @param breakDown
     * @param jobId
     * @param Dfp reportService 
     * @return DART6Message.DeliveryRequest
     */
    public HTTPWrapper.IGenericRequest createDartDeliveryRequest(AdServer_Login__c credential, String breakDown, String dateRange, Long jobid, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService) {
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DeliveryRequest(credential, jobid, reportService);
        }
        return null;
    }

    /** ------------ Delivery Request ----------------- */
    /*****************************************************************************************************************************************************************
    @ Method:         createDartDeliveryRequest
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
    @                 Cloned from EU Advertising
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.11.2020 / Acmatac SEING / Created the class.
    ***********************************************************************************************************************************************************/
    public HTTPWrapper.IGenericRequest createDartDeliveryRequest(AdServer_Login__c credential,String breakDown, Long jobid, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService, String sobjectType, Date startDate, Date endDate)
    {
        if(DARTUtil.DART6.equals(credential.RecordType.Name))
        {
        return new DART6Message.DeliveryRequest(credential, jobid, reportService); 
        } 

        return null;
    }

    /**
     * Get order request 
     * @param AdserverLogin
     * @param Opportunity
     * @param OpportunityLineItem
     * @return DART6Message.DFPGetOrderRequest
     */
    public HTTPWrapper.IGenericRequest createGetOrderRequest(AdServer_Login__c credential, SObject contextRecord) {
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPGetOrderRequest(contextRecord, credential);
        }
        return null;
    }

    /*********************************************************************************************************************************
    @ Method:         createGetProposalRequest
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        method to call to get proposal from GAM
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Create method. US-0009927 - Update PG Opportunity Flow 
    *********************************************************************************************************************************/
    public HTTPWrapper.IGenericRequest createGetProposalRequest(AdServer_Login__c credential, SObject contextRecord) {
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPGetProposalRequest(contextRecord, credential);
        }
        return null;
    }

    /**
     * Get order request
     * @param AdserverLogin
     * @param OpportunityLineItem
     * @param dartOrder
     * @return DART6Message.DFPGetLineItemRequest
     */
    public HTTPWrapper.IGenericRequest createGetLineItemRequest(AdServer_Login__c credential, SObject contextRecord, DARTObject.IDARTObjectOrder dartOrder) {
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPGetLineItemRequest(credential, contextRecord, dartOrder);
        }
        return null;
    }

    /**
     */
    public HTTPWrapper.IGenericRequest createGetLineItemRequestByAdIds(AdServer_Login__c credential, OpportunityLineItem item) {
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPGetLineItemRequestById(item);
        }
        return null;

    }

    /*********************************************************************************************************************************
    @ Method:         createGetProposalLineItemRequest
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        method to call to get proposal lineitem from GAM
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Create method. US-0009927 - Update PG Opportunity Flow 
    *********************************************************************************************************************************/
    public HTTPWrapper.IGenericRequest createGetProposalLineItemRequest(AdServer_Login__c credential, SObject contextRecord, DARTObject.IDARTObjectOrder dartProposal) {
        if (DARTUtil.DART6.equals(credential.RecordType.Name)) {
            return new DART6Message.DFPGetProposalLineItemRequest(credential, contextRecord, dartProposal);
        }
        return null;
    }


    /**
     * AdxReport Request
     * @param AdserverLogin
     * @param breakDown
     * @param jobId
     * @param Dfp reportService 
     * @return DART6Message.DeliveryRequest
     */
    public HTTPWrapper.IGenericRequest createAdxReportRequest(AdServer_Login__c credential, String breakDown, String dateRange,
        Long jobid, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService) {
        return null; //new DART6Message.DeliveryRequest(credential, jobid, reportService); 
    }

}