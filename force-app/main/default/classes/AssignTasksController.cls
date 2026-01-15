/*********************************************************************************************************************************
@ Class:          AssignTasksController
@ Version:        1.0
@ Author:         
@ Purpose:        Controller Class for Button "Create tasks"
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.08.2018 /  / Created the class.
@				: 26.12.2018/Vadhanak Voun/ [EPH-6854] Create Tasks for Updated Seller List
@				: 27.02.2020/Vadhanak Voun/US-0007221 Hypercare - Create Tasks functionality causes APEX CPU Timeout
@						Moved create/update logic to BatchCreateUpdateTask
@               : 01.02.2021/Mony Nou/US-0008970 - [Pl Adv] "Survey Id" to be made optional for PL Outreach Campaigns
@                       Skipped Survey ID for PL OutReach Campaign
@               : 13.12.2022/SRONG TIN/US-0012626 - Error when try to Refresh task 20K
@				: 22.02.2023/ Chetra Sarom / US-0013230 - Task Creation in Outreach Campaigns gets duplicated when Users attempts to Click "Refresh Tasks" and "Reassign Tasks" Simultaneously
*********************************************************************************************************************************/
public class AssignTasksController {
	/************************************* CONSTANT DEFINITION *************************************************/
    
    public static final string queryCampaign = 'select Name ,OwnerId,survey_id__c,Ardira_survey__c,EBH_TaskCreated__c,EBH_SellerList__c,ebh_channel__c,EBH_NumberofCampaignMembers__c, ebh_channelmp__c, Task_Creation_Running__c, recordtype.developername from Campaign where Id = :campaignId';
    public static final string queryGCXUser = 'select Id from GCX_User__c where Campaign_Name__c =:campaignID limit 1';
    public static final String PROFILE_STANDARD_ADS_USER = 'Standard Ads User Profile'; //MN:01022021
    /************************************ END OF CONSTANT DEFINITION*******************************************/
    Id campaignId;
    public Campaign cRecord        { set; get; }
    public List<GCX_User__c> gcxUser        { set; get; }
    public User usr        { set; get; }
    public boolean validUser 		   { set; get; }
    public Integer insertedTasks 		   { set; get; }
    String reURL;
    
    public String msg        { set; get; }
    public Boolean isError        { set; get; }
    public Boolean showConfirm        { set; get; }
    public Boolean showResult        { set; get; }
    
    public Boolean showConfirmNumber  { set; get; } //NK:02/07/2019: EPH-7731: show confirm number for user click next before docreate/udpate task
    public Boolean showButtonNext  { set; get; }
    public Boolean isAUProfile  { set; get; }
    
    @testVisible
    private Boolean recordOK  { set; get; }
    private Boolean isPLAdsUser  { set; get; } //MN:01/02/2021: US-0008970 To check if current user is PL Ads User (User with 'Standard Ads User Profile' profile and permission set "GCX Super User")
    private Map<String,EBH_TargetedSeller__c> mapTargetSeller;
    
