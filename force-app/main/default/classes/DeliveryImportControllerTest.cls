@isTest
private class DeliveryImportControllerTest {
    @isTest
    private static void processImportDeliveryZoneTest(){
        DeliveryImportController.processImportDeliveryZone('EMEA');
    }

    @isTest
    private static void processImportDeliveryRS_DailyZoneTest(){
        DeliveryImportController.processImportDeliveryRS_DailyZone('EMEA');
    }

    @isTest
    private static void processImportDeliveryRS_MonthlyZoneTest(){
        DeliveryImportController.processImportDeliveryRS_MonthlyZone('EMEA');
    }

    @isTest
    private static void processImportLast30DaysTest(){
        DeliveryImportController.processImportLast30Days(DeliveryController.SOBJECT_AD_PRODUCT);
    }

    @isTest
    private static void doImport_ByDateTest(){
        DeliveryImportController.doImport_ByDate(DeliveryController.SOBJECT_AD_PRODUCT, 'EMEA', Date.today().format(), Date.today().addDays(2).format());
    }
}