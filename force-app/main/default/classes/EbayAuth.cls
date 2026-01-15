/*********************************************************************************************************************************
@ Class:          EbayAuth
@ Version:        1.0
@ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:        US-0009666 - [SEP] Setup ebay as a Custom External Authentication Provider
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.08.2021 / Acmatac SEING / Created the class.
@               : 30.05.2024 / Acmatac SEING / US-0015181 - Implement Seamless eBay SSO Authentication
*********************************************************************************************************************************/
global with sharing class EbayAuth extends Auth.AuthProviderPluginClass {

    private String customMetadataTypeApiName = 'Ebay_SSO_Provider__mdt';
    public  String redirectUrl; 
    private String key;
    private String secret;
    private String authUrl;  
    private String accessTokenUrl; 
    private String userInfoUrl; 
    private String scope;
    
    private static final String MOCK_HANDLECALLBACK = '{"userId":"testtest","username":"test","accountType":"INDIVIDUAL","registrationMarketplaceId":"EBAY_US", "access_token":"testToken"}';
    private static final String MOCK_GETUSERINFO = '{"userId":"testtest","username":"test","accountType":"INDIVIDUAL","registrationMarketplaceId":"EBAY_US", "access_token":"testToken"}';

    global String getCustomMetadataType(){
        return customMetadataTypeApiName;
    }
    
    /*********************************************************************************************************************************
    @ Change history: 30.05.2024 / Acmatac SEING / US-0015181 - Remove prompt=login from the parameter
    *********************************************************************************************************************************/
    /* Step 1 */
    global PageReference initiate(Map<string,string> authProviderConfiguration, String stateToPropagate) { 
    
        key         = authProviderConfiguration.get('Client_Id__c');
        authUrl     = authProviderConfiguration.get('Auth_URL__c');
        scope       = authProviderConfiguration.get('Scope__c');
        redirectUrl = authProviderConfiguration.get('Callback_URL__c');
        String urlToRedirect = authUrl+'?client_id='+key+'&redirect_uri='+redirectUrl+'&scope='+scope+
                               '&state='+stateToPropagate+'&response_type=code';
        PageReference pageRef = new PageReference(urlToRedirect);                    
        return pageRef; 
    } 
    
    /* Step 2 */
    global Auth.AuthProviderTokenResponse handleCallback(Map<string,string> authProviderConfiguration, Auth.AuthProviderCallbackState state ) { 
        
        // This will contain an optional accessToken and refreshToken 
        key = authProviderConfiguration.get('Client_Id__c'); 
        secret = authProviderConfiguration.get('Client_Secret__c'); 
        accessTokenUrl = authProviderConfiguration.get('Token_URL__c'); 
        redirectUrl = authProviderConfiguration.get('Callback_URL__c');

        Map<String,String> queryParams = state.queryParameters; 
        String code = queryParams.get('code'); 
        String sfdcState = queryParams.get('state'); 
        
        
        HttpRequest req = new HttpRequest(); 
        String requestBody = 'code='+code +'&redirect_uri='+redirectUrl+'&state='+sfdcState+'&grant_type=authorization_code';

        Blob headerValue = Blob.valueOf(key + ':' + secret);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
   
        Map<String, String> mapHeader = new Map<String, String>();
        mapHeader.put('Authorization', authorizationHeader);
        mapHeader.put('Accept', 'application/json');
        HTTPWrapper.IRequest request = new HTTPWrapper.SimpleRequest(accessTokenUrl,'GET',requestBody,mapHeader);
        HTTPWrapper.SimpleResponse response = new HTTPWrapper.SimpleResponse(request);
        response.mockBody = MOCK_GETUSERINFO; 
        Map<String,Object> mapResponse = (Map<String,Object>)JSON.deserializeUntyped(response.getResBody());
        
        if(mapResponse.containsKey('error'))
        {
            throw new EbayAuthException(mapResponse.get('error_description')+'');
        }

        return new Auth.AuthProviderTokenResponse('EbayAuth', mapResponse.get('access_token')+'', 'refreshToken', sfdcState); 
        
    } 
   
               
    global Auth.UserData getUserInfo(Map<string,string> authProviderConfiguration, Auth.AuthProviderTokenResponse response) { 
        userInfoUrl = authProviderConfiguration.get('User_Info_URL__c');
    
        Map<String, String> mapHeader = new Map<String, String>();
        mapHeader.put('Authorization', 'Bearer '+response.oauthToken);
        mapHeader.put('Content-Type', 'application/json');
        HTTPWrapper.IRequest request = new HTTPWrapper.SimpleRequest(userInfoUrl,'GET','',mapHeader);
        HTTPWrapper.SimpleResponse res = new HTTPWrapper.SimpleResponse(request); 
        res.mockBody = MOCK_HANDLECALLBACK; 
        Map<String,Object> mapResponse = (Map<String,Object>)JSON.deserializeUntyped(res.getResBody());
        if(mapResponse.containsKey('error'))
        {
            throw new EbayAuthException(mapResponse.get('error_description')+'');
        }
        // System.debug('### mapResponse '+mapResponse);

        // additional attribute can pass from this map
        Map<String,String> attributeMap = new Map<String,String>();
        Auth.UserData userdata = new Auth.UserData(mapResponse.get('userId')+'', null, null, null, null, 
                null, mapResponse.get('username')+'', 'en_US', 'eBay', null , attributeMap);
        
        return userdata;
    } 

    class EbayAuthException extends Exception{

    }

}