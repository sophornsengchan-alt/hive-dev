/*********************************************************************************************************************************
@ Class:          BatchIdentifyFailedPortalUser
@ Version:        1.0
@ Author:        Mony Nou
@ Purpose:       US-0016679: To identify active portal users created in the last 30 minutes who are not assigned to any portal groups, 
@                    based on the SP main domain field.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  13.03.2025 / Mony Nou / Created the class.
*********************************************************************************************************************************/
global with sharing class BatchIdentifyFailedPortalUser implements Database.Batchable<SObject>,Schedulable {

    private final static String SOQLCLAUSE_PROFILENAME = '%Seller Portal%';
    private final static String SOQLCLAUSE_GROUPNAME = '%_Seller_Portal';
    private final static String SOQLCLAUSE_GROUPTYPE = 'Regular';
    private final static String SOQLCLAUSE_PERMISSIONSET = '%Seller_Portal%';
    
    private String SOQL = 'SELECT Id, Contact.Account.SP_Main_Domain__c, Name, Profile.Name, Permission_Sets__c, Createddate, PendingforProcessing__c FROM User';
    private String SOQL_WHERE = ' WHERE IsActive = true AND Profile.Name LIKE:SOQLCLAUSE_PROFILENAME AND Permission_Sets__c <> NULL AND Permission_Sets__c LIKE:SOQLCLAUSE_PERMISSIONSET';
    private String CLAUSE_DEFAULT = ' AND Id NOT IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.Name LIKE:SOQLCLAUSE_GROUPNAME AND Group.Type =:SOQLCLAUSE_GROUPTYPE)';
    private String CLAUSE_PENDINGPROCESS = ' AND PendingforProcessing__c = TRUE';
    private Set<Id> sUserIds = new Set<Id>();

    private Boolean isPendingProcessing = false;

    private static Map<String, Id> mSEPPubGroup {
        get {
            if (mSEPPubGroup == null) {
                mSEPPubGroup = new Map<String, Id>();
                for (Group grp : [SELECT Id, DeveloperName FROM  Group WHERE Type='Regular' AND DeveloperName IN:SEP_Helper.mSEPDomainPubGroup.values()]) {
                    mSEPPubGroup.put(grp.DeveloperName, grp.Id);
                }
            }
            return mSEPPubGroup;
        }
        private set;
    }

    public BatchIdentifyFailedPortalUser(Set<Id> sUserIds){
        this.sUserIds = sUserIds;
        this.SOQL_WHERE = ' WHERE Id IN :sUserIds';
    }

    public BatchIdentifyFailedPortalUser(Boolean isPendingProcessing){
        this.SOQL_WHERE += (isPendingProcessing) ? CLAUSE_PENDINGPROCESS : CLAUSE_DEFAULT;
        this.isPendingProcessing = isPendingProcessing;
    }

    public BatchIdentifyFailedPortalUser(){
        this.SOQL_WHERE += CLAUSE_DEFAULT;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(SOQL + SOQL_WHERE);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope){

        
        Map<Id, GroupMember> mGM2Insert = new Map<Id, GroupMember>();

        Set<Id> sPendingProcessUserIds = new Set<Id>();

        for (User usr : (List<User>)scope){

            String spMainDomain = usr.Contact?.Account?.SP_Main_Domain__c;

            // Add user to the public group based on the SP main domain
            if (String.isNotBlank(spMainDomain) && SEP_Helper.mSEPDomainPubGroup.containsKey(spMainDomain)) {
                Id pgId = mSEPPubGroup.get(SEP_Helper.mSEPDomainPubGroup.get(spMainDomain));
                mGM2Insert.put(usr.Id, new GroupMember(UserOrGroupId = usr.Id, GroupId = pgId));
            }

            // Check if the user is pending for processing
            if (usr.PendingforProcessing__c) {
                sPendingProcessUserIds.add(usr.Id);
            }
        }

        if (isPendingProcessing && !sPendingProcessUserIds.isEmpty()) {

            List<GroupMember> lstGM2Delete = new List<GroupMember>();
            Set<Id> sUserIds2Reset = new Set<Id>();

            //Find the SEP Group that the user is currently in and remove them from the group            
            for (GroupMember gm : [SELECT Id, UserOrGroupId, GroupId FROM GroupMember WHERE UserOrGroupId IN :sPendingProcessUserIds AND Group.Type =:SOQLCLAUSE_GROUPTYPE AND Group.Name LIKE:SOQLCLAUSE_GROUPNAME]) {
                
                //If the user is in the correct group, remove them from the list to be deleted (example: If user changed from "Seller Portal Member" profile to SEP Profile)
                if (mGM2Insert.containsKey(gm.UserOrGroupId) && gm.GroupId == mGM2Insert.get(gm.UserOrGroupId).GroupId) {
                    mGM2Insert.remove(gm.UserOrGroupId);
                    sUserIds2Reset.add(gm.UserOrGroupId);
                } else {
                    lstGM2Delete.add(gm);
                }
            }


            //Delete the user from the old/incorrect group
            Database.DeleteResult[] deleteResult = ApexSafe.dml().doDelete(lstGM2Delete,false); //false for partial success
            logError(deleteResult);
            
            //Find the users that are successfully deleted from the group to reset the PendingforProcessing__c field
            List<User> lstUser2Reset = [SELECT Id FROM User WHERE PendingforProcessing__c = TRUE AND Id IN :sPendingProcessUserIds AND Id NOT IN (Select UserOrGroupId FROM GroupMember WHERE Id IN:lstGM2Delete)];

            sUserIds2Reset.addAll(new Map<Id, User>(lstUser2Reset).keySet());

            //Reset the PendingforProcessing__c field
            List<User> lstUser2Update = new List<User>();
            for (Id usr : sUserIds2Reset) {
                lstUser2Update.add(new User(Id = usr, PendingforProcessing__c = false));
            }

            Database.SaveResult[] updateResult = ApexSafe.dml().doUpdate(lstUser2Update,false); //false for partial success
            logError(updateResult);

        }

        //Insert the user to the correct SEP public group based on the SP main domain
        Database.SaveResult[] insertResult = ApexSafe.dml().doInsert(mGM2Insert.values(),false); //false for partial success
        logError(insertResult);
    }

    global void finish(Database.BatchableContext pBc){
        if (!isPendingProcessing) {
            Database.executeBatch(new BatchIdentifyFailedPortalUser(true)); //Call the batch again to process the pending users
        }
    }

    global void execute(SchedulableContext sc) { // make it available to be scheduled
        Database.executeBatch(new BatchIdentifyFailedPortalUser());
    }

    @testvisible
    private void logError(Database.SaveResult[] insertResult)
    {
        
        List<Database.Error> listErrors = new List<Database.Error>();
        for (Database.SaveResult sr : insertResult) 
        {
            if (!sr.isSuccess()) { listErrors.addAll(sr.getErrors()); }
        }

        if(!listErrors.isEmpty()) { EBH_ApexLogger.logError(listErrors, 'BatchIdentifyFailedPortalUser','execute-insert'); }
    }

    
    @testvisible
    private void logError(Database.DeleteResult[] deleteResult)
    {
        
        List<Database.Error> listErrors = new List<Database.Error>();
        for (Database.deleteResult sr : deleteResult) 
        {
            if (!sr.isSuccess()) { listErrors.addAll(sr.getErrors()); }
        }

        if(!listErrors.isEmpty()) { EBH_ApexLogger.logError(listErrors, 'BatchIdentifyFailedPortalUser','execute-delete'); }
    }
        

}