public with sharing class LC_ChooseAgencyController {
    
    @AuraEnabled
    public static RemoteResponse getInitData(String advertiserId){
    	RemoteResponse response = new RemoteResponse();
	    try {
	    	Map<String, Object> res = new Map<String, Object>();
            res.put('lstAdvAgencyRel', [SELECT Id, Name, Advertiser__r.Name, Agency__r.Name, Bill_To_Contact__r.Name, Advertiser__c, Agency__c, Bill_To__c, Bill_To_Contact__c, Bill_To_Email__c 
            							FROM Advertiser_Agency_Relationship__c 
            							WHERE Advertiser__c =: advertiserId AND Agency__c != null AND Active__c= TRUE]);
            
            Map<String,Schema.RecordTypeInfo> rtMapByName =	Schema.SObjectType.Account.getRecordTypeInfosByName();
            if(rtMapByName.containskey(Label.ACC_RECORDTYPENAME_AGENCY)) {
            	res.put('agencyRecordTypeId', rtMapByName.get(Label.ACC_RECORDTYPENAME_AGENCY).getRecordTypeId());
            }						
            res.put('agencyRecordTypeId', Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.ACC_RECORDTYPENAME_AGENCY).getRecordTypeId());
            for( Account acc : [SELECT Name FROM Account WHERE Id =:advertiserId]) {
            	res.put('advertiser', acc);
            }

            response.statusCode = RemoteResponse.STATUSCODE_OK;
	        response.content = res;
	        response.message = 'successed';
	            
	    } catch (Exception e) {
	        response.statusCode = RemoteResponse.STATUSCODE_ERROR;
	        response.message = e.getMessage() + ' : ' + e.getStackTraceString();
	    }
	    return response;
	    
    }

    @AuraEnabled
    public static RemoteResponse createAdvAgencyRelation(String advertiserId, String agencyId, Advertiser_Agency_Relationship__c newAgencyFields, String phone, String contactName){
        RemoteResponse response = new RemoteResponse();
        try {
            Advertiser_Agency_Relationship__c advAgencyRel = new Advertiser_Agency_Relationship__c(
                                                                    Name = newAgencyFields.Name,
                                                                    Advertiser__c = advertiserId, 
                                                                    Agency__c = agencyId, 
                                                                    Active__c = true,
                                                                    Bill_To__c = newAgencyFields.Bill_To__c); 

            if(String.isNotBlank(contactName)){
                Contact contact = new Contact(  LastName = contactName, 
                                        AccountId = agencyId, 
                                        Email = newAgencyFields.Bill_To_Email__c,
                                        Phone = phone);
                insert contact;
                advAgencyRel.Bill_To_Contact__c = contact.Id;
            }
            insert advAgencyRel;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            response.content = advAgencyRel.id;
        } catch(Exception ex) {
            return new RemoteResponse(ex.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
        return response;

    }
}