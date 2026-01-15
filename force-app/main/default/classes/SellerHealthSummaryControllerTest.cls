/***************************************************************************************************************************************
@ Class:          SellerHealthSummaryControllerTest
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Test class for SellerHealthSummaryControllerTest
----------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.07.2018 / Vadhanak Voun / Created the class.
***************************************************************************************************************************************/

@isTest
private  class SellerHealthSummaryControllerTest {
	
	static  testMethod void testBasicPdf()
	{
		List<Account> sellers =  EBH_TestDataFactory.createAccounts(1, 'EBH_Seller') ;
		
		Test.startTest();
			SellerHealthSummaryController shs = new SellerHealthSummaryController(new ApexPages.StandardController(sellers[0]));
			List<String> listGroup  = shs.listGroup;
			Map<String,String> mapGroupToLabel = shs.mapGroupToLabel;
		Test.stopTest();
		
	}
    
}