/*********************************************************************************************************************************
@ Class:          ContactsRelatedController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0007434 - [AU & EU] Related Contact
Shared Controller for LC: ContactsRelated
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.04.2020 / Sovantheany Dim / Created the class.
*********************************************************************************************************************************/
public class ContactsRelatedController {
	/************************************* CONSTANT DEFINITION *************************************************/
    
    public static final string SOQL_SELLER = 'select ParentId from Account';

    /************************************ END OF CONSTANT DEFINITION*******************************************/
    
	/***********************************************************************************************************************************
    @ Method:       getContacts 
    @ Version:      1.0
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0007434 - [AU & EU] Related Contact
    @ Parameter:    parentId: project id
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns  Map<String,Object>
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.04.2020 / Sovantheany Dim / Created the Method.
    @				17.06.2020 / Sovantheany Dim/ Update method : US-0007668 - [EU & AU] Move Contacts from Legal Entity to seller
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getContacts(Id parentId) {
        Map<String,Object> mapResult = new Map<String,Object>();

        Boolean isNotScalingRecordType = false;

        String legalEntityId = '';
        String objectName = parentId.getSObjectType().getDescribe().getName();
        String contactHeader = 'Contacts';
        //TH: US-0007668: Component Contact related list  can see from seller
        if(objectName == 'Account'){
        	Account acc = Database.query(SOQL_SELLER+' where id =: parentId');
        	legalEntityId = acc.ParentId;
        	contactHeader = 'Legal Entity Contacts';
        }
        //TH:US-0007434: Component Contact related list  can see from Project
        else if(objectName == 'EBH_Project__c'){
        	EBH_Project__c project = Database.query(EBH_ConstantsUtility.SOQL_PROJECT+' where id =: parentId');
        	legalEntityId = project.LegalEntity__c;
        }

        //LA/23/06/2020:US-0007635  hide Contact related list from Scaling record
        List<EBH_Project__c> projectWithScalingRecordType = [SELECT Id, Name FROM EBH_Project__c WHERE Id =:parentId AND RecordType.DeveloperName='Scaling' LIMIT 1];
        if(projectWithScalingRecordType.size() == 0){
            isNotScalingRecordType = true;
        }


        //get list contact related to Project
        List<Contact> lstContact = Database.query(contactQuery+' where AccountId != null AND AccountId =: legalEntityId order by Name '+EBH_ConstantsUtility.SOQL_CONTACT_LIMIT);
        //get list column header
        List<LightningTableColumnWrapper> lstTableColumn = new list<LightningTableColumnWrapper> ();
        for(Schema.FieldSetMember fld : SObjectType.Contact.FieldSets.ContactRelatedProject.getFields()){
        	LightningTableColumnWrapper colWrapper = new LightningTableColumnWrapper();
        	colWrapper.label = fld.getLabel();
        	colWrapper.fieldName = fld.getFieldPath();
        	colWrapper.type = String.valueof(fld.getType()).toLowerCase();
        	colWrapper.sortable = true;
        	lstTableColumn.add(colWrapper);
        }
        LightningTableWraper ltngTableWrapper = new LightningTableWraper();
        ltngTableWrapper.tableRecord = lstContact;
        ltngTableWrapper.tableColumn = lstTableColumn;
        mapResult.put('lstWrapper',ltngTableWrapper);
        mapResult.put('contactNumber',ltngTableWrapper.tableRecord.size());
        mapResult.put('isMoreValue',lstContact.size() == 6 ? true : false);
        mapResult.put('legalEnityId',legalEntityId);
        mapResult.put('isViewAll',lstContact.isEmpty() ? false:true );


        //mapResult.put('legalEnityRelatdLink',String.isBlank(legalEntityId) ? '' : '/lightning/r/'+legalEntityId+'/related/Contacts/view');
        mapResult.put('contactHeader',contactHeader);
        mapResult.put('sitePrefix',Site.getPathPrefix());
        mapResult.put('isNotScalingRecordType',isNotScalingRecordType);

        return mapResult;
    }
    @AuraEnabled
    public static Id getRecTypeId(){
        RecordType manaulRecordType = ApexUtil.getRecordTypeByName('Contact',EBH_ConstantsUtility.CONTACT_MANAUL_RECORDTYPE);        
        return manaulRecordType.Id;
    }
    private static String contactQuery {
        get {
            //query contact with placeholder
            String query = EBH_ConstantsUtility.SOQL_CONTACT_FIELDSET;
            String PLACEHOLDER = EBH_ConstantsUtility.FR_BLANK;
            //All the fields are being queried which are present in the fieldset
            for(Schema.FieldSetMember fld : SObjectType.Contact.FieldSets.ContactRelatedProject.getFields()) {
                PLACEHOLDER += EBH_ConstantsUtility.ATCH_COMMA + fld.getFieldPath();
            }
            return !String.isBlank(PLACEHOLDER) ? query.replace(EBH_ConstantsUtility.PLACEH, PLACEHOLDER) : query.replace(EBH_ConstantsUtility.PLACEH, EBH_ConstantsUtility.FR_BLANK);
        }
    }  
    public class LightningTableColumnWrapper {
    	 @AuraEnabled
    	 public string label {get;set;}
    	 @AuraEnabled
    	 public String fieldName {get;set;}
    	 @AuraEnabled
    	 public string type {get;set;}
    	 @AuraEnabled
    	 public boolean sortable {get;set;}
    }
    public class LightningTableWraper{
    	@AuraEnabled
    	public List<sObject> tableRecord {get;Set;}
    	@AuraEnabled
    	public List<LightningTableColumnWrapper> tableColumn {get;set;}
    }   
}