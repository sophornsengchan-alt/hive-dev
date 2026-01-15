/*********************************************************************************************************************************
@ Class:          CouponCategoryTriggerHandlerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        test Class for trigger Coupon Category
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.04.2019 / Sovantheany Dim / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.08.202 / Mony Nou  / US-0009746 - Coupon - enable deletion of coupon related records
*********************************************************************************************************************************/
@isTest
private class CouponCategoryTriggerHandlerTest {
    static testmethod void setupData(){
        EBH_TestDataFactory.setUpCustomSettings();   
        
       
    }
    static testMethod void TestInsertCouponCategoryAndCouponSeller() {
        setupData();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Map<String,RecordType> couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c = 'US');
    	insert acc;
    	Account acc2 = new Account(Name='Test Abc2',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c = 'US');
        insert acc2;
        Account acc3 = new Account(Name='Test Abc3',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c = 'US');
        insert acc3;
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id,Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCoupon123');
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id);
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc2.Id);
    	insert new List<Coupon_Seller__c>{cs1,cs2};
    	Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0,Active__c=true); // added active__c =true by DHE on 2020-07-09 to fix test class
    	Category_Tree__c ct2 = new Category_Tree__c(Name = 'testCategoryTree2',Level__c = 1,Note_ID__c=ct1.Id,Active__c=true);
		Category_Tree__c ct3 = new Category_Tree__c(Name = 'testCategoryTree3',Level__c = 1,Active__c=true);
		Category_Tree__c ct4 = new Category_Tree__c(Name = 'testCategoryTree4',Level__c = 0, Active__c=true);
    	insert new List<Category_Tree__c>{ct1,ct2,ct3,ct4};
    	Coupon_Category__c cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct4.Id);
    	Coupon_Category__c cc2 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct2.Id);
    	insert new List<Coupon_Category__c>{cc1,cc2};
    	//update coupon stage to negotiation
		c1.Stage__c = EBH_ConstantsUtility.COUPON_SELLER_NEGOTIATION_STAGE;
		update c1;
		
		//assertion after coupon change status to Seller Negotiation
		for(Coupon_Co_Invest__c coInvest : [select id, Coupon_Category__c,Coupon_Name__c, Seller_Name__c , RecordTypeId, RecordType.DeveloperName from Coupon_Co_Invest__c where Coupon_Name__c =: c1.Id]){
    		if(coInvest.Coupon_Category__c == cc1.Id){
    			System.assertEquals(EBH_ConstantsUtility.CO_INVEST_SELLER, coInvest.RecordType.DeveloperName, 'Rule i : Coupon Co-Invest Seller when Coupon Object Record type: Seller/Category based and Coupon Stage in "Seller Negotiation" and Coupon Level = 0');
    		}else if(coInvest.Coupon_Category__c == cc2.Id){
    			System.assertEquals(EBH_ConstantsUtility.CO_INVEST_CATEGORY, coInvest.RecordType.DeveloperName, 'Rule ii : Coupon Co-Invest Category when Coupon Object Record type: Seller/Category based and Coupon Stage in "Seller Negotiation" and Coupon Level > 0');
    		}
    	}
        Test.startTest();

        Coupon_Category__c cc3 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct3.Id);
        insert cc3;
        Coupon_Seller__c cs3 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc3.Id);
        insert cs3;
        Test.stopTest();
        
        //assertion to coinvest should be 9
        List<Coupon_Co_Invest__c> lstCoInvestCreated = [select id from Coupon_Co_Invest__c where Coupon_Name__c =: c1.Id];
        System.assertEquals(9,lstCoInvestCreated.size(),'total co invest should be 9');
        
    }

	static testMethod void blockDuplicatedCategoryTest() {
		setupData();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Map<String,RecordType> couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');

		Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id);
    	insert acc;

		Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id,Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCoupon1');
		Coupon__c c2 = new Coupon__c(RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id,Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCoupon2');
		insert new List<Coupon__c> {c1,c2};

		Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0,Active__c=true);// added active__c =true by DHE on 2020-07-09 to fix test class
		Category_Tree__c ct2 = new Category_Tree__c(Name = 'testCategoryTree2',Level__c = 0,Active__c=true);
    	insert new List<Category_Tree__c> {ct1,ct2};

		Coupon_Category__c cc1 = new Coupon_Category__c(Category__c = ct1.Id,Coupon__c = c1.Id);
		Coupon_Category__c cc3 = new Coupon_Category__c(Category__c = ct2.Id,Coupon__c = c2.Id);
		insert new List<Coupon_Category__c>{cc1,cc3};
	
		//test.startTest();
		try {
			cc3.Category__c = cc1.Category__c;
			cc3.Coupon__c = cc1.Coupon__c;
			update cc3;
			
			Coupon_Category__c cc2 = new Coupon_Category__c(Category__c = cc3.Category__c,Coupon__c = cc3.Coupon__c);
			insert cc2;
		
		} catch (Exception e) {
			System.assert(e.getMessage().contains(Label.ErrMsg_duplicateCategory), 'System should alert error message = \'Label.ErrMsg_duplicateCategory\', Actual = \''+e.getMessage()+'\'');
		}
		//test.stopTest();
	}

	@isTest
	static void test_preventRecordDeletion() {

		setupData();
    	
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Map<String,RecordType> couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');

		Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id);
    	insert acc;

		Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id,Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCoupon123');
		insert new List<Coupon__c> {c1};

		c1.Stage__c='T4 Statement Send';
		update c1;

		Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0,Active__c=true);// added active__c =true by DHE on 2020-07-09 to fix test class
		insert new List<Category_Tree__c> {ct1};

		Coupon_Category__c cc1 = new Coupon_Category__c(Category__c = ct1.Id,Coupon__c = c1.Id);
		insert new List<Coupon_Category__c>{cc1};
	
		Test.startTest();
			try {
				delete cc1;
			} catch (Exception ex) { 
				System.assert(ex.getMessage().contains(System.Label.Prevent_Deletion_of_Coupon_Category));
			}
			
		Test.stopTest();
	}
	
}