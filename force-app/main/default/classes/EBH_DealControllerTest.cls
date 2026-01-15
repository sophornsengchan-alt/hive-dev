/*********************************************************************************************************************************
@ Class:          EBH_DealControllerTest
@ Version:        1.0
@ Author:         
@ Purpose:        Test class for EBH_DealController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.11.2017 /  / Created the test class.
*********************************************************************************************************************************/

@isTest
private class EBH_DealControllerTest {
    
    @testSetup
    static void setupData(){
        //EBH_TestDataFactory.setUpCustomSettings();    

        // Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData(); 
        // Account acc = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
        //                FROM Account WHERE Id =: testDataMap.get('se1').Id][0];
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='se1',RecordTypeID = sellerRecordType.Id,NA_Deal_Program_Vetted__c = true);
        insert acc;
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Test', EBH_Country__c='UK');
        insert sc;
        Id drcRecordTypeId = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', 'Deal_Campaign_V2').Id;
         Date startDate = System.today().addDays(20);
        Date endDate = System.today().addDays(21);
        EBH_DealRetailCampaign__c drc = new EBH_DealRetailCampaign__c(
            RecordTypeId = drcRecordTypeId,
            EBH_DealTitle__c = 'SRO Test 001',
            Start_Retail_Week__c='2',
            EBH_Date__c = startDate,
            EPH_EndDate__c=endDate,
            End_Retail_Week__c = '5',
            EBH_Slots__c=3);
        insert drc;
        RecordType unSubRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c',EBH_DealController.RECORDTYPE_UNSUBDEAL);        
        EBH_Deal__c d1 = new EBH_Deal__c(EBH_BusinessName__c=acc.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456789012', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test', EBH_SpotlightCategory__c=sc.Id,
                                EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
        EBH_Deal__c d2 = new EBH_Deal__c(EBH_DealSiteId__c = '0',recordTypeId = unSubRecordType.Id, EBH_BusinessName__c=acc.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456789013', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test', EBH_SpotlightCategory__c=sc.Id,
                                EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_DealRetailCampaign__c = drc.Id,EBH_Status__c='Scheduled');
        EBH_Deal__c d3 = new EBH_Deal__c(EBH_DealSiteId__c = '0',recordTypeId= unSubRecordType.Id,EBH_BusinessName__c=acc.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456789014', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test', EBH_SpotlightCategory__c=sc.Id,
                                EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_DealRetailCampaign__c = drc.Id,EBH_Status__c='Running');                                                
        EBH_Deal__c d4 = new EBH_Deal__c(EBH_DealSiteId__c = '0',recordTypeId= unSubRecordType.Id,EBH_BusinessName__c=acc.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456789014', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test', EBH_SpotlightCategory__c=sc.Id,
                                EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_DealRetailCampaign__c = drc.Id,EBH_Status__c='Incomplete Data');  
        EBH_Deal__c d5 = new EBH_Deal__c(EBH_DealSiteId__c = '15',recordTypeId= unSubRecordType.Id,EBH_BusinessName__c=acc.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456789014', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test', EBH_SpotlightCategory__c=sc.Id,
                                EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_DealRetailCampaign__c = drc.Id,EBH_Status__c='Incomplete Data');  
        insert new List<EBH_Deal__c>{d1,d2,d3,d4,d5};

    }
    
