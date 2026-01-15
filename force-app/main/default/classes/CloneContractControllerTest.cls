/*********************************************************************************************************************************
@ Class:          CloneContractControllerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0003807 [Contracts] Ability to clone pricing details when cloning Contract
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.01.2020 / Sovantheany Dim / Created the class.
*********************************************************************************************************************************/
@isTest
private class CloneContractControllerTest {
	@testSetup private static void setup() {
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' Limit 1];  
        User objUser = new User(Alias = 'JNgom1', 
                                Email = 'jacques.ngom-lea@maxappsltd.co.uk', 
                                EmailEncodingKey = 'UTF-8', 
                                LastName = 'Ngom-Lea',
                                LocaleSidKey = 'en_US', 
                                LanguageLocaleKey='en_US', 
                                ProfileId = objProfile.Id, 
                                TimeZoneSidKey = 'Europe/London', 
                                UserName = 'test@hive.project.com.invalide');
        insert objUser;
        System.runAs(objUser){
            RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
            Contact oneCont = new Contact();
            oneCont.LastName = 'testCont';
            oneCont.Email = 'test@gg.com';
            oneCont.recordTypeId = manaulconRt.Id;
            
            Contact oneCont2 = new Contact();
            oneCont2.LastName = 'testCont2';
            oneCont2.Email = 'test2@gg.com';
            oneCont2.recordTypeId = manaulconRt.Id;
            insert new List<Contact>{oneCont,oneCont2};
            
            Account acc = new Account();
            acc.Name = 'TestAcclegal';
            acc.RecordTypeID = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id;
            acc.Primary_Contact__c = oneCont.Id;
            acc.EBH_BillingCountry__c = 'UK';
            acc.EBH_OracleID__c = '11111';
            Account acc2 = new Account();
            acc2.Name = 'TestPartner1';
            acc2.RecordTypeID = ApexUtil.getRecordTypeByName('Account','EBH_Partner').Id;
            acc2.Primary_Contact__c = oneCont.Id;
            acc2.EBH_OracleID__c = '22222';
            insert new List<Account>{acc,acc2};
            Account acc3 = new Account();
            acc3.Name = 'TestAccSell';
            acc3.RecordTypeID = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id;
            acc3.Primary_Contact__c = oneCont2.Id;
            acc3.ParentId = acc.Id;
            acc3.EBH_OracleID__c = '33333';
            Account acc4 = new Account();
            acc4.Name = 'TestPpp';
            acc4.RecordTypeID = ApexUtil.getRecordTypeByName('Account','EBH_Partner').Id;
            acc4.Primary_Contact__c = oneCont2.Id;
            acc4.ParentId = acc.Id;
            acc4.EBH_OracleID__c = '4444';
            insert new List<Account>{acc3,acc4};
        }
        
	}
	
