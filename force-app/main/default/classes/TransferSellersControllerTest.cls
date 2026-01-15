/*********************************************************************************************************************************
@ Class:          TransferSellersControllerTest
@ Version:        1.0
@ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
@ Purpose:        test Class for TransferSellersController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.06.2021 / Loumang SENG / Created the class
@               : 05.06.2024 / Sophal Noch / US-0015352 - Transfer Cohort Seller Issue - Conflict and Order of execution
@               : 08.12.2025 / Sophal Noch / US-0033965 - 7. Approve - Transfer
*********************************************************************************************************************************/
@isTest
private  class TransferSellersControllerTest {
    static Account acc;
    static Account acc2;
    static Account acc4;
    static Contact cont;
    static Contact cont2;
    static BoB__c bob;
    static BoB__c bob2;
    static BoB__c bob3;
    static BoB__c bob4;
    static BoB_Seller__c bs;
    static BoB_Seller__c bs2;
    static BoB_Seller__c bs4;
    static Action_Template__c template1;
    static Action__c action1;
    static Action_Template__c template2;
    static Action__c action2;

    static void setUpData()
    {
         	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
            acc = new Account(
                Name='Test Account',
                RecordTypeId=sellerRecordType.Id,
                Managed_Type__c = 'LTTM Managed'
            );
            acc2 = new Account(
                Name='Test Account2',
                RecordTypeId=sellerRecordType.Id,
                Managed_Type__c = 'LTTM Plus'
            );
            acc4 = new Account(
                Name='Test Account4',
                RecordTypeId=sellerRecordType.Id,
                Managed_Type__c = 'LTTM Plus'
            );
            insert new List<Account>{acc,acc2,acc4};
    
            cont = new Contact(LastName='Last',AccountId=acc.Id);
            cont2 = new Contact(LastName='Last2',AccountId=acc2.Id);
            insert new List<Contact>{cont,cont2};
    
            RecordType boblttmRecordType = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
            RecordType bobAdsRecordType = ApexUtil.getRecordTypeByName('BOB__c', 'Advertising_Cohort');
            bob = new BoB__c(
                Status__c='BoB Active',
                EBH_BOBCNTRY__c='3',
                EBH_BOBVertical__c='Fashion',
                Managed_Type__c ='LTTM Managed',
                LTTM_Group__c='test group',
                RecordTypeId=boblttmRecordType.Id,
                ownerId = UserInfo.getUserId()
            );
            bob2 = new BoB__c(
                Status__c='BoB Active',
                EBH_BOBCNTRY__c='3',
                EBH_BOBVertical__c='Fashion',
                Managed_Type__c ='LTTM Managed',
                LTTM_Group__c='test group2',
                RecordTypeId=boblttmRecordType.Id,
                ownerId = UserInfo.getUserId()
            );
            bob3 = new BoB__c(
                Status__c='BoB Active',
                EBH_BOBCNTRY__c='3',
                EBH_BOBVertical__c='Fashion',
                Managed_Type__c ='LTTM Plus',
                LTTM_Group__c='test group3',
                RecordTypeId=boblttmRecordType.Id,
                ownerId = UserInfo.getUserId()
            );
            bob4 = new BoB__c(
                Status__c='BoB Active',
                EBH_BOBCNTRY__c='3',
                EBH_BOBVertical__c='Fashion',
                Managed_Type__c ='Advertising',
                LTTM_Group__c='test group4',
                RecordTypeId=bobAdsRecordType.Id,
                ownerId = UserInfo.getUserId()
            );
            insert new List<BoB__c>{bob,bob2,bob3,bob4};
    
            RecordType bobSellerlttmRecordType = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
            RecordType bobSellerAdsRecordType = ApexUtil.getRecordTypeByName('BoB_Seller__c','Advertising');
    
            bs = new BoB_Seller__c(
                RecordTypeId = bobSellerlttmRecordType.Id,
                Parent_Seller__c=acc.Id,
                Account_Manager__c=UserInfo.getUserId(),
                Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,
                Seller__c=acc.Id,
                BoB__c = bob.Id,
                EBH_BOBSegment__c='MSO',
                BoB_Subsegment__c='Platin',
                Call_Outcome__c='Next call scheduled',
                Call_Attempt__c = 0
            );
            bs2 = new BoB_Seller__c(
                RecordTypeId = bobSellerlttmRecordType.Id,
                Parent_Seller__c=acc2.Id,
                Account_Manager__c=UserInfo.getUserId(),
                Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,
                Seller__c=acc2.Id,
                BoB__c = bob3.Id,
                EBH_BOBSegment__c='MSO',
                BoB_Subsegment__c='Platin',
                Call_Outcome__c='Next call scheduled',
                Call_Attempt__c = 0
            );
            bs4 = new BoB_Seller__c(
                RecordTypeId = bobSellerAdsRecordType.Id,
                Parent_Seller__c=acc4.Id,
                Account_Manager__c=UserInfo.getUserId(),
                Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,
                Seller__c=acc4.Id,
                BoB__c = bob4.Id
            );
    
            insert new List<BoB_Seller__c>{bs,bs2,bs4};
    
            template1 = new Action_Template__c(Name='Tempalte1',Active__c=true);
            insert template1;
    
            action1 = new Action__c(Name='Action1',Action_Template__c=template1.Id,LTTM_Seller__c=bs.Id,Status__c='Not Started');
            insert action1;
    
            template2 = new Action_Template__c(Name='Tempalte2',Active__c=true);
            insert template2;
    
            action2 = new Action__c(Name='Action2',Action_Template__c=template2.Id,LTTM_Seller__c=bs2.Id,Status__c='Not Started');
            insert action2;   
    }

