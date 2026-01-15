/*********************************************************************************************************************************
@ Class:         Batch_BobSellerBulkCSVTest
@ Version:       1.0
@ Author:        sovantheany.dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       US-0007333 - LTTM - Bulk Upload BoB Sellers
@ test logic for Batch_BobSellerBulkCSV
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.03.2020 /sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class.
@				: 06.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
*********************************************************************************************************************************/
@isTest
private class Batch_BobSellerBulkCSVTest {
static testMethod void testBobSellerBulkUpload() {
	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
		insert acc;
	/*List<User> admUsers = EBH_TestDataFactory.createUsers(1, 'System Administrator');
			admUsers[0].BoB_Country__c = '3';
			insert admUsers;
	*/
	
			// Updated by DHE on 2020-05-06 to fix test class execution in UAT
			List<User> admUsers=[select id, profileid from user where isactive=true and UserType = 'Standard' limit 1];
			//admUsers[0].BoB_Country__c = '3';
			
	RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
	BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
			insert bob;
			String csvStringEN ='oracle id, account manager, secondary am\r1003293591,testCorpID,testCorpID\r1003293591,testCorpID,testCorpID\r18116485,testCorpID,testCorpID';
			String uniqueName = ApexUtil.genUniqueString(10);
		Document doc=new Document(Name=uniqueName,Body=Blob.valueOf(csvStringEN),FolderId=UserInfo.getUserId());
		insert doc;
			Test.startTest();
			Batch_BobSellerBulkCSV b = new Batch_BobSellerBulkCSV(bob.Id, uniqueName,'EN',',');
			Database.executeBatch(b);

		Test.stopTest();
	    String bobId = bob.Id;
	    List<BoB_Seller__c> bobSellers = Database.query( +'select Account_Manager__r.FederationIdentifier, BoB__r.Account_Manager__r.FederationIdentifier, TTEC_MANAGER__c from BoB_Seller__c  Where BoB__c =:bobId');
	    System.assert(bobSellers.size()==1);
	}
	
	static testMethod void testBobSellerBulkUploadWithAffectSeller() {
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');//LA:05-12-2023-US-0014231: Remove EBH_DealsProgram__c='Accepted'
		insert acc;
		
		List<User> admUsers=[select id, profileid from user where isactive=true and UserType = 'Standard' limit 1];
		//admUsers[0].BoB_Country__c = '3';
			
		RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
		BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
		BoB__c bob2 = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
		insert new List<BoB__c>{bob,bob2};
		RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
		BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Seller__c=acc.Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        insert bs;  
            
	    String csvStringEN ='oracle id, account manager, secondary am\r1003293591,testCorpID,testCorpID\r1003293591,testCorpID,testCorpID\r18116485,testCorpID,testCorpID';
		String uniqueName = ApexUtil.genUniqueString(10);
		Document doc2=new Document(Name=uniqueName,Body=Blob.valueOf(csvStringEN),FolderId=UserInfo.getUserId());
		insert doc2;
		
	    
		test.startTest();
		Batch_BobSellerBulkCSV b2 = new Batch_BobSellerBulkCSV(bob2.Id, uniqueName,'EN',',');
		Database.executeBatch(b2);
		test.stopTest();
	}
}