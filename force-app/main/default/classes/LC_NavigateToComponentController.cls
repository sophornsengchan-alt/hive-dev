/*
    Description: This serves as the controller class for LC_NavigateToComponent.cmp
    Change history: 
        MN      10122019
                    - If quote is approved, disable the ‘Edit Line Item’ functionality and throw a message saying ‘You cannot edit an already approved Quote’.
        US-0016235 10.12.2024 / Sothea Horn / ADS - Apply Filters on Price books in Edit line items screen
*/
public with sharing class LC_NavigateToComponentController {

    private static final String SOQL_QUOTE = 'SELECT Id, Name, Pricebook2Id, Status, OpportunityId FROM Quote WHERE Id = :quoteId LIMIT 1';
    
    @AuraEnabled
    public static Map<String, Object> doInitInfo(String recId) {
        Map<String, Object> mapInfo = new Map<String, Object>();
        if (recId instanceof Id) return mapInfo;
        
        String sObjectType = String.valueOf(((Id)recId).getSObjectType());
        mapInfo.put('sObjectName', sObjectType);
        
        return mapInfo;
    }

    /*****************************************************************************************************************************
    @ Method:   getRecordData
    @ Author: 	Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:	US-0009102 - [Ads 2020] Product Config - Roles and Pricebooks
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: US-0009102 23.02.2021 / Sophal Noch / Modify method
                      US-0016235 10.12.2024 / Sothea Horn / ADS - Apply Filters on Price books in Edit line items screen
    *****************************************************************************************************************************/  
    @AuraEnabled
	public static Quote getRecordData(String quoteId) {
        List<Quote> listQuotes = ApexSafe.query().doQuery(SOQL_QUOTE, new Map<String, Object> {'quoteId' => quoteId});
        Quote quote = listQuotes[0];
		// GW_Quote.assignDefaultPricebook(quote);
        List<Pricebook2> pricebook = LC_AddPricebook2Quote.getPricebookData(null, quote.OpportunityId);
        // US-0009102 update default price if user has only one
        if (quote.Pricebook2Id == null && pricebook.size() == 1) { 
            quote.Pricebook2Id = pricebook[0].Id; 
            ApexSafe.dml().doUpdate(new List<Quote>{quote}, true);
        } 
		return quote;
	}

    // 31.07.2020 / Acmatac SEING: US-0007876 Be able to create one or many quotes on an Opportunity, without needing to create a Media Plan
    // @AuraEnabled
    // public static RemoteResponse createQuoteFromMP(String mediaPlanId){
    //     RemoteResponse response = new RemoteResponse();
    //     try {
            
    //         if(!Util.hasPermission('New_Quote')){
    //             response.statusCode = RemoteResponse.STATUSCODE_ERROR;
    //             response.message = 'You don\'t have permission to create new Quote!';
    //             return response;
    //         }
            
    //         Quote newQuote = GW_MediaPlan.convertMediaPlanToQuote(mediaPlanId);
    //         GW_Quote.applyInitValue(newQuote);
    //         //insert newQuote;
    //         WithoutSharing.doInsert(new List<sObject>{newQuote});
    //         response.content = newQuote.Id;
    //         response.statusCode = RemoteResponse.STATUSCODE_OK;
    //     } catch(Exception ex) {
    //         return new RemoteResponse(ex.getMessage(),RemoteResponse.STATUSCODE_ERROR);
    //     }
    //     return response;
    // }

    /*****************************************************************************************************************************
    @ Method:   createQuoteFromOpp
    @ Version:  1.0
    @ Author: 	Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:	US-0007876 Be able to create one or many quotes on an Opportunity, without needing to create a Media Plan
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     String recordId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.07.2020 / Acmatac SEING / Created the  Method.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static RemoteResponse createQuoteFromOpp(String recordId){
        RemoteResponse response = new RemoteResponse();
        try {
            
            if(!Util.hasPermission('New_Quote')){ response.statusCode = RemoteResponse.STATUSCODE_ERROR; response.message = 'You don\'t have permission to create new Quote!'; return response;}
            
            Quote newQuote = GW_Opportunity.convertOppToQuote(recordId);
            GW_Quote2.applyInitValue(newQuote);

            WithoutSharing.doInsert(new List<sObject>{newQuote});
            response.content = newQuote.Id;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
        } catch(Exception ex) {
            return new RemoteResponse(ex.getMessage(),RemoteResponse.STATUSCODE_ERROR);
        }
        return response;
    }

    @AuraEnabled
    public static RemoteResponse hasPermission(){
        RemoteResponse response = new RemoteResponse();
            if(!Util.hasPermission('AddProducts')){ response.statusCode = RemoteResponse.STATUSCODE_ERROR; response.message = 'You don\'t have permission to add products!'; return response;}
            response.statusCode = RemoteResponse.STATUSCODE_OK;
        return response;
    }
}