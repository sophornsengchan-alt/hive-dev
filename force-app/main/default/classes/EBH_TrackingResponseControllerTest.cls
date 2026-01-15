/*********************************************************************************************************************************
@ Class:          EBH_DealControllerTest
@ Version:        1.0
@ Author:         
@ Purpose:        Test class for EBH_DealController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.11.2017 /  / Created the test class.
@ Change history: 22/01/2024 / Vimean Heng / disable record type "special permission request" , devloper name = Admin_Request
*********************************************************************************************************************************/
@isTest
private class EBH_TrackingResponseControllerTest {

    static testMethod void testTracking() {

        EBH_TestDataFactory.setUpCustomSettings();     
        /*Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData();     
        Account acc = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
                       FROM Account WHERE Id =: testDataMap.get('se1').Id][0];*/
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
	    //Account acc = new Account(EBH_PrimarySite__c='UK',Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_SoldItems__c=100,EBH_GMVLast12Months__c=10, EBH_RevenueLast12Months__c=10,EBH_VATNumber__c='1122334455');
        Account acc = new Account(EBH_PrimarySite__c='UK',Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_SoldItems__c=100,EBH_GMVLast12Months__c=10, EBH_RevenueLast12Months__c=10,EBH_VATNumber__c='1122334455');
	    insert acc;

        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Test', EBH_Country__c='UK');
        insert sc;
                
        EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(EBH_Slots__c =2);
        insert dsa1;
        Date myDate = Date.today().addDays(30);

	Contact oContact = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',FirstName='firstname',Salutation='Mr.',LastName='test1',Email='test1@test.com' , AccountId = acc.Id,Contact_Role__c='Deals');
        insert oContact;
        EBH_Deal__c d1 = new EBH_Deal__c(
	    Seller_Contact__c=oContact.Id,
            EBH_Status__c='New',
            EBH_DealStartTime__c= System.now().time(), 
            EBH_DealStartDate__c=System.toDay().addDays(1),
            EBH_eBayItemID__c='12345678901',
            EBH_DEALSITEID__c='77',
        	EBH_BusinessName__c=acc.Id,
            EBH_SpotlightCategory__c=sc.Id,
            EBH_MaximumPurchases__c =324,
            EBH_DealRetailCampaign__c=dsa1.Id,
            EBH_SellerPrice__c=40,
            EBH_DealPrice__c=20,
            EBH_SoldItems__c=2,
            EBH_Vertical__c='CSA',
            EBH_DealEndDate__c = myDate,
            EBH_DealEndTime__c = System.now().time(),
            EBH_DealFormat__c='Primary',
            EBH_Category__c='Gold', 
            EBH_ProductTitle__c='product 1',
            EBH_SellerEmail__c='sales@test.com',
            EBH_Quantity__c=1
        );
        insert d1;

        d1.EBH_Status__c = 'Planned';
        update d1;
        
        Test.startTest();
        
          PageReference pageRef = Page.EBH_TrackingResponse;
          Test.setCurrentPage(pageRef);
          ApexPages.currentPage().getParameters().put('id', d1.Id);
          ApexPages.currentPage().getParameters().put('reURL', 'www.ebay.de');
          
          EBH_TrackingResponseController con = new EBH_TrackingResponseController();
          con.checkResponse();
          
          EBH_Deal__c  deal = [Select Id,EBH_Selleraccepted__c,EBH_Selleracceptedfrom__c from EBH_Deal__c Where Id=:d1.Id];
          System.assert(deal.EBH_Selleraccepted__c <> null,'date time must be populated');
          
          ApexPages.currentPage().getParameters().put('id', null);
          con.checkResponse();
          
        Test.stopTest();
        
    }
    
