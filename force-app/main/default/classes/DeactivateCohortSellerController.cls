/*********************************************************************************************************************************
@ Class:          DeactivateCohortSellerController
@ Version:        1.0
@ Author:         Chetra Sarom
@ Purpose:        14.07.2022/ US-0012010 - Add New Button "Deactivate Sellers" Button next to "Remove Sellers"
@ Change history: 24.04.2023 / US-0013479 - Pro Trader Plus Seller Rejection Process
@               : 17.10.2023 / Sophal Noch / US-0014207 - ADS - Cohort - Bulk Deactivate Sellers
@               : 11.12.2023 / Sophal Noch / US-0014363 - Ph 1 - Deactivate Sellers button
@               : 02.09.2025 / Seng Chan Sophorn / US-0033165 - Cohorts: Enable individual cohort seller changes
*********************************************************************************************************************************/
public with sharing class DeactivateCohortSellerController {
    private final static String BOB_CATEGORY_PERMISSION = 'BoB_Category_Lead';
    private final String ADS_COHORT_PERMISSION = 'Advertising_Cohort_Lead';

    private final String RTYPE_BOB_ADS_COHORT = 'Advertising_Cohort';

    public List<BoB_Seller__c> selectedCohortSeller {get;set;}
    public String reUrl{get;set;}
 
    public String msg {get;set;}
    public Integer numSelected {get;set;}
    public Boolean hasPermis {get;set;}
    public Boolean isAdmin {get;set;}

    public Boolean isDone {get;set;}  //when save button already clicked
    public Boolean isError {get;set;} //warning or error 
    public String severity {get;set;} // warning,info,error,confirm
    // BR-24-04-23-US-0013479
    public Boolean isShow {get;set;} 
    public BoB_Seller__c bob_seller {get;set;} // BR-24-04-23-US-0013479
    public String deactivation_reason_note {get;set;}
    // END

    public Boolean isInit{get;set;}
    public String listBsIdJson {get;set;}
    public Boolean isBatchRunning{get;set;}

    //CSP:02092025: US-0033165 
    public String retUrl {get;set;}
    

    public String bobId  {get;set;}
    public DeactivateCohortSellerController(ApexPages.StandardSetController controller) {

        // BR-24-04-23-US-0013479
        bob_seller = new BoB_Seller__c();
        deactivation_reason_note = System.Label.DEACTIVATION_REASON_NOTE; 
        // END
        selectedCohortSeller = (List<BoB_Seller__c>)controller.getSelected();
        numSelected = selectedCohortSeller.size();
        //reUrl = controller.cancel().getUrl();
         
        hasPermis = ApexUtil.checkPermissionSet(new Set<String>{BOB_CATEGORY_PERMISSION, ADS_COHORT_PERMISSION}); // 17.10.2023 / Sophal Noch / US-0014207 : add ps 'Advertising_Cohort_Lead' to exist Set<String>
        isAdmin = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
        
        bobId = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')).escapeHtml4(); // 02.09.2025 / Sophal Noch / US-0033165 : add escapeHtml4() to fix PMD warning

        // CSP:02092025: US-0033165  start
        String retUrlParam = ApexPages.currentPage().getParameters().get('retUrl');
        if (String.isNotBlank(retUrlParam)) {
            retUrl = String.escapeSingleQuotes(retUrlParam).escapeHtml4();
        } else {
            retUrl = null;
        }
        // CSP:02092025: US-0033165  end
       
        // retUrl=null;
        reUrl = '/lightning/r/' + bobId + '/related/BoB_Sellers__r/view';
        
        isError = false;
        isDone = false;
        isShow = false; // BR-24-04-23-US-0013479
        msg = System.Label.TEXT_MSG_FOR_DEACTIVATE_SELLER;
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

        List<String> listBsIds = new List<String>();
        for(BoB_Seller__c bs : selectedCohortSeller){
            listBsIds.add(bs.Id);
        }

        // 11.12.2023 / Sophal Noch / US-0014363 :
        isInit = true;
        listBsIdJson = JSON.serialize(listBsIds); 
        if(!isError && CohortActionController.getBatchIsRunning()){  isShow = true; }
        
    }

    public PageReference backToListView(){
        PageReference pageRef = new PageReference(reUrl);
        pageRef.setRedirect(true);
        return pageRef;
   }

   
   public PageReference deactivateSellers(){
       try {
            
            /* 

            11.12.2023 / Sophal Noch / US-0014363 :

            // US-0012010 - Amends to "Remove Sellers" Button 
            List<Account> lstAcc = new List<Account>();
            List<BoB_Seller__c> lstBS = new List<BoB_Seller__c>();
            Boolean isAdsBob = [Select Id From BoB__c Where Id=:bobId And RecordType.DeveloperName =: RTYPE_BOB_ADS_COHORT Limit 1].isEmpty() ? false : true; // 17.10.2023 / Sophal Noch / US-0014207


            for (BoB_Seller__c bs : [SELECT Id, Seller__c,Status__c FROM BoB_Seller__c WHERE Id IN:selectedCohortSeller]) {
                lstBS.add(new BoB_Seller__c(
                    Id = bs.Id,
                    Status__c = 'Inactive'
                ));
                if(!isAdsBob){
                    lstAcc.add(new Account(
                        Id = bs.Seller__c,
                        Managed_Type__c = '',
                        OwnerId = ApexUtil.INTEGRATION_USER_ID,
                        EBH_BOBManaged__c = false,
                        EBH_BOBSegment__c = '',
                        EBH_BOBVertical__c= '',
                        EBH_BOBCNTRY__c= '',
                        EBH_AccountManageName__c = ''
                    ));
                }else{
                    // 17.10.2023 / Sophal Noch / US-0014207 : clear field for BoB__c.RecordType.DeveloperName = 'Advertising_Cohort'
                    lstAcc.add(new Account(Id = bs.Seller__c, Brand_Engagement_Lead__c = null, PL_Segment__c = null));
                }

            }

            update lstBS;
            update lstAcc;
            */
            
            isError = false; 
            msg = System.Label.DEACTIVATE_COHORSELLER_SUCCESS;
            severity = ApexPages.severity.CONFIRM.name();      
            isDone = true;
       } catch (DMLException dmx) {          
            isError = true;  msg = dmx.getMessage(); severity = ApexPages.severity.FATAL.name();   
       }
       
        return null;
    }
    /*********************************************************************************************************************************
    @ Method:         deactivationReason
    @ Version:        1.0
    @ Author:         Bora CHHORN
    @ Purpose:        US-0013479 - Pro Trader Plus Seller Rejection Process
    @ Change history: 02.09.2025 / Sophal Noch / US-0033165 - Cohorts: Enable individual cohort seller changes
    *********************************************************************************************************************************/
    public PageReference deactivationReason(){
        try {
            List<BoB_Seller__c> lstBS = new List<BoB_Seller__c>();
            for (BoB_Seller__c bs : (List<BoB_Seller__c>)(ApexSafe.query().secCheck(false).doQuery('SELECT Id,Deactivation_Reason__c FROM BoB_Seller__c WHERE Id IN:selectedCohortSeller', new Map<String, Object>{'selectedCohortSeller' => selectedCohortSeller}))) { // 02.09.2025 / Sophal Noch / US-0033165 : change static query to ApexSafe
                lstBS.add(new BoB_Seller__c(
                    Id = bs.Id,
                    Deactivation_Reason__c = bob_seller.Deactivation_Reason__c
                ));
            }
            ApexSafe.dml().secCheck(false).doUpdate(lstBS, true); // 02.09.2025 / Sophal Noch / US-0033165 : change to ApexSafe
            isShow = true;
        } catch (DMLException dmx) {         
            isError = true;  deactivation_reason_note = dmx.getMessage(); severity = ApexPages.severity.FATAL.name();   
        }
        return null;
    }
}