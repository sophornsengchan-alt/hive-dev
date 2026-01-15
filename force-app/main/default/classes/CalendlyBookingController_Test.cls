@isTest
private class CalendlyBookingController_Test {
    @isTest
    public static void testCalendlyURL() {

        byPass__c bypass = new byPass__c(byPass_WFRule__c=true, setupOwnerid=userInfo.getUserId());
        insert bypass;

        User brandEngagementUser = new User(id=userInfo.getUserID(), Calendly__CalendlyLink__c='https://calendly.com/test-test');
        update brandEngagementUser;

        Account a = new Account(name='TEST', brand_engagement_lead__c=userInfo.getUserId(), SP_Main_Domain__c = SEP_Helper.SEP_Domain_DE);
        insert a;

        Contact c = new Contact (lastname='TEST', accountID=a.id, email='test@test.com');
        insert c;

        Event e = new Event(whoID=c.id, subject='TEST', calendly_event_uuid__c='TEST', startDateTime=System.now().addDays(1),DurationInMinutes=30);
        insert e;

        /* MN-11062024-US-0015298
        Profile p = [SELECT id FROM profile WHERE name = 'DE - Seller Portal'];

        User portalUser = new User (username='test@test.com', email='test@test.com', contactID=c.id, lastName='Test', Alias='Test', TimeZoneSidKey='Europe/Berlin', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', ProfileId=p.id, LanguageLocaleKey='en_US');
        insert portalUser;
        */

        User portalUser = SEPTestGenerator.createSEPUser('sepDEcbc1', c.id); //MN-11062024-US-0015298

        System.runAs(portalUser) {

            // Test Initialization
            CalendlyBookingController cbc = new CalendlyBookingController();
            System.assert(cbc.calendlyURL != null);
            System.assert(cbc.calendlyURL.contains('https://calendly.com/test-test'));
            System.assert(cbc.calendlyURL.contains('test@test.com'));

            // Test Get Events
            List<CalendlyBookingController.EventWrapper> events = cbc.getEvents();
            System.assertEquals(1, events.size());

            // Test setCalendlyURL - cancel
            ApexPages.currentPage().getParameters().put('id', e.id);  
            ApexPages.currentPage().getParameters().put('type', 'Cancel');  
            cbc.setCalendlyUrl();
            System.assertEquals(Label.Bookings_Calendly_Cancellation_URL + e.id, cbc.calendlyURL);

            // Test setCalendlyURL - reschedule
            ApexPages.currentPage().getParameters().put('id', e.id);  
            ApexPages.currentPage().getParameters().put('type', 'Reschedule');  
            cbc.setCalendlyUrl();
            System.assertEquals(Label.Bookings_Calendly_Reschedule_URL + e.id, cbc.calendlyURL);

            // Test setCalendlyURL - other
            ApexPages.currentPage().getParameters().put('id', e.id);  
            ApexPages.currentPage().getParameters().put('type', 'View');  
            cbc.setCalendlyUrl();
            System.assertEquals('/apex/CalendlyShowEventDetails?' + e.id, cbc.calendlyURL);

            // Test setUserTimeZone
            String tz;
            if (userInfo.getTimeZone().toString()=='America/Los_Angeles') {
                tz = 'Europe/Berlin';                
            } else {
                tz = 'America/Los_Angeles';
            }
            CalendlyBookingController.setUserTimeZone(tz);
            System.assertEquals(tz, userInfo.getTimeZone().toString());

            // Test rerenderPage
            cbc.rerenderPage();
            System.assert(cbc.calendlyURL != null);
            System.assert(cbc.calendlyURL.contains('https://calendly.com/test-test'));
            System.assert(cbc.calendlyURL.contains('test@test.com'));




        }


    }
}