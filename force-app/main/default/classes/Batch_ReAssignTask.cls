/*********************************************************************************************************************************
@ Class:         Batch_ReAssignTask
@ Version:       1.0
@ Author:        Vahanak Voun (vahanak.voun@gaea-sys.com)
@ Purpose:       US-0007189 [Sub Campaigns] Auto Task Assignment for Marketing Sub Campaigns
@					Similar to ReAssignTaskController to allow mass operation
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.03.2020 / Vahanak Voun (vahanak.voun@gaea-sys.com) / Created the class.
@				: 11.11.2020/ vadhanak voun/  US-0008647 - [Hypercare] - GCX Campaigns - Sub campaign tasks are not auto assigned via trigger
*********************************************************************************************************************************/
global without sharing class Batch_ReAssignTask implements Database.Batchable<SObject>,Database.Stateful{	
	private String subCampaignRT = ApexUtil.getRecordTypeByName('Campaign', EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE).Id;
	private String statusOpen = 'Open';
    private String GCXOutReachCampChannel = EBH_ConstantsUtility.CAMPAIGN_CHANNEL_GCX_OUTREACH;
    
    @TestVisible 
	private String sWhereTask = ' Where WhatId IN:setCampaign And Status =:statusOpen AND (Call_attempts__c=0 OR Call_attempts__c=null) AND EBH_ResponseCode__c =10 Order By WhatId ASC, Order_Priority__c ASC NULLS LAST';
	
	//track the index of the agent last assigned to the previouse scope; then continue on current scope
    Map<String,Integer> mapAgentIndexTracker = new Map<String,Integer>();
    Set<Id> setCampaign;
    
    //campaigns that just processed by : BatchCreateTaskForSubCampaign
    public Batch_ReAssignTask(Set<Id> setCampaign)
    {
    	this.setCampaign = setCampaign;
    }	
    		 
	global Database.querylocator start(Database.BatchableContext bc) 
	{
        return Database.getQueryLocator(EBH_ConstantsUtility.SOQL_TASK+sWhereTask);
    }
    
    global void execute(Database.BatchableContext bc, List<Task> scope) 
    {
    	Set<String> setThisCampIds = new Set<String>();
    	for(Task t: scope)
    	{
    		setThisCampIds.add(t.WhatId);
    	}
    	String sWhereCapm  = ' Where Id IN:setThisCampIds AND Active_GCX_User_Count__c > 0 ';
    	Map<Id,Campaign> mapCampaign = new Map<Id,Campaign>((List<Campaign>)Database.query(EBH_ConstantsUtility.CMRC_QUERY2+sWhereCapm));
    	
    	//contains campaign id => Map<Integer,GCX_User__c>
    	Map<String,GCX_User__c[]> mapAgentsByCampaign = new Map<String,GCX_User__c[]>();
    	
    	//Map<Integer,GCX_User__c> mapAgents = new Map<Integer,GCX_User__c>();
    	String sWhereGCX = ' Where Campaign_Name__c IN:setThisCampIds And Active__c=True AND User_Name__c <> NULL ORDER BY NAME ASC';
    	 
		for(GCX_User__c agent: Database.query(EBH_ConstantsUtility.SOQL_GCX_USER+sWhereGCX))
		{
			if(!mapAgentsByCampaign.containsKey(agent.Campaign_Name__c))
			{
				mapAgentsByCampaign.put(agent.Campaign_Name__c,new List<GCX_User__c>{agent}); //first campaign
				 
			}else {
				
				((GCX_User__c[])mapAgentsByCampaign.get(agent.Campaign_Name__c)).add(agent); //same campaign
			}
			 
		}
    	//System.debug('>>mapAgentsByCampaign: '+mapAgentsByCampaign);		
    	List<Task> listTaskToUpdate = new List<Task>();
    	Integer uIndex;
    	for(Task t: scope)
    	{
    		//has gcx user and correct channel
    		//do nonthing when no agent attached!!!!!
    		 if((!mapCampaign.containsKey(t.WhatId)) || (mapCampaign.containsKey(t.WhatId) && mapCampaign.get(t.WhatId).EBH_Channel__c <> EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL))
    		 {
    		 	continue;
    		 }
    		 //get the last index , if still tasks fro same previous campaign
			 uIndex = mapAgentIndexTracker.containsKey(t.WhatId)?mapAgentIndexTracker.get(t.WhatId):0;	//start from first agent if new campign			 
			 //System.debug('>>uIndex: '+uIndex);
			 //available agents for this campaign
    		 List<GCX_User__c> listAgents = (List<GCX_User__c>)mapAgentsByCampaign.get(t.WhatId);
			 t.OwnerId = listAgents[uIndex].User_Name__c;			 
			 //go to next agent or start from first agent
			 uIndex =  uIndex < (listAgents.size()-1) ? (uIndex+1) : 0;
			 mapAgentIndexTracker.put(t.WhatId,uIndex); //keep track for the last index
			 listTaskToUpdate.add(t);
    	}
    	
    	if(!listTaskToUpdate.isEmpty())
    	{
    		update listTaskToUpdate;
    	}
    }
    
    global void finish(Database.BatchableContext bc) 
    {
       
    }
}