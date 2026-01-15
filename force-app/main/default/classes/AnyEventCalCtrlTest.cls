/**
 * @description     Update test unit for more coverage above 75%
 * @modifiedDate    25/10/2021
 * @modifiedBy      Samnang MUONG
 */

//@isTest(seeAllData=true) Samnang MUONG: Comment see all data then create sample data
@isTest
public class AnyEventCalCtrlTest {

    @TestSetup
    static void makeData(){
      
        // create event for handle existing test methods
        Event e = new Event(StartDateTime=System.today(), EndDateTime = System.today()+5);
        insert e;

        // create seller (Account) 

        
        Account acc = new Account(SP_Deals__c='Full Access',SP_Coupons__c='Full Access',Name='Test Abc123',RecordTypeId = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller').Id,EBH_RevRollup__c='DE');
        insert acc;
        
        // create coupon 
        //String recIdCoupon = Schema.sObjectType.Coupon__c.getRecordTypeInfosByName().get('Seller / Category Based').getRecordTypeId();
        //LA-26-09-2023: US-0013980 - Retire Contract Template field on Coupon
        Coupon__c c = new Coupon__c(Coupon_Start_Time__c=System.Now().timeGmt(), Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), Coupon_Start_Date__c=System.Today(), Coupon_End_Date__c=System.Today().addDays(2),Main_Coupon_Site__c = 'ebay.de', Coupon_Co_invest_Type__c = 'Contra');
        insert c;

        // create coupon seller
        Coupon_Seller__c cs = new Coupon_Seller__c(Coupon__c = c.Id, Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED, Seller__c=acc.Id);
        insert cs;

        // create deal retail campaign
        RecordType rt_DRC_Window = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', 'Deal_Campaign_V2');
        EBH_DealRetailCampaign__c d = new EBH_DealRetailCampaign__c(EBH_DealTitle__c='test title',Focus_Categories__c = 'Electronics', EBH_Date__c = System.today(), EPH_EndDate__c = System.today()+1, EBH_Country__c = '0',RecordTypeId = rt_DRC_Window.Id);
        insert d;
        
		User admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(admins)
        {
            /* MN-10062024-US-0015298
            RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
            Account portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id,
                SP_Deals__c = 'Full Access'
            );
            insert portalAccount1;
            */

            Account portalAccountNA = SEPTestGenerator.createSeller('Portal Seller NA 001', SEP_Helper.SEP_Domain_NA, 'Full Access', null, null);
            Account portalAccountNA_2 = SEPTestGenerator.createSeller('Portal Seller NA 002', SEP_Helper.SEP_Domain_NA, 'Full Access', null, null);

            RecordType recSP = ApexUtil.getRecordTypeByName('Contact', 'Seller_Portal');
            Contact contact1 = new Contact(
                FirstName = 'Test1111111111',
                Lastname = 'AMT_TEST',
                AccountId = portalAccountNA.Id,
                Email = System.now().millisecond() + 'test1@test.com',
                RecordTypeId=recSP.Id
            );
            insert contact1;

            AccountContactRelation acr =  new AccountContactRelation(ContactId=contact1.Id,AccountId=portalAccountNA_2.Id,IsActive=True);
            insert acr;

            //Create user
            /* MN-10062024-US-0015298
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'NA - Seller Portal' LIMIT 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test1111',
                Email = 'test1111@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'AMT_TEST',
                CommunityNickname = 'test1111',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            insert new User[]{user1};
            */

            User user1 = SEPTestGenerator.createSEPUser('sepNAaecc1', contact1.Id);

            for(PermissionSetGroup psg : [select Id, Status from PermissionSetGroup where DeveloperName IN ('Seller_Portal_NA')]){
                // force calculation of the PSG if it is not already Updated
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }

                insert new PermissionSetAssignment(AssigneeId=user1.Id,PermissionSetGroupId=psg.Id);
            }

        } 
    }

    @isTest static void test_getCoupan() {
        AnyEventCalCtrl.getCoupan('Coupon_Seller__c', 'Coupon_Start_Date__c', 'Coupon_End_Date__c', 'EBH_DealRetailCampaign__c');
    }
    
    //TH:04/05/2022:US-0011536
