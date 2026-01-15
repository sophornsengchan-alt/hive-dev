/*********************************************************************************************************************************
@ Class:          EBH_ProjectTriggerHandler
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Handler Class for Project Trigger
                  US-0006886 [AU] Approval Process for eBay AU SMB Project with lead Source "Self Gen"
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  26.12.2019 / Sovantheany Dim /Created the class.
@ Change history:  30.06.2023 / Chetra Sarom / US-0013306 - Retirement of Managed Payment Solution (Technical Debt3)
@ Change history:  18.09.2024 / Vimean Heng / US-0015879 - 1.2 One-Off Account Management Project record needs to be created only from quick actions button / Deprecated the methode, Reason : This method is deprecated in EBH_Project.trigger.
@ Change history:  23.09.2024 / Acmatac Seing / US-0015913 - Post DE launch Fixes - Automations
@ 				:  31.10.2024 / Davy Sorn / US-0016145 - Error When Submit Formsite & Outreach
@ 				:  07.11.2024 / Chan Sophorn / US-0016017 - Exclude System Admin from the validation for One-Off record creation validation
@				:  07.01.2025 / Sothea Horn / US-0016405 - Opportunity Acc Id to be populated with Seller
*********************************************************************************************************************************/
public with sharing class EBH_ProjectTriggerHandler {
		// *** PUBLIC ***
		public static final String PROJECT_STAGE_LIVETOSITE = 'Live to Site';
		public static final String PROJECT_STAGE_COMPLETED = 'Completed';
		public static final String PROJECT_STAGE_SUBMITTED = 'Submitted';
		public static Boolean isFromQuickAction = false; // vaiable can be assigned from quick action ( CreateProjectController method createProject )
		public static final String ACCOUNT_SOQL = 'SELECT Id, Name, Website, EBH_VATNumber__c, EBH_OracleId__c, EBH_ActualStandard__c FROM Account ';
		// *** END PUBLIC ***
		
		// *** PRIVATE ***
		private static final String RECORDTYPE_ONE_OFF_ACCOUNT_MANAGEMENT = 'One_Off_Account_Management'; //EBH Project Record Type
		private static final String PS_BYPASS_VALIDATION_RULE = 'Bypass_Validation_Rule'; //custom permission set
		private static final String EBH_PROJECT = 'EBH_Project__c'; // custom object (Project)
		// *** END PRIVATE ***
		/*****************************************************************************************************************************
		@ Method:       validateOneOfAccountManagement
		@ Author:       Vimean Heng (vimean.heng@gaea-sys.com)
		@ Purpose:      US-0015879 - 1.2 One-Off Account Management Project record needs to be created only from quick actions button
		@ Event: 		before insert
		------------------------------------------------------------------------------------------------------------------------------
		@ Parameter:	List<EBH_Project__c> lstProj => List of Project before insert
		------------------------------------------------------------------------------------------------------------------------------
		@ Change history:  18.09.2024 / Vimean Heng / Created the methode.
		@ 				:  07.11.2024 / Chan Sophorn / US-0016017 - Exclude System Admin from the validation for One-Off record creation validation
		@*****************************************************************************************************************************/
		public static void validateOneOfAccountManagement(List<EBH_Project__c> lstProj) {
			RecordType oneOffRecordType = ApexUtil.getRecordTypeByName(EBH_PROJECT, RECORDTYPE_ONE_OFF_ACCOUNT_MANAGEMENT);
			//system.debug('System.currentPageReference(): ' + System.currentPageReference());
			if(!isByPassValidationRule() && !isFromQuickAction ){
				for(EBH_Project__c pro : lstProj){
					// Record Type = One-Off Account Management,We are allowed create from Quick Action only.
					if(pro.RecordTypeId == oneOffRecordType.Id){
						//show error
						pro.addError(Label.Project_One_Off_Account_Management_Error);
					}
				}
			}
	
		}
		private static boolean isByPassValidationRule(){
			//check bypass validation rule
			byPass__c bp = byPass__c.getInstance(UserInfo.getUserId());
			Boolean hasByPassPS = FeatureManagement.checkPermission(PS_BYPASS_VALIDATION_RULE);
			// CSP-07112024-US-0016017
			return (bp!=null && bp.ByPass_Validation__c && !String.isBlank(bp.triggerObjects__c) && bp.triggerObjects__c.containsIgnoreCase(EBH_PROJECT)) && hasByPassPS;
		}
	
		/*********************************************************************************************************************************
		@ Method:       autoLinkSeller
		@ Author:       Acmatac Seing
		@ Purpose:      US-0015650, US-0015662 : Reusable method to auto link seller whenever a seller or oracleId field get changed
						Using in Lead, Project and Opportunity
		@ Parameter:    oldMap: Trigger.oldMap, List<SObject> Trigger.newMap, 
						recordTypeId, sellerFieldAPI: api name of the seller field, oracleIdFieldAPI: api name of the oracleId field
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history:  12.08.2024 / Acmatac Seing / create the method
		@				:  31.10.2024 / Davy Sorn / US-0016145 - Error When Submit Formsite & Outreach
		@				:  07.01.2025 / Sothea Horn / US-0016405 - Opportunity Acc Id to be populated with Seller
		*********************************************************************************************************************************/
		public static void autoLinkSeller(Map<Id, SObject> oldMap, List<SObject> newRecordList){
			Set<String> sellerIds = new Set<String>();
			Set<String> oracleIds = new Set<String>();
	
			AutoLinkSellerWrapper asw = new AutoLinkSellerWrapper();
			if(!newRecordList.isEmpty()){
				String objectAPIName = String.valueOf(newRecordList.get(0).getSObjectType());
				if(objectAPIName == 'Lead'){
					asw = setAutoLinkData(
						new Set<String>{LeadTriggerHandler.RT_LEAD_EBDEV_ID, ApexUtil.getRecordTypeByName('Lead', 'EBH_eBayAUSMB').Id},
						'eBayID__c',
						'EBH_OracleID__c',
						'EBH_eBayID__c',
						null,
						// 07.01.2025 / Sothea Horn / US-0016405 - Opportunity Acc Id to be populated with Seller
						null,
						null
					);
				}else if(objectAPIName == 'Opportunity'){
					asw = setAutoLinkData(
						new Set<String>{OpportunityTriggerHandler.opportunityRecTypeBD.Id},
						'Seller__c',
						'Oracle_ID__c',
						'Seller_Name__c',
						null,
						// 07.01.2025 / Sothea Horn / US-0016405 - Opportunity Acc Id to be populated with Seller
						'AccountId',
						'LegalEntity__c'
					);
				}else if(objectAPIName == EBH_PROJECT){
					asw = setAutoLinkData(
						new Set<String>{ApexUtil.getRecordTypeByName(EBH_PROJECT, 'Integration_Help').Id, ApexUtil.getRecordTypeByName(EBH_PROJECT, 'EUOnboarding').Id},
						'EBH_Seller__c',
						'OracleID__c',
						'Seller_Name__c',
						'Incoming_Seller_Standard__c',
						// 07.01.2025 / Sothea Horn / US-0016405 - Opportunity Acc Id to be populated with Seller
						null,
						null
					);
				}
			}
			if(!newRecordList.isEmpty() && !asw.recordTypeIds.contains(String.valueOf(newRecordList[0].get('RecordTypeId')))) {
				return;
			}
			for (SObject newRecord : newRecordList){
				if (asw.recordTypeIds.contains(String.valueOf(newRecord.get('RecordTypeId')))){
					if (String.isNotBlank(String.valueOf(newRecord.get(asw.sellerFieldAPI)))){
						// New Context || Update Context
						if(oldMap == null || (oldMap != null && newRecord.get(asw.sellerFieldAPI) != oldMap.get(newRecord.Id).get(asw.sellerFieldAPI))){
							sellerIds.add(String.valueOf(newRecord.get(asw.sellerFieldAPI)));
				}
					} else if (String.isNotBlank(String.valueOf(newRecord.get(asw.oracleIdFieldAPI)))){
						// New Context || Update Context
						if(oldMap == null || (oldMap != null && newRecord.get(asw.oracleIdFieldAPI) != oldMap.get(newRecord.Id).get(asw.oracleIdFieldAPI) 
												&& String.isNotBlank(String.valueOf(newRecord.get(asw.oracleIdFieldAPI))) 
												&& String.isBlank(String.valueOf(newRecord.get(asw.sellerFieldAPI))))){
							oracleIds.add(String.valueOf(newRecord.get(asw.oracleIdFieldAPI)));
					}
				}
			}
		}
		
		if (sellerIds.isEmpty() && oracleIds.isEmpty()) { // 31.10.2024 / Davy Sorn / US-0016145
			return;
		}

			Map<String, Account> mapOfSeller = new Map<String, Account>();
			String buildSOQL = ACCOUNT_SOQL+ ' WHERE Id IN :sellerIds OR EBH_OracleId__c IN :oracleIds';
			for(Account oAcc : (List<Account>) ApexSafe.query().doQuery(buildSOQL, new Map<String, Object> {'sellerIds' => sellerIds, 'oracleIds' => oracleIds})){
				mapOfSeller.put(oAcc.Id, oAcc);
				if(String.isNotBlank(oAcc.EBH_OracleId__c)){
					mapOfSeller.put(oAcc.EBH_OracleId__c, oAcc);
						} 
					}
			populateAutoLinkSellerFields(oldMap, newRecordList, mapOfSeller, asw);
				}
				
		/*********************************************************************************************************************************
		@ Method:       populateAutoLinkSellerFields
		@ Author:       Acmatac Seing
		@ Purpose:      US-0015650, US-0015662 : Method to populate fields from autoLinkSeller method
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history:  13.08.2024 / Acmatac Seing / create the method
		@				:  07.01.2025 / Sothea Horn / US-0016405 - Opportunity Acc Id to be populated with Seller
		*********************************************************************************************************************************/
		private static void populateAutoLinkSellerFields(Map<Id, SObject> oldMap, List<SObject> newRecordList, Map<String, Account> mapOfSeller, AutoLinkSellerWrapper asw){
			for (SObject newRecord : newRecordList){
				String objectAPIName = String.valueOf(newRecord.getSObjectType());
				if (asw.recordTypeIds.contains(String.valueOf(newRecord.get('RecordTypeId')))){
					if (String.isNotBlank(String.valueOf(newRecord.get(asw.sellerFieldAPI)))){
						// New Context || Update Context
						if(oldMap == null || (oldMap != null && newRecord.get(asw.sellerFieldAPI) != oldMap.get(newRecord.Id).get(asw.sellerFieldAPI))){
							if(mapOfSeller.containsKey(String.valueOf(newRecord.get(asw.sellerFieldAPI)))){
								newRecord.put(asw.oracleIdFieldAPI, mapOfSeller.get(String.valueOf(newRecord.get(asw.sellerFieldAPI))).EBH_OracleId__c);
								newRecord.put(asw.sellerNameFieldAPI, mapOfSeller.get(String.valueOf(newRecord.get(asw.sellerFieldAPI))).Name);
								if(objectAPIName == EBH_PROJECT){
									newRecord.put(asw.incomingSellerStandardFieldAPI, mapOfSeller.get(String.valueOf(newRecord.get(asw.sellerFieldAPI))).EBH_ActualStandard__c);
								}
								// 07.01.2025 / Sothea Horn / (US-0016405) BD Opportunity,AccountId to be populated with Seller Id if Opportunity.Legal Entity is populated
								if (objectAPIName == 'Opportunity' && isLegalEntityPopulated(newRecord, asw)) {
									newRecord.put(asw.accountIdFieldAPI, mapOfSeller.get(String.valueOf(newRecord.get(asw.sellerFieldAPI))).Id);
								}
							}
						}
					} else if (String.isNotBlank(String.valueOf(newRecord.get(asw.oracleIdFieldAPI)))){
						// New Context || Update Context
						if(oldMap == null || (oldMap != null && newRecord.get(asw.oracleIdFieldAPI) != oldMap.get(newRecord.Id).get(asw.oracleIdFieldAPI) 
												&& String.isNotBlank(String.valueOf(newRecord.get(asw.oracleIdFieldAPI))) 
												&& String.isBlank(String.valueOf(newRecord.get(asw.sellerFieldAPI))))){
							if(mapOfSeller.containsKey(String.valueOf(newRecord.get(asw.oracleIdFieldAPI)))){
								newRecord.put(asw.sellerFieldAPI, mapOfSeller.get(String.valueOf(newRecord.get(asw.oracleIdFieldAPI))).Id);
								newRecord.put(asw.sellerNameFieldAPI, mapOfSeller.get(String.valueOf(newRecord.get(asw.oracleIdFieldAPI))).Name);
								if(objectAPIName == EBH_PROJECT){
									newRecord.put(asw.incomingSellerStandardFieldAPI, mapOfSeller.get(String.valueOf(newRecord.get(asw.oracleIdFieldAPI))).EBH_ActualStandard__c);
								}
								// 07.01.2025 / Sothea Horn / (US-0016405) BD Opportunity,AccountId to be populated with Seller Id if Opportunity.Legal Entity is populated
								if (objectAPIName == 'Opportunity' && isLegalEntityPopulated(newRecord, asw)) {
									newRecord.put(asw.accountIdFieldAPI, mapOfSeller.get(String.valueOf(newRecord.get(asw.oracleIdFieldAPI))).Id);
								}
							}
						}
					}
				}
			}
			}
		
		/*********************************************************************************************************************************
		@ Method:       isLegalEntityPopulated
		@ Author:       Sothea Horn
		@ Purpose:      US-0016405 : Method to check whether Legal Enity is populated
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history:  07.01.2025 / Sothea Horn / Create the method
		*********************************************************************************************************************************/
		private static Boolean isLegalEntityPopulated(SObject newRecord, AutoLinkSellerWrapper asw) {
			return  String.isNotBlank(String.valueOf(newRecord.get(asw.legalEntityFieldAPI)));
		}
			
		private static AutoLinkSellerWrapper setAutoLinkData(Set<String> recordTypeIds, String sellerFieldAPI, String oracleIdFieldAPI, String sellerNameFieldAPI, String incomingSellerStandardFieldAPI, String accountIdFieldAPI, String legalEntityFieldAPI){
			AutoLinkSellerWrapper asw = new AutoLinkSellerWrapper();
			asw.recordTypeIds = recordTypeIds;
			asw.sellerFieldAPI = sellerFieldAPI;
			asw.oracleIdFieldAPI = oracleIdFieldAPI;
			asw.sellerNameFieldAPI = sellerNameFieldAPI;
			asw.incomingSellerStandardFieldAPI = incomingSellerStandardFieldAPI;
			//  07.01.2025 / Sothea Horn / US-0016405 - Opportunity Acc Id to be populated with Seller
			asw.accountIdFieldAPI = accountIdFieldAPI;
			asw.legalEntityFieldAPI = legalEntityFieldAPI;

			return asw;
		}
	
		public class AutoLinkSellerWrapper{
			public String sellerFieldAPI {get;set;}
			public String oracleIdFieldAPI {get;set;}
			public String sellerNameFieldAPI {get;set;}
			public String incomingSellerStandardFieldAPI {get;set;}
			public Set<String> recordTypeIds {get;set;}
			//  07.01.2025 / Sothea Horn / US-0016405 - Opportunity Acc Id to be populated with Seller
			public String accountIdFieldAPI {get;set;} 
			public String legalEntityFieldAPI {get;set;} 

			public AutoLinkSellerWrapper(){
				this.sellerFieldAPI = '';
				this.oracleIdFieldAPI = '';
				this.sellerNameFieldAPI = '';
				this.incomingSellerStandardFieldAPI = '';
				this.recordTypeIds = new Set<String>();
				//  07.01.2025 / Sothea Horn / US-0016405 - Opportunity Acc Id to be populated with Seller
				this.accountIdFieldAPI = ''; 
				this.legalEntityFieldAPI = ''; 
			}
		}
	}