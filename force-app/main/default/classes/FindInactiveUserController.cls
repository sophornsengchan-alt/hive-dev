/*********************************************************************************************************************************
@ Class:          FindInactiveUserController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Controller for L-Component FindInactiveUser
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.05.2019 / Vadhanak Voun / Created the class.
---------------------------------------------------------------------------------------------------------------------------------/
@ Change history: 22.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0007615 Change Ticket__c to Case
*********************************************************************************************************************************/
public without sharing class FindInactiveUserController {

    /*****************************************************************************************************************************
	@ Method:   apexSaveTicket
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-7204 Record Type for Object ticket: User Reactivation
	@			assign user to Ticket (inactive user field)
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:   current ticket id, selected userid
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 16.05.2019 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> apexSaveTicket(String ticketId, String inactiveUserId)
    {	
        Map<String,String> mapResult = new Map<String,String>();
        try
        {
            Case t = new Case(Id=ticketId,Inactive_User__c=inactiveUserId);
            update t;
            mapResult.put('status','ok');
        }catch(DMLException dex) 
    	{
    		mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}
    	catch(Exception ex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
    	}
     
     	return mapResult;
    }
}