/*********************************************************************************************************************************
@ Class:          DRC_RedirectorController
@ Version:        1.0
@ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
@ Purpose:        Controller Class for Deal list view buttons pages in related list Deal Retail Campaign
@                  
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23-07-2021 / Loumang SENG / Created the class.	
@               : 27-01-2025 / Sovantheany Dim / US-0016410 - 5 - Bulk Subsidize Deals - Using the Bulk Subsidized Deals Button		  
*********************************************************************************************************************************/
public without sharing class DRC_RedirectorController {
    public List<EBH_Deal__c> selectedDeal{get;set;}
    public String pageId{get;set;}
    public String selectedIds{get;set;}
    //public String pageName{get;set;}

    //TH:US-0016410
    public Boolean hasPermis{get;set;}
    public Boolean isDCA{get;set;}
    private final static String SUBSIDIZE_DEAL_PERMISSION = 'US_Manage_Deals';
    private final static String DCA_SOBJECT_NAME = 'Deal_Contract_Agreement__c';

    public DRC_RedirectorController(ApexPages.StandardSetController controller) {
        //pageName = Apexpages.currentPage().getParameters().get('pageName');
        selectedDeal = controller.getSelected();
        pageId = Apexpages.currentPage().getParameters().get('id');
        selectedIds = '';
        for(EBH_Deal__c deal : selectedDeal){
            selectedIds += deal.Id + ',';
        }

        selectedIds = selectedIds != '' ? selectedIds.removeEnd(',') : selectedIds;
        
        //TH:US-0016410:check if current user have permission set : Promotions User - Subsidized Deals 
        hasPermis = ApexUtil.checkPermissionSet(new Set<String>{SUBSIDIZE_DEAL_PERMISSION}) || FeatureManagement.checkPermission(SUBSIDIZE_DEAL_PERMISSION);
        isDCA = false;
        if(String.isNotBlank(pageId)){
            Id parentId = (Id) pageId;
            String sObjectName = parentId.getSObjectType().getDescribe().getName();
            if(String.isNotBlank(parentId) && sObjectName.equalsIgnoreCase(DCA_SOBJECT_NAME)){ 
                isDCA = true;
            }
        }
        
    
    }
    
}