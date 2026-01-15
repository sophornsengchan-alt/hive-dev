/*********************************************************************************************************************************
@ Class:          DealMassTimeEditController
@ Version:        1.0
@ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
@ Purpose:        US-0008179 - [US]* Deals Mass Edit Deal Times Process for Deals Managers
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.10.2020 / Loumang SENG / Created the class.
*********************************************************************************************************************************/
public with sharing class DealMassTimeEditController {
    public static final String NA_PROFILE = 'NA Standard User Base';
    public final static String US_MANAGE_DEAL_PERM='US_Manage_Deals';
    private final ApexPages.StandardSetController cntr;
    private final PageReference fromPage;
    private List<SObject> objs;
    public Boolean isStartTimeBigger {get;set;}
    public Boolean isUpdateError {get;set;}
    public Boolean isError {get;set;}
    public String errormessage {get;set;}
    public Integer selectedSize {get;set;}
    public Time startTime {get;set;}
    public Time endTime {get;set;}
   
    public DealMassTimeEditController(ApexPages.StandardSetController controller) {
       
        controller.setPageSize(1000);
        cntr = (ApexPages.StandardSetController)controller;
        fromPage = cntr.cancel();
        
        isError = false;
        String NAprofile = ApexUtil.getProfileByName(NA_PROFILE).Id;
        Boolean isNA = UserInfo.getProfileId().equals(NAprofile);
        Boolean isAdmin = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
        String currentUserId = UserInfo.getUserId();
        Boolean hasManageDealPerm = ApexUtil.checkPermissionSet(new Set<String>{US_MANAGE_DEAL_PERM});

       if (this.objs == null) {
            this.objs = (List<SObject>)cntr.getSelected();
            selectedSize = this.objs.size();
            if(!isAdmin && !isNA || (isNA && !hasManageDealPerm)){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, System.Label.NA_CANCEL_FUNC_ERR2));
                isError = true;
                return;
            }
       }
    }
    
    public PageReference cancel() {
        return fromPage;
    }
    
    // update deal start time and end time...
    public PageReference updateDeal(){
        try{
            if((startTime == null && endTime == null)){
                return null;
            }
            //if (startTime > endTime ){
            //    isStartTimeBigger = true;
            //    return null;
            //}
            List<EBH_Deal__c> deals = new List<EBH_Deal__c>();
            for(SObject oneDeal: objs){
                EBH_Deal__c deal = (EBH_Deal__c)oneDeal;
                if (startTime!=null) {
                     deal.EBH_DealStartTime__c = startTime;
                 }
                 if (endTime!=null) {
                     deal.EBH_DealEndTime__c = endTime;
                 }
                 deals.add(deal);
            }
            if(!deals.isEmpty()){
                update deals;
            }
         
        }catch(Exception e){
            isUpdateError = true;
            errormessage = e.getMessage();
        }
        
        return fromPage;
    }
   
}