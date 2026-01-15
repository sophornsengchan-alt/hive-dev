/*********************************************************************************************************************************
@ Class:          CohortActionControllerTest
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        US-0014345 - Cohort Activation Process Part 1
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  07.11.2023 / Sophal Noch / Created the class.
@               :  15.11.2023 / Sophal Noch / US-0014353 - Cohort Deactivation Process
@               :  11.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
@               :  11.12.2023 / Sophal Noch / US-0014363 - Ph 1 - Deactivate Sellers button
@               :  09.01.2024 / Sophal Noch / US-0014658 - Cohort Activation Flow failing
@               :  30.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
@               :  18.04.2024 / Sophal Noch / US-0015035 - We need to allow the Deactivation of the Pro-Trader Seller in part of subscribe request for any Status that is
@               :  14.05.2024 / Sophal Noch / US-0015200 - PT+ - Cohort Invite process should be application on for Pro-Trader
*********************************************************************************************************************************/
@isTest
private class CohortActionControllerTest {

    //private static BoB__c managedBob;
    //private static BOB_Seller__c managedBobSeller1;

    private static BoB__c lttmBob;
    private static BOB_Seller__c lttmBobSeller1;
    private static BOB_Seller__c lttmBobSeller2;
    private static BOB_Seller__c lttmBobSeller3;

    private static List<BOB_Seller__c> listLttmBobSeller;
    private static List<String> listLttmBsId;

    private static User currentUser;
    private static User anotherUser;

    private static List<Account> sellers;


    private static void setupData(){

        currentUser = [Select Id From User Where Id = : UserInfo.getUserId() And IsActive = true Limit 1];
        anotherUser = [Select Id From User Where Id !=: currentUser.Id And Profile.Name = 'System Administrator' And IsActive = true Limit 1];

        System.runAs(currentUser){ 
            // remove calendly
            currentUser.Calendly__CalendlyLink__c = null;
            update currentUser;
        }   

        System.runAs(anotherUser){ 
            // config calendly
            anotherUser.Calendly__CalendlyLink__c = 'ebay.com';
            update anotherUser;
        }   

        Account parentSeller = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller')[0];

        sellers = EBH_TestDataFactory.createAccounts(3, 'EBH_Seller');

        /*RecordType bobRecordTypeMgn = ApexUtil.getRecordTypeByName('BOB__c','Managed_Cohort');
        RecordType bobSellerRecordTypeMgn = ApexUtil.getRecordTypeByName('BoB_Seller__c','Managed');

        managedBob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Collectibles',RecordTypeId = bobRecordTypeMgn.Id, Account_Manager__c = currentUser.Id);
        insert managedBob;
        managedBobSeller1 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeMgn.Id ,BOB__c=managedBob.Id,Parent_Seller__c = parentSeller.Id, Seller__c=sellers[0].Id, Account_Manager__c = currentUser.Id, Status__c = 'Submitted');
        insert managedBobSeller1;

        managedBob.Status__c = 'BoB Inactive';
        update managedBob;*/

        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
    	RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');

        lttmBob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id, Managed_Type__c = 'Others Managed');
        insert lttmBob;

        Category_Tree__c ct0 = new Category_Tree__c(Name = 'l0',Active__c=true,Site__c='77');
     	insert ct0;
    	Category_Tree__c ct1 = new Category_Tree__c(Name = 'l1',Note_ID__c=ct0.Id,Active__c=true);
    	insert ct1;
		Category_Tree__c ct2 = new Category_Tree__c(Name = 'l2a',Note_ID__c = ct1.Id,Active__c=true);
		insert ct2;
		Category_Tree__c ct3 = new Category_Tree__c(Name = 'l3',Note_ID__c = ct2.Id,Active__c=true);
    	insert ct3;

        Map<String,Object> resultSave = CategoryTreeController.apexSaveCat(lttmBob.Id,new List<String>{ct3.Id});
        System.assertEquals('ok',resultSave.get('status'),'save success');


