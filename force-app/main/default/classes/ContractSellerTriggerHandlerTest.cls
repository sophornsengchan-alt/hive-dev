@isTest
private class ContractSellerTriggerHandlerTest {
    @TestSetup
    static void setup(){
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller', Contract_Seller__c = true);
    }

    @isTest
    static void testValidate3PPContractSeller_Insert(){
        Account partnerAcc = new Account(
            RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_Partner').Id,
            Name = 'TST ACC Partner ',
            EBH_OracleID__c = '11111111'
        );
        insert partnerAcc;
        
        Map<String,Account> accounts = EBH_TestDataFactory.setupAccountTriggerHandlerData();

    	RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = partnerAcc.Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact;

        /****** CREATE CONTRACT RECORD ************************/
        Contract c = new Contract(RecordTypeId = ApexUtil.getRecordTypeByName('Contract','Three_PP_Pricing_Program').Id, 
            Name = 'Test Contract 1', 
            accountId = partnerAcc.Id,
            Status = EBH_ConstantsUtility.CONTRACT_DRAFTSTATUS,
            EBH_Site__c = 'UK',
            EBH_Language__c= 'English',
            Reason_for_Contract_Amendment__c = 'Seller / Brand Acquisition',
            EBH_RequesterNotes__c = 'test',
            Surcharge__c = true,
            PricingVersion__c = 'P1.0',
            StartDate = System.today(),
            EndDate = System.today() + 1,
            Business_Contact__c=contact.id
        );
        insert c;

        /****** CREATE CONTRACT SELLER RECORD ************************/
        EBH_ContractSeller__c contractSeller = new EBH_ContractSeller__c(EBH_ContractNumber__c = c.Id, EBH_BusinessName__c = accounts.get('se1').Id, StartDate__c = System.today(), Status__c = 'Active');
        insert contractSeller;
        Test.startTest();
            try{
                EBH_ContractSeller__c contractSeller2 = new EBH_ContractSeller__c(EBH_ContractNumber__c = c.Id, EBH_BusinessName__c = accounts.get('se1').Id, StartDate__c = System.today(), Status__c = 'Active');
                insert contractSeller2;
            }catch(Exception e){
                Assert.isTrue(e.getMessage().contains(Label.Duplicate_3PPContractSeller_ErrorMessage));
            }
        Test.stopTest();
    }
    
    @isTest
    static void testValidate3PPContractSeller_Update(){
        Account partnerAcc = new Account(
            RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_Partner').Id,
            Name = 'TST ACC Partner ',
            EBH_OracleID__c = '11111111'
        );
        insert partnerAcc;
        
        Map<String,Account> accounts = EBH_TestDataFactory.setupAccountTriggerHandlerData();

    	RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = partnerAcc.Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact;

        /****** CREATE CONTRACT RECORD ************************/
        Contract c = new Contract(RecordTypeId = ApexUtil.getRecordTypeByName('Contract','Three_PP_Pricing_Program').Id, 
            Name = 'Test Contract 1', 
            accountId = partnerAcc.Id,
            Status = EBH_ConstantsUtility.CONTRACT_DRAFTSTATUS,
            EBH_Site__c = 'UK',
            EBH_Language__c= 'English',
            Reason_for_Contract_Amendment__c = 'Seller / Brand Acquisition',
            EBH_RequesterNotes__c = 'test',
            Surcharge__c = true,
            PricingVersion__c = 'P1.0',
            StartDate = System.today(),
            EndDate = System.today() + 1,
            Business_Contact__c=contact.id
        );
        insert c;

        /****** CREATE CONTRACT SELLER RECORD ************************/
        EBH_ContractSeller__c contractSeller = new EBH_ContractSeller__c(EBH_ContractNumber__c = c.Id, EBH_BusinessName__c = accounts.get('se1').Id, StartDate__c = System.today(), Status__c = 'Active');
        insert contractSeller;
        EBH_ContractSeller__c contractSeller2 = new EBH_ContractSeller__c(EBH_ContractNumber__c = c.Id, EBH_BusinessName__c = accounts.get('se1').Id, StartDate__c = System.today().addDays(-1), Status__c = 'Active');
        insert contractSeller2;
        Test.startTest();
            try{
                contractSeller2.StartDate__c=System.today();
                update contractSeller2;
            }catch(Exception e){
                Assert.isTrue(e.getMessage().contains(Label.Duplicate_3PPContractSeller_ErrorMessage));
            }
        Test.stopTest();
    }

