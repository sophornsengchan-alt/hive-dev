/*********************************************************************************************************************************
@ Class:        CouponCategoryControllerTest
@ Version:      1.0
@ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:      US-0013712 - Add filter on coupon category component
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.06.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
@isTest
private class CouponCategoryControllerTest {
    static testMethod void testCategorySelectionAndSave() {

        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType couponRecordType = ApexUtil.getRecordTypeByName('Coupon__c','Category_Based');
         
        Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='DE', EBH_EmailOut__c = false, SP_Coupons__c = 'Full Access');
        insert acc;

        Coupon__c c1 = new Coupon__c(RecordTypeID = couponRecordType.Id, Main_Coupon_Site__c = 'ebay.de', Coupon_Co_invest_Type__c='Contra');
        insert c1;
        
     	Category_Tree__c ct0 = new Category_Tree__c(Name = 'l0',Active__c=true,Site__c='77', Level__c = 0);
     	insert ct0;
    	Category_Tree__c ct1 = new Category_Tree__c(Name = 'l1',Note_ID__c=ct0.Id,Active__c=true, Site__c='77',  Level__c = 1);
    	insert ct1;
		Category_Tree__c ct2 = new Category_Tree__c(Name = 'l2',Note_ID__c = ct1.Id,Active__c=true, Site__c='77',  Level__c = 2);
		insert ct2;
		Category_Tree__c ct3 = new Category_Tree__c(Name = 'l3',Note_ID__c = ct2.Id,Active__c=true, Site__c='77',  Level__c = 3);
    	insert ct3;
         	
        Test.startTest();
        	
            Map<String,Object> result = CouponCategoryController.apexQueryCat(null,c1.Id,null, null); // test init
            System.assertEquals(1,((List<Object>)result.get('listResult')).size());

            result = CouponCategoryController.apexQueryCat('77',c1.Id ,ct2.Id, null ); // test selected level 2
            System.assertEquals(1,((List<Object>)result.get('listResult')).size());

            // test save level 3
            List<Coupon_Category__c> listCouponCat = new List<Coupon_Category__c>{new Coupon_Category__c(Category__c = ct3.Id, Coupon__c = c1.Id, Exception_Category__c = false, External_Id__c = null, Seller_Share__c = 10 )};

         	Map<String,Object> resultSave = CouponCategoryController.apexSaveCat(listCouponCat);
         	System.assertEquals('ok',resultSave.get('status'),'save success');
         	

         Test.stopTest();
        
    }
}