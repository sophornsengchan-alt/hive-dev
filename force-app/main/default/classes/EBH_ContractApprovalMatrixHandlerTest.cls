/*****************************************************************************************************************************
@ Class:       EBH_ContractApprovalMatrixHandler
@ Author:      Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:     US-0008347 test class for EBH_ContractApprovalMatrixHandler
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  11.11.2021 / Mony Nou / Created the method.
@*****************************************************************************************************************************/
@IsTest 
private class EBH_ContractApprovalMatrixHandlerTest {
   
    @testSetup static void setUp() {
		//EBH_TestDataFactory.setUpCustomSettings();  
        EBH_ActiveTriggers__c cusettingTrigger = new EBH_ActiveTriggers__c();
        cusettingTrigger.Name = 'EBH Trigger Controller';
        cusettingTrigger.EBH_ContactTrigger__c = true;
        cusettingTrigger.EBH_ContractApprovalMatrixTrigger__c = true;
        insert cusettingTrigger; 
	}

    private static RecordType PricingRecordType = ApexUtil.getRecordTypeByName('EBH_Pricing__c','EBH_ListingPricing');
    
    static testMethod void testProfile_SA() {
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) {
            testupdateApprovers(); 
            testupdatePreApprovedTemplate();
        }        
    }

    public static void testupdateApprovers() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        
        List<User> users = EBH_TestDataFactory.createUsers(4, 'Standard User');
        
        insert users;
        
        EBH_ContractApprovalMatrix__c  matrixRecordDE = EBH_TestDataFactory.createContractApprovalMatrix ( 'DE', users[0].id, users[1].id ) ;
        EBH_ContractApprovalMatrix__c  matrixRecordFR = EBH_TestDataFactory.createContractApprovalMatrix ( 'FR', users[0].id, users[1].id ) ;
        EBH_ContractApprovalMatrix__c  matrixRecordIT = EBH_TestDataFactory.createContractApprovalMatrix ('IT', users[0].id, users[1].id ) ;
        EBH_ContractApprovalMatrix__c  matrixRecordES = EBH_TestDataFactory.createContractApprovalMatrix ( 'ES', users[0].id, users[1].id ) ;
        EBH_ContractApprovalMatrix__c  matrixRecordUK = EBH_TestDataFactory.createContractApprovalMatrix ( 'UK', users[0].id, users[1].id ) ;
        EBH_ContractApprovalMatrix__c  matrixRecordRest = EBH_TestDataFactory.createContractApprovalMatrix ( 'Rest of Europe', users[0].id, users[1].id ) ;
        insert new List<EBH_ContractApprovalMatrix__c>{matrixRecordDE,matrixRecordFR,matrixRecordIT,matrixRecordES,matrixRecordUK,matrixRecordRest};
        
        EBH_ContractApprovalHierarchy__c child1 = EBH_TestDataFactory.createContractApprovalHierarchy ( EBH_ConstantsUtility.HIERARCHY_CONTROLLING, users[2].id, 5000000.0);
        child1.EBH_ContractApprovalMatrix__c = matrixRecordDE.Id;
        EBH_ContractApprovalHierarchy__c child2 = EBH_TestDataFactory.createContractApprovalHierarchy ( EBH_ConstantsUtility.HIERARCHY_FINANCE, users[3].id, 5000000.0);
        child2.EBH_ContractApprovalMatrix__c = matrixRecordFR.Id;
        insert new List<EBH_ContractApprovalHierarchy__c>{child1,child2};
        
        Account acc1 = new Account(RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id, Name = 'Test Account 1',EBH_BillingCountry__c = 'DE');
        Account acc2 = new Account(RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id, Name = 'Test Account 2',EBH_BillingCountry__c = 'FR');
        Account acc3 = new Account(RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id, Name = 'Test Account 3',EBH_BillingCountry__c = 'IT');
        Account acc4 = new Account(RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id, Name = 'Test Account 4',EBH_BillingCountry__c = 'ES');
        Account acc5 = new Account(RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id, Name = 'Test Account 5',EBH_BillingCountry__c = 'UK');
        Account acc6 = new Account(RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id, Name = 'Test Account 6',EBH_BillingCountry__c = 'Rest of Europe');
        Account acc7 = new Account(RecordTypeId = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id, Name = 'Test Account 6',EBH_BillingCountry__c = 'Rest of Europe');
        insert new List<Account>{acc1,acc2,acc3,acc4,acc5,acc6,acc7};

        String rtCtrACPId = ApexUtil.getRecordTypeByName('Contract',EBH_ConstantsUtility.CONTRACT_ACPRECORDTYPE).Id;
        String rtCtManualId = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL').Id;
        List<Map<String,String>> listMapContractSetupData = new List<Map<String,String>>();
        listMapContractSetupData.add(new Map<String,String>{'rtCtrACPId'=>rtCtrACPId,'rtCtManualId'=>rtCtManualId,'customerLegalEntity'=>acc1.Id,'ebayLegalEntity'=>acc7.Id,'site'=>'DE'});
        listMapContractSetupData.add(new Map<String,String>{'rtCtrACPId'=>rtCtrACPId,'rtCtManualId'=>rtCtManualId,'customerLegalEntity'=>acc2.Id,'ebayLegalEntity'=>acc7.Id,'site'=>'FR'});
        listMapContractSetupData.add(new Map<String,String>{'rtCtrACPId'=>rtCtrACPId,'rtCtManualId'=>rtCtManualId,'customerLegalEntity'=>acc3.Id,'ebayLegalEntity'=>acc7.Id,'site'=>'IT'});
        listMapContractSetupData.add(new Map<String,String>{'rtCtrACPId'=>rtCtrACPId,'rtCtManualId'=>rtCtManualId,'customerLegalEntity'=>acc4.Id,'ebayLegalEntity'=>acc7.Id,'site'=>'ES'});
        listMapContractSetupData.add(new Map<String,String>{'rtCtrACPId'=>rtCtrACPId,'rtCtManualId'=>rtCtManualId,'customerLegalEntity'=>acc5.Id,'ebayLegalEntity'=>acc7.Id,'site'=>'UK'});
        listMapContractSetupData.add(new Map<String,String>{'rtCtrACPId'=>rtCtrACPId,'rtCtManualId'=>rtCtManualId,'customerLegalEntity'=>acc6.Id,'ebayLegalEntity'=>acc7.Id,'site'=>'NL'});

        createMultipleContract(listMapContractSetupData);
    }

    static void testupdatePreApprovedTemplate() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        
        RecordType rt = ApexUtil.getRecordTypeByName('Contract','EBH_ACP');
        RecordType leg = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
        
        Account legalEntities = new Account(Name='Test Acc', RecordTypeId=leg.Id);
        insert legalEntities;
        RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = legalEntities.Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact;
        Contract testData = new Contract(RecordTypeId = rt.Id, 
                                       Name = 'Test Contract ', 
                                       accountId = legalEntities.Id, 
                                       EBH_eBayLegalEntity__c = legalEntities.Id, Status='Draft',
                                       Surcharge__c = true,
                                       StartDate = System.today(), 
                                       EndDate = System.today().addDays(1),
                                       Business_Contact__c=contact.id,
                                       TargetType__c = 'Amount'
        );
        insert testData;    
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            testData.EBH_Site__c = EBH_ConstantsUtility.CONTRACT_SITE_DE;
            testData.EBH_Language__c = EBH_ConstantsUtility.CONTRACT_LANGUAGE_DE;
            
            
            /*Excecute test*/
            update testData; //on change of Site and Language, if it matches the rule defined in the custom settings, it will update Pre-Approved Template field on Contract              
            
            /*Validate test*/
            List<Contract> contracts = [SELECT EBH_PreApprovedTemplate__c
                           FROM Contract WHERE Id = : testdata.Id and  EBH_PreApprovedTemplate__c = true];
            
            
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/     
            testData.EBH_Site__c = EBH_ConstantsUtility.CONTRACT_SITE_IT;
            testData.EBH_Language__c = EBH_ConstantsUtility.CONTRACT_LANGUAGE_DE;        
            
            /*Excecute test*/
            update testData;
            /*Validate test*/
            contracts = [SELECT EBH_PreApprovedTemplate__c
                           FROM Contract WHERE Id = : testdata.Id and  EBH_PreApprovedTemplate__c = true];
            
            System.assertEquals( 0, contracts.size() );
            
            testData.EBH_Site__c = EBH_ConstantsUtility.CONTRACT_SITE_IT;
            testData.EBH_Language__c = EBH_ConstantsUtility.CONTRACT_LANGUAGE_DE;
            testData.EBH_PreApprovedTemplate__c = true;
           
            
            Database.update(testdata, false);
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            Test.stopTest();
    }

    private static List<Contract> createMultipleContract(List<Map<String,String>> listMapContractSetupData){
        // Sophal: 06/08/2021: US-0009896 
        List<Contact> listContact = new List<Contact>();
        List<Contract> listContract = new List<Contract>();
    	for(Map<String,String> mapData: listMapContractSetupData){

            String rtCtrACPId = mapData.get('rtCtrACPId');
            String rtCtManualId = mapData.get('rtCtManualId');
            String customerLegalEntity = mapData.get('customerLegalEntity');
            String ebayLegalEntity = mapData.get('ebayLegalEntity');
            String site = mapData.get('site');

            listContact.add(new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = customerLegalEntity,recordTypeId = rtCtManualId, EBH_DataOrigin__c='test'));
            listContract.add(new Contract(RecordTypeId = rtCtrACPId, Name = 'Test Contract', accountId = customerLegalEntity,EBH_eBayLegalEntity__c = ebayLegalEntity, Status='Draft', Surcharge__c = true, StartDate = System.today(), EndDate = System.today().addDays(1),EBH_Site__c=site, TargetType__c = 'Amount'));
        }
        insert listContact;
        Integer index = 0;
        for(Contact contact : listContact){
            listContract[index].Business_Contact__c = contact.Id;
            index++;
        }
        insert listContract;
        return listContract;
    }
}