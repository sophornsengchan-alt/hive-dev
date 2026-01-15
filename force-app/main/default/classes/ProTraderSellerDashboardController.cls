/**
 * @Clas Name          : ProTraderSellerDashboardController
 * @Description        : This class is used for ProTrader Seller Dashboard in seller portal
 * @ Change history:   : 12.01.2024 / Bora Chhorn / US-0014603 - Design Update - Pro-Trader Seller Dashboard
 *                     : 03.04.2024 / Bora Chhorn / US-0015015 - 7 PT for US - Display the Dashboard to the NA PT Seller when they Click on Your Dashboard button
 *                     : 09.04.2024 / Bora Chhorn / US-0015016 - 5 PT for US- TC - Call Booking functionality - SP and Book a call in Hive
 *                     :21.10.2024/ vadhanak voun / US-0015188 - Tech debt- Remove Currency_ISO_Code__c custom field in cohort seller object
 *                     : 24.10.2024 / sovantheany dim/ US-0015390 - ADS - Create an Advertising program component for Bookings
 *                     : 14.02.2025/ vadhanak voun/ US-0016605 - Calendly reporting wrong day of week
 *                     : 21.08.2025 / Bora Chhorn / US-0033295 - GSD: (TDD) Meetings booked from seller account not showing on Seller Portal
 */
