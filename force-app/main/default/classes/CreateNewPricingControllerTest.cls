/*********************************************************************************************************************************
@ Class:          CreateNewPricingControllerTest
@ Version:        1.0
@ Author:         LoumAng SENG (loumang.seng@gaea-sys.com)
@ Purpose:        US-0008204 - [Contracts] New Custom Button "Create New Pricing" in Contracts Detail Page
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.03.2021 / LoumAng SENG / Created the class.
				  
*********************************************************************************************************************************/
@isTest
private class CreateNewPricingControllerTest {

    @isTest
    static void testdoCreatePricing(){
        EBH_TestDataFactory.setUpCustomSettings();
        List<Account> legalEntities = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
        RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = legalEntities[0].Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact;
        RecordType listingRT = ApexUtil.getRecordTypeByName('Contract',EBH_ConstantsUtility.CONTRACT_LISTINGRECORDTYPE);
        Contract ct1  = new Contract(Name = 'Test contract P1',RecordTypeId = listingRT.Id, accountId = legalEntities[0].Id,EBH_eBayLegalEntity__c = legalEntities[1].Id, Status='Draft',VolumeDiscounts__c=0.25, StartDate = System.today(), EndDate = System.today() + 1,Surcharge__c = true,Business_Contact__c=contact.id);
        Contract ct2  = new Contract(Name = 'Test contract P2',RecordTypeId = listingRT.Id, accountId = legalEntities[0].Id,EBH_eBayLegalEntity__c = legalEntities[1].Id, Status='Draft', VolumeDiscounts__c=0.25,StartDate = System.today(), EndDate = System.today() + 1,Surcharge__c = true,Business_Contact__c=contact.id);

        insert new List<Contract>{ct1,ct2};

        Test.startTest();
            ct1.PricingVersion__c = 'P1.0';
            ct2.PricingVersion__c = 'P2.0';
            update new List<Contract>{ct1,ct2};
         	Map<String, Object> mResult1 = CreateNewPricingController.doCreatePricing(ct1.Id);
        	System.assert(ApexUtil.getRecordTypeByName('EBH_Pricing__c','EBH_ListingPricing').Id ==  mResult1.get('recordTypeId'), mResult1.get('recordTypeId'));
            Map<String, Object> mResult2 = CreateNewPricingController.doCreatePricing(ct2.Id);
            System.assert(ApexUtil.getRecordTypeByName('EBH_Pricing__c','Listing_Pricing_P2_0').Id ==  mResult2.get('recordTypeId'), mResult2.get('recordTypeId'));
        
        Test.stopTest();
    }

}