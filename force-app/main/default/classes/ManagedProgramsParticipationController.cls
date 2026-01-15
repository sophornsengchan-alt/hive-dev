/*********************************************************************************************************************************
@ Class:          ManagedProgramsParticipationController
@ Version:        1.0
@ Author:         Sothea Horn
@ Purpose:        Handle the managed programs participation functionality
@ Test Class:     ManageProgramParticipationControllerTest
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.11.2025 / Sothea Horn / Create the class / US-0033849 - Step 1 - Seller Overview
*********************************************************************************************************************************/
public with sharing class ManagedProgramsParticipationController {
    public final static String PERMISSIONSET_ACTION_CHANGE_REQUEST_SUBMITTER = 'Actions_Change_Request_Submitter';
    
    /*********************************************************************************************************************************
    @ Class:          hasPermissionSubmitChangeRequest
    @ Version:        1.0
    @ Author:         Sothea Horn
    @ Purpose:        Check if user has permission to submit change request
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.11.2025 / Sothea Horn / Create the method / US-0033849 - Step 1 - Seller Overview
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static boolean hasPermissionSubmitChangeRequest() {
       return ApexUtil.checkPermissionSet(new Set<String>{PERMISSIONSET_ACTION_CHANGE_REQUEST_SUBMITTER});
    }
}