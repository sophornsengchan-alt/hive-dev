/*********************************************************************************************************************************
@ Class:          CloneQuoteControllerTest
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        US-0009693 - Modify Clone Quote Functionality.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.06.2021 / Mony Nou / Created the class.
                  
*********************************************************************************************************************************/
@isTest
private class CloneQuoteControllerTest {
    
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
        quote.Legacy_SFDC_ID__c = '123456789';
        insert quote;
       
    }

    @isTest
    static void test_cloneQuote() {

        setupData();
        
        Test.startTest();

            //1) Check user permission
            Boolean bol_res = CloneQuoteController.isValid();
            System.assert(bol_res, 'The result should be true.');

            //2) Init Page
            Map<String,Object> m_res = CloneQuoteController.apexInit(opp.Id);
            System.assert(m_res != null, 'The result should not null.');

            //3) Clone Quote
            m_res = CloneQuoteController.apexSave(quote.Id, opp.Id);
            System.assert(m_res != null && m_res.containsKey('status') && m_res.get('status') == 'ok', 'The result should not null.');

            Quote newQuote = [Select Id,Legacy_SFDC_ID__c from Quote Where Id <> : quote.Id];
            System.assertEquals(null, newQuote.Legacy_SFDC_ID__c); // Sophal: 02/08/2021: US-0010053

        Test.stopTest();
    }

    @isTest
    static void test_cloneQli() {

        setupData();

        Boolean bol_res = CloneQuoteController.isValid();
        System.assert(bol_res, 'The result should be true.');

        //2) Init Page
        Map<String,Object> m_res = CloneQuoteController.apexInit(opp.Id);
        System.assert(m_res != null, 'The result should not null.');

        quote.Pricebook2Id=Test.getStandardPriceBookId();
        update quote;


        // 29.05.2021 / Sophal Noch / US-0009753 insert products
        RecordType rt_roDart6 = ApexUtil.getRecordTypeByName('Product2', 'DART6');
        RecordType rt_proPackage = ApexUtil.getRecordTypeByName('Product2', 'Package');

        Product2 product1 = TST_DataGenerator.generateProduct();
        product1.IsActive = true;
        product1.RecordTypeId = rt_roDart6.Id;

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

        Product2 product3 = TST_DataGenerator.generateProduct();
        product3.IsActive = true;
        product3.RecordTypeId = rt_roDart6.Id;

        Product2 product4Pk = TST_DataGenerator.generateProduct();
        product4Pk.RecordTypeId = rt_proPackage.Id;
        product4Pk.Name = 'package test 2';
        product4Pk.IsActive = true;
        Product2 product4Component1 = TST_DataGenerator.generateProduct();
        product4Component1.RecordTypeId = rt_roDart6.Id;
        product4Component1.IsActive = true;
        Product2 product4Component2 = TST_DataGenerator.generateProduct();
        product4Component2.RecordTypeId = rt_roDart6.Id;
        product4Component2.IsActive = true;

        Product2 product5 = TST_DataGenerator.generateProduct();
        product5.IsActive = true;
        product5.RecordTypeId = rt_roDart6.Id;


        insert new List<Product2>{product1,product2Pk,product2Component1,product2Component2,product3,product4Pk,product4Component1,product4Component2,product5};

        // 29.05.2021 / Sophal Noch / US-0009753 insert pricebook entry
        PriceBookEntry pbe1 = TST_DataGenerator.generatePricebookEntry(product1.Id,null);
        PriceBookEntry pbe2Pk = TST_DataGenerator.generatePricebookEntry(product2Pk.Id,null);
        PriceBookEntry pbe2comp1 = TST_DataGenerator.generatePricebookEntry(product2Component1.Id,null);
        PriceBookEntry pbe2comp2 = TST_DataGenerator.generatePricebookEntry(product2Component2.Id,null);
        PriceBookEntry pbe3 = TST_DataGenerator.generatePricebookEntry(product3.Id,null);
        PriceBookEntry pbe4Pk = TST_DataGenerator.generatePricebookEntry(product4Pk.Id,null);
        PriceBookEntry pbe4comp1 = TST_DataGenerator.generatePricebookEntry(product4Component1.Id,null);
        PriceBookEntry pbe4comp2 = TST_DataGenerator.generatePricebookEntry(product4Component2.Id,null);
        PriceBookEntry pbe5 = TST_DataGenerator.generatePricebookEntry(product5.Id,null);

        insert new List<PriceBookEntry>{pbe1,pbe2Pk,pbe2comp1,pbe2comp2,pbe3,pbe4Pk,pbe4comp1,pbe4comp2,pbe5};


        // 29.05.2021 / Sophal Noch / US-0009753 insert product package
        Product_Package__c pp2comp1 = new Product_Package__c(Product__c=product2Component1.Id,Package_Product__c=product2Pk.Id);
        Product_Package__c pp2comp2 = new Product_Package__c(Product__c=product2Component2.Id,Package_Product__c=product2Pk.Id);

        Product_Package__c pp4comp1 = new Product_Package__c(Product__c=product4Component1.Id,Package_Product__c=product4Pk.Id);
        Product_Package__c pp4comp2 = new Product_Package__c(Product__c=product4Component2.Id,Package_Product__c=product4Pk.Id);
        
        insert new List<Product_Package__c>{pp2comp1,pp2comp2,pp4comp1,pp4comp2};

        // 29.05.2021 / Sophal Noch / US-0009753 insert targeting, content, avaialable site for product 1
        Targeting__c prod1Targeting = new Targeting__c(Description__c = 'test targeting prod 1');
        Targeting__c prod3Targeting = new Targeting__c(Description__c = 'test targeting prod 3');
        insert new List<Targeting__c>{prod1Targeting, prod3Targeting};

        Content__c prod1Content = new Content__c(Name = 'Test Prod 1 Content', DartName__c = 'test', Active__c = true);
        Content__c prod3Content = new Content__c(Name = 'Test Prod 3 Content', DartName__c = 'test', Active__c = true);
        insert new List<Content__c>{prod1Content, prod3Content};

        TargetingContentAssociation__c prod1TargetingContent = new TargetingContentAssociation__c(
                                                                Targeting__c = prod1Targeting.Id, 
                                                                TargetingContent__c = prod1Content.Id);

        TargetingContentAssociation__c prod3TargetingContent = new TargetingContentAssociation__c(
                                                                Targeting__c = prod3Targeting.Id, 
                                                                TargetingContent__c = prod3Content.Id
        );
        insert new List<TargetingContentAssociation__c>{prod1TargetingContent,prod3TargetingContent};

        Devices__c operatingSystem = new Devices__c(DFP_API_Name__c='OperatingSystem', Dart_ID__c = 55555);
        Devices__c mobileDevice = new Devices__c(DFP_API_Name__c='MobileDevice', Dart_ID__c = 77777);
        insert new List<Devices__c>{operatingSystem, mobileDevice};

        TargetingDeviceAssociation__c prod1targetDeviceAssoc = new TargetingDeviceAssociation__c(Device__c=operatingSystem.Id,Targeting__c=prod1Targeting.Id);
        TargetingDeviceAssociation__c prod3targetDeviceAssoc = new TargetingDeviceAssociation__c(Device__c=mobileDevice.Id,Targeting__c=prod3Targeting.Id);
        insert new List<TargetingDeviceAssociation__c>{prod1targetDeviceAssoc,prod3targetDeviceAssoc};

        Available_Site__c prod1Avs = new Available_Site__c (Available_Site__c = prod1Content.Id, Product__c=product1.Id);
        Available_Site__c prod3Avs = new Available_Site__c (Available_Site__c = prod3Content.Id, Product__c=product3.Id);

        insert new List<Available_Site__c>{prod1Avs,prod3Avs};


        // 29.05.2021 / Sophal Noch / US-0009753 insert quotelineitem for parent qli
        QuoteLineItem qliP1 = createItem(quote.Id, product1.Id, prod1Targeting.Id, pbe1.Id, 20, 10);
        QuoteLineItem qliP2Pk = createItem(quote.Id, product2Pk.Id, null, pbe2Pk.Id, 20, 10);
        QuoteLineItem qliP3 = createItem(quote.Id, product3.Id, prod3Targeting.Id, pbe3.Id, 20, 10);
        QuoteLineItem qliP4Pk = createItem(quote.Id, product4Pk.Id, null, pbe4Pk.Id, 20, 10);
        QuoteLineItem qliP5 = createItem(quote.Id, product5.Id, prod3Targeting.Id, pbe5.Id, 20, 10); // this is case where product 3 targeting id is used on product 5 targeting

        List<QuoteLineItem> mainQli = new List<QuoteLineItem>{qliP1,qliP2Pk,qliP3,qliP4Pk,qliP5};
        insert mainQli;
        

        // 29.05.2021 / Sophal Noch / US-0009753 insert quotelineitem for child qli
        QuoteLineItem qliP2Comp1 = createItem(quote.Id, product2Component1.Id, null, pbe2comp1.Id, 20, 10);
        qliP2Comp1.package_line_item__c = qliP2Pk.Id;
        QuoteLineItem qliP2Comp2 = createItem(quote.Id, product2Component2.Id, null, pbe2comp2.Id, 20, 10);
        qliP2Comp2.package_line_item__c = qliP2Pk.Id;

        QuoteLineItem qliP4Comp1 = createItem(quote.Id, product4Component1.Id, null, pbe4comp1.Id, 20, 10);
        qliP4Comp1.package_line_item__c = qliP4Pk.Id;
        QuoteLineItem qliP4Comp2 = createItem(quote.Id, product4Component2.Id, null, pbe4comp2.Id, 20, 10);
        qliP4Comp2.package_line_item__c = qliP4Pk.Id;

        List<QuoteLineItem> childQli = new List<QuoteLineItem>{qliP2Comp1,qliP2Comp2,qliP4Comp1,qliP4Comp2};
        insert childQli;

        Test.startTest();

        // 29.05.2021 / Sophal Noch / US-0009753 clone quote and qli
        Map<String,Object> mapResult = CloneQuoteController.apexSave(quote.Id, opp.Id);
        System.assert(mapResult != null);
        System.assertEquals(null, mapResult.get('error'));
        System.assertEquals('ok', mapResult.get('status'));

        // 29.05.2021 / Sophal Noch / US-0009753 test when package qli is cloned
        List<QuoteLineItem> clonedParentQli = [Select Id,Targeting__c, Targeting__r.Description__c from QuoteLineItem Where QuoteId !=: quote.Id And package_line_item__c = null Order by Id Asc];
        System.assertEquals(5, clonedParentQli.size());
        // not-equal targeting checking for parent qli below:
        System.assertNotEquals(null, clonedParentQli[0].Targeting__c);
        System.assertNotEquals(prod1Targeting.Id, clonedParentQli[0].Targeting__c);
        System.assertNotEquals(null, clonedParentQli[1].Targeting__c);
        System.assertNotEquals(null, clonedParentQli[2].Targeting__c);
        System.assertNotEquals(prod3Targeting.Id, clonedParentQli[2].Targeting__c);
        System.assertNotEquals(null, clonedParentQli[3].Targeting__c);
        System.assertNotEquals(null, clonedParentQli[4].Targeting__c);
        System.assertNotEquals(clonedParentQli[2].Targeting__c, clonedParentQli[4].Targeting__c);
        

        List<TargetingContentAssociation__c> clonedParentQliTarAssc = [Select Id, Targeting__c, TargetingContent__c From TargetingContentAssociation__c 
                                            Where Targeting__c IN: new Set<Id>{clonedParentQli[0].Targeting__c, clonedParentQli[2].Targeting__c, clonedParentQli[4].Targeting__c} 
                                            Order by Targeting__c ASC
        ];
        System.assertNotEquals(prod1TargetingContent.Id, clonedParentQliTarAssc[0].Id);
        System.assertNotEquals(prod3TargetingContent.Id, clonedParentQliTarAssc[1].Id);
        System.assertNotEquals(prod3TargetingContent.Id, clonedParentQliTarAssc[2].Id);


        List<TargetingDeviceAssociation__c> clonedtargetingDevices = [Select id,Targeting__c,Device__c 
                                                from TargetingDeviceAssociation__c 
                                                Where Targeting__c IN: new Set<Id>{clonedParentQli[0].Targeting__c,clonedParentQli[2].Targeting__c, clonedParentQli[4].Targeting__c}
                                                Order by Targeting__c ASC];

        System.assertNotEquals(prod1targetDeviceAssoc.Id, clonedtargetingDevices[0].Id);
        System.assertNotEquals(prod3targetDeviceAssoc.Id, clonedtargetingDevices[1].Id);
        System.assertNotEquals(prod3targetDeviceAssoc.Id, clonedtargetingDevices[2].Id);


        // equal targeting checking for parent qli below:
        System.assertEquals(prod1Targeting.Description__c, clonedParentQli[0].Targeting__r.Description__c);
        System.assertEquals(prod3Targeting.Description__c, clonedParentQli[2].Targeting__r.Description__c);
        System.assertEquals(prod3Targeting.Description__c, clonedParentQli[4].Targeting__r.Description__c);

        System.assertEquals(prod1TargetingContent.TargetingContent__c, clonedParentQliTarAssc[0].TargetingContent__c);
        System.assertEquals(prod3TargetingContent.TargetingContent__c, clonedParentQliTarAssc[1].TargetingContent__c);
        System.assertEquals(prod3TargetingContent.TargetingContent__c, clonedParentQliTarAssc[2].TargetingContent__c);

        System.assertEquals(prod1targetDeviceAssoc.Device__c, clonedtargetingDevices[0].Device__c);
        System.assertEquals(prod3targetDeviceAssoc.Device__c, clonedtargetingDevices[1].Device__c);
        System.assertEquals(prod3targetDeviceAssoc.Device__c, clonedtargetingDevices[2].Device__c);

        List<QuoteLineItem> clonedChildQli = [Select Id,Targeting__c, package_line_item__c from QuoteLineItem Where QuoteId !=: quote.Id And package_line_item__c != null Order by package_line_item__c Asc];
        System.assertEquals(4, clonedChildQli.size());
        // not-equal targeting checking for children qli below:
        System.assertNotEquals(null, clonedChildQli[0].Targeting__c);
        System.assertNotEquals(null, clonedChildQli[1].Targeting__c);
        System.assertNotEquals(null, clonedChildQli[2].Targeting__c);
        System.assertNotEquals(null, clonedChildQli[3].Targeting__c);

         // check package_line_item is set corrected for child package qli
        System.assertEquals(clonedParentQli[1].Id, clonedChildQli[0].package_line_item__c);
        System.assertEquals(clonedParentQli[1].Id, clonedChildQli[1].package_line_item__c);

        System.assertEquals(clonedParentQli[3].Id, clonedChildQli[2].package_line_item__c);
        System.assertEquals(clonedParentQli[3].Id, clonedChildQli[3].package_line_item__c);

        Test.stopTest();
        
    }

    private static QuoteLineItem createItem(String quoteId,String productId,String targetingId,String pbeId,Double qty,Decimal uPrice)
    {                
            return  new QuoteLineItem(
                    Product2Id = productId,
                    QuoteId = quoteId,
                    Quantity = qty,
                    Quantity__c = qty,
                    UnitPrice = uPrice,                        
                    Targeting__c = targetingId,
                    PricebookEntryId = pbeId
            );
    }
}