/*********************************************************************************************************************************
@ Class:          CreateProjectFromTaskController
@ Version:        1.0
@ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:        US-0007988 [AU] Copy related task fields when create new project.
                Controller for CreateProjectFromTask.cmp.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.08.2020 / Acmatac SEING / Created the class.
*********************************************************************************************************************************/

public without sharing class CreateProjectFromTaskController {
    public static final RecordType PROJ_SCALING_RT = ApexUtil.getRecordTypeByName('EBH_Project__c', 'Scaling');

    /*********************************************************************************************************************************
    @ Purpose:  Retrieve Task and generate uniqueId.
                uniqueId will be using for getting Project record back after e.force:createRecord event finished.
    *********************************************************************************************************************************/
    @AuraEnabled
    public static RemoteResponse getTaskRec(Id recordId) {
        RemoteResponse response;
        try {
            List<Task> oTask = QueryUtil.queryRecords('Task', new Set<String>{recordId});
            String uniqueId = apexUtil.genUniqueString(20);
            response = new RemoteResponse('', RemoteResponse.STATUSCODE_OK, new Map<String, Object> {'Record' => oTask.get(0), 'recordTypeId' => PROJ_SCALING_RT.Id, 'uniqueId' => uniqueId});
        } catch(Exception e) {
            response = new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
        return response;
    }

    /*********************************************************************************************************************************
    @ Purpose:  Link Project back to Task
    *********************************************************************************************************************************/
    @AuraEnabled
    public static RemoteResponse linkProjectToTask(Id recordId, String uniqueId) {
        RemoteResponse response;
        try {
            List<EBH_Project__c> oProj = QueryUtil.queryRecords('EBH_Project__c', 'UniqueKey__c=:value1', new Map<String,Object>{'value1'=>uniqueId});
            update new Task(Id=recordId, RelatedProject__c=oProj.get(0).Id);
            response = new RemoteResponse('', RemoteResponse.STATUSCODE_OK);
        } catch(Exception e) {
            response = new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
        return response;
    }
}