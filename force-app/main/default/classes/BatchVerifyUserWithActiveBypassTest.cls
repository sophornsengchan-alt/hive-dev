/*********************************************************************************************************************************
@ Class:          BatchVerifyUserWithActiveBypassTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0012474 - Test Class for BatchVerifyUserWithActiveBypass
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.06.2025 / Sovantheany Dim / Created the class.
********************************************************************************************************************************/
@IsTest(SeeAllData=false)
private class BatchVerifyUserWithActiveBypassTest {
    @testSetup
    static void setup(){ 
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		User standardUser;
		System.runAs(admin){
			Profile p = [select id from Profile where name='Standard User Profile' limit 1];
            standardUser = new User(alias = 'tsUser', email='TestStardardUser@ebay.com',
                            emailencodingkey='UTF-8', lastname='TestStandardUser', firstname='TestStandardUser', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id,
                            timezonesidkey='America/Los_Angeles', username='TestStardarduser@salesforce.de', isActive = true);
            insert standardUser;
		}
        byPass__c bp = new byPass__c(SetupOwnerId = standardUser.Id, triggerObjects__c = 'Quote QuoteLineItem', byPass_Trigger__c = true, Bypass_Flow__c = true,ByPass_Validation__c=true);
        insert bp;
    }

    @isTest
    static void testBatchActiveBypass() {
        User u = [select Id, ProfileId, Profile.Name from User where username = 'TestStardarduser@salesforce.de' limit 1];
        RecordType rtAccess = ApexUtil.getRecordTypeByName('Ticket__c', BatchVerifyUserWithActiveBypass.TICKET_RECORD_TYPE);
        Ticket__c ticket2 = new Ticket__c(RecordTypeId= rtAccess.Id);
        ticket2.Type_of_Elevated_Access__c = BatchVerifyUserWithActiveBypass.TICKET_TYPE_BYPASS; //Full System Admin /	Enable Bypass
        ticket2.Duration_In_Minutes__c = 90; //90 minutes from now
        ticket2.Business_Reason__c = 'testing purpose';
        ticket2.User__c = u.Id;
        ticket2.Previous_Profile_Name__c = u.Profile.Name;
        ticket2.Previous_Profile_Id__c = u.ProfileId; 
        ticket2.Triggered_Objects__c   = 'Quote QuoteLineItem';
        ticket2.Flow__c = true;
        ticket2.Trigger__c = true;
        ticket2.Validation_Rule__c = true;   
        ticket2.Status__c = 'Pending';
        ApexSafe.dml().doInsert(new List<Ticket__c>{ticket2}, true);
        Test.startTest();
            BatchVerifyUserWithActiveBypass batch = new BatchVerifyUserWithActiveBypass(u.Id);
            Database.executeBatch(batch, 100);
        Test.stopTest();
        for(Ticket__c t : [SELECT Id,User__c, User__r.Name, Triggered_Objects__c,Flow__c,Trigger__c,Validation_Rule__c, Status__c,Duration_In_Minutes__c,Duration_In_Date_time__c FROM Ticket__c WHERE User__c = : u.Id]){
            System.assertEquals('Pending', t.Status__c, 'Ticket status should remain Pending for future tickets');
        }
    }
    @isTest
    static void testBatchInActiveBypass() {
        //User u = [select Id, ProfileId, Profile.Name from User where id =: UserInfo.getUserId() limit 1];
        User u = [select Id, ProfileId, Profile.Name from User where username = 'TestStardarduser@salesforce.de' limit 1];
        RecordType rtAccess = ApexUtil.getRecordTypeByName('Ticket__c', BatchVerifyUserWithActiveBypass.TICKET_RECORD_TYPE);
        Ticket__c ticket = new Ticket__c(RecordTypeId= rtAccess.Id);
        ticket.Type_of_Elevated_Access__c = BatchVerifyUserWithActiveBypass.TICKET_TYPE_BYPASS; //Full System Admin /	Enable Bypass
        ticket.Duration_In_Minutes__c = -60; //-60 minutes ago
        ticket.Business_Reason__c = 'testing purpose';
        ticket.User__c = u.Id;
        ticket.Previous_Profile_Name__c = u.Profile.Name;
        ticket.Previous_Profile_Id__c = u.ProfileId; 
        ticket.Triggered_Objects__c   = 'Quote QuoteLineItem';
        ticket.Flow__c = true;
        ticket.Trigger__c = true;
        ticket.Validation_Rule__c = true;   
        ticket.Status__c = 'Pending';
        ApexSafe.dml().doInsert(new List<Ticket__c>{ticket}, true);
        Test.startTest();
            BatchVerifyUserWithActiveBypass batch = new BatchVerifyUserWithActiveBypass(u.Id);
            Database.executeBatch(batch, 100);
        Test.stopTest();
        for(Ticket__c t : [SELECT Id,User__c, User__r.Name, Triggered_Objects__c,Flow__c,Trigger__c,Validation_Rule__c, Status__c,Duration_In_Minutes__c,Duration_In_Date_time__c FROM Ticket__c WHERE User__c = : u.Id]){
            System.assertEquals('Completed', t.Status__c, 'Ticket status should be updated to Completed for past tickets');
        }
        // Verify that the byPass__c record has been updated
        byPass__c updatedByPass = [SELECT Id,SetupOwner.Name, SetupOwnerId, triggerObjects__c, ByPass_Flow__c, byPass_Trigger__c, ByPass_Validation__c FROM byPass__c WHERE SetupOwnerId = : u.Id LIMIT 1];
        System.assertEquals(null, updatedByPass.triggerObjects__c, 'triggerObjects__c should be null after batch processing');
        System.assertEquals(false, updatedByPass.Bypass_Flow__c, 'Bypass_Flow__c should be false after batch processing');
        System.assertEquals(false, updatedByPass.byPass_Trigger__c, 'byPass_Trigger__c should be false after batch processing');
        System.assertEquals(false, updatedByPass.ByPass_Validation__c, 'ByPass_Validation__c should be false after batch processing');
    }
}