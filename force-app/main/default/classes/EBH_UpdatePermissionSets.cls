/*********************************************************************************************************************************
@ Class:        EBH_UpdatePermissionSets
@ Version:      1.0
@ Author:       David Herrero
@ Purpose:      Update permission set field on user every 15 minutes
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.06.2018 / David Herrero / Created the class.
@ Change history: 16.11.2021 / SRONG TIN / US-0008349 / Update for Test class coverage purpose.
*********************************************************************************************************************************/

global without sharing class EBH_UpdatePermissionSets implements Database.Batchable<SObject>,Schedulable 
{	
	
	@TestVisible private String soql = null;
	
	
	@TestVisible private Integer batchSize = 10;
    //16.11.2021 / SRONG TIN / US-0008349
	public EBH_UpdatePermissionSets(String soql){
        this.soql = soql;
    }
	
    global Database.querylocator start(Database.BatchableContext bc)
    {
    	return Database.getQueryLocator(Test.isRunningTest()?soql:'select id,permission_sets__c from User where isactive=true and profile.UserLicense.name=\'Salesforce\'');
    }
    
    global void execute(Database.BatchableContext bc,List<User> scope)
    {
        EBH_UserTriggerHandler.UpdatePermissionSets(scope, new Map<ID,User>(scope));
    }
    global void finish(Database.BatchableContext bc)
    {
    	
    }
    
    //for scheduler
    global void execute(SchedulableContext ctx){
        //16.11.2021 / SRONG TIN / US-0008349
        EBH_UpdatePermissionSets batchPermissionSet = new EBH_UpdatePermissionSets(soql);
        if(!Test.isRunningTest()){Database.executeBatch(batchPermissionSet,batchSize);}
    }
    
       }