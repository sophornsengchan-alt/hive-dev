/*********************************************************************************************************************************
@ Class:          ContractCategoryTriggerHandlerTest
@ Version:        1.0
@ Author:         SRONG TIN
@ Purpose:        Handler Class for ContractCategoryTriggerHandler
US-0016063 - Pricing Configuration Record Lock - Contract & Pricing
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.01.2025 / SRONG TIN / Created the class.
*********************************************************************************************************************************/
@isTest
private class ContractCategoryTriggerHandlerTest {

    @testSetup static void setUp() {
		//EBH_TestDataFactory.setUpCustomSettings();  
        EBH_ActiveTriggers__c cusettingTrigger = new EBH_ActiveTriggers__c();
        cusettingTrigger.Name = 'EBH Trigger Controller';
        cusettingTrigger.ContractCategoryTrigger__c = true;
        cusettingTrigger.Contract_Seller__c = true;
        insert cusettingTrigger; 
        byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Contract_Category__c', byPass_Trigger__c = false);
        insert bp;
        
	}
    @isTest
    static void testContractCategory(){
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
        
        EBH_ContractPricingMatrix__c conMatrix = new EBH_ContractPricingMatrix__c(
            EBH_CAP__c = 10,
            EBH_FVF__c = 20,
            EBH_ListingFormat__c = 'Auction',
            EBH_SiteCountry__c = 'US',
            EBH_Site__c = 'US',
            CurrencyIsoCode = 'USD'     
       );
        insert conMatrix;
        
        RecordType PricingRecordType = ApexUtil.getRecordTypeByName('EBH_Pricing__c','EBH_ListingPricing');
        EBH_Pricing__c pricing = new EBH_Pricing__c(EBH_ContractId__c=contr.Id,
            EBH_Site__c='US',
            EBH_ContractPricingMatrix__c = conMatrix.Id,
            EBH_Projected12MGMV__c = 11,
            EBH_ASP__c =11,
            RecordTypeId = PricingRecordType.Id
        );
        insert pricing;
        
        Category_Tree__c ct0 = new Category_Tree__c(Name = 'l0',Active__c=true,Site__c='0', Level__c = 0);
     	insert ct0;
    	Category_Tree__c ct1 = new Category_Tree__c(Name = 'l1',Note_ID__c=ct0.Id,Active__c=true, Site__c='0',  Level__c = 1);
    	insert ct1;
		Category_Tree__c ct2 = new Category_Tree__c(Name = 'l2',Note_ID__c = ct1.Id,Active__c=true, Site__c='0',  Level__c = 2);
		insert ct2;
		Category_Tree__c ct3 = new Category_Tree__c(Name = 'l3',Note_ID__c = ct2.Id,Active__c=true, Site__c='0',  Level__c = 3);
    	insert ct3;
        
        Contract_Category__c concat1 = new Contract_Category__c(Contratc_Category_Type__c='0',Contract_Pricing_Matrix__c= conMatrix.Id,Category__c = ct3.Id, Contract__c = contr.Id);
        insert concat1;
        
        EBH_ContractSeller__c contrSeller = new EBH_ContractSeller__c(
            EBH_ContractNumber__c = contr.Id,
            EBH_BusinessName__c = seller1.Id
        );
        insert contrSeller;
        
        contr.EBH_FinanceAgreesinPrincipal__c = True;
        contr.EBH_AttachmentCheck__c = true;
        contr.EBH_FinancePostCheckDone__c = False;
        contr.Status = 'Sent for Finance Post-check';
        Update contr;

        contr.Status = 'Pricing Configuration';
        Update contr;

        concat1.Mandatory_Exclusion_List__c = true;
        Test.startTest();
            try {
                update concat1;
                delete concat1;             
            } catch (Exception e) {
                System.assert(e.getMessage().contains(Label.PricingConfigurationLockedFieldsMessage));
            }
        Test.stopTest();

    }


