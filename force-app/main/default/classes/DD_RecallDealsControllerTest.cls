/*********************************************************************************************************************************
@ Class:          DD_RecallDealsControllerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        test Class for DD_RecallDealsController
@ Description :   US-0008182 - [US]* Deals Mass Recall from Approval Process for Deals Managers
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  29.09.2020 / Sovantheany Dim / Created the class.
@ Change history:  27.07.2021 / SRONG TIN / update the class.
*********************************************************************************************************************************/
@isTest
private class DD_RecallDealsControllerTest {
    public static final String DRC_Deal_WINDOW = 'Deal_Campaign_V2';
    public static final String NA_Unsub_Deal = 'Deal_V3';
    @testSetup
    static void setup(){
        
        Id drcRecordTypeId = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', DRC_Deal_WINDOW).Id;
        Id dealRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_Deal__c', NA_Unsub_Deal).Id;
        Date startDate = System.today().addDays(20);
        Date endDate = System.today().addDays(21);
        DateTime dt = System.today();
        Time myTime = Time.newInstance(dt.hour(), dt.minute(), dt.second(), dt.millisecond());
        EBH_DealRetailCampaign__c drc = new EBH_DealRetailCampaign__c(
            RecordTypeId = drcRecordTypeId,
            EBH_DealTitle__c = 'SRO Test 001',
            Start_Retail_Week__c='2',
            EBH_Date__c = startDate,
            EPH_EndDate__c=endDate,
            End_Retail_Week__c = '5',
            EBH_Slots__c=3);
        insert drc;
        
    	byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        RecordType recseller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account acc = new Account(Name='Test Account Name: 1', BillingCountry='CH', RecordTypeId=recseller.Id,EBH_OracleID__c='12345');
        insert acc;
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = acc.Id);
        Contact contact2 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test2',
                                      email='test2@test.com' , AccountId = acc.Id);
        insert new List<Contact>{contact1,contact2};
        RecordType recNAdeal = ApexUtil.getRecordTypeByName('EBH_Deal__c',DD_RecallDealsController.NA_DEAL_RECORDTYPE);
        EBH_Deal__c d1 = new EBH_Deal__c(Seller_Approver_1__c = contact1.Id, Merchant_Approver__c = UserInfo.getUserId(),EBH_Vertical__c='Electronics', EBH_Status__c=DD_RecallDealsController.IN_APPROVAL,EBH_BusinessName__c=acc.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='000000000011', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test',RecordTypeId=recNAdeal.Id,
                                EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
        EBH_Deal__c d2 = new EBH_Deal__c(Seller_Approver_1__c = contact2.Id, Merchant_Approver__c = UserInfo.getUserId(), EBH_Vertical__c='Electronics',EBH_Status__c=DD_RecallDealsController.SENT_TO_SELLER,EBH_BusinessName__c=acc.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='000000000012', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test',RecordTypeId=recNAdeal.Id,
                                EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
        EBH_Deal__c d3 = new EBH_Deal__c(RecordTypeId = dealRecordTypeId, EBH_SellerPrice__c = 1000,EBH_DealPrice__c = 11,EBH_BusinessName__c = acc.Id,EBH_SoldItems__c = 2,
                                             EBH_Vertical__c = 'CSA',EBH_DealStartDate__c = System.today(),EBH_DealEndDate__c = System.today().addDays(1),EBH_Status__c = 'Rejected',
                                             EBH_Category__c = 'Gold',EBH_ProductTitle__c = 'product',EBH_SellerEmail__c = 'sales@test.com',EBH_Quantity__c = 1,EBH_DealStartTime__c = myTime,
                                             EBH_DealEndTime__c = myTime,EBH_DealFormat__c = 'Deal',EBH_eBayItemID__c = '1234567891',EBH_DealSiteId__c='77',EBH_DealRetailCampaign__c = drc.Id,Seller_Contact__c = contact1.Id);
                                             
        
        insert new list<EBH_Deal__c>{d1,d2,d3};
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(d1.id);
        Approval.ProcessResult result = Approval.process(app);
    }
    
    static testMethod void testrecallDealsAction() {
        List<EBH_Deal__c> lstDeal = [select id,EBH_Status__c from EBH_Deal__c];
        System.debug('<<<<lstDeal='+lstDeal);
        Test.startTest();
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
        ssc.setSelected(lstDeal);
        DD_RecallDealsController ddRecall = new DD_RecallDealsController(ssc);
        ddRecall.recallDealsAction();
        ddRecall.cancel();
        Test.stopTest();
        List<EBH_Deal__c> lstDealSelect = [select EBH_Status__c from EBH_Deal__c where id IN: lstDeal];
        System.assert(lstDealSelect.size() == 3);
    }
    
    @isTest 
    public static void test_isNotSendToSellerOrInApproval(){
        List<EBH_Deal__c> lstDeal = [select id from EBH_Deal__c];
        for(EBH_Deal__c eachDeal : lstDeal){
            eachDeal.EBH_Status__c = 'Internally Approved';
        }
        update lstDeal;
        Test.startTest();
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
            ssc.setSelected(lstDeal);
            DD_RecallDealsController controller = new DD_RecallDealsController(ssc);
            controller.recallDealsAction();
        Test.stopTest();
        System.assertEquals(true, controller.isNotSendToSellerOrInApproval);
    } 
    @isTest 
    public static void test_isDealWindowDRC(){
        List<EBH_Deal__c> lstDeal = [select id from EBH_Deal__c Where EBH_DealRetailCampaign__c != null];
        EBH_DealRetailCampaign__c drc = [select Id,Status__c from EBH_DealRetailCampaign__c];
        Test.startTest();
        	ApexPages.currentPage().getParameters().put('Id',drc.Id);   
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
            ssc.setSelected(lstDeal);
            DD_RecallDealsController controller = new DD_RecallDealsController(ssc);
            controller.recallDealsAction();
        Test.stopTest();
        lstDeal = [select Id,EBH_Status__c from EBH_Deal__c where EBH_DealRetailCampaign__c != null];
        System.assert(lstDeal[0].EBH_Status__c == drc.Status__c);
    } 
}