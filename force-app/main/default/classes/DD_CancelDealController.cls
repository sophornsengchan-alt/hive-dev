/*********************************************************************************************************************************
@ Class:          DD_CancelDealController
@ Version:        1.0
@ Author:         Sreymeas Nao (sreymeas.nao@gaea-sys.com)
@ Purpose:        US-0008178 - [US]* Deals Mass Cancellation Process for Deals Managers
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.10.2020 / Sreymeas Nao / Created the class.
                  24.12.2020 / Mony Nou     / Updated the class for US-0008827 - [NA] NA Deals: Make Cancellation Reason required when Cancelling Deals from List View
                  03.06.2021 / Sophal Noch  / Updated the class for US-0009585 - [NA] NA Deals, Recall Deals out of Approval Process if Deal is Cancelled
                  14.09.2021 / Sophal Noch  / Updated the class for US-0010387 - BUG - Canceled Deals still have Approval Process.
                  28.02.2022 / Mony Nou     / Updated the class for US-0010984 - Emails are sent to other sellers when cancelling Subsidized deals
                  07.09.2022 / Mony Nou     / US-0011149 - Cancelling or Recalling or Updating Spotlight Category AU Unsub Deal
                  16.05.2023 / Mony Nou     / US-0013603 - IT Deals Team - Need access to all the process in the Un-Sub Deals process for Deal Site = IT
                  19.05.2023 / LoumAng SENG / US-0013504 - Sub Deal_V2 - Cancel Deal localization
                  06.12.2023 / Sambath Seng / US-0014372 - Ability to select up to 285 records for Deals Cancellation process
                  10.01.2024 / Sambath Seng / US-0014541 - Tech Debt (IT region): refine apex code for {Email Preview Method}
*********************************************************************************************************************************/
public without sharing class DD_CancelDealController {
    public static final String NA_PROFILE = 'NA Standard User Base';
    public static final String AU_PROFILE = 'AU Standard User Profile'; //MN-07092022-US-0011149
    public static final String STD_PROFILE = 'Standard User Profile'; //MN-16052023-US-0013603

    public final static String US_MANAGE_DEAL_PERM='Select PermissionSet.Name, PermissionSetId, AssigneeId From PermissionSetAssignment  where (PermissionSet.Name IN (\'US_Manage_Deals\') OR PermissionSet.Name IN (\'eBay_NA_Manage_Unsub_Deals\')) AND AssigneeId=:currentUserId  limit  1';
    public List<EBH_Deal__c> selectedDeal {get;set;}
    public Boolean isError {get;set;}
    ApexPages.StandardSetController setCon;
    public String cancellationReason {get;set;}
    private final static String PERMISSION_NA_UNSUB_DEAL = 'eBay_NA_Manage_Unsub_Deals';
    private final static String PERMISSION_NA_MANAGE_DEAL = 'US_Manage_Deals';
    private static final String RECORDTYPE_UNSUBDEAL = 'Deal_V3';
    public Boolean isLabelContinue {get;set;}
    // SRONG TIN 09.08.2021 : US-0009958 Confirmation Pop-up when Cancelling or Rejecting or Approving Dels
    public Boolean displayPopup {get; set;}

    //MN-28022022-US-0010984
    public List<EmailPreviewWrapper> lstEmailPrevWrapper {get;set;}
    Map<String,Set<String>> map2Address = new Map<String,Set<String>>();
    public String exceed_msg {get;set;}
    public Boolean isExceed {get;set;}
    public Boolean isNeedEmailPreview {get;set;}
    // private Integer LIMITRECORD = 70;
    private Integer LIMITRECORD = 285; //SB 6.12.2023 US-0014372 - Ability to select up to 285 records for Deals Cancellation process
    private Integer record_size;

    private final static String PROCESS_INST_P_STATUS = 'Pending'; 
    private final static String REQUEST_ACTION = 'Removed'; 
    
    private static final String SITE_IT = '101'; //MN-17052023-US-0013603
    private final String SELCOM_IT_CANCEL_EMAILTEMPLATE = 'Sub Deal Cancellation Email to Seller - IT'; //LA-19-05-2023-US-0013504
    private final Id SELCOM_RT_DEALS = ApexUtil.getRecordTypeByName('Seller_Communication__c', 'Deals').Id;//LA-19-05-2023-US-0013504
    private final Id RECORDTYPE_SUBDEAL = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id;//LA-19-05-2023-US-0013504
    private final String SELCOM_REGION_IT = 'IT';//LA-19-05-2023-US-0013504
    private final String SELCOM_PLATEFORM = 'Seller Portal';//LA-19-05-2023-US-0013504


    public DD_CancelDealController(ApexPages.StandardSetController controller) {
        setCon = controller;
        isError = false;
        isExceed = false; //MN-02032022-US-0010984
        isNeedEmailPreview = false; //MN-04032022-US-0010984
        selectedDeal = controller.getSelected();
        
        String NAprofile    = ApexUtil.getProfileByName(NA_PROFILE).Id;
        String auProfile    = ApexUtil.getProfileByName(AU_PROFILE).Id; //MN-07092022-US-0011149
        String stdProfile   = ApexUtil.getProfileByName(STD_PROFILE).Id; //MN-16052023-US-0013603

        Boolean isNA    = UserInfo.getProfileId().equals(NAprofile);
        Boolean isAU    = UserInfo.getProfileId().equals(auProfile); //MN-07092022-US-0011149
        Boolean isSTD   = UserInfo.getProfileId().equals(stdProfile); //MN-16052023-US-0013603
        
        Boolean isAdmin = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
        String currentUserId = UserInfo.getUserId();
        Boolean isPSNaUnSubDeal = ApexUtil.checkPermissionSet(new Set<String>{PERMISSION_NA_UNSUB_DEAL});
        Boolean isPSNaManageDeal = ApexUtil.checkPermissionSet(new Set<String>{PERMISSION_NA_MANAGE_DEAL});
        isLabelContinue = false;
    	List<PermissionSetAssignment> listPSA = Database.query(US_MANAGE_DEAL_PERM);
        if(selectedDeal.size() <= 0){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, System.Label.NA_CANCEL_FUNC_ERR3));
            isError = true;
            return;
        }
        //MN-17052023-US-0013603:Added EBH_DealSiteId__c into below query
        selectedDeal = [SELECT Id, Name, RecordType.DeveloperName, Cancellation_Reason__c, RecordTypeId, EBH_BusinessName__c ,
                        OwnerId,Deal_Contract_Agreement__c,Deal_Contract_Agreement__r.Name,Preview_Date_Time__c,EBH_DealSiteId__c,Seller_Contact__c,EBH_eBayItemID__c,
                        Seller_Approver_1__r.Email,
                        Seller_Approver_2__r.Email,
                        Seller_Approver_3__r.Email,
                        Seller_Approver_4__r.Email,
                        Seller_Approver_5__r.Email 
                        FROM EBH_Deal__c WHERE Id IN: selectedDeal]; 

        //MN-17082022-US-0011119-Remove reference with old record type name
        // String dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
        RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
        String dealNARecordTypeId = String.valueOf(subDealRecordType.Id);

        RecordType NAUnsubDealRecType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V3');
        String ebSeller = selectedDeal.get(0).EBH_BusinessName__c;

        //MN-17052023-US-0013603
        Boolean isIT = isSTD && selectedDeal.get(0).EBH_DealSiteId__c.equals(SITE_IT);

        // preveiw send email notification
        Map<String,Set<String>> mapToAddress = new Map<String,Set<String>>();
        Set<String> emailsapprovers = new Set<String>();

        for(EBH_Deal__c deal : selectedDeal){
            if(deal.RecordTypeId != null && dealNARecordTypeId != deal.RecordTypeId && deal.RecordTypeId != NAUnsubDealRecType.Id){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, System.Label.NA_CANCEL_FUNC_ERR));
                isError = true;
                selectedDeal = new List<EBH_Deal__c>();
                return;
            }

            //MN-07092022-US-0011149 - Added isAU into condition
            //MN-17052023-US-0013603 - Added isIT into condition
            if((deal.RecordTypeId == NAUnsubDealRecType.Id && (isNA || isAU || isIT) && !isPSNaUnSubDeal)
                ||(deal.RecordTypeId == dealNARecordTypeId && (isNA || isAU || isIT) && !isPSNaManageDeal)){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, System.Label.NA_CANCEL_FUNC_ERR2));
                isError = true;
                return;
            }
            //LA-19.05.2023-US-0013504: add condition for IT-Subsidised Deals
            if(deal.RecordTypeId == NAUnsubDealRecType.Id || (deal.RecordTypeId == RECORDTYPE_SUBDEAL && deal.EBH_DealSiteId__c==SITE_IT)) isLabelContinue = true;
            if(deal.EBH_BusinessName__c != null && ebSeller != deal.EBH_BusinessName__c){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, System.Label.NA_CANCEL_FUNC_ERR1));
                isError = true;
                selectedDeal = new List<EBH_Deal__c>();
                return;
            }

            // preveiw send email notification
            if(mapToAddress.containsKey(deal.Deal_Contract_Agreement__c)) emailsapprovers = mapToAddress.get(deal.Deal_Contract_Agreement__c);
            if (String.isNotBlank(deal.Seller_Approver_1__r.Email)) { emailsapprovers.add(deal.Seller_Approver_1__r.Email); }
            if (String.isNotBlank(deal.Seller_Approver_2__r.Email)) { emailsapprovers.add(deal.Seller_Approver_2__r.Email); }
            if (String.isNotBlank(deal.Seller_Approver_3__r.Email)) { emailsapprovers.add(deal.Seller_Approver_3__r.Email); }
            if (String.isNotBlank(deal.Seller_Approver_4__r.Email)) { emailsapprovers.add(deal.Seller_Approver_4__r.Email); }
            if (String.isNotBlank(deal.Seller_Approver_5__r.Email)) { emailsapprovers.add(deal.Seller_Approver_5__r.Email); }
            mapToAddress.put(deal.Deal_Contract_Agreement__c, emailsapprovers);

            //LA-19.05.2023-US-0013504: skip for site IT
            if (!isNeedEmailPreview && dealNARecordTypeId == deal.RecordTypeId && deal.EBH_DealSiteId__c != SITE_IT) isNeedEmailPreview = true;

        }

        //MN-07092022-US-0011149 - Added isAU into condition
        //MN-17052023-US-0013603 - Added isIT into condition
        if(!isAdmin && !isNA && !isAU && !isIT || ((isNA || isAU || isIT) && listPSA.isEmpty()) ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, System.Label.NA_CANCEL_FUNC_ERR2));
            isError = true;
            return;
        }

        // preveiw send email notification
        lstEmailPrevWrapper = new List<EmailPreviewWrapper>();
        map2Address = mapToAddress;

    }

    /*****************************************************************************************************************************
    @ Method:         initialize
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        mark Preview Date/Time field = Current Date/Time of the selected records 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.02.2022 / Mony  / US-0010984 - Created the  Method.
    @               : 10.01.2024 / Sambath Seng / US-0014541 - Tech Debt (IT region): refine apex code for {Email Preview Method}
    *****************************************************************************************************************************/
    public void initialize() {

        //MN-02032022-US-0010984-Check if Selected Deals are more than 70 records, if so, display inform message on screen
        record_size = selectedDeal.size();
        if (isError) return;
        if (record_size > LIMITRECORD) {
            record_size = LIMITRECORD;
            exceed_msg = Label.DD_CancelDeal_Infor;
            isExceed = true;
        }
        else if (isNeedEmailPreview) //SB 10.01.2024 US-0014541
        { generateEmailPreview(); }
        
    }

    /*****************************************************************************************************************************
    @ Method:         generateEmailPreview
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        mark Preview Date/Time field = Current Date/Time of the selected records then process to Email Preview Screen
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.03.2022 / Mony  / US-0010984 - Created the  Method.
    *****************************************************************************************************************************/
    public void generateEmailPreview() {

        for (Integer i=0; i<record_size; i++) { selectedDeal.get(i).Preview_Date_Time__c = System.now(); }

        update selectedDeal;

        sendEmailTemplatePreview(selectedDeal,map2Address); 

        if (isExceed) isExceed = false;
    }

    public PageReference cancel(){
        // US-0011577 - UAT Feedback for NA Deals Custom List view
        String parentRecId = CustomRelatedListController.checkIfFromCustomRelatedList_ThenReturnParentId();
        if(String.isNotBlank(parentRecId)){
            PageReference pg = new PageReference('/'+parentRecId);
            pg.setRedirect(true);
            return pg;
        }

        //MN-02032022-US-0010984 - Clear Preview Date Time from each record
        List<EBH_Deal__c> tmp = new List<EBH_Deal__c>();
        for (Integer i=0; i<record_size; i++) { if(selectedDeal.get(i).Preview_Date_Time__c != null) { tmp.add(new EBH_Deal__c(Id=selectedDeal.get(i).Id, Preview_Date_Time__c = null)); } }
        //update selectedDeal;
        if (!tmp.isEmpty()) update tmp;

        return setCon.cancel();
    }
    /*****************************************************************************************************************************
    @ Method:         ok
    @ Version:        1.0
    @ Author:         SRONG TIN
    @ Purpose:        close the confirm popup and start process deal(s)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.09.2021 / SRONG TIN  / Created the  Method.
    @               06.05.2022 / Acmatac SEING / US-0011577 - UAT Feedback for NA Deals Custom List view
    *****************************************************************************************************************************/
    public PageReference ok(){
        displayPopup = false;
        massCancelDeal();
        // US-0011577 - UAT Feedback for NA Deals Custom List view
        String parentRecId = CustomRelatedListController.checkIfFromCustomRelatedList_ThenReturnParentId();
        if(String.isNotBlank(parentRecId)){
            PageReference pg = new PageReference('/'+parentRecId);
            pg.setRedirect(true);
            return pg;
        }

        return setCon.cancel();
    }
    /*****************************************************************************************************************************
    @ Method:         confirmDeal
    @ Version:        1.0
    @ Author:         SRONG TIN
    @ Purpose:        To alert message confirm popup 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.09.2021 / SRONG TIN  / Created the  Method.
                      13.10.2021 / SRONG TIN / Update the Method. [EU Deal] Wrong page displayed when click Accept/ Reject Standard Deal   
                      22.10.2021 / SRONG TIN / Update the Method. US-0010303
    *****************************************************************************************************************************/
    public PageReference confirmDeal(){
        if(!selectedDeal.isEmpty()) {
            // SRONG TIN : 13.10.2021 | US-0010303
            Boolean isNAUnsubDeal = false;

            for (Integer i=0; i<record_size; i++) { //MN-02032022-US-0010984
                EBH_Deal__c d = selectedDeal.get(i); //MN-02032022-US-0010984
                // for(EBH_Deal__c d: selectedDeal){
                //LA-19.05.2023-US-0013504: add condition for IT Subsidised Deals
             	if(d.RecordType.DeveloperName==RECORDTYPE_UNSUBDEAL || (d.RecordTypeId==RECORDTYPE_SUBDEAL && d.EBH_DealSiteId__c==SITE_IT)){
                    isNAUnsubDeal = true;
                    break;
            	}
        	}

            if (String.isBlank(cancellationReason)) { ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.NA_CANCEL_FUNC_ERR4)); return null; }
            // SRONG TIN : 13.10.2021 | US-0010303
            if(!isNAUnsubDeal){
                // SRONG TIN : 22.10.2021 | US-0010303
                return massCancelDeal();
            }else{ displayPopup = isNAUnsubDeal; return null; }
        }
        return setCon.cancel();
    }

    public PageReference massCancelDeal(){
        try {

            if (String.isBlank(cancellationReason)) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.NA_CANCEL_FUNC_ERR4));
                return null;
            }

            // 03.06.2021 / Sophal Noch  / for US-0009585 remove approval process before update deal status to 'Cancelled'
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            for(ProcessInstanceWorkitem workitem : [Select id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN :selectedDeal AND ProcessInstance.Status =:PROCESS_INST_P_STATUS]){

                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setAction(REQUEST_ACTION);
                req.setWorkItemId(workitem.id);
                requests.add(req);
            }
            if(!requests.isEmpty()){
                Approval.ProcessResult[] processResults = Approval.process(requests);
            }

            Map<String,Set<String>> mapToAddress = new Map<String,Set<String>>();
            Set<String> emailsapprovers = new Set<String>();
            List<EBH_Deal__c> listDealToSendEmail = new  List<EBH_Deal__c>();
            Map<String,List<EBH_Deal__c>> mapDealItems = new Map<String,List<EBH_Deal__c>>();

            for (Integer i=0; i<record_size; i++) { //MN-02032022-US-0010984
                //LA-19-05-2023-US-0013504:  move from the below code
                EBH_Deal__c deal = selectedDeal.get(i); //MN-02032022-US-0010984

                //-START-LA-19.05.2023-US-0013504
                if(deal.recordTypeId== RECORDTYPE_SUBDEAL && deal.EBH_DealSiteId__c== SITE_IT && deal.Seller_Contact__c != null){
                    List<EBH_Deal__c> listITDealPerSeller = mapDealItems.get(deal.EBH_BusinessName__c);
                    if(listITDealPerSeller == null) { 
                        listITDealPerSeller = new List<EBH_Deal__c>();
                        mapDealItems.put(deal.EBH_BusinessName__c, listITDealPerSeller);  // Group IT Deals per Seller and then create Seller Communication for each Seller in below logic
                    }
                    listITDealPerSeller.add(deal);
                   
                }else{

                    listDealToSendEmail.add(deal);
                    //Move the logic from the below
                    if(mapToAddress.containsKey(deal.Deal_Contract_Agreement__c)) emailsapprovers = mapToAddress.get(deal.Deal_Contract_Agreement__c);
                    if (String.isNotBlank(deal.Seller_Approver_1__r.Email)) { emailsapprovers.add(deal.Seller_Approver_1__r.Email); }
                    if (String.isNotBlank(deal.Seller_Approver_2__r.Email)) { emailsapprovers.add(deal.Seller_Approver_2__r.Email); }
                    if (String.isNotBlank(deal.Seller_Approver_3__r.Email)) { emailsapprovers.add(deal.Seller_Approver_3__r.Email); }
                    if (String.isNotBlank(deal.Seller_Approver_4__r.Email)) { emailsapprovers.add(deal.Seller_Approver_4__r.Email); }
                    if (String.isNotBlank(deal.Seller_Approver_5__r.Email)) { emailsapprovers.add(deal.Seller_Approver_5__r.Email); }
                    mapToAddress.put(deal.Deal_Contract_Agreement__c, emailsapprovers);
                    
                }
                //END US-0013504

                // EBH_Deal__c deal = selectedDeal.get(i); //MN-02032022-US-0010984 //LA-19.05.2023-US-0013504: commend code
                // for(EBH_Deal__c deal : selectedDeal){
                deal.EBH_Status__c = 'Cancelled';
                deal.Cancellation_Reason__c = cancellationReason;
                deal.Cancellation_Date_Time__c = System.Now();
                deal.Cancelled_Deal__c = true;
                deal.Preview_Date_Time__c = null; //MN-28022022-US-0010984

                //LA-19.05.2023-US-0013504: commend these codes
                // if(mapToAddress.containsKey(deal.Deal_Contract_Agreement__c)) emailsapprovers = mapToAddress.get(deal.Deal_Contract_Agreement__c);
                // if (String.isNotBlank(deal.Seller_Approver_1__r.Email)) { emailsapprovers.add(deal.Seller_Approver_1__r.Email); }
                // if (String.isNotBlank(deal.Seller_Approver_2__r.Email)) { emailsapprovers.add(deal.Seller_Approver_2__r.Email); }
                // if (String.isNotBlank(deal.Seller_Approver_3__r.Email)) { emailsapprovers.add(deal.Seller_Approver_3__r.Email); }
                // if (String.isNotBlank(deal.Seller_Approver_4__r.Email)) { emailsapprovers.add(deal.Seller_Approver_4__r.Email); }
                // if (String.isNotBlank(deal.Seller_Approver_5__r.Email)) { emailsapprovers.add(deal.Seller_Approver_5__r.Email); }
                // mapToAddress.put(deal.Deal_Contract_Agreement__c, emailsapprovers);
                
            }

            update selectedDeal;
            
            //LA-19.05.2023-US-0013504
            if(!mapDealItems.isEmpty()){
                List<Seller_Communication__c> lstITSellerComToInsert = new List<Seller_Communication__c>();
                for(Id sellerId : mapDealItems.keySet()){
                    if(sellerId != null) {
                        List<String> listEbayItems = new List<String>();
                        Map<Id, EBH_Deal__c> mapContIdToDeal = new Map<Id, EBH_Deal__c>();
                        for(EBH_Deal__c d : mapDealItems.get(sellerId)){
                            listEbayItems.add(d.EBH_eBayItemID__c);
                            if(!mapContIdToDeal.containsKey(d.Seller_Contact__c)){ mapContIdToDeal.put(d.Seller_Contact__c, d); } // create more than 1 Seller Communication For Seller if Deals per Seller have multiple different Contacts
                        }

                        String ebayItemsPerSeller = String.join(listEbayItems,','); // Create a String that contains Deal Ebay Item Ids per Seller Separate by comma

                        for(EBH_Deal__c d : mapContIdToDeal.values()){

                            lstITSellerComToInsert.add(new Seller_Communication__c(
                                RecordTypeId = SELCOM_RT_DEALS, 
                                Contact__c = d.Seller_Contact__c,
                                Account__c = sellerId,
                                Region__c = SELCOM_REGION_IT,
                                Email_Template__c = SELCOM_IT_CANCEL_EMAILTEMPLATE,
                                Email_Body__c = ebayItemsPerSeller,
                                Name = SELCOM_IT_CANCEL_EMAILTEMPLATE,
                                Deal__c = d.Id,
                                Platform__c = SELCOM_PLATEFORM
                            ));
                               
                        }
                        
                       
                    }

                }
                if(!lstITSellerComToInsert.isempty()) insert lstITSellerComToInsert;
                
            }
            //LA-19.05.2023-US-0013504: Move the logic to the below becaus IT no need to send email
            //     // SRONG TIN 10-02-2022 :US-0011327 : turn off notification
            //     // turn on
            //     sendEmailTemplate(selectedDeal,mapToAddress); 
            if(!listDealToSendEmail.isEmpty()){
                sendEmailTemplate(listDealToSendEmail,mapToAddress); 
            }

            //END US-0013504
            
        } catch (Exception ex) { ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage())); return null; }

        return setCon.cancel();
    }

    public void sendEmailTemplate(List<EBH_Deal__c> deals,Map<String,Set<String>> mapToAddress){

        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'NewDocument_Approval_Seller_cancellation'];
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        Set<String> sAgreement = new Set<String>();
        
        for (Integer i=0; i<record_size; i++) { //MN-02032022-US-0010984
            
            EBH_Deal__c deal = deals.get(i); //MN-02032022-US-0010984
            // for(EBH_Deal__c deal : deals){
            if(deal.Deal_Contract_Agreement__c == null || sAgreement.contains(deal.Deal_Contract_Agreement__c)) continue;
            sAgreement.add(deal.Deal_Contract_Agreement__c);
            
            List<string> toAddress = new List<string>();
            //toAddress.add('sovantheany.dim@gmail.com');
            if(mapToAddress.containsKey(deal.Deal_Contract_Agreement__c)){
                Set<String> emailsapprovers = mapToAddress.get(deal.Deal_Contract_Agreement__c);
                toAddress.addAll(emailsapprovers);
            }
            List<String> listCCAddresses = new List<String>{Label.DD_SubsidyDL};
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et.Id, deal.OwnerId, deal.Id);
                mail.setToAddresses(toAddress);
                mail.setCcAddresses(listCCAddresses);                   
                mail.setSaveAsActivity(false);
            allmsg.add(mail);
        }
        if(!test.isRunningTest() && !allmsg.isEmpty()) Messaging.sendEmail(allmsg,false);
    }

    /*****************************************************************************************************************************
    @ Method:         sendEmailTemplatePreview
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        to display Preview Email that will send to Seller Approve (s) when those selected deals update to Cancelled
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<EBH_Deal__c> deals & Map<String,Set<String>> mapToAddress
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.02.2022 / Mony Nou  / Created the  Method for US-0010984 - Emails are sent to other sellers when cancelling Subsidized deals
    *****************************************************************************************************************************/
    public void sendEmailTemplatePreview(List<EBH_Deal__c> deals,Map<String,Set<String>> mapToAddress){

        EmailTemplate et = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Document_Approval_Seller_cancel_Preview'];
        Set<String> sAgreement = new Set<String>();
        Map<Id, List<String>> mDealContractAgreeSelectDeals = new Map<Id, List<String>>();

        for (Integer i=0; i<record_size; i++) {
            
            EBH_Deal__c deal = deals.get(i);
        
            if (deal.Deal_Contract_Agreement__c!= null) {
                if (!mDealContractAgreeSelectDeals.containsKey(deal.Deal_Contract_Agreement__c)) mDealContractAgreeSelectDeals.put(deal.Deal_Contract_Agreement__c, new List<String>());
                mDealContractAgreeSelectDeals.get(deal.Deal_Contract_Agreement__c).add(deal.Name);
            }
        
            if(deal.Deal_Contract_Agreement__c == null || sAgreement.contains(deal.Deal_Contract_Agreement__c)) continue;
            sAgreement.add(deal.Deal_Contract_Agreement__c);

            List<string> toAddress = new List<string>();
            
            if(mapToAddress.containsKey(deal.Deal_Contract_Agreement__c)){
                Set<String> emailsapprovers = mapToAddress.get(deal.Deal_Contract_Agreement__c);
                toAddress.addAll(emailsapprovers);
            }
            
            List<String> listCCAddresses = new List<String>{Label.DD_SubsidyDL};
            String strPrevEmail='';
            
            EmailPreviewWrapper epw = new EmailPreviewWrapper();
            epw.dcaId = deal.Deal_Contract_Agreement__c;
            epw.to_addresses = String.join(toAddress, ', ');
            epw.cc_addresses = String.join(listCCAddresses, ', ');
            
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et.Id, deal.OwnerId, deal.Id);

            // System.debug('1.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            mail.setToAddresses(toAddress);
            mail.setCcAddresses(listCCAddresses);                   
            mail.setSaveAsActivity(false);
            
            List<Messaging.SingleEmailMessage> lstEmail = new List<Messaging.SingleEmailMessage>();
            lstEmail.add(mail);
            
            Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage(); //This errorEmail is purposely to create an error when we invoke sendEmail() so that we can getHTMLBody() content otherwise it will return NULL because the body will return when we invoke sendEmail only.
            lstEmail.add(errorEmail);
            try {
                List<Messaging.SendEmailResult> previewResult = Messaging.sendEmail(lstEmail);
            }
            catch (Exception ex) { strPrevEmail = mail.getHtmlBody(); } //since we already invoke sendEmail() method then we can getHtmlBody content without receiving NULL
            
            epw.email_prev_body = strPrevEmail;
            lstEmailPrevWrapper.add(epw);
        }

        //Assigned Selected Deal's Name into wrapper to display the Deal's information
        for (EmailPreviewWrapper epw : lstEmailPrevWrapper) {
            if (mDealContractAgreeSelectDeals.containsKey(epw.dcaId)) {
                epw.selected_deals = String.join(mDealContractAgreeSelectDeals.get(epw.dcaId), ', ');
            }
        }
        
       
    }
    //MN-28022022-US-0010984
    public class EmailPreviewWrapper {

        public String email_prev_body {get;set;}
        public String to_addresses {get;set;}
        public String cc_addresses {get;set;}
        public String selected_deals {get;set;}
        
        private Id dcaId;

    }

}