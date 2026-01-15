/*********************************************************************************************************************************
@ Class:          GleanAgentController
@ Version:        1.0
@ Author:         Sambath Seng
@ Purpose:        Controller for lwc: chatGleanCmp US-0033579
@ Test Class:     GleanAgentControllerTest
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.10.2025 / Sambath Seng / Created the class.
                : 21.10.2025 / Sophal Noch / US-0033581 - 3. Connect Glean Agent from chat component
                : 12.11.2025 / Sophal Noch / US-0033813 - Feedback on Glean custom chat component
                : 14.11.2025 / Vimean Heng / US-0033583 - 4. Display Predefined Prompts in Chat UI
*********************************************************************************************************************************/
public with sharing class GleanAgentController {

    private static final String CLASS_NAME = 'GleanAgentController';
    private static final String MT_NAME_IS_USER_AUTHORIZED = 'isUserAuthorized';
    private static final String MT_NAME_GET_AGENT_RESPONSE = 'getAgentResponse';
    private static final String MT_NAME_GET_GLEAN_AGENT_OPTIONS = 'getGleanAgentOptions';
    private static final String MT_NAME_PARSE_RESPONSE_BODY = 'parseResponseBody';
    private static final String MT_NAME_GET_CHAT_HISTORY = 'getChatHistory';
    private static final String MT_NAME_PARSE_GET_CHAT_RESPONSE_BODY = 'parseGetChatResponseBody';

    // Glean API Configuration
    private static final String GLEAN_NAMED_CREDENTIAL = 'callout:Glean_AI_NC';
    private static final String GLEAN_CHAT_ENDPOINT = GLEAN_NAMED_CREDENTIAL + '/rest/api/v1/chat';
    private static final String GLEAN_GET_DEFAULT_AGENT_ENDPOINT = GLEAN_NAMED_CREDENTIAL + '/rest/api/v1/agents/';
    private static final String GLEAN_GET_CHAT_ENDPOINT = GLEAN_NAMED_CREDENTIAL + '/rest/api/v1/getchat'; // 12.11.2025 / Sophal Noch / US-0033813 :get chat history

    // HTTP Configuration
    private static final Integer HTTP_TIMEOUT = 120000;
    private static final String METHOD_GET = 'GET';
    private static final String METHOD_POST = 'POST';
    private static final Integer RESPONSE_CODE_200 = 200;
    private static final String HD_KEY_AUTHORIZATION = 'Authorization';
    private static final String HD_VAL_AUTHORIZATION = 'Bearer ';

    private static final String EMPTY_STRING = '';
    private static final String PROP_ID = 'id';

    // Authentication Configuration
    private static final String MS_PROVIDER_NAME = 'Microsoft';
    private static final String AUTH_PROVIDER_NAME = 'Microsoft_Glean_Auth';
    private static final String MS_AUTH_PROD_URL = '/services/auth/oauth/Microsoft_Glean_Auth';

    private static final String SOQL_THIRD_PARTY = 'SELECT Id, SsoProviderId, Provider, UserId, RemoteIdentifier FROM ThirdPartyAccountLink WHERE UserId = :userId AND SsoProvider.DeveloperName = :authProviderName LIMIT 1';
    private static final String SOQL_AGENT_METADATA = 'Select Id,MasterLabel,Prompts_Id__c,IsDefault__c,Agent_Created_By__c FROM GleanAgent_Config__mdt WHERE IsActive__c = true ORDER BY IsDefault__c DESC, MasterLabel ASC';
    private static final String SOQL_GET_USER_CHAT_ID = 'SELECT Glean_Chat_Id__c FROM User WHERE Id = :userId LIMIT 1';

    private static ThirdPartyAccountLink thirdPartyMSAuth { // get auth provider for microsoft from current user
        get{
            if(thirdPartyMSAuth == null){
                User currentUser = ApexUtil.getCurrentUser();
                List<ThirdPartyAccountLink> listTpl = ApexSafe.query().secCheck(false).doQuery(SOQL_THIRD_PARTY, new Map<String, Object> {'userId' => currentUser?.Id, 'authProviderName' => AUTH_PROVIDER_NAME});
                if(!listTpl.isEmpty() && !Test.isRunningTest()){
                    thirdPartyMSAuth = listTpl[0];
                }
                thirdPartyMSAuth = Test.isRunningTest() ? GleanAgentControllerHttpMock.getMSAuthProvider() : thirdPartyMSAuth;

            }
           return thirdPartyMSAuth;
        }
        set;
    }

    private static GleanAgentOption defaultAgent{ // get default agent from metadata
        get{
            if(defaultAgent == null){
                List<GleanAgentOption> agentOptions = getGleanAgentOptions();
                for(GleanAgentOption agent : agentOptions){
                    if(agent.isDefault){
                        defaultAgent = agent;
                        break;
                    }
                }
            }
           return defaultAgent ;
        }
        set;
    }

    /*********************************************************************************************************************************
    @ Method:         getAuthUrl
    @ Author:         Sambath Seng
    @ Purpose:        Get Auth Provider Url
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.10.2025 / Sambath Seng / US-0033579
    @*****************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static String getAuthUrl() {
        return URL.getOrgDomainUrl().toExternalForm() + MS_AUTH_PROD_URL;
    }


    /*********************************************************************************************************************************
    @ Class:          getAgentResponse
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        Controller for lwc: chatGleanCmp
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.10.2025 / Sambath Seng / Created the method.
                    : 21.10.2025 / Sophal Noch / US-0033581 - 3. Connect Glean Agent from chat component
                    : 12.11.2025 / Sophal Noch / US-0033813 - Feedback on Glean custom chat component
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=false)
    public static AgentResponse getAgentResponse(String agentId, String userMessage, String chatId) {
        // send question to glean agent and get response
        AgentResponse agentResponse;
        try {
            agentResponse = new AgentResponse();
            String responseText = EMPTY_STRING;
            agentResponse.chatId = chatId;

            GleanChatHttpRequest gleanRequest = new GleanChatHttpRequest(agentId, userMessage, chatId);
            String requestBody = gleanRequest.toJson();

            HttpRequest request = prepareGleanRequest(GLEAN_CHAT_ENDPOINT, METHOD_POST, requestBody);
            // Send the request.
            Http http = new Http();
            HttpResponse response = Test.isRunningTest() ? GleanAgentControllerHttpMock.getDefaultAgentHttpResponse() : http.send(request);

            // Process the response.
            if (response.getStatusCode() == RESPONSE_CODE_200) {
                GleanChatHttpResponse gleanChatRes = parseResponseBody(response.getBody());
                responseText = gleanChatRes?.getChatResponseText();
                agentResponse.chatId = gleanChatRes?.getChatId();
                updateUserGleanChatId(agentResponse.chatId); // 12.11.2025 / Sophal Noch / US-0033813 : update chat id to user record

            } else {
                responseText  = Label.Glean_Error_Agent_Is_Not_Available + response.getBody();
                EBH_ApexLogger.logError(new List<Exception>{new GleanAgentException(responseText)}, CLASS_NAME, MT_NAME_GET_AGENT_RESPONSE);
            }

            agentResponse.responseText = responseText;

        } catch (Exception e) {
            EBH_ApexLogger.logError(new List<Exception>{e}, CLASS_NAME, MT_NAME_GET_AGENT_RESPONSE);
        }

        return agentResponse;
    }

    /*********************************************************************************************************************************
    @ Method:         parseResponseBody
    @ Author:         Sophal Noch
    @ Purpose:        US-0033581 - 3. Connect Glean Agent from chat component
    @ Parameter:      responseBody - JSON string response from Glean API
    @ Return:         GleanChatHttpResponse object
    @ Change history: 23.10.2025 / Sophal Noch / Create method
    *********************************************************************************************************************************/
    private static GleanChatHttpResponse parseResponseBody(String responseBody) {
        // parse response body from glean agent
        GleanChatHttpResponse gleanChatRes;
        try {
            gleanChatRes = GleanChatHttpResponse.parse(responseBody);
        } catch (Exception e) {
            String errMsg = String.format(Label.Glean_Error_Parsing_Response_Body,  new List<String>{e.getMessage(), responseBody});
            EBH_ApexLogger.logError(new List<GleanAgentException>{new GleanAgentException(errMsg)}, CLASS_NAME, MT_NAME_PARSE_RESPONSE_BODY);
        }
         return gleanChatRes;
    }

    /*********************************************************************************************************************************
    @ Method:         prepareGleanRequest
    @ Author:         Sophal Noch
    @ Purpose:        US-0033581 - 3. Connect Glean Agent from chat component
    @ Parameter:      endPoint - The API endpoint URL, method - HTTP method (GET, POST, etc.),JSON request body
    @ Return:         return HttpRequest - Configured HTTP request object
    @ Change history: 21.10.2025 / Sophal Noch / Create method
    *********************************************************************************************************************************/
    private static HttpRequest prepareGleanRequest(String endPoint, String method, String requestBody){

            // reusable method to prepare Glean HTTP request

            // Initialize the HTTP request.
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endPoint);
            request.setMethod(method);
            request.setTimeout(HTTP_TIMEOUT);

            String accessToken = getAccessToken(); // get access token from Auth Provider
            request.setHeader(HD_KEY_AUTHORIZATION, HD_VAL_AUTHORIZATION + accessToken); 

            if(String.isNotBlank(requestBody)){
                request.setBody(requestBody);
            }
            return request;
    }

    /*********************************************************************************************************************************
    @ Method:         getChatById
    @ Author:         Sophal Noch
    @ Purpose:        US-0033813 - Feedback on Glean custom chat component
    @ Change history: 10.11.2025 / Sophal Noch / Create method
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=false)
    public static List<GleanGetChatHttpResponse.CustomChatItem> getChatById(String chatId) {
        // get chat history by chat id
        List<GleanGetChatHttpResponse.CustomChatItem> listCustomChatItem;
        try {
            Map<String, String> mapRequest = new Map<String, String>(); 
            mapRequest.put(PROP_ID, chatId);
            String requestBody = JSON.serialize(mapRequest);

            HttpRequest request = prepareGleanRequest(GLEAN_GET_CHAT_ENDPOINT, METHOD_POST, requestBody);
            // Send the request.
            Http http = new Http();
            HttpResponse response = Test.isRunningTest() ?  GleanAgentControllerHttpMock.getChatHistoryHttpResponse() : http.send(request);
            // Process the response.
            if (response.getStatusCode() == RESPONSE_CODE_200) {
                GleanGetChatHttpResponse gleanGetChatRes = parseGetChatResponseBody(response.getBody()); // parse chat history response
                listCustomChatItem = gleanGetChatRes.getChatItems(); // extract custom chat items from response
            } else {
                EBH_ApexLogger.logError(new List<Exception>{new GleanAgentException(response.getBody())}, CLASS_NAME, MT_NAME_GET_CHAT_HISTORY);
            }
        } catch (Exception e) {
            EBH_ApexLogger.logError(new List<Exception>{e}, CLASS_NAME, MT_NAME_GET_CHAT_HISTORY);
        }

        return listCustomChatItem;
    }

    /*********************************************************************************************************************************
    @ Method:         getChatById
    @ Author:         Sophal Noch
    @ Purpose:        US-0033813 - Feedback on Glean custom chat component
    @ Change history: 10.11.2025 / Sophal Noch / Create method
    *********************************************************************************************************************************/
    private static GleanGetChatHttpResponse parseGetChatResponseBody(String responseBody) {
        // parse chat history response body from glean agent
        GleanGetChatHttpResponse resp;
        try {
            resp = GleanGetChatHttpResponse.parse(responseBody);
        } catch (Exception e) {
           String errMsg = String.format(Label.Glean_Error_Parsing_Response_Body,  new List<String>{e.getMessage(), responseBody});
           EBH_ApexLogger.logError(new List<GleanAgentException>{new GleanAgentException(errMsg)}, CLASS_NAME, MT_NAME_PARSE_GET_CHAT_RESPONSE_BODY);
        }
        return resp;
    }


    /*********************************************************************************************************************************
    @ Method:         isUserAuthorized
    @ Author:         Sambath Seng
    @ Purpose:        Check access token
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.10.2025 / Sambath Seng / US-0033579
    @*****************************************************************************************************************************/
    @AuraEnabled(cacheable=false)
    public static Boolean isUserAuthorized() {
        Boolean isAuthorized = false;
        try {

            if(thirdPartyMSAuth != null){

                HttpResponse response;

                String accessToken = getAccessToken();

                if(String.isNotBlank(accessToken)){

                    // Safe access to defaultAgent
                    GleanAgentOption defAgent = defaultAgent;
                    String agentValue = (defAgent != null && String.isNotBlank(defAgent.value)) ? defAgent.value : Label.Glean_Value_Hive_Default;
                    
                    String endPoint = GLEAN_GET_DEFAULT_AGENT_ENDPOINT + agentValue;
                    HttpRequest request = prepareGleanRequest(endPoint, METHOD_GET, null);
                    Http http = new Http();
                    response= Test.isRunningTest() ? GleanAgentControllerHttpMock.getUserAuthorizationHttpResponse() : http.send(request);

                    if(response?.getStatusCode() == RESPONSE_CODE_200){
                        isAuthorized = true;
                    }else if(!Test.isRunningTest()){
                        Auth.AuthToken.revokeAccess(thirdPartyMSAuth?.SsoProviderId, thirdPartyMSAuth?.Provider, thirdPartyMSAuth?.UserId, thirdPartyMSAuth?.RemoteIdentifier);
                    }
                }
            }

        } catch (Exception e) {
            // If an exception occurs, it means the token could not be retrieved
            // for various reasons (e.g., not yet authorized), so we return false
            EBH_ApexLogger.logError(new List<Exception>{e}, CLASS_NAME, MT_NAME_IS_USER_AUTHORIZED);
        }
        return isAuthorized;
    }

    /*********************************************************************************************************************************
    @ Method:         getGleanAgentOptions
    @ Author:         Sambath Seng
    @ Purpose:        Retrieve Glean Agent from Custom Metadata
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.10.2025 / Sambath Seng / US-0033579
    @*****************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<GleanAgentOption> getGleanAgentOptions() {
        List<GleanAgentOption> agentOptions = new List<GleanAgentOption>();
        
        try {
            List<GleanAgent_Config__mdt> agentConfigs = ApexSafe.query().secCheck(false).doQuery(SOQL_AGENT_METADATA);
            
            for (GleanAgent_Config__mdt config : agentConfigs) {
                GleanAgentOption option = new GleanAgentOption();
                if(config.IsDefault__c || config.Agent_Created_By__c == UserInfo.getUserName()){
                    option.label = config.MasterLabel + (config.IsDefault__c ? ' ' + Label.Glean_Const_Default : EMPTY_STRING);
                    option.value = config.Prompts_Id__c;
                    option.isDefault = config.IsDefault__c;
                    agentOptions.add(option);
                }
            }
            
        } catch (Exception e) {
            // Return fallback options if metadata query fails
            agentOptions.add(new GleanAgentOption(Label.Glean_Const_Hive_Assistant + ' ' + Label.Glean_Const_Default, Label.Glean_Value_Hive_Default, true));
            EBH_ApexLogger.logError(new List<Exception>{e}, CLASS_NAME, MT_NAME_GET_GLEAN_AGENT_OPTIONS);
        }
        
        return agentOptions;
    }

    /*********************************************************************************************************************************
    @ Method:         getChatId
    @ Author:         Sophal Noch
    @ Purpose:        US-0033813 - Feedback on Glean custom chat component
    @ Change history: 21.10.2025 / Sophal Noch / Create method
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=false)
    public static String getChatId() {
        // get chat id from user
        String chatId = getUserGleanChatId();
        return chatId;
    }

    private static String getUserGleanChatId() {
        // retrieve glean chat id because previous chat id is stored in user record
        User currentUser = ApexUtil.getCurrentUser();
        List<User> listUser = ApexSafe.query().doQuery(SOQL_GET_USER_CHAT_ID, new Map<String, Object> {'userId' => currentUser?.Id});
        return listUser.isEmpty() ? null : listUser[0].Glean_Chat_Id__c;
    }

    private static void updateUserGleanChatId(String chatId) {
        // Update chat id to the user
        String userChatId = getUserGleanChatId();
        User currentUser = ApexUtil.getCurrentUser();
        if(String.isNotBlank(chatId) && chatId != userChatId){
            ApexSafe.dml().doUpdate(new List<User>{ new User(Id = currentUser.Id, Glean_Chat_Id__c = chatId) }, true);
        }
    }

    private static String getAccessToken() {
        // get autheticate from Auth Provider Token
        String accessToken = Test.isRunningTest() ? GleanAgentControllerHttpMock.getAccessToken() : Auth.AuthToken.getAccessToken(thirdPartyMSAuth?.SsoProviderId, MS_PROVIDER_NAME);
        return accessToken;
    }

    /*********************************************************************************************************************************
    @ Method:         getConversationStarters
    @ Author:         Vimean Heng
    @ Purpose:        Retrieve conversation starters from Custom Metadata for a specific agent
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      agentName - The name of the agent to get conversation starters for
    @ Return:         List<String> - List of conversation starter texts
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: : 14.11.2025 / Vimean Heng / US-0033583 - 4. Display Predefined Prompts in Chat UI
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=false)
    public static List<String> getConversationStarters(String agentName) {
        List<String> starters = new List<String>();
        try {
            // Query custom metadata for conversation starters
            String soqlQuery = 'SELECT Starter_Text__c FROM GleanConversationStarter__mdt ' +
                             'WHERE Active__c = true AND Agent_Name__c = :agentName ' +
                             'ORDER BY Sort_Order__c ASC LIMIT 10';
            
            //List<GleanConversationStarter__mdt> starterRecords = Database.query(soqlQuery);
            List<GleanConversationStarter__mdt> starterRecords = ApexSafe.query().secCheck(false).doQuery(soqlQuery, new Map<String, Object> {'agentName' => agentName});
            for (GleanConversationStarter__mdt record : starterRecords) {
                if (String.isNotBlank(record.Starter_Text__c)) {
                    starters.add(record.Starter_Text__c);
                }
            }
        } catch (Exception e) {
            System.debug('Error retrieving conversation starters: ' + e.getMessage());
        }
        return starters;
    }

    /*********************************************************************************************************************************
    @ Method:         getAccountSummaryAgent
    @ Author:         Mohit Methi
    @ Purpose:        Get the Account Summary agent configuration from Glean_Assistant__mdt custom metadata
    ------------------------------------------------------------------------------------------------------------------------------
    @ Return:         String - The Application ID for Account Summary agent
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.12.2025 / Mohit Methi / Created to retrieve Account Summary agent from custom metadata
    *********************************************************************************************************************************/
    private static String getAccountSummaryAgent() {
        String agentId = null;
        try {
            // Query Glean_Assistant__mdt for Account Summary agent configuration
            String soqlQuery = 'SELECT Application_Id__c FROM Glean_Assistant__mdt WHERE Object_Name__c = \'AccountSummary\' LIMIT 1';
            List<SObject> gleanAssistants = Database.query(soqlQuery);
            
            if (!gleanAssistants.isEmpty()) {
                agentId = String.valueOf(gleanAssistants[0].get('Application_Id__c'));
            }
        } catch (Exception ex) {
            EBH_ApexLogger.logError(new List<Exception>{ex}, CLASS_NAME, 'getAccountSummaryAgent');
        }
        
        // Fallback to default agent if Account Summary agent not found
        if (String.isBlank(agentId)) {
            GleanAgentOption defAgent = defaultAgent;
            agentId = (defAgent != null && String.isNotBlank(defAgent.value)) 
                      ? defAgent.value 
                      : Label.Glean_Value_Hive_Default;
        }
        
        return agentId;
    }

    /*********************************************************************************************************************************
    @ Method:         getAccountSummary
    @ Author:         Mohit Methi
    @ Purpose:        Get account summary from Glean AI Agent for Account record page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accountId - The Account record ID
    @                 accountName - The Account name
    @                 oracleId - The Account Oracle ID (EBH_OracleID__c)
    @ Return:         AgentResponse - Contains the summary text and chatId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 01.12.2025 / Mohit Methi / Created for Account Summary component
                    : 04.12.2025 / Mohit Methi / Use default agent (same as chat component)
                    : 10.12.2025 / Mohit Methi / Use dedicated Account Summary agent from Glean_Assistant__mdt metadata
                    : 12.12.2025 / Mohit Methi / Updated prompt to include Oracle ID and Account Name
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=false)
    public static AgentResponse getAccountSummary(String accountId, String accountName, String oracleId) {
        AgentResponse agentResponse = new AgentResponse();
        try {
            // Build the prompt with Salescloud context, type, Oracle ID and Account Name
            String userMessage = 'app:Salescloud appinstance:"HIVE Salesforce" Type:"Account" OracleID:' + oracleId + ' ' + accountName;
            
            // Use dedicated Account Summary agent from Glean_Assistant__mdt custom metadata
            String agentId = getAccountSummaryAgent();
            
            if (String.isBlank(agentId)) {
                agentResponse.responseText = Label.Glean_Error_Could_Not_Get_Response;
                return agentResponse;
            }
            
            // Create new chat session for each summary request
            GleanChatHttpRequest gleanRequest = new GleanChatHttpRequest(agentId, userMessage, null);
            HttpRequest request = prepareGleanRequest(GLEAN_CHAT_ENDPOINT, METHOD_POST, gleanRequest.toJson());
            
            // Send the request
            Http http = new Http();
            HttpResponse response = Test.isRunningTest() ? GleanAgentControllerHttpMock.getDefaultAgentHttpResponse() : http.send(request);
            
            // Process the response
            if (response.getStatusCode() == RESPONSE_CODE_200) {
                GleanChatHttpResponse gleanChatRes = parseResponseBody(response.getBody());
                agentResponse.responseText = gleanChatRes?.getChatResponseText();
                agentResponse.chatId = gleanChatRes?.getChatId();
            } else {
                agentResponse.responseText = Label.Glean_Error_Agent_Is_Not_Available + response.getBody();
                EBH_ApexLogger.logError(new List<Exception>{new GleanAgentException(response.getBody())}, CLASS_NAME, 'getAccountSummary');
            }

        } catch (Exception e) {
            agentResponse.responseText = Label.Glean_Error_Could_Not_Get_Response;
            EBH_ApexLogger.logError(new List<Exception>{e}, CLASS_NAME, 'getAccountSummary');
        }
        
        return agentResponse;
    }
    

    // Wrapper class for glean agent options
    public class GleanAgentOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public Boolean isDefault { get; set; }

        public GleanAgentOption(){
            this.label = EMPTY_STRING;
            this.value = EMPTY_STRING;
            this.isDefault = false;
        }
        
        public GleanAgentOption(String label, String value, Boolean isDefault) {
            this.label = label;
            this.value = value;
            this.isDefault = isDefault;
        }
    }

    public class AgentResponse {

        @AuraEnabled
        public String chatId; 

        @AuraEnabled
        public String responseText;
    }

    private class GleanAgentException extends Exception {

    }


}