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
private class LeadTriggerHandlerTest {
	private static Id projAUSMB_RT = ApexUtil.getRecordTypeByName('EBH_Project__c', 'eBayAUSMB').Id;
	private static Id projEU_RT = ApexUtil.getRecordTypeByName('EBH_Project__c', 'EUOnboarding').Id;
	private static void setup(){
		EBH_TestDataFactory.setUpCustomSettings(); 
		ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;

		Account accPartner1 = new Account();
		accPartner1.Name = 'accPartner1';
		accPartner1.RecordTypeId = ApexUtil.getRecordTypeByName('Account', 'EBH_Partner').Id;
		accPartner1.EBH_PartnerType__c = 'Shop System';
		insert accPartner1;

		List<Account> legalEntt =  EBH_TestDataFactory.createAccounts(1, 'EBH_LegalEntity') ;
    	legalEntt[0].Name = 'LegalEntity Test';
    	update legalEntt;

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

		Lead oneL2 = EBH_TestDataFactory.createLeads();
		oneL2.RecordTypeId = ApexUtil.getRecordTypeByName('Lead', 'EBH_eBayAUSMB').Id;
		oneL2.EBH_eBayID__c = 'biggest_sellert_test';
		oneL2.Site__c = 'AU';
		oneL2.LeadSource = 'Self Gen';
		oneL2.LeadSegment__c = 'SMB';
		oneL2.OtherLeadSource__c = 'other leadsource tst';
		oneL2.LastName = 'AMT Lead tst 02';
		oneL2.Phone = '012 345 5674';
		oneL2.Website = 'www.test.com.test1';
		oneL2.Email = 'test@tes.com.invalid1';
		oneL2.Shopping_Card__c = accPartner1.Id;
		oneL2.EBH_Vertical__c = 'Collectibles';
		oneL2.VAT_Number__c = '1231231231231223312';
		oneL2.isapproved__c = true;
		oneL2.Company = 'LegalEntity Test'; //Make it same as cc
		insert oneL2;

		Lead oneL3 = EBH_TestDataFactory.createLeads();
		oneL3.RecordTypeId = ApexUtil.getRecordTypeByName('Lead', 'EBH_eBayAUSMB').Id;
		oneL3.EBH_eBayID__c = 'biggest_sellert_test';
		oneL3.Site__c = 'DE'; //EU
		oneL3.LeadSource = 'Self Gen';
		oneL3.LeadSegment__c = 'SMB';
		oneL3.OtherLeadSource__c = 'other leadsource tst';
		oneL3.LastName = 'AMT Lead tst 03';
		oneL3.Phone = '012 345 5674';
		oneL3.Website = 'www.test.com.test1';
		oneL3.Email = 'test@tes.com.invalid3';
		oneL3.Shopping_Card__c = accPartner1.Id;
		oneL3.EBH_Vertical__c = 'Collectibles';
		oneL3.VAT_Number__c = '12312312444444';
		oneL3.isapproved__c = true;
		oneL3.Company = 'LegalEntity Test3';
		oneL3.LegalEntity__c = legalEntt.get(0).Id;
		insert oneL3;

		// AU Task
		Task oneT = new Task();
		oneT.RecordTypeId = ApexUtil.getRecordTypeByName('Task', EBH_ConstantsUtility.TASK_AU_RT).Id;
		oneT.WhoId = oneL.Id;
		insert oneT;

		// Nomal Task
		Task oneT2 = new Task();
		oneT2.WhoId = oneL.Id;
		insert oneT2;
		
		// Campaign
		Campaign cmp1 = new Campaign();
		cmp1.RecordTypeId = EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID;
		cmp1.Name = 'TST Campaign 001';
		cmp1.StartDate = Date.today();
		cmp1.EndDate = Date.today().addDays(7);

		Campaign cmp2 = new Campaign();
		cmp2.RecordTypeId = EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID;
		cmp2.Name = 'TST Campaign 002';
		cmp2.StartDate = Date.today();
		cmp2.EndDate = Date.today().addDays(7);

		insert new List<Campaign>{cmp1, cmp2};

		//CampaignMember
		CampaignMember cpmMember1 = new CampaignMember(
			CampaignId = cmp1.Id, 
			LeadId = oneL.Id, 
			EBH_Results__c = 'Sent', 
			EBH_ResponseCode__c = 20, //EBH_HasResponded__c = hasResponded,
			EBH_LastResponseDate__c = system.today()
		);

		CampaignMember cpmMember2 = new CampaignMember(
			CampaignId = cmp2.Id, 
			LeadId = oneL.Id, 
			EBH_Results__c = 'Sent', 
			EBH_ResponseCode__c = 20, 
			EBH_LastResponseDate__c = system.today()
		);
		
		insert new List<CampaignMember>{cpmMember1, cpmMember2};
	}

