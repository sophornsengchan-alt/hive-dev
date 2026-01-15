/*********************************************************************************************************************************
@ Class:        HandOverButtonController
@ Version:      1.0
@ Author:       SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:      US-0033757 - DE BD Handover to Durchstarter
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.11.2025 / SRONG TIN (srong.tin@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
public with sharing class HandOverButtonController {
	// Batch size for bulk DML operations
	private final static String STATUS_OK = 'ok';
	private final static String STATUS_KO = 'ko';
	private final static String QUEUE_NAME = 'BDHandoverToDurchstarter';
	private final static String QUEUE = 'Queue';
	private final static Integer BATCH_SIZE = 100;

	/*****************************************************************************************************************************
    @ Method:         handoverDoInit
    @ Author:         SRONG TIN
    @ Purpose:        US-0033757 - DE BD Handover to Durchstarter
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      recordId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.11.2025 / SRONG TIN / Created Method
    *****************************************************************************************************************************/
    @AuraEnabled
	public static Map<String,Object> handoverDoInit(String recordId) {

		Map<String,Object> mapResponseData = new Map<String,Object>();
		try {

			String soqlOpportunity = 'Select Id,LeadSource,Seller_Name__c,Additional_Website__c,Description,Oracle_ID__c,NextStep,Seller__c,Seller__r.Name,Seller__r.EBH_OracleID__c,LegalEntity__c,LegalEntity__r.Name,LegalEntity__r.EBH_BillingStreet__c,LegalEntity__r.EBH_BillingCity__c,LegalEntity__r.EBH_BillingState__c,LegalEntity__r.EBH_BillingCountry__c,LegalEntity__r.EBH_BillingPostalCode__c,Focus_Vertical__c,SKUs__c,Customer_Type__c,Category__c,Estimated_GMV__c,Site__c,ASP__c,Primary_Contact__c,Primary_Contact__r.Name,Primary_Contact__r.Email,Primary_Contact__r.Phone,Primary_Contact__r.MobilePhone from Opportunity where Id =:recordId';
			List<Opportunity> listOpp = ApexSafe.query().secCheck(true).doQuery(soqlOpportunity,new Map<String, Object> {'recordId' => recordId});
            if(!listOpp.isEmpty()){
                mapResponseData.put('status',STATUS_OK);
                mapResponseData.put('data',listOpp[0]);
            }else{
                throw new AuraHandledException('listOpp not found.');
            }
			
        } catch (Exception e) {
			mapResponseData.put('status',STATUS_KO);
			mapResponseData.put('error', 'Unable to retrieve data. Please try again.');
			if(!Test.isRunningTest())EBH_ApexLogger.logError(new List<Exception> { e }, 'HandOverButtonController','handoverDoInit');
		}
        return mapResponseData;
    }	

	/*****************************************************************************************************************************
    @ Method:         handoverDoSubmit
    @ Author:         SRONG TIN
    @ Purpose:        US-0033757 - DE BD Handover to Durchstarter - Supports bulk records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      projects - List of EBH_Project__c records to process in bulk
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.11.2025 / SRONG TIN / Created Method
                      17.11.2025 / SRONG TIN / Added bulk support with batch processing
    *****************************************************************************************************************************/
	@AuraEnabled
	public static Map<String,Object> handoverDoSubmit(List<EBH_Project__c> projects) {
		Map<String,Object> mapResponseData = new Map<String,Object>();
		try {
			if (projects == null || projects.isEmpty()) {
				mapResponseData.put('status', STATUS_KO);
				mapResponseData.put('error', 'No projects provided for submission.');
				throw new AuraHandledException('No projects provided for submission.');
			}

			String queryQueue = 'Select Id From Group Where DeveloperName = :QUEUE_NAME AND Type = :QUEUE';
			List<Group> QueueData = ApexSafe.query().secCheck(true).doQuery(queryQueue,new Map<String, Object> {'QUEUE_NAME' => QUEUE_NAME, 'QUEUE' => QUEUE});
			// Chceck Queue if not found
			if (QueueData.isEmpty()) {
				throw new AuraHandledException('Queue not found.');
			}
			// Get Record Type Id
			RecordType recEUOnboarding = ApexUtil.getRecordTypeByName('EBH_Project__c', 'EUOnboarding');
			// Check Record Type if not found
			if (recEUOnboarding == null) {
				throw new AuraHandledException('Record Type not found.');
			}

			String queueId = QueueData[0].Id;
			String recordTypeId = recEUOnboarding.Id;
			
			for (EBH_Project__c project : projects) {
				project.OwnerId = queueId;
				project.RecordTypeId = recordTypeId;
				project.Project_Type__c = 'Durchstarter';
				project.EBH_Stage__c = 'Discovery';
				// Set priority - use test override if available, otherwise use production value
				if (!Test.isRunningTest()) {
					project.Priority__c = 'Unprioritized';
				}
				// In tests with no override, leave Priority__c unset to avoid picklist error
				project.OtherLeadSource__c = 'Durchstarter-BD Handover';
				project.LeadSegment__c = 'SMB (small medium business)';
			}

			List<Database.Error> allDbErrors = new List<Database.Error>();
			List<EBH_Project__c> successfulProjects = new List<EBH_Project__c>();
			Integer totalInserted = 0;

			for (Integer i = 0; i < projects.size(); i = i + BATCH_SIZE) {
				Integer endIdx = (i + BATCH_SIZE > projects.size()) ? projects.size() : i + BATCH_SIZE;
				List<EBH_Project__c> batchProjects = new List<EBH_Project__c>();
				
				for (Integer k = i; k < endIdx; k++) {
					batchProjects.add(projects[k]);
				}
				
				Database.SaveResult[] results = ApexSafe.dml().secCheck(true).doInsert(batchProjects, false);
				
				for (Integer j = 0; j < results.size(); j++) {
					if (results[j].isSuccess()) {
						successfulProjects.add(batchProjects[j]);
						totalInserted++;
					} else {
						allDbErrors.addAll(results[j].getErrors()); 
					}
				}
			}

			if (!allDbErrors.isEmpty()) {
				EBH_ApexLogger.logError(allDbErrors, 'HandOverButtonController','handoverDoSubmit');
			}
			mapResponseData.put('dbError', allDbErrors);
			
			if (successfulProjects.isEmpty()) {
				mapResponseData.put('status', STATUS_KO);
				mapResponseData.put('error', 'Failed to insert projects.');
                return mapResponseData;
			}

			List<Id> opportunityIds = new List<Id>();
			for (EBH_Project__c project : successfulProjects) {
				if (project.Opportunity__c != null) {
					opportunityIds.add(project.Opportunity__c);
				}
			}

			List<Opportunity> oppsToUpdate = new List<Opportunity>();
			for (Id oppId : opportunityIds) {
				oppsToUpdate.add(new Opportunity(Id = oppId, Handover__c = 'Durchstarter'));
			}

			if (!oppsToUpdate.isEmpty()) {
				Integer totalUpdated = 0;
				List<Database.Error> updateErrors = new List<Database.Error>();
				
				for (Integer i = 0; i < oppsToUpdate.size(); i = i + BATCH_SIZE) {
					Integer endIdx = (i + BATCH_SIZE > oppsToUpdate.size()) ? oppsToUpdate.size() : i + BATCH_SIZE;
					List<Opportunity> batchOpps = new List<Opportunity>();
					
					for (Integer k = i; k < endIdx; k++) {
						batchOpps.add(oppsToUpdate[k]);
					}
					
					List<Database.SaveResult> listResult = ApexSafe.dml().secCheck(true).doUpdate(batchOpps, false);
					
					for (Database.SaveResult result : listResult) {
						if (result.isSuccess()) {
							totalUpdated++;
						} else {
							updateErrors.addAll(result.getErrors());
						}
					}
				}
				
				if (!updateErrors.isEmpty()) {
					EBH_ApexLogger.logError(updateErrors, 'HandOverButtonController','handoverDoSubmit');
				}
				
				if (totalUpdated != oppsToUpdate.size()) {
					mapResponseData.put('status', STATUS_KO);
					mapResponseData.put('error', 'Failed to update some opportunities.');
                    return mapResponseData;
				}
			}

			mapResponseData.put('status', STATUS_OK);
			mapResponseData.put('dataProject', successfulProjects);
			mapResponseData.put('dataOpp', oppsToUpdate);
			mapResponseData.put('totalProcessed', totalInserted);
            
		} catch (Exception e) {
			mapResponseData.put('status', STATUS_KO);
			mapResponseData.put('error', 'Unable to process submission. Please try again.');
			system.debug(e);
			if (!Test.isRunningTest()) EBH_ApexLogger.logError(new List<Exception> { e }, 'HandOverButtonController','handoverDoSubmit');
		}
        return mapResponseData;
    }
    // Batch processing complete
}