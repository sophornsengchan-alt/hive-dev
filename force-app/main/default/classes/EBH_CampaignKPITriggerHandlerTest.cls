/*********************************************************************************************************************************
@ Class:          EBH_CampaignKPITriggerHandlerTest
@ Version:        1.0
@ Author:         NEHA LUND 
@ Purpose:        Test class for EBH_CampaignKPITriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.05.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_CampaignKPITriggerHandlerTest {
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testupdateCampaignKPIRollup();}        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testupdateCampaignKPIRollup(); }
    }
    
    
    /*****************************************************************************************************************************
    @ Method:         testupdateCampaignKPIRollup
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        TEST CASE (*) System should be able to create the Campaign KPI from parent to child records
                      COVERAGES (*) createChildKPIRecords(): Creates the Campaign KPI records from the parent record
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testupdateCampaignKPIRollup() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();    
        EBH_TestDataFactory.setUpCampaignKPITriggerHandlerData();
        
        /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
        
        /*Validate test*/ 
       // System.assertEquals( 24, [SELECT id from EBH_CampaignKPI__c].size());
        
        /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
        
    }


    //MN-01102021-US-0008399
    @isTest 
    static void test_hasRollupChanged() {

        EBH_TestDataFactory.setUpCustomSettings();    
        EBH_TestDataFactory.setUpCampaignKPITriggerHandlerData();

        Test.startTest();
            List<EBH_CampaignKPI__c> lstCmpKPI = [SELECT EBH_Actual__c, EBH_Campaign__c FROM EBH_CampaignKPI__c];
            
            for (EBH_CampaignKPI__c cmpKPI : lstCmpKPI) {
                Boolean res = EBH_CampaignKPITriggerHandler.hasRollupChanged(cmpKPI, null);
            }
        Test.stopTest();
        
    }
}