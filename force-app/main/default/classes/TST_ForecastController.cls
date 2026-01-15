/***
 * @author: SRONG TIN
 * @createdDate: 05/July/2018
 * @description: 
 *  - test class of ForecastController
 *  - coverage : 100%
 * @references: 
 *  - 
 * @changeLog:
 *
 */
@isTest
private class TST_ForecastController {
	public static Account account;
	public static Opportunity opp;
	public static Quote quote;
	public static Media_Plan__c media;

	@testSetup static void setup(){
		//
	}

	static testMethod void testForcecast(){
		//create new targeting template
        Id RecId = Schema.SObjectType.Targeting__c.getRecordTypeInfosByName().get('Template').getRecordTypeId();
        Targeting__c t = new Targeting__c();
        t.Description__c = 'Tageting Template';
        t.RecordTypeId = RecId;
        insert t;

		Site__c site = new Site__c(Name = 'Test', Country__c = 'Test');
		insert site;
        
		Id adRecordTypeId = Schema.SObjectType.AdServer_Login__c.getRecordTypeInfosByName().get('DART6').getRecordTypeId();
		AdServer_Login__c adServer = TST_DataGenerator.generateAdServerLogin();
		insert adServer;

        Content__c content = new Content__c(Name = 'Test Contant', DartName__c = 'test', Active__c = true);
        insert content;

        Content__c content1 = new Content__c(Name = 'Test Contant 11', DartName__c = 'test 11', Active__c = true, Content__c = content.Id);
        insert content1;

        TargetingContentAssociation__c  targetContentAss = new TargetingContentAssociation__c( Targeting__c = t.Id, TargetingContent__c = content.Id );
        insert targetContentAss;


		account = TST_DataGenerator.generateAccount();
        insert account;

        opp = TST_DataGenerator.generateOpp(account.Id);
        insert opp;
        //media = TST_DataGenerator.generateMediaPlan(opp);
        //insert media;
        
        quote = TST_DataGenerator.generateQuote(opp.Id);
        insert quote;

        Id proRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('GAM').getRecordTypeId();
        Product2 product = TST_DataGenerator.generateProduct();
        product.RecordTypeId = proRecordTypeId;
        product.Available_Key_Values__c = 'posN';
        product.Content__c = content.Id+'';
        product.Site__c  = site.Id;
        insert product;
        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(product.Id,null);
        insert pbe;

        QuoteLineItem quoteLineItem = TST_DataGenerator.generateQuoteLinItem(quote.Id, product.Id, pbe.Id);

        quoteLineItem.Quantity = 20;
        quoteLineItem.Quantity__c = 20;
        quoteLineItem.UnitPrice = 10;
        quoteLineItem.Targeting__c = t.Id;
        insert quoteLineItem;

        QuoteLineItem quoteLineItem2 = (QuoteLineItem) QueryUtil.queryRecord(quoteLineItem.id, DFPController.DFP_QUOTE_ADDITIONAL_FIELD );

        Test.startTest();

            ForecastController forecase = new ForecastController(quoteLineItem2);
            String getInvokedMethod = forecase.getInvokedMethod();
            forecase.forecastProcess();
            List<DARTObject.DARTForecast> lstFC = forecase.getObjectForecast();
            System.assert(lstFC.size() >0) ;
            DARTObject.DARTForecast fc = lstFC[0];
            System.assertEquals(fc.getAvailableUnits(),'300');
	    Test.stopTest();
	}
}