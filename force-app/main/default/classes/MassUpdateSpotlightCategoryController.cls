/*********************************************************************************************************************************
@ Class:          MassUpdateSpotlightCategoryController
@ Version:        1.0
@ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
@ Purpose:        US-0009955-[SEP] NA Unsub Deal: Remove un-needed buttons from Page Layout
@                  
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26-07-2021 / Loumang SENG / Created the class.			  
@                 02-06-2023 / Mony Nou / US-0013721 - SP - IT Deals UAT issue fixes - AC2
*********************************************************************************************************************************/
public without sharing class MassUpdateSpotlightCategoryController {
    private static final String PERMISSION_NA_UNSUB_DEAL = 'eBay_NA_Manage_Unsub_Deals';
    private static final String RECORDTYPE_UNSUBDEAL = 'Deal_V3';
    private static final String RECORDTYPE_SUBDEAL = 'Deal_V2'; //MN-02062023-US-0013721

    @AuraEnabled
    public static Map<String,Object> apexInit(String drcId, String dealIds)
    {	
        Map<String,Object> mapResult = new Map<String,Object>();
        try{
            List<String> listDealId = dealIds.split(',');
            if(String.isBlank(dealIds) || listDealId.isEmpty()){ mapResult.put('status','ko'); mapResult.put('error',System.Label.NA_CANCEL_FUNC_ERR3); return mapResult; }
            List<EBH_Deal__c> selectedDeal = [Select Id, RecordType.DeveloperName, RecordTypeId, EBH_SpotlightCategory__c, EBH_DealSiteId__c From EBH_Deal__c Where Id IN :listDealId];
            Boolean isPSNaUnSubDeal = ApexUtil.checkPermissionSet(new Set<String>{PERMISSION_NA_UNSUB_DEAL});
            Set<String> allowedRecordType= new Set<String>{RECORDTYPE_UNSUBDEAL, RECORDTYPE_SUBDEAL}; //MN-02062023-US-0013721-AC2:Allowed for all regions (NA, AU, IT)
            Boolean isAdmin = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
            for(EBH_Deal__c d: selectedDeal)
            {
                //Block update spotlight category deals with different recordtypes
                if(!allowedRecordType.contains(d.RecordType.DeveloperName)){ mapResult.put('status','ko'); mapResult.put('error',System.Label.UNSUB_DEAL_RECORDTYPE_ERROR); return mapResult;}
                
                //Update Spotlight Category button from  user profile != Admin or user without permission set NA Manage Unsub Deals
                if(!isAdmin && !isPSNaUnSubDeal){ mapResult.put('status','ko'); mapResult.put('error',System.Label.THIS_FUNCTIONALITY_IS_NOT_AVAILABLE_TO_YOUR_REGION); return mapResult; }
                
            }
            Map<String,Object> mapChunkedDeal = ApexUtil.chunkList(listDealId,Integer.valueOf(System.Label.DEAL_SPOTLIGHT_CHUNK_SIZE_LIMIT));
            mapResult.put('status','ok');
            mapResult.put('mapChunkedDeal',mapChunkedDeal);

        }catch(Exception ex){ mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString()); }
        return mapResult;

    }

    @AuraEnabled
    public static Map<String,Object> apexSave(List<String> listDealIds, String spotlightCategory, Integer index)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        try {
            List<EBH_Deal__c> listDealToUpdate = new List<EBH_Deal__c>();
            for(String dealId : listDealIds){
                listDealToUpdate.add(new EBH_Deal__c(Id=dealId, EBH_SpotlightCategory__c =spotlightCategory));

            }
            update listDealToUpdate;
            index ++;
            mapResult.put('status','ok');
            mapResult.put('index', index);

        }catch(Exception ex){ mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString()); }
        return mapResult;
    }
}