/*********************************************************************************************************************************
@ Class:          WelcomeEmailControllerTest
@ Version:        1.0
@ Author:         sovantheany.dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Test class for WelcomeEmailController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.03.2022 / sovantheany.dim / Created the  class.
*********************************************************************************************************************************/
@isTest
private class WelcomeEmailControllerTest {
    @isTest 
    private static void test_method(){
        Account acc = new Account( Name = 'TestAccount', EBH_StoreSubscription__c = 'Anchor');
        insert acc;
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false, FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
        
        /* MN-10062024-US-0015298
        Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'DE - Seller Portal'];
        User user1 = new User(
                                Username = System.now().millisecond() + 'test12345@test.com',
                                ContactId = con.Id,
                                ProfileId = profile1.Id,
                                Alias = 'testU',
                                Email = 'test12345xx@test.com',
                                EmailEncodingKey = 'UTF-8',
                                LastName = 'McTesty',
                                CommunityNickname = 'test12345',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'de_DE',
                                LanguageLocaleKey = 'de'
                                );
        */

        Test.startTest();
        WelcomeEmailController controller = new WelcomeEmailController();
        controller.cont = con;
        List<User> lstUser = controller.users;
        String strDomain = controller.MainDomain;
        String strSellerName = controller.SellerName;
        String strSellerNameFromCurrentUser = controller.sellerNameFromCurrentUser;
        String strUserName = controller.UserNameStr;
        Test.stopTest();
    }
}