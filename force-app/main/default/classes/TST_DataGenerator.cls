/**
 * Author : Gaeasys
 * CreatedDate: 31-May-2018
 * Description:
 */
public with sharing class TST_DataGenerator {

    public static Set<String> dataSet = new Set<String>{'Account', 'Opportunity', 'Quote', 'QuoteLineItem'};

    private static RecordType rtAdvertiser = [SELECT id FROM recordType WHERE name = 'Advertiser' AND sobjectType = 'Account'];

    public static Account generateAccount(){
    	return new Account(
    		Name = 'Account test',
    		BillingStreet = 'Goethestrasse 97',
            BillingPostalCode = '19053',
            BillingCity = 'Schwerin',
            BillingState = 'Berlin',
            BillingCountry = 'Germany',
            Phone = '+1234567890',
            recordTypeid = rtAdvertiser.id,
            Record_Type_Text__c = 'Advertiser'
		);
    }

    public static Opportunity generateOpp(Id accId){
    	return new Opportunity(
    		Name = 'Opp test',
    		CloseDate = Date.today() + 90,
    		AccountId = accId,
            StageName = 'Qualification'
    		);
    }

    // Remove by Acmatac, January 17, 2021, We're stop using Media Plan
    // public static Media_Plan__c generateMediaPlan(Opportunity opp){
    //     return GW_Opportunity.convertOppToMediaPlan(opp);
    // }

    public static Quote generateQuote(Id oppId, Id mediaPlanId ){
    	return new Quote(
    		Name = 'Quote Test',
    		OpportunityId = oppId,
    		Media_Plan__c = mediaPlanId,
            Pricebook2Id=Test.getStandardPriceBookId()
    		);
    }

    public static Quote generateQuote(Id oppId){
    	return new Quote(
    		Name = 'Quote Test',
    		OpportunityId = oppId,
            Pricebook2Id=Test.getStandardPriceBookId()
    		);
    }

    public static AdServer_Login__c generateAdServerLogin(){
      return new AdServer_Login__c(
        Name = 'Test',
        Refresh_Token__c = 'xxxxxx',
        Client_Id__c = 'xxxxxx',
        Network_ID__c = 'Test',
        Active__c = true,
        Client_Secret__c = 'xxxxx'
        );
    }

    public static Product2 generateProduct(){
        return generateProduct(null);
    }

    public static Product2 generateProduct(Id siteId){
      return new Product2(
            Name = 'Product Test',
            Site__c = siteId
            );
    }

    public static Site__c generateSite(){
      return new Site__c(Name='Test', Country__c='Test');
    }

    public static PriceBookEntry generatePricebookEntry(Id prodId, Id pbId){
        return new PriceBookEntry(
            Product2Id = prodId,
            IsActive = true,
            UnitPrice = 10,
            Pricebook2Id = pbId !=null ? pbId : Test.getStandardPriceBookId()
            );
    }

    public static QuoteLineItem generateQuoteLinItem(Id quoteId, Id prodId, Id pbeId){
        return new QuoteLineItem(
            from_Date__c =  date.newInstance(System.now().year(), System.now().month(), 1),
            until_Date__c = date.newInstance(System.now().year(), System.now().month(), 30),  
            Product2Id = prodId,
            UnitPrice = 10,
            Quantity = 10,
            Quantity__c = 10,
            Keywords_KeyValue_combination__c = 'AND',
            Check_Inventory__c = true,
            PricebookEntryId = pbeId,
            QuoteId = quoteId
            );
    }

    public static OpportunityLineItem generateOpportunityLinItem(Id oppId, Id pbId, Id targetId){
        return new OpportunityLineItem( 
                                  OpportunityId= oppId,
                                  from_Date__c =  date.newInstance(System.now().year(), System.now().month(), 1),
                                  until_Date__c = date.newInstance(System.now().year(), System.now().month(), 30),
                                  Quantity =  200,
                                  Billing_category__c='CPM',
                                  Description='Test Desc',
                                  Check_Inventory__c=true,
                                  AdDayOfWeek__c='Monday;Sunday',
                                  AdHourOfDay__c='12:00 - 12:59;23:00 - 23:59',
                                  AdWebBrowsers__c='Mozilla',
                                  AdOperatingSystems__c='Macintosh',
                                  FC_Ad_served_every__c=5,
                                  FC_Quantity__c=100,
                                  TotalPrice = 400,
                                  FC_Period__c='Days',
                                  PricebookEntryId=pbId,
                                  Targeting__c=targetId,
                                  Ad_Name__c = 'LineItemTest',
                                  SalesPriceNet__c = 10 ,
                                  Device_Targeting__c='Test1,Test2,Test3',
                                  UniqueLineDescription__c = 'TestUniqueLineDescription'
                                  );
    }

    public static Targeting__c generateTargeting(){
    		Targeting__c tg = new Targeting__c(Description__c='test');
    		insert tg;
      	return tg;
    }

    public static Targeting__c createTargetingObject(){
        Targeting__c tg =  generateTargeting();
        Devices__c dev1 = new Devices__c(Name = 'Test1', Dart_ID__c=123456, DFP_API_Name__c='DeviceManufacturer');
        insert dev1;
        Connection__c conn1 = new Connection__c(Name = 'Test1', Dart_ID__c=123456, DFP_API_Name__c='BandwidthGroup');
        Connection__c conn2 = new Connection__c(Name = 'Test3', Dart_ID__c=111111, DFP_API_Name__c='MobileCarrier');
        insert new Connection__c[]{conn1, conn2};
        Geography__c geo1 = new Geography__c(Name = 'Test1', Dart_ID__c=123456, Type__c = 'COUNTRY');
        Geography__c geo2 = new Geography__c(Name = 'Test2', Dart_ID__c=888888, Type__c = 'CITY', Node_ID__c=geo1.Id);
        insert new Geography__c[]{geo1,geo2};
        Placement__c plc = new Placement__c(Name='test placement', Dart_ID__c=11111);
        insert plc;
        TargetingDeviceAssociation__c devAssoc = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev', Targeting__c=tg.Id, Device__c = dev1.id);
        TargetingConnectionAssociation__c connAssoc = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn', Targeting__c=tg.Id, Connection__c = conn2.id);
        TargetingGeographyAssociation__c geoAssoc = new TargetingGeographyAssociation__c(TargetGeography__c='TestGeo', Targeting__c=tg.Id, Geography__c = geo2.id);
        insert devAssoc;
        insert connAssoc;
        insert geoAssoc;
        return tg;
    }

    public static Map<String, List<sObject>> setupSimpleData(Set<String> dataSetConfig){
        Map<String, List<sObject>> configuredData = new Map<String, List<sObject>>();
        if (dataSetConfig.contains('Account')){
            Account acc = generateAccount();
            insert acc;
            configuredData.put('Account', new Account[]{acc});

            if(dataSetConfig.contains('Opportunity')){

                Opportunity opp = generateOpp(acc.id);
                insert opp;
                configuredData.put('Opportunity', new Opportunity[]{opp});

                if(dataSetConfig.contains('Quote') || dataSetConfig.contains('IO')){
                    Quote q = generateQuote(opp.id, opp.Media_Plan__c);
                    insert q;
                    configuredData.put('Quote', new Quote[]{q});

                    // We're stop using IO?, Acmatac SEING Jan/17/2021
                    // IO__c io = GW_IO.convertQuoteToIO(q, false);
                    // if(dataSetConfig.contains('IO__c')){
                    //     insert io;
                    //     configuredData.put('IO__c', new IO__c[]{io});
                    // }

                    if(dataSetConfig.contains('QuoteLineItem') || dataSetConfig.contains('IO_LineItem__c') ){
                        Site__c site = generateSite();
                        insert site;
                        Product2 prod = generateProduct(site.Id);
                        insert prod;
                        PriceBookEntry pbe =generatePricebookEntry(prod.id, null);
                        insert pbe;
                        QuoteLineItem qli = generateQuoteLinItem( q.id, prod.id, pbe.id);
                        
                        Targeting__c tg;
                        if(dataSetConfig.contains('Targeting__c')){
                            tg =createTargetingObject();
                            qli.Targeting__c = tg.Id;    
                            configuredData.put('Targeting__c', new Targeting__c[]{tg});
                        }

                        insert qli;
                        configuredData.put('QuoteLineItem', new QuoteLineItem[]{qli});

                        // We're stop using IO?, Acmatac SEING Jan/17/2021
                        // if(dataSetConfig.contains('IO_LineItem__c')){
                        //     IO_LineItem__c IOLine =GW_IO.convertQuoteLIToIOLineItem( qli,  false);
                        //     IOLine.IO__c = io.Id;
                        //     if(dataSetConfig.contains('Targeting__c')){
                        //         IOLine.Targeting__c = tg.id;
                        //     }
                        //     insert IOLine;
                        //     configuredData.put('IO_LineItem__c', new IO_LineItem__c[]{IOLine});
                        // } 

                    }
                }
            }
        }

        return configuredData;
    }

    public static Map<String, List<sObject>> setUpTargetingData(){
        return setupSimpleData( new Set<String>{'Account', 'Opportunity', 'Quote', 'QuoteLineItem','IO__c','IO_LineItem__c','Targeting__c'});
    }

}