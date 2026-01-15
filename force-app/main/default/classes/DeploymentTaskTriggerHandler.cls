/********************************************************************************************************************************
@ Class:          DeploymentTaskTriggerHandler
@ Version:        1.0
@ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Trigger handler for Deployment Task object (copado__Deployment_Task__c)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.05.2024 /  vadhanak voun / Created the class. US-0015246 - Deployment Task Owner must be populated
*********************************************************************************************************************************/
public with sharing class DeploymentTaskTriggerHandler {
    final static String TASK_TYPE_MANUAL = 'Manual Task';
    final static String TASK_OWNER_EMPTY = '000000000000000'; //copado assigns this such value when the task owner is empty

    /*********************************************************************************************************************************
    @ Method:         populateFields
    @ Version:        1.0
    @ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        US-0015246 - Deployment Task Owner must be populated
    @ Param:          List<copado__Deployment_Task__c> listDTask
    @ Event:          Before Insert
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.05.2024 / vadhanak voun / Created the method.    
    *********************************************************************************************************************************/
    public static void populateFields(List<copado__Deployment_Task__c> listDTask)
    {
         
        for(copado__Deployment_Task__c dTask : listDTask)
        {
            //Only for manual tasks to have the task owner populated
            if(dTask.copado__Type__c==TASK_TYPE_MANUAL && String.isNotBlank(dTask.copado__dataJSON__c))
            {
                checkTaskOwner(dTask);
            }
        }        
    }

    /*********************************************************************************************************************************
    @ Method:         checkTaskOwner
    @ Version:        1.0
    @ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        US-0015246 - Deployment Task Owner must be populated
    @ Param:          List<copado__Deployment_Task__c> listDTask
    @ Event:          Before Insert
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.05.2024 / vadhanak voun / Created the method.    
    *********************************************************************************************************************************/
    private static void checkTaskOwner(copado__Deployment_Task__c dTask )
    {
        Map<String, Object> dataJSON = (Map<String, Object>) JSON.deserializeUntyped(dTask.copado__dataJSON__c);
        String taskOwner = (String)dataJSON.get('Task_Owner');
        if(String.isBlank(taskOwner) || taskOwner==TASK_OWNER_EMPTY)
        {
            dataJSON.put('Task_Owner',UserInfo.getUserId());
            dataJSON.put('Notify_Task_Owner', 'Email');
            dTask.copado__dataJSON__c = JSON.serialize(dataJSON);
        }
    }
}