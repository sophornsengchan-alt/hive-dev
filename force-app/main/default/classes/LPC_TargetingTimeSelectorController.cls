/**
 *	Class do SF database transaction call from lightning components TargetingTimeSelector
 *	@author : CPN
 *	@date : 07/Sep/2016
 *	@description : Task #9389 - CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements 
 * 	@references: 
 *	- LPC_TargetingTimeSelector lightning component
 * 	@changeLog:
 *
 * ----------------------------------------------------------------------------------------------------------------------------------
 @ Change history: 22.08.2023 / Sarom Chetra / US-0014000 - Tech Debt: fix dml in the loop for LPC_TargetingTimeSelectorController           
 */

public with sharing class LPC_TargetingTimeSelectorController {
    
    // /**
    //  * Availables opportunities line item for selection
    //  * @param oppLineId, opportunityLineItem Id
    //  * @return RemoteResponse
    //  */
    // @AuraEnabled
    // public static RemoteResponse getTargetingTimeSelector(String quoteLineId){
    //     try{
    //     	Targeting__c tg;
    //     	for(QuoteLineItem q: [select 	Targeting__r.DFP_Time_Monday__c, Targeting__r.DFP_Time_Tuesday__c, 
    //     									Targeting__r.DFP_Time_Wednesday__c, Targeting__r.DFP_Time_Thursday__c, 
    //     									Targeting__r.DFP_Time_Friday__c, Targeting__r.DFP_Time_Saturday__c, 
    //     									Targeting__r.DFP_Time_Sunday__c from QuoteLineItem where id = :quoteLineId and Targeting__c != null ]) {
        										
    //     		tg = new Targeting__c(Id=q.Targeting__c, DFP_Time_Monday__c = q.Targeting__r.DFP_Time_Monday__c,
    //     												DFP_Time_Tuesday__c = q.Targeting__r.DFP_Time_Tuesday__c,
    //     												DFP_Time_Wednesday__c = q.Targeting__r.DFP_Time_Wednesday__c,
    //     												DFP_Time_Thursday__c = q.Targeting__r.DFP_Time_Thursday__c,
    //     												DFP_Time_Friday__c = q.Targeting__r.DFP_Time_Friday__c,
    //     												DFP_Time_Saturday__c = q.Targeting__r.DFP_Time_Saturday__c,
    //     												DFP_Time_Sunday__c = q.Targeting__r.DFP_Time_Sunday__c	);
    //     	}  
    //         RemoteResponse response = new RemoteResponse();
    //         response.content = tg==null? new Targeting__c() : tg;
    //         response.statusCode = RemoteResponse.STATUSCODE_OK;
    //         return response;
    //     }catch(Exception e){
    //         return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    //     }
    // }
    
    /**
     * Availables update opportunity line item record
     * @param oppLineId, opportunity Id
     * @param itemSelector
     * @return RemoteResponse
     *  * ----------------------------------------------------------------------------------------------------------------------------------
     @ Change history: 22.08.2023 / Sarom Chetra / US-0014000 - Tech Debt: fix dml in the loop for LPC_TargetingTimeSelectorController           
     */
    
    @AuraEnabled
    public static RemoteResponse saveTargetingTimeSelector(String quoteLineId, String timeSelector){
    	try{
    		Map<String, Object> mpTimeSelector = (Map<String, Object>)JSON.deserializeUntyped(timeSelector);
            List<Targeting__c> targetingList = new List<Targeting__c>();
    		for(QuoteLineItem q: [select Targeting__c from QuoteLineItem where id = :quoteLineId and Targeting__c != null ]) {
                targetingList.add( new Targeting__c(
                    id = q.Targeting__c,
                    DFP_Time_Monday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Monday__c')),
                    DFP_Time_Tuesday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Tuesday__c')),
                    DFP_Time_Wednesday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Wednesday__c')),
                    DFP_Time_Thursday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Thursday__c')),
                    DFP_Time_Friday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Friday__c')),
                    DFP_Time_Saturday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Saturday__c')),
                    DFP_Time_Sunday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Sunday__c'))
                ));
    		}

            update targetingList;
    		
    		
	        RemoteResponse response = new RemoteResponse();
            response.content = 'Time selector has been save successfully.';
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
    	}catch(Exception e){
    		return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    
	/**
     * Availables targeting for selection
     * @param targetId, Targeting__c Id
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse getTargetingTimeSelectorTemplate(String targetId){
        try{
            List<Targeting__c> lstOppTime = [ Select DFP_Time_Monday__c, 
                                                    DFP_Time_Tuesday__c, 
                                                    DFP_Time_Wednesday__c, 
                                                    DFP_Time_Thursday__c, 
                                                    DFP_Time_Friday__c, 
                                                    DFP_Time_Saturday__c , 
                                                    DFP_Time_Sunday__c
                                                    From Targeting__c Where Id =: targetId
                                            ]; 
            RemoteResponse response = new RemoteResponse();
            response.content = lstOppTime.size() > 0?lstOppTime.get(0):null;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
    
    /**
     * Availables update targeting record
     * @param targetId, targeting Id
     * @param timeSelector
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse saveTargetingTimeSelectorTemplate(String targetId, String timeSelector){
        try{
            Map<String, Object> mpTimeSelector = (Map<String, Object>)JSON.deserializeUntyped(timeSelector);
            Targeting__c tar = new Targeting__c(id = targetId);
            tar.DFP_Time_Monday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Monday__c'));
            tar.DFP_Time_Tuesday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Tuesday__c'));
            tar.DFP_Time_Wednesday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Wednesday__c'));
            tar.DFP_Time_Thursday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Thursday__c'));
            tar.DFP_Time_Friday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Friday__c'));
            tar.DFP_Time_Saturday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Saturday__c'));
            tar.DFP_Time_Sunday__c = String.valueOf(mpTimeSelector.get(Util.NS+'DFP_Time_Sunday__c'));
            
            update tar;
            
            RemoteResponse response = new RemoteResponse();
            response.content = 'Time selector template has been save successfully.';
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
}