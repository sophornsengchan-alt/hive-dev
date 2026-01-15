/*****************************************************************************************************************************************************************
    @ Method:         SchWeeklyDeliveryRSD
    @ Version:        1.0
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
    @                 Cloned from EU Advertising, SchWeeklyDeliveryRSD.cls
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.11.2020 / Acmatac SEING / Created the class.
***********************************************************************************************************************************************************/

global class SchWeeklyDeliveryRSD implements Schedulable{
    global void execute(SchedulableContext sc) {
        DeliveryController.start(DeliveryController.SCH_TYPE_WEEKLY, DeliveryController.SOBJECT_AD_REV_DAILY, System.today().addDays(-30) , System.today(), null);
    }
}