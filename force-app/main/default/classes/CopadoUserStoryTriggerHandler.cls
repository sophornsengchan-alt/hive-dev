/*********************************************************************************************************************************
@ Class:          CopadoUserStoryTriggerHandler
@ Version:        1.0
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.09.2022 / Sambath Seng / US-0011909 - Implement restrictions on changing status of a user story
                  14.09.2022 / Sambath Seng / US-0012624 - Error when updating Status & Sprint together for a User Story/Bug
                  06.10.2022 / Acmatac SEING / US-0011910 - Implement mandatory check on additional fields in a user story
                  26.07.2023/ vadhanak voun / US-0013924 - Team and HIVE Product automations
                  09.10.2023/ David Herrero / US-0014181 - Check that all related feature requests are closed
                  26.10.2023/ vadhanak voun / US-0014332 - HIVE Product to Team mapping
                  03.06.2024/ David Herrero / US-0015368 - Setting default values
                  09.08.2024/ Vimean Heng / US-0015680 - [Flow Error] User Story - After Update - Update Feature Request" Flow
                  12.09.2024/ Vimean Heng / US-0015843 - Allow to assign Hive Platform stories to all 3 Scrum teams
*********************************************************************************************************************************/
public class CopadoUserStoryTriggerHandler {
  private static final String COPADO_USER_STORY_EXCLUDE_FIELDS = 'Fields_to_Exclude';

  private static Integer recurRunCount = 1;

  private static final String STATUS_BINDED = 'Binded';
  private static final String USERSTORY_SOQL = 'select count(Id) totalStory,Hive_Project__c from copado__User_Story__c';
  //private static final String PROJECT_SOQL = 'select id,Status__c,(select id from User_Stories__r where copado__Status__c NOT IN: completedStatus limit 1) from Hive_Project__c';
  private static final String PROJECT_SOQL = 'select id,Status__c,(select id from User_Stories__r where copado__Status__c NOT IN: completedStatus limit 1),(select id from Feature_Requests__r where status__c not in:completedStatus ) from Hive_Project__c'; //DHE 2023-10-09 Including feature request
  private static final String COMPLETED_STATUS = 'Completed';
  private static final String DEVELOPMENT_STATUS = 'Development';
  private static final String DRAFT_STATUS = 'Draft';
  private static final String READY_FOR_REFINEMENT_STATUS = 'Ready for refinement';
  private static final String APPROVE_STATUS = 'Approved';
  

  private static final String CURRENT_USER_ID {
    get {
      if (CURRENT_USER_ID == null) {
        CURRENT_USER_ID = String.valueOf(UserInfo.getUserId());
      }
      return CURRENT_USER_ID;
    }
    set;
  }
  private static final String STATUS_APPROVED = 'Approved';
  private static final String STATUS_IN_DEV = 'In Dev';
  private static final String STATUS_DEPLOYED_IN_QA = 'Deployed in QA';
  private static final String STATUS_DEPLOYED_IN_UAT = 'Deployed in UAT';
  private static final String STATUS_STAGING = 'Staging';

  private static final String SPRINT_STATUS_INPROGRESS = 'In progress';
  private static final Id RECORDTYPEID_USER_STORY = ApexUtil.getRecordTypeByName(
      'copado__User_Story__c',
      'User_Story'
    )
    .Id;
  private static final Id RECORDTYPEID_BUG = ApexUtil.getRecordTypeByName(
      'copado__User_Story__c',
      'Bug'
    )
    .Id;
  private static final Id RECORDTYPEID_HELPER = ApexUtil.getRecordTypeByName(
      'copado__User_Story__c',
      'Helper'
    )
    .Id; // Sambath Seng 2.9.2022 US-0011909 - Implement restrictions on changing status of a user story
  private static final Set<String> SET_CHANGING_PRIORITY_USERID {
    get {
      if (SET_CHANGING_PRIORITY_USERID == null) {
        Set<String> setUserId = new Set<String>();
        setUserId.addAll(Label.ChangingPriorityUserId.split(','));
        SET_CHANGING_PRIORITY_USERID = setUserId;
      }
      return SET_CHANGING_PRIORITY_USERID;
    }
    set;
  }
  private static final List<String> LIST_SALAMI_NAMES {
    get {
      if (LIST_SALAMI_NAMES == null) {
        List<String> listSalamiName = new List<String>();
        for (String spName : Label.SprintSalamiNames.split(';')) {
          listSalamiName.add(spName.trim().toLowerCase());
        }
        LIST_SALAMI_NAMES = listSalamiName;
      }
      return LIST_SALAMI_NAMES;
    }
    set;
  }
  private static final Set<String> SET_RESTRICTION_STATUS = new Set<String>{
    'In Dev',
    'Deployed in QA',
    'Deployed in UAT',
    'Staging',
    'Deployed in PROD',
    'Closed - Complete'
  }; // Sambath Seng 2.9.2022 US-0011909 - Implement restrictions on changing status of a user story