	// Methos is no longer used
    // static testMethod void testRemoveLeadGDPR() {
    // 	setup();
    	
	// 	Lead l = EBH_TestDataFactory.createLeads();
	// 	l.VAT_Number__c = '123123123123120';
	// 	l.LastName = 'AMT Lead tst 03';
	// 	l.Phone = '012 345 56745';
	// 	l.Website = 'www.test.com.test2';
	// 	l.Email = 'test@tes.com.invalid2';
	// 	l.EBH_eBayID__c = 'biggest_sellert_test';
	// 	l.Company = 'test3company';
    // 	insert l;
    	
    // 	List<Account> sellers =  EBH_TestDataFactory.createAccounts(1, 'EBH_LegalEntity') ;
    // 	sellers[0].Name = 'biggest_sellert_test';
    // 	update sellers;
    	
        
    //     Test.startTest();
    //     	List<Contact> contacts =  EBH_TestDataFactory.createContacts(1, 'Test Contact', sellers[0].id);
	//     	contacts[0].Email = 'testxyz@test.com';
	//     	contacts[0].EBH_GDPRRemoved__c = true;
	//     	contacts[0].EBH_Status__c = 'Active';
	//     	update contacts;
    //     Test.stopTest();
        
    //     	Lead l_select = [SElect Id,Email,GDPR_Removed__c,Website From Lead where Id =:l.Id];
    //     	System.assertEquals('deleted@deleted.com',l_select.Email,'field replaced with deleted');
    //     	System.assertEquals('deleted',l_select.Website,'field replaced with deleted');
    //     	System.assertEquals(true,l_select.GDPR_Removed__c,'field marked as GDPR deleted');
        	
        	
        
        
    // }
	static testMethod void testvalidateAUSMBLead() {
		setup();
    	RecordType recTypeAuSMBLead = ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUSMB');
    	Lead l = EBH_TestDataFactory.createLeads();
    	l.LeadSource = EBH_ConstantsUtility.LEAD_SOURCE_SELF_GEN;
    	l.RecordTypeId = recTypeAuSMBLead.Id;
    	l.isapproved__c = false;
    	l.Site__c = 'AU';
    	l.LeadSegment__c = 'SMB';
    	insert l;
    	Test.startTest();
    	try{
    		l.Status = EBH_ConstantsUtility.LEAD_STATUS_QUALIFIED;
    		update l;
    	}catch(Exception e){
    		System.AssertEquals(e.getMessage().contains(System.label.eBayAuSBM_Err_2), true);
    	}
    	Test.stopTest();
    	System.Assert([select Status from Lead where id =: l.Id].Status != EBH_ConstantsUtility.LEAD_STATUS_QUALIFIED,'Record is not updated, error :'+System.label.eBayAuSBM_Err_2);
	}
	
	@isTest
	private static void leadOnboardingProcessTest(){
		setup();
		Lead oneL = [SELECT Site__c, Company FROM Lead WHERE LastName = 'AMT Lead tst 01'];
		oneL.Status = 'Qualified';
		update oneL;
		Test.startTest();
			List<EBH_Project__c> lstProj = [SELECT Name, RecordTypeId, LegalEntity__c FROM EBH_Project__c WHERE Lead__c =: oneL.Id];
			System.assert(lstProj.size() == 1);
			System.assert(lstProj.get(0).LegalEntity__c != null);
			System.assert('Onboarding '+ oneL.Site__c + ' ' + oneL.Company == lstProj.get(0).Name);
			System.assert(lstProj.get(0).RecordTypeId == projAUSMB_RT);
			List<Contact> lstCont = [SELECT Id FROM Contact WHERE AccountId =: lstProj.get(0).LegalEntity__c];
			System.assert(lstCont.size() == 1);

			List<Task> lstTask = [SELECT Id FROM Task WHERE WhatId =: lstProj.get(0).Id];
			System.assertEquals(lstTask.size(), 2);
		Test.stopTest();
	}

	@isTest
	private static void leadOnboardingProcessTest2(){
		setup();
		Lead oneL = [SELECT Site__c, Company FROM Lead WHERE LastName = 'AMT Lead tst 02'];
		
		Test.startTest();
			try {
				oneL.Status = 'Qualified';
				update oneL;
			} catch (Exception ex) {
				System.assert(ex.getMessage().contains(Label.LeadAccount_Duplicate_ErrorMsg));
			}
		Test.stopTest();
	}

