/*********************************************************************************************************************************
@ Class:          GCX_USer_Handler
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        handle for trigger/ object GCX_USer__c
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.10.2019 / Vadhanak Voun / Created the class.
*********************************************************************************************************************************/
public without sharing class GCX_USer_Handler {
    
    /*****************************************************************************************************************************
    @ Method:   apexReAssignTasks
    @ Version:  1.0
    @ Author: 	Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	US-0009681 (4)Automatic Task Assignment - Remove GCX user from Campaign and reassign
    @			AC1: Remove GCX user from the Campaign
	@				Given that I am GCX Team Lead with "GCX Super User Permission" 
	@				When I go to an Outreach Campaign(with Outreach record type, Channel =GCX Outreach(Phone)) and go to Related List "GCX Users" and select a user and set the flag "Inactive for this Campaign" = true
	@				Then the GCX user selected should be removed from the junction object so it is no more related to the Campaign. 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    list new, old map
    @ Event		: After Update
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 23.10.2019 / Vadhanak Voun / Created the  Method
   	@				: 25.10.2019/ Vadhanak Voun/ US-0009666 (3)Automatic Task Assignment - Validation Rules
    *****************************************************************************************************************************/
    public static void removeInactiveRecord(List<GCX_User__c> listNew, Map<Id,GCX_User__c> mapOld)
    {
    	Set<String> setIdToDelete = new Set<String>();
    	for(GCX_User__c gcx : listNew)
    	{
    		if(!gcx.Active__c && gcx.Active__c <> mapOld.get(gcx.Id).Active__c) //when set to Inactive
    		{
    			setIdToDelete.add(gcx.Id);
    		}
    	}
    	 
    	if(!setIdToDelete.isEmpty())
    	{
    		deleteGCXAsyn(setIdToDelete);
    	}
    }
    
    @future
    private static void deleteGCXAsyn(Set<String> setIdToDelete)
    {
    	delete Database.query(EBH_ConstantsUtility.SOQL_GCX_USER +' Where Id IN:setIdToDelete');
    }
}