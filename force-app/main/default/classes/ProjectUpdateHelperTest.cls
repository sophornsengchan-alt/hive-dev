/*********************************************************************************************************************************
@ Class:          ProjectUpdateHelperTest
@ Version:        1.0
@ Author:         Sophal Noch (sophalead.noch@gaea-sys.com)
@ Purpose:        US-0014671 - Tech debt - Migrate Process Builder to Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  25.01.2023 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
private class ProjectUpdateHelperTest {
  
    /*********************************************************************************************************************************
    @ Method:         testUpdateRelatedAUProject
    @ Version:        1.0
    @ Author:         Sophal Noch (sophalead.noch@gaea-sys.com)
    @ Purpose:        US-0014671 - Tech debt - Migrate Process Builder to Trigger
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  25.01.2023 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void testUpdateRelatedAUProject(){
        EBH_TestDataFactory.setUpCustomSettings(); 
        
        Account seller1 =  EBH_TestDataFactory.createAccounts(1, 'EBH_Seller')[0];

        RecordType recTypeLeadAuSMB = ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUSMB');
        Lead lead = EBH_TestDataFactory.createLeads();
    	lead.LeadSource = 'Self Gen';
    	lead.RecordTypeId = recTypeLeadAuSMB.Id;
    	lead.isapproved__c = true;
    	lead.Site__c = 'AU';
    	lead.LeadSegment__c = 'SMB';
    	insert lead;

        RecordType recTypeProjAuOnboarding = ApexUtil.getRecordTypeByName('EBH_Project__c','eBayAUSMB');
    	EBH_Project__c proj1 = new EBH_Project__c(
            EBH_Seller__c = seller1.Id,
            ProjectName__c='Project 1', 
            EBH_Stage__c = 'Store Launched',
            Lead__c = lead.Id, 
            RecordTypeId = recTypeProjAuOnboarding.Id,
            OracleID__c = '111111',
            Listings__c = 200,
            LegalName__c = 'test 1',
            ABNVATNumber__c = ' test 1'
        );
        insert proj1;

        Test.startTest();
            ProjectUpdateHelper.updateRelatedAUProject(new Set<String>{seller1.Id});
            proj1 = [Select Id, EBH_Stage__c, ActualLiveToSite__c from EBH_Project__c Where Id =: proj1.Id];
            System.assertEquals('Live to Site', proj1.EBH_Stage__c);
            System.assertNotEquals(null, proj1.ActualLiveToSite__c);
        Test.stopTest();
        
    
    }

}