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
 * : 07.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
 */
@isTest
private class BoBSellerTriggerHandlerTest {

    static testMethod void testValidateBoBSeller()
    {
        User existAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        BoBSellerViewControllerTest.setUpUserGroup();
        List<Account> sellers = EBH_TestDataFactory.createAccounts(3, 'EBH_Seller');
        RecordType bobRecordTypeLttm = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
        RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        Test.startTest();
            BoB__c bob = new BoB__c(RecordTypeId = bobRecordTypeLttm.Id ,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,/*BoB_Cohort__c='2018',*/EBH_BOBCNTRY__c='Spain',EBH_BOBVertical__c='Fashion');
            insert bob;
            BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=sellers[0].Id,Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            insert bs;  
        Test.stopTest();
        //test duplicate
        BoB_Seller__c bs2 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=sellers[0].Id,Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        insert bs2;
        try
        {
            bs2.Seller__c=sellers[0].Id;
            update bs2;
        }catch(Exception ex)
        {
            System.assert(ex.getDmlMessage(0).startsWith('Once created, seller cannot be changed'),'duplicate error');
        }
        //test seller occupied by another active bob
        BoB__c bob2 = new BoB__c(RecordTypeId = bobRecordTypeLttm.Id ,Status__c=EBH_ConstantsUtility.BOB_STATUS_ACTIVE/*,BoB_Cohort__c='2018'*/,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion');
        insert bob2;
        BoB_Seller__c bs3 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=sellers[0].Id,Seller__c=sellers[2].Id,BoB__c = bob2.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        insert bs3;
//        BoB__c bob4 = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,BoB_Cohort__c='2018',EBH_BOBCNTRY__c=null,EBH_BOBVertical__c='Fashion');
        BoB__c bob4 = new BoB__c(RecordTypeId = bobRecordTypeLttm.Id , Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='Portugal',EBH_BOBVertical__c='Fashion');
        insert bob4;
        BoB_Seller__c bs4 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=sellers[0].Id,Seller__c=sellers[0].Id,BoB__c = bob4.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        try
        {
            insert bs4;
        }catch(Exception ex)
        {
            system.debug('>>>error: '+ex.getDmlMessage(0));
            System.assert(ex.getDmlMessage(0).startsWith(System.Label.ErrorSellerPartOfActiveBoB.substring(0,10)),'error: bob seller occupied by another aticve bob');
        }
        //test delete
        try
        {
            delete bs;
        }catch(Exception ex)
        {
            System.assert(ex.getMessage().contains(System.Label.ErrorBoBSellerDelete),'error: only New can be deleted');
        }
        //test assignAccountManagerToSellerOwner
        List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
        //admUsers[0].BoB_Country__c = '3';

        System.runAs(existAdmin){
            insert admUsers;
        }

        
        System.runAs(admUsers[0])
        {
        	Group gcxOp = [Select Id,Name,DeveloperName From Group Where DeveloperName =:EBH_ConstantsUtility.BOB_GROUP_BOB_GCX_OPERATIONS];
        	GroupMember gm1 = new GroupMember(UserOrGroupId=admUsers[0].Id,GroupId=gcxOp.Id);
        	insert gm1;
        }
        bs3.Account_Manager__c = admUsers[0].Id;
        update bs3;
        /*
        Account selAccount = [Select Id,OwnerId from Account where Id=:sellers[2].Id];
        System.assertEquals(bs3.Account_Manager__c,selAccount.OwnerId,'Owner updated from BoBSeller Account Manager');
        */
    }
    static testMethod void testpopulateBobSeller(){

        User existAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

    	RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
    	List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
        //admUsers[0].BoB_Country__c = '3';
        System.runAs(existAdmin){
            insert admUsers;
        }
        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
    	 Test.startTest();
            BoB__c bob = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='Spain',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
            insert bob;
            BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            insert bs;

            BoB__c bob1 = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='Spain',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
            insert bob1;
            BoB_Seller__c bs1 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=admUsers[0].Id,Seller__c=sellers[0].Id,BoB__c = bob1.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            insert bs1;

        Test.stopTest();
        BoB_Seller__c bss = [select Account_Manager__c, Parent_Seller__c,Seller__c, EBH_BOBSegment__c from BoB_Seller__c where id =: bs.Id];
        System.assertNotEquals(bss.Account_Manager__c,bob.Account_Manager__c,'auto populate bobSeller.Account Manager = bob.Account Manager');
        System.assertEquals(bss.Parent_Seller__c,bss.Seller__c,'set "Parent Seller" = seller if Parent Seller is empty');
        //System.assertEquals(bss.EBH_BOBSegment__c,EBH_ConstantsUtility.BOB_SELLER_SEGMENT_LTTM,'set default Segment to LTTM for LTTML bob record type');
        BoB_Seller__c bss1 = [select Account_Manager__c, Parent_Seller__c,Seller__c, EBH_BOBSegment__c from BoB_Seller__c where id =: bs1.Id];
        System.assertEquals(bss1.Account_Manager__c,bob1.Account_Manager__c,'auto populate bobSeller.Account Manager = bob.Account Manager');
    }


    @isTest
    private static void testUpdateUserAvailibilityWithBobSeller(){
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',UserAvailabilityTrigger__c = true, EBH_TaskTrigger__c = true);

        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        
        BoB__c bob = new BoB__c(
            RecordTypeId = bobRecordTypeLTTM.Id ,
            Name='Bob 1',
            Status__c = 'BoB Active',
            Managed_Type__c = 'LTTM Managed'
        );
        insert bob;
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
 		Account seller = new Account(Name='Seller',RecordTypeID = sellerRecordType.Id);
        Account seller1 = new Account(Name='Seller222',RecordTypeID = sellerRecordType.Id);
        insert new List<Account>{seller,seller1};

        Id currentUserId = UserInfo.getUserId();

        Date d = Date.newInstance(Date.today().year(), Date.today().month(), Date.today().day());
        Datetime dt = (DateTime)d;
        String dow = dt.format('EEEE');
        if (dow == 'Saturday') d = Date.today().addDays(3);
        else if (dow == 'Sunday') d = Date.today().addDays(2);
        
        BOB_Seller__c bobSeller = new BOB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLTTM.Id ,
            BOB__c=bob.Id, 
            Seller__c=seller.Id,
            Next_Call_Schedule_Date__c = d,
            Time_Slot__c = 'Morning (9 AM to 12 PM)'
        );

        //  15.07.2023 / Sophal Noch / US-0013955 : fix test class
        List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
        System.runAs(admUsers[0]){
            update new User(Id = currentUserId); //, BoB_Country__c = '3'
            Group gcxOp = [Select Id,Name,DeveloperName From Group Where DeveloperName =:EBH_ConstantsUtility.BOB_GROUP_BOB_GCX_OPERATIONS];
            GroupMember gm1 = new GroupMember(UserOrGroupId=currentUserId, GroupId=gcxOp.Id);
            insert gm1;
        }

        
        insert bobSeller;
        
        bobSeller.Account_Manager__c = currentUserId;
        update bobSeller;



        Test.startTest();
            User_Availability__c uv = new User_Availability__c(Date__c=d, Unique_Id__c=(currentUserId+'#'+d), Available_Calls_Morning_Slot__c = 4, Available_Calls_Afternoon_Slot__c = 4, OwnerId=currentUserId);
            insert uv;
            uv = [Select Id, Date__c, Unique_Id__c, Scheduled_Calls_Morning_Slot__c, Scheduled_Calls_Afternoon_Slot__c From User_Availability__c Where Id =: uv.Id];
            System.assertEquals(1, uv.Scheduled_Calls_Morning_Slot__c);
            System.assertEquals(null, uv.Scheduled_Calls_Afternoon_Slot__c);

            BOB_Seller__c bobSeller1 = new BOB_Seller__c(
                RecordTypeId = bobSellerRecordTypeLTTM.Id ,
                BOB__c=bob.Id, 
                Seller__c=seller1.Id,
                Next_Call_Schedule_Date__c = d,
                Time_Slot__c = 'Afternoon(1 PM to 5 PM)'
            );

            insert bobSeller1;
            bobSeller1.Account_Manager__c = currentUserId;
            update bobSeller1;

            uv = [Select Id, Date__c, Unique_Id__c, Scheduled_Calls_Morning_Slot__c, Scheduled_Calls_Afternoon_Slot__c From User_Availability__c Where Id =: uv.Id];
            System.assertEquals(1, uv.Scheduled_Calls_Morning_Slot__c);
            System.assertEquals(1, uv.Scheduled_Calls_Afternoon_Slot__c);

        Test.stopTest();
    }

