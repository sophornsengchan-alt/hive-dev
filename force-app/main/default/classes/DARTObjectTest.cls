/*****************************************************************************************************************************
@ Class:       DARTObject
@ Author:      Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:     US-0009350 test class for DARTObject
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  13.04.2021 / Mony Nou / Created the method.
@*****************************************************************************************************************************/
@IsTest 
private class DARTObjectTest {

    @isTest
    static void test_AbstractDARTController() {

        Test.startTest();

            DummyClass obj = new DummyClass();
            obj.getInvokedMethod();
            obj.getListDart();

        Test.stopTest();
    }

    @isTest
    static void test_DARTOrder() {
        
        setUpData();

        Test.startTest();

            DARTObject.DARTOrder obj = new DARTObject.DARTOrder('testorderId','testadvertiserId');
            obj = new DARTObject.DARTOrder(opp);

            obj.getValueField('campaignStart');
            obj.getOwnerId();
            obj.getOppId();
            obj.getOppName();
            obj.getPONumber();
            obj.getOrderName();
            obj.getOrderId();

            DARTObject.DARTPerson objDARTPerson = new DARTObject.DARTPerson();
            obj.setPrimaryTrafficker(objDARTPerson);
            obj.getPrimaryTrafficker();
            obj.setSalepeople(objDARTPerson);
            obj.getSalepeople();
            obj.setAdvertiserId('testAdId');
            obj.getOrderAvertiserId();
            obj.setDyOppName('testName');
            obj.setDyOppId('testID');

            obj.setTempId('testTempId');
            obj.setDartName('testDartName');
            obj.setDartId('testDartId');
            obj.setAssignAdserver('testAdserver');
            obj.setDartErrMsg('testError');
            obj.getTempId();
            obj.getDartName();
            obj.getDartId();
            obj.getAssignAdserver();
            obj.getDartErrMsg();


        Test.stopTest();
    }

    @isTest
    static void test_DARTAdvertiser() {

        setUpData();

        Test.startTest();

            acc = [SELECT Name,RecordTypeId, RecordType.Name From Account WHERE Id=:acc.Id];

            DARTObject.DARTAdvertiser obj = new DARTObject.DARTAdvertiser(acc);

            obj.getAccountRectName();
            obj.getAccountId();
            obj.getAccountName();

        Test.stopTest();
    }

    @isTest
    static void test_DARTAds() {

        setUpData();

        Test.startTest();

            DARTObject.DARTAds obj = new DARTObject.DARTAds(qli1);

            obj.getAdId();
            obj.getStatus();
            obj.setExternalFromDate(Date.today());
            obj.getExternalFromDate();
            obj.setExternalEndDate(Date.today().addDays(7));
            obj.getExternalEndDate();
            obj.setExternalQuality(10);
            obj.getExternalQualilty();
            obj.setExternalBillingCategory('testBillingCategory');
            obj.getExternalBillingCategory();
            obj.setExternalSalePrice(20);
            obj.getExternalSalePrice();

            DARTObject.IDARTObjectOrder obj1 = new DARTObject.DARTOrder(opp);
            obj.setOrder(obj1);
            obj.getOrder();



        Test.stopTest();
    }

    @isTest
    static void test_DARTPerson() {

        setUpData();

        Test.startTest();

            DARTObject.DARTPerson obj = new DARTObject.DARTPerson();
            obj.setUserEmail('test@test.com.invalid');
            obj.getUserEmail();

        Test.stopTest();

    }

