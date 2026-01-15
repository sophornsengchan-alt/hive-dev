/*********************************************************************************************************************************
@ Class:          ActionJourneyStatusController
//this is another test
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        EPH-6484 Add campaign members in SFMC journeys	- Controller for Aura: ActionJourneyStatus
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.09.2018 / Vadhanak Voun / Created the class.
*********************************************************************************************************************************/
public with sharing class ActionJourneyStatusController {
    //this is a test
    
    /*****************************************************************************************************************************
	@ Method:   apexPullStatus
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-6484 Add campaign members in SFMC journeys
	@			called from Aura: ActionJourneyStatus  
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      parentId:  campaignId
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 31.09.2018 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexPullStatus(String campaignId)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
    	
    	Campaign cam = Database.query(EBH_ConstantsUtility.CMRC_QUERY);
    	if(cam.Journey_ID__c==null || cam.Journey_Version__c==null)
    	{
    		mapResult.put('status','ko');
    		mapResult.put('error','Journey ID and Journey Version are required');
    		 
    	}else
    	{
    		try
    		{
    			String jstatus = requestStatus(EncodingUtil.urlEncode(cam.Journey_ID__c,'UTF-8'),cam.Journey_Version__c+'');
    			cam.Journey_Status__c = jstatus;
    			update cam;
    			
    			mapResult.put('status','ok');
    		}
    		catch(DmlException ex)
    		{
    			mapResult.put('status','ko');
    			mapResult.put('error',ex.getDmlMessage(0));
    			System.debug(ex);
    		}catch(Exception ex2)
    		{
    			mapResult.put('status','ko');
    			mapResult.put('error',ex2.getMessage());
    			System.debug(ex2);
    		}
    	}
    	
    	return mapResult;
    }
    /**
    	Host: https://www.exacttargetapis.com
		GET /interaction/v1/interactions/{journeyid}/{versionid}
		Content-Type: application/json
		Authorization: Bearer YOUR_ACCESS_TOKEN
		    */
    private static String requestStatus(String jid,String vid)
    {
    	MC_API__c mcCall = MC_API__c.getInstance('mc-call');
		if(mcCall==null || (mcCall <>null && !mcCall.Active__c))
		{
			throw new MCException('Credential for MC API call not defined or not Active in Custom Setting: MC_API__c');
		}
		String token =  requestToken();
		Map<String,String> mapHeader = new Map<String,String>{
		'Content-Type'=>'application/json',
		'Authorization'=>'Bearer '+token 
		}; 
					  
		//String ss = 'https://www.exacttargetapis.com/interaction/v1/interactions/ced8569f-e1be-49a3-9385-046840021e83?versionNumber=3';
		String url = mcCall.Endpoint__c+jid+'?versionNumber='+vid;
		Map<String,String> resMap = sendRequest(url,'GET',mapHeader,null);
		Map<String,Object> resMapJS = (Map<String,Object>) JSON.deserializeUntyped(resMap.get('resBody'));
		
		if(resMapJS.containsKey('errorcode')) 
		{
			throw new MCException('MC returns errorcode: '+resMapJS.get('errorcode')+'.\nMessage: '+resMapJS.get('message'));
		}else
		{
			return resMapJS.get('status')+'';
		}
		
    } 
    
    /**
    	To retrieve access token - 
		REST API POST https://auth.exacttargetapis.com/v1/requestToken
		Body :
		clientId - xxxxx
		clientSecret - yyyyy
		*/
    private static String requestToken()
    {
		MC_API__c mcAuth = MC_API__c.getInstance('mc-auth');
		if(mcAuth==null || (mcAuth <>null && !mcAuth.Active__c))
		{
			throw new MCException('Authentication Credential for MC not defined or not Active in Custom Setting: MC_API__c');
		}
		String reqBody = 'clientId='+mcAuth.Client_Id__c +'&clientSecret='+mcAuth.Secret__c	;
		Map<String,String> resMap = sendRequest(mcAuth.Endpoint__c,'POST',null,reqBody);
		Map<String,String> resMapJS = (Map<String,String>) JSON.deserialize(resMap.get('resBody'),Map<String,String>.class);
		//System.debug('>>>: resMap: '+resMapSS);
		
		 
    	return resMapJS.get('accessToken');
    }
     
    private static Map<String,String> sendRequest(String endpoint,String method,Map<String,String> mapHeader,String body)
    {
    	Map<String,String> mapResult = new Map<String,String>();
    	HttpRequest req = new HttpRequest();
		req.setEndpoint(endpoint);
		req.setMethod(method);
		if(body<>null)req.setBody(body);
		if(mapHeader <> null && !mapHeader.isEmpty())
		{
			for(String k: mapHeader.keySet())
			{
				req.setHeader(k, mapHeader.get(k));
			}
		}
		 
		Http http = new Http();
		HTTPResponse res = http.send(req);
		//System.debug('>>>>>body:'+res.getBody());
		
		mapResult.put('resBody',res.getBody());
		
    	return mapResult;
    }
    
    class MCException extends Exception{} 
    
}