/*****************************************************************************************************************************
@ Class:       FactoryParserTest
@ Author:      Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:     US-0008380 test class for FactoryParser
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  15.09.2021 / Mony Nou / Created the method.
@*****************************************************************************************************************************/
@IsTest 
private class FactoryParserTest {
    
    @isTest
    static void test_getInstance() {

        Test.startTest();

            FactoryParser res = FactoryParser.getInstance();

            System.assert(res != null);

        Test.stopTest();

    }

    @isTest 
    static void test_createAdvertiserParser() {

        Test.startTest();
            
            setUpData();
            
            DART6Parser.IDARTParser res_1 = FactoryParser.getInstance().createAdvertiserParser(acc, 'DART6');

            DART6Parser.IDARTParser res_2 = FactoryParser.getInstance().createAdvertiserParser(acc, 'TEST');

        Test.stopTest();        
    }

    @isTest 
    static void test_createOrderParser() {

        Test.startTest();
            
            setUpData();

            Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
            
            DART6Parser.IDARTParser res_1 = FactoryParser.getInstance().createOrderParser(adServer, 'DART6', acc);
            DART6Parser.IDARTParser res_2 = FactoryParser.getInstance().createOrderParser(adServer, 'TEST', acc);

        Test.stopTest(); 
    }

    @isTest 
    static void test_createSalespersonParser() {

        Test.startTest();
            
            setUpData();

            Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
            
            DART6Parser.IDARTParser res_1 = FactoryParser.getInstance().createSalespersonParser('DART6');
            DART6Parser.IDARTParser res_2 = FactoryParser.getInstance().createSalespersonParser('TEST');

        Test.stopTest(); 
    }

    @isTest 
    static void test_createAdsParser() {

        Test.startTest();
            
            setUpData();

            Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
            
            DART6Parser.IDARTParser res_1 = FactoryParser.getInstance().createAdsParser(adServer, 'DART6', acc, mapAdvertiser);
            DART6Parser.IDARTParser res_2 = FactoryParser.getInstance().createAdsParser(adServer, 'TEST', acc, mapAdvertiser);

        Test.stopTest(); 
    }

    @isTest 
    static void test_createForecastParser() {

        Test.startTest();
            
            setUpData();

            Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
            
            DART6Parser.IDARTParser res_1 = FactoryParser.getInstance().createForecastParser('DART6', acc);
            DART6Parser.IDARTParser res_2 = FactoryParser.getInstance().createForecastParser('TEST', acc);

        Test.stopTest(); 
    }

    @isTest 
    static void test_createDeliveryParser_EU() {

        Test.startTest();
            
            setUpData();

            Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
            
            DART6Parser.IDARTParser res_1 = FactoryParser.getInstance().createDeliveryParser_EU('DART6', 'Quote');
            DART6Parser.IDARTParser res_2 = FactoryParser.getInstance().createDeliveryParser_EU('TEST', 'Quote');

        Test.stopTest(); 
    }

    //////// STATIC TEST RECORDS //////////
    static Account acc;
    static AdServer_Login__c adServer;

    private static void setUpData(){

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
    }

}