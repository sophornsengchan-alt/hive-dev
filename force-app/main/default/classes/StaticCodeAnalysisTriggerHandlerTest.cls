@isTest
private class StaticCodeAnalysisTriggerHandlerTest {
        
    @TestSetup
    static void makeData(){
        EBH_TestDataFactory.setUpCustomSettings();

        copado__Org__c credential = new copado__Org__c();
        credential.copado__Default_Credential__c=true;
        credential.name='DEV';

        insert credential;

        copado__Environment__c environment = new copado__Environment__c();
        environment.name='DEV';
        environment.copado__Minimum_Apex_Test_Coverage__c=75;
        environment.copado__Promotion_Default_Credential__c='All Promotions';
        environment.copado__Type__c='Sandbox';
        environment.copado__Platform__c='Salesforce';
        environment.copado__Org_ID__c=credential.ID;

        insert environment;

        credential.copado__Environment__c=environment.ID;
        update credential;

        Id rtUSId = ApexUtil.getRecordTypeByName('copado__User_Story__c','User_Story').Id;
        copado__User_Story__c cus = new copado__User_Story__c(copado__Apex_Code_Coverage__c=99,
            copado__Has_Apex_Code__c=true,
            copado__User_Story_Title__c='US007',
            Description__c='test',
            copado__Technical_Specifications__c='test',
            BA_Priority__c='Medium',
            Business_Value_Points__c=300,
            RecordTypeId=rtUSId,
            copado__Org_Credential__c = credential.Id,
            copado__Environment__c = environment.Id);         
       
        insert cus;
 
    }

    @IsTest
    static void testAssignCSAScore(){
        
        Test.startTest();
            copado__User_Story__c cus = [Select Id From copado__User_Story__c where copado__User_Story_Title__c='US007'];
            try {
                cus.copado__Promote_Change__c = true;
                cus.Code_has_been_reviewed__c = true;
                update cus;
            }catch (Exception ex) {
                System.assert(ex.getMessage().contains('Run Static Code Analysis'), 'validation rule name: Validate_SCA: '+ ex.getMessage());
            }
            
            
            copado__Static_Code_Analysis_Result__c result1 = new copado__Static_Code_Analysis_Result__c(copado__User_Story__c=cus.Id);
            insert result1;

            cus = [Select Id,Static_Code_Analysis_score__c From copado__User_Story__c where copado__User_Story_Title__c='US007'];
            System.assertEquals(0, cus.Static_Code_Analysis_score__c,'Zero on insert: '+cus.Static_Code_Analysis_score__c);

            RecordType rtPMD = ApexUtil.getRecordTypeByName('copado__Static_Code_Analysis_Violation__c','PMD');
            copado__Static_Code_Analysis_Violation__c vio1 = new copado__Static_Code_Analysis_Violation__c(copado__Priority__c=1,RecordTypeId=rtPMD.Id,copado__Static_Code_Analysis_Result__c=result1.Id);
            copado__Static_Code_Analysis_Violation__c vio2 = new copado__Static_Code_Analysis_Violation__c(copado__Priority__c=1,RecordTypeId=rtPMD.Id,copado__Static_Code_Analysis_Result__c=result1.Id);

            insert new List<copado__Static_Code_Analysis_Violation__c>{vio1,vio2};

             cus = [Select Id,Static_Code_Analysis_score__c From copado__User_Story__c where copado__User_Story_Title__c='US007'];
             
             System.assertEquals(10, cus.Static_Code_Analysis_score__c,'2 violation (prio1) = 10p: '+cus.Static_Code_Analysis_score__c);

             cus.copado__Promote_Change__c = true;
             cus.Code_has_been_reviewed__c = true;
                
             update cus;

             //NK:10/10/2024: US-0016024
             //From Credential
             copado__Org__c credential = [Select Id From copado__Org__c where name = 'DEV'];
             copado__Static_Code_Analysis_Result__c result2 = new copado__Static_Code_Analysis_Result__c(copado__Org_Credential__c= credential.Id);
             insert result2;
             
        Test.stopTest();
        
    }
}