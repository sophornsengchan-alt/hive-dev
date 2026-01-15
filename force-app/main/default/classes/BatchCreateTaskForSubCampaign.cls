/*********************************************************************************************************************************
@ Class:        BatchCreateTaskForSubCampaign
@ Version:      1.0
@ Author:       Acmatac Seing (acmatac.seing@gaea-sys.com)
@ Purpose:      EPH-7049 :
@    - For object: Campaign & Record type: Sub-Campaign & Sub-Campaign.Channel = GCX Outreach (Phone)
@    - Once per day check if SUM (Campaign Members) >0
@    - If yes, create one Task per each Campaign Member.
@    - Task.Subject = GCX Outreach call task
@    - Task.Type = Phone Outreach
@    - Task.RelatedTo.Name (WhoId) = Campaign Member.Customer
@    - Task.RelatedTo (WhatId) = Campaign Member.Campaign
@    - Task.Status = Open
@    - Do not dublicate tasks for the same combination of Task. 
@    RelatedTo.Name (WhoId) & Task.RelatedTo (WhatId)
@
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.March.2019 / Acmatac SEING (acmatac.seing@gaea-sys.com) / Created the class.
@                21.January.2020 / Acmatac SEING / US-0007006
@                09/03/2020/vadhanak voun/ US-0007189 [Sub Campaigns] Auto Task Assignment for Marketing Sub Campaigns
@                16/03/2020/vadhanak voun/ US-0007357 - Deleted Task got re-created after batch scheduler run
@                20/03/2020/acmatac seing/ fix null populate
@                29/12/2020/acmatac seing/ US-0008879 [Hypercare Bug] Too many query rows in BatchCreateTaskForSubCampaign
@                08/02/2020/vadhanak voun/US-0008727 - [Hypercare] - MC "Task Cancelled" cancels Campaign Members but not Tasks
@                07/12/2021/vadhanak voun/US-0010953 - Bugs found from regression test o US-0009714
@                                        / added Campaign.Ardira_Survey__c to the filter
*********************************************************************************************************************************/

