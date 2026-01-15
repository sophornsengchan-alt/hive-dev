/*****************************************************************************************************************************************************************
    @ Method:         SchDeliveryAdProduct_America
    @ Version:        1.0
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
    @                 Cloned from EU Advertising, SchDeliveryOpportunityProduct_America.cls
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.11.2020 / Acmatac SEING / Created the class.
***********************************************************************************************************************************************************/

global class SchDeliveryAdProduct_America implements Schedulable{
    global void execute(SchedulableContext sc) {
        DeliveryController.start(DeliveryController.SCH_TYPE_DAILY, DeliveryController.SOBJECT_AD_PRODUCT, 'America');
    }
}