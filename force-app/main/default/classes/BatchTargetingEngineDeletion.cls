/*********************************************************************************************************************************
@ Class:         BatchTargetingEngineDeletion
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       EPH-6898 Target Engine - Deletion of redundant targetlists
@				AC2) Create weekly batch job in HIVE that will delete a targetlists that matches following criteria EBH_TE_Expiration_Date__c < CURRENT_DATE
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.01.2019 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the class.
@               : 17.03.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011770 - Fix BatchTargetingEngineDeletion
*********************************************************************************************************************************/
global without sharing class BatchTargetingEngineDeletion implements Database.Batchable<SObject>,Schedulable{
    
    // String soql_where = ' WHERE EBH_TE_Expiration_Date__c < TODAY';

    private Integer objIndex = 0; //for which obj to be deleted

    private final List<String> LIST_SQOL_SOBJECT = new List<String>
    {
        'SELECT id FROM EBH_TargetedSeller__c WHERE EBH_SellerList__r.EBH_TE_Expiration_Date__c < TODAY',
        'SELECT id FROM EBH_Filter__c WHERE EBH_TE_Expiration_Date__c < TODAY'
    };

    public BatchTargetingEngineDeletion()
    {
    	
    }

    /*************************************************************************************************************************************
    @ Constructor:          BatchTargetingEngineDeletion 
    @ Version:              1.0
    @ Author:               Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:              17.03.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011770 - Fix BatchTargetingEngineDeletion
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:       17.03.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011770 create Constructor
    *****************************************************************************************************************************/
    public BatchTargetingEngineDeletion(Integer objIndex)
    {
    	this.objIndex = objIndex;
    }
    
    global Database.querylocator start(Database.BatchableContext bc)
    {
        // return Database.getQueryLocator(EBH_ConstantsUtility.SOQL_TARGETING_ENGINE+soql_where);
        return Database.getQueryLocator(LIST_SQOL_SOBJECT[objIndex]);  // 17.03.2023 / Sophal Noch / US-0011770 : what SObject to query is depend on index 
    }   
    
    global void execute(Database.BatchableContext bc,List<SObject> scope)
    {
       try 
       {
             delete scope;
             
		}catch(Exception ex) {
			system.debug(ex);EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchTargetingEngineDeletion', 'execute');
		} 
    }
    
    global void finish(Database.BatchableContext bc)
    {
        // 17.03.2023 / Sophal Noch / US-0011770 : go to next object index to delete parent record with batch
        Integer nextObjIndexToDelete = objIndex + 1;
        if(nextObjIndexToDelete < LIST_SQOL_SOBJECT.size()){ 
            BatchTargetingEngineDeletion bTEDelete = new BatchTargetingEngineDeletion(nextObjIndexToDelete);
            Database.executeBatch(bTEDelete);
        }
    }
    
    //for scheduler
    global void execute(SchedulableContext ctx){
    	BatchTargetingEngineDeletion bTEDelete = new BatchTargetingEngineDeletion();
    	Database.executeBatch(bTEDelete);
    }
    
}