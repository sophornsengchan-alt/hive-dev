/*********************************************************************************************************************************
@ Class:         CreatePortalUserMessageControllerTest
@ Version:       1.0
@ Author:        Broseth.KATOR (broseth.kator@skyvva.con)
@ Purpose:       To Test create and view Portal User Message and item
@				Controller for LWC: lwcViewPortalUserMessage, lwcViewPortalUserMessageDatabase
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15/Sep/2021 / Broseth.KATOR (broseth.kator@skyvva.con) / Created the class.
*********************************************************************************************************************************/


@isTest	
private class CreatePortalUserMessageControllerTest {

    @testSetup 
    static void setup() {
        /*
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' Limit 1];  
        User objUser = new User(Alias = 'Bro', 
                                Email = 'bro-seth@example.com', 
                                EmailEncodingKey = 'UTF-8', 
                                LastName = 'Kator',
                                LocaleSidKey = 'en_US', 
                                LanguageLocaleKey='en_US', 
                                ProfileId = objProfile.Id, 
                                TimeZoneSidKey = 'Europe/London', 
                                UserName = 'bro-seth@example.com');
        insert objUser;
        */
        Account acc = new Account(Name='Broseth');
        insert acc;

        Contact cont = new Contact(MailingCountry='USA',
                                        MailingState='TX',MailingCity='Dallas',
                                        FirstName='conFirst',Salutation='Mr.',LastName='conLast',
                                        email='test1@test.com' , AccountId = acc.Id);
        insert cont;

        Portal_User_Message__c postMessage = new Portal_User_Message__c();
        postMessage.Name = 'Test Inbox Only';
        postMessage.Applies_to_User_Region__c = 'NA';
        postMessage.Content__c = 'Test Content Messgae';
        postMessage.Start_time__c = Date.today();
        postMessage.End_time__c = Date.today();
        postMessage.Message_Type__c = 'Inbox Only';
        postMessage.Status__c = 'Active';
        postMessage.Type__c = 'Broadcast';

        //insert postMessage;

        Portal_User_Message__c postMessage2 = new Portal_User_Message__c();
        postMessage2.Name = 'Test Global banner';
        postMessage2.Applies_to_User_Region__c = 'NA';
        postMessage2.Content__c = 'Test Content Messgae Global banner';
        postMessage2.Start_time__c = Date.today();
        postMessage2.End_time__c = Date.today();
        postMessage2.Message_Type__c = 'Global banner';
        postMessage2.Status__c = 'Active';
        postMessage2.Type__c = 'Broadcast';

        //insert postMessage2;

        Portal_User_Message__c postMessage3 = new Portal_User_Message__c();
        postMessage3.Name = 'Test Modal';
        postMessage3.Applies_to_User_Region__c = 'NA';
        postMessage3.Content__c = 'Test Content Messgae Modal';
        postMessage3.Start_time__c = Date.today();
        postMessage3.End_time__c = Date.today();
        postMessage3.Message_Type__c = 'Modal';
        postMessage3.Status__c = 'Active';
        postMessage3.Type__c = 'Broadcast';

        //insert postMessage3;

        insert new List<Portal_User_Message__c> {postMessage, postMessage2, postMessage3};

        // Portal_User_Message_Item__c postMessageItem = new Portal_User_Message_Item__c();
        // postMessageItem.Name = 'Test Title';
        // postMessageItem.Content__c = 'Test Content Messgae';
        // // postMessageItem.Start_time__c = Date.today();
        // // postMessageItem.End_time__c = Date.today();
        // postMessageItem.Message_Type__c = 'Modal';
        // postMessageItem.Status__c = 'Active';
        // postMessageItem.Type__c = 'Broadcast';

        // postMessageItem.Portal_User_Message__c = postMessage.Id;
        // postMessageItem.Contact__c = cont.Id;

        // insert postMessageItem;
    
    }
    
