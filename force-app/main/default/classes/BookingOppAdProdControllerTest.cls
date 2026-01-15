/*****************************************************************************************************************************
@ Class:       BookingOppAdProdControllerTest
@ Author:      Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:     US-0008578 test class for BookingOppAdProdController
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  03.12.2020 / Sophal Noch / Created the method.
------------------------------------------------------------------------------------------------------------------------------
@ Change history 14/11/2023 / Vimean Heng / US-0014420 - test method should run in TestDARTCodeCoverage test class
@*****************************************************************************************************************************/
@IsTest 
private class BookingOppAdProdControllerTest {
    
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
    static Ad_Product__c adProd;
    static Date startDate;
    static Date endDate;


    static Media_Plan__c mediaPlan;
    static QuoteLineItem qli;

    static String quotePgRecordTypeId = ApexUtil.getRecordTypeByName('Quote','PG_PMP_Quote').Id;
    static String oppPgRecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','Programmatic').Id;
    private static User currentUser = [ select Id, Name from User where Id = :UserInfo.getUserId() ]; 

    // US-0008578 from here are the test methods for covering Opportunity and Ad Product Booking
    
    private static void setUpData(){

        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false,byPass_Validation__c=true);
        Profile p = [select id from Profile where name='Standard Ads User Profile' limit 1];
        u1 = new User(alias = 'TestApro', email='TestsubApprov@ebay.com', 
                            emailencodingkey='UTF-8', lastname='TestsubApprov', firstname='TestsubApprov', languagelocalekey='en_US', 
                            localesidkey='en_US', profileid = p.Id, 
                            timezonesidkey='America/Los_Angeles', username='TestsubApprov@salesforce.de', isActive = true);
        System.runAs(u1){

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


            
            insert bp;
    
            acc = TST_DataGenerator.generateAccount();
            acc.Record_Type_Text__c = 'Advertiser';
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
            site.Name = 'US';
            site.Country__c = 'US';
            site.currencyIsoCode = 'USD';
            insert site;

            Advertising_Medium__c adVertMedium = new Advertising_Medium__c(Name='test test test');
            insert adVertMedium;
            
            Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;

            prod1 = TST_DataGenerator.generateProduct(site.Id);
            prod1.RecordTypeId = prodDartRTId;
            prod1.Advertising_Medium__c = adVertMedium.Id;

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

    private static void setUpData2(){

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
            RecordTypeId = adServerDartRTId,
            ExternalLineDescriptionId__c = '123456789'
        );
        insert adServer;

        acc = TST_DataGenerator.generateAccount();
        acc.Record_Type_Text__c = 'Advertiser';
        insert acc;

        Id accId = acc.Id;
        acc = [Select Id,Name, RecordType.Name From Account Where Id =: accId ];

        Advertiser__c advertiser = new Advertiser__c(Account__c=acc.id, Agency__c=acc.id, DART5_Advertiser_Id__c='111111', DART6_Advertiser_Id__c='222222');
        insert advertiser;


        opp = TST_DataGenerator.generateOpp(acc.Id);
        opp.Name = 'Test test test test';
        opp.Buyer_Seat__c = '123456789'; // 21.12.2021 / Sophal Noch / US-0009971
        opp.OwnerId = UserInfo.getUserId();

        Date startDate = Date.today().addDays(1);
        Date endDate = Date.today().addDays(2);

        opp.Start_Date__c = startDate;
        opp.End_Date__c = endDate;
        opp.RecordTypeId = oppPgRecordTypeId;

        insert opp;
        Id oppId = opp.Id;
        opp = [Select Id,Name, Owner.Id From Opportunity Where Id =: oppId];


        site = TST_DataGenerator.generateSite();
        site.Name = 'US';
        site.Country__c = 'US';
        site.currencyIsoCode = 'USD';
        insert site;
            
        Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
        prod1 = TST_DataGenerator.generateProduct(site.Id);
        prod1.Name = 'Test test test';
        prod1.RecordTypeId = prodDartRTId;
        //insert prod1;

        //Sophal:03/03/2021:US-0009139 to cover DFPController.getAvailability below
        Advertising_Medium__c adVertMedium = new Advertising_Medium__c(Name='test test test',Dart_AdSlotSize__c='100x100',Quantity_Multiplier__c=1,to_Subtract__c=1);
        insert adVertMedium;

        prod1.Advertising_Medium__c = adVertMedium.Id;
        //update prod1;
        insert prod1;
        
        quote = TST_DataGenerator.generateQuote(opp.Id);
        quote.RecordTypeId = quotePgRecordTypeId;
        insert quote;

        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(prod1.id, null);
        insert pbe;

        qli = TST_DataGenerator.generateQuoteLinItem( quote.id, prod1.id, pbe.id);

        //insert qli;


        Targeting__c tg = new Targeting__c(Description__c='test');
        tg.DFP_Time_Monday__c = '0:00 - 0:59';
        tg.DFP_Time_Tuesday__c = '0:00 - 0:59';
        tg.DFP_Time_Wednesday__c = '0:00 - 0:59';
        tg.DFP_Time_Thursday__c = '0:00 - 0:59';
        tg.DFP_Time_Friday__c = '0:00 - 0:59';
        tg.DFP_Time_Saturday__c = '0:00 - 0:59';
        tg.DFP_Time_Sunday__c = '0:00 - 0:59';
        insert tg;

        qli.Targeting__c = tg.Id;
        //update qli;
        insert qli;
        

        Devices__c browser = new Devices__c(DFP_API_Name__c='Browser', Dart_ID__c = 111111);
        Devices__c browserLanguage = new Devices__c(DFP_API_Name__c='BrowserLanguage', Dart_ID__c = 22222);
        Devices__c deviceCapability = new Devices__c(DFP_API_Name__c='DeviceCapability', Dart_ID__c = 33333);
        Devices__c deviceManufacturer = new Devices__c(DFP_API_Name__c='DeviceManufacturer', Dart_ID__c = 44444);
        Devices__c operatingSystem = new Devices__c(DFP_API_Name__c='OperatingSystem', Dart_ID__c = 55555);
        Devices__c operatingSystemVersion = new Devices__c(DFP_API_Name__c='OperatingSystemVersion', Dart_ID__c = 66666);
        Devices__c mobileDevice = new Devices__c(DFP_API_Name__c='MobileDevice', Dart_ID__c = 77777);
        Devices__c mobileDeviceSubmodel = new Devices__c(DFP_API_Name__c='MobileDeviceSubmodel', Dart_ID__c = 888888);
        List<Devices__c> devices = new List<Devices__c>{browser,browserLanguage,deviceCapability,deviceManufacturer,operatingSystem,operatingSystemVersion,mobileDevice,mobileDeviceSubmodel};
        insert devices;

        List<TargetingDeviceAssociation__c> targetDeviceAssoc = new List<TargetingDeviceAssociation__c>();
        for(Devices__c device : devices){
            targetDeviceAssoc.add(new TargetingDeviceAssociation__c(Device__c=device.Id,Targeting__c=tg.Id));
        }
        insert targetDeviceAssoc;

        Content__c content = new Content__c(Name = 'test content');
        insert content;

        adProd = [Select Id,Quantity__c,Billing_Category__c,Targeting__c, UnitPrice__c, Name,Ad_Id__c From Ad_Product__c Where Opportunity__c =: opp.Id Limit 1];
        adProd.Product2__c = prod1.Id;
        adProd.Billing_Category__c = 'Test';
        adProd.UnitPrice__c = 9;
        adProd.Targeting__c = tg.Id;
        adProd.Line_Item_Description__c = 'Test test test';
        adProd.SalesPriceNet__c = 18;
        adProd.Predefined_Adunit__c = content.Id;
        update adProd;
    }


