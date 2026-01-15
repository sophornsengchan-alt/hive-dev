/*********************************************************************************************************************************
@ Class:          EBH_RelatedSellersControllerTest
@ Version:        1.0
@ Author:         NEHA LUND (nalund@deloitte.co.uk)
@ Purpose:        Test class for EBH_AccountTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.07.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_RelatedSellersControllerTest {
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
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
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
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
    @ Change history: 31.07.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static void testUpdateCustomRollUp() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData();     
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            testDataMap.get('se1').EBH_SoldItems__c = 11;
            testDataMap.get('se1').EBH_GMVLast12Months__c = 22;
            testDataMap.get('se1').EBH_RevenueLast12Months__c = 33;
            
            testDataMap.get('se2').EBH_SoldItems__c = 44;
            testDataMap.get('se2').EBH_GMVLast12Months__c = 55;
            testDataMap.get('se2').EBH_RevenueLast12Months__c = 66;
            
            testDataMap.get('se3').EBH_SoldItems__c = 77;
            testDataMap.get('se3').EBH_GMVLast12Months__c = 88;
            testDataMap.get('se3').EBH_RevenueLast12Months__c = 99;
            
            testDataMap.get('se7').ParentId = testDataMap.get('le1').Id;
            /*Excecute test*/
            insert new Account(Name = 'se8', ParentId = testDataMap.get('le1').Id, EBH_SoldItems__c = 100); //on insert
            update testDataMap.values(); //on update + reparenting               
            
            /*Validate test*/
            Account le1 = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
                           FROM Account WHERE Id =: testDataMap.get('le1').Id][0];
            Account le2 = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
                           FROM Account WHERE Id =: testDataMap.get('le2').Id][0];
            Account le3 = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
                           FROM Account WHERE Id =: testDataMap.get('le3').Id][0];
            Account le4 = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
                           FROM Account WHERE Id =: testDataMap.get('le4').Id][0];
            
            System.assertEquals(332, le1.EBH_SoldItems__c);
            System.assertEquals(165, le1.EBH_GMVLast12Months__c);
            System.assertEquals(198, le1.EBH_RevenueLast12Months__c);
                                     
            System.assertEquals(77, le2.EBH_SoldItems__c);
            System.assertEquals(88, le2.EBH_GMVLast12Months__c);
            System.assertEquals(99, le2.EBH_RevenueLast12Months__c);
            
            EBH_RelatedSellersController instance = new EBH_RelatedSellersController(new ApexPages.standardController(le1));              
            instance.first();
            instance.last();
            instance.next();
            instance.previous();
            List<Account> sellerRecords = instance.sellers;
            
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            testDataMap.get('le3').EBH_SoldItems__c = 9999;
            
            /*Excecute test*/
            update testDataMap.values(); //change in legal entity should not roll up
            
            /*Validate test*/
            le2 = [SELECT EBH_SoldItems__c FROM Account WHERE Id =: testDataMap.get('le2').Id][0];
            
            System.assertEquals(10076, le2.EBH_SoldItems__c);
            
            System.assertEquals(0, le3.EBH_SoldItems__c);
            System.assertEquals(0, le3.EBH_GMVLast12Months__c);
            System.assertEquals(0, le3.EBH_RevenueLast12Months__c);
            
            System.assertEquals(0, le4.EBH_SoldItems__c);
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/             
            testDataMap.get('se1').EBH_RevenueLast12Months__c = 99999999999999.0;
            
            /*Excecute test*/
            update testDataMap.values(); //change in legal entity should not roll up
            
            /*Validate test*/
            System.assertEquals(1, [SELECT EBH_MethodName__c FROM EBH_ApexLog__c 
                                    WHERE EBH_MethodName__c = 'updateCustomRollUp'].size());
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
}