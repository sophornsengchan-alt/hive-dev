/*********************************************************************************************************************************
@ Class:          MassDeleteCouponSellersController
@ Version:        1.0
@ Author:         srong tin (srong.tin@gaea-sys.com)
@ Purpose:        US-0015086 - Coupon Manager for bulk edit functions
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.07.2024 / srong tin / Created the class.
@               : 08.08.2024 / srong tin / US-0015656 - Insufficient Privileges for Bulk Delete Sellrs
*********************************************************************************************************************************/

public with sharing class MassDeleteCouponSellersController {
    public String reUrl{get;set;}
    public List<Coupon_Seller__c> selectedCouponSeller{get;set;}
    public List<Id> lstSelCSid {get{return lstSelCSid = (lstSelCSid !=null ? lstSelCSid : new List<Id>());} set;}
    public Map<String,Object> mChunkedCS {get{return mChunkedCS = (mChunkedCS !=null ? mChunkedCS : new Map<String,Object>());} set;}
    public Integer chunkIndex   {get{return chunkIndex = (chunkIndex !=null ? chunkIndex : 0);} set;}
    public Integer chunkSize    {get{return chunkSize = (chunkSize !=null ? chunkSize : 0);} set;}
    public Boolean hasNextChunk {get;set;}
    public Boolean finishChunk  {get{return finishChunk = (finishChunk !=null ? finishChunk : false);} set;}
    public String  errorMessage {get;set;}
    public Boolean isError      {get;set;}
    public String recordId {get;set;}
    private static String COUPON_SELLERSTAGE_CONTRACT_TARGETED 	= 'Targeted';
	private static String COUPON_SELLER_STAGE_CONTRACT_REACHED 		= 'Reached';
	private static String COUPON_SELLER_STAGE_CONTRACT_NEGOTIATION 	= 'Contract Negotiation';
    Set<String> validDeleteCouponSellerStage = new Set<String>{
        COUPON_SELLERSTAGE_CONTRACT_TARGETED,
        COUPON_SELLER_STAGE_CONTRACT_REACHED,
        COUPON_SELLER_STAGE_CONTRACT_NEGOTIATION
    };
    
    private final Integer chunkSizeLimit = Integer.valueOf(System.Label.COUPONSELLER_MASSDELETE_CHUNK_SIZE_LIMIT);

    public MassDeleteCouponSellersController(ApexPages.StandardSetController controller) {
        recordId = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')+'');
        reUrl = controller.cancel().getUrl();
        selectedCouponSeller = (List<Coupon_Seller__c>)controller.getSelected();
        for (Coupon_Seller__c cs : selectedCouponSeller) {
            lstSelCSid.add(cs.Id);
        }
        List<Coupon_Seller__c> excludeData = [SELECT Id, Coupon_Seller_Stage__c FROM Coupon_Seller__c WHERE Id IN :lstSelCSid AND Coupon_Seller_Stage__c NOT IN :validDeleteCouponSellerStage];
        if(!excludeData.isEmpty()){
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Prevent_Deletion_of_Coupon_Seller));  
        }

        mChunkedCS = ApexUtil.chunkList(lstSelCSid,chunkSizeLimit);
        chunkSize = (Integer)mChunkedCS.get('chunkSize');//08.08.2024 / srong tin / US-0015656
    }

    public boolean isDeleteSuccess{get;set;}
    public void deleteRecordAction() {
        try{

            List<List<Object>> listAllCSChunk = (List<List<Object>>)mChunkedCS.get('listAllChunk');
            List<Id> listCSId = new List<Id>();
            for(Object objId : listAllCSChunk[chunkIndex]){
                listCSId.add((Id)objId);
            }

            if (!listCSId.isEmpty()) {

                List<Coupon_Seller__c> lstSelectedCs = new List<Coupon_Seller__c>();

                for (Id csId : listCSId) {
                    Coupon_Seller__c objcs = new Coupon_Seller__c(Id = csId);
                    lstSelectedCs.add(objcs);
                }

                // Delete Coupon Seller
                ApexSafe.dml().doDelete(lstSelectedCs,true);//08.08.2024 / srong tin / US-0015656

                chunkIndex++;
                if(chunkIndex >= chunkSize){
                    finishChunk = true;
                    isDeleteSuccess=true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM , 'Delete successfully!'));
                    
                }else{
                    hasNextChunk = true;
                }

            }

        }catch(Exception ex){

            String errMsg = ex.getMessage(); 
            if (errMsg.contains(Label.Prevent_Deletion_of_Coupon_Seller)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Prevent_Deletion_of_Coupon_Seller));  
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            }
            isDeleteSuccess=false;
            isError=true; 
        }
    }
}