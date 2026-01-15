/************************************************************************************************************************************
@ Class:          Batch_DeleteTargettedSeller
@ Version:        1.0
@ Author:         Ratha SIM (ratha.sim@gaea-sys.com)
@ Purpose:        US-0008047 separated batch job from finish of Batch_TargetingEngineReminder. to avoid cascade delete of Seller List
--------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.08.2020 / Ratha SIM / Created the class.
**************************************************************************************************************************************/
global class Batch_DeleteTargettedSeller implements Database.Batchable<sObject> {

    //all related MD child objects. need to delete them first before delte parent (avoid Casecade delete exceeding)
    private final List<String> listSQOL_SOBJECT = new List<String>
    {
        'SELECT id FROM EBH_TargetedSeller__c WHERE EBH_SellerList__c IN: teIds',
        //'SELECT id FROM Targetted_Listing__c WHERE Trading_Engine__c IN: teIds',
        'SELECT id FROM Targetted_Product__c WHERE Trading_Engine__c IN: teIds',
        'SELECT id FROM EBH_Filter__c WHERE ID IN: teIds'
    };
    private Integer objIndex = 0; //for which obj to be deleted

    public final static String STR_TE_SELECTQUERY = 'SELECT id FROM EBH_TargetedSeller__c ';
    private final static String STR_TE_WHEREQUERY = 'WHERE EBH_SellerList__c IN: teIds';
    private Set<Id> teIds = new Set<Id>();

    /*************************************************************************************************************************************
    @ Method:         constructor
    @ Change history: 31.08.2020 / Ratha SIM / Created the method.
                      need past value list unique ID Targeting Engine from class Batch_TargetingEngineReminder
                      when targeting engine EBH_TE_Expiration_Date__c <= TODAY
    ***************************************************************************************************************************************/
    global Batch_DeleteTargettedSeller(Set<Id> teIds,Integer objIndex) {
        this.teIds = teIds;
        this.objIndex = objIndex;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        return Database.getQueryLocator(listSQOL_SOBJECT[objIndex]); 
    }

    /*********************************************************************************************************************************
    @ Method:         execute
    @ Change history: 31.08.2020 / Ratha SIM / Created the method.
                      Delete list targeted Seller by EBH_SellerList__c [Targeting EngineRemin Id]
                      Child of Targeting Engine
    *********************************************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<sObject> targetedSellers) {
        //Database.delete(targetedSellers,false);// incase today can not delete, (sfdc bug?) then delete tmr since it is daily job
        Database.DeleteResult[] drList = Database.delete(targetedSellers,false);
        // TH: 04/07/2022: US-0011961 : check Error message
        for(Database.DeleteResult dr : drList) {
            if ( !dr.isSuccess() ) {  
                EBH_ApexLogger.logError(new List<Database.Error> { dr.getErrors()[0]}, 'Batch_DeleteTargettedSeller', 'execute : objIndex='+objIndex);
                break;
            }
        }
    }

    /*********************************************************************************************************************************
    @ Method:         finish
    @ Change history: 31.08.2020 / Ratha SIM / Created the method.
                      Delete Targeting Engine on EBH_TE_Expiration_Date__c <= TODAY
                      Parent of targeted Seller
    *********************************************************************************************************************************/
    global void finish(Database.BatchableContext BC) {
        Integer nextObjectToDelete = objIndex + 1;
        if(nextObjectToDelete <listSQOL_SOBJECT.size())
        {
            Batch_DeleteTargettedSeller b = new Batch_DeleteTargettedSeller(teIds,nextObjectToDelete);
            Database.executeBatch(b);
        } 
        
    }

}