/*********************************************************************************************************************************
@ Class:          EBH_CampaignKPIRollupBatchTest
@ Version:        1.0
@ Author:         NEHA LUND 
@ Purpose:        Test class for EBH_CampaignKPITriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.05.2017 / NEHA LUND / Created the test class.
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.11.2021 / Mony Nou / US-0008353
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_CampaignKPIRollupBatchTest{
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testupdateCampaignKPIRollup();}        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testupdateCampaignKPIRollup(); }
    }
    
    
    /*****************************************************************************************************************************
    @ Method:         testupdateCampaignKPIRollup
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        TEST CASE (*) System should be able to update the 'Pre-Approved Template' field on Contract 
                                    based on the combination of below fields stored in Custom Settings (Pre-Approved Contract template rules)
                                    - Site
                                    - Language
                                    - Record Type
                      COVERAGES (*) updatePreApprovedTemplate(): Updates the Pre-Approved Template field based on the changes of below fields
                                        |___hasPreApprovedParametersChanged(): Checks field change in Contract
                                        |
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testupdateCampaignKPIRollup() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();    
        
        EBH_TestDataFactory.setUpCampaignKPITriggerHandlerData();
        
        List<EBH_CampaignKPI__c> cKPI = new List<EBH_CampaignKPI__c>();
        for( EBH_CampaignKPI__c kpi: [SELECT id from EBH_CampaignKPI__c]){
            
            kpi.EBH_UpdateCampaignActualHierarchy__c  = true;
            cKPI.add(kpi);
        }
        
        update cKPI;

        EBH_CampaignKPIRollupBatch kpiBatch = new EBH_CampaignKPIRollupBatch();

        Database.executeBatch( new EBH_CampaignKPIRollupBatch());
        SchedulableContext sc;
        kpiBatch.execute(sc);
    }

    //MN-15112021-US-0008353
    @isTest
    static void mytestmethod () {

        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();    
        
        EBH_TestDataFactory.setUpCampaignKPITriggerHandlerData();
        
        
        List<Campaign> lstParCmp = [SELECT Id FROM Campaign WHERE RecordType.DeveloperName='EBH_Campaign'];
        List<Campaign> lstSubCmp = [SELECT Id FROM Campaign WHERE RecordType.DeveloperName='EBH_SubCampaign'];

        Campaign subcmp = new Campaign(Id=lstSubCmp[0].Id, ParentId = lstParCmp[0].Id);
        update subcmp;

        List<EBH_KPI__c> kpiRecords = [SELECT Id FROM EBH_KPI__c];
        EBH_CampaignKPI__c subCMPKPI = new EBH_CampaignKPI__c( EBH_Campaign__c = lstSubCmp[0].Id,
                                               EBH_KPI__C = kpiRecords[0].Id,
                                               EBH_Actual__c = 10 );
        insert subCMPKPI;    
        
        List<EBH_CampaignKPI__c> cKPI = new List<EBH_CampaignKPI__c>();
        for( EBH_CampaignKPI__c kpi: [SELECT id from EBH_CampaignKPI__c]){
            
            kpi.EBH_UpdateCampaignActualHierarchy__c  = true;
            cKPI.add(kpi);
        }
        
        update cKPI;

        EBH_CampaignKPIRollupBatch kpiBatch = new EBH_CampaignKPIRollupBatch();

        Database.executeBatch( new EBH_CampaignKPIRollupBatch());
        SchedulableContext sc;
        kpiBatch.execute(sc);
    }
}