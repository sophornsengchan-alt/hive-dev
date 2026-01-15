/*********************************************************************************************************************************
@ Class:          ProjectToActionRecordEditorController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0007535 Controller for Lightning: ProjectToActionsRelatedList
@ 				  AC2:
@ 				  Given that I am any User (incl. Community Users)
@ 				  When I go to Project record, eBay AU Enterprise, eBay AU SMB, EU Onboarding record types
@ 				  and on details I see new button "Update Action Status"
@ 				  and press on it and see similar flow as in LTTM Actions
@ 				  where I can mass update status of Actions
@ 				  screenshots of the proposed flow below
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the class.
@ Change history: 22.05.2023 / Chetra Sarom / US-0013378 - Initiate Call features merged with "Mass Action Update" feature in Onboarding
@                 06.02.2024 / Acmatac Seing / US-0014470 - Update it to with sharing and apexsafe to avoid security issue
@				  11.11.2024 / Sovantheany Dim /US-0016104 - Initiate call does not allow to track DMC not committed	
*********************************************************************************************************************************/
public class ProjectToActionRecordEditorController {
	//Loumang:31.07.2020
	private final static String PROJECT_SCALING_RECORD_TYPE = 'Scaling';
	private final static String ACTION_FIELD_SCALING_STAGE = 'Scaling_Stage__c';
    private static Map<String,String> mapLinkField = new Map<String,String>{'Name'=>'Name','Account.Name'=>'AccountId','RecordType.Name'=>'RecordTypeId','Owner.Name'=>'OwnerId'};
	/*****************************************************************************************************************************
    @ Method:   apexInit
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose: 	get action records which are child of project record, then pass it to lightning component.
	@			use project id to query action records.
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String project id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 03.06.2020 / Sophal Noch / Created the  Method.
    @                 06.02.2024 / Acmatac Seing / US-0014470 - Update it to with sharing and apexsafe to avoid security issue
	@				  11.11.2024 / Sovantheany Dim /US-0016104 - Initiate call does not allow to track DMC not committed
    *****************************************************************************************************************************/

    @AuraEnabled
	public static Map<String,Object> apexInit(String recordId) {
		Map<String,Object> mapResult = new Map<String,Object>();
        String projectSoql = 'Select Id, Name,RecordType.DeveloperName, Call_Outcome__c, Comments__c, Call_Attempt__c, Next_Call_Schedule_Date__c, Next_Call_Time__c,(Select Id From Actions__r limit 1) from EBH_Project__c where Id =:recordId'; 
        List<EBH_Project__c> projects = (List<EBH_Project__c>) ApexSafe.query().doQuery(projectSoql,new Map<String, Object> {'recordId' => recordId});

        if(projects[0].Actions__r.isEmpty()) {
			mapResult.put('project',projects[0]);
        	mapResult.put('status','ko');
        	mapResult.put('error','No related actions.');
        }else {
	        Map<String,String> mapFixLabel = new Map<String,String>{'RecordType.Name'=>'Record Type','Owner.Name'=>'Owner'};
	        List<ColName> listColNameAction = new List<ColName>();
	        Set<String> setFieldNameAction = new Set<String>{'id'};

	        for(Schema.FieldSetMember f: SObjectType.Action__c.FieldSets.UpdateActionStatus.getFields()){
				if(projects[0].RecordType.DeveloperName != PROJECT_SCALING_RECORD_TYPE && f.getFieldPath() == ACTION_FIELD_SCALING_STAGE){
					continue;
				}
				setFieldNameAction.add(f.getFieldPath());
				if(f.getFieldPath().contains('.') && f.getFieldPath().endsWith('Name')){
					String fId = ApexUtil.getFieldIdRef(f.getFieldPath());
					setFieldNameAction.add(fId);
				}
				String filedLabel = mapFixLabel.containsKey(f.getFieldPath())?mapFixLabel.get(f.getFieldPath()):f.getLabel();
				listColNameAction.add(
					new ColName(filedLabel,
					f.getFieldPath(),
					f.getType()+'')
				);
	        }
	        
	        String soql_action = ' Select '+String.join(new List<String>(setFieldNameAction),',')+' From Action__c Where Project__c=:recordId';
        	Action__c[] listActions = ApexSafe.query().doQuery(soql_action,new Map<String, Object> {'recordId' => recordId});
        	mapResult.put('listColNameAction',listColNameAction);
			mapResult.put('listActions',listActions);
			mapResult.put('actionOutComePicklists',ApexUtil.getPicklistValues(Action__c.Action_Outcome__c));//TH:US-0016104:Get picklist values for Action_Outcome__c
			mapResult.put('project',projects[0]);
        	mapResult.put('status','ok');
        }
        return mapResult;
	}

	/*****************************************************************************************************************************
    @ Method:   apexSave
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose: 	update action records which are modified from lightning component
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      list record of actions
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 03.06.2020 / Sophal Noch / Created the  Method.
	@ Change history: 22.05.2023 / Chetra Sarom / US-0013378 - Initiate Call features merged with "Mass Action Update" feature in Onboarding
    @                 06.02.2024 / Acmatac Seing / US-0014470 - Update it to with sharing and apexsafe to avoid security issue
    *****************************************************************************************************************************/
	@AuraEnabled
	public static Map<String,Object> apexSave(List<Action__c> listActions,EBH_Project__c project) {
		Map<String,Object> mapResult = new Map<String,Object>();
		try {
			ApexSafe.dml().doUpdate(listActions, true);
			ApexSafe.dml().doUpdate(new List<EBH_Project__c>{project}, true);
			mapResult.put('status','ok');
		}catch(DMLException dex){	
            mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}catch(Exception ex){
            mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());	
        }
		return mapResult;
	}

    private class ColName{
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
    	
    	public ColName(String label,String fieldName,String type) {
    		this.label = label;
    		this.fieldName = fieldName;
    		this.type = type.toLowerCase();

    		if(fieldName=='RecordType.Name'){
    			this.fieldName = mapLinkField.get(fieldName);
    		}else if(mapLinkField.containsKey(fieldName)){
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