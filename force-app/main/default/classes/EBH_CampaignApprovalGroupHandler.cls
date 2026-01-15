/*********************************************************************************************************************************
@ Class:          EBH_CampaignApprovalGroupHandler
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        EPH-3184: Handler Class for Campaign Approval Group Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.09.2017 / NEHA LUND / Created the class.
*********************************************************************************************************************************/

public with sharing class EBH_CampaignApprovalGroupHandler {
     
     Map<String, ID> sitePublicGroupMap = new Map<String,ID>(); //to store Site as Key and Id of the public group as value
     Map<String, GroupMember> existingMembers = new Map<String, GroupMember>(); //to get the existing members of the group
     
     /*****************************************************************************************************************************
    @ Constructor:         
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        processes campaign approval group records and based on the parent Site
                      For each site respective public group is stored in the custom settings
    ------------------------------------------------------------------------------------------------------------
    @ Parameter:      
    ------------------------------------------------------------------------------------------------------------
    @ Change history: 23.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
     public EBH_CampaignApprovalGroupHandler() {
         
         Set<String> crsGroups;
         //populate the map
         if(sitePublicGroupMap.isEmpty()) {
            Map<String, String> campRequestSites  = new Map<String,String>();
            //to get the custom settings data - public group developer name as key and Site value
            for( EBH_CampaignRequestSiteGroup__c request : EBH_CampaignRequestSiteGroup__c.getAll().values()){
                campRequestSites.put(request.EBH_PublicGroup__c, request.Name);
            }
            
            crsGroups = campRequestSites.keyset();
            
            //Key will be Site and value will be group ID required for creating group members
            for(Group grp :Database.query(EBH_constantsUtility.CAGH_GRPMEMS)) {
                sitePublicGroupMap.put( campRequestSites.get(grp.DeveloperName), grp.Id );
                for( GroupMember gm :grp.GroupMembers) {
                    //to get the existing members
                    existingMembers.put( gm.UserOrGroupId+EBH_ConstantsUtility.HYPHEN_KEY+gm.GroupId, gm);
                }
            }
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         updateApproversInPublicGroups
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        For insert trigger event, add the group members as Campaign Approval group is added
    ------------------------------------------------------------------------------------------------------------
    @ Parameter:      Passed through trigger scope
                      List<EBH_CampaignApprovalGroup__c> campaignApprovals
                      Map<Id,EBH_CampaignApprovalGroup__c> oldMap 
    ------------------------------------------------------------------------------------------------------------
    @ Change history: 23.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public void updateApproversInPublicGroups(List<EBH_CampaignApprovalGroup__c> campaignApprovals, Map<Id,EBH_CampaignApprovalGroup__c> oldMap ){
        
        GroupMember GM = new GroupMember();
        List<String> groupMembers = new List<String>();
        
        //parse through trigger scope records
        for( EBH_CampaignApprovalGroup__c campGroup : campaignApprovals ){
            
            //if Site or approver is changed, then new Group Member should be added
            if( hasSiteOrApproversChanged( campGroup, oldMap) && 
                sitePublicGroupMap.containsKey(campGroup.EBH_ParentSite__c) &&
                !existingMembers.containsKey( campGroup.EBH_Approver__c+EBH_ConstantsUtility.HYPHEN_KEY 
                                              + sitePublicGroupMap.get( campGroup.EBH_ParentSite__c)) ){
                
                    GM = new GroupMember();
                    GM.GroupId = sitePublicGroupMap.get( campGroup.EBH_ParentSite__c);
                    GM.UserOrGroupId = campGroup.EBH_Approver__c;
                    groupMembers.add( JSON.serialize(GM));
                
            }
        }
         //future method to avoid DML exception, add the new group members when new records are created/updated
         addMembers(groupMembers, true);
    }
    
    /*****************************************************************************************************************************
    @ Method:         removeApproversFromPublicGroups
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        processes campaign approval group records and based on the parent Site
                      For each site respective public group is stored in the custom settings
    ------------------------------------------------------------------------------------------------------------
    @ Parameter:      campaignGroupRecords - passed from trigger scope, for after update/delete events of 
                                             Campaign Approval Group records
                      oldMap - old map of the trigger scope, to check if Site/approver information is updated                    
    ------------------------------------------------------------------------------------------------------------
    @ Change history: 23.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    
    public List<String> removeApproversFromPublicGroups( List<EBH_CampaignApprovalGroup__c> campaignGroupRecords, Map<Id,EBH_CampaignApprovalGroup__c> oldMap){
        
        List<String> groupMembersTobeDeleted = new List<String>();
        GroupMember GM = new GroupMember();
        
        for( EBH_CampaignApprovalGroup__c campGroup : campaignGroupRecords ){
            
            if( hasSiteOrApproversChanged( campGroup, oldMap ) && sitePublicGroupMap.containsKey(campGroup.EBH_ParentSite__c) 
              ){    
                    GM = new GroupMember();
                    if( oldMap != null){
                        //if an update event is invoked then, old approver should be removed from the public group
                        GM.Id = existingMembers.get( oldMap.get(campGroup.id).EBH_Approver__c+ EBH_ConstantsUtility.HYPHEN_KEY
                                                     + sitePublicGroupMap.get( campGroup.EBH_ParentSite__c)).id;
                    }
                    else{
                        //if a delete event is invoked then, current approver should be removed from the public group
                        GM.Id = existingMembers.get( campGroup.EBH_Approver__c + EBH_ConstantsUtility.HYPHEN_KEY
                                                     + sitePublicGroupMap.get( campGroup.EBH_ParentSite__c)).id;
                    }
                    groupMembersTobeDeleted.add(JSON.serialize(GM));   
                
            }
        }
        addMembers(  groupMembersToBeDeleted, false);
        return groupMembersTobeDeleted;

    }  
    /*****************************************************************************************************************************
    @ Method:         addMembers
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        processes campaign approval group records and based on the parent Site
                      For each site respective public group is stored in the custom settings
    ------------------------------------------------------------------------------------------------------------
    @ Parameter:      StandardController - passed through the action i.e. when Campaign is submitted for an approval
    ------------------------------------------------------------------------------------------------------------
    @ Change history: 23.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    @future
    public static void addMembers(List<String> groupMembersToBeAdded, boolean isInsert ){
        
        List<GroupMember> members = new List<GroupMember>();
        for( String member: groupMembersToBeAdded){
            members.add((GroupMember) JSON.deserialize(member, sobject.class));
        }
         //method used for both adding or deleting group members, to avoid mix dml operation future annotation is used 
         if( !members.isEmpty() ){
     
             try{
                if( isInsert ){ 
                    Database.insert(members,false);
                }
                else{
                    Database.delete(members, false);
                }
              } catch(Exception ex) {
                    EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.REQUEST_CLASS,
                    EBH_ConstantsUtility.REQUEST_METHOD);
                }
         }

       
    }
    
      
   /*****************************************************************************************************************************
    @ Method:         hasSiteOrApproversChanged
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Check and returns true if any of the following fields has changed in account passed in param:
                       - Site
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Campaign Approval Group: to check if approver has been changed
                      oldMap:  old map from trigger scope to compare
                      - Parent Site
                      - Approver
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the fields are changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 23.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public Boolean hasSiteOrApproversChanged(EBH_CampaignApprovalGroup__c camp, Map<Id, EBH_CampaignApprovalGroup__c> oldMap) {
        
        EBH_CampaignApprovalGroup__c oldCamp = oldMap != Null ? oldMap.get(camp.Id) : camp;
        
        return camp.EBH_ParentSite__c != oldCamp.EBH_ParentSite__c ||
               camp.EBH_Approver__c != oldCamp.EBH_Approver__c ||
               oldMap == null; 
               
    } 
   
}