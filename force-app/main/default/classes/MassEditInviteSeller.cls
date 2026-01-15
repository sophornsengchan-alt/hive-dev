/*********************************************************************************************************************************
@ Class:          MassEditInviteSeller
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0013334 - New fields and automations on Seller Invitation process
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.03.2023 / Sovantheany Dim / Created the class.
                : 30.11.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
                : 14.05.2024 / Sophal Noch / US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
                : 02.09.2025 / Seng Chan Sophorn / US-0033165 - Cohorts: Enable individual cohort seller changes
*********************************************************************************************************************************/
public with sharing class MassEditInviteSeller {
    public List<BoB_Seller__c > selectedCohortSeller{get;set;}
    public String reUrl{get;set;}
    // 30.11.2023 / Sophal Noch / US-0014362 : disable variable because no long need
    // public boolean isChangedSuccess{get;set;}
    // public boolean inviteSeller{get;set;}
    // public Integer chunkIndex   {get{return chunkIndex = (chunkIndex !=null ? chunkIndex : 0);} set;}
    // public Integer chunkSize    {get{return chunkSize = (chunkSize !=null ? chunkSize : 0);} set;}
    // public Boolean finishChunk  {get{return finishChunk = (finishChunk !=null ? finishChunk : false);} set;}
    // private final Integer CHUNK_SIZE_LIMIT = Integer.valueOf(System.Label.COHORT_SELLER_MASSEDIT_CHUNK_SIZE_LIMIT);
    // public Map<String,Object> mChunkedCS {get{return mChunkedCS = (mChunkedCS !=null ? mChunkedCS : new Map<String,Object>());} set;}
    public Boolean isError      {get;set;}
    // public Boolean hasNextChunk {get;set;}
    public String bobId {get;set;}
    public String listBsIdJson {get;set;}
    public Boolean isInitSuccess {get;set;}
    public Integer numSelected {get;set;}
    public Boolean hasPermis {get;set;}
    public Boolean isAdmin {get;set;}
    private final static String BOB_CATEGORY_PERMISSION = 'BoB_Category_Lead';
    private final static String BOB_ADS_PERMISSION = 'Advertising_Cohort_Lead';
    public String msg {get;set;}
    public String severity {get;set;}
    public String retUrl {get;set;} //CSP:02092025: US-0033165 
        
	public MassEditInviteSeller(ApexPages.StandardSetController controller) {
        // inviteSeller = false;
        bobId = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')).escapeHtml4(); // 02.09.2025 / Sophal Noch / US-0033165 : add escapeHtml4() to fix PMD warning
        //reUrl = controller.cancel().getUrl();
        reUrl = '/lightning/r/'+bobId+'/related/BoB_Sellers__r/view';
        selectedCohortSeller = (List<BoB_Seller__c >)controller.getSelected();
        numSelected = selectedCohortSeller.size();
		// mChunkedCS = ApexUtil.chunkList(selectedCohortSeller,CHUNK_SIZE_LIMIT);
        // chunkSize = (Integer)mChunkedCS.get('chunkSize');
        hasPermis = ApexUtil.checkPermissionSet(new Set<String>{BOB_CATEGORY_PERMISSION, BOB_ADS_PERMISSION});  // 30.11.2023 / Sophal Noch / US-0014362 : allow Advertising_Cohort_Lead to use
        isAdmin = (Userinfo.getprofileId() == ApexUtil.ADMIN_PROFILE_ID || Userinfo.getprofileId() == ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
       
        // 30.11.2023 / Sophal Noch / US-0014362 : check pro-trader
        BoB__c bob = CohortActionController.getBobWithId(bobId); // 14.05.2024 / Sophal Noch / US-0015200
        String inviteSellerPageUrl = Page.MassEditInviteSeller.getUrl();
        String currentUrl = ApexPages.currentPage().getUrl();
        Boolean isProTrader = CohortActionController.isProTrader(bob);
        isError = false;

        // CSP:02092025: US-0033165  start
        String retUrlParam = ApexPages.currentPage().getParameters().get('retUrl');
        if (String.isNotBlank(retUrlParam)) {
            retUrl = String.escapeSingleQuotes(retUrlParam).escapeHtml4();
        } else {
            retUrl = null;
        }
        // CSP:02092025: US-0033165  end
       
        if(!isAdmin && !hasPermis)
        {
            isError = true;
            msg = System.Label.ERR_MSG_NO_BOB_CATEGORY_LEAD_PERMIS_2;
            severity = ApexPages.severity.WARNING.name();
        }else if(currentUrl.toLowerCase().contains(inviteSellerPageUrl) && !isProTrader){ // 30.11.2023 / Sophal Noch / US-0014362 : if not pro-trader and use MassEditInviteSeller page, show error message
            isError = true;
            msg = Label.Error_InviteSeller_On_None_ProTrader;
            severity = ApexPages.severity.WARNING.name();
        }
        /* //  15.12.2023 / Sophal Noch / US-0014362
        else if(selectedCohortSeller.isEmpty()){
            isError = true; 
            msg = System.Label.Error_SelectAtLeaseOne;
            severity = ApexPages.severity.WARNING.name();
        }*/

        // 30.11.2023 / Sophal Noch / US-0014362 :
        List<String> listBsIds = new List<String>();
        for(BoB_Seller__c bs : selectedCohortSeller){
            listBsIds.add(bs.Id);
        }

        listBsIdJson = JSON.serialize(listBsIds); // need this as json so that it can be passed to aura and lwc
        isInitSuccess = true;
    }
    
    // public void updateInviteSeller() { // 30.11.2023 / Sophal Noch / US-0014362 : disable method because no long need
    //     try{
        
    //     List<List<Object>> listAllCSChunk = (List<List<Object>>)mChunkedCS.get('listAllChunk');
    //     List<BoB_Seller__c> listCS = new List<BoB_Seller__c>();
    //     for(Object obj : listAllCSChunk[chunkIndex]){
    //         listCS.add((BoB_Seller__c)obj);
    //     }
    //     if (!listCS.isEmpty()) {
    //         List<BoB_Seller__c> lstSelectedCs = new List<BoB_Seller__c>();
    //         for (BoB_Seller__c bs : listCS) {
    //             BoB_Seller__c objcs = new BoB_Seller__c(Id = bs.Id, Invite_Seller__c = inviteSeller);
    //             lstSelectedCs.add(objcs);
    //         }
    //         update lstSelectedCs;
    //         chunkIndex++;
            
    //         if(chunkIndex >= chunkSize){
                    
    //             finishChunk = true;
    //             isChangedSuccess=true;
    //             msg = 'Saved successfully!';
    //         	severity = ApexPages.severity.CONFIRM.name();
                
    //         }else{
    //             hasNextChunk = true;
                
    //         }
    //     }
    //    	}catch(DMLException dmx){
    //         msg = dmx.getDmlMessage(0);
    //         severity = ApexPages.severity.Error.name();
    //         isChangedSuccess=false;
    //         isError=true;
    //     }
    // }
    
    public pageReference cancelAction() {
        return new Pagereference(reUrl);
    }
    
}