@isTest
private class MySurveyControllerTest {
    @TestSetup
    static void makeData(){
        ArdiraSurvey__Survey__c sv1 = new ArdiraSurvey__Survey__c(Name='Test Survey 007');
        insert sv1;

        NPS_Surveys_Replies__c csat1 = new NPS_Surveys_Replies__c(Name='Test Survey RPL ' + System.now(),
                RecordTypeId=ApexUtil.getRecordTypeByName('NPS_Surveys_Replies__c','CSAT_Survey').Id,
                User__c=UserInfo.getUserId() 
                // Product__c='Coupon',   //so it will not match the flow to find the SurveyId. We dont need to test the flow matching here 
                // Product_Sub_Flow__c='Coupon Seller Negotiation' //so it will not match the flow to find the SurveyId. We dont need to test the flow matching here
            );

        insert csat1;	

        ArdiraSurvey__Survey_Result__c sr1 = new ArdiraSurvey__Survey_Result__c(
            ArdiraSurvey__Assigned_To_User__c=UserInfo.getUserId(),  
            ArdiraSurvey__Assignee_Type__c='User',
            ArdiraSurvey__Status__c='Assigned/Dispatched',
            ArdiraSurvey__Survey__c=sv1.Id, 
            NPS_Surveys_Replies__c=csat1.Id 
        );
        insert sr1;
    }

    @isTest
    static void testApexGetMySurveys()
    {
        Test.startTest();
            Map<String,Object> result1 = MySurveyController.apexGetMySurveys('','');
            System.assertEquals(1, ((List<SObject>)result1.get('listCSAT')).size(),'1 csat survey should be returned');

            List<ArdiraSurvey__Survey_Result__c> listCSAT = [Select Id,ArdiraSurvey__Logical_Id__c FROM ArdiraSurvey__Survey_Result__c Limit 1];
            result1 = MySurveyController.apexGetMySurveys(listCSAT[0].ArdiraSurvey__Logical_Id__c,'');
            System.assertEquals(1, ((List<SObject>)result1.get('listCSAT')).size(),'1 csat survey should be returned');

            result1 = MySurveyController.apexGetMySurveys('','Assigned/Dispatched');
            System.assertEquals(1, ((List<SObject>)result1.get('listCSAT')).size(),'1 csat survey should be returned');

        Test.stopTest();
    }
}