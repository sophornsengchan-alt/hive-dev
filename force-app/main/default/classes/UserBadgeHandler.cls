/*********************************************************************************************************************************
@ Class:          UserBadgeHandler
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        Handler Class for UserBadgeHandler Trigger
@ Change history: 19.08.2021 / SRONG TIN / Created the class.
                : 13.03.2023 / Loumang SENG / US-0013125 - Fix Trigger User Badge
*********************************************************************************************************************************/
public with sharing class UserBadgeHandler {

    private static final String STATUS_COMPLETED = 'Completed';
    private static final String TYPE_MODULE = 'Module';
    private final static String SOQL_PERMISSIONSET_ASSIGNMENT = 'Select PermissionSet.Name, PermissionSetId, AssigneeId From PermissionSetAssignment ';

    /*****************************************************************************************************************************
	@ Method:   updatePermissionToUserBadge
	@ Version:  1.0
	@ Author:   SRONG TIN (srong.tin@gaea-sys.com)
	@ Purpose:  US-0009878 - update field permission set, permission description
    @ Event:     Before update trigger: UserBadge 
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 19.08.2021 / SRONG TIN / Created the  Method.
                    : 29.09.2022 / David Herrero / Preparing for inserting
                    : 13.03.2023 / Loumang SENG / US-0013125 - Fix Trigger User Badge
	*****************************************************************************************************************************/
    public static void updatePermissionToUserBadge(Map<Id,trailheadapp__User_Badge__c> mapOld,List<trailheadapp__User_Badge__c> listNew){
        List<trailheadapp__User_Badge__c> userBadges = new List<trailheadapp__User_Badge__c>();
        Set<Id> badgeIds = new Set<Id>();
        Set<String> userIds  = new Set<String>();
        Map<Id,String> userMap  = new Map<Id,String>();
        for(trailheadapp__User_Badge__c userBadge: listNew){
            if( ((mapOld!= null && mapOld.get(userBadge.Id).trailheadapp__Status__c != userBadge.trailheadapp__Status__c) || mapOld==null) && 
                userBadge.trailheadapp__Status__c == STATUS_COMPLETED &&
                userBadge.Badge_Type__c == TYPE_MODULE
            ){

                badgeIds.add(userBadge.trailheadapp__Badge__c);
                userIds.add(userBadge.trailheadapp__User__c);
                userMap.put(userBadge.trailheadapp__Badge__c, userBadge.trailheadapp__User__c);
                userBadges.add(userBadge);
            }
        }
        if(userBadges.isEmpty()) return;
        // get All permission set Assignment from user
        Map<String,List<PermissionSetAssignment>> permissionAssigmentbyUser = new Map<String,List<PermissionSetAssignment>>();
        String sWhere = ' WHERE AssigneeId in :userIds';   
        // get PermissionSetAssignment by user
        List<PermissionSetAssignment> userPMSList = Database.query(SOQL_PERMISSIONSET_ASSIGNMENT + sWhere); 
        for(Id uId:userIds){
            List<PermissionSetAssignment> permissionSA = new List<PermissionSetAssignment>();
            for(PermissionSetAssignment pmsList: userPMSList){
                if(uId == pmsList.AssigneeId){
                    permissionSA.add(pmsList);
                }
            }
            permissionAssigmentbyUser.put(uId,permissionSA);
        }

        // list all permission set Name to set
        Set<String> allPermissionSetInBadgeName = new Set<String>();
        List<trailheadapp__Badge__c> allBadges = [Select Id,Permission_Set__c,Permission_Set_Description__c,trailheadapp__Type__c FROM trailheadapp__Badge__c Where Id  in:badgeIds];
        for(trailheadapp__Badge__c b: allBadges){
            if(b.Permission_Set__c != null){
                List<String> lstPMS = b.Permission_Set__c.split(';');
                allPermissionSetInBadgeName.addAll(lstPMS);
            }
        }
        
        // get all permission set from badges
        Map<String,List<PermissionSet>> permissionSetBadgesMap = new Map<String,List<PermissionSet>>();
        List<PermissionSet> allPermissionSetInBadges = [Select Id,Label,Name From PermissionSet Where Name in:allPermissionSetInBadgeName];
        // map permission to badge
        for(trailheadapp__Badge__c b: allBadges){
            if(b.Permission_Set__c != null){
                List<String> lstPMS = b.Permission_Set__c.split(';');
                List<PermissionSet> bPermissionset = new List<PermissionSet>();
                for(PermissionSet p: allPermissionSetInBadges){
                    if(lstPMS.contains(p.Name)){
                        bPermissionset.add(p);
                    }
                }
                permissionSetBadgesMap.put(b.Id,bPermissionset);
            }
        }

        // check duplicate permission set
        Map<Id,trailheadapp__Badge__c> badgeMap = new Map<Id,trailheadapp__Badge__c>();
        Map<String,String> permissionAssigmentMap = new Map<String,String>();
        for(trailheadapp__Badge__c b: allBadges){
            String permissionsetId = getPermissionSetId(b,userMap.get(b.Id),permissionSetBadgesMap,permissionAssigmentbyUser);          
            if (String.isNotBlank(permissionsetid) && permissionsetId.length()>=15){ // Added by DHE on 2022-09-08 to avoid assignation of empty permissions
                badgeMap.put(b.Id,b);
                permissionAssigmentMap.put(userMap.get(b.Id), permissionsetId);
            }
            
        }
        // Assgin field from Badge to User Badge
        if(!badgeMap.isEmpty()){ //LA-13-03-2023-US-0013125
            for(trailheadapp__User_Badge__c userBadge: userBadges){
                trailheadapp__Badge__c badge = badgeMap.get(userBadge.trailheadapp__Badge__c);
                if(badge != null ){//LA-13-03-2023-US-0013125
                    userBadge.Permission_Set__c = badge.Permission_Set__c;
                    userBadge.Permission_Set_Description__c = badge.Permission_Set_Description__c;
                }
            }
        }

        
        // assign permission set to User
        if(!permissionAssigmentMap.isEmpty()){
            assignPermissionToUser(permissionAssigmentMap,userIds);
        }
    }

    /*****************************************************************************************************************************
	@ Method:   getPermissionSetId
	@ Version:  1.0
	@ Author:   SRONG TIN (srong.tin@gaea-sys.com)
    @ Parameter: badge,userId,permissionSetBadgesMap,permissionAssigmentbyUser
	@ Purpose:  getPermissionSetId
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 19.08.2021 / SRONG TIN / Created the  Method.
	*****************************************************************************************************************************/
    private static String getPermissionSetId(trailheadapp__Badge__c badge,String userId,Map<String,List<PermissionSet>> permissionSetBadgesMap,Map<String,List<PermissionSetAssignment>> permissionAssigmentbyUser){
        // check if Badge Type not equal Module
        String permissionString = '';
        String permissionId = '';
        // if(permissionSetBadgesMap.isEmpty())return '';
        if(permissionSetBadgesMap.isEmpty() || !permissionSetBadgesMap.containskey(badge.id))return '';//LA-13-03-2023-US-0013125
        List<PermissionSet> permissionSetList = permissionSetBadgesMap.get(badge.Id);
        for(PermissionSet ps: permissionSetList){
            Boolean isDuplicated = false;
            // check permission set duplicated
            List<PermissionSetAssignment> uperPMSList = permissionAssigmentbyUser.get(userId);
            for(PermissionSetAssignment pmsa: uperPMSList){
                if(ps.Id == pmsa.PermissionSetId){
                    isDuplicated = true;
                    break;
                }
            }
            // add new permission set to the set
            if(!isDuplicated){
                permissionString += (ps.Name + ',\n');
                permissionId += (ps.Id + ','); 
            }
        }
        badge.Permission_Set__c = permissionString;
        return permissionId;
    }

    @future
    private static void assignPermissionToUser(Map<String,String> permissionAssigmentMap,Set<String> userIds){
       // Assgin field from Badge to User Badge map<string,string> userid,groupid
       List<PermissionSetAssignment> lstPermissionsetAssignment = new List<PermissionSetAssignment>();
       for(String userId: userIds){
           // Assgin new permission set to User
           String permissionToAssign = permissionAssigmentMap.get(userId);
           if(permissionToAssign != null){
                List<String> permissionIds = permissionToAssign.split(',');
                for(String pIds: permissionIds){
                    if(pIds != null){
                        PermissionSetAssignment psa = new PermissionSetAssignment();
                        psa.PermissionSetId = pIds;
                        psa.AssigneeId = userId;
                        lstPermissionsetAssignment.add(psa);
                    }
                
                }
           }
           
       }
       // Assgin new permission set to User
       if(!lstPermissionsetAssignment.isEmpty()){
           insert lstPermissionsetAssignment;
       }
    }
    
}