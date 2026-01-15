/*********************************************************************************************************************************
@ Class:          RequestSapNumber
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        US-0009234 - Button to verify EU VAT ID & Request SAP ID
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.05.2021 / Mony Nou / Created the class
                  
*********************************************************************************************************************************/
public without sharing class RequestSapNumber {
    
    /**
     * Request SAP Number by sending email
     * Description: US-0009234 - Button to verify EU VAT ID & Request SAP ID
     * @param id, Account Id
      @return Map<String,Object> 
     */
    public static Map<String,Object> SendEmailNotification(String id) {

        Map<String,Object> result = new Map<String,Object>();
        String status = 'ok';
        String errMsg = '';


        try {

            Account account = [SELECT Id, Name, BillingCity, BillingStreet, BillingCountry, BillingPostalCode, VAT_ID__c, SAP_ID__c, Country_Code__c FROM Account WHERE Id = :id];

            //Set to validate with VAT_ID__c
            Set<String> sValidateCountry = new Set<String>{'AT','BE','BG','CY','CZ','DE','DK','EE','GR','ES','FI','FR','GB','HR','HU','IE','IT','LT','LU','LV','MT','NL','PL','PT','RO','SE','SI','SK','SM'};
            
            if (String.isBlank(account.BillingCity) 
                || String.isBlank(account.BillingStreet) 
                || String.isBlank(account.BillingCountry)
                || (String.isBlank(account.VAT_ID__c) && sValidateCountry.contains(account.BillingCountry.toUpperCase()))
                || String.isBlank(account.BillingPostalCode)) {
                
                errMsg = System.Label.Acc_Req_SAP_Email_Error_1;
            }
            
            else if (String.isNotBlank(account.SAP_ID__c)) { errMsg = System.Label.Acc_Req_SAP_Email_Error_2; }
            
            else {

                Map<String, String> mEmailAddress = new Map<String, String>{
                    'DE'        => System.Label.Acc_Req_SAP_Email_for_DE,
                    'AU'        => System.Label.Acc_Req_SAP_Email_for_AU,
                    'DEFAULT'   => System.Label.Acc_Req_SAP_Email_for_DEFAULT
                };
        
                String htmlbody = '<html>\n'
                                            + '<head>\n'
                                            + '<style type="text/css">\n'
                                            + '</style>\n'
                                            + '<h1>New Account SAP ID requested</h1>\n'
                                            + '</head>\n'
                                            + '<body>\n'
                                            + '<h3>Name: '+ account.Name +'</h3>\n'
                                            + '<h3>Street/House number: '+ account.BillingStreet+'</h3>\n'
                                            + '<h3>Postal Code: '+ account.BillingPostalCode+'</h3>\n'
                                            + '<h3>City: '+ account.BillingCity+'</h3>\n'
                                            + '<h3>Country: '+ account.BillingCountry+'</h3>\n'
                                            + '<h3>VAT Number: '+ account.VAT_ID__c+'</h3>\n'
                                            + '<h2>Direct link: https://' + URL.getSalesforceBaseURL().getHost()  + '/' + account.Id+ '</h2>\n'
                                            + '</body>\n'
                                            + '</html>\n'
                                            ;
                //create a mail object to send a single email.
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
                String countrycode = (String.isBlank(account.Country_Code__c) || !mEmailAddress.containsKey(account.Country_Code__c))?'DEFAULT':account.Country_Code__c;
    
                //set the email properties  buchhaltung-eag@ebay.de
                String emailToEmailAddress = mEmailAddress.get(countrycode);
                
                mail.setToAddresses(new string[] {emailToEmailAddress});
                mail.setSenderDisplayName('SF.com Email Agent');
                mail.setSubject('New Account created, request for SAP number');
                mail.setHtmlBody( htmlbody);
                
                //send the email
                if (!Test.isRunningTest()) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail } );

            }

        } catch(Exception ex) { errMsg = ex.getMessage(); }
        
        if (String.isNotBlank(errMsg)) status = 'ko';

        result.put('status',status);
        result.put('msg',errMsg);

        return result;

    }
}