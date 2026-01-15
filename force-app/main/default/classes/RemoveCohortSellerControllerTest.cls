/*********************************************************************************************************************************
@ Class:          RemoveCohortSellerControllerTest
@ Version:        1.0
@ Author:         
@ Purpose:        Test class for RemoveCohortSellerController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.08.2020 / Sreymeas Nao / Created the test class.
                : 30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
                : 11.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
*********************************************************************************************************************************/
@isTest
public class RemoveCohortSellerControllerTest {
    @testSetup static void setUp() {
		RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
        BoB__c bob = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='Spain',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = UserInfo.getUserId());
        insert bob;
        
        RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        
        BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        BoB_Seller__c bs1 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        List<BoB_Seller__c> lstBs = new List<BoB_Seller__c>{bs,bs1}; 
        insert lstBs;
    }
    
    static testMethod void removeSellers(){
        User admUsers = EBH_TestDataFactory.createUser('System Administrator');
        //admUsers.BoB_Country__c = '3';
        System.runAs(admUsers){
            List<BoB_Seller__c> lstBs = [select id from BoB_Seller__c];
        	Test.startTest();
                Test.setCurrentPage(Page.RemoveCohortSeller);
                ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstBs);
                sc.setSelected(lstBs);
                RemoveCohortSellerController tc = new RemoveCohortSellerController(sc);
                // tc.removeSellers(); // 30.01.2024 / Sophal Noch / US-0014277
            	tc.backToListView();
                // System.assert(tc.msg.contains(System.Label.RM_COHORSELLER_SUCCESS));
                System.assertEquals(true, tc.isInit); // 30.01.2024 / Sophal Noch / US-0014277
        	Test.stopTest();
        }
    }

}