    @isTest 
    static void test_DARTForecast() {

        setUpData();

        Test.startTest();

            qli1 = (QuoteLineItem) QueryUtil.queryRecord(qli1.Id, DFPController.DFP_QUOTE_ADDITIONAL_FIELD );

            DARTObject.DARTForecast obj = new DARTObject.DARTForecast(qli1);
            obj.getStartDateTime();
            obj.getEndDateTime();
            obj.getLineItemId();
            obj.getLineDesc();
            obj.getQuantity();
            obj.getFCQty();
            obj.getFCAdServedEvery();
            obj.getFCPeriodDart6();
            obj.getIncludeGeography();
            obj.getIncludeDevice();
            obj.getFrequencyCappings();
            obj.getIncludeConnection();
            obj.getAdOpsComments();
            obj.getIncludeDartSite();
            obj.getIncludeDartZone();
            obj.getListContentsTargeting();
            obj.getPredefinedAdunit();
            obj.getIncludePlacementTarget();
            obj.getKeyWKV();
            obj.getLineItemType();
            obj.getListAdSlotWH();
            obj.getBillingCat();
            obj.getDartProductType();
            obj.getDartCompanionSize();
            obj.setAvailableUnits('test');
            obj.getAvailableUnits();
            obj.setMatchingUnits('test');
            obj.getMatchingUnits();
            obj.getToSubtract(10);
            obj.getQuantityMultiplier();
            obj.getAvailableImpressions();
            obj.getAvailableMatchingImpressions();
            obj.getShareOfVoice();
            obj.getRate();
            obj.getCurrencyCode();
            obj.getPriority();
            obj.getName();
            
            adProd = (Ad_Product__c)QueryUtil.queryRecord(adProd.Id, DFPController.DFP_ADPROD_ADDITIONAL_FIELD);
            DARTObject.DARTForecast obj1 = new DARTObject.DARTForecast(adProd);
            obj1.getProductName();

        Test.stopTest();

    }

    @isTest
    static void test_DTOTimeTargeting() {

        setUpData();

        Test.startTest();

            DARTObject.DTOTimeTargeting obj = new DARTObject.DTOTimeTargeting('monday', '0:00 - 0:59');
            
        Test.stopTest();
    }

    @isTest
    static void test_DARTDelivery() {

        setUpData();

        Test.startTest();

            DARTObject.DARTDelivery obj = new DARTObject.DARTDelivery();
            
            Map<object,object> mTemp = new Map<object, object>{
                'AdDeliveredLifetime' => 10,
                'ImpressionsDelivered' => 10,
                'AdClickedLifetime' => 10,
                'ClicksDelivered' => 10,
                'AdOSI' => 10,
                'AdId' => '12345',
                'CampaignId' => '12345',
                'testCol' => 'testVal',
                'dateormonth' => 'testMonth',
                'AdActiveViewViewableImpression' => 10,
                'AdActiveViewMeasurableImpression' => 10,
                'AdActiveViewViewableImpressionRate' => 10
            };

            obj = new DARTObject.DARTDelivery(mTemp);

            obj.getAdDelivered();
            obj.getImpressionsDelivered();
            obj.getAdClickedLifetime();
            obj.getClicksDelivered();
            obj.getAdOSI();
            obj.getAdId();
            obj.getOrderId();
            obj.getValue('testCol');
            obj.getDateString();
            obj.getAdActiveViewViewableImpression();
            obj.getAdActiveViewMeasurableImpression();
            obj.getAdActiveViewViewableImpressionRate();

        Test.stopTest();
    }

    @isTest
    static void test_DARTAdxImport() {

        setUpData();

        Test.startTest();

            DARTObject.DARTAdxImport obj = new DARTObject.DARTAdxImport();

            Map<object,object> mTemp = new Map<object, object>{
                'AdxImpression' => '200,00',
                'AdxClick'      => '200,00',
                'AdxRevenue'    => '500',
                'AdId'          => '12345',
                'CampaignId'    => '12345',
                'testColumn'    => 'testValue',
                'dateormonth'   => 'testMonth'    
            };

            obj = new DARTObject.DARTAdxImport(mTemp);

            obj.getAdxImpression();
            obj.getAdxClick();
            obj.getAdxRevenue();
            obj.getAdId();
            obj.getOrderId();
            obj.getValue('testColumn');
            obj.getDateString();
            
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

            Targeting__c tg = new Targeting__c(Description__c='test');
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

    }

    public class DummyClass extends DARTObject.AbstractDARTController {}

}