    /*****************************************************************************************************************************
    @ Method:       testError_initializeDataOpportunity
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 test method for BookingOppAdProdController.initializeDataOpportunity
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.11.2023 / Vimean Heng / US-0014420 / Fix Mixed DML
    @*****************************************************************************************************************************/
    static testMethod void testError_initializeDataOpportunity () {
        setUpData();

        quote.Primary_Quote__c = false;
        System.runAs(currentUser){
            update quote;
        }
        System.runAs(u1){

            RemoteResponse rrs = BookingOppAdProdController.initializeDataOpportunity(opp.Id);
            System.assertEquals(Label.Error_Primary_Quote_Is_Required_To_Do_Booking, rrs.validationMsg);

        }
        //US-0014420 Vimean split the test method to avoid Limit Exceeded DML (testError_CanNotBookAdProduct)
        /*
        quote.Primary_Quote__c = true;
        System.runAs(currentUser){
            update quote;
        }
        
        System.runAs(u1){

            RemoteResponse rrs = BookingOppAdProdController.initializeDataOpportunity(opp.Id);
            System.assertEquals(Label.Error_Can_Not_Book_AdProduct_On_Quote_RT_Advertising, rrs.validationMsg);

        }

        quote.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','PG_PMP_Quote').Id;
        Test.startTest();
        update quote;
        Test.stopTest();

        System.runAs(u1){
            RemoteResponse rrs = BookingOppAdProdController.initializeDataOpportunity(opp.Id);
            System.assertEquals(Label.Error_Can_Not_Book_AdProduct_On_Quote_RT_PG_PMP, rrs.validationMsg);

        }
       */

    }
    /*****************************************************************************************************************************
    @ Method:       testError_CanNotBookAdProduct
    @ Author:       Vimean Heng
    @ Purpose:      US-0014420 test method for BookingOppAdProdController.initializeDataOpportunity
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.11.2023 / Vimean Heng / US-0014420 / Fix Mixed DML And Apex CPU Limit
    @*****************************************************************************************************************************/
    static testMethod void testError_CanNotBookAdProduct () {
        setUpData();
        quote.Primary_Quote__c = true;
        System.runAs(currentUser){
            update quote;
        }
        
        System.runAs(u1){

            RemoteResponse rrs = BookingOppAdProdController.initializeDataOpportunity(opp.Id);
            System.assertEquals(Label.Error_Can_Not_Book_AdProduct_On_Quote_RT_Advertising, rrs.validationMsg);

        }

        quote.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','PG_PMP_Quote').Id;
        Test.startTest();
            System.runAs(currentUser){
                update quote;
            }
        Test.stopTest();

        System.runAs(u1){
            RemoteResponse rrs = BookingOppAdProdController.initializeDataOpportunity(opp.Id);
            System.assertEquals(Label.Error_Can_Not_Book_AdProduct_On_Quote_RT_PG_PMP, rrs.validationMsg);

        }

    }
    /*****************************************************************************************************************************
    @ Method:       test_initializeDataOpportunity
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 test method for BookingOppAdProdController.initializeDataOpportunity
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.11.2023 / Vimean Heng / US-0014420 / Fix Mixed DML
    @*****************************************************************************************************************************/
    static testMethod void test_initializeDataOpportunity () {
        setUpData();
        quote.Primary_Quote__c = true;
        quote.Dually_Signed__c = true;
        // quote.Status = 'Approved';
        //VM Fix Mixed DML
        System.runAs(currentUser){
            update quote;
        }
        
        System.runAs(u1){
            RemoteResponse rrs = BookingOppAdProdController.initializeDataOpportunity(opp.Id);
            // System.assertEquals('successed', rrs.message);

        }

    }

    /*****************************************************************************************************************************
    @ Method:       test_bookingDataAdProductOpportunity
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 test method for BookingOppAdProdController.bookingDataAdProductOpportunity
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.11.2023 / Vimean Heng / US-0014420 / Fix Mixed DML
    @*****************************************************************************************************************************/
    static testMethod void test_bookingDataAdProductOpportunity () {


        setUpData();
        quote.Primary_Quote__c = true;
        quote.Dually_Signed__c = true;
        // quote.Status = 'Approved';
        //VM Fix Mixed DML
        System.runAs(currentUser){
            update quote;
        }

        Ad_Product__c adProd = [Select Id From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id];
        System.assertNotEquals(null, adProd.Id);

        Targeting__c tg = new Targeting__c(Description__c='test');
        tg.DFP_Time_Monday__c = '0:00 - 0:59';
        tg.DFP_Time_Tuesday__c = '0:00 - 0:59';
        tg.DFP_Time_Wednesday__c = '0:00 - 0:59';
        tg.DFP_Time_Thursday__c = '0:00 - 0:59';
        tg.DFP_Time_Friday__c = '0:00 - 0:59';
        tg.DFP_Time_Saturday__c = '0:00 - 0:59';
        tg.DFP_Time_Sunday__c = '0:00 - 0:59';
        //VM Fix Mixed DML
        System.runAs(currentUser){
            insert tg;
        }

       

        // Content__c content = new Content__c(Name = 'test content');
        // insert content;

        adProd.Targeting__c = tg.Id;
        // adProd.Predefined_Adunit__c = content.Id;
        //VM Fix Mixed DML
        System.runAs(currentUser){
            update adProd;
        }
       

        System.runAs(u1){
            RemoteResponse rrs = BookingOppAdProdController.bookingDataAdProductOpportunity(adProd.Id);
            System.assertEquals('Default message', rrs.message);

        }

    }


    // US-0008578 from here are the test methods to covering Quote,QuoteLineItem,IO,IOQuoteLineItem

