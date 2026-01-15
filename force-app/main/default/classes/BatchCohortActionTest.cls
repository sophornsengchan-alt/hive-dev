/*********************************************************************************************************************************
@ Class:          BatchCohortActionTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0014361 - Cohort Activation Process Part 2
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  09.11.2023 / Sophal Noch / Created the class.
@               :  15.11.2023 / Sophal Noch / US-0014353 - Cohort Deactivation Process
@               :  11.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
@               :  11.12.2023 / Sophal Noch / US-0014363 - Ph 1 - Deactivate Sellers button
@               :  30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
@               :  24.02.2024 / Sophal Noch / US-0016833 - Account History | Owner changes several times a day
@               :  03.07.2025 / Sophal Noch / US-0033064 - Limiting paid programs visibility to only existing subscribers
*********************************************************************************************************************************/
@isTest
private class BatchCohortActionTest {

    private static BoB__c managedBob;
    private static BOB_Seller__c managedBobSeller1;

    private static BoB__c lttmBob;
    private static BOB_Seller__c lttmBobSeller1;
    private static BOB_Seller__c lttmBobSeller2;
    private static BOB_Seller__c lttmBobSeller3;

    private static List<BOB_Seller__c> listLttmBobSeller;

    private static User currentUser;
    private static User anotherUser;

    private static List<Account> sellers;

    private static void setupData(){

        currentUser = [Select Id From User Where Id = : UserInfo.getUserId() And IsActive = true Limit 1];
        anotherUser = [Select Id From User Where Id !=: currentUser.Id And Profile.Name = 'System Administrator' And IsActive = true Limit 1];

        System.runAs(currentUser){ 
            // remove calendly
            currentUser.Calendly__CalendlyLink__c = null;
            update currentUser;
        }   

        System.runAs(anotherUser){ 
            // config calendly
            anotherUser.Calendly__CalendlyLink__c = 'ebay.com';
            update anotherUser;
        }   

        Account parentSeller = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller')[0];

        sellers = EBH_TestDataFactory.createAccounts(3, 'EBH_Seller');

        /*RecordType bobRecordTypeMgn = ApexUtil.getRecordTypeByName('BOB__c','Managed_Cohort');
        RecordType bobSellerRecordTypeMgn = ApexUtil.getRecordTypeByName('BoB_Seller__c','Managed');

        managedBob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Collectibles',RecordTypeId = bobRecordTypeMgn.Id, Account_Manager__c = currentUser.Id);
        insert managedBob;
        managedBobSeller1 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeMgn.Id ,BOB__c=managedBob.Id,Parent_Seller__c = parentSeller.Id, Seller__c=sellers[0].Id, Account_Manager__c = currentUser.Id);
        insert managedBobSeller1;

        managedBob.Status__c = 'BoB Inactive';
        update managedBob;*/

        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
    	RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

        Date today = Date.today(); // 24.02.2024 / Sophal Noch / US-0016833
        lttmBob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id, Managed_Type__c = 'Others Managed', Registration_Start_Date__c = today.addDays(1), RegistrationCloseDate__c =  today.addDays(6));
        insert lttmBob;

        Category_Tree__c ct0 = new Category_Tree__c(Name = 'l0',Active__c=true,Site__c='77');
     	insert ct0;
    	Category_Tree__c ct1 = new Category_Tree__c(Name = 'l1',Note_ID__c=ct0.Id,Active__c=true);
    	insert ct1;
		Category_Tree__c ct2 = new Category_Tree__c(Name = 'l2a',Note_ID__c = ct1.Id,Active__c=true);
		insert ct2;
		Category_Tree__c ct3 = new Category_Tree__c(Name = 'l3',Note_ID__c = ct2.Id,Active__c=true);
    	insert ct3;

        Map<String,Object> resultSave = CategoryTreeController.apexSaveCat(lttmBob.Id,new List<String>{ct3.Id});
        System.assertEquals('ok',resultSave.get('status'),'save success');


