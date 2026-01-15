/*********************************************************************************************************************************
@ Class:          UTIL_BookingItemsControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Test class for UTIL_BookingItemsController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  29.09.2021 / Sophal Noch / Created the  class.
*********************************************************************************************************************************/
@IsTest 
private class UTIL_BookingItemsControllerTest {

    static byPass__c bp;
    static Account acc;
    static Opportunity opp;
    static Quote quote;
    static Site__c site;
    static Product2 prod1;
    static Product2 prod2;
    static QuoteLineItem qli;
    static testMethod void test_UTIL_BookingItemsController () {


        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = true,byPass_Validation__c=true);
        insert bp;
        
        Id opp_direct = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('eBay Ads - Direct').getRecordTypeId();

        acc = TST_DataGenerator.generateAccount();
        insert acc;

        opp = TST_DataGenerator.generateOpp(acc.Id);
        opp.Special_Terms__c = 'New Terms - Spe';
        opp.Start_Date__c = Date.today();
        opp.End_Date__c = Date.today().addDays(1);
        opp.Amount = 100;
        opp.RecordTypeId = opp_direct;
        insert opp;

        // mediaPlan = TST_DataGenerator.generateMediaPlan(opp);
        // insert mediaPlan;

        quote = TST_DataGenerator.generateQuote(opp.Id);
        insert quote;

        Site__c site = TST_DataGenerator.generateSite();
        site.Name = 'US';
        site.Country__c = 'US';
        site.currencyIsoCode = 'USD';
        insert site;

        Product2 prod = TST_DataGenerator.generateProduct(site.Id);
        insert prod;

        PriceBookEntry pbe =TST_DataGenerator.generatePricebookEntry(prod.id, null);
        insert pbe;

        qli = TST_DataGenerator.generateQuoteLinItem( quote.id, prod.id, pbe.id);
        Test.startTest();
            insert qli;


            Ad_Product__c adProd = [Select Id, name from Ad_Product__c where Opportunity__c =: opp.Id Limit 1];

            try{
                UTIL_BookingItemsController.initializeDataOpportunity(opp.Id);
            }catch(Exception e){}
            try{    
                UTIL_BookingItemsController.bookingDataOpportunity(adProd.Id);
            }catch(Exception e){}


            try{
                UTIL_BookingItemsController.initializeDataQuote(null);
            }catch(Exception e){}
            try{
                UTIL_BookingItemsController.bookingDataQuote(null);
            }catch(Exception e){}

            // try{ // Sophal: 29/09/2021: US-0008398 deprecated
            //     UTIL_BookingItemsController.initializeDataIO(null);
            // }catch(Exception e){}
            // try{ // Sophal: 29/09/2021: US-0008398 deprecated   
            //     UTIL_BookingItemsController.bookingDataIO(null);
            // }catch(Exception e){}


        Test.stopTest();



        

    }

}