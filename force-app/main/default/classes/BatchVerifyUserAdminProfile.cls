/*********************************************************************************************************************************
@ Class:          BatchVerifyUserAdminProfile
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0012474 - 9Elevated Admin Access - 3 Ensure Appropriate User Permissions and Profiles
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.06.2025 / Sovantheany Dim / Created the class.
********************************************************************************************************************************/
public with sharing class BatchVerifyUserAdminProfile implements Database.Batchable<SObject>, Schedulable, Database.Stateful{
    private static final String ADMIN = 'System Administrator';
    private static final String BUSINESS_ADMIN = 'Business Admin';
    private String bsinessAdminProfileId = ApexUtil.getProfileByName(BUSINESS_ADMIN).Id;
    public static final String TICKET_TYPE_FULL_ADMIN = 'Full System Admin';
    private Set<String> setStatus = new Set<String>{'Approved'};
    private Datetime dateTimeNow = Datetime.now();
    public static final String TICKET_RECORD_TYPE = 'Elevated_Access_Request';
    private Set<String> setExcludeUser = new Set<String>{'hseel@hive.project.com','romaier@hive.project.com'}; // Exclude these users from the batch
    private String sQuery = 'SELECT Id, Name, ProfileId FROM User WHERE Profile.Name =: ADMIN AND IsActive = true AND Username NOT IN: setExcludeUser';
    private String sTicketQuery = 'SELECT Previous_Profile_Id__c , User__c FROM Ticket__c WHERE User__c IN: setUserIds AND Status__c IN: setStatus AND RecordType.DeveloperName =: TICKET_RECORD_TYPE AND Type_of_Elevated_Access__c =: TICKET_TYPE_FULL_ADMIN AND Previous_Profile_Name__c != null AND Previous_Profile_Name__c !=: ADMIN AND Duration_In_Date_time__c <: dateTimeNow';//AND Duration_In_Date_time__c <: Datetime.now()
    private String userId;
    private Set<String> setUserIds = new Set<String>();
    private final static String OBJ_USER = 'User';
    private final static String OBJ_TICKET = 'Ticket__c';
    private String objToRun;

    public BatchVerifyUserAdminProfile() {
        this.objToRun = OBJ_USER;
    }
    // THIS CONSTRUCTOR IS USED FOR TESTING PURPOSES ONLY
    public BatchVerifyUserAdminProfile(String userId) {
        this.objToRun = OBJ_USER;
        this.userId = userId;
        this.sQuery += ' AND Id =: userId';
    }
    // This constuctor is used When finish method is called to run the next batch for Ticket Updated
    public BatchVerifyUserAdminProfile(String objToRun, Set<String> setUserIds) {
        this.objToRun = objToRun;
        this.setUserIds = setUserIds;
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String sQuery = objToRun == OBJ_USER ? sQuery : sTicketQuery;
        return Database.getQueryLocator(sQuery);
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if(objToRun == OBJ_USER){
            updateUser(scope);
        }
        else {
            updateTicket(scope);
       }
    }
    public void finish(Database.BatchableContext bc) {
        if(this.objToRun == OBJ_USER && !setUserIds.isEmpty()){
            BatchVerifyUserAdminProfile b = new BatchVerifyUserAdminProfile(OBJ_TICKET, setUserIds);
            Database.executeBatch(b);
        }
    }

    /*********************************************************************************************************************************
    @ Method:         updateUser
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantehany.dim@gmail.com)
    @ Purpose:        Update User Profile
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.06.2025 / Sovantheany Dim / Created the method.
    *********************************************************************************************************************************/
    private void updateUser(List<SObject> scope){
        List<User> listUser = (List<User>)scope;
        List<Ticket__c> listTicket = ApexSafe.query().doQuery(sTicketQuery,new Map<String, Object> {'setUserIds' => listUser, 'setStatus' => setStatus , 'TICKET_RECORD_TYPE' => TICKET_RECORD_TYPE, 'TICKET_TYPE_FULL_ADMIN' => TICKET_TYPE_FULL_ADMIN, 'ADMIN' => ADMIN, 'dateTimeNow' => dateTimeNow});
        
        Map<String,String> mapUserProfile = new Map<String,String>();
        for(Ticket__c tk : listTicket){
            mapUserProfile.put(tk.User__c, tk.Previous_Profile_Id__c);
        }
        List<User> listUserToUpdate = new List<User>();
        set<String> sUserIdsMatchingTicket = new Set<String>();
        for(User u : listUser){
            if(mapUserProfile.containsKey(u.Id)){
                u.ProfileId = mapUserProfile.get(u.Id);
            } 
            else {
                u.ProfileId = bsinessAdminProfileId; // Reset to Business Admin profile if no ticket found
            }
            listUserToUpdate.add(u);
        }

        try {
            
            Database.SaveResult[] results = ApexSafe.dml().doUpdate(listUserToUpdate, false);
            List<Database.Error> dbError = new List<Database.Error>();
            for (Database.SaveResult result : results) {
                if (result.isSuccess() && mapUserProfile.containsKey(result.getId())) {
                    setUserIds.add(result.getId());// Collect successfully updated user IDs to Updated Ticket to Complete
                }
                else if (!result.isSuccess() && !Test.isRunningTest()) { dbError.addAll(result.getErrors()); }
            }
            if (!dbError.isEmpty()) { EBH_ApexLogger.logError(dbError, 'BatchVerifyUserAdminProfile','Updated User Profile'); }

        } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchVerifyUserAdminProfile','Updated User Profile'); }
    }

    /*********************************************************************************************************************************
    @ Method:         updateTicket
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantehany.dim@gmail.com)
    @ Purpose:        Update Ticket Status to Completed after User Profile is updated
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.06.2025 / Sovantheany Dim / Created the method.
    *********************************************************************************************************************************/
    private void updateTicket(List<SObject> scope){
        List<Ticket__c> listTicket = (List<Ticket__c>)scope;
        //Update Ticket to Completed after finish updated User profile
        for (Ticket__c ticket : listTicket) {
                ticket.Status__c = 'Completed'; // Update status to Completed
        }
        try {
            Database.SaveResult[] ticketResults = ApexSafe.dml().doUpdate(listTicket, false);
            List<Database.Error> ticketErrors = new List<Database.Error>();
            for (Database.SaveResult result : ticketResults) {
                if (!result.isSuccess() && !Test.isRunningTest()) { ticketErrors.addAll(result.getErrors()); }
            }
            if (!ticketErrors.isEmpty()) { EBH_ApexLogger.logError(ticketErrors, 'BatchVerifyUserAdminProfile','Updated Ticket'); }
        } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchVerifyUserAdminProfile','Updated Ticket'); }
    }

    public void execute(SchedulableContext sc) {
        BatchVerifyUserAdminProfile batch = new BatchVerifyUserAdminProfile();
        Database.executeBatch(batch, 100);
    }
}