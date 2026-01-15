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
private class BatchDealVerifyStatementTest {

    static testMethod void testDealAutoStatusVerify() 
    {
    	
        Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
        ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
        insert ac;
		 
   		Date dateEnd = Date.today().addDays(-32);
   		Date dateStart = Date.today().addDays(-60);
         
   		EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(EBH_Slots__c =2);
        insert dsa1;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
        insert sc; 
        
        EBH_Deal__c d1 = new EBH_Deal__c(EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=dateStart,EBH_DealEndDate__c = dateEnd,EBH_Status__c=EBH_ConstantsUtility.DEAL_STATUS_EXEC ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_eBayItemID__c='123456789');
        
        insert d1;
        
        BatchDealVerifyStatement b  = new BatchDealVerifyStatement();
        Test.startTest();
        	b.sWhere = b.sWhere.replace('>0','>=0'); //can not set formula field
        	Database.executeBatch(b);
        	
        	b.execute(null);
        	b = new BatchDealVerifyStatement(d1.Id); 
        Test.stopTest();
        
        EBH_Deal__c d1Sel = [Select Id,EBH_Status__c From EBH_Deal__c Where Id=:d1.Id];
        System.assertEquals(EBH_ConstantsUtility.DEAL_STATUS_VERIFY,d1Sel.EBH_Status__c,'set to verify by batch');
        
    }
}