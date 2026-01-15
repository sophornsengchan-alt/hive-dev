/*********************************************************************************************************************************
@ Class:          EBH_PricingTriggerHandlerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_PricingTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.05.2017 / JOY MONDOL / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_PricingTriggerHandlerTest {
    @testSetup static void setup(){
        EBH_TestDataFactory.setUpCustomSettings();
    }
    /*****************************************************************************************************************************
@ Method:         testProfile_SA
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Profile testing for System Administrator
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
*****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testUpdateCustomRollUp(); }        
    }
    
    /*****************************************************************************************************************************
@ Method:         testProfile_SU
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Profile testing for Standard User
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
*****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testUpdateCustomRollUp(); }
    }
    
    /*****************************************************************************************************************************
@ Method:         testUpdateCustomRollUp
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        TEST CASE (*) System should be able to rollup the following fields in sellers to its legal entity 
(which is a one to many relationship of one level of depth) 
on insert and update and reparenting:
- GMV
- Revenue 
- Sold Items
COVERAGES (*) updateCustomRollUp(): Updates custom roll ups on legal entity from child sellers 
|___hasRollupChanged(): Checks field change in seller
|___hasParentChanged(): Checks parent change in seller
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
*****************************************************************************************************************************/
    static testMethod void testUpdateCustomRollUp() {
        
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        //EBH_TestDataFactory.setUpCustomSettings();     
        Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData();     
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/
        createData();
        Test.startTest();
        /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
        /*Modify data for test*/             
        testDataMap.get('se1').EBH_SoldItems__c = 11;
        testDataMap.get('se1').EBH_GMVLast12Months__c = 22;
        testDataMap.get('se1').EBH_RevenueLast12Months__c = 33;
        
        testDataMap.get('se2').EBH_SoldItems__c = 44;
        testDataMap.get('se2').EBH_GMVLast12Months__c = 55;
        testDataMap.get('se2').EBH_RevenueLast12Months__c = 66;
        
        testDataMap.get('se3').EBH_SoldItems__c = 77;
        testDataMap.get('se3').EBH_GMVLast12Months__c = 88;
        testDataMap.get('se3').EBH_RevenueLast12Months__c = 99;
        
        testDataMap.get('se7').ParentId = testDataMap.get('le1').Id;
        
        /*Excecute test*/
        insert new Account(Name = 'se8', ParentId = testDataMap.get('le1').Id, EBH_SoldItems__c = 100); //on insert
        update testDataMap.values(); //on update + reparenting               
        
        /*Validate test*/
        Account le1 = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
                       FROM Account WHERE Id =: testDataMap.get('le1').Id][0];
        Account le2 = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
                       FROM Account WHERE Id =: testDataMap.get('le2').Id][0];
        Account le3 = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
                       FROM Account WHERE Id =: testDataMap.get('le3').Id][0];
        Account le4 = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
                       FROM Account WHERE Id =: testDataMap.get('le4').Id][0];
        /*System.assertEquals(200, le1.EBH_SoldItems__c);
        System.assertEquals(0, le1.EBH_GMVLast12Months__c);
        System.assertEquals(0, le1.EBH_RevenueLast12Months__c);*/
        System.assertEquals(332, le1.EBH_SoldItems__c);
        System.assertEquals(165, le1.EBH_GMVLast12Months__c);
        System.assertEquals(198, le1.EBH_RevenueLast12Months__c);
        

        /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
        
        /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
        /*Modify data for test*/             
        testDataMap.get('le3').EBH_SoldItems__c = 9999;
        
        /*Excecute test*/
        update testDataMap.values(); //change in legal entity should not roll up
        
        /*Validate test*/
        le2 = [SELECT EBH_SoldItems__c FROM Account WHERE Id =: testDataMap.get('le2').Id][0];
        
        /*System.assertEquals(null, le2.EBH_SoldItems__c);
        
        System.assertEquals(null, le3.EBH_SoldItems__c);
        System.assertEquals(null, le3.EBH_GMVLast12Months__c);
        System.assertEquals(null, le3.EBH_RevenueLast12Months__c);
        
        System.assertEquals(null, le4.EBH_SoldItems__c);*/
        /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
        
        /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
        /*Modify data for test*/             
        testDataMap.get('se1').EBH_RevenueLast12Months__c = 9999.9;
        
        /*Excecute test*/
        update testDataMap.values(); //change in legal entity should not roll up
        
        /*Validate test*/
        System.assertEquals(0, [SELECT EBH_MethodName__c FROM EBH_ApexLog__c 
                                WHERE EBH_MethodName__c = 'updateCustomRollUp'].size());
        /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
    static testMethod void testUpdateCustomRollUp2(){
        //EBH_TestDataFactory.setUpCustomSettings();     
        createData();
        /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
        /*Modify data for test*/             
        //contracts[0].EBH_RebateTierrebate__c = 200000.09;
        //contracts[0].EBH_ContractExposure__c = Decimal.valueof('abc');
        /*Excecute test*/
        //update testDataList[0]; //change in legal entity should not roll up
        //update contracts[0]; //change in legal entity should not roll up
        /*Validate test*/
        
        List<Account> legalEntty = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
        
        List<Contract> contractslst  = EBH_TestDataFactory.createContracts (2, 'Listing Agreement', 
                                                                            legalEntty[0].id, legalEntty[1].id );
        contractslst[0].PricingVersion__c = 'P1.0';
        update contractslst;

        List<EBH_Pricing__c> pricingslst = EBH_TestDataFactory.createPricing (2, 'EBH_ListingPricing', 
                                                                              contractslst[0].id, 15, 900.00, 800.00, 2000000, 800, 'UK');
        Test.startTest();  
        contractslst = EBH_TestDataFactory.createContracts (2, 'Revenue Share', 
                                                            legalEntty[0].id, legalEntty[1].id );                                 
        pricingslst = EBH_TestDataFactory.createPricing (2, 'EBH_RevenueShareTargets', 
                                                         contractslst[0].id, 15, 900.00, 800.00, 2000000, 800, 'UK');   
        System.assertEquals(0, [SELECT EBH_MethodName__c FROM EBH_ApexLog__c 
                                WHERE EBH_MethodName__c = 'updateCustomRollUp'].size());
        /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        
        Test.stopTest();
    }

	static testMethod void testUpdateCustomRollUp1() {
    
    /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
    //EBH_TestDataFactory.setUpCustomSettings();     
    // List<EBH_Pricing__c> testDataList = EBH_TestDataFactory.setUpPricingTriggerHandlerData();     
    /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/
    //testDataList[0].EBH_Projected12MGMV__c = 200000;
    //  update testDataList[0];
    
    /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -------------*/
    List<Account> legalEntty = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
    createData();
    
    List<Contract> contractslst = EBH_TestDataFactory.createContracts (10, 'ACP', 
                                                                       legalEntty[0].id, legalEntty[1].id );
    
    List<EBH_Pricing__c> pricingslst = EBH_TestDataFactory.createPricing (10, 'EBH_ACPTargets', 
                                                                          contractslst[0].id, 15, 900.00, 800.00, 2000000, 800, 'UK');
    Test.startTest();  
    try{
        pricingslst[0].EBH_contractPricingMatrix__c = EBH_TestDataFactory.createContractPricingMatrix('UK').ID;
        update pricingslst[0];}
    catch(Exception e){
    }
    System.assertEquals(1, [SELECT Id,Name FROM Account WHERE Id=:legalEntty[0].id].size());
    System.assertEquals(1, [SELECT Id,Name FROM Contract WHERE Id=:contractslst[0].id].size()); 
    System.assertEquals(1, [SELECT Id,Name FROM EBH_Pricing__c WHERE Id=:pricingslst[0].id].size());                                        
    /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
    
    /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/    
    //    System.assertEquals('Test Account 0', [SELECT Id,Name FROM Account WHERE Id=:legalEntty[0].id].Name);
    System.assertEquals('Test Contract 0', [SELECT Id,Name FROM Contract WHERE Id=:contractslst[0].id].Name); 
    /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -----------*/
    Test.stopTest();
}

    /*****************************************************************************************************************************
	@ Method:         testContractValue_ExposureCalFVF
	@ Version:        1.0
	@ Author:         Sovantheany Dim
	@ Purpose:        US-0033097 - eBay Live: Feedback Enhancements
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 24.09.2025 / Sovantheany Dim / Created the test Method.
	*****************************************************************************************************************************/
    static testMethod void testContractValue_ExposureCalFVF() {
	    
	    EBH_TestDataFactory.setupContractCustomSettingFee();   
        createData();
	    List<Account> legalEntty = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
        Date startDate = System.today();
        Date endDate = System.today().addDays(31);
        List<Contract> contractsFVF = createContracts(1, 'FVF Discount Contract', legalEntty[0].id, legalEntty[1].id, startDate, endDate);
        insert contractsFVF;

		List<EBH_Pricing__c> pricingsFVF = EBH_TestDataFactory.createPricing (2, 'FVF_Discount_Pricing', contractsFVF[0].id, 15, 900.00, 800.00, 2000000, 800, 'US');
        pricingsFVF[0].FVFBaseRate504__c = 3;
        update pricingsFVF;

        Test.startTest();
	    contractsFVF[0].EBH_Site__c = 'US';
        contractsFVF[0].GMVTarget__c = 10000;
        update contractsFVF;

        List<Contract> listContractResultFVF = [Select recordtype.Name,Id,EBH_ContractValue__c,EBH_ContractExposure__c from Contract WHERE Id=:contractsFVF[0].Id];
        System.assertEquals(1100, listContractResultFVF[0].EBH_ContractExposure__c,'[(13%−Base Rate)×GMV Target]×1.1');
	    
	    Test.stopTest();
	}

	/*****************************************************************************************************************************
	@ Method:         testContractValue_ExposureCal
	@ Version:        1.0
	@ Author:         Vadhanak Voun
	@ Purpose:        test for: EPH-5479 Additional bolt-ons for Listing and ACP
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 26.04.2018 / Vadhanak Voun / Created the test Method.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  02.09.2021 / Sophal Noch / US-0010295 Modified the method.
	*****************************************************************************************************************************/
	static testMethod void testContractValue_ExposureCal() {
	    
	    EBH_TestDataFactory.setupContractCustomSettingFee();
        
	    //EBH_TestDataFactory.setUpCustomSettings();     
        createData();
	    List<Account> legalEntty = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');

        // Sophal / 02.09.2021 / US-0010295 : disable calling method below because it can not set startDate and endDate. 
        //                                    uncertain startDate and endDate can give unexpected Contract.EBH_ContractValue__c value
        // List<Contract> contractsACP = EBH_TestDataFactory.createContracts (1, 'ACP', legalEntty[0].id, legalEntty[1].id );

        // Sophal / 02.09.2021 / US-0010295 : make sure number of days between start date and end date are always same every time this test method run
        //                                    so EBH_PricingTriggerHandler.calDatePeriod can return unchanged value.
        Date startDate = System.today();
        Date endDate = System.today().addDays(31);
        // Sophal / 02.09.2021 / US-0010295 calling new method below because we can set startDate and endDate.
        List<Contract> contractsACP = createContracts(1, 'ACP', legalEntty[0].id, legalEntty[1].id, startDate, endDate);
        insert contractsACP;

		List<EBH_Pricing__c> pricingsACP = EBH_TestDataFactory.createPricing (2, 'EBH_ACPTargets', contractsACP[0].id, 15, 900.00, 800.00, 2000000, 800, 'DE');
        pricingsACP[0].EBH_GMVTarget__c = 10000;
        update pricingsACP;

        Test.startTest();
	    contractsACP[0].EBH_Site__c = 'DE';
        contractsACP[0].AM_Bolt_on__c = 'Standard Price';
        contractsACP[0].VolumeBasedDiscount__c=true;
        contractsACP[0].EBH_AverageTakeRate__c=10;
        contractsACP[0].EBH_RebateTierrebate__c =10;
        contractsACP[0].EBH_StoreSubscription__c = 'Basic'; 
        contractsACP[0].EBH_MainVertical__c = 'Media';
        update contractsACP;
        
        List<Contract> listContractResultACP = [Select recordtype.Name,Id,EBH_ContractValue__c,EBH_ContractExposure__c,EBH_MainVertical__c from Contract WHERE Id=:contractsACP[0].Id];
	    System.debug('listContractResultACP::'+listContractResultACP);
        System.assertEquals(0.86, listContractResultACP[0].EBH_ContractValue__c.setScale(2),' calc from table in custom setting'); 
	    System.assertEquals(0.00, listContractResultACP[0].EBH_ContractExposure__c.setScale(2),' calc from table in custom setting');
	    
	    Test.stopTest();
	}

    static testMethod void testContractValue_ExposureCalVIP() {
	    
	    EBH_TestDataFactory.setupContractCustomSettingFee();
        
	    //EBH_TestDataFactory.setUpCustomSettings();     
        createData();
	    List<Account> legalEntty = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');

        Date startDate = System.today();
        Date endDate = System.today().addDays(31);
	                      
        List<Contract> contractsVIP = createContracts(1, 'VIP Contract', legalEntty[0].id, legalEntty[1].id, startDate, endDate);
        insert contractsVIP;

        RecordType vipPricingRT = EBH_TestDataFactory.getRecordTypeByName('EBH_Pricing__c','VIP_Pricing');

        EBH_Pricing__c vipPricing = new EBH_Pricing__c(
            EBH_ContractId__c = contractsVIP[0].Id,
            RecordtypeId = vipPricingRT.Id, 
            EBH_Site__c = 'US', 
            EBH_GMVTarget__c = 8000000, 
            GMVThreshold0__c = 0, 
            GMVThreshold1__c = 2000000, 
            GMVThreshold2__c = 3000000, 
            GMVThreshold3__c = 4000000,
            GMVThreshold4__c = 5000000, 
            GMVThreshold5__c = 6000000,  
            Tier_0_bps_Discount__c = 100, 
            Tier_1_bps_Discount__c = 200, 
            Tier_2_bps_Discount__c = 300, 
            Tier_3_bps_Discount__c = 400,
            Tier_4_bps_Discount__c = 500,
            Tier_5_bps_Discount__c = 600
        );
        insert vipPricing;

        Test.startTest();

        contractsVIP[0].Status = 'Draft';
        contractsVIP[0].EBH_Site__c = 'US';
        contractsVIP[0].EBH_AverageTakeRate__c=10;
        contractsVIP[0].EBH_StoreSubscription__c = 'Premium';
        update contractsVIP;

        List<Contract> listContractResultVIP = [Select recordtype.Name,Id,EBH_ContractValue__c,EBH_ContractExposure__c from Contract WHERE Id=:contractsVIP[0].Id];
	    // System.assertEquals(60000, listContractResultVIP[0].EBH_ContractValue__c.setScale(2),' calc from table in custom setting'); 
	    //System.assertEquals(110000, listContractResultVIP[0].EBH_ContractExposure__c.setScale(2),' calc from table in custom setting');
        System.assertEquals(280000, listContractResultVIP[0].EBH_ContractExposure__c.setScale(2),' calc from table in custom setting');
	    
	    Test.stopTest();
	}

    private static Map<String,Object> createData()
    {
        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;

        Map<String,Object> mapResult = new Map<String,Object>();
        EBH_ListingPricingExposure__c lp = new EBH_ListingPricingExposure__c( Name='DE', EBH_InsertionFees__c =5 );
        EBH_ListingPricingExposure__c lp2 = new EBH_ListingPricingExposure__c( Name='US', EBH_InsertionFees__c =5 );
        insert new List<EBH_ListingPricingExposure__c>{lp, lp2};

        mapResult.put('lp',lp);
        mapResult.put('lp2',lp2);
        return mapResult;
    }

