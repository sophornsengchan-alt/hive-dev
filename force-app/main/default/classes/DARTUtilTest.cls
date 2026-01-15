/*****************************************************************************************************************************
@ Class:       DARTUtil
@ Author:      Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:     US-0008375 test class for DARTObject
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  10.05.2021 / Mony Nou / Created the class.
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  16.11.2023 / Vimean Heng / US-0014417 / Fix Mixed DML
@*****************************************************************************************************************************/

@IsTest 
private class DARTUtilTest {

    private static User currentUser = [ select Id, Name from User where Id = :UserInfo.getUserId() ]; 

    @isTest
    static void test_composeDigestAuthorizationHeader () {

        Test.startTest();

            String result = DARTUtil.composeDigestAuthorizationHeader('TestString1', 'TestString2', 'TestString3', 'TestString4');
            System.assert(String.isNotBlank(result));

        Test.stopTest();
    }

    @isTest
    static void test_getRequestToken () {

        initData();
        
        Test.startTest();

            String result = DARTUtil.getRequestToken('US');
            System.assert(String.isNotBlank(result));

        Test.stopTest();
    }

    @isTest
    static void test_sendMail () {

        Test.startTest();

            DARTUtil.sendMail(new List<String>{'test@test.com.invalid'}, new List<String>{'test@test.com.invalid'}, 'test', 'TEST', 'This is test.');
            
        Test.stopTest();
    }

    @isTest
    static void test_generateIds () {
        
        Test.startTest();

            String result = DARTUtil.generateIds(new Set<String>{'Id1', 'Id2'});
            System.debug('### result :: ' + result);
            System.assert(String.isNotBlank(result));

        Test.stopTest();
    }
    /************************************************************************
    -------------------------------------------------------------------------
    @ Change history:  16.11.2023 / Vimean Heng / US-0014417 / Fix Mixed DML
    *************************************************************************/
    @isTest
    static void test_getListGeographies () {
        
        initData();
        geo = new Geography__c(Name = 'Cambodia');
        System.runAs(currentUser){
            insert geo;
        }       
        geo2 = new Geography__c(Name = 'My City',Node_ID__c=geo.Id);
        System.runAs(currentUser){  
            insert geo2;
        }
        TargetingGeographyAssociation__c targetGeo = new TargetingGeographyAssociation__c( Targeting__c = tg.Id, Geography__c=geo.Id );
        System.runAs(currentUser){
            insert targetGeo;
        }
        Test.startTest();

            Geography__c[] result = DARTUtil.getListGeographies(tg.Id);
            System.assert(result != null & !result.isEmpty());

        Test.stopTest();
    }
    /************************************************************************
    -------------------------------------------------------------------------
    @ Change history:  16.11.2023 / Vimean Heng / US-0014417 / Fix Mixed DML
    *************************************************************************/
    @isTest
    static void test_getListDevices () {
        
        initData();

        Devices__c mobileDeviceCategory = new Devices__c(Name='Test',DFP_API_Name__c='DeviceCategory', Dart_ID__c = 99999);
        List<Devices__c> devices = new List<Devices__c>{mobileDeviceCategory};
        System.runAs(currentUser){
            insert devices;
        }
        List<TargetingDeviceAssociation__c> targetDeviceAssoc = new List<TargetingDeviceAssociation__c>();
        for(Devices__c device : devices){
            targetDeviceAssoc.add(new TargetingDeviceAssociation__c(Device__c=device.Id,Targeting__c=tg.Id));
        }
        System.runAs(currentUser){
            insert targetDeviceAssoc;
        }
        
        Test.startTest();

            Devices__c[] result = DARTUtil.getListDevices(tg.Id);
            System.assert(result != null & !result.isEmpty());

        Test.stopTest();
    }
    /************************************************************************
    -------------------------------------------------------------------------
    @ Change history:  16.11.2023 / Vimean Heng / US-0014417 / Fix Mixed DML
    *************************************************************************/
    @isTest
    static void test_getListFrequencyCappings () {
        
        initData();
        
        TargetingFrequencyAssociation__c taFC = new TargetingFrequencyAssociation__c(Targeting__c = tg.Id, FC_Check_Inventory__c = true) ;
        System.runAs(currentUser){
            insert taFC;
        }
        Test.startTest();

            TargetingFrequencyAssociation__c[] result = DARTUtil.getListFrequencyCappings(tg.Id);
            System.assert(result != null & !result.isEmpty());

        Test.stopTest();
    }
    /************************************************************************
    -------------------------------------------------------------------------
    @ Change history:  16.11.2023 / Vimean Heng / US-0014417 / Fix Mixed DML
    *************************************************************************/
    @isTest
    static void test_getListConnections () {
        
        initData();

        Connection__c con1 = new Connection__c(Dart_ID__c = 123456);
        System.runAs(currentUser){
            insert con1;
        }
        TargetingConnectionAssociation__c targetConn = new TargetingConnectionAssociation__c(Targeting__c = tg.Id,Connection__c=con1.Id);
        System.runAs(currentUser){
            insert targetConn;
        }
        Test.startTest();

            Connection__c[] result = DARTUtil.getListConnections(tg.Id);
            System.assert(result != null & !result.isEmpty());

        Test.stopTest();
    }

