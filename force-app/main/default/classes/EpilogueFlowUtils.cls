public with sharing class EpilogueFlowUtils {

    /***********************************************************************************************************************************
    @ Method:       insertSurveyResult
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Version:        1.0
    @ Author:         David Herrero <dherero@ebay.com>
    @ Purpose:          Update a survey result object 
    @ Return:         void
    ----------------------------------------------------------------------------------------------------------------------------------
    ***********************************************************************************************************************************/

    @InvocableMethod(label='updateSurveyAsynch' description='Update an object using future method')
    public static void updateSurveyResult(List<ArdiraSurvey__Survey_Result__c> sr){
        String serializedObject = Json.serializePretty(sr);
        updateFuture(serializedObject);
    }
    @future
    public static void updateFuture (String sr){
        List<ArdiraSurvey__Survey_Result__c> asr = (List<ArdiraSurvey__Survey_Result__c>)JSON.deserialize(sr,List<ArdiraSurvey__Survey_Result__c>.class);
        update asr;
    }
}