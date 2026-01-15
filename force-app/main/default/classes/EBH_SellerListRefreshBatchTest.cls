/*********************************************************************************************************************************
@ Class:          EBH_TargetingCockpitControllerTest
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Test class for EBH_TargetingCockpitController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.05.2017 / JOY MONDOL / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_SellerListRefreshBatchTest{
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {    
        User user = EBH_TestDataFactory.createUser('System Administrator'); 
        insert user;  
        System.runAs(user) { testCreateSnapshot(); }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        User user =  EBH_TestDataFactory.createUser('Business Admin');
        insert user;
        System.runAs(user) { testCreateSnapshot(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testCreateSnapshot
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
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
    @ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testCreateSnapshot() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        List<EBH_TargetedSeller__c> testDataMap = EBH_TestDataFactory.setUpTargetedSellerTriggerHandlerData();  
       /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            EBH_Filter__c filter =  [SELECT id, owner.email from EBH_Filter__c LIMIT 1][0];
            filter.EBH_NextRefreshDate__c = System.today();
            filter.recordTypeId = [SELECT id from RecordType where developername ='EBH_AutoRefreshSellerList'].Id; 
			//filter.recordTypeId = [SELECT id from RecordType where developername ='Snapshot_Seller_List'].Id;
            filter.EBH_Filter__c = 'SELECT COUNT() FROM Account WHERE Name LIKE \'%a%\' AND RecordType.DeveloperName = \'EBH_Seller\' LIMIT 1000000';
            update filter;
            Database.executeBatch(new EBH_SellerListRefreshBatch());
            
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            
            /*Excecute test*/
            
            /*Validate test*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/             
            
            /*Excecute test*/
            
            /*Validate test*/
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
        new EBH_SellerListRefreshBatch().execute(null); //US-0008410: for class coverage
    }
}