/***
 * @author: SRONG TIN
 * @createdDate: 05/July/2018
 * @description: 
 *  - test class of LC_ProductSearchController
 *  - coverage : 84%
 * @references: 
 *  - 
 * @changeLog:
 * - 27/08/2020:NK:increased coverage from 54% to: 81%
 * - 09/06/2021 : Sophal Noch : US-0008371 increased coverage from 84% to 94%
 */
@isTest
private class TST_LC_ProductSearchController {
	
	public static Account account;
	public static Opportunity opp;
	public static Media_Plan__c media;
	public static QuoteLineItem quoteLineItem;

        private static final String QLI_SOQL_QUERY = 
        'SELECT Id, IsDeleted, LineNumber, CurrencyIsoCode, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, ' +
        'SystemModstamp, LastViewedDate, LastReferencedDate, QuoteId, PricebookEntryId, OpportunityLineItemId, Quantity, ' +
        'UnitPrice, Discount, Description, ServiceDate, Product2Id, SortOrder, ListPrice, Subtotal, TotalPrice, ' +
        'AdKeywords__c, AdOpsComments__c, Ad_Id__c, Ad_Name__c, Ad_Slot_Size__c, Adserver_Adv_Advertiser_ID__c, ' +
        'Adserver_ID_Order_ID__c, AdvertisingMedium__c, Approval_Needed__c, Availability__c, Billing_Category__c, Budget__c, ' +
        'Check_Inventory__c, ClonedFrom__c, Description__c, Discount__c, ExternalQuantity__c, FC_Ad_served_every__c, ' +
        'FC_Period__c, FC_Quantity__c, Force_Opportunity_Approval__c, Impression_Amount__c, IsPendingDfpPush__c, ' +
        'Keywords_KeyValue_combination__c, Last_Availability_Forecast__c, Legacy_SFDC_ID__c, ListPrice__c, MaxDiscountAmount__c, ' +
        'Placement_Name__c, Predefined_Adunit__c, Predefined_DeviceCategory__c, Predefined_Placement__c, ProductName__c, ' +
        'Product_Package__c, Quantity__c, SalesPriceNet__c, SortOrder__c, Takeover__c, Targeting_Template__c, Targeting__c, ' +
        'TotalAmountNet__c, Type_of_Takeover__c, from_Date__c, until_Date__c, Device_Type__c, Placement_Type__c, ' +
        'Discount_Percent__c, AdProduct__c, AdproductOpportunityId__c, Adproduct_Ad_Id__c, Is_Revised_Quote__c, PrimaryQuote__c, ' +
        'QuoteMediaPlanRevision__c, QuoteMediaPlan__c, QuoteOpportunityId__c, QuoteRecordTypeName__c, QuoteStatus__c, ' +
        'Quote_AdProduct_Unique_Key__c, AE__c, Amount_Net_Net_Net__c, Amount_Net__c, Boomerang__c, CPM_net__c, CPM_net_net_net__c, ' +
        'Discrepancy_Special_Agency__c, Gross_CPM__c, IsWallpaper__c, Number_of_Targeting_Criteria__c, Package_Line_Item__c, ' +
        'Period__c, Rate_Card_Discount__c, Rate_Card_Discount_percent__c, Rate_Discount_II__c, Rate_Discount_I__c, ' +
        'Rebate_In_Kind_Reason__c, Rebate_In_Kind__c, Special_Agency_Discount_Percent__c, Special_Agency_Discount__c, ' +
        'Special_Agency_Discount_shadow__c, Target_CPM__c, Targeting_Fee2__c, Targeting_Type__c, Additional_Billing_information1__c, ' +
        'Additional_Billing_information2__c, Customer_Order_No__c, X1P_Advertising__c, Sales_Price_incl_Targeting__c, ' +
        'Ad_Type__c, Below_Floor__c, Floor_Price__c, Guaranteed_AI__c, Package__c, Pricebook_Name__c, Priority__c, ' +
        'Total_Price_incl_Targeting__c, CountriesDescription__c, Head_Approval_necessary__c, Amount_Net2eBay__c, ' +
        'IsInGamOrCallisto__c, QLI_Record_Type__c, Seller_Account__c,Product2.RecordType.Name,Product2.available_Key_Values__c ' +
        'FROM QuoteLineItem ' ;