        lttmBobSeller1 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[0].Id, Account_Manager__c = anotherUser.Id);
        lttmBobSeller2 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[1].Id, Account_Manager__c = currentUser.Id);
        lttmBobSeller3 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[2].Id, Account_Manager__c = anotherUser.Id);
        listLttmBobSeller = new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2, lttmBobSeller3};
        insert listLttmBobSeller;
        listLttmBsId = new List<String>{lttmBobSeller1.Id, lttmBobSeller2.Id, lttmBobSeller3.Id};

        RecordType actionTemplateLTTM = ApexUtil.getRecordTypeByName('Action_Template__c','LTTM');
        Action_Template__c parentTemplate = new Action_Template__c(Name='parentTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Active__c=true);
        insert parentTemplate;

        Action_Template__c childTemplate = new Action_Template__c(Name='childTemplate',RecordTypeId=actionTemplateLTTM.Id,Country__c='DE',Parent_Action__c=parentTemplate.Id,Active__c=true);
        insert childTemplate;

        Action__c action1 = new Action__c(Name='Action1',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller1.Id);
        Action__c action2 = new Action__c(Name='Action2',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller2.Id);
        Action__c action3 = new Action__c(Name='Action3',Completed_Date__c = null,Action_Template__c=childTemplate.Id,LTTM_Seller__c=lttmBobSeller2.Id);
        insert new List<Action__c>{action1, action2, action3};
        
    }

    @isTest
    static void test_GetBobSellerToActivate(){

        setupData();

        /*managedBob.Status__c = 'BoB Active';
        update managedBob;*/

        Map<String, Object> mapResult = CohortActionController.getBobSellerId(lttmBob.Id, true);


        mapResult = CohortActionController.activateCohort(lttmBob.Id);
        System.assertEquals(null,  mapResult.get('error'));
        

        Test.startTest();

            mapResult = CohortActionController.getBobSellerToActivate(lttmBob.Id, null, false);
            System.assertNotEquals(null,  mapResult.get('listBsToActivate'));

            CohortActionController.activateCohortSeller(null, listLttmBsId, false);

            CohortActionController.runActivateCohortSellerBatch(lttmBob.Id, null);
            

        Test.stopTest();

        /*lttmBobSeller1 = [Select Id, Status__c, Conflict_Reason__c From BOB_Seller__c Where Id = :lttmBobSeller1.Id];
        System.assertNotEquals(null,lttmBobSeller1.Conflict_Reason__c); // suppose to have error
        System.assertEquals('Conflicted',lttmBobSeller1.Status__c);*/
        

        lttmBobSeller2 = [Select Id, Status__c, Conflict_Reason__c From BOB_Seller__c Where Id = :lttmBobSeller2.Id];   
        System.assertEquals(null,lttmBobSeller2.Conflict_Reason__c);  // suppose NOT to have error
        System.assertEquals('Draft',lttmBobSeller2.Status__c);
        

        lttmBobSeller3 = [Select Id, Status__c, Conflict_Reason__c From BOB_Seller__c Where Id = :lttmBobSeller3.Id];
        System.assertEquals(null,lttmBobSeller3.Conflict_Reason__c); // suppose NOT to have error
        System.assertEquals('Draft',lttmBobSeller3.Status__c);


    }

    @isTest
    static void test_GetProTraderBobSellerToActivate(){
        setupData();

        //managedBob.Status__c = 'BoB Active';
        lttmBob.Managed_Type__c = 'LTTM Managed';
        lttmBob.Managed_Segment__c = 'Pro-Trader Cat';  // 14.05.2024 / Sophal Noch / US-0015200
        lttmBob.Registration_Start_Date__c = Date.today();
        lttmBob.RegistrationCloseDate__c = Date.today().addDays(1);
       // update new List<BoB__c>{lttmBob, managedBob};
       update new List<BoB__c>{lttmBob};


       lttmBobSeller1.EBH_BOBSegment__c = 'Pro-Trader Cat';
       lttmBobSeller2.EBH_BOBSegment__c = 'Pro-Trader Cat';
       lttmBobSeller3.EBH_BOBSegment__c = 'Pro-Trader Cat';
       update new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2, lttmBobSeller3};

        Map<String, Object> mapResult = CohortActionController.getBobSellerId(lttmBob.Id, true);

        mapResult = CohortActionController.validateBeforeActivate(lttmBob.Id);

        mapResult = CohortActionController.activateCohort(lttmBob.Id);
        System.assertEquals(null,  mapResult.get('error'));

        Test.startTest();
            CohortActionController.activateCohortSeller(null, listLttmBsId, false);

            CohortActionController.runActivateCohortSellerBatch(null, listLttmBsId);

        Test.stopTest();


        /*lttmBobSeller1 = [Select Id, Status__c, Conflict_Reason__c From BOB_Seller__c Where Id = :lttmBobSeller1.Id];
        System.assertNotEquals(null,lttmBobSeller1.Conflict_Reason__c); // suppose to have error
        System.assertEquals('Conflicted',lttmBobSeller1.Status__c);*/
        

        lttmBobSeller2 = [Select Id, Status__c, Conflict_Reason__c From BOB_Seller__c Where Id = :lttmBobSeller2.Id];   
        System.assertNotEquals(null,lttmBobSeller2.Conflict_Reason__c); // suppose to have error

        System.assertEquals('Conflicted',lttmBobSeller2.Status__c);
        
        lttmBobSeller3 = [Select Id, Status__c, Conflict_Reason__c From BOB_Seller__c Where Id = :lttmBobSeller3.Id];
        System.assertEquals(null,lttmBobSeller3.Conflict_Reason__c); // suppose NOT to have error
        System.assertEquals('Invited',lttmBobSeller3.Status__c);

    }

    @isTest
    static void test_GetBobSellerToDeactivate(){

        // 15.11.2023 / Sophal Noch / US-0014353

        setupData();

        lttmBob.Status__c = 'BoB Active';
        update lttmBob;

        RecordType leg = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
        
        Account legalEntities = new Account(Name='Test Acc', RecordTypeId=leg.Id);
        insert legalEntities;
        RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');

	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = legalEntities.Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact;


        sellers[0].ParentId = legalEntities.Id;
        sellers[0].EBH_BOBManaged__c = true;

        sellers[1].ParentId = legalEntities.Id;
        sellers[1].EBH_BOBManaged__c = true;

        sellers[2].ParentId = legalEntities.Id;
        sellers[2].EBH_BOBManaged__c = true;

        update sellers;

        RecordType contractListRTId = ApexUtil.getRecordTypeByName('Contract', 'EBH_ListingAgreement');
        Contract contract = new Contract(
                                       Name = 'Test Contract ', 
                                       accountId = legalEntities.Id, 
                                       EBH_eBayLegalEntity__c = legalEntities.Id, 
                                       Status='Draft',
                                       Surcharge__c = true,
                                       StartDate = System.today(), 
                                       EndDate = System.today().addDays(1),
                                       Business_Contact__c=contact.id,
                                       RecordTypeId = contractListRTId.Id,
                                       PricingVersion__c = 'P1.0'
                                    
        );

        insert contract;

        EBH_ContractSeller__c contractSeller0 = new EBH_ContractSeller__c(EBH_ContractNumber__c = contract.Id, EBH_BusinessName__c = sellers[0].Id);
        EBH_ContractSeller__c contractSeller1 = new EBH_ContractSeller__c(EBH_ContractNumber__c = contract.Id, EBH_BusinessName__c = sellers[1].Id);
        EBH_ContractSeller__c contractSeller2 = new EBH_ContractSeller__c(EBH_ContractNumber__c = contract.Id, EBH_BusinessName__c = sellers[2].Id);
        insert new List<EBH_ContractSeller__c>{ contractSeller0, contractSeller1, contractSeller2};

        EBH_ContractPricingMatrix__c contractPricingMatrix = EBH_TestDataFactory.createContractPricingMatrix('DE');
        RecordType PricingRecordType = ApexUtil.getRecordTypeByName('EBH_Pricing__c','EBH_ListingPricing');
        EBH_Pricing__c pricing = new EBH_Pricing__c(EBH_ContractId__c=contract.Id,
            EBH_Site__c='DE',
            EBH_ContractPricingMatrix__c = contractPricingMatrix.Id,
            EBH_Projected12MGMV__c = 11,
            EBH_ASP__c =11,
            RecordTypeId = PricingRecordType.Id
        );
        insert pricing;

        ActiveValidationRules__c bp = new ActiveValidationRules__c(SetupOwnerId = UserInfo.getUserId(), All_Validation_Rules_Deactivated__c = true);
        insert bp;

        //contract.Status = 'Executed';
        contract.Status = 'Sent for Finance Post-check';
        update contract;
        contract.Status = 'Executed';
        update contract;

        bp.All_Validation_Rules_Deactivated__c = false;
        update bp;

        RecordType subReqRTAM = ApexUtil.getRecordTypeByName('Subscription_Request__c', 'Account_Manager');
      
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller', Subscription_Request_Trigger__c = true);

        Subscription_Request__c subReq = new Subscription_Request__c(
            Request_Date__c =  Date.today(),          
            Status__c = 'Subscribed',
            Requestor__c = contact.Id ,
            Seller__c = sellers[0].Id,
            CurrencyIsoCode = 'EUR',
            RecordTypeId  = subReqRTAM.Id,
            Opt_In_Effective_Date__c = Date.today()
        );
        insert subReq;


        lttmBobSeller1 = [Select Id, Status__c From BOB_Seller__c Where Id = :lttmBobSeller1.Id];
        lttmBobSeller1.Status__c = 'Draft';

        lttmBobSeller2 = [Select Id, Status__c From BOB_Seller__c Where Id = :lttmBobSeller2.Id];   
        lttmBobSeller2.Status__c = 'Draft';
        
        lttmBobSeller3 = [Select Id,Status__c From BOB_Seller__c Where Id = :lttmBobSeller3.Id];
        lttmBobSeller3.Status__c = 'Draft';

        update new List<BOB_Seller__c>{lttmBobSeller1, lttmBobSeller2, lttmBobSeller3};

        Test.startTest();

            Map<String, Object> mapResult = CohortActionController.getBobSellerId(lttmBob.Id, true);

            mapResult = CohortActionController.getBobSellerToDeactivate(lttmBob.Id, null, false);
            System.assertNotEquals(null,  mapResult.get('listBsToDeactivate'));
            System.assertEquals(null,  mapResult.get('error'));

            CohortActionController.deactivateCohort(null, listLttmBsId);
            
            CohortActionController.runDeactivateCohortSellerBatch(lttmBob.Id, null);

        Test.stopTest();

        lttmBobSeller1 = [Select Id, Conflict_Reason__c From BOB_Seller__c Where Id = :lttmBobSeller1.Id];
        System.assertNotEquals(null,lttmBobSeller1.Conflict_Reason__c);
        
        lttmBobSeller2 = [Select Id, Conflict_Reason__c From BOB_Seller__c Where Id = :lttmBobSeller2.Id];   
        System.assertNotEquals(null,lttmBobSeller2.Conflict_Reason__c);  // 
        
        lttmBobSeller3 = [Select Id,Conflict_Reason__c From BOB_Seller__c Where Id = :lttmBobSeller3.Id];
        System.assertNotEquals(null,lttmBobSeller3.Conflict_Reason__c); //

    }

    @isTest
    static void test_GetBobSellerToDeactivateNoConflict(){

        setupData();

        lttmBob.Status__c = 'BoB Active';
        update lttmBob;

        Test.startTest();

            Map<String, Object> mapResult = CohortActionController.getBobSellerId(lttmBob.Id, true);

            mapResult = CohortActionController.getBobSellerToDeactivate(lttmBob.Id, null, false);
            System.assertNotEquals(null,  mapResult.get('listBsToDeactivate'));
            System.assertEquals(null,  mapResult.get('error'));

        
            CohortActionController.deactivateCohort(null, listLttmBsId);

            CohortActionController.runDeactivateCohortSellerBatch(null, listLttmBsId);


            mapResult = CohortActionController.deactivateCohortWhenNoCs(lttmBob.Id);

        Test.stopTest();

        lttmBobSeller1 = [Select Id, Status__c From BOB_Seller__c Where Id = :lttmBobSeller1.Id];
        System.assertEquals('Inactive',lttmBobSeller1.Status__c);
        
        lttmBobSeller2 = [Select Id, Status__c From BOB_Seller__c Where Id = :lttmBobSeller2.Id];   
        System.assertEquals('Inactive',lttmBobSeller2.Status__c);  // 
        
        lttmBobSeller3 = [Select Id,Status__c From BOB_Seller__c Where Id = :lttmBobSeller3.Id];
        System.assertEquals('Inactive',lttmBobSeller3.Status__c); //

        // 30.01.2024 / Sophal Noch / US-0014277 : test delete cohort seller
        mapResult = CohortActionController.getBobSellerToDeactivate(null, listLttmBsId, true);
        System.assertNotEquals(null,  mapResult.get('listBsToDeactivate'));
        CohortActionController.deleteCohortSeller(listLttmBsId);
        System.assertEquals(0,  [Select Id From BOB_Seller__c WHERE Id IN :listLttmBsId].size());
    }
}