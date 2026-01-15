@isTest
private class HiveProjectTriggerHandlerTest {

    static testMethod void testValidateCloseProjectOpenUS() {

        //create project
        Hive_Project__c p = new Hive_Project__c(name='Testint project',Status__c='Draft');
        insert p;

        //Create copado Project
        copado__Project__c cp = new copado__Project__c(name='Project test 1');
        insert cp;

        copado__Org__c credential = new copado__Org__c(Name = 'Testing Credential');// Sambath Seng 29.09.2022 US-0012472 - Fix failing test class HiveProjectTriggerHandlerTest
        insert credential;

        // Create User Story
        copado__User_Story__c cus = new copado__User_Story__c(copado__User_Story_Title__c='Test User Story');
        cus.copado__Project__c=cp.id;
        cus.HIVE_Product__c='Advertising';
        cus.Component__c='Salesforce';
        cus.copado__Status__c='Draft';
        cus.BU_Requester__c=UserInfo.getUserId();
        cus.Hive_Project__c=p.ID;
        cus.copado__Org_Credential__c = credential.Id;// Sambath Seng 29.09.2022 US-0012472 - Fix failing test class HiveProjectTriggerHandlerTest
        insert cus;

        Test.startTest();
        p.Status__c='Completed';
        try{
            update p;
        }catch(Exception e){
            System.assert(e.getMessage().indexOf(HiveProjectTriggerHandler.ERROR_MESSAGE)>0, 'Must validate number of user stories not closed');
        }

    }


    static testMethod void testValidateCloseProjectOpenFR() {

        //create project
        Hive_Project__c p2 = new Hive_Project__c(name='Testint project',Status__c ='Under Review (Requirement Clarification)');// Sambath Seng 29.09.2022 US-0012472 - Fix failing test class HiveProjectTriggerHandlerTest
        insert p2;

        // Create Feature Request    
        Requirement_Request__c rr = new Requirement_Request__c (name='RR title');
        rr.Hive_Project__c=p2.id;
        rr.Status__c='New';
        rr.Region__c='IT'; 
        insert rr;

        Test.startTest();
        p2.Status__c='Completed';
        try{
            update p2;
        }catch(Exception e){
            System.assert(e.getMessage().indexOf(HiveProjectTriggerHandler.ERROR_MESSAGE)>0, 'Must validate number of user stories not closed');
        }

    }

}