    @isTest
    static void test_getListContents () {
        
        initData();

        Test.startTest();
            Product2 prod = [SELECT Id,PlacementDB__c FROM Product2 WHERE PlacementDB__c <> null LIMIT 1];
            Content__c[] result = DARTUtil.getListContents (tg.Id, prod.Id);
            System.assert(result != null & !result.isEmpty());

            result = DARTUtil.getPredefinedContents(content.Id);
            System.assert(result != null & !result.isEmpty());

        Test.stopTest();
    }

    /************************************************************************
    -------------------------------------------------------------------------
    @ Change history:  16.11.2023 / Vimean Heng / US-0014417 / Fix Mixed DML
    *************************************************************************/
    @isTest
    static void test_getPlacementTargeting () {
        
        initData();
        PlacementTargetingAssociation__c pta = new PlacementTargetingAssociation__c(Targeting__c = tg.Id,Placement__c=plc.id);
        System.runAs(currentUser){
            insert pta;
        }
        Test.startTest();

            Placement__c[] result = DARTUtil.getPlacementTargeting(tg.Id);
            System.assert(result != null & !result.isEmpty());

        Test.stopTest();
    }
    
    @isTest
    static void test_getListDevicesCategory () {
        
        Devices__c mobileDeviceCategory = new Devices__c(Name='Test',DFP_API_Name__c='DeviceCategory', Dart_ID__c = 99999);
        List<Devices__c> devices = new List<Devices__c>{mobileDeviceCategory};
        insert devices;

        Test.startTest();

            Devices__c[] result = DARTUtil.getListDevicesCategory(new List<String>{'Test'});
            System.assert(result != null & !result.isEmpty());

        Test.stopTest();
    }
    
    @isTest
    static void test_getListAvailSites () {
        
        initData();

        Test.startTest();
            Product2 prod = [SELECT Id,PlacementDB__c FROM Product2 WHERE PlacementDB__c <> null LIMIT 1];
            Content__c[] result = DARTUtil.getListAvailSites (prod.Id,new Set<String>{'Dart - Site'});
            System.assert(result != null & !result.isEmpty());
        Test.stopTest();
    }

    @isTest
    static void test_getAccessToken() {

        initData();

        Test.startTest();

            String result = DARTUtil.getAccessToken(adServer);

        Test.stopTest();
    }
    /************************************************************************
    -------------------------------------------------------------------------
    @ Change history:  16.11.2023 / Vimean Heng / US-0014417 / Fix Mixed DML
    *************************************************************************/
    @isTest
    static void test_getAdvertiser () {
        
        initData();

        Advertiser__c advertiser = new Advertiser__c(Account__c=acc.id, Agency__c=acc.id, DART5_Advertiser_Id__c='111111', DART6_Advertiser_Id__c='222222');
        System.runAs(currentUser){
            insert advertiser;
        }
        Test.startTest();
            Advertiser__c[] result = DARTUtil.getAdvertiser (acc.Id,acc.Id);
            System.assert(result != null & !result.isEmpty());
        Test.stopTest();
    }

