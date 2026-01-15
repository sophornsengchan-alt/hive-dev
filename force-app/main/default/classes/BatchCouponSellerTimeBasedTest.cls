@isTest
private class BatchCouponSellerTimeBasedTest {

    @isTest
	static void test_BatchCouponSellerTimeBased() {

        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        RecordType recDWH = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
        Account portalAccount1, portalAccount2, portalAccount3;
        Contact contact1, contact2;
		RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        Coupon__c c1, c2, c3;

        //Create account
        portalAccount1 = new Account(
            Name = 'Test Seller Account',
            eBay_API_User_Id__c = 'test_test_test',
            RecordTypeId = recSeller.Id,
            SP_Coupons__c = 'Full Access',
            EBH_RevRollup__c='US',
            EBH_EmailOut__c = false
        );    

        portalAccount2 = new Account(
            Name = 'Test Seller Account 2',
            eBay_API_User_Id__c = 'test_test_test',
            RecordTypeId = recSeller.Id,
            SP_Coupons__c = 'Full Access',
            EBH_RevRollup__c='AU',
            EBH_EmailOut__c = false
        ); 

        portalAccount3 = new Account(
            Name = 'Test Seller Account 3',
            eBay_API_User_Id__c = 'test_test_test',
            RecordTypeId = recSeller.Id,
            SP_Coupons__c = 'Full Access',
            EBH_RevRollup__c='UK',
            EBH_EmailOut__c = false
        ); 

        insert new List<Account>{portalAccount1, portalAccount2, portalAccount3};

        //Create contact
        contact1 = new Contact(
            FirstName = 'Test',
            Lastname = 'SEP Contact',
            AccountId = portalAccount1.Id,
            Email = System.now().millisecond() + 'test@test.sep.com',
            recordTypeId = recDWH.Id
        );

        contact2 = new Contact(
            FirstName = 'Test',
            Lastname = 'SEP Contact UK',
            AccountId = portalAccount3.Id,
            Email = System.now().millisecond() + 'test@test.sepuk.com',
            recordTypeId = recDWH.Id
        );            
        insert new Contact[]{contact1, contact2};

        
        c1 = new Coupon__c(
            Main_Coupon_Site__c = 'ebay.com',
            MC_Whitelisted__c = true,
            Stage__c = 'Draft', 
            RecordTypeID = couponRecordTypeItem.Id,
            Coupon_Start_Date__c = Date.today().addDays(7),
            Coupon_End_Date__c=Date.today().addDays(14),
            Contract_Due_Date__c = Date.today().addDays(2),
            Marketing_Coupon_Name__c = 'Test Marketing Coupon Name',
            Coupon_ID__c = 'TestCouponID'
        );

        c2 = new Coupon__c(
            Main_Coupon_Site__c = 'ebay.com.au',
            MC_Whitelisted__c = true,
            Stage__c = 'Draft', 
            RecordTypeID = couponRecordTypeItem.Id,
            Coupon_Start_Date__c = Date.today().addDays(7),
            Coupon_End_Date__c=Date.today().addDays(14),
            Contract_Due_Date__c = Date.today().addDays(1),
            Marketing_Coupon_Name__c = 'Test Marketing Coupon Name',
            Coupon_ID__c = 'TestCouponID'
        );

        c3 = new Coupon__c(
            Main_Coupon_Site__c = 'ebay.co.uk',
            MC_Whitelisted__c = true,
            Stage__c = 'Draft', 
            RecordTypeID = couponRecordTypeItem.Id,
            Coupon_Start_Date__c = Date.today().addDays(2),
            Coupon_End_Date__c=Date.today().addDays(14),
            Contract_Due_Date__c = Date.today(),
            Marketing_Coupon_Name__c = 'Test Marketing Coupon Name',
            Coupon_ID__c = 'TestCouponID'
        );
        insert new List<Coupon__c>{c1, c2, c3};

        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Contract Send',Seller_Contact__c=contact1.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = portalAccount1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
        Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c2.Id,Coupon_Seller_Stage__c='Contract Send',EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = portalAccount2.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
        Coupon_Seller__c cs3 = new Coupon_Seller__c(Coupon__c = c3.Id,Coupon_Seller_Stage__c='Contract Signed',Seller_Contact__c=contact2.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = portalAccount3.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
        insert new List<Coupon_Seller__c>{cs1, cs2, cs3};

    	
    	Test.startTest();

            new BatchCouponSellerTimeBased().execute(null);

    	Test.stopTest();

        List<Seller_Communication__c> lstResult = [SELECT Id, Coupon_Seller__c, Email_Template__c, Region__c, Day_Before_Reminder__c FROM Seller_Communication__c];

        System.assert( !lstResult.isEmpty(), 'There should be at least one Seller_Communication__c record created.');
        
    }
    
    @testSetup 
    static void setupData(){
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


}