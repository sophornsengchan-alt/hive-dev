/***
 * @author: SRONG TIN
 * @createdDate: 05/July/2018
 * @description: 
 *  - test class of RemoteResponse
 *  - coverage : 100%
 * @references: 
 *  - 
 * @changeLog:
 *
 */
@isTest
private class TST_RemoteResponse {
	@testSetup static void setup(){
		//
	}

	static testMethod void test(){
		
		Test.startTest();
		
		RemoteResponse response = new RemoteResponse();
		System.assertEquals(response.content, 0);
		RemoteResponse response2 = new RemoteResponse('Default message',0);
		System.assertEquals(response2.statusCode, 0);

		
		RemoteResponse response3 = new RemoteResponse('data');
		System.assert(response3.content != null);

		Test.stopTest();
		
	}
}