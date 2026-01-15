/*********************************************************************************************************************************
@ Class:        BatchLeadConversion
@ Version:      1.0
@ Author:       Acmatac Seing (acmatac.seing@gaea-sys.com)
@ Purpose:    	US-0006501[AU] AU Lead Conversion Automation - 2.Relate DWH Seller and Contact(DWH)
				- Lead is automatically converted 
				- Associated to the "Project.Seller" Record 
				

----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.December.2019 / Acmatac Seing (acmatac.seing@gaea-sys.com) / Created the batch class.
					3.January.2020 / Acmatac Seing (acmatac.seing@gaea-sys.com) / Add Project stage criteria.
					27.March.2020 / Acmatac Seing (acmatac.seing@gaea-sys.com) / [US-0007336] - [AU & EU ] AU Lead Conversion Automation - 2.Relate DWH Seller and Contact(DWH)
*********************************************************************************************************************************/

global class BatchLeadConversion implements Database.Batchable<SObject> {

	private String contactRTManual = ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL').Id;
	private Set<String> sProjRT = new Set<String>{EBH_ConstantsUtility.PROJECT_RT_AUSMB, EBH_ConstantsUtility.PROJECT_RT_AUENTERPRISE};
	private Set<String> projStage = new Set<String>{EBH_ConstantsUtility.PROJECT_STAGE_LIVETOSITE, EBH_ConstantsUtility.PROJECT_STAGE_STORELAUNCHED};
	private String leadStatus = EBH_ConstantsUtility.LEAD_STATUS_QUALIFIED;

	@TestVisible
	private String sqlStr = EBH_ConstantsUtility.BATCH_LEAD_SQL + ' WHERE RecordType.DeveloperName IN: sProjRT '+
									' AND EBH_Seller__c <> null '+
									' AND Lead__c <> null '+
									' AND Lead__r.Email <> null '+
									// ' AND EBH_Seller__r.Primary_Contact__c <> null '+
									// ' AND EBH_Seller__r.Primary_Contact__r.Email <> null '+
									' AND EBH_Stage__c IN: projStage '+
									' AND Lead__r.Status =: leadStatus '+
									' AND Lead__r.IsConverted = false'+
									' AND Lead__r.RecordType.DeveloperName = \'EBH_eBayAUSMB\' ORDER BY Id';
	//
	global Database.querylocator start(Database.BatchableContext bc) {
        // Fix error testclass running batch record more than 200, AMT@15.04.20
        if(Test.isRunningTest()) sqlStr += ' LIMIT 10';
        return Database.getQueryLocator(sqlStr);
    }
    global void execute(Database.BatchableContext bc, List<EBH_Project__c> scope) {
		try {
			List<Database.LeadConvert> lstLeadConv = new List<Database.LeadConvert>();
			Map<Id, Contact> mLeadCont = new Map<Id, Contact>();
			Map<String, String> mLead_Acc = new Map<String, String>();

			for(EBH_Project__c oneProj : scope){
				// 1 Lead <=> 1 Project and take only the first old one, @AMT 2.April.20
				if(mLead_Acc.containsKey(oneProj.Lead__c)) continue;

				mLead_Acc.put(oneProj.Lead__c, oneProj.EBH_Seller__c);

				Database.LeadConvert leadConv = new Database.LeadConvert();
				leadConv.setLeadId(oneProj.Lead__c);
				leadConv.setConvertedStatus('Converted');
				leadConv.setDoNotCreateOpportunity(true);
				leadConv.setAccountId(oneProj.EBH_Seller__c);

				// Verify the Lead Contact (Email Address) exists in the seller we associated in step1. (Match by Lead Email Address) 
				// if found merge Lead Contact details with DWH fields.
				Contact oneCont = new Contact();
				if(String.isNotBlank(oneProj.EBH_Seller__r.Primary_Contact__c) && oneProj.Lead__r.Email == oneProj.EBH_Seller__r.Primary_Contact__r.Email){
					leadConv.setContactId(oneProj.EBH_Seller__r.Primary_Contact__c);
					oneCont = mergeDWHContactMatch(oneCont, oneProj);
					oneCont.Id = oneProj.EBH_Seller__r.Primary_Contact__c;

					mLeadCont.put(oneProj.Lead__c, oneCont);
				}
				// If the Lead contact (Email Address) does not match,
				// Create a manual contact for the DWH seller with the details from lead. 
				// These contacts will have record type as “manual” and will be related to the DWH Seller (Customer) record. 
				else{
					leadConv.setContactId(null);
					oneCont = mergeDWHContactNew(oneCont, oneProj);
					oneCont.RecordTypeId = contactRTManual;
					oneCont.AccountId = oneProj.EBH_Seller__c;
					
					mLeadCont.put(oneProj.Lead__c, oneCont);
				}
				lstLeadConv.add(leadConv);
			}
			if(!lstLeadConv.isEmpty()){
				List<Contact> lstCont = new List<Contact>();
				List<Database.LeadConvertResult> lstLCR = Database.convertLead(lstLeadConv, false);
				for(Database.LeadConvertResult lcr : lstLCR){
					if(lcr.isSuccess()){
						Id leadId = lcr.getLeadId();
						Id accId = lcr.getAccountId();
						Id contactId = lcr.getContactId();
						Contact oneCont = mLeadCont.get(leadId);
						if(String.isBlank(oneCont.Id)){
							oneCont.Id = contactId;
						}
						lstCont.add(oneCont);
					}
				}

				if(!lstCont.isEmpty()){
					update lstCont;
				}
				
				Set<String> sLeadId = mLead_Acc.keySet();
				List<Task> lstTask = Database.query(EBH_ConstantsUtility.SOQL_TASK + ' WHERE WhoId IN: sLeadId');

				// Automation should also move the Activities of record type "AU Task" 
				// If any exists in the Leads before conversion stage they need to associate with DWH Seller(Customer) record. 
				for(Task oneTask : lstTask){
					// related to
					oneTask.WhatId = mLead_Acc.get(oneTask.WhoId);
					// name
					oneTask.WhoId = null;
				}
				if(!lstTask.isEmpty()){
					update lstTask;
				}
			}

		}catch(Exception ex) {
			// ApexUtil.doSend('Debug Error', 'acmatac.seing@gaea-sys.com', 'Error: '+ex.getMessage()+'\nDetail: '+ex.getStackTraceString());
			// System.debug('Debug Error' + ex.getMessage()+'\nDetail: '+ex.getStackTraceString());
			EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchLeadConversion', 'execute');
		}
    }
	global void finish(Database.BatchableContext bc) {

    }

	// This mapping from Lead is using for existing Contact
	private static Contact mergeDWHContactMatch(Contact oneCont, EBH_Project__c oneProj){
		oneCont.EBH_SecondaryEmail__c = oneProj.Lead__r.Email;
		oneCont.MobilePhone = oneProj.Lead__r.MobilePhone;
		oneCont.PreferredContactTime__c = oneProj.Lead__r.EBH_PreferredContactTime__c;
		return oneCont;
	}

	// This mapping from Lead is using for new Contact
	private static Contact mergeDWHContactNew(Contact oneCont, EBH_Project__c oneProj){
		oneCont.FirstName = oneProj.Lead__r.FirstName;
		oneCont.LastName = oneProj.Lead__r.LastName;
		oneCont.Title = oneProj.Lead__r.Title;
		oneCont.Email = oneProj.Lead__r.Email;
		oneCont.Phone = oneProj.Lead__r.Phone;
		oneCont.MobilePhone = oneProj.Lead__r.MobilePhone;
		oneCont.PreferredContactTime__c = oneProj.Lead__r.EBH_PreferredContactTime__c;
		oneCont.EBH_MailingStreet__c = oneProj.Lead__r.Street;
		oneCont.EBH_MailingCity__c = oneProj.Lead__r.City;
		oneCont.EBH_MailingCountry__c = oneProj.Lead__r.Country;
		oneCont.EBH_MailingPostalCode__c = oneProj.Lead__r.PostalCode;
		oneCont.EBH_MailingState__c = oneProj.Lead__r.State;
		return oneCont;
	}
}