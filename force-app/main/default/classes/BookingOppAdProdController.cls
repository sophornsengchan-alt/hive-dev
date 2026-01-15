/*********************************************************************************************************************************
@ Class:          BookingOppAdProdController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Class for booking ad product. It is called from UTIL_BookingItemsController.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  01.12.2020 / Sophal Noch / Created the class.
@ Change history:  23.07.2021 / Mony Nou / US-0009996 - Booking button visible now, but returns error when opp not closed
@ Change history:  01.12.2021 / Sophal Noch / US-0009927 - Update PG Opportunity Flow 
*********************************************************************************************************************************/
public without sharing class BookingOppAdProdController {

    public static String QUOTE_RT_ADVERTISING = 'eBay_Advertising';
    public static String QUOTE_RT_PG_PMP_QUOTE = 'PG_PMP_Quote';
    private static String OPP_API_NAME = 'Opportunity';
    private static String OPP_STATUS_APPROVED = 'Approved';
    private static String BOOKING_PERMISSION = 'Booking';

    private static Boolean isEUAdsUser { //MN-23072021-US-0009996
        get {
            if (isEUAdsUser ==  null) {

                Profile profile_eu = ApexUtil.getProfileByName('Standard Ads EU User Profile');
                isEUAdsUser = UserInfo.getProfileId() == profile_eu.Id;
                
            }
            return isEUAdsUser;
        }
        private set;
    }

    private static final String OPP_PG_RT_ID = ApexUtil.getRecordTypeByName('Opportunity','Programmatic').Id;

    /*****************************************************************************************************************************
    @ Method:       initializeDataOpportunity
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578
    @               Recreate / Modify Booking Lightning Component to function based on Ad Products from the Opportunity record as opposed to IO Line Items.
    @               AC 1) Create new 'Booking' button on the Opportunity object
    @               Button should launch the Lightning Component
    @               The Apex Classes that support Booking from IOLineItems should be cloned/modified to refer to Ad Product records instead
    @               Existing components should be cloned and modified to refer to Ad Products instead of IO Line Items, the new button should be located on the Opportunity Layout accessible for all NA Ads Profiles.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	id of opporutnity
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2020 / Sophal Noch / Created the method.
    @               : 01.01.2021 / vadhanak voun / US-0009612 - [Ads 2020] Change to booking service
    @*****************************************************************************************************************************/
    public static RemoteResponse initializeDataOpportunity(String recordId) {

        RemoteResponse rrs = new RemoteResponse();
        Map<String, Object> res = new Map<String, Object> ();
        try {

            if (!Util.hasPermission(BOOKING_PERMISSION)) {rrs.statusCode = RemoteResponse.STATUSCODE_OK; rrs.validationMsg = Label.Error_No_Permission_To_Do_DFP_Booking; return rrs;}

            Opportunity opp = [
                SELECT 
                Id,
                Name,
                RecordType.DeveloperName,
                (Select Id, Dually_Signed__c,Status, Buyer_Accepted__c, RecordType.DeveloperName From Quotes Where Primary_Quote__c = true Order By Id Desc Limit 1),
                // (
                //     Select Id, 
                //     Name,
                //     Ad_Id__c, 
                //     IsPendingDfpPush__c,
                //     Quantity__c,
                //     SalesPriceNet__c,
                //     from_Date__c,
                //     TotalPrice__c,
                //     until_Date__c,
                //     Product2__r.Name,
                //     Product2__r.Billing_Category__c // commentted out so it can be change to multi-select value
                //     From Ad_Products__r
                //     Where Ad_Id__c = NULL OR IsPendingDfpPush__c = True
                // )
                // Sophal:01/03/2021:US-0009134
                (
                    Select Id, 
                    Name,
                    Ad_Id__c, 
                    IsPendingDfpPush__c,
                    Quantity__c,
                    SalesPriceNet__c,
                    from_Date__c,
                    TotalPrice__c,
                    until_Date__c,
                    Product2__r.Name,
                    Billing_Category__c,
                    CurrencyISOCode
                    From Ad_Products__r
                    Where ((Ad_Id__c = NULL AND Proposal_Lineitem_id__c = NULL) OR IsPendingDfpPush__c = True) 
                    AND Product2__r.Non_GAM_Product__c = False
                )

                FROM Opportunity WHERE Id =: recordId Limit 1
            ];

            Quote primaryQuote = !opp.Quotes.isEmpty() ? opp.Quotes[0] : null;
            
            if(primaryQuote == null){
                rrs.statusCode = RemoteResponse.STATUSCODE_OK;
                rrs.validationMsg = Label.Error_Primary_Quote_Is_Required_To_Do_Booking;
                return rrs;
            }
            
            else if(primaryQuote.RecordType.DeveloperName == QUOTE_RT_ADVERTISING && (!primaryQuote.Dually_Signed__c || primaryQuote.Status != OPP_STATUS_APPROVED) && !isEUAdsUser){ //MN-23072021-US-0009996
                    rrs.statusCode = RemoteResponse.STATUSCODE_OK;
                    rrs.validationMsg = Label.Error_Can_Not_Book_AdProduct_On_Quote_RT_Advertising;
                    return rrs;
            
            }else if(primaryQuote.RecordType.DeveloperName == QUOTE_RT_PG_PMP_QUOTE && primaryQuote.Status != OPP_STATUS_APPROVED && !isEUAdsUser){ //MN-23072021-US-0009996 // 01.12.2021 / Sophal Noch / US-0009927
                    rrs.statusCode = RemoteResponse.STATUSCODE_OK;
                    rrs.validationMsg = Label.Error_Can_Not_Book_AdProduct_On_Quote_RT_PG_PMP;
                    return rrs;
            }

            res.put('lstLineItem', opp.Ad_Products__r);

            rrs.statusCode = RemoteResponse.STATUSCODE_OK;
            rrs.content = res;
            rrs.message = 'successed';
        } catch (Exception e) {
            rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;
            rrs.message = e.getMessage();
            rrs.debug = e.getMessage() + ':' + e.getStackTraceString();
        }
        return rrs;
    }

    /*****************************************************************************************************************************
    @ Method:       bookingDataAdProduct
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578
    @               Recreate / Modify Booking Lightning Component to function based on Ad Products from the Opportunity record as opposed to IO Line Items.
    @               AC 1) Create new 'Booking' button on the Opportunity object
    @               Button should launch the Lightning Component
    @               The Apex Classes that support Booking from IOLineItems should be cloned/modified to refer to Ad Product records instead
    @               Existing components should be cloned and modified to refer to Ad Products instead of IO Line Items, the new button should be located on the Opportunity Layout accessible for all NA Ads Profiles.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	id of ad product
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2020 / Sophal Noch / Created the method.
    @ Change history:  01.12.2021 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    public static RemoteResponse bookingDataAdProductOpportunity(String recordId) {
        RemoteResponse rrs = new RemoteResponse();
        try {
            Ad_Product__c adProduct = (Ad_Product__c) QueryUtil.queryRecord(recordId,new Set<String>{Util.NS+'Product2__r.'+Util.NS+'Advertising_Medium__c','Opportunity__r.RecordTypeId'});
            //boolean isRebooking = adProduct.Ad_Id__c != null;
           
            if(adProduct.Targeting__c == null){throw new AdProductException(Label.Error_AdProduct_Targeting_Can_Not_Be_Empty);}
            if(adProduct.Product2__r.Advertising_Medium__c == null){throw new AdProductException(Label.Error_Product_Advertising_Medium_Can_Not_Be_Empty);}

            DFPController.initContext(recordId, OPP_API_NAME);

            // 01.12.2021 / Sophal Noch / US-0009927 :
            if(adProduct.Opportunity__r.RecordTypeId == OPP_PG_RT_ID && String.isBlank(adProduct.Ad_Id__c)){
                rrs = DFPController.doProposing(recordId, OPP_API_NAME);
            }else{
                rrs = DFPController.doBooking(recordId, OPP_API_NAME);
            }
            
            if (rrs.statusCode == RemoteResponse.STATUSCODE_OK) {
                adProduct.IsPendingDfpPush__c = false;
                update adProduct;
            }
        } catch (Exception e) {
            rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;
            rrs.message = e.getMessage();
            rrs.debug = e.getMessage() + ':' + e.getStackTraceString();
        }
        return rrs;
    }

    public class AdProductException extends Exception {}

    
}