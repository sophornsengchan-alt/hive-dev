@isTest
private class WorkManagerHIVETest {

    @TestSetup
    static void makeData(){
        List<copado__Team__c> listTeams = new List<copado__Team__c>{
            new copado__Team__c(Name='Honeycomb'),
            new copado__Team__c(Name='Nectar'),
            new copado__Team__c(Name='Hive Force')
        };
       insert listTeams;

        copado__Environment__c env = new copado__Environment__c(Name='DEV');
        insert env;

        copado__Org__c org1 = new copado__Org__c(Name = 'DEV',copado__Environment__c=env.Id);
        insert org1;


        List<copado__Sprint__c> listSprint = new List<copado__Sprint__c>{    
            new copado__Sprint__c(
                Name = 'Sprint Now',
                copado__Status__c = 'In progress',
                Active_Sprint__c = true,
                copado__Start_Date__c = Date.today().addDays(-10),
                copado__End_Date__c = Date.today().addDays(10),
                copado__Team__c = listTeams[0].Id
            ),
            new copado__Sprint__c(
                Name = 'Sprint Next',
                copado__Status__c = 'Planned',
                copado__Start_Date__c = Date.today().addDays(10),
                copado__End_Date__c = Date.today().addDays(20),
                copado__Team__c = listTeams[0].Id
            )
        };
        insert listSprint;

        List<copado__User_Story__c> listStory = new List<copado__User_Story__c>{
            new copado__User_Story__c(
                copado__User_Story_Title__c = 'Test User Story',
                copado__Status__c = 'Draft',          
                Component__c = 'Domo',
                copado__Team__c = listTeams[0].Id,
                copado__Sprint__c = listSprint[0].Id
            )
        };
        insert listStory;
      


    }

    @isTest
    static void testWorkManagerInit() {
        // Create test data
      

        // Call the method being tested
        Test.startTest();
            String sprintIdNow = [Select Id From copado__Sprint__c Where Name='Sprint Now'].Id;
            String sprintIdNext = [Select Id From copado__Sprint__c Where Name='Sprint Next'].Id;

            Map<String, Object> result = WorkManagerHIVE.workManagerInit();
            copado__Sprint__c sNow = (copado__Sprint__c)result.get('curSprint');
            System.assertEquals(sprintIdNow, sNow.Id,'curent sprint is Sprint Now');

            String jsonPageInfo = '{"mainFilter1":"copado__Team__r.Name=\'Honeycomb\'","mainFilter2":"","mainFilter3":"","pName":"Honeycomb_Work_Manager","pLabel":"Honeycomb Work Manager","panelRowCount":"200","additionalQuery":""}';
            String jsonPanel = '{"panelName":"Next_Sprint","panelLabel":"Next Sprint","panelFilter":["copado__Sprint__c=:sprintId"],"sortOrder":"copado__Backburner_Rank__c","sortOrderDir":"asc","columns":["Name","copado__User_Story_Title__c","Total_Story_Points__c","HIVE_Products__c","copado__Backburner_Rank__c"]}';
        
            Map<String, Object> result2 = WorkManagerHIVE.getRecordsPanel(jsonPageInfo, jsonPanel, sprintIdNow);
            System.assertEquals(1, result2.get('totalStory') ,' 1 user story for current sprint');

           String jsonString ='{"lastVisitPage":"Honeycomb_Work_Manager"}';

           Map<String, Object> result3 = WorkManagerHIVE.wmSaveSetting(jsonString);
           System.assertEquals('ok', result3.get('status') ,'save setting to current user');

            List<copado__User_Story__c> listUS = [Select Id From copado__User_Story__c Where copado__User_Story_Title__c='Test User Story'];
            
            Map<String, Object> result4 = WorkManagerHIVE.wmMoveStory('update_bburner', null, new List<String>{listUS[0].Id});
            System.assertEquals('ok', result4.get('status') ,'Backburner Rank updated');


            Map<String, Object> result5 = WorkManagerHIVE.wmMoveStory('to_sprint', sprintIdNext, new List<String>{listUS[0].Id});
            System.assertEquals('ok', result5.get('status') ,'User story moved to next sprint');

        Test.stopTest();
    }
}