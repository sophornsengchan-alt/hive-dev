public with sharing class UTIL_BookingItemsController {

    @AuraEnabled
    public static RemoteResponse initializeDataQuote(String recordId) {
        return LC_BookingQuoteItemsController.initializeDataQuote(recordId);
    }
    
    @AuraEnabled
    public static RemoteResponse bookingDataQuote(String recordId){
        return LC_BookingQuoteItemsController.bookingLineItemQuote(recordId);
    }
    
    // Sophal: 29/09/2021: US-0008398 deprecated
    // @AuraEnabled
    // public static RemoteResponse initializeDataIO(String recordId) {
    //     return LC_BookingIOItemsController.initializeDataIO(recordId);
    // }
    
    // Sophal: 29/09/2021: US-0008398 deprecated
    // @AuraEnabled
    // public static RemoteResponse bookingDataIO(String recordId){
    //     return LC_BookingIOItemsController.bookingLineItemIO(recordId);
    // }


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
    @*****************************************************************************************************************************/
    @AuraEnabled
    public static RemoteResponse initializeDataOpportunity(String recordId) {
        return BookingOppAdProdController.initializeDataOpportunity(recordId);
    }

    /*****************************************************************************************************************************
    @ Method:       bookingDataOpportunity
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
    @*****************************************************************************************************************************/
    @AuraEnabled
    public static RemoteResponse bookingDataOpportunity(String recordId) {
        return BookingOppAdProdController.bookingDataAdProductOpportunity(recordId);
    }

    

}