    static testMethod void doTestfetchUserInfo() {
        
        User currUser = CreatePortalUserMessageController.fetchUserInfo();
        
        List<User> resultUser = [SELECT Id FROM User WHERE LastName = 'Kator'];
        Id currentUserId = UserInfo.getUserId();
        // System.assertEquals(currUser.Id, resultUser[0].Id);
        
    }

    static testMethod void testDoPostMessage() {

        Portal_User_Message__c postMessage = new Portal_User_Message__c();
        postMessage.Name = 'Test Title Posting';
        postMessage.Applies_to_User_Region__c = 'NA';
        postMessage.Content__c = 'Test Content Messgae 2';
        postMessage.Start_time__c = Date.today();
        postMessage.End_time__c = Date.today();
        postMessage.Message_Type__c = 'Modal';
        postMessage.Status__c = 'Active';
        postMessage.Type__c = 'Broadcast';
        
        CreatePortalUserMessageController.doPosting(postMessage);
        
        // List<Portal_User_Message__c> lstResult = [SELECT Id, Name From Portal_User_Message__c WHERE Name LIKE 'Test Title Posting'];
        // System.assertEquals(lstResult.size(), 1);
        // System.assertEquals(postMessage.Name, lstResult[0].Name);
        
    }

    static testMethod void testgetPortalUserMessage() {

        Integer limitRec = 1;
        String ProFi = 'Na';

        CreatePortalUserMessageController.domain = SEP_Helper.SEP_Domain_NA; //MN-03062024-US-0015298
        List<Portal_User_Message_Item__c> getRes = CreatePortalUserMessageController.getPortalUserMessage(limitRec, proFi);
        
        // List<Portal_User_Message_Item__c> lstResult = [SELECT Id, Name From Portal_User_Message_Item__c WHERE Message_Type__c = 'Global banner'];
        // system.debug(getRes);
        // System.assertEquals(lstResult.size(), getRes.size());
        // System.assertEquals(getRes[0].Name, lstResult[0].Name);
        
    }

    static testMethod void testgetPortalUserMessageInBox() {

        String statusValue = 'Active';

        List<Portal_User_Message__c> getRes = CreatePortalUserMessageController.getPortalUserMessageInBox(statusValue);
        
        // List<Portal_User_Message__c> lstResult = [SELECT Id, Name From Portal_User_Message__c WHERE Message_Type__c = 'Inbox Only'];
        // system.debug(lstResult);
        // System.assertEquals(lstResult.size(), getRes.size());
        // System.assertEquals(getRes[0].Name, lstResult[0].Name);

        
    }

    static testMethod void testgetPortalUserMessageModal() {

        List<Portal_User_Message_Item__c> getRes = CreatePortalUserMessageController.getPortalUserMessageModal();
        
        // List<Portal_User_Message_Item__c> lstResult = [SELECT Id, Name From Portal_User_Message_Item__c WHERE Message_Type__c = 'Modal'];
        // system.debug(lstResult);
        // System.assertEquals(lstResult.size(), getRes.size());
        // System.assertEquals(getRes[0].Name, lstResult[0].Name);

        
    }

    @isTest
    static void testinitAgreementTerms(){
        Boolean result = CreatePortalUserMessageController.initAgreementTerms();
        System.assert(!result);
    }
    @isTest
    static void testacceptedAgreement(){
        String result = CreatePortalUserMessageController.acceptedAgreement();
        System.assertEquals('success', result);
    }

    @isTest
    static void testupdateModalRead(){
        Portal_User_Message_Item__c messageItem = [SELECT Id FROM Portal_User_Message_Item__c where Read__c = false AND Message_Type__c = 'Modal' LIMIT 1];
        CreatePortalUserMessageController.updateModalRead(messageItem.Id);
        Portal_User_Message_Item__c updatedMessageItem = [SELECT Id, Read__c FROM Portal_User_Message_Item__c where Id = :messageItem.Id];

        System.assertEquals(updatedMessageItem.Read__c, true);
    }

    
}