public with sharing class PortalUserMessageTriggerHandler {

    public static void handleBeforeInsert(List<Portal_User_Message__c> portalUserMessages){
        List<Portal_User_Message__c> portalUserMessagesToValidate = new List<Portal_User_Message__c>();
        for(Portal_User_Message__c portalUserMessage:portalUserMessages){
            if(portalUserMessage.Status__c == 'Active' && portalUserMessage.Message_Type__c == 'Modal'){
                portalUserMessagesToValidate.add(portalUserMessage);
            }
        }
        PortalUserMessageValidation.validateExistingActiveModalWithSameRegion(portalUserMessagesToValidate);
    }

    public static void handleBeforeUpdate(Map<Id,Portal_User_Message__c> oldPortalUserMessageMap, Map<Id,Portal_User_Message__c> newPortalUserMessageMap){
        List<Portal_User_Message__c> portalUserMessagesToValidate = new List<Portal_User_Message__c>();
        for(Id portalUserMessageId:oldPortalUserMessageMap.keySet()){
            Portal_User_Message__c oldMessage = oldPortalUserMessageMap.get(portalUserMessageId);
            Portal_User_Message__c newMessage = newPortalUserMessageMap.get(portalUserMessageId);
            if(newMessage.Status__c == 'Active' && newMessage.Message_Type__c == 'Modal' && (
                (newMessage.Status__c == 'Active' && oldMessage.Status__c != 'Active') || 
                (newMessage.Start_time__c != oldMessage.Start_time__c ) ||
                (newMessage.End_time__c != oldMessage.End_time__c ) ||
                (newMessage.Applies_to_User_Region__c != oldMessage.Applies_to_User_Region__c ) ||
                (newMessage.Message_Type__c == 'Modal' && oldMessage.Message_Type__c != 'Modal' ))){
                    portalUserMessagesToValidate.add(newMessage);
                }
            }
        PortalUserMessageValidation.validateExistingActiveModalWithSameRegion(portalUserMessagesToValidate);
    }

    
}