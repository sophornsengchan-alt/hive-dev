/*********************************************************************************************************************************
@ Class:          DD_CreateDealStatementTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Test for class DD_CreateDealStatement
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.01.2021 / Sovantheany Dim / Created the class migrate from join
@ Change history: 12.09.2022/ Sophal Noch / US-0012393 - Fix Test Class DD_CreateDealStatement , increase coverage from 0 to 80%
*********************************************************************************************************************************/
@isTest
private class DD_CreateDealStatementTest {
	private static List<EBH_Deal__c> deals = new List<EBH_Deal__c>();
    private static Deal_Statement_Setting__c setting = new Deal_Statement_Setting__c();
     @testSetup
    static void setup(){
    	setting.Initial_Payout__c=0.60;
    	setting.Amount_Held_Back__c=0.40;
    	setting.Deal_Statement_Owner__c = 'Deals_BU_team';
    	insert setting;
        Account acc = new Account(Name='Test Account Name: 1', BillingCountry='CH');
        insert acc;
        Account eBaySeller1 = new Account (Name='Test eBaySeller For Doc Approve 1',EBH_OracleID__c='12345');
        Account eBaySeller2 = new Account (Name='Test eBaySeller For Doc Approve 2',EBH_OracleID__c='12346');
        Account eBaySeller3 = new Account (Name='Test eBaySeller For Doc Approve 3',EBH_OracleID__c='12347');
        insert new List<Account>{eBaySeller1,eBaySeller2,eBaySeller3};
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller1.Id);
        Contact contact2 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test2',
                                      email='test2@test.com' , AccountId = eBaySeller2.Id);
        insert new List<Contact>{contact1,contact2};
        Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
        dealTimezone.TimeZone__c='America/Los_Angeles';     
        insert dealTimezone;
        EBH_SpotlightCategory__c spotCat = new EBH_SpotlightCategory__c(Name = 'test spotLightCat',EBH_Country__c='NA',EBH_SpotlightCategoryID__c='testSpotId');
        insert spotCat;
        Id devRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2').Id;
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(RecordTypeId=ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals').Id);
        insert ndca;
        Time t = System.now().time();
        Date myDate = System.Today();
        integer i=0;
        Time startTime = t.addHours(2);
        Time endTime = t.addHours(3);
        deals = new List<EBH_Deal__c>();
            EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i++, 
            Seller_Approver_1__c = contact1.Id,
            EBH_BusinessName__c=eBaySeller1.ID,
            EBH_SpotlightCategory__c = spotCat.Id,
            RecordTypeId=devRecordTypeId,
            EBH_SellerPrice__c=20,
            EBH_Quantity__c=2,
            EBH_SoldItems__c=2,
            Final_Sold_Items__c=5,
            EBH_DealPrice__c =10,
            EBH_DealStartDate__c=myDate,
            EBH_DealStartTime__c =  startTime,
            EBH_DealEndDate__c=myDate,
            EBH_DealEndTime__c = endTime,
            EBH_Status__c='Running',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
            Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
            EBH_DealSiteId__c = '0', // 12.09.2022/ Sophal Noch / US-0012393
            EBH_MaximumPurchases__c = 2,  // 12.09.2022/ Sophal Noch / US-0012393
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);

            deals.add( d1);
            
            EBH_Deal__c d2 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i++, 
            Seller_Approver_1__c = contact1.Id,
            EBH_BusinessName__c=eBaySeller2.ID,
            EBH_SpotlightCategory__c = spotCat.Id,
            RecordTypeId=devRecordTypeId,
            EBH_SellerPrice__c=20,
            EBH_Quantity__c=5,
            EBH_DealPrice__c =10,
            EBH_DealStartDate__c=myDate,
            EBH_DealStartTime__c =  startTime,
            EBH_DealEndDate__c=myDate,
            EBH_DealEndTime__c = startTime,           
            EBH_SoldItems__c=5,
            Final_Sold_Items__c=5,
            EBH_Status__c='Running',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
            Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
            EBH_DealSiteId__c = '0', // 12.09.2022/ Sophal Noch / US-0012393
            EBH_MaximumPurchases__c = 2,  // 12.09.2022/ Sophal Noch / US-0012393
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);
            deals.add( d2);
            
            EBH_Deal__c d3 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i, 
            Seller_Approver_1__c = contact1.Id,
            EBH_BusinessName__c=eBaySeller3.ID,
            EBH_SpotlightCategory__c = spotCat.Id,
            RecordTypeId=devRecordTypeId,
            EBH_SellerPrice__c=20,
            EBH_Quantity__c=5,         
            EBH_SoldItems__c=5,
            Final_Sold_Items__c=5,
            EBH_DealStartDate__c=myDate,
            EBH_DealPrice__c =5,
            EBH_DealStartTime__c =  startTime,
            EBH_DealEndDate__c=myDate,
            EBH_DealEndTime__c = startTime,
            EBH_Status__c='Running',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
            Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
            EBH_DealSiteId__c = '0', // 12.09.2022/ Sophal Noch / US-0012393
            EBH_MaximumPurchases__c = 2,  // 12.09.2022/ Sophal Noch / US-0012393
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);     
            deals.add( d3);
            
            EBH_Deal__c d4 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000002'+i, 
            Seller_Approver_1__c = contact1.Id,
            EBH_BusinessName__c=eBaySeller3.ID,
            EBH_SpotlightCategory__c = spotCat.Id,
            RecordTypeId=devRecordTypeId,
            EBH_SellerPrice__c=20,
            EBH_Quantity__c=5,         
            EBH_SoldItems__c=5,
            Final_Sold_Items__c=5,
            EBH_DealStartDate__c=myDate,
            EBH_DealPrice__c =5,
            EBH_DealStartTime__c =  startTime,
            EBH_DealEndDate__c=myDate,
            EBH_DealEndTime__c = startTime,
            EBH_Status__c='Running',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
            Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
            EBH_DealSiteId__c = '0', // 12.09.2022/ Sophal Noch / US-0012393
            EBH_MaximumPurchases__c = 2,  // 12.09.2022/ Sophal Noch / US-0012393
            EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);
            deals.add(d4);
            insert deals;
    }
    @isTest 
    public static void test_batchFail(){
    	Deal_Statement_Setting__c ds_setting = Deal_Statement_Setting__c.getOrgDefaults();
    	ds_setting.Deal_Statement_Owner__c = 'Fake_Name1';
    	update ds_setting;

        test.starttest();
        Database.executeBatch(new DD_CreateDealStatement());       
        test.stoptest();    	
    }
    @isTest 
    public static void test_create1stStatement(){
        List<EBH_Deal__c> listDeals = [Select id, Subsidy_Due_30_Days__c From EBH_Deal__c];
        //Update deals to fit 1st statement
        listDeals[0].Subsidy_Due_30_Days__c = 10;
        listDeals[1].Subsidy_Due_30_Days__c = 20;
        listDeals[2].Subsidy_Due_30_Days__c = 30;
        listDeals[3].Subsidy_Due_30_Days__c = 30;
        listDeals[0].Subsidy_Due_60_Days__c = 10;
        listDeals[1].Subsidy_Due_60_Days__c = 20;
        listDeals[2].Subsidy_Due_60_Days__c = 30;
        listDeals[3].Subsidy_Due_60_Days__c = 30;       
        update listdeals;
        
        test.starttest();
        Database.executeBatch(new DD_CreateDealStatement());       
        test.stoptest();
        
        List<Deal_Statement__c> dealstatements =[select Id,Initial_Payout__c,Amount_Held_Back__c,Second_Payout__c,eBay_Seller__r.Name,Subsidy_30_day_calculation__c, Subsidy_Final_Calculation__c,Status__c from Deal_Statement__c where eBay_Seller__r.Name in('Test eBaySeller For Doc Approve 1','Test eBaySeller For Doc Approve 2','Test eBaySeller For Doc Approve 3')];
        System.AssertEquals(dealstatements.size(),3);     
        for(Deal_Statement__c ds:dealstatements){
            if(ds.eBay_Seller__r.Name=='Test eBaySeller For Doc Approve 1'){
                System.AssertEquals(ds.Subsidy_30_day_calculation__c,10);
                System.assertEquals(ds.Initial_Payout__c,6);   
                System.assertEquals(ds.Amount_Held_Back__c,4);                  
            }else if(ds.eBay_Seller__r.Name=='Test eBaySeller For Doc Approve 2'){
                System.AssertEquals(ds.Subsidy_30_day_calculation__c,20);
                System.assertEquals(ds.Initial_Payout__c,12);   
                System.assertEquals(ds.Amount_Held_Back__c,8);                  
            }else if(ds.eBay_Seller__r.Name=='Test eBaySeller For Doc Approve 3'){
                System.AssertEquals(ds.Subsidy_30_day_calculation__c,60);
                System.assertEquals(ds.Initial_Payout__c,36);   
                System.assertEquals(ds.Amount_Held_Back__c,24);                 
            }
       }
    } 
    @istest 
    private static void test2ndStatement(){
        List<Account> listseller = [Select id, name From Account where Name in('Test eBaySeller For Doc Approve 1','Test eBaySeller For Doc Approve 2','Test eBaySeller For Doc Approve 3')];
        User[] admins = [select id from User where Profile.Name='System Administrator' AND isActive=TRUE limit 4];
        
    	//Create deal statements
    	List<deal_statement__c> dealstatements = new List<deal_Statement__c>();
    	Deal_Statement__c ds1 = new Deal_Statement__c();
    	ds1.Name = 'Test eBaySeller For Doc Approve 1';
    	ds1.Status__c = '1st Payout Approved';
    	ds1.Sold_item_effective_Date__c = System.Today().addMonths(-2);
    	ds1.Subsidy_30_day_calculation__c = 10;
    	ds1.Initial_Payout__c = 6;
    	ds1.Amount_Held_Back__c= 4;
    	ds1.ebay_seller__c = listseller[0].id;
    	dealstatements.add(ds1);
    	Deal_Statement__c ds2 = new Deal_Statement__c();
    	ds2.Name = 'Test eBaySeller For Doc Approve 2';
    	ds2.Status__c = '1st Payout Approved';
    	ds2.Sold_item_effective_Date__c = System.Today().addMonths(-2);
    	ds2.Subsidy_30_day_calculation__c = 20;
    	ds2.Initial_Payout__c = 12;
    	ds2.Amount_Held_Back__c= 8;
    	ds2.ebay_seller__c = listseller[1].id;    	
    	dealstatements.add(ds2);
    	Deal_Statement__c ds3 = new Deal_Statement__c();
    	ds3.Name = 'Test eBaySeller For Doc Approve 3';
    	ds3.Status__c = '1st Payout Approved';
    	ds3.Sold_item_effective_Date__c = System.Today().addMonths(-2);
    	ds3.Subsidy_30_day_calculation__c = 60;
    	ds3.Initial_Payout__c = 36;
    	ds3.Amount_Held_Back__c= 24;
    	ds3.ebay_seller__c = listseller[2].id;    	
    	dealstatements.add(ds3);    
    	insert dealstatements;	
     
    	List<EBH_Deal__c> listDeals = [Select id, EBH_DealStartDate__c, Subsidy_Due_30_Days__c From EBH_Deal__c];
        //Update deals to fit 1st statement
        listDeals[0].Subsidy_Due_30_Days__c = 10;
        listDeals[1].Subsidy_Due_30_Days__c = 20;
        listDeals[2].Subsidy_Due_30_Days__c = 30;
        listDeals[3].Subsidy_Due_30_Days__c = 30;
        listDeals[0].Subsidy_Due_60_Days__c = 10;
        listDeals[1].Subsidy_Due_60_Days__c = 16;
        listDeals[2].Subsidy_Due_60_Days__c = 20;
        listDeals[3].Subsidy_Due_60_Days__c = 30;
        listDeals[0].Sold_item_effective_date__c = System.Today();
        listDeals[1].Sold_item_effective_date__c = System.Today();
        listDeals[2].Sold_item_effective_date__c = System.Today();
        listDeals[3].Sold_item_effective_date__c = System.Today();
        listDeals[0].X1st_Payout_Amount__c = 6;
        listDeals[1].X1st_Payout_Amount__c = 12;
        listDeals[2].X1st_Payout_Amount__c = 18;
        listDeals[3].X1st_Payout_Amount__c = 18;
        listDeals[0].X1st_Payout_Amount_Remaining__c = 4;
        listDeals[1].X1st_Payout_Amount_Remaining__c = 8;
        listDeals[2].X1st_Payout_Amount_Remaining__c = 12;
        listDeals[3].X1st_Payout_Amount_Remaining__c = 12;
        listDeals[0].X2nd_Payout_Amount__c = 4;
        listDeals[1].X2nd_Payout_Amount__c = 4;
        listDeals[2].X2nd_Payout_Amount__c = 2;
        listDeals[3].X2nd_Payout_Amount__c = 12; 
        listDeals[0].Deal_statement__c = ds1.id;
        listDeals[1].Deal_statement__c = ds2.id;
        listDeals[2].Deal_statement__c = ds3.id;
        listDeals[3].Deal_statement__c = ds3.id;                    
        update listdeals;

        ds1.month__c = String.ValueOf(listDeals[0].EBH_DealStartDate__c.month());        
        ds2.month__c = String.ValueOf(listDeals[1].EBH_DealStartDate__c.month());
        ds3.month__c = String.ValueOf(listDeals[2].EBH_DealStartDate__c.month());
        update dealstatements;

       

         
            test.starttest();
                DD_CreateDealStatement bcds = new DD_CreateDealStatement();
                Database.executeBatch(bcds); 
            test.stoptest();    
                
            dealstatements =[select Id,Initial_Payout__c,Amount_Held_Back__c,Second_Payout__c,eBay_Seller__r.Name,Subsidy_30_day_calculation__c, Subsidy_Final_Calculation__c,Status__c from Deal_Statement__c where eBay_Seller__r.Name in('Test eBaySeller For Doc Approve 1','Test eBaySeller For Doc Approve 2','Test eBaySeller For Doc Approve 3')];
            System.AssertEquals(dealstatements.size(),3);     
            for(Deal_Statement__c ds:dealstatements){
                if(ds.eBay_Seller__r.Name=='Test eBaySeller For Doc Approve 1'){
                    System.AssertEquals(ds.Status__c,'2nd Statement');
                    System.AssertEquals(ds.Subsidy_Final_Calculation__c,10);
                    System.AssertEquals(ds.Second_Payout__c,4);            	          
                }else if(ds.eBay_Seller__r.Name=='Test eBaySeller For Doc Approve 2'){
                    System.AssertEquals(ds.Status__c,'2nd Statement');
                    System.AssertEquals(ds.Subsidy_Final_Calculation__c,16);
                    System.AssertEquals(ds.Second_Payout__c,4);            	
                }else if(ds.eBay_Seller__r.Name=='Test eBaySeller For Doc Approve 3'){
                    System.AssertEquals(ds.Status__c,'2nd Statement');
                    System.AssertEquals(ds.Subsidy_Final_Calculation__c,50);
                    System.AssertEquals(ds.Second_Payout__c,14);            	
                }
           } 
        
        
       	   
              
    }  
}