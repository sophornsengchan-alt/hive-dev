/*********************************************************************************************************************************
@ Class:          Batch_DRC_DealUpdate
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        DealRetailCampaignTriggerHandler.updateDealStatusByTimeBaseChange fix CPU limit
@ Change history: 06.July.2021 / SRONG TIN / Created the class.
---------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.August.2022 / Mony Nou / US-0011458 - AU Unsub Deal - Time Based Status Changes
@                 16.May.2023    / Mony Nou / US-0013603 - IT Deals Team - Need access to all the process in the Un-Sub Deals process for Deal Site = IT
@                 18.May.2023    / Mony Nou / US-0013507 - NA - Deal Window Submission Schedule Change - Time Based
*********************************************************************************************************************************/
global without sharing class Batch_DRC_DealUpdate implements Database.Batchable<SObject>{
     /****************************************************************************************************************************
	* CONSTANTS DEFINITION
	*****************************************************************************************************************************/
    private Set<ID> dealRetailCampaignIds;
    public static final String NA_Unsub_Deal = 'Deal_V3';
    // public Id spotlightUsVerticalsId = null; //MN-16082022-US-0011458 - Moved to use with mDefSpotLight
    public static final String OPS_REVIEW = 'Ops Review';
    //public static final String CM_REVIEW = 'CM Review'; //MN-18052023-US-0013507: No longer use this value
    public static final String SCHEDULED = 'Scheduled';
    public static final String RUNNING = 'Running';
    public static final String COMPLETED = 'Completed';
    // 29.July.2021 / SRONG TIN : US-0010037 
    private Set<String> STATUS_REJECTED_CANCELLED;

    Id dealRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_Deal__c', NA_Unsub_Deal).Id;
    private String whereCS = ' WHERE EBH_DealRetailCampaign__c IN: dealRetailCampaignIds AND RecordTypeId =: dealRecordTypeId';
    
    //MN-16082022-US-0011458 - Add EBH_DealRetailCampaign__r.EBH_Country__c into below soql query
	private final static String SOQL_DEAL = 'SELECT Id, EBH_Status__c,EBH_DealRetailCampaign__c,EBH_DealRetailCampaign__r.Status__c,EBH_DealRetailCampaign__r.EBH_Country__c,EBH_SpotlightCategory__c FROM EBH_Deal__c' ;
    
    private final static String DEALSITE_US = '0'; //MN-16082022-US-0011458
    private final static String DEALSITE_AU = '15'; //MN-16082022-US-0011458
    private final static String DEALSITE_IT = '101'; //MN-16052023-US-0013603 
    
    public Map<String, Id> mDefSpotLight = new Map<String, Id> { //MN-16082022-US-0011458
        DEALSITE_US => null,
        DEALSITE_AU => null
    };
    /************************************END CONSTANTS DEFINITION*************************************************************/

    public Batch_DRC_DealUpdate(set<Id> dealRetailCampaignIds) {
        this.dealRetailCampaignIds = dealRetailCampaignIds;
        //get US defualt Spotlight Category if field Spotlight Category == null
        for(EBH_SpotlightCategory__c spl: [SELECT Id FROM EBH_SpotlightCategory__c WHERE  Name = :Label.US_UnSubDeal_Default_Spotlight limit 1]){
            // spotlightUsVerticalsId = spl.Id; //MN-16082022-US-0011458 - Moved to use with mDefSpotLight
            mDefSpotLight.put(DEALSITE_US, spl.Id);
        }

        //get AU defualt Spotlight Category if field Spotlight Category == null
        for(EBH_SpotlightCategory__c spl: [SELECT Id FROM EBH_SpotlightCategory__c WHERE  Name = :Label.AU_UnSubDeal_Default_Spotlight limit 1]){
            mDefSpotLight.put(DEALSITE_AU, spl.Id);
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) 
    {        
        return Database.getQueryLocator(SOQL_DEAL + whereCS);
    }

    global void execute(Database.BatchableContext pBc, List<EBH_Deal__c> scope)
    {
        List<EBH_Deal__c> listDeals = new List<EBH_Deal__c>();
        // 29.July.2021 / SRONG TIN : US-0010037 
        STATUS_REJECTED_CANCELLED = new Set<String>{'Cancelled','Rejected'};
        for(EBH_Deal__c oDeal : scope){

            /* MN-18052023-US-0013507 - Remove "CM Review" from below criteria => NA, AU & IT will only use Ops Review
            //MN-16082022-US-0011458 - Add Criteria != AU  into below condition => it work only for NA
            if(oDeal.EBH_DealRetailCampaign__r.Status__c == CM_REVIEW && oDeal.EBH_Status__c == OPS_REVIEW && oDeal.EBH_DealRetailCampaign__r.EBH_Country__c != DEALSITE_AU){
                 // 2 Days at 18:00:00 PST before Deal Window Start Date: 
                 oDeal.EBH_Status__c = CM_REVIEW;
            }
            //MN-16082022-US-0011458 - Edit below condition to work for both NA & AU
            //MN-16052023-US-0013603 - Added IT into below condition
            //else if(oDeal.EBH_DealRetailCampaign__r.Status__c == SCHEDULED && ((oDeal.EBH_Status__c == CM_REVIEW && oDeal.EBH_DealRetailCampaign__r.EBH_Country__c != DEALSITE_AU) || (oDeal.EBH_Status__c == OPS_REVIEW && (oDeal.EBH_DealRetailCampaign__r.EBH_Country__c == DEALSITE_AU ||oDeal.EBH_DealRetailCampaign__r.EBH_Country__c == DEALSITE_IT )))){
            */
            
            //MN-18052023-US-0013507 - Remove "CM Review" from below criteria => NA, AU & IT will only use Ops Review
            if(oDeal.EBH_DealRetailCampaign__r.Status__c == SCHEDULED && oDeal.EBH_Status__c == OPS_REVIEW){
                 // When 1 Day at 18:00:00 PST before Deal Window Start Date:
                 oDeal.EBH_Status__c = SCHEDULED;
                /*//MN-16082022-US-0011458
                 // If Spotlight Category is NULL, Update 'Spotlight Category' field to 'US Verticals' Category
                if( String.isBlank(oDeal.EBH_SpotlightCategory__c) &&
                    String.isNotBlank(spotlightUsVerticalsId)){
                    oDeal.EBH_SpotlightCategory__c = spotlightUsVerticalsId;
                }
                */

                //MN-16082022-US-0011458
                // If Spotlight Category is NULL, Update 'Spotlight Category' field to default Category based on DRC.Deal Site
                if ( String.isBlank(oDeal.EBH_SpotlightCategory__c) && mDefSpotLight.containsKey(oDeal.EBH_DealRetailCampaign__r.EBH_Country__c) && mDefSpotLight.get(oDeal.EBH_DealRetailCampaign__r.EBH_Country__c) != null) {
                    oDeal.EBH_SpotlightCategory__c = mDefSpotLight.get(oDeal.EBH_DealRetailCampaign__r.EBH_Country__c);
                }

            // 29.July.2021 / SRONG TIN : US-0010037 
            }else if(oDeal.EBH_DealRetailCampaign__r.Status__c == RUNNING && !STATUS_REJECTED_CANCELLED.contains(oDeal.EBH_Status__c)){
                 // When Deal Window Start Date is reached:
                 oDeal.EBH_Status__c = RUNNING;
             }else if(oDeal.EBH_DealRetailCampaign__r.Status__c == COMPLETED && !STATUS_REJECTED_CANCELLED.contains(oDeal.EBH_Status__c)){
                 // When Deal Window End Date is reached:
                 oDeal.EBH_Status__c = COMPLETED;
             }

             // add list of Deals
             listDeals.add(oDeal);
         }
         if(!listDeals.isEmpty()){
             // update list of Deals
             update listDeals;
         }
		 
    }  
    
    
    global void finish(Database.BatchableContext pBc)
    {
        
    }
}