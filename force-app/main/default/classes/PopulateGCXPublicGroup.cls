/*********************************************************************************************************************************
@ Class:        PopulateGCXPublicGroup
@ Version:      1.0
@ Author:       David Herrero
@ Purpose:      functionality to add GCX Super Users to GCX Super User public group
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.01.2019/ David Herrero / Created the class.
				
*********************************************************************************************************************************/

global without sharing class PopulateGCXPublicGroup implements Database.Batchable<SObject>,Schedulable 
{	
	
	@TestVisible private String soql = null;
	
	
	@TestVisible private Integer batchSize = 10;
	public PopulateGCXPublicGroup(){}
    global Database.querylocator start(Database.BatchableContext bc)
    {
    	return Database.getQueryLocator(Test.isRunningTest()?soql:EBH_ConstantsUtility.SOQL_GCX_FILL_GROUP);
    }
    
    global void execute(Database.BatchableContext bc,List<PermissionSetAssignment> scope)
    {
    	System.debug('Scope = '+ scope);
        Id groupId=Database.query(EBH_ConstantsUtility.SOQL_GET_GCX_PUBLIC_GROUP).id;
        if (groupId!=null){
        	set<id>CurrentAssignationsToGCXGroup = new set <id>();
        	for (GroupMember gm : Database.query(EBH_ConstantsUtility.SOQL_GET_CURRENT_GROUP_ASSIGNATIONS)){
        	CurrentAssignationsToGCXGroup.add(gm.UserOrGroupId);
        	}
        	
        	List<GroupMember> gmToInsert = new List<GroupMember>();
        	for (PermissionSetAssignment psa : scope){
        	if (!CurrentAssignationsToGCXGroup.contains(psa.AssigneeId)){
        		gmToInsert.add(new GroupMember(groupId=groupID,UserOrGroupId=psa.AssigneeID));
        	}
        	
        	}
        
        if (!gmToInsert.isEmpty()){
        	insert gmToInsert;
        }
        }
        
    }
    global void finish(Database.BatchableContext bc)
    {
    	//checks that all members of Group GCX have the Permission set Assignment
    Map<id,GroupMember> SetOfUsersIdInGCXUserGroup= new Map<id,GroupMember>();
    List<GroupMember> GroupMembersToRemove = new List<GroupMember>();
    
  	for (GroupMember gm : Database.query(EBH_ConstantsUtility.SOQL_GET_CURRENT_GROUP_ASSIGNATIONS)){
        	SetOfUsersIdInGCXUserGroup.put(gm.UserOrGroupId,gm);
        	}
	set<id> listOfUsersWithPermissionSet = new set<id>();
	for (PermissionsetAssignment psa : Database.query(EBH_ConstantsUtility.SOQL_GCX_FILL_GROUP))        	{
	listOfUsersWithPermissionSet.add(psa.AssigneeId);
	
	}
	for (ID userid : SetOfUsersIdInGCXUserGroup.keyset()){
	if (!listOfUsersWithPermissionSet.contains(userId)){
		GroupMembersToRemove.add(SetOfUsersIdInGCXUserGroup.get(userid));
	
	}
	}
        	
      if(!GroupMembersToRemove.IsEmpty()){
      	delete GroupMembersToRemove;
      }  	
        	
    }
    //for scheduler
    global void execute(SchedulableContext ctx){
    	PopulateGCXPublicGroup batchPermissionSet = new PopulateGCXPublicGroup();
    	Database.executeBatch(batchPermissionSet,batchSize);
    }
    
       }