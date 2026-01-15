/*****************************************************************************************************************************************************************
@ Class:         AdRevenueDailyTriggerHandlerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0008300 test class for AdRevenueDailyTriggerHandler
----------------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history:  31.12.2020 / Sophal Noch / Created the class.
@ Change history:  12.01.2024 / Vimean Heng / Workflow rule not execute "assign PVP ID for AD Renvenue Daily".
***********************************************************************************************************************************************************/
@isTest
private without sharing class AdRevenueDailyTriggerHandlerTest {

    private static Account seller;
    private static Opportunity opp;

    private static Date startDate;
    private static Date endDate;

    private static Quote quote1;
    private static Quote quote2;

    private static Site__c site;
    private static Product2 prod1;

    private static Id book1Id;

    private static PriceBookEntry pbe1;

    private static QuoteLineItem qli1;

    private static byPass__c bp;

    private static QuoteLineItem qliP2Comp1;
    private static QuoteLineItem qliP2Comp2;
    private static QuoteLineItem qliP4Comp1;
    private static QuoteLineItem qliP4Comp2;

    // setup method
    static void setUpData(){


        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false, byPass_WFRule__c = false);
        insert bp;

        AdRevenueDailyTriggerHandler.runAsFuture = false;

        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'Advertiser');
        seller = sellers[0];
        seller.Record_Type_Text__c = 'Advertiser';//avoid validation rule error
        update seller;

        opp = new Opportunity(AccountId = seller.Id, Name = 'Test Opp',StageName='Qualified Meeting',CloseDate=Date.newInstance( 2021, 1, 1), RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id);
        insert opp;

        site = TST_DataGenerator.generateSite();
        insert site;

        prod1 = TST_DataGenerator.generateProduct(site.Id);
        insert prod1;

        book1Id = Test.getStandardPriceBookId();
        
        pbe1 = TST_DataGenerator.generatePricebookEntry(prod1.id, book1Id);
        insert pbe1;

        quote1 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp.Id, Pricebook2Id = book1Id, Is_Revised_Quote__c = false, Primary_Quote__c = true);

        insert quote1;

        quote1.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote1.Primary_Quote__c= true;
        update quote1;
        

        qli1 = TST_DataGenerator.generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = 100;
        qli1.from_Date__c = Date.today().addMonths(-1);
        qli1.until_Date__c = Date.today().addMonths(1);
        insert qli1;


        
        
    }

    static testMethod void testUpdateDeliverySummeDailyFixPrice(){

        setUpData();
        Ad_Product__c adProd = [Select Id, Package_line_item__c, Quote_Line_Item__c,Product2__r.RecordType.DeveloperName,(Select Id, Delivered_AI__c From Ads_Revenue_Daily__r  Order by Day__c ASC) From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id];
        System.assertNotEquals(null, adProd.Id);

        opp.Order_Id__c = '1';
        update opp;
        adProd.Ad_Id__c = '1';
        adProd.Booked_Quantity__c = 1000;
        adProd.Quantity__c = 1000;
        adProd.Billing_Category__c = 'Fix Price';
        update adProd;

        Ad_Product__c adProdAfterQuery = [Select Id,Billing_Category__c From Ad_Product__c Where Id =: adProd.Id];
        System.assertEquals(('Fix Price'.toLowerCase()), (adProdAfterQuery.Billing_Category__c.toLowerCase()));

        Date today = System.today();
        List<Ad_Revenue_Daily__c> listDailyAfterUpdate = new List<Ad_Revenue_Daily__c>();

        for(Ad_Revenue_Daily__c eachDaily : adProd.Ads_Revenue_Daily__r){
            eachDaily.Delivered_AI__c = eachDaily.Delivered_AI__c == null ? 0 : eachDaily.Delivered_AI__c;
            eachDaily.Delivered_AI__c = Integer.valueOf(eachDaily.Delivered_AI__c) + 1;
        }
        update adProd.Ads_Revenue_Daily__r;

    
        listDailyAfterUpdate = [Select Id,Invoice_Quantity__c,Daily_quantity__c,Delivered_Sum__c, Day__c From Ad_Revenue_Daily__c Where Ad_Product__c =:adProd.Id Order by Day__c ASC];
        System.assertEquals(1, listDailyAfterUpdate[0].Daily_quantity__c);
        System.assertEquals(1, listDailyAfterUpdate[0].Invoice_Quantity__c);
        System.assertEquals(1, listDailyAfterUpdate[0].Delivered_Sum__c);

        Decimal dailyQuantityOfFixPrice = listDailyAfterUpdate[0].Daily_quantity__c;
        Decimal deliveredSum = dailyQuantityOfFixPrice;
        
        for(Ad_Revenue_Daily__c eachDaily : listDailyAfterUpdate){

            if(eachDaily.Day__c <= today){
                System.assertEquals(1, eachDaily.Invoice_Quantity__c);
                System.assertEquals(deliveredSum, eachDaily.Delivered_Sum__c);
                deliveredSum = deliveredSum + dailyQuantityOfFixPrice;

            }else{
                System.assertEquals(null, eachDaily.Invoice_Quantity__c);
                System.assertEquals(null, eachDaily.Delivered_Sum__c);
            }
           
        }

        
       // test future method
        for(Ad_Revenue_Daily__c eachDaily : adProd.Ads_Revenue_Daily__r){

            // make trigger run again
            eachDaily.Delivered_AI__c = eachDaily.Delivered_AI__c == null ? 0 : eachDaily.Delivered_AI__c;
            eachDaily.Delivered_AI__c = Integer.valueOf(eachDaily.Delivered_AI__c) + 1;
            eachDaily.Delivered_Sum__c = null; 
        }
        AdRevenueDailyTriggerHandler.runAsFuture = true;
        Test.startTest();
            update adProd.Ads_Revenue_Daily__r;
        Test.stopTest();

        listDailyAfterUpdate.clear();
        listDailyAfterUpdate = [Select Id,Invoice_Quantity__c,Daily_quantity__c,Delivered_Sum__c,Day__c From Ad_Revenue_Daily__c Where Ad_Product__c =:adProd.Id Order by Day__c ASC];
        System.assertEquals(1, listDailyAfterUpdate[0].Daily_quantity__c);
        System.assertEquals(1, listDailyAfterUpdate[0].Invoice_Quantity__c);
        System.assertEquals(1, listDailyAfterUpdate[0].Delivered_Sum__c);

        dailyQuantityOfFixPrice = listDailyAfterUpdate[0].Daily_quantity__c;
        deliveredSum = dailyQuantityOfFixPrice;

        for(Ad_Revenue_Daily__c eachDaily : listDailyAfterUpdate){

            if(eachDaily.Day__c <= today){
                System.assertEquals(1, eachDaily.Invoice_Quantity__c);
                System.assertEquals(deliveredSum, eachDaily.Delivered_Sum__c);
                deliveredSum = deliveredSum + dailyQuantityOfFixPrice;

            }else{
                System.assertEquals(null, eachDaily.Invoice_Quantity__c);
                System.assertEquals(null, eachDaily.Delivered_Sum__c);
            }
        }


    }


    static testMethod void testUpdateDeliverySummeDailyCPM(){

        setUpData();
        Ad_Product__c adProd = [Select Id,(Select Id From Ads_Revenue_Daily__r  Order by Day__c ASC) From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id];
        System.assertNotEquals(null, adProd.Id);

        opp.Order_Id__c = '1';
        update opp;
        adProd.Ad_Id__c = '1';
        adProd.Booked_Quantity__c = 1000;
        adProd.Quantity__c = 1000;
        adProd.Billing_Category__c = 'CPM';
        update adProd;

        Ad_Product__c adProdAfterQuery = [Select Id,Billing_Category__c From Ad_Product__c Where Id =: adProd.Id];
        System.assertEquals('CPM', adProdAfterQuery.Billing_Category__c);

        Date today = System.today();
        List<Ad_Revenue_Daily__c> listDailyAfterUpdate = new List<Ad_Revenue_Daily__c>();

        Decimal deliveredAiIncrement = 10;

        for(Ad_Revenue_Daily__c eachDaily : adProd.Ads_Revenue_Daily__r){
            eachDaily.Delivered_AI__c = deliveredAiIncrement;
        }
        update adProd.Ads_Revenue_Daily__r;

    
        listDailyAfterUpdate = [Select Id,Invoice_Quantity__c,Daily_quantity__c,Delivered_Sum__c, Booked_Quantity__c, Day__c From Ad_Revenue_Daily__c Where Ad_Product__c =:adProd.Id Order by Day__c ASC];
        System.assertEquals(deliveredAiIncrement, listDailyAfterUpdate[0].Daily_quantity__c);
        System.assertEquals(deliveredAiIncrement, listDailyAfterUpdate[0].Invoice_Quantity__c);
        System.assertEquals(deliveredAiIncrement, listDailyAfterUpdate[0].Delivered_Sum__c);

        Decimal dailyQuantityOfCmp = deliveredAiIncrement;
        Decimal deliveredSum = dailyQuantityOfCmp;
        
        for(Ad_Revenue_Daily__c eachDaily : listDailyAfterUpdate){

            if(eachDaily.Day__c <= today){

                System.assertEquals(dailyQuantityOfCmp, eachDaily.Invoice_Quantity__c);
                System.assertEquals(deliveredSum, eachDaily.Delivered_Sum__c);
                deliveredSum = deliveredSum + dailyQuantityOfCmp;

            }else{
                System.assertEquals(null, eachDaily.Invoice_Quantity__c);
                System.assertEquals(null, eachDaily.Delivered_Sum__c);
            }
           
        }


        // test future method
        deliveredAiIncrement = 43;
        for(Ad_Revenue_Daily__c eachDaily : adProd.Ads_Revenue_Daily__r){
            eachDaily.Delivered_AI__c = deliveredAiIncrement;
        }

        AdRevenueDailyTriggerHandler.runAsFuture = true;
        Test.startTest();
        update adProd.Ads_Revenue_Daily__r;
        Test.stopTest();

    
        listDailyAfterUpdate = [Select Id,Invoice_Quantity__c,Daily_quantity__c,Delivered_Sum__c, Booked_Quantity__c, Day__c From Ad_Revenue_Daily__c Where Ad_Product__c =:adProd.Id Order by Day__c ASC];
        System.assertEquals(deliveredAiIncrement, listDailyAfterUpdate[0].Daily_quantity__c);
        System.assertEquals(deliveredAiIncrement, listDailyAfterUpdate[0].Invoice_Quantity__c);
        System.assertEquals(deliveredAiIncrement, listDailyAfterUpdate[0].Delivered_Sum__c);

        dailyQuantityOfCmp = deliveredAiIncrement;
        deliveredSum = dailyQuantityOfCmp;
        
        for(Ad_Revenue_Daily__c eachDaily : listDailyAfterUpdate){

            if(eachDaily.Day__c <= today){
                
                if (eachDaily.Booked_Quantity__c >= deliveredSum) {
                    System.assertEquals(dailyQuantityOfCmp, eachDaily.Invoice_Quantity__c);
                } else if (eachDaily.Booked_Quantity__c >= (deliveredSum - dailyQuantityOfCmp)) {
                    System.assertEquals((eachDaily.Booked_Quantity__c - (deliveredSum - dailyQuantityOfCmp)), eachDaily.Invoice_Quantity__c);
                }else{
                    System.assertEquals(0, eachDaily.Invoice_Quantity__c);
                }

                System.assertEquals(deliveredSum, eachDaily.Delivered_Sum__c);
                deliveredSum = deliveredSum + dailyQuantityOfCmp;

            }else{
                System.assertEquals(null, eachDaily.Invoice_Quantity__c);
                System.assertEquals(null, eachDaily.Delivered_Sum__c);
            }
           
        }
    
    }

    //@ Change history:  12.01.2024 / Vimean Heng / US-0014415 / Workflow rule not execute "assign PVP ID for AD Renvenue Daily".
    static testMethod void testUpdatePvpIdWhenAdProductHasAdId(){
        // Sophal / 27.08.2021 / US-0010259
        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false, byPass_WFRule__c = false);
        insert bp;

        AdRevenueDailyTriggerHandler.runAsFuture = false;

        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'Advertiser');
        seller = sellers[0];
        seller.Record_Type_Text__c = 'Advertiser';//avoid validation rule error
        update seller;

        opp = new Opportunity(AccountId = seller.Id, Name = 'Test Opp',StageName='Qualified Meeting',CloseDate=Date.newInstance( 2021, 1, 1), RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id);
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
        

        qli1 = TST_DataGenerator.generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = 100;
        qli1.from_Date__c = Date.today().addDays(-1);
        qli1.until_Date__c = Date.today().addDays(1);
        
        QuoteLineItem qli2 = TST_DataGenerator.generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli2.Budget__c = 100;
        qli2.from_Date__c = Date.today().addDays(-1);
        qli2.until_Date__c = Date.today().addDays(1);

        Test.startTest();
            AdProductTriggerHandler.RG_DML_CHUNK_LIMIT = 1;
            insert new List<QuoteLineItem>{qli1,qli2};
            qli1.Quantity__c = 1000;
            qli1.Billing_Category__c = 'CPM';
            
            update qli1;

            Ad_Product__c adProd = [Select Id,(Select Id, Delivered_AI__c From Ads_Revenue_Daily__r  Order by Day__c ASC) From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id];
            System.assertNotEquals(null, adProd.Id);

            //prod1.Callisto__c = true;
            //update prod1;

            opp.Order_Id__c = '1';
            update opp;

            //adProd.Ad_Id__c = '1';
            
            //update adProd;
        Test.stopTest();

        for(Ad_Revenue_Daily__c eachDaily : [Select Id, Day__c,Ad_Id__c,PVP_ID__c From Ad_Revenue_Daily__c Where Ad_Product__c =:adProd.Id Order by Day__c ASC]){

            String dateAsString = String.valueOfGmt(eachDaily.Day__c);
            dateAsString = dateAsString.split(' ')[0];
            System.assertEquals(dateAsString + eachDaily.Ad_Id__c, eachDaily.PVP_ID__c);
           
        }


    }

    //17/06/2022/ Sovantheany Dim / US-0011096 - ADS - Packages show incorrectly in Excel reports
    static void setUpData2(){
        byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false, byPass_WFRule__c = false);
        insert bp;

        AdRevenueDailyTriggerHandler.runAsFuture = false;

        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'Advertiser');
        Account seller = sellers[0];
        seller.Record_Type_Text__c = 'Advertiser';//avoid validation rule error
        update seller;

        Opportunity opp = new Opportunity(AccountId = seller.Id, Name = 'Test Opp',StageName='Qualified Meeting',CloseDate=Date.newInstance( 2021, 1, 1), RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id);
        insert opp;

        Id book1Id = Test.getStandardPriceBookId();
        
        quote2 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp.Id, Pricebook2Id = book1Id, Is_Revised_Quote__c = false, Primary_Quote__c = true);
        insert quote2;
        quote2.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote2.Primary_Quote__c= true;
        update quote2;

        RecordType rt_roDart6 = ApexUtil.getRecordTypeByName('Product2', 'DART6');
        RecordType rt_proPackage = ApexUtil.getRecordTypeByName('Product2', 'Package');

        Product2 product2Pk = TST_DataGenerator.generateProduct();
        product2Pk.RecordTypeId = rt_proPackage.Id;
        product2Pk.Name = 'package test';
        product2Pk.IsActive = true;
        Product2 product2Component1 = TST_DataGenerator.generateProduct();
        product2Component1.RecordTypeId = rt_roDart6.Id;
        product2Component1.IsActive = true;
        Product2 product2Component2 = TST_DataGenerator.generateProduct();
        product2Component2.RecordTypeId = rt_roDart6.Id;
        product2Component2.IsActive = true;

        insert new List<Product2>{product2Pk,product2Component1,product2Component2};

        PriceBookEntry pbe2Pk = TST_DataGenerator.generatePricebookEntry(product2Pk.Id,null);
        PriceBookEntry pbe2comp1 = TST_DataGenerator.generatePricebookEntry(product2Component1.Id,null);
        PriceBookEntry pbe2comp2 = TST_DataGenerator.generatePricebookEntry(product2Component2.Id,null);
        insert new List<PriceBookEntry>{pbe2Pk,pbe2comp1,pbe2comp2};

        Product_Package__c pp2comp1 = new Product_Package__c(Product__c=product2Component1.Id,Package_Product__c=product2Pk.Id);
        Product_Package__c pp2comp2 = new Product_Package__c(Product__c=product2Component2.Id,Package_Product__c=product2Pk.Id);

       insert new List<Product_Package__c>{pp2comp1,pp2comp2};

        QuoteLineItem qliP2Pk = createItem(quote2.Id, product2Pk.Id, pbe2Pk.Id, 20, 10);
        insert qliP2Pk;

        qliP2Comp1 = createItem(quote2.Id, product2Component1.Id, pbe2comp1.Id, 20, 10);
        qliP2Comp1.package_line_item__c = qliP2Pk.Id;
        qliP2Comp2 = createItem(quote2.Id, product2Component2.Id, pbe2comp2.Id, 20, 10);
        qliP2Comp2.package_line_item__c = qliP2Pk.Id;

        List<QuoteLineItem> childQli = new List<QuoteLineItem>{qliP2Comp1,qliP2Comp2};
        insert childQli;
    }

    private static QuoteLineItem createItem(String quoteId,String productId,String pbeId,Double qty,Decimal uPrice)
    {                
            return  new QuoteLineItem(
                from_Date__c =  date.newInstance(System.now().year(), System.now().month(), 1),
                until_Date__c = date.newInstance(System.now().year(), System.now().month(), 30),  
                Product2Id = productId,
                UnitPrice = uPrice,
                Quantity = qty,
                Quantity__c = qty,
                Check_Inventory__c = true,
                PricebookEntryId = pbeId,
                QuoteId = quoteId,
                Budget__c = 100
                );
    }

    static testMethod void testSumDeliveredAndClickRecord(){
        setUpData2();

        List<Ad_Revenue_Daily__c> adDaily = [Select Id From Ad_Revenue_Daily__c Where Ad_Product__r.Quote_Line_Item__r.QuoteId =: quote2.Id and Ad_Product__r.Package_line_item__c != null];
        
        System.assert(adDaily.size()>0);
        AdRevenueDailyTriggerHandler.runAsFuture = true;
        Test.startTest();
            Decimal deliveredAiIncrement = 10;
            Decimal clickRecord = 1;
            for(Ad_Revenue_Daily__c eachDaily : adDaily){
                eachDaily.Delivered_AI__c = deliveredAiIncrement;
                eachDaily.Clicks_Recorded__c = clickRecord;
            }
            update adDaily;
        	
        Test.stopTest();
        List<Ad_Revenue_Daily__c> mainPackage = [select Delivered_AI__c, Clicks_Recorded__c from Ad_Revenue_Daily__c where Ad_Product__r.Quote_Line_Item__r.QuoteId =: quote2.Id and Package_line_item__c = null and Day__c = TODAY];
        for(Ad_Revenue_Daily__c package1 : mainPackage){
            System.assertEquals(deliveredAiIncrement*2, package1.Delivered_AI__c);
            System.assertEquals(clickRecord*2, package1.Clicks_Recorded__c);
        }
    }


}