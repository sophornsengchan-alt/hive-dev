/**
 * test logic for DD_CancelDealController
 * @Create by : theany
 * @Created Date : 09/08/2018
 * @Change history
    - 24.12.2020 / Mony Nou / Updated the class for US-0008827 - [NA] NA Deals: Make Cancellation Reason required when Cancelling Deals from List View  
 */

@isTest
private class DD_CancelDealControllerTest {

    @isTest
    public static void test_NotNAUser() {

        //setupData();
        
        List<EBH_Deal__c> lstDealSeller1 = [select id,OwnerId from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 1'];
    	List<EBH_Deal__c> lstDealSeller2 = [select id,OwnerId from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 2'];
    	
        Test.startTest();
            
            // User user = [Select Id, Profile.Name From User Where Profile.Name <>: DD_CancelDealController.NA_PROFILE AND ProfileId <>: EBH_ConstantsUtility.ADMIN_PROFILE_ID AND isActive = true LIMIT 1];

            User user = [Select Id, Profile.Name From User Where Profile.Name = 'Standard User Profile' AND isActive = true LIMIT 1];

            System.debug('#### user :: ' + user.Id + ' - ' + user.Profile.Name);

            System.runAs(user) {
                ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDealSeller1);
                ssc.setSelected(lstDealSeller1);
                DD_CancelDealController controller = new DD_CancelDealController(ssc);
                
                //controller.massCancelDeal();

                System.assert(ApexPages.hasMessages(ApexPages.SEVERITY.ERROR));
            }
    		
    	Test.stopTest();
     
    }

    @isTest
    public static void test_EmptyCancellationReason () {

        //setupData();

        List<EBH_Deal__c> lstDealSeller1 = [select id,OwnerId from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 1'];
    	List<EBH_Deal__c> lstDealSeller2 = [select id,OwnerId from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 2'];
    	
        Test.startTest();
    		
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDealSeller1);
            ssc.setSelected(lstDealSeller1);
            DD_CancelDealController controller = new DD_CancelDealController(ssc);
            
            controller.massCancelDeal();

            System.assert(ApexPages.hasMessages(ApexPages.SEVERITY.ERROR));
            
    	Test.stopTest();
        
    }
    
    @isTest
    public static void test_DocApproval(){
        //setupData();
        /*
        RecordType sellerRecordTypeLeg = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
    	Account acc = new Account(Name='Test Account Name: 1', BillingCountry='CH',RecordTypeID = sellerRecordTypeLeg.Id);
        insert acc;
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');

        Account eBaySeller1 = new Account (Name='Test eBaySeller For Doc Approve 1',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id);
        Account eBaySeller2 = new Account (Name='Test eBaySeller For Doc Approve 2',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id);
        insert new List<Account>{eBaySeller1,eBaySeller2};
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller1.Id);
        Contact contact2 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test2',
                                      email='test2@test.com' , AccountId = eBaySeller2.Id);
        insert new List<Contact>{contact1,contact2};
            
        Date myDate = System.Today().adddays(2);
        EBH_SpotlightCategory__c spotCat = new EBH_SpotlightCategory__c(Name = 'test spotLightCat',EBH_Country__c='UK',EBH_SpotlightCategoryID__c='1243545',Spotlight_Start_Date__c=myDate,Spotlight_End_Date__c=myDate);
        insert spotCat;
        Id devRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c();
        insert ndca;
        
        Time myTime = Time.newInstance(1, 1, 1, 1);
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
        for(Integer i = 1; i < 3; i++){
        	EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i, 
	        Seller_Approver_1__c = contact1.Id,
	        EBH_BusinessName__c=eBaySeller1.ID,
	        EBH_SpotlightCategory__c = spotCat.Id,
	        RecordTypeId=devRecordTypeId,
	        EBH_SellerPrice__c=20,EBH_DealPrice__c=5,
	        EBH_Quantity__c=2,EBH_DealStartDate__c=myDate,
	        EBH_DealEndDate__c=myDate,EBH_DealStartTime__c = 
	        myTime,
	        EBH_DealEndTime__c = myTime,
	        EBH_Status__c='Internally Approved',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
	        Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
	        EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);
	        lstDeal.add(d1);
        }
        
            EBH_Deal__c d2 = new EBH_Deal__c(
            EBH_eBayItemID__c = '000000000010', 
	        Seller_Approver_1__c = contact2.Id,
	        EBH_BusinessName__c=eBaySeller2.ID,
	        EBH_SpotlightCategory__c = spotCat.Id,
	        RecordTypeId=devRecordTypeId,
	        EBH_SellerPrice__c=20,EBH_DealPrice__c=5,
	        EBH_Quantity__c=2,EBH_DealStartDate__c=myDate,
	        EBH_DealEndDate__c=myDate,EBH_DealStartTime__c = 
	        myTime,
	        EBH_DealEndTime__c = myTime,
	        EBH_Status__c='Internally Approved',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
	        Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
	        EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);
	        lstDeal.add(d2);
        insert lstDeal;
        */
        List<EBH_Deal__c> lstDealSeller1 = [select id,OwnerId from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 1'];
    	List<EBH_Deal__c> lstDealSeller2 = [select id,OwnerId from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 2'];
    	Test.startTest();
    		//test error no deal selected
    		ApexPages.StandardSetController ssc0 = new ApexPages.StandardSetController(new List<EBH_Deal__c>());
            ssc0.setSelected(new List<EBH_Deal__c>());
            DD_CancelDealController controller0 = new DD_CancelDealController(ssc0);
           	//test success updated
    		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDealSeller1);
            ssc.setSelected(lstDealSeller1);
            DD_CancelDealController controller = new DD_CancelDealController(ssc);
            controller.initialize(); //MN-03022022-US-0010984
            controller.cancellationReason = 'testCancel';
            controller.massCancelDeal();
            List<EBH_Deal__c> cancelDeals = [select EBH_status__c, Cancellation_Reason__c from EBH_Deal__c where id IN: lstDealSeller1];
            for(EBH_Deal__c d : cancelDeals){
            	System.assertEquals('Cancelled',d.EBH_status__c);
            	System.assertEquals('testCancel',d.Cancellation_Reason__c);
            }
            controller.cancel();
            //controller.sendEmailTemplate(lstDealSeller1);
            //test error difference seller
            List<EBH_Deal__c> bindListDeal = new List<EBH_Deal__c>();
            bindListDeal.addall(lstDealSeller1);
            bindListDeal.addall(lstDealSeller2);
            ApexPages.StandardSetController ssc2 = new ApexPages.StandardSetController(bindListDeal);
            ssc2.setSelected(bindListDeal);
            DD_CancelDealController controller2 = new DD_CancelDealController(ssc2);
        	controller2.ok();
        	controller2.confirmDeal();
            controller2.massCancelDeal();
        
            
            //test error wrong deal record type
            // Id devRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
            // lstDealSeller1.RecordTypeId = devRecordTypeId;
            // update lstDealSeller1;
            // ApexPages.StandardSetController ssc3 = new ApexPages.StandardSetController(lstDealSeller1);
            // ssc3.setSelected(lstDealSeller1);
            // DD_CancelDealController controller3 = new DD_CancelDealController(ssc3);
    	Test.stopTest();
    }

    @testSetup static void testSetup() {

        EBH_TestDataFactory.setUpCustomSettings();   
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;

        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;


        RecordType sellerRecordTypeLeg = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
    	Account acc = new Account(Name='Test Account Name: 1', BillingCountry='CH',RecordTypeID = sellerRecordTypeLeg.Id);
        insert acc;
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');

        Account eBaySeller1 = new Account (Name='Test eBaySeller For Doc Approve 1',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id);
        Account eBaySeller2 = new Account (Name='Test eBaySeller For Doc Approve 2',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id);
        insert new List<Account>{eBaySeller1,eBaySeller2};
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller1.Id);
        Contact contact2 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test2',
                                      email='test2@test.com' , AccountId = eBaySeller2.Id);
        Contact contact3 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
        FirstName='firstname',Salutation='Mr.',LastName='test2',
        email='test2@test.com' , AccountId = eBaySeller2.Id);
        insert new List<Contact>{contact1,contact2,contact3};
            
        Date myDate = System.Today().adddays(2);
        EBH_SpotlightCategory__c spotCat = new EBH_SpotlightCategory__c(Name = 'test spotLightCat',EBH_Country__c='UK',EBH_SpotlightCategoryID__c='1243545',Spotlight_Start_Date__c=myDate,Spotlight_End_Date__c=myDate);
        insert spotCat;
        
        //MN-17082022-US-0011119-Remove reference with old record type name
        // Id devRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
        RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
        Id devRecordTypeId = subDealRecordType.Id;

        Id unSubdealRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V3').Id;

        Id stdDealRTId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(); 
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(RecordTypeId=ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals').Id);
        insert ndca;
        
        Time myTime = Time.newInstance(1, 1, 1, 1);
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
        for(Integer i = 1; i < 3; i++){
        	EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i, 
	        Seller_Approver_1__c = contact1.Id,
	        EBH_BusinessName__c=eBaySeller1.ID,
	        EBH_SpotlightCategory__c = spotCat.Id,
	        RecordTypeId=devRecordTypeId,
	        EBH_SellerPrice__c=20,EBH_DealPrice__c=5,
	        EBH_Quantity__c=2,EBH_DealStartDate__c=myDate,
	        EBH_DealEndDate__c=myDate,EBH_DealStartTime__c = 
	        myTime,
	        EBH_DealEndTime__c = myTime,
	        EBH_Status__c='Internally Approved',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
	        Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
	        EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id, EBH_DealSiteId__c = '0');
            lstDeal.add(d1);
        }
        
        EBH_Deal__c d2 = new EBH_Deal__c(
        EBH_eBayItemID__c = '000000000010', 
        Seller_Approver_1__c = contact2.Id,
        EBH_BusinessName__c=eBaySeller2.ID,
        EBH_SpotlightCategory__c = spotCat.Id,
        RecordTypeId=devRecordTypeId,
        EBH_SellerPrice__c=20,EBH_DealPrice__c=5,
        EBH_Quantity__c=2,EBH_DealStartDate__c=myDate,
        EBH_DealEndDate__c=myDate,EBH_DealStartTime__c = 
        myTime,
        EBH_DealEndTime__c = myTime,
        EBH_Status__c='Internally Approved',
        EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
        Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
        EBH_DealSiteId__c = '0',
        EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);
        lstDeal.add(d2);
        
        EBH_Deal__c d3 = new EBH_Deal__c(RecordTypeId = devRecordTypeId, 
                                             EBH_SellerPrice__c = 1000,
                                             EBH_DealPrice__c = 11,
                                             EBH_BusinessName__c = eBaySeller2.Id,
                                             EBH_SoldItems__c = 2,
                                             EBH_Vertical__c = 'CSA',
                                             EBH_DealStartDate__c = System.today().addDays(3),
                                             EBH_DealEndDate__c = System.today().addDays(5),
                                             EBH_Status__c = 'Ops Review',
                                             EBH_Category__c = 'Gold',
                                             EBH_ProductTitle__c = 'product1',
                                             EBH_SellerEmail__c = 'sales@test.com',
                                             EBH_Quantity__c = 10,
                                             EBH_DealStartTime__c = myTime,
        EBH_DealEndTime__c = myTime,
                                             EBH_DealFormat__c = 'Deal',
                                             EBH_eBayItemID__c = '333456789110',
                                             EBH_DealSiteId__c='101',
                                             EBH_MaximumPurchases__c=2,
                                             Seller_Contact__c = contact3.Id);
        lstDeal.add(d3);

        EBH_Deal__c d4 = new EBH_Deal__c(RecordTypeId = devRecordTypeId, 
                                             EBH_SellerPrice__c = 1000,
                                             EBH_DealPrice__c = 11,
                                             EBH_BusinessName__c = eBaySeller2.Id,
                                             EBH_SoldItems__c = 2,
                                             EBH_Vertical__c = 'CSA',
                                             EBH_DealStartDate__c = System.today().addDays(10),
                                             EBH_DealEndDate__c = System.today().addDays(15),
                                             EBH_Status__c = 'Ops Review',
                                             EBH_Category__c = 'Gold',
                                             EBH_ProductTitle__c = 'product2',
                                             EBH_SellerEmail__c = 'sales@test.com',
                                             EBH_Quantity__c = 10,
                                             EBH_DealStartTime__c = myTime,
                                             EBH_DealEndTime__c = myTime,
                                             EBH_DealFormat__c = 'Deal',
                                             EBH_eBayItemID__c = '333456789110',
                                             EBH_DealSiteId__c='101',
                                             EBH_MaximumPurchases__c=2,
                                             Seller_Contact__c = contact2.Id);
        lstDeal.add(d4);
        insert lstDeal;

        

    }

