/**
Create VF custom action on Deals called Submit for Approval

Multiple Deals can be selected from List view

VF action will take deals selected and submit into approval process created in 00199654
*/


/*********************************************************************************************************************************
@ Class:          SubmitForApprovalController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0008230 
                  It was migrated from join instance with original name: DD_SubmitForApprovalController.
                  Controller Class for vf page SubmitForApprovalPage
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  07.10.2020 / Sophal Noch / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  17.11.2020 / Sophal Noch / US-0008618  Modified the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  06.04.2021 / Sophal Noch / US-0009353  Modified the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  01.11.2021 / Loumang SENG / US-0010649-[NA Deals] Deals for CA Sellers need to go through CA Approval Process for US Site
*********************************************************************************************************************************/
public without sharing class SubmitForApprovalController {
    
    public static String AP_PREFIX = 'DD_AP_';
    
    // public List<EBH_Deal__c> selectedDeal {get;set;}
    public Integer dealSize {get;set;}
    public Boolean displayPopup {get; set;}
    ApexPages.StandardSetController setCon;
    public Boolean isSuccess;
    public String dealNARecordTypeId {get; set;}
    public Boolean isNotebayNa {get;set;}
    ///apex/DD_MassApprovals?sfdc.tabName=01r1F000000DHSG
    public Boolean hasNoPermission {get;set;}

    // public String chunkedListDeal {get;set;}

    public List<Id> lstSelDid {get{return lstSelDid = (lstSelDid !=null ? lstSelDid : new List<Id>());} set;}

    private final static String DEAL_SITE_CA_API_NAME = '2';

    private final static String CA_DEALS_APPROVERS_QUEUES_API = 'CA_Deals_Approvers';


    private final static Set<String> SET_PNAME = new Set<String>{
        'US_Manage_Deals', 'Deal_Start_End_time_fileds'
    };

    public static Map<Id,UserApprovalDetail> testMapUserIdToDeal = new map<Id,UserApprovalDetail>();
    

    public final static String DEAL_IN_APPROVAL_STATUS = 'In Approval';

    public final static String MERCHANT_APPROVER_EMAIL_BINDING = '{!EBH_Deal__c.Merchant_Approver__c}';
    public final static String INSTANCE_URL_EMAIL_BINDING = '{!EBH_Deal__c.Link}';
    public final static String NA_DEALS_NOTIFY_APPROVALS_TEMPLATE = 'NA_Deals_Notify_Approvals';

    public final static String VERTICAL_EMAIL_BINDING = '{!EBH_Deal__c.EBH_Vertical__c}';
    public final static String HTML_LINE_BREAK = '<br><br>';
    public final static String VERTICAL_NUMBER_BINDING = '{!Vertical_Number}';
    public final static String CATEGORY_NUMBER_BINDING = '{!Category_Number}';
    public final static String TOTAL_NUMBER_BINDING = '{!Total_Number}';
    public final static String VERTICAL_CATEGORY_DEAL_APPROVAL_MSG = '- You have '+TOTAL_NUMBER_BINDING + ' "' + VERTICAL_NUMBER_BINDING+'" Vertical and "'+CATEGORY_NUMBER_BINDING+'" Category deal(s) for approval.';
    public final static String TOTAL_DEAL_APPROVAL_MSG = 'Total: ' + TOTAL_NUMBER_BINDING+' deal(s) for approval.';


    private final static String PRO_INS_STATUS_PENDING = 'Pending';
    private final static String APPR_PROC_COMMENT = 'Submitted for approval. Please approve.';

    private final Integer CHUNK_SIZE_LIMIT = Integer.valueOf(System.Label.DEAL_APPROVAL_CHUNK_SIZE_LIMIT);


    public Map<String,Object> mapChunkedDeal {get{return mapChunkedDeal = (mapChunkedDeal !=null ? mapChunkedDeal : new Map<String,Object>());} set;}
    public Integer chunkIndex {get{return chunkIndex = (chunkIndex !=null ? chunkIndex : 0);} set;}
    public Integer chunkSize {get{return chunkSize = (chunkSize !=null ? chunkSize : 0);} set;}
    public Boolean canContinueSending {get;set;}
    public Boolean finishSending{get{return finishSending = (finishSending !=null ? finishSending : false);} set;}
    public String errorMessage {get;set;}
    public Boolean isError {get;set;}

    @TestVisible private Set<Id> setDealIdToSendEmail = new Set<Id>();

    //loumang:01-11-2021: US-0010649
    private final static Set<String> SELLER_PRIMARY_SITE = new Set<String>{'Canada','Canada (French)'};
    

    

    /*********************************************************************************************************************************
    @ Method:         SubmitForApprovalController
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008230
    @                 It was migrated from join instance with original name: DD_SubmitForApprovalController.DD_SubmitForApprovalController
    @
    @                 As a...
    @                 US Standard User with permission set: 'US Manage Deals'
    @                 Want to...
    @                 be able to submit a valid US CA Deal record with status='New' or 'Negotiating' for the Internal eBay Approval process for Deals
    @                 So that...
    @                 when the Deal is approved by the internal eBay Approvers it can be sent to the Seller for Approval.
    @                 Description
    @                 Summary: Ability to submit a US/CA Deal record with recordtype = 'NA Deal' for Internal eBay Approval
    @                 AC 1)
    @                 As a US Standard User with permission sets: 'US Manage Deals' + 'Deal Start/End time fields'
    @                 When I go to a list view which contains deals with the status = 'New' or 'Negotiating' I can see an action button 'Submit for Approval' I can select multiple deals using the list view check boxes, and I am able to initiate the internal Approval process for the open Deal record by using the button. 
    @                 AC 2)
    @                 After submitting the Deal records for external Seller Approval the system will update all submitted Deal records' Status field to 'In Approval'. The system will then group the Deals by each Approver and send the Approver a single email notification per submitted batch informing them that they have Deals pending their approval. The notification should inform the Approver the number of Deals which they need to approve along the the Deals' corresponding Vertical and Category.
    @                 AC 3)
    @                 The 'Submit for Approval' button should only be usable to the 'US Manage Deals' permission set. If user on different permission sets or profile Error message will be displayed stating 'This functionality is not available to your region.'
    @                 AC 4)
    @                 Turn off standard notifications for Approval Process.  See Technical Description for details.
    @ Event:		  when DD_SubmitForApprovalPage init
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.10.2020 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public SubmitForApprovalController(ApexPages.StandardSetController controller) {

        // Boolean isAdmin = Userinfo.getprofileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID;
        // List<PermissionSetAssignment> listPSA = [
        //     Select Id FROM PermissionSetAssignment Where AssigneeId =:UserInfo.getUserId() AND PermissionSet.Name IN :SET_PNAME
        // ];

        // if(!isAdmin && listPSA.size() != 2){hasNoPermission = true; return;}

        hasNoPermission = checkPermission();
        if(hasNoPermission){return;}
        
        isNotebayNa = false;
        setCon = controller;

        dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get('Deal_V2').getRecordTypeId();  

        // selectedDeal = controller.getSelected();
        // for(EBH_Deal__c deal : selectedDeal){
        //     if(deal.RecordTypeId != null && dealNARecordTypeId != deal.RecordTypeId){
        //         isNotebayNa = true;
        //     }
        // }
        // dealSize = selectedDeal.size();
        for(EBH_Deal__c deal : ((List<EBH_Deal__c>)controller.getSelected())){
            if(deal.RecordTypeId != null && dealNARecordTypeId != deal.RecordTypeId){
                isNotebayNa = true;
            }
            lstSelDid.add(deal.Id);
        }
        dealSize = lstSelDid.size();

        if (dealSize>0) {
            displayPopup = true;
        }
        
        // chunkedListDeal = JSON.serialize(ApexUtil.chunkList(lstSelDid,CHUNK_SIZE_LIMIT));

        mapChunkedDeal = ApexUtil.chunkList(lstSelDid,CHUNK_SIZE_LIMIT);
        chunkSize = (Integer)mapChunkedDeal.get('chunkSize');

        isSuccess = false;
    }

    private static Boolean checkPermission(){

        //Sophal:07/04/2021:US-0009353 check permission

        Boolean permNotFound = false;

        Boolean isAdmin = Userinfo.getprofileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID;
        List<PermissionSetAssignment> listPSA = [
            Select Id FROM PermissionSetAssignment Where AssigneeId =:UserInfo.getUserId() AND PermissionSet.Name IN :SET_PNAME
        ];
        if(!isAdmin && listPSA.size() != 2){permNotFound = true;}

        return permNotFound;
    }
    
    /**
    * Approval action
    */

    /*********************************************************************************************************************************
    @ Method:         submitForApproval
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008230
                      It was migrated from join instance with original name: DD_SubmitForApprovalController.submitForApproval
    @                 submit multiple deal for approval
    @ Event:		  when user click button 'Confirm mass submit for approval'
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.10.2020 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06.04.2021 / Sophal Noch / US-0009353 disable we use remote method from client side to avoiding error cpu limit
     ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  11.08.2021 / Sophal Noch / US-0009771 stop using remote method, so reuse this method again
    *********************************************************************************************************************************/
    public PageReference submitForApproval() {

        canContinueSending = false;

        // we handle 2 blocs
     
        // Deal to start approval process
        // Deal in pending approval - need to resend email
        Set<Id> setDealSubmForApprId = new  Set<Id>();
        List<Id> listDealApprReminderId = new List<Id>();
        List<User> listUser = new List<User>(); // US-0008618 list of users who are merchant or director
        Map<Id, EBH_Deal__c> mapDeal = new Map<Id, EBH_Deal__c>();

        if(chunkIndex < chunkSize && !finishSending){

            try{

                List<List<Object>> listAllDealChunk = (List<List<Object>>)mapChunkedDeal.get('listAllChunk');
                    
                List<Id> listDealId = new List<Id>();
                for(Object objId : listAllDealChunk[chunkIndex]){
                    listDealId.add((Id)objId);
                }

                mapDeal = getSubmittingListDeal(listDealId,dealNARecordTypeId);
                listUser = getApproverFromListDeal(mapDeal, setDealSubmForApprId, listDealApprReminderId, listUser);
                setDealIdToSendEmail.addAll(listDealApprReminderId);
    
            }catch (Exception ex) {isError = true;  errorMessage = ex.getMessage(); System.debug('nsp: ex 1== '+ex.getMessage()); ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));}
            
    
            // US-0008618 use 2 try-catch because if code in second try-catch fail, we can still update back the users notification setting.
            try{
            
                if (!setDealSubmForApprId.isEmpty() && !listUser.isEmpty()) {
    
                    updateUserNotification(listUser,true);
                    
                    List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
                    Id userId = UserInfo.getUserId();
                    for(Id dealId :setDealSubmForApprId){
                        // Create an approval request for the Deal
                        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                        req.setComments(APPR_PROC_COMMENT);
                        req.setObjectId(dealId);
                        req.setSubmitterId(userId);
                        requests.add(req);
                    
                    }
    
                    if(!requests.isEmpty()){
                        Approval.ProcessResult[] processResults = null;
                        EBH_UserTriggerHandler.byPassUserTrigger = true;
                        processResults = Approval.process(requests, true);
                        setDealIdToSendEmail.addAll(setDealSubmForApprId);
                    }
                
                    updateUserNotification(listUser,false);
    
                }

                chunkIndex++;
                if(chunkIndex >= chunkSize){
                    finishSending = true;
                }else{
                    canContinueSending = true;
                }
                
            }catch (Exception ex) {
                if (!setDealSubmForApprId.isEmpty()) { updateUserNotification(listUser,false); }  isError = true;  errorMessage = ex.getMessage(); System.debug('nsp: ex 2 == '+ex.getMessage()); ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage())); 
            }


        }



        return null;

    }

    // public PageReference cancel(){
    //     return setCon.cancel();
    // }

    /*********************************************************************************************************************************
    @ Method:         submitForApproval
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0009353
                      use client side to send submit deal for approval. this is to fix the error CPU limit
    @ Event:		  when user click button 'Confirm mass submit for approval'
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	list id of deal, NA deal record type, list id of deal used to send email later
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06.04.2021 / Sophal Noch / Created the method.
    @ Change history:  11.08.2021 / Sophal Noch / US-0009771 stop using remote method, so disable for now
    *********************************************************************************************************************************/    
    // @RemoteAction
    // public static Map<String,Object> submitForApproval(List<Id> listDealId, Id dealRtId, List<Id> listDealApprReminderId) {

    //     Map<String,Object> mapResult = new Map<String,Object>();

    //     // we handle 2 blocs
     
    //     // Deal to start approval process
    //     // Deal in pending approval - need to resend email
    //     Set<Id> setDealSubmForApprId = new  Set<Id>();
    //     List<User> listUser = new List<User>(); // US-0008618 list of users who are merchant or director
    //     Map<Id, EBH_Deal__c> mapDeal = new Map<Id, EBH_Deal__c>();

    //     try{

    //         Boolean permNotFound = checkPermission();
    //         if(permNotFound){mapResult.put('status', 'ko');mapResult.put('error', Label.Error_No_Permission_To_Submit_For_Approval); return mapResult;}

    //         mapDeal = getSubmittingListDeal(listDealId,dealRtId);
    //         listUser = getApproverFromListDeal(mapDeal, setDealSubmForApprId, listDealApprReminderId, listUser);

    //     }catch (Exception ex) {mapResult.put('status', 'ko');mapResult.put('error', ex.getMessage()); return mapResult;}
        
    //     // System.debug('nsp: listUser = '+listUser);
    //     // System.debug('nsp: mapDeal = '+mapDeal);
    //     // System.debug('nsp: setDealSubmForApprId = '+setDealSubmForApprId);
    //     // System.debug('nsp: listDealApprReminderId = '+listDealApprReminderId);

    //     // US-0008618 use 2 try-catch because if code in second try-catch fail, we can still update back the users notification setting.
    //     try{
        
    //     	if (!setDealSubmForApprId.isEmpty() && !listUser.isEmpty()) {

    //             updateUserNotification(listUser,true);
                
    //             List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
    //             Id userId = UserInfo.getUserId();
    //             for(Id dealId :setDealSubmForApprId){
    //                 // Create an approval request for the Deal
    //                 Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    //                 req.setComments(APPR_PROC_COMMENT);
    //                 req.setObjectId(dealId);
    //                 req.setSubmitterId(userId);
    //                 requests.add(req);
                
    //             }

	//             if(!requests.isEmpty()){
	//                 Approval.ProcessResult[] processResults = null;
    //                 EBH_UserTriggerHandler.byPassUserTrigger = true;
	//                 processResults = Approval.process(requests, true);
    //                 listDealApprReminderId.addAll(setDealSubmForApprId);
	//             }
            
    //             updateUserNotification(listUser,false);

    //     	}
        	
    //         mapResult.put('listDealApprReminderId', listDealApprReminderId);
    //         mapResult.put('status', 'ok');
            
    //     }catch (Exception ex) {

    //         if (!setDealSubmForApprId.isEmpty()) { updateUserNotification(listUser,false); } mapResult.put('status', 'ko'); mapResult.put('error', ex.getMessage());
            
    //     }

    //     return mapResult;

    // }

    private static Map<Id,EBH_Deal__c> getSubmittingListDeal(List<Id> listDealId, Id dealRtId){

        //Sophal:06/04/2021:US-0009353
        
        return new Map<Id, EBH_Deal__c>([select id,EBH_BusinessName__r.EBH_PrimarySite__c,EBH_Status__c,Merchant_Approver__c, Director__c, EBH_Vertical__c,EBH_Category__c,EBH_DealSiteId__c, RecordTypeId from EBH_Deal__c 
                                                where Id IN: listDealId and 
                                                RecordTypeId =: dealRtId]);
    }

    private static List<User> getApproverFromListDeal(Map<Id, EBH_Deal__c> mapDeal, Set<Id> setDealSubmForApprId, List<Id> listDealApprReminderId, List<User> listUser){
        //Sophal:06/04/2021:US-0009353
        if(!mapDeal.isEmpty()){

            Boolean hasCaDeal = false;

            Set<Id> setApproverId = new Set<Id>();
            for (EBH_Deal__c d : mapDeal.values()) {
        
                if (d.EBH_Status__c == DEAL_IN_APPROVAL_STATUS)	 {
                    listDealApprReminderId.add(d.Id);
                }			
                else {
                    setDealSubmForApprId.add(d.Id);
                    //Loumang:01-11-2021: US-0010649
                    if(d.EBH_DealSiteId__c != DEAL_SITE_CA_API_NAME && !SELLER_PRIMARY_SITE.contains(d.EBH_BusinessName__r.EBH_PrimarySite__c)){ // 04.06.2021 / Sophal Noch / US-0009606 Ignore CA Deal because CA deal has Queue as approver in the first step
                        if(d.Merchant_Approver__c != null){
                            setApproverId.add(d.Merchant_Approver__c);
                        }
                    }else{
                        hasCaDeal = true;
                    }

                }
                            
            }

            if(hasCaDeal){  // 04.06.2021 / Sophal Noch / US-0009606 If CA deal, Get user from Queue 'CA_Deals_Approvers'

                for (GroupMember gm : [Select UserOrGroupId, GroupId FROM GroupMember WHERE Group.Type='Queue' AND Group.DeveloperName =: CA_DEALS_APPROVERS_QUEUES_API]) {
                    setApproverId.add(gm.UserOrGroupId);
                }
            }

            // System.debug('nsp: setApproverId = '+setApproverId);

            if (!setDealSubmForApprId.isEmpty() && !setApproverId.isEmpty()) {
                listUser = [Select Id,UserPreferencesReceiveNoNotificationsAsApprover,UserPreferencesReceiveNotificationsAsDelegatedApprover From User WHERE Id IN : setApproverId];
            }


            
        }

        return listUser;
    }


    /*********************************************************************************************************************************
    @ Method:         notifyAprroversInDeals
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0009353 send email for approver from the submitted deal
    @ Event:		  when user click button 'Confirm mass submit for approval'
    ----------------------------------------------------------------------------------------------------------------------------------    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	  list id of deal used to send email, NA deal record type,
     ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06.04.2021 / Sophal Noch / Created the method.
    @ Change history:  11.08.2021 / Sophal Noch / US-0009771 stop using remote method, so update method to use normal vf page apex method 
    *********************************************************************************************************************************/    
    public Pagereference notifyApproversInDeals(){

        try{
            if (!setDealIdToSendEmail.isEmpty()) {

                List<ProcessInstanceWorkitem> lstPIWI = [SELECT OriginalActorId, processInstance.TargetObjectId FROM ProcessInstanceWorkitem 
                                        WHERE processInstance.TargetObjectId IN:setDealIdToSendEmail 
                                        AND ProcessInstance.Status = :PRO_INS_STATUS_PENDING];

                Map<Id, EBH_Deal__c> mapDeal = !lstPIWI.isEmpty() ? getSubmittingListDeal(new List<Id>(setDealIdToSendEmail), dealNARecordTypeId) : null; 
                
                if(mapDeal != null && !mapDeal.isEmpty()){

                    Set<Id> sMAId = new Set<Id>();
                    
                    Map<Id,UserApprovalDetail> mapUserIdToDeal = new map<Id,UserApprovalDetail>();
        
                    initUserApprovalDetail(lstPIWI, mapDeal, sMAId, mapUserIdToDeal); //US-0008618

                    if(Test.isRunningTest()){testMapUserIdToDeal = mapUserIdToDeal;}
        
                    sendEmaiToApprovers(sMAId,mapUserIdToDeal); // US-0008618
                }

            }
        }catch (Exception ex) { isError = true;  errorMessage = ex.getMessage(); System.debug('nsp: email sending err == '+ex.getMessage()); ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));}

        return null;
        
    }


    public PageReference cancel(){
        return setCon.cancel();
    }


    /*********************************************************************************************************************************
    @ Method:         notifyApprovers
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008230
    @                 It was migrated from join instance with original name: DD_SendToSellerHelper.notifyApprovers
    @  
    @                 method for notifying the approver using approval process
    @ Event:		  it called from SubmitForApprovalController.submitForApproval
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	list of approval process
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.10.2020 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.11.2020 / Sophal Noch / US-0008618 Update the method. move code to new method so it can be reused in other class.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06.04.2021 / Sophal Noch / US-0009353 disable because the method 'submitForApproval()' who uses this method is disable.
    *********************************************************************************************************************************/
    // private static void notifyApprovers(List<ProcessInstanceWorkitem> lstPIWI, Map<Id, EBH_Deal__c> mapDeal) {
    //     // SetId of Merchant Approver
    //         Set<Id> sMAId = new Set<Id>();
    //         Map<Id,UserApprovalDetail> mapUserIdToDeal = new map<Id,UserApprovalDetail>();

    //         initUserApprovalDetail(lstPIWI, mapDeal, sMAId, mapUserIdToDeal); //US-0008618

    //         // System.debug('nsp: after group, sMAIdis '+sMAId);


    //         if(Test.isRunningTest()){testMapUserIdToDeal = mapUserIdToDeal;}

    //         sendEmaiToApprovers(sMAId,mapUserIdToDeal); // US-0008618

    // }

    /*********************************************************************************************************************************************************************
    @ Method:         sendEmaiToApprovers
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008618 so it can be reuseable.
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	Set User Id, Map class UserApprovalDetail
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.11.2020 / Sophal Noch / Created the method.
    ***********************************************************************************************************************************************************************/
    public static void sendEmaiToApprovers(Set<Id> sMAId, Map<Id,UserApprovalDetail> mapUserIdToDeal){
        //  US-0008618 this method is also reused in class EBH_DealTriggerHandler, DD_MassApprovals

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        // String templateName = 'NA_Deals_Notify_Approvals';
        for (User u : [SELECT Email, Name FROM User WHERE Id IN:sMAId]) {
            Map<String,String> binding = new Map<String,String>();
            binding.put(MERCHANT_APPROVER_EMAIL_BINDING, u.Name);
            binding.put(INSTANCE_URL_EMAIL_BINDING, URL.getOrgDomainUrl().toExternalForm());
            String numberOfDealTemplate = '';
            if(mapUserIdToDeal.containsKey(u.Id)){
                numberOfDealTemplate = getFormattedUserApprovalDetail(mapUserIdToDeal.get(u.Id));
            }
            binding.put(VERTICAL_EMAIL_BINDING, numberOfDealTemplate);
            emails.add(ApexUtil.prepareEmail(null, new String[] {u.Email}, null, NA_DEALS_NOTIFY_APPROVALS_TEMPLATE, null, binding,null,null));
        }


        // System.debug('nsp: approval emails '+emails);
        
        if (!emails.isEmpty()) {
            ApexUtil.sendEmail(emails);
        }


    }



    /*********************************************************************************************************************************************************************
    @ Method:         initUserApprovalDetail
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008618 so it can be reuseable.
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	list of ProcessInstanceWorkitem, map deal related to ProcessInstanceWorkitem, Set Id of User for Store Id, Map class UserApprovalDetail to store value
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.11.2020 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.14.2021 / Sophal Noch / US-0009353 change method name from getUserApprovalDetail to initUserApprovalDetail
    ***********************************************************************************************************************************************************************/
    public static void initUserApprovalDetail(
        List<ProcessInstanceWorkitem> lstPIWI,
        Map<Id, EBH_Deal__c> mapDeal,
        Set<Id> sMAId,
        Map<Id,UserApprovalDetail> mapUserIdToDeal
    ){

        //  US-0008618 this method is also reused in class DD_MassApprovals

        Set<Id> sQueuIds = new Set<Id>();

        Map<Id,List<ProcessInstanceWorkitem>> mapQueuIdToLstPiwi = new Map<Id,List<ProcessInstanceWorkitem>>();

        for (ProcessInstanceWorkitem piwi : lstPIWI) {

            if (String.valueOf(piwi.OriginalActorId).startsWith('00G')) {
                sQueuIds.add(piwi.OriginalActorId);

                if(mapQueuIdToLstPiwi.containsKey(piwi.OriginalActorId)){
                    mapQueuIdToLstPiwi.get(piwi.OriginalActorId).add(piwi);
                }else{
                    mapQueuIdToLstPiwi.put(piwi.OriginalActorId,new List<ProcessInstanceWorkitem>{piwi});
                }
                
            }else{
                sMAId.add(piwi.OriginalActorId);

                EBH_Deal__c eachDeal = mapDeal.get(piwi.processInstance.TargetObjectId);
                if(eachDeal != null){
                    mapUserIdToDeal = setUpUserApprovalDetail(piwi.OriginalActorId,eachDeal,mapUserIdToDeal);
                }

            }

        }


        // System.debug('nsp: sMAIdis '+sMAId);
        // System.debug('nsp: sQueuIds '+sQueuIds);

        for (GroupMember gm : [Select UserOrGroupId,GroupId FROM GroupMember 
                        WHERE Group.Type='Queue' 
                        AND GroupId in : sQueuIds]) {
            //
            if (String.valueOf(gm.UserOrGroupId).startsWith('005')) {
                sMAId.add(gm.UserOrGroupId);

                if(mapQueuIdToLstPiwi.containsKey(gm.GroupId)){

                    for (ProcessInstanceWorkitem piwi : mapQueuIdToLstPiwi.get(gm.GroupId)) {

                        EBH_Deal__c eachDeal = mapDeal.get(piwi.processInstance.TargetObjectId);
                        if(eachDeal != null){
                            mapUserIdToDeal = setUpUserApprovalDetail(gm.UserOrGroupId,eachDeal,mapUserIdToDeal);
                        }

                    }
                }
            }
        }


    }


    /*********************************************************************************************************************************
    @ Method:         updateUserNotification
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008618
    @                 AC1)When a set of Deals are 'Submitted for Approval' 
    @                 for the Deals Internal Approval process, only the custom email notification is sent, 
    @                 and not the standard Approval notifications. 
    @                 Code should temporarily suppress approval notifications and then reactivate once the process is completed and the single notification is sent.
    @                 This should be done for all approval levels.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	list of user to turn on or off notifcation, value to check the process should be turninig off/on notication
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  17.11.2020 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public static void updateUserNotification(List<User> listUser, Boolean turnOffNotify){
        
         //  US-0008618 this method is also reused in class DD_MassApprovals
        if(!listUser.isEmpty()){
            EBH_UserTriggerHandler.byPassUserTrigger = true;
            // US-0008618 turn off notification of users who are merchant or director.
            if(turnOffNotify){
                List<User> listUserToTurnoff = new List<User>();
                for(User u : listUser){
                    listUserToTurnoff.add(new User(Id = u.Id, UserPreferencesReceiveNoNotificationsAsApprover = true, UserPreferencesReceiveNotificationsAsDelegatedApprover = false));
                }
                update listUserToTurnoff;
    
            }else{
                // US-0008618 turn back on the notification of users who are merchant or director.
                update listUser;
                
            }

        }

    }

    // Sophal: 11.08.2021 : US-0009771 not use anymore because not using remote method anymore
    // @RemoteAction
    // public static Map<String,Object> remoteUpdateUserNotification(List<User> listUser, Boolean turnOffNotify){
        
         
        
    //     //Sophal:07/04/2021:US-0009353 when cpu limit error, use this json to turn back on the user's notification
    //     Map<String,Object> mapResult = new Map<String,Object>();
    //     try{

    //         Boolean permNotFound = checkPermission();
    //         if(permNotFound){mapResult.put('status', 'ko');mapResult.put('error', Label.Error_No_Permission_To_Submit_For_Approval); return mapResult;}

    //         if(!listUser.isEmpty()){

    //             List<User> listUserToUpdate = new List<User>();

    //             for(User eachUser : listUser){

    //                 listUserToUpdate.add(
    //                     new User(
    //                         Id = eachUser.Id,
    //                         UserPreferencesReceiveNoNotificationsAsApprover = eachUser.UserPreferencesReceiveNoNotificationsAsApprover,
    //                         UserPreferencesReceiveNotificationsAsDelegatedApprover = eachUser.UserPreferencesReceiveNotificationsAsDelegatedApprover
    //                     )
    //                 );
    //             }

    //             updateUserNotification(listUserToUpdate,turnOffNotify);

    //         }

    //         mapResult.put('status','ok');
    //     }catch (Exception ex) {mapResult.put('status', 'ko');mapResult.put('error', ex.getMessage());}

    //     return mapResult;
    // } 

    public static Map<Id,UserApprovalDetail> setUpUserApprovalDetail(Id userId, EBH_Deal__c eachDeal,Map<Id, UserApprovalDetail> mapUserIdToDeal){

        //  US-0008618 this method is also reused in class EBH_DealTriggerHandler
        String dealVertical = eachDeal.EBH_Vertical__c != null ? eachDeal.EBH_Vertical__c : '';
        String dealCategory = eachDeal.EBH_Category__c != null ? eachDeal.EBH_Category__c : '';

        VerticalAndCategory verticalAndCategory;
        if(mapUserIdToDeal.containsKey(userId)){

            verticalAndCategory  = mapUserIdToDeal.get(userId).mapVerticalAndCategory.get(dealVertical+'_'+dealCategory);
            if(verticalAndCategory != null){
                verticalAndCategory.size += 1;
            }else{
                verticalAndCategory = new VerticalAndCategory(dealVertical,dealCategory);
            }
            mapUserIdToDeal.get(userId).mapVerticalAndCategory.put(dealVertical+'_'+dealCategory,verticalAndCategory);
        }else{
            verticalAndCategory = new VerticalAndCategory(dealVertical,dealCategory);
            Map<String,VerticalAndCategory> mapVerticalAndCategory = new Map<String,VerticalAndCategory>();
            mapVerticalAndCategory.put(dealVertical+'_'+dealCategory,verticalAndCategory);
            mapUserIdToDeal.put(userId,new UserApprovalDetail(mapVerticalAndCategory));
        }

        return mapUserIdToDeal;
    }

    public static String getFormattedUserApprovalDetail(UserApprovalDetail userApprovalDetail){
        String numberOfDealMsg = '';

        Integer totalDealNumber = 0;

        if(!userApprovalDetail.mapVerticalAndCategory.isEmpty()){
            for(VerticalAndCategory verticalAndCategory : userApprovalDetail.mapVerticalAndCategory.values()){
                totalDealNumber += verticalAndCategory.size;
                numberOfDealMsg += VERTICAL_CATEGORY_DEAL_APPROVAL_MSG
                                    .replace(VERTICAL_NUMBER_BINDING, verticalAndCategory.vertical)
                                    .replace(CATEGORY_NUMBER_BINDING, verticalAndCategory.category)
                                    .replace(TOTAL_NUMBER_BINDING, verticalAndCategory.size+'');
                numberOfDealMsg += HTML_LINE_BREAK;
            }
            numberOfDealMsg += TOTAL_DEAL_APPROVAL_MSG.replace(TOTAL_NUMBER_BINDING, totalDealNumber+'');

        }

        return numberOfDealMsg;
    }

    public class UserApprovalDetail{
        public Map<String,VerticalAndCategory> mapVerticalAndCategory = new Map<String,VerticalAndCategory>();
        public UserApprovalDetail(Map<String,VerticalAndCategory> mapVerticalAndCategory){
            this.mapVerticalAndCategory = mapVerticalAndCategory;
        }
    }
    private class VerticalAndCategory{

        public String  vertical;
        public String category;
        public Integer size = 1;
        public VerticalAndCategory(String  vertical,String category){
            this.vertical = vertical;
            this.category = category;
        }

    }
    
  
}