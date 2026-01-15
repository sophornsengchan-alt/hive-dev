/*********************************************************************************************************************************
@ Class:          ContractPricingMatrixTriggerHandlerTest
@ Version:        1.0
@ Author:         Mony Nou
@ Purpose:        Test class coverage for ContractPricingMatrixTriggerHandler
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.01.2025 / Mony Nou / Created the class.
*********************************************************************************************************************************/
@isTest
private class ContractPricingMatrixTriggerHandlerTest {
    
    @isTest
    static void testValidateVIPCustomCPM() {

        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',EBH_ContractPricingMatrix__c = true);

        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        
	    List<Account> legalEntty = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
        legalEntty[0].EBH_BillingCountry__c = 'US';
        update legalEntty;

        Date startDate = System.today();
        Date endDate = System.today().addDays(31); 
	                      
        List<Contract> contractsVIP = createContracts(1, 'VIP Contract', legalEntty[0].id, legalEntty[1].id, startDate, endDate);
        contractsVIP[0].Status = 'Draft';
        insert contractsVIP;
        
        RecordType vipPricingRT = EBH_TestDataFactory.getRecordTypeByName('EBH_Pricing__c','VIP_Pricing');
        Id vipPricingmatrixRT = EBH_TestDataFactory.getRecordTypeByName('EBH_ContractPricingMatrix__c','VIP_Custom').Id;
        EBH_ContractPricingMatrix__c cpm = new EBH_ContractPricingMatrix__c();
           cpm.EBH_CAP__c = 10;
           cpm.EBH_FVF__c = 20;
           cpm.RecordTypeId = vipPricingmatrixRT;
           cpm.EBH_SiteCountry__c = 'US';
           cpm.EBH_Site__c = 'US';
           insert cpm;
	
        EBH_Pricing__c vipPricing = new EBH_Pricing__c(
            EBH_ContractId__c = contractsVIP[0].Id,
            RecordtypeId = vipPricingRT.Id,
            EBH_ContractPricingMatrix__c = cpm.Id,
            EBH_Site__c = 'US', 
            EBH_GMVTarget__c = 8000000, 
            GMVThreshold0__c = 0, 
            GMVThreshold1__c = 1000000, 
            GMVThreshold2__c = 4000000, 
            GMVThreshold3__c = 10000000, 
            Tier_0_bps_Discount__c = 100, 
            Tier_1_bps_Discount__c = 200, 
            Tier_2_bps_Discount__c = 300, 
            Tier_3_bps_Discount__c = 400
        );
        insert vipPricing;

        //Create User
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		User standardUser;
		System.runAs(admin){
			Profile p = [select id from Profile where name='NA Standard User Base' limit 1];
            standardUser = new User(alias = 'tsUser', email='TestStardardUser@ebay.com',
                            emailencodingkey='UTF-8', lastname='TestStandardUser', firstname='TestStandardUser', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id,
                            timezonesidkey='America/Los_Angeles', username='TestStardarduser@salesforce.na', isActive = true);
            insert standardUser;

            List<PermissionSet> lstPS = [SELECT Id,Name FROM PermissionSet WHERE Name In ('Contract_Manager', 'eBay_Standard_User', 'US_CA_Standard_user')];
            List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
            
            for (PermissionSet ps : lstPS) {

                PermissionSetAssignment tmp = new PermissionSetAssignment();
                tmp.PermissionSetId = ps.Id;
                tmp.AssigneeId = standardUser.Id;
                    
                
                psa.add(tmp);
            }
            insert psa;

            byPass__c bp = new byPass__c(SetupOwnerId = standardUser.Id, ByPass_Validation__c=true);
            insert bp;

		}

        contractsVIP[0].Status = 'Voided';
        update contractsVIP;
        
        Test.startTest();
            
            try{
                System.runAs(standardUser){
                    cpm.EBH_CAP__c = 20;
                    update cpm;
                }
            }catch(Exception e){
                System.assert(e.getMessage().contains(System.Label.ErrorUpdateCPMRecordNotStageDraft));
            }
        
            
            
        Test.stopTest();

    }

    private static List<Contract> createContracts(Integer numRecords, String recordType, Id customerLegalEntity, Id ebayLegalEntity, Date startDate, Date endDate) {
        
        // Sophal / 02.09.2021 / US-0010295 copy from EBH_TestDataFactory.createContracts

        List<Contract> contracts = new List<Contract>();
        
        RecordType rt = Database.query(EBH_TestDataFactory.CONTRACTRECTYPQUERY);
        RecordType manaulconRt = EBH_TestDataFactory.getRecordTypeByName('Contact','EBH_MANUAL');
        Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = customerLegalEntity,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
        insert contact;
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            contracts.add(new Contract(RecordTypeId = rt.Id, 
                                       Name = 'Test Contract ' + iCounter, 
                                       accountId = customerLegalEntity, 
                                       EBH_eBayLegalEntity__c = ebayLegalEntity, Status='Draft'
                                       ,StartDate=startDate,EndDate=endDate, Surcharge__c = true,Business_Contact__c=contact.id));
        }
        return contracts;
    }
}