    @IsTest
    private static void test_CancelApprovalProcess() {
         // 03.06.2021 / Sophal Noch  / US-0009585 test method

        Id userId = UserInfo.getUserId();

        Account eBaySeller = [Select id From Account where Name ='Test eBaySeller For Doc Approve 1'];
        
        EBH_Deal__c deal1 = [select id,
                                Seller_Approver_1__r.Email,
                                Seller_Approver_2__r.Email,
                                Seller_Approver_3__r.Email,
                                Seller_Approver_4__r.Email,
                                Seller_Approver_5__r.Email,
                                Deal_Contract_Agreement__c,
                                EBH_BusinessName__c, 
                                OwnerId 
                            from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 1' Limit 1];
    	EBH_Deal__c deal2 = [select id,
                                Seller_Approver_1__r.Email,
                                Seller_Approver_2__r.Email,
                                Seller_Approver_3__r.Email,
                                Seller_Approver_4__r.Email,
                                Seller_Approver_5__r.Email,
                                Deal_Contract_Agreement__c,
                                EBH_BusinessName__c, 
                                OwnerId 
                            from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 2' Limit 1];
        List<EBH_Deal__c> listDeal = new List<EBH_Deal__c>{deal1,deal2};
        listDeal[0].Merchant_Approver__c = userId;
        listDeal[0].EBH_BusinessName__c = eBaySeller.Id;
        listDeal[1].Merchant_Approver__c = userId;
        listDeal[1].EBH_BusinessName__c = eBaySeller.Id;
        update listDeal;

        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();

        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Test Approve Deal 1');
        req1.setObjectId(listDeal[0].Id);
        req1.setSubmitterId(userId);
        requests.add(req1);

        Approval.ProcessSubmitRequest req2 = new Approval.ProcessSubmitRequest();
        req2.setComments('Test Approve Deal 2');
        req2.setObjectId(listDeal[1].Id);
        req2.setSubmitterId(userId);
        requests.add(req2);

        Approval.process(requests);

        List<ProcessInstanceWorkitem> workitems =  [Select id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN :listDeal AND ProcessInstance.Status ='Pending'];
        System.assertEquals(2, workitems.size());

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(listDeal);
        ssc.setSelected(listDeal);
        DD_CancelDealController controller = new DD_CancelDealController(ssc);
        controller.cancellationReason = 'testCancel';
        controller.massCancelDeal();

        Map<String,Set<String>> mapToAddress = new Map<String,Set<String>>();
        Set<String> emailsapprovers = new Set<String>();

        for(EBH_Deal__c deal : listDeal){
            if(mapToAddress.containsKey(deal.Deal_Contract_Agreement__c)) emailsapprovers = mapToAddress.get(deal.Deal_Contract_Agreement__c);
            if (String.isNotBlank(deal.Seller_Approver_1__r.Email)) {
                emailsapprovers.add(deal.Seller_Approver_1__r.Email);
            }
            if (String.isNotBlank(deal.Seller_Approver_2__r.Email)) {
                emailsapprovers.add(deal.Seller_Approver_2__r.Email);
            }
            if (String.isNotBlank(deal.Seller_Approver_3__r.Email)) {
                emailsapprovers.add(deal.Seller_Approver_3__r.Email);
            }
            if (String.isNotBlank(deal.Seller_Approver_4__r.Email)) {
                emailsapprovers.add(deal.Seller_Approver_4__r.Email);
            }
            if (String.isNotBlank(deal.Seller_Approver_5__r.Email)) {
                emailsapprovers.add(deal.Seller_Approver_5__r.Email);
            }
            mapToAddress.put(deal.Deal_Contract_Agreement__c, emailsapprovers);
        }
        controller.sendEmailTemplate(listDeal,mapToAddress);

        workitems =  [Select id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN :listDeal AND ProcessInstance.Status ='Pending'];
        System.assertEquals(0, workitems.size());
    }

    /*
	static testmethod void setupData(){

        EBH_TestDataFactory.setUpCustomSettings();   
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;

    }
    */
   @IsTest
    private static void test_Cancel_IT() {

        List<EBH_Deal__c> listDeal =[Select Id,EBH_eBayItemID__c,EBH_BusinessName__c FROM EBH_Deal__c WHERE EBH_DealSiteId__c ='101'];
        List<Seller_Communication__c> lstITSellerComToInsert = new List<Seller_Communication__c>();
        Id sellerComRT_Deals =ApexUtil.getRecordTypeByName('Seller_Communication__c', 'Deals').Id;
        List<String> listEbayItems = new List<String>();
        for(EBH_Deal__c d: listDeal){
            listEbayItems.add(d.EBH_eBayItemID__c);
        }

        Test.startTest();

            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(listDeal);
            ssc.setSelected(listDeal);
            DD_CancelDealController controller = new DD_CancelDealController(ssc);
            controller.initialize(); //MN-03022022-US-0010984
            controller.cancellationReason = 'testCancel';
            controller.massCancelDeal();
            List<EBH_Deal__c> cancelDeals = [select Id,EBH_eBayItemID__c,EBH_BusinessName__c,Seller_Contact__c, EBH_status__c, Cancellation_Reason__c from EBH_Deal__c where id IN: listDeal];
            Id sellerId = cancelDeals[0].EBH_BusinessName__c;
            for(EBH_Deal__c d : cancelDeals){
                String ebayItemsPerSeller = String.join(listEbayItems,',');
                lstITSellerComToInsert.add(new Seller_Communication__c(
                    RecordTypeId = sellerComRT_Deals, 
                    Contact__c = d.Seller_Contact__c,
                    Account__c = sellerId,
                    Region__c = 'IT',
                    Email_Template__c = 'Sub Deal Cancellation Email to Seller - IT',
                    Email_Body__c = ebayItemsPerSeller,
                    Name = 'Sub Deal Cancellation Email to Seller - IT',
                    Deal__c = d.Id,
                    Platform__c = 'Seller Portal'
                ));
                    
            }
            insert lstITSellerComToInsert;
    		controller.cancel();

    	Test.stopTest();

    }
}