    static testMethod void testTrackingCouponSeller() {
    	EBH_TestDataFactory.setUpCustomSettings();     
        /*Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData();     
        Account acc = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
                       FROM Account WHERE Id =: testDataMap.get('se1').Id][0];*/
                    
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
	    //Account acc = new Account(Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_SoldItems__c=100,EBH_GMVLast12Months__c=10, EBH_RevenueLast12Months__c=10,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        Account acc = new Account(EBH_RevRollup__c='US', Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_SoldItems__c=100,EBH_GMVLast12Months__c=10, EBH_RevenueLast12Months__c=10,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
	    insert acc;
        RecordType couponRecordTypeCategory = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
        Coupon__c c1 = new Coupon__c(Coupon_ID__c='test',Main_Coupon_Site__c = 'ebay.com', RecordTypeID = couponRecordTypeCategory.Id,Contract_Due_Date__c = System.today()-2, Coupon_Start_Date__c = System.today()+1, Coupon_End_Date__c = System.today() +2);
        insert c1;
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO,Seller__c = acc.Id,Allow_reaccept_contract__c=false);
        insert cs1;    
        Test.startTest();
        PageReference pageRef = Page.EBH_TrackingResponse;
          Test.setCurrentPage(pageRef);
          ApexPages.currentPage().getParameters().put('csid', cs1.Id);
          ApexPages.currentPage().getParameters().put('reURL', 'www.ebay.de');
          ApexPages.currentPage().getParameters().put('restype', 'cscontract');
          
          EBH_TrackingResponseController con = new EBH_TrackingResponseController();
          con.checkResponse();
          
          c1.Contract_Due_Date__c = System.today();
          update c1;
          
          con.checkResponse();
          
          Coupon_Seller__c cs = [select Coupon_Seller_Stage__c, Contract_Accept_Date__c from Coupon_Seller__c where id =: cs1.Id];
          System.assert(cs.Coupon_Seller_Stage__c == EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED,'Coupon seller stage update to '+EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED);
          
