/*********************************************************************************************************************************
@ Class:          AssignCallTaskController
@ Version:        1.0
@ Author:         
@ Purpose:        Controller Class for Deal list view buttons pages
@                 EPH-31 : Campaign Review and Measurement
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.08.2018 /  / Created the class.

*********************************************************************************************************************************/
public without sharing class AssignCallTaskController {
    
    
    public static String DATE_FORMAT = 'yyyy-MM-dd';
    public Task task{get;set;}
    public List<Task>selectedTask{get;set;}
    
    public String reUrl{get;set;}
    
    
    
    /*****************************************************************************************************************************
@ Method:         EBH_DealController
@ Version:        1.0
@ Author:          
@ Purpose:        Constructor
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      ApexPages.StandardController controller
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.11.2017 /   / Created the  Method.
*****************************************************************************************************************************/
    public AssignCallTaskController(ApexPages.StandardSetController controller){
        selectedTask = (List<Task>)controller.getSelected();
        selectedTask = [Select Id,WhoId , who.name, what.name,WhatId   ,WhoCount ,WhatCount ,Subject  ,ActivityDate ,Status ,Priority ,
                        OwnerId ,owner.name ,Description ,Type,AccountId,account.name,CallType ,CallDisposition ,CallObject,EBH_LegacyID__c,
                        EBH_CampaignMemberId__c,EBH_DMC__c ,EBH_Response__c  From task Where Id IN :selectedTask];
        
        reUrl = controller.cancel().getUrl();
        task = new Task();
        task.OwnerId=userinfo.getUserId();
        
    

    }

    
           
    public pagereference assignTasks(){
        if (task.OwnerId==null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must choose a valid team mate'));
        }else {
            
            for (Task t : selectedTask)            {
                t.ownerId=task.OwnerId;
            }
            try{
                update selectedtask;    
            }catch(Exception e){
                System.debug('>> Exception updating tasks' + e.getMessage());
                EBH_ApexLogger.logError(new List<Exception> { e }, 'AssignCallTaskController','assignTask');
                return null;
            }
            
            
            
            
        }
        
        
        
        return new PageReference(reUrl);        
    }
    public pageReference cancel(){
        return new PageReference(reUrl);        
        
    }
}