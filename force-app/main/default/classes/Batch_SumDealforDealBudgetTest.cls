/*********************************************************************************************************************************
@ Class:         Batch_SumDealforDealBudgetTest
@ Version:       1.0
@ Author:        Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       test logic for Batch_SumDealforDealBudget
                 Subsidy Planned = Sum of Subsidy Planned from related deals records
                 Subsidy Running = Sum of Subsidy Running from related deals records
                 Subsidy Forecast = Sum of Subsidy Forecast from related deals records
                 Subsidy Final = Sum of Subsidy Final from related deals records
                 Subsidy Spent = =subsidy planned+subsidy running+subsidy forecast+subsidy final
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/

@isTest
private class Batch_SumDealforDealBudgetTest {

    static testMethod void myUnitTest() {

        Test.startTest();
            Batch_SumDealforDealBudget b = new Batch_SumDealforDealBudget();
            Database.executeBatch(b);
        Test.stopTest();

		String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, b);

    	/* EBH_DealsBudget__c db1 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Soft Home', EBH_Quarter__c = 'Q1');
    	 EBH_DealsBudget__c db2 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Soft Home', EBH_Quarter__c = 'Q1');
    	 insert new List<EBH_DealsBudget__c>{db1,db2};
    	 Account ac = new Account(Name='Seller');
         ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
         insert ac;
    	 EBH_Deal__c d1a = new EBH_Deal__c(EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
         d1a.EBH_DealPrice__c = 200;
         d1a.EBH_DealFormat__c = 'iji';
         d1a.EBH_DealStartDate__c = Date.today();
         d1a.EBH_DealEndDate__c = Date.today()-60;
         d1a.EBH_SellerEmail__c ='dd@d.com';
         d1a.EBH_MaximumPurchases__c =324;
         d1a.EBH_BusinessName__c = ac.Id;
         d1a.Deals_Budget__c = db1.Id;
         d1a.Subsidy_Running__c = 10;
         d1a.EBH_Payout_SI__c = 10;
         EBH_Deal__c d2a = new EBH_Deal__c(EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
         d2a.EBH_DealPrice__c = 200;
         d2a.EBH_DealFormat__c = 'iji';
         d2a.EBH_DealStartDate__c = Date.today();
         d2a.EBH_DealEndDate__c = Date.today()-60;
         d2a.EBH_SellerEmail__c ='dd@d.com';
         d2a.EBH_MaximumPurchases__c =324;
         d2a.EBH_BusinessName__c = ac.Id;
         d2a.Deals_Budget__c = db2.Id;
         d2a.Subsidy_Running__c = 10;
         d2a.EBH_Payout_SI__c = 10;
         insert new List<EBH_Deal__c>{d1a,d2a};
        Test.startTest();
        Batch_SumDealforDealBudget b = new Batch_SumDealforDealBudget();
        Database.executeBatch(b);
        Test.stopTest();
        List<EBH_DealsBudget__c> lstDealBudget = [Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Forecast__c, e.Subsidy_Final__c From EBH_DealsBudget__c e where id IN: new List<EBH_DealsBudget__c>{db1,db2}];
        System.assertEquals(10,lstDealBudget[0].Subsidy_Running__c);
        System.assertEquals(790,lstDealBudget[0].Subsidy_Planned__c);
        System.assertEquals(8000,lstDealBudget[0].Subsidy_Final__c);
        
        System.assertEquals(10,lstDealBudget[1].Subsidy_Running__c);
        System.assertEquals(790,lstDealBudget[1].Subsidy_Planned__c);
        System.assertEquals(8000,lstDealBudget[1].Subsidy_Final__c);
        */
    }
}