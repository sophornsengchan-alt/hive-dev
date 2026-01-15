/*********************************************************************************************************************************
@ Class:          DocusignRecipientStatusRelatedController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0009928 - [Docusign] Display Related List to show Recipient Status
Shared Controller for LC: DocusignRecipientStatusRelated
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.07.2021 / Sovantheany Dim / Created the class.
*********************************************************************************************************************************/
public class DocusignRecipientStatusRelatedController {
	/************************************* CONSTANT DEFINITION *************************************************/
    
    public static final string SOQL_DOCUSIGN_RECIPIENT_STATUS = 'select Id[PLACEHOLDER] from dsfs__DocuSign_Recipient_Status__c';
    public static final string SOQL_DOCUSIGN_STATUS = 'select Id from dsfs__DocuSign_Status__c';

    /************************************ END OF CONSTANT DEFINITION*******************************************/
    
    /***********************************************************************************************************************************
    @ Method:       getDocuRecipStatus 
    @ Version:      1.0
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0009928 - [Docusign] Display Related List to show Recipient Status
    @ Parameter:    parentId: Contract id
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Param  Id parentId, Integer limitClause
	@ Returns  Map<String,Object> mapResult
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.07.2021 / Sovantheany Dim / Created the Method.
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getDocuRecipStatus(Id parentId,Integer limitClause) {
        Map<String,Object> mapResult = new Map<String,Object>();
        List<ContactsRelatedController.LightningTableColumnWrapper> lstTableColumn = new list<ContactsRelatedController.LightningTableColumnWrapper> ();
        //get list column header
        for(Schema.FieldSetMember fld : SObjectType.dsfs__DocuSign_Recipient_Status__c.FieldSets.DocuRecipStatusRelatedList.getFields()){
            ContactsRelatedController.LightningTableColumnWrapper colWrapper = new ContactsRelatedController.LightningTableColumnWrapper();
            colWrapper.label = fld.getLabel();
            colWrapper.fieldName = fld.getFieldPath();
            colWrapper.type = String.valueof(fld.getType()).toLowerCase();
            colWrapper.sortable = true;
            lstTableColumn.add(colWrapper);
        }
        
        List<dsfs__DocuSign_Status__c > lstDocuStatus = Database.query(SOQL_DOCUSIGN_STATUS+' where dsfs__Contract__c =: parentId');
        List<dsfs__DocuSign_Recipient_Status__c> lstDocuRecipStatus = Database.query(docuRecipStatusQuery+' where dsfs__Parent_Status_Record__c IN: lstDocuStatus order by Name Limit '+limitClause);
        
        ContactsRelatedController.LightningTableWraper ltngTableWrapper = new ContactsRelatedController.LightningTableWraper();
        ltngTableWrapper.tableRecord = lstDocuRecipStatus;
        ltngTableWrapper.tableColumn = lstTableColumn;
        
        mapResult.put('lstWrapper',ltngTableWrapper);
        mapResult.put('docuNumber',lstDocuRecipStatus.size());
        mapResult.put('isMoreValue',lstDocuRecipStatus.size() == limitClause ? true : false);
        return mapResult;
    }
    
    private static String docuRecipStatusQuery {
        get {
            //query docuRecipStatus with placeholder
            String query = SOQL_DOCUSIGN_RECIPIENT_STATUS;
            String PLACEHOLDER = EBH_ConstantsUtility.FR_BLANK;
            //All the fields are being queried which are present in the fieldset
            for(Schema.FieldSetMember fld : SObjectType.dsfs__DocuSign_Recipient_Status__c.FieldSets.DocuRecipStatusRelatedList.getFields()) {
                PLACEHOLDER += EBH_ConstantsUtility.ATCH_COMMA + fld.getFieldPath();
            }
            return !String.isBlank(PLACEHOLDER) ? query.replace(EBH_ConstantsUtility.PLACEH, PLACEHOLDER) : 
                   query.replace(EBH_ConstantsUtility.PLACEH, EBH_ConstantsUtility.FR_BLANK);
        }
    } 
}