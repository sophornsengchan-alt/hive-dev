/*********************************************************************************************************************************
@ Class:          BatchGetProposalLineItemTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Test class for BatchGetProposalLineItem
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  01.12.2021 / Sophal Noch / Created Class. US-0009927 - Update PG Opportunity Flow 
@ Change history:  15.01.2024 / Vimean Heng / Limit Exceeded
*********************************************************************************************************************************/
@isTest
private class BatchGetProposalLineItemTest {

    static User u1;
    static Id adServerDartRTId = ApexUtil.getRecordTypeByName('AdServer_Login__c','DART6').Id;
    static AdServer_Login__c adServer;
    static AdServer_Login__c adServer2;
    static byPass__c bp;
    static Account acc;
    static Opportunity opp;
    static Quote quote;
    static Site__c site;
    static Site__c site2;
    static Product2 prod1;
    static Product2 prod2;
    static QuoteLineItem qli;
    static QuoteLineItem qli1;
    static QuoteLineItem qli2;
    static Ad_Product__c adProd;
    static Ad_Product__c adProd2;
    static Date startDate;
    static Date endDate;

    static String quotePgRecordTypeId = ApexUtil.getRecordTypeByName('Quote','PG_PMP_Quote').Id;
    static String oppPgRecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','Programmatic').Id;

    private static void setUpData(){
        adServer = new AdServer_Login__c(
            Name = 'US',
            Login_URL__c='http://test.com',
            User_Name__c='dart6testuser@gmail.com',
            Password__c ='testpwddart6123456',
            Active__c = true,
            Network_ID__c='123456',
            Client_ID__c = 'xxxxxxxxxxxxxxxxxxxxx',
            Client_Secret__c = 'xxxxxxxxxxxxxxx',
            Refresh_Token__c = 'xxxxxxxxxxx',
            RT_Waiting__c = true,
            RecordTypeId = adServerDartRTId,
            ExternalLineDescriptionId__c = '123456789'
        );
        insert adServer;

        acc = TST_DataGenerator.generateAccount();
        acc.Record_Type_Text__c = 'Advertiser';
        insert acc;

        Id accId = acc.Id;
        acc = [Select Id,Name, RecordType.Name From Account Where Id =: accId ];

        Advertiser__c advertiser = new Advertiser__c(Account__c=acc.id, Agency__c=acc.id, DART5_Advertiser_Id__c='111111', DART6_Advertiser_Id__c='222222');
        insert advertiser;


        opp = TST_DataGenerator.generateOpp(acc.Id);
        opp.Name = 'Test test test test';
        opp.OwnerId = UserInfo.getUserId();

        Date startDate = Date.today().addDays(1);
        Date endDate = Date.today().addDays(2);

        opp.Start_Date__c = startDate;
        opp.End_Date__c = endDate;
        opp.RecordTypeId = oppPgRecordTypeId;

        insert opp;
        Id oppId = opp.Id;
        opp = [Select Id,Name, Owner.Id From Opportunity Where Id =: oppId];


        site = TST_DataGenerator.generateSite();
        site.Name = 'US';
        site.Country__c = 'US';
        site.currencyIsoCode = 'USD';
        insert site;
            
        Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
        prod1 = TST_DataGenerator.generateProduct(site.Id);
        prod1.Name = 'Test test test';
        prod1.RecordTypeId = prodDartRTId;
        insert prod1;

        Advertising_Medium__c adVertMedium = new Advertising_Medium__c(Name='test test test',Dart_AdSlotSize__c='100x100',Quantity_Multiplier__c=1,to_Subtract__c=1);
        insert adVertMedium;

        prod1.Advertising_Medium__c = adVertMedium.Id;
        update prod1;

        quote = TST_DataGenerator.generateQuote(opp.Id);
        quote.RecordTypeId = quotePgRecordTypeId;
        insert quote;

        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(prod1.id, null);
        insert pbe;

        qli = TST_DataGenerator.generateQuoteLinItem( quote.id, prod1.id, pbe.id);

        insert qli;

        adProd = [Select Id,Quantity__c,Billing_Category__c,Targeting__c, UnitPrice__c, Name,Ad_Id__c From Ad_Product__c Where Opportunity__c =: opp.Id Limit 1];
        adProd.Product2__c = prod1.Id;
        adProd.Billing_Category__c = 'Test';
        adProd.UnitPrice__c = 9;
        adProd.Line_Item_Description__c = 'Test test test';
        adProd.SalesPriceNet__c = 18;
        update adProd;

    }