global without sharing class BatchCreateTaskForSubCampaign implements Database.Batchable<SObject>, Schedulable,Database.Stateful {

    private static String subCampaignRT = ApexUtil.getRecordTypeByName('Campaign', EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE).Id;
    private static String GCXOutReachCampChannel = EBH_ConstantsUtility.CAMPAIGN_CHANNEL_GCX_OUTREACH;
    private static String statuc_mc_cancelled = EBH_ConstantsUtility.CM_MC_STATUS_CANCELLED;
    
    //NK:US-0008727: moved from constant and included the missing conition (cancelled)
    private static String SOQL_SUBCAMPAIGN = 'SELECT Marketing_Cloud_Status__c,EBH_ResponseCode__c,PriorityOrder__c, Campaign.Ardira_Survey__c,Campaign.Survey_ID__c,Campaign_Related_Seller_Details__c,CampaignId, ContactId FROM CampaignMember WHERE Campaign.RecordTypeId =: subCampaignRT AND Campaign.EBH_Channel__c =: GCXOutReachCampChannel AND (Campaign.Survey_ID__c != null OR Campaign.Ardira_Survey__c !=null) AND (Campaign.EndDate > TODAY OR Campaign.EndDate = null) AND Marketing_Cloud_Status__c <>:statuc_mc_cancelled ';

    public final static String SOQL_TASKINCAMPAIGN = 'SELECT Campaign_related_Seller_Details__c, Order_Priority__c, WhatId, WhoId FROM Task WHERE WhatId IN: sCampaginId';
    //NK:09/03/2020: store all processed Campaign for Task ReAssignment on finish
    Set<Id> setCampaignId = new Set<Id>();
    
    public BatchCreateTaskForSubCampaign() {}

    global Database.querylocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(SOQL_SUBCAMPAIGN);
    }
    
    global void execute(Database.BatchableContext bc, List<CampaignMember> scope) {
        try{
            List<Task> lstTaskInsert = new List<Task>();
            List<Task> lstTaskUpdate = new List<Task>();
            Map<Id,  Map<Id, Task>> mTaskCampCont = new Map<Id,  Map<Id, Task>>();

            Set<Id> sCampaginId = new Set<Id>();
            for(CampaignMember campMem : scope) {
                sCampaginId.add(campMem.CampaignId);
            }
			
			setCampaignId.addAll(sCampaginId);
			
            // Get all Task that already created in Campagins
            for(Task sTask : Database.query(EBH_ConstantsUtility.SOQL_TASKINCAMPAIGN)) {
                if(mTaskCampCont.containsKey(sTask.WhatId)) {
                    mTaskCampCont.get(sTask.WhatId).put(sTask.WhoId, sTask);
                }else{
                    mTaskCampCont.put(sTask.WhatId, new Map<Id, Task>{sTask.WhoId => sTask});
                }
            }
            for(CampaignMember campMem : scope) {
                // If no task ever created with CampaignId then CREATE
                // If task ever created with CampaignId then Check CampaignMember.ContactId in all Task.ContactId then if no contain then CREATE
                if(!mTaskCampCont.containsKey(campMem.CampaignId) || 
                    (mTaskCampCont.containsKey(campMem.CampaignId) && !mTaskCampCont.get(campMem.CampaignId).containsKey(campMem.ContactId))) {
                    Task sTask = new Task();
                    sTask.Subject = 'GCX Outreach call task';
                    // 'Phone Outreach'
                    sTask.Type = EBH_ConstantsUtility.GCX_TASK_TYPE;
                    // Customer(Contact)
                    sTask.WhoId = campMem.ContactId;
                    // RelatedTo
                    sTask.WhatId = campMem.CampaignId;
                    sTask.Status = 'Open';
                  //sTask.Campaign_related_Seller_Details__c = campMem.Campaign_Related_Seller_Details__c; //NK:29/11/2019: US-0000802 
                    sTask.Campaign_related_Seller_Details__c = (campMem.Campaign_Related_Seller_Details__c==null?'':campMem.Campaign_Related_Seller_Details__c.left(255)); //caping the maximum size of the field in task                
                    sTask.EBH_CampaignMemberId__c = campMem.Id;
                    sTask.Survey_ID__c = campMem.Campaign.Ardira_Survey__c == null? campMem.Campaign.Survey_ID__c : campMem.Campaign.Ardira_Survey__c;//NK:07/12/2021:US-0010953

                    // US-0007006
                    sTask.Order_Priority__c = campMem.PriorityOrder__c;

                    lstTaskInsert.add(sTask);
                }
                // US-0007006
                else if(mTaskCampCont.containsKey(campMem.CampaignId) && mTaskCampCont.get(campMem.CampaignId).containsKey(campMem.ContactId)){
                    Task sTask = mTaskCampCont.get(campMem.CampaignId).get(campMem.ContactId);
                    String taskSlrDetail = String.isBlank(sTask.Campaign_related_Seller_Details__c) ? '' : sTask.Campaign_related_Seller_Details__c;
                    String campMemSlrDetail = String.isBlank(campMem.Campaign_related_Seller_Details__c) ? '' : campMem.Campaign_related_Seller_Details__c.left(255);
                    
                    if(sTask.Order_Priority__c != campMem.PriorityOrder__c || taskSlrDetail != campMemSlrDetail){
                        //
                        sTask.Order_Priority__c = sTask.Order_Priority__c != campMem.PriorityOrder__c ? campMem.PriorityOrder__c : sTask.Order_Priority__c;
                        sTask.Campaign_related_Seller_Details__c = taskSlrDetail != campMemSlrDetail ? campMemSlrDetail : taskSlrDetail;
                        sTask.MCStatus__c = 'Updated';
                        lstTaskUpdate.add(sTask);
                    }
                }
            }
            
            if(!lstTaskInsert.isEmpty()) {
                insert lstTaskInsert;
            }
            if(!lstTaskUpdate.isEmpty()){
                update lstTaskUpdate;
            }
        }catch(Exception e){
            EBH_ApexLogger.logError(new List<Exception> { e }, 'BatchCreateTaskForSubCampaign', 'execute');
        }
    }
	
    global void finish(Database.BatchableContext bc) {
        if(!setCampaignId.isEmpty())
        {
        	Batch_ReAssignTask b = new Batch_ReAssignTask(setCampaignId);
        	Database.executeBatch(b);
        }
        
    }

    global void execute(SchedulableContext ctx) {
        // US-0008879 Acmatac SEING, [Hypercare Bug] Too many query rows in BatchCreateTaskForSubCampaign
        // Set batch size to 50
        Database.executeBatch(new BatchCreateTaskForSubCampaign(), 50);
    }

}