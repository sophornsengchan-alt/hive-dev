/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Get, Upsert and Delete relevent sObject declared in the Lightning and Community Builder
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Randy Grewal   <rgrewal@salesfore.com>
* @modifiedBy     Randy Grewal   <rgrewal@salesfore.com>
* @maintainedBy   Randy Grewal   <rgrewal@salesfore.com>
* @version        1.1
* @created        2017-05-01
* @modified       2017-06-12
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.1            rgrewal@salesfore.com
* 2017-06-08     	Added option to filter query by logged in user and removed System.debug logs
* 2017-06-12		Security Review Fixes:
*					Added isAccessible(), isCreateable(), isDeletable() for CRUD/FLS Enforcement fix
*					Added Typecasting to all injected field API names for SOQL Injection fix
*					Added "with sharing" keyword to Class for Sharing Violation Fix
* 29.08.2022        Sophal Noch / US-0012311 - Seller filter on calendar displaying for deal only sellers
* 02.09.2022        Mony Nou / US-0012342 - Coupon records showing in to-do when permission set not assigned
* 05.12.2022        vadhanak voun / US-0012917 - [UK] Homepage
* 10.01.2023        Mony Nou / US-0012915 - [FR] Homepage
* 04.04.2023        Bora Chhorn / US-0012916 - [IT] Homepage
* 02.05.2023        SRONG TIN / US-0013353 - IT Deals SP Home Page
* 06.06.2024        Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c 
* 13.11.2024        vadhanak voun/ US-0016188 - [Seller Portal License Change] - Components not visible correctly with new profile
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