	@isTest
	private static void leadOnboardingProcessTest3(){
		setup();
		Lead oneL = [SELECT Site__c, Company FROM Lead WHERE LastName = 'AMT Lead tst 03'];
		oneL.Status = 'Qualified';
		update oneL;
		Test.startTest();
			List<EBH_Project__c> lstProj = [SELECT Name, RecordTypeId, LegalEntity__c FROM EBH_Project__c WHERE Lead__c =: oneL.Id];
			System.assert(lstProj.size() == 1);
			System.assert(lstProj.get(0).LegalEntity__c != null);
			System.assert('Onboarding '+ oneL.Site__c + ' ' + oneL.Company == lstProj.get(0).Name);
			System.assert(lstProj.get(0).RecordTypeId == projEU_RT);
		Test.stopTest();
	}

	@isTest
	private static void leadOnboardingProcessTest4(){
		//Create User
		setup();
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		User standardUser;
		System.runAs(admin){
			//NK:30/10/2025:US-0033819
			UserRole roleParter =  [SELECT Id,DeveloperName from UserRole  where DeveloperName ='Global' LIMIT 1];
			Profile p = [select id from Profile where name='Standard User Profile' limit 1];
            standardUser = new User(alias = 'olitUser', email='testleadconvertion@test.com',UserRoleId = roleParter.Id,
                            emailencodingkey='UTF-8', lastname='Test Standard User', firstname='TestStandardUser', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id,
                            timezonesidkey='America/Los_Angeles', username='testleadconvertion@test.com', isActive = true);
            insert standardUser;

            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Lead_New_Seller_Registration_Manager' LIMIT 1];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = standardUser.Id,
                PermissionSetId = ps.Id
            );
            insert psa;

		}
		System.runAs(standardUser){
			Account accPartner1 = [SELECT Id,Name FROM Account WHERE Name = 'accPartner1'];
			List<Account> legalEntt =  EBH_TestDataFactory.createAccounts(1, 'EBH_LegalEntity') ;
			Lead myLead = EBH_TestDataFactory.createLeads();
			myLead.RecordTypeId = ApexUtil.getRecordTypeByName('Lead', 'EBH_eBayAUSMB').Id;
			myLead.EBH_eBayID__c = 'biggest_sellert_test';
			myLead.Site__c = 'DE'; //EU
			myLead.LeadSource = 'Self Gen';
			myLead.LeadSegment__c = 'SMB';
			myLead.OtherLeadSource__c = 'other leadsource tst';
			myLead.LastName = 'AMT Lead tst 04';
			myLead.Phone = '012 345 5674';
			myLead.Website = 'www.test.com.test1';
			myLead.Email = 'test@tes.com.invalid3';
			myLead.Shopping_Card__c = accPartner1.Id;
			myLead.EBH_Vertical__c = 'Collectibles';
			myLead.VAT_Number__c = '12312312444444';
			myLead.isapproved__c = true;
			myLead.Company = 'LegalEntity tst Test3';
			myLead.LegalEntity__c = legalEntt.get(0).Id;
			Test.startTest();
				try {
					insert myLead;
				} catch (Exception ex) {
					System.assert(ex.getMessage().contains('DUPLICATES_DETECTED'));
				}
			Test.stopTest();
		}
	}

	/*********************************************************************************************************************************
    @ method:         testProcessBDLeadConversion
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / create the method
    *********************************************************************************************************************************/
    @isTest
	private static void testProcessBDLeadConversion(){

		EBH_TestDataFactory.setUpCustomSettings(); 

		List<Account> listLegalEntity =  EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity') ;
    	listLegalEntity[0].Name = 'ebdev LegalEntity Test 0';
		listLegalEntity[1].Name = 'ebdev LegalEntity Test 1';
		ApexSafe.dml().secCheck(false).doUpdate(listLegalEntity, true);

		List<Account> listSeller =  EBH_TestDataFactory.createAccounts(1, 'EBH_Seller') ;

		Id rtContManualId =  ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL')?.Id;
		Contact cont = new Contact(
			LastName = 'LegalEntity Test Contact 1',
			Email = 'snoch@ebay.com.invalid',
			AccountId = listLegalEntity[0].Id
		);
		ApexSafe.dml().secCheck(false).doInsert(new List<Contact>{cont}, true);

		Lead lead = EBH_TestDataFactory.createLeads();
		lead.RecordTypeId = ApexUtil.getRecordTypeByName('Lead', 'eBay_Business_Development').Id;
		lead.Site__c = 'DE';
		lead.LastName = 'LegalEntity Test Contact 1';
		lead.Phone = '070';
		lead.Website = 'ebay.com';
		lead.Email = 'snoch@ebay.com.invalid';
		lead.Company = 'LegalEntity Test';
		ApexSafe.dml().secCheck(false).doInsert(new List<Lead>{lead}, true);

		Test.startTest();
			List<Lead> listLeadWithAllFields = ApexSafe.query().doQuery(('Select ' + ApexUtil.generateSQOLFields('Lead') + ' From Lead Where Id =: leadId limit 1'), new Map<String, Object> {'leadId' => lead.Id});
			lead = listLeadWithAllFields[0];

			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(lead.id);
			lc.setAccountId(listLegalEntity[1].Id);
			lc.setContactId(cont.Id);
			lc.setDoNotCreateOpportunity(false);
			lc.setConvertedStatus('Converted');
			Database.LeadConvertResult lcr = Database.convertLead(lc, false);
		
			System.assertNotEquals(null, lcr.getErrors().isEmpty() ? null : lcr.getErrors()[0] , 'Should have Error Message');

			Opportunity bdOpp = new Opportunity(
				Name = 'Test Opp',
				RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity', 'eBay_Business_Development').Id,
				StageName = 'Discovery',
				CloseDate = Date.today(),
				IsConverted__c = true
			);
			ApexSafe.dml().secCheck(false).doInsert(new List<Opportunity>{bdOpp}, true);

			// lead.eBayID__c = listSeller[0].Id;
			lead.Title = 'Test Title';
			update lead;

			lc = new Database.LeadConvert();
			lc.setLeadId(lead.id);
			lc.setAccountId(listLegalEntity[0].Id);
			lc.setContactId(cont.Id);
			lc.setOpportunityId(bdOpp.Id);
			lc.setConvertedStatus('Converted');
			lcr = Database.convertLead(lc, true);

			// System.assertEquals(null, lcr.getErrors().isEmpty() ? null : lcr.getErrors()[0] , 'Should be successfully converted');

			List<Contact> listContact =  ApexSafe.query().secCheck(false).doQuery(('Select Id, Title From Contact Where Id =: contId'), new Map<String, Object> {'contId' => cont.Id});
			System.assertEquals(lead.Title, listContact[0].Title, 'Contact.Title Updated with Lead.Title');
			
		Test.stopTest();
    }
	
	@isTest
	private static void testAutoLinkSeller(){
		EBH_TestDataFactory.setUpCustomSettings();
		List<Account> listSeller =  EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
		listSeller[0].Name = 'TEST Seller AMT 01';
    	listSeller[0].EBH_OracleId__c = '111222333';

		listSeller[1].Name = 'TEST Seller AMT 02';
    	listSeller[1].EBH_OracleId__c = '444555666';
		update listSeller;

		Lead oLeadTest = new Lead();
		oLeadTest.RecordTypeId = LeadTriggerHandler.RT_LEAD_EBDEV_ID;
		oLeadTest.eBayID__c = listSeller[0].Id;
		oLeadTest.LastName = 'AMT Last Lead';
		oLeadTest.Company = 'AMT Company';
		insert oLeadTest;

		Test.startTest();
			Lead oLead = [SELECT Name, eBayID__c, EBH_OracleID__c, EBH_eBayID__c FROM Lead WHERE Id=:oLeadTest.Id];
			System.assertEquals(oLead.EBH_OracleID__c, listSeller[0].EBH_OracleId__c, ' OracleId should be inherited from Seller');
			System.assertEquals(oLead.EBH_eBayID__c, listSeller[0].Name, ' SellerName should be inherited from Seller');
			
			oLead.eBayID__c = null;
			oLead.EBH_OracleID__c = '444555666';
			update oLead;
			oLead = [SELECT Name, eBayID__c, EBH_OracleID__c, EBH_eBayID__c FROM Lead WHERE Id=:oLeadTest.Id];
			System.assertEquals(oLead.eBayID__c, listSeller[1].Id, ' Seller should be == Seller of that oracleId');
			System.assertEquals(oLead.EBH_eBayID__c, listSeller[1].Name, ' SellerName should be inherited from Seller');
		Test.stopTest();
	}

	@isTest
	private static void testRemoveGDPRContacts()
    {
    	EBH_TestDataFactory.setUpCustomSettings();

		List<Account> lstAcc = EBH_TestDataFactory.createAccounts(2,'EBH_Seller');
		Set<String> setAccountIds = new Set<String>();
    	Set<String> setEmails = new Set<String>();

		for(Account acc : lstAcc)
		{
			setAccountIds.add(acc.Id);
		}

    	Test.startTest();
			LeadTriggerHandler.removeLeadGDPR(setAccountIds, new Set<String> {'test@test.com'});
		Test.stopTest();
    }

}