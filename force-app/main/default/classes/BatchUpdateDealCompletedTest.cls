/*********************************************************************************************************************************
@ Class:         BatchUpdateDealCompletedTest
@ Version:       1.0
@ Author:        Vimean Heng (vimean.heng@gaea-sys.com)
@ Purpose:       US-0033060 - The Deals needs to be marked Completed past the Deal End Date
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.06.2025 / Vimean Heng / US-0033060 - The Deals needs to be marked Completed past the Deal End Date
----------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
private class BatchUpdateDealCompletedTest {
    @testSetup
    static void initData(){
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account eBaySeller1 = new Account (Name='Test eBaySeller for batch Cancel Deal',RecordTypeID = sellerRecordType.Id, NA_Deal_Program_Vetted__c = true);
        insert eBaySeller1;
        List<String> recordTypes = new List<String>{'Deal_V1', 'Deal_V2', 'Deal_V3'};
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
        Integer i = 0;
        for(String recordType : recordTypes) {
            RecordType rt = ApexUtil.getRecordTypeByName('EBH_Deal__c', recordType);
            Time myTime = Time.newInstance(1, 1, 1, 1);
            Date myStartDate = System.Today().adddays(-2);
            Date myEndDate = System.Today().adddays(-1);
            EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i, 
	        RecordTypeId= rt.Id,
            EBH_BusinessName__c=eBaySeller1.ID,
	        EBH_SellerPrice__c=20,
            EBH_DealPrice__c=5,
	        EBH_Quantity__c=2,
            EBH_DealStartDate__c=myStartDate,
	        EBH_DealEndDate__c=myEndDate,
            EBH_DealStartTime__c = myTime,
	        EBH_DealEndTime__c = myTime,
	        EBH_Status__c='Running',
            EBH_ProductTitle__c='product 1',
            EBH_DealSiteId__c = '77',
            EBH_MaximumPurchases__c=2);
            lstDeal.add(d1);
        
        }
        insert lstDeal;
    }
    @isTest
    static void updateToCompleted() {
        Test.startTest();
        Map<String,String> mapRecordTypeToStatus = new Map<String,String>{
        'Deal_V1' => 'Executed',
        'Deal_V2' => 'Completed',
        'Deal_V3' => 'Completed'
    };
        BatchUpdateDealCompleted b = new BatchUpdateDealCompleted();
        b.execute(null);
        Test.stopTest();
        List<EBH_Deal__c> lstDeal = [SELECT Id, EBH_Status__c,RecordType.DeveloperName FROM EBH_Deal__c WHERE RecordType.DeveloperName IN :mapRecordTypeToStatus.keySet()];
        System.assertEquals(3, lstDeal.size(),'The number of deals should be 3');
        for(EBH_Deal__c deal : lstDeal) {
            System.assertEquals(mapRecordTypeToStatus.get(deal.RecordType.DeveloperName), deal.EBH_Status__c, 'The status of the deal should be updated to ' + mapRecordTypeToStatus.get(deal.RecordType.DeveloperName));
        }
    }
}