/**
Create VF list view button

Allows user to select Deal records from list view. 
Need to validate that all Deals records selected have been 'Internally Approved' 
once validated pass records to class created in 00201530


CR00397704
Need to update the code for both butters on sent to seller 
and Send for Approval so that if they are already sent the email to the user or the seller(s). 
This should only be possible if they are in Status 'Sent to Seller' or 'In Approval' for the respective buttons

@ Change history: SRONG TIN - 15.05.2023 - US-0013428:1. Send Contract to Seller - Deal Contract in Seller Portal
@               : SRONT TIN - 19.09.2023 - US-0014161 - Contract email notification is failing/ Error on Sent to Seller

*/
public without sharing class DD_SendToSellerController {
    
    public List<EBH_Deal__c> selectedDeal {get;set;}
    public Integer dealSize {get;set;}
    public Boolean displayPopup {get; set;}
    ApexPages.StandardSetController setCon;
    public static Deal_Timezone__c dealTimezone = Deal_Timezone__c.getInstance();
    
    public List<DD_SendToSellerHelper.ContractAgreementWrapper> dcas {get;set;}
    // SRONG TIN - 19.09.2023 - US-0014161
    public Map<String,String> mapDCAIds  {get;set;}
    public Set<String> accountIds {get;set;}
    public Boolean isNotInternalApproved {get;set;}
    public Boolean isAfterStartDate {get;set;}
    public Boolean isError {get;set;}
    
    public static final string INTERNALLY_APPROVED = 'Internally Approved';
    public static final string EXPIRED = 'Expired';
    public static final string SENT_TO_SELLER = 'Sent to Seller';
    public static final string STATUS_NEW = 'New';
    public static final string STATUS_CANCELLED = 'Cancelled';
    public static final string FULL_ACCESS = 'Full Access';
    private static final Set<String> ALLOWED_STATUS = new Set<String> { INTERNALLY_APPROVED, SENT_TO_SELLER, EXPIRED}; // 28.05.2021 / Sophal Noch / US-0009533
    // SRONG TIN - 15.05.2023 - US-0013428
    private static final Set<String> ALLOWED_STATUS_IT = new Set<String> { STATUS_NEW, STATUS_CANCELLED};
    public static final String STANDARD_USER_PROFILE = 'Standard User Profile';
    private Set<String> sSellerId = new Set<String>();
    private Set<String> sSellerPortalGroupId = new Set<String>();
    private final static string SELCOM_DEALS_CONTRACT_NAME = 'Send Deals Contract to Seller - IT';
    private final static string SELCOM_DEAL_CONTRACT_APPROVAL_EMAILTEMPLATE = 'Deal Contract for Approval - IT';

    public static Boolean PROCESS_SENT_SELLER = false;
    public static final String NA_PROFILE = 'NA Standard User Base';
    // SRONG TIN - 26.09.2023 - US-0014161
    private static final string MESSAGE_INFO_ERROR = 'Error';
    private static final string MESSAGE_INFO_WARNING = 'Warning';
    private static final string MESSAGE_INFO_SUCCESS = 'Success';
    private static final string SELLERCOM_EMAIL_EMPTY = 'Email is empty';

    public final static String US_MANAGE_DEAL_PERM='Select PermissionSet.Name, PermissionSetId, AssigneeId From PermissionSetAssignment  where PermissionSet.Name IN (\'US_Manage_Deals\') AND AssigneeId=:currentUserId  limit  1';
    //public static final string INTERNALLY_APPROVED = 'Negotiating';
    
    @TestVisible private static Integer CHUNK_SIZE_LIMIT = 25;
    // public List<Id> lstAllDealId {get{return lstAllDealId = (lstAllDealId !=null ? lstAllDealId : new List<Id>());} set;}


    public Map<String,Object> mapChunkedDeal {get{return mapChunkedDeal = (mapChunkedDeal !=null ? mapChunkedDeal : new Map<String,Object>());} set;}
    public Integer chunkIndex {get{return chunkIndex = (chunkIndex !=null ? chunkIndex : 0);} set;}
    public Integer chunkSize {get{return chunkSize = (chunkSize !=null ? chunkSize : 0);} set;}
    public Boolean canContinueSending {get;set;}
    public Boolean finishSending{get{return finishSending = (finishSending !=null ? finishSending : false);} set;}
    // SRONG TIN - 19.09.2023 - US-0014161
    public String errorMessage {get;set;}
    public String errorMessageDetail {get;set;}
    public Boolean isRollBack {get;set;}// for sellerCom
    public Boolean isShowMessageInfo {get;set;}
    public String  messageInfoType {get;set;}

    @TestVisible private Set<Id> setDealIdToSendEmail = new Set<Id>();
    @TestVisible private Set<Id> setPrevInternally = new Set<Id>();
    // private Set<Id> setPrevSendToSeller = new Set<Id>();

    private Id dealNA;
    private Boolean isIT;
   

    public DD_SendToSellerController(ApexPages.StandardSetController controller) { 
        isError = false;
        isNotInternalApproved = false;
        isAfterStartDate = false;
        isIT = false;
        setCon = controller;
        errorMessage = '';
        errorMessageDetail = '';
        mapDCAIds = new Map<String,String>();
        accountIds = new Set<String>();
        isRollBack = true;
        isShowMessageInfo = false;
        messageInfoType = 'Error';
        selectedDeal = controller.getSelected();
        Timezone tz = Timezone.getTimeZone(dealTimezone.TimeZone__c);
        Datetime dNow =  DateTime.newInstance(System.Now().getTime() + tz.getOffset(System.Now()));
        String NAprofile = ApexUtil.getProfileByName(NA_PROFILE).Id;
        Boolean isNA = UserInfo.getProfileId().equals(NAprofile);
        Boolean isAdmin = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
        String currentUserId = UserInfo.getUserId();
        
        List<Id> lstAllDealId = new List<Id>();

        //MN-17082022-US-0011119-Remove reference with old record type name
        // dealNA = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
    	RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
        dealNA = subDealRecordType.Id;
        String siteIT = ApexUtil.MAP_COUNTRY_CODE.get('IT');
        Set<String> dealSite = new Set<String>();
        for(EBH_Deal__c deal : [select RecordTypeId, EBH_Status__c, EBH_DealStartDate__c, EBH_DealStartTime__c, seller_approved__c, cancelled_deal__c, EBH_DealSiteId__c,EBH_BusinessName__c,EBH_BusinessName__r.Seller_Portal_Group__c,EBH_BusinessName__r.SP_Deals__c from EBH_Deal__c where id IN: selectedDeal]){
            
            if(deal.EBH_DealSiteId__c != siteIT && deal.EBH_Status__c != INTERNALLY_APPROVED && deal.EBH_Status__c != SENT_TO_SELLER && deal.EBH_Status__c != EXPIRED){
                isNotInternalApproved = true;
            }

            Boolean isExpired = DD_SendToSellerHelper.checkExpiredDeal(deal,dNow);
            
            if(deal.EBH_Status__c == EXPIRED && deal.seller_approved__c == false && deal.cancelled_deal__c == false && isExpired){ // 04.06.2021 / Sophal Noch / US-0009649
                isAfterStartDate = true;
            }
            
            // if(deal.EBH_Status__c == EXPIRED || (deal.EBH_Status__c != SENT_TO_SELLER && isExpired)){ // 28.05.2021 / Sophal Noch / US-0009533
            //     isAfterStartDate = true;
            // }

            if(deal.EBH_DealSiteId__c != siteIT && ( deal.EBH_Status__c == INTERNALLY_APPROVED || deal.EBH_Status__c == SENT_TO_SELLER || deal.EBH_Status__c == EXPIRED)){ // 28.05.2021 / Sophal Noch / US-0009533
                lstAllDealId.add(deal.Id);
            }else if(deal.RecordTypeId == dealNA && deal.EBH_DealSiteId__c == siteIT && deal.EBH_BusinessName__r.SP_Deals__c == FULL_ACCESS && (deal.EBH_Status__c == STATUS_NEW || deal.EBH_Status__c == STATUS_CANCELLED)){ // SRONG TIN - 15.05.2023 - US-0013428
                isIT = true;
                lstAllDealId.add(deal.Id);
                sSellerId.add(deal.EBH_BusinessName__c);
                sSellerPortalGroupId.add(deal.EBH_BusinessName__r.Seller_Portal_Group__c);
            }
            //SRONG TIN - 15.05.2023 - US-0013428
            dealSite.add(deal.EBH_DealSiteId__c);
            if(dealSite.size()>1){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,System.Label.NA_CANCEL_FUNC_ERR5));
                isError = true;
                return;
            }

        }
        
        mapChunkedDeal = ApexUtil.chunkList(lstAllDealId,CHUNK_SIZE_LIMIT);
        chunkSize = (Integer)mapChunkedDeal.get('chunkSize');
        
        if(checkingHasNoPermission()){
            //System.debug('ERROR>>>>>');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, System.Label.NA_CANCEL_FUNC_ERR2));
            isError = true;
            return;
        }

        dealSize = selectedDeal.size();
        if (dealSize>0) {
            displayPopup = true;
        }
    }
    


    // Sophal:27/04/2021: US-0009436 disable because we use client side to fix cpu limit
    /**
    * Send to Seller
    * we only take Internally Approved/Sent to Seller Deals
    */
    // public PageReference sentToSellerAction() {
        
    //     //try{
    //         	PROCESS_SENT_SELLER = true;
    //             Map<String,List<EBH_Deal__c>> deals = loadDeals();
                
    //             // 2 blocs 
    //             // for INTERNALLY_APPROVED do normal process
    //             // for SENT_TO_SELLER we re sent email
    //             List<EBH_Deal__c> listINTERNALLY_APPROVED = deals.get(INTERNALLY_APPROVED);
    //             if(deals.containskey(EXPIRED)&&deals.containskey(INTERNALLY_APPROVED))listINTERNALLY_APPROVED.addall(deals.get(EXPIRED));
    //             else if(deals.containsKey(EXPIRED))listINTERNALLY_APPROVED = deals.get(EXPIRED);
    //             List<EBH_Deal__c> listSENT_TO_SELLER = deals.get(SENT_TO_SELLER);
                
    //             if (listINTERNALLY_APPROVED!=null && !listINTERNALLY_APPROVED.isEmpty()) {
    //                 updateDeals(listINTERNALLY_APPROVED); 
    //                 System.debug('<<<<listINTERNALLY_APPROVED:'+listINTERNALLY_APPROVED);
    //                 dcas = DD_SendToSellerHelper.createDealContractAgreement(listINTERNALLY_APPROVED);
                    
    //                 //DD_SendToSellerHelper.sendEmail(dcas, listINTERNALLY_APPROVED, false);  
                    
    //             }
                
    //             if (listSENT_TO_SELLER!=null && !listSENT_TO_SELLER.isEmpty()) {
    //                 dcas = DD_SendToSellerHelper.convertTContractAgreementWrapper(listSENT_TO_SELLER);
    //                 updateDeals(listSENT_TO_SELLER);
    //             }
                
                
    //         	PROCESS_SENT_SELLER = false;
    //     /*}catch (Exception ex) {
    //         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
    //         DD_Utils.PROCESS_SENT_SELLER = false;
    //         return null;
    //     }*/
    //     // bring user to the Contract Agreement ?
    //     return setCon.cancel();
    // }


    
    /*********************************************************************************************************************************
    @ Method:         sentToSellerAction
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0009436
                      use client side to send deal to seller. this is to fix the error CPU limit
    @ Event:		  when user click button 'Send to Seller'
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	list id of deal, list id of deal to send email later,
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  27.04.2021 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  24.06.2021 / Sophal Noch / US-0009754 modifed the method to be non-static method because we stop using remote action in vf page
    *********************************************************************************************************************************/  
    public PageReference sentToSellerAction() {

        canContinueSending = false;
        
        try{

                // if(checkingHasNoPermission()){ mapResult.put('status','ko'); mapResult.put('error',  System.Label.NA_CANCEL_FUNC_ERR2);return mapResult;}
                if(chunkIndex == 0){createSellerCom();}
                if(chunkIndex < chunkSize && !finishSending){

                    List<List<Object>> listAllDealChunk = (List<List<Object>>)mapChunkedDeal.get('listAllChunk');
                    Set<Id> setDealId = new Set<Id>();
                    for(Object objId : listAllDealChunk[chunkIndex]){
                        setDealId.add((Id)objId);
                    }
                    
                    Map<String,Map<Id,EBH_Deal__c>> mapDeals = setDealId.size() >0 ?loadDeals(setDealId):new Map<String,Map<Id,EBH_Deal__c>>();
    
                    Map<Id, EBH_Deal__c> mapDealInternallApproved = mapDeals.get(INTERNALLY_APPROVED); // 28.05.2021 / Sophal Noch / US-0009533 use 'internally approved' deal only
                    
                    
                    // 04.06.2021 / Sophal Noch / US-0009649
                    if(mapDeals.containskey(EXPIRED) && mapDeals.containskey(INTERNALLY_APPROVED)) mapDealInternallApproved.putAll(mapDeals.get(EXPIRED));
                    else if(mapDeals.containsKey(EXPIRED)) mapDealInternallApproved = mapDeals.get(EXPIRED);

                    // SRONG TIN - 15.05.2023 - US-0013428
                    Map<Id, EBH_Deal__c> mapDealsSendToSellerForIT = new Map<Id, EBH_Deal__c>();
                    if(mapDeals.containskey(STATUS_NEW))mapDealsSendToSellerForIT.putAll(mapDeals.get(STATUS_NEW));
                    if(mapDeals.containskey(STATUS_CANCELLED))mapDealsSendToSellerForIT.putAll(mapDeals.get(STATUS_CANCELLED));
    
    
                    Map<Id,EBH_Deal__c> mapDealSentToSeller = mapDeals.get(SENT_TO_SELLER);
    
                    List<DD_SendToSellerHelper.ContractAgreementWrapper> dcas;
                    if (mapDealInternallApproved != null && !mapDealInternallApproved.isEmpty()) {

                        updateDeals(mapDealInternallApproved.values()); 
                        dcas = DD_SendToSellerHelper.createDealContractAgreement(mapDealInternallApproved.values(), doQueryDeals(dealNA, ALLOWED_STATUS, setPrevInternally) );
    
                        setDealIdToSendEmail.addAll(mapDealInternallApproved.keySet());
                        setPrevInternally.addAll(mapDealInternallApproved.keySet());
                        
                    }
                    
                    if (mapDealSentToSeller != null && !mapDealSentToSeller.isEmpty()) {
                        // dcas = DD_SendToSellerHelper.convertTContractAgreementWrapper(mapDealSentToSeller.values(), doQueryDeals(dealNA, ALLOWED_STATUS, listPrevSendToSeller));
                        dcas = DD_SendToSellerHelper.convertTContractAgreementWrapper(mapDealSentToSeller.values(), new List<EBH_Deal__c>()); // Sophal:29/04/2021: US-0009476 no need to check previous deal for already 'sent to seller' deals
                        // updateDeals(mapDealSentToSeller.values()); 
    
                        setDealIdToSendEmail.addAll(mapDealSentToSeller.keySet());
    
                        // setPrevSendToSeller.addAll(mapDealSentToSeller.keySet()); not used
    
                    }
                    // SRONG TIN - 15.05.2023 - US-0013428
                    dcas = new List<DD_SendToSellerHelper.ContractAgreementWrapper>();
                    if(!mapDealsSendToSellerForIT.isEmpty()){
                        List<EBH_Deal__c> dealToUpdate = new List<EBH_Deal__c>();
                        // SRONG TIN - 26.09.2023 - US-0014161
                        if(!accountIds.isEmpty()){
                            for(EBH_Deal__c  d: mapDealsSendToSellerForIT.values()){
                                if(accountIds.contains(d.EBH_BusinessName__c) || accountIds.contains(d.EBH_BusinessName__r.Seller_Portal_Group__c)){
                                    dealToUpdate.add(d);
                                }
                            }
                        }
                        if(!dealToUpdate.isEmpty()){
                            updateDeals(dealToUpdate); 
                            dcas = DD_SendToSellerHelper.createDealContractAgreement(dealToUpdate, doQueryDeals(dealNA, ALLOWED_STATUS_IT, new Set<Id>()),'IT');
                        } 
                        
                    }
                    for(EBH_Deal__c d: [select EBH_BusinessName__c,EBH_BusinessName__r.Seller_Portal_Group__c,Deal_Contract_Agreement__c from EBH_Deal__c where id IN: setDealId]){
                        mapDCAIds.put(d.EBH_BusinessName__c,d.Deal_Contract_Agreement__c);
                        mapDCAIds.put(d.EBH_BusinessName__r.Seller_Portal_Group__c,d.Deal_Contract_Agreement__c);
                    }

                    chunkIndex++;
                    if(chunkIndex >= chunkSize){
                        finishSending = true;
                    }else{
                        canContinueSending = true;
                    }
                }
                // SRONG TIN - 15.05.2023 - US-0013428
                if(finishSending && isIT){
                    isRollBack = false;
                    createSellerCom();
                }


        }catch (Exception ex) { 
            isError = true;  
            messageInfoType = MESSAGE_INFO_ERROR;
            errorMessage = ex.getMessage(); 
            errorMessageDetail = ex.getStackTraceString();
            System.debug('nsp: ex == '+ex.getMessage()); 
           // ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,errorMessage));
        }

        return null;

    }
    // SRONG TIN - 19.09.2023 - US-0014161
    public PageReference createSellerCom() {
        //
        Savepoint sp = Database.setSavepoint();
        List<Database.SaveResult> insertResults = new List<Database.SaveResult>();
        try{
            if(!isIT)return null;
            RecordType rectypeDeal = ApexUtil.getRecordTypeByName('Seller_Communication__c','Deals');
            List<Seller_Communication__c> lstSellerComToCreated = new List<Seller_Communication__c>();
            Boolean is_Success = false;
            Boolean is_Error = false;
            for(Contact cont : [select Id,Email,AccountId from Contact where ((RecordType.DeveloperName = 'EBH_DWH' AND AccountId IN: sSellerId) OR (Active_Community_User__c = true AND (AccountId IN: sSellerId OR AccountId IN: sSellerPortalGroupId))) AND Account.SP_Deals__c = :FULL_ACCESS AND AccountId != null]){
                accountIds.add(cont.AccountId);
                String dcaId = mapDCAIds.get(cont.AccountId) != null?mapDCAIds.get(cont.AccountId):'';
                Seller_Communication__c sellerCom = new Seller_Communication__c();
                sellerCom.RecordTypeId = rectypeDeal.Id;
                sellerCom.Contact__c = cont.Id;
                sellerCom.Region__c = 'IT';
                sellerCom.Platform__c = 'Seller Portal';
                if(dcaId != ''){sellerCom.PM_Deal__c = dcaId;}
                sellerCom.Name = SELCOM_DEALS_CONTRACT_NAME;
                sellerCom.Email_Template__c = SELCOM_DEAL_CONTRACT_APPROVAL_EMAILTEMPLATE;
                sellerCom.Account__c = cont.AccountId;
                if(cont.Email == null){sellerCom.Message_Log__c = SELLERCOM_EMAIL_EMPTY;}
                lstSellerComToCreated.add(sellerCom);
            }
            if(!lstSellerComToCreated.isEmpty()){
                insertResults = Database.insert(lstSellerComToCreated, false);
                for(Integer i=0;i<insertResults.size();i++){
                    if (insertResults.get(i).isSuccess()){
                       // inserted sellerCom
                       is_Success = true;
                    }else if (!insertResults.get(i).isSuccess()){
                    // DML operation failed
                    is_Error = true;
                    Database.Error error = insertResults.get(i).getErrors().get(0);
                    String failedDML = error.getMessage();
                    errorMessage += insertResults.get(i).getId() +' '+ failedDML+' <br/> ';
                    }
                }
                if(is_Error){messageInfoType = MESSAGE_INFO_ERROR;isShowMessageInfo = true;}
                if(is_Success){messageInfoType = MESSAGE_INFO_SUCCESS;}
                if(is_Error && is_Success){messageInfoType = MESSAGE_INFO_WARNING;}
                
            } 

        }catch( DmlException ex ){
            isShowMessageInfo = true;  
            errorMessage += ex.getDmlMessage(0);
            errorMessageDetail = ex.getStackTraceString();
        }catch (Exception ex) { 
            isShowMessageInfo = true;  
            errorMessage += ex.getMessage(); 
            errorMessageDetail = ex.getStackTraceString();
           // ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,errorMessage));
        }

        

        if(isRollBack){
           Database.rollBack(sp);
        }

        return null;

    }

    private static Boolean checkingHasNoPermission() {

        Boolean hasNoPermission = false;

        String currentUserId = UserInfo.getUserId();
        String NAprofile = ApexUtil.getProfileByName(NA_PROFILE).Id;
        String StandardUserProfile = ApexUtil.getProfileByName(STANDARD_USER_PROFILE).Id;
        Boolean isAdmin = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
        Boolean isNA = UserInfo.getProfileId().equals(NAprofile);
        Boolean isStandardUserProfile = UserInfo.getProfileId().equals(StandardUserProfile);

        List<PermissionSetAssignment> listPSA = Database.query(US_MANAGE_DEAL_PERM);
        
        if( (!isAdmin && !isNA && !isStandardUserProfile) || ((isNA || isStandardUserProfile) && listPSA.isEmpty())){
            hasNoPermission = true;
        }

        return hasNoPermission;
    }


    /*********************************************************************************************************************************
    @ Method:         sendEmailToSellerAction
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0009436
                      use client side to send email to seller. this is to fix the error CPU limit
    @ Event:		  when user click button 'Send to Seller'
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	list id of deal, list id of deal to send email later,
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  27.04.2021 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  24.06.2021 / Sophal Noch / US-0009754 modifed the method to be non-static method because we stop using remote action in vf page
    *********************************************************************************************************************************/  
    public Pagereference sendEmailToSellerAction() {

        try{
            if(!setDealIdToSendEmail.isEmpty()){
                DD_SendToSellerHelper.sendApprovalToExternalSeller(doQueryDeals(dealNA, ALLOWED_STATUS, setDealIdToSendEmail));
            }
        }catch (Exception ex) { isError = true;  errorMessage = ex.getMessage(); System.debug('nsp: email sending err == '+ex.getMessage()); ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));}
        return null;


    }

    public Pagereference prepareToSend() {return null;}  // Sophal:28/06/2021: to make it work on firefox, call empty method first

    private static List<EBH_Deal__c> doQueryDeals(Id dealNA, Set<String> status, Set<Id> setDealId ){

        // Sophal:27/04/2021: US-0009436 query deal when send to seller and when to send email
        List<EBH_Deal__c> lstDeals = new List<EBH_Deal__c>();
        if(!setDealId.isEmpty()){
            
            lstDeals = [ Select Id,EBH_Status__c,
            EBH_DealStartDate__c,
            EBH_DealStartTime__c,
            Seller_Approver_1__c, 
            Seller_Approver_2__c,
            Seller_Approver_3__c,
            Seller_Approver_4__c,
            Seller_Approver_5__c,
            Seller_Approver_1_Email__c,
            Seller_Approver_2_Email__c,
            Seller_Approver_3_Email__c,
            Seller_Approver_4_Email__c,
            Seller_Approver_5_Email__c,
            Name,
            Current_Digest__c,
            Deal_Contract_Agreement__c,
            Deal_Contract_Agreement__r.Current_Digest__c, 
            Deal_Contract_Agreement__r.RecordtypeId, 
            EBH_BusinessName__c,
            EBH_BusinessName__r.Seller_Portal_Group__c,
            Deal_Contract_Seller_Name__c,
            EBH_DealSiteId__c,
            SiteURL__c,
            OwnerId,
            Owner.Name from EBH_Deal__c 
            Where  RecordTypeId =:dealNA
                    And id in : setDealId
                    And EBH_status__c in :status
                    Order by EBH_BusinessName__c
        ]; 
            
        }
        return lstDeals;

    }


    private Map<String,Map<Id, EBH_Deal__c>> loadDeals(Set<Id> setDealId) {

        // Sophal:27/04/2021: US-0009436 loadDeals to send to seller
        // Sophal:24/06/2021: US-0009754 change to non static method
        Map<String,Map<Id, EBH_Deal__c>> res = new  Map<String,Map<Id, EBH_Deal__c>>();
        Set<String> statusToAllowed = isIT?ALLOWED_STATUS_IT:ALLOWED_STATUS;
        for (EBH_Deal__c d : doQueryDeals(dealNA, statusToAllowed, setDealId)) {
            // 28.05.2021 / Sophal Noch / US-0009533 optimize way to store variable in collection 
            if(!res.containsKey(d.EBH_Status__c)){
                res.put(d.EBH_Status__c,new Map<Id,EBH_Deal__c>());
            }
            res.get(d.EBH_Status__c).put(d.Id,d);
             
        }                                       
        return res;
 }
    
     // Sophal:27/04/2021: US-0009436 disable because we use client side to fix cpu limit

    // private Map<String,List<EBH_Deal__c>> loadDeals() {
    //        ID dealNA = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
           
    //        Map<String,List<EBH_Deal__c>> res = new  Map<String,List<EBH_Deal__c>>();
    //        Set<String> status = new Set<String> {INTERNALLY_APPROVED,SENT_TO_SELLER,EXPIRED};
            
    //        for (EBH_Deal__c d : [Select Id,EBH_Status__c,
    //                                 Seller_Approver_1__c, 
    //                                 Seller_Approver_2__c,
    //                                 Seller_Approver_3__c,
    //                                 Seller_Approver_4__c,
    //                                 Seller_Approver_5__c,
    //                                 Name, 
    //                                 Deal_Contract_Agreement__c,
    //                                 Deal_Contract_Agreement__r.Current_Digest__c, 
    //                                 EBH_BusinessName__c,
    //                                 OwnerId,
    //                                 Owner.Name from EBH_Deal__c 
    //                                             where  RecordTypeId =:dealNA
    //                                                     and id in : selectedDeal
    //                                                     and EBH_status__c in :status
    //                                                     order by EBH_BusinessName__c]) 
    //                                                     {
                    
                        
    //                     List<EBH_Deal__c> l = res.get(d.EBH_Status__c);
                        
    //                     if (l==null) {
    //                         l = new List<EBH_Deal__c>();
    //                     }

    //                     l.add(d);
                        
    //                     res.put(d.EBH_Status__c,l);
                
    //         }
         
                                                        
    //          return res;
    // }
    
    // update deals to 'Sent to Seller'     
    // SRONG TIN - 19.09.2023 - US-0014161
    public PageReference updateDeals(List<EBH_Deal__c> deals) {
    	 
        try{
            Boolean is_Success = false;
            Boolean is_Error = false;
            List<EBH_Deal__c> dealstobeupdated = new List<EBH_Deal__c>();
             for (EBH_Deal__c d : deals) {
             	//if (sellersent.contains(d.EBH_BusinessName__c)) {
             		d.EBH_Status__c=SENT_TO_SELLER;
                	dealstobeupdated.add(d);
             	//}
              }
                    
             if (!dealstobeupdated.isEmpty()) {
                List<Database.SaveResult> updateResults = Database.update(dealstobeupdated, false);
                
                for(Integer i=0;i<updateResults.size();i++){
                    if (updateResults.get(i).isSuccess()){
                    // inserted sellerCom
                    is_Success = true;
                    }else if (!updateResults.get(i).isSuccess()){
                    // DML operation failed
                    is_Error = true;
                    Database.Error error = updateResults.get(i).getErrors().get(0);
                    String failedDML = error.getMessage();
                    errorMessage += updateResults.get(i).getId() +' '+ failedDML+' <br/> ';
                    }
                }
                if(is_Error){messageInfoType = MESSAGE_INFO_ERROR;isShowMessageInfo = true;}
                if(is_Success){messageInfoType = MESSAGE_INFO_SUCCESS;}
                if(is_Error && is_Success){messageInfoType = MESSAGE_INFO_WARNING;}
              }
        }catch( DmlException ex ){
            isShowMessageInfo = true;  
            errorMessage += ex.getDmlMessage(0);
            errorMessageDetail = ex.getStackTraceString();
        }catch (Exception ex) { 
            isShowMessageInfo = true;  
            errorMessage += ex.getMessage(); 
            errorMessageDetail = ex.getStackTraceString();
           // ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,errorMessage));
        }
          	
        return null;
          
    }

    public PageReference cancel(){
        return setCon.cancel();
    }
}