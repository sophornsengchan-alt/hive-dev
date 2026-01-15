/*********************************************************************************************************************************
@ Class:          GleanAssistantControllerTest
@ Version:        1.0
@ Author:         Sovantheany Dim
@ Purpose:        US-0016843 - test class for GleanAssistantController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.04.2025 / Sovantheany Dim / Created the class.
*********************************************************************************************************************************/
@isTest
private class GleanAssistantControllerTest {

    @isTest
    static void myUnitTest() {
        Test.startTest();
            String appID = GleanAssistantController.fetchGleanAssistantMetadata('Default');

            Test.setCurrentPage(Page.GleanAssistant);
            ApexPages.currentPage().getParameters().put('applicationID', appID);
            GleanAssistantController controller = new GleanAssistantController();
            System.assertEquals(appID, controller.applicationId, '');
        Test.stopTest();
    
    }
}