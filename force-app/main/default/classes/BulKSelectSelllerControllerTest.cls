/*********************************************************************************************************************************
@ Class:          BulKSelectSelllerController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0014207 - ADS - Cohort - Bulk Deactivate Sellers
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  17.10.2023 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
private class BulKSelectSelllerControllerTest {

    static BoB__c bob;
    static BoB_Seller__c bs;

    static void setUpData()
    {
         	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
             Account acc = new Account(
                Name='Test Account',
                RecordTypeId=sellerRecordType.Id,
                Managed_Type__c = 'LTTM Managed'
            );
        
            insert new List<Account>{acc};
    
            Contact cont = new Contact(LastName='Last',AccountId=acc.Id);
            insert new List<Contact>{cont};
    
            RecordType bobAdsRecordType = ApexUtil.getRecordTypeByName('BOB__c','Advertising_Cohort');
            bob = new BoB__c(
                Status__c='Draft',
                EBH_BOBCNTRY__c='3',
                EBH_BOBVertical__c='Fashion',
                LTTM_Group__c='test group',
                RecordTypeId=bobAdsRecordType.Id,
                ownerId = UserInfo.getUserId()
            );
            insert new List<BoB__c>{bob};
    
            RecordType bobSellerAdsRecordType = ApexUtil.getRecordTypeByName('BoB_Seller__c','Advertising');
    
            BoB_Seller__c bs = new BoB_Seller__c(
                RecordTypeId = bobSellerAdsRecordType.Id,
                Parent_Seller__c=acc.Id,
                Account_Manager__c=UserInfo.getUserId(),
                Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,
                Seller__c=acc.Id,
                BoB__c = bob.Id,
                EBH_BOBSegment__c='Offsite Ads',
                BoB_Subsegment__c='Platin',
                Call_Outcome__c='Next call scheduled',
                Call_Attempt__c = 0
            );
    
            insert new List<BoB_Seller__c>{bs};
    
           
    }

    /*********************************************************************************************************************************
    @ Method:         test_BulKSelectSelllerController
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014207 - ADS - Cohort - Bulk Deactivate Sellers
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  17.10.2023 / Sophal Noch / Created the Method.
    *********************************************************************************************************************************/
    @isTest
    private static void test_BulKSelectSelllerController(){
        // to test constructor of BulKSelectSelllerController
        setUpData();

        Test.setCurrentPage(Page.BulKSelectSelller);
        ApexPages.currentPage().getParameters().put('id',bob.Id);

        List<BoB_Seller__c> lstbs = new List<BoB_Seller__c>{bs};
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstbs);
        sc.setSelected(lstbs);
        BulKSelectSelllerController ctrl = new BulKSelectSelllerController(sc);
        System.assertEquals(true, ctrl.isAdvertising);
    }
}