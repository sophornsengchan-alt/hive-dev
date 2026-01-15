/*********************************************************************************************************************************
 @ Class:          CustomDeleteContactControllerTest
 @ Version:        1.0
 @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
 @ Purpose:        test logic for CustomDeleteContactController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.09.2023 / Sambath Seng / Created the class.
@               : 22.04.2024/ vadhanak voun/ US-0015092 - Add "Delete contact reason" on "Delete Contact" button.
*********************************************************************************************************************************/
@isTest
private class CustomDeleteContactControllerTest {

    // Define a test setup method to create test data
    @testSetup
    static void setupTestData() {
        EBH_TestDataFactory.setUpCustomSettings();  
        EBH_ActiveTriggers__c csettingTrigger = EBH_ActiveTriggers__c.getInstance(CaseTriggerHandler.TRIGGERCONTROLLER);
        csettingTrigger.CaseTrigger__c = true;
        update csettingTrigger;

        Account seller = new Account (Name='Test Seller');
        insert seller;
        
        RecordType contactManualRT = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        Contact con = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',FirstName='firstname',Salutation='Mr.',LastName='test1',email='test1@test.com' , AccountId = seller.Id, RecordtypeId = ContactManualRT.Id);
        insert con;
    }

    @isTest
    static void testCreateContactRemovalTicketSuccess() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        String caseReason = 'Wrong Data';

        Test.startTest();
        Map<String,Object> result1 = CustomDeleteContactController.checkForValidContact(con.Id);
        Map<String,Object> result2 = CustomDeleteContactController.createContactRemovalTicket(con.Id, caseReason);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result1.get('isValidContact'),'contact is valid');
        System.assertEquals('ok', result2.get('status'), 'Status should be "success"');
    }

    @isTest
    static void testCreateContactRemovalTicketRequestSubmitted() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        String caseReason = 'Wrong Data';

        CustomDeleteContactController.createContactRemovalTicket(con.Id, caseReason);

        Test.startTest();
        Map<String,Object> result = CustomDeleteContactController.checkForValidContact(con.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.get('isValidContact'), 'isValidContact should be "false"');
        System.assert(result.containsKey('message'), 'already been submitted');
    }

    @isTest
    static void testCreateContactRemovalTicketDMLException() {
        // Trigger a DML exception by using an invalid Contact Id
        String contactId = [SELECT Id FROM Account LIMIT 1].Id;
        String caseReason = 'Wrong Data';

        Test.startTest();
        Map<String, Object> result = CustomDeleteContactController.createContactRemovalTicket(contactId, caseReason);
        Test.stopTest();

        // Assert
        System.assertEquals('ko', result.get('status'), 'Status should be "error"');
        System.assert(result.containsKey('message'), 'Error message should be present');
    }

}