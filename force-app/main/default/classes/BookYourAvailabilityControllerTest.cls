/*********************************************************************************************************************************
@ Class:          BookYourAvailabilityController
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        US-0009691 - [Pro-Trader] Capability for Advisors to book available slots weekly
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.06.2021 / Mony Nou / Created the class.
*********************************************************************************************************************************/

@isTest
private class BookYourAvailabilityControllerTest {
    private static Date d;
    static void setupData(){

        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',UserAvailabilityTrigger__c = true, EBH_TaskTrigger__c = true);

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


        d = Date.today();
        Datetime dt = (DateTime)d;
        String dow = dt.format('EEEE');
        if (dow == 'Saturday') d = Date.today().addDays(3);
        else if (dow == 'Sunday') d = Date.today().addDays(2);
        
        BOB_Seller__c bobSeller = new BOB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLTTM.Id ,
            BOB__c=bob.Id, 
            Seller__c=seller.Id,
            Next_Call_Schedule_Date__c = d,
            Time_Slot__c = 'Morning (9 AM to 12 PM)',
            Account_Manager__c = UserInfo.getUserId()
        );
        
        BOB_Seller__c bobSeller1 = new BOB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLTTM.Id ,
            BOB__c=bob.Id, 
            Seller__c=seller1.Id,
            Next_Call_Schedule_Date__c = d,
            Time_Slot__c = 'Afternoon(1 PM to 5 PM)',
            Account_Manager__c = UserInfo.getUserId()
        );
        insert new List<BOB_Seller__c>{bobSeller, bobSeller1};

        bobSeller.Account_Manager__c = UserInfo.getUserId();
        bobSeller1.Account_Manager__c = UserInfo.getUserId();
        update new List<BOB_Seller__c>{bobSeller, bobSeller1};

    }

    @isTest
    static void test_apexInit() {

        setupData();
        
        Test.startTest();

            
            Map<String,Object> result = BookYourAvailabilityController.apexInit();

            System.debug('### result :: ' + result);

            System.assert(result != null);

        Test.stopTest();
    }

    @isTest
    static void test_getNextPrevWeeklyUserAvailability() {

        setupData();
        
        Test.startTest();

            
            Map<String,Object> result = BookYourAvailabilityController.getNextPrevWeeklyUserAvailability(d, 'PREV');

            System.debug('### result :: ' + result);

            System.assert(result != null);

        Test.stopTest();
    }
    
    @isTest
    static void test_createUserAvailabilityRecords() {

        setupData();
        
        Test.startTest();

            Map<String,Object> result = BookYourAvailabilityController.apexInit();
            
            String jsonUAW = JSON.serialize(result.get('user_availability'));
            
            result = BookYourAvailabilityController.createUserAvailabilityRecords(jsonUAW);

            System.debug('### result :: ' + result);

            System.assert(result != null);

        Test.stopTest();
    }
}