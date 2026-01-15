/*********************************************************************************************************************************
@ Class:          AdProductTriggerHandlerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Test class for AdProductTrigger Trigger and class AdProductTriggerHandler
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  17.08.2020 / Sophal Noch / Created the  class.
*********************************************************************************************************************************/
@isTest
private class AdProductTriggerHandlerTest {

    private static Account seller;
    private static Opportunity opp;
    private static Map<Id,List <Ad_Revenue_Monthly__c>> adMonthlyMap;
    private static Map<Id,List <Ad_Revenue_Daily__c>> adDailyMap;


    private static Account account;
    private static  IO__c io;
    private static Opportunity opp1;


    private static Date startDate;
    private static Date endDate;

    private static Quote quote1;

    private static Site__c site;
    private static Product2 prod1;

    private static Id book1Id;

    private static PriceBookEntry pbe1;

    private static QuoteLineItem qli1;
    private static QuoteLineItem qli2;
    private static QuoteLineItem qli3;

    private static Integer offSet5Days = 5;

    private static RecordType rtAdvertiser = [SELECT id FROM recordType WHERE name = 'Advertiser' AND sobjectType = 'Account'];

    private static byPass__c bp;

    // setup method
    private static Account generateAccount(){
    	return new Account(
    		Name = 'Account test',
    		BillingStreet = 'Goethestrasse 97',
            BillingPostalCode = '19053',
            BillingCity = 'Schwerin',
            BillingState = 'Berlin',
            BillingCountry = 'Germany',
            Phone = '+1234567890',
            recordTypeid = rtAdvertiser.id
		);
    }

    // setup method
    private static Site__c generateSite(){
        return new Site__c(Name='Test', Country__c='Test');
    }

    private static Product2 generateProduct(Id siteId){
        return new Product2(
              Name = 'Product Test',
              Site__c = siteId
              );
    }

    // setup method
    private static PriceBookEntry generatePricebookEntry(Id prodId, Id pbId){
        return new PriceBookEntry(
            Product2Id = prodId,
            IsActive = true,
            UnitPrice = 10,
            Pricebook2Id = pbId !=null ? pbId : Test.getStandardPriceBookId()
            );
    }

    // setup method
    private static QuoteLineItem generateQuoteLinItem(Id quoteId, Id prodId, Id pbeId){
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

    
    // setup method
    static void setUpData(){

        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false, byPass_WFRule__c = false);
        insert bp;

        account = generateAccount();
        account.Record_Type_Text__c = 'Advertiser';//avoid validation rule error
        insert account;

        opp = new Opportunity(AccountId = account.Id, Name = 'Test Opp',StageName='Qualified Meeting',CloseDate=Date.newInstance( 2021, 1, 1),RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id);
        insert opp;
    }

    // setup method
    private static void setUpData2(){

        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false, ByPass_Validation__c=true);
        bp.byPass_WFRule__c = true;
        insert bp;

        account = generateAccount();
        insert account;

        Account agency = generateAccount();
        agency.RecordTypeId = ApexUtil.getRecordTypeByName('Account','Agency').Id;
        insert agency;

        startDate = Date.today().toStartOfMonth().addMonths(-1);
        endDate = startDate.addMonths(2).toStartOfMonth().addDays(10); // 1 + 10 = 11

        io = new IO__c(DS_Approved__c = true,Dually_Signed_IO__c=true);
        insert io;
        opp1 = new Opportunity(
                Name = 'Opp 1',
                Amount = 100,
                StageName = 'Closed Won',
                CloseDate = Date.today().addYears(1),
                Start_Date__c = startDate,
                End_Date__c = endDate,
                IO__c = io.Id,
                Quote_Sync_In_Progress__c = true,
                AccountId = account.Id,
                Agency__c = agency.Id
        );

        insert opp1;


        site = generateSite();
        insert site;

        prod1 = generateProduct(site.Id);
        insert prod1;

        book1Id = Test.getStandardPriceBookId();
        
        pbe1 = generatePricebookEntry(prod1.id, book1Id);
        insert pbe1;

