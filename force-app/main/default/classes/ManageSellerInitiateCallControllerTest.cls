@isTest
private  class ManageSellerInitiateCallControllerTest {

    static Account acc;
    static Contact cont;
    static BoB__c bob;
    static BoB_Seller__c bs;
    static Action_Template__c template1;
    static Action__c action1;

    static void setUpData()
    {
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType rec_bobRecordTypeManage = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
        RecordType rec_bs_managed = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

        acc = new Account(Name='Seller1');
        insert acc;
        cont = new Contact(LastName='Last',AccountId=acc.Id);
        insert cont;

        bob = new BoB__c(RecordTypeId = rec_bobRecordTypeManage.Id ,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='UK',EBH_BOBVertical__c='Fashion');
        insert bob;
        bs = new BoB_Seller__c(RecordTypeId=rec_bs_managed.Id,Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=acc.Id,Status__c='New',Seller__c=acc.Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        insert bs;  
        
        template1 = new Action_Template__c(Name='Tempalte1',Active__c=true);
        insert template1;

        action1 = new Action__c(Name='Action1',Action_Template__c=template1.Id,LTTM_Seller__c=bs.Id);
        insert action1;
    }

    static void setUpDataForLttm()
    {
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        acc = new Account(
            Name='Test Account',
            RecordTypeId=sellerRecordType.Id,
            Managed_Type__c = 'LTTM Plus'
        );
        insert acc;

        cont = new Contact(LastName='Last',AccountId=acc.Id);
        insert cont;

        RecordType boblttmRecordType = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
        bob = new BoB__c(
            Status__c='Draft',
            EBH_BOBCNTRY__c='3',
            EBH_BOBVertical__c='Fashion',
            Managed_Type__c ='LTTM Plus',
            LTTM_Group__c='test group',
            RecordTypeId=boblttmRecordType.Id
          
        );
        insert bob;

        RecordType bobSellerlttmRecordType = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

        bs = new BoB_Seller__c(
            RecordTypeId = bobSellerlttmRecordType.Id,
            Parent_Seller__c=acc.Id,
            // Account_Manager__c=UserInfo.getUserId(),
            Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,
            Seller__c=acc.Id,
            BoB__c = bob.Id,
            EBH_BOBSegment__c='MSO',
            BoB_Subsegment__c='Platin',
            Call_Outcome__c='Next call scheduled',
            Call_Attempt__c = 0
        );

        insert bs;

        // Campaign c = new Campaign();
        // c.inbound_call__c=true;
        // c.survey_id__c='surveytest';
        // c.RecordTypeId=EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID;
        // c.status=EBH_ConstantsUtility.CMRC_EXECUTION;
        // c.name='Testing Inbound Campaign';
        // insert c;

        template1 = new Action_Template__c(Name='Tempalte1',Active__c=true);
        insert template1;

        action1 = new Action__c(Name='Action1',Action_Template__c=template1.Id,LTTM_Seller__c=bs.Id,Status__c='Not Started');
        insert action1;

    }

    @IsTest
    static void testApexInit(){
        
        setUpData();

        Test.startTest();            
            Map<String,Object> mapResult =  ManageSellerInitiateCallController.apexInit(bs.Id);
            system.debug(mapResult);
            System.assertEquals(1, ((List<Contact>)mapResult.get('listContact')).size(),'1 realted contact');
            System.assertEquals(1, ((List<Action__c>)mapResult.get('listActions')).size(),'1 realted action');

            delete action1;
            mapResult =  ManageSellerInitiateCallController.apexInit(bs.Id);
            System.assertEquals('ko',mapResult.get('status')+'','no action');

        Test.stopTest();
        
    }  

    @IsTest
    static void testApexSave(){
        setUpData();

        Test.startTest();
            action1.Status__c = 'Working on it';
            bs.Call_Outcome__c = 'Wrong Phone Number';
            Map<String,Object> mapResult =  ManageSellerInitiateCallController.apexSave(bs, new List<Action__c> {action1},false,false,new List<Contact>(),new Map<String,String>());

            BoB_Seller__c bsSel = [Select Id,Name,Call_Outcome__c,Call_Attempt__c From BoB_Seller__c Where Id=:bs.Id];

            System.assertEquals(bs.Call_Outcome__c, bsSel.Call_Outcome__c,'Call_Outcome__c updated');
            System.assertEquals(1, bsSel.Call_Attempt__c,'call attempt updated 1');

            Action__c actionSel = [Select Id,Status__c From Action__c Where Id=:action1.Id];
            System.assertEquals(action1.Status__c, actionSel.Status__c,'status updated');

        Test.stopTest();
        
    }

    @IsTest
    static void testApexSaveAndCreateTask(){
        setUpDataForLttm();
        EBH_TestDataFactory.setUpCustomSettings();

        action1.Status__c = 'Completed';
        bs.Call_Outcome__c = 'DMC Committed';
        
        Test.startTest(); 
        Map<String,Object> mapResult =   ManageSellerInitiateCallController.apexSave(bs, new List<Action__c> {action1},false,true,new List<Contact>{cont},new Map<String,String>());
        Test.stopTest(); 

        System.assertEquals('ok', mapResult.get('status'));

        Action__c updatedAction1 = [Select Id, Status__c FROM Action__c Where Id =: action1.Id];
        System.assertEquals('Completed', updatedAction1.Status__c);

        BoB_Seller__c updatedBobSeller = [Select Id, Call_Outcome__c FROM BoB_Seller__c Where Id =: bs.Id];
        System.assertEquals('DMC Committed', updatedBobSeller.Call_Outcome__c);

        Task tsk = [SELECT Id,WhoId FROM Task Where WhatId =:bs.id];
        System.assertEquals(cont.Id, tsk.WhoId);

    }
 
}