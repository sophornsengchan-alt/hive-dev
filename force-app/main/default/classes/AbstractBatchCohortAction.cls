/*********************************************************************************************************************************
@ Class:          AbstractBatchCohortAction
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 30.01.2024 / Sophal Noch / Create the class
                : 15.02.2024 / Sophal Noch / US-0014756 - Data Synchronization of the Managed fields when the Account Manager on Active Cohort is updated
                : 16.02.2024 / Sophal Noch / US-0014755 - ADS - Cohort Seller and Seller nightly synch
                : 28.03.2024 / Sophal Noch / US-0015011 - 1 PT for US - Enable Cohort Invitation Process
                : 22.04.2024 / sovantheany dim / US-0015106 - Retire Managed Cohort - Retire the record type Managed Cohort and update the Record Type of LTTM
                : 13.05.2024 / Sophal Noch / US-0015242 - Fix Account Owner Updating to Integration User Issue
                : 14.05.2024 / Sophal Noch / US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
                : 24.02.2024 / Sophal Noch / US-0016833 - Account History | Owner changes several times a day
                : 03.07.2025 / Sophal Noch / US-0033064 - Limiting paid programs visibility to only existing subscribers
*********************************************************************************************************************************/
public inherited sharing abstract class AbstractBatchCohortAction implements ICohortAction{

    public abstract void execute(List<Sobject> listSobject);
    public abstract String getSoql();
    public abstract String getActionLabel();

    private final String BOB_RT_ADS = 'Advertising_Cohort';
    private final String BOB_RT_LTTM = 'Light_Touch_Category_Cohort';
    //private final String BOB_RT_MNG = 'Managed_Cohort';//TH:US-0015106 : comment out
    private final String BOB_STATUS_ACTIVE = 'BoB Active';
    private final String BOB_STATUS_INACTIVE = 'BoB Inactive';

    private final Map<String, String> MAP_BOB_COUNTRY_TO_DOMAIN = CohortActionController.MAP_COUNTRY_KEY_TO_DOMAIN; // 28.03.2024 / Sophal Noch / US-0015011 : move from hard code to custom metadata

    private final String BS_FNAME_BOB = 'BoB__c';
    private final String BS_MANGEDTYPE_PRO_TRADER = 'LTTM Managed';
    private final String BS_STATUS_INVITED = 'Invited';
    private final String BS_STATUS_ACTIVE = 'Draft';
    private final String BS_STATUS_INACTIVE = 'Inactive';
    private final String BS_STATUS_REMOVED = 'Removed';
    private final String BS_STATUS_NEW = 'New';
    private final Set<String> SET_BS_GSD_AM_DOMAIN = new Set<String>{SEP_Helper.SEP_Domain_NA, SEP_Helper.SEP_Domain_UK, SEP_Helper.SEP_Domain_DE}; // 07.07.2025 / Sophal Noch / US-0033064

    private final Set<String> SET_BS_STATUS_INACTIVE = new Set<String>{
        BS_STATUS_INACTIVE, 
        BS_STATUS_REMOVED
    };

    private final String USER_TYPE_POWER_CUSTOMER_SUCCESS = 'PowerCustomerSuccess';

    private final String ACC_SOBJ = 'Account';

    private final String PKL_VAL_FULL_ACCESS = 'Full Access';
    private final String FLD_OWNERID = 'OwnerId';

    private final String MDT_SYNC_ACTIVE_CS = 'Active_CohortSeller';
    // 01.12.2023 / Sophal Noch / US-0014172 
    private final String MDT_SYNC_ACTIVE_ADS_CS = 'Active_Ads_CohortSeller';
    private final Set<String> SET_MDT_SYNC_ACTIVE_CS = new Set<String>{MDT_SYNC_ACTIVE_CS, MDT_SYNC_ACTIVE_ADS_CS};

    private final Map<String, String> MAP_BOB_RT_TO_MDT_SYNC = new Map<String, String>{
        BOB_RT_LTTM => MDT_SYNC_ACTIVE_CS,
        //BOB_RT_MNG => MDT_SYNC_ACTIVE_CS,//TH:US-0015106 : comment out
        BOB_RT_ADS => MDT_SYNC_ACTIVE_ADS_CS
    };

    private final String MDT_SYNC_FYPE_CHECKBOX = 'Checkbox';

    private final String EMAIL_TMP_CS_STATUS_UPDATE = 'Cohort_Sellers_Status_Update';
    private final String LINK_TO_BOB_RELATED_LIST_CS = '{0}/lightning/r/BOB__c/{1}/related/BoB_Sellers__r/view';
    private final String MERGE_FLD_USER_NAME = '{!User.Name}';
    private final String MERGE_FLD_BOB_LINK = '{!BOB__c.Link}';

    private final static Id INTEGRATION_USER_ID = (Id)ApexUtil.INTEGRATION_USER_ID; // 24.02.2024 / Sophal Noch / US-0016833 
    private final static Id DEACTIVATION_USER_ID = (Id)Label.Cohort_Deactivation_UserId; // 13.05.2024 / Sophal Noch / US-0015242,  // 24.02.2024 / Sophal Noch / US-0016833 : change string to Id
    public final static Set<Id> SET_DEACTIVATION_USER_ID = new Set<Id>{INTEGRATION_USER_ID, DEACTIVATION_USER_ID}; // 13.05.2024 / Sophal Noch / US-0015242, // 24.02.2024 / Sophal Noch / US-0016833 : create a set for deactivation user ids

    private final String ERR_MSG = '- {0}';

    private final Set<String> SET_LTTM_ADS_RTYPES_BOB = new Set<String>{BOB_RT_LTTM,BOB_RT_ADS};
    //private final Set<String> SET_LTTM_MNG_RTYPES_BOB = new Set<String>{BOB_RT_LTTM,BOB_RT_MNG};//TH:US-0015106 : comment out
    private final Set<String> SET_LTTM_MNG_RTYPES_BOB = new Set<String>{BOB_RT_LTTM};

    //private final Set<String> SET_ALL_RTYPES_BOB = new Set<String>{BOB_RT_LTTM, BOB_RT_MNG, BOB_RT_ADS};//TH:US-0015106 : comment out
    private final Set<String> SET_ALL_RTYPES_BOB = new Set<String>{BOB_RT_LTTM, BOB_RT_ADS};

    private final String BS_SOQL = 'Select Id, Name, Status__c, Seller__c, Account_Manager__c, Managed_Type__c, BoB__c, BOB__r.Managed_Type__c, BoB__r.EBH_BOBCNTRY__c, Bob__r.RecordType.DeveloperName, Deactivation_Reason__c, Conflict_Reason__c From BoB_Seller__c';
    public final static String BS_TO_SYNC_SOQL = 'Select Id, Name, Active__c, Managed_Type__c, EBH_BOBSegment__c,BoB_Subsegment__c, BoB_Country__c, Account_Manager_CalendlyLink__c, RecordTypeId, Status__c, Account_Manager__c, Ads_Partner_Manager__c, Ads_GTM_Segment__c, BoB_Vertical__c,' // 03.07.2025 / Sophal Noch / US-0033064 : add fields BoB_Country__c, Account_Manager_CalendlyLink__c, RecordTypeId
    + 'Account_Manager__r.Name,BoB__c,BoB__r.Name, BOB__r.Managed_Type__c, BOB__r.Managed_Segment__c, BoB__r.OwnerId,BoB__r.Owner.Name,BoB__r.EBH_BOBCNTRY__c,BoB__r.EBH_BOBVertical__c,BoB__r.Status__c,' // 14.05.2024 / Sophal Noch / US-0015200 : add BOB__r.Managed_Segment__c to soql
    + 'Bob__r.RecordType.DeveloperName, Bob__r.RecordTypeId, Seller__c,Seller__r.Name, BoB_Managed__c from BoB_Seller__c ';  // 16.02.2024 / Sophal Noch / US-0014755 : make it public static to reuse in BatchFixBoBAccountManager, // 14.05.2024 / Sophal Noch / US-0015200 : add BOB__r.RecordTypeId to soql
    public final static String ACC_SOQL = 'Select Id, Name, OwnerId From Account '; // 16.02.2024 / Sophal Noch / US-0014755 : make it public static to reuse in BatchFixBoBAccountManager,  24.02.2024 / Sophal Noch / US-0016833 : add ownerId to SOQL
    private final String WHERE_BOB = ' WHERE BoB__c IN : setSobjIds';
    private final String WHERE_BS = ' WHERE Id IN : setSobjIds'; // 30.11.2023 / Sophal Noch / US-0014362 
    

    protected final String BS_TO_SYNC_SOQL_WHEN_ACTIVATE_BOB = BS_TO_SYNC_SOQL + WHERE_BOB;

    protected final String BS_SELECTED_TO_SYNC_SOQL = BS_TO_SYNC_SOQL + WHERE_BS; // 30.11.2023 / Sophal Noch / US-0014362 

    protected final String BOB_SOQL = 'Select Id, Name From BoB__c Where Id IN: setSobjIds';

    protected final String BOB_SOQL_TO_DEACTIVATE = BOB_SOQL + ' AND Status__c !=: BOB_STATUS_INACTIVE';

    protected final String ACC_SOQL_TO_SYNC = ACC_SOQL + 'Where Id IN: setSobjIds'; // 16.02.2024 / Sophal Noch / US-0014755

    private final String ACC_SOQL_TO_UPDATE_SP_FLDS = 'Select Id, Name, SP_Account_Management__c, SP_Main_Domain__c, OwnerId From Account Where Id IN :setAccId';

    private String action = '';
    private Integer soqlIndex = null;

    private Set<Id> setAccId = new Set<Id>();
    private Set<Id> setActiveBsAccId = new Set<Id>();
    private Set<Id> setActiveAdsBsAccId = new Set<Id>();
    Map<Id,User> mapValidUser = new Map<Id,User>();
    private Set<String> setSobjIds = new Set<String>();
    private Set<String> setNextSobjIds;
    protected String initActionLabel;
    private String className = '';
    private String methodName = '';
    private Boolean skipPublishEvent = false;

    public Database.QueryLocator startBatch(){
        return Database.getQueryLocator(this.getSoql());
    }

    public List<SObject> executeQuery(){
        return Database.query(this.getSoql());
    }

    public ICohortAction setAction(String action){
        this.action = action;
        return this;
    }
    public ICohortAction setSoqlIndex(Integer soqlIndex){
        this.soqlIndex = soqlIndex;
        return this;
    }
    public ICohortAction setSetSobjIds(Set<String> setSobjIds){
        this.setSobjIds = setSobjIds;
        return this;
    }
    public ICohortAction setClassName(String className){
        this.className = className;
        return this;
    }
    public ICohortAction setMethodName(String methodName){ // 16.02.2024 / Sophal Noch / US-0014755
        this.methodName = methodName;
        return this;
    }
    public ICohortAction setSkipPublishEvent(Boolean skipPublishEvent){ // 16.02.2024 / Sophal Noch / US-0014755
        this.skipPublishEvent = skipPublishEvent;
        return this;
    }
    public Set<String> getNextSobjIds(){
        return this.setNextSobjIds;
    }

    public void publishInitEvent(){ // 11.12.2023 / Sophal Noch / US-0014362
        if(String.isNotBlank(this.initActionLabel)){
            CohortAction_Event__e initEvent = new CohortAction_Event__e(Action_Name__c = this.className, Action_Index__c = 0, Action_Label__c = this.initActionLabel);
            EventBus.publish(initEvent);
        }
    }

    public void publishSuccessEvent(){
        if(!this.skipPublishEvent){
            CohortAction_Event__e updateEvent = new CohortAction_Event__e(Action_Name__c = this.action, Action_Index__c = this.soqlIndex, Action_Label__c = getActionLabel());
            EventBus.publish(updateEvent);
        }
    }
    
    public void publishErrorEvent(Exception e){
        EBH_ApexLogger.logError(new List<Exception>{e}, this.className, this.getActionNameIndex()); 
        if(!this.skipPublishEvent){
            CohortAction_Event__e updateEvent = new CohortAction_Event__e(Action_Name__c = this.action, Action_Index__c = this.soqlIndex, Action_Label__c = getActionLabel(), Is_Error__c = true, Error_Message__c = e.getMessage());
            EventBus.publish(updateEvent);
        }
    }

    private String getActionNameIndex(){
        return String.isNotBlank(methodName) ? methodName : (this.action + (this.soqlIndex != null ? ('_'+this.soqlIndex) : ''));
    }

    private void getActiveSellerId( List<BoB_Seller__c> listBs, Set<Id> setAccIdToSync){

        // get other bob sellers that are already active
        // make it seperate method for reussability

        setActiveBsAccId = new Set<Id>();
        setActiveAdsBsAccId = new Set<Id>();
        mapValidUser = new Map<Id,User>();
        setAccId = new Set<Id>();
        Set<Id> setBSId = new Set<Id>();
        Set<Id> setBSAccManId = new Set<Id>();

        if(listBs != null){

            for(BoB_Seller__c bs : listBs){
                if(bs.Seller__c != null){ setAccId.add(bs.Seller__c); }
                setBSId.add(bs.Id);

                if(isBsActive(bs)){
                    
                    if(bs.BoB__r.RecordType.DeveloperName == BOB_RT_ADS){ // 01.12.2023 / Sophal Noch / US-0014172 : store different active bob seller depending on bob record type
                        setActiveAdsBsAccId.add(bs.Seller__c);
                    }else{
                        setActiveBsAccId.add(bs.Seller__c);
                    }
                    
                    if (bs.Account_Manager__c != null) {
                        setBSAccManId.add(bs.Account_Manager__c);
                    }
                }
                
            }
        }else if(setAccIdToSync != null){
            setAccId = setAccIdToSync;
        }

        mapValidUser = new Map<Id,User>([SELECT id  From User where Id IN: setBSAccManId AND IsPortalEnabled =FALSE AND UserRoleId != null]); 
        //TH:US-0015106 : remove (Bob__r.RecordType.DeveloperName =: BOB_RT_MNG AND Active__c = true)
        for(BoB_Seller__c bs : [Select Seller__c, BoB__r.RecordType.DeveloperName From BoB_Seller__c Where Seller__c IN: setAccId AND ID NOT IN: setBSId
            AND Bob__r.Status__c =: BOB_STATUS_ACTIVE
            AND (Bob__r.RecordType.DeveloperName IN: SET_LTTM_ADS_RTYPES_BOB AND Status__c =: BS_STATUS_ACTIVE)]
        ){

            if(bs.BoB__r.RecordType.DeveloperName == BOB_RT_ADS){ // 01.12.2023 / Sophal Noch / US-0014172 : store different active bob seller depending on bob record type
                setActiveAdsBsAccId.add(bs.Seller__c);
            }else{
                setActiveBsAccId.add(bs.Seller__c);
            }

        }
    }

    private Boolean isBsActive(BoB_Seller__c bs){ // check bob seller is active or not
        //TH:US-0015106 : remove (bs.Bob__r.RecordType.DeveloperName == BOB_RT_MNG && bs.Active__c == true) || 
        return bs.BoB__r.Status__c == BOB_STATUS_ACTIVE && ((SET_LTTM_ADS_RTYPES_BOB.contains(bs.Bob__r.RecordType.DeveloperName) && bs.Status__c == BS_STATUS_ACTIVE));
    }

    private Map<String, List<CohortSeller_To_Account_Sync__mdt>> getMapGroupByToFldSync(){

        //  01.12.2023 / Sophal Noch / US-0014172 lttm and ads has different fields sync so different custom metadata record
        Map<String, List<CohortSeller_To_Account_Sync__mdt>> mapGroupByToFldSync = new Map<String, List<CohortSeller_To_Account_Sync__mdt>>();
        for(CohortSeller_To_Account_Sync__mdt fieldSync : [SELECT Id, Group_by__c, Source_Field__c, Target_Field__c, Target_Field_Type__c FROM CohortSeller_To_Account_Sync__mdt WHERE Group_by__c IN :SET_MDT_SYNC_ACTIVE_CS and IsActive__c = true]){
            List<CohortSeller_To_Account_Sync__mdt> listFldSyn = mapGroupByToFldSync.get(fieldSync.Group_by__c);
            if(listFldSyn == null){
                listFldSyn = new List<CohortSeller_To_Account_Sync__mdt>();
                mapGroupByToFldSync.put(fieldSync.Group_by__c, listFldSyn);
            }
            listFldSyn.add(fieldSync);
        }
        return mapGroupByToFldSync;
    }

    protected void syncBsToAccount(List<BoB_Seller__c> listBobSeller){

        // sync invite, active, inactive bob seller to account
        // make it seperate method for reussability

        getActiveSellerId(listBobSeller, null);  // get other bob sellers that are already active

        // Map<String, Account> mapAcc = new Map<String, Account>([Select Id, Name, SP_Account_Management__c, SP_Main_Domain__c, OwnerId From Account Where Id IN: setAccId]); // 24.02.2024 / Sophal Noch / US-0016833 : add OwnerId to SOQL
        Map<String, Account> mapAcc = new Map<String, Account>((List<Account>)ApexSafe.query().secCheck(false).doQuery(ACC_SOQL_TO_UPDATE_SP_FLDS, new Map<String, Object> {'setAccId' => setAccId})); // 03.07.2025 / Sophal Noch / US-0033064 : move static query to ApexSafe

        Map<String, List<CohortSeller_To_Account_Sync__mdt>> mapGroupByToFldSync = getMapGroupByToFldSync();

        for(BoB_Seller__c bs : listBobSeller){

            Account acc = mapAcc.get(bs.Seller__c);
            if(acc == null){
                acc = new Account(Id = bs.Seller__c);
                mapAcc.put(bs.Seller__c, acc);
            }

            if(CohortActionController.isProTrader(bs.BoB__r) && bs.Status__c == BS_STATUS_INVITED){ // for pro-trader bob seller with status invited

                if(String.isBlank(acc.SP_Account_Management__c)){ acc.SP_Account_Management__c = PKL_VAL_FULL_ACCESS;}
                if(String.isBlank(acc.SP_Main_Domain__c)){ acc.SP_Main_Domain__c = MAP_BOB_COUNTRY_TO_DOMAIN.get(bs.BoB__r.EBH_BOBCNTRY__c); }
            }else if(SET_ALL_RTYPES_BOB.contains(bs.BoB__r.RecordType.DeveloperName)){  //  sync active, inactive bob seller to account

                if(isUpdateGSDAccMgnFullAccess(bs, acc)){ // 03.07.2025 / Sophal Noch / US-0033064 : check GSD Account Management eligibility before update Full Access to SP_Account_Management__c
                    acc.SP_Account_Management__c = PKL_VAL_FULL_ACCESS;
                }

                String mdtNameFldSyn = MAP_BOB_RT_TO_MDT_SYNC.get(bs.BoB__r.RecordType.DeveloperName);  //  01.12.2023 / Sophal Noch / US-0014172 : get differetn metadata record for lttm and ads
                if(String.isBlank(mdtNameFldSyn)){ continue; }
                List<CohortSeller_To_Account_Sync__mdt> listFldSyn = mapGroupByToFldSync.get(mdtNameFldSyn);
                if(listFldSyn == null) { continue; }

                for(CohortSeller_To_Account_Sync__mdt fieldSync : listFldSyn){

                    if(String.isBlank(fieldSync.Target_Field__c)) { continue; }
    
                    if(isBsActive(bs)){  // is active bob seller

                        Object fieldVal = ApexUtil.getValue(fieldSync.Source_Field__c, bs);
                        
                        if(fieldVal == null && String.isNotBlank(fieldSync.Target_Field_Type__c) && fieldSync.Target_Field_Type__c.toLowerCase() == MDT_SYNC_FYPE_CHECKBOX.toLowerCase()){ fieldVal = false; }
                        if(fieldSync.Target_Field__c == FLD_OWNERID){
                            String userId = fieldVal != null ? String.valueOf(fieldVal) : null;
                            if(mapValidUser.containsKey(userId)){
                                fieldVal = mapValidUser.get(userId).Id;
                            }else if (!SET_DEACTIVATION_USER_ID.contains(acc.OwnerId)){ // 24.02.2024 / Sophal Noch / US-0016833 : update onwer only when owner is not deactivation user
                                fieldVal = DEACTIVATION_USER_ID; // 13.05.2024 / Sophal Noch / US-0015242 : change from INTEGRATION_USER_ID to DEACTIVATION_USER_ID
                            }else{
                               continue; // 24.02.2024 / Sophal Noch / US-0016833
                            }
                        }

                        acc.put(fieldSync.Target_Field__c, fieldVal);

                    }else{  // is inactive bob seller

                        if(isSellerActiveInOtherBob(bs, null, acc.Id)){
                            continue;
                        }
                        resetAccField(fieldSync, acc);

                    }
                    
                }

            }
            
        }

        if(!mapAcc.isEmpty()){
            List<String> listError = new List<String>();
            for(Database.SaveResult sr : Database.Update(mapAcc.values(), false)){
                if(!sr.isSuccess()){ listError.add(mapAcc.get(sr.getId())?.Name + '_' + sr.getErrors()[0].getMessage()); } // 11.12.2023 / Sophal Noch / US-0014362 : add account name to error message, 15.02.2024 / Sophal Noch / US-0014756
            }
            if(!listError.isEmpty()){ logApexError(listError);}
        }
    }

    protected void unsyncAccount(List<Account> listAccToUnsync){

        // 30.01.2024 / Sophal Noch / US-0014277 : method to unsync list acc
        
        Set<Id> setAccIdToUnsync = new Set<id>();
        for(Account acc : listAccToUnsync){
            setAccIdToUnsync.add(acc.Id);
        }

        getActiveSellerId(null, setAccIdToUnsync);
        Map<String, List<CohortSeller_To_Account_Sync__mdt>> mapGroupByToFldSync = getMapGroupByToFldSync();

        Map<Id, Account> mapAccToUpdate = new Map<Id, Account>();
        for(Account acc : listAccToUnsync){

            Boolean hasAccToUpdate = false;
            for(String groupBy : mapGroupByToFldSync.Keyset()){
                
                if(isSellerActiveInOtherBob(null, groupBy, acc.Id)){
                    continue;
                }

                List<CohortSeller_To_Account_Sync__mdt> listFldSyn = mapGroupByToFldSync.get(groupBy);
                for(CohortSeller_To_Account_Sync__mdt fieldSync : listFldSyn){
                    resetAccField(fieldSync, acc);
                }
                hasAccToUpdate = true;
            }
            
            if(hasAccToUpdate){
                mapAccToUpdate.put(acc.Id, acc);
            }

        }
        if(!mapAccToUpdate.isEmpty()){
            List<String> listError = new List<String>();
            for(Database.SaveResult sr : Database.Update(mapAccToUpdate.values(), false)){               
                if(!sr.isSuccess()){ listError.add(mapAccToUpdate.get(sr.getId())?.Name + '_' + sr.getErrors()[0].getMessage()); } // 15.02.2024 / Sophal Noch / US-0014756
            }
            if(!listError.isEmpty()){ logApexError(listError);}
        }
    }

    private Boolean isSellerActiveInOtherBob(BoB_Seller__c bs, String groupBy, Id accId){

        // 01.12.2023 / Sophal Noch / US-0014172 : check there is exist active ads bob seller or not before unsync field
        // 30.01.2024 / Sophal Noch / US-0014277 : make this a seperate method for reusability

        Boolean hasActive = false;
        if(
            (((bs != null && SET_LTTM_MNG_RTYPES_BOB.contains(bs.BoB__r.RecordType.DeveloperName)) || groupBy == MDT_SYNC_ACTIVE_CS) && setActiveBsAccId.contains(accId))
            || (((bs != null && bs.BoB__r.RecordType.DeveloperName == BOB_RT_ADS) || groupBy == MDT_SYNC_ACTIVE_ADS_CS) && setActiveAdsBsAccId.contains(accId))
        ){
            hasActive = true;
        }
        return hasActive;
    }

    private void resetAccField(CohortSeller_To_Account_Sync__mdt fieldSync, Account acc){
        // 30.01.2024 / Sophal Noch / US-0014277 : make this a seperate method for reusability
        Object fieldVal = null;
        if(String.isNotBlank(fieldSync.Target_Field_Type__c) && fieldSync.Target_Field_Type__c.toLowerCase() == MDT_SYNC_FYPE_CHECKBOX.toLowerCase()){ fieldVal = false; }
        if(fieldSync.Target_Field__c == FLD_OWNERID){ // 24.02.2024 / Sophal Noch / US-0016833 
            If(!SET_DEACTIVATION_USER_ID.contains(acc.OwnerId)){  // 24.02.2024 / Sophal Noch / US-0016833 : update onwer only when owner is not deactivation user
                fieldVal = DEACTIVATION_USER_ID; // 13.05.2024 / Sophal Noch / US-0015242 : change from INTEGRATION_USER_ID to DEACTIVATION_USER_ID
            }else{
                return; // 24.02.2024 / Sophal Noch / US-0016833
            }
        } 
        acc.put(fieldSync.Target_Field__c, fieldVal);
    }

    protected void sendEmailAfterCohortUpdate(List<BoB__c> listBob){

        if(UserInfo.getUserType() ==  USER_TYPE_POWER_CUSTOMER_SUCCESS){return;}

        // send email after bob sellers are activated or after bob is deactivated
        List<Messaging.SingleEmailMessage> listEmail = new List<Messaging.SingleEmailMessage>();
        String sfUrl = URL.getOrgDomainUrl().toExternalForm();
        User currentUser = ApexUtil.getCurrentUser();
        OrgWideEmailAddress orgWide = ApexUtil.getOWDbyAddress(Label.CohortSellers_StatusUpdate_OWD_Email);

        for(BoB__c bob : listBob){ // send email to user who tirgger the batch with link to bob
            Map<String,String> binding = new Map<String,String>();
            binding.put(MERGE_FLD_USER_NAME, currentUser.Name);
            binding.put(MERGE_FLD_BOB_LINK, String.format(LINK_TO_BOB_RELATED_LIST_CS, new List<String>{sfUrl, bob.Id}));
            Messaging.SingleEmailMessage email = ApexUtil.prepareEmail(null, new String[] {currentUser.Email}, null, EMAIL_TMP_CS_STATUS_UPDATE, null, binding, null, orgWide);
            listEmail.add(email);
        }

        if (!listEmail.isEmpty()) {
            ApexUtil.sendEmail(listEmail);
        }
    }

    protected void deactivateCohort(List<BoB__c> listBob){
        // update parent bob to bob inactive when all bob sellers are inactive
        Map<Id,BoB__c> mapBobToUpdate = new Map<Id,BoB__c>();
        List<String> listError = new List<String>();
        for(BoB__c bob : listBob){
            bob.Status__c = BOB_STATUS_INACTIVE;
            mapBobToUpdate.put(bob.Id, bob);
        }
        Set<Id> setBobId = mapBobToUpdate.keySet();
        for (AggregateResult agBs : Database.query('Select BoB__c From BoB_Seller__c WHERE BoB__c IN: setBobId And Status__c NOT IN: SET_BS_STATUS_INACTIVE Group By BoB__c')){
            Id bobId = (Id)agBs.get(BS_FNAME_BOB);
            if(mapBobToUpdate.containsKey(bobId)){
                // listError.add(String.format(Label.Cohort_can_not_be_Deactivated, new List<String>{mapBobToUpdate.get(bobId).Name}));
                mapBobToUpdate.remove(bobId);
            }
        }
        
        if(!mapBobToUpdate.isEmpty()){ 
            for(Database.SaveResult sr : Database.Update(mapBobToUpdate.values(), false)){
                if(!sr.isSuccess()){
                    listError.add(mapBobToUpdate.get(sr.getId())?.Name  + '_' + sr.getErrors()[0].getMessage()); // 11.12.2023 / Sophal Noch / US-0014362 : add cohort name to error message, 15.02.2024 / Sophal Noch / US-0014756
                }
            }
        }
        if(!listError.isEmpty()){ logApexError(listError);}
    }

    protected void changeNextSobjectToFromBsToBoB(List<BoB_Seller__c> listBobSeller){
        // 30.11.2023 / Sophal Noch / US-0014362 : pouplate setNextSobjIds, so when each action batch finish, it uses setNextSobjIds to replace setSobjIds
        for(BoB_Seller__c bs :listBobSeller){
            if(setNextSobjIds == null){ setNextSobjIds = new Set<String>();}
            if(bs.BoB__c == null){ continue;}
            setNextSobjIds.add(bs.BoB__c);
        }
    }

    private void logApexError(List<String> listError){
        List<AbstractBatchCohortActionException> listException = new List<AbstractBatchCohortActionException>();
        for(String errorMsg : listError){
            errorMsg = String.format(ERR_MSG, new List<String>{errorMsg});
            AbstractBatchCohortActionException e = new AbstractBatchCohortActionException(errorMsg);
            listException.add(e);
        }
        EBH_ApexLogger.logError(listException, this.className,this.getActionNameIndex()); 
    }

    private Boolean isUpdateGSDAccMgnFullAccess(BoB_Seller__c bs, Account acc){
        // check if GSD Account Management seller should be update SP Account Management as Full Access or not
        return
        String.isBlank(acc.SP_Account_Management__c)
        && String.isNotBlank(acc.SP_Main_Domain__c)
        && SET_BS_GSD_AM_DOMAIN.contains(acc.SP_Main_Domain__c)
        && String.isNotBlank(bs.Account_Manager_CalendlyLink__c)
        && bs.BoB_Managed__c
        && SEP_Helper.isGSDAccMgnEligible(bs);
    }
    
    class AbstractBatchCohortActionException extends Exception{}

}