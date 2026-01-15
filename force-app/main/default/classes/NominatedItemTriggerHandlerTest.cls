/*********************************************************************************************************************************
@ Class:          NominatedItemTriggerHandlerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        test Handler Class for trigger NominatedItem
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.05.2019 / Sovantheany Dim / Created the class.
@				: 06/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
*********************************************************************************************************************************/
@isTest
private class NominatedItemTriggerHandlerTest {
    static testmethod void setupData(){
        EBH_TestDataFactory.setUpCustomSettings();      
    }
    static testMethod void myUnitTest() {
        setupData();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c = 'UK');
    	insert acc;
    	//RecordType prodRecordType = ApexUtil.getRecordTypeByName('Product__c','TTP_Product');
    	
    	Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(Discount_FVF__c = 25,Seller_Name__c = acc.Id);
    	insert fvf;
    	
    	
		Nominated_Item__c norItem = new Nominated_Item__c(Final_Value_Fee_FVF__c = fvf.Id);
        Test.startTest();
        	insert norItem;
		Test.stopTest();
		
		System.assertNotEquals(null,norItem.Id,'OK');
	 
    }

	static testMethod void updateNominatedByOwnerAndRequestorTest(){
		
		setupData();
        
       	RecordType contacDW_RT = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
        Contact cont = new Contact(LastName='Test Cont1',RecordTypeID=contacDW_RT.Id);
        insert cont;
		
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,Primary_Contact__c=cont.Id,EBH_RevRollup__c = 'UK');
    	insert acc;
       
        
    	Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(Discount_FVF__c = 25, Seller_Name__c = acc.Id,Seller_Email__c='test@test.com', Requestor__c=UserInfo.getUserId());
		
    	insert new List<Final_Value_Fee_FVF__c>{fvf};

		Test.startTest();
		Nominated_Item__c norItem = new Nominated_Item__c(Final_Value_Fee_FVF__c = fvf.Id);
		insert norItem;

		Profile pstd = [select id from profile where name='Standard User']; 
         User usr1 = new User(alias = 'standt', email='standarduser99@testorg99.com', 
            emailencodingkey='UTF-8', lastname='Testing',FirstName='Jake', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = pstd.Id, 
            timezonesidkey='America/Los_Angeles', username='standarduser99@testorg9.com');
            
          // insert u;
         System.runAs(usr1) {
			try {
				update norItem;
				// System admin can update Nominated_Item__c
			} catch (DMLException dex) {
				System.debug(dex.getMessage());
				System.assert(false, 'Only System admin should have permission to update the record: '+dex.getStackTraceString());
			}
        }	
		Test.stopTest();
	}
	
}