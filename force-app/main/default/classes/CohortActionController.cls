/*********************************************************************************************************************************@ Class:          CohortActionController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0014345 - Cohort Activation Process Part 1
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  07.11.2023 / Sophal Noch / Created the class.
                :  09.11.2023 / Sophal Noch / US-0014361 - Cohort Activation Process Part 2
                :  15.11.2023 / Sophal Noch / US-0014353 - Cohort Deactivation Process
                :  30.11.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
                :  01.12.2023 / Sophal Noch / US-0014363 - Ph 1 - Deactivate Sellers button
                :  09.01.2024 / Sophal Noch / US-0014658 - Cohort Activation Flow failing
                :  30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
                :  14.03.2024 / Sovantheany Dim / US-0014804 - Allow Activate the Seller in the Cohort those are currently Inactive
                :  28.03.2024 / Sophal Noch / US-0015011 - 1 PT for US - Enable Cohort Invitation Process
                :  18.04.2024 / Sophal Noch / US-0015035 - We need to allow the Deactivation of the Pro-Trader Seller in part of subscribe request for any Status that is not Active
                :  22.04.2024 / Sovantheany Dim / US-0015106 - Retire Managed Cohort - Retire the record type Managed Cohort and update the Record Type of LTTM
                :  14.05.2024 / Sophal Noch / US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
                :  04.11.2024 / Vimean Heng / US-0015981 - Conflict Screen should show the Conflicted Cohort Seller Number with Hyperlink and Owner field
                :  10.03.2025 / Vimean Heng / US-0016616 - 3. Eliminate manual BOB category selection validation for Activating the PT Cohort
----------------------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************************/
public with sharing class CohortActionController {

    private static final String CLASS_NAME = 'CohortActionController';

    private final static String BOB_ACTIVE_STATUS = 'BoB Active';
    private final static String BOB_INACTIVE_STATUS = 'BoB Inactive';

    private final static Set<String> SET_BOB_STATUS = new Set<String>{ BOB_ACTIVE_STATUS, BOB_INACTIVE_STATUS};

    // 14.05.2024 / Sophal Noch / US-0015200 :
    private final static String BOB_MNG_TYPE_PRO_TRADER = 'LTTM Managed';
    private final static String BOB_MNG_SGM_PRO_TRADER_CAT = 'Pro-Trader Cat';  

    // @testVisible
    // private static Integer COHORT_ACTION_SYNC_LIMIT = String.isNotBlank(Label.Cohort_Action_Sync_Limit) ? Integer.valueOf(Label.Cohort_Action_Sync_Limit) : -1;
    
    @testVisible
    private static Integer UPDATE_COHORT_SELLER_CHUNK_LIMIT = String.isNotBlank(Label.Update_Cohort_Seller_Chunk_Limit) ? Integer.valueOf(Label.Update_Cohort_Seller_Chunk_Limit) : 2000;

    private final static Set<String> SET_BS_REQ_SOQL_FLD = new Set<String>{
        'Id',
        'Name',
        'BoB__c',
        'Status__c',
        'Conflict_Reason__c',
        'Invite_Seller__c',
        'Deactivation_Reason__c',
        'BoB__r.RecordTypeId', // 14.05.2024 / Sophal Noch / US-0015200
        'BoB__r.RecordType.DeveloperName',
        'BoB__r.Managed_Type__c',
        'BoB__r.Managed_Segment__c', // 14.05.2024 / Sophal Noch / US-0015200
        'BoB__r.EBH_BOBCNTRY__c', 
        'Seller__c',
        'Seller__r.Name',
        'Managed_Type__c',
        'Account_Manager__c'
    };

    private final static String BS_DEACT_COHORT_INACTIVE = 'Cohort Inactivated';

    private final static String BS_STATUS_CONFLICTED = 'Conflicted';
    private final static String BS_STATUS_INVITED = 'Invited';
    private final static String BS_STATUS_ACTIVE = 'Draft';
    private final static String BS_STATUS_INACTIVE = 'Inactive';
    private final static String BS_STATUS_REMOVED = 'Removed';
    private final static String BS_STATUS_NEW = 'New';

    public final static Map<String, String> MAP_COUNTRY_KEY_TO_DOMAIN{ // 28.03.2024 / Sophal Noch / US-0015011
        get{
            if(MAP_COUNTRY_KEY_TO_DOMAIN == null){
                Map<String, String> mapCtrToDomain = new Map<String, String>();
                for(Cohort_Country_To_Domain_Mapping__mdt cntrMapping : Cohort_Country_To_Domain_Mapping__mdt.getAll().values()){
                    if(cntrMapping.Is_Active__c){
                        mapCtrToDomain.put(cntrMapping.Country_Key__c, cntrMapping.Domain_Name__c);
                    }
                }
                MAP_COUNTRY_KEY_TO_DOMAIN = mapCtrToDomain;
            }
            return MAP_COUNTRY_KEY_TO_DOMAIN;
        }set;
    }
    private final static Set<String> SET_PRO_TRADER_COUNTRY = MAP_COUNTRY_KEY_TO_DOMAIN.keySet(); // 28.03.2024 / Sophal Noch / US-0015011 : move from hard code to custom metadata

    private final static Set<String> SET_BS_BEGIN_STATUS = new Set<String>{
        BS_STATUS_NEW,
        BS_STATUS_CONFLICTED,
        BS_STATUS_INACTIVE//TH:US-0014804:expand Activation for the Inactive Sellers
    };

    private final static Set<String> SET_BS_INACTIVE_STATUS = new Set<String>{
        BS_STATUS_INACTIVE, 
        BS_STATUS_REMOVED
    };

    private static final String SOQL_BOB = 'Select Id, Status__c, Managed_Type__c, Managed_Segment__c, EBH_BOBCNTRY__c, RecordTypeId, RecordType.DeveloperName From BoB__c Where Id =: bobId Limit 1'; // 14.05.2024 / Sophal Noch / US-0015200

    private static final String BOB_ADS_RECORDTYPE = 'Advertising_Cohort';
    private static final String BOB_LTTM_RECORDTYPE = 'Light_Touch_Category_Cohort';
    private static final Id BOB_LTTM_RTYPE_ID = ApexUtil.getRecordTypeByName('BOB__c', BOB_LTTM_RECORDTYPE).Id; // 14.05.2024 / Sophal Noch / US-0015200
    //private static final String BOB_MANAGED_RECORDTYPE = 'Managed_Cohort';//TH: US-0015106:comment out
    private static final Set<String> SET_BOB_RTYPES = new Set<String>{BOB_LTTM_RECORDTYPE};//TH: US-0015106:remove BOB_MANAGED_RECORDTYPE
    private static final Set<Id> SET_BOB_RTYPES_ALLOW_PROTRADER = new Set<Id>{BOB_LTTM_RTYPE_ID}; // 14.05.2024 / Sophal Noch / US-0015200 : change from RecordType.DeveloperName to RecordTypeId 
   

    private static final Map<String,String> MAP_STATUS_TO_OPT_DESC = new Map<String,String>{

        // lttm cohort
        // non lttm pro-trader :
        'false_'+ BOB_LTTM_RECORDTYPE + '_' + BOB_ACTIVE_STATUS  => Label.Cohort_Active_Description,
        'false_'+ BOB_LTTM_RECORDTYPE + '_' + BOB_INACTIVE_STATUS  => Label.Cohort_Inactive_Description,
        // lttm pro-trader :
        'true_' + BOB_LTTM_RECORDTYPE + '_' + BOB_ACTIVE_STATUS  => Label.ProTrader_Cohort_Active_Description,
        'true_' + BOB_LTTM_RECORDTYPE + '_' + BOB_INACTIVE_STATUS  => Label.ProTrader_Cohort_Inactive_Description,

        // ads cohort 
        // non ads pro-trader :
        'false_'+ BOB_ADS_RECORDTYPE + '_' + BOB_ACTIVE_STATUS  => Label.Ads_Cohort_Active_Description,
        'false_'+ BOB_ADS_RECORDTYPE + '_' + BOB_INACTIVE_STATUS  => Label.Ads_Cohort_Inactive_Description,
        // lttm ads pro-trader :
        'true_' + BOB_ADS_RECORDTYPE + '_' + BOB_ACTIVE_STATUS  => Label.ProTrader_Cohort_Active_Description,
        'true_' + BOB_ADS_RECORDTYPE + '_' + BOB_INACTIVE_STATUS  => Label.Ads_Cohort_Inactive_Description

    };

    private static final String CONTR_STATUS_EXECUTED = 'Executed';
    private static final Set<String> SET_CONTR_RTYPES = new Set<String>{'EBH_ACP','EBH_ListingAgreement'};

    private static final String SUB_REQ_STATUS_SUBSCRIBED = 'Subscribed';

    private static String ERROR_MSG = '{0} {1}';

    private static final String PERM_BOB_CATE_LEAD = 'BoB_Category_Lead';
    private static final String PERM_ADS_COHORT_LEAD = 'Advertising_Cohort_Lead';

    private static final String BATCH_JOB_TYPE = 'BatchApex';
    private static final String BATCH_NAME = 'BatchCohortAction';

    private static final Feature_Switch__c FEATURE_SWITCH = Feature_Switch__c.getInstance(); // 11.12.2023 / Sophal Noch / US-0014362 : for bypass AM validation
    
    /*********************************************************************************************************************************
    @ Method:         getBobWithId
    @ Author:         Sophal Noch
    @ Purpose:        US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  14.05.2024 / Sophal Noch / Created the Method.
    *********************************************************************************************************************************/
    public static BoB__c getBobWithId(String bobId){ 
        // create reusable method to query bob that is related to cohort activation or deactivation
        List<BoB__c> listBoB = (List<BoB__c>)ApexSafe.query().secCheck(false).doQuery(SOQL_BOB,new Map<String, Object> {'bobId' => bobId});
        return !listBoB.isEmpty() ? listBoB[0] : null;
    }

    /*********************************************************************************************************************************
    @ Method:         getBobSelerId
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014345 - Cohort Activation Process Part 1
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.11.2023 / Sophal Noch / Created the method.
                    :  30.11.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
                    :  14.05.2024 / Sophal Noch / US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> getBobSellerId(String bobId, Boolean fromCohort) {
        Map<String, Object> mapResult = new Map<String, Object>{'status'=> 'ok'};
        try{

            Boolean isBatchRunning = getBatchIsRunning();
            if(isBatchRunning){ mapResult.put('isBatchRunning', isBatchRunning); return mapResult;}

            BoB__c bob = getBobWithId(bobId); // 14.05.2024 / Sophal Noch / US-0015200 : change query to reusable method to retrieve bob
            Boolean isProTrader = isProTrader(bob);
            List<Map<String,String>> listStatusOpt = new List<Map<String,String>>();
            
            if(fromCohort){ // 30.11.2023 / Sophal Noch / US-0014362 : it is only null when click on update cohort seller

                Schema.DescribeFieldResult fieldResult = BoB__c.Status__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for( Schema.PicklistEntry pickListVal : ple){
                    if(SET_BOB_STATUS.contains(pickListVal.getValue()) && pickListVal.getValue() != bob.Status__c){
                        Map<String,String> opt = new Map<String,String>();
                        opt.put('label', pickListVal.getLabel());
                        opt.put('value', pickListVal.getValue());
                        opt.put('desc', MAP_STATUS_TO_OPT_DESC.get(isProTrader + '_' + bob.RecordType.DeveloperName + '_' + pickListVal.getValue()));
                        listStatusOpt.add(opt);
                    }
                }

                mapResult.put('listStatusOpt', listStatusOpt);
            }
           
            mapResult.put('isCohortActive', bob.Status__c == BOB_ACTIVE_STATUS);
            mapResult.put('isBatchRunning', isBatchRunning);
            mapResult.put('isAds', bob.RecordType.DeveloperName == BOB_ADS_RECORDTYPE);
            mapResult.put('isLttm', bob.RecordType.DeveloperName == BOB_LTTM_RECORDTYPE);
            mapResult.put('isProTrader', isProTrader);
            mapResult.put('bob', bob);
        
        }catch(Exception e){mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         validateBeforeActivate
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.11.2023 / Sophal Noch / Created the method.
    @               :  14.05.2024 / Sophal Noch / US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
    @               :  10.03.2025 / Vimean Heng / US-0016616 - 3. Eliminate manual BOB category selection validation for Activating the PT Cohort
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> validateBeforeActivate(String bobId) {
        // validate before active cohort
        Map<String, Object> mapResult = new Map<String, Object>{'status'=> 'ok'};
        try{
            Boolean isErrorBeforeActivate = false;
            BoB__c bob = getBobWithId(bobId);
            if(bob?.Managed_Type__c == BOB_MNG_TYPE_PRO_TRADER && SET_BOB_RTYPES_ALLOW_PROTRADER.contains(bob?.RecordTypeId)){ // 14.05.2024 / Sophal Noch / US-0015200 
                isErrorBeforeActivate = ApexSafe.query().doQuery('Select Id From Action__c Where LTTM_Seller__c IN (Select Id From BoB_Seller__c Where BoB__c =: bobId) Limit 1',new Map<String,Object>{'bobId' => bobId}).isEmpty();
                //isErrorBeforeActivate = [Select Id From Action__c Where LTTM_Seller__c IN (Select Id From BoB_Seller__c Where BoB__c =: bobId) Limit 1].isEmpty();
                //VM : US-0016616 - no require BOB category for PT Cohort
                /*
                if(CohortActionController.isProTrader(bob)){ // 14.05.2024 / Sophal Noch / US-0015200 : reuse method to check whether bob is protrader or not
                    isErrorBeforeActivate = isErrorBeforeActivate ? isErrorBeforeActivate : [Select Id From BoB_Category__c Where BoB__c =: bobId Limit 1].isEmpty();
                }
                */
            }
            mapResult.put('isErrorBeforeActivate', isErrorBeforeActivate);
           
        }catch(Exception e){mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         getBobSellerToActivate
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014345 - Cohort Activation Process Part 1
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.11.2023 / Sophal Noch / Created the method.
                    :  11.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
                    :  09.01.2024 / Sophal Noch / US-0014658 - Cohort Activation Flow failing
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> getBobSellerToActivate(String bobId, List<String> listBsId, Boolean isInvitedToActive) {

        Map<String, Object> mapResult = new Map<String, Object>();
        try{

            Set<String> setFldApiName =  new Set<String>();
            Map<String, Columns> mapColumn = new Map<String,Columns>();
            // generate table column from fieldset for lwc lightning table :
            generateTableColumn(SObjectType.BoB_Seller__c.FieldSets.CohortSeller_To_Be_Activated_Column.getFields(), setFldApiName, mapColumn); 

            Map<Id, BoB_Seller__c>  mapBsToActivate = new Map<Id, BoB_Seller__c>();

            Map<String, String> mapBsIdToError = new Map<String, String>();
            Map<String, String> mapBsIdToConflicted = new Map<String, String>();

            Set<String> setBobId;
            Set<String> setBsId;
        
            if(bobId != null){ // 09.01.2024 / Sophal Noch / US-0014658 : if bobId is not null, it is cohort activation. otherwise, it is cohort seller activation
                setBobId = new Set<String>{bobId};
            }else{
                setBsId = new Set<String>(listBsId);
            }
            
            // query cohort seller to activate and check if there is any conflicted or error
            queryBobSellerToActivate(setFldApiName, mapBsToActivate, setBobId, setBsId,  mapBsIdToError, mapBsIdToConflicted, isInvitedToActive);

            List<String> listBsToActivateId = new List<String>();
            for(Id bsId : mapBsToActivate.keySet()){
                listBsToActivateId.add(bsId);
            }
            Map<String, Object> chunkListBsId = ApexUtil.chunkList(listBsToActivateId, UPDATE_COHORT_SELLER_CHUNK_LIMIT);

            mapResult.put('chunkListBsId', chunkListBsId);
            mapResult.put('chunkRowLimit', UPDATE_COHORT_SELLER_CHUNK_LIMIT);
            mapResult.put('listToActivateColumn', mapColumn.values());
            mapResult.put('listBsToActivate', mapBsToActivate.values());
            mapResult.put('mapBsIdToError', mapBsIdToError);
            mapResult.put('mapBsIdToConflicted', mapBsIdToConflicted);
            
           
            mapResult.put('status', 'ok');

        }catch(Exception e){mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}
 
        return mapResult;

    }
    
    /*********************************************************************************************************************************
    @ Method:         activateCohort
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014345 - Cohort Activation Process Part 1
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.11.2023 / Sophal Noch / Created the method.
                    :  09.11.2034 / Sophal Noch / US-0014361 - Cohort Activation Process Part 2
                    :  30.11.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    @AuraEnabled
    public static  Map<String, Object> activateCohort(String bobId){
        Savepoint sp = Database.setSavepoint();
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            BoB__c bob = new BoB__c(Id = bobId, Status__c = BOB_ACTIVE_STATUS);
            update bob;
            mapResult.put('status', 'ok');
        }catch(Exception e){Database.rollback(sp); mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         activateCohortSeller
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.11.2023 / Sophal Noch / Created the method.
                    :  11.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
                    :  09.01.2024 / Sophal Noch / US-0014658 - Cohort Activation Flow failing
    *********************************************************************************************************************************/
    @AuraEnabled
    public static  Map<String, Object> activateCohortSeller(String bobId, List<String> listBsId, Boolean isInvitedToActive){
        // method to active all cohort seller sync or async
        Savepoint sp = Database.setSavepoint();
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            activateBsToInviteOrActive(null, new Set<String>(listBsId), isInvitedToActive);
            mapResult.put('status', 'ok');
        }catch(Exception e){Database.rollback(sp); mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         runActivateCohortSellerBatch
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        09.01.2024 / Sophal Noch / US-0014658 - Cohort Activation Flow failing
    ----------------------------------------------------------------------------------------------------------------------------------
                    :  09.01.2024 / Sophal Noch / Created the method
    *********************************************************************************************************************************/
    @AuraEnabled
    public static  Map<String, Object> runActivateCohortSellerBatch(String bobId, List<String> listBsId){

        Savepoint sp = Database.setSavepoint();
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            if(bobId != null){ // run batch from cohort activation
                Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_ACTIVATE_COHORT_SELLER, 0, new Set<String>{bobId})); 
            }else{ // run batch from cohort seller activation
                Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_ACTIVATE_SELECTED_COHORT_SELLER, 0, new Set<String>(listBsId))); 
            }
            mapResult.put('status', 'ok');
        }catch(Exception e){Database.rollback(sp); mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}
       
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         queryBobSellerToActivate
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014345 - Cohort Activation Process Part 1
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.11.2023 / Sophal Noch / Created the method.
                    :  11.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
                    :  09.01.2024 / Sophal Noch / US-0014658 - Cohort Activation Flow failing
                    :  04.11.2024 / Vimean Heng / US-0015981 - Conflict Screen should show the Conflicted Cohort Seller Number with Hyperlink and Owner field
    *********************************************************************************************************************************/
    public static void queryBobSellerToActivate(Set<String> setFieldToQuery, Map<Id, BoB_Seller__c> mapBsToActivate,  Set<String> setBobId, Set<String> setBsId, Map<String, String> mapBsIdToError,  Map<String, Object> mapBsIdToConflicted, Boolean isInvitedToActive){
        
        // this method will be reused in batch

        if(setFieldToQuery == null){ setFieldToQuery = new Set<String>(); }
        setFieldToQuery.addAll(SET_BS_REQ_SOQL_FLD);

        Map<String,Object> mBsParam = new Map<String,Object>{'BOB_INACTIVE_STATUS' => BOB_INACTIVE_STATUS};    
        String whereCondition = ''; // 11.12.2023 / Sophal Noch / US-0014362
        if(setBobId != null){
            whereCondition =  'WHERE BoB__c IN: setBobId';
            mBsParam.put('setBobId', setBobId);
        }else{
            whereCondition =  'WHERE Id IN: setBsId';
            mBsParam.put('setBsId', setBsId);
        }

        // query cohort sellers to activate :
        if(mapBsToActivate.isEmpty()){
            Set<String> setBsBeginStatus = isInvitedToActive ? new Set<String>{BS_STATUS_INVITED} : SET_BS_BEGIN_STATUS.clone(); // 11.12.2023 / Sophal Noch / US-0014362 :if user click activste seller button from pro-trader cohort, we update invited to active 
            mBsParam.put('setBsBeginStatus', setBsBeginStatus);
            //for(BoB_Seller__c bs : Database.query('SELECT ' + String.join(new List<String>(setFieldToQuery), ',') + ' FROM BoB_Seller__c '+ whereCondition +' AND Seller__c != null AND BoB__c != null AND Status__c IN: setBsBeginStatus AND BoB__r.Status__c !=: BOB_INACTIVE_STATUS')){
            for(BoB_Seller__c bs : (BoB_Seller__c[]) ApexSafe.query().doQuery('SELECT ' + String.join(new List<String>(setFieldToQuery), ',') + ' FROM BoB_Seller__c '+ whereCondition +' AND Seller__c != null AND BoB__c != null AND Status__c IN: setBsBeginStatus AND BoB__r.Status__c !=: BOB_INACTIVE_STATUS',mBsParam)){
                mapBsToActivate.put(bs.Id, bs);
            }
        }

        Set<String> setAccId = new Set<String>();
        Set<String> setAccMgr = new Set<String>();

        for(BoB_Seller__c bs : mapBsToActivate.values()){
            setAccId.add(bs.Seller__c);
            if(isProTrader(bs.BoB__r) && bs.Account_Manager__c != null){
                setAccMgr.add(bs.Account_Manager__c);
            }
        }

        Map<Id, User> mapUser = new Map<Id, User>();
        if(!setAccMgr.isEmpty()){
            // query user from that is account manager with calendly setup :
            //mapUser = new Map<Id, User>([Select Id From User Where Id IN: setAccMgr AND Calendly__CalendlyLink__c != null]);
            mapUser = new Map<Id,User>((User[]) ApexSafe.query().doQuery('Select Id From User Where Id IN: setAccMgr AND Calendly__CalendlyLink__c != null',new Map<String, Object>{'setAccMgr' => setAccMgr}));
        }

        Map<Id, Map<Id, BoB_Seller__c>> mapSellerToMapConflictedBs = new Map<Id, Map<Id, BoB_Seller__c>>();
        // query conflicted cohort seller :
        if(!setAccId.isEmpty()){
            Set<Id> setActiveBsId = mapBsToActivate.keySet(); //  11.12.2023 / Sophal Noch / US-0014362 
            Set<String> setBsInactiveStatus = SET_BS_INACTIVE_STATUS.clone();
            setBsInactiveStatus.addAll(new Set <String>{BS_STATUS_NEW, BS_STATUS_CONFLICTED}); // 09.01.2024 / Sophal Noch / US-0014658 : need to add status New and Conflict so it does not query to check conflict
            Map<String,Object> mBsConfParam = new Map<String,Object>{'setAccId' => setAccId,'setActiveBsId' => setActiveBsId,'setBsInactiveStatus' => setBsInactiveStatus,'BOB_INACTIVE_STATUS' => BOB_INACTIVE_STATUS};    
            //for(BoB_Seller__c bs : Database.query('SELECT ' + String.join(new List<String>(setFieldToQuery), ',') + ' FROM BoB_Seller__c WHERE Seller__c IN : setAccId AND Id NOT IN : setActiveBsId AND Status__c NOT IN: setBsInactiveStatus AND BoB__r.Status__c !=: BOB_INACTIVE_STATUS')){
            for(BoB_Seller__c bs : (BoB_Seller__c[]) ApexSafe.query().doQuery('SELECT ' + String.join(new List<String>(setFieldToQuery), ',') + ',Owner.Name,BoB__r.Name FROM BoB_Seller__c WHERE Seller__c IN : setAccId AND Id NOT IN : setActiveBsId AND Status__c NOT IN: setBsInactiveStatus AND BoB__r.Status__c !=: BOB_INACTIVE_STATUS',mBsConfParam)){
                Map<Id, BoB_Seller__c> mapConflictedBs = mapSellerToMapConflictedBs.get(bs.Seller__c);
                if(mapConflictedBs == null){
                    mapConflictedBs = new Map<Id, BoB_Seller__c>();
                    mapSellerToMapConflictedBs.put(bs.Seller__c, mapConflictedBs);
                }
                mapConflictedBs.put(bs.Id, bs);
            }
        }

        for(BoB_Seller__c bs : mapBsToActivate.values()){

            // get conflicted cohort seller by seller__c field :
            Map<Id, BoB_Seller__c> mapConflictedBs = mapSellerToMapConflictedBs.get(bs.Seller__c);
    
            if(mapConflictedBs != null){
                List<String> listConflictedBs = new List<String>();
                BoB_Seller__c bobSellerConflict = null;
                for(BoB_Seller__c conflictedBs : mapConflictedBs.values()){

                    if(conflictedBs.BoB__c == null){ continue; }

                     // skip if cohort seller to be activated is lttm or managed and conflicted cohort seller is advertising and vice versa :
                    if((SET_BOB_RTYPES.contains(conflictedBs.BoB__r.RecordType.DeveloperName) && bs.BoB__r.RecordType.DeveloperName == BOB_ADS_RECORDTYPE) || (SET_BOB_RTYPES.contains(bs.BoB__r.RecordType.DeveloperName) && conflictedBs.BoB__r.RecordType.DeveloperName == BOB_ADS_RECORDTYPE)){ continue; }
                    listConflictedBs.add(conflictedBs.Name);
                    bobSellerConflict = conflictedBs;
                }
                mapConflictedBs.put(bs.Id, bs);

                if(!listConflictedBs.isEmpty()){
                    // store conficted message
                    String cohortName = String.isNotBlank(bobSellerConflict.BoB__r.Name) ?  bobSellerConflict.BoB__r.Name : '';
                    String sellerConflictHTML = Label.Cohort_Seller_Conflict_HTML;
                    String conflictedMsg = Label.Conflicted_With + String.join(listConflictedBs, ', ') + ' ' + bobSellerConflict.Owner.Name + ' ' + cohortName;
                    mapBsIdToConflicted.put(bs.Id, conflictedMsg);
                    sellerConflictHTML = sellerConflictHTML.replace('{0}', Label.Conflicted_With);
                    sellerConflictHTML = sellerConflictHTML.replace('{1}', String.join(listConflictedBs, ', '));
                    sellerConflictHTML = sellerConflictHTML.replace('{2}', bobSellerConflict.Owner.Name);
                    sellerConflictHTML = sellerConflictHTML.replace('{3}', cohortName);
                    sellerConflictHTML = sellerConflictHTML.replace('{recordId}',bobSellerConflict.Id);
                    sellerConflictHTML = sellerConflictHTML.replace('{bobId}',bobSellerConflict.BoB__c);
                    mapBsIdToConflicted.put(bs.Id + '_Link', sellerConflictHTML);
                }
            
            }
           

            if(isProTrader(bs.BoB__r)){

                if(bs.Account_Manager__c == null){
                    if(!FEATURE_SWITCH.Bypass_Required_Field_AM__c){ //  11.12.2023 / Sophal Noch / US-0014362 : bypass if true
                        mapBsIdToError.put(bs.Id, Label.Required_Field_AM);
                    }
                }else if(!mapUser.containsKey(bs.Account_Manager__c)){
                    if(!FEATURE_SWITCH.Bypass_Invalid_AM_Calendly__c){ //  11.12.2023 / Sophal Noch / US-0014362 : bypass if true
                        // store calendly configuration error message
                        mapBsIdToError.put(bs.Id, Label.Invalid_AM_Calendly);
                    }
                }

            }

            if(mapConflictedBs == null){
                // store conhort seller in case any cohort sellers to be activated has the same seller :
                mapConflictedBs = new Map<Id, BoB_Seller__c>{bs.Id => bs};
                mapSellerToMapConflictedBs.put(bs.Seller__c, mapConflictedBs);
            }

        }


    }

    
    private static void activateBsToInviteOrActive(Set<String> setBobId, Set<String> setBsId, Boolean isInvitedToActive){
        // 09.01.2024 / Sophal Noch / US-0014658  : change method name

        //11.12.2023 / Sophal Noch / US-0014362 : updating status to active or invite must be sync

        Map<Id, BoB_Seller__c> mapBobSeller = new  Map<Id, BoB_Seller__c>();
        Map<String, String> mapBsIdToError = new Map<String, String>();
        Map<String, String> mapBsIdToConflicted = new Map<String, String>();

        queryBobSellerToActivate(null, mapBobSeller, setBobId, setBsId, mapBsIdToError, mapBsIdToConflicted, isInvitedToActive);

        List<String> listError = new List<String>();

        List<BoB_Seller__c> listBsToUpdate = new List<BoB_Seller__c>();
        for(BoB_Seller__c bs : mapBobSeller.values()){

            String oldStatus = bs.Status__c;
            String oldConflictReason = bs.Conflict_Reason__c;
            Boolean oldInviteSeller = bs.Invite_Seller__c;

            List<String> listConflictReason = new List<String>();
            if(mapBsIdToConflicted.containsKey(bs.Id)){
                listConflictReason.add(mapBsIdToConflicted.get(bs.Id));
            }
            if(mapBsIdToError.containsKey(bs.Id)){
                listConflictReason.add(mapBsIdToError.get(bs.Id));
            }

            if(!listConflictReason.isEmpty()){
                bs.Conflict_Reason__c = String.join(listConflictReason, ', ');
                bs.Status__c = BS_STATUS_CONFLICTED;
            }else{
                bs.Conflict_Reason__c = null;
                if(CohortActionController.isProTrader(bs.BoB__r) && !isInvitedToActive){
                    bs.Status__c = BS_STATUS_INVITED;
                    bs.Invite_Seller__c = true;
                }else{
                    bs.Status__c = BS_STATUS_ACTIVE;
                }
            }

            if(oldStatus != bs.Status__c || oldConflictReason != bs.Conflict_Reason__c || oldInviteSeller != bs.Invite_Seller__c){
                listBsToUpdate.add(bs);
            }
            
        }

        if(!listBsToUpdate.isEmpty()){
            updateCohortSellerStatus(listBsToUpdate, 'activateBsToInviteOrActive');
        }

    }

    /*********************************************************************************************************************************
    @ Method:         getBobSellerToDeactivate
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0014353 - Cohort Deactivation Process
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.11.2023 / Sophal Noch / Created the method.
                    :  09.01.2024 / Sophal Noch / US-0014658 - Cohort Activation Flow failing
                    :  30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> getBobSellerToDeactivate(String bobId, List<String> listBsId, Boolean isToDelete) {

        Map<String, Object> mapResult = new Map<String, Object>();
        try{

            Set<String> setFldApiName =  new Set<String>();
            Map<String, Columns> mapColumn = new Map<String,Columns>();
            // generate table column from fieldset for lwc lightning table :
            generateTableColumn(SObjectType.BoB_Seller__c.FieldSets.CohortSeller_To_Be_Deactivate_Column.getFields(), setFldApiName, mapColumn); 

            Map<Id, BoB_Seller__c>  mapBsToDeactivate = new Map<Id, BoB_Seller__c>();

            Map<String, String> mapBsIdToError = new Map<String, String>();

            Set<String> setBobId;
            Set<String> setBsId;
        
            if(bobId != null){ // 09.01.2024 / Sophal Noch / US-0014658 : if bobId is not null, it is cohort deactivation. otherwise, it is cohort seller deactivation
                setBobId = new Set<String>{bobId};
            }else{
                setBsId = new Set<String>(listBsId);
            }
            
            // query cohort seller to deactivate and check if there is any error, 30.01.2024 / Sophal Noch / US-0014277 : add flag isToDelete 
            queryBobSellerToDeactivate(setFldApiName, mapBsToDeactivate, setBobId, setBsId, mapBsIdToError, isToDelete);

            List<String> listBsToDeactivateId = new List<String>();
            for(Id bsId : mapBsToDeactivate.keySet()){
                listBsToDeactivateId.add(bsId);
            }
            Map<String, Object> chunkListBsId = ApexUtil.chunkList(listBsToDeactivateId, UPDATE_COHORT_SELLER_CHUNK_LIMIT);

            mapResult.put('chunkListBsId', chunkListBsId);
            mapResult.put('chunkRowLimit', UPDATE_COHORT_SELLER_CHUNK_LIMIT);
            mapResult.put('listToDeactivateColumn', mapColumn.values());
            mapResult.put('listBsToDeactivate', mapBsToDeactivate.values());
            mapResult.put('mapBsIdToError', mapBsIdToError);
            
           
            mapResult.put('status', 'ok');

        }catch(Exception e){mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}
 
        return mapResult;

    }

    /*********************************************************************************************************************************
    @ Method:         deactivateCohort
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014353 - Cohort Deactivation Process
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.11.2023 / Sophal Noch / Created the method.
                    :  11.12.2023 / Sophal Noch /  US-0014363 - Ph 1 - Deactivate Sellers button
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    @AuraEnabled
    public static  Map<String, Object> deactivateCohort(String bobId, List<String> listBsId){
        Savepoint sp = Database.setSavepoint();
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            deactivateBsToInactive(null, new Set<String>(listBsId));
            mapResult.put('status', 'ok');
        }catch(Exception e){Database.rollback(sp); mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         deactivateCohortWhenNoCs
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014353 - Cohort Deactivation Process
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.11.2023 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    @AuraEnabled
    public static  Map<String, Object> deactivateCohortWhenNoCs(String bobId){
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            update new BoB__c(Id = bobId, Status__c = BOB_INACTIVE_STATUS);
            mapResult.put('status', 'ok');
        }catch(Exception e){mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}
        return mapResult;
    }
    /*********************************************************************************************************************************
    @ Method:         runDeactivateCohortSellerBatch
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        09.01.2024 / Sophal Noch / US-0014658 - Cohort Activation Flow failing
    ----------------------------------------------------------------------------------------------------------------------------------
                    :  09.01.2024 / Sophal Noch / Created the method
    *********************************************************************************************************************************/
    @AuraEnabled
    public static  Map<String, Object> runDeactivateCohortSellerBatch(String bobId, List<String> listBsId){
        Savepoint sp = Database.setSavepoint();
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            if(bobId != null){
                Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_DEACTIVATE_COHORT_SELLER, 0, new Set<String>{bobId})); 
            }else{
                Database.executeBatch(new BatchCohortAction(BatchCohortAction.ACTION_DEACTIVATE_SELECTED_COHORT_SELLER, 0, new Set<String>(listBsId))); 
            }
            mapResult.put('status', 'ok');
        }catch(Exception e){Database.rollback(sp); mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}
       
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         queryBobSellerToDeactivate
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014353 - Cohort Deactivation Process
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.11.2023 / Sophal Noch / Created the method.
                    :  18.04.2024 / Sophal Noch / US-0015035 - We need to allow the Deactivation of the Pro-Trader Seller in part of subscribe request for any Status that is not Active
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    public static void queryBobSellerToDeactivate(Set<String> setFieldToQuery, Map<Id, BoB_Seller__c> mapBsToDeactivate, Set<String> setBobId , Set<String> setBsId, Map<String, String> mapBsIdToError, Boolean isToDelete){
        
        // this method will be reused in batch

        if(setFieldToQuery == null){ setFieldToQuery = new Set<String>(); }
        setFieldToQuery.addAll(SET_BS_REQ_SOQL_FLD);


        String whereCondition = '';
        if(setBobId != null){
            whereCondition =  'WHERE BoB__c IN: setBobId';
        }else{
            whereCondition =  'WHERE Id IN: setBsId';
        }

        // 30.01.2024 / Sophal Noch / US-0014277 : add flag isToDelete to check whether it is for deactivate or delete cohort seller
        if(!isToDelete){
            whereCondition += ' AND Status__c NOT IN:SET_BS_INACTIVE_STATUS';
        }else{
            whereCondition += ' AND Status__c IN:SET_BS_INACTIVE_STATUS';
        }

        // query cohort sellers to deactivate :
        if(mapBsToDeactivate.isEmpty()){
            for(BoB_Seller__c bs : Database.query('SELECT ' + String.join(new List<String>(setFieldToQuery), ',') + ' FROM BoB_Seller__c '+ whereCondition +' And Seller__c != null AND BoB__c != null')){
                mapBsToDeactivate.put(bs.Id, bs);
            }
        }

        if(!isToDelete){ // 30.01.2024 / Sophal Noch / US-0014277 : no need to run validate when delete cohort seller
            
            Set<String> setAccId = new Set<String>();

            for(BoB_Seller__c bs : mapBsToDeactivate.values()){
                setAccId.add(bs.Seller__c);
            }
    
            // get active contract from contract seller that lookup to seller
    
            Map<Id, List<EBH_ContractSeller__c>> mapSellerToListContrSeller = new Map<Id, List<EBH_ContractSeller__c>>();
            if(!setAccId.isEmpty()){
                for(EBH_ContractSeller__c  contrSeller : [Select Id, Name, EBH_BusinessName__c, EBH_ContractNumber__r.ContractNumber From EBH_ContractSeller__c Where EBH_BusinessName__c IN: setAccId AND EBH_ContractNumber__r.Status =:CONTR_STATUS_EXECUTED AND EBH_ContractNumber__r.RecordType.DeveloperName IN: SET_CONTR_RTYPES]){
                    List<EBH_ContractSeller__c> listContrSeller = mapSellerToListContrSeller.get(contrSeller.EBH_BusinessName__c);
                    if(listContrSeller == null){
                        listContrSeller = new List<EBH_ContractSeller__c>();
                        mapSellerToListContrSeller.put(contrSeller.EBH_BusinessName__c, listContrSeller);
                    }
                    listContrSeller.add(contrSeller);
                }
            }
    
    
            // get subscription request that lookup to seller
            Map<Id, List<Subscription_Request__c>> mapSellerToListSubReq = new Map<Id, List<Subscription_Request__c>>();
            if(!setAccId.isEmpty()){
                for(Subscription_Request__c  subReq : [Select Id, Name, Seller__c From Subscription_Request__c Where Seller__c IN: setAccId AND Status__c =:SUB_REQ_STATUS_SUBSCRIBED]){
                    List<Subscription_Request__c> listSubReq = mapSellerToListSubReq.get(subReq.Seller__c);
                    if(listSubReq == null){
                        listSubReq = new List<Subscription_Request__c>();
                        mapSellerToListSubReq.put(subReq.Seller__c, listSubReq);
                    }
                    listSubReq.add(subReq);
                }
            }
    
            for(BoB_Seller__c bs : mapBsToDeactivate.values()){

                if(bs.BoB__r.RecordType.DeveloperName == BOB_ADS_RECORDTYPE || bs.Status__c != BS_STATUS_ACTIVE){ // 18.04.2024 / Sophal Noch / US-0015035
                    continue;
                }
    
                List<EBH_ContractSeller__c> listContrSeller = mapSellerToListContrSeller.get(bs.Seller__c);
                List<Subscription_Request__c> listSubReq = mapSellerToListSubReq.get(bs.Seller__c);
                List<String> listError = new List<String>();
                if(listContrSeller != null){ // can not deactivate if seller is related to active contract
    
                    Set<String> setErrorContrSeller = new Set<String>();
                    for(EBH_ContractSeller__c contrSeller : listContrSeller){
                        setErrorContrSeller.add(contrSeller.EBH_ContractNumber__r.ContractNumber);
                    }
                    List<String> listErrorContrSeller = new List<String>(setErrorContrSeller);
                    listError.add(String.format(ERROR_MSG, new List<String>{Label.Active_Contract_With, String.join(listErrorContrSeller, ', ')}));
                }
    
                if(listSubReq != null){ // can not deactivate if seller is related subscription request with status = subscribed 
    
                    List<String> listErrorSubReq = new List<String>();
                    for(Subscription_Request__c subReq : listSubReq){
                        listErrorSubReq.add(subReq.Name);
                    }
                    listError.add(String.format(ERROR_MSG, new List<String>{Label.Subscribed_With, String.join(listErrorSubReq, ', ')}));
                }
    
                if(!listError.isEmpty()){ mapBsIdToError.put(bs.Id, String.join(listError, '. ')); }
    
                
            }
        }

    }

    private static void deactivateBsToInactive(Set<String> setBobId, Set<String> setBsId){
         // 09.01.2024 / Sophal Noch / US-0014658  : change method name

        // 11.12.2023 / Sophal Noch /  US-0014363 : updating status to inactive must be sync

        // update status to inactive
        Map<Id, BoB_Seller__c> mapBobSeller = new  Map<Id, BoB_Seller__c>();
        Map<String, String> mapBsIdToError = new Map<String, String>();

        queryBobSellerToDeactivate(null, mapBobSeller, setBobId, setBsId, mapBsIdToError, false);

        List<String> listError = new List<String>();

        List<BoB_Seller__c> listBsToUpdate = new List<BoB_Seller__c>();
        for(BoB_Seller__c bs : mapBobSeller.values()){

            String oldStatus = bs.Status__c;
            String oldConflictReason = bs.Conflict_Reason__c;
            String oldDeactivateReason = bs.Deactivation_Reason__c;

            if(mapBsIdToError.containsKey(bs.Id)){
                bs.Conflict_Reason__c = mapBsIdToError.get(bs.Id);
                // listError.add(bs.Conflict_Reason__c);
            }else{
                bs.Conflict_Reason__c = null;
                bs.Status__c = BS_STATUS_INACTIVE;
                bs.Deactivation_Reason__c = (bs.Deactivation_Reason__c != null ? bs.Deactivation_Reason__c : BS_DEACT_COHORT_INACTIVE);
            }

            if(oldStatus != bs.Status__c || oldConflictReason != bs.Conflict_Reason__c || oldDeactivateReason != bs.Deactivation_Reason__c){
                listBsToUpdate.add(bs);
            }
            
        }

        if(!listBsToUpdate.isEmpty()){
            updateCohortSellerStatus(listBsToUpdate, 'deactivateBsToInactive');
        }

    }

    private static void updateCohortSellerStatus(List<BoB_Seller__c> listBsToUpdate, String methodName){

        Map<Id, BoB_Seller__c> mapBobSellerToUpdate = new Map<Id, BoB_Seller__c>();
        for(BoB_Seller__c bs : listBsToUpdate){
            mapBobSellerToUpdate.put(bs.Id, bs);
        }

        // update bob seller status
        List<CohortActionControllerException> listException = new List<CohortActionControllerException>();

        if(!mapBobSellerToUpdate.isEmpty()){
            BatchCohortAction.isRunning = true;
            for(Database.SaveResult sr : Database.Update(mapBobSellerToUpdate.values(), false)){
                if(!sr.isSuccess()){
                    CohortActionControllerException e = new CohortActionControllerException((mapBobSellerToUpdate.get(sr.getId()).Name + '_' + sr.getErrors()[0].getMessage()));
                    listException.add(e);
                }
            }
        }
        if(!listException.isEmpty()){
            // EBH_ApexLogger.logError(listException, CLASS_NAME, 'updateCohortSellerStatus');
            EBH_ApexLogger.logError(listException, CLASS_NAME, methodName);
        }

    }

    /*********************************************************************************************************************************
    @ Method:         deleteCohortSeller
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014277 - Unable to delete Cohort Seller record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.01.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    @AuraEnabled
    public static  Map<String, Object> deleteCohortSeller(List<String> listBsId){
        Savepoint sp = Database.setSavepoint();
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            
            Set<String> setBsId = new Set<String>();
            if(listBsId != null){
                setBsId.addAll(listBsId);
            }
            Map<Id, BoB_Seller__c> mapBobSellerToDelete = new  Map<Id, BoB_Seller__c>();
            queryBobSellerToDeactivate(null, mapBobSellerToDelete, null, setBsId, null, true);

            if(!mapBobSellerToDelete.isEmpty()){
                List<CohortActionControllerException> listException = new List<CohortActionControllerException>();
                BatchCohortAction.isRunning = true;

                Boolean hasBobPerm = FeatureManagement.checkPermission(PERM_BOB_CATE_LEAD);
                Boolean hasAdsPerm = FeatureManagement.checkPermission(PERM_ADS_COHORT_LEAD);
                List<Database.DeleteResult> listDeleteResult;
                if(hasBobPerm || hasAdsPerm){
                    listDeleteResult =  WithoutSharing.doDelete(mapBobSellerToDelete.values(), false);
                }else{
                    listDeleteResult =  Database.Delete(mapBobSellerToDelete.values(), false);
                }
                for(Database.DeleteResult sr : listDeleteResult){
                    if(!sr.isSuccess()){
                        CohortActionControllerException e = new CohortActionControllerException((mapBobSellerToDelete.get(sr.getId()).Name + '_' + sr.getErrors()[0].getMessage()));
                        listException.add(e);
                    }
                }
                if(!listException.isEmpty()){
                    EBH_ApexLogger.logError(listException, CLASS_NAME, 'deleteCohortSeller');
                }
            }
            mapResult.put('status', 'ok');
        }catch(Exception e){Database.rollback(sp); mapResult.put('status', 'ko');mapResult.put('error', e.getMessage());}
        return mapResult;
    }

    private static void generateTableColumn(List<Schema.FieldSetMember> fieldSetMember, Set<String> setFldApiName, Map<String, Columns> mapColumn){

        for(Schema.FieldSetMember f: fieldSetMember){

            String label = f.getLabel();
            String fieldName = f.getFieldPath();
            String type = f.getType()+'';

            setFldApiName.add(fieldName); 

            Columns col = new Columns(label, fieldName, type);
            mapColumn.put(col.fieldName, col);


            String lookupfApiName;
            if(fieldName.contains('__r.Name')){
                lookupfApiName = fieldName.replace('__r.Name', '__c');
            }else if(fieldName.contains('.Name')){
                lookupfApiName = f.getFieldPath().replace('.Name', 'Id');
            }else if(fieldName == 'Name'){
                lookupfApiName = 'Id';
            }

            if(String.isNotBlank(lookupfApiName) && mapColumn.containsKey(lookupfApiName)){
                Columns lookupCol = mapColumn.get(lookupfApiName);
                col.makeFieldIntoLink(lookupCol.fieldName, lookupCol.label);
                mapColumn.remove(lookupfApiName);
            }
        }
    }

    /*********************************************************************************************************************************
    @ Method:         isProTrader
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014345 - Cohort Activation Process Part 1
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.11.2023 / Sophal Noch / Created the method.
                    :  14.05.2024 / Sophal Noch / 14.05.2024 / Sophal Noch / US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    public static Boolean isProTrader(BoB__c bob) {
        // 14.05.2024 / Sophal Noch / US-0015200 : add BOB__r.Managed_Segment__c == BS_PRO_TRADER_CAT to condition, and use BoB__c.RecordTypeId to check if it is pro-trader
        return bob.Managed_Type__c == BOB_MNG_TYPE_PRO_TRADER && bob.Managed_Segment__c == BOB_MNG_SGM_PRO_TRADER_CAT && SET_PRO_TRADER_COUNTRY.contains(bob.EBH_BOBCNTRY__c) && SET_BOB_RTYPES_ALLOW_PROTRADER.contains(bob.RecordTypeId);
    }

    /*********************************************************************************************************************************
    @ Method:         getBatchIsRunning
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014345 - Cohort Activation Process Part 1
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.11.2023 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    public static Boolean getBatchIsRunning() {
        User currentUser = ApexUtil.getCurrentUser();
        Integer countRunningBatch = ApexUtil.countRunningBatchByUser(new Set<String>{BATCH_NAME}, new Set<String>{BATCH_JOB_TYPE}, new Set<Id>{currentUser.Id});
        return (countRunningBatch > 0 ? true : false) ;
    }



    class Columns{

        @AuraEnabled
        public String label {get; set;}

        @AuraEnabled
        public String fieldName {get; set;}

        @AuraEnabled
        public String type {get; set;}

        @AuraEnabled
    	public Map<String,Object> typeAttributes;



        public Columns(String label,String fieldName,String type){
            this.label = label;
    		this.fieldName = fieldName;
    		this.type = type.toLowerCase();
        }

        public void makeFieldIntoLink(String lookupFieldName, String lookupFieldLabel){

            typeAttributes = new Map<String,Object>{
                'label' => new Map<String,Object>{'fieldName'=>this.fieldName},
                'target'=>'_blank',
                'tooltip'=>''
            };
            this.fieldName = 'link_'+lookupFieldName;
            this.type = 'url';
            this.label = (lookupFieldLabel == 'Record Id') ? this.label : lookupFieldLabel;
        }

    }

    class CohortActionControllerException extends Exception{}
}