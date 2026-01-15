/*********************************************************************************************************************************
@ Class:          BAT_RSD_PVP_Test
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0009295 - Migrate BAT_RSD_PVP from EU Ads to Hive. 
                  This is test class for 'BAT_RSD_PVP'
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  12.04.2021 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
private without sharing class BAT_RSD_PVP_Test {


    private static Account seller;
    private static Opportunity opp;

    private static Date startDate;
    private static Date endDate;

    private static Quote quote1;

    private static Site__c site;
    private static Product2 prod1;

    private static Id book1Id;

    private static PriceBookEntry pbe1;

    private static QuoteLineItem qli1;

    private static QuoteLineItem qli2;

    private static byPass__c bp;

    static void setUpData(){

        // bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false, byPass_WFRule__c = false);
        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = true, byPass_WFRule__c = true); // to improve performance, bypass tirgger, process builder, flow ... etc
        insert bp;


        // List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'Advertiser'); //MN-13092022-US-0012442
        seller = sellers[0];

        seller.Record_Type_Text__c = 'Advertiser';
        update seller;

        opp = new Opportunity(AccountId = seller.Id, Name = 'Test Opp',StageName='Qualified Meeting',CloseDate=Date.newInstance( 2021, 1, 1));
        insert opp;

        site = TST_DataGenerator.generateSite();
        insert site;

        prod1 = TST_DataGenerator.generateProduct(site.Id);
        prod1.Callisto__c = true;
        insert prod1;

        book1Id = Test.getStandardPriceBookId();
        
        pbe1 = TST_DataGenerator.generatePricebookEntry(prod1.id, book1Id);
        insert pbe1;

        quote1 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp.Id, Pricebook2Id = book1Id, Is_Revised_Quote__c = false, Primary_Quote__c = true);

        insert quote1;

        quote1.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote1.Primary_Quote__c= true;
        update quote1;
        
    }

    static testMethod void testBatRSD_PVP() {
        setUpData();

        Date lastMonth = Date.today().addMonths(-1);
        Integer daysInTheMonth = Date.daysInMonth(lastMonth.year(), lastMonth.month());

        qli1 = TST_DataGenerator.generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = 100;
        qli1.from_Date__c = Date.newInstance(lastMonth.year(), lastMonth.month(), 1);
        qli1.until_Date__c = Date.newInstance(lastMonth.year(), lastMonth.month(), daysInTheMonth);
        qli1.Billing_Category__c = 'CPM';


        qli2 = TST_DataGenerator.generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli2.Budget__c = 100;
        qli2.from_Date__c = Date.newInstance(lastMonth.year(), lastMonth.month(), 1);
        qli2.until_Date__c = Date.newInstance(lastMonth.year(), lastMonth.month(), daysInTheMonth);
        qli2.Billing_Category__c = 'CPM';

        bp.byPass_Trigger__c = false;
        update bp;

        insert new List<QuoteLineItem>{qli1,qli2};

        bp.byPass_Trigger__c = true;
        update bp;

        List<Ad_Product__c> listAdProduct = [Select Id From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id or Quote_Line_Item__c =: qli2.Id Order by Id ASC];
        System.assertEquals(2, listAdProduct.size());

        List<Ad_Revenue_Daily__c> listRdaily = [Select Id, Ad_Revenue_Monthly__c, X3rd_Party_Gross__c, X3rd_Party_Clicks__c, X3rd_Party_AI__c From Ad_Revenue_Daily__c Where Ad_Product__c IN : listAdProduct Order by Ad_Product__c,Ad_Revenue_Monthly__c, Transaction_Date__c ASC];

        System.assert(listRdaily.size() > 0);

        Map<Id,Decimal> mapDailyIdSumX3PartyGross = new Map<Id,Decimal>();
        Map<Id,Decimal> mapDailyIdSumX3PartyClick = new Map<Id,Decimal>();
        Map<Id,Decimal> mapDailyIdSumXPartyAI = new Map<Id,Decimal>();

        for(Ad_Revenue_Daily__c eachDaily : listRdaily){


                eachDaily.X3rd_Party_Gross__c = 10;
                eachDaily.X3rd_Party_Clicks__c = 20;
                eachDaily.X3rd_Party_AI__c = 30;

                if(mapDailyIdSumX3PartyGross.containsKey(eachDaily.Ad_Revenue_Monthly__c)){
                    mapDailyIdSumX3PartyGross.put(eachDaily.Ad_Revenue_Monthly__c, mapDailyIdSumX3PartyGross.get(eachDaily.Ad_Revenue_Monthly__c) + eachDaily.X3rd_Party_Gross__c);
                }else{
                    mapDailyIdSumX3PartyGross.put(eachDaily.Ad_Revenue_Monthly__c,  eachDaily.X3rd_Party_Gross__c);
                }
    
                if(mapDailyIdSumX3PartyClick.containsKey(eachDaily.Ad_Revenue_Monthly__c)){
                    mapDailyIdSumX3PartyClick.put(eachDaily.Ad_Revenue_Monthly__c, mapDailyIdSumX3PartyClick.get(eachDaily.Ad_Revenue_Monthly__c) + eachDaily.X3rd_Party_Clicks__c);
                }else{
                    mapDailyIdSumX3PartyClick.put(eachDaily.Ad_Revenue_Monthly__c,  eachDaily.X3rd_Party_Clicks__c);
                }
    
                if(mapDailyIdSumXPartyAI.containsKey(eachDaily.Ad_Revenue_Monthly__c)){
                    mapDailyIdSumXPartyAI.put(eachDaily.Ad_Revenue_Monthly__c, mapDailyIdSumXPartyAI.get(eachDaily.Ad_Revenue_Monthly__c) + eachDaily.X3rd_Party_AI__c);
                }else{
                    mapDailyIdSumXPartyAI.put(eachDaily.Ad_Revenue_Monthly__c,  eachDaily.X3rd_Party_AI__c);
                }



        }

        update listRdaily;

       
        Test.startTest();
            BAT_RSD_PVP bat_rsd = new BAT_RSD_PVP();
            bat_rsd.execute(null);
        Test.stopTest();
       
        List<Ad_Revenue_Monthly__c> listRmonthly = [Select Id, X3rd_Party_Monthly_Gross__c, X3rd_Party_Clicks__c, X3rd_Party_AI__c From Ad_Revenue_Monthly__c Where Ad_Product__c IN: listAdProduct Order by Id, Transaction_Date__c ASC];
        System.assertEquals(2, listRmonthly.size());

        System.assertEquals(mapDailyIdSumX3PartyGross.get(listRmonthly[0].Id), listRmonthly[0].X3rd_Party_Monthly_Gross__c);
        System.assertEquals(mapDailyIdSumX3PartyClick.get(listRmonthly[0].Id), listRmonthly[0].X3rd_Party_Clicks__c);
        System.assertEquals(mapDailyIdSumXPartyAI.get(listRmonthly[0].Id), listRmonthly[0].X3rd_Party_AI__c);

        System.assertEquals(mapDailyIdSumX3PartyGross.get(listRmonthly[1].Id), listRmonthly[1].X3rd_Party_Monthly_Gross__c);
        System.assertEquals(mapDailyIdSumX3PartyClick.get(listRmonthly[1].Id), listRmonthly[1].X3rd_Party_Clicks__c);
        System.assertEquals(mapDailyIdSumXPartyAI.get(listRmonthly[1].Id), listRmonthly[1].X3rd_Party_AI__c);

    

    }
    
    static testMethod void test_last6Month() {

        // Sophal: 02/08/2021: US-0010063 test method

        setUpData();

        Date last7Month = Date.today().addMonths(-7);

        Date currentMonth = Date.today();
        Integer daysInTheCurrentMonth = Date.daysInMonth(currentMonth.year(), currentMonth.month());

        qli1 = TST_DataGenerator.generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = 100;
        qli1.from_Date__c = Date.newInstance(last7Month.year(), last7Month.month(), 1);
        qli1.until_Date__c = Date.newInstance(currentMonth.year(), currentMonth.month(), daysInTheCurrentMonth);
        qli1.Billing_Category__c = 'CPM';
       

        bp.byPass_Trigger__c = false;
        update bp;

        insert qli1;

        bp.byPass_Trigger__c = true;
        update bp;

        List<Ad_Product__c> listAdProduct = [Select Id From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id Order by Id ASC];
        System.assertEquals(1, listAdProduct.size());

        List<Ad_Revenue_Daily__c> listRdaily = [Select Id, Ad_Revenue_Monthly__c, X3rd_Party_Gross__c, X3rd_Party_Clicks__c, X3rd_Party_AI__c From Ad_Revenue_Daily__c Where Ad_Product__c IN : listAdProduct Order by Ad_Product__c,Ad_Revenue_Monthly__c, Transaction_Date__c ASC];
        System.assert(listRdaily.size() > 0);


        Map<Id,Decimal> mapDailyIdSumX3PartyGross = new Map<Id,Decimal>();
        Map<Id,Decimal> mapDailyIdSumX3PartyClick = new Map<Id,Decimal>();
        Map<Id,Decimal> mapDailyIdSumXPartyAI = new Map<Id,Decimal>();

        for(Ad_Revenue_Daily__c eachDaily : listRdaily){


                eachDaily.X3rd_Party_Gross__c = 10;
                eachDaily.X3rd_Party_Clicks__c = 20;
                eachDaily.X3rd_Party_AI__c = 30;

                if(mapDailyIdSumX3PartyGross.containsKey(eachDaily.Ad_Revenue_Monthly__c)){
                    mapDailyIdSumX3PartyGross.put(eachDaily.Ad_Revenue_Monthly__c, mapDailyIdSumX3PartyGross.get(eachDaily.Ad_Revenue_Monthly__c) + eachDaily.X3rd_Party_Gross__c);
                }else{
                    mapDailyIdSumX3PartyGross.put(eachDaily.Ad_Revenue_Monthly__c,  eachDaily.X3rd_Party_Gross__c);
                }
    
                if(mapDailyIdSumX3PartyClick.containsKey(eachDaily.Ad_Revenue_Monthly__c)){
                    mapDailyIdSumX3PartyClick.put(eachDaily.Ad_Revenue_Monthly__c, mapDailyIdSumX3PartyClick.get(eachDaily.Ad_Revenue_Monthly__c) + eachDaily.X3rd_Party_Clicks__c);
                }else{
                    mapDailyIdSumX3PartyClick.put(eachDaily.Ad_Revenue_Monthly__c,  eachDaily.X3rd_Party_Clicks__c);
                }
    
                if(mapDailyIdSumXPartyAI.containsKey(eachDaily.Ad_Revenue_Monthly__c)){
                    mapDailyIdSumXPartyAI.put(eachDaily.Ad_Revenue_Monthly__c, mapDailyIdSumXPartyAI.get(eachDaily.Ad_Revenue_Monthly__c) + eachDaily.X3rd_Party_AI__c);
                }else{
                    mapDailyIdSumXPartyAI.put(eachDaily.Ad_Revenue_Monthly__c,  eachDaily.X3rd_Party_AI__c);
                }

        }

        // update listRdaily; // move to between Test.startTest() and  Test.stopTest().

        Test.startTest();

            update listRdaily;

            BAT_RSD_PVP bat_rsd = new BAT_RSD_PVP('=','LAST_N_MONTHS:6');
            Database.executeBatch(bat_rsd,100);
        Test.stopTest();

        List<Ad_Revenue_Monthly__c> listRmonthly = [Select Id, X3rd_Party_Monthly_Gross__c, X3rd_Party_Clicks__c, X3rd_Party_AI__c From Ad_Revenue_Monthly__c Where Ad_Product__c IN: listAdProduct Order by Id, Transaction_Date__c ASC];
        System.assertEquals(8, listRmonthly.size());

        System.assertEquals(null, listRmonthly[0].X3rd_Party_Monthly_Gross__c);
        System.assertEquals(null, listRmonthly[0].X3rd_Party_Clicks__c);
        System.assertEquals(null, listRmonthly[0].X3rd_Party_AI__c);

        // last 6 months, record start here:

        System.assertEquals(mapDailyIdSumX3PartyGross.get(listRmonthly[1].Id), listRmonthly[1].X3rd_Party_Monthly_Gross__c);
        System.assertEquals(mapDailyIdSumX3PartyClick.get(listRmonthly[1].Id), listRmonthly[1].X3rd_Party_Clicks__c);
        System.assertEquals(mapDailyIdSumXPartyAI.get(listRmonthly[1].Id), listRmonthly[1].X3rd_Party_AI__c);

        System.assertEquals(mapDailyIdSumX3PartyGross.get(listRmonthly[2].Id), listRmonthly[2].X3rd_Party_Monthly_Gross__c);
        System.assertEquals(mapDailyIdSumX3PartyClick.get(listRmonthly[2].Id), listRmonthly[2].X3rd_Party_Clicks__c);
        System.assertEquals(mapDailyIdSumXPartyAI.get(listRmonthly[2].Id), listRmonthly[2].X3rd_Party_AI__c);

        System.assertEquals(mapDailyIdSumX3PartyGross.get(listRmonthly[3].Id), listRmonthly[3].X3rd_Party_Monthly_Gross__c);
        System.assertEquals(mapDailyIdSumX3PartyClick.get(listRmonthly[3].Id), listRmonthly[3].X3rd_Party_Clicks__c);
        System.assertEquals(mapDailyIdSumXPartyAI.get(listRmonthly[3].Id), listRmonthly[3].X3rd_Party_AI__c);

        System.assertEquals(mapDailyIdSumX3PartyGross.get(listRmonthly[4].Id), listRmonthly[4].X3rd_Party_Monthly_Gross__c);
        System.assertEquals(mapDailyIdSumX3PartyClick.get(listRmonthly[4].Id), listRmonthly[4].X3rd_Party_Clicks__c);
        System.assertEquals(mapDailyIdSumXPartyAI.get(listRmonthly[4].Id), listRmonthly[4].X3rd_Party_AI__c);

        System.assertEquals(mapDailyIdSumX3PartyGross.get(listRmonthly[5].Id), listRmonthly[5].X3rd_Party_Monthly_Gross__c);
        System.assertEquals(mapDailyIdSumX3PartyClick.get(listRmonthly[5].Id), listRmonthly[5].X3rd_Party_Clicks__c);
        System.assertEquals(mapDailyIdSumXPartyAI.get(listRmonthly[5].Id), listRmonthly[5].X3rd_Party_AI__c);

        System.assertEquals(mapDailyIdSumX3PartyGross.get(listRmonthly[6].Id), listRmonthly[6].X3rd_Party_Monthly_Gross__c);
        System.assertEquals(mapDailyIdSumX3PartyClick.get(listRmonthly[6].Id), listRmonthly[6].X3rd_Party_Clicks__c);
        System.assertEquals(mapDailyIdSumXPartyAI.get(listRmonthly[6].Id), listRmonthly[6].X3rd_Party_AI__c);

       // last 6 months, record end here.

        System.assertEquals(null, listRmonthly[7].X3rd_Party_Monthly_Gross__c);
        System.assertEquals(null, listRmonthly[7].X3rd_Party_Clicks__c);
        System.assertEquals(null, listRmonthly[7].X3rd_Party_AI__c);

    }
    

}