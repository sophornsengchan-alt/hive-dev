@isTest
private class QuoteGenerateAndDocusignControllerTest {

        @isTest
        private static void test() {
    
    
            RecordType rt = [SELECT id FROM recordType WHERE sobjectType = 'Account' AND developername = 'Advertiser'];
    
            Account a = new Account(name='TEST', recordTypeID = rt.id, Record_Type_Text__c='Advertiser');
            insert a;
    
            Opportunity o = new Opportunity(Name = 'TEST', stageName = 'Closed Won', closeDate = System.today(), accountId = a.id);
            insert o;
    
            Quote q = new Quote(name='TEST', opportunityId = o.id);
            insert q;
    
            PageReference newPage = page.quote_redirector_ds;
            newPage.getParameters().put('page', 'QuoteUK2018');
            newPage.getParameters().put('Id', q.id);
            newPage.getParameters().put('nonce', 'Test');
            Test.setCurrentPageReference(newPage);
    
            QuoteGenerateAndDocusignController controller = new QuoteGenerateAndDocusignController();
            QuoteGenerateAndDocusignController.doGenerate();


            List<ContentVersion> cv = [SELECT id FROM contentVersion];
            System.assertEquals(1, cv.size());
            
        }
    }