    @isTest
    static void test_other() {

        Test.startTest();

            String result = DARTUtil.genTD('test');
            System.assert(String.isNotBlank(result));

            result = DARTUtil.genTR('test');
            System.assert(String.isNotBlank(result));

            CustomException err = new CustomException();
            err.setMessage('test error');
            Map<String, Exception> mError = new Map<String, Exception>{
                'TEST' => err
            };
            result = DARTUtil.generateTableForecastError(mError);
            System.assert(String.isNotBlank(result));

            result = DARTUtil.extractMessage('Web service callout failed: WebService returned a SOAP Fault: test faultcode=soap:Server faultactor=');

            result = DARTUtil.encodeHTML('<test>');

            result = DARTUtil.oauth2Request('test', 'test');

            DARTUtil.countCurrentBatch();
            DARTUtil.checkDfpReuiredFields(null);

            Double d = DARTUtil.toDouble('2.22');

            Integer i = DARTUtil.toInteger('2');
            i = DARTUtil.toInteger(2.0);

            Boolean b = DARTUtil.isNumber('2');

            // California locale time
            string year = '2009';
            string month = '3';
            string day = '5';
            string hour = '5';
            string minute = '2';
            string second = '2';
            string stringDate = year + '-' + month + '-' + day + ' ' + hour + ':' + minute +  ':' + second;

            DateTime dt = DARTUtil.fixTimezoneDateTime(stringDate, 'America/Los_Angeles');

            //for all static string variable
            result = DARTUtil.DART_DATEFORMAT_QUERY;
            result = DARTUtil.DART5;
            result = DARTUtil.DART6;
            result = DARTUtil.PRODUCT_PACKAGE;
            result = DARTUtil.AUTHENTICATION_TYPE;
            result = DARTUtil.EMAIL_SUBJECT;
            result = DARTUtil.EMAIL_SUBJECT_BOOKING;
            result = DARTUtil.USER_ROLE_SALESPERSON;
            result = DARTUtil.USER_ROLE_PRIMARY_TRAFICKER;
            result = DARTUtil.TEAM_MEMBER_ROLE;
            result = DARTUtil.ENDPOINT_GOOGLE_OAUTH2_TOKEN;
            

        Test.stopTest();
    }

//////// STATIC TEST RECORDS //////////
    class CustomException extends Exception{}
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
    static Geography__c posCode,geo,geo2;
    static Content__c content;
    static Targeting__c tg;
    static Placement__c plc;
    static AdServer_Login__c adServer;

    private static void initData() {

        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false,byPass_Validation__c=true);
        Profile p = [select id from Profile where name='Standard Ads User Profile' limit 1];
        u1 = new User(alias = 'TestApro', email='TestsubApprov@ebay.com', 
        emailencodingkey='UTF-8', lastname='TestsubApprov', firstname='TestsubApprov', languagelocalekey='en_US', 
        localesidkey='en_US', profileid = p.Id, 
        timezonesidkey='America/Los_Angeles', username='TestsubApprov@salesforce.de', isActive = true);

