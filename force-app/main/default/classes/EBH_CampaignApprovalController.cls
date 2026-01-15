/************************************************************************************************************************************************
@ Class:          EBH_CampaignApprovalController
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Controller for Lightning component - Campaign request submit for approval
                  EPH-23 : Campaign Requests
-------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.05.2017 / NEHA LUND / Created the class.
************************************************************************************************************************************************/

public with sharing class EBH_CampaignApprovalController {
  
    /********************************************************************************************************************************************
    @ Method:         submitApprovalRequest
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        receives the Campaign record & comments
    ---------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Pssed through the action i.e. when Campaign is submitted for an approval
    ---------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.09.2017 / NEHA LUND / Created the  Method.
    ********************************************************************************************************************************************/
    @AuraEnabled
    public static String submitApprovalRequest(Id campaignId, String comments) {
        
         //There is one public group approvers for every site, which is stored in EBH_CampaignRequestApprovers
         Campaign cRecord = Database.query(EBH_ConstantsUtility.CAMPAIGN_RECORDQUERY);
         
         //Get the Campaign Request Site Group settings and get the public group name
         String groupName = EBH_CampaignRequestSiteGroup__c.getAll().get(cRecord.EBH_Site__c).EBH_PublicGroup__c;
         List<Group> objGroup = Database.query(EBH_ConstantsUtility.SITE_GROUPQUERY);
         
         if(!objGroup.isEmpty()) {
            try {
                //submitting the approval process
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments(comments);
                req1.setObjectId(campaignId);
                //Set the approver as public group ID
                req1.setNextApproverIds(new Id[] {objGroup[0].Id });
                Approval.ProcessResult result = Approval.process(req1);
            } catch(Exception ex) {
                EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.REQUEST_CLASS, EBH_ConstantsUtility.REQUEST_METHOD);
            }       
        }
        
        return EBH_ConstantsUtility.DCS_BLANK;
    }
    
     @AuraEnabled
    public static String validateApproval(Id cId) {
        
        
        Campaign cRecord = [SELECT status from Campaign where Id = :cId];
       // System.debug('££££'+cRecord);
        //EPH-5614 - To display submission message 
        if(cRecord.Status.equalsIgnoreCase(EBH_ConstantsUtility.SUBMITTED_STATUS )){
             
             return Label.EBH_SubmittedCampaignApprovalError  ;
         }
        
         return EBH_ConstantsUtility.DCS_BLANK;
         
    }
}