  public static void decodeDescription(
    copado__User_Story__c[] newList,
    Map<id, copado__User_Story__c> oldMap,
    boolean isUpdate
  ) {
    /*
        Not needed anymore
        for (copado__User_Story__c cus:newlist){
            if(cus.Description__c != null &&  isUpdate && cus.Description__c!= oldmap.get(cus.id).Description__c || !isUpdate && cus.copado__Functional_Specifications__c!=null){
                cus.Description__c=cus.Description__c.unescapeHtml4();
                
                
            }
        }
        */
  }
  /*
Updated 2019-12-16 by DHE
it also calculate Technical Design length*/
  /*
    public static void calculateTechnicalSpecifications(List<copado__User_Story__c>newList){
        for (copado__User_Story__c us : newList){
            if(!String.isBlank(us.copado__Technical_Specifications__c)){
                us.Technical_Specifications_length__c=us.copado__Technical_Specifications__c.length();
                
            }else{
                us.Technical_Specifications_length__c=0;
                
            }
            
            
            if (!String.isBlank(us.Technical_Design__c)){
                System.debug('Technical design ' + us.Technical_Design__c);
                System.debug('Technical design ' + us.Technical_Design__c.length());
                us.Technical_Design_Length__c=us.Technical_Design__c.length();
                
            }else{
                us.Technical_Design_Length__c=0;
            }
        }
        
    }
    */
  /*
This method will prevent to copy certain fields when cloning a user story
*/
  public static void emptySelectedFieldsWhenCloning(
    List<copado__User_Story__c> newList
  ) {
    //System.debug('Is clone=' + newList);
    for (copado__User_Story__c cus : newList) {
      if (cus.isClone()) {
        System.debug('Is clone=' + cus.isClone());
        cus = excludeSomeFields(cus);
        cus = setDefaultValues(cus); // Added by DHE to implement default values when clonning
      }
    }
  }
  static List<User_Story_default_values__mdt> defaultValues;
  /*
    Description: Reads the default values from the custom metadata type and sets them in the user story
     */
  private static copado__user_story__c setDefaultValues(
    Copado__user_story__c cus
  ) {
    System.debug('**** set default values ' + cus);
    //read the custom metadata type
    if (defaultValues == null) {
      if (Test.isRunningTest()) {
        defaultValues = new List<User_Story_default_values__mdt>();
        defaultValues.add(
          new User_Story_default_values__mdt(
            MasterLabel = 'Copado__Status__c',
            DeveloperName = 'copado_status_c',
            Default_Value__c = 'Draft'
          )
        );
        defaultValues.add(
          new User_Story_default_values__mdt(
            MasterLabel = 'uat_test_passed__c',
            DeveloperName = 'copado_uat_c',
            Default_Value__c = 'true'
          )
        );
        defaultValues.add(
          new User_Story_default_values__mdt(
            MasterLabel = 'copado__Close_Date__c',
            DeveloperName = 'copado_last_promotion',
            Default_Value__c = '2024-06-06'
          )
        );
        defaultValues.add(
          new User_Story_default_values__mdt(
            MasterLabel = 'copado__Last_Compliance_Scan_Date__c',
            DeveloperName = 'copado_last_compliance',
            Default_Value__c = '2024-06-23 11:45:47'
          )
        );
        defaultValues.add(
          new User_Story_default_values__mdt(
            MasterLabel = 'copado__Actual_Points_Other__c',
            DeveloperName = 'actual_points_other',
            Default_Value__c = '2.0'
          )
        );
      } else {
        defaultValues = [
          SELECT MasterLabel, Default_Value__c
          FROM User_Story_default_values__mdt
        ];
      }
    }
    if (userstoryfieldsmap == null) {
      userstoryfieldsmap = Schema.getGlobalDescribe()
        .get('Copado__user_story__c')
        .getDescribe()
        .fields.getMap();
    }
    System.debug('=========' + defaultValues.size());
    System.debug('++++++++' + userstoryfieldsmap.size());
    for (User_Story_default_values__mdt fieldMetadata : defaultValues) {
      System.debug(
        '?????? ' + userstoryfieldsmap.containsKey(fieldMetadata.MasterLabel)
      );
      if (userstoryfieldsmap.containsKey(fieldMetadata.MasterLabel)) {
        Schema.DescribeFieldResult field = userstoryfieldsmap.get(
            fieldMetadata.MasterLabel.trim()
          )
          .getDescribe();
        String fieldType = ('' + field.getType())
          .replace('Schema.DisplayType.', '');

        System.debug(fieldMetadata.MasterLabel + ' ' + fieldType);
        if (!field.isUpdateable()) {
          continue;
        } else if (fieldType == 'DOUBLE') {
          cus.put(
            fieldMetadata.MasterLabel,
            Double.valueOf(fieldMetadata.Default_Value__c)
          );
        } else if (fieldType == 'BOOLEAN') {
          if (fieldMetadata.Default_Value__c.equalsIgnoreCase('true')) {
            cus.put(fieldMetadata.MasterLabel, true);
          } else {
            cus.put(fieldMetadata.MasterLabel, false);
          }
        } else if (
          fieldType == 'TEXT' ||
          fieldType == 'TEXTAREA' ||
          fieldType == 'PICKLIST' ||
          fieldType == 'EMAIL' ||
          fieldType == 'PHONE' ||
          fieldType == 'URL' ||
          fieldType == 'TEXTAREA' ||
          fieldType == 'REFERENCE'
        ) {
          cus.put(fieldMetadata.MasterLabel, fieldMetadata.Default_Value__c);
        } else if (fieldType == 'DATE') {
          cus.put(
            fieldMetadata.MasterLabel,
            Date.valueOf(fieldMetadata.Default_Value__c)
          );
        } else if (fieldType == 'DATETIME') {
          cus.put(
            fieldMetadata.MasterLabel,
            Datetime.valueOf(fieldMetadata.Default_Value__c)
          );
        } else {
          cus.put(fieldMetadata.MasterLabel, null);
        }
      }
    }
    return cus;
  }

