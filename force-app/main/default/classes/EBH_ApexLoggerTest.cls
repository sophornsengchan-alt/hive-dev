/*************************************************************************************************************************************************
@ Class:          EBH_ApexLoggerTest
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Test class for EBH_ApexLogger class
-------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.05.2017 / JOY MONDOL / Created the test class.
@                 11.12.2024 /  Sothea Horn /  US-0015300 - Generic LWC Exception handling & Application to program participation component            
*************************************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_ApexLoggerTest {
    
    /*****************************************************************************************************************************
    @ Methods:        testProfile_<profile name>_<method name>
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
    *****************************************************************************************************************************/
    //Profile testing for System Administrator - testLogError_1
    static testMethod void testProfile_SA_testLogError_1() {        
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testLogError_1(); }        
    }
    
    //Profile testing for System Administrator - testLogError_2
    static testMethod void testProfile_SA_testLogError_2() {        
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testLogError_2(); }        
    }
    
    //Profile testing for Standard User - testLogError_1
    static testMethod void testProfile_SU_testLogError_1() {
        System.runAs(EBH_TestDataFactory.createUser('Business Admin')) { testLogError_1(); }
    }
    
    //Profile testing for Standard User - testLogError_2
    static testMethod void testProfile_SU_testLogError_2() {
        System.runAs(EBH_TestDataFactory.createUser('Business Admin')) { testLogError_2(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testLogError_1
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        TEST CASE (*) System should be able to log exceptions thrown from an apex class for System Administrators
                      COVERAGES (*) logError(): Utility method to insert the exceptions to the Apex Log Object 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testLogError_1() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();
        
        Map<String, List<Sobject>> testDataMap = EBH_TestDataFactory.setUpApexLoggerData();     
        Account acc = ((List<Account>)(testDataMap.get('accounts')))[0]; 
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            acc.Name = '';
            
            /*Excecute test*/
            try {
                update acc;
            } catch(Exception ex) {
                EBH_ApexLogger.logError(new List<Exception> { ex }, 'EBH_ApexLoggerTest', 'testLogError_1');
            }
            
            /*Validate test*/
            System.assertEquals('testLogError_1', [SELECT EBH_MethodName__c FROM EBH_ApexLog__c 
                                                   WHERE EBH_MethodName__c = 'testLogError_1'][0].EBH_MethodName__c);
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            acc.Name = 'Test Account N';
            
            /*Excecute test*/
            try {
                update acc;
            } catch(Exception ex) {
                EBH_ApexLogger.logError(new List<Exception> { ex }, 'EBH_ApexLoggerTest', 'testLogError_N');
            }
            
            /*Validate test*/
            System.assertEquals(0, [SELECT EBH_MethodName__c FROM EBH_ApexLog__c 
                                    WHERE EBH_MethodName__c = 'testLogError_N'].size());
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
        Test.stopTest();
    }

    /*****************************************************************************************************************************
    @ Method:         testLogError_2
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        TEST CASE (*) System should be able to log errors thrown from an apex class for System Administrators
                      COVERAGES (*) logError(): Utility method to insert the exceptions to the Apex Log Object 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testLogError_2() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();
     
        Map<String, List<Sobject>> testDataMap = EBH_TestDataFactory.setUpApexLoggerData();     
        Account acc = ((List<Account>)(testDataMap.get('accounts')))[0]; 
        Account acc2 = new Account();
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Excecute test*/
            Database.SaveResult ur = Database.update(acc2, False);
        
            if(!ur.isSuccess()) {                   
                EBH_ApexLogger.logError(ur.getErrors(), 'EBH_ApexLoggerTest', 'testLogError_2');
            } 
            
            /*Validate test*/
            System.assertEquals('testLogError_2', [SELECT EBH_MethodName__c FROM EBH_ApexLog__c 
                                                   WHERE EBH_MethodName__c = 'testLogError_2'][0].EBH_MethodName__c);
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            acc.Name = 'Test Account N';
            
            /*Excecute test*/
            Database.SaveResult urN = Database.update(acc, False);
        
            if(!urN.isSuccess()) {                  
                EBH_ApexLogger.logError(urN.getErrors(), 'EBH_ApexLoggerTest', 'testLogError_N');
            }
            
            /*Validate test*/
            System.assertEquals(0, [SELECT EBH_MethodName__c FROM EBH_ApexLog__c 
                                    WHERE EBH_MethodName__c = 'testLogError_N'].size());
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
        Test.stopTest();
    }

    /*****************************************************************************************************************************
    @ Method:         test_logError
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        Coverage for method logError(String errCause,Integer lineNumber,String stackTrace,String errType,String errorMsg, String className, String methodName)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.09.2021 / Mony Nou / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void test_logError() {

        Test.startTest();

            EBH_ApexLogger.logError('test_errCause', 168, 'test_stackTrace', 'test_errType', 'test_errorMsg', 'test_className', 'test_methodName');

        Test.stopTest();

        List<EBH_ApexLog__c> res = [SELECT EBH_ClassName__c,EBH_MethodName__c,EBH_ExceptionCause__c,EBH_ExceptionLineNumber__c,EBH_ExceptionStackTraceString__c,EBH_ExceptionType__c,EBH_Message__c FROM EBH_ApexLog__c];

        System.assert(!res.isEmpty());
    }

    
    /*****************************************************************************************************************************
    @ Method:         test_logErrorFlow
    @ Version:        1.0
    @ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 01.12.2023 /  vadhanak voun /  US-0014472 - Trim flow message when creating apex log record on Share Case Flow
    *****************************************************************************************************************************/
    static testMethod void test_logErrorFlow() 
    {
        Test.startTest();
            EBH_ApexLogger.CustomParameter oneParamFlow = new EBH_ApexLogger.CustomParameter();
            oneParamFlow.className = 'NotAclassName007';
            oneParamFlow.stackTrace = 'very long stack trace';
            oneParamFlow.errorCause = 'UnknowTestCause';
            oneParamFlow.errorMessage = 'ThisIsMyTestMessage';
            oneParamFlow.errorActionName = 'FlowTestActionName';
            
            EBH_ApexLogger.logErrorFlow(new List<EBH_ApexLogger.CustomParameter>{oneParamFlow});
        Test.stopTest();
        EBH_ApexLog__c[] mylogs = [Select Id From EBH_ApexLog__c Where EBH_ClassName__c='NotAclassName007'];
            System.assertEquals(1, mylogs.size(),'one log should be created');
    }

    /*****************************************************************************************************************************
    @ Method:         testLogSellerPortal
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.12.2023 / Sambath Seng / US-0014263 - Store log of unsuccessful logins for sellers portal
    *****************************************************************************************************************************/
    @isTest static void testLogSellerPortal() {

        //create Custom Setting record for EBH_ActiveTriggers__c
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller', Seller_Portal_Service__c = true);
        
        Test.startTest();
        // Call the method to test
        EBH_ApexLogger.logSellerPortal('create','Test Seller','Test API ID','Test User ID','Test Page','Test Error Message','Test URL','Test Method');
        Test.stopTest();

        // Query the event
        List<Seller_Portal_Service__c> services = [SELECT Json_Data__c FROM Seller_Portal_Service__c];
        
        // Assert the results
        System.assertEquals(1, services.size(), 'One event should be published');
    }

    /*******************************************************************************************************************************************
    @ Method:         testLogErrorLWC
    @ Version:        1.0
    @ Author:         Sothea Horn (sohorn@ebay.com)
    ---------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2024 /  Sothea Horn /  US-0015300 - Generic LWC Exception handling & Application to program participation component
    **********************************************************************************************************************************************/
    static testMethod void testLogErrorLWC() 
    {
        Test.startTest();
            String lwcName = 'TestLWCFailure';
            String lwcMethodName = 'TestLWCFailureMethod';
            String errMsg = 'Test LWC error';
            EBH_ApexLogger.logErrorLWC('Test LWC error', '', lwcName, lwcMethodName);
        Test.stopTest();
        EBH_ApexLog__c[] mylogs = [Select Id, EBH_ClassName__c, EBH_MethodName__c, EBH_Message__c, IncidentId__c From EBH_ApexLog__c Where EBH_ClassName__c=: lwcName];
        System.assertEquals(1, mylogs.size(),'one log should be created');
        System.assertEquals(lwcName, mylogs[0].EBH_ClassName__c, 'Incident Id must be TestLWCFailure');
        System.assertEquals(lwcMethodName, mylogs[0].EBH_MethodName__c, 'Incident Id must be TestLWCFailureMethod');
        System.assertEquals(errMsg, mylogs[0].EBH_Message__c, 'Test LWC error');
        System.assertNOTEquals(null, mylogs[0].IncidentId__c, 'Incident Id must be populated');
    }

}