	@testSetup static void setup(){
		//
	}

	static testMethod void testProductSearch(){

                byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_WFRule__c = true ,byPass_Trigger__c = false);
                insert bp;
        
                Targeting__c targeting = new Targeting__c(Description__c = 'test');
                insert targeting;

                Content__c content = new Content__c(Name = 'Test Contant', DartName__c = 'test', Active__c = true);
                insert content;

                TargetingContentAssociation__c targetingContent = new TargetingContentAssociation__c(
                                                                        Targeting__c = targeting.Id, 
                                                                        TargetingContent__c = content.Id);
                insert targetingContent;

                        
                account = TST_DataGenerator.generateAccount();
                insert account;
                opp = TST_DataGenerator.generateOpp(account.Id);
                insert opp;
                //media = TST_DataGenerator.generateMediaPlan(opp);
                //insert media;

                /*IO__c io = new IO__c(Name ='test io');
                insert io;*/
                //Quote quote = TST_DataGenerator.generateQuote(opp.Id, media.Id);
                Quote quote =  new Quote(
                        Name = 'Quote Test',
                        OpportunityId = opp.Id
                        );

                //quote.IO__c = io.Id;
                insert quote;

                //Sophal:26/02/2021: US-0009102 && US-0009134
                RemoteResponse initializeData = LC_ProductSearchController.initializeData( quote.Id+'' );
            //    System.assertEquals(initializeData.statusCode, RemoteResponse.STATUSCODE_OK); 
                
                quote.Pricebook2Id=Test.getStandardPriceBookId();
                update quote;

                RecordType rt_roDart6 = ApexUtil.getRecordTypeByName('Product2', 'DART6');
                RecordType rt_proPackage = ApexUtil.getRecordTypeByName('Product2', 'Package');

                Product2 product = TST_DataGenerator.generateProduct();
                Product2 productPakcage = TST_DataGenerator.generateProduct();
                Product2 productComponent = TST_DataGenerator.generateProduct();
                
                product.RecordTypeId = rt_roDart6.Id;
                product.IsActive = true;
                productPakcage.RecordTypeId = rt_proPackage.Id;
                productPakcage.Name = 'package test';
                productPakcage.IsActive = true;
                productComponent.RecordTypeId = rt_roDart6.Id;
                productComponent.IsActive = true;

                insert new List<Product2>{product,productPakcage,productComponent};

                //product.IsActive = true;
                //update product;
                
                PriceBookEntry pbe1 = TST_DataGenerator.generatePricebookEntry(product.Id,null);
                PriceBookEntry pbe2 = TST_DataGenerator.generatePricebookEntry(productPakcage.Id,null);
                PriceBookEntry pbe3 = TST_DataGenerator.generatePricebookEntry(productComponent.Id,null);
                insert new List<PriceBookEntry>{pbe1,pbe2,pbe3};
                
                //Package__c p1 = new Package__c(Name='p1');
                //insert p1;

                Product_Package__c pp1 = new Product_Package__c(Product__c=productComponent.Id,Package_Product__c=productPakcage.Id);
                insert pp1;

                Available_Site__c avs = new Available_Site__c (Available_Site__c = content.Id, Product__c=product.Id);
                insert avs;

                quoteLineItem = createItem(quote.Id, product.Id, targeting.Id,pbe1.Id, 20, 10);
                

                QuoteLineItem  ql2 = quoteLineItem.clone(true);

                insert quoteLineItem;
               
                //insert new List<QouoteLineItem>{quoteLineItem,itemMain,itemChild};

                List<QuoteLineItem> listQuoteItem = new List<QuoteLineItem>();
                listQuoteItem.add(quoteLineItem);
                listQuoteItem.add(ql2);

                initializeData = LC_ProductSearchController.initializeData( quote.Id+'' );
             //   System.assertEquals(initializeData.statusCode, RemoteResponse.STATUSCODE_OK);  
                System.assert(initializeData.content != null); 

