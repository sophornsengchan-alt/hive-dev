/*********************************************************************************************************************************
@ Class:          DD_RetailWeekSpreadsheetControllerTest
@ Version:        1.0
@ Author:         MONY NOU (mony.nou@gaea-sys.com)
@ Purpose:        Coverage for DD_RetailWeekSpreadsheetController
@ Change history: 21.July.2021 / Mony Nou / Created the class.
@ Change history: 30.September.2022 / Bora Chhorn
*********************************************************************************************************************************/

@isTest
private class DD_RetailWeekSpreadsheetControllerTest {
    
    public static final String NA_Unsub_Deal = 'Deal_V3';
    public static final String DRC_Deal_WINDOW = 'Deal_Campaign_V2';
    
    @testSetup static void setup(){
		//DealRetailCampaignTriggerHandler.updateDealStatusByTimeBaseChange();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Id dealRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_Deal__c', NA_Unsub_Deal).Id;
        Id drcRecordTypeId = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', DRC_Deal_WINDOW).Id;
    	Account acc = new Account(Name='Test se2',RecordTypeID = sellerRecordType.Id,NA_Deals_Subsidy_PayPal_Email__c='test@test.com',NA_Deal_Program_Vetted__c = true);
        insert acc;
        Account accForAU = new Account(Name='AU Testing Seller',RecordTypeID = sellerRecordType.Id);
        insert accForAU;

        RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                        FirstName='firstname',Salutation='Mr.',LastName='test1',
                                        email='test1@test.com' , AccountId = acc.Id, recordtypeId = contactRecordTYpe.Id);
        insert contact1;
        Contact contact2 = new Contact(MailingCountry='AU',MailingState='Test',MailingCity='Test',
                                        FirstName='firstname',Salutation='Mr.',LastName='test1',
                                        email='test1@test.com' , AccountId = accForAU.Id, recordtypeId = contactRecordTYpe.Id);
        insert contact2;
        

        EBH_ActiveTriggers__c setting = new EBH_ActiveTriggers__c();
        setting.Name = 'EBH Trigger Controller';
        setting.DealRetailCampaign_Trigger__c = true;
        insert setting;
        Date startDate = System.today().addDays(20);
        Date endDate = System.today().addDays(21);
        DateTime dt = System.today();
        Time myTime = Time.newInstance(dt.hour(), dt.minute(), dt.second(), dt.millisecond());
        // create defualt spotlight category
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
        sc.Name = Label.US_UnSubDeal_Default_Spotlight;
        sc.EBH_Country__c = 'US';
        sc.EBH_SpotlightCategoryID__c = '123456789012';
        sc.Spotlight_End_Date__c = endDate;
        sc.Spotlight_Start_Date__c = startDate;
        insert sc;
        EBH_SpotlightCategory__c scAU = new EBH_SpotlightCategory__c();
        scAU.Name = Label.US_UnSubDeal_Default_Spotlight;
        scAU.EBH_Country__c = 'AU';
        scAU.EBH_SpotlightCategoryID__c = '123456789012';
        scAU.Spotlight_End_Date__c = endDate;
        scAU.Spotlight_Start_Date__c = startDate;
        insert scAU;

        EBH_DealRetailCampaign__c drc = new EBH_DealRetailCampaign__c(
            RecordTypeId = drcRecordTypeId,
            Status__c = 'Draft',
            EBH_DealTitle__c = 'SRO Test 001',
            Start_Retail_Week__c='2',
            EBH_Date__c = startDate,
            EPH_EndDate__c=endDate,
            End_Retail_Week__c = '5',
            EBH_Slots__c=3);
        insert drc;
        EBH_DealRetailCampaign__c drcAU = new EBH_DealRetailCampaign__c(
            RecordTypeId = drcRecordTypeId,
            Status__c = 'Draft',
            EBH_DealTitle__c = 'AU Test 001',
            Start_Retail_Week__c='2',
            EBH_Date__c = startDate,
            EPH_EndDate__c=endDate,
            End_Retail_Week__c = '5',
            EBH_Slots__c=3);
        insert drcAU;

