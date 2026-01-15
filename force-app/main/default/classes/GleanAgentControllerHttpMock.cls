/*********************************************************************************************************************************
@ Class:          GleanAgentController
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        US-0033581 - 3. Connect Glean Agent from chat component
@ Test Class:     GleanAgentControllerTest
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.10.2025 / Sophal Noch / Created the class.
                : 12.11.2025 / Sophal Noch / US-0033813 - Feedback on Glean custom chat component
*********************************************************************************************************************************/
@isTest
public with sharing class GleanAgentControllerHttpMock {
    public static String getAccessToken(){
        return ApexUtil.genUniqueStringNoSymbol(16);
    }

    public static ThirdPartyAccountLink getMSAuthProvider(){
        ThirdPartyAccountLink tpal = new ThirdPartyAccountLink();
        return tpal;
    }


    public static HTTPResponse getUserAuthorizationHttpResponse() {
        HttpResponse res = new HttpResponse();
        res.setBody('{"agent_id":"b840a9eb46dc42c1b30ec3a345618744","name":"Seller CRM (HIVE) General Assistant 1.0","description":"This app provides HIVE specific process and features assistance.","capabilities":{"ap.io.messages":true,"ap.io.streaming":true}}');
        res.setStatusCode(200);
        res.setStatus('OK');
        return res;
    }

    public static HTTPResponse getDefaultAgentHttpResponse() {
        HttpResponse res = new HttpResponse();
        List<StaticResource> listSr = ApexSafe.query().secCheck(false).doQuery('SELECT Id, Body FROM StaticResource WHERE Name = \'gleanChatMockResponse\' LIMIT 1');
        String sseData = listSr[0].Body.toString();
        res.setBody(sseData);
        res.setStatusCode(200);
        res.setStatus('OK');
        return res;
    }

    public static HTTPResponse getChatHistoryHttpResponse() {
        // 12.11.2025 / Sophal Noch / US-0033813
        HttpResponse res = new HttpResponse();
        List<StaticResource> listSr = ApexSafe.query().secCheck(false).doQuery('SELECT Id, Body FROM StaticResource WHERE Name = \'gleanGetChatMockResponse\' LIMIT 1');
        String sseData = listSr[0].Body.toString();
        res.setBody(sseData);
        res.setStatusCode(200);
        res.setStatus('OK');
        return res;
    }
}