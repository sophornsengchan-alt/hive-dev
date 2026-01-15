@isTest
private class DD_DealStatementSpreadsheetBatch_Test {
    
    
    static Map<String,Object> setup(){

        List<User> admins = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and isActive = true LIMIT 2];

        System.runAs(admins[0]) {
            byPass__c settings = byPass__c.getOrgDefaults();
            settings.ByPass_Validation__c = true;
            upsert settings byPass__c.Id;
            
            Deal_Statement_Setting__c setting = new Deal_Statement_Setting__c();
            setting.Initial_Payout__c=60;
            setting.Amount_Held_Back__c=40;
            insert setting;
        }

        User user;
    	
        System.runAs(admins[1]) {
            Profile adminProfile = [select Id,Name from Profile where Name = 'System Administrator'];

            user = new User();
            user.Alias='AMT';
            user.Email='amtmail@ebay.com';
            user.EmailEncodingKey='UTF-8';
            user.LastName='AMTUser';
            user.LanguageLocaleKey='en_US'; 
            user.LocaleSidKey='en_US';
            user.ProfileId = adminProfile.Id;
            user.TimeZoneSidKey='America/Los_Angeles';
            user.UserName='amtmail@ebay.com';
            insert user;
        }

        
        
        Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
        dealTimezone.TimeZone__c='America/Los_Angeles';     
        insert dealTimezone;

        Account acc = new Account();
        acc.Name = 'AMT_Account';
        acc.BillingCountry = 'US';
        insert acc;

        Account eBSeller = new Account();
        eBSeller.Name = 'AMT_Seller';
        //eBSeller.Account__c = acc.Id;
        eBSeller.EBH_MainVertical__c = 'Electronics';
        eBSeller.EBH_OracleID__c = 'AXTP-930494';
        //eBSeller.Daily_Deals_Whitelist__c = true;
        insert eBSeller;

        Contact cont = new Contact(RecordtypeId=ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL').Id);
        cont.LastName = 'AMT_Cont';
        cont.AccountId = eBSeller.Id;
        cont.Contact_Role__c='Deals;NA Deals Statement Recipient'; //Sophal:22/03/2021:US-0009181 replace 'Marketplaces - Daily Deals Statement Recipient' with 'NA Deals Statement Recipient'.
        cont.Email ='test@ebay.dailydeal.com';
        // cont.EBH_Decision_Maker_Role__c = 'Deals'; //Sophal:22/03/2021:US-0009181 not used anymore
        insert cont;

        EBH_SpotlightCategory__c spCat = new EBH_SpotlightCategory__c();
        spCat.Name = 'AMT_Spotligth NA';
        spCat.EBH_Country__c = 'NA';
        spCat.EBH_SpotlightCategoryID__c = 'SCiD-934035';
        //spCat.Vertical__c = 'Fashion';
        insert spCat;

        Date myDate = System.Today().adddays(2);
        Time myTime = Time.newInstance(1, 1, 1, 1);
        //MN-17082022-US-0011119-Remove reference with old record type name
        // Id euRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
        RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
        Id euRecordTypeId = subDealRecordType.Id;

        Deal_Statement__c ds1 = new Deal_Statement__c();
        ds1.Name = eBSeller.Name+myDate.month()+'Statement';
        ds1.Subsidy_Final_Calculation__c=0;                 
        ds1.Status__c = '1st Payout Approved';
        ds1.Initial_Payout__c =60;
        ds1.Second_Payout__c=40;
        ds1.eBay_Seller__c = eBSeller.Id;
        ds1.Subsidy_Final_Calculation__c=0;
        ds1.Month__c=myDate.month()+'';
        ds1.Amount_Held_Back__c=40;
        ds1.Initial_Payout__c=60;    
        ds1.Last_Statement_Sent_Out__c = System.now();
        insert ds1;

        EBH_Deal__c deal1 = new EBH_Deal__c();
        deal1.RecordTypeId = euRecordTypeId;
        deal1.Merchant_Approver__c = user.Id;
        deal1.EBH_BusinessName__c = eBSeller.Id;
        deal1.EBH_ProductTitle__c = 'AMTProductTest';
        deal1.EBH_DealSiteId__c = '0';
        deal1.EBH_Vertical__c = 'Home & Garden';
        deal1.EBH_Category__c='Home & Garden';
        deal1.Sub_Category__c = 'Bedding';
        deal1.EBH_DealFormat__c = 'Primary';
        deal1.EBH_DealStartDate__c = myDate;
        deal1.EBH_DealStartTime__c = myTime;
        deal1.EBH_DealEndDate__c = myDate;
        deal1.EBH_DealEndTime__c = myTime;
        deal1.EBH_Status__c = 'New';
        deal1.EBH_Quantity__c = 1;
        deal1.Quantity_Limitation_per_Purchaser__c = 1;
        deal1.EBH_DealPrice__c = 1;
        deal1.EBH_SellerPrice__c = 1;
        deal1.EBH_SoldItemsForecast__c = 123456;
        deal1.Seller_Approver_1__c = cont.Id;
        deal1.Sold_Items_30_Days__c = 1;
        deal1.Sold_Items_60_Days__c = 2;
        deal1.Final_Sold_Items__c = 1; 
        deal1.Deal_Statement__c = ds1.Id;   

     
        EBH_Deal__c deal2 = deal1.clone(false,false,false,false);
        deal2.Deal_Statement__c = ds1.Id;

        insert new List<EBH_Deal__c>{deal1,deal2};
        
        Map<String,Object> mapResut = new Map<String,Object>();
        mapResut.put('ds1',ds1);
        mapResut.put('deal1',deal1);
        mapResut.put('deal2',deal2);
        mapResut.put('cont',cont);

        return mapResut;
    }

