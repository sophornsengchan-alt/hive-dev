/*********************************************************************************************************************************
@ Class:         WelcomeEmailController
@ Version:       1.0
@ Author:        Sovantheany.dim(sovantheany.dim@gaea-sys.com)
@ Purpose:       US-0011571 - Welcome email has been enabled which will send same email template to every Sellers irrespective of region and type of Seller
@				 used by vf template name : Add_User_Welcome_Email_Template 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.03.2022 / Sovantheany.dim(sovantheany.dim@gaea-sys.com)
@               16.01.2023 / Acmatac SEING / US-0012095 [UK] Manage Users
*********************************************************************************************************************************/
public with sharing class WelcomeEmailController {
    public Contact cont { get; set; }
    public static String soqlUser = 'SELECT Username, FirstName, LastName, Contact.Account.SP_Main_Domain__c, Contact.Account.Name FROM User';

    /*****************************************************************************************************************************
    @ Method:       getUser
    @ Author:       sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0011571 - Welcome email has been enabled which will send same email template to every Sellers irrespective of region and type of Seller
    @               get UserName
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  29.03.2022 / sovantheany dim / US-0011571 Created the method.
    @*****************************************************************************************************************************/
    public List<User> users { 
        get{
            String contId = cont.Id;
            return Database.query(soqlUser+' where ContactId =: contId');
        } set; 
    }

    public String mainDomain {
        get{
            return users.isEmpty() ? '' : users[0].Contact.Account.SP_Main_Domain__c;
        } set;    
    }

    public String sellerNameFromCurrentUser {
        get{
            String currentUserId = UserInfo.getUserId();
            List<User> lstUser = Database.query(soqlUser+' where Id =: currentUserId');
            return lstUser.isEmpty() ? '' : lstUser[0].Contact.Account.Name;
        } set;    
    }

    public String sellerName {
        get{
            return users.isEmpty() ? '' : users[0].Contact.Account.Name;
        } set;    
    }

    public String userNameStr {
        get{
            return users.isEmpty() ? '' : users[0].Username;
        } set;    
    }

}