    /*****************************************************************************************************************************
    @ Method:       test_UTIL_BookingItemsController
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 test method for
    @               UTIL_BookingItemsController.initializeDataQuote
    @               UTIL_BookingItemsController.bookingDataQuote
    @               UTIL_BookingItemsController.initializeDataIO
    @               UTIL_BookingItemsController.bookingDataIO
    @               UTIL_BookingItemsController.initializeDataOpportunity
    @               UTIL_BookingItemsController.bookingDataOpportunity
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
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
        Test.stopTest();

        // quote.Status = 'Approved';
        // update quote;
        // Id ioId = GW_IO.createIOFromQuote(quote.Id);

        // quote = (Quote) QueryUtil.queryRecord(quote.id);
        // IO__c io = (IO__c) QueryUtil.queryRecord(ioId);
        // List<IO_LineItem__c> ioLineItem = [Select Id From IO_LineItem__c where IO__c =: io.Id];

        // UTIL_BookingItemsController.initializeDataQuote(quote.Id);
        // UTIL_BookingItemsController.bookingDataQuote(qli.Id);

        // UTIL_BookingItemsController.initializeDataIO(io.Id);
        // UTIL_BookingItemsController.bookingDataIO(ioLineItem[0].Id);

        // List<Ad_Product__c> adProduct = [Select Id From Ad_Product__c where Opportunity__c =: opp.Id];
        // UTIL_BookingItemsController.initializeDataOpportunity(opp.Id);
        // UTIL_BookingItemsController.bookingDataOpportunity(adProduct[0].Id);

    }


    /*****************************************************************************************************************************
    @ Method:       test_initializeData_Direct
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 test method for LC_BookingQuoteItemsController.initializeDataQuote and LC_BookingQuoteItemsController.bookingDataQuote
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    static testMethod void test_initializeData_Direct () {


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
        Test.startTest();
        insert qli;
        Test.stopTest();

        // quote.Status = 'Approved';
        // update quote;
        
        RemoteResponse response = LC_BookingQuoteItemsController.initializeDataQuote(quote.Id);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        // quote = (Quote) QueryUtil.queryRecord(quote.id);
        response = LC_BookingQuoteItemsController.bookingLineItemQuote(qli.Id);
        //System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);


    }

    /*****************************************************************************************************************************
    @ Method:       test_initializeData_Programmatic
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 test method for LC_BookingQuoteItemsController.initializeDataQuote and LC_BookingQuoteItemsController.bookingDataQuote
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    static testMethod void test_initializeData_Programmatic () {


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


        
        Id opp_direct = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('eBay Ads - Programmatic Guaranteed').getRecordTypeId();

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
        Test.startTest();
        insert qli;
        Test.stopTest();

        RemoteResponse response = LC_BookingQuoteItemsController.initializeDataQuote(quote.Id);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assertEquals(response.validationMsg , 'You can only book line items to DFP once the quote is approved');
        quote = (Quote) QueryUtil.queryRecord(quote.id);
        
        // quote.Status = 'Approved';
        // update quote;
        
        RemoteResponse responseQli = LC_BookingQuoteItemsController.bookingLineItemQuote(qli.Id);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName);
        
        System.runAs(u){
            response = LC_BookingQuoteItemsController.initializeDataQuote(quote.Id);
            System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_ERROR);
        }


    }

    /*****************************************************************************************************************************
    @ Method:       test_initializeIOData_Direct
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 test method for LC_BookingIOItemsController.initializeDataIO and LC_BookingIOItemsController.bookingLineItemIO
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @ Change history:  29.09.2021 / Sophal Noch / US-0008398 deprecated the method.
    @*****************************************************************************************************************************/
    // static testMethod void test_initializeIOData_Direct () {

    //     bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = true,byPass_Validation__c=true);
    //     insert bp;

    //     Id adServerDartRTId = ApexUtil.getRecordTypeByName('AdServer_Login__c','DART6').Id;
    //     AdServer_Login__c adServer = new AdServer_Login__c(
    //         Name = 'US',
    //         Login_URL__c='http://test.com',
    //         User_Name__c='dart6testuser@gmail.com',
    //         Password__c ='testpwddart6123456',
    //         Active__c = true,
    //         Network_ID__c='123456',
    //         Client_ID__c = 'xxxxxxxxxxxxxxxxxxxxx',
    //         Client_Secret__c = 'xxxxxxxxxxxxxxx',
    //         Refresh_Token__c = 'xxxxxxxxxxx',
    //         RT_Waiting__c = true,
    //         RecordTypeId = adServerDartRTId
    //     );
    //     insert adServer;


    //     Id opp_direct = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('eBay Ads - Direct').getRecordTypeId();

    //     acc = TST_DataGenerator.generateAccount();
    //     insert acc;

    //     opp = TST_DataGenerator.generateOpp(acc.Id);
    //     opp.Special_Terms__c = 'New Terms - Spe';
    //     opp.Start_Date__c = Date.today();
    //     opp.End_Date__c = Date.today().addDays(1);
    //     opp.Amount = 100;
    //     opp.RecordTypeId = opp_direct;
    //     insert opp;

    //     // mediaPlan = TST_DataGenerator.generateMediaPlan(opp);
    //     // insert mediaPlan;

    //     quote = TST_DataGenerator.generateQuote(opp.Id);
    //     insert quote;

    //     Site__c site = TST_DataGenerator.generateSite();
    //     site.Name = 'US';
    //     site.Country__c = 'US';
    //     site.currencyIsoCode = 'USD';
    //     insert site;

    //     Product2 prod = TST_DataGenerator.generateProduct(site.Id);
    //     Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
    //     prod.RecordTypeId = prodDartRTId;
    //     insert prod;

    //     PriceBookEntry pbe =TST_DataGenerator.generatePricebookEntry(prod.id, null);
    //     insert pbe;
       
    //     qli = TST_DataGenerator.generateQuoteLinItem( quote.id, prod.id, pbe.id);
    //     Test.startTest();
    //     insert qli;
    //     Test.stopTest();

    //     // quote.Status = 'Approved';
    //     // update quote;
    //     // Id ioId = GW_IO.createIOFromQuote(quote.Id);

    //     // quote = (Quote) QueryUtil.queryRecord(quote.id);
    //     // // IO__c io = (IO__c) QueryUtil.queryRecord(ioId);
    //     // // System.debug('#### io :: ' + io);

    //     // RemoteResponse response = LC_BookingIOItemsController.initializeDataIO(String.valueOf(io.Id));
    //     // System.debug('#### response 1 :: ' + response);
    //     // System.assertEquals(response.validationMsg , 'Dually Signed IO is required to do booking!');

    //     // List<IO_LineItem__c> listIoLineItemToUpdate = new List<IO_LineItem__c>();
    //     // for(IO_LineItem__c ioLine : [select id from IO_LineItem__c where IO__c = :quote.IO__c limit 1]) {
    //     //     ioLine.Ad_Id__c = '123';
    //     //     ioLine.Total_Price__c = 150;
    //     //     ioLine.from_Date__c = Date.today();
    //     //     ioLine.until_Date__c = Date.today().addDays(2);
    //     //     listIoLineItemToUpdate.add(ioLine);// create Ad_Campaign, Monthly and Daily on IO_LineItem__c trigger when ad id is populated
    //     // }
    //     // update listIoLineItemToUpdate;

    //     // io.Dually_Signed_IO__c = true;
    //     // update io;

    //     // response = LC_BookingIOItemsController.initializeDataIO(String.valueOf(io.Id));
    //     // System.debug('#### response 2 :: ' + response);
    //     // System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);

