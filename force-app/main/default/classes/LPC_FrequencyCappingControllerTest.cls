/**
 * @author: GIS-DevTeam
 * @createdDate: 18/June/2018
 * @description: 
 *  - test class of LPC_FrequencyCappingController
 * @references: 
 *  - 
 * @changeLog:
 *
 */
@isTest
private class LPC_FrequencyCappingControllerTest {
    /*
     *  Test LPC_FrequencyCappingController methods
     */
    @isTest static void testFrequencyCapping() {
        
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
        quoteLineItem.QuoteId = quote.Id;
        quoteLineItem.Quantity = 20;
        quoteLineItem.Quantity__c = 20;
        quoteLineItem.UnitPrice = 10;
        quoteLineItem.PricebookEntryId = pbe.Id;
        insert quoteLineItem;

        Test.startTest();                           

            List<String> lstPicklist = LPC_FrequencyCappingController.getPicklistValues('Opportunity','InvoiceGrouping__c');
            System.assert(lstPicklist != null);
                    
                    
            RemoteResponse res = LPC_FrequencyCappingController.getListTarFreAssociate(quoteLineItem.Id);
            System.assertEquals(res.statusCode, RemoteResponse.STATUSCODE_OK);
            
            
            res = LPC_FrequencyCappingController.getListTarFreAssociateTemplate(targ.Id);
            System.assertEquals(res.statusCode, RemoteResponse.STATUSCODE_OK);
            
            
            List<TargetingFrequencyAssociation__c>lstTarFre = new List<TargetingFrequencyAssociation__c>();
            lstTarFre.add(new TargetingFrequencyAssociation__c(Targeting__c = t.Id));       
                                                        
            res = LPC_FrequencyCappingController.saveFrequencyCapping(quoteLineItem.Id, lstTarFre);
            System.assertEquals(res.statusCode, RemoteResponse.STATUSCODE_OK);
            
            
            res = LPC_FrequencyCappingController.saveFrequencyCappingTemplate(targ.Id, lstTarFre);
            System.assertEquals(res.statusCode, RemoteResponse.STATUSCODE_OK);
        Test.stopTest();                

    }
}