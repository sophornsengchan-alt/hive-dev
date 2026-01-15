/*********************************************************************************************************************************
@ Class:          CancelSubDealDCADetailController
@ Version:        1.0
@ Author:         vadhanak (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0016441 - 8 - Cancel Subsidized Deal Contract Agreements
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.02.2025 / vadhanak/ Created the class.
*********************************************************************************************************************************/
public with sharing class CancelSubDealDCADetailController {
	 @testVisible private static final String DEAL_STATUS_NO_LONGER_WANTED_ON_PROMOTION = 'No longer wanted on promotion';
	 @testVisible private static final String DCA_STATUS_CANCELLED = 'Cancelled';
	 @testVisible private static final String DEALSTATUS_CANCELLED = 'Cancelled';	 
	 
	 @testVisible private static Integer TEST_LIMIT_DEAL_UPDATE = 1;	//for test class

	  private static final Integer LIMIT_DEAL_UPDATE = Test.isRunningTest()?TEST_LIMIT_DEAL_UPDATE:100;	//per chunk
    /*****************************************************************************************************************************
	@ Method:   apexInit
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  US-0016441 - 8 - Cancel Subsidized Deal Contract Agreements
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:     dcaId: String
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 03.02.2025 / vadhanak/ Created the method
	*****************************************************************************************************************************/
	 @AuraEnabled
	 public static Map<String,Object> apexInit(String dcaId)
	 {        
        Integer numDeals = ApexSafe.query().doCount('SELECT COUNT() FROM EBH_Deal__c WHERE Deal_Contract_Agreement__c = :dcaId',new Map<String,Object>{'dcaId' => dcaId}); 
        return new Map<String,Object>{'status'=>'ok','numDeals'=>numDeals};
     }

     /*****************************************************************************************************************************
	@ Method:   apexCancelDeals
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  US-0016441 - 8 - Cancel Subsidized Deal Contract Agreements
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:     dcaId: String
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 03.02.2025 / vadhanak/ Created the method
	*****************************************************************************************************************************/
     @AuraEnabled
	 public static Map<String,Object> apexCancelDeals(String dcaId,String cancelReason,Integer currentChunk)
	 {        
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok','done'=>false,'sucessCount'=>0,'errorCount'=>0,'hasDMLError'=>false};    
		Set<String> setFilterOut = new Set<String>{DEALSTATUS_CANCELLED};
		String soqlDCA = 'SELECT Id,Status__c,Cancellation_Reason__c,eBay_Seller__c FROM Deal_Contract_Agreement__c WHERE Id = :dcaId';
		String soqlDeal = 'SELECT Id,Deal_Contract_Agreement__c FROM EBH_Deal__c WHERE Deal_Contract_Agreement__c = :dcaId AND EBH_Status__c NOT IN :setFilterOut LIMIT :LIMIT_DEAL_UPDATE';

		System.SavePoint sp = Database.setSavepoint();
		try 
		{	
			//First update the DCA to Cancelled with the reason
			//second chunk will not update again the DCA if it is already cancelled
			List<Deal_Contract_Agreement__c> listDCA = (List<Deal_Contract_Agreement__c>)ApexSafe.query().secCheck(false).doQuery(soqlDCA,new Map<String, Object> {'dcaId' => dcaId});
			if(currentChunk==0)
			{
				 
				listDCA[0].Status__c = DCA_STATUS_CANCELLED;
				listDCA[0].Cancellation_Reason__c = cancelReason;			 
				ApexSafe.dml().secCheck(false).doUpdate(listDCA,true);

				DealContractAgreementTriggerHandler.createSellerComsByDCA('Deals',new Map<String,String>{dcaId=>listDCA[0].eBay_Seller__c},'Sub Deals Contract Cancellation', 'Subsidized Deal Contract Agreement Cancellation - US');
			}

			//update the related deals by chunk (limit 200?) until done = true
			List<EBH_Deal__c> dealsToUpdate = (List<EBH_Deal__c>)ApexSafe.query().secCheck(false).doQuery(soqlDeal,new Map<String, Object> {'dcaId' => dcaId,'setFilterOut'=>setFilterOut,'LIMIT_DEAL_UPDATE'=>LIMIT_DEAL_UPDATE});

			if(!dealsToUpdate.isEmpty())
			{
				for(EBH_Deal__c oDeal : dealsToUpdate)
				{
					oDeal.EBH_Status__c = DEALSTATUS_CANCELLED;
					oDeal.Cancellation_Reason__c = DEAL_STATUS_NO_LONGER_WANTED_ON_PROMOTION;
				}
            	Database.SaveResult[]  updateResult = ApexSafe.dml().secCheck(false).doUpdate(dealsToUpdate,false);
				handleError(updateResult,mapResult);

				
			}else 
			{
				mapResult.put('done',true); //nomore deals to update
				
			}

		} catch (Exception ex) 
		{
			System.debug(ex);mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
			Database.rollback(sp);
		}
        

		
        return mapResult;
     }

	 @testVisible
	 private static void handleError(Database.SaveResult[]  updateResult,Map<String,Object> mapResult)
	 {
		List<Database.Error> listError = new List<Database.Error>();
		Integer sucessCount = 0;
		for(Database.SaveResult sr : updateResult)
		{
			if(!sr.isSuccess())
			{
				for(Database.Error err : sr.getErrors())
				{
					//System.debug(err);
					listError.add(err);
				}
			}else {
				sucessCount++;
			}
		}
		mapResult.put('sucessCount', sucessCount);
		mapResult.put('hasDMLError', !listError.isEmpty());
		mapResult.put('errorCount', listError.size());
		if(!listError.isEmpty())
		{
			mapResult.put('listError', listError);
		}
	 }
}