/*********************************************************************************************************************************
@ Class:          EBH_InsertCampaignMemberBatch
@ Version:        1.0
@ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
@ Purpose:        Batch class to insert Campaign Member
                  EPH-106 : Campaign Member creation
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the class.
@				: 29.12.2018/ Vadhanak Voun (vadhanak.voun@gaea-sys.com) / EPH-6825 Add /Delete Multiple Seller Lists to Outreach
@				: 15.03.2019/ Vadhanak Voun (vadhanak.voun@gaea-sys.co)/ [#EPH-7023] Notification_ # sellers were not transfered to campaign members [Error] 
@				: 02/01/2020: US-0006483 Hypercare Bug - Create Tasks for Refreshed Members - Original tasks remain open
@							Test at: EBH_CampaignTriggerHandlerTest
@				: 08/03/2022/ vadhanak voun/ US-0008153 - Outreach tasks Trigger Deletion if Campaign Members response code 10 or 40
@				: 20/05/2022/ Sophal Noch / US-0011717 - Enable new column "Campaign Related Seller Details" in the Target List to create/update Key metrics in campaign members
@				: 09/06/2022 Sophal Noch / US-0011923 - Revert code from US-0008153 to resolve the issue on Task deletion in campaign outreach
@				: 19.03.2025 / Sambath Seng / US-0016682 - [Dev Only] Apex Class Classification to upgrade API version 3/5
*********************************************************************************************************************************/

