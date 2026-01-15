/*********************************************************************************************************************************
@ Class:          TST_GW_QuoteLineItem
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Test class for GW_QuoteLineItem.cls
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  21.10.2020 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
public without sharing class TST_GW_QuoteLineItem {

    public static Account account;
    public static Opportunity opp1;
    public static Integer currentYear = System.Today().year();

    public static Date startDate;
    public static Date endDate;

    public static Quote quote1;

    public static Site__c site;
    public static Product2 prod1;

    public static PriceBookEntry pbe1; 

    public static QuoteLineItem qli1;
    public static QuoteLineItem qli2;
    public static QuoteLineItem qli3;

    public static Date validStartDate;
    public static Date validEndDate;

    public static Date invalidStartDate;
    public static Date invalidEndDate;

    public static IO__c io;
    public static IO_LineItem__c ioLineItem;
    public static IO_LineItem_Junction__c ioJunction;

    public static byPass__c bp;
    
    private static RecordType rtAdvertiser = [SELECT id FROM recordType WHERE name = 'Advertiser' AND sobjectType = 'Account'];

    private static Account generateAccount(){
    	return new Account(
    		Name = 'Account test',
    		BillingStreet = 'Goethestrasse 97',
            BillingPostalCode = '19053',
            BillingCity = 'Schwerin',
            BillingState = 'Berlin',
            BillingCountry = 'Germany',
            Phone = '+1234567890',
            Record_Type_Text__c = 'Advertiser', // 03.08.2022 / Chetra Sarom / US-0009038
            recordTypeid = rtAdvertiser.id
		);
    }

    private static Site__c generateSite(){
        return new Site__c(Name='Test', Country__c='Test');
    }

    private static Product2 generateProduct(Id siteId){
        return new Product2(
              Name = 'Product Test',
              Site__c = siteId
              );
    }

    private static PriceBookEntry generatePricebookEntry(Id prodId, Id pbId){
        return new PriceBookEntry(
            Product2Id = prodId,
            IsActive = true,
            UnitPrice = 10,
            Pricebook2Id = pbId !=null ? pbId : Test.getStandardPriceBookId()
            );
    }

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


    private static void setUpQuoteLineItem(){

        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem Ad_Product__c', byPass_Trigger__c = false);  //  // US-0008988
        insert bp;

        account = generateAccount();
        insert account;

        startDate = Date.today();
        endDate = startDate.addMonths(3);

        opp1 = new Opportunity(
                Name = 'Opp 1',
                Amount = 100,
                StageName = 'Qualified Meeting',
                CloseDate = Date.newInstance( currentYear, 1, 1),
                Start_Date__c = startDate,
                End_Date__c = endDate,
                accountId = account.Id
        );

        insert opp1;

        site = generateSite();
        insert site;

        prod1 = generateProduct(site.Id);
        insert prod1;

        Id book1Id = Test.getStandardPriceBookId();
        
        pbe1 = generatePricebookEntry(prod1.id, book1Id);

        insert pbe1;

        // start: to coverage old code
        io = new IO__c();
        insert io;
        ioLineItem = new IO_LineItem__c(IO__c = io.Id);
        insert ioLineItem;
        ioJunction = new IO_LineItem_Junction__c(IO_LineItem__c=ioLineItem.Id);
        insert ioJunction;
        // end: to coverage old code

        Id ebayRecId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;

        quote1 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp1.Id, Pricebook2Id = book1Id, IO__c = io.Id, RecordTypeId = ebayRecId);

        insert quote1;

        quote1.Primary_Quote__c = false;
        quote1.Is_Revised_Quote__c = true;
        update quote1;
        

        // validStartDate = Date.today().addMonths(1);
        // validEndDate = validStartDate.addMonths(1);

        // invalidStartDate = Date.today().addMonths(-5);
        // invalidEndDate = invalidStartDate.addMonths(1);

        // 04.11.2022 / Sophal Noch / US-0012478 :
        validStartDate = Date.today().addDays(1);
        validEndDate = validStartDate.addMonths(1);

        invalidStartDate = Date.today().addDays(-5);
        invalidEndDate = invalidStartDate.addDays(1);


        qli1 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = 10;
        qli1.from_date__c = validStartDate;
        qli1.until_date__c = validEndDate;

        qli2 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli2.Budget__c = 20;
        qli2.from_date__c = invalidStartDate;
        qli2.until_date__c = invalidEndDate;

        qli3 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli3.Budget__c = 30;
        qli3.from_date__c = validStartDate;
        qli3.until_date__c = validEndDate;

    }

    
    /*****************************************************************************************************************************
    @ Method:       testPreventDeletingOrUpdatingQli
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008517 test method GW_QuoteLineItem.preventDeletingOrUpdatingQli
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.10.2020 / Sophal Noch / Created the class.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  26.04.2021 / Sophal Noch / update the class.
    @*****************************************************************************************************************************/
    static testMethod void testPreventDeletingOrUpdatingQli() {
        setUpQuoteLineItem();

        quote1.Is_Revised_Quote__c = false;
        update quote1;

        insert new List<QuoteLineItem>{qli1, qli2, qli3};

        quote1.Is_Revised_Quote__c = true;
        update quote1;


        qli2.Budget__c = qli2.Budget__c  + 10;
        // qli2.Description = 'test description';
        qli2.Placement_Name__c = 'test test test'; // US-0009038 to cuase error because description field is skipped in trigger validation 
        // start: to coverage old code
        ioJunction.Quote_LineItem__c = qli1.Id;
        update ioJunction;
         // end: to coverage old code

        //test update
        Database.SaveResult[] updateResultList = Database.update(new List<QuoteLineItem>{qli1, qli2, qli3}, false);

        System.assertEquals(true, updateResultList[0].isSuccess());

        System.assertEquals(false, updateResultList[1].isSuccess());
        System.assertEquals(true,updateResultList[1].getErrors()[0].getMessage().contains(System.Label.Error_Revised_Quote_Line_Item_Can_Not_Be_Updated));

        System.assertEquals(true, updateResultList[2].isSuccess());

        //test delete
        Database.DeleteResult[] deleteResultList = Database.delete(new List<QuoteLineItem>{qli1, qli2, qli3}, false);

        System.assertEquals(true, deleteResultList[0].isSuccess());

        System.assertEquals(false, deleteResultList[1].isSuccess());
        System.assertEquals(System.Label.Error_Revised_Quote_Line_Item_Can_Not_Be_Deleted, deleteResultList[1].getErrors()[0].getMessage());

        System.assertEquals(true, deleteResultList[2].isSuccess());

    }

    /*****************************************************************************************************************************
    @ Method:       testSkipPreventingDeletingOrUpdatingQli
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008517 test method GW_QuoteLineItem.preventDeletingOrUpdatingQli
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.10.2020 / Sophal Noch / Created the class.
    @*****************************************************************************************************************************/
    static testMethod void testSkipPreventingDeletingOrUpdatingQli() {
        setUpQuoteLineItem();

        Date newValidDate = Date.today();
        qli2.until_Date__c = newValidDate; // so today in between qli2 start date and qli2 end date. start date <= today >= end date.

        insert new List<QuoteLineItem>{qli1, qli2, qli3};

        // start: to coverage old code
        ioJunction.Quote_LineItem__c = qli1.Id;
        update ioJunction;
         // end: to coverage old code
        

        // 03.08.2022 / Chetra Sarom / US-0009038 :
        // Ad_Product__c initAdProd = [Select Id from Ad_Product__c where Opportunity__c =: opp1.Id Limit 1];

        // qli2.AdProduct__c = initAdProd.Id;
        // qli2.until_date__c = qli2.until_date__c.addDays(1);
        // qli2.Budget__c = qli2.Budget__c + 10;

        // //test update

        // Database.SaveResult[] updateResultList = Database.update(new List<QuoteLineItem>{qli1, qli2, qli3}, false);

        // System.assertEquals(true, updateResultList[0].isSuccess());

        // System.assertEquals(true, updateResultList[1].isSuccess());

        // System.assertEquals(true, updateResultList[2].isSuccess());

        Test.startTest();  // 03.08.2022 / Chetra Sarom / US-0009038 

        qli2.until_date__c = qli2.until_date__c.addDays(1);
        qli2.Budget__c = qli2.Budget__c + 10;

        //test delete
        Database.DeleteResult[] deleteResultList = Database.delete(new List<QuoteLineItem>{qli2}, false);
        System.assertEquals(false, deleteResultList[0].isSuccess());
        System.assertEquals(System.Label.Error_Revised_Quote_Line_Item_Can_Not_Be_Deleted, deleteResultList[0].getErrors()[0].getMessage());

        Test.stopTest();
    }

    //US-0008726 Sophal 16/12/2020
    static testMethod void testCopyQlinesToAP() {
        setUpQuoteLineItem();

        bp.ByPass_PrimaryQuoteRule__c = true; // US-0008988
        bp.byPass_Trigger__c = true; // 04.11.2022 / Sophal Noch / US-001247
        update bp;

        quote1.Primary_Quote__c = true;
        quote1.Is_Revised_Quote__c = false;

        // Test.startTest();  // 04.11.2022 / Sophal Noch / US-0012478

        update quote1;

        bp.byPass_Trigger__c = false; // 04.11.2022 / Sophal Noch / US-0012478
        update bp;

        Test.startTest(); // 03.08.2022 / Chetra Sarom / US-0009038

        insert new List<QuoteLineItem>{qli1, qli2, qli3};

        qli3.until_date__c = qli3.until_date__c.addDays(1);
        update qli3;

        Test.stopTest();

    }

    //US-0008726 Sophal 16/12/2020
    static testMethod void testUpdateIOLineItemWhenMediaPlanIsNotNull() {
        setUpQuoteLineItem();

        bp.ByPass_Validation__c = true; // US-0008886 / Sophal/ 29.12.2020
        update bp;

        Test.startTest();  // 04.11.2022 / Sophal Noch / US-0012478

        quote1.Primary_Quote__c = false;
        quote1.Is_Revised_Quote__c = false;
        quote1.Status = 'Approved'; 
        update quote1;
        insert new List<QuoteLineItem>{qli1, qli2, qli3};

        ioJunction.Quote_LineItem__c = qli1.Id;
        update ioJunction;

        Media_Plan__c mediaPlan = new Media_Plan__c(Name = 'test',IsRevision__c =false);
        insert mediaPlan;
        quote1.Media_Plan__c = mediaPlan.Id;
        update quote1;
        
        qli1.SalesPriceNet__c = 1234567;
        update qli1;
        delete qli1;

        Test.stopTest();  // 04.11.2022 / Sophal Noch / US-0012478

    }

    /*****************************************************************************************************************************
    @ Method:   testDeleteQuotelineitemWithAdProductBookedToDFP
    @ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:	US-0008866
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.12.2020 / Sophal Noch / US-0008866 Created the method.
    @                 test method for GW_QuoteLineItem.preventDeletingOrUpdatingQli, GW_QuoteLineItem.validateAdproductLookup
    *****************************************************************************************************************************/
    static testMethod void testDeleteQuotelineitemWithAdProductBookedToDFP() {
        setUpQuoteLineItem();

        quote1.Primary_Quote__c = false;
        quote1.Is_Revised_Quote__c = false;
        quote1.IO__c = null;
        update quote1;

        validStartDate = Date.today().addMonths(1);
        validEndDate = validStartDate.addMonths(1);

        qli1.from_date__c = validStartDate;
        qli1.until_date__c = validEndDate;

        qli2.from_date__c = validStartDate;
        qli2.until_date__c = validEndDate;

        qli3.from_date__c = validStartDate;
        qli3.until_date__c = validEndDate;

        List<QuoteLineItem> listQliToInsert = new  List<QuoteLineItem>{qli1, qli2, qli3};
        insert listQliToInsert;
        quote1.Primary_Quote__c = true;

        Test.startTest(); // 04.11.2022 / Sophal Noch / US-0012478
        update quote1;

        List<Ad_Product__c> listAdProd = [Select Id,Quote_Line_Item__c From Ad_Product__c Where Quote_Line_Item__c IN: listQliToInsert Order By Quote_Line_Item__c ASC];

        System.assertEquals(listQliToInsert.size(), listAdProd.size());
        System.assertEquals(listAdProd[0].Quote_Line_Item__c, qli1.Id);

        listAdProd[0].Ad_Id__c = '1234556'; // ad_product__c.Ad_Id__c can not be delete if it is not empty.
        update listAdProd[0];

        // Test.startTest(); // 03.08.2022 / Chetra Sarom / US-0009038

        Database.DeleteResult[] deleteResultList = Database.delete(listQliToInsert, false);
        System.assertEquals(false, deleteResultList[0].isSuccess()); // false
        System.assertEquals(Label.Error_QuoteLineItem_Cannot_Be_Deleted_When_AdProduct_Has_Been_Booked, deleteResultList[0].getErrors()[0].getMessage()); // false

        System.assertEquals(true, deleteResultList[1].isSuccess()); // true
        System.assertEquals(true, deleteResultList[2].isSuccess()); // true


        Database.DeleteResult[] deleteAdProductResult = Database.delete(new List<Ad_Product__c>{listAdProd[0]}, false);
        System.assertEquals(false, deleteAdProductResult[0].isSuccess()); // false
        System.assertEquals(Label.Error_AdProduct_Cannot_Be_Deleted_When_It_Has_Been_Booked, deleteAdProductResult[0].getErrors()[0].getMessage()); // false

        Test.stopTest();


    }

    /*****************************************************************************************************************************
    @ Method:   testQuotelineitemInSameQuoteHasDuplicateAdProductId
    @ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:	US-0008866
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.12.2020 / Sophal Noch / Created the method.
    @                 test method for GW_QuoteLineItem.validateAdproductLookup
    *****************************************************************************************************************************/
    static testMethod void testQuotelineitemInSameQuoteHasDuplicateAdProductId() {
        
        setUpQuoteLineItem();

        quote1.Primary_Quote__c = false;
        quote1.Is_Revised_Quote__c = false;
        quote1.IO__c = null;
        update quote1;

        // validStartDate = Date.today().addMonths(1);
        // validEndDate = validStartDate.addMonths(1);
        // 04.11.2022 / Sophal Noch / US-0012478 :
        validStartDate = Date.today().addDays(1);
        validEndDate = validStartDate.addDays(1);

        qli1.from_date__c = validStartDate;
        qli1.until_date__c = validEndDate;

        qli2.from_date__c = validStartDate;
        qli2.until_date__c = validEndDate;

        qli3.from_date__c = validStartDate;
        qli3.until_date__c = validEndDate;

        List<QuoteLineItem> listQliToInsert = new  List<QuoteLineItem>{qli1, qli2, qli3};
        insert listQliToInsert;

        quote1.Primary_Quote__c = true;
        Test.startTest();  // 04.11.2022 / Sophal Noch / US-0012478
        update quote1;

        List<Ad_Product__c> listAdProd = [Select Id,Quote_Line_Item__c From Ad_Product__c Where Quote_Line_Item__c IN: listQliToInsert Order By Quote_Line_Item__c ASC];

        System.assertEquals(listQliToInsert.size(), listAdProd.size());


        QuoteLineItem qli4 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli4.Budget__c = 30;
        qli4.from_date__c = validStartDate;
        qli4.until_date__c = validEndDate;
        qli4.AdProduct__c = listAdProd[2].Id;

        Database.SaveResult[] insertResultList = Database.insert(new List<QuoteLineItem>{qli4}, false);

        System.assertEquals(false, insertResultList[0].isSuccess()); // false because one Quotelineitem.AdProduct__c can not have duplicate value in the same Quote
        Test.stopTest(); // 04.11.2022 / Sophal Noch / US-0012478
    }

    /*****************************************************************************************************************************
    @ Method:   testQuotelineitemHasTheSameAdProdFromOtherOpportunity
    @ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:	US-0008866
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.12.2020 / Sophal Noch / Created the method.
    @                 test method for GW_QuoteLineItem.validateAdproductLookup
    *****************************************************************************************************************************/
    static testMethod void testQuotelineitemHasTheSameAdProdFromOtherOpportunity() {

        setUpQuoteLineItem();

        bp.byPass_WFRule__c = true;  // Sophal/ 26.04.2021 / US-0009456 byPass process builder 'Process Builder - eBay Ads - Opportunity'
        update bp;

        quote1.Primary_Quote__c = false;
        quote1.Is_Revised_Quote__c = false;
        quote1.IO__c = null;

        Test.startTest(); // 04.11.2022 / Sophal Noch / US-0012478

        update quote1;

        // validStartDate = Date.today().addMonths(1);
        // validEndDate = validStartDate.addMonths(1);
        // 04.11.2022 / Sophal Noch / US-0012478 :
        validStartDate = Date.today().addDays(1);
        validEndDate = validStartDate.addDays(1);
        

        qli1.from_date__c = validStartDate;
        qli1.until_date__c = validEndDate;

        qli2.from_date__c = validStartDate;
        qli2.until_date__c = validEndDate;

        qli3.from_date__c = validStartDate;
        qli3.until_date__c = validEndDate;

        List<QuoteLineItem> listQliToInsert = new  List<QuoteLineItem>{qli1, qli2, qli3};
        insert listQliToInsert;

        quote1.Primary_Quote__c = true;
        update quote1;

        List<QuoteLineItem> listQliQuery = [Select Id, AdProduct__c From QuoteLineItem Where Id =: listQliToInsert];

        List<Ad_Product__c> listAdProd = [Select Id,Quote_Line_Item__c From Ad_Product__c Where Quote_Line_Item__c IN: listQliToInsert Order By Quote_Line_Item__c ASC];

        System.assertEquals(listQliToInsert.size(), listAdProd.size());

        System.assertEquals(listAdProd[0].Id, listQliQuery[0].AdProduct__c);
        System.assertEquals(listAdProd[1].Id, listQliQuery[1].AdProduct__c);
        System.assertEquals(listAdProd[2].Id, listQliQuery[2].AdProduct__c);

        System.assertEquals(qli1.Id, listAdProd[0].Quote_Line_Item__c);
        System.assertEquals(qli2.Id, listAdProd[1].Quote_Line_Item__c);
        System.assertEquals(qli3.Id, listAdProd[2].Quote_Line_Item__c);

        // account.Country_Code__c = 'US';
        // update account;

        Id oppDirectRt = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id;

        // Account agency = generateAccount();
        // agency.RecordTypeId = ApexUtil.getRecordTypeByName('Account','Agency').Id;
        // agency.Country_Code__c = 'US';
        // insert agency;

        // 04.11.2022 / Sophal Noch / US-0012478 : disable trigger to save permformance
        bp.byPass_Trigger__c = true;
        update bp;

        Opportunity opp2 = new Opportunity(
                Name = 'Opp 2',
                Amount = 100,
                StageName = 'Qualified Meeting',
                CloseDate = Date.newInstance( currentYear, 1, 1),
                Start_Date__c = startDate,
                End_Date__c = endDate,
                accountId = account.Id
                // Agency__c = agency.Id,
                // RecordTypeId = oppDirectRt,
                // Product_line__c = '10084'
        );

        // Test.startTest(); // 03.08.2022 / Chetra Sarom / US-0009038

        insert opp2;

        Id book1Id = Test.getStandardPriceBookId();


        Id ebayRecId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;

        Quote quote2 = new Quote(Name = 'quote 2', Status= 'Draft', OpportunityId = opp2.Id, Pricebook2Id = book1Id, Is_Revised_Quote__c = false, RecordTypeId = ebayRecId, Primary_Quote__c = false);
        quote2.Primary_Quote__c = true;
        insert quote2;
        
        
        // insert quote2;
        
        // quote2.Status = 'Approved';
        // quote2.dually_signed__c = true;
        // quote2.Primary_Quote__c = true;
        // update  quote2;



        QuoteLineItem quote2Qli1 = generateQuoteLinItem( quote2.id, prod1.id, pbe1.id);
        quote2Qli1.AdProduct__c = listAdProd[0].Id;

        // 04.11.2022 / Sophal Noch / US-0012478 :
        // validStartDate = Date.today().addMonths(1);
        // validEndDate = validStartDate.addMonths(1);

        quote2Qli1.Budget__c = 10;
        quote2Qli1.from_date__c = validStartDate;
        quote2Qli1.until_date__c = validEndDate;

        bp.byPass_Trigger__c = false;  // 04.11.2022 / Sophal Noch / US-0012478 : enable back to validation the logic still work below
        update bp;
    
        // Test.startTest();
        insert quote2Qli1;
        // Test.stopTest();

         // 04.11.2022 / Sophal Noch / US-0012478 : no need to do system asertNotEqual below, it is not neccessary
        // QuoteLineItem quote2Qli1Query1 = [Select Id, AdProduct__c From QuoteLineItem Where Id =: quote2Qli1.Id];
        // System.assertNotEquals(listAdProd[0].Id, quote2Qli1Query1.AdProduct__c); // not equal because one AdProduct Id must be belong to one opportunity only

        quote2Qli1.AdProduct__c = listAdProd[0].Id;
        update quote2Qli1;

        Test.stopTest();  // 04.11.2022 / Sophal Noch / US-0012478

        QuoteLineItem quote2Qli1Query2 = [Select Id, AdProduct__c From QuoteLineItem Where Id =: quote2Qli1.Id];
        System.assertNotEquals(listAdProd[0].Id, quote2Qli1Query2.AdProduct__c); // not equal because one AdProduct Id must be belong to one opportunity only
        System.assertEquals(null, quote2Qli1Query2.AdProduct__c);  //  equal to null

        // Test.stopTest();
    }

    /*****************************************************************************************************************************
    @ Method:   testSyncNewRevisedQliToAdProdWhenQliIsInThePast
    @ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:	US-0008517, US-0008866
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.12.2020 / Sophal Noch / Created the method.
    @                 test method for GW_QuoteLineItem.preventDeletingOrUpdatingQli
    *****************************************************************************************************************************/
    static testMethod void testSyncNewRevisedQliToAdProdWhenQliIsInThePast() {
        setUpQuoteLineItem();

        quote1.Primary_Quote__c = true;
        
        Test.startTest(); // 04.11.2022 / Sophal Noch / US-0012478
        update quote1;

        Id book1Id = Test.getStandardPriceBookId();

        Id ebayRecId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
    
        Quote quote2 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp1.Id, Pricebook2Id = book1Id);
        quote2.Primary_Quote__c = false;
        quote2.Is_Revised_Quote__c = false;
        quote2.Description = null;
        quote2.RecordTypeId = ebayRecId;
        insert quote2;
        

        invalidStartDate = Date.today().addMonths(-5);
        // invalidEndDate = invalidStartDate.addMonths(1);
        invalidEndDate = invalidStartDate.addDays(1);  // 04.11.2022 / Sophal Noch / US-0012478


        Quotelineitem qli1ForQuote2 = generateQuoteLinItem( quote2.id, prod1.id, pbe1.id);
        qli1ForQuote2.Budget__c = 10;
        qli1ForQuote2.from_date__c = invalidStartDate;
        qli1ForQuote2.until_date__c = invalidEndDate;
        insert qli1ForQuote2;

        // Test.startTest();

        quote2.Is_Revised_Quote__c = true;
        update quote2;

        // qli1ForQuote2.Description = 'Test test';
        qli1ForQuote2.Placement_Name__c = 'test test test'; // US-0009038 to cuase error because description field is skipped in trigger validation 

        //modify field description will not allow in revised quotelineitem
        Database.SaveResult[] updateResultList = Database.update(new List<QuoteLineItem>{qli1ForQuote2}, false);

        System.assertEquals(false, updateResultList[0].isSuccess());
        System.assertEquals(true,updateResultList[0].getErrors()[0].getMessage().contains(System.Label.Error_Revised_Quote_Line_Item_Can_Not_Be_Updated));


        bp.byPass_WFRule__c = true;  // Sophal/ 26.04.2021 / US-0009456 byPass process builder 'Process Builder - eBay Ads - Opportunity'
        update bp;

        //modify field adproduct__c in revised quotelineitem is allowed because it is for syncing purpose
        quote2.Primary_Quote__c = true;

        update quote2;

        Test.stopTest(); // 04.11.2022 / Sophal Noch / US-0012478

        // Database.SaveResult[] updateQuoteResultList = Database.update(new List<Quote>{quote2}, false);
        // System.assertEquals(true, updateQuoteResultList[0].isSuccess());

        List<Ad_Product__c> listAdProd = [Select Id,Quote_Line_Item__r.QuoteId from Ad_Product__c Where Opportunity__c =: opp1.Id];
        System.assertEquals(1, listAdProd.size());

        System.assertEquals(quote2.Id, listAdProd[0].Quote_Line_Item__r.QuoteId);

        // Test.stopTest();

    }

    /*****************************************************************************************************************************
    @ Method:       testUpdatingWhenStartDateInPastAndEndDateInFuture
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0009456 test method GW_QuoteLineItem.preventDeletingOrUpdatingQli
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  26.04.2021 / Sophal Noch / update the method.
    @*****************************************************************************************************************************/
    static testMethod void testUpdatingWhenStartDateInPastAndEndDateInFuture() {
        setUpQuoteLineItem();

        quote1.Is_Revised_Quote__c = false;
        update quote1;


        Date pastStartDate = Date.today().addMonths(-1);
        Date futureEndDate = Date.today().addMonths(1);

        String billingCate = 'CPM';


        qli2.from_date__c = pastStartDate;
        qli2.until_date__c = futureEndDate;
        qli2.billing_category__c = billingCate;

        insert new List<QuoteLineItem>{qli1, qli2, qli3};

        quote1.Is_Revised_Quote__c = true;
        update quote1;

        qli2.from_date__c = qli2.from_date__c.addMonths(1); 

        //test update to get error
        Database.SaveResult[] updateResultList = Database.update(new List<QuoteLineItem>{qli1, qli2, qli3}, false);

        System.assertEquals(true, updateResultList[0].isSuccess());

        
        // 03.08.2022 / Chetra Sarom / US-0009038 :
        // System.assertEquals(false, updateResultList[1].isSuccess());
        // System.assertEquals(true,updateResultList[1].getErrors()[0].getMessage().contains(System.Label.Error_Revised_QLI_Can_Not_Be_Updated_DueTo_FromDate));
        System.assertEquals(true, updateResultList[1].isSuccess()); // 03.08.2022 / Chetra Sarom / US-0009038

        System.assertEquals(true, updateResultList[2].isSuccess());


         //test update to get error
        qli2.from_date__c = pastStartDate; // update back orignal from_date__c
        qli2.billing_category__c = 'CPC'; // change billing_category
        updateResultList = Database.update(new List<QuoteLineItem>{qli2}, false);

       
        System.assertEquals(false, updateResultList[0].isSuccess());
        System.assertEquals(true,updateResultList[0].getErrors()[0].getMessage().contains(System.Label.Error_Revised_QLI_Can_Not_Be_Updated_DueTo_FromDate));

       
         //test update to get success

        qli2.from_date__c = pastStartDate; // update back orignal from_date__c
        qli2.billing_category__c = billingCate; // change back to original billing_category
        qli2.budget__c += 100;

        updateResultList = Database.update(new List<QuoteLineItem>{qli2}, false);
        
        System.assertEquals(true, updateResultList[0].isSuccess());

    }


    /*****************************************************************************************************************************
    @ Method:       testUpdatingWhenEndDateIsToday
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0009456 test method GW_QuoteLineItem.preventDeletingOrUpdatingQli
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  26.04.2021 / Sophal Noch / update the method.
    @*****************************************************************************************************************************/
    static testMethod void testUpdatingWhenEndDateIsToday() {
        setUpQuoteLineItem();

        quote1.Is_Revised_Quote__c = false;
        update quote1;


        Date pastStartDate = Date.today().addMonths(-1);
        Date todayEndDate = Date.today();

        String billingCate = 'CPM';



        qli2.from_date__c = pastStartDate;
        qli2.until_date__c = todayEndDate;
        qli2.billing_category__c = billingCate;

        insert new List<QuoteLineItem>{qli1, qli2, qli3};

        Test.startTest();  // 04.11.2022 / Sophal Noch / US-0012478

        quote1.Is_Revised_Quote__c = true;
        update quote1;

        qli2.until_date__c = todayEndDate.addMonths(-1);

       

        //test update to get error
        Database.SaveResult[] updateResultList = Database.update(new List<QuoteLineItem>{qli1, qli2, qli3}, false);

        System.assertEquals(true, updateResultList[0].isSuccess());

        // 03.08.2022 / Chetra Sarom / US-0009038 :
        // System.assertEquals(false, updateResultList[1].isSuccess());
        // // Sophal/ 26.04.2021 / US-0009456 if end date is today, you can increase it but you can not decrease it.
        // System.assertEquals(true,updateResultList[1].getErrors()[0].getMessage().contains(System.Label.Error_Revised_QLI_Can_Not_Be_Updated_DueTo_EndDateIsToday));
        System.assertEquals(true, updateResultList[1].isSuccess()); // 03.08.2022 / Chetra Sarom / US-0009038


        System.assertEquals(true, updateResultList[2].isSuccess());

         //test update to get success by updating other field beside enddate

         qli2.until_date__c = todayEndDate; //reset back to original value
         qli2.budget__c = qli2.budget__c+10;

        updateResultList = Database.update(new List<QuoteLineItem>{qli2}, false);
         
         System.assertEquals(true, updateResultList[0].isSuccess());


         //test update to get success by updating other field increasing enddate

        qli2.until_date__c = todayEndDate.addMonths(1);

        updateResultList = Database.update(new List<QuoteLineItem>{qli2}, false);
        
        System.assertEquals(true, updateResultList[0].isSuccess());

        Test.stopTest();  // 04.11.2022 / Sophal Noch / US-0012478

    }



}