/**
 * @author: GIS-DevTeam
 * @createdDate: 28/June/2018
 * @description: 
 *  - test class of LPC_KeyValuesSelectorController
 * @references: 
 *  - 
 * @changeLog:
 *
 * -------------------------------------------------------------------------------------
 * Change history: 13.06.2025 / Sophal Noch / US-0012504 - 2. Deletion of custom objects
 */
@isTest
private class LPC_KeyValuesSelectorControllerTest {
	public static Account account;
	public static Opportunity opp;
	public static Media_Plan__c media;
	public static QuoteLineItem quoteLineItem;

    @testSetup static void setup(){
    	TestDARTCodeCoverage.createTestUser();
        TestDARTCodeCoverage.createCredential('DE');
    }

    /*********************************************************************************************************************************
    @ Method:              testKeyValueSelector  
    @ Migrated From:       Advertising Instance (Legacy Code)
    @ Purpose:             test method for GAM KeyValue
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
    *********************************************************************************************************************************/    
    static testMethod void testKeyValueSelector() {

    	 //create new targeting template
        Id RecId = Schema.SObjectType.Targeting__c.getRecordTypeInfosByName().get('Template').getRecordTypeId();
        Targeting__c targ = new Targeting__c();
        targ.Description__c = 'Tageting Template';
        targ.KeyValueString__c = '(Audience Segment=red) AND (car=bmw)';
        targ.RecordTypeId = RecId;
        


        // GAM_Key_Value__c key1= (GAM_Key_Value__c)TestDARTCodeCoverage.createKeyOrValueOrAS('k','TSK1','DE','33333333'); // new GAM_Key_Value__c( Name='TestKey1', Key__c='TSK1',  Key_Value_Name__c='TestKey1', Key_Value__c='TestKey1');
        // GAM_Key_Value__c key2=  (GAM_Key_Value__c)TestDARTCodeCoverage.createKeyOrValueOrAS('k','TSK2','DE','44444444');//new GAM_Key_Value__c( Name='TestKey2', Key__c='TSK2',  Key_Value_Name__c='TestKey2', Key_Value__c='TestKey2', Dart6_ValueId__c=2.5, Node_ID__c= key1.id);
        // GAM_Key_Value__c key3=  (GAM_Key_Value__c)TestDARTCodeCoverage.createKeyOrValueOrAS('k','TSK3','DE','55555555');//new GAM_Key_Value__c( Name='TestKey3', Key__c='TSK3',  Key_Value_Name__c='TestKey3', Key_Value__c='TestKey3', Node_ID__c= key2.id);
        // list<GAM_Key_Value__c> lstKeyToInsert =  new list<GAM_Key_Value__c>{ key1, key2, key3 };        
        // insert lstKeyToInsert;
        
        List<SObject> keyvalues = TestDARTCodeCoverage.createTargetingKVHierarchy();

        


        Site__c siteDE = TestDARTCodeCoverage.createSite('DE');
        insert siteDE;
        Targeting__c t = new Targeting__c(TempBinder__c = true, KeyValueString__c='(((uz=033) OR (uz=75009) OR (uz=75010) OR (uz=75013) OR (uz=75011)) AND (ms=M))');     
        
        insert new Targeting__c[]{targ,t};

        TargetingKeyValueAssociation__c tas0 = new TargetingKeyValueAssociation__c(Targeting__c=targ.Id,GAM_Key_Value__c=keyvalues[0].get('Id')+'');
        TargetingKeyValueAssociation__c tas1 = new TargetingKeyValueAssociation__c(Targeting__c=targ.Id,GAM_Key_Value__c=keyvalues[1].get('Id')+'');
        TargetingKeyValueAssociation__c tas3 = new TargetingKeyValueAssociation__c(Targeting__c=t.Id, GAM_Key_Value__c=keyvalues[0].get('Id')+'');
        
        insert new TargetingKeyValueAssociation__c[]{tas0,tas1,tas3};
        
        account = TST_DataGenerator.generateAccount();
        insert account;

        opp = TST_DataGenerator.generateOpp(account.Id);
        insert opp;
        //media = TST_DataGenerator.generateMediaPlan(opp);
        //insert media;
        Quote quote = TestDARTCodeCoverage.generateQuote(opp.Id);
        insert quote;
        Product2 product = TST_DataGenerator.generateProduct();
        product.Available_Key_Values__c = 'Audience Segment;car';
        product.Site__c = siteDE.Id;
        insert product;
        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(product.Id,null);
        insert pbe;

        quoteLineItem = new QuoteLineItem();
        quoteLineItem.Product2Id = product.Id;
        quoteLineItem.QuoteId = quote.Id;
        quoteLineItem.Quantity = 20;
        quoteLineItem.Quantity__c = 20;
        quoteLineItem.UnitPrice = 10;
        quoteLineItem.PricebookEntryId = pbe.Id;
        insert quoteLineItem;

    	Test.startTest();

    	String quoteLineItemId = quoteLineItem.Id + '';
    	RemoteResponse response = LPC_KeyValuesSelectorController.initKeyN(quoteLineItemId);
    	System.assertEquals(RemoteResponse.STATUSCODE_OK, response.statusCode);
        System.assert(response.content != null);


        update new Targeting__c(Id=t.id, KeyValueString__c='(kw=eye) OR (kw=renovation)');
        update new QuoteLineItem(Id=quoteLineItemId, Targeting__c = t.id);
        response = LPC_KeyValuesSelectorController.initKeyN(quoteLineItemId);

        System.assertEquals(RemoteResponse.STATUSCODE_OK, response.statusCode);
        System.assert(response.content != null);


        RemoteResponse resVal = LPC_KeyValuesSelectorController.initValueN(keyvalues[0].get('Id')+'', 'bmw', quoteLineItemId);
        System.assertEquals(RemoteResponse.STATUSCODE_OK, resVal.statusCode);

        RemoteResponse resVal2 = LPC_KeyValuesSelectorController.initValueN(DART6_KeyValueController.KV_TYPE_AudienceSegment, 'red', quoteLineItemId);
        System.assertEquals(RemoteResponse.STATUSCODE_OK, resVal2.statusCode);

         //List key value set
        List<LPC_KeyValuesSelectorController.KeyWrp> keyList = new List<LPC_KeyValuesSelectorController.KeyWrp>();
        LPC_KeyValuesSelectorController.KeyWrp keyOne = new LPC_KeyValuesSelectorController.KeyWrp(keyvalues[0].get('Id')+'', keyvalues[0].get('Name')+'', keyvalues[0].get('Name')+'');
        keyList.add(keyOne);
        
        List<LPC_KeyValuesSelectorController.ValueWrp> valueList = new List<LPC_KeyValuesSelectorController.ValueWrp>();
        LPC_KeyValuesSelectorController.ValueWrp valueOne = new LPC_KeyValuesSelectorController.ValueWrp(keyvalues[3].get('Id')+'', String.valueOf(keyvalues[3].get('GAM_Id__c'))+'', keyvalues[3].get('Name')+'');
        valueList.add(valueOne);
        
        LPC_KeyValuesSelectorController.KeyValueWrp kvWrp = new LPC_KeyValuesSelectorController.KeyValueWrp();
        kvWrp.index = 0;
        kvWrp.keyone = keyOne;
        kvWrp.operator2 = 'AND';
        kvWrp.operator3='OR';
        kvWrp.valueN = valueList;
        
        List<LPC_KeyValuesSelectorController.KeyValueWrp> kvWrpList = new List<LPC_KeyValuesSelectorController.KeyValueWrp>();
        kvWrpList.add(kvWrp);
        
        LPC_KeyValuesSelectorController.KeyValueSetWrp kvSetWrp = new LPC_KeyValuesSelectorController.KeyValueSetWrp();
        kvSetWrp.index = 0;
        kvSetWrp.valueListSel = new List<LPC_KeyValuesSelectorController.ValueWrp>();
        kvSetWrp.keyOneSel = new LPC_KeyValuesSelectorController.KeyWrp(null, '', '');
        kvSetWrp.keyValueN = kvWrpList;
        
        List<LPC_KeyValuesSelectorController.KeyValueSetWrp> keyValueSetWrpList = new List<LPC_KeyValuesSelectorController.KeyValueSetWrp>();
        keyValueSetWrpList.add(kvSetWrp);
        
        
        String keyValueSetList = JSON.serialize(keyValueSetWrpList);
        RemoteResponse saveKeyValue = LPC_KeyValuesSelectorController.saveKeyValue(quoteLineItemId, keyValueSetList,null);
        System.assertEquals(saveKeyValue.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(saveKeyValue.content != null);
                
        //Targeting Template
        RemoteResponse saveKeyValueTemp = LPC_KeyValuesSelectorController.saveKeyValueTemplate(t.Id, keyValueSetList);


        RemoteResponse loadKeyValueTemp = LPC_KeyValuesSelectorController.loadKeyValueTemplate(quoteLineItemId,targ.Id);
        System.assertEquals(loadKeyValueTemp.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(loadKeyValueTemp.content != null);


    	Test.stopTest(); 
    }
   
}