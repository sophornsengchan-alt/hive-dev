/*********************************************************************************************************************************@ Class:          ClsListViewController
@ Version:        1.0
@ Author:         Sochettra Saing
@ Purpose:        Ability to display Deal List View(EBAY-260)
@ ClsFullCalendarController for LWC lwcDealsFullCalendar
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 28.06.2021 / Sochettra Saing / Created the class.
@ Change history: 24.11.2021 / Sovantheany Dim / US-0010793 - [SEP] Seller views their Deals in Deal Windows
@ Change history: 11/01/2022 : sovantheany dim : US-0010969 -  BUG -[SP EU-Deals] All Deal List Columns " Zustand des Artikels " and " Aktionsformat " not display value in DE
@ Change history: 13-05-2022 / Loumang SENG / US-0011707 -  Ability to view Coupons in list views on Coupon list page (upcoming, future, past, declined, etc) - Part 2
@ Change history: 15.08.2022 / Loumang SENG / US-0012218 - NA Coupons: hide Coupon code field from NA Sellers
@ Change history: 02.09.2022 / Mony Nou / US-0012342 - Coupon records showing in to-do when permission set not assigned
@ Change history: 06-09-2022 / Mony Nou / US-0012572 - Decline reason not displaying in German
@ Change history: 13-10-2022 / Sovantheany Dim/ US-0012814 - PM Deals should not be visible in Deals tab
@ Change history: 11-01-2023 / Mony Nou / US-0012905 - PM Deals feature - Link multiple Account
                : 02-06-2023 / Loumang SENG / US-0013029 - Streamline of coupon seller statuses & retiring coupon fields(AC2)
                : 09.06.2023 / Sambath Seng / US-0013316 - Cancelled Items - Seller Portal
                : 18.08.2023/ vadhanak voun / US-0013998 - Tech Debt: fix dml in the loop for ClsListViewController
                : 12.01.2024 / Sambath Seng / US-0013136 - Seller_Portal_Status__c - Deprecate
                : 19.02.2025 / Sovantheany Dim / US-0016318 - 9.1 - Seller Portal - My Subsidized Deal Contract Agreements Page
                : 03.03.2025 / Sovantheany Dim / US-0016567 - 12.2 - Seller Portal - Details of the deal in the Deals List View
                : 17.10.2025 / Leon Morocki / US-0033386 - Hierarchical relationship display in Seller Portal list
                : 17.10.2025 / Leon Morocki / PMD fixes
                : 29.10.2025 / Sovantheany Dim / US-0033793 - Seller Portal Stuck in Buffering For Deals
*********************************************************************************************************************************/
public with sharing class ClsListViewController {

    /*@AuraEnabled
    public static Map<String, Object> getAllRecords(String mdtName){
        return new Map<String,Object>();
    }*/

    /*@AuraEnabled
    public static String initLocalCode(){
        String userSite = 'en';
        Map<String, String> mapLanguageLocalCode = new Map<String, String>{'Germany'=>'de'};
       
        List<Contact> cons = [SELECT Id, Account.EBH_RegistrationSite__c FROM Contact WHERE Id IN (SELECT ContactId FROM User WHERE Id =:UserInfo.getUserID())];

        if (!cons.isEmpty() || Test.isRunningTest()) {

            String regSite = (!Test.isRunningTest()) ? cons[0].Account.EBH_RegistrationSite__c : '';

            userSite = mapLanguageLocalCode.containsKey(regSite) ? mapLanguageLocalCode.get(regSite) : 'en';

        }

        return userSite;    
    }*/

    @AuraEnabled
    public static Map<String, Object> getAllSetting(String mdtName){
       //System.debug('@@@@ metadata name'+mdtName);
        Map<String, Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{
            // String message = '';
            mdtName = mdtName.trim();
            Seller_Portal_Setting__mdt spsMdt = readMtdObject(mdtName);
            if(checkIsInValid(spsMdt)){
                //System.debug('@@@@ invalid metadada'+spsMdt);
                mResult.put('message', 'Missing FiledSet or Object Name!');
            } else {

                //MN-02092022-US-0012342 - Enforced sObject Access => if user has no access to sObject => skip it 
                Boolean hasSObjAccess = Schema.getGlobalDescribe().get(spsMdt.Object_API_Name__c).getDescribe().isAccessible();
                mResult.put('message', 'no access on sObject: ' + spsMdt.Object_API_Name__c);
                if(!hasSObjAccess) {return mResult; }         
                //----- MN-02092022-US-0012342

                //System.debug('@@@@ valid metadada'+spsMdt);
                
                //Map<String, Object> mHighlightFields = readFieldSet(spsMdt.Field_Set_Name__c, spsMdt.Object_API_Name__c);
                //Map<String, Object> mDetailFields = readFieldSet(spsMdt.Field_Set_Detail_Name__c, spsMdt.Object_API_Name__c);
                Set<String> setAccessFnames = getAccessibleFieldApiNames(spsMdt.Object_API_Name__c); //LA-15-08-22-US-0012218;
                
                Map<String, Object> mHighlightFields = readFieldSet(spsMdt.Field_Set_Name__c, spsMdt.Object_API_Name__c, setAccessFnames); //LA-15-08-22-US-0012218
                Map<String, Object> mDetailFields = readFieldSet(spsMdt.Field_Set_Detail_Name__c, spsMdt.Object_API_Name__c, setAccessFnames); //LA-15-08-22-US-0012218
                
                //System.debug('mHighlightFields::'+mHighlightFields);
                //System.debug('mDetailFields::'+mDetailFields);
                Set<String> allFieldsAPI = new Set<String>();
                allFieldsAPI.addAll((Set<String>) mHighlightFields.get('allFields'));
                allFieldsAPI.addAll((Set<String>) mDetailFields.get('allFields'));
                //String query = buildQuery(spsMdt, allFieldsAPI);
                
                RecordType recType = String.isBlank(spsMdt.Record_Type__c) ? null : ApexUtil.getRecordTypeByName(spsMdt.Object_API_Name__c, spsMdt.Record_Type__c);//TH:US-0016318
                mResult.put('recordTypeId', recType == null ? '' : recType.Id);//TH:US-0016318
                mResult.put('highlightFields', mHighlightFields.get('allFieldsObj'));
                mResult.put('detailFields', mDetailFields.get('allFieldsObj'));
                mResult.put('numberOfRecordsPerPage', spsMdt.Number_Of_Records_To_Display__c);
                
                //mResult.put('userDisplayMode', getPortalDisplayDensity()); //MN-02122021-US-0010808

                
                mResult.put('sObjectName', spsMdt.Object_API_Name__c); // Samnang MUONG : return sobject name
                
                mResult.put('status', 'success');
            }
            
        } catch( Exception ex){mResult.put('message', 'Error:'+ex.getLineNumber()+ ex.getMessage());}
        
        return mResult;
    }

    @AuraEnabled
    public static Map<String, Object> doUpdateContact(Contact con){
        Map<String, Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{
            ApexSafe.dml().secCheck(false).doUpdate(new List<Contact> { con }, true);
            mResult.put('status', 'success');
            mResult.put('message', 'The contact is updated successfully!');
        } catch( Exception ex){mResult.put('message', 'Error:'+ex.getLineNumber()+ ex.getMessage());}
        return mResult;
    }

    /*********************************************************************************************************************************
    @ Method:          getSearchResult
    @ Parameter :      String searchKey, String settingName,string filter,String optionalId
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.06.2023 / Sambath Seng / US-0013316 - Cancelled Items - Seller Portal
    @               : 12.01.2024 / Sambath Seng / US-0013136 - Seller_Portal_Status__c - Deprecate
    @               : 17.10.2025 / Leon Morocki / US-0033386 - Hierarchical relationship display in Seller Portal list
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getSearchResult(String searchKey, String settingName,string filter,String optionalId){
        //try {

            settingName = settingName.trim();
            //String query = 'SELECT EBH_eBayItemID__c, EBH_ProductTitle__c, Status_Seller_Portal__c, EBH_DealPrice__c, EBH_RRPWASPrice__c, EBH_Quantity__c, EBH_Category__c, EBH_DealStartDate__c, EBH_DealEndDate__c, eBay_Seller_Name__c FROM EBH_Deal__c WHERE EBH_DealStartDate__c > TODAY AND OwnerId=\'0051F00000o9wFdQAI\'';
            
            Seller_Portal_Setting__mdt spsMdt = [SELECT DeveloperName, Field_Set_Name__c, Field_Set_Detail_Name__c, Object_API_Name__c, Filter_Values__c, Number_Of_Records_To_Display__c, Order_Fields__c, Maximum_Records__c, Specific_Search_Field__c, Hierarchy_Relationship_Name__c FROM Seller_Portal_Setting__mdt WHERE DeveloperName =: settingName WITH SECURITY_ENFORCED];
            String selectedFields = '';
            String filters = '';
            String newFilter='';
            String newFilterToExcludePMDeal = '';
            
             //sObject filterData=(sObject)JSON.deserialize(filter,sObject.class);
             if(string.isNotBlank(filter))
             {
                newFilter= filter;
            //  Filter filterData=(Filter)(JSON.deserialize(filter,Filter.class));
            
             

            //     if(String.isNotBlank(filterData.status))
            //     {
            //         newFilter+=' AND Seller_Portal_Status__c='+'\''+filterData.status +'\'';
            //     }
           
            //     if(String.isNotBlank(filterData.rejectionReason))
            //     {
            //         newFilter+=' AND EBH_ReasonforRejection__c='+'\''+filterData.rejectionReason +'\'';
            //     }

            //     if(String.isNotBlank(filterData.dealFormat))
            //     {
            //         newFilter+=' AND EBH_DealFormat__c='+'\''+filterData.dealFormat +'\'';
            //     }
            //     if(String.isNotBlank(filterData.startDate)||String.isNotBlank(filterData.endDate))
            //     {
            //         newFilter+=' AND EBH_DealStartDate__c>='+''+filterData.startDate +'';
            //         newFilter+=' AND EBH_DealEndDate__c <='+''+filterData.endDate +'';
            //     }
            }
            
            String pmDealRT = '';
            if(!checkIsInValid(spsMdt)){
                Set<String> setAccessFnames = getAccessibleFieldApiNames(spsMdt.Object_API_Name__c); //LA-15-08-22-US-0012218;
                
                Map<String, Object> mHighlightFields = readFieldSet(spsMdt.Field_Set_Name__c, spsMdt.Object_API_Name__c, setAccessFnames); //LA-15-08-22-US-0012218
                Map<String, Object> mDetailFields = readFieldSet(spsMdt.Field_Set_Detail_Name__c, spsMdt.Object_API_Name__c, setAccessFnames);//LA-15-08-22-US-0012218

                //Map<String, Object> mHighlightFields = readFieldSet(spsMdt.Field_Set_Name__c, spsMdt.Object_API_Name__c);
                //Map<String, Object> mDetailFields = readFieldSet(spsMdt.Field_Set_Detail_Name__c, spsMdt.Object_API_Name__c);
                
                filters = (String.isNotBlank(spsMdt.Filter_Values__c) ? spsMdt.Filter_Values__c : '');

                Set<String> allFieldsAPI = new Set<String>();
                allFieldsAPI.addAll((Set<String>) mHighlightFields.get('allFields'));
                allFieldsAPI.addAll((Set<String>) mDetailFields.get('allFields'));

                if (spsMdt.Object_API_Name__c == 'EBH_Deal__c') {
                    allFieldsAPI.add('EBH_BusinessName__r.Name'); //MN-27042021-US-0010950 - To get EBH_BusinessName__r.Name
                    //TH:US-0012814:13/10/2022 : PM Deals should not be visible in Deals tab 
                    if(!spsMdt.DeveloperName.startsWith('PM_Deal_')){
                        pmDealRT = 'PM_Deal';
                        newFilterToExcludePMDeal = ' RecordType.DeveloperName !=: pmDealRT ' ; 
                    }   
                }
                //MN-11012023-US-0012905
                else if ( spsMdt.Object_API_Name__c == 'Deal_Contract_Agreement__c') {
                    allFieldsAPI.add('eBay_Seller__r.Name');
                    allFieldsAPI.add('Status__c'); //TH:US-0016318
                    allFieldsAPI.add('RecordType.DeveloperName'); //TH:US-0016318
                }
                selectedFields = String.join(new List<String>(allFieldsAPI), ', ');
                
            }
            
            String key = '';
            String id = '';
            String optionalQueryId = ''; //SB 09.06.2023 US-0013316
            // Id userId = UserInfo.getUserID();
            //Boolean hasOwnerIdField = doesFieldExist(spsMdt.Object_API_Name__c, 'OwnerId');

            // filters = (filters.containsIgnoreCase('{$User.Id}') ?filters.replace('{$User.Id}', '\''+userId +'\'') : 
            //                                                     (String.isNotBlank(filters)? filters +newFilter+ ' AND OwnerId='+'\''+userId +'\'' : ' OwnerId='+'\''+userId +'\''));

           // Updated 26/10/2021 Samnang MUONG : for ignore ownerId for list view of Deal_Search_Result and Deal_Retail_Campaign_Search_Result
            //Set<String> ignoreOwnerIdFieldSetName = new Set<String>{'Deal_Search_Result', 'Deal_Retail_Campaign_Search_Result'};

            //MN-09122021-US-0010932-For some reason some org return this value as Decimal => cause an issue with Query that expected such value as integer
            Integer maxRecords = (spsMdt.Maximum_Records__c == null || spsMdt.Maximum_Records__c == 0)?0:Integer.valueOf(spsMdt.Maximum_Records__c); 

            //TH:comment out code filter by OwnerId :US-0010889:14/12/2021
           /*if (!ignoreOwnerIdFieldSetName.contains(settingName)) {
               filters = (filters.containsIgnoreCase('{$User.Id}') ?filters.replace('{$User.Id}', '\''+userId +'\'') : 
                                                                   (String.isNotBlank(filters)? filters +newFilter+ (hasOwnerIdField ? ' AND OwnerId='+'\''+userId +'\'' : '') : (hasOwnerIdField ? ' OwnerId='+'\''+userId +'\'' : '')));
           }*/
           filters = (String.isNotBlank(filters)? filters +newFilter : '');
             //END US-0010889 

            //SB 09.06.2023 US-0013316
            if(String.isNotBlank(optionalId)) {
                optionalQueryId = optionalId;
            }

            if ( String.isNotBlank(searchKey)) {
                key = '%' + searchKey + '%';

                //TH:US-0010793 :24/11/2021: id is using in Meta Data Seller Portal Setting.My_Deal_Related_List
                id = searchKey;
                // SRONG TIN:US-0010435 : 2.05.2022: Ability to view Coupons in list views on Coupon list page (upcoming, future, past, declined, etc) - Part 1
                if (String.isNotBlank(filters) && String.isNotBlank(spsMdt.Specific_Search_Field__c)) {
                    filters += ' AND ';
                }

                if(String.isNotBlank(spsMdt.Specific_Search_Field__c) ) {
                    filters += ' (' + spsMdt.Specific_Search_Field__c +') ';
                }
            }
            // update 01/10/2021 : Samnang MUONG : purpose : Translate picklist value
            // update 11/01/2022 : TH : US-0010969 -  add translation for picklist value "Item_Condition__c" and "EBH_DealFormat__c"\
            // update 13-05-2022 : LA : US-0011707 : Add translation for picklist value "Coupon_Type__c" and "Coupon_Seller_Stage_Portal__c"
            // update 06-09-2022 : MN : US-0012572 : Add translation for picklist value "Seller_Declined_Reasons__c"
            // SB 12.01.2024 US-0013136
            // String newSelectedFields = selectedFields.replace('Seller_Portal_Status__c', 'toLabel(Seller_Portal_Status__c)')
            String newSelectedFields = selectedFields.replace('Item_Condition__c', 'toLabel(Item_Condition__c)')
                                        .replace('EBH_DealFormat__c', 'toLabel(EBH_DealFormat__c)')
                                        .replace('Coupon_Type__c', 'toLabel(Coupon_Type__c)')
                                        .replace('Coupon_Seller_Stage_Portal__c', 'toLabel(Coupon_Seller_Stage_Portal__c)')
                                        .replace('Seller_Declined_Reasons__c','toLabel(Seller_Declined_Reasons__c)');



            //TH:US-0012814:13/10/2022 : PM Deals should not be visible in Deals tab 
            if (String.isNotBlank(newFilterToExcludePMDeal)) {
                filters += (String.isNotBlank(filters) ?' AND ' :'') + newFilterToExcludePMDeal;
            }

            //MN-09122021-US-0010932 - Replace field spsMdt.Maximum_Records__c with Integer variable max_records so that it will make sure to have Integer Value for LIMIT 
            //String query = 'SELECT '+ newSelectedFields + ' FROM '+ spsMdt.Object_API_Name__c +(String.isNotBlank(filters)? ' WHERE '+filters : '') + (String.isNotBlank(spsMdt.Order_Fields__c)? ' ORDER BY '+spsMdt.Order_Fields__c : '' ) + (spsMdt.Maximum_Records__c > 0 ? ' LIMIT '+spsMdt.Maximum_Records__c:'');
            String hierarchySubquery = (String.isNotBlank(spsMdt.Hierarchy_Relationship_Name__c) ? '(SELECT ' + newSelectedFields + ' FROM ' + spsMdt.Hierarchy_Relationship_Name__c + ')' : '');
            String query = 'SELECT '+ newSelectedFields + (String.isNotBlank(hierarchySubquery) ? ', ' + hierarchySubquery : '') + ' FROM '+ spsMdt.Object_API_Name__c +(String.isNotBlank(filters)? ' WHERE '+filters : '') + (String.isNotBlank(spsMdt.Order_Fields__c)? ' ORDER BY '+spsMdt.Order_Fields__c : '' ) + (maxRecords > 0 ? ' LIMIT '+ maxRecords:'');

            Map<String,Object> mResult = new Map<String,Object>();
            System.System.debug('query---'+query);
            mResult.put('query', query);
            mResult.put('settingName', settingName);
            // TODO TECH DEBT extra "id" bind variable added because it exists in mdt filter criteria - need to review
            mResult.put('listRecord', ApexSafe.query().secCheck(false).doQuery(query, new Map<String, Object> { 'id' => id, 'key' => key, 'pmDealRT' => pmDealRT, 'optionalQueryId' => optionalQueryId }));//TH: US-0033793 : 29.10.2025: add optionalQueryId to bind variable 
            //mResult.put('listRecord', ApexSafe.query().doQuery(query));
            mResult.put('newFilter', newFilter);
            mResult.put('hierarchyRelationshipName', spsMdt.Hierarchy_Relationship_Name__c);
            return mResult;    
            
         //} catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    /* MN-02122021-US-0010808
    private static User getPortalDisplayDensity(){
        return [SELECT Id, ContactId, Contact.Portal_Display_Density__c FROM User WHERE Id=: UserInfo.getUserID() Limit 1];
    }
    */

    private static Boolean checkIsInValid(Seller_Portal_Setting__mdt spsMdt) {
        Boolean isInValid = false;
        if (String.isBlank(spsMdt.Field_Set_Name__c) || String.isBlank(spsMdt.Object_API_Name__c)) {
            isInValid = true;
        }
        return isInValid;
    }

    public static boolean doesFieldExist(String objName, string fieldName){
        try {
            SObject so = Schema.getGlobalDescribe().get(objName).newSObject();
            return so.getSobjectType().getDescribe().fields.getMap().containsKey(fieldName);
        }
        catch(Exception ex) {return false;}
         
        
    }

    /*private static String buildQuery(Seller_Portal_Setting__mdt spsMdt, Set<String> allFieldsAPI) {
        String query = ''; 
        String selectedField = String.join(new List<String>(allFieldsAPI), ', ');
        String filters = (String.isNotBlank(spsMdt.Filter_Values__c) ? spsMdt.Filter_Values__c : '');

        Id userId = UserInfo.getUserID();

        filters = (filters.containsIgnoreCase('{$User.Id}') ?filters.replace('{$User.Id}', '\''+userId +'\'') : 
                                                                filters + ' AND OwnerId='+'\''+userId +'\'');
        
        String orderFields = (String.isNotBlank(spsMdt.Order_Fields__c)? spsMdt.Order_Fields__c : '');

        query = 'SELECT '+selectedField+' FROM '+spsMdt.Object_API_Name__c+(String.isNotBlank(filters)? ' WHERE '+filters : '')+(String.isNotBlank(orderFields)? ' ORDER BY '+orderFields : '' ) + (spsMdt.Maximum_Records__c > 0? ' LIMIT '+spsMdt.Maximum_Records__c:'');
        
        return query;
    }*/

    public static Map<String, Object> readFieldSet(String fieldSetName, String objectName, Set<String> setAccessFnames) {
        Map<String, Object> mFieldSet = new Map<String,Object>();

        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();


        Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        //List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        List<Map<String,String>> allFieldsObj = new List<Map<String,String>>();
        Set<String> allFields = new Set<String>();
        Map<String,String> mapFieldColHeader = new Map<String,String>();//TH:US-0016567
        for(Schema.FieldSetMember fsm : fieldSetObj.getFields()) {

            if(setAccessFnames == null || setAccessFnames.contains(fsm.getFieldPath())){ //LA-15-08-22-US-0012218
                //lstFields.add(fieldSetMemberObj.getFieldPath());
                Map<String,String> mObj = new Map<String,String>();
                mObj.put('fieldName',fsm.getFieldPath());
                mObj.put('label',fsm.getLabel());
                mObj.put('type',String.valueOf(fsm.getType()));
                allFieldsObj.add(mObj);

                allFields.add(fsm.getFieldPath());

                mapFieldColHeader.put(fsm.getFieldPath(),fsm.getLabel());//TH:US-0016567
            }

        }
        mFieldSet.put('allFields', allFields);
        mFieldSet.put('allFieldsObj', allFieldsObj);
        mFieldSet.put('mapFieldColHeader', mapFieldColHeader);//TH:US-0016567

        return mFieldSet; 
    }
    @AuraEnabled
    public static Seller_Portal_Setting__mdt readMtdObject(String mdtName) {
        String soqlMtd = 'SELECT DeveloperName, Field_Set_Name__c, Field_Set_Detail_Name__c, Object_API_Name__c, Filter_Values__c, Number_Of_Records_To_Display__c, Order_Fields__c, Maximum_Records__c, Specific_Search_Field__c,Record_Type__c FROM Seller_Portal_Setting__mdt WHERE DeveloperName =: mdtName';
        List<Seller_Portal_Setting__mdt> mdtResults = (List<Seller_Portal_Setting__mdt>) ApexSafe.query().secCheck(false).doQuery(soqlMtd,new Map<String, Object> {'mdtName' => mdtName});
        return mdtResults.isEmpty() ? new Seller_Portal_Setting__mdt() : mdtResults[0];
    }

    @AuraEnabled
    public static String getMtdObjectName(String mdtName) {
        //System.debug('@@@@ mdtName'+mdtName);
        Seller_Portal_Setting__mdt spsMdt = new Seller_Portal_Setting__mdt();
        for(Seller_Portal_Setting__mdt mdt : [SELECT DeveloperName, Object_API_Name__c FROM Seller_Portal_Setting__mdt WHERE DeveloperName =: mdtName WITH SECURITY_ENFORCED]){
            spsMdt = mdt;
        }

        return spsMdt.Object_API_Name__c;
    }

    public class Filter {
        public String status;
        public String rejectionReason;
        public String dealFormat;
        public String startDate;
        public String endDate;
    }

    /*********************************************************************************************************************************
    @ Method:          updateInterest
    @ Parameter :      coupon id
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: ...
    @               18.08.2023/ vadhanak voun / US-0013998 - Tech Debt: fix dml in the loop for ClsListViewController
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> updateInterest(List<Id> coup){
        Map<String, Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{
            // update coup;
            // Map<String, String> session = Auth.SessionManagement.getCurrentSession();
            String soqlCouponSeller = 'SELECT Id, Coupon__c, Coupon_Seller_Stage__c, Contract_Accept_Date__c, Contract_Accepted_From__c FROM Coupon_Seller__c WHERE Coupon__c IN: coup';
            List<Coupon_Seller__c> lstCouponSeller = (List<Coupon_Seller__c>) ApexSafe.query().secCheck(true).doQuery(soqlCouponSeller, new Map<String, Object> {'coup' => coup});
            if (!lstCouponSeller.isEmpty()) {
                for (Integer i = 0; i < lstCouponSeller.size(); i++) {
                    // if(String.isNotBlank(lstCoupon_Seller[i].Id)){
                    //     update new Coupon_Seller__c(
                    //         Id=lstCoupon_Seller[i].Id, 
                    //         //Coupon_Seller_Stage__c='Commited' //LA-02-06-2023-US-0013029
                    //         Coupon_Seller_Stage__c='Reached' //LA-02-06-2023-US-0013029: Replace picklist 'Commited' to 'Reached'
                    //         // ,
                    //         // Contract_Accept_Date__c=system.now(),
                    //         // Contract_Accepted_From__c=session.get('SourceIp')
                    //     );   
                    // }
                    //NK:18/08/2023:US-0013998
                    lstCouponSeller[i].Coupon_Seller_Stage__c='Reached';
                }
                //NK:18/08/2023:US-0013998
                ApexSafe.dml().secCheck(false).doUpdate(lstCouponSeller, true);
            }
            mResult.put('status', 'success');
            mResult.put('message', 'The Coupon is updated successfully!');
        } catch( Exception ex){mResult.put('message', 'Error:'+ex.getLineNumber()+ ex.getMessage());}
        return mResult;
    }

    @AuraEnabled
    public static Map<String, Object> updateNotInterest(List<Id> coup){
        Map<String, Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{
            // update coup;
            String soqlCouponSeller = 'SELECT Id, Coupon__c, Coupon_Seller_Stage__c, Contract_Accept_Date__c, Contract_Accepted_From__c FROM Coupon_Seller__c WHERE Coupon__c IN: coup';
            List<Coupon_Seller__c> lstCouponSeller = (List<Coupon_Seller__c>) ApexSafe.query().secCheck(true).doQuery(soqlCouponSeller, new Map<String, Object> {'coup' => coup});
            if (!lstCouponSeller.isEmpty()) {
                List<Coupon_Seller__c> recordsToUpdate = new List<Coupon_Seller__c>();
                for (Integer i = 0; i < lstCouponSeller.size(); i++) {
                    if (String.isNotBlank(lstCouponSeller[i].Id)) {
                        recordsToUpdate.add(new Coupon_Seller__c(
                            Id=lstCouponSeller[i].Id,
                            Coupon_Seller_Stage__c='Seller Declined',
                            Seller_Declined_Reasons__c='Other'
                        ));
                    }
                }
                // Bulkified DML - single update operation outside the loop
                if (!recordsToUpdate.isEmpty()) {
                    ApexSafe.dml().secCheck(false).doUpdate(recordsToUpdate, true);
                }
            }
            mResult.put('status', 'success');
            mResult.put('message', 'The Coupon is updated successfully!');
        } catch( Exception ex){mResult.put('message', 'Error:'+ex.getLineNumber()+ ex.getMessage());}
        return mResult;
    }

    public static Set<String> getAccessibleFieldApiNames(String objApiName){
        Set<String> setAccessFnames = new Set<String>();
        SObjectType objectType = Schema.getGlobalDescribe().get(objApiName);
        Map<String,Schema.SObjectField> mfields = objectType.getDescribe().fields.getMap();
        for(Schema.SObjectField field : mfields.values()){
            Schema.DescribeFieldResult dfr = field.getDescribe();
            if(dfr.isAccessible()){
                setAccessFnames.add(dfr.getName());
            }
        }
        return setAccessFnames;
    }

    /*********************************************************************************************************************************
    @ Method:          fetchActionMetadata
    @ Parameter :      String objectAPIName, String listViewName
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.02.2025 / Sovantheany Dim / US-0016318 - 9.1 - Seller Portal - My Subsidized Deal Contract Agreements Page
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=true) 
    public static Map<String, Object> fetchActionMetadata(String objectAPIName, String listViewName){
        Map<String, Object> mResult = new Map<String,Object>();
        String soqlMDT = 'select DeveloperName,Action_Label__c,  List_View_Name__c, Object_API_Name__c,Action_Condition__c,Url__c from Seller_Portal_Action_Mapping__mdt where Object_API_Name__c =: objectAPIName';
        for(Seller_Portal_Action_Mapping__mdt mdta : (List<Seller_Portal_Action_Mapping__mdt>) ApexSafe.query().secCheck(false).doQuery(soqlMDT,new Map<String, Object> {'objectAPIName' => objectAPIName})){
            if (String.isNotBlank(mdta.List_View_Name__c) && mdta.List_View_Name__c.contains(listViewName)) {
                mResult.put(mdta.DeveloperName,mdta);
            }
        }
        return mResult;
    }

}