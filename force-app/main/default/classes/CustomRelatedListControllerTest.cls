@isTest
private class CustomRelatedListControllerTest {
    public static final String NA_Unsub_Deal = 'Deal_V3';
    public static final String DRC_Deal_WINDOW = 'Deal_Campaign_V2';
    public static final String DRC_Deal_WINDOW_CAMPAIGN = 'Deal_Campaign_V3';

    @testSetup static void setup(){
        //DealRetailCampaignTriggerHandler.updateDealStatusByTimeBaseChange();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Id dealRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_Deal__c', NA_Unsub_Deal).Id;
        Id drcRecordTypeId = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', DRC_Deal_WINDOW).Id;
        Account acc = new Account(Name='Test se2',RecordTypeID = sellerRecordType.Id,NA_Deals_Subsidy_PayPal_Email__c='test@test.com',NA_Deal_Program_Vetted__c = true);
        insert acc;

        RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                        FirstName='firstname',Salutation='Mr.',LastName='test1',
                                        email='test1@test.com' , AccountId = acc.Id, recordtypeId = contactRecordTYpe.Id);
        insert contact1;
        

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

        List<EBH_DealRetailCampaign__c> lstDW = new List<EBH_DealRetailCampaign__c>();
        EBH_DealRetailCampaign__c drc = new EBH_DealRetailCampaign__c(
            EBH_Country__c = '0',
            RecordTypeId = drcRecordTypeId,
            Status__c = 'Draft',
            EBH_DealTitle__c = 'SRO Test 001',
            Start_Retail_Week__c='2',
            EBH_Date__c = startDate,
            EPH_EndDate__c=endDate,
            End_Retail_Week__c = '5',
            EBH_Slots__c=3);

        lstDW.add(drc);

        for(Integer i=0;i<5;i++){
            EBH_DealRetailCampaign__c dw = new EBH_DealRetailCampaign__c(
                                                                            RecordTypeId = drcRecordTypeId,
                                                                            Status__c = 'Draft',
                                                                            EBH_DealTitle__c = 'SCH Test 00'+i,
                                                                            Start_Retail_Week__c='2',
                                                                            EBH_Date__c = System.today().addDays(1),
                                                                            EPH_EndDate__c=System.today().addDays(6),
                                                                            End_Retail_Week__c = '5',
                                                                            EBH_Slots__c=3
                                                                        );
                                                                                                            
            lstDW.add(dw);
        }
        insert lstDW;

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

        insert deals;
    }   

    @isTest
    static void initVFPageTest(){
        PageReference myVfPage = Page.CustomRelatedListVF;
        Test.setCurrentPage(myVfPage);

        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('metadata_record_name', 'Deal_On_DRC');

        EBH_DealRetailCampaign__c drc = [SELECT Id FROM EBH_DealRetailCampaign__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(drc);
        CustomRelatedListController ac = new CustomRelatedListController();
        ac.initVFPage();

        CustomRelatedListController.apexInit('Deal_On_DRC', drc.Id);
        CustomRelatedListController.deleteRecord(drc.Id);
        
    }
}