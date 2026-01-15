/*****************************************************************************************************************************
@ Class:          CustomDeleteContactController
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        US-0014008 - Make it easier for users to delete contact
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      exceptions: List of Exceptions
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.09.2023 / Sambath Seng / Created Class
@               : 22.04.2024/ vadhanak voun/ US-0015092 - Add "Delete contact reason" on "Delete Contact" button.
*****************************************************************************************************************************/
public with sharing class CustomDeleteContactController {
    
    private final static String MANUAL_RECTYPE = 'EBH_MANUAL';
    private final static String CONTACT_REMOVAL_RECTYPE = 'Contact_Removal_Form';
    private final static String CASE_NEW_STATUS = 'New';
    private final static String CASE_IN_PROGESS_STATUS = 'In Progress';
    private final static String SOQL_CONTACT = 'Select Id,RecordType.DeveloperName From Contact ' ;
    private final static String SOQL_CASE = 'Select Id,Remove_Contact__c,RecordType.DeveloperName From Case ' ;


    /*****************************************************************************************************************************
    @ Method:          checkForValidContact
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0014008 - Make it easier for users to delete contact
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     conId: Contact Id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.09.2023 / Sambath Seng / Created Class
    @               : 22.04.2024/ vadhanak voun/ US-0015092 - Add "Delete contact reason" on "Delete Contact" button.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> checkForValidContact(String conId)
    {       
        Map<String,Object> mResult = new Map<String,Object>
        {
            'recordTypeContactRemovalId' => ApexUtil.getRecordTypeByName('Case', CONTACT_REMOVAL_RECTYPE).Id
        };
        Contact con = getContact(conId);

        // Get existing case
        List<Case> lstExistingCase = Database.query(SOQL_CASE+' WHERE Status IN (:CASE_NEW_STATUS,:CASE_IN_PROGESS_STATUS) AND Remove_Contact__c =:conId AND RecordType.DeveloperName =:CONTACT_REMOVAL_RECTYPE LIMIT 1');

        // Prevent case create if request for remove this contact already been submitted
        if(!lstExistingCase.isEmpty()){
            mResult.put('isValidContact',false);
            mResult.put('message', System.Label.CustomDeleteContact_RequestAlreadySubmitted);
        } 
        // Check Record Type
        else if (con.RecordType.DeveloperName != MANUAL_RECTYPE){
            mResult.put('isValidContact',false);
            mResult.put('message', System.Label.CustomDeleteContact_NotManualContact);
        } else {
            mResult.put('isValidContact',true);
        }

        return mResult;
    }

    /*****************************************************************************************************************************
    @ Method:          checkForValidContact
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0014008 - Make it easier for users to delete contact
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     conId: Contact Id,  caseReason
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.09.2023 / Sambath Seng / Created Class
    @               : 22.04.2024/ vadhanak voun/ US-0015092 - Add "Delete contact reason" on "Delete Contact" button.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> createContactRemovalTicket(String conId,String caseReason)
    {       
        Map<String,Object> mResult = new Map<String,Object>();
        RecordType contactRemoveRT = ApexUtil.getRecordTypeByName('Case', CONTACT_REMOVAL_RECTYPE);
        
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        Case contactRemoveTicket = new Case(
            RecordTypeId = contactRemoveRT.Id,
            Remove_Contact__c = conId,
            Status = 'New',
            I_want_to_be_notified__c = true,
            // Summary__c = summary, //summary already provided by the Flow as "Wrong data"
            Reason = caseReason
        );

        contactRemoveTicket.setOptions(dmo);
        //NK:23/04/2024:US-0015092
        //insert contactRemoveTicket;        
        try 
        {
            Database.SaveResult[] saveResults = ApexSafe.dml().doInsert(new List<Case>{contactRemoveTicket}, true);
            mResult.put('status','ok');   
            mResult.put('message', System.Label.CustomDeleteContact_SuccessMessage); 
        }catch(DMLException dex)
        {
            mResult.put('status','ko');mResult.put('message',dex.getDmlMessage(0));mResult.put('errorDetail',dex.getStackTraceString());
        }
            
        return mResult;
    }

    private static Contact getContact(String conId)
    {  
        conId = String.escapeSingleQuotes(conId);
        return Database.query(SOQL_CONTACT+' WHERE Id =:conId');
    }
}