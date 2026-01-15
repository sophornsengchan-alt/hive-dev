/**
 * Author : Gaeasys
 * CreatedDate: 31-May-2018
 * Description: Create new Opportunity from: Opportunity tab, Related list in Advertiser/Agency
 */
public with sharing class LC_NewOpportunity {
    /**
     * Get Opportunity Stage Picklist
     * @return List String
     */
    //@AuraEnabled
    //public static List<String> getOppStagePicklist() {
    //    List<String> options = new List<String>();
    //    //String opts;
    //    //Getting The Object's Picklist's Values
    //    Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
    //    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

    //    //Adding the Picklist Values into An Array
    //    for(Schema.PicklistEntry f : ple){
    //       options.add(f.getLabel());
    //     }
    //    //Stringifying The Array and Assigning It To A String
    //    //opts = JSON.serialize(options);
    //    return options;
    //}
    
    @AuraEnabled
    public static RemoteResponse initializeData(String advId, String agencyId, String advAgentRelId){
    	RemoteResponse response = new RemoteResponse();
	    try {
	    	Map <String, Object> res = new Map <String, Object> ();

	    	List<Advertiser_Agency_Relationship__c> lstaar = (List<Advertiser_Agency_Relationship__c>) QueryUtil.queryRecords(Util.NS+'Advertiser_Agency_Relationship__c', 
                    Util.NS+'Agency__c =: value1 AND '+Util.NS+'Advertiser__c =: value2 AND Id=:value3',
                    new Set<String>{Util.NS+'Agency__r.Name', Util.NS+'Advertiser__r.Name'},
                    new Map<String,Object>{'value1'=>agencyId,'value2'=>advId,'value3'=>advAgentRelId});
	    
            if( lstaar.isEmpty() ){
                if(String.isNotBlank(advId)) res.put('advertiser', QueryUtil.queryRecord(advId));
                if(String.isNotBlank(agencyId)) res.put('agency', QueryUtil.queryRecord(agencyId));
                res.put('aar', new Advertiser_Agency_Relationship__c());
            }else{
                res.put('aar', lstaar.get(0));
                res.put('advertiser', lstaar.get(0).Advertiser__r);
                res.put('agency', lstaar.get(0).Agency__r);
            }
            res.put('msg', 'successed');
            res.put('userId', UserInfo.getUserId());

            response.statusCode = RemoteResponse.STATUSCODE_OK;
            response.content = res;
            response.message = 'successed';
	            
	    } catch (Exception e) {
	        response.statusCode = RemoteResponse.STATUSCODE_ERROR;
            response.message = e.getMessage() + ':' + e.getStackTraceString();
	    }
	    return response;
	    
    }
}