/*********************************************************************************************************************************
@ Class:          LeadConversionHelper
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        US-0015329 - Opportunity - Conversion
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  30.07.2024 / Sophal Noch / Created the class.
                   08.01.2025 / Davy Sorn / US-0016404 - Validation in the "Convert Lead"
                   07.01.2025 / Sothea Horn / US-0016405 - Opportunity Acc Id to be populated with Seller
                   28.01.2025 / Acmatac Seing / US-0016686 - Newly converted BD Leads are not populating the Legal Entity after conversion.
*********************************************************************************************************************************/
public inherited sharing class LeadConversionHelper {

    private final static String SOQL_LEAD_OPP = 'SELECT Id, RecordTypeId, AccountId, Seller__c FROM Opportunity WHERE Id IN :setLeadOppId';
    private final static String SOQL_LEAD_ACCOUNT = 'SELECT Id, Name, RecordTypeId, CreatedDate, LastModifiedDate, ParentId FROM Account WHERE Id IN :setLeadAccountId';
    private final static String SOQL_LEAD_CONTACT = 'SELECT Id, Name, AccountId, RecordTypeId, CreatedDate, LastModifiedDate FROM Contact WHERE Id IN :setLeadContactId';
    private final static String SOQL_SELLER = 'SELECT Id, Name, ParentId, Parent.Name FROM Account WHERE Id IN :setSellerId';

    private final static String SOBJ_LEAD_APINAME = 'Lead';
    private final static String SOBJ_OPP_APINAME = 'Opportunity';
    private final static String SOBJ_ACC_APINAME = 'Account';
    private final static String SOBJ_CONTACT_APINAME = 'Contact';

    private final static String LEAD_RTYPE_NAME_BD = 'eBay_Business_Development';
    private final static String OPP_RTYPE_NAME_BD = LEAD_RTYPE_NAME_BD;
    private final static String ACC_RTYPE_NAME_LEGAL_ENTITY = 'EBH_LegalEntity';
    private final static String CONT_RTYPE_NAME_MANUAL = 'EBH_MANUAL';

    private final static String OPP_STAGE_NAME_DISCOVERY = 'Discovery';

    private final static Date CURRENT_DATE = Date.today();

    private Boolean isSecCheck = true;

    private Map<Id, Lead> mapConvertedLead = new  Map<Id, Lead>();
    private Map<Id, Lead> mapOldConvertedLead = new  Map<Id, Lead>();
    private Set<Id> setLeadOppId = new Set<Id>();
    private Set<Id> setSellerId = new Set<Id>();
    private Set<Id> setLeadAccountId =  new Set<Id>();
    private Set<Id> setLeadContactId = new Set<Id>();

    private Map<Id, Opportunity> mapLeadOpp = new Map<Id, Opportunity>();
    private Map<Id, Account> mapSeller = new Map<Id, Account>();
    private Map<Id, Account> mapLeadAccount = new Map<Id, Account>();
    private Map<Id, Contact> mapLeadContact = new Map<Id, Contact>();

    private Map<String, List<Lead_Conversion_Mapping__mdt>> mapLeadRTypeTargetObjToListMapping = new Map<String, List<Lead_Conversion_Mapping__mdt>>();

    /*********************************************************************************************************************************
    @ Method:         processBDLeadConversion
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public static void processBDLeadConversion(Map<Id, Lead> mapOldLead,  List<Lead> listLead, Boolean secCheck){

        LeadConversionHelper helper = new LeadConversionHelper();
        helper.setSecCheck(secCheck).filterConvertedBDLead(mapOldLead, listLead);
        if(helper.mapConvertedLead.isEmpty()){
           return;
        }
        helper
        .retrieveMapLeadOpp() // Query Opportunity related leadConverted
        .retrieveMapLeadAccount() // Query Account related leadConverted
        .retreveMapLeadContact() // Query Contact related leadConverted
        .retrieveMapSeller()  // Query Account From Lead.eBayID__c
        .validateBDLeadConversion() // Validate before Let eBay_Business_Development Lead Conversion Success
        .retrieveLeadConversionMapping() // Retrieve Custom Metadata for Custom mapping between Lead and Opportunity, Account, Contact Fields
        .mapBDLeadFiedlToOppAccContField(); // Custom Mapping Lead Fields to Opportunity, Account, Contact Fields

    }

    /*********************************************************************************************************************************
    @ Method:         filterConvertedBDLead
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    private LeadConversionHelper filterConvertedBDLead(Map<Id, Lead> mapOldLead, List<Lead> listLead){

        // filter Lead that is converted with RecordType is eBay_Business_Development and has ConvertedOpportunityId

        Id rtLeadBDId =  ApexUtil.getRecordTypeByName(SOBJ_LEAD_APINAME, LEAD_RTYPE_NAME_BD)?.Id;

        mapConvertedLead = new Map<Id, Lead>();
        mapOldConvertedLead = new Map<Id, Lead>();
        setSellerId = new Set<Id>();
        setLeadAccountId = new Set<Id>();
        setLeadContactId = new Set<Id>();
        for(Lead lead : listLead){
            Lead oldLead = mapOldLead?.get(lead.Id);
            if(lead.RecordTypeId == rtLeadBDId  && lead.IsConverted && lead.IsConverted != oldLead?.IsConverted){
                mapConvertedLead.put(lead.Id, lead);
                mapOldConvertedLead.put(lead.Id, oldLead);
                setLeadAccountId.add(lead.ConvertedAccountId);
                setLeadContactId.add(lead.ConvertedContactId);
                if(String.isNotBlank(lead.ConvertedOpportunityId)){
                    setLeadOppId.add(lead.ConvertedOpportunityId);
                }
                if(lead.eBayID__c != null){
                    setSellerId.add(lead.eBayID__c);
                }
                if(lead.LegalEntity__c != null){
                    setSellerId.add(lead.LegalEntity__c);
                }
               
            }
        }

        return this;
    }

    private LeadConversionHelper setSecCheck(Boolean secCheck){
        this.isSecCheck = secCheck;
        return this;
    }

    private LeadConversionHelper retrieveMapLeadOpp(){
        mapLeadOpp = new Map<Id, Opportunity>();
        List<Opportunity> listOpp = ApexSafe.query().secCheck(isSecCheck).doQuery(SOQL_LEAD_OPP, new Map<String, Object> {'setLeadOppId' => setLeadOppId});
        for(Opportunity opp : listOpp){
            mapLeadOpp.put(opp.Id, opp);
        }
        return this;
    }

    private LeadConversionHelper retrieveMapLeadAccount(){
        mapLeadAccount = new Map<Id, Account>();
        List<Account> listAccount = ApexSafe.query().secCheck(isSecCheck).doQuery(SOQL_LEAD_ACCOUNT, new Map<String, Object> {'setLeadAccountId' => setLeadAccountId});
        for(Account acc : listAccount){
            mapLeadAccount.put(acc.Id, acc);
        }
        return this;
    }

    private LeadConversionHelper retreveMapLeadContact(){
        mapLeadContact = new Map<Id, Contact>();
        List<Contact> listContact = ApexSafe.query().secCheck(isSecCheck).doQuery(SOQL_LEAD_CONTACT, new Map<String, Object> {'setLeadContactId' => setLeadContactId});
        for(Contact cont : listContact){
            mapLeadContact.put(cont.Id, cont);
        }
        return this;
    }

    private LeadConversionHelper retrieveMapSeller(){
        mapSeller = new Map<Id, Account>();
        if(!setSellerId.isEmpty()){
            List<Account> listAccount = ApexSafe.query().secCheck(isSecCheck).doQuery(SOQL_SELLER, new Map<String, Object> {'setSellerId' => setSellerId});
            for(Account acc : listAccount){
                mapSeller.put(acc.Id, acc);
            }
        }
        return this;
    }

    /*********************************************************************************************************************************
    @ Method:         validateBDLeadConversion
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / Created the method.
                       08.01.2025 / Davy Sorn /  US-0016404 - Validation in the "Convert Lead"
                       28.01.2025 / Acmatac Seing / US-0016686 - Newly converted BD Leads are not populating the Legal Entity after conversion.
    *********************************************************************************************************************************/
    private LeadConversionHelper validateBDLeadConversion(){

        Id rtOppBDId =  ApexUtil.getRecordTypeByName(SOBJ_OPP_APINAME, OPP_RTYPE_NAME_BD)?.Id;
        Id rtAcctLegalEntityId =  ApexUtil.getRecordTypeByName(SOBJ_ACC_APINAME, ACC_RTYPE_NAME_LEGAL_ENTITY)?.Id;
        Id rtContManualId =  ApexUtil.getRecordTypeByName(SOBJ_CONTACT_APINAME, CONT_RTYPE_NAME_MANUAL)?.Id;

        for(Lead lead : mapConvertedLead.values()){

            Lead oldLead = mapOldConvertedLead.get(lead.Id);
            Opportunity leadOpp = mapLeadOpp.get(lead.ConvertedOpportunityId);
            Account seller = mapSeller.get(lead.eBayID__c);
            Account leadLegalEnt = mapSeller.get(lead.LegalEntity__c);
            Account leadAcc = mapLeadAccount.get(lead.ConvertedAccountId);
            Contact leadCont = mapLeadContact.get(lead.ConvertedContactId);
            String linkedLegalEntity = lead.LegalEntity__c;
            String linkedSeller = lead.eBayId__c;

            if(String.isNotBlank(lead.ConvertedOpportunityId) && leadOpp?.RecordTypeId != rtOppBDId){ // Validate Opportunity Record type Not eBay_Business_Development
                lead.addError(Label.Error_BD_Opp_Conversion_Invalid_Rtype);
            }
            // Scenario Lead.Seller Is Not Blank. Note: Seller field is preffered over Legal Entity
            if(String.isNotBlank(lead.eBayID__c)){
                if(seller?.ParentId != null){ // Validate Lead.eBayId__c is not blank and it has ParentAccount Legal Entity
                    if(lead.ConvertedAccountId != seller?.ParentId && lead.ConvertedAccountId != lead.eBayId__c){
                        lead.addError(Label.Error_BD_Lead_Conversion_Lead_Is_Linked_to_Seller.replace('{0}', seller.Name));
                    }
                }else if(lead.ConvertedAccountId != lead.eBayId__c){
                    lead.addError(Label.Error_BD_Lead_Conversion_Lead_Is_Linked_to_Seller.replace('{0}', seller.Name));
                }
            }
            // Scenario Lead.Seller Is Blank
            else if(String.isBlank(lead.eBayID__c)){
                if(String.isNotBlank(linkedLegalEntity) && lead.LegalEntity__c != lead.ConvertedAccountId){
                    lead.addError(Label.Error_BD_Choose_Existing_Customer.replace('{0}', leadLegalEnt.Name));
                }
            }
            
            if(leadCont != null && isContactCreatedFromLead(lead, oldLead, leadCont) && leadCont?.RecordTypeId != rtContManualId){ // Validate New Contact RecordType Not Manual
                lead.addError(Label.Error_BD_Contact_Conversion_Invalid_Rtype);
            }

            if(leadCont?.AccountId != leadAcc?.Id){ // validate Selected Contact is not related to New Account or Exist Account
                lead.addError(Label.Error_BD_Opp_Conversion_Contact_Not_Related_To_Account);
            }

        }

        return this;
    }

    /*********************************************************************************************************************************
    @ Method:         isAccountCreatedFromLead
    @ Version:        1.0
    @ Author:         Davy Sorn
    @ Purpose:        US-0016404 - Validation in the "Convert Lead"
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  08.01.2025 / Davy Sorn / Created the method.
    *********************************************************************************************************************************/
    private Boolean isAccountCreatedFromLead(Lead lead, Lead oldLead, Account acc){
        Boolean isNewAccount = false;
        if(oldLead != null && oldLead.LastModifiedDate <= acc.CreatedDate && lead.LastModifiedDate>=acc.CreatedDate && isNewRecord(acc.LastModifiedDate, acc.CreatedDate)){
            isNewAccount = true;
        }
        return isNewAccount;
    }

    /*********************************************************************************************************************************
    @ Method:         isContactCreatedFromLead
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    private Boolean isContactCreatedFromLead(Lead lead, Lead oldLead, Contact cont){
        // check is Contact is created from Lead Conversion or Is Exist Contact by compare Contact.CreatedDate and Lead.LastModifiedDate
        Boolean isNewContact = false;
        if(oldLead != null && oldLead.LastModifiedDate <= cont.CreatedDate && lead.LastModifiedDate>=cont.CreatedDate && isNewRecord(cont.LastModifiedDate, cont.CreatedDate)){
            isNewContact = true;
        }
        return isNewContact;
    }

    private Boolean isNewRecord(Datetime lastModifiedDate, Datetime createdDate){
        Long lastModifiedMil = lastModifiedDate.getTime() ;
        Long createdDateMil = createdDate.getTime();
        Long  durationMil = lastModifiedMil - createdDateMil;
        Long durationSec = durationMil / 1000;
        return durationSec <= 3 ? true : false;
    }

    /*********************************************************************************************************************************
    @ Method:         retrieveLeadConversionMapping
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    private LeadConversionHelper retrieveLeadConversionMapping(){
        // get fields mapping between Lead and Opportunity, Account, Contact field from Custom Metadata
        mapLeadRTypeTargetObjToListMapping = new Map<String, List<Lead_Conversion_Mapping__mdt>>();
        for(Lead_Conversion_Mapping__mdt mapping : Lead_Conversion_Mapping__mdt.getAll().values()){
            if(mapping.Is_Active__c){
                List<Lead_Conversion_Mapping__mdt> listMapping = mapLeadRTypeTargetObjToListMapping.get(mapping.Lead_RecordType__c + mapping.Target_SObject_Name__c);
                if(listMapping == null){
                    listMapping = new List<Lead_Conversion_Mapping__mdt>();
                    mapLeadRTypeTargetObjToListMapping.put(mapping.Lead_RecordType__c + mapping.Target_SObject_Name__c, listMapping);
                }
                listMapping.add(mapping);
            }
        }
        return this;
    }

    /*********************************************************************************************************************************
    @ Method:         mapBDLeadFiedlToOppAccContField
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    private LeadConversionHelper mapBDLeadFiedlToOppAccContField(){
        // do mapping process with custom mapping BD Lead fields to  Opportunity, Account, Contact Fields
        List<Opportunity> listOppToUpdate = new List<Opportunity>();
        Map<Id, Account> mapAccToUpdate = new Map<Id, Account>();
        List<Contact> listContToUpdate = new List<Contact>();
        for(Lead lead : mapConvertedLead.values()){
            if(lead.hasErrors()){
                continue;
            }
            mapBDLeadFieldToOppField(listOppToUpdate, lead);
            mapBDLeadFieldToAccField(mapAccToUpdate, lead);
            mapLeadFieldToContField(listContToUpdate, lead);
        }
        ApexSafe.dml().secCheck(isSecCheck).doUpdate(listOppToUpdate, true);
        ApexSafe.dml().secCheck(isSecCheck).doUpdate(mapAccToUpdate.values(), true);
        ApexSafe.dml().secCheck(isSecCheck).doUpdate(listContToUpdate, true);
        return this;
    }

    /*********************************************************************************************************************************
    @ Method:         mapBDLeadFieldToOppField
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / Created the method.
    @               :  07.01.2025 / Sothea Horn / US-0016405 - Opportunity Acc Id to be populated with Seller
    @                  28.01.2025 / Acmatac Seing / US-0016686 - Newly converted BD Leads are not populating the Legal Entity after conversion.
    *********************************************************************************************************************************/
    private void mapBDLeadFieldToOppField(List<Opportunity> listOppToUpate, Lead lead){

        // map BD Lead fields to Opportunity fields by custom code and custom mapping fields
        Id rtOppBDId =  ApexUtil.getRecordTypeByName(SOBJ_OPP_APINAME, OPP_RTYPE_NAME_BD)?.Id;
        Opportunity opp = mapLeadOpp.get(lead.ConvertedOpportunityId);
        if(opp == null){
            return;
        }
        Account acc = mapLeadAccount.get(lead.ConvertedAccountId);
        
        // When user choose existing customer as Legal Entity
        if(acc.RecordTypeId == ApexUtil.getRecordTypeByName(SOBJ_ACC_APINAME, ACC_RTYPE_NAME_LEGAL_ENTITY)?.Id){
            opp.LegalEntity__c = acc?.Id;
        }
        // When user choose existing customer as Seller
        else if(String.isNotBlank(acc?.ParentId)){
            opp.LegalEntity__c = acc?.ParentId;
        }
        opp.StageName = OPP_STAGE_NAME_DISCOVERY; // set stage to Discovery
        opp.OwnerId = lead.OwnerId;
        opp.CloseDate = CURRENT_DATE.addDays(30);
        mapLeadFieldToSObjField(lead, opp, SOBJ_OPP_APINAME);
        // 07.01.2025 / Sothea Horn / (US-0016405) BD Opportunity.AccountId to be auto-populated with Linked Seller Id
        if (opp.RecordTypeId == rtOppBDId && opp.Seller__c != null) {
            opp.AccountId = opp.Seller__c;
        }
        listOppToUpate.add(opp);
    }

    /*********************************************************************************************************************************
    @ Method:         mapBDLeadFieldToAccField
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / Created the method.
                    : 29.01.2025 / Acmatac Seing / US-0016686 - Remove the code to update the Account.ParentId with the Seller
    *********************************************************************************************************************************/
    private void mapBDLeadFieldToAccField(Map<Id, Account> mapAccToUpdate, Lead lead){

        // map BD Lead fields to Account fields by custom code and custom mapping fields

        Account acc = mapLeadAccount.get(lead.ConvertedAccountId);
        if(acc == null){
            return;
        }
        Account seller = mapSeller.get(lead.eBayID__c);

        // 29.01.2025 / Acmatac Seing / US-0016686
        // if(seller != null && seller?.ParentId == null && !mapAccToUpdate.containsKey(seller.Id)){ // update Lead.eBayID__r.ParentId with LegalEntityId from LeadConversion If It is Blank
        //     seller.ParentId =  acc?.Id;
        //     mapAccToUpdate.put(seller.Id, seller);
        // }

        acc.OwnerId = ApexUtil.getCurrentUser()?.Id;
        mapLeadFieldToSObjField(lead, acc, SOBJ_ACC_APINAME);
        mapAccToUpdate.put(acc.Id, acc);
    }

    /*********************************************************************************************************************************
    @ Method:         mapLeadFieldToContField
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    private void mapLeadFieldToContField(List<Contact> listContToUpdate, Lead lead){

        // map Lead fields to Contact fields by custom mapping fields

        Contact cont = mapLeadContact.get(lead.ConvertedContactId);
        if(cont == null){
            return;
        }
        mapLeadFieldToSObjField(lead, cont, SOBJ_CONTACT_APINAME);
        Contact contToUpdate = cont.clone(false, false, false, false); // Contact contain fields CreatedDate from Query, Clone it here to prevent from DML error when update it
        contToUpdate.Id = cont.Id;
        listContToUpdate.add(contToUpdate);
    }

    /*********************************************************************************************************************************
    @ Method:         mapLeadFieldToSObjField
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0015329 - Opportunity - Conversion
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.07.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    private void mapLeadFieldToSObjField(Lead lead, SObject sobj, String sobjName){
        // use mapping from Custom Metadata to map Lead fields to Opportunity, Account, Lead
        List<Lead_Conversion_Mapping__mdt> listMapping = mapLeadRTypeTargetObjToListMapping.get(lead.RecordTypeId + sobjName);
        if(listMapping == null){
            return;
        }
        for(Lead_Conversion_Mapping__mdt mapping : listMapping){
            Object fieldVal = ApexUtil.getValue(mapping.Lead_Field__c, lead);
            sobj.put(mapping.Target_SObject_Field__c, fieldVal);
        }
    }
}