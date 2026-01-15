@isTest
private class UserStoryTriggerHandlerTest {
  @testSetup
  static void setup() {
    copado__User_Story__c story = new copado__User_Story__c();
    story.copado__User_Story_Title__c = 'Test';
    story.PO_Reviewed__c = true;
    insert story;
    insert new EBH_ActiveTriggers__c(
      Name = 'EBH Trigger Controller',
      Subscription_Request_Trigger__c = false,
      CopadoUserStory__c = true
    );
  }
  @isTest
  static void testCloneNewUserStory() {
    copado__User_Story__c cs = [
      SELECT id, copado__status__c, po_reviewed__c
      FROM copado__user_story__c
      LIMIT 1
    ];
    copado__User_Story__c csClone = cs.clone();

    Test.startTest();
    upsert csClone;
    csClone = [
      SELECT id, copado__status__c, po_reviewed__c
      FROM copado__user_story__c
      WHERE id = :csClone.id
    ];
    System.assert(
      csClone.PO_Reviewed__c = true,
      'PO Reivew = TRUE, Because it was in COPADO_USER_STORY_EXCLUDE_FIELDS field set'
    );
    System.assertEquals('Draft', csClone.copado__status__c, 'Status is Draft');
    Test.stopTest();
  }

  /***************************************START TEST METHOD FOR PROCESS BUILDER***************************************************/

  /**PROCESS BUILDER NAME: Process Builder for User Story Created or Edited
       Loumang: 12-02-2021 
	*/
  @isTest
  public static void test_Process_updateFeatureRequestStatusComingSoon() {
    Map<String, Object> mapData = generateData();
    Hive_Project__c hp = (Hive_Project__c) mapData.get('hp1');
    Requirement_Request__c fr = (Requirement_Request__c) mapData.get('fr1');

    copado__User_Story__c userStory1 = createStory('Draft', fr.Id);
    copado__User_Story__c userStory2 = createStory('Draft', fr.Id);

    insert new List<copado__User_Story__c>{ userStory1, userStory2 };

    Test.startTest();
    userStory1.copado__Status__c = 'Approved';
    userStory1.Business_Value_Points__c = 100;
    userStory1.BA_Priority__c = 'Low';
    userStory1.Include_into_Release_Comms__c = 'No'; //NK:22/08/2023:US-0014022
    update userStory1;
    System.assertEquals(
      'Development',
      [SELECT Status__c FROM Requirement_Request__c WHERE id = :fr.Id].Status__c
    );
    Test.stopTest();
  }

  @isTest
  public static void test_Process_updateFeatureRequestStatusRequirementAccepted() {
    Map<String, Object> mapData = generateData();
    Hive_Project__c hp = (Hive_Project__c) mapData.get('hp1');
    Requirement_Request__c fr = (Requirement_Request__c) mapData.get('fr1');

    copado__User_Story__c userStory1 = createStory('Draft', fr.Id);
    copado__User_Story__c userStory2 = createStory('Draft', fr.Id);

    insert new List<copado__User_Story__c>{ userStory1, userStory2 };

    Test.startTest();
    userStory1.copado__Status__c = 'Backburner';
    userStory1.Business_Value_Points__c = 100;
    userStory1.BA_Priority__c = 'Low';
    update userStory1;
    System.assertEquals(
      'Requirement Accepted',
      [SELECT Status__c FROM Requirement_Request__c WHERE id = :fr.Id].Status__c
    );
    Test.stopTest();
  }
  @isTest
  public static void test_Process_notifyPO() {
    Map<String, Object> mapData = generateData();
    User admin = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE
      LIMIT 1
    ];
    Profile objProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
      LIMIT 1
    ];
    System.runAs(admin) {
      copado__Org__c credential = new copado__Org__c(
        Name = 'Testing Credential'
      );
      insert credential;
      User objUser = new User(
        Alias = 'LA1',
        Email = 'jacques.th@maxappsltd.co.uk',
        EmailEncodingKey = 'UTF-8',
        LastName = 'LA',
        LocaleSidKey = 'en_US',
        LanguageLocaleKey = 'en_US',
        ProfileId = objProfile.Id,
        TimeZoneSidKey = 'Europe/London',
        UserName = 'la@hive.project.com.jacquesdev'
      );
      insert objUser;

      copado__Project__c cp = (copado__Project__c) mapData.get('cp1');
      Hive_Project__c hp = (Hive_Project__c) mapData.get('hp1');
      Requirement_Request__c fr = (Requirement_Request__c) mapData.get('fr1');

      RecordType bugRecType = ApexUtil.getRecordTypeByName(
        'copado__User_Story__c',
        'Bug'
      );
      copado__User_Story__c userStory = createStory('Draft', fr.Id);

      userStory.Business_Value_Points__c = 100;
      userStory.BA_Priority__c = 'Low';
      userStory.BU_Requester__c = objUser.Id;
      userStory.Component__c = 'Salesforce - Admin';
      userStory.copado__Project__c = cp.Id;
      userStory.RecordTypeID = bugRecType.Id;
      userStory.Hive_Project__c = hp.Id;
      userStory.copado__Org_Credential__c = credential.Id;
      insert userStory;

      Test.startTest();
      userStory.Bug_Priority__c = 'P3';
      userStory.Exclude_from_promotion__c = false;
      update userStory;
      Test.stopTest();
    }

  }
  private static Map<String, Object> generateData() {
    Hive_Project__c hp = new Hive_Project__c(
      Name = 'test Hive',
      Status__c = 'Under Review (Requirement Clarification)'
    );
    insert hp;
    copado__Project__c cp = new copado__Project__c(
      Name = 'test copado project'
    );
    insert cp;

    RecordType featureRequestRecType = ApexUtil.getRecordTypeByName(
      'Requirement_Request__c',
      'Feature_Request'
    );

    Requirement_Request__c fr = new Requirement_Request__c(
      Name = 'test la',
      Hive_Project__c = hp.Id,
      Region__c = 'DE',
      RecordTypeID = featureRequestRecType.Id
    );
    insert fr;

    return new Map<String, Object>{ 'hp1' => hp, 'cp1' => cp, 'fr1' => fr };
  }

  static copado__User_Story__c createStory(String status, String reqId) {
    return new copado__User_Story__c(
      copado__Status__c = status,
      Requirement_Request__c = reqId
    );
  }

  /***************************************END TEST METHOD FOR PROCESS BUILDER***************************************************/
}