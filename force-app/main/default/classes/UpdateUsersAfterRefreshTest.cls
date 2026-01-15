@isTest
class UpdateUsersAfterRefreshTest {
 
    @isTest
    static void testMySandboxPrep() {
        // Insert logic here to create records of the objects that the class you’re testing
        // manipulates.
 
        Test.startTest();
 
        Test.testSandboxPostCopyScript(
            new UpdateUsersAFterRefresh(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
 
        Test.stopTest();
        Map<String,String> mapProfiles = new Map<String,String>();
        Map<String,String> mapUsers = new Map<String,String>();
        for(Sandbox_Refresh__mdt sbSetting : [Select Id,DeveloperName,Label,New_Profile__c,Get_By__c From Sandbox_Refresh__mdt])
        {
            if(sbSetting.Get_By__c=='By Profile')
            {
                mapProfiles.put(sbSetting.Label,sbSetting.New_Profile__c); //by Frofile name
            }else if(sbSetting.Get_By__c=='By User')
            {
                mapUsers.put(sbSetting.Label,sbSetting.New_Profile__c); //by Full Name
            }
        }
        //System.debug('mapProfiles: '+mapProfiles);
       // System.debug('mapUsers: '+mapUsers);
        for(User usr: [Select Id,Name,Email,Profile.Name From User Where IsActive=True AND IsPortalEnabled=False AND(Profile.Name IN:mapProfiles.keySet() OR Name IN:mapUsers.keySet()) limit 5])
        {
            System.assertEquals(mapUsers.get(usr.Name), usr.Profile.Name, 'Profile updated');
            System.assertEquals(true, !(usr.Email).contains('.invalid'), 'email fixed');
        }

    }
}