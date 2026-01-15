/*********************************************************************************************************************************
@ Class:          ReAssignTaskController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Controller for Aura: Re_assign_Tasks
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.10.2019 / Vadhanak Voun / Created the class.
@				: 22.02.2023 / Chetra Sarom / US-0013230 - Task Creation in Outreach Campaigns gets duplicated when Users attempts to Click "Refresh Tasks" and "Reassign Tasks" Simultaneously
@				02.03.2023 / Acmatac Seing / US-0013230 
*********************************************************************************************************************************/
public without sharing class ReAssignTaskController {
	private final static Integer  RECORD_LIMIT_PER_TRANS = 200;
	private final static String ADMIN_PROFILE_ID = '00e6A000000HNzwQAG';
	private final static String CMRC_QUERY 
        = 'SELECT OwnerId,EndDate,Campaign_Type__c,EBH_TaskCreated__c,Survey_ID__c,EBH_ChannelMP__c,EBH_Channel__c,Journey_ID__c,Journey_Status__c,Journey_Version__c,Id, EBH_SellerList__c, EBH_ControlGroupSize__c, RecordType.DEveloperName, Status, Parent.Status,Task_Creation_Running__c FROM Campaign WHERE Id = :campaignId';
	private final static String SOQL_TASK = 'Select EBH_ResponseCode__c,Campaign_related_Seller_Details__c, OwnerId,Owner.Name,Survey_ID__c,IsClosed,Id,EBH_CampaignMemberId__c,WhatId,WhoId,Status,Order_Priority__c,EBH_Response__c,Call_attempts__c From Task ';
	private final static String SOQL_GCX_USER = 'Select Id,Name,Campaign_Name__c,User_Name__c,Active__c From GCX_User__c ';
	private final static String CAMP_RECORDTYPE_OUTREACH='EBH_AMOutreach';
	private final static String GCX_TASK_CALL_CHANNEL='GCX Outreach (Phone)';
	private final static String CAMP_STATUS_PAUSED = 'Campaign Paused';

	/*****************************************************************************************************************************
    @ Method:   apexReAssignTasks
    @ Version:  1.0
    @ Author: 	Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	US-0009683 (2)Automatic Task Assignment - "Assign Tasks"
    @			AC1: Add logic to the new button “Assign Tasks” to auto assign available GCX users based on Dynamic rule (Round Robin basis).  
	@			Given that I am a user with GCX Super User permission 
	@			When I navigate to an Campaign object, select an Outreach Campaign (with Outreach record type, Channel =GCX Outreach(Phone)),
	@			I should see a new button “Assign Tasks” "Re-assign Tasks" and I Click “Assign Tasks” "Re-assign Tasks"
	@			Then system will query all the “Tasks” with status = Open  Order by desc Priority and assign to the Agents related to the Campaign in a round robin method. 
	@			Dynamic Rule should assign the Priority 1 Tasks first followed by Priority nth tasks and other Tasks with No priority set, to all team mates in the related list “GCX Users”. 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     String campaign Id
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 23.10.2019 / Vadhanak Voun / Created the  Method
   	@				: 25.10.2019/ Vadhanak Voun/ US-0009666 (3)Automatic Task Assignment - Validation Rules
   	@				AC1: Error Message when no Agents available in GCX users and “Assign Task” button is Clicked 
	@					 Given that I am Any user with GCX Super User permission 
	@					When I navigate to an Campaign object, select an Outreach Campaign (with Outreach record type, Channel =GCX Outreach(Phone)), and Click “Assign Task” when there are no GCX Users allocated to the Campaign should throw the below error message.
	@					 “Please allocate GCX Users to this Campaign before assigning tasks to Agents".
	@				AC2: Error Message when trying to "Assign Task" when an Outreach Campaign has a status "Campaign Paused"
	@					 Given that I am Any user with GCX Super User permission 
	@					When I navigate to an Campaign object, select an Outreach Campaign (with Outreach record type, Channel =GCX Outreach(Phone)) 
	@					When I click “Assign Task” when Campaign status is "Campaign Paused" it should throw below error message.
	@					"Tasks cannot be assigned while the campaign is paused."
	@
	@			:24/01/2020: US-0000224 Automatic Task Assignment - Reassignment when Add/Remove New sellers to Campaign
	@				AC1: Add new Sellers to the Campaign and Click "Re-Assign Task"
	@					Given that I am GCX Team Lead with "GCX Super User Permission" 
	@					When I go to an Outreach Campaign(with Outreach record type, Channel =GCX Outreach(Phone)) and click "Re-Assign Task" after adding new sellers to the Campaign,
	@					Query ALL the Open Tasks with Priority 1 first (then P2,Pn) with Call Attempt = 0 and reassign to the available Active GCX users related to the Campaign in a round-robin fashion.
	@				AC2: Remove Sellers from section Campaign Targeting in an Campaign Outreach record
	@					Given that I am GCX Team with "GCX Super User Permission" 
	@					When I go to Outreach record and Delete Sellers from the Targeting Section ,press Refresh Members and Click "Re-Assign Task" .
	@					Then System to query all existing Open Tasks (P1 priority re assigned first) to the GCX users related to the Campaign in a round robin fashion.
	@				AC3 : Use case to test reassign when Agent is already started on existing Task with Call attempt >1 and 2 more sellers are added and 2 more users are added.
	@					Reassignment should consider all existing OPEN tasks with Call attempt = 0 for reassignment to Active Team Mates
	@			:06/03/2020: US-0007189 [Sub Campaigns] Auto Task Assignment for Marketing Sub Campaigns
	@			:15/02/2022 : Svoantheany Dim : US-0011133 - [Bug] re-assign task stop working
	@			02.03.2023 / Acmatac Seing / US-0013230 Task Creation in Outreach Campaigns gets duplicated when Users attempts to Click "Refresh Tasks" and "Reassign Tasks" Simultaneously
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexReAssignTasks(String parentId,List<String> listTaskIds,Integer index, Map<Integer,GCX_User__c> mapAgents2, Integer agentIndex)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
    	Boolean isAdmin = UserInfo.getProfileId().equals(ADMIN_PROFILE_ID);
    	Boolean isGCXSuperUser = ApexUtil.checkPermissionSet(new Set<String>{'GCX_Super_User'});
    	
    	if(isAdmin || isGCXSuperUser)
    	{
    		try
    		{
				if(listTaskIds.isEmpty()){
					String campaignId = parentId;
					Campaign camp = Database.query(CMRC_QUERY);
					//RecordType recCampOutReach = ApexUtil.getRecordTypeByName('Campaign','EBH_AMOutreach'); 
					String statusOpen = 'Open';
					String sWhereTask = ' Where WhatId=:parentId And Status =:statusOpen AND (Call_attempts__c=0 OR Call_attempts__c=null) Order By Order_Priority__c Desc NULLS LAST';
					String sWhereGCX = ' Where Campaign_Name__c=:parentId And Active__c=True AND User_Name__c <> NULL';
					
					List<Task> tasksAll = Database.query(SOQL_TASK+sWhereTask);
					
					Map<Integer,GCX_User__c> mapAgents = new Map<Integer,GCX_User__c>();
					Integer i = 0;
					//Set<String> setAgentIds = new Set<String>();
					for(GCX_User__c agent: Database.query(SOQL_GCX_USER+sWhereGCX))
					{
						mapAgents.put(++i,agent);
						//setAgentIds.add(agent.User_Name__c);
					}
					 
					//system.debug('>>>mapAgents: '+mapAgents);
					String msg = '';
					String status = 'ok';
					// 02.03.2023/ Acmatac Seing / US-0013230
					if(camp.Task_Creation_Running__c) {
						msg = System.Label.Task_Creation_is_in_progress;
						status = 'ko';
					}else if(camp.RecordType.DEveloperName <> CAMP_RECORDTYPE_OUTREACH || camp.EBH_Channel__c <> GCX_TASK_CALL_CHANNEL) //GCX Outreach (Phone)
					{
						msg = System.Label.Error_Invalid_OutReach_Channel;
						status = 'ko';
						 
					}else if(camp.Status == CAMP_STATUS_PAUSED)
					{
						msg = System.Label.Error_Campaign_Paused;
						status = 'ko';
					}else if(tasksAll.isEmpty())
					{
						msg = System.Label.Error_No_OpenTask_Assign;
						status = 'ko';
					}else if(mapAgents.isEmpty())
					{
						msg = System.Label.Error_No_GCX_User_available;
						status = 'ko';
					} 

					//TH:11/02/2022:US-0011133 
					List<String> listTaskId = new List<String>();
					for(Task t : tasksAll){
						listTaskId.add(t.Id);
					}
					Map<String,Object> mapChunkedTask = ApexUtil.chunkList(listTaskId,RECORD_LIMIT_PER_TRANS);
					

					mapResult.put('status',status);
					mapResult.put('message',msg);
					mapResult.put('mapAllChunk',mapChunkedTask);
					mapResult.put('mapAgents',mapAgents);
				}else{
					List<String> listError = new  List<String>();
					List<Task> listToSave = new List<Task>();
					Integer i = agentIndex;
					for(String taskId : listTaskIds)
					{
						listToSave.add(new Task(id = taskId, OwnerId = mapAgents2.get(i).User_Name__c));
						i =  i<mapAgents2.size()?++i:1;
					}
					Integer updatedCount = 0;
					Integer updatedFailCount = 0;
					if(!listToSave.isEmpty()){
						//update listToSave;
						Database.SaveResult[] srList = Database.update(listToSave, false);
						for (Database.SaveResult sr : srList) {
							if (sr.isSuccess()) {
								updatedCount ++ ;
							}else{
								updatedFailCount ++ ;
								listError.add(sr.getErrors()[0].getMessage());
							}
						}
					}
					index ++;
					mapResult.put('status','ok');
					mapResult.put('index', index);
					mapResult.put('updatedCount', updatedCount);
					mapResult.put('agentIndex', i);
					mapResult.put('listError', listError);
					mapResult.put('updatedFailCount', updatedFailCount);
				}
    		}catch(Exception ex){mapResult.put('status','ko');mapResult.put('message','Reassignment failed.\n'+ex.getMessage());}
    		
    	}else
    	{
    		mapResult.put('status','ko');
    		mapResult.put('message','Only GCX Super User allowed.');
    	}
    	
    	return mapResult;
	}
}