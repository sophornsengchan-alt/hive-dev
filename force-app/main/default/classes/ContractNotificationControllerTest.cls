@IsTest 
public class ContractNotificationControllerTest {
	@isTest 
    static void test_method() {
        User admin = EBH_TestDataFactory.createUser('System Administrator');
        System.runAs(admin)
    	{
        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = true;
        insert avr;   
        RecordType rt = ApexUtil.getRecordTypeByName('Contract','EBH_ACP');
        RecordType leg = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
        
        Map<String,Account> accounts = EBH_TestDataFactory.setupAccountTriggerHandlerData();
        RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = accounts.get('le1').Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact; 
        Contract contract = new Contract(RecordTypeId = rt.Id, 
                                       Name = 'Test Contract ', 
                                       accountId = accounts.get('le1').Id, 
                                       EBH_eBayLegalEntity__c = accounts.get('le1').Id, 
                                       Status='Draft',
                                       Surcharge__c = true,
                                       EBH_FinanceAgreesinPrincipal__c = true,
                                       StartDate = System.today(), 
                                       EndDate = System.today().addDays(1),
                                       Business_Contact__c=contact.id
        );  
        Contract contract2 = new Contract(RecordTypeId = rt.Id, 
                                       Name = 'Test Contract ', 
                                       accountId = accounts.get('le1').Id, 
                                       EBH_eBayLegalEntity__c = accounts.get('le1').Id, 
                                       Status='Draft',
                                       Surcharge__c = true,
                                       EBH_FinanceAgreesinPrincipal__c = true,
                                       StartDate = System.today(), 
                                       EndDate = System.today().addDays(1),
                                       Business_Contact__c=contact.id
        );
        insert new List<Contract>{contract,contract2};
        contract2.Status = 'Approved';
        update contract2;
        EBH_ContractSeller__c contractSeller = new EBH_ContractSeller__c(EBH_ContractNumber__c = contract.Id, EBH_BusinessName__c = accounts.get('se1').Id);
        EBH_ContractSeller__c contractSeller2 = new EBH_ContractSeller__c(EBH_ContractNumber__c = contract2.Id, EBH_BusinessName__c = accounts.get('se1').Id);
        insert new List<EBH_ContractSeller__c>{contractSeller,contractSeller2};
          
		Test.startTest();
            contract2.Status = 'Executed';
            update contract2;
            Map<String,Object> data = ContractNotificationController.checkAccountExistingExecutedContract(contract.Id);
           // System.assertEquals('1', rw.dealCount);
        Test.stopTest();        
       }
    }
}