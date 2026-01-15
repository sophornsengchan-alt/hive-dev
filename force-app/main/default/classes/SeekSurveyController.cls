/*********************************************************************************************************************************
@ Class:          SeekSurveyController
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        US-0015110 - User Feedback Survey for US SEP (Test in Prod)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.04.2024 / Sambath Seng / Created the class.
@               : 14.05.2024 / Sambath Seng / US-0015111 - User Feedback Survey for US, AU, UK (Launch)
*********************************************************************************************************************************/
public with sharing class SeekSurveyController {
    
    private static String soqlUser = 'Select Id,Contact.Account.Name From User Where Id=:userId'; // SB 14.05.2024 US-0015111

    @AuraEnabled
    public static Map<String,Object> getSellerData()
 	{
        Map<String,Object> mSellerData = new Map<String,Object>();
        User currentUser = new User();
        List<User> lstUsers = (List<User>) ApexSafe.query().secCheck(false).doQuery(soqlUser,new Map<String, Object> {'userId' => UserInfo.getUserId()});
        if (!lstUsers.isEmpty()) {
            currentUser = lstUsers[0];
        }

        mSellerData.put('sellerName',currentUser.Contact.Account.Name);

        return mSellerData;
    }
}