  static Map<String, Schema.SObjectField> userstoryfieldsmap;
  /*
acan we make changes in copado: when user is cloning the record, story points should be set to zero,
developer should be set to null and status =draft, sprint should be removed
*/
  //I want to create a map where I will define some fields and the corresponding mapping
  private static copado__User_Story__c excludeSomeFields(
    copado__User_Story__c cus
  ) {
    /*    List<String> fieldsToExclude = new list<string>{'copado__Story_Points_Other__c',
            'copado__Story_Points_SFDC__c', 'Story_Points_Dev__c', 'Story_Points_Test__c' ,'copado__developer__c','copado__status__c','copado__Acceptance_Criteria_Status__c',
            'PO_reviewed__c','copado__Org_Credential__c','copado__Environment__c','copado__Apex_Tests_Passed__c','copado__Manual_Tests_Passed__c',
            'SAT_Tests_passed__c','Smoke_Test_Passed__c','UAT_Test_Passed__c','copado__Documentation_Complete__c','Code_has_been_reviewed__c'};
*/
    //updated by DHE 2020-07-01 to use a field set
    Schema.FieldSet fs1 = Schema.SObjectType.Copado__User_Story__c.fieldSets.getMap()
      .get(COPADO_USER_STORY_EXCLUDE_FIELDS);
    if (userstoryfieldsmap == null) {
      userstoryfieldsmap = Schema.getGlobalDescribe()
        .get('Copado__user_story__c')
        .getDescribe()
        .fields.getMap();
    }
    String f = '';
    for (Schema.FieldSetMember fsm : fs1.getFields()) {
      f = fsm.getFieldPath();

      Schema.DescribeFieldResult field = userstoryfieldsmap.get(f.trim())
        .getDescribe();
      String fieldType = ('' + field.getType())
        .replace('Schema.DisplayType.', '');

      System.debug(f + ' ' + fieldType);
      if (!field.isUpdateable()) {
        continue;
      } else if (fieldType == 'DOUBLE') {
        cus.put(f, 0);
      } else if (fieldType == 'BOOLEAN') {
        cus.put(f, false);
      } else {
        cus.put(f, null);
      }
    }

    return cus;
  }

  /*****************************************************************************************************************************
    @ Method	:   checkDependency
    @ Version	:   1.0
    @ Author	: 	Loumang SENG (loumang.seng@gaea-sys.com)
    @ Purpose	:	US-0009262 - Synchronize related user stories status
    @ Trigger 	: 	after updated
	@ Param 	: 	Map<Id,copado__User_Story__c> mapOld, List<copado__User_Story__c> listNew	
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 24.03.2021 / Loumang SENG / Method Creation
    *****************************************************************************************************************************/
  public static void checkDependency(
    List<copado__User_Story__c> listNew,
    Map<Id, copado__User_Story__c> mapOld
  ) {
    if (recurRunCount > 2)
      return;
    Map<Id, String> mapUSId = new Map<Id, String>();
    for (copado__User_Story__c cus : listNew) {
      copado__User_Story__c oldcus = mapOld.get(cus.Id);
      if (cus.copado__Status__c != oldcus.copado__Status__c) {
        mapUSId.put(cus.Id, cus.copado__Status__c);
      }
    }

    if (!mapUSId.isEmpty()) {
      Map<Id, copado__User_Story__c> mapUsChildToUpdate = new Map<Id, copado__User_Story__c>();

      for (copado__Team_Dependency__c usd : [
        SELECT
          Id,
          copado__Dependent_User_Story__c,
          copado__Provider_User_Story__c
        FROM copado__Team_Dependency__c
        WHERE
          copado__Provider_User_Story__c IN :mapUSId.keySet()
          AND Relationship__c = :STATUS_BINDED
      ]) {
        if (
          !mapUsChildToUpdate.containsKey(usd.copado__Dependent_User_Story__c)
        ) {
          String status = mapUSId.get(usd.copado__Provider_User_Story__c);
          copado__User_Story__c childUs = new copado__User_Story__c(
            Id = usd.copado__Dependent_User_Story__c,
            copado__Status__c = status
          );
          mapUsChildToUpdate.put(usd.copado__Dependent_User_Story__c, childUs);
        }
      }

      if (!mapUsChildToUpdate.isEmpty()) {
        recurRunCount++;
        update mapUsChildToUpdate.values();
      }
    }
  }

