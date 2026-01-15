/*****************************************************************************************************************************
@ Class:         DocuSignLNSending2ControllerExt
@ Version:        1.0
@ Author:         Vadhanak Voun	
@ Purpose:        Class controller for LN: DocuSignLightningSendingLocked2 
@							  
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      ContractId:      Id of contract to be checked and shared attachment
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.02.2018 / Vadhanak Voun / Created the  Method.
@				  29.04.2024 / Mony Nou / US-0014641 - Send with Docusign is not Automatically Populating the Seller Signatory Contact	   
*****************************************************************************************************************************/
public without sharing class DocuSignLNSending2ControllerExt {
    
/*****************************************************************************************************************************
@ Method:         checkAndShareAttachments
@ Version:        1.0
@ Author:         Vadhanak Voun	
@ Purpose:        EPH-5370 -  
@							  
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      ContractId:      Id of contract to be checked and shared attachment
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.02.2018 / Vadhanak Voun / Created the  Method.		

*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> checkAndShareAttachments(String contractId) 
    {
    	Map<String,String> result = new  Map<String,String>(); 
		
    	try
    	{	String currentUserId = UserInfo.getUserId();
    		List<ContentDocumentLink> listNewSharing = new List<ContentDocumentLink>();
    		Map<String,ContentDocumentLink> mapBeingShared = new Map<String,ContentDocumentLink>();
    		
 			//all files attached to contract
 			List<ContentDocumentLink> listAttachmets =  [Select  Id, LinkedEntityId, ContentDocumentId From ContentDocumentLink  where LinkedEntityId=:contractId];
 			
 			//files being shared to current user
 			for(ContentDocumentLink cdl: [Select  Id, LinkedEntityId, ContentDocumentId From ContentDocumentLink  where LinkedEntityId=:currentUserId])
 			{
 				mapBeingShared.put(cdl.ContentDocumentId,cdl);
 			}
 			for(ContentDocumentLink cdl : listAttachmets)
 			{
 				if(!mapBeingShared.containsKey(cdl.ContentDocumentId))
 				{
 					listNewSharing.add(
 						new ContentDocumentLink(LinkedEntityId=currentUserId,ContentDocumentId=cdl.ContentDocumentId,Visibility='AllUsers',ShareType='V')
 					);
 				}
 			}
 			
 			if(!listNewSharing.isEmpty())
 			{
 				insert listNewSharing;
 			}

			result.put('status','ok');
			result.put('newshared',listNewSharing.size()+'');
    	}catch(Exception ex)
    	{
    		result.put('status','error');
    		result.put('error',ex.getMessage());
    	}
    	
    	return result;
    }
	
	/*****************************************************************************************************************************
	@ Method:         handleButtonVisibility
	@ Version:        1.0
	@ Author:         Vadhanak Voun	
	@ Purpose:        EPH-6009 Make Docu-Sign Button Visible to Only Those with Docu-Sign Access
	@							  
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      none
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 25.06.2018 / Vadhanak Voun / Created the  Method.
	@				  29.04.2024 / Mony Nou / US-0014641 - Send with Docusign is not Automatically Populating the Seller Signatory Contact		   
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> handleButtonVisibility(String contractId) //MN-29042024-US-0014641: Changed return type to Map<String,Object> & Added contractId parameter
    {
    	String currentUserId = UserInfo.getUserId();
    	PermissionSetAssignment[]  pss = Database.query(EBH_ConstantsUtility.SOQL_DOCUSIGN_USER_PS );
    	
    	//Map<String,String> result = new  Map<String,String>{'visible'=>(pss.isEmpty()?'ko':'ok')}; //MN-29042024-US-0014641  
		Map<String, Object> result = new Map<String, Object>{'visible'=>(pss.isEmpty()?'ko':'ok')}; //MN-29042024-US-0014641: Changed return type to Map<String,Object>
		
    	result.put('docuPageUrl',System.Page.dsfs__DocuSign_CreateEnvelope.getUrl());

		//MN-29042024-US-0014641--START
		String query = 'select Business_Contact__c, Business_Contact__r.Name, Business_Contact__r.Email, Business_Contact__r.FirstName, Business_Contact__r.LastName, RecordType.Name, Owner.Name, ContractNumber, EBH_ContractValue__c from Contract where Id =:contractId AND Business_Contact__c <> NULL AND Business_Contact__r.Email <> NULL';
		List<Contract> lstCont = (List<Contract>) ApexSafe.query().secCheck(false).doQuery(query,new Map<String, Object> {'contractId' => contractId});
		for (Contract cont : lstCont) {
			result.put('sscontact', cont);
		}
		//MN-29042024-US-0014641--END
		
    	return result;
    }
}