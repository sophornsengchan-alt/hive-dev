/*****************************************************************************************************************************
@ Class:       FactoryDARTRequest
@ Author:      Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:     US-0008406 test class for FactoryDARTRequest
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  29.09.2021 / Mony Nou / Created the method.
@*****************************************************************************************************************************/
@IsTest 
private class FactoryDARTRequestTest {

    @isTest
    static void test_createDARTSubmitAdvertiserRequest() {

        setUpData();

        Test.startTest();

            HTTPWrapper.IGenericRequest res = FactoryDARTRequest.getInstance().createDartSubmitAdvertiserRequest(adServer, acc);

            adServer = [SELECT RecordType.Name,Name,Login_URL__c,User_Name__c,Password__c,Active__c,Network_ID__c,Client_ID__c,Client_Secret__c,Refresh_Token__c,RT_Waiting__c FROM AdServer_Login__c WHERE Id=:adServer.Id];
            
            res = FactoryDARTRequest.getInstance().createDartSubmitAdvertiserRequest(adServer, acc);

        Test.stopTest();
    }

    @isTest
    static void test_createDARTSubmitOrderRequest() {

        setUpData();

        Test.startTest();

            HTTPWrapper.IGenericRequest res = FactoryDARTRequest.getInstance().createDARTSubmitOrderRequest(adServer, site.Country__c, opp, qli, new Map<String, DARTObject.DARTPerson>(), new Map<String, Advertiser__c>());
            
            adServer = [SELECT RecordType.Name,Name,Login_URL__c,User_Name__c,Password__c,Active__c,Network_ID__c,Client_ID__c,Client_Secret__c,Refresh_Token__c,RT_Waiting__c FROM AdServer_Login__c WHERE Id=:adServer.Id];

            res = FactoryDARTRequest.getInstance().createDARTSubmitOrderRequest(adServer, site.Country__c, opp, qli, new Map<String, DARTObject.DARTPerson>(), new Map<String, Advertiser__c>());

        Test.stopTest();
    }

    @isTest 
    static void test_createDARTSubmitAdsRequest() {

        setUpData();

        Test.startTest();

            HTTPWrapper.IGenericRequest res = FactoryDARTRequest.getInstance().createDARTSubmitAdsRequest(adServer, opp, null);

            adServer = [SELECT RecordType.Name,Name,Login_URL__c,User_Name__c,Password__c,Active__c,Network_ID__c,Client_ID__c,Client_Secret__c,Refresh_Token__c,RT_Waiting__c FROM AdServer_Login__c WHERE Id=:adServer.Id];

            res = FactoryDARTRequest.getInstance().createDARTSubmitAdsRequest(adServer, opp, null);
            
        Test.stopTest();

    }

    @isTest 
    static void test_createDartSubmitSalePersonRequest() {

        setUpData();

        Test.startTest();

            HTTPWrapper.IGenericRequest res = FactoryDARTRequest.getInstance().createDartSubmitSalePersonRequest(adServer, opp);

            adServer = [SELECT RecordType.Name,Name,Login_URL__c,User_Name__c,Password__c,Active__c,Network_ID__c,Client_ID__c,Client_Secret__c,Refresh_Token__c,RT_Waiting__c FROM AdServer_Login__c WHERE Id=:adServer.Id];
            
            res = FactoryDARTRequest.getInstance().createDartSubmitSalePersonRequest(adServer, opp);

        Test.stopTest();

    }

    @isTest 
    static void test_createDartForecastRequest() {

        setUpData();

        Test.startTest();

            HTTPWrapper.IGenericRequest res = FactoryDARTRequest.getInstance().createDartForecastRequest(adServer, qli1);

            adServer = [SELECT RecordType.Name,Name,Login_URL__c,User_Name__c,Password__c,Active__c,Network_ID__c,Client_ID__c,Client_Secret__c,Refresh_Token__c,RT_Waiting__c FROM AdServer_Login__c WHERE Id=:adServer.Id];

            res = FactoryDARTRequest.getInstance().createDartForecastRequest(adServer, qli1);

        Test.stopTest();

    }

