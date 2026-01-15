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
@isTest
private class DealInvoiceVerificationControllerTest {

    static testMethod void testDealInvoiceReadyForPayment() {
        RecordType r_seller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account seller1 = new Account(RecordTypeId=r_seller.Id,Name='seller test deal invoice 123456');
        insert seller1;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Spotlight Category', EBH_SpotlightCategoryID__c='Spotlight Category1',EBH_Country__c='UK'); 
        insert sc;
        EBH_Deal__c d1 = new EBH_Deal__c(EBH_DealEndDate__c=Date.today().addDays(1),EBH_DealFormat__c='Primary',EBH_eBayItemID__c='123456789',EBH_SellerPrice__c=1000,EBH_DealPrice__c=500,EBH_SoldItems__c=2,EBH_DealStartDate__c=System.today(),EBH_Status__c='New',EBH_DealSiteId__c='77',EBH_Vertical__c='Fashion',EBH_Category__c='Baby', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1, EBH_SpotlightCategory__c=sc.id,EBH_BusinessName__c=seller1.Id);
        insert d1;
        
        EBH_DealInvoice__c div1 = new EBH_DealInvoice__c(EBH_Deal__c = d1.Id);
        insert div1;
        
        Test.startTest();
        Map<String,Object> mapResult = DealInvoiceVerificationController.apexInit(div1.Id);
        
        EBH_DealInvoice__c div1_Res =  (EBH_DealInvoice__c)mapResult.get('dealInvoice');
        System.assertEquals(div1.Id,div1_Res.Id,'object with fields value');
        
        Map<String,Object> mapResult2 = DealInvoiceVerificationController.apexReadyPayment(d1.Id,div1.Id);
        System.assertEquals('ok',mapResult2.get('status')+'','ready for payment updated');
        
        Test.stopTest();
        
        
    }
    
    static testMethod void testDealInvoiceRejectFR() {
    	RecordType r_seller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account seller1 = new Account(RecordTypeId=r_seller.Id,Name='seller test deal invoice 123456');
        insert seller1;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Spotlight Category', EBH_SpotlightCategoryID__c='Spotlight Category1',EBH_Country__c='FR'); 
        insert sc;
        EBH_Deal__c d1 = new EBH_Deal__c(EBH_DealEndDate__c=Date.today().addDays(1),EBH_DealFormat__c='Primary',EBH_eBayItemID__c='123456789',EBH_SellerPrice__c=1000,EBH_DealPrice__c=500,EBH_SoldItems__c=2,EBH_DealStartDate__c=System.today(),EBH_Status__c='New',EBH_DealSiteId__c='77',EBH_Vertical__c='Fashion',EBH_Category__c='Baby', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1, EBH_SpotlightCategory__c=sc.id,EBH_BusinessName__c=seller1.Id);
    	insert d1;
    	EBH_DealInvoice__c div1 = new EBH_DealInvoice__c(EBH_Deal__c = d1.Id);
    	insert div1;
    	Test.startTest();
        Map<String,Object> mapResult = DealInvoiceVerificationController.apexInit(div1.Id);
        
        Map<String,Object> mapResult3 = DealInvoiceVerificationController.apexReject(d1.Id,'test reject',div1.Id);
        System.assertEquals('ok',mapResult3.get('status')+'','invoice rejected');
        Test.stopTest();
    }
    
    static testMethod void testDealInvoiceRejectNoEmailTemplateFound() {
    	RecordType r_seller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account seller1 = new Account(RecordTypeId=r_seller.Id,Name='seller test deal invoice 123456');
        insert seller1;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Spotlight Category', EBH_SpotlightCategoryID__c='Spotlight Category1',EBH_Country__c='DE'); 
        insert sc;
        Id devRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V3').Id;
        EBH_Deal__c d1 = new EBH_Deal__c(RecordTypeId=devRecordTypeId, EBH_DealEndDate__c=Date.today().addDays(1),EBH_DealFormat__c='Primary',EBH_eBayItemID__c='123456789312',EBH_SellerPrice__c=1000,EBH_DealPrice__c=500,EBH_SoldItems__c=2,EBH_DealStartDate__c=System.today(),EBH_Status__c='New',EBH_DealSiteId__c='15',EBH_Vertical__c='Fashion',EBH_Category__c='Baby', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1, EBH_SpotlightCategory__c=sc.id,EBH_BusinessName__c=seller1.Id);
    	insert d1;
    	EBH_DealInvoice__c div1 = new EBH_DealInvoice__c(EBH_Deal__c = d1.Id);
    	insert div1;
    	
    	Test.startTest();
        Map<String,Object> mapResult = DealInvoiceVerificationController.apexInit(div1.Id);
        
        Map<String,Object> mapResult3 = DealInvoiceVerificationController.apexReject(d1.Id,'test reject',div1.Id);
        System.assertEquals('ko',mapResult3.get('status')+'','no email template found');
        System.assertEquals('No Email Template found!\nPlease check deal site.',mapResult3.get('error')+'');
        Test.stopTest();
    }
      
}