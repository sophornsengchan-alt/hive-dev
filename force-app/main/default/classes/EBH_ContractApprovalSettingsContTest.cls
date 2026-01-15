/*********************************************************************************************************************************
@ Class:          EBH_ContractApprovalSettingsContTest
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Test class for EBH_ContractApprovalSettingsController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.05.2017 / JOY MONDOL / Created the test class.
@ Change history:  06.12.2023 / Vimean Heng / Fix SOQL 101.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_ContractApprovalSettingsContTest {
    
    private static User currentUser = [ select Id, Name from User where Id = :UserInfo.getUserId() ];

    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2017 / JOY MONDOL / Created the test Method.
    -----------------------------------
    @ Change history:  06.12.2023 / Vimean Heng / US-0014422 currentUser is admin.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {  
        //US-0014422 System.runAs(EBH_TestDataFactory.createUser('System Administrator')) {      
        System.runAs(currentUser) { 
            testEBH_ContractApprovalSettingsController(); 
        }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Profile testing for Developer
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2017 / JOY MONDOL / Created the test Method.
    *****************************************************************************************************************************/
  /*  static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Developer')) { 
            testEBH_ContractApprovalSettingsController(); 
        }
    }
    */
    /*****************************************************************************************************************************
    @ Method:         testEBH_ContractApprovalSettingsController
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        TEST CASE (*) System should be able to initialise all the global data structures for the page
                      COVERAGES (*) EBH_ContractApprovalSettingsController(): constructor 
                                        |___initiate(): initialises all the global data structures - approval matrix & hierarchy
                                        
                                    createNewMatrices(): Creates new approval matrix for the sites non exitent for first time.
                                        |___getSites(): retrieves the site picklist entries from the approval matrix object
                                        |___getDefaultUser(): get a random sys admin user
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2017 / JOY MONDOL / Created the test Method.
					  01.10.2021 / TIN SRONG / Update test method coverage.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06.12.2023 / Vimean Heng / US-0014422 Fix SOQL 101.
    *****************************************************************************************************************************/
    //static testMethod void testEBH_ContractApprovalSettingsController() {
    static void testEBH_ContractApprovalSettingsController() {
        Map<String, Object> mapData = EBH_TestDataFactory.setupEBH_ContractApprovalSettingsControllerData();
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        /*
        List<User> stdUsers = (List<User>)(EBH_TestDataFactory.setupEBH_ContractApprovalSettingsControllerData().get('stdUsers')); 
        List<String> sites = (List<String>)(EBH_TestDataFactory.setupEBH_ContractApprovalSettingsControllerData().get('sites'));
        Ebh_testdatafactory.setUpCustomSettings();
        
        EBH_ContractApprovalMatrix__c mx = (EBH_ContractApprovalMatrix__c)
            (EBH_TestDataFactory.setupEBH_ContractApprovalSettingsControllerData().get('mx'));
        //insert mx;
        
        List<EBH_ContractApprovalHierarchy__c> hierarchies = new List<EBH_ContractApprovalHierarchy__c >();
        
        EBH_ContractApprovalHierarchy__c hxf1 = (EBH_ContractApprovalHierarchy__c)
            (EBH_TestDataFactory.setupEBH_ContractApprovalSettingsControllerData().get('hxf1'));
        EBH_ContractApprovalHierarchy__c hxf2 = (EBH_ContractApprovalHierarchy__c)
            (EBH_TestDataFactory.setupEBH_ContractApprovalSettingsControllerData().get('hxf2'));
        EBH_ContractApprovalHierarchy__c hxc1 = (EBH_ContractApprovalHierarchy__c)
            (EBH_TestDataFactory.setupEBH_ContractApprovalSettingsControllerData().get('hxc1'));
        EBH_ContractApprovalHierarchy__c hxc2 = (EBH_ContractApprovalHierarchy__c)
            (EBH_TestDataFactory.setupEBH_ContractApprovalSettingsControllerData().get('hxc2'));
        */
        List<User> stdUsers = (List<User>)(mapData.get('stdUsers')); 
        List<String> sites = (List<String>)(mapData.get('sites'));
        Ebh_testdatafactory.setUpCustomSettings();
        
        EBH_ContractApprovalMatrix__c mx = (EBH_ContractApprovalMatrix__c)
            (mapData.get('mx'));
        //insert mx;
        
        List<EBH_ContractApprovalHierarchy__c> hierarchies = new List<EBH_ContractApprovalHierarchy__c >();
        
        EBH_ContractApprovalHierarchy__c hxf1 = (EBH_ContractApprovalHierarchy__c)
            (mapData.get('hxf1'));
        EBH_ContractApprovalHierarchy__c hxf2 = (EBH_ContractApprovalHierarchy__c)
            (mapData.get('hxf2'));
        EBH_ContractApprovalHierarchy__c hxc1 = (EBH_ContractApprovalHierarchy__c)
            (mapData.get('hxc1'));
        EBH_ContractApprovalHierarchy__c hxc2 = (EBH_ContractApprovalHierarchy__c)
            (mapData.get('hxc2'));
           /* hxf1.EBH_ContractApprovalMatrix__c = mx.id;
            hxf2.EBH_ContractApprovalMatrix__c = mx.id;
            hxc1.EBH_ContractApprovalMatrix__c = mx.id;
            hxc2.EBH_ContractApprovalMatrix__c = mx.id;
            
            hierarchies.add( hxf1);
            hierarchies.add( hxf2);
            hierarchies.add( hxc1);
            hierarchies.add( hxc2);
            insert hierarchies;*/
            
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Setup the page to load*/    
            Test.setCurrentPage(Page.EBH_ContractApprovalSettings);
            /*Excecute test*/
         	EBH_ContractApprovalSettingsController casController = new EBH_ContractApprovalSettingsController(); 
        	casController.createNewMatrices();
        	casController.initiate();
            casController.getSites();
            
        	// 01.10.2021 / TIN SRONG : update coverage
            casController.site = 'UK';
        	casController.edit();
            casController.add();
            casController.save();
            casController.remove();
        	casController.Hierarchy = 'BU';
        	casController.add();
        	casController.remove();
        	casController.Hierarchy = 'Controlling';
        	casController.add();
        	casController.remove();
        	casController.Hierarchy = 'Finance';
        	casController.add();
        	casController.remove();
            //casController.removeHierarchy(); 
            casController.cancel();
        	//----
            /*Validate test*/
            Id profId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
            
            List<EBH_ContractApprovalMatrix__c> ams = [SELECT Id, EBH_Site__c, EBH_LegalApprover__r.ProfileId, 
                                                              EBH_FinancePreCheckApprover__r.ProfileId, 
                                                              (SELECT Id FROM EBH_ContractApprovalHierarchies__r) 
                                                         FROM EBH_ContractApprovalMatrix__c];
                           
            /*first ever load should create matrix recs for each site mapped to system admin*/
            //System.assertEquals(sites.size(), ams.size());
           // System.assertEquals(profId, ams[0].EBH_LegalApprover__r.ProfileId);
            //System.assertEquals(profId, ams[0].EBH_FinancePreCheckApprover__r.ProfileId);
            
            /*Modify data for test*/
            delete ams; insert mx;
            hxf1.EBH_ContractApprovalMatrix__c = mx.Id; insert hxf1;
            hxf2.EBH_ContractApprovalMatrix__c = mx.Id; insert hxf2;
            hxc1.EBH_ContractApprovalMatrix__c = mx.Id; insert hxc1;
            hxc2.EBH_ContractApprovalMatrix__c = mx.Id; insert hxc2;
            
            /*Excecute test*/
            casController = new EBH_ContractApprovalSettingsController();
            casController.createNewMatrices();
            
            /*Validate test*/
            ams = [SELECT Id, EBH_Site__c, EBH_LegalApprover__r.ProfileId, EBH_FinancePreCheckApprover__r.ProfileId, 
                          (SELECT Id FROM EBH_ContractApprovalHierarchies__r) 
                     FROM EBH_ContractApprovalMatrix__c];
                                                         
            List< EBH_BUApproverGroup__c> bu = new List< EBH_BUApproverGroup__c >();
            bu.add(EBH_TestDataFactory.createBUApprovalHierarchy(hxf1.Id, UserInfo.getUserId()));
            bu.add(EBH_TestDataFactory.createBUApprovalHierarchy(hxf2.Id, UserInfo.getUserId()));
            for(EBH_BUApproverGroup__c b: bu){
                b.EBH_BUHierarchy__c = hxc1.Id;
            }
            insert bu;
            
        	bu[0].EBH_Approver__c  = stdUsers[0].Id;
            update bu[0];
        	// 01.10.2021 / TIN SRONG : update coverage
        	Set<ID> susers = new Set<ID>();
        	susers.add(stdUsers[0].Id);
            List<EBH_ContractApprovalHierarchy__c> ahs = new List<EBH_ContractApprovalHierarchy__c>();
            casController.handleError(null,susers,ahs,casController.ApprovalMatrices);
        
            EBH_BUApproverGroup__c buDelete = EBH_TestDataFactory.createBUApprovalHierarchy(hxf1.Id, UserInfo.getUserId());
            try{
            delete buDelete;
            }
            catch(Exception e){
            }
            
            //System.assertEquals(sites.size(), ams.size());          
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/             
            //testDataMap.get('se1').EBH_RevenueLast12Months__c = 9999999999999999.9;
            
            /*Excecute test*/
            //update testDataMap.values(); //change in legal entity should not roll up
            
            /*Validate test*/
            //System.assertEquals(1, [SELECT EBH_MethodName__c FROM EBH_ApexLog__c 
            //                        WHERE EBH_MethodName__c = 'updateCustomRollUp'].size());
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
}