@isTest
private class SellerCommunicationTriggerHandlerTest {
    static RecordType EBAY_BOOKING_MEETING_SELLERCOM_RTID = ApexUtil.getRecordTypeByName('Seller_Communication__c', 'eBay_Bookings_Meetings');
    @testSetup
    private static void setup(){
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',Seller_Communication__c=true);
        
        Calendly__CalendlyAction__c cAction = new Calendly__CalendlyAction__c(
            Name = 'invitee.created',
            Calendly__EventCreatedAt__c = System.now(),
            Calendly__EventStartTime__c = System.now().addDays(2),
            Calendly__EventEndTime__c = System.now().addDays(5),
            Calendly__EventSubject__c = 'Test: Promoted Listings Consultation',
            Calendly__EventTypeDuration__c = 30,
            Calendly__EventUuid__c = 'abc-defg-afffds',
            Calendly__InviteeCreatedAt__c = System.now(),
            Calendly__InviteeEmail__c = 'testingabc@test.test',
            Calendly__EventPrimaryPublisherEmail__c = 'testingabc@test.test',
            Calendly__EventPrimaryPublisherName__c = 'AMT Test Publisher',
            Calendly__EventTypeKind__c = 'solo',
            Calendly__EventTypeName__c = 'Promoted Listings Consultation',
            Calendly__EventTypeSlug__c = 'promoted-listings-consultation',
            Calendly__InviteeUuid__c = 'abc-defg-afffds-uuid',
            Calendly__RequestId__c = 'abc-defg-afffds-requestid',
            Calendly__InviteeTimezone__c = 'Europe/London'
        );
        insert cAction;
        
        Seller_Communication__c scO = new Seller_Communication__c(
            Region__c = 'DE',
            Calendly_Action__c = cAction.id,
            recordTypeId = EBAY_BOOKING_MEETING_SELLERCOM_RTID.Id
        );
        insert scO;
    }

    @IsTest
    private static void test1(){
        Calendly__CalendlyAction__c ccAction = [SELECT Id FROM Calendly__CalendlyAction__c WHERE Name = 'invitee.created'];
        Seller_Communication__c scO = [SELECT Id,Calendly_EventStartTimeByRegion__c,Calendly_EventStartTime__c,Region__c,Calendly_Timezone__c FROM Seller_Communication__c WHERE Calendly_Action__c=:ccAction.Id];
        Test.startTest();
            System.assert(scO.Calendly_EventStartTimeByRegion__c == scO.Calendly_EventStartTime__c.format(SellerCommunicationTriggerHandler.mapRegionWithDateTimeFormat.get(scO.Region__c), scO.Calendly_Timezone__c)+' ('+scO.Calendly_Timezone__c+')');
        Test.stopTest();
        
    }

    @IsTest
    private static void test2(){
        Calendly__CalendlyAction__c ccAction = [SELECT Id FROM Calendly__CalendlyAction__c WHERE Name = 'invitee.created'];
        Seller_Communication__c scO = new Seller_Communication__c(
            Region__c = 'NA',
            Calendly_Action__c = ccAction.id,
            recordTypeId = EBAY_BOOKING_MEETING_SELLERCOM_RTID.Id
        );
        insert scO;

        Seller_Communication__c sc1 = [SELECT Id,Calendly_EventStartTimeByRegion__c,Calendly_EventStartTime__c,Region__c,Calendly_Timezone__c FROM Seller_Communication__c WHERE Id =: scO.Id];
        Test.startTest();
            System.assert(sc1.Calendly_EventStartTimeByRegion__c == sc1.Calendly_EventStartTime__c.format(SellerCommunicationTriggerHandler.mapRegionWithDateTimeFormat.get(sc1.Region__c), sc1.Calendly_Timezone__c)+' ('+sc1.Calendly_Timezone__c+')');
        Test.stopTest();
        
    }
}