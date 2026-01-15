/*********************************************************************************************************************************
@ Class:        BatchCheckEligibleForNADeals
@ Version:      1.0
@ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:      US-0011168 - 'NA Seller Portal Eligible' field on Account object
@               AC4: To determine how to automate this
@               On a daily basis Hive should run some automated code to determine what Accounts are "Eligible for NA Deals" using the Custom Metadata Record by the same name
@               Any record meeting the condition should have 'NA Seller Portal Eligible' set to TRUE
@               Any record no longer meeting the condition that currently has 'NA Seller Portal Eligible' should be set to FALSE
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.02.2022 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
global with sharing class BatchCheckEligibleForNADeals implements Database.Batchable<SObject>,Schedulable{
    private String soqlSeller = 'Select NA_Seller_Portal_Eligible__c From Account where RecordType.DeveloperName=:RECORD_TYPE_SELLER';
    private String soqlSeller2 = '';
    private static final String ELIGIBLE_FOR_NA_DEALS = 'Eligible_for_NA_Deals';
    private final String RECORD_TYPE_SELLER = 'EBH_Seller';
    private Map<String,String>  mapSetting;

    public BatchCheckEligibleForNADeals()
    {
        mapSetting =  getEligibleForNADealsSetting();
        soqlSeller2 = soqlSeller + ' AND (( '+ mapSetting.get(ELIGIBLE_FOR_NA_DEALS)+' ) OR NA_Seller_Portal_Eligible__c = true)';
    }

    global Database.querylocator start(Database.BatchableContext bc)
    {
    	return Database.getQueryLocator(soqlSeller2);
    }

    global void execute(Database.BatchableContext bc,List<Account> scope)
    {
        List<Account> lstAccToUpdate = new List<Account>();
        //Converting list to map
        Map<Id, Account> mapFromScope = new Map<Id, Account>(scope);
        String wherecls = ' AND ID IN: scope AND '+ mapSetting.get(ELIGIBLE_FOR_NA_DEALS);
        //Any record meeting the condition should have 'NA Seller Portal Eligible' set to TRUE
        for(Account acc : Database.query(soqlSeller + wherecls)){
            acc.NA_Seller_Portal_Eligible__c = true;
            lstAccToUpdate.add(acc);
            mapFromScope.remove(acc.Id);
        }
        //Any record no longer meeting the condition should be set to FALSE 
        for(Account acc : mapFromScope.values()){
            acc.NA_Seller_Portal_Eligible__c = false;
            lstAccToUpdate.add(acc);
        }
        if(!lstAccToUpdate.isEmpty()) update lstAccToUpdate;
    }
    global void finish(Database.BatchableContext bc)
    {
       
    }

    private static Map<String,String> getEligibleForNADealsSetting()
    {
        Map<String,String>  mapSetting = new Map<String,String>();
        for(Seller_Portal_Setting__mdt setting: [Select Id,DeveloperName,Filter_Values__c from Seller_Portal_Setting__mdt where DeveloperName  =: ELIGIBLE_FOR_NA_DEALS])
        {
            mapSetting.put(setting.DeveloperName,setting.Filter_Values__c);
        }
        return mapSetting;
    }

    //for scheduler
    global void execute(SchedulableContext ctx)
    {
    	BatchCheckEligibleForNADeals bCheckEligible = new BatchCheckEligibleForNADeals();
    	Database.executeBatch(bCheckEligible);
    }
}