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
private class ActionCreationControllerTest {
    
	public static final String RECTYPE_ACTION_TEMPLATE_ACQ='Acquisition';
    static final RecordType recTypeAuSMBProject = ApexUtil.getRecordTypeByName('EBH_Project__c','eBayAUSMB');

    @TestSetup
    static void makeData(){
        EBH_TestDataFactory.setUpCustomSettings(); 
		ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;

        Account accPartner1 = new Account();
		accPartner1.Name = 'accPartner1';
		accPartner1.RecordTypeId = ApexUtil.getRecordTypeByName('Account', 'EBH_Partner').Id;
		accPartner1.EBH_PartnerType__c = 'Shop System';
		insert accPartner1;

		Lead oneL = EBH_TestDataFactory.createLeads();
		oneL.RecordTypeId = ApexUtil.getRecordTypeByName('Lead', 'EBH_eBayAUSMB').Id;
		oneL.EBH_eBayID__c = 'biggest_sellert_test';
		oneL.Site__c = 'AU';
		oneL.LeadSource = 'Self Gen';
		oneL.LeadSegment__c = 'SMB';
		oneL.OtherLeadSource__c = 'other leadsource tst';
		oneL.LastName = 'AMT Lead tst 01';
		oneL.Phone = '012 345 5678';
		oneL.Website = 'www.test.com.test';
		oneL.Email = 'test@tes.com.invalid';
		oneL.Shopping_Card__c = accPartner1.Id;
		oneL.EBH_Vertical__c = 'Collectibles';
		oneL.VAT_Number__c = '12312312312312';
		oneL.isapproved__c = true;
		oneL.Company = 'test1 company';
		insert oneL;
    }

