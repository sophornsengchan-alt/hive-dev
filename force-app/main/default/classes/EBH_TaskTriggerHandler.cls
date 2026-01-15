/************************************************************************************************************************************************
@ Class:          EBH_TaskTriggerHandler
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Trigger Handler for EBH_TaskTrigger
EPH-3780: To capture response code on related Campaign Member with the help of Response on Task 
-------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.10.2017 / NEHA LUND / Created the class.
@ Change history: 10.01.2019 / David Herrero / Add 
@               : 25.09.23 / Bora Chhorn / US-0013984 - Create Seller Risk Management ticket from the Onboarding (2)
@               : 30.04.2024 / Acmatac Seing / US-0014978 - Remove sendEventAfterStartCallScript method and move it to Epilogue Flow
@               : 10/09/2025 / vadhaank voun / US-0033124 - Genesys - Start Call Script from Task
************************************************************************************************************************************************/

public with sharing class EBH_TaskTriggerHandler {
  private final static String PROJ_EXTERNAL_PREFIX = 'PRJ_FF-';
  private final static String TASK_COMPLETED_STATUS = 'Completed';
  /********************************************************************************************************************************************
@ Method:         captureUrgencyAccountID
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        EPH-4122: When the urgency task is created then account Id will be mapped to custom account field
- For Email templates and populating comments for Task using urgency action and urgency reason
---------------------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Passed through the Task Trigger
---------------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.10.2017 / NEHA LUND / Created the  Method.
@ Change history: 25.10.2018 / David Herrero /  modify the method for populating the field AccountId with the whatid in case of account, of whatid.accountid in case of contact
@               : 15.10.2020 / Vadhanak Voun/ US-0008206 - [LTTM Plus] Campaign Code to be mandated and Cohort Seller Comments ,DMC, SR# to be recorded in Activities
@                                           /ignore the log task; so seller get pouplated from Initiate Call
@               : 25.09.23 / Bora Chhorn / US-0013984 - Create Seller Risk Management ticket from the Onboarding (2)
********************************************************************************************************************************************/
  public static void captureUrgencyAccountID(List<Task> tasks) {
    Set<ID> accountIds = new Set<ID>();
    map<id, Contact> mapContacts = new Map<id, Contact>();
    Set<ID> contactIds = new Set<ID>();
    String saux = '';
    for (task t : tasks) {
      if (!String.isEmpty(t.whoid) && !t.Log_Task__c) {
        //NK:15/10/2020:US-0008206
        if (('' + t.whoid).startswith('003')) {
          contactIds.add(t.whoid);
        }
      }
    }
    if (!contactIds.isEmpty()) {
      for (Contact c : [
        SELECT id, accountid
        FROM contact
        WHERE id IN :contactids
      ]) {
        mapContacts.put(c.id, c);
      }
    }

    for (Task tsk : tasks) {
      if (tsk.Log_Task__c)
        continue; //NK:15/10/2020:US-0008206
      if (tsk.subject == EBH_ConstantsUtility.TTH_URGENCYTASK) {
        tsk.EBH_Account__c = tsk.WhatId;
        accountIds.add(tsk.WhatId);
      }
      // BR-25-09-23-US-0013984
      else if (tsk.AccountId != null && tsk.EBH_Account__c == null) {
        tsk.EBH_Account__c = tsk.AccountId;
        // accountIds.add(tsk.AccountId); // BR-25-09-23-US-0013984
      }

      if (null != tsk.WhatId && ('' + tsk.whatId).startswith('001')) {
        tsk.EBH_Account__c = tsk.WhatId;
      } else if (
        null != tsk.whoid &&
        !mapContacts.isEmpty() &&
        mapContacts.containsKey(tsk.whoid)
      ) {
        tsk.EBH_Account__c = mapContacts.get(tsk.whoid).AccountID;
      }
    }

    if (!accountIds.isEmpty()) {
      Account accRecord;
      Map<ID, Account> accountMap = new Map<ID, Account>(
        (List<Account>) Database.query(EBH_ConstantsUtility.TTH_ACCQUERY)
      );

      for (Task tsk : tasks) {
        if (
          tsk.subject == EBH_ConstantsUtility.TTH_URGENCYTASK &&
          accountMap.containsKey(tsk.WhatId)
        ) {
          tsk.Description = EBH_ConstantsUtility.TCC_BLANK;

          accRecord = accountMap.get(tsk.WhatId);

          if (!String.isBlank(accRecord.EBH_UrgencyReason__c)) {
            tsk.Description +=
              EBH_ConstantsUtility.TTH_URGENCYREASON +
              accRecord.EBH_UrgencyReason__c +
              '\n';
          }
          if (!String.isBlank(accRecord.EBH_DefectReason__c)) {
            tsk.Description +=
              EBH_ConstantsUtility.TTH_URGENCYACTION +
              accRecord.EBH_DefectReason__c;
          }

          // accountIds.add(tsk.WhatId); // BR-25-09-23-US-0013984
        }
      }
    }
  }

  /********************************************************************************************************************************************
@ Method:         captureMemberResponseCode
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        receives the Task records and for AM Outreach tasks get the related Response Code with the help of 
- Response 
---------------------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      Passed through the Task Trigger
---------------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.10.2017 / NEHA LUND / Created the  Method.
@ Change history: 10.01.2019 / DHE / update response code when call attempts = 3
@ Change History: 05.12.2019 / DHE / Updated for copying also Seller Ineligible Reasons
@				: 06.02.2020/ Vadhanak / US-0007171 Hypercare - Create task process failed
@				: 			added flag to prevent loop triger cm<-->task
@ Change history: 22.05.2022 / Mony Nou / US-0011525 - Expose Campaign detail on Customer account - AC3
********************************************************************************************************************************************/
  public static void captureMemberResponseCode(
    List<Task> tasks,
    Map<Id, Task> oldTasks
  ) {
    //prevent loop
    if (EBH_CampaignMemberTriggerHandler.FROM_MC_FIELDS_UPATE)
      return;

    List<CampaignMember> cMembers = new List<CampaignMember>();
    CampaignMember campMember = new CampaignMember();
    Set<ID> campaignMemberIds = new Set<ID>();

    for (Task tsk : tasks) {
      campaignMemberIds.add(tsk.EBH_CampaignMemberId__c);
    }
    Map<Id, CampaignMember> campaignMemberMap = queryMapCampaignMember(
      campaignMemberIds
    );
    //
    for (Task tsk : tasks) {
      //prevent null pointer exception  // by DHE 2019-03-14
      /*   if(!campaignMemberMap.containsKey(campMember.Id)){
                continue;
            }
           */
      //If Response Code is changed and Task Type is AM Outreach
      //if( hasResponseChanged(tsk, oldTasks) && tsk.EBH_CampaignMemberId__c != null && campaignMemberMap.containskey(tsk.EBH_CampaignMemberId__c) || hasCallAttemptsReachedTheMaximum(tsk, oldTasks)){
      if (
        hasResponseChanged(tsk, oldTasks) &&
        tsk.EBH_CampaignMemberId__c != null &&
        campaignMemberMap.containskey(tsk.EBH_CampaignMemberId__c)
      ) {
        //      System.debug('Has changed response code? ' +hasResponseChanged(tsk, oldTasks) + '[' + tsk.EBH_ResponseCode__c + ']');
        if (oldTasks != null && oldTasks.containskey(tsk.id)) {
          //   System.debug( '['+ oldTasks.get(tsk.id).EBH_ResponseCode__c +']');
        }

        //if Response is changed, then copy that on the Campaign Member
        campMember = new CampaignMember();
        campMember.Id = tsk.EBH_CampaignMemberId__c;

        //Capture First Response Date only when it is blank

        if (
          campaignMemberMap.get(campMember.Id).EBH_FirstResponseDate__c == null
        ) {
          campMember.EBH_FirstResponseDate__c = Date.Today();
        }

        //Capture the Last Response Date and Response Code
        campMember.EBH_LastResponseDate__c = Date.Today();

        /*       campMember.EBH_ResponseCode__c = (tsk.EBH_Response__c == EBH_ConstantsUtility.AOC_TASKCALL) ? 10 : 
                (tsk.EBH_Response__c == EBH_ConstantsUtility.AOC_TASKPHONE) ? 20 :
                (tsk.EBH_Response__c == EBH_ConstantsUtility.AOC_TASKWRONGPHONE) ? 30 :
                (tsk.EBH_Response__c == EBH_ConstantsUtility.AOC_TASKCALLNOTANSWERED) ? 40 :
                (tsk.EBH_Response__c == EBH_ConstantsUtility.AOC_TASKDMCNOTREACHED) ? 50 :
                (tsk.EBH_Response__c == EBH_ConstantsUtility.AOC_TASKDMCNOTINTERESTED) ? 60 :
                (tsk.EBH_Response__c == EBH_ConstantsUtility.AOC_UNSUBSCRIBE) ? 80 :
                (tsk.EBH_Response__c == EBH_ConstantsUtility.AOC_TASKDMCINTERESTED) ? 90 :
                (tsk.EBH_Response__c == EBH_ConstantsUtility.AOC_TASKDMCCOMMITTED) ? 100 :
                campaignMemberMap.get(campMember.Id).EBH_ResponseCode__c;

                 String TaskResponseCode= String.valueOf(tsk.EBH_ResponseCode__c);
                  campMember.EBH_ResponseCode__c = (TaskResponseCode == EBH_ConstantsUtility.AOC_TASKCALL) ? 10 : 
                (TaskResponseCode == EBH_ConstantsUtility.AOC_TASKPHONE) ? 20 :
                (TaskResponseCode == EBH_ConstantsUtility.AOC_TASKWRONGPHONE) ? 30 :
                (TaskResponseCode == EBH_ConstantsUtility.AOC_TASKCALLNOTANSWERED) ? 40 :
                (TaskResponseCode == EBH_ConstantsUtility.AOC_TASKDMCNOTREACHED) ? 50 :
                (TaskResponseCode == EBH_ConstantsUtility.AOC_TASKDMCNOTINTERESTED) ? 60 :
                (TaskResponseCode == EBH_ConstantsUtility.AOC_UNSUBSCRIBE) ? 80 :
                (TaskResponseCode == EBH_ConstantsUtility.AOC_TASKDMCINTERESTED) ? 90 :
                (TaskResponseCode == EBH_ConstantsUtility.AOC_TASKDMCCOMMITTED) ? 100 :
                campaignMemberMap.get(campMember.Id).EBH_ResponseCode__c;*/
        campMember.EBH_ResponseCode__c = tsk.EBH_ResponseCode__c;
        campMember.Seller_Ineligible_Reasons__c = tsk.Seller_Ineligible_Reasons__c; // we don't need to map values anymore. We just copy the double value from task to campaign member
        /*     if(hasCallAttemptsReachedTheMaximum(tsk, oldTasks)){                        
                       campMember.EBH_ResponseCode__c =  EBH_CampaignChannelResponse__c.getAll().get(String.valueOf(EBH_ConstantsUtility.RESPONSE_CODE_NOT_REACHED)).EBH_ResponseCode__c;                         
					                           
                    }
*/

        //MN-26052022-US-0011525
        campMember.Related_Task__c = tsk.Id;

        cMembers.add(campMember);
      }
    }

    try {
      if (!cMembers.isEmpty()) {
        //   System.debug('Updating Campaign Member = ' + cMembers[0].EBH_ResponseCode__c);
        Database.update(cMembers);
      }
    } catch (Exception ex) {
      //     System.debug('Exception');
      EBH_ApexLogger.logError(
        new List<Exception>{ ex },
        EBH_ConstantsUtility.TTH_CLASS,
        EBH_ConstantsUtility.TTH_METHOD
      );
    }
  }
  //in case trigger in some loop of update
  static Map<Id, CampaignMember> mapCampaignMember;
  private static Map<Id, CampaignMember> queryMapCampaignMember(
    Set<ID> campaignMemberIds
  ) {
    if (mapCampaignMember == null) {
      mapCampaignMember = new Map<Id, CampaignMember>(
        (List<CampaignMember>) Database.query(EBH_ConstantsUtility.TTH_QUERY)
      );
    }
    return mapCampaignMember;
  }

  /*****************************************************************************************************************************
@ Method:         hasResponseChanged
@ Version:        1.0
@ Author:         Neha Lund
@ Purpose:        Check and returns true if Account Status has changed in old account passed in param
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      tsk:           task record
taskOldMap:    task old map
------------------------------------------------------------------------------------------------------------------------------
@ Returns:        Boolean: True if any of the field changed
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.10.2017 / NEHA LUND / Created the  Method.
@ Change history: 05.12.2019 / DHE / response changed OR Seller Ineligible Reasons Changed
*****************************************************************************************************************************/
  public static Boolean hasResponseChanged(Task tsk, Map<Id, Task> taskOldMap) {
    Task oldTsk = taskOldMap != null ? taskOldMap.get(tsk.Id) : tsk;
    /*
        return ((tsk.EBH_Response__c != oldTsk.EBH_Response__c &&
                 tsk.Type == EBH_ConstantsUtility.AOC_OUTREACH 
                ) || taskOldMap == null) && tsk.EBH_CampaignMemberId__c != null;
        */
    //updated the responsecode to ebh_responsecode__c
    return (((tsk.EBH_ResponseCode__c != oldTsk.EBH_ResponseCode__c ||
      (tsk.Seller_Ineligible_Reasons__c !=
      oldTsk.Seller_Ineligible_Reasons__c)) &&
      tsk.Type == EBH_ConstantsUtility.AOC_OUTREACH) || taskOldMap == null) &&
      tsk.EBH_CampaignMemberId__c != null;
  }
  /*****************************************************************************************************************************
@ Method:         hasCallAttemptsReachedTheMaximum
@ Version:        1.0
@ Author:         David Herrero
@ Purpose:        Check and returns true if Call Attempts has reached the maximum
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      tsk:           task record
taskOldMap:    task old map
------------------------------------------------------------------------------------------------------------------------------
@ Returns:        Boolean: True if any of the field changed
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.09.2019 / David Herrero/ Created the  Method.
*****************************************************************************************************************************/
  /*   public static Boolean hasCallAttemptsReachedTheMaximum(Task tsk, Map<Id, Task> taskOldMap) {
        
        Task oldTsk = taskOldMap != Null ? taskOldMap.get(tsk.Id) : tsk;
        
        return (tsk.Call_attempts__c==EBH_ConstantsUtility.NUMBER_OF_CALL_ATTEMPTS_TO_BE_CONSIDERED_NOT_REACHED && tsk.Call_attempts__c != oldTsk.Call_attempts__c );
        
    }    
    */
  /*****************************************************************************************************************************
@ Method:         PopulateCampaignCountry
@ Version:        1.0
@ Author:         David Herrero
@ Purpose:        Populate field Campaign Country
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      tasklist:           list of tasks
------------------------------------------------------------------------------------------------------------------------------
@ Returns:        void
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.01.2019 / David Herrero/ Created the  Method.
*****************************************************************************************************************************/
  public static void PopulateCampaignCountry(
    list<task> taskslist,
    Map<Id, Task> mapOld
  ) {
    //NK:06/02/2020: US-0007171
    if (EBH_CampaignMemberTriggerHandler.FROM_MC_FIELDS_UPATE)
      return;

    Map<id, Campaign> MapCampaigns = new Map<id, Campaign>();
    set<id> campaignIds = new Set<id>();
    Boolean isNew = (mapOld == null);
    for (Task t : taskslist) {
      if (
        (isNew && isCampaign(t)) ||
        (!isNew &&
        isCampaign(t) &&
        t.whatId <> mapOld.get(t.Id).whatId)
      ) {
        //new and update.
        CampaignIds.add(t.whatid);
      }
      //UPDATED 2019-03-29 BY DHE
      if (isCampaign(t)) {
        t.Related_Campaign__c = t.whatid;
      }
    }

    //  System.debug('Campaign ids == ' + campaignIds);

    if (campaignIds.isEmpty())
      return;

    MapCampaigns = new Map<id, Campaign>(
      [SELECT id, EBH_Site__c FROM campaign WHERE id IN :campaignIds]
    );
    //      System.debug('MapCampaigns ids == ' + MapCampaigns);
    for (Task t : taskslist) {
      if (
        null != t.WhatId &&
        MapCampaigns.containsKey(t.WhatId) &&
        String.isNotBlank(MapCampaigns.get(t.WhatId).EBH_Site__c)
      ) {
        String country = MapCampaigns.get(t.WhatId).EBH_Site__c.toLowercase();
        country = EBH_ConstantsUtility.MapCountryLanguage.containsKey(country)
          ? EBH_ConstantsUtility.MapCountryLanguage.get(country)
          : 'en'; //By default en language
        t.Campaign_Country__c = country.length() > 3
          ? country.substring(0, 3)
          : country;
      } else {
        //by default en language
        t.Campaign_Country__c = 'en';
      }
    }
  }

  private static Boolean isCampaign(Task t) {
    return null != t.whatId && ('' + t.whatId).startsWith('701');
  }

  /*****************************************************************************************************************************
    @ Method:       populateTargetDateFromTask
    @ Version:      1.0
    @ Author:       Vadhanak Voun 
    @ Purpose:      EPH-7043 "Target Date" in campaign-members. Email & GCX
    @			AC3:
	@				Clicktool
	@				Given that Outreach.Channel = GCX Outreach (Phone) OR GCX Inbound (Phone)
	@				Populate Target Date with current_time  when Task. Call Attempts =1
	@				
	@				Given that Sub-Campaign.Channel = GCX Outreach (Phone) OR GCX Inbound (Phone)
	@				Populate Target Date with current_time  when Task. Call Attempts =1
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      listTask:                 : listTask  
    @                 mapOld  : Task old map from trigger scope to compare
    @ Trigger:		  before insert,before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12/02/2019 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
  public static void populateTargetDateFromTask(
    List<Task> listTask,
    Map<Id, Task> mapOld
  ) {
    //NK:06/02/2020: US-0007171
    if (EBH_CampaignMemberTriggerHandler.FROM_MC_FIELDS_UPATE)
      return;

    Boolean isNew = (mapOld == null);
    Set<String> setChannel = new Set<String>{
      'GCX Outreach (Phone)',
      'GCX Inbound (Phone)'
    };
    List<CampaignMember> listCMToUpdate = new List<CampaignMember>();
    Set<String> cmIds = new Set<String>();
    for (Task t : listTask) {
      if (
        isNew && t.Call_attempts__c == 1 ||
        (!isNew &&
        t.Call_attempts__c <> mapOld.get(t.Id).Call_attempts__c &&
        t.Call_attempts__c == 1) && t.EBH_CampaignMemberId__c <> null
      ) {
        cmIds.add(t.EBH_CampaignMemberId__c);
      }
    }

    if (!cmIds.isEmpty()) {
      //check recordtype and channel out reach or sub
      Set<String> recordTypeAllow = new Set<String>{
        EBH_ConstantsUtility.CAMP_RECORDTYPE_SUB_ID,
        EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID
      };
      String whereCon = ' WHERE Id IN :cmIds AND Campaign.EBH_Channel__c IN :setChannel AND Campaign.RecordTypeId IN :recordTypeAllow AND EBH_ResponseCode__c > 10';
      for (
        CampaignMember camp : Database.query(
          EBH_ConstantsUtility.SOQL_CAM_MEMBER + whereCon
        )
      ) {
        listCMToUpdate.add(
          new CampaignMember(Id = camp.Id, Target_Date__c = System.today())
        );
      }

      if (!listCMToUpdate.isEmpty()) {
        update listCMToUpdate;
      }
    }
  }
  //DHE : if Status =closed or cancelled and Response Code > 25 , update campaign member
  public static void updateCampaignMember(
    List<Task> listTask,
    Map<Id, Task> mapOld
  ) {
    //NK:30/01/2020:US-0007007: prevent loop back trigger CM Trigger<--->Task Trigger
    if (EBH_CampaignMemberTriggerHandler.FROM_MC_FIELDS_UPATE)
      return;

    set<id> CampaignMemberIds = new Set<id>();
    Map<id, Task> mapIdTask = new Map<id, Task>();

    List<CampaignMember> listCMToUpdate = new List<CampaignMember>();
    for (Task t : listTask) {
      if (
        (t.Status == EBH_ConstantsUtility.STATUS_CLOSED ||
        t.Status == EBH_ConstantsUtility.CMRC_COMPLETED) &&
        t.EBH_ResponseCode__c > 25 &&
        t.EBH_CampaignMemberId__c != null
      ) {
        CampaignMemberIds.add(t.EBH_CampaignMemberId__c);
        mapIdTask.put(t.EBH_CampaignMemberId__c, t);
      }
    }

    if (!CampaignMemberIds.isEmpty()) {
      String whereCon = ' WHERE Id IN :CampaignMemberIds';
      for (
        CampaignMember camp : Database.query(
          EBH_ConstantsUtility.SOQL_CAM_MEMBER + whereCon
        )
      ) {
        if (mapIdtask.containsKey(camp.id)) {
          listCMToUpdate.add(
            new CampaignMember(
              Id = camp.Id,
              ebh_responsecode__c = mapIdTask.get(camp.ID).ebh_responsecode__c
            )
          );
        }
      }

      if (!listCMToUpdate.isEmpty()) {
        update listCMToUpdate;
      }
    }
  }
  /*
   * http://txl-entas-057:8080/browse/EPH-7678
   * Method that auto-populates the task subject
   * created date : 2019 06 20
   * created by : David Herrero dherrero@ebay.com
   *
   */
  public static void updatePriorityOrderFromFollowUpTasks(
    List<Task> listTasks
  ) {
    //NK:06/02/2020: US-0007171
    if (EBH_CampaignMemberTriggerHandler.FROM_MC_FIELDS_UPATE)
      return;

    final string FOLLOWUPSUBJECT = 'FOLLOWUPCALL';
    set<id> campaignIds = new Set<id>();
    for (Task t : listTasks) {
      if (FOLLOWUPSUBJECT.equals(t.subject) && null != t.WhatId) {
        campaignIds.add(t.WhatId);
      }
    }

    if (campaignIds.isEmpty())
      return;

    Map<id, String> mapCampaignNames = new Map<id, string>();
    for (Campaign c : [
      SELECT id, name
      FROM campaign
      WHERE id IN :campaignIds
    ]) {
      mapCampaignNames.put(c.id, c.name);
    }
    for (Task t : listTasks) {
      if (mapCampaignNames.containsKey(t.WhatId) && isOutreachTask(t)) {
        if (FOLLOWUPSUBJECT.equals(t.subject) && t.Follow_Up_Task__c) {
          t.subject =
            mapCampaignNames.get(t.WhatId) +
            '_' +
            System.Label.FollowUpTaskName;
        } else {
          t.subject =
            mapCampaignNames.get(t.WhatId) +
            '_' +
            System.Label.Outreach_Task;
        }
      }
    }
  }
  /*
   Method returns true if is an Open Outreach Task*/
  private static boolean isOutreachTask(Task t) {
    return (t != null &&
    null != t.WhatId &&
    null != t.type &&
    t.type.equals(EBH_ConstantsUtility.CAMPAIGN_CHANNEL_PHONE_OUTREACH) &&
    null != t.status &&
    t.Status.equals(EBH_ConstantsUtility.AOC_TASKSTATUS));
  }
  /*
	DHE
	2019-04-17
	From Clicktools we cannot receive DateTime, so we receive Date in one field, Time in other field and add the time to the date.
	http://txl-entas-057:8080/browse/EPH-7268
	*/
  public static void updateCallBackDateTime(
    List<Task> listTask,
    Map<Id, Task> mapOld
  ) {
    //NK:06/02/2020: US-0007171
    if (EBH_CampaignMemberTriggerHandler.FROM_MC_FIELDS_UPATE)
      return;

    //TimeZone tz = UserInfo.getTimeZone();
    //Timezone tz = Timezone.getTimeZone([select id,TimeZoneSidKey  from user where id='0056A000000yx6iQAA'].TimeZoneSidKey);
    Integer offset;
    Map<id, TimeZone> mapUserTZ = new Map<id, TimeZone>();
    set<id> taskowners = new Set<id>();
    for (Task t : listtask) {
      //TH 22/07/2020 : US-0007639 : add Log_Task__c condition check to skip
      if (t.Log_Task__c)
        continue;
      taskowners.add(t.ownerid);
    }
    for (User u : [
      SELECT id, TimeZoneSidKey
      FROM user
      WHERE id IN :taskowners
    ]) {
      mapUserTZ.put(u.id, Timezone.getTimeZone(u.TimeZoneSidKey));
    }

    for (Task t : listTask) {
      //DHE 2020-05-11 US-0007480
      //if start and end date are equal don't update
      //TH 22/07/2020 : US-0007639 : add Log_Task__c condition check to skip
      if (
        t.Log_Task__c ||
        (mapOld != null &&
        t.Call_Back_Window_Start_CT__c ==
        mapOld.get(t.id).Call_Back_Window_Start_CT__c &&
        t.Call_Back_Window_End_CT__c ==
        mapOld.get(t.id).Call_Back_Window_end_CT__c)
      ) {
        continue;
      }
      offset = mapUserTZ.get(t.ownerid).getOffset(Datetime.now());
      offset = -1 * offset;
      //            if (t.Call_Back_Window_Start_CT__c!=null && t.Call_Back_Start_Time__c!=null && mapOld.containsKey(t.id) && mapOld!=null && ( mapOld.get(t.id).Call_Back_Start_Time__c!=t.Call_Back_Start_Time__c || mapold.get(t.id).Call_Back_Window_Start_CT__c <> t.Call_Back_Window_Start_CT__c)){
      if (
        t.Call_Back_Window_Start_CT__c != null &&
        t.Call_Back_Start_Time__c != null
      ) {
        t.Call_Back_Window_start__c = addTime(
          t.Call_Back_Window_Start_CT__c,
          t.Call_Back_Start_Time__c
        );
        //    System.debug('Offset= ' + offset);
        //	System.debug('t.Call_Back_Window_start__c= ' + t.Call_Back_Window_start__c);

        t.Call_Back_Window_start__c = t.Call_Back_Window_start__c.addSeconds(
          offset / 1000
        );
        //   System.debug('After adding offset=t.Call_Back_Window_start__c= ' + t.Call_Back_Window_start__c);
      }
      //          if (t.Call_Back_Window_end_CT__c!=null && t.Call_Back_End_Time__c!=null && (mapOld.get(t.id).Call_Back_End_Time__c!=t.Call_Back_End_Time__c || mapold.get(t.id).Call_Back_Window_End_CT__c <> t.Call_Back_Window_End_CT__c)){
      if (
        t.Call_Back_Window_end_CT__c != null &&
        t.Call_Back_End_Time__c != null
      ) {
        t.Call_Back_Window_end__c = addTime(
          t.Call_Back_Window_end_CT__c,
          t.Call_Back_End_Time__c
        );
        t.Call_Back_Window_end__c = t.Call_Back_Window_end__c.addSeconds(
          offset / 1000
        );
      }
    }
  }
  /*
	DHE
	2019-04-17
	Add Time to Date field
	*/
  private static DateTime addTime(Date dt, String sTime) {
    try {
      Integer hours = Integer.valueOf(stime.split(':')[0]);
      //   system.debug(hours);
      Integer minutes = Integer.valueOf(stime.split(':')[1]);
      //   system.debug(minutes);

      return DateTime.newInstanceGmt(
        dt.year(),
        dt.month(),
        dt.day(),
        hours,
        minutes,
        0
      );
    } catch (Exception e) {
      return Datetime.now();
    }
  }

  /*****************************************************************************************************************************
    @ Method:       preventActivityOnInactiveContact
    @ Version:      1.0
    @ Author:       Vadhanak Voun 
    @ Purpose:      EPH-7586 Allow users to flag seller related contacts as inactive
    @			AC3) As any user I should not be able to create activities e.g. create tasks or log a call with contacts marked as inactive. 
    @			If a user want's to create an activity for an inactive contact a warning note will be displayed: 
    @			"You are not able to create an activity for this contact as it's status is inactive, please, select another contact of this seller."
    @				
    @				Generic method to work with both Task and Event
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      listNew:                 : listTask/Event  
    @                 mapOld  : Task/Event old map from trigger scope to compare
    @ Trigger:		  before insert,before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14/06/2019 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
  public static void preventActivityOnInactiveContact(
    List<SObject> listNew,
    Map<Id, SObject> mapOld
  ) {
    Boolean isNew = (mapOld == null);
    Set<String> setContactId = new Set<String>();
    List<SObject> listObj = new List<SObject>();
    for (SObject sobj : listNew) {
      //get contact id
      if (
        (isNew &&
        sobj.get('WhoId') <> null &&
        (sobj.get('WhoId') + '').startsWith('003')) ||
        (!isNew &&
        sobj.get('WhoId') <> mapOld.get(sobj.get('Id') + '').get('WhoId') &&
        (sobj.get('WhoId') + '').startsWith('003'))
      ) {
        if (sobj.get('Calendly_Event_UUID__c') == null) {
          setContactId.add(sobj.get('WhoId') + '');
          listObj.add(sobj);
        }
      }
    }
    if (!setContactId.isEmpty()) {
      Map<Id, Contact> mapContact = new Map<Id, Contact>(
        (List<Contact>) Database.query(
          EBH_ConstantsUtility.SOQL_CONTACT + ' Where Id IN:setContactId'
        )
      );

      for (SObject sobj : listObj) {
        if (
          mapContact.get(sobj.get('WhoId') + '').EBH_Status__c ==
          EBH_ConstantsUtility.CONTACT_STATUS_INACTIVE
        ) {
          sobj.addError(System.Label.ErrorActivityInactiveContact);
        }
      }
    }
  }

  /*****************************************************************************************************************************
    @ Method:       historyTask
    @ Version:      1.0
    @ Author:       Vadhanak Voun 
    @ Purpose:      EPH-7525 New custom object: Task History
    @			AC2: 
	@			Create process builder/ trigger that will follow a rule:
	@			Every time a field "Call Attempts" in the object "Task" is changing it's value ->
	@			Create new  "Call History" record and copy values from the original Task record to the newly created Task History record
    @				
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      listNew:                 : listTask/Event  
    @                 mapOld  : Task/Event old map from trigger scope to compare
    @ Trigger:		  before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18/06/2019 / Vadhanak Voun / Created the  Method.
    @				: 06/08/2019/ Vadhanak Voun/ add transactionId for upsert instead of insert
	@				: 20/10/2020 / David Herrero / Add a condition when the task history should be created
    @				: 26/11/2021 / David Herrero / Truncate name field to 80 US-0010928
    @        : 10/09/2025 / vadhaank voun / US-0033124 - Genesys - Start Call Script from Task
    *****************************************************************************************************************************/
  public static void historyTask(List<Task> listNew, Map<Id, Task> mapOld) {
    List<Task_History__c> listHistory = new List<Task_History__c>();
    for (Task t : listNew) {
      if (
        (t.whatId <> null &&
        t.WhatId.getSObjectType() == Campaign.sObjectType) &&
        t.Call_attempts__c <> mapOld.get(t.Id).Call_attempts__c &&
        t.Call_attempts__c > 0 && //US-0008560 Only if the call attempts is > 0 &&
        t.call_attempts__c < 4 //to prevent creating wrong task history records, we won't create if the call attempt >3
      ) {
        listHistory.add(
          new Task_History__c(
            //	Name = t.Subject, To prevent string too long error I am truncating this field
            Name = (t.subject != null &&
              t.subject.length() > 80
              ? t.subject.substring(80)
              : t.subject),
            Task_ID__c = t.Id,
            Campaign__c = t.WhatId,
            Date__c = System.today(),
            Call_Agent__c = t.OwnerId,
            DMC__c = t.EBH_DMC__c,
            Response_Code__c = t.EBH_ResponseCode__c,
            Status__c = t.Status,
            Call_attempts__c = t.Call_attempts__c,
            TransactionId__c = getTransactionId(t),
            Response_code_Text__c = t.EBH_fResponseCode__c,
            Customer__c = t.EBH_Account__c,
            Comments__c = t.Description,
            Survey_result_1__c = t.SurveyResult1__c,
            Survey_result_2__c = t.SurveyResult2__c,
            Survey_result_3__c = t.SurveyResult3__c
          )
        );
      }

     else if (  //NK:10/09/2025: US-0033124 - added else instead of if to avoid creating 2 history records in one update  
        (t.whatId <> null &&
        t.WhatId.getSObjectType() == Campaign.sObjectType) &&
        ((t.EBH_DMC__c <> mapOld.get(t.Id).EBH_DMC__c &&
        t.EBH_DMC__c == true) ||
        (t.EBH_ResponseCode__c <> mapOld.get(t.id).EBH_ResponseCode__c &&
        t.EBH_ResponseCode__c >= 70) ||
        (t.recordtypeId != mapOld.get(t.id).recordtypeId &&
        t.ebh_dmc__c == true) ||
        (t.Action_Outcome_Date__c != mapOld.get(t.id).Action_Outcome_Date__c &&
        t.ebh_dmc__c == true)) //updating if DMC is changed and is true
      ) {
        listHistory.add(
          new Task_History__c(
            Task_ID__c = t.Id,  //NK:10/09/2025: US-0033124 -fixed error at Epilogue missing task id
            TransactionId__c = getTransactionId(t),
            Response_Code__c = t.EBH_ResponseCode__c,
            Response_code_Text__c = t.EBH_fResponseCode__c,
            Status__c = t.Status,
            DMC__c = true
          )
        ); //setting DMC = true because any of the conditions above is true
      }
    }
    if (!listHistory.isEmpty()) {
      upsert listHistory TransactionId__c;
    }
  }

  //NK:06/08/2019: prevent duplicate history (for multiple trigger/workflow behind)
  private static String transactionId;
  //Updated 2023-11-16 by DHE
  /*
    @parameters: Task t
    @returns: generated string */
  private static String getTransactionId(Task t) {
    if (transactionId == null) {
      //transactionId = ApexUtil.genUniqueString(20);
      String callAttempts = String.valueOf((Integer) t.Call_attempts__c);
      // transactionId = t.id + '_' + t.Call_attempts__c;
      transactionId = t.id + '_' + callAttempts;
    }
    return transactionId;
  }

  /*****************************************************************************************************************************
    @ Method:       preventLogTask
    @ Version:      1.0
    @ Author:       Vadhanak Voun 
    @ Purpose:      EPH-7589 Attach Coupon Contract under Coupon Seller related for audit
    @			AC1: 
	@			For all users it is read only and cannot be deleted by any user
    @			EPH-7676	
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      listNew:                 : listTask 
    @                 mapOld  : Task/Event old map from trigger scope to compare
    @ Trigger:		  before update, before delete
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04/09/2019 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
  public static void preventLogTask(List<Task> listNew) {
    Boolean isAdmin = UserInfo.getProfileId()
      .equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
    if (isAdmin)
      return;
    for (Task t : listNew) {
      if (t.Log_Task__c) {
        t.addError(System.Label.ErrorLogTaskPreventEdit);
      }
    }
  }

  /*****************************************************************************************************************************
    @ Method:       createFulfilmentProject
    @ Version:      1.0
    @ Author:       Acmatac SEING
    @ Purpose:      US-0015694 Create a trigger that will create a Fulfilment record every time a new Tasks is created for the Fulfilment Campaign.
                    Task. Related To contains Fulfilment Acqusition
                    AC2: Before creation of the Fulfilment record, trigger should check if the Fulfilment record for this seller is already existing 
                    And if if it does, not to create a duplicate.
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    listNew : listTask 
    @ Trigger:      after insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:      void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 03/10/2019 / Acmatac SEING / Created the  Method.
                      02/12/2019 / Acmatac SEING / Updated the  Method. US-0006909 Hypercare Bug- Duplicate values in Fulfilment.
                            AC1: Populate external id value for the Project record when creating it, <Static_Prefix>-<Account ORACLE_ID>:PRJ_FF-Account.EBH_OracleID__c
                            AC2: Consider to use UPSERT operation instead of having loops in the trigger to avoid potential issues with big data amounts. 
    *****************************************************************************************************************************/
  public static void createFulfilmentProject(List<Task> listNew) {
    Map<Id, List<Task>> mLstTask = new Map<Id, List<Task>>();
    // Only Task.Related To type Campaign AND Task.Name Contact
    for (Task oTask : listNew) {
      if (String.isNotBlank(oTask.WhatId) && String.isNotBlank(oTask.WhoId)) {
        Boolean isCorrectType =
          oTask.WhatId.getSObjectType() == Campaign.sObjectType &&
          oTask.WhoId.getSObjectType() == Contact.sObjectType;
        if (isCorrectType) {
          // Some Campaign may have many tasks.
          if (mLstTask.containsKey(oTask.WhatId)) {
            mLstTask.get(oTask.WhatId).add(oTask);
          } else {
            mLstTask.put(oTask.WhatId, new List<Task>{ oTask });
          }
        }
      }
    }

    //NK:06/02/2020: prevent todoing useless thing
    if (mLstTask.isEmpty())
      return;

    List<Task> lstNewTask = new List<Task>();
    Set<Id> sTaskId = mLstTask.keySet();
    // Take only Task. Related To (Campaign) contains name Fulfilment Acqusition
    String campgnSQL =
      EBH_ConstantsUtility.CAMPAIGN_SQL.Replace('[EXTRA_CLAUSE]', 'Name') +
      ' WHERE Id IN: sTaskId AND Name LIKE \'%DE GCX Fulfillment%\'';
    for (Campaign oCampgn : Database.query(campgnSQL)) {
      if (mLstTask.containsKey(oCampgn.Id)) {
        lstNewTask.addAll(mLstTask.get(oCampgn.Id));
      }
    }

    Set<Id> sContactId = new Set<Id>();
    for (Task oTask : lstNewTask) {
      sContactId.add(oTask.WhoId);
    }

    // AC2 Before creation of the Fulfilment record, trigger should check if the Fulfilment record for this seller is already existing and if if it does, not to create a duplicate.
    Set<Id> sAccountId = new Set<Id>();
    String contactSQL =
      EBH_ConstantsUtility.CONTACT_SQL.Replace(
        '[EXTRA_CLAUSE]',
        'Name, AccountId, Account.EBH_OracleID__c, Account.Name'
      ) + ' WHERE Id IN: sContactId';
    List<Contact> lstCont = new List<Contact>();
    for (Contact oCont : Database.query(contactSQL)) {
      sAccountId.add(oCont.AccountId);
      // Add to list for prevent re-query
      lstCont.add(oCont);
    }

    String projSQL =
      EBH_ConstantsUtility.EBH_PROJECT_SQL.Replace(
        '[EXTRA_CLAUSE]',
        'EBH_Seller__c'
      ) + ' WHERE EBH_Seller__c IN: sAccountId';
    for (EBH_Project__c oProj : Database.query(projSQL)) {
      if (sAccountId.contains(oProj.EBH_Seller__c)) {
        // Remove already created task
        sAccountId.remove(oProj.EBH_Seller__c);
      }
    }

    List<EBH_Project__c> lstProjFulfmnt = new List<EBH_Project__c>();
    Id proj_RTFulfilment = Schema.SObjectType.EBH_Project__c.getRecordTypeInfosByDeveloperName()
      .get('Fulfilment')
      .getRecordTypeId();
    for (Contact oCont : lstCont) {
      if (sAccountId.contains(oCont.AccountId)) {
        EBH_Project__c oProj = new EBH_Project__c();
        oProj.RecordTypeId = proj_RTFulfilment;
        oProj.Name = 'Fulfilment ' + oCont.Account.Name;
        oProj.EBH_Seller__c = oCont.AccountId;
        oProj.EBH_Contact__c = oCont.Id;
        oProj.External_ID__c =
          PROJ_EXTERNAL_PREFIX + oCont.Account.EBH_OracleID__c;
        lstProjFulfmnt.add(oProj);
      }
    }

    if (!lstProjFulfmnt.isEmpty()) {
      upsert lstProjFulfmnt External_ID__c;
    }
  }

  /*****************************************************************************************************************************
    @ Method:   populateSchduleSlotsWithTask
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  US-0011996 - Call booking for Ads
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    listNewTask = list of New Task, mapOldTask =  map of Old Task
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.07.2022 / Sophal Noch / Created the  Method.
    *****************************************************************************************************************************/
  public static void populateSchduleSlotsWithTask(
    List<Task> listNewTask,
    Map<Id, Task> mapOldTask
  ) {
    Boolean isNewOrDelete = mapOldTask == null ? true : false;
    Set<String> setUniqueId = new Set<String>();
    for (Task newTask : listNewTask) {
      Task oldTask = !isNewOrDelete ? mapOldTask.get(newTask.Id) : null;

      // when there are changes in Task like Task.OwnerId, User_Availability__c of Old Task.OwnerId need to be re-calculated.
      if (
        !isNewOrDelete && validateSchduleSlotsWithTask(true, oldTask, newTask)
      ) {
        setUniqueId.add(
          UserAvailabilityTriggerHandler.createUniqueId(
            oldTask.OwnerId,
            oldTask.Call_Back_Window_start__c.dateGmt()
          )
        );
      }

      // when there are changes in Task like Task.OwnerId, User_Availability__c of New Task.OwnerId need to be re-calculated.
      if (
        !isNewOrDelete &&
        validateSchduleSlotsWithTask(true, newTask, oldTask) ||
        (isNewOrDelete && validateSchduleSlotsWithTask(false, newTask, null))
      ) {
        setUniqueId.add(
          UserAvailabilityTriggerHandler.createUniqueId(
            newTask.OwnerId,
            newTask.Call_Back_Window_start__c.dateGmt()
          )
        );
      }
    }

    if (!setUniqueId.isEmpty())
      UserAvailabilityTriggerHandler.calculateSlotsFromRelatedObj(
        setUniqueId,
        false,
        true
      );
  }

  private static Boolean validateSchduleSlotsWithTask(
    Boolean isCompareField,
    Task targetTask,
    Task comparedTask
  ) {
    return ((targetTask.Update_User_Availability__c &&
    targetTask.Call_Back_Window_start__c != null &&
    targetTask.Call_Back_Window_end__c != null) &&
    (!isCompareField ||
    (isCompareField &&
    (targetTask.OwnerId != comparedTask.OwnerId ||
    targetTask.Update_User_Availability__c !=
    comparedTask.Update_User_Availability__c ||
    targetTask.Call_Back_Window_start__c !=
    comparedTask.Call_Back_Window_start__c ||
    targetTask.Call_Back_Window_end__c !=
    comparedTask.Call_Back_Window_end__c))));
  }
}