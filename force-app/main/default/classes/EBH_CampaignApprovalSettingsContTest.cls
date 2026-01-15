/*********************************************************************************************************************************
@ Class:          EBH_CampaignApprovalSettingsContTest
@ Version:        1.0
@ Author:         Ashish Baranwal
@ Purpose:        EPH-3184: Test class for EBH_CampaignApprovalSettingsController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.09.2017 / Ashish Baranwal / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_CampaignApprovalSettingsContTest {
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         Ashish Baranwal
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2017 / Ashish Baranwal / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { 
            testEBH_CampaignApprovalSettingsController(); 
        }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         Ashish Baranwal
    @ Purpose:        Profile testing for Developer
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2017 / Ashish Baranwal / Created the test Method.
    *****************************************************************************************************************************/
    /*static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Developer')) { 
            testEBH_CampaignApprovalSettingsController(); 
        }
    }*/
    
    /*****************************************************************************************************************************
    @ Method:         testEBH_CampaignApprovalSettingsController
    @ Version:        1.0
    @ Author:         Ashish Baranwal
    @ Purpose:        TEST CASE (*) System should be able to initialise all the global data structures for the page
                      COVERAGES (*) EBH_testEBH_CampaignApprovalSettingsControllerController(): constructor 
                                        |___initiate(): initialises all the global data structures - approval matrix & hierarchy
                                        
                                    createNewMatrices(): Creates new approval matrix for the sites non exitent for first time.
                                        |___getSites(): retrieves the site picklist entries from the approval matrix object
                                        |___getDefaultUser(): get a random sys admin user
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2017 / Ashish Baranwal / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testEBH_CampaignApprovalSettingsController() {
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        EBH_TestDataFactory.SetUpCampaignRequestSiteGroupSettings('UK','EBH_CampaignRequestApprovers');
        
        List<User> stdUsers = (List<User>)(EBH_TestDataFactory.setupCampaignApprovalSettingsControllerData().get('stdUsers')); 
        List<String> sites = (List<String>)(EBH_TestDataFactory.setupCampaignApprovalSettingsControllerData().get('sites'));
        
        EBH_CampaignApprovalMatrix__c mx = (EBH_CampaignApprovalMatrix__c)
            (EBH_TestDataFactory.setupCampaignApprovalSettingsControllerData().get('mx'));
        
        EBH_CampaignApprovalGroup__c hxf1 = (EBH_CampaignApprovalGroup__c)
            (EBH_TestDataFactory.setupCampaignApprovalSettingsControllerData().get('hxf1'));
        EBH_CampaignApprovalGroup__c hxf2 = (EBH_CampaignApprovalGroup__c)
            (EBH_TestDataFactory.setupCampaignApprovalSettingsControllerData().get('hxf2'));
        
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Setup the page to load*/             
            Test.setCurrentPage(Page.EBH_CampaignApprovalSettings);
            System.assertEquals(1, [SELECT id from EBH_CampaignRequestSiteGroup__c].size() );
            /*Excecute test*/
            EBH_CampaignApprovalSettingsController casController = new EBH_CampaignApprovalSettingsController();               
            casController.createNewMatrices();
            casController.initiate();
            casController.getSites();
            //----
            casController.site = 'DE';
            casController.edit();
            casController.add();
            casController.save();
            casController.remove();
            //casController.removeHierarchy();
            casController.cancel();
            
            //----
            /*Validate test*/
            Id profId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
            
            List<EBH_CampaignApprovalMatrix__c> ams = [SELECT Id, EBH_Site__c,
                                                        (SELECT Id FROM EBH_CampaignApprovalGroup__r) 
                                                         FROM EBH_CampaignApprovalMatrix__c];
                           
            /*first ever load should create matrix recs for each site mapped to system admin*/
            //System.assertEquals(sites.size(), ams.size());
            
            /*Modify data for test*/
            delete ams; insert mx;
            
            hxf1.EBH_CampaignApprovalMatrix__c = mx.Id; insert hxf1;
            hxf2.EBH_CampaignApprovalMatrix__c = mx.Id; insert hxf2;
            
            /*Excecute test*/
            casController = new EBH_CampaignApprovalSettingsController();
            //casController.createNewMatrices();
           
            /*Validate test*/
            ams = [SELECT Id, EBH_Site__c, 
                          (SELECT Id FROM EBH_CampaignApprovalGroup__r) 
                     FROM EBH_CampaignApprovalMatrix__c];
                                                         
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
            //EBH_TestDataFactory.createCampaignApprovalMatrixList(10001,'UK');
            System.assertEquals(1, [SELECT EBH_MethodName__c FROM EBH_ApexLog__c 
                                    WHERE EBH_MethodName__c = 'createNewMatrices'].size());
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
}