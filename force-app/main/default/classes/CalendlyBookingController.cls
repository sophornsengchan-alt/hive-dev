/*********************************************************************************************************************************
@ Class:          CalendlyBookingController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.07.2023 / Acmatac Seing / US-0013589 - Language localizations and referrer reporting for Bookings
@               27.07.2023 / Acmatac Seing / US-0013943 - Bookings - error on the page
*********************************************************************************************************************************/
public with sharing class CalendlyBookingController {

    public String calendlyURL{get;set;}
    private User currentUser;
    private String userRevRollup;

    // 04.07.2023 / Acmatac Seing / US-0013589
    public String label_MyAppointment {
        get{
            return Label.get('', 'MyAppointment', userRevRollup);
        }
    }
    // 04.07.2023 / Acmatac Seing / US-0013589
    public String label_Reschedule {
        get{
            return Label.get('', 'Reschedule', userRevRollup);
        }
    }
    // 04.07.2023 / Acmatac Seing / US-0013589
    public String label_CancelBooking {
        get{
            return Label.get('', 'CancelBooking', userRevRollup);
        }
    }

    public CalendlyBookingController() {
        initCalendlyURL();
    }

    /*********************************************************************************************************************************
    @ Method:          initCalendlyURL
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.07.2023 / Acmatac Seing / US-0013589 - Language localizations and referrer reporting for Bookings
    @               25.07.2023 / Acmatac Seing / US-0013590 - Email notifications for Bookings
    *********************************************************************************************************************************/
    private void initCalendlyURL() {
        
        // currentUser = [SELECT Id, Contact.Account.EBH_RevRollup__c, contactId, contact.email, contact.name, contact.account.EBH_OracleID__c,contact.account.name, contact.phone, contact.account.Brand_Engagement_Lead__c, contact.account.Brand_Engagement_Lead__r.calendly__calendlylink__c FROM user WHERE id = :userInfo.getUserId()];        
        for(User oUs :(User[]) WithoutSharing.doQuery('SELECT Id, Contact.Account.EBH_RevRollup__c, contactId, contact.email, contact.name, contact.account.EBH_OracleID__c,contact.account.name, contact.phone, contact.account.Brand_Engagement_Lead__c, contact.account.Brand_Engagement_Lead__r.calendly__calendlylink__c FROM user', ' WHERE id ='+ApexUtil.closeSQoute(userInfo.getUserId()),'')){
            currentUser = oUs;  
        }
        if(String.isNotBlank(currentUser.Contact.Account.EBH_RevRollup__c)){
            userRevRollup = currentUser.Contact.Account.EBH_RevRollup__c;
        }
        else{
            // 04.07.2023 / Acmatac Seing / US-0013589
            // if account.revrollup is blank default is US
            userRevRollup = 'US';
        }

        if (currentUser.contact != null && currentUser.contact.account != null && currentUser.contact.account.brand_engagement_lead__c != null && currentUser.contact.account.brand_engagement_lead__r.calendly__calendlylink__c != null)  {
                
            //String cal = '30-minutes-session-on-promoted-listings';
            String qs = '?email=' + currentUser.contact.email + '&name=' + currentUser.contact.name + '&a1=' + currentUser.contact.account.name + '&a2=' + (currentUser.contact.phone==null?'': currentUser.contact.phone) + '&a4=' + currentUser.contactId
                        + '&utm_source=' + currentUser.Id // 25.07.2023 / Acmatac Seing / US-0013590
                        + '&utm_campaign=bookings' // 25.07.2023 / Acmatac Seing / US-0013590
                        + '&utm_term=' + currentUser.contactId; // 25.07.2023 / Acmatac Seing / US-0013590
            calendlyURL = currentUser.contact.account.brand_engagement_lead__r.calendly__calendlylink__c + qs;
            // calendlyURL = JSON.serialize(currentUser)+currentUser.contact.account.brand_engagement_lead__r.calendly__calendlylink__c + qs;
            
        }
    }
    /*********************************************************************************************************************************
    @ Method:          getEvents
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.07.2023 / Acmatac Seing / US-0013943 - Bookings - error on the page
    *********************************************************************************************************************************/
    public List<EventWrapper> getEvents() {
        currentUser = [SELECT Id, Contact.Account.EBH_RevRollup__c, contact.email, contact.name, contact.account.Brand_Engagement_Lead__r.email, contact.account.EBH_OracleID__c,contact.account.name, contact.phone FROM user WHERE id = :userInfo.getUserId()];
        List<EventWrapper> events = new List<EventWrapper>();
        // for (Event e : [SELECT Id, Subject, StartDateTime, isCancelled__c, calendly_event_uuid__c,Calendly__InviteeUuid__c, ownerid, owner.id, owner.firstname, owner.lastname, Request_Description__c  FROM Event WHERE calendly_event_uuid__c != null AND whoId = :currentUser.contactID AND startDateTime > :System.now() ORDER BY startDateTime]) {
        for (Event e : (Event[]) WithoutSharing.doQuery('SELECT Id, Subject, StartDateTime, isCancelled__c, calendly_event_uuid__c,Calendly__InviteeUuid__c, ownerid, owner.id, owner.firstname, owner.lastname, Request_Description__c  FROM Event ', 'WHERE calendly_event_uuid__c != null AND whoId ='+ApexUtil.closeSQoute(currentUser.contactID)+' AND startDateTime > TODAY ORDER BY startDateTime','')) {
          events.add(new EventWrapper(e, userRevRollup));
        }
        return events;
    }

    @RemoteAction
    public static PageReference setUserTimeZone(String userTimeZone) {
        if (userTimeZone != String.valueOf(userInfo.getTimeZone())) {
            User u = new User(id=userInfo.getUserID(), TimeZoneSidKey=userTimeZone);
            update u;
        }
        return null;
    }

    public PageReference setCalendlyURL() {
        String id   = ApexPages.currentPage().getParameters().get('id');  
        String type = ApexPages.currentPage().getParameters().get('type');  
        if (type == 'Cancel') {
            calendlyURL = label.Bookings_Calendly_Cancellation_URL + id;
        } else if (type == 'Reschedule'){
            calendlyURL = label.Bookings_Calendly_Reschedule_URL + id;            
        } else {
            calendlyURL = '/apex/CalendlyShowEventDetails?' + id;            
        }
        return null;
    }

    public PageReference rerenderPage() {
        initCalendlyURL();
        return null;
    }
 
public class EventWrapper {
    public String calendly_event_uuid {get; private set;}
    public String calendly_invitee_uuid {get; private set;}
    public String subject {get; private set;}
    public String startDateTime {get; private set;}
    public String eventName {get; private set;}
    public Boolean isCancelled {get; private set;}

    EventWrapper(Event e, String revRollup) {
        this.subject = e.subject;
        // 04.07.2023 / Acmatac Seing / US-0013589 - If RevRollup US show 'M/d/yyyy'
        this.startDateTime = e.startDateTime.format('E') + ' ' + (revRollup == 'US' ? e.startDateTime.format('M/d/yyyy') : e.startDateTime.format());
        // this.startDateTime = e.startDateTime.format('E') + ' ' + e.startDateTime.format();
        this.calendly_event_uuid = e.calendly_event_uuid__c;
        this.calendly_invitee_uuid = e.Calendly__InviteeUuid__c;
        this.eventName = '<b>'+(e.owner.firstname == null?'':e.owner.firstname)+ ' ' + e.owner.lastname+ '</b><br/>' + (e.Request_Description__c == null?'':e.Request_Description__c);
        isCancelled = e.iscancelled__c;
    }
}



}