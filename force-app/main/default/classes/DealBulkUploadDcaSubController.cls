/*********************************************************************************************************************************
@ Class:          DealBulkUploadDcaSubController
@ Version:        1.0
@ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0016262 - 10 - Seller Portal - Upload Sub Deals
                  Controller for lwc: dealBulkUploadDcaSub
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.02.2025 / vadhanak voun  / Created the class.
@               : 25.02.2025 / vadhanak voun  / Add createNewDca method. US-0016415 - 11 - Seller Self Initiated Deal Upload on Seller Portal
@               : 02.04.2025/ vadhanak voun/ US-0016977 - Bulk Upload - Business and internal Testing feedback
@               : 24.02.2025/ Chansophorn Seng/ US-0017008 - Upload Items link should provide proper error message when clicked in non upload status
@               : 16.05.2025/ vadhanak voun/ US-0032872 - Bug DCA upload deal limitation is ignored with Link Account
*********************************************************************************************************************************/
public with sharing class DealBulkUploadDcaSubController {
    private static final String STATUS_REJECTED = 'Rejected';
    
    private static final String STATUS_SELLERCANCELLED = 'Seller Cancelled'; 
    private static final String USER_PORTAL = 'PowerCustomerSuccess';
    private static final String USER_STANDARD = 'Standard';

    // 24.02.2025/ Chansophorn Seng/ US-0017008
    private static final String STATUS_WAITING_FOR_SUBMISSIONS = 'Waiting for Submissions';
    private static final String STATUS_IN_PROGRESS = 'In Progress';
    private static final List<String> STATUS_DCA_ALLOW_UPLOAD = new List<String>{
        STATUS_WAITING_FOR_SUBMISSIONS,
        STATUS_IN_PROGRESS
    };

    /*****************************************************************************************************************************
    @ Method:         doLoadSetting
    @ Version:        1.0
    @ Author:         vadhanak voun
    @ Purpose:        US-0016262 - 10 - Seller Portal - Upload Sub Deals
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<Coupon_Co_Invest__c> lstCPItems (Multiples Coupon Co-Invest from uploaded CSV)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.02.2025 /vadhanak voun/ Created the  Method.    
    @               : 24.02.2025/ Chansophorn Seng/ US-0017008 - Upload Items link should provide proper error message when clicked in non upload status
    @               : 16.05.2025/ vadhanak voun/ US-0032872 - Bug DCA upload deal limitation is ignored with Link Account
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Object doLoadSettingLinkedAccount(String metaData,String dcaId,String sellerId)
    {
        Map<String, Object> mResult = new Map<String, Object>{'status' => 'success'};

        if(String.isBlank(dcaId))
        {
            return new Map<String, Object>{'status' => 'error','message' => System.Label.LWCDealBulkUploadDCASub_ErrorDCAReq};
        }
        Set<String> sOptOutStatus = new Set<String>{ STATUS_REJECTED, STATUS_SELLERCANCELLED};
        Integer maxDealPerDCA = 1000;// default max if not set in metadata
        String userId = UserInfo.getUserID();
      
        String soqlMeta  = 'SELECT Id,DeveloperName,Maximum_Records__c,Excel_Column_Names__c,Required_Fields__c,Mapped_Field_Types__c,Batch_Size__c,Server_side_Post_DML__c   from Excel_Importer_Template__mdt WHERE DeveloperName =: metaData';
        String soqlUser = 'SELECT Id, Profile.Name, ContactId, Contact.LastName, Contact.FirstName, Contact.Email, Contact.AccountId, Contact.Account.Parent_Account_ID__c, Contact.Account.Deal_Window_Limit__c, Contact.Account.EBH_RegistrationSite__c From User WHERE Id =: userId';
 
        mResult.put('dd_DuplicateError', System.Label.DD_DuplicateError); 
   
        try
        {          
            List<Excel_Importer_Template__mdt> listMeta =  ApexSafe.query().secCheck(false).doQuery(soqlMeta, new Map<String,Object>{'metaData' => metaData});
            List<User> listUser = ApexSafe.query().secCheck(false).doQuery(soqlUser, new Map<String,Object>{'userId' => userId});
                
            maxDealPerDCA = listMeta[0].Maximum_Records__c==null?maxDealPerDCA:Integer.valueOf(listMeta[0].Maximum_Records__c);
            //NK: 16/05/2025:US-0032872 - remove sellerId from query to avoid error when link account : EBH_BusinessName__c =: sellerId
            String soqlCount = 'SELECT COUNT() FROM EBH_Deal__c WHERE Deal_Contract_Agreement__c =: dcaId AND EBH_Status__c NOT IN:sOptOutStatus AND IsDeleted = FALSE';
            String soqlDCA = 'SELECT Id,eBay_Seller__c, Status__c FROM Deal_Contract_Agreement__c WHERE Id =: dcaId';

            Integer totalDealPerCampaign = ApexSafe.query().doCount(soqlCount, new Map<String,Object>{'dcaId' => dcaId,'sOptOutStatus' => sOptOutStatus});
            Deal_Contract_Agreement__c[] listDCA = ApexSafe.query().doQuery(soqlDCA, new Map<String,Object>{'dcaId' => dcaId});
            
            // 24.02.2025/ Chansophorn Seng/ US-0017008 
            Boolean isDealSubmissionDCAAllowUpload = STATUS_DCA_ALLOW_UPLOAD.contains((String)listDCA[0].get('Status__c'));

            mResult.put('maxDealPerDCA', maxDealPerDCA);
            mResult.put('totalDealPerCampaign', totalDealPerCampaign);
            mResult.put('availableDeal', maxDealPerDCA - totalDealPerCampaign);
          
            mResult.put('accountId', listUser[0].Contact.AccountId);
            mResult.put('sellerDCA', listDCA[0].eBay_Seller__c); //seller of current dca //NK:09/04/2025: for link account
            mResult.put('contactId', listUser[0].ContactId);
            mResult.put('fullContactName', listUser[0].Contact.FirstName+ ' ' + listUser[0].Contact.LastName);
            mResult.put('conEmail', listUser[0].Contact.Email); 
            mResult.put('isDealSubmissionDCAAllowUpload', isDealSubmissionDCAAllowUpload); // display error message if isDealSubmissionDCAClose true //CSP: 24.02.2025 / US-0017008 

            mResult.put('metadata', listMeta[0]);            

        } catch(Exception ex) 
        {
            mResult.put('status', 'error');mResult.put('message', ex.getMessage());
        }
        
        return mResult;  
    }

    
    /*****************************************************************************************************************************
    @ Method:         getDCADetail
    @ Version:        1.0
    @ Author:         vadhanak voun
    @ Purpose:        US-0016262 - 10 - Seller Portal - Upload Sub Deals
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<Coupon_Co_Invest__c> lstCPItems (Multiples Coupon Co-Invest from uploaded CSV)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.02.2025 /vadhanak voun/ Created the  Method.    
    @               : 02.04.2025/ vadhanak voun/ US-0016977 - Bulk Upload - Business and internal Testing feedback
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Object submitDeals(List<EBH_Deal__c> lstDeals, Map<String,String> mapParams) {
        // Savepoint sp = Database.setSavepoint();
        Map<String,Object> mResult = new Map<String,Object>();
        mResult.put('status', 'error');
        try{
            RecordType rtSubDeal = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2');            
            String soqlDCA = 'Select Id,Deal_Site__c,eBay_Seller__c,Category__c From  Deal_Contract_Agreement__c Where Id=:dcaId';
            List<Deal_Contract_Agreement__c> listDCA = (Deal_Contract_Agreement__c[])ApexSafe.query().secCheck(false).doQuery(soqlDCA,new Map<String,Object>{'dcaId'=>mapParams.get('dcaId')});
            
            for(EBH_Deal__c deal : lstDeals)
            {
                deal.RecordTypeId = rtSubDeal.Id;
                deal.Deal_Contract_Agreement__c = mapParams.get('dcaId');         
                deal.EBH_Status__c = 'New';
                deal.EBH_DealSiteId__c = listDCA[0].Deal_Site__c;

                deal.EBH_BusinessName__c = listDCA[0].eBay_Seller__c;//mapParams.get('accountId');
                deal.Seller_Contact__c = mapParams.get('contactId');
                deal.Seller_Name__c = mapParams.get('fullContactName');
                deal.EBH_SellerEmail__c = mapParams.get('email');
                // deal.Seller_Approver_1__c = mapParams.get('contactId');
                deal.Uploaded_By_DCA__c = true;
                deal.EBH_Category__c =  listDCA[0].Category__c;
            }

            // //MN-04062024-US-0015298: Check current user's SP Main Domain instead of Profile Name
            // if(SEP_Helper.sepUser.isEU() && String.isNotBlank(dealReatilCampaingId)){
            //     EBH_DealTriggerHandler.isFromBulkUpload_DE = true;
            // }

 
            Database.SaveResult[] srList = ApexSafe.dml().secCheck(false).doInsert(lstDeals, false);
            mResult.put('srList', JSON.serialize(srList));
            mResult.put('message', 'The Deals are submitted successfully!');
            mResult.put('status', 'success');
            // mResult.put('isFromBulkUpload_DE', EBH_DealTriggerHandler.isFromBulkUpload_DE);
            mResult.put('lstDeals', lstDeals);

            // Database.rollback(sp);
        } catch (Exception ex) {
            System.debug('@@@@@ex'+ex);mResult.put('message', 'Error:'+ex.getLineNumber()+':'+ ex.getMessage());EBH_ApexLogger.logError(new List<Exception> { ex }, 'DealBulkUploadDcaSubController','submitDeals');             
        }
        return mResult;
    }
    /*****************************************************************************************************************************
    @ Method:         createNewDca
    @ Version:        1.0
    @ Author:         vadhanak voun
    @ Purpose:        US-0016415 - 11 - Seller Self Initiated Deal Upload on Seller Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Map<String,String> mapParam
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.02.2025 /vadhanak voun/ Created the  Method.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object>  createNewDca(Map<String,String> mapParam)
    {
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};       
        try 
        { 
            String catManagerEmail = (mapParam.get('catManagerEmail')+'').trim();
            String soqlUser = 'SELECT Id, ContactId, Contact.AccountId From User WHERE Id =: userId';
            List<User> listUser = ApexSafe.query().secCheck(false).doQuery(soqlUser, new Map<String,Object>{'userId' => UserInfo.getUserId()});
            
            RecordType rtDCASubDeal = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals');       

            Deal_Contract_Agreement__c newDca = new Deal_Contract_Agreement__c();
            newDca.Deal_Site__c = '0';  //US
            newDca.eBay_Seller__c = mapParam.get('accountId');//listUser[0].Contact.AccountId;
            newDca.Category__c = mapParam.get('category');
            newDca.Status__c ='In Progress';
            newDca.Vertical__c='';
            newDca.RecordTypeId = rtDCASubDeal.Id;

            // Owner of the DCA record should be updated to the matching Hive user in the system of the category manager email address entered by the Seller as part of AC2.3
            // I see that the DCA is assigned "Seller " as owner if the Category Manager's email does not return an active users (in scenarios where an incorrect email is used or the user is deactivated)
            String soqlUserCatMgr = 'SELECT Id,UserType From User WHERE Email =: catManagerEmail AND IsActive = TRUE AND UserType =: USER_STANDARD';
            List<User> listCM = ApexSafe.query(true).secCheck(false).doQuery(soqlUserCatMgr, new Map<String,Object>{'catManagerEmail' => catManagerEmail, 'USER_STANDARD' => USER_STANDARD});
            if(!listCM.isEmpty())
            {
                newDca.OwnerId = listCM[0].Id; //sorry, but only the first one!
                 
            }else
            {
                //trigger flow of DCA create/update owner (Deal_Contract_Agreement_TriggerAfter_Notify_DL_BOND)
                newDca.Email_Alert_With_Template__c = 'Subsidized DCA Notify BOND When SEP Created'; 
            }
            //super DML to avoid INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
            Database.SaveResult[] srList = ApexSafe.dml(true).secCheck(false).doInsert(new List<Deal_Contract_Agreement__c>{newDca}, true);
            mapResult.put('dcaId',newDca.Id);
     
            
        } catch (DmlException dex) 
        {
             mapResult.put('status','ko');mapResult.put('error',dex.getMessage());mapResult.put('detail',dex.getStackTraceString()); System.debug(LoggingLevel.Error, dex.getStackTraceString());EBH_ApexLogger.logError(new List<Exception> { dex }, 'DealBulkUploadDcaSubController','createNewDca');             
        }
 
        return mapResult;
    }
    
    public class SubDealUploadDCAPostDMLSEP extends ExcelImporterController.PostDMLBase{

        public override Map<String,Object> doPostDML()
        {
           Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
           String dcaId = postData.get('parentId');
            
           try 
           {
                //super query to get owner.email to assign to seller com fires flow send email to owner
                String soqlDCA = 'Select Id,Status__c,Seller_Name__c,eBay_Seller__c,eBay_Seller__r.Name,Owner.Email,OwnerId From  Deal_Contract_Agreement__c Where Id=:dcaId';
                List<Deal_Contract_Agreement__c> listDCA = (Deal_Contract_Agreement__c[])ApexSafe.query(true).secCheck(false).doQuery(soqlDCA,new Map<String,Object>{'dcaId'=>dcaId});
                if(listDCA[0].Status__c <> 'In Progress' || listDCA[0].Seller_Name__c <> listDCA[0].eBay_Seller__r.Name)
                {
                    listDCA[0].Status__c ='In Progress';
                    listDCA[0].Seller_Name__c=listDCA[0].eBay_Seller__r.Name;
                    ApexSafe.dml().secCheck(false).doUpdate(listDCA, true);
                }
                
                //make sure the owner is not portal user
                String soqlUserCatMgr = 'SELECT Id,UserType From User WHERE Id =: dcaOwnerId AND IsActive = TRUE';
                List<User> listOwner = ApexSafe.query(true).secCheck(false).doQuery(soqlUserCatMgr, new Map<String,Object>{'dcaOwnerId' => listDCA[0].OwnerId});                
                if(!listOwner.isEmpty() && listOwner[0].UserType <> USER_PORTAL)
                {
                    //Portal user has not PS to launch flow, so we need to create Seller Communication to notify CM
                    String templateName = 'Subsidized Deal Contract Agreement Upload Notify CM';
                    RecordType rtSCDeal = ApexUtil.getRecordTypeByName('Seller_Communication__c', 'Deals');
                    Seller_Communication__c scDCA = new Seller_Communication__c(
                        Name = templateName,
                        RecordTypeId = rtSCDeal.Id,
                        Email_address__c = listDCA[0].Owner.Email,
                        Email_Template__c = templateName,
                        Account__c =  listDCA[0].eBay_Seller__c,
                        PM_Deal__c =  listDCA[0].Id
                    );        
                    ApexSafe.dml().secCheck(false).doInsert(new List<Seller_Communication__c>{scDCA},true);
                }

           } catch (DmlException dex) 
           {
                mapResult.put('status','ko');mapResult.put('error',dex.getMessage());mapResult.put('detail',dex.getStackTraceString()); System.debug(LoggingLevel.Error, dex.getStackTraceString());EBH_ApexLogger.logError(new List<Exception> { dex }, 'DealBulkUploadDcaSubController.SubDealUploadDCAPostDMLSEP','doPostDML');
           }
           return mapResult;
        }
    }
}