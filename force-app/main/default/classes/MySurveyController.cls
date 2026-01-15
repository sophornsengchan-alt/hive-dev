/*********************************************************************************************************************************
@ Class:          MySurveyController
@ Version:        1.0
@ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0014928 - Introduce new User CSAT Survey - Email Notification and My Assigned Task
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.03.2024 / vadhanak voun / Created the class.
@				   
*********************************************************************************************************************************/
public with sharing class MySurveyController {
    final static String RT_CSAT = ApexUtil.getRecordTypeByName('NPS_Surveys_Replies__c','CSAT_Survey').Id;
    final static String SOQL_SURVEY = 'SELECT %fields% FROM ArdiraSurvey__Survey_Result__c %where% Order By CreatedDate DESC'; 
    final static Set<String> STATUS_DEFUALT = new Set<String>(System.Label.DEAFAULT_SURVEY_STATUS.split(','));//{'In Progress','Assigned/Dispatched'};
    
    final static Map<String,String> MAP_FIELD_TYPES = new Map<String,String>{
        'STRING'=>'string',
        'PICKLIST'=>'string',
        'DATE'=>'date-local',
        'PERCENT'=>'percent'
    };


    /*****************************************************************************************************************************
    @ Method:       apexGetMySurveys
    @ Author:       vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      US-0014928 - Introduce new User CSAT Survey - Email Notification and My Assigned Task 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	String surveyId: logical id (ArdiraSurvey__Logical_Id__c)  or empty for all (respect sharing)
    @               String orStatus: Status of the survey. Specific Ids or specific status or empty for all
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.03.2024 / vadhanak voun  / Created the method.
    @*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexGetMySurveys(String surveyId,String orStatus)
    {
        surveyId = String.escapeSingleQuotes(surveyId);
        orStatus = String.escapeSingleQuotes(orStatus);

        Map<String,Object> mapResult = new Map<String,Object>();
        

        Set<String> setFields = new Set<String>{'Id','ArdiraSurvey__Response_URL__c'};
        Map<String,String> mapField = new Map<String,String>();
        List<String> listFIelds = new List<String>();
        for(Schema.FieldSetMember f: SObjectType.ArdiraSurvey__Survey_Result__c.FieldSets.My_Assigned_Survey_Fields_Custom.getFields())
        {
            // listFIelds.add(f.getFieldPath());
            setFields.add(f.getFieldPath());
            mapField.put(f.getFieldPath(),f.getLabel());
        }

        // setFields.addAll(listFIelds);
        String soqlFinal = SOQL_SURVEY.replace('%fields%',String.join(new List<String>(setFields),','));
        String sFilter = '';
        if(String.isBlank(surveyId) && String.isBlank(orStatus))
        {
            sFilter = 'WHERE NPS_Surveys_Replies__r.RecordTypeId=:RT_CSAT AND ArdiraSurvey__Assigned_To_User__c =:uId AND ArdiraSurvey__Status__c IN:STATUS_DEFUALT';

        }else if(!String.isBlank(surveyId))
        {
            sFilter = 'WHERE ArdiraSurvey__Logical_Id__c =:surveyId';

        }else if(!String.isBlank(orStatus))
        {
            sFilter = 'WHERE NPS_Surveys_Replies__r.RecordTypeId=:RT_CSAT AND ArdiraSurvey__Assigned_To_User__c =:uId AND ArdiraSurvey__Status__c =:orStatus';
        }        

        soqlFinal = soqlFinal.replace('%where%',sFilter);
        
        List<SObject> listCSAT = ApexSafe.query().doQuery(soqlFinal,new Map<String, Object>{'uId'=> UserInfo.getUserId(),'orStatus'=>orStatus,'surveyId'=>surveyId,'STATUS_DEFUALT'=>STATUS_DEFUALT,'RT_CSAT'=>RT_CSAT});

        List<Object> listFields2 = ApexUtil.getFieldSet('ArdiraSurvey__Survey_Result__c', 'My_Assigned_Survey_Fields_Custom',true);

        mapResult.put('listCSAT',listCSAT);
        mapResult.put('MAP_FIELD_TYPES',MAP_FIELD_TYPES);
        mapResult.put('listFields',listFields2);

        return mapResult;
    }
}