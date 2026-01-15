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
 * : 10.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
 */
@isTest
private class CreateActionSellerLttmControllerTest {

    static testMethod void testApexInitActionTemplateList() {
    	RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB__c bob = new BoB__c(RecordTypeId = bobRecordTypeLTTM.Id ,Name='Bob 1',Managed_Segment__c='Strategic');
        insert bob;
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
 		Account seller = new Account(Name='Seller',RecordTypeID = sellerRecordType.Id);
        insert seller;
        BOB_Seller__c bobSeller = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=bob.Id, Seller__c=seller.Id);
        insert bobSeller;
        RecordType recTemplateLttm = ApexUtil.getRecordTypeByName('Action_Template__c',EBH_ConstantsUtility.RECTYPE_ACTION_TEMPLATE_LTTM);
        RecordType recAction = ApexUtil.getRecordTypeByName('Action__c',EBH_ConstantsUtility.RECTYPE_ACTION_TEMPLATE_LTTM);

        Action_Template__c parentTemplate = new Action_Template__c(Name='parentTemplate',RecordTypeId=recTemplateLttm.Id,Active__c=true);
        insert parentTemplate;

        Action_Template__c tm1 = new Action_Template__c(Name='Temp1',RecordTypeId=recTemplateLttm.Id,Required__c=true,Active__c=true,Parent_Action__c=parentTemplate.Id,Managed_Segment__c ='Strategic');
        Action_Template__c tm2 = new Action_Template__c(Name='Temp2',RecordTypeId=recTemplateLttm.Id,Required__c=false,Active__c=true,Parent_Action__c=parentTemplate.Id,Managed_Segment__c='Strategic');
        insert new Action_Template__c[]{tm1,tm2};

