/*********************************************************************************************************************************
@ Class:          DeleteUserAvailabilityController
@ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:        Controller Class for User Availability list view buttons pages
@                 US-0010477 - [PT] New Button "Bulk Delete" on User Availability Layout
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.10.2021 /Created the class.			  
*********************************************************************************************************************************/

public class DeleteUserAvailabilityController {
    private ApexPages.StandardSetController setCon;
    private List<User_Availability__c> selectedRecord {get;set;}
    private Boolean isBOB_CAT_LEAD = ApexUtil.checkPermissionSet(new Set<String>{DeleteUserAvailabilityController.PERMISSION_BOB_CATEGORY_LEAD});
    private Boolean isAdmin = Userinfo.getprofileId() == ApexUtil.ADMIN_PROFILE_ID;

    public static final String PERMISSION_BOB_CATEGORY_LEAD= 'BoB_Category_Lead';
    public Boolean isError {get;set;}
    
    public DeleteUserAvailabilityController(ApexPages.StandardSetController controller){
        setCon = controller;
        selectedRecord = controller.getSelected();
    }

    public PageReference backToListView(){
        return setCon.cancel();
    }

    public PageReference initDeleting(){
        
        if(isAdmin) return null;

        
        if(!isBOB_CAT_LEAD){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.YOU_NEED_PERMISSION_TO_PERFORM_THIS_ACTION));
            isError = true;
        }  
        
        return null;
    }

    public PageReference actionDelete(){

        if(!selectedRecord.isEmpty()){
            try{

                if(isBOB_CAT_LEAD || isAdmin){
                    delete selectedRecord;
                }
            
            }catch(Exception ex){
                ApexPages.addMessages(ex);
            }
        }

        return setCon.cancel();
    }
}