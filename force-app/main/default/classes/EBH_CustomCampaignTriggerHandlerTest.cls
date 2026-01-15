/*********************************************************************************************************************************
@ Class:          EBH_CampaignMemberTriggerHandlerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_CampaignMemberTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.06.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_CustomCampaignTriggerHandlerTest{
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testFrontEndMetrics(); }        
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
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testFrontEndMetrics(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testFrontEndMetrics
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) System should be able to rollup the following fields in sellers to its legal entity 
                                    (which is a one to many relationship of one level of depth) 
                                    on insert and update and reparenting:
                                     - GMV
                                     - Revenue 
                                     - Sold Items
                      COVERAGES (*) updateCustomRollUp(): Updates custom roll ups on legal entity from child sellers 
                                        |___hasRollupChanged(): Checks field change in seller
                                        |___hasParentChanged(): Checks parent change in seller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testFrontEndMetrics() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        List<EBH_CampaignMember__c> campaignMembers = EBH_TestDataFactory.setUpCustomCampaignMemberTriggerHandlerData();     
       
      
        
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
                         
            /*Excecute test*/
             
            /*Validate test*/
            System.assertEquals(4, [SELECT id from CampaignMember].size());
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            /*Excecute test*/
            
            /*Validate test*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/        
               Test.stopTest();     
              CampaignMember cMember= [SELECT id from CampaignMember where EBH_cockpitResultId__c ='12384'];
        EBH_CampaignMember__c cM = new EBH_CampaignMember__c(EBH_CockpitResultId__c = '12384');
        insert cM;
            /*Excecute test*/
            
            /*Validate test*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
     
    }
}