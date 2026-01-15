/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
/*********************************************************************************************************************************
@ Change history: 14.12.2022 / Bora Chhorn (bora.chhorn@gaea-sys.com) / US-0011835 - Clean Lead Layouts (Technical Debt)
*********************************************************************************************************************************/
@isTest
private class LX_CustomLeadConversionContrTest {
    public final static String SOQL_LEAD2 = 'SELECT isapproved__c, Name, Salutation, RecordTypeId, RecordType.DeveloperName, Company, eBayID__c, EBH_OracleID__c, LeadSegment__c, LeadSource, OtherLeadSource__c, VAT_Number__c, FirstName, LastName, Title, Email, Phone, MobilePhone, EBH_PreferredContactTime__c, Street, City, Country, PostalCode, State, Website, EBH_OtherMarketplaces__c, OnlineRank__c, EBH_CommentsBusinessReview__c, ShippingTechnology__c, TheoreticalRevenue__c, Site__c, EBH_Vertical__c, Status FROM Lead ';

    static testMethod void testConversion() {
    	
    	EBH_TestDataFactory.setUpCustomSettings();     
    	
    	List<Account> sellers =  EBH_TestDataFactory.createAccounts(1, 'EBH_Seller') ;
    	EBH_Project__c p1 = new EBH_Project__c(API__c = 'Other eBay API',EBH_Seller__c=sellers[0].Id,ProjectName__c='Project 1',RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Project__c','eBayAUEnterprise').Id);
        insert p1;
        Contact con = new Contact(LastName = 'testCount1', AccountId = sellers[0].Id, EBH_DataOrigin__c='test',EBH_Status__c='Active');
        insert con;
         
        // Lead l1 = new Lead(Status='Qualified',LeadSource='Self Gen',OtherLeadSource__c='test',LastName='Lead1',FirstName = 'FirstTest',MobilePhone='11223344',Phone='11223344',Email='test@test.com',Website='www.ebay.com',EBH_Vertical__c='Collectibles',VAT_Number__c='112233',Company='eBay',RecordTypeId=ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUEnterprise').Id); //BR-US-0011835
        Lead l1 = new Lead(Status='Qualified',LeadSource='Self Gen',OtherLeadSource__c='test',LastName='Lead1',FirstName = 'FirstTest',MobilePhone='11223344',Phone='11223344',Email='test@test.com',Website='www.ebay.com',EBH_Vertical__c='Collectibles',VAT_Number__c='112233',Company='eBay',RecordTypeId=ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUSMB').Id); 
        // Lead l2 = new Lead(Status='Declined',LeadSource='Self Gen',OtherLeadSource__c='test',LastName='Lead2',FirstName = 'FirstTest',MobilePhone='11223344',Phone='11223344',Email='test@test.com',Website='www.ebay.com',EBH_Vertical__c='Collectibles',VAT_Number__c='112233',Company='eBay',RecordTypeId=ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUEnterprise').Id); //BR-US-0011835
        Lead l2 = new Lead(Status='Declined',LeadSource='Self Gen',OtherLeadSource__c='test',LastName='Lead2',FirstName = 'FirstTest',MobilePhone='11223344',Phone='11223344',Email='test@test.com',Website='www.ebay.com',EBH_Vertical__c='Collectibles',VAT_Number__c='112233',Company='eBay',RecordTypeId=ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUSMB').Id);
        // Lead l3 = new Lead(Status='Qualified',LeadSource=null,OtherLeadSource__c='test',LastName='Lead3',FirstName = 'FirstTest',MobilePhone='11223344',Phone='11223344',Email='test@test.com',Website='www.ebay.com',EBH_Vertical__c='Collectibles',VAT_Number__c='112233',Company='eBay',RecordTypeId=ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUEnterprise').Id);
        insert new Lead[]{l1,l2};
        
        Test.startTest();
        //init: case1:  sucess
        Map<String,Object> result = LX_CustomLeadConversionContr.initCLCWrapper(l1.Id);
        //System.assertEquals('ok',result.get('status')+'','success. ready to convert');
        
        //init: case2: Qualified lead success 
        result = LX_CustomLeadConversionContr.initCLCWrapper(l2.Id);
        System.assertEquals('ko',result.get('status')+'','Only Qualified Leads are eligible for Conversion');
        
        //init: case3: Qualified lead failed
        // result = LX_CustomLeadConversionContr.initCLCWrapper(l3.Id);
        // System.assertEquals('ko',result.get('status')+'','required field missing');
        
        
        //fetchProject: case1:
        LX_CustomLeadConversionContr.CustomLeadConversionWrapper wpResult =  LX_CustomLeadConversionContr.fetchProject(sellers[0].Id);
        System.assertEquals(true,wpResult.ReturnResult.isSuccess = true,'fetch success');
        
        //convert;
        String leadId = l2.Id;
        String sWhere = ' Where Id=:leadId';
        Lead oneLead = Database.query(SOQL_LEAD2 +sWhere);
        
        wpResult.convAccount.account = sellers[0];
        wpResult.convContact.contact = con;
        wpResult.convProject.projects = new List<EBH_Project__c>{p1};
        wpResult.lead = oneLead;
       
        String strCLCWrp  = JSON.serialize(wpResult);
        
        LX_CustomLeadConversionContr.CustomLeadConversionWrapper convertResult =  LX_CustomLeadConversionContr.convertLead( strCLCWrp);
        
        Test.stopTest();
        
    }
    
   
}