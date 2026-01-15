/*********************************************************************************************************************************
@ Class:          ClsBulkUploadCSV
@ Version:        1.0
@ Author:         Sochettra Saing
@ Purpose:        Ability to create multiple Deals in one time(EBAY-228)
@ ClsSubmitMultipleDealsController for LWC lwcSubmitMultipleDeals
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.07.2021 / Sochettra Saing / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.12.2021 / Mony Nou / US-0010730- [SP - EU Deals] [Bug] Deleted Deals not removed from recycle bin affecting daily limit count
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.12.2021 / Mony Nou / US-0011048 - Remove codes that try to query DRC & Deal when page on load because when page on load there is no DRC selected yet
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.05.2022 / Mony Nou / US-0010656 - Ability to upload/manage items to item based coupons
@               30-08-2022/ vadhanak voun/ US-0012297 - BETA Feedback
@               09-09-2022/ sovantheany Dim/ US-0012281 - Validation and upload of Deals
@               24-10-2022 /Bora Chhorn/ US-0012600 - Enable Link Multiple Accounts for NA/ AU Portal Sellers
@               28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations 
@               03-11-2022 / Sovantheany Dim / US-0012494 - Simplify Item Upload Process
@               03.11.2022 / Sambath Seng / US-0012877 - Simplify Item Upload Process for PM Deals
@               22.11.2022 / Sambath Seng / US-0012026 - [FR] Localization for Item Upload template file
@               23.11.2022 / Sambath Seng / US-0012030 - [IT] Localization for Item Upload template file
@               24.11.2022 / vadhanak voun / US-0012035 - [UK] Localization for Item Upload template file
@               08.12.2022 / SRONG TIN / US-0012861 - Move content of MyPickListInfo to ClsBulkUploadCSV
@               09.01.2023 / Bora Chhorn / US-0013053 - Deal Price should be stamped on Seller Price for Un-Sub Deals
@               20.02.2023 / Bora Chhorn / US-0013232 - UK Beta Testing Fixes
@               22.03.2023 / Mony Nou / US-0012628 - Seller Deal Cancellation - on Seller Portal
@               26.04.2023 / SRONG TIN / US-0013352 - IT - Deals Bulk Upload Localization and translation
@               09.06.2023 / Sophal Noch / US-0013666 - Ability to restrict number of items per seller to be uploaded against item based coupon
@               12.10.2023 / Mony Nou / US-0012769 - Discontinue use of 'Without Sharing' for Deals/Coupons
@                                           - Change from "Without Sharing" to "With Sharing"
@               14.11.2023 / Mony Nou / US-0014404 - Item limit on coupon seller is not working
@               05-12-2023 /SRONG TIN/ US-0014342 - Regression test issue on DE / NA Feature process
@               16.05.2024 /SRONG TIN/ US-0015312 - Item Upload Template download button not working
@               04/06/2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
*********************************************************************************************************************************/
public with sharing class ClsBulkUploadCSV {
    private static String DE_pfName = 'DE - Seller Portal';
    private static final String STATUS_REJECTED = 'Rejected';
    private static final String STATUS_SELLERCANCELLED = 'Seller Cancelled'; //MN-22032023-US-0012628
    private static final String STATUS_INVREJECTED = 'Invoice Rejected (Email resend to Seller)';
    
    private final static String PF_PORTAL_NA = 'NA - Seller Portal';
    private final static String PORTAL_AU = 'AU - Seller Portal';
    private final static String STATUS_IN_PROGRESS = 'In Progress';
    private final static String STATUS_REVIEW = 'Review';
    private final static String PORTAL_FR_LANG = 'fr';//SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
    private final static String PORTAL_DE_LANG = 'de';//SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
    private final static String PORTAL_IT_LANG = 'it';//SB 22.11.2022 US-0012030 - [IT] Localization for Item Upload template file
    private final static String PORTAL_EN_LANG = 'en_US'; //NK:24/11/2022:US-0012035
    private final static String PORTAL_UK_LANG = 'en_GB'; //SRONG:16/05/2024:US-0015312
    private final static Id UNSUB_DEAL_RTID = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V3').Id; //BR 09-01-2023-US-0013053
    private final static Map<String, Object> portalDomain = SEP_Helper.getPortalDomain();//26.04.2023 / SRONG TIN / US-0013352
    private final static Id ITEM_BASED_COUPON_RTID = ApexUtil.getRecordTypeByName('Coupon__c', 'Item_Based').Id; // 09.06.2023 / Sophal Noch / US-0013666
    
    /*****************************************************************************************************************************
    @ Method:         doSubmitMultipleCouponItems
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        US-0010656 - Ability to upload/manage items to item based coupons
    @                 Bulk Create Coupon Co-Inves Records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<Coupon_Co_Invest__c> lstCPItems (Multiples Coupon Co-Invest from uploaded CSV)
    @ Parameter:      String csCouponType (Coupon Seller's Coupon Type)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17-05-2022 /Mony Nou/ Created the  Method.
    @ Change history: 03-11-2022 / Sovantheany Dim / US-0012494 - Simplify Item Upload Process
    *****************************************************************************************************************************/
    private static Map<String, String> mCouponCoInvestRT = new Map<String, String>{
        'Item Based' => 'Coupon Co-Invest Item'
    };

    @AuraEnabled
    public static Object doSubmitMultipleCouponItems (List<Coupon_Co_Invest__c> lstCPItems, String csCouponType) {
        
        Map<String,Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{

            if (String.isNotBlank(csCouponType) && mCouponCoInvestRT.containsKey(csCouponType)) {
                Id cciRT = Schema.SObjectType.Coupon_Co_Invest__c.getRecordTypeInfosByName().get(mCouponCoInvestRT.get(csCouponType)).getRecordTypeId();
                for (Coupon_Co_Invest__c cci : lstCPItems) {
                    cci.RecordTypeId = cciRT;
                }
            } 
            Savepoint sp = Database.setSavepoint();
            
            //Database.SaveResult[] srList = Database.insert(lstCPItems, false);
            //MN-18102023-US-0012769: We need to use WithoutSharing.doInsert for CouponItem upload because we have to populate Coupon into Coupon_Name lookup field and that's required read access to that Coupon record and SEP User do not have access to any Coupon Record.
            Database.SaveResult[] srList = WithoutSharing.doInsert(lstCPItems, false);
            
            //TH:03/11/2022:US-0012494 - Simplify Item Upload Process
            Boolean isSomeFail = false;
            for(Database.SaveResult result : srList){
                if(!result.isSuccess()){
                    isSomeFail = true;
                    break;
                }
            }
            mResult.put('srList', JSON.serialize(srList));
            mResult.put('message', '');
            mResult.put('status', 'success');
            mResult.put('lstCPItems', lstCPItems);
            if(isSomeFail)  Database.rollback(sp);
            
        } catch ( Exception ex) {
            System.debug('@@@@@messgee'+ex);
            mResult.put('message', 'Error:'+ex.getLineNumber()+':'+ ex.getMessage());
        }
        return mResult;
    }
    
    /*****************************************************************************************************************************
    @ Method:         doSubmitMultipleDealsForDCA
    @ Version:        1.0
    @ Author:         Sovantheany Dim
    @ Purpose:        US-0012281 - Validation and upload of Deals
    @                 Bulk Create Deals Records for Deal Contract Agreement
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<EBH_Deal__c> lstDeals
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07-09-2022 /Sovantheany Dim/ Created the  Method.
                      03.11.2022 / Sambath Seng / US-0012877 - Simplify Item Upload Process for PM Deals
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Object doSubmitMultipleDealsForDCA (List<EBH_Deal__c> lstDeals) {
        Map<String,Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{
            RecordType rt_PMdeal = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'PM_Deal');
            for (EBH_Deal__c deal : lstDeals) {
                deal.RecordTypeId = rt_PMdeal.Id;
            }
            Savepoint sp = Database.setSavepoint(); // SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
            Database.SaveResult[] srList = Database.insert(lstDeals, false);
            // Start SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
            Boolean isSomeFail = false;
            for(Database.SaveResult result : srList){
                if(!result.isSuccess()){
                    isSomeFail = true;
                    break;
                }
            }
            // End SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
            mResult.put('srList', JSON.serialize(srList));
            //mResult.put('srList', srList);
            mResult.put('message', '');
            mResult.put('status', 'success');
            mResult.put('lstDeals', lstDeals);
            if(isSomeFail)  Database.rollback(sp); // SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
            
        } catch ( Exception ex) {
            System.debug('@@@@@messgee'+ex);
            mResult.put('message', 'Error:'+ex.getLineNumber()+':'+ ex.getMessage());
        }
        return mResult;
    }

    @AuraEnabled
    public static Object doSubmitMultipleDeals(List<EBH_Deal__c> lstDeals, String accountId) {
        
        Map<String,Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{
            // SRONG TIN - 17/03/2022 : US-0011338
            String dealReatilCampaingId = '';
            String currUserLang = '';
            for(User u : [SELECT Id, Profile.Name From User WHERE Id =: UserInfo.getUserID()]) {
                currUserLang = u.Profile.Name;
            }
            //insert lstDeals;
            for(EBH_Deal__c deal : lstDeals){
                deal.EBH_BusinessName__c = accountId;

                /* MN-04062024-US-0015298
                // SRONG TIN - 17/03/2022 : US-0011338
                if(currUserLang == DE_pfName){
                    if(String.isNotBlank(deal.EBH_DealRetailCampaign__c)){
                        dealReatilCampaingId = deal.EBH_DealRetailCampaign__c;
                    }
                }
                */

                //MN-04062024-US-0015298: Check current user's SP Main Domain instead of Profile Name
                if(SEP_Helper.sepUser.isEU()){
                    if(String.isNotBlank(deal.EBH_DealRetailCampaign__c)){
                        dealReatilCampaingId = deal.EBH_DealRetailCampaign__c;
                    }
                }

                /* MN-04062024-US-0015298
                //BR 09-01-2023-US-0013053
                //Check Deal Bulk Upload in SEP for NA & AU for Deal_V3 ONLY
                // 26-04-2023 /SRONG TIN/ US-0013352
                if(String.isNotBlank(deal.EBH_DealRetailCampaign__c) && (currUserLang == PF_PORTAL_NA || currUserLang == PORTAL_AU || portalDomain.get('isIT') == true)){
                    deal.RecordTypeId = UNSUB_DEAL_RTID;
                    deal.EBH_SellerPrice__c = deal.EBH_DealPrice__c;
                }
                */

                //MN-04062024-US-0015298: Check current user's SP Main Domain instead of Profile Name
                if(String.isNotBlank(deal.EBH_DealRetailCampaign__c) && (SEP_Helper.sepUser.isNA() || SEP_Helper.sepUser.isAU() || SEP_Helper.sepUser.isIT())) {
                    deal.RecordTypeId = UNSUB_DEAL_RTID;
                    deal.EBH_SellerPrice__c = deal.EBH_DealPrice__c;
                }
            }

            /* MN-04062024-US-0015298
            // SRONG TIN - 17/03/2022 : US-0011338
            if(currUserLang == DE_pfName && String.isNotBlank(dealReatilCampaingId)){
                EBH_DealTriggerHandler.isFromBulkUpload_DE = true;
            }
            */

            //MN-04062024-US-0015298: Check current user's SP Main Domain instead of Profile Name
            if(SEP_Helper.sepUser.isEU() && String.isNotBlank(dealReatilCampaingId)){
                EBH_DealTriggerHandler.isFromBulkUpload_DE = true;
            }

            Database.SaveResult[] srList = Database.insert(lstDeals, false);
            mResult.put('srList', JSON.serialize(srList));
            mResult.put('message', 'The Deals are submitted successfully!');
            mResult.put('status', 'success');
            mResult.put('isFromBulkUpload_DE', EBH_DealTriggerHandler.isFromBulkUpload_DE);
            mResult.put('lstDeals', lstDeals);

            // Iterate through each returned result
            /*for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }*/
            
            
        } catch ( Exception ex) {
            System.debug('@@@@@messgee'+ex);
            mResult.put('message', 'Error:'+ex.getLineNumber()+':'+ ex.getMessage());
        }
        return mResult;
    }

    /*@AuraEnabled
    public static Object doClearHalfCompleteDeals(List<EBH_Deal__c> lstDeals) {
        Map<String,Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{
            delete lstDeals;
            Database.emptyRecycleBin(lstDeals);
            mResult.put('status', 'success');
            //mResult.put('lstDeals', lstDeals);
            mResult.put('message', 'The Deals are removed successfully!');
            
        } catch ( Exception ex) {
            mResult.put('message', 'Error:'+ex.getLineNumber()+':'+ ex.getMessage());
        }
        return mResult;
    }*/

    @AuraEnabled
    public static Object doLoadSetting(String dealReatilCampaingId){
        Map<String, Object> mResult = new Map<String, Object>();
        mResult.put('status', 'error');
        try{
            //LA-29-11-2021-US-0010733: commmend this code and move to method getTodayDealSetting(dealReatilCampaingId);
            /*Decimal maxDealWindow = 100; 
            String userId = '';
            String accountId = '';
            String contactId = '';
            String fullContactName = '';
            String conEmail = '';
            String currUserLang = '';
            String parentAccId = '';
            for(User u : [SELECT Id, Profile.Name, ContactId, Contact.LastName, Contact.FirstName, Contact.Email, Contact.AccountId, Contact.Account.Parent_Account_ID__c, Contact.Account.Deal_Window_Limit__c, Contact.Account.EBH_RegistrationSite__c From User WHERE Id =: UserInfo.getUserID()]) {
                userId = u.Id;
                if(u.ContactId != null) {
                    conEmail = u.Contact.Email;
                    contactId = u.ContactId;
                    fullContactName = u.Contact.FirstName+ ' ' + u.Contact.LastName ;
                }
                if(u.ContactId != null && u.Contact.AccountId != null ) {
                    maxDealWindow = u.Contact.Account.Deal_Window_Limit__c;
                    accountId = u.Contact.AccountId;
                    parentAccId = u.Contact.Account.Parent_Account_ID__c;
                    //currUserLang = u.Contact.Account.EBH_RegistrationSite__c;
                }
                if(u.ProfileId != null) {
                    currUserLang = u.Profile.Name;
                }
            }*/
            // 'a0u1F0000022jpnQAA'
            //Decimal totalDeal = [SELECT Count() FROM EBH_Deal__c WHERE EBH_DealRetailCampaign__c =: dealReatilCampaingId AND EBH_Status__c != 'Rejected'];
            //List<EBH_Deal__c> lstDeal = [SELECT EBH_eBayItemID__c FROM EBH_Deal__c WHERE EBH_DealRetailCampaign__c =: dealReatilCampaingId AND EBH_Status__c != 'Rejected'];
            mResult = getTodayDealSetting(dealReatilCampaingId);//LA-29-11-2021-US-0010733
            if(mResult.get('status') == 'error') return mResult;
            String currUserLang= (String)mResult.get('currUserLang');

            /* //MN-21122021-US-0011048 - When page is onload, user not yet select any DRC yet so there is no use to query it with NULL DRC's ID => query EVERYTHING
            String query = 'SELECT EBH_eBayItemID__c FROM EBH_Deal__c WHERE EBH_DealRetailCampaign__c =: dealReatilCampaingId AND EBH_Status__c !=: STATUS_REJECTED ';
            query += (currUserLang == DE_pfName ? ' AND EBH_DealSiteId__c = \'77\' ': '');
            System.debug('query: '+query);
            List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
            for(EBH_Deal__c[] deals: Database.query(query)){
                lstDeal.addAll(deals);
            }
            */
            String dd_DuplicateError = System.Label.DD_DuplicateError ;
            // mResult.put('query', query+ '   :'+ dealReatilCampaingId); //MN-21122021-US-0011048
            mResult.put('dd_DuplicateError', dd_DuplicateError); 

            // mResult.put('lstDeal', lstDeal); //MN-21122021-US-0011048 - When page is onload, user not yet select any DRC yet so there is no use to query it with NULL DRC's ID => query EVERYTHING

            /****LA-29-11-2021-US-0010733: commmend this code and move to method getTodayDealSetting(dealReatilCampaingId);***/
            //SELECT COUNT() FROM Account WHERE Name LIKE 'a%'
            //mResult.put('availableDeal', maxDealWindow - lstDeal.size());
            /* mResult.put('availableDeal', maxDealWindow - ([SELECT COUNT() FROM EBH_Deal__c WHERE EBH_DealRetailCampaign__c =: dealReatilCampaingId AND EBH_BusinessName__c =: accountId AND EBH_Status__c != 'Rejected']));
            if(currUserLang == DE_pfName) {
                mResult.put('totalDealOfDEToday', [SELECT COUNT() FROM EBH_Deal__c WHERE CreatedDate = TODAY AND EBH_BusinessName__r.Parent_Account_ID__c =: parentAccId]);
                mResult.put('fieldDependencies', ClsBulkUploadCSV.getFieldDependencies('EBH_Deal__c','EBH_DealSiteId__c','EBH_Category__c'));
            }
            mResult.put('userId', userId);
            mResult.put('accountId', accountId);
            mResult.put('contactId', contactId);
            mResult.put('fullContactName', fullContactName);
            mResult.put('conEmail', conEmail);
            mResult.put('currUserLang', currUserLang);
            mResult.put('status', 'success');*/

        } catch(Exception ex) {
            mResult.put('message', ex.getMessage());
        }
        
        return mResult;  
    }

    /*****************************************************************************************************************************
    @ Method:         doDELoadSetting RENAME -> doLoadSettingLinkedAccount // BR-24-10-22-US-0012600
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        US-0010950 - Account Selection field on Deal Creation/List Views
    @                 Individual init function for dealBulkUploadDE
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dealReatilCampaingId
    @ Parameter:      String accountId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29-11-2021 /Mony Nou/ Created the  Method.
    @ Change history: 24-10-2022 /Bora Chhorn/ US-0012600 - Enable Link Multiple Accounts for NA/ AU Portal Sellers
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Object doLoadSettingLinkedAccount(String dealReatilCampaingId, String accountId){
        Map<String, Object> mResult = new Map<String, Object>();
        mResult.put('status', 'error');
        try{
            eligibleAccountId = accountId;
            
            mResult = getTodayDealSetting(dealReatilCampaingId);
            if(mResult.get('status') == 'error') return mResult;
            String currUserLang= (String)mResult.get('currUserLang');

            String dd_DuplicateError = System.Label.DD_DuplicateError ;
            
            mResult.put('dd_DuplicateError', dd_DuplicateError); 

        } catch(Exception ex) {
            mResult.put('message', ex.getMessage());
        }
        
        return mResult;  
    }

    @AuraEnabled
    public static Object getDealRetailCampaign(String recordId){
        Map<String, Object> mResult = new Map<String, Object>();
        mResult.put('status', 'error');
        try{
            EBH_DealRetailCampaign__c dealRetailCampaign = [SELECT Id, Start_Time__c, EBH_Date__c, End_Time__c, EPH_EndDate__c, EBH_Country__c FROM EBH_DealRetailCampaign__c WHERE Id = :recordId];
            mResult.put('status', 'success');
            mResult.put('dealRetailCampaign', dealRetailCampaign);
            mResult.put('message', 'The Deal Retail Campaign was retrived successfully!');
        }
        catch(Exception ex) {
            mResult.put('message', ex.getMessage());
        }
        return mResult;  
    }

    //MN-21122021-US-0011048 - add one more param currUserLang because we move some logic m doLoadSetting() to here 
    @AuraEnabled
    public static Object getDealOverlapDateDRC(String drcId, String currUserLang){
        Map<String, Object> mResult = new Map<String, Object>();
        mResult.put('status', 'error');
        try{
            Date startDate;
            Date endDate;
            for(EBH_DealRetailCampaign__c drc : [SELECT Id, Start_Time__c, EBH_Date__c, End_Time__c, EPH_EndDate__c, EBH_Country__c FROM EBH_DealRetailCampaign__c WHERE Id = :drcId]) {
                startDate = drc.EBH_Date__c;
                endDate = drc.EPH_EndDate__c;
            }

            List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
            if(startDate != null && endDate != null){
                lstDeal = [SELECT Id, EBH_eBayItemID__c, EBH_DealRetailCampaign__r.EBH_Date__c, EBH_DealRetailCampaign__r.EPH_EndDate__c FROM EBH_Deal__c WHERE EBH_DealSiteId__c = '77' AND ((EBH_DealRetailCampaign__r.EBH_Date__c <= : startDate AND EBH_DealRetailCampaign__r.EPH_EndDate__c >=: startDate) OR (EBH_DealRetailCampaign__r.EBH_Date__c >= : startDate AND EBH_DealRetailCampaign__r.EBH_Date__c <=: endDate))];
            }

            //MN-22032023-US-0012628 - Including status "Seller Cancelled"
            Set<String> sOptOutStatus = new Set<String>{ STATUS_REJECTED, STATUS_SELLERCANCELLED};

            //MN-21122021-US-0011048 - Move from doLoadSetting()
            //String query = 'SELECT EBH_eBayItemID__c FROM EBH_Deal__c WHERE EBH_DealRetailCampaign__c =: drcId AND EBH_Status__c !=: STATUS_REJECTED ';
            String query = 'SELECT EBH_eBayItemID__c FROM EBH_Deal__c WHERE EBH_DealRetailCampaign__c =: drcId AND EBH_Status__c NOT IN:sOptOutStatus ';
            
            /* MN-04062024-US-0015298
            query += (currUserLang == DE_pfName ? ' AND EBH_DealSiteId__c = \'77\' ': '');
            */

            //MN-04062024-US-0015298: Check current user's SP Main Domain instead of Profile Name
            query += (SEP_Helper.sepUser.isDE() ? ' AND EBH_DealSiteId__c = \'77\' ': '');

            // System.debug('query: '+query);
            List<EBH_Deal__c> lstTmp = new List<EBH_Deal__c>();
            for(EBH_Deal__c[] deals: Database.query(query)){
                lstTmp.addAll(deals);
            }
            mResult.put('lstExistedDeal', lstTmp);
            //=====MN-21122021-US-0011048

            mResult.put('status', 'success');
            mResult.put('lstDeal', lstDeal);
            mResult.put('message', 'The Deals were retrived successfully!');
        }
        catch(Exception ex) {
            mResult.put('message', ex.getMessage());
        }
        return mResult;  
    }


    public static Map<String, List<String>> getFieldDependencies(String objectName, String controllingField, String dependentField)
    {
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>();

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);

        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();

        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();

        for(Schema.PicklistEntry currControllingValue : controllingValues)
        {
            //System.debug('ControllingField: Label:' + currControllingValue.getLabel());
            //controllingInfo.put(currControllingValue.getLabel(), new List<String>());
            controllingInfo.put(currControllingValue.getValue(), new List<String>());
        }

        for(Schema.PicklistEntry currDependentValue : dependentValues)
        {
            String jsonString = JSON.serialize(currDependentValue);

            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);

            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();

            //System.debug('DependentField: Label:' + currDependentValue.getLabel() + ' ValidForInHex:' + hexString + ' JsonString:' + jsonString);

            Integer baseCount = 0;

            for(Integer curr : hexString.getChars())
            {
                Integer val = 0;

                if(curr >= 65)
                {
                    val = curr - 65 + 10;
                }
                else
                {
                    val = curr - 48;
                }

                if((val & 8) == 8)
                {
                    //System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 0].getLabel());
                    //controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue.getLabel());
                    controllingInfo.get(controllingValues[baseCount + 0].getValue()).add(currDependentValue.getValue());
                }
                if((val & 4) == 4)
                {
                    //System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 1].getLabel());
                    controllingInfo.get(controllingValues[baseCount + 1].getValue()).add(currDependentValue.getValue());                    
                }
                if((val & 2) == 2)
                {
                    //System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 2].getLabel());
                    controllingInfo.get(controllingValues[baseCount + 2].getValue()).add(currDependentValue.getValue());                    
                }
                if((val & 1) == 1)
                {
                    //System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 3].getLabel());
                    controllingInfo.get(controllingValues[baseCount + 3].getValue()).add(currDependentValue.getValue());                    
                }

                baseCount += 4;
            }       
        } 

        //System.debug('ControllingInfo: ' + controllingInfo);

        return controllingInfo;
    }

    /*****************************************************************************************************************************
    @ Method:         getTodayDealSetting
    @ Version:        1.0
    @ Author:          
    @ Purpose:        US-0010733 - [SP - EU Deals] [Bug] Single Deal Form should not allow 
                                    submit when seller has reached daily or DRC limit
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dealReatilCampaingId
    ------------------------------------------------------------------------------------------------------------------------------
    @               : 29-11-2021 /Loumang SENG/ Created the  Method.
    @               : 20-12-2021 /Mony Nou/ US-0010730 - [SP - EU Deals] [Bug] Deleted Deals not removed from recycle bin affecting daily limit count
    @               : 25-02-2022 /Mony Nou/ US-0011332 - Daily Limit counter issue - Rejected deals are also counting in the daily limit
    @               : 24-10-2022 /Bora Chhorn/ US-0012600 - Enable Link Multiple Accounts for NA/ AU Portal Sellers
    @               : 26-04-2023 /SRONG TIN/ US-0013352 - IT - Deals Bulk Upload Localization and translation
    @               : 05-12-2023 /SRONG TIN/ US-0014342 - Regression test issue on DE / NA Feature process
    *****************************************************************************************************************************/
    
    public static String eligibleAccountId; //MN-26042021-US-0010950

    public static Map<String,Object> getTodayDealSetting(String dealReatilCampaingId){
        Map<String, Object> mResult = new Map<String, Object>();
        mResult.put('status', 'error');
        try{
            Decimal maxDealWindow = 100; 
            String userId = UserInfo.getUserID();
            String accountId = '';
            String contactId = '';
            String fullContactName = '';
            String conEmail = '';
            String currUserLang = '';
            String parentAccId = '';
            List<EBH_DealRetailCampaign__c> listDrc = new List<EBH_DealRetailCampaign__c> ();
            for(User u : [SELECT Id, Profile.Name, ContactId, Contact.LastName, Contact.FirstName, Contact.Email, Contact.AccountId, Contact.Account.Parent_Account_ID__c, Contact.Account.Deal_Window_Limit__c, Contact.Account.EBH_RegistrationSite__c From User WHERE Id =: UserInfo.getUserID()]) {
                //userId = u.Id;
                //if(u.ContactId != null) {
                    conEmail = u.Contact.Email;
                    contactId = u.ContactId;
                    fullContactName = u.Contact.FirstName+ ' ' + u.Contact.LastName ;
                //}
                //if(u.ContactId != null && u.Contact.AccountId != null ) {
                    maxDealWindow = u.Contact.Account.Deal_Window_Limit__c;
                    accountId = u.Contact.AccountId;
                    parentAccId = u.Contact.Account.Parent_Account_ID__c;
                //}
                //if(u.ProfileId != null) {
                    currUserLang = u.Profile.Name;
                //}
            }
            //BR-25-10-22-US-0012600
            if(String.isNotBlank(eligibleAccountId)){
                for(Account acc : [SELECT Id, Deal_Window_Limit__c FROM Account WHERE Id =: eligibleAccountId]) {
                    maxDealWindow = acc.Deal_Window_Limit__c;
                }
            }
            //END BR-25-10-22-US-0012600
            //MN-20122021-US-0010730 - Add IsDeleted = FALSE into Query so we won't count the deleted records ( that existed in Recycle Bin) in the Deal Limitation
            
            /* //MN-21122021-US-0011048 - When page is onload, user not yet select any DRC yet so there is no use to query it with NULL DRC's ID => query EVERYTHING
            Integer totalDealPerCampaign = [SELECT COUNT() FROM EBH_Deal__c WHERE EBH_DealRetailCampaign__c =: dealReatilCampaingId AND EBH_BusinessName__c =: accountId AND EBH_Status__c !=: STATUS_REJECTED AND IsDeleted = FALSE];
            mResult.put('totalDealPerCampaign', totalDealPerCampaign);
            mResult.put('availableDeal', maxDealWindow - totalDealPerCampaign);
            */
            
            
            // 26-04-2023 /SRONG TIN/ US-0013352
            //if(currUserLang == DE_pfName && portalDomain.get('isIT') != true) { //MN-04062024-US-0015298
            if(SEP_Helper.sepUser.isEU() && !SEP_Helper.sepUser.isIT()) { //MN-04062024-US-0015298: Check current user's SP Main Domain instead of Profile Name
              
                //MN-25022022-US-0011332 - Status(es) that we won't count in the Deal Limitation 
                //MN-22032023-US-0012628 - Including status "Seller Cancelled"
                Set<String> sOptOutStatus = new Set<String>{ STATUS_REJECTED, STATUS_SELLERCANCELLED};

                //MN-20122021-US-0010730 - Add IsDeleted = FALSE into Query so we won't count the deleted records ( that existed in Recycle Bin) in the Deal Limitation
                //MN-25022022-US-0011332 - Add EBH_Status__c NOT IN:sOptOutStatus into Query so we won't count it in the Deal Limitation
                //MN-26042021-US-0010950 //mResult.put('totalDealOfDEToday', [SELECT COUNT() FROM EBH_Deal__c WHERE CreatedDate = TODAY AND EBH_BusinessName__r.Parent_Account_ID__c =: parentAccId AND EBH_Status__c NOT IN:sOptOutStatus AND  IsDeleted = FALSE]);
                
                //MN-26042021-US-0010950
                //Integer totalDealOfDEToday = (String.isBlank(eligibleAccountId)?0:[SELECT COUNT() FROM EBH_Deal__c WHERE CreatedDate = TODAY AND EBH_BusinessName__r.Parent_Account_ID__c =: eligibleAccountId AND EBH_Status__c NOT IN:sOptOutStatus AND  IsDeleted = FALSE]);
                //SRONG TIN - 05/12/2023 : US-0014342
                Integer totalDealOfDEToday = (String.isBlank(eligibleAccountId)?0:[SELECT COUNT() FROM EBH_Deal__c WHERE CreatedDate = TODAY AND EBH_BusinessName__c =: eligibleAccountId AND EBH_Status__c NOT IN:sOptOutStatus AND  IsDeleted = FALSE]);
                mResult.put('totalDealOfDEToday', totalDealOfDEToday);

                mResult.put('fieldDependencies', ClsBulkUploadCSV.getFieldDependencies('EBH_Deal__c','EBH_DealSiteId__c','EBH_Category__c'));
            }else 
            {
                //MN-22032023-US-0012628 - Including status "Seller Cancelled"
                Set<String> sOptOutStatus = new Set<String>{ STATUS_REJECTED, STATUS_SELLERCANCELLED};
               
                //Integer totalDealPerCampaign = [SELECT COUNT() FROM EBH_Deal__c WHERE EBH_DealRetailCampaign__c =: dealReatilCampaingId AND EBH_BusinessName__c =: eligibleAccountId AND EBH_Status__c !=: STATUS_REJECTED AND IsDeleted = FALSE]; // BR-24-10-22-US-0012600
                Integer totalDealPerCampaign = [SELECT COUNT() FROM EBH_Deal__c WHERE EBH_DealRetailCampaign__c =: dealReatilCampaingId AND EBH_BusinessName__c =: eligibleAccountId AND EBH_Status__c NOT IN:sOptOutStatus AND IsDeleted = FALSE]; //MN-22032023-US-0012628
                mResult.put('totalDealPerCampaign', totalDealPerCampaign);
                mResult.put('availableDeal', maxDealWindow - totalDealPerCampaign);
                System.debug('sro:: totalDealPerCampaign:'+totalDealPerCampaign);
            }
            
            mResult.put('userId', userId);
            mResult.put('accountId', accountId);
            mResult.put('contactId', contactId);
            mResult.put('fullContactName', fullContactName);
            mResult.put('conEmail', conEmail);
            mResult.put('currUserLang', currUserLang);
            mResult.put('status', 'success');
            mResult.put('isEU', SEP_Helper.sepUser.isEU()); //MN-05062024-US-0015298
            //Loumang:03-02-2022:US-0011290: add condition to prevent null Id in query
            if(String.isNotBlank(dealReatilCampaingId)){
                listDrc = [Select Id,EBH_OpenSeatsAvailable__c from EBH_DealRetailCampaign__c where Id=:dealReatilCampaingId limit 1];
                //Loumang:03-02-2022:US-0011290: Uncomment code because we have prevent at condition if(String.isNotBlank(dealReatilCampaingId))
                mResult.put('drc', !listDrc.isEmpty() ? listDrc[0] : null); //MN-21122021-US-0011048 -  When page is onload, user not yet select any DRC yet so there is no use to query it with NULL DRC's ID => query EVERYTHING
            } 

        } catch(Exception ex) {mResult.put('message', ex.getMessage());}
        
        return mResult;  
    }


    /*****************************************************************************************************************************
    @ Method:         doLoadCouponUploadItems
    @ Author:         Acmatac SEING
    @ Purpose:        US-0010660 - Items upload validations
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String couponSellerId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 23-05-2022 / Acmatac SEING / Created the  Method.
    @               : 30-08-2022/ vadhanak voun/ US-0012297 - BETA Feedback
    @               : 22.11.2022 / Sambath Seng / US-0012026 - [FR] Localization for Item Upload template file
    @               : 23.11.2022 / Sambath Seng / US-0012030 - [IT] Localization for Item Upload template file
    @               : 09.06.2023 / Sophal Noch / US-0013666 - Ability to restrict number of items per seller to be uploaded against item based coupon
    @               : 14.11.2023 / Mony Nou  / US-0014404 - Item limit on coupon seller is not working
    *****************************************************************************************************************************/    
    @AuraEnabled
    public static Map<String, Object> doLoadCouponUploadItems(String couponSellerId){
        Map<String, Object> mResult = new Map<String, Object>();
        try{
            //BR-US-0013232
            Boolean isMainSiteUK = false;
            // 09.06.2023 / Sophal Noch / US-0013666 : add Item_Limit__c and Coupon__r.RecordTypeId field to Coupon_Seller__c
            //MN-14112023-US-0014404: Add Coupon_Type__c into below query
            Coupon_Seller__c couponSeller = [SELECT Id, Main_Coupon_Site__c, Item_Limit__c, Coupon_Type__c, Coupon__r.RecordTypeId FROM Coupon_Seller__c WHERE Id =: couponSellerId LIMIT 1];
            if(String.isNotBlank(couponSeller.Main_Coupon_Site__c) && couponSeller.Main_Coupon_Site__c != null && couponSeller.Main_Coupon_Site__c == 'ebay.co.uk'){
                isMainSiteUK = true;
            }
            //END BR-US-0013232
            String currUserProfileName = '';
            String currUserLang = UserInfo.getLanguage();//SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
            for(User u : [SELECT Id, Profile.Name From User WHERE Id =: UserInfo.getUserID()]) {
                currUserProfileName = u.Profile.Name;
            }

            Set<String> couponCoInvestItemIds = new Set<String>();
            for(Coupon_Co_Invest__c oCCI : [SELECT Item_ID__c FROM Coupon_Co_Invest__c WHERE Coupon_Seller__c =: couponSellerId]){
                couponCoInvestItemIds.add(oCCI.Item_ID__c);
            }

            mResult.put('currUserProfileName', currUserProfileName);
            mResult.put('couponCoInvestCount', couponCoInvestItemIds.size());
            mResult.put('couponCoInvestItemIds', couponCoInvestItemIds);
            
            /*MN-14112023-US-0014404: 
                Since we changed to use "With Sharing" from US-0012769 => SEP User don't have access to Coupon__c record thus criteria "couponSeller.Coupon__r.RecordTypeId == ITEM_BASED_COUPON_RTID" will not work
                So we need to use Coupon_Seller__c.Coupon_Type__c instead   
            */
            //mResult.put('maxCoinvestPerCoupon', couponSeller.Item_Limit__c != null && couponSeller.Coupon__r.RecordTypeId == ITEM_BASED_COUPON_RTID ? Integer.valueOf(couponSeller.Item_Limit__c) : null); // 09.06.2023 / Sophal Noch / US-0013666
            mResult.put('maxCoinvestPerCoupon', couponSeller.Item_Limit__c != null && couponSeller.Coupon_Type__c == SEPCouponController.COUPON_ITEMBASE ? Integer.valueOf(couponSeller.Item_Limit__c) : null); // 09.06.2023 / Sophal Noch / US-0013666
            
            /* MN-04062024-US-0015298
            mResult.put('isDE', currUserProfileName==DE_pfName && currUserLang==PORTAL_DE_LANG);//SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
            mResult.put('isNA', currUserProfileName==PF_PORTAL_NA);
            mResult.put('isAU', currUserProfileName==PORTAL_AU);
            mResult.put('isFR', currUserProfileName==DE_pfName && currUserLang==PORTAL_FR_LANG);//SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
            mResult.put('isIT', currUserProfileName==DE_pfName && currUserLang==PORTAL_IT_LANG);//SB 23.11.2022 US-0012030 - [IT] Localization for Item Upload template file
            mResult.put('isUK', currUserProfileName==DE_pfName && (currUserLang==PORTAL_EN_LANG || currUserLang == PORTAL_UK_LANG));//SRONG:16/05/2024:US-0015312 //NK:24/11/2022:US-0012035
            */

            //START--MN-04062024-US-0015298: Check current user's SP Main Domain instead of Profile Name
            mResult.put('isDE', SEP_Helper.sepUser.isDE());//SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
            mResult.put('isNA', SEP_HELPER.sepUser.isNA());
            mResult.put('isAU', SEP_Helper.sepUser.isAU());
            mResult.put('isFR', SEP_Helper.sepUser.isFR());//SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
            mResult.put('isIT', SEP_Helper.sepUser.isIT());//SB 23.11.2022 US-0012030 - [IT] Localization for Item Upload template file
            mResult.put('isUK', SEP_Helper.sepUser.isUK());//SRONG:16/05/2024:US-0015312 //NK:24/11/2022:US-0012035
            //--END

            mResult.put('isMainSiteUK', isMainSiteUK);
            mResult.put('status', 'success');
        }
        catch(Exception ex) {
            mResult.put('status', 'error');
            mResult.put('message', ex.getMessage());
        }
        return mResult;
        
    }

    /*****************************************************************************************************************************
    @ Method:         doLoadDCAUploadDeal
    @ Author:         Sovantheany Dim
    @ Purpose:        US-0012281 - Validation and upload of Deals
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dcaID
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07-09-2022 / Sovantheany Dim / Created the  Method.
                      28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations 
    *****************************************************************************************************************************/    
    @AuraEnabled
    public static Map<String, Object> doLoadDCAUploadDeal(String dcaID){
        Map<String, Object> mResult = new Map<String, Object>();
        try{
            /*String currUserProfileName = '';
            for(User u : [SELECT Id, Profile.Name From User WHERE Id =: UserInfo.getUserID()]) {
                currUserProfileName = u.Profile.Name;
            }*/

            Set<String> dealItemIds = new Set<String>();
            for(EBH_Deal__c deal : [select id,EBH_eBayItemID__c from EBH_Deal__c where Deal_Contract_Agreement__c =: dcaID]){
                dealItemIds.add(deal.EBH_eBayItemID__c);
            }

            //mResult.put('currUserProfileName', currUserProfileName);
            //mResult.put('dealCount', dealItemIds.size());
            mResult.put('dealCount', dealItemIds.size()); // 28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations 
            mResult.put('dealItemIds', dealItemIds);

            /*mResult.put('isDE', currUserProfileName==DE_pfName);
            mResult.put('isNA', currUserProfileName==PF_PORTAL_NA);
            mResult.put('isAU', currUserProfileName==PORTAL_AU);*/

            mResult.put('status', 'success');
        }
        catch(Exception ex) {
            mResult.put('status', 'error');
            mResult.put('message', ex.getMessage());
        }
        return mResult;
        
    }
    //08.12.2022 / SRONG TIN / US-0012861 - Move content of MyPickListInfo to ClsBulkUploadCSV
    public class MyPickListInfo {

        public String validFor;
    
    }
}