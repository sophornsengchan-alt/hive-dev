/*********************************************************************************************************************************
@ Class:         BatchCreateUpdateTask
@ Version:       1.0
@ Author:        vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       US-0007221 Hypercare - Create Tasks functionality causes APEX CPU Timeout
@					Moved from AssignTasksController.createUpdateTasks()
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.02.2020 / vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the class.
@				: 09.11.2020 / vadhanak voun (vadhanak.voun@gaea-sys.com) / US-0008651 - Email result for "Create Task" for campaign outreach always show 0 result
@																		 / added the missing counter
@				: 17.06.2021/ vadhanak voun (vadhanak.voun@gaea-sys.com) / US-0009690 - [PL Adv] Assignment for PL Outreach Campaigns based on Outreach Manager
@				: 20.07.2021/ Sophal Noch (sophal.noch@gaea-sys.com) / US-0009938 - Refresh Tasks is assigning some of the tasks to AM on GCX Outreach Campaign
@				: 08/03/2022/ vadhanak voun/ US-0008153 - Outreach tasks Trigger Deletion if Campaign Members response code 10 or 40
@ 				: 20.05.2022/ Sophal Noch / US-0011717 - Enable new column "Campaign Related Seller Details" in the Target List to create/update Key metrics in campaign members
@				: 09/06/2022/  Sophal Noch / US-0011923 - Revert code from US-0008153 to resolve the issue on Task deletion in campaign outreach
@				: 15/05/2023/  Sophal Noch / US-0013593 - Task is not deleted when "Refresh Tasks" for a Cancelled Campaign Member
@				: 14.05.2024 / Sophal Noch / US-0015242 - Fix Account Owner Updating to Integration User Issue
@				: 28.04.2025 / Sophal Noch / US-0017154 - Replace OwnerId with Account_Manager__c for CohortSeller, Account, Campaign Related classes
*********************************************************************************************************************************/
global without sharing class BatchCreateUpdateTask implements Database.Batchable<SObject>,Database.Stateful{	
	/************************************* CONSTANT DEFINITION *************************************************/
    private static final Id DEPLOYMENT_USER_ID = '0056A000000yx6iQAA';
	private static final Id INTEGRATION_USER_ID2 = '0056A000000yVozQAE';
	static final String SOQL_TASK = 'Select Follow_Up_Task__c,EBH_ResponseCode__c,Campaign_related_Seller_Details__c, OwnerId,Owner.Name,Survey_ID__c,IsClosed,Id,EBH_CampaignMemberId__c,WhatId,WhoId,Status,Order_Priority__c,EBH_Response__c,Call_attempts__c From Task ';
	final static String SOQL_CAMP_TARGET_SELLERLIST = 'Select CreatedDate,Id,Campaign__c,Campaign__r.EBH_MemberLastRefreshDate__c,Seller_List__c From Campaign_Targeting__c';
	final static String CMRC_QUERY  = 'SELECT OwnerId,EndDate,Campaign_Type__c,EBH_TaskCreated__c,Survey_ID__c,EBH_ChannelMP__c,EBH_Channel__c,toLabel(EBH_Channel__c)lbl_EBH_Channel,Journey_ID__c,Journey_Status__c,Journey_Version__c,Id, EBH_SellerList__c, EBH_ControlGroupSize__c, RecordType.DEveloperName, Status, Parent.Status FROM Campaign WHERE Id = :campaignId';
	final static String CAMP_CHANNEL_AM_OUTREACH = 'AM Outreach';
	final static String CAMP_CHANNEL_GCX_PHONE_OUTREACH = 'GCX Outreach (Phone)'; // 20.07.2021 / Sophal Noch / US-0009938
	// static final String CTH_TARGETEDSELLERQUERY = 'SELECT Id,Priority__c, EBH_Seller__c, EBH_SellerList__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c WHERE EBH_SellerList__c in: sellerMapId ';  
	static final String CTH_TARGETEDSELLERQUERY = 'SELECT Id,Priority__c, EBH_Seller__c, EBH_SellerList__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c WHERE EBH_SellerList__c in: sellerMapId Order By Id desc';  // 20.05.2022 / Sophal Noch / US-0011717 : using "order by id desc" to make sure latest target seller is on top of the list
	
	// 28.04.2025 / Sophal Noch / US-0017154 : replace Contact.Account.OwnerId with Contact.Account.Account_Manager__c in below query
	static final String SOQL_CAM_MEMBER = 'Select Campaign_Related_Seller_Details__c, Contact.Account.Account_Manager__c,Contact.Account.Outreach_Manager__c,Contact.EBH_DoNotContact__c,Contact.Incorrect_Phone_Number__c,Campaign.RecordTypeId,Campaign.EBH_Channel__c,Campaign.Campaign_Type__c,Campaign.EBH_Site__c ,Id,Contact.EBH_PhoneOptOut__c,Contact.Primary_Contact__c,LeadId,Campaign.EBH_MemberLastRefreshDate__c,contact.Name,contact.firstname,contact.lastname,lead.name,campaign.ownerId,Campaign.Triggered_Send_Name__c,CampaignId,Campaign.ParentId,Campaign.Parent.RecordType.DeveloperName,Campaign.RecordType.DeveloperName, ContactId, campaign.survey_id__c,Contact.AccountId, EBH_ResponseCode__c,EBH_LastResponseDate__c,EBH_FirstResponseDate__c From CampaignMember';
	
	final static String TASK_STATUS_CANCELLED = 'Cancelled';
	static final String AOC_TASKSTATUS = 'Open';
	// final static String INTEGRATION_USER_ID = '0056A000000zaxM';
	private final static Id INTEGRATION_USER_ID = (Id)ApexUtil.INTEGRATION_USER_ID; // 14.05.2024 / Sophal Noch / US-0015242 : use int user from apex apex util
	final static String GCX_TASK_CALL_TYPE='Outbound';
	final static String GCX_TASK_TYPE='Phone Outreach';

	 // 14.05.2024 / Sophal Noch / US-0015242 :
	// private final static Id DEACTIVATION_USER_ID = (Id)(Label.Cohort_Deactivation_UserId); // 28.04.2025 / Sophal Noch / US-0017154 : no longer need
	private final static Set<Id> SET_INT_USER_ID = new Set<Id>{INTEGRATION_USER_ID}; // 28.04.2025 / Sophal Noch / US-0017154 : remove DEACTIVATION_USER_ID from Set
	private final static Set<Id> SET_ALL_INT_USER_ID = new Set<Id>{INTEGRATION_USER_ID, INTEGRATION_USER_ID2, DEPLOYMENT_USER_ID}; // 28.04.2025 / Sophal Noch / US-0017154 : remove DEACTIVATION_USER_ID from Set

	final static Set<String> SET_SITES_GCX_PHONE_OUTREACH = new Set<String>{'UK','DE','FR','IT','ES','EEC'}; // 20.07.2021 / Sophal Noch / US-0009938
	final static Set<String> CHANNEL_OUTREACH = new Set<String>{'AM Outreach','GCX Outreach (Phone)'};
    /************************************ END OF CONSTANT DEFINITION*******************************************/
	private Integer countTaskCreate = 0;
	private Integer countTaskUpdate = 0;
	private Integer countTaskDelete = 0;
	
	private Integer countAcManager = 0;
	private Integer countIntUser = 0;
	
	private String campaignId;
	private String sWhere = ' Where CampaignId =:campaignId';
	private Campaign cRecord;
	private boolean isOutReach = false;
	private String outReachChLabel; // 20.07.2021 / Sophal Noch / US-0009938
	
	private Map<String,String> mapLastError;
	
    //String filterId = cRecord.EBH_SellerList__c; use multi-sellerList instead
    private Map<String,EBH_TargetedSeller__c> mapTargetSeller;   
        
	public BatchCreateUpdateTask(String campaignId)
	{
		this.campaignId = campaignId;
		init();
	} 
	
	private void init()
	{
		this.cRecord = Database.query(CMRC_QUERY);
		this.isOutReach = cRecord.recordType.DeveloperName =='EBH_AMOutreach' && CHANNEL_OUTREACH.contains(cRecord.EBH_Channel__c);
		this.outReachChLabel = (String)cRecord.get('lbl_EBH_Channel'); // 20.07.2021 / Sophal Noch / US-0009938 use label of picklist value to display in email template

		mapLastError = new Map<String,String>();
		mapTargetSeller = new Map<String,EBH_TargetedSeller__c>();
		
		Set<String> sellerMapId = new Set<String>();
	    Set<String> campaignIds = new Set<String>{campaignId};
	    // for(Campaign_Targeting__c ct : Database.query(SOQL_CAMP_TARGET_SELLERLIST + ' Where Campaign__c IN: campaignIds'))
		// 20.05.2022 / Sophal Noch / US-0011717 : make sure latest campaign targeting run in loop first
		for(Campaign_Targeting__c ct : Database.query(SOQL_CAMP_TARGET_SELLERLIST + ' Where Campaign__c IN: campaignIds Order By Id desc'))
	    {
	    	sellerMapId.add(ct.Seller_List__c);
	    }
    	
    	for(EBH_TargetedSeller__c ts: Database.query(CTH_TARGETEDSELLERQUERY))
	    {
	    	// mapTargetSeller.put(ts.EBH_Seller__c,ts);
			if(!mapTargetSeller.containsKey(ts.EBH_Seller__c)) mapTargetSeller.put(ts.EBH_Seller__c,ts); // 20.05.2022 / Sophal Noch / US-0011717 : so latest targetedSeller is not overwritten by the old one
	    }
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(SOQL_CAM_MEMBER + sWhere);
    }	
		
	global void execute(Database.BatchableContext pBc, List<SObject> scope){
		
    	try
    	{
	    	//1. Update all Campaign Members with existing response code < 20 or empty to response code = 22
			//Map<String,CampaignMember> mapCM_existing = new Map<String,CampaignMember>();
	    	Map<String,CampaignMember> mapCM_existingById = new Map<String,CampaignMember>();
		
	    	for(CampaignMember cm: (List<CampaignMember>)scope)
	    	{
        		mapCM_existingById.put(cm.Id,cm);
	    	}
	    	
	    	//Tasks Changes
		 	//	1. For Campaign Members with Response code = 22 & call attempts > 0: Tasks status changed to "Cancelled"
		 	//	2. For Campaign Members with Response code =22 & call attempts =0: delete Task
		 	//	3. For Campaign Members with Response code =10, check if tasks exists, then not -> create New Tasks
		 	Map<Id,Task> mapTaskToUpdate = new Map<Id,Task>(); // avoid duplicate for multi-update
		 	List<Task> listTaskNew = new List<Task>();
		 	List<Task> listTaskDelete = new List<Task>();
		 	List<CampaignMember> listCMCount = new List<CampaignMember>();
		 	Set<String> setCM_id = mapCM_existingById.keySet();
	    	Map<String,List<Task>> mapCM_tasks = new Map<String,List<Task>>();
            
	    	//mapping list of tasks into CM
	    	for(Task t: Database.query(SOQL_TASK+' Where EBH_CampaignMemberId__c IN :setCM_id '))
	    	{
                //system.debug('>>t: '+t);
	    		if(!mapCM_tasks.containsKey(t.EBH_CampaignMemberId__c))
	    		{
	    			mapCM_tasks.put(t.EBH_CampaignMemberId__c,new List<Task>());
	    		}
	    		mapCM_tasks.get(t.EBH_CampaignMemberId__c).add(t);
	    	}
	    	for(String cmId: setCM_id)
	    	{
	    		CampaignMember cm = mapCM_existingById.get(cmId);
				//system.debug('>>>>>cm: '+cm);
				//system.debug('>>>>>cm: '+cm.EndDate);
	    		List<Task> listTasks = mapCM_tasks.get(cmId);
	    		if(listTasks <> null)
	    		{
	    			for(Task t: listTasks) //possible many tasks to single CM?!
		    		{
		    			//system.debug('>>>cm.EBH_ResponseCode__c: '+cm.EBH_ResponseCode__c+'   >>t.Call_attempts__c: '+t.Call_attempts__c);
		    			//	1. For Campaign Members with Response code = 22 & call attempts > 0: Tasks status changed to "Cancelled"
		    			if(cm.EBH_ResponseCode__c==22 && t.Call_attempts__c>0)
			    		 {
			    		 	//t.Status = EBH_ConstantsUtility.TASK_STATUS_CANCELLED;
			    		 	//use set for Asyn: listTaskUpdate.add(t);
			    		 	t.Status = TASK_STATUS_CANCELLED;
			    		 	t.EBH_ResponseCode__c=22;
			    		 	mapTaskToUpdate.put(t.Id,t);
			    		 }
			    		 //	2. For Campaign Members with Response code =22 & call attempts =0: delete Task
						 //NK:08/03/2022:US-0008153:check if the (related Task to Campaign Member is not a follow up task and Task.EBH_ResponseCode__c = 10 or 40 )then
						//delete the related Tasks related to the Campaign Members instead of updating Task Status to "Cancelled".
			    		//  else if((cm.Campaign_Related_Seller_Details__c && cm.EBH_ResponseCode__c==22 && (t.Call_attempts__c==0 || t.Call_attempts__c==null ))
						//  	|| (!t.Follow_Up_Task__c && t.EBH_ResponseCode__c <> null && (t.EBH_ResponseCode__c ==10 || t.EBH_ResponseCode__c ==40))
						//  	)
			    		//  {
			    		//  	listTaskDelete.add(t);
			    		//  }
						// 20.05.2022 / Sophal Noch / US-0011717 do not delete task when Campaign_Related_Seller_Details__c is not empty
						// else if((String.isBlank(t.Campaign_Related_Seller_Details__c) && cm.EBH_ResponseCode__c==22 && (t.Call_attempts__c==0 || t.Call_attempts__c==null ))
						// 09.06.2022 / Sophal Noch /US-0011923 :
						// || (String.isBlank(t.Campaign_Related_Seller_Details__c) && !t.Follow_Up_Task__c && t.EBH_ResponseCode__c <> null && (t.EBH_ResponseCode__c ==10 || t.EBH_ResponseCode__c ==40))
						// 15.05.2023 / Sophal Noch / US-0013593 :
						else if((String.isBlank(t.Campaign_Related_Seller_Details__c) || !mapTargetSeller.containsKey(cm.Contact.AccountId)) && cm.EBH_ResponseCode__c==22 && (t.Call_attempts__c==0 || t.Call_attempts__c==null ))
						{
							listTaskDelete.add(t);
						} 
						 
		    		}
	    		}
	    		 
	    		//	3. For Campaign Members with Response code =10, check if tasks exists, then not -> create New Tasks
	    		//NK: 15/03/2019: EPH-7143 Update priority when adding/deleting new campaign members
	 			//		For Campaign Members with Response code =10, CHECK if tasks exists:
	 		    //        a) if exists and task status is "Open" OR "Closed" -->keep existing tasks, update priority: Task.Priority Order = Seller List. Priority
	 		    //        b) if exists and task status is "Cancelled" --> reopen the task, keep original Call Attempts count, update priority: Task.Priority Order = Seller List. Priority
	 		    //        c) if NOT exist --> open new Tasks
	    		if(cm.EBH_ResponseCode__c==10 && (listTasks == null ||(listTasks <> null && listTasks.isEmpty())) 
	    			//&& !cm.Contact.EBH_DoNotContact__c && !cm.Contact.Incorrect_Phone_Number__c) //NK: EPH-7356:13/05/2019
	    				&& !cm.Contact.EBH_DoNotContact__c && !cm.Contact.Incorrect_Phone_Number__c && (!cm.Contact.EBH_PhoneOptOut__c || cm.Campaign.Campaign_Type__c=='Admin' )) //DHE: EPH-7460
	    		{
	    			//system.debug('>>>>>ContactId: '+cm.ContactId+' >> Name: '+cm.Contact.Name);
					//Task t = doCreateTask(cm);

					// Task t = doCreateTask(cm.ContactId+'',cm.Contact.Name,cm.Id+'',campaignId+'',getTaskOwner(cm),cRecord.survey_id__c,(mapTargetSeller.containsKey(cm.Contact.AccountId)?mapTargetSeller.get(cm.Contact.AccountId).Priority__c:null));
					Task t = doCreateTask(cm, campaignId+'',getTaskOwner(cm),cRecord.survey_id__c,(mapTargetSeller.containsKey(cm.Contact.AccountId)?mapTargetSeller.get(cm.Contact.AccountId).Priority__c:null)); // 20.05.2022 / Sophal Noch / US-0011717
	    			listTaskNew.add(t);
	    			listCMCount.add(cm);
	    			
	    		}else if(listTasks <> null && !listTasks.isEmpty())
	    		{
	    			for(Task t: listTasks)  
		    		{
		    			//b) if exists and task status is "Cancelled" --> reopen the task, keep original Call Attempts count, update priority: Task.Priority Order = Seller List. Priority
		    			if(t.Status == TASK_STATUS_CANCELLED && !mapTaskToUpdate.containsKey(t.Id)) //not from Cancelled above!
		    			{
		    				t.Status =  AOC_TASKSTATUS; //Open
		    				t.Order_Priority__c = mapTargetSeller.containsKey(cm.Contact.AccountId)?mapTargetSeller.get(cm.Contact.AccountId).Priority__c:t.Order_Priority__c;
		    				t.Campaign_related_Seller_Details__c = cm.Campaign_related_Seller_Details__c != null ? cm.Campaign_related_Seller_Details__c.left(255) : ''; // 20.05.2022 / Sophal Noch / US-0011717
							mapTaskToUpdate.put(t.Id,t);
		    			}
		    			//a) if exists and task status is "Open" OR "Closed" -->keep existing tasks, update priority: Task.Priority Order = Seller List. Priority
		    			else if ((t.Status == AOC_TASKSTATUS || t.IsClosed) && mapTargetSeller.containsKey(cm.Contact.AccountId))//NK:21/03/2019: fixed null pointer, when seller removed
		    			{
		    				t.Order_Priority__c = mapTargetSeller.get(cm.Contact.AccountId).Priority__c;
		    				t.Campaign_related_Seller_Details__c = cm.Campaign_related_Seller_Details__c != null ? cm.Campaign_related_Seller_Details__c.left(255) : ''; // 20.05.2022 / Sophal Noch / US-0011717

		    				//NK: US-0009352 24.09.2019: US-0009352: it should update existing "open" tasks with the Campaign Survey Id field.
		    				if(t.Status == AOC_TASKSTATUS && t.Survey_ID__c <> cRecord.survey_id__c)
			    			{
			    				t.Survey_ID__c = cRecord.survey_id__c;
			    			}
		    				
		    				mapTaskToUpdate.put(t.Id,t);
		    			}
		    		}
	    		}
	    	}
	    	 
	    	//NK:02/07/2019: EPH-7731
	    	if(isOutReach)
	    	{
    			for(CampaignMember cm: listCMCount)
    			{
    				// if((cm.Contact.Account.OwnerId+'').subString(0,15)==INTEGRATION_USER_ID)
					// if(SET_INT_USER_ID.contains(cm.Contact.Account.OwnerId))  // 14.05.2024 / Sophal Noch / US-0015242 
					if(String.isBlank(cm.Contact.Account.Account_Manager__c) || SET_INT_USER_ID.contains(cm.Contact.Account.Account_Manager__c)) // 28.04.2025 / Sophal Noch / US-0017154 use account manager field to count integration user
			    	{
			    		countIntUser++;
			    	}else
			    	{
			    		countAcManager++;
			    	}
    			}
	    	}
	    	//NK:US-0008651: added the missing counters
	    	if(!mapTaskToUpdate.isEmpty())
	    	{
	    		// update mapTaskToUpdate.values(); countTaskUpdate +=mapTaskToUpdate.size();
				ApexSafe.dml().secCheck(false).doUpdate(mapTaskToUpdate.values(),true); countTaskUpdate +=mapTaskToUpdate.size(); // 28.04.2025 / Sophal Noch / US-0017154 : use ApexSafe to update
				
	    	}
	    	
	    	if(!listTaskDelete.isEmpty())
	    	{
	    		// delete listTaskDelete; countTaskDelete +=listTaskDelete.size();
				ApexSafe.dml().secCheck(false).doDelete(listTaskDelete,true); countTaskDelete +=listTaskDelete.size(); // 28.04.2025 / Sophal Noch / US-0017154 : use ApexSafe to delete
				
	    	}
	    	if(!listTaskNew.isEmpty())
	    	{
	    		//NK:03/02/2020:US-0007153
	    		// insert listTaskNew; countTaskCreate +=listTaskNew.size();
				ApexSafe.dml().secCheck(false).doInsert(listTaskNew,true); countTaskCreate +=listTaskNew.size(); // 28.04.2025 / Sophal Noch / US-0017154 : use ApexSafe to insert
				
	   	 		
	   	 		if(!cRecord.EBH_TaskCreated__c)
	   	 		{
	   	 			cRecord.EBH_TaskCreated__c = true;
	    			// update cRecord;
					ApexSafe.dml().secCheck(false).doUpdate(new List<Campaign>{cRecord},true); // 28.04.2025 / Sophal Noch / US-0017154 : use ApexSafe to update
	   	 		} 
	    		
	    		//system.debug('>>>>>listTaskNew: '+listTaskNew);
	    	}
    		
    	}catch(Exception ex)
    	{
               system.debug(ex); mapLastError.put('err',ex.getMessage());
        }
       
	}
	
	// private Task doCreateTask(String contactId,String contactName,String cmemberId,String campaignId,String ownerId,String surveyId,Decimal priority)
	private Task doCreateTask(CampaignMember cmember, String campaignId,String ownerId,String surveyId,Decimal priority)
    {
        //updated by DHE adding task recordtype
		Task t = new Task( 
					CallType=GCX_TASK_CALL_TYPE,
					//Description=EBH_ConstantsUtility.GCX_Task_Description, 2019-08-05 Commented by DHE. We don't need to have the Comments field pre-populated
					Status='Open',
					//    EBH_CampaignMemberId__c=cmemberId, // 2018-09-18 Added by DHE
					EBH_CampaignMemberId__c=cmember.Id,
					Subject='GCX Outreach Call Task',
					//    WhoId= contactId,
					WhoId= cmember.ContactId,
					//t.Contact_Name__c=cm.ebh_contactfullname__c;
					//    Contact_Name__c=contactName,
					Contact_Name__c = cmember.Contact.Name,
					WhatId=campaignId,
					OwnerId=ownerId,
					Survey_ID__c=surveyId,
					Type=GCX_TASK_TYPE,
					//25.12.2018/ NK: EPH-6850
					Order_Priority__c = priority,
					RecordtypeId=ApexUtil.getRecordTypeByName('Task', 'Standard_Task').ID,
					//Campaign_related_Seller_Details__c =sellerDeatil //NK:27/11/2019: US-0000802 : BatchCreateTaskForSubCampaign
					//US-0007296 - "Due Date" to be auto populated in Task for AM Outreach
					ActivityDate=isOutReach?cRecord.EndDate:null,
					Campaign_related_Seller_Details__c = cmember.Campaign_related_Seller_Details__c // 20.05.2022 / Sophal Noch / US-0011717
		);
                 
         return t;
    }
    
    /*****************************************************************************************************************************
    @ Method:         getTaskOwner
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        EPH-7731 AM Outreach. Assign Tasks to Account Managers
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:        Campaign Member
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        User Id of for TaskOwner
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.07.2019 / Vadhanak Voun / Created the  Method.
	@							All Tasks are automatically assigned to Users who are managing these sellers.
	@							Task. Assigned to = Campaign Member.Customer. Owner If Customer.Owner= Deployment user (Integration User?!?) assign to the Task to Campaign.Owner
	@				: 17.06.2021/ vadhanak voun (vadhanak.voun@gaea-sys.com) / US-0009690 - [PL Adv] Assignment for PL Outreach Campaigns based on Outreach Manager
	@				: 14.05.2024 / Sophal Noch / US-0015242 - Fix Account Owner Updating to Integration User Issue
	@				: 28.04.2025 / Sophal Noch / US-0017154 - Replace OwnerId with Account_Manager__c for CohortSeller, Account, Campaign Related classes
    *****************************************************************************************************************************/    
	
	private String getTaskOwner(CampaignMember cm)
    {

		if(!isOutReach)
    	{
            //SM://08/07/2020 - US-0007767 - [AU]Assignment for AU Outreach Campaigns based on Outreach Manager
            if(cm.Contact.Account.Outreach_Manager__c != null && (cm.Campaign.EBH_Site__c=='AU' || cm.Campaign.EBH_Site__c=='US')){
                return cm.Contact.Account.Outreach_Manager__c;
            }else{
                return UserInfo.getUserId();//NK:/10/07/2019
            }
    		
    	}

		//for outreach
		if(
			// (cm.Contact.Account.OwnerId==INTEGRATION_USER_ID || cm.Contact.Account.OwnerId==INTEGRATION_USER_ID2 || cm.Contact.Account.OwnerId==DEPLOYMENT_USER_ID)
			// SET_ALL_INT_USER_ID.contains(cm.Contact.Account.OwnerId) // 14.05.2024 / Sophal Noch / US-0015242 
			(String.isBlank(cm.Contact.Account.Account_Manager__c) || SET_ALL_INT_USER_ID.contains(cm.Contact.Account.Account_Manager__c)) // 28.04.2025 / Sophal Noch / US-0017154 : use Accout_Manager__c field to check with integration user
			&& cm.Campaign.EBH_Channel__c == CAMP_CHANNEL_AM_OUTREACH // 20.07.2021 / Sophal Noch / US-0009938
		){
    		return cm.Campaign.ownerId;
		}
		else if(cm.Campaign.EBH_Channel__c == CAMP_CHANNEL_GCX_PHONE_OUTREACH && SET_SITES_GCX_PHONE_OUTREACH.contains(cm.Campaign.EBH_Site__c)){ // 20.07.2021 / Sophal Noch / US-0009938
			return cm.Campaign.ownerId;
		}
        //SM://08/07/2020 - US-0007767 - [AU]Assignment for AU Outreach Campaigns based on Outreach Manager
        else if(cm.Campaign.EBH_Site__c=='AU' || cm.Campaign.EBH_Site__c=='US'){
            if(cm.Contact.Account.Outreach_Manager__c != null){
                return cm.Contact.Account.Outreach_Manager__c;
            }else{
                return cm.Campaign.ownerId;
            }
        }
		else
    	{
    		// return cm.Contact.Account.OwnerId;
			return String.isNotBlank(cm.Contact.Account.Account_Manager__c) ? cm.Contact.Account.Account_Manager__c : INTEGRATION_USER_ID; // 28.04.2025 / Sophal Noch / US-0017154 : use Account_Manager__c field as the owner
    	}
    }
    private String mergeBody(String htmlBody)
    {
		String outReachSec = 'You are about to create Tasks for this '+outReachChLabel+'.<br/>' +
		'<ul><li><strong>'+countAcManager+ '</strong> of your tasks will be automatically assigned to sellers\'s corresponding Account Managers.</li>'+
		'<li><strong>'+countIntUser+ '</strong> of your tasks will be assigned to you as these sellers do not have an Account Manager.</li></ul>'+
		'You can still go to Tasks and manually reassign tasks to other users.';
		
		String foundError = mapLastError.isEmpty()?'':'Error during job:<br/>'+mapLastError.get('err');
		String hbody = htmlBody
					.replace('{!OutreachInfo}',isOutReach?outReachSec:'')
					.replace('{!Error}',foundError)
					.replace('{!taskUpdate}',countTaskUpdate+'')
					.replace('{!taskDelete}',countTaskDelete+'')
					.replace('{!taskCreate}',countTaskCreate+'')
					.replace('{!CurrentUser}',ApexUtil.getCurrentUser().Name)
					
					;
	
		return hbody;
    }
    	
	global void finish(Database.BatchableContext pBc)
	{
		EmailTemplate emailTmp = [select Id, Subject, HtmlValue, DeveloperName  from EmailTemplate where DeveloperName = 'CreateTaskResult'];
       
     	String emailBody = mergeBody(emailTmp.HtmlValue);
		
		ApexUtil.doSend(emailTmp.Subject,UserInfo.getUserEmail(),emailBody);
		
		// 02.03.2023/ Acmatac Seing / US-0013230
		update (new Campaign(Id = campaignId, Task_Creation_Running__c = false));

    	//1. Update all Campaign Members with existing response code < 20 or empty to response code = 22
		//2. Compare new Seller List with existing campaign members. If sellerlist.businessname exists in campmember.contact.account 
    	//-> if	campmember.response code = 22, then set it to 10; else skip
    	//3. Upload Campaign Members from new Target List, set Response code to 10
		//batch update existing members
    	if(!Test.isRunningTest())
    	{
    		EBH_InsertCampaignMemberBatch cmBatch = new EBH_InsertCampaignMemberBatch(new Set<Id>{campaignId});
			Database.executeBatch(cmBatch,200);
    	}
    }
}