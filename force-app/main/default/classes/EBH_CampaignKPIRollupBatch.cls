/*********************************************************************************************************************************
@ Class:          EBH_CampaignKPIRollupBatch
@ Version:        1.0
@ Author:         NEHA LUND (nalund@deloitte.co.uk)
@ Purpose:        Batch class to delete targeted seller
                  epic: Targeting Engine Filters
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.07.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the class.
@				: 13.06.2025 / Sophal Noch / US-0012504 - 2. Deletion of custom objects
*********************************************************************************************************************************/

global with sharing class EBH_CampaignKPIRollupBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    global final EBH_Filter__c Filter {get;set;}
 
   Set<Id> parentIds = new Set<Id>();    //distinct parent ids of the KPIResults in trigger scope
        Set<ID> pIDs = new Set<ID>();
        String type ='';
        EBH_CampaignKPI__c cloneCampaignKPI;
        List<EBH_CampaignKPI__c> results = new List<EBH_CampaignKPI__c>();
        List< EBH_CampaignKPI__c> parents;                //list of distinct parents from parentIds
        List<EBH_CampaignKPI__c> parentKPIRecords = new List<EBH_CampaignKPI__c>();
        List<EBH_CampaignKPI__c> updateparentKPIRecords = new List<EBH_CampaignKPI__c>();
        Map<String, EBH_CampaignKPI__c> existingCampaignKPIs = new Map<String, EBH_CampaignKPI__c>();
        Map<String, List<EBH_CampaignKPI__c>> parentCampaignKPIMap = new Map<String, List<EBH_CampaignKPI__c>>();
    /*****************************************************************************************************************************
    @ Constructor:    EBH_CampaignKPIRollupBatch
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Initialises the class for controller instance.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Seller List record, LocalAccQuery
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the constructor.
    *****************************************************************************************************************************/
    global EBH_CampaignKPIRollupBatch(){
       // Filter = Filt;

    }
    
    /*****************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        QueryLocator start method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    ****************************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //return Database.getQueryLocator(targetedSellerQuery);
        return Database.getQueryLocator('SELECT id, EBH_Campaign__c from EBH_CampaignKPI__c where EBH_UpdateCampaignActualHierarchy__c = true' );
    }
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        QueryLocator execute method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    @               : 13.06.2025 / Sophal Noch / US-0012504 - 2. Deletion of custom objects
    *****************************************************************************************************************************/
    global void execute(Database.BatchableContext pBc, List<SObject> scope){
        try {
        
        EBH_ActiveTriggers__c aTrigger = EBH_ActiveTriggers__c.getInstance(EBH_ConstantsUtility.TRIGGERCONTROLLER);
        aTrigger.EBH_CampaignKPITrigger__c = false;
        update aTrigger;
        
        for( EBH_CampaignKPI__c ckpi : (List<EBH_CampaignKPI__c>)scope){
            ckpi.EBH_UpdateCampaignActualHierarchy__c = false;
            parentIds.add(ckpi.EBH_Campaign__c);
            
        }
        if( !scope.isEmpty())
        update scope;
     
        
          //Get the parent campaigns of the Campaigns associated with Campaigns of KPI Results
        for( Campaign cmp : [SELECT ParentId from Campaign where ID IN :parentIds]){
            pIds.add(cmp.ParentId);
        }
        
        //Get all the child campaigns of the Campaigns so that child calcualtions roll up to parent correctly
        for( Campaign cmp : [SELECT id from Campaign where parentID IN :pIDs]){
            parentIDs.add(cmp.id);
        }
        
        
            
                                                       
            for(EBH_CampaignKPI__c existingResultRecord : [SELECT EBH_KPI__c, Id, EBH_Actual__c, 
                                                       EBH_KPI__r.EBH_Type__c ,
                                                       EBH_Campaign__c from EBH_CampaignKPI__c where 
                                                       EBH_Campaign__c IN :pIDs]){
                                                           
            existingCampaignKPIs.put( existingResultRecord.EBH_Campaign__c+ EBH_ConstantsUtility.HYPHEN_KEY+
                                   existingResultRecord.EBH_KPI__r.EBH_Type__c , existingResultRecord);
        }
        
        //fetch the parents and the childs and sellers from parentIds
        for( EBH_CampaignKPI__c kpi :Database.query(EBH_ConstantsUtility.CKTH_PARENTCHILDQUERY)){
            results = parentCampaignKPIMap.containsKey(kpi.EBH_Campaign__r.ParentID + EBH_ConstantsUtility.HYPHEN_KEY+
                           kpi.EBH_KPI__r.EBH_Type__c) ? parentCampaignKPIMap.get(kpi.EBH_Campaign__r.ParentID+ 
                            EBH_ConstantsUtility.HYPHEN_KEY + kpi.EBH_KPI__r.EBH_Type__c) : new List<EBH_CampaignKPI__c>();
            results.add(kpi);   
            if( kpi.EBH_Campaign__r.ParentID != null){       
                parentCampaignKPIMap.put(kpi.EBH_Campaign__r.ParentID + EBH_ConstantsUtility.HYPHEN_KEY+
                                         kpi.EBH_KPI__r.EBH_Type__c, results);
            }
        }        
        
        //fetch the childs and sellers of parents from parentIds and populate parentChildMap
        for(String uniqueKey : parentCampaignKPIMap.keyset()) {
            cloneCampaignKPI = new EBH_CampaignKPI__c();
            type = uniqueKey.split(EBH_ConstantsUtility.HYPHEN_KEY)[1];
            //reset the roll ups
            cloneCampaignKPI.EBH_Actual__c = 0;
            cloneCampaignKPI.EBH_Campaign__c = uniqueKey.split(EBH_ConstantsUtility.HYPHEN_KEY)[0];
            if( existingCampaignKPIs.containsKey( uniqueKey)){
                cloneCampaignKPI.Id = existingCampaignKPIs.get(uniqueKey).id;
            }
            cloneCampaignKPI.EBH_UpdateCampaignActualHierarchy__c = true;
            for(EBH_CampaignKPI__c kpResult: parentCampaignKPIMap.get(uniqueKey)){
                type = kpResult.EBH_KPI__r.EBH_Type__c != null ? kpResult.EBH_KPI__r.EBH_Type__c : '';
                if(type.equalsIgnoreCase(EBH_ConstantsUtility.TYPE_SUM) || 
                    type.equalsIgnoreCase(EBH_ConstantsUtility.TYPE_COUNT) ||
                    type.equalsIgnoreCase(EBH_ConstantsUtility.TYPE_AVERAGE) ){
                
                    cloneCampaignKPI.EBH_Actual__c += kpResult.EBH_Actual__c!= null ?
                                                  kpResult.EBH_Actual__c:0;
                }
                else if(type.equalsIgnoreCase(EBH_ConstantsUtility.TYPE_MAXIMUM) && 
                    cloneCampaignKPI.EBH_Actual__c == 0 ){
                    cloneCampaignKPI.EBH_Actual__c += kpResult.EBH_Actual__c!= null ? 
                                                      kpResult.EBH_Actual__c:0;
                }
                else if(type.equalsIgnoreCase(EBH_ConstantsUtility.TYPE_MINIMUM) ){
                    cloneCampaignKPI.EBH_Actual__c = kpResult.EBH_Actual__c!= null ? 
                                                     kpResult.EBH_Actual__c:0;
                }
                if(String.isBlank( cloneCampaignKPI.Id)){
                    cloneCampaignKPI.EBH_KPI__c = kpResult.EBH_KPI__c;
                }
            }
            
            if( String.isBlank( cloneCampaignKPI.Id)){
                parentKPIRecords.add(cloneCampaignKPI);
            }
            
            else{
                updateparentKPIRecords.add(cloneCampaignKPI);
            }
        } 
        //update parents
        try {
            if(!parentKPIRecords.isEmpty()){
                Database.insert(parentKPIRecords);
            }
            if(!updateparentKPIRecords.isEmpty()){
                Database.update(updateparentKPIRecords);
            }
        } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.CKTH_CLASS, EBH_ConstantsUtility.CKTH_METHOD); }
        } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.TCC_CLS, EBH_ConstantsUtility.TCC_METHODRF); } //log error on exception to apex logger object
    }
    
    /*****************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        QueryLocator finish method, it calls the insert batch
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.07.2017 / NEHA LUND (nalund@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global void finish(Database.BatchableContext pBc){
       // EBH_InsertTargetSellersBatch tSBatch = new EBH_InsertTargetSellersBatch (Filter, LocalAccountQuery);
        EBH_ActiveTriggers__c aTrigger = EBH_ActiveTriggers__c.getInstance(EBH_ConstantsUtility.TRIGGERCONTROLLER);
        aTrigger.EBH_CampaignKPITrigger__c = true;
        update aTrigger;
        
        if( Database.Query('SELECT id, EBH_Campaign__c from EBH_CampaignKPI__c where EBH_UpdateCampaignActualHierarchy__c = true' ).size() > 0)
        Database.executeBatch(new EBH_CampaignKPIRollupBatch(),200);
        
    }
    
    global void execute(SchedulableContext sc) { 
        EBH_CampaignKPIRollupBatch b = new EBH_CampaignKPIRollupBatch();
        Database.executeBatch(b);
    }
}