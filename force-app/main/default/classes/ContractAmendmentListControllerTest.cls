/*****************************************************************************************************************************
    @ Method:         ContractAmendmentListControllerTest
    @ Author:         SRONG TIN
    @ Purpose:        US-0033057
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.07.2025 / SRONG TIN / Created Class
    *****************************************************************************************************************************/
@isTest
private class  ContractAmendmentListControllerTest {
    static testMethod void testPricing() {

        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType contractRecordType = ApexUtil.getRecordTypeByName('Contract','EBH_ACP');
        
        RecordType legalEntityRecordType = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
			List<Account> legalEntity = new List<Account>();
			for(Integer i = 0; i < 2; i++){
				
				Account acc = new Account(
						Name = 'Seller_'+(i+1),
						EBH_RevRollup__c = 'DE',
						EBH_PrimarySite__c= 'DE',
						RecordTypeId = legalEntityRecordType.Id,
						SP_Coupons__c = 'Full Access',
						EBH_BillingAddress__c='PP',
						EBH_BillingCity__c='pp',
						EBH_BillingCountry__c='DE',
						EBH_CompanyName__c='test',
						EBH_BillingPostalCode__c='12102'
				);

				legalEntity.add(acc);
			}
			insert legalEntity;

        RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = legalEntity[0].Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
        insert contact;

        Date startDate = System.today();
        Date endDate = System.today().addDays(31);

        Contract contr = new Contract(RecordTypeId = contractRecordType.Id, 
                                       Name = 'Test Contract 1', 
                                       accountId = legalEntity[0].id, 
                                       EBH_eBayLegalEntity__c = legalEntity[1].id,
                                       EBH_Site__c = 'DE',
                                       TargetType__c = 'Amount',
                                       Status = 'Draft',
                                       StartDate = startDate,
                                       EndDate = endDate,
                                       Surcharge__c = true,
                                       Business_Contact__c = contact.id);

        insert contr;
        Contract contr2 = new Contract(RecordTypeId = contractRecordType.Id, 
                                       Name = 'Test Contract 1', 
                                       accountId = legalEntity[0].id, 
                                       EBH_eBayLegalEntity__c = legalEntity[1].id,
                                       EBH_ContractAmendment__c = 'Amendment',
                                       TargetType__c = 'Amount',
                                       EBH_LinkedContract__c = contr.Id,
                                       EBH_Site__c = 'DE',
                                       Status = 'Draft',
                                       StartDate = startDate,
                                       EndDate = endDate,
                                       Surcharge__c = true,
                                       Business_Contact__c = contact.id);

        insert contr2;

        RecordType feeTypeRecordType = ApexUtil.getRecordTypeByName('FeeType__c','Primary');
        FeeType__c feeType = new FeeType__c(RecordTypeId = feeTypeRecordType.Id,
                                        PrimarySite__c = 'DE',
                                        RelatedContract__c = contr2.Id,
                                        TypeofFee__c = 'EBAY_TOP_RATED_SELLER_DISCOUNT'

        );

        insert feeType;

        List<EBH_Pricing__c> pricings1 = createPricing (1,'EBH_ACPTargets',contr2.Id, 15, 900.00, 800.00, 2000000, 800, 'DE');
        pricings1[0].CurrencyIsoCode = 'EUR';
        insert pricings1;
        
        List<EBH_Pricing__c> pricings2 = createPricing (1,'EBH_ACPTargets',contr2.Id, 15, 900.00, 800.00, 2000000, 800, 'DE');
        pricings2[0].CurrencyIsoCode = 'EUR';
        insert pricings2;
        
        FeeType__c feeType2 = new FeeType__c(RecordTypeId = feeTypeRecordType.Id,
                                        PrimarySite__c = 'DE',
                                        RelatedPricing__c = pricings2[0].Id,
                                        RelatedContract__c = contr2.Id,
                                        TypeofFee__c = 'EBAY_TOP_RATED_SELLER_DISCOUNT'

        );
        
        FeeType__c feeType3 = new FeeType__c(RecordTypeId = feeTypeRecordType.Id,
                                        PrimarySite__c = 'DE',
                                        RelatedPricing__c = pricings2[0].Id,
                                        RelatedContract__c = contr2.Id,
                                        TypeofFee__c = 'EBAY_TOP_RATED_SELLER_DISCOUNT'

        );
        insert new List<FeeType__c>{feeType2, feeType3};


        Map<String, Object> data = ContractAmendmentListController.getContractData(contr.Id);
        if (data != null && data.containsKey('feeTypeList') && data.get('feeTypeList') != null) {
            List<FeeType__c> feeTypeList = (List<FeeType__c>) data.get('feeTypeList');
            System.assertEquals(1, feeTypeList.size(), '1 record found');
        }



    }

    static List<EBH_Pricing__c> createPricing(Integer numRecords, String recordType, Id contractID, Decimal EBH_FVFDiscount,Decimal EBH_FVFCap, Decimal EBH_ASP, Decimal EBH_Projected12MGMV, Decimal EBH_DefaultFVFCap, String EBH_Site) {
        
        List<EBH_Pricing__c> pricingRecords = new List<EBH_Pricing__c>();
        RecordType rt = ApexUtil.getRecordTypeByName('EBH_Pricing__c',recordType);
        
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
    
}