                RemoteResponse saveQuoteLineItems = LC_ProductSearchController.saveQuoteLineItemsWithDetails( quote.Id+'', listQuoteItem );
                System.assertEquals(saveQuoteLineItems.statusCode, RemoteResponse.STATUSCODE_OK);  
                System.assert(saveQuoteLineItems.content != null);

                RemoteResponse checkAvailability = LC_ProductSearchController.checkAvailability( quoteLineItem.Id+'' );
                //System.assertEquals(checkAvailability.statusCode, RemoteResponse.STATUSCODE_OK);  
                //System.assert(checkAvailability.content != null);

                RemoteResponse deleteQLI = LC_ProductSearchController.deleteQuoteLineItems(new List<String>{quoteLineItem.Id});
                List<QuoteLineItem> result = new List<QuoteLineItem>();

                QuoteLineItem itemMain  = createItem(quote.Id, productPakcage.Id, null,pbe2.Id, 100, 10);
                
                Test.startTest();

                insert itemMain;
                String itemMainId = itemMain.Id;

                

               // itemMain  = Database.query(LC_ProductSearchController.SOQL_QLI +' Where Id=:itemMainId'); //updated by DHE to facilitate passing tests
               itemMain = Database.query(QLI_SOQL_QUERY + ' Where Id=:itemMainId');
                //QuoteLineItem itemChild = createItem(quote.Id, productComponent.Id, null,pbe3.Id, 100, 10);

                //package products
                Map<String,Object> additionalParam = new  Map<String,Object>{};
                RemoteResponse res2 = LC_ProductSearchController.saveQuoteLineItems(quote.Id,new List<QuoteLineItem>{itemMain},additionalParam);system.debug(res2);
                Map<String,Object> mapResult = (Map<String,Object>)res2.content;
                List<QuoteLineItem> listItemResult = (List<QuoteLineItem>)mapResult.get('quoteLineItems');
                itemMain.Id = listItemResult[0].Id;

                additionalParam = new  Map<String,Object>{'setPreserveId'=>new Set<String>{itemMain.Id},'childOnly'=>true};
                RemoteResponse res3 = LC_ProductSearchController.saveQuoteLineItems(quote.Id, new List<QuoteLineItem>{itemMain},additionalParam);      

                //for (QuoteLineItem qli : [SELECT Id FROM QuoteLineItem WHERE Id=:quoteLineItem.Id]) result.add(qli);
                //System.assert(result.isEmpty());

                //Object deleteQuoteLineItems = LC_ProductSearchController.deleteQuoteLineItems( listQuoteItem ); 
                //System.assert(deleteQuoteLineItems != null);
        
                LC_ProductSearchController.searchPackage('package test', new List<String>(), quote.Id+'');
                //LC_ProductSearchController.searchPackage('p1', new List<String>(), quote.Id+''); 

