/************************************************************************************************************************************
@ Class:          Batch_DealBudget
@ Version:        1.0
@ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:        US-0009132 - [EU Deals] Deals Budget & Deal Budget Month Batch Process
@                 AC2: Create a batch to
@                 Find all "Deal Budget Month" records eligible for the calculation. Filter criteria would be "Tracking End Date" (from AC1) >= "Current Date"
--------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.04.2021 / Acmatac SEING / Created the class.
                  21.05.2021 / SRONG TIN / US-0009552 - [Bug] Need to sum all the Deal Budget (Month) Subsidy Running field to Deal Budget Subsidy Running. to Deal
                  02/02/2023 / Sovantheany Dim / US-0013020 - Remove negotiating picklist from the Deal V1 record type
**************************************************************************************************************************************/
global class Batch_DealBudget implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
    //private Set<String> dealStatuses = new Set<String>{'New', 'Negotiating', 'Negotiating Amended', 'Rejected'};//TH:US-0013020
    private Set<String> dealStatuses = new Set<String>{'New','Rejected'};
    private Set<Id> dealBudgets= new Set<Id>();
    private Set<Id> dealBudgetMonths= new Set<Id>();
    private Set<Id> dealIds= new Set<Id>();

    private String dealRT = 'Deal_V1';

    private final String SOQL_DEALBUDGET = 'SELECT Id FROM EBH_DealsBudget__c WHERE Id IN: dealBudgets';
    private final String SOQL_DEALBUDGET_MONTH = 'SELECT Id, EBH_DealsBudget__c, EBH_DealsBudget__r.EBH_Vertical__c, EBH_MonthYear__c FROM EBH_DealsBudgetMonth__c WHERE Tracking_End_Date__c >= TODAY';
    
    private final String SOQL_DEALBUDGET_MONTH_SUM = 'SELECT EBH_DealsBudget__c, ' +
                                                        'SUM(Subsidy_Planned__c) Sum_SubsidyPlanned, ' +
                                                        'SUM(Subsidy_Running__c) Sum_SubsidyRunning, ' +//US-0009552
                                                        'SUM(EBH_SubsidyForecast__c) Sum_SubsidyForecast, ' +
                                                        'SUM(Subsidy_Final__c) Sum_SubsidyFinal ' +
                                                    'FROM EBH_DealsBudgetMonth__c WHERE EBH_DealsBudget__c IN: scope AND Id IN: dealBudgetMonths GROUP BY EBH_DealsBudget__c';
    
    private String SOQL_DEAL = 'SELECT EBH_StartDateMonthYear__c, EBH_Vertical__c, ' +
                                            'EBH_SubsidyMax__c, ' +
                                            'Subsidy_Running__c, ' +
                                            'EBH_SubsidyForecast__c, ' +
                                            'Subsidy_Final_Net__c ' +
                                        'FROM EBH_Deal__c WHERE EBH_Status__c NOT IN: dealStatuses AND Unique_Budget_Month__c IN: uniqueKeys';

    private String soqlQuery = '';
    
    // Default
    private String objToRun = 'DBM';

    global Batch_DealBudget(){}

    // Purpose: For QA testing easier with specific deal record.
    global Batch_DealBudget(Set<Id> dealIds){
        this.dealIds = dealIds;
        SOQL_DEAL += ' AND Id IN: dealIds';
    }

    global Batch_DealBudget(String objToRun, Set<Id> dealBudgets, Set<Id> dealBudgetMonths){
        this.objToRun = objToRun;
        this.dealBudgets = dealBudgets;
        this.dealBudgetMonths = dealBudgetMonths;
    } 


    global Database.QueryLocator start(Database.BatchableContext BC){
        soqlQuery = objToRun == 'DBM' ? SOQL_DEALBUDGET_MONTH : SOQL_DEALBUDGET;
        return Database.getQueryLocator(soqlQuery);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        if(objToRun == 'DBM'){
            calc_DBM(scope);
        }
        else if(objToRun == 'DB'){
            calc_DB(scope);
        }
    }

    global void finish(Database.BatchableContext BC){
        if(this.objToRun == 'DBM'){
            Database.executeBatch(new Batch_DealBudget('DB', this.dealBudgets, this.dealBudgetMonths));
        }
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_DealBudget());
    }

    /************************************************************************************************************************************
    @ Method:         calc_DBM
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0009132 - [EU Deals] Deals Budget & Deal Budget Month Batch Process
    @                 Map "Deal" records for each eligible "Deal Budget Month" record based on criteria below and calculate/update summary values:
    @                 Mapping rules for Deals to Deal Budget Month:
    @                 EBH_Deal__c .RecordType.DeveloperName = 'Deal_V1'
    @                 EBH_Deal__c .EBH_Status__c NOT in (New, Negotiating, Negotiating Amended, Rejected)
    @                 EBH_Deal__c .EBH_DealStartDate__c "is in" EBH_DealsBudgetMonth__c.EBH_Month__c
    @                 EBH_Deal__c.EBH_Vertical__c == EBH_DealsBudgetMonth__c. EBH_DealsBudget__c.EBH_Vertical__c
    @
    @                 Summary fields to calculate and update respective "Deal Budget Month" record:
    @                 EBH_DealsBudgetMonth__c.Subsidy_Planned__c = SUM(EBH_Deal__c.EBH_SubsidyMax__c) 
    @                 EBH_DealsBudgetMonth__c.Subsidy_Running__c = SUM(EBH_Deal__c. Subsidy_Running__c) 
    @                 EBH_DealsBudgetMonth__c.EBH_SubsidyForecast__c = SUM(EBH_Deal__c.EBH_SubsidyForecast__c) 
    @                 EBH_DealsBudgetMonth__c.Subsidy_Final__c = SUM(EBH_Deal__c.Subsidy_Final_Net__c) 
    --------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 23.04.2021 / Acmatac SEING / Created the method.
    **************************************************************************************************************************************/
    private void calc_DBM(List<EBH_DealsBudgetMonth__c> scope){
        Map<String, String> mDBM_Deal_Key = new Map<String, String>();
        for(EBH_DealsBudgetMonth__c oDBM : scope){
            // Unique Key for query all Deal.Unique_Budget_Month__c IN this key
            mDBM_Deal_Key.put(dealRT + oDBM.EBH_MonthYear__c + oDBM.EBH_DealsBudget__r.EBH_Vertical__c, oDBM.Id);
            
            // dealBudgets & dealBudgetMonths For next cal_DB batch
            dealBudgets.add(oDBM.EBH_DealsBudget__c);
            dealBudgetMonths.add(oDBM.Id);
        }

        Set<String> uniqueKeys = mDBM_Deal_Key.keySet();
        Map<String, EBH_DealsBudgetMonth__c> mDBM_Deal_Sum = new Map<String, EBH_DealsBudgetMonth__c>();
        for(EBH_Deal__c oDeal : Database.Query(SOQL_DEAL)){
            String dKey = dealRT + oDeal.EBH_StartDateMonthYear__c + oDeal.EBH_Vertical__c;
            if(!mDBM_Deal_Sum.containsKey(dKey)){
                mDBM_Deal_Sum.put(dKey, new EBH_DealsBudgetMonth__c(
                    Id = mDBM_Deal_Key.get(dKey),
                    Subsidy_Planned__c = 0,
                    Subsidy_Running__c = 0,
                    EBH_SubsidyForecast__c = 0,
                    Subsidy_Final__c = 0)
                );
            }

            EBH_DealsBudgetMonth__c dbm = mDBM_Deal_Sum.get(dKey);
            dbm.Subsidy_Planned__c += oDeal.EBH_SubsidyMax__c == null ? 0 : (Decimal) oDeal.EBH_SubsidyMax__c;
            dbm.Subsidy_Running__c += oDeal.Subsidy_Running__c == null ? 0 : (Decimal) oDeal.Subsidy_Running__c;
            dbm.EBH_SubsidyForecast__c += oDeal.EBH_SubsidyForecast__c == null ? 0 : (Decimal) oDeal.EBH_SubsidyForecast__c;
            dbm.Subsidy_Final__c += oDeal.Subsidy_Final_Net__c == null ? 0 : (Decimal) oDeal.Subsidy_Final_Net__c;
        }

        if(!mDBM_Deal_Sum.isEmpty()){
            update mDBM_Deal_Sum.values();
        }
    }

    /************************************************************************************************************************************
    @ Method:         calc_DB
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0009132 - [EU Deals] Deals Budget & Deal Budget Month Batch Process
    @                 Update fields on parent Deal Budget
    @                 Summary fields to calculate and update respective "Deal Budget" records. Please consider ALL child "Deal Budget Month" records.
    @                 SUM(EBH_DealsBudgetMonth__c.Subsidy_Planned__c) = EBH_DealsBudget__c.Subsidy_Planned__c
    @                 SUM(EBH_DealsBudgetMonth__c.EBH_SubsidyForecast__c) = EBH_DealsBudget__c.Subsidy_Forecast__c
    @                 SUM(EBH_DealsBudgetMonth__c.Subsidy_Final__c) = EBH_DealsBudget__c.Subsidy_Final__c
    --------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 23.04.2021 / Acmatac SEING / Created the method.
    @                 21.05.2021 / SRONG TIN / US-0009552 - [Bug] Need to sum all the Deal Budget (Month) Subsidy Running field to Deal Budget Subsidy Running. to Deal
    **************************************************************************************************************************************/

    
    private void calc_DB(List<EBH_DealsBudget__c> scope){
        List<EBH_DealsBudget__c> lstDB = new List<EBH_DealsBudget__c>();
        for(AggregateResult oDB : Database.Query(SOQL_DEALBUDGET_MONTH_SUM)){
            lstDB.add(new EBH_DealsBudget__c(
            Id = (Id) oDB.get('EBH_DealsBudget__c'),
            Subsidy_Planned__c = (Decimal) oDB.get('Sum_SubsidyPlanned'),
            Subsidy_Forecast__c = (Decimal) oDB.get('Sum_SubsidyForecast'),
            Subsidy_Running__c = (Decimal) oDB.get('Sum_SubsidyRunning'),//US-0009552
            Subsidy_Final__c = (Decimal) oDB.get('Sum_SubsidyFinal')    
            ));
        }
        if(!lstDB.isEmpty()){
            update lstDB;
        }
    }
}