    @isTest
    private static void populateSomeValuesTest(){

        Profile p =[SELECT Id, Name FROM Profile WHERE Name = 'Business Admin'];
	    User existAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        User businessAdm = new User(Alias             = 'usr', 
                            Email             = 'usr' + Math.random() + '@org.com', 
                            EmailEncodingKey  = 'UTF-8', 
                            LastName          = 'Testing' + Math.random(), 
                            LanguageLocaleKey = 'en_US', 
                            LocaleSidKey      = 'en_US', 
                            ProfileId         = p.Id, 
                            TimeZoneSidKey    = 'America/Los_Angeles',
                            UserName          = 'usr' + Math.random() + '@org.com',
                            IsActive = true,
                            Competency__c = 'Copy');   
        System.runAs(existAdmin){
            insert businessAdm;
        }

    	RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',BoBSellerTriggerHandler.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        Id bsId = null;
    	Test.startTest();
            System.runAs(businessAdm){
                BoB__c bob = new BoB__c(Status__c=BoBSellerTriggerHandler.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='Spain',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = businessAdm.Id);
                insert bob;
                BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
                insert bs;
                bsId = bs.Id;
            }
        Test.stopTest();
        BoB_Seller__c bss = [SELECT Vertical__c, BoB_Owner_Email__c, Seller__r.EBH_MainVertical__c, BoB__r.Owner.Email FROM BoB_Seller__c WHERE Id =: bsId];
        System.assertEquals(bss.Vertical__c,bss.Seller__r.EBH_MainVertical__c,'auto populate Vertical__c=Seller__r.EBH_MainVertical__c');
        System.assertEquals(bss.BoB_Owner_Email__c,bss.BoB__r.Owner.Email,'auto populate BoB_Owner_Email__c=BoB__r.Owner.Email');
    }

