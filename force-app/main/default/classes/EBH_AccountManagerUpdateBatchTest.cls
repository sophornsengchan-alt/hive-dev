/*********************************************************************************************************************************
@ Class:          EBH_AccountManagerUpdateBatchTest
@ Version:        1.0
@ Author:         NEHA LUND (nalund@deloitte.co.uk)
@ Purpose:        Test class for EBH_AccountManagerUpdateBatch class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.08.2017 / NEHA LUND  / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_AccountManagerUpdateBatchTest {
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND  / Created the test Method.
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
    @ Change history: 16.08.2017 / NEHA LUND  / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testUpdateCustomRollUp(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testUpdateCustomRollUp
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        TEST CASE (*) System should be able to update the Account Owner if there are any changes in the Account
                                    Manager Name
                                    If Account Manager text field is changed then workflow will update the checkbox to be picked
                                    up in the batch for updating the owner
                      COVERAGES (*) execute(): Updates the Account Owner using the User records
                                        |___ Workflow will also trigger task creation if Urgency flag is ticked
                                        |___ Notification to the User about task creation if Urgency flag is ticked
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.08.2017 / NEHA LUND  / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testUpdateCustomRollUp() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData();     
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            
            /*Modify data for test*/             
            testDataMap.get('se1').EBH_UpdateAccountManager__c = true;
            testDataMap.get('se1').EBH_UrgencyFlag__c = true;
            testDataMap.get('se1').EBH_AccountManageName__c = 'Neha Lund';
            testDataMap.get('se1').ownerId = UserInfo.getUserID();
            
            testDataMap.get('se2').EBH_UpdateAccountManager__c = true;
            testDataMap.get('se2').EBH_UrgencyFlag__c = true;
            testDataMap.get('se2').ownerId = UserInfo.getUserID();
            
            testDataMap.get('se3').EBH_UpdateAccountManager__c = true;
            testDataMap.get('se3').ownerId = UserInfo.getUserID();
            
            testDataMap.get('se3').EBH_AccountManageName__c = [SELECT lastName from User where id = :UserInfo.getUserID()].LastName;
            testDataMap.get('se3').EBH_UpdateAccountManager__c = true;
            
            /*Excecute test*/
            Database.executeBatch( new EBH_AccountManagerUpdateBatch());
            EBH_AccountManagerUpdateBatch instance = new EBH_AccountManagerUpdateBatch();
            SchedulableContext sc;
            instance.execute( sc);
            
            /*Validate test*/
            Account le2 = [SELECT owner.UserName
                           FROM Account WHERE Id =: testDataMap.get('le1').Id][0];
            System.assertEquals(UserInfo.getUserName(), le2.owner.UserName);
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            testDataMap.get('le3').EBH_AccountManageName__c = '';
            
            /*Excecute test*/
            update testDataMap.values(); //change in legal entity should not roll up
            
            /*Validate test*/
            le2 = [SELECT owner.UserName FROM Account WHERE Id = :testDataMap.get('le2').Id][0];
            
            System.assertEquals(UserInfo.getUserName(), le2.owner.UserName);
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/             
            testDataMap.get('se1').EBH_RevenueLast12Months__c = 99999999999999.0;
            
            /*Excecute test*/
            update testDataMap.values(); //change in legal entity should not roll up
            
            //System.assertEquals(2, [SELECT id from Task].size());
            /*Validate test*/
            //System.assertEquals(1, [SELECT EBH_MethodName__c FROM EBH_ApexLog__c 
            //                        WHERE EBH_MethodName__c = 'updateCustomRollUp'].size());
            
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
}