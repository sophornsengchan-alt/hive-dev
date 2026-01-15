/*********************************************************************************************************************************
@ Class:          CloneFVFControllerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        EPH-7680 Clone function on FVF promo clones Nominated Items
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.08.2019 / Sovantheany Dim / Created the class.
@				: 13/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
*********************************************************************************************************************************/
@isTest
private class CloneFVFControllerTest {

    static testMethod void testapexCloneFVF() {
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id);
    	insert acc;    	 
		RecordType fvfRecordType = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE);
    	Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(RecordTypeId =fvfRecordType.Id,Seller_Email__c='test@test.com',Site__c='UK');
    	insert fvf;
		Nominated_Item__c norItem = new Nominated_Item__c(Final_Value_Fee_FVF__c = fvf.Id);
        insert norItem;
        
        Test.startTest();
        Map<String,Object> mapResult = CloneFVFController.apexCloneFVF(fvf.Id);
		Map<String,Object> mapResult2 = CloneFVFController.apexCloneFVF(null);
        Test.stopTest();
        System.assertEquals('ok',mapResult.get('status'));
		System.assertEquals('ko',mapResult2.get('status'));
    }
	
}