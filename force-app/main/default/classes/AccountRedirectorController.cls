/*********************************************************************************************************************************
@ Class:          AccountRedirectorController
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        This controller will store all logic for every Quick Action (Lighting component type) for sObject Account
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.05.2021 / Mony Nou / Created the class
                  
*********************************************************************************************************************************/
public without sharing class AccountRedirectorController {
    
    /**
     * Execute logic under Quick Action "Request SAP ID"
     * Description: US-0009234 - Button to verify EU VAT ID & Request SAP ID
     * @param id, Account Id
      @return Map<String,Object> 
     */
	@AuraEnabled
    public static Map<String,Object> handleRequestSAPID(string id) {
        return RequestSapNumber.SendEmailNotification(id);
    }

}