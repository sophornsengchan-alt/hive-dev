/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class EBH_TaskTriggerHandlerTest {
  @TestSetup
  static void setup() {
    User adminUser = [
      SELECT Id
      FROM User
      WHERE IsActive = TRUE AND Profile.Name = 'System Administrator'
      LIMIT 1
    ];
    System.runAs(adminUser) {
      EBH_TestDataFactory.setUpCustomSettings();
    }

  }

  static testMethod void testPopulateTargetDateFromTask() {
    //EBH_TestDataFactory.setUpCustomSettings();
    List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');

    RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName(
      'EBH_Filter__c',
      'EBH_ManualSellerList'
    );
    EBH_Filter__c sellerList1 = new EBH_Filter__c(
      Name = 'test m1',
      RecordTypeId = rtSellerlist.Id
    );
    insert sellerList1;

    List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(
      2,
      'Test Campaign1',
      'UK',
      EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,
      null,
      'Feasibility'
    );
    List<Contact> contacts = EBH_TestDataFactory.createContacts(
      4,
      'Test Contact',
      sellers[0].id
    );
    contacts[0].EBH_PhoneOptOut__c = false;
    contacts[1].EBH_PhoneOptOut__c = false;
    contacts[2].EBH_PhoneOptOut__c = false;
    contacts[3].EBH_PhoneOptOut__c = false;
    update contacts;

    campaigns1[0].EBH_ChannelMP__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
    campaigns1[0].EBH_Channel__c = 'GCX Outreach (Phone)';
    campaigns1[0].EBH_SellerList__c = sellerList1.Id;
    update campaigns1;

    List<CampaignMember> listCM0 = EBH_TestDataFactory.createCampaignMembers2(
      1,
      campaigns1[0].Id,
      contacts[0].Id,
      11,
      System.today() - 5,
      System.today()
    );
    listCM0[0].EBH_ResponseCode__c = 10;
    update listCM0;

    EBH_TargetedSeller__c ts = new EBH_TargetedSeller__c(
      EBH_Seller__c = sellers[0].Id,
      EBH_SellerList__c = sellerList1.Id,
      Priority__c = 10,
      EBH_ExitCode__c = '20'
    );
    insert ts;

    Campaign_Targeting__c ct = new Campaign_Targeting__c(
      Campaign__c = campaigns1[0].Id,
      Seller_List__c = sellerList1.Id
    );
    insert ct;

    Test.startTest();

    Test.setCurrentPage(Page.AssignTasks);
    ApexPages.StandardController stdController = new ApexPages.StandardController(
      campaigns1[0]
    );
    AssignTasksController con = new AssignTasksController(stdController);
    con.validUser = true;
    //con.assignCallTasks();
    con.showConfirmNumber = false;
    con.createUpdateTasks();

    //Task[] taskSel = [Select Id,WhatId,WhoId,EBH_CampaignMemberId__c,Call_attempts__c From Task Where WhatId=: campaigns1[0].Id];

    //System.assertEquals(1,taskSel.size(),'1 tasks created for the first click. 1 task per contact per seller');
    //taskSel[0].Call_attempts__c = 1;

    //listCM0[0].EBH_ResponseCode__c = 11;
    //update listCM0;

    //update taskSel[0];
    //system.debug('--------------xxxx-------------------xxx----------------------');
    //CampaignMember cmSel = [Select Id,Target_Date__c From CampaignMember Where Id=:taskSel[0].EBH_CampaignMemberId__c];
    //System.assertEquals(System.today(),cmSel.Target_Date__c,' date today populated from task updated call attemps = 1');

    //cmSel.Target_Date__c = null;
    //update cmSel;

    //Task t2 = new Task(Call_attempts__c=1,Subject = 'test', WhatId=taskSel[0].WhatId,WhoId=taskSel[0].WhoId,EBH_CampaignMemberId__c=taskSel[0].EBH_CampaignMemberId__c);
    //insert t2;
    //cmSel = [Select Id,Target_Date__c From CampaignMember Where Id=:taskSel[0].EBH_CampaignMemberId__c];
    //System.assertEquals(System.today(),cmSel.Target_Date__c,' date today populated from new task inserted with call attemps = 1');

    Test.stopTest();
  }
  static testMethod void testUrgencyTask() {
    //EBH_TestDataFactory.setUpCustomSettings();
    List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
    RecordType contactManaul = ApexUtil.getRecordTypeByName(
      'Contact',
      'EBH_MANUAL'
    );
    List<Contact> listContact = new List<Contact>{
      new Contact(
        EBH_Status__c = 'Active',
        LastName = 'last1',
        AccountId = sellers[0].Id,
        recordTypeId = contactManaul.Id,
        EBH_DataOrigin__c = 'test'
      ),
      new Contact(
        EBH_Status__c = 'Inactive',
        LastName = 'last2',
        AccountId = sellers[0].Id,
        recordTypeId = contactManaul.Id,
        EBH_DataOrigin__c = 'test'
      )
    };

    insert listContact;

    Test.startTest();
    Task t1 = new Task(
      WhatId = sellers[0].Id,
      WhoId = listContact[0].Id,
      Subject = EBH_ConstantsUtility.TTH_URGENCYTASK
    );
    insert t1;

    Test.stopTest();
  }

  static testMethod void testResponseCodeChange() {
    //EBH_TestDataFactory.setUpCustomSettings();
    List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
    RecordType contactManaul = ApexUtil.getRecordTypeByName(
      'Contact',
      'EBH_MANUAL'
    );
    List<Contact> listContact = new List<Contact>{
      new Contact(
        EBH_Status__c = 'Active',
        LastName = 'last1',
        AccountId = sellers[0].Id,
        recordTypeId = contactManaul.Id,
        EBH_DataOrigin__c = 'test'
      ),
      new Contact(
        EBH_Status__c = 'Inactive',
        LastName = 'last2',
        AccountId = sellers[0].Id,
        recordTypeId = contactManaul.Id,
        EBH_DataOrigin__c = 'test'
      )
    };

    insert listContact;
    List<Campaign> campaigns = EBH_TestDataFactory.createCampaigns(
      1,
      'Request',
      'UK',
      'EBH_AMOutreach'
    );
    campaigns[0].survey_id__c = '1t6nqa0iq6nmy';

    update campaigns;

    List<CampaignMember> campmembers = EBH_TestDataFactory.createCampaignMembers(
      1,
      campaigns[0].id,
      listContact[0].id,
      false
    );
    //insert campmembers;

    Test.startTest();
    Task t1 = new Task(
      WhatId = sellers[0].Id,
      WhoId = listContact[0].Id,
      Subject = EBH_ConstantsUtility.TTH_URGENCYTASK
    );
    t1.ebh_campaignmemberid__c = campmembers[0].id;
    insert t1;
    t1.EBH_ResponseCode__c = 30;
    update t1;
    Task tcheck = [
      SELECT id, EBH_ResponseCode__c, EBH_CampaignMemberId__c
      FROM task
      WHERE id = :t1.id
    ];
    CampaignMember cmcheck = [
      SELECT id, ebh_responsecode__c
      FROM campaignmember
      WHERE id = :tcheck.EBH_CampaignMemberId__c
    ];
    System.debug(
      '[][][][]' +
        cmcheck.EBH_ResponseCode__c +
        '[][][][]' +
        tcheck.EBH_ResponseCode__c
    );
    //  System.assert(cmcheck.EBH_ResponseCode__c==tcheck.EBH_ResponseCode__c);

    Test.stopTest();
  }
  static testMethod void testIncreaseCoverage() {
    //EBH_TestDataFactory.setUpCustomSettings();
    List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');

    RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName(
      'EBH_Filter__c',
      'EBH_ManualSellerList'
    );
    EBH_Filter__c sellerList1 = new EBH_Filter__c(
      Name = 'test m1',
      RecordTypeId = rtSellerlist.Id
    );
    insert sellerList1;

    List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(
      2,
      'Test Campaign1',
      'UK',
      EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,
      null,
      'Feasibility'
    );
    List<Contact> contacts = EBH_TestDataFactory.createContacts(
      4,
      'Test Contact',
      sellers[0].id
    );
    contacts[0].EBH_PhoneOptOut__c = false;
    contacts[1].EBH_PhoneOptOut__c = false;
    contacts[2].EBH_PhoneOptOut__c = false;
    contacts[3].EBH_PhoneOptOut__c = false;
    update contacts;

    campaigns1[0].EBH_ChannelMP__c = EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
    campaigns1[0].EBH_Channel__c = 'GCX Outreach (Phone)';
    campaigns1[0].EBH_SellerList__c = sellerList1.Id;
    update campaigns1;

    List<CampaignMember> listCM0 = EBH_TestDataFactory.createCampaignMembers2(
      1,
      campaigns1[0].Id,
      contacts[0].Id,
      11,
      System.today() - 5,
      System.today()
    );
    listCM0[0].EBH_ResponseCode__c = 10;
    update listCM0;

    Test.startTest();
    Task t1 = new Task(
      Subject = 'test1',
      WhatId = campaigns1[0].Id,
      WhoId = contacts[0].Id,
      EBH_CampaignMemberId__c = listCM0[0].id
    );
    insert t1;

    /*-
        Boolean isCorrectType = oTask.WhatId.getSObjectType() == Campaign.sObjectType 
                                        && oTask.WhoId.getSObjectType() == Contact.sObjectType; 
                if(isCorrectType){

*/
    t1.status = 'Closed';
    t1.EBH_ResponseCode__c = 50;

    update t1;
  }
  static testMethod void testPreventActivityOnInactiveContact() {
    //EBH_TestDataFactory.setUpCustomSettings();
    List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
    RecordType contactManaul = ApexUtil.getRecordTypeByName(
      'Contact',
      'EBH_MANUAL'
    );
    List<Contact> listContact = new List<Contact>{
      new Contact(
        EBH_Status__c = 'Active',
        LastName = 'last1',
        AccountId = sellers[0].Id,
        recordTypeId = contactManaul.Id,
        EBH_DataOrigin__c = 'test'
      ),
      new Contact(
        EBH_Status__c = 'Inactive',
        LastName = 'last2',
        AccountId = sellers[0].Id,
        recordTypeId = contactManaul.Id,
        EBH_DataOrigin__c = 'test'
      )
    };

    insert listContact;

    Test.startTest();
    Task t1 = new Task(
      Subject = 'test1',
      WhatId = sellers[0].Id,
      WhoId = listContact[0].Id
    );
    insert t1;

    Task t2 = new Task(
      Subject = 'test2',
      WhatId = sellers[0].Id,
      WhoId = listContact[1].Id
    );
    try {
      insert t2;
    } catch (Exception ex) {
      System.assert(true, 'inactive contact not allowed');
    }

    Event e1 = new Event(
      Subject = 'test1',
      WhatId = sellers[0].Id,
      WhoId = listContact[0].Id,
      DurationInMinutes = 10,
      ActivityDateTime = system.now()
    );
    insert e1;

    Event e2 = new Event(
      Subject = 'test2',
      WhatId = sellers[0].Id,
      WhoId = listContact[1].Id,
      DurationInMinutes = 20,
      ActivityDateTime = system.now()
    );
    try {
      insert e2;
    } catch (Exception ex) {
      System.assert(true, 'inactive contact not allowed');
    }
    Test.stopTest();
  }
  static testMethod void testadddatetime() {
    //EBH_TestDataFactory.setUpCustomSettings();
    List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
    sellers[0].EBH_UrgencyReason__c = 'Will not be blank';
    update sellers;

    List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(
      1,
      'Test Campaign1',
      'UK',
      EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,
      null,
      'Feasibility'
    );
    /*
* if(t.Call_Back_Window_Start_CT__c!=null && t.Call_Back_Start_Time__c!=null){
t.Call_Back_Window_start__c=addTime(t.Call_Back_Window_Start_CT__c, t.Call_Back_Start_Time__c);
System.debug('Offset= ' + offset);
System.debug('t.Call_Back_Window_start__c= ' + t.Call_Back_Window_start__c);                

t.Call_Back_Window_start__c=t.Call_Back_Window_start__c.addSeconds(offset/1000);


return (t!=null && null!=t.WhatId && null!=t.type && t.type.equals(EBH_ConstantsUtility.CAMPAIGN_CHANNEL_PHONE_OUTREACH) && null!=t.status&&  t.Status.equals(EBH_ConstantsUtility.AOC_TASKSTATUS));

}

    if(t.Call_Back_Window_end_CT__c!=null && t.Call_Back_End_Time__c!=null)          {
                t.Call_Back_Window_end__c=addTime(t.Call_Back_Window_end_CT__c,t.Call_Back_End_Time__c);
                t.Call_Back_Window_end__c=t.Call_Back_Window_end__c.addSeconds(offset/1000);
            }
        }
*/
    Test.startTest();
    Task t1 = new Task(
      Subject = 'test1',
      WhatId = sellers[0].Id,
      Call_Back_Window_Start_CT__c = Date.today(),
      Call_Back_Start_Time__c = '16:30'
    );
    Task t2 = new Task(
      Subject = 'test2',
      WhatId = campaigns1[0].Id,
      Call_Back_Window_Start_CT__c = Date.today(),
      Call_Back_Start_Time__c = '16:30',
      type = EBH_ConstantsUtility.CAMPAIGN_CHANNEL_PHONE_OUTREACH
    );
    Task t3 = new Task(
      WhatId = campaigns1[0].Id,
      Call_Back_Window_Start_CT__c = Date.today(),
      Call_Back_Window_end__c = date.today(),
      Call_Back_End_Time__c = '18:00',
      Call_Back_Start_Time__c = '16:30',
      type = EBH_ConstantsUtility.CAMPAIGN_CHANNEL_PHONE_OUTREACH,
      subject = 'FOLLOWUPCALL'
    );
    Task t4 = new Task(
      WhatId = campaigns1[0].Id,
      Call_Back_Window_Start_CT__c = Date.today(),
      Call_Back_Start_Time__c = '16:30',
      type = EBH_ConstantsUtility.CAMPAIGN_CHANNEL_PHONE_OUTREACH,
      subject = 'FOLLOWUPCALL',
      call_attempts__c = 1,
      Follow_Up_Task__c = true
    );
    Task t5 = new Task(
      WhatId = campaigns1[0].Id,
      Call_Back_Window_Start_CT__c = Date.today(),
      Call_Back_Start_Time__c = '16:30',
      type = EBH_ConstantsUtility.CAMPAIGN_CHANNEL_PHONE_OUTREACH,
      subject = 'FOLLOWUPCALL',
      call_attempts__c = 1,
      Follow_Up_Task__c = true
    );

    insert new List<Task>{ t1, t2, t3, t4, t5 };
    t5.status = 'Closed';
    t5.EBH_ResponseCode__c = 50;
    update t5;
    Test.stopTest();
  }
  static testMethod void testTaskHistory() {
    //EBH_TestDataFactory.setUpCustomSettings();
    List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');

    List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(
      1,
      'Test Campaign1',
      'UK',
      EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,
      null,
      'Feasibility'
    );

    Test.startTest();
    Task t1 = new Task(Subject = 'test1', WhatId = sellers[0].Id);
    Task t2 = new Task(Subject = 'test2', WhatId = campaigns1[0].Id);

    insert new List<Task>{ t1, t2 };
    t1.Call_attempts__c = 1;
    t2.Call_attempts__c = 2;

    update new List<Task>{ t1, t2 };

    Task_History__c[] th1sel = [
      SELECT Id, Name, Campaign__c
      FROM Task_History__c
      WHERE Task_ID__c = :t1.Id
    ];
    Task_History__c[] th2sel = [
      SELECT Id, Name, Campaign__c
      FROM Task_History__c
      WHERE Task_ID__c = :t2.Id
    ];

    System.assertEquals(
      0,
      th1sel.size(),
      ' what id is not camaign, no history created'
    );
    System.assertEquals(1, th2sel.size(), ' history created');

    Test.stopTest();
  }

  static testMethod void testPreventLogTask() {
    //EBH_TestDataFactory.setUpCustomSettings();
    List<User> stdUsers = new List<User>();
    List<Account> sellers = new List<Account>();
    //Task t1 = new Task(Subject ='test1', WhatId=sellers[0].Id,Log_Task__c=true);
    Task t1 = new Task();

    User adminUser = [
      SELECT Id
      FROM User
      WHERE IsActive = TRUE AND Profile.Name = 'System Administrator'
      LIMIT 1
    ];
    System.runAs(adminUser) {
      stdUsers = EBH_TestDataFactory.createUsers(1, 'Standard User');
      // List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller') ;
    }

    System.runAs(adminUser) {
      sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
      t1 = new Task(
        Subject = 'test1',
        WhatId = sellers[0].Id,
        Log_Task__c = true
      );
      insert t1;
    }

    Test.startTest();
    System.runAs(stdUsers[0]) {
      t1.subject = 'new subject';

      try {
        update t1;
      } catch (Exception ex) {
        System.assertNotEquals(
          ex.getMessage(),
          null,
          'user not allowed to edit on log task created by coupon seller trigger'
        );
      }
      try {
        delete t1;
      } catch (Exception ex) {
        System.assertNotEquals(
          ex.getMessage(),
          null,
          'user not allowed to delete log task created by coupon seller trigger'
        );
      }
    }

    // t1.Subject = 'admin subject';
    // update t1;

    System.runAs(adminUser) {
      t1.Subject = 'admin subject';
      update t1;
      Task t1_sel = [SELECT Id, Subject FROM Task WHERE Id = :t1.Id];
      System.assertEquals(
        t1_sel.Subject,
        'admin subject',
        'admin able to do everything'
      );
    }

    Test.stopTest();
  }

  @isTest
  public static void testCreateFulfilmentProject() {
    //EBH_TestDataFactory.setUpCustomSettings();
    List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
    List<Contact> contacts = EBH_TestDataFactory.createContacts(
      1,
      'Test Contact',
      sellers[0].id
    );
    List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(
      2,
      'DE GCX Fulfillment Campaign',
      'UK',
      EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,
      null,
      'Feasibility'
    );

    Test.startTest();

    Task t1 = new Task(
      Subject = 'test1',
      WhatId = campaigns1[0].Id,
      WhoId = contacts[0].Id
    );
    Task t2 = new Task(
      Subject = 'test2',
      WhatId = campaigns1[1].Id,
      WhoId = contacts[0].Id
    );
    insert t1;
    insert t2;
    List<EBH_Project__c> oProj = [
      SELECT Id
      FROM EBH_Project__c
      WHERE EBH_Seller__c = :sellers[0].Id
    ];
    //      System.assert(!oProj.isEmpty(), 'Fulfilment project should be created!');
    Test.stopTest();
  }

  @isTest
  private static void testUpdateUserAvailibilityWithTask() {
    insert new EBH_ActiveTriggers__c(
      Name = 'EBH Trigger Controller',
      UserAvailabilityTrigger__c = true,
      EBH_TaskTrigger__c = true
    );

    Id currentUserId = UserInfo.getUserId();

    Date d = Date.newInstance(
      Date.today().year(),
      Date.today().month(),
      Date.today().day()
    );
    Datetime dt = (DateTime) d;
    String dow = dt.format('EEEE');
    if (dow == 'Saturday')
      d = Date.today().addDays(3);
    else if (dow == 'Sunday')
      d = Date.today().addDays(2);

    Datetime startDatetime = Datetime.newInstanceGmt(
      d.year(),
      d.month(),
      d.day(),
      8,
      0,
      0
    );
    Datetime endDatetime = Datetime.newInstanceGmt(
      d.year(),
      d.month(),
      d.day(),
      11,
      0,
      0
    );

    Task task = new Task(
      Subject = 'test User Availability',
      Update_User_Availability__c = false,
      Call_Back_Window_start__c = startDatetime,
      Call_Back_Window_end__c = endDatetime,
      OwnerId = currentUserId
    );
    insert task;

    Test.startTest();
    User_Availability__c uv = new User_Availability__c(
      Date__c = d,
      Unique_Id__c = (currentUserId +
      '#' +
      d),
      Available_Calls_Morning_Slot__c = 4,
      Available_Calls_Afternoon_Slot__c = 4,
      OwnerId = currentUserId
    );
    insert uv;
    uv = [
      SELECT
        Id,
        Date__c,
        Unique_Id__c,
        Scheduled_Calls_Morning_Slot__c,
        Scheduled_Calls_Afternoon_Slot__c
      FROM User_Availability__c
      WHERE Id = :uv.Id
    ];
    System.assertEquals(null, uv.Scheduled_Calls_Morning_Slot__c);

    task.Update_User_Availability__c = true;
    update task;

    uv = [
      SELECT
        Id,
        Date__c,
        Unique_Id__c,
        Scheduled_Calls_Morning_Slot__c,
        Scheduled_Calls_Afternoon_Slot__c
      FROM User_Availability__c
      WHERE Id = :uv.Id
    ];
    System.assertEquals(1, uv.Scheduled_Calls_Morning_Slot__c);

    Test.stopTest();
  }
  //create a new test method for EBH_TaskTriggerhHanDler upsertHistoryTask
  @isTest
  private static void testUpsertHistoryTask() {
    List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(
      1,
      'Test Campaign1',
      'UK',
      EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,
      null,
      'Feasibility'
    );

    Test.startTest();
    Task t2 = new Task(Subject = 'test2', WhatId = campaigns1[0].Id);

    insert new List<Task>{ t2 };
    t2.call_attempts__c = 1;
    update t2;
    // Call the method being tested
    t2.ebh_dmc__c = true;
    update t2;
    Test.stopTest();
    task_history__c th = [
      SELECT id, dmc__c, call_attempts__c
      FROM task_history__c
      WHERE Task_ID__c = :t2.id
      ORDER BY lastmodifieddate DESC
      LIMIT 1
    ];
    System.assertEquals(th.dmc__c, true, 'dmc__c should be true');
    System.assertEquals(th.call_attempts__c, 1, 'call_attempts__c should be 1');
  }

  @isTest
  static void testTransactionId() {
    List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(
      1,
      'Test Campaign1',
      'UK',
      EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH,
      null,
      'Feasibility'
    );

    Test.startTest();

    Task t2 = new Task(Subject = 'test2', WhatId = campaigns1[0].Id);

    insert new List<Task>{ t2 };

    t2.Call_attempts__c = 2;

    update new List<Task>{ t2 };

    Test.stopTest();
    Task_History__c[] th2sel = [
      SELECT Id, Name, Campaign__c, TransactionId__c
      FROM Task_History__c
      WHERE Task_ID__c = :t2.Id
    ];

    System.Assert.areEqual(
      th2sel[0].TransactionId__c,
      (String.valueOf(t2.Id) + '_' + String.valueOf(t2.Call_attempts__c))
    );
  }
}