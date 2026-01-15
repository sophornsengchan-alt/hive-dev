/*****************************************************************************************************************************************************************
@ Class:         AdRevenueMonthlyTriggerHandlerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0008908 test class for AdRevenueMonthlyTriggerHandler
----------------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history:  08.02.2021 / Sophal Noch / Created the class.
@ Change history:  09.01.2024 / Vimean Heng / Fix validation rule.
***********************************************************************************************************************************************************/
@isTest(seeAllData = False)
private without sharing class AdRevenueMonthlyTriggerHandlerTest {
    
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

    private static byPass__c bp;

    //@ Change history:  09.01.2024 / Vimean Heng / US-0014415 / Fix validation rule.
    // setup method
    static void setUpData(){


        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false, byPass_WFRule__c = false);
        insert bp;

        AdRevenueMonthlyTriggerHandler.runAsFuture = false;

        //List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        //seller = sellers[0];
        seller = TST_DataGenerator.generateAccount();
        seller.Record_Type_Text__c = 'Advertiser';
        insert seller;
        /*
        opp = new Opportunity(AccountId = seller.Id, Name = 'Test Opp',StageName='Qualified Meeting',CloseDate=Date.newInstance( 2021, 1, 1));
        insert opp;
        */
        opp = TST_DataGenerator.generateOpp(seller.Id);
        opp.StageName = 'Qualified Meeting';
        insert opp;
        opp.Order_Id__c = '1';
        update opp;
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
        qli1.until_Date__c = Date.today().addMonths(11);
        insert qli1;  
        
    }

     @TestSetup
    static void setup(){
        setUpData();
    }

    @IsTest
    static void testUpdateDeliverySummeMonthlyFixPrice(){

        //setUpData();
        //insert qli1;

        //Ad_Product__c adProd = [Select Id,(Select Id, Delivered_AI__c From Ad_Revenue_Monthly__r  Order by Transaction_Date__c ASC) From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id];
        Ad_Product__c adProd = [Select Id,(Select Id, Delivered_AI__c From Ad_Revenue_Monthly__r  Order by Transaction_Date__c ASC) From Ad_Product__c Where Quote_Line_Item__r.Quote.name = 'q1'];
        System.assertNotEquals(null, adProd.Id, 'Ad Product should be created');

        adProd.Ad_Id__c = '1';
        adProd.Booked_Quantity__c = 1000;
        adProd.Quantity__c = 1000;
        adProd.Billing_Category__c = 'Fix Price';
        update adProd;

        Ad_Product__c adProdAfterQuery = [Select Id,Billing_Category__c From Ad_Product__c Where Id =: adProd.Id];
        System.assertEquals(('Fix Price'.toLowerCase()), (adProdAfterQuery.Billing_Category__c.toLowerCase()), 'Billing_Category__c should be Fix Price');

        Date today = System.today();
        List<Ad_Revenue_Monthly__c> listMonthlyAfterUpdate = new List<Ad_Revenue_Monthly__c>();

        for(Ad_Revenue_Monthly__c eachMonthly : adProd.Ad_Revenue_Monthly__r){
            eachMonthly.Delivered_AI__c = eachMonthly.Delivered_AI__c == null ? 0 : eachMonthly.Delivered_AI__c;
            eachMonthly.Delivered_AI__c = Integer.valueOf(eachMonthly.Delivered_AI__c) + 1;
        }
        update adProd.Ad_Revenue_Monthly__r;

        listMonthlyAfterUpdate = [Select Id,Invoice_Quantity__c,Monthly_Quantity__c,Delivered_Sum__c, Transaction_Date__c From Ad_Revenue_Monthly__c Where Ad_Product__c =:adProd.Id Order by Transaction_Date__c ASC];
        System.assertEquals(1, listMonthlyAfterUpdate[0].Monthly_Quantity__c, 'Monthly_Quantity__c should be 1');
        System.assertEquals(1, listMonthlyAfterUpdate[0].Invoice_Quantity__c, 'Invoice_Quantity__c should be 1');
        System.assertEquals(1, listMonthlyAfterUpdate[0].Delivered_Sum__c, 'Delivered_Sum__c should be 1');

        Decimal monthlyQuantityOfFixPrice = listMonthlyAfterUpdate[0].Monthly_Quantity__c;
        Decimal deliveredSum = monthlyQuantityOfFixPrice;
        
        for(Ad_Revenue_Monthly__c eachMonthly : listMonthlyAfterUpdate){

            //if(eachMonthly.Transaction_Date__c <= today){
                System.assertEquals(1, eachMonthly.Invoice_Quantity__c, 'Invoice_Quantity__c should be 1');
                System.assertEquals(deliveredSum, eachMonthly.Delivered_Sum__c, 'Delivered_Sum__c should be ' + deliveredSum);
                deliveredSum = deliveredSum + monthlyQuantityOfFixPrice;

            // }else{
            //     System.assertEquals(null, eachMonthly.Invoice_Quantity__c);
            //     System.assertEquals(null, eachMonthly.Delivered_Sum__c);
            // }
           
        }

        
       // test future method
        for(Ad_Revenue_Monthly__c eachMonthly : adProd.Ad_Revenue_Monthly__r){

            // make trigger run again
            eachMonthly.Delivered_AI__c = eachMonthly.Delivered_AI__c == null ? 0 : eachMonthly.Delivered_AI__c;
            eachMonthly.Delivered_AI__c = Integer.valueOf(eachMonthly.Delivered_AI__c) + 1;
            eachMonthly.Delivered_Sum__c = null; 
        }
        AdRevenueMonthlyTriggerHandler.runAsFuture = true;
        Test.startTest();
            update adProd.Ad_Revenue_Monthly__r;
        Test.stopTest();

        listMonthlyAfterUpdate.clear();
        listMonthlyAfterUpdate = [Select Id,Invoice_Quantity__c,Monthly_Quantity__c,Delivered_Sum__c,Transaction_Date__c From Ad_Revenue_Monthly__c Where Ad_Product__c =:adProd.Id Order by Transaction_Date__c ASC];
        System.assertEquals(1, listMonthlyAfterUpdate[0].Monthly_Quantity__c, 'Monthly_Quantity__c should be 1');
        System.assertEquals(1, listMonthlyAfterUpdate[0].Invoice_Quantity__c, 'Invoice_Quantity__c should be 1');
        System.assertEquals(1, listMonthlyAfterUpdate[0].Delivered_Sum__c, 'Delivered_Sum__c should be 1');

        monthlyQuantityOfFixPrice = listMonthlyAfterUpdate[0].Monthly_Quantity__c;
        deliveredSum = monthlyQuantityOfFixPrice;

        for(Ad_Revenue_Monthly__c eachMonthly : listMonthlyAfterUpdate){

            // if(eachMonthly.Transaction_Date__c <= today){
                System.assertEquals(1, eachMonthly.Invoice_Quantity__c, 'Invoice_Quantity__c should be 1');
                System.assertEquals(deliveredSum, eachMonthly.Delivered_Sum__c, '');
                deliveredSum = deliveredSum + monthlyQuantityOfFixPrice;

            // }else{
            //     System.assertEquals(null, eachMonthly.Invoice_Quantity__c);
            //     System.assertEquals(null, eachMonthly.Delivered_Sum__c);
            // }
        }


    }


    @IsTest
    static void testUpdateDeliverySummeMonthlyCPM(){

        //setUpData();
        //insert qli1;

        Ad_Product__c adProd = [Select Id,(Select Id From Ad_Revenue_Monthly__r  Order by Transaction_Date__c ASC) From Ad_Product__c Where Quote_Line_Item__r.Quote.name = 'q1'];
        System.assertNotEquals(null, adProd.Id, 'Ad Product should be created');

        adProd.Ad_Id__c = '1';
        adProd.Booked_Quantity__c = 1000;
        adProd.Quantity__c = 1000;
        adProd.Billing_Category__c = 'CPM';
        update adProd;

        Ad_Product__c adProdAfterQuery = [Select Id,Billing_Category__c From Ad_Product__c Where Id =: adProd.Id];
        System.assertEquals('CPM', adProdAfterQuery.Billing_Category__c,' Billing_Category__c should be CPM');

        Date today = System.today();
        List<Ad_Revenue_Monthly__c> listMonthlyAfterUpdate = new List<Ad_Revenue_Monthly__c>();

        Decimal deliveredAiIncrement = 10;

        for(Ad_Revenue_Monthly__c eachMonthly : adProd.Ad_Revenue_Monthly__r){
            eachMonthly.Delivered_AI__c = deliveredAiIncrement;
        }
        update adProd.Ad_Revenue_Monthly__r;

    
        listMonthlyAfterUpdate = [Select Id,Invoice_Quantity__c,Monthly_Quantity__c,Delivered_Sum__c, Booked_Quantity__c, Transaction_Date__c From Ad_Revenue_Monthly__c Where Ad_Product__c =:adProd.Id Order by Transaction_Date__c ASC];
        System.assertEquals(deliveredAiIncrement, listMonthlyAfterUpdate[0].Monthly_Quantity__c, 'Monthly_Quantity__c should be ' + deliveredAiIncrement);
        System.assertEquals(deliveredAiIncrement, listMonthlyAfterUpdate[0].Invoice_Quantity__c, 'Invoice_Quantity__c should be ' + deliveredAiIncrement);
        System.assertEquals(deliveredAiIncrement, listMonthlyAfterUpdate[0].Delivered_Sum__c, 'Delivered_Sum__c should be ' + deliveredAiIncrement);

        Decimal monthlyQuantityOfCmp = deliveredAiIncrement;
        Decimal deliveredSum = monthlyQuantityOfCmp;
        
        for(Ad_Revenue_Monthly__c eachMonthly : listMonthlyAfterUpdate){

            // if(eachMonthly.Transaction_Date__c <= today){

                if (eachMonthly.Booked_Quantity__c >= deliveredSum) {

                    System.assertEquals(monthlyQuantityOfCmp, eachMonthly.Invoice_Quantity__c, 'Invoice_Quantity__c should be ' + monthlyQuantityOfCmp);
                    System.assertEquals(deliveredSum, eachMonthly.Delivered_Sum__c, 'Delivered_Sum__c should be ' + deliveredSum);

                }else if (eachMonthly.Booked_Quantity__c >= (deliveredSum - monthlyQuantityOfCmp)) {
                    System.assertEquals((eachMonthly.Booked_Quantity__c - (deliveredSum - monthlyQuantityOfCmp)), eachMonthly.Invoice_Quantity__c, 'Invoice_Quantity__c should be ' + (eachMonthly.Booked_Quantity__c - (deliveredSum - monthlyQuantityOfCmp)));
                }else{
                    System.assertEquals(0, eachMonthly.Invoice_Quantity__c, 'Invoice_Quantity__c should be 0');
                }


                
                deliveredSum = deliveredSum + monthlyQuantityOfCmp;

            // }else{
            //     System.assertEquals(null, eachMonthly.Invoice_Quantity__c);
            //     System.assertEquals(null, eachMonthly.Delivered_Sum__c);
            // }
           
        }


        // test future method
        deliveredAiIncrement = 43;
        for(Ad_Revenue_Monthly__c eachMonthly : adProd.Ad_Revenue_Monthly__r){
            eachMonthly.Delivered_AI__c = deliveredAiIncrement;
        }

        AdRevenueMonthlyTriggerHandler.runAsFuture = true;
        Test.startTest();
        update adProd.Ad_Revenue_Monthly__r;
        Test.stopTest();

    
        listMonthlyAfterUpdate = [Select Id,Invoice_Quantity__c,Monthly_Quantity__c,Delivered_Sum__c, Booked_Quantity__c, Transaction_Date__c From Ad_Revenue_Monthly__c Where Ad_Product__c =:adProd.Id Order by Transaction_Date__c ASC];
        System.assertEquals(deliveredAiIncrement, listMonthlyAfterUpdate[0].Monthly_Quantity__c, 'Monthly_Quantity__c should be ' + deliveredAiIncrement);
        System.assertEquals(deliveredAiIncrement, listMonthlyAfterUpdate[0].Invoice_Quantity__c, 'Invoice_Quantity__c should be ' + deliveredAiIncrement);
        System.assertEquals(deliveredAiIncrement, listMonthlyAfterUpdate[0].Delivered_Sum__c, 'Delivered_Sum__c should be ' + deliveredAiIncrement);

        monthlyQuantityOfCmp = deliveredAiIncrement;
        deliveredSum = monthlyQuantityOfCmp;
        
        for(Ad_Revenue_Monthly__c eachMonthly : listMonthlyAfterUpdate){

            // if(eachMonthly.Transaction_Date__c <= today){
                
                if (eachMonthly.Booked_Quantity__c >= deliveredSum) {
                    System.assertEquals(monthlyQuantityOfCmp, eachMonthly.Invoice_Quantity__c, 'Invoice_Quantity__c should be ' + monthlyQuantityOfCmp);
                } else if (eachMonthly.Booked_Quantity__c >= (deliveredSum - monthlyQuantityOfCmp)) {
                    System.assertEquals((eachMonthly.Booked_Quantity__c - (deliveredSum - monthlyQuantityOfCmp)), eachMonthly.Invoice_Quantity__c, 'Invoice_Quantity__c should be ' + (eachMonthly.Booked_Quantity__c - (deliveredSum - monthlyQuantityOfCmp)));
                }else{
                    System.assertEquals(0, eachMonthly.Invoice_Quantity__c, 'Invoice_Quantity__c should be 0');
                }

                System.assertEquals(deliveredSum, eachMonthly.Delivered_Sum__c, 'Delivered_Sum__c should be ' + deliveredSum);
                deliveredSum = deliveredSum + monthlyQuantityOfCmp;

            // }else{
            //     System.assertEquals(null, eachMonthly.Invoice_Quantity__c);
            //     System.assertEquals(null, eachMonthly.Delivered_Sum__c);
            // }
           
        }
    
    }

    @IsTest
    static void testBookedQuantityAndTotalPriceExcceed(){

        // Sophal / 08.04.2021 / US-0009328

        //setUpData();
         // total 4 months 
        QuoteLineItem qli1 = [select Id, from_Date__c, until_Date__c From QuoteLineItem Where Quote.name = 'q1'];
        qli1.from_Date__c = Date.today().addMonths(-4);
        qli1.until_Date__c = Date.today().addMonths(-1);

        update qli1;

        Ad_Product__c adProd = [Select Id,until_date__c From Ad_Product__c Where Quote_Line_Item__c =: qli1.Id];
        System.assertNotEquals(null, adProd.Id, 'Ad Product should be created');

        adProd.Ad_Id__c = '1';
        adProd.Booked_Quantity__c = 10;
        adProd.Quantity__c = 10;
        adProd.Billing_Category__c = 'CPM';
        adProd.Net_Net_Net__c = 1;
        adProd.TotalPrice__c = 1000;
        adProd.Amount_Net2eBay__c = 1;  // Sophal / 28.09.2021 / US-0010526 fix this test method after formula field Ad_Revenue_Monthly__c.Invoice_amount__c changed.

        // adProd.Product_Startdate__c = qli1.from_Date__c;
        // adProd.Product_Enddate__c = qli1.from_Date__c;

       
        update adProd;

        List<Ad_Revenue_Monthly__c> listReMonthly = [Select Id, Transaction_Date__c from Ad_Revenue_Monthly__c Where Ad_Product__c =: adProd.Id Order By Transaction_Date__c ASC]; 

        System.assertEquals(4, listReMonthly.size(), 'There should be 4 months of Ad_Revenue_Monthly__c created');

        System.assertEquals(Date.today().addMonths(-4).month(), listReMonthly[0].Transaction_Date__c.month(), 'The first month should be 4 months ago');
        System.assertEquals(Date.today().addMonths(-3).month(), listReMonthly[1].Transaction_Date__c.month(), 'The second month should be 3 months ago');
        System.assertEquals(Date.today().addMonths(-2).month(), listReMonthly[2].Transaction_Date__c.month(), 'The third month should be 2 months ago');
        System.assertEquals(Date.today().addMonths(-1).month(), listReMonthly[3].Transaction_Date__c.month(), 'The fourth month should be 1 month ago');



        listReMonthly[0].X3rd_Party_AI__c = 5;
        listReMonthly[1].X3rd_Party_AI__c = 5;
        listReMonthly[2].X3rd_Party_AI__c = 2;
        listReMonthly[3].X3rd_Party_AI__c = 1;

        listReMonthly[0].X3rd_Party_Monthly_Gross__c = null;
        listReMonthly[1].X3rd_Party_Monthly_Gross__c = null;
        listReMonthly[2].X3rd_Party_Monthly_Gross__c = null;
        listReMonthly[3].X3rd_Party_Monthly_Gross__c = null;

        update listReMonthly;

        listReMonthly = [Select Id, X3rd_Party_AI__c, Invoice_Quantity__c, Is_Exceeding_BookedQuantity__c,Invoice_amount__c, Invoice_Amount2__c from Ad_Revenue_Monthly__c Where Ad_Product__c =: adProd.Id Order By Transaction_Date__c ASC]; 

        System.assertEquals(listReMonthly[0].X3rd_Party_AI__c, listReMonthly[0].Invoice_Quantity__c, 'X3rd_Party_AI__c should equal Invoice_Quantity__c for the first month');
        System.assertEquals(listReMonthly[1].X3rd_Party_AI__c, listReMonthly[1].Invoice_Quantity__c, 'X3rd_Party_AI__c should equal Invoice_Quantity__c for the second month');
        System.assertEquals(0, listReMonthly[2].Invoice_Quantity__c, 'Invoice_Quantity__c should be 0 for the third month');
        System.assertEquals(0, listReMonthly[3].Invoice_Quantity__c, 'Invoice_Quantity__c should be 0 for the fourth month');


        /* Sophal:28/06/2021: US-0009797 we are no longer use Monthly_Quantity__c to check if Booked_Quantity__c is exceeded or not

            // System.assertEquals(false, listReMonthly[0].Is_Exceeding_BookedQuantity__c);
            // System.assertEquals(false, listReMonthly[1].Is_Exceeding_BookedQuantity__c);
            // System.assertEquals(true, listReMonthly[2].Is_Exceeding_BookedQuantity__c);
            // System.assertEquals(true, listReMonthly[3].Is_Exceeding_BookedQuantity__c);

        */

        System.assertEquals(false, listReMonthly[0].Is_Exceeding_BookedQuantity__c, 'The first month should not exceed Booked_Quantity__c');
        System.assertEquals(false, listReMonthly[1].Is_Exceeding_BookedQuantity__c, 'The second month should not exceed Booked_Quantity__c');
        System.assertEquals(false, listReMonthly[2].Is_Exceeding_BookedQuantity__c, 'The third month should not exceed Booked_Quantity__c');
        System.assertEquals(false, listReMonthly[3].Is_Exceeding_BookedQuantity__c, 'The fourth month should not exceed Booked_Quantity__c');

        System.assertNotEquals(null,listReMonthly[0].Invoice_amount__c, 'The first month Invoice_amount__c should not be null');
        System.assertNotEquals(null,listReMonthly[1].Invoice_amount__c, 'The second month Invoice_amount__c should not be null');
        System.assertNotEquals(null,listReMonthly[2].Invoice_amount__c, 'The third month Invoice_amount__c should not be null');
        System.assertNotEquals(null,listReMonthly[3].Invoice_amount__c, 'The fourth month Invoice_amount__c should not be null');

        System.assert(listReMonthly[0].Invoice_amount__c > 0, 'The first month Invoice_amount__c should be greater than 0');
        System.assert(listReMonthly[1].Invoice_amount__c > 0, 'The second month Invoice_amount__c should be greater than 0');
        System.assert(listReMonthly[2].Invoice_amount__c == 0, 'The third month Invoice_amount__c should be 0');
        System.assert(listReMonthly[3].Invoice_amount__c == 0, 'The fourth month Invoice_amount__c should be 0');


        System.assertEquals(listReMonthly[0].Invoice_amount__c, listReMonthly[0].Invoice_Amount2__c, 'The first month Invoice_amount__c should equal Invoice_Amount2__c');
        System.assertEquals(listReMonthly[1].Invoice_amount__c, listReMonthly[1].Invoice_Amount2__c, 'The second month Invoice_amount__c should equal Invoice_Amount2__c');
        System.assertEquals(listReMonthly[2].Invoice_amount__c, listReMonthly[2].Invoice_Amount2__c, 'The third month Invoice_amount__c should equal Invoice_Amount2__c');
        System.assertEquals(listReMonthly[3].Invoice_amount__c, listReMonthly[3].Invoice_Amount2__c, 'The fourth month Invoice_amount__c should equal Invoice_Amount2__c');

        Test.startTest();
        adProd = [Select Id,TotalPrice__c, Total_Invoice_Amount__c, TotalPrice_Is_Exceeded__c From Ad_Product__c Where Id =: adProd.Id];

    
        System.assertEquals(false, adProd.TotalPrice_Is_Exceeded__c, 'TotalPrice_Is_Exceeded__c should be false');

        adProd.Net_Net_Net__c = 10000000;
        adProd.Amount_Net2eBay__c = 10000000; // Sophal / 28.09.2021 / US-0010526 fix this test method after formula field Ad_Revenue_Monthly__c.Invoice_amount__c changed.
        
        update adProd;
        

        adProd = [Select Id,TotalPrice__c, Total_Invoice_Amount__c, TotalPrice_Is_Exceeded__c From Ad_Product__c Where Id =: adProd.Id];

        System.assertEquals(true, adProd.TotalPrice_Is_Exceeded__c, 'TotalPrice_Is_Exceeded__c should be true');


        // Sophal:28/06/2021: US-0009797 we use invoice quantity direct to check if Booked_Quantity__c is exceeded or not
        listReMonthly[0].Invoice_Quantity__c = 10000000;
        update listReMonthly[0];
        listReMonthly = [Select Id, X3rd_Party_AI__c, Invoice_Quantity__c, Is_Exceeding_BookedQuantity__c,Invoice_amount__c, Invoice_Amount2__c from Ad_Revenue_Monthly__c Where Ad_Product__c =: adProd.Id Order By Transaction_Date__c ASC]; 
        System.assertEquals(true, listReMonthly[0].Is_Exceeding_BookedQuantity__c, 'The first month should exceed Booked_Quantity__c');
        System.assertEquals(true, listReMonthly[1].Is_Exceeding_BookedQuantity__c, 'The second month should exceed Booked_Quantity__c');
        System.assertEquals(true, listReMonthly[2].Is_Exceeding_BookedQuantity__c, 'The third month should exceed Booked_Quantity__c');
        System.assertEquals(true, listReMonthly[3].Is_Exceeding_BookedQuantity__c, 'The fourth month should exceed Booked_Quantity__c');

        

        Test.stopTest();
        


       
    }
    @IsTest
    static void testTotalPriceCPO(){

        //setUpData();
        

        Ad_Product__c adProd = [Select Id From Ad_Product__c Where Quote_Line_Item__r.Quote.name = 'q1'];
        System.assertNotEquals(null, adProd.Id, 'Ad Product should be created');

        adProd.Ad_Id__c = '1';
        adProd.Booked_Quantity__c = 1000;
        adProd.Quantity__c = 1000;
        adProd.Billing_Category__c = 'CPO';
        adProd.Net_Net_Net__c = 1;
        adProd.TotalPrice__c = 1000;
        adProd.Amount_Net2eBay__c = 1;

       
        update adProd;

        List<Ad_Revenue_Monthly__c> listReMonthly = [Select Id,X3rd_Party_Monthly_Gross__c from Ad_Revenue_Monthly__c Where Ad_Product__c =: adProd.Id Order By Transaction_Date__c ASC];

        listReMonthly[0].X3rd_Party_Monthly_Gross__c = 2000;

        update listReMonthly;

        listReMonthly = [Select Id, X3rd_Party_Monthly_Gross__c from Ad_Revenue_Monthly__c Where Ad_Product__c =: adProd.Id Order By Transaction_Date__c ASC];
        System.assertEquals(1000, listReMonthly[0].X3rd_Party_Monthly_Gross__c, 'Amount should be 1000 because it should not exceed TotalPrice of Ad_Product__c');
    }



}