    @isTest
    public static void testSyncBoBSellerToAcc(){

        // 11.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management

        Account parentSeller = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller')[0];

        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');

        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
    	RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

        User currentUser = [Select Id From User Where Id = : UserInfo.getUserId() And IsActive = true Limit 1];

        BoB__c lttmBob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id, Managed_Type__c = 'Others Managed', Account_Manager__c = currentUser.Id);
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

        BOB_Seller__c lttmBobSeller1 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[0].Id, Account_Manager__c = currentUser.Id, EBH_BOBSegment__c='Pro-Trader Cat');
        insert new List<BOB_Seller__c>{lttmBobSeller1};

        RecordType actionTemplateLTTM = ApexUtil.getRecordTypeByName('Action_Template__c','LTTM');
        Action_Template__c parentTemplate = new Action_Template__c(Name='parentTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Active__c=true);
        insert parentTemplate;

        Action_Template__c childTemplate = new Action_Template__c(Name='childTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Parent_Action__c=parentTemplate.Id,Active__c=true);
        insert childTemplate;

        Action__c action1 = new Action__c(Name='Action1',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller1.Id);
        insert new List<Action__c>{action1};

        lttmBob.Status__c = 'BoB Active';
        update lttmBob;
        Test.startTest();
            lttmBobSeller1.Status__c = 'Draft';
            update lttmBobSeller1;
        Test.stopTest();
        
        List<Account> listAcc = [Select Id, EBH_BOBManaged__c,EBH_BOBSegment__c From Account Where Id IN :new Set<String>{lttmBobSeller1.Seller__c}];
        System.debug('EBH_BOBSegment__c :::'+listAcc[0].EBH_BOBSegment__c);
        System.assert(lttmBobSeller1.EBH_BOBSegment__c == listAcc[0].EBH_BOBSegment__c, listAcc[0].EBH_BOBSegment__c);
        System.assertEquals(true, listAcc[0].EBH_BOBManaged__c);
    }

    @isTest
    public static void testUnSyncBoBSellerToAcc(){

        // 11.12.2023 / Sophal Noch / US-0014363 - Ph 1 - Deactivate Sellers button

        Account parentSeller = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller')[0];

        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        sellers[0].EBH_BOBManaged__c = true;
        update sellers;

        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
    	RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

        User currentUser = [Select Id From User Where Id = : UserInfo.getUserId() And IsActive = true Limit 1];

        BoB__c lttmBob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id, Managed_Type__c = 'Others Managed', Account_Manager__c = currentUser.Id);
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

        BOB_Seller__c lttmBobSeller1 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[0].Id, Account_Manager__c = currentUser.Id);
        insert new List<BOB_Seller__c>{lttmBobSeller1};

        RecordType actionTemplateLTTM = ApexUtil.getRecordTypeByName('Action_Template__c','LTTM');
        Action_Template__c parentTemplate = new Action_Template__c(Name='parentTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Active__c=true);
        insert parentTemplate;

        Action_Template__c childTemplate = new Action_Template__c(Name='childTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Parent_Action__c=parentTemplate.Id,Active__c=true);
        insert childTemplate;

        Action__c action1 = new Action__c(Name='Action1',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller1.Id);
        insert new List<Action__c>{action1};

        lttmBob.Status__c = 'BoB Inactive';
        update lttmBob;
        Test.startTest();
            lttmBobSeller1.Status__c = 'Inactive';
            update lttmBobSeller1;
        Test.stopTest();

        List<Account> listAcc = [Select Id, EBH_BOBManaged__c From Account Where Id IN :new Set<String>{lttmBobSeller1.Seller__c}];
        System.assertEquals(false, listAcc[0].EBH_BOBManaged__c);
    } 

    @isTest
    public static void testDeleteBoBSellerToUnsyncAcc(){

        // 30.01.2024 / Sophal Noch / US-0014277 

        Account parentSeller = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller')[0];

        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        sellers[0].EBH_BOBManaged__c = true;
        update sellers;

        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
    	RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

        User currentUser = [Select Id From User Where Id = : UserInfo.getUserId() And IsActive = true Limit 1];

        BoB__c lttmBob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id, Managed_Type__c = 'Others Managed', Account_Manager__c = currentUser.Id);
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

        BOB_Seller__c lttmBobSeller1 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[0].Id, Account_Manager__c = currentUser.Id);
        insert new List<BOB_Seller__c>{lttmBobSeller1};

        RecordType actionTemplateLTTM = ApexUtil.getRecordTypeByName('Action_Template__c','LTTM');
        Action_Template__c parentTemplate = new Action_Template__c(Name='parentTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Active__c=true);
        insert parentTemplate;

        Action_Template__c childTemplate = new Action_Template__c(Name='childTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Parent_Action__c=parentTemplate.Id,Active__c=true);
        insert childTemplate;

        Action__c action1 = new Action__c(Name='Action1',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller1.Id);
        insert new List<Action__c>{action1};

        List<Account> listAcc = [Select Id, EBH_BOBManaged__c From Account Where Id IN :new Set<String>{sellers[0].Id}];
        System.assertEquals(true, listAcc[0].EBH_BOBManaged__c);

        Test.startTest();
            delete lttmBobSeller1;
        Test.stopTest();

        listAcc = [Select Id, EBH_BOBManaged__c From Account Where Id IN :new Set<String>{sellers[0].Id}];
        System.assertEquals(false, listAcc[0].EBH_BOBManaged__c);

        
    }    

    @isTest
    public static void testSyncBoBSellerToAcc_Invited_to_Active() {
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c', 'Light_Touch_Category_Cohort');
        RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c', 'LTTM');

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() AND IsActive = true LIMIT 1];

        BoB__c lttmBob = new BoB__c(
            Status__c = 'Draft',
            EBH_BOBCNTRY__c = '77',
            EBH_BOBVertical__c = 'Fashion',
            RecordTypeId = bobRecordTypeLTTM.Id,
            Managed_Type__c = 'Others Managed',
            Account_Manager__c = currentUser.Id
        );
        insert lttmBob;

        Category_Tree__c ct0 = new Category_Tree__c(Name = 'l0', Active__c = true, Site__c = '77');
        insert ct0;
        Category_Tree__c ct1 = new Category_Tree__c(Name = 'l1', Note_ID__c = ct0.Id, Active__c = true);
        insert ct1;
        Category_Tree__c ct2 = new Category_Tree__c(Name = 'l2a', Note_ID__c = ct1.Id, Active__c = true);
        insert ct2;
        Category_Tree__c ct3 = new Category_Tree__c(Name = 'l3', Note_ID__c = ct2.Id, Active__c = true);
        insert ct3;

        Map<String, Object> resultSave = CategoryTreeController.apexSaveCat(lttmBob.Id, new List<String>{ct3.Id});
        System.assertEquals('ok', resultSave.get('status'), 'save success');

        BOB_Seller__c lttmBobSeller1 = new BOB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLTTM.Id,
            BOB__c = lttmBob.Id,
            Seller__c = sellers[0].Id,
            Account_Manager__c = currentUser.Id,
            EBH_BOBSegment__c = 'Pro-Trader Cat',
            Status__c = 'Invited'
        );
        BOB_Seller__c lttmBobSeller2 = new BOB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLTTM.Id,
            BOB__c = lttmBob.Id,
            Seller__c = sellers[1].Id,
            Account_Manager__c = currentUser.Id,
            EBH_BOBSegment__c = 'Pro-Trader Cat',
            Status__c = 'Invited'
        );
        insert new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2};

        RecordType actionTemplateLTTM = ApexUtil.getRecordTypeByName('Action_Template__c', 'LTTM');
        Action_Template__c parentTemplate = new Action_Template__c(
            Name = 'parentTemplate',
            RecordTypeId = actionTemplateLTTM.Id,
            Country__c = 'DE',
            Active__c = true
        );
        insert parentTemplate;

        Action_Template__c childTemplate = new Action_Template__c(
            Name = 'childTemplate',
            RecordTypeId = actionTemplateLTTM.Id,
            Country__c = 'DE',
            Parent_Action__c = parentTemplate.Id,
            Active__c = true
        );
        insert childTemplate;

        Action__c action1 = new Action__c(
            Name = 'Action1',
            Completed_Date__c = null,
            Action_Template__c = childTemplate.Id,
            LTTM_Seller__c = lttmBobSeller1.Id
        );
        insert action1;

        lttmBob.Status__c = 'BoB Active';
        update lttmBob;

        Test.startTest();
            lttmBobSeller1.Status__c = 'Draft';
            lttmBobSeller2.Status__c = 'Draft';
            update new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2};
        Test.stopTest();

        List<Account> listAcc = [SELECT Id, EBH_BOBManaged__c, EBH_BOBSegment__c FROM Account WHERE Id IN :new Set<String>{lttmBobSeller1.Seller__c}];
        System.debug('EBH_BOBSegment__c :::' + listAcc[0].EBH_BOBSegment__c);
        System.assert(lttmBobSeller1.EBH_BOBSegment__c == listAcc[0].EBH_BOBSegment__c, listAcc[0].EBH_BOBSegment__c);
        System.assertEquals(true, listAcc[0].EBH_BOBManaged__c);
    }

    @isTest
    private static void testIsChangedAndEligible() {
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c', 'Light_Touch_Category_Cohort');
        RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c', 'LTTM');

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() AND IsActive = true LIMIT 1];

        BoB__c lttmBob = new BoB__c(
            Status__c = 'Draft',
            EBH_BOBCNTRY__c = '77',
            EBH_BOBVertical__c = 'Fashion',
            RecordTypeId = bobRecordTypeLTTM.Id,
            Managed_Type__c = 'LTTM Managed',
            Account_Manager__c = currentUser.Id
        );
        insert lttmBob;

        Category_Tree__c ct0 = new Category_Tree__c(Name = 'l0', Active__c = true, Site__c = '77');
        insert ct0;
        Category_Tree__c ct1 = new Category_Tree__c(Name = 'l1', Note_ID__c = ct0.Id, Active__c = true);
        insert ct1;
        Category_Tree__c ct2 = new Category_Tree__c(Name = 'l2a', Note_ID__c = ct1.Id, Active__c = true);
        insert ct2;
        Category_Tree__c ct3 = new Category_Tree__c(Name = 'l3', Note_ID__c = ct2.Id, Active__c = true);
        insert ct3;

        Map<String, Object> resultSave = CategoryTreeController.apexSaveCat(lttmBob.Id, new List<String>{ct3.Id});
        System.assertEquals('ok', resultSave.get('status'), 'save success');

        BOB_Seller__c lttmBobSeller1 = new BOB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLTTM.Id,
            BOB__c = lttmBob.Id,
            Seller__c = sellers[0].Id,
            Account_Manager__c = currentUser.Id,
            EBH_BOBSegment__c = 'Pro-Trader Cat',
            Status__c = 'Invited'
        );
        BOB_Seller__c lttmBobSeller2 = new BOB_Seller__c(
            RecordTypeId = bobSellerRecordTypeLTTM.Id,
            BOB__c = lttmBob.Id,
            Seller__c = sellers[1].Id,
            Account_Manager__c = currentUser.Id,
            EBH_BOBSegment__c = 'Pro-Trader Cat',
            Status__c = 'New'
        );
        insert new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2};

        Test.startTest();
            lttmBobSeller1 = [SELECT Id,Seller_Portal_Eligible__c FROM BOB_Seller__c WHERE Id =: lttmBobSeller1.Id];
            lttmBobSeller2 = [SELECT Id,Seller_Portal_Eligible__c FROM BOB_Seller__c WHERE Id =: lttmBobSeller2.Id];
            // Verify the result
            System.assertEquals(true, lttmBobSeller1.Seller_Portal_Eligible__c, 'Expected sellerPortalEligible to be true');
            System.assertEquals(false, lttmBobSeller2.Seller_Portal_Eligible__c, 'Expected sellerPortalEligible to be false because Status is New');
        Test.stopTest();

    }
}