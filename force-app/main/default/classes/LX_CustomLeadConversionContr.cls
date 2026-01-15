/*********************************************************************************************************************************
@ Class:         LX_CustomLeadConversionContr
@ Version:       1.0
@ Author:        Acmatac Seing (acmatac.seing@gaea-sys.com)
@ Purpose:       US-0018726 [AU] New Lead Process/Fields for ebay AU SMB and ebay AU Enterprise.
@ AuraComp:      LX_CustomLeadConversion.cmp
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 029.10.2019 / Acmatac Seing (acmatac.seing@gaea-sys.com) / Created the class.
@ Change history: 14.12.2022 / Bora Chhorn (bora.chhorn@gaea-sys.com) / US-0011835 - Clean Lead Layouts (Technical Debt)
*********************************************************************************************************************************/

public without sharing class LX_CustomLeadConversionContr {
    
    private static Map<String, String> mRT_LeadProject = new Map<String, String>{
        // 'EBH_eBayAUEnterprise' => 'eBayAUEnterprise', //BR-US-0011835
        'EBH_eBayAUSMB' => 'eBayAUSMB'
    };

	//Mapping field Lead to Project
	private static Map<String,String> mappingLeadProject = new Map<String,String>
	{
		'eBayID__c' => 'eBayUserID__c',
		'EBH_OracleID__c' => 'OracleID__c',
		'EBH_Vertical__c' => 'Vertical__c',
		'LeadSegment__c' => 'LeadSegment__c',
		'LeadSource' => 'LeadSource__c',
		'OtherLeadSource__c' => 'OtherLeadSource__c',
		'Campaign__c' => 'Campaign__c',
		'Website' => 'Website__c',
		'EBH_OtherMarketplaces__c' => 'OtherMarketPlaces__c',
		'OnlineRank__c' => 'OnlineRank__c',
		'EBH_CommentsBusinessReview__c' => 'Comments__c',
		'ShippingTechnology__c' => 'ShippingTechnology__c',
		'TheoreticalRevenue__c' => 'Theoretical_Revenue__c',
		'Site__c' => 'Site__c',
        'VAT_Number__c' => 'ABNVATNumber__c'
	};
	
    
    @AuraEnabled
    public static Map<String,Object> initCLCWrapper(String leadId){
    	
    	Map<String,Object>  mapResult = new Map<String,Object>();
        CustomLeadConversionWrapper clcWrp = new CustomLeadConversionWrapper();
        try{
        	String sWhere = ' Where Id=:leadId';
            Lead oneLead = Database.query(EBH_ConstantsUtility.SOQL_LEAD2 +sWhere);
            clcWrp.lead = oneLead;
            if(oneLead.Status != EBH_ConstantsUtility.LEAD_STATUS_QLY)
            {
            	mapResult.put('status','ko'); 
            	mapResult.put('msg','Only Qualified Leads are eligible for Conversion'); 
            }else if(oneLead.Converted_Date__c <> null)
            {
            	mapResult.put('status','ko'); 
            	mapResult.put('msg','Sorry, Lead already converted!'); 
            }else
            {
            	clcWrp.convAccount.accountRTPKL = getsObjRTPKL('Account');
	            clcWrp.convAccount.account.Name = oneLead.Company;

                clcWrp.convContact.contact.FirstName = oneLead.FirstName;
                clcWrp.convContact.contact.LastName = oneLead.LastName;
	            clcWrp.convContact.contactRTPKL = getsObjRTPKL('Contact');

	            clcWrp.convProject.projects = new List<EBH_Project__c>();
	            clcWrp.convProject.projectName = oneLead.Company;

	            clcWrp.ReturnResult.isSuccess = true;
	            clcWrp.ReturnResult.msg = 'Success!';
	            
	            mapResult.put('status','ok'); 
            }

        }catch(Exception ex){
        	mapResult.put('status','ko'); 
        	mapResult.put('msg',ex.getMessage()); 
            clcWrp.ReturnResult.isSuccess = false;
            clcWrp.ReturnResult.msg = ex.getMessage();
        }
        
        mapResult.put('clcWrp',clcWrp);
        
        return mapResult;
    }
	
    @AuraEnabled
    public static CustomLeadConversionWrapper convertLead(String strCLCWrp){
        CustomLeadConversionWrapper clcWrp = new CustomLeadConversionWrapper();
        //Savepoint sp = Database.setSavepoint();
        try{
            clcWrp = (CustomLeadConversionWrapper) JSON.deserialize(strCLCWrp, CustomLeadConversionWrapper.class);
            Lead oneLead = clcWrp.lead;
            Account oneAccount = clcWrp.convAccount.account;
            Contact oneContact = clcWrp.convContact.contact;
            EBH_Project__c oneProject = clcWrp.convProject.projects[0];
            Boolean isNewAcc = String.isBlank(oneAccount.Id);
            Boolean isNewCont = String.isBlank(oneContact.Id);

            Database.LeadConvert leadConv = new Database.LeadConvert();
            leadConv.setLeadId(oneLead.Id);
            leadConv.setConvertedStatus('Converted');
            leadConv.setDoNotCreateOpportunity(true);

            if(!isNewAcc){
                leadConv.setAccountId(oneAccount.Id);
            }

            if(!isNewCont){
                leadConv.setContactId(oneContact.Id);
            }

            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            //dml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.LeadConvertResult lcr = Database.convertLead(leadConv, dml);
            if(!lcr.isSuccess()){
                clcWrp.ReturnResult.isSuccess = false;
                clcWrp.ReturnResult.msg = lcr.getErrors()[0].getMessage();
                return clcWrp;
            }
            Id accId = lcr.getAccountId();
            Id contactId = lcr.getContactId();

            String accName = oneAccount.Name;
            Account acc = new Account();
            if(isNewAcc){
                acc.Id = accId;
                acc.Name = accName;
                acc.RecordTypeId = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller').Id;
                update acc;
            }

            String contFirst = oneContact.FirstName;
            String contLast = oneContact.LastName;
            Contact cont = new Contact();
            cont.Id = contactId;
            //Standard Mapping Lead not support for address
            cont.EBH_MailingStreet__c = oneLead.Street;
            cont.EBH_MailingCity__c = oneLead.City;
            cont.EBH_MailingCountry__c = oneLead.Country;
            cont.EBH_MailingPostalCode__c = oneLead.PostalCode;
            cont.EBH_MailingState__c = oneLead.State;
            if(isNewCont){
                cont.FirstName = contFirst;
                cont.LastName = contLast;
                cont.RecordTypeId = ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL').Id;
            }
            update cont;

            oneProject = (EBH_Project__c) transformLeadTosObj('EBH_Project__c', oneLead, oneProject);
            oneProject.EBH_Seller__c = accId;
            oneProject.RecordTypeId = ApexUtil.getRecordTypeByName('EBH_Project__c', mRT_LeadProject.get(oneLead.RecordType.DeveloperName)).Id;
            upsert oneProject;

            //Lead lead = new Lead();
            //lead.Id = oneLead.Id;
            //lead.Converted_Date__c = System.today();
            //lead.Status = 'Converted';
            //update lead;

            clcWrp.ReturnResult.isSuccess = true;
            clcWrp.ReturnResult.msg = 'Success!';
            return clcWrp;

        }catch(Exception ex){
            //Database.rollback(sp);
            clcWrp.ReturnResult.isSuccess = false;
            clcWrp.ReturnResult.msg = ex.getMessage();
             //system.debug('>>>>>>:'+ex);
            return clcWrp;
        }
    }
    
    @AuraEnabled
    public static CustomLeadConversionWrapper fetchProject(String accId){
        CustomLeadConversionWrapper clcWrp = new CustomLeadConversionWrapper();
        try{
            List<EBH_Project__c> lstProj = [SELECT Name, CloseDate__c FROM EBH_Project__c WHERE EBH_Seller__c =: accId];
            clcWrp.convProject.projects = lstProj;

            clcWrp.ReturnResult.isSuccess = true;
            clcWrp.ReturnResult.msg = 'Success!';
            return clcWrp;

        }catch(Exception ex){
            clcWrp.ReturnResult.isSuccess = false;
            clcWrp.ReturnResult.msg = ex.getMessage();
            return clcWrp;
        }
    }

/* 
* Private Method
*******/

    private static List<PicklistWrapper> getsObjRTPKL(String sObjectName){
        List<PicklistWrapper> lstPklWrp = new List<PicklistWrapper>();
        for(RecordType oneRT : [SELECT Name, DeveloperName FROM RecordType WHERE sObjectType =: sObjectName]){
            PicklistWrapper onePklWrp = new PicklistWrapper();
            onePklWrp.label = oneRT.Name;
            onePklWrp.value = oneRT.Id;
            lstPklWrp.add(onePklWrp);
        }
        return lstPklWrp;
    }
    
	private static Map<String,String> getMapping(String sobjType)
	{
		if(sobjType=='EBH_Project__c')	
		{
			return mappingLeadProject;
		}
		
		return null;
	}
	
    private static SObject transformLeadTosObj(String sObjType, Lead oneLead, SObject oneSObj){
        Map<String,String> mapField = getMapping(sObjType);
        for(String leadFname : mapField.keySet()){
        	String targetFname = mapField.get(leadFname);
        	 oneSObj.put(targetFname, oneLead.get(leadFname));
        }
        return oneSObj;
    }
 
	/* 
	* Wrapper Class
	*******/

    public class ReturnResultWrapper {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String msg;

        public ReturnResultWrapper(){
            this.isSuccess = false;
            this.msg = '';
        }
    }

    public class CustomLeadConversionWrapper {
        @AuraEnabled public Lead lead;
        @AuraEnabled public AccountWrapper convAccount;
        @AuraEnabled public ContactWrapper convContact;
        @AuraEnabled public ProjectWrapper convProject;

        @AuraEnabled public ReturnResultWrapper ReturnResult;

        public CustomLeadConversionWrapper(){
            this.lead = new Lead();
            this.convAccount = new AccountWrapper();
            this.convContact = new ContactWrapper();
            this.convProject = new ProjectWrapper();
            this.ReturnResult = new ReturnResultWrapper();
        }
    }

    public class AccountWrapper {
        @AuraEnabled public Account account;
        @AuraEnabled public List<PicklistWrapper> accountRTPKL;

        public AccountWrapper() {
            this.account = new Account();
            this.accountRTPKL = new List<PicklistWrapper>();
        }
    }

    public class ContactWrapper {
        @AuraEnabled public Contact contact;
        @AuraEnabled public List<PicklistWrapper> contactRTPKL;

        public ContactWrapper() {
            this.contact = new Contact();
            this.contactRTPKL = new List<PicklistWrapper>();
        }
    }

    public class ProjectWrapper {
        @AuraEnabled public List<EBH_Project__c> projects;
        @AuraEnabled public String projectName;

        public ProjectWrapper() {
            this.projects = new List<EBH_Project__c>();
            this.projectName = '';
        }
    }

    public class PicklistWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistWrapper(){
            this.label = '';
            this.value = '';
        }
    }
}