    public AssignTasksController(ApexPages.StandardController controller) {
        if (!test.isRunningTest()){ controller.addFields(new List<String> {'recordtype'}); }
        
        showConfirmNumber = false;
        showButtonNext = false;
        
        campaignId = controller.getId();
        cRecord = Database.query(queryCampaign);
        //US-0007313 - [AU]Assignment for AU Outreach Campaigns
        gcxUser = Database.query(queryGCXUser); 

        isAUProfile = Userinfo.getprofileId() == ApexUtil.getProfileByName(EBH_ConstantsUtility.TICKET_AU_PROFILE).Id;
        isPLAdsUser = (UserInfo.getProfileId() == ApexUtil.getProfileByName(PROFILE_STANDARD_ADS_USER).Id && isGCXLead); //MN:01022021: US-0008970
        
        validUser = validateUser();
        
        reURL=controller.cancel().geturl();
        
        recordOK = vaidateRecord();
        isError = false;
        showConfirm = false;
        showResult = false;
     	if(validUser &&  recordOK && cRecord.EBH_TaskCreated__c)
        {
        	showConfirm = true;
         	msg = System.Label.ConfirmTaskCreate;
        } 
        // 13.12.2022/SRONG TIN/US-0012626 - this block code is no used anymore

            // Set<String> sellerMapId = new Set<String>();
            //Set<String> campaignIds = new Set<String>{campaignId};
            // for(Campaign_Targeting__c ct : Database.query(EBH_ConstantsUtility.SOQL_CAMP_TARGET_SELLERLIST + ' Where Campaign__c IN: campaignIds'))
            // {
            // 	sellerMapId.add(ct.Seller_List__c);
            // }
            //String filterId = cRecord.EBH_SellerList__c; use multi-sellerList instead
            // mapTargetSeller = new Map<String,EBH_TargetedSeller__c>();
            // for(EBH_TargetedSeller__c ts: Database.query(EBH_ConstantsUtility.CTH_TARGETEDSELLERQUERY))
            // {
            // 	mapTargetSeller.put(ts.EBH_Seller__c,ts);
            // }
        
        if(!validUser)   
        {
        	msg = 'User is not allowed to Create Tasks';
        	isError = true;
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
        	 
         }else if(!recordOK)
         {
         	 //msg = 'Campaign Channel is not ' + EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
         	 msg = 'Invalid Channel or Recortype or No Campaign Member!'; isError = true; ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
         	  
         }
    }
    /**NK:04/07/2019:EPH-7756
    	Only User with GCX permission set should be able to "Create Tasks" if record type =Outreach & channel = GCX Outreach (Phone) OR GCX Inbound (Phone)
		Any User shouldbe able to "Create Tasks" if record type =Outreach, channel = AM Outreach 
    */
    private Boolean validateUser()
    {
        /* MN:01022021:US-0008970 - Moved these line to get/set variable isGCXLead
        ID CurrentUserId=UserInfo.getUserId();    
    	PermissionSetAssignment[]  pss = Database.query(EBH_ConstantsUtility.SOQL_GCX_TEAM_LEAD );
        Boolean isGCXLead = !pss.isEmpty();
        */
    	Set<String> setChannels = new Set<String>{EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL,EBH_ConstantsUtility.CAMP_CHANNEL_GCXINBOUND_PHONE};
    	
       
       if(isOutReach)
       {
       		return true;
       }else if(cRecord.recordType.DeveloperName =='EBH_AMOutreach' && isGCXLead && setChannels.contains(cRecord.EBH_Channel__c))
       {
       		return true;
       }
       return false;
    }
    /*****************************************************************************************************************************
    @ Method:         createUpdateTasks
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        [EPH-6854] AC3: Given that user selected YES in AC1, 1.2. then:
    @				Campaign Members changes
	@				1. Update all Campaign Members with existing response code < 20 or empty to response code = 22
	@				2. Compare new Seller List with existing campaign members. If sellerlist.businessname exists in campmember.contact.account -> if
	@					campmember.response code = 22, then set it to 10; else skip
	@				3. Upload Campaign Members from new Target List, set Response code to 10
	@				
	@				Tasks Changes
	@				1. For Campaign Members with Response code = 22 & call attempts > 0: Tasks status changed to "Cancelled"
	@				2. For Campaign Members with Response code =22 & call attempts =0: delete Task
	@				3. For Campaign Members with Response code =10, check if tasks exists, then not -> create New Tasks
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:        
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.12.2018 / Vadhanak Voun / Created the  Method.
    @ 				: 15.03.2019 / Vadhanka Von / EPH-7143 Update priority when adding/deleting new campaign members
	@				: 13.05.2019 / Vadhanka Von / EPH-7356 Exclude "Do not contact" and "incorrect phone number" contacts from the outreach
	@				: 02.07.2019/ Vadhanka Von / EPH-7731 AM Outreach. Assign Tasks to Account Managers
	@							All Tasks are automatically assigned to Users who are managing these sellers.
	@							Task. Assigned to = Campaign Member.Customer. Owner If Customer.Owner= Deployment user assign to the Task to Campaign.Owner
	@				: 24.09.2019: US-0009352: it should update existing "open" tasks with the Campaign Survey Id field.
	@				: 30.09.2019: US-0018692 Campaign member response code 22 but Task Response code still "In Queue"
	@				: 03.02.2020/ Vadhanak Voun/US-0007153: moved insert future into DML_Worker; so we can retry for lock-row 
	@				: 27.02.2020/ Vadhanak Voun/US-0007221 Hypercare - Create Tasks functionality causes APEX CPU Timeout
    @					moved to BatchCreateUpdateTask
    @				: 22.02.2023/ Chetra Sarom / US-0013230 - Task Creation in Outreach Campaigns gets duplicated when Users attempts to Click "Refresh Tasks" and "Reassign Tasks" Simultaneously
    *****************************************************************************************************************************/
    public PageReference createUpdateTasks()
    {
        // 22.02.2023/ Chetra Sarom / US-0013230 
        if(!cRecord.Task_Creation_Running__c){
            cRecord.Task_Creation_Running__c = true;
            update cRecord;
        }
        // end 22.02.2023/ Chetra Sarom / US-0013230 

    	BatchCreateUpdateTask b = new BatchCreateUpdateTask(campaignId);
    	Database.executeBatch(b,200);
        
        showButtonNext = false;
        showResult  = true;
		showConfirm = false;

        msg = 'Task creation job is created and running in the background.';            
    	return null; 
    }
    
    
    public boolean isOutReach {get {
    		return cRecord.recordType.DeveloperName ==EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH && EBH_ConstantsUtility.CAMP_CHANNEL_AM_OUTREACH == cRecord.EBH_Channel__c;}
    	set;}
    
