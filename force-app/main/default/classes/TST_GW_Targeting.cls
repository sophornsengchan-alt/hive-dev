@isTest
private class TST_GW_Targeting
{
	static Map<String,Object> mapResult;

	@testSetup static void setup(){
    	TestDARTCodeCoverage.createTestUser();
        TestDARTCodeCoverage.createCredential('DE');
    }

	static void setUpData()
	{
		mapResult = new Map<String,Object>();

		Targeting__c t1 = new Targeting__c(Description__c = 'test');		 
		Content__c content = new Content__c(Name = 'Test Contant', DartName__c = 'test', Active__c = true);
		Devices__c device = new Devices__c(Name = 'Microsoft Windows 10');        
		Geography__c geo = new Geography__c(Name = 'Cambodia');         
		Connection__c con1 = new Connection__c(Dart_ID__c = 123456);
		GAM_Key_Value__c key1=  (GAM_Key_Value__c)TestDARTCodeCoverage.createKeyOrValueOrAS('k','TSK1','DE','33333333');   //new GAM_Key_Value__c( Name='TestKey1', Key__c='TSK1',  Key_Value_Name__c='TestKey1', Key_Value__c='TestKey1');
		Placement__c plc = new Placement__c(Name='test placement', Dart_ID__c=11111);

		insert new List<SObject>{t1,content,device,geo,con1,key1,plc};

		TargetingContentAssociation__c targetingContent = new TargetingContentAssociation__c(Targeting__c = t1.Id, TargetingContent__c = content.Id);		 
		TargetingGeographyAssociation__c tag = new TargetingGeographyAssociation__c(Targeting__c = t1.Id,Geography__c=geo.Id);
		TargetingKeyValueAssociation__c takv = new TargetingKeyValueAssociation__c(Targeting__c = t1.Id, GAM_Key_Value__c=key1.Id); 
		TargetingDeviceAssociation__c tadv = new TargetingDeviceAssociation__c(Targeting__c = t1.Id,Device__c = device.Id);
		TargetingConnectionAssociation__c tacn = new TargetingConnectionAssociation__c(Targeting__c = t1.Id,Connection__c = con1.Id);
		TargetingFrequencyAssociation__c tafre = new TargetingFrequencyAssociation__c(Targeting__c = t1.Id);
		PlacementTargetingAssociation__c tat = new PlacementTargetingAssociation__c(Targeting__c = t1.Id,Placement__c=plc.id);
		
		insert new List<SObject>{targetingContent,tag,takv,tadv,tacn,tafre,tat};	

			Account account = TST_DataGenerator.generateAccount();
			insert account;
			Opportunity opp = TST_DataGenerator.generateOpp(account.Id);
			insert opp;
			//media = TST_DataGenerator.generateMediaPlan(opp);
			//insert media;

			/*IO__c io = new IO__c(Name ='test io');
			insert io;*/
			//Quote quote = TST_DataGenerator.generateQuote(opp.Id, media.Id);
			Quote quote =  new Quote(
					Name = 'Quote Test',
					OpportunityId = opp.Id,
					Pricebook2Id=Test.getStandardPriceBookId()
					);

			//quote.IO__c = io.Id;
			insert quote;
			Product2 product = TST_DataGenerator.generateProduct();
			insert product;
			PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(product.Id,null);
			insert pbe;
			
			Package__c p1 = new Package__c(Name='p1');
			insert p1;

			Product_Package__c pp1 = new Product_Package__c(Product__c=product.Id,Package__c=p1.Id);
			insert pp1;

			QuoteLineItem qli1 = new QuoteLineItem();
			qli1.Product2Id = product.Id;
			qli1.QuoteId = quote.Id;
			qli1.Quantity = 20;
			qli1.Quantity__c = 20;
			qli1.UnitPrice = 10;
			qli1.Targeting__c = t1.Id;
			qli1.PricebookEntryId = pbe.Id;

			QuoteLineItem  qli2 = qli1.clone(true);

			insert new QuoteLineItem[]{qli1,qli2};

			mapResult.put('t1',t1);
			mapResult.put('qli1',qli1);
			mapResult.put('qli2',qli2);			 
	}

	static testMethod void testCopy1()
	{ 
		setUpData();
		//System.debug('>>mapResult1: '+mapResult);

		Targeting__c t1 = (Targeting__c)mapResult.get('t1');
		QuoteLineItem qli1 = (QuoteLineItem)mapResult.get('qli1');
		QuoteLineItem qli2 = (QuoteLineItem)mapResult.get('qli2');

		Test.startTest();

			GW_Targeting.initPredefinedTargetings(qli1);
			GW_Targeting.copyTargeting(new Set<String>{t1.Id});

		Test.stopTest();
	}
	static testMethod void testCopy2()
	{
		setUpData();
		Targeting__c t1 = (Targeting__c)mapResult.get('t1');
		QuoteLineItem qli1 = (QuoteLineItem)mapResult.get('qli1');
		QuoteLineItem qli2 = (QuoteLineItem)mapResult.get('qli2');

		Test.startTest();

			GW_Targeting.copyTargetings(qli1.Id, new String[]{qli2.Id});

		Test.stopTest();
	}
	static testMethod void testCopyPkg1()
	{
		setUpData();
		Targeting__c t1 = (Targeting__c)mapResult.get('t1');
		QuoteLineItem qli1 = (QuoteLineItem)mapResult.get('qli1');
		QuoteLineItem qli2 = (QuoteLineItem)mapResult.get('qli2');

		Test.startTest();

			GW_Targeting.copyProdPackageTargetingToLine(t1.Id, new Set<String>{qli1.Id});
		
		Test.stopTest();
	}
	static testMethod void testCopyPkg2()
	{
		setUpData();
		Targeting__c t1 = (Targeting__c)mapResult.get('t1');
		QuoteLineItem qli1 = (QuoteLineItem)mapResult.get('qli1');
		QuoteLineItem qli2 = (QuoteLineItem)mapResult.get('qli2');

		Test.startTest();

			Map<String,String> mapQli2Targeting = new Map<String,String>{'0'=>t1.Id};

			GW_Targeting.copyProdPackageTargetingToLine(mapQli2Targeting);
		
		Test.stopTest();
	}
}