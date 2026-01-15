@isTest
private class LC_AdvertiserSearchControllerTest {
    @isTest
    private static void testGetAdvertisers() {
        RecordType rtAdvertiser = [SELECT id FROM recordType WHERE name = 'Advertiser' AND sobjectType = 'Account'];
    	Account acc = new Account(
    		Name = 'Account test',
    		BillingStreet = 'Goethestrasse 97',
            BillingPostalCode = '19053',
            BillingCity = 'Schwerin',
            BillingState = 'Berlin',
            BillingCountry = 'Germany',
            Phone = '+1234567890',
            recordTypeid = rtAdvertiser.id
		);
        insert acc;
        
        LC_AdvertiserSearchController.getAdvertisers(acc);
    }
}