public with sharing class LC_AdvertiserSearchController {
    @AuraEnabled
	// Acmatac SEING, 17/03/2022 US-0011204 - TECHDEBT: SOQL SOSL Injection - Prio 1
    public static RemoteResponse getAdvertisers(Account acc){
    	RemoteResponse response = new RemoteResponse();
    	String filters = '';
		String accName = '%'+acc.Name+'%';
		String accBillingStreet = '%'+acc.BillingStreet+'%';
		String accBillingCity = '%'+acc.BillingCity+'%';
		String accBillingState = '%'+acc.BillingState+'%';
		String accBillingPostalCode = '%'+acc.BillingPostalCode+'%';
		String accBillingCountry = '%'+acc.BillingCountry+'%';

		String accRecordtypeNameADV = Label.ACC_RECORDTYPENAME_ADV;

	    if(String.isNotEmpty(acc.Name))filters += ' Name LIKE :accName';
	    if(String.isNotEmpty(accBillingStreet))filters += (String.isNotEmpty(filters)?' AND':'') + ' BillingStreet LIKE :accBillingStreet';
	    if(String.isNotEmpty(accBillingCity))filters += (String.isNotEmpty(filters)?' AND':'') + ' BillingCity LIKE :accBillingCity';
	    if(String.isNotEmpty(accBillingState))filters += (String.isNotEmpty(filters)?' AND':'') + ' BillingState LIKE :accBillingState';
	    if(String.isNotEmpty(accBillingPostalCode))filters += (String.isNotEmpty(filters)?' AND':'') + ' BillingPostalcode LIKE :accBillingPostalCode';
	    if(String.isNotEmpty(accBillingCountry))filters += (String.isNotEmpty(filters)?' AND':'') + ' BillingCountry LIKE :accBillingCountry';
	       
        String query = 'SELECT Name, RecordType.Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account WHERE RecordType.Name = :accRecordtypeNameADV'; 
        if(String.isNotEmpty(filters)) query += ' AND ' + filters; 
        query += ' LIMIT 20';
        	
        response.statusCode = RemoteResponse.STATUSCODE_OK;
	    response.content = new Map < String, Object > {'lstAdvertiser' => Database.query(query)};
	    return response;
	    
    }
}