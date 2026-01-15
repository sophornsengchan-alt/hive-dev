/*********************************************************************************************************************************
@ Class:          QuickActionRedirectorController
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        This controller will store all logic for every Quick Action (Lighting component type) for sObject
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.09.2021 / Mony Nou / Created the class
*********************************************************************************************************************************/
public class QuickActionRedirectorController {

    /**
     * Execute logic under Deal's Quick Action "Amend Contract"
     * Description: US-0010019 - [NA] Subsidized Deals Contract Amendment Process
     *  @param  id, Deal Id
        @return Map<String,Object> 
     */
	@AuraEnabled
    public static Map<String,Object> validateDealForAmendContract(string id) {
        return DealAmendmentProcessController.validateDealForAmendContract(id);
    }

    /**
     * Execute logic under Deal's Quick Action "	Cancel Amendment"
     * Description: US-0010019 - [NA] Subsidized Deals Contract Amendment Process
     *  @param  id, Deal Id
        @return Map<String,Object> 
     */
	@AuraEnabled
    public static Map<String,Object> cancelAmendContract(string id) {
        return DealAmendmentProcessController.cancelAmendContract(id);
    }

    /**
     * Execute logic under Quote's Quick Action "Withdraw Approval"
     * Description: US-0010299 - ADS - Ability to Withdraw an Approved Quote
     *  @param  id, Deal Id
        @return Map<String,Object> 
     */
    @AuraEnabled
    public static Map<String,Object> withdrawApprovalQuote(string id) {
        return GW_Quote2.withdrawApprovalQuote(id);
    }
    
}