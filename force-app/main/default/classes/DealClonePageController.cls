/*********************************************************************************************************************************
@ Class:          DealClonePageController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.08.2023 / Sambath Seng / US-0013761 - Clone Deal functionality should copy the Seller Contact
*********************************************************************************************************************************/
public with sharing class DealClonePageController {
    
    private ID dealId;
    Private EBH_Deal__c deal;
    // SB 10.08.2023 US-0013761
    private final static List<String> DEAL_CLONE_FIELDS_TO_COPY = new List<String>{'EBH_BusinessName__c','EBH_SellerEmail__c','EBH_ProductTitle__c','EBH_DealSiteId__c','EBH_MarketingTitle__c','EBH_Category__c','EBH_Vertical__c','EBH_SpotlightCategory__c','EBH_DealPrice__c','Seller_Contact__c'};
    public DealClonePageController(ApexPages.StandardController controller) {
        
        if (!test.isRunningTest()){
            // SB 10.08.2023 US-0013761
            controller.addFields(DEAL_CLONE_FIELDS_TO_COPY);
        }
        
        dealId = controller.getId();
        deal = (EBH_Deal__c)controller.getRecord();
        
        
    }
    
    public pageReference clonecustom(){
        
        EBH_Deal__c d = deal.clone();
        d.EBH_DealPrice__c=0;
        insert d;
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Record Cloned Successfully.Thank you!'));
        PageReference pg = new PageReference('/'+d.Id);
        pg.setRedirect(true);
        return pg; 
    }
}