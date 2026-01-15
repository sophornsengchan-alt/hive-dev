/*********************************************************************************************************************************
@ Class:          DealBudgetTriggerHandler
@ Version:        1.0
@ Author:         Sreymeas Nao (sreymeas.nao@gaea-sys.com)
@ Purpose:        Handler Class for DayTrigger (Day__c)
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.06.2019 / Sreymeas Nao / Created the class.
*********************************************************************************************************************************/
public without sharing class DealBudgetTriggerHandler {

	public static List<EBH_DealsBudgetMonth__c> addDealBudget = new List<EBH_DealsBudgetMonth__c>();		
	public static Date datobj = System.today();

	/*****************************************************************************************************************************
    @ Method:         createDealBudgetMonth
    @ Version:        1.0
    @ Author:         Sreymeas Nao
    @ Purpose:        create Related record Deal Budget Month
    @ Event:		  After Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<EBH_DealsBudget__c> newDealBudget
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.06.2019 / Sreymeas Nao / Created the  Method.
    *****************************************************************************************************************************/
	public static List<EBH_DealsBudgetMonth__c> createDealBudgetMonth(List<EBH_DealsBudget__c> newDealBudget){
		Map<String, List<Integer>> mMonthQ = new Map<String, List<Integer>>{
			'Q1'=> new List<Integer>{1,3},
			'Q2'=> new List<Integer>{4,6},
			'Q3'=> new List<Integer>{7,9},
			'Q4'=> new List<Integer>{10,12}
		};

		List<EBH_DealsBudgetMonth__c> result = new List<EBH_DealsBudgetMonth__c>();
		for(EBH_DealsBudget__c oneDealBudget : newDealBudget){
			result.addAll(DealBudgetTriggerHandler.generateDealsBudgetMonths(mMonthQ.get(oneDealBudget.EBH_Quarter__c)[0],mMonthQ.get(oneDealBudget.EBH_Quarter__c)[1], oneDealBudget.EBH_Quarter__c, oneDealBudget));
			
		}
		insert result;
		return result;
	}

  	public static List<EBH_DealsBudgetMonth__c> generateDealsBudgetMonths(Integer monthStart, Integer monthEnd, String q, EBH_DealsBudget__c oneDealBudget){
  		List<EBH_DealsBudgetMonth__c> result = new List<EBH_DealsBudgetMonth__c>();
  		Map<Integer, String> mMonth = new Map<Integer, String>{
			1=> 'January', 
			2=> 'February', 
			3=> 'March', 
			4=> 'April',
			5=> 'May',
			6=> 'June',
			7=> 'July',
			8=> 'August',
			9=> 'September',
			10=> 'October',
			11=> 'November',
			12=> 'December'
		};
		
  		for(Integer i=monthStart; i<=monthEnd; i++){
				EBH_DealsBudgetMonth__c monthQ = new EBH_DealsBudgetMonth__c(EBH_DealsBudget__c = oneDealBudget.Id, EBH_Month__c = mMonth.get(i));
				result.add(monthQ);
		}  	
  		
  		return result;
  	}

}