    //     // for(IO_LineItem__c ioLine : [select id from IO_LineItem__c where IO__c = :quote.IO__c limit 1]) {
    //     //     response = LC_BookingIOItemsController.bookingLineItemIO(String.valueOf(ioLine.Id));
    //     //     System.debug('#### response 3 :: ' + response);
    //     // }


    // }

    /*****************************************************************************************************************************
    @ Method:       test_initializeIOData_Direct
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 test method for LC_BookingIOItemsController.initializeDataIO and LC_BookingIOItemsController.bookingLineItemIO
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    /*static testMethod void test_initializeIOData_Programmatic () {

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



        //Id opp_programmic = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('eBay Ads - Programmatic Guaranteed').getRecordTypeId();
        Id opp_programmic = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('eBay Ads - Programmatic Guaranteed').getRecordTypeId();

        acc = TST_DataGenerator.generateAccount();
        insert acc;

        opp = TST_DataGenerator.generateOpp(acc.Id);
        opp.Special_Terms__c = 'New Terms - Spe';
        opp.Start_Date__c = Date.today();
        opp.End_Date__c = Date.today().addDays(1);
        opp.Amount = 100;
        opp.RecordTypeId = opp_programmic;
        insert opp;

        // mediaPlan = TST_DataGenerator.generateMediaPlan(opp);
        // insert mediaPlan;

        quote = TST_DataGenerator.generateQuote(opp.Id);
        insert quote;

        Site__c site = TST_DataGenerator.generateSite();
        site.Name = 'us';
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
        Test.startTest();
        insert qli;
        Test.stopTest();

        quote.Status = 'Approved';
        update quote;
        Id ioId = GW_IO.createIOFromQuote(quote.Id);
        System.assertNotEquals(null ,ioId);

        quote = (Quote) QueryUtil.queryRecord(quote.id);


        IO__c ioToUpdate = new IO__c(Id = ioId,RecordTypeId=ApexUtil.getRecordTypeByName('IO__c','Programmatic').Id);
        update ioToUpdate;

        RemoteResponse response = LC_BookingIOItemsController.initializeDataIO(String.valueOf(ioId));
        System.debug('#### response 1 :: ' + response);
        System.assertEquals('You cannot book line items until the IO is approved or Buyer has Accepted.', response.validationMsg);
                


        List<IO_LineItem__c> listIoLineItemToUpdate = new List<IO_LineItem__c>();
        for(IO_LineItem__c ioLine : [select id from IO_LineItem__c where IO__c = :ioId limit 1]) {
            ioLine.Ad_Id__c = '123';
            ioLine.Total_Price__c = 150;
            ioLine.from_Date__c = Date.today();
            ioLine.until_Date__c = Date.today().addDays(2);
            listIoLineItemToUpdate.add(ioLine);
            // update ioLine; // create Ad_Campaign, Monthly and Daily on IO_LineItem__c trigger when ad id is populated
        }
        update listIoLineItemToUpdate;
        
        ioToUpdate = new IO__c(Id = ioId,Buyer_Accepted__c = true,IO_Status__c = 'Approved');
        update ioToUpdate;

        response = LC_BookingIOItemsController.initializeDataIO(String.valueOf(ioToUpdate.Id));
        System.debug('#### response 2 :: ' + response);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);

        for(IO_LineItem__c ioLine : [select id from IO_LineItem__c where IO__c = :quote.IO__c limit 1]) {
            response = LC_BookingIOItemsController.bookingLineItemIO(String.valueOf(ioLine.Id));
            System.debug('#### response 3 :: ' + response);
        }

        response = LC_BookingIOItemsController.bookingLineItemIO(String.valueOf(ioToUpdate.Id));
            System.debug('#### response 4 :: ' + response);

    }*/

    // US-0008578 from here are the test methods to covering Existing Dart classes.

    // /*****************************************************************************************************************************
    // @ Method:       testDART6_KeyValueController
    // @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    // @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testDART6_KeyValueController
    // ------------------------------------------------------------------------------------------------------------------------------
    // @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    // @*****************************************************************************************************************************/
    // static testMethod void testDART6_KeyValueController () {
    //     TestDARTCodeCoverage.call_setup();
    //     TestDARTCodeCoverage.call_testDART6_KeyValueController();
    // }

    /*****************************************************************************************************************************
    @ Method:       testDART6Message
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testDART6Message
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history 14/11/2023 / Vimean Heng / US-0014420 - test method should run in TestDARTCodeCoverage test class
    @*****************************************************************************************************************************/
    //static testMethod void testDART6Message () {
    //    TestDARTCodeCoverage.call_setup();
    //    TestDARTCodeCoverage.call_testDART6Message();
    //}

    /*****************************************************************************************************************************
    @ Method:       testDART6RequestForecast
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testDART6RequestForecast
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history 14/11/2023 / Vimean Heng / US-0014420 - test method should run in TestDARTCodeCoverage test class
    @*****************************************************************************************************************************/
    //static testMethod void testDART6RequestForecast () {
    //    TestDARTCodeCoverage.call_setup();
    //    TestDARTCodeCoverage.call_testDART6RequestForecast();
    //}

    /*****************************************************************************************************************************
    @ Method:       testDart6GetAdvertiser
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testDart6GetAdvertiser
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history 14/11/2023 / Vimean Heng / US-0014420 - test method should run in TestDARTCodeCoverage test class
    @*****************************************************************************************************************************/
    //static testMethod void testDart6GetAdvertiser () {
    //    TestDARTCodeCoverage.call_setup();
    //    TestDARTCodeCoverage.call_testDart6GetAdvertiser();
    //}
    
    /*****************************************************************************************************************************
    @ Method:       testDART6Booking
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testDART6Booking
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history 14/11/2023 / Vimean Heng / US-0014420 - test method should run in TestDARTCodeCoverage test class
    @*****************************************************************************************************************************/
    //static testMethod void testDART6Booking () {
    //    TestDARTCodeCoverage.call_setup();
    //    TestDARTCodeCoverage.call_testDART6Booking();
    //}

    // /*****************************************************************************************************************************
    // @ Method:       testDART6DeliveryReport
    // @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    // @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testDART6DeliveryReport
    // ------------------------------------------------------------------------------------------------------------------------------
    // @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    // @*****************************************************************************************************************************/
    // static testMethod void testDART6DeliveryReport () {
    //     TestDARTCodeCoverage.call_setup();
    //     TestDARTCodeCoverage.call_testDART6DeliveryReport();
    // }

