/***************************************************************************************************************************************
@ Class:          SEPTestGenerator
@ Version:        1.0
@ Author:         Mony nou
@ Purpose:        Utility Class for the Creation of Test Data related with Seller Portal (SEP)
----------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.06.2024 / Mony Nou / Created the class.
***************************************************************************************************************************************/

@isTest
public class SEPTestGenerator {
    
    public static final String USERLICENSE_CUSTCOMPLUSLOGIN = 'Customer Community Plus Login';
    public static final String USERLICENSE_CUSTCOMPLUSMEMBER = 'Customer Community Plus';
    
    private static RecordType rtSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');

    /* 
        Description: This variable will return Map of PowerCustomerSuccess (user type) Profiles based on UserLicense Name. 
        ex: 
            key = 'Customer Community Plus Login' => value = List of Profiles
            key = 'Customer Community Plus' => value = List of Profiles
    */
    public static Map<String, List<Profile>> mapPowerCustomerSuccessProfiles {

        get {

            if (mapPowerCustomerSuccessProfiles == null) {

                mapPowerCustomerSuccessProfiles = new Map<String, List<Profile>>();

                for (Profile prof : [select id, name, UserLicense.Name, UserType from profile where UserType = 'PowerCustomerSuccess' and Name like '%Seller Portal%']) {
                    if (!mapPowerCustomerSuccessProfiles.containsKey(prof.UserLicense.Name)) mapPowerCustomerSuccessProfiles.put(prof.UserLicense.Name, new List<Profile>());
                    mapPowerCustomerSuccessProfiles.get(prof.UserLicense.Name).add(prof);
                }

            }
            return mapPowerCustomerSuccessProfiles;
        }

        private set;
    }

    /***************************************************************************************************************************************
    @ Purpose:       Prepare a Seller Account with given parameters
    ----------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String name - Name of the Account to create
    @                 Id recordTypeId - Record Type Id of the Account
    ----------------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        User - Prepared User record
    ***************************************************************************************************************************************/
    public static Account prepareAccountRecord(String name, Id recordTypeId) {

        return prepareAccountRecord(name, recordTypeId, (name + System.now().millisecond()), null, null, null, null);
    }

    /***************************************************************************************************************************************
    @ Purpose:       Prepare a Seller Account with given parameters
    ----------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String name - Name of the Account to create
    @                 Id recordTypeId - Record Type Id of the Account
    @                 String ebayAPI - Value for eBay_API_User_Id__c field
    @                 String spMainDomain - Value for SP_Main_Domain__c field
    @                 String spDeal - Value for SP_Deals__c field
    @                 String spCoupon - Value for SP_Coupons__c field
    @                 String spPromo - Value for SP_Promotions_Manager__c field
    ----------------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        User - Prepared User record
    ***************************************************************************************************************************************/
    public static Account prepareAccountRecord(String name, Id recordTypeId, String ebayAPI, String spMainDomain, String spDeal, String spCoupon, String spPromo) {

        recordTypeId = (recordTypeId == null)?rtSeller.Id:recordTypeId;

        Account acc = new Account(
            Name = name,
            RecordTypeId = recordTypeId,
            eBay_API_User_Id__c = ebayAPI,
            SP_Main_Domain__c = spMainDomain,
            SP_Deals__c = spDeal,
            SP_Coupons__c = spCoupon,
            SP_Promotions_Manager__c = spPromo
        );

        return acc;
    }

    /***************************************************************************************************************************************
    @ Purpose:        Create a Seller Account with given parameters
    ----------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String name - Name of the Account to create
    ----------------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        User - Prepared User record
    ***************************************************************************************************************************************/
    public static Account createSeller(String name) {
        return createSeller(name, null, null, null, null);
    }
    
    /***************************************************************************************************************************************
    @ Purpose:        Create a Seller Account with given parameters
    ----------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String name - Name of the Account to create
    @                 String spMainDomain - Value for SP_Main_Domain__c field
    ----------------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        User - Prepared User record
    ***************************************************************************************************************************************/
    public static Account createSeller(String name, String spMainDomain) {
        return createSeller(name, spMainDomain, null, null, null);
    }

