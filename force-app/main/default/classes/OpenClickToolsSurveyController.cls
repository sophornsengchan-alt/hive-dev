/*****************************************************************************************************************************
    @ Calss:   OpenClickToolsSurveyController
    @ Version:  1.0
    @ Author:   DHE
    @ Purpose:  US-7157	: Class for redirecting to an Oubound Survey in Clicktools
    @TEST CLASS : RecordInboundCallControllerTest
    ------------------------------------------------------------------------------------------------------------------------------    
    @ Change history: ?/?/? / DHE / US-7157
    @               : 2020-06-29/ Vadhanak Voun/  US-0007759 - Hypercare Bug- AU GCX Clicktools script not launching
    @                   :Convert to lighting component controller to use navigateToURL
    *****************************************************************************************************************************/
public without sharing class OpenClickToolsSurveyController {
        
    private static List<String> lfields = new list<string> {'OwnerId','WhoId','EBH_Account__c','Task_Owner_Name__c','Contact_Name__c','Survey_ID__c','EBH_CampaignMemberId__c','Call_attempts__c',
            'Account_Name__c','Related_Campaign__r.name','Campaign_Country__c','EBH_Account__r.EBH_OracleID__c','Related_Campaign__c'};
   

    /*****************************************************************************************************************************
    @ Method:   apexInitActionTemplateList
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0007443 - [EU & AU] Create Actions
	@		    Init list for component
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String projectId: current project id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 2020-05-14 / DHE / RENAMe the method
    @               : 2020-06-29/ Vadhanak Voun/  US-0007759 - Hypercare Bug- AU GCX Clicktools script not launching
    @                   :Convert to lighting component to use navigateToURL
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexInitClicTool(String taskId){ 
        
        Map<String,Object> mapResult = new Map<String,Object>();
        mapResult.put('status','ok');
        try
        {
            String taskSoql = 'Select Id,'+String.join(lfields, ',') +' From Task Where Id=:taskId';
            System.debug('>>>taskSoql: '+taskSoql);
            Task tsk = Database.query(taskSoql);
            
            EBH_OutboundLink__c outboundlink = EBH_OutboundLink__c.getInstance();
            List<CampaignMember> relatedCM = [select id,Campaign_Related_Seller_Details__c from CampaignMember where id = :tsk.EBH_CampaignMemberId__c];
            if (relatedCM.isempty())
            {
                mapResult.put('status','ko');
                mapResult.put('error','There is a problem with the related Campaign Member record ' + tsk.EBH_CampaignMemberId__c);
                
            }else if(outboundlink.Clicktools_Outbound_Survey__c==null)
            {            
                mapResult.put('status','ko');
                mapResult.put('error','Survey Id not defined in Custom Settings');
            }else
            {                 
                String surveyId=outboundlink.Clicktools_Outbound_Survey__c;
                String epilogueSurvey = outboundlink.Clicktools_Epilogue_Survey__c;
                String campaignRelatedDetails =(relatedCM.isempty()?'':relatedCM[0].Campaign_Related_Seller_Details__c);
                campaignRelatedDetails = CampaignRelatedDetails!=null? EncodingUtil.urlEncode(CampaignRelatedDetails, 'UTF-8'):'';
                String clickToolsUrl ='https://app.clicktools.com/go?iv=' + surveyId;
                clickToolsUrl+='&q1=' + tsk.OwnerId;     
                clickToolsUrl+='&q2='+ tsk.WhoId;
                clickToolsUrl+='&q3=' + tsk.EBH_Account__c;
                clickToolsUrl+='&q4=' +tsk.Task_Owner_Name__c ; 
                clickToolsUrl+='&q5=' + (tsk.Contact_Name__c!=null?tsk.Contact_Name__c:'') ; 
                clickToolsUrl+='&q6=' + tsk.Id ; 
                clickToolsUrl+='&q7=' +tsk.Survey_ID__c; 
                clickToolsUrl+='&q8=' +tsk.EBH_CampaignMemberId__c; 
                clickToolsUrl+='&q9=' + tsk.Call_attempts__c;
                clickToolsUrl+='&language=' + tsk.Campaign_Country__c; 
                clickToolsUrl+='&q11=' + tsk.EBH_Account__r.EBH_OracleID__c;    
                clickToolsUrl+='&q12=' + tsk.Account_Name__c;    
                clickToolsUrl+='&q13=' + tsk.Related_Campaign__r.name;    
                clickToolsUrl+='&q14=' + tsk.Related_Campaign__c;    
                clickToolsUrl+='&q15=' + epilogueSurvey;     
                clickToolsUrl+='&q16=' + CampaignRelatedDetails;          

                mapResult.put('clickToolsUrl',clickToolsUrl);
            }
        }
    	catch(Exception ex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
    	}
        
         return mapResult;
    }
    

}