    /*****************************************************************************************************************************
    @ Method:       testClassDART6_COMPANYSERVICE
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testClassDART6_COMPANYSERVICE
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    // static testMethod void testClassDART6_COMPANYSERVICE () {
    //     TestDARTCodeCoverage.call_testClassDART6_COMPANYSERVICE();
    // }

    /*****************************************************************************************************************************
    @ Method:       testClassDART6_USERSERVICE
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testClassDART6_USERSERVICE
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    // static testMethod void testClassDART6_USERSERVICE () {
    //     TestDARTCodeCoverage.call_testClassDART6_USERSERVICE();
    // }

    /*****************************************************************************************************************************
    @ Method:       testClassDART6_ORDERSERVICE
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testClassDART6_ORDERSERVICE
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    // static testMethod void testClassDART6_ORDERSERVICE () {
    //     TestDARTCodeCoverage.call_testClassDART6_ORDERSERVICE();
    // }

    /*****************************************************************************************************************************
    @ Method:       testClassDART6_LINEITEMSERVICE
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testClassDART6_LINEITEMSERVICE
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    // static testMethod void testClassDART6_LINEITEMSERVICE () {
    //     TestDARTCodeCoverage.call_testClassDART6_LINEITEMSERVICE();
    // }

    /*****************************************************************************************************************************
    @ Method:       testClassDart6AvailabilityForecast
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testClassDart6AvailabilityForecast
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    // static testMethod void testClassDart6AvailabilityForecast () {
    //     TestDARTCodeCoverage.call_testClassDart6AvailabilityForecast();
    // }

    /*****************************************************************************************************************************
    @ Method:       testDART6ReportService
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testDART6ReportService
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    // static testMethod void testDART6ReportService () {
    //     TestDARTCodeCoverage.call_testDART6ReportService();
    // }

    /*****************************************************************************************************************************
    @ Method:       testDART6CustomTargetingService
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testDART6CustomTargetingService
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    // static testMethod void testDART6CustomTargetingService () {
    //     TestDARTCodeCoverage.call_testDART6CustomTargetingService();
    // }
    
    /*****************************************************************************************************************************
    @ Method:       testDART6NetworkService
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 call test method TestDARTCodeCoverage.call_testDART6NetworkService
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    // static testMethod void testDART6NetworkService () {
    //     TestDARTCodeCoverage.call_testDART6NetworkService();
    // }


    // US-0008578 from here are the test methods to covering DARTObject, DART6Message. DART6Parser

    /*****************************************************************************************************************************
    @ Method:       test_DARTObjectAndDART6MessageCoverage
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008578 to cover missing line of DARTObject and DART6Message class
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    static testMethod void test_DARTObjectAndDART6MessageCoverage () {
        // for DARTObject class:
        DARTObject dartObj = new DARTObject();

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
            RecordTypeId = adServerDartRTId,
            ExternalLineDescriptionId__c = '123456789'
        );
        insert adServer;

        acc = TST_DataGenerator.generateAccount();
        insert acc;

        Id accId = acc.Id;
        acc = [Select Id,Name, RecordType.Name From Account Where Id =: accId ];

        Advertiser__c advertiser = new Advertiser__c(Account__c=acc.id, Agency__c=acc.id, DART5_Advertiser_Id__c='111111', DART6_Advertiser_Id__c='222222');
        insert advertiser;


        DARTObject.DARTAdvertiser dartAdver = new DARTObject.DARTAdvertiser(acc);
        System.assertEquals(acc.Id, dartAdver.getAccountId());
        System.assertEquals(acc.Name, dartAdver.getAccountName());
        System.assertEquals(acc.RecordType.Name, dartAdver.getAccountRectName());

        String tempId = '12345678';
        String assignAdserver = 'US';
        String errMsg = 'Test Error';

        dartAdver.setTempId(tempId);
        dartAdver.setAssignAdserver(assignAdserver);
        dartAdver.setDartErrMsg(errMsg);

        System.assertEquals(tempId, dartAdver.getTempId());
        System.assertEquals(assignAdserver, dartAdver.getAssignAdserver());
        System.assertEquals(errMsg, dartAdver.getDartErrMsg());



        opp = TST_DataGenerator.generateOpp(acc.Id);
        opp.Name = 'Test test test test';
        opp.OwnerId = UserInfo.getUserId();

        Date startDate = Date.today().addDays(1);
        Date endDate = Date.today().addDays(2);

        opp.Start_Date__c = startDate;
        opp.End_Date__c = endDate;

        insert opp;
        Id oppId = opp.Id;
        opp = [Select Id,Name, Owner.Id From Opportunity Where Id =: oppId];

        DARTObject.DARTOrder dartOrder = new DARTObject.DARTOrder(opp);

        DARTObject.DARTPerson salesPeople = new DARTObject.DARTPerson();
        salesPeople.setUserEmail('testuser1@gaea-sys.com');
        dartOrder.setSalepeople(salesPeople);
        System.assertEquals('testuser1@gaea-sys.com', dartOrder.getSalepeople().getUserEmail());

        DARTObject.DARTPerson primaryTrafficker = new DARTObject.DARTPerson();
        primaryTrafficker.setUserEmail('testuser2@gaea-sys.com');
        dartOrder.setPrimaryTrafficker(primaryTrafficker);
        System.assertEquals('testuser2@gaea-sys.com', dartOrder.getPrimaryTrafficker().getUserEmail());

        System.assertEquals(UserInfo.getUserId(), dartOrder.getOwnerId());


        site = TST_DataGenerator.generateSite();
        site.Name = 'US';
        site.Country__c = 'US';
        site.currencyIsoCode = 'USD';
        insert site;
            
        Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
        prod1 = TST_DataGenerator.generateProduct(site.Id);
        prod1.Name = 'Test test test';
        prod1.RecordTypeId = prodDartRTId;
        insert prod1;

        //Sophal:03/03/2021:US-0009139 to cover DFPController.getAvailability below
        Advertising_Medium__c adVertMedium = new Advertising_Medium__c(Name='test test test',Dart_AdSlotSize__c='100x100',Quantity_Multiplier__c=1,to_Subtract__c=1);
        insert adVertMedium;

        prod1.Advertising_Medium__c = adVertMedium.Id;
        System.runAs(currentUser){
            update prod1;
        }
        


        quote = TST_DataGenerator.generateQuote(opp.Id);
        insert quote;

        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(prod1.id, null);
        insert pbe;

        qli = TST_DataGenerator.generateQuoteLinItem( quote.id, prod1.id, pbe.id);

        //insert qli;


        Targeting__c tg = new Targeting__c(Description__c='test');
        tg.DFP_Time_Monday__c = '0:00 - 0:59';
        tg.DFP_Time_Tuesday__c = '0:00 - 0:59';
        tg.DFP_Time_Wednesday__c = '0:00 - 0:59';
        tg.DFP_Time_Thursday__c = '0:00 - 0:59';
        tg.DFP_Time_Friday__c = '0:00 - 0:59';
        tg.DFP_Time_Saturday__c = '0:00 - 0:59';
        tg.DFP_Time_Sunday__c = '0:00 - 0:59';
        insert tg;

        qli.Targeting__c = tg.Id;
        insert qli;
        //System.runAs(currentUser){
            //update qli;
        //}
        RemoteResponse response =  DFPController.getAvailability(qli.Id);
        System.debug('#### response :: ' + response);
        System.assertEquals('', response.message);
        System.assertEquals(RemoteResponse.STATUSCODE_OK,response.statusCode);


        Devices__c browser = new Devices__c(DFP_API_Name__c='Browser', Dart_ID__c = 111111);
        Devices__c browserLanguage = new Devices__c(DFP_API_Name__c='BrowserLanguage', Dart_ID__c = 22222);
        Devices__c deviceCapability = new Devices__c(DFP_API_Name__c='DeviceCapability', Dart_ID__c = 33333);
        Devices__c deviceManufacturer = new Devices__c(DFP_API_Name__c='DeviceManufacturer', Dart_ID__c = 44444);
        Devices__c operatingSystem = new Devices__c(DFP_API_Name__c='OperatingSystem', Dart_ID__c = 55555);
        Devices__c operatingSystemVersion = new Devices__c(DFP_API_Name__c='OperatingSystemVersion', Dart_ID__c = 66666);
        Devices__c mobileDevice = new Devices__c(DFP_API_Name__c='MobileDevice', Dart_ID__c = 77777);
        Devices__c mobileDeviceSubmodel = new Devices__c(DFP_API_Name__c='MobileDeviceSubmodel', Dart_ID__c = 888888);
        List<Devices__c> devices = new List<Devices__c>{browser,browserLanguage,deviceCapability,deviceManufacturer,operatingSystem,operatingSystemVersion,mobileDevice,mobileDeviceSubmodel};
        insert devices;

        List<TargetingDeviceAssociation__c> targetDeviceAssoc = new List<TargetingDeviceAssociation__c>();
        for(Devices__c device : devices){
            targetDeviceAssoc.add(new TargetingDeviceAssociation__c(Device__c=device.Id,Targeting__c=tg.Id));
        }
        insert targetDeviceAssoc;

        Content__c content = new Content__c(Name = 'test content');
        insert content;

        Ad_Product__c adProd = [Select Id,Quantity__c,Billing_Category__c,Targeting__c, UnitPrice__c, Name,Ad_Id__c From Ad_Product__c Where Opportunity__c =: opp.Id Limit 1];
        adProd.Product2__c = prod1.Id;
        adProd.Billing_Category__c = 'Test';
        adProd.UnitPrice__c = 9;
        adProd.Targeting__c = tg.Id;
        adProd.Line_Item_Description__c = 'Test test test';
        adProd.SalesPriceNet__c = 18;
        adProd.Predefined_Adunit__c = content.Id;
        System.runAs(currentUser){
            update adProd;
        }
        
        Ad_Product__c adProdAfterRequery = (Ad_Product__c)QueryUtil.queryRecord(adProd.Id, DFPController.DFP_ADPROD_ADDITIONAL_FIELD);
        DARTObject.DARTAds dartAds = new DARTObject.DARTAds(adProdAfterRequery);
        
        dartAds.setExternalFromDate(startDate);
        dartAds.setExternalEndDate(endDate);
        dartAds.setExternalQuality(Long.valueOf(String.valueof(adProd.Quantity__c)));
        dartAds.setExternalBillingCategory(adProd.Billing_Category__c);
        dartAds.setExternalSalePrice(Long.valueOf(String.valueof(adProd.UnitPrice__c)));

        Test.startTest();

        System.assertEquals(startDate, dartAds.getExternalFromDate());
        System.assertEquals(endDate, dartAds.getExternalEndDate());
        System.assertEquals(adProd.Quantity__c, dartAds.getExternalQualilty());
        System.assertEquals(adProd.Billing_Category__c, dartAds.getExternalBillingCategory());
        System.assertEquals(adProd.UnitPrice__c, dartAds.getExternalSalePrice());
        System.assertEquals(adProd.Line_Item_Description__c, dartAds.getLineDesc());

        System.assertEquals(adProdAfterRequery.from_Date__c, dartAds.getStartDateTime());
        System.assertEquals(adProdAfterRequery.until_Date__c, dartAds.getEndDateTime());
        System.assertEquals(prod1.Name, dartAds.getProductName());

        System.assert(dartAds.getListDTOTimeTargeting().size() > 0);
        System.assert(dartAds.getRate() != null);
        System.assert(dartAds.getCurrencyCode() != null);

        // for DART6Message

        Id adServerId = adServer.Id;
        adServer = [
            Select
            Id,
            Timezone__c,
            Name,
            Login_URL__c,
            User_Name__c,
            Password__c,
            Active__c,
            Network_ID__c,
            Client_ID__c,
            Client_Secret__c,
            Refresh_Token__c,
            RT_Waiting__c,
            ExternalLineDescriptionId__c,
            RecordTypeId,
            RecordType.Name
            From AdServer_Login__c
            Where Id =: adServerId
        ];
        FactoryDARTRequest factoryDart  = FactoryDARTRequest.getInstance();
        DART6Message.DFPAdsRequest dartAdsRequest = (DART6Message.DFPAdsRequest )factoryDart.createDARTSubmitAdsRequest(adServer,adProdAfterRequery,null);
        dartAdsRequest.Invoke();

        update new Opportunity(Id=opp.Id, Quote_Sync_In_Progress__c = true);
        OpportunityLineItem oppLineItem = TST_DataGenerator.generateOpportunityLinItem(opp.Id,pbe.Id,tg.Id);
        insert oppLineItem;
        Id oppLineItemId = oppLineItem.Id;

        oppLineItem = [Select Id,Ad_Id__c,PriceBookEntry.Product2.Site__r.Country__c From OpportunityLineItem Where Id =: oppLineItemId];
    

        Dart6Message.DFPGetLineItemRequestById dartOppLineItemRequest = new Dart6Message.DFPGetLineItemRequestById(oppLineItem);
        dartOppLineItemRequest.invoke();

        Test.stopTest();
        
    }

    // /*****************************************************************************************************************************
    // @ Method:       test_DART6ParserCoverage
    // @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    // @ Purpose:      US-0008578 to cover missing line of DART6Parser class
    // ------------------------------------------------------------------------------------------------------------------------------
    // @ Change history:  03.12.2020 / Sophal Noch / Created the method.
    // @*****************************************************************************************************************************/
    // static testMethod void test_DART6ParserCoverage () {
    //     DART6Parser dart6Parser = new DART6Parser();
    //     bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = true,byPass_Validation__c=true);
    //     insert bp;

