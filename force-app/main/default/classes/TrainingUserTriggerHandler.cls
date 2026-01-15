/*********************************************************************************************************************************
@ Class:        TrainingUserTriggerHandler
@ Version:      1.0
@ Author:       Sovanthany.dim (sovantheany.dim@gaea-sys.com)
@ Purpose:      Handler for Training_User__c Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.08.2020 / Sovanthany.dim / Created the Class.
*********************************************************************************************************************************/
public without sharing class TrainingUserTriggerHandler {
/************************************* CONSTANT DEFINITION *************************************************/
    private static String SOQL_TRAINING_USER = 'Select OwnerId, Training_Calendar__c From Training_User__c where Training_Calendar__c IN: setTrainCalendarId OR OwnerId IN: setTrainUserOwnerId';
/************************************ END OF CONSTANT DEFINITION*******************************************/
    
/*****************************************************************************************************************************
    @ Method:   checkDuplicatedUserCreated
    @ Version:  1.0
    @ Author:   Sovanthany.dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  US-0008091 - Training User Bugs
    @ When user click on "Sign Up" button it should create one Training user record. But when user click on "Sign Up" again it should not allow to create a duplicate create by same user
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<Training_User__c> listTrainUser
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.08.2020 / Sovanthany.dim / Created the  Method.
    *****************************************************************************************************************************/
    public static void checkDuplicatedUserCreated(List<Training_User__c> listTrainUser)
    {
        Set<String> setTrainCalendarId = new Set<String>();
        Set<String> setTrainUserOwnerId = new Set<String>();
        for(Training_User__c trainuser : listTrainUser){
            setTrainCalendarId.add(trainuser.Training_Calendar__c);
            setTrainUserOwnerId.add(trainuser.OwnerId);
            
        }
        
        if(setTrainCalendarId.isEmpty() || setTrainUserOwnerId.isEmpty()) return;
        
        Set<String> sExistingTrainUser = new Set<String>();
        for(Training_User__c existTrainUser : Database.query(SOQL_TRAINING_USER)){
            sExistingTrainUser.add(existTrainUser.Training_Calendar__c+'/'+existTrainUser.OwnerId);
        }
        for(Training_User__c trainuser : listTrainUser){
            String key = trainuser.Training_Calendar__c+'/'+trainuser.OwnerId;
            if(sExistingTrainUser.contains(key)){
                trainuser.addError(System.label.Duplicate_Training_User);
            }
        }
    }
}