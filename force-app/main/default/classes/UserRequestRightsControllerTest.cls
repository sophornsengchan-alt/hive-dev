@isTest
private class UserRequestRightsControllerTest {

    @testSetup
    static void setupData()
    {
        Profile p = [select id from Profile where name='Standard Ads User Profile' limit 1];
        User testUser = new User(alias = 'TestApro', email='testaccelq@ebay.com', 
                            emailencodingkey='UTF-8', lastname='testaccelq', firstname='testaccelq', languagelocalekey='en_US', 
                            localesidkey='en_US', profileid = p.Id, 
                            timezonesidkey='America/Los_Angeles', username='testaccelq@salesforce.de', isActive = true);
       
        ApexSafe.dml().doInsert(new List<User>{testUser},true);

    }

    @isTest
    static void testGetUserRequestRights()
    {
        User testUser = [select id,ProfileId,Profile.Name From User where alias='TestApro' limit 1];
        Test.startTest();
             Map<String,Object>  mapResult = UserRequestRightsController.apexInit();
             List<User_RequestRights__mdt> listMeta = (List<User_RequestRights__mdt>)mapResult.get('listMeta');
             System.assertNotEquals(0,listMeta.size(),'Result: '+mapResult);

            ///={userId:"",byPassType:"",objects:"",duration:"",reason:"",bypassFlow:false,bypassVR:false,bypassTrigger:false};
             Map<String,Object> requestData = new Map<String,Object>{
                'userId'=>testUser.Id,'byPassType'=>'Full System Admin',
                'objects'=>'Account, Contact',
                'duration'=>'60',
                'reason'=>'Test',
                'bypassFlow'=>false,
                'bypassVR'=>false,
                'bypassTrigger'=>false
             };

            mapResult = UserRequestRightsController.submitRequest(requestData);
            System.assertEquals('ok',mapResult.get('status'),'Result: '+mapResult);
            System.assertNotEquals(null,mapResult.get('ticketId'),'Result: '+mapResult);

        Test.stopTest();

    }
}