/**#12768
  - 17/10/2017 - vadhanak.voun@gaea-sys.com
  Task:
  Create a scheduled job that executes the same functionality (budget calculation/deal slot assignment) as the deals trigger.
  Scope: all deals where systemmodstamp > today - 4 weeks (so all deals modified in the last 4 weeks); this will be approx. 2,000 deals
  @ Change history: 13.09.2022 / Sarom Chetra / US-0012444 - Fix failing test class EBH_CalculateDealsTest
*/
global without sharing class EBH_CalculateDeals implements Database.Batchable<SObject> ,Schedulable,Database.Stateful{
    
   String query = 'Select Id,RecordTypeId,EBH_UID__c,EBH_Status__c,EBH_DealStartDate__c,EBH_DealPrice__c,EBH_Quantity__c,EBH_Vertical__c,EBH_SubsidyFinal__c,EBH_SubsidyForecast__c,EBH_SubsidyMax__c, EBH_StartDateMonthYear__c  From EBH_Deal__c '; // 13.09.2022 / Sarom Chetra / US-0012444 - Fix failing test class EBH_CalculateDealsTest
    
   Map<String,Double> monthYearDealsStorage = new Map<String,Double>();
   
   public EBH_CalculateDeals(){}
    
   global Database.QueryLocator start(Database.BatchableContext BC)
   {
       String sWhere = ' WHERE SystemModStamp > LAST_N_WEEKS:4 AND EBH_Vertical__c<>null AND EBH_DealStartDate__c<>null';
       sWhere = Test.isRunningTest()?sWhere.replace('> LAST_N_WEEKS:4','=TODAY'):sWhere; // for unit test
        return Database.getQueryLocator(query+sWhere);
   }
   
   global void execute(Database.BatchableContext BC, List<EBH_Deal__c> scope)
   {
       Set<String> setMonthYear = new Set<String>();
    Set<String> setVertical = new Set<String>();
    
       for(EBH_Deal__c deal : scope)
       {
      setMonthYear.add(deal.EBH_DealStartDate__c.month()+''+deal.EBH_DealStartDate__c.year());
      setVertical.add(deal.EBH_Vertical__c);
       }
    //query the relavant DBM  
       Map<String,EBH_DealsBudgetMonth__c> mapDBM = new Map<String,EBH_DealsBudgetMonth__c>();
    for(EBH_DealsBudgetMonth__c dbm:[Select Id,EBH_MonthYear__c,EBH_DealsBudget__r.EBH_Vertical__c From EBH_DealsBudgetMonth__c WHERE EBH_MonthYear__c IN:setMonthYear AND EBH_DealsBudget__r.EBH_Vertical__c IN:setVertical])
    {
      mapDBM.put(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c,dbm);
    }
    
    //calculate deals here:  
       EBH_DealTriggerHandler.doCalculateDeals(mapDBM,scope,false);  
       
       //there could be matched Deals in the next scope
       //monthYearDealsStorage stores the previous value for complete sum 
       //System.debug('>>>>monthYearDealsStorage:'+monthYearDealsStorage);
       for(EBH_DealsBudgetMonth__c dbm: mapDBM.values())
    {
      //System.debug('>>>>dbm:'+dbm);
      dbm.EBH_SubsidyPaid__c   = monthYearDealsStorage.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_FINAL)    !=null ? monthYearDealsStorage.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_FINAL)    +(dbm.EBH_SubsidyPaid__c == null?0:dbm.EBH_SubsidyPaid__c)     : dbm.EBH_SubsidyPaid__c;
      dbm.EBH_SubsidyInvoiced__c = monthYearDealsStorage.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_INVOICED) !=null ? monthYearDealsStorage.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_INVOICED) +(dbm.EBH_SubsidyInvoiced__c==null?0:dbm.EBH_SubsidyInvoiced__c) : dbm.EBH_SubsidyInvoiced__c;
      //TH: EPH-7468 change to new formula On EBH_DealTriggerHandler.sumDealForDealBudgetMonth
      //dbm.EBH_SubsidyForecast__c = monthYearDealsStorage.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_FORECAST) !=null ? monthYearDealsStorage.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_FORECAST) +(dbm.EBH_SubsidyForecast__c==null?0:dbm.EBH_SubsidyForecast__c) : dbm.EBH_SubsidyForecast__c;
      dbm.EBH_SubsidyMax__c    = monthYearDealsStorage.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_MAX)    !=null ? monthYearDealsStorage.get(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_MAX)      +(dbm.EBH_SubsidyMax__c==null?0:dbm.EBH_SubsidyMax__c)       : dbm.EBH_SubsidyMax__c ;
    } 
     
     //store value in case matched deals remain in the next scope 
       for(EBH_DealsBudgetMonth__c dbm: mapDBM.values())
    {
      monthYearDealsStorage.put(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_FINAL,dbm.EBH_SubsidyPaid__c);
      monthYearDealsStorage.put(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_INVOICED,dbm.EBH_SubsidyInvoiced__c);
      //TH: EPH-7468 change to new formula On EBH_DealTriggerHandler.sumDealForDealBudgetMonth
      //monthYearDealsStorage.put(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_FORECAST,dbm.EBH_SubsidyForecast__c);
      monthYearDealsStorage.put(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c+''+EBH_DealTriggerHandler.KEY_STATUS_MAX,dbm.EBH_SubsidyMax__c);
      
    }
    
    update mapDBM.values();
    
    //Handle AdSlot Allocation logic
    List<EBH_Deal__c> listOldDealsToCompare = scope.deepClone(true,true,true); //deals before processing
    List<EBH_Deal__c> listDealsToUpdate = new List<EBH_Deal__c>();
    EBH_DealTriggerHandler.handleDealSlotAllocation(false,null,scope);
    Integer i=0;
    //check if deal has been modified after: handleDealSlotAllocation()
    //because handleDealSlotAllocation() originaly run in before trigger without dml
    //EBH_Deal__c also has trigger; so filter here only modified Deals need to dml
    for(EBH_Deal__c deal : scope)
    {
      if(deal != listOldDealsToCompare[i])
      {
        listDealsToUpdate.add(deal);
      }
      i++;
    }
    if(!listDealsToUpdate.isEmpty())
    {
      update listDealsToUpdate;
    }
   }
   
   global void finish(Database.BatchableContext BC)
   {
     //TODO?
   }
   
   //to allow scheduler
   global void execute(SchedulableContext sc) {
       EBH_CalculateDeals bc = new EBH_CalculateDeals();
        Database.executebatch(bc); 
   }
   
}