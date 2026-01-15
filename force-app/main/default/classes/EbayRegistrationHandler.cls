/*********************************************************************************************************************************
@ Class:          EbayRegistrationHandler
@ Version:        1.0
@ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:        US-0010085 - [SEP] Implement matching classes for ebay SSO to identify community users based on ebay account
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.08.2021 / Acmatac SEING / Created the class.
@                 13.09.2021 / Acmatac SEING / US-0010353 - AC1: Update the SSO logic: to Query the Contact record which has Record Type='DWH' to pick the contact for SSO login.
@                 02.02.2022/ vadhanak voun / US-0010870 - [SP] Just in Time Provisioning of Sellers (Deals, Monetization) - NA, DE
@                 08.04.2022/ vadhanak voun / US-0010870 - rework - final?
@                 04.05.2022/ SRONG TIN / US-0011083 - SSO Adjustments for Linked Accounts
@                 27.07.2022/ Mony Nou / US-0011699 - Auto Provisioning of Sellers (Deals) - AU (Perm Set Group) - AC6
@                 21.11.2022/ Mony Nou / US-0012333 - UK Seller Portal Profile/ Permission Set and Auto Provisioning
@                 30.03.2023/ Loumang SENG / US-0013446 - Fix for not activating the deactivated Seller Portal User with federated login=true
@                 24.04.2023 / Sophal Noch / US-0013565 - eBay Registration Handler for Call booking site.
@                 16.08.2023 / vadhanak voun/ US-0013999 - Tech Debt: fix hardcoded Id (part 1)
@                 16.10.2023 / SRONG TIN / US-0014262 - AU Sellers are unable to access Seller Portal
@                 07.11.2023 / Sharath / US-0012584 - ✓[TS]Delete Metadata created for Trusted Shops
@                 08.12.2023 / Sambath Seng / US-0014263 - Store log of unsuccessful logins for sellers portal
@                 05.01.2024 / Mony Nou / US-0014477 - Auto Provisioning is not working for bauportal
@                 21.05.2024 / Acmatac Seing / US-0015257 - Bookings.com NA Seller are getting DE language
@                 06.06.2024 / Acmatac Seing / US-0015181 - Implement Seamless eBay SSO Authentication
@                 11.06.2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
@                 14.10.2024/ vadhanak voun / US-0015432 - ADS - Eligibility for Advertising program component
*********************************************************************************************************************************/
global virtual class EbayRegistrationHandler implements Auth.RegistrationHandler{
    private final static Id CONTACT_DWH_RTID = ApexUtil.getRecordTypeByName('Contact','EBH_DWH').Id;//'0126A000000T3OOQA0'; // Contact recordtype DWH      //NK:16/08/2023:US-0013999
    private final String RECORD_TYPE_SELLER = 'EBH_Seller';

    /* MN-11062024-US-0015298: Not using anywhere
    private final String PORTAL_DE = 'DE - Seller Portal';
    private final String PORTAL_NA = 'NA - Seller Portal';
    private final String PORTAL_AU = 'AU - Seller Portal'; //MN-27072022-US-0011699
    */
    private final String DEACTIVATED_SUFFIX = '%@deactviated.com%'; //NK:14/10/2024:US-0015432 
    private final String PORTAL_SUFFIX = '.ebay.portal';
    
    public final static String PSGROUP_DE = 'Seller_Portal_DE';
    private final String PSGROUP_NA = 'Seller_Portal_NA';
    private final String PSGROUP_AU = 'Seller_Portal_AU'; //MN-27072022-US-0011699
    private String SELLER_NAME = ''; //SRONG/16.10.2023/US-0014262 
    private String Page_Login = 'Login'; //SB 08.12.2023 US-0014263 - Store log of unsuccessful logins for sellers portal
    
    // private final String ELIGBILE_CHECK_PORTAL ='Eligible_for_Seller_Portal';
    private final String ELIGBILE_CHECK_PORTAL = getPortalEligibilityMdtName(); // 24.04.2023/ Sophal Noch / US-0013565 : return custom metadata name

    // private final String ELIGBILE_CHECK_DE ='Eligible_for_DE_Deals';
    // private final String ELIGBILE_CHECK_NA ='Eligible_for_NA_Deals';
    

    // private final Set<String> DE_META_IDENTIFIER = new Set<String>{'Eligible_for_DE_Deals','Eligible_for_Account_Manager','Eligible_for_Growth_Based_Discounts'};
    // private final Set<String> NA_META_IDENTIFIER = new Set<String>{'Eligible_for_NA_Deals'};

    // SB 8.12.2023 US-0014263
    //MN-11062024-US-0015298: Added field FinalSPMainDomain__c to query
    //NK:14/10/2024:US-0015432 
    protected String soqlSeller0 = 'Select Id,Name,eBay_API_User_Id__c,Seller_Portal_Group__c,User_Disconnected__c,Seller_Portal_Profile__c,EBH_OracleID__c, FinalSPMainDomain__c From Account ';
    protected String soqlSellerFilter = ' WHERE eBay_API_User_Id__c=:sellerId AND RecordType.DeveloperName=:RECORD_TYPE_SELLER ';

    private String soqlSeller =  soqlSeller0 + soqlSellerFilter;

    // 24.04.2023 / Sophal Noch / US-0013565 : custom metadata to use in seller portal and bookign portal
    private Map<String, Portal_Eligibility__mdt> MAP_ELGIBILITY = new Map<String, Portal_Eligibility__mdt>();
    private Map<String, Portal_Eligibility_Permission__mdt> MAP_ELGIBILITY_PERM = new Map<String, Portal_Eligibility_Permission__mdt>();
    
    // 21.05.2024 / Acmatac Seing / US-0015257 - Bookings.com NA Seller are getting DE language
    protected virtual Boolean isFromBookingPortal(){ return false; }
    //

    /* MN-11062024-US-0015298: We are using field Account.FinalSPMainDomain__c instead
    private static Map<String, String> SP_MAIN_DOMAIN_MAPPING = new Map<String, String> {
        'US' => Label.SEP_Domain_NA,
        'CA' => Label.SEP_Domain_NA,
        'AU' => Label.SEP_Domain_AU,
        'NZ' => Label.SEP_Domain_AU,
        'UK' => Label.SEP_Domain_UK,
        'DE' => Label.SEP_Domain_DE,
        'ROE -Other' => Label.SEP_Domain_DE,
        'PL' => Label.SEP_Domain_DE,
        'NL' => Label.SEP_Domain_DE,
        'SE' => Label.SEP_Domain_DE,
        'AT' => Label.SEP_Domain_DE,
        'IT' => Label.SEP_Domain_IT,
        'FR' => Label.SEP_Domain_FR,
        'BE' => Label.SEP_Domain_DE,
        'CZ' => Label.SEP_Domain_DE,
        'DK' => Label.SEP_Domain_DE,
        'GR' => Label.SEP_Domain_DE,
        'HU' => Label.SEP_Domain_DE,
        'IE' => Label.SEP_Domain_DE,
        'LU' => Label.SEP_Domain_DE,
        'PT' => Label.SEP_Domain_DE,
        'RO' => Label.SEP_Domain_DE,
        'SK' => Label.SEP_Domain_DE,
        'ES' => Label.SEP_Domain_DE
    };
    */

    global User createUser(Id portalId, Auth.UserData data){
        // SRONGTIN: 6.05.2022 :US-0011083: SSO Adjustments for Linked Accounts
        User sU = checkSSOAccountLogin(portalId,data);
        return sU;
       
    }
    

    global void updateUser(Id userId, Id portalId, Auth.UserData data){
        // SRONGTIN: 6.05.2022 : US-0011083: SSO Adjustments for Linked Accounts
        User usr = checkSSOAccountLogin(portalId,data);

   
    }

    /*********************************************************************************************************************************
    @ Method:         getPortalEligibilityMdtName
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0013565 - eBay Registration Handler for Call booking site.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.04.2023 / Sophal Noch / create method
    @                 05.01.2024 / Mony Nou / US-0014477 - Auto Provisioning is not working for bauportal
    **********************************************************************************************************************************/
    protected virtual String getPortalEligibilityMdtName(){return 'Seller_Portal_Eligibility';} // custom metdata name for seller portal

    // SRONGTIN: 6.05.2022 : US-0011083: SSO Adjustments for Linked Accounts
    private void updateUserActiveUser(Id userId, Id portalId, Auth.UserData data, Boolean isHasGroup){  

        //MN-05012024-US-0014477: Added fields to below query: UserRoleId, UserRole.PortalAccountOwnerId, Contact.AccountId, Contact.Account.OwnerId
        User usr = [Select Id,Email,isActive,Permission_Sets__c,IsPortalEnabled, UserRoleId, UserRole.PortalAccountOwnerId, Contact.AccountId, Contact.Account.OwnerId From User Where Id=:userId];  

        // SB 6.12.2023 US-0014263 
        try {
            if(!usr.isActive){
                // SRONGTIN: 20.05.2022 : US-0011083
                String sellerId = data.identifier;
                usr.isActive = true;
                usr.IsPortalEnabled = true;
                usr.Id = userId;


                //MN-05012024-US-0014477: verifying the user's role validity by comparing the user's role owner(PortalAccountOwnerId) with the account owner
                if (usr.UserRole.PortalAccountOwnerId != null && usr.UserRole.PortalAccountOwnerId != usr.Contact.Account.OwnerId) {
                    //UserRole usr_role = new UserRole(PortalAccountId = usr.Contact.AccountId, PortalType = 'CustomerPortal'); 
                    UserRole usr_role = new UserRole();

                    //Find the existing user role for the account owner
                    for (UserRole usr_role_exist : [SELECT Id FROM UserRole WHERE PortalType = 'CustomerPortal' AND PortalAccountOwnerId = :usr.Contact.Account.OwnerId]) {
                        usr_role = usr_role_exist;
                    }
                    
                    //If the user role is not found, create a new one
                    if (usr_role.Id == null) {
                        usr_role = new UserRole(PortalAccountId = usr.Contact.AccountId, PortalType = 'CustomerPortal'); 
                        insert usr_role;
                    }

                    usr.UserRoleId = usr_role.Id;

                }

                //check if Seller have Seller Portal Group
                if(!isHasGroup){
                    
                    // User userValidated = sellerValidation(sellerId,data);   //revaliate with metadata and to get Permset
                    User userValidated = sellerValidation(sellerId,data, usr);  // 24.04.2023/ Sophal Noch / US-0013565 add urs to argument
                    usr.Permission_Sets__c = userValidated.Permission_Sets__c;
                    usr.ProfileId = userValidated.ProfileId;
                    update usr;
                }else{
                    update usr; 
                } 
            }
        } catch (DmlException dex) {
            String logId = EBH_ApexLogger.logSellerPortal('create',data.username,data.identifier,userId,Page_Login,dex.getDmlMessage(0) + '\n' + dex.getStackTraceString(),URL.getSalesforceBaseUrl().getHost(),'updateUserActiveUser');
            throw new EbayRegistrationHandlerException(logId);
        } catch (Exception ex) {
            String logId = EBH_ApexLogger.logSellerPortal('create',data.username,data.identifier,userId,Page_Login,ex.getMessage() + '\n' + ex.getStackTraceString(),URL.getSalesforceBaseUrl().getHost(),'updateUserActiveUser');
            throw new EbayRegistrationHandlerException(logId);
        }
    } 

    /*********************************************************************************************************************************
    @ Method:         checkSSOAccountLogin
    @ Version:        1.0
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 03.05.2022 / SRONGTIN / US-0011083 - SSO Adjustments for Linked Accounts
                      08.12.2023 / Sambath Seng / US-0014263 - Store log of unsuccessful logins for sellers portal
                      14.10.2024/ vadhanak voun / US-0015432 - ADS - Eligibility for Advertising program component
    **********************************************************************************************************************************/
    private User checkSSOAccountLogin(Id portalId, Auth.UserData data){
        System.debug('Auth.UserData data :: '+data);
        Boolean isDE = isFromDESite();
        String sellerId = data.identifier;
        //Account[] sellers = Database.query(soqlSeller);
        Account[] sellers = (Account[])ApexSafe.query().secCheck(false).doQuery(soqlSeller, new Map<String, Object>{'sellerId' => sellerId,'RECORD_TYPE_SELLER'=>RECORD_TYPE_SELLER});
         
        // SB 6.12.2023 US-0014263
        String errorMessage;
        
        if (!sellers.isEmpty()) {
            //SRONG/16.10.2023/US-0014262 
            SELLER_NAME = sellers[0].Name;

            // SRONGTIN: 24.05.2022 : US-0011083
            if(sellers[0].User_Disconnected__c == true){
                // SB 6.12.2023 US-0014263 
                // throw new EbayRegistrationHandlerException(getMessage(isDE,'LoginErrorMsg_6'));
                errorMessage = getMessage(isDE,'LoginErrorMsg_6');
                String logId = EBH_ApexLogger.logSellerPortal('create',data.username,data.identifier,'',Page_Login,errorMessage,URL.getSalesforceBaseUrl().getHost(),'checkSSOAccountLogin-1');
                throw new EbayRegistrationHandlerException(logId);
            }else 
            // IS Account have Seller Portal Group?
            //NK:14/10/2024:US-0015432 
            if(sellers[0].Seller_Portal_Group__c != null && !isFromBookingPortal()){
                //Yes
                //Does Seller Portal Group have Contact already enabled for SSO for which there is a Active User?
                String sellerPortalGroupId = sellers[0].Seller_Portal_Group__c;
                //LA-30-03-2023-US-0013446: Add field filtering conditions in query
                // 24.04.2023/ Sophal Noch / US-0013565 : add field Profile.Name, Permission_Sets__c, Contact.Original_Seller__r.eBay_API_User_Id__c to query
                //MN-11062024-US-0015298: Add field Contact.Account.FinalSPMainDomain__c to query
                // for(User sU : [SELECT userName, email, lastName, firstName, alias,isActive, Profile.Name, Permission_Sets__c, Contact.Original_Seller__r.eBay_API_User_Id__c, Contact.Account.FinalSPMainDomain__c FROM User 
                //         WHERE Contact.Account.Id = :sellerPortalGroupId AND Federated_Login__c = false AND (NOT(Username LIKE '%@deactviated.com%')) LIMIT 1])
                // {
                String usrQuery = 'SELECT userName, email, lastName, firstName, alias,isActive, Profile.Name, Permission_Sets__c, Contact.Original_Seller__r.eBay_API_User_Id__c, Contact.Account.FinalSPMainDomain__c FROM User WHERE Contact.Account.Id = :sellerPortalGroupId AND Federated_Login__c = false AND (NOT(Username LIKE :DEACTIVATED_SUFFIX)) LIMIT 1';
                for(User sU : (User[])ApexSafe.query().secCheck(false).doQuery(usrQuery, new Map<String, Object>{'sellerPortalGroupId' => sellerPortalGroupId, 'DEACTIVATED_SUFFIX' => DEACTIVATED_SUFFIX}))
                {
                    if(!sU.IsActive){
                        // User not Active US-0011083: AC6
                        // from old story:US-0010870
                        updateUserActiveUser(sU.Id,portalId,data,true);
                    }else{
                        // 24.04.2023/ Sophal Noch / US-0013565 : validate linked account seller eligibility, permission set, permission set group
                        manageActiveUserPermSet(sU, sU.Contact.Original_Seller__r.eBay_API_User_Id__c);
                    }
                    //Yes  US-0011083: AC4
                    return sU;

                }
                // No User not found US-0011083: AC5
                // SB 6.12.2023 US-0014263 
                // throw new EbayRegistrationHandlerException(getMessage(isDE,'LoginErrorMsg_5'));
                errorMessage = getMessage(isDE,'LoginErrorMsg_5');
                String logId = EBH_ApexLogger.logSellerPortal('create',data.username,data.identifier,'',Page_Login,errorMessage,URL.getSalesforceBaseUrl().getHost(),'checkSSOAccountLogin-2');
                throw new EbayRegistrationHandlerException(logId);

            }else{
                //No
                //Does Account have contact already enabled for SSO for which there is a Active User?
                // 24.04.2023/ Sophal Noch / US-0013565 : add field Profile.Name, Permission_Sets__c to query
                //MN-11062024-US-0015298: Add field Contact.Account.FinalSPMainDomain__c to query
                // 13.09.2021 / Acmatac SEING / US-0010353
                //NK:14/10/2024:US-0015432 
                String soqlUser = 'SELECT userName, email, lastName, firstName, alias,isActive, Profile.Name, Permission_Sets__c, Contact.Account.FinalSPMainDomain__c FROM User  WHERE Contact.Account.eBay_API_User_Id__c = :data_identifier AND Contact.RecordTypeId = :CONTACT_DWH_RTID LIMIT 1';                 
                for(User sU : (User[])ApexSafe.query().secCheck(false).doQuery(soqlUser, new Map<String, Object>{'data_identifier' => data.identifier, 'CONTACT_DWH_RTID' => CONTACT_DWH_RTID}))
                {
                    if(!sU.isActive)
                    {
                        // User not Active US-0011083: AC3
                        // from old story:US-0010870
                        updateUserActiveUser(sU.Id,portalId,data,false);       
                    }else{
                        // 24.04.2023/ Sophal Noch / US-0013565 : validate seller eligibility, permission set, permission set group
                        manageActiveUserPermSet(sU, sellers[0].eBay_API_User_Id__c);
                    }
                    // US-0011083: AC2 
                    return sU;
                }
            }
        }else{
            //incase no user found
            // Is Account not found within Hive US-0011083: AC1
            // SB 6.12.2023 US-0014263 
            // throw new EbayRegistrationHandlerException(getMessage(isDE,'LoginErrorMsg_4')); // 'Cannot find the user. For help, contact your administrator.'
            errorMessage = getMessage(isDE,'LoginErrorMsg_4');
            String logId = EBH_ApexLogger.logSellerPortal('create',data.username,data.identifier,'',Page_Login,errorMessage,URL.getSalesforceBaseUrl().getHost(),'checkSSOAccountLogin-3');
            throw new EbayRegistrationHandlerException(logId);
        }
        // return sellerValidation(sellerId,data);
        return sellerValidation(sellerId,data, null);  // 24.04.2023/ Sophal Noch / US-0013565 add null argument for user param, this is for new user
    }
    

    /*********************************************************************************************************************************
    @ Method:         manageActiveUserPermSet
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0013565 - eBay Registration Handler for Call booking site.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.04.2023 / Sophal Noch / create method
                    : 08.12.2023 / Sambath Seng / US-0014263 - Store log of unsuccessful logins for sellers portal
    **********************************************************************************************************************************/
    private void manageActiveUserPermSet(User user, String eBayAPIUserId){

        // validate exist active user with correct eligbile
        Boolean isDE = isFromDESite();
        Map<String,String>  mapSetting = getMetaSetting();
        Account findSeller = checkEligible(new Set<String>{ELIGBILE_CHECK_PORTAL},mapSetting,eBayAPIUserId);

        if(findSeller == null){
            //SRONG/16.10.2023/US-0014262 
            String errorMsg = getMessage(isDE,'LoginErrorMsg_3');
            errorMsg = errorMsg.replace('USER_NAME', SELLER_NAME);

            // SB 08.12.2023 US-0014263
            String logId = EBH_ApexLogger.logSellerPortal('create',SELLER_NAME,eBayAPIUserId,user != null ? user.Id : '',Page_Login,errorMsg,URL.getSalesforceBaseUrl().getHost(),'manageActiveUserPermSet');

            throw new EbayRegistrationHandlerException( logId );
        }

        // check exist active user with correct permission set and permission set group
        Boolean isFound = true;

        //Portal_Eligibility_Permission__mdt portalEligiPermMdt = getEligibilityPermMdt(user.Profile.Name); //MN-11062024-US-0015298: No longer use Profile Name
        Portal_Eligibility_Permission__mdt portalEligiPermMdt = getEligibilityPermMdt(findSeller.FinalSPMainDomain__c); //MN-11062024-US-0015298: Use SP Main Domain instead of Profile Name

        Set<String> setCurrentPS =  new Set<String>();
        for(PermissionSetAssignment psa : [Select Id, PermissionSetGroupId, PermissionSetGroup.DeveloperName,PermissionSet.Name From PermissionSetAssignment Where AssigneeId =: user.Id And PermissionSet.IsOwnedByProfile = false]){
            if(psa.PermissionSetGroupId != null){ // get exist user permission set group
                setCurrentPS.add(psa.PermissionSetGroup.DeveloperName);
            }else{  // get exist user permission set
                setCurrentPS.add(psa.PermissionSet.Name);
            }
        }

        Set<String> setMdtPS = new Set<String>();
        if(portalEligiPermMdt != null){
            for(String ps : portalEligiPermMdt.Permission_Sets__c.split(';')){
               if(!setCurrentPS.contains(ps)){ isFound = false; break; }
            }
        }
        
        if(!isFound){ // if there is missing permission set group or permission set, then update User.Permission_Sets__c with correct Permission Set Group and Permission Set
            user.Permission_Sets__c = getAvailablePermSet(user, portalEligiPermMdt);
            update user;
        }

    }

    /*********************************************************************************************************************************
    @ Method:         sellerValidation
    @ Version:        1.0
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.12.2023 / Sambath Seng / US-0014263 - Store log of unsuccessful logins for sellers portal
    **********************************************************************************************************************************/
    private User sellerValidation(String sellerId,Auth.UserData data, User existUser)
    {
         // 24.04.2023/ Sophal Noch / US-0013565 : add existUser parameter

        Boolean isDE = isFromDESite();
        //found seller. let check if eligible?
        Map<String,String>  mapSetting = getMetaSetting();
        //check is this is portal eligible
        Account findSeller = checkEligible(new Set<String>{ELIGBILE_CHECK_PORTAL},mapSetting,sellerId);

        if(findSeller == null){
            //SRONG/16.10.2023/US-0014262 
            String errorMsg = getMessage(isDE,'LoginErrorMsg_3');
            errorMsg = errorMsg.replace('USER_NAME', SELLER_NAME);

            // SB 08.12.2023 US-0014263 
            String userId = existUser?.Id; //MN-09012024-US-0014477: Added userId variable to avoid error of "Invalid id: " when we use inline condition as passing parameter
            String logId = EBH_ApexLogger.logSellerPortal('create',data.username,data.identifier,userId,Page_Login,errorMsg,URL.getSalesforceBaseUrl().getHost(),'sellerValidation-1');

            throw new EbayRegistrationHandlerException( logId );
        }
        
        // 24.04.2023/ Sophal Noch / US-0013565 : disable code below, no longer use static mapping
        // if(findSeller <> null && findSeller.Seller_Portal_Profile__c==PORTAL_DE)
        // {
        //     return prepareUser(findSeller.Id,data,PORTAL_DE,PSGROUP_DE);

        // }else if(findSeller <> null && findSeller.Seller_Portal_Profile__c==PORTAL_NA)
        // {
        //     return prepareUser(findSeller.Id,data,PORTAL_NA,PSGROUP_NA);

        // }else if(findSeller <> null && findSeller.Seller_Portal_Profile__c==PORTAL_AU) { //MN-27072022-US-0011699
        //     return prepareUser(findSeller.Id,data,PORTAL_AU,PSGROUP_AU);
        // }else 
        // {
        //      //seller not eligible for portal access- Throw the error
        //     //throw new EbayRegistrationHandlerException(System.Label.Err_UserNotEligible); 
        //     throw new EbayRegistrationHandlerException( getMessage(isDE,'LoginErrorMsg_3') );
        // }
        
        // 24.04.2023/ Sophal Noch / US-0013565 : use custom metadata to map Account.Seller_Portal_Profile__c with User.Profile, Permission Set, Permission Set Group
        // Seller Portal Mapping :
        //  - Account.Seller_Portal_Profile__c "DE - Seller Portal" -> User.Profile "DE - Seller Portal" -> Permission Set Group "Seller_Portal_DE"
        //  - Account.Seller_Portal_Profile__c "NA - Seller Portal" -> User.Profile "NA - Seller Portal" -> Permission Set Group "Seller_Portal_NA"
        //  - Account.Seller_Portal_Profile__c "AU - Seller Portal" -> User.Profile "AU - Seller Portal" -> Permission Set Group "Seller_Portal_AU"
        // Booking Portal Mapping :
        //  - Account.Seller_Portal_Profile__c "DE - Seller Portal" -> User.Profile "DE - Seller Portal" -> Permission Set Group "Bookings_Portal" -> Permission Set "Bookings_Portal_General"
        //  - Account.Seller_Portal_Profile__c "NA - Seller Portal" -> User.Profile "NA - Seller Portal" -> Permission Set Group "Bookings_Portal" -> Permission Set "Bookings_Portal_General"
        //  - Account.Seller_Portal_Profile__c "AU - Seller Portal" -> User.Profile "AU - Seller Portal" -> Permission Set Group "Bookings_Portal" -> Permission Set "Bookings_Portal_General"
        
        //Portal_Eligibility_Permission__mdt eligibilityPermMdt = getEligibilityPermMdt(findSeller.Seller_Portal_Profile__c); //MN-11062024-US-0015298: No longer use Seller_Portal_Profile__c 
        Portal_Eligibility_Permission__mdt eligibilityPermMdt = getEligibilityPermMdt(findSeller.FinalSPMainDomain__c); //MN-11062024-US-0015298: Use SP Main Domain instead of Seller_Portal_Profile__c

        String permSet = eligibilityPermMdt != null && eligibilityPermMdt.Permission_Sets__c != null ? eligibilityPermMdt.Permission_Sets__c : null;
        
        /* MN-11062024-US-0015298: No longer use Seller_Portal_Profile__c
        if(findSeller <> null && findSeller.Seller_Portal_Profile__c <> null && String.isNotBlank(permSet)){
            return prepareUser(findSeller.Id,data, findSeller.Seller_Portal_Profile__c, permSet, existUser);
        }
        */

        //MN-11062024-US-0015298: Use FinalSPMainDomain__c instead of Seller_Portal_Profile__c
        if(findSeller <> null && String.isNotBlank(findSeller.FinalSPMainDomain__c) && String.isNotBlank(permSet)){
            return prepareUser(findSeller.Id,data, '', permSet, existUser);
        }
        else {
             //seller not eligible for portal access- Throw the error
            //throw new EbayRegistrationHandlerException(System.Label.Err_UserNotEligible); 
            //SRONG/16.10.2023/US-0014262 
            String errorMsg = getMessage(isDE,'LoginErrorMsg_3');
            errorMsg = errorMsg.replace('USER_NAME', SELLER_NAME);

            // SB 08.12.2023 US-0014263
            String logId = EBH_ApexLogger.logSellerPortal('create',data.username,data.identifier,existUser?.Id,Page_Login,errorMsg,URL.getSalesforceBaseUrl().getHost(),'sellerValidation-2');

            throw new EbayRegistrationHandlerException( logId );
        }

        // String permSets = 'Seller_Portal_Baseline_Account_Contact_Access'; //default for both DE and NA
        // if(findSeller <> null)
        // {
        //     //seller is eligible for NA Portal - process create Portal User
        //     //check if eligible for NA
        //     String ssFilter = ' AND ('+ mapSetting.get(ELIGBILE_CHECK_NA) +') ';             
        //     Account[] sellersToVerify = Database.query(soqlSeller + ssFilter );
        //     permSets += (sellersToVerify.isEmpty() ? '' : ';NA_Seller_Portal_Deals'); //additional permset if elibile for NA DEAL. to be assigned by other flow/trigger
        //    // system.debug('---NA permSets: '+permSets);
        //     return prepareUser(findSeller.Id,data,PORTAL_NA,permSets);
        // }else  
        // {
        //     //2,not NA then DE?
        //     findSeller = checkEligible(DE_META_IDENTIFIER,mapSetting,sellerId);
        //     if(findSeller <> null) 
        //     {
        //         //seller is eligible for DE Portal - process create Portal User
        //         //check if eligible for DEAL
        //         String ssFilter = ' AND ('+ mapSetting.get(ELIGBILE_CHECK_DE) +') ';             
        //         Account[] sellersToVerify = Database.query(soqlSeller + ssFilter );
        //         permSets += ( sellersToVerify.isEmpty() ? '' : ';DE_Seller_Portal_Deals');   //additional permset if elibile for DE DEAL. to be assigned by other flow/trigger
        //         //system.debug('---DE permSets: '+permSets);
        //         return prepareUser(findSeller.Id,data,PORTAL_DE,permSets);

        //     }else 
        //     {
        //         //seller not eligible for neither NA or DE - Throw the error
        //         throw new EbayRegistrationHandlerException(System.Label.Err_UserNotEligible); 
        //     }

        // }
    }

    /*********************************************************************************************************************************
    @ Method:         getEligbilitytMdt
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0013565 - eBay Registration Handler for Call booking site.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.04.2023 / Sophal Noch / create method
    **********************************************************************************************************************************/
    private Portal_Eligibility__mdt getEligbilitytMdt(){
        // get eligiblity to validate seller from custom metadata
        if(!MAP_ELGIBILITY.containsKey(ELIGBILE_CHECK_PORTAL)){
            for(Portal_Eligibility__mdt setting: [Select Id,DeveloperName, Eligibility_Criteria__c, PermSet_Allowed_To_Keep__c from Portal_Eligibility__mdt where DeveloperName  =: ELIGBILE_CHECK_PORTAL]){
                MAP_ELGIBILITY.put(setting.DeveloperName, setting);
            }
        }
       return MAP_ELGIBILITY.get(ELIGBILE_CHECK_PORTAL);
    }

    /*********************************************************************************************************************************
    @ Method:         getEligibilityPermMdt
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0013565 - eBay Registration Handler for Call booking site.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.04.2023 / Sophal Noch / create method
    **********************************************************************************************************************************/
    /* MN-11062024-US-0015298: No longer Use
    private Portal_Eligibility_Permission__mdt getEligibilityPermMdt(String profileName){
        // get eligiblity to populate profile, permission set group, permission set
        Portal_Eligibility_Permission__mdt eligibilityPermMdt = MAP_ELGIBILITY_PERM.get(profileName);
        if(eligibilityPermMdt == null){
            for( Portal_Eligibility_Permission__mdt setting : [Select Id,DeveloperName, Portal_Eligibility__c, Seller_Portal_Profile__c, Permission_Sets__c from Portal_Eligibility_Permission__mdt 
                                                            Where Portal_Eligibility__c  =: ELIGBILE_CHECK_PORTAL And Seller_Portal_Profile__c =: profileName]
            ){
                MAP_ELGIBILITY_PERM.put(setting.Seller_Portal_Profile__c, setting);
            }
        }
       return MAP_ELGIBILITY_PERM.get(profileName);
    }
    */ 
    /*********************************************************************************************************************************
    @ Method:         getEligibilityPermMdt
    @ Version:        2.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        Retreive Portal Eligibility Permissions based on Portal_Eligibility__c & SP Main Domain
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.06.2024 / Mony Nou / create method for US-0015298
    **********************************************************************************************************************************/
    private Portal_Eligibility_Permission__mdt getEligibilityPermMdt(String spMainDomain){

        // get eligiblity to populate profile, permission set group, permission set
        Portal_Eligibility_Permission__mdt eligibilityPermMdt = MAP_ELGIBILITY_PERM.get(spMainDomain);
        if(eligibilityPermMdt == null){
            for( Portal_Eligibility_Permission__mdt setting : [Select Id,DeveloperName, Portal_Eligibility__c, Seller_Portal_Profile__c, Permission_Sets__c, SPMainDomain__c from Portal_Eligibility_Permission__mdt 
                                                            Where Portal_Eligibility__c  =: ELIGBILE_CHECK_PORTAL And SPMainDomain__c =: spMainDomain]
            ){
                MAP_ELGIBILITY_PERM.put(setting.SPMainDomain__c, setting);
            }
        }
       return MAP_ELGIBILITY_PERM.get(spMainDomain);
    }

    
    private User prepareUser(String accId, Auth.UserData data,String profileName,String permSets, User existUser)
    {  
         // 24.04.2023/ Sophal Noch / US-0013565 : add existUser parameter
        //MN-11062024-US-0015298: Add field to query: Account.FinalSPMainDomain__c
        Contact[] conts = [Select Id,firstName,LastName,Email,Account.SP_Main_Domain__c,Account.FinalSPMainDomain__c,Account.EBH_RevRollup__c From Contact Where AccountId =:accId AND RecordTypeId=:CONTACT_DWH_RTID order by Primary_Contact__c  desc LIMIT 1];
       
        if(conts.isEmpty())
        {
            throw new EbayRegistrationHandlerException('No valid contact!');  // may never reach in real case
        }
         
        
        
        String metaRecord = '';
        String spMainDomain = ''; //MN-11062024-US-0015298

        // From Booking Portal
        if(isFromBookingPortal()){

            /* MN-11062024-US-0015298: No longer use static mapping and Profile Name
            if(SP_MAIN_DOMAIN_MAPPING.containsKey(conts[0].Account.EBH_RevRollup__c)) {
                metaRecord = SEP_Helper.getProfileMappingMetaName(SP_MAIN_DOMAIN_MAPPING.get(conts[0].Account.EBH_RevRollup__c)); // Acmatac SEING / US-0012095 - [UK] Manage Users
            }else{
                // default to NA
                metaRecord = 'NA - Seller Portal';
            }
            */

            //MN-11062024-US-0015298: Default SP Main Domain is NA
            spMainDomain = String.isBlank(conts[0].Account.FinalSPMainDomain__c) ? SEP_Helper.SEP_Domain_NA : conts[0].Account.FinalSPMainDomain__c; 

        }
        // From Seller Portal
        else{

            //MN-11062024-US-0015298: No longer use static mapping and Profile Name
            //metaRecord = SEP_Helper.getProfileMappingMetaName(conts[0].Account.SP_Main_Domain__c); // Acmatac SEING / US-0012095 - [UK] Manage Users

            //MN-11062024-US-0015298: Default SP Main Domain is DE
            spMainDomain = String.isBlank(conts[0].Account.FinalSPMainDomain__c) ? SEP_Helper.SEP_Domain_DE : conts[0].Account.FinalSPMainDomain__c; 
        }

        //MN-11062024-US-0015298: No longer use Profile 
        //Profile_Mapping__mdt pmapping = [Select Id,User_Currency__c,User_Language__c,User_Locale__c,timeZoneSidKey__c From Profile_Mapping__mdt Where MasterLabel=:metaRecord];

        //MN-11062024-US-0015298: Use SP Main Domain to get Profile Mapping
        Profile_Mapping__mdt pmapping = [Select Id,User_Currency__c,User_Language__c,User_Locale__c,timeZoneSidKey__c, ProfileName__c From Profile_Mapping__mdt Where SPMainDomain__c=:spMainDomain];
        
        Profile prof = [Select Id From Profile Where Name=:pmapping.ProfileName__c]; //MN-11062024-US-0015298: Use Profile from Profile Mapping

        User userNew = new User();        
        userNew.username = conts[0].email + PORTAL_SUFFIX;
        userNew.email = conts[0].email;
        userNew.lastName = conts[0].lastName;
        userNew.firstName = conts[0].firstName;
        String alias = data.username;
        if(alias.length() > 8) {
            alias = alias.substring(0, 8);
        }
        userNew.alias = alias;
        userNew.languagelocalekey = pmapping.User_Language__c;
        userNew.localesidkey = pmapping.User_Locale__c;
        userNew.emailEncodingKey = 'UTF-8';
        userNew.timeZoneSidKey = pmapping.timeZoneSidKey__c;//'America/Los_Angeles'; //Europe/Berlin
        userNew.profileId = prof.Id;
        userNew.ContactId = conts[0].Id;
        //userNew.Permission_Sets__c = permSets;
        if(existUser != null && String.isNotBlank(existUser.Permission_Sets__c)){ userNew.Permission_Sets__c = existUser.Permission_Sets__c; } // 24.04.2023/ Sophal Noch / US-0013565 : must be populate Permission_Sets__c for reactivating user logic
        // 24.04.2023/ Sophal Noch / US-0013565 use custom metadata to populate field User.Permission_Sets__c and flow will run to populate the permission set group and permission set,
        
        //Portal_Eligibility_Permission__mdt eligibilityPermMdt = getEligibilityPermMdt(profileName); //MN-11062024-US-0015298: No longer use Profile Name
        Portal_Eligibility_Permission__mdt eligibilityPermMdt = getEligibilityPermMdt(spMainDomain); //MN-11062024-US-0015298: Use SP Main Domain instead of Profile Name

        userNew.Permission_Sets__c = eligibilityPermMdt != null ? getAvailablePermSet(userNew, eligibilityPermMdt) : permSets;
        
        userNew.Source_Domain__c = ApexUtil.getDomain(); //MN-21112022-US-0012333
        userNew.DefaultCurrencyIsoCode = pmapping.User_Currency__c; //MN-24112022-US-0012333

        return userNew;
    }    

    /*********************************************************************************************************************************
    @ Method:         getAvailablePermSet
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0013565 - eBay Registration Handler for Call booking site.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.04.2023 / Sophal Noch / create method
    **********************************************************************************************************************************/
    private String getAvailablePermSet(User user, Portal_Eligibility_Permission__mdt portalEligiPermSetting){

        // generate correct permission set group and permission set 
        
        String permSet = user.Permission_Sets__c;

        Set<String> setCurrentPS =  new Set<String>();
        if(user.Permission_Sets__c != null) setCurrentPS.addAll(user.Permission_Sets__c.split(';'));

        Set<String> setMdtPS = new Set<String>();
        if(portalEligiPermSetting.Permission_Sets__c != null) setMdtPS.addAll(portalEligiPermSetting.Permission_Sets__c.split(';' ));

        Portal_Eligibility__mdt eligilbilityMdt = getEligbilitytMdt();
        Set<String> setPSAllowedToKeep = new Set<String>();
        if(eligilbilityMdt != null && eligilbilityMdt.PermSet_Allowed_To_Keep__c != null) setPSAllowedToKeep.addAll(eligilbilityMdt.PermSet_Allowed_To_Keep__c.split(';' ));

        setCurrentPS.addAll(setMdtPS);
        for(String ps : setCurrentPS){
            if(!setMdtPS.contains(ps) && !setPSAllowedToKeep.contains(ps)){
                setCurrentPS.remove(ps);
            }
        }
        String permSetToUpdate = String.join(new List<String>(setCurrentPS), ';');

        if(permSetToUpdate == permSet){permSetToUpdate += ';' ;} // if User.Permission_Sets__c is correct but Permission Set Group and Permission Set are missing and then add ';' to trigger flow
        return permSetToUpdate;

    }

    //NK:14/10/2024:US-0015432 
    protected virtual Account checkEligible(Set<String> setMetaIdentity, Map<String,String> mapSetting,String sellerId)
    {
        //System.debug('---checkEligible: '+sellerId + ' - '+ setMetaIdentity);
        List<String> setFilters = new List<String>();
        for(String meta : setMetaIdentity)
        {
            //setFilters.add(mapSetting.get(meta));
            String naFilter = ' AND ('+ mapSetting.get(meta) +') ';
            //System.debug('--naFilter: '+naFilter);
            Account[] sellers = Database.query(soqlSeller + naFilter );
            if(!sellers.isEmpty())
            {
                return sellers[0];
            }
        }     
        //System.debug('---checkEligible: KO!!!');
        return null;
    }

    private Map<String,String> getMetaSetting()
    {
        Map<String,String>  mapSetting = new Map<String,String>();
        // for(Seller_Portal_Setting__mdt setting: [Select Id,DeveloperName,Filter_Values__c from Seller_Portal_Setting__mdt where DeveloperName  =:ELIGBILE_CHECK_PORTAL])
        // {
        //     mapSetting.put(setting.DeveloperName,setting.Filter_Values__c);
        // }
        // 24.04.2023/ Sophal Noch / US-0013565 : change custom metadata from Seller_Portal_Setting__mdt to Portal_Eligibility__mdt
        Portal_Eligibility__mdt eligbilitytMdt = getEligbilitytMdt();
        if(eligbilitytMdt != null){mapSetting.put(eligbilitytMdt.DeveloperName,eligbilitytMdt.Eligibility_Criteria__c);}
        return mapSetting;
    }

    private Boolean isFromDESite()
    {
        return System.Label.SEP_Domain_DE.contains(URL.getSalesforceBaseUrl().getHost());
    }
    //SRONG: 03.05.2022 : US-0011083 - SSO Adjustments for Linked Accounts
    // Add dynamic parameter MessageName
    private String getMessage(Boolean isDE, String messageName)
    {
        for(Seller_Portal_Global_Variables__mdt tmp: [SELECT DeveloperName, Value__c, Value_in_German__c FROM Seller_Portal_Global_Variables__mdt WHERE DeveloperName =:messageName])
        {
            //return isDE?tmp.Value_in_German__c : tmp.Value__c;
            return tmp.Value__c;
        }

        //never reach
        return 'Cannot find the user. For help, contact your administrator..';
    }


    class EbayRegistrationHandlerException extends Exception {}
}