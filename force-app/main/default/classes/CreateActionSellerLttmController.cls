/*********************************************************************************************************************************
@ Class:         CreateActionSellerLttmController
@ Version:       1.0
@ Author:        Sreymeas Nao (sreymeas.nao@gaea-sys.com)
@ Purpose:       US-0007429 - [LTTM] - Create Actions for LTTM Sellers in Light touch category cohort
@				 Controller for aura: CreateActionSellerLttm
@				 US-0008799 Modified method apexInitActionTemplateList
@				 Controller for VF Page: CreateActionForCohortSeller
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  	20.04.2020 / Sreymeas Nao (sreymeas.nao@gaea-sys.com) / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:	06.07.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0007809 Modified method apexInitActionTemplateList
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:	23.10.2020 / Sim Ratha (ratha.sim@gaea-sys.com) / US-0008439 - [US] Seller Management US & CA Added to Country for Action Template
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:	13.01.2021 / Mony Nou (mony.nou@gaea-sys.com)/ US-0008799 Modified method apexInitActionTemplateList
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:	16.07.2021 / Mony Nou (mony.nou@gaea-sys.com)/ US-0009960 Modified method apexSaveActions
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:	05.08.2021 / Mony Nou (mony.nou@gaea-sys.com)/ US-0010084 
				:   05.05.2022 / Loumang SENG /US-0011260 - TECHDEBT: Reflected XSS
				:   06.07.2022 / Sophal Noch / US-0012056 - Error Message thrown when attemption to Create 96 Actions to Cohort Sellers
				:   29.11.2022 / Bora Chhorn / US-0012663 - Remove "create action" "create category" "bulk upload cohort seller" from permission set "Growth Coaching"
				:   28.04.2022 / Sovantheany Dim / US-0013510 - New Field "Managed Segment" in Action Template
				: 	18.07.2023 / Sophal Noch / US-0014214 - ADS - Cohort Create action flow
				: 	31.01.2024 / Sophal Noch / US-0014525 - ADS - Enable cohort operations for Advertising cohorts
				:   25.09.2024 / Vimean Heng / US-0015956 - One-Off Account Management Action templates are pre-selected for other Managed segments Action creation process
*********************************************************************************************************************************/

