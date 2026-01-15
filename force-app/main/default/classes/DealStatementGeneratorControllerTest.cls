/*********************************************************************************************************************************
@ Class:          DealStatementGeneratorControllerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Test class for DealStatementGeneratorController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  18.10.2021 / Sovantheany Dim / Created the  class.
*********************************************************************************************************************************/
@isTest
private class DealStatementGeneratorControllerTest {
    @isTest 
    private static void testgenerateToExcel(){
        Account eBSeller = new Account (Name='Test 1',EBH_OracleID__c='12345');
        insert eBSeller;
        Date mydate = System.Today();
        Deal_Statement_Summary__c dss = new Deal_Statement_Summary__c(Deal_Site__c = 'US', Month__c = mydate.month()+'', Year__c = mydate.year()+'', Status__c = 'New', Statement_Type__c = '1st Statement');
        insert dss;
        Test.startTest();
        //test fail 
        Map<String, Object> mapresult = DealStatementGeneratorController.generateToExcel(dss.Id);
		System.assert(mapresult.get('isSuccess') == false);
        
        //test success
        Deal_Statement__c ds1 = new Deal_Statement__c();
        ds1.Name = eBSeller.Name+'Statement';
        ds1.Subsidy_Final_Calculation__c=0;                 
        ds1.Status__c = '1st Payout Approved';
        ds1.X1st_Statement_Approved__c = true;
        ds1.Initial_Payout__c =60;
        ds1.Second_Payout__c=40;
        ds1.eBay_Seller__c = eBSeller.Id;
        ds1.Subsidy_Final_Calculation__c=0;
        ds1.Month__c = mydate.month()+'';
        ds1.Year__c  = mydate.year();
        ds1.Amount_Held_Back__c=40;
        ds1.Initial_Payout__c=60;    
        ds1.Last_Statement_Sent_Out__c = System.now();
        ds1.Site__c = '0';
        insert ds1;
        Map<String, Object> mapresult2 = DealStatementGeneratorController.generateToExcel(dss.Id);
        System.assert(mapresult2.get('isSuccess') == true);
        Test.stopTest();
    }
}