    @isTest 
    static void test_createDartGetAdvertiserRequest() {

        setUpData();

        Test.startTest();

            HTTPWrapper.IGenericRequest res = FactoryDARTRequest.getInstance().createDartGetAdvertiserRequest(adServer, opp, acc, site.Country__c);

            adServer = [SELECT RecordType.Name,Name,Login_URL__c,User_Name__c,Password__c,Active__c,Network_ID__c,Client_ID__c,Client_Secret__c,Refresh_Token__c,RT_Waiting__c FROM AdServer_Login__c WHERE Id=:adServer.Id];

            res = FactoryDARTRequest.getInstance().createDartGetAdvertiserRequest(adServer, opp, acc, site.Country__c);

        Test.stopTest();

    }


    @isTest 
    static void test_createDartDeliveryRequest() {
        setUpData();

        Test.startTest();

            HTTPWrapper.IGenericRequest res = FactoryDARTRequest.getInstance().createDartDeliveryRequest(adServer, '', '', 1, null);
            res = FactoryDARTRequest.getInstance().createDartDeliveryRequest(adServer, '', 1, null, 'Opportunity', Date.today(), Date.today().addDays(7));

            adServer = [SELECT RecordType.Name,Name,Login_URL__c,User_Name__c,Password__c,Active__c,Network_ID__c,Client_ID__c,Client_Secret__c,Refresh_Token__c,RT_Waiting__c FROM AdServer_Login__c WHERE Id=:adServer.Id];
            res = FactoryDARTRequest.getInstance().createDartDeliveryRequest(adServer, '', '', 1, null);
            res = FactoryDARTRequest.getInstance().createDartDeliveryRequest(adServer, '', 1, null, 'Opportunity', Date.today(), Date.today().addDays(7));

        Test.stopTest();
    }

    @isTest 
    static void test_createGetOrderRequest() {
        setUpData();

        Test.startTest();

            HTTPWrapper.IGenericRequest res = FactoryDARTRequest.getInstance().createGetOrderRequest(adServer, opp);
            adServer = [SELECT RecordType.Name,Name,Login_URL__c,User_Name__c,Password__c,Active__c,Network_ID__c,Client_ID__c,Client_Secret__c,Refresh_Token__c,RT_Waiting__c FROM AdServer_Login__c WHERE Id=:adServer.Id];
            res = FactoryDARTRequest.getInstance().createGetOrderRequest(adServer, opp);

        Test.stopTest();
    }

    @isTest 
    static void test_createGetLineItemRequest() {
        setUpData();

        Test.startTest();

            HTTPWrapper.IGenericRequest res = FactoryDARTRequest.getInstance().createGetLineItemRequest(adServer, opp, null);
            adServer = [SELECT RecordType.Name,Name,Login_URL__c,User_Name__c,Password__c,Active__c,Network_ID__c,Client_ID__c,Client_Secret__c,Refresh_Token__c,RT_Waiting__c FROM AdServer_Login__c WHERE Id=:adServer.Id];
            res = FactoryDARTRequest.getInstance().createGetLineItemRequest(adServer, opp, null);

        Test.stopTest();
    }
   
    @isTest 
    static void test_createGetLineItemRequestByAdIds() {
        setUpData();

        Test.startTest();

            HTTPWrapper.IGenericRequest res = FactoryDARTRequest.getInstance().createGetLineItemRequestByAdIds(adServer, new OpportunityLineItem());
            adServer = [SELECT RecordType.Name,Name,Login_URL__c,User_Name__c,Password__c,Active__c,Network_ID__c,Client_ID__c,Client_Secret__c,Refresh_Token__c,RT_Waiting__c FROM AdServer_Login__c WHERE Id=:adServer.Id];
            res = FactoryDARTRequest.getInstance().createGetLineItemRequestByAdIds(adServer, new OpportunityLineItem());

        Test.stopTest();
    }

