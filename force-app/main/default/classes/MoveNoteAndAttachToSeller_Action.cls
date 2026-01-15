/***************************************************************************************************************************************
@ Class:          MoveNoteAndAttachToSeller_Action
@ Version:        1.0
@ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:        US-0007654 [EU & AU] Move Activities & Notes to seller
----------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.06.2020 / Acmatac SEING / Created the class.
***************************************************************************************************************************************/
public without sharing class MoveNoteAndAttachToSeller_Action {
    public static final String PROJECT_SOQL = 'SELECT Id, EBH_Seller__c, RecordTypeId FROM EBH_Project__c ';
    public static final String CDL_SOQL = 'SELECT Id, LinkedEntityId, ContentDocumentId, ShareType FROM ContentDocumentLink ';


    /***************************************************************************************************************************************
    @ Method:         moveNoteAndAttachToSeller
    @ Version:        1.0
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0007654 [EU & AU] Move Activities & Notes to seller
    ----------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.06.2020 / Acmatac SEING / Created the method.
    ***************************************************************************************************************************************/
    @InvocableMethod(label='Move Note and Attachment from Project to Seller')
    public static void moveNoteAndAttachToSeller(List<ID> projIds) {
        if(projIds.isEmpty()) return;

        // Only one Project record will pass through this method
        Id projId = projIds.get(0);
        Id projRTId_AUOnboarding = ApexUtil.getRecordTypeByName('EBH_Project__c','eBayAUSMB').Id;
        Id projRTId_EUOnboarding = ApexUtil.getRecordTypeByName('EBH_Project__c','EUOnboarding').Id;
        EBH_Project__c oneProj = Database.query(PROJECT_SOQL + ' WHERE Id =: projId');

        if(String.isNotBlank(oneProj.EBH_Seller__c)){
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            List<ContentDocumentLink> cdlExt = new List<ContentDocumentLink>();
                
            for(ContentDocumentLink cdl : Database.query(CDL_SOQL + ' WHERE LinkedEntityId =: projId')) {
                ContentDocumentLink cloned = cdl.clone();
                cloned.LinkedEntityId = oneProj.EBH_Seller__c;
                cloned.ShareType = cdl.ShareType;
                cdlList.add(cloned);
                cdlExt.add(cdl);
            }
            if(!cdlList.isEmpty()){
                insert cdlList; // new CDL records
                delete cdlExt; // delete old CDL records
            }
        }



    }
}