@isTest
private class TST_UTIL_ExportToCSVController {

    @isTest static void testUTIL_ExportToCSVController() {
        Test.startTest();                           
            UTIL_ExportToCSVController contrl = new UTIL_ExportToCSVController();
            System.assert(contrl.getRows().isEmpty());
        Test.stopTest();                
    }
}