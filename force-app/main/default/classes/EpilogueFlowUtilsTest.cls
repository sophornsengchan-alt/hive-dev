@isTest
public with sharing class EpilogueFlowUtilsTest {
    

        @IsTest
        static void testUpdateSurveyResults(){
        List<ArdiraSurvey__Survey_Result__c> test = new List<ArdiraSurvey__Survey_Result__c>();
        EpilogueFlowUtils.updateSurveyResult(test);
    
    }
}