    @IsTest
    static void testBatch1(){
        Map<String,Object> mapResut = setup();
        Deal_Statement__c ds1 = (Deal_Statement__c)mapResut.get('ds1');
        
        Attachment att1 = new Attachment(name='att1.log',parentId=ds1.Id,body = EncodingUtil.Base64Decode('test'));
        insert att1;

        ds1.MostRecentFirstStatement__c = att1.Id;
        ds1.MostRecentFinalStatement__c = att1.Id;
        update ds1;
        
        Test.startTest();
            DD_DealStatementSpreadsheetBatch b1 = new DD_DealStatementSpreadsheetBatch(new List<String>{ds1.Id});           
            Database.executeBatch(b1);
        Test.stopTest();
        
            b1 = new DD_DealStatementSpreadsheetBatch(new List<String>{ds1.Id});
    }
    
    @IsTest
    static void testBatch2Withcontenversion(){
        Map<String,Object> mapResut = setup();
        Deal_Statement__c ds1 = (Deal_Statement__c)mapResut.get('ds1');
        
        Blob bodyBlob=Blob.valueOf('Test Attachment Body');
        ContentVersion cv = new ContentVersion(Title='Test Attachment_completed',FirstPublishLocationID=ds1.Id,VersionData=bodyBlob, pathOnCLient='TEST.png');
        insert cv;
        ContentVersion testContent = [SELECT id,title,PathOnClient,VersionData, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        ds1.MostRecentFirstStatement__c = testContent.ContentDocumentId;
        ds1.MostRecentFinalStatement__c = testContent.ContentDocumentId;
        update ds1;
        
        Test.startTest();
            DD_DealStatementSpreadsheetBatch b1 = new DD_DealStatementSpreadsheetBatch(new List<String>{ds1.Id});           
            Database.executeBatch(b1);
        Test.stopTest();
        
            b1 = new DD_DealStatementSpreadsheetBatch(new List<String>{ds1.Id});
    }
    
     @IsTest
    static void testBatch3NocontractRole(){
    	Map<String,Object> mapResut = setup();
    	List<Contact> lstCon = new List<contact>();
    	for(Contact c : [select Contact_Role__c from Contact where Name like '%AMT_Cont%']){
    		c.Contact_Role__c = null;
    		lstCon.add(c);
    	} 
    	if(!lstCon.isEmpty()) update lstCon;
    	
        Deal_Statement__c ds1 = (Deal_Statement__c)mapResut.get('ds1');
        Attachment att1 = new Attachment(name='att1.log',parentId=ds1.Id,body = EncodingUtil.Base64Decode('test'));
        insert att1;

        ds1.MostRecentFirstStatement__c = att1.Id;
        ds1.MostRecentFinalStatement__c = att1.Id;
        update ds1;
        
        Test.startTest();
            DD_DealStatementSpreadsheetBatch b1 = new DD_DealStatementSpreadsheetBatch(new List<String>{ds1.Id});           
            Database.executeBatch(b1);
        Test.stopTest();
            
    }
 
}