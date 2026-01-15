/*********************************************************************************************************************************
@ Class:          CloneContractController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0003807 [Contracts] Ability to clone pricing details when cloning Contract
@ CloneContractController for Aura CloneContract
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.01.2020 / Sovantheany Dim / Created the class.
@				: 12.03.2021/ Vadhanak Voun / US-0009233 - {Hypercare} - [Contracts] - Users unable to clone existing contract
*********************************************************************************************************************************/
public without sharing class CloneContractController {
	static List<String> listFieldForACP = new List<String>{'EBH_IncrementalGMVonly__c','EBH_Partner__c'};
	static List<String> listFieldForListing = new List<String>{'Pricebook2Id','EBH_DeceleratorThreshold__c',
				'EBH_MainTierThresholdofTarget__c','EBH_AcceleratorThreshold__c','EBH_AverageTakeRate__c',
				'EBH_DeceleratorTierrebate__c','EBH_RebateTierrebate__c','EBH_AcceleratorTierrebate__c',
				'EBH_IncrementalGMVonly__c','EBH_Partner__c'};
	static List<String> listFieldForRevenue = new List<String>{'Pricebook2Id','Reason_for_Contract_Amendment__c',
				'EBH_MainVertical__c','EBH_StoreSubscription__c','AM_Bolt_on__c'};
	static set<String> sStatus = new Set<String>{'Expired','Voided'};			
	////NK:12.03.2021:US-0009233
	// static List<String> listcontractFields = new List<String>{'RecordTypeId', 'OwnerId', 'EBH_Country__c', 'AccountId',
	// 			'EBH_ContractAmendment__c','EBH_Language__c','EBH_Site__c','CurrencyIsoCode','EBH_RequesterNotes__c',
	// 			'EBH_LinkedContract__c','EBH_PreApprovedTemplate__c','EBH_FinanceAgreesinPrincipal__c', 'Status','EBH_EUSignNotes__c',
	// 			'EBH_eBayLegalEntity__c', 'EBH_ContractValue__c', 'EBH_eTRSEligible__c', 'EBH_ContractExposure__c',
	// 			'Reason_for_Contract_Amendment__c','EBH_MainVertical__c','EBH_StoreSubscription__c','AM_Bolt_on__c',
	// 			'EBH_DeceleratorThreshold__c', 'EBH_MainTierThresholdofTarget__c', 'EBH_AcceleratorThreshold__c', 
	// 			'EBH_GMVforContractPeriod__c','EBH_AverageTakeRate__c', 'EBH_DeceleratorTierrebate__c', 'EBH_RebateTierrebate__c', 
	// 			'EBH_AcceleratorTierrebate__c','EBH_IncrementalGMVonly__c', 'EBH_Partner__c', 'Pricebook2Id'};
	public static boolean from_clone = false;
	final static Set<String> SET_PRICING_PKL_DEPENTDANT = new Set<String>{'EBH_GalleryPlus__c','EBH_InsertionFees__c','EBH_InternationalSiteVisibility__c','EBH_PicturePack1_12__c','EBH_Subtitle__c','EBH_XXLBild__c'};
/*****************************************************************************************************************************
	@ Method:   apexCloneContract
	@ Version:  1.0
	@ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
	@ Purpose:  US-0003807 [Contracts] Ability to clone pricing details when cloning Contract
	@ AC1 : Cloned Contract to include all related Pricing information from the Cloning Contract
	@ Given that Any User
	@ Navigate to Contracts Tab ->Select a ACP Contract that has related Pricing records
	@ Then I click "Clone" in the Contract Detail Page"
	@ all the Contract Details( Contract Information, Lifecycle, Signatory Details,Pricing Information)
	@ and
	@ related Pricing,Contract Seller,Attachment,RelatedContract should be copied completely to the newly created cloned Contract record.
	@ AC2 : Repeat AC1 to test the Clone functionality for other Contract Record types(Listing Agreement).
	@ See Attached screen shot "Listing Agreement Contracts(Fields and Related Records that needs to be copied)" for testing verification.
	@ AC3 : Repeat AC1 to test the Clone functionality for other Contract Record types(Revenue Share).
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      parentId:  contractId
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 22.01.2020 / Sovantheany Dim / Created the  Method.
	@				: 12.03.2021/ Vadhanak Voun / US-0009233 - {Hypercare} - [Contracts] - Users unable to clone existing contract
	@				: 09/06/2021 / Sovantheany Dim / US-0009603 - [Contract Clone] Cloned contract does not pass through approvals
	@				Given that I am any user(Contract Owner)
	@				Select any Contract(record type = Listing Agreement or ACP)
	@ 				Clone a Contract with Contract.status !=Expired or Voided
	@				so that the newly cloned contract should have the below value
	@					contract.EBH_FinancePostCheckDone__c = False
	@					contract.Surcharge__c = "Y"
	@				: 09/08/2021/vadhanak voun/ US-0010029 - [Clone] When Cloning a Contract the new field values "Contract Signed by" and "Seller Signed Date" to be cleared off
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexCloneContract(String parentId)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        try
		{
			RecordType acpRecordType = ApexUtil.getRecordTypeByName('Contract',EBH_ConstantsUtility.CONTRACT_ACPRECORDTYPE);
			RecordType listingRecordType = ApexUtil.getRecordTypeByName('Contract',EBH_ConstantsUtility.CONTRACT_LISTINGRECORDTYPE);
			RecordType rsRecordType = ApexUtil.getRecordTypeByName('Contract',EBH_ConstantsUtility.CONTRACT_RSRECORDTYPE);
			
			//Map Contract Record type with list of Contract fields that is not clone
			Map<String,List<String>> mapContractRecordType = new Map<String,List<String>>();
			mapContractRecordType.put(acpRecordType.id,listFieldForACP);
			mapContractRecordType.put(listingRecordType.id,listFieldForListing);
			mapContractRecordType.put(rsRecordType.id,listFieldForRevenue);
			
			String contractFields = ApexUtil.generateSQOLFields('Contract');//String.join(listcontractFields,','); //NK:12.03.2021:US-0009233
			String soqlContract  = 'Select '+contractFields+' From Contract Where Id =: parentId';
			String soqlContractSeller  = 'Select '+ApexUtil.generateSQOLFields('EBH_ContractSeller__c')+' From EBH_ContractSeller__c Where EBH_ContractNumber__c =: parentId';
			String soqlPricing = 'Select '+ApexUtil.generateSQOLFields('EBH_Pricing__c')+' from EBH_Pricing__c where EBH_ContractId__c =: parentId';
			String soqlAttachement = 'Select '+ApexUtil.generateSQOLFields('Attachment')+' From Attachment where ParentId =: parentId';
			String soqlRelatedContracts = 'Select '+contractFields+' From Contract Where EBH_LinkedContract__c =: parentId';
			String soqlContentDucumentLink = 'Select '+ApexUtil.generateSQOLFields('ContentDocumentLink')+' FROM ContentDocumentLink where LinkedEntityId =: parentId';
			
			//Clone Contract
			List<Contract> contracts = Database.query(soqlContract);
			Contract cloneContract = contracts[0].clone(false,true,false,false);
			//TH: US-0009603:if Contract.status !=Expired or Voided and contract record type = Listing Agreement or ACP
			if(!sStatus.contains(contracts[0].Status) && (contracts[0].RecordTypeId == acpRecordType.id || contracts[0].RecordTypeId == listingRecordType.id)){
				cloneContract.EBH_FinancePostCheckDone__c = false;
    			cloneContract.Surcharge__c = true;
			}
			//End : US-0009603
    		cloneContract.Status = 'Draft';

			//NK:US-0010029:09/08/2021: fields to be reset
			for(Schema.FieldSetMember fld : SObjectType.Contract.FieldSets.Reset_Fields_Clone.getFields()) 
			{
               if(fld.getType() == Schema.DisplayType.BOOLEAN)
			   {
					cloneContract.put(fld.getFieldPath(),false);
			   }else
			   {
					cloneContract.put(fld.getFieldPath(),null);
			   } 
            }

    		if(mapContractRecordType.containsKey(contracts[0].RecordTypeId)){
    			for(String fieldApiName : mapContractRecordType.get(contracts[0].RecordTypeId)){
    				if(fieldApiName == 'EBH_IncrementalGMVonly__c'){
    					cloneContract.put(fieldApiName,false);
    				}else{
    					cloneContract.put(fieldApiName,null);
    				}
    			}
    		}
    		insert cloneContract;
    		//1.Clone Contract Seller
    		List<EBH_ContractSeller__c> lstContractSellerToClone = new List<EBH_ContractSeller__c>();
    		for(EBH_ContractSeller__c contractSeller : Database.query(soqlContractSeller)){
    			EBH_ContractSeller__c contractSellerClone = contractSeller.clone(false,true,false,false);
    			contractSellerClone.EBH_ContractNumber__c = cloneContract.Id;
    			lstContractSellerToClone.add(contractSellerClone);  
    		}
    		if(!lstContractSellerToClone.isEmpty()){
    			insert lstContractSellerToClone;
    		}
    		//End Contract Seller
    		//2.Clone Pricing
    		List<EBH_Pricing__c> lstPricingToClone = new List<EBH_Pricing__c>();
    		for(EBH_Pricing__c pricing : Database.query(soqlPricing)){				
    			EBH_Pricing__c pricingClone = pricing.clone(false,true,false,false);
				//NK:US-0009233
				//depentdant picklist available for recordtype but not for site, when receive default value, cuases bad value!
				for(String fName : SET_PRICING_PKL_DEPENTDANT)
				{
					//system.debug('_______name: '+fName+'--vale: '+pricing.get(fName) +'>>>>: '+ String.isBlank(pricing.get(fName)+''));
					if(pricing.get(fName)==null )
					{
						pricingClone.put(fName, null); 
					}
				}

    			pricingClone.EBH_ContractId__c = cloneContract.Id;
    			lstPricingToClone.add(pricingClone);  
    		}
    		if(!lstPricingToClone.isEmpty()){
    			insert lstPricingToClone;
    		}
    		//End Pricing
    		//3.Clone Attachment
    		List<Attachment> lstAttachmentToClone = new List<Attachment>();
    		for(Attachment att : Database.query(soqlAttachement)){
    			Attachment attClone = att.clone(false,true,false,false);
    			attClone.ParentId = cloneContract.Id;
    			lstAttachmentToClone.add(attClone);  
    		}
    		if(!lstAttachmentToClone.isEmpty()){
    			insert lstAttachmentToClone;
    		}
    		
    		List<ContentDocumentLink> lstContentDocLinkToClone = new List<ContentDocumentLink>();
    		for(ContentDocumentLink contendDocLink : Database.query(soqlContentDucumentLink)){
    			ContentDocumentLink contendDocLinkClone = contendDocLink.clone(false,true,false,false);
    			contendDocLinkClone.LinkedEntityId = cloneContract.Id;
    			lstContentDocLinkToClone.add(contendDocLinkClone); 
    		}
    		if(!lstContentDocLinkToClone.isEmpty()){
    			from_clone = true;
    			insert lstContentDocLinkToClone;
    		}
    		//EndAttachement
    		//5.Clone Child Contract
    		List<Contract> lstRelateContractToClone = new List<Contract>();
    		for(Contract relateContract : Database.query(soqlRelatedContracts)){
    			Contract relateContractClone = relateContract.clone(false,true,false,false);
    			relateContractClone.EBH_LinkedContract__c = cloneContract.Id;
    			if(mapContractRecordType.containsKey(relateContract.RecordTypeId)){
    			for(String fieldApiName : mapContractRecordType.get(relateContract.RecordTypeId)){
    				if(fieldApiName == 'EBH_IncrementalGMVonly__c'){
    					relateContractClone.put(fieldApiName,false);
    				}else{
    					relateContractClone.put(fieldApiName,null);
    				}
    			}
    		}
    			lstRelateContractToClone.add(relateContractClone);  
    		}
    		if(!lstRelateContractToClone.isEmpty()){
    			insert lstRelateContractToClone;
    		}
    		//End Child contract
			mapResult.put('status','ok');
			mapResult.put('contractId',cloneContract.Id+'');
		}
		catch(DmlException ex)
		{
			mapResult.put('status','ko');
			mapResult.put('error',ex.getDmlMessage(0));
			System.debug(ex);
		}catch(Exception ex2)
		{
			mapResult.put('status','ko');
			mapResult.put('error',ex2.getMessage());
			System.debug(ex2);
		}
        return mapResult;
    }
    
}