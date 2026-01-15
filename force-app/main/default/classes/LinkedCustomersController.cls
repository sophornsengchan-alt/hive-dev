/*********************************************************************************************************************************
@ Class:          LinkedCustomersController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0009214 - [Linked Acc]Enable Linked B2C Customers to be shown in Customer 360
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.03.2021 / Sovantheany Dim / Created the class.
                : 17.03.2025 / Bora Chhorn / US-0016865 - Display Linked Customers on the Seller 360
                : 01.04.2025 / Sothea Horn / US-0017049 - Validate Linkage and capture first call feedback
*********************************************************************************************************************************/
public class LinkedCustomersController {
    /************************************* CONSTANT DEFINITION *************************************************/
    
    private static final string SOQL_SELLER = 'Select Id,Parent.Name[PLACEHOLDER] From Account';
    private static final string SOQL_SELLER_Parent = 'Select Id, Linked_Acc_Group_Id__c From Account';
    private static final string SELLER_RECORDTYPE = 'EBH_Seller';
    private final static String STATUS_OK = 'ok';
	private final static String STATUS_KO = 'ko';

    /************************************ END OF CONSTANT DEFINITION*******************************************/
    
    /***********************************************************************************************************************************
    @ Method:       getAccounts 
    @ Version:      1.0
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0009214 - [Linked Acc]Enable Linked B2C Customers to be shown in Customer 360
    @ Parameter:    parentId: AccountId, limitClause : limit soql query
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns  Map<String,Object>
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 23.03.2021 / Sovantheany Dim / Created the Method.
                    : 17.03.2025 / Bora Chhorn / US-0016865 - Display Linked Customers on the Seller 360
                    : 03.04.2025 / Sothea Horn / US-0017049 - Validate Linkage and capture first call feedback
	***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getAccounts(Id parentId, Integer limitClause, String fieldSetName) {
        Map<String,Object> mapResult = new Map<String,Object>();
        List<ContactsRelatedController.LightningTableColumnWrapper> lstTableColumn = new list<ContactsRelatedController.LightningTableColumnWrapper> ();
        List<Account> lstAccount = new List<Account>();
    
        //get Linked_Acc_Group_Id__c from parent seller
        List<Account> parentSeller = Database.query(SOQL_SELLER_Parent+' where Linked_Acc_Group_Id__c != null AND Id =: parentId AND recordtype.DeveloperName =: SELLER_RECORDTYPE');
        String linkCustomer = parentSeller.isEmpty()?'':parentSeller[0].Linked_Acc_Group_Id__c;
        if(!String.isBlank(linkCustomer)){
            //get list Account related to Seller.Linked_Acc_Group_Id__c
	        lstAccount = Database.query(getAccountQuery(fieldSetName)+' where Linked_Acc_Group_Id__c != null AND Linked_Acc_Group_Id__c =: linkCustomer AND Id !=: parentId AND recordtype.DeveloperName =: SELLER_RECORDTYPE order by EBH_OracleID__c Limit '+limitClause);
	        //get list column header
            //BR 17.03.2025 / US-0016865
            Schema.DescribeSObjectResult objSchema = Schema.getGlobalDescribe().get('Account').getDescribe();
            Schema.FieldSet fieldSet = objSchema.fieldSets.getMap().get(fieldSetName);

	        for(Schema.FieldSetMember fld : fieldSet.getFields()){
	        	ContactsRelatedController.LightningTableColumnWrapper colWrapper = new ContactsRelatedController.LightningTableColumnWrapper();
	        	colWrapper.label = fld.getLabel();
	        	colWrapper.fieldName = fld.getFieldPath();
	        	colWrapper.type = String.valueof(fld.getType()).toLowerCase();
	        	colWrapper.sortable = true;
	        	lstTableColumn.add(colWrapper);
	        }
        }

        ContactsRelatedController.LightningTableWraper ltngTableWrapper = new ContactsRelatedController.LightningTableWraper();
        ltngTableWrapper.tableRecord = lstAccount;
        ltngTableWrapper.tableColumn = lstTableColumn;
        
        mapResult.put('lstWrapper',ltngTableWrapper);
        mapResult.put('accountNumber',ltngTableWrapper.tableRecord.size() > 0 ? ltngTableWrapper.tableRecord.size() : 0);
        mapResult.put('isMoreValue',lstAccount.size() == limitClause ? true : false);
        mapResult.put('sitePrefix',Site.getPathPrefix());
        //01-April-2025 - Sothea - Get picklist values of Account.ValidateLinkage__c (US-0017049)
        mapResult.put('validateLinkagePicklistValues',ApexUtil.getPicklistValues(Account.ValidateLinkage__c));

        return mapResult;
    }
    
    private static String getAccountQuery(String fieldSetName) {
        //query account with placeholder
        String query = SOQL_SELLER;
        String PLACEHOLDER = EBH_ConstantsUtility.FR_BLANK;
        //All the fields are being queried which are present in the fieldset
        Schema.FieldSet fieldSet = SObjectType.Account.FieldSets.getMap().get(fieldSetName);
        for(Schema.FieldSetMember fld : fieldSet.getFields()) {
            PLACEHOLDER += EBH_ConstantsUtility.ATCH_COMMA + fld.getFieldPath();
        }
        return !String.isBlank(PLACEHOLDER) ? query.replace(EBH_ConstantsUtility.PLACEH, PLACEHOLDER) : 
                query.replace(EBH_ConstantsUtility.PLACEH, EBH_ConstantsUtility.FR_BLANK);

    } 

    /**************************************************************************************************
    @ Method:       updateLinkedCustomers 
    @ Version:      1.0
    @ Author:       Sothea Horn (sohorn@ebay.com)
    @ Purpose:      US-0017049 - Validate Linkage and capture first call feedback 
    @ Parameter:    List<Account> listUpdatedLinkedCustomers
    @ Created  :    01 April 2025
    ***************************************************************************************************/
    @AuraEnabled
	public static Map<String,Object> updateLinkedCustomers(List<Account> listUpdatedLinkedCustomers) {
		Map<String,Object> mapResponseData = new Map<String,Object>();
		Savepoint sp = Database.setSavepoint();
		try {
			ApexSafe.dml().secCheck(false).doUpdate(listUpdatedLinkedCustomers, true);
			mapResponseData.put('status',STATUS_OK);
		}catch(Exception ex){
			Database.rollback(sp);
			mapResponseData.put('status',STATUS_KO);
			mapResponseData.put('error',ex.getMessage());
		}
		return mapResponseData;
	}
}