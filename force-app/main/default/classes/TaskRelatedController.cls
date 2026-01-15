/*********************************************************************************************************************************
@ Class:          TaskRelatedController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Shared Controller for LC: TaskRelated
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.02.2019 / Sovantheany Dim / Created the class.
@ Change history: 29.Apr.2022 / Chetra Sarom (chetra.sarom@gaea-sys.com) :US-0011530 - related tasks not visible
@ Change history: 09.06.2022 / Sophal Noch :US-0011788 - The unfixed Bug of US-0011530 - related tasks not visible
*********************************************************************************************************************************/
public without sharing class TaskRelatedController {
    private final static String SOQL_TASK1 = 'select EBH_Account__r.Linked_Acc_Group_Id__c,Campaign_Priority__c, Campaign_Group__c, Action_Committed__c, Action_Outcome__c, Action_Outcome_Date__c, Description, Subject, WhatId,What.Name,What.Type, WhoId,Who.Name,OwnerId,Owner.Name,Order_Priority__c,Task_Completed_Date__c, EBH_fResponseCode__c, EBH_Response__c, Call_Back_Comments__c From Task';
	private final static String SOQL_CONTACT = 'select Account.Linked_Acc_Group_Id__c, id,AccountId,Account.Name,Phone,Account.EBH_OracleID__c, Account.ParentId,Account.Parent.Name,Email, EBH_MailingStreet__c, EBH_MailingPostalCode__c,EBH_MailingCountry__c,EBH_MailingCity__c,EBH_MailingAddress__c from Contact';
    /***********************************************************************************************************************************
    @ Method:       getTasks 
    @ Version:      1.0
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      In a new section "Related Tasks" I see all related Tasks (definition of the related tasks below):
    @ Two Tasks are related if at least one fields below in two Tasks is the same and not NULL:
    @
    @ Contact. Business Name
    @ Contact. Primary Email
    @ Contact. Phone
    @ Seller. Oracle ID
    @ Seller. Parent Legal Entity
    @ Seller. Address
    @ Parameter:    parentId: TaskObjectId
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List of Related Tasks
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.02.2019 / Sovantheany Dim / Created the Method.
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getOpenTasks(String parentId)
    {
    	return getTasks(parentId,false);
    }
    
    /***********************************************************************************************************************************
    @ Method:       getCompletedTasks 
    @ Version:      1.0
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      EPH-7879 "Open Related Tasks” and "Completed Related Tasks" tab in Task Detail Page
    Create another Tab called "Completed Related Tasks" which will show all Completed Task which are related to the same Account and will show the
	below columns. This Tab is a clone of existing "Task Related" tab with only difference is that this will show up all completed related Tasks ONLY and no
	Open related Tasks with below columns in the list.
	Subject,Campaign Name,Business Name, Assigned To, Priority Order,Response,Response Code,Task Completed Date,Comments,Contact,
	Parent Legal Entity,Phone Number,Primary Email
    @ Parameter:    parentId: TaskObjectId
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List of Related Tasks
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.08.2019 / Sovantheany Dim / Created the Method.
    				23/04/2021 / sovantheany dim / update the method : US-0009318 - [Linked Acc]Display related Tasks with Linked B2C Seller
					09/06/2022 / Sophal Noch / update the method : US-0011788 - The unfixed Bug of US-0011530 - related tasks not visible
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getCompletedTasks(String parentId)
    {
    	return getTasks(parentId,true);
    }
    
    private static Map<String,Object> getTasks(String parentId,Boolean isCompletedTask)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
    	mapResult.put('isOK',true);
		try{
			Boolean isAdmin = (Userinfo.getprofileId()==EBH_ConstantsUtility.ADMIN_PROFILE_ID);
			Boolean isStandard = (Userinfo.getprofileId()==EBH_ConstantsUtility.PROFILE_ID_STANDARD);
			Boolean isGCX = (Userinfo.getprofileId()==EBH_ConstantsUtility.PROFILE_GCX_PARTNER_ID);
			Boolean isMSOUser = ApexUtil.checkPermissionSet(new Set<String>{EBH_ConstantsUtility.PERMISSION_SET_MSO});
			mapResult.put('isMSO',false);
			if(isAdmin || isStandard || isMSOUser || isGCX) mapResult.put('isMSO',true);
			Id sellerRecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id;
			String contacttype = Schema.SObjectType.Contact.getKeyPrefix();
			Task t = [Select t.WhoId, EBH_Account__r.Linked_Acc_Group_Id__c,EBH_Account__c From Task t where id =: parentId];
			//TH:US-0009318 - [Linked Acc]Display related Tasks with Linked B2C Seller  : 23/04/2021
			String groupId = t.EBH_Account__c != null ? t.EBH_Account__r.Linked_Acc_Group_Id__c : '';
			
			String contactId = '';
			if(t.WhoId != null && String.valueOf(t.WhoId).startsWith(contacttype)) contactId = t.WhoId;
			/*if(String.isBlank(contactId)){
				mapResult.put('showButton',false);
				mapResult.put('isOK',false);
				return mapResult;
			}*/
			List<Contact> listcon = [select AccountId, Account.Linked_Acc_Group_Id__c, Account.EBH_OracleID__c, Account.ParentId, Account.RecordTypeId,
			Account.BillingStreet,Account.BillingState,Account.BillingPostalCode,Account.BillingCountry,Account.BillingCity,Email,Phone from Contact where id =: contactId];
			/*if(listcon.isEmpty() || listcon[0].Account.RecordTypeId != sellerRecordTypeId){
				mapResult.put('showButton',false);
				mapResult.put('isOK',false);
				return mapResult;
			}*/
			//  29.Apr.2022 / Chetra Sarom (chetra.sarom@gaea-sys.com) :US-0011530 - related tasks not visible
			// Map<Id, Contact> mlstContact = new Map<Id, Contact>();
			Set<Id> setContId = new Set<Id>();
			// end US-0011530
			if(!listcon.isEmpty() && listcon[0].Account.RecordTypeId == sellerRecordTypeId){
				Contact c = listcon[0];
			
				String businessName = c.AccountId;
				String primaryEmail = c.Email;
				String phone = c.Phone;
				String oracleId = c.Account.EBH_OracleID__c;
				String parentLegalEntity = c.Account.ParentId;
				String billingStreet = c.Account.BillingStreet;
				String billingState = c.Account.BillingState;
				String billingPostalCode = c.Account.BillingPostalCode;
				String billingCountry = c.Account.BillingCountry;
				String billingCity = c.Account.BillingCity;
				
				String campaignPrefix = Campaign.sobjecttype.getDescribe().getKeyPrefix();
				/*Map<String, Contact> mlstContact = new Map<String, Contact>([select id,AccountId,Account.Name,Phone,Account.EBH_OracleID__c, Account.ParentId,Account.Parent.Name,Email,
				EBH_MailingStreet__c, EBH_MailingPostalCode__c,EBH_MailingCountry__c,EBH_MailingCity__c,EBH_MailingAddress__c from Contact 
				where (Email != null AND Email =: primaryEmail) OR (Phone != null AND Phone =: phone) OR 
				(AccountId != null AND Account.RecordTypeId =: sellerRecordTypeId AND (AccountId =: businessName OR (Account.ParentId != null AND Account.ParentId =: parentLegalEntity) OR 
				(Account.EBH_OracleID__c != null AND Account.EBH_OracleID__c =: oracleId)
				OR ((Account.BillingStreet != null OR Account.BillingState != null OR Account.BillingPostalCode != null OR Account.BillingCountry != null OR Account.BillingCity != null) 
				AND Account.BillingStreet =: billingStreet AND Account.BillingState =: billingState AND Account.BillingPostalCode =: billingPostalCode AND Account.BillingCountry =: billingCountry
				AND Account.BillingCity =: billingCity)))]);*/
				
				String whereContact = ' where (Email != null AND Email =: primaryEmail)';
				whereContact += ' OR (Phone != null AND Phone =: phone)';

				// 09.06.2022 / Sophal Noch / US-0011788 : disable query where use Contact.Account in conditions because it requires a lot of executed time.
				// whereContact += ' OR (AccountId != null AND Account.RecordTypeId =: sellerRecordTypeId AND (AccountId =: businessName OR (Account.ParentId != null AND Account.ParentId =: parentLegalEntity)' 
				// +' OR (Account.EBH_OracleID__c != null AND Account.EBH_OracleID__c =: oracleId)';
				// whereContact += ' OR ((Account.BillingStreet != null OR Account.BillingState != null OR Account.BillingPostalCode != null OR Account.BillingCountry != null OR Account.BillingCity != null)' 
				// +' AND Account.BillingStreet =: billingStreet AND Account.BillingState =: billingState AND Account.BillingPostalCode =: billingPostalCode AND Account.BillingCountry =: billingCountry'
				// +' AND Account.BillingCity =: billingCity)))';

				// 09.06.2022 / Sophal Noch / US-0011788 : query Account to get accountids first then use them in Contact Query. It is faster permformance than using Contact.Account in conditions.
				String whereAcc = ' Where (RecordTypeId =: sellerRecordTypeId AND (Id =: businessName OR (ParentId != null AND ParentId =: parentLegalEntity)' 
				+' OR (EBH_OracleID__c != null AND EBH_OracleID__c =: oracleId)';
				whereAcc += ' OR ((BillingStreet != null OR BillingState != null OR BillingPostalCode != null OR BillingCountry != null OR BillingCity != null)' 
				+' AND BillingStreet =: billingStreet AND BillingState =: billingState AND BillingPostalCode =: billingPostalCode AND BillingCountry =: billingCountry'
				+' AND BillingCity =: billingCity)))';
				Set<Id> setAccId = new Set<Id>();
				for(Account acc : Database.query('Select Id from Account' + whereAcc)){
					setAccId.add(acc.Id);
				}
				if(!setAccId.isEmpty()) whereContact += ' OR (AccountId IN : setAccId)';

				
				//  29.Apr.2022 / Chetra Sarom (chetra.sarom@gaea-sys.com) :US-0011530 - related tasks not visible
				
				// for(Contact cont : Database.query(SOQL_CONTACT + whereContact)){
				// 	mlstContact.put(cont.Id,cont);
				// }
				
				// mlstContact = new Map<Id, Contact> ((List<Contact>) Database.query(SOQL_CONTACT + whereContact));
				for(Contact cont : Database.query('Select Id From Contact ' + whereContact)){ // 09.06.2022 / Sophal Noch / US-0011788
					// mlstContact.put(cont.Id,cont);
					setContId.add(cont.Id);
				}
				// end US-0011530
			}
			
			// if(mlstContact.isEmpty() && String.isBlank(groupId)){
			if(setContId.isEmpty() && String.isBlank(groupId)){
				mapResult.put('showButton',false);
				mapResult.put('isOK',false);
				return mapResult;
			}
			
			//  29.Apr.2022 / Chetra Sarom (chetra.sarom@gaea-sys.com) :US-0011530 - related tasks not visible
			String wherecls = ' Where CreatedDate = LAST_N_DAYS:90 AND id != \''+parentId+'\'';
			wherecls += ' AND ( ';
			// if(!mlstContact.isEmpty()) wherecls += ' WhoId IN (\''+String.join(new List<Id>(mlstContact.keySet()),'\',\'')+'\') ';
			if(!setContId.isEmpty()) wherecls += ' WhoId IN (\''+String.join(new List<Id>(setContId),'\',\'')+'\') ';
			// end US-0011530
			// if(!mlstContact.isEmpty() && !String.isBlank(groupId)) wherecls += ' OR ';
			if(!setContId.isEmpty() && !String.isBlank(groupId)) wherecls += ' OR ';
			if(!String.isBlank(groupId)) wherecls += ' (EBH_Account__r.Linked_Acc_Group_Id__c != null AND EBH_Account__r.Linked_Acc_Group_Id__c =\''+groupId+'\')';
			wherecls += ')';
			/*if(!String.isBlank(groupId)) wherecls += '(';
			if(!mlstContact.isEmpty()) wherecls += 'WhoId IN (\''+String.join(new List<String>(mlstContact.keySet()),'\',\'')+'\')';
			//TH:US-0009318 - [Linked Acc]Display related Tasks with Linked B2C Seller  : 23/04/2021 : TH US-0009551 :fix bug
			if(!String.isBlank(groupId) && !mlstContact.isEmpty()) wherecls += ' OR ';
			if(!String.isBlank(groupId)) wherecls += '(EBH_Account__r.Linked_Acc_Group_Id__c != null AND EBH_Account__r.Linked_Acc_Group_Id__c =\''+groupId+'\'))';
			//End US-0009551*/
			if(isCompletedTask) {
				wherecls += ' AND Status = \'Completed\' ';
			}else{
				wherecls += ' AND Status NOT IN (\'Completed\',\'Closed\') ';
			}
			
			if(!isCompletedTask){
				Boolean isAdmingUser = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
				Boolean isGCXSuperUser =   EBH_CampaignTriggerHandler.checkGCXSuperUser();
				if(isAdmingUser || isGCXSuperUser){
					mapResult.put('showButton',true);
				}else{
					mapResult.put('showButton',false);
				}
			}
			mapResult.put('sitePrefix',Site.getPathPrefix());
			mapResult.put('baseSOQL',SOQL_TASK1);
			mapResult.put('wherecls',wherecls);
		}catch(Exception e){
			mapResult.put('isOK',false);
			mapResult.put('error',e.getMessage());
		}
    	return mapResult;
    }
    /**
     * TH Comment code out: 31/Jul/2020 : US-0007968 : Issue:" Open related Tasks" and "Completed related Tasks" Not loading most of the time- the team are seeing the hanging screen
    private static Map<String,Object> getTasks1(String parentId,Boolean isCompletedTask)
    
    {
		
    	Map<String,Object> mapResult = new Map<String,Object>();
    	
    	Boolean isAdmin = (Userinfo.getprofileId()==EBH_ConstantsUtility.ADMIN_PROFILE_ID);
    	Boolean isStandard = (Userinfo.getprofileId()==EBH_ConstantsUtility.PROFILE_ID_STANDARD);
    	Boolean isGCX = (Userinfo.getprofileId()==EBH_ConstantsUtility.PROFILE_GCX_PARTNER_ID);
    	Boolean isMSOUser = ApexUtil.checkPermissionSet(new Set<String>{EBH_ConstantsUtility.PERMISSION_SET_MSO});
    	mapResult.put('isMSO',false);
    	if(isAdmin || isStandard || isMSOUser || isGCX) mapResult.put('isMSO',true);
    	
    	Id sellerRecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id;
    	String contacttype = Schema.SObjectType.Contact.getKeyPrefix();
    	String contactId = '';
    	Task t = [Select t.WhoId From Task t where id =: parentId];
    	if(t.WhoId != null && String.valueOf(t.WhoId).startsWith(contacttype)) contactId = t.WhoId;
    	
    	List<Contact> listcon = [select AccountId, Account.EBH_OracleID__c, Account.ParentId, Account.RecordTypeId,
    	Account.BillingStreet,Account.BillingState,Account.BillingPostalCode,Account.BillingCountry,Account.BillingCity,Email,Phone from Contact where id =: contactId];

    	if(listcon.isEmpty() || listcon[0].Account.RecordTypeId != sellerRecordTypeId){
    		mapResult.put('showButton',false);
    		mapResult.put('listItemData',new List<ItemData>());
    		return mapResult;
    	}
    	
    	Contact c = listcon[0];
    	
    	String businessName = c.AccountId;
    	String primaryEmail = c.Email;
    	String phone = c.Phone;
    	String oracleId = c.Account.EBH_OracleID__c;
    	String parentLegalEntity = c.Account.ParentId;
    	String billingStreet = c.Account.BillingStreet;
    	String billingState = c.Account.BillingState;
    	String billingPostalCode = c.Account.BillingPostalCode;
    	String billingCountry = c.Account.BillingCountry;
    	String billingCity = c.Account.BillingCity;
    	
    	String campaignPrefix = Campaign.sobjecttype.getDescribe().getKeyPrefix();
    	Map<ID, Contact> mlstContact = new Map<ID, Contact>([select id,AccountId,Account.Name,Phone,Account.EBH_OracleID__c, Account.ParentId,Account.Parent.Name,Email,
    	EBH_MailingStreet__c, EBH_MailingPostalCode__c,EBH_MailingCountry__c,EBH_MailingCity__c,EBH_MailingAddress__c from Contact 
    	where (Email != null AND Email =: primaryEmail) OR (Phone != null AND Phone =: phone) OR 
    	(AccountId != null AND Account.RecordTypeId =: sellerRecordTypeId AND (AccountId =: businessName OR (Account.ParentId != null AND Account.ParentId =: parentLegalEntity) OR 
    	(Account.EBH_OracleID__c != null AND Account.EBH_OracleID__c =: oracleId)
    	OR ((Account.BillingStreet != null OR Account.BillingState != null OR Account.BillingPostalCode != null OR Account.BillingCountry != null OR Account.BillingCity != null) 
    	AND Account.BillingStreet =: billingStreet AND Account.BillingState =: billingState AND Account.BillingPostalCode =: billingPostalCode AND Account.BillingCountry =: billingCountry
    	AND Account.BillingCity =: billingCity)))]);
    	List<ItemData> listItemData = new List<ItemData>();
    	Set<Id> sContact = mlstContact.keySet();
    	String wherecls = ' Where WhoId IN: sContact and id !=: parentId';
    	String taskCompleted = EBH_ConstantsUtility.TASK_STATUS_COMPLETED;
    	Set<String> sCloseTask = new Set<String>{EBH_ConstantsUtility.TASK_STATUS_COMPLETED,EBH_ConstantsUtility.STATUS_CLOSED};
    	if(isCompletedTask) {
    		wherecls += ' and Status =: taskCompleted';
    	}else{
    		wherecls += ' and Status NOT IN: sCloseTask';
    	}
    		
    	for(Task task : Database.query(EBH_ConstantsUtility.SOQL_TASK1 + wherecls)){
    		Contact con = mlstContact.get(task.WhoId);
    		ItemData taskData = new ItemData();
    		taskData.taskSubject = task.Subject;
    		taskData.assignedTo = task.Owner.Name;
    		taskData.assignedToID = task.OwnerId;
    		taskData.priorityOrder = task.Order_Priority__c;
    		taskData.taskId = task.Id;
    		taskData.contact = task.Who.Name;
    		taskData.contactID = task.WhoId;
    		taskData.businessName = con.Account.Name;
    		taskData.businessNameID = con.AccountId;
    		taskData.parentLegalEntity = con.Account.Parent.Name;
    		taskData.parentLegalEntityID = con.Account.ParentId;
    		taskData.phoneNumber = con.Phone;
    		taskData.primaryEmail = con.Email;
    		taskData.response = ApexUtil.checkNull(task.EBH_Response__c)+'';
    		taskData.responseCode = ApexUtil.checkNull(task.EBH_fResponseCode__c)+'';
    		taskData.comments = ApexUtil.checkNull(task.Description)+'';
    		taskData.taskCompletedDate = task.Task_Completed_Date__c == null?'':task.Task_Completed_Date__c.format();
    		taskData.actionCommitted = ApexUtil.checkNull(task.Action_Committed__c)+'';
    		taskData.actionOutcome = ApexUtil.checkNull(task.Action_Outcome__c)+'';
    		taskData.actionOutcomeDate = task.Action_Outcome_Date__c == null ? '' : task.Action_Outcome_Date__c.format();
    		
    		taskData.campaignPriority = task.Campaign_Priority__c;
    		taskData.campaignGroup = task.Campaign_Group__c;
    		if(task.WhatId != null && String.valueOf(task.WhatId).startsWith(campaignPrefix)){
    			taskData.campaignName = task.What.Name;
    			taskData.campaignID = task.WhatId;
    		}
    		listItemData.add(taskData);
    	}
    	
    	if(!isCompletedTask){
    		Boolean isAdmingUser = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
	    	Boolean isGCXSuperUser =   EBH_CampaignTriggerHandler.checkGCXSuperUser();
	    	if(isAdmingUser || isGCXSuperUser){
	    		mapResult.put('showButton',true);
	    	}else{
	    		mapResult.put('showButton',false);
	    	}
    	}
    	
    	mapResult.put('listItemData',listItemData);
    	mapResult.put('sitePrefix',Site.getPathPrefix());
    	return mapResult;
    }*/
    
    /***********************************************************************************************************************************
    @ Method:       reAssignTask 
    @ Version:      1.0
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      EPH-7029 Reassign Tasks
    @ When I am on the "Linked Tasks" section in the task view
    @ I can select Tasks (Multiple-picklist) and click on the button: "Re-assign Tasks"
	@ Then reassign task to new user
    @ Parameter:    userID: user to assign
    @				taskIds : list selected task to updated
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns  Map<String,String> status ok or ko
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.02.2019 / Sovantheany Dim / Created the Method.
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> reAssignTask(String userID, List<String> taskIds){
    	Map<String,String> mapResult = new Map<String,String>();
    	try
    	{
	    	List<Task> lstTasks = new List<Task>();
	    	for(Task task : [select OwnerId from Task where id IN: taskIds]){
	    		task.OwnerId = userID;
	    		lstTasks.add(task);
	    	}
	    	if(!lstTasks.isEmpty()) update lstTasks;
	    	mapResult.put('status','ok');
    	}catch(DMLException dex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}
    	catch(Exception ex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
    	}
    	return mapResult;
    }
    
     /***********************************************************************************************************************************
    @ Method:       queryRelatedFields 
    @ Version:      1.0
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:    	US-0007968 - [AU] Hypercare bug- Open related tasks not opening on tasks
    @ Parameter:    String whoIds
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns  Map<String,String> status ok or ko
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 03.08.2020 / Sovantheany Dim / Created the Method.
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> queryRelatedFields(String whoIds){
    	Map<String,Object> mapResult = new Map<String,Object>();
    	Type idArrType = Type.forName('List<string>');
    	List<string> listWhoIds = (List<string>) JSON.deserialize(whoIds, idArrType);
    	String wherecls = ' where id IN: listWhoIds';
    	//Map<ID, Contact> mlstContact = new Map<ID, Contact>((List<Contact>)Database.query(SOQL_CONTACT + wherecls));
    	List<Contact> lstContact = Database.query(SOQL_CONTACT + wherecls);
    	mapResult.put('lstContact',lstContact);
    	return mapResult;
    }
}