	static Contract createContract(id recordTypeId, id userId, id accId, id parterId, id standardPriceId){
		RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = accId,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact;
		Contract contract = new Contract();
        contract.RecordTypeId = recordTypeId;
        contract.OwnerId = userId;
        contract.AccountId = accId;
        contract.EBH_ContractAmendment__c = 'Master/ Standalone';
        contract.EBH_Language__c = 'English';
        contract.EBH_Site__c = 'DE';
        contract.EBH_RequesterNotes__c = 'test Note';
        contract.EBH_PreApprovedTemplate__c = true;
        contract.EBH_FinanceAgreesinPrincipal__c = true;
        contract.Status = 'Draft';
        contract.EBH_EUSignNotes__c = 'test eu signNot';
        contract.EBH_eBayLegalEntity__c = accId;
        contract.EBH_ContractValue__c = 10;
        contract.EBH_eTRSEligible__c = 'No';
        contract.EBH_ContractExposure__c = 10;
        contract.Reason_for_Contract_Amendment__c = 'Seller Acceleration';
        contract.EBH_MainVertical__c = 'Electronics';
        //contract.EBH_StoreSubscription__c = 'Standard Price';
        contract.AM_Bolt_on__c = 'Standard Price';
        contract.EBH_DeceleratorThreshold__c = 1;
        contract.EBH_MainTierThresholdofTarget__c = 1;
        contract.EBH_AcceleratorThreshold__c = 1;
        contract.EBH_AverageTakeRate__c = 1;
        contract.EBH_DeceleratorTierrebate__c = 1;
        contract.EBH_RebateTierrebate__c = 1;
        contract.EBH_AcceleratorTierrebate__c = 1;
        contract.EBH_IncrementalGMVonly__c = true;
        contract.EBH_Partner__c = parterId;
        contract.Pricebook2Id = standardPriceId;
        contract.Surcharge__c = true;
        contract.Business_Contact__c=contact.id;
        return contract;
	}
	static testMethod void testapexCloneContractListing() {
		User user = [select id from User where UserName = 'test@hive.project.com.invalide'];
		Account acc = [select id from Account where Name = 'TestAcclegal'];
		Account partneracc = [select id from Account where Name = 'TestPartner1'];
		Account selleracc = [select id from Account where Name = 'TestAccSell'];
		RecordType reListingContract = EBH_TestDataFactory.getRecordTypeByName('Contract',EBH_ConstantsUtility.CONTRACT_LISTINGRECORDTYPE);
        Contract contract = createContract(reListingContract.Id, user.Id, acc.Id, partneracc.Id, Test.getStandardPricebookId());
        contract.PricingVersion__c='P1.0';
        insert contract;
        EBH_ContractSeller__c contractSeller = new EBH_ContractSeller__c(EBH_BusinessName__c = selleracc.Id, EBH_ContractNumber__c = contract.Id);
        insert contractSeller;
		
        EBH_ContractPricingMatrix__c conMatrix = createContractPricingMatrix('UK','GBP');
        insert conMatrix;

        List<EBH_Pricing__c> pricings1 = createPricing (1, EBH_ConstantsUtility.PRICING_LISTINGRECORDTYPE,contract.id, 15, 900.00, 800.00, 2000000, 800, 'UK');
        pricings1[0].CurrencyIsoCode = 'GBP';
        pricings1[0].EBH_ContractPricingMatrix__c =  conMatrix.Id;
        insert pricings1;
        Attachment a = new Attachment(parentId=contract.id,name='test');
  		a.body = Blob.valueOf('Testing Body of Attachment');
  		insert a;
  		ContentVersion att2 = EBH_TestDataFactory.createFileAttachment('TestAtt2', 'test attach2' ,contract.Id );
  		Contract contractsRelated = createContract(reListingContract.Id, user.Id, acc.Id, partneracc.Id, Test.getStandardPricebookId());
  		contractsRelated.EBH_LinkedContract__c = contract.Id;
  		contractsRelated.EBH_ContractAmendment__c = 'Amendment';
  		insert contractsRelated;
		Test.startTest();
		Map<String,Object> mapResult = CloneContractController.apexCloneContract(contract.Id);
		Test.stopTest();
		System.assertEquals('ok',mapResult.get('status'));
	}

    static EBH_ContractPricingMatrix__c createContractPricingMatrix(String Site,String isoCode ) {
        
         return new EBH_ContractPricingMatrix__c(
            EBH_CAP__c = 10,
            EBH_FVF__c = 20,
            EBH_ListingFormat__c = 'Auction',
            EBH_SiteCountry__c = Site,
            EBH_Site__c = Site,
            CurrencyIsoCode =    isoCode     
       );
     }

