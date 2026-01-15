/*********************************************************************************************************************************
@ Class:        BatchDeactivateUsersTest
@ Version:      1.0
@ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:      Test for BatchDeactivateUsers
@				- Test using CreatedDate as LastLoginDate since it is read-only
@                  
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.06.2018 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
@isTest
private class BatchDeactivateUsersTest {
	static String testSoql = 'SELECT Profile.Name,Profile.UserLicense.Name,CreatedDate,First_Notification__c,Second_Notification__c,Final_Notification__c,Reactivated_Date__c,Name, LastLoginDate,IsActive, Id From User';
	
	@TestSetup
	static void makeData(){
		EBH_TestDataFactory.setUpCustomSettings();
		Account a = new Account ( Name='GCX' , RecordTypeId=ApexUtil.getRecordTypeByName('Account', 'EBH_Partner').ID);
		insert a;
		Contact c = EBH_TestDataFactory.createContacts(1, 'lastname', a.Id)[0];
	}

    static testMethod void testDeactivateUserLast45() {
         User u = EBH_TestDataFactory.createUser('Standard User Profile');		 
         u.Active_Approver__c =false;
		 u.isActive = true;
         insert u;
		
        Test.startTest();
         	
	         BatchDeactivateUsers b = new BatchDeactivateUsers(testSoql +' WHERE ID=\''+u.Id+'\'');
	         b.lastLoginField = 'CreatedDate';
	         b.lastLoginDateStrict45 = System.now().addDays(1);
	         b.batchSize = 1;
	         
	         Database.executeBatch(b);
         Test.stopTest();
		 User uSel = Database.query(testSoql+' WHERE ID=\''+u.Id+'\'');
        //system.assertEquals(false,uSel.isActive,'deactivated');
		
		Case[] listCases = [Select Id From Case where Deactivate_User__c =: u.Id];
		//system.assertEquals(true,!listCases.isEmpty(),'case created and closed');

    }
    static testMethod void testDeactivateUserLast40() {
         User u = EBH_TestDataFactory.createUser('Standard User Profile');
         u.Active_Approver__c =false;
		 u.isActive = true;
         insert u;         
        
         Test.startTest();
         	
	         BatchDeactivateUsers b = new BatchDeactivateUsers(testSoql+' WHERE ID=\''+u.Id+'\'');
	         b.lastLoginField = 'CreatedDate';
	         b.lastLoginDateStrict45 = System.now().addDays(-1);
	         b.lastLoginDateStrict37 = System.now().addDays(1);
	         b.batchSize = 1;
	         
	         Database.executeBatch(b);
         Test.stopTest();
		 User uSel = Database.query(testSoql+' WHERE ID=\''+u.Id+'\'');        	
         system.assertEquals(true,uSel.isActive,'still active');
    }
    static testMethod void testDeactivateUserLast30() {
         User u = EBH_TestDataFactory.createUser('Standard User Profile');
         u.Active_Approver__c =false;
		 u.isActive = true;
         insert u;   

         Test.startTest();
         	
	         BatchDeactivateUsers b = new BatchDeactivateUsers(testSoql+' WHERE ID=\''+u.Id+'\'');
	         b.lastLoginField = 'CreatedDate';
	         b.lastLoginDateStrict45 = System.now().addDays(-1);
	         b.lastLoginDateStrict37 = System.now().addDays(-1);
	         b.lastLoginDateStrict30 = System.now().addDays(1);
	         //b.batchSize = 1;
	         
	         Database.executeBatch(b);
         Test.stopTest();
		 User uSel = Database.query(testSoql+' WHERE ID=\''+u.Id+'\'');        	
    	system.assertEquals(true,uSel.isActive,'still active');
	
	}
	
	static testMethod void testDeactivateUserLast80() {
		Contact c = [select id from Contact where Account.name = 'GCX' limit 1];
		User u=EBH_TestDataFactory.createUser('Influencer Partner Profile');
		u.contactid=c.id;
		u.Active_Approver__c =false;
		u.isActive = true;
		insert u;
		Test.startTest();
			BatchDeactivateUsers b = new BatchDeactivateUsers(testSoql+' WHERE ID=\''+u.Id+'\'');
			b.lastLoginField = 'CreatedDate';
			b.lastLoginDateStrict80 = System.now().addDays(1);
			
			Database.executeBatch(b);
		Test.stopTest();
		User uSel = Database.query(testSoql+' WHERE ID=\''+u.Id+'\''); 	
	   system.assertEquals(true,uSel.isActive,'still active');
	   system.assert(uSel.First_Notification__c != null);
   
   }
   static testMethod void testDeactivateUserLast90() {
	Contact c = [select id from Contact where Account.name = 'GCX' limit 1];
	User u=EBH_TestDataFactory.createUser('Influencer Partner Profile');
	u.contactid=c.id;
	u.Active_Approver__c =false;
	u.isActive = true;
	insert u;
	Test.startTest();
		BatchDeactivateUsers b = new BatchDeactivateUsers(testSoql+' WHERE ID=\''+u.Id+'\'');
		b.lastLoginField = 'CreatedDate';
		b.lastLoginDateStrict90 = System.now().addDays(1);
		
		Database.executeBatch(b);
	Test.stopTest();
	User uSel = Database.query(testSoql+' WHERE ID=\''+u.Id+'\'');	
   system.assertEquals(false,uSel.isActive,'user inactive');
   system.assert(uSel.Final_Notification__c != null);

	}
    
	static testMethod void testFinalCoverage() {
		//just for coverage
		Test.startTest();

			BatchDeactivateUsers b2 = new BatchDeactivateUsers();
			//b2.batchSize = 500;
			b2.execute(null);
		Test.stopTest();
	}
}