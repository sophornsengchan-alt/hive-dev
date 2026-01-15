@IsTest
private with sharing class BulkConvertDealContrTest {
	@TestSetup
	private static void setUp(){
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        ID dealNAUnsubRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V3').Id;
        RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        Account ac = new Account(Name='Seller',EBH_VATNumber__c='VAT1111',RecordTypeID = sellerRecordType.Id,NA_Deal_Program_Vetted__c=true);
		insert ac;

		Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
								FirstName='firstname',Salutation='Mr.',LastName='test1',
								email='test1@test.com' , AccountId = ac.Id,
								Contact_Role__c='Deals',
								recordtypeId = contactRecordTYpe.Id);
		insert contact1;

		Deal_Contract_Agreement__c dc = new Deal_Contract_Agreement__c(RecordTypeId=ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals').Id);
        insert dc;

		EBH_Deal__c d1a = new EBH_Deal__c( 
			EBH_SellerPrice__c=1000
			, EBH_SoldItems__c=2
			, EBH_Vertical__c='Soft Home'
			, EBH_DealSiteId__c='0'
			, EBH_Status__c='New'
			, EBH_Category__c='Gold'
			, EBH_ProductTitle__c='product 1'
			, EBH_Quantity__c=1
			, EBH_DealPrice__c = 200
			, EBH_DealFormat__c = 'iji'
			, EBH_DealStartDate__c = Date.today()+1
			, EBH_DealEndDate__c = Date.today()+30
			, EBH_SellerEmail__c ='dd@d.com'
			, EBH_MaximumPurchases__c =1
			, EBH_BusinessName__c = ac.Id
			, Subsidy_Running__c = 10
			, EBH_Payout_SI__c = 10
			, recordtypeId = dealNAUnsubRecordTypeId
			, EBH_eBayItemID__c='123456789000'
			, Seller_Approver_1__c=contact1.Id
			,Deal_Contract_Agreement__c = dc.Id
		);
		insert d1a;
	}
    @IsTest
    private static void apexInitRecordListTest(){
        Test.startTest();
			List<EBH_Deal__c> listDeal = [SELECT Id,Deal_Contract_Agreement__c FROM EBH_Deal__c];
            Map<String,Object> result = BulkConvertDealContr.apexInitRecordList(listDeal[0].Id+'',listDeal[0].Deal_Contract_Agreement__c);
        Test.stopTest();
		System.assertEquals(true, result.get('isBulkFromDCA'), 'Bulk Subsidize Deal on DCA');
    }
    @IsTest
    private static void apexSaveRecordListTest(){
        List<EBH_Deal__c> listDeal = [SELECT Id,EBH_DealPrice__c,EBH_SellerPrice__c FROM EBH_Deal__c];
        Test.startTest();
            String listStr = JSON.serialize(listDeal);
            Map<String,Object> result = BulkConvertDealContr.apexSaveRecordList(listStr, true);
        Test.stopTest();
    }
    
}