/*****************************************************************************************************************************
	@ Method:         test_ShowFriendlyMessage
	@ Version:        1.0
	@ Author:         Sophal Noch
	@ Purpose:        US-0010295 - Error Message is non friendly when Seller Signatory Contract is missing during Pricing creation
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  02.09.2021 / Sophal Noch / US-0010295 Create the method.
	*****************************************************************************************************************************/
	static testMethod void test_ShowFriendlyMessage(){

        EBH_TestDataFactory.setupContractCustomSettingFee();

        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = false;
        upsert settings byPass__c.Id;

        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',EBH_PricingTrigger__c = true);
        insert  new EBH_ListingPricingExposure__c( Name='DE', EBH_InsertionFees__c =5 );
      
	    List<Account> legalEntty = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');

        Date startDate = System.today();
        Date endDate = System.today().addDays(31);
    
        List<Contract> contractsACP = createContracts(1, 'ACP', legalEntty[0].id, legalEntty[1].id, startDate, endDate);
        contractsACP[0].Status = 'Draft';
        contractsACP[0].EBH_Site__c = 'DE';
        contractsACP[0].AM_Bolt_on__c = 'Standard Price';
        contractsACP[0].VolumeBasedDiscount__c=true;
        contractsACP[0].EBH_AverageTakeRate__c=10;
        contractsACP[0].EBH_RebateTierrebate__c =10;
        contractsACP[0].EBH_StoreSubscription__c = 'Basic'; 
        contractsACP[0].TargetType__c = 'Amount';
        insert contractsACP;

        // update contractsACP;

        Test.startTest();

        System.assertNotEquals(Null, contractsACP[0].Business_Contact__c);

        Contact businessContact = [Select Id, FirstName from Contact where Id =: contractsACP[0].Business_Contact__c];
        businessContact.FirstName = '';
        update businessContact;

        try {
            List<EBH_Pricing__c> pricingsACP = EBH_TestDataFactory.createPricing (2, 'EBH_ACPTargets', contractsACP[0].id, 15, 900.00, 800.00, 2000000, 800, 'DE');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.ErrorInvalidSellerSignatoryContact));
        }
       

	    Test.stopTest();
    }


    /*********************************************************************************************************************************
    @ Method:         createContracts
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0010295 - Error Message is non friendly when Seller Signatory Contract is missing during Pricing creation
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  02.09.2021 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
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
    /*********************************************************************************************************************************
    @ Method:         updateCustomVIPflag
    @ Version:        1.0
    @ Author:         Veenus Gollapalli
    @ Purpose:        US-0015293 - VIP flag on Contract
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06.29.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    static testMethod void testupdateCustomVIPflag_updatefalsetest() {
        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        
	    List<Account> legalEntty = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
        Date startDate = System.today();
        Date endDate = System.today().addDays(31);                   
        List<Contract> contractsVIP = createContracts(1, 'VIP Contract', legalEntty[0].id, legalEntty[1].id, startDate, endDate);
        insert contractsVIP;
        RecordType vipPricingRT = EBH_TestDataFactory.getRecordTypeByName('EBH_Pricing__c','VIP_Pricing');
        Id vipPricingmatrixRT = EBH_TestDataFactory.getRecordTypeByName('EBH_ContractPricingMatrix__c','VIP_Template').Id;
        
        EBH_ContractPricingMatrix__c cpm = new EBH_ContractPricingMatrix__c();
           cpm.EBH_CAP__c = 10;
           cpm.EBH_FVF__c = 20;
           cpm.RecordTypeId = vipPricingmatrixRT;
           cpm.EBH_SiteCountry__c = 'US';
           cpm.EBH_Site__c = 'US';
           insert cpm;
	        
       EBH_Pricing__c vipPricing1 = new EBH_Pricing__c(
            EBH_ContractId__c = contractsVIP[0].Id,
            RecordtypeId = vipPricingRT.Id,
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
        
        
        Test.startTest();
        insert vipPricing1;
        vipPricing1.EBH_ContractPricingMatrix__c = cpm.Id;
        update vipPricing1;
        List<Contract> listContractResultVIP = [Select Id,Custom_VIP__c from Contract WHERE Id=:contractsVIP[0].Id];
	    System.assertEquals(false, listContractResultVIP[0].Custom_VIP__c,'VIPflag should mark as false'); 
	    Test.stopTest();

    }
     static testMethod void testupdateCustomVIPflag_updatetruetest() {
        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
	    List<Account> legalEntty = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
        Date startDate = System.today();
        Date endDate = System.today().addDays(31);                   
        List<Contract> contractsVIP = createContracts(1, 'VIP Contract', legalEntty[0].id, legalEntty[1].id, startDate, endDate);
        insert contractsVIP;


        RecordType vipPricingRT = EBH_TestDataFactory.getRecordTypeByName('EBH_Pricing__c','VIP_Pricing');
        Id vipPricingmatrixRT = EBH_TestDataFactory.getRecordTypeByName('EBH_ContractPricingMatrix__c','VIP_Template').Id;
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
            EBH_contractPricingMatrix__c = cpm.Id,
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
        
        Test.startTest();
        insert vipPricing;
		vipPricing.EBH_contractPricingMatrix__c = null;
        update vipPricing; 
        List<Contract> listContractResultVIP = [Select Id,Custom_VIP__c from Contract WHERE Id=:contractsVIP[0].Id];
	    System.assertEquals(true, listContractResultVIP[0].Custom_VIP__c,'VIPflag should mark as true'); 
	    Test.stopTest();

    }
    static testMethod void testupdateCustomVIPflag_deletetest() {
        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
	    List<Account> legalEntty = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');

        Date startDate = System.today();
        Date endDate = System.today().addDays(31); 
	                      
        List<Contract> contractsVIP = createContracts(1, 'VIP Contract', legalEntty[0].id, legalEntty[1].id, startDate, endDate);
        contractsVIP[0].Custom_VIP__c = true;
        insert contractsVIP;
        
        RecordType vipPricingRT = EBH_TestDataFactory.getRecordTypeByName('EBH_Pricing__c','VIP_Pricing');
        Id vipPricingmatrixRT = EBH_TestDataFactory.getRecordTypeByName('EBH_ContractPricingMatrix__c','VIP_Template').Id;
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
        
        Test.startTest();
        insert vipPricing;
        delete vipPricing; 
        List<Contract> listContractResultVIP = [Select Id,Custom_VIP__c from Contract WHERE Id=:contractsVIP[0].Id];
	    System.assertEquals(false, listContractResultVIP[0].Custom_VIP__c,'VIPflag should mark as false'); 
	    Test.stopTest();

    }

@isTest
static void testValidateLockedFields(){
    
    // Add bypass settings to avoid validation rules
    byPass__c settings = byPass__c.getOrgDefaults();
    settings.ByPass_Validation__c = true;
    upsert settings byPass__c.Id;
    
    // Add active validation rules bypass
    ActiveValidationRules__c avr = new ActiveValidationRules__c();
    avr.All_Validation_Rules_Deactivated__c = true;
    insert avr;
    
    Id legalEntityRecType = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id;
    Id sellerRecType = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id;
    Id manualRecType = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL').Id;
    Id vipContractRecType = ApexUtil.getRecordTypeByName('Contract','VIP_Contracts').Id;
    Id vipTemplateRecType = ApexUtil.getRecordTypeByName('EBH_ContractPricingMatrix__c','VIP_Template').Id;
    Id vipPricingRecType = ApexUtil.getRecordTypeByName('EBH_Pricing__c','VIP_Pricing').Id;

    // Create admin user to avoid permission issues
    User adminUser = EBH_TestDataFactory.createUser('System Administrator');
    
    System.runAs(adminUser) {
        Account legalEntity = new Account(
            RecordTypeId = legalEntityRecType,
            Name = 'TST Legal Entity ',
            EBH_BillingCountry__c = 'US'
        );
        insert legalEntity;

        Account seller1 = new Account(
            RecordTypeId = sellerRecType,
            Name = 'TST Seller 1',
            EBH_RevRollup__c = 'US'
        );
        insert seller1;

        Account seller2 = new Account(
            RecordTypeId = sellerRecType,
            Name = 'TST Seller 2',
            EBH_RevRollup__c = 'US'
        );
        insert seller2;

        Contact cont = new Contact(
            RecordTypeId = manualRecType,
            LastName = 'TST',
            FirstName = 'Contact',
            Email = 'test@test.com',
            AccountId = legalEntity.Id,
            EBH_Status__c = 'Active',
            EBH_DataOrigin__c = 'test'
        );
        insert cont;

        Contract contr = new Contract(
            RecordTypeId = vipContractRecType, 
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
            Business_Contact__c = cont.Id,
            EBH_PricingStartDate__c = System.today(),
            EBH_PricingEndDate__c = System.today() + 1,
            EBH_AverageTakeRate__c = 5.5,
            Surcharge__c = true
        );
        insert contr;
        
        EBH_ContractSeller__c contrSeller = new EBH_ContractSeller__c(
            EBH_ContractNumber__c = contr.Id,
            EBH_BusinessName__c = seller1.Id
        );
        insert contrSeller;
        
        Test.startTest();
        
            EBH_ContractPricingMatrix__c cpm = new EBH_ContractPricingMatrix__c(
               EBH_CAP__c = 10,
               EBH_FVF__c = 20,
               RecordTypeId = vipTemplateRecType,
               EBH_SiteCountry__c = 'US',
               EBH_Site__c = 'US',
               Active__c = true
            );
            insert cpm;
                
            EBH_Pricing__c vipPricing = new EBH_Pricing__c(
                EBH_ContractId__c = contr.Id,
                RecordtypeId = vipPricingRecType,
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
            
            contr.EBH_FinanceAgreesinPrincipal__c = True;
            contr.EBH_AttachmentCheck__c = true;
            contr.EBH_FinancePostCheckDone__c = False;
            contr.EBH_AverageTakeRate__c=5.5;
            contr.Status = 'Sent for Finance Post-check';
            Update contr;
    
            contr.Status = 'Pricing Configuration';
            Update contr;
    
            vipPricing.Status__c = 'Live';
        
            try {
                update vipPricing;
                System.assert(false, 'Expected validation error for locked fields');
            } catch (Exception e) {
                System.assert(e.getMessage().contains(Label.PricingConfigurationLockedFieldsMessage) || 
                             e.getMessage().contains('permission') || 
                             e.getMessage().contains('locked'), 
                             'Should fail due to locked fields validation. Actual error: ' + e.getMessage());
            }
        
        Test.stopTest();
    }
}

    /*****************************************************************************************************************************
    @ Method:         testPopulateTimezoneOffsets
    @ Version:        1.0
    @ Author:         GitHub Copilot
    @ Purpose:        US-0033985: Test timezone offset population on Pricing insert and update using Contract dates
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2025 / GitHub Copilot / Created the test Method.
    *****************************************************************************************************************************/
    @isTest
    static void testPopulateTimezoneOffsets() {
        // Setup bypass settings
        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        
        // Create test user
        User testUser = EBH_TestDataFactory.createUser('System Administrator');
        System.runAs(testUser) {
            // Create Account
            RecordType legalEntity = ApexUtil.getRecordTypeByName('Account', 'EBH_LegalEntity');
            Account testAccount = new Account(
                Name = 'Test Legal Entity',
                RecordTypeId = legalEntity.Id,
                EBH_BillingCountry__c = 'US'
            );
            insert testAccount;
            
            // Create Contact
            RecordType contactRT = ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL');
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test@test.com',
                AccountId = testAccount.Id,
                RecordTypeId = contactRT.Id,
                EBH_Status__c = 'Active',
                EBH_DataOrigin__c = 'test'
            );
            insert testContact;
            
            // Create Contract with specific dates
            RecordType contractRT = ApexUtil.getRecordTypeByName('Contract', 'EBH_ListingAgreement');
            Contract testContract = new Contract(
                Name = 'Test Contract',
                AccountId = testAccount.Id,
                Status = 'Draft',
                RecordTypeId = contractRT.Id,
                StartDate = Date.newInstance(2025, 6, 15), // June 15, 2025
                EndDate = Date.newInstance(2025, 12, 31), // December 31, 2025
                EBH_Site__c = 'US',
                PricingVersion__c = 'P1.0',
                CompanySignedId = testUser.Id,
                CompanySignedDate = System.today(),
                CustomerSignedDate = System.today(),
                Business_Contact__c = testContact.Id,
                Surcharge__c = true
            );
            insert testContract;
            
            Test.startTest();
            
            // Test INSERT - Create Pricing record using factory method
            List<EBH_Pricing__c> pricingList = EBH_TestDataFactory.createPricing(1, 'EBH_ListingPricing', 
                                                                                 testContract.Id, 15, 900.00, 800.00, 2000000, 800, 'US');
            EBH_Pricing__c testPricing = pricingList[0];
            
            // Verify timezone offsets were populated on insert
            EBH_Pricing__c insertedPricing = [SELECT Id, StartDateOffset__c, EndDateOffset__c, EBH_Site__c FROM EBH_Pricing__c WHERE Id = :testPricing.Id];
            
            System.assertNotEquals(null, insertedPricing.StartDateOffset__c, 'Start Date Offset should be populated on insert');
            System.assertNotEquals(null, insertedPricing.EndDateOffset__c, 'End Date Offset should be populated on insert');
            
            // Verify the offset values match expected timezone calculation for US
            Decimal expectedStartOffset = ApexUtil.getDateTimezoneOffsetForSite(testContract.StartDate, 'US');
            Decimal expectedEndOffset = ApexUtil.getDateTimezoneOffsetForSite(testContract.EndDate, 'US');
            
            System.assertEquals(expectedStartOffset, insertedPricing.StartDateOffset__c, 'Start Date Offset should match expected US timezone offset');
            System.assertEquals(expectedEndOffset, insertedPricing.EndDateOffset__c, 'End Date Offset should match expected US timezone offset');
            
            // Test UPDATE - Change site to trigger offset recalculation
            Decimal initialStartOffset = insertedPricing.StartDateOffset__c;
            Decimal initialEndOffset = insertedPricing.EndDateOffset__c;
            
            testPricing.EBH_Site__c = 'UK';
            update testPricing;
            
            // Verify timezone offsets were updated
            EBH_Pricing__c updatedPricing = [SELECT Id, StartDateOffset__c, EndDateOffset__c, EBH_Site__c FROM EBH_Pricing__c WHERE Id = :testPricing.Id];
            
            System.assertNotEquals(initialStartOffset, updatedPricing.StartDateOffset__c, 'Start Date Offset should change when site changes');
            System.assertNotEquals(initialEndOffset, updatedPricing.EndDateOffset__c, 'End Date Offset should change when site changes');
            
            // Verify the new offset values match expected timezone calculation for UK
            Decimal expectedUKStartOffset = ApexUtil.getDateTimezoneOffsetForSite(testContract.StartDate, 'UK');
            Decimal expectedUKEndOffset = ApexUtil.getDateTimezoneOffsetForSite(testContract.EndDate, 'UK');
            
            System.assertEquals(expectedUKStartOffset, updatedPricing.StartDateOffset__c, 'Start Date Offset should match expected UK timezone offset');
            System.assertEquals(expectedUKEndOffset, updatedPricing.EndDateOffset__c, 'End Date Offset should match expected UK timezone offset');
            
            Test.stopTest();
        }
    }

}