@isTest 
public class GCXMassTaskAssignTest {
    
    
    
    
    static testMethod void testMethod1() 
    {
        List<Campaign> campaigns = EBH_TestDataFactory.createCampaignsWithSellerList(2, 'Test Campaign', 'UK', 'EBH_Campaign',EBH_TestDataFactory.createSellerLists(2, 'Test Seller List', 'Snapshot_Seller_List', System.today() + 365));
        Campaign c = campaigns[0];
        c.EBH_Channel__c=EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
        update c;
        Lead l = EBH_TestDataFactory.createLeads();
        insert l; 
        List<CampaignMember> lcm = new List<CampaignMember>();
        lcm.add ( new CampaignMember(campaignId=c.ID,LeadId=l.id));
        insert lcm;
        
             Test.startTest();
        Test.setCurrentPage(Page.GCXMassTaskAssign);
        ApexPages.StandardController controller = new ApexPages.StandardController(c);
        
        
        AssignTasksController actc = new AssignTasksController(controller);
        
      actc.assignCallTasks();
        actc.cancel();
        c.EBH_Channel__c='Other Channel';
        update c;
        
        controller = new ApexPages.StandardController(c);
        
        
         actc = new AssignTasksController(controller);
        actc.assignCallTasks();
        
      actc.assignCallTasks();
        
        Test.stopTest();

    }
}