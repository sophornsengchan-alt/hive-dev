@isTest	
private class ActionJourneyStatusControllerTest {
    
    static testMethod void testPullJourneyStatus() {
    	setupCustomSetting();
    	List<Campaign> listCamp = EBH_TestDataFactory.createCampaigns(2, 'test camp1', 'UK','EBH_Campaign');
    	listCamp[0].Journey_ID__c = 'xxxd8569f-e1be-49a3-9385-046840021yyy';
		listCamp[0].Journey_Version__c = 3;
		update listCamp[0];
    		
    	Test.startTest();
    	
	    	Map<String,Object> mapResult = ActionJourneyStatusController.apexPullStatus(listCamp[1].Id);
	    	
	    	System.assertEquals('ko',mapResult.get('status'),'no journey id error');
	    	System.assertEquals('Journey ID and Journey Version are required',mapResult.get('error'),'no journey id error');
    		
    		
    		
    		MockHttpMC mcMock = new MockHttpMC();
    		Test.setMock(HttpCalloutMock.class, mcMock);
    		
    		mapResult = ActionJourneyStatusController.apexPullStatus(listCamp[0].Id);
    		
    	Test.stopTest();
    	 
    }
    
    static void setupCustomSetting()
    {
    	insert new List<MC_API__c>{ 
    		new MC_API__c(name='mc-auth',Active__c=true,Client_Id__c='123456',Secret__c='secret1',Endpoint__c='http://auth.test.test/'),
    		new MC_API__c(name='mc-call',Active__c=true,Client_Id__c='123456',Secret__c='secret1',Endpoint__c='http://call.test.test/')
    	};
    }
    
    public class MockHttpMC implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            system.debug('>>mock endpoint: '+req.getEndpoint());
            if(req.getEndpoint().startsWith('http://auth.test.test/'))
            {
            	 res.setBody('{"accessToken":"ssfsdfr3545safsef","expiresIn":3478}');
            }else if(req.getEndpoint().startsWith('http://call.test.test/'))
            {
            	 res.setBody('{"status": "Draft","definitionId": "33d3d333-9988-e111-9ef0-88aaa9eeedd3"}');
            }
            res.setStatusCode(200);
            return res;
        }
    }
}