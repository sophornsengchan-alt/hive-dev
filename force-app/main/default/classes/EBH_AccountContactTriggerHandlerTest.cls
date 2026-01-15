/*********************************************************************************************************************************
@ Class:          EBH_AccountContactTriggerHandlerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_AccountContactRelationTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.08.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_AccountContactTriggerHandlerTest {
    static Map<String, AccountContactRelation> testDataMap = new Map<String, AccountContactRelation>();
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.08.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { setupData();
                     testUpdateValidate();
        }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.08.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        setUpData();
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testUpdateValidate(); }
    }
    static testmethod void setupData(){
        EBH_TestDataFactory.setUpCustomSettings();   
        testDataMap = EBH_TestDataFactory.setUpAccountContactTriggerHandlerData();     
        Account acc = new Account(Id = testDataMap.get('ac2').AccountId,EBH_Status__c='Deleted');  
        update acc; 
       
    }
    /*****************************************************************************************************************************
    @ Method:         testUpdateValidate
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) User should not be able to update the contact/account details if status is 
                                    - Pending Termination
                                    - Deleted
                      COVERAGES (*) testUpdateValidate()
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.08.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testUpdateValidate() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
         /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/
        if(testDataMap.size() == 0)
        setupData();
        
        Test.startTest();
            /*Modify data for test*/   
            testDataMap.get('ac2').EBH_PrimaryContact__c = true;     
            try{
            	/*Excecute test*/
               update testDataMap.get('ac2');
            }catch(Exception e){
                /*Validate test*/
              	System.assert(e.getMessage().contains(Label.EBH_AccountContactUpdateError));
             }
            
            /*Modify data for test*/             
             try{
             	delete testDataMap.get('ac2');
             }catch(Exception e){
                 System.assert(e.getMessage().contains(Label.EBH_AccountContactUpdateError));
             }
            
        Test.stopTest();
    }
}