/*********************************************************************************************************************************
@ Class:          DealSubAmendUploadController
@ Version:        1.0
@ Author:         Vimean Heng (vimean.heng@gaea-sys.com)
@ Purpose:        US-0016717 - Contract Amendment Process - No Change in Subsidy
                  Controller for lwc: dealSubAmendUpload
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.03.2025 / Vimean Heng  / Created the class.
@ Change history: 27.03.2025 / Vimean Heng / US-0017027 - Amended Contract - Trigger Approval Process  
@ Change history: 08.04.2025 / Vimean Heng / US-0017027 - Amended Contract - Trigger Approval Process
@ Change history: 01.05.2025 / Vimean Heng / US-0017102 - Contract Amendment - Feedback
@ Change history: 01.07.2025 / Vimean Heng / US-0033105 - Exclude auto cancellation of Amended deals
*********************************************************************************************************************************/
public with sharing class DealSubAmendUploadController {
    
    public static final String DEAL_STATUS_CANCELLED = 'Cancelled';
    public static final String DEAL_STATUS_SELLER_CANCELLED = 'Seller Cancelled';
    public static final String DEAL_STATUS_SELLER_REJECTED = 'Seller Rejected';
    public static final String DEAL_STATUS_INTERNALLY_REJECTED = 'Internally Rejected';
    public static final String DEAL_STATUS_EXPIRED = 'Expired';
    public static final String DEAL_STATUS_REJECTED = 'Rejected';
    /*****************************************************************************************************************************
    @ Method:         doLoadSetting
    @ Version:        1.0
    @ Author:         Vimean Heng
    @ Purpose:        US-0016717 - Contract Amendment Process - No Change in Subsidy
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.03.2025 /Vimean Heng / Created the  Method.    
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Object doLoadSetting(String templateName)
    {
        Map<String, Object> mResult = new Map<String, Object>{'status' => 'success'};

        String userId = UserInfo.getUserID();
      
        String soqlMeta  = 'SELECT Id,Skipped_Field_Names__c,MasterLabel, Subtitle__c,Input_Placeholder__c,Sobject_Api_Name__c, DeveloperName,Maximum_Records__c,Excel_Column_Names__c,Required_Fields__c,Mapped_Field_Types__c,Batch_Size__c,Server_side_Post_DML__c,Exceed_Maximum_Message__c,Operator__c,Description__c,Allowed_Profiles__c,Allowed_Permission_Set__c,Allowed_Parent_RecordTypes__c,All_Permissions_Or_None__c,Parent_SObject_ApiName__c  from Excel_Importer_Template__mdt WHERE DeveloperName =: templateName';
       
        mResult.put('dd_DuplicateError', System.Label.DD_DuplicateError); 
   
        try
        {          
            List<Excel_Importer_Template__mdt> listMeta =  ApexSafe.query().secCheck(false).doQuery(soqlMeta, new Map<String,Object>{'templateName' => templateName});
            mResult.put('metadata', listMeta[0]); 
            mResult.put('hasNoPermission',!CSVExporterController.checkUserHasAccess(listMeta[0], null))    ;       

        } catch(Exception ex) 
        {
            mResult.put('status', 'error');mResult.put('message', ex.getMessage());
        }
        
        return mResult;  
    }
    /*****************************************************************************************************************************
    @ Method:         getAllDeals
    @ Version:        1.0
    @ Author:         Vimean Heng
    @ Purpose:        US-0016717 - Contract Amendment Process - No Change in Subsidy
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.03.2025 /Vimean Heng / Created the  Method.    
    @ Change history: 08.04.2025 / Vimean Heng / US-0017027 - Amended Contract - Trigger Approval Process
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Object getAllDeals(List<String> itemIds,List<String> overlapItemIds) {
        //get all deals to check change or no change Seller Price/Deal Price
        Map<String,Object> mResult = new Map<String,Object>();
        String statusRunning = 'Running';
        String amendedYes = 'Yes';
        mResult.put('status', 'error');
        try {
          RecordType rtSubDeal = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2');
          String soqlDeal = 'SELECT Id,RecordTypeId,EBH_Category__c,EBH_Vertical__c,EBH_RRPWASPrice__c,EBH_ProductTitle__c,EBH_Quantity__c,EBH_DealStartDate__c,EBH_DealEndDate__c,EBH_MaximumPurchases__c,EBH_DealEndTime__c,EBH_DealSiteId__c,EBH_BusinessName__c,Originating_Deal__c,Deal_Contract_Agreement__r.Category__c,Deal_Contract_Agreement__r.Vertical__c,Deal_Contract_Agreement__r.Deal_Site__c,Name,EBH_SellerPrice__c,EBH_DealPrice__c,EBH_eBayItemID__c from EBH_Deal__c WHERE EBH_eBayItemID__c IN :itemIds AND EBH_Status__c =:statusRunning and RecordTypeId =:recordType and Amended__c !=:amendedYes';
          List<EBH_Deal__c> lsDeal = (List<EBH_Deal__c>)ApexSafe.query().secCheck(false).doQuery(soqlDeal, new Map<String,Object>{'itemIds'=>itemIds,'statusRunning'=>statusRunning,'recordType'=>rtSubDeal.Id,'amendedYes'=>amendedYes});
          mResult.put('status', 'success');
          mResult.put('allDeals', lsDeal);
          mResult.put('RecordType', rtSubDeal.Id);
          mResult.put('overlapDeals', getOverlapDeals(overlapItemIds));
        } catch (Exception ex) {
            System.debug('@@@@@ex'+ex);mResult.put('message', 'Error:'+ex.getLineNumber()+':'+ ex.getMessage());EBH_ApexLogger.logError(new List<Exception> { ex }, 'DealBulkUploadController','getAllDeals');             
        }
        return mResult;
    }
    /*****************************************************************************************************************************
    @ Method:         getOverlapDeals
    @ Version:        1.0
    @ Author:         Vimean Heng
    @ Purpose:        US-0017102 - Contract Amendment - Feedback
    ------------------------------------------------------------------------------------------------------------------------------  
    @ Change history: 29.04.2025 / Vimean Heng / US-0017102 - Contract Amendment - Feedback
    *****************************************************************************************************************************/
    private static Map<String,List<EBH_Deal__c>> getOverlapDeals(List<String> itemIds) {
        Map<String,List<EBH_Deal__c>> mOverlapDeal = new Map<String,List<EBH_Deal__c>>();
        if(itemIds == null || itemIds.isEmpty()){
            return mOverlapDeal;
        }
        Set<String> sStatusToExclude = new Set<String> {
                DEAL_STATUS_CANCELLED, DEAL_STATUS_REJECTED, DEAL_STATUS_SELLER_REJECTED, DEAL_STATUS_INTERNALLY_REJECTED, DEAL_STATUS_EXPIRED, DEAL_STATUS_SELLER_CANCELLED
            };
        RecordType rtSubDeal = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2');
        String soqlDeal = 'SELECT Id,RecordTypeId,EBH_Status__c,EBH_ProductTitle__c,EBH_DealStartDate__c,EBH_DealEndDate__c,EBH_eBayItemID__c from EBH_Deal__c WHERE EBH_eBayItemID__c IN :itemIds AND EBH_Status__c NOT IN:sStatusToExclude AND RecordTypeId =:recordType';
        List<EBH_Deal__c> lsDeal = (List<EBH_Deal__c>)ApexSafe.query().secCheck(false).doQuery(soqlDeal, new Map<String,Object>{'itemIds'=>itemIds,'sStatusToExclude'=>sStatusToExclude,'recordType'=>rtSubDeal.Id});
        for(EBH_Deal__c d : lsDeal){
            if(!mOverlapDeal.containsKey(d.EBH_eBayItemID__c)){
                mOverlapDeal.put(d.EBH_eBayItemID__c, new List<EBH_Deal__c>());
            }
            mOverlapDeal.get(d.EBH_eBayItemID__c).add(d);    
        }
        return mOverlapDeal;
    }
    /*****************************************************************************************************************************
    @ Method:         submitDeals
    @ Version:        1.0
    @ Author:         Vimean Heng
    @ Purpose:        US-0016717 - Contract Amendment Process - No Change in Subsidy
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.03.2025 /Vimean Heng / Created the  Method.    
    @ Change history: 27.03.2025 /Vimean Heng / US-0017027 - Amended Contract - Trigger Approval Process  
    @ Change history: 01.05.2025 /Vimean Heng / US-0017102 - Contract Amendment - Feedback
    @ Change history: 01.07.2025 / Vimean Heng / US-0033105 - Exclude auto cancellation of Amended deals
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Object submitDeals(List<EBH_Deal__c> lstDeals,Map<String,Map<String,String>> mapParam,Map<String,String> mapItemOriginalDeal) {
        Map<String,Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try {
            RecordType rtSubDeal = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2');
            Map<String,Deal_Contract_Agreement__c> mapSellerDCA = new Map<String,Deal_Contract_Agreement__c>();
            for(String key : mapParam.keySet()){
                Deal_Contract_Agreement__c newDca = createDCAPerSeller(key,mapParam.get(key));
                mapSellerDCA.put(key, newDca);
            }
            ApexSafe.dml().secCheck(false).doInsert(mapSellerDCA.values(), false);
            Map<String,EBH_Deal__c> mapOriginalDeal = new Map<String, EBH_Deal__c>();
            for(EBH_Deal__c deal : lstDeals){
                deal.Deal_Contract_Agreement__c = mapSellerDCA.get(deal.EBH_BusinessName__c).Id;
                deal.EBH_Status__c = 'In Amendment';
                deal.Uploaded_By_DCA__c = true;

                deal.RecordTypeId = rtSubDeal.Id;
                
                String origDealId = mapItemOriginalDeal.get(deal.EBH_eBayItemID__c);
                if(String.isNotBlank(origDealId)){
                    EBH_Deal__c newDeal = new EBH_Deal__c(Id=origDealId,Amended__c='Yes',Amendment_Date__c = datetime.now());
                    mapOriginalDeal.put(origDealId,newDeal);
                }
            }
            Schema.SObjectField uniqueId = Schema.getGlobalDescribe().get('EBH_Deal__c').getDescribe().fields.getMap().get('Id');
            List<Database.UpsertResult> srList = ApexSafe.dml().secCheck(false).doUpsert(lstDeals,uniqueId, false);
            for(Integer i = 0;i < srList.size() ;i++){
                Database.UpsertResult rs = srList[i];
                if(!rs.isSuccess()){
                    //if amend deal error we don't need to update the original deal
                    EBH_Deal__c deal = lstDeals[i];
                    String origDealId = mapItemOriginalDeal.get(deal.EBH_eBayItemID__c);
                    if(String.isNotBlank(origDealId)){
                        mapOriginalDeal.remove(origDealId);
                    }
                }
            }
            if(!mapOriginalDeal.values().isEmpty()){
                ApexSafe.dml().secCheck(false).doUpdate(mapOriginalDeal.values(), false);
            }
            
            //Submit Approval
            if(mapSellerDCA.values().isEmpty() == false){
                amendSubmitApproval(mapSellerDCA.values());
            }
            mResult.put('message', 'The Deals are submitted successfully!');
            mResult.put('status', 'success');
            mResult.put('srList', JSON.serialize(srList));
            mResult.put('dca', mapParam);
        } catch (Exception ex) {
            System.debug('@@@@@ex'+ex);mResult.put('message', 'Error:'+ex.getLineNumber()+':'+ ex.getMessage());EBH_ApexLogger.logError(new List<Exception> { ex }, 'DealBulkUploadController','submitDeals');             
        }
        return mResult;
    }
    private static void amendSubmitApproval(List<Deal_Contract_Agreement__c> lsDCA){
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        Id userId = UserInfo.getUserId();
        for(Deal_Contract_Agreement__c dca :lsDCA){
            // Create an approval request for new DCA
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments(Label.Deal_Submission_Comment);
            req.setObjectId(dca.Id);
            req.setSubmitterId(userId);
            requests.add(req);
        }
        Approval.process(requests,true);
    }
    private static Deal_Contract_Agreement__c createDCAPerSeller(String sellId,Map<String,String> mapParam){
        RecordType rtDCASubDeal = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals');      
        Deal_Contract_Agreement__c newDca = new Deal_Contract_Agreement__c();
        newDca.Deal_Site__c = mapParam.get('dealSite');
        newDca.eBay_Seller__c = sellId;
        newDca.Category__c = mapParam.get('category');
        newDca.Status__c ='In Progress';
        newDca.Vertical__c=mapParam.get('vertical');
        newDca.RecordTypeId = rtDCASubDeal.Id;
        newDca.Amended__c='Yes';
        
        return newDca;
    }
}