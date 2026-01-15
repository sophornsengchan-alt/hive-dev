/**
 * Author : Gaeasys
 * CreatedDate: 28-june-2018
 * Description:
 */
@isTest
private class LPC_TargetingTreeSelectorControllerTest {

	public static Account account;
	public static Opportunity opp;
	public static Media_Plan__c media;
	public static QuoteLineItem quoteLineItem;
	public static Connection__c con1, con2, con3;
    static Content__c content0,content,content1;
    static Targeting__c t;
    static Devices__c device;
    static Placement__c placment;
    static Geography__c posCode,geo,geo2;

	static void setupData(){
        Id RecId = Schema.SObjectType.Targeting__c.getRecordTypeInfosByName().get('Template').getRecordTypeId();
        t = new Targeting__c();
        t.Description__c = 'Tageting Template';
        t.RecordTypeId = RecId;
        insert t;

        con1 = new Connection__c(Dart_ID__c = 123456);		 
		con2 = new Connection__c(Dart_ID__c = 111111);		 
		con3 = new Connection__c(Dart_ID__c = 666666);
		insert new Connection__c[]{con1,con2,con3};
        
		device = new Devices__c(Name = 'Microsoft Windows 10');
        insert device;


        TargetingDeviceAssociation__c targetingDeAss = new TargetingDeviceAssociation__c();
        targetingDeAss.Targeting__c  = t.Id;
        targetingDeAss.Device__c = device.Id;
        insert targetingDeAss;

        TargetingConnectionAssociation__c targetConAss = new TargetingConnectionAssociation__c();
        targetConAss.Targeting__c  = t.Id;
        targetConAss.Connection__c = con1.Id;
        insert targetConAss;

        geo = new Geography__c(Name = 'Cambodia');
        insert geo;
        geo2 = new Geography__c(Name = 'My City',Node_ID__c=geo.Id);
        insert geo2;

        TargetingGeographyAssociation__c targetGeo = new TargetingGeographyAssociation__c( Targeting__c = t.Id, Geography__c=geo.Id );
        insert targetGeo;

        content0 = new Content__c(Name = 'Test Contant 11', DartName__c = 'test 11', Active__c = true, Type__c='Dart - Zone');
        insert content0;

        content = new Content__c(Name = 'Test Contant', DartName__c = 'test', Active__c = true,Content__c = content0.Id,Type__c='Dart - Site');//Dart - Site, Dart - Zone, Dart - ContentCategory
        insert content;

        content1 = new Content__c(Name = 'Test Contant 11', DartName__c = 'test 11', Active__c = true, Content__c = content.Id,Type__c='Dart - ContentCategory');
        insert content1;

        TargetingContentAssociation__c  targetContentAss = new TargetingContentAssociation__c( Targeting__c = t.Id, TargetingContent__c = content.Id );
        insert targetContentAss;

        placment = new Placement__c(Name = 'Test Placement', Content_Category_Site__c = content.Id);
        insert placment;

        PlacementTargetingAssociation__c placmentTarget = new PlacementTargetingAssociation__c( Targeting__c = t.Id, Placement__c = placment.Id );
        insert placmentTarget;

        
        account = TST_DataGenerator.generateAccount();
        insert account;

        opp = TST_DataGenerator.generateOpp(account.Id);
        insert opp;
        //media = TST_DataGenerator.generateMediaPlan(opp);
        //insert media;
        Quote quote = TST_DataGenerator.generateQuote(opp.Id);
        insert quote;
        Product2 product = TST_DataGenerator.generateProduct();
        product.Available_Key_Values__c = 'posN';
        product.Content__c = content.Id+'';
        insert product;
        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(product.Id,null);
        insert pbe;

        quoteLineItem = new QuoteLineItem();
        quoteLineItem.Product2Id = product.Id;
        quoteLineItem.QuoteId = quote.Id;
        quoteLineItem.Quantity = 20;
        quoteLineItem.Quantity__c = 20;
        quoteLineItem.UnitPrice = 10;
        quoteLineItem.Targeting__c = t.Id;
        quoteLineItem.PricebookEntryId = pbe.Id;
        insert quoteLineItem;

        posCode = new Geography__c(Name = '12345', Dart_ID__c=999999, Type__c = 'POSTAL_CODE');
        insert posCode;

		System.debug('log');

	}

