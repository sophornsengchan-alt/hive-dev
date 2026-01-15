/*********************************************************************************************************************************
@ Class:          EBH_CampaignMemberRefreshController
@ Version:        1.0
@ Author:         ASHISH BARANWAL 
@ Purpose:        Controller Class for CampaignMember refresh
                  EPH-31 : Campaign Review and Measurement
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.06.2017 / ASHISH BARANWAL / Created the class.
@				  25.09.2018/ Vadhanak Voun		/EPH-6484 Add campaign members in SFMC journeys. AC5
@				 04.12.2018/ Vadhanak Voun / EPH-6817 Hide "Refresh Members" button
@				 02.11.2022/ Sophal Noch / US-0012514 - Error refresh campaign member with seller list 50K
*********************************************************************************************************************************/
public with sharing class EBH_CampaignMemberRefreshController {
    
    public Boolean CampaignExecuted { get; set; }
    public Boolean SellerListSelected { get; set; }
    Id campaignId;
    Campaign camp;
	
	public Boolean validationError { get; set; }
    public String validateErrorMsg { get; set; }
    
    public Boolean isAdmin {get;set;}
    public Boolean unBlocked {get;set;}
	public Boolean isSuccess {get;set;}
    public Boolean isQueryLimitError {get;set;}
    /*****************************************************************************************************************************
    @ Method:         EBH_CampaignMemberRefreshController
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL 
    @ Purpose:        initialization of parameters
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      ApexPages.StandardController controller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.06.2017 / ASHISH BARANWAL  / Created the  Method.
	@				  25.09.2018/ Vadhanak Voun		/EPH-6484 Add campaign members in SFMC journeys. AC5
	@				  16.10.2018/ Vadhanak Voun 	/ EPH-6562
	@						AC1: (this should be existing)
	@						Given that I have the "Refresh Members" button
	@						And I navigate to the Campaign that is "Campaign Running" and beyond
	@						When I click on the button
	@						Then I receive the error message "You cannot refresh your campaign members after a Campaign is executed."
	@				 30.12.2018: EPH-6825 Add /Delete Multiple Seller Lists to Outreach
	@					Natalia's Comment:
	@					Any User can perform steps in AC1- AC4 if record type of the Campaign = Outreach and Channel = AM Outreach
	@					Only GCX Super and Marketing User can perform steps in AC1-AC4 if record type of the Campaign = Outreach and Channel = GCX Outbound
	@					(Phone) & GCX Inbound (Phone).
    *****************************************************************************************************************************/
    public EBH_CampaignMemberRefreshController(ApexPages.StandardController controller) {
    	isAdmin = UserInfo.getProfileId()==EBH_ConstantsUtility.ADMIN_PROFILE_ID;
    	 
        campaignId = controller.getId();
        //query campaign details and based on the status the member refresh functionality will be invoked
        camp = Database.query(EBH_ConstantsUtility.CMRC_QUERY);
        campaignExecuted = false;
        //isSuccess = true;
        
        //allowed only Outreach recordtype and  master/sub for admin
        unBlocked = (camp.RecordType.DeveloperName.equalsIgnoreCase(EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH)
        			|| (isAdmin && (camp.RecordType.DeveloperName.equalsIgnoreCase(EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE) ||
        					camp.RecordType.DeveloperName.equalsIgnoreCase(EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE)) )
        			);
        
        if( camp.RecordType.DeveloperName.equalsIgnoreCase(EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE)){
          
            CampaignExecuted = (camp.Parent.Status == EBH_ConstantsUtility.CMRC_EXECUTION || 
                           camp.Parent.Status == EBH_ConstantsUtility.CMRC_CANCELLED ||
                           camp.Parent.Status == EBH_ConstantsUtility.CMRC_COMPLETED ) ;
        }
        
        if(camp.RecordType.DeveloperName.equalsIgnoreCase(EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE)){
            
              CampaignExecuted = (camp.Status == EBH_ConstantsUtility.CMRC_EXECUTION || 
                           camp.Status == EBH_ConstantsUtility.CMRC_CANCELLED ||
                           camp.Status == EBH_ConstantsUtility.CMRC_COMPLETED ) ;
        
        }
        //SellerListSelected = !String.isBlank(camp.EBH_SellerList__c);
        //single SellerList no longer use
        SellerListSelected = !Database.query(EBH_ConstantsUtility.SOQL_CAMP_TARGET_SELLERLIST + ' Where Campaign__c=:campaignId LIMIT 1').isEmpty();
		validationError = false;
        //if(camp.EBH_ChannelMP__c == EBH_ConstantsUtility.CAMPAIGN_CHANNEL_PHONE_OUTREACH || camp.EBH_Channel__c == EBH_ConstantsUtility.CAMPAIGN_CHANNEL_PHONE_OUTREACH )
        //updated by DHE 16/11/2018
        //EPH-6761
        //if((camp.ebh_channelmp__c!=null && camp.EBH_ChannelMP__c.indexOfIgnoreCase(EBH_ConstantsUtility.CAMPAIGN_CHANNEL_PHONE_OUTREACH)>0) || camp.EBH_Channel__c == EBH_ConstantsUtility.CAMPAIGN_CHANNEL_PHONE_OUTREACH )
        //{	
			//NK:27/09/2018
        	//The validation should not be applied if the there is only value selected in Channel field which is Phone Outreach (Single select)
			//For all other combinations the validation should apply including a scenario where multiple channels are selected for example Phone Outreach + Email
			
        	//validationError = true;
        	//validateErrorMsg = System.Label.ErrorPhoneOutreachNotAllowed;
       // }else
        //{
        	if(camp.Journey_ID__c==null && camp.RecordType.DeveloperName!='EBH_AMOutreach') // Added exclusion for recordtype am outreach DHE 2018-11-30
        	{
        		validateErrorMsg = System.Label.ErrorEmptyJourneyId;
        		validationError = true;
        	}else if(camp.Journey_ID__c <> null && camp.Journey_Status__c <> EBH_ConstantsUtility.JOURNEY_STATUS_PUBLISHED)
        	{
        		validateErrorMsg = System.Label.ErrorInvalidJourneyStatus;
        		validationError = true;
        	}
        //}  
        //EPH-6825
        //Any User can perform steps in AC1- AC4 if record type of the Campaign = Outreach and Channel = AM Outreach
		//Only GCX Super and Marketing User can perform steps in AC1-AC4 if record type of the Campaign = Outreach and Channel = GCX Outbound
		//(Phone) & GCX Inbound (Phone).
        
        Boolean isMarketingUser = UserInfo.getProfileId().equals(EBH_ConstantsUtility.PROFILE_ID_MARKETING);
        Boolean isGCXSuperUser = EBH_CampaignTriggerHandler.checkGCXSuperUser();
        Set<String> setGCXAllow = new Set<String>{EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL,EBH_ConstantsUtility.CAMP_CHANNEL_GCXINBOUND_PHONE };
        if((camp.RecordType.DeveloperName.equalsIgnoreCase(EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH) &&  camp.EBH_Channel__c== EBH_ConstantsUtility.CAMP_CHANNEL_AM_OUTREACH)
        	|| ( (isGCXSuperUser || isMarketingUser) && camp.RecordType.DeveloperName.equalsIgnoreCase(EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH) && setGCXAllow.contains(camp.EBH_Channel__c))
        )
        {
        	
        	
        }else
        {
        	validateErrorMsg = 'User not allowed or invalid channel.';
        	validationError = true;
        }
        
		//NK: 16.10.2018 EPH-6562
        if(camp.Status == EBH_ConstantsUtility.CMRC_EXECUTION)
        {
        	validateErrorMsg = System.Label.ErrorCampaignMemberRefresh_Executed;
        	validationError = true;
        }   
    }
    /*****************************************************************************************************************************
    @ Method:         refreshFilter
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL 
    @ Purpose:        refresh campaign member
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      no parameter
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.06.2017 / ASHISH BARANWAL  / Created the  Method.
					:  28.01.2020/ LoumAng/ US-0001246-Campaign Members are successfully refreshed
                    :  02.11.2022/ Sophal Noch / US-0012514 - Error refresh campaign member with seller list 50K
    *****************************************************************************************************************************/
    public PageReference refreshFilter() {
    	 
        //IF campaign status is not executed or cancelled and if seller list is added to the campaign
        if(!CampaignExecuted && SellerListSelected && !validationError && unBlocked) { //NK:04/12/2018:EPH-6817: unBlocked
             //EPH-5628 - to capture member last refresh date when refresh members button has been clicked
            //camp.EBH_MemberLastRefreshDate__c = System.now();
            //update camp;
            ////LoumAng: 01/28/2020: US-0001246-Campaign Members are successfully refreshed
            
            // isSuccess = true; // 02.11.2022 / Sophal Noch / US-0012514 : move near end of the method
            
            // System.debug('isSuccess>>> '+ isSuccess);
            Set<Id> campaignIds = new Set<Id>{campaignId};
            // Integer numMember = Database.countQuery(EBH_ConstantsUtility.DCSC_COUNTQUERY); 
            // 02.11.2022 / Sophal Noch / US-0012514 add " limit 1" because we only need to check whether campaign member exist or not.
            Integer numMember = Database.countQuery(EBH_ConstantsUtility.DCSC_COUNTQUERY + ' Limit 1');

            // 02.11.2022 / Sophal Noch / US-0012514 : query seller list id and count all seller targetings to check with query limit
            Set<Id> setSellerListId = new Set<Id>();
            for(Campaign_Targeting__c campTagr : [Select Seller_List__c From Campaign_Targeting__c Where Campaign__c IN: campaignIds]){
                if(campTagr.Seller_List__c != null )setSellerListId.add(campTagr.Seller_List__c);
            }
            Integer countSellerTarg = [SELECT count() From EBH_TargetedSeller__c Where EBH_SellerList__c IN : setSellerListId];
            if(countSellerTarg > Integer.valueOf(Label.RefreshCMQueryRowLimit)){ isQueryLimitError = true; return null; } // 02.11.2022 / Sophal Noch / US-0012514 : currently Label.RefreshCMQueryRowLimit = 47000.

            if(numMember >0 )
            {
            	//batch update existing members 
            	EBH_InsertCampaignMemberBatch cmBatch = new EBH_InsertCampaignMemberBatch(campaignIds);
        		Database.executeBatch(cmBatch,200);
            	
            } 
            else //create new
            {
            	EBH_CampaignTriggerHandler.createCampaignMemberRecords((Database.query(EBH_ConstantsUtility.CMRC_QUERY)));
            }
            //System.debug('page reference' + new PageReference('/' + campaignId));
     
            // 02.11.2022 / Sophal Noch / US-0012514 set isSuccess to true after no error
            isSuccess = true;
            System.debug('isSuccess>>> '+ isSuccess);

        }
        
        return null;
        
    }
}