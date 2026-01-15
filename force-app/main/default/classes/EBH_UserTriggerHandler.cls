/*********************************************************************************************************************************
@ Class:          EBH_UserTriggerHandler
@ Version:        1.0
@ Author:         David Herrero
@ Purpose:        Handler Class for User Trigger

----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.06.2018 / David Herrero / Created the class.
                  19.05.2021 / David Herrero / Add ticket creation for Sox Audit purposes - US-0009567
                  31.03.2023 / Sophal Noch   / US-0013488 - Manage User created from link Account is not working properly
                  24.04.2023 / Sophal Noch / US-0013565 - eBay Registration Handler for Call booking site.
                  16.08.2023 / vadhanak voun/ US-0013999 - Tech Debt: fix hardcoded Id (part 1)
--------------------------------
@ Change history 21/09/2023 / Vimean Heng / US-0014173 - Deprecate method
@               : 23.01.2025 / Acmatac Seing / US-0016663 We dont need recountAccountTeam feature anymore
*********************************************************************************************************************************/
public without sharing class EBH_UserTriggerHandler {
    static List<String> permissionsToCheck= new List<String>{'DocuSign_User','DocuSign_Administrator'};
    public static Boolean byPassUserTrigger = false;
    public static final String SUPPORT_CASE_RT= ApexUtil.getRecordTypeByName('Case','Support_Ticket').Id;//'0123u0000019nkzAAA'; //NK:16/08/2023:US-0013999
    public static final String STATUS_CLOSED='Closed';
    public static final String QUERY_PROFILES='select id,name from Profile';
    public static final String QUERY_USERS='Select id,name from user where id in :setUsersId';
    public static final String OLD_VALUE='old';
    public static final string NEW_VALUE='new';
    public static Map<id,String> mapProfileIDName ;


        /*****************************************************************************************************************************
@ Method:         update Permission sets in user
@ Version:        1.0
@ Author:         David Herrero
@ Purpose:        Update field permission set in users
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Users:      Users from the trigger scope
UsersMap: Users old map from the trigger scope
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.06.2018 / David Herrero / Created the  Method.
*****************************************************************************************************************************/
        public static void UpdatePermissionSets(List<User> users, Map<Id, User> UsersMap) {
            
            Map<id,String> mapUserPermissionSet = new map<id,STring>();
            for (PermissionSetAssignment psa:[select id,permissionset.name,AssigneeId from permissionsetassignment where permissionset.name in : permissionsToCheck and assignee.id in :UsersMap.keyset()]){
                if (mapUserPermissionSet.containskey(psa.AssigneeId)){
                    mapUserPermissionSet.put(psa.AssigneeId,mapUserPermissionSet.get(psa.AssigneeId)+';' + psa.PermissionSet.name);
                }else{
                    mapUserPermissionSet.put(psa.AssigneeId, psa.PermissionSet.name);
                }
                
            }
            if (!mapUserPermissionSet.isEmpty()){
                if(!System.IsBatch()){
                    Futureperformchanges(mapUserPermissionSet);            
                }else{
                    performchanges(mapUserPermissionSet);            
                }
                
            }
            
        }    
    
    
    @future
    private static void Futureperformchanges( Map<id,String> mapUserPermissionSet){
        
        List<User>lusers=[select id,Permission_Sets__c from User where id in :mapuserPermissionSet.keyset()];
        
        for (User u :lusers){
            u.Permission_sets__c=mapUserPermissionSet.get(u.ID);
        }
        try{
            update lusers;    
        }catch(Exception e){
            System.debug('Exception updating user ' + e.getMessage());
        }
        
        
    }
    @TestVisible
    private static void performchanges( Map<id,String> mapUserPermissionSet){
        
        List<User>lusers=[select id,Permission_Sets__c from User where id in :mapuserPermissionSet.keyset()];
        
        for (User u :lusers){
            u.Permission_sets__c=mapUserPermissionSet.get(u.ID);
        }
        try{
            update lusers;    
        }catch(Exception e){
            System.debug('Exception updating user ' + e.getMessage());
        }
        
        
    }
    
    /*****************************************************************************************************************************
    @ Method:       deleteDaysForInactiveUsers
    @ Version:      1.0
    @ Author:       Vadhanak Voun
    @ Purpose:      EPH-6940 Triggers for new object: "Day"
    @				AC3:
	@				When a user gets deactivated who is a member of the Public Group: Marketing Execution Team all records in object Day for this user with Day > Today get deleted.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      trigger.new, trigger.oldMap  
    -----------------------------------------------------------------------------------------------------------------------------
    @ Event		: After Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.01.2019 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    public static void deleteDaysForInactiveUsers(List<User> listUserNew,Map<Id,User> mapOld)
    {
    	
    	Set<String> setUsers = new Set<String>();
    	for(User u: listUserNew)
    	{
    		if(u.isActive <> mapOld.get(u.Id).isActive && !u.isActive)
    		{
    			setUsers.add(u.Id);
    		}
    	}
    	 
    	if(!setUsers.isEmpty())
    	{
    		Set<String> setGoups = new Set<String>{EBH_ConstantsUtility.GROUP_MARKETING_EXC};
    		Set<String> setAllUsersInGroup = new Set<String>();
    		
    		for(GroupMember gm: Database.query(EBH_ConstantsUtility.SOQL_GROUP_MEMBER))
    		{
    			setAllUsersInGroup.add(gm.UserOrGroupId);
    		}
    		Set<String> setUsersToProcess = new Set<String>();
    		for(String uId : setUsers)
    		{
    			if(setAllUsersInGroup.contains(uId))
    			{
    				setUsersToProcess.add(uId);
    			}
    		}
    		 
    		if(!setUsersToProcess.isEmpty())
    		{
    			if(System.isBatch()){
    				EBH_UserTriggerHandler.doDeletedWhenBatch(setUsersToProcess);
    			}else{
    				doDeleteDaysAsyn(setUsersToProcess);
    			}
    		}
    	}
    }
	
	@TestVisible
    private static void doDeletedWhenBatch(Set<String> setUsersToProcess){
    
    	//TH: 21 jan 2020 : US-0000227
		List<Day__c> lstDayDelete = [Select Id from Day__c Where  User__c IN :setUsersToProcess AND Day__c > Today];
		User_DMLWorker deleteWorker = new User_DMLWorker(lstDayDelete,'deleteDaysForInactiveUsers',5); //no retry
		deleteWorker.doUpdate();
    }
    
	@future private static void doDeleteDaysAsyn(Set<String> setUsersToProcess)
    {
    	delete [Select Id from Day__c Where  User__c IN :setUsersToProcess AND Day__c > Today];
    }
    /*
    public static void preventUserCreationDelegatedAdmins (List<User> newList){        
        Map<id,Profile> mapProfiles = new Map<id,Profile>();
        for (Profile p : (List<Profile>) Database.query(EBH_ConstantsUtility.SOQL_ADMIN_PROFILES)){
            mapProfiles.put(p.id,p);
        }
        
        for (User u : newList){
            if (!mapProfiles.containsKey(UserInfo.getProfileId())){
                if (!Test.isRunningTest()){
                u.addError(Label.Error_Not_Allowed_to_ccreate_users );    
                }
                
            }
            
        }

    }
*/    
    //asyn job
    class User_DMLWorker extends DMLWorker{
    	
    	public User_DMLWorker(List<SObject> listSobject,String methodName,Integer numRetry)
    	{
    		super(listSobject,'EBH_UserTriggerHandler',methodName, 'delete');
    		retry_counter = numRetry;
    	}
    	
    	void setCounter()
		{
			retry_counter = retry_counter+1;
			 
		}
		
   	 	void doRetry()
   	 	{
   	 		Id jobID = System.enqueueJob(new User_DMLWorker(listSobject,methodName,retry_counter)); //retry
   	 	}  
    	
    }

    //Method that inserts a ticket in the system every time a user gets changed the profile
    //US-0009567
    //Vimean Heng : US-0014173
    /*
    public static void createTicketWhenChangeProfile(List<User> newList, Map<Id,User>oldMap){
      
        Map<id,Map<String,String>> mapUserProfileChanges = new Map<id,Map<String,String>>(); 
        if (mapProfileIDName==null || mapProfileIDName.isEmpty()){
            mapProfileIDName = new Map<id,String> ();
            for (Profile p : Database.query(QUERY_PROFILES)){
                mapProfileIDName.put(p.id,p.name);
            }
        }
        //check if any user has been changed
        for (User u : newList){
            if (u.profileid!=oldMap.get(u.id).ProfileId){
                mapUserProfileChanges.put(u.id,new map<String,String>{
                    OLD_VALUE=>mapProfileIDName.get(oldMap.get(u.id).profileid),
                    NEW_VALUE=>mapProfileIDName.get(u.profileid)
                });

            }
        }

        if (!mapUserProfileChanges.isEmpty()){
            createSupportTickets(Json.serialize(mapUserProfileChanges));
        }
    }

   
    @future
    public static void createSupportTickets(String parameter){
        Map<id,Map<String,String>> mapUserProfileChanges =( Map<id,Map<String,String>>) JSON.deserialize(parameter,Map<id,Map<String,String>>.class);
        set <id>setUsersId=mapUserProfileChanges.keySet();
        map<Id,String>mapUserIdName = new Map<id,string>();
        List<Case> SupportTicketsToCreate = new list<Case>();

        for (User u : Database.query(QUERY_USERS)){
            mapUserIdName.put(u.id,u.name);

       }
        // @AMT, US-0011331 - Move Hive Product as Picklist to Lookup
        List<HIVE_Products__c> lstHP = [SELECT Id FROM HIVE_Products__c WHERE Name = 'Hive' LIMIT 1];
        
        for (ID userid: mapUserProfileChanges.keySet()){
            Case c = new Case();
            c.recordtypeid=SUPPORT_CASE_RT;
            c.Subject=String.format(Label.Suport_Case_subject, new List<String>{mapUserIdName.get(userid)});
            c.Description=String.format(Label.Support_ticket_description,new List<String>{mapUserIdName.get(userid),mapUserProfileChanges.get(userid).get(OLD_VALUE),mapUserProfileChanges.get(userid).get(NEW_VALUE)});
            c.Description__c=c.Description;
            c.Status=STATUS_CLOSED;
            c.HIVE_Products__c=lstHP.isEmpty() ? null : lstHP.get(0).Id;
            c.Summary__c=c.Subject;
            c.OwnerId=UserInfo.getUserId();
            SupportTicketsToCreate.add(c);
        
        }

        if (!SupportTicketsToCreate.isEmpty()){
            insert SupportTicketsToCreate;
        }
    }
    */
    /*****************************************************************************************************************************
    @ Method:         checkAssignPermSetSEP
    @ Version:        1.0
    @ Author:         vadhanak voun
    @ Purpose:        US-0010870 - [SP] Just in Time Provisioning of Sellers (Deals, Monetization) - NA, DE
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Users:      Users from Flow: Userflow - Profile Mapping
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 03.02.2022 / vadhanak voun / Created the  Method.
    @               : 08.04.2022 / vadhanak voun / US-0010870: assign permisison group instead of PS
    @               : 02.06.2022 / Mony Nou      /  US-0011435 - Creation of seller communication records for coupons - AC2
    @               : 31.03.2023 / Sophal Noch   / US-0013488 - Manage User created from link Account is not working properly
    @               : 24.04.2023 / Sophal Noch / US-0013565 - eBay Registration Handler for Call booking site.
    *****************************************************************************************************************************/
    @InvocableMethod(label='checkAssignPermSetSEP' description='check assign permission set accordingly' category='User')
    public static void checkAssignPermSetSEP(List<User> listUserSEP)
    {
        Set<String> permset = new Set<String>();
        Set<String> setUserId = new Set<String>();
        Map<Id, Id> mContUserId = new Map<Id, Id>(); //MN-02062022-US-0011435

        for(User usr: listUserSEP)
        {
            if(String.isNotBlank(usr.Permission_Sets__c))
            {
                permset.addAll(usr.Permission_Sets__c.split(';'));
            }
                    
            setUserId.add(usr.Id);

            if (String.isNotBlank(usr.ContactId)) mContUserId.put(usr.ContactId, usr.Id); //MN-06062022-US-0011435

        }

        // if (!mContUserId.isEmpty()) async_UpdateCommunityUserInfor(JSON.serialize(mContUserId)); //MN-06062022-US-0011435
        if (!ManageUserController.IS_MANAGE_USER && !mContUserId.isEmpty()) async_UpdateCommunityUserInfor(JSON.serialize(mContUserId)); //MN-06062022-US-0011435, SP-310320230US-0013488 prevent future method to run when manage user is being created.
        
        permset.remove('');  // 24.04.2023 / Sophal Noch / US-0013565 : remove empty string after User.Permission_Sets__c valaue is convert to Set
        if(permset.isEmpty())return;

        Map<String,String> mapPermId = new Map<String,String>();
        for(PermissionSetGroup psg : [Select Id,DeveloperName From PermissionSetGroup Where DeveloperName IN: permset])
        {
            mapPermId.put(psg.DeveloperName,psg.Id);
        }

        // 24.04.2023 / Sophal Noch / US-0013565 : store permission set in Map String
        Map<String,String> mapPermSetId = new Map<String,String>();
        for(PermissionSet ps : [Select Id,Name From PermissionSet Where Name IN: permset AND PermissionSet.IsOwnedByProfile = FALSE])
        {
            mapPermSetId.put(ps.Name,ps.Id);
        }

        
        Map<String,PermissionSetAssignment> mapPermToAssign = new Map<String,PermissionSetAssignment>();
        for(User usr: listUserSEP)
        {
            if(String.isBlank(usr.Permission_Sets__c))continue;
            for(String psName :usr.Permission_Sets__c.split(';') )  //1 or 2 permission set from EbayRegistrationHandler
            {
                if(String.isBlank(psName)) continue; // 24.04.2023 / Sophal Noch / US-0013565 : skip empty string when User.Permission_Sets__c valaue is convert to Set
                // mapPermToAssign.put(usr.Id+'_'+psName,
                //     new PermissionSetAssignment(AssigneeId=usr.Id,PermissionSetGroupId=mapPermId.get(psName))
                // );
                if(mapPermId.containsKey(psName)){ // 24.04.2023 / Sophal Noch / US-0013565 : update Permission Set Group
                    mapPermToAssign.put(usr.Id+'_'+psName, new PermissionSetAssignment(AssigneeId=usr.Id,PermissionSetGroupId=mapPermId.get(psName)));
                }else if(mapPermSetId.containsKey(psName)){  // 24.04.2023 / Sophal Noch / US-0013565 : update Permission Set
                    mapPermToAssign.put(usr.Id+'_'+psName, new PermissionSetAssignment(AssigneeId=usr.Id,PermissionSetId=mapPermSetId.get(psName)));
                }        
            }
        }     

        if(!mapPermToAssign.isEmpty())
        {
            //delete all
            delete [Select Id From PermissionSetAssignment Where AssigneeId IN:setUserId AND PermissionSet.IsOwnedByProfile = FALSE];
            //and recreate the assignment
            insert mapPermToAssign.values();
        }

        
         
    }

    /*****************************************************************************************************************************
    @ Method:         async_UpdateCommunityUserInfor
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        US-0011435 - Creation of seller communication records for coupons - AC2
    @                   + Future method to update Contact to avoid MIXED DML error
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      jsonMapConUsr : String JSON Serialized of Map<Id,Id> key:ContactId => Value:UserId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.06.2022 / Mony Nou / Created the  Method.
    *****************************************************************************************************************************/
    @future
    public static void async_UpdateCommunityUserInfor(String jsonMapConUsr){ 

        if (String.isNotBlank(jsonMapConUsr)) {
            
            Map<Id, Id> mConUserId = (Map<Id,Id>) JSON.deserialize(jsonMapConUsr, Map<Id,Id>.class);
            
            if (!mConUserId.isEmpty()) {
                List<Contact> lstCon = new List<Contact>();
                for (Id conId : mConUserId.keySet()) {
                    lstCon.add(new Contact(
                        Id = conId,
                        Community_User__c = mConUserId.get(conId)
                    ));
                }

                update lstCon;
            
            }
        }
    }
}