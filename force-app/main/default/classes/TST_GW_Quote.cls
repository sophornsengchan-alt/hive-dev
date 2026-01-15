/*****************************************************************************************************************************
@ Class:   TST_GW_Quote
@ Author: 	Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:	All GW_Quote and GW_Quote2 test methods.
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 8.09.2020/ Acmatac SEING / Created the  Class
@               : 06.09.2033 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync
*****************************************************************************************************************************/
@isTest
private class TST_GW_Quote {

    private static Quote quote;
    private static Opportunity opp;
    private static Account acc;
    private static byPass__c bp;

    static void setupData(Boolean byPassTrigger){
        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = byPassTrigger, ByPass_Validation__c = true);
        insert bp;

               

        acc = TST_DataGenerator.generateAccount();
        insert acc;
        Contact c = new Contact(AccountId = acc.Id, LastName = 'Test Contact', FirstName = 'Test',Contact_Role__c = 'Billing Contact',recordtypeid = ApexUtil.getRecordTypeByName('Contact','EBH_DWH').Id,Email = 'test@contact.es');
   
        insert c;

        opp = TST_DataGenerator.generateOpp(acc.Id);
        opp.Special_Terms__c = 'New Terms - Spe';
        opp.StageName = 'Qualified Meeting';
        opp.Bill_To_Party__c = 'Advertiser';
        insert opp;


        quote = TST_DataGenerator.generateQuote(opp.Id, null);
        quote.Name= 'AMT Test QUOTE 1';
        quote.RecordTypeId =  ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote.Primary_Quote__c = false; // workflow will update this to true anyway
        insert quote;
        
        Site__c site = TST_DataGenerator.generateSite();
        insert site;
        
        Product2 prod1 = TST_DataGenerator.generateProduct(site.Id);
        Product2 prod2 = TST_DataGenerator.generateProduct(site.Id);
        insert new List<Product2>{prod1, prod2};
        
        PriceBookEntry pbe1 =TST_DataGenerator.generatePricebookEntry(prod1.id, null);
        PriceBookEntry pbe2 =TST_DataGenerator.generatePricebookEntry(prod2.id, null);
        insert new List<PriceBookEntry>{pbe1, pbe2};

