@isTest
private class GoToUserStoryControllerTest {
      @testSetup
    static void setupData(){
        copado__User_Story__c cus = new copado__User_Story__c();
        cus.Old_Copado_Reference__c='OldReference';
        insert cus;
    }

 private static testMethod void test1() {

              
          
         PageReference pageRef = Page.GoToUserStory;
          Test.setCurrentPage(pageRef);

   		pageRef.getParameters().put('OldReference',null);
          GoToUserStoryController gtusc = new GoToUserStoryController();
          gtusc.redirect();

        
          
      }
    
     private static testMethod void test2() {

              
          
         PageReference pageRef = Page.GoToUserStory;
          Test.setCurrentPage(pageRef);

   		pageRef.getParameters().put('12345',null);
          GoToUserStoryController gtusc = new GoToUserStoryController();
          gtusc.redirect();

        
          
      }

}