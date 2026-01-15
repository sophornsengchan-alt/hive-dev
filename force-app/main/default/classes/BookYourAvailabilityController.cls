/*********************************************************************************************************************************
@ Class:         BookYourAvailabilityController
@ Version:       1.0
@ Author:        Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:       US-0009691 - [Pro-Trader] Capability for Advisors to book available slots weekly
@                   - Controller Class for BookYourAvailability Lightning Component
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  	24.06.2021 / Mony Nou (mony.nou@gaea-sys.com) / Created the class.
@                   25.06.2021 / Mony Nou (mony.nou@gaea-sys.com) / US-0009738 - [Pro-Trader] Automation to calculate "Scheduled Calls Morning ","Scheduled Calls Afternoon"
@                   11.10.2021/ vadhanak voun (vadhanak.voun@gaea-sys.com) / US-0010468 - [PT]System will default 4 as Availability on Page Load where no availability exists
@                   22.10.2021 / Mony Nou (mony.nou@gaea-sys.com) / US-0010693 - [PT] Hypercare - User availability record is duplicated when an entry already exists which was created by Leads from the user availability Tab
@                   15.07.2022/ Sophal Noch (sophal.noch@gaea-sys.com) / US-0011996 - Call booking for Ads
*********************************************************************************************************************************/
public without sharing class BookYourAvailabilityController {

    private static String       BOBSELLER_TIMESLOT_MOR = 'Morning (9 AM to 12 PM)';
    private static String       BOBSELLER_TIMESLOT_AFT = 'Afternoon(1 PM to 5 PM)';
    private static Set<String>  BOBSELLER_TIMESLOT = new Set<String>{BOBSELLER_TIMESLOT_MOR,BOBSELLER_TIMESLOT_AFT};
    private static Set<String>  BOB_MANAGEDTYPE = new Set<String> {'LTTM Managed'};
    private static String       BOB_ACTIVESTATUS = 'BoB Active';
    private static String       BOB_RECORDTYPELTTC = 'Light_Touch_Category_Cohort';

    private static String       FNAME_SC_MRN_SLOT = 'Scheduled_Calls_Morning_Slot__c';
    private static String       FNAME_SC_AFT_SLOT = 'Scheduled_Calls_Afternoon_Slot__c';

    private final static Integer DEFAULT_SLOT_NUM = 4;

    @AuraEnabled
    public static Map<String,Object> apexInit() {	
        
        Map<String,Object> mapResult = new Map<String,Object>();
        mapResult.put('status', 'ok');

        try {
            List<UserAvailabilityWrapper> lstUAW = generateWeeklyUserAvailability(Date.today());
            mapResult.put('user_availability', lstUAW);
            
        }catch(Exception ex) { mapResult.put('status', 'ko'); mapResult.put('errorMsg', ex.getMessage()); }
        
        
        return mapResult;

    }   

    @AuraEnabled
    public static Map<String,Object> getNextPrevWeeklyUserAvailability(Date curDate, String mode) {	
        
        Map<String,Object> mapResult = new Map<String,Object>();
        mapResult.put('status', 'ok');

        try {

            curDate = (mode.equals('PREV'))?curDate.addDays(-1):curDate.addDays(1);

            List<UserAvailabilityWrapper> lstUAW = generateWeeklyUserAvailability(curDate);

            mapResult.put('user_availability', lstUAW);
            
        }catch(Exception ex) { mapResult.put('status', 'ko'); mapResult.put('errorMsg', ex.getMessage()); }
        
        
        return mapResult;

    }  

    @AuraEnabled
    public static Map<String,Object> createUserAvailabilityRecords(String jsonUAW) {	
        
        Map<String,Object> mapResult = new Map<String,Object>();

        mapResult.put('status', 'ok');

        try {

            List<UserAvailabilityWrapper> lstUAW = (List<UserAvailabilityWrapper>) JSON.deserialize(jsonUAW, List<UserAvailabilityWrapper>.class);

            List<User_Availability__c> lstUA = new List<User_Availability__c>();

            for (UserAvailabilityWrapper uaw : lstUAW) {
                if (uaw.isWeekend) continue;

                // 15.07.2022/ Sophal Noch / US-0011996 : remove the update to Scheduled_Calls_Morning_Slot__c and Scheduled_Calls_Afternoon_Slot__c because we use trigger to handler it now
                Map<String, Object> uaFields = (Map<String, Object>) JSON.deserializeUntyped( JSON.serialize( uaw.usr_avail ) );
                uaFields.remove(FNAME_SC_MRN_SLOT);
                uaFields.remove(FNAME_SC_AFT_SLOT);
                uaw.usr_avail = (User_Availability__c) JSON.deserialize( JSON.serialize( uaFields ), User_Availability__c.class );

                User_Availability__c ua = uaw.usr_avail;

                if (String.isBlank(ua.Id)) ua.Date__c = uaw.d;
                if (String.isBlank(ua.Unique_Id__c)) ua.Unique_Id__c = UserInfo.getUserId() +'#' + uaw.d;
                
                //Check if it just a blank record => skip it
                // if (!isBlankRecord(ua)) lstUA.add(ua); //MN-22102021-US-0010693 
                lstUA.add(ua); //MN-22102021-US-0010693 
            }

            upsert lstUA Unique_Id__c;

            //NK:14/10/2021: US-0010468.
            //get the Name/detail (e.g. new saved to the table display)
            Map<Id,User_Availability__c> mapUA= new Map<Id,User_Availability__c>([SELECT Id,Name,Date__c, Available_Calls_Morning_Slot__c, Available_Calls_Afternoon_Slot__c
                        , Scheduled_Calls_Morning_Slot__c, Scheduled_Calls_Afternoon_Slot__c, Unique_Id__c 
                        FROM User_Availability__c WHERE Id IN:lstUA]);

            for (UserAvailabilityWrapper uaw : lstUAW) 
            {
                if (uaw.isWeekend) continue;
                uaw.usr_avail = mapUA.get(uaw.usr_avail.Id);
            }

            mapResult.put('user_availability', lstUAW);

        }catch(Exception ex) { mapResult.put('status', 'ko'); mapResult.put('errorMsg', ex.getMessage()); }

        
        
        return mapResult;

    } 

    private static List<UserAvailabilityWrapper> generateWeeklyUserAvailability(Date curDateOfWeek) {

        List<UserAvailabilityWrapper> lstTmp = new List<UserAvailabilityWrapper>();

        if (curDateOfWeek != null) {

            //Get Start Date of current week
            Date sow = curDateOfWeek.toStartofWeek(); 
            
            //Get End Date of current week
            Date eow =  sow.addDays(6);

            /* MN-25062021-US-0009738 
                - Calculate Schedule Slot for Current Login User who is BoB_Seller__c.Account_Manager__c group by BoB_Seller__c.Next_Call_Schedule_Date__c and BoB_Seller__c.Time_Slot__c
                    - We will calculate by finding Next_Call_Schedule_Date__c within the 7 days of the week that display on BookYourAvailability Screen 
            */

           /* 15.07.2022/ Sophal Noch / US-0011996 : comment out because we use bob seller and task now.

                // Map<Date, Map<String, Integer>> mBoBSellerScheduledSlot = new Map<Date, Map<String, Integer>>();

                // for (AggregateResult agg : [SELECT Count(id) no_rows, Time_Slot__c ts, Next_Call_Schedule_Date__c ncsd FROM BoB_Seller__c 
                //                             WHERE BoB__r.RecordType.DeveloperName =:BOB_RECORDTYPELTTC AND BoB__r.Managed_Type__c IN:BOB_MANAGEDTYPE AND BoB__r.Status__c =:BOB_ACTIVESTATUS 
                //                                 AND Account_Manager__c =:UserInfo.getUserId()  and Time_Slot__c IN:BOBSELLER_TIMESLOT 
                //                                 AND Next_Call_Schedule_Date__c>=:sow AND Next_Call_Schedule_Date__c<=:eow
                //                                 GROUP BY Time_Slot__c, Next_Call_Schedule_Date__c]) {
                    
                //     Date d = (Date) agg.get('ncsd');
                //     String t_slot = (String) agg.get('ts');
                //     Integer no_rows = (Integer) agg.get('no_rows');

                //     if (!mBoBSellerScheduledSlot.containsKey(d)) mBoBSellerScheduledSlot.put(d, new Map<String, Integer>{BOBSELLER_TIMESLOT_MOR => 0, BOBSELLER_TIMESLOT_AFT => 0});
                //     mBoBSellerScheduledSlot.get(d).put(t_slot, no_rows);

                // }

            */


            Map<Date, User_Availability__c> mExistedUsrAvail = new Map<Date, User_Availability__c>();
            for (User_Availability__c ua : [SELECT Id,Name,Date__c, Available_Calls_Morning_Slot__c, Available_Calls_Afternoon_Slot__c
                                                , Scheduled_Calls_Morning_Slot__c, Scheduled_Calls_Afternoon_Slot__c, Unique_Id__c 
                                                FROM User_Availability__c 
                                                // WHERE Unique_Id__c <> NULL AND CreatedById=:UserInfo.getUserId() AND Date__c >=:sow AND Date__c <=:eow]) { //MN-22102021-US-0010693
                                                WHERE OwnerId=:UserInfo.getUserId() AND Date__c >=:sow AND Date__c <=:eow]) { //MN-22102021-US-0010693 - Pull existed records based on OwnerId field instead since now other user able to create UA record for someone else
                mExistedUsrAvail.put(ua.Date__c, ua);
            }

            // 15.07.2022/ Sophal Noch / US-0011996 :
            Map<String, User_Availability__c> maUnqiueIdToUserAva = new Map<String, User_Availability__c>();
            User currentUser = ApexUtil.getCurrentUser();
            
            UserAvailabilityWrapper last_uaw;
            for (Date d = sow; d <= eow; d=d.addDays(1)) {

                UserAvailabilityWrapper uaw = new UserAvailabilityWrapper();
                
                /* 15.07.2022/ Sophal Noch / US-0011996 : comment out because we use bob seller and task now.

                    if (mExistedUsrAvail.containsKey(d)) uaw.usr_avail = mExistedUsrAvail.get(d);

                        //MN-25062021-US-0009738 - Assigned above calcuation of Schedule Slot into Scheduled_Calls_Morning_Slot__c & Scheduled_Calls_Afternoon_Slot__c
                        // if (mBoBSellerScheduledSlot.containsKey(d)) {
                        //     Integer tmp = mBoBSellerScheduledSlot.get(d).get(BOBSELLER_TIMESLOT_MOR);
                        //     if (tmp>0) uaw.usr_avail.Scheduled_Calls_Morning_Slot__c = tmp;
                            
                        //     tmp = mBoBSellerScheduledSlot.get(d).get(BOBSELLER_TIMESLOT_AFT);
                        //     if (tmp>0) uaw.usr_avail.Scheduled_Calls_Afternoon_Slot__c = tmp;
                        // }

                */

                
                if (mExistedUsrAvail.containsKey(d)){
                    uaw.usr_avail = mExistedUsrAvail.get(d);
                }else{
                   // 15.07.2022/ Sophal Noch / US-0011996 : store User_Availability__c that has not created yet to do calculate later
                    String uniqueId = UserAvailabilityTriggerHandler.createUniqueId(currentUser.Id, d);
                    maUnqiueIdToUserAva.put(uniqueId, uaw.usr_avail);
                }

                
                uaw.d = d;
                Datetime dt = (DateTime)d;
                uaw.dow = dt.format('EEEE',UserInfo.getTimeZone().getDisplayName());
                if (uaw.dow == 'Saturday' || uaw.dow == 'Sunday') uaw.isWeekend = true;

                //NK:11/10/2021:US-0010468
                uaw.usr_avail.Available_Calls_Morning_Slot__c = uaw.usr_avail.Available_Calls_Morning_Slot__c == null ? DEFAULT_SLOT_NUM : uaw.usr_avail.Available_Calls_Morning_Slot__c;
                uaw.usr_avail.Available_Calls_Afternoon_Slot__c = uaw.usr_avail.Available_Calls_Afternoon_Slot__c ==null? DEFAULT_SLOT_NUM: uaw.usr_avail.Available_Calls_Afternoon_Slot__c;

                lstTmp.add(uaw);

                
            }

            // 15.07.2022/ Sophal Noch / US-0011996 : reused method from UserAvailabilityTriggerHandler to handle slot calculation of User_Availability__c that has not created yet
            if(!maUnqiueIdToUserAva.isEmpty()){
                UserAvailabilityTriggerHandler.calculateAndUpdateSlots(maUnqiueIdToUserAva, sow, eow, new Set<Id>{currentUser.Id});
            }

            
        }
        

        return lstTmp;


    }
    
    /*//MN-22102021-US-0010693 - Based on story US-0010468 => there is no longer a blank record since we assigned default value to it so this method is no longer user
    private Static Boolean isBlankRecord(User_Availability__c rec) {
        Boolean tmp = false;

        if ( rec.Id == null
                && (rec.Scheduled_Calls_Morning_Slot__c     == null || rec.Scheduled_Calls_Morning_Slot__c == 0) 
                && (rec.Scheduled_Calls_Afternoon_Slot__c   == null || rec.Scheduled_Calls_Afternoon_Slot__c == 0)
                && (rec.Available_Calls_Morning_Slot__c     == null) 
                && (rec.Available_Calls_Afternoon_Slot__c   == null)) tmp = true;

        return tmp;
    }
    */


    class UserAvailabilityWrapper {
        
        @AuraEnabled
        public User_Availability__c usr_avail;

        @AuraEnabled
        public Date d; 

        @AuraEnabled
        public String dow;

        @AuraEnabled
        public Boolean isWeekend;

        public UserAvailabilityWrapper() {

            this.usr_avail = new User_Availability__c();
            this.isWeekend = false;
            
        }        
    }

}