/*********************************************************************************************************************************
@ Class:          DD_RecallDealsController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Controller Class for DD_RecallDeals.page
@ Description :   US-0008182 - [US]* Deals Mass Recall from Approval Process for Deals Managers
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  29.09.2020 / Sovantheany Dim / Created the class.
@ Change history:  27.07.2021 / SRONG TIN / update class.
@ Change history:  09.12.2024 / Davy Sorn / US-0015202 - 'Recall deals' button not working as expected
*********************************************************************************************************************************/
public without sharing class DD_RecallDealsController {
    ApexPages.StandardSetController setCon;
    public Boolean isNotSendToSellerOrInApproval {get;set;}
    public List<EBH_Deal__c> selectedDeal {get;set;}
    public Integer dealSize {get;set;}
    public Boolean displayPopup {get; set;}
    public Boolean hasNoPermission {get;set;}
    // SRONG TIN 27-July-2021, US-0009954: from Deal Retail Campaign related list
    public String dealRetailCampaignStatus {get;set;}
    public final string DEAL_WINDOW_RECORDTYPE = 'Deal_Campaign_V2';
    private final static String PERMISSION_NA_UNSUB_DEAL = 'eBay_NA_Manage_Unsub_Deals';
    public final string NA_UNSUB_DEAL_RECORDTYPE = 'Deal_V3';
    public final string STATUS_REJECTED = 'Rejected';
    public final string STATUS_CANCELLED = 'Cancelled';
    public Boolean isNotRejectedAndCancelled {get;set;}
    public Boolean isDealWindow {get;set;}
    public String parentId {get;set;}
    public Boolean isSTATUS_REJECTED {get;set;}
    public Boolean isSTATUS_CANCELLED {get;set;}
    // SRONG TIN 03-08-2021
    public Boolean isNotReviewStatus {get;set;}
    public final Set<String> STATUS_REVIEW = new Set<String>{'Ops Review','CM Review'};
    // SRONG TIN 28-July-2021, US-0009954
    @TestVisible private static Integer CHUNK_SIZE_LIMIT = 25;
    public Map<String,Object> mapChunkedDeal {get{return mapChunkedDeal = (mapChunkedDeal !=null ? mapChunkedDeal : new Map<String,Object>());} set;}
    public Integer chunkIndex {get{return chunkIndex = (chunkIndex !=null ? chunkIndex : 0);} set;}
    public Integer chunkSize {get{return chunkSize = (chunkSize !=null ? chunkSize : 0);} set;}
    public Boolean canContinueRecallDeals {get;set;}
    public Boolean finishRecallDeals{get{return finishRecallDeals = (finishRecallDeals !=null ? finishRecallDeals : false);} set;}
    public String errorMessage {get;set;}
    public Boolean isError {get;set;}
    


    //end US-0009954
    private final static String PERMISSION_BULK_UPLOAD_DEAL_US = 'US_Manage_Deals';
    private final static String PERMISSION_BULK_UPLOAD_DEAL_DATE_TIME = 'Deal_Start_End_time_fileds';
    private static Set<String> sPermissionDeal = new Set<String>{PERMISSION_BULK_UPLOAD_DEAL_US,PERMISSION_BULK_UPLOAD_DEAL_DATE_TIME,PERMISSION_NA_UNSUB_DEAL};
        
    public static final string SENT_TO_SELLER = 'Sent to Seller';
    public static final string IN_APPROVAL = 'In Approval';
    public static final string NEGOTIATING = 'Negotiating';
    public static final string INTERNALLY_APPROVED = 'Internally Approved';
    
    public static final string NA_DEAL_RECORDTYPE = 'Deal_V2';
    
    public DD_RecallDealsController(ApexPages.StandardSetController controller) {
        // SRONG TIN 27-July-2021, get Deal Retail Campaign Id from url
        isDealWindow = false;
        isError = false;
        isSTATUS_REJECTED = false;
        isSTATUS_CANCELLED = false;
        isNotReviewStatus = false;
        parentId = ApexPages.currentPage().getParameters().get('id');
        if(parentId != null && parentId.contains('a0u')){
            RecordType recDealWindow = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c',DEAL_WINDOW_RECORDTYPE);
            for(EBH_DealRetailCampaign__c drc: [SELECT Id,RecordTypeId,Status__c FROM EBH_DealRetailCampaign__c WHERE Id = :parentId]){
                if(drc.RecordTypeId == recDealWindow.Id){
                    isDealWindow = true;
                    dealRetailCampaignStatus = drc.Status__c; 
                    if(!STATUS_REVIEW.contains(drc.Status__c) ){
                        isNotReviewStatus = true;
                    }
                }
            }
        }
        // end
        isNotSendToSellerOrInApproval = false;
        hasNoPermission = false;
        setCon = controller;
        selectedDeal = controller.getSelected();
        Boolean hasNADealPermission = ApexUtil.checkPermissionSet(sPermissionDeal);
        Boolean isAdmin = Userinfo.getprofileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID;
        if(!hasNADealPermission && !isAdmin){
            hasNoPermission = true;
        }
        List<Id> lstAllDealIds = new List<Id>();
        for(EBH_Deal__c deal : [select EBH_Status__c from EBH_Deal__c where id IN: selectedDeal]){

            if(!isDealWindow && (deal.EBH_Status__c != SENT_TO_SELLER && deal.EBH_Status__c != IN_APPROVAL)){
                isNotSendToSellerOrInApproval = true;

            // SRONG TIN 27-July-2021, check if it Rejected,Cancelled
            }else if(isDealWindow && deal.EBH_Status__c == STATUS_REJECTED){
                isSTATUS_REJECTED = true;
            }else if(isDealWindow && deal.EBH_Status__c == STATUS_CANCELLED){
                isSTATUS_CANCELLED = true;
            }else if(isDealWindow && (deal.EBH_Status__c != STATUS_REJECTED && deal.EBH_Status__c != STATUS_CANCELLED)){
                // if deals status not Rejected,Cancelled 
                isNotRejectedAndCancelled = true;
            }
            //add all ids
            lstAllDealIds.add(deal.Id);
        }
        // SRONG TIN 27-July-2021,check if deals status selected have both Rejected,Cancelled
        if((isSTATUS_REJECTED && isSTATUS_CANCELLED)){
           isNotRejectedAndCancelled = true;
        }
        
        dealSize = selectedDeal.size();
        if (dealSize>0) {
            displayPopup = true;
        }
        // SRONG TIN 28-July-2021, US-0009954
        mapChunkedDeal = ApexUtil.chunkList(lstAllDealIds,CHUNK_SIZE_LIMIT);
        chunkSize = (Integer)mapChunkedDeal.get('chunkSize');
    }
    
    /*****************************************************************************************************************************
    @ Method:       recallDealsAction
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0008182 - [US]* Deals Mass Recall from Approval Process for Deals Managers
    @ Event:		after click button Recall
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	no
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.09.2020 / Sovantheany Dim / Created the method.
    @ Change history: 27.07.2021 / SRONG TIN / update method.
    @ Change history: 28.07.2021 / SRONG TIN / update method.
    @               06.05.2022 / Acmatac SEING / US-0011577 - UAT Feedback for NA Deals Custom List view
    @               09.12.2024 / Davy Sorn / US-0015202 - 'Recall deals' button not working as expected
    @*****************************************************************************************************************************/
    public PageReference recallDealsAction() {
        canContinueRecallDeals = false;
        try{
                 if(chunkIndex < chunkSize && !finishRecallDeals){

                    List<List<Object>> listAllDealChunk = (List<List<Object>>)mapChunkedDeal.get('listAllChunk');
                    Set<Id> setDealId = new Set<Id>();
                    for(Object objId : listAllDealChunk[chunkIndex]){
                        setDealId.add((Id)objId);
                    }
                    // SRONG TIN 28-July-2021, US-0009954
                    List<EBH_Deal__c> deals = loadDeals(setDealId);
                    ApexSafe.SafeDML safeDml = ApexSafe.dml();
                    
                    if(deals.size() > 0){
                        if(!isDealWindow){
                            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

                            String soql = 'Select id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN :deals';
                            List<ProcessInstanceWorkitem> listWorkItems = ApexSafe.query().doQuery(soql,new Map<String, Object> {'deals' => deals});
                            Map<id,Id> mapDealWorkItem = new Map<id,id>();
                            for(ProcessInstanceWorkitem WorkItem:listWorkItems){
                                mapDealWorkItem.put(workItem.ProcessInstance.TargetObjectId, workitem.id);
                            }
                            for(EBH_Deal__c eachDeal : deals){

                                if(eachDeal.EBH_Status__c == SENT_TO_SELLER){
                                    eachDeal.EBH_Status__c = INTERNALLY_APPROVED;
                                }else if(eachDeal.EBH_Status__c == IN_APPROVAL){
                                    eachDeal.EBH_Status__c = NEGOTIATING;
                                    
                                    if(mapDealWorkItem.containsKey(eachDeal.id)){
                                        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                                        req.setAction('Removed');
                                        req.setWorkItemId(mapDealWorkItem.get(eachDeal.id));
                                        requests.add(req);
                                    }
                                }
                            }
                            if(!requests.isEmpty()){
                                Approval.ProcessResult[] processResults = Approval.process(requests, true);
                            }
                            safeDml.doUpdate(deals, true);
                        }else{
                            // SRONG TIN 27-July-2021, update Deal Status to follow drc status
                            for(EBH_Deal__c eachDeal : deals){
                                // SRONG TIN 03-08-2021, US-0009954
                                eachDeal.EBH_ReasonforRejection__c = null;
                                eachDeal.EBH_ReasonforRejectionextd__c = null;
                                eachDeal.Cancellation_Reason__c = null;
                                eachDeal.EBH_Status__c = dealRetailCampaignStatus;
                            } 
                            safeDml.doUpdate(deals, true);
                        }
                        
                    }
    
                    chunkIndex++;
                    if(chunkIndex >= chunkSize){
                        finishRecallDeals = true;
                        // US-0011577 - UAT Feedback for NA Deals Custom List view
                        String parentRecId = CustomRelatedListController.checkIfFromCustomRelatedList_ThenReturnParentId();
                        if(String.isNotBlank(parentRecId)){
                            PageReference pg = new PageReference('/'+parentRecId);
                            pg.setRedirect(true);
                            return pg;
                        }
                    }else{
                        canContinueRecallDeals = true;
                    }
                }

        } catch(DmlException ex) {
            isError = true;
            errorMessage = Label.DD_Recall_Deal_Approval_Submitter;
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
        } catch (Exception ex) { 
            isError = true;  
            errorMessage = ex.getMessage(); System.debug('nsp: ex == '+ex.getMessage()); 
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
        }
        return null;//setCon.cancel();
    }
    /*****************************************************************************************************************************
    @ Method:       loadDeals
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0008182 - [US]* Deals Mass Recall from Approval Process for Deals Managers
					load all selected NA deal where status 'In Approval' or 'Sent to Seller'
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	no
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.09.2020 / Sovantheany Dim / Created the method.
    @ Change history: 28.07.2021 / SRONG TIN / update method. Added parameter : ids
    @*****************************************************************************************************************************/
    private List<EBH_Deal__c> loadDeals(Set<Id> ids) {
        RecordType recDeal = ApexUtil.getRecordTypeByName('EBH_Deal__c',NA_DEAL_RECORDTYPE);
        // SRONG TIN 27-July-2021 US-0009954
        String whereDealStatus = SENT_TO_SELLER;
        String whereDealStatus2 = IN_APPROVAL;
        if(isDealWindow){
            recDeal = ApexUtil.getRecordTypeByName('EBH_Deal__c',NA_UNSUB_DEAL_RECORDTYPE);
            whereDealStatus = STATUS_REJECTED;
            whereDealStatus2 = STATUS_CANCELLED;
        }
        
        List<EBH_Deal__c> deals = [Select Id, EBH_Status__c , Name from EBH_Deal__c 
                                                where (
                                                        EBH_Status__c=:whereDealStatus
                                                        OR EBH_Status__c=:whereDealStatus2
                                                    )
                                                    and RecordTypeId =:recDeal.ID
                                                    and id in : ids];
        return deals;
    }
    
    /*****************************************************************************************************************************
    @ Method:       cancel
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0008182 - [US]* Deals Mass Recall from Approval Process for Deals Managers
					when click cancel button
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	no
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.09.2020 / Sovantheany Dim / Created the method.
    @               06.05.2022 / Acmatac SEING / US-0011577 - UAT Feedback for NA Deals Custom List view
    @*****************************************************************************************************************************/
    public PageReference cancel(){
        // US-0011577 - UAT Feedback for NA Deals Custom List view
        String parentRecId = CustomRelatedListController.checkIfFromCustomRelatedList_ThenReturnParentId();
        if(String.isNotBlank(parentRecId)){
            PageReference pg = new PageReference('/'+parentRecId);
            pg.setRedirect(true);
            return pg;
        }

        return setCon.cancel();
    }
    
}