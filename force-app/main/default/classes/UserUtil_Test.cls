/*********************************************************************************
@ Class:          UserUtil_Test
@ Version:        1.0
@ Author:         Vimean Heng
@ Purpose:        General utility class for updating user
----------------------------------------------------------------------------------
@ Change history: 26.04.2024 / Vimean Heng / US-0014980 / Created the class.
@                 18.07.2025 / vadhanak voun / US-0012459 - AccelQ - Extend UserUtil class
**************************************************************************************/
@isTest
private class UserUtil_Test {
    @TestSetup
    static void makeData(){
        // Create test data
        Profile p = [select id from Profile where name='Standard Ads User Profile' limit 1];
        User testUser = new User(alias = 'TestApro', email='testaccelq@ebay.com', 
                            emailencodingkey='UTF-8', lastname='testaccelq', firstname='testaccelq', languagelocalekey='en_US', 
                            localesidkey='en_US', profileid = p.Id, 
                            timezonesidkey='America/Los_Angeles', username='testaccelq@salesforce.de', isActive = true);
       
        ApexSafe.dml().doInsert(new List<User>{testUser},false);
    }
    @isTest
    static void testUpdateUser() {
        String userName = 'testaccelq@salesforce.de';
        UserUtil.addPermissionSet(userName,'New User');
        UserUtil.addPermissionSetGroup(userName,'Copado Developers');
        UserUtil.updateUser(userName,'Standard User Profile');
        UserUtil.updateUser(userName,'',new String[]{'Business User'});
        UserUtil.updateUser(userName,'NA Standard User Base','New User',true,'Copado Users',true,'DE',true);

        //
        UserUtil.updateUser(userName,'NA Standard User Base',new String[]{'New User'},true,new String[]{'Copado Users'},false,'DE',true);

        UserUtil.addPermissionSetGroup(userName,'Copado Developers');
        UserUtil.addPermissionSetGroup(userName,new String[]{'Copado Developers'});

        //
        User u = UserUtil.getUser(userName);
        UserRole role = UserUtil.getUserRole('DE');
        Profile p = UserUtil.getProfile('NA Standard User Base');
        List<PermissionSetAssignment> ps = ApexSafe.query().doQuery('Select PermissionSet.Name, PermissionSetId, AssigneeId From PermissionSetAssignment WHERE PermissionSet.IsOwnedByProfile = false AND PermissionSetGroupId = null AND AssigneeId=\'' + u.Id + '\'');
        Assert.isTrue(!ps.isEmpty());
        Assert.isTrue(u.IsActive);
        Assert.areEqual(u.ProfileId , p.Id);
        Assert.areEqual(u.UserRoleId, role.Id);
    }
    @isTest
    static void testremoveAllPermissionSet() {
        String userName = 'testaccelq@salesforce.de';
        UserUtil.addPermissionSet(userName,new String[]{'New User','Business User'});
        User u = UserUtil.getUser(userName);
        UserUtil.removeAllPermissionSet(userName);
        List<PermissionSetAssignment> ps = ApexSafe.query().doQuery('Select PermissionSet.Name, PermissionSetId, AssigneeId From PermissionSetAssignment WHERE PermissionSet.IsOwnedByProfile = false AND PermissionSetGroupId = null AND AssigneeId=\'' + u.Id + '\'');
        Assert.isTrue(ps.isEmpty());
    }
}