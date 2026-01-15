/*********************************************************************************************************************************
@ Class:          SEP_Helper
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        Controller class for general using in SEP Community
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.5.2022 / Mony Nou / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.11.2022 / Mony Nou / US-0012023 - [FR] Accessibility Configurations
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.11.2022 / Mony Nou / US-0012027 - [IT] Accessibility Configurations
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.11.2022 / Mony Nou / US-0012333 - UK Seller Portal Profile/ Permission Set and Auto Provisioning
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.11.2022 / Mony Nou / US-0012172 - IT Seller Portal Profile/ Permission Set and Auto Provisioning
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.11.2022 / Mony Nou / US-0012329 - FR Seller Portal Profile/ Permission Set and Auto Provisioning
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.12.2022 / Mony Nou / US-0012331 - UK Login Page for Seller Portal
@                 13/12/2022 / Acmatac SEING / US-0012095 - [UK] Manage Users
@               : 06.01.2023 / Sambath Seng / US-0013001 - Domain Selection for SP Eligible Sellers
@               : 01.02.2023 / Mony Nou / US-0013139 - Seller Portal Footer, Display Current Year
@               : 17.03.2023/vadhanak voun (vadhanak.voun@gaea-sys.com)/ US-0013108 - Prevent users from accessing deep links if not agreed to master agreement
@                                                                     /just set domain labels to public
@               : 27.04.2023 / Sambath Seng / US-0013312 - IT - Page Translation and Regional Localization Deals List and Record View  
@               : 05.06.2023 / Loumang SENG / US-0013029 - Streamline of coupon seller statuses & retiring coupon fields   
@               : 14/07/2023 / Acmatac SEING / US-0013589 - Language localizations and referrer reporting for Bookings
@               : 21/07/2023 / SRONG TIN / US-0013839 - Create Deal button on Deal Window page
@               : 11/01/2024 / Mony Nou / US-0014538 - Account -Record Trigger flow -After Context Exception
@               : 15/02/2024 / Mony Nou / US-0014491 - [Tech Debt] Remove dependency from URL Domain and replace with SP Main Domain Field in SEP Features
@               : 04/06/2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c 
@               : 14/03/2025 / Mony Nou / US-0016679 - Tech debt- Add failed portal users to SEP groups
@               : 04.07.2025 / Sophal Noch / US-0033064 - Limiting paid programs visibility to only existing subscribers
@               : 24/09/2025 / Mony Nou / US-0033439 - CA SP - Update URL links for CA Seller Portal
*********************************************************************************************************************************/

