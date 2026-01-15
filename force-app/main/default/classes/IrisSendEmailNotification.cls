/*********************************************************************************************************************************
@ Class:          IrisSendEmailNotification
@ Version:        1.0
@ Author:         Sambath Seng
@ Purpose:        Invocable class to send email and log EmailMessage record
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.09.2025 / Sambath Seng / US-0033129 Create the class
*********************************************************************************************************************************/
public with sharing class IrisSendEmailNotification {

    private static final string EMAIL_NO_SUBJECT = 'No Subject';
    private static final string EMAIL_MESSAGE_MOCK_ID = '02s000000000001';

    // Request class to pass inputs from Flow
    public class Request {
        @InvocableVariable(label='Recipient Email Addresses' description='List of recipient email addresses')
        public List<String> toAddresses;

        @InvocableVariable(label='Email Subject' description='Subject line of the email')
        public String subject;

        @InvocableVariable(label='HTML Body' description='HTML content of the email body')
        public String htmlBody;

        @InvocableVariable(label='Reply-To Address' description='Reply-to email address')
        public String replyTo;

        @InvocableVariable(label='Account ID' description='Account ID to associate the email with (RelatedToId)')
        public Id accountId;

        @InvocableVariable(label='Org-Wide Email Address ID' description='Org-Wide Email Address ID (prefix 0D2)')
        public Id orgWideEmailAddressId;

        @InvocableVariable(label='Contact ID' description='Contact ID to create email relation')
        public Id contactId;
    }

    public class Response {
        @InvocableVariable(label='Email Message ID' description='ID of the created EmailMessage record')
        public Id emailMessageId;
    }

    /*********************************************************************************************************************************
    @ Method:       sendEmail
    @ Author:       Sambath Seng
    @ Purpose:      Main invocable method to send email notifications and create EmailMessage records
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.09.2025 / Sambath Seng / US-0033129 Create the method
    *********************************************************************************************************************************/
    @InvocableMethod(label='IRIS - Send Email Notification' description='Send email and log EmailMessage')
    public static List<Response> sendEmail(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Request req : requests) {
            // Create email message
            Messaging.SingleEmailMessage mail = createEmailMessage(req);
            emailsToSend.add(mail);

            // Create response with EmailMessage ID
            Response resp = new Response();
            
            if (!Test.isRunningTest()) {
                EmailMessage em = logEmailMessage(req);
                resp.emailMessageId = em.Id;
            } else {
                resp.emailMessageId = EMAIL_MESSAGE_MOCK_ID; // Mock ID for testing
            }
            
            responses.add(resp);
        }

        // Send all emails
        if (!emailsToSend.isEmpty() && !Test.isRunningTest()) {
            Messaging.sendEmail(emailsToSend, false);
        }

        return responses;
    }

    /*********************************************************************************************************************************
    @ Method:       createEmailMessage
    @ Author:       Sambath Seng
    @ Purpose:      Creates and configures a Messaging.SingleEmailMessage object from the request parameters.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.09.2025 / Sambath Seng / US-0033129 Create the method
    *********************************************************************************************************************************/
    private static Messaging.SingleEmailMessage createEmailMessage(Request req) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Set recipients
        if (req.toAddresses != null && !req.toAddresses.isEmpty()) {
            mail.setToAddresses(req.toAddresses);
        }

        // Set subject (with default)
        mail.setSubject(String.isNotBlank(req.subject) ? req.subject : EMAIL_NO_SUBJECT);

        // Set HTML body
        mail.setHtmlBody(req.htmlBody);

        // Set reply-to if provided
        if (String.isNotBlank(req.replyTo)) {
            mail.setReplyTo(req.replyTo);
        }

        // Set org-wide email address if provided
        if (req.orgWideEmailAddressId != null) {
            mail.setOrgWideEmailAddressId(req.orgWideEmailAddressId);
        }

        // Disable automatic activity logging (we handle it manually)
        mail.setSaveAsActivity(false);

        return mail;
    }

    /*********************************************************************************************************************************
    @ Method:       logEmailMessage
    @ Author:       Sambath Seng
    @ Purpose:      Creates and inserts an EmailMessage record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.09.2025 / Sambath Seng / US-0033129 Create the method
    *********************************************************************************************************************************/
    @TestVisible
    private static EmailMessage logEmailMessage(Request req) {
        EmailMessage em = new EmailMessage();
        em.Subject = String.isNotBlank(req.subject) ? req.subject : EMAIL_NO_SUBJECT;
        em.HtmlBody = req.htmlBody;
        em.ToAddress = (req.toAddresses != null && !req.toAddresses.isEmpty()) ? 
                       String.join(req.toAddresses, ';') : null;
        em.Incoming = false;
        em.Status = '3'; // Sent status
        
        if (req.accountId != null) {
            em.RelatedToId = req.accountId;
        }

        ApexSafe.dml().secCheck(false).doInsert(new List<EmailMessage>{em}, true);

        // Create EmailMessageRelation for Contact if provided
        if (req.contactId != null) {
            createEmailMessageRelation(em.Id, req.contactId);
        }

        return em;
    }

    /*********************************************************************************************************************************
    @ Method:       createEmailMessageRelation
    @ Author:       Sambath Seng
    @ Purpose:      Creates EmailMessageRelation records to establish relationships between EmailMessage and Contact records
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.09.2025 / Sambath Seng / US-0033129 Create the method
    *********************************************************************************************************************************/
    @TestVisible
    private static void createEmailMessageRelation(Id emailMessageId, Id contactId) {
        EmailMessageRelation emr = new EmailMessageRelation();
        emr.EmailMessageId = emailMessageId;
        emr.RelationId = contactId;
        emr.RelationType = 'ToAddress';
        ApexSafe.dml().secCheck(false).doInsert(new List<EmailMessageRelation>{emr}, true);
    }

}