        QuoteLineItem qli1 = TST_DataGenerator.generateQuoteLinItem( quote.id, prod1.id, pbe1.id);
        qli1.Budget__c = 30;
        qli1.from_Date__c = date.today();
        qli1.until_Date__c = date.today();
        QuoteLineItem qli2 = TST_DataGenerator.generateQuoteLinItem( quote.id, prod2.id, pbe2.id);
        qli2.Budget__c = 55;
        qli2.from_Date__c = date.today();
        qli2.until_Date__c = date.today();
        insert new List<QuoteLineItem>{qli1, qli2};       
       

    }
    
    /*****************************************************************************************************************************
    @ Method:   copyQlinesToAPTest
    @ Author: 	Acmatac SEING (acmatac.seing@gaea-sys.com)
	@ Purpose:	US-0008016
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 2.09.2020 / Acmatac SEING / Created the  Method
    *****************************************************************************************************************************/
    @isTest
    static void copyQlinesToAPTest(){
        setupData(false);
        Test.startTest();
            quote = [SELECT Id, RecordType.DeveloperName, OpportunityId FROM Quote LIMIT 1];
            quote.Primary_Quote__c = false;
            update quote;

            quote.Primary_Quote__c = true;
            update quote;

            List<QuoteLineItem> lstQLI = [SELECT Id, AdProduct__c FROM QuoteLineItem WHERE QuoteId =: quote.Id Order By Budget__c Asc];
            System.assert(lstQLI.size() == 2);

            List<Ad_Product__c> lstAP = [SELECT Id FROM Ad_Product__c WHERE Opportunity__c =: quote.OpportunityId];
            System.assert(lstAP.size() == 2);

            opp = [SELECT Amount FROM Opportunity WHERE Id =: quote.OpportunityId];
            System.assert(opp.Amount == 85);

            delete lstQLI[0];
            // Deleted QLI, then AdProduct will re-sync
            lstAP = [SELECT Id FROM Ad_Product__c WHERE Opportunity__c =: quote.OpportunityId];
            System.assert(lstAP.size() == 1);

            // Deleted QLI, then Total Amount should Recal-
            opp = [SELECT Amount FROM Opportunity WHERE Id =: quote.OpportunityId];
            // System.assert(opp.Amount == 55); 
            System.assertEquals(55, opp.Amount);  // 28.05.2021 / Sophal Noch / US-0009582
            

        Test.stopTest();   
    }
    
    // Test method
    // US-0008472, @Ratha Sim [Ads 2020] Sync Primary Quote start and end dates to Opportunity
    @isTest
    static void updatePrimaryQuoteSetDateToOpportunity() {
        setupData(false);
        Test.startTest();
        	
        	date startDate = date.today();
        	startDate = startDate.addDays(5);
        	date endDate = date.today();
        	endDate = endDate.addDays(20);
        
        	quote = [SELECT Id, RecordType.DeveloperName, OpportunityId, Campaign_Start__c, Campaign_End__c FROM Quote LIMIT 1];
        	quote.Primary_Quote__c = false;
        	update quote;
        	
        	List<QuoteLineItem> lstQLI = [SELECT Id, AdProduct__c, from_Date__c, until_Date__c FROM QuoteLineItem WHERE QuoteId =: quote.Id];
            System.assert(lstQLI.size() == 2);
            for(QuoteLineItem li : lstQLI) {
            	li.from_Date__c = startDate;
        		li.until_Date__c = endDate;
            }
        	update lstQLI;
        	
        	quote = [SELECT Id, RecordType.DeveloperName, OpportunityId, Campaign_Start__c, Campaign_End__c FROM Quote LIMIT 1];
            quote.Primary_Quote__c = true;
            update quote;
        
        	List<Opportunity> opps = [SELECT Id, Amount, Start_Date__c, End_Date__c FROM Opportunity WHERE Id =: quote.OpportunityId];
        	opp = opps.get(0);
            System.assertEquals(opp.Start_Date__c, startDate);
        	System.assertEquals(opp.End_Date__c, endDate);
        	
        Test.stopTest(); 
    }


