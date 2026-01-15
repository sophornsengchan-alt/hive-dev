/*********************************************************************************************************************************
@ Class:         UserAvailabilityTriggerHandler
@ Version:       1.0
@ Author:        Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:       US-0011996 - Call booking for Ads
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  15.07.2022 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
public with sharing class UserAvailabilityTriggerHandler {

    public static final String TRIGGERCONTROLLER  = 'EBH Trigger Controller'; // custom setting

    private static final String       BOBSELLER_TIMESLOT_MOR = 'Morning (9 AM to 12 PM)';
    private static final String       BOBSELLER_TIMESLOT_AFT = 'Afternoon(1 PM to 5 PM)';
    private static final Set<String>  BOBSELLER_TIMESLOT = new Set<String>{BOBSELLER_TIMESLOT_MOR,BOBSELLER_TIMESLOT_AFT};
    private static final Set<String>  BOB_MANAGEDTYPE = new Set<String> {'LTTM Managed'};
    private static final String       BOB_ACTIVESTATUS = 'BoB Active';
    private static final String       BOB_RECORDTYPELTTC = 'Light_Touch_Category_Cohort';
    
    private static final String       AGGR_FIELD_SCHEDULE_DATE = 'scheduleDate';
    private static final String       AGGR_FIELD_TIME_SLOT = 'timeSlot';
    private static final String       AGGR_FIELD_RECORD_COUNTS = 'recordCounts';
    private static final String       AGGR_FIELD_USER_ID = 'userId';
    private static final String       AGGR_FIELD_START_HOUR = 'startHour';
    private static final String       AGGR_FIELD_END_HOUR = 'endHour';

    private static final List<Integer> MORNING_TIMESLOTS{
        get{
            if(MORNING_TIMESLOTS == null){
                List<Integer> morningTimeSlots = new List<Integer>();
                for(String timeSlot : Label.UserAvailabilityMorningTimeSlots.split('-')){
                    morningTimeSlots.add(Integer.valueOf(timeSlot));
                }
                MORNING_TIMESLOTS = morningTimeSlots;
            }
            return MORNING_TIMESLOTS;
        }
        set;
    }
    private static final List<Integer> AFTERNOON_TIMESLOTS{
        get{
            if(AFTERNOON_TIMESLOTS == null){
                List<Integer> afternoonTimeSlots = new List<Integer>();
                for(String timeSlot : Label.UserAvailabilityAfternoonTimeSlots.split('-')){
                    afternoonTimeSlots.add(Integer.valueOf(timeSlot));
                }
                AFTERNOON_TIMESLOTS = afternoonTimeSlots;
            }
            return AFTERNOON_TIMESLOTS;
        }
        set;
    }


	/*****************************************************************************************************************************
    @ Method:   populateSchduleSlots
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  US-0011996 - Call booking for Ads
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      listNewUserAva = list of new User_Availability__c , mapOldUserAva = Map of old User_Availability__c
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.07.2022 / Sophal Noch / Created the  Method.
    *****************************************************************************************************************************/
    public static void populateSchduleSlots(List<User_Availability__c> listNewUserAva, Map<Id,User_Availability__c> mapOldUserAva) {

        Boolean isNew = mapOldUserAva == null ? true : false;

        Date minStartDate;
        Date maxEndDate;
        User currentUser = ApexUtil.getCurrentUser();
        Set<Id> setUserId = new Set<Id>();
        Map<String, User_Availability__c> mapUserAvaToPopulate = new  Map<String, User_Availability__c>();
       
        for(User_Availability__c userAva : listNewUserAva){

            if((String.isNotBlank(userAva.Unique_Id__c) && userAva.Date__c != null)
                && (isNew || (!isNew && (userAva.Date__c != mapOldUserAva.get(userAva.Id).Date__c || userAva.OwnerId != mapOldUserAva.get(userAva.Id).OwnerId)))
            ){
                if(minStartDate == null || minStartDate > userAva.Date__c) minStartDate = userAva.Date__c;
                if(maxEndDate == null || maxEndDate < userAva.Date__c) maxEndDate = userAva.Date__c;
                setUserId.add(userAva.OwnerId);
                
                // reset slot when date changed
                userAva.Scheduled_Calls_Morning_Slot__c = null;
                userAva.Scheduled_Calls_Afternoon_Slot__c = null;

                
                mapUserAvaToPopulate.put(userAva.Unique_Id__c, userAva);
            }
        }

        if(mapUserAvaToPopulate.isEmpty()) return;

        calculateAndUpdateSlots(mapUserAvaToPopulate, minStartDate, maxEndDate, setUserId);


    }

	/**********************************************************************************************************************************************************************************************************************
    @ Method:   calculateAndUpdateSlots
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  US-0011996 - Call booking for Ads
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      mapUserAvaToPopulate = map of Unique_Id__c to record User_Availability__c , minStartDate = mininum of Date__c in trigger,  maxEndDate = maximumn of Date__c in trigger, setUserId = set of user id
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.07.2022 / Sophal Noch / Created the  Method.
    ************************************************************************************************************************************************************************************************************************/    
    public static void calculateAndUpdateSlots(Map<String, User_Availability__c> mapUserAvaToPopulate, Date minStartDate, Date maxEndDate, Set<Id> setUserId){

        // this method is used in this class UserAvailabilityTriggerHandler and reused in class BookYourAvailabilityController

        for (AggregateResult agg : [SELECT Count(id) recordCounts, Time_Slot__c timeSlot, Next_Call_Schedule_Date__c scheduleDate, Account_Manager__c userId FROM BoB_Seller__c
            WHERE BoB__r.RecordType.DeveloperName =:BOB_RECORDTYPELTTC AND BoB__r.Managed_Type__c IN:BOB_MANAGEDTYPE AND BoB__r.Status__c =:BOB_ACTIVESTATUS
            AND Account_Manager__c IN: setUserId  and Time_Slot__c IN:BOBSELLER_TIMESLOT
            AND Next_Call_Schedule_Date__c>=:minStartDate AND Next_Call_Schedule_Date__c<=:maxEndDate
            GROUP BY Time_Slot__c, Next_Call_Schedule_Date__c, Account_Manager__c]
        ){
                
            Date scheduleDate = (Date) agg.get(AGGR_FIELD_SCHEDULE_DATE);
            String timeSlot = (String) agg.get(AGGR_FIELD_TIME_SLOT);
            Integer recordCounts = (Integer) agg.get(AGGR_FIELD_RECORD_COUNTS);
            String userId = (String) agg.get(AGGR_FIELD_USER_ID);

            String userAvaUniqueId = createUniqueId(userId,scheduleDate);

            User_Availability__c userAva = mapUserAvaToPopulate.get(userAvaUniqueId);

            if(userAva == null) continue;

            if(timeSlot == BOBSELLER_TIMESLOT_MOR) userAva.Scheduled_Calls_Morning_Slot__c = userAva.Scheduled_Calls_Morning_Slot__c != null ? (userAva.Scheduled_Calls_Morning_Slot__c + recordCounts) : recordCounts;
            if(timeSlot == BOBSELLER_TIMESLOT_AFT) userAva.Scheduled_Calls_Afternoon_Slot__c = userAva.Scheduled_Calls_Afternoon_Slot__c != null ? (userAva.Scheduled_Calls_Afternoon_Slot__c + recordCounts) : recordCounts;

        }

        // covert Dates to Datetimes of UTC zone because Task.Call_Back_Window_start__c and Task.Call_Back_Window_end__c are datetime field and store as UTC
        Datetime minStartDatetime = Datetime.newInstanceGmt(minStartDate.year(),minStartDate.month(), minStartDate.day(), 0, 0 ,0);
        Datetime maxEndDatetime = Datetime.newInstanceGmt(maxEndDate.year(),maxEndDate.month(), maxEndDate.day(), 23, 59 , 59);

        for(AggregateResult agg : [Select count(Id) recordCounts, Day_Only(Call_Back_Window_start__c) scheduleDate, HOUR_IN_DAY(Call_Back_Window_start__c) startHour, HOUR_IN_DAY(Call_Back_Window_end__c) endHour, OwnerId userId  From Task 
                Where OwnerId IN: setUserId AND Update_User_Availability__c = true AND Call_Back_Window_start__c != null AND Call_Back_Window_end__c != null 
                AND Call_Back_Window_start__c>=:minStartDatetime AND Call_Back_Window_end__c<=:maxEndDatetime GROUP BY Day_Only(Call_Back_Window_start__c), HOUR_IN_DAY(Call_Back_Window_start__c), HOUR_IN_DAY(Call_Back_Window_end__c), OwnerId]){

                Date scheduleDate = (Date) agg.get(AGGR_FIELD_SCHEDULE_DATE);
                Integer startHour = (Integer) agg.get(AGGR_FIELD_START_HOUR);
                Integer endHour = (Integer) agg.get(AGGR_FIELD_END_HOUR);
                Integer recordCounts = (Integer) agg.get(AGGR_FIELD_RECORD_COUNTS);
                String userId = (String) agg.get(AGGR_FIELD_USER_ID);

                String userAvaUniqueId = createUniqueId(userId,scheduleDate);


            User_Availability__c userAva = mapUserAvaToPopulate.get(userAvaUniqueId);
            if(userAva == null) continue;             
            
            // startHour must >= 8 && <= 11 for morning slot, // endHour must >= 12 && <= 16 for afternoon slot
            if(startHour >= MORNING_TIMESLOTS[0] && endHour <=MORNING_TIMESLOTS[1]){ userAva.Scheduled_Calls_Morning_Slot__c = userAva.Scheduled_Calls_Morning_Slot__c != null ? (userAva.Scheduled_Calls_Morning_Slot__c + recordCounts) : recordCounts;}
            else if(startHour >= AFTERNOON_TIMESLOTS[0] && endHour <= AFTERNOON_TIMESLOTS[1]){userAva.Scheduled_Calls_Afternoon_Slot__c = userAva.Scheduled_Calls_Afternoon_Slot__c != null ? (userAva.Scheduled_Calls_Afternoon_Slot__c + recordCounts) : recordCounts;}

        }

    }

    /**********************************************************************************************************************************************************************************************************************
    @ Method:   calculateAndUpdateSlots
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  US-0011996 - Call booking for Ads
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      userId = id of user that is owner of User_Availability__c , scheduleDate = Date__c value of User_Availability__c
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.07.2022 / Sophal Noch / Created the  Method.
    ************************************************************************************************************************************************************************************************************************/    
    public static String createUniqueId(Id userId, Date scheduleDate){
         // this method is used in this class UserAvailabilityTriggerHandler and reused in class BookYourAvailabilityController, BoBSellerTriggerHandler and EBH_TaskTriggerHandler
        return userId+'#'+scheduleDate;
    }

    /**********************************************************************************************************************************************************************************************************************
    @ Method:   calculateSlotsFromRelatedObj
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  US-0011996 - Call booking for Ads
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      setUniqueId = set user id from BoB_Seller__c.Account_Manager__c or Task.Owner , isFuture = flag for method is called from future method or not, allOrNone = flag to allow partial upsert or not when there are errors
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.07.2022 / Sophal Noch / Created the  Method.
    ************************************************************************************************************************************************************************************************************************/    
    public static void calculateSlotsFromRelatedObj(Set<String> setUniqueId, Boolean isFuture ,Boolean allOrNone){

        // this method is used other classes like BoBSellerTriggerHandler and EBH_TaskTriggerHandler

        Map<String, User_Availability__c> mapUserAvaToPopulate = new  Map<String, User_Availability__c>();

		Date minStartDate;
        Date maxEndDate;
        Set<Id> setUserId = new Set<Id>();

		for(User_Availability__c userAva : [Select Id, Unique_Id__c, Date__c, OwnerId, Scheduled_Calls_Morning_Slot__c, Scheduled_Calls_Afternoon_Slot__c From User_Availability__c Where Unique_Id__c IN : setUniqueId And Date__c != null]){
			if(minStartDate == null || minStartDate > userAva.Date__c) minStartDate = userAva.Date__c;
            if(maxEndDate == null || maxEndDate < userAva.Date__c) maxEndDate = userAva.Date__c;
			setUserId.add(userAva.OwnerId);

            // reset field before re-calculate
			userAva.Scheduled_Calls_Morning_Slot__c = null;
			userAva.Scheduled_Calls_Afternoon_Slot__c = null;

			mapUserAvaToPopulate.put(userAva.Unique_Id__c, userAva);
		}

		if(mapUserAvaToPopulate.isEmpty()) return;

        if(!isFuture){
            UserAvailabilityTriggerHandler.calculateAndUpdateSlots(mapUserAvaToPopulate, minStartDate, maxEndDate, setUserId);
        }else{ 
            try{ // use try-catch to avoid Record Lock Error just in case it happens When Query Related Object Records
                UserAvailabilityTriggerHandler.calculateAndUpdateSlots(mapUserAvaToPopulate, minStartDate, maxEndDate, setUserId);
            }catch(Exception e){EBH_ApexLogger.logError(new List<Exception>{e} , 'BoBSellerTriggerHandler','calculateSlotsFromRelatedObj'); return;} 
        }
        
        List<Database.UpsertResult> upsertResult = Database.upsert(mapUserAvaToPopulate.values(), User_Availability__c.Unique_Id__c, allOrNone);
        List<Database.Error> listException = new List<Database.Error>();
        for (Database.UpsertResult upRe : upsertResult) {
            if (!upRe.isSuccess()) listException.addAll(upRe.getErrors());
        }
        if(!listException.isEmpty()) EBH_ApexLogger.logError(listException, 'BoBSellerTriggerHandler','calculateSlotsFromRelatedObj');


	}



}