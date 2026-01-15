/*********************************************************************************************************************************
@ Class:          EBH_ContractApprovalController
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Controller for Lightning component - Contract request submit for approval
                  EPH-14 : Contract Approval
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.05.2017 / NEHA LUND / Created the class.
*********************************************************************************************************************************/

public with sharing class EBH_ContractApprovalController {
  
    /*****************************************************************************************************************************
    @ Method:         submitApprovalRequest
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        receives the Contract record & comments
    ------------------------------------------------------------------------------------------------------------
    @ Parameter:      Pssed through the action i.e. when Contract is submitted for an approval
    ------------------------------------------------------------------------------------------------------------
    @ Change history: 26.05.2017 / NEHA LUND / Created the  Method.
    */
    @AuraEnabled
    public static String submitApprovalRequest(Id contractId, String comments) {
        try{
            //submitting the approval process
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments(comments);
            
            //EPH-5469 - Copy comments to Requester Notes fields on Contract
            if(comments != null){
                
                //Query existing Requester Notes so that will be appended everytime
                Contract conRecord = new Contract(Id = contractId);
                
                //EPH-5476 - to let anyone submit the contract for an approval
                /*Only contract owner can submit the record for an approval, 
                when the user who is not contract owner will submit the record then that user is set as a contract owner via code 
                so that record could be submitted for an approval and not blocked.
                */
                
                conRecord.ownerId = userInfo.getUserID();
                
                /*Commenting this as part of EPH-5586 - it is an editable field on contract to capture notes
                if( conRecord.EBH_RequesterNotes__c == null){
                    
                    conRecord.EBH_RequesterNotes__c = '';
                }
                
                conRecord.EBH_RequesterNotes__c += '\n'+ comments; */
                
                //update the Contract
                Database.update(conRecord);
            }
            req1.setObjectId(contractId);
            Approval.ProcessResult result = Approval.process(req1);
        } catch(Exception ex){
            EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                    EBH_ConstantsUtility.CAC_CLASSNAME, EBH_ConstantsUtility.CAC_METHOD);
        }       
        return '';
    }
    
    /*****************************************************************************************************************************
    @ Method:         validateBUApprover
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        receives the Contract record ID 
                      - To throw an error message, if Contract Value exceeds 500k, then BU Approver is required
    ------------------------------------------------------------------------------------------------------------
    @ Parameter:      Pssed through the action i.e. when Contract is submitted for an approval
    ------------------------------------------------------------------------------------------------------------
    @ Change history: 26.05.2017 / NEHA LUND / Created the  Method.
    */
    @AuraEnabled
    public static String validateBUApprover(Id contractId) {
        Contract contractRecord  = Database.query(EBH_ConstantsUtility.CAC_QUERYSTRING);

        List<ContentDocumentLink> atchRecords = [SELECT id from ContentDocumentLink where LinkedEntityId = :contractRecord.Id];
           
         if(contractRecord.Status != EBH_ConstantsUtility.CONTRACT_DRAFTSTATUS &&
            contractRecord.Status != EBH_ConstantsUtility.CONTRACT_NEGOTIATIONSTATUS &&
            contractRecord.Status != EBH_ConstantsUtility.CONTRACT_PENDINGSTATUS && 
            contractRecord.Status != EBH_ConstantsUtility.CONTRACT_FINANCESENTSTATUS){
			
            return Label.EBH_BUApproverValidationMessage;
        }
        else if( contractRecord.Status.equalsIgnoreCase( EBH_ConstantsUtility.CONTRACT_PENDINGSTATUS) || 
            contractRecord.Status.equalsIgnoreCase( EBH_ConstantsUtility.CONTRACT_FINANCESENTSTATUS)) {
             
            return Label.EBH_RecordInApprovalProcess;
        }else
        if( atchRecords.isEmpty() && contractRecord.Status.equalsIgnoreCase( EBH_ConstantsUtility.CONTRACT_NEGOTIATIONSTATUS) )
        {
              return 'Please attach the Final PAT or Legal stamped Contracts before submitting for Contract Post-Check.';
            
        }
        return '';   
    }
}