/*********************************************************************************************************************************
@ Class:          EBH_DeleteCampaignMemberBatch
@ Version:        1.0
@ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
@ Purpose:        Batch class to delete Campaign Member
                  EPH-106 : Campaign Member deletion
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the class.
*********************************************************************************************************************************/

global with sharing class EBH_DeleteCampaignMemberBatch implements Database.Batchable<SObject>, Database.Stateful{
    
    //list of CampaignMember to delete

    // Acmatac SEING, 17/03/2022 US-0011204 - TECHDEBT: SOQL SOSL Injection - Prio 1
    // global final String campaignMemberListToDelete = EBH_ConstantsUtility.CTH_CAMPAIGNMEMBERTODELETERQUERY;
    global static final String campaignMemberListToDelete = 'SELECT Id FROM CampaignMember WHERE CampaignId in : campaignIds ';  

    //map of seller list id and list of targeted seller 
    global final Map<Id,List<EBH_TargetedSeller__c>> sellerListTargetedSellerMap;
    //campaign map to store the campaign id 
    global final Map<Id, Campaign> sellerIdCampaignMap;
    //set to store account ids
    global final Set<Id> accountIds;
    //set to store campaign ids
    global final Set<Id> campaignIds;
    
    /*****************************************************************************************************************************
    @ Constructor:    EBH_DeleteTargetSellersBatch
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        Initialises the class for controller instance.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accounts, campaigns, sellerListTargetedSellers, sellerIdCampaigns
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the constructor.
    *****************************************************************************************************************************/
    global EBH_DeleteCampaignMemberBatch(Set<Id> accounts, Set<Id> campaigns, 
                                    Map<Id,List<EBH_TargetedSeller__c>> sellerListTargetedSellers, 
                                    Map<Id, Campaign> sellerIdCampaigns){
        accountIds = accounts;
        campaignIds = campaigns;
        sellerListTargetedSellerMap = sellerListTargetedSellers;
        sellerIdCampaignMap = sellerIdCampaigns;
    }
    
    /*****************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator start method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //run the query and pass the records to excute method in 200 scope
        return Database.getQueryLocator(campaignMemberListToDelete);
        
    }
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator execute method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global void execute(Database.BatchableContext pBc, List<SObject> scope){
       
        EBH_DataOrigin__c dOrigin = EBH_DataOrigin__c.getOrgDefaults();
        dOrigin.EBH_CampaignDeleteValidation__c = true;
        update dOrigin;
        
        try {
            //deleting the existing campaign members
            Database.delete(scope);
        } catch(Exception ex) {
            //log error on exception to apex logger object
            EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                    EBH_ConstantsUtility.DCMBATCH_CLASS, EBH_ConstantsUtility.DCMBATCH_EMETHOD);
        } 
        
        dOrigin.EBH_CampaignDeleteValidation__c = false;
        update dOrigin;
    }
    
    /*****************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator finish method, it calls the insert batch
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global void finish(Database.BatchableContext pBc){
        //call EBH_InsertCampaignMemberBatch batch class
        EBH_InsertCampaignMemberBatch CMBatch 
            = new EBH_InsertCampaignMemberBatch(accountIds, campaignIds, sellerListTargetedSellerMap, sellerIdCampaignMap);
        //scope 200
        Database.executeBatch(CMBatch,200);
    }
}