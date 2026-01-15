/***
 * @author: SRONG TIN
 * @createdDate: 04/July/2018
 * @description: 
 *  - test class of LC_NavigateToComponentController
 *  - coverage : 80%
 * @references: 
 *  - 
 * @changeLog:
 *
 */
@isTest
private class TST_LC_NavigateToComponentController {

	public static Account acc;
	public static Opportunity opp;
	public static Quote quote;
	public static Media_Plan__c mediaPlan;

	@testSetup static void setup(){
		// PermissionSet pmsMediaPlanner = [SELECT Id FROM PermissionSet WHERE Name = 'Ebay_Advertisement_Media_Planners'];
		// PermissionSet pmsSales_Ops = [SELECT Id FROM PermissionSet WHERE Name = 'Ebay_Advertisement_Sales_Ops'];

		// PermissionSetAssignment psa1 = new PermissionSetAssignment(PermissionSetId = pmsMediaPlanner.Id, AssigneeId = UserInfo.getUserId());
		// insert psa1; 

		// PermissionSetAssignment psa2 = new PermissionSetAssignment(PermissionSetId = pmsSales_Ops.Id, AssigneeId = UserInfo.getUserId());
		// insert psa2;
	}

	static testMethod void testNavigateToCom(){
		acc = TST_DataGenerator.generateAccount();
		insert acc;

		opp = TST_DataGenerator.generateOpp(acc.Id);
		insert opp;

		// mediaPlan = TST_DataGenerator.generateMediaPlan(opp);
		// insert mediaPlan;

		quote = TST_DataGenerator.generateQuote(opp.Id);
		insert quote;

		Quote quote2 = new Quote(Name = 'test quote2', OpportunityId = opp.Id);
		insert quote2;

		Test.startTest();
			Map<String, Object> data = LC_NavigateToComponentController.doInitInfo( quote.Id+'' );
			system.assert(data.get('sObjectName') != '');

			Map<String, Object> errorData = new Map<String, Object>();
			Boolean isError = true;
			try{
				errorData = LC_NavigateToComponentController.doInitInfo( quote.Id+'test' );
				isError = false;
			}catch(Exception e){
				System.assertEquals(isError, true);
			}

			Quote quoteData = LC_NavigateToComponentController.getRecordData( quote.Id+'' );
			System.assertEquals(quoteData.Name, quote.Name);

			Quote quoteData1 = LC_NavigateToComponentController.getRecordData( quote2.Id+'' );
			System.assertEquals(quoteData1.Name, quote2.Name);

			// RemoteResponse response = LC_NavigateToComponentController.createQuoteFromMP(mediaPlan.Id);
			RemoteResponse response = LC_NavigateToComponentController.createQuoteFromOpp(opp.Id);
			response = LC_NavigateToComponentController.createQuoteFromOpp(opp.Id+'test');

			// System.assert(response.content != null);
			response = LC_NavigateToComponentController.hasPermission();
		Test.stopTest();
	}

	static testMethod void testNavigateToCom2(){
		acc = TST_DataGenerator.generateAccount();
		insert acc;
		System.debug('TEST >>>'+acc.Id);
		Test.startTest();
			Map<String, Object> data = LC_NavigateToComponentController.doInitInfo(String.valueOf(acc.Id));
			
			LC_NavigateToComponentController.hasPermission();
			
			//GW_MediaPlan gw = new GW_MediaPlan();//TH:US-0016001: Destructive Changes for GW_MediaPlan
			Media_Plan__c mp = new Media_Plan__c();
			insert mp;
			update mp;
			delete mp;


		Test.stopTest();
	}
}