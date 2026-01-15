/*********************************************************************************************************************************
@ Class:         ActionCreationController
@ Version:       1.0
@ Author:        vadhanak.voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       US-0007443 - [EU & AU] Create Actions
@				Controller for aura: ActionCreation
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.04.2020 / vadhanak.voun (vadhanak.voun@gaea-sys.com) / Created the class.
@ Change history: 03.07.2023/ Sophal Noch (sophal.noch@gaea-sys.com) / US-0013131 - SUSU - Bulk Action creation for Multiple Projects
@				: 18.07.2024 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / US-0015542 - Add Project Type as criteria for action template
@				: 05.09.2024 / vadhanak voun (vadhanak.voun@gaea-sys.com) / US-0015822 - Seller Clinics - Buttons on the Project Record
*********************************************************************************************************************************/
public without sharing class ActionCreationController{
	
	public Boolean isRedirect  {get;set;}  // 03.07.2023/ Sophal Noch / US-0013131
	public String  projectIds   {get;set;} // 03.07.2023/ Sophal Noch / US-0013131

	public static final String RECTYPE_ACTION_TEMPLATE_SCALING = 'Scaling';
	public final static String BATCH_LEAD_SQL = 'SELECT Project_Type__c, RecordTypeId,RecordType.DeveloperName,LeadSegment__c,Site__c,OwnerId,Lead__r.Site__c,Lead__r.LeadSegment__c,EBH_Seller__c, EBH_Seller__r.Primary_Contact__r.Email, Lead__c, Lead__r.FirstName, Lead__r.LastName, Lead__r.Title, Lead__r.Email, Lead__r.Phone, Lead__r.MobilePhone, Lead__r.Street, Lead__r.City, Lead__r.Country, Lead__r.PostalCode, Lead__r.State, Lead__r.EBH_PreferredContactTime__c FROM EBH_Project__c';
	public static final String SOQL_ACTION = 'Select Id,Name,Action_Outcome__c,Action_Template__c,Completed_Date__c,Description__c,Due_Date__c,Project__c,RecordTypeId,Required__c,Status__c, Detailed_Description__c From Action__c ';
	public static final String SOQL_ACTION_TEMPLATE  = 'Select Project_Type__c,Id,Name,Active__c,Country__c,Description__c,Group__c,Lead_Segment__c,RecordTypeId,RecordType.Name,RecordType.DeveloperName, Required__c, Detailed_Description__c From Action_Template__c '; // 03.07.2023/ Sophal Noch / US-0013131 : add RecordType.DeveloperName to SOQL_ACTION_TEMPLATE
	public static final String RECTYPE_ACTION_TEMPLATE_ACQ='Acquisition';
	private static final String KICKSTARTER = 'Kickstarter';//TH:US-0015542
	private static final String EUONBOARDING_RECORDTYPE  = 'EUOnboarding';//TH:US-0015542
	private static final String SITE_AU = 'AU';//TH:US-0015542
	private static final String LEADSEGMENT_SMB = 'SMB';//TH:US-0015542
	private static final String PROJECT_SQL = 'SELECT RecordType.DeveloperName FROM EBH_Project__c WHERE Id = :listProjectId';
	
	//NK:05/09/2024:US-0015822
	private static final String RECTYPE_ONE_ACC_MGT = 'One_Off_Account_Management';	
	private static final String RECTYPE_ACTION_TEMPLATE_ACCMGT = 'LTTM'; //Account Management former: LTTM
	private static final String TEMPLATE_MANAGEDSEGMENT_ONEOFACCMGT = 'One-Off Account Management';
	
	/*****************************************************************************************************************************
    @ Constructor:  ActionCreationController
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com) 
    @ Purpose:  US-0013131 - SUSU - Bulk Action creation for Multiple Projects
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: ApexPages.StandardSetController from project list view
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 03.07.2023 /  Sophal Noch / Create Constructor
    *****************************************************************************************************************************/
	public ActionCreationController(ApexPages.StandardSetController controller){

		List<EBH_Project__c> listProjects = controller.getSelected();
        List<String> tmpIds = new List<Id>();
        for(EBH_Project__c pro: listProjects){
            tmpIds.add(pro.Id);
        }
        projectIds = (tmpIds.isEmpty())?'':String.join(tmpIds, ',');
		isRedirect = true;
	}
	
	/*****************************************************************************************************************************
    @ Method:   apexInitActionTemplateList
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0007443 - [EU & AU] Create Actions
	@		    Init list for component
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String projectId: current project id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.04.2020 / Vadhanak Voun / Created the  Method.
	@ Change history: 04.04.2022 / Chetra Sarom  / US-0011551 - "Detail Description" field to be updated on Action Creation	
	@ Change history: 03.07.2023/ Sophal Noch / US-0013131 - SUSU - Bulk Action creation for Multiple Projects
	@				: 18.07.2024 / Sovantheany Dim / US-0015542 - Add Project Type as criteria for action template
	@				: 05.09.2024 / vadhanak voun (vadhanak.voun@gaea-sys.com) / US-0015822 - Seller Clinics - Buttons on the Project Record
    *****************************************************************************************************************************/
	 @AuraEnabled
	public static Map<String,Object> apexInitActionTemplateList(List<String> listProjectId, List<String> listRecTypeName) // 03.07.2023/ Sophal Noch / US-0013131 change params to list
	 {
	 	Map<String,Object> mapResult = new Map<String,Object>();
	 	
		//  03.07.2023/ Sophal Noch / US-0013131 : start - not using single project anymore :
		String recAcqa = RECTYPE_ACTION_TEMPLATE_ACQ;

		// 03.07.2023/ Sophal Noch / US-0013131 : start - make component support multiple projects :
		String recScale = RECTYPE_ACTION_TEMPLATE_SCALING;

		String sWhereProject = ' Where Id IN:listProjectId';
		Set<String> setLeadCountry = new Set<String>();
		Set<String> setLeadSeg = new Set<String>();
		Boolean hasKickStarter = false;//TH:US-0015542
		Boolean isNotKickStarter = false;//TH:US-0015542

		List<EBH_Project__c> listProject = ApexSafe.query().doQuery(BATCH_LEAD_SQL+sWhereProject,new Map<String, Object> {'listProjectId' => listProjectId});
		for(EBH_Project__c project : listProject){
			//TH:US-0015542
			if(project.RecordType.DeveloperName == EUONBOARDING_RECORDTYPE && project.Site__c == SITE_AU && project.LeadSegment__c == LEADSEGMENT_SMB && KICKSTARTER.equalsIgnoreCase(project.Project_Type__c)){
				hasKickStarter = true;
			}else{
				isNotKickStarter = true;
				setLeadCountry.add(project.Site__c);
				setLeadSeg.add(project.LeadSegment__c);
			}
		}

		//  03.07.2023/ Sophal Noch / US-0013131 : start - make query support multiple projects
		Boolean hasScaleRT = false;
		Boolean hasAcqaRT = false;
		Boolean hasOneAccMgtRT = false;	//NK:05/09/2024:US-0015822
		for(String rt : listRecTypeName){

			if(rt == recScale){hasScaleRT = true;}
			else if(rt == RECTYPE_ONE_ACC_MGT)//NK:05/09/2024:US-0015822
			{
				hasOneAccMgtRT = true; 
			}	
			else{hasAcqaRT = true;}

			if(hasScaleRT && hasAcqaRT && hasOneAccMgtRT) {break;}
		}
		List<String> listCondition = new List<String>();

		
		if(hasAcqaRT){
			//TH:US-0015542: if some Project selected have kickstarter , then we will include filter by project type = kickstarter
			if(hasKickStarter) {listCondition.add('(RecordType.DeveloperName='+ApexUtil.closeSQoute(recAcqa)+' AND Country__c ='+ApexUtil.closeSQoute(SITE_AU)+' AND Lead_Segment__c ='+ApexUtil.closeSQoute(LEADSEGMENT_SMB)+' AND Project_Type__c ='+ApexUtil.closeSQoute(KICKSTARTER)+')');}
			if(isNotKickStarter) {listCondition.add('(RecordType.DeveloperName='+ApexUtil.closeSQoute(recAcqa)+' AND Country__c IN:setLeadCountry AND Lead_Segment__c IN:setLeadSeg AND Project_Type__c != '+ApexUtil.closeSQoute(KICKSTARTER)+')');}
		}
		if(hasScaleRT){ listCondition.add('(RecordType.DeveloperName ='+ApexUtil.closeSQoute(recScale)+' AND Country__c IN :setLeadCountry)'); }
		//NK:05/09/2024:US-0015822 
		if(hasOneAccMgtRT)
		{
			listCondition.add('(RecordType.DeveloperName ='+ApexUtil.closeSQoute(RECTYPE_ACTION_TEMPLATE_ACCMGT)+' AND Managed_Segment__c=:TEMPLATE_MANAGEDSEGMENT_ONEOFACCMGT AND Country__c IN :setLeadCountry)');
		}

		String finalCondition = String.join(listCondition,' OR ');

		String sWhereTemplate = ' Where Active__c=true And (' + finalCondition + ') Order by Name';

		String sWhereAction  = ' Where Project__c IN:listProjectId';
		//  03.07.2023/ Sophal Noch / US-0013131 : - stop

	 	List<Template> listPossibleActions = new List<Template>();
	 	List<Template> listSelectedAction = new List<Template>();
	 	Set<String> setExisting = new Set<String>();
		List<Action__c> listAction = ApexSafe.query().doQuery(SOQL_ACTION+sWhereAction,new Map<String, Object> {'listProjectId' => listProjectId});
	 	for(Action__c ac:listAction)
	 	{
	 		setExisting.add(ac.Action_Template__c);
	 	}
	 	system.debug('::::sWhereTemplate: '+sWhereTemplate);
		//  03.07.2023/ Sophal Noch / US-0013131 :
		 List<Action_Template__c> listTemplate = ApexSafe.query().doQuery(SOQL_ACTION_TEMPLATE+sWhereTemplate,new Map<String, Object> {'setLeadCountry' => setLeadCountry,'setLeadSeg' => setLeadSeg,'TEMPLATE_MANAGEDSEGMENT_ONEOFACCMGT'=>TEMPLATE_MANAGEDSEGMENT_ONEOFACCMGT});//NK:05/09/2024:US-0015822 
	 	
	 	for(Action_Template__c acTempl: listTemplate)
	 	{
	 		Template tmp = new Template(acTempl);
	 		tmp.isRequired = acTempl.Required__c;
	 		tmp.isExisting = setExisting.contains(acTempl.Id);
	 		tmp.template = acTempl;
	 		if(tmp.isRequired || tmp.isExisting)
	 		{
	 			listSelectedAction.add(tmp);
	 		}else
	 		{
	 			listPossibleActions.add(tmp);
	 		}
	 	}
	 	
	 	mapResult.put('status','ok');
	 	mapResult.put('listPossibleActions',listPossibleActions);
	 	mapResult.put('listSelectedAction',listSelectedAction);
	 	
	 	return mapResult;
	 }
	 
	 
	/*****************************************************************************************************************************
    @ Method:   apexSaveActions
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0007443 - [EU & AU] Create Actions
	@		    Save selected new action templates
	@			Action. Name = Action Template. Name
	@		·   Action. Project = Lookup (project) – project from which process was triggered
	@		·   Action.Owner = Project. Owner
	@		·   Action. Due Date = Today + Action template. Number of dates required
	@		·   Action.Seller Name = Project. seller
	@		·   Action (Lookup) = Action Template
	@		·   Action. Description = Action Template. Description
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String projectId: current project id, list of selected template to be assigned
    @------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.04.2020 / Vadhanak Voun / Created the  Method.
	@ Change history: 04.04.2022 / Chetra Sarom  / US-0011551 - "Detail Description" field to be updated on Action Creation
	@				  22.04.2022 / Acmatac SEING / US-0011630 - Pro-Trader/aSelleration/Scaling/Acquisition: Tie Actions Record to Customer Record
	@				  03.07.2023/ Sophal Noch / US-0013131 - SUSU - Bulk Action creation for Multiple Projects	
    *****************************************************************************************************************************/
	 @AuraEnabled
	//  public static Map<String,Object> apexSaveActions(String projectId,List<String> selectedNewTemplates)
	public static Map<String,Object> apexSaveActions(List<String> listProjectId,List<String> selectedNewTemplates) //  03.07.2023/ Sophal Noch / US-0013131 change params to list
	 {
	 	Map<String,Object> mapResult = new Map<String,Object>();
		//  03.07.2023/ Sophal Noch / US-0013131 make where condition works with multiple projects
		String sWhereProject = ' Where Id IN:listProjectId';

		//@ Change history: 04.04.2022 / Chetra Sarom  / US-0011551
		Set<String> validProjectRecordType = new Set<String>{
			'Scaling',
			'EUOnboarding',
			'eBayAUSMB',
			'eBayAUEnterprise'
		};
		// US-0011551 end

		// 22.04.2022 / Acmatac SEING / US-0011630
		Set<String> validProjectRecordType_4PopulateManagedSeller = new Set<String>{
			'eBayAUSMB',
			'EUOnboarding',
			'Scaling'
		};

		// 03.07.2023/ Sophal Noch / US-0013131 : use list to retrive multiple projects
		List <EBH_Project__c> listProject = ApexSafe.query().doQuery(BATCH_LEAD_SQL+sWhereProject,new Map<String, Object> {'listProjectId' => listProjectId});
		
	 	String sWhereTemplate = ' Where Id IN:selectedNewTemplates';
	 	Map<Id,Action_Template__c> mapTemplate = new Map<Id,Action_Template__c>((List<Action_Template__c>)ApexSafe.query().doQuery(SOQL_ACTION_TEMPLATE+sWhereTemplate,new Map<String, Object> {'selectedNewTemplates' => selectedNewTemplates}));
	 	
	 	List<Action__c> listActionToCreate = new List<Action__c>();
		for(EBH_Project__c project : listProject){ // 03.07.2023/ Sophal Noch / US-0013131
			for(String templateId : selectedNewTemplates)
			{

				Action_Template__c actionTemplate = mapTemplate.get(templateId); // 03.07.2023/ Sophal Noch / US-0013131

				// 03.07.2023/ Sophal Noch / US-0013131 : stop create or update action if action template and project are not matched
				if(actionTemplate.RecordType.DeveloperName == RECTYPE_ACTION_TEMPLATE_ACQ && (project.RecordType.DeveloperName == RECTYPE_ACTION_TEMPLATE_SCALING || actionTemplate.Country__c != project.Site__c ||  actionTemplate.Lead_Segment__c != project.LeadSegment__c)){continue;}
				if(actionTemplate.RecordType.DeveloperName == RECTYPE_ACTION_TEMPLATE_SCALING && (project.RecordType.DeveloperName != RECTYPE_ACTION_TEMPLATE_SCALING || actionTemplate.Country__c != project.Site__c)){continue;}
				//TH:US-0015542: if project type are difference and one of them is kickstarter then we will not create action
				if(actionTemplate.RecordType.DeveloperName == RECTYPE_ACTION_TEMPLATE_ACQ && project.Site__c == SITE_AU && project.LeadSegment__c == LEADSEGMENT_SMB  && project.Project_Type__c != actionTemplate.Project_Type__c && (KICKSTARTER.equalsIgnoreCase(actionTemplate.Project_Type__c) || KICKSTARTER.equalsIgnoreCase(project.Project_Type__c))) {continue;}
				listActionToCreate.add(
					new Action__c(
						Name = actionTemplate.Name, // 03.07.2023/ Sophal Noch / US-0013131

						// Project__c = projectId,
						Project__c = project.Id,
						OwnerId = project.OwnerId,
					   //@ Change history: 04.04.2022 / Chetra Sarom  / US-0011551
					   //    Detailed_Description__c = (validProjectRecordType.contains(project.RecordType.DeveloperName) && mapTemplate.get(templateId).Detailed_Description__c != null)? mapTemplate.get(templateId).Detailed_Description__c: '',
					   Detailed_Description__c = (validProjectRecordType.contains(project.RecordType.DeveloperName) && actionTemplate.Detailed_Description__c != null)? actionTemplate.Detailed_Description__c: '', // 03.07.2023/ Sophal Noch / US-0013131
					
					   // US-0011551 end
   
					   //US-0011630
					   Managed_Seller__c = validProjectRecordType_4PopulateManagedSeller.contains(project.RecordType.DeveloperName) ? project.EBH_Seller__c : null,
						Action_Template__c = templateId,
						RecordTypeId = (project.RecordType.DeveloperName==RECTYPE_ACTION_TEMPLATE_SCALING) ? ApexUtil.getRecordTypeByName('Action__c',RECTYPE_ACTION_TEMPLATE_SCALING).Id : ApexUtil.getRecordTypeByName('Action__c',RECTYPE_ACTION_TEMPLATE_ACQ).Id,
						TemplateUniqueId__c = project.Id+'_'+templateId  // 03.07.2023/ Sophal Noch / US-0013131
					)
				);
			}
		}

	 	
	 	try
	 	{
			ApexSafe.dml().doUpsert(listActionToCreate, Action__c.TemplateUniqueId__c, true);
	 		mapResult.put('status','ok');
	 		
	 	}catch(DMLException dex)
    	{mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}catch(Exception ex){
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
    	}
    	
	 	return mapResult;
	 }
	
	 /*****************************************************************************************************************************
    @ Method:   getPro
    @ Version:  1.0
    @ Author:   Sreymeas Nao (sreymeas.nao@gaea-sys.com)
    @ Purpose:  US-0007649 - [ AU] Create Actions for Scaling Project Record
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Id proId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 23.06.2020 / Sreymeas Nao / Created the  Method.
	@ Change history: 03.07.2023/ Sophal Noch / US-0013131 - SUSU - Bulk Action creation for Multiple Projects	
    *****************************************************************************************************************************/
	
	@AuraEnabled
	public static List<String> getPro(List<String> listProjectId) { // 03.07.2023/ Sophal Noch / US-0013131 make method support multiple projects
		Set<String> setRecTypeName = new Set<String>();
		List<EBH_Project__c> lstProject = ApexSafe.query().doQuery(PROJECT_SQL,new Map<String, Object> {'listProjectId' => listProjectId});
		for(EBH_Project__c project : lstProject){
			if(!setRecTypeName.contains(project.RecordType.DeveloperName)){setRecTypeName.add(project.RecordType.DeveloperName);}
		}
		return new List<String>(setRecTypeName);
	}
	 
	 class Template{
	 	
	 	@AuraEnabled
	 	public Action_Template__c template;
	 	
	 	@AuraEnabled
	 	public Boolean isRequired;
	 	
	 	@AuraEnabled
	 	public Boolean isExisting;
	 	
	 	@AuraEnabled
	 	public Boolean leftCheck = false; //checked but not yet moved to selection panel
	 	
	 	@AuraEnabled
	 	public Boolean rightCheck = false; //check and on the right panel
	 	
	 	@AuraEnabled
	 	public Boolean selected = false; // on the right panel could be check on uncheck
	 	
	 	@AuraEnabled
	 	public String id;
	 	
	 	public Template(Action_Template__c template)
	 	{
	 		this.id = template.Id;
	 	}
	 }
		
}