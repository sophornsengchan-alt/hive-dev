/*********************************************************************************************************************************
@ Class:         CustomChatterControllerTest
@ Version:       1.0
@ Author:        Broseth.KATOR (broseth.kator@skyvva.con)
@ Purpose:       To Test Post Message to FeedItem as Chatter Feed
@				Controller for LWC: CustomChatter
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25/July/2021 / Broseth.KATOR (broseth.kator@skyvva.con) / Created the class.
*********************************************************************************************************************************/


@isTest	
private class CustomChatterControllerTest {

    @testSetup 
    static void setup() {
		CustomChatterController.fetchUserInfo();
        Id currentUserId = UserInfo.getUserId();
        String titleValue = 'Post From eBay Seller Portal Site.';
        String bodyValue = 'Test';
        FeedItem postMessage = new FeedItem();
        postMessage.ParentId = currentUserId;
        postMessage.Title = titleValue;
        postMessage.Body = bodyValue;

        //insert postMessage;
    
    }
    
    static testMethod void testDoPostMessage() {
        Id currentUserId = UserInfo.getUserId();
        String titleValue = 'Post From eBay Seller Portal Site.';
        String bodyValue = 'Test';
        FeedItem postMessage = new FeedItem();
        postMessage.ParentId = currentUserId;
        postMessage.Title = titleValue;
        postMessage.Body = bodyValue;
        
        CustomChatterController.doPosting(postMessage);
        
        List<FeedItem> resultFeed = [SELECT Id From FeedItem];
        System.assertEquals(resultFeed.size(), 1);
        
    }

    static testMethod void testGetPostedMessage() {
        String currentRecordId = 'Post From eBay Seller Portal Site.';
        CustomChatterController.getChatterPost(currentRecordId);
    }

    static testMethod void testDoPostMessageFail() {
        Id currentUserId = UserInfo.getUserId();
        String titleValue = 'Post From eBay Seller Portal Site.';
        String bodyValue = 'Test';
        FeedItem postMessage = new FeedItem();
        postMessage.ParentId = currentUserId;
        postMessage.Title = titleValue;
        postMessage.Body = bodyValue;
        postMessage.Type = 'Test Error';
        
        CustomChatterController.doPosting(postMessage);
        
        List<FeedItem> resultFeed = [SELECT Id From FeedItem];
        System.assertEquals(resultFeed.size(), 0);
        
    }
    
}