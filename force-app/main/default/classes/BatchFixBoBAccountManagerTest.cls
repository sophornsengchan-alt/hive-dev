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
private class BatchFixBoBAccountManagerTest {

    /*****************************************************************************************************************************
	@ Method:   testFixFromBS
    @ Version:  2.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:  if Bob__r.RecordType.DeveloperName == 'Managed_Cohort'
    @			then Account.EBH_BOBManaged__c == true
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      none
	------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / update the method.
    @               : 09.11.2023 / Sophal Noch / US-0014361 - Cohort Activation Process Part 2
    *****************************************************************************************************************************/
    /*static testMethod void testFixFromBS() {
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        User[] admins = [Select Id,Name From User Where ProfileId =:EBH_ConstantsUtility.ADMIN_PROFILE_ID AND isActive = true limit 3];
        
        Test.startTest();
            RecordType bobRecordTypeMgn = ApexUtil.getRecordTypeByName('BOB__c','Managed_Cohort'); // 09.11.2023 / Sophal Noch / US-0014361
            BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',Managed_Type__c ='Others Managed', RecordTypeId = bobRecordTypeMgn.Id);
            insert bob;
            RecordType bobSellerRecordTypeManaged = ApexUtil.getRecordTypeByName('BoB_Seller__c','Managed');
            BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeManaged.Id,Account_Manager__c=admins[1].Id,Parent_Seller__c=sellers[0].Id,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_NEW,Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            BoB_Seller__c bs2 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeManaged.Id,Account_Manager__c=admins[2].Id,Parent_Seller__c=sellers[0].Id,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED,Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            insert new List<BoB_Seller__c>{bs,bs2};  
            bob.Status__c=EBH_ConstantsUtility.BOB_STATUS_ACTIVE;
            update bob;
            
            BatchFixBoBAccountManager b = new BatchFixBoBAccountManager();
            b.execute(null);
            
        Test.stopTest();

        Account updatedAccount = [Select Managed_Type__c,Id,EBH_BOBManaged__c From Account where Id =: sellers[0].Id];
        System.assertEquals(true, updatedAccount.EBH_BOBManaged__c);
        System.assertEquals('Others Managed', updatedAccount.Managed_Type__c);
        
        
    }*/

