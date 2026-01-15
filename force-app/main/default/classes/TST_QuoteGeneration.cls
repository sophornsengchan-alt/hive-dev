@isTest
private class TST_QuoteGeneration {


    /*****************************************************************************************************************************
    @ Change history: 02.09.2021 / Sambath Seng / Increase code coverage for QuoteController, AngebotControllerOVK
    *****************************************************************************************************************************/
    @isTest
    static void testQuoteUK2018(){
          
        Test.startTest();

        RecordType accRT = [SELECT id FROM recordType WHERE sobjectType = 'Account' AND name = 'Advertiser'];
        
        Account acc = new Account();
        acc.Name = 'TestingTesting';
        acc.recordTypeId = accRT.id;
        acc.Record_Type_Text__c = 'Advertiser';
        insert acc;
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'Test';
        con.Phone = '+41 999 9999 99';
        con.Account = acc;
        con.MailingCity = 'Test';
        con.AccountId = acc.Id;
        insert con;

        
        Product2 p = new Product2();
        p.Name = 'TestTestTest TestTestTest TestTest TestTestTest TestTest';
        p.IsActive = true;
        insert p;
        
        PriceBookEntry prBookEntry = new PriceBookEntry();
        prBookEntry.Product2Id = p.Id;
        prBookEntry.IsActive = true;
        prBookEntry.UseStandardPrice = false; 
        prBookEntry.PriceBook2Id = Test.getStandardPricebookId(); 
        prBookEntry.UnitPrice = 0;             
        insert prBookEntry;

        //Sambath SENG 02.09.2021 increase test class coverage
        EBH_ActiveTriggers__c activeTrigger = new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller');
        insert activeTrigger;
        
        for(Integer i=0;i<1;i++) {
            String lang = null;
            
            if(i == 0) {
                lang = 'English';
            }

            Opportunity opp = new Opportunity(Name = 'Test', AccountId = acc.Id, CloseDate = system.today());
            opp.StageName = 'Test';
            opp.Description = 'teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting abcDDEqwert teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting AAAAAAA ggggggg \n \n teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting \n \n teeeeeeeeeeeeessssting \n \n  abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz';
            if(i == 0) {
                opp.Agency__c = acc.Id;
            }

            byPass__c settings = byPass__c.getOrgDefaults();
            settings.byPass_WFRule__c = true;
            upsert settings byPass__c.Id;

            insert opp;

            
            
            OpportunityContactRole oppConRole = new OpportunityContactRole();
            oppConRole.OpportunityId = opp.Id;
            oppConRole.ContactId = con.Id;

            //Sambath SENG 02.09.2021 increase test class coverage
            oppConRole.Role = 'Invoice recipient';

            if(i == 0) {
                oppConRole.IsPrimary = true;
            }
            insert oppConRole;
            
            Quote quo = new Quote(opportunityId=opp.id, name='TEST',  pricebook2id=Test.getStandardPricebookId());
            quo.Template_language__c = lang;

            //Sambath SENG 02.09.2021 increase test class coverage
            quo.Description = 'test';
            quo.Rate_Discount_II__c = 10.00;
            quo.GST_Amount__c = 100;

            insert quo;
            
            QuoteLineItem li = new QuoteLineItem(quoteId = quo.Id, Quantity = 1000, quantity__c = 1000, UnitPrice = 50.0, PricebookEntryId = prBookEntry.id, Description = 'testing Description');
            li.from_Date__c = Date.today();
            li.until_Date__c = Date.today();
            insert li;
            
            QuoteLineItem li2 = new QuoteLineItem(quoteId = quo.Id, Quantity = 2, quantity__c = 2, UnitPrice = 5000.0, PricebookEntryId = prBookEntry.id,  Billing_category__c = 'CPM');
            insert li2;
            
            //Sambath SENG 02.09.2021 increase test class coverage
            QuoteLineItem li3 = new QuoteLineItem(quoteId = quo.Id, Quantity = 3, quantity__c = 2, UnitPrice = 5000.0, PricebookEntryId = prBookEntry.id,  Billing_category__c = 'ABC');
            insert li3;
            
            String str = '/apex/Angebots?Id=' + quo.Id ;
            PageReference pageRef = new PageReference(str);
            Test.setCurrentPage(pageRef);
            
            QuoteUK2018 ac = new QuoteUK2018(new ApexPages.StandardController(quo));

            str = '/apex/Quote?Id=' + quo.Id ;
            pageRef = new PageReference(str);
            Test.setCurrentPage(pageRef);
            QuoteController qc = new QuoteController(new ApexPages.StandardController(quo));
            
            qc.getCurrencyCode();
            qc.pageBreaker('this is test this is test this is test',5);
            qc.createLineItemList();
            qc.descrPageBreaker(' this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test');
            

            str = '/apex/Angebots?Id=' + quo.Id ;
            pageRef = new PageReference(str);
            Test.setCurrentPage(pageRef);
            
            AngebotControllerOVK acovk = new AngebotControllerOVK(new ApexPages.StandardController(quo));

            
        }
              
        Test.stopTest();
        
    }

