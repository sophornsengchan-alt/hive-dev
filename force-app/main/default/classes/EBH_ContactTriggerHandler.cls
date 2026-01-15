/*********************************************************************************************************************************
@ Class:          EBH_ContactTriggerHandler
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Handler Class for Contact Trigger
                  EPH-3270: Sprint 7 : Customer Management
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 28.09.2017 / NEHA LUND / Created the class.
@               : 14.08.2024/ vadhanak voun / US-0015725 - "Delete Contact" button is not working
@               : 04.07.2025 / Sothea Horn / US-0033083 - Enable the merging tool for DWH contact
*********************************************************************************************************************************/

public without sharing class EBH_ContactTriggerHandler {

    //04.07.2025 / Sothea Horn / US-0033083 - Enable the merging tool for DWH contact
    private static RecordType contactRecTypeDWH = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
    private static RecordType accountRecTypeSeller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    
    private static Id sellerRecordTypeId = accountRecTypeSeller.Id;
    /*****************************************************************************************************************************
    @ Method:         validateUpsert
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        EPH-3270 : Do not upsert any Contacts if the status is
                      - Deleted
                      - Pending Termination
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Contacts:      Contacts from the trigger scope
                      ContactOldMap: Contacts old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.09.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static void validateDeleteUpsert(List<Contact> Contacts, Map<ID, Contact> ContactOldMap) {
       
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(EBH_ConstantsUtility.CTH_OBJECTNAME).getDescribe().fields.getMap();
        
         //loop through trigger scope
        for(Contact con : Contacts) { 
        
            //get distinct parent ids from trigger scope Campaigns and populate parentIds 
            if(!hasStatusChanged(con, ContactOldMap) && 
                String.isNotBlank(con.EBH_Status__c) &&
               (con.EBH_Status__c.equalsIgnoreCase(EBH_ConstantsUtility.ACRTH_TERMINATEDSTATUS) || 
                con.EBH_Status__c.equalsIgnoreCase(EBH_ConstantsUtility.ACRTH_DELETEDSTATUS)) ) {
              
                 for(String fieldName : fieldMap.keyset()){
                     if( fieldMap.get(fieldName).getDescribe().isUpdateable())
                     con.put(fieldName,  ContactOldMap.get(con.Id).get(fieldName));
                 }
                 
            }
        }
        
        
    }
     /*****************************************************************************************************************************
    @ Method:         hasStatusChanged
    @ Version:        1.0
    @ Author:         Neha Lund
    @ Purpose:        Check and returns true if Contact Status has changed in old Contact passed in param
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      con:           Contact to check field(s) change for
                      ContactOldMap: Contact old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static Boolean hasStatusChanged(Contact con, Map<Id, Contact> ContactOldMap) {
        
        Contact oldcon = ContactOldMap != Null ? ContactOldMap.get(con.Id) : con;
        
        return con.EBH_Status__c != oldcon.EBH_Status__c;
               
    }    
    
    /*****************************************************************************************************************************
    @ Method:   countNumberOfContactsWithIssues
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  EPH-5630 Seller - Quality & Preference
                    Number of Contacts with Issues = COUNT number of Contacts that are not Green 
                    Contact Data Quality =  "Red" =Seller has 0 Contacts with Contact Data Quality equal to "Green".
                                        "Amber" = Seller has 1 or more Contacts not Green, but at least 1 Contact that is Green
                                        "Green" = All Contacts of the Seller are Green
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      contacts: old Contact from Trigger when trigger deleted else new contact from trigger
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 01.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the  Method.
                      07/05/2018 / Neha Lund (nalund@deloitte.co.uk) / to calculate number of contacts with Marketing opt in on Seller
    *****************************************************************************************************************************/
    public static void countNumberOfContactsWithIssues(List<Contact> contacts){
        Set<String> sAccountId = new Set<String>();
        //loop through trigger scope
        for(Contact con : contacts){
            if(con.AccountID != null)
            
            sAccountId.add(con.AccountId);
        }
        Map<String,Integer> mapContactSize = new Map<String,Integer>();
        Map<String,Integer> marketingCountMap = new Map<String,Integer>();

        //get all child Contacts for each parent Account
        if( !sAccountID.isEmpty()) {
            // 09.07.2025 / Sothea Horn / Fix Apex CRUD Violation (US-0033083)
            String soqlAggregate = 'select count(Id) myCount, sum(EBH_MarketingOptIn__c) marketing, AccountId from Contact where AccountId IN: sAccountId Group by AccountId';
            List<AggregateResult> listAggregateResults = ApexSafe.query().secCheck(false).doQuery(soqlAggregate, new Map<String, Object> {'sAccountId' => sAccountId});
            for(AggregateResult ar : listAggregateResults) {
                mapContactSize.put((String) ar.get('AccountId'), (integer) ar.get('myCount'));
                marketingCountMap.put((String) ar.get('AccountId'), integer.valueOf(ar.get('marketing')));
            }
        }
        System.debug('MArketingCount Map'+marketingCountMap);
        List <Account> lstAccountsToUpdate = new List <Account>();
        
        if( !sAccountId.isEmpty()) {
            // 09.07.2025 / Sothea Horn / Fix Apex CRUD Violation (US-0033083)
            String soqlAccs = 'select Id, Number_of_Contacts_with_Issues__c, Contact_Data_Quality__c, (Select ID From Contacts where Contact_Data_Quality__c !=: greenContact) from Account where id IN: sAccountId and RecordTypeId =: sellerRecordTypeId';
            List<Account> listAccs = ApexSafe.query().secCheck(false).doQuery(soqlAccs, new Map<String, Object> {'greenContact' => EBH_ConstantsUtility.GREEN_CONTACT, 'sAccountId' => sAccountId, 'sellerRecordTypeId' => sellerRecordTypeId});
            for(Account acc : listAccs) {
                Account accObj = new Account ();
                accObj.Id = acc.Id;
                
                //COUNT number of Contacts that are not Green 
                accObj.Number_of_Contacts_with_Issues__c = acc.Contacts.size();
            
                //update Contact Data Quality if there are child Contact relation
                if(mapContactSize.containsKey(acc.Id)) {
                
                accObj.EBH_NumberofContactsWithMarketingOptIn__c = marketingCountMap.get(acc.Id);
                Integer allContactsize = mapContactSize.get(acc.Id);
                accObj.EBH_NumberofContacts__c = allContactsize;
                    //Seller has 0 Contacts with Contact Data Quality equal to "Green".
                    if(allContactsize == accObj.Number_of_Contacts_with_Issues__c){
                        accObj.Contact_Data_Quality__c = EBH_ConstantsUtility.RED_ACCOUNT;
                    }
                    //All Contacts of the Seller are Green
                    else if(allContactsize == (allContactsize - accObj.Number_of_Contacts_with_Issues__c)){
                        accObj.Contact_Data_Quality__c = EBH_ConstantsUtility.GREEN_CONTACT;
                    }
                    //Seller has 1 or more Contacts not Green, but at least 1 Contact that is Green
                    else{
                        accObj.Contact_Data_Quality__c = EBH_ConstantsUtility.AMBER_ACCOUNT;
                    }
                }
                //Todo : if there are no child contact relationship, Contact_Data_Quality__c should equal to red or null??
                else{
                    accObj.Contact_Data_Quality__c = null;
                }
                lstAccountsToUpdate.add(accObj);
            }
        }
        if (!lstAccountsToUpdate.isEmpty()) {
            // 09.07.2025 / Sothea Horn / Fix Apex CRUD Violation (US-0033083)
            ApexSafe.dml().secCheck(false).doUpdate(lstAccountsToUpdate, true);
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:   checkPrimaryContact
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  EPH-5629 Contact - Quality & Preference
                    there can only be one "Primary Contact" for each Account
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      contacts: list of new contact from trigger before insert and before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the  Method.
    *****************************************************************************************************************************/
//    public static void checkPrimaryContact(List<Contact> contacts, Map<ID, Contact> ContactOldMap, Boolean isUpdate){
//        Set<String> sAccountId = new Set<String>();
//        Map<String,Boolean> mapIsPrimCurCon = new Map<String,Boolean>();
//        for(Contact con : contacts){
//            if(con.AccountId != null && con.Primary_Contact__c) {
//            //check primary on current contact
//            addError(con,mapIsPrimCurCon);
//            mapIsPrimCurCon.put(con.AccountId,true);
//            if(isUpdate){
//                Contact oldCon = ContactOldMap.get(con.Id);
//                if(!oldCon.Primary_Contact__c){
//                    sAccountId.add(con.AccountId);
//                }
//            }else{
//                    sAccountId.add(con.AccountId);
//            }
//            }
//        }
//        System.debug('<<<<sAccountId='+sAccountId);
//        Map<String,Boolean> mapIsPrimCon = new Map<String,Boolean>();
//        for(Account a : [Select a.Id, (Select Id, Primary_Contact__c From Contacts where Primary_Contact__c = true) From Account a where id IN: sAccountId]){
//            mapIsPrimCon.put(a.Id, a.contacts.size()>0 ? true : false);
//        }
//        for(Contact con : contacts){
//            addError(con,mapIsPrimCon);
//        }
//    }
    
    /*****************************************************************************************************************************
    @ Method:   addError
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  add error if there more than one primary contact in each account
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    con : new contact from trigger
                    mapIsPrimCon : map account id if there there is primary contact
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the  Method.
    *****************************************************************************************************************************/
//    public static void addError(Contact con,Map<String,Boolean> mapIsPrimCon){
//        if(mapIsPrimCon.containsKey(con.AccountId) && mapIsPrimCon.get(con.AccountId) == true){
//           con.addError(System.Label.PrimaryContact_Error_Msg);
//       }
//    }
    
    /*****************************************************************************************************************************
    @ Method:         removeGDPRContact 
    @ Version:        1.0
    @ Author:         Neha Lund
    @ Purpose:        Check and returns true if Contact Status has changed in old Contact passed in param
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      con:           Contact to check field(s) change for
                      ContactOldMap: Contact old map from trigger scope to compare
                      EPH-5413 - to remove GDPR contact
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.05.2018 / NEHA LUND / Created the  Method.
    @				: 12.06.2018/ Vadhanak Voun/ [#EPH-5656]: extends to GDPR Lead remvove
    @               : 14.08.2024/ vadhanak voun / US-0015725 - "Delete Contact" button is not working
    *****************************************************************************************************************************/
    public static void removeGDPRContact (List<Contact> contacts, Map<ID, Contact> oldMap){
        
        List<Contact> removeContacts = new List<Contact>();
        
        Set<String> setAccountIds = new Set<String>();
    	Set<String> setEmails = new Set<String>();
    	
        for(Contact con: contacts){
            
            if( con.EBH_GDPRRemoved__c && oldMap.get(con.Id).EBH_GDPRRemoved__c != con.EBH_GDPRRemoved__c){
                removeContacts.add(con);
                
                setAccountIds.add(con.AccountId);
    			if((con.Email+'').toLowerCase() <> 'deleted@deleted.com')
                {
                    setEmails.add(con.Email);
                }
            }
        }
        if( !contacts.isEmpty()){
            
            EBH_AccountTriggerHandler.removeGDPRContacts(removeContacts , false);
            
            //NK:12/06/2018: [#EPH-5656]
            //NK:14/08/2024:US-0015725 - disabled the method
            //empty email causes the gdpr of Leads with blank email DML 10001
            //if(!setAccountIds.isEmpty() || !setEmails.isEmpty())
            //{
            //	LeadTriggerHandler.removeLeadGDPR(setAccountIds,setEmails);
            //}
        }
    
         
    }
    /*****************************************************************************************************************************
@ Method:         UpdateAccountPrimaryContactRelatedFields 
@ Version:        1.0
@ Author:         David Herrero
@ Purpose:        EPH-6581
------------------------------------------------------------------------------------------------------------------------------

@ Change history: 25-10-2018/ David Herrero/ Created the  Method.

*****************************************************************************************************************************/
    public static void UpdateAccountPrimaryContactRelatedFields (List<Contact> contacts){
        map<id,List<Contact>> mapAccountIdListContacts = new map<id,List<Contact>>();
        map<id,Account> mapAccountIdAccounts = new map<id,account>();
        set<id> accountIds = new set<id>();
        
        for (Contact c : contacts){
            if(c.AccountID != null) accountIds.add(c.AccountID);
        }
        /* UPDATED 2018-12-10 BY DHE
         * If we use a sub-query, it fails when updating GCX Contacts. maximum number of subquery records is 200.
        for (Account a : [select id ,Primary_Contact_Name__c,Primary_Contact_Email__c ,(select id,primary_contact__c, recordtype.name,name,email from contacts) from account where id in :accountIds]){
            mapAccountIdListContacts.put(a.id,a.contacts);
            mapAccountIdAccounts.put(a.id,a);    
            
        }
*/		
        // 09.07.2025 / Sothea Horn / Fix Apex CRUD Violation (US-0033083)
        String soqlAcc = 'Select id, primary_contact_name__c , primary_contact_email__c From Account Where id in : accountIds';
        List<Account> listAccs = ApexSafe.query().secCheck(false).doQuery(soqlAcc, new Map<String, Object> {'accountIds' => accountIds});
        for (Account a : listAccs){
            mapAccountIdAccounts.put(a.id, a);    
        }
        // 09.07.2025 / Sothea Horn / Fix Apex CRUD Violation (US-0033083)
        String soqlContact = 'Select id, primary_contact__c, recordtype.name, name, email, accountId From Contact Where Accountid in :accountIds';
        List<Contact> listContacts = ApexSafe.query().secCheck(false).doQuery(soqlContact, new Map<String, Object> {'accountIds' => accountIds});
        for (Contact c: listContacts) {
            if (mapAccountIdListContacts.containskey(c.AccountId)){
                mapAccountIdListContacts.get(c.AccountId).add(c);
            }else{
                mapAccountIdListContacts.put(c.AccountId, new List<Contact>{c});
            }
        }
        
        for (ID accountid : mapAccountIdListContacts.keyset()){
            List<Contact> lcs = (List<Contact>)mapAccountIdListContacts.get(accountid);
            String primaryContactEmail,primaryContactName;
            ID primaryContactId;
            boolean found=false;
            if (lcs!=null && !lcs.isEmpty()){
                for (Contact c : lcs){
                    if (c.primary_contact__c==true){
                        primaryContactName=c.name;
                        primaryContactEmail=c.email;
                        primaryContactId=c.id;
                        found=true;
                        break;
                    }
                }                    
                if (!found){
                    for (Contact c2 : lcs){
                        if (c2.recordtype.name==Ebh_Constantsutility.RECORDTYPE_DWH){
                            primaryContactName=c2.name;
                            primaryContactEmail=c2.email;  
                              primaryContactId=c2.id;
							found=true;
                              	
                            break;
    }
                    }
                }
            }
            
          if(!mapAccountIdAccounts.containsKey(accountId)) continue;
		  
          if(!String.isBlank( primaryContactName) || !String.isBlank( primaryContactEmail)){
          	mapAccountIdAccounts.get(accountId).Primary_Contact_Name__c=primaryContactName;
          
          	mapAccountIdAccounts.get(accountId).Primary_Contact_Email__c=primaryContactEmail;
          	mapAccountIdAccounts.get(accountId).Primary_Contact__c=primaryContactId;
          }  
          if(String.isBlank( primaryContactName)&&
          String.isBlank( primaryContactEmail)
          ){
          mapAccountIdAccounts.remove(accountID);
          }
            
          
        }  
        if (!mapAccountIdAccounts.isEmpty()){
        	update mapAccountIdAccounts.values();
        }
    }
    
    public static void updatePrimaryContactFlag(List<Contact> newList,Boolean isUpdate){
        set<id> accountIds = new set<id>();
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact c :  newList){
            if (c.AccountId!=null && c.Primary_Contact__c){
                accountIds.add(c.AccountId);
            }
        }
        Map<id,Contact> mapAccountIdContact = new Map<id,Contact>();

        // 09.07.2025 / Sothea Horn / Fix Apex CRUD Violation (US-0033083)
        String soqlAccs = 'Select id ,(Select id,primary_contact__c From Contacts Where id not in :setNewContactIds) From Account Where id in :accountIds';
        List<Account> listAccs = ApexSafe.query().secCheck(false).doQuery(soqlAccs, new Map<String, Object> {'setNewContactIds' => new Map<id,Contact>(newList).keyset(), 'accountIds' => accountIds});
        for (Account a : listAccs){
            for (Contact c : a.Contacts){
                if (c.Primary_Contact__c){
                    mapAccountIdContact.put(a.id,c);
                }
            }
        }
        
        for (Contact c : newList){
            if(c.accountid!=null && mapAccountIdContact.containsKey(c.AccountId) &&  mapAccountIdContact.get(c.AccountId).id!=c.id){
                Contact aux=mapAccountIdContact.get(c.AccountId);
                aux.Primary_Contact__c=false;
                contactsToUpdate.add(aux);
            }
        
        }
        
        if(!contactsToUpdate.isEmpty()){
            // 09.07.2025 / Sothea Horn / Fix Apex CRUD Violation (US-0033083)
            ApexSafe.dml().secCheck(false).doUpdate(contactsToUpdate, true);
        }
    }
    /*****************************************************************************************************************************
    @ Method:         setCloneSource
    @ Version:        1.0
    @ Author:         vadhanak voun
    @ Purpose:        US-0011343 - Adding User to Existing Seller Portal Group
	@ Event:		before Insert 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Contacts:       new
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.05.2022 / vadhanak voun / Created the  Method.
    *****************************************************************************************************************************/
    public static void setCloneSource(List<Contact> listContNew)
    {
        for(Contact cont: listContNew)
        {
            if(cont.isClone())cont.ClonedSource__c = cont.getCloneSourceId();
        }
    }

    /*****************************************************************************************************************************
    @ Method:         validateContactUpdateBusinessName
    @ Version:        1.0
    @ Author:         Bora Chhorn
    @ Purpose:        US-0013526 - Seller Portal Contact's Account Name shouldn't be changed
	@ Event:		  before Update 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<Contact> contacts
                      Map<ID, Contact> oldMap
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.06.2023 / Bora Chhorn / Created the  Method.
    *****************************************************************************************************************************/
    public static void validateUpdateBusinessName(List<Contact> contacts, Map<ID, Contact> oldMap)
    {
        Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID);
        if(isAdmin || LinkedAccountsController.IS_LINKING_ACCOUNT) return;
        for (Contact con : contacts){
        	Contact oldCon = oldMap.get(con.Id);
            if(con.AccountId != oldCon.AccountId && String.isNotBlank(con.Community_User__c)) {
                con.addError(Label.Error_Update_Business_Name_On_Contact);
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:         preventDeleteDWHContact
    @ Version:        1.0
    @ Author:         Sothea Horn
    @ Purpose:        US-0033083 - Enable the merging tool for DWH contact
	@ Event:		before delete 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      listContOld:       old
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.07.2025 / Sothea Horn / Created the Method.
    *****************************************************************************************************************************/
    public static void preventDeleteDWHContact(List<Contact> listContOld) {
        if (!isByPassValidationRule()) {
            for(Contact cont: listContOld) {
                if (cont.RecordTypeId == contactRecTypeDWH.Id) {
                    cont.addError(System.Label.Prevent_Deletion_of_DWH_Contact_Message);
                }
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:         isByPassValidationRule
    @ Version:        1.0
    @ Author:         Sothea Horns
    @ Purpose:        US-0033083 - Enable the merging tool for DWH contact
	@ Event:		before delete 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.07.2025 / Sothea Horn / Created the Method.
    *****************************************************************************************************************************/
    private static boolean isByPassValidationRule() {
        //check bypass validation rule
        byPass__c bp = byPass__c.getInstance(UserInfo.getUserId());
        return (bp!=null && bp.ByPass_Validation__c);
    }
}