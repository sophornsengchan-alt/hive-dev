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
 * 
 * 	19/07/2024/ vadhanak voun/ US-0015373 - Align Apex Classes with Deactivated FVF_Campaign Record Type
 *  @ Change history : 19.05.2025 / Vimean Heng / US-0026060 - Hiveforce product areas testing due to API version upgrade (1/5)
 */
@isTest
private class Batch_FVFCampaignBulkCSVTest {

    static testMethod void testFvFcampaignUpload() {
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');//LA:05-12-2023-US-0014231: Remove EBH_DealsProgram__c='Accepted'
    	insert acc;
    	
		//NK:19/07/2024:US-0015373
        RecordType fvfCampRec = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c','FVF_Seller_Level'); //EBH_ConstantsUtility.FVF_CAMPAIGN_RECORDTYPE
        
        Final_Value_Fee_FVF__c fvfCamp = new Final_Value_Fee_FVF__c(Site__c='UK',RecordTypeId =fvfCampRec.Id ,Legal_Entity_Country__c='UK', Legal_Entity_Name__c='My Company',Legal_Entity_Street__c='street1',Legal_Entity_Zip__c='12345',Seller_Name__c=acc.Id,Seller_Email__c='test@test.com');
    	insert fvfCamp;
    	String csvStringEN ='oracle id,listing id,price (target)\r1003293591,352863576988,37.12\r1003293591,302638000000,12.15\r18116485,391810407692,102.60';
    	
    	String uniqueName = ApexUtil.genUniqueString(10);
    	Document doc=new Document(Name=uniqueName,Body=Blob.valueOf(csvStringEN),FolderId=UserInfo.getUserId());
	    insert doc;
	    
	    Test.startTest();
	    	Batch_FVFCampaignBulkCSV b = new Batch_FVFCampaignBulkCSV(fvfCamp.Id, uniqueName,'EN',',');
	    	Database.executeBatch(b);	    
	    
	    Test.stopTest();
	    // Final_Value_Fee_FVF__c[] fvfListing = [Select Id,Seller_Name__c From Final_Value_Fee_FVF__c Where FVF_Campaign__c =:fvfCamp.Id];
    	// System.assertEquals(2,fvfListing.size(),'2 fvf listing created from upload and attached to fvf campaign');
    	
    	// Nominated_Item__c[] items = [Select Id From Nominated_Item__c Where Final_Value_Fee_FVF__r.FVF_Campaign__c =:fvfCamp.Id];
    	// System.assertEquals(3,items.size(),'3 in total of Nominated_Item__c created from csv upload and attached to fvf listing');
    }
}