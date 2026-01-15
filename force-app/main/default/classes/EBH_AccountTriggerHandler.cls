/*********************************************************************************************************************************
@ Class:          EBH_AccountTriggerHandler
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Handler Class for Account Trigger
                  EPH-5 : Customer Management
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.05.2017 / JOY MONDOL / Created the class.
                  29.03.2018 / Neha Lund / Modified as part of EPH-5459 to replace <OWNER_NAME> in email with Owner Name
                                           for Urgency email notifications
                  28.07.2021 / Mony Nou / US-0009966 - [EU][GROWTH PORTAL] Deactivate email alert "DE Deals Terms & Conditions V1"
                  28.04.2022 / Loumang SENG / US-0011388 - Deactivate Contact Quality Task creation in the Seller Record
                  US-0014671 / Sophal Noch / US-0014671 - Tech debt - Migrate Process Builder to Trigger
                  08.03.2024 / Bora Chhorn / US-0014862 - When SP Account Management is set to Full Access when inviting the seller, set the Group account to Allowed
                  06.12.2024 / Sambath SENG / US-0016228 - Eligible Seller need to get Seller Portal Access
                  20.01.2025 / Acmatac Seing / US-0016292 - Auto Display of Account Team Members - Outreach Manager
                  17.04.2025 / vadhanak voun / US-0017119 - Linked Account - SP Promotion Manager reflect on the SP Group
                  28.04.2025 / Sophal Noch / US-0017154 - Replace OwnerId with Account_Manager__c for CohortSeller, Account, Campaign Related classes
                  08.05.2025 / Vimean Heng / US-0016303 - Launch - Eligibility - Remove Beta User Condition
*********************************************************************************************************************************/

