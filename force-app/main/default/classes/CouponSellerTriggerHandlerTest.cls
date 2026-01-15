/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 * @ Change history: 02.09.2022 / Chetra Sarom / US-0012067 - Deactivate automatic task "Urgent Action Required - Call the Seller"
 * @			   : 30.04.2025 / Sothea Horn / US-0017159 - Replace OwnerId with Account_Manager__c for Coupon Related Class
 * @			   : 10.09.2025 / Leon Morocki / US-0033151 - POP - Coupon Seller - Create New Record Type (Program Coupon Seller)
 * @			   : 16.10.2025 / SENG Chan Sophorn / US-0033614 - POP - Trigger to update status of Program Seller to Opt- in - instead of Contract signed
 * @			   : 15.12.2025 / Leon Morocki / US-0033470 - POP - SP - Download Item file attached to Coupon Seller record
 */
@isTest
private class CouponSellerTriggerHandlerTest {
	
	@testSetup 
    static void setup() {
    	EBH_TestDataFactory.setUpCustomSettings();   
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;

		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		RecordType rt_itemBased = ApexUtil.getRecordTypeByName('Coupon__c','Item_Based');
		RecordType rt_catBased = ApexUtil.getRecordTypeByName('Coupon__c','Category_Based');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='DE', EBH_EmailOut__c = false, SP_Coupons__c = 'Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	Account acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='ES', EBH_EmailOut__c = false, SP_Coupons__c = 'Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert new List<Account>{acc,acc2};
    	Coupon__c c1 = new Coupon__c(RecordTypeID = rt_catBased.Id,Main_Coupon_Site__c = 'ebay.es',Coupon_Co_invest_Type__c='Contra',Marketing_Coupon_Name__c='Category_Based', Coupon_ID__c='Test001');
		insert c1;
		Coupon__c c2 = new Coupon__c(RecordTypeID = rt_itemBased.Id,Main_Coupon_Site__c = 'ebay.es',Coupon_Co_invest_Type__c='Contra',Marketing_Coupon_Name__c='Item_Based',Coupon_ID__c='Test002');
		insert c2;
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
		
    }
    //static testmethod void setupData(){
        
    //}
    static testMethod void testcreateCoInvestOnceCouponSellerCreated() { 
        //setupdata();
        /*RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false);
        insert acc1;
        
		RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
        Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordTypeItem.Id, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com');
		insert c1;
		c1.Stage__c = EBH_ConstantsUtility.COUPON_SELLER_NEGOTIATION_STAGE;
		update c1;
		Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0, Active__c=true);
    	insert ct1;
    	Category_Tree__c ct2 = new Category_Tree__c(Name = 'testCategoryTree2',Level__c = 1,Note_ID__c=ct1.Id,Active__c=true);
    	insert ct2;
    	Coupon_Category__c cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct1.Id);
    	Coupon_Category__c cc2 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct2.Id);
		
    	insert new List<Coupon_Category__c>{cc1,cc2};*/
		Coupon__c c1 =[SELECT ID,Stage__c FROM Coupon__c WHERE Marketing_Coupon_Name__c='Category_Based' limit 1];
    	
		Test.startTest();
		/*UploadController.mapCsSellerShare.put(1, '34.2');
		UploadController.mapCsSellerShare.put(2, '34.2');
		UploadController.mapCsSellerShare.put(3, '34.2');
		UploadController.mapCsSellerShare.put(4, '34.2');
		UploadController.mapCsSellerShare.put(5, '34.2');*/
		c1.Stage__c =  'Seller Negotiation';
		update c1;
		Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Contract Negotiation',Legal_Entity_Name_w__c='pp',Legal_Entity_Street_w__c='pp',Legal_Entity_Zip_w__c='12102');
		insert cs1;
		List<Coupon_Category__c> cc = [SELECT ID FROM Coupon_Category__c LIMIT 2];
		
        Test.stopTest();
		
        Coupon_Co_Invest__c[] cciSel = [select Id,name,RecordType.DeveloperName,Coupon_Category__c,Coupon_Name__c From Coupon_Co_Invest__c Where Coupon_Name__c =: c1.Id];
		System.assertEquals(6,cciSel.size(),' 2 Co-Invest created');
        for(Coupon_Co_Invest__c coInvest : cciSel){
    		if(coInvest.Coupon_Category__c == cc[0].Id){
    			System.assertEquals(EBH_ConstantsUtility.CO_INVEST_SELLER, coInvest.RecordType.DeveloperName, 'Rule i : Coupon Co-Invest Seller when Coupon Object Record type: Seller/Category based and Coupon Stage in "Seller Negotiation" and Coupon Level = 0');
    		}else if(coInvest.Coupon_Category__c == cc[1].Id){
    			System.assertEquals(EBH_ConstantsUtility.CO_INVEST_CATEGORY, coInvest.RecordType.DeveloperName, 'Rule ii : Coupon Co-Invest Category when Coupon Object Record type: Seller/Category based and Coupon Stage in "Seller Negotiation" and Coupon Level > 0');
    		}
		}
    }
    
	/*static testMethod void testCreateCoInvest2() {
         //setupdata();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc1 = new Account(Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_EmailOut__c = false,EBH_RevRollup__c = 'UK',SP_Coupons__c = 'Full Access');
        insert acc1;
        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordTypeItem.Id,Contract_Due_Date__c = System.today(), Main_Coupon_Site__c='ebay.co.uk', Couponsite_s__c = 'ebay.co.uk');
		insert c1;
		
		Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted');
		insert cs1;
		
		Coupon_Item__c ci = new Coupon_Item__c(Coupon_ID__c=c1.Id, Coupon_Seller_ID__c=cs1.Id,Item_ID__c='1234567890',Seller_Share__c=10);
		insert ci;
		Test.startTest();
			cs1.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO;
			update cs1;
		Test.stopTest();
		System.assertEquals(EBH_ConstantsUtility.CO_INVEST_ITEM,[select Id,RecordType.DeveloperName From Coupon_Co_Invest__c Where Coupon_Seller__c = :cs1.Id].RecordType.DeveloperName,' 1 Co-Invest created with Coupon_Co_Invest_Item record type');
    }*/
    
    static testMethod void testSendContract()
    {
		Test.startTest();

    	//Set<String> excludeUser = new Set<String>{'Integration','Deployment'}; //by pass validation rule
    	User admin1 = EBH_TestDataFactory.createUser('System Administrator');
    	admin1.FirstName = 'Test';//by pass validation rule
    	//User admin1 = [Select Id,Name From User where isActive = true and Profile.Name = 'System Administrator' AND Name NOT IN :excludeUser Limit 1 ];
    	System.runAs(admin1)
    	{
	        //setupdata();
	    	// EBH_TestDataFactory.setUpCustomSettings();
	    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
	    	Account acc1 = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_RevRollup__c='ES',SP_Coupons__c='Full Access');
	        //insert acc1;
			
			Account acc2 = new Account(Name='Test Abc2',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false, EBH_RevRollup__c='ES',SP_Coupons__c='Full Access');
	        //insert acc2;

			insert new List<Account>{acc1,acc2};
			Contact con1 = new Contact(LastName='Test Con1', Email='test1@test.com.invalid', AccountId=acc1.Id); //MN-30082021-US-0009948
			Contact con2 = new Contact(LastName='Test Con2', Email='test2@test.com.invalid', AccountId=acc2.Id); //MN-30082021-US-0009948
        	insert new List<Contact>{con1, con2}; //MN-30082021-US-0009948
			
	        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
	        Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1, Main_Coupon_Site__c='ebay.es', Couponsite_s__c = 'ebay.es', Coupon_ID__c = 'TestCP002');
			insert c1;
			