    @isTest 
    static void test_createAdxReportRequest() {
        setUpData();

        Test.startTest();

            HTTPWrapper.IGenericRequest res = FactoryDARTRequest.getInstance().createAdxReportRequest(adServer, '','',1,null);
            adServer = [SELECT RecordType.Name,Name,Login_URL__c,User_Name__c,Password__c,Active__c,Network_ID__c,Client_ID__c,Client_Secret__c,Refresh_Token__c,RT_Waiting__c FROM AdServer_Login__c WHERE Id=:adServer.Id];
            res = FactoryDARTRequest.getInstance().createAdxReportRequest(adServer, '','',1,null);
            
        Test.stopTest();
    }

    
    
    
    //////// STATIC TEST RECORDS //////////
    
    static User u1;
    static byPass__c bp;
    static Account acc;
    static Opportunity opp;
    static Quote quote;
    static Site__c site;
    static Product2 prod1;
    static Product2 prod2;
    static QuoteLineItem qli1;
    static QuoteLineItem qli2;


    static Media_Plan__c mediaPlan;
    static QuoteLineItem qli;

    static Ad_Product__c adProd;

    static AdServer_Login__c adServer;

    private static void setUpData(){

        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false,byPass_Validation__c=true);
        Profile p = [select id from Profile where name='Standard Ads User Profile' limit 1];
        u1 = new User(alias = 'TestApro', email='TestsubApprov@ebay.com', 
                            emailencodingkey='UTF-8', lastname='TestsubApprov', firstname='TestsubApprov', languagelocalekey='en_US', 
                            localesidkey='en_US', profileid = p.Id, 
                            timezonesidkey='America/Los_Angeles', username='TestsubApprov@salesforce.de', isActive = true);
        

        Id adServerDartRTId = ApexUtil.getRecordTypeByName('AdServer_Login__c','DART6').Id;
        adServer = new AdServer_Login__c(
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

        insert bp;

        acc = TST_DataGenerator.generateAccount();
        insert acc;

        opp = TST_DataGenerator.generateOpp(acc.Id);
        opp.Special_Terms__c = 'New Terms - Spe';
        opp.StageName = 'Qualified Meeting';
        insert opp;
        
        Id book1Id = Test.getStandardPriceBookId();

        quote  = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp.Id, Pricebook2Id = book1Id);
        quote.RecordTypeId =  ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        insert quote;
        
        site = TST_DataGenerator.generateSite();
        site.Name = 'us';
        site.Country__c = 'US';
        site.currencyIsoCode = 'USD';
        insert site;

        Advertising_Medium__c adVertMedium = new Advertising_Medium__c(Name='test test test');
        insert adVertMedium;
        
        Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;

        prod1 = TST_DataGenerator.generateProduct(site.Id);
        prod1.RecordTypeId = prodDartRTId;
        prod1.Advertising_Medium__c = adVertMedium.Id;
        prod1.Fixed_Site__c = true;

        prod2 = TST_DataGenerator.generateProduct(site.Id);
        prod2.RecordTypeId = prodDartRTId;
        prod2.Advertising_Medium__c = adVertMedium.Id;
        insert new List<Product2>{prod1, prod2};
        
        PriceBookEntry pbe1 =TST_DataGenerator.generatePricebookEntry(prod1.id, null);
        PriceBookEntry pbe2 =TST_DataGenerator.generatePricebookEntry(prod2.id, null);
        insert new List<PriceBookEntry>{pbe1, pbe2};

        qli1 = TST_DataGenerator.generateQuoteLinItem( quote.id, prod1.id, pbe1.id);
        qli1.Budget__c = 30;
        qli1.from_Date__c = date.today();
        qli1.until_Date__c = date.today();

        qli2 = TST_DataGenerator.generateQuoteLinItem( quote.id, prod2.id, pbe2.id);
        qli2.Budget__c = 55;
        qli2.from_Date__c = date.today();
        qli2.until_Date__c = date.today();
        insert new List<QuoteLineItem>{qli1, qli2};

    }

}