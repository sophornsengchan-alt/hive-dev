/*********************************************************************************************************************************
@ Change history: 16.July.2020 / Acmatac SEING / Continue US-0007818 Clicktools Survey for GCX Portal User
*********************************************************************************************************************************/
public with sharing class NPSSurvey_Homepage_Component_Controller {
    public User u {get;set;} 
    public string randomNumber {get;set;}
    public boolean OpenTheSurvey{get{ return ShowSurvey();}set;}
    public String surveyURL {get{
        //updateNPSUser();
        u=getU();
        System.debug('Updating user last nps' +u.Last_NPS_Survey_Send_Date__c);
        EBH_OutboundLink__c outboundlink=EBH_OutboundLink__c.getInstance();
        SurveyURL = 'https://app.clicktools.com/go?iv=' + outboundlink.NPS_Survey_URL__c
            + '&q1='+ u.id 
            + '&q2='+ u.name 
            + '&q3='+ u.profile.name
            + '&q4='+ u.Cost_Center__c;
        return SurveyURL;
    }set;} 
    public NPSSurvey_Homepage_Component_Controller() {
        u=getU();
    }

    public void updateNPSUser(){
        u=getU();
        u.Last_NPS_Survey_Send_Date__c=system.now();
        update u;
    }

    public static set<String> excludedProfiles = new set<STring>{
      'System Administrator',
      'Business Admin',
        'System Administrator - Limited Privileges',
        'Salesforce QA Platform User',
        'Salesforce Platform User'
    };
    
    /* @changes 2020-03-27 Exclude System admin and dev team from the survey
    */
    private static Set<String> Excluded_Email_Domains = new Set<string>{'gaea-sys'};

    public boolean ShowSurvey(){
        //I will think in a number , and if the randomizer guess the number, the survey will be opened
        Integer SecretInteger=1;
        Integer RandomizeNumber = Integer.valueof((Math.random() * Integer.valueOf(Label.NPS_NUMBER )))+1;
        //for testing
        if (ApexUtil.runningInASandbox()){
            RandomizeNumber=SecretInteger;    
        }
        System.debug('RandomizeNumber= ' + RandomizeNumber);
        DateTime rightnow= Datetime.now();
        Integer numberOfDays=Integer.valueOf(Label.NPS_Number_of_Days);
        DateTime NinetyDaysAgo=rightnow.addDays(-numberOfDays);
        return (SecretInteger==RandomizeNumber &&
                (u.Last_NPS_Survey_Send_Date__c==null || u.Last_NPS_Survey_Send_Date__c <=NinetyDaysAgo)
                && !excludedProfiles.contains(u.profile.name)
                && !Excluded_Email_Domains.contains(getEmailDomain()));
    }
    private String getEmailDomain(){
        return u.email.substringbetween('@','.');                
        
    }

    //@AMT, July,16,20
    private static String getEmailDomain(String email){
        return email.substringbetween('@','.');                
        
    }
    private User getU(){
        u=[select id,Last_NPS_Survey_Send_Date__c,Cost_Center__c,profile.name ,name,Email from user where id =: userinfo.getUserId()];
        return u;
    }


    /*********************************************************************************************************************************
    @ Method:         apexInitClicTool
    @ Author:         David Herrero
    @ Purpose:        Aura: OpenNPSSurvey.cmp, US-0007818 Clicktools Survey for GCX Portal User
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.July.2020 / David Herrero / Created the method.
                        16.July.2020 / Acmatac SEING / Continue David job.
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexInitClicTool(){ 
        //System.debug('Entering in apex Init Click Tool');
        Map<String,Object> mapResult = new Map<String,Object>();
        mapResult.put('status','ok');
        try
        {
            User u = [SELECT Id, Last_NPS_Survey_Send_Date__c, Cost_Center__c, Profile.name, Name, Email From User WHERE Id =: userinfo.getUserId()];
            DateTime rightnow = Datetime.now();
            Integer numberOfDays = Integer.valueOf(Label.NPS_Number_of_Days);
            DateTime NinetyDaysAgo = rightnow.addDays(-numberOfDays);
            EBH_OutboundLink__c outboundlink = EBH_OutboundLink__c.getInstance();
            
            if(outboundlink.NPS_GCX_Survey__c==null)
            {            
                mapResult.put('status','ko');
                mapResult.put('error','Survey Id not defined in Custom Settings');
            }else if(!(u.Last_NPS_Survey_Send_Date__c==null || u.Last_NPS_Survey_Send_Date__c <=NinetyDaysAgo) 
                       || NPSSurvey_Homepage_Component_Controller.excludedProfiles.contains(u.Profile.name) 
                       || Excluded_Email_Domains.contains(getEmailDomain(u.Email)))
            {
                mapResult.put('status','ko');
                mapResult.put('error','User is not allowed to see the survey');
            }else
            {                 
                // Update user
                u.Last_NPS_Survey_Send_Date__c=system.now();
                update u;
                
                String clickToolsUrl = 'https://app.clicktools.com/go?iv=' + outboundlink.NPS_GCX_Survey__c
                + '&q1='+ u.id 
                + '&q2='+ u.name 
                + '&q3='+ u.profile.name
                + '&q4='+ u.Cost_Center__c;       

                mapResult.put('clickToolsUrl',clickToolsUrl);
                //System.debug('Everything went OK , =>' + mapResult + '\r mapresult=' + mapResult.get('clickToolsUrl'));
            }
        }
    	catch(Exception ex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
    	}
        
        //System.debug ('We are going to return = ' + mapResult);
        return mapResult;
    }
}