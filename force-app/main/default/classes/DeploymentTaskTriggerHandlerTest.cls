@isTest
private class DeploymentTaskTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        EBH_TestDataFactory.setUpCustomSettings();
    }

    @isTest
    static void testPopulateFields()
    {
        // Setup        
        // Test
        Test.startTest();
            copado__User_Story__c story = new copado__User_Story__c();
            insert story;

            copado__Deployment_Task__c dtask = new copado__Deployment_Task__c(copado__User_Story__c=story.Id);
            dtask.copado__Type__c = 'Manual Task';
            dtask.copado__dataJSON__c = '{"Task_Owner": ""}';
            List<copado__Deployment_Task__c> tasks = new List<copado__Deployment_Task__c>{dtask};
            //DeploymentTaskTriggerHandler.populateFields(tasks);
            
            insert dtask;
            copado__Deployment_Task__c dtaskSel = [Select Id,copado__dataJSON__c from copado__Deployment_Task__c where Id =: dtask.Id];
        Test.stopTest();
        
        // Verify
        System.assertEquals(UserInfo.getUserId(), ((Map<String,Object>)JSON.deserializeUntyped(dtaskSel.copado__dataJSON__c)).get('Task_Owner')+'',' current usr assigned');
        System.assertEquals('Email', ((Map<String,Object>)JSON.deserializeUntyped(dtaskSel.copado__dataJSON__c)).get('Notify_Task_Owner')+'',' by email');
    }
}