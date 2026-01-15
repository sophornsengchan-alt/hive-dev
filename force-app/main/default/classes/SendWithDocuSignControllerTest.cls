/*********************************************************************************************************************************
@ Class:          SendWithDocuSignControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Test Class for SendWithDocuSignController.cls
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  23.07.2021 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
private class SendWithDocuSignControllerTest {

    @isTest
    private static void test_sendWithDocuSign(){

        ApexPages.StandardController sc = new ApexPages.StandardController(new Contract());
        SendWithDocuSignController controller = new SendWithDocuSignController(sc);

        Test.startTest();
            controller.docuSignUrl = URL.getSalesforceBaseUrl().toExternalForm();
            controller.sendWithDocuSign();
        Test.stopTest();
        
    }
    
}