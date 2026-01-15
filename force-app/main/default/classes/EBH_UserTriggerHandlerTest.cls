/*********************************************************************************************************************************
@ Class:        EBH_UserTriggerHandlerTest
@ Version:      1.0
@ Author:       David Herrero
@ Purpose:      Test for EBH_UserTriggerHandlerTest
@                  
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.06.2018 / David Herrero / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history 21/09/2023 / Vimean Heng / US-0014173 - Deprecate method
@ Change history:  18.12.2023 / Vimean Heng / Fix lock row.
*********************************************************************************************************************************/
@isTest(SeeAllData=false)
private class EBH_UserTriggerHandlerTest {

    private static UserRole r = [select Id from UserRole where DeveloperName='Standard_Users' Limit 1];

    @TestSetup
    static void setup(){
        byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), byPass_Trigger__c = false,byPass_Validation__c=true);
        insert bp;
        EBH_TestDataFactory.setUpCustomSettings();
    }
    // @ Change history:  18.12.2023 / Vimean Heng / US-0014423 / Fix lock row.
    static testMethod void testUpdateUser() {
        // EBH_TestDataFactory.setUpCustomSettings();
        User u = EBH_TestDataFactory.createUser('Standard User Profile');
        u.UserRoleId = r.Id;
        insert u;
        User auUser2 = EBH_TestDataFactory.createUser(EBH_ConstantsUtility.TICKET_AU_PROFILE);
        insert auUser2;
        System.runAs(auUser2){
        	PermissionSet ps = [select id,name from PermissionSet where name ='DocuSign_User' limit 1];
	        System.debug('*************************');
	        
	        System.debug(ps);
	        
	        PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetid=ps.id,AssigneeId=u.ID);
	        
	        insert psa;
	        Map<id,String> mapUserPermissionSet = new map<id,STring>();
	        mapUserPermissionSet.put(u.ID,ps.Name);
	        EBH_UserTriggerHandler.performchanges(mapUserPermissionSet);
        }
        
        System.debug('*************************');
        System.debug([select PermissionSet.name, assigneeId, assignee.username from PermissionsetAssignment where assigneeid=:u.ID]);
        Test.startTest();
        update u;
        Test.stopTest();
        u=[select id,permission_sets__c from User where id =:u.ID];
        //        System.assert(u.Permission_Sets__c.indexOf(ps.name)>=0);
        
        
        
    }
    //Vimean Heng : US-0014173
    /*
    static testMethod void testUpdateUserProfile() {
        // EBH_TestDataFactory.setUpCustomSettings();
        User u = EBH_TestDataFactory.createUser('System Administrator');
        User u2 = EBH_TestDataFactory.createUser('Standard User Profile');
        
        Profile p = [select id from profile where name = 'Business Admin' limit 1];
        insert u;
        insert u2;
        System.runAs(u){
            Test.startTest();
            u2.profileid=p.id;
            update u2;
        }
        Test.stopTest();
  
        
    }
    */
    // @ Change history:  18.12.2023 / Vimean Heng / US-0014423 / Fix lock row.
    static testmethod void testCreateUserNoSystemAdmin(){
        // EBH_TestDataFactory.setUpCustomSettings();
        Profile p = [select id from Profile where name ='Standard User Profile'];
        User cu = EBH_TestDataFactory.createUser('Chatter Free User');
        User u = new User(Alias             = 'usr', 
                            Email             = 'usr' + Math.random() + '@org.com', 
                            EmailEncodingKey  = 'UTF-8', 
                            LastName          = 'Testing' + Math.random(), 
                            LanguageLocaleKey = 'en_US', 
                            LocaleSidKey      = 'en_US', 
                            //ProfileId         = p.Id, 
                            ProfileId         = cu.ProfileId,
                            TimeZoneSidKey    = 'America/Los_Angeles',
                            UserName          = 'usr' + Math.random() + '@org.com',
                            IsActive = true,
                            Permission_Sets__c = 'eBay_Standard_User', //MN-11062024-US-0015298
                            Competency__c = 'Copy');
        insert u;
        u.ProfileId = p.Id;
        update u;
        EBH_UserTriggerHandler.checkAssignPermSetSEP(new List<User>{u});
        
            
            
        }
        
        static testmethod void testDeleteDaysForInactiveUsers(){
        // EBH_TestDataFactory.setUpCustomSettings();
        Test.startTest();
        List<User> adminUsers = [Select Id From User where ProfileId=:EBH_ConstantsUtility.ADMIN_PROFILE_ID AND isActive=true];
	    		
        Profile p = [select id from Profile where name ='Standard User Profile'];
        
        User u = new User(Alias             = 'usr', 
                            Email             = 'usr' + Math.random() + '@org.com', 
                            EmailEncodingKey  = 'UTF-8', 
                            LastName          = 'Testing' + Math.random(), 
                            LanguageLocaleKey = 'en_US', 
                            LocaleSidKey      = 'en_US', 
                            ProfileId         = p.Id, 
                            TimeZoneSidKey    = 'America/Los_Angeles',
                            UserName          = 'usr' + Math.random() + '@org.com',
                            IsActive = true,
                          
                            Competency__c = 'Copy');
        insert u;
        //US-0014173 change system.today()+1 to system.today()+2 
        Day__c d = new Day__c(User__c = u.Id,Day__c = system.today()+2,Available_capacity_of_your_work_time__c = 10);
        System.RunAs(adminUsers[0])
    	{
            insert d;
        }

        
        System.RunAs(adminUsers[0])
    	{
    		// Group g = [Select id From Group g where DeveloperName =: EBH_ConstantsUtility.GROUP_MARKETING_EXC];
    		 
    		// GroupMember gMember = new GroupMember(GroupId = g.ID,UserOrGroupId=u.Id);
    		// insert gMember;
    		
    		u.IsActive = false;
    		update u;
    		EBH_UserTriggerHandler.doDeletedWhenBatch(new Set<String>{u.Id});
    	}
        Test.stopTest();   
        List<Day__c> dSel = [select id from Day__c where id =: d.Id];
         
        System.assert(dSel.isEmpty());
        }

    @IsTest
    static void testReassignPermSet()
    {
        for(PermissionSetGroup psg : [select Id, Status from PermissionSetGroup where DeveloperName IN ('Seller_Portal_DE', 'Seller_Portal_NA')]){
            // force calculation of the PSG if it is not already Updated
            if (psg.Status != 'Updated') {
                Test.calculatePermissionSetGroup(psg.Id);
            }
        }
        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        Account portalAccount1;
        Contact contact1;
        System.runAs(admins[0])
        {
            //Create account
            portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id,
                SP_Main_Domain__c = SEP_Helper.SEP_Domain_AU //MN-10062024-US-0015298
            );            
            insert new List<Account>{portalAccount1};

            //Create contact
            contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com'
            );            
            insert new Contact[]{contact1};
        }
        
        Test.startTest();
        System.runAs(admins[1])
        {
            //Create user
            User user1 = SEPTestGenerator.createSEPUser('sepUseruth1', contact1.Id); //MN-10062024-US-0015298

            /*  MN-10062024-US-0015298
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'AU - Seller Portal' LIMIT 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'AMT_TEST',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Permission_Sets__c = 'Seller_Portal_DE'
            );
            
            insert new User[]{user1};

            List<PermissionSetAssignment> listAssignment = [Select Id From PermissionSetAssignment Where AssigneeId =:user1.Id];
            //System.assert(listAssignment.size() >= 1,' Permset Group assigned');
            */
        }   

        Test.stopTest();
        
    }
}