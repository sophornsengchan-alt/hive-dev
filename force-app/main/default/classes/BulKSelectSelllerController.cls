/*********************************************************************************************************************************
@ Class:          BulKSelectSelllerController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0014207 - ADS - Cohort - Bulk Deactivate Sellers
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  17.10.2023 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
public with sharing class BulKSelectSelllerController {

    public Boolean isManagedLttm  {get;set;} 
	public Boolean  isAdvertising   {get;set;} 
    private final String PARAM_ID = 'id';
    private final String RTYPE_BOB_ADS_COHORT = 'Advertising_Cohort';

    /*********************************************************************************************************************************
    @ Method:         BulKSelectSelllerController
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014207 - ADS - Cohort - Bulk Deactivate Sellers
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  17.10.2023 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    public BulKSelectSelllerController(ApexPages.StandardSetController controller){
        
        // use Managed / LTTM custom related list as default
        isManagedLttm = true;
        isAdvertising = false;

        String bobId = String.escapeSingleQuotes(String.isBlank(System.currentPageReference().getParameters().get(PARAM_ID)) ? '': System.currentPageReference().getParameters().get(PARAM_ID));
        if(String.isNotBlank(bobId)){
            Boolean isAdsBob = [Select Id From BoB__c Where Id=:bobId And RecordType.DeveloperName =: RTYPE_BOB_ADS_COHORT Limit 1].isEmpty() ? false : true;
            if(isAdsBob){ // use Advertising custom related list when BoB__c.RecordType.DeveloperName = 'Advertising_Cohort'
                isManagedLttm = false;
                isAdvertising = true;
            }
        }
    }
}