global with sharing class EBH_InsertCampaignMemberBatch implements Database.Batchable<SObject>, Database.Stateful{
    static final String SOQL_CAM_MEMBER = 'Select Campaign_Related_Seller_Details__c, Contact.Account.OwnerId,Contact.Account.Outreach_Manager__c,Contact.EBH_DoNotContact__c,Contact.Incorrect_Phone_Number__c,Campaign.RecordTypeId,Campaign.EBH_Channel__c,Campaign.Campaign_Type__c,Campaign.EBH_Site__c ,Id,Contact.EBH_PhoneOptOut__c,Contact.Primary_Contact__c,LeadId,Campaign.EBH_MemberLastRefreshDate__c,contact.Name,contact.firstname,contact.lastname,lead.name,campaign.ownerId,Campaign.Triggered_Send_Name__c,CampaignId,Campaign.ParentId,Campaign.Parent.RecordType.DeveloperName,Campaign.RecordType.DeveloperName, ContactId, campaign.survey_id__c,Contact.AccountId, EBH_ResponseCode__c,EBH_LastResponseDate__c,EBH_FirstResponseDate__c,Marketing_Cloud_Status__c From CampaignMember';
	final static String CMRC_CANCELLED     = 'Cancelled';
    //list of AccountContactRelation queried by accountid
    global final String AccountContactReleationQuery = EBH_ConstantsUtility.CTH_ACRQUERY;
    //map of seller list id and list of targeted seller
    global final Map<Id,List<EBH_TargetedSeller__c>> sellerListTargetedSellerMap;
    //campaign map to store the campaign 
    global final Map<Id, Campaign> sellerIdCampaignMap;
    //set to store account ids
    global final Set<Id> accountIds;
    //set to store campaign ids
    global final Set<Id> campaignIds; 
    
    global final Boolean toUpdate; //create new member or update existing?
    
    private Map<String,Set<String>> mapCampaignSellerLists; //map Campaign with multiple Seller List set
    private Map<String,Set<String>> mapSellerListToCampaigns; // mappinng 1 sellerList to set of Campaigns
    private Set<String> setNewSellerList; //Seller list (campaign Targeting) that created after Button Refresh Member
    
    private Set<String> setSellerContactsCreatedTracker = new Set<String>(); //1 campaign member per campaign per seller
    
    private Boolean isGCXUser = EBH_CampaignTriggerHandler.checkGCXSuperUser();
 	private Boolean isMarketingUser = UserInfo.getProfileId().equals(EBH_ConstantsUtility.PROFILE_ID_MARKETING);
 	
 	private Map<Id,Campaign> mapCampaign; // Campaign store for update scope	
 	
 	private Set<String> countTargettedSeller = new Set<String>();
	private Integer countCreatedMember = 0;
	private Set<String> countSellerOptout = new Set<String>();
	private Set<String> countSellerOtherReason = new Set<String>();
	private Set<String> setBadSellers = new Set<String>();
	private Set<String> setAllCampSeller = new Set<String>();
	private Integer countSellerList = 0;// number of seller List

	// 20.05.2022 / Sophal Noch / US-0011717 : using "order by id desc" to make sure latest target seller is on top of the list
	private static final String CTH_TARGETEDSELLERQUERY = 'SELECT Id,Priority__c,Campaign_Related_Seller_Details__c, EBH_Seller__c, EBH_SellerList__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c WHERE EBH_SellerList__c in: sellerMapId Order By Id desc';

    /*****************************************************************************************************************************
    @ Constructor:    EBH_InsertCampaignMemberBatch
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        Initialises the class for controller instance.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accounts, campaigns, sellerListTargetedSellers, sellerIdCampaigns
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the constructor.
    *****************************************************************************************************************************/
    global EBH_InsertCampaignMemberBatch (Set<Id> accounts, Set<Id> campaigns, 
                                    Map<Id,List<EBH_TargetedSeller__c>> sellerListTargetedSellers, 
                                    Map<Id, Campaign> sellerIdCampaigns){
        accountIds = accounts;
        campaignIds = campaigns;
        sellerListTargetedSellerMap = sellerListTargetedSellers;
        sellerIdCampaignMap = sellerIdCampaigns;
        this.toUpdate = false;
        
        initMapCampaignSellerList();
    }
    
    global EBH_InsertCampaignMemberBatch(Set<Id> campaigns)
    {
    	campaignIds = campaigns;
    	this.toUpdate = true;
    	
    	initMapCampaignSellerList();
    }
    private void initMapCampaignSellerList()
    {
    	mapCampaignSellerLists = new Map<String,Set<String>>();
    	mapSellerListToCampaigns = new Map<String,Set<String>>(); 
    	setNewSellerList  = new Set<String>();

    	// for(Campaign_Targeting__c ct : Database.query(EBH_ConstantsUtility.SOQL_CAMP_TARGET_SELLERLIST + ' Where Campaign__c IN: campaignIds'))
		// 20.05.2022 / Sophal Noch / US-0011717 : make sure latest campaign targeting run in loop first
		for(Campaign_Targeting__c ct : Database.query(EBH_ConstantsUtility.SOQL_CAMP_TARGET_SELLERLIST + ' Where Campaign__c IN: campaignIds Order By Id desc'))
        {
        	if(!mapCampaignSellerLists.containsKey(ct.Campaign__c))
        	{
        		mapCampaignSellerLists.put(ct.Campaign__c,new Set<String>());
        	}
        	mapCampaignSellerLists.get(ct.Campaign__c).add(ct.Seller_List__c);
        	
        	if(!mapSellerListToCampaigns.containsKey(ct.Seller_List__c))
        	{
        		mapSellerListToCampaigns.put(ct.Seller_List__c,new Set<String>());
        	}
        	mapSellerListToCampaigns.get(ct.Seller_List__c).add(ct.Campaign__c);
        	
        	//store SellerList(newer) that created after button refresh
        	if(ct.CreatedDate > ct.Campaign__r.EBH_MemberLastRefreshDate__c)
        	{
        		setNewSellerList.add(ct.Seller_List__c);
        	}
        	
        	countSellerList +=1; 
        }
        System.debug('>>>campaignIds: '+campaignIds);
        mapCampaign = new Map<Id,Campaign>((List<Campaign>)Database.query(EBH_ConstantsUtility.CTH_CAMPAIGNQUERY));
        System.debug('>>>mapCampaignSellerLists: '+mapCampaignSellerLists);
    }
    /*****************************************************************************************************************************
    @ Method:         start
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator start method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    @				: 13.05.2019 / Vadhanka Von / EPH-7356 Exclude "Do not contact" and "incorrect phone number" contacts from the outreach
    *****************************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
    	
       String recDWH = ApexUtil.getRecordTypeByName('Contact','EBH_DWH').Id;//NK:06/02/2019: just more filter. because only primary or dhw will be created as member
       String soqlWhereForContact = ' AND ( Primary_Contact__c=true OR RecordtypeId=:recDWH ) AND EBH_DoNotContact__c=false AND Incorrect_Phone_Number__c=false'; //NK: EPH-7356:13/05/2019
       String soqlBatch = toUpdate?SOQL_CAM_MEMBER+' Where CampaignId IN:campaignIds':EBH_ConstantsUtility.ATH_ACCOUNTCONTACTQUERY+soqlWhereForContact;
        
        //run the query and pass the records to excute method in 200 scope
        return Database.getQueryLocator(soqlBatch);
    
    }
    
    /*****************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator execute method
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global void execute(Database.BatchableContext pBc, List<SObject> scope){
         //system.debug('>>>scope: '+scope);
             if(!toUpdate)
             {
             	doCreate(scope);
             }else
             {
             	//update existing members
             	try
             	{
             		doUpdateExistingMembers(scope);
             	} catch(Exception ex) {
					System.debug(ex);EBH_ApexLogger.logError(new List<Exception> { ex }, 'EBH_InsertCampaignMemberBatch', 'doUpdateExistingMembers');
				}
             	
             	
             }   
    }
    
    /*****************************************************************************************************************************
    @ Method:       doUpdateExistingMembers
    @ Version:      1.0
    @ Author:       Vadhanak Voun
    @ Purpose:      EPH-6825 Add /Delete Multiple Seller Lists to Outreach
    @				AC4: Given that I am any User
    @				When I go to Outreach record and channel = AM Outreach
	@				When I press on Refresh Members button.
	@				Given that Campaign members > 0
	@				Then:
	@					1. Update all Campaign Members with existing response code < 20 or empty to response code = 22
	@					2. Compare new Seller List with existing campaign members. If sellerlist.businessname exists in campmember.contact.account -> if
	@						campmember.response code = 22, then set it to 10; else skip
	@					3. Upload Campaign Members from new Target List, set Response code to 10
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.12.2018 / Vadhanak Voun  / Created the  Method.
    @				: 13.05.2019 / Vadhanka Von / EPH-7356 Exclude "Do not contact" and "incorrect phone number" contacts from the outreach
    @				: 02/01/2020/ Vadhanka Von / US-0006483 Hypercare Bug - Create Tasks for Refreshed Members - Original tasks remain open
    @					1) Update all Campaign Members with existing response code < 20 or 40 or empty to response code = 22
	@					2)Compare Seller List with existing campaign members. If sellerlist.businessname exists in campmember.contact.account -> if campmember.response code = 22 and task has more than 0 call attempts, then set it to 40, if campmember.response code =22 and tasks has 0 call attempts, then set it to 10, else skip
	@					3) Upload Campaign Members from new Target List, set Response code to 10
	@				: 08/03/2022/ vadhanak voun/ US-0008153 - Outreach tasks Trigger Deletion if Campaign Members response code 10 or 40
    *****************************************************************************************************************************/
    private void doUpdateExistingMembers(List<CampaignMember> listMembers)
    {
	    	Map<String,Set<String>> mapSellerToSetCampaigns =   new Map<String,Set<String>>(); 
	    	
	    	Set<String> setCurrentCampaigns = new Set<String>();
	    	Set<String> setCurrentSellerofCM = new Set<String>();
	    	for(CampaignMember cm: listMembers)
	    	{
	    		setCurrentCampaigns.add(cm.CampaignId); //current campaign for this scope
	    		setCurrentSellerofCM.add(cm.Contact.AccountId);
	    	}
	    	
	    	//all sellerLists connected to this Campaign (scope)
	    	Set<String> sellerMapId = new Set<String>();
	    	for(String camId : setCurrentCampaigns)
	    	{
	    		sellerMapId.addAll(mapCampaignSellerLists.get(camId));
	    	}

	    	//Map<String,Set<String>>  mapSellerListToSellers = new Map<String,Set<String>>(); //1 seller list for mulitple sellers 
			Map<String,Map<Id, EBH_TargetedSeller__c>> mapSellerListToTargSellers = new Map<String,Map<Id, EBH_TargetedSeller__c>>();  // 20.05.2022 / Sophal Noch / US-0011717
	    	
	    	Set<String> setSeller_for_NewSellerList = new Set<String>();
	        Map<String,EBH_TargetedSeller__c> mapTargetSeller = new Map<String,EBH_TargetedSeller__c>();
	        // for(EBH_TargetedSeller__c ts: Database.query(EBH_ConstantsUtility.CTH_TARGETEDSELLERQUERY))
			for(EBH_TargetedSeller__c ts: Database.query(CTH_TARGETEDSELLERQUERY))  // 20.05.2022 / Sophal Noch / US-0011717
	        {
	        	// mapTargetSeller.put(ts.EBH_Seller__c,ts);
				// 20.05.2022 / Sophal Noch / US-0011717 : so latest targetedSeller is not overwritten by the old one
				if(!mapTargetSeller.containsKey(ts.EBH_Seller__c))  mapTargetSeller.put(ts.EBH_Seller__c,ts);
	        	
	        	if(mapSellerListToCampaigns.containsKey(ts.EBH_SellerList__c))
	        	{
	        		if(!mapSellerToSetCampaigns.containsKey(ts.EBH_Seller__c))
	        		{
	        			mapSellerToSetCampaigns.put(ts.EBH_Seller__c,new Set<String>());
	        		}
	        		mapSellerToSetCampaigns.get(ts.EBH_Seller__c).addAll(mapSellerListToCampaigns.get(ts.EBH_SellerList__c)); //map campaigns to Seller
	        	}
	        	if(setNewSellerList.contains(ts.EBH_SellerList__c))
	        	{
	        		setSeller_for_NewSellerList.add(ts.EBH_Seller__c);
	        	}
	        	
	        	// if(!mapSellerListToSellers.containsKey(ts.EBH_SellerList__c))
	        	// {
	        	// 	mapSellerListToSellers.put(ts.EBH_SellerList__c,new Set<String>());
	        	// }
	        	// mapSellerListToSellers.get(ts.EBH_SellerList__c).add(ts.EBH_Seller__c);

				 // 20.05.2022 / Sophal Noch / US-0011717 store target seller instead of just seller id
				if(!mapSellerListToTargSellers.containsKey(ts.EBH_SellerList__c))
	        	{
	        		mapSellerListToTargSellers.put(ts.EBH_SellerList__c,new Map<Id,EBH_TargetedSeller__c>());
	        	}
	        	mapSellerListToTargSellers.get(ts.EBH_SellerList__c).put(ts.EBH_Seller__c,ts);

	        	//NK:15/03/2019: EPH-7023
	        	countTargettedSeller.add(ts.Id);
	        }
        
    		//NK:02/01/2020:US-0006483: 1) Update all Campaign Members with existing response code < 20 or 40 or empty to response code = 22
	    	Map<String,CampaignMember> mapCM_existing = new Map<String,CampaignMember>();
	    	Map<String,CampaignMember> mapCM_existingById = new Map<String,CampaignMember>();
	    	for(CampaignMember cm: listMembers)
	    	{				 
				// //NK:29/03/2022:US-0008153
	    		// if(cm.Marketing_Cloud_Status__c == CMRC_CANCELLED && (cm.EBH_ResponseCode__c ==null || (cm.EBH_ResponseCode__c <> null && (cm.EBH_ResponseCode__c <20 || cm.EBH_ResponseCode__c ==40))))
	    		// {
	    		// 	cm.EBH_ResponseCode__c = 22;
				// 	//NK:08/03/2022:US-0008153
				// 	//cm.Marketing_Cloud_Status__c = CMRC_CANCELLED;
				// 	cm.Status = CMRC_CANCELLED;
	    		// }

				// 09.06.2022 / Sophal Noch /US-0011923 :
				if(cm.EBH_ResponseCode__c ==null || (cm.EBH_ResponseCode__c <> null && (cm.EBH_ResponseCode__c <20 || cm.EBH_ResponseCode__c ==40)))
	    		{
	    			cm.EBH_ResponseCode__c = 22;
	    		}
	    		mapCM_existing.put(cm.ContactId,cm);
	    		mapCM_existingById.put(cm.Id,cm);
	    	}
	    	
	    	//get related tasks to check call attempt (normally 1 task per campaign per member)
	    	Map<String,List<Task>> mapCM_tasks = new Map<String,List<Task>>();
            Set<String> setCM_id = mapCM_existingById.keySet();
	    	//mapping list of tasks into CM
	    	for(Task t: Database.query(EBH_ConstantsUtility.SOQL_TASK+' Where EBH_CampaignMemberId__c IN :setCM_id '))
	    	{
	    		if(!mapCM_tasks.containsKey(t.EBH_CampaignMemberId__c))
	    		{
	    			mapCM_tasks.put(t.EBH_CampaignMemberId__c,new List<Task>());
	    		}
	    		mapCM_tasks.get(t.EBH_CampaignMemberId__c).add(t);
	    	}
	    	
	    	//NK:02/01/2020:US-0006483: 2)Compare Seller List with existing campaign members. If sellerlist.businessname exists in campmember.contact.account 
	    	//-> if campmember.response code = 22 and task has more than 0 call attempts, then set it to 40, 
	    	//-> if campmember.response code =22 and tasks has 0 call attempts, then set it to 10, else skip
	    	for(CampaignMember cm: mapCM_existing.values())
	    	{
				Set<Id> alreadyModifiedCampMemb = new Set<Id>(); // 20.05.2022 / Sophal Noch / US-0011717 : use in condiiton below, so campagin memeber field is not synced with old targeted seller

	    		Set<String> setSellerListId = mapCampaignSellerLists.get(cm.CampaignId);
	    		if(setSellerListId<>null)
	    		{
	    			for(String sellerListId: setSellerListId)
	    			{
	    				// Set<String> setSellers = mapSellerListToSellers.get(sellerListId);
						Map<Id,EBH_TargetedSeller__c> mapTargSeller = mapSellerListToTargSellers.get(sellerListId);  // 20.05.2022 / Sophal Noch / US-0011717

	    				// if(setSellers<>null && setSellers.contains(cm.Contact.AccountId))//seller still exists in targeted seller list
						if(!alreadyModifiedCampMemb.contains(cm.Id) && mapTargSeller<>null && mapTargSeller.containsKey(cm.Contact.AccountId))//seller still exists in targeted seller list,  // 20.05.2022 / Sophal Noch / US-0011717 
	    				{
							 // 20.05.2022 / Sophal Noch / US-0011717 update cm.Campaign_Related_Seller_Details__c with target seller Campaign_Related_Seller_Details__c
							EBH_TargetedSeller__c targSeller = mapTargSeller.get(cm.Contact.AccountId);
							cm.Campaign_Related_Seller_Details__c = targSeller.Campaign_Related_Seller_Details__c;

	    					if(cm.EBH_ResponseCode__c == 22)
				    		{
				    			List<Task> listTasks = mapCM_tasks.get(cm.Id);
					    		if(listTasks <> null && !listTasks.isEmpty())
					    		{
					    			for(Task t: listTasks) //1 task per campaign per member
					    			{
					    				if(t.Call_attempts__c <> null && t.Call_attempts__c > 0)
					    				{
					    					cm.EBH_ResponseCode__c = 40;
					    				}else if(t.Call_attempts__c == null || t.Call_attempts__c == 0)
					    				{
					    					cm.EBH_ResponseCode__c = 10;
					    				}
					    			}
					    			
					    		}else //no task, use old logic
					    		{
					    			cm.EBH_ResponseCode__c = 10;
					    		}
				    		}
							alreadyModifiedCampMemb.add(cm.ID);
	    				}
	    			}
	    		}
	    		//NK:EPH-6854:04/01/2019: not ONLY NEW seller lists, but all seller lists
	    		//if(setSeller_for_NewSellerList.contains(cm.Contact.AccountId) && cm.EBH_ResponseCode__c == 22)
	    		//if(setSeller_for_NewSellerList.contains(cm.Contact.AccountId) && cm.EBH_ResponseCode__c == 22)
	    		//{
	    		//	cm.EBH_ResponseCode__c = 10;
	    		//}
	    	}
	    	update mapCM_existing.values();
	    	
	    	//3. Upload Campaign Members from new Target List, set Response code to 10
	    	//support mass operation
	    	List<CampaignMember> listNewCM = new List<CampaignMember>();
	    	Set<String> setExistingContactMembers = new Set<String>();
	    	
	    	for(CampaignMember cm: Database.query(EBH_ConstantsUtility.SOQL_CAM_MEMBER+' Where CampaignId IN:setCurrentCampaigns'))
	    	{
	    		//setExistingContactMembers.add(cm.CampaignId+''+cm.ContactId);
	    		setExistingContactMembers.add(cm.CampaignId+''+cm.Contact.AccountId);
	    	}
	    	
	    	Map<String,Contact[]> mapSellerContacts = new Map<String,Contact[]>();
	    	
	    	Set<String> accountIds = mapTargetSeller.keySet();
	    	for(Contact con : Database.query(EBH_ConstantsUtility.ATH_ACCOUNTCONTACTQUERY +' AND EBH_DoNotContact__c=false AND Incorrect_Phone_Number__c=false')) //NK: EPH-7356:13/05/2019
	    	{
	    		if(!mapSellerContacts.containsKey(con.AccountId))
	    		{
	    			mapSellerContacts.put(con.AccountId,new List<Contact>());
	    		}
	    		mapSellerContacts.get(con.AccountId).add(con); 
	    	}
	    	
	    	for(String sellerId : mapSellerToSetCampaigns.keySet())
	    	{
	    		for(String camId : mapSellerToSetCampaigns.get(sellerId))
	    		{
	    			if(setExistingContactMembers.contains(camId+''+sellerId))continue; //seller and already for this camp(1 cm 1 seller per camp)
	    			
	    			setAllCampSeller.add(camId+'_'+sellerId); //NK:15/03/2019: EPH-7023

					// 20.05.2022 / Sophal Noch / US-0011717 :
					EBH_TargetedSeller__c targSeller; // is used to store the latest targeted seller
					Set<String> setSellerList = mapCampaignSellerLists.get(camId); 
					if(setSellerList != null){
						for(String sellerListId : setSellerList){
							Map<Id, EBH_TargetedSeller__c> mapSellerIdToTargSeller = mapSellerListToTargSellers.get(sellerListId);
							targSeller = mapSellerIdToTargSeller != null ? mapSellerIdToTargSeller.get(sellerId) : null;
							if(targSeller != null) break; // if it is not null = found the latest targeted seller. break the loop to avoid overwrite the latest targeted seller with old one.
						}
					}
	    			
	    			List<Contact> listContacts = mapSellerContacts.get(sellerId);
	    			if(listContacts <> null)
	    			{
		    			for(Contact con: listContacts)
			    		{
			    			if(doNotCreateMember(mapCampaign.get(camId),con))
			    			{
			    				countSellerOptout.add(camId+'_'+sellerId); //NK:15/03/2019: EPH-7023
			    				continue;
			    			}
			    			if(con.Primary_Contact__c)
			    			{

			    				//new CampaignMember
				                // listNewCM.add(new CampaignMember( 
					            //      CampaignId = camId, 
					            //      ContactId = con.Id,
					            //      EBH_ResponseCode__c = EBH_ConstantsUtility.TCC_TEN,
					            //      EBH_Seller__c = con.AccountId
				                // ));

								// 20.05.2022 / Sophal Noch / US-0011717 :
								CampaignMember newCm = new CampaignMember( 
									     CampaignId = camId, 
									     ContactId = con.Id,
									     EBH_ResponseCode__c = EBH_ConstantsUtility.TCC_TEN,
									     EBH_Seller__c = con.AccountId
								);
								if(targSeller != null) newCm.Campaign_Related_Seller_Details__c = targSeller.Campaign_Related_Seller_Details__c;
								listNewCM.add(newCm);
								
				                setExistingContactMembers.add(camId+''+con.AccountId);
				                setSellerContactsCreatedTracker.add(camId+'_'+con.AccountId);
			    				break;
			    			}
			    		}
	    			}
		    		if(!setExistingContactMembers.contains(camId+''+sellerId) && (listContacts<> null && !listContacts.isEmpty()))
		    		{
		    			//find dwh contact
		    			for(Contact con: listContacts)
			    		{
			    			if(doNotCreateMember(mapCampaign.get(camId),con))
			    			{
			    				countSellerOptout.add(camId+'_'+sellerId); //NK:15/03/2019: EPH-7023
			    				continue;
			    			}
			    			
							if(con.recordTypeId == ApexUtil.getRecordTypeByName('Contact','EBH_DWH').Id)
							{
								// listNewCM.add(new CampaignMember( 
					            //      CampaignId = camId, 
					            //      ContactId = con.Id,
					            //      EBH_ResponseCode__c = EBH_ConstantsUtility.TCC_TEN,
					            //      EBH_Seller__c = con.AccountId
				                // ));
								
								// 20.05.2022 / Sophal Noch / US-0011717 :
								CampaignMember newCm = new CampaignMember( 
									     CampaignId = camId, 
									     ContactId = con.Id,
									     EBH_ResponseCode__c = EBH_ConstantsUtility.TCC_TEN,
									     EBH_Seller__c = con.AccountId
								);
								if(targSeller != null) newCm.Campaign_Related_Seller_Details__c = targSeller.Campaign_Related_Seller_Details__c;
								listNewCM.add(newCm);

				                setExistingContactMembers.add(camId+''+con.AccountId);
				                setSellerContactsCreatedTracker.add(camId+'_'+con.AccountId);
			    				break;
							}
			    		}
		    		}
	    		}
	    	}
	    	
	    	if(!listNewCM.isEmpty())
	    	{
	    		insert listNewCM; 
	    		
	    		//NK:15/03/2019: EPH-7023
	    		countCreatedMember+= listNewCM.size();
	    	}	
    }
    /*****************************************************************************************************************************
    @ Method:       doCreate
    @ Version:      1.0
    @ Author:       Vadhanak Voun
    @ Purpose:      EPH-6825 Add /Delete Multiple Seller Lists to Outreach
    @				AC4: Given that I am any User
    @				When I go to Outreach record and channel = AM Outreach
	@				When I press on Refresh Members button.
	@				Given that Campaign members > 0
	@				Then:
	@					1. Update all Campaign Members with existing response code < 20 or empty to response code = 22
	@					2. Compare new Seller List with existing campaign members. If sellerlist.businessname exists in campmember.contact.account -> if
	@						campmember.response code = 22, then set it to 10; else skip
	@					3. Upload Campaign Members from new Target List, set Response code to 10
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.12.2018 / Vadhanak Voun  / Created the  Method.
    @				: 06.02.2019/ Vadhanak Voun  / EPH-6988 Admin Outreach Campaign
    @						AC2:
	@						Given that I am GCX Super User or Marketing User
	@						When I attach Seller List to the record type: "Outreach" and Refresh Campaign Members
	@						Given that Outreach.Type=Marketing
	@						Then create Campaign Members (one campaign member per seller) only for sellers without phone-opt out:
	@						Do not create campaign members, where Contact.Phone Opt-out =True
    *****************************************************************************************************************************/
    private void doCreate(List<Contact> scope)
    {
    	//Map<Id, Account> accountMap = new Map<Id, Account>();    //account map
        Map<Id, List<Contact>> accountConMap = new Map<Id, List<Contact>>();    //account map
        
        Map<String,CampaignMember> campaignMemberMap = new Map<String,CampaignMember>();    //list of CampaignMember to insert
        Map<Id,List<Contact>> sellerListContactMap = new Map<Id,List<Contact>>();    
        List<Contact> relatedRecords = new list<Contact>();
        
        //fetch all the account and related contacts
        for(Contact con : scope) {
            relatedRecords = accountConMap.containsKey( con.accountID) ? 
                                        accountConMap.get( con.accountId) : new List<Contact>();
            relatedRecords.add( con);
            accountConMap.put(con.accountId, relatedRecords);
        }
        
        // Map<String,Set<String>>  mapSellerListToSellers = new Map<String,Set<String>>(); //1 seller list for mulitple sellers 
		Map<String,Map<Id, EBH_TargetedSeller__c>> mapSellerListToTargSellers = new Map<String,Map<Id, EBH_TargetedSeller__c>>(); //1 seller list for mulitple sellers , // 20.05.2022 / Sophal Noch / US-0011717
        //to get all contacts in sellerListContactMap
        List<Contact> conList = new List<Contact>();          
        for(List<EBH_TargetedSeller__c> targetedSellerListIterate : sellerListTargetedSellerMap.values()){
            for(EBH_TargetedSeller__c targetedSellerRecord : targetedSellerListIterate){
                
                //targetedSellerMap.put(targetedSellerRecord.EBH_Seller__c, targetedSellerRecord.ID);
                
                //if( targetedSellerRecord.EBH_ExitCode__c == '10'){
                    if(sellerListContactMap.containsKey(targetedSellerRecord.EBH_SellerList__c)){
                        if( accountConMap.containsKey( targetedSellerRecord.EBH_Seller__c))        
                        conList.addAll(accountConMap.get(targetedSellerRecord.EBH_Seller__c));
                    } 
                    else {
                        conList = new List<Contact>();  
                        if( accountConMap.containsKey( targetedSellerRecord.EBH_Seller__c))        
                        conList.addAll(accountConMap.get(targetedSellerRecord.EBH_Seller__c));
                    }
                    sellerListContactMap.put(targetedSellerRecord.EBH_SellerList__c, conList);
                //}
                
                 
	        	// if(!mapSellerListToSellers.containsKey(targetedSellerRecord.EBH_SellerList__c))
	        	// {
	        	// 	mapSellerListToSellers.put(targetedSellerRecord.EBH_SellerList__c,new Set<String>());
	        	// }
	        	// mapSellerListToSellers.get(targetedSellerRecord.EBH_SellerList__c).add(targetedSellerRecord.EBH_Seller__c);
	        	
				// 20.05.2022 / Sophal Noch / US-0011717 :
				if(!mapSellerListToTargSellers.containsKey(targetedSellerRecord.EBH_SellerList__c))
				{
					mapSellerListToTargSellers.put(targetedSellerRecord.EBH_SellerList__c,new Map<Id,EBH_TargetedSeller__c>());
				}
				mapSellerListToTargSellers.get(targetedSellerRecord.EBH_SellerList__c).put(targetedSellerRecord.EBH_Seller__c,targetedSellerRecord);

	        	//NK:15/03/2019: EPH-7023
	        	countTargettedSeller.add(targetedSellerRecord.Id);
            }
        }
 
        //to iterate through campaigns
        for(Campaign campaignRecord : sellerIdCampaignMap.values()){
            //proceed if sellerListContactMap and campaign has the same sellerlist 
            Set<String> setSellerLists = mapCampaignSellerLists.get(campaignRecord.Id);
            for(String sellerListId: setSellerLists)
            {
            	// Set<String> setSellers = mapSellerListToSellers.get(sellerListId);
				Map<Id,EBH_TargetedSeller__c> mapTargSeller = mapSellerListToTargSellers.get(sellerListId); // 20.05.2022 / Sophal Noch / US-0011717

            	// if(setSellers <> null)
				if(mapTargSeller <> null)
            	{
            		// for(String sellerId : setSellers)
					for(String sellerId : mapTargSeller.keySet()) // 20.05.2022 / Sophal Noch / US-0011717
	            	{
	            		if(setSellerContactsCreatedTracker.contains(campaignRecord.Id+'_'+sellerId))continue; //1 cm per seller per campaign. traking the whole batch
	            		
	            		setAllCampSeller.add(campaignRecord.Id+'_'+sellerId); //NK:15/03/2019: EPH-7023
	            		
	            		 List<Contact> listContacts = accountConMap.get(sellerId);
	            		 //system.debug('>>>0listContacts: '+listContacts);
	            		 if(listContacts <> null)
	            		 {

							EBH_TargetedSeller__c targSeller = mapTargSeller.get(sellerId);
	            		 	//1, loop for primary
	            		 	for(Contact con : listContacts)
		            		{	 
		            			//system.debug('>>>0con: '+con);
		            			//NK:06/02/2019: EPH-6988: Outreach.Type=Marketing Do not create campaign members, where Contact.Phone Opt-out =True
		            			if(doNotCreateMember(campaignRecord,con))
		            			{
		            				countSellerOptout.add(campaignRecord.Id+'_'+sellerId); //NK:15/03/2019: EPH-7023
		            				continue;
		            			} 
		            		 	//system.debug('>>>0con: yes'); 
		            		 	if(con.Primary_Contact__c)
			    				{
			    					CampaignMember cm = new CampaignMember(
					                    	CampaignId = campaignRecord.Id,
					                    	ContactId = con.Id,
					                    	EBH_ResponseCode__c = EBH_ConstantsUtility.TCC_TEN,
					                    	EBH_Seller__c = sellerId,
											Campaign_Related_Seller_Details__c = targSeller.Campaign_Related_Seller_Details__c // 20.05.2022 / Sophal Noch / US-0011717
					                    );
					                    campaignMemberMap.put(campaignRecord.Id+''+sellerId,cm);  
					                    setSellerContactsCreatedTracker.add(campaignRecord.Id+'_'+sellerId);
					                    break;  
			    				}
		            		}
		            		//no primary found, find DWH contact
		            		if(!campaignMemberMap.containsKey(campaignRecord.Id+''+sellerId) && !listContacts.isEmpty())
		            		{
		            			for(Contact con : listContacts)
			            		{	
			            			//system.debug('>>>1con: '+con); 
			            			//NK:06/02/2019: EPH-6988: Outreach.Type=Marketing Do not create campaign members, where Contact.Phone Opt-out =True
		            				if(doNotCreateMember(campaignRecord,con))
		            				{
		            					countSellerOptout.add(campaignRecord.Id+'_'+sellerId); //NK:15/03/2019: EPH-7023
		            					continue;
		            				}
		            				//system.debug('>>>1con yes: '); 
			            			if(con.recordTypeId == ApexUtil.getRecordTypeByName('Contact','EBH_DWH').Id)
			            			{
			            				CampaignMember cm = new CampaignMember(
					                    	CampaignId = campaignRecord.Id,
					                    	ContactId = con.Id,
					                    	EBH_ResponseCode__c = EBH_ConstantsUtility.TCC_TEN,
					                    	EBH_Seller__c = sellerId,
											Campaign_Related_Seller_Details__c = targSeller.Campaign_Related_Seller_Details__c // 20.05.2022 / Sophal Noch / US-0011717
					                    ); 
					                    campaignMemberMap.put(campaignRecord.Id+''+sellerId,cm);  
					                    setSellerContactsCreatedTracker.add(campaignRecord.Id+'_'+sellerId);
					                    break;  
			            			}
			            		}
		            		}
	            		 }
	            	}
            	}
            }
        }
        //proceed if map is not empty
        if(!campaignMemberMap.values().isEmpty()){
        	Integer oldNum = countCreatedMember;
            try {
                //insert the campaign members
                Database.insert(campaignMemberMap.values());
                
                //NK:15/03/2019: EPH-7023
	    		countCreatedMember+= campaignMemberMap.size();
                
            } catch(Exception ex) {
            	countCreatedMember = oldNum; //restore number in case error
                System.debug(ex);EBH_ApexLogger.logError(new List<Exception> { ex },EBH_ConstantsUtility.ICMBATCH_CLASS, EBH_ConstantsUtility.ICMBATCH_EMETHOD);
            }   
        }
    }
    
    //NK:06/02/2019: EPH-6988: Outreach.Type=Marketing Do not create campaign members, where Contact.Phone Opt-out =True
    private boolean doNotCreateMember(Campaign camp, Contact con)
    {
		return (isGCXUser || isMarketingUser) 
		&& EBH_ConstantsUtility.OUTREACH_TYPE_MARKETING.equals(camp.Campaign_Type__c) 
		&& EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID.equals(camp.RecordTypeId) 
		&& con.EBH_PhoneOptOut__c ;
    }
    /*****************************************************************************************************************************
    @ Method:         finish
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL (asbaranwal@deloitte.co.uk)
    @ Purpose:        QueryLocator finish method, it sends an email notification to the seller list owner once the insert batch
                      is complete.  
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.07.2017 / ASHISH BARANWAL (asbaranwal@deloitte.co.uk) / Created the method.
    *****************************************************************************************************************************/
    global void finish(Database.BatchableContext pBc){
    	
    	//save refresh timestamp; so we can comare the new sellerlist
    	List<Campaign> listCampToUpdate = new List<Campaign>();
    	for(Campaign c: Database.query(EBH_ConstantsUtility.CTH_CAMPPRIORITYACRQUERY))
    	{
    		c.EBH_MemberLastRefreshDate__c = System.now();
    		listCampToUpdate.add(c); 
    	}
    	try
    	 {
           update listCampToUpdate;
           
        } catch(Exception ex) {
            System.debug(ex);EBH_ApexLogger.logError(new List<Exception> { ex },EBH_ConstantsUtility.ICMBATCH_CLASS, 'finish');
        }   
        String campaignName = listCampToUpdate.size()==1?listCampToUpdate[0].Name: listCampToUpdate.size()+' Campaign(s)'; 
        //NK:15/03/2019: EPH-7023
        sendEmailResult(campaignName);
         

    }
    //
    /*****************************************************************************************************************************
    @ Method:         sendEmailResult
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaga-sys.com)
    @ Purpose:        [#EPH-7023] Notification_ # sellers were not transfered to campaign members [Error] 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.03.2019 / Vadhanak Voun (vadhanak.voun@gaga-sys.com)/ Created the method.
	@				: 19.03.2025 / Sambath Seng / US-0016682 - [Dev Only] Apex Class Classification to upgrade API version 3/5
    *****************************************************************************************************************************/
    private void sendEmailResult(String campaignName)
    {
    	Integer numCountTargettedSeller = countTargettedSeller.size();
    	Integer numSellerOptOut = 0;
    	Integer numSellerErrorOther = 0;
    	Set<String> setSellerOtherReasonId = new Set<String>();
    	//all sellers by campaigns that have been involved into this batch
    	for(String camp_sellerId : setAllCampSeller)
    	{
    		//could be 1 contact (of seller) opt-out but other ok and created as member
    		//-> opt-out and no creation
    		if(countSellerOptout.contains(camp_sellerId) && !setSellerContactsCreatedTracker.contains(camp_sellerId))
    		{
    			numSellerOptOut += 1;
    		}
    		
    		//no creation and not opt-out; there must be other reason
    		if(!setSellerContactsCreatedTracker.contains(camp_sellerId) && !countSellerOptout.contains(camp_sellerId))
    		{
    			numSellerErrorOther +=1;
    			setSellerOtherReasonId.add(camp_sellerId.split('_')[1]);//campId_sellerId
    		}
    	}
    	
    	
    	EmailTemplate emailTmp = [select Id, Subject, HtmlValue, DeveloperName  from EmailTemplate where DeveloperName = 'RefreshMemberInfo'];
    	 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {UserInfo.getUserEmail()};
        
        String htmlBody = emailTmp.HtmlValue;
        
        String allSellerOther = '';
        if(!setSellerOtherReasonId.isEmpty())
        {
        	String serverUrl =  URL.getOrgDomainUrl().toExternalForm(); //19.03.2025 Sambath Seng US-0016682 Replace getSalesforceBaseUrl
        	Set<String> setAccountIds = setSellerOtherReasonId;
        	for(Account seller : Database.query(EBH_ConstantsUtility.SOQL_ACCOUNT)){
	           allSellerOther+= '<p><a href="'+serverUrl+'/lightning/r/Account/'+seller.Id+'/view'+'">'+seller.Name+'</a></p>';
	       	}
        }
       
     	String emailBody = htmlBody.replace('{!BadSellers}',allSellerOther)
     		.replace('{!CountTargetSeller}',numCountTargettedSeller+'')
     		.replace('{!CountCMCreated}',countCreatedMember+'')
     		.replace('{!CountSellerOptOut}',numSellerOptOut+'')
     		.replace('{!BadSellerOther}',numSellerErrorOther+'') 
     		.replace('{!CountSellerList}', countSellerList+'')
			.replace('{!CampaignName}', campaignName);
		String subject = emailTmp.Subject.replace('{!CampaignName}',campaignName);
		
		
      	ApexUtil.doSend(subject,UserInfo.getUserEmail(),emailBody); 
      
    }
}