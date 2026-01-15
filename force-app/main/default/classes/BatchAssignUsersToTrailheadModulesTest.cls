@isTest
private  class BatchAssignUsersToTrailheadModulesTest {
    static final String GROUPNAME='TestGroup1';
    static final String BADGENAME='BADGENAME';
    static final String BADGEURL='https://hive.my.trailhead.com/content/hive/modules/na-unsubsidised-deals-creation-approval/';
private static void setupdata(){


    User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 1];
        
        
        
        User stdUsr;
        Group g;
        System.runAs(admins[0])
        {

            stdUsr = EBH_TestDataFactory.createUser('Standard User Profile');
            stdUsr.FirstName = 'Test';
            Insert stdUsr;
            
             g = [select id from Group where name='Testers' and Type='Regular' limit 1];
            if (g==null){
                g= new Group(name='Testers', Type='Regular');
                insert g;

               }
            

        }


    
    GroupMember gm = new GroupMember(GroupId=g.id,UserOrGroupId=stdUsr.id);
    insert gm;



}
 @IsTest
static void methodName(){
    setupdata();
    User u = [select id from user where isactive=true and profile.name='System Administrator' limit 1];
    Test.startTest();
    System.runAs(u){
        BatchAssignUsersToTrailheadModules battm = new BatchAssignUsersToTrailheadModules();
        Database.executeBatch(battm);
    }
    Test.stopTest();
    List<trailheadapp__user_badge__c> loub=Database.query('Select id,trailheadapp__Badge__r.name from trailheadapp__user_badge__c   where trailheadapp__Badge__r.Name =:BADGENAME');
 //   System.assert(!loub.isEmpty(), 'No user badge has been created');
    
}

}