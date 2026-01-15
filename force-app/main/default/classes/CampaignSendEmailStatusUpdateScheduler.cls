/*********************************************************************************************************************************
@ Class:          CampaignSendEmailStatusUpdateScheduler
@ Version:        1.0
@ Author:         Anujit
@ Purpose:        Scheduled Batch Class to send Email to the Campaign Members and Update the Campaign Status
US-0014522 - Campaign Status to be Stopped and Reminded about the same to the Campaign Owner
*********************************************************************************************************************************/

global class CampaignSendEmailStatusUpdateScheduler implements Schedulable{
	global void execute(SchedulableContext sc) { 
        CampaignSendEmailandStatusUpdateBatch campaignEmailSchedulerClass = new CampaignSendEmailandStatusUpdateBatch();
        Database.executeBatch(campaignEmailSchedulerClass, 100);
    }
}