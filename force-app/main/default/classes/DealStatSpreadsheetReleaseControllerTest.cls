/*****************************************************************************************************************************
@ Class:        DealStatSpreadsheetReleaseControllerTest
@ Version:      1.0
@ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:      US-0008786 Test class for DealStatSpreadsheetReleaseController.
@               It is migrated from JOIN, it is DD_DealStatSpreadsheetReleaseConTest
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.01.2021 / Sophal Noch / Created the class.
*****************************************************************************************************************************/
@isTest
public class DealStatSpreadsheetReleaseControllerTest {
    
    @testSetup static void setup() {
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            byPass__c settings = byPass__c.getOrgDefaults();
            settings.ByPass_Validation__c = true;
            upsert settings byPass__c.Id;
            Profile adminProfile = [select Id,Name from Profile where Name = 'System Administrator'];
    
            User user = new User();
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
            
            Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
            dealTimezone.TimeZone__c='America/Los_Angeles';     
            insert dealTimezone;
    
            Account acc = new Account();
            acc.Name = 'AMT_Account';
            acc.BillingCountry = 'US';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EBH_LegalEntity').getRecordTypeId();
            insert acc;
    
            Account eBSeller = new Account();
            eBSeller.Name = 'AMT_Seller';
            eBSeller.ParentId = acc.Id;
            eBSeller.EBH_MainVertical__c = 'Electronics';
            eBSeller.EBH_OracleID__c = 'AXTP-930494';
            // eBSeller.Daily_Deals_Whitelist__c = true;
            insert eBSeller;
    
            Contact cont = new Contact();
            cont.LastName = 'AMT_Cont';
            // cont.AccountId = acc.Id;
            cont.AccountId = eBSeller.Id;
            cont.Contact_Role__c='Deals;Marketplaces - Daily Deals Statement Recipient';
            //cont.EBH_Decision_Maker_Role__c = 'Deals'; //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
            cont.Email ='test@ebay.dailydeal.com';
            cont.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('EBH_MANUAL').getRecordTypeId();
            insert cont;
    
            EBH_SpotlightCategory__c spCat = new EBH_SpotlightCategory__c();
            spCat.Name = 'AMT_Spotligth NA';
            spCat.EBH_Country__c = 'NA';
            spCat.EBH_SpotlightCategoryID__c = 'SCiD-934035';
            //spCat.Vertical__c = 'Fashion';
            insert spCat;
    
            Date myDate = System.Today().adddays(2);
            Time myTime = Time.newInstance(1, 1, 1, 1);
            Id euRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get('Deal_V2').getRecordTypeId();
            
            EBH_Deal__c deal1 = new EBH_Deal__c();
            deal1.RecordTypeId = euRecordTypeId;
            deal1.Merchant_Approver__c = user.Id;
            deal1.EBH_BusinessName__c = eBSeller.Id;
            deal1.EBH_ProductTitle__c = 'AMTProductTest';
            deal1.EBH_Vertical__c = 'Fashion';
            deal1.EBH_Category__c = 'Health';
            deal1.Sub_Category__c = 'Massage';
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
         
            insert deal1;
            
            EBH_Deal__c deal2 = new EBH_Deal__c();
            deal2.RecordTypeId = euRecordTypeId;
            deal2.Merchant_Approver__c = user.Id;
            deal2.EBH_BusinessName__c = eBSeller.Id;
            deal2.EBH_ProductTitle__c = 'AMTProductTest2';
            deal2.EBH_Vertical__c = 'Fashion';
            deal2.EBH_Category__c = 'Health';
            deal2.Sub_Category__c = 'Massage';
            deal2.EBH_DealFormat__c = 'Primary';
            deal2.EBH_DealStartDate__c = myDate;
            deal2.EBH_DealStartTime__c = myTime;
            deal2.EBH_DealEndDate__c = myDate;
            deal2.EBH_DealEndTime__c = myTime;
            deal2.EBH_Status__c = 'New';
            deal2.EBH_Quantity__c = 1;
            deal2.Quantity_Limitation_per_Purchaser__c = 1;
            deal2.EBH_DealPrice__c = 1;
            deal2.EBH_SellerPrice__c = 1;
            deal2.EBH_SoldItemsForecast__c = 123456;
            deal2.Seller_Approver_1__c = cont.Id;
            deal2.Sold_Items_30_Days__c = 1;
            deal2.Sold_Items_60_Days__c = 2;
            deal2.Final_Sold_Items__c = 1; 
            
            insert deal2;
         
            
            Deal_Statement__c ds1 = new Deal_Statement__c();
            ds1.Name = eBSeller.Name+myDate.month()+'Statement';
            ds1.Subsidy_Final_Calculation__c=0;                 
            ds1.Status__c = '1st Payout Approved';
                
            ds1.eBay_Seller__c =deal1.EBH_BusinessName__c ;
            ds1.Subsidy_Final_Calculation__c=0;
            
                
            insert ds1;
        
            
            deal1.Deal_Statement__c = ds1.Id;
            update deal1;
            
            deal2.Deal_Statement__c = ds1.Id;
            update deal2;
        }
        
    }
    
    @isTest 
    public static void test_method(){
        Test.startTest();
            String defRecordType = '';
            DealStatSpreadsheetReleaseController.getDealStatement('1st Payout Approved',0,10, new List<String>(),defRecordType); //Sophal:11/05/2021:US-0009424
            DealStatSpreadsheetReleaseController.getDealStatement('2nd Payout Approved',0,10, new List<String>(),defRecordType); //Sophal:11/05/2021:US-0009424
            DealStatSpreadsheetReleaseController.getSearchDealStatement('1st Payout Approved',0,10,'test', 'Name', 'Name', true, new List<String>()); //Sophal:11/05/2021:US-0009424
            DealStatSpreadsheetReleaseController.getSearchDealStatement('2nd Payout Approved',0,10,'test', 'Name', 'Name', true, new List<String>()); //Sophal:11/05/2021:US-0009424
            DealStatSpreadsheetReleaseController.getSearchDealStatement('1st Payout Approved',0,10,'0', 'Subsidy_Final_Calculation__c', 'Subsidy_Final_Calculation__c', true, new List<String>()); //Sophal:11/05/2021:US-0009424
            DealStatSpreadsheetReleaseController.getSearchDealStatement('2nd Payout Approved',0,10,'0', 'Subsidy_Final_Calculation__c', 'Subsidy_Final_Calculation__c', true, new List<String>()); //Sophal:11/05/2021:US-0009424
            DealStatSpreadsheetReleaseController.fetchRecordType();
            List<Deal_Statement__c> dealStateLst = [SELECT Id, Name FROM Deal_Statement__c WHERE Status__c = '1st Payout Approved'];
            List<String> dsLstId = new List<String>();
            for (Deal_Statement__c ds: dealStateLst) {
                dsLstId.add(ds.Id);
            }
        
            DealStatSpreadsheetReleaseController.sendExcel(dsLstId);     
            
        Test.stopTest();
    }
    
    
}