/*********************************************************************************************************************************
@ Class:         UserAvailabilityTriggerHandlerTest
@ Version:       1.0
@ Author:        Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:       US-0011996 - Call booking for Ads
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  15.07.2022 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
@isTest
private class UserAvailabilityTriggerHandlerTest {

    private static void setupData(){
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',UserAvailabilityTrigger__c = true, EBH_TaskTrigger__c = true);
    }

    @isTest
    private static void testInsertUpdateUserAvailibility(){
        setupData();

        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        
        BoB__c bob = new BoB__c(
            RecordTypeId = bobRecordTypeLTTM.Id ,
            Name='Bob 1',
            Status__c = 'BoB Active',
            Managed_Type__c = 'LTTM Managed'
        );
        insert bob;
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
 		Account seller = new Account(Name='Seller',RecordTypeID = sellerRecordType.Id);
        Account seller1 = new Account(Name='Seller222',RecordTypeID = sellerRecordType.Id);
        insert new List<Account>{seller,seller1};

        Id currentUserId = UserInfo.getUserId();

        Date d = Date.newInstance(Date.today().year(), Date.today().month(), Date.today().day());
        Datetime dt = (DateTime)d;
        String dow = dt.format('EEEE');
        if (dow == 'Saturday') d = Date.today().addDays(3);
        else if (dow == 'Sunday') d = Date.today().addDays(2);
        
        BOB_Seller__c bobSeller = new BOB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLTTM.Id ,
            BOB__c=bob.Id, 
            Seller__c=seller.Id,
            Next_Call_Schedule_Date__c = d,
            Time_Slot__c = 'Morning (9 AM to 12 PM)'
        );
        
        BOB_Seller__c bobSeller1 = new BOB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLTTM.Id ,
            BOB__c=bob.Id, 
            Seller__c=seller1.Id,
            Next_Call_Schedule_Date__c = d,
            Time_Slot__c = 'Afternoon(1 PM to 5 PM)'
        );
        insert new List<BOB_Seller__c>{bobSeller, bobSeller1};
        bobSeller.Account_Manager__c = currentUserId;
        bobSeller1.Account_Manager__c = currentUserId;
        update new List<BOB_Seller__c>{bobSeller, bobSeller1};

        Datetime startDatetime = Datetime.newInstanceGmt(d.year(),d.month(),d.day(), 8, 0,0);
        Datetime endDatetime = Datetime.newInstanceGmt(d.year(),d.month(),d.day(), 11, 0,0);

        Task task = new Task(Subject = 'test User Availability', Update_User_Availability__c = false, Call_Back_Window_start__c = startDatetime, Call_Back_Window_end__c = endDatetime, OwnerId=currentUserId);
        insert task;

        Test.startTest();
            User_Availability__c uv = new User_Availability__c(Date__c=d, Unique_Id__c=(currentUserId+'#'+d), Available_Calls_Morning_Slot__c = 4, Available_Calls_Afternoon_Slot__c = 4, OwnerId=currentUserId);
            insert uv;
            uv = [Select Id, Date__c, Unique_Id__c, Scheduled_Calls_Morning_Slot__c, Scheduled_Calls_Afternoon_Slot__c From User_Availability__c Where Id =: uv.Id];
            System.assertEquals(1, uv.Scheduled_Calls_Morning_Slot__c);
            System.assertEquals(1, uv.Scheduled_Calls_Afternoon_Slot__c);

            task.Update_User_Availability__c = true;
            update task;
            uv = [Select Id, Date__c, Unique_Id__c, Scheduled_Calls_Morning_Slot__c, Scheduled_Calls_Afternoon_Slot__c From User_Availability__c Where Id =: uv.Id];
            System.assertEquals(2, uv.Scheduled_Calls_Morning_Slot__c);
            System.assertEquals(1, uv.Scheduled_Calls_Afternoon_Slot__c);

            delete bobSeller1;
            uv = [Select Id, Date__c, Unique_Id__c, Scheduled_Calls_Morning_Slot__c, Scheduled_Calls_Afternoon_Slot__c From User_Availability__c Where Id =: uv.Id];
            System.assertEquals(2, uv.Scheduled_Calls_Morning_Slot__c);
            System.assertEquals(null, uv.Scheduled_Calls_Afternoon_Slot__c);
        Test.stopTest();
    }

}