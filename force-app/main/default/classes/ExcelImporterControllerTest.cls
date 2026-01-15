/*********************************************************************************************************************************
@ Class:          ExcelImporterControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0011643 - SPIKE Implement Excel import module using JS to support copy paste
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  17.06.2022 / Sophal Noch / Created the class.
@               : 11.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
*********************************************************************************************************************************/
@isTest
private class ExcelImporterControllerTest {
    private static RecordType rtAdvertiser = [SELECT id FROM recordType WHERE name = 'Advertiser' AND sobjectType = 'Account'];

    @isTest
    private static void testUploadExcel(){

        //17.06.2022 / Sophal Noch / US-0011643 : test method for ExcelImporterController methods

        ApexPages.currentPage().getParameters().put('template','test');
        new ExcelImporterController();
        ExcelImporterController.getExcelImporterTemplate('test', null);

        Map<String,String> mapObject = new Map<String,String>{'Name'=>'Test1'};

        Map<String,Object> mapResult;

        Test.startTest();
            mapResult = ExcelImporterController.saveRecords('Account','Insert', new List<Map<String,String>>{mapObject}, null);
            System.assertEquals(null, mapResult.get('error'));

            Account insertedAccount = [Select Id, Name From Account Where Name = 'Test1'];
            mapObject.put('Id',insertedAccount.Id);
            mapResult = ExcelImporterController.saveRecords('Account','Update', new List<Map<String,String>>{mapObject}, null);
            System.assertEquals(null, mapResult.get('error'));


            mapObject.remove('Id');
            mapObject.put('Name','Test2');
            mapResult = ExcelImporterController.saveRecords('Account','Upsert', new List<Map<String,String>>{mapObject}, null);
            System.assertEquals(null, mapResult.get('error'));

        Test.stopTest();

    }

    @isTest
    private static void testUploadExcelV2(){

        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType couponCategoryRecordType = ApexUtil.getRecordTypeByName('Coupon__c','Category_Based');
        //LA:05-12-2023-US-0014231
        //Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='US',EBH_DealsProgram__c ='Accepted',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
		Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='US',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        Account acc1 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id, EBH_OracleID__c = 'test21312',EBH_EmailOut__c = false);
        insert new list<Account>{acc,acc1};
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponCategoryRecordType.Id, Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com',Coupon_Co_invest_Type__c = 'Contra',  Coupon_ID__c = 'TESTCOUPON001');
		insert c1;

        Map<String,Object> mapResult;