			//Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Email_Adress__c='test@test.com',EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc2.Id); //MN-30082021-US-0009948
			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c =  con2.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc2.Id); //MN-30082021-US-0009948
			insert cs1;
			
			// Coupon_Item__c ci = new Coupon_Item__c(Coupon_ID__c=c1.Id, Coupon_Seller_ID__c=cs1.Id,Item_ID__c='1234567890',Seller_Share__c=10);
			// insert ci;
			
			cs1.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO;
			update cs1;
			
			Coupon_Co_Invest__c coInvest = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc2.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
			insert coInvest;
			
			cs1.Legal_Entity_Name_w__c = 'test entity';
			cs1.Legal_Entity_Street_w__c = 'test street';
			cs1.Legal_Entity_Zip_w__c = 'test zip';
			cs1.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND ;
			update cs1;
			
			Test.stopTest();

            //Coupon_Seller__c cs2 = new Coupon_Seller__c(Email_Adress__c='test2@test.com',Coupon__c = c1.Id, Seller__c = acc1.Id, Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND); //MN-30082021-US-0009948
            Coupon_Seller__c cs2 = new Coupon_Seller__c(Seller_Contact__c =  con1.Id,Coupon__c = c1.Id, Seller__c = acc1.Id, Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND); //MN-30082021-US-0009948
            try{
                insert cs2;
            }catch(Exception e){
                
                System.assert(e.getMessage().contains(system.label.error_CouponItem_notExist));
            }
            
            cs2.Coupon_Seller_Stage__c = 'Targeted';
            insert cs2;            	
            
            // Coupon_Item__c ci2 = new Coupon_Item__c(Coupon_ID__c=c1.Id, Coupon_Seller_ID__c=cs2.Id,Item_ID__c='1234567892',Seller_Share__c=10);
            // insert ci2;
            cs2.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO;
            update cs2;

			Coupon_Co_Invest__c coInvest2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs2.Id,Seller_Name__c=acc1.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
			insert coInvest2;

            cs2.Legal_Entity_Name_w__c = 'test entity';
            cs2.Legal_Entity_Street_w__c = 'test street';
            cs2.Legal_Entity_Zip_w__c = 'test zip';
            cs2.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND ;
            update cs2;
            
			
			List<Task> lstTask = [select Id from Task where WhatId =: cs1.Id];
			System.assertEquals(1,lstTask.size());
			List<Attachment> lsttaskAtt = [select id,Name from Attachment where ParentId =: lstTask[0].id];
			System.assertEquals(2,lsttaskAtt.size());
			List<Task> lstTask2 = [select Id from Task where WhatId =: cs2.Id];
			System.assertEquals(1,lstTask2.size());
			
			cs1.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_EXEC;
			cs1.Day4AfterCouponEnd_Trigger_DE__c = System.now();
			cs1.Contract_Accept_Date__c = System.now();
			update cs1;
			
			cs1.Day34AfterCouponEnd_Trigger_DE__c = System.now();
			//cs1.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_T4;
			cs1.Coupon_Seller_Stage__c = 'T34 Statement Send';
			update cs1;
    	}
    }
	
	static testMethod void testsetEmailAddress(){
         //setupdata();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	RecordType ContactRecordType = ApexUtil.getRecordTypeByName('Contact',EBH_ConstantsUtility.CONTACT_RECORDTYPE_DWH);
    	Account acc1 = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102',EBH_RevRollup__c='US');
    	Account acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102',EBH_RevRollup__c='US');
        insert new List<Account>{acc1,acc2};
        Contact con = new Contact(LastName = 'testContact1', AccountId = acc1.Id, EBH_Status__c='Active',Email='test1@gmail.com',
    	Phone='123456',EBH_MailingStreet__c='testMailingStreet',EBH_MailingPostalCode__c='testMailingPostalcode',
    	EBH_MailingCountry__c='testMailingCountry',EBH_MailingCity__c='testMailingCity',EBH_MailingAddress__c='testMailingAddress',EBH_Decision_Maker_Role__c=EBH_ConstantsUtility.DECISION_MAKER_ROLE);
    	Contact con2 = new Contact(LastName = 'testContact2', AccountId = acc1.Id, EBH_Status__c='Active',Email='test2@gmail.com',
    	Phone='123457',EBH_MailingStreet__c='testMailingStreet',EBH_MailingPostalCode__c='testMailingPostalcode',
    	EBH_MailingCountry__c='testMailingCountry',EBH_MailingCity__c='testMailingCity',EBH_MailingAddress__c='testMailingAddress',RecordTypeId=ContactRecordType.Id);
    	Contact con3 = new Contact(LastName = 'testContact3', AccountId = acc2.Id, EBH_Status__c='Active',Email='test3@gmail.com',
    	Phone='123458',EBH_MailingStreet__c='testMailingStreet',EBH_MailingPostalCode__c='testMailingPostalcode',
    	EBH_MailingCountry__c='testMailingCountry',EBH_MailingCity__c='testMailingCity',EBH_MailingAddress__c='testMailingAddress',RecordTypeId=ContactRecordType.Id);
    	insert new List<Contact>{con,con2,con3};
    	Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCP003');
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller__c=acc1.Id);
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller__c=acc2.Id);
    	Test.startTest();
    	insert new List<Coupon_Seller__c>{cs1,cs2};
    	Test.stopTest();
    	/* //MN-30082021-US-0009948
		System.assertEquals(con.Email,[select Email_Adress__c from Coupon_Seller__c where id =: cs1.Id].Email_Adress__c);
    	System.assertEquals(con3.Email,[select Email_Adress__c from Coupon_Seller__c where id =: cs2.Id].Email_Adress__c);
		*/

		System.assertEquals(con.Id,[select Seller_Contact__c from Coupon_Seller__c where id =: cs1.Id].Seller_Contact__c); //MN-30082021-US-0009948
    	System.assertEquals(con3.Id,[select Seller_Contact__c from Coupon_Seller__c where id =: cs2.Id].Seller_Contact__c); //MN-30082021-US-0009948
    }
	
	static testMethod void testPrepopulateOwnerFromSeller(){
        //setupData();
    	Test.startTest();
			User testUser = EBH_TestDataFactory.createUser('System Administrator');
			insert testUser;
	    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
	    	Account acc1 = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id, Account_Manager__c=testUser.Id , EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102',EBH_RevRollup__c='US');
	    	insert acc1;
	    	Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com' , Coupon_ID__c = 'TestCP004');
			insert c1;
	    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller__c=acc1.Id);
	    	insert cs1;
	    	cs1 = [SELECT EBH_CouponSellerOwner__c FROM Coupon_Seller__c WHERE Id =: cs1.Id];
	    	acc1 = [SELECT OwnerId, Account_Manager__c FROM Account WHERE Id =: acc1.Id];
	    	System.assertEquals(cs1.EBH_CouponSellerOwner__c, acc1.Account_Manager__c);
    	
    	Test.stopTest();
    }
    
    
    static testMethod void testblockManualSetStageWhenCreate(){
         //setupdata();
    		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    		Account acc1 = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102',EBH_RevRollup__c='US');
    		insert acc1;
    		Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCP005');
			insert c1;
    		Test.startTest();
    		try {
    			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Contract Signed',Seller__c=acc1.Id);
	    		insert cs1;
        	}catch(Exception e) {
        		System.assert(e.getMessage().contains(EBH_ConstantsUtility.COUPON_SELLER_ERROR_MSG));
        	}
    		Test.stopTest();
    //	}
    	
    }
    
    static testMethod void testblockManualSetStageWhenUpdated(){
         //setupdata();
    		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    		Account acc1 = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102',EBH_RevRollup__c='US');
    		insert acc1;
    		Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com',  Coupon_ID__c = 'TestCP006');
			insert c1;
			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller__c=acc1.Id);
	    	insert cs1;
    		Test.startTest();
    		try {
				cs1.Coupon_Seller_Stage__c = 'Coupon Running';
				update c1;
        	}catch(Exception e) {
        		System.assert(e.getMessage().contains(EBH_ConstantsUtility.COUPON_SELLER_ERROR_MSG));
        	}
    		Test.stopTest();
    	//} Commented by DHE
    }
    
	// US-0012067 - Deactivate automatic task "Urgent Action Required - Call the Seller"
    // static testMethod void testcouponSellerContractReminderAU(){
    // 	//setupdata();
    // 	User auUser1 = EBH_TestDataFactory.createUser(EBH_ConstantsUtility.TICKET_AU_PROFILE);
    //     User auUser2 = EBH_TestDataFactory.createUser(EBH_ConstantsUtility.TICKET_AU_PROFILE);
    //     insert new List<User>{auUser1,auUser2};
    //     System.runAs(auUser2){
    //         PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name =: EBH_ConstantsUtility.PERMISSION_COUPONSPECIALPERMISSION];
    //         PermissionSetAssignment pmm = new PermissionSetAssignment(AssigneeId = auUser1.id, PermissionSetId = ps.Id);
    //         insert pmm;
    //     }
    // 	System.runAs(auUser1)
    // 	{
	//     	// EBH_TestDataFactory.setUpCustomSettings();
	//     	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
	//     	Account acc1 = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_EmailOut__c = false);
	//         insert acc1;
			
	// 		Account acc2 = new Account(Name='Test Abc2',RecordTypeID = sellerRecordType.Id, EBH_DealsProgram__c='Accepted',EBH_EmailOut__c = false);
	//         insert acc2;

	// 		Contact con1 = new Contact(LastName='Test Con1', Email='test1@test.com.invalid', AccountId=acc1.Id); //MN-30082021-US-0009948
	// 		Contact con2 = new Contact(LastName='Test Con2', Email='test2@test.com.invalid', AccountId=acc2.Id); //MN-30082021-US-0009948
    //     	insert new List<Contact>{con1, con2}; //MN-30082021-US-0009948
			
	//         RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
	//         Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today()+3,Coupon_End_Date__c=System.today()+7,Contract_Due_Date__c = System.today()+1, Main_Coupon_Site__c='ebay.com.au', Couponsite_s__c = 'ebay.com.au');
	// 		insert c1;
			
	// 		//Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Contract_Accept_Date__c = null,Coupon_Seller_Stage__c='Targeted',Email_Adress__c='test@test.com',EBH_CouponSellerOwner__c = UserInfo.getUserId()); //MN-30082021-US-0009948
	// 		Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Contract_Accept_Date__c = null,Coupon_Seller_Stage__c='Targeted',Seller__c = acc2.Id, Seller_Contact__c=con2.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId()); //MN-30082021-US-0009948
	// 		insert cs1;
			
	// 		Coupon_Item__c ci = new Coupon_Item__c(Coupon_ID__c=c1.Id, Coupon_Seller_ID__c=cs1.Id,Item_ID__c='1234567890',Seller_Share__c=10);
	// 		insert ci;

	// 		Coupon_Co_Invest__c cci = new Coupon_Co_Invest__c(Coupon_Name__c=c1.Id, Coupon_Seller__c=cs1.Id, Co_Invest__c=10, Item_ID__c='1234567890');
	// 		insert cci;
			
	// 		cs1.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO;
	// 		update cs1;
	// 		cs1.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPONSELLER_STAGE_APPROVED;
	// 		update cs1;
	// 		Test.startTest();
			
	// 		cs1.Seller__c = acc2.Id;
	// 		update cs1;

	// 		cs1.Legal_Entity_Name_w__c = 'test entity';
	// 		cs1.Legal_Entity_Street_w__c = 'test street';
	// 		cs1.Legal_Entity_Zip_w__c = 'test zip';
	// 		cs1.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND ;
	// 		update cs1;
			
	// 		//Coupon_Seller__c cs2 = new Coupon_Seller__c(Email_Adress__c='test2@test.com',Coupon__c = c1.Id, Seller__c = acc1.Id, Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND);
	// 		Coupon_Seller__c cs2 = new Coupon_Seller__c(Seller_Contact__c=con1.Id,Coupon__c = c1.Id, Seller__c = acc1.Id, Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND);
	// 		try{
	// 			insert cs2;
	// 		}catch(Exception e){
	// 			System.assert(e.getMessage().contains(system.label.error_CouponItem_notExist));
	// 		}
	// 		cs2.Coupon_Seller_Stage__c = 'Targeted';
	// 		insert cs2;
	// 		Coupon_Item__c ci2 = new Coupon_Item__c(Coupon_ID__c=c1.Id, Coupon_Seller_ID__c=cs2.Id,Item_ID__c='1234567892',Seller_Share__c=10);
	// 		insert ci2;
	// 		Coupon_Co_Invest__c cci2 = new Coupon_Co_Invest__c(Coupon_Name__c=c1.Id, Coupon_Seller__c=cs2.Id, Co_Invest__c=10, Item_ID__c='1234567892');
	// 		insert cci2;
	// 		cs2.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO;
	// 		update cs2;
	// 		cs2.Coupon_Seller_Stage__c = 'Approved';
	// 		update cs2;
	// 		cs2.Legal_Entity_Name_w__c = 'test entity';
	// 		cs2.Legal_Entity_Street_w__c = 'test street';
	// 		cs2.Legal_Entity_Zip_w__c = 'test zip';
	// 		cs2.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND ;
	// 		update cs2;
			
	// 		Test.stopTest();
	// 		List<Task> lstTask = [select Id from Task where WhatId =: cs1.Id];
	// 		System.assertEquals(1,lstTask.size());
			
	// 		//List<Task> lstTask2 = [select Id from Task where WhatId =: cs2.Id];
	// 		//System.assertEquals(3,lstTask2.size());
				
    // 	}
    	 
	// }
	// end US-0012067 - Deactivate automatic task "Urgent Action Required - Call the Seller"
	
	@isTest 
	private static void testValidateCoInv_SellerShareAndCompanyDetail(){
		//setupdata();
		User admin1 = EBH_TestDataFactory.createUser('System Administrator');
    	admin1.FirstName = 'Test';
    	System.runAs(admin1)
    	{
		Test.startTest();
			RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
			//LA:05-12-2023-US-0014231: remove EBH_DealsProgram__c ='Accepted'
			//Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
			Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102',EBH_RevRollup__c='US');
			insert acc;

			Coupon__c c1 = new Coupon__c(Seller_Co_funding_share_forecast__c = null,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c = System.today().addDays(1), Negotiation_End_Date__c=System.today().addDays(1), Contract_Due_Date__c = System.today().addDays(-1), Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCP007');
			insert c1;

			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,Legal_Entity_Name_w__c = 'testName',Legal_Entity_Street_w__c='testStreet',Legal_Entity_Zip_w__c='testZip');
			insert cs1;
			
			Coupon_Co_Invest__c coInvest = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=null);
			insert coInvest;
			
			// AC1)
			try {
				cs1.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND;
				update cs1;
				//System.assert(false);
			} catch (Exception ex) {
				System.assert(ex.getMessage().contains(Label.CouponSellerStageContractSend_Error2), ex.getMessage());
			}

			coInvest.Co_Invest__c = 10;
			update coInvest;

			// AC2)
			try {
				update cs1;
				//System.assert(false);
			} catch (Exception ex) {
				System.assert(ex.getMessage().contains('Seller Share value on related Co-Invest Records, Company, Street and ZIP cannot be empty'), ex.getMessage());
			}

			try {
				cs1.Legal_Entity_Name_w__c = 'test entity';
				cs1.Legal_Entity_Street_w__c = 'test street';
				cs1.Legal_Entity_Zip_w__c = 'test zip';
				update cs1;
				
			} catch (Exception ex) {
				System.assert(false, ex.getMessage());
			}
			
			// Should be success
			try {
				update cs1;
			} catch (Exception ex) {
				System.assert(false, ex.getMessage());
			}
			
		Test.stopTest();
    	}
	}
    
	//commented by DHE on 2020-09-02 because of us-0008187
	//uncommented by Ratha Sim on 2020-09-09 because of US-0008170
	// commented by 16.01.2023 / Sambath Seng / US-0012735 - Migrate coupon start reminder to seller communication records
	/* static testMethod void testSendCouponLaunchReminderTemplates(){
		User admin1 = EBH_TestDataFactory.createUser('System Administrator');
		admin1.FirstName = 'Test';
		System.runAs(admin1)
		{
			//setupdata();
			RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
			Account acc1 = new Account(Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_EmailOut__c = false);
			insert acc1;

			Contact con = new Contact(LastName='Test Con1', Email='test@test.com.invalid', AccountId=acc1.Id); //MN-30082021-US-0009948
        	insert con; //MN-30082021-US-0009948
			
			RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
			Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com');//SB 8.11.2021 US-0010476 add contract due date value to coupon
			insert c1;
			
			RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
			//Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Email_Adress__c='test@test.com',EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id); //MN-30082021-US-0009948
			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id); //MN-30082021-US-0009948
			insert cs1;

			Coupon_Co_Invest__c coInvest = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc1.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
			insert coInvest;
			
			Test.startTest();
				cs1.UK_Coupon_Launch_Reminder_Date__c = System.now();
				update cs1;
			Test.stopTest();
			for(Task task : [select Id from Task where WhatId =: cs1.Id]){
				List<Attachment> lsttaskAtt = [select id,Name from Attachment where ParentId =: task.id];
				System.assertEquals(2,lsttaskAtt.size());
			}
			
		}
	} */
	
	/*static testMethod void testsendCpnAcceptOfCpnContr(){
		User admin1 = EBH_TestDataFactory.createUser('System Administrator');
    	admin1.FirstName = 'Test';
    	System.runAs(admin1)
    	{
    		//setupdata();
    		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
	    	Account acc1 = new Account(Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_EmailOut__c = false);
	        insert acc1;

			Contact con = new Contact(LastName='Test Con1', Email='test@test.com.invalid', AccountId=acc1.Id); //MN-30082021-US-0009948
        	insert con; //MN-30082021-US-0009948
	        
	    	RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
	        Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com');
			insert c1;
			
			RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
			//Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Email_Adress__c='test@test.com',EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id); //MN-30082021-US-0009948
			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id); //MN-30082021-US-0009948
			insert cs1;
    
			Coupon_Co_Invest__c coInvest = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc1.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
			insert coInvest;
			
			Test.startTest();
				cs1.Coupon_Seller_Stage__c = 'Contract Signed';
				update cs1;
			Test.stopTest();
			List<Task> lstTask = [select Id from Task where WhatId =: cs1.Id];
			System.assertEquals(1,lstTask.size());
			
    	}
	}*/

	@isTest
	static void test_preventRecordDeletion(){
		User admin1 = EBH_TestDataFactory.createUser('System Administrator');
    	admin1.FirstName = 'Test';
    	System.runAs(admin1)
    	{
    		//setupdata();
    		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
			//LA:05-12-2023-US-0014231: remove EBH_DealsProgram__c ='Accepted'
	    	//Account acc1 = new Account(Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
			Account acc1 = new Account(Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102',EBH_RevRollup__c='US');
	        insert acc1;
	        
			Contact con = new Contact(LastName='Test Con1', Email='test@test.com.invalid', AccountId=acc1.Id); //MN-30082021-US-0009948
        	insert con; //MN-30082021-US-0009948

	    	RecordType itemBasedCouponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c', CouponSellerTriggerHandler.COUPON_ITEMBASE); // Change history: 16.03.2022 / Chetra Sarom / 16.03.2022 / US-0010643 
			RecordType popCouponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c', CouponSellerTriggerHandler.POP_COUPON); // Chetra Sarom / 16.03.2022 / US-0010643

	        Coupon__c c1 = new Coupon__c(Stage__c = 'Draft', RecordTypeID = itemBasedCouponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCP008');
			Coupon__c c2 = new Coupon__c(Stage__c = 'Coupon Running', RecordTypeID = itemBasedCouponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCP009');
			Coupon__c c3 = new Coupon__c(Stage__c = 'Coupon Running', RecordTypeID = popCouponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCP010'); // Chetra Sarom / 16.03.2022 / US-0010643
			insert new List<Coupon__c>{c1,c2,c3};
			
			RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',CouponSellerTriggerHandler.COUPONSELLER_MANHATTAN_RECORDTYPE);
			RecordType couponPopCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',CouponSellerTriggerHandler.COUPON_POP_RECORDTYPE); // Chetra Sarom / 16.03.2022 / US-0010643
			// Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='T4 Statement Send',Email_Adress__c='test@test.com',EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id); //MN-30082021-US-0009948
			// Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c2.Id,Coupon_Seller_Stage__c='Targeted',Email_Adress__c='test1@test.com',EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id); //MN-30082021-US-0009948
			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='T34 Statement Send',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id); //MN-30082021-US-0009948
			Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c2.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id); //MN-30082021-US-0009948
			Coupon_Seller__c cs3 = new Coupon_Seller__c(Coupon__c = c3.Id,Coupon_Seller_Stage__c='New',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=couponPopCouponSellerRecordType.Id); // Chetra Sarom / 16.03.2022 / US-0010643
			insert new List<Coupon_Seller__c>{cs1,cs2,cs3};
    
			Test.startTest();
				//error in 1st filtering
				try {

					delete cs1;

				}catch(Exception ex) {
					//System.assert(ex.getMessage().contains(System.Label.Prevent_Deletion_of_Coupon_Seller));
				}

				//error in 2nd filtering
				try {

					delete cs2;

				}catch(Exception ex) {
					System.assert(ex.getMessage().contains(System.Label.Prevent_Deletion_of_Coupon_Seller));
				}

				// Chetra Sarom / 16.03.2022 / US-0010643 
				try {

					delete cs3;

				}catch(Exception ex) {
					System.assert(ex.getMessage().contains(System.Label.Prevent_Deletion_of_Pop_Coupon_Seller));
				}
				// US-0010643 END

			Test.stopTest();
			
			
    	}
	}
	@isTest
	static void test_addFileAttachment(){
		User admin1 = EBH_TestDataFactory.createUser('System Administrator');
    	admin1.FirstName = 'Test';
    	System.runAs(admin1)
    	{
    		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
			//LA:05-12-2023-US-0014231: remove EBH_DealsProgram__c ='Accepted'
	    	//Account acc1 = new Account(Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_EmailOut__c = false,EBH_RevRollup__c = 'UK',SP_Coupons__c = 'Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
			Account acc1 = new Account(Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_RevRollup__c = 'UK',SP_Coupons__c = 'Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
	        insert acc1;
	        
			Contact con = new Contact(LastName='Test Con1', Email='test@test.com.invalid', AccountId=acc1.Id); //MN-30082021-US-0009948
        	insert con;

	    	RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
	        Coupon__c c1 = new Coupon__c(MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1, Main_Coupon_Site__c='ebay.co.uk', Couponsite_s__c = 'ebay.co.uk', Coupon_ID__c = 'TestCP012');
			insert new List<Coupon__c>{c1};
			
			RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id); //MN-30082021-US-0009948
			insert new List<Coupon_Seller__c>{cs1};
			
			Coupon_Co_Invest__c coInvest = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc1.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
			insert coInvest;
    	
			Test.startTest();
			cs1.Coupon_Seller_Stage__c = 'Contract Signed';
			update cs1;
			Test.stopTest();
			
			List<Attachment> lstAtt = [select id from Attachment where ParentId =: cs1.Id];
			//System.assert(lstAtt.size() == 2,'2 Attachment should be add to Coupon seller');
    	}
	}

	@isTest
	static void test_calculateCouponSeller(){
		User admin1 = EBH_TestDataFactory.createUser('System Administrator');
    	admin1.FirstName = 'Test';
    	System.runAs(admin1)
    	{
    		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
			List<Account> listAcc = new List<Account>();
			for(Integer i = 0; i < 4; i++){
				Account acc = new Account(
						Name = 'Seller_'+(i+1),
						EBH_RevRollup__c = 'US',
						EBH_PrimarySite__c= 'UK',
						//EBH_DealsProgram__c='Accepted',//LA:05-12-2023-US-0014231: remove EBH_DealsProgram__c ='Accepted'
						RecordTypeId = sellerRecordType.Id,
                    	EBH_EmailOut__c = false,
						EBH_BillingAddress__c='PP',
						EBH_BillingCity__c='pp',
						EBH_BillingCountry__c='US',
						EBH_CompanyName__c='test',
						EBH_BillingPostalCode__c='12102',
						SP_Coupons__c = 'Full Access' //MN-15122022-US-0012734 
				);

				listAcc.add(acc);
			}
			insert listAcc;

			List<Contact> listCont = new List<Contact>();
			for(Integer i = 0; i < 4; i++){

				Contact cont = new Contact(
						LastName = 'SellerContact_'+(i+1),
						Email='test@test.com.invalid', 
						AccountId=listAcc[i].Id
				);

				listCont.add(cont);
			}
			insert listCont;

	    	RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
	        Coupon__c c1 = new Coupon__c(MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCP013');
			insert new List<Coupon__c>{c1};

			List<Coupon_Seller__c> listCS = new List<Coupon_Seller__c>();
			RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
			for(Integer i = 0; i < 4; i++){

				Coupon_Seller__c cs = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c=listCont[i].Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = listAcc[i].Id,RecordTypeID=manhattanCouponSellerRecordType.Id);

				listCS.add(cs);
			}
			insert listCS;
			
			Coupon_Co_Invest__c coInvest = new Coupon_Co_Invest__c(Coupon_Seller__c=listCS[0].Id,Seller_Name__c=listAcc[0].Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
			insert coInvest;
			listCS[1].Coupon_Seller_Stage__c = 'Contract Signed';
			update listCS;
			Test.startTest();
				listCS[0].Coupon_Seller_Stage__c = 'Contract Signed';
				listCS[1].Contract_Accept_Date__c = System.Now();
				update listCS;
				System.runAs(admin1)
    			{
					delete listCS[3];
				}

			Test.stopTest();
			List<Coupon__c> coupon = [select id,Sellers_Targeted2__c,Sellers_Contract_Send2__c,Sellers_Contract_Signed2__c from Coupon__c where Id =: c1.Id];
			System.assertEquals(3,coupon[0].Sellers_Targeted2__c);
			System.assertEquals(2,coupon[0].Sellers_Contract_Send2__c);
			System.assertEquals(1,coupon[0].Sellers_Contract_Signed2__c);
    	}
	}

	@isTest
	static void test_updateTransFileAccess(){
		User admin1 = EBH_TestDataFactory.createUser('System Administrator');
    	admin1.FirstName = 'Test';
    	System.runAs(admin1)
    	{
    		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
			//LA:05-12-2023-US-0014231: remove EBH_DealsProgram__c ='Accepted'
	    	//Account acc1 = new Account(Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
			Account acc1 = new Account(Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102',EBH_RevRollup__c='US');
	        insert acc1;
	        
			Contact con = new Contact(LastName='Test Con1', Email='test@test.com.invalid', AccountId=acc1.Id); //MN-30082021-US-0009948
        	insert con;

	    	RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
	        Coupon__c c1 = new Coupon__c(MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCP014');
			insert new List<Coupon__c>{c1};
			
			RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Coupon Running',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id); //MN-30082021-US-0009948
			insert new List<Coupon_Seller__c>{cs1};

			ContentVersion contentVersion_1 = new ContentVersion(
				Title = 'Penguins',
				PathOnClient = 'Penguins.csv',
				VersionData = Blob.valueOf('Test Content'),
				Description = 'File consists of Seller performance in this coupon'
            );
            insert contentVersion_1;

			List<ContentDocument> documents = [SELECT Id FROM ContentDocument];

			ContentDocumentLink cdl = new ContentDocumentLink(
				ContentDocumentId = documents[0].Id,
				LinkedEntityId  = cs1.Id
			);
            insert cdl;
    	
			Test.startTest();
			cs1.Trans_File_SF_ID__c = contentVersion_1.Id;
			update cs1;
			Test.stopTest();

			ContentDocumentLink updatedCDL = [SELECT Id, Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id LIMIT 1];
			System.assertEquals('AllUsers',updatedCDL.Visibility);
    	}
	}

	@isTest
	static void test_updateCoInvestFileAccess(){
		User admin1 = EBH_TestDataFactory.createUser('System Administrator');
    	admin1.FirstName = 'Test';
    	System.runAs(admin1)
    	{
    		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
			Account acc1 = new Account(Name='Test Abc1',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102',EBH_RevRollup__c='US');
	        insert acc1;
	        
			Contact con = new Contact(LastName='Test Con1', Email='test@test.com.invalid', AccountId=acc1.Id);
        	insert con;

	    	RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
	        Coupon__c c1 = new Coupon__c(MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCP016');
			insert new List<Coupon__c>{c1};
			
			RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Contract Signed',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc1.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
			insert new List<Coupon_Seller__c>{cs1};

			ContentVersion contentVersion_1 = new ContentVersion(
				Title = 'CoInvest File',
				PathOnClient = 'CoInvest.csv',
				VersionData = Blob.valueOf('Test CoInvest Content'),
				Description = 'File consists of CoInvest data for this coupon seller'
            );
            insert contentVersion_1;

			List<ContentDocument> documents = [SELECT Id FROM ContentDocument];

			ContentDocumentLink cdl = new ContentDocumentLink(
				ContentDocumentId = documents[0].Id,
				LinkedEntityId  = cs1.Id
			);
            insert cdl;
    	
			Test.startTest();
			cs1.CoInvestFileSFID__c = contentVersion_1.Id;
			update cs1;
			Test.stopTest();

			ContentDocumentLink updatedCDL = [SELECT Id, Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id LIMIT 1];
			System.assertEquals('AllUsers',updatedCDL.Visibility);
    	}
	}

    @isTest
	static void test_updateSPEligibility(){


    	User admin1 = EBH_TestDataFactory.createUser('System Administrator');
    	admin1.FirstName = 'Test';//by pass validation rule
    	System.runAs(admin1)
    	{
	        
	    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
	    	Account acc1 = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false,EBH_RevRollup__c='ES',SP_Main_Domain__c='wachstumsportal.ebay.de',SP_Coupons__c='Read Only');
	        //insert acc1;
			
			Account acc2 = new Account(Name='Test Abc2',RecordTypeID = sellerRecordType.Id,EBH_EmailOut__c = false, EBH_RevRollup__c='ES');
	        //insert acc2;

			insert new List<Account>{acc1,acc2};
			Contact con1 = new Contact(LastName='Test Con1', Email='test1@test.com.invalid', AccountId=acc1.Id);
			Contact con2 = new Contact(LastName='Test Con2', Email='test2@test.com.invalid', AccountId=acc2.Id);
        	insert new List<Contact>{con1, con2};
	        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
	        Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1, Main_Coupon_Site__c='ebay.de', Couponsite_s__c = 'ebay.de', Coupon_ID__c = 'TestCP015');
			insert c1;

			Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c = con2.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc2.Id);
			insert cs1;
			Coupon_Seller__c cs2 = new Coupon_Seller__c(Seller_Contact__c =  con1.Id,Coupon__c = c1.Id, Seller__c = acc1.Id, Coupon_Seller_Stage__c='Targeted');
			insert cs2;
			Coupon_Co_Invest__c coInvest = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc2.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
			insert coInvest;
			Coupon_Co_Invest__c coInvest2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs2.Id,Seller_Name__c=acc1.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
			insert coInvest2;
			
			Test.startTest();
            
				cs1.Legal_Entity_Name_w__c = 'test entity';
				cs1.Legal_Entity_Street_w__c = 'test street';
				cs1.Legal_Entity_Zip_w__c = 'test zip';
				cs1.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND ;
				update cs1;

				cs2.Legal_Entity_Name_w__c = 'test entity';
				cs2.Legal_Entity_Street_w__c = 'test street';
				cs2.Legal_Entity_Zip_w__c = 'test zip';
				cs2.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND ;
				update cs2;

			Test.stopTest();

			List<Coupon_Seller__c> listSeller = [select id,seller__r.SP_Main_Domain__c,seller__r.SP_Coupons__c from Coupon_Seller__c where coupon__c =: c1.Id];
			
			System.assertEquals('wachstumsportal.ebay.de',listSeller[0].seller__r.SP_Main_Domain__c);
			System.assertEquals('Full Access',listSeller[0].seller__r.SP_Coupons__c);
    	}
	}

    /**
     * US-0033151 AC4: Test automatic stage update for Program Coupon Sellers when Master Agreement Contract is accepted
     * 
     * Given: A user has the associated Coupon Permission set/s assigned
     * When: The Master Agreement Contract has been accepted and Stage has been set to Contract Signed
     * Then: Any associated Program Coupon Seller records should automatically be updated to Contract Signed stage
     * 
     * This tests the trigger-based automatic stage propagation from Master to Program Coupons
     */
	@isTest
    static void testAutoUpdateProgramCouponSellersWhenMasterContractSignedViaTrigger() {
        // Setup test data
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		RecordType masterAgreementRT = ApexUtil.getRecordTypeByName('Coupon_Seller__c','Master_Agreement_Seller');
		RecordType programCSRT = ApexUtil.getRecordTypeByName('Coupon_Seller__c','Program_Coupon_Seller');
        Account seller = new Account(
            Name='Test POP Seller', 
            RecordTypeID = sellerRecordType.Id,
            EBH_RevRollup__c ='DE', 
            SP_Coupons__c='Full Access',
            EBH_EmailOut__c = false,
            EBH_BillingAddress__c='Test Address',
            EBH_BillingCity__c='Berlin',
            EBH_BillingCountry__c='DE',
            EBH_CompanyName__c='Test Company',
            EBH_BillingPostalCode__c='12345'
        );
        insert seller;
        
        // Create Master Coupon (MC) with appropriate record type
        RecordType masterCouponRecordType = ApexUtil.getRecordTypeByName('Coupon__c', EBH_ConstantsUtility.COUPON_MASTER_RECORDTYPE);
        Coupon__c masterCoupon = new Coupon__c(
            RecordTypeID = masterCouponRecordType.Id,
            Main_Coupon_Site__c = 'ebay.de',
            Coupon_Co_invest_Type__c = 'Contra',
            Coupon_Start_Date__c = Date.today(),
            Coupon_End_Date__c = Date.today().addDays(30),
            Stage__c = 'Coupon Running',
            Marketing_Coupon_Name__c = 'Master Agreement Coupon for POP',
            Coupon_ID__c='MasterTest001'
        );
        insert masterCoupon;
        
        // Create Program Coupons linked to Master Coupon
        RecordType programCouponRecordType = ApexUtil.getRecordTypeByName('Coupon__c', EBH_ConstantsUtility.COUPON_PROGRAM_RECORDTYPE);
        List<Coupon__c> programCoupons = new List<Coupon__c>();
        for (Integer i = 1; i <= 3; i++) {
            programCoupons.add(new Coupon__c(
                Master_Coupon__c = masterCoupon.Id, // Link to Master Coupon
                RecordTypeID = programCouponRecordType.Id,
                Main_Coupon_Site__c = 'ebay.de',
                Coupon_Co_invest_Type__c = 'Contra',
                Coupon_Start_Date__c = Date.today(),
                Coupon_End_Date__c = Date.today().addDays(10),
                Stage__c = 'Coupon Running',
                Marketing_Coupon_Name__c = 'Program Coupon ' + i + ' for POP',
                Coupon_ID__c='Programtest001'
            ));
        }
        insert programCoupons;
        
        // Create Master Agreement Coupon Seller (the one that gets manually accepted)
        Coupon_Seller__c masterAgreementCouponSeller = new Coupon_Seller__c(
			RecordTypeID = masterAgreementRT.Id,
            Coupon__c = masterCoupon.Id,
            Seller__c = seller.Id,
            Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND, // Initially Contract Send
            Legal_Entity_Name_w__c = 'Test Legal Entity',
            Legal_Entity_Street_w__c = 'Test Street 123',
            Legal_Entity_Zip_w__c = '12345',
            Seller_Declined_Reasons__c = null // Has not opted-out
        );
        insert masterAgreementCouponSeller;
        
        // Create Program Coupon Sellers linked to Master Agreement Coupon Seller
        List<Coupon_Seller__c> programCouponSellers = new List<Coupon_Seller__c>();
        for (Coupon__c programCoupon : programCoupons) {
            programCouponSellers.add(new Coupon_Seller__c(
                Coupon__c = programCoupon.Id,
                Seller__c = seller.Id,
				recordTypeId = programCSRT.Id,
                Master_Agreement_Coupon_Seller__c = masterAgreementCouponSeller.Id, // Link to Master Agreement Coupon Seller
                //Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND, // Initially Contract Send
                Coupon_Seller_Stage__c = 'Draft', 
				Legal_Entity_Name_w__c = 'Test Legal Entity',
                Legal_Entity_Street_w__c = 'Test Street 123',
                Legal_Entity_Zip_w__c = '12345',
                Seller_Declined_Reasons__c = null // Has not opted-out
            ));
        }
        insert programCouponSellers;
        
        // Verify initial state - all should be in Contract Send stage
        /*List<Coupon_Seller__c> initialProgramSellers = [
            SELECT Id,RecordType.DeveloperName, Coupon_Seller_Stage__c, Master_Agreement_Coupon_Seller__c, Coupon__r.RecordType.DeveloperName
            FROM Coupon_Seller__c 
            WHERE Coupon__c IN :programCoupons
        ];
        
        for (Coupon_Seller__c cs : initialProgramSellers) {
            System.assertEquals(
                EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND, 
                cs.Coupon_Seller_Stage__c,
                'Program Coupon Seller should initially be in Contract Send stage'
            );
        }*/
        
        Test.startTest();
        
        // AC4 TRIGGER: Update Master Agreement Coupon Seller to Contract Signed
        // This should trigger automatic update of all associated Program Coupon Sellers
        masterAgreementCouponSeller.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED;
        masterAgreementCouponSeller.Contract_Accept_Date__c = Date.today();
        update masterAgreementCouponSeller;
        
        Test.stopTest();
        
        // AC4 VERIFICATION: All associated Program Coupon Sellers should now be Contract Signed
        List<Coupon_Seller__c> updatedProgramSellers = [
            SELECT Id, Coupon_Seller_Stage__c, Master_Agreement_Coupon_Seller__c, Coupon__r.RecordType.DeveloperName,
                   Master_Agreement_Coupon_Seller__r.Id, Contract_Accept_Date__c
            FROM Coupon_Seller__c 
            WHERE Coupon__c IN :programCoupons
            ORDER BY Coupon__r.Name
        ];

        System.assertEquals(3, updatedProgramSellers.size(), 'Should have 3 Program Coupon Sellers');
        
        for (Coupon_Seller__c cs : updatedProgramSellers) {
			
			// CSP-16102025:US-0033614 Start
            System.assertEquals(
                'Opted-In', 
                cs.Coupon_Seller_Stage__c,
                'Program Coupon Seller stage should be automatically updated to Opted-In when Master Agreement Contract is accepted'
            );
			// CSP-16102025:US-0033614 End
            
            System.assertEquals(
                masterAgreementCouponSeller.Id, 
                cs.Master_Agreement_Coupon_Seller__c,
                'Program Coupon Seller should be linked to Master Agreement Coupon Seller'
            );
            
            System.assertEquals(
                EBH_ConstantsUtility.COUPON_PROGRAM_RECORDTYPE, 
                cs.Coupon__r.RecordType.DeveloperName,
                'Should be Program Coupon record type'
            );
        }
        
        // Verify the Master Agreement Coupon Seller was updated correctly
        Coupon_Seller__c updatedMasterSeller = [
            SELECT Id, Coupon_Seller_Stage__c, Contract_Accept_Date__c
            FROM Coupon_Seller__c 
            WHERE Id = :masterAgreementCouponSeller.Id
        ];
        
        System.assertEquals(
            EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED, 
            updatedMasterSeller.Coupon_Seller_Stage__c,
            'Master Agreement Coupon Seller should be Contract Signed'
        );
        
        System.assertEquals(
            Date.today(), 
            updatedMasterSeller.Contract_Accept_Date__c,
            'Master Agreement Coupon Seller should have Contract Accept Date set'
        );
    }

	/**
	 * Test method for populateMasterAgreementCouponSellerField with maximum bulk scenario
	 * Tests 200 Program Coupon Sellers each with different Master Coupons (200 master coupons total)
	 * Validates enterprise-scale bulk processing, governor limits compliance, and Master Agreement creation logic
	 * US-0033512 - POP - Create Master Coupon Seller Automation Trigger
	 */
	@isTest
	static void testPopulateMasterAgreementCouponSellerField() {
		
		// Get record types
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		RecordType masterAgreementRT = ApexUtil.getRecordTypeByName('Coupon_Seller__c','Master_Agreement_Seller');
		RecordType programCSRT = ApexUtil.getRecordTypeByName('Coupon_Seller__c','Program_Coupon_Seller');
		RecordType masterCouponRT = ApexUtil.getRecordTypeByName('Coupon__c','Single_Contract_Multi_Coupon_SCMC_Category_Based');
		RecordType programCouponRT = ApexUtil.getRecordTypeByName('Coupon__c','Program_Coupon');
		
		// Create 200 test sellers (one for each program coupon seller)
		List<Account> sellers = new List<Account>();
		for(Integer i = 1; i <= 200; i++) {
			sellers.add(new Account(
				Name = 'Bulk Test Seller ' + i,
				RecordTypeId = sellerRecordType.Id,
				EBH_RevRollup__c = 'DE',
				EBH_EmailOut__c = false,
				SP_Coupons__c = 'Full Access',
				EBH_BillingAddress__c = 'Address ' + i + ' Main St',
				EBH_BillingCity__c = 'Berlin',
				EBH_BillingCountry__c = 'DE',
				EBH_CompanyName__c = 'Bulk Test Company ' + i,
				EBH_BillingPostalCode__c = String.valueOf(10000 + Math.mod(i, 9999))
			));
		}
		insert sellers;
		
		// Create 200 different master coupons (one for each program coupon)
		List<Coupon__c> masterCoupons = new List<Coupon__c>();
		for(Integer i = 1; i <= 200; i++) {
			masterCoupons.add(new Coupon__c(
				RecordTypeId = masterCouponRT.Id,
				Main_Coupon_Site__c = 'ebay.de',
				Coupon_Co_invest_Type__c = 'Contra',
				Marketing_Coupon_Name__c = 'Bulk Master Coupon ' + i,
				Coupon_ID__c = 'BulkMasterCoupon' + String.valueOf(10000 + i),
				Stage__c = 'Draft'
			));
		}
		insert masterCoupons;
		
		// Create 200 program coupons, each linked to a different master coupon
		List<Coupon__c> programCoupons = new List<Coupon__c>();
		for(Integer i = 0; i < 200; i++) {
			programCoupons.add(new Coupon__c(
				RecordTypeId = programCouponRT.Id,
				Main_Coupon_Site__c = 'ebay.de',
				Coupon_Co_invest_Type__c = 'Contra',
				Marketing_Coupon_Name__c = 'Bulk Program Coupon ' + (i + 1),
				Master_Coupon__c = masterCoupons[i].Id,
				Coupon_ID__c = 'BulkProgramCoupon' + String.valueOf(20000 + i + 1),
				Stage__c = 'Draft'
			));
		}
		insert programCoupons;
		
		// Create some existing Master Agreement Coupon Sellers for partial coverage testing
		// Create existing Master Agreement records for first 50 master coupons with different stages
		List<Coupon_Seller__c> existingMasterCS = new List<Coupon_Seller__c>();
		for(Integer i = 0; i < 50; i++) {
			String stage = (Math.mod(i, 3) == 0) ? 'Contract Signed' : 
						   (Math.mod(i, 3) == 1) ? 'Contract Send' : 'Draft';
			existingMasterCS.add(new Coupon_Seller__c(
				RecordTypeId = masterAgreementRT.Id,
				Coupon__c = masterCoupons[i].Id,
				Seller__c = sellers[i].Id,
				CoInvestFileSFID__c = 'ExistingMaster' + String.valueOf(i + 1),
				Coupon_Seller_Stage__c = stage
			));
		}
		insert existingMasterCS;
		
		// Create 200 Program Coupon Sellers, each with different seller and different master coupon
		List<Coupon_Seller__c> programCouponSellers = new List<Coupon_Seller__c>();
		for(Integer i = 0; i < 200; i++) {
			programCouponSellers.add(new Coupon_Seller__c(
				RecordTypeId = programCSRT.Id,
				Coupon__c = programCoupons[i].Id,
				Seller__c = sellers[i].Id,
				CoInvestFileSFID__c = 'BulkMaxTestFile' + String.valueOf(i + 1),
				Coupon_Seller_Stage__c = 'Draft'
			));
		}
		
		Test.startTest();
		
			// Insert all 200 Program Coupon Sellers in one bulk operation
			insert programCouponSellers;
		
		Test.stopTest();
		
		// Comprehensive result verification
		List<Coupon_Seller__c> allProgramCS = [
			SELECT Id, Coupon_Seller_Stage__c, Master_Agreement_Coupon_Seller__c, Seller__c, 
				   Coupon__c, Coupon__r.Master_Coupon__c, CoInvestFileSFID__c, RecordTypeId
			FROM Coupon_Seller__c 
			WHERE RecordTypeId = :programCSRT.Id
			ORDER BY CreatedDate, Id
		];
		
		List<Coupon_Seller__c> allMasterCS = [
			SELECT Id, Coupon_Seller_Stage__c, Seller__c, Coupon__c, CoInvestFileSFID__c, RecordTypeId
			FROM Coupon_Seller__c 
			WHERE RecordTypeId = :masterAgreementRT.Id
			ORDER BY Coupon__c, Seller__c
		];
		
		// Verify all 200 Program Coupon Sellers were created successfully
		System.assertEquals(200, allProgramCS.size(), 'Should have exactly 200 program coupon sellers');
		
		// Verify that every Program Coupon Seller has Master Agreement Coupon Seller field populated
		Set<Id> masterAgreementIds = new Set<Id>();
		for(Coupon_Seller__c programCS : allProgramCS) {
			System.assertNotEquals(null, programCS.Master_Agreement_Coupon_Seller__c, 
								  'Master Agreement Coupon Seller field must be populated for Program CS: ' + programCS.Id);
			masterAgreementIds.add(programCS.Master_Agreement_Coupon_Seller__c);
		}
		
		// Verify Master Agreement Coupon Sellers count
		// Should have 50 existing + 150 newly created = 200 total (one per unique master coupon)
		System.assertEquals(200, allMasterCS.size(), 'Should have exactly 200 master agreement coupon sellers (50 existing + 150 newly created)');
		
		// Verify that we have unique Master Agreement records (no duplicates)
		System.assertEquals(200, masterAgreementIds.size(), 'All Program Coupon Sellers should link to unique Master Agreement records');
		
		// Verify stage logic for Program Coupon Sellers based on Master Agreement stages
		Integer optedInCount = 0;
		Integer draftCount = 0;
		Map<Id, String> masterCSStageMap = new Map<Id, String>();
		
		// Build map of Master Agreement stages
		for(Coupon_Seller__c masterCS : allMasterCS) {
			masterCSStageMap.put(masterCS.Id, masterCS.Coupon_Seller_Stage__c);
		}
		
		// Check Program Coupon Seller stage updates
		for(Coupon_Seller__c programCS : allProgramCS) {
			String masterStage = masterCSStageMap.get(programCS.Master_Agreement_Coupon_Seller__c);
			if(programCS.Coupon_Seller_Stage__c == 'Opted-In') {
				optedInCount++;
				// Should be Opted-In only if Master Agreement is Contract Signed
				System.assertEquals('Contract Signed', masterStage, 
								   'Program CS should be Opted-In only when Master Agreement is Contract Signed');
			} else if(programCS.Coupon_Seller_Stage__c == 'Draft') {
				draftCount++;
				// Should be Draft if Master Agreement is not Contract Signed
				System.assertNotEquals('Contract Signed', masterStage, 
									  'Program CS should remain Draft when Master Agreement is not Contract Signed');
			}
		}
		
		// Verify proper stage distribution based on test data setup
		System.assert(optedInCount >= 16, 'Should have at least 16 Program Coupon Sellers in Opted-In status (Contract Signed Masters)');
		System.assert(draftCount >= 180, 'Should have at least 180 Program Coupon Sellers in Draft status');
		System.assertEquals(200, optedInCount + draftCount, 'All Program Coupon Sellers should be accounted for');
		
		// Verify data integrity and relationships
		Set<String> sellerMasterCombinations = new Set<String>();
		for(Coupon_Seller__c programCS : allProgramCS) {
			// Verify each Program CS has unique seller-master coupon combination
			String combination = programCS.Seller__c + '_' + programCS.Coupon__r.Master_Coupon__c;
			System.assert(!sellerMasterCombinations.contains(combination), 
						 'Each seller-master coupon combination should be unique');
			sellerMasterCombinations.add(combination);
			
			// Find corresponding Master Agreement CS and verify relationship
			Coupon_Seller__c relatedMasterCS = null;
			for(Coupon_Seller__c masterCS : allMasterCS) {
				if(masterCS.Id == programCS.Master_Agreement_Coupon_Seller__c) {
					relatedMasterCS = masterCS;
					break;
				}
			}
			
			System.assertNotEquals(null, relatedMasterCS, 
								  'Should find corresponding Master Agreement CS for Program CS: ' + programCS.Id);
			System.assertEquals(programCS.Seller__c, relatedMasterCS.Seller__c, 
							   'Master Agreement CS should have same seller as Program CS');
			System.assertEquals(programCS.Coupon__r.Master_Coupon__c, relatedMasterCS.Coupon__c, 
							   'Master Agreement CS should be linked to correct Master Coupon');
		}
		
		// Verify performance and governor limits compliance
		System.assertEquals(200, sellerMasterCombinations.size(), 
						   'Should have 200 unique seller-master coupon combinations');
		
	}

}