    static testMethod void testGetProposalLineItems() {
        setUpData();
        opp.Proposal_Id__c = DARTMockUp.proposalId;
        update opp;
        adProd.Proposal_Lineitem_Id__c = DARTMockUp.proposalLineitemId;
        update adProd;
        Test.startTest();
            BatchGetProposalLineItem batch = new BatchGetProposalLineItem();
            batch.execute(null);
        Test.stopTest();

        opp = [Select Id,Order_Id__c, Name from Opportunity Where Id =: opp.Id];
        adProd = [Select Id,Ad_Id__c From Ad_Product__c Where Opportunity__c =: opp.Id Limit 1];
        
        System.assertEquals(DARTMockUp.orderId, opp.Order_Id__c);
        System.assertEquals(DARTMockUp.orderLineitemId, adProd.Ad_Id__c);

    }
    //@ Change history:  15.01.2024 / Vimean Heng / US-0014416 / Limit Exceeded
    static testMethod void testGetSameSiteProposalLineItems() {

        setUpData();

        site2 = TST_DataGenerator.generateSite();
        site2.Name = 'US';
        site2.Country__c = 'US';
        site2.currencyIsoCode = 'USD';
        insert site2;

        Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
        prod2 = TST_DataGenerator.generateProduct(site2.Id);
        prod2.Name = 'Test test test';
        prod2.RecordTypeId = prodDartRTId;
        insert prod2;

        Advertising_Medium__c adVertMedium2 = new Advertising_Medium__c(Name='test test test',Dart_AdSlotSize__c='100x100',Quantity_Multiplier__c=1,to_Subtract__c=1);
        insert adVertMedium2;

        prod2.Advertising_Medium__c = adVertMedium2.Id;
        update prod2;

        PriceBookEntry pbe2 = TST_DataGenerator.generatePricebookEntry(prod2.id, null);
        insert pbe2;
        Test.startTest();
            qli2 = TST_DataGenerator.generateQuoteLinItem( quote.id, prod2.id, pbe2.id);
            insert qli2;

            adProd2 = [Select Id,Quantity__c,Billing_Category__c,Targeting__c, UnitPrice__c, Name,Ad_Id__c From Ad_Product__c Where Quote_Line_Item__c =: qli2.Id Limit 1];
            adProd2.Product2__c = prod2.Id;
            adProd2.Proposal_Lineitem_Id__c = DARTMockUp.proposalLineitemId;

            opp.Proposal_Id__c = DARTMockUp.proposalId;
            update opp;
            adProd.Proposal_Lineitem_Id__c = DARTMockUp.proposalLineitemId;
            update new List<Ad_Product__c>{adProd,adProd2};

        
            BatchGetProposalLineItem batch = new BatchGetProposalLineItem();
            batch.execute(null);
        Test.stopTest();

        opp = [Select Id,Order_Id__c, Name from Opportunity Where Id =: opp.Id];
        List<Ad_Product__c> listAdProd = [Select Id,Ad_Id__c From Ad_Product__c Where Opportunity__c =: opp.Id Limit 2];
        
        System.assertEquals(DARTMockUp.orderId, opp.Order_Id__c);
        System.assertEquals(null, listAdProd[0].Ad_Id__c);
        System.assertEquals(DARTMockUp.orderLineitemId, listAdProd[1].Ad_Id__c); // Batch choose the latest record to update
    }
    //@ Change history:  15.01.2024 / Vimean Heng / US-0014416 / Limit Exceeded
    static testMethod void testGetDifferentSiteProposalLineItems() {

        setUpData();

        adServer2 = new AdServer_Login__c(
            Name = 'DE',
            Login_URL__c='http://test.com',
            User_Name__c='dart6testuse2r@gmail.com',
            Password__c ='testpwddart6123456',
            Active__c = true,
            Network_ID__c='654321',
            Client_ID__c = 'yxxxxxxxxxxxxxxxxxxxx',
            Client_Secret__c = 'yxxxxxxxxxxxxxx',
            Refresh_Token__c = 'yxxxxxxxxxx',
            RT_Waiting__c = true,
            RecordTypeId = adServerDartRTId,
            ExternalLineDescriptionId__c = '987654321'
        );
        insert adServer2;

        site2 = TST_DataGenerator.generateSite();
        site2.Name = 'DE';
        site2.Country__c = 'DE';
        site2.currencyIsoCode = 'EUR';
        insert site2;

        Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
        prod2 = TST_DataGenerator.generateProduct(site2.Id);
        prod2.Name = 'Test test test';
        prod2.RecordTypeId = prodDartRTId;
        insert prod2;

        Advertising_Medium__c adVertMedium2 = new Advertising_Medium__c(Name='test test test',Dart_AdSlotSize__c='100x100',Quantity_Multiplier__c=1,to_Subtract__c=1);
        insert adVertMedium2;

        prod2.Advertising_Medium__c = adVertMedium2.Id;
        update prod2;

        PriceBookEntry pbe2 = TST_DataGenerator.generatePricebookEntry(prod2.id, null);
        insert pbe2;
        Test.startTest();
            qli2 = TST_DataGenerator.generateQuoteLinItem( quote.id, prod2.id, pbe2.id);
            insert qli2;

            adProd2 = [Select Id,Quantity__c,Billing_Category__c,Targeting__c, UnitPrice__c, Name,Ad_Id__c From Ad_Product__c Where Quote_Line_Item__c =: qli2.Id Limit 1];
            adProd2.Product2__c = prod2.Id;
            adProd2.Proposal_Lineitem_Id__c = DARTMockUp.proposalLineitemId;

            opp.Proposal_Id__c = DARTMockUp.proposalId;
            update opp;
            adProd.Proposal_Lineitem_Id__c = DARTMockUp.proposalLineitemId;
            update new List<Ad_Product__c>{adProd,adProd2};

        
            BatchGetProposalLineItem batch = new BatchGetProposalLineItem();
            batch.execute(null);
        Test.stopTest();

        opp = [Select Id,Order_Id__c, Name from Opportunity Where Id =: opp.Id];
        List<Ad_Product__c> listAdProd = [Select Id,Ad_Id__c From Ad_Product__c Where Opportunity__c =: opp.Id Limit 2];
        
        System.assertEquals(DARTMockUp.orderId, opp.Order_Id__c);
        System.assertEquals(DARTMockUp.orderLineitemId, listAdProd[0].Ad_Id__c); // Batch choose the latest record that order by (Product2__r.RecordType.Name + '_' +  Product2__r.Site__r.Name) to update.
        System.assertEquals(null, listAdProd[1].Ad_Id__c);
    }
    //@ Change history:  15.01.2024 / Vimean Heng / US-0014416 / Limit Exceeded
    static testMethod void testGetProposalLineitemsWithMaxDaily() {

        setUpData();


        site2 = TST_DataGenerator.generateSite();
        site2.Name = 'US';
        site2.Country__c = 'US';
        site2.currencyIsoCode = 'USD';
        insert site2;

        Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
        prod2 = TST_DataGenerator.generateProduct(site2.Id);
        prod2.Name = 'Test test test';
        prod2.RecordTypeId = prodDartRTId;
        insert prod2;

        Advertising_Medium__c adVertMedium2 = new Advertising_Medium__c(Name='test test test',Dart_AdSlotSize__c='100x100',Quantity_Multiplier__c=1,to_Subtract__c=1);
        insert adVertMedium2;

        prod2.Advertising_Medium__c = adVertMedium2.Id;
        update prod2;

        PriceBookEntry pbe2 = TST_DataGenerator.generatePricebookEntry(prod2.id, null);
        insert pbe2;
        Test.startTest();
            qli2 = TST_DataGenerator.generateQuoteLinItem( quote.id, prod2.id, pbe2.id);
            insert qli2;

            adProd2 = [Select Id,Quantity__c,Billing_Category__c,Targeting__c, UnitPrice__c, Name,Ad_Id__c From Ad_Product__c Where Quote_Line_Item__c =: qli2.Id Limit 1];
            adProd2.Product2__c = prod2.Id;
            adProd2.Proposal_Lineitem_Id__c = DARTMockUp.proposalLineitemId;

            opp.Proposal_Id__c = DARTMockUp.proposalId;
            update opp;
            adProd.Proposal_Lineitem_Id__c = DARTMockUp.proposalLineitemId;
            update new List<Ad_Product__c>{adProd,adProd2};

        
            BatchGetProposalLineItem batch = new BatchGetProposalLineItem();
            BatchGetProposalLineItem.RG_DML_CHUNK_LIMIT = 1;
            batch.execute(null);
        Test.stopTest();

        opp = [Select Id,Order_Id__c, Name from Opportunity Where Id =: opp.Id];
        List<Ad_Product__c> listAdProd = [Select Id,Ad_Id__c From Ad_Product__c Where Opportunity__c =: opp.Id Limit 2];
        
        System.assertEquals(DARTMockUp.orderId, opp.Order_Id__c);
        System.assertEquals(DARTMockUp.orderLineitemId, listAdProd[0].Ad_Id__c);
        System.assertEquals(DARTMockUp.orderLineitemId, listAdProd[1].Ad_Id__c);

    }


}