    static testMethod void testApexInitActionTemplateList() {
        EBH_Project__c pro = new EBH_Project__c(Name='Project 1', Site__c = 'AU',LeadSegment__c = 'SMB');  //  03.07.2023/ Sophal Noch / US-0013131
        insert pro;
        
        RecordType recTemplateAcq = ApexUtil.getRecordTypeByName('Action_Template__c',RECTYPE_ACTION_TEMPLATE_ACQ);
        RecordType recAction = ApexUtil.getRecordTypeByName('Action__c',RECTYPE_ACTION_TEMPLATE_ACQ);
        
        Action_Template__c tm1 = new Action_Template__c(Name='Temp1',RecordTypeId=recTemplateAcq.Id,Required__c=true,Active__c=true,Country__c = 'AU',Lead_Segment__c = 'SMB');  //  03.07.2023/ Sophal Noch / US-0013131
        Action_Template__c tm2 = new Action_Template__c(Name='Temp2',RecordTypeId=recTemplateAcq.Id,Required__c=false,Active__c=true,Country__c = 'AU',Lead_Segment__c = 'SMB');  //  03.07.2023/ Sophal Noch / US-0013131
        insert new Action_Template__c[]{tm1,tm2};
        
        insert new Action__c(Name =tm1.Name, Project__c = pro.Id, Action_Template__c = tm1.Id, RecordTypeId= ApexUtil.getRecordTypeByName('Action__c',RECTYPE_ACTION_TEMPLATE_ACQ).Id);  //  03.07.2023/ Sophal Noch / US-0013131
        
        Test.startTest();
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<EBH_Project__c>{pro});
            stdSetController.setSelected(new List<EBH_Project__c>{pro});
            ActionCreationController controller = new ActionCreationController(stdSetController);
            List<String> recordTypeNames = ActionCreationController.getPro(new List<String>{pro.Id});
            Map<String,Object> mapResult = ActionCreationController.apexInitActionTemplateList(new List<String>{pro.Id},new List<String>{'EUOnboarding'}); //  03.07.2023/ Sophal Noch / US-0013131
        	System.assertEquals(1,((List<Object>)mapResult.get('listSelectedAction')).size(),'1 templates mandatory');
        	System.assertEquals(1,((List<Object>)mapResult.get('listPossibleActions')).size(),'1 templates not mandatory');
        Test.stopTest();
        //Action__c
        
    }
    
    static testMethod void testApexSaveActions() {
        Lead oLead = [SELECT Site__c, Company FROM Lead WHERE LastName = 'AMT Lead tst 01'];
        oLead.Status = 'Qualified';
		update oLead;

        RecordType recSeller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account acc = new Account(Name='Seller1',RecordTypeId=recSeller.Id);
        insert acc;

        EBH_Project__c pro = [SELECT Name, EBH_Seller__c, RecordTypeId, LegalEntity__c FROM EBH_Project__c WHERE Lead__c =: oLead.Id][0];
        
        RecordType recTemplateAcq = ApexUtil.getRecordTypeByName('Action_Template__c',RECTYPE_ACTION_TEMPLATE_ACQ);
        RecordType recAction = ApexUtil.getRecordTypeByName('Action__c',RECTYPE_ACTION_TEMPLATE_ACQ);
        
        Action_Template__c tm1 = new Action_Template__c(Name='Temp1',RecordTypeId=recTemplateAcq.Id,Required__c=true,Active__c=true, Country__c = 'AU',Lead_Segment__c = 'SMB');  //  03.07.2023/ Sophal Noch / US-0013131
        Action_Template__c tm2 = new Action_Template__c(Name='Temp2',RecordTypeId=recTemplateAcq.Id,Required__c=false,Active__c=true, Country__c = 'AU',Lead_Segment__c = 'SMB');  //  03.07.2023/ Sophal Noch / US-0013131
        insert new Action_Template__c[]{tm1,tm2};
        
        Test.startTest();
        	// Map<String,Object> mapResult = ActionCreationController.apexSaveActions(pro.Id,new List<String>{tm2.Id});
        	Map<String,Object> mapResult = ActionCreationController.apexSaveActions(new List<String>{pro.Id},new List<String>{tm2.Id}); //  03.07.2023/ Sophal Noch / US-0013131
            System.assertEquals('ok',mapResult.get('status')+'','saving complete');
        	Action__c[] listActionResult =  [Select Id,Name,Managed_Seller__c From Action__c Where Project__c =:pro.Id];
        	System.assertEquals(1,listActionResult.size(),'1 action created');
        	
            System.assertEquals(pro.EBH_Seller__c, listActionResult[0].Managed_Seller__c,'Manage Seller should populate from Project');
            
        	// mapResult = ActionCreationController.apexInitActionTemplateList(pro.Id,'EUOnboarding');
            mapResult = ActionCreationController.apexInitActionTemplateList(new List<String>{pro.Id},new List<String>{'EUOnboarding'}); //  03.07.2023/ Sophal Noch / US-0013131
        	
        Test.stopTest();
        
    }
    /***************************************START TEST METHOD FOR PROCESS BUILDER***************************************************/
    
    /**PROCESS BUILDER NAME: Action Process
       Loumang: US-0009227 : 15-03-2021 
       
	*/
    @isTest
    public static void test_Process_autoPopulateCompletedDate() {
        
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType rec_bob_ltcc = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
        RecordType rec_bs_lttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        RecordType rec_at_lttm = ApexUtil.getRecordTypeByName('Action_Template__c','LTTM');

        Account acc = new Account(Name='Seller1',RecordTypeId=recSeller.Id);
        insert acc;

        BoB__c bob = new BoB__c(RecordTypeId = rec_bob_ltcc.Id ,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='DE',EBH_BOBVertical__c='Fashion', Managed_Type__c='LTTM Managed');
        insert bob;

        BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId=rec_bs_lttm.Id,Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=acc.Id,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,Seller__c=acc.Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        insert bs;

        Action_Template__c template1 = new Action_Template__c(Name='Tempalte1',RecordTypeId=rec_at_lttm.Id,Country__c='DE',Active__c=true);
        insert template1;

        Action_Template__c template2 = new Action_Template__c(Name='Tempalte2',RecordTypeId=rec_at_lttm.Id,Country__c='DE',Parent_Action__c=template1.Id,Active__c=true);
        insert template2;

        Action__c action1 = new Action__c(Name='Action1',Completed_Date__c = null,Action_Template__c=template2.Id,LTTM_Seller__c=bs.Id);
        insert action1;
        
        action1.Status__c='Completed';
        Test.startTest();
            update action1;
        Test.stopTest();

    }

    /***************************************END TEST METHOD FOR PROCESS BUILDER***************************************************/
    
    
}