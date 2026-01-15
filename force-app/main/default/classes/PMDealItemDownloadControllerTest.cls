@isTest
private class PMDealItemDownloadControllerTest {
    @testSetup
    static void setup(){
    	byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
    }

    static testMethod void test_getPMDealItemDownloadExcel()
   {
		Account ac = new Account(Name='Test Seller',EBH_VATNumber__c='1122334455');
        ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
        insert ac;
		 
   		Date myDate = Date.today().addDays(30);

        RecordType rt_PMdeal = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'PM_Deal');
        RecordType rt_PMDCA = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Promotions_Manager_Deals');
        Deal_Contract_Agreement__c dca = new Deal_Contract_Agreement__c(Deal_Site__c='0', RecordTypeId = rt_PMDCA.Id,Status__c='In Progress');
        insert dca;
        
        EBH_Deal__c d1 = new EBH_Deal__c(Deal_Contract_Agreement__c=dca.Id,EBH_DealSiteId__c='0', RecordTypeId = rt_PMdeal.Id, EBH_BusinessName__c=ac.Id,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay(),EBH_DealEndDate__c = myDate,EBH_Status__c='New' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_eBayItemID__c='123456789001',EBH_SellerPrice__c=20);
        insert d1;

        Test.startTest();
            PageReference pageRef = new PageReference('/apex/PMDealItemDownloadPage');
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('id',dca.Id);

            PMDealItemDownloadController controller = new PMDealItemDownloadController();
            PMDealItemDownloadController.getPMDealItemDownloadExcel(dca.Id);
        
        Test.stopTest();
        
   }

}