    //TH:US-0016603 : Test Internally Rejected Deal
    static testMethod void testInternallyRejectedDeal(){
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='se1',RecordTypeID = sellerRecordType.Id,NA_Deal_Program_Vetted__c = true);
        insert acc;
        Contact cont = new Contact(
                    LastName = 'testsellerContact_1',
                    Email='test@test.com.invalid', 
                    Contact_Role__c = 'Deals',
                    AccountId=acc.Id
                );
        insert cont;
        Deal_Contract_Agreement__c dc = new Deal_Contract_Agreement__c(RecordTypeId=ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', EBH_DealController.RECORDTYPE_SUBSIDIZED_DCA).Id);
        insert dc;
        RecordType subRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c',EBH_DealController.RECORDTYPE_NA_DEAL);  
        EBH_Deal__c d1 = new EBH_Deal__c(EBH_Status__c=EBH_DealController.STATUS_IN_APPROVAL,Seller_Approver_1__c=cont.Id,EBH_DealSiteId__c = '77',
                                         EBH_MaximumPurchases__c = 1,EBH_BusinessName__c=acc.Id,recordTypeId = subRecordType.Id,Deal_Contract_Agreement__c = dc.Id, 
                                         EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456789012', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                         EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test',
                                         EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                         EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
        insert d1;

        Test.startTest();
            ApexPages.StandardSetController ssc2 = new ApexPages.StandardSetController(new List<EBH_Deal__c>());
            ssc2.setSelected(new List<EBH_Deal__c>{d1});
            EBH_DealController dcsa2 = new EBH_DealController(ssc2);
        	dcsa2.listSiteDeal[0].deal.EBH_ReasonforRejection__c ='Preis zu hoch';
            dcsa2.rejectDeal();
        Test.stopTest();
        EBH_Deal__c d = [select EBH_Status__c from EBH_Deal__c where id =: d1.Id];
        system.assertEquals('Internally Rejected', d.EBH_Status__c, 'Deal chagne status to Internally Rejected');
        
    }

    static EBH_Deal__c getInitExportDeal(){
        
        Account acc = new Account(Name='testAcc');
        insert acc;
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Test', EBH_Country__c='UK');
        insert sc;
        
        EBH_Deal__c d = new EBH_Deal__c(EBH_BusinessName__c=acc.Id, EBH_eBayItemID__c='123456789', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2000.55, 
                            EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test', EBH_SpotlightCategory__c=sc.Id,
                            EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                            EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
                            
        return d;
    }
    
    static testMethod void testTracking() {

        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        List<EBH_Deal__c> lstDeal = [select  OwnerId,EBH_Status__c, EBH_ReasonforRejection__c, RecordType.DeveloperName, EBH_DealSiteId__c from EBH_Deal__c];
        EBH_Deal__c d1 = lstDeal[0]; 
        //ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<EBH_Deal__c>{d1});
        //ssc.setSelected(new List<EBH_Deal__c>{d1});
        //EBH_DealController dcsa = new EBH_DealController(ssc);
        //dcsa.deal = new EBH_Deal__c(EBH_Status__c = 'Rejected', EBH_ReasonforRejection__c = 'Preis zu hoch');
        
        EBH_Deal__c exportDeal = getInitExportDeal();
        
        Profile p = [select id from Profile where name='NA Standard User Base' limit 1];
        User u1 = new User(alias = 'TestApro', email='TestsubApprov@ebay.com', 
                            emailencodingkey='UTF-8', lastname='TestsubApprov', firstname='TestsubApprov', languagelocalekey='en_US', 
                            localesidkey='en_US', profileid = p.Id, 
                            timezonesidkey='America/Los_Angeles', username='TestsubApprov@salesforce.de', isActive = true);
                            
        System.runAs(admin){
            
            insert u1;
        }
        
        
        System.runAs(admin){
            List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
            for(PermissionSet ps :  [SELECT Id, Name FROM PermissionSet WHERE Name = 'US_Manage_Deals']){
                psa.add(new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = u1.Id));
            }
            
            insert psa;
       }
            
        Test.startTest();
        
            //test error no deal selected
            ApexPages.StandardSetController ssc0 = new ApexPages.StandardSetController(new List<EBH_Deal__c>());
            ssc0.setSelected(new List<EBH_Deal__c>());
            EBH_DealController dcsa0 = new EBH_DealController(ssc0);
            dcsa0.initRejecting();
            

            System.runAs(u1){
                ApexPages.StandardSetController ssc1 = new ApexPages.StandardSetController(new List<EBH_Deal__c>());
                ssc1.setSelected(new List<EBH_Deal__c>{d1});
                EBH_DealController dcsa1 = new EBH_DealController(ssc1);
                dcsa1.initRejecting();
                dcsa1.confirmAcceptDeal();
        		dcsa1.confirmRejectDeal();
                dcsa1.acceptDeal();
                dcsa1.rejectDeal();
            }
           	//test success updated
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<EBH_Deal__c>{d1});
            ssc.setSelected(new List<EBH_Deal__c>{d1});
            EBH_DealController dcsa = new EBH_DealController(ssc);

            dcsa.selectedDeal = new List<EBH_Deal__c>{d1};
            d1.EBH_DealPrice__c = 200;
            d1.EBH_DealFormat__c = 'iji';
            d1.EBH_DealStartDate__c = Date.today();
            d1.EBH_DealEndDate__c = Date.today();
            d1.EBH_SellerEmail__c ='dd@d.com';
            d1.EBH_MaximumPurchases__c =324;
            update d1;
            //dcsa.acceptDeal();
            
            //dcsa.listSiteDeal[0].deal.EBH_ReasonforRejection__c ='Preis zu hoch';
            //dcsa.rejectDeal();
            //EBH_Deal__c d1Sel = [select  OwnerId,EBH_Status__c, EBH_ReasonforRejection__c from EBH_Deal__c where Id=:d1.Id].get(0); 
            //System.assert(d1.EBH_Status__c == 'Rejected');
            //System.assertEquals('Rejected',d1.EBH_Status__c);
            
            PageReference pr = dcsa.backToListView();
            //System.assert(pr.getUrl() == dcsa.reUrl);

            
            ApexPages.StandardSetController ssc2 = new ApexPages.StandardSetController(new List<EBH_Deal__c>());
                ssc2.setSelected(lstDeal);
                EBH_DealController dcsa2 = new EBH_DealController(ssc2);
                dcsa2.initRejecting();
                dcsa2.confirmAcceptDeal();
        		dcsa2.confirmRejectDeal();
                dcsa2.acceptDeal();
                dcsa2.rejectDeal();

            
            String csvExportString = dcsa.buildCSVData(new List<EBH_Deal__c>{ exportDeal });
            System.assert(csvExportString.contains(exportDeal.EBH_eBayItemID__c));
            System.assert(csvExportString.contains(exportDeal.EBH_DealPrice__c+''));
            //System.assert(csvExportString.contains(exportDeal.EBH_RRPWASPrice__c+''));
            //System.debug('>>>>: '+csvExportString);
            System.assert(csvExportString.contains('2000.55')); //no thousand separator
            
            System.assert(csvExportString.contains(exportDeal.EBH_RecommendedRetailPriceWAS__c));
            System.assert(csvExportString.contains(exportDeal.EBH_MarketingTitle__c));
            System.assert(csvExportString.contains(exportDeal.EBH_DealFormat__c));
            
            System.assertEquals(d1.OwnerId,UserInfo.getUserId(),'user who accepted/rejected the deal, become the owner of the deals.');
            Database.executeBatch(new EBH_CalculateDeals());
        Test.stopTest();
    }
    //TH:18/08/2022
    static testMethod void testAcceptDeal(){
        List<EBH_Deal__c> lstDeal = [select  OwnerId,EBH_Status__c, EBH_ReasonforRejection__c from EBH_Deal__c where EBH_Status__c='Incomplete Data'];
        Test.startTest();
        	ApexPages.StandardSetController ssc1 = new ApexPages.StandardSetController(new List<EBH_Deal__c>());
                ssc1.setSelected(lstDeal);
                EBH_DealController dcsa1 = new EBH_DealController(ssc1);
                dcsa1.confirmAcceptDeal();
                dcsa1.acceptDeal();
        Test.stopTest();
        System.debug('deal ::'+[select EBH_Status__c from EBH_Deal__c where id IN: lstDeal]);
    }
    
