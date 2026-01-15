/*********************************************************************************************************************************
@ Class:         CreatePortalUserMessageController
@ Version:       1.0
@ Author:        Broseth.KATOR (broseth.kator@skyvva.con)
@ Purpose:       Create Message for Portal User Message 
@				 Controller for lwc: lwcCreatePortalUserMessage and lwcViewPortalUserMessage
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06/Sep/2021 / Broseth.KATOR (broseth.kator@skyvva.con) / Created the class.
@                 03.06.2024  / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
*********************************************************************************************************************************/

public with sharing class CreatePortalUserMessageController {

    @AuraEnabled 
    public static user fetchUserInfo(){
     // query current user information  
      User currUser = [SELECT Id, Username, ContactId, Contact.FirstName, FirstName, LastName, UserType, SPMainDomain__c //MN-03062024-US-0015298: Added SPMainDomain__c
                    FROM User WHERE Id =: userInfo.getUserId()];
        return currUser;
    }

    @AuraEnabled
    public static Object doPosting(Portal_User_Message__c postMessage) {
        Map<String, Object> mResult = new Map<String, object>();
        mResult.put('status','error');
        try {
            insert postMessage; 
            mResult.put('postMessage',postMessage);
            mResult.put('message', 'The message post successfully.');
            mResult.put('status','success');
        } catch (Exception e) {
            mResult.put('message', 'Error:'+ e.getMessage());
        }
        return mResult;
    }

    // @AuraEnabled
    // public static List<Portal_User_Message__c> getPortalUserMessage(Integer limitRec, String profileSetting) {
    //     List<Portal_User_Message__c> lstPortal_User_Message=[SELECT Id, Name, Type__c, Start_time__c, End_time__c, Content__c, Status__c, Applies_to_User_Region__c, Message_Type__c FROM Portal_User_Message__c WHERE Message_Type__c = 'Global banner' AND DAY_ONLY(Start_time__c )<=:Date.today() AND DAY_ONLY(End_time__c )>=:Date.today() AND Applies_to_User_Region__c LIKE:profileSetting AND Status__c = 'Active' ORDER BY CreatedDate DESC LIMIT: limitRec];
    //     return lstPortal_User_Message;
    // }

    //MN-03062024-US-0015298: Mapping SP Main Domain to Applies_to_User_Region__c. KEY:SP Main Domain => Value:Region
    private static Map<String, String> mSPDomain2Region = new Map<String, String> {
        SEP_Helper.SEP_Domain_NA => 'NA',
        SEP_Helper.SEP_Domain_DE => 'DE',
        SEP_Helper.SEP_Domain_AU => 'AU',
        SEP_Helper.SEP_Domain_FR => 'FR',
        SEP_Helper.SEP_Domain_IT => 'IT',
        SEP_Helper.SEP_Domain_UK => 'UK'
    };

    @testvisible
    private static String domain; //MN-03062024-US-0015298

    @AuraEnabled
    public static List<Portal_User_Message_Item__c> getPortalUserMessage(Integer limitRec, String profileSetting) {

        //START--MN-03062024-US-0015298: Get Region from SP Main Domain
        List<Portal_User_Message_Item__c> lstPortal_User_Message = new List<Portal_User_Message_Item__c>();
        User user = CreatePortalUserMessageController.fetchUserInfo();

        if (String.isBlank(domain)) domain = user.SPMainDomain__c;

        if (mSPDomain2Region.containsKey(domain)) {
            String region = mSPDomain2Region.get(user.SPMainDomain__c);
            lstPortal_User_Message=[SELECT Id, Name, Type__c, Start_time__c, End_time__c, Content__c, Status__c, Portal_User_Message__c, Portal_User_Message__r.Applies_to_User_Region__c, Message_Type__c FROM Portal_User_Message_Item__c WHERE Message_Type__c = 'Global banner' AND DAY_ONLY(Start_time__c)<=:Date.today() AND DAY_ONLY(End_time__c)>=:Date.today() AND Portal_User_Message__r.Applies_to_User_Region__c =:region AND Status__c = 'Active' ORDER BY CreatedDate DESC LIMIT: limitRec];
        }
        //--END

        //MN-03062024-US-0015298: Commented out the below code
        //List<Portal_User_Message_Item__c> lstPortal_User_Message=[SELECT Id, Name, Type__c, Start_time__c, End_time__c, Content__c, Status__c, Portal_User_Message__c, Portal_User_Message__r.Applies_to_User_Region__c, Message_Type__c FROM Portal_User_Message_Item__c WHERE Message_Type__c = 'Global banner' AND DAY_ONLY(Start_time__c )<=:Date.today() AND DAY_ONLY(End_time__c )>=:Date.today() AND Portal_User_Message__r.Applies_to_User_Region__c LIKE:profileSetting AND Status__c = 'Active' ORDER BY CreatedDate DESC LIMIT: limitRec];
        
        return lstPortal_User_Message;
    }

    @AuraEnabled
    public static List<Portal_User_Message__c> getPortalUserMessageInBox(String statusValue) {
        List<Portal_User_Message__c> lstPortal_User_Message=[SELECT Id, Name, Type__c, Start_time__c, End_time__c, Content__c, Status__c, Applies_to_User_Region__c, Message_Type__c FROM Portal_User_Message__c WHERE Message_Type__c = 'Inbox Only' AND Status__c LIKE:statusValue ORDER BY CreatedDate DESC LIMIT 500];
        return lstPortal_User_Message;
    }

    @AuraEnabled
    public static List<Portal_User_Message_Item__c> getPortalUserMessageModal() {
        Id contactId = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId; 
        List<Portal_User_Message_Item__c> lstPortal_User_Message=[SELECT Id, Name, Read__c, Message_Type__c, Content__c FROM Portal_User_Message_Item__c WHERE Read__c = FALSE AND Message_Type__c = 'Modal' AND DAY_ONLY(Start_time__c )<=:Date.today() AND DAY_ONLY(End_time__c )>=:Date.today() AND Status__c = 'Active' AND Contact__c = :contactId ORDER BY CreatedDate DESC LIMIT 1];
        return lstPortal_User_Message;
    }


    @AuraEnabled(cacheable=false)   
    public static Boolean initAgreementTerms() {     

        try {

            Boolean result = false;
            List<Portal_User_Message_Item__c> lstPortal_User_Message=[SELECT Id, Read__c, Message_Type__c FROM Portal_User_Message_Item__c WHERE Message_Type__c = 'Modal' ORDER BY CreatedDate DESC LIMIT 1];
            if (!lstPortal_User_Message.isEmpty()) {
                result = lstPortal_User_Message[0].Read__c; 
            }

         return result;
            
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled(cacheable=false)   
    public static void updateModalRead(String portalUserMessageId) {
        //System.debug('portalUserMessageId: '+portalUserMessageId);
        Portal_User_Message_Item__c portalUserMessage = [SELECT Id FROM Portal_User_Message_Item__c WHERE Id =:portalUserMessageId LIMIT 1];
        portalUserMessage.Read__c = true;
        update portalUserMessage;
    }

    @AuraEnabled(cacheable=false)   
    public static String acceptedAgreement() {     

        String message = 'success';
        try {         
            List<Portal_User_Message_Item__c> lstPortal_User_Message=[SELECT Id, Read__c, Message_Type__c FROM Portal_User_Message_Item__c WHERE Message_Type__c = 'Modal' ORDER BY CreatedDate DESC LIMIT 1];

            if (!lstPortal_User_Message.isEmpty() && String.isNotBlank(lstPortal_User_Message[0].Id)) {                  
                
             if(!Test.isRunningTest()) update new Portal_User_Message_Item__c(Id=lstPortal_User_Message[0].Id, Read__c=true);
          
            }
            
        } catch (Exception e) { message = e.getMessage(); } 

        return message; 


    }

    @InvocableMethod(label='Another Active Modal message record is live, please deactivate before creating a new one' description='')
    public static void showErrorMessage(List< Portal_User_Message__c> potalmessage) {
        
        //parse inputs and variables

        //System.debug('>>>potalmessage'+potalmessage);
        for(Portal_User_Message__c poc: potalmessage){
            poc.addError(Label.object_user_validation_message,'',true);
        }
        
    }
}