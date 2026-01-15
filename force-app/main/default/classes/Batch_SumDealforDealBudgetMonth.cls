/*********************************************************************************************************************************
@ Class:         Batch_SumDealforDealBudget
@ Version:       1.0
@ Author:        Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       EPH-7599 Deal Month Object for Invoice Redesign
                 Subsidy Planned = Sum of Subsidy Planned from related deals records
                 Subsidy Running = Sum of Subsidy Running from related deals records
                 Subsidy Forecast = Sum of Subsidy Forecast from related deals records
                 Subsidy Final = Sum of Subsidy Final from related deals records
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 28.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
 global without sharing class Batch_SumDealforDealBudgetMonth implements Database.Batchable<SObject>, Schedulable{
    String soql = 'Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Final__c, e.EBH_SubsidyForecast__c, e.EBH_MonthYear__c, e.EBH_DealsBudget__r.EBH_Vertical__c, e.EBH_DealsBudget__c From EBH_DealsBudgetMonth__c e where EBH_MonthYear__c<>null';
    /*****************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        QueryLocator start method
    ------------------------------------------------_------------------------------------------------------------------------------
    @ Change history: 28.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
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
    @ Change history: 28.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/
     global void execute(Database.BatchableContext pBc, List<EBH_DealsBudgetMonth__c> scope){
    	/*Set<String> setDealBudget = new Set<String>();
    	Map<String,EBH_DealsBudgetMonth__c> mapDealBudgetMonth = new Map<String,EBH_DealsBudgetMonth__c>();
    	for(EBH_DealsBudgetMonth__c dealBudgetMonth : scope){
    		setDealBudget.add(dealBudgetMonth.EBH_DealsBudget__c);
    		dealBudgetMonth.Subsidy_Running__c = 0;
    		dealBudgetMonth.Subsidy_Planned__c = 0;
    		dealBudgetMonth.Subsidy_Final__c = 0;
    		dealBudgetMonth.EBH_SubsidyForecast__c = 0;
    		mapDealBudgetMonth.put(dealBudgetMonth.EBH_DealsBudget__c+''+dealBudgetMonth.EBH_MonthYear__c,dealBudgetMonth);
    	}
    	
    	String whereString = ' where Deals_Budget__c IN: setDealBudget and EBH_StartDateMonthYear__c <> null';
    	for(EBH_Deal__c deal:Database.query(EBH_ConstantsUtility.SOQL_DEAL + whereString))
    	{
    		if(!mapDealBudgetMonth.containsKey(deal.Deals_Budget__c+''+deal.EBH_StartDateMonthYear__c)) continue;
    		EBH_DealsBudgetMonth__c dealBudgetMonth = mapDealBudgetMonth.get(deal.Deals_Budget__c+''+deal.EBH_StartDateMonthYear__c);
    		dealBudgetMonth.Subsidy_Running__c += deal.Subsidy_Running__c == null ? 0 : deal.Subsidy_Running__c;
    		dealBudgetMonth.EBH_SubsidyForecast__c += deal.EBH_SubsidyForecast__c == null ? 0 : deal.EBH_SubsidyForecast__c;
    		dealBudgetMonth.Subsidy_Final__c += deal.EBH_SubsidyFinal__c == null ? 0 : deal.EBH_SubsidyFinal__c;
    		dealBudgetMonth.Subsidy_Planned__c += deal.EBH_SubsidyMax__c == null ? 0 : deal.EBH_SubsidyMax__c;
    	}
    	if(!mapDealBudgetMonth.isEmpty()) update mapDealBudgetMonth.values();*/
    } 
    
    /*****************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        QueryLocator finish method, it calls the insert batch
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/ 
     global void finish(Database.BatchableContext pBc){
        
    } 
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        Allow this batch to be schedulable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the method.
    *****************************************************************************************************************************/ 
      global void execute(SchedulableContext sc) { 
        Batch_SumDealforDealBudgetMonth b = new Batch_SumDealforDealBudgetMonth();
        Database.executeBatch(b);
    }

    
}