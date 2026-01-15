/*********************************************************************************************************************************
@ Class:        TaskRelatedCampaignController
@ Version:      1.0
@ Author:       sovantheany.dim (sovantheany.dim@gaea-sys.com)
@ Purpose:      US-0000203 - Show all related tasks on Outreach record
@				Controller for aura: TaskRelatedCampaign
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.05.2020 / sovantheany.dim (sovantheany.dim@gaea-sys.com) / Created the class.
@ Change history: 28.11.2022 / Chetra Sarom / US-0012767 - Tasks tab in Campaign Outreach always crashed the browser with about 6-7K rec
*********************************************************************************************************************************/
public without sharing class TaskRelatedCampaignController {
    /************************************* CONSTANT DEFINITION *************************************************/
    
    /************************************ END OF CONSTANT DEFINITION*******************************************/
    
	/*****************************************************************************************************************************
    @ Method:   apexInit
    @ Version:  1.0
    @ Author:   sovantheany.dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  US-0000203 - Show all related tasks on Outreach record
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String recordId : Campaign Id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.05.2020 / sovantheany.dim / Created the  Method.
    @ Change history: 28.11.2022 / Chetra Sarom / US-0012767 - Tasks tab in Campaign Outreach always crashed the browser with about 6-7K rec
    *****************************************************************************************************************************/
	@AuraEnabled
	public static Map<String,Object> apexInit(String recordId) {
        
        Map<String,Object> mapResult = new Map<String,Object>();
        List<ColName> listColNameTask = new List<ColName>();
	    Set<String> setFieldNameTask = new Set<String>{'id'};
	    Map<String,String> mapFixLabel = new Map<String,String>{'Owner.Name'=>'Assigned to'};
        for(Schema.FieldSetMember f: SObjectType.Task.FieldSets.TaskRelatedCampaign.getFields())
        {
            setFieldNameTask.add(f.getFieldPath());
            if(f.getFieldPath().contains('.') && f.getFieldPath().endsWith('Name'))
        	{
        		String fId = ApexUtil.getFieldIdRef(f.getFieldPath());
        		setFieldNameTask.add(fId);
        	}
            listColNameTask.add(
                new ColName(mapFixLabel.containsKey(f.getFieldPath())?mapFixLabel.get(f.getFieldPath()):f.getLabel(),
                            f.getFieldPath(),
                            f.getType()+'')
            );
        }

        
        String soql_Task = 'Select '+String.join(new List<String>(setFieldNameTask),',')+' From Task Where WhatId =:recordId'; 
        // 28.11.2022 / Chetra Sarom / US-0012767
        String baseSOQL = 'Select '+String.join(new List<String>(setFieldNameTask),',')+' From Task'; 
        String wherecls = ' Where WhatId = '+ApexUtil.closeSQoute(recordId);
        // end 28.11.2022 / Chetra Sarom / US-0012767

        Task[] listTask = Database.query(soql_Task);
        
        mapResult.put('isOK',true); // 28.11.2022 / Chetra Sarom / US-0012767
        mapResult.put('baseSOQL',baseSOQL); // 28.11.2022 / Chetra Sarom / US-0012767
        mapResult.put('wherecls',wherecls); // 28.11.2022 / Chetra Sarom / US-0012767
        mapResult.put('listColNameTask',listColNameTask);
        mapResult.put('listTask',listTask);
        mapResult.put('sitePrefix',Site.getPathPrefix());
        //show button Assign task for only admin and GXC SUper user
        Boolean isAdmingUser = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
    	Boolean isGCXSuperUser =   EBH_CampaignTriggerHandler.checkGCXSuperUser();
    	if(isAdmingUser || isGCXSuperUser){
    		mapResult.put('showButton',true);
    	}else{
    		mapResult.put('showButton',false);
    	}
    	//End
        mapResult.put('status','ok');
        return mapResult;
    }
    @AuraEnabled
    public static Map<String,String> assignTask(String userID, List<String> taskIds){
    	return TaskRelatedController.reAssignTask(userID,taskIds);
    }
    static Map<String,String> mapLinkField = new Map<String,String>{'Subject'=>'Subject','Owner.Name'=>'OwnerId'};
    static Map<String, Set<String>> lightningToApexDataTypeMap = new Map<String, Set<String>>{
                'text' => new Set<String>{'address', 'id', 'phone', 'email', 'string', 'textarea'},
                'date' => new Set<String>{'date', 'datetime'},
                'number' => new Set<String>{'double', 'integer'},
                'percent' => new Set<String>{'percent'},
                'currency' => new Set<String>{'currency'},
                'url' => new Set<String>{'url'}
        };
    
    class ColName{
    	@AuraEnabled
    	public String label;
    	
    	@AuraEnabled
    	public String fieldName;
      
        @AuraEnabled
    	public String type;
    	
        @AuraEnabled
    	public Boolean sortable = true;
    	
    	@AuraEnabled
    	public Map<String,Object> typeAttributes;
    	
    	public ColName(String label,String fieldName,String type)
    	{
    		this.label = label;
    		this.fieldName = fieldName;
    		this.type = type.toLowerCase();
    		
	        for (String typeMap : lightningToApexDataTypeMap.keySet()) {
	            if (lightningToApexDataTypeMap.get(typeMap).contains(this.type)) {
	                this.type = typeMap;
	                break;
	            }
	        }
    		
    		if(mapLinkField.containsKey(fieldName))
    		{
    			typeAttributes = new Map<String,Object>{
    				'label' => new Map<String,Object>{'fieldName'=>mapLinkField.get(fieldName)},
    				'target'=>'_blank',
    				'tooltip'=>''
    			};
    			this.fieldName = 'link_'+mapLinkField.get(fieldName);
    			this.type = 'url';
    		} 
    	}
    }
}