        List<EBH_Deal__c> deals = new List<EBH_Deal__c>();
        for(Integer i=0;i<=9;i++){
            EBH_Deal__c d1 = new EBH_Deal__c(RecordTypeId = dealRecordTypeId, 
                                             EBH_SellerPrice__c = 1000,
                                             EBH_DealPrice__c = 11,
                                             EBH_BusinessName__c = acc.Id,
                                             EBH_SoldItems__c = 2,
                                             EBH_Vertical__c = 'CSA',
                                             EBH_DealStartDate__c = System.today(),
                                             EBH_DealEndDate__c = System.today().addDays(1),
                                             EBH_Status__c = 'Ops Review',
                                             EBH_Category__c = 'Gold',
                                             EBH_ProductTitle__c = 'product'+i,
                                             EBH_SellerEmail__c = 'sales@test.com'+i,
                                             EBH_Quantity__c = 1,
                                             EBH_DealStartTime__c = myTime,
                                             EBH_DealEndTime__c = myTime,
                                             EBH_DealFormat__c = 'Deal',
                                             EBH_eBayItemID__c = '12345678911'+i,
                                             EBH_DealSiteId__c='77',
                                             EBH_DealRetailCampaign__c = drc.Id,
                                             Seller_Contact__c = contact1.Id);
                                             
            deals.add(d1);
        }
        for(Integer i=0;i<=9;i++){
            EBH_Deal__c auDeals = new EBH_Deal__c(RecordTypeId = dealRecordTypeId, 
                                             EBH_SellerPrice__c = 1000,
                                             EBH_DealPrice__c = 11,
                                             EBH_BusinessName__c = accForAU.Id,
                                             EBH_SoldItems__c = 2,
                                             EBH_Vertical__c = 'CSA',
                                             EBH_DealStartDate__c = System.today(),
                                             EBH_DealEndDate__c = System.today().addDays(1),
                                             EBH_Status__c = 'Ops Review',
                                             EBH_Category__c = 'Gold',
                                             EBH_ProductTitle__c = 'product'+i,
                                             EBH_SellerEmail__c = 'sales@test.com'+i,
                                             EBH_Quantity__c = 1,
                                             EBH_DealStartTime__c = myTime,
                                             EBH_DealEndTime__c = myTime,
                                             EBH_DealFormat__c = 'Deal',
                                             EBH_eBayItemID__c = '12345678911'+i,
                                             EBH_DealSiteId__c='15',
                                             EBH_DealRetailCampaign__c = drcAU.Id,
                                             Seller_Contact__c = contact2.Id);
                                             
            deals.add(auDeals);
        }
        insert deals;
    }   

    @isTest
    static void test_method() {

        Test.startTest();

            EBH_DealRetailCampaign__c drc = [SELECT Id,Status__c,EBH_Date__c FROM EBH_DealRetailCampaign__c WHERE EBH_DealTitle__c = 'SRO Test 001'];
            String drcId = drc.Id;
            for(EBH_Deal__c deal: [SELECT EBH_DealRetailCampaign__r.Start_Retail_Week__c,Seller_Contact__c FROM EBH_Deal__c WHERE EBH_DealRetailCampaign__c = :drcId LIMIT 1]){
                PageReference rws_page = Page.DD_RetailWeekSpreadsheet;
                Test.setCurrentPage(rws_page);
                rws_page.getParameters().put('dwid', drcId);
                rws_page.getParameters().put('scid', String.valueOf(deal.Seller_Contact__c));
                rws_page.getParameters().put('dwrw', String.valueOf(deal.EBH_DealRetailCampaign__r.Start_Retail_Week__c));
                DD_RetailWeekSpreadsheetController cont = new DD_RetailWeekSpreadsheetController();

                String result = cont.currencyFormat;

            }

            EBH_DealRetailCampaign__c drcAU = [SELECT Id,Status__c,EBH_Date__c FROM EBH_DealRetailCampaign__c WHERE EBH_DealTitle__c = 'AU Test 001'];
            String drcAUId = drcAU.Id;
            for(EBH_Deal__c deal: [SELECT EBH_DealRetailCampaign__r.Start_Retail_Week__c,Seller_Contact__c FROM EBH_Deal__c WHERE EBH_DealRetailCampaign__c = :drcAUId LIMIT 1]){
                PageReference rws_page = Page.DD_RetailWeekSpreadsheet;
                Test.setCurrentPage(rws_page);
                rws_page.getParameters().put('dwid', drcAUId);
                rws_page.getParameters().put('scid', String.valueOf(deal.Seller_Contact__c));
                rws_page.getParameters().put('dwrw', String.valueOf(deal.EBH_DealRetailCampaign__r.Start_Retail_Week__c));
                DD_RetailWeekSpreadsheetController cont = new DD_RetailWeekSpreadsheetController();

                String result = cont.currencyFormat;

            }

        Test.stopTest();
    }
}