    /*****************************************************************************************************************************
	@ Method:   testFixFromBSWithBobRecordTypeLTTM
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:  if Bob__r.RecordType.DeveloperName == 'Light_Touch_Category_Cohort'
    @			then Account.EBH_BOBManaged__c == true
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      none
	------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / create the method.
                    : 09.11.2023 / Sophal Noch / US-0014361 - Cohort Activation Process Part 2
    *****************************************************************************************************************************/
    static testMethod void testFixFromBSWithBobRecordTypeLTTM() {

        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        User[] admins = [Select Id,Name From User Where ProfileId =:EBH_ConstantsUtility.ADMIN_PROFILE_ID AND isActive = true limit 3];
        
        Test.startTest();

            Id boblightTouchCategoryCohortRecordTypeId =  ApexUtil.getRecordTypeByName('BOB__c',BatchFixBoBAccountManager.BOB_LIGHT_TOUCH_CATEGORY_COHORT_RECORDTYPE).Id;

            BoB__c bob = new BoB__c(
                Status__c=BatchFixBoBAccountManager.BOB_ACTIVE_STATUS,
                EBH_BOBCNTRY__c='3',
                EBH_BOBVertical__c='Fashion',
                RecordTypeId=boblightTouchCategoryCohortRecordTypeId,
                Managed_Type__c ='LTTM Managed'
            );
            insert bob;

            // 09.11.2023 / Sophal Noch / US-0014361 :
            Category_Tree__c ct0 = new Category_Tree__c(Name = 'l0',Active__c=true,Site__c='3');
            insert ct0;
            Category_Tree__c ct1 = new Category_Tree__c(Name = 'l1',Note_ID__c=ct0.Id,Active__c=true);
            insert ct1;
            Category_Tree__c ct2 = new Category_Tree__c(Name = 'l2a',Note_ID__c = ct1.Id,Active__c=true);
            insert ct2;
            Category_Tree__c ct3 = new Category_Tree__c(Name = 'l3',Note_ID__c = ct2.Id,Active__c=true);
            insert ct3;
           Map<String,Object> resultSave = CategoryTreeController.apexSaveCat(bob.Id,new List<String>{ct3.Id});
           System.assertEquals('ok',resultSave.get('status'),'save success');


            // RecordType bobSellerRecordTypeManaged = ApexUtil.getRecordTypeByName('BoB_Seller__c','Managed');
            RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM'); // 09.11.2023 / Sophal Noch / US-0014361
            
            // 09.11.2023 / Sophal Noch / US-0014361 :
            // BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeManaged.Id,Account_Manager__c=admins[1].Id,Parent_Seller__c=sellers[0].Id,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_NEW,Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            // BoB_Seller__c bs2 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id,Account_Manager__c=admins[2].Id,Parent_Seller__c=sellers[0].Id,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED,Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id,Account_Manager__c=admins[1].Id,Parent_Seller__c=sellers[0].Id,Status__c='Draft',Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            BoB_Seller__c bs2 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id,Account_Manager__c=admins[2].Id,Parent_Seller__c=sellers[0].Id,Status__c='Inactive',Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');

            insert new List<BoB_Seller__c>{bs,bs2}; 
            
            RecordType actionTemplateLTTM = ApexUtil.getRecordTypeByName('Action_Template__c','LTTM');
            Action_Template__c parentTemplate = new Action_Template__c(Name='parentTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Active__c=true);
            insert parentTemplate;
            Action_Template__c childTemplate = new Action_Template__c(Name='childTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Parent_Action__c=parentTemplate.Id,Active__c=true);
            insert childTemplate;
            Action__c action1 = new Action__c(Name='Action1',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=bs.Id);
            Action__c action2 = new Action__c(Name='Action2',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=bs2.Id);
            insert new List<Action__c>{action1,action2};

            bob.Status__c=EBH_ConstantsUtility.BOB_STATUS_ACTIVE;
            update bob;
            
            BatchFixBoBAccountManager b = new BatchFixBoBAccountManager('bs',new Set<String>{bob.Id});
            b.execute(null);
            
        Test.stopTest();

        Account updatedAccount = [Select Managed_Type__c,Id,EBH_BOBManaged__c From Account where Id =: sellers[0].Id];
        System.assertEquals(true, updatedAccount.EBH_BOBManaged__c);
        System.assertEquals('LTTM Managed', updatedAccount.Managed_Type__c);

    }

    /*****************************************************************************************************************************
	@ Method:   testFixFromSeller
    @ Version:  2.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  remove make important fields blank if account is not bob seller
    @           and check BatchFixBoBAccountManager instance parameter if it work or not
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      none
	------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / update the method.
    *****************************************************************************************************************************/
    static testMethod void testFixFromSeller() {
        
        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        
        Test.startTest();
             
            sellers[0].EBH_BOBManaged__c = true;
            sellers[0].EBH_AccountManageName__c = 'tester';
            sellers[0].Managed_Type__c = 'Others Managed';
            update sellers[0];
            
            // BatchFixBoBAccountManager b = new BatchFixBoBAccountManager('acc');
            // check if adding id cause sql error or not
            BatchFixBoBAccountManager b = new BatchFixBoBAccountManager('acc',new Set<String>{sellers[0].Id});
            Database.executeBatch(b); 
            
        Test.stopTest();
        
       Account sellerSel = [Select Managed_Type__c,Id,Name,EBH_BOBManaged__c,EBH_AccountManageName__c From Account where Id=:sellers[0].Id];
       System.assertEquals(false,sellerSel.EBH_BOBManaged__c,'clear from batch');
       System.assertEquals(null,sellerSel.EBH_AccountManageName__c,'clear from batch');
       System.assertEquals(null,sellerSel.Managed_Type__c,'clear from batch');
    }

    static testMethod void testInactiveBob() {

        // 11.01.2022 / Sophal Noch / US-0011008

        User[] admins = [Select Id,Name From User Where ProfileId =:EBH_ConstantsUtility.ADMIN_PROFILE_ID AND isActive = true limit 3];

        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');

        Id boblightTouchCategoryCohortRecordTypeId =  ApexUtil.getRecordTypeByName('BOB__c',BatchFixBoBAccountManager.BOB_LIGHT_TOUCH_CATEGORY_COHORT_RECORDTYPE).Id;
        BoB__c bob = new BoB__c(
            Status__c=BatchFixBoBAccountManager.BOB_ACTIVE_STATUS,
            EBH_BOBCNTRY__c='3',
            EBH_BOBVertical__c='Fashion',
            RecordTypeId=boblightTouchCategoryCohortRecordTypeId,
            Managed_Type__c ='LTTM Managed'
        );
        insert bob;

        RecordType bobSellerLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerLTTM.Id,Account_Manager__c=admins[1].Id,Parent_Seller__c=sellers[0].Id,Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        BoB_Seller__c bs2 = new BoB_Seller__c(RecordTypeId = bobSellerLTTM.Id,Account_Manager__c=admins[2].Id,Parent_Seller__c=sellers[0].Id,Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        insert new List<BoB_Seller__c>{bs,bs2};

        bob.Status__c = 'BoB Inactive';
        update bob;

        sellers[0].OwnerId = UserInfo.getUserId();
        sellers[1].OwnerId = UserInfo.getUserId();
        update sellers;

        Test.startTest();
            BatchFixBoBAccountManager b = new BatchFixBoBAccountManager('bs');
            Database.executeBatch(b); 
        Test.stopTest();

        sellers = [Select Id, OwnerId From Account Where Id in: sellers];
        System.assertEquals(ApexUtil.INTEGRATION_USER_ID, sellers[0].OwnerId);
        System.assertEquals(ApexUtil.INTEGRATION_USER_ID, sellers[1].OwnerId);

    }

   /*********************************************************************************************************************************
    @ Method:         testGetCountryMap
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0016680 - [Dev Only] Apex Class Classification to upgrade API version 1/5
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  28.02.2025 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    @isTest 
    static void testGetCountryMap() {
        Map<String,String> mapCodeToContry = BatchFixBoBAccountManager.MAP_CODE_TO_COUNTRY;
        Test.startTest();
            System.assertEquals(false, mapCodeToContry.isEmpty(), 'expect map is not empty');
        Test.stopTest();
       
    }
}