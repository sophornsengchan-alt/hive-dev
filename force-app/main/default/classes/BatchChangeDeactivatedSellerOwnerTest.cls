/*********************************************************************************************************************************
@ Class:          BatchChangeDeactivatedSellerOwnerTest
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        US-0015242 - Fix Account Owner Updating to Integration User Issue
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  13.05.2024 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
private class BatchChangeDeactivatedSellerOwnerTest {

    private static List<Account> sellers;
    private static BoB__c lttmBob;
    private static List<String> listLttmBsId;

    private static void setupData(){

        User currentUser = [Select Id From User Where Id = : UserInfo.getUserId() And IsActive = true Limit 1];

        sellers = EBH_TestDataFactory.createAccounts(3, 'EBH_Seller');

        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
    	RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

        lttmBob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id, Managed_Type__c = 'Others Managed');
        insert lttmBob;

        BOB_Seller__c lttmBobSeller1 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[0].Id, Account_Manager__c = currentUser.Id);
        BOB_Seller__c lttmBobSeller2 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[1].Id, Account_Manager__c = currentUser.Id);
        BOB_Seller__c lttmBobSeller3 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[2].Id, Account_Manager__c = currentUser.Id);
        List<BOB_Seller__c> listLttmBobSeller = new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2, lttmBobSeller3};
        insert listLttmBobSeller;
        listLttmBsId = new List<String>{lttmBobSeller1.Id, lttmBobSeller2.Id, lttmBobSeller3.Id};

        RecordType actionTemplateLTTM = ApexUtil.getRecordTypeByName('Action_Template__c','LTTM');
        Action_Template__c parentTemplate = new Action_Template__c(Name='parentTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Active__c=true);
        insert parentTemplate;

        Action_Template__c childTemplate = new Action_Template__c(Name='childTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Parent_Action__c=parentTemplate.Id,Active__c=true);
        insert childTemplate;

        Action__c action1 = new Action__c(Name='Action1',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller1.Id);
        Action__c action2 = new Action__c(Name='Action2',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller2.Id);
        Action__c action3 = new Action__c(Name='Action3',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller3.Id);
        insert new List<Action__c>{action1, action2, action3};
        
    }

    @isTest
    static void testChangeDeactivatedSellerOwner() {

        // 13.05.2024 / Sophal Noch / US-0015242 :

        setupData();

        Test.startTest();

            Map<String, Object> mapResult = CohortActionController.activateCohort(lttmBob.Id);
            System.assertEquals(null,  mapResult.get('error'));

            mapResult = CohortActionController.activateCohortSeller(null, listLttmBsId, false);
            System.assertEquals(null,  mapResult.get('error'));

            CohortActionController.runActivateCohortSellerBatch(lttmBob.Id, null);
            
            mapResult = CohortActionController.deactivateCohort(null, listLttmBsId);
            System.assertEquals(null,  mapResult.get('error'));

            CohortActionController.runDeactivateCohortSellerBatch(lttmBob.Id, null);

            List<Account> listAccToUpdate = [Select Id, OwnerId From Account Where Id IN: sellers];
            String deactivateUserId = String.valueOf(Label.Cohort_Deactivation_UserId);
            for(Account acc : listAccToUpdate){
                acc.OwnerId = deactivateUserId;
            }
            update listAccToUpdate;

       
            BatchChangeDeactivatedSellerOwner sch = new BatchChangeDeactivatedSellerOwner();
            sch.execute(null);
            Database.executeBatch(new BatchChangeDeactivatedSellerOwner(new Set<String>{lttmBob.Id}));

        Test.stopTest();

        List<Account> listAccToCheck = [Select Id, OwnerId From Account Where Id IN: sellers];
        for(Account acc : listAccToCheck){
            System.assertEquals(ApexUtil.INTEGRATION_USER_ID, acc.OwnerId);
        }

    }
}