@isTest
private class TaskInitiateFlowControllerTest {
	@isTest
    private static void queryTasksTest(){
        EBH_TestDataFactory.setUpCustomSettings();

        Campaign subCampaign = new Campaign();
        subCampaign.Name = 'Test SubCampaign 01';
        subCampaign.recordTypeId = EBH_TestDataFactory.getRecordTypeByName('Campaign', EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE).Id;
        subCampaign.EBH_Channel__c = EBH_ConstantsUtility.CAMPAIGN_CHANNEL_GCX_OUTREACH;
        subCampaign.Survey_ID__c = 'testServey';
		subCampaign.EBH_Site__c = 'AU';
        insert subCampaign;
        
        List<Account> sA = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        
        Task sT = new Task(
        	WhatId = sA[0].Id,
            Subject = 'test',
            Related_Campaign__c = subCampaign.Id
        );
        insert sT;
        
        Test.startTest();
        	Task nTask = TaskInitiateFlowController.queryTasks(sT.Id);
        	System.assert(nTask != null);
            try{
            	nTask = TaskInitiateFlowController.queryTasks(null);
            }catch(Exception ex){
                
            }
        Test.stopTest();
    }
}