public with sharing class PortalUserMessageValidation {

    public static void validateExistingActiveModalWithSameRegion(List<Portal_User_Message__c> portalUserMessages){
        DateTime minStartTime;
        DateTime maxEndTime;
        Set<String> regions = new Set<String>();
        Set<String> ids = new Set<String>();
        for(Portal_User_Message__c portalUserMessage:portalUserMessages){
            if(minStartTime == null || portalUserMessage.Start_time__c < minStartTime){
                minStartTime = portalUserMessage.Start_time__c;
            }
            if(maxEndTime == null || portalUserMessage.End_time__c > maxEndTime){
                maxEndTime = portalUserMessage.End_time__c;
            }
            regions.add(portalUserMessage.Applies_to_User_Region__c);
            ids.add(portalUserMessage.Id);

        }

        List<Portal_User_Message__c> existingModalMessages = [SELECT Id FROM Portal_User_Message__c WHERE Message_Type__c = 'Modal' AND Status__c = 'Active' AND
                        Applies_to_User_Region__c IN :regions AND Id NOT IN :ids AND (
                        (Start_time__c <= :minStartTime AND End_time__c >= :minStartTime) 
                        OR (Start_time__c <= :maxEndTime AND End_time__c >= :maxEndTime)
                        OR (Start_time__c >= :minStartTime AND End_time__c <= :maxEndTime))];

        if(existingModalMessages.size()>0){
            portalUserMessages.get(0).addError(System.label.object_user_validation_message);
        }

    }
}