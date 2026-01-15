/*********************************************************************************************************************************
@ Class:          EBH_ContractApprovalHierarchyHandlers
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        EPH-51: Handler Class for Campaign Approval Group Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.09.2017 / NEHA LUND / Created the class.
*********************************************************************************************************************************/

public with sharing class EBH_ContractApprovalMatrixHandler {
    
    
    /*****************************************************************************************************************************
    @ Method:         updateContractApprovers
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        For insert trigger event, add the group members as Campaign Approval group is added
    ------------------------------------------------------------------------------------------------------------
    @ Parameter:      Passed through trigger scope
                      List<EBH_CampaignApprovalGroup__c> campaignApprovals
                      Map<Id,EBH_CampaignApprovalGroup__c> oldMap 
    ------------------------------------------------------------------------------------------------------------
    @ Change history: 23.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
  
    public void updateContractApprovers(List< EBH_ContractApprovalMatrix__c> hierarchy, Map<ID, EBH_ContractApprovalMatrix__c> oldMap){
          
         boolean executeContractUpdateBatch = EBH_ActiveTriggers__c.getInstance(EBH_ConstantsUtility.TRIGGERCONTROLLER).EBH_ExecuteContractUpdateBatch__c;
         boolean invokeBatch = false;
         EBH_ContractApprovalMatrix__c oldCon ;
         for(EBH_ContractApprovalMatrix__c hier : hierarchy){
             
             oldCon = oldMap != null ? oldMap.get(hier.Id) : hier;
             if( (hier.EBH_FinancePrecheckApprover__c != oldCon.EBH_FinancePrecheckApprover__c ||
                  hier.EBH_LegalApprover__c != oldCon.EBH_LegalApprover__c ||
                  hier.EBH_Site__c != oldCon.EBH_Site__c || hier  == oldCon) && 
                  !executeContractUpdateBatch 
                 )
                 {
                     invokeBatch = true;
                     break;
                 }
         }
         
         if( invokeBatch){
              EBH_ActiveTriggers__c tr = EBH_ActiveTriggers__c.getInstance(EBH_ConstantsUtility.TRIGGERCONTROLLER);
              tr.EBH_ExecuteContractUpdateBatch__c = true;
              update tr;
               updateContractApprovers();  
         }
    }
    /*****************************************************************************************************************************
    @ Method:         updateContractApprovers
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        For insert trigger event, add the group members as Campaign Approval group is added
    ------------------------------------------------------------------------------------------------------------
    @ Parameter:      Passed through trigger scope
                      List<EBH_CampaignApprovalGroup__c> campaignApprovals
                      Map<Id,EBH_CampaignApprovalGroup__c> oldMap 
    ------------------------------------------------------------------------------------------------------------
    @ Change history: 23.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
 
    public static void updateContractApprovers(){
        
        if(!System.isFuture())
        Database.executeBatch(new EBH_UpdateContractApproversBatch(), 5000);
          
         
    }
}