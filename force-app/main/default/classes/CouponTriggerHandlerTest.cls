/*********************************************************************************************************************************
 @ Class:          CouponTriggerHandlerTest
 @ Version:        1.0
 @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
 @ Purpose:        test Handler Class for trigger Coupon
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.04.2019 /  Sovantheany Dim / Created the class.
@				: 16.06.2023 / Chetra Sarom / US-0013475 - Deactivate redundant Coupon Approval process & email
@ Change history:  14.12.2023 / Vimean Heng / Fix lock row.
*********************************************************************************************************************************/
@isTest
private class CouponTriggerHandlerTest {
	    static testmethod void setupData(){
        EBH_TestDataFactory.setUpCustomSettings();
		ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;   
        
       
    }
    static testMethod void testDraftDefault() {
        setupData();
		RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        
        Test.startTest();
        	//Coupon__c c1 = new Coupon__c();
			//insert c1;
			Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordTypeItem.Id,Main_Coupon_Site__c = 'ebay.de',Coupon_Co_invest_Type__c='Contra',Coupon_ID__c='TestCoupon001');
			insert c1;
        Test.stopTest();
        Coupon__c c = [select stage__c from Coupon__c where id =: c1.Id];
        System.assertEquals('Draft',c.stage__c,'1 coupon is create with default value set to Draft');
    }
    
    static testMethod void testPopulateDateTimeAuto()
    {
        setupData();
    	DateTime now1 = System.now();
    	
    	Coupon__c c1 = new Coupon__c(Coupon_Start_Date__c=now1.date(),Coupon_Start_Time__c=now1.timeGmt(),Coupon_End_Date__c=now1.addDays(1).date(), Coupon_end_Time__c=now1.timeGmt(),Main_Coupon_Site__c = 'ebay.de',Coupon_Co_invest_Type__c='Contra',Coupon_ID__c='TestCoupon001');
    	insert c1;
    	
    	Test.startTest();
    	
    		Coupon__c csell = [Select Start_Date_Time__c,End_Date_Time__c, Id from Coupon__c Where Id =:c1.Id];
    		System.assertNotEquals(null,csell.Start_Date_Time__c,' populated from the combination of date and time');
    		System.assertNotEquals(null,csell.End_Date_Time__c,' populated from the combination of date and time');
    		
    		c1.Coupon_End_Date__c = now1.addDays(3).date();
    		c1.Coupon_Start_Date__c = now1.addDays(1).date();
    		update  c1;
    	Test.stopTest(); 
    }
    
    static testMethod void testcreateCoInvestWithRecordType()
    {
        setupdata();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Map<String,RecordType> couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='DE', EBH_EmailOut__c = false, SP_Coupons__c = 'Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	Account acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='DE', EBH_EmailOut__c = false, SP_Coupons__c = 'Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert new List<Account>{acc,acc2};
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id,Main_Coupon_Site__c = 'ebay.de',Coupon_Co_invest_Type__c='Contra',Coupon_ID__c='TestCoupon001');
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id);
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc2.Id);
    	insert new List<Coupon_Seller__c>{cs1,cs2};
    	Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0,Active__c=true);
    	insert ct1;
    	Category_Tree__c ct2 = new Category_Tree__c(Name = 'testCategoryTree2',Level__c = 1,Note_ID__c=ct1.Id,Active__c=true);
    	insert ct2;
    	Coupon_Category__c cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct1.Id);
    	Coupon_Category__c cc2 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct2.Id);
    	insert new List<Coupon_Category__c>{cc1,cc2};
    	Test.startTest();
    	//update coupon stage to negotiation
		c1.Stage__c = EBH_ConstantsUtility.COUPON_SELLER_NEGOTIATION_STAGE;
		update c1;
    	Test.stopTest();
    	for(Coupon_Co_Invest__c coInvest : [select id, Coupon_Category__c,Coupon_Name__c, Seller_Name__c , RecordTypeId, RecordType.DeveloperName from Coupon_Co_Invest__c where Coupon_Name__c =: c1.Id]){
    		if(coInvest.Coupon_Category__c == cc1.Id){
    			System.assertEquals(EBH_ConstantsUtility.CO_INVEST_SELLER, coInvest.RecordType.DeveloperName, 'Rule i : Coupon Co-Invest Seller when Coupon Object Record type: Seller/Category based and Coupon Stage in "Seller Negotiation" and Coupon Level = 0');
    		}else if(coInvest.Coupon_Category__c == cc2.Id){
    			System.assertEquals(EBH_ConstantsUtility.CO_INVEST_CATEGORY, coInvest.RecordType.DeveloperName, 'Rule ii : Coupon Co-Invest Category when Coupon Object Record type: Seller/Category based and Coupon Stage in "Seller Negotiation" and Coupon Level > 0');
    		}
    	}
    }
    
    static testMethod void testcreateCoInvestWithRecordTypeAndAuCouponSite()
    {
        setupdata();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Map<String,RecordType> couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,Coupon_Funding_Preference__c = 'Strategic',Strategic_Seller_Share_w__c='40', EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert new List<Account>{acc};
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id,Couponsite_s__c='ebay.com.au',Main_Coupon_Site__c = 'ebay.com.au',Coupon_Co_invest_Type__c='Contra',Coupon_ID__c='TestCoupon001');
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id);
    	insert new List<Coupon_Seller__c>{cs1};
    	Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0,Active__c=true);
    	insert ct1;
    	Coupon_Category__c cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct1.Id);
    	insert new List<Coupon_Category__c>{cc1};
    	Test.startTest();
    	//update coupon stage to negotiation
		c1.Stage__c = EBH_ConstantsUtility.COUPON_SELLER_NEGOTIATION_STAGE;
		update c1;
    	Test.stopTest();
    	for(Coupon_Co_Invest__c coInvest : [select Co_Invest__c from Coupon_Co_Invest__c where Coupon_Name__c =: c1.Id]){
    			System.assertEquals(coInvest.Co_Invest__c, 40, 'When the Couponsite_s__c = "ebay.com.au" and change the stage Coupon Stage to "Seller Negotiation", auto-populate the Seller Share % with strategic seller share from seller');
    	}
    }
    
	/*
	static testMethod void testsetEmailManhattan(){
        setupdata();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Map<String,RecordType> couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id);
    	Account acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id);
    	insert new List<Account>{acc,acc2};
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id);
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id);
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc2.Id);
    	insert new List<Coupon_Seller__c>{cs1,cs2};
    	Test.startTest();
    	c1.Coupon_End_Date__c = System.today()-4;
    	c1.Coupon_end_Time__c = System.now().timeGmt();
    	update c1;
    	Test.stopTest();
    	//for(Coupon_Seller__c cs : [select TriggerEmailManhattan__c from Coupon_Seller__c where Coupon__c =: c1.Id]){
    	//	System.assert(cs.TriggerEmailManhattan__c == true);
    	//}	
    }
    */
	// 20.05.2022 / Loumang SENG / US-0011328 - Deprecate the function to Send BCD file via email to Finance DL after Coupon ended
    /*static testMethod void testsendBCDFileEmail(){
        setupdata();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id);
    	Account acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id);
    	insert new List<Account>{acc,acc2};
    	Coupon__c c1 = new Coupon__c(Coupon_Start_Date__c=Date.Today(),Coupon_End_Date__c = Date.toDay().addDays(4));
		insert c1;
		Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,Contract_Accept_Date__c= System.now(),Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_EXEC); 
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc2.Id,Contract_Accept_Date__c= System.now(),Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_T4);
    	insert new List<Coupon_Seller__c>{cs1,cs2};
		Test.startTest();
		c1.Trigger4DayAfterEndDate__c = System.now();
		c1.Trigger34DayAfterEndDate__c =  System.now();
		update c1;
		Test.stopTest();
		//List<Attachment> lsAtt = [select Name from Attachment where ParentId =: c1.Id];
		//System.assert(lsAtt[0].Name == 'BCD_File.csv');
    }*/
    @future
    public static void insertBusinessAdm(){
        Profile p =[SELECT Id, Name FROM Profile WHERE Name = 'Business Admin'];
	        
        User businessAdm = new User(Alias             = 'usr', 
                            Email             = 'usr' + Math.random() + '@org.com', 
                            EmailEncodingKey  = 'UTF-8', 
                            LastName          = 'Testing' + Math.random(), 
                            LanguageLocaleKey = 'en_US', 
                            LocaleSidKey      = 'en_US', 
                            ProfileId         = p.Id, 
                            TimeZoneSidKey    = 'America/Los_Angeles',
                            UserName          = 'usr' + Math.random() + '@org.com',
                            IsActive = true,
                            Competency__c = 'Copy');   
                        
		insert businessAdm;
    	PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name =: EBH_ConstantsUtility.PERMISSION_SET_PROMO];
		insert new PermissionSetAssignment(AssigneeId = businessAdm.id, PermissionSetId = ps.Id);
    }
    static testMethod void testblockManualSetStageWhenCreate(){
        
        setupdata();
        CouponTriggerHandlerTest.insertBusinessAdm();
   /* 	Profile p =[SELECT Id, Name FROM Profile WHERE Name = 'Business Admin'];
	        
        User businessAdm = new User(Alias             = 'usr', 
                            Email             = 'usr' + Math.random() + '@org.com', 
                            EmailEncodingKey  = 'UTF-8', 
                            LastName          = 'Testing' + Math.random(), 
                            LanguageLocaleKey = 'en_US', 
                            LocaleSidKey      = 'en_US', 
                            ProfileId         = p.Id, 
                            TimeZoneSidKey    = 'America/Los_Angeles',
                            UserName          = 'usr' + Math.random() + '@org.com',
                            IsActive = true,
                            Competency__c = 'Copy');   
                        
		insert businessAdm;
    	PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name =: EBH_ConstantsUtility.PERMISSION_SET_PROMO];
		insert new PermissionSetAssignment(AssigneeId = businessAdm.id, PermissionSetId = ps.Id);
    	System.RunAs(businessAdm){*/
        //setupdata();
        CouponTriggerHandlerTest.insertBusinessAdm();
    		Test.startTest();
    		try {
    			Coupon__c c1 = new Coupon__c(Stage__c = 'Coupon Running',Main_Coupon_Site__c = 'ebay.de',Coupon_Co_invest_Type__c='Contra',Coupon_ID__c='TestCoupon001');
				insert c1;
        	}catch(Exception e) {
        		System.assert(e.getMessage().contains(EBH_ConstantsUtility.COUPON_ERROR_MSG));
        	}
    		Test.stopTest();
    //	} commented by DHE
    	
    }
    
    static testMethod void testblockManualSetStageWhenUpdated(){
    	/*Profile p =[SELECT Id, Name FROM Profile WHERE Name = 'Business Admin'];
	        
       User businessAdm = new User(Alias             = 'usr', 
                            Email             = 'usr' + Math.random() + '@org.com', 
                            EmailEncodingKey  = 'UTF-8', 
                            LastName          = 'Testing' + Math.random(), 
                            LanguageLocaleKey = 'en_US', 
                            LocaleSidKey      = 'en_US', 
                            ProfileId         = p.Id, 
                            TimeZoneSidKey    = 'America/Los_Angeles',
                            UserName          = 'usr' + Math.random() + '@org.com',
                            IsActive = true,
                            Competency__c = 'Copy');   
                        
		insert businessAdm;
    	PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name =: EBH_ConstantsUtility.PERMISSION_SET_PROMO];
		insert new PermissionSetAssignment(AssigneeId = businessAdm.id, PermissionSetId = ps.Id);
    	System.RunAs(businessAdm){*/
        setupdata();
        CouponTriggerHandlerTest.insertBusinessAdm();
        
        
         		Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c = 'ebay.com.au',Coupon_Co_invest_Type__c='Contra',Coupon_ID__c='TestCoupon001');
			insert c1;
    		Test.startTest();
    		try {
				c1.Stage__c = 'Coupon Executed';
				update c1;
        	}catch(Exception e) {
        		System.assert(e.getMessage().contains(EBH_ConstantsUtility.COUPON_ERROR_MSG));
        	}
    		Test.stopTest();
    	//} commented by DHE
    	
    }
    //@ Change history:  14.12.2023 / Vimean Heng / US-0014423 / Fix lock row.
    static testMethod void testsetCouponCoinvestStaticOwner(){
    	setupdata();
		User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Map<String,RecordType> couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id, EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	Account acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id, EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert new List<Account>{acc,acc2};
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id,Main_Coupon_Site__c = 'ebay.com.au',Coupon_Co_invest_Type__c='Contra',Coupon_ID__c='TestCoupon001');
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id);
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc2.Id);
    	insert new List<Coupon_Seller__c>{cs1,cs2};
    	Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0,Active__c=true);
    	insert ct1;
    	Category_Tree__c ct2 = new Category_Tree__c(Name = 'testCategoryTree2',Level__c = 1,Note_ID__c=ct1.Id,Active__c=true);
    	insert ct2;
    	Coupon_Category__c cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct1.Id);
    	Coupon_Category__c cc2 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct2.Id,Exception_Category__c=true);
    	insert new List<Coupon_Category__c>{cc1,cc2};
    	Coupon_Co_Invest__c coInvest2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Coupon_Category__c=cc2.Id);
        insert coInvest2;
		User u;
		System.runAs(admins[0]) {			
			u = EBH_TestDataFactory.createUser('Standard User Profile');		
    		insert u;

						//updated by DHE to fix test class fail
		String SOQL_PERMISSION ='select id from permissionset where name=\'Standard_User_Base\' limit 1';
		List<PermissionSet> ps = Database.query(SOQL_PERMISSION);
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps[0].Id);
		}
	
    	
    	test.startTest();

		
    		c1.OwnerId = u.Id;
    		update c1;
    	test.stopTest();
    	List<Coupon_Co_Invest__c> lstcoInvest = [select OwnerId, id, Coupon_Category__c,Coupon_Name__c, Seller_Name__c , RecordTypeId, RecordType.DeveloperName from Coupon_Co_Invest__c where Coupon_Name__c =: c1.Id];
    	System.assert(lstcoInvest.size()==1);
    	System.assert(lstcoInvest[0].OwnerId == c1.OwnerId);
    }
	//@	: 16.06.2023 / Chetra Sarom / US-0013475 - Deactivate redundant Coupon Approval process & email
	/* static testMethod void testcouponNegotitaionEndDateReachSendEmailAU(){
    	setupdata();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Map<String,RecordType> couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_OracleID__c = '33444',EBH_EmailOut__c = false);
    	Account acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_OracleID__c = '5544',EBH_EmailOut__c = false);
    	insert new List<Account>{acc,acc2};
    	Coupon__c c1 = new Coupon__c();
		c1.RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id;
		c1.Coupon_Discount__c = 20;
		c1.Coupon_ID__c = 'coupon id test';
		c1.Marketing_Coupon_Name__c = 'marketing name test';
		c1.Main_Coupon_Site__c = 'ebay.com.au';
		c1.Coupon_Co_invest_Type__c='Contra';
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO);
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc2.Id);
    	insert new List<Coupon_Seller__c>{cs1,cs2};
    	Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0,Active__c=true);
    	insert ct1;
    	Category_Tree__c ct2 = new Category_Tree__c(Name = 'testCategoryTree2',Level__c = 1,Note_ID__c=ct1.Id,Active__c=true);
    	insert ct2;
    	Coupon_Category__c cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct1.Id);
    	Coupon_Category__c cc2 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct2.Id,Exception_Category__c=true);
    	insert new List<Coupon_Category__c>{cc1,cc2};
    	Coupon_Co_Invest__c coInvest2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Coupon_Category__c=cc2.Id);
		coInvest2.Co_Invest__c = 10;
        insert coInvest2;
    	test.startTest();
			c1.Trigger1DayAfterNegotiationEndDate__c = System.now();
			update c1;
    	test.stopTest();
	} */
	
	static testMethod void testcouponNegotitaionEndDateReachSendEmailUK(){
    	setupdata();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Map<String,RecordType> couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_OracleID__c = '33444',EBH_RevRollup__c='UK',EBH_EmailOut__c = false,SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	Account acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_OracleID__c = '5544',EBH_RevRollup__c='UK',EBH_EmailOut__c = false,SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert new List<Account>{acc,acc2};
    	Coupon__c c1 = new Coupon__c();
		c1.RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id;
		c1.Coupon_Discount__c = 20;
		c1.Coupon_ID__c = 'couponidtest1239';
		c1.Marketing_Coupon_Name__c = 'marketing name test';
		c1.Main_Coupon_Site__c = 'ebay.co.uk';
		c1.Coupon_Co_invest_Type__c='Contra';
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO);
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc2.Id);
    	insert new List<Coupon_Seller__c>{cs1,cs2};
    	Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0,Active__c=true);
    	insert ct1;
    	Category_Tree__c ct2 = new Category_Tree__c(Name = 'testCategoryTree2',Level__c = 1,Note_ID__c=ct1.Id,Active__c=true);
    	insert ct2;
    	Coupon_Category__c cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct1.Id);
    	Coupon_Category__c cc2 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct2.Id,Exception_Category__c=true);
    	insert new List<Coupon_Category__c>{cc1,cc2};
    	Coupon_Co_Invest__c coInvest2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Coupon_Category__c=cc2.Id);
		coInvest2.Co_Invest__c = 10;
        insert coInvest2;
    	test.startTest();
			c1.Trigger1DayAfterNegotiationEndDate__c = System.now();
			update c1;
    	test.stopTest();
    }
	
	static testMethod void testUpdateCpnCateWhenCpnStageIsSellerNego(){
		//Sophal:11/03/2022:US-0011385

		setupdata();

		DateTime now1 = System.now();
		RecordType cpnRTypeItemBase = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
    	Coupon__c c1 = new Coupon__c(Stage__c = 'Draft', Coupon_Start_Date__c=now1.date(),Coupon_Start_Time__c=now1.timeGmt(),Coupon_End_Date__c=now1.addDays(1).date(), Coupon_end_Time__c=now1.timeGmt(), RecordTypeId = cpnRTypeItemBase.Id,Main_Coupon_Site__c = 'ebay.com.au',Coupon_Co_invest_Type__c='Contra',Coupon_ID__c='TestCoupon001');
    	insert c1;

		Test.startTest();

		Coupon_Category__c cpnCate = new Coupon_Category__c(Coupon__c = c1.Id);
		insert cpnCate;
		cpnCate = [Select Id, Is_Visible_in_Seller_Portal__c from Coupon_Category__c Where Id =: cpnCate.Id];
		System.assertEquals(false, cpnCate.Is_Visible_in_Seller_Portal__c);

		c1.Stage__c = 'Seller Negotiation';
		update c1;

		Test.stopTest();

		cpnCate = [Select Id, Is_Visible_in_Seller_Portal__c from Coupon_Category__c Where Id =: cpnCate.Id];
		System.assertEquals(true, cpnCate.Is_Visible_in_Seller_Portal__c);

	}

	/* COMMENTED OUT: MN-27012025-US-0015576: Move to BatchSyncCouponFieldsToCouponSeller
	@isTest 
	static void test_syncCouponInfo2CouponSellers() {

		setupdata();
		User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        Account portalAccount1;
        Contact contact1;
		RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        Coupon__c c1;
		User user1;

		Test.startTest();

        System.runAs(admins[0])
        {
            //Create account
            portalAccount1 = new Account(
                Name = 'AMT_TEST',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id,
				EBH_EmailOut__c = false,
				EBH_BillingAddress__c='PP',
				EBH_BillingCity__c='pp',
				EBH_BillingCountry__c='US',
				EBH_CompanyName__c='test',
				EBH_BillingPostalCode__c='12102'
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
				Coupon_ID__c = 'Test Coupon ID'
			);
			insert new List<Coupon__c>{c1};

			RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c=contact1.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = portalAccount1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
			insert cs1;

			Test.stopTest();

        }
        
        
        System.runAs(admins[1])
        {
			PermissionSetGroup psg = [select Id, Status from PermissionSetGroup where DeveloperName='Seller_Portal_DE'];
            // force calculation of the PSG if it is not already Updated
            if (psg.Status != 'Updated') {
                Test.calculatePermissionSetGroup(psg.Id);
            }
			
            //Create user

			user1 = SEPTestGenerator.createSEPUser('sepUsercth1', contact1.Id); //MN-10062024-US-0015298

			
        }   

    	
    	//Test.startTest();

		System.runAs(admins[0])
        {
			contact1.Community_User__c = user1.Id;
			update contact1;

			c1.Marketing_Coupon_Name__c = 'Update Test Marketing Coupon Name';
			c1.Coupon_ID__c = 'Update Test Coupon ID';
			update c1;

			for (Coupon_Seller__c cs : [SELECT Coupon_Marketing_Name__c, Coupon_Code__c FROM Coupon_Seller__c WHERE Coupon__c=:c1.Id]) {
				System.assertEquals('Update Test Marketing Coupon Name', cs.Coupon_Marketing_Name__c, 'The Coupon Marketing Name should be update to "Update Test Marketing Coupon Name"');
				System.assertEquals('Update Test Coupon ID', cs.Coupon_Code__c, 'The Coupon Code should be update to "Update Test Coupon ID"');
			}
		}
    	
		

    	//Test.stopTest();

		
		
		
    	
	}
	*/

	@isTest 
	static void test_buildCSVData() {

        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Map<String,RecordType> couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');
        Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,Registration_Site_ID__c ='77',ISO_Currency_Code__c ='123',EBH_RevRollup__c='DE',EBH_EmailOut__c = false, SP_Coupons__c = 'Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc;
        Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id,Main_Coupon_Site__c = 'ebay.de',Coupon_Co_invest_Type__c='Contra',Coupon_ID__c='TestCoupon001');
        insert c1;
		/*Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,Contract_Accept_Date__c=System.today(),Coupon_Seller_Stage__c='T4 Statement Send');
        Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,Contract_Accept_Date__c=System.today(),Coupon_Seller_Stage__c='T4 Statement Send');*/
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,Contract_Accept_Date__c=System.today(),Coupon_Seller_Stage__c='T34 Statement Send');
        Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,Contract_Accept_Date__c=System.today(),Coupon_Seller_Stage__c='T34 Statement Send');
        insert new List<Coupon_Seller__c>{cs1,cs2};
        
        Test.startTest();
        CouponBCDFileDownloadController controller = new CouponBCDFileDownloadController(new ApexPages.standardController(c1)); 
        System.debug('<<<controller.csvData='+controller.csvData);
        List<String> listRow = controller.csvData.split('\n'); 
      //  System.assert(listRow.size() == 3);
     //   System.assert(controller.csvData.contains('testExternalId'));
      //  System.assert(controller.csvData.contains('testProvideId'));
      //  System.assert(controller.csvData.contains('EUR'));
        Test.stopTest();
        
    }

}