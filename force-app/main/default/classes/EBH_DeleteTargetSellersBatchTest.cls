/*********************************************************************************************************************************
@ Class:          EBH_DeleteTargetSellersBatchTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_TrainingMaterialsController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.06.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_DeleteTargetSellersBatchTest{
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testTargetedSellerBatch(); }        
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
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testTargetedSellerBatch(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testTargetedSellerBatch
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) System should be able to create the Targeted Sellers based on the attachment
                                    uploaded on Seller List Snapshot record, It will delete previous Targeted Sellers &
                                    creates the new Targeted Sellers
                      COVERAGES (*) testTargetedSellerBatch(): Creates the Seller records
                                    Attachment records on Seller List Snapshot object
                                    Attachment Trigger and Handler class
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testTargetedSellerBatch() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
                         
            List<EBH_TargetedSeller__c> testDataMap = EBH_TestDataFactory.setUpTargetedSellerTriggerHandlerData();     
            /*Excecute test*/
            try{
            EBH_DeleteTargetSellersBatch  controllerIns = new EBH_DeleteTargetSellersBatch ([SELECT id, Name, Owner.Email from EBH_Filter__c where owner.Email != null limit 1], 
                    'SELECT id from Account');
            Database.executeBatch(controllerIns );
            }
            catch(Exception e){}
            
            /*Validate test*/
            
          
            
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            
            /*Excecute test*/
            
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