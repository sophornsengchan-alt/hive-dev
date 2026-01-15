/*********************************************************************************************************************************
@ Class:         UpdateUsersAfterRefresh
@ Version:       1.0
@ Author:        David
@ Purpose:       US-0008143 - Create Class to reset dev team users & emails
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.08.2020 / David/ Created the class.
@                 04.07.2023 / vadhanak voun / US-0013749 - Update UpdateUsersAfterRefresh class
@                 09.08.2024 / vadhanak voun / US-0015686 - Automated Removal of "SSO_enforced" Permission Set in Refreshed Sandboxes
----------------------------------------------------------------------------------------------------------------------------------*/
global with sharing class UpdateUsersAfterRefresh implements SandboxPostCopy  {

    final String psSSOEnforce = 'SSO_enforced';
    final String byUSER= 'By User';
    final String byPROFILE = 'By Profile';

    final String soqlUSER = 'Select Id,Name,Email,Profile.Name From User Where IsActive=True AND IsPortalEnabled=False '; //e.g. same name but gcx can not set to admin
    global void runApexClass(SandboxContext context) {
         

        Map<String,String> mapProfiles = new Map<String,String>();
        Map<String,String> mapUsers = new Map<String,String>();
        
        
        for(Sandbox_Refresh__mdt sbSetting :  (List<Sandbox_Refresh__mdt>)ApexSafe.query().doQuery('Select Id,DeveloperName,Label,New_Profile__c,Get_By__c From Sandbox_Refresh__mdt'))
        {
            if(sbSetting.Get_By__c==byPROFILE)
            {
                mapProfiles.put(sbSetting.Label,sbSetting.New_Profile__c); //by Frofile name
            }else if(sbSetting.Get_By__c==byUSER)
            {
                mapUsers.put(sbSetting.Label,sbSetting.New_Profile__c); //by Full Name
            }
        }
        if(mapUsers.isEmpty() && mapProfiles.isEmpty())
        {
            return;
        }

        Set<String> setUsers = mapUsers.keySet();
        Set<String> setProfiles = mapProfiles.keySet();
        Set<String> setCons = new Set<String>{(setUsers.isEmpty()?null:' Name IN:setUsers '),(setProfiles.isEmpty()?null:' Profile.Name IN:setProfiles ')};
        setCons.remove(null);//just in case

        String finalSOQLUser = soqlUSER +  ' AND ('+ String.join(new List<String>(setCons),' OR ') +')';
        //System.debug(finalSOQLUser);
        //Select Id,Name,Email,Profile.Name From User Where IsActive=True  AND ( Name IN:setUsers  OR  Profile.Name IN:setProfiles )
        List<User> listOfUsers = new List<User>();
        Set<Id> setUserIds = new Set<Id>();
        for(User usr: (List<User>)ApexSafe.query().doQuery((finalSOQLUser),new Map<String, Object>{'setUsers'=>setUsers,'setProfiles'=>setProfiles}))
        {
            if(setProfiles.contains(usr.Profile.Name))
            {
                usr.ProfileId   = ApexUtil.getProfileByName(mapProfiles.get(usr.Profile.Name)).Id;
            }
            //In case Specific User overide the priority of profile
            if(setUsers.contains(usr.Name))
            {
                usr.ProfileId   = ApexUtil.getProfileByName(mapUsers.get(usr.Name)).Id;
            }
            usr.Email   = usr.Email.removeEnd('.invalid');
            listOfUsers.add(usr);
            setUserIds.add(usr.Id);
        }
        
 
        //Database.SaveResult[] results = Database.update( listOfUsers,false);
        //System.debug('results: '+results);
        
        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerUserEmail = true;
    
        // Database.update(listOfUsers,dlo); 
        ApexSafe.dml().setDMLOPtion(dlo).secCheck(false).doUpdate(listOfUsers, true);
        
        //NK:09/08/2024:US-0015686
        //remove SSO enforce PS; so we can use pwd/login to sandbox (sso not configure in dev/sat)
        removePS(setUserIds);
    }

    private void removePS(Set<Id> setUserIds)
    {
        String soqlPAS = 'Select Id, PermissionSetId, AssigneeId from PermissionSetAssignment where Permissionset.Name=:psSSOEnforce AND AssigneeId IN:setUserIds';
        List<PermissionSetAssignment> listPSA =ApexSafe.query().secCheck(false).doQuery(soqlPAS, new Map<String,Object>{'psSSOEnforce'=>psSSOEnforce,'setUserIds'=>setUserIds});
        ApexSafe.dml().secCheck(false).doDelete(listPSA,true);
    }
}