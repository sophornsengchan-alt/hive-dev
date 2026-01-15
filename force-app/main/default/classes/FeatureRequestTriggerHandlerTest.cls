@isTest
private class FeatureRequestTriggerHandlerTest {

    @testSetup
    static void setup(){
        
        EBH_TestDataFactory.setUpCustomSettings();
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;

    	//create project
        Hive_Project__c hp1 = new Hive_Project__c(name='Testing project1',Status__c='Development');
        Hive_Project__c hp2 = new Hive_Project__c(name='Testing project2',Status__c='Development');
        insert new List<Hive_Project__c>{hp1,hp2};

        // Create Feature Request
        Requirement_Request__c rr1 = new Requirement_Request__c (name='FeatureRequest title1');
        rr1.Hive_Project__c=hp1.id;
        rr1.Status__c='New';
        rr1.Region__c='IT';
        rr1.Complexity_Estimation_story_points__c = 3;

        Requirement_Request__c rr2 = new Requirement_Request__c (name='FeatureRequest title2');
        rr2.Hive_Project__c=hp1.id;
        rr2.Status__c='New';
        rr2.Region__c='IT';
        rr2.Complexity_Estimation_story_points__c = 2;

        insert new List<Requirement_Request__c>{rr1,rr2};

        
    }

    @isTest 
    static void testcalculateComplexityEstimation() {
        Requirement_Request__c rr = [SELECT Id,Complexity_Estimation_story_points__c,Hive_Project__c,Hive_Project__r.ComplexityEstimationDevStoryPoints__c FROM Requirement_Request__c WHERE Name = 'FeatureRequest title1' limit 1];
        Hive_Project__c hp = [SELECT Id,ComplexityEstimationDevStoryPoints__c FROM Hive_Project__c WHERE Name ='Testing project2' limit 1];
        Requirement_Request__c rr3 = new Requirement_Request__c (name='FeatureRequest title3');
        rr3.Hive_Project__c=hp.id;
        rr3.Status__c='New';
        rr3.Region__c='IT';
        rr3.Complexity_Estimation_story_points__c = 3;
        
        Test.startTest();

            insert rr3;
            
            rr.Complexity_Estimation_story_points__c = 2;
            update rr;

        Test.stopTest();
        Set<Id> Ids = new Set<Id>{hp.Id,rr.Hive_Project__c};
        List<Hive_Project__c> projects = [SELECT Id,ComplexityEstimationDevStoryPoints__c FROM Hive_Project__c WHERE Id IN: Ids];
        System.debug('p1='+projects[0].ComplexityEstimationDevStoryPoints__c +' p2='+projects[1].ComplexityEstimationDevStoryPoints__c);
        System.assertEquals(4,projects[0].ComplexityEstimationDevStoryPoints__c);
		System.assertEquals(3,projects[1].ComplexityEstimationDevStoryPoints__c);

    }
    @isTest 
    static void testresetComplexityEstimation() {
        Requirement_Request__c rr = [SELECT Id,Complexity_Estimation_story_points__c,Hive_Project__c,Hive_Project__r.ComplexityEstimationDevStoryPoints__c FROM Requirement_Request__c WHERE name='FeatureRequest title2' limit 1];

        Test.startTest();
            delete rr;
        Test.stopTest();
        Hive_Project__c project = [SELECT Id,ComplexityEstimationDevStoryPoints__c FROM Hive_Project__c WHERE Name = 'Testing project1' limit 1];
        System.assertEquals(3,project.ComplexityEstimationDevStoryPoints__c);
    }

}