        Test.startTest();
            mapResult = ExcelImporterController.getExcelImporterTemplate('Bulk_Upload_Coupon_Sellers', c1.Id);
            System.assert(mapResult.containsKey('parentObjectLabel'), 'There should be parentObjectLabel key in mapResult');
            System.assert(mapResult.get('parentObjectLabel') == 'Coupon', 'The parent label should be "Coupon"');
        Test.stopTest();

    }

    @isTest
    private static void testImportAdProduct(){
        // 28.09.2022 / Sophal Noch / US-0011695 
        byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Quote QuoteLineItem Opportunity', byPass_Trigger__c = false, byPass_WFRule__c = true);
        insert bp;

        Account account = new Account(
    		Name = 'Account test',
    		BillingStreet = 'Test',
            BillingPostalCode = 'test',
            BillingCity = 'test',
            BillingState = 'test',
            BillingCountry = 'Germany',
            Phone = '+1234567890',
            Record_Type_Text__c = 'Advertiser',
            recordTypeid = rtAdvertiser.id
		);
        insert account;

        Opportunity opp = new Opportunity(AccountId = account.Id, Name = 'Test Opp',StageName='Qualified Meeting',CloseDate=Date.newInstance( 2021, 1, 1),RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay').Id);
        insert opp;

        List<Map<String,String>> listRecord = new List<Map<String,String>>();
        for(Ad_Product__c adProd : [Select Id, Name From Ad_Product__c Where Opportunity__c =: opp.Id]){
            listRecord.add(new Map<String,String>{'Id'=> adProd.Id, 'Name' =>  adProd.Name});
        }
        ExcelImporterController.getExcelImporterTemplate('Ad_Product_Import', opp.Id);
        ExcelImporterController.saveRecords('Ad_Product__c','Update',listRecord,'Ad_Product_Import');


    }

    @isTest static void testServerSidePreDMLCheck(){

        // 12.12.2022 / Sophal Noch / US-0012119
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account testDataMap = new Account(Name='se1',RecordTypeID = sellerRecordType.Id);
        insert testDataMap;
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(EBH_SpotlightCategoryID__c='1111');
        insert sc; 
        EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(EBH_Slots__c =2);
        insert dsa1;
       
        String headerStr = 'ebh_ebayitemid__c,ebh_businessname__c,ebh_producttitle__c,ebh_ean__c,ebh_sellerprice__c,ebh_dealprice__c,ebh_dealstartdate__c,ebh_dealstarttime__c,ebh_dealenddate__c,ebh_dealendtime__c,ebh_recommendedretailpricewas__c,ebh_rrpwasprice__c,ebh_quantity__c,ebh_dealdateearliestpossible__c,ebh_dealformat__c,ebh_spotlightcategory__c,ebh_idealolink__c,ebh_amazonlink__c,ebay_link_url__c,ebh_picturelink__c,ebh_commentfromebaysourcer__c,ebh_commentfromseller__c,ebh_category__c,ebh_dealretailcampaign__c,ebh_selleremail__c,ebh_dealsiteid__c,ownerid';
        String rowStr = '12312414,%sellerName%,test1,13,200,20,30/6/2019,3:00,30/7/2019,5:00,10,9,50,5/7/19,Primary,%spotlightCategory%,www.test.com,www.test.com,www.test.com,www.test.com,Test Suer ,Test Suer ,Immobilien,%RetailCampaignID%,sovantheany.dim@gmail.com,UK,%OwnerID%';
        rowStr = rowStr.replace('%sellerName%',testDataMap.Name);
        rowStr = rowStr.replace('%RetailCampaignID%',dsa1.Id);
        rowStr = rowStr.replace('%OwnerID%',UserInfo.getUserId());
        rowStr = rowStr.replace('%spotlightCategory%',sc.EBH_SpotlightCategoryID__c);


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
        mapArgs.put('startIndex', 0);
        mapArgs.put('locale', 'en');

        Test.startTest();

        Map<String, Object> mapResult = ExcelImporterController.serverSidePreDMLCheck('EBH_UploadDealController.DealImport','importDealPreDML',mapArgs);

        Map<Integer, String> mapIndexToErrMsg =  (Map<Integer, String>)(JSON.deserialize(JSON.serialize(mapResult.get('mapIndexToErrMsg')), Map<Integer, String>.class)); 
        if(!mapIndexToErrMsg.isEmpty()){ System.debug('nsp : mapIndexToErrMsg == '+mapIndexToErrMsg); }
        System.assertEquals(0, mapIndexToErrMsg.size());

        Test.stopTest();
    }

    @isTest
    private static void testUploadNADeal(){

        //  19.05.2023 / Sophal Noch / US-0013298 : 

        String headerStr = 'OwnerId;EBH_Vertical__c;LeadSource;OtherLeadSource__c;Company;Website;LastName;FirstName;Email;Title;Role__c;Street;City;State;PostalCode;Site__c;Phone;LeadSegment__c;Shopping_Card__c;EBH_OracleID__c;EBH_eBayID__c';
        String rowStr1 = '{!ownerId1};Collectibles;Tradeshow;Event xyz;"Rosery, Inc.";XXXX;Red;Rose;Rose@roseryinc.com;lastNameHere;XXXXX;XXXXX;XXXXX;XXXXX;11110;AU;000 000 0000;Brand;;{!oracleId1};{!accId1}';
        String rowStr2 = '{!ownerId2};Fashion;Tradeshow;Event abc;"Lily, Inc.";YYYYY;Blue;Lily;Lily@flowerlily.com;lastNameHere;XXXXX;XXXXX;XXXXX;XXXXX;1111;AU;000 000 0000;Brand;;{!oracleId2};{!accId2}';

        String dateFm = '01/01/2021';

        RecordType partnerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Partner');
        Account acc = new Account(EBH_OracleId__c='123456789',Name='Test Acc1',RecordTypeID = partnerRecordType.Id,EBH_PartnerType__c='Shop System');
        insert acc;

        rowStr1 = rowStr1.replace('{!ownerId1}', UserInfo.getUserId());
        rowStr1 = rowStr1.replace('{!accId1}', acc.Id);
        rowStr1 = rowStr1.replace('{!oracleId1}', acc.EBH_OracleId__c);
        rowStr1 = rowStr1.replace('{!date}', dateFm);

        rowStr2 = rowStr2.replace('{!ownerId2}', UserInfo.getUserId());
        rowStr2 = rowStr2.replace('{!accId2}', acc.Id);
        rowStr2 = rowStr2.replace('{!oracleId2}', acc.EBH_OracleId__c);
        rowStr2 = rowStr2.replace('{!date}', dateFm);

        List<String> listHeaderCol = headerStr.split(';');
        List<String> listRowCol1 = rowStr1.split(';');
        List<String> listRowCol2 = rowStr2.split(';');


        List<Map<String,String>> listRecord = new List<Map<String,String>>();
        Map<String,String> mapObj1 = new Map<String,String>();
        Map<String,String> mapObj2 = new Map<String,String>();
        for(Integer i = 0; i < listHeaderCol.size(); i++){
            mapObj1.put(listHeaderCol[i], listRowCol1[i]);
            mapObj2.put(listHeaderCol[i], listRowCol2[i]);
        }
        listRecord.add(mapObj1);
        listRecord.add(mapObj2);

        Test.startTest();
        Map<String,Object> mapResult = ExcelImporterController.saveRecords('Lead','Insert',listRecord,'Upload_NA_Lead');
        Test.stopTest();

        System.assertEquals(null, mapResult.get('error'));
        System.assertEquals(2, [Select Id From Lead Where EBH_eBayID__c =: acc.Id].size());
        System.assertEquals(true, [Select Id, isSkipDupRule__c From Lead Where EBH_eBayID__c =: acc.Id Limit 1]?.isSkipDupRule__c);

       

    }

    
	@isTest 
    private static void testBulkExport(){
        // 17.10.2023 / Sophal Noch / US-0014165 
		List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
		//admUsers[0].BoB_Country__c = '3';
		admUsers[0].FederationIdentifier = 'adminTest';
		insert admUsers;
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_EmailOut__c = false);//LA:05-12-2023-US-0014231: Remove EBH_DealsProgram__c='Accepted'
		insert acc;
		RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
		BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
		insert bob;

        RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB_Seller__c bobSeller = new BoB_Seller__c(Seller__c = acc.Id, account_manager__c = admUsers[0].Id, ttec_manager__c = admUsers[0].Id, parent_seller__c =  acc.Id, RecordTypeId = bobSellerRecordTypeLTTM.Id, Bob__c = bob.Id);
        insert bobSeller;

		Test.startTest();

        Map<String, Object> mapResult = ExcelImporterController.bulkExport('Bulk_Upload_Cohort_Sellers', bob.Id );
        System.assertNotEquals(null, mapResult.get('content'));

        Test.stopTest();
	}

    @isTest
    private static void testSendEmailResult() {
        Test.startTest();
        ExcelImporterController.sendEmailResult(10, new List<String>{'Error 1', 'Error 2'});
        Test.stopTest();
    }

    @isTest
    private static void testPostDML() 
    {
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account seller1 = new Account(Name='Test Seller',RecordTypeID = sellerRecordType.Id,NA_Deal_Program_Vetted__c=true);
        insert seller1;

        RecordType rtDCASub = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c','Subsidized_Deals');
        Deal_Contract_Agreement__c dca = new Deal_Contract_Agreement__c(RecordTypeId=rtDCASub.Id,eBay_Seller__c=seller1.Id, Deal_Site__c='0', Vertical__c='Fashion', Category__c='Music');
        insert dca;

        Map<String,String> postData = new Map<String,String>{'parentId'=>dca.Id};
        String templateName = 'Upload_Deal_DCA_HIVE';

        Map<String,Object> postDmlResult = ExcelImporterController.apexProcessPostDML(postData,templateName);
        System.assertEquals('ok', postDmlResult.get('status'));
    }
}