public with sharing class CreateActionSellerLttmController {

	//Start-Sambath Seng 09.09.2021 US-0010209 add Detailed Description to query
	// 18.07.2023 / Sophal Noch / US-0014214 : add RecordType.DeveloperName to SOQL_ACTION_TEMPLATE
	private static String SOQL_ACTION_TEMPLATE  = 'Select (Select Id,Action_Template__c,LTTM_Seller__c From Actions__r Where LTTM_Seller__c IN:bobSellerId limit 1),Id,Name,Active__c,Country__c,Description__c,Detailed_Description__c,Group__c,Lead_Segment__c,RecordTypeId,RecordType.Name,RecordType.DeveloperName,Required__c,Managed_Segment__c From Action_Template__c ';
	//End-Sambath Seng 09.09.2021 US-0010209 add Detailed Description to query
	/******************* CONTROLLER FOR VF PAGE *****************************/
	public String   bobId           {get;set;}
    public String   bobSellerIds    {get;set;}
    public Integer  numSelected     {get;set;}
    public String   msg             {get;set;}
    public Boolean  isError         {get;set;} //warning or error 
    public String   severity        {get;set;} // warning,info,error,confirm

    private final String RECTYPE_BOBSELLER_LTTM = System.Label.BoBSellerRecordType_LTTM;
	private final String RECTYPE_BOBSELLER_ADS = 'Advertising';
	private final String BS_SOBJECT_NAME = 'BoB_Seller__c';
	
	private final Set<Id> SET_ALLOW_CS_RTTYPE_ID = new Set<Id>{ApexUtil.getRecordTypeByName(BS_SOBJECT_NAME,RECTYPE_BOBSELLER_LTTM).Id, ApexUtil.getRecordTypeByName(BS_SOBJECT_NAME,RECTYPE_BOBSELLER_ADS).Id}; // 31.01.2024 / Sophal Noch / US-0014525
	
	private final static Integer INSERT_ACTION_RECORD_LIMIT = Integer.valueOf(System.Label.InsertActionRecordLimit);

    public CreateActionSellerLttmController(ApexPages.StandardSetController controller) {

        List<BoB_Seller__c> bobSellers = controller.getSelected();
		//bobId = (ApexPages.currentPage().getParameters().get('id')!=null)?String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')):'';
		bobId = String.escapeSingleQuotes(String.isBlank(System.currentPageReference().getParameters().get('id')) ? '' : ApexPages.currentPage().getParameters().get('id'));//LA-04-05-2022:US-0011260
		numSelected = (bobSellers!=null)?bobSellers.size():0;

        if (numSelected < 1) {
            isError = true; 
            msg = System.Label.BoBCreateActionError_1;
            severity = ApexPages.severity.WARNING.name();
        } else {

			// Id recTypeLTTMId = ApexUtil.getRecordTypeByName('BoB_Seller__c',RECTYPE_BOBSELLER_LTTM).Id;
            
            List<Id> tmpIds = new List<Id>();
            for (BoB_Seller__c bobSeller: bobSellers) {
				// if (bobSeller.RecordTypeId == recTypeLTTMId) tmpIds.add(bobSeller.Id);
                if (SET_ALLOW_CS_RTTYPE_ID.contains(bobSeller.RecordTypeId)) { // 31.01.2024 / Sophal Noch / US-0014525
					tmpIds.add(bobSeller.Id);
				}
            }

            bobSellerIds = (tmpIds.isEmpty())?'':String.join(tmpIds, ',');
		}
    }

    public PageReference backToListView(){

        PageReference pageRef = new PageReference('/lightning/r/'+bobId+'/related/BoB_Sellers__r/view');
        pageRef.setRedirect(true);
        return pageRef;
    }
	/******************* END OF CONTROLLER FOR VF PAGE **********************/


	/******************* CONSTANTS DEFINITION*****************************/
     public final static String SOQL_BOB_SELLER_1 = 'select Oracle_Id__c, Seller__r.Name from BoB_Seller__c';
	 // 18.07.2023 / Sophal Noch / US-0014214 : add RecordType.DeveloperName to SOQL_BOB_1
	 public final static String SOQL_BOB_1 = 'Select Managed_Segment__c,Status__c, Name, RecordTypeId, RecordType.DeveloperName, Account_Manager__c,Owner.Name,owner.Email,EBH_BOBCNTRY__c From BOB__c';
	 public static final Map<String,String> mapCountry = new Map<String,String>{'3'=>'UK','77'=>'DE', '71'=>'FR','101'=>'IT','186'=>'ES','163'=>'PL',
            '99'=>'IE','193'=>'CH','146'=>'NL','23'=>'BE','15'=>'AU','168'=>'EEC-Unsited','0'=>'US','2'=>'CA'};

	// 18.07.2023 / Sophal Noch / US-0014214 : add multiple constants below to be used in method apexInitActionTemplateList and apexSaveActions
	private final static String RTYPE_BOB_ADS = 'Advertising_Cohort';

	private final static String RTYPE_ACTION_TEMPLATE_LTTM = 'LTTM';
	private final static String RTYPE_ACTION_TEMPLATE_ADS = 'Advertising';
	private final static String RTYPE_ACTION_TEMPLATE_PM = 'Promotions';
	private final static Set<String> SET_RTYPE_ADS_PRO = new Set<String>{RTYPE_ACTION_TEMPLATE_ADS, RTYPE_ACTION_TEMPLATE_PM};

	private final static String RTYPE_ACTION_LTTM = 'LTTM';
	private final static String RTYPE_ACTION_ADS = 'Advertising';
	private final static String RTYPE_ACTION_PM = 'Promotions';
	private final static Map<String, String> MAP_RT_TEMPLATE_TO_RT_ACTION = new Map<String, String>{
		RTYPE_ACTION_TEMPLATE_LTTM => RTYPE_ACTION_LTTM,
		RTYPE_ACTION_TEMPLATE_ADS => RTYPE_ACTION_ADS,
		RTYPE_ACTION_TEMPLATE_PM => RTYPE_ACTION_PM
	};

     /* ***************  END OF CONSTANTS DEFINITION********************/
    
	
	/***************************************************************************************************************************************
	@ Method:        apexInitActionTemplateList
	@ Version:       2.0
	@ Author:        Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:       US-0007809 be able to have "Select All" feature while Selecting Action Templates
	@				 to be able to view only the Child Action Templates(type LTTM) that has Parent Action IS NOT BLANK
	-----------------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 06.07.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / Modified the method. Adding Parent_Action__c != NULL when
	@																		Selecting Action Templates
	@				  13.01.2020 / Mony Nou (mony.nou@gaea-sys.com)/ US-0008799 - [LTTM Plus]Create Actions for selected Subset of Light touch cohort Sellers
	@				: 02.04.2021/ Vadhanak Voun/ US-0009354 - [Pro-Trader Hyper Care] "Create Actions" resulting in error when attempting to create 26 Actions in PROD
	@				: 26.11.2021 / SRONG TIN / US-0010820 - [PT/aSell] Pro-Trader/aSelleration: Apply missing actions across cohort sellers
	@				: 28.04.2023 / Sovantheany dim / US-0013510 - New Field "Managed Segment" in Action Template
	@				: 18.07.2023 / Sophal Noch / US-0014214 - ADS - Cohort Create action flow
	@				: 25.09.2024 / Vimean Heng / US-0015956 - One-Off Account Management Action templates are pre-selected for other Managed segments Action creation process
	-----------------------------------------------------------------------------------------------------------------------------------------*/	 
    @AuraEnabled
	 public static Map<String,Object> apexInitActionTemplateList(String bobId, String bobSellerIds,String selectedSegment)
	 {	
	 	Map<String,Object> result = new Map<String,Object>();
		Map<String,Object> pBob = new Map<String,Object>();
		Map<String,Object> pBobSeller = new Map<String,Object>();
		Map<String,Object> pActTemplate = new Map<String,Object>();
		pBob.put('bobId',bobId);
		pBobSeller.put('bobId',bobId);
	 	String sWhereBob = ' Where Id=:bobId';
		String sWhereBobSeller = ' Where BoB__c=:bobId';
		if (String.isNotBlank(bobSellerIds)) {
			List<String> lBoBSellerIds = bobSellerIds.split(',');
			sWhereBobSeller+=' And Id IN:lBoBSellerIds';
			pBobSeller.put('lBoBSellerIds',lBoBSellerIds);
		}
		// String recLttm = EBH_ConstantsUtility.RECTYPE_ACTION_TEMPLATE_LTTM; // 18.07.2023 / Sophal Noch / US-0014214
	 	//BOB__c bob = (BOB__c)Database.query(SOQL_BOB_1+sWhereBob)[0];
		BOB__c bob = (BOB__c) ApexSafe.query().doQuery(SOQL_BOB_1+sWhereBob,pBob)[0];
		//List<BOB_Seller__c> bobSeller = Database.query(SOQL_BOB_SELLER_1+sWhereBobSeller);
		//Map<Id,BOB_Seller__c> mapBobSeller = new Map<Id,BOB_Seller__c>( (BOB_Seller__c[])Database.query(SOQL_BOB_SELLER_1+sWhereBobSeller) );
		Map<Id,BOB_Seller__c> mapBobSeller = new Map<Id,BOB_Seller__c>( (BOB_Seller__c[]) ApexSafe.query().doQuery(SOQL_BOB_SELLER_1+sWhereBobSeller,pBobSeller));
		String bobCountry = bob.EBH_BOBCNTRY__c;
        Set<Id> bobSellerId = mapBobSeller.keySet();
		pActTemplate.put('bobSellerId',bobSellerId);
		String mapBobCountry = mapCountry.get(bobCountry);
		//TH: US-0013510: set Default managed segment to bob.Managed_Segment__c
		if(String.isBlank(selectedSegment)){
			selectedSegment = bob.Managed_Segment__c;
			//empty filter when picklist mismatch
			Set<String> sPicklistValue = new Set<String>();
			for(Schema.PicklistEntry pkl: Action_Template__c.Managed_Segment__c.getDescribe().getPicklistValues())
			{
				if(pkl.isActive())
				{
					sPicklistValue.add(pkl.getValue());
				}
			}
			if(!sPicklistValue.contains(selectedSegment)){
				selectedSegment = 'None';
			}
		}

		// String sWhereTemplate  = ' Where Active__c=true And RecordType.DeveloperName=:recLttm AND Country__c =:mapBobCountry AND Parent_Action__c != NULL Order by Name';
		// 18.07.2023 / Sophal Noch / US-0014214 : differentiate SOQL Action Template Condition By BoB Record Type
		String sWhereTemplate;
		if(bob.RecordType.DeveloperName == RTYPE_BOB_ADS){
			pActTemplate.put('SET_RTYPE_ADS_PRO',SET_RTYPE_ADS_PRO);
			sWhereTemplate  = ' Where Active__c=true And RecordType.DeveloperName IN: SET_RTYPE_ADS_PRO Order by Name';
		}else{
			//swSgM filter base on Managed_Segment__c level, if none selected segment, show all
			String swSgM = '';
			if(String.isNotBlank(selectedSegment) && !selectedSegment.equalsIgnoreCase('None')){
				swSgM =  ' AND Managed_Segment__c INCLUDES (:selectedSegment)';
				pActTemplate.put('selectedSegment',selectedSegment);
			}
			pActTemplate.put('RTYPE_ACTION_TEMPLATE_LTTM',RTYPE_ACTION_TEMPLATE_LTTM);
			pActTemplate.put('mapBobCountry',mapBobCountry);
			
			sWhereTemplate  = ' Where Active__c=true And RecordType.DeveloperName =: RTYPE_ACTION_TEMPLATE_LTTM AND Country__c =:mapBobCountry AND Parent_Action__c != NULL ' + swSgM + ' Order by Name';
		}

	 	//String sWhereAction  = ' Where LTTM_Seller__c IN :bobSellerId';
	 	
	 	List<Template> listPossibleActions = new List<Template>();
	 	List<Template> listSelectedAction = new List<Template>();
	 	// Set<String> setExisting = new Set<String>();
	 	// for(Action__c ac: Database.query(EBH_ConstantsUtility.SOQL_ACTION+sWhereAction))
	 	// {
	 	// 	setExisting.add(ac.Action_Template__c);
	 	// }
	 	
	 	// List<Action_Template__c> listTemplate = Database.query(SOQL_ACTION_TEMPLATE+sWhereTemplate);
	 	
	 	for(Action_Template__c acTempl: (Action_Template__c[]) ApexSafe.query().doQuery(SOQL_ACTION_TEMPLATE+sWhereTemplate,pActTemplate))
	 	{
	 		Template tmp = new Template(acTempl);
	 		tmp.isRequired = acTempl.Required__c;
	 		//tmp.isExisting = setExisting.contains(acTempl.Id);
			
			tmp.isExisting = (acTempl.Actions__r <> null && !acTempl.Actions__r.isEmpty());
			// SRONG TIN / 26.11.2021 / US-0010820
			if (bobSellerId.size() == 1 && tmp.isExisting) {
				continue; //MN-05082021-US-0010084 - No longer keep the existed one
			}
			tmp.template = acTempl;
			//if(tmp.isRequired || tmp.isExisting) //MN-05082021-US-0010084 - No longer keep the existed one
			if (tmp.isRequired) //MN-05082021-US-0010084 - Keep the auto select required action template as is
	 		{
	 			listSelectedAction.add(tmp); 
	 		}else
	 		{
				 //TH:US-0013510:get action template where Managed_Segment__c = selectedSegment
				 Set<String> sManagedSegment = new set<String>();
				 if(String.isNotBlank(acTempl.Managed_Segment__c)) {
					sManagedSegment.addAll(acTempl.Managed_Segment__c.split(';'));
				 }
				 if(selectedSegment =='None' || String.isBlank(selectedSegment) || (String.isNotBlank(selectedSegment) && sManagedSegment.contains(selectedSegment))){
					listPossibleActions.add(tmp);
				 }
	 			
	 		}
	 	}
	 	
	 	result.put('status','ok');
	 	result.put('listPossibleActions',listPossibleActions);
	 	result.put('listSelectedAction',listSelectedAction);
        //result.put('bobSeller',bobSeller);
		result.put('bobSellerId',bobSellerId);
		result.put('bobSellerChunkResult',ApexUtil.chunkList(new List<Id>(bobSellerId), 25));  //limit Bob Seller per save
		
		result.put('selectedSegment',selectedSegment);
	 	return result;
	 }
	 
     /*****************************************************************************************************************************
    @ Method:   apexSaveActions
    @ Version:  1.0
    @ Author:   Sreymeas Nao (sreymeas.nao@gaea-sys.com)
    @ Purpose:  US-0007429 - [LTTM] - Create Actions for LTTM Sellers in Light touch category cohort
	@		    Save selected new action templates
	@			Action. Name = Action Template. Name
	@		·   Action. LTTM Seller = Lookup (BoB_Seller__c) 
	@		·   Action.Owner = BoB_Seller__c. Account_Manager__c
	@		·   Action. Due Date = Today + Action template. Number of dates required
	@		·   Action.Seller = BoB_Seller__c. Seller__c
	@		·   Action (Lookup) = Action Template
	@		·   Action. Description = Action Template. Description
	@			Action. Group = Action Template. Group
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String bobId: current bob id, list of selected template to be assigned
	@				  String bobSellerIds: selected BoB Sellers from Related List "Cohort Sellers" button called "Create Actions for Selected Sellers"
    @------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.04.2020 / Sreymeas Nao / Created the  Method.
	@				  19.01.2021 / Mony Nou (mony.nou@gaea-sys.com)/ US-0008799 - [LTTM Plus]Create Actions for selected Subset of Light touch cohort Sellers
	@				  16.07.2021 / Mony Nou (mony.nou@gaea-sys.com)/ US-0009960 - [Pro-Trader] P1 "Create Actions" button creates Duplicated Actions for Transferred sellers
	@							+ Just changed the unique key in TemplateUniqueId__c to use with Action Template Id + BoBSeller Id to avoid any duplicate creation when BoBSeller changed to new BoB
    @				  08.09.2021 / Sambath Seng (sambath.seng@gaea-sys.com)/ US-0010209 - [Pro-Trader] Action Template Description length to be increased to 32000
	@				  06.07.2022 / Sophal Noch / US-0012056 - Error Message thrown when attemption to Create 96 Actions to Cohort Sellers
	@				  18.07.2023 / Sophal Noch / US-0014214 - ADS - Cohort Create action flow
	*****************************************************************************************************************************/
	 @AuraEnabled
	 public static Map<String,Object> apexSaveActions(String bobId, String bobSellerIds, List<String> selectedNewTemplates)
	 {
	 	Map<String,Object> mapResult = new Map<String,Object>();
	 	String sWhereBob = ' Where Id=:bobId';
        String sWhereBobSeller = ' Where BoB__c=:bobId';
		if (String.isNotBlank(bobSellerIds)) {
			List<String> lBoBSellerIds = bobSellerIds.split(',');
			sWhereBobSeller+=' And Id IN:lBoBSellerIds';
		}
        Set<String> bobSellerId = new Set<String>();
	 	BOB__c bob = (BOB__c)Database.query(SOQL_BOB_1+sWhereBob)[0];
	 	List<BOB_Seller__c> bobSeller = Database.query(SOQL_BOB_SELLER_1+sWhereBobSeller);
        //System.debug('bobSeller>>>'+);
        String sWhereTemplate = ' Where Id IN:selectedNewTemplates';
		//Start-Sambath Seng 09.09.2021 US-0010209 change from EBH_ConstantUtility.SOQL_ACTION_TEMPLATE to SOQL_ACTION_TEMPLATE
	 	Map<Id,Action_Template__c> mapTemplate = new Map<Id,Action_Template__c>((List<Action_Template__c>)Database.query(SOQL_ACTION_TEMPLATE+sWhereTemplate));
		//End-Sambath Seng 09.09.2021 US-0010209 change from EBH_ConstantUtility.SOQL_ACTION_TEMPLATE to SOQL_ACTION_TEMPLATE
		 List<Action__c> listActionToCreate = new List<Action__c>();
	 	for(String templateId : selectedNewTemplates)
	 	{
            for(BOB_Seller__c oneBobSeller : bobSeller){

				// 18.07.2023 / Sophal Noch / US-0014214 : get action template record from map and use it in below logic
				Action_Template__c actionTemp =  mapTemplate.get(templateId);
				String rtActionDevName = MAP_RT_TEMPLATE_TO_RT_ACTION.get(actionTemp.RecordType.DeveloperName);

                listActionToCreate.add(
	 			new Action__c(
					// Name = mapTemplate.get(templateId).Name,
					Name = actionTemp.Name, // 18.07.2023 / Sophal Noch / US-0014214
	 				LTTM_Seller__c = oneBobSeller.Id,
	 				OwnerId = bob.OwnerId,
                    Managed_Seller__c = oneBobSeller.Seller__c,
	 				//Due_Date__c,
	 				Action_Template__c = templateId,

	 				// RecordTypeId = ApexUtil.getRecordTypeByName('Action__c',EBH_ConstantsUtility.RECTYPE_ACTION_TEMPLATE_LTTM).Id,
					RecordTypeId = ApexUtil.getRecordTypeByName('Action__c',rtActionDevName).Id, // 18.07.2023 / Sophal Noch / US-0014214

	 				// TemplateUniqueId__c = bobId+'_'+templateId+'_'+oneBobSeller.Id
					 TemplateUniqueId__c = templateId+'_'+oneBobSeller.Id, //MN-16072021-US-0009960
					// Detailed_Description__c = mapTemplate.get(templateId).Detailed_Description__c //Sambath Seng-08/09/2021-US-0010209
					Detailed_Description__c = actionTemp.Detailed_Description__c // 18.07.2023 / Sophal Noch / US-0014214
                 )
               );
            }
	 	}
	 	try
	 	{
			if(listActionToCreate.size() > INSERT_ACTION_RECORD_LIMIT ){mapResult.put('status','ko');mapResult.put('error',System.Label.ErrorInsertActionsAboveLimitation);return mapResult;} // Sophal Noch / 06.07.2022 / US-0012056 : record insert limit is 10000.
	 		upsert listActionToCreate TemplateUniqueId__c;
	 		mapResult.put('status','ok');
	 		
	 	}catch(DMLException dex)
    	{mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
        }catch(Exception ex){
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
        }
    	
	 	return mapResult;
	 }

	/*****************************************************************************************************************************
    @ Method:   getPicklistValueData
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  US-0013510 - New Field "Managed Segment" in Action Template
    @------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.04.2023 / Sovantheany dim / Created the  Method.
	*****************************************************************************************************************************/
	@AuraEnabled
	public static Map<String,Object> getPicklistValueData()
	{
		Map<String,Object> mapResult = new Map<String,Object>();
		try
	 	{
			List<Map<String,String>> listManageSegmentActionTemplate = ApexUtil.getPicklistValues(Action_Template__c.Managed_Segment__c);
			mapResult.put('status','ok');
			mapResult.put('listSegmentPickListValue',listManageSegmentActionTemplate);
	 	}catch(Exception ex){
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
        }
	 	return mapResult;
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