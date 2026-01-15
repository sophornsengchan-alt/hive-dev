public class LC_DateRangeDeliveryController {
	
    @AuraEnabled
    public static RemoteResponse importDFPDelivery(String siteId, String startDate, String endDate){
    	RemoteResponse rrs = new RemoteResponse();
	    try {
	    	Site__c site = [SELECT Country__c FROM Site__c WHERE ID=:siteId ];
	    	AdServer_Login__c login = DARTUtil.getCredential( DARTUtil.DART6 ,site.Country__c);
	    	// DART6_Delivery.start( DART6_Delivery.SCH_TYPE_ALL,DART6_Delivery.SOBJECT_DAILY,  Date.valueOf(startDate),  Date.valueOf(endDate), login.ID); //MN-21042021-US-0009432 - Remove reference with DART6_Delivery since it's already deprecated
			DeliveryController.start('ALL', DeliveryController.AD_REVENUE_DAILY_API_NAME, Date.valueOf(startDate), Date.valueOf(endDate), login.ID); //MN-21042021-US-0009432 - Calling the new logic
	        rrs.message = String.format(LABEL.MSG_IMPORT_DELIVERY_START, new String[]{site.Country__c});
	    } catch (Exception e) { rrs.statusCode = RemoteResponse.STATUSCODE_ERROR; rrs.message = e.getMessage() + ':' + e.getStackTraceString(); }
	    
		return rrs;
    }
}