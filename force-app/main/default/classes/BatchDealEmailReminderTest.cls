/*********************************************************************************************************************************
@ Class:         BatchDealEmailReminderTest
@ Version:       1.0
@ Author:        Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       US-0026100 - Contarct Signature reminder email before Cancelling the Deals
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.05.2025 / Sovantheany Dim / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
private class BatchDealEmailReminderTest {
    @testSetup
    static void setup(){   
        EBH_TestDataFactory.setUpCustomSettings();   
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;

        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        List<Account> lsteBaySeller = new List<Account>();
        for(Integer i = 0; i < 3; i++){
            Account eBaySeller1 = new Account (Name='Test eBaySeller for batch Cancel Deal '+i,RecordTypeID = sellerRecordType.Id, NA_Deal_Program_Vetted__c = true);
            lsteBaySeller.add(eBaySeller1);
        }
        insert lsteBaySeller;
        RecordType contactDWHRecordType = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
        List<Contact> lstCont = new List<Contact>();
        for(Integer i = 0; i < 3; i++){
            Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = lsteBaySeller[i].Id, Contact_Role__c = 'Deals',RecordTypeID = contactDWHRecordType.Id);
            lstCont.add(contact1);
        }
        insert lstCont;
        RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
        List<Deal_Contract_Agreement__c> lstDCA = new List<Deal_Contract_Agreement__c>();
        for(Integer i = 0; i < 3; i++){
            Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(RecordTypeId=ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals').Id,eBay_Seller__c=lsteBaySeller[i].ID);
            lstDCA.add(ndca);
        }
        insert lstDCA;
        Time myTime = Time.newInstance(1, 1, 1, 1);
        Date myStartDate = System.Today();
        Date myEndDate = System.Today().adddays(4);
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
        for(Integer i = 0; i < 3; i++){
        	EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i, 
	        Seller_Approver_1__c = lstCont[i].Id,
	        EBH_BusinessName__c=lsteBaySeller[i].ID,
	        RecordTypeId=subDealRecordType.Id,
	        EBH_SellerPrice__c=20,
            EBH_DealPrice__c=5,
	        EBH_Quantity__c=2,
            EBH_DealStartDate__c=myStartDate,
	        EBH_DealEndDate__c=myEndDate,
            EBH_DealStartTime__c = myTime,
	        EBH_DealEndTime__c = myTime,
	        EBH_Status__c='Sent to Seller',
            EBH_ProductTitle__c='product 1',
            Deal_Contract_Agreement__c = lstDCA[i].id,
            EBH_DealSiteId__c = '0',
            EBH_MaximumPurchases__c=2);
            lstDeal.add(d1);
        }
        insert lstDeal;
    }
    @isTest
    static void test_CreateSellerComm() {
        List<Deal_Contract_Agreement__c> lstDca = [select id from Deal_Contract_Agreement__c limit 1];
        System.debug('lstDeal : '+[select id,EBH_Status__c,EBH_DealStartDate__c,RecordType.DeveloperName,EBH_DealSiteId__c from EBH_Deal__c]);
        Test.startTest();
        BatchDealEmailReminder b0 = new BatchDealEmailReminder(new set<String>{lstDca[0].Id});
        BatchDealEmailReminder b = new BatchDealEmailReminder();
        Database.executeBatch(b);
        Test.stopTest();
        List<Seller_Communication__c> lstSellerCom = [select id,Name from Seller_Communication__c];
        System.assertEquals(3,lstSellerCom.size(),'3 seller com create because deal have the same seller');
        System.Assert(lstSellerCom[0].Name == BatchDealEmailReminder.SELLER_COMM_NAME, 'new seller comm name should be '+BatchDealEmailReminder.SELLER_COMM_NAME);
    }
}