    //     Id adServerDartRTId = ApexUtil.getRecordTypeByName('AdServer_Login__c','DART6').Id;
    //     AdServer_Login__c adServer = new AdServer_Login__c(
    //         Name = 'US',
    //         Login_URL__c='http://test.com',
    //         User_Name__c='dart6testuser@gmail.com',
    //         Password__c ='testpwddart6123456',
    //         Active__c = true,
    //         Network_ID__c='123456',
    //         Client_ID__c = 'xxxxxxxxxxxxxxxxxxxxx',
    //         Client_Secret__c = 'xxxxxxxxxxxxxxx',
    //         Refresh_Token__c = 'xxxxxxxxxxx',
    //         RT_Waiting__c = true,
    //         RecordTypeId = adServerDartRTId
    //     );
    //     insert adServer;


    //     Id opp_direct = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('eBay Ads - Direct').getRecordTypeId();

    //     acc = TST_DataGenerator.generateAccount();
    //     insert acc;

    //     opp = TST_DataGenerator.generateOpp(acc.Id);
    //     opp.Special_Terms__c = 'New Terms - Spe';
    //     opp.Start_Date__c = Date.today();
    //     opp.End_Date__c = Date.today().addDays(1);
    //     opp.Amount = 100;
    //     opp.RecordTypeId = opp_direct;
    //     insert opp;

