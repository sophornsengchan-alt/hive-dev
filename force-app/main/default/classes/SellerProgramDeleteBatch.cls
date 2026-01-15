/*********************************************************************************************************************************
@ Class:        SellerProgramDeleteBatch
@ Author:       Acmatac SEING
@ Purpose:      US-0016663 Inactive cohort sellers are flagged as managed
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.01.2025 / Acmatac SEING / Created the batch.
*********************************************************************************************************************************/
public class SellerProgramDeleteBatch implements Database.Batchable<sObject>, Database.Stateful{
    private final String ATM_TO_DELETE_SOQL = 'SELECT Id FROM AccountTeamMember WHERE Last_Sync_Date_Time__c != null AND Last_Sync_Date_Time__c <: currentDateTime AND TeamMemberRole IN: roleSet';
    private Datetime currentDateTime = null;
    private Set<String> roleSet = new Set<String>();
    private List<String> errorMessages = new List<String>();

    public SellerProgramDeleteBatch(Datetime currentDateTime, Set<String> roleSet){
        this.currentDateTime = currentDateTime;
        this.roleSet = roleSet;
    }
    public Database.QueryLocator start(Database.BatchableContext batchCont){
        return Database.getQueryLocator(ATM_TO_DELETE_SOQL); 
    }
    
    public void execute(Database.BatchableContext batchCont, List<SObject> listRecord){
        List<Database.DeleteResult> deleteResults = Database.delete(listRecord, false);
        List<Database.Error> listErrorException = new List<Database.Error>();
        
        for (Integer i = 0; i < deleteResults.size(); i++) {
            if (!deleteResults[i].isSuccess()) {
                for (Database.Error oError : deleteResults[i].getErrors()) {
                    listErrorException.add(oError);
                    errorMessages.add(oError.getMessage());
                }
            }
        }
        if(!listErrorException.isEmpty()){
            EBH_ApexLogger.logError(listErrorException, 'SellerProgramDeleteBatch','execute deleting the old program');
        }
        
    }

    public void finish(Database.BatchableContext batchCont){
        if(!errorMessages.isEmpty()){
            sendResult(errorMessages);
        }
    }

    @TestVisible
    private void sendResult(List<String> errorMessages){
        List<EmailTemplate> empt = ApexSafe.query().doQuery('SELECT Body,Id,DeveloperName,Subject,HtmlValue FROM EmailTemplate Where DeveloperName =: EMAILTEMPLATE_SELLER_PROGRAM_SYNC_ALERT', new Map<String, Object>{'EMAILTEMPLATE_SELLER_PROGRAM_SYNC_ALERT' => SellerProgramSyncBatch.EMAILTEMPLATE_SELLER_PROGRAM_SYNC_ALERT});
        String htmlBody = contructBody(empt[0].HtmlValue, errorMessages);
        if(!Test.isRunningTest()) ApexUtil.doSend(empt[0].subject,Label.SellercrmScheduleBatchAlertChannelEmail,htmlBody);
    }
    
    private String contructBody(String hbody, List<String> errorMessages){
		return hbody
		.replace('{!ErrorMessage}',String.join(errorMessages,'<br>'));
	}
}