	static testMethod void targetingTreeSelector() {

		setupData();
        

        Test.startTest();
        
        LPC_TargetingTreeSelectorController ttsc = new LPC_TargetingTreeSelectorController();
        ttsc.lsts = new List<LPC_TargetingTreeSelectorController.DTOTreeItem>();
        //RemoteResponse getTreeDevice = LPC_TargetingTreeSelectorController.getTree('Device', oppItem.id);
        //RemoteResponse getTreeContent = LPC_TargetingTreeSelectorController.getTree('Ad_Unit', oppItem.id);
        RemoteResponse getTreeDevice1 = LPC_TargetingTreeSelectorController.getTree('Device', quoteLineItem.Id,null);
        RemoteResponse getTreeBrowser = LPC_TargetingTreeSelectorController.getTree('Browser', quoteLineItem.Id, null);
        RemoteResponse getTreeOS = LPC_TargetingTreeSelectorController.getTree('OperatingSystem', quoteLineItem.Id, null);
        RemoteResponse getTreeConnection = LPC_TargetingTreeSelectorController.getTree('Connection', quoteLineItem.Id, null);
        RemoteResponse getTreeBandwidth = LPC_TargetingTreeSelectorController.getTree('Bandwidth', quoteLineItem.Id,null);
        RemoteResponse getTreeGeography = LPC_TargetingTreeSelectorController.getTree('Geography', quoteLineItem.Id, null);
        System.assertEquals(getTreeGeography.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(getTreeGeography.content != null);
        
        //RemoteResponse getTreeTempDevice = LPC_TargetingTreeSelectorController.getTreeTemplate('Device', targ.Id, oppItem.Id);
        //System.assertEquals(getTreeTempDevice.statusCode, RemoteResponse.STATUSCODE_OK);
        //System.assert(getTreeTempDevice.content != null);
        Map<String, object> response = (Map<String, object>) getTreeDevice1.content;
        list<object> lstrd = (list<object>) response.get('objs');
        String lstTobeSaved = JSON.serialize(lstrd[0]);
        RemoteResponse saveTreeDevice = LPC_TargetingTreeSelectorController.doSaveRecords('Device', quoteLineItem.Id, lstTobeSaved);

        //RemoteResponse saveTreeDeviceTemp = LPC_TargetingTreeSelectorController.doSaveRecordsTempleate('Device', targ.Id, lstTobeSaved);
        response = (Map<String, object>) getTreeConnection.content;
        list<object> lsc = (list<object>) response.get('objs');
        String lstTobeSavedc = JSON.serialize(lsc[0]);
        RemoteResponse saveTreegetTreeConnection = LPC_TargetingTreeSelectorController.doSaveRecords('Connection', quoteLineItem.Id, lstTobeSavedc);

        response = (Map<String, object>) getTreeGeography.content;
        list<object> lstt = (list<object>) response.get('objs');
        String lstTobeSavedt = JSON.serialize(lstt[0]);
        RemoteResponse saveTreeGeography = LPC_TargetingTreeSelectorController.doSaveRecords('Geography', quoteLineItem.Id, lstTobeSavedt);
        System.assertEquals(saveTreeGeography.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(saveTreeGeography.content != null);
        
        Map<String, String> mapDevSelectedMode = new Map<String, String>();
        Map<Id, String> lscd = (Map<Id, String>)lsc[1];
        for(Id ds: lscd.keySet()){
            mapDevSelectedMode.put(ds+'', lscd.get(ds));
        }

		//get childnode from Connection
		RemoteResponse getgetChildren = LPC_TargetingTreeSelectorController.getChildren('Connection', con1.Id, 1, mapDevSelectedMode);
        System.assert(getgetChildren.content != null);

        RemoteResponse getgetChildren1 = LPC_TargetingTreeSelectorController.getChildren('Browser', content.Id, 1, mapDevSelectedMode);
        System.assert(getgetChildren1.content != null);

        RemoteResponse getgetChildren2 = LPC_TargetingTreeSelectorController.getChildren('Geography', geo.Id, 1, mapDevSelectedMode);
        System.assert(getgetChildren2.content != null);

        RemoteResponse getgetChildren3 = LPC_TargetingTreeSelectorController.getChildren('Ad_Unit', content.Id, 1, mapDevSelectedMode);
        System.assert(getgetChildren3.content != null);

        //search tree
        RemoteResponse getdoSearchTree =  LPC_TargetingTreeSelectorController.doSearchTree('Connection','Test1', quoteLineItem.Id);
        System.assert(getdoSearchTree.content != null);

        RemoteResponse getTreeDevice = LPC_TargetingTreeSelectorController.getTree('Device', quoteLineItem.Id, null);
        RemoteResponse getTreeContent = LPC_TargetingTreeSelectorController.getTree('Ad_Unit', quoteLineItem.Id, null);
        
        RemoteResponse getTreeTempDevice = LPC_TargetingTreeSelectorController.getTreeTemplate('Device', t.Id, quoteLineItem.Id);
        System.assertEquals(getTreeTempDevice.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(getTreeTempDevice.content != null); 

        RemoteResponse getTreeTempConnection = LPC_TargetingTreeSelectorController.getTreeTemplate('Connection', t.Id, quoteLineItem.Id);
        System.assertEquals(getTreeTempConnection.statusCode, RemoteResponse.STATUSCODE_OK);  
        System.assert(getTreeTempConnection.content != null);    

        RemoteResponse getTreeTempGeo = LPC_TargetingTreeSelectorController.getTreeTemplate('Geography', t.Id, quoteLineItem.Id);
        System.assertEquals(getTreeTempGeo.statusCode, RemoteResponse.STATUSCODE_OK);  
        System.assert(getTreeTempGeo.content != null);    

        RemoteResponse getTreeTempContent = LPC_TargetingTreeSelectorController.getTreeTemplate('Ad_Unit', t.Id, quoteLineItem.Id);
        System.assertEquals(getTreeTempContent.statusCode, RemoteResponse.STATUSCODE_OK);  
        System.assert(getTreeTempContent.content != null);  

		RemoteResponse doSearchAd = LPC_TargetingTreeSelectorController.doSearchTree('Ad_Unit', 'test', quoteLineItem.Id);
		System.assertEquals(doSearchAd.statusCode, RemoteResponse.STATUSCODE_OK);  
        System.assert(doSearchAd.content != null);  

        RemoteResponse doSearchGeo = LPC_TargetingTreeSelectorController.doSearchTree('Geography', 'Cambodia', quoteLineItem.Id);
		System.assertEquals(doSearchGeo.statusCode, RemoteResponse.STATUSCODE_OK);  
        System.assert(doSearchGeo.content != null); 

        RemoteResponse doSaveRecords = LPC_TargetingTreeSelectorController.doSaveRecords('Geography', quoteLineItem.Id,'Cambodia');
		System.assertEquals(doSaveRecords.statusCode, RemoteResponse.STATUSCODE_OK);  
        System.assert(doSaveRecords.content != null); 

         RemoteResponse doSaveRecordsAd = LPC_TargetingTreeSelectorController.doSaveRecords('Ad_Unit', quoteLineItem.Id,'test');
		System.assertEquals(doSaveRecordsAd.statusCode, RemoteResponse.STATUSCODE_OK);  
        System.assert(doSaveRecordsAd.content != null); 

        RemoteResponse doSaveRecordsTempleate = LPC_TargetingTreeSelectorController.doSaveRecordsTempleate('Ad_Unit', t.Id,'test');
		System.assertEquals(doSaveRecordsTempleate.statusCode, RemoteResponse.STATUSCODE_OK);  
        System.assert(doSaveRecordsTempleate.content != null); 

       
       

       

        Test.stopTest();

	}
    static testMethod void testLoadSumary() 
    {
        setupData();
        Test.startTest();
            String contentFileCSV = '12345';
            RemoteResponse res_summary = LPC_TargetingTreeSelectorController.loadSummary (quoteLineItem.Id, contentFileCSV);
            
            //device,browser,os
            LPC_TargetingTreeSelectorController.DTOTreeItem item1 = new LPC_TargetingTreeSelectorController.DTOTreeItem();
            item1.treeId =  device.Id;//device id
            item1.treeName =  'Device';
            //connection/bandwidth
            LPC_TargetingTreeSelectorController.DTOTreeItem item2 = new LPC_TargetingTreeSelectorController.DTOTreeItem();
            item2.treeId = con1.Id;
            item2.treeName = 'Connection';
            //geo
             LPC_TargetingTreeSelectorController.DTOTreeItem item3 = new LPC_TargetingTreeSelectorController.DTOTreeItem();
            item3.treeId = geo.Id;
            item3.treeName = 'Geography';

            //adunit
            LPC_TargetingTreeSelectorController.DTOTreeItem item4 = new LPC_TargetingTreeSelectorController.DTOTreeItem();
            item4.treeId = content.Id;
            item4.treeName = 'Ad_Unit';

            LPC_TargetingTreeSelectorController.DTOTreeItem item5 = new LPC_TargetingTreeSelectorController.DTOTreeItem();
            item5.treeId = content1.Id;
            item5.treeName = 'Ad_Unit';

            List<Object> timesSelected = new List<Object>();            
            timesSelected.add(
                new Map<String, Object>{
                    'day'=>'Monday'
                }
            );


            TargetingFrequencyAssociation__c taFC = new TargetingFrequencyAssociation__c(Targeting__c = t.Id) ;
            insert taFC;
            
            //List<LPC_TargetingTreeSelectorController.DTOTreeItem> lstDto = new List<LPC_TargetingTreeSelectorController.DTOTreeItem>{item1,item2,item3};
            Map<String,Object> mapdata = new Map<String,Object>();
            mapdata.put('Device', JSON.serialize(new List<LPC_TargetingTreeSelectorController.DTOTreeItem>{item1}));
            mapdata.put('Connection', JSON.serialize(new List<LPC_TargetingTreeSelectorController.DTOTreeItem>{item2}));
            mapdata.put('Geography', JSON.serialize(new List<LPC_TargetingTreeSelectorController.DTOTreeItem>{item3}));
            mapdata.put('Ad_Unit', JSON.serialize(new List<LPC_TargetingTreeSelectorController.DTOTreeItem>{item4,item5}));           
            mapdata.put('FC', JSON.serialize(new List<TargetingFrequencyAssociation__c>{taFC}));
            mapdata.put('TargetingTime', JSON.serialize(timesSelected));
            //mapdata.put('Ad_Unit', JSON.serialize( ));
            
            String jsonAssoToSave = JSON.serialize(mapdata);
            
            
            RemoteResponse resSaveTemplate = LPC_TargetingTreeSelectorController.saveTemplate(t.Id,jsonAssoToSave);
        Test.stopTest();
    }

 
    
}