/*****************************************************************************************************************************
@ Method:   testUpdateQuoteToNonPrimary
@ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:	US-0008858
------------------------------------------------------------------------------------------------------------------------------
@ Change history: US-0008858 17.12.2020 / Sophal Noch / Created the method. test method for 
@                GW_Quote2.updateQuoteToNonPrimary and GW_Quote2.setDuallySignedQuoteToPrimary
------------------------------------------------------------------------------------------------------------------------------
@ Change history: US-0008874 17.12.2020 / Sophal Noch / Modify method to cover new logic which prevent old quote to be primary
@               : 06.09.2033 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync
*****************************************************************************************************************************/    
@isTest
    static void testUpdateQuoteToNonPrimary() {

        setupData(true);

        bp.byPass_WFRule__c = true;
        update bp;

        Set<Id> setQuoteId = new Set<Id>();
        quote.Primary_Quote__c = true;


        bp.byPass_Trigger__c = false;
        update bp;
        update quote;
        setQuoteId.add(quote.Id);


        Test.startTest();

        Quote quote2 = TST_DataGenerator.generateQuote(opp.Id, null);
        quote2.Name= 'Test QUOTE 2';
        quote2.RecordTypeId =  ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote2.Primary_Quote__c = false;
        bp.byPass_Trigger__c = true;
        update bp;
        insert quote2;
        setQuoteId.add(quote2.Id);
        
        Site__c site = TST_DataGenerator.generateSite();
        insert site;
        
        Product2 prod1 = TST_DataGenerator.generateProduct(site.Id);
        Product2 prod2 = TST_DataGenerator.generateProduct(site.Id);
        insert new List<Product2>{prod1, prod2};
        
        PriceBookEntry pbe1 =TST_DataGenerator.generatePricebookEntry(prod1.id, null);
        PriceBookEntry pbe2 =TST_DataGenerator.generatePricebookEntry(prod2.id, null);
        insert new List<PriceBookEntry>{pbe1, pbe2};

       
        QuoteLineItem qli1 = TST_DataGenerator.generateQuoteLinItem( quote2.id, prod1.id, pbe1.id);
        qli1.Budget__c = 30;
        qli1.from_Date__c = date.today();
        qli1.until_Date__c = date.today();
        QuoteLineItem qli2 = TST_DataGenerator.generateQuoteLinItem( quote2.id, prod2.id, pbe2.id);
        qli2.Budget__c = 55;
        qli2.from_Date__c = date.today();
        qli2.until_Date__c = date.today();
        insert new List<QuoteLineItem>{qli1, qli2};

        bp.byPass_Trigger__c = false;
        update bp;
        Opportunity opp2 = TST_DataGenerator.generateOpp(acc.Id);
        opp2.Special_Terms__c = 'New Terms - Spe';
        opp2.StageName = 'Qualified Meeting';
        insert opp2;

        // this quote3 should not be effect by other primary quote from other opp
        Quote quote3ForOpp2 = TST_DataGenerator.generateQuote(opp2.Id, null);
        quote3ForOpp2.Name= 'Test Opp 2 QUOTE 11';
        quote3ForOpp2.RecordTypeId =  ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote3ForOpp2.Primary_Quote__c = true;
        insert quote3ForOpp2;

        setQuoteId.add(quote3ForOpp2.Id);


        quote2.Primary_Quote__c = true;
        
        update quote2;
        
         
        Test.stopTest();


        List<Quote> listQuote = [Select Id, Primary_Quote__c From Quote Where Id IN: setQuoteId Order by Id Asc];
        System.assertEquals(3, listQuote.size());
        
        System.assertEquals(false, listQuote[0].Primary_Quote__c); // opp 1 quote number 1 = false
        System.assertEquals(true, listQuote[1].Primary_Quote__c); // opp 1 quote  number 2 = true
        System.assertEquals(true, listQuote[2].Primary_Quote__c); // opp 2 quote number 1 = true


        Quote quote3 = TST_DataGenerator.generateQuote(opp.Id, null);
        quote3.Name= 'Test QUOTE 3';
        quote3.RecordTypeId =  ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        
        
        insert quote3;
       

        setQuoteId.add(quote3.Id);


        QuoteLineItem qli1ForQuote3 = TST_DataGenerator.generateQuoteLinItem( quote3.id, prod1.id, pbe1.id);
        qli1ForQuote3.Budget__c = 30;
        qli1ForQuote3.from_Date__c = date.today().addMonths(1);
        qli1ForQuote3.until_Date__c = date.today().addMonths(2);
        insert qli1ForQuote3;

        
        quote3.Primary_Quote__c = true;
        
        update quote3;
         
        
  

        List<Quote> listQuoteRequeried = [Select Id, Primary_Quote__c From Quote Where Id IN: setQuoteId Order by Id Asc];
        System.assertEquals(4, listQuoteRequeried.size());
        
        System.assertEquals(false, listQuoteRequeried[0].Primary_Quote__c); // opp 1 quote number 1 = false
        System.assertEquals(false, listQuoteRequeried[1].Primary_Quote__c); // opp 1 quote  number 2 = false

        System.assertEquals(true, listQuoteRequeried[2].Primary_Quote__c); // opp 2 quote number 1 = true

        System.assertEquals(true, listQuoteRequeried[3].Primary_Quote__c); // opp 1 quote  number 3 = true



  //      List<Ad_Product__c> newAdProduct = [Select Id, Quote_Line_Item__r.QuoteId from Ad_Product__c Where Opportunity__c =: opp.Id];
  //      System.assert(newAdProduct.size() > 0);
  //      for(Ad_Product__c eachAdProd : newAdProduct){
  //          System.assertEquals(quote3.Id, eachAdProd.Quote_Line_Item__r.QuoteId);
  //      }

    }

    /*****************************************************************************************************************************
    @ Method:   testSetPreviousQuoteToPrimary
    @ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:	US-0008874
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0008874 23.12.2020 / Sophal Noch / Create method.
                    Test method for GW_Quote2.preventPreviousQuoteBecomingPrimary and GW_Quote2.markQuoteToHavingBeenPrimary
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0008951, US-0008975 14.01.2020 / Sophal Noch / modified method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0008988 18.01.2021 / Sophal Noch / modified method.
    @               : 06.09.2033 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync
    *****************************************************************************************************************************/ 
    @isTest
    static void testSetPreviousQuoteToPrimary() {

        setupData(false);
        
        bp.ByPass_PrimaryQuoteRule__c = false; // Sophal/ 21.07.2022 / US-0012062 make sure it is not bypass for testing the apex validation
        bp.byPass_WFRule__c = true; // Sophal/ 21.07.2022 / US-0012062 byPass process builder 'Process Builder - eBay Ads - Opportunity' to save performance beacuse there many quote becoming primary logic below
        update bp;

        Set<Id> setQuoteId = new Set<Id>();
        quote.Primary_Quote__c = true;
        // quote.Status = 'Approved'; // for US-0008975 // US-0008988
        // quote.Dually_Signed__c = true; // for US-0008975 // US-0008988
        Test.startTest();

        update quote;

        setQuoteId.add(quote.Id);

        Id ebayAdId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;


        Quote quote2 = TST_DataGenerator.generateQuote(opp.Id, null);
        quote2.Name= 'Test QUOTE 2';
        quote2.RecordTypeId =  ebayAdId;
        quote2.Primary_Quote__c = false;

        bp.byPass_Trigger__c = true;
        update bp;
        insert quote2;

        setQuoteId.add(quote2.Id);

        Site__c site = TST_DataGenerator.generateSite();
        insert site;
        
        Product2 prod1 = TST_DataGenerator.generateProduct(site.Id);
        Product2 prod2 = TST_DataGenerator.generateProduct(site.Id);
        insert new List<Product2>{prod1, prod2};
        
        PriceBookEntry pbe1 =TST_DataGenerator.generatePricebookEntry(prod1.id, null);
        PriceBookEntry pbe2 =TST_DataGenerator.generatePricebookEntry(prod2.id, null);
        insert new List<PriceBookEntry>{pbe1, pbe2};

        
        
        QuoteLineItem qli1 = TST_DataGenerator.generateQuoteLinItem( quote2.id, prod1.id, pbe1.id);
        qli1.Budget__c = 30;
        qli1.from_Date__c = date.today();
        qli1.until_Date__c = date.today();
        QuoteLineItem qli2 = TST_DataGenerator.generateQuoteLinItem( quote2.id, prod2.id, pbe2.id);
        qli2.Budget__c = 55;
        qli2.from_Date__c = date.today();
        qli2.until_Date__c = date.today();
        insert new List<QuoteLineItem>{qli1, qli2};


        Quote quote2Query = [Select Id,Primary_Quote__c,HasBeenPrimary__c From Quote Where Id =: quote2.Id Limit 1];
        System.assertEquals(false, quote2Query.Primary_Quote__c);
        System.assertEquals(false, quote2Query.HasBeenPrimary__c);

        quote2.Primary_Quote__c = true;
        quote2.Is_Revised_Quote__c = true; // is revised quote

        quote2.Status = 'Approved'; // for US-0008975
        quote2.Dually_Signed__c = true; // for US-0008975

        bp.byPass_Trigger__c = false;
        update bp;
        update quote2;

        List<Quote> listQuoteRequeried = [Select Id, Primary_Quote__c,HasBeenPrimary__c From Quote Where Id IN:setQuoteId Order by Id Asc];
        System.assertEquals(2, listQuoteRequeried.size());

        System.assertEquals(false, listQuoteRequeried[0].Primary_Quote__c); // opp 1 quote number 1 = false
        System.assertEquals(true, listQuoteRequeried[1].Primary_Quote__c); // opp 1 quote  number 2 = true

        System.assertEquals(true, listQuoteRequeried[0].HasBeenPrimary__c);
        System.assertEquals(true, listQuoteRequeried[1].HasBeenPrimary__c); 


        quote.Primary_Quote__c = true;

        Database.SaveResult[] updateResultList = Database.update(new List<Quote>{quote}, false);
        System.assertEquals(false, updateResultList[0].isSuccess()); // false
        System.assertEquals(Label.Error_Only_Latest_Quote_Can_Be_Primary, updateResultList[0].getErrors()[0].getMessage());
        
        
        /* 
        //  06.09.2033 / Sophal Noch / US-0014020 : disable because above test in this method already cover the case

        Quote quote3 = TST_DataGenerator.generateQuote(opp.Id, null);
        quote3.Name= 'Test QUOTE 3';
        quote3.RecordTypeId =  ebayAdId;
        quote3.Primary_Quote__c = false;
        quote3.Is_Revised_Quote__c = true; // is revised quote
        insert quote3;
        setQuoteId.add(quote3.Id);

        site = TST_DataGenerator.generateSite();
        insert site;
        
        prod1 = TST_DataGenerator.generateProduct(site.Id);
        prod2 = TST_DataGenerator.generateProduct(site.Id);
        insert new List<Product2>{prod1, prod2};
        
        pbe1 =TST_DataGenerator.generatePricebookEntry(prod1.id, null);
        pbe2 =TST_DataGenerator.generatePricebookEntry(prod2.id, null);
        insert new List<PriceBookEntry>{pbe1, pbe2};

        qli1 = TST_DataGenerator.generateQuoteLinItem( quote3.id, prod1.id, pbe1.id);
        qli1.Budget__c = 30;
        qli1.from_Date__c = date.today().addDays(1);
        qli1.until_Date__c = date.today().addDays(1);
        qli2 = TST_DataGenerator.generateQuoteLinItem( quote3.id, prod2.id, pbe2.id);
        qli2.Budget__c = 55;
        qli2.from_Date__c = date.today().addDays(1);
        qli2.until_Date__c = date.today().addDays(1);
        insert new List<QuoteLineItem>{qli1, qli2};



        Quote quote4 = TST_DataGenerator.generateQuote(opp.Id, null);
        quote4.Name= 'Test QUOTE 4';
        quote4.RecordTypeId =  ebayAdId;
        quote4.Primary_Quote__c = false;
        quote4.Is_Revised_Quote__c = true; // is revised quote
        insert quote4;
        setQuoteId.add(quote4.Id);

        site = TST_DataGenerator.generateSite();
        insert site;
        
        prod1 = TST_DataGenerator.generateProduct(site.Id);
        prod2 = TST_DataGenerator.generateProduct(site.Id);
        insert new List<Product2>{prod1, prod2};
        
        pbe1 =TST_DataGenerator.generatePricebookEntry(prod1.id, null);
        pbe2 =TST_DataGenerator.generatePricebookEntry(prod2.id, null);
        insert new List<PriceBookEntry>{pbe1, pbe2};

        qli1 = TST_DataGenerator.generateQuoteLinItem( quote3.id, prod1.id, pbe1.id);
        qli1.Budget__c = 30;
        qli1.from_Date__c = date.today().addDays(1);
        qli1.until_Date__c = date.today().addDays(1);
        qli2 = TST_DataGenerator.generateQuoteLinItem( quote3.id, prod2.id, pbe2.id);
        qli2.Budget__c = 55;
        qli2.from_Date__c = date.today().addDays(1);
        qli2.until_Date__c = date.today().addDays(1);
        insert new List<QuoteLineItem>{qli1, qli2};

        listQuoteRequeried = [Select Id, Primary_Quote__c,HasBeenPrimary__c From Quote Where Id IN:setQuoteId Order by Id Asc];
        System.assertEquals(4, listQuoteRequeried.size());


        quote4.Status = 'Approved'; // for US-0008975
        quote4.Dually_Signed__c = true; // for US-0008975
        quote4.Primary_Quote__c = true; // for US-0008975
        Test.stopTest();
        update quote4; // quote is revised quote and it is now primary.
        

        quote3.Primary_Quote__c = true; // quote 3 is revised quote and it should not be primary because of it is not approved yet.
        updateResultList = Database.update(new List<Quote>{quote3}, false); // doing the update on quote 3
        System.assertEquals(false, updateResultList[0].isSuccess()); // false, can not update to primary
        System.assertEquals(Label.Error_Only_Latest_Quote_Can_Be_Primary, updateResultList[0].getErrors()[0].getMessage());

        

        */


        // Sophal/ 21.07.2022 / US-0012062 ; disable code below to save permformance after many quote has run update quote-to-primary logic

        // quote2.Primary_Quote__c = true; // quote 2 is revised quote and it can be set to primary because of it has approved.
        

        // bp.ByPass_PrimaryQuoteRule__c = false; // Sophal/ 26.04.2021 / US-0009456 for this testing, this must not be bypassed
        // bp.byPass_WFRule__c = true;  // Sophal/ 26.04.2021 / US-0009456 byPass process builder 'Process Builder - eBay Ads - Opportunity'
        // update bp;

        // updateResultList = Database.update(new List<Quote>{quote2}, false); // doing the update on quote 2

       
        // if(updateResultList[0].getErrors().size() > 0){ // it is not supposed to false, but just in case it false unexpectly. if it has no error. it will skip this.

        //     System.assertEquals(null, updateResultList[0].getErrors()[0].getMessage()); // to debug error in test method. if it has no error. it will skip this.
        // }
        
        // System.assertEquals(true, updateResultList[0].isSuccess()); // true, can update back to primary
        
        
         
    }


    /*****************************************************************************************************************************
    @ Method:   testUseBypassToSetPreviousQuoteToPrimary
    @ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:	US-0008951
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0008951 12.01.2021 / Sophal Noch / Create method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0008975 14.01.2021 / Sophal Noch / modified method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0008988 18.01.2021 / Sophal Noch / modified method.
    *****************************************************************************************************************************/ 
    @isTest
    static void testUseBypassToSetPreviousQuoteToPrimary() {

        setupData(false);

        Set<Id> setQuoteId = new Set<Id>();
        quote.Primary_Quote__c = true;
        update quote;
        setQuoteId.add(quote.Id);

        Test.startTest();

        quote.Status = 'Approved'; // for US-0008975
        quote.Dually_Signed__c = true; // for US-0008975
        update quote; // for US-0008975


        Quote quote2 = TST_DataGenerator.generateQuote(opp.Id, null);
        quote2.Name= 'Test QUOTE 2';
        quote2.RecordTypeId =  ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote2.Primary_Quote__c = false;
        insert quote2;

        quote2.Status = 'Approved';
        quote2.Dually_Signed__c = true;
        quote2.Primary_Quote__c = true;

        Database.SaveResult[] updateResultList = Database.update(new List<Quote>{quote2}, false);
        System.assertEquals(false, updateResultList[0].isSuccess()); // false
        System.assertEquals(Label.Error_Quote_Cannot_Be_Primary_If_DuallySigned_Or_BuyerAccepted, updateResultList[0].getErrors()[0].getMessage());

        bp.ByPass_PrimaryQuoteRule__c = true;
        update bp;

        // update quote2;

        updateResultList = Database.update(new List<Quote>{quote2}, false);
        String errorMsg = updateResultList[0].getErrors().isEmpty() == false ? updateResultList[0].getErrors()[0].getMessage() : null;
        System.assertEquals(null, errorMsg);
        System.assertEquals(true, updateResultList[0].isSuccess()); // false

        Test.stopTest();
        
        // bp.ByPass_PrimaryQuoteRule__c = false;
        // update bp;

        // quote.Primary_Quote__c = true;

        // updateResultList = Database.update(new List<Quote>{quote}, false);
        // System.assertEquals(false, updateResultList[0].isSuccess()); // false
        // System.assertEquals(Label.Error_Quote_Cannot_Be_Primary_If_DuallySigned_Or_BuyerAccepted, updateResultList[0].getErrors()[0].getMessage());
        

        // bp.ByPass_PrimaryQuoteRule__c = true;
        // update bp;

        // updateResultList = Database.update(new List<Quote>{quote}, false);
        // System.assertEquals(null, updateResultList[0].getErrors()[0]);
        // System.assertEquals(true, updateResultList[0].isSuccess()); // false
      

         
       



    }


    /*****************************************************************************************************************************
    @ Method:   testFixingSoqlErrorWhenQuoteIsApproved
    @ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:	US-0008955
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0008955 12.01.2021 / Sophal Noch / create method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0008951, US-0008975 15.01.2021 / Sophal Noch / modified method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0008988 18.01.2021 / Sophal Noch / modified method.
    @               : 06.09.2033 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync
    *****************************************************************************************************************************/    
    /* 
     //  06.09.2033 / Sophal Noch / US-0014020 : disable because there is soql 101 error anymore and there no feature to test with this test method. there are other method that cover this already.

    @isTest
    static void testFixingSoqlErrorWhenQuoteIsApproved() {

       
        
        setupData(true);

        // US-0008955 the error mostly come from process builder name "eBay Ads Updates for Existing Quotes"

        bp.ByPass_PrimaryQuoteRule__c = true; // US-0008988
        update bp;
        

        Set<Id> setQuoteId = new Set<Id>();
        quote.Dually_Signed__c = true;
        quote.Buyer_Accepted__c = true;
        quote.Status = 'Approved';
        quote.Primary_Quote__c = true;

        bp.byPass_Trigger__c = false;
        update bp;
        update quote;

        setQuoteId.add(quote.Id);



        Quote quote2 = TST_DataGenerator.generateQuote(opp.Id, null);
        quote2.Name= 'Test QUOTE 2';
        quote2.RecordTypeId =  ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote2.Primary_Quote__c = false;

        bp.byPass_Trigger__c = true;
        update bp;
        insert quote2;
        
        setQuoteId.add(quote2.Id);
        
        Site__c site = TST_DataGenerator.generateSite();
        insert site;
        
        Product2 prod1 = TST_DataGenerator.generateProduct(site.Id);
        Product2 prod2 = TST_DataGenerator.generateProduct(site.Id);
        insert new List<Product2>{prod1, prod2};
        
        PriceBookEntry pbe1 =TST_DataGenerator.generatePricebookEntry(prod1.id, null);
        PriceBookEntry pbe2 =TST_DataGenerator.generatePricebookEntry(prod2.id, null);
        insert new List<PriceBookEntry>{pbe1, pbe2};

        QuoteLineItem qli1 = TST_DataGenerator.generateQuoteLinItem( quote2.id, prod1.id, pbe1.id);
        qli1.Budget__c = 30;
        qli1.from_Date__c = date.today();
        qli1.until_Date__c = date.today();
        QuoteLineItem qli2 = TST_DataGenerator.generateQuoteLinItem( quote2.id, prod2.id, pbe2.id);
        qli2.Budget__c = 55;
        qli2.from_Date__c = date.today();
        qli2.until_Date__c = date.today();
        insert new List<QuoteLineItem>{qli1, qli2};

        Test.startTest();

        Opportunity opp2 = TST_DataGenerator.generateOpp(acc.Id);
        opp2.Special_Terms__c = 'New Terms - Spe';
        opp2.StageName = 'Qualified Meeting';
        bp.byPass_Trigger__c = false;
        update bp;
        insert opp2;

        // this quote3 should not be effect by other primary quote from other opp
        Quote quote3ForOpp2 = TST_DataGenerator.generateQuote(opp2.Id, null);
        quote3ForOpp2.Name= 'Test Opp 2 QUOTE 11';
        quote3ForOpp2.RecordTypeId =  ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;

        quote3ForOpp2.Primary_Quote__c = true;
        insert quote3ForOpp2;

        setQuoteId.add(quote3ForOpp2.Id);

        quote2.Dually_Signed__c = true;
        quote2.Buyer_Accepted__c = true;
        quote2.Status = 'Approved';
        quote2.Primary_Quote__c = true;
        
        update quote2;
        
        
        Test.stopTest();

        List<Quote> listQuote = [Select Id, Primary_Quote__c From Quote Where Id IN: setQuoteId Order by Id Asc];
        System.assertEquals(3, listQuote.size());
        
        System.assertEquals(false, listQuote[0].Primary_Quote__c); // opp 1 quote number 1 = false
        System.assertEquals(true, listQuote[1].Primary_Quote__c); // opp 1 quote  number 2 = true
        System.assertEquals(true, listQuote[2].Primary_Quote__c); // opp 2 quote number 1 = true


    } */


    /*****************************************************************************************************************************
    @ Method:   testMakeLatestNormalQuoteToPrimaryWhenDuallySignedOrBuyerAccepted
    @ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:	US-0008988
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.01.2021 / Sophal Noch / US-0008988 modified method.
    *****************************************************************************************************************************/ 
    @isTest
    public static void testMakeLatestNormalQuoteToPrimaryWhenDuallySignedOrBuyerAccepted() {
        setupData(false);

        Test.startTest();
        

        Set<Id> setQuoteId = new Set<Id>();
        quote.Primary_Quote__c = true;
        update quote;
        setQuoteId.add(quote.Id);

        quote.Status = 'Approved';
        quote.Dually_Signed__c = true; 
        update quote;


        Quote quote2 = TST_DataGenerator.generateQuote(opp.Id, null);
        quote2.Name= 'Test QUOTE 2';
        quote2.RecordTypeId =  ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;

        quote2.Dually_Signed__c = false;
        quote2.Buyer_Accepted__c = false;
        quote2.Primary_Quote__c = false;
        insert quote2;

        quote2.Status = 'Approved';
        quote2.Dually_Signed__c = true;
        quote2.Primary_Quote__c = true;

         
        Test.stopTest();

        Database.SaveResult[] updateResultList = Database.update(new List<Quote>{quote2}, false);
        System.assertEquals(false, updateResultList[0].isSuccess()); // false
        System.assertEquals(Label.Error_Quote_Cannot_Be_Primary_If_DuallySigned_Or_BuyerAccepted, updateResultList[0].getErrors()[0].getMessage());
    }


    /*******************************************************************************************************************************************
    @ Method:   testCopyDiscountsFromQuoteToQuoteLineItems
    @ Author: 	Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:	US-0009260
    --------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0009260 24.03.2021 / Mony Nou / Created the method. test method for QuoteHandler.copyDiscountsFromQuoteToQuoteLineItems
    -------------------------------------------------------------------------------------------------------------------------------------------*/    
    @isTest
    static void testCopyDiscountsFromQuoteToQuoteLineItems() {
        
        setupData(false);

        bp.byPass_WFRule__c = true;
        update bp;

        Test.startTest();

        Quote quote2 = TST_DataGenerator.generateQuote(opp.Id, null);
        quote2.Name= 'Test QUOTE 2';
        quote2.RecordTypeId =  ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote2.Primary_Quote__c = false;
        insert quote2;
        
        Site__c site = TST_DataGenerator.generateSite();
        insert site;
        
        Product2 prod1 = TST_DataGenerator.generateProduct(site.Id);
        Product2 prod2 = TST_DataGenerator.generateProduct(site.Id);
        insert new List<Product2>{prod1, prod2};
        
        PriceBookEntry pbe1 =TST_DataGenerator.generatePricebookEntry(prod1.id, null);
        PriceBookEntry pbe2 =TST_DataGenerator.generatePricebookEntry(prod2.id, null);
        insert new List<PriceBookEntry>{pbe1, pbe2};

        QuoteLineItem qli1 = TST_DataGenerator.generateQuoteLinItem( quote2.id, prod1.id, pbe1.id);
        qli1.Budget__c = 30;
        qli1.from_Date__c = date.today();
        qli1.until_Date__c = date.today();
        QuoteLineItem qli2 = TST_DataGenerator.generateQuoteLinItem( quote2.id, prod2.id, pbe2.id);
        qli2.Budget__c = 55;
        qli2.from_Date__c = date.today();
        qli2.until_Date__c = date.today();
        insert new List<QuoteLineItem>{qli1, qli2};

        quote2.Primary_Quote__c = true;
        quote2.AE__c = true;
        update quote2;
        
        
        Test.stopTest();

       

    }

    /*******************************************************************************************************************************************
    @ Method:   testwithdrawApprovalQuote
    @ Author: 	Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:	US-0010299
    --------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.10.2021 / Mony Nou / US-0010299 - Created the method. test method for GW_Quote2.withdrawApprovalQuote
    -------------------------------------------------------------------------------------------------------------------------------------------*/    
    @isTest
    static void testwithdrawApprovalQuote() {
        
        setupData(false);

        bp.byPass_WFRule__c = true;
        update bp;

        Test.startTest();

            Map<String, Object> res = GW_Quote2.withdrawApprovalQuote('');
            System.assert(res != null);

            Quote q = [SELECT Id, Status FROM Quote];
            q.Status = 'Needs Review';
            update q;        


            res = GW_Quote2.withdrawApprovalQuote(q.Id);
            System.assert(res != null);
        
        Test.stopTest();

       

    }


}