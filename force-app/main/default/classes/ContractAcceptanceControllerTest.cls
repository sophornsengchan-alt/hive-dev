@isTest
private class ContractAcceptanceControllerTest {
    @isTest 
    private static void test_method(){
    	byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = true;
        insert avr;
        
    	Map<String,Account> accounts = EBH_TestDataFactory.setupAccountTriggerHandlerData();  
    	RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
	    Contact contact = new Contact(EBH_MailingAddress__c = 'uk',EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = accounts.get('le1').Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');            
	    insert contact; 
        Id RT_PRELOVED_ID = ApexUtil.getRecordTypeByName('Contract','Pre_Loved_Partner_Program').Id;
    	Contract contract = new Contract(RecordTypeId = RT_PRELOVED_ID, 
            Name = 'Test Contract 1', 
            accountId = accounts.get('le1').Id,
            Status = 'Draft',
            EBH_Site__c = 'UK',
            EBH_Language__c= 'English',
            Reason_for_Contract_Amendment__c = 'Seller / Brand Acquisition',
            EBH_RequesterNotes__c = 'test',
            StartDate = System.today(),
            EndDate = System.today() + 1,
            Business_Contact__c=contact.id,
            Contract_Signed_by__c=contact.id,
            Support_Request_Email__c = 'test.contract@test.com'
        );
        insert contract;
        EBH_ContractSeller__c contractSeller = new EBH_ContractSeller__c(EBH_ContractNumber__c = contract.Id, EBH_BusinessName__c = accounts.get('se1').Id);
        insert contractSeller;
        contract.Status = 'Contract Accepted';
        update contract;
        test.startTest();
        	ContractAcceptanceController controller = new ContractAcceptanceController();
            controller.con = contract;
            controller.getPage();
        test.stopTest();
    }
}