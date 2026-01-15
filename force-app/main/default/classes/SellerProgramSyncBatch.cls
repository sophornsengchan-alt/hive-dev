/*********************************************************************************************************************************
@ Class:        SellerProgramSyncBatch
@ Author:       Acmatac SEING
@ Purpose:      US-0016294 Display of eBay Points of Contact on Seller Growth Page
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.01.2025 / Acmatac SEING / Created the batch.
*********************************************************************************************************************************/
public class SellerProgramSyncBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    private final String POC_SOQL = 'SELECT Id, Label, Query_String__c, DeveloperName, Order__c FROM Program_POC__mdt WHERE Is_Active__c = true ORDER BY Order__c DESC';
    private final String POC_ROLE_SOQL = 'SELECT Id, Program__c, Program__r.Label, Role_Name__c, User_Display_Field__c, Account_Field__c, Order__c FROM Program_POC_Role__mdt WHERE Program__c IN:pocMDTIds  ORDER BY Order__c DESC';

    private Map<Id, Program_POC__mdt> pocMDT = new Map<Id, Program_POC__mdt>();
    private Map<Id, List<Program_POC_Role__mdt>> pocRoleMDT = new Map<Id, List<Program_POC_Role__mdt>>();
    private List<Id> pocIds = new List<Id>();
    private Set<String> roleSet = new Set<String>();
    private Integer batchStep = 0;

    public static final String EMAILTEMPLATE_SELLER_PROGRAM_SYNC_ALERT = 'Seller_Program_Sync_Alert_Email_Template';
    public Integer minuteN = 1440; //1440 => 1day
    public List<String> errorMessages = new List<String>();
    
    public SellerProgramSyncBatch(){
        this(0, null, null, null, null);
    }
    public SellerProgramSyncBatch(Integer minuteN){
        this(0, null, null, null, null);
        this.minuteN = minuteN;
    }
    public SellerProgramSyncBatch(Integer batchStep, Map<Id, Program_POC__mdt> pocMDT, Map<Id, List<Program_POC_Role__mdt>> pocRoleMDT, Set<String> roleSet, List<Id> pocIds) {
        try {
            this.batchStep = batchStep;
            
            if(pocMDT == null){
                this.pocMDT = new Map<Id, Program_POC__mdt>();
                this.pocIds = new List<Id>();
                // Adding like this to avoid Set<Id> auto sort which make our ordering incorrectly.                
                // for(Program_POC__mdt onePOCMDT: [SELECT Id, Label, Query_String__c, DeveloperName, Order__c FROM Program_POC__mdt WHERE Is_Active__c = true ORDER BY Order__c DESC]){
                for(Program_POC__mdt onePOCMDT: (List<Program_POC__mdt>) ApexSafe.query().doQuery(POC_SOQL)){
                    this.pocMDT.put(onePOCMDT.Id, onePOCMDT);
                    this.pocIds.add(onePOCMDT.Id);
                }
                this.pocRoleMDT = new Map<Id, List<Program_POC_Role__mdt>>();
                Set<Id> pocMDTIds = this.pocMDT.keySet();
                
                // for(Program_POC_Role__mdt pocRole: [SELECT Id, Program__c, Program__r.Label, Role_Name__c, User_Display_Field__c, Account_Field__c, Order__c FROM Program_POC_Role__mdt WHERE Program__c IN:pocMDTIds  ORDER BY Order__c DESC]){
                for(Program_POC_Role__mdt pocRole: (List<Program_POC_Role__mdt>) ApexSafe.query().doQuery(POC_ROLE_SOQL, new Map<String, Object>{'pocMDTIds' => pocMDTIds})){    
                    this.roleSet.add(pocRole.Role_Name__c);
                    if(this.pocRoleMDT.containsKey(pocRole.Program__c)){
                        this.pocRoleMDT.get(pocRole.Program__c).add(pocRole);
                    }else{
                        this.pocRoleMDT.put(pocRole.Program__c, new List<Program_POC_Role__mdt>{pocRole});
                    }
                }         
            }else {
                this.pocMDT = pocMDT;
                this.pocRoleMDT = pocRoleMDT;
                this.pocIds = pocIds;
                this.roleSet = roleSet;
            }
        }catch (Exception exc) {logError(exc, errorMessages, 'contructor'); }
    }

    public Database.QueryLocator start(Database.BatchableContext batchCont){
        try {
            String mapKey = pocIds[batchStep];
            Program_POC__mdt programPoc = pocMDT.get(mapKey);
            return Database.getQueryLocator(programPoc.Query_String__c); 
        }catch (Exception exc) {logError(exc, errorMessages, 'start'); 
            return null;
        }
    }
 
    public void execute(Database.BatchableContext batchCont, List<SObject> listRecord){
        try {
            String mapKey = pocIds[batchStep];
            Program_POC__mdt programPoc = pocMDT.get(mapKey);
            List<AccountTeamMember> listPreAccountTeam = new List<AccountTeamMember>();
            Set<Id> userDisplayIds = new Set<Id>();
            for (SObject oneRecord : listRecord) {
                for(Program_POC_Role__mdt progPocRole : this.pocRoleMDT.get(programPoc.Id)) {
                    String userId = String.valueOf(oneRecord.get(progPocRole.User_Display_Field__c));
                    if(String.isNotBlank(userId)){
                        // Create a new AccountTeamMember record     
                        listPreAccountTeam.add(new AccountTeamMember(
                            AccountId = String.valueOf(oneRecord.get(progPocRole.Account_Field__c)),
                            UserId = userId,
                            TeamMemberRole = String.valueOf(progPocRole.Role_Name__c),
                            Last_Sync_Date_Time__c = DateTime.now()
                        ));
                        userDisplayIds.add(userId);
                    }
                }
            }

            List<AccountTeamMember> listAccountTeamToInsert = new List<AccountTeamMember>();
            // prevent inactive user to be added as Account Team member user
            Map<Id, User> mapActiveUser = new Map<Id, User>((List<User>) ApexSafe.query().doQuery('SELECT Id FROM User WHERE Id IN: userDisplayIds AND IsActive = true', new Map<String, Object>{'userDisplayIds' => userDisplayIds}));
            for(AccountTeamMember oneATM : listPreAccountTeam) {
                if(mapActiveUser.containsKey(oneATM.UserId)){
                    listAccountTeamToInsert.add(oneATM);
                }
            }
            // Perform the insert operation with allOrNone set to false
            Database.SaveResult[] results = Database.insert(listAccountTeamToInsert, false);
            List<Database.Error> listErrorException = new List<Database.Error>();
            // Iterate over the results to handle successes and failures
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    // There was an error inserting the record
                    for (Database.Error oError : results[i].getErrors()) {
                        listErrorException.add(oError);
                        errorMessages.add(oError.getMessage());
                    }
                }
            }
            if(!listErrorException.isEmpty()){
                EBH_ApexLogger.logError(listErrorException, 'SellerProgramSyncBatch','execute (insert) listAccountTeamToInsert');
            }
        }catch (Exception exc) { logError(exc, errorMessages, 'execute'); }
    }

    public void finish(Database.BatchableContext batchCont){
        try {
            Integer nextStepToRun = batchStep + 1;
            if(nextStepToRun < pocIds.size())
            {
                SellerProgramSyncBatch b = new SellerProgramSyncBatch(nextStepToRun, pocMDT, pocRoleMDT, roleSet, pocIds);
                b.minuteN = this.minuteN;
                b.errorMessages = this.errorMessages;
                Database.executeBatch(b);
            }
            // Last step
            else{
                Datetime currentDateTime = DateTime.now().addMinutes(-minuteN);
                SellerProgramDeleteBatch spDelete = new SellerProgramDeleteBatch(currentDateTime, roleSet);
                Database.executeBatch(spDelete);
            }
        }catch (Exception exc) { logError(exc, errorMessages, 'finish'); }

        if(!errorMessages.isEmpty()) sendResult(errorMessages);
    }
    
    //for scheduler
    public void execute(SchedulableContext ctx){
    	SellerProgramSyncBatch b = new SellerProgramSyncBatch();
        Database.executeBatch(b);
    }

    @TestVisible
    private void sendResult(List<String> errorMessages){
        List<EmailTemplate> empt = ApexSafe.query().doQuery('SELECT Body,Id,DeveloperName,Subject,HtmlValue FROM EmailTemplate Where DeveloperName =: EMAILTEMPLATE_SELLER_PROGRAM_SYNC_ALERT', new Map<String, Object>{'EMAILTEMPLATE_SELLER_PROGRAM_SYNC_ALERT' => EMAILTEMPLATE_SELLER_PROGRAM_SYNC_ALERT});
        String htmlBody = contructBody(empt[0].HtmlValue, errorMessages);
        if(!Test.isRunningTest()) ApexUtil.doSend(empt[0].subject,Label.SellercrmScheduleBatchAlertChannelEmail,htmlBody);
    }

    private String contructBody(String hbody, List<String> errorMessages){
		return hbody
		.replace('{!ErrorMessage}',String.join(errorMessages,'<br>'));
	}

    @TestVisible
    private void logError(Exception exc, List<String> errorMessages, String methodName){
        errorMessages.add('SellerProgramSyncBatch '+methodName+' : '+exc.getStackTraceString());
        EBH_ApexLogger.logError(new List<Exception>{exc}, 'SellerProgramSyncBatch',methodName);
    }
}