/*********************************************************************************************************************************
@ Class:         Batch_ContractStatus
@ Version:       1.0
@ Author:        Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:       US-0012107 - [Contract] Auto Expiration of Contracts not working			 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.07.2022 / Sambath Seng / Created the class.
@                 23.08.2024 / Mony Nou / US-0015669 - Update Contract Process Stage Changes
*********************************************************************************************************************************/
global with sharing class Batch_ContractStatus implements Database.Batchable<SObject>, Schedulable{	
    
    private static final string CONTRACT_STATUS_EXECUTED = 'Executed';
    private static final string CONTRACT_STATUS_EXPIRED = 'Expired';
    private Set<String> setContractRecType = new Set<String>{'EBH_ListingAgreement', 'EBH_ACP', 'VIP_Contracts'}; //MN-230824-0015669:Add VIP Contract 
	private String soqlContract = 'Select Status, EndDate, RecordType.DeveloperName From Contract';
    private String sWhere = ' Where Status =:CONTRACT_STATUS_EXECUTED AND RecordType.DeveloperName IN:setContractRecType AND EndDate <= TODAY';
    private String contractId;

    public Batch_ContractStatus()
    {
    }
    
	public Batch_ContractStatus(String contractId)
    {
    	this.contractId = contractId;
    	sWhere += ' And Id =:contractId';
    }
	
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(soqlContract+sWhere);
    }

    global void execute(Database.BatchableContext pBc, List<Contract> scope){
        
        List<Contract> lstContractUpdate = new List<Contract>();
        
        for (Contract oContract : scope){

            oContract.Status = CONTRACT_STATUS_EXPIRED;
            lstContractUpdate.add(oContract);

		}

        if (!lstContractUpdate.isEmpty()) {
            
            Database.SaveResult[] results = Database.update(lstContractUpdate,false);
            List<Database.Error> dbError = new List<Database.Error>();

            for (Database.SaveResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()){ dbError.addAll(result.getErrors()); }
            }

            if (!dbError.isEmpty()) EBH_ApexLogger.logError(dbError, 'Batch_ContractStatus','execute (batch)');
        }

    }

    global void finish(Database.BatchableContext pBc){

    }
    global void execute(SchedulableContext sc) { 
        Batch_ContractStatus b = new Batch_ContractStatus();
        Database.executeBatch(b);
    }

}