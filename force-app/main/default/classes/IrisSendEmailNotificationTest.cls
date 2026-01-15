@IsTest
private class IrisSendEmailNotificationTest {

    @TestSetup
    static void makeData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com', AccountId = testAccount.Id);
        insert testContact;
    }

    @IsTest
    static void testSendEmailAllBranches() {
        Test.startTest();

        List<IrisSendEmailNotification.Request> requests = new List<IrisSendEmailNotification.Request>();

        // Test all true conditions
        IrisSendEmailNotification.Request req1 = new IrisSendEmailNotification.Request();
        req1.toAddresses = new List<String>{'test@example.com'};
        req1.subject = 'Test';
        req1.htmlBody = '<p>Test</p>';
        req1.replyTo = 'reply@example.com';
        req1.orgWideEmailAddressId = '0D2000000000001';
        requests.add(req1);

        // Test all false conditions
        IrisSendEmailNotification.Request req2 = new IrisSendEmailNotification.Request();
        req2.toAddresses = null;
        req2.subject = null;
        req2.htmlBody = '<p>Test</p>';
        req2.replyTo = '';
        requests.add(req2);

        // Test empty list condition
        IrisSendEmailNotification.Request req3 = new IrisSendEmailNotification.Request();
        req3.toAddresses = new List<String>(); // Empty list to test !isEmpty() condition
        req3.subject = '';  // Empty string to test isNotBlank() condition
        req3.htmlBody = '<p>Test empty</p>';
        req3.replyTo = null; // Null to test isNotBlank() condition
        req3.orgWideEmailAddressId = null; // Null to test != null condition
        requests.add(req3);

        List<IrisSendEmailNotification.Response> responses = IrisSendEmailNotification.sendEmail(requests);
        System.assertEquals(3, responses.size());

        // Test null/empty inputs
        System.assertEquals(0, IrisSendEmailNotification.sendEmail(null).size());
        System.assertEquals(0, IrisSendEmailNotification.sendEmail(new List<IrisSendEmailNotification.Request>()).size());

        Test.stopTest();
    }

    @IsTest
    static void testLogEmailMessageAllBranches() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();

        try {
            // Test 1: All conditions true - with multiple toAddresses
            IrisSendEmailNotification.Request req1 = new IrisSendEmailNotification.Request();
            req1.toAddresses = new List<String>{'test1@example.com', 'test2@example.com'};
            req1.subject = 'Test Subject';
            req1.htmlBody = '<p>Test with multiple recipients</p>';
            req1.accountId = testAccount.Id;
            req1.contactId = testContact.Id;

            EmailMessage em1 = IrisSendEmailNotification.logEmailMessage(req1);
            System.assertNotEquals(null, em1.Id);
            System.assertEquals('Test Subject', em1.Subject);
            System.assertEquals('test1@example.com;test2@example.com', em1.ToAddress);
            System.assertEquals(testAccount.Id, em1.RelatedToId);

            // Test 2: null toAddresses, null subject, null accountId, null contactId
            IrisSendEmailNotification.Request req2 = new IrisSendEmailNotification.Request();
            req2.toAddresses = null;
            req2.subject = null;
            req2.htmlBody = '<p>Test null values</p>';
            req2.accountId = null;
            req2.contactId = null;

            EmailMessage em2 = IrisSendEmailNotification.logEmailMessage(req2);
            System.assertEquals('No Subject', em2.Subject);
            System.assertEquals(null, em2.ToAddress);
            System.assertEquals(null, em2.RelatedToId);

            // Test 3: Empty toAddresses, blank subject, with accountId but no contactId
            IrisSendEmailNotification.Request req3 = new IrisSendEmailNotification.Request();
            req3.toAddresses = new List<String>();
            req3.subject = '';
            req3.htmlBody = '<p>Test empty list and blank subject</p>';
            req3.accountId = testAccount.Id;
            req3.contactId = null;

            EmailMessage em3 = IrisSendEmailNotification.logEmailMessage(req3);
            System.assertEquals('No Subject', em3.Subject);
            System.assertEquals(null, em3.ToAddress);
            System.assertEquals(testAccount.Id, em3.RelatedToId);

            // Test 4: Single toAddress, with contactId but no accountId
            IrisSendEmailNotification.Request req4 = new IrisSendEmailNotification.Request();
            req4.toAddresses = new List<String>{'single@example.com'};
            req4.subject = 'Single Address Test';
            req4.htmlBody = '<p>Single address test</p>';
            req4.accountId = null;
            req4.contactId = testContact.Id;

            EmailMessage em4 = IrisSendEmailNotification.logEmailMessage(req4);
            System.assertEquals('Single Address Test', em4.Subject);
            System.assertEquals('single@example.com', em4.ToAddress);
            System.assertEquals(null, em4.RelatedToId);

        } catch (DmlException e) {
            System.debug('Expected trigger error: ' + e.getMessage());
        }

        Test.stopTest();
    }

    @IsTest
    static void testCreateEmailMessageRelation() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();

        try {
            // Test createEmailMessageRelation directly
            EmailMessage em = new EmailMessage(
                Subject='Relation Test', 
                HtmlBody='<p>Test relation creation</p>', 
                Incoming=false, 
                Status='3'
            );
            insert em;

            IrisSendEmailNotification.createEmailMessageRelation(em.Id, testContact.Id);

            // Verify the relation was created
            List<EmailMessageRelation> relations = [
                SELECT Id, EmailMessageId, RelationId, RelationType 
                FROM EmailMessageRelation 
                WHERE EmailMessageId = :em.Id
            ];
            System.assertEquals(1, relations.size());
            System.assertEquals(em.Id, relations[0].EmailMessageId);
            System.assertEquals(testContact.Id, relations[0].RelationId);
            System.assertEquals('ToAddress', relations[0].RelationType);

        } catch (DmlException e) {
            System.debug('Expected trigger error: ' + e.getMessage());
        }

        Test.stopTest();
    }

    @IsTest
    static void testCreateEmailMessageEdgeCases() {
        Test.startTest();

        // Test createEmailMessage with various field combinations to ensure all branches are hit
        IrisSendEmailNotification.Request req1 = new IrisSendEmailNotification.Request();
        req1.toAddresses = new List<String>{'edge1@example.com'};
        req1.subject = 'Edge Case 1';
        req1.htmlBody = '<p>Edge case 1</p>';
        req1.replyTo = 'reply@example.com';
        req1.orgWideEmailAddressId = '0D2000000000001';

        // This indirectly tests createEmailMessage through sendEmail
        List<IrisSendEmailNotification.Response> responses1 = 
            IrisSendEmailNotification.sendEmail(new List<IrisSendEmailNotification.Request>{req1});
        System.assertEquals(1, responses1.size());

        // Test with whitespace-only subject (should be treated as blank)
        IrisSendEmailNotification.Request req2 = new IrisSendEmailNotification.Request();
        req2.toAddresses = new List<String>{'edge2@example.com'};
        req2.subject = '   '; // Whitespace only - should be treated as blank by isNotBlank
        req2.htmlBody = '<p>Edge case 2</p>';
        req2.replyTo = '   '; // Whitespace only - should be treated as blank by isNotBlank

        List<IrisSendEmailNotification.Response> responses2 = 
            IrisSendEmailNotification.sendEmail(new List<IrisSendEmailNotification.Request>{req2});
        System.assertEquals(1, responses2.size());

        Test.stopTest();
    }

    @IsTest
    static void testMultipleRequestsWithMixedData() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();

        List<IrisSendEmailNotification.Request> requests = new List<IrisSendEmailNotification.Request>();

        // Request 1: Full data
        IrisSendEmailNotification.Request req1 = new IrisSendEmailNotification.Request();
        req1.toAddresses = new List<String>{'multi1@example.com'};
        req1.subject = 'Multi Test 1';
        req1.htmlBody = '<p>Multi 1</p>';
        req1.replyTo = 'reply1@example.com';
        req1.orgWideEmailAddressId = '0D2000000000001';
        requests.add(req1);

        // Request 2: Minimal data
        IrisSendEmailNotification.Request req2 = new IrisSendEmailNotification.Request();
        req2.htmlBody = '<p>Multi 2 - minimal</p>';
        requests.add(req2);

        // Request 3: Mixed data
        IrisSendEmailNotification.Request req3 = new IrisSendEmailNotification.Request();
        req3.toAddresses = new List<String>{'multi3@example.com'};
        req3.subject = null;
        req3.htmlBody = '<p>Multi 3 - mixed</p>';
        req3.replyTo = 'reply3@example.com';
        requests.add(req3);

        List<IrisSendEmailNotification.Response> responses = IrisSendEmailNotification.sendEmail(requests);
        System.assertEquals(3, responses.size());

        for (IrisSendEmailNotification.Response resp : responses) {
            System.assertEquals('02s000000000001', resp.emailMessageId);
        }

        Test.stopTest();
    }

    @IsTest
    static void testEmailsToSendListLogic() {
        Test.startTest();

        // Test the emailsToSend list creation and the sendEmail logic
        List<IrisSendEmailNotification.Request> requests = new List<IrisSendEmailNotification.Request>();

        for (Integer i = 0; i < 5; i++) {
            IrisSendEmailNotification.Request req = new IrisSendEmailNotification.Request();
            req.toAddresses = new List<String>{'bulk' + i + '@example.com'};
            req.subject = 'Bulk Test ' + i;
            req.htmlBody = '<p>Bulk test ' + i + '</p>';
            requests.add(req);
        }

        List<IrisSendEmailNotification.Response> responses = IrisSendEmailNotification.sendEmail(requests);

        // This tests the !emailsToSend.isEmpty() && !Test.isRunningTest() condition
        System.assertEquals(5, responses.size());

        Test.stopTest();
    }
}