public with sharing class AnyEventCalCtrl {
    /**
     * @description EBAY-482
     * @date        08/09/2021
     * @modifiedBy  Samnang MUONG
     */

    private static final String ELIGIBLE_FOR_DE_CALENDAR = 'Eligible_for_DE_Calendar';

    @AuraEnabled
    public static String initLocalCode(){

            // Map<String, String> mapProfileLocalCode = new Map<String, String>{'DE - Seller Portal'=>'de'};

            // String currentProfileId = UserInfo.getProfileId();
            // Profile p = [SELECT Id, Name FROM Profile WHERE Id = :currentProfileId];

        //   return mapProfileLocalCode.containsKey(p.Name) ? mapProfileLocalCode.get(p.Name) : 'en';
        //05/12/2022:US-0012917
        return [Select Id,LanguageLocaleKey From User Where Id=:UserInfo.getUserId()].LanguageLocaleKey;

    }
    /*********************************************************************************************************************************
    @ class:    getAccounts
    @ Version:  1.0
    @ Author:   SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:  US-0010814 - Status, Product & Seller filters on calendar on homepage
    @ Change history: 14.07.2022 / Mony Nou / US-0012057 - Homepage not respecting SP Eligibility
    @                                           - Added Seller_Portal_Group__r.SP_Deals__c & Seller_Portal_Group__r.SP_Coupons__c into query
    @                 29.08.2022 / Sophal Noch / US-0012311 - Seller filter on calendar displaying for deal only sellers
    *********************************************************************************************************************************/
    @AuraEnabled
    public static List<Account> getAccounts(){

        List<Account> lstAcc = new List<Account>();

        // Map<String,Object> data = AccountPickerController.getDEEligibleAccounts();
        // 29.08.2022 / Sophal Noch / US-0012311 :
        List<Seller_Portal_Setting__mdt> meta = [Select Id,DeveloperName,Filter_Values__c from Seller_Portal_Setting__mdt where DeveloperName =:ELIGIBLE_FOR_DE_CALENDAR];
        Map<String,Object> data = AccountPickerController.getDEEligibleAccountsByMetadata(meta);


        Set<Id> ids = new Set<Id>();
        for(Object arc: (List<Object>) data.get('accRelationAll')){
            AccountContactRelation oneAcr = (AccountContactRelation)arc;
            ids.add(oneAcr.AccountId);
        }
        //MN-14072022-US-0012057-Added Seller_Portal_Group__r.SP_Deals__c,Seller_Portal_Group__r.SP_Coupons__c into query
        lstAcc = [Select Id, Name, SP_Coupons__c, SP_Deals__c, Seller_Portal_Group__r.SP_Deals__c,Seller_Portal_Group__r.SP_Coupons__c  From Account Where Id in :ids];
    
        return lstAcc;
    }

    //TH:04/05/2022:US-0011536 :Server Action Processing time too high
    /*@AuraEnabled
    public static List<EventObj> getEvents(String sObjectName, String titleField, String startDateTimeField, String endDateTimeField, String descriptionField, String userField, Boolean filterByUserField){
        String q = 'SELECT Id,' +
            String.valueOf(titleField) + ',' +
            String.valueOf(startDateTimeField) + ',' +
            String.valueOf(endDateTimeField) + ',' +
            String.valueOf(descriptionField) + ',' +
            String.valueOf(userField) + ' FROM ' +
            String.valueOf(sObjectName) + ' WHERE ' +
            String.valueOf(userField) + ' = \'' + UserInfo.getUserId() + '\'';
        if (!filterByUserField) {
            q = 'SELECT Id,' +
                String.valueOf(titleField) + ',' +
            String.valueOf(startDateTimeField) + ',' +
            String.valueOf(endDateTimeField) + ',' +
            String.valueOf(descriptionField) + ',' +
            String.valueOf(userField) + ' FROM ' +
            String.valueOf(sObjectName);
        }

        List<sObject> sObjectList = Database.query(q);

        List<EventObj> eventRecords = new List<EventObj>();
        if(isAccessible(sObjectName)) {
            for (sObject obj : sObjectList) {
                EventObj newEv = new EventObj(obj.Id,
                                              String.valueOf(obj.get(titleField)),
                                              DateTime.valueOf(obj.get(startDateTimeField)),
                                              DateTime.valueOf(obj.get(endDateTimeField)),
                                              String.valueOf(obj.get(descriptionField)),
                                              String.valueOf(obj.get(userField))
                                             );
                eventRecords.add(newEv);
            }
        }
        return eventRecords;
    }

    @AuraEnabled
    public static EventObj upsertEvents(String sEventObj, String sObjectName, String titleField, String startDateTimeField, String endDateTimeField, String descriptionField, String userField){
        EventObj upsertingEvent = (EventObj)JSON.deserialize(sEventObj, EventObj.class);
        sObject newRecord = Schema.getGlobalDescribe().get(sObjectName).newSObject();
        if (upsertingEvent.Id != null && isAccessible(sObjectName,'Id')){
            newRecord.put('Id',upsertingEvent.Id);
        }
        if (isAccessible(sObjectName,titleField)) {
            newRecord.put(titleField, upsertingEvent.title);
        }
        if (isAccessible(sObjectName,startDateTimeField)) {
            newRecord.put(startDateTimeField, upsertingEvent.startDateTime);
        }
        if (isAccessible(sObjectName,endDateTimeField)) {
            newRecord.put(endDateTimeField, upsertingEvent.endDateTime);
        }
        if (isAccessible(sObjectName,descriptionField)) {
            newRecord.put(descriptionField, upsertingEvent.description);
        }



        try {
            upsert newRecord;
            EventObj newEv = new EventObj(newRecord.Id,
                                  String.valueOf(newRecord.get(titleField)),
                                  DateTime.valueOf(newRecord.get(startDateTimeField)),
                                  DateTime.valueOf(newRecord.get(endDateTimeField)),
                                  String.valueOf(newRecord.get(descriptionField)),
                                  String.valueOf(newRecord.get(userField))
                                 );
            return newEv;
        } catch (Exception e) {
            System.debug(e.getMessage());
            return null;
        }

    }
    @AuraEnabled
    public static String deleteEvent(String eventId, String sObjectName, String titleField, String startDateTimeField, String endDateTimeField, String descriptionField, String userField){
        String q = 'SELECT Id,' +
                titleField + ',' +
                startDateTimeField + ',' +
                endDateTimeField + ',' +
                descriptionField + ',' +
                userField + ' FROM ' +
                sObjectName + ' WHERE Id = \'' + eventId  + '\'';
        List<sObject> sObjectList = Database.query(q);
        try {
            if(isDeletable(sObjectName)) {
                delete sObjectList;
            }
            return eventId;
        } catch (Exception e) {
            System.debug(e.getMessage());
            return null;
        }

    }
    public class EventObj {
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String title {get;set;}
        @AuraEnabled
        public DateTime startDateTime {get;set;}
        @AuraEnabled
        public DateTime endDateTime {get;set;}
        @AuraEnabled
        public String description {get;set;}
        @AuraEnabled
        public String owner {get;set;}


        public EventObj(String i,String t, DateTime s, DateTime e, String d, String o){
            this.Id = i;
            this.title = t;
            this.startDateTime = s;
            this.endDateTime = e;
            this.description = d;
            this.owner = o;
        }

    }
    public static Boolean isAccessible(String sObjectType, String fieldName){
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectType);
        Map<String, SObjectField> fields = schemaType.getDescribe().fields.getMap();
        DescribeFieldResult fieldDescribe = fields.get(fieldName).getDescribe();
        return fieldDescribe.isAccessible();
    }
    public static Boolean isAccessible(String sObjectType){
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectType);
        return schemaType.getDescribe().isAccessible();
    }
    public static Boolean isCreateable(String sObjectType){
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectType);
        return schemaType.getDescribe().isCreateable();
    }
    public static Boolean isDeletable(String sObjectType){
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectType);
        return schemaType.getDescribe().isDeletable();
    }
*/

    // For Aura Componenent
    //DHE removed Coupon_Type__c because was not existing
    @AuraEnabled
    public static List<CalendarEventObj>  getCoupan(String couponObject,String couponstartdate,String couponenddate,String dealRetailObject)
    {
        String coupanQuery='SELECT Id,Marketing_Coupon_Name__c,Coupon_Contract_Due_Date__c,'
        +couponstartdate+','+couponenddate +' FROM '+couponObject;

        System.debug('query>> '+coupanQuery);

        List<sObject> sObjectList = Database.query(coupanQuery);

        List<sObject> sObjectCompList = [SELECT Id, EBH_DealTitle__c,EBH_Date__c,EPH_EndDate__c,EBH_AcceptProposalsEnd__c,EBH_OpenSeatsAvailable__c FROM EBH_DealRetailCampaign__c
        where EBH_Date__c !=NULL AND EPH_EndDate__c !=NULL ];

        List<CalendarEventObj> eventRecords = new List<CalendarEventObj>();
        System.debug('coupansObjectList>>>'+sObjectList);
        System.debug('coupansObjectCompList>>>'+sObjectCompList);
        if(sObjectList.size()>0)
        {
        for (sObject obj : sObjectList) {
            System.debug('datetime'+obj.get('Coupon_Contract_Due_Date__c'));
            Date startDate = Date.valueOf(''+obj.get(couponstartdate));
            datetime dt= datetime.newInstance(startDate.year(), startDate.month(),startDate.day());
            String dateStr = dt.format('yyyy-MM-dd hh:mm:ss');

            Date endDate = Date.valueOf(''+obj.get(couponstartdate));
            datetime dtEndDate= datetime.newInstance(endDate.year(), endDate.month(),endDate.day());
            String endDateStr = dtEndDate.format('yyyy-MM-dd hh:mm:ss');

            CalendarEventObj newEv = new CalendarEventObj(String.valueOf(obj.Id),
                                          String.valueOf(obj.get('Marketing_Coupon_Name__c')),
                                          DateTime.valueOf(dateStr),
                                          DateTime.valueOf(endDateStr),
                                         // datetime.newInstance(dToday.year(), dToday.month(),dToday.day()),
                                         // datetime.newInstance(dToday.year(), dToday.month(),dToday.day()),
                                          String.valueOf(obj.get('Marketing_Coupon_Name__c')),
                                          String.valueOf('Coupon'));

            eventRecords.add(newEv);
        }
    }
    if(sObjectCompList.size()>0)
    {
        for (sObject obj : sObjectCompList) {
            System.debug('datetimecomp>>'+obj.get('EBH_Date__c'));
            Date dToday = Date.valueOf(''+obj.get('EBH_Date__c'));
            datetime dt= datetime.newInstance(dToday.year(), dToday.month(),dToday.day());
            String dateStr = dt.format('yyyy-MM-dd hh:mm:ss');
            CalendarEventObj newEv = new CalendarEventObj(String.valueOf(obj.Id),
                                            String.valueOf(obj.get('EBH_DealTitle__c')),
                                            DateTime.valueOf(dateStr),
                                            DateTime.valueOf(dateStr),
                                            String.valueOf(obj.get('EBH_OpenSeatsAvailable__c')),
                                            String.valueOf('Deal Retail'));

            eventRecords.add(newEv);
        }
    }

        System.debug('coupan>>>'+eventRecords);
        return eventRecords;
    }



    public class CalendarEventObj {
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String title {get;set;}
        @AuraEnabled
        public DateTime startDateTime {get;set;}
        @AuraEnabled
        public DateTime endDateTime {get;set;}
        @AuraEnabled
        public String description {get;set;}
        @AuraEnabled
        public String owner {get;set;}

        @AuraEnabled
        public Object record {get;set;}

        public CalendarEventObj(String i,String t, DateTime s, DateTime e, String d, String o){
            this.Id = i;
            this.title = t;
            this.startDateTime = s;
            this.endDateTime = e;
            this.description = d;
            this.owner = o;
        }

    }

    final static String DF_FORMAT_JS = 'yyyy-MM-dd hh:mm:ss';
    final static String SQOL_SETTING = 'Select Additional_Fields__c,Id,For_Profiles__c,Event_Start_Field__c,Event_Start_Time_Field__c,Event_End_Time_Field__c,Event_End_Field__c,Object_Name__c,Event_Title_Field__c,List_Field_Popup__c,Filter_Condition__c FROM Seller_Portal_Calendar_Setting__mdt Where Active__c=TRUE ';
    final static String PORTAL_NA = 'NA - Seller Portal';//TH:US-0012012:17/08/2022: 
    final static String PORTAL_AU = 'AU - Seller Portal';//TH:US-0012012:17/08/2022: 
    /*********************************************************************************************************************************
    @ class:    getCalendarItems
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0010540 - [SP - EU Deals] Add DRC in Calendar view to Home Page
    @ Param:    dateFrom,dateTo. yyyy-MM-dd. current start date and end date being shown in the calendar view
    @            List<String> statusFilter: filter apply?
    @            String searchingObj : what object being filtered? //SRO:26.05.2022 US-0010814 change from String to List<String>
    @            List<String> sellers : filter for coupon seller
    @ Return:   List<Object>
    @----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2021 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / US-0010540 - [SP - EU Deals] Add DRC in Calendar view to Home Page
    @----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.01.2022 / Mony Nou (mony.nou@gaea-sys.com) / US-0010642 - [SP - EU Deals] Status & Product filters on calendar on homepage
    @               : 20.05.2022/ vadhanak voun (vdhanak.voun@gaea-sys.com)/ US-0010786 - Display Coupon Seller records in Calendar on Homepage
    @               : 26.05.2022/ SRONG TIN (srong.tin@gaea-sys.com) / US-0010814 - Status, Product & Seller filters on calendar on homepage
    @               : 11.08.2022/ Sovantheany Dim (sovantheany.dim@gaea-sys.com) / US-0012012 - NA Portal Homepage rework and localizations needed
    @               : 02.09.2022/ Mony Nou / US-0012342 - Coupon records showing in to-do when permission set not assigned
    @               : 30/11/2022/ vadhanak voun/US-0012917 - [UK] Homepage
    *********************************************************************************************************************************/
    @AuraEnabled
    public static List<Object> getCalendarItems(String dateFrom,String dateTo, List<String> statusFilter,List<String> searchingObj,List<String> sellers,String metadata)
    {
        //NK:30/11/2022:US-0012917
        String whereByMetadata = String.isBlank(metadata)?'':' AND DeveloperName IN (' + ApexUtil.constructQuoteString(metadata.split(',')) + ')';
        
        String criteria = ''; //MN-21012022-US-0010642
        String couponCriteria = '';//SRONG-25.05.2022-US-0010814
        String dealCriteria = '';//SRONG-25.05.2022-US-0010814
        if (!statusFilter.isEmpty()) { //MN-21012022-US-0010642
            //SRONG-25.05.2022-US-0010814
            List<String> tmp = new List<String>();
            List<String> coupon_tmp = new List<String>();
            for (String staFil : statusFilter) {
                if(staFil.contains('Coupon')){
                    coupon_tmp.add(' (' + staFil + ') ');
                }else{
                    tmp.add(' (' + staFil + ') ');
                }
                
            }
            dealCriteria = String.join(tmp, ' OR ');
            couponCriteria = String.join(coupon_tmp, ' OR ');
        }
        //SRONG-25.05.2022-US-0010814
        String searchObj = '';
        Map<String,String> listSearchObj = new Map<String,String>();
        if(!searchingObj.isEmpty()){
            for (String objName : searchingObj) {
                listSearchObj.put(objName,objName);
            }
        }

        Date calendar_start = Date.valueOf(dateFrom);
        Date calendar_end = Date.valueOf(dateTo);
        List<Object> listObj = new List<Object>();
        //AND RecordTypeId=:rt_std.Id AND EBH_DealSlotDisabled__c=FALSE
        //RecordType rt_std = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', 'Deal_Campaign_V1');

        String currentProfile = [Select Profile.Name From User Where Id=:UserInfo.getUserId()].Profile.Name;
        //SRONG TIN : 02/05/2023 : US-0013353 - IT Deals SP Home Page
        
        Map<String, Object> portalDomain = SEP_Helper.getPortalDomain();
        //Boolean isNA = currentProfile.equalsIgnoreCase(PORTAL_NA);//TH:US-0012012:18/08/2022 //MN-06062024-US-0015298
        Boolean isNA = SEP_Helper.sepUser.isNA(); //MN-06062024-US-0015298: Use SP Main Domain instead of Profile

        //Boolean isAU = currentProfile.equalsIgnoreCase(PORTAL_AU);//TH:US-0012012:18/08/2022 //MN-06062024-US-0015298
        Boolean isAU = SEP_Helper.sepUser.isAU();//MN-06062024-US-0015298: Use SP Main Domain instead of Profile

        Boolean isIT = portalDomain.get('isIT') == true;//SRONG:US-0013353:02/05/2023
        
        Map<String,Schema.SObjectType> sobjTypesAll = Schema.getGlobalDescribe();

        // system.debug('--1: '+allFieldDes.get('EBH_Date__c').getDescribe().getDataTranslationEnabled());
        // system.debug('--2: '+allFieldDes.get('EBH_Date__c').getDescribe().getLabel());

        Map<String,Schema.SObjectType> gmap = Schema.getGlobalDescribe(); //MN-02092022-US-0012342
        
        for(Seller_Portal_Calendar_Setting__mdt setting : Database.query(SQOL_SETTING + whereByMetadata))
        {
            //SRONG-30.05.2022-US-0010814
            searchObj = listSearchObj.get(setting.Object_Name__c);
            if(searchObj != null && searchObj == 'Coupon_Seller__c'){
                criteria = couponCriteria;
            }else if(searchObj != null && searchObj == 'EBH_DealRetailCampaign__c'){
                criteria = dealCriteria;
            }
            //if(searchObj != setting.Object_Name__c)continue;
            //TH:US-0012012:10/08/2022
            if(setting.For_Profiles__c <> NULL && !setting.For_Profiles__c.contains(currentProfile) || searchObj != setting.Object_Name__c)continue; //if setting is not for this user's profile

            String objName = setting.Object_Name__c;

            //MN-02092022-US-0012342 - Enforced sObject Access => if user has no access to sObject => skip it 
            if (String.isNotBlank(objName) && gmap.containsKey(objName) && !gmap.get(objName).getDescribe().isAccessible()) continue;
            //----- MN-02092022-US-0012342

            String filterCon = setting.Filter_Condition__c==null?'':setting.Filter_Condition__c;
            //MN-21012022-US-0010642
            if (String.isBlank(filterCon) && String.isNotBlank(criteria)) criteria = ' WHERE ' + criteria; 
            if (String.isNotBlank(filterCon) && String.isNotBlank(criteria)) criteria = ' AND (' + criteria + ')';
            //SRONG-25.05.2022-US-0010814
            if(searchObj == 'Coupon_Seller__c'){
                if (String.isBlank(filterCon) && String.isBlank(criteria) && !sellers.isEmpty()) criteria += ' WHERE ( Seller__c in :sellers )';
                if (String.isNotBlank(filterCon) && !sellers.isEmpty()) criteria += ' AND ( Seller__c in :sellers )';
            }

            filterCon = filterCon + criteria; //MN-21012022-US-0010642 - if there are any criteria from Filter section on page then it will AND with those criteria             

            Set<String> setFields = new Set<String>{
                'Id',
                setting.Event_Start_Field__c,
                setting.Event_End_Field__c,
                setting.Event_Title_Field__c,
                setting.Event_Start_Time_Field__c,
                setting.Event_End_Time_Field__c
            };
            if(setting.List_Field_Popup__c<>null)
            {
                setFields.addAll((setting.List_Field_Popup__c).split(','));
            }
            if(setting.Additional_Fields__c<>null)
            {
                setFields.addAll((setting.Additional_Fields__c).split(','));
            }

            String soql_obj = 'SELECT ' + String.join(new List<String>(setFields), ',') + ' FROM '+objName + ' ' + filterCon;
            List<CalendarEventObj> listEvent = new List<CalendarEventObj>();
            for(SObject sobj : Database.query(soql_obj))
            {

                CalendarEventObj newEv = new CalendarEventObj(
                    sobj.Id+'',
                    String.valueOf(sobj.get(setting.Event_Title_Field__c)),
                    DateTime.newInstanceGMT((Date)sobj.get(setting.Event_Start_Field__c), (Time)sobj.get(setting.Event_Start_Time_Field__c)),
                    DateTime.newInstanceGMT((Date)sobj.get(setting.Event_End_Field__c), (Time)sobj.get(setting.Event_End_Time_Field__c)),
                    '',
                    ''
                );
                
                newEv.record = sobj;
                listEvent.add(newEv);
            }

            Map<String, Schema.SObjectField> allFieldDes = sobjTypesAll.get(objName).getDescribe().fields.getMap();
            Map<String,Object> mapFieldApiLabel = new Map<String,Object>(); // for label translation
            for(String fName: setFields)
            {            
                if(!fName.contains('toLabel('))
                {
                    mapFieldApiLabel.put(fName,new Map<String,String>{'label'=>allFieldDes.get(fName).getDescribe().getLabel(),'type'=>(allFieldDes.get(fName).getDescribe().getType()+'').toLowerCase()});
                }else
                {
                    //toLabel(Coupon_Seller_Stage_Portal__c) Coupon_Seller_Stage_Portal__label
                    String fname2a = (fName.split(' ')[0]).replace('toLabel(','').replace(')','');
                    String fname2b = fName.split(' ')[1];                   
                    mapFieldApiLabel.put(fname2a,new Map<String,String>{'label'=>allFieldDes.get(fname2a).getDescribe().getLabel(),'type'=>(allFieldDes.get(fname2a).getDescribe().getType()+'').toLowerCase()});
                    mapFieldApiLabel.put(fname2b,new Map<String,String>{'label'=>allFieldDes.get(fname2a).getDescribe().getLabel(),'type'=>(allFieldDes.get(fname2a).getDescribe().getType()+'').toLowerCase()});
                }
                
            }

            setting.List_Field_Popup__c = cleanToLabel(setting.List_Field_Popup__c);
            setting.Additional_Fields__c = cleanToLabel(setting.Additional_Fields__c);
            Map<String,Object> mapObj = new Map<String,Object>
            {
                'setting'=>setting,
                'mapFieldApiLabel'=>mapFieldApiLabel,
                'listEvent'=>listEvent,
                'isNA'=>isNA,//TH:US-0012012:18/08/2022
                'isAU'=>isAU,//TH:US-0012012:18/08/2022
                'isIT'=>isIT //SRONG:US-0013353:02/05/2023
            };

            listObj.add(mapObj);
        }



        return listObj;
    }

    private static String cleanToLabel(String listFields)
    {
        List<String> listResult = new List<String>();
        for(String fName: listFields.split(','))
        {
            //,toLabel(Coupon_Seller_Stage_Portal__c) Coupon_Seller_Stage_Portal__label,
            if(fName.contains('toLabel('))
            {
                listResult.add(fName.split(' ')[1]);
            }else
            {
                listResult.add(fName);
            }
        }
        return String.join(listResult, ',');
    }

    /***********************************************************************************************************************************
    @ Method:       fetchStatusFilterMetadata 
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Description:  To get all 'DECalendarFilter_Status' records from Custom Metadata Seller_Portal_Global_Variables__mdt's that has Prefix that assigned in DeveloperName field
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Params:       String, prefix before underscore that we use in DeveloperName field of each records 
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:      List<Seller_Portal_Global_Variables__mdt>
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.01.2022 / Mony Nou / US-0010642 - [SP - EU Deals] Status & Product filters on calendar on homepage
    @                 19/08/2022/ Sovantheany Dim / US-0012012 - NA Portal Homepage rework and localizations needed
    @                 30/11/2022/ vadhanak voun/US-0012917 - [UK] Homepage
    @                                          / specificMeta: setup from community builder
    @                 10/01/2023/ Mony Nou / US-0012915 - [FR] Homepage
    @                 04/04/2023/ Bora Chhorn / US-0012916 - [IT] Homepage
    @                 13/11/2024/ vadhanak voun/ US-0016188 - [Seller Portal License Change] - Components not visible correctly with new profile
    ***********************************************************************************************************************************/
    @AuraEnabled ( cacheable=true )   
    public static List<Seller_Portal_Global_Variables__mdt> fetchStatusFilterMetadata(String prefix,String specificMeta) {
        
        String tmp = (String.isNotBlank(prefix)?prefix.trim():'') + '%';
        //NK:13/11/2024:US-0016188
        // String currentProfile = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;//TH:US-0012012:19/08/2022
        User usr = (User)ApexSafe.query().doQuery('SELECT Id, Contact.Account.SP_Main_Domain__c FROM User WHERE Id =:usrId', new Map<String, Object>{'usrId' => UserInfo.getUserId()})[0];
        List<Seller_Portal_Global_Variables__mdt> fetchMeta = new List<Seller_Portal_Global_Variables__mdt>();
        
        //MN-10012023-US-0012915-Added Value_in_French__c to below query
        //BR-04042023-US-0012916-Added Value_in_Italian__c to below query
        String soqlMeta = 'SELECT Id, Label, DeveloperName, Value__c, Value_in_German__c, Value_Big__c,Value_in_French__c, Value_in_Italian__c,For_Domains__c, For_Profiles__c FROM Seller_Portal_Global_Variables__mdt';
        String sWhere = String.isBlank(specificMeta) ? '  WHERE DeveloperName like:tmp Order By DeveloperName ' : ' WHERE DeveloperName IN('+ ApexUtil.constructQuoteString(specificMeta.split(','))+') Order By DeveloperName ';
        //for(Seller_Portal_Global_Variables__mdt metaData : [SELECT Id, Label, DeveloperName, Value__c, Value_in_German__c, Value_Big__c,For_Profiles__c FROM Seller_Portal_Global_Variables__mdt WHERE DeveloperName like:tmp Order By DeveloperName]){
        // for(Seller_Portal_Global_Variables__mdt metaData : Database.query(soqlMeta+sWhere)){
        for(Seller_Portal_Global_Variables__mdt metaData : (Seller_Portal_Global_Variables__mdt[])ApexSafe.query().secCheck(false).doQuery(soqlMeta+sWhere,new Map<String, Object>{'tmp' => tmp})){
            //TH:US-0012012:19/08/2022
            //NK:13/11/2024:US-0016188
            // if(metaData.For_Profiles__c == null || metaData.For_Profiles__c.contains(currentProfile)){
            if(metaData.For_Domains__c == null || (metaData.For_Domains__c<>NULL && metaData.For_Domains__c==usr.Contact.Account.SP_Main_Domain__c)){
                fetchMeta.add(metaData);
            }
        }
        return fetchMeta;

    }

}