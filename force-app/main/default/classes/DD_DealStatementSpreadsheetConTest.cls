@isTest
public class DD_DealStatementSpreadsheetConTest {
    @testSetup
    static void setup(){
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',Deal_Statement_Trigger__c = true);
        List<User> admins = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and isActive = true LIMIT 2];


    	byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        
         Deal_Statement_Setting__c setting = new Deal_Statement_Setting__c();
        setting.Initial_Payout__c=60;
        setting.Amount_Held_Back__c=40;
        insert setting;

        Profile adminProfile = [select Id,Name from Profile where Name = 'System Administrator'];
        
        User user;
        System.runAs(admins[0]) {
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
        cont.Contact_Role__c='Deals;NA Deals Statement Recipient';
        cont.Email ='test@ebay.dailydeal.com';
        // cont.EBH_Decision_Maker_Role__c = 'Deals'; //MN:13/05/2021:US-0009542 - not used anymore
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
        deal1.Sold_Items_Further_Disputes__c = 1;
        deal1.Subsidy_Per_Unit_Further_Disputes__c = 1;
     
        EBH_Deal__c deal2 = deal1.clone(false,false,false,false);
        insert new List<EBH_Deal__c>{deal1,deal2};
        
        
        Deal_Statement__c ds1 = new Deal_Statement__c();
        ds1.Name = eBSeller.Name+myDate.month()+'Statement';
        ds1.Subsidy_30_Day_Calculation__c = 10;
        ds1.Subsidy_Final_Calculation__c=0;                 
        ds1.Status__c = 'Draft';
        ds1.Initial_Payout__c =60;
        ds1.Second_Payout__c=40;
        ds1.eBay_Seller__c =deal1.EBH_BusinessName__c ;
        ds1.Subsidy_Final_Calculation__c=0;
        ds1.Month__c=myDate.month()+'';
        ds1.Amount_Held_Back__c=40;
        ds1.Initial_Payout__c=60;    
        ds1.Last_Statement_Sent_Out__c = System.now();
        insert ds1;

        ds1.Status__c = '1st Statement'; // when status == '1st Statement' and create attachment
        update ds1;

        // 05.05.2021 / Sophal Noch / US-0009424

        Deal_Statement__c queriedDs1 =[Select  Id,MostRecentFirstStatement__c, Status__c from Deal_Statement__c where id =: ds1.Id];
        List<Attachment> files = [Select Id From Attachment Where Id=:queriedDs1.MostRecentFirstStatement__c];
        System.assertEquals(1, files.size());

        List<ProcessInstanceWorkitem> workItems = [Select id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =:queriedDs1.Id AND ProcessInstance.Status = 'Pending'];
        if(!workItems.isEmpty()){ //in case, process builder run and cause deal statement to submit for approval
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setAction('Removed');
            req.setWorkItemId(workItems[0].id);
            Approval.process(req, true); // remove approval process, this for test class only
            System.assertEquals('In 1st Payout Approval', queriedDs1.Status__c);
        }else{
            System.assertEquals('1st Statement', queriedDs1.Status__c);
        }


        ds1.Status__c = '1st Payout Approved';
        update ds1;

        
        deal1.Deal_Statement__c = ds1.Id;
        update deal1;
        
        deal2.Deal_Statement__c = ds1.Id;
        update deal2;

        
    }
    
