/*********************************************************************************************************************************
@ Class:        TrainingUserTriggerHandlerTest
@ Version:      1.0
@ Author:       Sovanthany.dim (sovantheany.dim@gaea-sys.com)
@ Purpose:      Test Handler for Training_User__c Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.08.2020 / Sovanthany.dim / Created the Class.
*********************************************************************************************************************************/
@isTest
private class TrainingUserTriggerHandlerTest {
    static testMethod void testCheckDuplicatedUserCreated(){
        try{
            Training_Calendar__c trCalendar = new Training_Calendar__c();
            insert trCalendar;
            Training_User__c trUser = new Training_User__c(Training_Calendar__c = trCalendar.Id);
            insert trUser;
            Test.startTest();
            Training_User__c trUser1 = new Training_User__c(Training_Calendar__c = trCalendar.Id);
            insert trUser1;
            Test.stopTest();
        }catch(Exception e){
            System.assert(e.getMessage().contains(System.label.Duplicate_Training_User),'Error : '+System.label.Duplicate_Training_User);
        }

        
    }
}