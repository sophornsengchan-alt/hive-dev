/*********************************************************************************************************************************
@ Class:          EBH_IndividualResultTriggerHandler
@ Version:        1.0
@ Author:         Neha Lund
@ Purpose:        Handler Class for Account Trigger
                  EPH-5 : Customer Management
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.05.2018 / NEHA LUND/ Created the class.
*********************************************************************************************************************************/

public with sharing class EBH_IndividualResultTriggerHandler {
    
     /*****************************************************************************************************************************
    @ Method:         updateEmailPhoneContacts
    @ Version:        1.0
    @ Author:         Neha Lund: EPH-5945
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accounts:      accounts from the trigger scope
                      accountOldMap: accounts old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2018 /NEHA LUND / Created the  Method.
    @				: 21.02.2019/Vadhanak Voun/ change List<Contact> to map to fix: System.ListException: Duplicate id in list
    *****************************************************************************************************************************/
    public static void updateEmailPhoneContacts(List<et4ae5__IndividualEmailResult__c> results, 
                                        Map<Id, et4ae5__IndividualEmailResult__c> oldMap){
                  
           Map<String,Contact> mapContact = new Map<String,Contact>();
           Contact con;
                                 
           for(et4ae5__IndividualEmailResult__c res: results){
               
               con = new Contact(ID = res.et4ae5__Contact__c);
               
               if( oldMap == null || res.et4ae5__HardBounce__c != oldMap.get(res.Id).et4ae5__HardBounce__c ){
                   
                   con.Email_Bounced__c = res.et4ae5__HardBounce__c;
                   
               		mapContact.put(res.et4ae5__Contact__c+'',con);
               }
               
           }
           
           if( !mapContact.isEmpty()){
               try {
             		update mapContact.values();
				} catch(Exception ex) {
					EBH_ApexLogger.logError(new List<Exception> { ex }, 'EBH_IndividualResultTriggerHandler','updateEmailPhoneContacts');
				} 
               
           }
           
    
    }
    
    /*****************************************************************************************************************************
    @ Method:         trackCampaignMembers
    @ Version:        1.0
    @ Author:         
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accounts:      accounts from the trigger scope
                      accountOldMap: accounts old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2018 /NEHA LUND / Created the  Method.
	@				  27/09/2018/ Vadhanak Voun	/ EPH-6485 Synchronise campaign feedback from SFMC to SFDC
    @											The Response Code is updated where the below match:
	@											Campaign Record Type = Sub-Campaign
	@											IER. Triggered Send Name = Campaign Member. Parent Campaign. Triggered Send Name
	@											IER. Contact = Campaign Member . Contact
    @				03/10/2018/ Vadhanak Voun/	Get CampaignMember Ids
    @				29/10/2018/ Vadhanak Voun/ EPH-6568 Response Date and Aggregation for Campaign Feedback
    @											"First Response Date" = upon create/edit, if the "First Response Date" is blank, the earliest of "Date Bounce" or "Date Opened" if populated.
	@											 "Last Response Date" = upon create/edit, the latest of "Date Bounce", "Date Opened", "Date Unsubscribed" if populated.
	@				11/11/2020/ vadhanak voun/ US-0008647 - [Hypercare] - GCX Campaigns - Sub campaign tasks are not auto assigned via trigger
	@										 / change from list map avoid duplicate error
    *****************************************************************************************************************************/
    public static void trackCampaignMembers(List<et4ae5__IndividualEmailResult__c> results, 
                                        Map<Id, et4ae5__IndividualEmailResult__c> oldMap){
            			
			Map<String,CampaignMember> mapCMToUpdate = new Map<String,CampaignMember>();
			//----
			Map<String,CampaignMember> mapCM = getRefMapCampMember(results);
			//----
            for(et4ae5__IndividualEmailResult__c res: results){
					CampaignMember member = 	mapCM.get(res.et4ae5__Contact__c+''+res.et4ae5__TriggeredSendDefinition__c);
					//system.debug('>>>>>Member: '+member);
					
					if(member <> null)res.et4ae5__CampaignMemberId__c = member.Id; //because it is 'before' trigger, assign the member id to it.
					
                    if(member <> null && calculateTracking(res,oldMap)){
                    
                        //CampaignMember member = new CampaignMember(Id = res.et4ae5__CampaignMemberId__c);
                        member.et4ae5__Activity__c = res.et4ae5__DateUnsubscribed__c != null ? 'Unsubscribed' :

                        res.et4ae5__HardBounce__c ? 'Hard Bounce' :  res.et4ae5__SoftBounce__c ? 'Soft Bounce' : res.et4ae5__Clicked__c ? 'Clicked' : res.et4ae5__Opened__c ? 'Opened' : 'Sent';
                        
                        //NK: 27/09/2018: EPH-6485
                        if(isOk(member,res))
                        {
                        	member.EBH_ResponseCode__c =
	                        res.et4ae5__DateUnsubscribed__c != null ? 80 : res.et4ae5__NumberOfUniqueClicks__c > 0 ? 90: res.et4ae5__Opened__c ? 60: res.et4ae5__SoftBounce__c ? 40: res.et4ae5__HardBounce__c ? 30:
	                        res.et4ae5__DateSent__c != null && ( !res.et4ae5__HardBounce__c || !res.et4ae5__SoftBounce__c) ? 50 : 10;	                        
	                        //29/10/2018:NK: EPH-6568
	                        populateFirstLastResponseDate(member,res);
	                        
                        }                        

						mapCMToUpdate.put(member.Id,member);
                    }

			}

			if(!mapCMToUpdate.isEmpty())
			{
				IR_DMLWorker updateWorker = new IR_DMLWorker(mapCMToUpdate.values(),'trackCampaignMembers',trackCampaignMembersRetry_counter);
				updateWorker.doUpdate();
	   	 		 
			}
    }
    
    private static Map<String,CampaignMember> mapRefCM;
    //NK:12/02/2019: moved into here for sharing with other method without re-query
    private static Map<String,CampaignMember> getRefMapCampMember(List<et4ae5__IndividualEmailResult__c> results)
    {
    	if(mapRefCM==null)
    	{
    		Set<String> setContact_ids = new Set<String>();
			Set<String> setTriggerSend_ids = new Set<String>();
			
			//get campaignMemberId
			for(et4ae5__IndividualEmailResult__c res: results){
				if(res.et4ae5__Contact__c <> null)setContact_ids.add(res.et4ae5__Contact__c);
				if(res.et4ae5__TriggeredSendDefinition__c <> null)setTriggerSend_ids.add(res.et4ae5__TriggeredSendDefinition__c);
			}
			String soqlWhere = ' Where ContactId IN:setContact_ids AND Campaign.Triggered_Send_Name__c IN:setTriggerSend_ids';
			mapRefCM = new Map<String,CampaignMember>();
			for(CampaignMember cm: Database.query(EBH_ConstantsUtility.SOQL_CAM_MEMBER+soqlWhere))
			{
				mapRefCM.put(cm.ContactId+''+cm.Campaign.Triggered_Send_Name__c,cm);
			}
    	}
    	return mapRefCM;
    }
    
    public static Integer trackCampaignMembersRetry_counter = 0;
        
    /*****************************************************************************************************************************
    @ Method:       populateFirstLastResponseDate
    @ Version:      1.0
    @ Author:       Vadhanak Voun
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    CampaignMember:       
    @				et4ae5__IndividualEmailResult__c
    ------------------------------------------------------------------------------------------------------------------------------
    @				29/10/2018/ Vadhanak Voun/ EPH-6568 Response Date and Aggregation for Campaign Feedback
	@				"First Response Date" = upon create/edit, if the "First Response Date" is blank, the earliest of "Date Bounce" or "Date Opened" if populated.
	@				"Last Response Date" = upon create/edit, the latest of "Date Bounce", "Date Opened", "Date Unsubscribed" if populated.
    ******************************************************************************************************************************/
    private static void populateFirstLastResponseDate(CampaignMember member, et4ae5__IndividualEmailResult__c ier)
    {
    	List<DateTime> listToSort = new List<DateTime>();
    	if(ier.et4ae5__DateBounced__c <> null)
    	{
    		listToSort.add(ier.et4ae5__DateBounced__c);
    	}
    	if(ier.et4ae5__DateOpened__c <> null)
    	{
    		listToSort.add(ier.et4ae5__DateOpened__c);
    	}
    	//first res date
    	if(member.EBH_FirstResponseDate__c == null)
    	{
    		listToSort.sort(); 
    		 
    		member.EBH_FirstResponseDate__c =  listToSort.isEmpty()?null:listToSort[0].date();
    	}
    	//last res date
    	if(ier.et4ae5__DateUnsubscribed__c <> null)
    	{
    		listToSort.add(ier.et4ae5__DateUnsubscribed__c);
    	}
    	listToSort.sort();
       
        member.EBH_LastResponseDate__c = listToSort.isEmpty()?null:listToSort[listToSort.size()-1].date();
        
    }
    
	/*****************************************************************************************************************************
    @ Method:         isOk
    @ Version:        1.0
    @ Author:          Vadhanak Voun
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      CampaignMember:       
    @				  et4ae5__IndividualEmailResult__c
    ------------------------------------------------------------------------------------------------------------------------------
    @				  27/09/2018/ Vadhanak Voun	/ EPH-6485 Synchronise campaign feedback from SFMC to SFDC
    @											The Response Code is updated where the below match:
	@											Campaign Record Type = Sub-Campaign
	@											IER. Triggered Send Name = Campaign Member. Parent Campaign. Triggered Send Name
	@											IER. Contact = Campaign Member . Contact
    *****************************************************************************************************************************/  
    private static boolean isOk(CampaignMember cm, et4ae5__IndividualEmailResult__c ier)
    {
    	if(EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE==cm.Campaign.RecordType.DeveloperName
    		&& ier.et4ae5__TriggeredSendDefinition__c == cm.Campaign.Triggered_Send_Name__c
    		&& ier.et4ae5__Contact__c == cm.ContactId
    		)
    	{
    		
    		return true;
    	}
    	return false;	
    }
	
    /*****************************************************************************************************************************
    @ Method:         calculateTracking
    @ Version:        1.0
    @ Author:         
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accounts:      accounts from the trigger scope
                      accountOldMap: accounts old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2018 /NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static boolean calculateTracking( et4ae5__IndividualEmailResult__c emailRec, 
    Map<Id, et4ae5__IndividualEmailResult__c> emailOldMap){

        et4ae5__IndividualEmailResult__c oldres = emailOldMap != null ?  emailOldMap.get(emailRec.Id) : emailRec;

        return  ( emailRec.et4ae5__CampaignMemberId__c != null   &&   (emailOldMap == null ||  
        oldres.et4ae5__CampaignMemberId__c != emailRec.et4ae5__CampaignMemberId__c || 
        oldres.et4ae5__HardBounce__c != emailRec.et4ae5__HardBounce__c ||
        oldRes.et4ae5__Opened__c != emailRec.et4ae5__Opened__c ||
        oldRes.et4ae5__SoftBounce__c != emailRec.et4ae5__SoftBounce__c ||
        oldRes.et4ae5__HardBounce__c != emailRec.et4ae5__HardBounce__c ||
        oldRes.et4ae5__DateSent__c != emailRec.et4ae5__DateSent__c ||
        oldRes.et4ae5__DateUnsubscribed__c != emailRec.et4ae5__DateUnsubscribed__c ||
        oldRes.et4ae5__NumberOfUniqueClicks__c != emailRec.et4ae5__NumberOfUniqueClicks__c
         )  );           

    }

	class IR_DMLWorker extends DMLWorker{
    	
    	public IR_DMLWorker(List<SObject> listSobject,String methodName,Integer numRetry)
    	{
    		super(listSobject,'EBH_IndividualResultTriggerHandler',methodName);
    		retry_counter = numRetry;
    	}
    	
    	void setCounter()
		{
			retry_counter = retry_counter+1;
			EBH_IndividualResultTriggerHandler.trackCampaignMembersRetry_counter = retry_counter;
		}
		
   	 	void doRetry()
   	 	{
   	 		Id jobID = System.enqueueJob(new IR_DMLWorker(listSobject,methodName,retry_counter)); //retry
   	 	}  
    	
    }
    
    /*****************************************************************************************************************************
    @ Method:       populateTargetDate
    @ Version:      1.0
    @ Author:       Vadhanak Voun 
    @ Purpose:      EPH-7043 "Target Date" in campaign-members. Email & GCX
    @			AC2:
	@				Trigger
	@				Given that Sub-Campaign = Email
	@				Populate  "Target Date" with values from et4ae5__IndividualEmailResult__c.et4ae5__DateSent__c
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      listIERNew:                 : CampaignMember  
    @                 mapOld  : IndividualEmailResult old map from trigger scope to compare
    @ Trigger:		  before insert,before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11/02/2019 / Vadhanak Voun / Created the  Method.
	@				: 12/01/2021/ Vadhanak Voun / US-0008907 - [Dev Only] - Fix EBH_CampaignMemberTracking trigger
    *****************************************************************************************************************************/
    public static void populateTargetDate(List<et4ae5__IndividualEmailResult__c> listIERNew,Map<Id, et4ae5__IndividualEmailResult__c> mapOld)
    {
    	Boolean isInsert = (mapOld==null);
    	Map<Id,Campaign> mapCamp;
    	Set<String> campaignIdsToUpdate = new Set<String>();
    	//List<CampaignMember> listCMToUpdate = new List<CampaignMember>(); 
		Map<String,CampaignMember> mapCMToUpdate = new Map<String,CampaignMember>();
    	Map<String,CampaignMember> mapCM =  getRefMapCampMember(listIERNew);
    	if(isInsert)
    	{
    		for(et4ae5__IndividualEmailResult__c res: listIERNew)
			{
				 CampaignMember cm = mapCM.get(res.et4ae5__Contact__c+''+res.et4ae5__TriggeredSendDefinition__c);
				 if(cm<> null && cm.EBH_ResponseCode__c != null && cm.EBH_ResponseCode__c > 10 && cm.Campaign.RecordTypeId == EBH_ConstantsUtility.CAMP_RECORDTYPE_SUB_ID && cm.Campaign.EBH_Channel__c == EBH_ConstantsUtility.CAMPAIGN_CHANNEL_EMAIL && res.et4ae5__DateSent__c <> null)
				 {
				 	//AC2: Populate  "Target Date" with values from: et4ae5__IndividualEmailResult__c.et4ae5__DateSent__c
				 	cm.Target_Date__c= res.et4ae5__DateSent__c.dateGMT();//NK:23/01/2020: to GMT
				 	//listCMToUpdate.add(cm);
					 mapCMToUpdate.put(cm.Id,cm);
				 }
			}
			
			if(!mapCMToUpdate.isEmpty())
			{
				update mapCMToUpdate.values();
			}
			
    	}else 
    	{
    		for(et4ae5__IndividualEmailResult__c res: listIERNew)
			{
				//sent date changed
				 if(res.et4ae5__DateSent__c <> mapOld.get(res.Id).et4ae5__DateSent__c && res.et4ae5__DateSent__c <> null)
				 {
				 	CampaignMember cm = mapCM.get(res.et4ae5__Contact__c+''+res.et4ae5__TriggeredSendDefinition__c);
				 	if(cm<> null && cm.EBH_ResponseCode__c != null && cm.EBH_ResponseCode__c > 10 && cm.Campaign.RecordTypeId == EBH_ConstantsUtility.CAMP_RECORDTYPE_SUB_ID && cm.Campaign.EBH_Channel__c == EBH_ConstantsUtility.CAMPAIGN_CHANNEL_EMAIL)
				 	{
				 		//AC2: Populate  "Target Date" with values from: et4ae5__IndividualEmailResult__c.et4ae5__DateSent__c
				 		cm.Target_Date__c= res.et4ae5__DateSent__c.dateGMT();//NK:23/01/2020: to GMT
				 		mapCMToUpdate.put(cm.Id,cm);
				 	}
				 }
			}  
			if(!mapCMToUpdate.isEmpty())
			{
				update mapCMToUpdate.values();
			}
    	}
    }
    
}