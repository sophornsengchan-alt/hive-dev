/*********************************************************************************************************************************
@ Class:          EBH_DistinctCampaignSellersController2
@ Version:        1.0
@ Author:         JOY MONDOL
@ Purpose:        Extension class for Visualforce Page - EBH_CampaignSellerList
                  To display Distinct Seller List on Sub-Campaign/Campaign & Programme Levels
                  Extensions for Unique Sellers List on all the hierarchy levels of Campaign
                  EPH-27, EPH-103 : Campaign Execution
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.07.2017 / JOY MONDOL / Created the class.
*********************************************************************************************************************************/
public with sharing class EBH_DistinctCampaignSellersController2 {

    public Id      CampaignId { get; set; }    //current campaign id
    public Set<Id> AccountIds { get; set; }    //final set of account ids to fetch for the current page
    
    public String SellersQuery {
        get {
            String query = EBH_ConstantsUtility.DCS_SELLERQUERY;
            String PLACEHOLDER = EBH_ConstantsUtility.DCS_BLANK;
            
            for(Schema.FieldSetMember fld : SObjectType.Account.FieldSets.EBH_CampaignSellers.getFields()) {
                PLACEHOLDER += EBH_ConstantsUtility.DCS_COMMA + fld.getFieldPath();
            }
            
            return !String.isBlank(PLACEHOLDER) ? query.replace(EBH_ConstantsUtility.DCS_PLACEH, PLACEHOLDER) : 
                   query.replace(EBH_ConstantsUtility.DCS_PLACEH, EBH_ConstantsUtility.DCS_BLANK);
        }
    }
    
    /*****************************************************************************************************************************
    @ Constructor:    EBH_DistinctCampaignSellersController2 
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        To get the Seller Id, passed through inline VF page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      controller: standard controller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public EBH_DistinctCampaignSellersController2(ApexPages.StandardController controller) {    
         campaignId = controller.getId();
         accountIds = new Set<Id>();
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchLowestLevelCampaignIds
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Used for get the lowest level of campaign ids in the hierarchy
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      campaignId: current campaign id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Set<Id>: lowest level campaign ids
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static Set<Id> fetchLowestLevelCampaignIds(Id campaignId) {
        
        Boolean hasChild = true;        
        
        Set<Id> campaignIds = new Set<Id> { campaignId };
        
        do {
            hasChild = false;
            
            for(Campaign campaign : Database.query(EBH_ConstantsUtility.DCS_CAMPQUERY)) {
                
                List<Campaign> camps = campaign.ChildCampaigns;
                
                if(!camps.isEmpty()) {
                    campaignIds.remove(campaign.Id);
                    
                    for(Campaign camp : camps) {
                        campaignIds.add(camp.Id);
                    }
                    
                    hasChild = true;
                }                
            }
        } while(hasChild);
        
        return campaignIds;
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchContactCount
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        fetches the contact count in db
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      campaignIds: lowest level campaign ids
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Integer: count
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static Integer fetchContactCount(List<Id> campaignIds) {        
        return Database.countQuery(EBH_ConstantsUtility.DCSC_COUNTQUERY);
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchSellers
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        fetches the related sellers from last level of campaign member contacts in the campaign hierarchy
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      campaignIds: lowest level campaign ids
                      iOffset:     custom offset
                      limit:       limit of rows
                      query:       account query icluding columns from fieldset
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map<Decimal, List<Account>>:  related contact accounts indexed  by last offset index - single item map
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static Map<Decimal, List<Account>> fetchSellers(List<Id> campaignIds, Decimal iOffset, Integer rows, String query) {        
        
        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        
        for(CampaignMember cm : Database.query(EBH_ConstantsUtility.DCSC_CAMPAIGNMEMBERQUERY)) {
            contactIds.add(cm.ContactId);
            iOffset = cm.EBH_SerialF__c;
        }
        
        for(AccountContactRelation acr : Database.query(EBH_ConstantsUtility.DCSC_ACRQUERY)) {
            accountIds.add(acr.AccountId);
        }
        return (!accountIds.isEmpty()) ? new Map<Decimal, List<Account>> { iOffset => Database.query(query) } : null;
    }
}