public with sharing class LC_BookingQuoteItemsController {

    public static String OPP_RT_PMP = Label.OPP_RECORDTYPEDEVNAME_PMP;
    public static String OPP_RT_PROGRAMMATIC = Label.OPP_RECORDTYPEDEVNAME_PROGRAMMATIC;

    public static RemoteResponse initializeDataQuote(String recordId) {

        RemoteResponse rrs = new RemoteResponse();
        Map<String, Object> res = new Map<String, Object> ();
        try {
            if (!Util.hasPermission('Booking')) { rrs.statusCode = RemoteResponse.STATUSCODE_OK; rrs.validationMsg = 'You don\'t have permission to do DFP booking!'; return rrs;}

            Quote q = [SELECT Id, Name, Pricebook2Id, Media_Plan__r.End_Flight_Date__c,
                Media_Plan__r.Start_Flight_Date__c, Opportunity.Amount,
                Opportunity.Type, Dually_Signed__c,
                Status, Media_Plan__r.IsRevision__c
                FROM Quote WHERE Id =: recordId
            ];

            if (q.Status != 'Approved') {
                rrs.statusCode = RemoteResponse.STATUSCODE_OK;
                rrs.validationMsg = 'You can only book line items to DFP once the quote is approved';
                return rrs;
            }

            List<QuoteLineItem> lstQli = [SELECT Id, LineNumber, Product2Id, UnitPrice, Ad_Id__c,
                until_Date__c, from_Date__c, Quantity, Quantity__c, Availability__c, Last_Availability_Forecast__c,
                Product2.Name, Product2.Id, Product2.Time__c, Product2.Site__c,
                Product2.FC__c, Product2.OperatingSystem__c, Product2.Bandwidth__c,
                Product2.Connection__c, Product2.Browser__c, Product2.Device__c,
                Product2.Geo_IP__c, Product2.Keywords__c, Product2.Content__c, 
                // Product2.Billing_Category__c, // Sophal:01/03/2021:US-0009134 so it can be changed to Multi-picklist value
                Budget__c, SalesPriceNet__c, CreatedDate, Product_Package__c,
                Product_Package__r.Package__c, Product_Package__r.Package__r.Name,
                Description, SortOrder__c, PricebookEntryId,
                Product2.Advertising_Medium__r.Dart_AdSlotSize__c, Product2.Advertising_Medium__r.Name, Product2.Advertising_Medium__r.DART_AdType__c, Product2.Advertising_Medium__r.Dart_Product_Type__c
                FROM QuoteLineItem WHERE QuoteId =: recordId AND (Ad_Id__c = NULL OR IsPendingDfpPush__c = TRUE) ORDER BY SortOrder__c ASC
            ];

            res.put('lstLineItem', lstQli);

            rrs.statusCode = RemoteResponse.STATUSCODE_OK;
            rrs.content = res;
            rrs.message = 'successed';

        } catch (Exception e) {rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = e.getMessage();rrs.debug = e.getMessage() + ':' + e.getStackTraceString();}
        return rrs;
    }

    public static RemoteResponse bookingLineItemQuote(String recordId) {
        RemoteResponse rrs = new RemoteResponse();
        try { 
            QuoteLineItem qli = (QuoteLineItem) QueryUtil.queryRecord(recordId, new Set<String> {});
            boolean isRebooking = qli.Ad_Id__c != null;
            DFPController.initContext(recordId, 'Quote');
            rrs = DFPController.doBooking(recordId, 'Quote');
            if (rrs.statusCode == RemoteResponse.STATUSCODE_OK) {
                qli.IsPendingDfpPush__c = false;
                update qli;
            }
        } catch (Exception e) {rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = e.getMessage();rrs.debug = e.getMessage() + ':' + e.getStackTraceString();}
        return rrs;
    }
}