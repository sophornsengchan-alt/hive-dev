/*********************************************************************************************************************************
 @ Class:          UploadControllerTest
 @ Version:        1.0
 @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
 @ Purpose:        test logic for UploadController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.04.2019 /  Sovantheany Dim / Created the class.
@				 : 30.06.2023 / Chetra Sarom / US-0013306 - Retirement of Managed Payment Solution (Technical Debt3)
@				 : 13/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
@				 : 22/05/2024/ vadhanak voun/ US-0015117 - 3. Deletion of custom objects
@				 : 11.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
@				 : 22.07.2024/ vadhanak voun/ US-0015373 - Align Apex Classes with Deactivated FVF_Campaign Record Type
@				 : 30.04.2025 / Sothea Horn / US-0017159 - Replace OwnerId with Account_Manager__c for Coupon Related Class
*********************************************************************************************************************************/
@isTest
private class UploadControllerTest {
    static testMethod void testApexInit() {
    	System.runAs(EBH_TestDataFactory.createUser('System Administrator')) {
		List<ActiveValidationRules__c> listRule = [Select Id, All_Validation_Rules_Deactivated__c From ActiveValidationRules__c Where SetupOwnerId = :UserInfo.getUserId() Limit 1];
        if (listRule.isEmpty()) {
			ActiveValidationRules__c avr = new ActiveValidationRules__c(SetupOwnerId = UserInfo.getUserId(), All_Validation_Rules_Deactivated__c = false);
            insert avr;
        }
    	Test.startTest();
    		Map<String,Object> mapResult = UploadController.apexInit();
    	Test.stopTest();
    	System.assert(mapResult.get('status') == 'ok');
    	}
    }
	 

	//MN-19092022-US-0010910-Test methods for new import with Coupon_Co_Invest__c
	
	@isTest
	static void testapexCouponCoInvestImportKo() {

    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	RecordType couponItemRecordType = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
    	
		Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_RevRollup__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert acc;
    	
		Coupon__c c1 = new Coupon__c(RecordTypeID = couponItemRecordType.Id, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com',Coupon_Co_invest_Type__c = 'Contra');
		insert c1;
    	
		Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id);
    	insert cs1;
    	
		Test.startTest();
    		String csvContence = 'Item ID \r\n'+
    		'123456 \r\n'+
    		'234567';
    		Map<String,Object> mapResult = UploadController.apexCouponCoInvestImport(cs1.Id,csvContence,null,0,',','en');
    		mapResult = UploadController.apexCouponCoInvestImport(cs1.Id,null,(List<List<Coupon_Co_Invest__c>>)mapResult.get('listAllChunk'),1,',','en');
    		System.assert(mapResult.get('status') == 'ko');			
    	Test.stopTest();
    	
    }

	@isTest
	static void testapexCouponCoInvestImportOk() {

    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	RecordType couponItemRecordType = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
    	
		Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_RevRollup__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert acc;
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponItemRecordType.Id, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com',Coupon_Co_invest_Type__c = 'Contra');
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id);
    	insert cs1;
    	
		Test.startTest();
    		String csvContence2 = 'Item ID, Item Title, Share% \r\n'+
    		'123456789,Test title, 10 \r\n'+
    		'23456778910,Test title, 10';
    		Map<String,Object> mapResult2 = UploadController.apexCouponCoInvestImport(cs1.Id,csvContence2,null,0,',','en');
    		mapResult2 = UploadController.apexCouponCoInvestImport(cs1.Id,null,(List<List<Coupon_Co_Invest__c>>)mapResult2.get('listAllChunk'),1,',','en');
			UploadController.getDocumentUrl(null,'couponItem');
    	Test.stopTest();
    
