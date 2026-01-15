/*********************************************************************************************************************************
@ Class:          RemoveCohortSellerController
@ Version:        1.0
@ Author:         Sreymeas Nao 
@ Purpose:        US-0008068: [LTTM] Bulk Removal of Cohort Sellers capability and Field Label Change
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.08.2020 / Sreymeas Nao / Created the class.  
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.09.2021 / Mony Nou / US-0010407 - [BoB] Empty Seller."Owner" when Category Leads click "Remove Sellers"
@                   21/06/2022 / Sovantheany Dim / US-0011890 - Grant "NA Standard User base" users with access to Light touch Pro-trader and aSelleration capablities
@                   16.03.2023 / Sovantheany Dim / US-0013334 - New fields and automations on Seller Invitation process
@                   30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
*********************************************************************************************************************************/
public without sharing class RemoveCohortSellerController {
    private final static String BOB_CATEGORY_PERMISSION = 'BoB_Category_Lead';
    private final String ADS_COHORT_PERMISSION = 'Advertising_Cohort_Lead'; // 30.01.2024 / Sophal Noch / US-0014277
    private final static String NA_STANDARD_PERMISSION = 'US_CA_Standard_user';//TH:21/06/2022:US-0011890
    public List<BoB_Seller__c> selectedCohortSeller {get;set;}
    public String reUrl{get;set;}
 
    public String msg {get;set;}
    public Integer numSelected {get;set;}
    public Boolean hasPermis {get;set;}
    public Boolean isAdmin {get;set;}

    public Boolean isDone {get;set;}  //when save button already clicked
    public Boolean isError {get;set;} //warning or error 
    public String severity {get;set;} // warning,info,error,confirm
    public Boolean isInit {get;set;}

    public String bobId {get;set;} 
    public String listBsIdJson {get;set;}

    public RemoveCohortSellerController(ApexPages.StandardSetController controller) {
        selectedCohortSeller = (List<BoB_Seller__c>)controller.getSelected();
        numSelected = selectedCohortSeller.size();
        //reUrl = controller.cancel().getUrl();
         
        hasPermis = ApexUtil.checkPermissionSet(new Set<String>{BOB_CATEGORY_PERMISSION, NA_STANDARD_PERMISSION, ADS_COHORT_PERMISSION});
        isAdmin = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
        
        bobId = ApexPages.currentPage().getParameters().get('id');
        reUrl = '/lightning/r/'+bobId+'/related/BoB_Sellers__r/view';
        isError = false;
        isDone = false;
        msg = System.Label.TEXT_MSG_FOR_REMOVE_SELLER;
        severity = ApexPages.severity.INFO.name();
        

        if(!isAdmin && !hasPermis)
        {
            isError = true; 
            msg = System.Label.ERR_MSG_NO_BOB_CATEGORY_LEAD_PERMIS;
            severity = ApexPages.severity.WARNING.name();
        }else if(numSelected==0)
        {
            isError = true; 
            msg = System.Label.TEXT_MSG_FOR_UNABLE_TO_REMOVE_SELLER;
            severity = ApexPages.severity.WARNING.name();
        }


        // 30.01.2024 / Sophal Noch / US-0014277 : return listBsIdJson to client side to call aura
        List<String> listBsIds = new List<String>();
        for(BoB_Seller__c bs : selectedCohortSeller){
            listBsIds.add(bs.Id);
        }
        listBsIdJson = JSON.serialize(listBsIds); 
        isInit = !isError ? true : false;

    }

    public PageReference backToListView(){
        PageReference pageRef = new PageReference(reUrl);
        pageRef.setRedirect(true);
        return pageRef;
   }

}