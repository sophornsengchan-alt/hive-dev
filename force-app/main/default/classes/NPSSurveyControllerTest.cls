@isTest
public class NPSSurveyControllerTest {
    
    static testMethod void testpage(){
        Test.startTest();
        
        
        NPSSurvey_Homepage_Component_Controller controller = new NPSSurvey_Homepage_Component_Controller();
        controller.showSurvey();
        System.debug(controller.SurveyURL);
        System.debug(controller.OpenTheSurvey);
        System.debug(controller.randomNumber);
        controller.updateNPSUser();
        
        Test.stopTest();
        
        
    }  
    
    static testMethod void testGaeaEmail(){
        
        User u = EBH_TestDataFactory.createUser('Standard User Profile');
        u.email='liny.soeung@gaea-sys.com';
        insert u;
        
        System.runAs(u){
            Test.startTest();
            
            
            NPSSurvey_Homepage_Component_Controller controller = new NPSSurvey_Homepage_Component_Controller();
            System.assert(!controller.showSurvey());
            
            
            Test.stopTest();  
            
        }
        
        
        
        
    }
    
     static testMethod void testSystemAdminProfile(){
        
        User u = EBH_TestDataFactory.createUser('System Administrator');
        u.Last_NPS_Survey_Send_Date__c = Datetime.now().addDays(-Integer.valueOf(Label.NPS_Number_of_Days));
        insert u;
        
        System.runAs(u){
            Test.startTest();
            
            EBH_OutboundLink__c outboundlink = new EBH_OutboundLink__c();
            outboundlink.NPS_GCX_Survey__c = '123123';
            outboundlink.EBH_URL__c = 'testtest.com';
            insert outboundlink;
            
            NPSSurvey_Homepage_Component_Controller controller = new NPSSurvey_Homepage_Component_Controller();
            Map<String,Object> mapResult = NPSSurvey_Homepage_Component_Controller.apexInitClicTool();
        //    System.assertEquals('ok', mapResult.get('status'));
            
            
            Test.stopTest();  
            
        }
        
        
        
        
    }
    
}