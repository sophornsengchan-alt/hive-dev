public with sharing class BatchAssignUsersToTrailheadModules implements Database.Batchable<SObject>, Schedulable {
  public String periodOfTime = '';
  public final String Query = 'select id,label,developername,active__c, My_Trailhead_Trailmix__c, My_Trailhead_Badge__c, Related_Permission_Set__c from Sailpoint_Public_Group_Permissions__mdt';
  public final String whereClause = ' where active__c=true';

  public static String QUERY_GROUP_MEMBERS = 'select Id, GroupId,Group.DeveloperName, UserOrGroupId from groupmember where group.DeveloperName in :groupNames and SystemModStamp >= {periodOfTime}';
  public static String QUERY_EXISTING_USERBADGES = 'select trailheadapp__External_ID__c from trailheadapp__User_Badge__c where trailheadapp__External_ID__c in :generatedKeys';
  public static final STring QUERY_PERMISSION_SET_IN_BADGES='select id,Permission_Set__c from trailheadapp__badge__c where Permission_Set__c !=null and id in :badgesIds';
  public static final STring QUERY_USERS_HAVING_PERMISSION_SET='select id,PermissionSetId,AssigneeId from PermissionSetAssignment where PermissionSetId in :permissionsSet and AssigneeId in :usersId';
  public static final STring QUERY_PERMISSIONSETS_NAMES_IDS = 'select id,name from PermissionSet where name in :permissionsSet';
  public final static String ASSIGNED = 'Assigned';

  public BatchAssignUsersToTrailheadModules(String periodOfTime) {
    this.periodOfTime = periodOfTime;
  }

  public BatchAssignUsersToTrailheadModules() {
    periodOfTime = 'LAST_WEEK';
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {

    return Database.getQueryLocator(Query + whereClause);
  }

  public void execute(Database.BatchableContext bc, List<Sailpoint_Public_Group_Permissions__mdt> scope) {
    List<String> groupNames = new List<String>();
    Map<String, Sailpoint_Public_Group_Permissions__mdt> mapGroupCMD = new Map<String, Sailpoint_Public_Group_Permissions__mdt>();
    if (Test.isRunningTest()) {
      trailheadapp__Badge__c badge = new trailheadapp__Badge__c();
      badge.name = 'BADGENAME';
      badge.trailheadapp__Description__c = 'trailheadapp__Badge__c';
      badge.trailheadapp__Icon__c = 'https://res.cloudinary.com/hy4kyit2a/f_auto,fl_lossy,q_70/learn/modules/heroku-certified-architecture-designer-maintenance-summer-20/8170db56d525f7f6a102d56cbf999dc2_badge.png';
      badge.trailheadapp__Namespace__c = 'learn';
      badge.trailheadapp__API_Name__c = 'BADGENAME';
      badge.trailheadapp__URL__c = 'https://hive.my.trailhead.com/content/hive/modules/na-testingbadge/';
      insert badge;

      scope = new List<Sailpoint_Public_Group_Permissions__mdt>{
        new Sailpoint_Public_Group_Permissions__mdt(
          active__c = true,
          developername = 'Testers',
          My_Trailhead_Badge__c = badge.id
        )
      };
    }
    System.debug('Scope = ' + scope);
    for (Sailpoint_Public_Group_Permissions__mdt i : scope) {
      groupNames.add(i.developername);
      mapGroupCMD.put(i.developername, i);
    }

    Map<String, trailheadapp__User_Badge__c> userBadgesToInsert = new Map<String, trailheadapp__User_Badge__c>();

    QUERY_GROUP_MEMBERS = QUERY_GROUP_MEMBERS.replace('{periodOfTime}', periodOfTime);

    set<Id> badgesIds= new set<Id>();
    set<id> usersId= new Set<Id>();
    for (GroupMember gm : Database.query(QUERY_GROUP_MEMBERS)) {
      String auxGroupName = gm.Group.DeveloperName;
      userBadgesToInsert.put(
        gm.UserOrGroupId + '-' + mapGroupCMD.get(auxGroupName).My_Trailhead_Badge__c,
        new trailheadapp__User_Badge__c(
          trailheadapp__User__c = gm.UserOrGroupId,
          trailheadapp__Badge__c = mapGroupCMD.get(auxGroupName).My_Trailhead_Badge__c,
          trailheadapp__Status__c = ASSIGNED,
          trailheadapp__Assigned_Date__c = System.now()
        )
      );
      
      badgesIds.add(mapGroupCMD.get(auxGroupName).My_Trailhead_Badge__c);
      usersId.add(gm.UserOrGroupId);
    }
    //check if the badge has any permission set assigned
    set<String> permissionsSet= new set<String>();
    Map<STring,String> mappermissionsetBadge = new Map<String,String>();
    Map<String,String> mapBadgePermission = new Map<String,String>();
   for (trailheadapp__Badge__c b  : Database.query(QUERY_PERMISSION_SET_IN_BADGES)){
    mappermissionsetBadge.put(b.id,b.Permission_Set__c);
    MapBadgePermission.put(b.Permission_Set__c,b.id);
   }
   permissionsSet.addAll(mappermissionsetBadge.values());
   Map<String,String> mapPermissionsetIdName = new Map<String,String>();
  
    for (PermissionSet ps : Database.query(QUERY_PERMISSIONSETS_NAMES_IDS)){
      mapPermissionsetIdName.put(ps.id,ps.name);
    }

    permissionsSet.addAll(mapPermissionsetIdName.keySet());
   //check if the user has already assigned the permission set
   for (PermissionSetAssignment psa : Database.query(QUERY_USERS_HAVING_PERMISSION_SET)){
    //String key = psa.AssigneeId + '-'+mapPermissionsetIdName.get(psa.PermissionSetId);
    String key = psa.AssigneeId + '-' + MapBadgePermission.get(mapPermissionsetIdName.get(psa.PermissionSetId));
    System.debug('Key = ' + key );
    if (userBadgesToInsert.containsKey(key)){ 
      userBadgesToInsert.remove(key);
    }


   }

    for (trailheadapp__User_Badge__c ub : userBadgesToInsert.values()) {
      if (userBadgesToInsert.containsKey(ub.trailheadapp__External_ID__c)) {
        userBadgesToInsert.remove(ub.trailheadapp__External_ID__c);
      }
    }
    
    List<String> generatedKeys = new List<String>();
    generatedKeys.addAll(userBadgesToInsert.keySet());

    for (trailheadapp__User_Badge__c ub : Database.query(QUERY_EXISTING_USERBADGES)) {
      if (userBadgesToInsert.containsKey(ub.trailheadapp__External_ID__c)) {
        userBadgesToInsert.remove(ub.trailheadapp__External_ID__c);
      }
    }

    if (!userBadgesToInsert.isEmpty()) {
      Database.insert(userBadgesToInsert.values(), false);
    }
  }

  public void finish(Database.BatchableContext bc) {
  }

  public void execute(SchedulableContext sc) {
    BatchAssignUsersToTrailheadModules batchSchedule = new BatchAssignUsersToTrailheadModules();
    Database.executeBatch(batchSchedule, 100);
  }
}