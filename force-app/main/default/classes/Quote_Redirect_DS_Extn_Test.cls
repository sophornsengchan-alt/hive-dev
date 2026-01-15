@isTest
private class Quote_Redirect_DS_Extn_Test {
    
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
        newPage.getParameters().put('nonce', 'Test');
        Test.setCurrentPageReference(newPage);

        ApexPages.StandardController std = new ApexPages.StandardController(q);
        Quote_Redirect_DS_Extn controller = new Quote_Redirect_DS_Extn(std);
        System.assertEquals('Test', controller.nonce);
        
    }
}