/*****************************************************************************************************************************
    @ Method:         NewPricingRequestControllerTest
    @ Author:         SRONG TIN
    @ Purpose:        US-0016732 - Enhance Pricing Guided flow with Feature Fee steps - Listing Agreement Pricing P1
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.02.2025 / SRONG TIN / Created Class
    *****************************************************************************************************************************/
@isTest
private class NewPricingRequestControllerTest {



    @isTest
    static void testGetContractCategories() {

        EBH_TestDataFactory.setUpCustomSettings();

        ActiveValidationRules__c bp = new ActiveValidationRules__c(SetupOwnerId = UserInfo.getUserId(), All_Validation_Rules_Deactivated__c = true);
        insert bp;

        byPass__c bp1 = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Contract',ByPass_Validation__c=true);
        insert bp1;

        Map<String, Account> mAccounts = EBH_TestDataFactory.setupAccountTriggerHandlerData();
        
        RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = mAccounts.get('le1').Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact;

        Contract contract = new Contract(RecordTypeId = ApexUtil.getRecordTypeByName('Contract','VIP_Contracts').Id, 
                                       Name = 'Test Contract 1', 
                                       accountId = mAccounts.get('le1').Id, 
                                       Status='Draft',
                                       StartDate = System.today(),
                                       EndDate = System.today() + 1,
                                       Surcharge__c = true,
                                       EBH_Site__c = 'UK',
                                       Business_Contact__c=contact.id);

        insert contract;

        

        List<EBH_ContractSeller__c> contractSellers = new List<EBH_ContractSeller__c>();
        EBH_ContractSeller__c contractSeller = new EBH_ContractSeller__c(
            EBH_ContractNumber__c = contract.Id,
            EBH_BusinessName__c = mAccounts.get('se1').Id
        );
        insert contractSeller;

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

        Id vipPricingRecordTypeId = Schema.SObjectType.EBH_Pricing__c.getRecordTypeInfosByDeveloperName().get('VIP_Pricing').getRecordTypeId();

        // Create the EBH_Pricing__c record
        EBH_Pricing__c vipPricing = new EBH_Pricing__c(
            RecordTypeId = vipPricingRecordTypeId,
            EBH_ContractPricingMatrix__c = pricingMatrix.Id,
            EBH_ContractId__c = contract.Id,
            EBH_Site__c = 'UK'
        );
        insert vipPricing;

        Contract_Category__c contractCategory1 = new Contract_Category__c(
            Category__c = category1.Id,
            Contract_Pricing_Matrix__c = pricingMatrix.Id,
            ContractPricing__c = vipPricing.Id,
            Contratc_Category_Type__c = '1'
        );
        insert contractCategory1;

        Contract_Category__c contractCategory2 = new Contract_Category__c(
            Category__c = category2.Id,
            Contract_Pricing_Matrix__c = pricingMatrix.Id,
            Contratc_Category_Type__c = '0'
        );
        insert contractCategory2;

        // Test the method
        Test.startTest();
        Map<String, Object> result = NewPricingRequestController.getContractCategories(
            pricingMatrix.Id,
            'UK',
            true,
            '',
            false,
            new List<String>{category1.Id},
            new List<String>{category2.Id}
        );
        Test.stopTest();

        // Assertions
        System.assertEquals('success', result.get('status'), 'Status should be success');
        System.assert(result.containsKey('ContractCategory'), 'ContractCategory should be present in the result');
        System.assert(result.containsKey('SelectedCategory'), 'SelectedCategory should be present in the result');
        System.assert(result.containsKey('AllCategories'), 'AllCategories should be present in the result');
        System.assert(result.containsKey('ccPricingRT'), 'ccPricingRT should be present in the result');

    }

	static testMethod void testPricingRequest() {

        Category_Tree__c cate = new Category_Tree__c();
        cate.Name = 'Test';
        cate.Site_Name__c = 'UK';
        cate.Site__c = '3';
        cate.Active__c = true;
        insert cate;
        
        Category_Tree__c cate2 = new Category_Tree__c();
        cate2.Name = 'Test2';
        cate2.Site_Name__c = 'US';
        cate2.Site__c = '0';
        cate2.Active__c = true;
        insert cate2;
        
        EBH_ContractPricingMatrix__c conMatrix = createContractPricingMatrix('UK','GBP');
        conMatrix.EBH_L2_Category__c = cate.Id;
        insert conMatrix;
        Test.startTest();
        List<EBH_ContractPricingMatrix__c> cpmList = NewPricingRequestController.getCategories('Test','UK',false);
        System.assertEquals(1,cpmList.size(),'1 record found');
        cpmList = NewPricingRequestController.getCategories('Test','UK',true);
        List<String> site = new List<String>();
        site.add('3');
        site.add('0');
        List<Category_Tree__c> catList = NewPricingRequestController.getCategoryTree(site,'',false,false,0, new List<String>());
        System.debug(catList);
        System.assertEquals(2,catList.size(),'2 record found');
        catList = NewPricingRequestController.getCategoryTree(site,'test',true,false,0, new List<String>());
        System.assertEquals(2,catList.size(),'2 record found');

        catList = NewPricingRequestController.getCategoryTree(site,'test',true,false,0, new List<String>{cate2.Id});

    }
    
    static EBH_ContractPricingMatrix__c createContractPricingMatrix(String Site,String isoCode ) {
        
         return new EBH_ContractPricingMatrix__c(
            EBH_CAP__c = 10,
            EBH_FVF__c = 20,
            EBH_ListingFormat__c = 'Auction',
            EBH_SiteCountry__c = Site,
            EBH_Site__c = Site,
            CurrencyIsoCode =    isoCode,
            Active__c = true     
       );
     }
}