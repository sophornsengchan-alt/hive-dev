/*********************************************************************************************************************************
@ Class:         BatchCouponSellerTimeBased
@ Version:       1.0
@ Author:        Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:       US-0002115 - Tech - Migrate "Coupon Seller Time Based" to Batch Job
@                   - This batch schedule is the replica of all Flows related with Coupon Seller Time Based
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.05.2025 / Mony Nou / Created the class.
@                 19.08.2025 / LoumAng SENG / US-0033260 - CA SP - Coupon Launch Reminder Email
----------------------------------------------------------------------------------------------------------------------------------
*/
global with sharing class BatchCouponSellerTimeBased implements Database.Batchable<SObject>, Schedulable {
    
    private final static String SWITCH_COUPONREMINDER = 'Coupon_Launch_Reminder';
    private final static String OWD_HIVESUPPORT = 'Hive Support';
    private final static Set<String> SWITCHMODE = new Set<String>{SWITCH_COUPONREMINDER};
    private final static String RT_MANHATTAN = 'Manhattan_Coupon';
    private final static String STAGE_CONTRACT_SEND = 'Contract Send';
    private final static String STAGE_CONTRACT_NEGO = 'Contract Negotiation';
    private final static String STAGE_CONTRACT_SIGNED = 'Contract Signed';
    private final static String SITE_US = 'ebay.com';
    private final static String SITE_DE = 'ebay.de';
    private final static String SITE_AU = 'ebay.com.au';    
    private final static String SITE_IT = 'ebay.it';
    private final static String SITE_FR = 'ebay.fr';
    private final static String SITE_UK = 'ebay.co.uk';
    private final static String SITE_CA = 'ebay.ca'; //LA-19-08-2025-US-0033260
    //private final static Set<String> COUPONSITE = new Set<String>{SITE_US,SITE_DE,SITE_IT,SITE_FR,SITE_UK,SITE_AU};//LA-19-08-2025-US-0033260
    // private final static Set<String> COUPONSITE_EU = new Set<String>{SITE_DE,SITE_IT,SITE_FR,SITE_UK};//LA-19-08-2025-US-0033260
    private final static Set<String> COUPONSITE_EU_CA = new Set<String>{SITE_DE,SITE_IT,SITE_FR,SITE_UK,SITE_CA};//Add site CA //LA-19-08-2025-US-0033260
    private final static Set<String> COUPONTYPE = new Set<String> {'Item Based', 'Category Based'};
    private final static String SPCOUPONACCESS_ALLOWED = 'Allowed';
    private final static String SPCOUPONACCESS_FULL = 'Full Access';
    private final static String SC_DELIVERY_STATUS = 'Pending';
    private final static String SC_EMT_SIGNAGREEMENT = 'Sign Agreement Reminder';
    private final static String SC_EMT_UPLOADITEMS = 'Upload Items Reminder';
    private final static String SC_EMT_CPSTARTRMD = 'Coupon Start Reminder';
    private final static String SC_PLATFORM = 'Seller Portal';
    private final static Id SC_RTID = ApexUtil.getRecordTypeByName('Seller_Communication__c', 'Coupons').Id;
    private final static Id CONT_RTID_DWH = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH').Id;
    private final static Id CONT_RTID_GDPR = ApexUtil.getRecordTypeByName('Contact', 'EBH_GDPR_Removed').Id;
    private final static Id ACC_RTID_SPGRP = ApexUtil.getRecordTypeByName('Account', 'Seller_Portal_Group').Id;
    private final static Id TASK_RTID = ApexUtil.getRecordTypeByName('Task', 'Standard_Task').Id;
    private final static String TASK_STATUS = 'Completed';
    private final static String TASK_SUBJECT = 'Email: Coupon Launch Reminder';
    private final static String TASK_SUBTYPE = 'Email';
    private final static String TASK_DESCRIPTION = 'To: ';
    private final static String EMAIL_SUBJECT = 'Coupon Contract Email cannot be sent for ';
    private final static String EMAIL_BODY = 'Unable to send Coupon Contract email to Seller ';
    private final static String EMAIL_BODY_2 = 'Seller Contact information was not found. Please ensure the Seller\'s details are correctly entered and try again.';

    private Set<String> sCSIds = new Set<String>();
    private String sQuery = 'SELECT Id, EBH_CouponSellerOwner__c, Coupon_Seller_Stage__c,  Negotiation_End_Date__c, Coupon_Start_Date__c, Contract_Due_Date__c, Coupon__r.Main_Coupon_Site__c, Seller__c, Seller__r.Name, Seller__r.EBH_OracleID__c, Seller__r.Seller_Portal_Group__c, Seller__r.RecordType.DeveloperName FROM Coupon_Seller__c';
    private String sWhere = ' WHERE RecordType.DeveloperName =:RT_MANHATTAN AND Coupon_Type__c IN:COUPONTYPE AND Seller__r.EBH_EmailOut__c = FALSE  AND ((Seller__r.Seller_Portal_Group__c != NULL AND Seller__r.Seller_Portal_Group__r.SP_Coupons__c =:SPCOUPONACCESS_ALLOWED) OR (Seller__r.Seller_Portal_Group__c = NULL AND Seller__r.SP_Coupons__c =:SPCOUPONACCESS_FULL))'
                    + ' AND ( '
                    + ' (Contract_Due_Date__c = NEXT_N_DAYS:5 AND Coupon__r.Main_Coupon_Site__c =:SITE_AU AND Coupon_Seller_Stage__c =:STAGE_CONTRACT_SEND) OR '
                    + ' (Contract_Due_Date__c = NEXT_N_DAYS:2 AND Coupon__r.Main_Coupon_Site__c =:SITE_US AND Coupon_Seller_Stage__c=:STAGE_CONTRACT_SEND) OR '
                    + ' (Negotiation_End_Date__c = NEXT_N_DAYS:2 AND Coupon__r.Main_Coupon_Site__c =:SITE_US AND Coupon_Seller_Stage__c=:STAGE_CONTRACT_NEGO) OR '
                    + ' (Contract_Due_Date__c = NEXT_N_DAYS:2 AND Coupon__r.Main_Coupon_Site__c IN:COUPONSITE_EU_CA AND Coupon_Seller_Stage__c =:STAGE_CONTRACT_SEND) OR ' //LA-19-08-2025-US-0033260: change COUPONSITE_EU to COUPONSITE_EU_CA
                    + ' (Coupon_Start_Date__c = NEXT_N_DAYS:2 AND (Coupon__r.Main_Coupon_Site__c =:SITE_UK OR Coupon__r.Main_Coupon_Site__c =:SITE_CA) AND Coupon_Seller_Stage__c =:STAGE_CONTRACT_SIGNED)' //LA-19-08-2025-US-0033260: Add Site CA
                    + ' )';
    
    // Map to store the site variant for each site
    private Map<String,String> mapSiteVariant = new Map<String,String>{
        SITE_AU => 'AU',
        SITE_US => 'NA',
        SITE_DE => 'DE',
        SITE_IT => 'IT',
        SITE_FR => 'FR', 
        SITE_UK => 'UK',
        SITE_CA => 'CA' //LA-19-08-2025-US-0033260: Add Site CA
    };

    // Map to store the email template for each stage
    private Map<String, String> mapStageEmailTemplate = new Map<String, String>{
        STAGE_CONTRACT_SEND => SC_EMT_SIGNAGREEMENT,
        STAGE_CONTRACT_NEGO => SC_EMT_UPLOADITEMS,
        STAGE_CONTRACT_SIGNED => SC_EMT_CPSTARTRMD
    };

    /*
    * @Description: Map to store the Switch Services for the Coupon Launch Reminder
    */
    private Map<String,Switch_services__mdt> mSwtichService {
        get {

            if (mSwtichService == null) {

                mSwtichService = new Map<String,Switch_services__mdt>();

                for (Switch_services__mdt ss : [SELECT ID, DeveloperName, Active__c FROM Switch_services__mdt WHERE DeveloperName IN:SWITCHMODE]){
                    mSwtichService.put(ss.DeveloperName, ss);
                }

            }

            return mSwtichService;
        }

        private set;
    }

    /*
    * @Description: Map to store the Org Wide Email Address for the Hive Support
    */
    private OrgWideEmailAddress owdHiveSupport {

        get {
            if (owdHiveSupport == null) {
                for (OrgWideEmailAddress owd : [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName =:OWD_HIVESUPPORT]) {
                    owdHiveSupport = owd;
                }
            }
            return owdHiveSupport;
        }

        private set;
    }

    /*
    * @Description: Map to store the configuration for the Coupon Seller Time Based for each site
    */
    private Map<String, List<SiteTimeBased>> mapSiteTimeBased {

        get {

            if (mapSiteTimeBased == null) {
                mapSiteTimeBased = new Map<String, List<SiteTimeBased>> {
                    SITE_AU => new List<SiteTimeBased>(),
                    SITE_US => new List<SiteTimeBased>(),
                    SITE_DE => new List<SiteTimeBased>(),
                    SITE_IT => new List<SiteTimeBased>(),
                    SITE_FR => new List<SiteTimeBased>(),
                    SITE_UK => new List<SiteTimeBased>(),
                    SITE_CA => new List<SiteTimeBased>() //LA-19-08-2025-US-0033260: Add Site CA
                };

                // AU: 1 & 5 days before Contract Due Date to send reminders
                mapSiteTimeBased.get(SITE_AU).add(new SiteTimeBased(SITE_AU, 1, STAGE_CONTRACT_SEND));
                mapSiteTimeBased.get(SITE_AU).add(new SiteTimeBased(SITE_AU, 5, STAGE_CONTRACT_SEND));

                // US: 2 days before Contract Due Date to send reminders for Contract Send
                mapSiteTimeBased.get(SITE_US).add(new SiteTimeBased(SITE_US, 2, STAGE_CONTRACT_SEND));
                // US: 2 days before Negotiation End Date to send reminders for Contract Negotiation
                mapSiteTimeBased.get(SITE_US).add(new SiteTimeBased(SITE_US, 2, STAGE_CONTRACT_NEGO));
            

                // DE: 2 days before Contract Due Date to send reminders
                mapSiteTimeBased.get(SITE_DE).add(new SiteTimeBased(SITE_DE, 2, STAGE_CONTRACT_SEND));

                // IT: 2 days before Contract Due Date to send reminders
                mapSiteTimeBased.get(SITE_IT).add(new SiteTimeBased(SITE_IT, 2, STAGE_CONTRACT_SEND));

                // FR: 2 days before Contract Due Date to send reminders
                mapSiteTimeBased.get(SITE_FR).add(new SiteTimeBased(SITE_FR, 2, STAGE_CONTRACT_SEND));

                // UK: 2 days before Contract Due Date to send reminders for Contract Send
                mapSiteTimeBased.get(SITE_UK).add(new SiteTimeBased(SITE_UK, 2, STAGE_CONTRACT_SEND));
                // UK: 2 days before Coupon Start Date to send reminders for Contract Signed
                mapSiteTimeBased.get(SITE_UK).add(new SiteTimeBased(SITE_UK, 2, STAGE_CONTRACT_SIGNED));

                // CA: 2 days before Contract Due Date to send reminders for Contract Send
                mapSiteTimeBased.get(SITE_CA).add(new SiteTimeBased(SITE_CA, 2, STAGE_CONTRACT_SEND));//LA-19-08-2025-US-0033260
                // CA: 2 days before Coupon Start Date to send reminders for Contract Signed
                mapSiteTimeBased.get(SITE_CA).add(new SiteTimeBased(SITE_CA, 2, STAGE_CONTRACT_SIGNED));//LA-19-08-2025-US-0033260


            }
            return mapSiteTimeBased;

        }

        private set;
    }

    /*
    * @Description: Wrapper Class to store the configuration for the Coupon Seller Time Based for each site
    */
    public class SiteTimeBased {

        public String site; // Main Coupon Site
        public Integer nDayReminder; // Number of days before the event to send the reminder
        public String stage; // Coupon Seller Stage

        public SiteTimeBased(String site, Integer nDayReminder, String stage) {
            this.site = site;
            this.nDayReminder = nDayReminder;
            this.stage = stage;
        }
    }

    public BatchCouponSellerTimeBased() {}

    /*
    * @Description: Constructor to initialize the batch with a set of Coupon Seller IDs
    * @param sCSIds Set of Coupon Seller IDs to process
    */
    public BatchCouponSellerTimeBased(Set<String> sCSIds) {
        if (!sCSIds.isEmpty()) {
            this.sCSIds.addAll(sCSIds);
            sWhere = ' WHERE Id IN:sCSIds';    
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(sQuery+sWhere);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope){

        Map<Id, List<Seller_Communication__c>> mapSellerCommunication = new Map<Id, List<Seller_Communication__c>>();
        Map<Id, Set<Id>> mapSellerPortalGroup = new Map<Id, Set<Id>>();
        Map<Id, Coupon_Seller__c> mapCouponSeller = new Map<Id, Coupon_Seller__c>((List<Coupon_Seller__c>)scope); //Convert List to Map for faster access

        for (Coupon_Seller__c cs : mapCouponSeller.values()) {
            
            if (mapSiteTimeBased.containsKey(cs.Coupon__r.Main_Coupon_Site__c)) { //Check if there is a configuration for the site

                checkTimeBasePerCouponSeller(cs, mapSellerCommunication, mapSellerPortalGroup); //Check if the time base is due for the coupon seller

            }
        }

        if (!mapSellerCommunication.isEmpty()) { createSellerCommunication(mapSellerCommunication, mapSellerPortalGroup, mapCouponSeller); }

    }

    /*
    * @Description: Check if the time base is due for the coupon seller
    * @param mainSite Main Coupon Site
    * @param mapSellerCommunication Map of Seller Communication records to be created
    * @param mapSellerPortalGroup Map of Seller Portal Group IDs to be used for sending emails
    */
    private void checkTimeBasePerCouponSeller (Coupon_Seller__c cs, Map<Id, List<Seller_Communication__c>> mapSellerCommunication, Map<Id, Set<Id>> mapSellerPortalGroup) {

        String mainSite = cs.Coupon__r.Main_Coupon_Site__c;
            
        for (SiteTimeBased siteTimeBased : mapSiteTimeBased.get(mainSite)) {

            String stage = siteTimeBased.stage;

            if (cs.Coupon_Seller_Stage__c != stage) { continue; } // Check if the stage matches

            Integer nDayReminder = siteTimeBased.nDayReminder;
            // IF UK and the stage is Contract Signed and reminder date is due, create a Seller Communication
            // IF US and the stage is Contract Negotiation and Negotiation date is due, create a Seller Communication
            // Else if reminder date is due, create a Seller Communication
            //LA-19-08-2025-US-0033260: Add SITE_CA to condition
            if ((stage == STAGE_CONTRACT_SIGNED && (mainSite == SITE_UK || mainSite == SITE_CA) && cs.Coupon_Start_Date__c != null && cs.Coupon_Start_Date__c == Date.today().addDays(nDayReminder) && mSwtichService.containsKey(SWITCH_COUPONREMINDER) && mSwtichService.get(SWITCH_COUPONREMINDER).Active__c) || 
                (stage == STAGE_CONTRACT_NEGO && mainSite == SITE_US && cs.Negotiation_End_Date__c != null && cs.Negotiation_End_Date__c.Date() == Date.today().addDays(nDayReminder)) ||
                (cs.Contract_Due_Date__c != null && cs.Contract_Due_Date__c == Date.today().addDays(nDayReminder))) {

                if (!mapSellerCommunication.containsKey(cs.Seller__c)) { mapSellerCommunication.put(cs.Seller__c, new List<Seller_Communication__c>()); }
                mapSellerCommunication.get(cs.Seller__c).add(createSellerCommunication(cs, nDayReminder, siteTimeBased.stage));

                if (cs.Seller__r.Seller_Portal_Group__c == null) { continue; }

                if (!mapSellerPortalGroup.containsKey(cs.Seller__r.Seller_Portal_Group__c)) { mapSellerPortalGroup.put(cs.Seller__r.Seller_Portal_Group__c, new Set<Id>()); }
                mapSellerPortalGroup.get(cs.Seller__r.Seller_Portal_Group__c).add(cs.Seller__c);

            }

        }
    }

    /*
    * @Description: Retrieve the contacts for the sellers in the map and create Seller Communication records
    * @param mapSellerCommunication Map of Seller Communication records to be created
    * @param mapSellerPortalGroup Map of Seller Portal Group IDs to be used for sending emails
    */
    private void createSellerCommunication(Map<Id, List<Seller_Communication__c>> mapSellerCommunication, Map<Id, Set<Id>> mapSellerPortalGroup, Map<Id, Coupon_Seller__c> mapCouponSeller) {

        Map<Id, List<Contact>> mapSellerContacts = new Map<Id, List<Contact>>();
        List<Seller_Communication__c> lstSC2Insert = new List<Seller_Communication__c>();
        List<Task> lstTask2Insert = new List<Task>();
        List<Messaging.SingleEmailMessage> lstEmail2Insert = new List<Messaging.SingleEmailMessage>();
        
        // Get the contacts (a DWH Contact & Any active communication users) for the sellers in the map
        for (Contact cont : [SELECT Id, Name, AccountId, Account.RecordTypeId FROM Contact 
                                WHERE (AccountId IN:mapSellerCommunication.keySet() AND RecordTypeId=:CONT_RTID_DWH AND Email != NULL) 
                                OR ((AccountId IN:mapSellerCommunication.keySet() OR AccountId IN:mapSellerPortalGroup.keySet()) AND Community_User__c != NULL AND Active_Community_User__c = TRUE AND AccountId != NULL AND RecordTypeId !=: CONT_RTID_GDPR)]) {
        
            if (!mapSellerContacts.containsKey(cont.AccountId)) { mapSellerContacts.put(cont.AccountId, new List<Contact>()); }
            mapSellerContacts.get(cont.AccountId).add(cont);
        }   

        for (Id sellerId : mapSellerCommunication.keySet()) {

            for (Seller_Communication__c sc : mapSellerCommunication.get(sellerId)) {

                Boolean isCouponStartReminder = (sc.Email_Template__c == SC_EMT_CPSTARTRMD);

                if (mapCouponSeller.containsKey(sc.Coupon_Seller__c)) {

                    Coupon_Seller__c cs = mapCouponSeller.get(sc.Coupon_Seller__c);
                    
                    List<String> lstContactName = new List<String>();
                    if (mapSellerContacts.containsKey(cs.Seller__c)) {
                        
                        iterateContacts(cs.Seller__c, mapSellerContacts, cs, sc, isCouponStartReminder, lstSC2Insert, lstContactName);
                        
                        String sepAccountId = cs.Seller__r.Seller_Portal_Group__c;
                        if (sepAccountId != null && mapSellerContacts.containsKey(sepAccountId)) { iterateContacts(sepAccountId, mapSellerContacts, cs, sc, isCouponStartReminder, lstSC2Insert, lstContactName); }


                    }
                    else if (cs.Coupon__r.Main_Coupon_Site__c == SITE_AU) { // For AU, if no contact is found, send email to Hive Support
                        Messaging.SingleEmailMessage email = setSingleEmailMessage(cs);
                        if (email != null) { lstEmail2Insert.add(email); }
                    }

                    //Additional Logic for Coupon Start Reminder: Create Standard Task
                    if (isCouponStartReminder && !lstContactName.isEmpty()) {
                        lstTask2Insert.add(new Task(
                            ActivityDate = Date.today(),
                            Description = TASK_DESCRIPTION + String.join(lstContactName, ', '),
                            IsVisibleInSelfService = false,
                            Log_Task__c = true,
                            OwnerId = cs.EBH_CouponSellerOwner__c,
                            RecordTypeId = TASK_RTID,
                            Status = TASK_STATUS,
                            Subject = TASK_SUBJECT,
                            TaskSubtype = TASK_SUBTYPE,
                            WhatId = cs.Id
                        ));
                    }   
                    

                }
            }
        }

        try {
            
            // Insert Seller Communication
            Database.SaveResult[] insertResult = ApexSafe.dml().doInsert(lstSC2Insert,false); //false for partial success
            logError(insertResult, 'Insert: Seller Communication');
            
            // Insert Task if there are any
            if (!lstTask2Insert.isEmpty()) {
                insertResult = ApexSafe.dml().doInsert(lstTask2Insert,false); //false for partial success
                logError(insertResult, 'Insert: Task');
            }

            // Send email if there are any
            if (!lstEmail2Insert.isEmpty()) {
                ApexUtil.sendEmail(lstEmail2Insert);
            }

        }catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchCouponSellerTimeBased','execute (batch)'); }
        
    }

    /*
    * @Description: Iterate through the contacts for each seller and create Seller Communication records
    * @param accountId Account ID of the seller
    * @param mapSellerContacts Map of Account ID to List of Contacts for the seller
    * @param cs Coupon Seller record
    * @param isCouponStartReminder Boolean indicating if this is a Coupon Start Reminder           
    * @param lstSC2Insert List of Seller Communication records to be inserted
    * @param lstContactName List of contact names for the Coupon Start Reminder
    */
    private void iterateContacts (String accountId, Map<Id, List<Contact>> mapSellerContacts, Coupon_Seller__c cs, Seller_Communication__c sc, Boolean isCouponStartReminder, List<Seller_Communication__c> lstSC2Insert, List<String> lstContactName) {

        for (Contact cont : mapSellerContacts.get(accountId)) {
            Id scAccountId = (cont.Account.RecordTypeId == ACC_RTID_SPGRP && cs.Seller__r.Seller_Portal_Group__c != null && cont.AccountId == cs.Seller__r.Seller_Portal_Group__c)?cs.Seller__r.Seller_Portal_Group__c:cont.AccountId;
            Seller_Communication__c sc2Insert = sc.clone();
            sc2Insert.Contact__c = cont.Id;
            sc2Insert.Account__c = scAccountId;
            lstSC2Insert.add(sc2Insert);
            
            //Additional Logic for Coupon Start Reminder
            if (isCouponStartReminder) { lstContactName.add(cont.Name); }


        }

    }
 
    /*
    * @Description: Log the errors from the DML operation
    * @param insertResult List of Database.SaveResult from the DML operation
    * @param sMethodName Name of the method where the error occurred
    */
    @testvisible
    private void logError(Database.SaveResult[] insertResult, String sMethodName) 
    {
        if (insertResult == null || insertResult.isEmpty()) { return; }

        List<Database.Error> listErrors = new List<Database.Error>();
        for (Database.SaveResult sr : insertResult) 
        {
            if (!sr.isSuccess()) { listErrors.addAll(sr.getErrors()); }
        }

        if(!listErrors.isEmpty()) { EBH_ApexLogger.logError(listErrors, 'BatchCouponSellerTimeBased',sMethodName); }
    }
    
    /*
    * @Description: Create a new Seller Communication record
    * @param cs Coupon Seller record
    * @param nDayReminder Number of days before the event to send the reminder
    * @param stage Coupon Seller Stage
    * @return Seller_Communication__c object
    */
    private Seller_Communication__c createSellerCommunication(Coupon_Seller__c cs, Integer nDayReminder, String stage) {

        Seller_Communication__c sc = new Seller_Communication__c();
        sc.Coupon_Seller__c = cs.Id;
        sc.Delivery_Status__c = SC_DELIVERY_STATUS;
        sc.Email_Template__c = mapStageEmailTemplate.get(stage);
        sc.Platform__c = SC_PLATFORM;
        sc.RecordTypeId = SC_RTID;
        sc.Region__c = mapSiteVariant.get(cs.Coupon__r.Main_Coupon_Site__c);
        sc.Day_Before_Reminder__c = nDayReminder;
        return sc;
    }

    /*
    * @Description: Set the email message for the Hive Support
    * @param cs Coupon Seller record
    * @return Messaging.SingleEmailMessage object
    */
    private Messaging.SingleEmailMessage setSingleEmailMessage(Coupon_Seller__c cs){

        if (owdHiveSupport == null) { return null; }

        String emailSubject = EMAIL_SUBJECT + cs.Seller__r.Name;
    	String emailBody = EMAIL_BODY + cs.Seller__r.Name + ', ' + cs.Seller__r.EBH_OracleID__c + '.\n\n'
                            + EMAIL_BODY_2;
                            
    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(owdHiveSupport.Id); // Set OWD
        mail.setToAddresses(new String[] { Label.OWD_MKT_REP }); // Recipient from Custom Label
        mail.setSubject(emailSubject);
        mail.setPlainTextBody(emailBody);
    	return mail;
    }

    global void finish(Database.BatchableContext pBc) {}

    global void execute(SchedulableContext sc) { 
        BatchCouponSellerTimeBased bat = new BatchCouponSellerTimeBased();
        Database.executeBatch(bat,200);
    }
}