  /*****************************************************************************************************************************
    @ Method	:   updateProjectStatus
    @ Version	:   1.0
    @ Author	: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose	:	US-0010666 - New Validations for Feature Request creation
    @ AC 2 
    @ Please create an automation for the following rules:
    @ 1) If there are User stories Linked to any {Hive_Project__c} record with Status equal to 'New/'Under Review' , and {copado__User_Story__c.copado__Sprint__c} is populated 
    @ Then, there should be an automation to change the linked project status {Hive_Project__c.Status__c} to "Development"
    @ 2) If the linked User stories with active status is equal to 'Deployed in PROD' Linked to any {Hive_Project__c} record,
    @ {Hive_Project__c.Status__c} to "Completed"
    @ Trigger 	: 	after insert, updated
	@ Param 	: 	Map<Id,copado__User_Story__c> mapOld, List<copado__User_Story__c> listNew	
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 25.05.2022 /Sovantheany Dim / Method Creation
    *****************************************************************************************************************************/
  public static void updateProjectStatus(
    List<copado__User_Story__c> listNew,
    Map<Id, copado__User_Story__c> mapOld
  ) {
    try {
      Boolean isNew = (mapOld == null);
      Set<String> sProjectIds = new Set<String>();
      Set<String> completedStatus = new Set<String>(
        System.label.Complete_User_Story_Status.Split(';')
      );
      for (copado__User_Story__c userStory : listNew) {
        if (
          userStory.Hive_Project__c == null ||
          userStory.copado__Sprint__c == null
        )
          continue;

        //If copado__Sprint__c is populated
        if (
          isNew ||
          (!isNew &&
          (userStory.copado__Sprint__c !=
          mapOld.get(userStory.Id).copado__Sprint__c ||
          userStory.Hive_Project__c !=
          mapOld.get(userStory.Id).Hive_Project__c))
        ) {
          sProjectIds.add(userStory.Hive_Project__c);
        }
        //If User stories status is equal to 'Deployed in PROD' or Complete
        else if (
          (isNew ||
          (!isNew &&
          (userStory.copado__Status__c !=
          mapOld.get(userStory.Id).copado__Status__c ||
          userStory.Hive_Project__c !=
          mapOld.get(userStory.Id).Hive_Project__c))) &&
          completedStatus.contains(userStory.copado__Status__c)
        ) {
          sProjectIds.add(userStory.Hive_Project__c);
        }
      }
      if (sProjectIds.isEmpty())
        return;
      List<Hive_Project__c> lstProjectToUpdate = new List<Hive_Project__c>();
      Set<String> newProjectStatus = new Set<String>(
        System.label.New_Project_Status.Split(';')
      );
      for (
        Hive_Project__c project : Database.query(
          PROJECT_SOQL + ' where id IN: sProjectIds'
        )
      ) {
        //if All related User Story have  Complete status, update Project to Complete
        //if(project.User_Stories__r.isEmpty() && project.Status__c != COMPLETED_STATUS) lstProjectToUpdate.add(new Hive_Project__c(id = project.Id, Status__c = COMPLETED_STATUS));
        if (
          project.User_Stories__r.isEmpty() &&
          project.Feature_Requests__r.isEmpty() &&
          project.Status__c != COMPLETED_STATUS
        )
          lstProjectToUpdate.add(
            new Hive_Project__c(id = project.Id, Status__c = COMPLETED_STATUS)
          );
        //if Project Status equal to 'New/'Under Review' and copado__Sprint__c is populated, update Project to Development
        else if (newProjectStatus.contains(project.Status__c))
          lstProjectToUpdate.add(
            new Hive_Project__c(id = project.Id, Status__c = DEVELOPMENT_STATUS)
          );
      }
      if (!lstProjectToUpdate.isEmpty())
        update lstProjectToUpdate;
    } catch (System.DmlException e) {
      Trigger.new[0].addError(e.getDmlMessage(0));
    }
  }

