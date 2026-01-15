@isTest
private class Batch_RemoveInActiveGroupMembersTest {

     @TestSetup
     static void makeData()
     {
        Group g1 = new Group(Name='Group 1 The Great',DeveloperName='Group_1_The_Great');
        insert g1;

        List<User> listUsers =  EBH_TestDataFactory.createUsers(3,'Standard User Profile');
        insert listUsers;

        List<GroupMember> listGM = new List<GroupMember>();
        for(User usr: listUsers)
        {
            listGM.add(new GroupMember(UserOrGroupId=usr.Id,GroupId=g1.Id));
        }
        insert listGM;

     }

     @IsTest
     static void testRemoveInActiveMember()
     {
        Test.startTest();       
             
                List<GroupMember> listGM = [Select Id,UserOrGroupId,GroupId,Group.DeveloperName From GroupMember Where Group.DeveloperName='Group_1_The_Great'];
                System.assertEquals(3, listGM.size(),'existing member is 3 before deactivation');
    
                User usr1 = new User(Id=listGM[0].UserOrGroupId,IsActive=False);
                update usr1;
    
                Batch_RemoveInActiveGroupMembers btc = new Batch_RemoveInActiveGroupMembers('Group_1_The_Great');
                Database.executeBatch(btc);
        Test.stopTest();
         
        List<GroupMember> listGM2 = [Select Id,UserOrGroupId,GroupId,Group.DeveloperName From GroupMember Where Group.DeveloperName='Group_1_The_Great'];
        System.assertEquals(2, listGM2.size(),'1 deactivated then removed from the group. Remains 2');

        btc.execute(null);
     }
}