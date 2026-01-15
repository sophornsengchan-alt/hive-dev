/*********************************************************************************************************************************
@ Class:          CreateRevisedQuoteControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Test class for CreateRevisedQuoteController.cls
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  21.10.2020 / Sophal Noch / Created the class.
                :  11.09.2023 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync    
*********************************************************************************************************************************/
@isTest
private class CreateRevisedQuoteControllerTest {

    public static Account account;
    public static  IO__c io;
    public static Opportunity opp1;
    public static Opportunity opp2;
    public static Integer currentYear = System.Today().year();

    public static Date startDate;
    public static Date endDate;

    public static Quote quote1;
    public static Quote quote2;
    public static Quote quote1ForOpp2;

    public static Site__c site;
    public static Product2 prod1;
    public static Product2 prod2;

    public static Id book1Id;
    public static Id book2Id;

    public static PriceBookEntry pbe1; 
    public static PriceBookEntry pbe2;

    public static QuoteLineItem qli1;
    public static QuoteLineItem qli2;

    public static Set<String> dataSet = new Set<String>{'Account', 'Opportunity', 'Quote', 'QuoteLineItem'};
    private static RecordType rtAdvertiser = [SELECT id FROM recordType WHERE name = 'Advertiser' AND sobjectType = 'Account'];

    private static Opportunity opp;
    private static Account acc;

    private static byPass__c bp;
    
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

    public static Opportunity generateOpp(Id accId){
    	return new Opportunity(
    		Name = 'Opp test',
    		CloseDate = Date.today() + 90,
    		AccountId = accId,
            StageName = 'Qualified Meeting'
    		);
    }

    public static Quote generateQuote(Id oppId, Id mediaPlanId ){
    	return new Quote(
    		Name = 'Quote Test',
    		OpportunityId = oppId,
    		Media_Plan__c = mediaPlanId,
            Pricebook2Id=Test.getStandardPriceBookId()
    		);
    }

    private static void setUpQuote(){

        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Opportunity Quote QuoteLineItem', byPass_Trigger__c = false,ByPass_Validation__c=true,byPass_WFRule__c=true);
        bp.byPass_Trigger__c = true; // 11.09.2023 / Sophal Noch / US-0014020 : fix cpu limit in test class
        insert bp;

        account = generateAccount();
        insert account;

        startDate = Date.today();
        endDate = startDate.addMonths(3);

        opp1 = new Opportunity(
                Name = 'Opp 1',
                Amount = 100,
                StageName = 'Closed Won',
                CloseDate = Date.newInstance( currentYear, 1, 1),
                Start_Date__c = startDate,
                End_Date__c = endDate
        );

       
        opp2 = new Opportunity(
                Name = 'Opp 2',
                Amount = 200,
                StageName = 'Qualified Meeting',
                CloseDate = Date.newInstance( currentYear, 1, 1),
                Start_Date__c = startDate,
                End_Date__c = endDate
        );

        insert new List<Opportunity>{opp1,opp2};


        site = generateSite();
        insert site;

        prod1 = generateProduct(site.Id);
        prod2 = generateProduct(site.Id);
        insert new List<Product2>{prod1, prod2};

        book1Id = Test.getStandardPriceBookId();
        book2Id = Test.getStandardPriceBookId();
        
        pbe1 = generatePricebookEntry(prod1.id, book1Id);
        pbe2 = generatePricebookEntry(prod2.id, book2Id);
        insert new List<PriceBookEntry>{pbe1, pbe2};

        quote1 = new Quote(Name = 'q1', Status= 'Draft', OpportunityId = opp1.Id, Pricebook2Id = book1Id);
        quote2 = new Quote(Name = 'q2', Status= 'Draft', OpportunityId = opp1.Id, Pricebook2Id = book2Id);

        quote1ForOpp2 = new Quote(Name = 'q1ForOpp2', Primary_Quote__c = true, Status= 'Draft', OpportunityId = opp2.Id, Pricebook2Id = Test.getStandardPriceBookId());

        insert new List<Quote>{quote1,quote2,quote1ForOpp2};

        quote1.Primary_Quote__c = false;
        quote2.Primary_Quote__c = false;
        update new List<Quote>{quote1,quote2};


        qli1 = generateQuoteLinItem( quote1.id, prod1.id, pbe1.id);
        qli1.Budget__c = 30;

        qli2 = generateQuoteLinItem( quote2.id, prod2.id, pbe2.id);
        qli2.Budget__c = 55;
        insert new List<QuoteLineItem>{qli1, qli2};

    }