/*static testMethod void getEventsTest() {
        AnyEventCalCtrl.getEvents('Event', 'Subject', 'StartDateTime', 'EndDateTime', 'Description', 'OwnerId', true);
        AnyEventCalCtrl.getEvents('Event', 'Subject', 'StartDateTime', 'EndDateTime', 'Description', 'OwnerId', false);
    }
    static testMethod void upsertEventsTest() {
        AnyEventCalCtrl.upsertEvents('{"title":"dasdsad","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Event', 'Subject', 'StartDateTime', 'EndDateTime', 'Description', 'OwnerId');
    	AnyEventCalCtrl.upsertEvents('{"id":"sadad","title":"dasdsad","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Event', 'Subject', 'StartDateTime', 'EndDateTime', 'Description', 'OwnerId');
    }
    static testMethod void deleteEventTest() {
        Event e = [SELECT Id FROM Event LIMIT 1];
        AnyEventCalCtrl.deleteEvent(e.Id, 'Event', 'Subject', 'StartDateTime', 'EndDateTime', 'Description', 'OwnerId');
    }
    static testMethod void crudSecurityTest() {
        AnyEventCalCtrl.isAccessible('Event');
        AnyEventCalCtrl.isAccessible('Event','Subject');
        AnyEventCalCtrl.isCreateable('Event');
        AnyEventCalCtrl.isDeletable('Event');
    }
*/
    @IsTest
    static void testGetCalendarItems(){  
        Test.startTest();

            //User[] userPortals = [Select Id From User Where Email='test1111@test.com']; //MN-10062024-US-0015298
            User[] userPortals = [Select Id From User Where Contact.FirstName = 'Test1111111111' Limit 1];//MN-10062024-US-0015298

            /*
            for(PermissionSetGroup psg : [select Id, Status from PermissionSetGroup where DeveloperName IN ('Seller_Portal_NA')]){
                // force calculation of the PSG if it is not already Updated
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }

                insert new PermissionSetAssignment(AssigneeId=userPortals[0].Id,PermissionSetGroupId=psg.Id);
            }
            */

            System.runAs(userPortals[0])
            {
                List<Object> listCal = AnyEventCalCtrl.getCalendarItems(Datetime.now().format('YYYY-MM-dd'), Datetime.now().format('YYYY-MM-dd'),new List<String>(),new List<String>{'EBH_DealRetailCampaign__c'},new List<String>(),'');
                System.assertEquals(false, listCal.isEmpty(),'setting with data');
            }
            
        Test.stopTest();
        /*Test.stopTest();

        Test.startTest();
        List<Object> listCal = AnyEventCalCtrl.getCalendarItems(Datetime.now().format('YYYY-MM-dd'), Datetime.now().format('YYYY-MM-dd'),new List<String>(),new List<String>{'EBH_DealRetailCampaign__c'},new List<String>());
            System.assertEquals(false, listCal.isEmpty(),'setting with data');

        Test.stopTest();*/
        
    }

    @IsTest
    static void testGetCalendarItems_withFiltering(){
        
        Test.startTest();
        
        //User[] userPortals = [Select Id From User Where Email='test1111@test.com'];//MN-10062024-US-0015298
        User[] userPortals = [Select Id From User Where Contact.FirstName = 'Test1111111111' Limit 1];//MN-10062024-US-0015298

        /*
        for(PermissionSetGroup psg : [select Id, Status from PermissionSetGroup where DeveloperName IN ('Seller_Portal_NA')]){
            // force calculation of the PSG if it is not already Updated
            if (psg.Status != 'Updated') {
                Test.calculatePermissionSetGroup(psg.Id);
            }

            insert new PermissionSetAssignment(AssigneeId=userPortals[0].Id,PermissionSetGroupId=psg.Id);
        }
        */
            System.runAs(userPortals[0])
            {
                String criteria = 'EPH_EndDate__c < TODAY';
                List<Object> listCal = AnyEventCalCtrl.getCalendarItems(Datetime.now().format('YYYY-MM-dd'), Datetime.now().format('YYYY-MM-dd'),new List<String>{criteria},new List<String>{'EBH_DealRetailCampaign__c'},new List<String>(),'');
                System.assertEquals(false, listCal.isEmpty(),'setting with data');
            }
        Test.stopTest();
        
    }

    @IsTest
    static void testfetchStatusFilterMetadata(){
        
        Test.startTest();
            
            List<Seller_Portal_Global_Variables__mdt> lstMeta = AnyEventCalCtrl.fetchStatusFilterMetadata('DECalendarFilter_Status','');
            System.assertEquals(false, lstMeta.isEmpty(),'setting with data');

        Test.stopTest();
        
    }

    @IsTest
    static void testinitLocalCode(){
        
        Test.startTest();
            
            String result = AnyEventCalCtrl.initLocalCode();
            System.assertEquals(false, String.isBlank(result),'there should be locale return.');

        Test.stopTest();
        
    }

    @IsTest
    static void testgetAccounts(){

        Test.startTest();
            
            //User[] userPortals = [Select Id From User Where Email='test12345@test.com']; //MN-10062024-US-0015298

            //START--MN-10062024-US-0015298
            Account acc = [SELECT Id FROM Account WHERE SP_Main_Domain__c =:SEP_Helper.SEP_Domain_NA limit 1]; 
            Contact con = [SELECT Id,Email FROM Contact WHERE AccountId=:acc.Id limit 1];
            User[] userPortals = [SELECT Id,name From User WHERE ContactId=:con.Id limit 1];
            //--END

            System.runAs(userPortals[0])
            {

                List<Account> lstAcc = AnyEventCalCtrl.getAccounts();
                
                System.assert(!lstAcc.isEmpty(), 'There should be records return.');
            }
            

        Test.stopTest();

        /* MN-10062024-US-0015298
        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];

        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        Account portalAccount1, portalAccount2;
        Contact contact1,contact2,contact3;
        System.runAs(admins[0])
        {
            //Create account
            portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id,
                SP_Deals__c = 'Full Access'
            );

            portalAccount2 = new Account(
                Name = 'test_seller007',
                eBay_API_User_Id__c = 'test_test_test2',
                RecordTypeId = recSeller.Id,
                SP_Deals__c = 'Full Access'
            );
            insert new List<Account>{portalAccount1, portalAccount2};
            RecordType recSP = ApexUtil.getRecordTypeByName('Contact', 'Seller_Portal');
            RecordType recDWH = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
            contact1 = new Contact(
                FirstName = 'Test1111111111',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test1@test.com',
                RecordTypeId=recSP.Id
            );
            contact2 = new Contact(
                FirstName = 'Test',
                Lastname = 'test con2',
                AccountId = portalAccount2.Id,
                Email = System.now().millisecond() + 'test2@test.com',
                RecordTypeId=recDWH.Id
            );
            insert new Contact[]{contact1,contact2};

            AccountContactRelation acr =  new AccountContactRelation(ContactId=contact1.Id,AccountId=portalAccount2.Id,IsActive=True);
            insert acr;
        }

        System.runAs(admins[1])
        {
            //Create user
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'NA - Seller Portal' LIMIT 1];
            Profile portalProfileDE = [SELECT Id FROM Profile WHERE Name = 'DE - Seller Portal' LIMIT 1];
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
                LanguageLocaleKey = 'en_US'
            );
            User user2 = new User(
                Username = System.now().millisecond() + 'test2@test.com',
                ContactId = contact2.Id,
                ProfileId = portalProfileDE.Id,
                Alias = 'test2',
                Email = 'test2@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Test2',
                CommunityNickname = 'test2',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            insert new User[]{user1,user2};
        }   
        */
        
    }


}