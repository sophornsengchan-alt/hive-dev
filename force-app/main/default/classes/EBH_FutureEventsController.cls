/*********************************************************************************************************************************
@ Class:          EBH_FutureEventsController
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Controller for VF page: EBH_FutureEvents - This is without sharing - public  
                  EPH-2551 : Future Events
---------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.09.2017 / NEHA LUND / Created the class.
*********************************************************************************************************************************/
public without sharing class EBH_FutureEventsController {

   
    public List<event> tasks { get; set; }    //training materials to display as links
    public integer eventCount { get; set; }

    /*****************************************************************************************************************************
    @ Constructor:    EBH_TrainingMaterialsController
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        to get the future and today events
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.09.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public EBH_FutureEventsController() {
       
       eventCount = Database.countQuery(EBH_ConstantsUtility.FTC_COUNTEVENTQUERY);
       tasks = Database.query(taskQuery); 
       
    }
    public void getMoreTasks(){
        String tskQ = taskQuery.replace('LIMIT 5', '');
        tasks = Database.query(tskQ);
       
    }
     public String taskQuery {
        get {
            //query campaign members using pagenumber offset
            String query = EBH_ConstantsUtility.FTC_EVENTQUERY;
            
            String PLACEHOLDER = EBH_ConstantsUtility.FR_BLANK;
            
            //All the fields are being queried which are present in the fieldset
            for(Schema.FieldSetMember fld : SObjectType.Event.FieldSets.EBH_EventFields.getFields()) {
                PLACEHOLDER += EBH_ConstantsUtility.ATCH_COMMA + fld.getFieldPath();
            }
            
            return !String.isBlank(PLACEHOLDER) ? query.replace(EBH_ConstantsUtility.PLACEH, PLACEHOLDER) : 
                   query.replace(EBH_ConstantsUtility.PLACEH, EBH_ConstantsUtility.FR_BLANK);
        }
    }
}