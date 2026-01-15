/*********************************************************************************************************************************
@ Class:          LeadTriggerHandler
@ Version:        1.0
@ Author:         Vadhanak.Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Handler Class for Lead Trigger
@                  [#EPH-5656] SF - GDPR - Data Deletion from Leads Object
@                  So in summary the unique identifer between Lead Object and contact record should be 
@
@				  Cases
@					CHECK IF eBay ID (from Lead Object) =  Business Name (from Contact Record) 
@					IF NOT THEN 
@					CHECK  Oracle ID (from Lead Object) = Oracle ID (from related seller) 
@					IF NOT THEN 
@					EMAIL (from Lead Object) = Primary Email (from Contact Record)
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.06.2018 / Vadhanak.Voun / Created the class.
                  24.03.2020 / Acmatac SEING / Created the moveTask_LeadProject Method.
                  14.01.2021/ Mony Nou / Modified leadOnboardingProcess Method
                  02.11.2022/ Sophal Noch/ US-0012821 Modified leadOnboardingProcess Method
                  10.01.2023/Sovantheany Dim / US-0013009 - eBay Academy Checkbox on Lead
                  20.03.2023/ Mony Nou / US-0013422 - Focus Initiate for Project
                  06.07.2023/ Sovantheany / US-0013498 - Collaboration Type for Leads
                  25.07,2023/ Sophal Noch / US-0013889 - Add Email History from Leads to Projects
                  26.09.2023/ Sovantheany Dim / US-0014100 - Pre-populate Recipient on email template sent from custom objects
                  01.07.2024 / sovantheany Dim / US-0015399 - Amendments for AU Kickstater (Durchstarter) Program
                  30.07.2024 / Sophal Noch / US-0015329 - Opportunity - Conversion
                  08.11.2024 / Bora Chhorn / US-0016108 - Remove ebay NA Acquisition record type from Profiles/permission sets
                  22.11.2024 / Sophal Noch / US-0015408 - Enable Qualified Lead With Event having multiple Attendee
                  05.12.2024 / Bora Chhorn / US-0015483 - Tech debt- Remove campaign__c custom field in Lead object
                  20.05.2025 / Bora Chhorn / US-0026065 - Cannot process lead as qualified when existing Legal Entity matches with Lead Company Name
                  30.10.2025 / vadhanak voun / US-0033819 - Leads that are currently part of a Cadence cannot be qualified due to a system error.
*********************************************************************************************************************************/
public without sharing class LeadTriggerHandler {
    public static final String ACCOUNT_SOQL = 'SELECT Id, Name, Website, EBH_VATNumber__c, EBH_OracleId__c FROM Account ';
    public static final String PROJECT_SOQL = 'SELECT Id, Lead__c FROM EBH_Project__c';
    public static final String SOQL_TASK = 'Select EBH_ResponseCode__c,Campaign_related_Seller_Details__c, OwnerId,Owner.Name,Survey_ID__c,IsClosed,Id,EBH_CampaignMemberId__c,WhatId,WhoId,Status,Order_Priority__c,EBH_Response__c,Call_attempts__c From Task ';
    public static final String SOQL_PROJECT = 'Select Lead__c, count(Id) projectCount from EBH_Project__c';
    public static final String SOQL_OPPORTUNITY = 'SELECT Id, RecordType.DeveloperName FROM Opportunity ';
    public static final String SOQL_LEAD = 'SELECT Id, ConvertedOpportunityId, ConvertedAccount.RecordType.DeveloperName, ConvertedOpportunity.RecordType.DeveloperName FROM Lead ';
    public static final String SOQL_CAMPAIGNMEMBER = 'select id, LeadId, CampaignId from CampaignMember';

    public static final String LEAD_STATUS_QLY = 'Qualified';
    public static final String LEAD_SITE_AU = 'AU';
    public static final String LEAD_SEGMENT_SMB = 'SMB';
    public static final String LEAD_SEGMENT_ENTERPRISE = 'Enterprise';
    public static final String ACCOUNT_LEGAL_ENTITY_RT_DEVNAME = 'EBH_LegalEntity';
    // public static final String OPPORTUNITY_NA_RT_DEVNAME = 'eBay_NA_Acquisition'; //BR-08.11.24-US-0016066
    public static final String LEAD_NA_RT_DEVNAME = 'eBay_NA_Acquisition';
    private static final String LEAD_SOURCE_SELF_GEN = 'Self Gen';
    private static final Set<String> setAUsmbLeadSource = new Set<String>{'Kickstarter - Acquisition','Kickstarter - Organic signup'};

    public static final Id RT_LEAD_EBDEV_ID =  ApexUtil.getRecordTypeByName('Lead', 'eBay_Business_Development')?.Id;
   
    /*****************************************************************************************************************************
    @ Method:         removeLeadGDPR
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        [#EPH-5656] SF - GDPR - Data Deletion from Leads Object
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Contacts:      Contacts sent from EBH_ContactTriggerHandler.removeGDPRContact()  
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.08.2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    public static void removeLeadGDPR(Set<String> setAccountIds,Set<String> setEmails)
    {
    	Set<String> setEbayIds = new Set<String>();
    	Set<String> setOracleIds = new Set<String>();
    	for(Account a: Database.query(EBH_ConstantsUtility.SOQL_ACCOUNT))
    	{
    		setEbayIds.add(a.Name);
    		if(a.EBH_OracleID__c<>null)setOracleIds.add(a.EBH_OracleID__c);
    	}
    	//system.debug('removeLeadGDPR>>>setAccountIds:'+setAccountIds+'>>>setEmails:'+setEmails+'>>>setEbayIds:'+setEbayIds+'>>>setOracleIds:'+setOracleIds);  
    	List<Lead> listLeads = Database.query(EBH_ConstantsUtility.SOQL_LEAD);
    	for(Lead l: listLeads)
    	{
    		doRemoveData(l);
    	}
    	if(!listLeads.isEmpty())
    	{
    		try
    		{
    			update listLeads;
    		} catch(Exception ex) {
                EBH_ApexLogger.logError(new List<Exception> { ex }, 'LeadTriggerHandler', 'removeLeadGDPR');
            } 
    	}
    }
	/*****************************************************************************************************************************
    @ Method:         changeConvertedContactRecordType
    @ Version:        1.0
    @ Author:         Acmatac SEING
    @ Purpose:        US-0018712	After convert Lead, Seller record doesn't populate values for some fields
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Contacts:      Contacts sent from EBH_ContactTriggerHandler.removeGDPRContact()  
	@ Event:	 	  before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 4.10.2019 / Acmatac SEING / Created the  Method.
                    : 30.07.2024 / Sophal Noch / US-0015329 - Opportunity - Conversion
    *****************************************************************************************************************************/
    public static void changeConvertedContactRecordType(List<Lead> lstNewLead){
		Set<Id> sContactId = new Set<Id>();
		for(Lead oLead : lstNewLead){
			if (oLead.IsConverted && oLead.RecordTypeId != RT_LEAD_EBDEV_ID){ //  30.07.2024 / Sophal Noch / US-0015329 : Exclude Lead with RecordType eBay_Business_Development
				sContactId.add(oLead.ConvertedContactId);  
			}
		}
		List<Contact> lstContact = new List<Contact>();
        Id contactRTManual= Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('EBH_MANUAL').getRecordTypeId();
		
        // for(Contact oCont : [SELECT Id FROM Contact WHERE Id IN: sContactId]){
        List<Contact> listContact = ApexSafe.query().secCheck(false).doQuery('SELECT Id FROM Contact WHERE Id IN: sContactId', new Map<String, Object> {'sContactId' => sContactId}); //  30.07.2024 / Sophal Noch / US-0015329 : replace Normal Query with ApexSafe Query
        for(Contact oCont : listContact){
			oCont.RecordTypeId = contactRTManual;
			lstContact.add(oCont);
		}
		if(!lstContact.isEmpty()){
			// update lstContact;
            ApexSafe.dml().secCheck(false).doUpdate(lstContact, true);  //  30.07.2024 / Sophal Noch / US-0015329 : replace normal DML with ApexSafe DML
		}
    }
    private static void doRemoveData(Lead l)
    {
    	l.Salutation = 'deleted';
    	l.FirstName = 'deleted';
    	l.LastName = 'deleted';
    	l.Suffix = 'deleted';
    	l.Title = 'deleted';
    	l.Email = 'deleted@deleted.com';
    	l.Phone = 'deleted';
    	l.MobilePhone = 'deleted';
    	l.EBH_PreferredContactTime__c = 'deleted';
    	l.Website = 'deleted';
    	l.GDPR_Removed__c = true;
    }
    /*****************************************************************************************************************************
    @ Method:         validateAUSMBLead
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0006886 [AU] Approval Process for eBay AU SMB Project with lead Source "Self Gen"
    @ Rule 2 ->When Lead: Record Type EQUALS eBay AU SMB AND Lead Source = "Self Gen" and isapproved = "False"
    @ When attempting to set the Lead Status to "Qualified" throw the below error.
    @ Should NOT allow the Self Gen Leads to be qualified until they are approved.
    @ "Please submit the Lead for Approval."
    @ Note - This is applicable only for SMB Leads and not for Enterprise Leads.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<Lead> lstNewLead
	@ Event:	 	  before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.12.2019 / Sovantheany Dim / Created the  Method.
    @ Change history: 25.03.2020 / Sovantheany Dim /Updated the methode : US-0007330 - [EU & AU] Approval Process.
        Rule 2 ->When Lead: record type "New Seller Registration Process" (previously EBH_eBayAUSMB record type) AND Lead Source = "Self Gen" and isapproved = "False" and LeadSegment__c = SMB (small medium business) and Site__c = AU
        When attempting to set the Lead Status to "Qualified" throw the below error.
        Should NOT allow the Self Gen Leads to be qualified until they are approved.
        "Please submit the Lead for Approval."
    *****************************************************************************************************************************/
    public static void validateAUSMBLead(List<Lead> lstNewLead){
    	RecordType recTypeAuSMBLead = ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUSMB');
		for(Lead newLead : lstNewLead){
			if (newLead.RecordTypeId == recTypeAuSMBLead.Id && newLead.LeadSource != null && newLead.LeadSource == LEAD_SOURCE_SELF_GEN && newLead.isapproved__c == false && newLead.Status == LEAD_STATUS_QLY && newLead.Site__c == LEAD_SITE_AU && newLead.LeadSegment__c == LEAD_SEGMENT_SMB){
				newLead.addError(System.label.eBayAuSBM_Err_2,false);
			}
		}
	}
	/*****************************************************************************************************************************
    @ Method:         leadOnboardingProcess
    @ Version:        1.0
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0007400 - [EU & AU] Create Legal Entity & Project & Contact
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Map<Id, Lead> mOldLead => Old Map Lead, 
                      Map<Id, Lead> mNewLead => New Map Lead
    @ Event:	 	  after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.04.2020 / Acmatac SEING / Created the  Method.
                    26.05.2020 / Acmatac SEING / US-0007584 [AU & EU] Existing Legal Entity for Lead
                                                Given that in the system there is already Legal Entity record where Lead.Company = Legal Entity. Business Name
                                                When I try to move this Lead to status "Qualified"
                                                Then I see the following error message: 
                    19.04.2020 / Sreymeas Nao / US-0007643 : [AU & EU] Only one project per Lead is possible
                    20.04.2020 / Acmatac SEING / US-0007645 [AU] Changes to AU Acquisition Process
                    08.07.2020 / Acmatac SEING / US-0007797 [EU & AU] Validation for Lead. Changes & unprioritized field
                    14.01.2021 / Mony Nou/ US-0008828 - [EU & AU] Create Legal Entity & Project & Contact. Adjustments 2
                    22.03.2022 / Acmatac SEING / US-0010974 - Users unable to qualify lead with existing related project.
                    02.11.2022/ Sophal Noch / US-0012821 - Non-selective query against large object type
                    10.01.2023/ Sovantheany Dim /US-0013009 - eBay Academy Checkbox on Lead
                    06.07.2023/ Sovantheany / US-0013498 - Collaboration Type for Leads
                    25.07.2023/ Sophal Noch / US-0013889 - Add Email History from Leads to Projects
                    26.09.2023/ Sovantheany Dim / US-0014100 - Pre-populate Recipient on email template sent from custom objects
                    09.07.2024/ sovantheany dim / US-0015399 - 
                        Given a lead with
                        record type = New Seller Registration
                        AND Country = AU has been created
                        AND lead source = Kickstarter - Acquisition OR Kickstarter - Organic signup
                        AND Lead segment = SMB
                        Then The project created is of record type = EU onboarding
                    22.11.2024 / Sophal Noch / US-0015408 - Enable Qualified Lead With Event having multiple Attendee
    *****************************************************************************************************************************/
    public static void leadOnboardingProcess(Map<Id, Lead> mOldLead, Map<Id, Lead> mNewLead){

        // 22.11.2024 / Sophal Noch / US-0015408 : change exist variable names to camel case to follow naming convention of PMD
        Id leadNSRPRtypeId = ApexUtil.getRecordTypeByName('Lead', 'EBH_eBayAUSMB').Id;
        Id accLegalEnttRTypeId =  ApexUtil.getRecordTypeByName('Account', 'EBH_LegalEntity').Id;

        Map<Id, Lead> mapLead = new Map<Id, Lead>();
        Set<Id> legalEnttIds = new Set<Id>();
        Set<String> leadCompanys = new Set<String>();
        Set<String> leadCompanyExistings = new Set<String>();
        Set<String> projWithLead = new Set<String>();
        Set<Id> leadId = new Set<Id>();
        for(Lead oldLead : mOldLead.values()){
            Lead newLead = mNewLead.get(oldLead.Id);
            if(newLead.RecordTypeId == leadNSRPRtypeId && newLead.Status == LEAD_STATUS_QLY
                && oldLead.Status != newLead.Status){
                //
                mapLead.put(newLead.Id, newLead);
                leadId.add(newLead.Id);
                // leadCompanys.add(newLead.Company);
                 // 02.11.2022/ Sophal Noch / US-0012821 : check not empty on company field
                if(String.isNotBlank(newLead.Company)) { leadCompanys.add(newLead.Company); }
                if(String.isNotBlank(newLead.LegalEntity__c)){
                    legalEnttIds.add(newLead.LegalEntity__c);
                }
            }
        }
        if(mapLead.keySet().isEmpty()) { return; }
        // ***** Project Creation *****
       
        // Map<Id, Account> mLegalEntt = new Map<Id, Account>((List<Account>) Database.query(ACCOUNT_SOQL + ' WHERE Id IN: legalEnttIds'));  25.11.2024 / Sophal Noch / US-0015408 : disable static query, use ApexSafe to query below instead
        Map<Id, Account> mLegalEntt = new Map<Id, Account>((List<Account>)ApexSafe.query().secCheck(false).doQuery(ACCOUNT_SOQL + ' WHERE Id IN: legalEnttIds', new Map<String, Object> {'legalEnttIds' => legalEnttIds})); // 22.11.2024 / Sophal Noch / US-0015408

        //Map<Id,EBH_Project__c> projWithLead = new Map<Id,EBH_Project__c>((List<EBH_Project__c>) Database.query(EBH_ConstantsUtility.BATCH_LEAD_SQL+ ' where Lead__c IN :leadId'));
        
        // for(Account oAcc : Database.query(ACCOUNT_SOQL + ' WHERE Name IN: leadCompanys ')){
        // 02.11.2022/ Sophal Noch / US-0012821 : add RecordTypeId condition to query LegalEntity Account Only

        // for(Account oAcc : [Select Name From Account Where Name IN: leadCompanys And RecordTypeId =: accLegalEnttRtype ]){  // 22.11.2024 / Sophal Noch / US-0015408 : disable static query, use ApexSafe query below instead 
        for(Account oAcc : (List<Account>)ApexSafe.query().secCheck(false).doQuery('Select Name From Account Where Name IN: leadCompanys And RecordTypeId =: accLegalEnttRTypeId', new Map<String, Object> {'leadCompanys' => leadCompanys, 'accLegalEnttRTypeId' => accLegalEnttRTypeId})){ // 22.11.2024 / Sophal Noch / US-0015408
            leadCompanyExistings.add(oAcc.Name);
        }

        // US-0010974 - Users unable to qualify lead with existing related project but with filtering recordtype.
        Set<String> projectFilterRT = new Set<String>{'eBayAUSMB', 'EUOnboarding'};
        
        // US-0007643 SRM: [AU & EU] Only one project per Lead is possible
        // for(AggregateResult proj : Database.query(SOQL_PROJECT+ ' WHERE Lead__c IN :leadId AND RecordType.DeveloperName IN:projectFilterRT GROUP BY Lead__c')){ 25.11.2024 / Sophal Noch / US-0015408 : disable static query, use ApexSafe to query below instead
        for(AggregateResult proj : (List<AggregateResult>)ApexSafe.query().secCheck(false).doQuery(SOQL_PROJECT+ ' WHERE Lead__c IN :leadId AND RecordType.DeveloperName IN:projectFilterRT GROUP BY Lead__c', new Map<String, Object> {'leadId' => leadId,'projectFilterRT' => projectFilterRT}) ){ // 25.11.2024 / Sophal Noch / US-0015408
            mapLead.remove(String.valueOf(proj.get('Lead__c')));
        }

        Map<String, EBH_Project__c> mLeadProj = createLegalEntityAndPopulateProj(mapLead, mLegalEntt, leadCompanyExistings); // 25.11.2024 / Sophal Noch / US-0015408 : move logic to a separate method

        // if(!mLeadProj.values().isEmpty()) insert mLeadProj.values(); // 22.11.2024 / Sophal Noch / US-0015408 : disable dml statement, use ApexSafe dml below instead
        // 22.11.2024 / Sophal Noch / US-0015408 :
        if(mLeadProj.isEmpty()) { return; } 
        ApexSafe.dml().secCheck(false).doInsert(mLeadProj.values(), true);

        moveLeadTaskEventToProj(mLeadProj); // 25.11.2024 / Sophal Noch / US-0015408 : move logic to a separate method

        updateLeadCampMembToProj(leadId); // 25.11.2024 / Sophal Noch / US-0015408 : move logic to a separate method
    }

    private static Map<String, EBH_Project__c> createLegalEntityAndPopulateProj(Map<Id, Lead> mapLead, Map<Id, Account> mLegalEntt, Set<String> leadCompanyExistings){
        // 25.11.2024 / Sophal Noch / US-0015408 : this method is created because we moved logic from leadOnboardingProcess method

        Id projEURtypeId = ApexUtil.getRecordTypeByName('EBH_Project__c', 'EUOnboarding').Id;
        Id projAUSMBRtypeId = ApexUtil.getRecordTypeByName('EBH_Project__c', 'eBayAUSMB').Id;

        List<Account> lstUpsertLegalEntt = new List<Account>();
        // Mapping Collect Legal Entity in one object with Project and Contact,
        // Purpose: To link Legal Entity to them later after inserted
        List<LegalEntityMappingWrapper> lstLegEnttMapping = new List<LegalEntityMappingWrapper>();
        
        // To Map between Lead and Project
        // Purpose: To move Task from Lead to Project later after Project inserted
        Map<String, EBH_Project__c> mLeadProj = new Map<String, EBH_Project__c>();
        for(Lead oLead : mapLead.values()){
            EBH_Project__c oProj = mappingLeadProject_Qualified(oLead);

            // If Site__c = AU then create project record of type “AU Onboarding”
            if(oLead.Site__c == LEAD_SITE_AU){    
                oProj.RecordTypeId = projAUSMBRtypeId;
                //TH:US-0015399:lead source = Kickstarter - Acquisition OR Kickstarter - Organic signup and Lead segment = SMB
                if(setAUsmbLeadSource.contains(oLead.LeadSource) && oLead.LeadSegment__c == LEAD_SEGMENT_SMB){
                    oProj.RecordTypeId = projEURtypeId;
                }
            }
            // If  Site__c DOES NOT EQUAL AU , then create project record of type “EU Onboarding”
            else{
                oProj.RecordTypeId = projEURtypeId;
                oProj.Priority__c = oLead.Priority__c; //AMT: 08/07/2020:US-0007797
            }
            oProj.Lead__c = oLead.Id;
            
            Account oAcc;
            Account seller;

            if(String.isNotBlank(oLead.eBayID__c)){
                seller = new Account(Id = oLead.eBayID__c);
            } 

            Boolean notUpsertLegalEntity = String.isBlank(oLead.LegalEntity__c) && String.isNotBlank(oLead.eBayID__c);
            
            if(!notUpsertLegalEntity){ // upsert legal entity when notUpsertLegalEntity = false
                oAcc = mapQualifiedLeadToLegalEntity(oLead, mLegalEntt);
                if( oAcc.Id != null){oProj.LegalEntity__c = oAcc.Id;}
                // @AMT, US-0007584 [AU & EU] Existing Legal Entity for Lead, If any LegalEntity Exist, throw error and skip the event
                if(oAcc.Id == null && leadCompanyExistings.contains(oLead.Company)){
                    oLead.addError(Label.LeadAccount_Duplicate_ErrorMsg);
                    continue;
                }
            }

            LegalEntityMappingWrapper legalEnttMapping = new LegalEntityMappingWrapper();

            Contact oCont = new Contact(
                FirstName = oLead.FirstName,
                MiddleName = oLead.MiddleName,
                LastName = oLead.LastName,
                Title = oLead.Title,
                Email = oLead.Email,
                Phone = oLead.Phone,
                MobilePhone = oLead.MobilePhone,
                RecordTypeId = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL').Id
            );

            if(!notUpsertLegalEntity){  // upsert legal entity when notUpsertLegalEntity = false
                // Legal Entity
                lstUpsertLegalEntt.add(oAcc);
            }

            // Project
            mLeadProj.put(oLead.Id, oProj);
            legalEnttMapping.legalEntt = oAcc != null ? oAcc : null;
            legalEnttMapping.seller = seller != null ? seller : null;
            legalEnttMapping.project = oProj;
            legalEnttMapping.contact = oCont;
            lstLegEnttMapping.add(legalEnttMapping);
        }

        // if(!lstUpsertLegalEntt.isEmpty()) upsert lstUpsertLegalEntt; //  22.11.2024 / Sophal Noch / US-0015408 : disable dml statement, use ApexSafe DML below instead
        //20.05.2025 / Bora Chhorn / US-0026065
        try{
            if(!lstUpsertLegalEntt.isEmpty()) { ApexSafe.dml().secCheck(false).doUpsert(lstUpsertLegalEntt, Account.Id, true); } // 22.11.2024 / Sophal Noch / US-0015408
        } catch(DmlException dmlEx){
            System.debug(dmlEx);
            String errMsg = Label.Lead_Error_Message_Duplication_Rule;
            for(Lead dupLead : mapLead.values()){
                errMsg = errMsg.replace('{company_name}', dupLead.Company);
                if(dmlEx.getDMLType(0) == StatusCode.DUPLICATES_DETECTED){
                    dupLead.addError(errMsg);
                } else {
                    dupLead.addError(dmlEx.getDMLMessage(0));
                }
            }
        }
        createContactFromEntityWrapper(mLeadProj, lstLegEnttMapping);

        return mLeadProj;
    }

    private static Account mapQualifiedLeadToLegalEntity(Lead oLead,  Map<Id, Account> mLegalEntt){
        // 25.11.2024 / Sophal Noch / US-0015408 : this method is created because we moved logic from leadOnboardingProcess method

        // ***** Legal Entity Creation *****
        Id accLegalEnttRTypeId =  ApexUtil.getRecordTypeByName('Account', 'EBH_LegalEntity').Id;
        Account oAcc = new Account(RecordTypeId=accLegalEnttRTypeId);
        // If Lead.Legal Entity is not empty, then relate this Legal Entity to the newly created project
        // And prepopulate : Website, EBH_VATNumber__c
        if(String.isNotBlank(oLead.LegalEntity__c) && mLegalEntt.containsKey(oLead.LegalEntity__c)) {
            oAcc = mLegalEntt.get(oLead.LegalEntity__c);
            oAcc.Website = String.isBlank(oAcc.Website) ? oLead.Website : oAcc.Website;
            oAcc.EBH_VATNumber__c = String.isBlank(oAcc.EBH_VATNumber__c) ? oLead.VAT_Number__c : oAcc.EBH_VATNumber__c;
        }
        // Lead.Legal Entity is empty, then create a new Legal Entity and relate it to a project
        else{
            oAcc.Name = oLead.Company;
            oAcc.OwnerId = UserInfo.getUserId();
            oAcc.EBH_BillingStreet__c = oLead.Street;
            oAcc.EBH_BillingCity__c = oLead.City;
            oAcc.EBH_BillingCountry__c = oLead.Country;
            oAcc.EBH_BillingPostalCode__c = oLead.PostalCode;
            oAcc.Website = oLead.Website;
            oAcc.EBH_VATNumber__c = oLead.VAT_Number__c;
        }
        return oAcc;
    }

    private static void createContactFromEntityWrapper(Map<String, EBH_Project__c> mLeadProj, List<LegalEntityMappingWrapper> lstLegEnttMapping){
        // 25.11.2024 / Sophal Noch / US-0015408 : this method is created because we moved logic from leadOnboardingProcess method

        List<Contact> lstCont = new List<Contact>();
        for(LegalEntityMappingWrapper oLEMW: lstLegEnttMapping){
            // If Lead. Legal Entity is Empty we need to create new and Link to th new Project
            if(mLeadProj.containsKey(oLEMW.project.Lead__c) && String.isBlank(oLEMW.project.LegalEntity__c) && oLEMW.legalEntt != null) {
                mLeadProj.get(oLEMW.project.Lead__c).LegalEntity__c = oLEMW.legalEntt.Id;
            }

            if(oLEMW.seller != null){
                 oLEMW.contact.AccountId = oLEMW.seller.Id;
            }else{
                oLEMW.contact.AccountId = oLEMW.legalEntt.Id;
            }
            
            lstCont.add(oLEMW.contact);
        }

        // if(!lstCont.isEmpty()) insert lstCont; // 22.11.2024 / Sophal Noch / US-0015408 : disable dml statement, use ApexSafe dml below instead
        if(!lstCont.isEmpty()) { ApexSafe.dml().secCheck(false).doInsert(lstCont, true); } // 22.11.2024 / Sophal Noch / US-0015408

        //TH:US-0014100:Link contact in lookup field on the project record to Pre-populate Recipient on email
        for(LegalEntityMappingWrapper oLEMW: lstLegEnttMapping){
            if(mLeadProj.containsKey(oLEMW.project.Lead__c) && String.isBlank(oLEMW.project.EBH_Contact__c)) {
                mLeadProj.get(oLEMW.project.Lead__c).EBH_Contact__c = oLEMW.contact.Id;
            }
        }
    }

    private static void moveLeadTaskEventToProj(Map<String, EBH_Project__c> mLeadProj){
        // 25.11.2024 / Sophal Noch / US-0015408 : this method is created because we moved logic from leadOnboardingProcess method

        // ***** Move Task from Lead to Project *****
        List<Task> lstTask = new List<Task>();
        Set<String> leadIds = mLeadProj.keySet();
        String subtypeCadence = 'Cadence';   //to be excluded   NK:30.10.2025:US-0033819
        // for(Task oneTask : Database.query(SOQL_TASK + ' WHERE WhoId IN: leadIds')){ // 22.11.2024 / Sophal Noch / US-0015408 : disable static query, use ApexSafe to query below instead
        for(Task oneTask : (List<Task>)ApexSafe.query().secCheck(false).doQuery(SOQL_TASK + ' WHERE TaskSubtype <> :subtypeCadence AND WhoId IN: leadIds', new Map<String, Object> {'subtypeCadence' => subtypeCadence,'leadIds' => leadIds})){ //  22.11.2024 / Sophal Noch / US-0015408, NK:30.10.2025:US-0033819
            if(mLeadProj.containsKey(oneTask.WhoId)){
                oneTask.WhatId = mLeadProj.get(oneTask.WhoId).Id;
                oneTask.WhoId = null;
                lstTask.add(oneTask);
            }
        }

        // if(!lstTask.isEmpty()) update lstTask; // 22.11.2024 / Sophal Noch / US-0015408 : disable dml statement, use ApexSafe dml below instead
        if(!lstTask.isEmpty()) { ApexSafe.dml().secCheck(false).doUpdate(lstTask, true); }// 22.11.2024 / Sophal Noch / US-0015408

        // 25.07,2023 / Sophal Noch / US-0013889 : Move Event to EBH_Project__c When Lead is Qualified
        List<Event> lstEvtToUpdate = new List<Event>();
        // for(Event evt : [Select Id, WhatId, WhoId From Event Where WhoId IN: leadIds]){  // 22.11.2024 / Sophal Noch / US-0015408 : disable static query, use ApexSafe to query below instead
        for(Event evt : (List<Event>)ApexSafe.query().secCheck(false).doQuery('Select Id, WhatId, WhoId From Event Where IsChild = false And WhoId IN: leadIds', new Map<String, Object> {'leadIds' => leadIds})){ //  22.11.2024 / Sophal Noch / US-0015408 : add IsChild = false into query
            if(mLeadProj.containsKey(evt.WhoId)){
                evt.WhatId = mLeadProj.get(evt.WhoId).Id;
                evt.WhoId = null;
                lstEvtToUpdate.add(evt);
            }
        }

        // if(!lstEvtToUpdate.isEmpty()) update lstEvtToUpdate; // 22.11.2024 / Sophal Noch / US-0015408 : disable dml statement, use ApexSafe dml below instead
        if(!lstEvtToUpdate.isEmpty()) { ApexSafe.dml().secCheck(false).doUpdate(lstEvtToUpdate, true); }// 22.11.2024 / Sophal Noch / US-0015408
    }

    private static void updateLeadCampMembToProj(Set<Id> leadId){
        // 25.11.2024 / Sophal Noch / US-0015408 : // 25.11.2024 / Sophal Noch / US-0015408 : this method is created because we moved logic from leadOnboardingProcess method

        // US-0008828 - [EU & AU] Create Legal Entity & Project & Contact. Adjustments 2
        Map<Id, Id> mLeadLastestCampaignId = new Map<Id,Id>(); //Key: LeadId => Value: CampaignId from the lastest CampaignMember that the lead associate to
        // Finding the latest CampaignMember of each Lead
        // for (CampaignMember cm : Database.query(SOQL_CAMPAIGNMEMBER + ' WHERE LeadId IN:leadId ORDER BY LastModifiedDate DESC')) { 25.11.2024 / Sophal Noch / US-0015408 : disable static query, use ApexSafe to query below instead
        for (CampaignMember cm : (List<CampaignMember>)ApexSafe.query().secCheck(false).doQuery(SOQL_CAMPAIGNMEMBER + ' WHERE LeadId IN:leadId ORDER BY LastModifiedDate DESC', new Map<String, Object> {'leadId' => leadId})) { // 25.11.2024 / Sophal Noch / US-0015408 
            if (!mLeadLastestCampaignId.containsKey(cm.LeadId)) { mLeadLastestCampaignId.put(cm.LeadId, cm.CampaignId); }
        }
        // Populate the above latest CampaignId to the Project that link to each Lead
        List<EBH_Project__c> lstProj = new List<EBH_Project__c>();
        // for (EBH_Project__c proj : Database.query(PROJECT_SOQL + ' WHERE Lead__c IN:leadId')) { 25.11.2024 / Sophal Noch / US-0015408 : disable static query, use ApexSafe to query below instead
        for (EBH_Project__c proj : (List<EBH_Project__c>)ApexSafe.query().secCheck(false).doQuery(PROJECT_SOQL + ' WHERE Lead__c IN:leadId', new Map<String, Object> {'leadId' => leadId})) { // 25.11.2024 / Sophal Noch / US-0015408
            if (mLeadLastestCampaignId.containsKey(proj.Lead__c)) { lstProj.add(new EBH_Project__c(Id=proj.Id, Campaign__c=mLeadLastestCampaignId.get(proj.Lead__c))); }
        }

        // if (!lstProj.isEmpty()) update lstProj; // 22.11.2024 / Sophal Noch / US-0015408 : disable dml statement, use ApexSafe dml below instead
        if (!lstProj.isEmpty()) { ApexSafe.dml().secCheck(false).doUpdate(lstProj, true); } // 22.11.2024 / Sophal Noch / US-0015408
    }

    /*****************************************************************************************************************************
    @ Method:         leadConversionNA_Validation
    @ Version:        1.0
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0008556 - [NA] Lead Conversion to Opportunity
                        Checks whether the Account Record Type of the Lead.convertedAccountId is a Legal Entity. If not, show the error message
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      mNewLead
    @ Event:	 	  after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.11.2020 / Acmatac SEING / Created the  Method.
    *****************************************************************************************************************************/
    public static void leadConversionNA_Validation(Map<Id, Lead> mNewLead){
        Id leadNA_RT_Id =  ApexUtil.getRecordTypeByName('Lead', LEAD_NA_RT_DEVNAME).Id;
        Set<Id> leadIds = new Set<Id>();
        for(Lead newLead : mNewLead.values()){
            if(newLead.IsConverted && newLead.RecordTypeId == leadNA_RT_Id && String.isNotBlank(newLead.ConvertedAccountId)){
                leadIds.add(newLead.Id);
            }
        }
        if(!leadIds.isEmpty()){
            String whereSOQL = ' WHERE Id IN: leadIds';
            for(Lead oLead : Database.query(SOQL_LEAD + whereSOQL)){
                if(oLead.ConvertedAccount.RecordType.DeveloperName != ACCOUNT_LEGAL_ENTITY_RT_DEVNAME){
                    mNewLead.get(oLead.Id).addError(Label.LEAD_CONVERSION_NA_VALIDATION_ERROR_ACC_MSG);
                }
            }
        }
	}
    
    /******************************************  PRIVATE METHOD  ***********************************************************/

    private static EBH_Project__c mappingLeadProject_Qualified(Lead oLead){
        return new EBH_Project__c(
            OwnerId = oLead.OwnerId,
            Name = ('Onboarding '+ oLead.Site__c + ' ' + oLead.Company).left(80),
            OracleID__c = oLead.EBH_OracleID__c,
            Vertical__c = oLead.EBH_Vertical__c,
            LeadSegment__c = oLead.LeadSegment__c,
            LeadSource__c = oLead.LeadSource,
            OtherLeadSource__c = oLead.OtherLeadSource__c,
            // Campaign__c = oLead.Campaign__c, //BR-05/12/2024-US-0015483
            ABNVATNumber__c = oLead.VAT_Number__c,
            Website__c = oLead.Website,
            OtherMarketPlaces__c = oLead.EBH_OtherMarketplaces__c,
            OnlineRank__c = oLead.OnlineRank__c,
            Comments__c = oLead.EBH_CommentsBusinessReview__c,
            Shopping_Card__c = oLead.Shopping_Card__c,
            ShippingTechnology__c = oLead.ShippingTechnology__c,
            Theoretical_Revenue__c = oLead.TheoreticalRevenue__c,
            CurrencyIsoCode = oLead.CurrencyIsoCode,
            Integration_partner__c = oLead.Integration_partner__c,
            Site__c = oLead.Site__c,
            Points__c = oLead.Points__c,
            Main_Meta_Category__c= oLead.Main_Meta_Category__c,//TH: 19/06/2020:US-0007644 - [AU & EU] Meta Category
            Collaboration_Type__c = oLead.Collaboration_Type__c,//TH: US-0013498 - map value from lead when Lead "Qualified"
            eBay_Academy__c = oLead.eBay_Academy__c,//TH: 10/01/2023:US-0013009 - eBay Academy Checkbox on Lead
            Focus_Initiative__c = oLead.Focus_Initiative__c //MN-20032023-US-0013422
        );
    }
    private class LegalEntityMappingWrapper{
        Account legalEntt;
        Account seller;
        EBH_Project__c project;
        Contact contact;
        public LegalEntityMappingWrapper(){
            this.legalEntt = new Account();
            this.seller = new Account();
            this.project = new EBH_Project__c();
            this.contact = new Contact();
        }
    }

    /*********************************************************************************************************************************
    @ method:          processBDLeadConversion
    @ Version:         1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / create the method
    *********************************************************************************************************************************/
    public static void processBDLeadConversion(Map<Id, Lead> mapOldLead, List<Lead> listNewLead){
        LeadConversionHelper.processBDLeadConversion(mapOldLead, listNewLead, false);
    }
}