public with sharing class ProTraderSellerDashboardController {
    /**
     * @Method Name        : getCohortSellerandCategoryPerformanceData
     * @Description        : This method is used to get the data for ProTrader Seller Dashboard
     */
    @AuraEnabled
    public static ProTraderSellerDashboardWrapperClass getCohortSellerandCategoryPerformanceData(string cohortSellerId) {

        BoB_Seller__c bobSeller = new BoB_Seller__c();
        List<Bob_Seller_Category__c> bobSellerTopCategoryList = new List<Bob_Seller_Category__c>();
        List<Action__c> cohortActionList = new List<Action__c>();
        list<SubCategoryClass> subCategoryClassList = new list<SubCategoryClass>();
        list<CohortTaskClass> cohortTaskClassList = new list<CohortTaskClass>();
        list<User> accountManagerUserDetails = new list<User>();
        
        try{
            
            list<BoB_Seller__c> bobSellerList = (list<BoB_Seller__c>) DataCreator.getRecordbyId(BoB_Seller__c.sObjectType, cohortSellerId /*loggedInUserDetails[0].contact.AccountId*/);
            bobSeller = bobSellerList[0];
            accountManagerUserDetails = (list<User>) DataCreator.getRecordbyId(User.sObjectType, bobSeller.Account_Manager__c);
            bobSellerTopCategoryList = (List<Bob_Seller_Category__c>) DataCreator.getRecordsByIds(Bob_Seller_Category__c.sObjectType, new set<id>{bobSeller.id});
            cohortActionList = (List<Action__c>) DataCreator.getRecordsByIds(Action__c.sObjectType, new set<id>{bobSeller.id});
        
        }catch(exception e){
            EBH_ApexLogger.logError(new List<Exception> { e }, 'ProTraderSellerDashboardController','getCohortSellerandCategoryPerformanceData');
        }
        
        ProTraderSellerDashboardWrapperClass proTraderSellerDashboard = new ProTraderSellerDashboardWrapperClass();

        proTraderSellerDashboard.shareofSales = bobSeller.Share_of_Sales__c;
        proTraderSellerDashboard.totalSalesCohort = bobSeller.Total_Sales_Cohort__c;
        proTraderSellerDashboard.cohortRanking = (Integer)bobSeller.Ranking__c;
        proTraderSellerDashboard.shareofSalesPreviousMonth = bobSeller.Share_of_Sales_Previous_Month__c;
        proTraderSellerDashboard.shareofSalesPreviousYear = bobSeller.Share_of_Sales_Previous_Year__c;
        proTraderSellerDashboard.totalSalesPreviousMonth = bobSeller.Total_Sales_Cohort_Previous_Month__c;
        proTraderSellerDashboard.totalSalesPreviousYear = bobSeller.Total_Sales_Cohort_Previous_Year__c;
        proTraderSellerDashboard.rankingPreviousMonth = (Integer)bobSeller.Ranking_Previous_Month__c;
        proTraderSellerDashboard.rankingPreviousYear = (Integer)bobSeller.Ranking_Previous_Year__c;
        proTraderSellerDashboard.conversionRate = bobSeller.Conversion_Rate_USD_Local__c;
        proTraderSellerDashboard.cohortName = bobSeller.Bob_Cohort_Name__c;
        proTraderSellerDashboard.cohortSellerParentSellerName = bobSeller.Seller_Name__c;
        proTraderSellerDashboard.accountManagerName = accountManagerUserDetails.size() > 0 ? accountManagerUserDetails[0]?.FirstName + ' ' + accountManagerUserDetails[0]?.LastName : '';
        proTraderSellerDashboard.accountManagerEmail = accountManagerUserDetails.size() > 0 ? accountManagerUserDetails[0]?.Customer_facing_eMail__c : '';
        proTraderSellerDashboard.accountManagerProfileUrl = accountManagerUserDetails.size() > 0 ? accountManagerUserDetails[0]?.MediumPhotoUrl : '';
        proTraderSellerDashboard.accountManagerCalendlyLink = accountManagerUserDetails.size() > 0 ? accountManagerUserDetails[0]?.Calendly__CalendlyLink__c : '';
        
        //NK:21/10/2024:US-0015188
        //proTraderSellerDashboard.cohortSellerCurrency = bobSeller.Currency_ISO_Code__c; // 03.04.2024 / Bora Chhorn / US-0015015
        proTraderSellerDashboard.cohortSellerCurrency = bobSeller.CurrencyIsoCode;

        for(Bob_Seller_Category__c eachCategory : bobSellerTopCategoryList){
            SubCategoryClass subCategoryObj = new SubCategoryClass();
            subCategoryObj.subCategoryName = eachCategory.Category_Name__c; //eachCategory.Category_Tree__r.name;
            subCategoryObj.categoryShareSales = eachCategory.Categ_Share_Sales__c == null ? 0 : eachCategory.Categ_Share_Sales__c;
            subCategoryObj.categoryShareSalesPreviousMonth = eachCategory.Categ_Share_Sales_Prev_MOM__c == null ? 0 : eachCategory.Categ_Share_Sales_Prev_MOM__c;
            subCategoryObj.categoryTotalSales = eachCategory.Categ_Total_Sales__c == null ? 0 : eachCategory.Categ_Total_Sales__c;
            subCategoryObj.categoryTotalSalesPreviousMonth = eachCategory.Categ_Total_sales_Prev_MOM__c == null ? 0 : eachCategory.Categ_Total_sales_Prev_MOM__c;
            subCategoryObj.categoryRanking = (Integer)eachCategory.Categ_Ranking__c == null ? 0 : (Integer)eachCategory.Categ_Ranking__c;
            subCategoryObj.categoryRankingPreviousMonth = (Integer)eachCategory.Categ_Ranking_Prev_Month__c == null ? 0 : (Integer)eachCategory.Categ_Ranking_Prev_Month__c;
            subCategoryObj.fastAndFreeCount = eachCategory.Fast_Free_Ship__c;
            subCategoryObj.clickAndCollectCount = eachCategory.Click_Collect__c;
            subCategoryObj.returnOfThirtyDaysCount = eachCategory.Returns_30days_Or_Longer__c;
            subCategoryObj.nextDayDeliveryCount= eachCategory.Nextday_Delivery__c;
            subCategoryObj.multiBuyCount = eachCategory.MultiBuy__c;
            subCategoryObj.orderDiscountCount = eachCategory.Order_Discount__c;
            subCategoryObj.salesEvent = eachCategory.Sale_Event__c;
            subCategoryObj.itemsSepcificYourListingCount = eachCategory.Slr_Item_Specifics_Per_LL__c;
            subCategoryObj.itemSpecificEbayAverageCount = eachCategory.Item_Specifics_Per_LL__c;
            subCategoryObj.photosYourListingCount = eachCategory.Slr_Photos_Per_LL__c;
            subCategoryObj.photosEbaysAverageCount = eachCategory.Photos_Per_LL__c;
            subCategoryObj.titleLengthYourListingCount = eachCategory.Slr_Title_length_Character_Cnt__c;
            subCategoryObj.titleLengthEbaysAverageCount = eachCategory.Title_Length_Character_Cnt__c;
            subCategoryObj.sponsoredListingYourCategoryCoverageCount = eachCategory.Slr_Sponsored_LL_Number_of_LL__c;
            subCategoryObj.sponsoredListingEbayCategoryCoverageCount = eachCategory.Sponsored_LL_Number_of_LL__c;

            subCategoryClassList.add(subCategoryObj);
        }
        proTraderSellerDashboard.subCategoryList = subCategoryClassList;

        for(Action__c eachAction : cohortActionList){
            CohortTaskClass cohortTaskObj = new CohortTaskClass();
            cohortTaskObj.description = eachAction.Description__c;
            cohortTaskObj.comments= eachAction.Comments__c;
            cohortTaskObj.sellerFacingMessage = eachAction.Seller_facing_Dashboard_message__c;
            cohortTaskObj.actionTemplateId = eachAction.Action_Template__c;
            cohortTaskObj.status = eachAction.Status__c;
            cohortTaskObj.helptext = eachAction.Action_Template__r.ActionTemplate_Help_Text__c;
            cohortTaskObj.documentLink = eachAction.Action_Document_Link__c;
            // 12.01.2024 / Bora Chhorn / US-0014603
            if(eachAction.Due_Date__c != null){
                cohortTaskObj.dueDate = eachAction.Due_Date__c.format();
            } else {
                cohortTaskObj.dueDate = '';
            }
            cohortTaskClassList.add(cohortTaskObj);
        }

        proTraderSellerDashboard.cohortTaskList = cohortTaskClassList;

        //system.debug('proTraderSellerDashboard---'+proTraderSellerDashboard);
       
        return proTraderSellerDashboard;
    }

    /**
     * @Method Name        : getObjectsHelpTexts
     * @Description        : This method is used to get the help text for the fields in the object
     * @param objectName   : Object Name
     */
    @AuraEnabled(cacheable=true) 
    public static Map<String, String> getObjectsHelpTexts(String objectName) {
        Map<String, String> helpTexts = new Map<String, String>();
        SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType != null) {
            for (SObjectField field : objectType.getDescribe().fields.getMap().values()) {
                DescribeFieldResult des = field.getDescribe();
                helpTexts.put(des.getName(), des.getInlineHelpText());
            }
        }
        return helpTexts;
    }

    /**
     * @Method Name        : isCommunity
     * @Description        : This method is used to determine if its community or internal page
     */
    private static boolean isCommunity(){
        Id siteId = Site.getSiteId(); 
        if (siteId != null) {
            return true;        
        }    
        return false;
    }

    /**
     * @Method Name        : getCommunityBasePath
     * @Description        : This method is used to get the community base path
     */
    @AuraEnabled(cacheable=true)
    public static string getCommunityBasePath(){
        if(isCommunity()){
            string communityBasepath = Network.getLoginUrl(Network.getNetworkId());
            system.debug('==communityBasepath='+communityBasepath);
            return communityBasepath.substring(0,communityBasepath.indexOf('login'));
        }
        return '';
    }

    /**
     * @Method Name: getEvents
     * Desc: This method is used to get the events for the logged in user
     * US-0015390 : TH: add (cacheable=true) to the method 
     * : 14.02.2025/ vadhanak voun/ US-0016605 - Calendly reporting wrong day of week
     * : 21.08.2025 / Bora Chhorn / US-0033295 - GSD: (TDD) Meetings booked from seller account not showing on Seller Portal
     */
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getEvents(string cohortSellerId) {

        Map<String,Object> mapResult = new Map<String,Object>();
        // 21.08.2025 / Bora Chhorn / US-0033295
        String sellerId = '';
        if(String.isNotBlank(cohortSellerId)) {
            List<BoB_Seller__c> bobSellerList = ApexSafe.query().doQuery('SELECT Id, Seller__c FROM BoB_Seller__c WHERE Id = :cohortSellerId LIMIT 1', new Map<String, Object>{'cohortSellerId' => cohortSellerId});
            if(!bobSellerList.isEmpty() && String.isNotBlank(bobSellerList[0].Seller__c)) {
                sellerId = bobSellerList[0].Seller__c;
            }
        }

        string userId = UserInfo.getUserId(); //'0057A000006Oa34QAC';
        String userSoql = 'Select ContactId,Contact.AccountId From User';
        string userSoqlWhere = ' Where Id='+ApexUtil.closeSQoute(userId); 
        List<User> lstUsers = WithoutSharing.doQuery(userSoql,userSoqlWhere, ''); // disable security check. must set access level to system mode to get existing ccontact details for current user
        //List<User> lstUsers = (List<User>) ApexSafe.query().doQuery(userSoql,new Map<String, Object> {'userId' => userId});//UserInfo.getUserId()
        List<Event> events = new List<Event>();
        string eventSoql = 'SELECT Id, WhatId, Subject, StartDateTime, isCancelled__c, calendly_event_uuid__c,Calendly__InviteeUuid__c,';
        eventSoql += 'owner.Name,ownerid, owner.id,owner.firstname, owner.lastname, Request_Description__c  FROM Event ';
        eventSoql += 'WHERE calendly_event_uuid__c != null ';//AND whoId ='+ApexUtil.closeSQoute(lstUsers[0]?.contactId);
        // 09.04.2024 / Bora Chhorn / US-0015016
        // if(isCommunity()){
        //     eventSoql +=' AND whoId ='+ApexUtil.closeSQoute(lstUsers[0]?.contactId);
        // }
        // END

        // 21.08.2025 / Bora Chhorn / US-0033295
        Set<String> setWhatId = new Set<String>{cohortSellerId};
        if(String.isNotBlank(sellerId) && AccountManagementController.checkEligibilityFor_Booking_Advertising(sellerId)){
            setWhatId.add(sellerId);
        }
        // eventSoql += ' AND WhatId =' +ApexUtil.closeSQoute(cohortSellerId) +' AND startDateTime > TODAY ORDER BY startDateTime '; 
        eventSoql += ' AND WhatId IN (' + ApexUtil.constructQuoteString(setWhatId)+') AND startDateTime > TODAY ORDER BY startDateTime '; 
        
        //NK:14/02/2025:US-0016605   
        String dmFormat = ApexUtil.MAP_LOCALE_DATEFORMAT().get(UserInfo.getLocale());
        dmFormat = dmFormat==null?'EEE dd/MM/yyyy':'EEE '+dmFormat;
        dmFormat += ' (z)';
        try{
            for (Event e : (Event[]) WithoutSharing.doQuery(eventSoql,'', '')) { // disable security check. must set access level to system mode to get existing ccontact details for current user
                mapResult.put('formatedStartDateTime'+e.Id,e.StartDateTime.format());                
                mapResult.put('formatedStartDateTime2'+e.Id,e.StartDateTime.format(dmFormat));  //NK:14/02/2025:US-0016605
                events.add(e);
              }
              mapResult.put('events',events);
        }catch(exception e){
            EBH_ApexLogger.logError(new List<Exception> { e }, 'ProTraderSellerDashboardController','getEvents');
        }

        return mapResult;
    }

    public class ProTraderSellerDashboardWrapperClass{
        @AuraEnabled
        public decimal shareofSales;
        @AuraEnabled
        public decimal totalSalesCohort;
        @AuraEnabled
        public integer cohortRanking;
        @AuraEnabled
        public decimal shareofSalesPreviousMonth;
        @AuraEnabled
        public decimal shareofSalesPreviousYear;
        @AuraEnabled
        public decimal totalSalesPreviousMonth;
        @AuraEnabled
        public decimal totalSalesPreviousYear;
        @AuraEnabled
        public integer rankingPreviousMonth;
        @AuraEnabled
        public integer rankingPreviousYear;
        @AuraEnabled
        public decimal conversionRate;
        @AuraEnabled
        public string cohortName;
        @AuraEnabled
        public string accountManagerName;
        @AuraEnabled
        public string accountManagerEmail;
        @AuraEnabled
        public string accountManagerProfileUrl;
        @AuraEnabled
        public string accountManagerCalendlyLink;
        @AuraEnabled
        public string cohortSellerParentSellerName;
        @AuraEnabled
        public string cohortSellerCurrency; // 03.04.2024 / Bora Chhorn / US-0015015
        

        @AuraEnabled
        public list<SubCategoryClass> subCategoryList;

        @AuraEnabled
        public list<CohortTaskClass> cohortTaskList;

        
    }
    public class SubCategoryClass{
        @AuraEnabled
        public string subCategoryName;
        @AuraEnabled
        public decimal categoryShareSales;
        @AuraEnabled
        public decimal categoryShareSalesPreviousMonth;
        @AuraEnabled
        public decimal categoryTotalSales;
        @AuraEnabled
        public decimal categoryTotalSalesPreviousMonth;
        @AuraEnabled
        public integer categoryRanking;
        @AuraEnabled
        public integer categoryRankingPreviousMonth;

        @AuraEnabled
        public decimal fastAndFreeCount;
        @AuraEnabled
        public decimal clickAndCollectCount;
        @AuraEnabled
        public decimal returnOfThirtyDaysCount;
        @AuraEnabled
        public decimal nextDayDeliveryCount;
        @AuraEnabled
        public decimal multiBuyCount;
        @AuraEnabled
        public decimal orderDiscountCount;
        @AuraEnabled
        public string salesEvent; //make it string to do
        @AuraEnabled
        public decimal itemsSepcificYourListingCount;
        @AuraEnabled
        public decimal itemSpecificEbayAverageCount;
        @AuraEnabled
        public decimal photosYourListingCount;
        @AuraEnabled
        public decimal photosEbaysAverageCount;
        @AuraEnabled
        public decimal titleLengthYourListingCount;
        @AuraEnabled
        public decimal titleLengthEbaysAverageCount;
        @AuraEnabled
        public decimal sponsoredListingYourCategoryCoverageCount;
        @AuraEnabled
        public decimal sponsoredListingEbayCategoryCoverageCount;
    }
    public class CohortTaskClass{
        @AuraEnabled
        public string description;
        @AuraEnabled
        public string sellerFacingMessage;
        @AuraEnabled
        public string status;
        @AuraEnabled
        public string comments;
        @AuraEnabled
        public string actionTemplateId;
        @AuraEnabled
        public string helptext;
        @AuraEnabled
        public string documentLink;
        @AuraEnabled
        public string dueDate; // 12.01.2024 / Bora Chhorn / US-0014603
        
    }

    
}