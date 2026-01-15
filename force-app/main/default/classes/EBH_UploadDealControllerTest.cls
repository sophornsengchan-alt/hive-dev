@isTest
public with sharing class EBH_UploadDealControllerTest {
    
    
    @isTest static void testUploadDealFromCSV(){
        EBH_TestDataFactory.setUpCustomSettings();     
        //Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData();     
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account testDataMap = new Account(Name='se1',RecordTypeID = sellerRecordType.Id);
        insert testDataMap;
       // String contentFile = 'eBay Artikelnummer;Verkäufer;Artikelbezeichnung;EAN;Verkäuferpreis;RRP/WAS;Streichpreis;Menge;frühester Dealtermin;Deals Format;Idealo Link;Amazon Link;ebay Link;Bild Link;AM comment;Verkäuferkommentar;Vertical;Kampagnenvorschlag;Verkäufer e-mail Adresse\n\r332111284852;%sellerName%;ESET MultiDevice Security 2017 FFP 5U DE|YVVV2E06;;19.99 €;WAS;21.99;250;16/2/2017;Value Hero;http://www.idealo.de/preisvergleich/OffersOfProduct/5101535_-multi-device-security-2017-de-5-geraete-1-jahr-ffp-eset.html;;;;Test Sourcer;Test Seller;Sport;;test@ebaytest.de;77;10:00;20:00 am;';
       // String contentFileDE = 'eBay Artikelnummer;Verkäufer;Artikelbezeichnung;EAN;Verkäuferpreis;RRP/WAS;Streichpreis;Menge;frühester Dealtermin;Deals Format;Idealo Link;Amazon Link;ebay Link;Bild Link;AM comment;Verkäuferkommentar;Vertical;Kampagnenvorschlag;Verkäufer e-mail Adresse\n\r332111284852;%sellerName%;ESET MultiDevice Security 2017 FFP 5U DE|YVVV2E06;;19,99 €;WAS;21,99;;16/2/2017;Value Hero;http://www.idealo.de/preisvergleich/OffersOfProduct/5101535_-multi-device-security-2017-de-5-geraete-1-jahr-ffp-eset.html;;;;Test Sourcer;Test Seller;Sport;;test@ebaytest.de;77;10:00;;';
        String contentFile = 'eBay item id,seller user id,product title,ean,seller price,RRP/ WAS,RRP/ WAS price,QTY,earliest deal date,deal format,idealo url,amazon url,ebay url,picture url,comment ebay,comment seller,category,campaign proposal,seller email adress,Site ID\n\r12312414,%sellerName%,test1,343,6000,32,12,330,20/7/2019,Primary,www.test.com,www.test.com,www.test.com,www.test.com,Testing Comment E2E,Testing Comment Buser,Beauty & Gesundheit,,sovantheany.dim@gmail.com,UK';
        String contentFileDE = 'eBay item id,seller user id,product title,ean,seller price,RRP/ WAS,RRP/ WAS price,QTY,earliest deal date,deal format,idealo url,amazon url,ebay url,picture url,comment ebay,comment seller,category,campaign proposal,seller email adress,Site ID\n\r12312414,%sellerName%,test1,343,6000,32,12,330,20/7/2019,Primary,www.test.com,www.test.com,www.test.com,www.test.com,Testing Comment E2E,Testing Comment Buser,Beauty & Gesundheit,,sovantheany.dim@gmail.com,UK';
        contentFile = contentFile.replace('%sellerName%',testDataMap.Name);
        contentFileDE = contentFileDE.replace('%sellerName%',testDataMap.Name);
        Test.startTest();
            Map<String, Object>mResult = EBH_UploadDealController.createDealFromCSV(testDataMap.Id, 'testFileName', contentFile,',','en',false);
            System.assert(Boolean.valueOf(mResult.get('isSuccess')));
            List<EBH_Deal__c> listDeals   = (List<EBH_Deal__c> )mResult.get('lstRecord');
            //System.assertEquals(listDeals[0].EBH_DealPrice__c,listDeals[0].EBH_SellerPrice__c,'pre-assign EBH_DealPrice__c = EBH_SellerPrice__c');
             
            Map<String, Object>mResult2 = EBH_UploadDealController.createDealFromCSV(testDataMap.Id, 'testFileName', contentFileDE,',','de',false);
            //System.assert(String.valueOf(mResult2.get('listError')).contains('Required field missing value'),' missing quantity as required field!');
            
            
            //System.assert(Boolean.valueOf(mResult2.get('isSuccess')));
        Test.stopTest();
        
    }
    
    @isTest static void testPreviewDealFromCSV(){
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account testDataMap = new Account(Name='se1',RecordTypeID = sellerRecordType.Id);
        insert testDataMap;
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(EBH_SpotlightCategoryID__c='1111');
        insert sc; 
        EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(EBH_Slots__c =2);
        insert dsa1;
        
        String contentFile = 'eBay item id,seller user id,product title,ean,seller price,deal price,deal start date,deal start time,deal end date,deal end time,RRP/ WAS,RRP/ WAS price,QTY,earliest deal date,deal format,spotlight category id,idealo url,amazon url,ebay url,picture url,comment ebay,comment seller,category,Retail Campaign ID,seller email adress,Site ID,owner\n\r12312414,%sellerName%,test1,13,200,20,,3:00,30/7/2019,5:00,10,9,50,5/7/19,Primary,1112,www.test.com,www.test.com,www.test.com,www.test.com,Test Suer ,Test Suer ,Immobilien,%RetailCampaignID%,sovantheany.dim@gmail.com,UK,%OwnerID%';
        String contentFileDE = 'eBay item id,seller user id,product title,ean,seller price,deal price,deal start date,deal start time,deal end date,deal end time,RRP/ WAS,RRP/ WAS price,QTY,earliest deal date,deal format,spotlight category id,idealo url,amazon url,ebay url,picture url,comment ebay,comment seller,category,Retail Campaign ID,seller email adress,Site ID,owner\n\r12312414,%sellerName%,test1,13,200,20,20/7/2019,3:00,30/7/2019,5:00,10,9,50,5/7/19,Primary,1111,www.test.com,www.test.com,www.test.com,www.test.com,Test Suer ,Test Suer ,Immobilien,%RetailCampaignID%,sovantheany.dim@gmail.com,UK,%OwnerID%';
        contentFile = contentFile.replace('%sellerName%',testDataMap.Name);
        contentFileDE = contentFileDE.replace('%sellerName%',testDataMap.Name);
        contentFile = contentFile.replace('%RetailCampaignID%',dsa1.Id);
        contentFileDE = contentFileDE.replace('%RetailCampaignID%',dsa1.Id);
        contentFile = contentFile.replace('%OwnerID%',UserInfo.getUserId());
        contentFileDE = contentFileDE.replace('%OwnerID%',UserInfo.getUserId());
        Test.startTest();
            Map<String, Object>mResult = EBH_UploadDealController.createDealFromCSV(testDataMap.Id, 'testFileName', contentFile,',','en',true);
            System.assert(Boolean.valueOf(mResult.get('isSuccess')));
            List<EBH_Deal__c> listDeals   = (List<EBH_Deal__c> )mResult.get('lstRecord');
            //System.assertEquals(listDeals[0].EBH_DealPrice__c,listDeals[0].EBH_SellerPrice__c,'pre-assign EBH_DealPrice__c = EBH_SellerPrice__c');
            Map<String, Object>mResult2 = EBH_UploadDealController.createDealFromCSV(testDataMap.Id, 'testFileName', contentFileDE,',','de',true);
            //System.assert(String.valueOf(mResult2.get('listError')).contains('Required field missing value'),' missing quantity as required field!');
            
            
            //System.assert(Boolean.valueOf(mResult2.get('isSuccess')));
            //testerror
            String contentFile2 = '123456788,testTH,Product Test Pro_1,13,60,50,15/03/2021/234/32423,3:00,15/04/2021,5:00,12,11,25,15/03/2021,Primary,56576789,www.test.com,www.test.com,www.test.com,www.test.com,Test ,Test  ,Immobilien,a0u7X000001nHu9QAE,sovantheany.dim@gaea-sys.com,DE,0053u000002puEDAAY';
        	Map<String, Object> mResult3 = EBH_UploadDealController.createDealFromCSV(testDataMap.Id, 'testFileName', contentFile2,';','en',true);
        Test.stopTest();
    }

    @isTest static void testImportDealPreDML(){
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

        Callable extension = (Callable) Type.forName('EBH_UploadDealController.DealImport').newInstance();
        Map<String, Object> mapResult = (Map<String, Object>) extension.call('importDealPreDML', mapArgs);


        Map<Integer, String> mapIndexToErrMsg =  (Map<Integer, String>)(JSON.deserialize(JSON.serialize(mapResult.get('mapIndexToErrMsg')), Map<Integer, String>.class)); 
        if(!mapIndexToErrMsg.isEmpty()){ System.debug('nsp : mapIndexToErrMsg == '+mapIndexToErrMsg); }
        System.assertEquals(0, mapIndexToErrMsg.size());

        Test.stopTest();

    }
    
    @isTest static void testImportUnSubDealPreDML(){
        // 12.12.2022 / Sophal Noch / US-0012119
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account testDataMap = new Account(Name='se1',RecordTypeID = sellerRecordType.Id);
        insert testDataMap;

        Contact testCon = new Contact(LastName='test Contact 001', Email = 'test@test.com.invalid', AccountId=testDataMap.Id);
        Contact testCon1 = new Contact(LastName='test ContactDup 001', Email = 'test@test.com.invalid', AccountId=testDataMap.Id);
        insert new List<Contact>{testCon, testCon1};

        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(EBH_SpotlightCategoryID__c='1111');
        insert sc; 
        EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(EBH_Slots__c =2);
        insert dsa1;
       
        String headerStr = 'ebh_ebayitemid__c,ebh_businessname__c,seller_contact__c,ebh_producttitle__c,ebh_ean__c,ebh_sellerprice__c,ebh_dealprice__c,ebh_dealstartdate__c,ebh_dealstarttime__c,ebh_dealenddate__c,ebh_dealendtime__c,ebh_recommendedretailpricewas__c,ebh_rrpwasprice__c,ebh_quantity__c,ebh_dealdateearliestpossible__c,ebh_dealformat__c,ebh_spotlightcategory__c,ebh_idealolink__c,ebh_amazonlink__c,ebay_link_url__c,ebh_picturelink__c,ebh_commentfromebaysourcer__c,ebh_commentfromseller__c,ebh_category__c,ebh_dealretailcampaign__c,ebh_selleremail__c,ebh_dealsiteid__c,ownerid';
        String rowStr = '12312414,%sellerName%,%sellerContName%,test1,13,200,20,30/6/2019,3:00,30/7/2019,5:00,10,9,50,5/7/19,Primary,%spotlightCategory%,www.test.com,www.test.com,www.test.com,www.test.com,Test Suer ,Test Suer ,Immobilien,%RetailCampaignID%,sovantheany.dim@gmail.com,UK,%OwnerID%';
        rowStr = rowStr.replace('%sellerName%',testDataMap.Name);
        rowStr = rowStr.replace('%sellerContName%',testCon.LastName);
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
        mapArgs.put('parentId',dsa1.Id);
        Test.startTest();

        Callable extension = (Callable) Type.forName('EBH_UploadDealController.DealImport').newInstance();
        Map<String, Object> mapResult = (Map<String, Object>) extension.call('importUnSubDealPreDML', mapArgs);


        Map<Integer, String> mapIndexToErrMsg =  (Map<Integer, String>)(JSON.deserialize(JSON.serialize(mapResult.get('mapIndexToErrMsg')), Map<Integer, String>.class)); 
        if(!mapIndexToErrMsg.isEmpty()){ System.debug('nsp : mapIndexToErrMsg == '+mapIndexToErrMsg); }
        System.assertEquals(0, mapIndexToErrMsg.size());

        Test.stopTest();

    }
    
    @isTest static void testImportSubDealPreDML(){
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account testDataMap = new Account(Name='Test Seller',RecordTypeID = sellerRecordType.Id);
        insert testDataMap;

        Contact testCon1 = new Contact(LastName='test Contact 001', Email = 'test1@test.com.invalid', AccountId=testDataMap.Id);
        Contact testCon2 = new Contact(LastName='test Contact 002', Email = 'test2@test.com.invalid', AccountId=testDataMap.Id);
        Contact testCon3 = new Contact(LastName='test Contact 003', Email = 'test3@test.com.invalid', AccountId=testDataMap.Id);
        Contact testCon4 = new Contact(LastName='test Contact 004', Email = 'test4@test.com.invalid', AccountId=testDataMap.Id);
        Contact testCon5 = new Contact(LastName='test Contact 005', Email = 'test5@test.com.invalid', AccountId=testDataMap.Id);
        insert new List<Contact>{testCon1, testCon2, testCon3, testCon4, testCon5};
       //LA-29-01-2024-US-0014680- Replace list_price__c with EBH_RRPWASPrice__c in headerStr
        String headerStr = 'ownerid,ebh_dealsiteid__c,ebh_vertical__c,ebh_category__c,sub_category__c,ebh_dealformat__c,ebh_ebayitemid__c,ebh_businessname__c,ebh_producttitle__c,ebh_dealprice__c,ebh_recommendedretailpricewas__c,EBH_RRPWASPrice__c,ebh_sellerprice__c,ebh_quantity__c,ebh_solditemsforecast__c,ebh_maximumpurchases__c,ebh_dealdateearliestpossible__c,ebh_dealstartdate__c,ebh_dealstarttime__c,ebh_dealenddate__c,ebh_dealendtime__c,optional_notes__c,sellersdealpricemskulower__c,sellersdealpricemskuupper__c,sellersofferpricemskulower__c,sellersofferpricemskuupper__c,listpricemskulower__c,listpricemskuupper__c,seller_approver_1__c,seller_approver_2__c,seller_approver_3__c,seller_approver_4__c,seller_approver_5__c';
        String rowStr = '%OwnerID%,US,Business & Industrial,Cell Phones & Accessories,,Deal,123456789123,Test Seller,Test Product,4000,RRP,$5000,50000,1000,1000,5,12/20/2023,12/20/2023,11:00,12/28/2023,17:00,No Notes,250,300,200,250,200,250,%approver1%,%approver2%,%approver3%,%approver4%,%approver5%';
        rowStr = rowStr.replace('%OwnerID%',UserInfo.getUserId());
        rowStr = rowStr.replace('%approver1%',testCon1.Email);
        rowStr = rowStr.replace('%approver2%',testCon2.Email);
        rowStr = rowStr.replace('%approver3%',testCon3.Email);
        rowStr = rowStr.replace('%approver4%',testCon4.Email);
        rowStr = rowStr.replace('%approver5%',testCon5.Email);

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

        Callable extension = (Callable) Type.forName('EBH_UploadDealController.DealImport').newInstance();
        Map<String, Object> mapResult = (Map<String, Object>) extension.call('importSubDealPreDML', mapArgs);


        Map<Integer, String> mapIndexToErrMsg =  (Map<Integer, String>)(JSON.deserialize(JSON.serialize(mapResult.get('mapIndexToErrMsg')), Map<Integer, String>.class)); 
        if(!mapIndexToErrMsg.isEmpty()){ System.debug('nsp : mapIndexToErrMsg == '+mapIndexToErrMsg); }
        System.assertEquals(0, mapIndexToErrMsg.size());

        Test.stopTest();

    }
            
    @isTest static void testUploadSubDealPreDM_From_DCA()
    {
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account testDataMap = new Account(Name='Test Seller',RecordTypeID = sellerRecordType.Id,NA_Deal_Program_Vetted__c=true);
        insert testDataMap;

        RecordType rtDCASub = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c','Subsidized_Deals');
        Deal_Contract_Agreement__c dca = new Deal_Contract_Agreement__c(RecordTypeId=rtDCASub.Id,eBay_Seller__c=testDataMap.Id, Deal_Site__c='0', Vertical__c='Fashion', Category__c='Music');
        insert dca;

       //LA-29-01-2024-US-0014680- Replace list_price__c with EBH_RRPWASPrice__c in headerStr
        String headerStr = 'ebay item id*;item title*;deal price*;seller price*;list price*;quantity*;maximum purchases*;deal_start_date*;deal_start_time*;deal_end_date*;deal_end_time*;comments';
        String rowStr = '235906099222,Item_Title,100,120,200,100,10,1/23/2025,0:00,1/30/2025,23:59,Seller_Comments';
        
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
        mapArgs.put('parentId', dca.Id);

        Test.startTest();

            Callable extension = (Callable) Type.forName('EBH_UploadDealController.DealImport').newInstance();
            Map<String, Object> mapResult = (Map<String, Object>) extension.call('importSubDealPreDMLDCA', mapArgs);

            Map<Integer, String> mapIndexToErrMsg =  (Map<Integer, String>)(JSON.deserialize(JSON.serialize(mapResult.get('mapIndexToErrMsg')), Map<Integer, String>.class)); 
            if(!mapIndexToErrMsg.isEmpty()){ System.debug('---some error: '+mapIndexToErrMsg); }
            System.assertEquals(0, mapIndexToErrMsg.size());
            
        Test.stopTest();
    }
    /*=======================================================================================================
    @change history:  31/1/2025 / Vimean Heng / US-0016639 - Testing Feedback fixes - Deals - Sprint 117
    =======================================================================================================*/
    @isTest static void testImportSubDealPreDMLDCARelatedList(){
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account testDataMap = new Account(Name='Test Seller',RecordTypeID = sellerRecordType.Id);
        insert testDataMap;

        Contact testCon1 = new Contact(LastName='test Contact 001', Email = 'test1@test.com.invalid', AccountId=testDataMap.Id);
        Contact testCon2 = new Contact(LastName='test Contact 002', Email = 'test2@test.com.invalid', AccountId=testDataMap.Id);
        Contact testCon3 = new Contact(LastName='test Contact 003', Email = 'test3@test.com.invalid', AccountId=testDataMap.Id);
        Contact testCon4 = new Contact(LastName='test Contact 004', Email = 'test4@test.com.invalid', AccountId=testDataMap.Id);
        Contact testCon5 = new Contact(LastName='test Contact 005', Email = 'test5@test.com.invalid', AccountId=testDataMap.Id);
        insert new List<Contact>{testCon1, testCon2, testCon3, testCon4, testCon5};
       //LA-29-01-2024-US-0014680- Replace list_price__c with EBH_RRPWASPrice__c in headerStr
        String headerStr = 'ebh_status__c,ownerid,ebh_dealsiteid__c,ebh_vertical__c,ebh_category__c,sub_category__c,ebh_dealformat__c,ebh_ebayitemid__c,ebh_businessname__c,ebh_producttitle__c,ebh_dealprice__c,ebh_recommendedretailpricewas__c,EBH_RRPWASPrice__c,ebh_sellerprice__c,ebh_quantity__c,ebh_solditemsforecast__c,ebh_maximumpurchases__c,ebh_dealdateearliestpossible__c,ebh_dealstartdate__c,ebh_dealstarttime__c,ebh_dealenddate__c,ebh_dealendtime__c,optional_notes__c,sellersdealpricemskulower__c,sellersdealpricemskuupper__c,sellersofferpricemskulower__c,sellersofferpricemskuupper__c,listpricemskulower__c,listpricemskuupper__c,seller_approver_1__c,seller_approver_2__c,seller_approver_3__c,seller_approver_4__c,seller_approver_5__c';
        String rowStr = 'New,%OwnerID%,US,Business & Industrial,Cell Phones & Accessories,,Deal,123456789123,Test Seller,Test Product,4000,RRP,$5000,50000,1000,1000,5,12/20/2023,12/20/2023,11:00,12/28/2023,17:00,No Notes,250,300,200,250,200,250,%approver1%,%approver2%,%approver3%,%approver4%,%approver5%';
        rowStr = rowStr.replace('%OwnerID%',UserInfo.getUserId());
        rowStr = rowStr.replace('%approver1%',testCon1.Email);
        rowStr = rowStr.replace('%approver2%',testCon2.Email);
        rowStr = rowStr.replace('%approver3%',testCon3.Email);
        rowStr = rowStr.replace('%approver4%',testCon4.Email);
        rowStr = rowStr.replace('%approver5%',testCon5.Email);

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

        Callable extension = (Callable) Type.forName('EBH_UploadDealController.DealImport').newInstance();
        Map<String, Object> mapResult = (Map<String, Object>) extension.call('importSubDealPreDMLDCARelatedList', mapArgs);


        Map<Integer, String> mapIndexToErrMsg =  (Map<Integer, String>)(JSON.deserialize(JSON.serialize(mapResult.get('mapIndexToErrMsg')), Map<Integer, String>.class)); 
        if(!mapIndexToErrMsg.isEmpty()){ System.debug('nsp : mapIndexToErrMsg == '+mapIndexToErrMsg); }
        System.assertEquals(0, mapIndexToErrMsg.size());

        Test.stopTest();

    }
}