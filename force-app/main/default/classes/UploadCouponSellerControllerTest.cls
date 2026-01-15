/*********************************************************************************************************************************
@ Method:         UploadCouponSellerControllerTest
@ Version:        1.0
@ Author:         Chetra Sarom (chetra.sarom@gaea-sys.com)
@ Purpose:        US-0012713 - Seller Bulk Upload functionality - Extend excel copy paste feature
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  01.02.2023 / Chetra Sarom / Created the method.
*********************************************************************************************************************************/

@isTest
public with sharing class UploadCouponSellerControllerTest {
    @isTest static void testimportCSPreDML(){
        
        //MN-30012024-US-0014758: Select 1 inactive admin user so that we can test the inactive user scenario
        User inactiveUser = [SELECT Id, IsActive FROM User WHERE IsActive = false AND Profile.Name like 'System Administrator%' LIMIT 1];
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType couponCategoryRecordType = ApexUtil.getRecordTypeByName('Coupon__c','Category_Based');
        //LA:05-12-2023-US-0014231
        //Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='US',EBH_DealsProgram__c ='Accepted',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
		Account acc = new Account(EBH_Status__c = 'Confirmed',EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='US',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        Account acc1 = new Account(EBH_Status__c = 'Confirmed',Name='Test Acc2',RecordTypeID = sellerRecordType.Id, EBH_OracleID__c = 'test21312',EBH_EmailOut__c = false,EBH_RevRollup__c='US');
        Account acc2 = new Account(EBH_Status__c = 'Confirmed',Outreach_Manager__c=inactiveUser.Id, EBH_OracleId__c='1003293592',Name='Test Acc3',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='US',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        Account acc3 = new Account(EBH_Status__c = 'Confirmed',EBH_OracleId__c='1003293593',Name='Test Acc4',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='US',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert new list<Account>{acc, acc1, acc2, acc3};
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponCategoryRecordType.Id, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com',Coupon_Co_invest_Type__c = 'Contra');
		insert c1;
		Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc1.Id);
    	insert cs1;
        
        String headerStr = 'oracle_id__c,sellershareholder__c,EBH_CouponSellerOwner__c,ebay_co_fund_max__c,Additional_Terms_Override_of_Agreement__c,item_limit__c';
        String rowStr = '1003293591,10,%CouponSellerOwner%,10,Additional Terms,100';
        rowStr = rowStr.replace('%CouponSellerOwner%',UserInfo.getUserId());
        List<String> listHeaderCol = headerStr.split(',');
        List<String> listRowCol = rowStr.split(',');
        
        List<Map<String,String>> listRecord = new List<Map<String,String>>();
        Map<String,String> mapObj = new Map<String,String>();
        for(Integer i = 0; i < listHeaderCol.size(); i++){
            mapObj.put(listHeaderCol[i], listRowCol[i]);
        }
        
        listRecord.add(mapObj);

        //MN-19122023-US-0014106--START
        listRecord.add(generatExcelData('1001288282,10,%CouponSellerOwner%,10,Additional Terms,100', listHeaderCol));

        listRecord.add(generatExcelData('1003293591,10,%CouponSellerOwner%,10,Additional Terms,100', listHeaderCol));

        listRecord.add(generatExcelData('1003293591,10,%CouponSellerOwner%,10,Additional Terms,10000', listHeaderCol));

        listRecord.add(generatExcelData('1003293591,10,%CouponSellerOwner%,abc,Additional Terms,10', listHeaderCol));
        
        listRecord.add(generatExcelData('1003293591,abc,%CouponSellerOwner%,10,Additional Terms,10', listHeaderCol));

        listRecord.add(generatExcelData('1003293592,10,%CouponSellerOwner%,10,Additional Terms,10', listHeaderCol));

        listRecord.add(generatExcelData('1003293593,10,%CouponSellerOwner%,10,Additional Terms,abc', listHeaderCol));

        //MN-19122023-US-0014106--START

        Map<String, Object> mapArgs = new Map<String, Object>();
        mapArgs.put('parentId', c1.Id);
        mapArgs.put('listRecord', listRecord);
        mapArgs.put('startIndex', 0);
        mapArgs.put('locale', 'en');
        mapArgs.put('hasHeader', true);
        mapArgs.put('isExcelImporterV2', false);

        Test.startTest();

        Callable extension = (Callable) Type.forName('UploadCouponSellerController').newInstance();
        Map<String, Object> mapResult = (Map<String, Object>) extension.call('importCSPreDML', mapArgs);
        Map<Integer, String> mapIndexToErrMsg =  (Map<Integer, String>)(JSON.deserialize(JSON.serialize(mapResult.get('mapIndexToErrMsg')), Map<Integer, String>.class)); 
        Test.stopTest();
    }

    private static Map<String,String> generatExcelData(String rowStr, List<String> listHeaderCol) {
        rowStr = rowStr.replace('%CouponSellerOwner%',UserInfo.getUserId());
        List<String> listRowCol = rowStr.split(',');

        Map<String,String> mapObj = new Map<String,String>();
        for(Integer i = 0; i < listHeaderCol.size(); i++){
            mapObj.put(listHeaderCol[i], listRowCol[i]);
        }

        return mapObj;
    }

    @isTest
    private static void testgenerateSellerToolURLParam(){

        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType couponCategoryRecordType = ApexUtil.getRecordTypeByName('Coupon__c','Category_Based');
        Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='US',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        Account acc1 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id, EBH_OracleID__c = 'test21312',EBH_EmailOut__c = false);
        insert new list<Account>{acc,acc1};
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponCategoryRecordType.Id, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com',Coupon_Co_invest_Type__c = 'Contra');
		insert c1;

        //Create Category Level 1
        Category_Tree__c ct1 = new Category_Tree__c(Name = 'Meta Level', Level__c=1, Active__c=true, Site__c='0');
        insert ct1;

        //Create category level 2
        Category_Tree__c ct2 = new Category_Tree__c(Name = 'Level 2', Level__c=2, Active__c=true, Site__c='0', Note_ID__c=ct1.Id);
        insert ct2;

        //Create category level 3
        Category_Tree__c ct3 = new Category_Tree__c(Name = 'Level 3', Level__c=3, Active__c=true, Site__c='0', Note_ID__c=ct2.Id);
        insert ct3;

        //Create category level 4
        Category_Tree__c ct4 = new Category_Tree__c(Name = 'Level 4', Level__c=4, Active__c=true, Site__c='0', Note_ID__c=ct3.Id);
        insert ct4;

        //Create Coupon Category
        Coupon_Category__c cc = new Coupon_Category__c(Category__c=ct4.Id, Coupon__c=c1.Id, Seller_Share__c = 1);
        insert cc;

        Map<String,Object> mapResult;

        Test.startTest();
            mapResult = UploadCouponSellerController.generateSellerToolURLParam(c1.Id);
            System.assertEquals(mapResult.get('status'), 'ok');
            System.assert( mapResult.containsKey('mapCategory'), 'There should be mapCategory return.' );
        Test.stopTest();

    }

    
}