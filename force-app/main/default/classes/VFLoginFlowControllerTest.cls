/*********************************************************************************************************************************
@ Class:          VFLoginFlowController
@ Version:        1.0
@ Author:         Sarom Chetra (sarom.chetra@gaea-sys.com)
@ Purpose:        US-0013848 - Create NPS survey in VFpage instead of flow
*********************************************************************************************************************************/
@isTest
public class VFLoginFlowControllerTest {
    @isTest
	private static void testMothed() {
        Test.startTest();
        	VFLoginFlowController loginFlowController = new VFLoginFlowController();
        	loginFlowController.getRatingOptions();
            loginFlowController.getReasonOptions();
            loginFlowController.getShowLoginFlow();
            loginFlowController.selectedRating();
            loginFlowController.selectedReason();
            PageReference pageRef = Page.VFLoginFlow;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('retURL', '/');
        	loginFlowController.finishLoginFlowStartUrl();
        Test.stopTest();
    }
    
    @isTest
    private static void getShowLoginFlowTest() {
        User u = EBH_TestDataFactory.createUser('System Administrator');
        u.Last_NPS_Survey_Send_Date__c = Datetime.now().addDays(-Integer.valueOf(Label.NPS_Today_Minus_90));
        insert u;
        
        System.runAs(u){
            Test.startTest();
            VFLoginFlowController controller = new VFLoginFlowController();
            System.PageReference showLoginFlow = controller.getShowLoginFlow();
            System.assert(showLoginFlow != null);
            Test.stopTest();  
        }
    }
    
    @isTest
    private static void saveRecordTest() {
        User u = EBH_TestDataFactory.createUser('System Administrator');
        u.Last_NPS_Survey_Send_Date__c = Datetime.now().addDays(-Integer.valueOf(Label.NPS_Today_Minus_90));
        insert u;
        
        System.runAs(u){
            Test.startTest();
            VFLoginFlowController controller = new VFLoginFlowController();
            	System.PageReference saveRecord = controller.saveRecord();
            	System.assert(saveRecord == null);
            Test.stopTest();  
        }
    }
    
    

}