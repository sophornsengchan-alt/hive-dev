/*********************************************************************************************************************************
@ Class:         Batch_SumDealforDealBudget
@ Version:       1.0
@ Author:        Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       EPH-7467 Deal Budget -Object - Redesign
                 Subsidy Planned = Sum of Subsidy Planned from related deals records
                 Subsidy Running = Sum of Subsidy Running from related deals records
                 Subsidy Forecast = Sum of Subsidy Forecast from related deals records
                 Subsidy Final = Sum of Subsidy Final from related deals records
                 Subsidy Spent = =subsidy planned+subsidy running+subsidy forecast+subsidy final
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/

global without sharing class Batch_SumDealforDealBudget implements Database.Batchable<SObject>, Schedulable{
	String soql = 'Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Forecast__c, e.Subsidy_Final__c From EBH_DealsBudget__c e';
    
	/*****************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        QueryLocator start method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
    ****************************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(soql);
    }
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        QueryLocator execute method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/
    global void execute(Database.BatchableContext pBc, List<SObject> scope){
    	/*Map<Id,EBH_DealsBudget__c> mapDealBudget = new Map<Id,EBH_DealsBudget__c>();
    	String whereString = ' where Deals_Budget__c IN: scope';
    	for(EBH_Deal__c deal : Database.query(EBH_ConstantsUtility.SOQL_DEAL + whereString)){
    		EBH_DealsBudget__c dealBudget = new EBH_DealsBudget__c(id = deal.Deals_Budget__c, Subsidy_Running__c = 0, Subsidy_Forecast__c = 0, Subsidy_Final__c = 0, Subsidy_Planned__c=0);
    		if(mapDealBudget.containsKey(deal.Deals_Budget__c)) dealBudget = mapDealBudget.get(deal.Deals_Budget__c);
    		dealBudget.Subsidy_Running__c += deal.Subsidy_Running__c == null ? 0 : deal.Subsidy_Running__c;
    		dealBudget.Subsidy_Forecast__c += deal.EBH_SubsidyForecast__c == null ? 0 : deal.EBH_SubsidyForecast__c;
    		dealBudget.Subsidy_Final__c += deal.EBH_SubsidyFinal__c == null ? 0 : deal.EBH_SubsidyFinal__c;
    		dealBudget.Subsidy_Planned__c += deal.EBH_SubsidyMax__c == null ? 0 : deal.EBH_SubsidyMax__c;
    		mapDealBudget.put(deal.Deals_Budget__c,dealBudget);
    	}
    	if(!mapDealBudget.isEmpty()) update mapDealBudget.values();*/
    } 
    
    /*****************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        QueryLocator finish method, it calls the insert batch
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/ 
    global void finish(Database.BatchableContext pBc){
        
    }
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        Allow this batch to be schedulable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/ 
     global void execute(SchedulableContext sc) { 
        Batch_SumDealforDealBudget b = new Batch_SumDealforDealBudget();
        Database.executeBatch(b);
    }   
}