/*********************************************************************************************************************************
@ Class:          Delete Coupon Co-invest
@ Version:        1.0
@ Author:         Chetra Sarom
@ Purpose:        22.11.2022/ 22.11.2022/ US-0012681 - Ability to delete Coupon Co-invest records in bulk
---------------------------------------------------------------------------------------------------------------------------------
@ change history: 10.03.2023 / Sambath Seng / US-0013214 - Cannot mass delete co-invest records
@                 10.04.2023 / Bora Chhorn / US-0013156 - Amend validation error message for co-invest deletion
*********************************************************************************************************************************/
public with sharing class BulkDeleteCouponCoinvestController {
    private final static String PROMOTIONS_USER_PERMISSION = 'Promotions_User';
    private final static String SOQL_COUPON_COINVESTS = 'SELECT Id, Coupon__r.RecordType.DeveloperName,Coupon_Seller__r.Coupon_Seller_Stage__c FROM Coupon_Co_Invest__c WHERE Id IN:selectedCohortSeller';
    public List<Coupon_Co_Invest__c> selectedCohortSeller {get;set;}
    public String reUrl{get;set;}
 
    public String msg {get;set;}
    public Integer numSelected {get;set;}
    public Boolean hasPermis {get;set;}
    public Boolean isAdmin {get;set;}

    public Boolean isDone {get;set;}  //when save button already clicked
    public Boolean isError {get;set;} //warning or error 
    public String severity {get;set;} // warning,info,error,confirm

    private String couponSellerId = null;
        
    public BulkDeleteCouponCoinvestController(ApexPages.StandardSetController controller) {
        selectedCohortSeller = (List<Coupon_Co_Invest__c>) controller.getSelected();
        numSelected = selectedCohortSeller.size();
        //reUrl = controller.cancel().getUrl();
        PageReference pgCurrent = ApexPages.currentPage(); 
        // 14.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set        
        // hasPermis = ApexUtil.checkPermissionSet(new Set<String>{PROMOTIONS_USER_PERMISSION});
        hasPermis = FeatureManagement.checkPermission(ApexUtil.COUPON_BULK_EDITS_CUSTOM_PERMISSION);
        isAdmin = (Userinfo.getprofileId() == ApexUtil.ADMIN_PROFILE_ID || Userinfo.getprofileId() == ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
        
        couponSellerId = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')==null? '' : ApexPages.currentPage().getParameters().get('id'));
        
        reUrl = String.isBlank(pgCurrent.getParameters().get('retURL')) ? '/lightning/r/'+couponSellerId+'/related/Coupon_Co_Invests__r/view' : String.escapeSingleQuotes(pgCurrent.getParameters().get('retURL'));
        isError = false;
        isDone = false;
        msg = System.Label.TEXT_QUESTION_FOR_DELETE_COUPON_COINVEST;
        severity = ApexPages.severity.INFO.name();
        Coupon_Seller__c cs = [Select Id,Coupon__c,Coupon_Seller_Stage__c,Coupon__r.RecordType.DeveloperName From Coupon_Seller__c where Id =:couponSellerId];
        if(!isAdmin && !hasPermis)
        {
            isError = true; 
            msg = System.Label.ERR_MSG_NO_PROMOTIONS_USER;
            severity = ApexPages.severity.WARNING.name();
        }else if(numSelected==0)
        {
            isError = true; 
            msg = System.Label.TEXT_MSG_FOR_UNABLE_TO_REMOVE_COUPON_COINVESTS;
            severity = ApexPages.severity.WARNING.name();
        }else if(cs.Coupon_Seller_Stage__c != 'Review') {
            isError = true; 
            msg = System.Label.TEXT_MSG_FOR_DELETE_COUPON_COINVEST;
            severity = ApexPages.severity.WARNING.name();
        }
    }

    public PageReference backToListView(){
        PageReference pageRef = new PageReference(reUrl);
        pageRef.setRedirect(true);
        return pageRef;
   }

   
   public PageReference deleteCouponCoInvest(){
       try {
            // delete [SELECT Id FROM Coupon_Co_Invest__c WHERE Id IN:selectedCohortSeller]; //Commented by SB 10.03.2023 US-0013214 - Cannot mass delete co-invest records
            WithoutSharing.doDelete([SELECT Id FROM Coupon_Co_Invest__c WHERE Id IN:selectedCohortSeller]); //SB 10.03.2023 US-0013214 - Cannot mass delete co-invest records
            
            isError = false; 
            msg = System.Label.DELETE_COUPON_COINVEST_SUCCESS;
            severity = ApexPages.severity.CONFIRM.name();      
            isDone = true;
        } catch (DMLException dmx) {          
                isError = true;  msg = dmx.getDmlMessage(0); severity = ApexPages.severity.FATAL.name(); // BR-10-04-2023US-0013156
        }
        return null;
    }
}