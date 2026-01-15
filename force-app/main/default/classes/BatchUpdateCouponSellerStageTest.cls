@isTest
/**
 * ...
 * 13/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
 */
private class BatchUpdateCouponSellerStageTest {
    
    @isTest 
    static void test_UpdateStage4ContactSigned () {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(EBH_RevRollup__c = 'US', Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc1;

        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
        Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c = 'ebay.com',Coupon_ID__c = 'testitembased',RecordTypeID = couponRecordTypeItem.Id, Coupon_Start_Time__c=Time.newInstance(0, 0, 0, 0), Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), Coupon_Start_Date__c=System.Today().addDays(-1), Coupon_End_Date__c=System.Today().addDays(2));
        insert c1;

        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Contract Signed', 
            Seller__c=acc1.Id,
            Cofund_Start_Date__c = Date.today());
        insert cs1;

        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage();
            bat.execute(null);

        Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c  FROM Coupon_Seller__c WHERE Id=:cs1.Id]) {
            System.assert(cs.Coupon_Seller_Stage__c == 'Coupon Running', 'Coupon Seller Stage should be "Coupon Running".');
            System.assert(cs.TriggerStageUpdatedDate__c != null);
        }

    }

    @isTest 
    static void test_UpdateStage4CouponRunning () {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(EBH_RevRollup__c = 'US', Name='Test Abc123',RecordTypeID = sellerRecordType.Id, EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc1;

        Date d1 = Date.today().addDays(-7);
        Date d2 = Date.today().addDays(-1);

        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
        Coupon__c c1 = new Coupon__c(
            Main_Coupon_Site__c = 'ebay.com',
            RecordTypeID = couponRecordTypeItem.Id, 
            Coupon_ID__c = 'testitembased',
            Coupon_Start_Time__c=Time.newInstance(0, 0, 0, 0), 
            Coupon_End_Time__c=Time.newInstance(0, 0, 0, 0), 
            Coupon_Start_Date__c=d1, 
            Coupon_End_Date__c=d2
        );
        insert c1;

       

        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Coupon Running', 
            Seller__c=acc1.Id,
            Cofund_Start_Date__c = d1,
            Cofund_End_Date__c = d2
        );
        insert cs1;

        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage();
            bat.execute(null);

        Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c  FROM Coupon_Seller__c WHERE Id=:cs1.Id]) {
            System.assert(cs.Coupon_Seller_Stage__c == 'Coupon executed', 'Coupon Seller Stage should be "Coupon executed".');
            System.assert(cs.TriggerStageUpdatedDate__c != null);
        }

    }

    @isTest 
    static void test_UpdateStage4PopCouponRunning() {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(EBH_RevRollup__c = 'US', Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc1;

        Date d1 = Date.today().addDays(-7);
        Date d2 = Date.today();

        RecordType couponRecordTypePopCP = ApexUtil.getRecordTypeByName('Coupon__c','Pop_Coupon');
        Coupon__c c1 = new Coupon__c(
            Main_Coupon_Site__c = 'ebay.com',
            RecordTypeID = couponRecordTypePopCP.Id, 
            Coupon_Start_Date__c = d1,
            Coupon_End_Date__c = d2,
            Contract_Due_Date__c = Date.today().addDays(-9),
            Coupon_Start_Time__c=Time.newInstance(5,0,0,0),
            Coupon_End_Time__c=Time.newInstance(23,59,0,0),
            Coupon_ID__c = 'TESTPOPCOUPON'
        );
        insert c1;

       
        RecordType cSRecordTypePopCP = ApexUtil.getRecordTypeByName('Coupon_Seller__c','Pop_Coupon');
        

        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Running', 
            Seller__c=acc1.Id,
            Cofund_Start_Date__c = d1,
            Cofund_End_Date__c = d2,
            RecordTypeId = cSRecordTypePopCP.Id
        );
        insert cs1;

        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage();
            bat.execute(null);

        Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c  FROM Coupon_Seller__c WHERE Id=:cs1.Id]) {
            System.assert(cs.Coupon_Seller_Stage__c == 'Contract Terminated', 'Coupon Seller Stage should be "Contract Terminated".');
            System.assert(cs.TriggerStageUpdatedDate__c != null);
        }

    }

    @isTest 
    static void test_UpdateStage4ContractAccepted() {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(EBH_RevRollup__c = 'US', Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc1;

        Date d1 = Date.today();
        Date d2 = Date.today().addDays(7);

        RecordType couponRecordTypePopCP = ApexUtil.getRecordTypeByName('Coupon__c','Pop_Coupon');
        Coupon__c c1 = new Coupon__c(
            
            RecordTypeID = couponRecordTypePopCP.Id, 
            Coupon_Start_Date__c = d1,
            Coupon_End_Date__c = d2,
            Contract_Due_Date__c = Date.today().addDays(-2),
            Coupon_Start_Time__c=Time.newInstance(5,0,0,0),
            Coupon_End_Time__c=Time.newInstance(23,59,0,0),
            Main_Coupon_Site__c = 'ebay.com',
            Coupon_ID__c = 'TESTPOPCOUPON'
        );
        insert c1;

       
        RecordType cSRecordTypePopCP = ApexUtil.getRecordTypeByName('Coupon_Seller__c','Pop_Coupon');
        

        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Contract Accepted', 
            Seller__c=acc1.Id,
            Cofund_Start_Date__c = d1,
            Cofund_End_Date__c = d2,
            RecordTypeId = cSRecordTypePopCP.Id
        );
        insert cs1;

        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage();
            bat.execute(null);

        Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c  FROM Coupon_Seller__c WHERE Id=:cs1.Id]) {
            System.assert(cs.Coupon_Seller_Stage__c == 'Running', 'Coupon Seller Stage should be "Running".');
            System.assert(cs.TriggerStageUpdatedDate__c != null);
        }

    }

    @isTest
    static void test_UpdateStage() {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(EBH_RevRollup__c = 'US', Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_BillingAddress__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc1;

        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
        Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c = 'ebay.com',Coupon_ID__c = 'testitembased',RecordTypeID = couponRecordTypeItem.Id, Coupon_Start_Time__c=Time.newInstance(0, 0, 0, 0), Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), Coupon_Start_Date__c=System.Today().addDays(-1), Coupon_End_Date__c=System.Today().addDays(2));
        insert c1;
        
        Account acc = [Select Id from Account where Name = 'Test Abc123'];
        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Contract Signed', 
            Seller__c=acc1.Id,
            Cofund_Start_Date__c = Date.today());
        insert cs1;

        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage(cs1.Id);
            bat.execute(null);

        Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c,Contract_Language__c,Coupon_Contract_Due_Date__c  FROM Coupon_Seller__c WHERE Id=:cs1.Id]) {
            System.assert(cs.Coupon_Seller_Stage__c == 'Coupon Running', 'Coupon Seller Stage should be "Coupon Running".');
            System.assert(cs.TriggerStageUpdatedDate__c != null);
        }
    }

    @TestSetup
    static void makeData(){
        
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',
                                         EBH_AccountContactRelationTrigger__c = true,
                                         EBH_AccountTrigger__c = true,
                                         EBH_AttachmentTrigger__c = true,
                                         EBH_BUApprovalGroupTrigger__c = true,
                                         EBH_CampaignApprovalGroupTrigger__c = true,
                                         EBH_CampaignKPITrigger__c = true,
                                         EBH_CampaignMemberTrigger__c = true,
                                         EBH_CampaignTrigger__c = true,
                                         EBH_ContactTrigger__c = true,
                                         EBH_ContentDocumentLinkTrigger__c = true,
                                         EBH_ContentDocumentTrigger__c = true,
                                         EBH_ContractApprovalHierarchyTrigger__c = true,
                                         EBH_ContractApprovalMatrixTrigger__c = true,
                                         EBH_ContractTrigger__c = true,
                                         Coupon__c = false, //Disable Coupon Trigger so that we can use Batch to sync data
                                         Coupon_Category__c = true,
                                         Coupon_Co_Invest__c = true,
                                         Coupon_Item__c = true,
                                         Coupon_Seller__c = true,
                                         EBH_CustomCampaignMemberTrigger__c = true,
                                         EBH_DocuSignStatusTrigger__c = true,
                                         EBH_ExecuteContractUpdateBatch__c = true,
                                         EBH_FeedItemTrigger__c = true,
                                         Final_value_Fee__c = true,                                         
                                         EBH_KPIResultTrigger__c = true,                                         
                                         Nominated_Item__c = true,
                                         EBH_PricingTrigger__c = true,                                          
                                         EBH_SellerListTrigger__c = true,                                          
                                         EBH_EnableUrgencyEmail__c = true,
                                         EBH_TargetedSellerTrigger__c = true,
                                         EBH_TaskTrigger__c = true,
                                         EBH_TicketTrigger__c = true,
                                         EBH_User__c = true,
                                         DealTrigger__c = true,
                                         Coupon_Send_BCD_File_To_DL__c =true,
                                         Coupon_Seller_Send_T4_T40_to_seller__c =true,
                                         CaseTrigger__c =true
                                        ); 
		ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;   

    }
    
	@isTest 
    static void test_UpdateStage4SellerDeclined () {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        Account acc2 = new Account(EBH_RevRollup__c = 'US', Name='Test Abc123',RecordTypeID = sellerRecordType.Id, EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert new List<Account>{acc1, acc2};

        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
        Coupon__c c1 = new Coupon__c(
        Main_Coupon_Site__c = 'ebay.com.au',
        RecordTypeID = couponRecordTypeItem.Id,
        Coupon_ID__c = 'testitembased',
        Coupon_Start_Time__c=now.timeGmt(),
        Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000),
        Coupon_Start_Date__c=System.Today(),
        Coupon_End_Date__c=System.Today().addDays(2),
        Contract_Due_Date__c=System.Today().addDays(-1)
        );
        Coupon__c c2 = new Coupon__c(
        Main_Coupon_Site__c = 'ebay.com',
        RecordTypeID = couponRecordTypeItem.Id, 
        Coupon_ID__c = 'testitembased',
        Coupon_Start_Time__c=now.timeGmt(), 
        Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), 
        Coupon_Start_Date__c=System.Today(), 
        Coupon_End_Date__c=System.Today().addDays(2),
        Contract_Due_Date__c=System.Today().addDays(-3)
        );
        insert new List<Coupon__c>{c1, c2};

        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Contract Signed', 
            Seller__c=acc1.Id,
            Cofund_Start_Date__c = Date.today().addDays(-2));
        Coupon_Seller__c cs2 = new Coupon_Seller__c(
            Coupon__c = c2.Id,
            Coupon_Seller_Stage__c='Contract Signed', 
            Seller__c=acc2.Id,
            Cofund_Start_Date__c = Date.today().addDays(-2));
        insert new List<Coupon_Seller__c>{cs1, cs2};

        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage();
            bat.execute(null);

        Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Contract_Language__c, Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c  FROM Coupon_Seller__c WHERE Id IN:(new List<Id>{cs1.Id, cs2.Id})]) {
            
            System.assert(cs.Coupon_Seller_Stage__c == 'Seller Declined', 'Coupon Seller Stage should be "Seller Declined".');
            System.assert(cs.TriggerStageUpdatedDate__c != null, 'TriggerStageUpdatedDate__c should not be null.');
        }

    }

    @isTest 
    static void test_UpdateStage4SellerDeclined_AllowReAcceptContract () {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(EBH_RevRollup__c = 'US', Name='Test Abc123',RecordTypeID = sellerRecordType.Id, EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc1;

        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
        Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c = 'ebay.com',RecordTypeID = couponRecordTypeItem.Id,Coupon_ID__c = 'testitembased', Coupon_Start_Time__c=now.timeGmt(), Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), Coupon_Start_Date__c=System.Today(), Coupon_End_Date__c=System.Today().addDays(2),Contract_Due_Date__c=System.Today().addDays(-1));
        insert c1;

        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Contract Signed', 
            Seller__c=acc1.Id,
            Allow_reaccept_contract__c = true,
            Cofund_Start_Date__c = Date.today().addDays(-2));
        insert cs1;

        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage();
            bat.execute(null);

        Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c  FROM Coupon_Seller__c WHERE Id=:cs1.Id]) {
            
            System.assert(cs.Coupon_Seller_Stage__c != 'Seller Declined', 'Coupon Seller Stage should not be "Seller Declined". Because Allow_reaccept_contract__c = true');
            System.assert(cs.TriggerStageUpdatedDate__c != null);
        }

    }

    @isTest 
    static void test_UpdateStage4SellerDeclined_AllowReAcceptContrac_ContractSend_CouponEndDate () {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(EBH_RevRollup__c = 'US', Name='Test Abc123',RecordTypeID = sellerRecordType.Id, EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc1;

        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
        Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c = 'ebay.com',RecordTypeID = couponRecordTypeItem.Id,Coupon_ID__c = 'testitembased', Coupon_Start_Time__c=now.timeGmt(), Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), Coupon_Start_Date__c=System.Today().addDays(-2), Coupon_End_Date__c=System.Today().addDays(-1),Contract_Due_Date__c=System.Today().addDays(-3));
        insert c1;

        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Contract Send', 
            Seller__c=acc1.Id,
            Allow_reaccept_contract__c = true,
            Cofund_Start_Date__c = Date.today().addDays(-2));
        insert cs1;

        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage();
            bat.execute(null);

        Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c, Seller_Declined_Reasons__c  FROM Coupon_Seller__c WHERE Id=:cs1.Id]) {
            
            System.assert(cs.Coupon_Seller_Stage__c == 'Seller Declined', 'Coupon Seller Stage should be "Seller Declined"');
            System.assert(cs.Seller_Declined_Reasons__c == 'Seller did not respond', 'Coupon Seller Declined Reason should be "Seller did not respond"');
        }

    }

    @isTest 
    static void test_UpdateStage4SellerDeclined_AllowReAcceptContrac_CouponEndDate () {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(EBH_RevRollup__c = 'US', Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc1;

        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
        Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c = 'ebay.com',RecordTypeID = couponRecordTypeItem.Id,Coupon_ID__c = 'testitembased', Coupon_Start_Time__c=now.timeGmt(), Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), Coupon_Start_Date__c=System.Today().addDays(-2), Coupon_End_Date__c=System.Today().addDays(-1),Contract_Due_Date__c=System.Today().addDays(-3));
        insert c1;

        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Contract Signed', 
            Seller__c=acc1.Id,
            Allow_reaccept_contract__c = true,
            Cofund_Start_Date__c = Date.today().addDays(-2));
        insert cs1;

        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage();
            bat.execute(null);

        Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c, Seller_Declined_Reasons__c  FROM Coupon_Seller__c WHERE Id=:cs1.Id]) {
            
            System.assert(cs.Coupon_Seller_Stage__c == 'Seller Declined', 'Coupon Seller Stage should be "Seller Declined"');
            System.assert(cs.Seller_Declined_Reasons__c == 'Contract Voided', 'Coupon Seller Declined Reason should be "Contract Voided"');
        }

    }
    
    
    @isTest 
    static void test_UpdateStage4CACouponRunning () {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(EBH_RevRollup__c = 'CA', Name='Test Abc123',RecordTypeID = sellerRecordType.Id, EBH_BillingCity__c='pp',EBH_BillingCountry__c='CA',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc1;

        Date d1 = Date.today().addDays(-7);
        Date d2 = Date.today().addDays(-1);

        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
        Coupon__c c1 = new Coupon__c(
            Main_Coupon_Site__c = 'ebay.ca',
            RecordTypeID = couponRecordTypeItem.Id, 
            Coupon_ID__c = 'testitembased',
            Coupon_Start_Time__c=Time.newInstance(0, 0, 0, 0), 
            Coupon_End_Time__c=Time.newInstance(0, 0, 0, 0), 
            Coupon_Start_Date__c=d1, 
            Coupon_End_Date__c=d2
        );
        insert c1;
       

        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Coupon Running', 
            Seller__c=acc1.Id,
            Cofund_Start_Date__c = d1,
            Cofund_End_Date__c = d2
        );
        insert cs1;
        
        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage();
            bat.execute(null);

        Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c  FROM Coupon_Seller__c WHERE Id=:cs1.Id]) {
            System.assert(cs.Coupon_Seller_Stage__c == 'Coupon executed', 'Coupon Seller Stage should be "Coupon executed".');
            System.assert(cs.TriggerStageUpdatedDate__c != null);
        }

    }
    @isTest 
    static void test_UpdateStage4PastEnddateCouponRunning () {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(EBH_RevRollup__c = 'CA', Name='Test Abc123',RecordTypeID = sellerRecordType.Id, EBH_BillingCity__c='pp',EBH_BillingCountry__c='CA',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc1;

        Date d1 = Date.today().addDays(-10);
        Date d2 = Date.today().addDays(-1);

        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
        Coupon__c c1 = new Coupon__c(
            Main_Coupon_Site__c = 'ebay.ca',
            RecordTypeID = couponRecordTypeItem.Id, 
            Coupon_ID__c = 'testitembased',
            Coupon_Start_Time__c=Time.newInstance(0, 0, 0, 0), 
            Coupon_End_Time__c=Time.newInstance(0, 0, 0, 0), 
            Coupon_Start_Date__c=d1, 
            Coupon_End_Date__c=d2
        );
        insert c1;
        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Coupon Running', 
            Seller__c=acc1.Id,
            Cofund_Start_Date__c = d1,
            Cofund_End_Date__c = d2
        );
        insert cs1;
        
        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage();
            bat.execute(null);

        Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c  FROM Coupon_Seller__c WHERE Id=:cs1.Id]) {
            System.assert(cs.Coupon_Seller_Stage__c == 'Coupon executed', 'Coupon Seller Stage should be "Coupon executed".');
            System.assert(cs.TriggerStageUpdatedDate__c != null);
        }

    }
    @isTest 
    static void test_UpdateStage4PastEnddateCouponRunning_negativecase () {

        DateTime now = System.now();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(EBH_RevRollup__c = 'US', Name='Test Abc123',RecordTypeID = sellerRecordType.Id, EBH_BillingCity__c='pp',EBH_BillingCountry__c='CA',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc1;

        Date d1 = Date.today().addDays(-20);
        Date d2 = Date.today().addDays(-9);

        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
        Coupon__c c1 = new Coupon__c(
            Main_Coupon_Site__c = 'ebay.com',
            RecordTypeID = couponRecordTypeItem.Id, 
            Coupon_ID__c = 'testitembased',
            Coupon_Start_Time__c=Time.newInstance(0, 0, 0, 0), 
            Coupon_End_Time__c=Time.newInstance(0, 0, 0, 0), 
            Coupon_Start_Date__c=d1, 
            Coupon_End_Date__c=d2
        );
        insert c1;

        Coupon_Seller__c cs1 = new Coupon_Seller__c(
            Coupon__c = c1.Id,
            Coupon_Seller_Stage__c='Coupon Running', 
            Seller__c=acc1.Id,
            Cofund_Start_Date__c = d1,
            Cofund_End_Date__c = d2
        );
        insert cs1;
        
        Test.startTest();

            BatchUpdateCouponSellerStage bat = new BatchUpdateCouponSellerStage();
            bat.execute(null);

        Test.stopTest();
        
        for (Coupon_Seller__c cs : [SELECT Coupon_Seller_Stage__c, TriggerStageUpdatedDate__c  FROM Coupon_Seller__c WHERE Id=:cs1.Id]) {
            System.assertNotEquals(cs.Coupon_Seller_Stage__c, 'Coupon Executed', 'Coupon Seller Stage should not be "Coupon Executed".');
        }

    }
    

}