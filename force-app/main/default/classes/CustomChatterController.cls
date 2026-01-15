/*********************************************************************************************************************************
@ Class:         CustomChatterController
@ Version:       1.0
@ Author:        Broseth.KATOR (broseth.kator@skyvva.con)
@ Purpose:       Post Message to FeedItem as Chatter Feed
@				Controller for lwc: CustomChatter
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25/July/2021 / Broseth.KATOR (broseth.kator@skyvva.con) / Created the class.
*********************************************************************************************************************************/

public without sharing class CustomChatterController {

    @AuraEnabled 
    public static user fetchUserInfo(){
     // query current user information  
      User currUser = [SELECT Id, Username, ContactId, Contact.FirstName, FirstName, LastName, IsPortalEnabled, PostChatterPortal__c, UserType
                    FROM User WHERE Id =: userInfo.getUserId()];
        return currUser;
    }

    @AuraEnabled
    public static Object doPosting(FeedItem postMessage) {
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

    @AuraEnabled
    public static List<FeedItem> getChatterPost(String whereCondi) {
        List<FeedItem> lstFeedItem=[SELECT Id, Body, Type, ParentId, CreatedDate, Title FROM FeedItem WHERE Type = 'TextPost' AND Title LIKE: whereCondi ORDER BY CreatedDate DESC LIMIT 500];
        return lstFeedItem;
    }

}