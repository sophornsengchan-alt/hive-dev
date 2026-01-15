/*********************************************************************************************************************************
@ Class:         HelpCenterControllerTest
@ Version:       1.0

----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.12.2024 / Vimean Heng / US-0016088 - Help Center Page Layout and Quick Links and FAQ Section - Part 2

*********************************************************************************************************************************/
@isTest
private with sharing class HelpCenterControllerTest {
    
    @isTest
    static void getAllKnowledge() {
        HelpCenterController.getAllKnowledge();
    }
    @isTest
    static void getHelpCenterConfig() {
        HelpCenterController.getHelpCenterConfigByLabel('Default');
        HelpCenterController.getHelpCenterConfigByDeveloperName('Default');
    }
}