    @IsTest
    static void testApexInit(){
        setUpData();
        Test.startTest(); 

            Map<String,Object> mapResult1 =  TransferSellersController.apexInit(bob2.Id,null);
            System.assertNotEquals(null, mapResult1.get('error'));

            Map<String,Object> mapResult2 =  TransferSellersController.apexInit(bob3.Id,bs2.Id);
            System.assertEquals(null, mapResult2.get('error'));

            Map<String,Object> mapResult3 =  TransferSellersController.apexInit(bob2.Id,bs.Id);

            //system.System.debug('size:::'+mapResult1);
            //System.assertEquals(1, ((List<BOB__C>)mapResult.get('listPossibleBob')).size(),'1 realted contact');

            bob.Status__c = 'BoB Inactive';
            update bob;
            Map<String,Object> mapResult4 =  TransferSellersController.apexInit(bob.Id,bs.Id);
            System.assertNotEquals(null, mapResult4.get('error')); // expect error

            Map<String,Object> mapResult5 =  TransferSellersController.apexInit(bob4.Id,bs4.Id);
            System.assertNotEquals(null, mapResult5.get('error')); // expect error

        Test.stopTest();
        
    }  

    @IsTest
    static void testTransferCohortSeller(){
        setUpData();
        BoB_Seller__c bobSeller = new BoB_Seller__c(Account_Manager__c = UserInfo.getUserId(),TTEC_MANAGER__c=UserInfo.getUserId());
        Test.startTest();
            Map<String,Object> mapResult =  TransferSellersController.transferCohortSeller(bob2.Id,bs.Id,bobSeller,true,bob,null);
        	//System.assertEquals('ko', mapResult.get('error'));
        	bob.Status__c = 'BoB Inactive';
        	mapResult = TransferSellersController.transferCohortSeller(bob2.Id,bs.Id,bobSeller,true,bob,null);
        	System.assertEquals('ko', mapResult.get('status'));
        Test.stopTest();
        BoB_Seller__c bsSel = [Select Id,Name,BoB__c From BoB_Seller__c Where Id=:bs.Id];
       
    }

    @IsTest
    static void testTransferCohortSellerWithError(){
        // 04.06.2024 / Sophal Noch / US-0015352 : cover the error case to reach 90% coverage
        setUpData();
        BoB_Seller__c bobSeller = new BoB_Seller__c(Account_Manager__c = UserInfo.getUserId(),TTEC_MANAGER__c=UserInfo.getUserId());
        Map<String,Object> mapResult =  TransferSellersController.transferCohortSeller(bob2.Id,bs.Id,bobSeller,true,bob,null);
        System.assertEquals(null, mapResult.get('error'));

        mapResult = TransferSellersController.transferCohortSeller(bob2.Id,bs.Id,null,true,null,null);
        System.assertNotEquals(null, mapResult.get('error')); // expect error
        
        mapResult = TransferSellersController.apexInit(bob.Id,bs.Id);
        System.assertNotEquals(null, mapResult.get('error')); // expect error


        RecordType boblttmRecordType = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
        BoB__c bob5 = new BoB__c(
            Status__c='BoB Active',
            EBH_BOBCNTRY__c='3',
            EBH_BOBVertical__c='Fashion',
            Managed_Type__c ='LTTM Plus',
            LTTM_Group__c='test group5',
            RecordTypeId=boblttmRecordType.Id,
            ownerId = UserInfo.getUserId()
        );
        insert bob5;
        RecordType bobSellerlttmRecordType = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB_Seller__c bs5 = new BoB_Seller__c(
            RecordTypeId = bobSellerlttmRecordType.Id,
            Parent_Seller__c=acc.Id,
            Account_Manager__c=UserInfo.getUserId(),
            Status__c='New',
            Seller__c=acc.Id,
            BoB__c = bob5.Id,
            EBH_BOBSegment__c='MSO',
            BoB_Subsegment__c='Platin',
            Call_Outcome__c='Next call scheduled',
            Call_Attempt__c = 0
        );
        insert bs5;

        mapResult =  TransferSellersController.transferCohortSeller(bob2.Id,bs5.Id,bobSeller,true,bob,null);
        System.assertNotEquals(null, mapResult.get('error')); // expect error

    }

    @isTest
    static void test_createaction() {
        setUpData();

        Test.startTest();
            List<BoB_Seller__c> lstbs = [select Id, BOB__c, RecordTypeId from BoB_Seller__c where BOB__c=:bob.Id AND RecordType.DeveloperName='LTTM' AND Managed_Type__c='LTTM Managed'];
            Test.setCurrentPage(Page.TransferSellers);

            ApexPages.currentPage().getParameters().put('id',bob.Id);

            ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstbs);
            sc.setSelected(new List<BoB_Seller__c>());
            TransferSellersController tc = new TransferSellersController(sc);
            sc.setSelected(lstbs);
            tc = new TransferSellersController(sc);
            //tc.backToListView();

            System.assert(String.isNotBlank(tc.bobId));
            System.assert(String.isNotBlank(tc.bobSellerIds));

        Test.stopTest();
    }

}