    //     mediaPlan = TST_DataGenerator.generateMediaPlan(opp);
    //     insert mediaPlan;

    //     quote = TST_DataGenerator.generateQuote(opp.Id, mediaPlan.Id);
    //     insert quote;

    //     Site__c site = TST_DataGenerator.generateSite();
    //     site.Name = 'us';
    //     site.Country__c = 'US';
    //     site.currencyIsoCode = 'USD';
    //     insert site;

    //     Product2 prod = TST_DataGenerator.generateProduct(site.Id);
    //     Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
    //     prod.RecordTypeId = prodDartRTId;
    //     insert prod;

    //     PriceBookEntry pbe =TST_DataGenerator.generatePricebookEntry(prod.id, null);
    //     insert pbe;
       
    //     qli = TST_DataGenerator.generateQuoteLinItem( quote.id, prod.id, pbe.id);
    //     Test.startTest();
    //     insert qli;
    //     Test.stopTest();

    //     quote.Status = 'Approved';
    //     update quote;
    //     Id ioId = GW_IO.createIOFromQuote(quote.Id);

    //     quote = (Quote) QueryUtil.queryRecord(quote.id);
    //     IO__c io = (IO__c) QueryUtil.queryRecord(ioId);
    //     System.debug('#### io :: ' + io);

    //     Id ioLineItemId = [Select Id From IO_LineItem__c Where IO__c =: io.Id Limit 1].Id; 

    //     IO_LineItem__c ioLineItem = (IO_LineItem__c)QueryUtil.queryRecord(ioLineItemId, DFPController.DFP_IO_ADDITIONAL_FIELD);


    //     DART6_LINEITEMSERVICE.LineItem dartLineItem =  new  DART6_LINEITEMSERVICE.LineItem();
    //     DART6_FORECASTSERVICE.Goal gl = new DART6_FORECASTSERVICE.Goal(); 
    //     gl.unitType = 'IMPRESSIONS';
    //     gl.units = 50;
         
    //     dartLineItem.id = Long.valueOf('123456');
    //     //lineItem.unitType = 'STANDARD';
    //     dartLineItem.costType = 'CPM';
    //     dartLineItem.orderId=Long.valueOf('111111'); 
    //     dartLineItem.primaryGoal = gl;

    //     DART6_FORECASTSERVICE.Date_x date_x = new DART6_FORECASTSERVICE.Date_x();
    //     date_x.year = 2020;
    //     date_x.month = 11;
    //     date_x.day = 11;

    //     DART6_FORECASTSERVICE.DateTime_x datetime_x = new DART6_FORECASTSERVICE.DateTime_x();
    //     datetime_x.date_x = date_x;
    //     datetime_x.hour = 1;
    //     datetime_x.minute = 1;
    //     datetime_x.second = 1;
    //     datetime_x.timeZoneId = 'Asia/Singapore';
        

    //     dartLineItem.startDateTime = datetime_x;
    //     dartLineItem.endDateTime = datetime_x;

    //     DART6_LINEITEMSERVICE.Money money = new DART6_LINEITEMSERVICE.Money();
    //     money.currencyCode = 'us';
    //     money.microAmount = 1000000;
    //     dartLineItem.costPerUnit = money;
        

    //     DART6Parser.DFPResponseAdditionalItemFields dartParser = new DART6Parser.DFPResponseAdditionalItemFields(ioLineItem);
    //     dartParser.setObjectDFP(dartLineItem);
    //     dartParser.parse();


    //     DART6Parser.XmlToAdxImportParser xmlParser = new DART6Parser.XmlToAdxImportParser('Revenue Schedule Daily');
    //     xmlParser.setObjectDFP('<Report><ReportData><DataSet><Row><Column></Column></Row></DataSet></ReportData></Report>') ;
    //     try{
    //         xmlParser.parse();
    //     }catch(Exception e){ }

        

    // }

    // Added by Acmatac 17 Jan 2021
    @isTest
    static void test_UTIL_BookingItemsController2 () {
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
        try{
            UTIL_BookingItemsController.initializeDataOpportunity(null);
        }catch(Exception e){}
        try{    
            UTIL_BookingItemsController.bookingDataOpportunity(null);
        }catch(Exception e){}
    }

    // Added by Acmatac 17 Jan 2021
    @isTest
    static void test_DataGenerator_Coverage () {
        Set<String> dataSet = TST_DataGenerator.dataSet;
        Account ac1 = TST_DataGenerator.generateAccount();
        Opportunity opp1 = TST_DataGenerator.generateOpp(ac1.Id);
        Quote q1 = TST_DataGenerator.generateQuote(opp1.Id, null);
        Quote q2 = TST_DataGenerator.generateQuote(opp1.Id);
        AdServer_Login__c ads1 = TST_DataGenerator.generateAdServerLogin();
        Site__c site1 = TST_DataGenerator.generateSite();
        Product2 prod1 = TST_DataGenerator.generateProduct();
        Product2 prod2 = TST_DataGenerator.generateProduct(site1.Id);
        PriceBookEntry pbe1 = TST_DataGenerator.generatePricebookEntry(prod2.Id, null);
        QuoteLineItem qli1 = TST_DataGenerator.generateQuoteLinItem(q2.Id, prod1.Id, pbe1.Id);
        Targeting__c tg1 = TST_DataGenerator.createTargetingObject();
        Targeting__c tg2 = TST_DataGenerator.generateTargeting();
        OpportunityLineItem oppli = TST_DataGenerator.generateOpportunityLinItem(opp1.Id, pbe1.Id, tg1.Id);
        Map<String, List<sObject>> setupData = TST_DataGenerator.setupSimpleData(dataSet);
        //Map<String, List<sObject>> setupTGData = TST_DataGenerator.setUpTargetingData();
    }

