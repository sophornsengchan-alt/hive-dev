/*********************************************************************************************************************************
@ Class:        ExcelReportEmail
@ Version:      1.0
@ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:      US-0009356 - Client Reporting via Excel
                Migrated from EU
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.05.2021 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / migrated the class.
@               : 07.07.2021/ Vadhanak Voun (vadhanak.voun@gaea-sys.com) / US-0009906 - [Ads 2020] Org Wide Email for Excel Reports
                : 21.10.2021/ Loumang SENG (loumang.seng@gaea-sys.com) / US-0010415 - ADS - Copy Team UHL into all client facing auto-emails
                : 14.09.2023 /vadhanak voun / US-0013942 - PART 4 - Upgrade API version of all classes having an API version lower than 31
*********************************************************************************************************************************/
public without sharing class ExcelReportEmail {
      
     //email templates
     final String TEMPLATE_END_ED='Automated_Endreporting_Template_DE';
     final String TEMPLATE_END_EN='Automated_Endreporting_Template_EN';
     final String TEMPLATE_ED='Automated_reporting_Template_DE';
     final String TEMPLATE_EN='Automated_reporting_Template_EN';
   //  final String CAMPAIGN_MANAGER_EMAIL='AM-advertising@ebay.de'; //ADDED 2018-02-12 DHE
     final String CAMPAIGN_MANAGER_PROFILE='DE Campaign Manager';
    
     public String toAddress{get;set;}
     public String ccAddress{get;set;}
     public String subject{get;set;}
     public String bodyEmail{get;set;}   
     
     String name;// used in email body ex: Dear [name],
     
     /*====sender filtered by opp.owner role=====
     NOTE: In the future, if you want to add more emails, please follow 3 steps:
            1- create an Organization-Wide-Email-Address
            2- create a Custom-Label
                 (Organization-Wide-Email-Address.DisplayName = Custom-Label.value)
            3- go to method "getDisplayName" then add an item to map "mapPrefixRole"
                  Ex: 'FR' => System.Label.excel_email_display_name_FR
     
     EXISTING:
     System.Label.excel_email_display_name_ROE     = OrgWideEmailAddress.DisplayName ='eBay Advertising Account Management ROE';
     System.Label.excel_email_display_name_UK      = OrgWideEmailAddress.DisplayName ='eBay Advertising Account Management UK';  
     System.Label.excel_email_display_name_DE      = OrgWideEmailAddress.DisplayName ='eBay Advertising Account Management DE';  
     System.Label.excel_email_display_name_default                                 ='eBay Advertising Account Management';
     ==============*/
     String oppOwnerRole=''; //init in "initEmail" method
     /** 
     *   Used to get displayName from the "Owner.UserRole.Name" 
     */
     String getDisplayName(){
        //Key the the Role's prefix that we can clasify role's name to a specific country.
        map<String, String> mapPrefixRole = new map<String, String>{'ROE'=>System.Label.excel_email_display_name_ROE,
                                                                    'UK' =>System.Label.excel_email_display_name_UK ,
                                                                    'DE' =>System.Label.excel_email_display_name_DE };
        for(String prefix : mapPrefixRole.keySet()){
            //NK:07/07/2021:US-0009906
            if(oppOwnerRole.endsWith(prefix)){
                return mapPrefixRole.get(prefix);
            }
        }
        return System.Label.excel_email_display_name_default;
     }
     //=======================
     
     
     public String oppID{get;set;} 
     
     ExcelReport excelReport;
     public String attName{get;set;} 
     
     /** 
     *   Constructor default
     */
     public ExcelReportEmail(){             
        oppID=ApexPages.currentPage().getParameters().get('oppId');
        excelReport =new ExcelReport(oppID);
        attName= excelReport.fileName;
        initEmail();
     }
     
     /** 
     *   Constructor for calling from scheduler-batch
     */
     public ExcelReportEmail(String oppID){     
        this.oppID=oppID;
        excelReport =new ExcelReport(oppID);
        attName= excelReport.fileName; 
        initEmail();
     }
     
     /** 
     *   initialize all intance variables
     */ 
     void initEmail(){
        
        //Opportunity opp =[Select Owner.UserRole.Name, Internal_Only__c, Report_Language__c, (Select PricebookEntry.product2.Site__r.Name FROM OpportunityLineItems LIMIT 1), (Select Role, IsPrimary, Contact.Email, Contact.Name FROM OpportunityContactRoles WHERE Role=:ExcelReportHelper.CONTACT_ROLE_REPORT_RECEIVER OR IsPrimary=true), Campaign_Start__c, Campaign_End__c, Owner.Email, Owner.Name, Account_Manager__r.Email, Ext_Name_Campaign__c, Additional_Mail_Text__c, Account.Name FROM Opportunity WHERE id=:oppID];
        Opportunity opp =[Select Owner.UserRole.Name, Account_Manager__c, Account_Manager__r.Profile.Name,Internal_Only__c, Report_Language__c, (Select PricebookEntry.product2.Site__r.Name FROM OpportunityLineItems LIMIT 1), (Select Role, IsPrimary, Contact.Email, Contact.Name FROM OpportunityContactRoles WHERE Role=:ExcelReportHelper.CONTACT_ROLE_REPORT_RECEIVER OR IsPrimary=true), Campaign_Start2__c, Campaign_End__c, Owner.Email, Owner.Name, Account_Manager__r.Email, Ext_Name_Campaign__c, Additional_Mail_Text__c, Account.Name FROM Opportunity WHERE id=:oppID];
        
        oppOwnerRole=(opp.Owner.UserRole.Name==null?'':opp.Owner.UserRole.Name);
        
        //selecting tempate=== 
        String temName='';
        ccAddress ='';
        boolean isAfter=opp.Campaign_End__c<System.today()?true:false;
        if(opp.Report_Language__c==ExcelReportHelper.REPORT_LANGUAGE_GE){
            temName = isAfter?TEMPLATE_END_ED:TEMPLATE_ED;
            ccAddress = System.Label.cc_team_uhl_email_address+'; ';//Loumang-21/10/2021-US-0010415: DE account team agency TEAM UHL would like to be cc Email address - am-advertising@ebay.de
        }else{
            temName = isAfter?TEMPLATE_END_EN:TEMPLATE_EN;
        }
        list<EmailTemplate> listEmailTemplate= [Select HtmlValue, Subject from EmailTemplate where name=:temName limit 1];
        //=====================
        
        //If the field “opp.Internal_Only__c” is checked the mail will only be sent the opportunity owner and the user in “opp.Account_Manager__c”.
        if(opp.Internal_Only__c){
            toAddress=opp.Owner.Email;
            ccAddress +=opp.Account_Manager__r.Email==null?'':opp.Account_Manager__r.Email;
            name=opp.Owner.Name==null?'':opp.Owner.Name;            
        }else{
            
            ccAddress += opp.Owner.Email +'; '+ ((opp.Account_Manager__r.Email==null)?'':(opp.Account_Manager__r.Email+'; '));
            
            //Per default the recipients of the mail are all contact roles where role = “Reporting Receiver”.(1st for To-address, the remains for Cc-address) 
            //If there is no contact role with this role it will be replaced by the primary contact role
            for(OpportunityContactRole ocr : opp.OpportunityContactRoles){
                if(ocr.role==ExcelReportHelper.CONTACT_ROLE_REPORT_RECEIVER){
                    if(toAddress==null || toAddress=='' || toAddress=='null'){
                        toAddress=String.valueOf(ocr.Contact.Email);
                        name=String.valueOf(ocr.Contact.Name);
                    }else{
                        ccAddress+=ocr.Contact.Email==null?'':(ocr.Contact.Email+'; ');
                    }
                }
            }
            for(OpportunityContactRole ocr : opp.OpportunityContactRoles){
                if(toAddress!=null && toAddress!='' && toAddress!='null'){break;}
                if(ocr.IsPrimary){
                    if(toAddress==null || toAddress=='' || toAddress=='null'){
                        toAddress=String.valueOf(ocr.Contact.Email);
                        name=String.valueOf(ocr.Contact.Name);
                    }else{
                        ccAddress+=ocr.Contact.Email==null?'':(ocr.Contact.Email+'; ');
                    }
                }
            }
            
          if (opp.Account_Manager__c!=null && opp.Account_Manager__r.Profile.name.equalsIgnoreCase(CAMPAIGN_MANAGER_PROFILE)){
     //         system.debug('>>>>>>>>>>' +opp.Account_manager__r.Profile.name);
       //       system.debug('<<<<<<<<<<' +System.Label.Excel_Report_Email_CC_Address);
             ccAddress += System.Label.Excel_Report_Email_CC_Address + ';';
         }
            
            if(ccAddress.contains(';')){
                ccAddress=ccAddress.substring(0, ccAddress.lastIndexOf(';'));
            }
            
            
        }

        //[first LI.product2.Site_c.Name] 
        list<OpportunityLineItem> li =opp.OpportunityLineItems;
        String siteName='';
        if(!li.isEmpty()){ 
            siteName=li[0].PricebookEntry.product2.Site__r.Name==null?'':li[0].PricebookEntry.product2.Site__r.Name;
        }
        
        // find and replace 
        if(!listEmailTemplate.isEmpty()){
            subject=listEmailTemplate.get(0).Subject;
            subject=subject.replace('[first LI.product2.Site_c.Name]', siteName);
            subject=subject.replace('[opp.Account.Name]', opp.Account.Name==null?'':opp.Account.Name);
            subject=subject.replace('[opp.Ext_Name_Campaign__c]', opp.Ext_Name_Campaign__c==null?'':opp.Ext_Name_Campaign__c);
            subject=subject.replace('[Campaign_Start__c]', opp.Campaign_Start2__c==null?'':String.valueOf(opp.Campaign_Start2__c));
            subject=subject.replace('[Campaign_End__c]', opp.Campaign_End__c==null?'':String.valueOf(opp.Campaign_End__c));
            
            bodyEmail=listEmailTemplate.get(0).HtmlValue;
            bodyEmail= bodyEmail.replace('[name]', (name==null)?'':name);           
            bodyEmail= bodyEmail.replace('[opp.Ext_Name_Campaign__c]', opp.Ext_Name_Campaign__c==null?'':opp.Ext_Name_Campaign__c);
            bodyEmail= bodyEmail.replace('[first LI.product2.Site_c.Name]', siteName);
            bodyEmail= bodyEmail.replace('[Additional_Mail_Text__c]', opp.Additional_Mail_Text__c==null?'':opp.Additional_Mail_Text__c);
            
            //NK:20/07/2021:US-0009906: already modified in 4 email templates pointing to HIVE prod
            // Document[] doc=[Select Id From Document WHERE name='ebay_logo' limit 1];
            // String id = doc.isEmpty()?'':doc[0].id;          
            // bodyEmail= bodyEmail.replace('[logo]', System.URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.ImageServer?id='+id+'&oid='+UserInfo.getOrganizationId());
                    
        }
     }
     
     /** 
     *   Send Email with attachments
     */
     public Pagereference sendMail(){       
        if(toAddress==null || toAddress=='' || toAddress=='null'){return null;}
        toAddress=toAddress.replace(' ', '');//trim     
        List<String> listTo = new List<String>(toAddress.split(';'));
        //List<String> listTo = new List<String>{'bunhor.eng@gaea-sys.com'};
        // Set email file attachments
        Messaging.Emailfileattachment att = new Messaging.Emailfileattachment();
        att.setFileName(attName);//System.Label.excel_email_att_file_name
        att.setBody(Blob.valueOf(excelReport.getxml()));
        
        // Create EmailMessage and assign parameters        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setToAddresses(listTo);
        if(ccAddress!=null && ccAddress!=''){
            ccAddress=ccAddress.replace(' ', '');//trim
            List<String> listCC = new List<String>(ccAddress.split(';'));
            //List<String> listCC = new List<String>{'vadhanak.voun@gaea-sys.com'}; 
            mail.setCcAddresses(listCC);
        }
        
        /*=======Sender email can be defualt or from OrgWideEmailAddress ====   */
        String displayName= getDisplayName();
        if(displayName==System.Label.excel_email_display_name_default){
            mail.setSenderDisplayName(displayName);//sender address  will be determined by Email Settings in sf
        }else{
            List<OrgWideEmailAddress> listEmail =[Select Id From OrgWideEmailAddress Where DisplayName=:displayName Limit 1];
            if(listEmail.isEmpty()){
                mail.setSenderDisplayName(displayName);//sender address  will be determined by Email Settings in sf
            }else{
                mail.setOrgWideEmailAddressId(listEmail.get(0).Id);//sender address  will be determined by OrgWideEmailAddress
            }
        }
        //================
        
        
        mail.setSubject(subject); 
        mail.setHtmlBody(bodyEmail); 
        mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{att});
  
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            Pagereference oppPage = new Pagereference('/'+oppID);
            oppPage.setRedirect(true);
            return oppPage;
        }catch(System.EmailException ex){       
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,ex.getMessage() ); //Err_Email_Address
            ApexPages.addMessage(errormsg);
            return null;
        }
          
     }

     
     /** 
     *   call when click button back in email preview
     */ 
     public Pagereference back(){
        Pagereference oppPage = new Pagereference('/'+oppID);
        return oppPage;
     }
}