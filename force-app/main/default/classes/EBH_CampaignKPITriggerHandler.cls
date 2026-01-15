/*****************************************************************************************************************************************
@ Class:          EBH_CampaignKPITriggerHandler
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Handler Class for KPIResult Trigger
                  EPH-31 : Campaign Review and Measurement
------------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.05.2017 / NEHA LUND/ Created the class.
*****************************************************************************************************************************************/

public with sharing class EBH_CampaignKPITriggerHandler {
    
    /*************************************************************************************************************************************
    @ Method:         createChildKPIRecords
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        EPH-2149: creates the campaign KPI child records - it is a record roll down from parent campaign to child campaign
                      when campaign is created, then all the campaign KPI records are being moved from parent to child campaign
                      when Campaign KPI is created then it is moved to all the child campaigns.
    --------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      kpiRecords:      EBH_CampaignKPI__c from the trigger scope
    --------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / NEHA LUND/ Created the  Method.
    *************************************************************************************************************************************/
    public static void createChildKPIRecords(List<EBH_CampaignKPI__c> kpiRecords) {
       
        Map<Id, List<EBH_CampaignKPI__c>> parents = new Map<Id, List<EBH_CampaignKPI__c>>();
        List<EBH_CampaignKPI__c> ckpiRecords = new List<EBH_CampaignKPI__c>();
        Set<ID> kpiIds;
        
        //create the map of Parent Campaign and list of Campaign KPI Records
        for (EBH_CampaignKPI__c kpi: kpiRecords) {            
            ckpiRecords = new List<EBH_CampaignKPI__c>();
            
            if( parents.containsKey(kpi.EBH_Campaign__c)) {
                ckpiRecords = parents.get( kpi.EBH_Campaign__c);
            }
            
            ckpiRecords.add(kpi);
            parents.put( kpi.EBH_Campaign__c, ckpiRecords );
        }
        
        ckpiRecords = new List<EBH_CampaignKPI__c>();
        EBH_CampaignKPI__c cloneRecord = new EBH_CampaignKPI__c();
        kpiIds = parents.keyset();
        
        //Get the child campaigns, so that campaign KPI record is moved to all the child level hierarchies
        for(Campaign c: Database.query(EBH_constantsUtility.KPI_QUERY)){
            
            //parse through Campaign KPIs and clone the new ones
            for (EBH_CampaignKPI__c kpi: parents.get(c.Parentid)){
                cloneRecord = kpi.clone(false, false, false, false);
                cloneRecord.EBH_Campaign__c = c.id;
                ckpiRecords.add( cloneRecord );
            }            
        }
        
        //insert the cloned Capaign KPI for all the child levels
        try{
            if(!ckpiRecords.isEmpty()){ Database.insert(ckpiRecords); } } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.CKTH_CLASS, EBH_ConstantsUtility.CKTH_METHOD); }            
    }
    
    /************************************************************************************************************************************
    @ Method:         hasRollupChanged
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Check and returns true if any of the following fields has changed in KPIResult passed in param:
                        - GMV
                        - Revenue 
                        - Sold Items
                        - Legal Entity
                        - Parent
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      acc:             KPIResult to check field(s) change for
                      KPIResultOldMap: KPIResult old map from trigger scope to compare
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2017 / NEHA LUND/ Created the  Method.
    *************************************************************************************************************************************/
    public static Boolean hasRollupChanged(EBH_CampaignKPI__c acc, Map<Id, EBH_CampaignKPI__c> KPIResultOldMap) {        
        
        EBH_CampaignKPI__c oldAcc = KPIResultOldMap != null ? KPIResultOldMap.get(acc.Id) : acc;
        return acc.EBH_Actual__c != oldAcc.EBH_Actual__c || acc.EBH_Campaign__c != oldAcc.EBH_Campaign__c || 
               (KPIResultOldMap == null && acc.EBH_Actual__c != null); 
    } 
}