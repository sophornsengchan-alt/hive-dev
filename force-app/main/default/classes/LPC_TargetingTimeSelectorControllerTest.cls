/**
 * @author: GIS-DevTeam
 * @createdDate: 20/June/2018
 * @description: 
 *  - test class of LPC_TargetingTimeSelectorController
 * @references: 
 *  - 
 * @changeLog:
 *
 */
@isTest
private class LPC_TargetingTimeSelectorControllerTest {

	@isTest static void testTargetingTimeSelector(){

		//create new targeting template
        Id RecId = Schema.SObjectType.Targeting__c.getRecordTypeInfosByName().get('Template').getRecordTypeId();
        Targeting__c targ = new Targeting__c();
        targ.Description__c = 'Tageting Template';
        targ.RecordTypeId = RecId;
        insert targ;

        Targeting__c t = new Targeting__c(TempBinder__c = true); 
        insert t;

		Account account = TST_DataGenerator.generateAccount();
        insert account;

        Opportunity opp = TST_DataGenerator.generateOpp(account.Id);
        insert opp;
        /* MN-14072021-No longer use with MediaPlan
        Media_Plan__c media = TST_DataGenerator.generateMediaPlan(opp);
        insert media;
        Quote quote = TST_DataGenerator.generateQuote(opp.Id, media.Id);
        */
        Quote quote = TST_DataGenerator.generateQuote(opp.Id);
        insert quote;
        Product2 product = TST_DataGenerator.generateProduct();
        insert product;
        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(product.Id,null);
        insert pbe;

        QuoteLineItem quoteLineItem = new QuoteLineItem();
        quoteLineItem.Product2Id = product.Id;
        quoteLineItem.Targeting__c = t.id;
        quoteLineItem.QuoteId = quote.Id;
        quoteLineItem.Quantity = 20;
        quoteLineItem.Quantity__c = 20;
        quoteLineItem.UnitPrice = 10;
        quoteLineItem.PricebookEntryId = pbe.Id;
        insert quoteLineItem;
        
        Map<String, Object>mData = new Map<String, Object>{
            'DFP_Time_Monday__c' => '0:00 - 0:59',
            'DFP_Time_Tuesday__c' => '1:00 - 1:59',
            'DFP_Time_Wednesday__c' => '2:00 - 2:59',
            'DFP_Time_Thursday__c' => '3:00 - 3:59',
            'DFP_Time_Friday__c' => '4:00 - 4:59',
            'DFP_Time_Saturday__c' => '5:00 - 5:59',
            'DFP_Time_Sunday__c' => '6:00 - 6:59'
        };
        String timeSelector = JSON.serialize(mData);
        RemoteResponse response = LPC_TargetingTimeSelectorController.saveTargetingTimeSelector(quoteLineItem.Id, timeSelector);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        
        response = LPC_TargetingTimeSelectorController.getTargetingTimeSelectorTemplate(t.Id);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(response.content != null);
        
        response = LPC_TargetingTimeSelectorController.saveTargetingTimeSelectorTemplate(t.Id, timeSelector);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(response.content != null);
        
    }
}