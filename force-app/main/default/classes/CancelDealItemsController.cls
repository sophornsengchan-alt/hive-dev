/*********************************************************************************************************************************
@ Class:          CancelDealItemsController
@ Version:        1.0
@ Author:         Sarom Chetra (sarom.chetra@gaea-sys.com)
@ Purpose:        US-0013051 - Deal Contract Agreement - Cancel Deal Items
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.03.2023 / Sarom Chetra / Created the class.
@               : 31.03.2023 / Sarom Chetra / US-0013062 - Deal Contract Agreement - Cancel
@               : 04.04.2023 / Sovantheany dim / US-0013283 - Cancel PM Deal Items -Send email to seller
@               : 14.01.2024 / Mony Nou / US-0014538 - Account -Record Trigger flow -After Context Exception 
@               : 27/01/2025 / Chan Sophorn SENG / US-0016455: 8.1 -  Cancel Deals on a Deal Contract Agreement
@               : 21/04/2025 / Chan Sophorn SENG / US-0016809 - Removing double confirmation screen - Cancel - Sprint Review Feedback
*********************************************************************************************************************************/
public with sharing class CancelDealItemsController {
    public List<EBH_Deal__c> selectedDeal {get;set;}
    public Boolean isError {get;set;}
    public Boolean isRequired {get;set;}
    public Boolean displayPopup {get; set;}
    ApexPages.StandardSetController setCon;
    public String cancellationReason {get;set;}
    public Boolean isProcessingCancelDeal {get{return isProcessingCancelDeal = (isProcessingCancelDeal !=null ? isProcessingCancelDeal : false);} set;}
    
    public Map<String,Object> mapChunkedDeal {get{return mapChunkedDeal = (mapChunkedDeal !=null ? mapChunkedDeal : new Map<String,Object>());} set;}
    
    @TestVisible private final Integer CHUNK_SIZE_LIMIT = Integer.valueOf(System.Label.CANCEL_DEAL_ITEMS_CHUNK_SIZE_LIMIT);
    public Integer chunkIndex {get{return chunkIndex = (chunkIndex !=null ? chunkIndex : 0);} set;}
    public Integer chunkSize {get{return chunkSize = (chunkSize !=null ? chunkSize : 0);} set;}
    
    public Boolean hasNextChunk {get;set;}
    public Boolean finishChunk  {get{return finishChunk = (finishChunk !=null ? finishChunk : false);} set;}
    public Integer countRecordProcessing {get{return countRecordProcessing = (countRecordProcessing !=null ? countRecordProcessing : 0);} set;}
    public Integer totalRecords {get{return totalRecords = (totalRecords !=null ? totalRecords : 0);} set;}

    Set<String> dcaStatus = new Set<String>{
        'In Progress',
        'In Approval',
        'Sent to Seller',
        'Seller Approved',
        'Running'
    };
    @TestVisible private final static string SELCOM_CANCEL_EMAILTEMPLATE = 'Seller Email On Cancelled Items';//TH:US-0013283
    private Set<String> sSellerId = new Set<String>();//TH:US-0013283
    private Set<String> sSellerPortalGroupId = new Set<String>();//TH:US-0013283

    private static final String RECORD_TYPE_SUBSIDIZED_DCA = 'Subsidized_Deals';//CSP:US-0016455
    public static final String SOQL_DEAL = 'Select Id, EBH_Status__c, RecordType.DeveloperName,EBH_DealSiteId__c, RecordTypeId, Cancellation_Reason__c From EBH_Deal__c';//CSP:US-0016455
    public static final String SOQL_PARENT_DEAL = 'SELECT Id,RecordType.DeveloperName, Status__c,eBay_Seller__c, eBay_Seller__r.Seller_Portal_Group__c FROM Deal_Contract_Agreement__c where id=: parentRecId Limit 1';//CSP:US-0016455
    public Boolean isSUBSIDIZED_DCA {get; set;}
    public List<SelectOption> options {get; set;}
    public EBH_Deal__c dealSubDeal {get; set;}
    public Map<String,String> mapDCASellerId {get; set;}

    PageReference pgCurrent = ApexPages.currentPage();
    public String urlVal = String.isBlank(pgCurrent.getParameters().get('retURL')) ? '' : String.escapeSingleQuotes(pgCurrent.getParameters().get('retURL'));
    public String parentRecId = String.isBlank(pgCurrent.getParameters().get('Id')) ? '' : String.escapeSingleQuotes(pgCurrent.getParameters().get('Id'));

    // 21/04/2025 / CSP / US-0016809
    public Integer totalRecordsSite {get{return totalRecordsSite = (totalRecordsSite !=null ? totalRecordsSite : 0);} set;}


    /*****************************************************************************************************************************
    @ Method:         CancelDealItemsController
    @ Version:        1.0
    @ Author:          
    @ Purpose:        
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27/01/2025 / Chan Sophorn SENG / US-0016455: 8.1 -  Cancel Deals on a Deal Contract Agreement
    *****************************************************************************************************************************/
    public CancelDealItemsController(ApexPages.StandardSetController controller) {
        setCon = controller;
        isError = false;
        selectedDeal = controller.getSelected();

        // CSP-27012015: US-0016455
        init();
        
    }

    /*****************************************************************************************************************************
    @ Method:         init
    @ Version:        1.0
    @ Author:          
    @ Purpose:        initialize data for vf view
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      ApexPages.StandardController controller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27/01/2025 / Chan Sophorn SENG / US-0016455: 8.1 -  Cancel Deals on a Deal Contract Agreement
    @               : 21/04/2025 / Chan Sophorn SENG / US-0016809 - Removing double confirmation screen - Cancel - Sprint Review Feedback
    *****************************************************************************************************************************/
    private void init()
    {
        isSUBSIDIZED_DCA=false;
        Map<String,String> mapDeals = new Map<String,String>();
        // CSP-27012015: US-0016455
        List<Deal_Contract_Agreement__c> dealContactAgreement = ApexSafe.query().secCheck(false).doQuery(
            SOQL_PARENT_DEAL,
            new Map<String, Object>{'parentRecId' => parentRecId}
        );

        mapDCASellerId = new Map<String,String>();

        for(Deal_Contract_Agreement__c dca : dealContactAgreement){
            // CSP-27012015: US-0016455
            isSUBSIDIZED_DCA= dca.RecordType.DeveloperName == RECORD_TYPE_SUBSIDIZED_DCA ? true : false;
            mapDCASellerId.put(dca.Id,dca.eBay_Seller__c);
            if (!dcaStatus.contains(dca.Status__c)){
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.Error, 
                    System.Label.CANCEL_DEAL_ITEMS_STATUS_PROCESS_BUTTON
                ));
                isError = true;
                return;
            } 
        }

        String finalQuery = SOQL_DEAL+' Where Id IN :selectedDeal';
        List<SObject> listSelectedDeal = ApexSafe.query().doQuery(
            finalQuery,
            new Map<String, Object>{'selectedDeal' => selectedDeal}
        );
        selectedDeal = listSelectedDeal;

        totalRecords = selectedDeal.size();
        if(selectedDeal.size() <= 0){
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.WARNING, 
                System.Label.NA_CANCEL_FUNC_ERR3
            ));
            isError = true;
            return;
        }
        // 21/04/2025 / CSP / US-0016809
        List<Id> lstAllDealIds = new List<Id>();

        for(EBH_Deal__c deal : selectedDeal){
            lstAllDealIds.add(deal.Id);
            // 21/04/2025 / CSP / US-0016809
            mapDeals.put(deal.EBH_DealSiteId__c, deal.Id);
        }

        // 21/04/2025 / CSP / US-0016809
        totalRecordsSite = mapDeals.keySet().size();
         
        
        mapChunkedDeal = ApexUtil.chunkList(lstAllDealIds,CHUNK_SIZE_LIMIT);
        chunkSize = (Integer)mapChunkedDeal.get('chunkSize');

        createTmpDeal();
    }

    /*****************************************************************************************************************************
    @ Method:         createTmpDeal
    @ Version:        1.0
    @ Author:          
    @ Purpose:       
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27/01/2025 / Chan Sophorn SENG / US-0016455: 8.1 -  Cancel Deals on a Deal Contract Agreement
    *****************************************************************************************************************************/
    private void createTmpDeal()
    {
        for(EBH_Deal__c d: selectedDeal)
        {
            if( d.RecordTypeId != null && d.RecordType.DeveloperName != null){
                RecordType recordTypeDealSub =  ApexUtil.getRecordTypeByName('EBH_Deal__c', d.RecordType.DeveloperName);
                dealSubDeal =  new EBH_Deal__c(recordTypeId=recordTypeDealSub.Id);
                break;
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:       getCancellationReasonOptions
    @ Author:       Sarom Chetra (sarom.chetra@gaea-sys.com)
    @ Purpose:      US-0013062 - Deal Contract Agreement - Cancel
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.03.2023 / Sarom Chetra / US-0013062 - Deal Contract Agreement - Cancel
    @*****************************************************************************************************************************/  
    // public List<SelectOption> getCancellationReasonOptions() {   
    //     List<SelectOption> selectOptions = new List<SelectOption>();
    //     List<Map<String,String>> pickListEntries = ApexUtil.getPicklistValues(EBH_Deal__c.Cancellation_Reason__c);
    //     selectOptions.add(new SelectOption('','None'));
    //     for(Map<String,String> pl : pickListEntries) {
    //         selectOptions.add(new SelectOption(pl.get('label'), pl.get('value')));    
    //     }
    //     return selectOptions;
    // }


    public PageReference ok(){
        displayPopup = false;
        return massCancelDeal();
        // return null;
    }

    /*****************************************************************************************************************************
    @ Method:         confirmDeal
    @ Version:        1.0
    @ Author:          
    @ Purpose:        
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27/01/2025 / Chan Sophorn SENG / US-0016455: 8.1 -  Cancel Deals on a Deal Contract Agreement
    *****************************************************************************************************************************/
    public PageReference confirmDeal(){
        if(!selectedDeal.isEmpty()) {
            // CSP-27012015: US-0016455
            if (dealSubDeal != null && String.isBlank(dealSubDeal.Cancellation_Reason__c)) { 
                cancellationReason = dealSubDeal.Cancellation_Reason__c;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.NA_CANCEL_FUNC_ERR4)); 
                isRequired = true;
                return null; 
            }
            displayPopup = true;
        }
        return null;
    }

    public PageReference massCancelDeal(){
        hasNextChunk = false;
        isProcessingCancelDeal = true;
        try {
            if(chunkIndex < chunkSize){
                List<List<Object>> listAllDealChunk = (List<List<Object>>)mapChunkedDeal.get('listAllChunk');
                List<EBH_Deal__c> listDealToUpdate = new List<EBH_Deal__c>();

                for(Object objId : listAllDealChunk[chunkIndex]){
                    listDealToUpdate.add(
                        new EBH_Deal__c(
                            Id = (Id)objId, 
                            EBH_Status__c = 'Cancelled',
                            Cancellation_Reason__c = dealSubDeal.Cancellation_Reason__c,
                            Cancellation_Date_Time__c = System.Now(),
                            Cancelled_Deal__c = true,
                            Preview_Date_Time__c = null
                        )
                    );
                }   
                update listDealToUpdate;  
                //TH: US-0013283 : get SellerId and SellerPortalGroupId to create Seller com
                for(EBH_Deal__c deal : [select EBH_BusinessName__c,EBH_BusinessName__r.Seller_Portal_Group__c from EBH_Deal__c where id in: listDealToUpdate]){
                    sSellerId.add(deal.EBH_BusinessName__c);
                    sSellerPortalGroupId.add(deal.EBH_BusinessName__r.Seller_Portal_Group__c);
                }
                
                countRecordProcessing = countRecordProcessing + listAllDealChunk[chunkIndex].size();
                chunkIndex++;
                if(chunkIndex >= chunkSize){
                    finishChunk = true;
                }else{
                    hasNextChunk = true;
                }
            }
            // CSP-27012015: US-0016455
            if (finishChunk && isSUBSIDIZED_DCA) {
                Boolean allCancelled = true;

                for (EBH_Deal__c deal : selectedDeal) {
                    if (deal.EBH_Status__c != 'Cancelled') {
                        allCancelled = false;
                        break; 
                    }
                }
                if(!allCancelled) {
                    String sComName = 'Sub Deals Cancellation - Notification to Seller - US';
                    String emailTemplate = 'Sub Deals Cancellation - Notification to Seller - US';
                    DealContractAgreementTriggerHandler.createSellerComsByDCA(
                        'Deals',
                        mapDCASellerId,
                        sComName, 
                        emailTemplate
                    );
                }
                
            } 
            //TH: US-0013283 : the system needs to create one Seller Communication record for DWH contact and also any contact linked to the Seller Account or Seller Portal group with the following information: If Seller has 'Account.SP_Promotions_Manager__c = Full Access' and Contact has 'Contact.Active_Community_User__c = TRUE'
            else if(finishChunk){
                RecordType rectypePMDeal = ApexUtil.getRecordTypeByName('Seller_Communication__c','PM_Deal');
                List<Seller_Communication__c> lstSellerComToCreated = new List<Seller_Communication__c>();
                for(Contact cont : [select id,AccountId from Contact where ((email != null AND RecordType.DeveloperName = 'EBH_DWH' AND AccountId IN: sSellerId) OR (Active_Community_User__c = true AND (AccountId IN: sSellerId OR AccountId IN: sSellerPortalGroupId))) AND Account.SP_Promotions_Manager__c = 'Full Access' AND AccountId != null]){
                    lstSellerComToCreated.add(new Seller_Communication__c(
                        RecordTypeId = rectypePMDeal.Id,
                        Account__c = cont.AccountId, //MN-15012024-0014538: Add Account field since we replaced Region with SP_Main_Domain on the Seller Communication Flow for sending email
                        Contact__c = cont.Id,
                        PM_Deal__c = parentRecId,
                        Email_Template__c = SELCOM_CANCEL_EMAILTEMPLATE,
                        Name = SELCOM_CANCEL_EMAILTEMPLATE,
                        Region__c = 'NA',
                        Platform__c = 'Seller Portal'
                    ));
                }
                if(!lstSellerComToCreated.isEmpty()) insert lstSellerComToCreated;
            }
            
        } catch (Exception ex) { 
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()
            )
            ); 
            System.debug('ApexPages.severity.ERROR,ex.getMessage()'+ex.getMessage());
            // return null; 
        }

        return null;
    }

    public PageReference cancel(){
        if(String.isNotBlank(parentRecId)){
            PageReference pg = new PageReference('/'+parentRecId);
            pg.setRedirect(true);
            return pg;
        }

        return setCon.cancel();
    }

    public PageReference back(){
        displayPopup = false;
        return null;
    }
}