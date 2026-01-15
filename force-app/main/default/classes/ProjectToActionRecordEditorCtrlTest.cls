/*********************************************************************************************************************************
@ Class:          ProjectToActionRecordEditorCtrlTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0007535 Test Class for ProjectToActionRecordEditorController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/

@isTest
private  class ProjectToActionRecordEditorCtrlTest {
    private static Id PARENT_ID;

    private static List<Action__c> ACTIONS_TO_UPDATE = new List<Action__c>();

    private static void initData(){

        EBH_TestDataFactory.setUpCustomSettings(); 

        Lead lead = new Lead(LastName='test lead',Company='Gaea-sys');

        insert lead;

        Id eUOnboardingRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Project__c','EUOnboarding').Id;
        
        EBH_Project__c projectEUOnboarding = new EBH_Project__c(
            Name = 'Project EUOnboarding', 
            RecordTypeId = eUOnboardingRecordTypeId
        );

        insert projectEUOnboarding;

        Id acquisitionRecordTypeId = ApexUtil.getRecordTypeByName('Action_Template__c','Acquisition').Id;
        Action_Template__c actionTemplate = new Action_Template__c(
            Name = 'Action Template One',
            Country__c = 'DE',
            RecordTypeId = acquisitionRecordTypeId,
            Lead_Segment__c = 'SMB'
        );
        insert actionTemplate;

        Action__c actionOne = new Action__c(
            Name = 'Action One',
            Project__c = projectEUOnboarding.Id,
            Status__c = 'Not Started',
            Action_Template__c = actionTemplate.Id
        );
        Action__c actionTwo = new Action__c(
            Name = 'Action Two',
            Project__c = projectEUOnboarding.Id,
            Status__c = 'Not Started',
            Action_Template__c = actionTemplate.Id
        ); 

        Action__c actionThree = new Action__c(
            Name = 'Action Three',
            Project__c = projectEUOnboarding.Id,
            Status__c = 'Not Started',
            Action_Template__c = actionTemplate.Id
        ); 

        ACTIONS_TO_UPDATE = new List<Action__c>{actionOne,actionTwo,actionThree};

        insert ACTIONS_TO_UPDATE;

        PARENT_ID = projectEUOnboarding.Id;
        
        EBH_Project__c pro = new EBH_Project__c(Name='Project 1', Call_Attempt__c = 1, 
                                                Next_Call_Schedule_Date__c = Date.today(), 
                                                Next_Call_Time__c = '00:00 till 23:15 (15 minutes interval)',
                                                Comments__c = 'test'
                                               );
        insert pro;
    }


    @IsTest
    static void testApexInit(){
        
        initData();

        Test.startTest();     
            Map<String,Object> mapResult =  ProjectToActionRecordEditorController.apexInit(PARENT_ID);
            // system.debug(mapResult);
            System.assertEquals(3, ((List<Action__c>)mapResult.get('listActions')).size());

            delete ACTIONS_TO_UPDATE;
            mapResult =  ProjectToActionRecordEditorController.apexInit(PARENT_ID);
            System.assertEquals('ko',mapResult.get('status')+'');

        Test.stopTest();
        
    }
    @IsTest
    static void testApexSave(){
        initData();

        Test.startTest();
            String completedStatus = 'Completed';
            ACTIONS_TO_UPDATE[0].Status__c = completedStatus;
            ACTIONS_TO_UPDATE[1].Status__c = completedStatus;
        
			EBH_Project__c pro = [SELECT Name, Call_Attempt__c, Next_Call_Schedule_Date__c, Next_Call_Time__c, Comments__c FROM EBH_Project__c WHERE Name = 'Project 1'];
            Map<String,Object> mapResult =  ProjectToActionRecordEditorController.apexSave(ACTIONS_TO_UPDATE, pro);

            List<Action__c> actionList = [Select Id,Status__c From Action__c Where Project__c=:PARENT_ID];

            System.assertEquals(completedStatus, actionList[0].Status__c);
            System.assertEquals(completedStatus, actionList[1].Status__c);

            System.assertNotEquals(completedStatus, actionList[2].Status__c);

        Test.stopTest();
        
    }   


}