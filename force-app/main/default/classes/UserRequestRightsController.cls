/*********************************************************************************************************************************
@ Class:          UserRequestRightsController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Controller for lwc UserRequestRights
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.05.2025 / Vadhanak Voun / Created the class.
@                                           / US-0012480 - 2 Request Elevated Privileges Process - UI
@                :23.07.2025 / Vadhanak Voun/ US-0033166 - "Ad Hoc Elevated Access" Fixes
********************************************************************************************************************************/
public with sharing class UserRequestRightsController {
    final static String TICKET_STATUS_PENDING = 'Pending';

    /*****************************************************************************************************************************
	@ Method:   apexInit
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  US-0012480 - 2 Request Elevated Privileges Process - UI
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 22.05.2025 / Vadhanak Voun / Created the  Method.
    @                :23.07.2025 / Vadhanak Voun/ US-0033166 - "Ad Hoc Elevated Access" Fixes
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexInit() 
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        String mdtName = 'Default';
        String soqlMdt = 'SELECT  id,DeveloperName, Available_Bypass_Objects__c from User_RequestRights__mdt where DeveloperName =:mdtName';
        List<User_RequestRights__mdt> listMeta = (List<User_RequestRights__mdt>)ApexSafe.query().secCheck(false).doQuery(soqlMdt,new Map<String, Object>{'mdtName' => mdtName});
        mapResult.put('listMeta', listMeta);

        // Check if current user has required custom permissions
        Boolean hasFullHiveAdminAccess = FeatureManagement.checkPermission('Full_Hive_Admin_Access');
        Boolean hasHiveBypassAccess = FeatureManagement.checkPermission('Hive_Bypass_Access');
        
        mapResult.put('hasFullHiveAdminAccess', hasFullHiveAdminAccess);
        mapResult.put('hasHiveBypassAccess', hasHiveBypassAccess);
        
        //full Admin can see without custom permission
        mapResult.put('isFullAdmin', Userinfo.getprofileId() == ApexUtil.ADMIN_PROFILE_ID);
         

        return mapResult;
    }

    /*****************************************************************************************************************************
	@ Method:   submitRequest
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  US-0012480 - 2 Request Elevated Privileges Process - UI
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 22.05.2025 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> submitRequest(Map<String,Object> requestData)
    {
        //  userByPass ={userId:"",byPassType:"",objects:[],duration:"",reason:"",bypassFlow:false,bypassVR:false,bypassWF:false,bypassTrigger:false};
        // Type: "System Admin Request" or "Bypass Permission Set".
        // Duration: As provided in the modal.
        // Business Justification: As entered by the user.
        // Requester Name: Name of the user requesting access. dddd
        // Previous Profile Name: Name of the user's previous profile.
        // Previous Profile ID: ID of the user's previous profile.
        // Permissions Requested: Indicate if flow, trigger, or validation rule bypass is requested.
        // Objects Requested: Text area listing the objects involved.
        Map<String,Object> mapResult = new Map<String,Object>();

        String reqUserId = String.valueOf(requestData.get('userId'));
        String soqlUser = 'SELECT Id,Name,ProfileId,Profile.Name FROM User WHERE Id =:reqUserId';

        try
        {
                
            User reqUser = (User)ApexSafe.query().doQuery(soqlUser,new Map<String,Object>{'reqUserId' => reqUserId}).get(0);

            RecordType rtAccess = ApexUtil.getRecordTypeByName('Ticket__c', 'Elevated_Access_Request');
            Ticket__c ticket = new Ticket__c(RecordTypeId= rtAccess.Id);
            ticket.Type_of_Elevated_Access__c = String.valueOf(requestData.get('byPassType')); //Full System Admin /	Enable Bypass
            ticket.Duration_In_Minutes__c = Double.valueOf(requestData.get('duration'));
            ticket.Business_Reason__c = String.valueOf(requestData.get('reason'));
            ticket.User__c = reqUser.Id;
            ticket.Previous_Profile_Name__c = reqUser.Profile.Name;
            ticket.Previous_Profile_Id__c = reqUser.ProfileId;    
            ticket.Status__c = TICKET_STATUS_PENDING;   // Updated ty DHE to set default status to Pending

            ticket.Triggered_Objects__c   = String.valueOf(requestData.get('objects'));

            ticket.Flow__c = Boolean.valueOf(requestData.get('bypassFlow'));
            ticket.Trigger__c = Boolean.valueOf(requestData.get('bypassTrigger'));
            ticket.Validation_Rule__c = Boolean.valueOf(requestData.get('bypassVR'));       
        
            ApexSafe.dml().doInsert(new List<Ticket__c>{ticket}, true);
            mapResult.put('status','ok');
            mapResult.put('ticketId',ticket.Id);

        }catch(DMLException dex)
        { mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
        } catch(Exception ex){ mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString()); }
        

        return mapResult;
    }

    
}