/*********************************************************************************************************************************
@ Class:        HandOverButtonControllerTest
@ Version:      1.0
@ Author:       SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:      Coverage HandOverButtonController.cls
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.11.2025 / SRONG TIN (srong.tin@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
@isTest
public class HandOverButtonControllerTest {

	@testSetup
	static void setupTestData(){
		// Create seller and legal entity accounts
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account acc = new Account(
            Name = 'Seller_1',
            EBH_RevRollup__c = 'DE',
            EBH_BillingCountry__c= 'DE',
            EBH_DealsProgram__c='Accepted',
            RecordTypeId = sellerRecordType.Id
        );
        insert acc;
        RecordType legalEntityRecordType = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
		Account legal = new Account(
            Name = 'Legal Entity Test',
            EBH_RevRollup__c = 'DE',
            EBH_BillingCountry__c= 'DE',
            RecordTypeId = legalEntityRecordType.Id
        );
		insert legal;

		// Create contact and link to seller
		Contact c = new Contact(FirstName='Test', LastName='Contact', AccountId = acc.Id, Email='stin@ebay.com', Phone='0123456789');
		insert c;

		// Create an Opportunity with lookups set
		 RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'eBay_Business_Development' LIMIT 1];
         Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Negotiating',
            SKUs__c = 12,
            LegalEntity__c = legal.Id,
            CloseDate = Date.today().addDays(30), //Set a valid close date
            Focus_Vertical__c = 'Home',
            eBay_Platform__c = 'Core',
            //ForecastCategory= 'Pipeline',
            Site__c = 'DE',
            Amount = 10000.00,
            RecordTypeId = recordType.Id
         );
         insert testOpportunity;
	}

    @isTest
	static void testHandoverDoInit(){
		// retrieve an opportunity created in @testSetup
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		Test.startTest();
		Map<String,Object> res = HandOverButtonController.handoverDoInit(opp.Id);
		Test.stopTest();
		System.assertEquals('ok', res.get('status'));
		System.assertNotEquals(null, res.get('data'));
		// returned data should be an Opportunity sObject
		System.assert(((SObject)res.get('data')).get('Id') == opp.Id, 'Returned Opportunity Id should match');
	}

	@isTest
	static void testHandoverDoSubmit(){
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

		// Prepare EBH_Project__c to submit
		EBH_Project__c proj = new EBH_Project__c();
		proj.Name = 'Test Project from Test';
		proj.Opportunity__c = opp.Id;
        List<EBH_Project__c> projList = new List<EBH_Project__c>();
        projList.add(proj);
		Test.startTest();
		Map<String,Object> res = HandOverButtonController.handoverDoSubmit(projList);
		Test.stopTest();
		System.assertEquals('ok', res.get('status'));
		// verify project was created
		List<EBH_Project__c> createdProjects = (List<EBH_Project__c>) res.get('dataProject');
		System.assertNotEquals(null, createdProjects);
		System.assert(createdProjects.size() > 0, 'Expected at least one project created');

		// verify opportunity was updated
		Opportunity updatedOpp = [SELECT Id, Handover__c FROM Opportunity WHERE Id = :opp.Id];
		System.assertEquals('Durchstarter', updatedOpp.Handover__c, 'Opportunity Handover field should be set');
	}

	@isTest
	static void testHandoverDoSubmitNotFound(){
		// Test with null list
		Test.startTest();
		Map<String,Object> res = HandOverButtonController.handoverDoSubmit(null);
		Test.stopTest();
		System.assertEquals('ko', res.get('status'));
		System.assertNotEquals(null, res.get('error'));
	}

	@isTest
	static void testHandoverDoSubmitEmptyList(){
		// Test with empty list
		List<EBH_Project__c> emptyList = new List<EBH_Project__c>();
		Test.startTest();
		Map<String,Object> res = HandOverButtonController.handoverDoSubmit(emptyList);
		Test.stopTest();
		System.assertEquals('ko', res.get('status'));
		System.assertNotEquals(null, res.get('error'));
	}

	@isTest
	static void testHandoverDoInitNull(){
		// Test handoverDoInit with null recordId
		Test.startTest();
		Map<String,Object> res = HandOverButtonController.handoverDoInit(null);
		Test.stopTest();
		// Should return empty result since it checks if(!listOpp.isEmpty())
		System.assertEquals('ko', res.get('status')); // No status set when empty
	}

	@isTest
	static void testHandoverDoInitInvalidId(){
		// Test handoverDoInit with invalid record ID format
		Test.startTest();
		Map<String,Object> res = HandOverButtonController.handoverDoInit('001000000000000');
		Test.stopTest();
		// Should return empty result since opportunity doesn't exist
		System.assertEquals('ko', res.get('status'));
	}

}