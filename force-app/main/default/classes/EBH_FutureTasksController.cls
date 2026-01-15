/*********************************************************************************************************************************
@ Class:          EBH_FutureTasksController
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Controller for VF page: EBH_FutureTasks
                  EPH-2551 : Future Tasks
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.09.2017 / NEHA LUND / Created the class.
*********************************************************************************************************************************/
public with sharing class EBH_FutureTasksController {

   
    public List<Task> tasks { get; set; }    //to get the tasks created date greater than or equal to Today
    
    public integer taskCount { get; set; }
    
    /*****************************************************************************************************************************
    @ Constructor:    EBH_FutureTasksController
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        to get the Training Material records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.09.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public EBH_FutureTasksController() {
       
       taskCount = Database.countQuery(EBH_ConstantsUtility.FTC_COUNTTASKQUERY);
       tasks = Database.query(taskQuery); 
       
       
    }
    
    public void getMoreTasks(){
        String tskQ = taskQuery.replace('LIMIT 5', '');
        tasks = Database.query(tskQ);
       
    }
     public String taskQuery {
        get {
            //query campaign members using pagenumber offset
            String query = EBH_ConstantsUtility.FTC_TASKQUERY;
            
            String PLACEHOLDER = EBH_ConstantsUtility.FR_BLANK;
            
            //All the fields are being queried which are present in the fieldset
            for(Schema.FieldSetMember fld : SObjectType.Task.FieldSets.EBH_TaskFields.getFields()) {
                PLACEHOLDER += EBH_ConstantsUtility.ATCH_COMMA + fld.getFieldPath();
            }
            
            return !String.isBlank(PLACEHOLDER) ? query.replace(EBH_ConstantsUtility.PLACEH, PLACEHOLDER) : 
                   query.replace(EBH_ConstantsUtility.PLACEH, EBH_ConstantsUtility.FR_BLANK);
        }
    }
}