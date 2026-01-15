/*********************************************************************************************************************************
@ Class:          DeactivateCohortSellerController
@ Version:        1.0
@ Author:         Chetra Sarom
@ Purpose:        14.07.2022/ US-0012010 - Add New Button "Deactivate Sellers" Button next to "Remove Sellers"
@ Change history: 17.10.2023 / Sophal Noch / US-0014363 - Ph 1 - Deactivate Sellers button
@               : 10.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
*********************************************************************************************************************************/
@isTest
public with sharing class DeactivateCohortSellerControllerTest {
    @testSetup static void setUp() {
        	RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
            BoB__c bob = new BoB__c(Status__c= 'BoB Active',EBH_BOBCNTRY__c='Spain',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = UserInfo.getUserId());
            insert bob;
            
            RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
            List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
            
            BoB_Seller__c bs = new BoB_Seller__c(Status__c= 'Inactive', RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            BoB_Seller__c bs1 = new BoB_Seller__c(Status__c= 'Inactive', RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            List<BoB_Seller__c> lstBs = new List<BoB_Seller__c>{bs,bs1}; 
            insert lstBs;    
    }
    
    static testMethod void deactivateSellers(){
        User admUsers = EBH_TestDataFactory.createUser('System Administrator');
        //admUsers.BoB_Country__c = '3';
        System.runAs(admUsers){
            List<BoB_Seller__c> lstBs = [select id from BoB_Seller__c];
        	Test.startTest();
                Test.setCurrentPage(Page.DeactivateCohortSeller);
                BoB__c bob = [select id from BoB__c limit 1];
                ApexPages.currentPage().getParameters().put('id', bob.Id); // 17.10.2023 / Sophal Noch /US-0014363
                ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstBs);
                sc.setSelected(lstBs);
                DeactivateCohortSellerController tc = new DeactivateCohortSellerController(sc);
                tc.isBatchRunning = false;
                for(BoB_Seller__c bs : lstBs){
                    bs.Deactivation_Reason__c = 'Below Standard';
                }
                update lstBs;
                tc.deactivationReason();
                tc.deactivateSellers();     
                System.assert(tc.msg.contains(System.Label.DEACTIVATE_COHORSELLER_SUCCESS));
        	Test.stopTest();
        }
    }

}