    	List<Coupon_Co_Invest__c> lstItem = [select id from Coupon_Co_Invest__c where Coupon_Name__c =: c1.Id];
		System.assertEquals(2,lstItem.size(),'2 coupon co-invest have been created');
    }

	@isTest
	static void testapexCouponCoInvestImportduplicate() {

    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	RecordType couponItemRecordType = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
    	
		Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_RevRollup__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert acc;
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponItemRecordType.Id, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com',Coupon_Co_invest_Type__c = 'Contra');
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id);
    	insert cs1;
    	
		Test.startTest();
    		String csvContence2 = 'Item ID \r\n'+
    		'123456789 \r\n'+
    		'123456789 \r\n'+
    		'23456778910';
    		Map<String,Object> mapResult2 = UploadController.apexCouponCoInvestImport(cs1.Id,csvContence2,null,0,',','en');
    		mapResult2 = UploadController.apexCouponCoInvestImport(cs1.Id,null,(List<List<Coupon_Co_Invest__c>>)mapResult2.get('listAllChunk'),1,',','en');
			Coupon_Co_Invest__c cci = new Coupon_Co_Invest__c(Coupon_Name__c=c1.Id, Coupon_Seller__c=cs1.Id,Item_ID__c='23456778910');
        	insert cci;
        	mapResult2 = UploadController.apexCouponCoInvestImport(cs1.Id,csvContence2,null,0,',','en');
			
    	Test.stopTest();
    	
		//System.assert(mapResult2.get('status') == 'ok');
    	List<Coupon_Co_Invest__c> lstItem = [select id from Coupon_Co_Invest__c where Coupon_Name__c =: c1.Id];
		System.assertEquals(2,lstItem.size(),'2 coupon co-invests have been created');
    }
	//---- MN-19092022-US-0010910-Test methods for new import with Coupon_Co_Invest__c

    static testMethod void testapexCouponSellerImport() {
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
            admUsers[0].FederationIdentifier = 'sthtest';
            insert admUsers;
            RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
            RecordType couponCategoryRecordType = ApexUtil.getRecordTypeByName('Coupon__c','Pop_Coupon');
            //RecordType couponCategoryRecordTypePop = ApexUtil.getRecordTypeByName('Coupon__c','Pop_Coupon');
            Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id, EBH_OracleID__c = 'test 21312',EBH_EmailOut__c = false, EBH_RevRollup__c='US', Account_Manager__c=admUsers[0].Id);
            Account acc1 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id, EBH_OracleID__c = 'test21312',EBH_EmailOut__c = false, EBH_RevRollup__c='US', Account_Manager__c=admUsers[0].Id);
            insert new list<Account>{acc,acc1};
            Coupon__c c1 = new Coupon__c(RecordTypeID = couponCategoryRecordType.Id, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com',Coupon_Co_invest_Type__c = 'Contra');
            insert c1;
            Test.startTest();
                String csvContence = 'OracleID,Share%,Coupon Seller Owner(federation ID)\r\n'+
                'test 21312,12.13,sthtest\r\n'+
                'test21312,13.13,sthtest';
                Map<String,Object> mapResult = UploadController.apexCouponSellerImport(c1.Id,csvContence,null,0,',','en');
                mapResult = UploadController.apexCouponSellerImport(c1.Id,null,(List<List<Coupon_Seller__c>>)mapResult.get('listAllChunk'),1,',','en');
    
                UploadController.getDocumentUrl(null,'couponSeller');
    
            Test.stopTest();
            System.assert(mapResult.get('status') == 'ok');
            List<Coupon_Seller__c> lstCouponSeller = [select id,EBH_CouponSellerOwner__c from Coupon_Seller__c where Coupon__c =: c1.Id];
            System.assertEquals(2,lstCouponSeller.size(),'2 coupon seller have been created');
            System.assertEquals(admUsers[0].Id,lstCouponSeller[0].EBH_CouponSellerOwner__c,'set value from column Coupon Seller Owner (federation ID) to coupon seller owner');
        }
    }
    static testMethod void testapexCouponSellerImportKO() {
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	RecordType couponCategoryRecordType = ApexUtil.getRecordTypeByName('Coupon__c','Category_Based');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id, EBH_OracleID__c = 'test 21312',EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_RevRollup__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	Account acc1 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id, EBH_OracleID__c = 'test21312',EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_RevRollup__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert new list<Account>{acc,acc1};
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponCategoryRecordType.Id, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com',Coupon_Co_invest_Type__c = 'Contra');
		insert c1;
		Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc1.Id);
    	insert cs1;
    	Test.startTest();
    		String csvContence = 'Oracle ID \r\n'+
    		'test 11111\r\n'+
    		'test21312\r\n'+
    		' \r\n'+
    		'test 11111';
    		Map<String,Object> mapResult = UploadController.apexCouponSellerImport(c1.Id,csvContence,null,0,',','en');
    		mapResult = UploadController.apexCouponSellerImport(c1.Id,null,(List<List<Coupon_Seller__c>>)mapResult.get('listAllChunk'),1,',','en');
    	Test.stopTest();
    	System.assert(mapResult.get('status') == 'ko');
    	List<Coupon_Seller__c> lstCouponSeller = [select id from Coupon_Seller__c where Coupon__c =: c1.Id];
    	//System.assertEquals(2,lstCouponSeller.size(),'2 coupon seller have been created');
    }
    static testMethod void testapexNominatedItemImport() {
    	 
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_EmailOut__c = false);
    	insert acc;
    	 
    	Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(Seller_Name__c=acc.Id);
    	insert fvf;
    	Test.startTest();
    		String csvContence = 'Listing ID,Price (target) \r\n'+
    		'1111111111,100\r\n'+
    		'2222222222,100\r\n'+
            '3333333333,200 ';
    		Map<String,Object> mapResult = UploadController.apexNominatedItemImport(fvf.Id,csvContence,null,0,false,false,'de',',');
    		mapResult = UploadController.apexNominatedItemImport(fvf.Id,null,(List<List<Nominated_Item__c>>)mapResult.get('listAllChunk'),1,false,false,'de',',');
        	mapResult = UploadController.apexNominatedItemImport(fvf.Id,null,(List<List<Nominated_Item__c>>)mapResult.get('listAllChunk'),2,false,false,'de',',');
        	 
        	Nominated_Item__c item = new Nominated_Item__c(
			   Final_Value_Fee_FVF__c = fvf.Id,
			Price_target_w__c = 100,
   			Listing_ID_w__c = '1111111111',
   			Discount_FVF_w__c = 1
   		);	
   		insert item;
        	mapResult = UploadController.apexNominatedItemImport(fvf.Id,csvContence,null,0,false,false,'de',',');
    	Test.stopTest();
    	System.assert(mapResult.get('status') == 'confirmExistListingId');
    	List<Nominated_Item__c> lstNominatedItem = [select id from Nominated_Item__c where Final_Value_Fee_FVF__c =: fvf.Id];
        System.assertEquals(4,lstNominatedItem.size(),'4 Nominated Item have been created');
    }
    static testMethod void testapexNominatedItemImport2() {
    	 
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_EmailOut__c = false);
    	insert acc;
    	 
    	Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(Seller_Name__c=acc.Id);
    	insert fvf;
    	Test.startTest();
    		String csvContence = 'EAN, Price Target \r\n'+
    		'1111111111,100\r\n'+
    		'2222222222,100\r\n'+
            '3333333333,200 ';
			String csvContence1 = 'Product Title, EAN, Price Target \r\n'+
			'\"test prduct\",1111111111,100\r\n'+
			'\"test prduct1\",2222222222,100\r\n'+
			'\"test prduct1\",3333333333,100\r\n';
    		Map<String,Object> mapResult = UploadController.apexNominatedItemImport(fvf.Id,csvContence,null,0, true,false,'de',',');
			Map<String,Object> mapResult1 = UploadController.apexNominatedItemImport(fvf.Id,csvContence1,null,0, true,false,'de',',');
    		mapResult = UploadController.apexNominatedItemImport(fvf.Id,null,(List<List<Nominated_Item__c>>)mapResult.get('listAllChunk'),1,false,false,'de',',');
        	mapResult = UploadController.apexNominatedItemImport(fvf.Id,null,(List<List<Nominated_Item__c>>)mapResult.get('listAllChunk'),2,false,false,'de',',');
			mapResult1 = UploadController.apexNominatedItemImport(fvf.Id,null,(List<List<Nominated_Item__c>>)mapResult.get('listAllChunk'),1,false,false,'de',',');
    	Test.stopTest();
    	System.assert(mapResult.get('status') == 'ok', mapResult.get('error')+''+mapResult.get('errorDetail'));
		System.assert(mapResult1.get('status') == 'ok', mapResult1.get('error')+''+mapResult1.get('errorDetail'));
    	List<Nominated_Item__c> lstNominatedItem = [select id from Nominated_Item__c where Final_Value_Fee_FVF__c =: fvf.Id];
        System.assertEquals(4,lstNominatedItem.size(),'4 Nominated Item have been created');
    }
	static testMethod void testapexNominatedItemImport3() {
    	 
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_EmailOut__c = false);
    	insert acc;
    	 
    	Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(Seller_Name__c=acc.Id);
    	insert fvf;
    	Test.startTest();
    		String csvContence = 'Listing ID,Price (target) \r\n'+
    		'11111,100\r\n'+
			'22dsf22,100\r\n'+
            '33,200 ';
    		Map<String,Object> mapResult = UploadController.apexNominatedItemImport(fvf.Id,csvContence,null,0, false,false,'de',',');
			csvContence = 'Listing ID,Price (target) \r\n'+
    		'1111111111,100\r\n'+
			'2222222222,100\r\n'+
    		'2222222222,100\r\n'+
            '3333333333,200 ';
    		mapResult = UploadController.apexNominatedItemImport(fvf.Id,csvContence,null,0, false,false,'de',',');
			csvContence = 'Listing ID,Price (target) \r\n'+
    		'1111111111,100\r\n'+
    		'2222222222,100\r\n'+
            '3333333333,200 ';
    		mapResult = UploadController.apexNominatedItemImport(fvf.Id,csvContence,null,0, false,false,'de',',');
    		mapResult = UploadController.apexNominatedItemImport(fvf.Id,null,(List<List<Nominated_Item__c>>)mapResult.get('listAllChunk'),1,false,true,'de',',');
        	mapResult = UploadController.apexNominatedItemImport(fvf.Id,null,(List<List<Nominated_Item__c>>)mapResult.get('listAllChunk'),2,false,true,'de',',');
    	Test.stopTest();
    	System.assert(mapResult.get('status') == 'ok', mapResult.get('error')+''+mapResult.get('errorDetail'));
    	List<Nominated_Item__c> lstNominatedItem = [select id from Nominated_Item__c where Final_Value_Fee_FVF__c =: fvf.Id];
        System.assertEquals(3,lstNominatedItem.size(),'3 Nominated Item have been created');
    }
    static testMethod void testApexImportSellerAndNominatedItemForFVFCampaign()
    {
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		//LA:05-12-2023-US-0014231
    	//Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_DealsProgram__c ='Accepted',EBH_EmailOut__c = false);
		Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_EmailOut__c = false);
    	insert acc;
        RecordType fvfCampRec = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c','FVF_Listing_Level');
        Final_Value_Fee_FVF__c fvfCamp = new Final_Value_Fee_FVF__c(Site__c='UK',RecordTypeId =fvfCampRec.Id ,Legal_Entity_Country__c='UK', Legal_Entity_Name__c='My Company',Legal_Entity_Street__c='street1',Legal_Entity_Zip__c='12345',Seller_Name__c=acc.Id,Seller_Email__c='test@test.com');
    	insert fvfCamp;
    	String csvStringEN ='oracle id,listing id,price (target)\r1003293591,352863576988,37.12\r1003293591,302638000000,12.15\r18116485,391810407692,102.60';
    	Test.startTest();
    		Map<String, Object> result = UploadController.apexImportSellerAndNominatedItemForFVFCampaign(fvfCamp.Id, csvStringEN, 'EN', ',');
    	Test.stopTest();
    	 
	}
	static testMethod void testDoSendEmailForReachingMaxRecord(){
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		//LA:05-12-2023-US-0014231
    	//Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_DealsProgram__c ='Accepted',EBH_EmailOut__c = false);
		Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_EmailOut__c = false);
    	insert acc;
        RecordType fvfCampRec = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c','FVF_Listing_Level');
        Final_Value_Fee_FVF__c fvfCamp = new Final_Value_Fee_FVF__c(Site__c='UK',RecordTypeId =fvfCampRec.Id ,Legal_Entity_Country__c='UK', Legal_Entity_Name__c='My Company',Legal_Entity_Street__c='street1',Legal_Entity_Zip__c='12345',Seller_Name__c=acc.Id,Seller_Email__c='test@test.com');
    	insert fvfCamp;
		Test.startTest();
    		Map<String, Object> result = UploadController.doSendEmailForReachingMaxRecord(fvfCamp.Id, '200', '100');
    	Test.stopTest();
	}
	static testMethod void testapexFVFCampaignInit(){
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		//LA:05-12-2023-US-0014231
    	//Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_DealsProgram__c ='Accepted',EBH_EmailOut__c = false);
    	Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_EmailOut__c = false);
		insert acc;
        RecordType fvfCampRec = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c','FVF_Listing_Level');
		Final_Value_Fee_FVF__c fvfCamp = new Final_Value_Fee_FVF__c(Site__c='UK',RecordTypeId =fvfCampRec.Id ,Legal_Entity_Country__c='UK', Legal_Entity_Name__c='My Company',Legal_Entity_Street__c='street1',Legal_Entity_Zip__c='12345',Seller_Name__c=acc.Id,Seller_Email__c='test@test.com');
    	insert fvfCamp;
		test.startTest();
		Map<String, Object> mapresult = UploadController.apexFVFCampaignInit(fvfCamp.Id);
		UploadController.getDocumentUrl(true,'fvfcampaign');
		UploadController.getDocumentUrl(false,'fvfcampaign');
		test.stopTest();
		System.assertEquals('true',mapresult.get('showUpload'),'showupload true if fvf stage = Draft');
	}
	static testMethod void testapexImportBobSeller(){
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
            //admUsers[0].BoB_Country__c = '3';
            insert admUsers;
            RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
			//LA:05-12-2023-US-0014231
            //Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_DealsProgram__c ='Accepted',EBH_EmailOut__c = false);
			Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_EmailOut__c = false);
            insert acc;
            RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
            BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
            insert bob;
            String csvStringEN ='oracle id\r1003293591\r1003293591\r18116485';
            UploadController.getDocumentUrl(null,'bobSeller');
            test.startTest();
            Map<String, Object> mapresult = UploadController.apexImportBobSeller(bob.Id,csvStringEN,'EN',',');
            test.stopTest();
            System.assertEquals('ok',mapresult.get('status'));
        }
	}
	static testMethod void testapexImportBobSeller2(){
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
            //admUsers[0].BoB_Country__c = '3';
            insert admUsers;
            RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
            BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
            insert bob;
            String csvStringEN ='oracle id\r1003293591\r1003293591\r18116485';
            UploadController.getDocumentUrl(null,'bobSeller');
            test.startTest();
            Map<String, Object> mapresult = UploadController.apexImportBobSeller(bob.Id,csvStringEN,'EN',',');
            mapresult = UploadController.apexImportBobSeller(bob.Id,csvStringEN,'EN',',');
            test.stopTest();
            System.assertEquals('ko',mapresult.get('status'));
        }
	}
	static testMethod void testapexBobInit(){
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
            //admUsers[0].BoB_Country__c = '3';
            insert admUsers;
            RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
            BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
            insert bob;
            test.startTest();
            Map<String, Object> mapresult = UploadController.apexBobInit(bob.Id);
            test.stopTest();
            System.assertEquals('true',mapresult.get('showUpload'),'showupload true if bob status = Draft');
        }
	}
    
    static testMethod void checkPermissionFVFUser(){
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Map<String,Object> mapresult = UploadController.checkPermissionFVFUser();
            System.assertEquals('ok',mapresult.get('status'));
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
	
	@isTest static void testImportCohortSellerPreDML(){
		List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
		//admUsers[0].BoB_Country__c = '3';
		admUsers[0].FederationIdentifier = 'adminTest';
		insert admUsers;
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		//LA:05-12-2023-US-0014231
		//Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_DealsProgram__c ='Accepted',EBH_EmailOut__c = false);
		Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_EmailOut__c = false);
		insert acc;
		RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
		BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
		insert bob;

		String headerStr = 'oracle_id__c,account_manager__c,ttec_manager__c,ebh_bobsegment__c,parent_seller__c';
        String rowStr = '1003293591,%accManager%,%secondManager%,LTAM,1003293591';
        rowStr = rowStr.replace('%accManager%',admUsers[0].FederationIdentifier);
        rowStr = rowStr.replace('%secondManager%',admUsers[0].FederationIdentifier);


        List<String> listHeaderCol = headerStr.split(',');
        List<String> listRowCol = rowStr.split(',');

        List<Map<String,String>> listRecord = new List<Map<String,String>>();
        Map<String,String> mapObj = new Map<String,String>();
        for(Integer i = 0; i < listHeaderCol.size(); i++){
            mapObj.put(listHeaderCol[i], listRowCol[i]);
        }
        listRecord.add(mapObj);

        Map<String, Object> mapArgs = new Map<String, Object>();
		mapArgs.put('listRecord', listRecord);
		mapArgs.put('parentId', bob.Id);
        mapArgs.put('startIndex', 0);
        mapArgs.put('locale', 'en');

		Test.startTest();
		
		Callable extension = (Callable) Type.forName('UploadController.CohortSellerImport').newInstance();
		Map<String, Object> mapResult = (Map<String, Object>) extension.call('importCohortSellerPreDML', mapArgs);

		Map<Integer, String> mapIndexToErrMsg =  (Map<Integer, String>)(JSON.deserialize(JSON.serialize(mapResult.get('mapIndexToErrMsg')), Map<Integer, String>.class)); 
        if(!mapIndexToErrMsg.isEmpty()){ System.debug('nsp : mapIndexToErrMsg == '+mapIndexToErrMsg); }
        System.assertEquals(0, mapIndexToErrMsg.size());

        Test.stopTest();
	}

	@isTest static void testAdsImportCohortSellerPreDML(){
		// 22.09.2023 / Sophal Noch / US-0014118
		List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
		//admUsers[0].BoB_Country__c = '3';
		admUsers[0].FederationIdentifier = 'adminTest';
		insert admUsers;
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		//LA:05-12-2023-US-0014231
		//Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_DealsProgram__c ='Accepted',EBH_EmailOut__c = false);
		Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_EmailOut__c = false);
		insert acc;
		RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Advertising_Cohort');
		BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
		insert bob;

		String headerStr = 'oracle_id__c,ads_partner_manager__c;account_manager__c,pl_segment__c';
        String rowStr = '1003293591,%adsManager%,%accManager%,Tier 3';
        rowStr = rowStr.replace('%adsManager%',admUsers[0].FederationIdentifier);
        rowStr = rowStr.replace('%accManager%',admUsers[0].FederationIdentifier);


        List<String> listHeaderCol = headerStr.split(',');
        List<String> listRowCol = rowStr.split(',');

        List<Map<String,String>> listRecord = new List<Map<String,String>>();
        Map<String,String> mapObj = new Map<String,String>();
        for(Integer i = 0; i < listHeaderCol.size(); i++){
            mapObj.put(listHeaderCol[i], listRowCol[i]);
        }
        listRecord.add(mapObj);

        Map<String, Object> mapArgs = new Map<String, Object>();
		mapArgs.put('listRecord', listRecord);
		mapArgs.put('parentId', bob.Id);
        mapArgs.put('startIndex', 0);
        mapArgs.put('locale', 'en');

		Test.startTest();
		
		Callable extension = (Callable) Type.forName('UploadController.CohortSellerImport').newInstance();
		Map<String, Object> mapResult = (Map<String, Object>) extension.call('importCohortSellerPreDML', mapArgs);

		Map<Integer, String> mapIndexToErrMsg =  (Map<Integer, String>)(JSON.deserialize(JSON.serialize(mapResult.get('mapIndexToErrMsg')), Map<Integer, String>.class)); 
        if(!mapIndexToErrMsg.isEmpty()){ System.debug('nsp : mapIndexToErrMsg == '+mapIndexToErrMsg); }
        System.assertEquals(0, mapIndexToErrMsg.size());

        Test.stopTest();
	}

	@isTest static void testImportNominatedItemPreDML(){

		RecordType contacDW_RT = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
        Contact cont = new Contact(LastName='Test Cont1',RecordTypeID=contacDW_RT.Id,Email='test@test.com');
        insert cont;
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		//LA:05-12-2023-US-0014231
    	//Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',Primary_Contact__c=cont.Id,EBH_DealsProgram__c ='Accepted');
		Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',Primary_Contact__c=cont.Id);
    	insert acc;

    	RecordType fvfRecordType = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE);
    	Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(Site__c='UK',RecordTypeId =fvfRecordType.Id ,Legal_Entity_Country__c='UK', Legal_Entity_Name__c='My Company',Legal_Entity_Street__c='street1',Legal_Entity_Zip__c='12345',Seller_Name__c=acc.Id,Seller_Email__c='test@test.com',Final_Value_Fee_Stage__c='Contract Declined');
    	insert fvf;


		String headerStr = 'listing_id_w__c,price_target_w__c';
        String rowStr = '786547654200,50';
        

        List<String> listHeaderCol = headerStr.split(',');
        List<String> listRowCol = rowStr.split(',');

        List<Map<String,String>> listRecord = new List<Map<String,String>>();
        Map<String,String> mapObj = new Map<String,String>();
        for(Integer i = 0; i < listHeaderCol.size(); i++){
            mapObj.put(listHeaderCol[i], listRowCol[i]);
        }
        listRecord.add(mapObj);

        Map<String, Object> mapArgs = new Map<String, Object>();
		mapArgs.put('listRecord', listRecord);
		mapArgs.put('parentId', fvf.Id);
        mapArgs.put('startIndex', 0);
        
		Test.startTest();
		
			Callable extension = (Callable) Type.forName('UploadController.NominatedItemImport').newInstance();
			Map<String, Object> mapResult = (Map<String, Object>) extension.call('importNominatedItemPreDML', mapArgs);

			String result = String.valueOf(mapResult.get('status'));
			System.assertEquals('ok', result, 'The result should be "ok".');
			
        Test.stopTest();
	}

}