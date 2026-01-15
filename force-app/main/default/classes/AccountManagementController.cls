/*********************************************************************************************************************************
@ Class:         AccountManagementController
@ Version:       1.0
@ Author:       Trigg
@ Purpose:        
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.12.2021 / vadhanak.voun (vadhanak.voun@gaea-sys.com) / US-0010561 - [AM] Store Account Manager Subscription Requests in Hive
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.12.2021 / Mony Nou (mony.nou@gaea-sys.com) / US-0010562 - [AM] Display account manager details in portal for subscribed & Platinum sellers
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 1.2.2023 / Sambath Seng (sambath.seng@gaea-sys.com) / US-0011155 - [AM]Add Account Picker to DE Book Account Manager
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011132 - ✓[AM][Bug] Fixing logic to display AM request or AM detail page
@               : 09.03.2023 / Sambath Seng / US-0013286 - [AM] - BUG - Opt-Out Effective Date - Future condition issue FIX
@               : 10.03.2023 / Mony Nou / US-0013309 - [AM] Opt-In Date and Opt-In Effective Date functionality change
@               : 07.09.2023 / Sovantheany Dim / US-0014060 - Change to the Account Manager Display Logic
@               : 17.10.2023 / Mony Nou / US-0012769 - Discontinue use of 'Without Sharing' for Deals/Coupons
@                                           - Comment out unused codes
@               : 15.Nov.2023 / Acmatac Seing / US-0014258 - 3 Pro Trader Registration Page - Registration availability and non-availability
@               : 21.12.2023 / Mony Nou / US-0014593 - Secure Coding - Tech Debt : AccountManagementController
@               : 14.05.2024 / Sophal Noch / US-0015242 - Fix Account Owner Updating to Integration User Issue
@               : 21.05.2024 / Bora Chhorn / US-0015153 - PT+ - Seller Eligible for PT+
@               : 28.04.2025 / Sophal Noch / US-0017160 - Replace OwnerId with Account_Manager__c for Seller Facing Components
@               : 15.05.2025 / Davy Sorn / US-0026115 - 2. Create a new component for Account Management / US-0012764 - 3. Add Advertising Bookings component to the Seller Portal
@               : 10.06.2025 / Davy Sorn / US-0032929 - Advertising component still not present in SP
@               : 02.07.2025 / Sophal Noch / US-0032963 - SP: Do not show Paid programs to GSD sellers
@               : 07.01.2026 / Sophal Noch / US-0033990 - UK Paid Programs - Current Subscription Overview (Step 1)
*********************************************************************************************************************************/
public with sharing class AccountManagementController {
    public final static String SOQL_COHORT_SELLER = 'SELECT Id, Name, Bob_Cohort_Name__c, Seller__c, Seller_Name__c, Managed_Type__c, EBH_BOBSegment__c, Status__c, RegistrationCloseDate__c, Account_Manager__c, Account_Manager_CalendlyLink__c FROM BoB_Seller__c ';    
    public final static String ELIGIBLE_FOR_ACCOUNT_MANAGER = 'Eligible_for_Account_Manager';
    public final static String ELIGIBLE_FOR_PROTRADER_PROGRAM = 'Eligible_for_ProTrader_Program';
    public final static String ELIGIBLE_FOR_PROTRADER_REGISTRATION = 'Eligible_for_ProTrader_Registration';
    public final static String ELIGIBLE_FOR_PROTRADER_DASHBOARD = 'Eligible_for_ProTrader_Dashboard';
    private final static String ELIGIBLE_FOR_PAID_PROGRAM = 'Eligible_for_Paid_Program'; // 07.01.2026 / Sophal Noch / US-0033990

     // DS 15.05.2025 US-0012764
    private final static String ELIGIBLE_FOR_BOOKING_ADVERTISING = 'Eligible_for_Booking_Advertising';
    private final static String ELIGIBLE_FOR_ADS_PARTNER_MANAGER = 'Booking_Portal_Eligibility';


    private final static String SOQL_CURRENTUSER= 'SELECT Id, Name, Contact.Name, Contact.Email, Contact.Account.Name, Contact.Phone, ContactId FROM User WHERE Id=: currentUserId';

    private final static String STATUS_NEW = 'New';
    private final static String COHORTSELLER_RT_MANAGED = 'Managed'; //MN-23122021-US-0010562
    private final static String STATUS_SUBSCRIBED = 'Subscribed';
    private final static String STATUS_UNSUBSCRIBE_REQUEST = 'Unsubscribe Request';
    private final static Set<String> SET_ACTIVE_SUB_REQ = new Set<String>{STATUS_NEW, STATUS_SUBSCRIBED, STATUS_UNSUBSCRIBE_REQUEST}; // 02.07.2025 / Sophal Noch / US-0032963

    private final static String SOQL_SELLER = 'Select Id, Name, EBH_StoreSubscription__c, EBH_RegistrationCountry__c, Store_Subscription_Site__c, EBH_BOBSegment__c From Account ' ; // 21-05-2024-BR-US-0015153 / Added EBH_BOBSegment__c into query
    private final static String ACCOUNT_RT_SELLER = 'EBH_Seller';

    private final static String MANAGED_TYPE_MANAGED_BOB = 'Managed BoB';
    private final static Set<String> SET_ACC_DETAIL_SUBLEVEL_WITH_SUBSCR_REQ = new Set<String>{'Anchor'};
    private final static Set<String> SET_ACC_DETAIL_SUBLEVEL_NO_SUBSCR_REQ = new Set<String>{'Platinum'};//TH:US-0014060 

    // 14.05.2024 / Sophal Noch / US-0015242 : 
    private final static Id INTEGRATION_USER_ID = (Id)ApexUtil.INTEGRATION_USER_ID;
	// private final static Id DEACTIVATION_USER_ID = (Id)(Label.Cohort_Deactivation_UserId); // 28.04.2025 / Sophal Noch / US-0017160 : no longer user deactivatation userid
	private final static Set<Id> SET_INT_USER_ID = new Set<Id>{INTEGRATION_USER_ID}; // 28.04.2025 / Sophal Noch / US-0017160 : remove DEACTIVATION_USER_ID from set

    private final static String PROGRAM_TYPE_AM = 'Account Management';
    private final static String PROGRAM_TYPE_ADS = 'Advertising';

    /* MN-21122023-US-0014593: Commented out as it is not used anymore
    @AuraEnabled(cacheable=true) 
    public static Account getStoreSubscription() {
        // let currentUser=UserInfo.getUserId();
        
        Account StoreSubscription;
        list<Contact> lstAccount=[SELECT AccountId FROM Contact where Id in (SELECT ContactId FROM User where id=:UserInfo.getUserId())];
        if(lstAccount.size()>0)
        {
            StoreSubscription= [SELECT EBH_StoreSubscription__c FROM Account where Id=:lstAccount[0].AccountId];
        }
        return StoreSubscription;
    }
    */

    /*****************************************************************************************************************************
    @ Method:   createSubscription
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0010561 - [AM] Store Account Manager Subscription Requests in Hive
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: String sellerId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.12.2021 / vadhanak.voun (vadhanak.voun@gaea-sys.com) / US-0010561 - [AM] Store Account Manager Subscription Requests in Hive
    @ Change history: 1.2.2023 / Sambath Seng / US-0011155 - [AM]Add Account Picker to DE Book Account Manager
    @ Change history: 06.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011132 - ✓[AM][Bug] Fixing logic to display AM request or AM detail page
    @                 15.Nov.2023 / Acmatac Seing / US-0014258 - 3 Pro Trader Registration Page - Registration availability and non-availability
    @                 15.05.2025 / Davy Sorn / US-0012764 - 3. Add Advertising Bookings component to the Seller Portal
    @                 02.07.2025 / Sophal Noch / US-0032963 - SP: Do not show Paid programs to GSD sellers
    @                 07.01.2026 / Sophal Noch / US-0033990 - UK Paid Programs - Current Subscription Overview (Step 1)
    *****************************************************************************************************************************/
    @AuraEnabled(cacheable=true) 
    public static Map<String,Object> getSellerInfo(String sellerId) 
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        try{
            sellerId = String.escapeSingleQuotes(sellerId);//Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager

            if(!String.isBlank(sellerId)){//Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
                Account seller = getSeller(sellerId);//Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
                
                //MN-21122023-US-0014593: Comment old code and keep it there for history purpose
                //Sobject[] ex_request = [Select Id,Status__c,Opt_Out_Effective_Date__c,Seller__r.Name FROM Subscription_Request__c WHERE Seller__c=:sellerId ORDER BY CreatedDate DESC LIMIT 1];  // 06.02.2023 / Sophal Noch / US-0011132
                
                //MN-21122023-US-0014593--START: Change query to use with ApexSafe class
                String soql = 'Select Id,Status__c,Opt_Out_Effective_Date__c,Seller__r.Name FROM Subscription_Request__c WHERE Seller__c=:sellerId ORDER BY CreatedDate DESC LIMIT 1';
                Sobject[] ex_request = ApexSafe.query().doQuery(soql,new Map<String, Object> {'sellerId' => sellerId});
                //MN-21122023-US-0014593--END

                Boolean hasActiveSubReq = false; // 02.07.2025 / Sophal Noch / US-0032963
                String optOutEftDateFormat = '';
                if(!ex_request.isEmpty()) {
                    Subscription_Request__c sr = (Subscription_Request__c)ex_request[0];
                    optOutEftDateFormat = sr.Opt_Out_Effective_Date__c != null ? sr.Opt_Out_Effective_Date__c.format() : '';   // 06.02.2023 / Sophal Noch / US-0011132 use format date so it is depend on locale
                    hasActiveSubReq = SET_ACTIVE_SUB_REQ.contains(sr.Status__c); // 02.07.2025 / Sophal Noch / US-0032963 : subscription request is active when status is in (New, Subscribed, Unsubscribe Request)
                }
                mapResult.put('optOutEftDate',optOutEftDateFormat);
                mapResult.put('account',seller);//Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
                mapResult.put('subscription',ex_request);

                // Checking if seller is part of Protrader registration program
                Boolean isEligibleFor_Protrader_Program = checkEligibilityFor_Protrader_Program(sellerId);
                // END of checking if seller is part of Protrader registration

                Boolean isEligibleFor_Booking_Advertising = checkEligibilityFor_Booking_Advertising(sellerId); // DS 15.05.2025 US-0012764
                Boolean isEligibleFor_Booking_AdsPartnerManager = checkEligibilityFor_Booking_AdsPartnerManager(sellerId); // DS 27.05.2025 US-0012764

                // 15.Nov.2023 / Acmatac Seing / US-0014258
                // Checking if seller is part of Account Manager program
                Boolean isEligibleFor_BookAM = (hasActiveSubReq || !isEligibleFor_Booking_Advertising) ? checkEligibilityFor_BookAM(sellerId) : false; // 02.07.2025 / Sophal Noch / US-0032963 : add checking Seller is part of Active Subscription Request OR is Not part of GSD AM for show BookAM
                // END of checking if seller is part of Account Manager program

                Boolean isEligibleFor_PaidProgram = checkEligibilityFor_PaidProgram(sellerId); // 07.01.2026 / Sophal Noch / US-0033990

                mapResult.put('eligibleFor_BookAM', isEligibleFor_BookAM);
                mapResult.put('eligibleFor_Protrader_Program', isEligibleFor_Protrader_Program);
                mapResult.put('eligibleFor_Booking_Advertising', isEligibleFor_Booking_Advertising); // DS 15.05.2025 US-0012764
                mapResult.put('eligibleFor_Booking_AdsPartnerManager', isEligibleFor_Booking_AdsPartnerManager); // DS 27.05.2025 US-0012764
                mapResult.put('eligibleFor_PaidProgram', isEligibleFor_PaidProgram);  // 07.01.2026 / Sophal Noch / US-0033990
                
                String selectedCohortSellerForAM;
                if(isEligibleFor_Booking_Advertising){
                    selectedCohortSellerForAM = getCohortSellerBySellerIdAndProgramType(sellerId, PROGRAM_TYPE_AM);
                }
                String selectedCohortSellerForAds;
                if(isEligibleFor_Booking_AdsPartnerManager){
                    selectedCohortSellerForAds = getCohortSellerBySellerIdAndProgramType(sellerId, PROGRAM_TYPE_ADS);
                }

                mapResult.put('selectedCohortSellerForAM', selectedCohortSellerForAM);
                mapResult.put('selectedCohortSellerForAds', selectedCohortSellerForAds);
                mapResult.put('status','ok');
            }
        }catch(Exception ex)
        {
            mapResult.put('status','ko'); mapResult.put('error',ex.getMessage()); mapResult.put('error_detail',ex.getStackTraceString());
        }
        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:   getActiveCohortSeller
    @ Version:  1.0
    @ Author:   Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:  US-0010562 - [AM] Display account manager details in portal for subscribed & Platinum sellers
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 23.12.2021 / Mony Nou (mony.nou@gaea-sys.com) / US-0010562 - [AM] Display account manager details in portal for subscribed & Platinum sellers
    @               : 06.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011132 - ✓[AM][Bug] Fixing logic to display AM request or AM detail page
    @               : 07.09.2023 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) US-0014060 - Change to the Account Manager Display Logic
    @               : 21.12.2023 / Mony Nou / US-0014593 - Secure Coding - Tech Debt : AccountManagementController
    @               : 14.05.2024 / Sophal Noch / US-0015242 - Fix Account Owner Updating to Integration User Issue
    @               : 28.04.2025 / Sophal Noch / US-0017160 - Replace OwnerId with Account_Manager__c for Seller Facing Components
    *****************************************************************************************************************************/
    @AuraEnabled(cacheable=true) 
    public static Map<String,Object> getActiveCohortSeller(String sellerId) {

        Map<String,Object> mapResult = new Map<String,Object>();

        if (String.isNotBlank(sellerId)) { //MN-21122023-US-0014593: Add null check for sellerId

            sellerId = String.escapeSingleQuotes(sellerId);
            
            //MN-21122023-US-0014593--START: Change query to use with ApexSafe class
            String soql = 'Select Id, Account_Manager__c, EBH_StoreSubscription__c, EBH_BOBManaged__c, Managed_Type__c  From Account Where Id =: sellerId Limit 1'; // 28.04.2025 / Sophal Noch / US-0017160 : replace OwnerId with Account_Manager__c
            List<Account> listAccount = (List<Account>) ApexSafe.query().doQuery(soql,new Map<String, Object> {'sellerId' => sellerId});
            //MN-21122023-US-0014593--END

            if(listAccount.isEmpty()) return mapResult;
            Account sellerRecord = listAccount[0];
            String accMgmntId;
            String sWhere = '';
            Sobject[] ex_request;

            if(SET_ACC_DETAIL_SUBLEVEL_NO_SUBSCR_REQ.contains(sellerRecord.EBH_StoreSubscription__c)){ // 09.02.2023 / Sophal Noch / US-0011132 : for level 'Platinum', 'Super Anchor Plan', we don't need Subscription_Request__c.
                //TH:US-0014060:AC1: remove sellerRecord.Managed_Type__c == MANAGED_TYPE_MANAGED_BOB from condition
                // if(sellerRecord.EBH_BOBManaged__c && !SET_INT_USER_ID.contains(sellerRecord.OwnerId)){ // 14.05.2024 / Sophal Noch / US-0015242 : use set id to check seller owner is not integration user
                if(sellerRecord.EBH_BOBManaged__c && String.isNotBlank(sellerRecord.Account_Manager__c) && !SET_INT_USER_ID.contains(sellerRecord.Account_Manager__c)){ // 28.04.2025 / Sophal Noch / US-0017160 : use replace OwnerId with Account_Manager__c to check in condition to find account manager
                    // accMgmntId = sellerRecord.OwnerId;
                    accMgmntId = sellerRecord.Account_Manager__c; // 28.04.2025 / Sophal Noch / US-0017160
                }
            }else{
                //MN-21122023-US-0014593--START: Change query to use with ApexSafe class
                soql = 'Select Seller__r.Account_Manager__c FROM Subscription_Request__c WHERE Seller__c =:sellerId AND Seller__c != null AND Seller__r.EBH_BOBManaged__c = true AND Seller__r.Account_Manager__c != null AND Seller__r.Account_Manager__c NOT IN :intUser ORDER BY CreatedDate DESC LIMIT 1'; // 14.05.2024 / Sophal Noch / US-0015242 : use set id in query,  // 28.04.2025 / Sophal Noch / US-0017160 : replace Seller__r.OwnerId with Seller__r.Account_Manager__c
                ex_request = ApexSafe.query().doQuery(soql,new Map<String, Object> {'sellerId' => sellerRecord.Id, 'intUser' => SET_INT_USER_ID}); // 14.05.2024 / Sophal Noch / US-0015242 : use set to check seller owner is not integration user
                //MN-21122023-US-0014593--END
                for (Subscription_Request__c sr : (List<Subscription_Request__c>) ex_request) { 
                    // accMgmntId = sr.Seller__r.OwnerId; // 06.02.2023 / Sophal Noch / US-0011132
                    accMgmntId =  sr.Seller__r.Account_Manager__c; // 28.04.2025 / Sophal Noch / US-0017160
                }
            }
            
            User accMgmntUsr = new User();

            if (String.isNotBlank(accMgmntId)) {
                // String soqlUser = 'SELECT Id, Name, FirstName, MiddleName, LastName, Email, Phone FROM User';
                String soqlUser = 'SELECT Id, Name, FirstName, MiddleName, LastName, Email, Customer_facing_eMail__c, Phone, FullPhotoUrl, MediumPhotoUrl, IsProfilePhotoActive FROM User';  // 06.02.2023 / Sophal Noch / US-0011132
                sWhere = ' WHERE Id='+ ApexUtil.closeSQoute(accMgmntId);

                //MN-21122023-US-0014593: We must use WithoutSharing in here because we need to get the Account Manager's information record of the seller that the current SEP User do not have access on
                ex_request = WithoutSharing.doQuery(soqlUser, sWhere, ''); 

                if (!ex_request.isEmpty()) accMgmntUsr = (User)  ex_request[0];
            }
            
            mapResult.put('accountMgmtInfo',accMgmntUsr);

        } //MN-21122023-US-0014593
        

        return mapResult;

    }


    /*****************************************************************************************************************************
    @ Method:   createSubscription
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0010561 - [AM] Store Account Manager Subscription Requests in Hive
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: String sellerId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.12.2021 / vadhanak.voun (vadhanak.voun@gaea-sys.com) / US-0010561 - [AM] Store Account Manager Subscription Requests in Hive
    @ Change history: 1.2.2023 / Sambath Seng / US-0011155 - [AM]Add Account Picker to DE Book Account Manager
    @               : 10.03.2023 / Mony Nou / US-0013309 - [AM] Opt-In Date and Opt-In Effective Date functionality change
    @               : 21.12.2023 / Mony Nou / US-0014593 - Secure Coding - Tech Debt : AccountManagementController
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> createSubscription(String sellerId) 
    {
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ko'}; //MN-21122023-US-0014593: Add default value for status = ko

        if (String.isNotBlank(sellerId)) { //MN-21122023-US-0014593: Add null check for sellerId

            sellerId = String.escapeSingleQuotes(sellerId);//Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager

            RecordType rt_AM = ApexUtil.getRecordTypeByName('Subscription_Request__c', 'Account_Manager');
            
            /* MN-21122023-US-0014593: Comment old code and keep it there for history purpose
            User currentUser = [Select ContactId,Contact.AccountId From User Where Id=:UserInfo.getUserId()];
            */

            //MN-21122023-US-0014593--START: Change query to use with ApexSafe class
            User currentUser = new User();
            String soql = 'Select ContactId,Contact.AccountId From User Where Id=:userId';
            List<User> lstUsers = (List<User>) ApexSafe.query().doQuery(soql,new Map<String, Object> {'userId' => UserInfo.getUserId()});
            if (!lstUsers.isEmpty()) currentUser = lstUsers[0];
            //MN-21122023-US-0014593--END

            Subscription_Request__c s_request = new Subscription_Request__c
            (
                Request_Date__c =  Date.today(),
                //Opt_In_Effective_Date__c = Date.today().addMonths(1).toStartOfMonth(),    //is set to the first day of the next calendar month //MN-10032023-US-0013309:AC1 remove it 
                Opt_In_Date__c = Date.today().addMonths(1).toStartOfMonth(), //MN-10032023-US-0013309     
                Status__c = STATUS_NEW,
                Requestor__c = currentUser.ContactId ,
                // Seller__c = currentUser.Contact.AccountId,
                Seller__c = sellerId, //Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
                CurrencyIsoCode = 'EUR',
                RecordTypeId  = rt_AM.Id

            );

            try 
            {
                //MN-21122023-US-0014593: Remove WithouSharing.doInsert() since SEP user now have access to create Subscription Request record via Permission Set "Seller Portal - Monetization" (US-0011012)
                //WithoutSharing.doInsert(new List<SObject>{s_request});
                Database.SaveResult[] result = ApexSafe.dml().doInsert(new List<SObject>{s_request}, true); //MN-21122023-US-0014593
                
                /* MN-21122023-US-0014593: Comment old code and keep it there for history purpose
                mapResult.put('status','ok'); //MN-21122023-US-0014593: Add status = ok
                mapResult.put('recordId',s_request.Id);
                */

                if (result[0].isSuccess()) {
                    mapResult.put('status','ok'); //MN-21122023-US-0014593: Add status = ok
                    mapResult.put('recordId',result[0].getId());
                } else {
                    mapResult.put('status','ko'); mapResult.put('error',result[0].getErrors()[0].getMessage()); mapResult.put('error_detail',result[0].getErrors()[0].getMessage());
                }
                
            }catch(Exception ex) { //MN-21122023-US-0014593: Add Exception handling
                mapResult.put('status','ko'); mapResult.put('error',ex.getMessage()); mapResult.put('error_detail',ex.getStackTraceString());
            }
            /* MN-21122023-US-0014593: Comment old code and keep it there for history purpose
            catch(DmlException dex)
            {
                mapResult.put('status','ko'); mapResult.put('error',dex.getDmlMessage(0)); mapResult.put('error_detail',dex.getMessage());
            }*/

        } //MN-21122023-US-0014593

        
        return mapResult;
    }

      /*****************************************************************************************************************************
    @ Method:   requestUnsubscription
    @ Version:  1.0
    @ Author:   Loumang SENG (loumang.seng@gaea-sys.com)
    @ Purpose:  
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: String sellerId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.12.2021 / Loumang SENG (loumang.seng@gaea-sys.com) / US-0010562 - [AM] Display account manager details in portal for subscribed & Platinum sellers
    @ Change history: 1.2.2023 / Sambath Seng / US-0011155 - [AM]Add Account Picker to DE Book Account Manager
    @ Change history: 06.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011132 - ✓[AM][Bug] Fixing logic to display AM request or AM detail page
    @               : 09.03.2023 / Sambath Seng / US-0013286 - [AM] - BUG - Opt-Out Effective Date - Future condition issue FIX
    @               : 21.12.2023 / Mony Nou / US-0014593 - Secure Coding - Tech Debt : AccountManagementController
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> requestUnsubscription(String sellerId) {

        Map<String,Object>  mapResult = new Map<String,Object>();
        mapResult.put('status','ko'); //MN-21122023-US-0014593: Add default value for status = ko

        if (String.isNotBlank(sellerId)) { //MN-21122023-US-0014593: Add null check for sellerId

            try 
            {
                sellerId = String.escapeSingleQuotes(sellerId);//Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
                RecordType rt_AM = ApexUtil.getRecordTypeByName('Subscription_Request__c', 'Account_Manager');
                // User currentUser = [Select ContactId,Contact.AccountId From User Where Id=:UserInfo.getUserId()];
                // List<Subscription_Request__c> listSubscription = [SELECT Id,Earliest_Unsubscribe_Date__c,Opt_Out_Date__c,Opt_Out_Effective_Date__c,Status__c FROM Subscription_Request__c WHERE Status__c=:STATUS_SUBSCRIBED AND RecordTypeId=:rt_AM.Id AND Seller__c =: currentUser.Contact.AccountId];
                /* MN-21122023-US-0014593: Comment old code and keep it there for history purpose
                List<Subscription_Request__c> listSubscription = [SELECT Id,Earliest_Unsubscribe_Date__c,Opt_Out_Date__c,Opt_Out_Effective_Date__c,Status__c FROM Subscription_Request__c WHERE Status__c=:STATUS_SUBSCRIBED AND RecordTypeId=:rt_AM.Id AND Seller__c =: sellerId]; //Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
                */

                //MN-21122023-US-0014593--START: Change query to use with ApexSafe class
                String soql = 'SELECT Id,Earliest_Unsubscribe_Date__c,Opt_Out_Date__c,Opt_Out_Effective_Date__c,Status__c FROM Subscription_Request__c WHERE Status__c=:STATUS_SUBSCRIBED AND RecordTypeId=:rt_AM AND Seller__c =: sellerId';
                List<Subscription_Request__c> listSubscription = (List<Subscription_Request__c>) ApexSafe.query().doQuery(soql,new Map<String, Object> {'STATUS_SUBSCRIBED' => STATUS_SUBSCRIBED, 'rt_AM' => rt_AM.Id, 'sellerId' => sellerId});
                //MN-21122023-US-0014593--END

                Date currentDate = Date.today();

                /* MN-21122023-US-0014593: Comment old code and keep it there for history purpose
                User currentUser = [Select Id,ContactId From User Where Id=:UserInfo.getUserId()];  // 06.02.2023 / Sophal Noch / US-0011132
                */
                //MN-21122023-US-0014593--START: Change query to use with ApexSafe class
                User currentUser = new User();
                soql = 'Select Id,ContactId From User Where Id=:userId';
                List<User> lstUsers = (List<User>) ApexSafe.query().doQuery(soql,new Map<String, Object> {'userId' => UserInfo.getUserId()});
                if (!lstUsers.isEmpty()) currentUser = lstUsers[0];
                //MN-21122023-US-0014593--END

                for (Subscription_Request__c sr : listSubscription) {

                    // if(sr.Earliest_Unsubscribe_Date__c < Date.today() && sr.Earliest_Unsubscribe_Date__c != null){
                    if(sr.Earliest_Unsubscribe_Date__c != null && (sr.Earliest_Unsubscribe_Date__c < Date.today() || 
                    (sr.Earliest_Unsubscribe_Date__c > Date.today() && sr.Earliest_Unsubscribe_Date__c.month() == currentDate.month() && sr.Earliest_Unsubscribe_Date__c.year() == currentDate.year()))
                    ){//SB 9.3.2023 US-0013286 - [AM] - BUG - Opt-Out Effective Date - Future condition issue FIX

                        sr.Opt_Out_Effective_Date__c = currentDate.addMonths(2).toStartOfMonth().addDays(-1);
                        
                    }else{
                        sr.Opt_Out_Effective_Date__c = sr.Earliest_Unsubscribe_Date__c;
                    }
                    sr.Status__c = STATUS_UNSUBSCRIBE_REQUEST;
                    sr.Opt_Out_Date__c = currentDate;
                    sr.Requestor__c = currentUser.ContactId;  // 06.02.2023 / Sophal Noch / US-0011132
                    

                }
                //MN-21122023-US-0014593: Remove WithouSharing.doUpdate() since SEP user now have access to update Subscription Request record via Permission Set "Seller Portal - Monetization" (US-0011012)
                //WithoutSharing.doUpdate(listSubscription);

                Database.SaveResult[] result = ApexSafe.dml().doUpdate(listSubscription, true); //MN-21122023-US-0014593
                /* MN-21122023-US-0014593: Comment old code and keep it there for history purpose
                mapResult.put('status','ok');
                */
                if (result[0].isSuccess()) {
                    mapResult.put('status','ok'); //MN-21122023-US-0014593: Add status = ok
                } else {
                    mapResult.put('status','ko'); mapResult.put('error',result[0].getErrors()[0].getMessage()); mapResult.put('error_detail',result[0].getErrors()[0].getMessage());
                }

            }catch (Exception ex) { //MN-21122023-US-0014593
                mapResult.put('status','ko'); mapResult.put('error',ex.getMessage()); mapResult.put('error_detail',ex.getStackTraceString());
            }
            /* //MN-21122023-US-0014593: Comment old code and keep it there for history purpose
            catch(DmlException dex)
            {
                mapResult.put('status','ko'); mapResult.put('error',dex.getDmlMessage(0)); mapResult.put('error_detail',dex.getMessage());
            }
            */

        } //MN-21122023-US-0014593
        
        return mapResult;

    }

    /*****************************************************************************************************************************
    @ Method:   getAllAccounts
    @ Version:  1.0
    @ Author:   Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:  US-0011155 - [AM]Add Account Picker to DE Book Account Manager
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 1.2.2023 / Sambath Seng / US-0011155 - [AM]Add Account Picker to DE Book Account Manager
    @                   15.Nov.2023 / Acmatac Seing / US-0014258 - 3 Pro Trader Registration Page - Registration availability and non-availability
    @                   21.12.2023 / Mony Nou / US-0014593 - Secure Coding - Tech Debt : AccountManagementController
    @                   10.05.2025 / Davy Sorn / US-0032929 - Advertising component still not present in SP
    @                   07.01.2026 / Sophal Noch / US-0033990 - UK Paid Programs - Current Subscription Overview (Step 1)
    *****************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getAllAccounts(){
        Map<String,Object> mapResult = new Map<String,Object>();
        
        /* MN-21122023-US-0014593: Comment old code and keep it there for history purpose
        User currentUser = [Select Id,UserName,Email,ContactId,Contact.RecordType.DeveloperName,Contact.AccountId,Contact.Account.OwnerId,Federated_Login__c From User Where Id=:UserInfo.getUserId()];
        */

        //MN-21122023-US-0014593--START: Change query to use with ApexSafe class
        User currentUser = new User();
        String soql = 'Select Id,UserName,Email,ContactId,Contact.RecordType.DeveloperName,Contact.AccountId,Contact.Account.OwnerId,Federated_Login__c From User Where Id=:userId';
        List<User> lstUsers = (List<User>) ApexSafe.query().doQuery(soql,new Map<String, Object> {'userId' => UserInfo.getUserId()});
        if (!lstUsers.isEmpty()) currentUser = lstUsers[0];
        //MN-21122023-US-0014593--END

        Map<String, Seller_Portal_Setting__mdt> mapEligibleAccounts = getSPMetadata(new Set<String>{ELIGIBLE_FOR_ACCOUNT_MANAGER, ELIGIBLE_FOR_PROTRADER_PROGRAM, ELIGIBLE_FOR_BOOKING_ADVERTISING, ELIGIBLE_FOR_PAID_PROGRAM}); //DS 15.05.2025 US-0012764,  07.01.2026 / Sophal Noch / US-0033990

        // List Id off Accounts to show in Account Picker
        Set<Id> eligibleAccIds = new Set<Id>();
        Set<Id> getAllAccountIdsRelated = getAllAccountIdsRelated(currentUser.ContactId);
        // Checking if seller is part of Account Manager program
        if(mapEligibleAccounts.containsKey(ELIGIBLE_FOR_ACCOUNT_MANAGER)){
            Seller_Portal_Setting__mdt eligibleForAM = mapEligibleAccounts.get(ELIGIBLE_FOR_ACCOUNT_MANAGER);

            //MN-21122023-US-0014593--START: Change query to use with ApexSafe class 
            soql = 'SELECT Id FROM Account WHERE ' + eligibleForAM.Filter_Values__c + ' AND Id IN :getAllAccountIdsRelated';
            List<Account> lstAccount = (List<Account>) ApexSafe.query().doQuery(soql, new Map<String, Object>{'getAllAccountIdsRelated' => getAllAccountIdsRelated});
            for(Account oAcc: lstAccount) {
                eligibleAccIds.add(oAcc.Id);
            }
            //MN-21122023-US-0014593--END
            
        }
        // 15.Nov.2023 / Acmatac Seing / US-0014258

        Map<Id, BoB_Seller__c> mapCohortSeller = new Map<Id, BoB_Seller__c>();
        mapCohortSeller.putAll(getSellerCohort(mapEligibleAccounts, getAllAccountIdsRelated, ELIGIBLE_FOR_PROTRADER_PROGRAM));
        mapCohortSeller.putAll(getSellerCohort(mapEligibleAccounts, getAllAccountIdsRelated, ELIGIBLE_FOR_BOOKING_ADVERTISING));
        Map<String, Portal_Eligibility__mdt> mapEligibleBooking = CalendlyBookingAdsController.getBookingPortalMetadata(new Set<String>{ELIGIBLE_FOR_ADS_PARTNER_MANAGER}); //DS 10.06.2025 US-0032929
        mapCohortSeller.putAll(getSellerCohort(mapEligibleBooking, getAllAccountIdsRelated, ELIGIBLE_FOR_ADS_PARTNER_MANAGER));
        mapCohortSeller.putAll(getSellerCohort(mapEligibleAccounts, getAllAccountIdsRelated, ELIGIBLE_FOR_PAID_PROGRAM)); // 07.01.2026 / Sophal Noch / US-0033990
        
        eligibleAccIds.addAll(mapCohortSeller.keySet());
        mapResult.put('listEligibleAccount', [SELECT Id, Name From Account Where Id in :eligibleAccIds]);
        mapResult.put('mapCohortSeller', mapCohortSeller);
        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:   getCohortSellerBySellerIdAndProgramType
    @ Version:  1.0
    @ Author:   Davy Sorn
    @ Purpose:  US-0032929 - Advertising component still not present in SP
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: sellerId
    @ Parameter: programType
    @ Returns:  Map<String,Object>
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 23.06.2025 / Davy Sorn / US-0032929 - Advertising component still not present in SP
    *****************************************************************************************************************************/
    @TestVisible
    private static String getCohortSellerBySellerIdAndProgramType(String sellerId, String programType){
        Map<Id, BoB_Seller__c> mapCohortSeller = new Map<Id, BoB_Seller__c>();
        Set<Id> getAllAccountIdsRelated = new Set<Id> {sellerId}; //getAllAccountIdsRelated(currentUser.ContactId);
        if (programType == PROGRAM_TYPE_AM) {
            Map<String, Seller_Portal_Setting__mdt> mapEligibleAccounts = getSPMetadata(new Set<String>{ELIGIBLE_FOR_BOOKING_ADVERTISING});
            mapCohortSeller.putAll(getSellerCohort(mapEligibleAccounts, getAllAccountIdsRelated, ELIGIBLE_FOR_BOOKING_ADVERTISING)); //Account Management (AM)
        } else if (programType == PROGRAM_TYPE_ADS) {
            Map<String, Portal_Eligibility__mdt> mapEligibleBooking = CalendlyBookingAdsController.getBookingPortalMetadata(new Set<String>{ELIGIBLE_FOR_ADS_PARTNER_MANAGER});
            mapCohortSeller.putAll(getSellerCohort(mapEligibleBooking, getAllAccountIdsRelated, ELIGIBLE_FOR_ADS_PARTNER_MANAGER)); //Advertising
        }
        String cohortSellerId = '';
        if (!mapCohortSeller.isEmpty()) {
            BoB_Seller__c cohortSeller = mapCohortSeller.get(sellerId);
            cohortSellerId = cohortSeller.Id;
        }
        return cohortSellerId;
    }

    /*****************************************************************************************************************************
    @ Method:   getSellerCohort
    @ Version:  1.0
    @ Author:   Davy Sorn (davy.sorn@gaea-sys.com)
    @ Purpose:  US-0032929 - Advertising component still not present in SP
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: Map<String, SObject> mapEligibleAccounts
    @ Parameter: Set<Id> getAllAccountIdsRelated
    @ Parameter: String eligibleKey
    @ Return: Map<Id, BoB_Seller__c>
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.05.2025 / Davy Sorn / US-0032929 - Advertising component still not present in SP
    @               : 07.01.2026 / Sophal Noch / US-0033990 - UK Paid Programs - Current Subscription Overview (Step 1)
    *****************************************************************************************************************************/
    public static Map<Id, BoB_Seller__c> getSellerCohort(Map<String, SObject> mapEligibleAccounts, Set<Id> getAllAccountIdsRelated, String eligibleKey) {
        // 07.01.2026 / Sophal Noch / US-0033990 : make method public so it could be reused in PaidProgramController
        Map<Id, BoB_Seller__c> mapCohortSeller = new Map<Id, BoB_Seller__c>();
        Set<Id> eligibleAccIds = getAllAccountIdsRelated;
        if (mapEligibleAccounts.containsKey(eligibleKey)) {
            SObject eligibleRecord = mapEligibleAccounts.get(eligibleKey);  //DS 10.06.2025 US-0032929
            String strFilter = '';
            if (eligibleRecord instanceof Seller_Portal_Setting__mdt) {
                Seller_Portal_Setting__mdt spsProtraderEligible = (Seller_Portal_Setting__mdt) eligibleRecord;
                strFilter = spsProtraderEligible.Filter_Values__c;
            } else if (eligibleRecord instanceof Portal_Eligibility__mdt) { 
                Portal_Eligibility__mdt bookingPortalEligible = (Portal_Eligibility__mdt) eligibleRecord;
                strFilter = bookingPortalEligible.Eligibility_Criteria__c;
            }
            if (String.isNotEmpty(strFilter)) {
                String soql = SOQL_COHORT_SELLER + ' WHERE ' + strFilter + ' AND Seller__c IN :eligibleAccIds';
                List<BoB_Seller__c> lstBobSeller = (List<BoB_Seller__c>) ApexSafe.query().doQuery(soql, new Map<String, Object>{'eligibleAccIds' => eligibleAccIds});
                for(BoB_Seller__c oBS: lstBobSeller) {
                    mapCohortSeller.put(oBS.Seller__c, oBS);
                }
            }
        }
        return mapCohortSeller;
    }

    /*****************************************************************************************************************************
    @ Method:   getSeller
    @ Version:  1.0
    @ Author:   Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:  US-0011155 - [AM]Add Account Picker to DE Book Account Manager
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: String accId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 1.2.2023 / Sambath Seng / US-0011155 - [AM]Add Account Picker to DE Book Account Manager
    @                   21.12.2023 / Mony Nou / US-0014593 - Secure Coding - Tech Debt : AccountManagementController
    *****************************************************************************************************************************/
    public static Account getSeller(String accId)
    {  
        /* MN-21122023-US-0014593: Comment old code and keep it there for history purpose
        accId = String.escapeSingleQuotes(accId);
        return Database.query(SOQL_SELLER+' WHERE Id =:accId');
        */

        //MN-21122023-US-0014593--START: 
        Account acc = new Account(); //MN-21122023-US-0014593: Add default value for acc

        if (String.isNotBlank(accId)) { //MN-21122023-US-0014593: Add null check for accId

            accId = String.escapeSingleQuotes(accId);

            //Change query to use with ApexSafe class 
            String soql = SOQL_SELLER+' WHERE Id =:accId';
            List<Account> lstAccount = (List<Account>) ApexSafe.query().doQuery(soql, new Map<String, Object>{'accId' => accId});
            
            if (!lstAccount.isEmpty()) acc = lstAccount[0];
            

            

        } 
        //MN-21122023-US-0014593--END

        return acc;
    }

    /*****************************************************************************************************************************
    @ Method:   getAllAccountIdsRelated
    @ Version:  1.0
    @ Author:   Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:  US-0014258 Ph 1 - 3 Pro Trader Registration Page - Registration availability and non-availability
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: String contactId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.11.2023 / Acmatac Seing / US-0014258 Ph 1 - 3 Pro Trader Registration Page - Registration availability and non-availability
    @                   21.12.2023 / Mony Nou / US-0014593 - Secure Coding - Tech Debt : AccountManagementController
    *****************************************************************************************************************************/
    public static Set<Id> getAllAccountIdsRelated(String contactId)
    {
        Set<Id> accIds = new Set<Id>();

        if (String.isNotBlank(contactId)) { //MN-21122023-US-0014593: Add null check for contactId

            String sQuery = 'Select Id,AccountId,Account.Name,Account.SP_Coupons__c,Account.SP_Deals__c,Contact.Name,Contact.Email,ContactId,IsActive From AccountContactRelation';
            String sWhere = ' Where Account.RecordType.DeveloperName ='+ApexUtil.closeSQoute(ACCOUNT_RT_SELLER)+' and ContactId='+ApexUtil.closeSQoute(contactId);

            /* MN-21122023-US-0014593: Comment old code and keep it there for history purpose
            for(AccountContactRelation acr : (List<AccountContactRelation>) Database.query(sQuery + sWhere)) {
                accIds.add(acr.AccountId);
            }
            */

            //MN-21122023-US-0014593--START: Change query to use with ApexSafe class 
            String soql = sQuery + sWhere;
            List<AccountContactRelation> lstAccConRel = (List<AccountContactRelation>) ApexSafe.query().doQuery(soql);
            for(AccountContactRelation acr : lstAccConRel) {
                accIds.add(acr.AccountId);
            }
            //MN-21122023-US-0014593--END

        } //MN-21122023-US-0014593

        return accIds;
    }
    /*****************************************************************************************************************************
    @ Method:   getSPMetadata
    @ Version:  1.0
    @ Author:   Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:  US-0014258 Ph 1 - 3 Pro Trader Registration Page - Registration availability and non-availability
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.11.2023 / Acmatac Seing / US-0014258 Ph 1 - 3 Pro Trader Registration Page - Registration availability and non-availability
    @                 21.12.2023 / Mony Nou / US-0014593 - Secure Coding - Tech Debt : AccountManagementController
    *****************************************************************************************************************************/
    public static Map<String, Seller_Portal_Setting__mdt> getSPMetadata(Set<String> metaDataRecord){
        Map<String, Seller_Portal_Setting__mdt> mapEligibleAccounts = new Map<String, Seller_Portal_Setting__mdt>();

        if (!metaDataRecord.isEmpty()) { //MN-21122023-US-0014593: Add null check for metaDataRecord
            for(Seller_Portal_Setting__mdt oSps: [SELECT Id,DeveloperName,Filter_Values__c FROM Seller_Portal_Setting__mdt WHERE DeveloperName IN:metaDataRecord]){
                mapEligibleAccounts.put(oSps.DeveloperName, oSps);
            }
        } //MN-21122023-US-0014593

        
        return mapEligibleAccounts;
    }

    public static Boolean checkEligibilityFor_BookAM(String sellerId){
        return checkingEligibility(ELIGIBLE_FOR_ACCOUNT_MANAGER, 'Account', 'Id ='+ApexUtil.closeSQoute(sellerId));
    }
    public static Boolean checkEligibilityFor_Protrader_Program(String sellerId){
        return checkingEligibility(ELIGIBLE_FOR_PROTRADER_PROGRAM, 'BoB_Seller__c', 'Seller__c ='+ApexUtil.closeSQoute(sellerId));
    }
    public static Boolean checkEligibilityFor_Booking_Advertising(String sellerId){
        return checkingEligibility(ELIGIBLE_FOR_BOOKING_ADVERTISING, 'BoB_Seller__c', 'Seller__c ='+ApexUtil.closeSQoute(sellerId));
    }
    private static Boolean checkEligibilityFor_PaidProgram(String sellerId){ // 07.01.2026 / Sophal Noch / US-0033990 : check eligibility of active cohort seller for Paid Program
        return checkingEligibility(ELIGIBLE_FOR_PAID_PROGRAM, 'BoB_Seller__c', 'Seller__c ='+ApexUtil.closeSQoute(sellerId));
    }

    /*****************************************************************************************************************************
    @ Method:   checkEligibilityFor_Booking_AdsPartnerManager
    @ Version:  1.0
    @ Author:   Davy Sorn (davy.sorn@gaea-sys.com)
    @ Purpose:  US-0032929 - Advertising component still not present in SP
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: String sellerId
    @ Return: Boolean
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.05.2025 / Davy Sorn / US-0032929 - Advertising component still not present in SP
    *****************************************************************************************************************************/
    public static Boolean checkEligibilityFor_Booking_AdsPartnerManager(String sellerId){   //DS 10.06.2025 US-0032929
        return checkingEligibility(ELIGIBLE_FOR_ADS_PARTNER_MANAGER, 'BoB_Seller__c', 'Seller__c ='+ApexUtil.closeSQoute(sellerId));
    }
    public static Boolean checkEligibilityFor_RegistrationCat(String cohortSellerId){
        return checkingEligibility(ELIGIBLE_FOR_PROTRADER_REGISTRATION, 'BoB_Seller__c', 'Id ='+ApexUtil.closeSQoute(cohortSellerId));
    }
    public static Boolean checkEligibilityFor_CatDashboard(String cohortSellerId){
        return checkingEligibility(ELIGIBLE_FOR_PROTRADER_DASHBOARD, 'BoB_Seller__c', 'Id ='+ApexUtil.closeSQoute(cohortSellerId));
    }

    /*****************************************************************************************************************************
    @ Method:   checkingEligibility
    @ Version:  1.0
    @ Author:   Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:  US-0014258 Ph 1 - 3 Pro Trader Registration Page - Registration availability and non-availability
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.11.2023 / Acmatac Seing / US-0014258 created this method
    @                 21.12.2023 / Mony Nou / US-0014593 - Secure Coding - Tech Debt : AccountManagementController
    @                 10.05.2025 / Davy Sorn / US-0032929 - Advertising component still not present in SP
    *****************************************************************************************************************************/
    private static Boolean checkingEligibility(String metaDataRecord, String targetSObject, String whereId){
        Boolean isEligible = false;
        if (String.isNotBlank(metaDataRecord) && String.isNotBlank(targetSObject) && String.isNotBlank(whereId)) { //MN-21122023-US-0014593: Add null check for metaDataRecord, targetSObject, whereId
            Map<String,SObject> mapEligibleSpMDT = getSPMetadata(new Set<String>{metaDataRecord}); //DS 10.06.2025 US-0032929
            Map<String,SObject> mapEligibleBookingMDT = CalendlyBookingAdsController.getBookingPortalMetadata(new Set<String>{metaDataRecord});
            Map<String,SObject> mapEligibleMDT = new Map<String,SObject>();
            mapEligibleMDT.putAll(mapEligibleSpMDT);
            mapEligibleMDT.putAll(mapEligibleBookingMDT);
            if(mapEligibleMDT.containsKey(metaDataRecord)){
                String strFilter = '';                
                SObject eligibleForAM = mapEligibleMDT.get(metaDataRecord);
                if (eligibleForAM instanceof Seller_Portal_Setting__mdt) {
                    Seller_Portal_Setting__mdt spMDT = (Seller_Portal_Setting__mdt) eligibleForAM;
                    strFilter = spMDT.Filter_Values__c;
                } else if (eligibleForAM instanceof Portal_Eligibility__mdt) {
                    Portal_Eligibility__mdt pMDT = (Portal_Eligibility__mdt) eligibleForAM;
                    strFilter = pMDT.Eligibility_Criteria__c;
                }
                Integer countRec = 0;
                if (String.isNotEmpty(strFilter)) {
                    String soql = 'SELECT COUNT() FROM ' + targetSObject + ' WHERE ' + strFilter + ' AND ' + whereId + ' LIMIT 1';
                    countRec = ApexSafe.query().doCount(soql);
                }
                isEligible = countRec > 0;
            }
        } //MN-21122023-US-0014593
        
        return isEligible;
    }
    /*****************************************************************************************************************************
    @ Method:   getAccountManagementMetadata
    @ Author:   Acmatac Seing
    @ Purpose:  US-0014494 Ph 1 - Account Manager Page - Rework
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.01.2024 / Acmatac Seing / US-0014494 created this method
    *****************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String, Component_help_text_setting__mdt> getAccountManagementMetadata(String metadataName){
        metadataName += '%';
        String strQuery = 'SELECT DeveloperName,Heading__c,Help_Text__c,Bigger_Body_Test__c,Id FROM Component_help_text_setting__mdt where DeveloperName LIKE:metadataName ORDER BY DeveloperName ASC';
        Map<String, Component_help_text_setting__mdt> mCHTS = new Map<String, Component_help_text_setting__mdt>();
        for(Component_help_text_setting__mdt cht : (List<Component_help_text_setting__mdt>) ApexSafe.query().doQuery(strQuery, new Map<String, Object>{'metadataName' => metadataName})){
            mCHTS.put(cht.DeveloperName, cht);   
        }
        return mCHTS;
    }

    /*********************************************************************************************************************************
    @ Method:       initDataBookingAdvertising
    @ Version:      1.0
    @ Author:       Davy Sorn
    @ Purpose:      US-0026115 - 2. Create a new component for Account Management
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.05.2025 / Davy Sorn / Created the Method.
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> initDataBookingAdvertising(String cohortSellerId){
        Map<String,Object> mapResult = new Map<String,Object>();
        String accManagerId = '';
        String accManagerName = '';
        String accManagerEmail = '';
        String accManagerImage = '';
        String accManagerCalendlyLink = '';
        ProTraderSellerDashboardController.ProTraderSellerDashboardWrapperClass cohortSellerData = new ProTraderSellerDashboardController.ProTraderSellerDashboardWrapperClass();
        Id currentUserId = UserInfo.getUserId();
        List<User> currentUsers = (List<User>) ApexSafe.query().doQuery(SOQL_CURRENTUSER,new Map<String, Object> {'currentUserId' => currentUserId});
        String soql = SOQL_COHORT_SELLER + ' Where Id =: cohortSellerId';
        for(BoB_Seller__c bs : (List<BoB_Seller__c>) ApexSafe.query().doQuery(soql, new Map<String, Object>{'cohortSellerId' => cohortSellerId})){
            cohortSellerData.cohortSellerParentSellerName = bs.Seller_Name__c;
            accManagerId = bs.Account_Manager__c; //DS??? .Ads_Partner_Manager__c;

        }
        if(String.isNotBlank(accManagerId)){
            for(User oAccManager : (List<User>) DataCreator.getRecordbyId(User.sObjectType, accManagerId)){
                accManagerName = oAccManager.Name;
                accManagerEmail = oAccManager.Customer_facing_eMail__c;
                accManagerImage = oAccManager.MediumPhotoUrl;
                accManagerCalendlyLink = oAccManager.Calendly__CalendlyLink__c;
            }
        }
        mapResult.put('accManagerName', accManagerName);
        mapResult.put('accManagerEmail', accManagerEmail);
        mapResult.put('accManagerImage', accManagerImage);
        mapResult.put('accManagerCalendlyLink', accManagerCalendlyLink);
        mapResult.put('currentUser', currentUsers[0]);
        mapResult.put('cohortSellerData', cohortSellerData);
        return mapResult;
    }
    
}