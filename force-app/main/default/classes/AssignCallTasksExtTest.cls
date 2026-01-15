/*****************************************************************************************************************************
@ Class:   AssignCallTasksExtTest
@ Author: 	Sambath SENG (sambath.seng@gaea-sys.com)
@ Purpose:	US-0008357 - Upgrade code coverage of AssignCallTasksExt from 0% to 85% 
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.09.2021 / Sambath Seng / Created the Test Class
*****************************************************************************************************************************/
@isTest(seeAllData = False)
public class AssignCallTasksExtTest {

    @isTest
    static void testHandleButtonVisibility() {
        Map<String,String> mapResult = AssignCallTasksExt.handleButtonVisibility();
        System.assertEquals(1, mapResult.values().size());
    }

    @isTest
    static void testAssignCallTasks() {
        EBH_TestDataFactory.setUpCustomSettings();
        List<Account> acc = EBH_TestDataFactory.createAccounts(1, 'EBH_LegalEntity');
        List<Contact> contact = EBH_TestDataFactory.createContacts(1, 'Test Contact', acc[0].id);
        List<Campaign> campaign = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE,null,'Feasibility');
        List<CampaignMember> campMember = EBH_TestDataFactory.createCampaignMembers2(1,campaign[0].Id,contact[0].Id,10,System.today()-5,System.today());
        Test.startTest();
        Map<String,String> mapResult = AssignCallTasksExt.assignCallTasks(campaign[0].Id);
        Test.stopTest();
        System.assertEquals(2, mapResult.values().size());
    }
}