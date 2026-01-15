/***************************************************************************************************************************************
@ Change history: 29.09.2022 / Chetra Sarom / US-0012486 - Fix failing test class CMP_RedirectorControllerTest
@ Change history:  13.12.2023 / Vimean Heng / Fix Apex CPU Limit.
***************************************************************************************************************************************/

@isTest
public class CMP_Calc_ControllerTest {
     
    @IsTest
    static void testInit(){
        Map<String,Object> mapData = setupData();        

        Quote q1 = (Quote)mapData.get('q1');

        Test.startTest();
            Map<String,Object> mapResult = CMP_Calc_Controller.apexInitCMP(q1.Id,'');
            System.assertEquals('ok', mapResult.get('status')+'', 'query success');
            System.assertEquals(1, ((List<Object>)mapResult.get('listItem')).size(), '1 normal + 1 package item');

            CMP_Calc_Controller.LineItem tmp = new CMP_Calc_Controller.LineItem();
        Test.stopTest();
        
    }

    @IsTest
    static void testUpdate(){
        Map<String,Object> mapData = setupData();
        Quote q1 = (Quote)mapData.get('q1');
        QuoteLineItem item1 = (QuoteLineItem)mapData.get('item1');
        Map<String,Object> mapResult = CMP_Calc_Controller.apexInitCMP(q1.Id,item1.Id);        

        Test.startTest();
        
        mapResult = CMP_Calc_Controller.apexSaveItems(q1.Id,JSON.serialize(mapResult.get('listItem')));
        System.assertEquals('ok', mapResult.get('status')+'', 'update success');

        Test.stopTest();
        
    }
    /********************************************************************************************************
    @ Change history: 29.09.2022 / Chetra Sarom / US-0012486 - Fix failing test class CMP_RedirectorControllerTest 
    @ Change history:  13.12.2023 / Vimean Heng / US-0014430 / Fix Apex CPU Limit
    ********************************************************************************************************/
    public static Map<String,Object> setupData()
    {
        byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = true, byPass_WFRule__c = true,ByPass_Validation__c=true);
        insert bp;
        // 29.09.2022 / Chetra Sarom / US-0012486
        RecordType rtAdvertiser = [SELECT id FROM recordType WHERE name = 'Advertiser' AND sobjectType = 'Account'];
        Account acc = new Account(
            Name = 'acc1xxyyxx yxx yxxee',
            Rating= 'Hot', 
            Industry= 'Agency/Advertising', 
            Brand_Segment__c= 'Indirect', 
            Country_Code__c= 'AU',
            recordTypeid = rtAdvertiser.id,
            Record_Type_Text__c = 'Advertiser'
        );
        //end - 29.09.2022 / Chetra Sarom / US-0012486
        insert acc;
         
        
        RecordType recPackage = [Select Id From RecordType Where SObjectType='Product2' and Name='Package'];
        Product2 pro1 = new Product2(IsActive=true,Name='test pkg',Variable_CPM_price__c=true,RecordTypeId=recPackage.Id);         
        Product2 pro2 = new Product2(IsActive=true,Name='test');     
        insert new Product2[]{pro1,pro2};

        PricebookEntry pbe1 =  new PricebookEntry(pricebook2id = Test.getStandardPricebookId(), product2id = pro1.id,unitprice=1.0, isActive=true);
        PricebookEntry pbe2 =  new PricebookEntry(pricebook2id = Test.getStandardPricebookId(), product2id = pro2.id,unitprice=2.0, isActive=true);
        PricebookEntry pbe3 =  new PricebookEntry(pricebook2id = Test.getStandardPricebookId(), product2id = pro2.id,unitprice=4.0, isActive=true);

       
        insert new PricebookEntry[]{pbe1,pbe2};
        
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Probability = 10,
            StageName = '10% - Angebot ohne Anfrage',
            CloseDate = system.today(),
            Start_Date__c = system.today(),
            End_Date__c = system.today(),
            Name = 'CPM Rechner Test Opportunity',
            CurrencyIsoCode=pbe1.CurrencyIsoCode
        );
        insert opp;

        Quote q1 = new Quote(Name='Quote 1',OpportunityId=opp.Id);
        insert q1;

        QuoteLineItem item1 = new QuoteLineItem(QuoteId=q1.Id,Product2Id=pro1.Id,PricebookEntryId=pbe1.Id,Quantity=10,UnitPrice=0.9,SalesPriceNet__c=0.9,Quantity__c=10);
        insert item1;
        QuoteLineItem item2 = new QuoteLineItem(QuoteId=q1.Id,Product2Id=pro2.Id,package_line_item__c=item1.Id,PricebookEntryId=pbe2.Id,Quantity=20,UnitPrice=0.5,SalesPriceNet__c=0.5,Quantity__c=20);
        QuoteLineItem item3 = new QuoteLineItem(QuoteId=q1.Id,Product2Id=pro2.Id,package_line_item__c=item1.Id,PricebookEntryId=pbe2.Id,Quantity=40,UnitPrice=1,SalesPriceNet__c=1,Billing_category__c=CMP_Calc_Controller.BILLING_CAT_FIXPRICE,Quantity__c=40);
        insert new QuoteLineItem[]{item2,item3};
          
        Map<String,Object> mapResult = new Map<String,Object>();
        mapResult.put('acc',acc);
        mapResult.put('pro1',pro1);
        mapResult.put('pro2',pro2);
        mapResult.put('pbe1',pbe1);
        mapResult.put('pbe2',pbe2);
        mapResult.put('opp',opp);
        mapResult.put('q1',q1);
        mapResult.put('item1',item1);
        mapResult.put('item2',item2);
        return mapResult;

    }
}