/*********************************************************************************
@ Class:          UserUtil
@ Version:        1.0
@ Author:         Vimean Heng
@ Purpose:        General utility class for updating user
----------------------------------------------------------------------------------
@ Change history: 26.04.2024 / Vimean Heng / US-0014980 / Created the class.
**************************************************************************************/
public with sharing class UserUtil {

  //1, 2param
  public static User updateUser(String userName, String profileName) {
    return updateUser(userName, profileName, '');
  }

  //2, 3param
  public static User updateUser(
    String userName,
    String profileName,
    String permissionSetName
  ) {
    return updateUser(userName, profileName, permissionSetName, false);
  }

  //3, 4param
  public static User updateUser(
    String userName,
    String profileName,
    String permissionSetName,
    boolean isRemoveAllPermissionSet
  ) {
    return updateUser(
      userName,
      profileName,
      permissionSetName,
      isRemoveAllPermissionSet,
      ''
    );
  }
  
  //4, 5param
  public static User updateUser(
    String userName,
    String profileName,
    String permissionSetName,
    boolean isRemoveAllPermissionSet,
    String permissionSetGroupName
  ) {
    return updateUser(
      userName,
      profileName,
      permissionSetName,
      isRemoveAllPermissionSet,
      permissionSetGroupName,
      false
    );
  }

  //5, 6param
  public static User updateUser(
    String userName,
    String profileName,
    String permissionSetName,
    boolean isRemoveAllPermissionSet,
    String permissionSetGroupName,
    boolean isRemoveAllPermissionSetGroup
  ) {
    return updateUser(
      userName,
      profileName,
      permissionSetName,
      isRemoveAllPermissionSet,
      permissionSetGroupName,
      isRemoveAllPermissionSetGroup,
      ''
    );
  }

  //6, 7param
  public static User updateUser(
    String userName,
    String profileName,
    String permissionSetName,
    boolean isRemoveAllPermissionSet,
    String permissionSetGroupName,
    boolean isRemoveAllPermissionSetGroup,
    String roleName
  ) {
    return updateUser(
      userName,
      profileName,
      permissionSetName,
      isRemoveAllPermissionSet,
      permissionSetGroupName,
      isRemoveAllPermissionSetGroup,
      roleName,
      false
    );
  }

  //7, 8param
  //update user from accelq
  public static User updateUser(
    String userName,
    String profileName,
    String permissionSetName,
    boolean isRemoveAllPermissionSet,
    String permissionSetGroupName,
    boolean isRemoveAllPermissionSetGroup,
    String roleName,
    boolean isActive
  ) {
    return updateUser(
      userName,
      profileName,
      new List<String>{ permissionSetName },
      isRemoveAllPermissionSet,
      permissionSetGroupName,
      isRemoveAllPermissionSetGroup,
      roleName,
      false
    );
  }

  //8, 8param
  public static User updateUser(
    String userName,
    String profileName,
    String[] permissionSetName,
    boolean isRemoveAllPermissionSet,
    String permissionSetGroupName,
    boolean isRemoveAllPermissionSetGroup,
    String roleName,
    boolean isActive
  ) {
    return doUpdateUser(userName, profileName, permissionSetName, isRemoveAllPermissionSet, new String[]{ permissionSetGroupName }, isRemoveAllPermissionSetGroup, roleName, isActive);
  }
  ///
  //9, 3param
  public static User updateUser(
    String userName,
    String profileName,
    String[] permissionSetName
  ) {
    return updateUser(userName, profileName, permissionSetName, false);
  }

  //10, 4param
  public static User updateUser(
    String userName,
    String profileName,
    String[] permissionSetName,
    boolean isRemoveAllPermissionSet
  ) {
    return updateUser(
      userName,
      profileName,
      permissionSetName,
      isRemoveAllPermissionSet,
      '',
      false,
      '',
      false
    );
  }  

  //11, 8param
  /*****************************************************************************************************************************
	@ Method:   updateUser
	@ Version:  1.0
	@ Author:   vadhanak (vadhanak.voun@gaea-sys.com)
	@ Purpose: US-0012459 - AccelQ - Extend UserUtil class
  @ Parameter: userName, profileName, listPSNames, isRemoveAllPermissionSet, 
                listPSGNames, isRemoveAllPermissionSetGroup, roleName, isActive
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 17.07.2025 / vadhanak/ Created the  Method.
	*****************************************************************************************************************************/
  public static User updateUser(String userName, String profileName, String[] listPSNames,boolean isRemoveAllPermissionSet, 
                String[] listPSGNames, boolean isRemoveAllPermissionSetGroup, String roleName, boolean isActive) 
  {
      return doUpdateUser(userName,profileName,listPSNames,isRemoveAllPermissionSet,listPSGNames,isRemoveAllPermissionSetGroup, roleName,false);

  }

   /*****************************************************************************************************************************
	@ Method:   addPermissionSetGroup
	@ Version:  1.0
	@ Author:   vadhanak (vadhanak.voun@gaea-sys.com)
	@ Purpose: US-0012459 - AccelQ - Extend UserUtil class
  @ Parameter:  userName, listPSGNames
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 17.07.2025 / vadhanak/ Created the  Method. moved from  updateUser(String userName, String profileName, String[] permissionSetName, boolean isRemoveAllPermissionSet, String permissionSetGroupName, boolean isRemoveAllPermissionSetGroup, String roleName, boolean isActive)
	*****************************************************************************************************************************/    
  private static User doUpdateUser(
    String userName,
    String profileName,
    String[] permissionSetName,
    boolean isRemoveAllPermissionSet,
    String[] listPSGNames,
    boolean isRemoveAllPermissionSetGroup,
    String roleName,
    boolean isActive   ) 
    {        
      User u = getUser(userName);
      if (u == null) {
        return null;
      }
      Profile prf = null;
      UserRole role = null;
      if (
        String.isNotBlank(profileName) &&
        !profileName.equalsIgnoreCase('System Administrator') &&
        !profileName.equalsIgnoreCase('System Administrator - Limited Privileges')
      ) {
        prf = getProfile(profileName);
        if (prf != null) {
          u.ProfileId = prf.Id;
        }
      }
      if (String.isNotBlank(roleName)) {
        role = getUserRole(roleName);
        if (role != null) {
          u.UserRoleId = role.Id;
        }
      }
      if (isActive) {
        u.IsActive = isActive;
      }
      if (prf != null || role != null || isActive) {
        Database.SaveResult[] res = ApexSafe.dml()
          .doUpdate(new List<User>{ u }, true);
        for (Database.SaveResult sr : res) {
          if (!sr.isSuccess()) {
            throw new UserException('Error: ' + sr.getErrors());
          }
        }
      }
      if (!permissionSetName.isEmpty()) {
        if (isRemoveAllPermissionSet) {
          removeAllPermissionSet(u);
        }
        addPermissionSet(u, permissionSetName);
      }

      if (isRemoveAllPermissionSetGroup) {
          removeAllPermissionSetGroup(u);
      }

      if (!listPSGNames.isEmpty()) 
      {
        doAddPermissionSetGroup(u, listPSGNames);
      }

      return u;
      
   }

  
  public static Profile getProfile(String profileName) {
    List<Profile> lsProfile = ApexSafe.query()
      .doQuery(
        'SELECT Id, Name FROM Profile WHERE Name = \'' + profileName + '\''
      );
    return lsProfile.isEmpty() ? null : lsProfile[0];
  }
  public static UserRole getUserRole(String roleName) {
    List<UserRole> lsUserRole = ApexSafe.query()
      .doQuery(
        'SELECT Id, Name FROM UserRole WHERE Name = \'' + roleName + '\''
      );
    return lsUserRole.isEmpty() ? null : lsUserRole[0];
  }
  public static User getUser(String userName) {
    List<User> lsUser = ApexSafe.query()
      .doQuery(
        'SELECT Id, ProfileId,UserRoleId,IsActive,username FROM User WHERE UserName = \'' +
          userName +
          '\''
      );
    return lsUser.isEmpty() ? null : lsUser[0];
  }
  public static void addPermissionSet(
    String userName,
    String permissionSetName
  ) {
    User u = getUser(userName);
    if (u != null) {
      addPermissionSet(u, permissionSetName);
    }
  }
  public static void addPermissionSet(
    String userName,
    String[] permissionSetName
  ) {
    User u = getUser(userName);
    if (u != null) {
      addPermissionSet(u, permissionSetName);
    }
  }

  public static void addPermissionSet(User u, String permissionSetName) {
    addPermissionSet(u, new List<String>{ permissionSetName });
  }
  public static void addPermissionSet(User u, String[] permissionSetName) {
    Map<String, String> mCon = new Map<String, String>();
    Integer i = 0;
    String strOr = '';
    for (String psName : permissionSetName) {
      String key = 'p' + i;
      mCon.put(key, psName);
      if (i > 0) {
        strOr += ' OR ';
      }
      strOr = strOr + ' Label = :' + key;
      i++;
    }
    List<PermissionSet> lsPs = ApexSafe.query()
      .doQuery(
        'SELECT Id FROM PermissionSet WHERE Type = \'Regular\' AND (' +
          strOr +
          ')',
        mCon
      );
    //List<PermissionSet> lsPs = ApexSafe.query().doQuery('SELECT Id FROM PermissionSet WHERE Type = \'Regular\' AND Label =\'' + permissionSetName + '\'');
    if (!lsPs.isEmpty()) {
      List<PermissionSetAssignment> lsAssign = new List<PermissionSetAssignment>();
      for (PermissionSet p : lsPs) {
        lsAssign.add(
          new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = p.Id)
        );
      }
      Database.SaveResult[] res = ApexSafe.dml().doInsert(lsAssign, false);
      for (Database.SaveResult sr : res) {
        if (!sr.isSuccess()) {
          throw new UserException('Error: ' + sr.getErrors());
        }
      }
    }
  }

  /*****************************************************************************************************************************
	@ Method:   addPermissionSetGroup
	@ Version:  1.0
	@ Author:   vadhanak (vadhanak.voun@gaea-sys.com)
	@ Purpose: US-0012459 - AccelQ - Extend UserUtil class
  @ Parameter:  userName, listPSGNames
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 17.07.2025 / vadhanak/ Created the  Method.
	*****************************************************************************************************************************/
  public static void addPermissionSetGroup(String userName, String[] listPSGNames) 
  {
      User u = getUser(userName);
      if (u != null) {
        doAddPermissionSetGroup(u, listPSGNames);
      }
    }

  public static void addPermissionSetGroup(
    String userName,
    String permissionSetGroupName
  ) {
    User u = getUser(userName);
    if (u != null) {
      doAddPermissionSetGroup(u, new String[]{ permissionSetGroupName });
    }
  }


  public static void addPermissionSetGroup(
    User u,
    String permissionSetGroupName
  ) {
    doAddPermissionSetGroup(u, new String[]{ permissionSetGroupName });
  }
  
  /*****************************************************************************************************************************
	@ Method:   doAddPermissionSetGroup
	@ Version:  1.0
	@ Author:   vadhanak (vadhanak.voun@gaea-sys.com)
	@ Purpose: US-0012459 - AccelQ - Extend UserUtil class
  @ Parameter:   u, listPSGNames
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 17.07.2025 / vadhanak/ Created the  Method. moved from addPermissionSetGroup(User u, String permissionSetGroupName)
	*****************************************************************************************************************************/  
  private static void doAddPermissionSetGroup(  User u, String[] listPSGNames )
  {
     List<PermissionSetGroup> lsPsg = ApexSafe.query()
      .doQuery('SELECT Id FROM PermissionSetGroup WHERE MasterLabel IN:listPSGNames',new Map<String, Object>{'listPSGNames' => listPSGNames });
    // If the PermissionSetGroup exists, assign it to the user;
    if (!lsPsg.isEmpty()) {
     // PermissionSetGroup psg = lsPsg[0];
     List<PermissionSetAssignment> lstPSA = new List<PermissionSetAssignment>();
      for(PermissionSetGroup psg : lsPsg)
      {
        lstPSA.add(
          new PermissionSetAssignment(
            AssigneeId = u.id,
            PermissionSetGroupId = psg.Id
          )
        );
      }
      Database.SaveResult[] res = ApexSafe.dml()
        .doInsert(lstPSA,false);
      // Check for errors in the save results);
      for (Database.SaveResult sr : res) {
        if (!sr.isSuccess()) {
          if(!sr.getErrors().isEmpty()) 
          {
            if(sr.getErrors()[0].getStatusCode() != System.StatusCode.DUPLICATE_VALUE) //ignore duplicate value error
            {
              throw new UserException('Error: ' + sr.getErrors());
            }
          }
        }
      }
    }
  }



  public static void removeAllPermissionSet(String userName) {
    User u = getUser(userName);
    if (u != null) {
      removeAllPermissionSet(u);
    }
  }
  // Modified by DHE on 2025-01-21
  //adding the permission set to be excluded from the query that will remove the permissions
  //US-0016640
  private static void removeAllPermissionSet(User u) {
    String username = u.Username;
    List<String> permissionsToBeExcluded = UserUtil.getPermissionsToBeExcluded(
      username
    );
    String permissionsetexclussion = '';
    if (!permissionsToBeExcluded.isEmpty()) {
      for (String permission : permissionsToBeExcluded) {
        permissionsetexclussion +=
          ' AND PermissionSet.Name != \'' +
          permission.trim() +
          '\'';
      }
    }

    List<PermissionSetAssignment> ps = ApexSafe.query()
      .doQuery(
        'Select PermissionSet.Name, PermissionSetId, AssigneeId From PermissionSetAssignment WHERE PermissionSet.IsOwnedByProfile = false AND PermissionSetGroupId = null AND AssigneeId=\'' +
          u.Id +
          '\' ' +
          permissionsetexclussion
      );
    if (!ps.isEmpty()) {
      Database.DeleteResult[] res = ApexSafe.dml().doDelete(ps, false);
      for (Database.DeleteResult sr : res) {
        if (!sr.isSuccess()) {
          throw new UserException('Error: ' + sr.getErrors());
        }
      }
    }
  }
  private static void removeAllPermissionSetGroup(User u) {
    List<PermissionSetAssignment> ps = ApexSafe.query()
      .doQuery(
        'Select PermissionSet.Name, PermissionSetId, AssigneeId From PermissionSetAssignment WHERE PermissionSet.IsOwnedByProfile = false AND PermissionSetGroupId != null AND AssigneeId= \'' +
          u.Id +
          '\''
      );
    if (!ps.isEmpty()) {
      Database.DeleteResult[] res = ApexSafe.dml().doDelete(ps, false);
      for (Database.DeleteResult sr : res) {
        if (!sr.isSuccess()) {
          throw new UserException('Error: ' + sr.getErrors());
        }
      }
    }
  }
  class UserException extends Exception {
  }

  /* Method that retrieves the list of permisisons set to be excluded from the query that will remove the permissions.
using AccelQ_Permissions_set_to_be_excluded__mdt
US-0016640
author : David Herrero
createddate : 2025-01-21

     * @param username - The DeveloperName to filter records in the Custom Metadata Type.
     * @return List<String> - A list of individual permissions from Permission_Set_List__c.
     * @throws CustomMetadataAccessException - If the Custom Metadata Type is not accessible.
     * @throws IllegalArgumentException - If the username is null or blank.
     */
  public static List<String> getPermissionsToBeExcluded(String username) {
    // Validate the input parameter
    if (String.isBlank(username)) {
      throw new IllegalArgumentException('Username cannot be null or blank.');
    }

    // Check if the custom metadata type is accessible
    if (
      !Schema.sObjectType.AccelQ_Permissions_set_to_be_excluded__mdt.isAccessible()
    ) {
      throw new UserException('Custom Metadata Type is not accessible.');
    }

    Set<String> permissions = new Set<String>();

    try {
      // Query the Custom Metadata Type with the provided username
      List<AccelQ_Permissions_set_to_be_excluded__mdt> metadataRecords = [
        SELECT DeveloperName, username__c, Permission_Set_List__c, Separator__c
        FROM AccelQ_Permissions_set_to_be_excluded__mdt
        WHERE username__c = :username
      ];

      // Process the records
      for (
        AccelQ_Permissions_set_to_be_excluded__mdt record : metadataRecords
      ) {
        // Determine the separator to use
        String separator = String.isNotBlank(record.Separator__c)
          ? record.Separator__c
          : ',';

        // Split the Permission_Set_List__c by the separator and add to the list
        if (String.isNotBlank(record.Permission_Set_List__c)) {
          permissions.addAll(record.Permission_Set_List__c.split(separator));
        }
      }
    } catch (Exception e) {
      System.debug('Error retrieving metadata records: ' + e.getMessage());
    }
    // Convert the set to a list
    List<String> permissionsList = new List<String>(permissions);

    return permissionsList;
  }
}