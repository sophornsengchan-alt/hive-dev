/*********************************************************************************************************************************
@ Class:          EBH_RandomControlGroupController
@ Version:        1.0
@ Author:         Neha Lund
@ Purpose:        Controller Class for EBH_RandomControlGroup page 
                  EPH-5854 : Move control group to Target List
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.05.2018 / NEHA LUND / Created the class.
*********************************************************************************************************************************/
public with sharing class EBH_RandomControlGroupController {
    
    public boolean campaignExecuted { get; set; }
    public boolean controlGroup { get; set; }
    public Id filterId   { get;set; }
    public boolean noSellers    {set;get;}
    EBH_Filter__c filterRecord;
    Campaign camp;
    
    /*****************************************************************************************************************************
    @ Method:         EBH_RandomControlGroupController
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        initialization of parameters
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      ApexPages.StandardController controller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2018 / NEHA LUND  / Created the  Method.
    *****************************************************************************************************************************/
    public EBH_RandomControlGroupController(ApexPages.StandardController controller) {
        
      
        filterId = controller.getId();
        
        filterRecord = Database.query(EBH_ConstantsUtility.RCG_FilTERQUERY );
        noSellers  = false;
        
        if( Database.query(EBH_ConstantsUtility.RCG_TARGETEDSELLERQUERYLIMIT ).isEmpty()){
            noSellers = true;
        }
        //query campaign details and based on the status the member refresh functionality will be invoked
        List<Campaign> campaigns = Database.query(EBH_ConstantsUtility.RCG_QUERY);
        if ( !campaigns.isEmpty()){
            camp = campaigns[0];
        }
        campaignExecuted = false;
        
        if( camp != null ){
            campaignExecuted = (camp.Status == EBH_ConstantsUtility.CMRC_EXECUTION || 
                               camp.Status == EBH_ConstantsUtility.CMRC_CANCELLED ||
                               camp.Status == EBH_ConstantsUtility.CMRC_COMPLETED ) ;
        
        }
        
        controlGroup = filterRecord.EBH_ActualControlGroupSize__c > 0;
        
        
    }
    /*****************************************************************************************************************************
    @ Method:         refreshRandomGroup
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        refresh random control group on targeted sellers
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      no parameter
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2018 / NEHA LUND  / Created the  Method.
    *****************************************************************************************************************************/
    public PageReference refreshRandomGroup() {
        //IF campaign status is not executed or cancelled and if seller list is added to the campaign
        if(!CampaignExecuted && controlGroup && !noSellers) {
        
        if( filterRecord.EBH_ActualControlGroupSize__c != null ){     
            filterRecord.EBH_GeneratedControlGroupSize__c= filterRecord.EBH_ActualControlGroupSize__c;
            update filterRecord;
        }
              
        EBH_ControlGroupTargetedSellersBatch DCMBatch 
            = new EBH_ControlGroupTargetedSellersBatch(filterId, filterRecord.EBH_ActualControlGroupSize__c );
        Database.executeBatch(DCMBatch,5000);
            return new PageReference('/' + filterRecord.Id);
        }
        return null;
    }
}