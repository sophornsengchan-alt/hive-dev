/*********************************************************************************************************************************
 * @ Class:          DocusignEnvelopeEventTriggerHandler
 * @ Version:        1.0
 * @ Story:          US-0016875: Use System User for DocuSign Workflow Updates to Bypass Validation Rules      
 * @ Purpose:        Trigger handler for DocusignEnvelopePETrigger
----------------------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************************/


public without sharing class DocusignEnvelopeEventTriggerHandler {
    
     /*********************************************************************************************************************************
    @ Method:       updateContractRecord
    @ Purpose:      To update contract status when platform event is published. using deployment user to update contract record.
    @----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    public static void updateContractRecord(List<Docusign_Envelope_Status__e> newDoc){

        list<Contract> contractList = new list<Contract>();
    
        for (Docusign_Envelope_Status__e event : newDoc) {
            Contract contractObj = new contract();
            contractObj.id = event.Contract_id__c;
            contractObj.Status = event.Status__c;
            contractList.add(contractObj);
        }
        try{
            List<Database.SaveResult> listResult = ApexSafe.dml().secCheck(false).doUpdate(contractList, true); 

        }catch (Exception e) {
            EBH_ApexLogger.logError(new List<Exception> { e }, 'DocusignEnvelopePETrigger','Contract status update from platform event');
        }
    
    }

}