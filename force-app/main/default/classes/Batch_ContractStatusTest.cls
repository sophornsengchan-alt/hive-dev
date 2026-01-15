/*********************************************************************************************************************************
@ Class:          Batch_ContractStatusTest
@ Version:        1.0
@ Author:         Sambath Seng
@ Purpose:        Test class for Batch_ContractStatus class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.07.2022 / Sambath Seng / Created the test class.
*********************************************************************************************************************************/
@isTest
public class Batch_ContractStatusTest {

    @isTest
    private static void testBatchContractStatus(){
    	byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = true;
        insert avr;
        
    	RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');

        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		User standardUsr;
		System.runAs(admin){
			Profile p = [select id from Profile where name='Standard User Profile' limit 1];
            standardUsr = new User(alias = 'tsUser', email='TestStardardUser@ebay.com',
                            emailencodingkey='UTF-8', lastname='TestStandardUser', firstname='TestStandardUser', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id,
                            timezonesidkey='America/Los_Angeles', username='TestStardarduser@salesforce.de', isActive = true);
            insert standardUsr;
		}
        system.debug('AAA ' + [select userrole.name from user where id = :standardusr.id].userrole.name);
        Map<String,Account> accounts;
        Contract contract;
        RecordType rt = ApexUtil.getRecordTypeByName('Contract','EBH_ACP');
        System.runAs(standardUsr){
            accounts = EBH_TestDataFactory.setupAccountTriggerHandlerData();  
            Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = accounts.get('le1').Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
            insert contact; 
            contract = new Contract(RecordTypeId = rt.Id,
                Name = 'Test Contract 1', 
                accountId = accounts.get('le1').Id,
                Status = 'Draft',
                EBH_Site__c = 'UK',
                EBH_Language__c= 'English',
                Reason_for_Contract_Amendment__c = 'Seller / Brand Acquisition',
                EBH_RequesterNotes__c = 'test',
                Surcharge__c = true,
                PricingVersion__c = 'P1.0',
                StartDate = System.today()-1,
                EndDate = System.today(),
                Business_Contact__c=contact.id,
                EBH_FinancePostCheckDone__c = true,
                EBH_FinanceApproved__c = true
            );
            insert contract;
        }
        
        contract.Status = 'Approved';
        update contract;
        EBH_ContractSeller__c contractSeller = new EBH_ContractSeller__c(EBH_ContractNumber__c = contract.Id, EBH_BusinessName__c = accounts.get('se1').Id);
        insert contractSeller;
        Batch_ContractStatus b = new Batch_ContractStatus();
        Test.startTest();
            contract.Status = 'Executed';
            update contract;
            Database.executeBatch(b);
        	b.execute(null);
        	b = new Batch_ContractStatus(contract.Id); 
        Test.stopTest();
        Contract c = [Select Status FROM Contract Where Id =: contract.Id];
        System.assertEquals('Expired', c.Status);
    }

    

}