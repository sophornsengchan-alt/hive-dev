/**
 * ...
 * 13/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
 */
@isTest
private class BatchSyncCouponFieldsToCouponSellerTest {

    @isTest
	static void test_BatchSyncCouponFieldsToCouponSeller() {

        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        Account portalAccount1;
        Contact contact1;
		RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        Coupon__c c1;
		User user1;
        System.runAs(admins[0])
        {
            //Create account
            portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id,
                EBH_RevRollup__c = 'US'
            );            
            insert new List<Account>{portalAccount1};

            //Create contact
            contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com'
            );            
            insert new Contact[]{contact1};

			
			c1 = new Coupon__c(
				Main_Coupon_Site__c = 'ebay.com',
				MC_Whitelisted__c = true,
				Stage__c = 'Draft', 
				RecordTypeID = couponRecordTypeItem.Id,
				Coupon_Start_Date__c = System.today(),
				Coupon_End_Date__c=System.today(),
				Contract_Due_Date__c = System.today()-1,
				Marketing_Coupon_Name__c = 'Test Marketing Coupon Name',
				Coupon_ID__c = 'TestCoupon123'
			);
			insert new List<Coupon__c>{c1};

			RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c=contact1.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = portalAccount1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
			insert cs1;
        }
        
        
        System.runAs(admins[1])
        {
			
            PermissionSetGroup psg = [select Id, Status from PermissionSetGroup where DeveloperName='Seller_Portal_DE'];
            // force calculation of the PSG if it is not already Updated
            if (psg.Status != 'Updated') {
                Test.calculatePermissionSetGroup(psg.Id);
            }

            //Create user

            user1 = SEPTestGenerator.createSEPUser('sepUserbscftcs1', contact1.Id);

            /* MN-10062024-US-0015298
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'NA - Seller Portal' LIMIT 1];
            user1 = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'AMT_TEST',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Permission_Sets__c = 'Seller_Portal_DE'
            );
            
            insert new User[]{user1};
            */ 
        }   

    	
    	Test.startTest();

		System.runAs(admins[0])
        {
			contact1.Community_User__c = user1.Id;
			update contact1;

            c1.Marketing_Coupon_Name__c = 'Update Test Marketing Coupon Name';
			c1.Coupon_ID__c = 'TestCoupon1234';
			update c1;

			BatchSyncCouponFieldsToCouponSeller bat = new BatchSyncCouponFieldsToCouponSeller();
            bat.execute(null);
		
        }
    	
    	Test.stopTest();

        for (Coupon_Seller__c cs : [SELECT Coupon_Marketing_Name__c, Coupon_Code__c FROM Coupon_Seller__c WHERE Coupon__c=:c1.Id]) {
            System.assertEquals('Update Test Marketing Coupon Name', cs.Coupon_Marketing_Name__c, 'The Coupon Marketing Name should be update to "Update Test Marketing Coupon Name"');
            System.assertEquals('TestCoupon1234', cs.Coupon_Code__c, 'The Coupon Code should be update to "Update Test Coupon ID"');
        }
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