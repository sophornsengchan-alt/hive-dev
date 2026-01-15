/*********************************************************************************************************************************
@ Class:         Batch_RemoveInActiveGroupMembers
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       US-0013423 - Admin : Scheduled job to find inactive users in email alert groups
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.08.2019 / Vadhanak Voun / Created the class.
*********************************************************************************************************************************/
global with sharing class Batch_RemoveInActiveGroupMembers implements Database.Batchable<SObject>, Schedulable{
     
    private final String SOQL_GROUP_MEMBER = 'Select Id,UserOrGroupId, Group.DeveloperName, GroupId From GroupMember ';
    private String where_USER = ' WHERE UserOrGroupId IN (Select Id From User where IsActive=FALSE)';
    private String groupApiName = '';
    
    public Batch_RemoveInActiveGroupMembers()
    {
        where_USER = Test.isRunningTest()? where_USER +' LIMIT 5' : where_USER;
    }
    //test purpose
    public Batch_RemoveInActiveGroupMembers(String groupApiName)
    {
        this.groupApiName = groupApiName;
        where_USER += ' AND Group.DeveloperName =:groupApiName';
    } 

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(SOQL_GROUP_MEMBER + where_USER);
    }

    global void execute(Database.BatchableContext pBc, List<SObject> scope)
    {
        //remove the membership
        Database.delete(scope,false);
    }

    global void finish(Database.BatchableContext pBc)
    {
         
    }

    //for scheduler
    global void execute(SchedulableContext sc) { 
        Batch_RemoveInActiveGroupMembers b = new Batch_RemoveInActiveGroupMembers();
        Database.executeBatch(b);
    }

}