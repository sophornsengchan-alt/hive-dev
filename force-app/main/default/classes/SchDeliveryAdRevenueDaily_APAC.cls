/*****************************************************************************************************************************************************************
    @ Method:         SchDeliveryAdRevenueDaily_APAC
    @ Version:        1.0
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
    @                 Cloned from EU Advertising, SchDeliveryRevenueScheduleDaily_APAC.cls
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.11.2020 / Acmatac SEING / Created the class.
***********************************************************************************************************************************************************/

global class SchDeliveryAdRevenueDaily_APAC implements Schedulable{
    global void execute(SchedulableContext sc) {
        DeliveryController.start(DeliveryController.SCH_TYPE_DAILY, DeliveryController.SOBJECT_AD_REV_DAILY, 'APAC');
    }
}