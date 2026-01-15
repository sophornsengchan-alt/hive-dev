/**
* An apex page controller that supports self registration of users in communities that allow self registration
* @changes  2020 - 02 - 03 Added Test records for OpenClickToolsSurveyController
* @         2021 - 01 - 19 Added new test method for US-0008800 
*/
@IsTest public with sharing class RecordInboundCallControllerTest {
    @IsTest(SeeAllData=false) 
    public static void testCommunitiesSelfRegController() {
        //Create Campaign
        List<Campaign> lc = EBH_TestDataFactory.createCampaigns(1, 'testing_campaign', 'DE', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH);
        lc[0].survey_id__c='surveytest';
        lc[0].Inbound_Call__c=true;
        lc[0].Status = EBH_ConstantsUtility.CMRC_EXECUTION;
        update lc;
        
        List<Account> la = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        
        
        update la;
        Campaign c= new Campaign();
        c.inbound_call__c=true;
        c.survey_id__c='surveytest';
        c.RecordTypeId=EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID;
        c.status=EBH_ConstantsUtility.CMRC_EXECUTION;
        c.name='Testing Inbound Campaign';
        insert c;
        Test.startTest();
        
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(la[0]);
        RecordInboundCallController ricc = new RecordInboundCallController(sc);
        
        ricc.Campaign=c.iD;
        
        insert new EBH_OutboundLink__c (Name='EBH_OutboundLink__c',Clicktools_Inbound_Survey__c='ThisIsAtest',
                                        EBH_URL__c='http://www.ebay.com',
                                        EBH_TicketURL__c ='http://www.ebay.de',
                                        NPS_Survey_URL__c ='http://www.ebay.co.uk',
                                        HUB_Search__c ='http://www.hub.de',
                                        EBH_ExternalCampaignRecordTypeId__c ='IdTest',
                                        //EBH_DriverTreeBaseURL__c ='http://www.ebay.com',
                                        Clicktools_Outbound_Survey__c ='213434334',
                                        
                                        Clicktools_Epilogue_Survey__c ='23434343'
                                        );
        
        ricc.cancel();
        ricc.startsurvey();
        Test.stopTest();
        
        
        
        
    }    
    @IsTest(SeeAllData=false) 
    public static void OpenClickToolsSurveyControllertest() {
          EBH_TestDataFactory.setUpCustomSettings();  
        
        //Create Campaign
        List<Campaign> lc = EBH_TestDataFactory.createCampaigns(1, 'testing_campaign', 'DE', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH);
        lc[0].survey_id__c='surveytest';
        lc[0].Inbound_Call__c=true;
        lc[0].Status = EBH_ConstantsUtility.CMRC_EXECUTION;
        update lc;
        
        List<Account> la = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        
        
        update la;
        Contact con = new Contact(Firstname='Test',LastName='Contact' , Email='tsting@contract.de',AccountId=la[0].id);
        insert con;
        Campaign c= new Campaign();
        c.inbound_call__c=true;
        c.survey_id__c='surveytest';
        c.RecordTypeId=EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID;
        c.status=EBH_ConstantsUtility.CMRC_EXECUTION;
        c.name='Testing Inbound Campaign';
        insert c;
        
        CampaignMember cm = new CampaignMember(campaignid=c.id);
        cm.ContactId=con.id;
        cm.Campaign_Related_Seller_Details__c='This is a test for testing how long can be the related seller details This is a test for testing how ';
        cm.Campaign_Related_Seller_Details__c+= 'long can be the related seller details This is a test for testing how long can be the related seller details This is a test for testing';
        cm.Campaign_Related_Seller_Details__c+=    'how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for ';
        cm.Campaign_Related_Seller_Details__c+=   'testing how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for';
        cm.Campaign_Related_Seller_Details__c+= 'testing how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for';
        cm.Campaign_Related_Seller_Details__c+= 'testing how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for';
        cm.Campaign_Related_Seller_Details__c+= 'testing how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for';
        cm.Campaign_Related_Seller_Details__c+= 'testing how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for';
        cm.Campaign_Related_Seller_Details__c+= 'testing how long can be the related seller details ';
        insert cm;
        
        Task t = new Task();
        t.WhatId=la[0].id;
        t.WhoId = con.id;
        t.EBH_Account__c=la[0].id;
        t.EBH_CampaignMemberId__c=cm.id;
        t.Survey_ID__c='surveyid';
        
        insert t;
        Test.startTest();
        
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(t);
        OpenClickToolsSurveyController octsc = new OpenClickToolsSurveyController();
        
        
        
        insert new EBH_OutboundLink__c (Name='EBH_OutboundLink__c',Clicktools_Inbound_Survey__c='ThisIsAtest',
                                        EBH_URL__c='http://www.ebay.com',
                                        EBH_TicketURL__c ='http://www.ebay.de',
                                        NPS_Survey_URL__c ='http://www.ebay.co.uk',
                                        HUB_Search__c ='http://www.hub.de',
                                        EBH_ExternalCampaignRecordTypeId__c ='IdTest',
                                        //EBH_DriverTreeBaseURL__c ='http://www.ebay.com',
                                        
                                        Clicktools_Outbound_Survey__c ='213434334',
                                        
                                        Clicktools_Epilogue_Survey__c ='23434343'
                                        
                                        );
        
        
      //  octsc.redirect();
        Test.stopTest();
        
        
        
        
    }  
    
    
     @IsTest(SeeAllData=false) 
    public static void OpenClickToolsSurveyControllertestExceptions() {
          EBH_TestDataFactory.setUpCustomSettings();  
        
        //Create Campaign
        List<Campaign> lc = EBH_TestDataFactory.createCampaigns(1, 'testing_campaign', 'DE', EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH);
        lc[0].survey_id__c='surveytest';
        lc[0].Inbound_Call__c=true;
        lc[0].Status = EBH_ConstantsUtility.CMRC_EXECUTION;
        update lc;
        
        List<Account> la = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        
        
        update la;
        Contact con = new Contact(Firstname='Test',LastName='Contact' , Email='tsting@contract.de',AccountId=la[0].id);
        insert con;
        Campaign c= new Campaign();
        c.inbound_call__c=true;
        c.survey_id__c='surveytest';
        c.RecordTypeId=EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID;
        c.status=EBH_ConstantsUtility.CMRC_EXECUTION;
        c.name='Testing Inbound Campaign';
        insert c;
        
        CampaignMember cm = new CampaignMember(campaignid=c.id);
        cm.ContactId=con.id;
        cm.Campaign_Related_Seller_Details__c='This is a test for testing how long can be the related seller details This is a test for testing how ';
        cm.Campaign_Related_Seller_Details__c+= 'long can be the related seller details This is a test for testing how long can be the related seller details This is a test for testing';
        cm.Campaign_Related_Seller_Details__c+=    'how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for ';
        cm.Campaign_Related_Seller_Details__c+=   'testing how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for';
        cm.Campaign_Related_Seller_Details__c+= 'testing how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for';
        cm.Campaign_Related_Seller_Details__c+= 'testing how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for';
        cm.Campaign_Related_Seller_Details__c+= 'testing how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for';
        cm.Campaign_Related_Seller_Details__c+= 'testing how long can be the related seller details This is a test for testing how long can be the related seller details This is a test for';
        cm.Campaign_Related_Seller_Details__c+= 'testing how long can be the related seller details ';
        insert cm;
        
        Task t = new Task();
        t.WhatId=la[0].id;
        t.WhoId = con.id;
        t.EBH_Account__c=la[0].id;
        //t.EBH_CampaignMemberId__c=cm.id;
        t.Survey_ID__c='surveyid';
        
        insert t;
        Test.startTest();
        
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(t);
        OpenClickToolsSurveyController octsc = new OpenClickToolsSurveyController();
        
        
        
        insert new EBH_OutboundLink__c (Name='EBH_OutboundLink__c',Clicktools_Inbound_Survey__c='ThisIsAtest',
                                        EBH_URL__c='http://www.ebay.com',
                                        EBH_TicketURL__c ='http://www.ebay.de',
                                        NPS_Survey_URL__c ='http://www.ebay.co.uk',
                                        HUB_Search__c ='http://www.hub.de',
                                        EBH_ExternalCampaignRecordTypeId__c ='IdTest',
                                        //EBH_DriverTreeBaseURL__c ='http://www.ebay.com',
                                        Clicktools_Outbound_Survey__c ='213434334',
                                        
                                        Clicktools_Epilogue_Survey__c ='23434343'
                                        
                                        );
        
        
     //   octsc.redirect();
        Test.stopTest();
        
        
        
        
    }

    @IsTest
    public static void testLTTMPlusCampaign() {
      RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
      Account acc = new Account(
        Name='Test Account',
        RecordTypeId=sellerRecordType.Id,
        Managed_Type__c = 'LTTM Plus'
      );
      insert acc;

      RecordType boblttmRecordType = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
      BoB__c bob = new BoB__c(
        Status__c='BoB Active',
        EBH_BOBCNTRY__c='3',
        EBH_BOBVertical__c='Fashion',
        Managed_Type__c ='LTTM Plus',
        LTTM_Group__c='test group',
        RecordTypeId=boblttmRecordType.Id
      );
      insert bob;

      RecordType bobSellerlttmRecordType = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

      BoB_Seller__c bs = new BoB_Seller__c(
        RecordTypeId = bobSellerlttmRecordType.Id,
        Account_Manager__c=UserInfo.getUserId(),
        Parent_Seller__c=acc.Id,
        Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,
        Seller__c=acc.Id,
        BoB__c = bob.Id,
        EBH_BOBSegment__c='MSO',
        BoB_Subsegment__c='Platin'
      );

      insert bs;

      Campaign c = new Campaign();
      c.inbound_call__c=true;
      c.survey_id__c='surveytest';
      c.RecordTypeId=EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID;
      c.status=EBH_ConstantsUtility.CMRC_EXECUTION;
      c.name='Testing Inbound Campaign';
      insert c;

      Account controllerAcc =  [SELECT Id,RecordTypeId,RecordType.DeveloperName,Managed_Type__c From Account];

      ApexPages.StandardController sc = new ApexPages.StandardController(controllerAcc);
      RecordInboundCallController controller = new RecordInboundCallController(sc);
      controller.getStep();

      System.assertEquals(true, controller.isRecordInboundStep);
      System.assertEquals(false, controller.isInboundCampaignStep);

      System.assertNotEquals(null, controller.bobSellerId);

      list<SelectOption> options = controller.getStep();

      System.assertEquals(2, options.size());

      controller.currentStep = 'Inbound Campaign';
      controller.nextStep();

      System.assertEquals(false, controller.isRecordInboundStep);
      System.assertEquals(true, controller.isInboundCampaignStep);
      System.assertEquals(false, controller.isLttmPlusCampignStep);


      controller.currentStep = 'LTTM Plus Campaign';
      controller.nextStep();

      System.assertEquals(false, controller.isRecordInboundStep);
      System.assertEquals(false, controller.isInboundCampaignStep);
      System.assertEquals(true, controller.isLttmPlusCampignStep);

    }
    
    //MN-19012021 
    @IsTest
    public static void testLTTMPlusCampaignForOtherManagedType() {
      RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
      Account acc = new Account(
        Name='Test Account',
        RecordTypeId=sellerRecordType.Id,
        Managed_Type__c = 'Others Managed',
        EBH_BOBSegment__c = 'Concierge'
      );
      insert acc;

      RecordType boblttmRecordType = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
      BoB__c bob = new BoB__c(
        Status__c='BoB Active',
        EBH_BOBCNTRY__c='3',
        EBH_BOBVertical__c='Fashion',
        Managed_Type__c ='Others Managed',
        LTTM_Group__c='test group',
        RecordTypeId=boblttmRecordType.Id
      );
      insert bob;

      RecordType bobSellerlttmRecordType = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

      BoB_Seller__c bs = new BoB_Seller__c(
        RecordTypeId = bobSellerlttmRecordType.Id,
        Account_Manager__c=UserInfo.getUserId(),
        Parent_Seller__c=acc.Id,
        Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,
        Seller__c=acc.Id,
        BoB__c = bob.Id,
        EBH_BOBSegment__c='Concierge'
      );

      insert bs;

      Campaign c = new Campaign();
      c.inbound_call__c=true;
      c.survey_id__c='surveytest';
      c.RecordTypeId=EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID;
      c.status=EBH_ConstantsUtility.CMRC_EXECUTION;
      c.name='Testing Inbound Campaign';
      insert c;

      Account controllerAcc =  [SELECT Id,RecordTypeId,RecordType.DeveloperName,Managed_Type__c,EBH_BOBSegment__c From Account];

      ApexPages.StandardController sc = new ApexPages.StandardController(controllerAcc);
      RecordInboundCallController controller = new RecordInboundCallController(sc);
      controller.getStep();

      System.assertEquals(true, controller.isRecordInboundStep);
      System.assertEquals(false, controller.isInboundCampaignStep);

      System.assertNotEquals(null, controller.bobSellerId);

      list<SelectOption> options = controller.getStep();

      System.assertEquals(2, options.size());

      controller.currentStep = 'Inbound Campaign';
      controller.nextStep();

      System.assertEquals(false, controller.isRecordInboundStep);
      System.assertEquals(true, controller.isInboundCampaignStep);
      System.assertEquals(false, controller.isLttmPlusCampignStep);


      controller.currentStep = 'LTTM Plus Campaign';
      controller.nextStep();

      System.assertEquals(false, controller.isRecordInboundStep);
      System.assertEquals(false, controller.isInboundCampaignStep);
      System.assertEquals(true, controller.isLttmPlusCampignStep);

    }
}