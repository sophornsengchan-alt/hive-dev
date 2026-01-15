@isTest
private class Subscription_Request_TriggerHandlerTest {
     
    @TestSetup
    static void makeData(){
        Test.startTest();

        EBH_TestDataFactory.setUpCustomSettings();

        Account acc = new Account( Name = 'TestAccount', EBH_StoreSubscription__c = 'Anchor', EBH_BOBManaged__c = true);//Basic
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;

        Test.stopTest();
    }

    @IsTest
    static void testPopulateFields(){
        


        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];
        //Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'DE - Seller Portal']; //MN-10062024-US-0015298
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];
        RecordType rt_AM = ApexUtil.getRecordTypeByName('Subscription_Request__c', 'Account_Manager');
        Subscription_Request__c s_request = new Subscription_Request__c
        (
            Request_Date__c =  Date.today(),
            //Opt_In_Date__c = Date.today().addMonths(1).toStartOfMonth(), 
            Opt_In_Effective_Date__c = Date.today().addDays(1),           
            Status__c = 'New',
            Requestor__c = con.Id ,
            Seller__c = acc.Id,
            CurrencyIsoCode = 'EUR',
            RecordTypeId  = rt_AM.Id

        );
        insert s_request;
        Test.startTest();
            s_request.Opt_In_Effective_Date__c = Date.today().addDays(2);
            update s_request;
            
            Subscription_Request__c r1 = [Select Id,Earliest_Unsubscribe_Date__c,Opt_In_Effective_Date__c from Subscription_Request__c Where Id=:s_request.Id];
            System.assert(r1.Earliest_Unsubscribe_Date__c <> null ,'Earliest_Unsubscribe_Date__c updated');

            s_request.Status__c = 'Subscribed';
            update s_request;
            r1 = [Select Id,Earliest_Unsubscribe_Date__c,Opt_In_Date__c from Subscription_Request__c Where Id=:s_request.Id];
            System.assert(r1.Opt_In_Date__c <> null ,'Opt_In_Date__c populated');

         
        Test.stopTest();
        
    }
    
    @IsTest
    static void testPopulateFieldsBaseOnSPDomain(){

        Account accDE = new Account( Name = 'TestAccount', SP_Main_Domain__c='wachstumsportal.ebay.de');
        insert accDE;

        Contact conDE = new Contact(FirstName='test fn', LastName='test ln', AccountId=accDE.Id, Email = 'test123@test.com');
        insert conDE;

        RecordType rt_AM = ApexUtil.getRecordTypeByName('Subscription_Request__c', 'Account_Manager');

        Subscription_Request__c s_requestDE = new Subscription_Request__c
        (
            Request_Date__c =  Date.today(), 
            Opt_In_Effective_Date__c = Date.today().addDays(1),           
            Status__c = 'New',
            Requestor__c = conDE.Id ,
            Seller__c = accDE.Id,
            RecordTypeId  = rt_AM.Id
        );
        insert s_requestDE;

        Account accUK = new Account( Name = 'TestAccount', SP_Main_Domain__c='sellerportal.ebay.co.uk');
        insert accUK;

        Contact conUK = new Contact(FirstName='test fn', LastName='test ln', AccountId=accUK.Id, Email = 'test123@test.com');
        insert conUK;

        Subscription_Request__c s_requestUK = new Subscription_Request__c
        (
            Request_Date__c =  Date.today(), 
            Opt_In_Effective_Date__c = Date.today().addDays(1),           
            Status__c = 'New',
            Requestor__c = conUK.Id ,
            Seller__c = accUK.Id,
            RecordTypeId  = rt_AM.Id
        );
        insert s_requestUK;

        Test.startTest();

        Subscription_Request__c subDE = [Select Id,Region__c,Monthly_Subscription_Fee__c, CurrencyIsoCode from Subscription_Request__c Where Id=:s_requestDE.Id];
        System.assertEquals(subDE.Region__c,'77');
        System.assertEquals(subDE.Monthly_Subscription_Fee__c,199);
        System.assertEquals(subDE.CurrencyIsoCode,'EUR');

        Subscription_Request__c subUK = [Select Id,Region__c,Monthly_Subscription_Fee__c, CurrencyIsoCode from Subscription_Request__c Where Id=:s_requestUK.Id];
        System.assertEquals(subUK.Region__c,'3');
        System.assertEquals(subUK.Monthly_Subscription_Fee__c,399);
        System.assertEquals(subUK.CurrencyIsoCode,'GBP');

        Test.stopTest();
    }
}