          ApexPages.currentPage().getParameters().put('csid', null);
          con.checkResponse();
        Test.stopTest();
    }
    
        static testMethod void testTrackingFinalValueFee() {
        	EBH_TestDataFactory.setUpCustomSettings();
        	/*Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData();
        	Account acc = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c FROM Account WHERE Id =: testDataMap.get('se1').Id][0];*/
            RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
	    	//Account acc = new Account(EBH_RevRollup__c ='UK',EBH_PrimarySite__c='UK',Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_SoldItems__c=100,EBH_GMVLast12Months__c=10, EBH_RevenueLast12Months__c=10);
            Account acc = new Account(EBH_RevRollup__c ='UK',EBH_PrimarySite__c='UK',Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_SoldItems__c=100,EBH_GMVLast12Months__c=10, EBH_RevenueLast12Months__c=10);
	    	insert acc;
        	Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(Seller_Name__c = acc.Id,Seller_Email__c='test@test.com',Discount_FVF__c =25,Requestor__c=UserInfo.getUserId());
            insert fvf;
            fvf.Final_Value_Fee_Stage__c = 'eBay Approved';
            fvf.Legal_Entity_Name__c = 'test';
            fvf.Legal_Entity_Street__c = 'test';
            fvf.Legal_Entity_Zip__c = 'test';
            fvf.Legal_Entity_Country__c = 'test';
            update fvf;
            User deploymentUser = [Select Id,Name From User where FirstName='Deployment' limit 1];
            System.runAs(deploymentUser)
            {
                fvf.Final_Value_Fee_Stage__c = 'Contract Sent';
                update fvf;
            }
	    	Test.startTest();
	    	
	    	PageReference pageRef = Page.EBH_TrackingResponse;
	    	Test.setCurrentPage(pageRef);
	    	ApexPages.currentPage().getParameters().put('fvfid', fvf.Id);
	    	ApexPages.currentPage().getParameters().put('reURL', 'www.ebay.de');
	    	ApexPages.currentPage().getParameters().put('restype', 'fvfcontract');
	    	
	    	EBH_TrackingResponseController con = new EBH_TrackingResponseController();
	    	con.checkResponse();
            Final_Value_Fee_FVF__c fvfSelected = [select Final_Value_Fee_Stage__c from Final_Value_Fee_FVF__c where id =: fvf.Id];
	    	System.assert(fvfSelected.Final_Value_Fee_Stage__c == EBH_ConstantsUtility.FVF_STAGE_CONTRACT_SIGNED,'FinalValue stage update to '+EBH_ConstantsUtility.FVF_STAGE_CONTRACT_SIGNED);
	    	
	    	ApexPages.currentPage().getParameters().put('fvfid', null);
	    	con.checkResponse();
	    	
	    	Test.stopTest();
        }
      //@ Change history: 22/01/2024 / Vimean Heng / US-0014626 / disable record type "special permission request" , devloper name = Admin_Request
      static testMethod void testHandleTicketSOS_Contract()
      {
        User admin1 = EBH_TestDataFactory.createUser('System Administrator');
          System.runAs(admin1){
              EBH_TestDataFactory.setUpCustomSettings();
              Database.DMLOptions dmo = new Database.DMLOptions();
              dmo.assignmentRuleHeader.useDefaultRule= true;
               Case c1 = new Case(    
                        Status = 'New',                        
                        Who_should_have_admin_access__c = UserInfo.getUserId()
                        //Admin_Request_Type__c = 'Export Reports',
                        //RecordTypeId = ApexUtil.getRecordTypeByName('Case','Admin_Request').Id

                   );
                   c1.setOptions(dmo);
                   
                   insert c1;
           Test.startTest();   
              Case cs = [Select Id,Unique_Id__c From Case where Id = :c1.Id];

              PageReference pageRef = Page.EBH_TrackingResponse;
              Test.setCurrentPage(pageRef);
              ApexPages.currentPage().getParameters().put('id', EncodingUtil.urlEncode(cs.Unique_Id__c, 'UTF-8'));
              ApexPages.currentPage().getParameters().put(EBH_TrackingResponseController.RESPONSE_TYPE, EBH_TrackingResponseController.CONRACT_TICKET_URL_TYPE_PII);
              
              EBH_TrackingResponseController con = new EBH_TrackingResponseController();
              EBH_CheckRecursive.Run = true;

              con.checkResponse();

              Test.stopTest();

             //PermissionSetAssignment[] psa = [Select Id  From PermissionSetAssignment Where PermissionSet.Name = 'EBH_exportReportsPermissionSet' AND AssigneeId = :UserInfo.getUserId()];
             //System.assertNotEquals(psa.size(), 0,'assign when accept from site');
          }
      }
    
    static testMethod void testHandleContractAgree(){
        EBH_TestDataFactory.setUpCustomSettings();
        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = true;
        insert avr;
        Map<String,Account> accounts = EBH_TestDataFactory.setupAccountTriggerHandlerData();  
    	RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = accounts.get('le1').Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact; 
    	Contract contract = new Contract(RecordTypeId = ApexUtil.getRecordTypeByName('Contract','Refurbished').Id, 
            Name = 'Test Contract 1', 
            accountId = accounts.get('le1').Id,
            Status = EBH_ConstantsUtility.CONTRACT_DRAFTSTATUS,
            EBH_Site__c = 'UK',
            EBH_Language__c= 'English',
            Reason_for_Contract_Amendment__c = 'Seller / Brand Acquisition',
            EBH_RequesterNotes__c = 'test',
            Surcharge__c = true,
            PricingVersion__c = 'P1.0',
            StartDate = System.today(),
            EndDate = System.today() + 1,
            Business_Contact__c=contact.id
        );
        insert contract;
        Test.startTest();
        Contract c = [select Unique_Id__c from Contract where id =: contract.Id];
        	PageReference pageRef = Page.EBH_TrackingResponse;
	    	Test.setCurrentPage(pageRef);
	    	ApexPages.currentPage().getParameters().put('id', EncodingUtil.urlEncode(c.Unique_Id__c, 'UTF-8'));
	    	ApexPages.currentPage().getParameters().put('reURL', 'www.ebay.uk');
	    	ApexPages.currentPage().getParameters().put('restype', EBH_TrackingResponseController.CONRACT_URL_TYPE);
	    	
	    	EBH_TrackingResponseController con = new EBH_TrackingResponseController();
	    	con.checkResponse();
        Test.stopTest();
        Contract contractSel = [select Contract_Accept_Date__c, Contract_Signed_by__c from Contract where id =: contract.Id]; 
    	System.assertEquals(Date.Today(), contractSel.Contract_Accept_Date__c);
        System.assertEquals(contract.Business_Contact__c, contractSel.Contract_Signed_by__c);
    }
}