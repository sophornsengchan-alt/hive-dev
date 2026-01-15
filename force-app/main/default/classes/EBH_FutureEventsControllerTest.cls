/*********************************************************************************************************************************
@ Class:          EBH_FutureTasksControllerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_FutureTasksController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.06.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_FutureEventsControllerTest {
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testMaterials(); }        
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
        System.runAs(EBH_TestDataFactory.createUser('Business Admin')) { testMaterials(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testMaterials
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) System should be able to create the Targeted Sellers based on the attachment
                                    uploaded on Seller List Snapshot record, It will delete previous Targeted Sellers &
                                    creates the new Targeted Sellers
                      COVERAGES (*) testMaterials(): Creates the Seller records
                                    Attachment records on Seller List Snapshot object
                                    Attachment Trigger and Handler class
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testMaterials() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            
            /*Excecute test*/
            EBH_FutureEventsController cs = new EBH_FutureEventsController();
            cs.getMoreTasks();
            /*Validate test*/
            System.assertEquals( 0 , [SELECT id from Task].size() );
             
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
                         
            EBH_TestDataFactory.setUpAttachmentTriggerHandlerData();
            
            /*Excecute test*/
            EBH_FutureEventsController controllerIns = new EBH_FutureEventsController();
            
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -------------*/
            /*Validate test*/
            System.assertEquals( 1 , [SELECT id from EBH_TrainingMaterial__c].size() );
            
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            
       Test.stopTest();
    }
}