        lttmBobSeller1 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[0].Id, Account_Manager__c = anotherUser.Id);
        lttmBobSeller2 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[1].Id, Account_Manager__c = currentUser.Id);
        lttmBobSeller3 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[2].Id, Account_Manager__c = anotherUser.Id);
        listLttmBobSeller = new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2, lttmBobSeller3};
        insert listLttmBobSeller;

        RecordType actionTemplateLTTM = ApexUtil.getRecordTypeByName('Action_Template__c','LTTM');
        Action_Template__c parentTemplate = new Action_Template__c(Name='parentTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Active__c=true);
        insert parentTemplate;

        Action_Template__c childTemplate = new Action_Template__c(Name='childTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Parent_Action__c=parentTemplate.Id,Active__c=true);
        insert childTemplate;

        Action__c action1 = new Action__c(Name='Action1',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller1.Id);
        Action__c action2 = new Action__c(Name='Action2',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller2.Id);
        Action__c action3 = new Action__c(Name='Action3',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller2.Id);
        insert new List<Action__c>{action1, action2, action3};

    }


    /*********************************************************************************************************************************
    @ Class:          test_BatchCohortAction
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014361 - Cohort Activation Process Part 2
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.11.2023 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    @isTest
    static void test_ActiveCohort(){
        setupData();

        lttmBob.Status__c = 'BoB Active';
        update lttmBob;

        lttmBobSeller1.Status__c = 'Draft';
        lttmBobSeller2.Status__c = 'Draft';
        lttmBobSeller3.Status__c = 'Draft';
        listLttmBobSeller = new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2, lttmBobSeller3};
        BatchCohortAction.isRunning = true;
        update listLttmBobSeller;

        Test.startTest();
            Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_ACTIVATE_COHORT_SELLER, 0, new Set<String>{lttmBob.Id}));
            Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_ACTIVATE_SELECTED_COHORT_SELLER, 0, new Set<String>{lttmBobSeller1.Id, lttmBobSeller2.Id, lttmBobSeller3.Id})); 
            Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_SYNC_COHORT_SELLER, null, new Set<String>{lttmBobSeller1.Id, lttmBobSeller2.Id, lttmBobSeller3.Id})); 
        Test.stopTest();

        List<Account> listAcc = [Select Id, EBH_BOBManaged__c From Account Where Id IN :new Set<String>{lttmBobSeller1.Seller__c, lttmBobSeller2.Seller__c, lttmBobSeller3.Seller__c}];

        System.assertEquals(true, listAcc[0].EBH_BOBManaged__c);
        System.assertEquals(true, listAcc[1].EBH_BOBManaged__c);
        System.assertEquals(true, listAcc[2].EBH_BOBManaged__c);
        
        new BatchCohortAction(BatchCohortAction.ACTION_ACTIVATE_COHORT_SELLER, 0, new Set<String>{lttmBob.Id}).executeSync(); // test sync mode
    }

    @isTest
    static void test_InviteProTraderCohort(){

        setupData();

        lttmBob.Managed_Type__c = 'LTTM Managed';
        lttmBob.Managed_Segment__c = 'Pro-Trader Cat'; // 14.05.2024 / Sophal Noch / US-0015200
        lttmBob.Status__c = 'BoB Active';

        update new List<BoB__c>{lttmBob};

        lttmBob.Status__c = 'BoB Active';
        update lttmBob;

        lttmBobSeller1.Status__c = 'Invited';
        lttmBobSeller2.Status__c = 'Invited';
        lttmBobSeller3.Status__c = 'Invited';
        listLttmBobSeller = new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2, lttmBobSeller3};
        BatchCohortAction.isRunning = true;
        update listLttmBobSeller;

        Test.startTest();
            Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_ACTIVATE_COHORT_SELLER, 0, new Set<String>{lttmBob.Id}));
            Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_ACTIVATE_SELECTED_COHORT_SELLER, 0, new Set<String>{lttmBobSeller1.Id, lttmBobSeller2.Id, lttmBobSeller3.Id})); 
        Test.stopTest();

        List<Account> listAcc = [Select Id, SP_Account_Management__c From Account Where Id IN :new Set<String>{lttmBobSeller1.Seller__c, lttmBobSeller2.Seller__c, lttmBobSeller3.Seller__c}];

        System.assertNotEquals(null, listAcc[0].SP_Account_Management__c);
        System.assertNotEquals(null, listAcc[1].SP_Account_Management__c);
        System.assertNotEquals(null, listAcc[2].SP_Account_Management__c);
        
       
    }

  
    @isTest
    static void test_DeactiveCohort(){

        // 15.11.2023 / Sophal Noch / US-0014353 - Cohort Deactivation Process

        setupData();

        lttmBob.Status__c = 'BoB Active';
        update lttmBob;

        lttmBobSeller1.Status__c = 'Inactive';
        lttmBobSeller2.Status__c = 'Inactive';
        lttmBobSeller3.Status__c = 'Inactive';
        listLttmBobSeller = new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2, lttmBobSeller3};
        BatchCohortAction.isRunning = true;
        update listLttmBobSeller;

        Test.startTest();
                Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_DEACTIVATE_COHORT_SELLER, 0, new Set<String>{lttmBob.Id})); 
                Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_DEACTIVATE_SELECTED_COHORT_SELLER, 0, new Set<String>{lttmBobSeller1.Id, lttmBobSeller2.Id, lttmBobSeller3.Id})); 
                Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_UNSYNC_COHORT_SELLER, null, new Set<String>{lttmBobSeller1.Id, lttmBobSeller2.Id, lttmBobSeller3.Id})); 
        Test.stopTest();

        System.assertEquals('BoB Inactive', [Select Id, Status__c From BoB__c Where Id = :lttmBob.Id].Status__c);

    }

    @isTest
    static void testDeleteCohortSeller(){
        // 30.01.2024 / Sophal Noch / US-0014277 :
        setupData();

        lttmBob.Status__c = 'BoB Inactive';
        update lttmBob;

        lttmBobSeller1.Status__c = 'Inactive';
        lttmBobSeller2.Status__c = 'Inactive';
        lttmBobSeller3.Status__c = 'Inactive';
        listLttmBobSeller = new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2, lttmBobSeller3};
        BatchCohortAction.isRunning = true;
        update listLttmBobSeller;

        sellers[0].EBH_BOBManaged__c = true;
        sellers[1].EBH_BOBManaged__c = true;
        sellers[2].EBH_BOBManaged__c = true;

        update sellers;

        Test.startTest();
                Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_USYNC_ACC, null, new Set<String>{sellers[0].Id, sellers[1].Id, sellers[2].Id})); 
        Test.stopTest();

        sellers = [Select Id, EBH_BOBManaged__c from Account where Id IN : sellers];
        System.assertEquals(false, sellers[0].EBH_BOBManaged__c);
        System.assertEquals(false, sellers[1].EBH_BOBManaged__c);
        System.assertEquals(false, sellers[2].EBH_BOBManaged__c);

    }

    /*****************************************************************************************************************************
    @ Method:   testActiveGSDAccMgnCohort
    @ Version:  1.0
    @ Author:   Sophal Noch
    @ Purpose:  03.07.2025 / Sophal Noch / US-0033064 - Limiting paid programs visibility to only existing subscribers
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.07.2025 / Sophal Noch / US-0033064 / Created the Method.
    *****************************************************************************************************************************/
    @isTest
    static void testActiveGSDAccMgnCohort(){
        // 03.07.2025 / Sophal Noch / US-0033064 : test method to when GSD Account Management cohort is activated and seller.SP_Account_Management__c is updated to Full Access
        setupData();

        sellers[0].SP_Main_Domain__c = SEP_Helper.SEP_Domain_DE;
        ApexSafe.dml().secCheck(false).doUpdate(new List<Account>{sellers[0]}, true);

        lttmBob.Managed_Type__c = 'Managed BoB';
        lttmBob.Status__c = 'BoB Active';
        ApexSafe.dml().secCheck(false).doUpdate(new List<BoB__c>{lttmBob}, true);

        lttmBobSeller1.EBH_BOBSegment__c = 'Enterprise';
        lttmBobSeller1.Status__c = 'Draft';
        BatchCohortAction.isRunning = true; // make sure it is Not running from trigger when cohort seller is activated
        ApexSafe.dml().secCheck(false).doUpdate(new List<BOB_Seller__c>{lttmBobSeller1}, true);

        Test.startTest();
            Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_ACTIVATE_SELECTED_COHORT_SELLER, 0, new Set<String>{lttmBobSeller1.Id})); 
        Test.stopTest();

        List<Account> listAcc = (List<Account>) ApexSafe.query().secCheck(false).doQuery('Select Id, SP_Account_Management__c From Account Where Id IN :setSellerId Limit 1',new Map<String, Object> {'setSellerId' => new Set<Id>{lttmBobSeller1.Seller__c}});
        System.assertEquals('Full Access', listAcc[0].SP_Account_Management__c, 'SP Account Management must be Full Access');
    }


}