        System.runAs(u1){

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

            acc = TST_DataGenerator.generateAccount();
            insert acc;

            site = TST_DataGenerator.generateSite();
            site.Name = 'us';
            site.Country__c = 'US';
            site.currencyIsoCode = 'USD';
            insert site;

            Advertising_Medium__c adVertMedium = new Advertising_Medium__c(Name='test test test');
            insert adVertMedium;

            content = new Content__c(Name = 'test content', Type__c = 'Dart - Site');
            insert content;

            plc = new Placement__c(Name='test placement', Dart_ID__c=11111, Content_Category_Site__c=content.Id);
            insert plc;
            
            Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;

            prod1 = TST_DataGenerator.generateProduct(site.Id);
            prod1.RecordTypeId = prodDartRTId;
            prod1.Advertising_Medium__c = adVertMedium.Id;
            prod1.Fixed_Site__c = true;
            prod1.PlacementDB__c = plc.Id;
            insert new List<Product2>{prod1};
            
            PriceBookEntry pbe1 =TST_DataGenerator.generatePricebookEntry(prod1.id, null);
            insert new List<PriceBookEntry>{pbe1};

            Available_Site__c avs = new Available_Site__c (Available_Site__c = content.Id, Product__c=prod1.Id);
            insert avs;

            tg = new Targeting__c(Description__c='test');
            tg.DFP_Time_Monday__c = '0:00 - 0:59';
            tg.DFP_Time_Tuesday__c = '0:00 - 0:59';
            tg.DFP_Time_Wednesday__c = '0:00 - 0:59';
            tg.DFP_Time_Thursday__c = '0:00 - 0:59';
            tg.DFP_Time_Friday__c = '0:00 - 0:59';
            tg.DFP_Time_Saturday__c = '0:00 - 0:59';
            tg.DFP_Time_Sunday__c = '0:00 - 0:59';
            insert tg;
        }
    }
    /*
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

            content = new Content__c(Name = 'test content', Type__c = 'Dart - Site');
            insert content;

            Placement__c plc = new Placement__c(Name='test placement', Dart_ID__c=11111, Content_Category_Site__c=content.Id);
            insert plc;
            
            Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;

            prod1 = TST_DataGenerator.generateProduct(site.Id);
            prod1.RecordTypeId = prodDartRTId;
            prod1.Advertising_Medium__c = adVertMedium.Id;
            prod1.Fixed_Site__c = true;
            prod1.PlacementDB__c = plc.Id;

            prod2 = TST_DataGenerator.generateProduct(site.Id);
            prod2.RecordTypeId = prodDartRTId;
            prod2.Advertising_Medium__c = adVertMedium.Id;
            insert new List<Product2>{prod1, prod2};
            
            PriceBookEntry pbe1 =TST_DataGenerator.generatePricebookEntry(prod1.id, null);
            PriceBookEntry pbe2 =TST_DataGenerator.generatePricebookEntry(prod2.id, null);
            insert new List<PriceBookEntry>{pbe1, pbe2};

            Available_Site__c avs = new Available_Site__c (Available_Site__c = content.Id, Product__c=prod1.Id);
            insert avs;

            Advertiser__c advertiser = new Advertiser__c(Account__c=acc.id, Agency__c=acc.id, DART5_Advertiser_Id__c='111111', DART6_Advertiser_Id__c='222222');
            insert advertiser;

            qli1 = TST_DataGenerator.generateQuoteLinItem( quote.id, prod1.id, pbe1.id);
            qli1.Budget__c = 30;
            qli1.from_Date__c = date.today();
            qli1.until_Date__c = date.today();

            qli2 = TST_DataGenerator.generateQuoteLinItem( quote.id, prod2.id, pbe2.id);
            qli2.Budget__c = 55;
            qli2.from_Date__c = date.today();
            qli2.until_Date__c = date.today();
            insert new List<QuoteLineItem>{qli1, qli2};

            tg = new Targeting__c(Description__c='test');
            tg.DFP_Time_Monday__c = '0:00 - 0:59';
            tg.DFP_Time_Tuesday__c = '0:00 - 0:59';
            tg.DFP_Time_Wednesday__c = '0:00 - 0:59';
            tg.DFP_Time_Thursday__c = '0:00 - 0:59';
            tg.DFP_Time_Friday__c = '0:00 - 0:59';
            tg.DFP_Time_Saturday__c = '0:00 - 0:59';
            tg.DFP_Time_Sunday__c = '0:00 - 0:59';
            insert tg;

            qli1.Targeting__c = tg.Id;
            update qli1;

            geo = new Geography__c(Name = 'Cambodia');
            insert geo;
            geo2 = new Geography__c(Name = 'My City',Node_ID__c=geo.Id);
            insert geo2;

            TargetingGeographyAssociation__c targetGeo = new TargetingGeographyAssociation__c( Targeting__c = tg.Id, Geography__c=geo.Id );
            insert targetGeo;

            Connection__c con1 = new Connection__c(Dart_ID__c = 123456);
            insert con1;

            TargetingConnectionAssociation__c targetConn = new TargetingConnectionAssociation__c(Targeting__c = tg.Id,Connection__c=con1.Id);
            insert targetConn;

            TargetingContentAssociation__c targetingContent = new TargetingContentAssociation__c(Targeting__c = tg.Id, TargetingContent__c = content.Id);
            insert targetingContent;

            PlacementTargetingAssociation__c pta = new PlacementTargetingAssociation__c(Targeting__c = tg.Id,Placement__c=plc.id);
            insert pta;

            Devices__c browser = new Devices__c(DFP_API_Name__c='Browser', Dart_ID__c = 111111);
            Devices__c browserLanguage = new Devices__c(DFP_API_Name__c='BrowserLanguage', Dart_ID__c = 22222);
            Devices__c deviceCapability = new Devices__c(DFP_API_Name__c='DeviceCapability', Dart_ID__c = 33333);
            Devices__c deviceManufacturer = new Devices__c(DFP_API_Name__c='DeviceManufacturer', Dart_ID__c = 44444);
            Devices__c operatingSystem = new Devices__c(DFP_API_Name__c='OperatingSystem', Dart_ID__c = 55555);
            Devices__c operatingSystemVersion = new Devices__c(DFP_API_Name__c='OperatingSystemVersion', Dart_ID__c = 66666);
            Devices__c mobileDevice = new Devices__c(DFP_API_Name__c='MobileDevice', Dart_ID__c = 77777);
            Devices__c mobileDeviceSubmodel = new Devices__c(DFP_API_Name__c='MobileDeviceSubmodel', Dart_ID__c = 888888);
            Devices__c mobileDeviceCategory = new Devices__c(Name='Test',DFP_API_Name__c='DeviceCategory', Dart_ID__c = 99999);
            List<Devices__c> devices = new List<Devices__c>{browser,browserLanguage,deviceCapability,deviceManufacturer,operatingSystem,operatingSystemVersion,mobileDevice,mobileDeviceSubmodel,mobileDeviceCategory};
            insert devices;

            List<TargetingDeviceAssociation__c> targetDeviceAssoc = new List<TargetingDeviceAssociation__c>();
            for(Devices__c device : devices){
                targetDeviceAssoc.add(new TargetingDeviceAssociation__c(Device__c=device.Id,Targeting__c=tg.Id));
            }
            insert targetDeviceAssoc;

            TargetingFrequencyAssociation__c taFC = new TargetingFrequencyAssociation__c(Targeting__c = tg.Id, FC_Check_Inventory__c = true) ;
            insert taFC;

            
            
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

    }
    */
}