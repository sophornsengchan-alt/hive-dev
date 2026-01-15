/*********************************************************************************************************************************
@ Class:          AccountTurnoverTest
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        Test class for AccountTurnover
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  12.03.2021 / Mony Nou / Created the  class.
@ Change history:  13.12.2023 / Vimean Heng / Fix Apex CPU Limit.
*********************************************************************************************************************************/
@isTest
private class AccountTurnoverTest {

    @isTest
    static void testAccountTurnoverSchedule(){
        for (Ad_Product__c ad : [SELECT Id, Total_price_incl_Targeting__c, Quantity__c, Billing_Category__c, UnitPrice__c, Targeting_fee__c FROM Ad_Product__c]) {
            System.debug('##### ad :: ' + ad);
        }
        Test.startTest();
            AccountTurnover accountTurnover = new AccountTurnover();
            accountTurnover.execute(null);
        Test.StopTest();

        for (Account acc : [SELECT Id,Name, Turnover_180_Days__c, Turnover_Calendar_Year__c, Turnover_actual_by_delivery__c FROM Account]) {
            System.debug('##### acc :: ' + acc);
        }
    }
    /********************************************************************************************************
     @ Change history:  13.12.2023 / Vimean Heng / US-0014430 / Fix Apex CPU Limit
     ********************************************************************************************************/
    @testSetup 
    static void setup() {

        byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = true, byPass_WFRule__c = true,ByPass_Validation__c=true);
        insert bp;
        
        Account account = TST_DataGenerator.generateAccount();
        account.Country_Code__c = 'DE';
        account.Turnover_180_Days__c            = 0.0;
        account.Turnover_Calendar_Year__c       = 0.0;
        account.Turnover_actual_by_delivery__c  = 0.0;
        
        Account account2 = TST_DataGenerator.generateAccount();
        account2.Name = 'Account test2';
        account2.Phone = '+1230987654';
        account2.Turnover_180_Days__c            = 0.0;
        account2.Turnover_Calendar_Year__c       = 0.0;
        account2.Turnover_actual_by_delivery__c  = 0.0;
        account2.Country_Code__c = 'DE';
        
        insert new List<Account>{account, account2};
            
        Contact con1 = new Contact(
            FirstName='Test', 
            LastName='Contact 1', 
            AccountId=account.Id, 
            Contact_Role__c='Billing Contact',
            Email='billing1@test.com'
        );
        Contact con2 = new Contact(
            FirstName='Test', 
            LastName='Contact 2', 
            AccountId=account2.Id, 
            Contact_Role__c='Billing Contact',
            Email='billing2@test.com'
        );
        insert new List<Contact>{con1, con2};

        Opportunity opp = TST_DataGenerator.generateOpp(account.Id);
        opp.RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id;
        opp.Bill_To_Party__c = 'Advertiser';
        
        Opportunity opp2 = TST_DataGenerator.generateOpp(account2.Id);
        opp2.RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id;
        opp2.Bill_To_Party__c = 'Advertiser';
        insert new List<Opportunity>{opp, opp2};


        Site__c site = generateSite();
        insert site;

        Product2 prod1 = generateProduct(site.Id);
        insert prod1;

        Id book1Id = Test.getStandardPriceBookId();
        
        PriceBookEntry pbe1 = generatePricebookEntry(prod1.id, book1Id);
        insert pbe1;
        
        Quote quote1 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp.Id, Pricebook2Id = book1Id, Is_Revised_Quote__c = false, Primary_Quote__c = true);
        Quote quote2 = new Quote(Name = 'q2', Status= 'Draft', OpportunityId = opp2.Id, Pricebook2Id = book1Id, Is_Revised_Quote__c = false, Primary_Quote__c = true);
        insert new List<Quote>{quote1, quote2};

        quote1.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote1.Primary_Quote__c= true;
        quote1.status = 'Approved';
        quote1.Dually_Signed__c = true;
        
        quote2.RecordTypeId = ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote2.Primary_Quote__c= true;
        quote2.status = 'Approved';
        quote2.Dually_Signed__c = true;
        
        //update new List<Quote>{quote1, quote2};

        Decimal qli1ToAdProd1 = 100;
        Decimal qli2ToAdProd2 = 200;
        Decimal qli3ToAdProd3 = 300;

        Integer offSet5Days = 5;

        Date startDate = Date.today().toStartOfMonth().addMonths(-1);
        Date endDate = startDate.addMonths(2).toStartOfMonth().addDays(10); // 1 + 10 = 11

        QuoteLineItem qli1 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = qli1ToAdProd1;
        qli1.from_Date__c = startDate;
        qli1.until_Date__c = endDate;


        QuoteLineItem qli2 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli2.Budget__c = qli2ToAdProd2;
        qli2.from_Date__c = startDate;
        qli2.until_Date__c = endDate;


        QuoteLineItem qli3 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli3.Budget__c = qli3ToAdProd3;
        qli3.from_Date__c = startDate.addDays(offSet5Days);
        qli3.until_Date__c = endDate;

        insert new List<QuoteLineItem>{qli1, qli2, qli3};


        Ad_Product__c adProd1 = new Ad_Product__c(
            TotalPrice__c = qli1ToAdProd1,
            from_Date__c = startDate,
            until_Date__c = endDate,
            Opportunity__c = opp.Id,
            Amount_Net_Net_Net__c = 100,
            Turnover_actual_by_delivery__c = 50,
            Quantity__c = 3
        );

        Ad_Product__c adProd2 = new Ad_Product__c(
            TotalPrice__c = qli2ToAdProd2,
            from_Date__c = startDate,
            until_Date__c = endDate,
            Opportunity__c = opp.Id,
            Amount_Net_Net_Net__c = 100,
            Turnover_actual_by_delivery__c = 50,
            Quantity__c = 3
        );

        Ad_Product__c adProd3 = new Ad_Product__c(
            TotalPrice__c = qli3ToAdProd3,
            from_Date__c = startDate.addDays(offSet5Days),
            until_Date__c = endDate,
            Opportunity__c = opp.Id,
            Amount_Net_Net_Net__c = 100,
            Turnover_actual_by_delivery__c = 50,
            Quantity__c = 3
        );

        insert new List<Ad_Product__c>{adProd1, adProd2, adProd3};

        qli1.AdProduct__c = adProd1.Id;
        qli2.AdProduct__c = adProd2.Id;
        qli3.AdProduct__c = adProd3.Id;

        update new List<QuoteLineItem>{qli1, qli2,qli3};

        opp.StageName = 'Closed Won';
        opp2.StageName = 'Closed Won';
        update new List<Opportunity>{opp, opp2};
        
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

    
    
}