  /*****************************************************************************************************************************
    @ Method	:   validatePriorityChanged
    @ Version	:   1.0
    @ Author	: 	Sophal Noch (sophal.noch@gaea-sys.com
    @ Purpose	:	US-0011960 - Managing prioritization of Product Backlog Items (PBIs)
    @ Trigger 	: 	before update
	@ Param 	: 	List<copado__User_Story__c> listNew, Map<Id,copado__User_Story__c> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 08.07.2022 / Sophal Noch / Create Method
    *****************************************************************************************************************************/
  public static void validatePriorityChanged(
    List<copado__User_Story__c> listNew,
    Map<Id, copado__User_Story__c> mapOld
  ) {
    // 08.07.2022 / Sophal Noch / US-0011960 : AC4, Use trigger to validiaion record instead. We can not use validation rule because of maximum number of 20 unique object reference on User Story.

    Set<Id> setSprintId = new Set<Id>();
    List<copado__User_Story__c> listPriorityChanged = new List<copado__User_Story__c>();

    for (copado__User_Story__c newUs : listNew) {
      copado__User_Story__c oldUs = mapOld.get(newUs.Id);
      if (
        newUs.copado__Status__c == STATUS_APPROVED &&
        newUs.copado__Sprint__c != null &&
        !SET_CHANGING_PRIORITY_USERID.contains(CURRENT_USER_ID) &&
        ((newUs.RecordTypeId == RECORDTYPEID_USER_STORY &&
        newUs.BA_Priority__c != oldUs.BA_Priority__c) ||
        (newUs.RecordTypeId == RECORDTYPEID_BUG &&
        newUs.Bug_Priority__c != oldUs.Bug_Priority__c))
      ) {
        setSprintId.add(newUs.copado__Sprint__c);
        listPriorityChanged.add(newUs);
      }
    }
    if (!setSprintId.isEmpty()) {
      Map<Id, copado__Sprint__c> mapSprint = new Map<Id, copado__Sprint__c>(
        [
          SELECT Id, Name
          FROM copado__Sprint__c
          WHERE
            Id IN :setSprintId
            AND copado__Status__c = :SPRINT_STATUS_INPROGRESS
        ]
      );
      if (mapSprint.isEmpty())
        return;
      for (copado__User_Story__c newUs : listPriorityChanged) {
        copado__Sprint__c sprint = mapSprint.get(newUs.copado__Sprint__c);
        if (sprint != null) {
          Boolean isSalami = false;
          for (String spName : LIST_SALAMI_NAMES) {
            // 08.07.2022 / Sophal Noch / US-0011960 salami sprint has no record type, so use name to identify it. ex: Salami Stream, 'Salami Iteration
            if (sprint.Name.toLowerCase().contains(spName)) {
              isSalami = true;
              break;
            }
          }
          if (isSalami && newUs.RecordTypeId == RECORDTYPEID_USER_STORY)
            newUs.BA_Priority__c.addError(
              Label.ErrorChangeBAPriorityWhenApproved
            );
          if (isSalami && newUs.RecordTypeId == RECORDTYPEID_BUG)
            newUs.Bug_Priority__c.addError(
              Label.ErrorChangeBugPriorityWhenApproved
            );
        }
      }
    }
  }

