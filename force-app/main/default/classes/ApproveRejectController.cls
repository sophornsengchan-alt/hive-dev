/*********************************************************************************************************************************
@ Class:          ApproveRejectController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Controller for Aura: ApproveReject
                [#EPH-7104] New Permission Set_ Final Value Fee Approval         
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.09.2018 / Vadhanak Voun / Created the class.
@               : 09.06.2023 / Sovantheany Dim / US-0013726 - FVF Roles
*********************************************************************************************************************************/
public without sharing class ApproveRejectController {
     
    /*****************************************************************************************************************************
	@ Method:   apexInit
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:   [#EPH-7104] New Permission Set_ Final Value Fee Approval      
    @              init for controller
    @               Given that I am a user with new user permission set "Final Value Fee Approval"
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:   parentId: FVF Id
	------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.05.2019 / Vadhanak Voun / Created the  Method.
    @               : 09.06.2023 / Sovantheany Dim / US-0013726 - FVF Roles
	*****************************************************************************************************************************/
     @AuraEnabled
     public static Map<String,string> apexInit(String parentId)
     {
         Map<String,string>  mapResult = new Map<String,string>();

        //TH:US-0013726: comment out
        //Set<String> pName = new Set<String>{EBH_ConstantsUtility.PERMISSION_SET_FVFAPPROVAL};
        Boolean isAdmin = (EBH_ConstantsUtility.ADMIN_PROFILE_ID == UserInfo.getProfileId());
        Final_Value_Fee_FVF__c fvf = Database.query(EBH_ConstantsUtility.SOQL_FVF+' Where Id =:parentId');
        //TH:US-0013726: comment out
        //Boolean hasPermssion = (isAdmin || ApexUtil.checkPermissionSet(pName));
        Boolean validStage = (EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE == fvf.Final_Value_Fee_Stage__c);
        //TH:US-0013726: comment out
        //mapResult.put('isAllowed',(hasPermssion && validStage)+'');
        mapResult.put('isAllowed',(isAdmin && validStage)+'');
        //if(!hasPermssion)
        if(!isAdmin)
        {
           mapResult.put('msg',System.Label.Approval_No_Permission); 
        }else if(EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE <> fvf.Final_Value_Fee_Stage__c)
        {
            mapResult.put('msg',System.Label.Approval_Invalid_Stage); 
        }
              

        return mapResult;
     }

     /*****************************************************************************************************************************
	@ Method:   apexDoApprovve
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:   [#EPH-7104] New Permission Set_ Final Value Fee Approval      
    @           AC3:
    @            Given that I press "Approve" in AC2
    @            Then the status of the record is changed to "eBay Approved"
    @            and the Owner of the record recives email notification
    @   
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:       parentId: fvf Id, comments: comment from approval
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 20.05.2019 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
     @AuraEnabled
     public static Map<String,string> apexDoApprove(String parentId,String comments)
     {
         Map<String,string>  mapResult = new Map<String,string>();
        try {
            Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c
                    (Id=parentId,
                    Approved_Date__c=System.now(),
                    Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_APPROVED,
                    Approval_Comments__c = comments
                    );

            update fvf;

            mapResult.put('status','ok');
        }catch(DMLException dex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}
    	catch(Exception ex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
    	}

        return mapResult;
     }

    /*****************************************************************************************************************************
	@ Method:   apexDoReject
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:   AC4:
    @                Given that I press "Approve" in AC2
    @                Then Owner of the record receives email notification
	@			 
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:       parentId: fvf Id, comments: comment from rejection
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 20.05.2019 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
     @AuraEnabled
     public static Map<String,string> apexDoReject(String parentId,String comments)
     {
         Map<String,string>  mapResult = new Map<String,string>();
        try {
            Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c
                    (Id=parentId,
                    Rejected_Date__c=System.now(),
                    //Final_Value_Fee_Stage__c = EBH_ConstantsUtility. ??,
                    Approval_Comments__c = comments
                    );

            update fvf;

            mapResult.put('status','ok');
        }catch(DMLException dex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}
    	catch(Exception ex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
    	}

        return mapResult;
     }
}