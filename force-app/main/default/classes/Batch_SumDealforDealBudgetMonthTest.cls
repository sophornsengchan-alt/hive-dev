/*********************************************************************************************************************************
@ Class:         Batch_SumDealforDealBudgetTest
@ Version:       1.0
@ Author:        Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       test logic for Batch_SumDealforDealBudgetMonth
                 Subsidy Planned = Sum of Subsidy Planned from related deals records
                 Subsidy Running = Sum of Subsidy Running from related deals records
                 Subsidy Forecast = Sum of Subsidy Forecast from related deals records
                 Subsidy Final = Sum of Subsidy Final from related deals records
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 28.06.2019 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class.
                 17.11.2021 / Sambath Seng (sambath.seng@gaea-sys.com) / US-0008366 - Upgrade code coverage of Batch_SumDealforDealBudgetMonth
*********************************************************************************************************************************/

@isTest
private class Batch_SumDealforDealBudgetMonthTest {

    static testMethod void myUnitTest() {
       /* EBH_DealsBudget__c db1 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Soft Home', EBH_Quarter__c = 'Q1',Year__c=String.valueof(System.today().Year()));
    	EBH_DealsBudget__c db2 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Soft Home', EBH_Quarter__c = 'Q2',Year__c=String.valueof(System.today().Year()));
    	insert new List<EBH_DealsBudget__c>{db1,db2};
    	 Account ac = new Account(Name='Seller');
         ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
         insert ac;
    	 EBH_Deal__c d1a = new EBH_Deal__c(EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
         d1a.EBH_DealPrice__c = 200;
         d1a.EBH_DealFormat__c = 'iji';
         d1a.EBH_DealStartDate__c = Date.newInstance(Date.today().year(),1,1);
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
         d2a.EBH_DealStartDate__c = Date.newInstance(Date.today().year(),5,1);
         d2a.EBH_DealEndDate__c = Date.today()-60;
         d2a.EBH_SellerEmail__c ='dd@d.com';
         d2a.EBH_MaximumPurchases__c =324;
         d2a.EBH_BusinessName__c = ac.Id;
         d2a.Deals_Budget__c = db2.Id;
         d2a.Subsidy_Running__c = 10;
         d2a.EBH_Payout_SI__c = 10;
         insert new List<EBH_Deal__c>{d1a,d2a};
        Test.startTest();
        Batch_SumDealforDealBudgetMonth b = new Batch_SumDealforDealBudgetMonth();
        Database.executeBatch(b);
        Test.stopTest();
        List<EBH_DealsBudgetMonth__c> lstDealBudgetMonth = [Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Final__c, e.EBH_SubsidyForecast__c, e.EBH_MonthYear__c, e.EBH_DealsBudget__r.EBH_Vertical__c, e.EBH_DealsBudget__c From EBH_DealsBudgetMonth__c e where EBH_DealsBudget__c IN: new List<EBH_DealsBudget__c>{db1,db2}];
         System.assertEquals(6,lstDealBudgetMonth.size());
         for(EBH_DealsBudgetMonth__c dMonth : lstDealBudgetMonth){
         	if(dMonth.EBH_MonthYear__c == '1'+String.valueOf(Date.today().year()) || dMonth.EBH_MonthYear__c == '5'+String.valueOf(Date.today().year())){
         		System.assertEquals(10,dMonth.Subsidy_Running__c);
		        System.assertEquals(790,dMonth.Subsidy_Planned__c);
		        System.assertEquals(8000,dMonth.Subsidy_Final__c);
         	}else{
         		System.assertEquals(0,dMonth.Subsidy_Running__c);
		        System.assertEquals(0,dMonth.Subsidy_Planned__c);
		        System.assertEquals(0,dMonth.Subsidy_Final__c);
         	}
         }*/

        //SB 17.11.2021 US-0008366 - Upgrade code coverage of Batch_SumDealforDealBudgetMonth
        List<EBH_DealsBudget__c> lstDB = new List<EBH_DealsBudget__c>();
        for(Integer i=1; i<=4; i++){
        	EBH_DealsBudget__c db = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Soft Home', EBH_Quarter__c = 'Q'+i);
        	lstDB.add(db);
        }
        insert lstDB;
        Test.startTest();
        List<EBH_DealsBudgetMonth__c> dbm = DealBudgetTriggerHandler.createDealBudgetMonth(lstDB);
        Batch_SumDealforDealBudgetMonth bsc = new Batch_SumDealforDealBudgetMonth();
        Database.executeBatch(bsc);
        System.schedule('Batch_SumDealforDealBudgetMonth', '0 0 * * * ?', bsc);
        Test.stopTest();
    }
}