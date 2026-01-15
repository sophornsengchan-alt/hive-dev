/*********************************************************************************************************************************
@ Class:         TransferSellersController
@ Version:       1.0
@ Author:        Loumang SENG (loumang.seng@gaea-sys.com)
@ Purpose:       US-0009600 - [Pro-Trader] In Flight transfer of Cohort Sellers within Pro-Trader
@				 Given that I am any user with "BoB Category Lead" Permission
@				 Select a Cohort Seller(related to Light Touch Category Cohort and BoB__c.Managed Type = "Pro-Trader")
@				 Click "Transfer Sellers" should open a new Component that displays
@				 All Light Touch Category Cohorts(with status = Cohort Active and Managed Type = Pro-Trader)
@				 Select a Cohort and click "Save
@				 so that the Cohort Seller , related Actions are transferred to new BoB or Cohort record selected.
@				US-0009917 - In Flight transfer of Cohort Sellers to from and to any "Light Touch Category Cohorts"
@				Given that I am any user with "BoB Category Lead" permissionSelect any Cohort(record type = Light touch category Cohort and Status = Cohort Active)
@				when I click "Transfer Sellers" in the Cohort Seller List View,
@				the Component should display all Cohorts(with record type = Light touch category Cohort and Status = Cohort Active)
@				the Component also displays below 2 fields which they can populate (BoB_Seller__C.Account_Manager__c , BoB_Seller__C.TTEC_MANAGER__c)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  	08.06.2021 / Loumang SENG (loumang.seng@gaea-sys.com) / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  	27.07.2021 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / updated the class.US-0009917
@               :   18.08.2022 / SRONG TIN / US-0012081 - Amends to "Transfer Sellers" Button
                    06.09.2022 / Sambath Seng / US-0012558 - Validations when changing Cohort Seller Status from "Inactive" to "Active"
                    24-02-2023 / SENG Loumang / US-0013201 -Transfer Capability of 600 BoB Sellers with 3 Action records each results in error
                    04.04.2024 / Sophal Noch / US-0015074 - Transfer Cohort Seller should create the new Cohort Seller status in Invited if original Cohort Seller is in Invited Status
                    04.06.2024 / Sophal Noch / US-0015352 - Transfer Cohort Seller Issue - Conflict and Order of execution
                    08.12.2025 / Sophal Noch / US-0033965 - 7. Approve - Transfer
*********************************************************************************************************************************/
public without sharing class TransferSellersController {
    /******************* CONTROLLER FOR VF PAGE *****************************/
	public String   bobId           {get;set;}
    public String   bobSellerIds    {get;set;}
    public Boolean  isError         {get;set;} 

    private final static String STATUS_BOB_ACTIVE = 'BoB Active';
    private final static String PRO_TRADER = 'LTTM Managed';
    //18.08.2022 / SRONG TIN / US-0012081
    private final static String BS_STATUS_INACTIVE = 'Inactive'; // 04.04.2024 / Sophal Noch / US-0015074 : rename variable
    private final static String BS_STATUS_INVITED = 'Invited'; // 04.04.2024 / Sophal Noch / US-0015074
    private final static String ACTION_STATUS_COMPLETED = 'Completed';
    private final static String ACTION_STATUS_CANCELLED = 'Cancelled';
    //Sambath Seng 06.09.2022 US-0012558
    private final static String BOB_LTCC_RECORDTYPE = 'Light_Touch_Category_Cohort';
	private final static String SOQL_BOBSELLER_CHECK_BOB_ACTIVE = 'Select Id,Seller__r.Name,Status__c,BoB__r.RecordType.DeveloperName from BoB_Seller__c';
    private final static String BOB_SELLER_STATUS_DRAFT = 'Draft';
    private final static Integer MAXIMUM_ACTION_RECORD = Integer.valueOf(System.Label.Maximun_Actions_Per_Transfer);//LA-24-02-2023-US-0013201

    private final static Set<String> SET_EXCL_ACTION_RT_TO_TRANSFER = new Set<String>{'Change_Request'}; // 08.12.2025 / Sophal Noch / US-0033965

    public TransferSellersController(ApexPages.StandardSetController controller)
    {
        List<BoB_Seller__c> bobSellers = controller.getSelected();
		bobId = (ApexPages.currentPage().getParameters().get('id')!=null)?String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')):'';
        List<String> tmpIds = new List<Id>();
        for(BOB_Seller__c bs: bobSellers){
            tmpIds.add(bs.Id);

        }
        bobSellerIds = (tmpIds.isEmpty())?'':String.join(tmpIds, ',');

    }

    @AuraEnabled
    public static Map<String,Object> apexInit(String bobId, String bobSellerIds)
    {	
        
        Map<String,Object> mapResult = new Map<String,Object>();
        if(String.isBlank(bobSellerIds)){
            mapResult.put('status','ko');
            mapResult.put('error',System.Label.COHORT_SELLERS_ERROR);
            mapResult.put('noCohortSellersError',true);
            return mapResult;

        }
        //23.08.2022 / SRONG TIN / US-0012081
        Id recLTCC = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort').Id;
        List<BoB__c> currentBob = [Select Id,Status__c,RecordTypeId From Bob__c Where Id =:bobId];
        if(currentBob[0].Status__c != STATUS_BOB_ACTIVE && currentBob[0].RecordTypeId == recLTCC){
            mapResult.put('status','ko');
            mapResult.put('error',System.Label.VALIDATIONS_TO_TRANSFER_OF_SELLERS);
            mapResult.put('validatedToTransferFail',true);
            return mapResult;
        }

        Id recTypeLTTMId = ApexUtil.getRecordTypeByName('BoB_Seller__c',System.Label.BoBSellerRecordType_LTTM).Id;
        List<String> tmp = bobSellerIds.split(',');
        List<BoB_Seller__c> listBS= [select Id, Managed_Type__c,RecordTypeId,Status__c,Seller__c,BoB__c,BoB__r.RecordType.DeveloperName from BoB_Seller__c where Id in:tmp];
        // Sambath Seng 09.09.2022 US-0012558
        Set<String> setBoBIds = new Set<String>();
    	Set<String> setSellers = new Set<String>();
        List<String> setErrorSellerName = new List<String>();

        for (BoB_Seller__c bobSeller: listBS) {
            if( bobSeller.RecordTypeId != recTypeLTTMId){ 
                mapResult.put('status','ko');
                mapResult.put('error','Incorrect record type');
                return mapResult;
            }
             //TH: 27/07/2021 : US-0009917: comment out, so that all Manage type can be transfer
            /*if( bobSeller.Managed_Type__c != PRO_TRADER){ //'LTTM Managed'
                mapResult.put('status','ko');
                mapResult.put('error',System.Label.CohortSeller_NOT_Protrader_Error);
                mapResult.put('noCohortSellersError',false);
                return mapResult;
            }*/

            // Sambath Seng 06.09.2022 US-0012558
            if(bobSeller.Status__c == BS_STATUS_INACTIVE && bobSeller.BoB__r.RecordType.DeveloperName == BOB_LTCC_RECORDTYPE){
                setBoBIds.add(bobSeller.BoB__c);
    		    setSellers.add(bobSeller.Seller__c);
            }
        }
        //Start - Sambath Seng 06.09.2022 US-0012558
		String addtionalWhere = ' WHERE BoB__c NOT IN :setBoBIds AND Seller__c IN :setSellers AND Status__c ='+ApexUtil.closeSQoute(BOB_SELLER_STATUS_DRAFT)+' AND BoB__r.RecordType.DeveloperName ='+ApexUtil.closeSQoute(BOB_LTCC_RECORDTYPE)+' AND BoB__r.Status__c ='+ApexUtil.closeSQoute(STATUS_BOB_ACTIVE);
    	List<BoB_Seller__c> listAffectSeller = Database.query(SOQL_BOBSELLER_CHECK_BOB_ACTIVE+addtionalWhere);
        for(BoB_Seller__c bs: listAffectSeller)
    	{
			setErrorSellerName.add(bs.Seller__r.Name);
    	}
        if(!setErrorSellerName.isEmpty()){
            mapResult.put('status','ko');
            mapResult.put('error',System.Label.ErrorTransferSellerInactiveBobSeller.replace('BOB_SELLER_NAME',String.join(setErrorSellerName,', ')));
            return mapResult;
        }
        //End - Sambath Seng 06.09.2022 US-0012558

        //String recLTCC = 'Light_Touch_Category_Cohort';
        String sWhereBob  = ' Where Id <>\''+bobId+'\' AND RecordTypeId =\''+recLTCC+'\' AND Status__c=\''+STATUS_BOB_ACTIVE+'\'';//AND Managed_Type__c =\''+PRO_TRADER+'\' //TH: US-0009917: comment out, so that all Manage type can be transfer 
        List<ColName> listColNameBOB = new List<ColName>();
        Set<String> setFieldNameBOB = new Set<String>{'id'};
        Map<String,String> mapFixPkl = new Map<String,String>{'Managed_Type__c'=>'toLabel(Managed_Type__c)lbl_Managed_Type__c','Status__c'=>'toLabel(Status__c)lbl_Status__c'};
        Map<String,String> mapFixPklForCol = new Map<String,String>{'Managed_Type__c'=>'lbl_Managed_Type__c','Status__c'=>'lbl_Status__c'};
        Map<String,String> mapFixLabel = new Map<String,String>{'Account_Manager__r.Name'=>'Account Manager'};
        for(Schema.FieldSetMember f: SObjectType.BOB__c.FieldSets.TransferSellers.getFields())
        {
            setFieldNameBOB.add(mapFixPkl.containsKey(f.getFieldPath())?mapFixPkl.get(f.getFieldPath()):f.getFieldPath() );
            if(f.getFieldPath().contains('.') && f.getFieldPath().endsWith('Name'))
        	{
        		String fId = ApexUtil.getFieldIdRef(f.getFieldPath());
        		setFieldNameBOB.add(fId);
        	}
            listColNameBOB.add(
                new ColName(mapFixLabel.containsKey(f.getFieldPath())?mapFixLabel.get(f.getFieldPath()):f.getLabel(),
                mapFixPklForCol.containsKey(f.getFieldPath())?mapFixPklForCol.get(f.getFieldPath()):f.getFieldPath(),
                f.getType()+'')
            );
        }
        //String soql_bob = 'Select '+String.join(new List<String>(setFieldNameBOB),',')+', Account_Manager__r.Name From BOB__c';
        String soql_bob = 'Select '+String.join(new List<String>(setFieldNameBOB),',')+' From BOB__c';
        
        mapResult.put('status','ok');
        mapResult.put('soql_bob',soql_bob);
        mapResult.put('sWhereBob',sWhereBob);
        mapResult.put('listColNameBOB',listColNameBOB);
        mapResult.put('sitePrefix',Site.getPathPrefix());
        mapResult.put('currentBob',currentBob[0]);
        
        return mapResult;
    }
    
    /*********************************************************************************************************************************
    @ Method:         transferCohortSeller
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0015074 - Transfer Cohort Seller should create the new Cohort Seller status in Invited if original Cohort Seller is in Invited Status
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  04.04.2024 / Sophal Noch / modified the method.
    @               :  04.06.2024 / Sophal Noch / US-0015352 - Transfer Cohort Seller Issue - Conflict and Order of execution
    @               :  08.12.2025 / Sophal Noch / US-0033965 - 7. Approve - Transfer
    *********************************************************************************************************************************/
	@AuraEnabled
	public static Map<String,Object> transferCohortSeller(String newbobId, String bobSellerIds,BoB_Seller__c bobSeller,Boolean isSelectedOptionYes,BoB__c currentBob, String selectedAccManagerId){
       
       // 05.06.2024 / Sophal Noch / US-0015352 : change method name from apexSave to transferCohortSeller
       
        Savepoint sp = Database.setSavepoint(); // 04.06.2024 / Sophal Noch / US-0015352
		Map<String,Object> mapResult = new Map<String,Object>();
		try {

			List<String> listBSId = bobSellerIds.split(',');
            if(!listBSId.isEmpty() && String.isNotBlank(newbobId)){ 
                //18.08.2022 / SRONG TIN / US-0012081
                Id recLTCC = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort').Id;

                // 08.12.2025 / Sophal Noch / US-0033965 : move queries to ApexSafe and add exclude filter for action record type Change Request
                List<BoB__c> bobs = ApexSafe.query().secCheck(false).doQuery('select Id,RecordTypeId,Account_Manager__c,Status__c from BOB__c where id =: newbobId',new Map<String, Object>{'newbobId' => newbobId }); 
                List<Action__c> actions = ApexSafe.query().secCheck(false).doQuery('Select Id,Status__c,LTTM_Seller__c From Action__c Where Status__c != :ACTION_STATUS_COMPLETED AND LTTM_Seller__c in :listBSId AND RecordType.DeveloperName NOT IN :SET_EXCL_ACTION_RT_TO_TRANSFER',new Map<String, Object>{'ACTION_STATUS_COMPLETED' => ACTION_STATUS_COMPLETED,'listBSId' => listBSId, 'SET_EXCL_ACTION_RT_TO_TRANSFER' => SET_EXCL_ACTION_RT_TO_TRANSFER});

                if( (currentBob.Status__c != STATUS_BOB_ACTIVE && currentBob.RecordTypeId == recLTCC) &&
                    (bobs[0].Status__c == STATUS_BOB_ACTIVE && bobs[0].RecordTypeId == recLTCC)
                ){
                    //AC2 Validations to ensure Transfer of sellers
                    mapResult.put('status','ko');
                    mapResult.put('error',System.Label.VALIDATIONS_TO_TRANSFER_OF_SELLERS);
                }else{
                    
                    if(isSelectedOptionYes && actions.size() > MAXIMUM_ACTION_RECORD){ //LA-24-02-2023-US-0013201: Validate 9000+ actions per transfer
                        mapResult.put('status','ko');
                        mapResult.put('error',System.Label.ERROR_LIMITATION_ACTIONS);
                    }else{
                        //18.08.2022 / SRONG TIN / US-0012081
                        List<BoB_Seller__c> listbs = New List<BoB_Seller__c>();
                        List<BoB_Seller__c> listClonebs = New List<BoB_Seller__c>();
                        String soqlBS  = 'Select '+ApexUtil.generateSQOLFields('BoB_Seller__c')+' From BoB_Seller__c Where Id=:listBSId';
                        //[select Id, Seller__c,Status__c,BoB__c,BoB__r.Status__c,Account_Manager__c,TTEC_MANAGER__c from BoB_Seller__c where Id In:listBSId]
                        Map<String,BoB_Seller__c> cohortSellerMap = new Map<String,BoB_Seller__c>();
                        List<BoB_Seller__c> listBsToTransfer = ApexSafe.query().secCheck(false).doQuery(soqlBS,new Map<String, Object>{'listBSId' => listBSId}); // 08.12.2025 / Sophal Noch / US-0033965 : move query to apexSafe
                        for(BoB_Seller__c bs : listBsToTransfer){
                            // Clone the Cohort Seller 
                            BoB_Seller__c cloneBS = bs.clone(false, false, false, false);
                            cloneBS.BoB__c = newbobId;
                            cloneBS.Source_Cohort_Seller__c = bs.Id;
                            //TH: US-0009917 :set bs.Account_Manager__c and bs.TTEC_MANAGER__c
                            cloneBS.Account_Manager__c = bobSeller.Account_Manager__c != null ? bobSeller.Account_Manager__c : bobs[0].Account_Manager__c;
                            if(String.isNotBlank(selectedAccManagerId)){ // 08.12.2025 / Sophal Noch / US-0033965 : use selectedAccManagerId pass from aura
                                cloneBS.Account_Manager__c = selectedAccManagerId;
                            }
                            cloneBS.TTEC_MANAGER__c = bobSeller.TTEC_MANAGER__c != null ? bobSeller.TTEC_MANAGER__c : null;
                            // cloneBS.Status__c = BOB_SELLER_STATUS_DRAFT;// Sambath Seng 12.09.2022 US-0012558
                            cloneBS.Status__c = cloneBS.Status__c != BS_STATUS_INVITED ? BOB_SELLER_STATUS_DRAFT : cloneBS.Status__c; // 04.04.2024 / Sophal Noch / US-0015074
                            listClonebs.add(cloneBS);
                            cohortSellerMap.put(bs.Id,cloneBS);
                            //update old record
                            bs.Status__c = BS_STATUS_INACTIVE;
                            listbs.add(bs);
                            
                        }
                        
                        // 08.12.2025 / Sophal Noch / US-0033965 : move to ApexSafe
                        ApexSafe.dml().secCheck(false).doUpdate(listbs, true);
                        ApexSafe.dml().secCheck(false).doInsert(listClonebs, true);
                        
                        List<Action__c> actionToUpdate = new List<Action__c>();
                        for(Action__c ac : actions){
                            BoB_Seller__c bs = cohortSellerMap.get(ac.LTTM_Seller__c);
                            if(isSelectedOptionYes){
                                ac.LTTM_Seller__c = bs.Id;
                            }else{
                                ac.Status__c = ACTION_STATUS_CANCELLED;
                            }
                            actionToUpdate.add(ac); 
                        }
                        ApexSafe.dml().secCheck(false).doUpdate(actionToUpdate, true); // 08.12.2025 / Sophal Noch / US-0033965 : move to ApexSafe
                        mapResult.put('status','ok');

                    }
                }
                
                
            }

		}catch(DMLException dex){
            Database.rollback(sp); // 04.06.2024 / Sophal Noch / US-0015352
            mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}catch(Exception ex){
            Database.rollback(sp); // 04.06.2024 / Sophal Noch / US-0015352
            mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());	
        }
        
		return mapResult;
	}
    
    static Map<String,String> mapLinkField = new Map<String,String>{'Account_Manager__r.Name'=>'Account_Manager__c'};
    
    class ColName{
    	@AuraEnabled
    	public String label;
    	
    	@AuraEnabled
    	public String fieldName;
      
        @AuraEnabled
    	public String type;
    	
    	@AuraEnabled
    	public Map<String,Object> typeAttributes;
    	
    	public ColName(String label,String fieldName,String type)
    	{
    		this.label = label;
    		this.fieldName = fieldName;
    		this.type = type.toLowerCase();
    		if(mapLinkField.containsKey(fieldName))
    		{
    			typeAttributes = new Map<String,Object>{
    				'label' => new Map<String,Object>{'fieldName'=>mapLinkField.get(fieldName)},
    				'target'=>'_blank',
    				'tooltip'=>''
    			};

    			this.fieldName = 'link_'+mapLinkField.get(fieldName);
    			this.type = 'url';

    		}else if(this.type.equalsIgnoreCase('datetime')){
                this.type = 'date';
                typeAttributes = new Map<String,Object>{
                    'label' => new Map<String,Object>{'fieldName'=>fieldName},
                    'day' => 'numeric',
                    'month'=> 'short',
                    'year'=> 'numeric',
                    'hour'=> '2-digit',
                    'minute'=> '2-digit',
                    'second'=> '2-digit',
                    'hour12'=> false
                };
            }
    	}
    }
	

}