public with sharing class SEP_Helper {

    //MN-22112022-US-0012333
    private static String PROFMAPPING_RECLABEL_DE = 'DE - Seller Portal'; 
    private static String PROFMAPPING_RECLABEL_NA = 'NA - Seller Portal'; 
    private static String PROFMAPPING_RECLABEL_AU = 'AU - Seller Portal'; 
    private static String PROFMAPPING_RECLABEL_UK = 'UK - Seller Portal';
    private static String PROFMAPPING_RECLABEL_IT = 'IT - Seller Portal'; //MN-22112022-US-0012172
    private static String PROFMAPPING_RECLABEL_FR = 'FR - Seller Portal'; //MN-22112022-US-0012329
    
    public static String SEP_Domain_DE = System.Label.SEP_Domain_DE; //'wachstumsportal.ebay.de' //MN-09122022-Using Custom Label instead of fixing url in it
    public static String SEP_Domain_NA = System.Label.SEP_Domain_NA; //'sellerportal.ebay.com' //MN-09122022-Using Custom Label instead of fixing url in it
    public static String SEP_Domain_CA = System.Label.SEP_Domain_CA; //DS US-0033595 - CA SP - Fix SP UI Contract Display Issues
    public static String SEP_Domain_AU = System.Label.SEP_Domain_AU; //'sellerportal.ebay.com.au'
    public static String SEP_Domain_UK = System.Label.SEP_Domain_UK; //'sellerportal.ebay.co.uk'; //MN-12122022-US-0012331- Using Custom Label instead of fixing url in it
    public static String SEP_Domain_IT = System.Label.SEP_Domain_IT; //MN-22112022-US-0012172
    public static String SEP_Domain_FR = System.Label.SEP_Domain_FR; //'portaildecroissance.ebay.fr' //MN-22112022-US-0012329 //MN-09122022-Using Custom Label instead of fixing url in it

    private final static String SEP_PUGGROUP_EU = 'DE_Seller_Portal';
    private final static String SEP_PUGGROUP_NA = 'NA_Seller_Portal';
    private final static String SEP_PUGGROUP_AU = 'AU_Seller_Portal';

    //KEY:SEP Domain store in custom label => VALUE: Custom Metadata Profile_Mapping__mdt's record name (Label field)
    public static Map<String, String> mSEPDomainProfMeta = new Map<String, String>{
        SEP_Domain_DE => PROFMAPPING_RECLABEL_DE
        , SEP_Domain_NA => PROFMAPPING_RECLABEL_NA
        , SEP_Domain_AU => PROFMAPPING_RECLABEL_AU
        , SEP_Domain_UK => PROFMAPPING_RECLABEL_UK
        , SEP_Domain_IT => PROFMAPPING_RECLABEL_IT //MN-22112022-US-0012172
        , SEP_Domain_FR => PROFMAPPING_RECLABEL_FR //MN-22112022-US-0012329
    };

    // Start SB 6.1.2023 US-0013001 - Domain Selection for SP Eligible Sellers
    private static Set<String> EU_DOMAIN_SET = new Set<String> {SEP_Domain_DE,SEP_Domain_IT,SEP_Domain_FR};
    public static Map<String, Set<String>> SP_MAIN_DOMAIN_MAPPING = new Map<String, Set<String>> {
        'US' => new Set<String> {SEP_Domain_NA},
        'CA' => new Set<String> {SEP_Domain_NA},
        'AU' => new Set<String> {SEP_Domain_AU},
        'NZ' => new Set<String> {SEP_Domain_AU}, //MN-11012024-US-0014538: Map NZ to AU Domain
        'UK' => new Set<String> {SEP_Domain_UK},
        'DE' => EU_DOMAIN_SET,
        'ROE -Other' => EU_DOMAIN_SET,
        'PL' => EU_DOMAIN_SET,
        'NL' => EU_DOMAIN_SET,
        'SE' => EU_DOMAIN_SET,
        'AT' => EU_DOMAIN_SET,
        'IT' => EU_DOMAIN_SET,
        'FR' => EU_DOMAIN_SET,
        'BE' => EU_DOMAIN_SET,
        'CZ' => EU_DOMAIN_SET,
        'DK' => EU_DOMAIN_SET,
        'GR' => EU_DOMAIN_SET,
        'HU' => EU_DOMAIN_SET,
        'IE' => EU_DOMAIN_SET,
        'LU' => EU_DOMAIN_SET,
        'PT' => EU_DOMAIN_SET,
        'RO' => EU_DOMAIN_SET,
        'SK' => EU_DOMAIN_SET,
        'ES' => EU_DOMAIN_SET
    };
    // End SB 6.1.2023 US-0013001 - Domain Selection for SP Eligible Sellers

    //MN-14032025-US-0016679
    public static Map<String, String> mSEPDomainPubGroup = new Map<String, String>{
        SEP_Domain_DE => SEP_PUGGROUP_EU
        , SEP_Domain_NA => SEP_PUGGROUP_NA
        , SEP_Domain_AU => SEP_PUGGROUP_AU
        , SEP_Domain_UK => SEP_PUGGROUP_EU
        , SEP_Domain_IT => SEP_PUGGROUP_EU 
        , SEP_Domain_FR => SEP_PUGGROUP_EU
    };

    // 04.07.2025 / Sophal Noch / US-0033064 : create variable to use in checking GSD Account Manager eligibilit
    private final static String BS_STATUS_ACTIVE = 'Draft';
    private final static String BS_OBJNAME = 'BoB_Seller__c';
    private final static String BS_RT_LTTM = 'LTTM';
    private final static Set<String> SET_BS_GSD_AM_COUNTRY = new Set<String>{'0', '1', '77','3'};
    private final static String BS_MANGEDTYPE_MANAGED_BOB = 'Managed BoB';
    private final static Id BS_RT_LTTM_ID = ApexUtil.getRecordTypeByName(BS_OBJNAME, BS_RT_LTTM)?.Id;
    private final static Set<String> SET_BS_GSD_AM_MANAGED_SGEMENT = new Set<String>{
		'Enterprise', 
		'Strategic'
	}; 

    /*****************************************************************************************************************************
    @ Method:         initRecordInfo
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        US-0011689 - Deployment window alert
    @                   + Init method for lwcRecordInfor
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.06.2022 / Mony Nou / Created the  Method.
    *****************************************************************************************************************************/
    
    private static String COUPONSELLER_API = 'Coupon_Seller__c';
    private static String COUPONSELLER_STAGE_TARGETED = 'Targeted';
    private static String COUPONSELLER_STAGE_REACHED = 'Reached';
    //private static String COUPONSELLER_STAGE_COMMITED = 'Commited';//LA-05-06-2023-US-0013029: Retire picklist value 'Commited' from Coupon_Seller_Stage__c 
    private static String COUPONSELLER_STAGE_NEGOTIATION = 'Contract Negotiation';
    private static String COUPONSELLER_COUPONTYPE_ITEM = 'Item Based';
    private static String COUPONSELLER_COUPONTYPE_CATE = 'Category Based';

    private static Map<String, String> mSObjSOQL = new Map<String, String>{
        COUPONSELLER_API => 'Select Coupon_Seller_Stage__c, Coupon_Type__c From Coupon_Seller__c WHERE Id=:recId'
    };

    @AuraEnabled
    public static Map<String,Object> initRecordInfo(String recId, String metaName, String overrideMetaName) {

        Map<String,Object> mapResult = new Map<String,Object>();
        
        //Get sObject API by RecordId 
        if (String.isNotBlank(recId)) {
            String sobj_api = getSObjectAPI(Id.valueOf(recId));
            SObject rec;
            if (mSObjSOQL.containsKey(sobj_api)) {
                 rec = Database.query(mSObjSOQL.get(sobj_api));
                
            }

            if (sobj_api.equalsIgnoreCase(COUPONSELLER_API)) {
                
                //Set<String> sNotConfirmedStage = new Set<String> {COUPONSELLER_STAGE_TARGETED, COUPONSELLER_STAGE_REACHED, COUPONSELLER_STAGE_COMMITED};//LA-05-06-2023-US-0013029: Retire picklist value 'Commited' from Coupon_Seller_Stage__c 
                Set<String> sNotConfirmedStage = new Set<String> {COUPONSELLER_STAGE_TARGETED, COUPONSELLER_STAGE_REACHED};//LA-05-06-2023-US-0013029: Retire picklist value 'Commited' from Coupon_Seller_Stage__c 

                Coupon_Seller__c cs = (Coupon_Seller__c) rec;

                if ((sNotConfirmedStage.contains(cs.Coupon_Seller_Stage__c) && (cs.Coupon_Type__c == COUPONSELLER_COUPONTYPE_ITEM || cs.Coupon_Type__c == COUPONSELLER_COUPONTYPE_CATE)) 
                        || (cs.Coupon_Seller_Stage__c == COUPONSELLER_STAGE_NEGOTIATION && cs.Coupon_Type__c == COUPONSELLER_COUPONTYPE_CATE)) {
                    
                    metaName = 'SEP_Coupon_Seller_Record_Info';
                    mapResult.put('metadataName', metaName);
                    
                }
                
                
            }

        }

        if (String.isNotBlank(overrideMetaName)) metaName = overrideMetaName;

        //Get Metadata
        if (String.isNotBlank(metaName)) {
            //MN-03112022-US-0012023-Adding Value_in_French__c  into query
            //MN-04112022-US-0012027-Adding Value_in_Italian__c  into query
            for (Seller_Portal_Global_Variables__mdt spgv : [SELECT Value__c, Value_Big__c, Value_in_German__c, Value_in_French__c, Value_in_Italian__c FROM Seller_Portal_Global_Variables__mdt WHERE DeveloperName =: metaName]) {
                mapResult.put('meta', spgv);
            }
        }


        String userLang = UserInfo.getLanguage();
        SEPWindowAlert__c sepwa = SEPWindowAlert__c.getOrgDefaults();
        
        mapResult.put('userLang',userLang);
        mapResult.put('isDeploying', sepwa.Deploying__c);
        
       
        return mapResult;
    }


    private static String getSObjectAPI (Id recordId) {
        Schema.SObjectType sobjectType = recordId.getSObjectType();
        String sobjectName = sobjectType.getDescribe().getName();
        return sobjectName;
    }


    /***********************************************************************************************************************************
    @ Method:       getProfileMappingMetaName
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        To return Custom Metadata Profile_Mapping__mdt's record label so that we can use it to update User's infor such as
    @                   + Locale, Language, Currency, Timezone
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21/11/2022 / Mony Nou / US-0012333 - UK Seller Portal Profile/ Permission Set and Auto Provisioning
    @                   13/12/2022 / Acmatac SEING / US-0012095 - Clone logic to another overload method
    ***********************************************************************************************************************************/
    public static String getProfileMappingMetaName() {
        
        // String defDomain = SEP_Domain_DE; //Default DE;
        String curDomain = (ApexUtil.runningInASandbox())?System.Label.SEP_Current_Sandbox_Domain:ApexUtil.getDomain();

        // if (String.isBlank(curDomain)) curDomain = defDomain;

        // return (mSEPDomainProfMeta.containsKey(curDomain))?mSEPDomainProfMeta.get(curDomain):mSEPDomainProfMeta.get(defDomain);
        return getProfileMappingMetaName(curDomain);
    }

    /***********************************************************************************************************************************
    @ Method:       getProfileMappingMetaName
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Author:       Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:      US-0012095 - [UK] Manage Users
    @ Param:        String domainStr => domain of the site. Example : sellerportal.ebay.com, wachstumsportal.ebay.de
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  13/12/2022 / Acmatac SEING / US-0012095 - [UK] Manage Users
    ***********************************************************************************************************************************/
    public static String getProfileMappingMetaName(String domainStr) {
        if(SEP_Helper.mSEPDomainProfMeta.containsKey(domainStr)){
            return SEP_Helper.mSEPDomainProfMeta.get(domainStr);
        }else{
            //Default DE;
            return SEP_Helper.PROFMAPPING_RECLABEL_DE;
        }

    }
        
    //NK:21/12/2022:US-0012914
    public final static Map<String, String> DOMAIN_AUTH_MAPPING = new Map<String,String>
    {
        SEP_Domain_DE=>'eBay_DE_Login',
        SEP_Domain_NA=>'Sign_in_with_eBay_Logins',
        SEP_Domain_AU=>'eBay_AU_Login',
        SEP_Domain_UK=>'eBay_UK_Login',
        SEP_Domain_IT=>'eBay_IT_Login',
        SEP_Domain_FR=>'eBay_FR_Login'
    };
    

    /***********************************************************************************************************************************
    @ Method:       getPortalDomain
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Get Current Portal Domain's infor
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01/02/2022 / Mony Nou / US-0013139 - Seller Portal Footer, Display Current Year
    @               :  27.04.2023 / Sambath Seng / US-0013312 - IT - Page Translation and Regional Localization Deals List and Record View
    @               :  24/09/2025 / Mony Nou / US-0033439 - CA SP - Update URL links for CA Seller Portal     
    ***********************************************************************************************************************************/
    private static Map<String, String> mDomainFooter = new Map<String, String> {
        SEP_Domain_DE => System.Label.PortalFooter_SEP_DE,
        SEP_Domain_NA => System.Label.PortalFooter_SEP_NA,
        SEP_Domain_UK => System.Label.PortalFooter_SEP_UK,
        SEP_Domain_IT => System.Label.PortalFooter_SEP_IT,
        SEP_Domain_FR => System.Label.PortalFooter_SEP_FR,
        SEP_Domain_AU => System.Label.PortalFooter_SEP_AU
    };

    // 14/07/2023 / Acmatac SEING / US-0013589 - Language localizations and referrer reporting for Bookings
    private static Map<String, String> mRevRollupFooter = new Map<String, String> {
        'US'  => System.Label.PortalFooter_SEP_NA,
        'DE' => System.Label.PortalFooter_SEP_DE,
        'IT'  => System.Label.PortalFooter_SEP_IT,
        'FR'  => System.Label.PortalFooter_SEP_FR
    };

    //MN-24092025-US-0033439: Map Domain with specific RevRollup Footer
    private static Map<String, Map<String, String>> mDomainRevRollup = new Map<String, Map<String, String>> {
        SEP_Domain_NA => new Map<String, String>{
            'CA'=>System.Label.PortalFooter_SEP_CA
        }
    };

    @AuraEnabled(cacheable=true) 
    public static Map<String, Object> getPortalDomain() {

        Map<String, Object> mResult = new Map<String, Object>();

        //String curDomain = (ApexUtil.runningInASandbox())?System.Label.SEP_Current_Sandbox_Domain:ApexUtil.getDomain(); //MN-15022024-US-0014491
        String curDomain = getSPMainDomain(); //MN-15022024-US-0014491
        if (String.isBlank(curDomain)) curDomain = ApexUtil.getDomain(); //MN-15022024-US-0014491: If SP Main Domain is empty, use the url as domain
        
        String footer_str = (mDomainFooter.containsKey(curDomain))?mDomainFooter.get(curDomain):mDomainFooter.get(SEP_Domain_DE); //Default with DE Footer


        //MN-24092025-US-0033439: If Domain has specific RevRollup Footer mapping, then check and replace the footer
        if (mDomainRevRollup.containsKey(curDomain) && mDomainRevRollup.get(curDomain).containsKey(SEP_Helper.sepUser.revRollup)) {
            footer_str = mDomainRevRollup.get(curDomain).get(SEP_Helper.sepUser.revRollup); 
        }

        mResult.put('footer_str', footer_str);
        // SB 27.04.2023 US-0013312
        mResult.put('isIT', curDomain==SEP_Domain_IT);
        // SRONG 21-7-2023 US-0013839
        mResult.put('isNA', curDomain==SEP_Domain_NA);
        mResult.put('isAU', curDomain==SEP_Domain_AU);

        mResult.put('isEU', SEP_Helper.sepUser.isEU()); //MN-05062024-US-0015298

        return mResult;
    }

    /***********************************************************************************************************************************
    @ Method:       getPortalFooter
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Author:       Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:      Get Portal Footer
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.07.2023 / Acmatac Seing / US-0013589 - Language localizations and referrer reporting for Bookings
    ***********************************************************************************************************************************/
    @AuraEnabled(cacheable=true) 
    public static Map<String, Object> getPortalFooter(String selectedPortal) {
        Map<String, Object> mResult = new Map<String, Object>();
        if(selectedPortal == 'eBay Seller Portal'){
            mResult = getPortalDomain();
        }else if(selectedPortal == 'Booking Portal'){
            String footer_str = mRevRollupFooter.get('US');
            for(User currentUser: [SELECT Id, Contact.Account.EBH_RevRollup__c FROM User Where Id=:UserInfo.getUserId() AND Contact.Account.EBH_RevRollup__c!=null]){
                footer_str = mRevRollupFooter.containsKey(currentUser.Contact.Account.EBH_RevRollup__c)?mRevRollupFooter.get(currentUser.Contact.Account.EBH_RevRollup__c):mRevRollupFooter.get('US');
            }
            mResult.put('footer_str', footer_str);
        }
    
        return mResult;
    }

    /***********************************************************************************************************************************
    @ Method:       getCurrentDomain
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Author:       Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:      US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.05.2023 / Sambath Seng / Create method
    ***********************************************************************************************************************************/
    Public static String getCurrentDomain() {
        return (ApexUtil.runningInASandbox())?System.Label.SEP_Current_Sandbox_Domain:ApexUtil.getDomain();
    }

    /***********************************************************************************************************************************
    @ Method:       getSPMainDomain
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Get SP Main Domain for Community User (User.Contact.Account.SP_Main_Domain__c)
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  12.09.2023 / Mony Nou / Create method
    ***********************************************************************************************************************************/
    Public static String getSPMainDomain() {
        
        String spMainDomain = '';

        //MN-25092025-Fixed PMD security violation
        String query = 'SELECT Contact.Account.SP_Main_Domain__c FROM User WHERE Id=:UserId';
        List<User> users = ApexSafe.query().secCheck(false).doQuery(query, new Map<String, Object>{'UserId' => UserInfo.getUserId()});
        for (User u: users) {
            spMainDomain = u.Contact.Account.SP_Main_Domain__c;
        }
        return spMainDomain;

    }

    /***********************************************************************************************************************************
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Wrapper Class, Method, Get/Set Variable for SEPUser      
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  04.06.2024 / Mony Nou / Create method
    ***********************************************************************************************************************************/
    public static SEPUser sepUser {
        get {
            if (sepUser == null) {
                sepUser = new SEPUser();
            }
            return sepUser;
        }
        private set;
    }

    public class SEPUser {

        public String domain;
        public User user;
        public String revRollup; //MN-24092025-US-0033439

        public SEPUser() {
            //this.domain = SEP_Helper.getSPMainDomain();
            this.user = new User();
            //MN-24092025-US-0033439: Added EBH_RevRollup__c to the query
            String soql = 'SELECT Id, Profile.Name, ContactId, Contact.AccountId, Contact.Account.Id, Contact.Account.SP_Deals__c, Contact.Account.SP_Main_Domain__c, Contact.Account.FinalSPMainDomain__c, Contact.Account.EBH_RevRollup__c FROM User WHERE Id=:userId';
            List<User> users = ApexSafe.query().secCheck(false).doQuery(soql, new Map<String, Object>{'userId' => UserInfo.getUserId()});
            for (User u: users) {
                this.domain = u.Contact.Account.FinalSPMainDomain__c;
                this.user = u;
                this.revRollup = u.Contact?.Account?.EBH_RevRollup__c; //MN-24092025-US-0033439
            }
        }

        //MN-24092025-US-0033439: Check if the user is from CA RevRollup
        public Boolean isCARRU() {
            return isNA() && String.isNotBlank(revRollup) && revRollup == 'CA';
        }

        public Boolean isDE() {
            return (String.isNotBlank(domain) && domain.equalsIgnoreCase(SEP_Domain_DE));
        }

        public Boolean isNA() {
            return (String.isNotBlank(domain) && domain.equalsIgnoreCase(SEP_Domain_NA));
        }

        public Boolean isAU() {
            return (String.isNotBlank(domain) && domain.equalsIgnoreCase(SEP_Domain_AU));
        }

        public Boolean isFR() {
            return (String.isNotBlank(domain) && domain.equalsIgnoreCase(SEP_Domain_FR));
        }

        public Boolean isIT() {
            return (String.isNotBlank(domain) && domain.equalsIgnoreCase(SEP_Domain_IT));
        }

        public Boolean isUK() {
            return (String.isNotBlank(domain) && domain.equalsIgnoreCase(SEP_Domain_UK));
        }

        public Boolean isEU() {
            return isDE() || isIT() || isFR() || isUK();
        }   
    }


    /*****************************************************************************************************************************
    @ Method:   isGSDAccMgnEligible
    @ Version:  1.0
    @ Author:   Sophal Noch
    @ Purpose:  04.07.2025 / Sophal Noch / US-0033064 - Limiting paid programs visibility to only existing subscribers
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: BoB_Seller__c bs
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  04.07.2025 / Sophal Noch / US-0033064 / Created the Method.
    *****************************************************************************************************************************/
    public static Boolean isGSDAccMgnEligible(BoB_Seller__c bs){
        // this method also used in class BoBSellerTriggerHandler and AbstractBatchCohortAction
        // It is use to check if GSD Account Management cohort seller is eligible
        return
        bs.RecordTypeId == BS_RT_LTTM_ID
        && bs.Managed_Type__c == BS_MANGEDTYPE_MANAGED_BOB
        && SET_BS_GSD_AM_MANAGED_SGEMENT.contains(bs.EBH_BOBSegment__c)
        && bs.Status__c == BS_STATUS_ACTIVE
        && SET_BS_GSD_AM_COUNTRY.contains(bs.BoB_Country__c);
    }
}