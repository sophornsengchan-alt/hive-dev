/*********************************************************************************************************************************
@ Change history: 10.12.2024 / Sothea Horn / US-0016235 - ADS - Apply Filters on Price books in Edit line items screen
*********************************************************************************************************************************/
public with sharing class LC_AddPricebook2Quote {

	@AuraEnabled
	public static String updateQuoteField(String quoteId, String pricebookId) {
		Id priceBId = Id.valueOf(pricebookId);
		try {
			update new Quote(id = quoteId, Pricebook2Id = priceBId) ;

		} catch (Exception e) {System.debug(LoggingLevel.Error, 'ERROR ' + e);AuraHandledException auraError = new AuraHandledException(e.getMessage() + e.getStackTraceString());auraError.setMessage(e.getMessage() + e.getStackTraceString());throw auraError;}

		return 'SUCCESS';
	}

/*****************************************************************************************************************************
@ Method:   getPricebookData
@ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:	US-0009102 - [Ads 2020] Product Config - Roles and Pricebooks
------------------------------------------------------------------------------------------------------------------------------
@ Change history: US-0009102 23.02.2021 / Sophal Noch / Modify method
				  US-0016235 10.12.2024 / Sothea Horn / ADS - Apply Filters on Price books in Edit line items screen
*****************************************************************************************************************************/    
	@AuraEnabled
	public static List<Pricebook2> getPricebookData(String searchName, String opportunityId) {
		List<Pricebook2> allowedPricebook = new List<Pricebook2>();
		try {

			allowedPricebook = HIVE_Helper.getPriceBooks(opportunityId, searchName);
			
        } catch (Exception e) {System.debug(LoggingLevel.Error, 'ERROR ' + e); AuraHandledException auraError = new AuraHandledException(e.getMessage() + e.getStackTraceString()); auraError.setMessage(e.getMessage() + e.getStackTraceString()); throw auraError;}

        return allowedPricebook;
	}

}