public class AssignTaskRedirectController {
    Campaign c;
    PageReference reUrl;
    public Boolean allowRedirect {get;set;}// allow page to redirect to the destination function page
    public Boolean isError {get;set;} 
    public String msg {get;set;} 
    public String msgTitle {get;set;} 
    public String msgSeverity {get;set;} 
    
    public AssignTaskRedirectController(ApexPages.StandardController controller){
        //controller.addFields(new List<String> {'Survey_ID__c'});
        c=(Campaign)controller.getRecord();
        reUrl=controller.cancel();
        
       String campaignId = c.id; 
       c = Database.query(EBH_ConstantsUtility.CMRC_QUERY); 
       allowRedirect = true;
      // system.debug('>>>c.EBH_TaskCreated__c: '+c.EBH_TaskCreated__c+' >>c.Survey_ID__c: '+c.Survey_ID__c);
       if(c.EBH_TaskCreated__c && c.Survey_ID__c <> null)
       {
       		allowRedirect = false;
       		msg = System.Label.WarningTaskAlreadyCreated +' '+ System.Label.WarningTaskAskingUpdateSurvey;
       		isError = false; //show update button
       	
       }else if(c.EBH_TaskCreated__c && c.Survey_ID__c == null)
       {
       		allowRedirect = false;
       		msg = System.Label.WarningTaskAlreadyCreated;
       		isError = true; //so hide the update button
       }
       //default
       msgSeverity = 'warning';
       msgTitle = 'Tasks already created!';
       
    }
   
    //NK:17/10/2018: EPH-6557 
    public PageReference updateSurveyIdToTasks()
    {
    	 
    	String campaignId = c.id;
    	
    	Map<Id,SObject> mapCM = new Map<Id,SObject>(Database.query(EBH_ConstantsUtility.AOC_CAMPQUERY));
    	Set<Id> setCM_ids = mapCM.keySet();
    	String soqlTask = 'Select Id from Task Where WhatId=: campaignId And EBH_CampaignMemberId__c IN:setCM_ids';
    	List<Task> listTask = Database.query(soqlTask);
    	for(Task t: listTask)
    	{
    		t.Survey_ID__c = c.Survey_ID__c;
    	}
    	isError = false;
    	if(!listTask.isEmpty())
    	{
    		try
    		{	
    			
    			update listTask;
    			
    			msgSeverity = 'confirm';
    			msgTitle = 'Update Task';
    			msg = 'Survey Id has been updated to tasks.';
    		}catch(DMLException dex)
	    	{
	    		system.debug(dex); isError = true; msgSeverity = 'error';msgTitle='Error';msg=dex.getDmlMessage(0);
	    	}
	    	catch(Exception ex)
	    	{
	    		system.debug(ex); isError = true; msgSeverity = 'error';msgTitle='Error';msg=ex.getMessage(); 
	    	}
    		
    	}else
    	{
    		msgSeverity = 'info';
			msgTitle = 'No Task';
			msg = 'No Related Task Found!';
			isError = true;
    	}
    	 
    	
    	return null;
    }
    
    public pageReference redirect(){
    	////if(!allowRedirect)return null;////stop the redirect
    	//complete redirect to new logic
        PageReference pr ;
//        if (c==null){
//            return reUrl;
//        }else
//        if (String.isBlank( c.Survey_ID__c)){
//            //AM Tasks
//            pr= Page.EBH_CampaignMemberTaskCreation;
//            
//        }else{
//            //Outreach tasks
//            pr=  Page.AssignTasks;
//        }
        
        pr=  Page.AssignTasks;
        pr.getParameters().put('id',c.id);
        return pr;
        
    }
    

}