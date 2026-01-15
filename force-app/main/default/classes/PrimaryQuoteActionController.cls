/*********************************************************************************************************************************
@ Class:         PrimaryQuoteActionController
@ Version:       1.0
@ Author:        Vahanak Voun (vahanak.voun@gaea-sys.com)
@ Purpose:       Controller for Aura: PrimaryQuote
@				 US-0007904 - [Ads 2020] New Functionality - Ability to make Quote a 'Primary Quote'
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.08.2020 / Vahanak Voun (vahanak.voun@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
public without sharing class PrimaryQuoteActionController {

    final static String soqlQuote = 'Select Id,OpportunityId,Primary_Quote__c From Quote ';

    /*****************************************************************************************************************************
	@ Method:   apexInit
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  US-0007904 - [Ads 2020] New Functionality - Ability to make Quote a 'Primary Quote'
	@			 
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      quoteId
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 20.08.2020/ Vadhanak Voun / Created the  Method. (same name confict in aura)	
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexInit(String parentId)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        Quote q = Database.query(soqlQuote+' Where Id=:parentId');
        mapResult.put('status','ok');
        mapResult.put('quote',q);

        return mapResult;
    }
     
    /*****************************************************************************************************************************
	@ Method:   apexMarkPrimary
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  US-0007904 - [Ads 2020] New Functionality - Ability to make Quote a 'Primary Quote'
	@			 
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      quoteId
	------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.08.2020/ Vadhanak Voun / Created the  Method. (same name confict in aura)
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 17.12.2020 / Sophal Noch / US-0008858 Move logic to Quote Trigger 	
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexMarkPrimary(String parentId)
    {
        Map<String,Object> mapResult = new Map<String,Object>();      

        try
        {
            // Quote current_q = Database.query(soqlQuote+' Where Id=:parentId');
            // String oppId = current_q.OpportunityId;
            // Quote[] listQuotes = Database.query(soqlQuote+' Where OpportunityId =:oppId');
            // for(Quote q: listQuotes)
            // {
            //     q.Primary_Quote__c = false;
            //     if(q.Id == current_q.Id)
            //     {
            //         q.Primary_Quote__c = true;
            //     }
            // }
            // update listQuotes;

            Quote currentQuote = [Select Id From Quote Where Id =: parentId];
            currentQuote.Primary_Quote__c = true;
            update currentQuote; //US-0008858 trigger will do the job

            mapResult.put('status','ok');
            mapResult.put('msg',System.Label.PrimaryQuote_Success);
            
    	}catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
    	catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}
    	
        return mapResult;
    }
}