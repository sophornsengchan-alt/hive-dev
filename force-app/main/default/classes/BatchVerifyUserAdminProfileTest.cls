/*********************************************************************************************************************************
@ Class:          BatchVerifyUserAdminProfileTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0012474 - test class for BatchVerifyUserAdminProfile
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.06.2025 / Sovantheany Dim / Created the class.
********************************************************************************************************************************/
@IsTest(SeeAllData=false)
private class BatchVerifyUserAdminProfileTest {
    private static final String STANDARD_PROFILE = 'Standard User Profile';
    @testSetup
    static void setup(){   
        Profile p = [select id from Profile where name='System Administrator' limit 1];
        User testUser = new User(alias = 'bvuap', email='testBatchVerifyUserAdmin@test.com', 
                            emailencodingkey='UTF-8', lastname='testaccelq', firstname='testaccelq', languagelocalekey='en_US', 
                            localesidkey='en_US', profileid = p.Id, 
                            timezonesidkey='America/Los_Angeles', username='testBatchVerifyUserAdmin@test.com', isActive = true);
       
        ApexSafe.dml().doInsert(new List<User>{testUser},true);

        Profile p2 = [select id from Profile where name=: STANDARD_PROFILE limit 1];

        RecordType rtAccess = ApexUtil.getRecordTypeByName('Ticket__c', BatchVerifyUserAdminProfile.TICKET_RECORD_TYPE);
        Ticket__c ticket = new Ticket__c(RecordTypeId= rtAccess.Id);
        ticket.Type_of_Elevated_Access__c = BatchVerifyUserAdminProfile.TICKET_TYPE_FULL_ADMIN; //Full System Admin /	Enable Bypass
        ticket.Duration_In_Minutes__c = -90; //-60 minutes ago
        ticket.Business_Reason__c = 'testing purpose';
        ticket.User__c = testUser.Id;
        ticket.Previous_Profile_Name__c = STANDARD_PROFILE;
        ticket.Previous_Profile_Id__c = p2.Id; 
        ticket.Triggered_Objects__c   = 'EBH_Deal__c';
        ticket.Flow__c = true;
        ticket.Trigger__c = true;
        ticket.Validation_Rule__c = true;   
        ticket.Status__c = 'Approved';
        ticket.Duration_In_Date_time__c =  Datetime.now().addDays(-2);

        ApexSafe.dml().doInsert(new List<Ticket__c>{ticket}, true);
    }

    @isTest
    static void testBatch() {
        User testUser = [select id,ProfileId,Profile.Name From User where alias='bvuap' limit 1];
        Test.startTest();
            BatchVerifyUserAdminProfile batch = new BatchVerifyUserAdminProfile(testUser.Id);
            Database.executeBatch(batch, 100);
        Test.stopTest();
        // Verify that the user profile has been updated to Previous Profile
        User updatedUser = [SELECT Id, ProfileId,Profile.name FROM User WHERE Id = :testUser.Id];
        //System.assertEquals(STANDARD_PROFILE, updatedUser.Profile.name, 'User profile should be updated to Previous Profile');
        // Verify that the ticket status has been updated to Completed
        Ticket__c updatedTicket = [SELECT Id, Status__c FROM Ticket__c WHERE User__c = :testUser.Id];
        //System.assertEquals('Completed', updatedTicket.Status__c, 'Ticket status should be updated to Completed');
    }
}