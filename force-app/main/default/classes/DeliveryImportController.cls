/*****************************************************************************************************************************************************************
    @ Class:          DeliveryImportController
    @ Version:        1.0
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0010709 - GAM Integration - Adhoc Requests for Historic Data.
    @                 Using for AuraComponent: DeliveryImport.cmp
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  26.10.2021 / Acmatac SEING / Created the class.
***********************************************************************************************************************************************************/

public class DeliveryImportController {

	/** Import Opportunity Product (yesterday/today) with specific zone*/
	@AuraEnabled
    public static Map<String, String> processImportDeliveryZone(String zone)
	{
		return doImport(DeliveryController.SCH_TYPE_MANUALLY, DeliveryController.SOBJECT_AD_PRODUCT, zone);
	}

	/** Import Revenue Schedule Daily (yesterday/today) with specific zone*/
	@AuraEnabled
    public static Map<String, String> processImportDeliveryRS_DailyZone(String zone)
	{
		return doImport(DeliveryController.SCH_TYPE_MANUALLY, DeliveryController.SOBJECT_AD_REV_DAILY, zone);
	}
	
	/** Import Revenue Schedule Monthly (Month to Date) with specific zone*/
	@AuraEnabled
    public static Map<String, String> processImportDeliveryRS_MonthlyZone(String zone)
	{
		return doImport(DeliveryController.SCH_TYPE_MANUALLY, DeliveryController.SOBJECT_AD_REV_MONTHLY, zone);
	}
	
	/** Import With period last 30 days of any SObject*/
	@AuraEnabled
    public static Map<String, String> processImportLast30Days(String sobj)
	{
		return doImport(DeliveryController.SCH_TYPE_MANUALLY, sobj, true);
	}

    /** Import With period by specific date of SObject*/
    @AuraEnabled
    public static Map<String, String> doImport_ByDate(String sobj, String zone, String startDate, String endDate)
	{
        
		try
		{ 
			Integer numPending = [Select count() from DART_Delivery_Support__c 
				WHERE Schedule_Type__c=:DeliveryController.SCH_TYPE_MANUALLY 
				AND Sobject__c=:sobj
				AND Zone__c=:zone
				AND Status__c <> :DeliveryController.DART_STATUS_FINISHED];
			System.debug('Standard Date:::'+System.today());
			System.debug('Converted Date:::'+Date.valueOf(startDate));
			//We expected all DDS are 'finished'; so we can run another, or wait until they all finish
			if(numPending>0)
			{
				return new Map<String, String>{'status' => 'ok', 'msg' => 'Importing Delivery of '+sobj+' - '+ zone + ' is already running.'};
			}
			DeliveryController.start(DeliveryController.SCH_TYPE_MANUALLY, sobj, Date.valueOf(startDate) , Date.valueOf(endDate), zone);
			
			return new Map<String, String>{'status' => 'ok', 'msg' => 'SUCCESS: Importing Delivery of '+sobj+' - '+ zone + ' is now running in background.'};
			
		}catch(Exception ex){
            return new Map<String, String>{'status' => 'ko', 'msg' => 'ERROR: ' + ex};
        }
	}
	
	private static Map<String, String> doImport(String schType,String sobjType, Boolean last30)
	{
		try
		{ 
			Integer numPending = [Select count() from DART_Delivery_Support__c 
				WHERE Schedule_Type__c=:schType 
				AND Sobject__c=:sobjType
				AND Status__c <> :DeliveryController.DART_STATUS_FINISHED];
			
			//We expected all DDS are 'finished'; so we can run another, or wait until they all finish
			if(numPending>0)
			{	  
				return new Map<String, String>{'status' => 'ok', 'msg' => 'Importing Delivery of '+sobjType+' is already running.'};
			}
			if(!last30){
                DeliveryController.start(schType, sobjType);
            }
			else if(sobjType == DeliveryController.SOBJECT_AD_REV_MONTHLY){
				DeliveryController.start(schType, sobjType, System.today().addMonths(-1) , System.today().addMonths(-1), null);
			}else{
				DeliveryController.start(schType, sobjType, System.today().addDays(-30) , System.today(), null);
			}
			return new Map<String, String>{'status' => 'ok', 'msg' => 'SUCCESS: Importing Delivery of '+sobjType+' is now running in background.'};
			
		}catch(Exception ex){
            return new Map<String, String>{'status' => 'ko', 'msg' => 'ERROR: ' + ex};
        }
	}
	
	private static Map<String, String> doImport(String schType,String sobjType, String zone)
	{
		try
		{ 
			Integer numPending = [Select count() from DART_Delivery_Support__c 
				WHERE Schedule_Type__c=:schType 
				AND Sobject__c=:sobjType
				AND Zone__c=:zone
				AND Status__c <> :DeliveryController.DART_STATUS_FINISHED];
			
			//We expected all DDS are 'finished'; so we can run another, or wait until they all finish
			if(numPending>0)
			{	  
				return new Map<String, String>{'status' => 'ok', 'msg' => 'Importing Delivery of '+sobjType+' - '+ zone + ' is already running.'};
			}
			DeliveryController.start(schType, sobjType, zone);
			
			return new Map<String, String>{'status' => 'ok', 'msg' => 'SUCCESS: Importing Delivery of '+sobjType+' - '+ zone + ' is now running in background.'};
			
		}catch(Exception ex){
            return new Map<String, String>{'status' => 'ko', 'msg' => 'ERROR: ' + ex};
        }
	}

    
}