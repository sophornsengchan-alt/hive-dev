/*********************************************************************************************************************************
@ Class:          CloneTaskController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0008191 - [AU & EU] Create follow up task from a closed task record
@ description:	  Controller for Aura : CloneTask
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.09.2020 / Sovantheany Dim / Created the class.
*********************************************************************************************************************************/
public without sharing class CloneTaskController {
    /****************************************************************************************************************************
	* CONSTANTS DEFINITION
	*****************************************************************************************************************************/
	private static String SOQL_TASK = 'Select t.WhoId, t.WhatId, t.Type, t.Survey_ID__c, t.Status, t.OwnerId, t.EBH_CampaignMemberId__c, t.EBH_Account__c,t.RecordTypeId,t.RecordType.DeveloperName From Task t';
	/************************************END CONSTANTS DEFINITION*************************************************************/
    /*****************************************************************************************************************************
    /*****************************************************************************************************************************
	@ Method:   apexCloneTask
	@ Version:  1.0
	@ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
	@ Purpose:  US-0008191 - [AU & EU] Create follow up task from a closed task record
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      parentId:  taskId
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 11.09.2020 / Sovantheany Dim / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexCloneTask(String parentId)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        try
		{
            List<Task> tasks = Database.query(SOQL_TASK + ' Where Id=:parentId');
            Set<String> sStatus = new Set<String>{'Completed','Closed'};
            if(tasks[0].RecordType.DeveloperName == 'X3CallAttempts' && sStatus.contains(tasks[0].Status)){
                Task cloneTask = tasks[0].clone(false,true,false,false);
                //cloneTask.Subject = tasks[0].Subject == null ? '':tasks[0].Subject + '_Clone';
                cloneTask.RecordTypeId = ApexUtil.getRecordTypeByName('Task','Standard_Task').Id;
                cloneTask.Status = 'Open';
                insert cloneTask;
                mapResult.put('status','ok');
                mapResult.put('taskId',cloneTask.Id+'');
            }else{
                mapResult.put('status','ko');
                mapResult.put('error',System.label.Err_CloneTask_Invalid_Status);
            }
            
        } catch(DmlException ex)
		{
			mapResult.put('status','ko');mapResult.put('error',ex.getDmlMessage(0));
		}catch(Exception ex2)
		{
			mapResult.put('status','ko');mapResult.put('error',ex2.getMessage());
		}
        return mapResult;
    }

}