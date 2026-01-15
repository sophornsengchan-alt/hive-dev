@isTest
public with sharing class LwcLoginFormControllerTest {
    
    @isTest
    static void testLogin(){
        try{
            LwcLoginFormController.doLogin('username', 'password', 'en','');
        }
        catch(Exception e){

        }
        
    }

    @isTest
    static void testTranslateLoginFailedErrorMessage(){
        try{
            Map<String,Object> res = LwcLoginFormController.translateLoginFailedErrorMessage('This is a generic error', 'de');
            System.assert( res != null && !res.isEmpty(), 'There should be a generic error message in DE return.');
        }
        catch(Exception e){

        }
        
    }

    @isTest
    static void testfectchUrl(){
        try{
            LwcLoginFormController.fectchUrl();
        }
        catch(Exception e){

        }
        
    }

    @isTest
    static void testfetchLoginLabelTranslation(){
        Map<String,Object> res = LwcLoginFormController.fetchLoginLabelTranslation(new List<String>{'SellerPortalLabel'});
        System.assert( res != null && !res.isEmpty(), 'There should be a record return in map.');
        
    }

}