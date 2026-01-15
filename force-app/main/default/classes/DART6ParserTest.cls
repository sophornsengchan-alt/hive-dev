@Istest
private  class DART6ParserTest {

    @IsTest
    static void testParser(){

        Site__c site = new Site__c(Name='US', Country__c='US');
        insert site;

        Test.startTest();

        Account account = TST_DataGenerator.generateAccount();
        insert account;

        Opportunity opp1 = TST_DataGenerator.generateOpp(account.Id);
        insert opp1;

        Quote q1 = TST_DataGenerator.generateQuote(opp1.Id);
        insert q1;

        AdServer_Login__c login1 =  TST_DataGenerator.generateAdServerLogin();
        insert login1;
        Product2 product1= TST_DataGenerator.generateProduct(site.Id);
        insert product1;

        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(product1.Id, Test.getStandardPriceBookId());
        insert pbe;

        QuoteLineItem qitem1 = TST_DataGenerator.generateQuoteLinItem(q1.Id, product1.Id, pbe.Id);        
        insert qitem1;
                
        

        //1,DFPResponseToCompanyParser
            DART6_COMPANYSERVICE.Company com1 = new DART6_COMPANYSERVICE.Company();
            com1.id = 123456L;
            com1.name = 'test comp';
            List<DART6_COMPANYSERVICE.Company> listCom = new List<DART6_COMPANYSERVICE.Company>{com1};
        

            DART6Parser.DFPResponseToCompanyParser p_company = new DART6Parser.DFPResponseToCompanyParser(account);
            p_company.setObjectDFP(listCom);
            p_company.parse();
            p_company.getListDartObject();


        //2, DFPResponseToOrderParser        
            DART6_ORDERSERVICE.Order order1 = new DART6_ORDERSERVICE.Order();
            order1.id = 123456;
            order1.name = 'test order1';
            DART6Parser.DFPResponseToOrderParser p_Order = new DART6Parser.DFPResponseToOrderParser(q1,login1);
            p_Order.setObjectDFP(order1);
            p_Order.parse();
            p_Order.getListDartObject();

        //3, DFPResponseToSalespersonParser
            DART6_USERSERVICE.User_x user1 = new DART6_USERSERVICE.User_x();
            user1.id = 33333;
            user1.name = 'test';
            user1.email = 'test@test.com';
            List<DART6_USERSERVICE.User_x> listUser = new List<DART6_USERSERVICE.User_x>{user1};
            DART6Parser.DFPResponseToSalespersonParser p_SalePerson = new DART6Parser.DFPResponseToSalespersonParser();
            p_SalePerson.setObjectDFP(listUser);
            p_SalePerson.parse();
            p_SalePerson.getListDartObject();
        
        //4, DFPResponseToAdsParser
            DART6_LINEITEMSERVICE.LineItem dfpItem1 = new DART6_LINEITEMSERVICE.LineItem();
            dfpItem1.id = 9056470;
            Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
            DART6Parser.DFPResponseToAdsParser p_Ads = new DART6Parser.DFPResponseToAdsParser(qitem1,login1,mapAdvertiser);
            p_Ads.setObjectDFP(dfpItem1);
            p_Ads.parse();
            p_Ads.getListDartObject();

        //5, DFPResponseToForecastParser
            DART6_FORECASTSERVICE.AvailabilityForecast forecast = new DART6_FORECASTSERVICE.AvailabilityForecast();
            forecast.orderId = order1.id;
            forecast.lineItemId = dfpItem1.id;

            DART6Parser.DFPResponseToForecastParser p_Forecast = new DART6Parser.DFPResponseToForecastParser(qitem1);
            p_Forecast.setObjectDFP(forecast);
            p_Forecast.parse();
            p_Forecast.getListDartObject();


        //6, CSV6ToDeliverParser         
        DART6Parser.CSV6ToDeliverParser csvP1 = new DART6Parser.CSV6ToDeliverParser(DeliveryController.SOBJECT_AD_PRODUCT);
        csvP1.setObjectDFP(DARTMockUp.DART6_IMPORTDELIVERY_RES_MOCK);
        csvP1.parse();
        csvP1.getListDartObject();

        DART6Parser.CSV6ToDeliverParser csvP2 = new DART6Parser.CSV6ToDeliverParser(DeliveryController.SOBJECT_AD_REV_DAILY);
        //csvP2.setObjectDFP();
        //csvP2.parse();

        DART6Parser.CSV6ToDeliverParser csvP3 = new DART6Parser.CSV6ToDeliverParser(DeliveryController.SOBJECT_AD_REV_MONTHLY);
        //csvP3.setObjectDFP();
        //csvP3.parse();
        

        Test.stopTest();
        
    }
     
}