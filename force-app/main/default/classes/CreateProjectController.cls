/*********************************************************************************************************************************
@ Class:        CreateProjectController
@ Version:      1.0
@ Author:       sovantheany.dim (sovantheany.dim@gaea-sys.com)
@ Purpose:      US-0015820 - Create Project Quick Action button
@				Controller for LWC: createProject
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.09.2024 / sovantheany.dim (sovantheany.dim@gaea-sys.com) / Created the class.
@ Change history:  18.09.2024 / Vimean Heng / Created a method, move lwc to apex code
*********************************************************************************************************************************/
public with sharing class CreateProjectController {
    private final static String STATUS_OK = 'ok';
	private final static String STATUS_KO = 'ko';
	public final static String ONE_OFF_RECORDTYPE = 'One_Off_Account_Management';
	private final static String INITIAL_STAGE = 'Initial';
	private final static String SECOND_STAGE = 'Second';
	private final static String FINAL_STAGE = 'Final';
	private final static set<String> SET_PROJECT_STAGE = new set<String>{INITIAL_STAGE,SECOND_STAGE,FINAL_STAGE};
    /*****************************************************************************************************************************
    @ Method:   apexInit
    @ Version:  1.0
    @ Author:   sovantheany.dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  US-0015820 - Create Project Quick Action button
	@		    Init list for component
	@		On Click of "Create Project" check
	@		if the Customer has associated One-Off Account Management Project
	@		If yes Update Project stage
	@		If no, Create new project
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: String Seller id
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 04.09.2024 / sovantheany.dim (sovantheany.dim@gaea-sys.com) /
    *****************************************************************************************************************************/
	@AuraEnabled
	public static Map<String,Object> apexInit(String recordId) {
        Map<String,Object> mapResponseData = new Map<String,Object>();
        try{
            Map<String,String> mapFixLabel = new Map<String,String>{'RecordType.Name'=>'Record Type'};
            List<ColName> listColNameContact = new List<ColName>();
            Set<String> setFieldNameCont = new Set<String>{'id'};
            populateContactColName(mapFixLabel, listColNameContact, setFieldNameCont);
            String soqlCont = 'Select '+String.join(new List<String>(setFieldNameCont),',')+' From Contact Where AccountId =:recordId and Active_Contact__c = true';
            String soqlProject = 'Select id,EBH_Stage__c From EBH_Project__c Where EBH_Seller__c =:recordId and RecordType.DeveloperName =: ONE_OFF_RECORDTYPE and EBH_Stage__c IN: SET_PROJECT_STAGE  limit 1';

            List<Contact> listContact = ApexSafe.query().doQuery(soqlCont,new Map<String, Object> {'recordId' => recordId});
			List<EBH_Project__c> listProject = ApexSafe.query().doQuery(soqlProject,new Map<String, Object> {'recordId' => recordId,'ONE_OFF_RECORDTYPE' => ONE_OFF_RECORDTYPE,'SET_PROJECT_STAGE' => SET_PROJECT_STAGE});
			String stagetoUpdate = '';
			for(EBH_Project__c pj : listProject){
				if(INITIAL_STAGE.equalsIgnoreCase(pj.EBH_Stage__c)){
					stagetoUpdate = SECOND_STAGE;
				}else if(SECOND_STAGE.equalsIgnoreCase(pj.EBH_Stage__c)){
					stagetoUpdate = FINAL_STAGE;
				}
			}
			RecordType oneOffRecordType = ApexUtil.getRecordTypeByName('EBH_Project__c', ONE_OFF_RECORDTYPE);

			mapResponseData.put('listProject',listProject);
            mapResponseData.put('listColNameContact',listColNameContact);
            mapResponseData.put('listContact',listContact);
			mapResponseData.put('oneOffRecordTypeID', oneOffRecordType.Id);
			mapResponseData.put('stagetoUpdate', stagetoUpdate);
            mapResponseData.put('sitePrefix',Site.getPathPrefix());
            mapResponseData.put('status',STATUS_OK);

        }catch (Exception e) {
			mapResponseData.put('status',STATUS_KO);
			mapResponseData.put('error',e.getMessage());
		}
        return mapResponseData;
    }
	/*****************************************************************************************************************************
    @ Method:       createProject
    @ Author:       Vimean Heng (vimean.heng@gaea-sys.com)
	@ Purpose:      US-0015879 - create project and assign isFromQuickAction = true to handle trigger
	@ Event: 		create project on customer
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	EBH_Project__c project
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.09.2024 / Vimean Heng / Created the method.
	@*****************************************************************************************************************************/
	@AuraEnabled
	public static Map<String,Object> createProject(EBH_Project__c project) {
		Map<String,Object> mapResponseData = new Map<String,Object>();
		EBH_ProjectTriggerHandler.isFromQuickAction = true;
		Database.SaveResult[] res = null;
		mapResponseData.put('status',STATUS_OK);
		try{
			res = ApexSafe.dml().doInsert(new List<SObject>{project},true);
            mapResponseData.put('id',res[0].getId());
		}catch (DMLException e) {
			mapResponseData.put('status',STATUS_KO);
			mapResponseData.put('error',e.getDMLMessage(0));
			mapResponseData.put('errorDetail',e.getStackTraceString());
		}
		return mapResponseData;
	}
    private static void populateContactColName(Map<String,String> mapFixLabel, List<ColName> listColNameContact, Set<String> setFieldNameCont){
		for(Schema.FieldSetMember f: SObjectType.Contact.FieldSets.Create_Project.getFields()){
			setFieldNameCont.add(f.getFieldPath());
			if(f.getFieldPath().contains('.') && f.getFieldPath().endsWith('Name'))
			{
				String fId = ApexUtil.getFieldIdRef(f.getFieldPath());
				setFieldNameCont.add(fId);
			}
		
			listColNameContact.add(
				new ColName(mapFixLabel.containsKey(f.getFieldPath())?mapFixLabel.get(f.getFieldPath()):f.getLabel(),
				f.getFieldPath(),
				f.getType()+'')
			);
		}
	}

    static Map<String,String> mapLinkField = new Map<String,String>{'Name'=>'Name','Account.Name'=>'AccountId','RecordType.Name'=>'RecordTypeId'};

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
    		
    		if(fieldName=='RecordType.Name')
    		{
    			this.fieldName = mapLinkField.get(fieldName);
    		}else if(mapLinkField.containsKey(fieldName))
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