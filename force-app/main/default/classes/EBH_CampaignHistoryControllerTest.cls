/*********************************************************************************************************************************
@ Class:          EBH_CampaignHistoryControllerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_CampaignHistoryController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.06.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_CampaignHistoryControllerTest {
    
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
    
            Test.startTest();
            /*NEGATIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            List<Campaign> campaigns = [SELECT id from Campaign where recordtype.DEVELOPERNAME ='EBH_SubCampaign'];
            System.assertEquals( 10, campaigns.size());
            /*Excecute test*/
            EBH_CampaignHistoryController extns = new EBH_CampaignHistoryController(
                                                        new ApexPages.standardController([SELECT id from Account][0]));
            String qry = extns.CampaignMemberQuery;
            
            extns.First();
            extns.Last();
            extns.Previous();
            extns.Next();

            List<CampaignMember> lstRes = extns.CampaignMembers;
            System.assert( !lstRes.isEmpty(), 'There should be campaignMembers in it.');
            
            /*Validate test*/
            System.assertEquals( 10, [SELECT ID from Account].size());
            
            /*NEGATIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            Account acc = [SELECT ID from Account limit 1];
            acc.recordTypeId = [SELECT id from RecordType where DeveloperName = 'EBH_Seller' and SobjectType = 'Account'].Id;
            update acc;
            
            /*Excecute test*/
            List<Contact> conRecords = new List<Contact>();
            
            /*Validate test*/
            System.assertEquals( 4, [SELECT id from CampaignMember].size());

            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
             Test.stopTest();
    }
}