/*********************************************************************************************************************************
@ Class:          EBH_UniqueCampaignSellersExtensionsTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_UniqueCampaignSellersExtensions class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.05.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_DistinctCampaignControllerTest{
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {  
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testUniqueSellersList(); }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        EBH_TestDataFactory.setUpGroup('EBH_CampaignRequestApprovers');
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testUniqueSellersList(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testUniqueSellersList
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) System should be able to automatically submit the Campaign request for an approval
                                    For every site- we have dedicated group of users to approve the request and covert it into
                                    Campaign
                      COVERAGES (*) testUniqueSellersList(): 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testUniqueSellersList() {
                    
            /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
            EBH_TestDataFactory.setUpCustomSettings();   
            EBH_TestDataFactory.setUpCampaignMemberTriggerHandlerData();
            
            /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/
    
        
            /*NEGATIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            List<Campaign> campaigns = [SELECT id from Campaign ];
            //System.assertEquals( 30, campaigns.size());
            /*Excecute test*/
            EBH_DistinctCampaignSellersController2 extns = new EBH_DistinctCampaignSellersController2(
                                                        new ApexPages.standardController(campaigns[0]));
            EBH_DistinctCampaignSellersController2.fetchLowestLevelCampaignIds(campaigns[0].id );
            campaigns = [SELECT id from Campaign ];
             EBH_DistinctCampaignSellersController2.fetchContactCount(new List<ID>{campaigns[0].Id});
             EBH_DistinctCampaignSellersController2.fetchSellers(new List<ID>{campaigns[0].id}, 1, 10, 'SELECT id from Campaign');
            //System.assertEquals( 0, EBH_DistinctCampaignSellersController2.fetchSellers(new List<ID>{campaigns[0].id}, 0, 10, 'SELECT id from Campaign').size());
            /*Validate test*/
            System.assertEquals( 10, [SELECT ID from Account].size());
            
            /*NEGATIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            Account acc = [SELECT ID from Account limit 1];
            acc.recordTypeId = [SELECT id from RecordType where DeveloperName = 'EBH_Seller' and SobjectType = 'Account'].Id;
               Test.startTest();
            update acc;
            
            /*Excecute test*/
            List<Contact> conRecords = new List<Contact>();
            extns = new EBH_DistinctCampaignSellersController2(
                                                        new ApexPages.standardController(campaigns[0]));
            
            String sd = extns.sellersQuery;
            
            /*Validate test*/
            System.assertEquals( 4, [SELECT id from CampaignMember].size());

          //  System.assertEquals( 1, extns.getSellers().size());

            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
             Test.stopTest();
    }
}