@isTest
private class EbayAuthTest {
        private static final String OAUTH_TOKEN = 'testToken'; 
        private static final String STATE = 'mocktestState'; 
        private static final String REFRESH_TOKEN = 'refreshToken'; 
        private static final String LOGIN_ID = 'testLoginId'; 
        private static final String USERNAME = 'testUsername'; 
        private static final String FIRST_NAME = 'testFirstName'; 
        private static final String LAST_NAME = 'testLastName'; 
        private static final String EMAIL_ADDRESS = 'testEmailAddress'; 
        private static final String LOCALE_NAME = 'testLocalName'; 
        private static final String FULL_NAME = FIRST_NAME + ' ' + LAST_NAME; 
        private static final String PROVIDER = 'eBay'; 
        private static final String CALLBACK_URL = 
        'http://localhost/services/authcallback/orgId/ebay'; 
        private static final String KEY = 'testKey'; 
        private static final String SECRET = 'testSecret'; 
        private static final String STATE_TO_PROPOGATE = 'testState'; 
        private static final String TOKEN_URL = 
        'http://www.dummyhost.com/accessTokenUri'; 
        private static final String API_USER_VERSION_URL = 
        'http://www.dummyhost.com/user/20/1'; 
        private static final String AUTH_URL = 
        'http://www.dummy.com/authurl'; 
        private static final String USER_INFO_URL = 
        'www.ebaysolutions.com/user/api'; 
    
    // In the real world scenario, the key and value would be read 
    // from the (custom fields in) custom metadata type record. 
    private static Map<String,String> setupAuthProviderConfig () 
    { 
        Map<String,String> authProviderConfiguration = new Map<String,String>(); 
        authProviderConfiguration.put('Client_Id__c', KEY); 
        authProviderConfiguration.put('Auth_URL__c', AUTH_URL); 
        authProviderConfiguration.put('Client_Secret__c', SECRET); 
        authProviderConfiguration.put('Token_URL__c', TOKEN_URL); 
        authProviderConfiguration.put('User_Info_URL__c',USER_INFO_URL); 
        authProviderConfiguration.put('Callback_URL__c',CALLBACK_URL); 
        authProviderConfiguration.put('State_c',STATE); 
        return authProviderConfiguration; 
    
    } 
    @isTest
    private static void testInitiateMethod() 
    { 
        String stateToPropogate = 'mocktestState'; 
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig(); 
        EbayAuth ebayAuthCls = new EbayAuth(); 
        String key         = authProviderConfiguration.get('Client_Id__c');
        String authUrl     = authProviderConfiguration.get('Auth_URL__c');
        String scope       = authProviderConfiguration.get('Scope__c');
        String redirectUrl = authProviderConfiguration.get('Callback_URL__c');
        String urlToRedirect = authUrl+'?client_id='+key+'&redirect_uri='+redirectUrl+'&scope='+scope+
                               '&state='+STATE_TO_PROPOGATE+'&response_type=code';
                               
        PageReference expectedUrl = new PageReference(urlToRedirect); 

        PageReference actualUrl = ebayAuthCls.initiate(authProviderConfiguration, STATE_TO_PROPOGATE); 
        System.assertEquals(expectedUrl.getUrl(), actualUrl.getUrl());
    } 
    @isTest
    private static void testHandleCallback() 
    { 
        Map<String,String> authProviderConfiguration = 
        setupAuthProviderConfig(); 
        EbayAuth ebayAuthCls = new EbayAuth(); 
        ebayAuthCls.redirectUrl = authProviderConfiguration.get
        ('CALLBACK_Url_c'); 
    
        Map<String,String> queryParams = new Map<String,String>(); 
        queryParams.put('code','code'); 
        queryParams.put('state',authProviderConfiguration.get('State_c')); 
        Auth.AuthProviderCallbackState cbState = 
        new Auth.AuthProviderCallbackState(null,null,queryParams); 
        Auth.AuthProviderTokenResponse actualAuthProvResponse = 
        ebayAuthCls.handleCallback(authProviderConfiguration, cbState); 
        Auth.AuthProviderTokenResponse expectedAuthProvResponse = 
        new Auth.AuthProviderTokenResponse(
        'EbayAuth', OAUTH_TOKEN, REFRESH_TOKEN, null); 
    
        System.assertEquals(expectedAuthProvResponse.provider, 
        actualAuthProvResponse.provider); 
        System.assertEquals(expectedAuthProvResponse.oauthToken, 
        actualAuthProvResponse.oauthToken); 
        System.assertEquals(expectedAuthProvResponse.oauthSecretOrRefreshToken, 
        actualAuthProvResponse.oauthSecretOrRefreshToken); 
    } 
    @isTest
    private static void testGetUserInfo() 
    { 
        Map<String,String> authProviderConfiguration = 
        setupAuthProviderConfig(); 
        EbayAuth ebayAuthCls = new EbayAuth(); 
    
        Auth.AuthProviderTokenResponse response = new Auth.AuthProviderTokenResponse(PROVIDER, OAUTH_TOKEN ,'sampleOauthSecret', STATE); 
        Auth.UserData actualUserData = ebayAuthCls.getUserInfo(authProviderConfiguration, response) ; 
    
        Map<String,String> provMap = new Map<String,String>(); 
        provMap.put('key1', 'value1'); 
        provMap.put('key2', 'value2'); 
    
        Auth.UserData expectedUserData = new Auth.UserData(LOGIN_ID, 
        FIRST_NAME, LAST_NAME, FULL_NAME, EMAIL_ADDRESS, 
        null, LOCALE_NAME, null, PROVIDER, null, provMap); 
    
        System.assertNotEquals(expectedUserData,null); 
    } 
    
    @isTest
    private static void testGetCustomMetadataType() 
    {
        EbayAuth ebayAuthCls = new EbayAuth();
        ebayAuthCls.getCustomMetadataType();
    }
    
}