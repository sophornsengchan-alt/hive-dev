@isTest
public class TST_LC_AddPricebook2Quote {
    private static Quote quote;
    private static Opportunity opp;
    private static Account acc;
    private static byPass__c bp;

    static void setupData(){
        
        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = false);
        insert bp;

        acc = TST_DataGenerator.generateAccount();
        insert acc;

        opp = TST_DataGenerator.generateOpp(acc.Id);
        opp.Special_Terms__c = 'New Terms - Spe';
        opp.StageName = 'Qualified Meeting';
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
    }

    /*****************************************************************************************************************************
    @ Method:   testGetPricebookData
    @ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:	US-0009102 - [Ads 2020] Product Config - Roles and Pricebooks
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0009102 23.02.2021 / Sophal Noch / create method.
    *****************************************************************************************************************************/
    static testMethod void testGetPricebookData(){
        setupData();

        Pricebook2 book = new Pricebook2(Name='Advertising UK');
        insert book;

        List<Pricebook2> pricebook = LC_AddPricebook2Quote.getPricebookData(null, opp.Id);

       String result = LC_AddPricebook2Quote.updateQuoteField(quote.Id,book.Id);

       System.assertEquals('SUCCESS', result);

    }

}