        Test.startTest();
        	Map<String,Object> mapResultPiclist = CreateActionSellerLttmController.getPicklistValueData();
        	Map<String,Object> mapResult = CreateActionSellerLttmController.apexInitActionTemplateList(bob.Id, '','');
        	System.assertEquals(1,((List<Object>)mapResult.get('listSelectedAction')).size(),'1 templates mandatory');
        	System.assertEquals(1,((List<Object>)mapResult.get('listPossibleActions')).size(),'1 templates not mandatory');
        Test.stopTest();

    }

    static testMethod void testApexInitActionTemplateListWithBoBSellers() {
        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB__c bob = new BoB__c(RecordTypeId = bobRecordTypeLTTM.Id ,Name='Bob 1',Managed_Segment__c ='Strategic');
        insert bob;
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
 		Account seller = new Account(Name='Seller',RecordTypeID = sellerRecordType.Id);
        insert seller;
        BOB_Seller__c bobSeller = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=bob.Id, Seller__c=seller.Id);
        insert bobSeller;
        RecordType recTemplateLttm = ApexUtil.getRecordTypeByName('Action_Template__c',EBH_ConstantsUtility.RECTYPE_ACTION_TEMPLATE_LTTM);
        RecordType recAction = ApexUtil.getRecordTypeByName('Action__c',EBH_ConstantsUtility.RECTYPE_ACTION_TEMPLATE_LTTM);

        Action_Template__c parentTemplate = new Action_Template__c(Name='parentTemplate',RecordTypeId=recTemplateLttm.Id,Active__c=true);
        insert parentTemplate;

        Action_Template__c tm1 = new Action_Template__c(Name='Temp1',RecordTypeId=recTemplateLttm.Id,Required__c=true,Active__c=true,Parent_Action__c=parentTemplate.Id,Managed_Segment__c ='Strategic');
        Action_Template__c tm2 = new Action_Template__c(Name='Temp2',RecordTypeId=recTemplateLttm.Id,Required__c=false,Active__c=true,Parent_Action__c=parentTemplate.Id,Managed_Segment__c ='Strategic');
        insert new Action_Template__c[]{tm1,tm2};

        Test.startTest();
        	Map<String,Object> mapResult = CreateActionSellerLttmController.apexInitActionTemplateList(bob.Id, bobSeller.Id,'');
        	System.assertEquals(1,((List<Object>)mapResult.get('listSelectedAction')).size(),'1 templates mandatory');
        	System.assertEquals(1,((List<Object>)mapResult.get('listPossibleActions')).size(),'1 templates not mandatory');
        Test.stopTest();

    }

    static testMethod void testApexSaveActions() {
    	RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB__c bob1 = new BoB__c(RecordTypeId = bobRecordTypeLTTM.Id ,Name='Bob2',Managed_Segment__c ='Strategic');
        insert bob1;
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
 		Account seller = new Account(Name='Seller',RecordTypeID = sellerRecordType.Id);
        insert seller;
        BOB_Seller__c bobSeller = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=bob1.Id, Seller__c=seller.Id);
        System.debug('bobSellertest>>>'+bobSeller);
        insert bobSeller;

        RecordType recTemplateLttm = ApexUtil.getRecordTypeByName('Action_Template__c',EBH_ConstantsUtility.RECTYPE_ACTION_TEMPLATE_LTTM);
        RecordType recAction = ApexUtil.getRecordTypeByName('Action__c',EBH_ConstantsUtility.RECTYPE_ACTION_TEMPLATE_LTTM);

        Action_Template__c tm1 = new Action_Template__c(Name='Temp1',RecordTypeId=recTemplateLttm.Id,Required__c=true,Active__c=true);
        Action_Template__c tm2 = new Action_Template__c(Name='Temp2',RecordTypeId=recTemplateLttm.Id,Required__c=false,Active__c=true,Managed_Segment__c ='Strategic');
        insert new Action_Template__c[]{tm1,tm2};

        Test.startTest();
        	Map<String,Object> mapResult = CreateActionSellerLttmController.apexSaveActions(bob1.Id, '',new List<String>{tm2.Id});
        	System.assertEquals('ok',mapResult.get('status')+'','saving complete');
        	Action__c[] listActionResult =  [Select Id,Name From Action__c Where LTTM_Seller__c =:bobSeller.Id];
        	System.assertEquals(1,listActionResult.size(),'1 action created');

        	mapResult = CreateActionSellerLttmController.apexInitActionTemplateList(bob1.Id, '','');

        Test.stopTest();

    }

    ////Testing for VF Page controller
    @isTest
    static void test_createaction() {

        User existAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
    	List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
       // admUsers[0].BoB_Country__c = '3';
       
        System.runAs(existAdmin){ // Sophal Noch / 06.07.2022 / US-0012056 : fix MIXED_DML error
            insert admUsers;
        }
        
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        BoB__c bob = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='Spain',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
        insert bob;
        BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        BoB_Seller__c bs1 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        List<BoB_Seller__c> lstBs = new List<BoB_Seller__c>{bs,bs1};
        insert lstBs;
        String auProfile = [SELECT Id FROM Profile WHERE Name =: EBH_ConstantsUtility.TICKET_AU_PROFILE].Id;
        User auUser1 = EBH_TestDataFactory.createUser(EBH_ConstantsUtility.TICKET_AU_PROFILE);
        Test.startTest();

            System.runAs(admUsers[0]){
                Test.setCurrentPage(Page.CreateActionForCohortSeller);

                ApexPages.currentPage().getParameters().put('id',bob.Id);

                ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstBs);
                sc.setSelected(lstBs);
                CreateActionSellerLttmController tc = new CreateActionSellerLttmController(sc);

                System.assert(String.isNotBlank(tc.bobId));
                System.assert(String.isNotBlank(tc.bobSellerIds));
            }

        Test.stopTest();
    }

    @isTest
    static void test_createactionWithoutBoBSeller() {

        User existAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
    	List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
       // admUsers[0].BoB_Country__c = '3';

        System.runAs(existAdmin){ // Sophal Noch / 06.07.2022 / US-0012056 : fix MIXED_DML error
            insert admUsers;
        }
        
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        BoB__c bob = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='Spain',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
        insert bob;
        BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        BoB_Seller__c bs1 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        List<BoB_Seller__c> lstBs = new List<BoB_Seller__c>{bs,bs1};
        insert lstBs;
        String auProfile = [SELECT Id FROM Profile WHERE Name =: EBH_ConstantsUtility.TICKET_AU_PROFILE].Id;
        User auUser1 = EBH_TestDataFactory.createUser(EBH_ConstantsUtility.TICKET_AU_PROFILE);
        Test.startTest();

            System.runAs(admUsers[0]){
                Test.setCurrentPage(Page.CreateActionForCohortSeller);

                ApexPages.currentPage().getParameters().put('id',bob.Id);

                ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstBs);
                CreateActionSellerLttmController tc = new CreateActionSellerLttmController(sc);

                System.assert(String.isNotBlank(tc.msg) && tc.isError);

                //Back to BoB record
                tc.backToListView();
            }

        Test.stopTest();
    }

    @isTest
    static void test_apexSaveActionsWithBoBSeller() {
    	RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB__c bob1 = new BoB__c(RecordTypeId = bobRecordTypeLTTM.Id ,Name='Bob2',Managed_Segment__c ='Strategic');
        insert bob1;
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
 		Account seller = new Account(Name='Seller',RecordTypeID = sellerRecordType.Id);
        insert seller;
        BOB_Seller__c bobSeller = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=bob1.Id, Seller__c=seller.Id);
        System.debug('bobSellertest>>>'+bobSeller);
        insert bobSeller;

        RecordType recTemplateLttm = ApexUtil.getRecordTypeByName('Action_Template__c',EBH_ConstantsUtility.RECTYPE_ACTION_TEMPLATE_LTTM);
        RecordType recAction = ApexUtil.getRecordTypeByName('Action__c',EBH_ConstantsUtility.RECTYPE_ACTION_TEMPLATE_LTTM);

        Action_Template__c tm1 = new Action_Template__c(Name='Temp1',RecordTypeId=recTemplateLttm.Id,Required__c=true,Active__c=true);
        Action_Template__c tm2 = new Action_Template__c(Name='Temp2',RecordTypeId=recTemplateLttm.Id,Required__c=false,Active__c=true,Managed_Segment__c ='Strategic');
        insert new Action_Template__c[]{tm1,tm2};

        Test.startTest();
        	Map<String,Object> mapResult = CreateActionSellerLttmController.apexSaveActions(bob1.Id, String.valueOf(bobSeller.Id),new List<String>{tm2.Id});
        	System.assertEquals('ok',mapResult.get('status')+'','saving complete');
        	Action__c[] listActionResult =  [Select Id,Name From Action__c Where LTTM_Seller__c =:bobSeller.Id];
        	System.assertEquals(1,listActionResult.size(),'1 action created');

        	mapResult = CreateActionSellerLttmController.apexInitActionTemplateList(bob1.Id, '','');

        Test.stopTest();

    }


  
}