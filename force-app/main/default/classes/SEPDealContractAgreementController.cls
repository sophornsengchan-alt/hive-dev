/*********************************************************************************************************************************
@ Class:          SEPDealContractAgreementController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Controller class for “Promotion Manager Feature in SEP”
@                 US-0012281 - Validation and upload of Deals
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.09.2022 / Sovantheany Dim / Created the class.
@               : 07.09.2022 / Loumang SENG / US-0012283 - Submit Deal Contract Agreement
@               : 15.09.2022 / SRONG TIN / US-0012298 - Ability to sign Agreement in portal
@               : 26.09.2022 / Mony Nou / US-0012359 - PM Deals: Downloading /storing Deal Contract on Portal and in Hive
@               : 27.10.2022 / Mony Nou / US-0012841 - Download Items PM Deals
@               : 27.10.2022 / Mony Nou / US-0012785 - Checks on status of Deal Contract Agreement - PM Deals
@               : 31.10.2022 / Mony Nou / US-0012856 - Corrections- PM Agreement in Seller Portal
@               : 16.05.2023/ vadhanak voun/ US-0013471 - 4. Seller should be able to download the contract on the Deal Overview page
@               : 19.05.2023 / Sambath Seng / US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
@               : 21.08.2023 / Mony Nou / US-0014035 - User Cannot Approve PM Contract
@               : 20.02.2025 / vadhanak voun / US-0016819 - NA Seller Eligible validation is fired when accept deal in SEP
@               : 24/02/2025 / Vimean Heng / US-0016475 - 12.1 - Seller Portal - Overview tab + Deal List Views
@               : 25.02.2025 / Sovantheany Dim / US-0016567 - 12.2 - Seller Portal - Details of the deal in the Deals List View
@               : 11.03.2025 / Sovantheany dim / US-0016373 - 14 - Seller Portal - Contract Sign Off
@               : 01.04.2025 / Sovantheany Dim / US-0016979 - Business Testing feedback - Subsidy per sold item is required in DCA related list
@               : 06.06.2025 / Sovantheany Dim / US-0032910 - Additional Column on the Deals view of the DCA SP
*********************************************************************************************************************************/
public with sharing class SEPDealContractAgreementController {
    //MN-27102022-US-0012841-Added field PM_Id__c into below query
    private final static String SOQL_DEAL_CONTRACT_AGREEMENT = 'select id,Name,Status__c,eBay_Funding__c,Rejection_Reason__c,Rejection_Comments__c,SellerPortal_Status__c,Contract_Due_Date__c,eBay_Seller__r.Name,eBay_Seller__r.Primary_Contact__c,eBay_Seller__r.SP_Promotions_Manager__c, Title__c,Deal_Page_Placement__c, Deal_Start_Date__c, Deal_Start_Time__c, Deal_End_Date__c, Deal_End_Time__c, Discount_Applied_in_Cart__c, Max_Total_Subsidy__c, Max_Unit_Subsidy__c, PM_Id__c from Deal_Contract_Agreement__c';
    private final static String WAITING_FOR_SUBMISSION_STATUS = 'Waiting for Submissions';
    private final static String IN_REVIEW_STATUS = 'In Review';
    //SRONG:15-09-2022-US-0012298 - Ability to sign Agreement in portal
    private final static String SP_PROMOTION_MANAGER = 'Full Access';
    private final static String SENT_TO_SELLER_STATUS = 'Sent to Seller';
    private final static String SELLER_APPROVED_STATUS = 'Seller Approved';
    private final static String SELLER_REJECTED_STATUS = 'Seller Rejected';
    private final static String RUNNING_STATUS = 'Running';
    private final static String COMPLETED_STATUS = 'Completed';
    private static final List<String> CONTRACT_AGREEMENT_STATUS_LIST = new List<String>{SENT_TO_SELLER_STATUS,SELLER_APPROVED_STATUS,SELLER_REJECTED_STATUS,RUNNING_STATUS,COMPLETED_STATUS};
    private final static integer BULK_DEAL_APPROVE_DECLINE_LIMIT = 200;//SB 19.05.2023 US-0013450
    private static final String DEAL_RECTYPE_SUBDEAL = 'Deal_V2';//SB 26.05.2023 US-0013450

     /*****************************************************************************************************************************
    @ Method:         getDealContractAgreement
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0012281 - Validation and upload of Deals
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dcaId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.09.2022 / Sovantheany Dim / Created the method
    @               : 15.09.2022 / SRONG TIN / US-0012298 - Ability to sign Agreement in portal
    @               : 24/02/2025 / Vimean Heng / US-0016475 - 12.1 - Seller Portal - Overview tab + Deal List Views
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getDealContractAgreement(String dcaId)
    {
        String mdtName = 'DCA_Tab_Visible_For_';
        Map<String,List<String>> mapMdt = fetchTapVisibleMdt(mdtName);
        Map<String,Object> mapResult = new Map<String,Object>();
        Deal_Contract_Agreement__c dca = Database.query(SOQL_DEAL_CONTRACT_AGREEMENT+' WHERE Id =:dcaId');
        Boolean isWaitSubmit = mapMdt.get(mdtName+'Upload_Deals').contains(dca.Status__c);
        Boolean isReview = mapMdt.get(mdtName+'Deal_Items').contains(dca.SellerPortal_Status__c);//LA:07-09-2022-US-0012283
        //SRONG:15-09-2022-US-0012298 - Ability to sign Agreement in portal
        Boolean isContractAgreement = CONTRACT_AGREEMENT_STATUS_LIST.contains(dca.Status__c);
        Boolean isShowViewAgreement = false;
        if( dca.Contract_Due_Date__c >= Date.today() && 
            dca.eBay_Seller__r.SP_Promotions_Manager__c == SP_PROMOTION_MANAGER &&
            dca.Status__c == SENT_TO_SELLER_STATUS
        ){
            isShowViewAgreement = true;
        }
        mapResult.put('isContractAgreement', isContractAgreement);
        mapResult.put('showViewAgreement', isShowViewAgreement);

        mapResult.put('hasUploadItemsAccess', isWaitSubmit);
        mapResult.put('hasDealItemsAccess', isReview);//LA:07-09-2022-US-0012283
        mapResult.put('pmID', dca.PM_Id__c); //MN-27102022-US-0012841
        mapResult.put('dca', dca); //VM 24/02/2025 / US-0016475
		return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:         fetchTapVisibleMdt
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0012660 - Submit button in Seller Portal to change the status of DCA
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String mdtName
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.09.2022 / Sovantheany Dim / Created the method
    *****************************************************************************************************************************/
    private static Map<String,List<String>> fetchTapVisibleMdt(String mdtName) {
        Map<String,List<String>> mapTabVisible = new Map<String,List<String>>();
        for(Seller_Portal_Global_Variables__mdt mdt : [SELECT DeveloperName, Value_Big__c FROM Seller_Portal_Global_Variables__mdt WHERE DeveloperName like: '%'+mdtName+'%']){
            List<String> sStatus = (List<String>) mdt.Value_Big__c.split(',');
            mapTabVisible.put(mdt.DeveloperName,sStatus);
        }
        return mapTabVisible;
    }

    //MN-26092022-US-0012359
    private final static Set<String> SET_STATUS_SHOW_DOWNLOAD_CONTRACT  = new Set<String>{
        'Seller Approved', 'Running', 'Completed'
    };
     /*****************************************************************************************************************************
    @ Method:         getDealContractAgreementData
    @ Version:        1.0
    @ Author:         SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:        US-0012298 - Ability to sign Agreement in portal 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dcaId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.09.2022 / SRONG TIN / Created the method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.10.2022 / Mony Nou / US-0012856 - Corrections- PM Agreement in Seller Portal
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getDealContractAgreementData(String dcaId)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        Deal_Contract_Agreement__c dca = Database.query(SOQL_DEAL_CONTRACT_AGREEMENT+' WHERE Id =:dcaId');
        Boolean isShowAgreeOrDecline = (dca.Status__c == SENT_TO_SELLER_STATUS);
        mapResult.put('isShowAgreeOrDecline', isShowAgreeOrDecline);
        mapResult.put('startTime', string.valueOf(dca.Deal_Start_Time__c));
        mapResult.put('endTime', string.valueOf(dca.Deal_End_Time__c));
        mapResult.put('dca', dca);

        String strDiscountAppliedInCart = (dca.Discount_Applied_in_Cart__c)?'Yes':'No'; //MN-31102022-US-0012856
        mapResult.put('isDiscountAppliedInCart', strDiscountAppliedInCart); //MN-31102022-US-0012856

        List<ContentDocumentLink> listAtt = [Select Id,ContentDocumentId From ContentDocumentLink where LinkedEntityId=:dcaId ORDER BY ContentDocument.CreatedDate DESC Limit 1];
        if(SET_STATUS_SHOW_DOWNLOAD_CONTRACT.contains(dca.Status__c) && !listAtt.isEmpty())
        {            
            ContentVersion[] cv = [Select Id,Title From ContentVersion Where ContentDocumentId =:listAtt[0].ContentDocumentId ORDER BY CreatedDate DESC Limit 1];
            mapResult.put('attachmentId',cv[0].Id);
            mapResult.put('fileNamePDF',cv[0].Title);      
            mapResult.put('showDownlaodPDF',SET_STATUS_SHOW_DOWNLOAD_CONTRACT.contains(dca.Status__c)); 
        }

		return mapResult;
    }


     /*****************************************************************************************************************************
    @ Method:         doAgreeOrDeclineDealContractAgreement
    @ Version:        1.0
    @ Author:         SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:        US-0012298 - Ability to sign Agreement in portal 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dcaId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.09.2022 / SRONG TIN / Created the method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.10.2022 / Mony Nou / US-0012785 - Checks on status of Deal Contract Agreement - PM Deals
    @               : 21.08.2023 / Mony Nou / US-0014035 - User Cannot Approve PM Contract
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> doAgreeOrDeclineDealContractAgreement(String jsonData)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        try{
            List<DealContractAgreementWrapper> lstData = (List<DealContractAgreementWrapper>) JSON.deserialize(jsonData, List<DealContractAgreementWrapper>.class);
            Deal_Contract_Agreement__c dca = new Deal_Contract_Agreement__c();
            dca.Id = lstData[0].dca.Id;
            dca.Seller_Accepted__c = datetime.now();
            
            //dca.Seller_Contact__c = lstData[0].dca.eBay_Seller__r.Primary_Contact__c; //MN-21082023-US-0014035
            //MN-21082023-US-0014035: Gonna use current user's contact to stamp on Contract instead
            for (User u : [Select ContactId From User Where Id=:UserInfo.getUserId()]) {
                dca.Seller_Contact__c =u.ContactId;
            }
            
            dca.Status__c = lstData[0].isAgree?SELLER_APPROVED_STATUS:SELLER_REJECTED_STATUS;
            dca.AutoStatusUpdateDateTime__c = System.now(); //MN-31102022-US-0012785
            dca.Seller_Name__c = lstData[0].dca.eBay_Seller__r.Name;
            if(!lstData[0].isAgree){
                dca.Rejection_Reason__c = lstData[0].dca.Rejection_Reason__c;
                dca.Rejection_Comments__c = lstData[0].dca.Rejection_Comments__c;
            }
            update dca;

            //MN-26092022-US-0012359 
            if (dca.Status__c == SELLER_APPROVED_STATUS) {

                for (Deal_Contract_Agreement__c tmp : [SELECT Title__c, eBay_Seller__r.Name, Deal_Start_Date__c, Deal_End_Date__c FROM Deal_Contract_Agreement__c WHERE Id=:dca.Id]) {
                    dca = tmp;
                }
                
                Map<String,String> resultAtt = SEPDCAContractDownloadController.createAttachment(dca);
                mapResult.put('attachmentId',resultAtt.get('id'));
                mapResult.put('fileNamePDF',resultAtt.get('name'));  
            }

            mapResult.put('isAgree', lstData[0].isAgree); //MN-26092022-US-0012359 
            mapResult.put('success', true);
        }
        catch(DMLException dex){ mapResult.put('success', false); mapResult.put('errorMsg', dex.getDmlMessage(0)); }
        catch(Exception e){ mapResult.put('success', false); mapResult.put('errorMsg', e.getMessage()); }
		
        return mapResult;
    }
    
    class DealContractAgreementWrapper {
        
        @AuraEnabled
        public Deal_Contract_Agreement__c dca;
    
        @AuraEnabled
        public Boolean isAgree;
            
    }

     /*****************************************************************************************************************************
    @ Method:         checkDCA
    @ Version:        1.0
    @ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        US-0013471 - 4. Seller should be able to download the contract on the Deal Overview page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    String dealId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.05.2023 / vadhanak voun / US-0013471 - 4. Seller should be able to download the contract on the Deal Overview page
    @                                           /Below are the condition to show the Contract download button:
    @       The Deal Status not equal to Cancelled and Deal_Contract_Agreement__c = not null and Deal Contract Agreement object contains a contract attachment in the Files related record.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> checkDCA(String dealId)
    {
        Set<String> setStatus = new Set<String>{'Cancelled'};
        Map<String,Object> mapResult = new Map<String,Object>{'hasContract'=>false,'showBtn'=>false};
        EBH_Deal__c deal = [Select Id,EBH_Status__c,Deal_Contract_Agreement__c From EBH_Deal__c Where Id=:dealId];
        if(deal.Deal_Contract_Agreement__c<>null)
        {
            String dcaId = deal.Deal_Contract_Agreement__c;
            List<ContentDocumentLink> listAtt = [Select Id,ContentDocumentId From ContentDocumentLink where LinkedEntityId=:dcaId ORDER BY ContentDocument.CreatedDate DESC Limit 1];
            mapResult.put('listAtt',listAtt);
            if(!listAtt.isEmpty())
            {
                ContentVersion[] cv = [Select Id,Title From ContentVersion Where ContentDocumentId =:listAtt[0].ContentDocumentId ORDER BY CreatedDate DESC Limit 1];
                mapResult.put('att_id',cv[0].Id);
                mapResult.put('att_title',cv[0].Title);
    
                mapResult.put('hasContract',true);            
                mapResult.put('showBtn',!setStatus.contains(deal.EBH_Status__c));
            }
        }
        //SEP_Auto_Generated_Deal_Contract_Agreement
        mapResult.put('isCancelled',setStatus.contains(deal.EBH_Status__c));
        mapResult.put('status','ok');

        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:         doApproveOrDeclineDeals
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<String> dealIds, Boolean isSelected, String status, String sellerId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2023 / Sambath Seng / Create method
    @               : 20.02.2025 / vadhanak voun / US-0016819 - NA Seller Eligible validation is fired when accept deal in SEP
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> doApproveOrDeclineDeals(List<String> dealIds, Boolean isSelected,String declineReason, String status, String sellerId)
    {
        Map<String,Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        List<EBH_Deal__c> lstDealUpdate = new List<EBH_Deal__c>();
        List<String> listSelectedDealId = new List<String>();
        Deal_Contract_Agreement__c newDCA = new Deal_Contract_Agreement__c();
        try{
            String query = 'Select Id,Deal_Contract_Agreement__c,EBH_DealSiteId__c FROM EBH_Deal__c ';
            String whereClause = 'WHERE EBH_Status__c =: SENT_TO_SELLER_STATUS AND RecordType.DeveloperName =: DEAL_RECTYPE_SUBDEAL AND EBH_BusinessName__c =: sellerId' + (isSelected ? ' AND Id IN:dealIds':'') + ' LIMIT :BULK_DEAL_APPROVE_DECLINE_LIMIT';
            List<EBH_Deal__c> listDeals = ApexSafe.query().secCheck(false).doQuery(query+whereClause,new Map<String,Object>{'SENT_TO_SELLER_STATUS'=>SENT_TO_SELLER_STATUS,'DEAL_RECTYPE_SUBDEAL'=>DEAL_RECTYPE_SUBDEAL,'sellerId'=>sellerId,'dealIds'=>dealIds,'BULK_DEAL_APPROVE_DECLINE_LIMIT'=>BULK_DEAL_APPROVE_DECLINE_LIMIT});
             
            if(status == SELLER_APPROVED_STATUS)
            { 
                newDCA = createDCAWithDigest(sellerId,listDeals[0].EBH_DealSiteId__c);    //NK:20-02-2025-US-0016819
            }
            //for(EBH_Deal__c oDeal : Database.query(query+whereClause)){
            for(EBH_Deal__c oDeal : listDeals){
                listSelectedDealId.add(oDeal.Id);
                oDeal.EBH_Status__c = status;
                if(status == SELLER_APPROVED_STATUS && oDeal.Deal_Contract_Agreement__c != null) {
                    oDeal.Deal_Contract_Agreement__c = newDCA.Id;
                } else {
                    oDeal.Seller_Decline_Reason__c = declineReason;
                }
                lstDealUpdate.add(oDeal);
            }

            if(!lstDealUpdate.isEmpty()){

                WithoutSharing.doUpdate(lstDealUpdate);
                mResult.put('status', 'success');

                if(status == SELLER_APPROVED_STATUS){
                    mResult.put('generateApprovedPDF',true);
                }
                mResult.put('newDcaId',newDCA.Id);

                mResult.put('totalDealsUpdate',lstDealUpdate.size());
                
            }
        } catch(DMLException dex)
        {
            mResult.put('status','error');mResult.put('error',dex.getDmlMessage(0));mResult.put('errorDetail',dex.getStackTraceString());
        }
        catch(Exception ex)
        {
            mResult.put('status','error');mResult.put('error',ex.getMessage());mResult.put('errorDetail',ex.getStackTraceString());
        }
        
        return mResult;
    }

    /*****************************************************************************************************************************
    @ Method:         generateDealApprovedPDF
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dcaId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.05.2023 / Sambath Seng / Create method
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> generateDealApprovedPDF(String dcaId){
        Map<String,Object> mResult = new Map<String,Object>();
        try {
            Map<String,String> resultAtt = SEPDCADownloadController.createAttachment(SEPDCADownloadController.getDCA(dcaId));
            mResult.put('attachmentId',resultAtt.get('id'));
            mResult.put('fileNamePDF',resultAtt.get('name'));
            mResult.put('status','success');
        } catch(DMLException dex)
        {
            mResult.put('status','error');mResult.put('error',dex.getDmlMessage(0));mResult.put('errorDetail',dex.getStackTraceString());
        }
        catch(Exception ex)
        {
            mResult.put('status','error');mResult.put('error',ex.getMessage());mResult.put('errorDetail',ex.getStackTraceString());
        }        
        return mResult;
    }

 
    /*****************************************************************************************************************************
    @ Method:         createDCAWithDigest
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String sellerId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.05.2023 / Sambath Seng / Create method
    @               : 20.02.2025 / vadhanak voun / US-0016819 - NA Seller Eligible validation is fired when accept deal in SEP
    *****************************************************************************************************************************/
    private static Deal_Contract_Agreement__c createDCAWithDigest(String sellerId,String dealSite)
    {
        Account seller = [Select Id,Name From Account Where Id =: sellerId LIMIT 1];
        Id DCASubrecordtype = Schema.SObjectType.Deal_Contract_Agreement__c.getRecordTypeInfosByDeveloperName().get('Subsidized_Deals').getRecordTypeId();
        Deal_Contract_Agreement__c dca = new Deal_Contract_Agreement__c();
        dca.eBay_Seller__c = seller.Id;
        dca.Seller_Name__c = seller.Name;
        dca.Current_Digest__c = ApexUtil.genUniqueStringNoSymbol(25);
        dca.Seller_Accepted__c = datetime.now();
        dca.Seller_Response_Time__c = System.now().time();
        dca.RecordTypeId = DCASubrecordtype; 
        //NK:20-02-2025-US-0016819
        if(dealSite=='101') //IT
        {
            dca.Deal_Site__c = '101';
        }

        insert dca;
        return dca;
    }

     /*****************************************************************************************************************************
    @ Method:         getDealsRelatedToDCA
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0016567 - 12.2 - Seller Portal - Details of the deal in the Deals List View
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dcaId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.02.2025 / Sovantheany Dim / Created the method
    @               : 01.04.2025 / Sovantheany Dim / US-0016979 - Business Testing feedback - Subsidy per sold item is required in DCA related list
    @               : 06.06.2025 / Sovantheany Dim / US-0032910 - Additional Column on the Deals view of the DCA SP
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> getDealsRelatedToDCA(String dcaId, String mdtName){
        Map<String, Object> mapResult = new Map<String, Object>();

        Seller_Portal_Setting__mdt spsMdt = ClsListViewController.readMtdObject(mdtName);
        Set<String> setAccessFnames = ClsListViewController.getAccessibleFieldApiNames(spsMdt.Object_API_Name__c);
        Map<String, Object> mHighlightFields = ClsListViewController.readFieldSet(spsMdt.Field_Set_Name__c, spsMdt.Object_API_Name__c, setAccessFnames);
        Set<String> allFieldsAPI = new Set<String>();
        allFieldsAPI.addAll((Set<String>) mHighlightFields.get('allFields'));
        //allFieldsAPI.remove('EBH_Subsidy__c');//US-0032910:06.06.2025:Comment out so the Column is add to Download //TH:US-0016979: Subsidy per Sold Item field shouldn't be included in the download items file.
        String selectedFields = String.join(new List<String>(allFieldsAPI), ', ');
        String soqlFields = selectedFields.replace('EBH_DealStartDate__c', 'format(EBH_DealStartDate__c)')
                                                 .replace('EBH_DealEndDate__c', 'format(EBH_DealEndDate__c)')
                                                 .replace('EBH_DealStartTime__c', 'format(EBH_DealStartTime__c)')
                                                 .replace('EBH_DealEndTime__c', 'format(EBH_DealEndTime__c)');
        String filters = (String.isNotBlank(spsMdt.Filter_Values__c) ? spsMdt.Filter_Values__c : '');
        String optionalQueryId = '';
        if(String.isNotBlank(dcaId)) {optionalQueryId = dcaId ;}
        String soqlDeal = 'SELECT '+ soqlFields + ' FROM '+ spsMdt.Object_API_Name__c +(String.isNotBlank(filters)? ' WHERE '+filters : '') + (String.isNotBlank(spsMdt.Order_Fields__c)? ' ORDER BY '+spsMdt.Order_Fields__c : '' );
        
        List<Map<String,Object>> lstSobjectNew = new List<Map<String,Object>>();
        List<SObject> listSobject = ApexSafe.query().doQuery(soqlDeal,new Map<String,Object>{'optionalQueryId'=>optionalQueryId});
        for(SObject sobj : listSobject){
            Map<String,Object> sObjectNew = new Map<String,Object>();
            for(String fieldApiName : allFieldsAPI){
                Object fieldValue = sobj.get(fieldApiName);
                sObjectNew.put(fieldApiName,fieldValue != null ? fieldValue : '');
            }
            lstSobjectNew.add(sObjectNew);
            
        }
        mapResult.put('lstRecords', lstSobjectNew);
        mapResult.put('mapFieldColHeader', mHighlightFields.get('mapFieldColHeader'));
        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:         getSelectedSellerDeclineReason
    @ Version:        1.0
    @ Author:         Sovantheany Dim
    @ Purpose:        US-0016373 - 14 - Seller Portal - Contract Sign Off

    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10-03-2025 /Sovantheany Dim/ Created the  Method.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> getSelectedSellerDeclineReason(String mdtName, String objectApiName, String fieldName){
        Set<String> validPicklist = new Set<String>();

        String soqlMDT = 'SELECT DeveloperName, Value_Big__c FROM Seller_Portal_Global_Variables__mdt WHERE DeveloperName =: mdtName';
        List<Seller_Portal_Global_Variables__mdt> records = ( List<Seller_Portal_Global_Variables__mdt>) ApexSafe.query().secCheck(false).doQuery(soqlMDT, new Map<String, Object>{ 'mdtName' => mdtName });
        Seller_Portal_Global_Variables__mdt spMdt = records.isEmpty() ? new Seller_Portal_Global_Variables__mdt() : records[0];
        if(String.isNotBlank(spMdt.Value_Big__c)){
            validPicklist.addAll(spMdt.Value_Big__c.split(';'));
        }
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        Map<String, String> picklistFieldValues = new Map<String, String>();
        
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(fieldName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            if (validPicklist.contains(objPickList.getValue())) {
                picklistFieldValues.put(objPickList.getLabel(), objPickList.getValue());
            }
        }

        return picklistFieldValues;
    }

    /*****************************************************************************************************************************
    @ Method:         doApproveOrDeclineSubDealsUS
    @ Version:        1.0
    @ Author:         Sovantheany dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0016373 - 14 - Seller Portal - Contract Sign Off
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<String> dealIds, Boolean isSelectedAll, String status, String dcaId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.03.2025 / Sovantheany dim / Create method
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> doApproveOrDeclineSubsidizeDeals(List<String> dealIds, Boolean isSelectedAll,String declineReason, String status, String dcaId, Integer totalRecord)
    {
        Map<String,Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        List<EBH_Deal__c> lstDealUpdate = new List<EBH_Deal__c>();
        try{
            String query = 'Select Id,EBH_Status__c FROM EBH_Deal__c ';
            String whereClause = 'WHERE EBH_Status__c =: SENT_TO_SELLER_STATUS AND RecordType.DeveloperName =: DEAL_RECTYPE_SUBDEAL AND Deal_Contract_Agreement__c =: dcaId' + (dealIds.isEmpty() ? '':' AND Id IN:dealIds');
            List<EBH_Deal__c> listDeals = ApexSafe.query().doQuery(query+whereClause,new Map<String,Object>{'SENT_TO_SELLER_STATUS'=>SENT_TO_SELLER_STATUS,'DEAL_RECTYPE_SUBDEAL'=>DEAL_RECTYPE_SUBDEAL,'dcaId'=>dcaId,'dealIds'=>dealIds});
             
            for(EBH_Deal__c oDeal : listDeals){
                oDeal.EBH_Status__c = status;
                if(String.isNotBlank(declineReason)){oDeal.Seller_Decline_Reason__c = declineReason;}
                lstDealUpdate.add(oDeal);
            }

            if(!lstDealUpdate.isEmpty()){

                ApexSafe.dml().doUpdate(lstDealUpdate, true);
                Integer totalDealsUpdate = lstDealUpdate.size();
                //update DCA status if all deals are approved/Rejected
                if(isSelectedAll || (totalRecord - totalDealsUpdate == 0)) {
                    List<Deal_Contract_Agreement__c> lstDCAUpdate = new List<Deal_Contract_Agreement__c>();
                    lstDCAUpdate.add(new Deal_Contract_Agreement__c(Id = dcaId, Status__c = status, AutoStatusUpdateDateTime__c = System.now()));
                    ApexSafe.dml().doUpdate(lstDCAUpdate, true);
                }

                //if all deals are approved, generate term and condition PDF
                if(status == SELLER_APPROVED_STATUS){
                    Deal_Contract_Agreement__c dca = new Deal_Contract_Agreement__c();
                    String dcaSoql = 'SELECT Title__c, Name, CreatedDate FROM Deal_Contract_Agreement__c WHERE Id=:dcaId';
                    List<Deal_Contract_Agreement__c> lstDca = (List<Deal_Contract_Agreement__c>) ApexSafe.query().doQuery(dcaSoql,new Map<String, Object> {'dcaId' => dcaId});
                    for (Deal_Contract_Agreement__c tmp : lstDca) {
                        dca = tmp;
                    }
                    Map<String,String> resultAtt = SubsidizeDCAContractDownloadController.createAttachment(dca);
                    mResult.put('attachmentId',resultAtt.get('id'));
                    mResult.put('fileNamePDF',resultAtt.get('name'));  
                }
                mResult.put('status', 'success');
                mResult.put('totalDealsUpdate',totalDealsUpdate);
                
            }
        } catch(DMLException dex)
        {
            mResult.put('status','error');mResult.put('error',dex.getDmlMessage(0));mResult.put('errorDetail',dex.getStackTraceString());
        }
        catch(Exception ex)
        {
            mResult.put('status','error');mResult.put('error',ex.getMessage());mResult.put('errorDetail',ex.getStackTraceString());
        }
        
        return mResult;
    }

}