/*********************************************************************************************************************************
@ Class:          EBH_ExitCodeControllerTest
@ Version:        1.0
@ Author:         NEHA LUND (nalund@deloitte.co.uk)
@ Purpose:        Test class for EBH_ExitCodeController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.05.2018 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_ExitCodeControllerTest{
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.07.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testUpdateCustomRollUp(); }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.07.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testUpdateCustomRollUp(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testUpdateCustomRollUp
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
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
    @ Change history: 17.07.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testUpdateCustomRollUp() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        EBH_TestDataFactory.setUpTargetedSellerTriggerHandlerData();     
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            Id sellerID = [SELECT id from Account limit 1].ID;
            EBH_ExitCodeController controllerInstance = new EBH_ExitCodeController (new ApexPages.standardController([SELECT id from EBH_Filter__c limit 1]));
            
            /*Excecute test*/
            EBH_ExitCodeController.fetchTargetedSellers(new String[]{'12334'}, [SELECT id from EBH_Filter__c limit 1].Id);
            EBH_ExitCodeController.createTargetedSellers(new String[]{sellerID}, 
                                                            [SELECT id from EBH_Filter__c limit 1].Id);
            /*Validate test*/
            System.assertEquals( 2, [SELECT id from EBH_TargetedSeller__C].size());
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            
            /*Excecute test*/
            EBH_ExitCodeController.fetchTargetedSellers(new String[]{sellerID,'3e'}, [SELECT id from EBH_Filter__c limit 1].Id);
            EBH_ExitCodeController.createTargetedSellers(new String[]{sellerID}, 
                                                            [SELECT id from EBH_Filter__c limit 1].Id);
            /*Validate test*/
            System.assertEquals( 2, [SELECT id from EBH_TargetedSeller__C].size());
            /*Validate test*/
             /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/             
           
            /*Excecute test*/
           
            
            /*Validate test*/
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
}