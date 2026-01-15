/*********************************************************************************************************************************
@ Class:          CSVExporterControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0011695 - ADS- CSV upload of attribution data on product
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  27.09.2022 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
private class CSVExporterControllerTest {
    private static RecordType rtAdvertiser = [SELECT id FROM recordType WHERE name = 'Advertiser' AND sobjectType = 'Account'];

    @isTest
    static void testGetCSVFile(){

        byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem Opportunity', byPass_Trigger__c = false, byPass_WFRule__c = true);
        insert bp;

        Account account = new Account(
    		Name = 'Account test',
    		BillingStreet = 'Test',
            BillingPostalCode = 'test',
            BillingCity = 'test',
            BillingState = 'test',
            BillingCountry = 'Germany',
            Phone = '+1234567890',
            Record_Type_Text__c = 'Advertiser',
            recordTypeid = rtAdvertiser.id
		);
        insert account;

        Opportunity opp = new Opportunity(AccountId = account.Id, Name = 'Test Opp',StageName='Qualified Meeting',CloseDate=Date.newInstance( 2021, 1, 1),RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id);
        insert opp;

        Pagereference page = Page.CSVExporter;
        Test.setCurrentPage(page);
        page.getParameters().put('template','Ad_Product_Export');
        page.getParameters().put('fv',opp.Id);
        page.getParameters().put('retUrlId',opp.Id);
        page.getParameters().put('prId',opp.Id);

        CSVExporterController contr = new CSVExporterController();
        System.assertNotEquals(null, contr.mapResult);
        contr.doRedirect();
    }
}