/*********************************************************************************************************************************
@ Class:          CampaignSendEmailandStatusUpdateBatch
@ Version:        1.0
@ Author:         Anujit
@ Purpose:        Batch class to update Campaign status to Stopped and send email to campaign owner
US-0014522 - Campaign Status to be Stopped and Reminded about the same to the Campaign Owner
*********************************************************************************************************************************/

global with sharing class CampaignSendEmailandStatusUpdateBatch implements Database.Batchable<SObject>{

    static date endDateInSevenDays = system.today()+7;
    static date endDateYesterday = system.today()-1;
    static final string COMPLETED = 'Completed';
    static final string emailTemplateName = 'Email_Template_for_Reminding_CampOwner';
    static final string orgWideEmailId = 'dl-ebay-hive-support@ebay.com';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        string campaignSoqlStr = 'SELECT Id, Name, Status,OwnerId,Owner.Email, EndDate FROM Campaign WHERE (EndDate != NULL AND (EndDate =: endDateInSevenDays OR EndDate =: endDateYesterday) AND Status !=: COMPLETED) WITH SYSTEM_MODE';
        return Database.getQueryLocator(campaignSoqlStr);
    }

    global void execute(Database.BatchableContext BC, List<Campaign> scope) {
        doUpdateCampaignStatusToStopped(scope);
        prepareCampaignListForEmail(scope);
    }

    global void finish(Database.BatchableContext BC) {

    }

    /**
     * Update the campaign status to stopped  when the Campaign end date+1 had reached
     */
    private void doUpdateCampaignStatusToStopped(List<Campaign> campaignList){

        List<Campaign> campaignListToUpdate = new List<Campaign>();
        Feature_Switch__c featureSwitch = Feature_Switch__c.getOrgDefaults(); //get org default feature switch

        for(Campaign campaign : campaignList){
            if(campaign.EndDate == endDateYesterday && featureSwitch.Update_Campaign_Status_to_Stopped__c){ 
                campaign.Status = COMPLETED;
                campaignListToUpdate.add(campaign);
            }          
        }
        
        try{
            update as system campaignListToUpdate;
        } catch(Exception ex) {
            System.debug(ex);
            EBH_ApexLogger.logError(new List<Exception> { ex }, 'CampaignSendEmailandStatusUpdateBatch', 'doUpdateCampaignStatusToStopped');
        }
    }

    /**
     * Prepare Campaign list to send to the Campaign owner. campaign end date+7 days
     */
    private void prepareCampaignListForEmail(List<Campaign> campaignList){

        List<Campaign> campaignListEndingInNextSevenDays = new List<Campaign>();

        for(Campaign campaign : campaignList){
            if(campaign.EndDate == endDateInSevenDays){ 
                campaignListEndingInNextSevenDays.add(campaign);
                system.debug('camName='+campaign.Name);
            }          
        }
        sendEmailResult(campaignListEndingInNextSevenDays);
    }

    /**
     * Send email to the Campaign owner. campaign end date+7 days
     */
    private void sendEmailResult(List<Campaign> campaignList){
        List<Messaging.SingleEmailMessage> listEmail = new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTmp = [SELECT Id from EmailTemplate WHERE DeveloperName =: emailTemplateName LIMIT 1];
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: orgWideEmailId LIMIT 1];

        for(Campaign campaign : campaignList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(emailTmp.Id);
            mail.setTargetObjectId(campaign.OwnerId);
            mail.setWhatId(campaign.Id);
            mail.setSaveAsActivity(false);
            mail.setToAddresses(new List<String> {campaign.Owner.Email});
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
            listEmail.add(mail);
        }
        try{
            Messaging.sendEmail(listEmail);
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, 'CampaignSendEmailandStatusUpdateBatch', 'sendEmailResult');
        }
    }
    
}