        quote1 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp1.Id, Pricebook2Id = book1Id, Is_Revised_Quote__c = false);
        
        insert quote1;

        System.debug('nsp: select quote1 == '+[Select id,name,Pricebook2.Name From Quote Where id =: quote1.Id]);

        quote1.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote1.Primary_Quote__c = false;
        update quote1;

        List<Ad_Product__c> listAdProdToDel = [Select Id from Ad_Product__c];
        delete listAdProdToDel;

        Decimal qli1ToAdProd1 = 100;

        Decimal qli2ToAdProd2 = 200;

        Decimal qli3ToAdProd3 = 300;

        qli1 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = qli1ToAdProd1;
        qli1.from_Date__c = startDate;
        qli1.until_Date__c = endDate;


        qli2 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli2.Budget__c = qli2ToAdProd2;
        qli2.from_Date__c = startDate;
        qli2.until_Date__c = endDate;


        qli3 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli3.Budget__c = qli3ToAdProd3;
        qli3.from_Date__c = startDate.addDays(offSet5Days);
        qli3.until_Date__c = endDate;

        insert new List<QuoteLineItem>{qli1, qli2, qli3};


        Ad_Product__c adProd1 = new Ad_Product__c(
            TotalPrice__c = qli1ToAdProd1,
            from_Date__c = startDate,
            until_Date__c = endDate,
            Opportunity__c = opp1.Id,
            Quantity__c = 3
        );

        Ad_Product__c adProd2 = new Ad_Product__c(
            TotalPrice__c = qli2ToAdProd2,
            from_Date__c = startDate,
            until_Date__c = endDate,
            Opportunity__c = opp1.Id,
            Quantity__c = 3
        );

        Ad_Product__c adProd3 = new Ad_Product__c(
            TotalPrice__c = qli3ToAdProd3,
            from_Date__c = startDate.addDays(offSet5Days),
            until_Date__c = endDate,
            Opportunity__c = opp1.Id,
            Quantity__c = 3
        );

        insert new List<Ad_Product__c>{adProd1, adProd2, adProd3};

        qli1.AdProduct__c = adProd1.Id;
        qli2.AdProduct__c = adProd2.Id;
        qli3.AdProduct__c = adProd3.Id;

        update new List<QuoteLineItem>{qli1, qli2,qli3};


    }

    // setup method
    static void setUpData3(){


        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false, byPass_WFRule__c = false);
        insert bp;

        AdRevenueDailyTriggerHandler.runAsFuture = false;

        account = generateAccount();
        account.Record_Type_Text__c = 'Advertiser';//avoid validation rule error
        insert account;

        opp = new Opportunity(AccountId = account.Id, Name = 'Test Opp',StageName='Qualified Meeting',CloseDate=Date.newInstance( 2021, 1, 1),RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id);
        insert opp;

        site = generateSite();
        insert site;

        prod1 = generateProduct(site.Id);
        insert prod1;

        book1Id = Test.getStandardPriceBookId();
        
        pbe1 = generatePricebookEntry(prod1.id, book1Id);
        insert pbe1;

        quote1 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp.Id, Pricebook2Id = book1Id, Is_Revised_Quote__c = false, Primary_Quote__c = true);

        insert quote1;

        quote1.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote1.Primary_Quote__c= true;
        update quote1;
        

        qli1 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = 100;
        qli1.from_Date__c = Date.today().addMonths(-1);
        qli1.until_Date__c = Date.today().addMonths(1);
        insert qli1;
        
    }

    // setup method
    static void setUpAdRevenueMonthlyAndAdRevenueDailyMap(){

        List <Ad_Revenue_Monthly__c> adMonthly = [SELECT Id, Amount__c,Ad_Product__c,Opportunity__c,Transaction_Date__c,Unique_Key__c FROM Ad_Revenue_Monthly__c Order by Transaction_Date__c Asc];
        
        
        adMonthlyMap = new Map<Id,List <Ad_Revenue_Monthly__c>>();

        for(Ad_Revenue_Monthly__c eachMonth : adMonthly){
            if(adMonthlyMap.containsKey(eachMonth.Ad_Product__c)){
                adMonthlyMap.get(eachMonth.Ad_Product__c).add(eachMonth);
            }else{
                adMonthlyMap.put(eachMonth.Ad_Product__c, new List<Ad_Revenue_Monthly__c>{eachMonth});
            }
        }


        adDailyMap = new Map<Id,List <Ad_Revenue_Daily__c>>();

        List <Ad_Revenue_Daily__c> adDaily = [SELECT Id, Ad_Revenue_Monthly__c,Amount__c,Ad_Product__c,Transaction_Date__c,Unique_Key__c FROM Ad_Revenue_Daily__c Order by Transaction_Date__c Asc];

        for(Ad_Revenue_Daily__c eachDaily : adDaily){
            if(adDailyMap.containsKey(eachDaily.Ad_Revenue_Monthly__c)){
                adDailyMap.get(eachDaily.Ad_Revenue_Monthly__c).add(eachDaily);
            }else{
                adDailyMap.put(eachDaily.Ad_Revenue_Monthly__c, new List<Ad_Revenue_Daily__c>{eachDaily});
            }
        }


    }

    /*****************************************************************************************************************************
    @ Method:       testCreateAndUpdateAdProducts
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      test method for story US-0007980
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  17.08.2020 / Sophal Noch / Created the  method.
    @*****************************************************************************************************************************/
    static testMethod void testCreateAndUpdateAdProducts() {

        setUpData();

        Date currentDate = Date.today();
        Integer nextYear = currentDate.year();

        Decimal adProduct1TotalPrice = 400;
        Date adProduct1StartDate = Date.newInstance( nextYear, 3, 4);
        Date adProduct1EndDate = Date.newInstance( nextYear, 6, 5);

        Ad_Product__c adProduct1 = new Ad_Product__c(
            Opportunity__c = opp.Id, 
            TotalPrice__c= adProduct1TotalPrice,
            from_Date__c = adProduct1StartDate,
            until_Date__c = adProduct1EndDate,
            Quantity__c = 4
        );


        Decimal adProduct2TotalPrice = 500;
        Date adProduct2StartDate = Date.newInstance( nextYear, 2, 3);
        Date adProduct2EndDate = Date.newInstance( nextYear, 3, 4);

        Ad_Product__c adProduct2 = new Ad_Product__c(
            Opportunity__c = opp.Id, 
            TotalPrice__c= adProduct2TotalPrice,
            from_Date__c = adProduct2StartDate,
            until_Date__c = adProduct2EndDate,
            Quantity__c = 2
        );

        Integer lastIndexOfMonthlyMapOfEachAdProduct = 0;
        Integer lastIndexOfDailyMapOfEachMonth = 0;
       
        

       insert new List<Ad_Product__c>{adProduct1,adProduct2};
        
        setUpAdRevenueMonthlyAndAdRevenueDailyMap();
        System.assert(adMonthlyMap.size() > 0);
        System.assert(adDailyMap.size() > 0);
        /* Test after insert : start here */

            /* test for adProduct1 : start here */
  
        System.assertEquals(4, adMonthlyMap.get(adProduct1.Id).size());

        System.assertEquals(adProduct1StartDate.toStartOfMonth(), adMonthlyMap.get(adProduct1.Id)[0].Transaction_Date__c);
        System.assertEquals(adProduct1StartDate.addMonths(1).toStartOfMonth(), adMonthlyMap.get(adProduct1.Id)[1].Transaction_Date__c);
        System.assertEquals(adProduct1StartDate.addMonths(2).toStartOfMonth(), adMonthlyMap.get(adProduct1.Id)[2].Transaction_Date__c);
        System.assertEquals(adProduct1StartDate.addMonths(3).toStartOfMonth(), adMonthlyMap.get(adProduct1.Id)[3].Transaction_Date__c);

                // test with first month

        Ad_Revenue_Monthly__c adProduct1FirstMonth = adMonthlyMap.get(adProduct1.Id)[0];
        System.assertNotEquals(null,adProduct1FirstMonth);
        System.assertEquals(true,adDailyMap.containsKey(adProduct1FirstMonth.Id));


        Decimal dayAmountOfAdProduct1 = adProduct1.TotalPrice__c / (adProduct1.from_Date__c.daysBetween(adProduct1.until_Date__c) + 1);
        Integer daysInFirstMonthOfAdProduct1 = Date.daysInMonth( adProduct1.from_Date__C.year(),  adProduct1.from_Date__C.month());
        Date endOfFirstMonthOfAdProduct1 = Date.newInstance( adProduct1.from_Date__C.year(),  adProduct1.from_Date__C.month(), daysInFirstMonthOfAdProduct1);

        Decimal amountOfProduct1FirstMonth = dayAmountOfAdProduct1 * (adProduct1.from_Date__C.daysBetween(endOfFirstMonthOfAdProduct1) + 1 );
        System.assertEquals(amountOfProduct1FirstMonth,adProduct1FirstMonth.Amount__c);

                // test with first day of first month
        Ad_Revenue_Daily__c adProduct1StartDateOfFirstMonthFirstDay = adDailyMap.get(adProduct1FirstMonth.Id)[0];
        System.assertEquals(adProduct1.from_Date__c, adProduct1StartDateOfFirstMonthFirstDay.Transaction_Date__c);
            
                // test with last month
        lastIndexOfMonthlyMapOfEachAdProduct = adMonthlyMap.get(adProduct1.Id).size() - 1;
        Ad_Revenue_Monthly__c adProduct1LastMonth = adMonthlyMap.get(adProduct1.Id)[lastIndexOfMonthlyMapOfEachAdProduct];
        System.assertNotEquals(null,adProduct1LastMonth);
        System.assertEquals(true,adDailyMap.containsKey(adProduct1LastMonth.Id));
        
                // test with last day of last month
        lastIndexOfDailyMapOfEachMonth = adDailyMap.get(adProduct1LastMonth.Id).size() - 1;
        Ad_Revenue_Daily__c adProduct1EndDateOfLastMonthLastDay = adDailyMap.get(adProduct1LastMonth.Id)[lastIndexOfDailyMapOfEachMonth];
        System.assertEquals(adProduct1.until_Date__c, adProduct1EndDateOfLastMonthLastDay.Transaction_Date__c);
        System.assertEquals(dayAmountOfAdProduct1, adProduct1EndDateOfLastMonthLastDay.Amount__c);
            /* test for adProduct1 : end here */

            /* test for adProduct2 : start here */

        System.assertEquals(2, adMonthlyMap.get(adProduct2.Id).size());

        System.assertEquals(adProduct2StartDate.toStartOfMonth(), adMonthlyMap.get(adProduct2.Id)[0].Transaction_Date__c);
        System.assertEquals(adProduct2StartDate.addMonths(1).toStartOfMonth(), adMonthlyMap.get(adProduct2.Id)[1].Transaction_Date__c);
                
                // test with first month
        Ad_Revenue_Monthly__c adProduct2FirstMonth = adMonthlyMap.get(adProduct2.Id)[0];
        System.assertNotEquals(null,adProduct2FirstMonth);
        System.assertEquals(true,adDailyMap.containsKey(adProduct2FirstMonth.Id));
        
        Decimal dayAmountOfAdProduct2 = adProduct2.TotalPrice__c / (adProduct2.from_Date__c.daysBetween(adProduct2.until_Date__c) + 1);
        Integer daysInFirstMonthOfAdProduct2 = Date.daysInMonth( adProduct2.from_Date__C.year(),  adProduct2.from_Date__C.month());
        Date endOfFirstMonthOfAdProduct2 = Date.newInstance( adProduct2.from_Date__C.year(),  adProduct2.from_Date__C.month(), daysInFirstMonthOfAdProduct2);

        Decimal amountOfProduct2FirstMonth = dayAmountOfAdProduct2 * (adProduct2.from_Date__C.daysBetween(endOfFirstMonthOfAdProduct2) + 1 );
        System.assertEquals(amountOfProduct2FirstMonth,adProduct2FirstMonth.Amount__c);

                // test with first day of first month
        Ad_Revenue_Daily__c adProduct2StartDateOfFirstMonthFirstDay = adDailyMap.get(adProduct2FirstMonth.Id)[0];
        System.assertEquals(adProduct2.from_Date__c, adProduct2StartDateOfFirstMonthFirstDay.Transaction_Date__c);
                
                // test with last month
        lastIndexOfMonthlyMapOfEachAdProduct = adMonthlyMap.get(adProduct2.Id).size() - 1;
        Ad_Revenue_Monthly__c adProduct2LastMonth = adMonthlyMap.get(adProduct2.Id)[lastIndexOfMonthlyMapOfEachAdProduct];
        System.assertNotEquals(null,adProduct2LastMonth);
        System.assertEquals(true,adDailyMap.containsKey(adProduct2LastMonth.Id));
                
                // test with last day of last month
        lastIndexOfDailyMapOfEachMonth = adDailyMap.get(adProduct2LastMonth.Id).size() - 1;
        Ad_Revenue_Daily__c adProduct2EndDateOfLastMonthLastDay = adDailyMap.get(adProduct2LastMonth.Id)[lastIndexOfDailyMapOfEachMonth];
        System.assertEquals(adProduct2.until_Date__c, adProduct2EndDateOfLastMonthLastDay.Transaction_Date__c);
        System.assertEquals(dayAmountOfAdProduct2, adProduct2EndDateOfLastMonthLastDay.Amount__c);
            /* test for adProduct2 : end here */


        /* Test after insert : end here */




        /* Test after update : start here */
        adProduct1StartDate = Date.newInstance( nextYear, 6, 7);
        adProduct1EndDate = Date.newInstance( nextYear, 7, 8);

        adProduct1.from_Date__c = adProduct1StartDate;
        adProduct1.until_Date__c = adProduct1EndDate;
        adProduct1.Quantity__c = 2;


        adProduct2StartDate = Date.newInstance( nextYear, 1, 2);
        adProduct2EndDate = Date.newInstance( nextYear, 5, 6);

        adProduct2.from_Date__c = adProduct2StartDate;
        adProduct2.until_Date__c = adProduct2EndDate;
        adProduct2.Quantity__c = 5;

        Test.startTest();
            update new List<Ad_Product__c>{adProduct1,adProduct2};
        Test.stopTest();
        setUpAdRevenueMonthlyAndAdRevenueDailyMap();
        System.assert(adMonthlyMap.size() > 0);
        System.assert(adDailyMap.size() > 0);

            /* test for adProduct1 : start here */
        System.assertEquals(2, adMonthlyMap.get(adProduct1.Id).size());

        System.assertEquals(adProduct1StartDate.toStartOfMonth(), adMonthlyMap.get(adProduct1.Id)[0].Transaction_Date__c);
        System.assertEquals(adProduct1StartDate.addMonths(1).toStartOfMonth(), adMonthlyMap.get(adProduct1.Id)[1].Transaction_Date__c);
                
                // test with first month

        adProduct1FirstMonth = adMonthlyMap.get(adProduct1.Id)[0];
        System.assertNotEquals(null,adProduct1FirstMonth);
        System.assertEquals(true,adDailyMap.containsKey(adProduct1FirstMonth.Id));


        dayAmountOfAdProduct1 = adProduct1.TotalPrice__c / (adProduct1.from_Date__c.daysBetween(adProduct1.until_Date__c) + 1);
        daysInFirstMonthOfAdProduct1 = Date.daysInMonth( adProduct1.from_Date__C.year(),  adProduct1.from_Date__C.month());
        endOfFirstMonthOfAdProduct1 = Date.newInstance( adProduct1.from_Date__C.year(),  adProduct1.from_Date__C.month(), daysInFirstMonthOfAdProduct1);

        amountOfProduct1FirstMonth = dayAmountOfAdProduct1 * (adProduct1.from_Date__C.daysBetween(endOfFirstMonthOfAdProduct1) + 1 );
        System.assertEquals(amountOfProduct1FirstMonth,adProduct1FirstMonth.Amount__c);

                // test with first day of first month

        adProduct1StartDateOfFirstMonthFirstDay = adDailyMap.get(adProduct1FirstMonth.Id)[0];
        System.assertEquals(adProduct1.from_Date__c, adProduct1StartDateOfFirstMonthFirstDay.Transaction_Date__c);

                // test with last month
        lastIndexOfMonthlyMapOfEachAdProduct =  adMonthlyMap.get(adProduct1.Id).size() - 1;
        adProduct1LastMonth = adMonthlyMap.get(adProduct1.Id)[lastIndexOfMonthlyMapOfEachAdProduct];
        System.assertNotEquals(null,adProduct1LastMonth);
        System.assertEquals(true,adDailyMap.containsKey(adProduct1LastMonth.Id));

                // test with last day of last month
        lastIndexOfDailyMapOfEachMonth = adDailyMap.get(adProduct1LastMonth.Id).size() - 1;
        adProduct1EndDateOfLastMonthLastDay = adDailyMap.get(adProduct1LastMonth.Id)[lastIndexOfDailyMapOfEachMonth];
        System.assertEquals(adProduct1.until_Date__c, adProduct1EndDateOfLastMonthLastDay.Transaction_Date__c);
        System.assertEquals(dayAmountOfAdProduct1, adProduct1EndDateOfLastMonthLastDay.Amount__c);
            /* test for adProduct1 : end here */

            /* test for adProduct2 : start here */
        System.assertEquals(5, adMonthlyMap.get(adProduct2.Id).size());

        System.assertEquals(adProduct2StartDate.toStartOfMonth(), adMonthlyMap.get(adProduct2.Id)[0].Transaction_Date__c);
        System.assertEquals(adProduct2StartDate.addMonths(1).toStartOfMonth(), adMonthlyMap.get(adProduct2.Id)[1].Transaction_Date__c);
        System.assertEquals(adProduct2StartDate.addMonths(2).toStartOfMonth(), adMonthlyMap.get(adProduct2.Id)[2].Transaction_Date__c);
        System.assertEquals(adProduct2StartDate.addMonths(3).toStartOfMonth(), adMonthlyMap.get(adProduct2.Id)[3].Transaction_Date__c);
        System.assertEquals(adProduct2StartDate.addMonths(4).toStartOfMonth(), adMonthlyMap.get(adProduct2.Id)[4].Transaction_Date__c);


        adProduct2FirstMonth = adMonthlyMap.get(adProduct2.Id)[0];
        System.assertNotEquals(null,adProduct2FirstMonth);
        System.assertEquals(true,adDailyMap.containsKey(adProduct2FirstMonth.Id));

                // test with first month
        dayAmountOfAdProduct2 = adProduct2.TotalPrice__c / (adProduct2.from_Date__c.daysBetween(adProduct2.until_Date__c) + 1);
        daysInFirstMonthOfAdProduct2 = Date.daysInMonth( adProduct2.from_Date__C.year(),  adProduct2.from_Date__C.month());
        endOfFirstMonthOfAdProduct2 = Date.newInstance( adProduct2.from_Date__C.year(),  adProduct2.from_Date__C.month(), daysInFirstMonthOfAdProduct2);

        amountOfProduct2FirstMonth = dayAmountOfAdProduct2 * (adProduct2.from_Date__C.daysBetween(endOfFirstMonthOfAdProduct2) + 1 );
        System.assertEquals(amountOfProduct2FirstMonth,adProduct2FirstMonth.Amount__c);

                // test with first day of first month
        adProduct2StartDateOfFirstMonthFirstDay = adDailyMap.get(adProduct2FirstMonth.Id)[0];
        System.assertEquals(adProduct2.from_Date__c, adProduct2StartDateOfFirstMonthFirstDay.Transaction_Date__c);

                // test with last month
        lastIndexOfMonthlyMapOfEachAdProduct = adMonthlyMap.get(adProduct2.Id).size() - 1;
        adProduct2LastMonth = adMonthlyMap.get(adProduct2.Id)[lastIndexOfMonthlyMapOfEachAdProduct];
        System.assertNotEquals(null,adProduct2LastMonth);
        System.assertEquals(true,adDailyMap.containsKey(adProduct2LastMonth.Id));
                
                // test with last day of last month
        lastIndexOfDailyMapOfEachMonth = adDailyMap.get(adProduct2LastMonth.Id).size() - 1;
        adProduct2EndDateOfLastMonthLastDay = adDailyMap.get(adProduct2LastMonth.Id)[lastIndexOfDailyMapOfEachMonth];
        System.assertEquals(adProduct2.until_Date__c, adProduct2EndDateOfLastMonthLastDay.Transaction_Date__c);
        System.assertEquals(dayAmountOfAdProduct2, adProduct2EndDateOfLastMonthLastDay.Amount__c);
            /* test for adProduct2 : end here */

            
        /* Test after update : end here */

    }


    /*****************************************************************************************************************************
    @ Method:       testDifferentiateRecordHavingProduct
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      test method for story US-0008007
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  25.08.2020 / Sophal Noch / Created the  method.
    @*****************************************************************************************************************************/
    static testMethod void testDifferentiateRecordHavingProduct(){
        setUpData();

        Ad_Product__c adProduct1 = new Ad_Product__c(
            Opportunity__c = opp.Id, 
            TotalPrice__c= 0,
            Quantity__c = 4
        );


        Ad_Product__c adProduct2 = new Ad_Product__c(
            Opportunity__c = opp.Id, 
            TotalPrice__c= 0,
            Quantity__c = 2
        );

       insert new List<Ad_Product__c>{adProduct1,adProduct2};

       List<Ad_Product__c> listAdProd = [SELECT Id, IsHavingProduct__c From Ad_Product__c WHERE Id =: adProduct1.Id OR Id =: adProduct2.Id];
        
       System.assertEquals(2, listAdProd.size());
       System.assertEquals(false, listAdProd[0].IsHavingProduct__c);
       System.assertEquals(false, listAdProd[1].IsHavingProduct__c);

       Product2 prodForAdProd1 = new Product2(Name ='test prod 1');
       insert prodForAdProd1;

       adProduct1.Product2__c = prodForAdProd1.Id;
       update adProduct1;


       listAdProd = [SELECT Id, IsHavingProduct__c From Ad_Product__c WHERE Id =: adProduct1.Id OR Id =: adProduct2.Id];

       System.assertEquals(2, listAdProd.size());
       System.assertEquals(true, listAdProd[0].IsHavingProduct__c);
       System.assertEquals(false, listAdProd[1].IsHavingProduct__c);


    }


    /*****************************************************************************************************************************
    @ Method:       testUpdateAdProductWhenQuoteIsRevisedAndPrimary
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      test method for story US-0008471
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  29.10.2020 / Sophal Noch / Created the  method.
    @*****************************************************************************************************************************/
    static testMethod void testUpdateAdProductWhenQuoteIsRevisedAndPrimary(){

        setUpData2();


        Date currentDate = Date.today();

        setUpAdRevenueMonthlyAndAdRevenueDailyMap();

        List<Ad_Product__c> listAdProd = [
            Select Id,Name, from_Date__c,until_Date__c,TotalPrice__c,Quote_Line_Item__c,Is_Revised_Quote__c
            From Ad_Product__c 
            Where Opportunity__c =: opp1.Id
            Order By Quote_Line_Item__c ASC
        ];
        System.assertEquals(3, listAdProd.size());

        System.assertEquals(false, listAdProd[0].Is_Revised_Quote__c);
        System.assertEquals(null, listAdProd[0].Quote_Line_Item__c);
        System.assertEquals(qli1.Budget__c, listAdProd[0].TotalPrice__c);
        System.assertEquals(qli1.until_Date__c, listAdProd[0].until_Date__c);
        System.assertEquals(qli1.from_Date__c, listAdProd[0].from_Date__c);

        System.assertEquals(false, listAdProd[1].Is_Revised_Quote__c);
        System.assertEquals(null, listAdProd[1].Quote_Line_Item__c);
        System.assertEquals(qli2.Budget__c, listAdProd[1].TotalPrice__c);
        System.assertEquals(qli2.until_Date__c, listAdProd[1].until_Date__c);
        System.assertEquals(qli2.from_Date__c, listAdProd[1].from_Date__c);

        System.assertEquals(false, listAdProd[2].Is_Revised_Quote__c);
        System.assertEquals(null, listAdProd[2].Quote_Line_Item__c);
        System.assertEquals(qli3.Budget__c, listAdProd[2].TotalPrice__c);
        System.assertEquals(qli3.until_Date__c, listAdProd[2].until_Date__c);
        System.assertEquals(qli3.from_Date__c, listAdProd[2].from_Date__c);


        System.assertEquals(3, adMonthlyMap.get(listAdProd[0].Id).size());
        System.assertEquals(3, adMonthlyMap.get(listAdProd[1].Id).size());
        System.assertEquals(3, adMonthlyMap.get(listAdProd[2].Id).size());

        // start: test ad product 1

        Decimal eachPricePerday = qli1.Budget__c / (listAdProd[0].from_Date__c.daysBetween(listAdProd[0].until_Date__c) + 1);

        Ad_Revenue_Monthly__c adProd1Month1 = adMonthlyMap.get(listAdProd[0].Id)[0]; 
        Decimal eachPricePerMonth = eachPricePerday * (Date.daysInMonth(adProd1Month1.Transaction_Date__c.year(),adProd1Month1.Transaction_Date__c.month()));
        System.assertEquals(eachPricePerMonth, adProd1Month1.Amount__c);

        Ad_Revenue_Monthly__c adProd1Month2 = adMonthlyMap.get(listAdProd[0].Id)[1]; 
        eachPricePerMonth = eachPricePerday * (Date.daysInMonth(adProd1Month2.Transaction_Date__c.year(),adProd1Month2.Transaction_Date__c.month()));
        System.assertEquals(eachPricePerMonth, adProd1Month2.Amount__c);

        Ad_Revenue_Monthly__c adProd1Month3 = adMonthlyMap.get(listAdProd[0].Id)[2];

        System.assertEquals(11, adDailyMap.get(adProd1Month3.Id).size());

        eachPricePerMonth = eachPricePerday * 11;
        System.assertEquals(eachPricePerMonth, adProd1Month3.Amount__c);

        // end: test ad product 1



        // start: test ad product 2

        eachPricePerday = qli2.Budget__c / (listAdProd[1].from_Date__c.daysBetween(listAdProd[1].until_Date__c) + 1);

        Ad_Revenue_Monthly__c adProd2Month1 = adMonthlyMap.get(listAdProd[1].Id)[0]; 
        eachPricePerMonth = eachPricePerday * (Date.daysInMonth(adProd2Month1.Transaction_Date__c.year(),adProd2Month1.Transaction_Date__c.month()));
        System.assertEquals(eachPricePerMonth, adProd2Month1.Amount__c);

        Ad_Revenue_Monthly__c adProd2Month2 = adMonthlyMap.get(listAdProd[1].Id)[1]; 
        eachPricePerMonth = eachPricePerday * (Date.daysInMonth(adProd2Month2.Transaction_Date__c.year(),adProd2Month2.Transaction_Date__c.month()));
        System.assertEquals(eachPricePerMonth, adProd2Month2.Amount__c);

        Ad_Revenue_Monthly__c adProd2Month3 = adMonthlyMap.get(listAdProd[1].Id)[2];

        System.assertEquals(11, adDailyMap.get(adProd2Month3.Id).size());

        eachPricePerMonth = eachPricePerday * 11;
        System.assertEquals(eachPricePerMonth, adProd2Month3.Amount__c);

        // end: test ad product 2

         // start: test ad product 3

         eachPricePerday = qli3.Budget__c / (listAdProd[2].from_Date__c.daysBetween(listAdProd[2].until_Date__c) + 1);

         Ad_Revenue_Monthly__c adProd3Month1 = adMonthlyMap.get(listAdProd[2].Id)[0]; 
         eachPricePerMonth = eachPricePerday * (Date.daysInMonth(adProd3Month1.Transaction_Date__c.year(),adProd3Month1.Transaction_Date__c.month())- offSet5Days);
         System.assertEquals(eachPricePerMonth, adProd3Month1.Amount__c);
 
         Ad_Revenue_Monthly__c adProd3Month2 = adMonthlyMap.get(listAdProd[2].Id)[1]; 
         eachPricePerMonth = eachPricePerday * (Date.daysInMonth(adProd3Month2.Transaction_Date__c.year(),adProd3Month2.Transaction_Date__c.month()));
         System.assertEquals(eachPricePerMonth, adProd3Month2.Amount__c);
 
         Ad_Revenue_Monthly__c adProd3Month3 = adMonthlyMap.get(listAdProd[2].Id)[2];
 
         System.assertEquals(11, adDailyMap.get(adProd3Month3.Id).size());
 
         eachPricePerMonth = eachPricePerday * 11;
         System.assertEquals(eachPricePerMonth, adProd3Month3.Amount__c);
 
         // end: test ad product 3
 

        Decimal oldQli1Budget = qli1.Budget__c;
        Decimal oldQli2Budget = qli2.Budget__c;
        Decimal oldQli3Budget = qli3.Budget__c;

        // qli1.Budget__c = 100; // update from 100 to 100 // 29.07.2022 / Chetra Sarom / US-0009038 disable because when budget changed, revised quote logic will not run
        qli1.until_Date__c = qli1.until_Date__c.addDays(5);

        // qli2.Budget__c = 250; // update from 200 to 250 // update from 100 to 100 // 29.07.2022 / Chetra Sarom / US-0009038 disable because when budget changed, revised quote logic will not run
        qli2.until_Date__c = qli2.until_Date__c.addDays(6);

        // qli3.Budget__c = 300; // update from 300 to 300 // update from 100 to 100 // 29.07.2022 / Chetra Sarom / US-0009038 disable because when budget changed, revised quote logic will not run
        qli3.from_Date__c = qli3.from_Date__c.addMonths(-1);
        qli3.until_Date__c = qli3.until_Date__c.addDays(5);

        update new List<QuoteLineItem>{qli1,qli2,qli3};

        quote1.Primary_Quote__c = true;
        quote1.Is_Revised_Quote__c = true;

        Test.startTest();
        update quote1;
        Test.stopTest();

        // after another primary quote

        Decimal beforePrimaryAdProd1EachPricePerday = oldQli1Budget / (listAdProd[0].from_Date__c.daysBetween(listAdProd[0].until_Date__c) + 1);

        Decimal beforePrimaryAdProd2EachPricePerday = oldQli2Budget / (listAdProd[1].from_Date__c.daysBetween(listAdProd[1].until_Date__c) + 1);

        Decimal beforePrimaryAdProd3EachPricePerday = oldQli3Budget / (listAdProd[2].from_Date__c.daysBetween(listAdProd[2].until_Date__c) + 1);
        
        List<Ad_Product__c> listAdProdRequeried = [
            Select Id,Name, from_Date__c,until_Date__c,TotalPrice__c,Quote_Line_Item__c
            From Ad_Product__c 
            Where Opportunity__c =: opp1.Id
            Order By Quote_Line_Item__c ASC
        ];
        
        System.assertEquals(3, listAdProdRequeried.size());

        System.assertEquals(listAdProd[0].Id, listAdProdRequeried[0].Id);

        System.assertEquals(listAdProd[1].Id, listAdProdRequeried[1].Id);

        System.assertEquals(listAdProd[2].Id, listAdProdRequeried[2].Id);

        System.assertEquals(qli1.Id, listAdProdRequeried[0].Quote_Line_Item__c);
        System.assertEquals(qli1.Budget__c, listAdProdRequeried[0].TotalPrice__c);
        System.assertEquals(qli1.until_Date__c, listAdProdRequeried[0].until_Date__c);
        System.assertEquals(qli1.from_Date__c, listAdProdRequeried[0].from_Date__c);

        System.assertEquals(qli2.Id, listAdProdRequeried[1].Quote_Line_Item__c);
        System.assertEquals(qli2.Budget__c, listAdProdRequeried[1].TotalPrice__c);
        System.assertEquals(qli2.until_Date__c, listAdProdRequeried[1].until_Date__c);
        System.assertEquals(qli2.from_Date__c, listAdProdRequeried[1].from_Date__c);

        System.assertEquals(qli3.Id, listAdProdRequeried[2].Quote_Line_Item__c);
        System.assertEquals(qli3.Budget__c, listAdProdRequeried[2].TotalPrice__c);
        System.assertEquals(qli3.until_Date__c, listAdProdRequeried[2].until_Date__c);
        System.assertEquals(qli3.from_Date__c, listAdProdRequeried[2].from_Date__c);


        setUpAdRevenueMonthlyAndAdRevenueDailyMap();

        System.assertEquals(3, adMonthlyMap.get(listAdProdRequeried[0].Id).size());
        System.assertEquals(3, adMonthlyMap.get(listAdProdRequeried[1].Id).size());
        System.assertEquals(4, adMonthlyMap.get(listAdProdRequeried[2].Id).size());

        Decimal remainingBudget = 0;
        Date nextDate = currentDate.addDays(1);
        Decimal remainingPricePerDay = 0;

        Decimal dailyAmount;

        // start: test ad product 1

        
            // month 1
            adProd1Month1 = adMonthlyMap.get(listAdProdRequeried[0].Id)[0]; 
            eachPricePerMonth = beforePrimaryAdProd1EachPricePerday * (Date.daysInMonth(adProd1Month1.Transaction_Date__c.year(),adProd1Month1.Transaction_Date__c.month()));
            System.assertEquals(eachPricePerMonth, adProd1Month1.Amount__c);
            Integer numberOfDayOfAdProd1Month1 = Date.daysInMonth(adProd1Month1.Transaction_Date__c.year(), adProd1Month1.Transaction_Date__c.month());
                // month 1 - daily
                dailyAmount = 0;
                for(Ad_Revenue_Daily__c eachDay : adDailyMap.get(adProd1Month1.Id)){
                    dailyAmount += eachDay.Amount__c;
                }
                System.assertEquals(adProd1Month1.Amount__c, dailyAmount);
                    

            // month 2
            adProd1Month2 = adMonthlyMap.get(listAdProdRequeried[0].Id)[1]; 
            Integer adProd1Month2UsedDay = (adProd1Month2.Transaction_Date__c.toStartOfMonth().daysBetween(currentDate) +1);
            eachPricePerMonth = beforePrimaryAdProd1EachPricePerday * adProd1Month2UsedDay;

            remainingBudget = listAdProdRequeried[0].TotalPrice__c - (beforePrimaryAdProd1EachPricePerday * (numberOfDayOfAdProd1Month1 + adProd1Month2UsedDay));

            remainingPricePerDay = remainingBudget / (Integer.valueOf(nextDate.daysBetween(listAdProdRequeried[0].until_Date__c)) +1);

            Integer numberOfDayOfAdProd1Month2 = Date.daysInMonth(adProd1Month2.Transaction_Date__c.year(), adProd1Month2.Transaction_Date__c.month());
            Date adProd1Month2LastDay  = Date.newInstance(adProd1Month2.Transaction_Date__c.year(), adProd1Month2.Transaction_Date__c.month(), numberOfDayOfAdProd1Month2);
            Integer adProd1Month2RemainingDay = (Integer.valueOf(nextDate.daysBetween(adProd1Month2LastDay)))+1;
            Decimal adProd1Month2RemainingAmount = (remainingPricePerDay * adProd1Month2RemainingDay);
            eachPricePerMonth =  eachPricePerMonth + adProd1Month2RemainingAmount;
                
            System.assertEquals(eachPricePerMonth, adProd1Month2.Amount__c);
                // month 2 - daily
                dailyAmount = 0;
                for(Ad_Revenue_Daily__c eachDay : adDailyMap.get(adProd1Month2.Id)){
                    dailyAmount += eachDay.Amount__c;
                }
                System.assertEquals(adProd1Month2.Amount__c, dailyAmount);            


            // month 3
            adProd1Month3 = adMonthlyMap.get(listAdProdRequeried[0].Id)[2];
            eachPricePerMonth = remainingPricePerDay * (Integer.valueOf(adProd1Month3.Transaction_Date__c.toStartOfMonth().daysBetween(listAdProdRequeried[0].until_Date__c)) +1);
            
            System.assertEquals(eachPricePerMonth, adProd1Month3.Amount__c);
                // month 3 - daily
                dailyAmount = 0;
                for(Ad_Revenue_Daily__c eachDay : adDailyMap.get(adProd1Month3.Id)){
                    dailyAmount += eachDay.Amount__c;
                }
                System.assertEquals(adProd1Month3.Amount__c, dailyAmount);   

         // start: test ad product 1
        


        // *****

        // start: test ad product 2

        
            // month 1 
            adProd2Month1 = adMonthlyMap.get(listAdProdRequeried[1].Id)[0]; 
            eachPricePerMonth = beforePrimaryAdProd2EachPricePerday * (Date.daysInMonth(adProd2Month1.Transaction_Date__c.year(),adProd2Month1.Transaction_Date__c.month()));
            System.assertEquals(eachPricePerMonth, adProd2Month1.Amount__c);
            Integer numberOfDayOfAdProd2Month1 = Date.daysInMonth(adProd2Month1.Transaction_Date__c.year(), adProd2Month1.Transaction_Date__c.month());


            // month 2
            adProd2Month2 = adMonthlyMap.get(listAdProdRequeried[1].Id)[1]; 
            Integer adProd2Month2UsedDay = (adProd2Month2.Transaction_Date__c.toStartOfMonth().daysBetween(currentDate) +1);
            eachPricePerMonth = beforePrimaryAdProd2EachPricePerday * adProd2Month2UsedDay;

            remainingBudget = listAdProdRequeried[1].TotalPrice__c - (beforePrimaryAdProd2EachPricePerday * (numberOfDayOfAdProd2Month1 + adProd2Month2UsedDay));

            remainingPricePerDay = remainingBudget / (Integer.valueOf(nextDate.daysBetween(listAdProdRequeried[1].until_Date__c)) +1);

            Integer numberOfDayOfAdProd2Month2 = Date.daysInMonth(adProd2Month2.Transaction_Date__c.year(), adProd2Month2.Transaction_Date__c.month());
            Date adProd2Month2LastDay  = Date.newInstance(adProd2Month2.Transaction_Date__c.year(), adProd2Month2.Transaction_Date__c.month(), numberOfDayOfAdProd2Month2);
            Integer adProd2Month2RemainingDay = (Integer.valueOf(nextDate.daysBetween(adProd2Month2LastDay)))+1;
            Decimal adProd2Month2RemainingAmount = (remainingPricePerDay * adProd2Month2RemainingDay);
            eachPricePerMonth =  eachPricePerMonth + adProd2Month2RemainingAmount;
                

            System.assertEquals(eachPricePerMonth, adProd2Month2.Amount__c);


            // month 3
            adProd2Month3 = adMonthlyMap.get(listAdProdRequeried[1].Id)[2];
            eachPricePerMonth = remainingPricePerDay * (Integer.valueOf(adProd2Month3.Transaction_Date__c.toStartOfMonth().daysBetween(listAdProdRequeried[1].until_Date__c)) +1);
            System.assertEquals(eachPricePerMonth, adProd2Month3.Amount__c);

         // end: test ad product 2


        // start: test ad product 3

            // month 1 
            adProd3Month1 = adMonthlyMap.get(listAdProdRequeried[2].Id)[0]; 
            System.assertEquals(0, adProd3Month1.Amount__c);

            // month 2 
            adProd3Month2 = adMonthlyMap.get(listAdProdRequeried[2].Id)[1]; 
            eachPricePerMonth = beforePrimaryAdProd3EachPricePerday * (Date.daysInMonth(adProd3Month2.Transaction_Date__c.year(),adProd3Month2.Transaction_Date__c.month()) - offSet5Days);
            System.assertEquals(eachPricePerMonth, adProd3Month2.Amount__c);
            Integer numberOfDayOfAdProd3Month2 = Date.daysInMonth(adProd3Month2.Transaction_Date__c.year(), adProd3Month2.Transaction_Date__c.month()) - offSet5Days;

            // month 3
            adProd3Month3 = adMonthlyMap.get(listAdProdRequeried[2].Id)[2]; 
            Integer adProd3Month3UsedDay = (adProd3Month3.Transaction_Date__c.toStartOfMonth().daysBetween(currentDate) +1);
            eachPricePerMonth = beforePrimaryAdProd3EachPricePerday * adProd3Month3UsedDay;

            remainingBudget = listAdProdRequeried[2].TotalPrice__c - (beforePrimaryAdProd3EachPricePerday * (numberOfDayOfAdProd3Month2 + adProd3Month3UsedDay));
            remainingPricePerDay = remainingBudget / (Integer.valueOf(nextDate.daysBetween(listAdProdRequeried[2].until_Date__c)) +1);
            
            Integer numberOfDayOfAdProd3Month3 = Date.daysInMonth(adProd3Month3.Transaction_Date__c.year(), adProd3Month3.Transaction_Date__c.month());
            Date adProd3Month3LastDay  = Date.newInstance(adProd3Month3.Transaction_Date__c.year(), adProd3Month3.Transaction_Date__c.month(), numberOfDayOfAdProd3Month3);
            Integer adProd3Month3RemainingDay = (Integer.valueOf(nextDate.daysBetween(adProd3Month3LastDay)))+1;
            Decimal adProd3Month3RemainingAmount = (remainingPricePerDay * adProd3Month3RemainingDay);
            eachPricePerMonth =  eachPricePerMonth + adProd3Month3RemainingAmount;

            System.assertEquals(eachPricePerMonth, adProd3Month3.Amount__c);

            // month 4
            Ad_Revenue_Monthly__c adProd3Month4 = adMonthlyMap.get(listAdProdRequeried[2].Id)[3];
            eachPricePerMonth = remainingPricePerDay * (Integer.valueOf(adProd3Month4.Transaction_Date__c.toStartOfMonth().daysBetween(listAdProdRequeried[2].until_Date__c)) +1);
            System.assertEquals(eachPricePerMonth, adProd3Month4.Amount__c);


        // end: test ad product 3
    }

    /*****************************************************************************************************************************
    @ Method:       testChangingFieldIsPendingDfpPushToTrue
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008838 test method for AdProductTriggerHandler.populateFields 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.12.2020 / Sophal Noch / US-0008838 Created the  method.
    @*****************************************************************************************************************************/
    static testMethod void testChangingFieldIsPendingDfpPushToTrue(){
        setUpData();

        site = generateSite();
        insert site;

        prod1 = generateProduct(site.Id);
        insert prod1;

        book1Id = Test.getStandardPriceBookId();
        
        pbe1 = generatePricebookEntry(prod1.id, book1Id);
        insert pbe1;

        quote1 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp.Id, Pricebook2Id = book1Id, Is_Revised_Quote__c = false, Primary_Quote__c = true);

        insert quote1;

        quote1.Primary_Quote__c = true;
        quote1.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        update quote1;

        qli1 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = 100;
        qli1.from_Date__c = Date.today().addMonths(2);
        qli1.until_Date__c = Date.today().addMonths(3);
        insert qli1;

        //quote1.Is_Revised_Quote__c = true;
        update quote1;

        Ad_Product__c adProductAfterInsert = [Select Id,IsPendingDfpPush__c From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id];
        System.assertEquals(false, adProductAfterInsert.IsPendingDfpPush__c);

        //qli1.Description__c = 'test test';
        qli1.Description = 'test test';
        update qli1;

        Ad_Product__c adProductAfterUpdate1 = [Select Id,IsPendingDfpPush__c From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id];
        System.assertEquals(false, adProductAfterUpdate1.IsPendingDfpPush__c);

        qli1.until_Date__c = qli1.until_Date__c.addDays(1);
        update qli1;

        Ad_Product__c adProductAfterUpdate2 = [Select Id,IsPendingDfpPush__c From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id];
        System.assertEquals(true, adProductAfterUpdate2.IsPendingDfpPush__c);
        
    }

    // // 07.01.2021 / Sophal Noch / US-0008300 :
    static testMethod void testUpdateDeliverySummeDaily(){

        setUpData3();
        Ad_Product__c adProd = [Select Id From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id];
        System.assertNotEquals(null, adProd.Id);

        opp.Order_Id__c = '1';
        update opp;
        adProd.Ad_Id__c = '1';
        adProd.Booked_Quantity__c = 1000;
        adProd.Billing_Category__c = 'Fix Price';

        Test.startTest();
        update adProd;
        Test.stopTest();

        //Date today = System.today();

        List<Ad_Revenue_Daily__c> dailyList = [Select Id,Day__c,Invoice_Quantity__c From Ad_Revenue_Daily__c Where Ad_Product__c =:adProd.Id  Order by Day__c ASC];
        System.assert(dailyList.size() > 0);
        //System.assertEquals(1, dailyList[0].Invoice_Quantity__c);

        //for(Ad_Revenue_Daily__c eachDaily : dailyList){
        //    if(eachDaily.Day__c <= today){
        //        System.assertEquals(1, eachDaily.Invoice_Quantity__c);
        //    }
        //}
        

    }


    //  Sophal Noch 15.01.2020  : US-0008981 - Add byPass on AdproductTrigger
    static testMethod void testByPassAdProductTrigger(){

        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Ad_Product__c', byPass_Trigger__c = true);
        insert bp;

        account = generateAccount();
        account.Record_Type_Text__c = 'Advertiser';//avoid validation rule error
        insert account;

        opp = new Opportunity(AccountId = account.Id, Name = 'Test Opp',StageName='Qualified Meeting',CloseDate=Date.newInstance( 2021, 1, 1),RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id);
        insert opp;

        site = generateSite();
        insert site;

        prod1 = generateProduct(site.Id);
        insert prod1;

        book1Id = Test.getStandardPriceBookId();
        
        pbe1 = generatePricebookEntry(prod1.id, book1Id);
        insert pbe1;

        quote1 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp.Id, Pricebook2Id = book1Id, Is_Revised_Quote__c = false, Primary_Quote__c = true);

        insert quote1;

        quote1.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote1.Primary_Quote__c= true;
        update quote1;
        

        qli1 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = 100;
        qli1.from_Date__c = Date.today().addMonths(-1);
        qli1.until_Date__c = Date.today().addMonths(1);
        insert qli1;

        Ad_Product__c adProd = [Select Id From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id];
        
        List<Ad_Revenue_Monthly__c> listMonthly = [Select Id from Ad_Revenue_Monthly__c Where Ad_Product__c =: adProd.Id];
        System.assertEquals(0, listMonthly.size());


    }

    static testMethod void testGenerateRevenueWithQueue() {
        // 10.09.2021 / Sophal Noch / US-0010379
        setUpData();

        site = generateSite();
        insert site;

        prod1 = generateProduct(site.Id);
        insert prod1;

        book1Id = Test.getStandardPriceBookId();
        
        pbe1 = generatePricebookEntry(prod1.id, book1Id);
        insert pbe1;

        quote1 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp.Id, Pricebook2Id = book1Id, Is_Revised_Quote__c = false, Primary_Quote__c = true);

        insert quote1;

        quote1.Primary_Quote__c = true;
        quote1.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        update quote1;

        qli1 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = 100;
        qli1.from_Date__c = Date.today().addMonths(2);
        qli1.until_Date__c = Date.today().addMonths(3);


        qli2 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli2.Budget__c = 100;
        qli2.from_Date__c = Date.today().addMonths(2);
        qli2.until_Date__c = Date.today().addMonths(4);

        List<QuoteLineItem> qliToInsert = new List<QuoteLineItem>{qli1,qli2};

        // AdProductTriggerHandler.testRunAsQueue = true;
        
        Test.startTest();

            AdProductTriggerHandler.RG_DML_CHUNK_LIMIT = 0; //  10.09.2021 / Sophal Noch / US-0010379 : make it zero so it can split in chunks
            // 10.09.2021 / Sophal Noch / US-0010379 : - first QLI will sync to first adProduct and generate revenue record
            // - second QLI will sync to second adProduct and but not can not generate revenue records because queue method can not be chained in test class.
            insert qliToInsert; 

            List<Ad_Product__c> listAdProd = [Select Id,Quote_Line_Item__c From Ad_Product__c where Quote_Line_Item__c IN: qliToInsert Order by Quote_Line_Item__c ASC];
            System.assertEquals(qliToInsert[0].Id, listAdProd[0].Quote_Line_Item__c);
            System.assertEquals(qliToInsert[1].Id, listAdProd[1].Quote_Line_Item__c);

            Map<Id,Ad_Product__c> mapAdProd2 = new Map<Id,Ad_Product__c>((List<Ad_Product__c>)QueryUtil.queryRecords('Ad_Product__c',' Id =:value1',new Map<String, Object>{'value1'=>listAdProd[1].Id}));
            List<Map<Id,Ad_Product__c>> listMapAdProd = new List<Map<Id,Ad_Product__c>>();
            listMapAdProd.add(mapAdProd2);
            QueueGenerateRevenue queueGenerator = new QueueGenerateRevenue(listMapAdProd,0);
            queueGenerator.execute(null);  // 10.09.2021 / Sophal Noch / US-0010379 : test class can not run chained queue so it need to be called manually for this second ad product
            queueGenerator.doRetry();
        
        Test.stopTest();

        List<Ad_Revenue_Monthly__c>  listMonlthyAdProd1 = [Select Id,Transaction_date__c From Ad_Revenue_Monthly__c Where ad_product__c =: listAdProd[0].Id];
        System.assert(listMonlthyAdProd1.size() > 0);
        System.assertEquals(qli1.until_Date__c.month(),listMonlthyAdProd1[listMonlthyAdProd1.size()-1].Transaction_date__c.month());

        List<Ad_Revenue_Monthly__c>  listMonlthyAdProd2 = [Select Id, Transaction_date__c From Ad_Revenue_Monthly__c Where ad_product__c =: listAdProd[1].Id];
        System.assert(listMonlthyAdProd2.size() > 0);
        System.assertEquals(qli2.until_Date__c.month(), listMonlthyAdProd2[listMonlthyAdProd2.size()-1].Transaction_date__c.month());

    }

    @isTest
    static void testPBName() {
        setUpData2();
    }


}