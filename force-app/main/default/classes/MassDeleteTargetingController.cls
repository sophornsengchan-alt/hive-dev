/*********************************************************************************************************************************
@ Class:          MassDeleteTargetingController
@ Version:        1.0
@ Author:         Sovantheany Dim
@ Description:    Override Standard Deletd button on object Campaign_Targeting__c
@ Purpose:        01.12.2022/ US-0011047 - Team Lead with GCX Super user Permission unable to Remove Target Lists created by other People from Campaigns
*********************************************************************************************************************************/
public with sharing class MassDeleteTargetingController {
    public List<Campaign_Targeting__c> selectedTargeting {get;set;}
    public Integer numSelected {get;set;}
    public String msg {get;set;}
    public String severity {get;set;}
    public Boolean isError {get;set;}
    public Boolean isDone {get;set;} 
    public String reUrl{get;set;}
    public PageReference reUrl2{get;set;}
    private String campaingId = null;
    Id targetingId;
    private List<Campaign_Targeting__c> lstTargeting;
    private final static String GCX_SUPER_USER = 'GCX_Super_User';
    private Boolean hasPermis {get;set;}
    private Boolean isAdmin {get;set;}
    private Boolean isOwner {get;set;}

    public MassDeleteTargetingController(ApexPages.StandardController controller) {
        targetingId = controller.getId();
        reUrl2 = controller.cancel();
        isError = false;
        isDone = false;
        msg = System.label.TEXT_QUESTION_FOR_DELETE_Campaign_Targeting;
        severity = ApexPages.severity.WARNING.name();
        lstTargeting = [SELECT Id,Campaign__c,OwnerId FROM Campaign_Targeting__c WHERE Id =: targetingId];
        PageReference pgCurrent = ApexPages.currentPage();
        reUrl = pgCurrent.getParameters().get('retURL');
        if(String.isBlank(reUrl)){
            //set reUrl to Campaign, if campaign is not null
            if(lstTargeting[0].Campaign__c != null){
                campaingId = lstTargeting[0].Campaign__c;
                reUrl = '/lightning/r/Campaign/'+campaingId +'/view';
            }else{
                reUrl = '/lightning/o/Targeting__c/list?filterName=Recent';
            }
        }
        hasPermis = ApexUtil.checkPermissionSet(new Set<String>{GCX_SUPER_USER});
        isAdmin = (Userinfo.getprofileId() == ApexUtil.ADMIN_PROFILE_ID || Userinfo.getprofileId() == ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
        isOwner = (UserInfo.getUserId() == lstTargeting[0].OwnerId);
        if(!isAdmin && !hasPermis  && !isOwner)
        {
            isError = true; 
            msg = System.Label.ERR_MSG_NO_GCX_SUPER_USER_PERMISSION;
            severity = ApexPages.severity.WARNING.name();
        }
    }
    public PageReference deleteTargeting(){
        try {
            WithoutSharing.doDelete(lstTargeting);
            isError = false; 
            msg = System.label.Delete_Targeting_Success;
            severity = ApexPages.severity.CONFIRM.name(); 
            isDone = true;
        } catch (DMLException dmx) {          
             isError = true;  msg = dmx.getMessage(); severity = ApexPages.severity.FATAL.name(); 
        }
        
         return null;
    }
    public PageReference backToListView(){
        PageReference pageRef = new PageReference(String.escapeSingleQuotes(reUrl));
        return pageRef;
   }
    public PageReference cancel(){
        return reUrl2;
    }
}