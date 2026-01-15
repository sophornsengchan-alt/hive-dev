public with sharing class LC_NewOppRedirectorController {
	@AuraEnabled
    public static RemoteResponse getRelatedAccount(String accId){
    	RemoteResponse response = new RemoteResponse();
	   
	    response.statusCode = RemoteResponse.STATUSCODE_OK;
	    for(Account acc : [ SELECT Name, RecordType.Name, BillingStreet,  BillingCity, BillingState, BillingPostalcode,  BillingCountry 
						FROM Account 
						WHERE Id =: accId]) {
	    	response.content = new Map < String, Object >{'relatedAcc' => acc};
		}
	    response.message = 'successed';
	    return response;
	    
    }

    @AuraEnabled
    public static RemoteResponse getRecordTypeData(String recTypeId, String accId) {
    	RemoteResponse response = new RemoteResponse();
        Map<String, Object> resContent = new Map<String, Object>();
    	try {
    		
            if(String.isBlank(recTypeId)){
            	for (Schema.RecordTypeInfo info : Schema.SObjectType.Opportunity.RecordTypeInfos) {
					if (info.DefaultRecordTypeMapping) {
						recTypeId = info.getRecordTypeId();
					}
				}
            }
            
            String devName = Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(recTypeId).getDeveloperName();
            //resContent.put('isNA', devName==Label.OPP_RECORDTYPENAME_AD);
            resContent.put('recTypeId', recTypeId);
            
            for(Account acc: [SELECT RecordTypeId FROM Account WHERE Id =: accId]){
            	String devNameAccRT = Schema.SObjectType.Account.getRecordTypeInfosById().get(acc.RecordTypeId).getDeveloperName();
            	resContent.put('isAgency', devNameAccRT == Label.ACC_RECORDTYPENAME_AGENCY);
            }
            
    		response.content = resContent;
    		response.statusCode = RemoteResponse.STATUSCODE_OK;
    	} catch(Exception ex) {
    		response.statusCode = RemoteResponse.STATUSCODE_ERROR;
    		response.message = ex.getMessage();
    	}
    	return response;
    	 
    }
}