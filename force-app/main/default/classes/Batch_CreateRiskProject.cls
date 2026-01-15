/*********************************************************************************************************************************
@ Class:        Batch_CreateRiskProject
@ Version:      1.0
@ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:      US-0010175 - [UK Risk] Create automatic Risk project records as per logic
@ when (Entry Criteria)
@ {!Customer.Risk_Last_modified_Date__c} => 90 days (equal to (or) greater than 90 days)
@ {!Customer.Risk_Status__c} = Approved
@ there should be an automation to-Update {!Customer.Risk_Status__c}= Pending
@ trigger creation of [EBH_Project__c], record type=Seller_Risk_Management 
@ auto populate the following fields
@ {EBH_Project__c.Name} = "{!Customer.BusinessName} Daily Deals re-vetting"
@ {EBH_Project__c.EBH_Seller__c} = {!Customer.BusinessName}
@ {EBH_Project__c.Request_Type__c} = Daily Deals/Promotions
@ {EBH_Project__c.Stage}= Submitted
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.Aug.2021 / Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@                   22.March.2022 / Sovantheany Dim , Updated the logic :US-0011271 - Automated Risk Project logic enhancement
@ Change history: 27.Apr.2022 / Chetra Sarom (chetra.sarom@gaea-sys.com) :US-0011612 - Automated Risk Project logic modification
*********************************************************************************************************************************/
global without sharing class Batch_CreateRiskProject implements Database.Batchable<SObject>, Schedulable{
    private static String RISK_PROJECT_RECORDTYPE = 'Seller_Risk_Management';
    private static String DAILY_DEAL_TYPE = 'Daily Deals/Promotions';
    private static String STAGE_SUBMITTED = 'Submitted ';
    public static String APPROVED = 'Approved';
    private static String PENDING = 'Pending ';
    private static Set<String> SET_REVROLLUP = new Set<String>{'UK', 'US', 'FR', 'IT', 'DE'};
    //TH:22/03/2022:US-0011271

    // 27.Apr.2022 / Chetra Sarom (chetra.sarom@gaea-sys.com) / US-0011612 - Automated Risk Project logic modification
	//private static String SOQL_CUSTOMER = 'SELECT id,Risk_Status__c,Name FROM Account where Risk_Status__c =: APPROVED AND EBH_RevRollup__c IN: SET_REVROLLUP AND (((System_Risk_Tier__c = 1 OR System_Risk_Tier__c = 2) AND Risk_Last_modified_Date__c <=: last360Days) OR (System_Risk_Tier__c = 3 AND Risk_Last_modified_Date__c <=: last180Days) OR (System_Risk_Tier__c = 4 AND Risk_Last_modified_Date__c <=: last90Days) OR (System_Risk_Tier__c = 5 AND Risk_Last_modified_Date__c <=: last45Days))';
    private static String SOQL_CUSTOMER = 'SELECT id,Risk_Status__c,Name FROM Account where Risk_Status__c =: APPROVED AND EBH_RevRollup__c IN: SET_REVROLLUP AND (((Risk_tier_manual__c = 1 OR Risk_tier_manual__c = 2) AND Risk_Last_modified_Date__c <=: last360Days) OR (Risk_tier_manual__c = 3 AND Risk_Last_modified_Date__c <=: last180Days) OR (Risk_tier_manual__c = 4 AND Risk_Last_modified_Date__c <=: last90Days) OR (Risk_tier_manual__c = 5 AND Risk_Last_modified_Date__c <=: last45Days))';
    // end US-0011612

    global Database.querylocator start(Database.BatchableContext bc) {
        DateTime last90Days = System.now()-90;
        DateTime last45Days = System.now()-45;
        DateTime last180Days = System.now()-180;
        DateTime last360Days = System.now()-360;
        return Database.getQueryLocator(SOQL_CUSTOMER);
    }
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        Id riskRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Project__c',RISK_PROJECT_RECORDTYPE).Id;
        List<Account> lstAccount = new List<Account>();
        List<EBH_Project__c > lstProject = new List<EBH_Project__c>();
        for(Account acc : scope){
            acc.Risk_Status__c = PENDING;
            lstAccount.add(acc);
            lstProject.add(new EBH_Project__c(Name = acc.Name+' '+System.Label.RiskProjectName,
                                              EBH_Seller__c  = acc.Id,
                                              Request_Type__c = DAILY_DEAL_TYPE,
                                              EBH_Stage__c = STAGE_SUBMITTED,
                                              RecordTypeId = riskRecordTypeId));
        }
        update lstAccount;
        insert lstProject;
        
    }
    global void finish(Database.BatchableContext bc) {
    }
    
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new Batch_CreateRiskProject());
    }
}