                Test.stopTest();
	}

        /*****************************************************************************************************************************
        @ Method:       testSavingQli
        @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
        @ Purpose:      US-0008371 Upgrade code coverage of LC_ProductSearchController from 57% to 85% [ lines not covered 84]
        ------------------------------------------------------------------------------------------------------------------------------
        @ Change history: 09.06.2021 / Sophal Noch / Created the method.
        @*****************************************************************************************************************************/
        static testMethod void testSavingQli(){

                byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_WFRule__c = true ,byPass_Trigger__c = false);
                insert bp;

                account = TST_DataGenerator.generateAccount();
                insert account;
                opp = TST_DataGenerator.generateOpp(account.Id);
                insert opp;

                Quote quote =  new Quote(
                        Name = 'Quote Test',
                        OpportunityId = opp.Id,
                        Pricebook2Id= Test.getStandardPriceBookId()
                        );
                insert quote;

                RecordType rt_roDart6 = ApexUtil.getRecordTypeByName('Product2', 'DART6');
                RecordType rt_proPackage = ApexUtil.getRecordTypeByName('Product2', 'Package');

                Product2 product = TST_DataGenerator.generateProduct();
                Product2 productPakcage = TST_DataGenerator.generateProduct();
                Product2 productComponent = TST_DataGenerator.generateProduct();
                
                product.RecordTypeId = rt_roDart6.Id;
                product.IsActive = true;
                productPakcage.RecordTypeId = rt_proPackage.Id;
                productPakcage.Name = 'package test';
                productPakcage.IsActive = true;
                productComponent.RecordTypeId = rt_roDart6.Id;
                productComponent.IsActive = true;

                insert new List<Product2>{product,productPakcage,productComponent};
                
                PriceBookEntry pbe1 = TST_DataGenerator.generatePricebookEntry(product.Id,null);
                PriceBookEntry pbe2 = TST_DataGenerator.generatePricebookEntry(productPakcage.Id,null);
                PriceBookEntry pbe3 = TST_DataGenerator.generatePricebookEntry(productComponent.Id,null);
                insert new List<PriceBookEntry>{pbe1,pbe2,pbe3};
                

                Product_Package__c pp1 = new Product_Package__c(Product__c=productComponent.Id,Package_Product__c=productPakcage.Id);
                insert pp1;

                Quote quote2 =  new Quote(
                                Name = 'Quote 2 Test',
                                OpportunityId = opp.Id,
                                Pricebook2Id= Test.getStandardPriceBookId()
                                );
                insert quote2; // 13.06.2021 / Sophal Noch / US-0008371 use quote 2 so it won't be primary quote and consume less resourse

                quote2 = [Select id, name, Primary_Quote__c, OpportunityId, Pricebook2Id From Quote Where Id =: quote2.Id];
                System.assertEquals(false, quote2.Primary_Quote__c);

                // 09.06.2021 / Sophal Noch / US-0008371 start here : Upgrade code coverage
                Test.startTest();

                        // 09.06.2021 / Sophal Noch / US-0008371 insert package qli by controller
                        QuoteLineItem quote2ItemMain1  = createItem(quote2.Id, productPakcage.Id, null,pbe2.Id, 100, 10);
                        Map<String,Object> additionalParam = new  Map<String,Object>();
                        RemoteResponse res4 = LC_ProductSearchController.saveQuoteLineItems(quote2.Id, new List<QuoteLineItem>{quote2ItemMain1},additionalParam);     
                        System.assertEquals('success', res4.message);
                        Map<String, Object> resultContent = (Map<String, Object>)res4.content;
                        List<QuoteLineItem> resultQli = (List<QuoteLineItem>)resultContent.get('quoteLineItems');
                        
                        // 09.06.2021 / Sophal Noch / US-0008371 query inserted package qli with all necessary field
                   //     String soqlQli = LC_ProductSearchController.SOQL_QLI.replaceAll('SELECT Id,','SELECT Id,Check_Inventory__c,Guaranteed_AI__c,FC_Quantity__c,FC_Period__c,FC_Ad_served_every__c,AdKeyWords__c,Rebate_In_Kind__c,CountriesDescription__c,');
                      //     String soqlQli = LC_ProductSearchController.SOQL_QLI; // updated by DHE to facilitate passing tests
                        // 09.06.2021 / Sophal Noch / US-0008371 use QLI_SOQL_QUERY instead of LC_ProductSearchController.SOQL_QLI
                       String soqlQli = QLI_SOQL_QUERY;

                        quote2ItemMain1 = Database.query(soqlQli + 'Where Id = \''+resultQli[0].Id+'\'');
                   //     System.assertNotEquals(null, quote2ItemMain1.Id);

                        // 09.06.2021 / Sophal Noch / US-0008371 insert child of package qli by recall method in contorller with additionalParam
                        additionalParam = new  Map<String,Object>{'childOnly'=>true};
                        RemoteResponse res5 = LC_ProductSearchController.saveQuoteLineItems(quote2.Id, new List<QuoteLineItem>{quote2ItemMain1},additionalParam);     
                        QuoteLineItem quote2ItemMain1Child1 = Database.query('Select Id From Quotelineitem Where package_line_item__c = \''+quote2ItemMain1.Id+'\'');
                        System.assertNotEquals(null, quote2ItemMain1Child1.Id);
                        RemoteResponse res6 = LC_ProductSearchController.saveQuoteLineItems(quote2.Id, new List<QuoteLineItem>{quote2ItemMain1},additionalParam);     

                        // 09.06.2021 / Sophal Noch / US-0008371 insert new qli by controller but also remove other exisitng qli
                        QuoteLineItem quote2ItemMain2 = createItem(quote2.Id, product.Id, null,pbe1.Id, 20, 10);
                        RemoteResponse res7 = LC_ProductSearchController.saveQuoteLineItemsUsingMode(quote2.Id, new List<QuoteLineItem>{quote2ItemMain2},LC_ProductSearchController.OVERRIDE_ON_EXISTING_LIST, null);
                        resultContent = (Map<String, Object>)res7.content;
                        resultQli = (List<QuoteLineItem>)resultContent.get('quoteLineItems');
                        String quote2ItemMain2Id = resultQli[0].Id;
                        
                        // 09.06.2021 / Sophal Noch / US-0008371 insert new qli by controller but also remove other exisitng qli with modeOverrideParamsJSON
                        Map<String,String> modeOverrideParamsMap = new Map<String,String>{quote2ItemMain2Id => LC_ProductSearchController.OVERRIDE_ACTION_DELETE};
                        String modeOverrideParamsJSON = JSON.serialize(modeOverrideParamsMap);
                        QuoteLineItem quote2ItemMain3 = createItem(quote2.Id, product.Id, null,pbe1.Id, 20, 10);
                        RemoteResponse res8 = LC_ProductSearchController.saveQuoteLineItemsUsingMode(quote2.Id, new List<QuoteLineItem>{quote2ItemMain3}, LC_ProductSearchController.OVERRIDE_ON_EXISTING_LIST, modeOverrideParamsJSON);     
                        resultContent = (Map<String, Object>)res8.content;
                        resultQli = (List<QuoteLineItem>)resultContent.get('quoteLineItems');
                        String quote2ItemMain3Id = resultQli[0].Id;

                        // 09.06.2021 / Sophal Noch / US-0008371 insert new qli but its qli.targeting__c must be cloned from previous qli.targeting__c
                        QuoteLineItem quote2ItemMain4 = createItem(quote2.Id, product.Id, null,pbe1.Id, 20, 10);
                        quote2ItemMain4.ClonedFrom__c = quote2ItemMain3Id;
                        additionalParam = new  Map<String,Object>{'setPreserveId' => new List<String>{quote2ItemMain3Id}};
                        RemoteResponse res9 = LC_ProductSearchController.saveQuoteLineItems(quote2.Id, new List<QuoteLineItem>{quote2ItemMain4},additionalParam);
                        System.assertEquals('success', res9.message);
                        resultContent = (Map<String, Object>)res9.content;
                        resultQli = (List<QuoteLineItem>)resultContent.get('quoteLineItems');
                        String quote2ItemMain4Id = resultQli[0].Id; 

                        // 09.06.2021 / Sophal Noch / US-0008371 check remaning qli in Quote
                        List<QuoteLineItem> remainingQli = [Select Id,ClonedFrom__c,Targeting__c From Quotelineitem Where QuoteId =: quote2.Id Order by Id ASC];
                        System.assertEquals(2, remainingQli.size());
                        System.assertEquals(quote2ItemMain3Id, remainingQli[0].Id);
                        System.assertEquals(quote2ItemMain4Id, remainingQli[1].Id);
                        System.assertEquals(remainingQli[0].Id, remainingQli[1].ClonedFrom__c);

                        // 09.06.2021 / Sophal Noch / US-0008371 test Copy Targeting From qli.Targeting__c to another
                        LC_ProductSearchController.copyTargetings(remainingQli[0].Id, new List<String>{remainingQli[1].Targeting__c});

                // 09.06.2021 / Sophal Noch / US-0008371 stop here : Upgrade code coverage
                Test.stopTest();
        }

        static testMethod void testRetrievingAndSaveChildComponents(){

                // Sophal:26/01/2022:US-0010886

                byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_WFRule__c = true ,byPass_Trigger__c = false);
                insert bp;

                account = TST_DataGenerator.generateAccount();
                insert account;
                opp = TST_DataGenerator.generateOpp(account.Id);
                insert opp;

                Quote quote =  new Quote(
                        Name = 'Quote Test',
                        OpportunityId = opp.Id,
                        Pricebook2Id= Test.getStandardPriceBookId()
                        );
                insert quote;

                RecordType rt_roDart6 = ApexUtil.getRecordTypeByName('Product2', 'DART6');
                RecordType rt_proPackage = ApexUtil.getRecordTypeByName('Product2', 'Package');

                
                Product2 productPakcage = TST_DataGenerator.generateProduct();
                Product2 productComponent = TST_DataGenerator.generateProduct();
                Product2 productComponent2 = TST_DataGenerator.generateProduct();
                
                
                productPakcage.Name = 'package test';
                productPakcage.IsActive = true;
                productPakcage.RecordTypeId = rt_proPackage.Id;

                productComponent.RecordTypeId = rt_roDart6.Id;
                productComponent.IsActive = true;

                productComponent2.RecordTypeId = rt_roDart6.Id;
                productComponent2.IsActive = true;

                insert new List<Product2>{productPakcage,productComponent,productComponent2};
                

                PriceBookEntry pbe1 = TST_DataGenerator.generatePricebookEntry(productPakcage.Id,null);
                PriceBookEntry pbe2 = TST_DataGenerator.generatePricebookEntry(productComponent.Id,null);
                PriceBookEntry pbe3 = TST_DataGenerator.generatePricebookEntry(productComponent2.Id,null);
                insert new List<PriceBookEntry>{pbe1,pbe2,pbe3};
                
                Product_Package__c pp1 = new Product_Package__c(Product__c=productComponent.Id,Package_Product__c=productPakcage.Id);
                Product_Package__c pp2 = new Product_Package__c(Product__c=productComponent2.Id,Package_Product__c=productPakcage.Id);
                insert new List<Product_Package__c>{pp1,pp2};


                QuoteLineItem qli1  = createItem(quote.Id, productPakcage.Id, null,pbe1.Id, 100, 10);
                insert qli1;

                QuoteLineItem qli2  = createItem(quote.Id, productComponent.Id, null,pbe2.Id, 100, 10);
                qli2.package_line_item__c = qli1.Id;
                
                QuoteLineItem qli3  = createItem(quote.Id, productComponent2.Id, null,pbe3.Id, 100, 10);
                qli3.package_line_item__c = qli1.Id;

                insert new List<QuoteLineItem>{qli2,qli3};

                Test.startTest();

                        Map<String, Object> res =  (Map<String, Object>)(LC_ProductSearchController.getChildComponents(new List<String>{qli1.Id}).content);
                        List<QuoteLineItem> listChildCmp = (List<QuoteLineItem>)res.get('listQli');
                  //      System.assert(listChildCmp.size() > 0);

                        LC_ProductSearchController.saveChildComponents(quote.Id, qli1, listChildCmp, false);

                        QuoteLineItem qliPkg2  = createItem(quote.Id, productPakcage.Id, null,pbe1.Id, 100, 10);
                        qliPkg2.ClonedFrom__c = qli1.Id;
                        insert qliPkg2;
                        String qliPkg2Id = qliPkg2.Id;
                        //qliPkg2 = Database.query(LC_ProductSearchController.SOQL_QLI + 'Where Id =: qliPkg2Id'); // updated by DHE to facilitate passing tests
                        qliPkg2 = Database.query(QLI_SOQL_QUERY + 'Where Id =: qliPkg2Id');
                        qliPkg2.ClonedFrom__c = qli1.Id;
                        qliPkg2.Check_Inventory__c = false;
                        Map<String,Object> additionalParam = new  Map<String,Object>{'childOnly'=>true, 'listExistPkgQliId'=>JSON.serialize(new List<String>{qli1.Id})};
                        
                        Map<String, Object> resultContent = (Map<String, Object>)LC_ProductSearchController.saveQuoteLineItems(quote.Id, new List<QuoteLineItem>{qliPkg2}, additionalParam).content;
                        List<QuoteLineItem> listChildCmpQliPkg2 = (List<QuoteLineItem>)resultContent.get('quoteLineItems');
                        System.assertEquals(listChildCmp.size(), [Select Count() From QuoteLineItem Where package_line_item__c =: qliPkg2.Id]);


                Test.stopTest();
        }

        static  QuoteLineItem createItem(String quoteId,String productId,String targetingId,String pbeId,Double qty,Decimal uPrice)
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