  /*****************************************************************************************************************************
    @ Method	:   checkStatus
    @ Version	:   1.0
    @ Author	: 	Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose	:	US-0011909 - Implement restrictions on changing status of a user story
    @ Trigger 	: 	before update
	@ Param 	: 	List<copado__User_Story__c> listNew, Map<Id,copado__User_Story__c> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 31.08.2022 / Sambath Seng / Create Method
                      14.09.2022 / Sambath Seng / US-0012624 - Error when updating Status & Sprint together for a User Story/Bug
    *****************************************************************************************************************************/
  // public static void checkStatus(List<copado__User_Story__c> listNew,Map<Id,copado__User_Story__c> mapOld){
  //     Boolean isAdmin = (new Set<Id>{ApexUtil.ADMIN_PROFILE_ID,ApexUtil.ADMIN_LT_PRIV_PROFILE_ID}).contains(Userinfo.getprofileId());
  //     if(isAdmin){
  //         return;
  //     }
  //     List<copado__User_Story__c> listUserStory = new List<copado__User_Story__c>();
  //     Set<Id> setSprintId = new Set<Id>();
  //     for(copado__User_Story__c newUs : listNew){
  //         copado__User_Story__c oldUs = mapOld.get(newUs.Id);
  //         if(newUs.recordTypeId != RECORDTYPEID_HELPER && newUs.copado__Status__c != oldUs.copado__Status__c && SET_RESTRICTION_STATUS.contains(newUs.copado__Status__c)){
  //             if(newUs.copado__Sprint__c != null){
  //                 listUserStory.add(newUs);
  //                 setSprintId.add(newUs.copado__Sprint__c);
  //             }else{
  //                 newUs.addError(Label.ChangingUserstoryStatusError.replace('{Status}', newUs.copado__Status__c).replace('{SprintNumber}',''));
  //             }
  //         }
  //     }
  //     if(!listUserStory.isEmpty()){
  //         Map<Id, copado__Sprint__c> mapSprint = new Map<Id, copado__Sprint__c>([SELECT Id,Name,Active_Sprint__c FROM copado__Sprint__c WHERE Id IN: setSprintId]);
  //         for(copado__User_Story__c oUS: listUserStory){
  //             copado__Sprint__c cpSpr = mapSprint.get(oUS.copado__Sprint__c);
  //             if(!cpSpr.Active_Sprint__c || (cpSpr.Active_Sprint__c && !cpSpr.Name.replaceAll('[^0-9.]', '').isNumeric())){
  //                 oUS.addError(Label.ChangingUserstoryStatusError.replace('{Status}', oUS.copado__Status__c).replace('{SprintNumber}', oUS.copado__Sprint__c == null ? '' : mapSprint.isEmpty() ? '' : mapSprint.get(oUS.copado__Sprint__c).Name));
  //             }
  //         }

  //     }
  // }

  /*****************************************************************************************************************************
    @ Method	:   validateFieldsWhenStatusApproved
    @ Version	:   1.0
    @ Author	: 	Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose	:	US-0011910 - Implement mandatory check on additional fields in a user story
    @ Trigger 	: 	before update
	@ Param 	: 	List<copado__User_Story__c> listNew, Map<Id,copado__User_Story__c> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 06.10.2022 / Acmatac SEING / Create Method
    *****************************************************************************************************************************/
  // public static void validateFieldsWhenStatusApproved(List<copado__User_Story__c> listNew,Map<Id,copado__User_Story__c> mapOld){
  //     Set<String> listMatchingStatus = new Set<String>{STATUS_APPROVED, STATUS_IN_DEV, STATUS_DEPLOYED_IN_QA, STATUS_DEPLOYED_IN_UAT};
  //     for(copado__User_Story__c newUs : listNew){
  //         copado__User_Story__c oldUs = mapOld.get(newUs.Id);
  //         if(newUs.RecordTypeId == RECORDTYPEID_USER_STORY && oldUs.copado__Status__c != newUs.copado__Status__c && listMatchingStatus.contains(newUs.copado__Status__c)){
  //             if(String.isBlank(newUs.Requirement_Request__c)){
  //                 newUs.Requirement_Request__c.addError(Label.Complete_This_Field);
  //             }
  //             if(newUs.Business_Value_Points__c == null || newUs.Business_Value_Points__c <= 0){
  //                 newUs.Business_Value_Points__c.addError(Label.Complete_This_Field);
  //             }
  //             if(String.isBlank(newUs.Risk__c)){
  //                 newUs.Risk__c.addError(Label.Complete_This_Field);
  //             }
  //             if(String.isBlank(newUs.copado__Business_Analyst__c)){
  //                 newUs.copado__Business_Analyst__c.addError(Label.Complete_This_Field);
  //             }
  //             if(String.isBlank(newUs.Description__c)){
  //                 newUs.Description__c.addError(Label.Complete_This_Field);
  //             }
  //         }

  //     }
  // }