    @isTest
    static void testValidateLockedFields(){

        Account legalEntity = new Account(
            RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id,
            Name = 'TST Legal Entity ',
            EBH_BillingCountry__c = 'US'
        );
        insert legalEntity;

        Account seller1 = new Account(
            RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id,
            Name = 'TST Seller 1',
            EBH_RevRollup__c = 'US'
        );
        insert seller1;

        Account seller2 = new Account(
            RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id,
            Name = 'TST Seller 2',
            EBH_RevRollup__c = 'US'
        );
        insert seller2;

        Contact cont = new Contact(
            RecordTypeId = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL').Id,
            LastName = 'TST',
            FirstName = 'Contact',
            Email = 'test@test.com',
            AccountId = legalEntity.Id
        );
        insert cont;

        Contract contr = new Contract(
            RecordTypeId = ApexUtil.getRecordTypeByName('Contract','VIP_Contracts').Id, 
            Name = 'Test LA Contract', 
            Status = 'Draft',
            EBH_Language__c = 'English',
            Reason_for_Contract_Amendment__c = 'Seller / Brand Acquisition',
            EBH_Site__c = 'US',
            EBH_ContractAmendment__c = 'Master/ Standalone',
            EBH_MainVertical__c = 'Business & Industrial',
            EBH_RequesterNotes__c = 'Test',
            StartDate = System.today(),
            EndDate = System.today() + 1,
            AccountId = legalEntity.Id,
            Business_Contact__c = cont.Id
        );
        insert contr;
        
        EBH_ContractSeller__c contrSeller = new EBH_ContractSeller__c(
            EBH_ContractNumber__c = contr.Id,
            EBH_BusinessName__c = seller1.Id
        );
        insert contrSeller;
        
        contr.EBH_FinanceAgreesinPrincipal__c = True;
        contr.EBH_AttachmentCheck__c = true;
        contr.EBH_FinancePostCheckDone__c = False;
        contr.EBH_AverageTakeRate__c = 1;
        contr.Status = 'Sent for Finance Post-check';
        Update contr;

        contr.Status = 'Pricing Configuration';
        Update contr;

        contrSeller.EBH_BusinessName__c = seller2.Id;

        Test.startTest();
            try {
                update contrSeller;
            } catch (Exception e) {
                System.assert(FeatureManagement.checkPermission('BypassLockedPricingConfiguration') || e.getMessage().containsIgnoreCase(Label.PricingConfigurationLockedFieldsMessage));
            }
        Test.stopTest();

    }

    @isTest
    static void testValidatePrimarySeller(){

        Account legalEntity = new Account(
            RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id,
            Name = 'TST Legal Entity ',
            EBH_BillingCountry__c = 'US'
        );
        insert legalEntity;

        Account seller1 = new Account(
            RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id,
            Name = 'TST Seller 1',
            EBH_RevRollup__c = 'US'
        );
        insert seller1;

        Account seller2 = new Account(
            RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id,
            Name = 'TST Seller 2',
            EBH_RevRollup__c = 'US'
        );
        insert seller2;

        Contact cont = new Contact(
            RecordTypeId = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL').Id,
            LastName = 'TST',
            FirstName = 'Contact',
            Email = 'test@test.com',
            AccountId = legalEntity.Id
        );
        insert cont;

        Contract contr = new Contract(
            RecordTypeId = ApexUtil.getRecordTypeByName('Contract','VIP_Contracts').Id, 
            Name = 'Test LA Contract', 
            Status = 'Draft',
            EBH_Language__c = 'English',
            Reason_for_Contract_Amendment__c = 'Seller / Brand Acquisition',
            EBH_Site__c = 'US',
            EBH_ContractAmendment__c = 'Master/ Standalone',
            EBH_MainVertical__c = 'Business & Industrial',
            EBH_RequesterNotes__c = 'Test',
            StartDate = System.today(),
            EndDate = System.today() + 1,
            AccountId = legalEntity.Id,
            Business_Contact__c = cont.Id
        );
        insert contr;
        
        EBH_ContractSeller__c contrSeller = new EBH_ContractSeller__c(
            EBH_ContractNumber__c = contr.Id,
            EBH_BusinessName__c = seller1.Id,
            PrimarySeller__c = true
        );
        insert contrSeller;
        
        Test.startTest();
            try {
                contrSeller.PrimarySeller__c = false;
                update contrSeller;
            } catch (Exception e) {
                System.assert(e.getMessage().contains(Label.ErrMSG_CS_NoPrimarySeller), 'The error message is not as expected');
            }
        Test.stopTest();

    }
}