    /*****************************************************************************************************************************
    @ Method:       test_doPropose
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0009927 - Update PG Opportunity Flow
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    static testMethod void test_doPropose () {

        Profile profileAdmin = ApexUtil.getProfileByName('System Administrator');
        User adminUser =new User(
            Username='testDfpUser@ebay.com',
            LastName='TestingUser', // to match with DFP user
            Alias='dfpUser',
            CommunityNickname='DFPUser2test',
            TimeZoneSidKey='Atlantic/Cape_Verde',
            LocaleSidKey='en_GB',
            EmailEncodingKey='ISO-8859-1',
            ProfileId=profileAdmin.id, 
            LanguageLocaleKey='de',
            Email='testDfpUser@ebay.com.invalid'
        );  
        insert adminUser;
        System.runAs(adminUser){

            setUpData2();

            Test.startTest();
                BookingOppAdProdController.bookingDataAdProductOpportunity(adProd.Id);
            Test.stopTest();
        }       
    
        
    }

/*****************************************************************************************************************************
    @ Method:       test_doPropose
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0009927 - Update PG Opportunity Flow
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    static testMethod void test_submitProposalAndLineitemToGAM () {

        Profile profileAdmin = ApexUtil.getProfileByName('System Administrator');
        User adminUser =new User(
                Username='testDfpUser@ebay.com',
                LastName='TestingUser', // to match with DFP user
                Alias='dfpUser',
                CommunityNickname='DFPUser2test',
                TimeZoneSidKey='Atlantic/Cape_Verde',
                LocaleSidKey='en_GB',
                EmailEncodingKey='ISO-8859-1',
                ProfileId=profileAdmin.id, 
                LanguageLocaleKey='de',
                Email='testDfpUser@ebay.com.invalid'
        );  
        insert adminUser;
        System.runAs(adminUser){
            //acc = [Select Id,Name, RecordType.Name From Account Where Name = 'Account test' Limit 1];
            //opp = [Select Id,Name, Owner.Id From Opportunity Where Name ='Test test test test' Limit 1];
            //adProd = [Select Id,Line_Item_Description__c,Quantity__c,Billing_Category__c,Targeting__c, UnitPrice__c, Name,Ad_Id__c From Ad_Product__c Where Opportunity__c =: opp.Id Limit 1];
            //prod1 = [Select Id,Name, RecordType.Name From Product2 Where Name = 'Test test test' Limit 1];
            setUpData2();

            RemoteResponse response = new RemoteResponse();
    
            DARTObject.DARTAdvertiser dartAdver = new DARTObject.DARTAdvertiser(acc);
            System.assertEquals(acc.Id, dartAdver.getAccountId());
            System.assertEquals(acc.Name, dartAdver.getAccountName());
            System.assertEquals(acc.RecordType.Name, dartAdver.getAccountRectName());
    
            String tempId = '12345678';
            String assignAdserver = 'US';
            String errMsg = 'Test Error';
    
            dartAdver.setTempId(tempId);
            dartAdver.setAssignAdserver(assignAdserver);
            dartAdver.setDartErrMsg(errMsg);
    
            System.assertEquals(tempId, dartAdver.getTempId());
            System.assertEquals(assignAdserver, dartAdver.getAssignAdserver());
            System.assertEquals(errMsg, dartAdver.getDartErrMsg());
    
            DARTObject.DARTOrder dartProposal = new DARTObject.DARTOrder(opp, true);
    
            DARTObject.DARTPerson salesPeople = new DARTObject.DARTPerson();
            salesPeople.setUserEmail('testuser1@gaea-sys.com');
            dartProposal.setSalepeople(salesPeople);
            System.assertEquals('testuser1@gaea-sys.com', dartProposal.getSalepeople().getUserEmail());
    
            DARTObject.DARTPerson primaryTrafficker = new DARTObject.DARTPerson();
            primaryTrafficker.setUserEmail('testuser2@gaea-sys.com');
            dartProposal.setPrimaryTrafficker(primaryTrafficker);
            System.assertEquals('testuser2@gaea-sys.com', dartProposal.getPrimaryTrafficker().getUserEmail());
            System.assertEquals(UserInfo.getUserId(), dartProposal.getOwnerId());
    
            Ad_Product__c adProdAfterRequery = (Ad_Product__c)QueryUtil.queryRecord(adProd.Id, DFPController.DFP_ADPROD_ADDITIONAL_FIELD);
            DARTObject.DARTAds dartProposalineitem = new DARTObject.DARTAds(adProdAfterRequery, true);
            
    
            Test.startTest();
    
            System.assertEquals(adProd.Line_Item_Description__c, dartProposalineitem.getLineDesc());
    
            System.assertEquals(adProdAfterRequery.from_Date__c, dartProposalineitem.getStartDateTime());
            System.assertEquals(adProdAfterRequery.until_Date__c, dartProposalineitem.getEndDateTime());
            System.assertEquals(prod1.Name, dartProposalineitem.getProductName());
    
            System.assert(dartProposalineitem.getListDTOTimeTargeting().size() > 0);
            System.assert(dartProposalineitem.getRate() != null);
            System.assert(dartProposalineitem.getCurrencyCode() != null);
    
    
            SObject parentRecord = QueryUtil.queryRecord(Util.getString(opp.Id), new Set<String>{'Owner.Name', 'Owner.id', 'Owner.Email', Util.NS + 'Account.Name'});
            SObject lineItemRecord = (SObject)adProdAfterRequery;
    
            Opportunity pi = (Opportunity)parentRecord;
    
            DFPController.lineItemRecord = lineItemRecord;
            DFPController.parentRecord = parentRecord;
            DFPController.dartCountry = adProdAfterRequery.Product2__r.Site__r.Name;
            DFPController.dartVerCountry = adProdAfterRequery.Product2__r.RecordType.DeveloperName + '_' +  DFPController.dartCountry ;
            DFPController.adserverIDOrderID = adProdAfterRequery.Adserver_ID_Order_ID__c;
            DFPController.proposalId = pi.Proposal_Id__c;
            DFPController.adserverAdvID = adProdAfterRequery.Adserver_Adv_Advertiser_ID__c;
            DFPController.advertiserID = pi.AccountId;
            DFPController.agencyID = pi.Agency__c;
            DFPController.dartVersion = adProdAfterRequery.Product2__r.RecordType.DeveloperName;
    
            BookingController bookingCon = new BookingController(parentRecord, lineItemRecord,  DFPController.dartVersion, DFPController.dartCountry, DFPController.dartVerCountry, acc.Id);
            DFPController.bookingCon = bookingCon;
    
            Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
            Map<String, Advertiser__c> mapAdverUpsert = new Map<String, Advertiser__c>();
    
            DFPController.getAdvertiser(mapAdvertiser);
            DFPController.processSearchAdvertiser(mapAdvertiser);
            DFPController.populateAdvertiserToUpsert(mapAdvertiser,mapAdverUpsert);
    
            bookingCon.getExistProposal();
            bookingCon.processAndSendProposal(mapAdvertiser);
            
            List<DARTObject.IDARTObjectOrder> listProposal = new List<DARTObject.IDARTObjectOrder>();
            listProposal = bookingCon.getListOrder();
            bookingCon.parentRecord.put('Proposal_Id__c', listProposal[0].getDartId());
    
            bookingCon.processAndSendProposalLineItem(listProposal.get(0), mapAdvertiser);
            bookingCon.lineItemRecord.put('Proposal_Lineitem_Id__c', '123456');
            bookingCon.processAndSendProposalLineItem(listProposal.get(0), mapAdvertiser);
            
            DFPController.logErroParentItemRequest(mapAdverUpsert, response, new DmlException());
            DFPController.logErrorLineitemRequest(false, response, new DmlException());
            DFPController.logGeneralBookingError(response, new DmlException());
    
            Test.stopTest();


        }
        

        
    }

}