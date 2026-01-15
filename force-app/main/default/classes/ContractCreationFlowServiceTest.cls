@isTest
private class ContractCreationFlowServiceTest {

    private static final String CONTRACT_LISTINGRECORDTYPE = 'EBH_ListingAgreement';
    
    @testSetup
    static void setup(){

        EBH_TestDataFactory.setUpCustomSettings();

        ActiveValidationRules__c bp = new ActiveValidationRules__c(SetupOwnerId = UserInfo.getUserId(), All_Validation_Rules_Deactivated__c = true);
        insert bp;

        byPass__c bp1 = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Contract',ByPass_Validation__c=true);
        insert bp1;

        Map<String, Account> mAccounts = EBH_TestDataFactory.setupAccountTriggerHandlerData();
        
        RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = mAccounts.get('le1').Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact;

        Contract contract = new Contract(RecordTypeId = ApexUtil.getRecordTypeByName('Contract',CONTRACT_LISTINGRECORDTYPE).Id, 
                                       Name = 'Test Contract 1', 
                                       accountId = mAccounts.get('le1').Id, 
                                       Status='Draft',
                                       StartDate = System.today(),
                                       EndDate = System.today() + 1,
                                       Surcharge__c = true,
                                       EBH_FinanceAgreesinPrincipal__c = true,
                                       Business_Contact__c=contact.id);

        insert contract;

        

        List<EBH_ContractSeller__c> contractSellers = new List<EBH_ContractSeller__c>();
        EBH_ContractSeller__c contractSeller = new EBH_ContractSeller__c(
            EBH_ContractNumber__c = contract.Id,
            EBH_BusinessName__c = mAccounts.get('se1').Id
        );
        insert contractSeller;

    }

    @isTest 
    static void test_queryExecutedContracts () {

        Test.startTest();

            EBH_ContractSeller__c contractSeller = [Select EBH_ContractNumber__c, EBH_ContractNumber__r.Status, EBH_BusinessName__c From EBH_ContractSeller__c LIMIT 1];
            
            Contract contract = new Contract(Id=contractSeller.EBH_ContractNumber__c, Status = 'Executed');
            update contract;

            List<List<String>> sellerRecords = new List<List<String>>();
            sellerRecords.add(new List<String>{contractSeller.EBH_BusinessName__c});
            List<ContractCreationFlowService.Result> result = ContractCreationFlowService.queryExecutedContracts(sellerRecords);

            System.assert( !result.isEmpty(), 'There should be result return.');

        Test.stopTest();

    }

}