	static List<EBH_Pricing__c> createPricing(Integer numRecords, String recordType, Id contractID, Decimal EBH_FVFDiscount,Decimal EBH_FVFCap, Decimal EBH_ASP, Decimal EBH_Projected12MGMV, Decimal EBH_DefaultFVFCap, String EBH_Site) {
        
        List<EBH_Pricing__c> pricingRecords = new List<EBH_Pricing__c>();
        RecordType rt = ApexUtil.getRecordTypeByName('EBH_Pricing__c', recordType);  //Database.query(PRICINGRECTYPQUERY);
        
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            pricingRecords.add(new EBH_Pricing__c(RecordTypeId = rt.Id, 
                                       //Name = 'Test Pricing Record ' + iCounter, 
                                       EBH_ContractId__c = contractId,
                                       EBH_FVFDiscount__c = EBH_FVFDiscount, 
                                       EBH_FVFCap__c = EBH_FVFCap, 
                                       EBH_ASP__c = EBH_ASP, 
                                       EBH_Projected12MGMV__c = EBH_Projected12MGMV, 
                                       EBH_DefaultFVFCap__c = EBH_DefaultFVFCap,
                                       EBH_Site__c = EBH_Site                                        
                                       ));
        }
       
         
        return pricingRecords;
    }

	static testMethod void testapexCloneContractACP() {
		User user = [select id from User where UserName = 'test@hive.project.com.invalide'];
		Account acc = [select id from Account where Name = 'TestAcclegal'];
		Account partneracc = [select id from Account where Name = 'TestPartner1'];
		Account selleracc = [select id from Account where Name = 'TestAccSell'];
		RecordType reListingContract = EBH_TestDataFactory.getRecordTypeByName('Contract',EBH_ConstantsUtility.CONTRACT_ACPRECORDTYPE);
		Contract contract = createContract(reListingContract.Id, user.Id, acc.Id, partneracc.Id, Test.getStandardPricebookId());
        insert contract;
        EBH_ContractSeller__c contractSeller = new EBH_ContractSeller__c(EBH_BusinessName__c = selleracc.Id, EBH_ContractNumber__c = contract.Id);
        insert contractSeller;
		List<EBH_Pricing__c> pricings1 = EBH_TestDataFactory.createPricing (1, EBH_ConstantsUtility.PRICING_ACPTARGETRECORDTYPE, 
                                                    contract.id, 15, 900.00, 800.00, 2000000, 800, 'UK');
        Attachment a = new Attachment(parentId=contract.id,name='test');
  		a.body = Blob.valueOf('Testing Body of Attachment');
  		insert a;
  		ContentVersion att2 = EBH_TestDataFactory.createFileAttachment('TestAtt2', 'test attach2' ,contract.Id );
  		Contract contractsRelated = createContract(reListingContract.Id, user.Id, acc.Id, partneracc.Id, Test.getStandardPricebookId());
  		contractsRelated.EBH_LinkedContract__c = contract.Id;
  		contractsRelated.EBH_ContractAmendment__c = 'Amendment';
  		insert contractsRelated;
		Test.startTest();
		Map<String,Object> mapResult = CloneContractController.apexCloneContract(contract.Id);
		Test.stopTest();
		System.assertEquals('ok',mapResult.get('status'));
	}
	
	static testMethod void testapexCloneContractRevenue() {
		User user = [select id from User where UserName = 'test@hive.project.com.invalide'];
		Account acc = [select id from Account where Name = 'TestAcclegal'];
		Account partneracc = [select id from Account where Name = 'TestPartner1'];
		Account parteracc2 = [select id from Account where Name = 'TestPpp'];
		RecordType reListingContract = EBH_TestDataFactory.getRecordTypeByName('Contract',EBH_ConstantsUtility.CONTRACT_RSRECORDTYPE);
		Contract contract = createContract(reListingContract.Id, user.Id, acc.Id, partneracc.Id, Test.getStandardPricebookId());
        insert contract;
        EBH_ContractSeller__c contractSeller = new EBH_ContractSeller__c(EBH_BusinessName__c = parteracc2.Id, EBH_ContractNumber__c = contract.Id);
        insert contractSeller;
		List<EBH_Pricing__c> pricings1 = EBH_TestDataFactory.createPricing (1, EBH_ConstantsUtility.PRICING_REVENUESHARETARGETRECORDTYPE, 
                                                    contract.id, 15, 900.00, 800.00, 2000000, 800, 'UK');
        Attachment a = new Attachment(parentId=contract.id,name='test');
  		a.body = Blob.valueOf('Testing Body of Attachment');
  		insert a;
  		ContentVersion att2 = EBH_TestDataFactory.createFileAttachment('TestAtt2', 'test attach2' ,contract.Id );
  		Contract contractsRelated = createContract(reListingContract.Id, user.Id, acc.Id, partneracc.Id, Test.getStandardPricebookId());
  		contractsRelated.EBH_LinkedContract__c = contract.Id;
  		contractsRelated.EBH_ContractAmendment__c = 'Amendment';
  		insert contractsRelated;
		Test.startTest();
		Map<String,Object> mapResult = CloneContractController.apexCloneContract(contract.Id);
		Test.stopTest();
		System.assertEquals('ok',mapResult.get('status'));
	}
}