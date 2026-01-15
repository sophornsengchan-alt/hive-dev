@isTest
private class DealFilterTest {
static testMethod void testDeal() {
	Id sellerRT_Id = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id;
	Account acc = new Account(Name='Seller',EBH_VATNumber__c='1122334455',recordtypeId=sellerRT_Id);
    insert acc;
	RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
    Contact con = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                  FirstName='firstname',Salutation='Mr.',LastName='test1',
                                  email='test1@test.com' , AccountId = acc.Id, 
                                  //EBH_Decision_Maker_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
                                  Contact_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - Use Contact_Role__c instead
                                  recordtypeId = contactRecordTYpe.Id);
    insert con;
    Deal_Statement__c statement = new Deal_Statement__c (name=acc.name + 'Statement');
    insert statement;      
    Date myDate = System.today();
    Time mytime = Time.newinstance(14,0,0,0);
    Id dealSTDRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c',DealFilter.RECTYPE_STD).Id;
    Id dealNARecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c',DealFilter.RECTYPE_NA).Id;
    EBH_Deal__c deal = new EBH_Deal__c(EBH_MaximumPurchases__c = 1, EBH_eBayItemID__c = '000000000010',EBH_BusinessName__c = acc.Id,Seller_Approver_1__c = con.Id,EBH_Status__c='Completed',RecordTypeId=dealNARecordTypeId,EBH_SellerPrice__c=10,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_DealStartDate__c=myDate,EBH_DealEndDate__c=myDate,EBH_DealSiteId__c = '0',EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product for update 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_DealFormat__c='Primary',deal_statement__c = statement.id);
    EBH_Deal__c deal2 = new EBH_Deal__c(EBH_MaximumPurchases__c = 1, EBH_eBayItemID__c = '000000000011',EBH_BusinessName__c = acc.Id,Seller_Approver_1__c = con.Id,EBH_Status__c='Completed',RecordTypeId=dealSTDRecordTypeId,EBH_SellerPrice__c=10,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_DealStartDate__c=myDate,EBH_DealEndDate__c=myDate,EBH_DealSiteId__c='77',EBH_Vertical__c='Fashion',EBH_Category__c='Baby',Sub_Category__c='Bedding', EBH_ProductTitle__c='product for update 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_DealFormat__c='Primary',deal_statement__c = statement.id);
    List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>{deal,deal2};
    insert lstDeal;
    Test.startTest();
	DealFilter dealFilter = DealFilter.getInstance(lstDeal, lstDeal);
	Test.stopTest();
	System.assert(dealFilter.getListNew_STD().size() == 1);
	System.assert(dealFilter.getListNew_NA().size() == 1);
	System.assert(dealFilter.getListOLD_STD().size() == 1);
	System.assert(dealFilter.getListOLD_NA().size() == 1);
	
	System.assert(dealFilter.getMapOld_STD().size() == 1);
	System.assert(dealFilter.getMapOld_NA().size() == 1);
	System.assert(dealFilter.getMapNew_STD().size() == 1);
	System.assert(dealFilter.getMapNew_NA().size() == 1);
	
}
}