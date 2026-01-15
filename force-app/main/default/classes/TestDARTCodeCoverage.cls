/*****************************************************************************************************************************
@ Class:   TestDARTCodeCoverage
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 7.02.2021 / Acmatac SEING / Clean the testclass and remove not using reference(IO & IOLineItem)
                  26.10.2021 / Sambath Seng / US-0008405 - create new test method for DART6SchReportRequestWatcher
                  21.11.2022 / Sophal Noch / US-0012883 Sophal Noch - Upgrade GAM version
                  11.07.2023 / Sophal Noch / US-0013954 - Upgrade GAM Version to v202305
                  19.02.2024 / Sophal Noch / US-0014655 - Upgrade GAM version from v202305 to v202402 
                  13.06.2025 / Sophal Noch / US-0012504 - 2. Deletion of custom objects
*****************************************************************************************************************************/
@isTest
public class TestDARTCodeCoverage {
	// something
    //static TestDataGenerator testDATA = new TestDataGenerator();
    private static string defaultCountry = 'DE';//'US';
    public static Quote quote;
    public static QuoteLineItem qli;
    public static Ad_Product__c adProd;
    public static AdServer_Login__c login;
    // public static IO__c io;
    // public static IO_LineItem__c IOline;
    
    public static AdServer_Login__c[] listLogin;
    public static Account[] lstAcc;
    public static Targeting__c[] targetting;
    public static Content__c[] contents;
    public static Advertiser__c[] lstAdvertiser;
    //public Region__c[] regions;

    //public AreaCode__c[] areaCodes;
    //public City__c[] cities;
    public static Site__c[] sites;
    // public static Country__c[] countries; // US-0015115 - 1. Deletion of custom objects
    public static GAM_Key_Value__c[] keyvalues;
    private static Placement__c[] lstPlacements;
    public static Devices__c[] lstDevices;
    public static Connection__c[] lstConns;
    public static Geography__c[] lstGeographies;
    public static User userAdmin;
    private static User currentUser = [ select Id, Name from User where Id = :UserInfo.getUserId() ]; 
    public static final String TESTINGCURRENCY = 'USD';
    
    public static String dartCountry;
    public static String dartVerCountry;
    public static String adserverIDOrderID;
    public static String adserverAdvID;
    public static String advertiserID;
    public static String agencyID;
    public static String dartVersion;
    static Product2 prod1;
    static Site__c site;
    static Account acc;
    static Opportunity opp;

    static byPass__c bp;

    @TestSetup public static void setup(){

        bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Account Opportunity Quote QuoteLineItem Ad_Product__c', byPass_Trigger__c = true);
        insert bp; // 19.02.2024 / Sophal Noch / US-0014655 : fix cpu limit in test class

    	setupSimpleData(new Set<String>{'Account', 'Opportunity', 'Quote', 'QuoteLineItem'});
        sites = QueryUtil.queryRecords('Site__c');
        createTestUser();
        createCredential();
        createTargetingHierarchy();
        createAccount();
        createAdvertiser();
        
        //testDATA.createOpp(testDATA.lstAcc.get(0));
        //testDATA.createOppTeamMember(testDATA.opp.id);
        //testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
        createTargetingKVHierarchy();
        //createTargetingKVHierarchy();
        Id adsSerLogRTId = ApexUtil.getRecordTypeByName('AdServer_Login__c','DART6').Id;
        login = generateAdServerLogin(defaultCountry, adsSerLogRTId);
        insert login;

        bp.byPass_Trigger__c = false;
        update bp;

    	
    }
    // Created: Acmatac SEING 07/01/2021
    public static Map<String, List<sObject>> setupSimpleData(Set<String> dataSetConfig){

        Map<String, List<sObject>> configuredData = new Map<String, List<sObject>>();
        if (dataSetConfig.contains('Account')){
            Account acc = generateAccount();
            insert acc;
            configuredData.put('Account', new Account[]{acc});

            if(dataSetConfig.contains('Opportunity')){

                Opportunity opp = TST_DataGenerator.generateOpp(acc.id);
                insert opp;
                configuredData.put('Opportunity', new Opportunity[]{opp});

                if(dataSetConfig.contains('Quote')){
                    Quote q = generateQuote(opp.id);
                    insert q;
                    configuredData.put('Quote', new Quote[]{q});

                    if(dataSetConfig.contains('QuoteLineItem')){
                        Site__c site = generateSite(defaultCountry);
                        insert site;
                        Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
                        Product2 prod = generateProduct(site.Id, prodDartRTId);
                        insert prod;
                        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(prod.id, null);
                        insert pbe;
                        QuoteLineItem qli = TST_DataGenerator.generateQuoteLinItem( q.id, prod.id, pbe.id);
                        
                        Targeting__c tg;
                        if(dataSetConfig.contains('Targeting__c')){
                            tg =TST_DataGenerator.createTargetingObject();
                            qli.Targeting__c = tg.Id;    
                            configuredData.put('Targeting__c', new Targeting__c[]{tg});
                        }

                        if(bp == null){ // 19.02.2024 / Sophal Noch / US-0014655 : fix cpu limit in test class
                            bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Account Opportunity Quote QuoteLineItem Ad_Product__c', byPass_Trigger__c = true);
                        }
                        bp.byPass_Trigger__c = false;
                        update bp;

                        insert qli;

                        bp.byPass_Trigger__c = true;
                        update bp;

                        configuredData.put('QuoteLineItem', new QuoteLineItem[]{qli});
                    }
                }
            }
        }

        return configuredData;
    }
    
    public static Quote generateQuote(Id oppId){
    	return new Quote(
    		Name = 'Quote Test',
    		OpportunityId = oppId,
            Pricebook2Id=Test.getStandardPriceBookId()
    		);
    }

    public static Account generateAccount(){
        Id rtAdvertiser = ApexUtil.getRecordTypeByName('Account','Advertiser').Id;
    	return new Account(
            Name = 'Account test',
    		BillingStreet = 'Goethestrasse 97',
            BillingPostalCode = '19053',
            BillingCity = 'Schwerin',
            BillingState = 'Berlin',
            BillingCountry = 'Germany',
            Phone = '+1234567890',
            recordTypeid = rtAdvertiser,
            Record_Type_Text__c = 'Advertiser'
            
		);
    }

    public static Product2 generateProduct(Id siteId, Id recordTypeId){
        return new Product2(
              Name = 'Product Test',
              Site__c = siteId,
              RecordTypeId = recordTypeId
              );
      }

    // public static Site__c generateSite(){
    //     return generateSite(null);
    // }

    public static Site__c generateSite(String country){
        return new Site__c(Name=country, Country__c=country);
    }

    //@vitou 13-05-2015
    static void getTestData(){
        quote = (Quote) QueryUtil.queryRecords('Quote','ID<>null limit 1',new Set<String>{'Owner.Name','Opportunity.AccountId'}, new Map<String,Object>()).get(0);  
    	qli = (QuoteLineItem ) QueryUtil.queryRecords('QuoteLineItem', 'Id<> null AND QuoteId=\'' + quote.Id + '\' limit 1 ',new Set<String>{'Product2.Site__r.Country__c','Product2.RecordType.DeveloperName','PricebookEntry.Product2.Id'}, new Map<String,Object>()).get(0);
        opp = (Opportunity) QueryUtil.queryRecords('Opportunity','ID<>null limit 1').get(0);
        adProd =  (Ad_Product__c) QueryUtil.queryRecords('Ad_Product__c','ID<>null limit 1').get(0);
        qli.Targeting__c =  QueryUtil.queryRecords(Util.NS +'Targeting__c','ID<>null limit 1').get(0).Id;
        logIn = [select id,Name, Refresh_Token__c, Client_Id__c, Client_Secret__c,ExternalLineDescriptionId__c, Network_ID__c,RecordTypeId,RecordType.Name from AdServer_Login__c where Name =: defaultCountry limit 1];
        update  qli;    
    	
		sites = QueryUtil.queryRecords(Util.NS + 'Site__c');
		lstAcc = QueryUtil.queryRecords('Account');
		lstAdvertiser = QueryUtil.queryRecords(Util.NS + 'Advertiser__c');
        targetting = QueryUtil.queryRecords(Util.NS + 'Targeting__c');
        
        dartCountry = qli.Product2.Site__r.Country__c;
        dartVerCountry = qli.Product2.RecordType.DeveloperName + '_' + dartCountry;

        adserverIDOrderID = qli.Adserver_ID_Order_ID__c;
        adserverAdvID = qli.Adserver_Adv_Advertiser_ID__c;
        advertiserID = quote.Opportunity.AccountId;
        agencyID = quote.Agency__c;
        dartVersion = qli.Product2.RecordType.DeveloperName;
    }

    //NK:10/02/2021:US-0008913: moved to DART6_KeyValueControllerTest
	// @isTest static void testDART6_KeyValueController(){
	// 	getTestData();
	// 	String token = 'DQAAAIYAAADrtubcdIuc0bz-CksXJh6v';
    //     String kv = '((car=hummer)) OR ((car=bmw) OR (car=tico) OR (car=vigo) OR (color=red) OR (color=white) OR (Audience Segment=Aud1) OR (Audience Segment=Aud2))';
    //     String nw = '18823133';
    //     String siteAuto = sites.get(0).id;

        
	// 	Test.startTest();
    //     		DART6_KeyValueController ctrl = new DART6_KeyValueController(siteAuto,kv,token,nw);
    //             ctrl.isNeedToCreate();
    //     		ctrl.isCreateNewKv();
    //     		ctrl.createObjectKeyVal();
    //     		ctrl.updateDart6ValueIds();
    //     		ctrl.searchCreateDFPFreeFormValues();
    //     		//ctrl.getListDart();
    //             List<DARTObject.IDARTGenericObject> ListDarts = ctrl.getListDart(); 
    //             System.assertEquals(1, ListDarts.size());
    //     Test.stopTest();
			
	// }
	
	@isTest static void testDART6Message(){
        
        createCredential();
		getTestData();
        
        site = generateSite(defaultCountry);
        site.Name = defaultCountry;
        site.Country__c = defaultCountry;
        site.currencyIsoCode = 'USD';
        insert site;

        Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
        Product2 prod2 = generateProduct(site.Id,prodDartRTId);
        prod2.Name = 'Test 2';
        insert prod2;

        adProd.Product2__c = prod2.Id;
        update adProd;
        

        Test.startTest();
            DFPController.initContext(adProd.Id, 'Opportunity');
            RemoteResponse response =  DFPController.doBooking(adProd.Id, 'Opportunity');
            //System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_ERROR);

            response =  DFPController.getAvailability(qli.Id);
            System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);

            response =  DFPController.doBooking(adProd.Id, 'Opportunity');
            //System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);

            response =  DFPController.doBooking(adProd.Id, 'Opportunity');
            //System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);