public with sharing class EBH_AccountTriggerHandler {

    private final static Integer GMV_LAST_12_MONTHS_100 = 100;

    private final static String SP_DEAL_FULL_ACCESS = 'Full Access';
    private final static String ACCOUNT_TEAM_ROLE_OUTREACH_MANAGER = 'Outreach Manager';
    private final static String USER_QUERY = 'SELECT Id, Name FROM User ';
    private final static String ACCOUNT_TEAM_MEMBER_QUERY = 'SELECT Id, AccountId, UserId FROM AccountTeamMember ';

    private static final String ATH_OWNERNAME = '<OWNER_NAME>';  // 28.04.2025 / Sophal Noch / US-0017154 : move query from EBH_ConstantsUtility.AOC_CAMPQUERY into local variable

    /*****************************************************************************************************************************
    @ Author:   Vadhanak Voun
    @ Purpose:  US-0006885 Hypercare - BoB Activation is not working
    @			To preven cpu exceed, from BoB activation that cause to update all the related account's fields. no logic related to this update; so no need trigger involved
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.12.2019 /Vadhanak Voun/ Created the  flag.
    *****************************************************************************************************************************/
    public static Boolean NO_TRIGGER_RUN = false;
    
    /*****************************************************************************************************************************
    @ Method:         updateCustomRollUp
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        EPH-1796 : Updates custom roll ups on account (record type: Legal Entity) from all child accounts 
                      across one level of seller hierarchy and child legal entities records for the following fields:
                       - GMV
                       - Revenue 
                       - Sold Items
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accounts:      accounts from the trigger scope
                      accountOldMap: accounts old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public static void updateCustomRollUp(List<Account> accounts, Map<Id, Account> accountOldMap) {
        
        Set<Id> parentIds = new Set<Id>();    //distinct parent ids of the accounts in trigger scope
        List<Account> parents;                //list of distinct parents from parentIds
        
        if(accounts != null) {
            for(Account acc : accounts) { 
            
                //get distinct parent ids from trigger scope accounts and populate parentIds if any aggregate fields has changed
                if(hasRollupChanged(acc, accountOldMap)) {              
                    
                    Id pId = acc.ParentId;
                    
                    if(!String.isBlank(pId)) {
                        parentIds.add(pId); 
                    }
                }
                
                //if parent lookup/legal entity lookup is changed, then both old and new parents need to be updated
                if(hasParentChanged(acc, accountOldMap)){
                    
                    Id pId = accountOldMap.get(acc.id).ParentId;
                    
                    if(!String.isBlank(pId)) {
                        parentIds.add(pId); 
                    }
                }
            }
        } else {            
            for( Account acc : accountOldMap.values()){
                
                Id pId = accountOldMap.get(acc.id).ParentId;
                
                if(!String.isBlank(pId)) {
                    parentIds.add(pId); 
                }
            } 
        }
        
        //fetch the parents and the childs and sellers from parentIds
        parents = Database.query(EBH_ConstantsUtility.ATH_PARENTCHILDQUERY);
        
        //fetch the childs and sellers of parents from parentIds and populate parentChildMap
        for(Account acc : parents) {
            
            //reset the roll ups
            acc.EBH_SoldItems__c = acc.EBH_GMVLast12Months__c = acc.EBH_RevenueLast12Months__c = EBH_ConstantsUtility.ATH_RESET;
            
            //aggregate from child accounts
            for(Account cAcc : acc.ChildAccounts) {                
                //aggregate and populate roll ups at parent
                acc.EBH_SoldItems__c += cAcc.EBH_SoldItems__c != Null ? cAcc.EBH_SoldItems__c : EBH_ConstantsUtility.ATH_RESET;
                acc.EBH_GMVLast12Months__c += cAcc.EBH_GMVLast12Months__c != Null ? cAcc.EBH_GMVLast12Months__c : 
                                                EBH_ConstantsUtility.ATH_RESET;
                acc.EBH_RevenueLast12Months__c += cAcc.EBH_RevenueLast12Months__c != Null ? cAcc.EBH_RevenueLast12Months__c : 
                                                EBH_ConstantsUtility.ATH_RESET; 
            }
        }

        //update parents
        try {
            Database.update(parents);
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.ATH_CLASS, EBH_ConstantsUtility.ATH_METHOD);
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         hasRollupChanged
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Check and returns true if any of the following fields has changed in account passed in param:
                       - GMV Last 12 Months
                       - Revenue 
                       - Sold Items
                       - Legal Entity
                       - Parent
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      acc:           account to check field(s) change for
                      accountOldMap: account old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public static Boolean hasRollupChanged(Account acc, Map<Id, Account> accountOldMap) {
        
        Account oldAcc = accountOldMap != Null ? accountOldMap.get(acc.Id) : acc;
        
        return acc.EBH_SoldItems__c != oldAcc.EBH_SoldItems__c ||
               acc.EBH_GMVLast12Months__c != oldAcc.EBH_GMVLast12Months__c ||
               acc.EBH_RevenueLast12Months__c != oldAcc.EBH_RevenueLast12Months__c ||
               acc.ParentId != oldAcc.ParentId || accountOldMap == null; 
    } 
    
    /*****************************************************************************************************************************
    @ Method:         hasParentChanged
    @ Version:        1.0
    @ Author:         Neha Lund
    @ Purpose:        Check and returns true if parent has changed in old account passed in param
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      acc:           account to check field(s) change for
                      accountOldMap: account old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static Boolean hasParentChanged(Account acc, Map<Id, Account> accountOldMap) {
        
        Account oldAcc = accountOldMap != Null ? accountOldMap.get(acc.Id) : acc;
        
        return acc.ParentId != oldAcc.ParentId;
    }    
    
     /*****************************************************************************************************************************
    @ Method:         updateRelatedContactStatus
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        EPH-3270 : Updates related Contacts's Status from the related Account's Status 
                      - Pending Termination
                      - Deleted
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accounts:      accounts from the trigger scope
                      accountOldMap: accounts old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.09.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static void updateRelatedContactStatus(List<Account> accounts, Map<Id, Account> accountOldMap) {
        
        Set<ID> accountIds = new Set<ID>();
        List<Contact> contactRecords  = new List<Contact>();
         //loop through trigger scope
        for(Account acc : accounts) { 
            //get distinct parent ids from trigger scope Campaigns and populate parentIds 
            if(hasStatusChanged(acc, accountOldMap)) {   
                accountIds.add(acc.Id); 
            }
        }
        
        if(!accountIds.isEmpty()){
            contactRecords = Database.query(EBH_ConstantsUtility.ATH_ACCOUNTCONTACTQUERY);
            for( Contact con: contactRecords){
                con.EBH_Status__c = con.Account.EBH_Status__c;
            }
        }
        
        //update Contacts
        try {
            Database.update(contactRecords);
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.ATH_CLASS, EBH_ConstantsUtility.ATH_METHOD);
        }
         
    }
     /*****************************************************************************************************************************
    @ Method:         validateUpsert
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        EPH-3270 : Do not upsert any accounts if the status is
                      - Deleted
                      - Pending Termination
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accounts:      accounts from the trigger scope
                      accountOldMap: accounts old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.09.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static void validateDeleteUpsert(List<Account> accounts, Map<ID, Account> accountOldMap) {
       
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(EBH_ConstantsUtility.ATH_OBJECTNAME).getDescribe().fields.getMap();
        
         //loop through trigger scope
        for(Account acc : accounts) { 
        
            //get distinct parent ids from trigger scope Campaigns and populate parentIds 
            if(!hasStatusChanged(acc, accountOldMap) && !String.isBlank(acc.EBH_Status__c) && 
               (acc.EBH_Status__c.equalsIgnoreCase(EBH_ConstantsUtility.ACRTH_TERMINATEDSTATUS) || 
                acc.EBH_Status__c.equalsIgnoreCase(EBH_ConstantsUtility.ACRTH_DELETEDSTATUS)) ) {
              
                 for(String fieldName : fieldMap.keyset()){
                     if( fieldMap.get(fieldName).getDescribe().isUpdateable())
                     acc.put(fieldName,  accountOldMap.get(acc.Id).get(fieldName));
                 }
                 
            }
        }
        
    }
     /*****************************************************************************************************************************
    @ Method:         notifyUrgencyTaskOwner
    @ Version:        1.0
    @ Author:         Neha Lund
    @ Purpose:        EPH-4122: Check and returns true if Urgency Flag is true
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      acc:           account to check field(s) change for
                      accountOldMap: account old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.10.2017 / NEHA LUND / Created the  Method.
    @               : 02.02.2018/ Vadhanak Voun / fixed Owner.Name by issue soql (Owner.Name is null from pure trigger)
    @               : 28.04.2025 / Sophal Noch / US-0017154 - Replace OwnerId with Account_Manager__c for CohortSeller, Account, Campaign Related classes
    *****************************************************************************************************************************/
    /* 29.04.2025 / Sophal Noch / US-0017154 : confirmed to be deprecated
    public static void notifyUrgencyTaskOwner(List<Account> accounts, Map<ID,Account> accountOldMap){
    
        // Set<String> setOwnerId = new Set<String>(); // 28.04.2025 / Sophal Noch / US-0017154 : no longer use set OwnerId to query
        Set<String> setAccManagerId = new Set<String>(); // 28.04.2025 / Sophal Noch / US-0017154 : replace set ownerid with set Account_Manager__c

        for( Account acc: accounts){

            // setOwnerId.add(acc.OwnerId);
            if(acc.Account_Manager__c != null){
                setAccManagerId.add(acc.Account_Manager__c);  // 28.04.2025 / Sophal Noch / US-0017154 : populate setAccManagerId with Account_Manager__c
            }
        }

        // Map<String,User> mapOwner = new Map<String,User>([Select Id,Name from User Where Id IN:setOwnerId]);  // 28.04.2025 / Sophal Noch / US-0017154 : no longer query with set OwnerId
        if(setAccManagerId.isEmpty()){  
            return;
        }
        // 28.04.2025 / Sophal Noch / US-0017154 : query users with Account_Manager__c and store in mapAccManager
        Map<String, User> mapAccManager = new Map<String, User>((List<User>) ApexSafe.query().secCheck(false).doQuery('Select Id, Name from User Where Id IN: setAccManagerId', new Map<String, Object>{'setAccManagerId' => setAccManagerId}));

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        String plainBody =' ';
        String urgencyReason;
        String defectReason;
        for( Account acc: accounts){                   
             
            if( String.isBlank(acc.EBH_UrgencyReason__c)){
                urgencyReason ='';
            }
            else{
                urgencyReason = acc.EBH_UrgencyReason__c;
            }
            if( String.isBlank(acc.EBH_DefectReason__c)){
                defectReason ='';
            }
            else{
                defectReason = acc.EBH_DefectReason__c;
            }
            
            if(hasUrgencyFlag(acc, accountOldMap, mapAccManager)){ // 28.04.2025 / Sophal Noch / US-0017154 : replace mapOwner with mapAccManager
            
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                // email.setTargetObjectId(acc.ownerId);
                email.setTargetObjectId(acc.Account_Manager__c); // 28.04.2025 / Sophal Noch / US-0017154 : replace recipient with Account_Manager__c

                email.setSubject(EBH_ConstantsUtility.TTH_URGENCYTASK);
                plainBody = EBH_ConstantsUtility.ATH_URGENCYEMAILBODY;
                
                // 28.04.2025 / Sophal Noch / US-0017154 : no longer use OwnerId to and EBH_AccountManageName__c in email template
                // if(!String.isBlank(acc.EBH_AccountManageName__c)){
                //     plainBody = plainBody.replace(EBH_ConstantsUtility.ATH_OWNERNAME, acc.EBH_AccountManageName__c);
                // }
                // else{
                //     //EPH-5459 - to fix <OWNER_NAME> issue
                //     plainBody = plainBody.replace(EBH_ConstantsUtility.ATH_OWNERNAME, mapOwner.get(acc.ownerID).Name);
                // }

                // 28.04.2025 / Sophal Noch / US-0017154 : use Name of Account_Manager__c in email template
                plainBody = plainBody.replace(ATH_OWNERNAME, mapAccManager.get(acc.Account_Manager__c)?.Name);
                
                plainBody = plainBody.replace(EBH_ConstantsUtility.ATH_ACCOUNTNAME, acc.Name);
                plainBody = plainBody.replace(EBH_ConstantsUtility.ATH_URGENCYREASON, urgencyReason);
                plainBody = plainBody.replace(EBH_ConstantsUtility.ATH_DEFECTREASON, defectReason);
                email.setplainTextBody(plainBody);
                email.setSaveAsActivity(false);
                emailsToSend.add(email);
               
            }
        
        }
        if(!emailsToSend.isEmpty()){
            Messaging.sendEmail(emailsToSend);
        }
        
    }
    */

    /*****************************************************************************************************************************
    @ Method:         hasUrgencyFlag
    @ Version:        1.0
    @ Author:         Neha Lund
    @ Purpose:        Check and returns true if Account Status has changed in old account passed in param
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      acc:           account to check field(s) change for
                      accountOldMap: account old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2017 / NEHA LUND / Created the  Method.
    @               : 02.02.2018/ Vadhanak Voun / fixed Owner.Name by issue soql (Owner.Name is null from pure trigger)
    @               : added param: Map<String,User> mapOwner
    @               : used map instead of: acc.Owner.Name
    @               : 28.04.2025 / Sophal Noch / US-0017154 - Replace OwnerId with Account_Manager__c for CohortSeller, Account, Campaign Related classes
    *****************************************************************************************************************************/
    /* 29.04.2025 / Sophal Noch / US-0017154 : confirmed to be deprecated
    public static Boolean hasUrgencyFlag(Account acc, Map<Id, Account> accountOldMap, Map<String,User> mapAccManager) {     

        Account oldAcc = accountOldMap != Null ? accountOldMap.get(acc.Id) : acc;
        
        // 28.04.2025 / Sophal Noch / US-0017154 : no longer use OwnerId to check in condition
        // return ((acc.EBH_UrgencyFlag__c != oldAcc.EBH_UrgencyFlag__c ||
        //        acc.ownerId != oldAcc.ownerID ) || accountOldMap==null ) &&
        //        mapOwner.get(acc.OwnerId).Name != Label.EBH_IntegrationUser &&            
        //        acc.EBH_UrgencyFlag__c ;
        
        // 28.04.2025 / Sophal Noch / US-0017154 : use ownerid with Account_Manager__c in urgency flag condition
        return ((acc.EBH_UrgencyFlag__c != oldAcc.EBH_UrgencyFlag__c ||
               acc.Account_Manager__c != oldAcc.Account_Manager__c ) || accountOldMap==null ) &&
               String.isNotBlank(acc.Account_Manager__c) &&
               mapAccManager.get(acc.Account_Manager__c)?.Name != Label.EBH_IntegrationUser &&            
               acc.EBH_UrgencyFlag__c ;
               
    }   
    */           
    
     /*****************************************************************************************************************************
    @ Method:         removeGDPRContact
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        EPH-5413 : Remove GDPR contact and related contacts
                     
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accounts:      accounts from the trigger scope
                      accountOldMap: accounts old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 01.05.2018 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static void removeGDPRContact(List<Account> accounts, Map<ID, Account> accountOldMap) {
                
                List<Account> removeAccounts = new List<Account>();
                
                for( Account acc: accounts){  
                    
                    if( hasGDPRRemoved(acc, accountOldMap)){
                        
                        removeAccounts.add(acc);
                    
                    }
                    
                }
                
               
                
                if(!removeAccounts.isEmpty()){
                
                   removeGDPRContacts([SELECT Email, Phone, MobilePhone, EBH_SecondaryEmail__c
                    from Contact where accountID IN : removeAccounts limit 10000], true);
               }
                    
                   
    }
     /*****************************************************************************************************************************
    @ Method:         removeGDPRContacts
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        EPH-5413 : Remove GDPR contact and related contacts
                     
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      contacts:      contacts from the trigger scope
                      accountTrigger: boolean to have a explicit DML
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 01.05.2018 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    
    public static void removeGDPRContacts(List<Contact> contacts, boolean accountTrigger){
         List<Contact> contactRecords = new List<Contact>();
                List<Contact> relatedContacts = new List<Contact>();
                Set<String> emails = new Set<String>();
                Set<String> phones = new Set<String>();
                
                
                RecordType rec = [SELECT id from RecordType where sobjectType = 'Contact' and DeveloperName = 'EBH_GDPR_Removed'];
                
                
         for(Contact con: contacts){
                        
                        con.recordTypeId =  rec.Id;
                        
                        if( con.Email != null ){
                           
                            emails.add(con.Email);
                        }
                        if(con.EBH_SecondaryEmail__c != null){
                          
                            emails.add(con.Ebh_SecondaryEMail__c);
                        }
                       
                        if( con.phone != null){
                            
                            phones.add(con.Phone);
                        }
                        if( con.MobilePhone != null){
                            phones.add(con.MobilePhone);
                        }
                        
                        con =  updateGDPRDeletedData(con);
                        if(accountTrigger)
                        contactRecords.add(con);
                    }
                     if(!contactRecords.isEmpty()){
                        update contactRecords;
                    }
        /*            
         * COMMENTED BY DHE in order to avoid unwanted deletions
         * 20190416
                    System.debug('£££££'+emails);
        
                    if( !emails.isEmpty() || !phones.isEmpty())
                    {
                       updateGDPRContacts(emails, phones, rec.ID); 
                    }
          */          
                   
    
    }
    
    public static Contact updateGDPRDeletedData(Contact con){
        
                        con.salutation = '';
                        con.EBH_ContactPreference__c = 'DELETED';
                        con.EBH_Status__c = 'Deleted';
                        con.EBH_DoNotContact__c= true;
                        con.EBH_emailOut__c = true;
                        con.EBH_MailingAddress__c = 'DELETED';
                        con.EBH_MailingCity__c = 'DELETED';
                        con.EBH_MailingCountry__c = 'DELETED';
                        con.EBH_MailingPostalCode__c = 'DELETED';
                        con.EBH_MailingStreet__c ='DELETED';
                        con.EBH_PhoneOptOut__c = true;
                        con.EBH_SecondaryEmail__c = 'DELETED@DELETED.com';
                        con.EMail = 'DELETED@DELETED.com';
                        con.FirstName = 'DELETED';
                        con.LastName  = 'DELETED';
                        con.MiddleName = 'DELETED';
                        con.Title = 'DELETED';
                        con.Suffix = 'DELETED';
                        con.MobilePhone = '###############';
                        con.HomePhone = '###############';
                        con.Phone = '###############';
                        return con;
                        
    }
    
    @future
    public static void updateGDPRContacts(Set<String> emails, Set<String> phones, String recID){
         List<Contact> contactRecords = new List<Contact>();       
        for(Contact con: [SELECT email from Contact where 
                    (Email IN :emails  OR  EBH_SecondaryEmail__c IN :emails OR MobilePhone IN :phones OR Phone IN :phones)
                     AND
                     (RecordType.DEveloperName = 'EBH_DWH' OR RecordType.DeveloperName = 'EBH_MANUAL')
                       limit 10000]){
                        
                        
                        con.recordTypeId =  recId;
                        con = updateGDPRDeletedData(con);
                        contactRecords.add(con);
                    }
                    
                
                
                if( !contactRecords.isEmpty() ){
                    Database.update(contactRecords,false);
                }
              
    }
     
     /*****************************************************************************************************************************
    @ Method:         hasGDPRRemoved
    @ Version:        1.0
    @ Author:         Neha Lund
    @ Purpose:        Check and returns true if Seller has been removed via GDPR removed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      acc:           account to check field(s) change for
                      accountOldMap: account old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 01.05.2018 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static Boolean hasGDPRRemoved(Account acc, Map<Id, Account> accountOldMap) {
        
        Account oldAcc = accountOldMap != Null ? accountOldMap.get(acc.Id) : acc;
        
        return acc.EBH_GDPR_Removed__c != oldAcc.EBH_GDPR_Removed__c && (acc.EBH_GDPR_Removed__c || accountOldMap == null);
               
    }  
    
     /*****************************************************************************************************************************
    @ Method:         hasStatusChanged
    @ Version:        1.0
    @ Author:         Neha Lund
    @ Purpose:        Check and returns true if Account Status has changed in old account passed in param
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      acc:           account to check field(s) change for
                      accountOldMap: account old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static Boolean hasStatusChanged(Account acc, Map<Id, Account> accountOldMap) {
        
        Account oldAcc = accountOldMap != Null ? accountOldMap.get(acc.Id) : acc;
        
        return acc.EBH_Status__c != oldAcc.EBH_Status__c;
               
    }  

       /*****************************************************************************************************************************
@ Method:         createRecordtypeField
@ Author:         David Herrero
@ Purpose:        Create a field in before trigger for using duplicate rules
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      ListAccounts:       List of Accounts

------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18-10-2018 /David Herrero / Created the  Method.
*****************************************************************************************************************************/
    public static void createRecordtypeField(List<Account>listAccounts){
        Map<id,string> mapRecordType = new Map<id,STring>();
        for(RecordType rt : [select id,developername from recordtype where sobjecttype='Account']){
            mapRecordType.put(rt.id,rt.developername);
        }
        for (Account a : listAccounts){
            //if (mapRecordType.get(a.RecordTypeId)=='EBH_Brand'){
                a.Record_Type_Text__c=mapRecordtype.get(a.RecordTypeId);    
            //}
            
        }
        
    }

    /*****************************************************************************************************************************
    @ Method:         updateSellerGroupWhenSPFieldChanged
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0012302 - Seller Portal Group needs to reflect the SP field values in the Related Account
    @ Event:		  after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	  listNewAcc from Trigger.new, mapOldAcc from Trigger.oldMap
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.08.2022 / Sophal Noch / Created the  Method.
    @                 08.03.2024 / Bora Chhorn / US-0014862 - When SP Account Management is set to Full Access when inviting the seller, set the Group account to Allowed
    @                 04.04.2025 / Sovantheany Dim / US-0016623 - Enable Link Multiple Account for NA
    @                 17.04.2025 / vadhanak voun / US-0017119 - Linked Account - SP Promotion Manager reflect on the SP Group
    *****************************************************************************************************************************/
    public static void updateSellerGroupWhenSPFieldChanged(List<Account> listNewAcc, Map<Id, Account> mapOldAcc){
        Set<String> setSellerGroupId = new Set<String>();
        for(Account newAcc  : listNewAcc){
            Account oldAcc = mapOldAcc.get(newAcc.Id);
            //TH:05.04.2025:US-0016623 : Check with NA_Deal_Program_Vetted__c
            //NK:17/04/2025:US-0017119 
            if(newAcc.Seller_Portal_Group__c != null && (newAcc.SP_Promotions_Manager__c != oldAcc.SP_Promotions_Manager__c || newAcc.SP_Deals__c != oldAcc.SP_Deals__c || newAcc.SP_Coupons__c != oldAcc.SP_Coupons__c || newAcc.SP_Account_Management__c != oldAcc.SP_Account_Management__c || newAcc.NA_Deal_Program_Vetted__c != oldAcc.NA_Deal_Program_Vetted__c))
            {
                setSellerGroupId.add(newAcc.Seller_Portal_Group__c);
            }
        }
        if(!setSellerGroupId.isEmpty()){
            Map<Id, Account> mapAccToUpdate = LinkedAccountsController.populateSellerGroupSPFields(setSellerGroupId, new Set<String>());
            if(!mapAccToUpdate.isEmpty()) update mapAccToUpdate.values();
        }
    }

    /*********************************************************************************************************************************
    @ Method:         updateRelatedAUProject
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014671 - Tech debt - Migrate Process Builder to Trigger
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  25.01.2023 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public static void updateRelatedAUProject(List<Account> listNewAcc, Map<Id, Account> mapOldAcc){
        
        Set<String> setAccId = new Set<String>();

        for(Account acc : listNewAcc){

            if(acc.EBH_GMVLast12Months__c != null && acc.EBH_GMVLast12Months__c >= GMV_LAST_12_MONTHS_100 && acc.EBH_GMVLast12Months__c != mapOldAcc.get(acc.Id).EBH_GMVLast12Months__c){
                setAccId.add(acc.Id);
            }

        }

        if(!setAccId.isEmpty()){
            ProjectUpdateHelper.updateRelatedAUProject(setAccId);
        }

    }

    /*********************************************************************************************************************************
    @ Method:         updateSPDealForNADealProgramSeller
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0016228 - Eligible Seller need to get Seller Portal Access
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06.12.2024 / Sambath / Created the method.
    @               :  03.02.2025 / Sambath Seng / US-0016643 - Tech debt-Optimise updateSPDealForNADealProgramSeller in Account trigger handler
    @               :  08.05.2025 / Vimean Heng / US-0016303 - Launch - Eligibility - Remove Beta User Condition
    *********************************************************************************************************************************/
    public static void updateSPDealForNADealProgramSeller(List<Account> listNewAcc){
        for(Account newAcc : listNewAcc){
            //VM: remove newAcc.Seller_Portal_Beta_User__c == true && 
            if(newAcc.NA_Deal_Program_Vetted__c == true && newAcc.EBH_RevRollup__c == 'US' && newAcc.SP_Deals__c != SP_DEAL_FULL_ACCESS){
                newAcc.SP_Deals__c = SP_DEAL_FULL_ACCESS;
                newAcc.SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA;
                newAcc.Deal_Program_Exemption__c = 'Item Limit';
            }
        }
    }

    /*********************************************************************************************************************************
    @ Method:         outReachProgramToAccountTeamMember
    @ Author:         Acmatac Seing
    @ Purpose:        US-0016292 - Auto Display of Account Team Members - Outreach Manager
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  20.01.2025 / Acmatac Seing / Created the method.
    *********************************************************************************************************************************/
    public static void outReachProgramToAccountTeamMember(List<Account> listNewAcc, Map<Id, Account> mapOldAcc){
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        List<AccountTeamMember> listAccountTeamToInsert = new List<AccountTeamMember>();
        List<Account> listMatchedAccount = new List<Account>();
        Set<Id> userIds = new Set<Id>();
        
        Map<Id, Id> mapATMToDelete = new Map<Id, Id>();
        Set<Id> deletionAccountId = new Set<Id>();
        // New Context
        if(mapOldAcc == null){
            for(Account newAcc : listNewAcc){
                if(!String.isEmpty(newAcc.Outreach_Manager__c) && recSeller.Id == newAcc.RecordTypeId){
                    userIds.add(newAcc.Outreach_Manager__c);
                    listMatchedAccount.add(newAcc);
                }
            }
        }else{
            List<Account> lstAccountsToUpdate = new List<Account>();
            for(Account newAcc : listNewAcc){
                Account oldAcc = mapOldAcc.get(newAcc.Id);
                if(newAcc.Outreach_Manager__c != oldAcc.Outreach_Manager__c && recSeller.Id == newAcc.RecordTypeId){
                    if(!String.isEmpty(newAcc.Outreach_Manager__c)){
                        userIds.add(newAcc.Outreach_Manager__c);
                        listMatchedAccount.add(newAcc);
                    }
                    // To delete account team member
                    else{
                        mapATMToDelete.put(newAcc.Id, oldAcc.Outreach_Manager__c);
                    }
                }
            }
        }

        // Insertion part
        if(!userIds.isEmpty()){
            Map<Id, User> mapUsers = new Map<Id, User>((List<User>) ApexSafe.query().doQuery(USER_QUERY + ' WHERE Id IN :userIds AND IsActive = true', new Map<String, Object>{'userIds' => userIds}));
            for (Account oneAcc : listMatchedAccount) {
                if(mapUsers.containsKey(oneAcc.Outreach_Manager__c)) {
                    listAccountTeamToInsert.add(new AccountTeamMember(
                        AccountId = oneAcc.Id,
                        UserId = oneAcc.Outreach_Manager__c,
                        TeamMemberRole = ACCOUNT_TEAM_ROLE_OUTREACH_MANAGER
                    ));
                }
            }
            Database.SaveResult[] results = ApexSafe.dml().secCheck(false).doInsert(listAccountTeamToInsert,true);
            List<Database.Error> dbError = new List<Database.Error>();
            for (Database.SaveResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()){ dbError.addAll(result.getErrors()); }
            }
            if (!dbError.isEmpty()) EBH_ApexLogger.logError(dbError, 'EBH_AccountTriggerHandler','outReachProgramToAccountTeamMember doInsert');
        }

        // Deletion part
        if(!mapATMToDelete.keySet().isEmpty()){
            Set<Id> accIds = mapATMToDelete.keySet();
            List<AccountTeamMember> listAtmToDelete = new List<AccountTeamMember>();
            for(AccountTeamMember atm : (List<AccountTeamMember>) ApexSafe.query().doQuery(ACCOUNT_TEAM_MEMBER_QUERY + ' WHERE AccountId IN: accIds', new Map<String, Object>{'accIds' => accIds})){
                if(mapATMToDelete.containsKey(atm.AccountId) 
                   && mapATMToDelete.get(atm.AccountId) == atm.UserId){
                    listAtmToDelete.add(atm);
                }
            }
            Database.DeleteResult[] results = ApexSafe.dml().secCheck(false).doDelete(listAtmToDelete,true);
            List<Database.Error> dbError = new List<Database.Error>();
            for (Database.DeleteResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()){ dbError.addAll(result.getErrors()); }
            }
            if (!dbError.isEmpty()) EBH_ApexLogger.logError(dbError, 'EBH_AccountTriggerHandler','outReachProgramToAccountTeamMember doDelete');
        }
        
    }
}