    @isTest 
    public static void test_FirstStatementSentOut(){
        List<Deal_Statement__c> dealStateLst = [SELECT Id, Name FROM Deal_Statement__c WHERE Status__c = '1st Payout Approved'];
        Test.startTest();
        
            PageReference pageRef = new PageReference('/apex/DD_DealStatementSpreadsheet');
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('Id',dealStateLst[0].Id);

            DD_DealStatementSpreadsheetController c = new DD_DealStatementSpreadsheetController ();
            DD_DealStatementSpreadsheetController.DtoDealSheet sheet = c.dealList;
            c.sellerName = 'Test Seller';
            c.endfile = 'Test Endfile';
            c.spdIndex = 0;
            c.erIndex = 0;
            c.dealIndex = 0;
            c.updateAdjustPayout();
            Double d = sheet.currentPay;
            Double alrPaid = sheet.alreadyPaid;
            String alrPaidLabel = sheet.alreadyPaidLabel;
            String mDispAdjPaid = sheet.monthDisputeAdjustmentPaid;
            String mFurDispAdjPaid = sheet.monthFurtherDisputeAdjustmentPaid;
            String mAdjPayout1 = sheet.monthAdjustmentPayout1;
            String mAdjPayout2 = sheet.monthAdjustmentPayout2;
            System.assert(String.isNotBlank(alrPaidLabel), 'alreadyPaidLabel should not blank');
            System.assert(String.isNotBlank(mDispAdjPaid), 'monthDisputeAdjustmentPaid should not blank');
            System.assert(String.isNotBlank(mFurDispAdjPaid), 'monthFurtherDisputeAdjustmentPaid should not blank');
            System.assert(String.isNotBlank(mAdjPayout1), 'monthAdjustmentPayout1 should not blank');
            System.assert(String.isNotBlank(mAdjPayout2), 'monthAdjustmentPayout2 should not blank');
            System.assertEquals('_(* #,##0.00_);_(* \\(#,##0.00\\);_(* "-"??_);_(@_)', c.numberFormat);
            System.assertEquals('_("$"* #,##0.00_);_("$"* \\(#,##0.00\\);_("$"* "-"??_);_(@_)', c.currencyFormat);
            System.assertEquals('_("$"* #,##0.00_);_("$"* \\(#,##0.00\\);_("$"* "-"??_);_(@_)', c.swissFormat);
            System.assertNotEquals(null, sheet.subTotalLabel);
            System.assertNotEquals(null, sheet.remainingLabel);
            System.assertNotEquals(null, sheet.totalLabel);
            System.assertNotEquals(null, sheet.remainingPay);
            System.assertNotEquals(null, sheet.dealSheetName);
            System.assertNotEquals(null, sheet.paymentDisputeSheetName);
            System.assertNotEquals(null, sheet.sellerPaymentSheetName);
            System.assertNotEquals(null, sheet.createdDate);
            
            DD_DealStatementSpreadsheetController.doGenerateSpeedsheet(dealStateLst[0].Id);         
            
        Test.stopTest();
        Id dsId = dealStateLst[0].Id;
        Deal_Statement__c ds =[Select Id,Last_Statement_Sent_Out__c,Status__c from Deal_Statement__c where Id =:dsId];
        List<Attachment> atts =[Select Id from Attachment where ParentId=:dsId];
        System.assertNotEquals(null,ds.Last_Statement_Sent_Out__c);
        System.assertEquals('1st Statement Sent out',ds.Status__c);
        System.assertEquals(1,atts.size());
        
    }
    /*
     @isTest 
    public static void test_SecondStatementSentOut(){
        List<Deal_Statement__c> dealStateLst = [SELECT Id, Name FROM Deal_Statement__c WHERE Status__c = '1st Payout Approved'];
        Deal_Statement__c ds = dealStateLst[0];

        ds.Subsidy_Final_Calculation__c = 20;  
        ds.Status__c = '2nd Statement';  // when status == '2nd Statement' and create attachment
        
        Test.startTest();
        update ds;  // need to be inside Test.startTest and Test.stopTest because of the future method need to run completely first
        Test.stopTest();

        // 05.05.2021 / Sophal Noch / US-0009424
        Deal_Statement__c queriedDs =[Select  Id,MostRecentFinalStatement__c, Status__c from Deal_Statement__c where id =: ds.Id];
        List<Attachment> files = [Select Id From Attachment Where Id=:queriedDs.MostRecentFinalStatement__c];
        System.assertEquals(1, files.size());
        System.assertEquals('In 2nd Payout Approval', queriedDs.Status__c); // approval process trigger from process builder 'Deal Statement Process'

        List<ProcessInstanceWorkitem> workItems = [Select id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =:queriedDs.Id AND ProcessInstance.Status = 'Pending'];
        if(!workItems.isEmpty()){
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setAction('Removed');
            req.setWorkItemId(workItems[0].id);
            Approval.process(req, true); // remove approval process, this for test class only
        }



        ds.Status__c = '2nd Payout Approved';
        update ds;
        
        

            PageReference pageRef = new PageReference('/apex/DD_DealStatementSpreadsheet');
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('Id',ds.Id);


            DD_DealStatementSpreadsheetController c=new DD_DealStatementSpreadsheetController ();
            DD_DealStatementSpreadsheetController.DtoDealSheet sheet = c.dealList;

            Double d = sheet.currentPay;
            System.assertEquals(null, c.sellerName);
            System.assertEquals(null, c.endfile);
            System.assertEquals('_(* #,##0.00_);_(* \\(#,##0.00\\);_(* "-"??_);_(@_)', c.numberFormat);
            System.assertEquals('_("$"* #,##0.00_);_("$"* \\(#,##0.00\\);_("$"* "-"??_);_(@_)', c.currencyFormat);
            System.assertEquals('_("$"* #,##0.00_);_("$"* \\(#,##0.00\\);_("$"* "-"??_);_(@_)', c.swissFormat);
            System.assertNotEquals(null, sheet.subTotalLabel);
            System.assertNotEquals(null, sheet.remainingLabel);
            System.assertNotEquals(null, sheet.totalLabel);
            System.assertNotEquals(null, sheet.remainingPay);
            System.assertNotEquals(null, sheet.dealSheetName);
            System.assertNotEquals(null, sheet.paymentDisputeSheetName);
            System.assertNotEquals(null, sheet.sellerPaymentSheetName);
            System.assertNotEquals(null, sheet.createdDate);
            
            DD_DealStatementSpreadsheetController.doGenerateSpeedsheet(dealStateLst[0].Id);         
            
            String a = sheet.alreadyPaidLabel;
            Double d2 = sheet.alreadyPaid;
            String s = sheet.monthDisputeAdjustmentPaid;
            String s2 = sheet.monthFurtherDisputeAdjustmentPaid;

        Id dsId = dealStateLst[0].Id;
        ds =[Select Id,Last_Statement_Sent_Out__c,Status__c from Deal_Statement__c where Id =:dsId];
        System.assertNotEquals(null,ds.Last_Statement_Sent_Out__c);
        System.assertEquals('2nd Statement Sent out',ds.Status__c);

        
    }
    */
    @isTest 
    public static void test_FirstStatementSentOutWithParamter(){

        List<Deal_Statement__c> dealStateLst = [SELECT Id, Name FROM Deal_Statement__c WHERE Status__c = '1st Payout Approved'];


        Map<Id,Deal_Statement__c> mapDs = DD_DealStatementSpreadsheetController.queryDealStatement(new Set<Id>{dealStateLst[0].Id});
        Map<Id,List<EBH_Deal__c>> mapDsIdToListDeal = DD_DealStatementSpreadsheetController.queryDealByDsId(new Set<Id>{dealStateLst[0].Id});

        System.assertEquals(1, mapDs.size());
        System.assertEquals(1, mapDsIdToListDeal.size());

        Test.startTest();

            // 20.05.2021 / Sophal Noch / US-0009544
            Cache.Org.put(DD_DealStatementSpreadsheetController.DS_CACHE_KEY+dealStateLst[0].Id,mapDs.get(dealStateLst[0].Id),300);   

            Cache.Org.put(DD_DealStatementSpreadsheetController.DEALS_CACHE_KEY+dealStateLst[0].Id, mapDsIdToListDeal.get(dealStateLst[0].Id),300);

        
            PageReference pageRef = new PageReference('/apex/DD_DealStatementSpreadsheet');
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('Id',dealStateLst[0].Id);
            pageRef.getParameters().put(DD_DealStatementSpreadsheetController.CACHE_PARAM,'true');


            DD_DealStatementSpreadsheetController c=new DD_DealStatementSpreadsheetController ();
            DD_DealStatementSpreadsheetController.DtoDealSheet sheet = c.dealList;
            Double d = sheet.currentPay;
            System.assertEquals('_(* #,##0.00_);_(* \\(#,##0.00\\);_(* "-"??_);_(@_)', c.numberFormat);
            System.assertEquals('_("$"* #,##0.00_);_("$"* \\(#,##0.00\\);_("$"* "-"??_);_(@_)', c.currencyFormat);
            System.assertEquals('_("$"* #,##0.00_);_("$"* \\(#,##0.00\\);_("$"* "-"??_);_(@_)', c.swissFormat);
            System.assertNotEquals(null, sheet.subTotalLabel);
            System.assertNotEquals(null, sheet.remainingLabel);
            System.assertNotEquals(null, sheet.totalLabel);
            System.assertNotEquals(null, sheet.remainingPay);
            System.assertNotEquals(null, sheet.dealSheetName);
            System.assertNotEquals(null, sheet.paymentDisputeSheetName);
            System.assertNotEquals(null, sheet.sellerPaymentSheetName);
            System.assertNotEquals(null, sheet.createdDate);
            
            DD_DealStatementSpreadsheetController.doGenerateSpeedsheet(dealStateLst[0].Id);

            Cache.Org.remove(DD_DealStatementSpreadsheetController.DS_CACHE_KEY+dealStateLst[0].Id);   

            Cache.Org.remove(DD_DealStatementSpreadsheetController.DEALS_CACHE_KEY+dealStateLst[0].Id);
            
        Test.stopTest();

        Id dsId = dealStateLst[0].Id;
        Deal_Statement__c ds =[Select Id,Last_Statement_Sent_Out__c,Status__c from Deal_Statement__c where Id =:dsId];
        List<Attachment> atts =[Select Id from Attachment where ParentId=:dsId];
        System.assertNotEquals(null,ds.Last_Statement_Sent_Out__c);
        System.assertEquals('1st Statement Sent out',ds.Status__c);
        System.assertEquals(1,atts.size());




    }


}