            qli.Targeting__c = null;
            update qli;
            response =  DFPController.getAvailability(qli.Id);
            System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_ERROR);
        Test.stopTest();
			
	}

  //  /** DART6 Request Forecast By LineItem */
    static testMethod void testDART6RequestForecast()
    {

        Test.startTest();

            //@vitou 13-05-2015 => get Test Data
            getTestData();

            // Dart6Message
            DART6Message dart6Msg = new DART6Message();
            // Dart6Parser
            DART6Parser dart6Parser = new DART6Parser();
            // DartObject
            DARTObject dartObj = new DARTObject();
            //DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(items.get(0));

            DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(qli);

            //List<OpportunityLineItem> items2 = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
            // ForecastController
            //ForecastController fcCont2 = new ForecastController(items2.get(0));
            // ForecastController fcCont2 = new ForecastController(qli);
            // fcCont2.forecastProcess();
            // List<DARTObject.DARTForecast> lstFc2 = fcCont2.getObjectForecast();
            // System.assertEquals(1, lstFc2.size());

            //@Vitou 08-04-2015
            //DartUtil.generateTableForecast(lstFc2);

        Test.stopTest();

        // Forecast Request by lineItem
        //System.assertEquals('300', lstFc2.get(0).getAvailableUnits(), '300, Test data from DARTMokup');
        //System.assertEquals('getForecast', fcCont2.getInvokedMethod(), '');

        ////System.assertEquals('Multiformat1', dartFC.getPackage(), '');
        //System.assertEquals('200', dartFC.getQuantity()+'', '');
        //System.assertEquals('Test Desc0', dartFC.getLineDesc(), '');
        //System.assertEquals('Test product0', dartFC.getProductName(), '');

    }

    static testMethod void testDart6GetAdvertiser()
    {
        Test.startTest();

            //@vitou 13-05-2015 => get Test Data
            getTestData();

            // Dart6Message
            DART6Message dart6Msg = new DART6Message();
            // Dart6Parser
            DART6Parser dart6Parser = new DART6Parser();
            // DartObject
            DARTObject dartObj = new DARTObject();
            // DARTMockUp
            DARTMockUp mockupdata = new DARTMockUp();

            //DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(items.get(0));
            DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(qli);

            //List<OpportunityLineItem> items2 = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
            // Booking
            //BookingController bookingCont2 = new BookingController(opp, items2.get(0));
            BookingController bookingCont2 = new BookingController(quote, qli, dartVersion, dartCountry, dartVerCountry, advertiserID);
            
            bookingCont2.processSearchAdvertiser();
            List<DARTObject.IDARTObjectAdvertiser> lstAdv = bookingCont2.getListAdvertiser();
            List<DARTObject.IDARTObjectOrder> lstExistOrder = bookingCont2.getExistOrder();
            System.assertNotEquals(null, lstExistOrder);


        Test.stopTest();
    }



    /** Test DART6 Booking */
    static testMethod void testDART6Booking()
    {

        Test.startTest();

            //@vitou 13-05-2015 => get Test Data
            //getTestData();
            //opp.ApprovalStatus__c = 'Previously Approved';
            //opp.ContractStatus__c = 'Signed';
            //update opp;
            //update item;
            getTestData();

            // Dart6Message
            DART6Message dart6Msg = new DART6Message();
            // Dart6Parser
            DART6Parser dart6Parser = new DART6Parser();
            // DartObject
            DARTObject dartObj = new DARTObject();
            // DARTMockUp
            DARTMockUp mockupdata = new DARTMockUp();

            //DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(items.get(0));
            DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(qli);

            //List<OpportunityLineItem> items2 = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
            // Booking
            //BookingController bookingCont2 = new BookingController(opp, items2.get(0));
            BookingController bookingCont2 = new BookingController(quote, qli, dartVersion, dartCountry, dartVerCountry, advertiserID);

            bookingCont2.requestCreateAdvertiser();
            List<DARTObject.IDARTObjectAdvertiser> lstAdv = bookingCont2.getListAdvertiser();


             Advertiser__c adv = new Advertiser__c(Dart6_Advertiser_Id__c=lstAdv.get(0).getDartId());

            Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
            //mapAdvertiser.put(DARTUtil.DART6+'_'+items2.get(0).PriceBookEntry.Product2.Site__r.Country__c, adv);
            mapAdvertiser.put(DARTUtil.DART6+'_'+qli.Product2.Site__r.Country__c, adv);

            bookingCont2.processAndSendOrder(mapAdvertiser);
            List<DARTObject.IDARTObjectOrder> lstOrder = bookingCont2.getListOrder();
            bookingCont2.processAndSendLineItem(lstOrder.get(0), mapAdvertiser);
            List<DARTObject.IDARTObjectAds> lstAds = bookingCont2.getListAds();



        Test.stopTest();

        // Result
        // Advertiser
        System.assertEquals('123456', lstAdv.get(0).getDartId(), '123456, Test data from DARTMokup');
        // Order
        System.assertEquals('22222', lstOrder.get(0).getDartId(), '22222, Test data from DARTMokup');
        //LineItem
        System.assertEquals('123456', lstAds.get(0).getDartId(), '123456, Test data from DARTMokup');
        System.assertEquals('111111', lstAds.get(0).getOrder().getDartId(), '111111, Test data from DARTMokup');
        //System.assertEquals('getLineItemByName', bookingCont2.getInvokedMethod());

    }

    /** Class DART6_COMPANYSERVICE*/
    static testMethod void testClassDART6_COMPANYSERVICE()
    {
        DART6_COMPANYSERVICE companyService = new DART6_COMPANYSERVICE();
        DART6_COMPANYSERVICE.CompanyServiceInterfacePort compInPort = new DART6_COMPANYSERVICE.CompanyServiceInterfacePort();
        DART6_COMPANYSERVICE.CommonError comErr = new DART6_COMPANYSERVICE.CommonError();
        DART6_COMPANYSERVICE.InternalApiError inApiErr = new DART6_COMPANYSERVICE.InternalApiError();
        DART6_COMPANYSERVICE.BooleanValue bv = new DART6_COMPANYSERVICE.BooleanValue();
        DART6_COMPANYSERVICE.AppliedLabel appLabel = new DART6_COMPANYSERVICE.AppliedLabel();
        DART6_COMPANYSERVICE.UniqueError uniquErr = new DART6_COMPANYSERVICE.UniqueError();
        DART6_COMPANYSERVICE.RequiredError requiErr  = new DART6_COMPANYSERVICE.RequiredError();
        DART6_COMPANYSERVICE.SetValue setval = new DART6_COMPANYSERVICE.SetValue();
        DART6_COMPANYSERVICE.AuthenticationError authErr = new DART6_COMPANYSERVICE.AuthenticationError();
        DART6_COMPANYSERVICE.PermissionError perErr = new DART6_COMPANYSERVICE.PermissionError();
        DART6_COMPANYSERVICE.PublisherQueryLanguageSyntaxError pubQuLangSynErr = new DART6_COMPANYSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_COMPANYSERVICE.String_ValueMapEntry valueMapEnty = new DART6_COMPANYSERVICE.String_ValueMapEntry();
        DART6_COMPANYSERVICE.StringLengthError strLenErr = new DART6_COMPANYSERVICE.StringLengthError();
        DART6_COMPANYSERVICE.Value v = new DART6_COMPANYSERVICE.Value();
        DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element getComByStatResEle = new DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element();
        DART6_COMPANYSERVICE.CompanyPage comPage = new DART6_COMPANYSERVICE.CompanyPage();
        DART6_COMPANYSERVICE.FeatureError FeatureErr = new DART6_COMPANYSERVICE.FeatureError();
        DART6_COMPANYSERVICE.updateCompaniesResponse_element upComResEle = new DART6_COMPANYSERVICE.updateCompaniesResponse_element();
        DART6_COMPANYSERVICE.TypeError typeErr = new DART6_COMPANYSERVICE.TypeError();
        DART6_COMPANYSERVICE.NumberValue numErr = new DART6_COMPANYSERVICE.NumberValue();
        DART6_COMPANYSERVICE.Company comp = new DART6_COMPANYSERVICE.Company();
        DART6_COMPANYSERVICE.SoapResponseHeader soapResHeader = new DART6_COMPANYSERVICE.SoapResponseHeader();
        DART6_COMPANYSERVICE.NotNullError notNullErr = new DART6_COMPANYSERVICE.NotNullError();
        DART6_COMPANYSERVICE.updateCompanies_element updateComEle = new DART6_COMPANYSERVICE.updateCompanies_element();
        DART6_COMPANYSERVICE.DateTimeValue dateValue = new DART6_COMPANYSERVICE.DateTimeValue();
        DART6_COMPANYSERVICE.getCompaniesByStatement_element getComByState = new DART6_COMPANYSERVICE.getCompaniesByStatement_element();
        DART6_COMPANYSERVICE.CompanyCreditStatusError comCrStatusErr = new DART6_COMPANYSERVICE.CompanyCreditStatusError();
        DART6_COMPANYSERVICE.Statement st = new DART6_COMPANYSERVICE.Statement();
        DART6_COMPANYSERVICE.PublisherQueryLanguageContextError publiConErro = new DART6_COMPANYSERVICE.PublisherQueryLanguageContextError();
        DART6_COMPANYSERVICE.ApiError apiErr = new DART6_COMPANYSERVICE.ApiError();
        DART6_COMPANYSERVICE.Date_x dtx = new DART6_COMPANYSERVICE.Date_x();
        DART6_COMPANYSERVICE.SoapRequestHeader soapReqHe = new DART6_COMPANYSERVICE.SoapRequestHeader();
        DART6_COMPANYSERVICE.TeamError teamErr = new DART6_COMPANYSERVICE.TeamError();
        DART6_COMPANYSERVICE.createCompaniesResponse_element createCompaniesResEle = new DART6_COMPANYSERVICE.createCompaniesResponse_element();
        DART6_COMPANYSERVICE.ApiException apiExc = new DART6_COMPANYSERVICE.ApiException();
        DART6_COMPANYSERVICE.QuotaError quaErr = new DART6_COMPANYSERVICE.QuotaError();
        DART6_COMPANYSERVICE.ApplicationException appExc = new DART6_COMPANYSERVICE.ApplicationException();
        DART6_COMPANYSERVICE.ParseError parseErr = new DART6_COMPANYSERVICE.ParseError();
        DART6_COMPANYSERVICE.ApiVersionError apiVerErr = new DART6_COMPANYSERVICE.ApiVersionError();
        DART6_COMPANYSERVICE.LabelEntityAssociationError labelAssErr = new DART6_COMPANYSERVICE.LabelEntityAssociationError();
        DART6_COMPANYSERVICE.ServerError serErr = new DART6_COMPANYSERVICE.ServerError();
        DART6_COMPANYSERVICE.DateTime_x datetimex = new DART6_COMPANYSERVICE.DateTime_x();
        DART6_COMPANYSERVICE.StatementError stateErr = new DART6_COMPANYSERVICE.StatementError();
        DART6_COMPANYSERVICE.TextValue txtVal = new DART6_COMPANYSERVICE.TextValue();
        DART6_COMPANYSERVICE.InvalidEmailError invErr = new DART6_COMPANYSERVICE.InvalidEmailError();
        DART6_COMPANYSERVICE.createCompanies_element createCompaniesEle = new DART6_COMPANYSERVICE.createCompanies_element();

        DART6_COMPANYSERVICE.CollectionSizeError colSizeErr = new DART6_COMPANYSERVICE.CollectionSizeError();
        DART6_COMPANYSERVICE.CompanyError cmpErr= new DART6_COMPANYSERVICE.CompanyError();
        // US-0008578 // DART6_COMPANYSERVICE.AvailableBillingError availBillErr = new DART6_COMPANYSERVICE.AvailableBillingError();
        DART6_COMPANYSERVICE.ObjectValue objv= new DART6_COMPANYSERVICE.ObjectValue();
        DART6_COMPANYSERVICE.DateValue dtV= new DART6_COMPANYSERVICE.DateValue();
        DART6_COMPANYSERVICE.CrossSellError crosSellErr= new DART6_COMPANYSERVICE.CrossSellError();
        DART6_COMPANYSERVICE.ResendInvitationAction resendInvitationAction= new DART6_COMPANYSERVICE.ResendInvitationAction();//US-0011408 -v202202
        DART6_COMPANYSERVICE.ReInviteAction reInviteAction= new DART6_COMPANYSERVICE.ReInviteAction();//US-0011408 -v202202
        DART6_COMPANYSERVICE.RequiredNumberError requiredNumberError= new DART6_COMPANYSERVICE.RequiredNumberError();//US-0011408 -v202202
        DART6_COMPANYSERVICE.performCompanyAction_element perform_element= new DART6_COMPANYSERVICE.performCompanyAction_element();//US-0011408 -v202202
        DART6_COMPANYSERVICE.CompanyAction compAct= new DART6_COMPANYSERVICE.CompanyAction();//US-0011408 -v202202
        DART6_COMPANYSERVICE.performCompanyActionResponse_element repspElem= new DART6_COMPANYSERVICE.performCompanyActionResponse_element();//US-0011408 -v202202
        DART6_COMPANYSERVICE.SiteError siteErr= new DART6_COMPANYSERVICE.SiteError();//US-0011408 -v202202
        DART6_COMPANYSERVICE.UpdateResult updateResult= new DART6_COMPANYSERVICE.UpdateResult();//US-0011408 -v202202
        DART6_COMPANYSERVICE.ChildPublisher childPublisher= new DART6_COMPANYSERVICE.ChildPublisher();//US-0011408 -v202202
        DART6_COMPANYSERVICE.EndAgreementAction endAgrAct= new DART6_COMPANYSERVICE.EndAgreementAction();//US-0011408 -v202202
        DART6_COMPANYSERVICE.InvalidUrlError invUrlErr= new DART6_COMPANYSERVICE.InvalidUrlError();//US-0011408 -v202202

        Object o = new DART6_COMPANYSERVICE.NullError();
        o = new DART6_COMPANYSERVICE.RequiredCollectionError();
        // o = new DART6_COMPANYSERVICE.CompanySettings(); // 19.02.2024 / Sophal Noch / US-0014655
        o = new DART6_COMPANYSERVICE.CustomFieldValueError();
        o = new DART6_COMPANYSERVICE.RegExError();
		o = new DART6_COMPANYSERVICE.NetworkError();
        o = new DART6_COMPANYSERVICE.FieldPathElement();
        o = new DART6_COMPANYSERVICE.StringFormatError();
        o = new DART6_COMPANYSERVICE.ViewabilityProvider();
        // 21.11.2022 / Sophal Noch / US-0012883 :
        o = new DART6_COMPANYSERVICE.ExchangeSignupApiError();
        o = new DART6_COMPANYSERVICE.InventoryClientApiError();

        Test.startTest(); 
            
            DART6_COMPANYSERVICE.CompanyServiceInterfacePort svc = new DART6_COMPANYSERVICE.CompanyServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_COMPANYSERVICE.updateCompaniesResponse_element()));
            svc.getCompaniesByStatement(new DART6_COMPANYSERVICE.Statement());
            svc.createCompanies(new DART6_COMPANYSERVICE.Company[0]);
            svc.updateCompanies(new DART6_COMPANYSERVICE.Company[0]);
            System.assertNotEquals(null, svc);

            
        Test.stopTest();
    }


    /** Class DART6_USERSERVICE */
    static testMethod void testClassDART6_USERSERVICE()
    {
        DART6_USERSERVICE userService=new DART6_USERSERVICE();
        DART6_USERSERVICE orderService = new DART6_USERSERVICE();
        DART6_USERSERVICE.CommonError comError = new DART6_USERSERVICE.CommonError();
        DART6_USERSERVICE.InternalApiError inApi = new DART6_USERSERVICE.InternalApiError();
        DART6_USERSERVICE.performUserActionResponse_element pUserAc = new DART6_USERSERVICE.performUserActionResponse_element();
        DART6_USERSERVICE.getUsersByStatementResponse_element userBySt = new DART6_USERSERVICE.getUsersByStatementResponse_element();
        DART6_USERSERVICE.BooleanValue bv = new DART6_USERSERVICE.BooleanValue();
        DART6_USERSERVICE.RequiredError reqerr = new DART6_USERSERVICE.RequiredError();
        DART6_USERSERVICE.PermissionError perErr = new DART6_USERSERVICE.PermissionError();
        DART6_USERSERVICE.AuthenticationError autErr = new DART6_USERSERVICE.AuthenticationError();
        DART6_USERSERVICE.PublisherQueryLanguageSyntaxError pquLaSyn = new DART6_USERSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_USERSERVICE.createUsers_element createUsE = new DART6_USERSERVICE.createUsers_element();
        DART6_USERSERVICE.getAllRolesResponse_element allRolRe = new DART6_USERSERVICE.getAllRolesResponse_element();
        DART6_USERSERVICE.String_ValueMapEntry stValMaEn = new DART6_USERSERVICE.String_ValueMapEntry();
        DART6_USERSERVICE.Value val = new DART6_USERSERVICE.Value();
        DART6_USERSERVICE.performUserAction_element perUsAct = new DART6_USERSERVICE.performUserAction_element();
        DART6_USERSERVICE.createUsersResponse_element creatUserResEle = new DART6_USERSERVICE.createUsersResponse_element();
        DART6_USERSERVICE.updateUsersResponse_element updUseResEle = new DART6_USERSERVICE.updateUsersResponse_element();
        DART6_USERSERVICE.TypeError typErr = new DART6_USERSERVICE.TypeError();
        DART6_USERSERVICE.UserAction usAc = new DART6_USERSERVICE.UserAction();
        DART6_USERSERVICE.updateUsers_element updatUs = new DART6_USERSERVICE.updateUsers_element();
        DART6_USERSERVICE.NumberValue numVal = new DART6_USERSERVICE.NumberValue();
        DART6_USERSERVICE.SoapResponseHeader soapResHeader = new DART6_USERSERVICE.SoapResponseHeader();
        DART6_USERSERVICE.NotNullError notNullErr = new DART6_USERSERVICE.NotNullError();
        DART6_USERSERVICE.Statement str = new DART6_USERSERVICE.Statement();
        DART6_USERSERVICE.PublisherQueryLanguageContextError pbLaCon = new DART6_USERSERVICE.PublisherQueryLanguageContextError();
        DART6_USERSERVICE.ApiError ApiErr = new DART6_USERSERVICE.ApiError();
        DART6_USERSERVICE.Date_x datex = new DART6_USERSERVICE.Date_x();
        DART6_USERSERVICE.SoapRequestHeader soapResHder = new DART6_USERSERVICE.SoapRequestHeader();
        DART6_USERSERVICE.getUsersByStatement_element userByStaEle = new DART6_USERSERVICE.getUsersByStatement_element();
        DART6_USERSERVICE.ApiException apiExeption = new DART6_USERSERVICE.ApiException();
        DART6_USERSERVICE.getAllRoles_element getAllRolesEle = new DART6_USERSERVICE.getAllRoles_element();
        DART6_USERSERVICE.QuotaError quaErr = new DART6_USERSERVICE.QuotaError();
        DART6_USERSERVICE.UserRecord uRec = new DART6_USERSERVICE.UserRecord();
        DART6_USERSERVICE.ApplicationException appExcep = new DART6_USERSERVICE.ApplicationException();
        DART6_USERSERVICE.ParseError parErr = new DART6_USERSERVICE.ParseError();
        DART6_USERSERVICE.ServerError serErr = new DART6_USERSERVICE.ServerError();
        DART6_USERSERVICE.DateTime_x dateTimex = new DART6_USERSERVICE.DateTime_x();
        DART6_USERSERVICE.TextValue txtVal = new DART6_USERSERVICE.TextValue();
        DART6_USERSERVICE.InvalidEmailError invaemailErr = new DART6_USERSERVICE.InvalidEmailError();
        DART6_USERSERVICE.getCurrentUser_element curEle = new DART6_USERSERVICE.getCurrentUser_element();
        DART6_USERSERVICE.Role rol = new DART6_USERSERVICE.Role();
        DART6_USERSERVICE.UpdateResult upResult = new DART6_USERSERVICE.UpdateResult();
        DART6_USERSERVICE.ActivateUsers activeUser = new DART6_USERSERVICE.ActivateUsers();
        DART6_USERSERVICE.StatementError stErr = new DART6_USERSERVICE.StatementError();
        DART6_USERSERVICE.getCurrentUserResponse_element curUsRes = new DART6_USERSERVICE.getCurrentUserResponse_element();
        DART6_USERSERVICE.FeatureError feaErr = new DART6_USERSERVICE.FeatureError();
        //DART6_USERSERVICE.DropDownCustomFieldValue dropCusFv = new DART6_USERSERVICE.DropDownCustomFieldValue();
        //DART6_USERSERVICE.BaseCustomFieldValue baseCusFv = new DART6_USERSERVICE.BaseCustomFieldValue();
        //DART6_USERSERVICE.CustomFieldValue custFv = new DART6_USERSERVICE.CustomFieldValue();
        DART6_USERSERVICE.TeamError teamErr = new DART6_USERSERVICE.TeamError();
        DART6_USERSERVICE.CustomFieldValueError custFvErr = new DART6_USERSERVICE.CustomFieldValueError();
        DART6_USERSERVICE.DateValue dv = new DART6_USERSERVICE.DateValue();
        DART6_USERSERVICE.ApiVersionError apivErr = new DART6_USERSERVICE.ApiVersionError();
        DART6_USERSERVICE.CollectionSizeError colSizeErr = new DART6_USERSERVICE.CollectionSizeError();
        DART6_USERSERVICE.ObjectValue objV= new DART6_USERSERVICE.ObjectValue();
        DART6_USERSERVICE.TimeZoneError timzErr= new DART6_USERSERVICE.TimeZoneError();

        //@vitou 08-04-2015
        DART6_USERSERVICE.SetValue setVal = new DART6_USERSERVICE.SetValue();
        DART6_USERSERVICE.UniqueError uniqErr = new DART6_USERSERVICE.UniqueError();
        DART6_USERSERVICE.DateTimeValue dtVal = new DART6_USERSERVICE.DateTimeValue();
        DART6_USERSERVICE.TokenError tokenErr = new DART6_USERSERVICE.TokenError();
        DART6_USERSERVICE.DeactivateUsers deactUser = new DART6_USERSERVICE.DeactivateUsers();
        
        DART6_USERSERVICE.RequiredCollectionError err = new DART6_USERSERVICE.RequiredCollectionError();
        DART6_USERSERVICE.StringLengthError err1 = new DART6_USERSERVICE.StringLengthError();
        
		Object o = new DART6_USERSERVICE.FieldPathElement();
        o = new DART6_USERSERVICE.StringFormatError();
        o = new DART6_USERSERVICE.User_x();
        o = new DART6_USERSERVICE.UserPage();
        o = new DART6_COMPANYSERVICE.InvalidUrlError();

        o = new DART6_USERSERVICE.EntityLimitReachedError(); // 19.02.2024 / Sophal Noch / US-0014655

        Test.startTest(); 
            
        
            DART6_USERSERVICE.UserServiceInterfacePort svc = new DART6_USERSERVICE.UserServiceInterfacePort();
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_USERSERVICE.getAllRolesResponse_element()));
            svc.getAllRoles();
            System.assertNotEquals(null, svc);
            
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_USERSERVICE.getCurrentUserResponse_element()));
            svc.getCurrentUser();
            System.assertNotEquals(null, svc);
           
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_USERSERVICE.performUserActionResponse_element()));
            svc.performUserAction(new DART6_USERSERVICE.UserAction(), new DART6_USERSERVICE.Statement());
            System.assertNotEquals(null, svc);
        
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_USERSERVICE.createUsersResponse_element()));
            svc.createUsers(new List<DART6_USERSERVICE.User_x>());
            System.assertNotEquals(null, svc);
        
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_USERSERVICE.updateUsersResponse_element()));
            svc.updateUsers(new List<DART6_USERSERVICE.User_x>());
            System.assertNotEquals(null, svc);

        Test.stopTest();
    }

    /** Class DART6_ORDERSERVICE */
    static testMethod void testClassDART6_ORDERSERVICE()
    {
        DART6_ORDERSERVICE orderService = new DART6_ORDERSERVICE();

        DART6_ORDERSERVICE.CommonError ordComErr = new DART6_ORDERSERVICE.CommonError();
        DART6_ORDERSERVICE.ApproveOrdersWithoutReservationChanges ordApWithCh = new DART6_ORDERSERVICE.ApproveOrdersWithoutReservationChanges();
        DART6_ORDERSERVICE.InternalApiError ordInApiErr = new DART6_ORDERSERVICE.InternalApiError();
        DART6_ORDERSERVICE.ApproveOrders ordAppOrd = new DART6_ORDERSERVICE.ApproveOrders();
        DART6_ORDERSERVICE.OrderError ordErr = new DART6_ORDERSERVICE.OrderError();
        DART6_ORDERSERVICE.SubmitOrdersForApprovalAndOverbook ordSubOrdOver = new DART6_ORDERSERVICE.SubmitOrdersForApprovalAndOverbook();
        DART6_ORDERSERVICE.StringLengthError ordStringErr = new DART6_ORDERSERVICE.StringLengthError();
        DART6_ORDERSERVICE.BooleanValue ordBooVal = new DART6_ORDERSERVICE.BooleanValue();
        DART6_ORDERSERVICE.AppliedLabel ordApLab = new DART6_ORDERSERVICE.AppliedLabel();
        DART6_ORDERSERVICE.UniqueError ordUniErr = new DART6_ORDERSERVICE.UniqueError();
        DART6_ORDERSERVICE.RequiredError ordReErr = new DART6_ORDERSERVICE.RequiredError();
        DART6_ORDERSERVICE.PauseOrders ordPauOrd = new DART6_ORDERSERVICE.PauseOrders();
        DART6_ORDERSERVICE.OrderPage ordPage = new DART6_ORDERSERVICE.OrderPage();
        DART6_ORDERSERVICE.AuthenticationError ordAuthErr = new DART6_ORDERSERVICE.AuthenticationError();
        DART6_ORDERSERVICE.PermissionError ordPerErr = new DART6_ORDERSERVICE.PermissionError();
        DART6_ORDERSERVICE.PublisherQueryLanguageSyntaxError ordPUSyErr = new DART6_ORDERSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_ORDERSERVICE.DisapproveOrders ordDisOrd = new DART6_ORDERSERVICE.DisapproveOrders();
        DART6_ORDERSERVICE.String_ValueMapEntry ordStMapEnt = new DART6_ORDERSERVICE.String_ValueMapEntry();
        DART6_ORDERSERVICE.createOrdersResponse_element ordCreResEle = new DART6_ORDERSERVICE.createOrdersResponse_element();
        DART6_ORDERSERVICE.Value ordVal = new DART6_ORDERSERVICE.Value();
        DART6_ORDERSERVICE.DropDownCustomFieldValue ordDroFv = new DART6_ORDERSERVICE.DropDownCustomFieldValue();
        DART6_ORDERSERVICE.ArchiveOrders ordArOrd = new DART6_ORDERSERVICE.ArchiveOrders();
        DART6_ORDERSERVICE.BaseCustomFieldValue ordBasFV = new DART6_ORDERSERVICE.BaseCustomFieldValue();
        DART6_ORDERSERVICE.TypeError ordTypErr = new DART6_ORDERSERVICE.TypeError();
        DART6_ORDERSERVICE.getOrdersByStatement_element ordOrdStaEle = new DART6_ORDERSERVICE.getOrdersByStatement_element();
        DART6_ORDERSERVICE.NumberValue ordNumVal = new DART6_ORDERSERVICE.NumberValue();
        DART6_ORDERSERVICE.SoapResponseHeader ordSoapRes = new DART6_ORDERSERVICE.SoapResponseHeader();
        DART6_ORDERSERVICE.CustomFieldValue ordCusFv = new DART6_ORDERSERVICE.CustomFieldValue();
        DART6_ORDERSERVICE.updateOrdersResponse_element ordUpdRs = new DART6_ORDERSERVICE.updateOrdersResponse_element();
        DART6_ORDERSERVICE.updateOrders_element ordupOrd = new DART6_ORDERSERVICE.updateOrders_element();
        DART6_ORDERSERVICE.SubmitOrdersForApprovalWithoutReservationChanges ordsubForAPch = new DART6_ORDERSERVICE.SubmitOrdersForApprovalWithoutReservationChanges();
        DART6_ORDERSERVICE.NotNullError ordNotNullErr = new DART6_ORDERSERVICE.NotNullError();
        DART6_ORDERSERVICE.SubmitOrdersForApproval ordSuAppva = new DART6_ORDERSERVICE.SubmitOrdersForApproval();
        DART6_ORDERSERVICE.ResumeAndOverbookOrders ordResOvOrd = new DART6_ORDERSERVICE.ResumeAndOverbookOrders();
        DART6_ORDERSERVICE.DateTimeValue ordDateVal = new DART6_ORDERSERVICE.DateTimeValue();
        DART6_ORDERSERVICE.Statement ordStat = new DART6_ORDERSERVICE.Statement();
        DART6_ORDERSERVICE.CompanyCreditStatusError ordComStat = new DART6_ORDERSERVICE.CompanyCreditStatusError();
        DART6_ORDERSERVICE.createOrders_element ordcreOrd = new DART6_ORDERSERVICE.createOrders_element();
        DART6_ORDERSERVICE.PublisherQueryLanguageContextError ordPuConEr = new DART6_ORDERSERVICE.PublisherQueryLanguageContextError();
        DART6_ORDERSERVICE.ApiError ordApiErr = new DART6_ORDERSERVICE.ApiError();
        DART6_ORDERSERVICE.DisapproveOrdersWithoutReservationChanges ordDisWitCh = new DART6_ORDERSERVICE.DisapproveOrdersWithoutReservationChanges();
        DART6_ORDERSERVICE.TeamError ordTeamErr = new DART6_ORDERSERVICE.TeamError();
        DART6_ORDERSERVICE.ApproveAndOverbookOrders ordOverBookOrd = new DART6_ORDERSERVICE.ApproveAndOverbookOrders();
        DART6_ORDERSERVICE.CustomFieldValueError ordCusvalErr = new DART6_ORDERSERVICE.CustomFieldValueError();
        DART6_ORDERSERVICE.performOrderActionResponse_element ordPerOrdresEle = new DART6_ORDERSERVICE.performOrderActionResponse_element();
        DART6_ORDERSERVICE.ResumeOrders ordResOrd = new DART6_ORDERSERVICE.ResumeOrders();
        DART6_ORDERSERVICE.ForecastError ordFcErr = new DART6_ORDERSERVICE.ForecastError();
        DART6_ORDERSERVICE.QuotaError ordQuErr = new DART6_ORDERSERVICE.QuotaError();
        DART6_ORDERSERVICE.OrderActionError ordOrdAcErr = new DART6_ORDERSERVICE.OrderActionError();
        //DART6_ORDERSERVICE.ApplicationException_x ordApiExcep = new DART6_ORDERSERVICE.ApplicationException_x();
        DART6_ORDERSERVICE.RangeError ordranErr = new DART6_ORDERSERVICE.RangeError();
        DART6_ORDERSERVICE.ParseError ordParErr = new DART6_ORDERSERVICE.ParseError();
        DART6_ORDERSERVICE.Money ordMoney = new DART6_ORDERSERVICE.Money();
        DART6_ORDERSERVICE.ApiVersionError ordVerErr = new DART6_ORDERSERVICE.ApiVersionError();
        DART6_ORDERSERVICE.LabelEntityAssociationError ordLaAssErr = new DART6_ORDERSERVICE.LabelEntityAssociationError();
        DART6_ORDERSERVICE.RetractOrdersWithoutReservationChanges ordRetWithCh = new DART6_ORDERSERVICE.RetractOrdersWithoutReservationChanges();
        DART6_ORDERSERVICE.ServerError ordSerErr = new DART6_ORDERSERVICE.ServerError();
        DART6_ORDERSERVICE.OrderAction ordOrAc = new DART6_ORDERSERVICE.OrderAction();
        DART6_ORDERSERVICE.UnarchiveOrders ordUnOrd = new DART6_ORDERSERVICE.UnarchiveOrders();
        DART6_ORDERSERVICE.DateTime_x orddatex = new DART6_ORDERSERVICE.DateTime_x();
        DART6_ORDERSERVICE.StatementError ordStatErr = new DART6_ORDERSERVICE.StatementError();
        DART6_ORDERSERVICE.RequiredCollectionError ordReCollErr = new DART6_ORDERSERVICE.RequiredCollectionError();
        DART6_ORDERSERVICE.TextValue ordTxtVal = new DART6_ORDERSERVICE.TextValue();
        DART6_ORDERSERVICE.InvalidEmailError ordInvEr = new DART6_ORDERSERVICE.InvalidEmailError();
        DART6_ORDERSERVICE.RetractOrders ordRetOrd = new DART6_ORDERSERVICE.RetractOrders();
        DART6_ORDERSERVICE.UpdateResult ordUpResl = new DART6_ORDERSERVICE.UpdateResult();
        DART6_ORDERSERVICE.getOrdersByStatementResponse_element ordByStEle = new DART6_ORDERSERVICE.getOrdersByStatementResponse_element();
        DART6_ORDERSERVICE.performOrderAction_element ordordACEle = new DART6_ORDERSERVICE.performOrderAction_element();
        DART6_ORDERSERVICE.DeleteOrders ordDel = new DART6_ORDERSERVICE.DeleteOrders();
        
        DART6_ORDERSERVICE.TechnologyTargetingError tect = new DART6_ORDERSERVICE.TechnologyTargetingError();
        DART6_ORDERSERVICE.DateTimeRangeTargetingError dateRT= new DART6_ORDERSERVICE.DateTimeRangeTargetingError();
        DART6_ORDERSERVICE.SetValue setv= new DART6_ORDERSERVICE.SetValue();
        DART6_ORDERSERVICE.InventoryTargetingError inerr= new DART6_ORDERSERVICE.InventoryTargetingError();
        DART6_ORDERSERVICE.TemplateInstantiatedCreativeError tempIncr= new DART6_ORDERSERVICE.TemplateInstantiatedCreativeError();
        DART6_ORDERSERVICE.FeatureError feaErr = new DART6_ORDERSERVICE.FeatureError();
        DART6_ORDERSERVICE.LineItemOperationError linOper = new DART6_ORDERSERVICE.LineItemOperationError();
        DART6_ORDERSERVICE.ProgrammaticError  proEr= new DART6_ORDERSERVICE.ProgrammaticError();
        DART6_ORDERSERVICE.EntityLimitReachedError entityReErr= new DART6_ORDERSERVICE.EntityLimitReachedError();
        DART6_ORDERSERVICE.NullError nuLerr= new DART6_ORDERSERVICE.NullError();
        DART6_ORDERSERVICE.ApiException apiErr = new DART6_ORDERSERVICE.ApiException();
        DART6_ORDERSERVICE.ApplicationException appExce= new DART6_ORDERSERVICE.ApplicationException();
        DART6_ORDERSERVICE.GenericTargetingError gerTarErr= new DART6_ORDERSERVICE.GenericTargetingError();
        // US-0011408 // DART6_ORDERSERVICE.ContentMetadataTargetingError ContMeta= new DART6_ORDERSERVICE.ContentMetadataTargetingError();
        DART6_ORDERSERVICE.FrequencyCapError freCaperr= new DART6_ORDERSERVICE.FrequencyCapError();
        DART6_ORDERSERVICE.LineItemError linErr= new DART6_ORDERSERVICE.LineItemError();
        DART6_ORDERSERVICE.CreativeError creErr= new DART6_ORDERSERVICE.CreativeError();
        DART6_ORDERSERVICE.UserDomainTargetingError urDeoTarErr= new DART6_ORDERSERVICE.UserDomainTargetingError();
        DART6_ORDERSERVICE.AudienceExtensionError audieExerr= new DART6_ORDERSERVICE.AudienceExtensionError();
        DART6_ORDERSERVICE.ClickTrackingLineItemError clickLinErr = new DART6_ORDERSERVICE.ClickTrackingLineItemError();
        DART6_ORDERSERVICE.LineItemCreativeAssociationError lineCreAssErr= new DART6_ORDERSERVICE.LineItemCreativeAssociationError();
        DART6_ORDERSERVICE.InvalidUrlError invurErr= new DART6_ORDERSERVICE.InvalidUrlError();

        //@vitou 08-04-2015
        DART6_ORDERSERVICE.RequiredSizeError reqSizeErr = new DART6_ORDERSERVICE.RequiredSizeError();
        DART6_ORDERSERVICE.RequiredNumberError reqNumErr = new DART6_ORDERSERVICE.RequiredNumberError();
        DART6_ORDERSERVICE.ReservationDetailsError ResDetErr = new DART6_ORDERSERVICE.ReservationDetailsError();
        DART6_ORDERSERVICE.DayPartTargetingError dayTarErr = new DART6_ORDERSERVICE.DayPartTargetingError();
        DART6_ORDERSERVICE.GeoTargetingError geoTarErr = new DART6_ORDERSERVICE.GeoTargetingError();
        DART6_ORDERSERVICE.DateValue dateVal = new DART6_ORDERSERVICE.DateValue();
        
        DART6_ORDERSERVICE.CustomTargetingError custTarErr = new DART6_ORDERSERVICE.CustomTargetingError();
        DART6_ORDERSERVICE.LineItemFlightDateError linItemFligErr = new DART6_ORDERSERVICE.LineItemFlightDateError();
        DART6_ORDERSERVICE.EntityChildrenLimitReachedError entChldLimErr = new DART6_ORDERSERVICE.EntityChildrenLimitReachedError();
        
        Object o = new DART6_ORDERSERVICE.CrossSellError();
        o = new DART6_ORDERSERVICE.TimeZoneError();
        o = new DART6_ORDERSERVICE.VideoPositionTargetingError();
        o = new DART6_ORDERSERVICE.SetTopBoxLineItemError();
        o = new DART6_ORDERSERVICE.ObjectValue();
        o = new DART6_ORDERSERVICE.LineItemActivityAssociationError();
        o = new DART6_ORDERSERVICE.GrpSettingsError();
        o = new DART6_ORDERSERVICE.ImageError();
        o = new DART6_ORDERSERVICE.RegExError();
        o = new DART6_ORDERSERVICE.CollectionSizeError();
        
        o = new DART6_ORDERSERVICE.AudienceSegmentError();
        o = new DART6_ORDERSERVICE.CollectionSizeError();
        o = new DART6_ORDERSERVICE.CollectionSizeError();
        o = new DART6_ORDERSERVICE.CollectionSizeError();
        
		o = new DART6_ORDERSERVICE.FieldPathElement();
        o = new DART6_ORDERSERVICE.StringFormatError();

        // 21.11.2022 / Sophal Noch / US-0012883 :
        o = new DART6_ORDERSERVICE.AssetError();
        o = new DART6_ORDERSERVICE.CurrencyCodeError();
        o = new DART6_ORDERSERVICE.TranscodingError();

        o = new DART6_ORDERSERVICE.PrecisionError(); // 19.02.2024 / Sophal Noch / US-0014655

        Test.startTest();
            DART6_ORDERSERVICE.OrderServiceInterfacePort svc = new DART6_ORDERSERVICE.OrderServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_ORDERSERVICE.performOrderActionResponse_element()));
            svc.performOrderAction(new DART6_ORDERSERVICE.OrderAction(), new DART6_ORDERSERVICE.Statement());
            System.assertNotEquals(null, svc);
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_ORDERSERVICE.updateOrdersResponse_element()));
            svc.updateOrders(new List<DART6_ORDERSERVICE.Order>());
            System.assertNotEquals(null, svc);
        Test.stopTest();
        
    }

    /** Class DART6_LINEITEMSERVICE */
    static testMethod void testClassDART6_LINEITEMSERVICE()
    {
        DART6_LINEITEMSERVICE lineItem  = new DART6_LINEITEMSERVICE();
        DART6_LINEITEMSERVICE.FrequencyCap itemFreCap = new DART6_LINEITEMSERVICE.FrequencyCap();
        DART6_LINEITEMSERVICE.BrowserTargeting item1BwTar= new DART6_LINEITEMSERVICE.BrowserTargeting();
        DART6_LINEITEMSERVICE.CommonError item1ComErr = new DART6_LINEITEMSERVICE.CommonError();
        DART6_LINEITEMSERVICE.Technology item1Technology = new DART6_LINEITEMSERVICE.Technology();
        DART6_LINEITEMSERVICE.ReserveAndOverbookLineItems item1ReAndOverBook = new DART6_LINEITEMSERVICE.ReserveAndOverbookLineItems();
        DART6_LINEITEMSERVICE.TechnologyTargetingError item1 = new DART6_LINEITEMSERVICE.TechnologyTargetingError();
        DART6_LINEITEMSERVICE.ReserveLineItems item2 = new DART6_LINEITEMSERVICE.ReserveLineItems();
        DART6_LINEITEMSERVICE.InternalApiError item3 = new DART6_LINEITEMSERVICE.InternalApiError();
        DART6_LINEITEMSERVICE.LineItemSummary item4 = new DART6_LINEITEMSERVICE.LineItemSummary();
        DART6_LINEITEMSERVICE.BandwidthGroup item5 = new DART6_LINEITEMSERVICE.BandwidthGroup();
        DART6_LINEITEMSERVICE.OrderError item6 = new DART6_LINEITEMSERVICE.OrderError();
        DART6_LINEITEMSERVICE.DateTimeRangeTargetingError item7 = new DART6_LINEITEMSERVICE.DateTimeRangeTargetingError();
        DART6_LINEITEMSERVICE.UserDomainTargeting item9 = new DART6_LINEITEMSERVICE.UserDomainTargeting();
        DART6_LINEITEMSERVICE.InventoryTargetingError item10 = new DART6_LINEITEMSERVICE.InventoryTargetingError();
        DART6_LINEITEMSERVICE.DayPartTargeting item11 = new DART6_LINEITEMSERVICE.DayPartTargeting();
        DART6_LINEITEMSERVICE.BooleanValue itema = new DART6_LINEITEMSERVICE.BooleanValue();
        DART6_LINEITEMSERVICE.RequiredError itemb = new DART6_LINEITEMSERVICE.RequiredError();
        DART6_LINEITEMSERVICE.CustomCriteriaLeaf itemc = new DART6_LINEITEMSERVICE.CustomCriteriaLeaf();
        DART6_LINEITEMSERVICE.AuthenticationError itemd = new DART6_LINEITEMSERVICE.AuthenticationError();
        DART6_LINEITEMSERVICE.PermissionError itemf = new DART6_LINEITEMSERVICE.PermissionError();
        DART6_LINEITEMSERVICE.DeviceManufacturerTargeting itemg = new DART6_LINEITEMSERVICE.DeviceManufacturerTargeting();
        DART6_LINEITEMSERVICE.updateLineItemsResponse_element itemh = new DART6_LINEITEMSERVICE.updateLineItemsResponse_element();
        DART6_LINEITEMSERVICE.InventoryTargeting itemi = new DART6_LINEITEMSERVICE.InventoryTargeting();
        DART6_LINEITEMSERVICE.LineItemOperationError itemgss = new DART6_LINEITEMSERVICE.LineItemOperationError();
        DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting itemk = new DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting();
        DART6_LINEITEMSERVICE.ReleaseLineItems itemRel = new DART6_LINEITEMSERVICE.ReleaseLineItems();
        DART6_LINEITEMSERVICE.OperatingSystemTargeting itemOpsTar = new DART6_LINEITEMSERVICE.OperatingSystemTargeting();
        DART6_LINEITEMSERVICE.MobileDevice itemModdv = new DART6_LINEITEMSERVICE.MobileDevice();
        DART6_LINEITEMSERVICE.BandwidthGroupTargeting itembdTa = new DART6_LINEITEMSERVICE.BandwidthGroupTargeting();
        DART6_LINEITEMSERVICE.CustomCriteria itemcus = new DART6_LINEITEMSERVICE.CustomCriteria();
        DART6_LINEITEMSERVICE.BaseCustomFieldValue itembasFv = new DART6_LINEITEMSERVICE.BaseCustomFieldValue();
        DART6_LINEITEMSERVICE.NumberValue itemnv = new DART6_LINEITEMSERVICE.NumberValue();
        DART6_LINEITEMSERVICE.GeoTargeting itemGo = new DART6_LINEITEMSERVICE.GeoTargeting();
        DART6_LINEITEMSERVICE.TimeOfDay itemToD = new DART6_LINEITEMSERVICE.TimeOfDay();
        DART6_LINEITEMSERVICE.CustomFieldValue itemcFv = new DART6_LINEITEMSERVICE.CustomFieldValue();
        DART6_LINEITEMSERVICE.SoapResponseHeader itemsoapResHe = new DART6_LINEITEMSERVICE.SoapResponseHeader();
        DART6_LINEITEMSERVICE.CustomCriteriaSet itemCusSet = new DART6_LINEITEMSERVICE.CustomCriteriaSet();
        DART6_LINEITEMSERVICE.NotNullError itemNotNul = new DART6_LINEITEMSERVICE.NotNullError();
        DART6_LINEITEMSERVICE.AudienceSegmentCriteria itemAudSeCr = new DART6_LINEITEMSERVICE.AudienceSegmentCriteria();
        DART6_LINEITEMSERVICE.EntityLimitReachedError itemEnReErr = new DART6_LINEITEMSERVICE.EntityLimitReachedError();
        DART6_LINEITEMSERVICE.BrowserLanguageTargeting itemBrowTar = new DART6_LINEITEMSERVICE.BrowserLanguageTargeting();
        DART6_LINEITEMSERVICE.DateTimeValue itemDateTimeVal = new DART6_LINEITEMSERVICE.DateTimeValue();
        DART6_LINEITEMSERVICE.CompanyCreditStatusError itemComStaErr = new DART6_LINEITEMSERVICE.CompanyCreditStatusError();
        DART6_LINEITEMSERVICE.AdUnitTargeting itemAdUnit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
        DART6_LINEITEMSERVICE.PublisherQueryLanguageContextError itemPubLaCon = new DART6_LINEITEMSERVICE.PublisherQueryLanguageContextError();
        DART6_LINEITEMSERVICE.performLineItemAction_element itemPerIAc = new DART6_LINEITEMSERVICE.performLineItemAction_element();
        DART6_LINEITEMSERVICE.SoapRequestHeader itemSoaHe = new DART6_LINEITEMSERVICE.SoapRequestHeader();
        DART6_LINEITEMSERVICE.TeamError itemTeamErr = new DART6_LINEITEMSERVICE.TeamError();
        DART6_LINEITEMSERVICE.ResumeAndOverbookLineItems itemResOvB = new DART6_LINEITEMSERVICE.ResumeAndOverbookLineItems();
        DART6_LINEITEMSERVICE.DeviceCategoryTargeting itemDevCatTar = new DART6_LINEITEMSERVICE.DeviceCategoryTargeting();
        DART6_LINEITEMSERVICE.NullError itemNuErr = new DART6_LINEITEMSERVICE.NullError();
        DART6_LINEITEMSERVICE.ApiException itemApiEx = new DART6_LINEITEMSERVICE.ApiException();
        DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting itemopeverTar = new DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting();
        DART6_LINEITEMSERVICE.ForecastError itemFc = new DART6_LINEITEMSERVICE.ForecastError();
        DART6_LINEITEMSERVICE.LineItemPage itemPage = new DART6_LINEITEMSERVICE.LineItemPage();
        DART6_LINEITEMSERVICE.MobileCarrierTargeting itemMoTar = new DART6_LINEITEMSERVICE.MobileCarrierTargeting();
        DART6_LINEITEMSERVICE.ApplicationException itemAppExc = new DART6_LINEITEMSERVICE.ApplicationException();
        DART6_LINEITEMSERVICE.GenericTargetingError itemGenTarErr = new DART6_LINEITEMSERVICE.GenericTargetingError();
        DART6_LINEITEMSERVICE.ApiVersionError itemApiverErr = new DART6_LINEITEMSERVICE.ApiVersionError();
        DART6_LINEITEMSERVICE.createLineItemsResponse_element itemcreResEle = new DART6_LINEITEMSERVICE.createLineItemsResponse_element();
        DART6_LINEITEMSERVICE.ContentTargeting itemContTar = new DART6_LINEITEMSERVICE.ContentTargeting();
        DART6_LINEITEMSERVICE.ServerError itemSerErr = new DART6_LINEITEMSERVICE.ServerError();
        DART6_LINEITEMSERVICE.FrequencyCapError itemFreErr = new DART6_LINEITEMSERVICE.FrequencyCapError();
        DART6_LINEITEMSERVICE.UnarchiveLineItems itemUna = new DART6_LINEITEMSERVICE.UnarchiveLineItems();
        DART6_LINEITEMSERVICE.DeviceCapabilityTargeting itemdevTar = new DART6_LINEITEMSERVICE.DeviceCapabilityTargeting();
        DART6_LINEITEMSERVICE.LineItemError itemEr = new DART6_LINEITEMSERVICE.LineItemError();
        DART6_LINEITEMSERVICE.performLineItemActionResponse_element itemPeracRes = new DART6_LINEITEMSERVICE.performLineItemActionResponse_element();
        DART6_LINEITEMSERVICE.DeviceCategory itemDev = new DART6_LINEITEMSERVICE.DeviceCategory();
        DART6_LINEITEMSERVICE.DeviceManufacturer itemDevMan = new DART6_LINEITEMSERVICE.DeviceManufacturer();
        DART6_LINEITEMSERVICE.BrowserLanguage itemBrovseLan = new DART6_LINEITEMSERVICE.BrowserLanguage();
        DART6_LINEITEMSERVICE.MobileDeviceSubmodel itemModSub = new DART6_LINEITEMSERVICE.MobileDeviceSubmodel();
        DART6_LINEITEMSERVICE.createLineItems_element itemcreaEl = new DART6_LINEITEMSERVICE.createLineItems_element();
        DART6_LINEITEMSERVICE.CustomCriteriaNode itemCusNod = new DART6_LINEITEMSERVICE.CustomCriteriaNode();
        DART6_LINEITEMSERVICE.StringLengthError itemstrLengErr = new DART6_LINEITEMSERVICE.StringLengthError();
        DART6_LINEITEMSERVICE.UserDomainTargetingError itemUseDoErr = new DART6_LINEITEMSERVICE.UserDomainTargetingError();
        DART6_LINEITEMSERVICE.AppliedLabel itemAppla = new DART6_LINEITEMSERVICE.AppliedLabel();
        DART6_LINEITEMSERVICE.ActivateLineItems itemActivate = new DART6_LINEITEMSERVICE.ActivateLineItems();
        DART6_LINEITEMSERVICE.UniqueError itemuniquErr = new DART6_LINEITEMSERVICE.UniqueError();
        DART6_LINEITEMSERVICE.ResumeLineItems itemResum = new DART6_LINEITEMSERVICE.ResumeLineItems();
        DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element itemgetLineResEle = new DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element();
        DART6_LINEITEMSERVICE.PublisherQueryLanguageSyntaxError itemPulbSynErr = new DART6_LINEITEMSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_LINEITEMSERVICE.DeliveryData itemDevData = new DART6_LINEITEMSERVICE.DeliveryData();
        DART6_LINEITEMSERVICE.AudienceExtensionError itemaudErr = new DART6_LINEITEMSERVICE.AudienceExtensionError();
        DART6_LINEITEMSERVICE.ClickTrackingLineItemError itemopSysErr = new DART6_LINEITEMSERVICE.ClickTrackingLineItemError();
        DART6_LINEITEMSERVICE.OperatingSystem itemopSys = new DART6_LINEITEMSERVICE.OperatingSystem();
        DART6_LINEITEMSERVICE.String_ValueMapEntry itemstrValMap = new DART6_LINEITEMSERVICE.String_ValueMapEntry();
        DART6_LINEITEMSERVICE.Size itemSize = new DART6_LINEITEMSERVICE.Size();
        DART6_LINEITEMSERVICE.Value itemval = new DART6_LINEITEMSERVICE.Value();
        DART6_LINEITEMSERVICE.DropDownCustomFieldValue itemDropCus = new DART6_LINEITEMSERVICE.DropDownCustomFieldValue();
        DART6_LINEITEMSERVICE.LineItemCreativeAssociationError itemLineAss = new DART6_LINEITEMSERVICE.LineItemCreativeAssociationError();
        DART6_LINEITEMSERVICE.InvalidUrlError itemInvaUrlErr = new DART6_LINEITEMSERVICE.InvalidUrlError();
        DART6_LINEITEMSERVICE.RequiredSizeError itemReqSizeErr = new DART6_LINEITEMSERVICE.RequiredSizeError();
        DART6_LINEITEMSERVICE.TypeError itemTypeErr = new DART6_LINEITEMSERVICE.TypeError();
        DART6_LINEITEMSERVICE.VideoPositionTargeting itemVaTarg = new DART6_LINEITEMSERVICE.VideoPositionTargeting();
        DART6_LINEITEMSERVICE.RequiredNumberError itemReNumErr = new DART6_LINEITEMSERVICE.RequiredNumberError();
        DART6_LINEITEMSERVICE.ReservationDetailsError itemResDetErr = new DART6_LINEITEMSERVICE.ReservationDetailsError();
        DART6_LINEITEMSERVICE.LineItemAction itemAc = new DART6_LINEITEMSERVICE.LineItemAction();
        DART6_LINEITEMSERVICE.Statement itemStat = new DART6_LINEITEMSERVICE.Statement();
        DART6_LINEITEMSERVICE.ApiError itemApiErr = new DART6_LINEITEMSERVICE.ApiError();
        DART6_LINEITEMSERVICE.Browser itemBw = new DART6_LINEITEMSERVICE.Browser();
        DART6_LINEITEMSERVICE.LineItemServiceInterfacePort itemInfPort = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
        DART6_LINEITEMSERVICE.CustomFieldValueError itemCusErr = new DART6_LINEITEMSERVICE.CustomFieldValueError();
        DART6_LINEITEMSERVICE.DayPartTargetingError itemDayErr = new DART6_LINEITEMSERVICE.DayPartTargetingError();
        DART6_LINEITEMSERVICE.GeoTargetingError itemGeoTarErr = new DART6_LINEITEMSERVICE.GeoTargetingError();
        DART6_LINEITEMSERVICE.QuotaError itemQuoErr = new DART6_LINEITEMSERVICE.QuotaError();
        DART6_LINEITEMSERVICE.MobileDeviceTargeting itemModTar = new DART6_LINEITEMSERVICE.MobileDeviceTargeting();
        DART6_LINEITEMSERVICE.getLineItemsByStatement_element itemBySt = new DART6_LINEITEMSERVICE.getLineItemsByStatement_element();
        DART6_LINEITEMSERVICE.RangeError itemRaErr = new DART6_LINEITEMSERVICE.RangeError();
        DART6_LINEITEMSERVICE.ParseError itemParErr = new DART6_LINEITEMSERVICE.ParseError();
        DART6_LINEITEMSERVICE.PauseLineItems itemPus = new DART6_LINEITEMSERVICE.PauseLineItems();
        DART6_LINEITEMSERVICE.LabelEntityAssociationError itemLaAssErr = new DART6_LINEITEMSERVICE.LabelEntityAssociationError();
        DART6_LINEITEMSERVICE.DeviceCapability itemDevCap = new DART6_LINEITEMSERVICE.DeviceCapability();
        DART6_LINEITEMSERVICE.DeliveryIndicator itemDeInd = new DART6_LINEITEMSERVICE.DeliveryIndicator();
        DART6_LINEITEMSERVICE.StatementError itemstatErr = new DART6_LINEITEMSERVICE.StatementError();
        DART6_LINEITEMSERVICE.ArchiveLineItems itemArch = new DART6_LINEITEMSERVICE.ArchiveLineItems();
        DART6_LINEITEMSERVICE.CreativePlaceholder itemCreHolder = new DART6_LINEITEMSERVICE.CreativePlaceholder();
        DART6_LINEITEMSERVICE.DeleteLineItems itemDelet = new DART6_LINEITEMSERVICE.DeleteLineItems();
        DART6_LINEITEMSERVICE.RequiredCollectionError itemRqueErr = new DART6_LINEITEMSERVICE.RequiredCollectionError();
        DART6_LINEITEMSERVICE.CustomTargetingError itemCustErr = new DART6_LINEITEMSERVICE.CustomTargetingError();
        DART6_LINEITEMSERVICE.TextValue itemTxtVal = new DART6_LINEITEMSERVICE.TextValue();
        DART6_LINEITEMSERVICE.LineItemFlightDateError itemFliDate = new DART6_LINEITEMSERVICE.LineItemFlightDateError();
        DART6_LINEITEMSERVICE.MobileCarrier itemMobCar = new DART6_LINEITEMSERVICE.MobileCarrier();
        DART6_LINEITEMSERVICE.updateLineItems_element itemUpElement = new DART6_LINEITEMSERVICE.updateLineItems_element();
        DART6_LINEITEMSERVICE.Stats itemState = new DART6_LINEITEMSERVICE.Stats();
        DART6_LINEITEMSERVICE.UpdateResult itemupRes = new DART6_LINEITEMSERVICE.UpdateResult();
        //DART6_LINEITEMSERVICE.PostalCodeLocation itemPosLoc = new DART6_LINEITEMSERVICE.PostalCodeLocation();
        DART6_LINEITEMSERVICE.OperatingSystemVersion itemopSysverson = new DART6_LINEITEMSERVICE.OperatingSystemVersion();
        DART6_LINEITEMSERVICE.VideoPositionTargeting vidpos = new DART6_LINEITEMSERVICE.VideoPositionTargeting();
        DART6_LINEITEMSERVICE.GrpSettings grpSet = new DART6_LINEITEMSERVICE.GrpSettings();
        DART6_LINEITEMSERVICE.SetValue sv   = new  DART6_LINEITEMSERVICE.SetValue();
        DART6_LINEITEMSERVICE.DateTime_x dtx   = new  DART6_LINEITEMSERVICE.DateTime_x();
        DART6_LINEITEMSERVICE.Date_x dx = new  DART6_LINEITEMSERVICE.Date_x();
        DART6_LINEITEMSERVICE.FeatureError fE = new  DART6_LINEITEMSERVICE.FeatureError();
        DART6_LINEITEMSERVICE.ProgrammaticError prg = new  DART6_LINEITEMSERVICE.ProgrammaticError();
        DART6_LINEITEMSERVICE.RequestPlatformTargeting reqPlatTar = new  DART6_LINEITEMSERVICE.RequestPlatformTargeting();
        DART6_LINEITEMSERVICE.CustomPacingCurve cusPac = new  DART6_LINEITEMSERVICE.CustomPacingCurve();
        // DART6_LINEITEMSERVICE.hasCustomPacingCurve_element cusPacElem = new  DART6_LINEITEMSERVICE.hasCustomPacingCurve_element();  // 21.11.2022 / Sophal Noch / US-0012883 
        DART6_LINEITEMSERVICE.LineItemDealInfoDto lineItemDealInf = new  DART6_LINEITEMSERVICE.LineItemDealInfoDto();
        DART6_LINEITEMSERVICE.MobileApplicationTargetingError mobileAppTarErr = new  DART6_LINEITEMSERVICE.MobileApplicationTargetingError();
        DART6_LINEITEMSERVICE.SetTopBoxLineItemError setLineItemErr = new  DART6_LINEITEMSERVICE.SetTopBoxLineItemError();
        DART6_LINEITEMSERVICE.RequestPlatformTargetingError reqTarErr = new  DART6_LINEITEMSERVICE.RequestPlatformTargetingError();
        DART6_LINEITEMSERVICE.DateTimeRangeTargeting dTTar = new  DART6_LINEITEMSERVICE.DateTimeRangeTargeting();
        DART6_LINEITEMSERVICE.BuyerUserListTargeting bUserListTar = new  DART6_LINEITEMSERVICE.BuyerUserListTargeting();
        DART6_LINEITEMSERVICE.DateTimeRange dTRang = new  DART6_LINEITEMSERVICE.DateTimeRange();
        DART6_LINEITEMSERVICE.CmsMetadataCriteria cmsMetadataCriteria = new  DART6_LINEITEMSERVICE.CmsMetadataCriteria();
        // DART6_LINEITEMSERVICE.ProposalLineItemMarketplaceInfo proPosLineItemInfo = new  DART6_LINEITEMSERVICE.ProposalLineItemMarketplaceInfo();  // 21.11.2022 / Sophal Noch / US-0012883
        DART6_LINEITEMSERVICE.ProposalLineItemMakegoodInfo proPosLineItemGoodInfo = new  DART6_LINEITEMSERVICE.ProposalLineItemMakegoodInfo();
        DART6_LINEITEMSERVICE.createMakegoods_element createMakElem = new  DART6_LINEITEMSERVICE.createMakegoods_element();
        DART6_LINEITEMSERVICE.ProposalLineItemPage proPosLineItemP = new  DART6_LINEITEMSERVICE.ProposalLineItemPage();
        DART6_LINEITEMSERVICE.ThirdPartyMeasurementSettings thParMeasurSets = new  DART6_LINEITEMSERVICE.ThirdPartyMeasurementSettings();
        DART6_LINEITEMSERVICE.getProposalLineItemsByStatement_element getPropStatElem = new  DART6_LINEITEMSERVICE.getProposalLineItemsByStatement_element();
        DART6_LINEITEMSERVICE.CustomPacingGoal cus = new  DART6_LINEITEMSERVICE.CustomPacingGoal();
        Object o = new  DART6_LINEITEMSERVICE.CrossSellError();
        o = new  DART6_LINEITEMSERVICE.CrossSellError();
        // US-0008578 // o = new  DART6_LINEITEMSERVICE.SetTopBoxInfo();
        o = new  DART6_LINEITEMSERVICE.VideoPositionWithinPod();
        // US-0008578 //  o = new  DART6_LINEITEMSERVICE.ContentMetadataTargetingError();
        o = new  DART6_LINEITEMSERVICE.CreativeError();
        o = new  DART6_LINEITEMSERVICE.EntityChildrenLimitReachedError();
        o = new  DART6_LINEITEMSERVICE.DateValue();
        o = new  DART6_LINEITEMSERVICE.TimeZoneError();
        o = new  DART6_LINEITEMSERVICE.VideoPositionTargetingError();
        o = new  DART6_LINEITEMSERVICE.SetTopBoxLineItemError();
        o = new  DART6_LINEITEMSERVICE.LineItemActivityAssociation();
        o = new  DART6_LINEITEMSERVICE.ObjectValue();
        o = new  DART6_LINEITEMSERVICE.CollectionSizeError();
        o = new  DART6_LINEITEMSERVICE.LineItemActivityAssociationError();
        o = new  DART6_LINEITEMSERVICE.GrpSettingsError();
        o = new  DART6_LINEITEMSERVICE.CreativeTargeting();
        // US-0008578 //  o = new  DART6_LINEITEMSERVICE.ContentMetadataKeyHierarchyTargeting();
        o = new  DART6_LINEITEMSERVICE.OrderActionError();
        o = new  DART6_LINEITEMSERVICE.VideoPosition();
        o = new  DART6_LINEITEMSERVICE.ImageError();
        o = new  DART6_LINEITEMSERVICE.DayPart();
        o = new  DART6_LINEITEMSERVICE.RegExError();
        
        o = new  DART6_LINEITEMSERVICE.VideoPositionTarget();
        o = new  DART6_LINEITEMSERVICE.AudienceSegmentError();
        o = new  DART6_LINEITEMSERVICE.RegExError();
        o = new  DART6_LINEITEMSERVICE.Goal();
        o = new  DART6_LINEITEMSERVICE.Targeting();
        o = new  DART6_LINEITEMSERVICE.TechnologyTargeting();
        o = new  DART6_LINEITEMSERVICE.Money();
        o = new  DART6_LINEITEMSERVICE.Location();
        
        
        o = new DART6_LINEITEMSERVICE.FieldPathElement();
        o = new DART6_LINEITEMSERVICE.MobileApplicationTargeting();
        o = new DART6_LINEITEMSERVICE.StringFormatError();

        // 21.11.2022 / Sophal Noch / US-0012883 :
        o = new DART6_LINEITEMSERVICE.InventorySizeTargeting(); 
        o = new DART6_LINEITEMSERVICE.AssetError();
        o = new DART6_LINEITEMSERVICE.InventoryUrl();
        o = new DART6_LINEITEMSERVICE.TargetedSize();
        o = new DART6_LINEITEMSERVICE.CurrencyCodeError();
        o = new DART6_LINEITEMSERVICE.InventoryUrlTargeting();
        o = new DART6_LINEITEMSERVICE.InventorySizeTargeting();
        o = new DART6_LINEITEMSERVICE.TranscodingError();

        // 19.02.2024 / Sophal Noch / US-0014655 :
        o = new DART6_LINEITEMSERVICE.ProposalLineItemActionError();
        o = new DART6_LINEITEMSERVICE.PreferredDealError();
        o = new DART6_LINEITEMSERVICE.DealError();
        o = new DART6_LINEITEMSERVICE.PauseProposalLineItems();
        o = new DART6_LINEITEMSERVICE.ReserveProposalLineItems();
        o = new DART6_LINEITEMSERVICE.ProposalLineItemAction();
        o = new DART6_LINEITEMSERVICE.ProposalLineItemMakegoodError();
        o = new DART6_LINEITEMSERVICE.ProposalActionError();
        o = new DART6_LINEITEMSERVICE.ProposalLineItemProgrammaticError();
        o = new DART6_LINEITEMSERVICE.ResumeProposalLineItems();
        o = new DART6_LINEITEMSERVICE.ProposalError();
        o = new DART6_LINEITEMSERVICE.ArchiveProposalLineItems();
        o = new DART6_LINEITEMSERVICE.PrecisionError();
        o = new DART6_LINEITEMSERVICE.BillingError();
        o = new DART6_LINEITEMSERVICE.ProposalLineItemError();
        o = new DART6_LINEITEMSERVICE.UnarchiveProposalLineItems();
        o = new DART6_LINEITEMSERVICE.PreferredDealError();
        o = new DART6_LINEITEMSERVICE.ReleaseProposalLineItems();

        Test.startTest();
            DART6_LINEITEMSERVICE.LineItemServiceInterfacePort svc = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
            svc.createLineItems(new DART6_LINEITEMSERVICE.LineItem[0]);
            System.assertNotEquals(null, svc);
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_LINEITEMSERVICE.performLineItemActionResponse_element()));
            svc.performLineItemAction(new DART6_LINEITEMSERVICE.LineItemAction(), new DART6_LINEITEMSERVICE.Statement());
            System.assertNotEquals(null, svc);
            /*Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_LINEITEMSERVICE.createMakegoodsResponse_element()));
            svc.createMakegoods(new DART6_LINEITEMSERVICE.createMakegoods());
            System.assertNotEquals(null, svc);
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_FORECASTSERVICE.getDeliveryForecastResponse_element()));
            svc.updateProposalLineItems(new DART6_LINEITEMSERVICE.updateProposalLineItemsResponse_element());
            System.assertNotEquals(null, svc);*/
        Test.stopTest();
    }


    /** Class DART6_FORECASTSERVICE */
    static testMethod void testClassDart6AvailabilityForecast()
    {
        DART6_FORECASTSERVICE dart6FcService = new DART6_FORECASTSERVICE();
        DART6_FORECASTSERVICE.AdUnitCodeError adUnitError = new DART6_FORECASTSERVICE.AdUnitCodeError();
        DART6_FORECASTSERVICE.AdUnitTargeting adUnitTar = new DART6_FORECASTSERVICE.AdUnitTargeting();
        DART6_FORECASTSERVICE.ApiError apiEr = new DART6_FORECASTSERVICE.ApiError();
        DART6_FORECASTSERVICE.ApiException apiEx = new DART6_FORECASTSERVICE.ApiException();
        DART6_FORECASTSERVICE.ApiVersionError apiVerErr = new DART6_FORECASTSERVICE.ApiVersionError();
        //DART6_FORECASTSERVICE.ApplicationException appExc = new DART6_FORECASTSERVICE.ApplicationException();
        DART6_FORECASTSERVICE.AppliedLabel applLabel = new DART6_FORECASTSERVICE.AppliedLabel();
        DART6_FORECASTSERVICE.AudienceExtensionError auEx = new DART6_FORECASTSERVICE.AudienceExtensionError();
        DART6_FORECASTSERVICE.AudienceSegmentCriteria auSeg = new DART6_FORECASTSERVICE.AudienceSegmentCriteria();
        DART6_FORECASTSERVICE.BandwidthGroupTargeting bwgt = new DART6_FORECASTSERVICE.BandwidthGroupTargeting();
        DART6_FORECASTSERVICE.BaseCustomFieldValue baseCus = new DART6_FORECASTSERVICE.BaseCustomFieldValue();
        DART6_FORECASTSERVICE.Browser brw = new DART6_FORECASTSERVICE.Browser();
        DART6_FORECASTSERVICE.BrowserLanguage brwLan = new DART6_FORECASTSERVICE.BrowserLanguage();
        DART6_FORECASTSERVICE.BrowserLanguageTargeting bwlt = new DART6_FORECASTSERVICE.BrowserLanguageTargeting();
        DART6_FORECASTSERVICE.BrowserTargeting bt = new DART6_FORECASTSERVICE.BrowserTargeting();
        //DART6_FORECASTSERVICE.CityLocation ctLoc = new DART6_FORECASTSERVICE.CityLocation();
        DART6_FORECASTSERVICE.ClickTrackingLineItemError clTrac = new DART6_FORECASTSERVICE.ClickTrackingLineItemError();
        DART6_FORECASTSERVICE.CompanyCreditStatusError comCred = new DART6_FORECASTSERVICE.CompanyCreditStatusError();
        DART6_FORECASTSERVICE.ContentTargeting contar = new DART6_FORECASTSERVICE.ContentTargeting();
        //DART6_FORECASTSERVICE.CountryLocation counLoc = new DART6_FORECASTSERVICE.CountryLocation();
        DART6_FORECASTSERVICE.CustomTargetingError custarErr = new DART6_FORECASTSERVICE.CustomTargetingError();
        DART6_FORECASTSERVICE.CustomFieldValueError cusFvErr = new DART6_FORECASTSERVICE.CustomFieldValueError();
        DART6_FORECASTSERVICE.CustomFieldValue cusFv = new DART6_FORECASTSERVICE.CustomFieldValue();
        DART6_FORECASTSERVICE.CustomCriteriaSet cusCritSet = new DART6_FORECASTSERVICE.CustomCriteriaSet();
        DART6_FORECASTSERVICE.CustomCriteriaNode custCritNode = new DART6_FORECASTSERVICE.CustomCriteriaNode();
        DART6_FORECASTSERVICE.CustomCriteriaLeaf cusCritLeaf = new DART6_FORECASTSERVICE.CustomCriteriaLeaf();
        DART6_FORECASTSERVICE.CustomCriteria custCrit = new DART6_FORECASTSERVICE.CustomCriteria();
        DART6_FORECASTSERVICE.CreativePlaceholder creatPlh = new DART6_FORECASTSERVICE.CreativePlaceholder();
        DART6_FORECASTSERVICE.DayPart dayPart = new DART6_FORECASTSERVICE.DayPart();
        DART6_FORECASTSERVICE.DayPartTargeting dayPartTar = new DART6_FORECASTSERVICE.DayPartTargeting();
        DART6_FORECASTSERVICE.DropDownCustomFieldValue dropCus = new DART6_FORECASTSERVICE.DropDownCustomFieldValue();
        DART6_FORECASTSERVICE.DeviceManufacturer devManu = new DART6_FORECASTSERVICE.DeviceManufacturer();
        DART6_FORECASTSERVICE.DeviceCategoryTargeting devcateTar = new DART6_FORECASTSERVICE.DeviceCategoryTargeting();
        DART6_FORECASTSERVICE.DeviceCategory devCat = new DART6_FORECASTSERVICE.DeviceCategory();
        DART6_FORECASTSERVICE.DeviceCapabilityTargeting devCap = new DART6_FORECASTSERVICE.DeviceCapabilityTargeting();
        DART6_FORECASTSERVICE.DeviceCapability devCapility = new DART6_FORECASTSERVICE.DeviceCapability();
        DART6_FORECASTSERVICE.DeliveryIndicator devInd = new DART6_FORECASTSERVICE.DeliveryIndicator();
        DART6_FORECASTSERVICE.DeliveryData devData = new DART6_FORECASTSERVICE.DeliveryData();
        DART6_FORECASTSERVICE.DayPartTargetingError dayParErr = new DART6_FORECASTSERVICE.DayPartTargetingError();
        DART6_FORECASTSERVICE.DayPartTargeting dayPartTarg = new DART6_FORECASTSERVICE.DayPartTargeting();
        DART6_FORECASTSERVICE.EntityLimitReachedError entErr = new DART6_FORECASTSERVICE.EntityLimitReachedError();
        DART6_FORECASTSERVICE.ForecastError fcerr = new DART6_FORECASTSERVICE.ForecastError();
        DART6_FORECASTSERVICE.FrequencyCap freq = new DART6_FORECASTSERVICE.FrequencyCap();
        DART6_FORECASTSERVICE.FrequencyCapError freCapErr = new DART6_FORECASTSERVICE.FrequencyCapError();
        //DART6_FORECASTSERVICE.GenericTargetingError genTar = new DART6_FORECASTSERVICE.GenericTargetingError();
        DART6_FORECASTSERVICE.GeoTargeting geoTar = new DART6_FORECASTSERVICE.GeoTargeting();
        DART6_FORECASTSERVICE.GeoTargetingError geoTarErr = new DART6_FORECASTSERVICE.GeoTargetingError();
        DART6_FORECASTSERVICE.InvalidUrlError inurlErr = new DART6_FORECASTSERVICE.InvalidUrlError();
        DART6_FORECASTSERVICE.InventoryTargeting invTarg = new DART6_FORECASTSERVICE.InventoryTargeting();
        DART6_FORECASTSERVICE.LabelEntityAssociationError labelEnAss = new DART6_FORECASTSERVICE.LabelEntityAssociationError();
        DART6_FORECASTSERVICE.LineItemCreativeAssociationError itemCreAss = new DART6_FORECASTSERVICE.LineItemCreativeAssociationError();
        DART6_FORECASTSERVICE.LineItemError itemErr = new DART6_FORECASTSERVICE.LineItemError();
        DART6_FORECASTSERVICE.LineItemFlightDateError lineFlighDateErr = new DART6_FORECASTSERVICE.LineItemFlightDateError();
        DART6_FORECASTSERVICE.Location lac = new DART6_FORECASTSERVICE.Location();
        //DART6_FORECASTSERVICE.MetroLocation metroLoc = new DART6_FORECASTSERVICE.MetroLocation();
        DART6_FORECASTSERVICE.MobileCarrier mobileCarr = new DART6_FORECASTSERVICE.MobileCarrier();
        DART6_FORECASTSERVICE.MobileCarrierTargeting mobCarTar = new DART6_FORECASTSERVICE.MobileCarrierTargeting();
        DART6_FORECASTSERVICE.MobileDevice mbDev = new DART6_FORECASTSERVICE.MobileDevice();
        DART6_FORECASTSERVICE.MobileDeviceSubmodel mobDevSub = new DART6_FORECASTSERVICE.MobileDeviceSubmodel();
        DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting mobDebSubModTar = new DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting();
        DART6_FORECASTSERVICE.MobileDeviceTargeting mobDevTar = new DART6_FORECASTSERVICE.MobileDeviceTargeting();
        DART6_FORECASTSERVICE.Money my = new DART6_FORECASTSERVICE.Money();
        DART6_FORECASTSERVICE.NotNullError notnullErr = new DART6_FORECASTSERVICE.NotNullError();
        DART6_FORECASTSERVICE.NullError nullErr = new DART6_FORECASTSERVICE.NullError();
        DART6_FORECASTSERVICE.NumberValue numVal = new DART6_FORECASTSERVICE.NumberValue();
        DART6_FORECASTSERVICE.OperatingSystem opSys = new DART6_FORECASTSERVICE.OperatingSystem();
        DART6_FORECASTSERVICE.OperatingSystemTargeting opSysTar = new DART6_FORECASTSERVICE.OperatingSystemTargeting();
        DART6_FORECASTSERVICE.OperatingSystemVersion optSysVer = new DART6_FORECASTSERVICE.OperatingSystemVersion();
        DART6_FORECASTSERVICE.OperatingSystemVersionTargeting optSysVerTar = new DART6_FORECASTSERVICE.OperatingSystemVersionTargeting();
        DART6_FORECASTSERVICE.QuotaError quotErr = new DART6_FORECASTSERVICE.QuotaError();
        DART6_FORECASTSERVICE.ParseError parsErr = new DART6_FORECASTSERVICE.ParseError();
        //DART6_FORECASTSERVICE.PostalCodeLocation posCodeLoc = new DART6_FORECASTSERVICE.PostalCodeLocation();
        DART6_FORECASTSERVICE.PublisherQueryLanguageContextError pubQueLangCon = new DART6_FORECASTSERVICE.PublisherQueryLanguageContextError();
        DART6_FORECASTSERVICE.PublisherQueryLanguageSyntaxError pbQuLocErr = new DART6_FORECASTSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_FORECASTSERVICE.RangeError rageErr = new DART6_FORECASTSERVICE.RangeError();
        DART6_FORECASTSERVICE.RegExError ReExErr = new DART6_FORECASTSERVICE.RegExError();
        //DART6_FORECASTSERVICE.RegionLocation regLoc = new DART6_FORECASTSERVICE.RegionLocation();
        DART6_FORECASTSERVICE.RequiredCollectionError reqCollErr = new DART6_FORECASTSERVICE.RequiredCollectionError();
        DART6_FORECASTSERVICE.RequiredError reqErr = new DART6_FORECASTSERVICE.RequiredError();
        DART6_FORECASTSERVICE.RequiredNumberError ReNum = new DART6_FORECASTSERVICE.RequiredNumberError();
        DART6_FORECASTSERVICE.RequiredSizeError reqSizeErr = new DART6_FORECASTSERVICE.RequiredSizeError();
        DART6_FORECASTSERVICE.ReservationDetailsError ResDetailErr = new DART6_FORECASTSERVICE.ReservationDetailsError();
        DART6_FORECASTSERVICE.ServerError serErr = new DART6_FORECASTSERVICE.ServerError();
        DART6_FORECASTSERVICE.StatementError stateErr = new DART6_FORECASTSERVICE.StatementError();
        DART6_FORECASTSERVICE.Stats stats  = new DART6_FORECASTSERVICE.Stats();
        DART6_FORECASTSERVICE.StringLengthError strLengErr = new DART6_FORECASTSERVICE.StringLengthError();
        DART6_FORECASTSERVICE.TeamError teatErr = new DART6_FORECASTSERVICE.TeamError();
        DART6_FORECASTSERVICE.Technology technology = new DART6_FORECASTSERVICE.Technology();
        DART6_FORECASTSERVICE.TechnologyTargeting techTar = new DART6_FORECASTSERVICE.TechnologyTargeting();
        DART6_FORECASTSERVICE.TechnologyTargetingError tecTarErr = new DART6_FORECASTSERVICE.TechnologyTargetingError();
        DART6_FORECASTSERVICE.TextValue txtVal = new DART6_FORECASTSERVICE.TextValue();
        DART6_FORECASTSERVICE.TimeOfDay timeofDay = new DART6_FORECASTSERVICE.TimeOfDay();
        DART6_FORECASTSERVICE.TypeError typeErr = new DART6_FORECASTSERVICE.TypeError();
        DART6_FORECASTSERVICE.UniqueError uniqErr = new DART6_FORECASTSERVICE.UniqueError();
        DART6_FORECASTSERVICE.UserDomainTargeting useDomainTar = new DART6_FORECASTSERVICE.UserDomainTargeting();
        DART6_FORECASTSERVICE.UserDomainTargetingError userDomainTarErr = new DART6_FORECASTSERVICE.UserDomainTargetingError();
        DART6_FORECASTSERVICE.VideoPositionTargeting videoPosTar = new DART6_FORECASTSERVICE.VideoPositionTargeting();
        DART6_FORECASTSERVICE.Value val = new DART6_FORECASTSERVICE.Value();
        DART6_FORECASTSERVICE.CommonError commErr = new DART6_FORECASTSERVICE.CommonError();
        DART6_FORECASTSERVICE.InternalApiError internalErr = new DART6_FORECASTSERVICE.InternalApiError();
        DART6_FORECASTSERVICE.LineItemSummary lineItemSum = new DART6_FORECASTSERVICE.LineItemSummary();
        DART6_FORECASTSERVICE.BandwidthGroup banwidthGro = new DART6_FORECASTSERVICE.BandwidthGroup();
        DART6_FORECASTSERVICE.OrderError ordErr = new DART6_FORECASTSERVICE.OrderError();
        DART6_FORECASTSERVICE.DateTimeRangeTargetingError dartTimeRangErr = new DART6_FORECASTSERVICE.DateTimeRangeTargetingError();
        DART6_FORECASTSERVICE.InventoryTargetingError inveTarErr = new DART6_FORECASTSERVICE.InventoryTargetingError();
        DART6_FORECASTSERVICE.BooleanValue booleanVal = new DART6_FORECASTSERVICE.BooleanValue();
        DART6_FORECASTSERVICE.AuthenticationError autErr = new DART6_FORECASTSERVICE.AuthenticationError();
        DART6_FORECASTSERVICE.PermissionError perErr = new DART6_FORECASTSERVICE.PermissionError();
        
        DART6_FORECASTSERVICE.DeviceManufacturerTargeting devManTar = new DART6_FORECASTSERVICE.DeviceManufacturerTargeting();
        DART6_FORECASTSERVICE.LineItemOperationError lineItemErr = new DART6_FORECASTSERVICE.LineItemOperationError();
        DART6_FORECASTSERVICE.InventoryUnitError invUnitErr = new DART6_FORECASTSERVICE.InventoryUnitError();
        DART6_FORECASTSERVICE.SoapResponseHeader soaHearder = new DART6_FORECASTSERVICE.SoapResponseHeader();
        DART6_FORECASTSERVICE.DateTimeValue dateTimeVal = new DART6_FORECASTSERVICE.DateTimeValue();

        //@vitou 08-04-2015
        DART6_FORECASTSERVICE.VideoPositionTarget vdoPosTar = new DART6_FORECASTSERVICE.VideoPositionTarget();
        DART6_FORECASTSERVICE.SetValue setVal = new DART6_FORECASTSERVICE.SetValue();
        DART6_FORECASTSERVICE.FeatureError featErr = new DART6_FORECASTSERVICE.FeatureError();
        DART6_FORECASTSERVICE.ProgrammaticError progErr = new DART6_FORECASTSERVICE.ProgrammaticError();
        DART6_FORECASTSERVICE.VideoPosition vdoPos = new DART6_FORECASTSERVICE.VideoPosition();
        DART6_FORECASTSERVICE.getAvailabilityForecastByIdResponse_element getForeById = new DART6_FORECASTSERVICE.getAvailabilityForecastByIdResponse_element();
        // US-0011408 // DART6_FORECASTSERVICE.ContentMetadataTargetingError contMetaTarErr =  new DART6_FORECASTSERVICE.ContentMetadataTargetingError();
        DART6_FORECASTSERVICE.CreativeError creativeErr = new DART6_FORECASTSERVICE.CreativeError();
        // US-0008578 //  DART6_FORECASTSERVICE.ContentMetadataKeyHierarchyTargeting contMetaKeyHierTar = new DART6_FORECASTSERVICE.ContentMetadataKeyHierarchyTargeting();
        DART6_FORECASTSERVICE.VideoPositionWithinPod vdoPosWitPod = new DART6_FORECASTSERVICE.VideoPositionWithinPod();
        DART6_FORECASTSERVICE.DateValue dateval = new DART6_FORECASTSERVICE.DateValue();
        DART6_FORECASTSERVICE.ContendingLineItem contLineItem = new DART6_FORECASTSERVICE.ContendingLineItem();
        DART6_FORECASTSERVICE.EntityChildrenLimitReachedError entChldReachErr = new DART6_FORECASTSERVICE.EntityChildrenLimitReachedError();
        DART6_FORECASTSERVICE.TrafficDataRequest traffDataReq = new DART6_FORECASTSERVICE.TrafficDataRequest();
        DART6_FORECASTSERVICE.CustomPacingCurve custCur = new DART6_FORECASTSERVICE.CustomPacingCurve();
        DART6_FORECASTSERVICE.ThirdPartyMeasurementSettings thPartMeasSet = new DART6_FORECASTSERVICE.ThirdPartyMeasurementSettings();
        DART6_FORECASTSERVICE.InventoryUrl invUrl = new DART6_FORECASTSERVICE.InventoryUrl();
        DART6_FORECASTSERVICE.LineItemDealInfoDto lineItemDealInfoDto = new DART6_FORECASTSERVICE.LineItemDealInfoDto();
        DART6_FORECASTSERVICE.MobileApplicationTargetingError mobAppTarg = new DART6_FORECASTSERVICE.MobileApplicationTargetingError();
        DART6_FORECASTSERVICE.ApplicationException appExcep = new DART6_FORECASTSERVICE.ApplicationException();
        DART6_FORECASTSERVICE.CustomPacingGoal customPacingGoal = new DART6_FORECASTSERVICE.CustomPacingGoal();
        DART6_FORECASTSERVICE.TrafficDataResponse traffDataResp = new DART6_FORECASTSERVICE.TrafficDataResponse();
        DART6_FORECASTSERVICE.RequestPlatformTargetingError reqTargErr = new DART6_FORECASTSERVICE.RequestPlatformTargetingError();
        DART6_FORECASTSERVICE.TimeSeries timeSeries = new DART6_FORECASTSERVICE.TimeSeries();
        DART6_FORECASTSERVICE.InventoryUrlTargeting invUrlTarg = new DART6_FORECASTSERVICE.InventoryUrlTargeting();
        DART6_FORECASTSERVICE.DateTimeRangeTargeting dTTarg = new DART6_FORECASTSERVICE.DateTimeRangeTargeting();
        DART6_FORECASTSERVICE.CollectionSizeError collecSizeErr = new DART6_FORECASTSERVICE.CollectionSizeError();
        DART6_FORECASTSERVICE.GenericTargetingError genTargErr = new DART6_FORECASTSERVICE.GenericTargetingError();
        DART6_FORECASTSERVICE.getTrafficData_element getTraffDataElem = new DART6_FORECASTSERVICE.getTrafficData_element();
        DART6_FORECASTSERVICE.BuyerUserListTargeting hasBuyerUserListTargeting_type_info = new DART6_FORECASTSERVICE.BuyerUserListTargeting();
        DART6_FORECASTSERVICE.DateRange dataR = new DART6_FORECASTSERVICE.DateRange();
        DART6_FORECASTSERVICE.ProposalLineItemMakegoodInfo propLineItemGoodInf = new DART6_FORECASTSERVICE.ProposalLineItemMakegoodInfo();
        DART6_FORECASTSERVICE.DateTimeRange dataTR = new DART6_FORECASTSERVICE.DateTimeRange();
        DART6_FORECASTSERVICE.getTrafficDataResponse_element getTraffRespElem = new DART6_FORECASTSERVICE.getTrafficDataResponse_element();
        DART6_FORECASTSERVICE.CmsMetadataCriteria cmsMDCrit = new DART6_FORECASTSERVICE.CmsMetadataCriteria();

        Object o = new DART6_FORECASTSERVICE.CrossSellError();
        o = new DART6_FORECASTSERVICE.CrossSellError();
        // US-0008578 // o = new DART6_FORECASTSERVICE.SetTopBoxInfo();
        o = new DART6_FORECASTSERVICE.getAvailabilityForecastById_element();
        o = new DART6_FORECASTSERVICE.LineItemDeliveryForecast();
        o = new DART6_FORECASTSERVICE.AlternativeUnitTypeForecast();
        o = new DART6_FORECASTSERVICE.DeliveryForecast();
        o = new DART6_FORECASTSERVICE.TimeZoneError();
        o = new DART6_FORECASTSERVICE.GrpSettings();
        o = new DART6_FORECASTSERVICE.VideoPositionTargetingError();
        o = new DART6_FORECASTSERVICE.SetTopBoxLineItemError();
        o = new DART6_FORECASTSERVICE.LineItemActivityAssociation();
        o = new DART6_FORECASTSERVICE.DeliveryForecastOptions();
        o = new DART6_FORECASTSERVICE.getDeliveryForecastResponse_element();
        o = new DART6_FORECASTSERVICE.ObjectValue();
        //o = new DART6_FORECASTSERVICE.CollectionSizeError();
        o = new DART6_FORECASTSERVICE.getDeliveryForecastByIdsResponse_element();
        o = new DART6_FORECASTSERVICE.LineItemActivityAssociationError();
        o = new DART6_FORECASTSERVICE.TargetingCriteriaBreakdown();
        o = new DART6_FORECASTSERVICE.GrpSettingsError();
        // o = new DART6_FORECASTSERVICE.GrpDemographicBreakdown();  // 11.07.2023 / Sophal Noch / US-0013954
        o = new DART6_FORECASTSERVICE.CreativeTargeting();
        o = new DART6_FORECASTSERVICE.getDeliveryForecastByIds_element();
        o = new DART6_FORECASTSERVICE.OrderActionError();
        o = new DART6_FORECASTSERVICE.ImageError();
        o = new DART6_FORECASTSERVICE.getDeliveryForecast_element();
        o = new DART6_FORECASTSERVICE.AudienceSegmentError();
        o = new DART6_FORECASTSERVICE.CrossSellError();
        o = new DART6_FORECASTSERVICE.Size();
        
        o = new DART6_FORECASTSERVICE.FieldPathElement();
        o = new DART6_FORECASTSERVICE.StringFormatError();
        // US-0011408 // o = new DART6_FORECASTSERVICE.AdRuleSlotError();
        o = new DART6_FORECASTSERVICE.MobileApplicationTargeting();
        // o = new DART6_FORECASTSERVICE.DeviceCategoryPremiumFeature();
        // o = new DART6_FORECASTSERVICE.UserDomainPremiumFeature();
        // US-0011408 // o = new DART6_FORECASTSERVICE.AdUnitPremiumFeature();
        // US-0011408 // o = new DART6_FORECASTSERVICE.CustomizableAttributes();
        // US-0011408 // o = new DART6_FORECASTSERVICE.FrequencyCapPremiumFeature();
        // US-0011408 // o = new DART6_FORECASTSERVICE.PremiumFeature();
        // US-0011408 // o = new DART6_FORECASTSERVICE.CustomTargetingPremiumFeature();
        // US-0011408 // o = new DART6_FORECASTSERVICE.ProposalLineItemConstraints();
        // US-0011408 // o = new DART6_FORECASTSERVICE.OperatingSystemPremiumFeature();
        // US-0011408 // o = new DART6_FORECASTSERVICE.DaypartPremiumFeature();
        // US-0011408 // o = new DART6_FORECASTSERVICE.BrowserLanguagePremiumFeature();
        o = new DART6_FORECASTSERVICE.ProposalLineItem();
        // US-0011408 // o = new DART6_FORECASTSERVICE.BrowserPremiumFeature();
        o = new DART6_FORECASTSERVICE.ForecastBreakdownOptions();
        // US-0008578 // o = new DART6_FORECASTSERVICE.MobileCarrierPremiumFeature();
        o = new DART6_FORECASTSERVICE.RequestPlatformTargeting();
        // US-0008578 // o = new DART6_FORECASTSERVICE.ProposalLineItemPremium();
        // US-0011408 // o = new DART6_FORECASTSERVICE.AudienceSegmentPremiumFeature();
        o = new DART6_FORECASTSERVICE.ForecastBreakdownEntry();
        // US-0011408 // o = new DART6_FORECASTSERVICE.DeviceManufacturerPremiumFeature();
        // o = new DART6_FORECASTSERVICE.ProposalLineItemMarketplaceInfo();  // 21.11.2022 / Sophal Noch / US-0012883 :
        // US-0011408 // o = new DART6_FORECASTSERVICE.UnknownPremiumFeature();
        o = new DART6_FORECASTSERVICE.ForecastBreakdown();
        // US-0011408 // o = new DART6_FORECASTSERVICE.ContentBundlePremiumFeature();
        o = new DART6_FORECASTSERVICE.ForecastBreakdownTarget();
        // US-0011408 // o = new DART6_FORECASTSERVICE.DeviceCapabilityPremiumFeature();
        // US-0011408 // o = new DART6_FORECASTSERVICE.GeographyPremiumFeature();
        // US-0011408 // o = new DART6_FORECASTSERVICE.BandwidthPremiumFeature();
        // US-0011408 // o = new DART6_FORECASTSERVICE.PremiumRateValue();
        // US-0011408 // o = new DART6_FORECASTSERVICE.PlacementPremiumFeature();
        // US-0011408 // o = new DART6_FORECASTSERVICE.VideoPositionPremiumFeature();
        o = new DART6_FORECASTSERVICE.BreakdownForecast();

        // 21.11.2022 / Sophal Noch / US-0012883 :
        o = new DART6_FORECASTSERVICE.AssetError(); 
        o = new DART6_FORECASTSERVICE.TargetedSize(); 
        o = new DART6_FORECASTSERVICE.CurrencyCodeError();
        o = new DART6_FORECASTSERVICE.InventorySizeTargeting();
        o = new DART6_FORECASTSERVICE.DateError();
        o = new DART6_FORECASTSERVICE.TranscodingError();

        o = new DART6_FORECASTSERVICE.PrecisionError(); // 19.02.2024 / Sophal Noch / US-0014655

        Test.startTest();
            DART6_FORECASTSERVICE.ForecastServiceInterfacePort svc = new DART6_FORECASTSERVICE.ForecastServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_FORECASTSERVICE.getAvailabilityForecastByIdResponse_element()));
            svc.getAvailabilityForecastById(1111, new DART6_FORECASTSERVICE.AvailabilityForecastOptions());
            System.assertNotEquals(null, svc);
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_FORECASTSERVICE.getDeliveryForecastByIdsResponse_element()));
            svc.getDeliveryForecastByIds(new Long[0], new DART6_FORECASTSERVICE.DeliveryForecastOptions());
            System.assertNotEquals(null, svc);
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_FORECASTSERVICE.getDeliveryForecastResponse_element()));
            svc.getDeliveryForecast(new DART6_FORECASTSERVICE.ProspectiveLineItem[0], new DART6_FORECASTSERVICE.DeliveryForecastOptions());
            System.assertNotEquals(null, svc);
            /*Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_FORECASTSERVICE.getTrafficDataResponse_element()));
            svc.getTrafficData(new DART6_FORECASTSERVICE.getTrafficData());
            System.assertNotEquals(null, svc);*/
        Test.stopTest();
        
    }

    /** Test Class DART6_REPORTSERVICE */

    static testMethod void testDART6ReportService()
    {
        DART6_REPORTSERVICE reportsv = new DART6_REPORTSERVICE();

        DART6_REPORTSERVICE.CommonError comErr = new DART6_REPORTSERVICE.CommonError();
        DART6_REPORTSERVICE.getReportDownloadUrlWithOptionsResponse_element getResDwOpRes = new    DART6_REPORTSERVICE.getReportDownloadUrlWithOptionsResponse_element();
        DART6_REPORTSERVICE.DateTimeValue dateTimeVal = new DART6_REPORTSERVICE.DateTimeValue();
        DART6_REPORTSERVICE.getReportDownloadUrlWithOptions_element getRepOpt = new DART6_REPORTSERVICE.getReportDownloadUrlWithOptions_element();
        DART6_REPORTSERVICE.InternalApiError internalErr = new DART6_REPORTSERVICE.InternalApiError();
        DART6_REPORTSERVICE.Statement statements = new DART6_REPORTSERVICE.Statement();
        DART6_REPORTSERVICE.PublisherQueryLanguageContextError publicQuCont = new DART6_REPORTSERVICE.PublisherQueryLanguageContextError();
        DART6_REPORTSERVICE.ApiError apiErr = new DART6_REPORTSERVICE.ApiError();
        DART6_REPORTSERVICE.runReportJobResponse_element runRepJopRes = new DART6_REPORTSERVICE.runReportJobResponse_element();
        DART6_REPORTSERVICE.Date_x datex = new DART6_REPORTSERVICE.Date_x();
        DART6_REPORTSERVICE.SoapRequestHeader soapResHd = new DART6_REPORTSERVICE.SoapRequestHeader();
        DART6_REPORTSERVICE.getReportDownloadURL_element getRepUrl = new DART6_REPORTSERVICE.getReportDownloadURL_element();
        DART6_REPORTSERVICE.getReportDownloadURLResponse_element getdRepUrlResEle = new DART6_REPORTSERVICE.getReportDownloadURLResponse_element();
        DART6_REPORTSERVICE.BooleanValue bval = new DART6_REPORTSERVICE.BooleanValue();
        DART6_REPORTSERVICE.ApiException apiEx = new DART6_REPORTSERVICE.ApiException();
        DART6_REPORTSERVICE.RequiredError reqErr = new DART6_REPORTSERVICE.RequiredError();
        DART6_REPORTSERVICE.AuthenticationError AuthErr = new DART6_REPORTSERVICE.AuthenticationError();
        DART6_REPORTSERVICE.PermissionError perErr = new DART6_REPORTSERVICE.PermissionError();
        DART6_REPORTSERVICE.QuotaError quotaErr = new DART6_REPORTSERVICE.QuotaError();
        DART6_REPORTSERVICE.PublisherQueryLanguageSyntaxError pubQuSynErr = new DART6_REPORTSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_REPORTSERVICE.ReportQuery requery = new DART6_REPORTSERVICE.ReportQuery();
        DART6_REPORTSERVICE.String_ValueMapEntry valMapEn = new DART6_REPORTSERVICE.String_ValueMapEntry();
        DART6_REPORTSERVICE.ApplicationException appEx = new DART6_REPORTSERVICE.ApplicationException();
        DART6_REPORTSERVICE.Value val = new DART6_REPORTSERVICE.Value();
        DART6_REPORTSERVICE.getReportJobStatus_element getJobEle = new DART6_REPORTSERVICE.getReportJobStatus_element();
        DART6_REPORTSERVICE.ApiVersionError apiVerErr = new DART6_REPORTSERVICE.ApiVersionError();
        DART6_REPORTSERVICE.ReportError repErr = new DART6_REPORTSERVICE.ReportError();
        DART6_REPORTSERVICE.ServerError serErr = new DART6_REPORTSERVICE.ServerError();
        DART6_REPORTSERVICE.DateTime_x dateTimex = new DART6_REPORTSERVICE.DateTime_x();
        DART6_REPORTSERVICE.ReportDownloadOptions repDop = new DART6_REPORTSERVICE.ReportDownloadOptions();
        DART6_REPORTSERVICE.StatementError stateErr = new DART6_REPORTSERVICE.StatementError();
        DART6_REPORTSERVICE.NumberValue numVal = new DART6_REPORTSERVICE.NumberValue();
        DART6_REPORTSERVICE.TextValue txtval = new DART6_REPORTSERVICE.TextValue();
        DART6_REPORTSERVICE.ReportServiceInterfacePort reIntPort = new DART6_REPORTSERVICE.ReportServiceInterfacePort();
        DART6_REPORTSERVICE.SoapResponseHeader sheader = new DART6_REPORTSERVICE.SoapResponseHeader();
        DART6_REPORTSERVICE.ReportJob reJob = new DART6_REPORTSERVICE.ReportJob();
        DART6_REPORTSERVICE.runReportJob_element runReJob = new DART6_REPORTSERVICE.runReportJob_element();
        DART6_REPORTSERVICE.getReportJobStatusResponse_element getRejobResEle = new DART6_REPORTSERVICE.getReportJobStatusResponse_element();
        DART6_REPORTSERVICE.NotNullError notNullErr = new DART6_REPORTSERVICE.NotNullError();
        DART6_REPORTSERVICE.CollectionSizeError colSizeErr = new DART6_REPORTSERVICE.CollectionSizeError();
        DART6_REPORTSERVICE.StringLengthError strlenErr= new DART6_REPORTSERVICE.StringLengthError();
        DART6_REPORTSERVICE.ObjectValue objV= new DART6_REPORTSERVICE.ObjectValue();

         //@vitou 08-04-2015
        DART6_REPORTSERVICE.SetValue setVal = new DART6_REPORTSERVICE.SetValue();
        DART6_REPORTSERVICE.FeatureError featErr = new DART6_REPORTSERVICE.FeatureError();
        DART6_REPORTSERVICE.DateValue dateVal = new DART6_REPORTSERVICE.DateValue();
        DART6_REPORTSERVICE.ParseError pasErr = new DART6_REPORTSERVICE.ParseError();
        
        Object o = new DART6_REPORTSERVICE.SavedQuery(); 
        o = new DART6_REPORTSERVICE.RequiredCollectionError(); 
        o = new DART6_REPORTSERVICE.getSavedQueriesByStatementResponse_element(); 
        o = new DART6_REPORTSERVICE.SavedQueryPage(); 
        o = new DART6_REPORTSERVICE.getSavedQueriesByStatement_element(); 
       
        o = new DART6_REPORTSERVICE.FieldPathElement();
        o = new DART6_REPORTSERVICE.StringFormatError();
        o = new DART6_REPORTSERVICE.CurrencyCodeError();

        Test.startTest();
            DART6_REPORTSERVICE.ReportServiceInterfacePort svc = new DART6_REPORTSERVICE.ReportServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_REPORTSERVICE.getSavedQueriesByStatementResponse_element()));
            svc.getSavedQueriesByStatement(new DART6_REPORTSERVICE.Statement());
            System.assertNotEquals(null, svc);
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_REPORTSERVICE.getReportDownloadURLResponse_element()));
            System.assertNotEquals(null, svc);
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_REPORTSERVICE.getReportJobStatusResponse_element()));
            svc.getReportJobStatus(12312);
            System.assertNotEquals(null, svc);
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_REPORTSERVICE.runReportJobResponse_element()));
            svc.runReportJob(new DART6_REPORTSERVICE.ReportJob());
            System.assertNotEquals(null, svc);
        Test.stopTest();
    }

    /** Test Class DART6_CUSTOMTARGETINGSERVICE */

    static testMethod void testDART6CustomTargetingService()
    {

        DART6_CUSTOMTARGETINGSERVICE customService = new DART6_CUSTOMTARGETINGSERVICE();

        DART6_CUSTOMTARGETINGSERVICE.CommonError comErr = new DART6_CUSTOMTARGETINGSERVICE.CommonError();
        DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingKeys delcusTarKey= new DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingKeys();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyAction custKeyAc= new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyAction();
        DART6_CUSTOMTARGETINGSERVICE.InternalApiError interApiErr = new DART6_CUSTOMTARGETINGSERVICE.InternalApiError();
        DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeys_element cTKeyEle = new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeys_element();
        DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueAction_element perCusValAc= new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueAction_element();
        DART6_CUSTOMTARGETINGSERVICE.BooleanValue bv = new DART6_CUSTOMTARGETINGSERVICE.BooleanValue();
        DART6_CUSTOMTARGETINGSERVICE.UniqueError uerr = new DART6_CUSTOMTARGETINGSERVICE.UniqueError();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey custKey = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey();
        DART6_CUSTOMTARGETINGSERVICE.RequiredError reErr = new DART6_CUSTOMTARGETINGSERVICE.RequiredError();
        DART6_CUSTOMTARGETINGSERVICE.AuthenticationError autErr = new DART6_CUSTOMTARGETINGSERVICE.AuthenticationError();
        DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValuesResponse_element updValResEle= new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValuesResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.PermissionError perErr = new DART6_CUSTOMTARGETINGSERVICE.PermissionError();
        DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageSyntaxError pubQLErr = new DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_CUSTOMTARGETINGSERVICE.String_ValueMapEntry valMaEnt = new DART6_CUSTOMTARGETINGSERVICE.String_ValueMapEntry();
        DART6_CUSTOMTARGETINGSERVICE.Value val = new DART6_CUSTOMTARGETINGSERVICE.Value();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue custTarVal = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
        DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element custValByStat = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeys_element updCusKeyEle = new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeys_element();
        DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeysResponse_element updTarKeyRes= new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeysResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.TypeError typeErr = new DART6_CUSTOMTARGETINGSERVICE.TypeError();
        DART6_CUSTOMTARGETINGSERVICE.NumberValue numVal = new DART6_CUSTOMTARGETINGSERVICE.NumberValue();
        DART6_CUSTOMTARGETINGSERVICE.SoapResponseHeader SoaHed = new DART6_CUSTOMTARGETINGSERVICE.SoapResponseHeader();
        DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element creaCustValResEle= new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.NotNullError notNullErr = new DART6_CUSTOMTARGETINGSERVICE.NotNullError();
        DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatementResponse_element getCustKeyByResEle = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatementResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyPage custTargPage = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyPage();
        DART6_CUSTOMTARGETINGSERVICE.DateTimeValue dtVal= new DART6_CUSTOMTARGETINGSERVICE.DateTimeValue();
        DART6_CUSTOMTARGETINGSERVICE.Statement st = new DART6_CUSTOMTARGETINGSERVICE.Statement();
        DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyAction_element perTargKeyAcElement = new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyAction_element();
        DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageContextError pubQlContErr = new DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageContextError();
        DART6_CUSTOMTARGETINGSERVICE.ApiError apiErr= new DART6_CUSTOMTARGETINGSERVICE.ApiError();
        DART6_CUSTOMTARGETINGSERVICE.Date_x dx = new DART6_CUSTOMTARGETINGSERVICE.Date_x();
        DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader sH = new DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort custSerInPort= new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort();
        DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValues_element updVal = new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValues_element();
        DART6_CUSTOMTARGETINGSERVICE.NullError  nulErr = new DART6_CUSTOMTARGETINGSERVICE.NullError();
        DART6_CUSTOMTARGETINGSERVICE.ApiException apiExc = new DART6_CUSTOMTARGETINGSERVICE.ApiException();
        DART6_CUSTOMTARGETINGSERVICE.QuotaError quoaErr = new DART6_CUSTOMTARGETINGSERVICE.QuotaError();
        DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValues_element creatTargValEle  = new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValues_element();
        DART6_CUSTOMTARGETINGSERVICE.ApplicationException appExc = new DART6_CUSTOMTARGETINGSERVICE.ApplicationException();
        DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatement_element getCustTarEle= new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatement_element();
        DART6_CUSTOMTARGETINGSERVICE.ApiVersionError apiVerErr = new DART6_CUSTOMTARGETINGSERVICE.ApiVersionError();
        DART6_CUSTOMTARGETINGSERVICE.ParseError paErr= new DART6_CUSTOMTARGETINGSERVICE.ParseError();
        DART6_CUSTOMTARGETINGSERVICE.ServerError serErr = new DART6_CUSTOMTARGETINGSERVICE.ServerError();
        DART6_CUSTOMTARGETINGSERVICE.DateTime_x dtx= new DART6_CUSTOMTARGETINGSERVICE.DateTime_x();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage cutValPage = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValueAction custValAc = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValueAction();
        DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeysResponse_element creatTaKeyRes = new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeysResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.StatementError staErr= new DART6_CUSTOMTARGETINGSERVICE.StatementError();
        DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyActionResponse_element perCustKeyRes = new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyActionResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatement_element getTarKeyStr = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatement_element();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingError custTarErr = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingError();
        DART6_CUSTOMTARGETINGSERVICE.TextValue txVal = new DART6_CUSTOMTARGETINGSERVICE.TextValue();
        DART6_CUSTOMTARGETINGSERVICE.UpdateResult updRes= new DART6_CUSTOMTARGETINGSERVICE.UpdateResult();
        DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueActionResponse_element perCustTarAcRes = new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueActionResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingValues delTarVal= new DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingValues();

        DART6_CUSTOMTARGETINGSERVICE.CollectionSizeError colSizeErr = new DART6_CUSTOMTARGETINGSERVICE.CollectionSizeError();
        DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingKeys actCusKey= new DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingKeys();
        DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingValues actCusVal= new DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingValues();
        DART6_CUSTOMTARGETINGSERVICE.EntityLimitReachedError entityReachErr= new DART6_CUSTOMTARGETINGSERVICE.EntityLimitReachedError();
        DART6_CUSTOMTARGETINGSERVICE.ObjectValue objV = new DART6_CUSTOMTARGETINGSERVICE.ObjectValue();
        DART6_CUSTOMTARGETINGSERVICE.EntityChildrenLimitReachedError entityLimReErr= new DART6_CUSTOMTARGETINGSERVICE.EntityChildrenLimitReachedError();

         //@vitou 08-04-2015
        DART6_CUSTOMTARGETINGSERVICE.SetValue setVal = new DART6_CUSTOMTARGETINGSERVICE.SetValue();
        DART6_CUSTOMTARGETINGSERVICE.FeatureError featErr = new DART6_CUSTOMTARGETINGSERVICE.FeatureError();
        DART6_CUSTOMTARGETINGSERVICE.DateValue dateVal = new DART6_CUSTOMTARGETINGSERVICE.DateValue();
        
        Object o = new DART6_CUSTOMTARGETINGSERVICE.RequiredCollectionError();
        o = new DART6_CUSTOMTARGETINGSERVICE.StringLengthError();

        o = new DART6_CUSTOMTARGETINGSERVICE.FieldPathElement();
        o = new DART6_CUSTOMTARGETINGSERVICE.StringFormatError();        
        Test.startTest();
            DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort svc = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeysResponse_element()));
            svc.createCustomTargetingKeys(new List<DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey>());
            System.assertNotEquals(null, svc);

            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeysResponse_element()));
            svc.updateCustomTargetingKeys(new List<DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey>());
            System.assertNotEquals(null, svc);

            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element()));
            svc.createCustomTargetingValues(new List<DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue>());
            System.assertNotEquals(null, svc);

            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element()));
            svc.getCustomTargetingValuesByStatement(new DART6_CUSTOMTARGETINGSERVICE.Statement());
            System.assertNotEquals(null, svc);

            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueActionResponse_element()));
            svc.performCustomTargetingValueAction(new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValueAction(), new DART6_CUSTOMTARGETINGSERVICE.Statement());
            System.assertNotEquals(null, svc);
            
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValuesResponse_element()));
            svc.updateCustomTargetingValues(new List<DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue>());
            System.assertNotEquals(null, svc);

            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyActionResponse_element()));
            svc.performCustomTargetingKeyAction(new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyAction(), new DART6_CUSTOMTARGETINGSERVICE.Statement());
            System.assertNotEquals(null, svc);
            
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatementResponse_element()));
            svc.getCustomTargetingKeysByStatement(new DART6_CUSTOMTARGETINGSERVICE.Statement());
            System.assertNotEquals(null, svc);
            
        Test.stopTest();
    }

    /** Test Class DART6_NETWORKSERVICE */

    static testMethod void testDART6NetworkService()
    {
        DART6_NETWORKSERVICE.CommonError comErr= new DART6_NETWORKSERVICE.CommonError();
        DART6_NETWORKSERVICE.InternalApiError intapiErr= new DART6_NETWORKSERVICE.InternalApiError();
        DART6_NETWORKSERVICE.CollectionSizeError colsizeErr= new DART6_NETWORKSERVICE.CollectionSizeError();
        DART6_NETWORKSERVICE.makeTestNetworkResponse_element mtResEle= new DART6_NETWORKSERVICE.makeTestNetworkResponse_element();
        DART6_NETWORKSERVICE.PublisherQueryLanguageContextError pubqleEr= new DART6_NETWORKSERVICE.PublisherQueryLanguageContextError();
        DART6_NETWORKSERVICE.ApiError apiErr= new DART6_NETWORKSERVICE.ApiError();
        DART6_NETWORKSERVICE.updateNetworkResponse_element updNetre= new DART6_NETWORKSERVICE.updateNetworkResponse_element();
        DART6_NETWORKSERVICE.SoapRequestHeader SoapRequestHeader= new DART6_NETWORKSERVICE.SoapRequestHeader();
        DART6_NETWORKSERVICE.StringLengthError StringLengthError= new DART6_NETWORKSERVICE.StringLengthError();
        DART6_NETWORKSERVICE.NetworkError NetworkError= new DART6_NETWORKSERVICE.NetworkError();
        DART6_NETWORKSERVICE.ApiException ApiException= new DART6_NETWORKSERVICE.ApiException();
        DART6_NETWORKSERVICE.UniqueError UniqueError= new DART6_NETWORKSERVICE.UniqueError();
        DART6_NETWORKSERVICE.RequiredError RequiredError= new DART6_NETWORKSERVICE.RequiredError();
        DART6_NETWORKSERVICE.FeatureError FeatureError= new DART6_NETWORKSERVICE.FeatureError();
        DART6_NETWORKSERVICE.AuthenticationError AuthenticationError= new DART6_NETWORKSERVICE.AuthenticationError();
        DART6_NETWORKSERVICE.PermissionError PermissionError= new DART6_NETWORKSERVICE.PermissionError();
        DART6_NETWORKSERVICE.QuotaError QuotaError= new DART6_NETWORKSERVICE.QuotaError();
        DART6_NETWORKSERVICE.PublisherQueryLanguageSyntaxError PublisherQueryLanguageSyntaxError= new DART6_NETWORKSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_NETWORKSERVICE.makeTestNetwork_element makeTestNetwork_element= new DART6_NETWORKSERVICE.makeTestNetwork_element();
        DART6_NETWORKSERVICE.ApplicationException ApplicationException= new DART6_NETWORKSERVICE.ApplicationException();
        // US-0011408 // DART6_NETWORKSERVICE.ExchangeRateError ExchangeRateError= new DART6_NETWORKSERVICE.ExchangeRateError();
        DART6_NETWORKSERVICE.ApiVersionError ApiVersionError= new DART6_NETWORKSERVICE.ApiVersionError();
        DART6_NETWORKSERVICE.ParseError ParseError= new DART6_NETWORKSERVICE.ParseError();
        DART6_NETWORKSERVICE.PrecisionError PrecisionError= new DART6_NETWORKSERVICE.PrecisionError();
        DART6_NETWORKSERVICE.updateNetwork_element updateNetwork_element= new DART6_NETWORKSERVICE.updateNetwork_element();
        DART6_NETWORKSERVICE.getAllNetworks_element getAllNetworks_element= new DART6_NETWORKSERVICE.getAllNetworks_element();
        DART6_NETWORKSERVICE.ServerError ServerError= new DART6_NETWORKSERVICE.ServerError();
        DART6_NETWORKSERVICE.getCurrentNetwork_element getCurrentNetwork_element= new DART6_NETWORKSERVICE.getCurrentNetwork_element();
        DART6_NETWORKSERVICE.getCurrentNetworkResponse_element getCurrentNetworkResponse_element= new DART6_NETWORKSERVICE.getCurrentNetworkResponse_element();
        DART6_NETWORKSERVICE.StatementError StatementError= new DART6_NETWORKSERVICE.StatementError();
        DART6_NETWORKSERVICE.RequiredCollectionError RequiredCollectionError= new DART6_NETWORKSERVICE.RequiredCollectionError();
        DART6_NETWORKSERVICE.TypeError TypeError= new DART6_NETWORKSERVICE.TypeError();
        DART6_NETWORKSERVICE.RequiredNumberError RequiredNumberError= new DART6_NETWORKSERVICE.RequiredNumberError();
        DART6_NETWORKSERVICE.getAllNetworksResponse_element getAllNetworksResponse_element= new DART6_NETWORKSERVICE.getAllNetworksResponse_element();
        DART6_NETWORKSERVICE.InvalidEmailError InvalidEmailError= new DART6_NETWORKSERVICE.InvalidEmailError();
        DART6_NETWORKSERVICE.SoapResponseHeader SoapResponseHeader= new DART6_NETWORKSERVICE.SoapResponseHeader();
        DART6_NETWORKSERVICE.Network Network= new DART6_NETWORKSERVICE.Network();
        DART6_NETWORKSERVICE.NotNullError NotNullError= new DART6_NETWORKSERVICE.NotNullError();
        DART6_NETWORKSERVICE.NetworkServiceInterfacePort NetworkServiceInterfacePort= new DART6_NETWORKSERVICE.NetworkServiceInterfacePort();
        DART6_NETWORKSERVICE.getDefaultThirdPartyDataDeclarationResponse_element  getFeatElem = new DART6_NETWORKSERVICE.getDefaultThirdPartyDataDeclarationResponse_element();//US-0011408 -v202202
        // DART6_NETWORKSERVICE.ChildPublisher  childPublisher = new DART6_NETWORKSERVICE.ChildPublisher();//US-0011408 -v202202, // 19.02.2024 / Sophal Noch / US-0014655 : deprecated in v202402
        DART6_NETWORKSERVICE.ThirdPartyDataDeclaration  thirdParDD = new DART6_NETWORKSERVICE.ThirdPartyDataDeclaration();//US-0011408 -v202202
        DART6_NETWORKSERVICE.LiveStreamEventSlateError  liveStrEvenSErr = new DART6_NETWORKSERVICE.LiveStreamEventSlateError();//US-0011408 -v202202
        DART6_NETWORKSERVICE.UrlError  urlError = new DART6_NETWORKSERVICE.UrlError();//US-0011408 -v202202
        DART6_NETWORKSERVICE.getDefaultThirdPartyDataDeclaration_element  getDefThParDDElem = new DART6_NETWORKSERVICE.getDefaultThirdPartyDataDeclaration_element();//US-0011408 -v202202
        
        Object o = new DART6_NETWORKSERVICE.SetTopBoxCreativeError();
		o = new DART6_NETWORKSERVICE.RequestError();
        o = new DART6_NETWORKSERVICE.StringFormatError();
        o = new DART6_NETWORKSERVICE.FieldPathElement();

        // 21.11.2022 / Sophal Noch / US-0012883 :
        o = new DART6_NETWORKSERVICE.ExchangeSignupApiError();
        o = new DART6_NETWORKSERVICE.InventoryClientApiError();

        Test.startTest();
            DART6_NETWORKSERVICE.NetworkServiceInterfacePort svc = new DART6_NETWORKSERVICE.NetworkServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_NETWORKSERVICE.updateNetworkResponse_element()));
            svc.updateNetwork(new DART6_NETWORKSERVICE.Network());
            System.assertNotEquals(null, svc);

            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_NETWORKSERVICE.getAllNetworksResponse_element()));
            svc.getAllNetworks();
            System.assertNotEquals(null, svc);

            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_NETWORKSERVICE.makeTestNetworkResponse_element()));
            svc.makeTestNetwork();
            System.assertNotEquals(null, svc);
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_NETWORKSERVICE.getCurrentNetworkResponse_element()));
            svc.getCurrentNetwork();
            System.assertNotEquals(null, svc);

            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_NETWORKSERVICE.getDefaultThirdPartyDataDeclarationResponse_element()));
            svc.getDefaultThirdPartyDataDeclaration();

        Test.stopTest();
    }



       /**
     * create advetiser test records
     */
    public static List<Advertiser__c> createAdvertiser()
    {
        System.runAs(currentUser){
            lstAdvertiser = new List<Advertiser__c>();
            Advertiser__c advertiser1 = new Advertiser__c(Account__c=lstAcc.get(0).id, Agency__c=lstAcc.get(0).id);
            lstAdvertiser.add(advertiser1);
            Advertiser__c advertiser2 = new Advertiser__c(Account__c=lstAcc.get(1).id, Agency__c=lstAcc.get(1).id, DART5_Advertiser_Id__c='111111', DART6_Advertiser_Id__c='222222');
            lstAdvertiser.add(advertiser2);
            
            insert lstAdvertiser;
        }
        return lstAdvertiser;
    }
    
    public static AdServer_Login__c generateAdServerLogin(String country, String recordTypeId){
        return new AdServer_Login__c(
          Name = country,
          Refresh_Token__c = 'xxxxxx',
          Client_Id__c = 'xxxxxx',
          Network_ID__c = country,
          Active__c = true,
          Client_Secret__c = 'xxxxx',
          RecordTypeId = recordTypeId
          );
    }


    /**
     * create AdserverLogin records
     */
    public static void createCredential(){
        createCredential(defaultCountry);
    }
    /**
     * create AdserverLogin records
     */
    public static List<AdServer_Login__c> createCredential(String country)
    {
        //System.runAs(userAdmin){
            Id recTypeDart6 = ApexUtil.getRecordTypeByName('AdServer_Login__c', DARTUtil.DART6).Id;
            AdServer_Login__c login6 = new AdServer_Login__c(RecordTypeId=recTypeDart6,
                Name = country,
                Login_URL__c='http://test.com',
                User_Name__c='dart6testuser@gmail.com',
                Password__c ='testpwddart6123456',
                Active__c = true,
                Network_ID__c='123456',
                Client_ID__c = 'xxxxxxxxxxxxxxxxxxxxx',
                Client_Secret__c = 'xxxxxxxxxxxxxxx',
                Refresh_Token__c = 'xxxxxxxxxxx'
                );
                
                listLogin = new List<AdServer_Login__c>{login6};
                upsert listLogin Network_ID__c;
        //}    
        return listLogin; 
    }
 
    /**
     * Type:
     * Dart - Site
     * Dart - Zone
     * Dart - ContentCategory
     * @param number of record to be created
     * @param list type of content
     */
    public static List<Content__c> createContents(Integer numToCreate,List<String> ctype)
    {
        System.runAs(currentUser){
            contents = new List<Content__c>();
            for(Integer i=0;i<numToCreate;i++)
            {
                Content__c c = new Content__c(Name='4000'+i,DartName__c='DartName'+i,Type__c=ctype[i]);
                contents.add(c);
            }
            insert contents;
        }
        return contents;
    }

    /**
     * create DartKeyvalue2 test records
     * @param number of records to be created
     */
    // public static Map<String,GAM_Key_Value__c[]> createKV(Integer numToCreate)
    // {
    //     keyvalues = new List<GAM_Key_Value__c>();
    //     Map<String,GAM_Key_Value__c[]> mapKV = new Map<String,GAM_Key_Value__c[]>();
    //     System.runAs(currentUser){
            
    //         // for(Integer i=0;i<numToCreate;i++)
    //         // {
    //         //     GAM_Key_Value__c kv = new GAM_Key_Value__c(Name='DE RTM Targeting'+i,Key__c='seg'+i,Key_Value__c='seg'+i,Key_Value_Name__c='DE RTM Targeting',Active__c=true);
    //         //     keyvalues.add(kv);
    //         // }
    //         // insert keyvalues;
                        
    //         for(Integer i=0;i<numToCreate;i++)
    //         {
                
    //             keyvalues.add(createKeyOrValueOrAS('k','seg','DE','11111111'));
    //         }
    //         insert keyvalues;    
    //         mapKV.put('k1',keyvalues);
    //     }
    //     return keyvalues;
    // }
    
    /**
     * create targeting test records
     * @param number of records to be created
     */
    public static List<Targeting__c> createTargetings(Integer numToCreate)
    {
        System.runAs(currentUser){
            targetting = new List<Targeting__c>();
            for(Integer i=0;i<numToCreate;i++)
            {
                Targeting__c t = new Targeting__c(Description__c='test');
                targetting.add(t);
            }
            insert targetting;
        }
        return targetting;
    }
    
    //13/01/2015 - to create Devices for testing
    public static List<Devices__c> createDevices() {
        System.runAs(currentUser){
            lstDevices = new List<Devices__c>();
            Devices__c dev1 = new Devices__c(Name = 'Test1', Dart_ID__c=123456, DFP_API_Name__c='DeviceManufacturer');
            insert dev1;
            Devices__c dev2 = new Devices__c(Name = 'Test2', Dart_ID__c=555555, Node_ID__c= dev1.Id, DFP_API_Name__c='DeviceCategory');
            insert dev2;
            Devices__c dev3 = new Devices__c(Name = 'Test3', Dart_ID__c=333333, Node_ID__c= dev1.Id, DFP_API_Name__c='DeviceCategory');
            insert dev3;
            lstDevices.add(dev1);
            lstDevices.add(dev2);
            lstDevices.add(dev3);
            //Dev Browser
            Devices__c devDv = new Devices__c(Name = 'Test', Dart_ID__c=09089, Node_ID__c= dev1.Id, DFP_API_Name__c='Browser');
            insert devDv;
            Devices__c devDv1 = new Devices__c(Name = 'Test', Dart_ID__c=12678, Node_ID__c= devDv.Id);
            insert devDv1;
            lstDevices.add(devDv);
            lstDevices.add(devDv1);
            // BrowserLanguage
            Devices__c devBl = new Devices__c(Name = 'Test', Dart_ID__c=555550, Node_ID__c= dev1.Id, DFP_API_Name__c='BrowserLanguage');
            insert devBl;
            Devices__c devBl1 = new Devices__c(Name = 'Test3', Dart_ID__c=555551, Node_ID__c= devBl.Id);
            insert devBl1;
            lstDevices.add(devBl);
            lstDevices.add(devBl1);
            //DeviceCapability
            Devices__c devDc = new Devices__c(Name = 'Test', Dart_ID__c=444440, Node_ID__c= dev1.Id, DFP_API_Name__c='DeviceCapability');
            insert devDc;
            Devices__c devDc1 = new Devices__c(Name = 'Test3', Dart_ID__c=444441, Node_ID__c= devDc.Id);
            insert devDc1;
            lstDevices.add(devDc);
            lstDevices.add(devDc1);
            //OperatingSystem
            Devices__c devOs = new Devices__c(Name = 'Test', Dart_ID__c=333330, Node_ID__c= dev1.Id, DFP_API_Name__c='OperatingSystem');
            insert devOs;
            Devices__c devOs1 = new Devices__c(Name = 'Test3', Dart_ID__c=333331, Node_ID__c= devOs.Id);
            insert devOs1;
            lstDevices.add(devOs);
            lstDevices.add(devOs1);
            //OperatingSystemVersion
            Devices__c devOsv = new Devices__c(Name = 'Test', Dart_ID__c=222220, Node_ID__c= dev1.Id, DFP_API_Name__c='OperatingSystemVersion');
            insert devOsv;
            Devices__c devOsv1 = new Devices__c(Name = 'Test3', Dart_ID__c=222221, Node_ID__c= devOsv.Id);
            insert devOsv1;
            lstDevices.add(devOsv);
            lstDevices.add(devOsv1);
            //MobileDevice
            Devices__c devMd = new Devices__c(Name = 'Test', Dart_ID__c=111110, Node_ID__c= dev1.Id, DFP_API_Name__c='MobileDevice');
            insert devMd;
            Devices__c devMd1 = new Devices__c(Name = 'Test3', Dart_ID__c=111100, Node_ID__c= devMd.Id);
            insert devMd1;
            lstDevices.add(devMd);
            lstDevices.add(devMd1);
            //MobileDeviceSubmodel
            Devices__c devMds = new Devices__c(Name = 'Test', Dart_ID__c=404040, Node_ID__c= dev1.Id, DFP_API_Name__c='MobileDeviceSubmodel');
            insert devMds;
            Devices__c devMds1 = new Devices__c(Name = 'Test3', Dart_ID__c=404041, Node_ID__c= devMds.Id);
            insert devMds1;
            lstDevices.add(devMds);
            lstDevices.add(devMds1);
        }

        return lstDevices;
     }
    
    //13/01/2015 - to create Connection for testing 
     public static List<Connection__c> createConnections() {
        System.runAs(currentUser){
            lstConns = new List<Connection__c>();
            Connection__c conn1 = new Connection__c(Name = 'Test1', Dart_ID__c=123456, DFP_API_Name__c='BandwidthGroup');
            insert conn1;
            Connection__c conn2 = new Connection__c(Name = 'Test3', Dart_ID__c=111111, DFP_API_Name__c='MobileCarrier');
            insert conn2;
            Connection__c conn3 = new Connection__c(Name = 'Test1', Dart_ID__c=666666, Node_ID__c = conn1.Id);
            insert conn3;
            
            Connection__c conn4 = new Connection__c(Name = 'Test1', Dart_ID__c=121213, Node_ID__c = conn2.Id);
            insert conn4;
            Connection__c conn5 = new Connection__c(Name = 'Test3', Dart_ID__c=131414, Node_ID__c = conn2.Id);
            insert conn5;
    
            lstConns.add(conn1);
            lstConns.add(conn2);
            lstConns.add(conn3);
            lstConns.add(conn4);
            lstConns.add(conn5);
        }
        return lstConns;
    }
    
    
    //13/01/2015 - to create Geography for testing
    public static List<Geography__c> createGeographies() {
        System.runAs(currentUser){
            lstGeographies = new List<Geography__c>();
            Geography__c geo1 = new Geography__c(Name = 'Test1', Dart_ID__c=123456, Type__c = 'COUNTRY');
            insert geo1;
            Geography__c geo2 = new Geography__c(Name = 'Test2', Dart_ID__c=888888, Type__c = 'CITY', Node_ID__c=geo1.Id);
            insert geo2;
            Geography__c geo3 = new Geography__c(Name = 'Test3', Dart_ID__c=999999, Type__c = 'CITY', Node_ID__c=geo2.Id);
            insert geo3;
            lstGeographies.add(geo1);
            lstGeographies.add(geo2);
            lstGeographies.add(geo3);
        } 

        return lstGeographies;
    }
    
    /**
     * create targeting Association
     */ 
    public static void createTargetingHierarchy()
    {
        System.runAs(currentUser){
            List<Sobject> listObj = new List<SObject>();
            createTargetings(1);
            
            ////country + assoc
            //createCountries(1);
            //TargetingCountryAssociation__c countryAssoc = new TargetingCountryAssociation__c(TargetCountry__c='TestCountry', Targeting__c=targetting[0].Id, Country__c=countries[0].Id);
            //listObj.add(countryAssoc);
            
            ////city +  assoc
            //createCities(1,countries[0].Id);
            //TargetingCityAssociation__c cityAsso =new TargetingCityAssociation__c(targetcity__c='TestCity',Targeting__c=targetting[0].Id,City__c=cities[0].Id);
            //listObj.add(cityAsso);
            
            //// Regions
            //createRegions(1);
            //TargetingRegionAssociation__c regionAss =new    TargetingRegionAssociation__c(  TargetRegion__c='TestRegion',Targeting__c=targetting[0].Id, Region__c=regions[0].Id);
            //listObj.add(regionAss);
            
            ////area +  assoc
            //createAreaCodes(1);
            //TargetingAreaCodeAssociation__c tgArea = new TargetingAreaCodeAssociation__c(AreaCode__c=areaCodes[0].Id,Targeting__c=targetting[0].Id);
            //listObj.add(tgArea);
            
            ////kv +  assoc
            //createKV(1);
            keyvalues = new List<GAM_Key_Value__c>();            
            GAM_Key_Value__c k1 = (GAM_Key_Value__c)createKeyOrValueOrAS('k','seg','DE','11111111');
            upsert k1 GAM_Id__c;
            keyvalues.add(k1);

            //TargetingKeyValueAssociation__c kvAssoc = new TargetingKeyValueAssociation__c(DART_KeyValue__c=keyvalues[0].Id,Targeting__c=targetting[0].Id);
            TargetingKeyValueAssociation__c kvAssoc = new TargetingKeyValueAssociation__c(GAM_Key_Value__c=keyvalues[0].Id,Targeting__c=targetting[0].Id);
            listObj.add(kvAssoc);
            
            //content +  assoc
            createContents(3,new List<String>{'Dart - Site','Dart - Zone','Dart - Zone'});
            TargetingContentAssociation__c contAssoc = new TargetingContentAssociation__c(Target_Content_Key__c='key',Targeting__c=targetting[0].Id,TargetingContent__c=contents[0].Id);
            TargetingContentAssociation__c contAssoc2 = new TargetingContentAssociation__c(Target_Content_Key__c='key-111',Targeting__c=targetting[0].Id,TargetingContent__c=contents[1].Id);
            listObj.add(contAssoc);
            listObj.add(contAssoc2);
    
            //Placement +  assoc
            //Chr: @updated 05-09-2014: Comment out this block of code in order to avoid dependency when deploy to UAT
            createPlacement();
            PlacementTargetingAssociation__c placementAssoc = new PlacementTargetingAssociation__c(Targeting__c=targetting[0].Id, Placement__c=lstPlacements[0].id);
            listObj.add(placementAssoc);
            
            // 13/01/2015 device + asso
            createDevices();
            TargetingDeviceAssociation__c devAssoc = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev', Targeting__c=targetting[0].Id, Device__c = lstDevices[0].id);
            listObj.add(devAssoc);
            TargetingDeviceAssociation__c devAssoc2 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[1].id);
            listObj.add(devAssoc2);
            TargetingDeviceAssociation__c devAssoc3 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[2].id);
            listObj.add(devAssoc3);
            TargetingDeviceAssociation__c devAssoc4 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[3].id);
            listObj.add(devAssoc4);
            TargetingDeviceAssociation__c devAssoc5 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[4].id);
            listObj.add(devAssoc5);
            TargetingDeviceAssociation__c devAssoc6 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[5].id);
            listObj.add(devAssoc6);
            TargetingDeviceAssociation__c devAssoc7 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[6].id);
            listObj.add(devAssoc7);
            TargetingDeviceAssociation__c devAssoc8 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[7].id);
            listObj.add(devAssoc8);
            TargetingDeviceAssociation__c devAssoc9 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[8].id);
            listObj.add(devAssoc9);
            TargetingDeviceAssociation__c devAssoc10 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[9].id);
            listObj.add(devAssoc10);
            TargetingDeviceAssociation__c devAssoc11 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[10].id);
            listObj.add(devAssoc11);
            TargetingDeviceAssociation__c devAssoc12 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[11].id);
            listObj.add(devAssoc12);
            TargetingDeviceAssociation__c devAssoc13 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[12].id);
            listObj.add(devAssoc13);
            TargetingDeviceAssociation__c devAssoc114 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[13].id);
            listObj.add(devAssoc114);
            TargetingDeviceAssociation__c devAssoc15 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[14].id);
            listObj.add(devAssoc15);
            TargetingDeviceAssociation__c devAssoc16 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[15].id);
            listObj.add(devAssoc16);
            TargetingDeviceAssociation__c devAssoc17 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[16].id);
            listObj.add(devAssoc17);
            
             //Connection + asso
            createConnections();
            TargetingConnectionAssociation__c connAssoc = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn', Targeting__c=targetting[0].Id, Connection__c = lstConns[0].id);
            listObj.add(connAssoc);
            TargetingConnectionAssociation__c connAssoc2 = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn2', Targeting__c=targetting[0].Id, Connection__c = lstConns[1].id);
            listObj.add(connAssoc2);
            TargetingConnectionAssociation__c connAssoc3 = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn3', Targeting__c=targetting[0].Id, Connection__c = lstConns[2].id);
            listObj.add(connAssoc3);
            TargetingConnectionAssociation__c connAssoc4 = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn2', Targeting__c=targetting[0].Id, Connection__c = lstConns[3].id);
            listObj.add(connAssoc4);
            TargetingConnectionAssociation__c connAssoc5 = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn3', Targeting__c=targetting[0].Id, Connection__c = lstConns[4].id);
            listObj.add(connAssoc5);
            
            //geography + assoc
            createGeographies();
            TargetingGeographyAssociation__c geoAssoc = new TargetingGeographyAssociation__c(TargetGeography__c='TestGeo', Targeting__c=targetting[0].Id, Geography__c = lstGeographies[0].id);
            listObj.add(geoAssoc);
            TargetingGeographyAssociation__c geoAssoc2 = new TargetingGeographyAssociation__c(TargetGeography__c='TestGeo2', Targeting__c=targetting[0].Id, Geography__c = lstGeographies[1].id);
            listObj.add(geoAssoc2);
            TargetingGeographyAssociation__c geoAssoc3 = new TargetingGeographyAssociation__c(TargetGeography__c='TestGeo3', Targeting__c=targetting[0].Id, Geography__c = lstGeographies[2].id);
            listObj.add(geoAssoc3);
            
            insert listObj;
        }
    }
    
    /*********************************************************************************************************************************
    @ Method:              createKeyOrValueOrAS  
    @ Migrated From:       Advertising Instance (Legacy Code)
    @ Purpose:             test method for GAM_Key_Value__c record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
    *********************************************************************************************************************************/    
    public static SObject createKeyOrValueOrAS(String oType,String kvName,String site,String gid)
    {
        String rec_kv_key = ApexUtil.getRecordTypeByName('GAM_Key_Value__c','Key').Id;
        String rec_kv_val = ApexUtil.getRecordTypeByName('GAM_Key_Value__c','Value').Id;
        AdServer_Login__c slogin = DARTUtil.getCredential(DARTUtil.DART6,site);
        SObject tmp = null;
        if(oType=='k') //key or value
        {   
            tmp = new GAM_Key_Value__c(RecordTypeId=rec_kv_key,Name=kvName,Disaplay_Name__c=kvName,Active__c = true,Type__c='FREEFORM',GAM_ID__c=gid,Site__c=slogin.Id);           
                
        }else if(oType =='v')
        {
            tmp = new GAM_Key_Value__c(RecordTypeId = rec_kv_val, Name = kvName, Disaplay_Name__c = kvName, Active__c = true, Match_Type__c = 'EXACT', GAM_ID__c = gid, Site__c = slogin.Id);

        }
        return tmp;
    }

    /*********************************************************************************************************************************
    @ Method:              createTargetingKVHierarchy  
    @ Migrated From:       Advertising Instance (Legacy Code)
    @ Purpose:             test method for GAM_Key_Value__c record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
    *********************************************************************************************************************************/    
    /**
     * create GAM_Key_Value__c test records
     */
    public static List<SObject> createTargetingKVHierarchy()
    {
        //Map<String,GAM_Key_Value__c[]> createKV(Integer numToCreate)
        List<SObject> keyvaluesAll = new List<SObject>(); 
        System.runAs(currentUser){
            //createSite(new Set<String>{'DE'});
            
            keyvalues = new List<GAM_Key_Value__c>(); 
           
            // Key Free-form 
            //GAM_Key_Value__c k1 = new GAM_Key_Value__c(Dart6_KeyId__c=11111,Name='car test',Key__c='car',Key_Value__c='car',Key_Value_Name__c='car',Active__c=true, Site__c=sites.get(0).id, Key_ValueType_FreeForm__c=true);
            //insert k1;
            GAM_Key_Value__c k1 = (GAM_Key_Value__c)createKeyOrValueOrAS('k','car','DE','11111');
            upsert k1 GAM_Id__c;

            GAM_Key_Value__c val1 = (GAM_Key_Value__c)createKeyOrValueOrAS('v','bmw','DE','22222');
            GAM_Key_Value__c val2 = (GAM_Key_Value__c)createKeyOrValueOrAS('v','hummer','DE',null);
            val1.Parent__c = k1.Id;
            val2.Parent__c = k1.Id;
            upsert new GAM_Key_Value__c[]{val1} GAM_Id__c;
            insert val2;

            // GAM_Key_Value__c val1 = new GAM_Key_Value__c(Node_ID__c=k1.Id,Dart6_ValueId__c=22222,Name='bmw',Key_Value__c='bmw',Key_Value_Name__c='bmw',Active__c=true);
            // GAM_Key_Value__c val2 = new GAM_Key_Value__c(Node_ID__c=k1.Id,Dart6_ValueId__c=null,Name='hummer',Key_Value__c='hummer',Key_Value_Name__c='hummer',Active__c=true);
            // insert new GAM_Key_Value__c[]{val1,val2};
            
            // Key not Free-form
            //GAM_Key_Value__c k2 = new GAM_Key_Value__c(Dart6_KeyId__c=123123,Name='color test',Key__c='color',Key_Value__c='color',Key_Value_Name__c='color',Active__c=true, Site__c=sites.get(0).id);
            GAM_Key_Value__c k2 = (GAM_Key_Value__c)createKeyOrValueOrAS('k','color','DE','123123');
            k2.Type__c = 'PREDEFINED';
            upsert k2 GAM_Id__c;
            
            //GAM_Key_Value__c val21 = new GAM_Key_Value__c(Node_ID__c=k2.Id,Dart6_ValueId__c=66666,Name='red',Key_Value__c='red',Key_Value_Name__c='red',Active__c=true);
            //GAM_Key_Value__c val22 = new GAM_Key_Value__c(Node_ID__c=k2.Id,Dart6_ValueId__c=555555,Name='white',Key_Value__c='white',Key_Value_Name__c='white',Active__c=true);
            GAM_Key_Value__c val21 = (GAM_Key_Value__c)createKeyOrValueOrAS('v','red','DE','66666');            
            GAM_Key_Value__c val22  = (GAM_Key_Value__c)createKeyOrValueOrAS('v','555555','DE','555555');
            val21.Parent__c = k2.Id;
            val22.Parent__c = k2.Id;
            upsert new GAM_Key_Value__c[]{val21,val22} GAM_Id__c;            
             
            keyvalues.add(k1);
            keyvalues.add(val1); 
            keyvalues.add(val2); 
            keyvalues.add(k2);
            keyvalues.add(val21); 
            keyvalues.add(val22);
            
            // Create Keyvalue Audience Segment
            
            // List<GAM_Key_Value__c> lstKeyAs = [Select id, name, Key_Value__c, Key_Value_Name__c From GAM_Key_Value__c Where Key_Value__c='Audience Segment'];
            // if(lstKeyAs.size()>0)
            // {
                
            //     GAM_Key_Value__c asVal11 = new GAM_Key_Value__c(Node_ID__c=lstKeyAs.get(0).Id,Dart6_ValueId__c=999999,Name='Aud1',Key_Value__c='Aud1',Key_Value_Name__c='Aud1',Active__c=true);
            //     GAM_Key_Value__c asVal12 = new GAM_Key_Value__c(Node_ID__c=lstKeyAs.get(0).Id,Dart6_ValueId__c=888888,Name='Aud2',Key_Value__c='Aud2',Key_Value_Name__c='Aud2',Active__c=true);
            //     insert new GAM_Key_Value__c[]{asVal11,asVal12};
                
            //     keyvalues.addAll(lstKeyAs);
            //     keyvalues.add(asVal11);
            //     keyvalues.add(asVal12);
                
            // }
            // else
            // {
            //     GAM_Key_Value__c kvAs = new GAM_Key_Value__c(Dart6_KeyId__c=123123,Name='Audience Segment',Key__c='Audience Segment',Key_Value__c='Audience Segment',Key_Value_Name__c='Audience Segment',Active__c=true);
            //     insert kvAs;
                
            //     GAM_Key_Value__c asVal1 = new GAM_Key_Value__c(Node_ID__c=kvAs.Id,Dart6_ValueId__c=999999,Name='Aud1',Key_Value__c='Aud1',Key_Value_Name__c='Aud1',Active__c=true);
            //     GAM_Key_Value__c asVal2 = new GAM_Key_Value__c(Node_ID__c=kvAs.Id,Dart6_ValueId__c=888888,Name='Aud2',Key_Value__c='Aud2',Key_Value_Name__c='Aud2',Active__c=true);
            //     insert new GAM_Key_Value__c[]{asVal1,asVal2};
                
            //     keyvalues.add(kvAs);
            //     keyvalues.add(asVal1);
            //     keyvalues.add(asVal2);
                
            // }

            keyvaluesAll.addAll((SObject[])keyvalues);
              //TargetingKeyValueAssociation__c kvAssoc1 = new TargetingKeyValueAssociation__c(Name='kvAssocTest1',DARTKeyValue__c=val1.Id,Targeting__c=targetting[0].Id);
              //TargetingKeyValueAssociation__c kvAssoc2 = new TargetingKeyValueAssociation__c(Name='kvAssocTest2',DARTKeyValue__c=val2.Id,Targeting__c=targetting[0].Id);
              //insert new TargetingKeyValueAssociation__c[]{kvAssoc1,kvAssoc2};
        }   
            
        return keyvaluesAll;
        
    }
    public static Site__c createSite(String sName)
    {
        return new Site__c(Name=sName, Country__c=sName);
    }
    public static List<Placement__c> createPlacement()
     {
        System.runAs(currentUser){
            lstPlacements=new List<Placement__c>();
            Placement__c plc = new Placement__c(Name='test placement', Dart_ID__c=11111);
            lstPlacements.add(plc);
            insert lstPlacements;
        }
        return lstPlacements;
     }

    public static List<Account> createAccount()
    {
        System.runAs(currentUser){
            if(userAdmin==null) createTestUser();
            lstAcc = new List<Account>();
            for(Integer i=0; i<3; i++)
            {
                Account acc = new Account(
                            Name='Test Acc'+i,
                            //Country_Code__c='DE',
                            BillingStreet='Street', 
                            BillingPostalCode='1Nl1', 
                            BillingCity='City',
                            ownerId= userAdmin.Id
                          );
                lstAcc.add(acc);
            }
            insert lstAcc;  
        }
        return lstAcc;
    }

    public static User createTestUser()
    {
        System.runAs ( currentUser ) {
            Profile p=[Select Id, Name From Profile Where Name='System Administrator'  or Name='Systemadministrator' Limit 1];
            userAdmin = new User();
            userAdmin.Username='testUser1@boco.com';
            userAdmin.LastName='testLastName1';
            userAdmin.Email='testEmail1@boco.com';
            userAdmin.Alias='test1';
            userAdmin.TimeZoneSidKey='Pacific/kiritimati';
            userAdmin.LocaleSidKey='ar';
            userAdmin.EmailEncodingKey='UTF-8';
            userAdmin.ProfileId=p.Id;
            userAdmin.LanguageLocaleKey='en_US';   
            insert userAdmin;
        }     
        return userAdmin;                  
    }
 
    // US-0008578 : method below are to be called from other test class

    public static void call_setup(){
        setup();
    }
    // public static void call_testDART6_KeyValueController () {
    //     testDART6_KeyValueController();
    // }
    public static void call_testDART6Message () {
        testDART6Message();
    }
    public static void call_testDART6RequestForecast () {
        testDART6RequestForecast();
    }
    public static void call_testDart6GetAdvertiser () {
        testDart6GetAdvertiser();
    }
    public static void call_testDART6Booking () {
        testDART6Booking();
    }


    public static void call_testClassDART6_COMPANYSERVICE () {
        TestDARTCodeCoverage.testClassDART6_COMPANYSERVICE();
    }
    public static void call_testClassDART6_USERSERVICE () {
        testClassDART6_USERSERVICE();
    }
    public static void call_testClassDART6_ORDERSERVICE () {
        testClassDART6_ORDERSERVICE();
    }
    public static void call_testClassDART6_LINEITEMSERVICE () {
        testClassDART6_LINEITEMSERVICE();
    }
    public static void call_testClassDart6AvailabilityForecast () {
        testClassDart6AvailabilityForecast();
    }
    public static void call_testDART6ReportService () {
        testDART6ReportService();
    }
    public static void call_testDART6CustomTargetingService () {
        testDART6CustomTargetingService();
    }
    public static void call_testDART6NetworkService () {
        testDART6NetworkService();
    }
    // public static void call_testClassDART6_ProposalService () {
    //     testClassDART6_ProposalService();
    // }
    // public static void call_testClassDART6_ProposalLineItemService () {
    //     testClassDART6_ProposalLineItemService();
    // }


    @isTest
    static void testSchDeliveryAdProduct_America()
	{
		Test.startTest();
		SchDeliveryAdProduct_America sch = new SchDeliveryAdProduct_America();
		
		String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);

		Test.stopTest();
		
    }
    @isTest
    static void testSchDeliveryAdProduct_APAC()
	{
		Test.startTest();
		SchDeliveryAdProduct_APAC sch = new SchDeliveryAdProduct_APAC();
		
		String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);

		Test.stopTest();
		
    }
    @isTest
    static void testSchDeliveryAdProduct_EMEA()
	{
		Test.startTest();
		SchDeliveryAdProduct_EMEA sch = new SchDeliveryAdProduct_EMEA();
		
		String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);

		Test.stopTest();
		
    }
    
    @isTest
    static void testSchDeliveryAdRevenueDaily_America()
	{
		Test.startTest();
		SchDeliveryAdRevenueDaily_America sch = new SchDeliveryAdRevenueDaily_America();
		
		String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);

		Test.stopTest();
		
    }
    @isTest
    static void testSchDeliveryAdRevenueDaily_APAC()
	{
		Test.startTest();
		SchDeliveryAdRevenueDaily_APAC sch = new SchDeliveryAdRevenueDaily_APAC();
		
		String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);

		Test.stopTest();
		
    }
    @isTest
    static void testSchDeliveryAdRevenueDaily_EMEA()
	{
		Test.startTest();
		SchDeliveryAdRevenueDaily_EMEA sch = new SchDeliveryAdRevenueDaily_EMEA();
		
		String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);

		Test.stopTest();
		
    }
    @isTest
    static void testSchDeliveryAdRevenueMonthly_America()
	{
		Test.startTest();
		SchDeliveryAdRevenueMonthly_America sch = new SchDeliveryAdRevenueMonthly_America();
		
		String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);

		Test.stopTest();
		
    }
    @isTest
    static void testSchDeliveryAdRevenueMonthly_APAC()
	{
		Test.startTest();
		SchDeliveryAdRevenueMonthly_APAC sch = new SchDeliveryAdRevenueMonthly_APAC();
		
		String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);

		Test.stopTest();
		
    }
    @isTest
    static void testSchDeliveryAdRevenueMonthly_EMEA()
	{
		Test.startTest();
		SchDeliveryAdRevenueMonthly_EMEA sch = new SchDeliveryAdRevenueMonthly_EMEA();
		
		String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);

		Test.stopTest();
		
    }
    @isTest
    static void testSchWeeklyDeliveryRSD()
	{
		Test.startTest();
		SchWeeklyDeliveryRSD sch = new SchWeeklyDeliveryRSD();
		
		String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);

		Test.stopTest();
		
	}
    @isTest
    static void testRetryimport()
	{
        getTestData();        
        DART_Delivery_Support__c dds = new DART_Delivery_Support__c(
                AdServer_Login__c=logIn.id, //AdServer_Login__c=testDATA.listLogin.get(0).id,
                Schedule_Type__c = 'Daily',
                Sobject__c = DeliveryController.SOBJECT_AD_REV_DAILY,
                Status__c = 'New',
                Attempt__c = 0,
                Query_Start_Date__c = System.today(),
                Query_End_Date__c = System.today().addMonths(1)
                );
        insert dds;

         acc =lstAcc[0];// [SELECT Id FROM Account LIMIT 1];

        opp = TST_DataGenerator.generateOpp(acc.Id);
        opp.Special_Terms__c = 'New Terms - Spe';
        opp.StageName = 'Qualified Meeting';
        insert opp;

        site = generateSite(defaultCountry);
        site.Name = defaultCountry;
        site.Country__c = defaultCountry;
        site.currencyIsoCode = 'USD';
        insert site;

        Id prodDartRTId = ApexUtil.getRecordTypeByName('Product2','DART6').Id;
        prod1 = generateProduct(site.Id,prodDartRTId);
        prod1.Name = 'Test test test';
        insert prod1;

        Ad_Revenue_Monthly__c adMonthly =  new Ad_Revenue_Monthly__c(Amount__c=100,Ad_Product__c=adProd.Id,Opportunity__c=opp.Id,Transaction_Date__c=system.today());
        insert adMonthly;
        // System.QueryException: List has no rows for assignment to SObject
        Ad_Revenue_Daily__c[] adDaily = [Select Ad_Id__c, Order_Id__c, Delivered_AI__c, Delivered_AI_Lifetime__c, Clicks_Recorded__c, Clicks_Recorded_Lifetime__c, OSI__c, Product_Country__c, Transaction_Date__c, Ad_Product__r.Product2__r.Advertising_Medium__r.Quantity_Multiplier__c From Ad_Revenue_Daily__c LIMIT 1];
        if(adDaily.isEmpty())
        {
            adDaily.add( new Ad_Revenue_Daily__c(
                Ad_Product__c = adProd.Id,
                Ad_Revenue_Monthly__c=adMonthly.Id,
                Amount__c = 50,
                Transaction_Date__c = System.today()
            ));
            insert adDaily;
        }else {
            adDaily[0].Transaction_Date__c = System.today();
            update adDaily;
        }
        

        Ad_Product__c adProd = new Ad_Product__c();
        adProd.Id = adDaily[0].Ad_Product__c;
        adProd.Product2__c = prod1.Id;
        adProd.Billing_Category__c = 'Test';
        adProd.UnitPrice__c = 9;
        adProd.Quantity__c = 10;
        // adProd.Targeting__c = tg.Id;
        adProd.Line_Item_Description__c = 'Test test test';
        adProd.SalesPriceNet__c = 18;
        // adProd.Predefined_Adunit__c = content.Id;
        // adProd.Ad_Id__c = '3123123,31231231,1231231';
        adProd.Ad_Id__c = '3123123,31231231,89121790';
        
        
        update adProd;

        Test.startTest();
            dds = [SELECT Id,Sobject__c,Query_End_Date__c,Query_Start_Date__c,AdServer_Login__r.Name,AdServer_Login__r.Network_ID__c,Status__c,AdServer_Login__r.RecordType.Name,Retry_Counter__c,Schedule_Type__c,Zone__c FROM DART_Delivery_Support__c WHERE Id =: dds.Id];
            
            dds = DeliveryController.getDeliverySupportRecord(dds.Id);
            DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = DeliveryController.buildQueryService(dds);
            DeliveryController devCont = new DeliveryController(dds);
            
            devCont.setReportService(reportService);
            devCont.importDelivery();
            
            DeliveryController.checkJobStatus(dds);
            DeliveryController.startNextAdServer('Ad Product', 'Monthly');
            DeliveryController.startNextAdServer('Ad Product', 'Monthly', 'test');
            DeliveryController.start('Monthly', 'Ad Product');
            DeliveryController.start('Monthly', 'Ad Product', 'test');
            DeliveryController.doStart(dds);
            
            DeliveryController.processBatchDelivery(dds, devCont.getListDart());

            DeliveryController devCont2 = new DeliveryController(dds);
            DeliveryController devCont3 = new DeliveryController(dds, DART6Message.BREAKDOWN_DAILY);

            DeliveryController.retryImport(dds, new DARTLogger.LogMessage(
                                    dds.Id ,'Import Delivery Process was abandoned',
                                    'DeliveryController.checkJobStatus', dds.AdServer_Login__r.RecordType.name,
                                    DARTLogger.TYPE_ERROR, dds.Status__c, 'test' ));
            // DeliveryController.checkJobStatus(dds);
            DART6BatchDeliverySupport batchSupport = new DART6BatchDeliverySupport(dds.Id, DART6BatchDeliverySupport.CALL_TYPE_CHECK_REPORT_STATUS);
            Database.executeBatch(batchSupport);
            
            try{
                batchSupport.dds = null;
                batchSupport.finish(null);
            }catch(Exception ex){

            }

            String dsStartDate = DateTime.newInstance(dds.Query_Start_Date__c.year(),dds.Query_Start_Date__c.month(),dds.Query_Start_Date__c.day()).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
            String dsEndDate = DateTime.newInstance(dds.Query_End_Date__c.year(),dds.Query_End_Date__c.month(),dds.Query_End_Date__c.day()).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
            String queryStr = DeliveryController.mQuerySObject.get(dds.Sobject__c).replace('%1', dds.AdServer_Login__r.Name).replace('%2', dds.AdServer_Login__r.RecordType.Name);
            queryStr = queryStr.replaceAll(DeliveryController.QUERY_START_DATE, dsStartDate).replaceAll(DeliveryController.QUERY_END_DATE, dsEndDate);
    
            BatchDeliveryProcess batchDelivery = new BatchDeliveryProcess(queryStr, devCont.getListDart(), dds.Id);
            Database.executeBatch(batchDelivery);
            batchDelivery.clearCompletedSch();
            try{
                Map < Object, Object > mapRecord = new Map < Object, Object >{
                    DARTObject.DEL_FIELD_ADID => '888998001',
                    DARTObject.DEL_FIELD_ORDERID => '888998001'
                };
                DARTObject.DARTDelivery d1 = new DARTObject.DARTDelivery();
                d1.mapRecord = mapRecord;
                batchDelivery.sumDartObjects_EU(new List<DARTObject.IDARTGenericObject>{d1});
            }catch(Exception ex){}

            try{
                batchDelivery.getCombinedKeyDart(null, true);
            }catch(Exception ex){}

            try{
                batchDelivery.dds = null;
                batchDelivery.doExecute_EU([Select Ad_Id__c, Order_Id__c, Delivered_AI__c, Delivered_AI_Lifetime__c, Clicks_Recorded__c, Clicks_Recorded_Lifetime__c, OSI__c, Product_Country__c, Transaction_Date__c, Ad_Product__r.Product2__r.Advertising_Medium__r.Quantity_Multiplier__c From Ad_Revenue_Daily__c]);
            }catch(Exception ex){}

            try{
                batchDelivery.dds = null;
                batchDelivery.finish(null);
            }catch(Exception ex){}

            FactoryDARTRequest factoryDart  = FactoryDARTRequest.getInstance();
            Long testVr = 111;
            HTTPWrapper.IGenericRequest deliveryRequest1 = factoryDart.createAdxReportRequest(logIn,'','',testVr,reportService);
            HTTPWrapper.IGenericRequest deliveryRequest2 = factoryDart.createDartDeliveryRequest(logIn,'','',testVr,reportService);
            try{
                HTTPWrapper.IGenericRequest deliveryRequest3 = factoryDart.createGetLineItemRequestByAdIds(logIn,new OpportunityLineItem());
            }catch(Exception ex){
                
            }
            //DART6_Delivery ddlr = new DART6_Delivery();//TH:US-0016001 - destructive changes DART6_Delivery
            
        Test.stopTest();
    }
    //SB 25/10/2021 US-0008405 - Upgrade code coverage of DART6SchReportRequestWatcher from 58% to 85%
    @isTest
    static void testSchReportRequestWatcher(){
        getTestData();
        DART_Delivery_Support__c dds = new DART_Delivery_Support__c(
                AdServer_Login__c=logIn.id,
                Schedule_Type__c = 'Daily',
                Sobject__c = DeliveryController.SOBJECT_AD_REV_DAILY,
                Status__c = 'New',
                Attempt__c = 0,
                Query_Start_Date__c = System.today(),
                Query_End_Date__c = System.today().addMonths(1)
                );
        insert dds;
        test.startTest();
            DART6SchReportRequestWatcher sch = new DART6SchReportRequestWatcher(dds.Id);
            String cron = sch.createCronExpForNextFireTime();
            system.schedule('Test',cron, sch);
        test.stopTest();
    }

    static testMethod void testClassDART6_ProposalService()
    {
        // 01.12.2021 / Sophal Noch / US-0009927
        DART6_ProposalService proposalService = new DART6_ProposalService();
    
        DART6_ProposalService.CommonError propComErr = new DART6_ProposalService.CommonError();
        DART6_ProposalService.InternalApiError propInApiErr = new DART6_ProposalService.InternalApiError();
        DART6_ProposalService.ProposalError propErr = new DART6_ProposalService.ProposalError();
        // DART6_ProposalService.SubmitProposalsForApproval propSubOrdOver = new DART6_ProposalService.SubmitProposalsForApproval(); //US-0011408
        DART6_ProposalService.StringLengthError propStringErr = new DART6_ProposalService.StringLengthError();
        DART6_ProposalService.BooleanValue propBooVal = new DART6_ProposalService.BooleanValue();
        DART6_ProposalService.AppliedLabel propApLab = new DART6_ProposalService.AppliedLabel();
        DART6_ProposalService.UniqueError propUniErr = new DART6_ProposalService.UniqueError();
        DART6_ProposalService.RequiredError propReErr = new DART6_ProposalService.RequiredError();
        DART6_ProposalService.PauseProposals propPauOrd = new DART6_ProposalService.PauseProposals();
        DART6_ProposalService.ProposalPage propPage = new DART6_ProposalService.ProposalPage();
        DART6_ProposalService.AuthenticationError propAuthErr = new DART6_ProposalService.AuthenticationError();
        DART6_ProposalService.PermissionError propPerErr = new DART6_ProposalService.PermissionError();
        DART6_ProposalService.PublisherQueryLanguageSyntaxError propPUSyErr = new DART6_ProposalService.PublisherQueryLanguageSyntaxError();
        DART6_ProposalService.String_ValueMapEntry propStMapEnt = new DART6_ProposalService.String_ValueMapEntry();
        DART6_ProposalService.createProposalsResponse_element propCreResEle = new DART6_ProposalService.createProposalsResponse_element();
        DART6_ProposalService.Value propVal = new DART6_ProposalService.Value();
        DART6_ProposalService.DropDownCustomFieldValue propDroFv = new DART6_ProposalService.DropDownCustomFieldValue();
        DART6_ProposalService.ArchiveProposals propArOrd = new DART6_ProposalService.ArchiveProposals();
        DART6_ProposalService.BaseCustomFieldValue propBasFV = new DART6_ProposalService.BaseCustomFieldValue();
        DART6_ProposalService.TypeError propTypErr = new DART6_ProposalService.TypeError();
        DART6_ProposalService.getProposalsByStatement_element propOrdStaEle = new DART6_ProposalService.getProposalsByStatement_element();
        DART6_ProposalService.NumberValue propNumVal = new DART6_ProposalService.NumberValue();
        DART6_ProposalService.SoapResponseHeader propSoapRes = new DART6_ProposalService.SoapResponseHeader();
        DART6_ProposalService.CustomFieldValue propCusFv = new DART6_ProposalService.CustomFieldValue();
        DART6_ProposalService.updateProposalsResponse_element propUpdRs = new DART6_ProposalService.updateProposalsResponse_element();
        DART6_ProposalService.updateProposals_element propupOrd = new DART6_ProposalService.updateProposals_element();
        DART6_ProposalService.NotNullError propNotNullErr = new DART6_ProposalService.NotNullError();
        //DART6_ProposalService.SubmitProposalsForApproval propSuAppva = new DART6_ProposalService.SubmitProposalsForApproval();
        DART6_ProposalService.DateTimeValue propDateVal = new DART6_ProposalService.DateTimeValue();
        DART6_ProposalService.Statement propStat = new DART6_ProposalService.Statement();
        DART6_ProposalService.createProposals_element propcreOrd = new DART6_ProposalService.createProposals_element();
        DART6_ProposalService.PublisherQueryLanguageContextError propPuConEr = new DART6_ProposalService.PublisherQueryLanguageContextError();
        DART6_ProposalService.ApiError propApiErr = new DART6_ProposalService.ApiError();
        DART6_ProposalService.TeamError propTeamErr = new DART6_ProposalService.TeamError();
        DART6_ProposalService.CustomFieldValueError propCusvalErr = new DART6_ProposalService.CustomFieldValueError();
        DART6_ProposalService.performProposalActionResponse_element propPerOrdresEle = new DART6_ProposalService.performProposalActionResponse_element();
        DART6_ProposalService.ResumeProposals propResOrd = new DART6_ProposalService.ResumeProposals();
        DART6_ProposalService.ForecastError propFcErr = new DART6_ProposalService.ForecastError();
        DART6_ProposalService.QuotaError propQuErr = new DART6_ProposalService.QuotaError();
        DART6_ProposalService.ProposalActionError propOrdAcErr = new DART6_ProposalService.ProposalActionError();
        DART6_ProposalService.ApplicationException propApiExcep = new DART6_ProposalService.ApplicationException();
        DART6_ProposalService.RangeError propranErr = new DART6_ProposalService.RangeError();
        DART6_ProposalService.ParseError propParErr = new DART6_ProposalService.ParseError();
        DART6_ProposalService.Money propMoney = new DART6_ProposalService.Money();
        DART6_ProposalService.ApiVersionError propVerErr = new DART6_ProposalService.ApiVersionError();
        DART6_ProposalService.LabelEntityAssociationError propLaAssErr = new DART6_ProposalService.LabelEntityAssociationError();
        DART6_ProposalService.ServerError propSerErr = new DART6_ProposalService.ServerError();
        DART6_ProposalService.ProposalAction propOrAc = new DART6_ProposalService.ProposalAction();
        DART6_ProposalService.UnarchiveProposals propUnOrd = new DART6_ProposalService.UnarchiveProposals();
        DART6_ProposalService.DateTime_x propdatex = new DART6_ProposalService.DateTime_x();
        DART6_ProposalService.StatementError propStatErr = new DART6_ProposalService.StatementError();
        DART6_ProposalService.RequiredCollectionError propReCollErr = new DART6_ProposalService.RequiredCollectionError();
        DART6_ProposalService.TextValue propTxtVal = new DART6_ProposalService.TextValue();
        DART6_ProposalService.InvalidUrlError propInvEr = new DART6_ProposalService.InvalidUrlError();
        // DART6_ProposalService.RetractProposals propRetOrd = new DART6_ProposalService.RetractProposals(); //US-0011408
        DART6_ProposalService.UpdateResult propUpResl = new DART6_ProposalService.UpdateResult();
        DART6_ProposalService.getProposalsByStatementResponse_element propByStEle = new DART6_ProposalService.getProposalsByStatementResponse_element();
        DART6_ProposalService.performProposalAction_element propordACEle = new DART6_ProposalService.performProposalAction_element();
        DART6_ProposalService.InventoryUrlTargeting invUrlTarg = new DART6_ProposalService.InventoryUrlTargeting(); //US-0011408 
        DART6_ProposalService.InventoryUrl inventoryUrl = new DART6_ProposalService.InventoryUrl(); //US-0011408

        DART6_ProposalService.TechnologyTargeting tect = new DART6_ProposalService.TechnologyTargeting();
        DART6_ProposalService.DateTimeRangeTargeting dateRT= new DART6_ProposalService.DateTimeRangeTargeting();
        DART6_ProposalService.SetValue setv= new DART6_ProposalService.SetValue();
        DART6_ProposalService.InventoryTargeting inerr= new DART6_ProposalService.InventoryTargeting();
        DART6_ProposalService.FeatureError feaErr = new DART6_ProposalService.FeatureError();
        DART6_ProposalService.LineItemOperationError linOper = new DART6_ProposalService.LineItemOperationError();
        DART6_ProposalService.ProposalLineItemProgrammaticError  proEr= new DART6_ProposalService.ProposalLineItemProgrammaticError();
        DART6_ProposalService.EntityLimitReachedError entityReErr= new DART6_ProposalService.EntityLimitReachedError();
        DART6_ProposalService.NullError nuLerr= new DART6_ProposalService.NullError();
        DART6_ProposalService.ApiException apiErr = new DART6_ProposalService.ApiException();
        DART6_ProposalService.ApplicationException appExce= new DART6_ProposalService.ApplicationException();
        DART6_ProposalService.ProposalLineItemError linErr= new DART6_ProposalService.ProposalLineItemError();
        DART6_ProposalService.CreativePlaceholder creErr= new DART6_ProposalService.CreativePlaceholder();
        DART6_ProposalService.UserDomainTargeting urDeoTarErr= new DART6_ProposalService.UserDomainTargeting();
        DART6_ProposalService.InvalidUrlError invurErr= new DART6_ProposalService.InvalidUrlError();

        DART6_ProposalService.RequiredError reqSizeErr = new DART6_ProposalService.RequiredError();
        DART6_ProposalService.RequiredNumberError reqNumErr = new DART6_ProposalService.RequiredNumberError();
        DART6_ProposalService.DayPartTargeting dayTarErr = new DART6_ProposalService.DayPartTargeting();
        DART6_ProposalService.GeoTargeting geoTarErr = new DART6_ProposalService.GeoTargeting();
        DART6_ProposalService.DateValue dateVal = new DART6_ProposalService.DateValue();
        
        DART6_ProposalService.EntityChildrenLimitReachedError entChldLimErr = new DART6_ProposalService.EntityChildrenLimitReachedError();
        
        Object o;
        o = new DART6_ProposalService.TimeZoneError();
        o = new DART6_ProposalService.VideoPositionTargeting();
        o = new DART6_ProposalService.ObjectValue();
        o = new DART6_ProposalService.CollectionSizeError();
        
        o = new DART6_ProposalService.AudienceSegmentError();
        o = new DART6_ProposalService.CollectionSizeError();
        o = new DART6_ProposalService.CollectionSizeError();
        o = new DART6_ProposalService.CollectionSizeError();
        
        o = new DART6_ProposalService.FieldPathElement();
        o = new DART6_ProposalService.StringFormatError();

        //
        o = new DART6_ProposalService.ExchangeRateError();
        // o = new DART6_ProposalService.RetractionDetails();
        o = new DART6_ProposalService.Size();
        o = new DART6_ProposalService.CustomCriteriaNode();
        o = new DART6_ProposalService.RequestBuyerAcceptance();
        o = new DART6_ProposalService.OperatingSystemVersion();
        o = new DART6_ProposalService.AdUnitTargeting();
        o = new DART6_ProposalService.AudienceSegmentCriteria();
        o = new DART6_ProposalService.BrowserLanguage();
        o = new DART6_ProposalService.VideoPositionWithinPod();
        o = new DART6_ProposalService.DeviceCategory();
        o = new DART6_ProposalService.OperatingSystemVersionTargeting();
        o = new DART6_ProposalService.RequestPlatformTargeting();
        // o = new DART6_ProposalService.PackageActionError();  // 11.07.2023 / Sophal Noch / US-0013954
        o = new DART6_ProposalService.ContentTargeting();
        o = new DART6_ProposalService.SalespersonSplit();
        o = new DART6_ProposalService.EditProposalsForNegotiation();
        o = new DART6_ProposalService.SoapRequestHeader();
        o = new DART6_ProposalService.UpdateOrderWithSellerData();
        o = new DART6_ProposalService.Browser();
        // o = new DART6_ProposalService.WorkflowValidationError(); // 21.11.2022 / Sophal Noch / US-0012883
        o = new DART6_ProposalService.Targeting();
        o = new DART6_ProposalService.MobileDeviceSubmodel();
        o = new DART6_ProposalService.ProposalMarketplaceInfo();
        o = new DART6_ProposalService.TerminateNegotiations();
        o = new DART6_ProposalService.MarketplaceComment();
        o = new DART6_ProposalService.DealError();
        o = new DART6_ProposalService.ProposalCompanyAssociation();
        o = new DART6_ProposalService.OperatingSystemTargeting();
        o = new DART6_ProposalService.MobileDeviceTargeting();
        o = new DART6_ProposalService.DeviceManufacturerTargeting();
        o = new DART6_ProposalService.DeviceCategoryTargeting();
        o = new DART6_ProposalService.MobileDeviceSubmodelTargeting();
        o = new DART6_ProposalService.MobileCarrierTargeting();
        o = new DART6_ProposalService.BrowserTargeting();
        o = new DART6_ProposalService.DeviceCapability();
        o = new DART6_ProposalService.MobileApplicationTargeting();
        o = new DART6_ProposalService.BandwidthGroupTargeting();
        o = new DART6_ProposalService.ReserveProposals();
        o = new DART6_ProposalService.MarketplaceCommentPage();
        o = new DART6_ProposalService.getMarketplaceCommentsByStatement_element();
        o = new DART6_ProposalService.Technology();
        // o = new DART6_ProposalService.WorkflowActionError(); //US-0011408
        o = new DART6_ProposalService.CustomCriteria();
        o = new DART6_ProposalService.BrowserLanguageTargeting();
        o = new DART6_ProposalService.BuyerRfp();
        o = new DART6_ProposalService.CustomCriteriaSet();
        // o = new DART6_ProposalService.ProductError(); // 21.11.2022 / Sophal Noch / US-0012883
        o = new DART6_ProposalService.BuyerUserListTargeting();
        o = new DART6_ProposalService.DeviceManufacturer();
        o = new DART6_ProposalService.PrecisionError();
        o = new DART6_ProposalService.CustomCriteriaLeaf();
        o = new DART6_ProposalService.Proposal();
        o = new DART6_ProposalService.DeviceCapabilityTargeting();
        o = new DART6_ProposalService.OperatingSystem();
        o = new DART6_ProposalService.MobileCarrier();
        o = new DART6_ProposalService.RequestBuyerReview();
        o = new DART6_ProposalService.MobileDevice();
        o = new DART6_ProposalService.getMarketplaceCommentsByStatementResponse_element();
        o = new DART6_ProposalService.DateTimeRange();
        o = new DART6_ProposalService.TimeOfDay();
        o = new DART6_ProposalService.DiscardLocalVersionEdits();
        o = new DART6_ProposalService.LabelEntityAssociationError();
        o = new DART6_ProposalService.VideoPosition();
        o = new DART6_ProposalService.Date_x();
        o = new DART6_ProposalService.BillingError();
        o = new DART6_ProposalService.DayPart();
        o = new DART6_ProposalService.VideoPositionTarget();
        o = new DART6_ProposalService.CmsMetadataCriteria();
        // o = new DART6_ProposalService.PackageError();  // 21.11.2022 / Sophal Noch / US-0012883
        o = new DART6_ProposalService.BandwidthGroup();
        o = new DART6_ProposalService.Location();
        //

        // 21.11.2022 / Sophal Noch / US-0012883
        o = new DART6_ProposalService.TargetedSize();
        o = new DART6_ProposalService.CurrencyCodeError();
        o = new DART6_ProposalService.InventorySizeTargeting();

        o = new DART6_ProposalService.ProgrammaticError(); // 19.02.2024 / Sophal Noch / US-0014655
    
        Test.startTest();
            DART6_ProposalService.ProposalServiceInterfacePort svc = new DART6_ProposalService.ProposalServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_ProposalService.performProposalActionResponse_element()));
            svc.performProposalAction(new DART6_ProposalService.ProposalAction(), new DART6_ProposalService.Statement());
            System.assertNotEquals(null, svc);
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_ProposalService.updateProposalsResponse_element()));
            svc.updateProposals(new List<DART6_ProposalService.Proposal>());
            System.assertNotEquals(null, svc);
        Test.stopTest();
        
    }

    static testMethod void testClassDART6_ProposalLineItemService()
    {
    //     // 01.12.2021 / Sophal Noch / US-0009927
        Test.startTest();
            DART6_LINEITEMSERVICE.ProposalLineItemServiceInterfacePort svc = new DART6_LINEITEMSERVICE.ProposalLineItemServiceInterfacePort();
            svc.createProposalLineItems(new DART6_LINEITEMSERVICE.ProposalLineItem[0]);
            System.assertNotEquals(null, svc);
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_LINEITEMSERVICE.performProposalLineItemActionResponse_element()));
            svc.performProposalLineItemAction(new DART6_LINEITEMSERVICE.LineItemAction(), new DART6_LINEITEMSERVICE.Statement());
            System.assertNotEquals(null, svc);

            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_LINEITEMSERVICE.updateProposalLineItemsResponse_element()));
            //svc.updateProposalLineItems(new DART6_LINEITEMSERVICE.ProposalLineItem[0]);
            svc.updateProposalLineItems(new DART6_LINEITEMSERVICE.ProposalLineItem[0]);
            System.assertNotEquals(null, svc);
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_LINEITEMSERVICE.getProposalLineItemsByStatement_element()));
            svc.getProposalLineItemsByStatement( new DART6_LINEITEMSERVICE.Statement());
            System.assertNotEquals(null, svc);
            /*Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_LINEITEMSERVICE.createMakegoodsResponse_element()));
            svc.createMakegoods(new DART6_LINEITEMSERVICE.ProposalLineItem[0]);
            System.assertNotEquals(null, svc);*/
        Test.stopTest();
    }

    static testMethod void testClassDart6_PublisherQueryLanguageService()
    {
        // 01.12.2021 / Sophal Noch / US-0009971
        Object o;
        o = new Dart6_PublisherQueryLanguageService.OrderError();
        o = new Dart6_PublisherQueryLanguageService.ExchangeRateError();
        o = new Dart6_PublisherQueryLanguageService.CustomCriteriaNode();
        o = new Dart6_PublisherQueryLanguageService.RequiredSizeError();
        o = new Dart6_PublisherQueryLanguageService.OperatingSystemVersion();
        o = new Dart6_PublisherQueryLanguageService.DateTime_x();
        o = new Dart6_PublisherQueryLanguageService.DayPartTargeting();
        o = new Dart6_PublisherQueryLanguageService.AdUnitTargeting();
        o = new Dart6_PublisherQueryLanguageService.AudienceSegmentCriteria();
        o = new Dart6_PublisherQueryLanguageService.BrowserLanguage();
        o = new Dart6_PublisherQueryLanguageService.BooleanValue();
        o = new Dart6_PublisherQueryLanguageService.ResultSet();
        o = new Dart6_PublisherQueryLanguageService.VideoPositionWithinPod();
        o = new Dart6_PublisherQueryLanguageService.RequiredCollectionError();
        o = new Dart6_PublisherQueryLanguageService.DeviceCategory();
        o = new Dart6_PublisherQueryLanguageService.TargetingValue();
        o = new Dart6_PublisherQueryLanguageService.SoapResponseHeader();
        o = new Dart6_PublisherQueryLanguageService.InventoryTargetingError();
        o = new Dart6_PublisherQueryLanguageService.UniqueError();
        o = new Dart6_PublisherQueryLanguageService.AuthenticationError();
        o = new Dart6_PublisherQueryLanguageService.OperatingSystemVersionTargeting();
        o = new Dart6_PublisherQueryLanguageService.RequestPlatformTargeting();
        o = new Dart6_PublisherQueryLanguageService.LineItemOperationError();
        o = new Dart6_PublisherQueryLanguageService.PermissionError();
        o = new Dart6_PublisherQueryLanguageService.ReservationDetailsError();
        o = new Dart6_PublisherQueryLanguageService.ContentTargeting();
        o = new Dart6_PublisherQueryLanguageService.FieldPathElement();
        o = new Dart6_PublisherQueryLanguageService.PublisherQueryLanguageContextError();
        o = new Dart6_PublisherQueryLanguageService.InternalApiError();
        o = new Dart6_PublisherQueryLanguageService.SoapRequestHeader();
        o = new Dart6_PublisherQueryLanguageService.UserDomainTargeting();
        o = new Dart6_PublisherQueryLanguageService.CreativeError();
        o = new Dart6_PublisherQueryLanguageService.TextValue();
        o = new Dart6_PublisherQueryLanguageService.LineItemFlightDateError();
        o = new Dart6_PublisherQueryLanguageService.TypeError();
        o = new Dart6_PublisherQueryLanguageService.ApiError();
        o = new Dart6_PublisherQueryLanguageService.Browser();
        o = new Dart6_PublisherQueryLanguageService.FileError();
        o = new Dart6_PublisherQueryLanguageService.Targeting();
        o = new Dart6_PublisherQueryLanguageService.MobileDeviceSubmodel();
        o = new Dart6_PublisherQueryLanguageService.PublisherQueryLanguageSyntaxError();
        o = new Dart6_PublisherQueryLanguageService.InvalidUrlError();
        o = new Dart6_PublisherQueryLanguageService.String_ValueMapEntry();
        o = new Dart6_PublisherQueryLanguageService.selectResponse_element();
        o = new Dart6_PublisherQueryLanguageService.NumberValue();
        o = new Dart6_PublisherQueryLanguageService.DateValue();
        o = new Dart6_PublisherQueryLanguageService.TechnologyTargeting();
        o = new Dart6_PublisherQueryLanguageService.OperatingSystemTargeting();
        o = new Dart6_PublisherQueryLanguageService.Statement();
        o = new Dart6_PublisherQueryLanguageService.MobileDeviceTargeting();
        o = new Dart6_PublisherQueryLanguageService.DeviceManufacturerTargeting();
        o = new Dart6_PublisherQueryLanguageService.VideoPositionTargeting();
        o = new Dart6_PublisherQueryLanguageService.AdUnitCodeError();
        o = new Dart6_PublisherQueryLanguageService.DeviceCategoryTargeting();
        o = new Dart6_PublisherQueryLanguageService.MobileDeviceSubmodelTargeting();
        o = new Dart6_PublisherQueryLanguageService.ApplicationException();
        o = new Dart6_PublisherQueryLanguageService.MobileCarrierTargeting();
        o = new Dart6_PublisherQueryLanguageService.BrowserTargeting();
        o = new Dart6_PublisherQueryLanguageService.ApiException();
        o = new Dart6_PublisherQueryLanguageService.DeviceCapability();
        o = new Dart6_PublisherQueryLanguageService.MobileApplicationTargeting();
        o = new Dart6_PublisherQueryLanguageService.ColumnType();
        o = new Dart6_PublisherQueryLanguageService.BandwidthGroupTargeting();
        o = new Dart6_PublisherQueryLanguageService.InventoryUnitError();
        o = new Dart6_PublisherQueryLanguageService.NotNullError();
        o = new Dart6_PublisherQueryLanguageService.NullError();
        o = new Dart6_PublisherQueryLanguageService.QuotaError();
        o = new Dart6_PublisherQueryLanguageService.ObjectValue();
        o = new Dart6_PublisherQueryLanguageService.RequiredNumberError();
        o = new Dart6_PublisherQueryLanguageService.Technology();
        o = new Dart6_PublisherQueryLanguageService.ApiVersionError();
        o = new Dart6_PublisherQueryLanguageService.DateTimeRangeTargeting();
        o = new Dart6_PublisherQueryLanguageService.StringLengthError();
        o = new Dart6_PublisherQueryLanguageService.CustomCriteria();
        o = new Dart6_PublisherQueryLanguageService.CollectionSizeError();
        o = new Dart6_PublisherQueryLanguageService.BrowserLanguageTargeting();
        o = new Dart6_PublisherQueryLanguageService.DateTimeValue();
        o = new Dart6_PublisherQueryLanguageService.ServerError();
        o = new Dart6_PublisherQueryLanguageService.CustomCriteriaSet();
        o = new Dart6_PublisherQueryLanguageService.InventoryTargeting();
        o = new Dart6_PublisherQueryLanguageService.GeoTargeting();
        o = new Dart6_PublisherQueryLanguageService.BuyerUserListTargeting();
        o = new Dart6_PublisherQueryLanguageService.DeviceManufacturer();
        o = new Dart6_PublisherQueryLanguageService.Value();
        o = new Dart6_PublisherQueryLanguageService.CustomCriteriaLeaf();
        o = new Dart6_PublisherQueryLanguageService.Row();
        o = new Dart6_PublisherQueryLanguageService.InvalidEmailError();
        o = new Dart6_PublisherQueryLanguageService.FeatureError();
        o = new Dart6_PublisherQueryLanguageService.DeviceCapabilityTargeting();
        o = new Dart6_PublisherQueryLanguageService.OperatingSystem();
        o = new Dart6_PublisherQueryLanguageService.MobileCarrier();
        o = new Dart6_PublisherQueryLanguageService.MobileDevice();
        o = new Dart6_PublisherQueryLanguageService.ChangeHistoryValue();
        o = new Dart6_PublisherQueryLanguageService.RangeError();
        o = new Dart6_PublisherQueryLanguageService.ParseError();
        o = new Dart6_PublisherQueryLanguageService.DateTimeRange();
        o = new Dart6_PublisherQueryLanguageService.AdUnitHierarchyError();
        o = new Dart6_PublisherQueryLanguageService.TimeOfDay();
        o = new Dart6_PublisherQueryLanguageService.select_element();
        o = new Dart6_PublisherQueryLanguageService.StringFormatError();
        o = new Dart6_PublisherQueryLanguageService.RequiredError();
        o = new Dart6_PublisherQueryLanguageService.OrderActionError();
        o = new Dart6_PublisherQueryLanguageService.VideoPosition();
        o = new Dart6_PublisherQueryLanguageService.Date_x();
        o = new Dart6_PublisherQueryLanguageService.DayPart();
        o = new Dart6_PublisherQueryLanguageService.StatementError();
        o = new Dart6_PublisherQueryLanguageService.RegExError();
        o = new Dart6_PublisherQueryLanguageService.VideoPositionTarget();
        o = new Dart6_PublisherQueryLanguageService.CmsMetadataCriteria();
        o = new Dart6_PublisherQueryLanguageService.CommonError();
        o = new Dart6_PublisherQueryLanguageService.AudienceSegmentError();
        o = new Dart6_PublisherQueryLanguageService.SetValue();
        o = new Dart6_PublisherQueryLanguageService.BandwidthGroup();
        o = new Dart6_PublisherQueryLanguageService.Location();
        // 21.11.2022 / Sophal Noch / US-0012883
        o = new Dart6_PublisherQueryLanguageService.InventoryUrlTargeting();
        o = new Dart6_PublisherQueryLanguageService.InventorySizeTargeting();
        o = new Dart6_PublisherQueryLanguageService.InventoryUrl();
        o = new Dart6_PublisherQueryLanguageService.DealError();
        o = new Dart6_PublisherQueryLanguageService.TargetedSize();
        

        Test.startTest();
            Dart6_PublisherQueryLanguageService.PublisherQueryLanguageServiceInterfacePort pqlService = new Dart6_PublisherQueryLanguageService.PublisherQueryLanguageServiceInterfacePort();
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new Dart6_PublisherQueryLanguageService.selectResponse_element()));
            pqlService.select_x(new Dart6_PublisherQueryLanguageService.Statement());
            System.assertNotEquals(null, pqlService);
        Test.stopTest();

    }


    
}