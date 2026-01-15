/*********************************************************************************************************************************
@ Class:         DealStatementSummaryAttachController
@ Version:       1.0
@ Author:        Sovantheany.dim(sovantheany.dim@gaea-sys.com)
@ Purpose:       US-0011130 - Email Notification for Deal Statement Summary approval
@				AC 3:Once the Approval process is completed, "Status" is changed to "Approved" and 
@				the system should automatically trigger an email notification with an excel file(statement summary previously generated as per AC 1) 
@				+ another excel file with Summary Approval
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.02.2022 / Sovantheany.dim(sovantheany.dim@gaea-sys.com)
@                   17.05.2022/ Sovantheany.dim : US-0011511 - Additional approval step for Deal Release Statements
*********************************************************************************************************************************/
public with sharing class DealStatementSummaryAttachController {
    public static String soqlStepAndItem = 'Select Id, TargetObjectId,TargetObject.Name, SubmittedById,SubmittedBy.Name, Status, ProcessDefinitionId, SystemModstamp, '+
                                     '  LastActorId,LastActor.Name,  CreatedDate,  CompletedDate, '+ 
                                     '(Select Id, TargetObjectId, StepStatus, ProcessNodeId,ProcessNode.Name, '+ 
                                      'OriginalActorId,OriginalActor.Name, ActorId,Actor.Name,  Comments,  CreatedDate From StepsAndWorkitems order by CreatedDate Desc limit 2) '+
                                      'From ProcessInstance';
    public static String soqlAttachment = 'select name, contentType, body from Attachment where parentId =: dssID order by CreatedDate desc limit 1';
    public Deal_Statement_Summary__c dss { get; set; }
    public String attBody{get;set;}
    private static Map<String,String[]> mapHeaderCol = new Map<String,String[]>
    {
    	'US'=>new String[]{'\uFEFFDeal Statement Summary Name','Submitter','Date Submitted','Assigned To','Actual Approver'}
    };

    /*****************************************************************************************************************************
    @ Method:       getattachments
    @ Author:       sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0011130 - Email Notification for Deal Statement Summary approval
    @               get existing Attachement
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.03.2022 / sovantheany dim / US-000942 Created the method.
    @*****************************************************************************************************************************/
    public List<Attachment> getattachments() {
           List<Attachment> atts = new List<Attachment>();
           String dssID = dss.Id;
           atts = Database.query(soqlAttachment);
           attBody = atts.isEmpty()?'':atts[0].body.toString();   
        return atts;
    }
    /*****************************************************************************************************************************
    @ Method:       getsummaryStatementBody
    @ Author:       sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0011130 - Email Notification for Deal Statement Summary approval
    @               build Deal Statment Summary Approval excel
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.03.2022 / sovantheany dim / US-000942 Created the method.
    @*****************************************************************************************************************************/
    public String getsummaryApprovalBody() {
        List<List<String>> listRows = new List<List<String>>{new String[]{'Deal Statement Summary Approval'}};
        //add empty line
        listRows.add(new List<String>{''});
        String key = 'US';
        String[] listHeader = mapHeaderCol.containsKey(key)?mapHeaderCol.get(key):null;
        listRows.add(listHeader);
        String dssID = dss.Id;
        String whereClauseAndlimitClause = ' where TargetObjectId =: dssID order by CreatedDate desc limit 1';
        for(ProcessInstance p : Database.query(soqlStepAndItem+ whereClauseAndlimitClause)){
            for(ProcessInstanceHistory  h : p.StepsAndWorkitems){
                List<String> listCells = new List<String>{p.TargetObject.Name,p.SubmittedBy.Name,h.CreatedDate.format(),h.OriginalActor.Name,h.Actor.Name};
                listRows.add(listCells);
            }
        }
        //generate to excel file
        List<ExcelGenerator.xSheet> listSheets = new List<ExcelGenerator.xSheet>();
        ExcelGenerator.xSheet sheetSTP = new ExcelGenerator.xSheet('Sheet1',listRows);
        listSheets.add(sheetSTP);
        ExcelGenerator generator = new ExcelGenerator(userinfo.getname(),listSheets,2);
        generator.generateWorkBook();
        String xml = generator.getWorkbookXML();
        return xml;
    }
    
}