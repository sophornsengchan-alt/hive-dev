public without sharing class  RecordInboundCallController {

    public Account  seller        					{ set; get; }
    public List<SelectOption> campaignsFiltered 	{ set; get; }
    public String Campaign 							{ set; get; }


    private final static String SELLER_RECORD_TYPE = 'EBH_Seller';
    private final static String MANAGED_TYPE_LTTM_PLUS = 'LTTM Plus';
    private final static String MANAGED_TYPE_OTHER_MANAGED = 'Others Managed';
    private final static String MANAGED_SEGMENT_CONCIERGE = 'Concierge';

    private final static String RECTYPE_BS_LTTM = 'LTTM';

    private final static String INBOUND_CAMPAIGN_STEP = 'Inbound Campaign';
    private final static String LTTM_PLUS_CAMPAIGN_STEP = 'LTTM Plus Campaign';

    public Boolean isRecordInboundStep { set; get; }
    public Boolean isInboundCampaignStep { set; get; }
    public Boolean isLttmPlusCampignStep { set; get; }
    
    public String currentStep{ set; get; }

    public Id bobSellerId { set; get; }
    
    public ApexPages.StandardController controller;
    
    
    private void populateCampaigns(){
        campaignsFiltered= new List<SelectOption>();
        //NK:11/01/2019:EPH-6842:
        //AC5: When I go to Seller record and click on Record Inbound Call
        //I can only see Inbound Outreaches with status "Campaign Running" in the list of available Inbound Outreaches. 
        //for (Campaign c: [select id,name from campaign where inbound_call__c=true and survey_id__c!=null and RecordType.DEveloperName=:EBH_ConstantsUtility.CMRC_CAMPRECORDTYPE]){//NK:31/10/2018: filter to sub campaign
        for (Campaign c: [select id,name from campaign where inbound_call__c=true and survey_id__c!=null and RecordTypeId =:EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID AND Status=:EBH_ConstantsUtility.CMRC_EXECUTION]){
            campaignsFiltered.add(new SelectOption(c.id,c.name));
        }
        
    }
    
    /*****************************************************************************************************************************
    @ Method/Construtor:   RecordInboundCallController
    @ Version:  2.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose: 	US-0007888 Show differently user interface depend on Customer Record Type and Managed Type pick list value
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    ApexPages.StandardController controller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Event:        When vf RecordInboundCall page loads.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.06.2020 / Sophal Noch / Update the  Method.
    @               : 19.10.2020 / Vadhanak Voun / US-0008431 - [Hyper care] LTTM Plus - Error message displaying when recording Inbound call for LTTM Plus Seller
    @               : 19.10.2021 / Mony Nou      / US-0008800 - [LTTM Plus] Enable LTTM Plus Concierge team to record Inbound calls for sellers who require concierge service
    *****************************************************************************************************************************/
    public RecordInboundCallController(ApexPages.StandardController controller) {


        List<String> lfields = new list<string> {'Name','Primary_Contact_Name__c','Primary_Contact__c','Primary_Contact_Email__c','EBH_OracleID__c','RecordType.DeveloperName','Managed_Type__c','EBH_BOBSegment__c'};
            if(!test.isRunningTest()){
            controller.addFields(lfields);    
            }

        seller=(ACcount)controller.getRecord();

        
        isLttmPlusCampignStep = false;
        if(seller.RecordType.DeveloperName == SELLER_RECORD_TYPE && (seller.Managed_Type__c == MANAGED_TYPE_LTTM_PLUS || (seller.Managed_Type__c == MANAGED_TYPE_OTHER_MANAGED && seller.EBH_BOBSegment__c==MANAGED_SEGMENT_CONCIERGE))){
            
            // US-0007888 Show Page where user have choice to choice between Inbound Campaign UI or LTTM Plus Campaign UI

            isRecordInboundStep = true;
            isInboundCampaignStep = false;
            

            List<BoB_Seller__c> bobSeller = [SELECT Id FROM BoB_Seller__c WHERE Seller__c =: seller.Id AND RecordType.DeveloperName =:RECTYPE_BS_LTTM AND Active__c =true Order BY Id ASC Limit 1];
            if(!bobSeller.isEmpty()){
                bobSellerId = bobSeller[0].Id;
            }


        }else{

            // US-0007888 Inbound Campaign Step

            isRecordInboundStep = false;
            isInboundCampaignStep = true;
        }
            
        currentStep = INBOUND_CAMPAIGN_STEP;
            
        this.controller=controller;

        
        populateCampaigns();
        
    }
    

    /*****************************************************************************************************************************
    @ Method:   nextStep
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose: 	US-0007888 show Inbound Campaign step or LTTM Plus Campaign depending on what user select in selection in the page
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Event:        When user click button Next.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / Create the  Method.
    *****************************************************************************************************************************/
    public void nextStep(){
        isRecordInboundStep = false;
        if(currentStep == INBOUND_CAMPAIGN_STEP){
            isInboundCampaignStep = true;
            isLttmPlusCampignStep = false;
        }else if(currentStep == LTTM_PLUS_CAMPAIGN_STEP){
            isInboundCampaignStep = false;
            isLttmPlusCampignStep = true;
        }
    }

    /*****************************************************************************************************************************
    @ Method:   getStep
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose: 	US-0007888 initialize options in Selection component of the page
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Event:        When vf RecordInboundCall page loads.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.06.2020 / Sophal Noch / Create the  Method.
    *****************************************************************************************************************************/
    public list<SelectOption> getStep()
    {
        list<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption(INBOUND_CAMPAIGN_STEP, INBOUND_CAMPAIGN_STEP));
        options.add(new SelectOption(LTTM_PLUS_CAMPAIGN_STEP, LTTM_PLUS_CAMPAIGN_STEP));
        return options;
    }
    
    public pagereference cancel(){
        return controller.cancel();
    }
    public pagereference startsurvey(){
        PageReference pr = null;
        if (Campaign==null){
            
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.ERROR, System.Label.Error_Not_Selecting_Campaign_Before_Starting_Survey));
            return pr;
        }else{
            
            
            

			            Campaign c = [select id,Survey_ID__c from campaign where id=:Campaign];            
            User currentUser = ApexUtil.getCurrentUser();
            
            /*
Subject: Inbound Call
Related to: linked to the selected Campaign and linked to the Primacy Contact (as defined in EPH-6581)
Assigned to: "myself"
And I will be automatically redirected to the corresponding click tool survey on the selected Campaign record

https://app.clicktools.com/go?iv=3jmnwz05mxl57 
&q1={!Task.OwnerId} 
&q2={!Task.Who} 
&q3={!Task.EBH_Account__c} 
&q4={!Task.Task_Owner_Name__c} 
&q5={!Task.Contact_Name__c} 
&q6={!Task.Id} 
&q7={!Task.Survey_ID__c} 
&q8={!Task.EBH_CampaignMemberId__c} 
&q9={!Task.Call_attempts__c}
****
updated 29-10-2018
https://app.clicktools.com/go?iv=2jhwe89besswt
&q1={!UserId}
&q2={!PrimaryContactId}
&q3={!AccountId}
&q4={!User.FullName}
&q5={!PrimaryContact.FullName}
&q6={!PrimaryContact.Email}
&q7={!SurveyId}
&q8={!CampaignId}
*/
            //DHE 2019-01-11
            //read survey Id from Custom settings
            //Map<String,ClicktoolsSurvey__c> ClickTools = ClicktoolsSurvey__c.getAll();
            EBH_OutboundLink__c outboundlink=EBH_OutboundLink__c.getInstance();

            if (outboundlink.Clicktools_Inbound_Survey__c==null){
                   ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Survey Id not defined in Custom Settings'));
                return null;
    
            }
            //String SurveyId=ClickTools.get(EBH_ConstantsUtility.OUTREACH_SURVEY).outreach_survey__c;
            String SurveyId=outboundlink.Clicktools_Inbound_Survey__c;
            
            //String clickToolsUrl='https://app.clicktools.com/go?iv=2jhwe89besswt';
            String clickToolsUrl='https://app.clicktools.com/go?iv=' + SurveyId;
            clickToolsUrl+='&q1=' + currentUser.id;	 
            clickToolsUrl+='&q2='+ seller.primary_contact__c; 
            clickToolsUrl+='&q3=' + seller.ID;
            clickToolsUrl+='&q4=' +currentUser.name ; 
            clickToolsUrl+='&q5=' + seller.Primary_Contact_Name__c ; 
            clickToolsUrl+='&q6=' + seller.Primary_Contact_Email__c ; 
            clickToolsUrl+='&q7=' +c.survey_id__c; 
            clickToolsUrl+='&q8=' +c.ID; 
            clickToolsUrl+='&q9=' + seller.EBH_OracleID__c; //2020-01-02 DHE Added Oracle ID
            clickToolsUrl+='&q10=' + seller.name; //2020-01-15 DHE Added Seller Name
            
            
            pagereference returnPage= new pagereference(clickToolsUrl);
            pr=returnPage;
        }
        return pr;
    }

}