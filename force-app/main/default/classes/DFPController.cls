/**
 * Author : Gaeasys
 * CreatedDate: 31-May-2018
 * Description:
 */

/*********************************************************************************************************************************
@ Class:          DFPController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Class for for handle booking along with class BookingController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  01.12.2021 / Sophal Noch / US-0009927 - Update PG Opportunity Flow 
*********************************************************************************************************************************/
public with sharing class DFPController {
    
	public static SObject lineItemRecord, parentRecord;
	public static String dartVersion, dartCountry, dartVerCountry, proposalId, adserverIDOrderID, adserverAdvID, advertiserID, agencyID;
    public static BookingController bookingCon;
    
    private static String OPP_API_NAME = 'Opportunity';
    private static String ADPROD_OPP_FIELD_API_NAME = 'Opportunity__c';
    
    
    /*****************************************************************************************************************************
    @ Method:       initContext
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 intial ad product and opportunity record before booking ad product
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	id of IO_LineItem__c or QuoteLineItem or Ad_Product__c, parent object such as Quote or IO or Opportunity
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  02.12.2020 / Sophal Noch / modify the method.
                    2 March 2022 / Acmatac SEING / US-0010618 - ADS - New Product record types and rename existing
    @*****************************************************************************************************************************/
	public static void initContext(String lineItemId, String sobjectType) {
	    if (lineItemRecord != null && parentRecord != null) return; 
	    if (sobjectType == 'Quote') {
            lineItemRecord = QueryUtil.queryRecord(lineItemId, DFP_QUOTE_ADDITIONAL_FIELD);
	        parentRecord = QueryUtil.queryRecord(Util.getString(lineItemRecord.get('QuoteId')), new Set<String>{'Owner.Name', 'Owner.id', 'Owner.Email', 'Opportunity.AccountId', 'Opportunity.' + Util.NS + 'Start_Date__c', 'Opportunity.' + Util.NS + 'Agency__c'});
            QuoteLineItem li = (QuoteLineItem)lineItemRecord;
            Quote pi = (Quote)parentRecord;
            
            if (pi.Opportunity.AccountId == null) throw new ExceptionGroup.DARTException('No related Advertiser for this Opportunity.');
            //dartCountry = li.PriceBookEntry.Product2.Site__r.Country__c;
            dartCountry = li.PriceBookEntry.Product2.Site__r.Name; //NK:19/04/2021
            dartVerCountry = li.PriceBookEntry.Product2.RecordType.DeveloperName + '_' + dartCountry; // Acmatac SEING, 2 March 2022 US-0010618 - Changed from RecordType.Name to RecordType.DeveloperName
	        adserverIDOrderID = li.Adserver_ID_Order_ID__c;
	        adserverAdvID = li.Adserver_Adv_Advertiser_ID__c;
	        advertiserID = pi.Opportunity.AccountId;
            agencyID = pi.Opportunity.Agency__c;
            dartVersion = li.PriceBookEntry.Product2.RecordType.DeveloperName;// Acmatac SEING, 2 March 2022 US-0010618 - Changed from RecordType.Name to RecordType.DeveloperName
	    } 
        // We're stop using IO?, Acmatac 17,January,2021
        /*else if (sobjectType == 'IO') {
            lineItemRecord = QueryUtil.queryRecord(lineItemId, DFP_IO_ADDITIONAL_FIELD);
            parentRecord = QueryUtil.queryRecord(Util.getString(lineItemRecord.get('IO__c')), new Set<String>{'Owner.Name', 'Owner.id', 'Owner.Email', Util.NS + 'Advertiser__r.Name'});
            IO_LineItem__c li = (IO_LineItem__c)lineItemRecord;
            IO__c pi = (IO__c)parentRecord;
            
            dartCountry = li.Product__r.Site__r.Country__c;
            dartVerCountry = li.Product__r.RecordType.Name + '_' + dartCountry;
            adserverIDOrderID = li.Adserver_ID_Order_ID__c;
            adserverAdvID = li.Adserver_Adv_Advertiser_ID__c;
            advertiserID = pi.Advertiser__c;
            agencyID = pi.Agency__c;
            dartVersion = li.Product__r.RecordType.Name;
            
        }
        */
        else if(sobjectType == OPP_API_NAME){

            // US-0008578
            lineItemRecord = QueryUtil.queryRecord(lineItemId, DFP_ADPROD_ADDITIONAL_FIELD);

            parentRecord = QueryUtil.queryRecord(Util.getString(lineItemRecord.get(ADPROD_OPP_FIELD_API_NAME)), new Set<String>{'Owner.Name', 'Owner.id', 'Owner.Email', Util.NS + 'Account.Name'});
            

            Ad_Product__c li = (Ad_Product__c)lineItemRecord;
            Opportunity pi = (Opportunity)parentRecord;
            
            //dartCountry = li.Product2__r.Site__r.Country__c; 
            dartCountry = li.Product2__r.Site__r.Name; //NK:19/04/2021
            
            dartVerCountry = li.Product2__r.RecordType.DeveloperName + '_' + dartCountry; // Acmatac SEING, 2 March 2022 US-0010618 - Changed from RecordType.Name to RecordType.DeveloperName
            adserverIDOrderID = li.Adserver_ID_Order_ID__c;
            proposalId = pi.Proposal_Id__c; // 01.12.2021 / Sophal Noch / US-0009927
            adserverAdvID = li.Adserver_Adv_Advertiser_ID__c;
            advertiserID = pi.AccountId;
            agencyID = pi.Agency__c;
            dartVersion = li.Product2__r.RecordType.DeveloperName; // Acmatac SEING, 2 March 2022 US-0010618 - Changed from RecordType.Name to RecordType.DeveloperName
           
        }

        bookingCon = new BookingController(parentRecord, lineItemRecord, dartVersion, dartCountry, dartVerCountry, advertiserID);

       
    }
    
    /*****************************************************************************************************************************
    @ Method:       populateContext
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 populate fields of Ad_Product__c and Opportunity from DFP order
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	DFP order. Object name
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  02.12.2020 / Sophal Noch / modify the method.
    @*****************************************************************************************************************************/
    public static void populateContext(DARTObject.IDARTObjectOrder ord, String sobjectType, Boolean isProposal) {
        if (sobjectType == 'Quote') {
            QuoteLineItem li = (QuoteLineItem)lineItemRecord;
            Quote pi = (Quote)parentRecord;
            li.Adserver_ID_Order_ID__c = ord == null ? '' : ord.getDartId();
            li.Adserver_Adv_Advertiser_ID__c = ord == null ? '' : ord.getOrderAvertiserId();
            pi.Order_Id__c = li.Adserver_ID_Order_ID__c;
        } 
        /* We're stop using IO?, Acmatac SEING 17/Jan/2021
        else if (sobjectType == 'IO') {
            IO_LineItem__c li = (IO_LineItem__c)lineItemRecord;
            IO__c pi = (IO__c)parentRecord;
            li.Adserver_ID_Order_ID__c = ord == null ? '' : ord.getDartId();
	        li.Adserver_Adv_Advertiser_ID__c = ord == null ? '' : ord.getOrderAvertiserId();
	        pi.Order_Id__c = li.Adserver_ID_Order_ID__c;
        }*/
        else if (sobjectType == OPP_API_NAME && !isProposal) {
            // US-0008578
            Ad_Product__c li = (Ad_Product__c)lineItemRecord;
            Opportunity pi = (Opportunity)parentRecord;
            li.Adserver_ID_Order_ID__c = ord == null ? '' : ord.getDartId();
	        li.Adserver_Adv_Advertiser_ID__c = ord == null ? '' : ord.getOrderAvertiserId();
	        pi.Order_Id__c = li.Adserver_ID_Order_ID__c;
        }else if (sobjectType == OPP_API_NAME && isProposal) { // 15.12.2021 / Sophal Noch / US-0009927 use isProposal boolean to flag proposal
            Opportunity pi = (Opportunity)parentRecord;
	        pi.Proposal_Id__c = ord.getDartId();
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:       populateContext
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 populate fiels of Ad_Product__c from DFP ads
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	DFP ads. Object name
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  02.12.2020 / Sophal Noch / modify the method.
    @*****************************************************************************************************************************/
    public static void populateContext(DARTObject.IDARTObjectAds ads, String sobjectType, Boolean isProposal) {
        if (sobjectType == 'Quote') {
            QuoteLineItem li = (QuoteLineItem)lineItemRecord;
            li.Ad_Id__c = ads.getDartId();
        } 
        /* We're stop using IO?, Acmatac SEING 17/Jan/2021
        else if (sobjectType == 'IO') {
            IO_LineItem__c li = (IO_LineItem__c)lineItemRecord;
            li.Ad_Id__c = ads.getDartId();
        }
        */
        else if (sobjectType == OPP_API_NAME && !isProposal) {
            // US-0008578
            Ad_Product__c li = (Ad_Product__c)lineItemRecord;
            li.Ad_Id__c = ads.getDartId();
        }else if (sobjectType == OPP_API_NAME && isProposal) { // 15.12.2021 / Sophal Noch / US-0009927 use isProposal boolean to flag proposal lineitem
            Ad_Product__c li = (Ad_Product__c)lineItemRecord;
            li.Proposal_Lineitem_Id__c = ads.getDartId();
        }
    }
    
    public static final Set<String> DFP_QUOTE_ADDITIONAL_FIELD = new Set<String>{
      'PriceBookEntry.Product2.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'Dart_Prio__c',
      'PriceBookEntry.Product2.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_CompanionSize__c',
      'PriceBookEntry.Product2.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_Product_Type__c',
      'PriceBookEntry.Product2.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'Dart_WebPropertyAlias__c',
      'PriceBookEntry.Product2.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_AdType__c',
      'PriceBookEntry.Product2.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'Quantity_Multiplier__c', //Sophal:03/03/2021:US-0009139 
      'PriceBookEntry.Product2.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'to_Subtract__c', //Sophal:03/03/2021:US-0009139 
      'PricebookEntry.Product2.'+Util.NS+'Site__r.Name',
      'PricebookEntry.Product2.'+Util.NS+'Site__r.id',
      'PriceBookEntry.Product2.'+Util.NS+'Fixed_Site__c',
      'PriceBookEntry.Product2.'+Util.NS+'Site__r.'+Util.NS+'Run_of_Network_ID__c',
      'PriceBookEntry.Product2.'+Util.NS+'PredifinedAdunit__c',
      'PriceBookEntry.Product2.'+Util.NS+'PredifinedAdunit__r.Name',
      'PriceBookEntry.Product2Id',
      'PriceBookEntry.Product2.'+Util.NS+'Site__r.'+Util.NS+'Country__c',
      'PriceBookEntry.Product2.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_AdSlotSize__c',
      'PricebookEntry.Product2.RecordType.Name',
      'PricebookEntry.Product2.RecordType.DeveloperName',
      'PricebookEntry.Product2.'+Util.NS+'Billing_Category__c',
      Util.NS+'Predefined_Adunit__r.Name'
    };

    public static final Set<String> DFP_IO_ADDITIONAL_FIELD = new Set<String>{
        Util.NS +'IO__r.Name',
        Util.NS+'Product__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'Dart_Prio__c',
        Util.NS+'Product__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_CompanionSize__c',
        Util.NS+'Product__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_Product_Type__c',
        Util.NS+'Product__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'Dart_WebPropertyAlias__c',
        Util.NS+'Product__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_AdType__c',
        Util.NS+'Product__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'Quantity_Multiplier__c', //Sophal:03/03/2021:US-0009139 
        Util.NS+'Product__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'to_Subtract__c', //Sophal:03/03/2021:US-0009139 
        Util.NS+'Product__r.name',
        Util.NS+'Product__r.'+Util.NS+'PredifinedAdunit__c',
        Util.NS+'Product__r.'+Util.NS+'PredifinedAdunit__r.Name',
        Util.NS+'Product__r.'+Util.NS+'Site__r.Name',
        Util.NS+'Product__r.'+Util.NS+'Site__r.id',
        Util.NS+'Product__r.'+Util.NS+'Fixed_Site__c',
        Util.NS+'Product__r.'+Util.NS+'Site__r.'+Util.NS+'Run_of_Network_ID__c',
        Util.NS+'Product__r.'+Util.NS+'Site__r.'+Util.NS+'Country__c',
        Util.NS+'Product__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_AdSlotSize__c',
        Util.NS+'Product__r.RecordType.Name',
        Util.NS+'Product__r.'+Util.NS+'Billing_Category__c',
        Util.NS+'Predefined_Adunit__r.Name'
    };

    //US-0008578 fields to query from ad product
    public static final Set<String> DFP_ADPROD_ADDITIONAL_FIELD = new Set<String>{
      Util.NS +'Opportunity__r.Name',
      Util.NS+'Product2__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'Dart_Prio__c',
      Util.NS+'Product2__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_CompanionSize__c',
      Util.NS+'Product2__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_Product_Type__c',
      Util.NS+'Product2__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'Dart_WebPropertyAlias__c',
      Util.NS+'Product2__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_AdType__c',
      Util.NS+'Product2__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'Quantity_Multiplier__c', //Sophal:03/03/2021:US-0009139 
      Util.NS+'Product2__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'to_Subtract__c', //Sophal:03/03/2021:US-0009139 
      Util.NS+'Product2__r.name',
      Util.NS+'Product2__r.'+Util.NS+'PredifinedAdunit__c',
      Util.NS+'Product2__r.'+Util.NS+'PredifinedAdunit__r.Name',
      Util.NS+'Product2__r.'+Util.NS+'Site__r.Name',
      Util.NS+'Product2__r.'+Util.NS+'Site__r.id',
      Util.NS+'Product2__r.'+Util.NS+'Fixed_Site__c',
      Util.NS+'Product2__r.'+Util.NS+'Site__r.'+Util.NS+'Run_of_Network_ID__c',
      Util.NS+'Product2__r.'+Util.NS+'Site__r.'+Util.NS+'Country__c',
      Util.NS+'Product2__r.'+Util.NS+'Advertising_Medium__r.'+Util.NS+'DART_AdSlotSize__c',
      Util.NS+'Product2__r.RecordType.Name',
      Util.NS+'Product2__r.RecordType.DeveloperName',
      Util.NS+'Product2__r.'+Util.NS+'Billing_Category__c',
      Util.NS+'Predefined_Adunit__r.Name'
    };

	public static RemoteResponse getAvailability(Id QuoteLineItemId) {
        RemoteResponse responseObj = new RemoteResponse();
        QuoteLineItem  qli = (QuoteLineItem) QueryUtil.queryRecord(QuoteLineItemId, DFPController.DFP_QUOTE_ADDITIONAL_FIELD );
        Targeting__c tar;
        try {
        	
			/**
            String validateDfpErr = DARTUtil.checkDfpReuiredFields(qli);
            if (String.isNotBlank(validateDfpErr)) {
                responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                responseObj.message =  validateDfpErr;
                return responseObj;
            }
            */

            
            ForecastController forecastCon = new ForecastController(qli);
            forecastCon.forecastProcess();
            String dartMethod = forecastCon.getInvokedMethod();
            List<DARTObject.DARTForecast> lstFC = forecastCon.getObjectForecast();
            if (lstFC != null)
            {
                DARTObject.DARTForecast fc = lstFC[0];
                // qli.Availability__c = DARTUtil.toDouble(fc.getAvailableUnits());
                // qli.Last_Availability_Forecast__c = DateTime.Now();
                // update qli;

                //Sophal:03/03/2021:US-0009139 use targeting instead of quotelineitem
                tar = new Targeting__c(Id = qli.Targeting__c);
                tar.Matching_Units__c = DARTUtil.toDouble(fc.getMatchingUnits());
                tar.Availability__c = DARTUtil.toDouble(fc.getAvailableUnits());
                tar.Available_Impressions__c = DARTUtil.toDouble(fc.getAvailableImpressions());
                tar.Available_Matching_Impressions__c = DARTUtil.toDouble(fc.getAvailableMatchingImpressions());
                tar.Available_Share_of_Voice__c = DARTUtil.toDouble(fc.getShareOfVoice());
                tar.Last_Availability_Forecast__c = DateTime.Now();
                update tar;


            }
            responseObj = new RemoteResponse(tar);

        } catch(Exception ex) {
            // responseObj = new RemoteResponse(qli);
            responseObj = new RemoteResponse(tar);
            responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
            Map<String, String> mapErrMsg = DART6Message.getMapFriendlyMsg();
            responseObj.message =  mapErrMsg.containsKey(ex.getMessage()) ? mapErrMsg.get(ex.getMessage()) : ex.getMessage();
        }
		return responseObj;
	}
    
    public static RemoteResponse doBooking(Id lineItemRecordId) {
        String sobjectType = 'IO';
        initContext(lineItemRecordId, sobjectType);
        return doBooking(lineItemRecordId, sobjectType);
    }
    
    public static RemoteResponse doBooking(Id lineItemRecordId, String sobjectType) {
         RemoteResponse responseObj = new RemoteResponse();
         Map<String, Advertiser__c> mapAdverUpsert = new Map<String, Advertiser__c>();
         Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
         Map<String, DARTObject.IDARTObjectOrder> mapNetworkOrder = new Map<String, DARTObject.DARTOrder>();
         
         try{

            // /**
            // String validateDfpErr = DARTUtil.checkDfpReuiredFields(IOLineItem);
            // if (String.isNotBlank(validateDfpErr)) {
            //     responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
            //     responseObj.message =  validateDfpErr;
            //     return responseObj;
            // }
            // */
            
            //mapping network & DFP order
            if (adserverIDOrderID != null && adserverAdvID != null) {
                DARTObject.DARTOrder ord = new DARTObject.DARTOrder(adserverIDOrderID, adserverAdvID);
                mapNetworkOrder.put(dartVerCountry, ord);
            }
            
            // //find Advertiser in SF
            // List<Advertiser__c> listAdvertiser = DARTUTIL.getAdvertiser(advertiserID, agencyID);
            // for (Advertiser__c adv : listAdvertiser) {
            //     if (adv.Dart6_Advertiser_Id__c != null) {
            //         mapAdvertiser.put(DARTUTIL.DART6 + '_' + adv.AdServer_Login_Name__c, adv);
            //     }
            // }
            // //BookingController bookingCon  = new BookingController(io,IOLineItem); //BookingController bookingCon  = new BookingController(opp,oppItem);
            // //if there is no Advertiser found in SF => Search in DFP
            // if (mapAdvertiser.get(dartVerCountry) == null) {
            //     //1-searching Advertiser from DFP
            //     bookingCon.processSearchAdvertiser();
            //     List<DARTObject.IDARTObjectAdvertiser> lstDartAdvertiser = bookingCon.getListAdvertiserExist();
            //     //if no advertiser found in DFP => create one in DFP
            //     if (lstDartAdvertiser.isEmpty()) {
            //         bookingCon.requestCreateAdvertiser();
            //         lstDartAdvertiser = bookingCon.getListAdvertiser();
            //     }
            //     Advertiser__c adv = new Advertiser__c();
            //     if (dartVersion.equals(DARTUTIL.DART6)) adv.Dart6_Advertiser_Id__c = lstDartAdvertiser.get(0).getDartId();
            //     mapAdvertiser.put(dartVerCountry, adv);
            // }

            // // Store all ads/lineItems request success
            // List<DARTObject.IDARTObjectAds> listAds = new List<DARTObject.IDARTObjectAds>();
            // List<DARTObject.IDARTObjectOrder> listOrders = new List<DARTObject.IDARTObjectOrder>();

            // //populate response's DFP fields to SF's fields
            // for (String str : mapAdvertiser.keySet()) {
            //     if (str.equals(dartVerCountry)) {
            //         Advertiser__c advToUpsert;
            //         Advertiser__c advertiser = mapAdvertiser.get(str);
            //         if (advertiser.Id == null) {
            //             advToUpsert = new Advertiser__c();
            //             advToUpsert.Account__c = advertiserID;
            //             advToUpsert.Agency__c = agencyID;
            //             advToUpsert.AdServer_Login_Name__c = dartCountry;
            //         } else {
            //             advToUpsert = new Advertiser__c(id=advertiser.Id);
            //         }
            //         if (dartVersion.equals(DARTUTIL.DART6)) advToUpsert.Dart6_Advertiser_Id__c = advertiser.Dart6_Advertiser_Id__c;
            //         mapAdverUpsert.put(str,advToUpsert);
            //     }
            // }

            // 01.12.2021 / Sophal Noch / US-0009927 : disable code above and move logic to below methods so it can be reused.
            getAdvertiser(mapAdvertiser);
            processSearchAdvertiser(mapAdvertiser);
            populateAdvertiserToUpsert(mapAdvertiser,mapAdverUpsert);

            // Store all ads/lineItems request success
            List<DARTObject.IDARTObjectAds> listAds = new List<DARTObject.IDARTObjectAds>();
            List<DARTObject.IDARTObjectOrder> listOrders = new List<DARTObject.IDARTObjectOrder>();


            //case to create order in DFP
            if (mapNetworkOrder.get(dartVerCountry) == null) {
                // Get existing order by opp's name
                List<DARTObject.IDARTObjectOrder> lstExistOrder = bookingCon.getExistOrder();
                if (!lstExistOrder.isEmpty()) {
                    
                    listOrders.addAll(lstExistOrder);
                    
                } else {
                    
                    try {
                        //request to create order in DFP
                        bookingCon.processAndSendOrder(mapAdvertiser);
                        listOrders = bookingCon.getListOrder();
                        
                    } catch(exception e) {
                        
                        // if (!mapAdverUpsert.isEmpty()) WithoutSharing.doUpsert( mapAdverUpsert.values());
                        // responseObj.content = 0;
                        // responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                        // Map<String, String> mapErrMsg = DART6Message.getMapFriendlyMsg();
                        // responseObj.message =  mapErrMsg.get(e.getMessage()) != null ? mapErrMsg.get(e.getMessage()) : e.getMessage() + e.getStackTraceString();
                        // //record error message as Parent attachment
                        // generateErrorLogasAttachment(lineItemRecord, DARTLogger.OPPERATION_SUBMIT_ORDER, null, dartVersion, responseObj.message, e.getStackTraceString());

                        // 01.12.2021 / Sophal Noch / US-0009927 : move logic to method below to reusable method
                        logErroParentItemRequest(mapAdverUpsert, responseObj, e);
                        return responseObj;
                    }
                }
                mapNetworkOrder.put(dartVerCountry, listOrders.get(0));
                
            } else {
                listOrders.add(mapNetworkOrder.get(dartVerCountry));
            }

            Boolean updateRecords = false;
            //populate response's DFP fields to SF's fields - OpportunityLineItem
            if (!mapNetworkOrder.isEmpty()) {
                for (String ordKey : mapNetworkOrder.keySet()) {
                    if (dartVerCountry.equals(ordKey)) {
                        updateRecords = true;
                        DARTObject.IDARTObjectOrder ord = mapNetworkOrder.get(dartVerCountry);
                        populateContext(ord, sobjectType, false);
                    }
                }
            }

            try {
                //process send lienItem to DFP
                bookingCon.processAndSendLineItem(listOrders.get(0), mapAdvertiser);
                listAds = bookingCon.getListAds();
                
            } catch(exception e) {
                
                // if (updateRecords) WithoutSharing.doUpdate(new List<SObject>{lineItemRecord});
                // if (updateRecords) WithoutSharing.doUpdate(new List<SObject>{parentRecord});
                // responseObj.content = lineItemRecord;
                // responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                // Map<String, String> mapErrMsg = DART6Message.getMapFriendlyMsg();
                // responseObj.message =  mapErrMsg.get(e.getMessage()) != null ? mapErrMsg.get(e.getMessage()) : e.getMessage() + e.getStackTraceString();
                // //record error message as Parent attachment
                // generateErrorLogasAttachment(lineItemRecord, DARTLogger.OPPERATION_SUBMIT_ORDER, null, dartVersion, responseObj.message, e.getStackTraceString());
                
                // 01.12.2021 / Sophal Noch / US-0009927 : move logic to method below to reusable method
                logErrorLineitemRequest(updateRecords, responseObj, e);
                return responseObj;
            }


            // if (!mapAdverUpsert.isEmpty()) WithoutSharing.doUpsert(mapAdverUpsert.values());
            // if (updateRecords) WithoutSharing.doUpdate(new List<SObject>{lineItemRecord});
            // if (updateRecords) WithoutSharing.doUpdate(new List<SObject>{parentRecord});
            
            // 01.12.2021 / Sophal Noch / US-0009927 : move logic to method below to reusable method
            updateAdvertiserAndParentAndLineItem(updateRecords, mapAdverUpsert);

            if (!listAds.isEmpty()) {
                for (DARTObject.IDARTObjectAds ads : listAds) {
                    if (ads.getDartId() != null) {
                        if (ads.getLineItemId() == lineItemRecord.Id) populateContext(ads, sobjectType, false);
                    }
                }
                // Database.SaveResult[] results = WithoutSharing.doUpdate(new List<SObject>{lineItemRecord}, false);
                // for (Database.SaveResult sr: results) {
                //     if (!sr.isSuccess()) {
                //         responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                //         for (Database.Error err : sr.getErrors()) {
                //             responseObj.message = err.getMessage();
                //         }
                //         return responseObj;
                //     }
                // }
                
                 // 01.12.2021 / Sophal Noch / US-0009927 : move logic to method below to reusable method
                Boolean isError = updateLineItemAndCheckResult(responseObj);
                if(isError){ return responseObj; } 

            }
            responseObj.statusCode = RemoteResponse.STATUSCODE_OK;
            responseObj.content = lineItemRecord;
        } catch(Exception ex) {
            // responseObj = new RemoteResponse();
            // responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
            // Map<String, String> mapErrMsg = DART6Message.getMapFriendlyMsg();
            // responseObj.message =  mapErrMsg.get(ex.getMessage())!=null? mapErrMsg.get(ex.getMessage()) : ex.getMessage() + ex.getStackTraceString();
            // //record error message as Parent attachment
            // generateErrorLogasAttachment(lineItemRecord, DARTLogger.OPPERATION_SUBMIT_ORDER, null, dartVersion, responseObj.message, ex.getStackTraceString());
            
            // 01.12.2021 / Sophal Noch / US-0009927 : move logic to method below to reusable method
            logGeneralBookingError(responseObj, ex);
            return responseObj;
        }

        return responseObj;
    }

    /*****************************************************************************************************************************
    @ Method:       doProposing
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      do propose to GAM
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Created the method. US-0009927 - Update PG Opportunity Flow
    @*****************************************************************************************************************************/
    public static RemoteResponse doProposing(Id lineItemRecordId, String sobjectType) {

        RemoteResponse responseObj = new RemoteResponse();
        Map<String, Advertiser__c> mapAdverUpsert = new Map<String, Advertiser__c>();
        Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();

        try{
            Map<String, DARTObject.IDARTObjectOrder> mapNetworkProposal = new Map<String, DARTObject.IDARTObjectOrder>();
            if (proposalId != null && adserverAdvID != null) {
                DARTObject.DARTOrder proposal = new DARTObject.DARTOrder(proposalId, adserverAdvID, true);
                mapNetworkProposal.put(dartVerCountry, proposal);
            }
    
            // 01.12.2021 / Sophal Noch / US-0009927 : use methods below to get advertisers. orignal code is from doBooking method
            getAdvertiser(mapAdvertiser);
            processSearchAdvertiser(mapAdvertiser);
            populateAdvertiserToUpsert(mapAdvertiser,mapAdverUpsert);
    
            List<DARTObject.IDARTObjectOrder> listProposal = new List<DARTObject.IDARTObjectOrder>();
            //case to create proposal in DFP
            if (mapNetworkProposal.get(dartVerCountry) == null) {
                // Get existing order by opp's name
                List<DARTObject.IDARTObjectOrder> lstExistProposal = bookingCon.getExistProposal();
                if (!lstExistProposal.isEmpty()) {
                    listProposal.addAll(lstExistProposal);
                } else {
                    try {
                        bookingCon.processAndSendProposal(mapAdvertiser);
                        listProposal = bookingCon.getListOrder();
                        
                    } catch(exception e) {
                        logErroParentItemRequest(mapAdverUpsert, responseObj, e);
                        return responseObj;
                    }
                }
                mapNetworkProposal.put(dartVerCountry, listProposal.get(0));
                
            } 
            else {
                listProposal.add(mapNetworkProposal.get(dartVerCountry));
            }
    
            Boolean updateRecords = false;
            if (!mapNetworkProposal.isEmpty()) {
                for (String prosKey : mapNetworkProposal.keySet()) {
                    if (dartVerCountry.equals(prosKey)) {
                        updateRecords = true;
                        DARTObject.IDARTObjectOrder pros = mapNetworkProposal.get(dartVerCountry);
                        populateContext(pros, sobjectType, true);
                    }
                }
            }
            

            List<DARTObject.IDARTObjectAds> listProposalLineItems = new List<DARTObject.IDARTObjectAds>();
            try {
                //process send lienItem to DFP
                bookingCon.processAndSendProposalLineItem(listProposal.get(0), mapAdvertiser);
                listProposalLineItems = bookingCon.getListAds();
                
            } catch(exception e) {
                logErrorLineitemRequest(updateRecords, responseObj, e);
                return responseObj;
            }
    
            updateAdvertiserAndParentAndLineItem(updateRecords, mapAdverUpsert);
    
            if (!listProposalLineItems.isEmpty()) {
                for (DARTObject.IDARTObjectAds prop : listProposalLineItems) {
                    if (prop.getDartId() != null) {
                        if (prop.getLineItemId() == lineItemRecord.Id) populateContext(prop, sobjectType, true);
                    }
                }
                Boolean isError = updateLineItemAndCheckResult(responseObj);
                if(isError){ return responseObj; } 
    
            }
            responseObj.statusCode = RemoteResponse.STATUSCODE_OK;
            responseObj.content = lineItemRecord;
        }catch(Exception e){
            logGeneralBookingError(responseObj,e);
            return responseObj;
        }
        
       return responseObj;
    }

    @TestVisible
    private static void getAdvertiser(Map<String, Advertiser__c> mapAdvertiser){
        
        List<Advertiser__c> listAdvertiser = DARTUTIL.getAdvertiser(advertiserID, agencyID);
        for (Advertiser__c adv : listAdvertiser) {
            if (adv.Dart6_Advertiser_Id__c != null) {
                mapAdvertiser.put(DARTUTIL.DART6 + '_' + adv.AdServer_Login_Name__c, adv);
            }
        }
    }

    @TestVisible
    private static void processSearchAdvertiser(Map<String, Advertiser__c> mapAdvertiser){
        if (mapAdvertiser.get(dartVerCountry) == null) {
            //1-searching Advertiser from DFP
            bookingCon.processSearchAdvertiser();
            List<DARTObject.IDARTObjectAdvertiser> lstDartAdvertiser = bookingCon.getListAdvertiserExist();
            //if no advertiser found in DFP => create one in DFP
            if (lstDartAdvertiser.isEmpty()) {
                bookingCon.requestCreateAdvertiser();
                lstDartAdvertiser = bookingCon.getListAdvertiser();
            }
            Advertiser__c adv = new Advertiser__c();
            if (dartVersion.equals(DARTUTIL.DART6)) adv.Dart6_Advertiser_Id__c = lstDartAdvertiser.get(0).getDartId();
            mapAdvertiser.put(dartVerCountry, adv);
        }
    }

    @TestVisible
    private static void populateAdvertiserToUpsert(Map<String, Advertiser__c> mapAdvertiser, Map<String, Advertiser__c> mapAdverUpsert){
            //populate response's DFP fields to SF's fields
            for (String str : mapAdvertiser.keySet()) {
                if (str.equals(dartVerCountry)) {
                    Advertiser__c advToUpsert;
                    Advertiser__c advertiser = mapAdvertiser.get(str);
                    if (advertiser.Id == null) {
                        advToUpsert = new Advertiser__c();
                        advToUpsert.Account__c = advertiserID;
                        advToUpsert.Agency__c = agencyID;
                        advToUpsert.AdServer_Login_Name__c = dartCountry;
                    } else {
                        advToUpsert = new Advertiser__c(id=advertiser.Id);
                    }
                    if (dartVersion.equals(DARTUTIL.DART6)) advToUpsert.Dart6_Advertiser_Id__c = advertiser.Dart6_Advertiser_Id__c;
                    mapAdverUpsert.put(str,advToUpsert);
                }
            }
    }

    @TestVisible
    private static void logErroParentItemRequest(Map<String, Advertiser__c> mapAdverUpsert, RemoteResponse responseObj, exception e){
        if (!mapAdverUpsert.isEmpty()) WithoutSharing.doUpsert( mapAdverUpsert.values());
        responseObj.content = 0;
        responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
        Map<String, String> mapErrMsg = DART6Message.getMapFriendlyMsg();
        responseObj.message =  mapErrMsg.get(e.getMessage()) != null ? mapErrMsg.get(e.getMessage()) : e.getMessage() + e.getStackTraceString();
        
        //record error message as Parent attachment
        generateErrorLogasAttachment(lineItemRecord, DARTLogger.OPPERATION_SUBMIT_ORDER, null, dartVersion, responseObj.message, e.getStackTraceString());
    }

    @TestVisible
    private static void logErrorLineitemRequest(Boolean updateRecords, RemoteResponse responseObj, exception e){
        if (updateRecords) WithoutSharing.doUpdate(new List<SObject>{lineItemRecord});
        if (updateRecords) WithoutSharing.doUpdate(new List<SObject>{parentRecord});
        responseObj.content = lineItemRecord;
        responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
        Map<String, String> mapErrMsg = DART6Message.getMapFriendlyMsg();
        responseObj.message =  mapErrMsg.get(e.getMessage()) != null ? mapErrMsg.get(e.getMessage()) : e.getMessage() + e.getStackTraceString();
        //record error message as Parent attachment
        generateErrorLogasAttachment(lineItemRecord, DARTLogger.OPPERATION_SUBMIT_ORDER, null, dartVersion, responseObj.message, e.getStackTraceString());
    }

    @TestVisible
    private static void logGeneralBookingError(RemoteResponse responseObj, exception e){
        responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
        Map<String, String> mapErrMsg = DART6Message.getMapFriendlyMsg();
        responseObj.message =  mapErrMsg.get(e.getMessage())!=null? mapErrMsg.get(e.getMessage()) : e.getMessage() + e.getStackTraceString();
        //record error message as Parent attachment
        generateErrorLogasAttachment(lineItemRecord, DARTLogger.OPPERATION_SUBMIT_ORDER, null, dartVersion, responseObj.message, e.getStackTraceString());
    }


    private static void updateAdvertiserAndParentAndLineItem(Boolean updateRecords, Map<String, Advertiser__c> mapAdverUpsert){
        if (!mapAdverUpsert.isEmpty()) WithoutSharing.doUpsert(mapAdverUpsert.values());
        if (updateRecords) WithoutSharing.doUpdate(new List<SObject>{lineItemRecord});
        if (updateRecords) WithoutSharing.doUpdate(new List<SObject>{parentRecord});
    }
    private static Boolean updateLineItemAndCheckResult(RemoteResponse responseObj){
        Boolean isError = false;
        Database.SaveResult[] results = WithoutSharing.doUpdate(new List<SObject>{lineItemRecord}, false);
        for (Database.SaveResult sr: results) {
            if (!sr.isSuccess()) {
                responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                for (Database.Error err : sr.getErrors()) {
                    responseObj.message = err.getMessage();
                }
                isError = true; return isError;
                
            }
        }
        return isError;
    }
	
	public static RemoteResponse schDelivery(Id IOLineId) {
		return null;
	}

    /**
     * To generate Error Log as attachment, then linking to parent record
     * @param : lineItem an Opportunity product record which will be forcasred/booked
     * @param : operation an operation name
     * @param : dartmethod name of dart method 
     * @param : dartVersion stat version of dart
     * @param : msg a message error which generate from any operation failed
     * @param : detail a detail message error which generate from any operation failed
     * @return 
     */
    private static void generateErrorLogasAttachment(SObject contextRecord, String operation, String dartmethod, String dartVers, String msg, String detail) {
        DARTLogger.LogMessage errorLog = new DARTLogger.LogMessage(
                                                        contextRecord.Id, 
                                                        operation,
                                                        dartmethod,
                                                        dartVers,
                                                        DARTLogger.TYPE_ERROR, msg, detail
                                          );
        DARTLogger.getInstance().log(parentRecord.Id, new List<DARTLogger.LogMessage>{errorLog});
    }
}