    @isTest
    public  static void testClass() {
    
     // new test classes
     FormatHelper.format(123456768,UserInfo.getLocale());
     
     FormatHelper.format(123456768);

     FormatHelper.formatDT(DateTime.newInstance(2021, 04, 12, 0, 0, 0));
     
     FormatHelper.formatDT(DateTime.newInstance(2021, 04, 12, 0, 0, 0), 'MM/DD/YYYY');
    
    }

    @isTest
    public static void TestLocaleFormatter(){
        Decimal val = 100010.15; 
        LocaleFormatter.getLocaleFormat(val, null);
        LocaleFormatter.getCurrency(null);
    }

    /*****************************************************************************************************************************
     @ Method : testAngebotControllerOVK
     @ Author : Sambath Seng (sambath.seng@gaea-sys.com)
     @ Purpose : Increase code coverage for AngebotControllerOVK
    *****************************************************************************************************************************/
    @isTest
    static void testAngebotControllerOVK(){
          
        Test.startTest();

        RecordType accRT = [SELECT id FROM recordType WHERE sobjectType = 'Account' AND name = 'Advertiser'];

        Account acc = new Account();
        acc.Name = 'TestingTestingtestingtestingtestingtestingtesting';
        acc.recordTypeId = accRT.id;
        acc.Record_Type_Text__c = 'Advertiser';
        insert acc;
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'Test';
        con.Phone = '+41 999 9999 99';
        con.Account = acc;
        con.MailingCity = 'Test';
        con.AccountId = acc.Id;
        insert con;
   
        Product2 product = new Product2();
        product.Name = 'TestTestTest TestTestTest TestTest TestTestTest TestTest';
        product.IsActive = true;
        insert product;
        
        PriceBookEntry prBookEntry = new PriceBookEntry();
        prBookEntry.Product2Id = product.Id;
        prBookEntry.IsActive = true;
        prBookEntry.UseStandardPrice = false; 
        prBookEntry.PriceBook2Id = Test.getStandardPricebookId(); 
        prBookEntry.UnitPrice = 0;             
        insert prBookEntry;

        EBH_ActiveTriggers__c activeTrigger = new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller');
        insert activeTrigger;
        
        String lang  = 'English';

        byPass__c settings = byPass__c.getOrgDefaults();
        settings.byPass_WFRule__c = true;
        upsert settings byPass__c.Id;

        Opportunity opp = new Opportunity(Name = 'Test', Account = acc, CloseDate = system.today());
        opp.StageName = 'Test';
        opp.Description = 'teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting abcDDEqwert teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting AAAAAAA ggggggg \n \n teeeeeeeeeeeeessssting teeeeeeeeeeeeessssting \n \n teeeeeeeeeeeeessssting \n \n  abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz';
        opp.Agency__c = acc.Id;
        opp.AccountId = acc.Id;
        insert opp;
        
        OpportunityContactRole oppConRole = new OpportunityContactRole();
        oppConRole.OpportunityId = opp.Id;
        oppConRole.ContactId = con.Id;
        oppConRole.IsPrimary = false;
        
        insert oppConRole;
        
        Quote quo = new Quote(opportunityId=opp.id, name='TEST',  pricebook2id=Test.getStandardPricebookId());
        quo.Template_language__c = lang;
        quo.Description = 'test';
        quo.Rate_Discount_II__c = 10.00;
        quo.GST_Amount__c = 100;
        insert quo;
        
        QuoteLineItem li = new QuoteLineItem(quoteId = quo.Id, Quantity = 1000, quantity__c = 1000, UnitPrice = 50.0, PricebookEntryId = prBookEntry.id, Description = 'testing Description');
        li.from_Date__c = Date.today();
        li.until_Date__c = Date.today();
        insert li;
        
        QuoteLineItem li2 = new QuoteLineItem(quoteId = quo.Id, Quantity = 2, quantity__c = 2, UnitPrice = 5000.0, PricebookEntryId = prBookEntry.id,  Billing_category__c = 'CPM');
        insert li2;
        
        String str = '/apex/Angebots?Id=' + quo.Id ;
        PageReference pageRef = new PageReference(str);
        Test.setCurrentPage(pageRef);
        
        QuoteUK2018 ac = new QuoteUK2018(new ApexPages.StandardController(quo));

        str = '/apex/Quote?Id=' + quo.Id ;
        pageRef = new PageReference(str);
        Test.setCurrentPage(pageRef);
        QuoteController qc = new QuoteController(new ApexPages.StandardController(quo));
        
        qc.getCurrencyCode();
        qc.pageBreaker('this is test this is test this is test',5);
        qc.createLineItemList();
        qc.descrPageBreaker(' this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test this is test');
        

        str = '/apex/Angebots?Id=' + quo.Id ;
        pageRef = new PageReference(str);
        Test.setCurrentPage(pageRef);
        
        AngebotControllerOVK acovk = new AngebotControllerOVK(new ApexPages.StandardController(quo));          
              
        Test.stopTest();
        
    }


}