/***
 * @author: SRONG TIN
 * @createdDate: 06/July/2018
 * @description: 
 *  - test class of DARTDeliveryWS
 *  - coverage : 78%
 * @references: 
 *  - 
 * @changeLog:
 * 				- MN 19/Apri/2021 - US-0008391 - Upgrade code coverage of DART6_Delivery from 62% to 85% [ lines not covered 98]
 */
@isTest
private class TST_DART6_Delivery {

	public static Account acc;
	public static Opportunity opp;
	public static Quote quote;
	public static Media_Plan__c mediaPlan;
	public static OpportunityLineItem oppLineItem;

	@testSetup static void setup(){
		//
		Targeting__c targeting = new Targeting__c(Description__c = 'test');
		insert targeting;

		acc = TST_DataGenerator.generateAccount();
        insert acc;
        opp = TST_DataGenerator.generateOpp(acc.Id);
        insert opp;

        // mediaPlan = TST_DataGenerator.generateMediaPlan(opp);
		// insert mediaPlan;

		quote = TST_DataGenerator.generateQuote(opp.Id);
		insert quote;

		Product2 product = TST_DataGenerator.generateProduct();
		insert product;

		PriceBookEntry pricebook = TST_DataGenerator.generatePricebookEntry(product.Id, null);
		insert pricebook;

		oppLineItem = TST_DataGenerator.generateOpportunityLinItem(opp.Id, pricebook.Id, targeting.Id);
		insert oppLineItem;
	}

	//static testMethod void testDART6_Delivery() { 
	//}

	static testMethod void testDARTBookingWS() { 

		Opportunity opp1 = (Opportunity) QueryUtil.queryRecords('Opportunity').get(0);
		String oppId = opp1.Id+'';
		test.startTest();
		//String result = DARTBookingWS.processWebservice(oppId, 'test');
		test.stopTest();
	}
}