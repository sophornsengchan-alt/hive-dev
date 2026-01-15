@IsTest
private class PrimaryQuoteActionControllerTest {
     
    @IsTest
    static void testApexInit(){
       
        Map<String,Object> mapData = createTestData();

        Test.startTest();
            
            Quote q1 = (Quote)mapData.get('q1');
            Map<String,Object> result = PrimaryQuoteActionController.apexInit(q1.Id);
            System.assertEquals('ok', result.get('status')+'', 'init success');
            
        Test.stopTest();
        
    }

    @IsTest
    static void testApexMarkPrimary(){
        
        Map<String,Object> mapData = createTestData();

        Test.startTest();
            
            Quote q2 = (Quote)mapData.get('q2');
            Map<String,Object> result = PrimaryQuoteActionController.apexMarkPrimary(q2.Id);
            System.assertEquals('ok', result.get('status')+'', 'init success');
            Quote q2A = [Select Id,Primary_Quote__c From Quote Where Id=:q2.Id];
            System.assertEquals(true, q2A.Primary_Quote__c, 'Primary successfully marked');

        Test.stopTest();
        
    }

    private static Map<String,Object> createTestData()
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        RecordType advRecordType = ApexUtil.getRecordTypeByName('Account','Advertiser');
        RecordType directRecordType = ApexUtil.getRecordTypeByName('Opportunity','eBay');

        Account acc = new Account(Name='acc test', RecordTypeId=advRecordType.Id, Record_Type_Text__c = 'Advertiser');
        insert acc;
        Opportunity opp = new Opportunity(RecordTypeId=directRecordType.Id, Name='Test opp',AccountId=acc.Id,StageName='Qualified Meeting',CloseDate=System.today().addDays(10));
        insert opp;
        Quote q1 = new Quote(OpportunityId=opp.Id,Name='Q1');
        Quote q2 = new Quote(OpportunityId=opp.Id,Name='Q2');
        insert new Quote[]{q1,q2};

        mapResult.put('acc',acc);
        mapResult.put('opp',opp);
        mapResult.put('q1',q1);
        mapResult.put('q2',q2);

        return mapResult;
    }
}