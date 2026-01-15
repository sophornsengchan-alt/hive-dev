/*********************************************************************************************************************************
@ Class:          LC_BookingQuoteItemsControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0008423 Test class for LC_BookingQuoteItemsController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  29.09.2021 / Sophal Noch / Created the  class.
*********************************************************************************************************************************/
@isTest
private class LC_BookingQuoteItemsControllerTest {

    static User u1;
    static byPass__c bp;
    static Account acc;
    static Opportunity opp;
    static Quote quote;
    static Site__c site;
    static Product2 prod;
    static QuoteLineItem qli;
    static testMethod void test_method () {

        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = true,byPass_Validation__c=true);
        insert bp;

        Id adServerDartRTId = ApexUtil.getRecordTypeByName('AdServer_Login__c','DART6').Id;
        AdServer_Login__c adServer = new AdServer_Login__c(
            Name = 'US',
            Login_URL__c='http://test.com',
            User_Name__c='dart6testuser@gmail.com',
            Password__c ='testpwddart6123456',
            Active__c = true,
            Network_ID__c='123456',
            Client_ID__c = 'xxxxxxxxxxxxxxxxxxxxx',
            Client_Secret__c = 'xxxxxxxxxxxxxxx',
            Refresh_Token__c = 'xxxxxxxxxxx',
            RT_Waiting__c = true,
            RecordTypeId = adServerDartRTId
        );
        insert adServer;

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
        Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
        prod.RecordTypeId = prodDartRTId;
        insert prod;

        PriceBookEntry pbe =TST_DataGenerator.generatePricebookEntry(prod.id, null);
        insert pbe;

        qli = TST_DataGenerator.generateQuoteLinItem( quote.id, prod.id, pbe.id);
        insert qli;

        Test.startTest();
        
            RemoteResponse response = LC_BookingQuoteItemsController.initializeDataQuote(quote.Id);
            System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
            response = LC_BookingQuoteItemsController.bookingLineItemQuote(qli.Id);
            //System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);


            quote.Status = 'Approved';
            update quote;

            response = LC_BookingQuoteItemsController.initializeDataQuote(quote.Id);
            System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
            
            response = LC_BookingQuoteItemsController.bookingLineItemQuote(qli.Id);
            //System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);


        Test.stopTest();


    }
}