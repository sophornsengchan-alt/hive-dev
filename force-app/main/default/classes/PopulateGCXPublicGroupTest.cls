/***************************************************************************************************************************************
@ Class:          PopulateGCXPublicGroupTest
@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        US-0008365 - Upgrade code coverage of PopulateGCXPublicGroup from 0% to 85%
----------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.10.2021 / Sambath Seng / Created the class.
***************************************************************************************************************************************/
@isTest
public class PopulateGCXPublicGroupTest {
    private static Set<Id> groupMemberIds = new Set<Id>();
    static void setup(){
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name='GCX_Super_User'].Id;
        Group gp = new Group(name = 'GCX Super User');
        insert gp;
        List<PermissionSetAssignment> lstPermissionSet = new List<PermissionSetAssignment>();
        List<GroupMember> lstGm = new List<GroupMember>();
        List<User> lstUser = EBH_TestDataFactory.createUsers(10,'Standard User');
        insert lstUser;
        //Assign permission set to 5 users
        for(Integer i = 0; i<5; i++){
            PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = permissionSetId, AssigneeId = lstUser[i].Id);
            lstPermissionSet.add(psa);
        }
        if(!lstPermissionSet.isEmpty()){
            insert lstPermissionSet;
        }
        for(User oUser : lstUser){
            lstGm.add(new GroupMember(groupId = gp.Id, userOrGroupId = oUser.Id));
        }
        if(!lstGm.isEmpty()){
            insert lstGm;
        }
        for(GroupMember oGm : lstGm){
            groupMemberIds.add(oGm.Id);
        }
    }
    @isTest
    static void testPopulateGCXPublicGroup(){
        setup();
        PopulateGCXPublicGroup ba = new PopulateGCXPublicGroup();
        ba.soql = 'Select  AssigneeId From PermissionSetAssignment  where PermissionSet.Name IN (\'GCX_Super_User\')';
        Test.startTest();
        	Database.executeBatch(ba);
        Test.stopTest();
		List<GroupMember> lstGroupMember = [SELECT Id, groupId, userOrGroupId FROM GroupMember WHERE Id IN :groupMemberIds];
        //Check group member list size
        system.assertEquals(5, lstGroupMember.size());        
    }
}