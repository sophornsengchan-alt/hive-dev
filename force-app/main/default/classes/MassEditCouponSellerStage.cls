/*********************************************************************************************************************************
@ Class:          MassEditCouponSellerStage
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0009605 - Coupon Seller: mass update of stage button
@					As any user
@					Given that I am on the related of a Coupon record (either for Category Based or Item Based)
@					and I select All or a few coupon seller names
@					When I click on the button "Mass editstage"
@					I want to be able to mass update the field Coupon_Seller_Stage__c to the value "Reached" OR "Committed" OR "Negotiation" OR "Approved".
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.06.2021 / Sovantheany Dim / Created the class.
@                 08.02.2023 / Mony Nou / US-0012505 - Ability for NA users to bulk change stage to Internal Approval
@                 02.04.2024 / Mony Nou / US-0014557 - Bulk Coupon Approval process for NA
@               :  11.07.2024 / SRONG TIN / US-0015086 - Coupon Manager for bulk edit functions
@				: 16.06.2025 / Sambath Seng / US-0012493 - Update Error Message with correct details on Coupon(Seller) approve stage update
*********************************************************************************************************************************/
public without sharing class MassEditCouponSellerStage {
    public String reUrl{get;set;}
    //ApexPages.StandardSetController stdSetCtlr;
    public List<Coupon_Seller__c> selectedCouponSeller{get;set;}
    public boolean isCSStageOk{get;set;}

    //MN-08022023-US-0012505--START
    public List<Id> lstSelCSid {get{return lstSelCSid = (lstSelCSid !=null ? lstSelCSid : new List<Id>());} set;}
    public Map<String,Object> mChunkedCS {get{return mChunkedCS = (mChunkedCS !=null ? mChunkedCS : new Map<String,Object>());} set;}
    public Integer chunkIndex   {get{return chunkIndex = (chunkIndex !=null ? chunkIndex : 0);} set;}
    public Integer chunkSize    {get{return chunkSize = (chunkSize !=null ? chunkSize : 0);} set;}
    public Boolean hasNextChunk {get;set;}
    public Boolean finishChunk  {get{return finishChunk = (finishChunk !=null ? finishChunk : false);} set;}
    public String  errorMessage {get;set;}
    public Boolean isError      {get;set;}
    public String recordId {get;set;}//Start:11.07.2024 / SRONG TIN / US-0015086 
    
    private final Integer CHUNK_SIZE_LIMIT = Integer.valueOf(System.Label.COUPONSELLER_MASSEDIT_CHUNK_SIZE_LIMIT);
    //MN-08022023-US-0012505--STOP

    public MassEditCouponSellerStage(ApexPages.StandardSetController controller) {
        isCSStageOk = true;
        //stdSetCtlr = controller;
        reUrl = controller.cancel().getUrl();
        selectedCouponSeller = (List<Coupon_Seller__c>)controller.getSelected();
        selectedCouponSeller = [Select Id,Coupon_Seller_Stage__c From Coupon_Seller__c Where Id IN :selectedCouponSeller];
        //display a message saying "Only the stages before contract is sent can be updated"
        Set<String> sCoupounSellerStageOld = new Set<String>(System.label.CouponSellerStageOld.split(','));
        recordId = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')+'');

        //MN-02042024-US-0014557--START: If current user is a Bond Team's member => allow Coupon Seller with Stage = 'Sent for Approval' (label: Internal Approval)
        Set<String> sCouponSellerBondTeamQueue = new Set<String>(System.label.CouponSellerNABondTeamQueue.split(','));
        Map<Id, User> mBondTeam = ApexUtil.getUsersMemberByGroup(sCouponSellerBondTeamQueue);
        Boolean isAdmin = (Userinfo.getprofileId() == ApexUtil.ADMIN_PROFILE_ID || Userinfo.getprofileId() == ApexUtil.ADMIN_LT_PRIV_PROFILE_ID); 
        
        if (isAdmin || (!mBondTeam.isEmpty() && mBondTeam.containsKey(UserInfo.getUserId()))) { //ONLY ADMIN & BOND TEAM can update Coupon Seller with Stage = 'Sent for Approval'
            sCoupounSellerStageOld.add('Sent for Approval');
        }
        //MN-02042024-US-0014557--STOP

        for (Coupon_Seller__c cs : selectedCouponSeller) {
            if(!sCoupounSellerStageOld.contains(cs.Coupon_Seller_Stage__c)){
                isCSStageOk = false;
                break;
            }
            lstSelCSid.add(cs.Id); //MN-08022023-US-0012505
        }

        //MN-08022023-US-0012505
        if(isCSStageOk) {
            mChunkedCS = ApexUtil.chunkList(lstSelCSid,CHUNK_SIZE_LIMIT);
            chunkSize = (Integer)mChunkedCS.get('chunkSize');
        }
    }
    public pageReference cancelAction() {
       // return new Pagereference(reUrl);
       //Start:11.07.2024 / SRONG TIN / US-0015086 
       String url = '/lightning/r/Coupon__c/'+recordId + '/related/Coupon_Sellers__r/view';
        PageReference pg = new PageReference(url);
        pg.setRedirect(true);
        return pg;
    }
    public boolean isChangedSuccess{get;set;}
    public void updateStageAction() {
        try{

            //MN-08022023-US-0012505----START
            List<List<Object>> listAllCSChunk = (List<List<Object>>)mChunkedCS.get('listAllChunk');
            List<Id> listCSId = new List<Id>();
            for(Object objId : listAllCSChunk[chunkIndex]){
                listCSId.add((Id)objId);
            }

            if (!listCSId.isEmpty()) {

                List<Coupon_Seller__c> lstSelectedCs = new List<Coupon_Seller__c>();

                for (Id csId : listCSId) {
                    Coupon_Seller__c objcs = new Coupon_Seller__c(Id = csId, Coupon_Seller_Stage__c = selectedStageValue);
                    lstSelectedCs.add(objcs);
                }

                update lstSelectedCs;

                chunkIndex++;
                // System.debug('**** chunkIndex :: ' + chunkIndex + ' of ' + chunkSize);
                if(chunkIndex >= chunkSize){
                    
                    finishChunk = true;
                    isChangedSuccess=true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM , 'Saved successfully!'));

                }else{
                    hasNextChunk = true;
                    
                }

            }

            //MN-08022023-US-0012505----STOP


            /*
            for (Coupon_Seller__c cs : selectedCouponSeller) {
                Coupon_Seller__c objcs = new Coupon_Seller__c(Id = cs.Id,
                                     Coupon_Seller_Stage__c = selectedStageValue);
                lstSelectedCs.add(objcs);
            }
            if(!lstSelectedCs.isEmpty()) update lstSelectedCs;
            */
            
            

        }catch(Exception ex){

            //MN-04042024-US-0014557--START
            String errMsg = ex.getMessage();
            //Check if the error message is thrown from Trigger Before Insert => No need to add it in Apexpages because SF will automatically display all the error message that thrown via addError() method.
            // if (!errMsg.contains(Label.Label_Only_users_with_Coupon_Special_Permission_can_approve)) { //SB 16.06.2025 US-0012493
            if (!errMsg.contains(Label.MissingCouponSellerApproverGroup)) { //SB 16.06.2025 US-0012493
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));  
            }
            //MN-04042024-US-0014557--STOP

            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage())); ////MN-04042024-US-0014557

            isChangedSuccess=false;
            isError=true; //MN-08022023-US-0012505
            //return null;
        }
        
        //return new Pagereference(reUrl);
    }
    
    public string selectedStageValue {get; set;}
    public List<SelectOption> getStageSelected() { 
        Schema.DescribeFieldResult stageDescription = Coupon_Seller__c.Coupon_Seller_Stage__c.getDescribe(); 
		Set<String> sCoupounSellerStage = new Set<String>(System.label.CouponSellerStageNew.split(','));
 	 	List<SelectOption> options = new List<SelectOption>();
 	 	//options.add(new SelectOption('','--None--'));
 	 	for (Schema.Picklistentry pl : stageDescription.getPicklistValues())
        {
            if(sCoupounSellerStage.contains(pl.getValue())) options.add(new SelectOption(pl.getValue(),pl.getLabel()));
        }
 	 	return options;
  	}
    
}