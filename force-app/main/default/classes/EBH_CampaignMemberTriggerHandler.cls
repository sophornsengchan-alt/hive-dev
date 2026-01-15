/*********************************************************************************************************************************
@ Class:          EBH_CampaignMemberTriggerHandler
@ Version:        1.0
@ Author:         NEHA LUND 
@ Purpose:        Handler Class for CampaignMember Trigger
                  EPH-31 : Campaign Review and Measurement
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.06.2017 / NEHA LUND / Created the class.
@               : 29/07/2022 / SRONG TIN : US-0012126 - CPU Limit error when user update Campaign stage to "Stopped" 
*********************************************************************************************************************************/
public without sharing class EBH_CampaignMemberTriggerHandler {
    
    //NK:30/01/2020:US-0007007:
    //flag that those field updated from MC, and need to udpate related tasks. task trigger also update back Campaign Member
    //prevent loop back trigger CM Trigger<--->Task Trigger
    public static Boolean FROM_MC_FIELDS_UPATE = false;
    public static String WHERE_TASK = ' Where EBH_CampaignMemberId__c IN: setCMIds AND Follow_Up_Task__c=false AND WhatId IN:setCampIds AND WhoId IN:setContIds';
    public final static String CMRC_COMPLETED     = 'Completed';
    
    /*****************************************************************************************************************************
    @ Method:         hasResponseCodeChanged
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Check and returns true if the EBH_ResponseCode__c field has changed in CampaignMember has changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      camp:                 CampaignMember to check field(s) change for
                      CampaignMemberOldMap: CampaignMember old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
                      Last Response Date
                      Response Code
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.06.2017 / NEHA LUND / Created the  Method.
    @               : 21.02.2018 / Vadhanak Voun / Updated (added) condition: (camp.EBH_Results__c==null && camp.EBH_ResponseCode__c <>null);
    *****************************************************************************************************************************/
    public static Boolean hasResponseCodeChanged(CampaignMember camp, Map<Id, CampaignMember> CampaignMemberOldMap) {
        
        CampaignMember oldcamp = CampaignMemberOldMap != Null ? CampaignMemberOldMap.get(camp.Id) : camp;
        
        return camp.campaignId != oldcamp.campaignId ||
               camp.EBH_LastResponseDate__c != oldcamp.EBH_LastResponseDate__c ||
               camp.EBH_ResponseCode__c != oldcamp.EBH_ResponseCode__c ||
               CampaignMemberOldMap == null ||
               (camp.EBH_Results__c==null && camp.EBH_ResponseCode__c <>null);
               
    } 
    public static void updateAccountResponse(List<CampaignMember> listCM_new , Map<ID,CampaignMember> mapCM_old){
        
       // Map<Id, Date> firstresponseDateMap = new Map<ID,  Date>();
       // Map<Id, Date> lastresponseDateMap = new Map<ID,  Date>();
        Map<ID, CampaignMember> cMap = new Map<ID, CampaignMember>();
        Map<ID, Date> firstResponseMap = new Map<ID, Date>();
        Map<ID, Date> lastResponseMap = new Map<ID, Date>();
        Map<ID, Integer> responseMap = new Map<ID, Integer>();
        
        Map<ID,Account> accountMap = new Map<ID,Account>();
        Set<ID> sAccountIDs = new Set<ID>();
        Map<ID, ID> campaignSellerListMap = new Map<ID, ID>();
        
        Set<ID> contactIds = new Set<ID>();
        Set<ID> campaignIds = new Set<ID>();
        List<CampaignMember> cMembers = new List<CampaignMember>();
        for(CampaignMember cm: listCM_new){
            
            if( (cm.EBH_REsponseCode__c <> mapCM_old.get(cm.Id).EBH_REsponseCode__c && cm.EBH_REsponseCode__c <> null) ||
	            (cm.EBH_FirstResponseDate__c <> mapCM_old.get(cm.Id).EBH_FirstResponseDate__c && cm.EBH_FirstResponseDate__c <> null) ||
	            (cm.EBH_LastResponseDate__c <> mapCM_old.get(cm.Id).EBH_LastResponseDate__c && cm.EBH_LastResponseDate__c <> null)
	            )
	         {
	            
	            cMembers.add(cm);
	            campaignIds.add(cm.campaignID);
	            cMap.put(cm.contactId, cm);
	            contactIds.add(cm.ContactId);
            }
        
        }
        if(cMembers.isEmpty()) return;
        
        if(!campaignIDs.isEmpty())
        for(Campaign cg: [SELECT EBH_SellerList__c, Id from Campaign where ID In :campaignIds]){
            
            campaignSellerListMap.put(cg.Id, cg.EBH_SellerList__c);
            
        }
    
        if(!contactIds.isEmpty()){
            Account accRecord;
            
            Set<ID> accountIds = new SET<ID>();
             for(Contact con: [SELECT AccountID, Id from Contact where ID IN :contactIds]){
                
                accountIds.add(con.AccountID);
              }
              
            for(CampaignMember cMember: [SELECT EBH_FirstResponseDate__c,EBH_ResponseCode__c , EBH_LAstREsponseDate__c, contactId, Id from CampaignMember 
                 WHERE campaignId IN :campaignIds and contact.AccountId IN :AccountIDs]){
                     cMap.put(CMember.contactId, cMember);
                     
             }
              
              Date firstDate,lastDate;
              Integer response;
              
              for(Account acc: [SELECT ID, (SELECT Id from Contacts) from Account WHERE ID IN :accountIds]){
                  
                  accountMap.put(acc.Id, acc);
                  sAccountIDs.add(acc.Id);
                  firstDate = firstResponseMap.containsKey(acc.Id) ? firstResponseMap.get(acc.Id) : null;
                  lastDate =  lastResponseMap.containsKey(acc.Id) ? lastResponseMap.get(acc.Id) : null;
                  response = responseMap.containskey(acc.Id) ? responseMap.get(acc.Id) : null;
                  
                  for(Contact con: acc.Contacts){
                      
                      if( cMap.containsKey(con.Id) && (firstDate == null || cMap.get(con.Id).EBH_FirstResponseDate__c < firstDate) 
                            ){
                          
                          firstDate = cMap.get(con.Id).EBH_FirstResponseDate__c ;
                          
                      }
                      
                      if( cMap.containsKey(con.Id) &&
                      (lastDate == null || cMap.get(con.Id).EBH_LastResponseDate__c > lastDate) 
                            ){
                          
                          lastDate = cMap.get(con.Id).EBH_LastResponseDate__c ;
                          
                      }
                      
                      if( cMap.containsKey(con.Id) &&
                      (response == null || cMap.get(con.Id).EBH_ResponseCode__c > response) 
                            ){
                          
                          response = Integer.valueOf(cMap.get(con.Id).EBH_ResponseCode__c) ;
                      }
                      
                  }
                  
                  firstResponseMap.put(acc.Id, firstDate);
                  lastResponseMap.put(acc.Id, lastDate);
                  responseMap.put(acc.Id, response);
                 
              }
            
        }
        /*List<EBH_TargetedSeller__c> tsellers = new List<EBH_TargetedSeller__c>();
        
        for(EBH_TargetedSeller__c ts: [SELECT eBH_FirstResponseDate__c, EBH_Seller__c,ebh_LastResponseDate__c, Id from EBH_TargetedSeller__c
                                        WHERE EBH_SellerList__c IN :campaignSellerListMap.values() and 
                                        EBH_Seller__c IN :accountMap.values()]){
                                            
            ts.EBH_FirstResponseDate__C = firstResponseMap.get(ts.EBH_Seller__c);
            ts.EBH_LastResponseDate__c = lastResponseMap.get(ts.eBH_Seller__c);
            ts.EBH_ExitCode__c = responseMap.get(ts.eBH_Seller__c)+'';
            
            tsellers.add(ts);
        }
        if(!tsellers.isEmpty()){
            update tsellers;
        }*/
        
        List<ID> sellerListID = campaignSellerListMap.values();
        if(System.isFuture() || System.isBatch() || System.isQueueable())
        {
        	doUpdateAccountResponse2(sellerListID, sAccountIDs,firstResponseMap,lastResponseMap,responseMap);
        }else
        {
        	//future
        	updateAccountResponse2(sellerListID, sAccountIDs,firstResponseMap,lastResponseMap,responseMap);
        }
    	
    }
    
    /*****************************************************************************************************************************
    @ Method:         updateAccountResponse2
    @ Version:        1.0
    @ Author:         Sovantheany.dim 
    @ Purpose:        EPH-7056 Change method from sync to Async
    @ We are reaching the too many soql limits when trying to update the account response of a Campaign.
    @ Please change this method EBH_CampaignMemberTriggerHandler.updateAccountResponse to be executed using the @future tag.
    @ Please add a error control in the catch section in order to save in the EBH_ApexLog the possible failures.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      sellerListID: list ID of Seller list
                      sellerIDs: List ID of Seller
                      firstResponseMap: first respone date
                      lastResponseMap: last respone date
                      responseMap: response code
    ------------------------------------------------------------------------------------------------------------------------------
    @ No Returns
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.Feb.2019 / Sovnatheany Dim / Created the  Method.
    *****************************************************************************************************************************/
    @future
    public static void updateAccountResponse2(List<ID> sellerListID, Set<ID> sellerIDs,Map<ID, Date> firstResponseMap,Map<ID, Date> lastResponseMap,Map<ID, Integer> responseMap){
    	
    	doUpdateAccountResponse2(sellerListID, sellerIDs,firstResponseMap,lastResponseMap,responseMap);
    }
     /*****************************************************************************************************************************
    @ Method:         doUpdateAccountResponse2
    @ Version:        1.0
    @ Author:         Vadhanak Voun 
    @ Purpose:        EPH-7056 Change method from sync to Async
   	@					2 sepparated methods to handle sync or asyn to prevent future called by future...
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      sellerListID: list ID of Seller list
                      sellerIDs: List ID of Seller
                      firstResponseMap: first respone date
                      lastResponseMap: last respone date
                      responseMap: response code
    ------------------------------------------------------------------------------------------------------------------------------
    @ No Returns
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.Feb.2019 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    public static void doUpdateAccountResponse2(List<ID> sellerListID, Set<ID> sellerIDs,Map<ID, Date> firstResponseMap,Map<ID, Date> lastResponseMap,Map<ID, Integer> responseMap){
    	try {
    		List<EBH_TargetedSeller__c> tsellers = new List<EBH_TargetedSeller__c>();
        
	        for(EBH_TargetedSeller__c ts: [SELECT eBH_FirstResponseDate__c, EBH_Seller__c,ebh_LastResponseDate__c, Id from EBH_TargetedSeller__c
	                                        WHERE EBH_SellerList__c IN :sellerListID and 
	                                        EBH_Seller__c IN :sellerIDs]){
	                                            
	            ts.EBH_FirstResponseDate__C = firstResponseMap.get(ts.EBH_Seller__c);
	            ts.EBH_LastResponseDate__c = lastResponseMap.get(ts.eBH_Seller__c);
	            ts.EBH_ExitCode__c = responseMap.get(ts.eBH_Seller__c)+'';
	            
	            tsellers.add(ts);
	        }
	        if(!tsellers.isEmpty()){
	            update tsellers;
	        }
	        
	        } catch(Exception ex) {
	        	EBH_ApexLogger.logError(new List<Exception> { ex }, 'EBH_CampaignMemberTriggerHandler','updateAccountResponse2');
	        	}
    }
    /*****************************************************************************************************************************
    @ Method:         updateCampaignMemberStatus
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Check and returns true if the EBH_ResponseCode__c field has changed in CampaignMember has changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      camp:                 CampaignMember to check field(s) change for
                      CampaignMemberOldMap: CampaignMember old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.06.2017 / NEHA LUND / Created the  Method.
    @               : 20.02.2018 / Vadhanak Voun / Moved all logic code to doUpdateCampaignMemberStatus and added forceUpdate to
                    : share the method with Batch_FixCampaignMemberResponseValue
    *****************************************************************************************************************************/
    public static void updateCampaignMemberStatus(List<CampaignMember> campaignMembers, 
                                                  Map<Id, CampaignMember> campaignMemberOldMap) {
        
        doUpdateCampaignMemberStatus(campaignMembers,campaignMemberOldMap,false);
    }
    
    /*****************************************************************************************************************************
    @ Method:         doUpdateCampaignMemberStatus
    @ Version:        1.0
    @ Author:         Vadhanak Voun 
    @ Purpose:        Moved all code from updateCampaignMemberStatus, and added 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      camp:                 : CampaignMember to check field(s) change for
                      CampaignMemberOldMap  : CampaignMember old map from trigger scope to compare
                      forceUpdate           : run from Batch_FixCampaignMemberResponseValue to fix the missing response 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.02.2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    public static void doUpdateCampaignMemberStatus(List<CampaignMember> campaignMembers_New, 
                                                  Map<Id, CampaignMember> campaignMemberOldMap, Boolean forceUpdate) {
        
        Boolean isInsert =   (campaignMemberOldMap == null);
        Boolean isDelete =    (campaignMembers_New == null);
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        if(isInsert || isDelete){
        	campaignMembers = (isInsert?campaignMembers_New: campaignMemberOldMap.values()); //before delete, use old trigger
        }else
        {
        	for(CampaignMember cm: campaignMembers_New)
        	{
        		//check if EBH_ResponseCode__c changed
        		if(cm.EBH_ResponseCode__c <> campaignMemberOldMap.get(cm.Id).EBH_ResponseCode__c)
        		{
        			campaignMembers.add(cm);
        		}
        	}
        }
        
        if(campaignMembers.isEmpty())return;
                                              
        Map<String, String> responseCodeMap = new Map<String, String>();
       // Map<String, String> outcomeCodeMap = new Map<String, String>();
       // Map<String, String> outcomeValueMap  = new Map<String, String>();
        
        
        //EPH-3818 - Campaign Response values based on the single channel picklist
        for( EBH_CampaignChannelResponse__c cResponse: EBH_CampaignChannelResponse__c.getAll().values()){
            
            if( cResponse.EBH_Channel__c != null)
            responseCodeMap.put( Integer.valueOf(cResponse.EBH_ResponseCode__c)+cResponse.EBH_Channel__c, cResponse.EBH_ResponseCodeValue__c);
            
            
           // outcomeCodeMap.put( Integer.valueOf(cResponse.EBH_ResponseCode__c)+cResponse.EBH_Channel__c, cResponse.EBH_OutcomeCode__c);
          //  outcomeValueMap.put( Integer.valueOf(cResponse.EBH_ResponseCode__c)+cResponse.EBH_Channel__c, cResponse.EBH_OutcomeCodeValue__c);
        }    
        
        Set<ID> campaignIds = new Set<ID>();
        Map<ID, String> campaignChannelMap = new Map<ID, String>();
        
        for( CampaignMember cMember: campaignMembers){
            campaignIDs.add(cMember.campaignId);
        }
        
        //Get the channel from the related campaigns
        for( Campaign cRecord: Database.query(EBH_ConstantsUtility.CTH_CAMPAIGNQUERY)){
           
            if( cRecord.EBH_Channel__c != null)
            campaignChannelMap.put( CRecord.Id, cRecord.EBH_Channel__c);
            
             if(cRecord.EBH_ChannelMP__c != null)
            campaignChannelMap.put( CRecord.Id, cRecord.EBH_ChannelMP__c);
           
        }
         
         //EPH-5945 - to update phone incorrect number on contact
         List<Contact> contacts = new List<Contact>();
         Contact con = new Contact();
         
         //EPH-3818 : loop through camp members to get parent campaign ids from trigger scope
         // if any aggregate fields has changed
        for(CampaignMember campMember : campaignMembers){  
            
          //  Boolean isOK = forceUpdate || hasResponseCodeChanged(campMember, CampaignMemberOldMap);
            //System.debug('>>>isOK: '+isOK);
            //if(isOK) {                
                //update the status based on response code                
                campMember.Status = campMember.EBH_ResponseCode__c == 10 ? EBH_ConstantsUtility.CTH_NONE_STATUS :
                                    campMember.EBH_ResponseCode__c == 20 ? EBH_ConstantsUtility.CTH_NONE_STATUS :
                                    campMember.EBH_ResponseCode__c == 30 ? EBH_ConstantsUtility.CTH_SENT_STATUS :
                                    campMember.EBH_ResponseCode__c == 40 ? EBH_ConstantsUtility.CTH_SENT_STATUS :
                                    campMember.EBH_ResponseCode__c == 50 ? EBH_ConstantsUtility.CTH_SENT_STATUS :
                                    campMember.EBH_ResponseCode__c == 60 ? EBH_ConstantsUtility.CTH_RESPONDED_STATUS :
                                    campMember.EBH_ResponseCode__c == 70 ? EBH_ConstantsUtility.CTH_RESPONDED_STATUS :
                                    campMember.EBH_ResponseCode__c == 80 ? EBH_ConstantsUtility.CTH_RESPONDED_STATUS :
                                    campMember.EBH_ResponseCode__c == 90 ? EBH_ConstantsUtility.CTH_RESPONDED_STATUS :
                                    campMember.EBH_ResponseCode__c == 100 ? EBH_ConstantsUtility.CTH_RESPONDED_STATUS :
                                    EBH_ConstantsUtility.CTH_NONE_STATUS;
                
                /* Commenting this as part of EPH-5628
                campMember.EBH_HasSent__c = campMember.Status == EBH_ConstantsUtility.CTH_SENT_STATUS || campMember.Status == EBH_ConstantsUtility.CTH_RESPONDED_STATUS ? true : false;  
                campMember.EBH_HasResponded__c = campMember.Status == EBH_ConstantsUtility.CTH_RESPONDED_STATUS ? true : false; 
                */
                
                //EPH-5945 - to capture incorrect phone number on Contact
                if(campMember.EBH_ResponseCode__c == 30 && campaignChannelMap.get(campMember.CampaignId).equalsIgnoreCase('GCX Outreach (Phone)'))
                {
                    con = new Contact(Id = campMember.contactId);
                    con.Incorrect_Phone_Number__c = true;
                    contacts.add(con);
                }
                                            
                Integer respCode = Integer.valueOf(campMember.EBH_ResponseCode__c);
                String key =      respCode + campaignChannelMap.get(campMember.CampaignId);
                String defaultKey = respCode + EBH_ConstantsUtility.CTH_DEFAULTVALUE;
                
                campMember.EBH_Results__c = responseCodeMap.containsKey(key) ? responseCodeMap.get(key) :
                                            (responseCodeMap.containsKey(defaultKey) ? responseCodeMap.get(defaultKey) : EBH_ConstantsUtility.CTH_UNKNOWN_RESULT);
        	}          
        
        if( !contacts.isEmpty()){
            Database.update(contacts, false);
        }                                 
    }
   
   /*****************************************************************************************************************************
    @ Method:       aggregateCMRespone
    @ Version:      1.0
    @ Author:       Vadhanak Voun 
    @ Purpose:      EPH-6485 Synchronise campaign feedback from SFMC to SFDC
    @				When I navigate to a Campaign (Campaign Record Type)
	@				Then the below fields are updated for the Campaign's Campaign Members
	@				Based on the aggregated value of the Sub-Campaign's Campaign Members:
	@					Response Code = the "greatest" value of the Response Code from Campaign Members of the same Contact
	@					First Response Date = the earliest of the First Response Date from Campaign Members of the same Contact
	@					Last Response Date = the latest of the Last Response Date from Campaign Members of the same Contact
	@					**recal everytime master or sub campaign created/updated
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      listCM:                 : CampaignMember  
    @                 mapOld  : CampaignMember old map from trigger scope to compare
    @ Trigger:		 after insert, after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27/09/2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
   public static void aggregateCMRespone(List<CampaignMember> listCM_new,Map<Id,CampaignMember> mapCM_old)
   {
   	 	Set<String> setCamId = new Set<String>();
   	 	Boolean isInsert = (mapCM_old==null);
   	 	List<CampaignMember> listCM = new List<CampaignMember>();
   	 	Set<String> setContactId = new Set<String>(); //contact ID for to filter soql
   	 	if(isInsert)
   	 	{
   	 		listCM = listCM_new;
   	 		for(CampaignMember cm: listCM)
	   	 	{
	   	 		setCamId.add(cm.CampaignId);
	   	 		setContactId.add(cm.ContactId);
	   	 	}
   	 	}else
   	 	{
   	 		for(CampaignMember cm: listCM_new)
	   	 	{
	   	 		if(fieldsChanged(mapCM_old.get(cm.Id),cm)) //check if 3 fields have been chagned: EBH_ResponseCode__c, EBH_FirstResponseDate__c, EBH_LastResponseDate__c
	   	 		{
	   	 			listCM.add(cm);
	   	 			setCamId.add(cm.CampaignId);
	   	 			setContactId.add(cm.ContactId);
	   	 		}
	   	 	}
   	 	}
   	 	//System.debug('>>>listCM: '+listCM);
   	 	if(listCM.isEmpty())return;
   	 	
   	 	//only EBH_Campaign with sub campaign
   	 	String campRecType = EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE;
   	 	String subRecType = EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE;
   	 	Set<String> setRecType = new Set<String>{EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE,EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE};
   	 	String soqlThisCamp = 'Select Id,ParentId,RecordType.DeveloperName, Parent.RecordType.DeveloperName From Campaign Where Id IN:setCamId'; 
   	 	Map<Id,SObject> mapThisCamp = new Map<Id,SObject>(Database.query(soqlThisCamp));
   	 	
   	 	Set<String> setMasterId = new Set<String>();
   	 	//filtering to master
   	 	for(CampaignMember cm: listCM)
   	 	{
   	 		Campaign camp = (Campaign)mapThisCamp.get(cm.CampaignId);
   	 		//System.debug('>>>camp: '+camp.RecordType.DeveloperName +' >>>P: '+camp.Parent.RecordType.DeveloperName);
   	 		if(!setRecType.contains(camp.RecordType.DeveloperName))
   	 		{
   	 			continue;
   	 		}
   	 		//for master campaign
   	 		if(EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE == camp.RecordType.DeveloperName)
   	 		{
   	 			setMasterId.add(camp.Id);
   	 			
   	 		}//for sub-campaign (make sure current camp is a sub of a master not sub of sub)
   	 		else if(camp.RecordType.DeveloperName==EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE && camp.Parent.RecordType.DeveloperName == EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE )
   	 		{
   	 			if(camp.ParentId <> null)setMasterId.add(camp.ParentId);
   	 		}
   	 	}
   	 	//System.debug('>>>setMasterId: '+setMasterId);
   	 	//we have master
   	 	if(!setMasterId.isEmpty())
   	 	{
   	 		String whereCampMaster = ' Where CampaignId IN:setMasterId AND ContactId IN :setContactId';
	   	 	String whereCampSub = ' Where Campaign.ParentId IN :setMasterId AND ContactId IN :setContactId';
	   	 	Map<String,CampaignMember> mapCM_Contact = new Map<String,CampaignMember>();
	   	 	
	   	 	//members from Master Campaign
	   	 	for(CampaignMember  cm :  Database.query(EBH_ConstantsUtility.SOQL_CAM_MEMBER + whereCampMaster))
	   	 	{
	   	 		mapCM_Contact.put(cm.ContactId,cm);
	   	 	}
	   	 	//System.debug('>>>mapCM_Contact: '+mapCM_Contact);
	   	 	Map<Id,CampaignMember> mapCMToUpdate = new Map<Id,CampaignMember>();
	   	 	Map<String,CampaignMember> mapDistinctMembers = new Map<String,CampaignMember>();
	   	 	//EPH-7108 Unique Campaign Member Upward Aggregation
	   	 	//campaign members from different sub campaign with same contact in the same Master considered as 1 member
	   	 	for(CampaignMember  cm :  Database.query(EBH_ConstantsUtility.SOQL_CAM_MEMBER + whereCampSub))
	   	 	{
				mapDistinctMembers.put(cm.Campaign.ParentId+'_'+cm.ContactId,cm);	   	 		
	   	 	}
	   	 	
	   	 	//members from sub campaign
	   	 	for(CampaignMember  cm : mapDistinctMembers.values())
	   	 	{
	   	 		if(mapCM_Contact.containsKey(cm.ContactId)){
	   	 			CampaignMember cmMaster = mapCM_Contact.get(cm.ContactId);
	   	 			///System.debug('>>>cmEBH_FirstResponseDate__c:  '+cm.EBH_FirstResponseDate__c +' >>masterEBH_FirstResponseDate__c: '+cmMaster.EBH_FirstResponseDate__c);
	   	 			//if sub-cam bigger, then take it. if not keep the old value
	   	 			cmMaster.EBH_ResponseCode__c = cm.EBH_ResponseCode__c ==null?cmMaster.EBH_ResponseCode__c:(cm.EBH_ResponseCode__c>cmMaster.EBH_ResponseCode__c?cm.EBH_ResponseCode__c:cmMaster.EBH_ResponseCode__c);
	   	 			cmMaster.EBH_FirstResponseDate__c = getSortedDate(cmMaster.EBH_FirstResponseDate__c,cm.EBH_FirstResponseDate__c,0);
	   	 			cmMaster.EBH_LastResponseDate__c = getSortedDate(cmMaster.EBH_LastResponseDate__c,cm.EBH_LastResponseDate__c,1);
	   	 			mapCMToUpdate.put(cmMaster.Id,cmMaster);
	   	 		}
	   	 	}	
	   	 	
	   	 	if(!mapCMToUpdate.isEmpty())
	   	 	{
	   	 		 
	   	 		 CM_DMLWorker updateWorker = new CM_DMLWorker(mapCMToUpdate.values(),'aggregateCMRespone',aggregateRetryCounter);
	   	 		 updateWorker.doUpdate();
	   	 	}
	   	 	 
   	 	}
   }
   public static Integer aggregateRetryCounter = 0;
   
   private static Boolean fieldsChanged(CampaignMember cmOld,CampaignMember cmNew)
   {
   		return (cmOld.EBH_ResponseCode__c <> cmNew.EBH_ResponseCode__c ||
   				cmOld.EBH_FirstResponseDate__c <> cmNew.EBH_FirstResponseDate__c ||
   				cmOld.EBH_LastResponseDate__c <> cmNew.EBH_LastResponseDate__c); 
   }
   
   private static Date getSortedDate(Date dMaster,Date dCM,Integer dest)
   {
   		List<Date> listDate = new List<Date>(); 
   		if(dMaster <> null)
   		{
   			listDate.add(dMaster);
   		}
   		if(dCM <> null)
   		{
   			listDate.add(dCM);
   		}
   		listDate.sort();
   		
   		return listDate.isEmpty()?null:(dest==0?listDate[0]:listDate[listDate.size()-1]);
   }
   /*****************************************************************************************************************************
    @ Method:       updateCampaignToExecute
    @ Version:      1.0
    @ Author:       Vadhanak Voun 
    @ Purpose:      EPH-6562 limit "Refresh Members" when Campaign is Ready to Launch
    @				AC2:
	@				Given that I have the "Refresh Members" button
	@				When the first Response Codes for the Campaign's Campaign Members is updated (via Journey, Survey or other means)
	@				Then the status of the Campaign will automatically update to "Executed"
	@				(And as per AC1, the "Refresh Members" button will no longer be clicked due to validation)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      listCM:                 : CampaignMember  
    @                 mapOld  : CampaignMember old map from trigger scope to compare
    @ Trigger:		  after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16/10/2018 / Vadhanak Voun / Created the  Method.
    @				: 22/02/2019 / Vadhanak Voun / EPH-7139: when stop: So we should not change the status of a Campaign to "Campaign Running".
    @               : 29/07/2022 / SRONG TIN : US-0012126 - CPU Limit error when user update Campaign stage to "Stopped" 
    *****************************************************************************************************************************/
    public static void updateCampaignToExecute(List<CampaignMember> listCM,Map<Id,CampaignMember> mapOld)
    {
    	Map<Id,Campaign> mapCampaignToUpdate = new Map<Id,Campaign>();
    	for(CampaignMember cm: listCM)
    	{
    		//SRONG TIN / 29.07.2022 : US-0012126
            if(EBH_CampaignTriggerHandler.getStoppedCampaigns().contains(cm.CampaignId) || cm.Campaign_Status__c == CMRC_COMPLETED)continue;//NK:22/02/2019: EPH-7139
    		//NK:01/11/2018: ""&& EBH_ResponseCode__c>10"
            
    		if(cm.EBH_ResponseCode__c <> mapOld.get(cm.Id).EBH_ResponseCode__c && cm.EBH_ResponseCode__c <> null && cm.EBH_ResponseCode__c>10 && (mapOld.get(cm.Id).EBH_ResponseCode__c==null || mapOld.get(cm.Id).EBH_ResponseCode__c==10) )
    		{
    			mapCampaignToUpdate.put(cm.CampaignId,new Campaign(Id=cm.CampaignId,Status=EBH_ConstantsUtility.CMRC_EXECUTION));
    		}
    	}
    	if(!mapCampaignToUpdate.isEmpty())
    	{
    		update mapCampaignToUpdate.values(); 
    	}
    }
    
    class CM_DMLWorker extends DMLWorker{
    	
    	public CM_DMLWorker(List<SObject> listSobject,String methodName,Integer numRetry)
    	{
    		super(listSobject,'EBH_CampaignMemberTriggerHandler',methodName);
    		retry_counter = numRetry;
    	}
    	
    	void setCounter()
		{
			retry_counter = retry_counter+1;
			EBH_CampaignMemberTriggerHandler.aggregateRetryCounter = retry_counter;
		}
		
   	 	void doRetry()
   	 	{
   	 		Id jobID = System.enqueueJob(new CM_DMLWorker(listSobject,methodName,retry_counter)); //retry
   	 	}  
    	
    }
    
    /*****************************************************************************************************************************
    @ Method:       updateSellerDetailToTasks
    @ Version:      1.0
    @ Author:       Vadhanak Voun 
    @ Purpose:      US-0000802 [GCX] Create Readonly field for Marketing Cloud in Tasks
    @				Extend existing Campaign Member trigger to watch for this field update and update related Tasks accordingly.
	@				When the field "Campaign Related Seller Details" is updated in Campaign Member ,when Tasks are created the value is pulled to the Task Field "Campaign Related Seller Details"
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      listCM:                 : CampaignMember  
    @                 mapOld  : CampaignMember old map from trigger scope to compare
    @ Trigger:		  before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27/11/2019 / Vadhanak Voun / Created the  Method.
    @				: 22/01/2020/ Vadhanak Voun/ US-0007007 [Sub Campaign]Cancellation of Campaign Member via Journey Builder. after update to before update
    @					If Campaign Member."Marketing Cloud Status" is set to "Cancelled" by MC Journey Builder
	@					{check if (Task.Follow_Up_Task__c = false AND Campaign Member. EBH_ResponseCode__c = 10 OR 40)
	@				            then proceed with Task Cancellation
	@					update the Campaign Member.EBH_ResponseCode__c to “22” 
	@					Update the Campaign Member.EBH_Results to “Cancelled”
	@				           Query the Task related to the campaign Member whose Marketing Cloud Status" = "Cancelled"
	@				           Update the Task.Response Code to “Cancelled” and set the “Task.Status = Cancelled”
	@				           update the Task.MC Status = "Cancelled"}
	@					else
	@						"Marketing Cloud Journey cannot cancel Tasks with Other response code"
	@				:04/03/2020/Vadhanak Voun/ US-0007249 [Sub Campaign] Task Deletion instead of Task cancellation
	@					"Marketing Cloud Status" = "Cancelled" to campaign Members with response code = 10 or 40 then
	@					HIVE to update the Campaign Member . Response code to “22” and status = Cancelled and
	@					check if the (Task is not a follow up task and Task.EBH_ResponseCode__c = 10 or 40 )then
    @					delete the Tasks related to the Campaign Members instead of updating Task Status to "Cancelled".
    @               :04/08/2020 / Vadhanak Voun / US-0008003 - Marketing Cloud Status is unable to be updated from Journey Builders
    @                   		** Task.WhatId = CampaigMember.CampaignId
	@	                        ** Task.WhoId = CampaigMember.ContactId
	@				: 29/04/2021 / Sovantheany Dim / US-0009239 - [MC Journey Builder] - Campaign Member related tasks are not deleted when MC Status = Cancelled
	@							Move from Trigger to nightly batch job for Campaign Member update & related task deletions
	@							Issue is believed to relate to large volume of tasks being deleted via Trigger causing failures task not properly deleted
    *****************************************************************************************************************************/
    
   public static void updateSellerDetailToTasks(List<CampaignMember> listCM,Map<Id,CampaignMember> mapOld)
    {
        byPass__c settings = byPass__c.getOrgDefaults();
        Map<String,CampaignMember> mapCMUpdated = new Map<String,CampaignMember>();
        Set<String> setCampIds = new Set<String>();
        Set<String> setContIds = new Set<String>();

    	for(CampaignMember cm: listCM)
    	{
    		if((cm.Campaign_Related_Seller_Details__c <> mapOld.get(cm.Id).Campaign_Related_Seller_Details__c)
    			|| (cm.PriorityOrder__c <> mapOld.get(cm.Id).PriorityOrder__c) 
    			|| ((cm.Marketing_Cloud_Status__c <> mapOld.get(cm.Id).Marketing_Cloud_Status__c) && cm.Marketing_Cloud_Status__c==EBH_ConstantsUtility.CM_MC_STATUS_CANCELLED)
    			)
    		{
                mapCMUpdated.put(cm.Id,cm);
                setCampIds.add(cm.CampaignId);
                setContIds.add(cm.ContactId);

    		}
    	}
    	//field updated, then find the related tasks then assign the updated value
    	if(!mapCMUpdated.isEmpty())
    	{
    		//Set<String> setTaskToDelete = new Set<String>();
    		Map<String,Task> mapTaskToDelete = new Map<String,Task>();
    		Set<String> setCMIds = mapCMUpdated.keySet();
    		Map<String,Task> mapTAskToUpdate = new Map<String,Task>();
    		for(Task t: Database.query(EBH_ConstantsUtility.SOQL_TASK + WHERE_TASK))
    		{
    			CampaignMember cm = mapCMUpdated.get(t.EBH_CampaignMemberId__c);
    			if(t.Campaign_related_Seller_Details__c <> (''+cm.Campaign_Related_Seller_Details__c).left(255)) // compare task with the first 255 characters of campaign member
    			{

    				t.MCStatus__c = 'Updated';
    				mapTAskToUpdate.put(t.Id,t);
    			}
    			if(cm.PriorityOrder__c <> t.Order_Priority__c)
    			{
    				t.Order_Priority__c = cm.PriorityOrder__c;
    				t.MCStatus__c = 'Updated';
    				mapTAskToUpdate.put(t.Id,t);
    			}
    			
    			//check if CM being Cancelled. then cancel the task
    			if(cm.Marketing_Cloud_Status__c==EBH_ConstantsUtility.CM_MC_STATUS_CANCELLED 
    				&& (cm.EBH_ResponseCode__c==10 || cm.EBH_ResponseCode__c==40))
    			{
    				//process cancallation
    				cm.EBH_ResponseCode__c = 22;
    				cm.EBH_Results__c = EBH_ConstantsUtility.CMRC_CANCELLED;
    				
    				//29/04/2021:TH:US-0009239 move to batch: Batch_CancelTaskOnCampaignMember
    				if(!settings.Delete_Task_From_Trigger__c) continue;
    				if(t.EBH_ResponseCode__c <> null && (t.EBH_ResponseCode__c==10 || t.EBH_ResponseCode__c==40))
    				{
    					//setTaskToDelete.add(t.Id);
    					mapTaskToDelete.put(t.Id,t);
    				}
    			}
    			
    		}
    		if(!mapTAskToUpdate.isEmpty())
    		{
    			FROM_MC_FIELDS_UPATE = true;
    			update mapTAskToUpdate.values();
    		}
    		//29/04/2021:TH:US-0009239 move to batch: Batch_CancelTaskOnCampaignMember
    		if(!mapTaskToDelete.isEmpty()) delete mapTaskToDelete.values();
    	}
    	
    }
    
}