    //NK:07/06/2018
    //TH: US-0013020:comment out
    /*static testMethod void testNegotiation()
    {
    	Test.startTest();
	    	EBH_Deal__c d1 = [select  OwnerId,EBH_Status__c, EBH_ReasonforRejection__c from EBH_Deal__c].get(0); 
	        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<EBH_Deal__c>{d1});
	        ssc.setSelected(new List<EBH_Deal__c>{d1});
	        EBH_DealController dcsa = new EBH_DealController(ssc);
	        dcsa.negotiationComment = 'comment test555';
	        dcsa.negotiateDeals();
        	
        	d1 = [select  OwnerId,EBH_Status__c, EBH_CommentfromeBaySourcer__c from EBH_Deal__c].get(0); 
        	
        	System.assertEquals(EBH_ConstantsUtility.DEAL_STATUS_NEGOTIATING,d1.EBH_Status__c,'status changed to Negotiating');
        	System.assertEquals(dcsa.negotiationComment,d1.EBH_CommentfromeBaySourcer__c,'status changed to Negotiating');
        	
        Test.stopTest();
        
    }*/
    
    //TH:17/08/2021:US-0010082 - [SEP] Generate Spotlight Export file from Deal Window
    static testMethod void testDealRetailCampaign_ExportDeal()
    {
    	EBH_DealController dcsa;
    	Test.startTest();
    		List<EBH_DealRetailCampaign__c> lstdealRetailCamapign = [select id from EBH_DealRetailCampaign__c];

    		ApexPages.StandardController sc = new ApexPages.StandardController(lstdealRetailCamapign[0]);
            dcsa = new EBH_DealController(sc);
    	Test.stopTest();
    	System.assert(String.isBlank(dcsa.csvData));
    }

    @isTest
    static void testacceptDealV1() {
        EBH_TestDataFactory.setUpCustomSettings();    
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='seller2',RecordTypeID = sellerRecordType.Id,NA_Deal_Program_Vetted__c = true,EBH_VATNumber__c = '10');
        insert acc;
        Contact cont = new Contact(
                    LastName = 'testsellerContact_2',
                    Email='test@test.com.invalid', 
                    Contact_Role__c = 'Deals',
                    AccountId=acc.Id
                );
        insert cont;
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Test', EBH_Country__c='DE');
        insert sc;
        RecordType v1RecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c',EBH_DealController.RECORDTYPE_DEAL_V1);        
        EBH_Deal__c d2 = new EBH_Deal__c(EBH_DealSiteId__c = '77',recordTypeId = v1RecordType.Id, EBH_BusinessName__c=acc.Id, Seller_Contact__c = cont.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456789050', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test', EBH_SpotlightCategory__c=sc.Id,
                                EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_Status__c='New');
        insert d2;
        Test.startTest();
        System.debug(' EBH_ActiveTriggers__c :: ' + EBH_ActiveTriggers__c.getInstance(EBH_ConstantsUtility.TRIGGERCONTROLLER));
        ApexPages.StandardSetController ssc2 = new ApexPages.StandardSetController(new List<EBH_Deal__c>());
        ssc2.setSelected(new List<EBH_Deal__c>{d2});
        EBH_DealController dcsa2 = new EBH_DealController(ssc2);
        dcsa2.acceptDealV1();
        Test.stopTest();
        List<EBH_Deal__c> deal2 = [SELECT Id, EBH_Status__c FROM EBH_Deal__c WHERE Id = :d2.Id];
        System.assertEquals(EBH_DealController.STATUS_PLANNED, deal2[0].EBH_Status__c, 'Deal Status is Updated to Planned after accepting the deal');
    }
}