    public boolean isPLAdsOutReach {
        get {
            
            return isGCXLead && cRecord.recordType.DeveloperName ==EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH && EBH_ConstantsUtility.CAMPAIGN_CHANNEL_GCX_OUTREACH == cRecord.EBH_Channel__c;
        }
        private set;
    }
    //MN:01022021:US-0008970 - get/set variable to return true when current user has "GCX Super User" Permission Set
    public Boolean isGCXLead {
        get {
            if (isGCXLead == null) {
                Id currentUserId = UserInfo.getUserId(); //Use to bind variable with below query string    
                PermissionSetAssignment[]  pss = Database.query(EBH_ConstantsUtility.SOQL_GCX_TEAM_LEAD );
                isGCXLead = !pss.isEmpty();
            }
            return isGCXLead;
        }
        private set;
    }
    
    private boolean vaidateRecord()
    {
    	if(cRecord!= null && 
              (
                   (cRecord.recordtype.developername==ebh_constantsUtility.CMRC_CAMPRECORDTYPE && Campaign.EBH_Channel__c!=null && isApiValue(EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL,Campaign.EBH_Channel__c.getDescribe()))||
                   (cRecord.recordtype.developername==ebh_constantsUtility.CMRC_MASCAMPRECORDTYPE && Campaign.EBH_ChannelMP__c!=null && isApiValue(EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL,Campaign.EBH_ChannelMP__c.getDescribe()) )||
               	                 	   (cRecord.recordType.DeveloperName=='EBH_AMOutreach' && cRecord.EBH_NumberofCampaignMembers__c>0 &&Campaign.EBH_Channel__c!=null && isApiValue(EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL,Campaign.EBH_Channel__c.getDescribe()))	)
               ){
               	
               	return true;
               }
    	
    	return false;
    }
    
    /**
    	25.12.2018/ Vadhanak Voun/ EPH-6850 Targeting Engine with Priority
        30.10.2019/ Vadhanak Voun/ US-0018806 [GCX] Validation in "Create Tasks" Button to restrict Task Creation when Survery ID is empty
        05.05.2020/ Sreymeas Nao/ US-0007313 - [AU]Assignment for AU Outreach Campaigns
        22.05.2020/ LoumAng SENG/US-0007385 - "Survey Id" to be made optional in AM Outreach Campaigns
        01.02.2021/ Mony Nou/US-0008970 - [Pl Adv] "Survey Id" to be made optional for PL Outreach Campaigns
        21.04.2021/ David Herrero - Added the posibility to create Tasks with Survey Vista instead of clicktools survey_id__c
    */
    public pageReference assignCallTasks()
    {
        
        // System.debug('nsp: isOutReach == '+isOutReach);
        // System.debug('nsp: isPLAdsUser == '+isPLAdsUser);
        // System.debug('nsp: isPLAdsOutReach == '+isPLAdsOutReach);

    	if(!validUser)   
        {
        	msg = 'User is not allowed to Create Tasks';
        	isError = true;
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
        	//return null;
         }else if(!recordOK)
         {
         	 //msg = 'Campaign Channel is not ' + EBH_ConstantsUtility.GCX_TASK_CALL_CHANNEL;
         	 msg = 'Invalid Channel or Recortype or No Campaign Member!';
         	 isError = true;
         	 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
         	 //return null;
         	 
         }else if((String.isBlank(cRecord.survey_id__c) && String.isBlank(cRecord.Ardira_Survey__c)) && !isOutReach && (!isPLAdsUser  || !isPLAdsOutReach)) //NK:30/10/2019: US-0018806 //LA:22.05.2020:US-0007385 //MN:01022021:US-0008970 //NSP:30/07/2021: US-0009970
         {
     		 msg = 'Please note that Tasks cannot be created until Survey ID is populated. Create a "Validate Survey" ticket to validate Survey ID and auto-populate it in Campaigns';
             isError = true;
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
         	 //return null;
         }
         // AU user cannot creat task when GCX User is none
         else if(gcxUser.isEmpty() && (isAUProfile || isPLAdsUser)) //NK:30/10/2019: US-0018806 //MN:01022021:US-0008970
         {
     		 msg = 'Please add GCX Users';
         	 isError = true;
         	 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
         	 //return null;
         }

        //MN:01022021:US-0008970 - Avoid showing both confirmation & error on screen
        if (showConfirm && isError) showConfirm = false; 

        //MN:01022021:US-0008970 - Return null on time when isError = true
        if (isError) return null;
         
         //NK:02/07/2019: lets create/update in one place: createUpdateTasks() 
        if (validUser && !cRecord.EBH_TaskCreated__c){
        	showConfirmNumber =  isOutReach;
        	 createUpdateTasks(); 
        }
        
        return null;    
    }
    
    private boolean isApivalue(String value, Schema.DescribeFieldResult field){
        
        //Schema.DescribeFieldResult field=Campaign.EBH_ChannelMP__c.getDescribe();
        //String s =EBH_ConstantsUtility.CAMPAIGN_CHANNEL_PHONE_OUTREACH;
        for (Schema.PicklistEntry pe : field.getPickListValues()){
            if (pe.getValue().equalsIgnoreCase(value)){
                return true;
            }
        }
        return false;
    }
    public pageReference cancel(){
        return new PageReference(reURL);        
        
    }
}