@isTest
public with sharing class PortalUserMessageValidationTest {
    

    @TestSetup
    static void makeData(){
        Portal_User_Message__c message2 = new Portal_User_Message__c(Start_time__c = Date.today(), End_time__c=Date.today().addDays(7), Status__c='Active', Content__c='123',
                            Message_Type__c = 'Modal', Type__c='Broadcast', Applies_to_User_Region__c='NA');
        Portal_User_Message__c message1 = new Portal_User_Message__c(Start_time__c = Date.today().addDays(-7), End_time__c=Date.today().addDays(7), Status__c='Active', Content__c='123',
                            Message_Type__c = 'Global banner', Type__c='Broadcast', Applies_to_User_Region__c='NA');
        insert new List<Portal_User_Message__c>{message1,message2};
    }
    @isTest
    static void testPartialOverlap(){

        try{
            Portal_User_Message__c message = new Portal_User_Message__c(Start_time__c = Date.today().addDays(3), End_time__c=Date.today().addDays(8), Status__c='Active', Content__c='123',
                            Message_Type__c = 'Modal', Type__c='Broadcast', Applies_to_User_Region__c='NA');
            insert message;
        }
        catch(DmlException e){
            System.assert(e.getMessage().contains(System.label.object_user_validation_message));
        }
    }
    @isTest
    static void testCompleteOverlap(){

        try{
            Portal_User_Message__c message = new Portal_User_Message__c(Start_time__c = Date.today().addDays(-1), End_time__c=Date.today().addDays(8), Status__c='Active', Content__c='123',
                            Message_Type__c = 'Modal', Type__c='Broadcast', Applies_to_User_Region__c='NA');
            insert message;
        }
        catch(DmlException e){
            System.assert(e.getMessage().contains(System.label.object_user_validation_message));
        }
    }
    @isTest
    static void testInsideOverlap(){

        try{
            Portal_User_Message__c message = new Portal_User_Message__c(Start_time__c = Date.today().addDays(2), End_time__c=Date.today().addDays(5), Status__c='Active', Content__c='123',
            Message_Type__c = 'Modal', Type__c='Broadcast', Applies_to_User_Region__c='NA');
            insert message;
        }
        catch(DmlException e){
            System.assert(e.getMessage().contains(System.label.object_user_validation_message));
        }
        
    }

    @isTest
    static void test2ActiveModals(){
        Portal_User_Message__c secondModal = new Portal_User_Message__c(Start_time__c = Date.today().addDays(-14), End_time__c=Date.today().addDays(-7), Status__c='Active', Content__c='123',
                            Message_Type__c = 'Modal', Type__c='Broadcast', Applies_to_User_Region__c='NA');
        insert secondModal;

        
        Portal_User_Message__c message = new Portal_User_Message__c(Start_time__c = Date.today().addDays(-6), End_time__c=Date.today().addDays(-2), Status__c='Active', Content__c='123',
        Message_Type__c = 'Modal', Type__c='Broadcast', Applies_to_User_Region__c='NA');
        insert message;
        
        
        
    }

    @isTest
    static void testUpdateModal(){
        Portal_User_Message__c secondModal = new Portal_User_Message__c(Start_time__c = Date.today().addDays(-14), End_time__c=Date.today().addDays(-7), Status__c='Active', Content__c='123',
                            Message_Type__c = 'Modal', Type__c='Broadcast', Applies_to_User_Region__c='NA');
        insert secondModal;

        
        Portal_User_Message__c message = new Portal_User_Message__c(Start_time__c = Date.today().addDays(-6), End_time__c=Date.today().addDays(-2), Status__c='Active', Content__c='123',
        Message_Type__c = 'Modal', Type__c='Broadcast', Applies_to_User_Region__c='NA');
        insert message;

        try{
            message.End_time__c = Date.today().addDays(7);
            update message;
        }
        catch(DmlException e){
            System.assert(e.getMessage().contains(System.label.object_user_validation_message));
        }
        
        
        
    }

    
}