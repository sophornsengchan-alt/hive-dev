public without sharing class AssignCallTasksExt {
    
    /*****************************************************************************************************************************
@ Method:         handleButtonVisibility
@ Version:        1.0
@ Author:         Vadhanak Voun	
@ Purpose:        EPH-6009 Make Docu-Sign Button Visible to Only Those with Docu-Sign Access
@							  
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      none
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.06.2018 / Vadhanak Voun / Created the  Method.

*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> handleButtonVisibility()
    {
        String currentUserId = UserInfo.getUserId();
        Map<String,String> result = new  Map<String,String>();
        try{
            PermissionSetAssignment[]  pss = Database.query(EBH_ConstantsUtility.SOQL_GCX_TEAM_LEAD );
            result.put('visible',(pss.isEmpty()?'ko':'ok'));
        }catch(Exception e){
            result.put('error',e.getMessage() + ' ' + ebh_constantsUtility.SOQL_GCX_TEAM_LEAD);
        }
        
        
        
        return result;
    }
    
    
        
/*****************************************************************************************************************************
@ Method:         checkAndShareAttachments
@ Version:        1.0
@ Author:         Vadhanak Voun	
@ Purpose:        EPH-5370 -  
@							  
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      ContractId:      Id of contract to be checked and shared attachment
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.02.2018 / Vadhanak Voun / Created the  Method.
				   
*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> assignCallTasks(String campaignId)
    {
         Map<String,String> result = new  Map<String,String>();
        System.debug('Campaign Received = ' + campaignID);
        result.put('status','ok');
        //get all campaign members
        List<Task> listTask = new List<Task>();
        for(CampaignMember cm :[select LeadId, ContactId,campaign.ownerId, CampaignId from CampaignMember where campaignId=:campaignId]){
            Task t = new Task();
            t.CallType=EBH_ConstantsUtility.GCX_TASK_CALL_TYPE;
            t.Description=EBH_ConstantsUtility.GCX_Task_Description;
			t.Status='Open';
            t.Subject='GCX Outreach call task';
            t.WhoId=(cm.LeadId==null?cm.ContactId:cm.LeadId);
            t.EBH_CampaignMemberId__c=cm.Id;
            t.WhatId=cm.CampaignId;
            t.OwnerId=cm.campaign.ownerId;
            t.Type=ebh_ConstantsUtility.GCX_TASK_TYPE;
            listTask.add(t);
            
            
        }
        insert listtask;
        result.put('numOfTasks',''+listTask.size());
        
        return result;
    }

}