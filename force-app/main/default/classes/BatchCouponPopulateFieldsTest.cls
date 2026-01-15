@isTest
private class BatchCouponPopulateFieldsTest {

    @isTest
	static void testCouponPopulateFields(){
		User admin1 = EBH_TestDataFactory.createUser('System Administrator');
    	admin1.FirstName = 'Test';
    	System.runAs(admin1)
    	{
    		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
			List<Account> listAcc = new List<Account>();
			for(Integer i = 0; i < 4; i++){
				
				Account acc = new Account(
						Name = 'Seller_'+(i+1),
						EBH_RevRollup__c = 'UK',
						EBH_PrimarySite__c= 'UK',
						//EBH_DealsProgram__c='Accepted',//LA:05-12-2023-US-0014231
						RecordTypeId = sellerRecordType.Id,
						SP_Coupons__c = 'Full Access',
						EBH_BillingAddress__c='PP',
						EBH_BillingCity__c='pp',
						EBH_BillingCountry__c='US',
						EBH_CompanyName__c='test',
						EBH_BillingPostalCode__c='12102'
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
	        Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c = 'ebay.co.uk',Coupon_Co_invest_Type__c='Contra',MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1);
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
            listCS[0].Coupon_Seller_Stage__c = 'Contract Signed';
			listCS[1].Contract_Accept_Date__c = System.Now();
			update listCS;

			Test.startTest();
            
                c1.Sellers_Targeted2__c = 0;
				c1.Sellers_Contract_Send2__c = 0;
				c1.Sellers_Contract_Signed2__c = 0;
				update c1;
				BatchCouponPopulateFields bc = new BatchCouponPopulateFields(new Set<Id>{c1.Id});
				Database.executeBatch(bc, 25);

			Test.stopTest();
			List<Coupon__c> coupon = [select id,Sellers_Targeted2__c,Sellers_Contract_Send2__c,Sellers_Contract_Signed2__c from Coupon__c where Id =: c1.Id];
			System.assertEquals(4,coupon[0].Sellers_Targeted2__c);
			System.assertEquals(2,coupon[0].Sellers_Contract_Send2__c);
			System.assertEquals(1,coupon[0].Sellers_Contract_Signed2__c);
    	}
	}
}