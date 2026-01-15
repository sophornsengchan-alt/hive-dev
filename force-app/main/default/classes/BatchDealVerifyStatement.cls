/*********************************************************************************************************************************
@ Class:         BatchDealVerifyStatement
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       EPH-8050 Verify Statement Work Flow Rule is not working
@				moved from workflow to dail scheduler (formula fields does not trigger!)				 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.09.2019 / Vadhanak Voun / Created the class.
@ Change history: 06.06.2022 / Sophal Noch / US-0011771 - Updating Deals to "Verify Statement" Batch
@                 05.10.2022 / Acmatac SEING / US-0012664 - Deals are stuck in Executed
*********************************************************************************************************************************/
global without sharing class BatchDealVerifyStatement implements Database.Batchable<SObject>, Schedulable{
	private Set<String> setStatusInclude = new Set<String>{EBH_DealTriggerHandler.DEAL_STATUS_EXECUTED};
	private String soqlDeal = 'Select Id From EBH_Deal__c ';
	
	@testVisible
	// private String sWhere = ' Where NumberOfDaysSinceDealEnd__c=32 AND EBH_Status__c IN:setStatusInclude AND EBH_SubsidyFinal__c >0 ';
    private String sWhere = ' Where NumberOfDaysSinceDealEnd__c >= 32 AND EBH_Status__c IN:setStatusInclude AND EBH_SubsidyFinal__c >0 '; // 06.06.2022 / Sophal Noch / US-0011771
    
    
    private String dealId;
    public BatchDealVerifyStatement()
    {
    }
    
    //testigng purpose
	public BatchDealVerifyStatement(String dealId)
    {
    	this.dealId = dealId;
    	sWhere += ' And Id =:dealId';
    }
	
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(soqlDeal+sWhere);
    }

    global void execute(Database.BatchableContext pBc, List<EBH_Deal__c> scope){

        for (EBH_Deal__c d : scope)
        {
            d.EBH_Status__c = EBH_DealTriggerHandler.DEAL_STATUS_VERIFY_STATEMENT;
        }

        Database.SaveResult[] results =  Database.update(scope, false);
        List<Database.Error> dbError = new List<Database.Error>();

        for(Database.SaveResult result : results) {
            if(!result.isSuccess()){
                dbError.addAll(result.getErrors());
            }
        }

        if (!dbError.isEmpty()){
            EBH_ApexLogger.logError(dbError, 'BatchDealVerifyStatement','execute (batch)');
        }
    }

    global void finish(Database.BatchableContext pBc){

    }
    global void execute(SchedulableContext sc) { 
        BatchDealVerifyStatement b = new BatchDealVerifyStatement();
        Database.executeBatch(b);
    }
    
    
}