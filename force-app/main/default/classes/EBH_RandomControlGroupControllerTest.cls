/*********************************************************************************************************************************
@ Class:          EBH_RandomControlGroupControllerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_RandomControlGroupController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.05.2018 / NEHA LUND / Created the test class.
@ Change history:  14.12.2023 / Vimean Heng / Fix lock row.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_RandomControlGroupControllerTest {
    
    private static User currentUser = [ select Id, Name from User where Id = :UserInfo.getUserId() ];
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    @ Change history:  14.12.2023 / Vimean Heng / Fix lock row. currentUser is admin
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        //System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testCampaignMemberRefresh(); } 
        System.runAs(currentUser) { testCampaignMemberRefresh(); }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    @ Change history:  14.12.2023 / Vimean Heng / US-0014423 / Fix lock row.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        UserRole r = [select Id from UserRole where DeveloperName='Standard_Users' Limit 1];
        Profile p = [select id from Profile where name = 'Standard User' Limit 1];
        User su = [Select Id from User where UserRoleId = :r.Id Limit 1];
        su.IsActive =  true;
        //User su = EBH_TestDataFactory.createUser('Standard User');
        //su.UserRoleId = r.Id;
        //insert su;
        System.runAs(su) { testCampaignMemberRefresh(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testCampaignMemberRefresh
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) System should be able to create the Targeted Sellers based on the attachment
                                    uploaded on Seller List Snapshot record, It will delete previous Targeted Sellers &
                                    creates the new Targeted Sellers
                      COVERAGES (*) testCampaignMemberRefresh(): Creates the Seller records
                                    Attachment records on Seller List Snapshot object
                                    Attachment Trigger and Handler class
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testCampaignMemberRefresh() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        RecordType rt = EBH_TestDataFactory.getRecordTypeByName('Campaign','EBH_CampaignProgramme');
        
        RecordType rt1 = EBH_TestDataFactory.getRecordTypeByName('Campaign','EBH_CampaignRequest');
        Campaign campaignsp = new Campaign(Name = 'Test Campaign SP',recordTypeId = rt.Id);
        insert campaignsp;
        
        List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign1', 'UK', 'EBH_Campaign',campaignsp.id,'Feasibility');
        List<EBH_KPI__c> kpiRecords = EBH_TestDataFactory.createKPIRecords('Test');
        List<EBH_CampaignKPI__c> campaignKPIRecords = new List<EBH_CampaignKPI__c>();
        
        campaignKPIRecords.add(EBH_TestDataFactory.createCampaignKPIRecord( campaigns1[0].id, kpiRecords[0].id, 10));
        insert campaignKPIRecords;
        
        List<Campaign> campaigns2 = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign2', 'UK', 'EBH_Campaign',campaignsp.id,'Submitted'); //NK:29/10/2018
        List<Campaign> campaigns3 = EBH_TestDataFactory.createCampaignsWithParent(2, 'Test Campaign2a', 'UK', 'EBH_Campaign',campaignsp.id,'Preparation'); //NK:29/10/2018

        List<Campaign>  listCam = campaigns1;
        
        EBH_TestDataFactory.setUpTargetedSellerTriggerHandlerData();
        List<EBH_Filter__c> sellerLists0 = EBH_TestDataFactory.createSellerLists(1, 'Test Seller List', 
                                                'Snapshot_Seller_List', System.today() + 365);
        EBH_Filter__c sellerL = sellerLists0[0];//[SELECT id from EBH_Filter__c where RecordType.dEveloperName = 'Snapshot_Seller_List' limit 1];
           
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
                         
            
            /*Excecute test*/
            
             List<EBH_Filter__c> sellerLists = EBH_TestDataFactory.createSellerLists(1, 'Test Seller List', 
                                                'Snapshot_Seller_List', System.today() + 365);
            Test.startTest();
            Campaign pRecord = listCam[0];//[SELECT id from Campaign][0];
            EBH_RandomControlGroupController controller = new EBH_RandomControlGroupController(
            new ApexPages.standardController(sellerLists[0])); 
            controller.refreshRandomGroup();
            
            
            
            sellerL.EBH_ActualControlGroupSize__c = 100;
            update sellerL;
            
            pRecord.EBH_SellerList__c = sellerL.ID;
            update pRecord;
            
            Test.stopTest();
            
            controller = new EBH_RandomControlGroupController(
            new ApexPages.standardController(sellerL)); 
            controller.refreshRandomGroup();
              
           
            sellerL.EBH_ActualControlGroupSize__c = 10;
            update sellerL;
            
            controller = new EBH_RandomControlGroupController(
            new ApexPages.standardController(sellerL)); 
            controller.refreshRandomGroup();

        
        
    }
}