    static void setUpQuote2(){

        byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = true);
        insert bp;

        acc = generateAccount();
        acc.Record_Type_Text__c = 'Advertiser';
        acc.Payment_Terms__c = 'NT00';
        insert acc;

        insert new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = acc.Id, Contact_Role__c = 'Billing Contact');
        
        opp = generateOpp(acc.Id);
        opp.Special_Terms__c = 'New Terms - Spe';
        opp.StageName = 'Qualified Meeting';
        opp.Bill_To_Party__c = 'Advertiser';
        insert opp;

        quote1 = generateQuote(opp.Id, null);
        quote1.Name= 'Test QUOTE 1';
        quote1.RecordTypeId =  ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id;
        quote1.Primary_Quote__c = true; // workflow will update this to true anyway
        insert quote1;
       
    }

    
    /*****************************************************************************************************************************
    @ Method:       testApexInit
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008517 test method CreateRevisedQuoteController.apexInit
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.10.2020 / Sophal Noch / Created the class.
    @               :  11.09.2023 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync
    @*****************************************************************************************************************************/
    static testMethod void testApexInit() {
        setUpQuote();
        Map<String,Object> mapResult = CreateRevisedQuoteController.apexInit(opp1.Id);
        System.assertEquals('ko', mapResult.get('status'));
        System.assertEquals(System.Label.Error_Revised_Quote_Can_Not_Be_Created, mapResult.get('error'));


        quote2.Primary_Quote__c = true;
        bp.byPass_Trigger__c = false; //  11.09.2023 / Sophal Noch / US-0014020 : fix cpu limit in test class 
        update bp;
        update quote2;

        Test.startTest();
        mapResult = CreateRevisedQuoteController.apexInit(opp1.Id);
        Test.stopTest();
        System.assertEquals(null, mapResult.get('error'));
        System.assertEquals('ok', mapResult.get('status'));
        

        Quote quote3 = [
            Select Id,Name,Is_Revised_Quote__c,
            (Select Id, Budget__c From QuoteLineItems) 
            From Quote Where OpportunityId =:opp1.Id
            And Id Not In: new Set<Id>{quote1.Id,quote2.Id}
        ];

        System.assertEquals(true, quote3.Is_Revised_Quote__c);
        System.assertEquals(1, quote3.QuoteLineItems.size());
        System.assertEquals(55, quote3.QuoteLineItems[0].Budget__c);
        // System.assertEquals(opp1.Name+' v3',  quote3.Name);
        System.assertEquals(true,quote3.Name.contains('v3'));

    }

    /*****************************************************************************************************************************
    @ Method:       testSetRevisedQuoteToPrimary
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008517 test method for CreateRevisedQuoteController.setRevisedQuoteToPrimary
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.10.2020 / Sophal Noch / Created the class.
    @               :  11.09.2023 / Sophal Noch / US-0014020 - US-0014020 - PL Opportunity Process - Ad product Sync
    @*****************************************************************************************************************************/
    static testMethod void testSetRevisedQuoteToPrimary() {
        setUpQuote();
        quote1.Primary_Quote__c = true; // set quote 1 as primary
        quote2.Primary_Quote__c = false; 

        List<Quote> listQuoteToUpdate = new List<Quote>{quote1,quote2};
  
        bp.byPass_Trigger__c = false; //  11.09.2023 / Sophal Noch / US-0014020 : fix cpu limit in test class
        update bp;
        update listQuoteToUpdate;

        Test.startTest();
        CreateRevisedQuoteController.setRevisedQuoteToPrimary(new List<Quote>{quote2}); // set quote 2 as primary, and quote 1 not primary
        Test.stopTest();

        List<Quote> listQueriedQuote = [Select Id,Primary_Quote__c From Quote Where Id IN : listQuoteToUpdate OR Id =:quote1ForOpp2.Id Order By Id Asc];

        System.assertEquals(false, listQueriedQuote[0].Primary_Quote__c); // quote 1, primary = false

        System.assertEquals(true, listQueriedQuote[1].Primary_Quote__c); // quote 2, primary = true

        System.assertEquals(true, listQueriedQuote[2].Primary_Quote__c); // quote 1 opp 2, still primary = true

    }


    /*****************************************************************************************************************************
    @ Method:       testRevisePackageQli
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0009885 test method when package qli is revised
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.06.2021 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    @isTest
    static void testRevisePackageQli() {
        setUpQuote2();

        quote1.Pricebook2Id=Test.getStandardPriceBookId();
        quote1.Status = 'Approved';
        quote1.Dually_Signed__c = true;
        quote1.Buyer_Accepted__c = true;
        update quote1;


        // 30.06.2021 / Sophal Noch / US-0009885 insert products
        RecordType rt_roDart6 = ApexUtil.getRecordTypeByName('Product2', 'DART6');
        RecordType rt_proPackage = ApexUtil.getRecordTypeByName('Product2', 'Package');

        Site__c site = generateSite();
        insert site;

        Product2 product1 = generateProduct(site.Id);
        product1.IsActive = true;
        product1.RecordTypeId = rt_roDart6.Id;

        Product2 product2Pk = generateProduct(site.Id);
        product2Pk.RecordTypeId = rt_proPackage.Id;
        product2Pk.Name = 'package test';
        product2Pk.IsActive = true;
        Product2 product2Component1 = generateProduct(site.Id);
        product2Component1.RecordTypeId = rt_roDart6.Id;
        product2Component1.IsActive = true;
        Product2 product2Component2 = generateProduct(site.Id);
        product2Component2.RecordTypeId = rt_roDart6.Id;
        product2Component2.IsActive = true;

        Product2 product3 = generateProduct(site.Id);
        product3.IsActive = true;
        product3.RecordTypeId = rt_roDart6.Id;

        Product2 product4Pk = generateProduct(site.Id);
        product4Pk.RecordTypeId = rt_proPackage.Id;
        product4Pk.Name = 'package test 2';
        product4Pk.IsActive = true;
        Product2 product4Component1 = generateProduct(site.Id);
        product4Component1.RecordTypeId = rt_roDart6.Id;
        product4Component1.IsActive = true;
        Product2 product4Component2 = generateProduct(site.Id);
        product4Component2.RecordTypeId = rt_roDart6.Id;
        product4Component2.IsActive = true;

        Product2 product5 = generateProduct(site.Id);
        product5.IsActive = true;
        product5.RecordTypeId = rt_roDart6.Id;


        insert new List<Product2>{product1,product2Pk,product2Component1,product2Component2,product3,product4Pk,product4Component1,product4Component2,product5};

        // 30.06.2021 / Sophal Noch / US-0009885 insert pricebook entry
        PriceBookEntry pbe1 = generatePricebookEntry(product1.Id,null);
        PriceBookEntry pbe2Pk = generatePricebookEntry(product2Pk.Id,null);
        PriceBookEntry pbe2comp1 = generatePricebookEntry(product2Component1.Id,null);
        PriceBookEntry pbe2comp2 = generatePricebookEntry(product2Component2.Id,null);
        PriceBookEntry pbe3 = generatePricebookEntry(product3.Id,null);
        PriceBookEntry pbe4Pk = generatePricebookEntry(product4Pk.Id,null);
        PriceBookEntry pbe4comp1 = generatePricebookEntry(product4Component1.Id,null);
        PriceBookEntry pbe4comp2 = generatePricebookEntry(product4Component2.Id,null);
        PriceBookEntry pbe5 = generatePricebookEntry(product5.Id,null);

        insert new List<PriceBookEntry>{pbe1,pbe2Pk,pbe2comp1,pbe2comp2,pbe3,pbe4Pk,pbe4comp1,pbe4comp2,pbe5};


        // 30.06.2021 / Sophal Noch / US-0009885 insert product package
        Product_Package__c pp2comp1 = new Product_Package__c(Product__c=product2Component1.Id,Package_Product__c=product2Pk.Id);
        Product_Package__c pp2comp2 = new Product_Package__c(Product__c=product2Component2.Id,Package_Product__c=product2Pk.Id);

        Product_Package__c pp4comp1 = new Product_Package__c(Product__c=product4Component1.Id,Package_Product__c=product4Pk.Id);
        Product_Package__c pp4comp2 = new Product_Package__c(Product__c=product4Component2.Id,Package_Product__c=product4Pk.Id);
        
        insert new List<Product_Package__c>{pp2comp1,pp2comp2,pp4comp1,pp4comp2};


        // 30.06.2021 / Sophal Noch / US-0009885 insert quotelineitem for parent qli
        QuoteLineItem qliP1 = generateQuoteLinItem(quote1.Id, product1.Id, pbe1.Id);
        QuoteLineItem qliP2Pk = generateQuoteLinItem(quote1.Id, product2Pk.Id, pbe2Pk.Id);
        qliP2Pk.Description = 'test qli 2';
        QuoteLineItem qliP3 = generateQuoteLinItem(quote1.Id, product3.Id, pbe3.Id);
        QuoteLineItem qliP4Pk = generateQuoteLinItem(quote1.Id, product4Pk.Id, pbe4Pk.Id);
        qliP4Pk.Description = 'test qli 4';
        QuoteLineItem qliP5 = generateQuoteLinItem(quote1.Id, product5.Id,pbe5.Id);

        List<QuoteLineItem> mainQli = new List<QuoteLineItem>{qliP1,qliP2Pk,qliP3,qliP4Pk,qliP5};
        insert mainQli;
        

        // 30.06.2021 / Sophal Noch / US-0009885 insert quotelineitem for child qli
        QuoteLineItem qliP2Comp1 = generateQuoteLinItem(quote1.Id, product2Component1.Id, pbe2comp1.Id);
        qliP2Comp1.package_line_item__c = qliP2Pk.Id;
        qliP2Comp1.Description = qliP2Pk.Description;
        QuoteLineItem qliP2Comp2 = generateQuoteLinItem(quote1.Id, product2Component2.Id, pbe2comp2.Id);
        qliP2Comp2.package_line_item__c = qliP2Pk.Id;
        qliP2Comp2.Description = qliP2Pk.Description;

        QuoteLineItem qliP4Comp1 = generateQuoteLinItem(quote1.Id, product4Component1.Id, pbe4comp1.Id);
        qliP4Comp1.package_line_item__c = qliP4Pk.Id;
        qliP4Comp1.Description = qliP4Pk.Description;
        QuoteLineItem qliP4Comp2 = generateQuoteLinItem(quote1.Id, product4Component2.Id, pbe4comp2.Id);
        qliP4Comp2.package_line_item__c = qliP4Pk.Id;
        qliP4Comp2.Description = qliP4Pk.Description;

        List<QuoteLineItem> childQli = new List<QuoteLineItem>{qliP2Comp1,qliP2Comp2,qliP4Comp1,qliP4Comp2};
        insert childQli;

        Test.startTest();

            // 30.06.2021 / Sophal Noch / US-0009885 revised quote and qli
            Map<String,Object> mapResult = CreateRevisedQuoteController.apexInit(opp.Id);
            System.assert(mapResult != null);
            System.assertEquals(null, mapResult.get('error'));
            System.assertEquals('ok', mapResult.get('status'));

            // 30.06.2021 / Sophal Noch / US-0009885 test when package qli is revised
            List<QuoteLineItem> revisedParentQli = [Select Id,Description from QuoteLineItem Where QuoteId !=: quote1.Id And package_line_item__c = null Order by Id Asc];
            System.assertEquals(5, revisedParentQli.size());


            List<QuoteLineItem> revisedChildQli = [Select Id,Description, package_line_item__c from QuoteLineItem Where QuoteId !=: quote1.Id And package_line_item__c != null Order by package_line_item__c, Id Asc];
            System.assertEquals(4, revisedChildQli.size());


            // check package_line_item is set corrected for child package qli
            System.assertEquals(revisedParentQli[1].Id, revisedChildQli[0].package_line_item__c);
            System.assertEquals(revisedParentQli[1].Description, revisedChildQli[0].Description);
            System.assertEquals(revisedParentQli[1].Id, revisedChildQli[1].package_line_item__c);
            System.assertEquals(revisedParentQli[1].Description, revisedChildQli[1].Description);

            System.assertEquals(revisedParentQli[3].Id, revisedChildQli[2].package_line_item__c);
            System.assertEquals(revisedParentQli[3].Description, revisedChildQli[2].Description);
            System.assertEquals(revisedParentQli[3].Id, revisedChildQli[3].package_line_item__c);
            System.assertEquals(revisedParentQli[3].Description, revisedChildQli[3].Description);

        Test.stopTest();
    }

}