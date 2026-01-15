/************************************************************************************************************************************************
@ Class:          EBH_CancelCampaignController
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Controller for Lightning component - Campaign request submit for approval
                  EPH-3780 : Cancelling Campaigns for AM outreach phone
-------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.10.2017 / NEHA LUND / Created the class.
************************************************************************************************************************************************/
public with sharing class EBH_CancelCampaignController {
  
    /********************************************************************************************************************************************
    @ Method:         submitApprovalRequest
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        receives the Campaign record & comments
    ---------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Pssed through the action i.e. when Campaign is submitted for an approval
    ---------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.10.2017 / NEHA LUND / Created the  Method.
    ********************************************************************************************************************************************/
    @AuraEnabled
    public static void cancelCampaign(Id campaignId) {
        
        //There is one public group approvers for every site, which is stored in EBH_CampaignRequestApprovers
        Campaign cRecord = Database.query(EBH_ConstantsUtility.CAMPAIGN_RECORDQUERY);
       
        cRecord.Status = EBH_ConstantsUtility.CMRC_CANCELLED;
        if(cRecord != null) {
            Database.update(cRecord);
        }
    }
}