/**********************************************************************************************************
 @ Change history:  05.01.2024 / Vimean Heng / Fix lock row.
***********************************************************************************************************/
@isTest
private class ExcelReportTest {
    
    static UserRole role1 = new UserRole(Name='UK-test advertising');
    @TestSetup
    static void setupData(){
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',
                                         OpportunityContactRole__c = true
                                        );    
    }
    //@ Change history:  05.01.2024 / Vimean Heng / US-0014424 / Fix lock row.
    static testMethod void testReportXls() {
        
        byPass__c[] bps = [Select Id from byPass__c Where SetupOwnerId  =: UserInfo.getUserId()];
        byPass__c bp = bps.isEmpty()?new byPass__c():new byPass__c(Id=bps[0].Id);
        bp.SetupOwnerId = UserInfo.getUserId();
        bp.triggerObjects__c = 'Quote QuoteLineItem';
        bp.byPass_Trigger__c = false;
        bp.ByPass_Validation__c=true;
        bp.byPass_WFRule__c = true;

        if(bps.isEmpty())
        {
            insert bp;
        }else{          
            update bp;
        }   
             
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
	    System.RunAs(usr){
			insert role1;//run DML of setup obj in different context
	    }
	     
        //create account
        Account acc = TST_DataGenerator.generateAccount();
        acc.SAP_ID__c = '11111112';
        insert acc;
        
        //get standard price book========
        //Pricebook2 pb = [select id from Pricebook2 where IsStandard = true limit 1];  
        Id pb =  Test.getStandardPricebookId();
        
        // create products========== 
        Product2 p1 = new Product2(
            name='Test Product 1',          
            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
            //RecordTypeId=ExcelReportHelper.getRecordTypeId(ExcelReportHelper.PRO_RECORD_TYPE_PACKAGE)
            RecordTypeId=ApexUtil.getRecordTypeByName('Product2','Package').Id
            //packege
        );
        insert p1;
        Product2 p2 = new Product2(
            name='Test Product 2',          
            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR
            //will be sub-item of packege p1
        );
        Product2 p3 = new Product2(
            name='Test Product 3',          
            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR
            //not sub item
        );
        List<Product2>listP = new List<Product2>{p2,p3};
        insert listP; 
        
        // create pricebookentreis==========
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id=pb,
            Product2Id=p1.id,
            UnitPrice=0.9,
            isActive=true,
            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id=pb,
            Product2Id=p2.id,
            UnitPrice=0.9,
            isActive=true,
            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR
        );
        PricebookEntry pbe3 = new PricebookEntry(
            Pricebook2Id=pb,
            Product2Id=p3.id,
            UnitPrice=0.9,
            isActive=true,
            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR
        );
        List<PricebookEntry>listPBE = new List<PricebookEntry>{pbe1,pbe2,pbe3};
        insert listPBE; 
        
        //create profile for user===========
        Profile profile = [Select id from Profile limit 1];
        
         
        //create user for opportunity=========
        User user1 =new User(
                Username='user3478test@test.com',
                LastName='user1test',
                Alias='SFDC2',
                CommunityNickname='ktang2test',
                TimeZoneSidKey='Atlantic/Cape_Verde',
                LocaleSidKey='en_GB',
                EmailEncodingKey='ISO-8859-1',
                ProfileId=profile.id, 
                LanguageLocaleKey='de',
                Email='user1@test.com',
                //Sales_Team__c='AT'//,
                //UserRoleId=role1.id
                UserRoleId=role1.id
        );             
        System.RunAs(usr){
        	insert user1;
        }
        
        // create an opportunity==========
        Opportunity opp1 = new Opportunity(
            name='Test Opp 1',
            AccountId=acc.id,
            Type='Existing Business',
            Product_line__c='Adsales (10046)',
            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
            CloseDate=Date.valueOf('2013-4-13'),
            StageName='Initial Offer (w/o request)',
            Reporting_Active__c=true,
            Internal_Only__c=false,
            Report_Language__c=ExcelReportHelper.REPORT_LANGUAGE_GE,
            Interval__c=ExcelReportHelper.INTERVAL_WEEKLY,
            Weekday__c=ExcelReportHelper.WEEKDAY_TUE,
            Additional_Columns__c=ExcelReportHelper.ADDITIONAL_COL,
            OwnerId=user1.id,
            Final_Reporting__c=false
        );
        Opportunity opp2 = new Opportunity(
            name='Test Opp 2',
            AccountId=acc.id,
            Type='Existing Business',
            Product_line__c='Adsales (10046)',
            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
            CloseDate=Date.valueOf('2013-4-13'),
            StageName='Initial Offer (w/o request)',
            Reporting_Active__c=true,
            Internal_Only__c=true,
            Report_Language__c=ExcelReportHelper.REPORT_LANGUAGE_EN,
            Interval__c=ExcelReportHelper.INTERVAL_MONTHLY,
            //Weekday__c=ExcelReportHelper.WEEKDAY_TUE,
            Additional_Columns__c=ExcelReportHelper.ADDITIONAL_COL,
            OwnerId=user1.id,
            Final_Reporting__c=false
        );
        Opportunity opp3 = new Opportunity(
            name='Test Opp 3',
            AccountId=acc.id,
            Type='Existing Business',
            Product_line__c='Adsales (10046)',
            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
            CloseDate=Date.valueOf('2013-4-13'),
            StageName='Initial Offer (w/o request)',
            Reporting_Active__c=true,
            Internal_Only__c=false,
            Report_Language__c=ExcelReportHelper.REPORT_LANGUAGE_GE,
            Interval__c=ExcelReportHelper.INTERVAL_WEEKLY,
            Weekday__c=ExcelReportHelper.WEEKDAY_TUE,
            Additional_Columns__c=ExcelReportHelper.ADDITIONAL_COL,
            OwnerId=user1.id,
            Final_Reporting__c=false
        );
        List<Opportunity> listOpp= new List<Opportunity>{opp1,opp2,opp3};
        insert listOpp;
        
        //trace relation form lineItems to Revenue_Schedule_daily2__c ==================
        // Revenue2__c r1 = new Revenue2__c();
        // Revenue2__c r2 = new Revenue2__c();
        // Revenue2__c r3 = new Revenue2__c();
        // Revenue2__c r4 = new Revenue2__c();
        // List<Revenue2__c> listR =new List<Revenue2__c>{r1,r2,r3,r4};
        // insert listR;
        
        Decimal qli1ToAdProd1 = 100;
        Decimal qli2ToAdProd2 = 200;
        Decimal qli3ToAdProd3 = 300;

        Ad_Product__c adProd1 = new Ad_Product__c(
            Product2__c = p1.Id,
            TotalPrice__c = qli1ToAdProd1,
            from_Date__c=Date.valueOf('2013-4-13'),
            until_Date__c=Date.valueOf('2014-4-13'),
            Opportunity__c = opp1.Id,
            Quantity__c = 3,
            Billing_category__c=ExcelReportHelper.BILL_CAT_FIXPRICE,
            package_line_item__c=ExcelReportHelper.PRO_RECORD_TYPE_PACKAGE //must package because p1 is packege
        );

        Ad_Product__c adProd2 = new Ad_Product__c(
                Product2__c = p2.Id,
                TotalPrice__c = qli2ToAdProd2,
                from_Date__c=Date.valueOf('2013-4-13'),
                until_Date__c=Date.valueOf('2014-8-13'),
                Opportunity__c = opp1.Id,
                Quantity__c = 3,
                Billing_category__c=ExcelReportHelper.BILL_CAT_CPC,
                package_line_item__c=p1.id//must be id of p1 because p2 is sub-item in package p1
            );

        Ad_Product__c adProd3 = new Ad_Product__c(
                Product2__c = p3.Id,
                TotalPrice__c = qli3ToAdProd3,
                from_Date__c=Date.valueOf('2013-4-13'),
                until_Date__c=System.Today().addDays(-2),
                Opportunity__c = opp1.Id,
                Quantity__c = 3,
                Billing_category__c=ExcelReportHelper.BILL_CAT_CPM,
                package_line_item__c=null
            );
            Ad_Product__c adProd4 = new Ad_Product__c(
                Product2__c = p3.Id,
                TotalPrice__c = qli3ToAdProd3,
                from_Date__c=System.Today().addDays(-10),
                until_Date__c=System.Today(),
                Opportunity__c = opp1.Id,
                Quantity__c = 3,
                Billing_category__c=ExcelReportHelper.BILL_CAT_CPO,
                package_line_item__c=null
            );
            Ad_Product__c adProd5 = new Ad_Product__c(
                Product2__c = p3.Id,
                TotalPrice__c = qli3ToAdProd3,
                from_Date__c=Date.valueOf('2013-4-13'),
                until_Date__c=Date.valueOf('2013-7-13'),
                Opportunity__c = opp2.Id,
                Quantity__c = 3,
                Billing_category__c=ExcelReportHelper.BILL_CAT_CPM,
                package_line_item__c=null
            );

            Test.startTest();//============Start test================

            List<Ad_Product__c> listAP = new List<Ad_Product__c>{adProd1, adProd2, adProd3,adProd4,adProd5};   
            insert  listAP;

            

        
        //System.debug('>>>listAP: '+JSON.serialize(listAP));
        // add line items========================
        /*
        OpportunityLineItem oli1 = new OpportunityLineItem(
                            PricebookEntryId = pbe1.id,//contain p1
                            OpportunityId = opp1.id,
                            from_Date__c=Date.valueOf('2013-4-13'),
                            until_Date__c=Date.valueOf('2014-4-13'),
                            Billing_category__c=ExcelReportHelper.BILL_CAT_FIXPRICE,
                            Quantity=555,
                            TotalPrice=999,
                            Revenue2__c=r1.id,
                            package_line_item__c=ExcelReportHelper.PRO_RECORD_TYPE_PACKAGE //must package because p1 is packege
        );      
        OpportunityLineItem oli2 = new OpportunityLineItem(
                            PricebookEntryId = pbe2.id,//contain p2
                            OpportunityId = opp1.id,
                            from_Date__c=Date.valueOf('2013-4-13'),
                            until_Date__c=Date.valueOf('2014-8-13'),
                            Billing_category__c=ExcelReportHelper.BILL_CAT_CPC,
                            Quantity=555,
                            TotalPrice=999,
                            Revenue2__c=r2.id,
                            package_line_item__c=p1.id//must be id of p1 because p2 is sub-item in package p1
        );
        OpportunityLineItem oli3 = new OpportunityLineItem(
                            PricebookEntryId = pbe3.id,
                            OpportunityId = opp1.id,
                            from_Date__c=Date.valueOf('2013-4-13'),
                            until_Date__c=System.Today().addDays(-2),
                            Billing_category__c=ExcelReportHelper.BILL_CAT_CPM,
                            Quantity=555,
                            TotalPrice=999,
                            Revenue2__c=r3.id,
                            package_line_item__c=null
        );  
        OpportunityLineItem oli4 = new OpportunityLineItem(
                            PricebookEntryId = pbe3.id,
                            OpportunityId = opp1.id,
                            from_Date__c=Date.valueOf('2013-3-13'),
                            until_Date__c=Date.valueOf('2015-3-19'),
                            Billing_category__c=ExcelReportHelper.BILL_CAT_CPO,
                            Quantity=555,
                            TotalPrice=999,
                            Revenue2__c=r4.id,
                            package_line_item__c=null
        );
        OpportunityLineItem oli5 = new OpportunityLineItem(//for opp2
                            PricebookEntryId = pbe3.id,
                            OpportunityId = opp2.id,
                            from_Date__c=Date.valueOf('2013-4-13'),
                            until_Date__c=Date.valueOf('2013-7-13'),
                            Billing_category__c=ExcelReportHelper.BILL_CAT_CPM,
                            Quantity=555,
                            TotalPrice=999,
                            Revenue2__c=r3.id,
                            package_line_item__c=null
        );             
        List<OpportunityLineItem> listOppLineItem = new List<OpportunityLineItem>{oli1,oli2,oli3,oli4,oli5};
        insert listOppLineItem;
        */
        //add contact for OpportunityContactRole==========
        Contact con1=new Contact(
                        LastName='Test Contact 1',
                        Email='test1@test.com',
                        CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR 
        );
        Contact con2=new Contact(
                        LastName='Test Contact 2',
                        Email='test2@test.com',
                        CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR 
        );
        List<Contact> listContact = new List<Contact>{con1,con2}; 
        insert listContact;
        
        //add OpportunityContactRole============
        OpportunityContactRole ocr1 = new OpportunityContactRole(
                                            OpportunityId=opp1.id,
                                            ContactId=con1.id,
                                            Role=ExcelReportHelper.CONTACT_ROLE_REPORT_RECEIVER,
                                            IsPrimary=false
        );
        OpportunityContactRole ocr2 = new OpportunityContactRole(
                                            OpportunityId=opp1.id,
                                            ContactId=con2.id,
                                            Role=ExcelReportHelper.CONTACT_ROLE_OTHER,
                                            IsPrimary=true
        );
        OpportunityContactRole ocr3 = new OpportunityContactRole(//for opp2
                                            OpportunityId=opp2.id,
                                            ContactId=con2.id,
                                            Role=ExcelReportHelper.CONTACT_ROLE_OTHER,
                                            IsPrimary=true
        );
        OpportunityContactRole ocr4 = new OpportunityContactRole(//for opp2
                                            OpportunityId=opp3.id,
                                            ContactId=con2.id,
                                            Role=ExcelReportHelper.CONTACT_ROLE_OTHER,
                                            IsPrimary=true
        );
        List<OpportunityContactRole> listContRole = new List<OpportunityContactRole>{ocr1,ocr2,ocr3,ocr4};
        insert listContRole;
        
        
        
        Ad_Revenue_Monthly__c adMonthly1 =  new Ad_Revenue_Monthly__c(Amount__c=100,Ad_Product__c=adProd1.Id,Opportunity__c=opp1.Id,Transaction_Date__c=Date.valueOf('2013-4-13'));
        Ad_Revenue_Monthly__c adMonthly2 =  new Ad_Revenue_Monthly__c(Amount__c=100,Ad_Product__c=adProd2.Id,Opportunity__c=opp1.Id,Transaction_Date__c=Date.valueOf('2013-4-13'));
        Ad_Revenue_Monthly__c adMonthly3 =  new Ad_Revenue_Monthly__c(Amount__c=100,Ad_Product__c=adProd3.Id,Opportunity__c=opp1.Id,Transaction_Date__c=Date.valueOf('2013-4-13'));
        Ad_Revenue_Monthly__c adMonthly4 =  new Ad_Revenue_Monthly__c(Amount__c=100,Ad_Product__c=adProd4.Id,Opportunity__c=opp1.Id,Transaction_Date__c=Date.valueOf('2013-4-13'));        
        insert new List<Ad_Revenue_Monthly__c>{adMonthly1,adMonthly2,adMonthly3,adMonthly4};

        //add RSD2 ===============================
        Ad_Revenue_Daily__c rsd1 = new Ad_Revenue_Daily__c(
                                    Opportunity__c=opp1.id,
                                    Ad_Product__c=adProd1.id,
                                    Ad_Revenue_Monthly__c = adMonthly1.Id,
                                    CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
                                    Delivered_AI__c=1,
                                    Clicks_Recorded__c=1,
                                    Transaction_Date__c=Date.valueOf('2013-4-13')
        );
        Ad_Revenue_Daily__c rsd2 = new Ad_Revenue_Daily__c(
                                    Opportunity__c=opp1.id,
                                    Ad_Product__c=adProd2.id,
                                    Ad_Revenue_Monthly__c = adMonthly2.Id,
                                    CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
                                    Delivered_AI__c=1,
                                    Clicks_Recorded__c=1,
                                    Transaction_Date__c=Date.valueOf('2013-4-13')
        );
        Ad_Revenue_Daily__c rsd3 = new Ad_Revenue_Daily__c(
                                    Opportunity__c=opp1.id,
                                    Ad_Product__c=adProd3.id,
                                    Ad_Revenue_Monthly__c = adMonthly3.Id,
                                    CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
                                    Delivered_AI__c=1,
                                    Clicks_Recorded__c=1,
                                    Transaction_Date__c=Date.valueOf('2013-4-13')
        );
        Ad_Revenue_Daily__c rsd4 = new Ad_Revenue_Daily__c(
                                    Opportunity__c=opp1.id,
                                    Ad_Product__c=adProd4.id,
                                    Ad_Revenue_Monthly__c = adMonthly4.Id,
                                    CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
                                    Delivered_AI__c=1,
                                    Clicks_Recorded__c=1,
                                    Transaction_Date__c=Date.valueOf('2013-4-13')
        );
        Ad_Revenue_Daily__c rsd5 = new Ad_Revenue_Daily__c( //for opp2
                                    Opportunity__c=opp2.id,
                                    Ad_Product__c=adProd4.id,
                                    Ad_Revenue_Monthly__c = adMonthly4.Id,
                                    CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
                                    Delivered_AI__c=1,
                                    Clicks_Recorded__c=1,
                                    Transaction_Date__c=Date.valueOf('2013-4-13')
        );
        List<Ad_Revenue_Daily__c> listRSD = new List<Ad_Revenue_Daily__c>{rsd1,rsd2,rsd3,rsd4,rsd5};
        insert listRSD;  
                        
        
	        //Case:=====3.1. Manual Execution Report=============
	        ExcelReport excel = new ExcelReport(opp1.id);
	        system.assertEquals(2, excel.listMapColumnValue.size(),'1 from test data, 1 from dummy AP');//number of row in summery sheet (OpportunityLineItem oli3)
	        system.assertEquals(2, excel.listMapColumnValueDetail.size());//number of row in summery sheet (1 record + 1 Total row =2)
	        
	        
	        //Case:=====3.2. Manual Execution Mail and Report=============
	        //opp1
	        ExcelReportEmail mail1 = new ExcelReportEmail(opp1.id);
	        system.assertEquals('test1@test.com', mail1.toAddress);//this user's role is report reveiver
	        //system.assertEquals('user1@test.com', mail1.ccAddress);//this user is opp owner
	        system.assertNotEquals(null, mail1.bodyEmail);
	        mail1.sendMail();
	        //opp2
	        ExcelReportEmail mail2 = new ExcelReportEmail(opp2.id);//report=internal_only, language=EN, interval=monthly
	        system.assertEquals('user1@test.com', mail2.toAddress);//To address is sent to opp owner
	        mail2.sendMail();
	        
	        ExcelReportEmail mail3 = new ExcelReportEmail(opp3.id);
	        
	        //Case:=====3.3. Automatic Execution=============
	        ExcelReportBatch schedule = new ExcelReportBatch();
	        //SchedulableContext sc;
            
	        schedule.execute(null); 
            Test.stopTest();//============Stop test=================

	        
        
        
    } 
   
}