    /***************************************************************************************************************************************
    @ Purpose:        Create a Seller Account with given parameters
    ----------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String name - Name of the Account to create
    @                 String spMainDomain - Value for SP_Main_Domain__c field
    @                 String spDeal - Value for SP_Deals__c field
    @                 String spCoupon - Value for SP_Coupons__c field
    @                 String spPromo - Value for SP_Promotions_Manager__c field
    ----------------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        User - Prepared User record
    ***************************************************************************************************************************************/
    public static Account createSeller(String name, String spMainDomain, String spDeal, String spCoupon, String spPromo) {

        Account acc = prepareAccountRecord(Name, rtSeller.Id, (name + System.now().millisecond()), spMainDomain, spDeal, spCoupon, spPromo);
        insert acc;

        return acc;

    }

    /***************************************************************************************************************************************
     @ Purpose:        Prepare a Community User record with given parameters
     ----------------------------------------------------------------------------------------------------------------------------------------------
     @ Parameter:      String name - Name of the user to create
     @                 Id contactId - Id of the contact to associate with the user
     @                 Id profileId - Id of the profile to associate with the user
     ----------------------------------------------------------------------------------------------------------------------------------------------
     @ Returns:        User - Prepared User record
     ***************************************************************************************************************************************/
    public static User prepareCommunityUserRecord(String name, Id contactId, Id profileId) {

        profileId = (profileId == null) ? mapPowerCustomerSuccessProfiles.get(USERLICENSE_CUSTCOMPLUSLOGIN).get(0).Id : profileId;

        User user = new User(
            Username = name + System.now().millisecond() + '@test.com',
            ContactId = contactId,
            ProfileId = profileId,
            Alias = 'test123',
            Email = 'test12345xx@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'McTesty',
            CommunityNickname = name + System.now().millisecond(),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        );

        return user;

    }

    /***************************************************************************************************************************************
     @ Purpose:        Creates a SEP User with given parameters
     ----------------------------------------------------------------------------------------------------------------------------------------------
     @ Parameter:      String name - Name of the user to create
     @                 Id contactId - Id of the contact to associate with the user
     ***************************************************************************************************************************************/
    public static User createSEPUser(String name, Id contactId) {
        return createSEPUser(name, contactId, null);
    }

    /***************************************************************************************************************************************
     @ Purpose:        Creates a SEP User with given parameters
     ----------------------------------------------------------------------------------------------------------------------------------------------
     @ Parameter:      String name - Name of the user to create
     @                 Id contactId - Id of the contact to associate with the user
     @                 Id profileId - Id of the profile to associate with the user
     ***************************************************************************************************************************************/
    public static User createSEPUser(String name, Id contactId, Id profileId) {

        User sep_user = prepareCommunityUserRecord(name, contactId, profileId);

        insert sep_user;

        return sep_user;

    }

    /***************************************************************************************************************************************
    @ Purpose:        Assigns a permission set group to a given user
    ----------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String permissionSetGroupName - Name of the permission set group to assign
    @                 String userId - Id of the user to assign the permission set group to
    ***************************************************************************************************************************************/
    public static void assignPermissionSetGroupToUser(String permissionSetGroupName, String userId) {
        
        // Query for the Permission Set Group by name
        PermissionSetGroup psg = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :permissionSetGroupName LIMIT 1];
        
        // Check if the assignment already exists to avoid duplicates
        List<PermissionSetAssignment> existingAssignments = [
            SELECT Id FROM PermissionSetAssignment 
            WHERE AssigneeId = :userId AND PermissionSetGroupId = :psg.Id
        ];
        
        if (existingAssignments.isEmpty()) {
            // Create the assignment
            PermissionSetAssignment assignment = new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetGroupId = psg.Id
            );
            
            insert assignment;

        } 
        
    }
    
}