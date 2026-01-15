/*********************************************************************************************************************************
@ Class:         BatchUpdateDealStatusTest
@ Version:       1.0
@ Author:        Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       US-0016569 - Test Class for BatchUpdateDealStatus
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.03.2025 / Sovantheany Dim / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
private class BatchUpdateDealStatusTest {

    @testSetup
    static void setup(){   
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account eBaySeller1 = new Account (Name='Test eBaySeller for batch Cancel Deal',RecordTypeID = sellerRecordType.Id, NA_Deal_Program_Vetted__c = true);
        insert eBaySeller1;
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller1.Id, Contact_Role__c = 'Deals');
        insert contact1;
        RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(RecordTypeId=ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals').Id);
        insert ndca;
        byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'EBH_Deal__c', byPass_Trigger__c = true, byPass_WFRule__c = true,ByPass_Validation__c=true);
        insert bp;
        Time myTime = Time.newInstance(1, 1, 1, 1);
        Date myStartDate = System.Today().adddays(-2);
        Date myEndDate = System.Today().adddays(4);
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
        for(Integer i = 1; i < 3; i++){
        	EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i, 
	        Seller_Approver_1__c = contact1.Id,
	        EBH_BusinessName__c=eBaySeller1.ID,
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
            Deal_Contract_Agreement__c = ndca.id,
            EBH_DealSiteId__c = '0',
            EBH_MaximumPurchases__c=2);
            lstDeal.add(d1);
        }
        insert lstDeal;
    }

    @isTest
    static void test_UpdatedStatus2Cancelled() {
        List<Deal_Contract_Agreement__c> lstDca = [select id from Deal_Contract_Agreement__c limit 1];
        Test.startTest();
        BatchUpdateDealStatus b0 = new BatchUpdateDealStatus(new set<String>{lstDca[0].Id});
        BatchUpdateDealStatus b = new BatchUpdateDealStatus();
        Database.executeBatch(b);
        Test.stopTest();
        List<EBH_Deal__c> lstDeal = [SELECT Id, EBH_Status__c FROM EBH_Deal__c WHERE EBH_Status__c = 'Cancelled'];
        System.assertEquals(2, lstDeal.size());
    }
}