    @isTest
    static void testDeleteMatchingVIPContractCategory() {

        // Setup test data
        Account legalEntity = new Account(
            RecordTypeId = ApexUtil.getRecordTypeByName('Account', 'EBH_LegalEntity').Id,
            Name = 'Test Legal Entity',
            EBH_BillingCountry__c = 'US'
        );
        insert legalEntity;

        Contact contact = new Contact(
            RecordTypeId = ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL').Id,
            LastName = 'Test',
            FirstName = 'Contact',
            Email = 'test@test.com',
            AccountId = legalEntity.Id
        );
        insert contact;

        Contract contract = new Contract(RecordTypeId = ApexUtil.getRecordTypeByName('Contract','VIP_Contracts').Id, 
            Name = 'Test Contract 1', 
            accountId = legalEntity.Id,
            Status='Draft',
            StartDate = System.today(),
            EndDate = System.today() + 1,
            Surcharge__c = true,
            EBH_Site__c = 'UK',
            Business_Contact__c=contact.id
        );

        insert contract;

        // Create test data
        Category_Tree__c category1 = new Category_Tree__c(
            Name = 'Test Category 1',
            Site_Name__c = 'UK',
            Site__c = '3',
            Active__c = true
        );
        insert category1;

        Category_Tree__c category2 = new Category_Tree__c(
            Name = 'Test Category 2',
            Site_Name__c = 'UK',
            Site__c = '3',
            Active__c = true
        );
        insert category2;

        Id vipCusCPMRecordTypeId = Schema.SObjectType.EBH_ContractPricingMatrix__c.getRecordTypeInfosByDeveloperName().get('VIP_Custom').getRecordTypeId();

        EBH_ContractPricingMatrix__c pricingMatrix = new EBH_ContractPricingMatrix__c(
            EBH_Site__c = 'UK',
            Active__c = true,
            RecordTypeId = vipCusCPMRecordTypeId
        );
        insert pricingMatrix;

        // Create the EBH_Pricing__c record
        Id vipPricingRecordTypeId = Schema.SObjectType.EBH_Pricing__c.getRecordTypeInfosByDeveloperName().get('VIP_Pricing').getRecordTypeId();
        EBH_Pricing__c vipPricing = new EBH_Pricing__c(
            RecordTypeId = vipPricingRecordTypeId,
            EBH_ContractPricingMatrix__c = pricingMatrix.Id,
            EBH_ContractId__c = contract.Id,
            EBH_Site__c = 'UK'
        );
        insert vipPricing;

        String CONTRACTCATEGORY_PRICINGID       =  ApexUtil.getRecordTypeByName('Contract_Category__c','Pricing_Contract_Category').Id;
        String CONTRACTCATEGORY_VIPID           =  ApexUtil.getRecordTypeByName('Contract_Category__c','VIP_Contract_Category').Id;

        Contract_Category__c contractCategory1 = new Contract_Category__c(
            Category__c = category1.Id,
            Contract__c = contract.Id,
            Contract_Pricing_Matrix__c = pricingMatrix.Id,
            ContractPricing__c = vipPricing.Id,
            Contratc_Category_Type__c = '1',
            RecordTypeId = CONTRACTCATEGORY_PRICINGID
        );
        
        Contract_Category__c contractCategory2 = new Contract_Category__c(
            Category__c = category1.Id,
            Contract__c = contract.Id,
            Contract_Pricing_Matrix__c = pricingMatrix.Id,
            Contratc_Category_Type__c = '1',
            RecordTypeId = CONTRACTCATEGORY_VIPID
        );
        
        insert new List<Contract_Category__c>{contractCategory1, contractCategory2};

        
        // Call the method to delete matching VIP contract categories
        Test.startTest();

            delete contractCategory1;
        
        Test.stopTest();

        // Verify the record is deleted
        System.assertEquals(0, [SELECT COUNT() FROM Contract_Category__c WHERE Contract__c = :contract.Id]);
    }

}