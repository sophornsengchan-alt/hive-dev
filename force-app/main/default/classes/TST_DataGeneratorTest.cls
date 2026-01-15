@isTest
public class TST_DataGeneratorTest {

    @isTest
    static void testGenerateAccount() {
        Account acc = TST_DataGenerator.generateAccount();
        insert acc;
        System.assertNotEquals(null, acc.Id, 'Account should be inserted');
    }

    @isTest
    static void testGenerateOpp() {
        Account acc = TST_DataGenerator.generateAccount();
        insert acc;
        Opportunity opp = TST_DataGenerator.generateOpp(acc.Id);
        insert opp;
        System.assertNotEquals(null, opp.Id, 'Opportunity should be inserted');
    }

    @isTest
    static void testGenerateQuote() {
        Account acc = TST_DataGenerator.generateAccount();
        insert acc;
        Opportunity opp = TST_DataGenerator.generateOpp(acc.Id);
        insert opp;
        Quote q = TST_DataGenerator.generateQuote(opp.Id);
        insert q;
        System.assertNotEquals(null, q.Id, 'Quote should be inserted');
    }

    @isTest
    static void testGenerateAdServerLogin() {
        AdServer_Login__c ad = TST_DataGenerator.generateAdServerLogin();
        insert ad;
        System.assertNotEquals(null, ad.Id, 'AdServer_Login__c should be inserted');
    }

    @isTest
    static void testGenerateProduct() {
        Product2 prod = TST_DataGenerator.generateProduct();
        insert prod;
        System.assertNotEquals(null, prod.Id, 'Product2 should be inserted');
    }

    @isTest
    static void testGenerateSite() {
        Site__c site = TST_DataGenerator.generateSite();
        insert site;
        System.assertNotEquals(null, site.Id, 'Site__c should be inserted');
    }

    @isTest
    static void testGeneratePricebookEntry() {
        Product2 prod = TST_DataGenerator.generateProduct();
        insert prod;
        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(prod.Id, null);
        insert pbe;
        System.assertNotEquals(null, pbe.Id, 'PriceBookEntry should be inserted');
    }

    @isTest
    static void testGenerateQuoteLineItem() {
        Account acc = TST_DataGenerator.generateAccount();
        insert acc;
        Opportunity opp = TST_DataGenerator.generateOpp(acc.Id);
        insert opp;
        Quote q = TST_DataGenerator.generateQuote(opp.Id);
        insert q;
        Product2 prod = TST_DataGenerator.generateProduct();
        insert prod;
        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(prod.Id, null);
        insert pbe;
        QuoteLineItem qli = TST_DataGenerator.generateQuoteLinItem(q.Id, prod.Id, pbe.Id);
        insert qli;
        System.assertNotEquals(null, qli.Id, 'QuoteLineItem should be inserted');
    }

    @isTest
    static void testGenerateOpportunityLineItem() {
        Account acc = TST_DataGenerator.generateAccount();
        insert acc;
        Opportunity opp = TST_DataGenerator.generateOpp(acc.Id);
        insert opp;
        Product2 prod = TST_DataGenerator.generateProduct();
        insert prod;
        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(prod.Id, null);
        insert pbe;
        Targeting__c tg = TST_DataGenerator.generateTargeting();
        OpportunityLineItem oli = TST_DataGenerator.generateOpportunityLinItem(opp.Id, pbe.Id, tg.Id);
        insert oli;
        System.assertNotEquals(null, oli.Id, 'OpportunityLineItem should be inserted');
    }

    @isTest
    static void testCreateTargetingObject() {
        Targeting__c tg = TST_DataGenerator.createTargetingObject();
        System.assertNotEquals(null, tg.Id, 'Targeting__c should be inserted');
    }

    @isTest
    static void testSetupSimpleData() {
        Set<String> config = new Set<String>{'Account', 'Opportunity', 'Quote', 'QuoteLineItem', 'Targeting__c'};
        Map<String, List<SObject>> data = TST_DataGenerator.setupSimpleData(config);
        System.assert(data.containsKey('Account'), 'Should contain Account');
        System.assert(data.containsKey('Opportunity'), 'Should contain Opportunity');
        System.assert(data.containsKey('Quote'), 'Should contain Quote');
        System.assert(data.containsKey('QuoteLineItem'), 'Should contain QuoteLineItem');
        System.assert(data.containsKey('Targeting__c'), 'Should contain Targeting__c');
    }

    @isTest
    static void testSetUpTargetingData() {
        Map<String, List<SObject>> data = TST_DataGenerator.setUpTargetingData();
        System.assert(data.containsKey('Account'), 'Should contain Account');
        System.assert(data.containsKey('Opportunity'), 'Should contain Opportunity');
        System.assert(data.containsKey('Quote'), 'Should contain Quote');
        System.assert(data.containsKey('QuoteLineItem'), 'Should contain QuoteLineItem');
        System.assert(data.containsKey('Targeting__c'), 'Should contain Targeting__c');
    }
}