  /*****************************************************************************************************************************
    @ Method	:   moratoriumValidation
    @ Version	:   1.0
    @ Author	: 	Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose	:	US-0012872 - Moratorium approval process
    @ Trigger 	: 	before update
	@ Param 	: 	List<copado__User_Story__c> listNew, Map<Id,copado__User_Story__c> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 06.10.2022 / Acmatac SEING / Create Method
    *****************************************************************************************************************************/
  public static void moratoriumValidation(
    List<copado__User_Story__c> listNew,
    Map<Id, copado__User_Story__c> mapOld
  ) {
    // Validation should be working only in Moratorium period
    if (
      !(System.today() >= Date.valueOf(Label.MoratoriumFromDate) &&
      System.today() <= Date.valueOf(Label.MoratoriumEndDate))
    ) {
      return;
    }

    Set<String> credentialNames = new Set<String>{ 'Sprint UAT', 'Staging' };
    Set<Id> credentialIds = (new Map<Id, copado__Org__c>(
        [SELECT Id FROM copado__Org__c WHERE Name IN :credentialNames]
      ))
      .keySet();
    for (copado__User_Story__c newUs : listNew) {
      copado__User_Story__c oldUs = mapOld.get(newUs.Id);
      if (
        (oldUs.copado__Promote_and_Deploy__c !=
        newUs.copado__Promote_and_Deploy__c ||
        oldUs.copado__Promote_Change__c != newUs.copado__Promote_Change__c) &&
        (newUs.copado__Promote_and_Deploy__c ||
        newUs.copado__Promote_Change__c) &&
        !newUs.Moratorium_Approved__c &&
        credentialIds.contains(newUs.copado__Org_Credential__c)
      ) {
        //
        newUs.addError(Label.MoratoriumValidationMessage);
      }
    }
  }
  /*****************************************************************************************************************************
    @ Method	:   isAdmin
    @ Version	:   1.0
    @ Author	: 	Vimean Heng (vimean.heng@gaea-sys.com)
    @ Purpose	:	US-0015680 - [Flow Error] User Story - After Update - Update Feature Request" Flow
    @ Trigger 	: 	before insert, before update
	  @ Param 	: 	List<copado__User_Story__c> listNew
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 09.08.2024/ Vimean Heng / US-0015680 - [Flow Error] User Story - After Update - Update Feature Request" Flow
    *****************************************************************************************************************************/
  private static boolean isAdmin(){
    //follow the validation rule condition in FR
    return UserInfo.getProfileId() == ApexUtil.ADMIN_PROFILE_ID  || UserInfo.getProfileId() == ApexUtil.ADMIN_LT_PRIV_PROFILE_ID || UserInfo.getProfileId() == ApexUtil.BUSINESS_ADMIN_PROFILE;
  }
  /*****************************************************************************************************************************
    @ Method	:   isHivePlatform
    @ Version	:   1.0
    @ Author	: 	Vimean Heng (vimean.heng@gaea-sys.com)
    @ Purpose	:	  US-0015843 - Allow to assign Hive Platform stories to all 3 Scrum teams
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 12.09.2024/ Vimean Heng / US-0015843 - Allow to assign Hive Platform stories to all 3 Scrum teams
    *****************************************************************************************************************************/
  private static boolean isHivePlatform(copado__User_Story__c story,copado__User_Story__c oldStory,HIVE_Products__c hiveProduct){
    //this is hive platform, trigger when team has been change and no change Feature Request and custom label hive platform contains hive product name, and story is bug or user story
    return oldStory != null && story.copado__Team__c <> oldStory.copado__Team__c && story.Requirement_Request__c == oldStory.Requirement_Request__c && hiveProduct != null && String.isNotBlank(Label.Hive_Platform) && Label.Hive_Platform.contains(hiveProduct.Name) && (story.RecordTypeId == RECORDTYPEID_BUG || story.RecordTypeId == RECORDTYPEID_USER_STORY);
  }
  /*****************************************************************************************************************************
    @ Method	:   validateFeatureRequest
    @ Version	:   1.0
    @ Author	: 	Vimean Heng (vimean.heng@gaea-sys.com)
    @ Purpose	:	US-0015680 - [Flow Error] User Story - After Update - Update Feature Request" Flow
    @ Trigger 	: 	before insert, before update
	  @ Param 	: 	List<copado__User_Story__c> listNew
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 09.08.2024/ Vimean Heng / US-0015680 - [Flow Error] User Story - After Update - Update Feature Request" Flow
    *****************************************************************************************************************************/
  public static void validateFeatureRequest(List<copado__User_Story__c> listNew){
    Map<String,copado__User_Story__c> mUS = new Map<String,copado__User_Story__c>();
    for (copado__User_Story__c story : listNew) {
      //VM US-0015680 - check FR's Hive Project before flow update FR
      if(String.isNotBlank(story.Requirement_Request__c)  && (story.copado__Status__c == DRAFT_STATUS || story.copado__Status__c == READY_FOR_REFINEMENT_STATUS || story.copado__Status__c == APPROVE_STATUS) && isAdmin()){
        mUS.put(story.Requirement_Request__c,story);
      }
    }
    if(!mUS.isEmpty()){
      Map<String, Object> parBinds = new Map<String, Object>{'ids' => mUS.keySet(),'sm'=>'SM_%'};
      String strFR = 'SELECT Id,Name,Hive_Project__c FROM Requirement_Request__c where Hive_Project__c = null AND (NOT(Name like :sm)) AND ID IN :ids';
      List<Requirement_Request__c> lsFR = ApexSafe.query().doQuery(strFR,parBinds);
      if(!lsFR.isEmpty()){
        for(Requirement_Request__c fr : lsFR){
          mUS.get(fr.Id).addError(System.Label.Feature_Request_Missing_Hive_Project);
        }
      }
    }
  }
  /*****************************************************************************************************************************
    @ Method	:   populateTeam
    @ Version	:   1.0
    @ Author	: 	vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose	:	US-0013924 - Team and HIVE Product automations
    @ Trigger 	: 	before insert, before update
	@ Param 	: 	List<copado__User_Story__c> listNew, Map<Id,copado__User_Story__c> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 26.07.2023 / vadhanak voun / US-0013924 - Team and HIVE Product automations
    @                                            /AC3 New Automation to autopopulate Team when HIVE Product is selected during US or Bug creation
    @               : 07.08.2023 / vadhanak voun / US-0013957 - Do not allow to change the Team if Hive Product is not changed
    @               : 26.10.2023/ vadhanak voun / US-0014332 - HIVE Product to Team mapping
    @               : 12.09.2024/ Vimean Heng / US-0015843 - Allow to assign Hive Platform stories to all 3 Scrum teams
    *****************************************************************************************************************************/
  public static void populateTeam(
    List<copado__User_Story__c> listNew,
    Map<Id, copado__User_Story__c> mapOld,
    Boolean isNew
  ) {
    List<copado__User_Story__c> listNewUpdate = new List<copado__User_Story__c>();
    Set<String> setHivePro = new Set<String>();

    Set<String> setTeamChange = new Set<String>();
    for (copado__User_Story__c story : listNew) {

      Boolean isChanged = (!isNew &&
      story.HIVE_Products__c <> mapOld.get(story.Id).HIVE_Products__c);
      if (
        (isNew &&
        story.HIVE_Products__c <> null &&
        story.copado__Team__c == null) || isChanged
      ) {
        listNewUpdate.add(story);
        setHivePro.add(story.HIVE_Products__c);
      }
      //NK:07/08/2023:US-0013957
      //when a product and team is already populated, and I try to update the team name,
      else if (
        !isNew &&
        story.copado__Team__c <> null &&
        story.copado__Team__c <> mapOld.get(story.Id).copado__Team__c
      ) {
        listNewUpdate.add(story);
        setHivePro.add(story.HIVE_Products__c);
        setTeamChange.add(story.Id);
      }
    }
    
    if (!setHivePro.isEmpty()) {
      //NK:26/10/2023:US-0014332
      ////get the name of HiveProduct, since we have only Id here
      // Map<Id,HIVE_Products__c> mapHivePro = new Map<Id,HIVE_Products__c>([Select Id,Name From HIVE_Products__c Where Id IN:setHivePro]);
      // Map<String,String> mapProTeam = new Map<String,String>();
      // Map<String,String> mapTeam = new Map<String,String>();
      // //get pre defined metadata mapping
      // for(Hive_Product_Team_Mapping__mdt mdt : [Select Id,MasterLabel,DeveloperName,Team__c From Hive_Product_Team_Mapping__mdt])
      // {
      //     mapProTeam.put(mdt.MasterLabel,mdt.Team__c);
      // }

      // for(copado__Team__c team : [Select Id,Name From copado__Team__c Where Name IN :mapProTeam.values()])
      // {
      //     mapTeam.put(team.Name,team.Id);
      //     mapTeam.put(team.Id,team.Name);
      // }
      //NK:26/10/2023:US-0014332
      Map<Id, HIVE_Products__c> mapHProduct = new Map<Id, HIVE_Products__c>(
        [SELECT Id, Name, Team__c FROM HIVE_Products__c WHERE Id IN :setHivePro]
      );

      for (copado__User_Story__c story : listNewUpdate) {
        // String proName = mapHivePro.get(story.HIVE_Products__c).Name;
        // String teamName = mapProTeam.get(proName); //Team name from mapping

        // //NK:07/08/2023:US-0013957
        // //it should check the Hive Product again and give me an error if the new team name doesn't match to the Hive Product.
        //if(setTeamChange.contains(story.Id) && mapTeam.get(story.copado__Team__c) <> teamName)//new team name is not the same as defined in the mapping
        System.debug('mapOld' + mapOld);
        boolean isHivePlatform = mapOld == null ? false : isHivePlatform(story,mapOld.get(story.Id),mapHProduct.get(story.HIVE_Products__c));
        if (
          setTeamChange.contains(story.Id) &&
          story.copado__Team__c <>
          mapHProduct.get(story.HIVE_Products__c).Team__c && 
          !isHivePlatform
        ) {
          story.copado__Team__c.addError(
            System.Label.Error_Invalid_HiveProduct_Team
          );
        } else if(!isHivePlatform){
          // story.copado__Team__c = mapTeam.containsKey(teamName)? mapTeam.get(teamName):story.copado__Team__c; //in case team does not exist, then just keep the old value

          //NK:26/10/2023:US-0014332
          story.copado__Team__c = mapHProduct.get(story.HIVE_Products__c)
            .Team__c;
        }
      }
    }
  }
}